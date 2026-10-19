"""Prepare voiced campaign rewrite drafts without changing the runtime campaign.

Uses the approved clones, calibrated V4 timings and current de-esser / limiter.
Explicit dialogue is read from the authored script. Inline branch alternatives
are enumerated below; prose, objectives and terminal documents are never spoken.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import shutil
import urllib.error
import urllib.request
import wave

import make_voices as m
import natural_voices as n
from sync_route_dialogue import intent

HERE = Path(__file__).resolve().parent
DOCUMENT = Path(m.ROOT) / 'docs/CAMPAIGN_REWRITE_2026_10_06.md'
PLAN = HERE / 'delivery_campaign_rewrite_v4.json'
CACHE = HERE / 'campaign_rewrite_v4'
RUNTIME_CACHE = n.OUT
SPEAKERS = {
    'GUNTHER': 'GuntherHermann', 'JC': 'JCDenton', 'AGENT': 'MIB',
    'SIMONS': 'WaltonSimons', 'MESSENGER': 'Red_Arrow_01',
    'MAX': 'MaxChen', 'MAGGIE': 'MaggieChow', 'GORDON': 'GordonQuick',
    'GUARD': 'TriadLumPath', 'TONG': 'TracerTong',
    'COMMANDER': 'MJ12Commando', 'TECHNICIAN': 'MJ12Troop',
    'PRISONER': 'ScientistConsulting',
}
# Only alternatives explicitly written in the document.
ALTERNATIVES = [
    ('NY-G03', 'GuntherHermann', 'Go to Hong Kong, Denton.', 'repeat'),
    ('NY-G03', 'GuntherHermann', 'Were you here with Paul?', 'outside-skipped'),
    ('HK-03', 'JCDenton', "I'll look into Chow. I haven't agreed to hand you a weapon.", 'qualified-acceptance'),
    ('HK-03', 'MaxChen', 'Then investigate. We will discuss the weapon when you have it.', 'qualified-acceptance'),
    ('HK-03', 'JCDenton', 'I want information, not a job.', 'decline-deal'),
    ('HK-03', 'MaxChen', 'Then ask Miss Chow why Yuen Kong never came home.', 'decline-deal'),
    ('HK-04', 'JCDenton', 'Did he come here?', 'max-not-met'),
    ('HK-05', 'JCDenton', 'I need to know what happened to the Dragon\'s Tooth.', 'maggie-not-met'),
    ('HK-06', 'JCDenton', 'Simons.', 'recording-seen'),
    ('HK-07', 'JCDenton', "I can prove she had the sword. Not that she killed him.", 'yuen-evidence-incomplete'),
    ('HK-07', 'JCDenton', "The sword is still at Queen's Tower. I brought the records.", 'sword-not-taken'),
    ('evidence', 'JCDenton', 'This copy has the same shipment identifiers', 'paul-records-not-read'),
    ('HK-12', 'TracerTong', 'Come with me.', 'escape'),
    ('HK-12', 'JCDenton', 'No.', 'escape'),
    ('HK-12', 'TracerTong', 'Then watch.', 'escape'),
    ('HK-13', 'MJ12Commando', 'Take him.', 'prisoner-saved'),
    ('HK-14', 'WaltonSimons', "Tong's death has been confirmed. The recovery team has secured his facility.", 'tong-dead'),
]


def normal(text):
    return text.replace('\u2019', "'").replace('\u201c', '"').replace('\u201d', '"').strip()


def dialogue():
    source = DOCUMENT.read_text(encoding='utf-8')
    entries, scenes = {}, {}
    section, branch, mode = None, 'main', 'direct'

    def add(scene, speaker, text, kind='con', branch_name='main', projection=False, line_number=None):
        text = normal(text)
        if text not in normal(source):
            raise ValueError('Dialogue absent from document: ' + text)
        key = m.voice_key(speaker, text, kind)
        intended_file = ('UCSceneGuntherTon.uc' if scene == 'NY-G01'
                         else 'UCSceneGuntherSearch.uc' if scene.startswith('NY-')
                         else 'UCSceneTongLab.uc' if scene in ('evidence', 'HK-09', 'HK-11', 'HK-12', 'HK-13')
                         else DOCUMENT.name)
        record = {
            'speaker': speaker, 'text': text, 'kind': kind, 'key': key,
            'file': intended_file, 'document': DOCUMENT.name,
            'document_line': line_number, 'scene': scene, 'branch': branch_name,
            'conversation': 'M06WaltonHolo' if projection else scene,
        }
        if key in entries:
            previous = entries[key]
            if (previous['speaker'], previous['text'], previous['kind']) != (speaker, text, kind):
                raise ValueError('Voice-key collision: ' + key)
            if projection and previous['conversation'] != 'M06WaltonHolo':
                raise ValueError('Conflicting processing roles: ' + key)
        else:
            entries[key] = record
        scenes.setdefault(scene, []).append({
            'key': key, 'branch': branch_name, 'document_line': line_number,
        })

    for line_number, raw in enumerate(source.splitlines(), 1):
        header = re.match(r'### ((?:NY-G|HK-)\d+)\b', raw)
        if header:
            section = header.group(1)
            branch, mode = 'main', 'direct'
        elif raw.startswith('### Terzo documento:'):
            section, branch, mode = 'evidence', 'main', 'direct'
        if raw.startswith('Se Anna '):
            branch = 'anna-dead'
        elif raw.startswith('Se Max è già'):
            branch = 'max-met'
        elif raw.startswith('Se Max non '):
            branch = 'max-not-met'
        elif raw.startswith('Poi, se JC '):
            branch = 'yuen-question'
        elif raw.startswith('**A. '):
            branch = 'sword-to-max'
        elif raw.startswith('**B. '):
            branch = 'evidence-to-gordon'
        elif raw.startswith('**C. '):
            branch = 'sword-retained'
        elif raw.startswith("Se manca la lettura"):
            branch = 'helibase-record-not-read'
        speech = re.match(r'^\*\*([A-Z ,]+):\*\*\s+(.+?)\s*$', raw)
        if not speech:
            continue
        if section is None:
            raise ValueError('Speech without scene: line ' + str(line_number))
        label, text = speech.groups()
        parts = [part.strip() for part in label.split(',')]
        speaker = SPEAKERS[parts[0]]
        if 'REGISTRAZIONE' in parts:
            mode = 'projection'
        elif 'INFOLINK' in parts:
            mode = 'radio'
        # Both voices in the hologram keep direct conversation lookup keys;
        # local DSP simulates their projected audio.
        add(section, speaker, text,
            'infolink' if mode == 'radio' and speaker == 'WaltonSimons' else 'con',
            branch, projection=mode == 'projection', line_number=line_number)
    for scene, speaker, text, condition in ALTERNATIVES:
        add(scene, speaker, text,
            'infolink' if scene == 'HK-14' else 'con',
            branch_name=condition)
    return list(entries.values()), scenes


def prepare():
    CACHE.mkdir(parents=True, exist_ok=True)
    previous_plan = json.loads(PLAN.read_text(encoding='utf-8')) if PLAN.exists() else {}
    calibration = json.loads((RUNTIME_CACHE / 'calibration.json').read_text(encoding='utf-8'))
    n.save(CACHE / 'calibration.json', calibration)
    n.OUT = CACHE
    lines, scenes = dialogue()
    plan = n.author_plan(calibration, lines, PLAN)
    for line in plan['lines'].values():
        line['intent'] = intent(line)
        if line['speaker'] == 'GuntherHermann':
            tag = 'firm, restrained' if line['scene'] == 'NY-G01' else 'serious, restrained'
        elif line['speaker'] == 'ScientistConsulting':
            tag = 'urgent, restrained'
        else:
            tag = line['delivery_tags']
        line['delivery_tags'] = tag
        line['tts_text'] = '[' + tag + '] ' + line['tts_text'].split('] ', 1)[1]
        # Retain natural pauses by changing tempo only to the nearest acceptable
        # boundary. Never force every phrase onto the center of the fitted range.
        line['tempo_target'] = 'nearest_boundary'
    plan.update(
        revision='campaign-rewrite-20261006-v4',
        status='draft-audio-not-linked-to-runtime',
        source_sha256=n.sha(DOCUMENT),
        source_document=str(DOCUMENT),
        scenes=scenes,
    )
    voices = m.load_voices()
    absent = [speaker for speaker in {x['speaker'] for x in lines} if not voices.get(speaker)]
    if absent:
        raise ValueError('No configured clone: ' + ', '.join(absent))
    receipts_path = CACHE / 'receipts.json'
    receipts = json.loads(receipts_path.read_text(encoding='utf-8')) if receipts_path.exists() else {}
    candidates = list(receipts.values())
    runtime_receipts = json.loads((RUNTIME_CACHE / 'receipts.json').read_text(encoding='utf-8'))
    candidates += list(runtime_receipts.values())
    reused, new = [], []
    (CACHE / 'raw').mkdir(exist_ok=True)
    for key, line in plan['lines'].items():
        settings = n.settings_for(line, plan)
        for candidate in candidates:
            if (candidate.get('speaker') != line['speaker']
                    or candidate.get('text') != line['text']
                    or candidate.get('tts_text') != line['tts_text']
                    or candidate.get('settings') != settings):
                continue
            old_key = candidate['key']
            seed = candidate.get('fingerprint_seed', int(old_key[1:]))
            payload = {'voice_id': voices[line['speaker']], 'text': line['tts_text'],
                       'settings': settings, 'seed': seed}
            fingerprint = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()
            if fingerprint != candidate.get('fingerprint'):
                continue
            raw_paths = (CACHE / 'raw' / (old_key + '.mp3'),
                         RUNTIME_CACHE / 'raw' / (old_key + '.mp3'))
            raw = next((p for p in raw_paths
                        if p.exists() and n.sha(p) == candidate.get('raw_sha256')), None)
            if raw is None:
                continue
            target = CACHE / 'raw' / (key + '.mp3')
            if raw != target:
                shutil.copy2(raw, target)
            line['seed'] = seed
            migrated = {**candidate, **line, 'fingerprint_seed': seed,
                        'fingerprint': fingerprint, 'migrated_from': old_key}
            wav_paths = (CACHE / (old_key + '.wav'), RUNTIME_CACHE / (old_key + '.wav'))
            wav = next((p for p in wav_paths
                        if p.exists() and n.sha(p) == candidate.get('sha256')), None)
            same_processing = candidate.get('processing_fingerprint') == n.processing_fingerprint(line)
            migrated['valid'] = bool(candidate.get('valid') and same_processing and wav)
            if migrated['valid'] and wav != CACHE / (key + '.wav'):
                shutil.copy2(wav, CACHE / (key + '.wav'))
            receipts[key] = migrated
            reused.append(key)
            break
        else:
            new.append(key)
    n.save(receipts_path, receipts)
    plan['reused_raw_takes'], plan['new_takes'] = reused, new
    # Replanning a finished batch must not misreport its new performances as
    # initial cache hits. Preserve the first plan's counts for this exact script.
    if previous_plan.get('source_sha256') == plan['source_sha256']:
        plan['generation_baseline'] = previous_plan.get('generation_baseline', {
            'new_takes': previous_plan['new_takes'],
            'reused_raw_takes': previous_plan['reused_raw_takes'],
        })
    else:
        plan['generation_baseline'] = {'new_takes': new, 'reused_raw_takes': reused}
    n.save(PLAN, plan)
    print('Draft lines:', len(lines), 'Cached raw:', len(reused), 'New TTS:', len(new), flush=True)
    print('Speakers:', dict(Counter(x['speaker'] for x in lines)), flush=True)
    print('New prompted characters:', sum(len(plan['lines'][k]['tts_text']) for k in new), flush=True)
    return plan


def preview(plan, scene, destination):
    silence = bytes(int(n.RATE * .28) * 2)
    chunks = [silence]
    selected = [x for x in plan['scenes'][scene] if x['branch'] == 'main']
    for item in selected:
        with wave.open(str(CACHE / (item['key'] + '.wav'))) as reader:
            chunks.append(reader.readframes(reader.getnframes()))
        chunks.append(silence)
    if not selected:
        raise ValueError('No main dialogue in preview scene')
    n.write_pcm(CACHE / destination, b''.join(chunks))


def report(plan, receipts):
    baseline = plan.get('generation_baseline', plan)
    n.save(CACHE / 'summary.json', {
        'status': plan['status'], 'source_sha256': plan['source_sha256'],
        'lines': len(plan['lines']), 'new_tts': len(baseline['new_takes']),
        'reused_raw': len(baseline['reused_raw_takes']),
        'max_true_peak_dbtp': max(receipts[k]['input_tp'] for k in plan['lines']),
        'max_loudness_error_lu': max(abs(receipts[k]['input_i'] - x['target_lufs'])
                                   for k, x in plan['lines'].items()),
        'speakers': dict(Counter(x['speaker'] for x in plan['lines'].values())),
    })
    for scene, name in [('NY-G01', 'Gunther_JC_preview.wav'),
                        ('HK-03', 'Max_JC_preview.wav'),
                        ('evidence', 'Tong_JC_preview.wav')]:
        preview(plan, scene, name)
    rows = ['# Campagna riscritta — audio V4', '',
            'Audio della riscrittura pronti per integrazione; queste battute non sono ancora collegate al gioco.', '',
            '| Voce | Canale | Audio | Secondi | LUFS | Testo |',
            '| --- | --- | --- | --- | --- | --- |']
    for key, line in plan['lines'].items():
        receipt = receipts[key]
        rows.append('| %s | %s | %s.wav | %.2f | %.2f | %s |' %
                    (line['speaker'], line.get('processing_channel', line['channel']),
                     key, receipt['seconds'], receipt['input_i'], line['text'].replace('|', '\\|')))
    (CACHE / 'report.md').write_text('\n'.join(rows) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['plan', 'generate', 'verify'])
    parser.add_argument('--only', help='Generate only this speaker.')
    parser.add_argument('--process-only', action='store_true')
    args = parser.parse_args()
    if args.command == 'plan':
        prepare()
        return
    n.OUT = CACHE
    plan = json.loads(PLAN.read_text(encoding='utf-8'))
    if n.sha(DOCUMENT) != plan['source_sha256']:
        raise ValueError('Rewrite changed; prepare the plan again before generation.')
    if args.command == 'generate':
        receipts = json.loads((CACHE / 'receipts.json').read_text(encoding='utf-8'))
        pending = [line for key, line in plan['lines'].items()
                   if (not args.only or line['speaker'] == args.only)
                   and not (receipts.get(key, {}).get('valid')
                            and receipts[key].get('processing_fingerprint') == n.processing_fingerprint(line)
                            and (CACHE / (key + '.wav')).exists()
                            and receipts[key].get('sha256') == n.sha(CACHE / (key + '.wav')))]
        print('Pending generation/processing:', len(pending), flush=True)
        n.generate(pending, plan, process_only=args.process_only)
        if args.only:
            n.verify(plan, keys=[k for k, line in plan['lines'].items() if line['speaker'] == args.only])
            return
    receipts = n.verify(plan)
    if n.sha(DOCUMENT) != plan['source_sha256']:
        raise ValueError('Rewrite changed during generation; refresh draft mapping.')
    report(plan, receipts)


if __name__ == '__main__':
    main()
