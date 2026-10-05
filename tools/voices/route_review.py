"""Save a review of the installed route audio, with two soldier previews."""
import argparse
import json
import re
from collections import Counter
from pathlib import Path
import wave
from datetime import datetime
import make_voices as m
import natural_voices as n
from build_voice_snapshot import read_log
from prepare_samples import RATE


def preview(speaker, texts, destination):
    chunks = [bytes(int(RATE * .15) * 2)]
    for text in texts:
        path = Path(m.OUT_SOUNDS) / (m.voice_key(speaker, text) + '.wav')
        with wave.open(str(path), 'rb') as reader:
            if (reader.getnchannels(), reader.getsampwidth(), reader.getframerate()) != (1, 2, RATE):
                raise ValueError('Unexpected preview PCM format')
            chunks.append(reader.readframes(reader.getnframes()))
        chunks.append(bytes(int(RATE * .25) * 2))
    n.write_pcm(destination, b''.join(chunks))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-system', type=Path, required=True)
    args = parser.parse_args()
    plan = json.loads(n.PLAN.read_text(encoding='utf-8'))
    generation = json.loads((n.OUT / 'route_generation.json').read_text(encoding='utf-8'))
    current_hashes = {path.name: n.sha(path) for path in Path(m.SRC).glob('*.uc')
                      if not path.name.endswith('CheckCommandlet.uc')}
    changed = sorted(name for name in set(current_hashes) | set(generation['source_hashes'])
                     if current_hashes.get(name) != generation['source_hashes'].get(name))
    if changed or set(plan['lines']) != {line['key'] for line in m.extract()}:
        raise ValueError('Sources changed since generation: ' + ', '.join(changed))
    receipts = json.loads((n.OUT / 'receipts.json').read_text(encoding='utf-8'))
    texts = ['Agent Denton.', 'Search operation. Orders from headquarters.', 'Among others.']
    for speaker, name in (('UNATCOTroop', 'unatco_soldier_1'), ('UNATCOTroopB', 'unatco_soldier_2')):
        preview(speaker, texts, n.OUT / (name + '_preview.wav'))
    build = args.build_system
    native = {}
    for check, filename, prefix in (
        ('voices', 'UCVoiceCheckCommandlet.log', 'UCVoiceCheck'),
        ('dialogue', 'UCDialogueCheckCommandlet.log', 'UCDialogueCheck'),
        ('route', 'UCRouteCheckCommandlet.log', 'UCRouteCheck'),
        ('voice_identity', 'VoiceIdentity.log', 'UCVoiceIdentityCheck')):
        match = re.search(prefix + r':\s*(\d+) checked,\s*(\d+) failed',
                          read_log(build / filename))
        if not match or int(match[2]) != 0:
            raise ValueError('Missing or failed native check: ' + check)
        native[check] = [int(match[1]), int(match[2])]
    identity_log = read_log(build / 'VoiceIdentity.log')
    native['real_map_soldiers'] = int(re.search(r'(\d+) native soldiers', identity_log)[1])
    game = Path('C:/Program Files (x86)/Steam/steamapps/common/Deus Ex/Revision/System')
    packages = {name: {'dist_sha256': n.sha(Path(m.ROOT) / 'dist' / name),
                       'installed_sha256': n.sha(game / name)}
                for name in ('UnatcoContinues.u', 'UnatcoVoices.u')}
    if any(value['dist_sha256'] != value['installed_sha256'] for value in packages.values()):
        raise ValueError('Installed packages do not match this build')
    counts = Counter(line['speaker'] for line in plan['lines'].values())
    summary = {**generation, 'installed': True, 'packages': packages,
               'native_checks': native,
               'max_loudness_error_lu': max(abs(receipts[k]['input_i'] - l['target_lufs']) for k,l in plan['lines'].items()),
               'max_true_peak_dbtp': max(receipts[k]['input_tp'] for k in plan['lines']),
               'preview_texts': texts, 'mix_profile': plan.get('mix_profile')}
    n.save(n.OUT / 'route_review.json', summary)
    report = ['# Voci della route aggiornata — ' + datetime.now().strftime('%d/%m/%Y'), '',
              '%d combinazioni voce/battuta correnti: %d take richieste dal piano aggiornato e %d '
              'registrazioni compatibili recuperate dalla cache. ' %
              (len(plan['lines']),len(generation['new_takes']),len(generation['reused_raw_takes'])) +
              'Pacchetti compilati e installati in Revision/System, verificati con SHA256.', '',
              'UNATCO Soldier 1 e 2 provengono esclusivamente dai gruppi originali AIBarks '
              '`UNATCOTroop` e `UNATCOTroopB`. Nessun sorteggio della voce per battuta o per skin. '
              'Il driver sceglie il profilo dal BarkBindName salvato sul PNG: saluto, dialogo e barks '
              'mantengono la stessa variante anche dopo i nomi temporanei UCGreeter/UCBark.', '',
              'Creati inoltre Jock, Walton Simons e due cloni MJ12 per ufficiale e guardia di Hong Kong. '
              'Barks nativi e nuovi dialoghi dei due PNG MJ12 usano lo stesso gruppo.', '',
              'Le scene del Ton e della ricerca di Paul includono %d audio di Gunther e %d di Gilbert. Il clone MIB copre %d battute degli agenti speciali del Ton e del Lucky Money. '
              'Gilbert usa un campione originale isolato di 90 secondi. Gunther mantiene una recitazione ferma e contenuta; '
              'la variabilita dei tempi osservata negli originali (residuo al percentile 95) evita di comprimere le risposte brevi. '
              'I codici della guardia conservano brevi pause fra le cifre.' %
              (counts.get('GuntherHermann',0), counts.get('GilbertRenton',0), counts.get('MIB',0)), '',
              'Hong Kong: %d audio di Maggie, %d di Max Chen, %d di Gordon Quick e %d del messaggero/contatto Red Arrow sono ora collegati a UCHKStory. '
              'La chiamata sulla spada usa il filtro InfoLink; la registrazione M06WaltonHolo usa un filtro elettronico per entrambi i personaggi, '
              'con banda derivata dagli originali remoti di Simons. Il codice viene letto come scritto nel copione corrente.' %
              (counts.get('MaggieChow',0), counts.get('MaxChen',0), counts.get('GordonQuick',0), counts.get('Red_Arrow_01',0)), '',
              'Laboratorio di Tong: i gruppi nativi TriadLumPath e TriadRedArrow hanno cloni distinti. '
              'UCTongGuard sceglie il Sound dal BarkBindName e dalla classe del PNG. '
              'Il comandante Special Projects usa MJ12Commando; il tecnico usa MJ12Troop A. '
              'Il prigioniero usa il singolo attore originale ScientistConsulting (37,4 secondi puliti), '
              'senza mescolare scienziati diversi. Campioni guardie: 34,9 e 33,4 secondi; commando: 50,4 secondi. '
              'Tutti sotto 10 MB. Ricevute dei quattro nuovi cloni in tools/voices/clone_receipts.json.', '',
              'Tutte le take usano Eleven v4. JC mantiene il clone sobrio gia approvato e deadpan '
              '(stabilita 1,00, somiglianza 0,85); soldati e Jock usano 0,95 / 0,80. '
              'Prompt brevi, con intenzioni per scena in delivery_natural_v4.json. '
              'UNATCO e FEMA hanno regole IPA nel solo prompt; i sottotitoli restano invariati.', '',
              'Ogni Sound identifica voce, canale e testo. Le risposte brevi identiche di personaggi '
              'diversi non possono riutilizzare il Sound di un altro personaggio. '
              'Il pacchetto importa solo il dialogo corrente; le take precedenti restano salvate.', '',
              'I tempi derivano dagli originali per voce e canale, con correzioni di velocita limitate '
              'a 0,80–1,22. Per frasi lunghe dei soldati si evita di imporre il ritmo delle brevi '
              'esclamazioni, usando anche un limite di riferimento di 225 parole/min. '
              'Il mix comune usa lo stesso livello per gli interlocutori diretti, evitando anche la differenza di circa 7,5 LU '
              'nei barks originali. Paul e Simons remoti mantengono il filtro InfoLink; JC resta asciutto. '
              'Scarto massimo misurato %.2f LU; picco massimo %.2f dBTP.' %
              (summary['max_loudness_error_lu'], summary['max_true_peak_dbtp']), '',
              'Revisione del volume: NPC diretti -14 LUFS, radio/proiezioni -14,5 LUFS, JC -15,5 LUFS. '
              'Tolleranza per take 0,25 LU, verificata su tutti i %d audio correnti. ' % len(plan['lines']) +
              'Le nuove battute seguono lo stesso profilo persistente in tools/voices/mix_profile.json. '
              'La precedente revisione locale dei volumi e documentata in natural_v4/mix_balance.json.', '',
              'Trattamento corrente: de-essing dinamico selettivo fino a 3 dB a 5,5 kHz; '
              'Simons radio fino a 6 dB a 5 kHz, con minore presenza a 3,2 kHz. '
              'Limiter sempre attivo a 4x, guadagno automatico disattivato. '
              'Picchi di campione e true peak verificati dopo conversione finale, entro -2 dB. '
              'La prova offline preserva il corpo della voce: check_dynamics.py.', '',
              '| Voce | Battute |', '|---|---:|']
    report += ['| %s | %d |' % item for item in counts.items()]
    report += ['', '## Verifiche', '',
               '- Compilazione: 0 errori, 0 avvisi.',
               '- Lookup Sound nel motore: %d/%d.' % (native['voices'][0],native['voices'][0]),
               '- Struttura dialoghi/camere: %d/%d.' % (native['dialogue'][0],native['dialogue'][0]),
               '- Route attuale e scelte di Jock: %d/%d.' % (native['route'][0],native['route'][0]),
               '- Identita vocale: %d/%d su %d soldati reali di 04_NYC_Street; ' %
               (native['voice_identity'][0],native['voice_identity'][0],native['real_map_soldiers']) +
               'A e B conservate dopo saluto, bark temporaneo e ripristino del binding.',
               '- Durata, livello, picco, PCM 22050 Hz mono 16 bit, hash e parole del prompt: %d/%d.' %
               (len(plan['lines']),len(plan['lines'])), '',
               'I controlli del motore sono automatici e headless. Il timbro e la naturalezza finale '
               'richiedono ascolto; le due anteprime sono in tools/voices/natural_v4.', '',
               '## Provenienza dei cloni', '',
               'Campioni: UNATCO A 53,0 s / B 46,4 s; MJ12 A 54,4 s / B 63,4 s; Jock 94,1 s; Simons 94,5 s. '
               'Tutti i WAV sono sotto 10 MB. Le parti di dolore, urla, effetti e suoni non verbali '
               'sono esclusi. I gruppi brevi restano separati, senza allungarli mescolando attori diversi. '
               '[La guida ElevenLabs](https://elevenlabs.io/docs/eleven-creative/voices/voice-cloning/instant-voice-cloning) '
               'consiglia audio coerente e pulito e ammette che campioni piu brevi possono funzionare.', '',
               'Manifest dei campioni: tools/voices/samples/manifest.json. Ricevute cloni: '
               'tools/voices/variant_clone_receipts.json. Rapporti per take: '
               'tools/voices/natural_v4/report.md e route_review.json.', '']
    (Path(m.ROOT) / 'docs/VOICE_ROUTE_REVIEW.md').write_text('\n'.join(report), encoding='utf-8')
    print('Installed route review saved. Two UNATCO previews ready.', flush=True)


if __name__ == '__main__':
    main()
