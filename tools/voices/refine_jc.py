"""Prepare a consistent, untreated original JC sample and a separate IVC.

The user-authorized refinement preserves the previous clone and records the
new voice before switching configuration. Never retry an unknown creation.
"""
import argparse
from datetime import datetime
import json
import math
from pathlib import Path
import sys
import wave

import numpy as np
import natural_voices as n
from clone_voices import create_clone

SAMPLE = n.HERE / 'samples/UC_JC_Restrained.wav'
RECEIPT = n.HERE / 'jc_refined_clone.json'
# Calm, ordinary dialogue; omit inventory/price barks and conspicuous hesitations.
OMIT = {3, 5, 8, 16, 21, 32, 36, 37, 38, 39, 40, 41, 42}


def prepare():
    manifest = json.loads((n.HERE / 'samples/manifest.json').read_text())['JCDenton']
    chunks, selected = [], []
    for i, clip in enumerate(manifest['clips']):
        if i in OMIT:
            continue
        source = n.REFS / ('JCDenton_direct_%d.wav' % i)
        signal, rate = n.read(source)
        assert rate == n.RATE
        chunks += [signal, np.zeros(round(rate * .12))]
        selected.append({'index': i, **clip, 'reference_file': str(source)})
    signal = np.concatenate(chunks)
    rms = 20 * math.log10(float(np.sqrt(np.mean(signal ** 2))))
    peak = 20 * math.log10(float(np.max(abs(signal))))
    gain = min(-20 - rms, -3 - peak)
    signal *= 10 ** (gain / 20)
    n.write_pcm(SAMPLE, np.clip(np.rint(signal * 32768), -32768, 32767).astype('<i2').tobytes())
    assert SAMPLE.stat().st_size < 10_000_000 and 60 <= len(signal) / rate <= 180
    n.save(SAMPLE.with_suffix('.json'), {'method': 'Original in-person JC dialogue. One fixed attenuation, no denoising/EQ/pitch change. Selected by scene/text; no automatic claim about emotion.',
        'clips': selected, 'seconds': len(signal) / rate, 'gain_db': gain, 'sha256': n.sha(SAMPLE)})
    print('JC sample: %.2fs, %.2f MB, %d original clips' % (len(signal) / rate, SAMPLE.stat().st_size / 1e6, len(selected)), flush=True)


def clone():
    cfg = json.loads(Path(n.m.VOICES).read_text())
    if RECEIPT.exists():
        made = json.loads(RECEIPT.read_text())
        if not made.get('voice_id'):
            raise ValueError('Unknown clone outcome: inspect ElevenLabs before retrying')
        if made.get('requires_verification'):
            raise ValueError('Clone requires verification in ElevenLabs')
    else:
        # Persist pending state before the network request to prevent duplicates.
        made = {'previous_voice_id': cfg['JCDenton'], 'sample_sha256': n.sha(SAMPLE),
                'created_at': datetime.now().isoformat(timespec='seconds'), 'state': 'pending'}
        n.save(RECEIPT, made)
        made.update(create_clone(n.m.api_key(), 'UC JC — restrained original', SAMPLE))
        made['state'] = 'created'
        n.save(RECEIPT, made)
        if not made.get('voice_id') or made.get('requires_verification'):
            raise ValueError('Clone not ready; receipt saved, configuration preserved')
    cfg['JCDenton'] = made['voice_id']
    n.save(Path(n.m.VOICES), cfg)
    print('Separate refined JC clone configured; previous voice ID retained in receipt.', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('prepare', 'clone'))
    args = parser.parse_args()
    prepare() if args.command == 'prepare' else clone()
