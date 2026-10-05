"""Author a line-by-line acting plan from the original transcripts and mod scenes.

Emotions are an editorial interpretation of the words and scene context, not
automatically measured from the reference audio. References remain available
in samples/manifest.json for listening comparisons.
"""
import json
from pathlib import Path

from make_voices import extract

HERE = Path(__file__).resolve().parent

# Character, original clip indices, baseline voice direction, stability.
PROFILES = {
    'JCDenton': ([0, 5, 12, 35], 'flat, dry, restrained', 1.0,
                 'Low-key questions and clipped assertions. Preserve the deadpan delivery even when challenging another agent.'),
    'AnnaNavarre': ([5, 6, 13, 24], 'cold, clipped, controlled', 0.5,
                    'Orders, reprimands and dry mockery. Authority comes from precise diction and controlled irritation.'),
    'GuntherHermann': ([14, 15, 17, 23], 'low, gravelly, deliberate', 0.5,
                       'Heavy declarative phrases about procedure, loyalty and orders. Threats remain deliberate and matter-of-fact.'),
    'UNATCOTroop': ([6, 7, 18, 24], 'matter-of-fact, military', 1.0,
                    'Short tactical reports and routine instructions. Personal comments need only a small change in tone.'),
    'MIB': ([0, 2, 5, 23], 'flat, precise, detached', 1.0,
            'Formal orders and clinical descriptions of subjects. Suspicion is conveyed with restrained emphasis.'),
    'AlexJacobson': ([2, 17, 18, 20], 'conversational, restrained', 0.5,
                     'Practical support and concern about colleagues. The private warning to JC is quiet and serious.'),
    'PaulDenton': ([0, 6, 9, 14], 'weary, quietly earnest', 0.5,
                   'An injured brother giving advice and explaining risks. Concern and persuasion remain intimate and controlled.'),
}

# These entries follow extract()'s scene order, but are keyed by exact text when
# saved. Wording checks below prevent directions drifting onto another line.
DIRECTIONS = [
    ('JC Denton. You came back.', 'measured, guarded approval', 'Gunther acknowledges JC returning to duty; a guarded observation.'),
    ('You sound surprised.', 'dry, mildly skeptical', 'JC tests Gunther with a deadpan remark.'),
    ('Your brother did not. Agents who listen to terrorists, they do not come back.', 'stern, deliberate', 'Contrast JC with Paul; a judgment and implicit warning.'),
    ("I listened. I didn't agree.", 'calm, firm', 'JC draws a precise distinction without becoming defensive.'),
    ('Good. Then we understand each other.', 'measured approval', 'Gunther accepts the answer while asserting a shared rule.'),
    ("Manderley's orders: I bring you home. We have a plane ready past the fort. Mr. Simons wants you on Liberty Island within the hour.", 'matter-of-fact, authoritative', 'An operational briefing; emphasis belongs on the orders and deadline.'),
    ('Simons?', 'dry, questioning', 'A small skeptical question, not alarm or excitement.'),
    ('Yes. FEMA, UNATCO... today everyone wants a piece of Paul Denton.', 'grim, matter-of-fact', 'Gunther states that the hunt for Paul has political weight.'),
    ("Let's go.", 'calm, decisive', 'JC accepts the next step tersely.'),
    ('Come. We walk. And JC Denton... do not make me carry you.', 'low, quietly threatening', 'A command followed by a warning; avoid turning the last line into a joke.'),
    ('Agent Denton. You were the last one to see him.', 'formal, quietly suspicious', 'MIB opens a controlled interrogation.'),
    ('He ran before I could stop him.', 'flat, guarded', 'JC provides the minimum factual answer.'),
    ('Of course he did.', 'dry, skeptical', 'MIB does not believe the explanation; no laughter or playful sarcasm.'),
    ('Agent Hermann is waiting for you at Battery Park. We will take it from here.', 'formal, dismissive', 'The MIB ends the interview and takes jurisdiction.'),
    ('Proceed to Battery Park, Agent Denton. This floor is under our authority now.', 'formal, firm', 'A bureaucratic order excluding JC from the investigation.'),
    ("Your brother's trail ends here. Ours doesn't.", 'cold, matter-of-fact', 'A veiled assertion that the investigation will continue.'),
    ("Bedroom's clear. Check the bathroom.", 'brisk, professional', 'A soldier reports and assigns the next search area.'),
    ("Window's open. He could've gone down the fire escape.", 'alert, factual', 'Observe evidence and suggest an escape route.'),
    ("Nobody touches the apartment until the MIBs are done with it.", 'firm, procedural', 'Protect the scene while another unit works.'),
    ('Agent Denton. Sorry about your brother, sir.', 'quiet, respectful', 'Brief, awkward sympathy to an officer; restrained, not mournful.'),
    ("Lobby's sealed. Nobody in, nobody out.", 'brisk, professional', 'Routine perimeter report.'),
    ('He was bleeding. Check the stairwell for blood.', 'alert, factual', 'Use the injury as a search clue.'),
    ("UNATCO's locking down the district.", 'matter-of-fact', 'Report an ongoing deployment.'),
    ('Orders are to bring Paul Denton in alive.', 'firm, procedural', 'State the rules of the arrest, emphasizing alive slightly.'),
    ('I heard your brother slipped through the perimeter.', 'quiet, conversational', 'A cautious personal comment, not combat alarm.'),
    ("Glad one Denton still remembers which side he's on.", 'dry, restrained approval', 'A partisan remark with a slight edge; not celebratory.'),
    ("Subway's open for you, Agent. Hermann's waiting at Battery Park.", 'professional, informative', 'Clear route instructions for an officer.'),
    ("Curfew's in effect. Civilians off the street.", 'firm, professional', 'Enforce a routine curfew without shouting.'),
    ("Agent Hermann's up by the old fort, sir.", 'professional, informative', 'Give a location succinctly.'),
    ("Transport's prepped. Wheels up as soon as you're aboard.", 'brisk, professional', 'Report readiness and the boarding condition.'),
    ('Denton! Where is he?', 'firm, restrained urgency', 'Anna has run to JC and immediately demands Paul\'s location; urgency rather than panic.'),
    ('Gone. He ran the moment I said no.', 'flat, factual', 'JC answers without guilt, triumph or surprise.'),
    ('You had him in a room with one door, and you let him walk out of it.', 'controlled irritation', 'A deliberate reprimand; controlled anger rather than a shouted outburst.'),
    ('He made his choice. I made mine.', 'calm, firm', 'JC asserts personal responsibility in two balanced statements.'),
    ("He's carrying UNATCO codes, troop rotations, safehouse locations. Every hour he's out there, agents die.", 'stern, controlled urgency', 'Explain the operational risk, hardening slightly on agents die.'),
    ("Then don't waste the hour on me.", 'dry, firm', 'JC pushes back with restrained irony.'),
    ("I'm taking the subway sweep. If he went underground, I'll find him.", 'decisive, professional', 'Anna moves from blame to a search plan.'),
    ("Hermann's waiting for you up by the old fort. Manderley wants you back on the island.", 'matter-of-fact, authoritative', 'Hand off JC and relay orders.'),
    ("And Denton. Next time you see your brother, make sure you're the one who walks away.", 'low, coldly threatening', 'A personal warning delivered with deliberate control.'),
    ('Is that a threat?', 'matter-of-fact', 'JC asks a direct, restrained question; no fear or amused performance.'),
    ('Yes.', 'dry, deadpan', 'Anna deliberately leaves both meanings in play. A short, level answer.'),
    ('JC. Manderley wants you back at headquarters.', 'serious, professional', 'Alex initiates a recall after Paul\'s departure.'),
    ("What's happened?", 'calm, questioning', 'JC asks for the missing information.'),
    ('Your brother happened.', 'dry, concerned', 'A brief, bitter shorthand for the problem; no comic punchline.'),
    ("They've revoked his clearance. Every UNATCO unit in Manhattan has his picture.", 'serious, factual', 'Report an escalating institutional response.'),
    ("I'm on my way.", 'calm, decisive', 'JC acknowledges and acts.'),
    ('JC...', 'quiet, hesitant', 'Alex pauses to make a personal warning, not a dramatic gasp.'),
    ('What?', 'flat, questioning', 'JC invites Alex to finish without impatience or shouting.'),
    ('Just get back here before somebody decides you need a new picture too.', 'quiet, concerned', 'Concern for JC\'s safety beneath a restrained dark warning.'),
    ("Hermann and Navarre are at Battery Park. Take the subway; the troops on the street will let you through.", 'professional, quietly reassuring', 'Give practical route information and confirmation of access.'),
    ("JC? The transmitter's live, but nothing's going out. What's wrong?", 'concerned, questioning', 'Paul notices the signal has not been sent and asks why.'),
    ("Nothing's wrong. I'm not sending it.", 'flat, firm', 'JC states a deliberate refusal rather than reacting in anger.'),
    ("JC... you've seen what's down there.", 'quiet, earnest', 'Paul appeals to shared evidence, with subdued disbelief.'),
    ("I've seen enough to know I'm not deciding this over a radio. I'm coming back. We'll talk face to face.", 'calm, resolute', 'JC sets a boundary and offers a face-to-face discussion.'),
    ("...All right. I'll be here.", 'quiet, resigned', 'Paul accepts the delay with restrained disappointment.'),
]


def main():
    lines = extract()
    if [x['text'] for x in lines] != [x[0] for x in DIRECTIONS]:
        raise SystemExit('Dialogue changed: review the authored delivery entries before generating.')
    manifest = json.loads((HERE / 'samples/manifest.json').read_text(encoding='utf-8'))
    characters = {}
    for name, (indices, tags, stability, analysis) in PROFILES.items():
        sample = manifest[name]
        characters[name] = {
            'baseline_tags': tags, 'settings': {'stability': stability},
            'analysis': analysis, 'reference_file': 'samples/' + sample['file'],
            'reference_clips': [sample['clips'][i] for i in indices],
        }
    entries = {}
    for line, (_, tags, intent) in zip(lines, DIRECTIONS):
        profile = characters[line['speaker']]
        entries[line['key']] = {
            **line, 'intent': intent, 'delivery_tags': tags,
            'tts_text': '[%s] [%s] %s' % (profile['baseline_tags'], tags, line['text']),
        }
        if line['text'] == 'Is that a threat?':
            entries[line['key']]['tts_text'] = '[matter-of-fact] ' + line['text']
            entries[line['key']]['settings'] = {
                'model_id': 'eleven_v4', 'stability': 0.9, 'similarity_boost': 0.75,
            }
    plan = {
        'revision': 'restrained-dialogue-v1', 'model_id': 'eleven_v3',
        'analysis_basis': 'Original game transcripts in samples/manifest.json and complete mod scenes. Emotional labels are editorial interpretations; audio listening remains the quality reference.',
        'rule': 'Preserve every spoken word and the plain-text audio key. Use vocal direction only; no laughter, sighs, music or other added sounds.',
        'settings': {'model_id': 'eleven_v3', 'similarity_boost': 0.8, 'style': 0.0, 'use_speaker_boost': False},
        'characters': characters, 'lines': entries,
    }
    (HERE / 'delivery_plan.json').write_text(json.dumps(plan, indent=2) + '\n', encoding='utf-8')
    report = ['# Direzione delle voci', '',
              'Interpretazione dei testi originali e del contesto della mod. Le etichette emotive sono scelte di regia; i campioni originali restano il riferimento per l\'ascolto.', '',
              'I tag cambiano solo la richiesta ElevenLabs. Il testo nel gioco e il nome del Sound restano identici.', '']
    for name, profile in characters.items():
        report += ['## ' + name, '', profile['analysis'], '', 'Riferimenti originali:', '']
        for clip in profile['reference_clips']:
            report.append('- `%s` a %.3fs: %s' % (clip['conversation'], clip['start_seconds'], clip['text']))
        report += ['', 'Battute della mod:', '']
        for entry in entries.values():
            if entry['speaker'] == name:
                report += ['- **%s**: %s\n  Direzione: %s\n  Prompt: `%s`' %
                           (entry['key'], entry['text'], entry['intent'], entry['tts_text'])]
        report += ['']
    (HERE / 'delivery_plan.md').write_text('\n'.join(report), encoding='utf-8')
    print('Authored directions for %d lines and %d characters.' % (len(entries), len(characters)))


if __name__ == '__main__':
    main()
