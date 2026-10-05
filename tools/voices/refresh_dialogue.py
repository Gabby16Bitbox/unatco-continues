"""Refresh current dialogue, reusing compatible raw takes and checking all WAVs."""
import argparse
from collections import Counter
from datetime import datetime
import json
from pathlib import Path
import shutil

import natural_voices as n
import sync_route_dialogue as route


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--process-only', action='store_true')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    backup = n.HERE / 'backups' / ('refresh-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
    backup.mkdir(parents=True, exist_ok=False)
    for path in (n.PLAN, n.OUT / 'receipts.json', n.OUT / 'route_generation.json'):
        if path.exists():
            shutil.copy2(path, backup / path.name)
    plan = n.author_plan(json.loads((n.OUT / 'calibration.json').read_text(encoding='utf-8')))
    reused, new = route.synchronize(plan)
    n.save(n.PLAN, plan)
    if args.process_only and new:
        raise ValueError('New/changed utterances require TTS: ' + ', '.join(new))
    audit = {'revision': plan['revision'], 'dialogue_count': len(plan['lines']),
             'speakers': dict(Counter(line['speaker'] for line in plan['lines'].values())),
             'reused_raw_takes': reused, 'new_takes': new,
             'source_hashes': {path.name: n.sha(path) for path in Path(n.m.SRC).glob('*.uc')
                               if not path.name.endswith('CheckCommandlet.uc')},
             'key_scheme': 'V + hash(speaker|channel|unchanged game dialogue)',
             'soldier_identity': 'Native saved BarkBindName A/B, independent of dialogue BindName.'}
    n.save(n.OUT / 'route_generation.json', audit)
    receipts = json.loads((n.OUT / 'receipts.json').read_text(encoding='utf-8'))
    pending = [line for key, line in plan['lines'].items() if key in new
               or not (receipts.get(key, {}).get('valid')
                       and receipts[key].get('processing_fingerprint') == n.processing_fingerprint(line)
                       and (n.OUT / (key + '.wav')).exists()
                       and receipts[key].get('sha256') == n.sha(n.OUT / (key + '.wav')))]
    print('Current:', len(plan['lines']), 'Cached:', len(reused), 'New:', len(new),
          'Pending processing:', len(pending), flush=True)
    n.generate(pending, plan, process_only=args.process_only)
    receipts = n.verify(plan)
    if set(plan['lines']) != {line['key'] for line in n.m.extract()}:
        raise ValueError('Dialogue changed during refresh; rerun against current sources.')
    if args.apply:
        n.apply(plan)
    n.save(n.OUT / 'refresh_summary.json', {
        **audit, 'applied': args.apply, 'backup': str(backup),
        'max_true_peak_dbtp': max(receipts[key]['input_tp'] for key in plan['lines']),
        'max_loudness_error_lu': max(abs(receipts[key]['input_i'] - line['target_lufs'])
                                    for key, line in plan['lines'].items())})


if __name__ == '__main__':
    main()
