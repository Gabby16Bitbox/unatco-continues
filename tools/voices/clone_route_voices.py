"""Create separate canonical soldier variants and Jock, with durable receipts.

Previously used IDs stay in the account and are retained in configuration.
Pending/unknown requests are never retried automatically.
"""
import argparse
import hashlib
import json
from datetime import datetime
from clone_voices import create_clone, save_json, NAMES, CONFIG, SAMPLES, HERE
from make_voices import api_key

SPEAKERS = ('UNATCOTroop', 'UNATCOTroopB', 'MJ12Troop', 'MJ12TroopB', 'Jock', 'WaltonSimons')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rights-confirmed', action='store_true', required=True)
    args = parser.parse_args()
    config = json.loads(CONFIG.read_text(encoding='utf-8'))
    manifest = json.loads((SAMPLES / 'manifest.json').read_text(encoding='utf-8'))
    path = HERE / 'variant_clone_receipts.json'
    receipts = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
    key = None
    for speaker in SPEAKERS:
        sample = SAMPLES / manifest[speaker]['file']
        digest = hashlib.sha256(sample.read_bytes()).hexdigest()
        if not 0 < sample.stat().st_size < 10_000_000:
            raise ValueError('Invalid sample size: ' + speaker)
        prior = receipts.get(speaker)
        if prior:
            if prior.get('state') != 'created' or prior.get('sample_sha256') != digest:
                raise ValueError('Inspect existing clone receipt before retrying: ' + speaker)
            config[speaker] = prior['voice_id']
            save_json(CONFIG, config)
            print(speaker + ': existing canonical clone preserved', flush=True)
            continue
        # Existing noncanonical soldier clone is preserved; this replacement
        # isolates AIBarks A from the other actors sharing a mission BindName.
        if speaker != 'UNATCOTroop' and config.get(speaker):
            raise ValueError('Unexpected existing voice: inspect ' + speaker)
        receipt = {'state': 'pending', 'previous_voice_id': config.get(speaker),
                   'name': NAMES[speaker], 'sample': sample.name,
                   'sample_sha256': digest, 'seconds': manifest[speaker]['seconds'],
                   'created_at': datetime.now().isoformat(timespec='seconds')}
        receipts[speaker] = receipt
        save_json(path, receipts)
        if key is None:
            key = api_key()
        print('Create ' + NAMES[speaker], flush=True)
        made = create_clone(key, NAMES[speaker], sample)
        receipt.update(made)
        receipt['state'] = 'created' if made.get('voice_id') and not made.get('requires_verification') else 'needs_review'
        save_json(path, receipts)
        if receipt['state'] != 'created':
            raise ValueError('Clone needs review in ElevenLabs: ' + speaker)
        if receipt['previous_voice_id']:
            config.setdefault('_legacy_voice_ids', {})[speaker] = receipt['previous_voice_id']
        config[speaker] = made['voice_id']
        save_json(CONFIG, config)
        print('Saved ' + speaker, flush=True)


if __name__ == '__main__':
    main()
