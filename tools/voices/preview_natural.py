"""Only two review voices. Never writes game WAVs, config, packages or installs.

Use Eleven v4 for faithful, restrained speech with minimal vocal direction.
Keep a dry full-band signal and equal preview loudness using fixed gain,
avoiding phrase-by-phrase automatic compression/pumping. Original character
levels are measured for later game-mix calibration, not applied in this preview.
"""
import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import subprocess
import wave

import make_voices as m

HERE = Path(__file__).resolve().parent
BASE_OUT = HERE / 'previews' / 'natural_v4'
OUT = BASE_OUT
PROFILES = {
    'AnnaNavarre': {
        'reference_indices': [0, 3, 5, 6, 12, 15, 24, 27],
        'stability': 1.0,
        'tempo': 0.94,
        'keys': ['V1299363', 'V9312630'],
        'tag': 'steady, matter-of-fact delivery, measured conversational pace',
        'direction': 'Restrained reprimand followed by practical instructions. Plain diction and a level voice; no dramatic whispering, raised pitch or anger tags.',
    },
    'GuntherHermann': {
        'reference_indices': [2, 4, 12, 14, 15, 16, 17, 24],
        'stability': 1.0,
        'tempo': 1.0,
        'keys': ['V2258766', 'V1501672'],
        'tag': 'steady, matter-of-fact delivery, unhurried conversational pace',
        'direction': 'Deliberate operational briefing and a restrained warning. Let the original clone supply weight and accent; no added gravelly/menacing tags.',
    },
}


def run(args):
    return subprocess.run([m.FFMPEG, '-hide_banner', '-loglevel', 'info', *args],
                          check=True, capture_output=True)


def measure(path):
    result = run(['-i', str(path), '-af', 'loudnorm=I=-18:TP=-1.5:LRA=11:print_format=json',
                  '-f', 'null', '-'])
    found = re.search(r'\{\s*"input_i".*?\}', result.stderr.decode('utf-8', 'replace'), re.S)
    if not found:
        raise ValueError('No loudness statistics: ' + str(path))
    return {key: float(value) for key, value in json.loads(found.group()).items()
            if key in ('input_i', 'input_tp', 'input_lra')}


def frames_info(path):
    with wave.open(str(path), 'rb') as reader:
        rate, channels, width = reader.getframerate(), reader.getnchannels(), reader.getsampwidth()
        data = array.array('h', reader.readframes(reader.getnframes()))
    if channels != 1 or width != 2 or not data:
        raise ValueError('Unexpected audio format')
    peak = max(abs(value) for value in data)
    if peak == 0:
        raise ValueError('Silent preview')
    return {'seconds': len(data) / rate, 'rate': rate, 'peak_dbfs': 20 * math.log10(peak / 32768),
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def slice_reference(speaker, clip, target):
    sample = json.loads((HERE / 'samples/manifest.json').read_text(encoding='utf-8'))[speaker]
    with wave.open(str(HERE / 'samples' / sample['file']), 'rb') as reader:
        params = reader.getparams()
        reader.setpos(round(clip['start_seconds'] * reader.getframerate()))
        data = reader.readframes(round(clip['duration_seconds'] * reader.getframerate()))
    with wave.open(str(target), 'wb') as writer:
        writer.setparams(params)
        writer.writeframes(data)


def main():
    global OUT
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--analyze-only', action='store_true')
    parser.add_argument('--refine', action='store_true', help='A separate revision; preserve the approved V4 base')
    args = parser.parse_args()
    if args.refine:
        OUT = HERE / 'previews' / 'natural_v4_r2'
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((HERE / 'samples/manifest.json').read_text(encoding='utf-8'))
    lines = {line['key']: line for line in m.extract()}
    cfg = json.loads(Path(m.VOICES).read_text(encoding='utf-8'))
    report_path = OUT / 'review.json'
    report = json.loads(report_path.read_text(encoding='utf-8')) if report_path.exists() else {}
    for speaker, profile in PROFILES.items():
        refs = []
        for index in profile['reference_indices']:
            clip = manifest[speaker]['clips'][index]
            reference = BASE_OUT / ('reference_%s_%d.wav' % (speaker, index))
            if not reference.exists():
                slice_reference(speaker, clip, reference)
            stats = measure(reference)
            refs.append({**clip, **stats, 'file': str(reference),
                         'words_per_minute': len(clip['text'].split()) * 60 / clip['duration_seconds']})
        # Median of several ordinary original lines, not a combat bark or one
        # clipped loud word. Integrated LUFS is only a baseline for comparison.
        target_lufs = statistics.median(ref['input_i'] for ref in refs)
        text_lines = [lines[key]['text'] for key in profile['keys']]
        spoken = ' '.join(text_lines)
        # One subtle delivery cue; punctuation provides the pauses. Do not
        # force an emotion onto each sentence or use unsupported v4 SSML.
        # V4 ellipses can imply hesitation. The new Gunther trial uses a comma
        # at the warning instead; the underlying game wording/key is unchanged.
        if args.refine and speaker == 'GuntherHermann':
            text_lines = [text.replace('JC Denton...', 'JC Denton,') for text in text_lines]
        tag = 'matter-of-fact' if args.refine else profile['tag']
        request = '[%s] %s' % (tag, '\n\n'.join(text_lines))
        settings = {'model_id': 'eleven_v4', 'stability': 0.9 if args.refine else profile['stability'],
                    'similarity_boost': 0.75}
        fingerprint = hashlib.sha256(json.dumps({'voice_id': cfg[speaker], 'text': request,
                                                 'settings': settings}, sort_keys=True).encode()).hexdigest()
        info = report.get(speaker, {})
        info.update({'original_references': refs, 'reference_target_lufs': target_lufs,
                     'direction': profile['direction'], 'text': spoken, 'tts_text': request,
                     'settings': settings, 'keys': profile['keys']})
        print('%s originals: median %.2f LUFS, median %.1f words/min' %
              (speaker, target_lufs, statistics.median(ref['words_per_minute'] for ref in refs)), flush=True)
        if args.analyze_only:
            report[speaker] = info
            continue
        raw = OUT / (speaker + '_raw.mp3')
        if not raw.exists() or info.get('request_fingerprint') != fingerprint:
            print('Generate ONLY review voice:', speaker, settings, flush=True)
            receipt = m.tts(m.api_key(), cfg[speaker], request, str(raw), settings, seed=20261003)
            info.update(receipt)
            info['request_fingerprint'] = fingerprint
            report[speaker] = info
            report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        decoded = OUT / (speaker + '_dry.wav')
        # Keep the full speech bandwidth. The refinement adds only a small EQ
        # correction and light compression; the base remains dry and untouched.
        decode_args = ['-y', '-i', str(raw)]
        tempo = profile['tempo']
        if args.refine:
            duration_result = subprocess.run([str(Path(m.FFMPEG).with_name('ffprobe.exe')),
                '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=nw=1:nk=1', str(raw)],
                capture_output=True, check=True, text=True)
            raw_wpm = len(spoken.split()) * 60 / float(duration_result.stdout)
            target_wpm = 205 if speaker == 'AnnaNavarre' else 190
            # The new Anna take is faster than the approved base. Slow this
            # cached take enough to reach the target without changing pitch.
            # Its resulting duration is only slightly longer than the base.
            minimum_tempo = 0.84 if speaker == 'AnnaNavarre' else 0.92
            tempo = max(minimum_tempo, min(1.08, target_wpm / raw_wpm))
            info.update({'raw_words_per_minute': raw_wpm, 'target_words_per_minute': target_wpm})
        filters = ['atempo=%.6f' % tempo] if tempo != 1.0 else []
        if args.refine:
            # Tentative small correction, not an attempt to copy the reference
            # recordings' high-frequency hiss. Levels remain matched at -17 LUFS.
            filters += ['bass=g=-0.7:f=180:width_type=o:width=1',
                        'equalizer=f=3200:width_type=o:width=1:g=0.75',
                        'acompressor=threshold=0.0631:ratio=1.25:attack=8:release=90:knee=2.828:makeup=1']
        if filters:
            decode_args += ['-af', ','.join(filters)]
        run(decode_args + ['-ac', '1', '-ar', '22050', '-sample_fmt', 's16', str(decoded)])
        raw_stats = measure(decoded)
        # Equal playback levels for the two review players. The original game
        # uses different sound radii/gain, which will be addressed after review.
        preview_target_lufs = -17.0
        wanted_gain = preview_target_lufs - raw_stats['input_i']
        safe_gain = -1.5 - raw_stats['input_tp']
        gain = min(wanted_gain, safe_gain)
        preview = OUT / (speaker + '_preview.wav')
        run(['-y', '-i', str(decoded), '-af', 'volume=%.4fdB' % gain,
             '-ac', '1', '-ar', '22050', '-sample_fmt', 's16', str(preview)])
        info.update({'raw_loudness': raw_stats, 'gain_db': gain,
                     'preview_target_lufs': preview_target_lufs,
                     'pitch_preserving_tempo': tempo, 'processing_filters': filters,
                     'revision': 'r2' if args.refine else 'base',
                     'preview_loudness': measure(preview), 'preview_file': str(preview),
                     'preview_info': frames_info(preview)})
        info['preview_words_per_minute'] = len(spoken.split()) * 60 / info['preview_info']['seconds']
        report[speaker] = info
        report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        print('Preview %.2fs, %.2f LUFS, %.1f words/min, gain %.2fdB: %s' %
              (info['preview_info']['seconds'], info['preview_loudness']['input_i'],
               info['preview_words_per_minute'], gain, preview), flush=True)
    report_path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
