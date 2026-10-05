"""Prepare only explicitly written Hong Kong M1 dialogue from the design notes.

The newer M1 plan overrides the old sword/Simons call. Drafts stay outside the
runtime package until matching UCCon scenes exist; their raw cache is reusable.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import wave
import make_voices as m
import natural_voices as n
from sync_route_dialogue import synchronize

HERE = Path(__file__).resolve().parent
PLAN = HERE / 'delivery_hk_draft_v4.json'
DOCS = Path(m.ROOT) / 'docs'


def scenes():
    # Each entry records the actual speaker. Prose, goals and stage directions
    # are not speech. No unwritten Maggie exposition or government-agent lines.
    return [
        ('red-arrow-messenger', 'HONGKONG_M1_PIANO.md', 'HK-3', 'con', [
            ('Red_Arrow_01', 'Denton?'), ('JCDenton', "Who's asking?"),
            ('Red_Arrow_01', "Someone who knows why you're here."), ('JCDenton', 'Who?'),
            ('Red_Arrow_01', 'Max Chen. Lucky Money.'),
            ('JCDenton', 'Why does Chen want to see me?'), ('Red_Arrow_01', 'Ask him.')]),
        ('max-introduction', 'HONGKONG_DESIGN.md', '5', 'con', [
            ('MaxChen', 'Mr. Denton.'), ('JCDenton', 'You know who I am.'),
            ('MaxChen', 'Everyone knows who you are.'), ('JCDenton', "I'm looking for Tracer Tong."),
            ('MaxChen', 'Then you are looking for the Luminous Path.'),
            ('JCDenton', 'And Maggie Chow?'), ('MaxChen', 'She is expecting you.')]),
        ('maggie-introduction', 'HONGKONG_DESIGN.md', '6', 'con', [
            ('MaggieChow', 'Mr. J.C. Denton.'), ('JCDenton', 'Maggie Chow.'),
            ('MaggieChow', 'As serious as your brother.'), ('JCDenton', 'You knew Paul?'),
            ('MaggieChow', 'Everyone involved with Tracer Tong knew Paul.'),
            ('JCDenton', "That's not what I asked."), ('MaggieChow', 'Yes.'),
            ('MaggieChow', 'Your brother came here looking for answers.'),
            ('JCDenton', 'What did he find?'), ('MaggieChow', 'Tracer Tong.'),
            ('MaggieChow', 'Look what happened to him.')]),
        ('gordon-gate', 'HONGKONG_DESIGN.md', '8', 'con', [
            ('GordonQuick', 'Paul Denton trusted you.'), ('JCDenton', 'Paul made a mistake.'),
            ('GordonQuick', 'Which one?'), ('JCDenton', 'Choosing terrorists over UNATCO.'),
            ('GordonQuick', 'No. Trusting his brother.'), ('JCDenton', "Where's Tong?"),
            ('GordonQuick', 'Somewhere you will never find him.'),
            ('JCDenton', "Then we're finished."), ('GordonQuick', 'Maybe.'),
            ('GordonQuick', 'Ask Maggie Chow who killed Yuen Kong.')]),
        ('chow-hologram', 'HONGKONG_M1_PIANO.md', 'HK-7 ologramma', 'infolink', [
            ('WaltonSimons', 'Maggie. Denton should be arriving shortly.'),
            ('MaggieChow', 'And if he refuses to cooperate?'), ('WaltonSimons', "He won't."),
            ('MaggieChow', "You're very confident."),
            ('WaltonSimons', 'His brother made that mistake for us.'),
            ('MaggieChow', 'And Tong?'), ('WaltonSimons', 'Denton will take care of that.'),
            ('JCDenton', 'Simons...')]),
        ('sword-simons-call', 'HONGKONG_M1_PIANO.md', 'HK-7 chiamata aggiornata', 'infolink', [
            ('JCDenton', "I found the Dragon's Tooth in Chow's apartment."),
            ('WaltonSimons', 'Then secure it.'), ('JCDenton', 'I also found a recording.'),
            ('JCDenton', 'You and Maggie.'), ('WaltonSimons', 'Maggie Chow is an intelligence asset.'),
            ('JCDenton', 'You knew.'), ('WaltonSimons', "I know a great many things you don't, Denton."),
            ('JCDenton', 'Did she kill Yuen Kong?'), ('WaltonSimons', 'Your objective is Tracer Tong.')]),
        ('max-evidence', 'HONGKONG_DESIGN.md', '13', 'con', [
            ('MaxChen', 'Maggie had this?'), ('JCDenton', 'Yes.'),
            ('MaxChen', 'Then she killed Yuen Kong.'), ('JCDenton', "That's what the evidence suggests."),
            ('MaxChen', "And you're working with her."), ('JCDenton', "I'm working for UNATCO."),
            ('MaxChen', 'Is there a difference?')]),
        ('gordon-permission', 'HONGKONG_DESIGN.md', '14', 'con', [
            ('GordonQuick', 'Tong will speak with you.'), ('JCDenton', "I didn't ask to speak with him."),
            ('GordonQuick', 'No. You came to arrest him.')]),
        ('tong-introduction', 'HONGKONG_DESIGN.md', '15', 'con', [
            ('TracerTong', 'J.C. Denton.'), ('JCDenton', 'Tracer Tong.'),
            ('TracerTong', 'Paul said you would come.'), ('JCDenton', "Paul thought I'd come for help."),
            ('TracerTong', 'And instead?'), ('JCDenton', "You're coming with me."),
            ('TracerTong', 'To UNATCO.'), ('JCDenton', "That's right."),
            ('TracerTong', 'Even now.'), ('JCDenton', 'Especially now.')]),
        ('tong-evidence', 'HONGKONG_DESIGN.md', '16', 'con', [
            ('TracerTong', 'Paul tried to convince you.'), ('JCDenton', "He didn't."),
            ('TracerTong', 'Because he gave you a conclusion.'), ('TracerTong', "I'll give you evidence."),
            ('JCDenton', 'Where did you get this?'), ('TracerTong', 'Ask your employers.'),
            ('JCDenton', "I'm asking you."), ('TracerTong', 'VersaLife.')]),
        ('tong-alarm', 'HONGKONG_DESIGN.md', '17', 'con', [
            ('TracerTong', 'You led them here.'), ('JCDenton', 'Who?'),
            ('TracerTong', "You still don't know?")]),
        ('mj12-arrival', 'HONGKONG_DESIGN.md', '18-19', 'infolink', [
            ('WaltonSimons', 'Denton.'), ('JCDenton', "There's a tactical team entering the compound."),
            ('WaltonSimons', 'Correct.'), ('JCDenton', 'You tracked me.'),
            ('WaltonSimons', 'We tracked Tong.'), ('JCDenton', 'Through me.'),
            ('WaltonSimons', 'You completed your assignment.'),
            ('WaltonSimons', 'Stand by. The recovery team will take him into custody.'),
            ('JCDenton', "He's my prisoner."), ('WaltonSimons', 'Not anymore.')]),
        ('tong-escape', 'HONGKONG_DESIGN.md', '20', 'con', [
            ('JCDenton', 'Come with me.'), ('TracerTong', 'No.'),
            ('TracerTong', 'Then look at what they do after I leave.'),
            ('JCDenton', 'Orders were to secure the facility.'), ('MJ12TroopB', 'Our orders are different.')]),
        ('mj12-prisoner', 'HONGKONG_DESIGN.md', '21', 'con', [
            ('JCDenton', "He's unarmed."), ('MJ12TroopB', 'Move along, Agent Denton.'),
            ('JCDenton', "That's an order."), ('MJ12TroopB', 'Not from my chain of command.')]),
        ('simons-ending', 'HONGKONG_DESIGN.md', '23', 'infolink', [
            ('JCDenton', 'Tong escaped.'), ('JCDenton', 'Your team alerted him.'),
            ('WaltonSimons', 'Our team prevented him from destroying valuable intelligence.'),
            ('JCDenton', 'I had him.'), ('WaltonSimons', 'You were talking to him.'),
            ('JCDenton', 'I was interrogating him.'), ('WaltonSimons', 'Then consider the interrogation over.'),
            ('JCDenton', 'Tong gave me information about VersaLife.'),
            ('WaltonSimons', 'What information?'), ('JCDenton', "That's what I'm going to find out."),
            ('WaltonSimons', 'Denton...'), ('JCDenton', 'You wanted Tong.'),
            ('JCDenton', 'He led me to VersaLife.'), ('JCDenton', "I'm following the lead."),
            ('WaltonSimons', 'Very well.')]),
    ]


def prepare():
    calibration = json.loads((n.OUT / 'calibration.json').read_text())
    entries, sequence = {}, []
    for scene, document, section, kind, dialogue in scenes():
        source = re.sub(r'\s+', ' ', (DOCS / document).read_text(encoding='utf-8'))
        keys = []
        for speaker, text in dialogue:
            if text not in source:
                raise ValueError('Draft no longer matches notes: ' + scene + ': ' + text)
            # Maggie is physically present beside the projected Simons.
            line_kind = 'con' if scene == 'chow-hologram' and speaker == 'MaggieChow' else kind
            key = m.voice_key(speaker, text, line_kind)
            line = {'speaker': speaker, 'text': text, 'kind': line_kind,
                    'file': document, 'source_section': section, 'scene': scene, 'key': key}
            if key in entries and (entries[key]['speaker'], entries[key]['text']) != (speaker, text):
                raise ValueError('Draft hash collision: ' + key)
            entries.setdefault(key, line)
            keys.append(key)
        sequence.append({'scene': scene, 'document': document, 'section': section, 'keys': keys})
    plan = n.author_plan(calibration, list(entries.values()), PLAN)
    reused, new = synchronize(plan)
    for line in plan['lines'].values():
        speaker = line['speaker']
        contexts = {
            'MaxChen': 'Triad leader speaks with composed authority and guarded politeness; measured questions, minimal emotion.',
            'MaggieChow': 'Maggie is poised and manipulative, politely confident. Natural pauses, subtle emphasis; no dramatic breathiness.',
            'GordonQuick': 'Gordon distrusts an UNATCO agent and resents Paul\'s betrayal. Low, controlled challenge, without aggression or shouting.',
            'TracerTong': 'Tong calmly confronts JC with evidence. Thoughtful, deliberate sentences, restrained irony; no lecturing performance.',
        }
        if speaker in contexts:
            line['intent'] = contexts[speaker]
        if speaker == 'TracerTong' and line['text'] == 'No.':
            # The brief vowel has little headroom at Tong's original level.
            # A -1.1 dB ceiling matches it without a new take or harsher EQ;
            # verify still requires the actual true peak to stay <= -1 dBTP.
            line['limiter_ceiling_db'] = -1.1
    plan.update(revision='hong-kong-m1-explicit-notes-v4', status='draft-not-linked-to-runtime',
                source_hashes={name: n.sha(DOCS / name) for name in ('HONGKONG_DESIGN.md', 'HONGKONG_M1_PIANO.md')},
                scenes=sequence, reused_raw_takes=reused, new_takes=new,
                pending=['La spiegazione di Maggie su Tong e sulle Triadi e ancora prosa: servono battute scritte per sonorizzarla.'])
    n.save(PLAN, plan)
    print('HK drafts:', len(entries), 'distinct voice/channel lines;', len(reused), 'cached;', len(new), 'new.')


def review(plan):
    receipts = n.verify(plan)
    for scene, speaker in (('maggie-introduction', 'MaggieChow'), ('max-introduction', 'MaxChen'),
                           ('gordon-gate', 'GordonQuick'), ('tong-introduction', 'TracerTong')):
        record = next(x for x in plan['scenes'] if x['scene'] == scene)
        chunks = [bytes(int(n.RATE * .15) * 2)]
        for key in record['keys']:
            with wave.open(str(n.OUT / (key + '.wav'))) as reader:
                chunks.append(reader.readframes(reader.getnframes()))
            chunks.append(bytes(int(n.RATE * .25) * 2))
        n.write_pcm(n.OUT / (speaker + '_hk_preview.wav'), b''.join(chunks))
    report = ['# Hong Kong — battute dagli appunti', '',
              '%d audio V4 pronti, separati dal pacchetto del gioco finche le scene HK-3–HK-11 non sono collegate nel codice.' % len(plan['lines']), '',
              'Fonti: HONGKONG_DESIGN.md (M1) e HONGKONG_M1_PIANO.md. La nuova versione HK-7 sostituisce i punti 11–12 del vecchio design. Nessun dialogo dedotto dalla sola prosa.', '',
              'Voci nuove clonate dalle registrazioni originali: Maggie Chow, Max Chen, Gordon Quick, Tracer Tong e messaggero Red Arrow. Il messaggero mantiene i 32 secondi disponibili del solo attore Red_Arrow_01. JC mantiene il clone deadpan approvato. Simons remoto/ologramma usa il filtro InfoLink; Maggie nella stanza resta asciutta.', '',
              'Il comandante MJ12 usa la variante B: mantenere quel BarkBindName quando verra piazzato nel livello. Tempi e volume derivano dalle registrazioni originali per personaggio.', '',
              'Verificati durata, livello, picchi, formato mono PCM 22050 Hz e integrita delle take. Scarto massimo %.2f LU; picco massimo %.2f dBTP.' %
              (max(abs(receipts[k]['input_i']-v['target_lufs']) for k,v in plan['lines'].items()), max(receipts[k]['input_tp'] for k in plan['lines'])), '',
              '| Personaggio | Audio |', '|---|---:|']
    report += ['| %s | %d |' % item for item in sorted(Counter(x['speaker'] for x in plan['lines'].values()).items())]
    report += ['', 'Restano da preparare:', '', *['- '+x for x in plan['pending']], '',
               'Il piano JSON registra ordine delle scene, fonte, voce, testo originale, prompt e tempi. Quando la stessa battuta viene aggiunta al codice, la cache riusa la take compatibile.']
    (DOCS / 'HK_VOICES_DRAFT.md').write_text('\n'.join(report)+'\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('prepare', 'generate', 'verify'))
    args = parser.parse_args()
    if args.command == 'prepare':
        prepare()
        return
    plan = json.loads(PLAN.read_text())
    if any(n.sha(DOCS/name) != digest for name,digest in plan['source_hashes'].items()):
        raise ValueError('HK notes changed; prepare the current written dialogue first.')
    if args.command == 'generate':
        n.generate(list(plan['lines'].values()), plan)
    review(plan)


if __name__ == '__main__':
    main()
