"""Offline regression checks for sibilance control and final PCM peak safety."""
import copy
import json
from pathlib import Path

import numpy as np
import natural_voices as n


def main():
    folder = n.OUT / 'dynamics_checks'
    folder.mkdir(parents=True, exist_ok=True)
    rate = n.RATE
    t = np.arange(rate * 3) / rate
    gate = ((t > .6) & (t < 1.0)) | ((t > 1.6) & (t < 2.0))
    # Known low-frequency vowel component plus loud high-frequency bursts.
    signal = .15 * np.sin(2 * np.pi * 700 * t) + gate * .35 * np.sin(2 * np.pi * 5500 * t)
    source = folder / 'vowel_and_sibilants.wav'
    n.write_pcm(source, np.rint(signal * 32767).astype('<i2').tobytes())
    mix = json.loads((n.HERE / 'mix_profile.json').read_text(encoding='utf-8'))
    line = {'key': 'test', 'deesser': mix['speaker_channels']['WaltonSimons/radio']['deesser']}
    deessed = folder / 'deessed.wav'
    n.ffmpeg(source, deessed, [n.deesser_filter(line)])
    processed, _ = n.read(deessed)
    span = (t > .65) & (t < .95)

    def component(x, frequency):
        phase = np.exp(-2j * np.pi * frequency * t[span])
        return abs(np.mean(x[span] * phase))

    high_db = 20 * np.log10(component(processed, 5500) / component(signal, 5500))
    low_db = 20 * np.log10(component(processed, 700) / component(signal, 700))
    assert high_db < -1, ('Sibilants were not reduced', high_db)
    assert abs(low_db) < .75, ('Vowel body changed too much', low_db)

    hot = folder / 'hot_input_limited.wav'
    n.ffmpeg(source, hot, ['volume=20dB', n.deesser_filter(line), 'aresample=88200',
                          'alimiter=limit=0.749894:attack=2:release=60:level=false:latency=true',
                          'aresample=22050'])
    measured = n.stats(hot)
    assert measured['input_tp'] <= -2.0, measured
    assert measured['sample_peak_db'] <= -2.0, measured

    plan = json.loads(n.PLAN.read_text(encoding='utf-8'))
    n.apply_mix_profile(plan)
    entry = next(iter(plan['lines'].values()))
    changed = copy.deepcopy(entry)
    changed['deesser']['threshold_db'] = -15
    assert n.processing_fingerprint(changed) != n.processing_fingerprint(entry)
    changed = copy.deepcopy(entry)
    changed['limiter_ceiling_db'] = -3
    assert n.processing_fingerprint(changed) != n.processing_fingerprint(entry)
    summary = {'sibilant_change_db': float(high_db), 'vowel_change_db': float(low_db),
               'hot_input_true_peak_dbtp': measured['input_tp'],
               'hot_input_sample_peak_dbfs': measured['sample_peak_db'],
               'processing_cache_invalidated_by_profile_change': True}
    n.save(folder / 'results.json', summary)
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
