"""Extract one speaker at a time from Revision's conversation packages.

No upload: creates mono PCM WAV samples and a provenance manifest locally.
Uses the conversation's speakerName + audioPackageName + soundID, never guesses
the speaker from a sound filename. Requires ffmpeg and tools/ue1pkg.py.
"""
import argparse
import io
import json
import shutil
import struct
import subprocess
import sys
import wave
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE.parent))
from ue1pkg import Pkg

SPEAKERS = {
    "AnnaNavarre": "AnnaNavarre",
    "GuntherHermann": "GuntherHermann",
    "UNATCOTroop": "UNATCOTroop",  # Do not mix in UNATCOTroopB (another actor).
    "MIB": "MiB",
    "AlexJacobson": "AlexJacobson",
    "PaulDenton": "PaulDenton",
    "JCDenton": "JCDenton",
    "UNATCOTroopB": "UNATCOTroopB",
    "MJ12Troop": "MJ12Troop",
    "MJ12TroopB": "MJ12TroopB",
    "Jock": "Jock",
    "WaltonSimons": "WaltonSimons",
    "GilbertRenton": "GilbertRenton",
    "MaggieChow": "MaggieChow",
    "MaxChen": "MaxChen",
    "GordonQuick": "GordonQuick",
    "TracerTong": "TracerTong",
    "Red_Arrow_01": "Red_Arrow_01",
    "TriadLumPath": "TriadLumPath",
    "TriadRedArrow": "TriadRedArrow",
    "MJ12Commando": "MJ12Commando",
    "ScientistConsulting": "ScientistConsulting",
}
BARK_SPEAKERS = {'UNATCOTroop', 'UNATCOTroopB', 'MJ12Troop', 'MJ12TroopB',
                 'TriadLumPath', 'TriadRedArrow', 'MJ12Commando'}
# This optional messenger has only ~31 seconds of original ordinary speech.
# Keep that actor isolated instead of padding the sample with another Triad.
SHORT_SAMPLE_SPEAKERS = {'Red_Arrow_01', 'ScientistConsulting'}
CLEAN_BARK_MODES = ('Idle', 'AreaSecure', 'PostAttackSearching', 'SearchGiveUp',
                    'AllianceFriendly', 'TargetLost', 'PreAttackSearching', 'Futz')
RATE = 22050
MAX_BYTES = 10_000_000


def sound_bytes(pkg, export):
    """Read UE1 USound's format name and lazy byte array (package v68)."""
    start = export["off"]
    end = start + export["size"]
    none, pos = pkg.ci(start)
    if pkg.names[none] != "None":
        raise ValueError("Sound has unexpected serialized properties")
    format_index, pos = pkg.ci(pos)
    skip = struct.unpack_from("<I", pkg.d, pos)[0]
    pos += 4
    size, pos = pkg.ci(pos)
    if size <= 0 or pos + size > end or skip != pos + size:
        raise ValueError("Invalid UE1 sound byte array")
    fmt = pkg.names[format_index].lower()
    if fmt not in ("mp3", "wav"):
        raise ValueError("Unsupported sound format: " + fmt)
    return pkg.d[pos:pos + size]


def candidates(system):
    pkg = Pkg(str(system / "RevisionConversationsText.u"))
    result = {name: [] for name in SPEAKERS}
    reverse = {source.lower(): target for target, source in SPEAKERS.items()}
    seen = set()
    for idx, export in enumerate(pkg.exports, 1):
        if pkg.classname(export) != "ConEventSpeech":
            continue
        props = {name.lower(): value for name, _, _, value in pkg.props(idx)}
        source = props.get("speakername", "")
        target = reverse.get(source.lower())
        if not target:
            continue
        speech_ref = props.get("conspeech", ("ref", 0))[1]
        con_ref = props.get("conversation", ("ref", 0))[1]
        if speech_ref <= 0 or con_ref <= 0:
            continue
        speech = {name.lower(): value for name, _, _, value in pkg.props(speech_ref)}
        text = speech.get("speech", "").strip()
        audio = pkg.get(con_ref, "audioPackageName", "")
        sound_id = speech.get("soundid", 0)
        if not audio or sound_id < 0 or len(text.split()) < (3 if target in BARK_SPEAKERS else 5) or "(" in text:
            continue
        identity = (target, audio, sound_id)
        if identity in seen:
            continue
        seen.add(identity)
        # Prefer ordinary dialogue over alarm/combat barks. DataLink recordings
        # are lower priority because some already include a radio effect.
        con_name = pkg.get(con_ref, "conName", "")
        # A mission's generic BindName can refer to several actors. Use the
        # canonical A/B bark recordings only, keeping each native voice apart.
        if target in BARK_SPEAKERS and (audio != 'AIBarks' or not any(
                str(con_name).endswith('_Bark' + mode) for mode in CLEAN_BARK_MODES)):
            continue
        priority = (audio == "AIBarks", str(con_name).startswith("DL_"), audio, sound_id)
        result[target].append({"speaker": target, "source_speaker": source,
                               "audio_package": audio, "sound_id": sound_id,
                               "conversation": str(con_name), "text": text,
                               "priority": priority})
    for records in result.values():
        records.sort(key=lambda item: item["priority"])
    return result


def decode(ffmpeg, encoded):
    # Trim only the leading and trailing quiet areas. No denoising, pitch shift
    # or synthesized replacement is applied to the original recordings.
    trim = "silenceremove=start_periods=1:start_duration=0.03:start_threshold=-50dB"
    process = subprocess.run(
        [ffmpeg, "-hide_banner", "-loglevel", "error", "-i", "pipe:0",
         "-af", trim + ",areverse," + trim + ",areverse",
         "-ac", "1", "-ar", str(RATE), "-f", "s16le", "pipe:1"],
        input=encoded, capture_output=True, check=True)
    return process.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--system", type=Path, default=ROOT / "DevInstall" / "System")
    parser.add_argument("--only", choices=list(SPEAKERS))
    parser.add_argument("--seconds", type=float, default=120)
    parser.add_argument("--out", type=Path, default=HERE / "samples")
    args = parser.parse_args()
    if not 60 <= args.seconds <= 180:
        parser.error("--seconds must be between 60 and 180")
    ffmpeg = shutil.which("ffmpeg") or r"C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe"
    if not Path(ffmpeg).is_file():
        parser.error("ffmpeg not found")
    args.out.mkdir(parents=True, exist_ok=True)
    records = candidates(args.system)
    cache = {}
    manifest_path = args.out / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
    for speaker, entries in records.items():
        if args.only and args.only != speaker:
            continue
        chunks = []
        chosen = []
        duration = 0
        used_text = set()
        for entry in entries:
            if entry["text"] in used_text:
                continue
            audio = entry["audio_package"]
            path = args.system / ("RevisionConversationsAudio" + audio + ".u")
            if not path.is_file():
                continue
            if audio not in cache:
                package = Pkg(str(path))
                exports = {e["name"]: e for e in package.exports if package.classname(e) == "Sound"}
                cache[audio] = (package, exports)
            package, exports = cache[audio]
            name = "ConAudio%s_%d" % (audio, entry["sound_id"])
            export = exports.get(name)
            if not export:
                continue
            pcm = decode(ffmpeg, sound_bytes(package, export))
            seconds = len(pcm) / (RATE * 2)
            if not (.5 if speaker in BARK_SPEAKERS else 1.2) <= seconds <= 20:
                continue
            # Keep complete sentences; do not cut at the target duration.
            if duration + seconds > 180:
                continue
            if chunks:
                chunks.append(bytes(int(RATE * 0.15) * 2))
                duration += 0.15
            offset = duration
            chunks.append(pcm)
            duration += seconds
            used_text.add(entry["text"])
            chosen.append({key: value for key, value in entry.items() if key != "priority"} |
                          {"package_file": path.name, "sound": name,
                           "start_seconds": round(offset, 3), "duration_seconds": round(seconds, 3)})
            if duration >= args.seconds:
                break
        # Canonical bark sets contain only 40–60 seconds of calm speech.
        # Keep their provenance intact rather than mixing in another actor or
        # combat shouts. ElevenLabs accepts shorter consistent samples.
        if duration < (30 if speaker in BARK_SPEAKERS | SHORT_SAMPLE_SPEAKERS else 60):
            raise RuntimeError("Not enough clean dialogue for " + speaker)
        buffer = io.BytesIO()
        with wave.open(buffer, "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(b"".join(chunks))
        data = buffer.getvalue()
        if len(data) >= MAX_BYTES:
            raise RuntimeError("Sample exceeds 10 MB: " + speaker)
        filename = "UC_" + speaker + ".wav"
        (args.out / filename).write_bytes(data)
        manifest[speaker] = {"file": filename, "seconds": round(duration, 3), "bytes": len(data),
                             "format": "PCM s16 mono 22050 Hz", "clips": chosen}
        if speaker in BARK_SPEAKERS:
            manifest[speaker]['selection'] = 'Canonical single-speaker calm AIBarks; no mixed mission actors, shouts, pain or nonverbal sounds.'
        manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("%s: %.1f seconds, %.2f MB, %d clips -> %s" %
              (speaker, duration, len(data) / 1_000_000, len(chosen), filename), flush=True)


if __name__ == "__main__":
    main()
