"""Generate, review and apply directed voice takes without losing working audio."""
import argparse
import array
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import tempfile
import wave
from datetime import datetime

import make_voices as m

HERE = Path(__file__).resolve().parent
TAKES = HERE / 'directed_v1'
PLAN = HERE / 'delivery_plan.json'


def save_json(path, data):
    staged = path.with_suffix('.json.tmp')
    staged.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    os.replace(staged, path)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def wav_info(path):
    with wave.open(str(path), 'rb') as reader:
        if (reader.getnchannels(), reader.getsampwidth(), reader.getframerate()) != (1, 2, 22050):
            raise ValueError('Unexpected game audio format: ' + str(path))
        data = array.array('h', reader.readframes(reader.getnframes()))
    duration = len(data) / 22050
    if duration < 0.15 or not data or max(abs(v) for v in data) == 0:
        raise ValueError('Empty or silent take: ' + str(path))
    rms = math.sqrt(sum(v * v for v in data) / len(data))
    return {'seconds': round(duration, 3), 'rms_dbfs': round(20 * math.log10(rms / 32768), 2),
            'peak': max(abs(v) for v in data), 'sha256': sha(path)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['plan', 'generate', 'preview', 'apply'])
    parser.add_argument('--keys', nargs='+', help='Only these unchanged V identifiers')
    parser.add_argument('--only', help='Only this character')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    cfg = json.loads(Path(m.VOICES).read_text(encoding='utf-8'))
    cfg['_delivery_plan'] = PLAN.name
    plan = json.loads(PLAN.read_text(encoding='utf-8'))
    lines = m.extract()
    # Validate the entire plan before spending credits or changing game assets.
    requests = {line['key']: m.acting_request(line, cfg) for line in lines}
    if set(requests) != set(plan['lines']):
        raise ValueError('The acting plan does not match the current dialogue set.')
    if args.keys and set(args.keys) - set(requests):
        parser.error('Unknown dialogue key')
    selected = [line for line in lines if (not args.keys or line['key'] in args.keys)
                and (not args.only or line['speaker'] == args.only)]
    TAKES.mkdir(exist_ok=True)
    receipt_path = TAKES / 'receipts.json'
    receipts = json.loads(receipt_path.read_text(encoding='utf-8')) if receipt_path.exists() else {}
    fingerprints = {}
    for line in lines:
        text, settings = requests[line['key']]
        payload = {'text': text, 'settings': settings, 'voice_id': cfg[line['speaker']],
                   'seed': int(line['key'][1:]), 'fx': cfg.get('_fx', {}).get(line['speaker'], ''),
                   'radio': line['kind'] == 'infolink'}
        fingerprints[line['key']] = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()

    def complete(line):
        target = TAKES / (line['key'] + '.wav')
        receipt = receipts.get(line['key'], {})
        return (target.exists() and receipt.get('fingerprint') == fingerprints[line['key']]
                and receipt.get('sha256') == sha(target))

    if args.command == 'plan':
        for line in selected:
            text, settings = requests[line['key']]
            print(line['key'], line['speaker'], 'stability=' + str(settings['stability']), text)
        print('%d directed lines; model=%s' % (len(selected), plan['model_id']))
        return

    if args.command == 'generate':
        pending = [line for line in selected if not complete(line)]
        print('%d requests, %d prompted characters' %
              (len(pending), sum(len(requests[line['key']][0]) for line in pending)), flush=True)
        if args.dry_run:
            for line in pending:
                print(line['key'], requests[line['key']][0])
            return
        if not Path(m.FFMPEG).is_file():
            raise ValueError('ffmpeg is not available')
        key = m.api_key() if pending else None
        with tempfile.TemporaryDirectory(dir=HERE, prefix='_directed_') as temp:
            for line in pending:
                text, settings = requests[line['key']]
                print('Generate', line['speaker'], line['key'], line['text'], flush=True)
                mp3, wav = Path(temp) / 'take.mp3', Path(temp) / 'take.wav'
                api_receipt = m.tts(key, cfg[line['speaker']], text, str(mp3), settings,
                                    seed=int(line['key'][1:]))
                m.to_wav(str(mp3), str(wav), line['kind'] == 'infolink',
                         cfg.get('_fx', {}).get(line['speaker'], ''))
                info = wav_info(wav)
                os.replace(wav, TAKES / (line['key'] + '.wav'))
                receipts[line['key']] = {**line, **info, **api_receipt,
                    'model_id': settings['model_id'], 'tts_text': text, 'settings': settings,
                    'fingerprint': fingerprints[line['key']]}
                save_json(receipt_path, receipts)
                print('  %.3fs, %.2f dBFS' % (info['seconds'], info['rms_dbfs']), flush=True)
        print('%d/%d selected takes ready.' % (sum(complete(line) for line in selected), len(selected)))
        return

    if args.command == 'preview':
        if not args.keys:
            selected = [line for line in selected if complete(line)]
        elif not all(complete(line) for line in selected):
            raise ValueError('Generate selected takes before preparing the preview.')
        preview = TAKES / 'preview.wav'
        with wave.open(str(preview), 'wb') as writer:
            writer.setparams((1, 2, 22050, 0, 'NONE', 'not compressed'))
            for line in selected:
                with wave.open(str(TAKES / (line['key'] + '.wav')), 'rb') as reader:
                    writer.writeframes(reader.readframes(reader.getnframes()))
                writer.writeframes(b'\0\0' * int(22050 * 0.35))
        save_json(TAKES / 'preview.json', [receipts[line['key']] for line in selected])
        print('Preview:', preview)
        return

    if args.command == 'apply':
        if args.keys or args.only:
            parser.error('Apply requires the complete dialogue set.')
        missing = [line['key'] for line in lines if not complete(line)]
        if missing:
            raise ValueError('Incomplete or stale takes: ' + ', '.join(missing))
        for line in lines:
            wav_info(TAKES / (line['key'] + '.wav'))
        backup = HERE / 'backups' / datetime.now().strftime('delivery-%Y%m%d-%H%M%S')
        backup.mkdir(parents=True, exist_ok=False)
        shutil.copy2(m.VOICES, backup / 'voices.json')
        for line in lines:
            target = Path(m.OUT_SOUNDS) / (line['key'] + '.wav')
            if target.exists():
                shutil.copy2(target, backup / target.name)
        # Old takes and configuration are fully backed up before replacing.
        for line in lines:
            target = Path(m.OUT_SOUNDS) / (line['key'] + '.wav')
            staged = target.with_suffix('.wav.new')
            shutil.copy2(TAKES / target.name, staged)
            os.replace(staged, target)
        cfg['_settings'] = {**plan['settings'], 'stability': 0.5}
        cfg['_info'] = ('Voice IDs per character. Acting prompts and per-character stability are in '
                        'delivery_plan.json, selected by _delivery_plan. Hash only the unchanged dialogue.')
        save_json(Path(m.VOICES), cfg)
        m.write_class()
        save_json(TAKES / 'applied.json', {'backup': str(backup), 'revision': plan['revision'],
                                          'lines': len(lines)})
        print('Applied %d directed voices; old WAVs/config: %s' % (len(lines), backup))


if __name__ == '__main__':
    main()
