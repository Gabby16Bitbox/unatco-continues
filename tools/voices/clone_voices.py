"""Create Instant Voice Clones from the locally prepared Revision samples.

python tools/voices/clone_voices.py --dry-run
python tools/voices/clone_voices.py --only AnnaNavarre --rights-confirmed

Existing voice IDs are preserved, including the user's JC clone. The flag
records the operator's confirmation of rights and consent; it grants no rights.
Requests that fail or time out are never retried automatically.
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

from make_voices import api_key

HERE = Path(__file__).resolve().parent
CONFIG = HERE / "voices.json"
SAMPLES = HERE / "samples"
NAMES = {"AnnaNavarre": "UC Anna", "GuntherHermann": "UC Gunther",
         "UNATCOTroop": "UC UNATCO Soldier 1", "UNATCOTroopB": "UC UNATCO Soldier 2",
         "MJ12Troop": "UC MJ12 Soldier 1", "MJ12TroopB": "UC MJ12 Soldier 2",
         "Jock": "UC Jock", "MIB": "UC Man in Black",
         "WaltonSimons": "UC Walton Simons",
         "GilbertRenton": "UC Gilbert Renton", "MaggieChow": "UC Maggie Chow",
         "MaxChen": "UC Max Chen", "GordonQuick": "UC Gordon Quick",
         "TracerTong": "UC Tracer Tong",
         "Red_Arrow_01": "UC Red Arrow Messenger",
         "TriadLumPath": "UC Luminous Path Guard",
         "TriadRedArrow": "UC Red Arrow Guard",
         "MJ12Commando": "UC MJ12 Commando",
         "ScientistConsulting": "UC Scientist",
         "AlexJacobson": "UC Alex", "PaulDenton": "UC Paul"}


def create_clone(key, name, path):
    boundary = "UC" + uuid.uuid4().hex
    parts = []
    for field, value in (("name", name), ("description", "Voice for the UNATCO Continues Deus Ex mod")):
        parts.append(("--%s\r\nContent-Disposition: form-data; name=\"%s\"\r\n\r\n%s\r\n" %
                      (boundary, field, value)).encode())
    parts.append(("--%s\r\nContent-Disposition: form-data; name=\"files\"; filename=\"%s\"\r\n"
                  "Content-Type: audio/wav\r\n\r\n" % (boundary, path.name)).encode())
    parts.append(path.read_bytes())
    parts.append(("\r\n--%s--\r\n" % boundary).encode())
    request = urllib.request.Request(
        "https://api.elevenlabs.io/v1/voices/add", data=b"".join(parts),
        headers={"xi-api-key": key, "Content-Type": "multipart/form-data; boundary=" + boundary})
    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError("ElevenLabs %s: %s" %
                           (error.code, error.read().decode("utf-8", "replace").replace(key, '[redacted]')[:700])) from None


def save_json(path, data):
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=list(NAMES))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--rights-confirmed", action="store_true")
    args = parser.parse_args()
    if not args.dry_run and not args.rights_confirmed:
        parser.error("Confirm rights and consent with --rights-confirmed before uploading")
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    manifest = json.loads((SAMPLES / "manifest.json").read_text(encoding="utf-8"))
    receipt_path = HERE / "clone_receipts.json"
    receipts = json.loads(receipt_path.read_text(encoding="utf-8")) if receipt_path.exists() else {}
    key = None
    for speaker, name in NAMES.items():
        if args.only and args.only != speaker:
            continue
        if config.get(speaker):
            print(speaker + ": existing voice preserved", flush=True)
            continue
        if speaker in receipts:
            raise RuntimeError("Clone already recorded for %s: inspect clone_receipts.json before continuing" % speaker)
        path = SAMPLES / manifest[speaker]["file"]
        if not path.is_file() or path.stat().st_size >= 10_000_000:
            raise RuntimeError("Missing sample or file >= 10 MB: " + speaker)
        print("%s -> %s (%.2f MB)" % (speaker, name, path.stat().st_size / 1_000_000), flush=True)
        if args.dry_run:
            continue
        if key is None:
            key = api_key()
        # Unknown outcomes require inspection of My Voices, never an automatic
        # duplicate clone. Record the pending upload before the network call.
        receipts[speaker] = {'state': 'pending', 'name': name, 'sample': path.name}
        save_json(receipt_path, receipts)
        made = create_clone(key, name, path)
        if not made.get("voice_id"):
            raise RuntimeError("Missing voice ID in response: check My Voices before retrying")
        receipts[speaker] = made
        save_json(receipt_path, receipts)
        if made.get("requires_verification"):
            raise RuntimeError("%s requires verification in ElevenLabs; ID recorded, not enabled in mod" % speaker)
        config[speaker] = made["voice_id"]
        # Original Gunther/MIB recordings already carry their characteristic
        # timbre. Avoid doubling that processing on their clones.
        if speaker in ("GuntherHermann", "MIB"):
            config.get("_fx", {}).pop(speaker, None)
        save_json(CONFIG, config)
        print("Saved " + speaker + " voice ID", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, urllib.error.URLError) as error:
        sys.exit(str(error))
