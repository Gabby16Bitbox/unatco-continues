"""Apply the shared dialogue mix to protected, already verified WAVs locally.

Requires natural_v4/mix_balance.json and its complete pre-mix audio backup.
No TTS requests, voice changes, tempo filters or replacement performances.
"""
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import math
import os
from pathlib import Path
import threading
import wave

import make_voices as m
import natural_voices as n


def main():
    audit_path = n.OUT / 'mix_balance.json'
    audit = json.loads(audit_path.read_text(encoding='utf-8'))
    plan = json.loads(n.PLAN.read_text(encoding='utf-8'))
    if set(plan['lines']) != set(audit['lines']) or set(plan['lines']) != {line['key'] for line in m.extract()}:
        raise ValueError('Dialogue changed since the protected mix backup')
    current = {path.name: n.sha(path) for path in Path(m.SRC).glob('*.uc')
               if not path.name.endswith('CheckCommandlet.uc')}
    if current != audit['source_hashes']:
        raise ValueError('Game code changed since the protected mix backup')
    n.apply_mix_profile(plan)
    n.save(n.PLAN, plan)
    receipt_path = n.OUT / 'receipts.json'
    receipts = json.loads(receipt_path.read_text(encoding='utf-8'))
    lock = threading.Lock()

    def job(key, line):
        old = audit['lines'][key]
        source = Path(audit['backup']) / 'audio' / (key + '.wav')
        if n.sha(source) != old['old_hash']:
            raise ValueError('Protected performance changed: ' + key)
        target = n.OUT / (key + '.wav')
        previous = receipts[key]
        revision = plan['mix_profile']['revision']
        if (previous.get('mix_revision') == revision and previous.get('valid')
                and target.exists() and previous.get('sha256') == n.sha(target)):
            return
        staged = n.OUT / 'work' / (key + '_mix.wav')
        gain = line['target_lufs'] - old['old_lufs']
        ceiling = -1.5
        use_limiter = old['old_peak'] + gain > ceiling
        for _ in range(10):
            filters = ['volume=%.6fdB' % gain]
            if use_limiter:
                filters = ['aresample=88200', *filters,
                           'alimiter=limit=%.6f:attack=2:release=60:level=false:latency=true' % (10 ** (ceiling / 20)),
                           'aresample=22050']
            n.ffmpeg(source, staged, filters)
            result = n.stats(staged)
            if result['input_tp'] > -1.0 and not use_limiter:
                use_limiter = True
                continue
            if abs(result['input_i'] - line['target_lufs']) <= .20:
                break
            gain += line['target_lufs'] - result['input_i']
        with wave.open(str(staged), 'rb') as reader:
            if reader.getnframes() != old['frames']:
                raise ValueError('Mix changed the number of PCM frames: ' + key)
            if (reader.getnchannels(), reader.getsampwidth(), reader.getframerate()) != (1, 2, n.RATE):
                raise ValueError('Mix changed the audio format: ' + key)
        lo, hi = line['duration_range']
        duration_ok = lo - .03 <= result['seconds'] <= hi + .03
        level_ok = (math.isfinite(result['input_i']) and
                    abs(result['input_i'] - line['target_lufs']) <= line['loudness_tolerance_lu']
                    and result['input_tp'] <= -1.0)
        if not duration_ok or not level_ok:
            raise ValueError('Local mix requires review: ' + key)
        os.replace(staged, target)
        receipt = {**previous, **line, **result, 'valid': True,
                   'duration_ok': duration_ok, 'level_ok': level_ok,
                   'mix_revision': revision, 'mix_source_sha256': old['old_hash'],
                   'mix_gain_db': gain, 'mix_filters': filters}
        with lock:
            receipts[key] = receipt
            n.save(receipt_path, receipts)
        print('%s %s: %.2f -> %.2f LUFS, gain %.2f dB, unchanged %d frames' %
              (key, line['speaker'], old['old_lufs'], result['input_i'], gain, old['frames']), flush=True)

    errors = []
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(job, key, line) for key, line in plan['lines'].items()]
        for future in as_completed(futures):
            try:
                future.result()
            except Exception as error:
                errors.append(str(error))
    if errors:
        raise ValueError('\n'.join(errors))
    audit.update(status='mixed', mix_profile=plan['mix_profile'],
                 max_loudness_error_lu=max(abs(receipts[k]['input_i'] - line['target_lufs'])
                                           for k, line in plan['lines'].items()),
                 api_requests=0, unchanged_frame_counts=True)
    n.save(audit_path, audit)
    print('Mixed %d verified performances locally. Zero API requests; all frame counts unchanged.' % len(plan['lines']), flush=True)


if __name__ == '__main__':
    main()
