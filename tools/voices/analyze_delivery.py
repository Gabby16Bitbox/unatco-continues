"""Compare acoustic timing and spectrum of reference speech and V4 previews.

These measurements describe rhythm/energy, not emotion or intelligibility.
References use different words, so spectral differences are tentative.
"""
import argparse
import json
from pathlib import Path
import wave

import numpy as np

HERE = Path(__file__).resolve().parent
PREVIEW = HERE / 'previews/natural_v4'


def read(path):
    with wave.open(str(path), 'rb') as reader:
        assert reader.getnchannels() == 1 and reader.getsampwidth() == 2
        rate = reader.getframerate()
        signal = np.frombuffer(reader.readframes(reader.getnframes()), dtype='<i2').astype(float) / 32768
    return signal, rate


def timing(signal, rate):
    hop = round(rate * 0.01)
    window = round(rate * 0.02)
    frames = np.lib.stride_tricks.sliding_window_view(signal, window)[::hop]
    rms_db = 20 * np.log10(np.maximum(np.sqrt(np.mean(frames ** 2, axis=1)), 1e-8))
    # Adaptive energy gate: same relation to normal speech level in every file.
    threshold = max(float(np.percentile(rms_db, 90)) - 20, -50)
    quiet = rms_db < threshold
    edges = np.flatnonzero(np.diff(np.r_[False, quiet, False].astype(int)))
    pauses = []
    spans = []
    for start, end in zip(edges[::2], edges[1::2]):
        if start == 0 or end == len(quiet):
            continue
        duration = (end - start) * hop / rate
        if duration >= 0.12:
            pauses.append(duration)
            spans.append([round(start * hop / rate, 3), round(end * hop / rate, 3)])
    active = rms_db[~quiet]
    power = np.abs(np.fft.rfft(frames[~quiet] * np.hanning(window), n=1024, axis=1)) ** 2
    frequencies = np.fft.rfftfreq(1024, 1 / rate)
    power = np.sum(power, axis=0)
    total = np.sum(power[(frequencies >= 80) & (frequencies < 10000)])
    bands = {'body_80_250': (80, 250), 'low_mid_250_1000': (250, 1000),
             'mid_1000_2500': (1000, 2500), 'clarity_2500_6000': (2500, 6000),
             'air_6000_10000': (6000, 10000)}
    return {
        'seconds': len(signal) / rate,
        'pause_seconds': [round(value, 3) for value in pauses], 'pause_spans': spans,
        'median_pause_seconds': float(np.median(pauses)) if pauses else None,
        'pause_fraction': sum(pauses) / (len(signal) / rate),
        'active_dynamic_range_p90_p10_db': float(np.percentile(active, 90) - np.percentile(active, 10)),
        'bands_pct': {name: 100 * float(np.sum(power[(frequencies >= low) & (frequencies < high)])) / total
                      for name, (low, high) in bands.items()},
        'gate_dbfs': threshold,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--refine', action='store_true', help='Analyze the separate second preview')
    args = parser.parse_args()
    preview_dir = HERE / 'previews/natural_v4_r2' if args.refine else PREVIEW
    review = json.loads((preview_dir / 'review.json').read_text(encoding='utf-8'))
    result = {'method': '20ms RMS windows, 10ms hop, internal quiet runs >=120ms; active-frame FFT. Original words differ; no claim of automatic emotion analysis.', 'characters': {}}
    for speaker, info in review.items():
        refs = []
        for ref in info['original_references']:
            signal, rate = read(ref['file'])
            refs.append({'text': ref['text'], **timing(signal, rate), 'words_per_minute': ref['words_per_minute']})
        signal, rate = read(info['preview_file'])
        candidate = timing(signal, rate)
        original_pauses = [value for ref in refs for value in ref['pause_seconds']]
        medians = {
            'words_per_minute': float(np.median([ref['words_per_minute'] for ref in refs])),
            'pause_seconds': float(np.median(original_pauses)) if original_pauses else None,
            'pause_fraction': float(np.median([ref['pause_fraction'] for ref in refs])),
            'active_dynamic_range_db': float(np.median([ref['active_dynamic_range_p90_p10_db'] for ref in refs])),
            'bands_pct': {name: float(np.median([ref['bands_pct'][name] for ref in refs]))
                          for name in refs[0]['bands_pct']},
        }
        result['characters'][speaker] = {'original_medians': medians, 'references': refs,
                                         'preview': candidate}
        print(speaker, json.dumps({'original': medians, 'preview': candidate}, indent=2))
    (preview_dir / 'acoustic_comparison.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
