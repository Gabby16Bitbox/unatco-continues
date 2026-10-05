"""Calibrate, generate and install restrained V4 dialogue against original audio.

Each line has a duration range fitted to its speaker, pronunciation and pauses,
plus a
reference loudness target. Cache raw takes before processing; apply only after
all lines pass. Remote InfoLink voices are filtered; JC's local replies stay dry.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import threading
import wave

import numpy as np
import make_voices as m
from prepare_samples import Pkg, sound_bytes, decode, RATE, BARK_SPEAKERS
from preview_natural import measure, slice_reference
from analyze_delivery import timing, read

HERE = Path(__file__).resolve().parent
OUT = HERE / 'natural_v4'
REFS = OUT / 'references'
PLAN = HERE / 'delivery_natural_v4.json'
LOCK = threading.Lock()


def save(path, value):
    staged = path.with_suffix(path.suffix + '.tmp')
    staged.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')
    os.replace(staged, path)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def words(text):
    return re.findall(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*", text.lower())


def syllables(word):
    # Approximate English pronunciation length, with the game's acronyms made
    # explicit. Word count alone treats 'JC' and 'UNATCO' like one short word.
    known = {'jc': 2, 'unatco': 3, "unatco's": 3, 'nsf': 3, 'mib': 3, 'mj12': 3, '1997': 5,
             'fema': 2, 'hour': 1, "hour's": 1, 'hours': 1, 'every': 2,
             'everyone': 3, 'fire': 1, 'our': 1, 'your': 1, 'weapons': 2,
             'quiet': 2, 'actually': 4, 'agent': 2, 'denton': 2,
             "doesn't": 2, "didn't": 2, "isn't": 2, "wasn't": 2,
             "shouldn't": 2, "couldn't": 2, "wouldn't": 2}
    if word in known:
        return known[word]
    word = word.replace("'", '')
    count = len(re.findall('[aeiouy]+', word))
    if word.endswith('es') and not word.endswith(('ses', 'xes', 'zes', 'ches', 'shes')):
        count -= 1
    elif word.endswith('ed') and not word.endswith(('ted', 'ded')):
        count -= 1
    elif word.endswith('e') and not word.endswith(('le', 'ye', 'ee')):
        count -= 1
    return max(1, count)


def duration_features(text):
    return [1, sum(syllables(word) for word in words(text)),
            max(0, len(re.findall(r'[.!?]+', text)) - 1)]


def channel(line):
    return 'radio' if line['kind'] == 'infolink' and line['speaker'] != 'JCDenton' else 'direct'


def write_pcm(path, pcm):
    with wave.open(str(path), 'wb') as writer:
        writer.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        writer.writeframes(pcm)


def ffmpeg(source, target, filters):
    subprocess.run([m.FFMPEG, '-y', '-hide_banner', '-loglevel', 'error', '-i', str(source),
                    '-af', ','.join(filters), '-ac', '1', '-ar', str(RATE),
                    '-sample_fmt', 's16', str(target)], check=True, capture_output=True,
                   stdin=subprocess.DEVNULL, timeout=120)


def stats(path):
    signal, rate = read(path)
    if len(signal) < rate * .15 or not np.any(signal):
        raise ValueError('Empty take: ' + str(path))
    loudness = measure(path)
    if not math.isfinite(loudness['input_i']):
        raise ValueError('Unable to measure integrated loudness: ' + str(path))
    return {**loudness, 'seconds': len(signal) / rate, 'sha256': sha(path),
            'sample_peak_db': 20 * math.log10(max(float(np.max(np.abs(signal))), 1e-12))}


def reference_stats(path, record):
    signal, rate = read(path)
    acoustic = timing(signal, rate)
    return {**record, **stats(path), 'file': str(path), 'words': len(words(record['text'])),
            'pause_fraction': acoustic['pause_fraction'], 'bands_pct': acoustic['bands_pct']}


def native_references():
    """Add actual radio recordings and short replies absent from clone samples."""
    pkg = Pkg(str(Path(m.ROOT) / 'DevInstall/System/RevisionConversationsText.u'))
    selected = {name: {'short': [], 'radio': []} for name in m.load_voices()}
    reverse = {'mib': 'MIB'}
    for index, export in enumerate(pkg.exports, 1):
        if pkg.classname(export) != 'ConEventSpeech':
            continue
        prop = {name.lower(): value for name, _, _, value in pkg.props(index)}
        source = prop.get('speakername', '')
        speaker = reverse.get(source.lower(), source)
        if speaker not in selected:
            continue
        if speaker in BARK_SPEAKERS:
            # Mission BindNames can pool other actors. Calibrate canonical
            # variants against the same isolated native bark recordings.
            continue
        con_ref = prop.get('conversation', ('ref', 0))[1]
        speech_ref = prop.get('conspeech', ('ref', 0))[1]
        if con_ref <= 0 or speech_ref <= 0:
            continue
        text = pkg.get(speech_ref, 'speech', '').strip()
        sound_id = pkg.get(speech_ref, 'soundID', -1)
        audio = pkg.get(con_ref, 'audioPackageName', '')
        con_name = str(pkg.get(con_ref, 'conName', ''))
        is_radio = bool(pkg.get(con_ref, 'bDataLinkCon', False)) or con_name.startswith('DL_')
        if not text or '(' in text or sound_id < 0 or not audio:
            continue
        count = len(words(text))
        if is_radio and speaker != 'JCDenton' and 5 <= count <= 38:
            category = 'radio'
        elif not is_radio and 1 <= count <= 4 and audio != 'AIBarks' and 'Bark' not in con_name:
            category = 'short'
        else:
            continue
        selected[speaker][category].append({'speaker': speaker, 'source_speaker': source,
            'text': text, 'conversation': con_name, 'audio_package': audio, 'sound_id': sound_id})
    packages = {}
    result = []
    for speaker, categories in selected.items():
        for category, entries in categories.items():
            entries.sort(key=lambda r: (r['audio_package'] != 'Mission04', r['audio_package'], r['sound_id']))
            seen = set()
            count = 0
            for entry in entries:
                identity = (entry['audio_package'], entry['sound_id'])
                if identity in seen:
                    continue
                seen.add(identity)
                audio = entry['audio_package']
                if audio not in packages:
                    package = Pkg(str(Path(m.ROOT) / ('DevInstall/System/RevisionConversationsAudio' + audio + '.u')))
                    packages[audio] = (package, {e['name']: e for e in package.exports if package.classname(e) == 'Sound'})
                package, exports = packages[audio]
                export = exports.get('ConAudio%s_%d' % identity)
                if export is None:
                    continue
                path = REFS / ('%s_%s_%s_%d.wav' % (speaker, category, audio, entry['sound_id']))
                if not path.exists():
                    write_pcm(path, decode(m.FFMPEG, sound_bytes(package, export)))
                signal, rate = read(path)
                if not .4 <= len(signal) / rate <= 18:
                    continue
                result.append((speaker, 'radio' if category == 'radio' else 'direct', reference_stats(path, entry)))
                count += 1
                if count >= (8 if category == 'radio' else 6):
                    break
    return result


def duration_model(refs):
    # Robust affine fit: short replies retain a natural minimum duration rather
    # than being forced to the same words/minute as a long briefing.
    slopes = [(a['seconds'] - b['seconds']) / (a['words'] - b['words'])
              for i, a in enumerate(refs) for b in refs[:i] if abs(a['words'] - b['words']) >= 4]
    slope = statistics.median(slopes) if slopes else statistics.median(r['seconds'] / r['words'] for r in refs)
    slope = max(.18, min(.45, slope))
    intercept = max(.15, min(.8, statistics.median(r['seconds'] - slope * r['words'] for r in refs)))
    x = np.array([duration_features(ref['text']) for ref in refs], dtype=float)
    y = np.array([ref['seconds'] for ref in refs])
    coefficients = np.linalg.lstsq(x, y, rcond=None)[0]
    for _ in range(10):
        residual = y - x @ coefficients
        scale = max(.1, float(np.median(abs(residual))) * 1.4826)
        weights = np.minimum(1, 1.35 * scale / np.maximum(abs(residual), .001))
        coefficients = np.linalg.lstsq(x * np.sqrt(weights[:, None]), y * np.sqrt(weights), rcond=None)[0]
        coefficients = np.clip(coefficients, [.15, .08, .10], [.8, .3, .35])
    return {'seconds_per_word': slope, 'overhead_seconds': intercept,
            'duration_coefficients': coefficients.tolist(),
            'median_seconds': statistics.median(r['seconds'] for r in refs),
            'median_words_per_minute': statistics.median(r['words'] * 60 / r['seconds'] for r in refs)}


def calibrate():
    REFS.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((HERE / 'samples/manifest.json').read_text(encoding='utf-8'))
    refs = {speaker: {'direct': [], 'radio': []} for speaker in m.load_voices()}
    for speaker, sample in manifest.items():
        if speaker not in refs:
            continue
        for i, clip in enumerate(sample['clips']):
            if re.search(r'Attacking|GoingForAlarm|Gore|Surprised|Combat|Dying', clip['conversation'], re.I):
                continue
            path = REFS / ('%s_direct_%d.wav' % (speaker, i))
            # Clone samples may be replaced with a better isolated source.
            # Index-only cache names cannot identify that change; refresh PCM.
            slice_reference(speaker, clip, path)
            refs[speaker]['direct'].append(reference_stats(path, clip))
    for speaker, kind, record in native_references():
        refs[speaker][kind].append(record)
    profiles = {}
    for speaker, channels in refs.items():
        profiles[speaker] = {}
        for kind, records in channels.items():
            if not records:
                continue
            # Speech paragraphs, not 1-word responses, determine the mix target.
            level_records = [r for r in records if r['seconds'] >= 1.2] or records
            profile = {**duration_model(records), 'target_lufs': statistics.median(r['input_i'] for r in level_records),
                       'reference_count': len(records), 'references': records,
                       'bands_pct': {band: statistics.median(r['bands_pct'][band] for r in records)
                                     for band in records[0]['bands_pct']}}
            profiles[speaker][kind] = profile
            print(speaker, kind, 'n=%d, %.1f words/min, %.2f LUFS' %
                  (len(records), profile['median_words_per_minute'], profile['target_lufs']), flush=True)
    # B's native bark recordings are ~7.5 LU quieter than A. Match new spoken
    # conversations to the route's native A mix, keeping B's timbre and timing.
    if 'UNATCOTroopB' in profiles and 'UNATCOTroop' in profiles:
        second = profiles['UNATCOTroopB']['direct']
        second['original_target_lufs'] = second['target_lufs']
        second['target_lufs'] = profiles['UNATCOTroop']['direct']['target_lufs']
        second['mix_reference'] = 'UNATCOTroop/direct: equal perceived dialogue level across A and B'
    calibration = {'method': 'Original PCM, robust fit to estimated syllables and sentence breaks, per speaker/channel, with 20% or 250ms tolerance. Long soldier dialogue also uses a word-rate floor, capped at 225 words/min, because short native barks should not force full sentences to rush. English syllable counts are approximate. Median integrated LUFS of complete speech; UNATCO A/B dialogue shares native A mix level. Spectral comparisons use different words and are approximate.',
                   'profiles': profiles}
    save(OUT / 'calibration.json', calibration)
    author_plan(calibration)


def author_plan(calibration, lines=None, destination=PLAN):
    prior = json.loads((HERE / 'delivery_plan.json').read_text(encoding='utf-8'))
    review_path = HERE / 'timing_reviews.json'
    timing_reviews = json.loads(review_path.read_text(encoding='utf-8')) if review_path.exists() else {}
    entries = {}
    pronunciations = {"UNATCO's": '/juːˈnætkoʊz/', 'UNATCO': '/juːˈnætkoʊ/',
                      'FEMA': '/ˈfiːmə/', '1997': '/wʌn naɪn naɪn ˈsɛvən/'}
    for line in m.extract() if lines is None else lines:
        kind = channel(line)
        projection = line.get('conversation') == 'M06WaltonHolo' and line['speaker'] in ('WaltonSimons', 'MaggieChow')
        profile_kind = 'radio' if projection and line['speaker'] == 'WaltonSimons' else kind
        profile = calibration['profiles'][line['speaker']][profile_kind]
        features = duration_features(line['text'])
        target = max(.6, float(np.dot(features, profile['duration_coefficients'])))
        # Spoken keypad digits need brief separation. Native short barks do
        # not contain these serial numbers and otherwise underpredict them.
        digit_groups = re.findall(r'\b(?:zero|one|two|three|four|five|six|seven|eight|nine)(?:-(?:zero|one|two|three|four|five|six|seven|eight|nine))+\b', line['text'], re.I)
        digit_pause = .15 * sum(group.count('-') for group in digit_groups)
        # M-J-twelve has three spoken syllables, with brief separation between
        # the initials and number. Treating the whole identifier as one syllable
        # incorrectly forced JC's short questions to the fastest allowed tempo.
        initialism_pause = .20 * len(re.findall(r'\bMJ12\b', line['text'], re.I))
        digit_pause += initialism_pause
        if re.search(r'\bcode\s+is\s+1997\b', line['text'], re.I):
            digit_pause += .45
        target += digit_pause
        if line['speaker'] in BARK_SPEAKERS and len(words(line['text'])) >= 9:
            target = max(target, len(words(line['text'])) * 60 / min(225, profile['median_words_per_minute']))
        if line['speaker'] == 'Red_Arrow_01' and len(words(line['text'])) >= 6:
            target = max(target, len(words(line['text'])) * 60 / min(225, profile['median_words_per_minute']))
        # 20% tolerance plus a small allowance for short, emphatic replies.
        allowance = max(.35 if line['speaker'] == 'JCDenton' else .25, target * .20)
        if line['speaker'] in ('JCDenton', 'GuntherHermann'):
            # Short, level replies vary substantially in the original actor's
            # recordings. Keep their observed timing spread instead of forcing
            # every deadpan answer onto one syllable-rate estimate. Gunther's
            # source set also has substantial sentence-pause variation.
            residuals = [abs(ref['seconds'] - float(np.dot(duration_features(ref['text']), profile['duration_coefficients'])))
                         for ref in profile['references']]
            allowance = max(allowance, float(np.quantile(residuals, .95 if line['speaker'] == 'GuntherHermann' else .90)))
        if line['speaker'] in ('MaggieChow', 'MaxChen', 'GordonQuick', 'TracerTong', 'Red_Arrow_01') and len(words(line['text'])) <= 5:
            # Brief replies are sparse in the new Hong Kong reference sets.
            # Retain observed pause variation without forcing one-word takes
            # onto the longer-sentence estimate or padding them with silence.
            residuals = [abs(ref['seconds'] - float(np.dot(duration_features(ref['text']), profile['duration_coefficients'])))
                         for ref in profile['references']]
            allowance = max(allowance, min(.75, float(np.quantile(residuals, .90))))
        if line['speaker'] == 'WaltonSimons' and profile_kind == 'radio' and len(words(line['text'])) <= 4:
            # His remote reference set contains paragraphs, so extrapolated
            # one-word answers need the measured model's pause uncertainty.
            residuals = [abs(ref['seconds'] - float(np.dot(duration_features(ref['text']), profile['duration_coefficients'])))
                         for ref in profile['references']]
            allowance = max(allowance, min(.6, float(np.quantile(residuals, .90))))
        review = timing_reviews.get(line['key'])
        if review:
            if (review['speaker'], review['text']) != (line['speaker'], line['text']):
                raise ValueError('Timing review belongs to a different utterance: ' + line['key'])
            residuals = [abs(ref['seconds'] - float(np.dot(duration_features(ref['text']), profile['duration_coefficients'])))
                         for ref in profile['references']]
            allowance = max(allowance, float(np.quantile(residuals, review['native_residual_quantile'])))
        spoken = line['text'].replace('...', ',').strip(', ')
        tag = 'matter-of-fact'
        if line['speaker'] == 'JCDenton':
            tag = 'deadpan'
            # Rare, small contrasts in an otherwise level delivery.
            if spoken == "I listened. I didn't agree.":
                spoken = spoken.replace('agree', 'AGREE')
        elif line['speaker'] in ('PaulDenton', 'WaltonSimons') or (line['speaker'] == 'AlexJacobson' and 'new picture' in spoken):
            tag = 'serious, restrained'
        elif line['speaker'] == 'AnnaNavarre' and ('agents die' in spoken or 'walks away' in spoken):
            tag = 'firm, restrained'
        assert words(spoken) == words(line['text'])
        prompted = spoken
        for grapheme, phonemes in pronunciations.items():
            if grapheme == '1997' and not re.search(r'\bcode\s+is\s+1997\b', line['text'], re.I):
                continue
            prompted = re.sub(r'(?<!\w)' + re.escape(grapheme) + r'(?!\w)', lambda match: phonemes, prompted)
        if line['key'] in entries and (entries[line['key']]['speaker'], entries[line['key']]['text'], entries[line['key']]['channel']) != (line['speaker'], line['text'], kind):
            raise ValueError('Voice hash collision: ' + line['key'])
        entries[line['key']] = {**line, 'channel': kind, 'spoken_text': spoken,
            'intent': prior['lines'].get(line['key'], {}).get('intent', 'Restrained delivery appropriate to the scene; review new dialogue in context.'), 'delivery_tags': tag,
            'tts_text': '[%s] %s' % (tag, prompted), 'target_seconds': target,
            'timing_features': {'estimated_syllables': features[1], 'extra_sentence_breaks': features[2], 'digit_pause_seconds': digit_pause},
            'duration_range': [max(.4, target - allowance), target + allowance],
            'target_lufs': profile['target_lufs']}
        if projection:
            entry = entries[line['key']]
            entry['processing_channel'] = 'radio'
            entry['processing_reference'] = 'WaltonSimons'
            entry['processing_reason'] = 'Both actors are projected recordings in M06WaltonHolo; Sound lookup retains the native conversation/direct key.'
            if line['speaker'] == 'MaggieChow':
                simons = calibration['profiles']['WaltonSimons']
                entry['target_lufs'] += simons['radio']['target_lufs'] - simons['direct']['target_lufs']
        if review:
            entries[line['key']]['timing_review'] = review
            entries[line['key']]['tempo_target'] = 'nearest_boundary'
        if initialism_pause:
            entries[line['key']]['tempo_target'] = 'nearest_boundary'
    yes_key = m.voice_key('AnnaNavarre', 'Yes.')
    if yes_key in entries:
        entries[yes_key]['intent'] = 'Anna confirms the threat with a short, level answer.'
    plan = {'revision': 'natural-v4-route-identity', 'model_id': 'eleven_v4',
            'pronunciations': pronunciations,
            'analysis_basis': calibration['method'],
            'settings': {'model_id': 'eleven_v4', 'stability': .9, 'similarity_boost': .75},
            'characters': {speaker: {'settings': {}} for speaker in calibration['profiles']},
            'lines': entries}
    plan['characters']['JCDenton']['settings'] = {'stability': 1.0, 'similarity_boost': .85}
    for speaker in ('UNATCOTroop', 'UNATCOTroopB', 'MJ12Troop', 'MJ12TroopB', 'Jock'):
        if speaker in plan['characters']:
            plan['characters'][speaker]['settings'] = {'stability': .95, 'similarity_boost': .8}
    apply_mix_profile(plan)
    save(destination, plan)
    print('Prepared', len(entries), 'calibrated V4 lines.', flush=True)
    return plan


def apply_mix_profile(plan):
    path = HERE / 'mix_profile.json'
    if not path.exists():
        return
    mix = json.loads(path.read_text(encoding='utf-8'))
    for line in plan['lines'].values():
        kind = line.get('processing_channel', line['channel'])
        line.setdefault('reference_target_lufs', line['target_lufs'])
        line['target_lufs'] = mix['speakers'].get(line['speaker'], mix['channels'][kind])
        line['loudness_tolerance_lu'] = mix['tolerance_lu']
        line['limiter_ceiling_db'] = mix.get('limiter_ceiling_db', -2.0)
        line['processing_revision'] = mix['revision']
        override = mix.get('speaker_channels', {}).get(line['speaker'] + '/' + kind, {})
        line['deesser'] = override.get('deesser', mix['deesser'])
        if 'radio_presence_max_db' in override:
            line['radio_presence_max_db'] = override['radio_presence_max_db']
    plan['mix_profile'] = mix


def processing_filters(line, tempo):
    filters = ['atempo=%.6f' % tempo, 'bass=g=-0.7:f=180:width_type=o:width=1',
               'equalizer=f=3200:width_type=o:width=1:g=0.75',
               'acompressor=threshold=0.0631:ratio=1.25:attack=8:release=90:knee=2.828:makeup=1']
    if line['speaker'] == 'JCDenton':
        # Let the original-sample clone supply JC's texture. Do not brighten it.
        filters = [filters[0], 'treble=g=-1.5:f=3500:width_type=o:width=1', filters[-1]]
    if line.get('processing_channel', line['channel']) == 'radio':
        # Actual InfoLink references below determine the bandwidth. No reverb:
        # the call should sound electronic but remain close and intelligible.
        calibration = json.loads((OUT / 'calibration.json').read_text())
        reference_speaker = line.get('processing_reference', line['speaker'])
        radio = calibration['profiles'][reference_speaker]['radio']['bands_pct']
        direct = calibration['profiles'][reference_speaker]['direct']['bands_pct']
        body_ratio = radio['body_80_250'] / max(direct['body_80_250'], .001)
        clarity_ratio = radio['clarity_2500_6000'] / max(direct['clarity_2500_6000'], .001)
        # Native InfoLink recordings have very little bass and much more
        # 2.5-6kHz energy than in-person recordings. A telephone low-pass at
        # 3.4kHz would lose that characteristic bright, electronic delivery.
        highpass = 1200 if body_ratio < .1 else (220 if body_ratio < .5 else 140)
        lowpass = 6500 if radio['air_6000_10000'] > 2 else (3800 if clarity_ratio < .65 else 5000)
        presence = max(1.2, min(8.0, 5 * math.log10(max(clarity_ratio, 1))))
        presence = min(presence, line.get('radio_presence_max_db', presence))
        filters += ['highpass=f=%d:p=2' % highpass, 'lowpass=f=%d:p=2' % lowpass,
                    'equalizer=f=3200:width_type=o:width=1.5:g=%.3f' % presence]
    return filters


def deesser_filter(line):
    # Band-selective de-essing preserves vowel body during a sibilant. This
    # project's FFmpeg (2023 build) uses a linear internal gain limit; the
    # bell response at its centre is the square of that gain (FFmpeg 6.0
    # af_adynamicequalizer.c). Explicitly cut ABOVE the detection threshold.
    profile = line['deesser']
    if (not 2000 <= profile['frequency_hz'] <= 9000
            or not -60 <= profile['threshold_db'] <= 0
            or not 0 <= profile['max_reduction_db'] <= 12
            or not .3 <= profile['q'] <= 4
            or not 1 <= profile['ratio'] <= 30):
        raise ValueError('Invalid de-esser profile: ' + line['key'])
    return ('adynamicequalizer=threshold=%.8f:dfrequency=%g:dqfactor=%g:'
            'tfrequency=%g:tqfactor=%g:attack=%g:release=%g:ratio=%g:range=%.8f:'
            'mode=cut:direction=upward:dftype=bandpass:tftype=bell:auto=disabled') % (
                10 ** (profile['threshold_db'] / 20), profile['frequency_hz'], profile['q'],
                profile['frequency_hz'], profile['q'], profile['attack_ms'],
                profile['release_ms'], profile['ratio'], 10 ** (profile['max_reduction_db'] / 40))


def processing_fingerprint(line):
    payload = {'version': 'band-deesser-oversampled-limiter-v2',
               'filters': processing_filters(line, 1), 'deesser': deesser_filter(line),
               'revision': line.get('processing_revision'),
               'ceiling_db': line.get('limiter_ceiling_db', -2.0),
               'target_lufs': line['target_lufs'],
               'loudness_tolerance_lu': line.get('loudness_tolerance_lu', .75),
               'target_seconds': line['target_seconds'], 'duration_range': line['duration_range'],
               'tempo_target': line.get('tempo_target')}
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()


def clean_take(source, target):
    decoded = target.with_suffix('.decoded.wav')
    ffmpeg(source, decoded, ['anull'])
    signal, rate = read(decoded)
    # Trim only quiet outer edges, retaining 20ms before / 60ms after speech.
    window = round(rate * .01)
    frames = np.lib.stride_tricks.sliding_window_view(signal, window)[::window]
    active = np.flatnonzero(np.sqrt(np.mean(frames ** 2, axis=1)) > 10 ** (-55 / 20))
    if not len(active):
        raise ValueError('Silent generated voice')
    start = max(0, active[0] * window - round(.02 * rate))
    end = min(len(signal), (active[-1] + 1) * window + round(.06 * rate))
    pcm = np.clip(np.rint(signal[start:end] * 32768), -32768, 32767).astype('<i2').tobytes()
    write_pcm(target, pcm)


def process(line, source):
    clean = OUT / 'work' / (line['key'] + '_clean.wav')
    clean_take(source, clean)
    raw_stats = stats(clean)
    low, high = line['duration_range']
    target = line['target_seconds']
    # Keep a take that already flows within the reference range. Otherwise use
    # a bounded pitch-preserving change, never impose a single cast-wide speed.
    tempo_target = max(low, min(high, raw_stats['seconds'])) if line.get('tempo_target') == 'nearest_boundary' else target
    tempo = 1.0 if low <= raw_stats['seconds'] <= high else raw_stats['seconds'] / tempo_target
    tempo = max(.80, min(1.22, tempo))
    prepared = OUT / 'work' / (line['key'] + '_prepared.wav')
    filters = processing_filters(line, tempo)
    ffmpeg(clean, prepared, filters)
    prepared_stats = stats(prepared)
    output = OUT / (line['key'] + '.wav')
    gain = line['target_lufs'] - prepared_stats['input_i']
    ceiling_db = min(-1.1, line.get('limiter_ceiling_db', -2.0))
    limiter_db = ceiling_db - .2
    # Fixed gain and a safety limiter at 4x sample rate. Match original speech
    # level without copying original clipped peaks or adding automatic AGC.
    for attempt in range(10):
        # De-ess after level matching, so quiet clone responses trigger the
        # same detector as louder ones. The limiter's auto gain stays disabled.
        final_filters = ['volume=%.5fdB' % gain, deesser_filter(line), 'aresample=88200',
            'alimiter=limit=%.6f:attack=2:release=60:level=false:latency=true' % (10 ** (limiter_db / 20)), 'aresample=22050']
        ffmpeg(prepared, output, final_filters)
        result = stats(output)
        peak_ok = result['input_tp'] <= ceiling_db - .05 and result['sample_peak_db'] <= ceiling_db
        if peak_ok and abs(result['input_i'] - line['target_lufs']) <= min(.65, line.get('loudness_tolerance_lu', .75) * .8):
            break
        if not peak_ok:
            limiter_db -= max(result['input_tp'] - ceiling_db + .1,
                              result['sample_peak_db'] - ceiling_db + .1)
        if attempt < 9:
            gain += line['target_lufs'] - result['input_i']
    duration_ok = low - .03 <= result['seconds'] <= high + .03
    level_ok = abs(result['input_i'] - line['target_lufs']) <= line.get('loudness_tolerance_lu', .75) and peak_ok
    return {**result, 'tempo': tempo, 'gain_db': gain, 'filters': filters, 'limiter_ceiling_db': ceiling_db,
            'final_filters': final_filters, 'limiter_internal_db': limiter_db,
            'processing_fingerprint': processing_fingerprint(line),
            'raw_seconds': raw_stats['seconds'], 'duration_ok': duration_ok, 'level_ok': level_ok,
            'valid': duration_ok and level_ok}


def settings_for(line, plan):
    return {**plan['settings'], **plan['characters'][line['speaker']]['settings'], **line.get('settings', {})}


def generate(selected, plan, process_only=False):
    for folder in ('raw', 'work'):
        (OUT / folder).mkdir(parents=True, exist_ok=True)
    cfg = json.loads(Path(m.VOICES).read_text())
    receipt_path = OUT / 'receipts.json'
    receipts = json.loads(receipt_path.read_text()) if receipt_path.exists() else {}
    api_key = None

    def job(line):
        nonlocal api_key
        key = line['key']
        settings = settings_for(line, plan)
        seed = line.get('seed', int(key[1:]))
        payload = {'voice_id': cfg[line['speaker']], 'text': line['tts_text'],
                   'settings': settings, 'seed': seed}
        fingerprint = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()
        prior = receipts.get(key, {})
        source = OUT / 'raw' / (key + '.mp3')
        receipt = {**line, 'fingerprint': fingerprint, 'fingerprint_seed': seed, 'settings': settings}
        for attempt in range(2):
            cached = source.exists() and prior.get('fingerprint') == fingerprint and prior.get('raw_sha256') == sha(source)
            if not cached:
                if process_only:
                    raise ValueError('No matching cached take: ' + key)
                with LOCK:
                    if api_key is None:
                        api_key = m.api_key()
                print('Generate', line['speaker'], key, '(attempt %d)' % (attempt + 1), flush=True)
                receipt['seed'] = seed + attempt
                api_receipt = m.tts(api_key, cfg[line['speaker']], line['tts_text'], str(source),
                                    settings, seed=receipt['seed'])
                receipt.update(api_receipt)
                receipt['raw_sha256'] = sha(source)
                with LOCK:
                    receipts[key] = receipt.copy()
                    save(receipt_path, receipts)
            else:
                receipt.update({k: v for k, v in prior.items() if k in ('request_id', 'character_cost', 'raw_sha256', 'seed')})
            processed = process(line, source)
            receipt.update(processed)
            with LOCK:
                receipts[key] = receipt.copy()
                save(receipt_path, receipts)
            print('%s %.2fs (%.2f-%.2f), %.2f LUFS (target %.2f), tempo %.3f: %s' %
                  (key, receipt['seconds'], *line['duration_range'], receipt['input_i'],
                   line['target_lufs'], receipt['tempo'], 'OK' if receipt['valid'] else 'RETRY'), flush=True)
            if receipt['valid']:
                return
            if receipt['duration_ok'] and not receipt['level_ok']:
                # A mix/limiter adjustment is local. Do not spend credits on
                # another performance merely because its gain needs review.
                raise ValueError('Review local mix (cached raw take retained): ' + key)
            if process_only:
                break
            prior = {}
        raise ValueError('Review required: ' + key)

    with ThreadPoolExecutor(max_workers=2) as executor:
        futures = [executor.submit(job, line) for line in selected]
        errors = []
        for future in as_completed(futures):
            try:
                future.result()
            except Exception as error:
                errors.append(str(error))
        if errors:
            raise ValueError('\n'.join(errors))


def verify(plan, keys=None):
    receipts = json.loads((OUT / 'receipts.json').read_text())
    failures = []
    cfg = json.loads(Path(m.VOICES).read_text())
    for key, line in plan['lines'].items():
        if keys is not None and key not in keys:
            continue
        path = OUT / (key + '.wav')
        receipt = receipts.get(key, {})
        payload = {'voice_id': cfg[line['speaker']], 'text': line['tts_text'],
                   'settings': settings_for(line, plan), 'seed': line.get('seed', int(key[1:]))}
        fingerprint = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()
        if (not path.exists() or not receipt.get('valid') or receipt.get('sha256') != sha(path)
                or receipt.get('fingerprint') != fingerprint
                or receipt.get('processing_fingerprint') != processing_fingerprint(line)):
            failures.append(key)
            continue
        actual = stats(path)
        lo, hi = line['duration_range']
        if (not lo - .03 <= actual['seconds'] <= hi + .03
                or abs(actual['input_i'] - line['target_lufs']) > line.get('loudness_tolerance_lu', .75)
                or actual['input_tp'] > line.get('limiter_ceiling_db', -2.0) - .05
                or actual['sample_peak_db'] > line.get('limiter_ceiling_db', -2.0)):
            failures.append(key)
        with wave.open(str(path)) as reader:
            if (reader.getnchannels(), reader.getsampwidth(), reader.getframerate()) != (1, 2, RATE):
                failures.append(key)
        if words(m.undo_pronunciation(re.sub(r'\[[^\]]*\]', '', line['tts_text']), plan)) != words(line['text']):
            failures.append(key)
    if failures:
        raise ValueError('Invalid or missing takes: ' + ', '.join(failures))
    print('Verified', len(plan['lines']) if keys is None else len(keys), 'WAVs: duration, mix loudness, sample/true peak, DSP profile, format, hashes, prompt words.', flush=True)
    return receipts


def apply(plan, keys=None):
    current = {line['key']: line for line in m.extract()}
    if set(current) != set(plan['lines']) or any(
            any(current[key].get(field) != line.get(field)
                for field in ('speaker', 'text', 'kind', 'conversation', 'file'))
            for key, line in plan['lines'].items()):
        raise ValueError('Dialogue changed while generating; refresh the plan before applying.')
    receipts = verify(plan, keys)
    selected = list(plan['lines']) if keys is None else keys
    backup = HERE / 'backups' / ('natural-v4-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
    backup.mkdir(parents=True, exist_ok=False)
    shutil.copy2(m.VOICES, backup / 'voices.json')
    for key in selected:
        target = Path(m.OUT_SOUNDS) / (key + '.wav')
        if target.exists():
            shutil.copy2(target, backup / target.name)
    for key in selected:
        target = Path(m.OUT_SOUNDS) / (key + '.wav')
        staged = target.with_suffix('.wav.new')
        shutil.copy2(OUT / target.name, staged)
        os.replace(staged, target)
    cfg = json.loads(Path(m.VOICES).read_text())
    cfg['_settings'] = plan['settings']
    cfg['_delivery_plan'] = PLAN.name
    cfg['_info'] = 'Restrained V4. Regenerate and calibrate with natural_voices.py; timing/loudness targets are in delivery_natural_v4.json.'
    cfg['_fx'] = {} # The calibrated pipeline supplies each channel's processing.
    save(Path(m.VOICES), cfg)
    m.write_class()
    save(OUT / 'applied.json', {'backup': str(backup), 'lines': len(selected), 'revision': plan['revision'], 'keys': selected})
    if keys is None:
        write_report(plan, receipts, backup)
    print('Applied calibrated V4 voices. Backup:', backup, flush=True)


def write_report(plan, receipts, backup):
    calibration = json.loads((OUT / 'calibration.json').read_text())
    report = ['# Dialoghi V4 calibrati — ' + datetime.now().strftime('%d/%m/%Y'), '',
        '%d battute applicate ai sorgenti; compilazione e installazione sono passaggi successivi.' % len(plan['lines']), '',
        'Direzione sobria: stabilita 0,90, somiglianza 0,75; JC usa il nuovo clone sobrio, '
        'stabilita 1,00, somiglianza 0,85 e deadpan. '
        'Soldati e Jock usano stabilita 0,95 e somiglianza 0,80. '
        'Minacce e avvertimenti restano contenuti. Nessun effetto metallico aggiunto a Gunther.', '',
        'Confronto su %d registrazioni originali, incluse vere chiamate InfoLink. '
        'I nuovi testi sono diversi dagli originali: i tempi sono stime per personaggio e canale, '
        'basate su pronuncia approssimata e pause tra frasi. Tolleranza del 20%% o 250 ms; '
        'per le risposte brevi di JC si usa anche il 90esimo percentile dello scarto dei suoi originali '
        '(circa 575 ms). UNATCO usa una pronuncia IPA nel solo prompt audio; '
        'nessun tag cambia le parole nel gioco.' % sum(profile['reference_count'] for channels in calibration['profiles'].values() for profile in channels.values()), '',
        'Le pause interne sono conservate. Rimosso soltanto il silenzio esterno; '
        'correzione di velocita senza cambiare altezza, limitata a 0,80–1,22. '
        'EQ lieve e compressione 1,25:1. Livello misurato dopo conversione finale, '
        'con de-esser lieve per tutti, piu deciso per Simons via radio, e limiter sempre attivo. '
        'Il tetto viene verificato dopo il ricampionamento finale. '
        'Errore massimo %.2f LU, picco massimo %.2f dBTP.' %
        (max(abs(receipts[key]['input_i'] - line['target_lufs']) for key, line in plan['lines'].items()),
         max(receipts[key]['input_tp'] for key in plan['lines'])), '',
        'Le varianti UNATCO A/B usano lo stesso livello di dialogo del profilo comune: '
        'i barks originali B erano circa 7,5 LU piu bassi. Il timbro e il modello dei tempi '
        'rimangono separati. Per le frasi lunghe dei soldati si applica anche un riferimento '
        'massimo di 225 parole/min, evitando di estrapolare un ritmo troppo rapido dai soli barks brevi.', '',
        'Radio: filtro passa-alto 1,2 kHz, passa-basso 6,5 kHz, presenza intorno a 3,2 kHz. '
        'La banda deriva dai confronti con i file InfoLink originali di Alex e Paul. '
        'E una simulazione: lo spettro dipende anche dalle parole e dal rumore della registrazione. '
        'Le risposte locali di JC restano senza filtro radio.', '',
        'Il codice riproduce le voci con guadagno esplicito 1,0 e le stesse regole di raggio del suono di '
        'ConPlay. Il confronto LUFS non sostituisce la valutazione finale del mix in gioco.', '',
        '| Personaggio/canale | Originali | Livello originale | Nuove battute |',
        '|---|---:|---:|---:|']
    for speaker, channels in calibration['profiles'].items():
        for kind, profile in channels.items():
            count = sum(line['speaker'] == speaker and line['channel'] == kind for line in plan['lines'].values())
            report.append('| %s / %s | %d | %.2f LUFS | %d |' %
                (speaker, kind, profile['reference_count'], profile.get('original_target_lufs', profile['target_lufs']), count))
    if plan.get('mix_profile'):
        mix = plan['mix_profile']
        report += ['', 'Mix comune persistente: NPC diretti %.1f LUFS; radio/proiezioni %.1f LUFS; '
                   'JC %.1f LUFS. I riferimenti originali determinano timbro e tempi; il livello personale '
                   'non determina piu il volume di ciascun interlocutore. Tolleranza massima %.2f LU. '
                   'Le take compatibili vengono riusate dalla cache senza richieste TTS.' %
                   (mix['channels']['direct'], mix['channels']['radio'], mix['speakers']['JCDenton'], mix['tolerance_lu'])]
    report += ['', '## Verifica delle take', '',
        '| Sound | Personaggio | Tempo previsto | WAV finale | LUFS | Battuta |',
        '|---|---|---:|---:|---:|---|']
    for key, line in plan['lines'].items():
        info = receipts[key]
        report.append('| %s | %s | %.2f–%.2f s | %.2f s | %.2f | %s |' %
            (key, line['speaker'], *line['duration_range'], info['seconds'], info['input_i'], line['text']))
    report += ['', 'Backup WAV/configurazione: `%s`.' % backup, '',
        '[Prompting ufficiale ElevenLabs](https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices): '
        'punteggiatura e indicazioni di recitazione coerenti con la voce. '
        '[Filtri FFmpeg](https://ffmpeg.org/ffmpeg-filters.html): atempo, equalizer, acompressor, adynamicequalizer, alimiter.', '']
    (OUT / 'report.md').write_text('\n'.join(report), encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('calibrate', 'plan', 'generate', 'verify', 'apply'))
    parser.add_argument('--only')
    parser.add_argument('--keys', nargs='+')
    parser.add_argument('--process-only', action='store_true', help='Reprocess cached raw audio; never call ElevenLabs')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    if args.command == 'calibrate':
        calibrate()
        return
    plan = json.loads(PLAN.read_text(encoding='utf-8'))
    if set(plan['lines']) != {line['key'] for line in m.extract()}:
        raise ValueError('Source dialogue changed; calibrate again before generation')
    selected = [line for line in plan['lines'].values() if (not args.only or args.only == line['speaker'])
                and (not args.keys or line['key'] in args.keys)]
    if not selected:
        raise ValueError('No selected dialogue')
    if args.command == 'plan':
        for line in selected:
            print(line['speaker'], line['key'], line['channel'], '%.2f-%.2fs, %.2f LUFS' %
                  (*line['duration_range'], line['target_lufs']), line['tts_text'])
    elif args.command == 'generate':
        generate(selected, plan, process_only=args.process_only)
    elif args.command == 'verify':
        verify(plan)
    elif args.command == 'apply':
        if args.only or args.keys:
            raise ValueError('Apply requires the complete verified set')
        apply(plan)


if __name__ == '__main__':
    main()
