"""Author current scene intentions and safely migrate compatible approved takes.

Run after natural_voices.py calibrate. Legacy raw audio is reused only when
speaker, spoken prompt and voice settings still match its receipt. Channel
processing is local and must be refreshed when a take moves across channels.
"""
import hashlib
import json
import shutil
from collections import Counter
from pathlib import Path
import make_voices as m
import natural_voices as n


def intent(line):
    speaker, text = line['speaker'], line['text']
    if speaker == 'JCDenton':
        if text == 'Is that a threat?':
            return 'A level, dry challenge to Anna. No shout or emotional pitch rise.'
        if text in ("He couldn't talk me into it.", 'He made his decision.', 'Those are my orders.'):
            return 'JC has chosen his side. Plain, settled answer; no anger or triumph.'
        if text in ('You know where?', 'Told by whom?', 'And you?', 'You know him?', 'Whose base is this?'):
            return 'JC probes for information with a flat, measured question.'
        return 'JC replies in his basic, slightly rough deadpan; preserve a small natural pause between sentences.'
    if speaker == 'Jock':
        if text == "These guys don't look like UNATCO.":
            return 'Jock notices the unfamiliar guards at the Hong Kong base, with quiet unease.'
        if text == "That wasn't what I said.":
            return 'Jock dryly corrects JC: the concern is who the guards are, not whether they expect them.'
        if text in ("Paul's put a lot on the line for you.", 'I guess you did too.', "Couldn't talk him into it?"):
            return 'Quiet concern about Paul and the brothers choosing different sides. Restrained, no melodrama.'
        if text in ('Ready?', 'Get in.', "Don't take too long."):
            return 'Pilot checks readiness and gives a practical boarding instruction, calmly.'
        if 'Tong' in text or 'low profile' in text:
            return 'Jock gives a discreet, careful briefing before JC searches for Tong; conversational pauses.'
        return 'Jock considers JC\'s choice, in a low, matter-of-fact conversational register.'
    if speaker == 'AnnaNavarre':
        if text == 'Yes.':
            return 'Anna confirms the threat with a short, level answer.'
        if 'walks away' in text:
            return 'Cold, controlled warning about Paul; threatening through certainty, not shouting.'
        return 'Anna is focused on finding Paul. Firm, clipped report or question, with controlled urgency.'
    if speaker == 'GuntherHermann':
        if line['file'] == 'UCSceneGuntherTon.uc':
            return 'Gunther challenges JC outside the hotel, suspicious and disciplined. Firm, level diction; leave space between questions without shouting.'
        if text in ('Damn it.', 'Of course it is.', 'We missed him.', 'Because we were late.'):
            return 'Gunther finds Paul has escaped. Brief, contained frustration, low and dry; no theatrical anger.'
        if 'Paul' in text or text in ('I asked for this assignment.', 'He betrayed the Coalition. UNATCO. Everyone who worked with him.'):
            return 'Gunther takes Paul\'s betrayal personally. Quiet, severe certainty; controlled weight on the key word, no melodrama.'
        return 'Gunther gives a deliberate report or order during the hotel search. Cold and professional, with natural sentence pauses.'
    if speaker == 'GilbertRenton':
        return 'Hotel owner questions armed agents entering his property. Guarded and mildly indignant, ordinary conversational volume.'
    if speaker == 'MIB':
        if line.get('conversation') == 'UC_LMForeshadow':
            return 'Government agent concludes a quiet, coercive shipment arrangement in Lucky Money. Flat certainty, conversational volume, no combat delivery.'
        return 'Special-assignment agent states operational authority. Flat, impersonal certainty, no raised voice or villainous flourish.'
    if speaker == 'Red_Arrow_01':
        return ('Red Arrow contact quietly disputes a shipment with government agents; wary and level, no confrontation shout.'
                if line.get('conversation') == 'UC_LMForeshadow' else
                'Discreet Red Arrow messenger directs JC to Max Chen. Short, practical phrases with clear pauses, no hurry.')
    if speaker == 'MaxChen':
        return ('Max receives evidence against Maggie and agrees to a truce. Composed authority with restrained suspicion; natural pauses.'
                if 'Maggie' in text or 'truce' in text or 'war' in text else
                'Max receives an UNATCO agent politely but guardedly. Measured diction and minimal emotion.')
    if speaker == 'MaggieChow':
        return ('Maggie asks Simons about their plan in a recorded exchange. Quiet confidence, controlled questions.'
                if line.get('conversation') == 'M06WaltonHolo' else
                'Maggie gives JC a persuasive, self-serving account of Tong and the Triads. Poised and polite, subtle emphasis, no melodrama.')
    if speaker == 'GordonQuick':
        return ('Gordon reluctantly lets JC reach Tong after the truce. Guarded respect and clear practical directions; read the code exactly as authored.'
                if any(word in text for word in ('truce', 'unexpected', 'laboratory', 'speak with you')) else
                'Gordon distrusts JC for abandoning Paul. Low, controlled challenge and dry questions, no shouting.')
    if speaker.startswith('UNATCOTroop'):
        return 'Friendly patrol addresses a superior during the search for Paul. Calm and professional, no combat shout.'
    if speaker == 'MJ12Troop':
        if line.get('conversation') == 'UC_SPTechTalk':
            return 'Special Projects technician describes the data wipe in a calm, clinical register. Brief factual answers, no hostility or triumph.'
        if text in ('Special Projects Directorate.', 'Coalition.'):
            return 'The officer gives an evasive official label, calmly and without defensiveness.'
        return 'Hong Kong base officer gives a formal welcome and directions, politely but guarded.'
    if speaker == 'MJ12TroopB':
        return 'Base guard is terse and wary about Tong. Matter-of-fact, with a short pause at each sentence.'
    if speaker == 'MJ12Commando':
        return 'Special Projects commander gives impersonal procedural orders. Controlled military authority, deliberate pauses, no combat shout.'
    if speaker in ('TriadLumPath', 'TriadRedArrow'):
        return 'Tong guard warns a tolerated visitor. Low, wary and firm, at ordinary conversation volume.'
    if speaker == 'ScientistConsulting':
        return 'Unarmed technician fears being mistaken for security. An urgent plea with clear words; frightened but intelligible, no prolonged scream.'
    if speaker == 'TracerTong':
        return 'Tong presents evidence and questions JC with patient, restrained certainty. Clear sentence pauses, no sermon or theatrical emotion.'
    if speaker == 'PaulDenton':
        return ('Paul speaks over InfoLink, concerned but contained, after JC refuses to send the signal.'
                if line['channel'] == 'radio' else
                'Paul and JC have reached an impasse. Quiet resignation or concern, without theatrical emotion.')
    if speaker == 'WaltonSimons':
        if text == 'It answers the part you need to know.':
            return 'Simons closes down JC\'s question with calm, bureaucratic certainty; no overt anger.'
        if text == 'Including your brother.':
            return 'Simons makes the link to Paul plain and cold, with a short pointed pause.'
        return 'Remote command briefing from Simons: controlled authority, deliberate diction and minimal emotion.'
    return 'Restrained performance consistent with the surrounding scene.'


def synchronize(plan):
    cfg = json.loads(Path(m.VOICES).read_text(encoding='utf-8'))
    receipts_path = n.OUT / 'receipts.json'
    receipts = json.loads(receipts_path.read_text(encoding='utf-8'))
    old = list(receipts.values())
    reused = []
    new = []
    for key, line in plan['lines'].items():
        line['intent'] = intent(line)
        # Directions remain short. Stability and clone samples carry the
        # understated original-game style; avoid stacking emotional tags.
        if line['speaker'] == 'AnnaNavarre' and line['text'] != 'Yes.':
            line['delivery_tags'] = 'firm, restrained'
            line['tts_text'] = '[firm, restrained] ' + line['tts_text'].split('] ', 1)[1]
        if line['speaker'] == 'Jock' and line['text'] in ("Paul's put a lot on the line for you.", 'I guess you did too.'):
            line['delivery_tags'] = 'serious, restrained'
            line['tts_text'] = '[serious, restrained] ' + line['tts_text'].split('] ', 1)[1]
        if line['speaker'] == 'GuntherHermann':
            tag = 'firm, restrained' if line['file'] == 'UCSceneGuntherTon.uc' else 'serious, restrained'
            line['delivery_tags'] = tag
            line['tts_text'] = '[' + tag + '] ' + line['tts_text'].split('] ', 1)[1]
        if line['speaker'] == 'ScientistConsulting':
            line['delivery_tags'] = 'urgent, restrained'
            line['tts_text'] = '[urgent, restrained] ' + line['tts_text'].split('] ', 1)[1]
        settings = n.settings_for(line, plan)
        # Prefer this key's approved receipt over older entries for the same
        # utterance. Legacy hashes must not displace a current verified take.
        candidates = sorted(old, key=lambda candidate: (candidate.get('key') != key, candidate.get('channel') != line['channel']))
        for candidate in candidates:
            if (candidate.get('speaker') != line['speaker'] or candidate.get('text') != line['text']
                    or candidate.get('tts_text') != line['tts_text']
                    or candidate.get('settings') != settings):
                continue
            old_key = candidate['key']
            # A migrated line keeps its original generation seed. The receipt
            # proves which voice generated it; never transfer audio by text alone.
            old_seed = candidate.get('fingerprint_seed', int(old_key[1:]))
            payload = {'voice_id': cfg[line['speaker']], 'text': line['tts_text'],
                       'settings': settings, 'seed': old_seed}
            fingerprint = hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()
            raw = n.OUT / 'raw' / (old_key + '.mp3')
            if candidate.get('fingerprint') != fingerprint or not raw.exists() or candidate.get('raw_sha256') != n.sha(raw):
                continue
            line['seed'] = old_seed
            destination = n.OUT / 'raw' / (key + '.mp3')
            if destination != raw:
                shutil.copy2(raw, destination)
            receipts[key] = {**candidate, **line, 'fingerprint': fingerprint,
                             'fingerprint_seed': old_seed, 'migrated_from': old_key}
            if (candidate.get('processing_fingerprint') != n.processing_fingerprint(line)
                    or old_key != key or candidate.get('channel') != line['channel']
                    or any(candidate.get(field) != line.get(field) for field in (
                        'processing_channel', 'processing_reference', 'target_lufs',
                        'loudness_tolerance_lu', 'duration_range', 'tempo_target'))
                    or ('limiter_ceiling_db' in line and
                        candidate.get('limiter_ceiling_db', -1.5) != line['limiter_ceiling_db'])):
                # Raw MP3 is the unprocessed TTS response. Channel filtering
                # is local, and the identical API payload above proves this
                # take is reusable. Require fresh processing before apply.
                receipts[key]['valid'] = False
                receipts[key]['migrated_from_channel'] = candidate.get('channel')
            reused.append(key)
            break
        else:
            new.append(key)
    keys = list(plan['lines'])
    if len(keys) != len(set(keys)):
        raise ValueError('Voice hash collision: change key scheme before generating')
    n.save(receipts_path, receipts)
    return reused, new


def main():
    plan = json.loads(n.PLAN.read_text(encoding='utf-8'))
    reused, new = synchronize(plan)
    n.save(n.PLAN, plan)
    n.save(n.OUT / 'route_generation.json', {
        'revision': plan['revision'], 'dialogue_count': len(plan['lines']),
        'speakers': dict(Counter(line['speaker'] for line in plan['lines'].values())),
        'reused_raw_takes': reused, 'new_takes': new,
        'source_hashes': {path.name: n.sha(path) for path in Path(m.SRC).glob('*.uc')
                          if not path.name.endswith('CheckCommandlet.uc')},
        'key_scheme': 'V + hash(speaker|channel|unchanged game dialogue)',
        'soldier_identity': 'Native saved BarkBindName A/B, independent of temporary dialogue BindName.'})
    print('Current dialogue:', len(plan['lines']), 'Compatible cached takes:', len(reused),
          'New takes required:', len(new), flush=True)


if __name__ == '__main__':
    main()
