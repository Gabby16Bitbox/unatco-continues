"""Voci della mod con ElevenLabs.

1. Estrae TUTTE le battute dal codice della mod (src/UnatcoContinues/Classes/*.uc):
   c.Line("Chi", "AChi", "Testo"), Say("Chi", "Testo") e le battute dei soldati/MIB.
2. Per ogni battuta il cui personaggio ha una voce in voices.json e che non ha ancora
   un file audio: chiama l'API ElevenLabs, converte in WAV 22050 Hz mono 16 bit
   (gli InfoLink con un leggero filtro radio) e salva in src/UnatcoVoices/Sounds/.
3. Riscrive src/UnatcoVoices/Classes/UnatcoVoices.uc con gli #exec AUDIO IMPORT.
   Poi .\\build.ps1 compila il pacchetto audio UnatcoVoices.u.

Il nome di ogni suono e' "V" + hash di voce, canale e testo: la mod in gioco calcola
lo stesso hash (UCVoice.VoiceKey). Personaggi diversi non condividono le risposte.

Chiave API: variabile d'ambiente ELEVENLABS_API_KEY, oppure il file
tools/voices/elevenlabs_key.txt (NON va condiviso: e' nel .gitignore).

Uso:
  python make_voices.py list            # elenco battute, chi le dice, se hanno audio
  python make_voices.py generate        # genera quelle mancanti (solo personaggi con voce)
  python make_voices.py generate --only AnnaNavarre
  python make_voices.py voices          # elenca le voci del tuo account ElevenLabs
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SRC = os.path.join(ROOT, 'src', 'UnatcoContinues', 'Classes')
OUT_SOUNDS = os.path.join(ROOT, 'src', 'UnatcoVoices', 'Sounds')
OUT_CLASS = os.path.join(ROOT, 'src', 'UnatcoVoices', 'Classes', 'UnatcoVoices.uc')
VOICES = os.path.join(os.path.dirname(__file__), 'voices.json')
KEYFILE = os.path.join(os.path.dirname(__file__), 'elevenlabs_key.txt')
FFMPEG = r'C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe'


def vhash(text):
    """Deve essere IDENTICO a UCVoice.Key() in UnrealScript."""
    h = 7
    for ch in text:
        h = (h * 31 + ord(ch)) % 16777213
    return 'V%d' % h


def unescape(s):
    return s.replace('\\"', '"')


def voice_key(speaker, text, kind='con'):
    channel = 'radio' if kind == 'infolink' and speaker != 'JCDenton' else 'direct'
    return vhash(speaker + '|' + channel + '|' + text)


def extract():
    """Ritorna lista di dict: speaker, text, kind ('con' o 'infolink'), file."""
    lines = []
    seen = set()

    def add(speaker, text, kind, fname, conversation=None):
        text = unescape(text)
        identity = (speaker, text, 'radio' if kind == 'infolink' and speaker != 'JCDenton' else 'direct')
        if not text or identity in seen:
            return
        seen.add(identity)
        entry = {'speaker': speaker, 'text': text, 'kind': kind, 'file': fname,
                 'key': voice_key(speaker, text, kind)}
        if conversation:
            entry['conversation'] = conversation
        lines.append(entry)

    rx_line = re.compile(r'\bc\.Line\(\s*("([^"]*)"|[A-Za-z_.]+)\s*,\s*("([^"]*)"|[A-Za-z_.]+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)')
    rx_say = re.compile(r'\bSay\(\s*"([^"]*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)')
    rx_ret = re.compile(r'return\s+"((?:[^"\\]|\\.)*)"\s*;')
    rx_begin = re.compile(r"\bc\.Begin\(\s*'([^']+)'\s*,")

    for fname in sorted(os.listdir(SRC)):
        if not fname.endswith('.uc'):
            continue
        source_path = os.path.join(SRC, fname)
        try:
            with open(source_path, encoding='utf-8-sig') as source:
                src = source.read()
        except UnicodeDecodeError:
            # UnrealEd/legacy SDK sources may contain Windows ANSI comments.
            # Decode them locally; never rewrite a concurrently edited file.
            with open(source_path, encoding='cp1252') as source:
                src = source.read()
        src = '\n'.join(l for l in src.split('\n') if not l.lstrip().startswith('//'))   # niente commenti
        beginnings = list(rx_begin.finditer(src))
        for m in rx_line.finditer(src):
            speaker = m.group(2) if m.group(2) is not None else m.group(1)
            if speaker == 'speaker':        # la definizione di UCCon.Line
                continue
            if 'BindName' in speaker:
                raise ValueError('Literal text with dynamic speaker needs an explicit profile: ' + fname)
            if speaker == 'UCGreeter':      # il soldato che riconosce JC in Hell's Kitchen
                # The selected actor might use either native voice variant.
                add('UNATCOTroopB', m.group(5), 'con', fname)
                speaker = 'UNATCOTroop'
            if speaker == 'UCTongGuard':
                # TongBase contains both native Triad voice actors. The live
                # pawn's saved BarkBindName selects the matching recording.
                add('TriadRedArrow', m.group(5), 'con', fname)
                speaker = 'TriadLumPath'
            # UCGateGuard: soldato UNATCO (classe UNATCOTroop) alla grata della metro
            speaker = {'UCHKOfficer': 'MJ12Troop', 'UCHKGuard': 'MJ12TroopB', 'UCGateGuard': 'UNATCOTroop', 'UCSpecialAgent1': 'MIB', 'UCSpecialAgent2': 'MIB',
                       'UCLMAgent1': 'MIB', 'UCLMAgent2': 'MIB', 'UCMaggieHolo': 'MaggieChow',
                       'UCMessenger': 'Red_Arrow_01', 'UCLMRedArrow': 'Red_Arrow_01',
                       'UCSPTech1': 'MJ12Troop', 'UCSPCommander': 'MJ12Commando',
                       'UCPrisoner': 'ScientistConsulting'}.get(speaker, speaker)
            if speaker in ('UCHKOfficer', 'UCHKGuard'):   # MJ12 all'eliporto di Hong Kong
                speaker = 'MJ12Troop'
            conversation = next((b.group(1) for b in reversed(beginnings) if b.start() < m.start()), None)
            add(speaker, m.group(5), 'con', fname, conversation)
        for m in rx_say.finditer(src):
            add(m.group(1), m.group(2), 'infolink', fname)

        # battute dei soldati / MIB (UCMod.BarkLine): blocco "IsA('MIB')" = MIB, resto = soldato
        if fname == 'UCMod.uc':
            a = src.find('function string BarkLine')
            b = src.find('function BarkTick')
            body = src[a:b]
            mib_a = body.find("if (sp.IsA('MIB'))")
            mib_b = body.find('switch', mib_a)
            for m in rx_ret.finditer(body):
                spk = 'MIB' if mib_a != -1 and mib_a < m.start() < mib_b else 'UNATCOTroop'
                add(spk, m.group(1), 'con', fname)
                if spk == 'UNATCOTroop':
                    add('UNATCOTroopB', m.group(1), 'con', fname)
    return lines


def load_voices():
    if not os.path.exists(VOICES):
        return {}
    data = json.load(open(VOICES, encoding='utf-8'))
    return {k: v for k, v in data.items() if not k.startswith('_') and v}


def api_key():
    key = os.environ.get('ELEVENLABS_API_KEY', '').strip()
    if not key and os.path.exists(KEYFILE):
        key = open(KEYFILE, encoding='utf-8').read().strip()
    # the key file may hold the bare key or the line "ElevenLabs API Key: <key>"
    # (see elevenlabs_key.example.txt); the unfilled placeholder counts as missing
    if ':' in key:
        key = key.split(':', 1)[1].strip()
    if key.startswith('['):
        key = ''
    if not key:
        sys.exit('Manca la chiave: imposta ELEVENLABS_API_KEY o crea tools/voices/elevenlabs_key.txt')
    return key


def tts(key, voice_id, text, out_mp3, settings, seed=None, previous_text=None, next_text=None):
    model = settings.get('model_id', 'eleven_multilingual_v2')
    is_v4 = model in ('eleven_v4', 'eleven_v4_turbo')
    voice_settings = {'stability': settings.get('stability', 0.45)}
    if is_v4:
        voice_settings['similarity_boost'] = settings.get('similarity_boost', 0.75)
    elif model != 'eleven_v3':
        voice_settings.update(similarity_boost=settings.get('similarity_boost', 0.8),
                              style=settings.get('style', 0.0),
                              use_speaker_boost=settings.get('use_speaker_boost', True))
        if 'speed' in settings:
            voice_settings['speed'] = settings['speed']
    body = {'text': text, 'model_id': model, 'voice_settings': voice_settings}
    if seed is not None:
        body['seed'] = seed
    if model == 'eleven_v3' or is_v4:
        if previous_text or next_text:
            raise ValueError('Use dialogue prompting rather than text context with v3/v4.')
        body['language_code'] = 'en'
    else:
        if previous_text:
            body['previous_text'] = previous_text
        if next_text:
            body['next_text'] = next_text
    req = urllib.request.Request('https://api.elevenlabs.io/v1/text-to-speech/%s?output_format=mp3_44100_128' % voice_id,
                                 data=json.dumps(body).encode('utf-8'),
                                 headers={'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            with open(out_mp3, 'wb') as output:
                output.write(r.read())
            return {'request_id': r.headers.get('request-id'),
                    'character_cost': r.headers.get('character-cost')}
    except urllib.error.HTTPError as error:
        raise RuntimeError('ElevenLabs %s: %s' %
                           (error.code, error.read().decode('utf-8', 'replace').replace(key, '[redacted]')[:500])) from None


def undo_pronunciation(text, plan):
    """Reverse only the explicitly authored IPA rules for word validation."""
    for grapheme, phonemes in plan.get('pronunciations', {}).items():
        text = text.replace(phonemes, grapheme)
    return text


def acting_request(line, cfg):
    """Use the authored performance, while hashing only the unchanged dialogue."""
    settings = cfg.get('_settings', {}).copy()
    text = line['text']
    plan_name = cfg.get('_delivery_plan')
    if not plan_name:
        return text, settings
    plan_path = os.path.join(os.path.dirname(__file__), plan_name)
    plan = json.load(open(plan_path, encoding='utf-8'))
    entry = plan['lines'].get(line['key'])
    if not entry or entry['text'] != text or entry['speaker'] != line['speaker']:
        raise ValueError('Manca una direzione aggiornata per ' + line['key'])
    prompted = entry['tts_text']
    spoken = entry.get('spoken_text', text)
    token_pattern = r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*"
    if (undo_pronunciation(re.sub(r'\[[^\]]*\]\s*', '', prompted), plan) != spoken or
            re.findall(token_pattern, spoken.lower()) != re.findall(token_pattern, text.lower())):
        raise ValueError('La direzione cambia le parole della battuta ' + line['key'])
    settings.update(plan['settings'])
    settings.update(plan['characters'][line['speaker']]['settings'])
    settings.update(entry.get('settings', {}))
    return prompted, settings


def to_wav(mp3, wav, radio, fx=''):
    chain = [fx] if fx else []
    chain.append('highpass=f=300,lowpass=f=3400,acompressor' if radio else 'loudnorm=I=-18')
    subprocess.run([FFMPEG, '-y', '-loglevel', 'error', '-i', mp3, '-af', ','.join(chain),
                    '-ac', '1', '-ar', '22050', '-sample_fmt', 's16', wav], check=True)


def api_json(key, path, body):
    req = urllib.request.Request('https://api.elevenlabs.io' + path, data=json.dumps(body).encode('utf-8'),
                                 headers={'xi-api-key': key, 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit('ElevenLabs %s -> %s: %s' % (path, e.code, e.read().decode('utf-8', 'replace')[:500]))


def design(key):
    """Voice Design: crea voci NUOVE dalle descrizioni in voices.json["_design"] (nessuna clonazione)
    per i personaggi che non hanno ancora un voice_id, e le salva in voices.json."""
    cfg = json.load(open(VOICES, encoding='utf-8'))
    sample = ("UNATCO is a peacekeeping force. We keep order where governments have failed, "
              "and we do it quietly. Nobody walks out of Hell's Kitchen tonight without our say-so.")
    for name, desc in cfg.get('_design', {}).items():
        if cfg.get(name):
            continue
        print('creo la voce', name, '...')
        prev = api_json(key, '/v1/text-to-voice/create-previews', {'voice_description': desc, 'text': sample})
        previews = prev.get('previews') or []
        if not previews:
            sys.exit('nessuna anteprima per ' + name)
        gid = previews[0].get('generated_voice_id')
        made = api_json(key, '/v1/text-to-voice/create-voice-from-preview',
                        {'voice_name': 'UNATCO Continues - ' + name, 'voice_description': desc, 'generated_voice_id': gid})
        cfg[name] = made.get('voice_id', '')
        print('  ->', cfg[name])
        json.dump(cfg, open(VOICES, 'w', encoding='utf-8'), indent=2)


def write_class():
    # Keep obsolete takes in local caches/backups but import only live dialogue.
    wavs = sorted(line['key'] + '.wav' for line in extract()
                  if os.path.isfile(os.path.join(OUT_SOUNDS, line['key'] + '.wav')))
    out = ['//=============================================================================',
           '// UnatcoVoices - pacchetto audio delle voci (GENERATO da tools/voices/make_voices.py).',
           '// Non modificare a mano: rilancia lo script.',
           '//=============================================================================',
           'class UnatcoVoices extends Object;', '']
    for w in wavs:
        out.append('#exec AUDIO IMPORT FILE="Sounds\\%s" NAME="%s"' % (w, w[:-4]))
    out += ['', 'defaultproperties', '{', '}', '']
    open(OUT_CLASS, 'w', encoding='utf-8').write('\n'.join(out))
    return len(wavs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', nargs='?', default='list', choices=['list', 'voices', 'design', 'generate', 'class'])
    parser.add_argument('--only', help='Genera solo questo personaggio')
    parser.add_argument('--limit', type=int, help='Numero massimo di nuove battute (utile per una prova)')
    parser.add_argument('--dry-run', action='store_true', help='Elenca le richieste senza consumare crediti')
    args = parser.parse_args()
    cmd, only = args.command, args.only
    if args.limit is not None and args.limit < 1:
        parser.error('--limit deve essere almeno 1')
    os.makedirs(OUT_SOUNDS, exist_ok=True)
    lines = extract()
    voices = load_voices()

    if cmd == 'list':
        for l in lines:
            has = os.path.exists(os.path.join(OUT_SOUNDS, l['key'] + '.wav'))
            print('%-4s %-16s %-9s %s' % ('OK' if has else ('--' if l['speaker'] in voices else 'no'),
                                         l['speaker'], l['kind'], l['text'][:90]))
        print('\n%d battute; personaggi: %s' % (len(lines), sorted(set(l['speaker'] for l in lines))))
        print('voci configurate:', sorted(voices) or 'nessuna (vedi voices.json)')
        return

    if cmd == 'voices':
        req = urllib.request.Request('https://api.elevenlabs.io/v1/voices', headers={'xi-api-key': api_key()})
        data = json.load(urllib.request.urlopen(req, timeout=60))
        for v in data.get('voices', []):
            print(v['voice_id'], '|', v['name'], '|', v.get('category'))
        return

    if cmd == 'design':
        design(api_key())
        return

    if cmd == 'generate':
        cfg = json.load(open(VOICES, encoding='utf-8'))
        fxs = cfg.get('_fx', {})
        pending = [line for line in lines if (not only or line['speaker'] == only)
                   and voices.get(line['speaker'])
                   and not os.path.exists(os.path.join(OUT_SOUNDS, line['key'] + '.wav'))]
        if args.limit:
            pending = pending[:args.limit]
        requests = {line['key']: acting_request(line, cfg) for line in pending}
        print('%d richieste, %d caratteri' % (len(pending), sum(len(line['text']) for line in pending)))
        if args.dry_run:
            for line in pending:
                print(line['speaker'], line['key'], line['kind'], requests[line['key']][0])
            return
        if not pending:
            print('Nessun audio da generare per le voci configurate.')
            return
        # Resolve local dependencies before making a paid API request.
        if not os.path.isfile(FFMPEG):
            sys.exit('ffmpeg non trovato: ' + FFMPEG)
        if cfg.get('_delivery_plan') == 'delivery_natural_v4.json':
            import natural_voices as natural
            plan = json.loads(natural.PLAN.read_text(encoding='utf-8'))
            if set(plan['lines']) != {line['key'] for line in lines}:
                sys.exit('Dialoghi modificati: aggiornare prima con voices.ps1 natural calibrate.')
            selected = [plan['lines'][line['key']] for line in pending]
            natural.generate(selected, plan)
            natural.apply(plan, keys=[line['key'] for line in pending])
            print('%d nuovi audio V4 calibrati. Ora: .\\build.ps1' % len(pending))
            return
        key = api_key()
        made = 0
        try:
            with tempfile.TemporaryDirectory(dir=os.path.dirname(__file__), prefix='_tts_') as temporary:
                tmp = os.path.join(temporary, 'speech.mp3')
                for l in pending:
                    wav = os.path.join(OUT_SOUNDS, l['key'] + '.wav')
                    print('genero', l['speaker'], '-', l['text'][:70], flush=True)
                    request_text, line_settings = requests[l['key']]
                    tts(key, voices[l['speaker']], request_text, tmp, line_settings,
                        seed=int(l['key'][1:]) if cfg.get('_delivery_plan') else None)
                    staged = os.path.join(temporary, l['key'] + '.wav')
                    to_wav(tmp, staged, radio=(l['kind'] == 'infolink'), fx=fxs.get(l['speaker'], ''))
                    os.replace(staged, wav)
                    made += 1
        finally:
            # Keep successfully generated files usable even if a later request fails.
            n = write_class()
        print('\n%d nuovi audio; %d in totale nel pacchetto. Ora: .\\build.ps1' % (made, n))
        return

    if cmd == 'class':
        print(write_class(), 'audio nel pacchetto')


if __name__ == '__main__':
    main()
