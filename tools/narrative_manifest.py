"""Ordine, titoli e note di regia del documento di narrative design (docs\\NARRATIVE_DESIGN.md).

Lo usa tools\\export_dialogues.py, che estrae i dialoghi dal codice: qui c'e' solo quello
che il codice non dice (in che ordine si incontrano le scene, come presentarle). Una
conversazione che non compare qui finisce comunque nel documento, in fondo, sotto
"Not placed yet": cosi' non se ne perde nessuna.
"""
import re

NAMES = {
    'JCDenton': 'JC Denton', 'PaulDenton': 'Paul Denton', 'GuntherHermann': 'Gunther Hermann',
    'AnnaNavarre': 'Anna Navarre', 'GilbertRenton': 'Gilbert Renton', 'UCSpecialAgent1': 'Special Agent',
    'UCSpecialAgent2': 'Special Agent', 'UCSpecialAgent3': 'Special Agent (the shooter)', 'UCGateGuard': 'UNATCO Trooper', 'UCGreeter': 'UNATCO Trooper',
    'Jock': 'Jock', 'UCHKOfficer': 'Special Projects Liaison', 'WaltonSimons': 'Walton Simons',
    'UCYardRaider1': 'Luminous Path Raider', 'UCYardRaider2': 'Luminous Path Raider', 'UCYardRaider3': 'Luminous Path Raider',
    'UCMessenger': 'Red Arrow Messenger', 'UCLMAgent1': 'Government Agent', 'UCLMAgent2': 'Second Government Agent',
    'UCLMRedArrow': 'Red Arrow', 'MaxChen': 'Max Chen', 'MaggieChow': 'Maggie Chow',
    'UCMaggieHolo': 'Maggie Chow (recording)', 'GordonQuick': 'Gordon Quick', 'TracerTong': 'Tracer Tong',
    'UCTongGuard': 'Luminous Path Guard', 'UCSPTech1': 'Special Projects Technician',
    'UCSPCommander': 'Special Projects Commander', 'UCPrisoner': 'Prisoner',
    'AlexJacobson': 'Alex Jacobson', 'Eva': 'Eva', 'UCBPBum': 'Bum', 'UCBPCop1': 'Police Officer',
    'UCBPCop2': 'Police Officer', 'UCBPJockBody': 'Jock (body)',
}

# flag -> cosa vuol dire, per chi legge
FLAGS = {
    'UNATCORouteCommitted': 'JC told Paul he is staying with UNATCO',
    'AnnaNavarre_Dead': 'Anna Navarre is dead',
    'M03PlayerKilledAnna': 'Anna died on the 747',
    'PlayerKilledLebedev': 'JC killed Lebedev',
    'AnnaKilledLebedev': 'Anna killed Lebedev',
    'ManderleyDebriefing03_Played': 'Manderley debriefed JC after the airfield',
    'GuntherTonEncounterPlayed': 'JC met Gunther outside the hotel',
    'GuntherTonSearchComplete': 'the search of Paul\'s room is over',
    'GuntherKnowsJCMetPaul': 'Gunther knows JC spoke to Paul',
    'GuntherReportedJCConduct': 'Gunther reported JC to Manderley',
    'UC_PaulContactReportSent': 'Gunther\'s report "JC spoke to Paul" was sent',
    'UC_AnnaPaulReportReceived': 'Anna received Gunther\'s report',
    'UC_AnnaKnowsJCMetPaul': 'Anna knows JC spoke to Paul',
    'UC_AnnaMetroOpened': 'Anna\'s first exchange at the subway gate was played',
    'UC_HeardLebedevMJ12': 'JC heard Lebedev name Majestic 12',
    'UC_MJ12NameKnown': 'JC knows the name Majestic 12',
    'UC_Messenger_Played': 'the Red Arrow messenger spoke to JC',
    'UC_LMForeshadow_Played': 'JC overheard the government agents at the Lucky Money',
    'MeetMaxChen_Played': 'JC met Max Chen',
    'Have_Evidence': 'JC found the Dragon\'s Tooth in Maggie Chow\'s apartment',
    'MaxChenConvinced': 'Max Chen declared the truce',
    'QuickLetPlayerIn': 'Gordon Quick gave JC access to Tong',
    'UC_MaggieMeet_Played': 'JC met Maggie Chow',
    'UC_GordonMeet_Played': 'JC met Gordon Quick',
    'UC_MaxEscort_Played': 'the Red Arrow greeted JC at the Lucky Money',
    'UC_MaxEscortDone': 'the Red Arrow reached Max Chen\'s doors',
    'UC_LobbyAgentPosted': 'the Special Agent took his post at the front desk',
    'UC_GuntherNotNowCD': '(cooldown of the line)',
    'AlwaysFalse': '(never: placeholder)',
}

# Capitoli: (titolo, introduzione, [voci]). Una voce e':
#   ('conv', nome, titolo, nota)      una conversazione
#   ('say', file, funzione, titolo, nota)   un InfoLink
#   ('text', markdown)                testo libero
#   ('barks',)                        le battute dei soldati di pattuglia
CHAPTERS = [
    ('Part I - New York', None, []),
    ('1. The fork: Paul at the \'Ton', """Mission 4 of the original game. Paul asks JC to send the NSF distress signal from the
transmitter. In the original game the player can refuse and go back to Paul, and a short
exchange plays (conversation `M04PlayerLikesUNATCO`, voiced, part of the original script:
JC says UNATCO is not perfect but he is not a terrorist; Paul answers that then they go
their separate ways). There it changes nothing: the raid happens anyway. **In the mod that
exchange is the fork**: if JC found the evidence at NSF headquarters, did not send the
signal and tells Paul no, the UNATCO route is committed. The original lines are not
reproduced here; everything below is new.

Paul stays in his chair. If JC talks to him again:""", [
        ('conv', 'UC_PaulAfter1', 'Paul, after the refusal (1)', None),
        ('conv', 'UC_PaulAfter2', 'Paul, after the refusal (2)', None),
        ('conv', 'UC_PaulAfter3', 'Paul, after the refusal (3)', None),
        ('conv', 'UC_PaulAfter4', 'Paul, repeat line', None),
        ('text', 'Paul disappears from the hotel the moment JC leaves the building. Nobody sees him go.'),
    ]),
    ('2. Gunther outside the \'Ton', """JC leaves through the front door. Gunther Hermann and two "Special Agents" (Men in
Black) are standing at the foot of the steps. They do not walk up to JC: the exchange
starts when JC comes down to them. Afterwards they climb the steps in single file and go
in; they stop at the hotel door while JC is looking and enter only when he is not.

Leaving through the bedroom window skips the scene. Attacking Gunther or the agents ends
the loyalist route.""", [
        ('conv', 'UC_GuntherTon1', 'The confrontation (G01 / G02)',
         'Two versions, chosen when the scene is set up. Gunther never has proof that JC killed Anna '
         '(Alex erased the logs), so even in the harsher version it is anger, not an accusation.'),
        ('conv', 'UC_GuntherTon2', 'As Gunther walks away',
         'Overheard, no cinematic camera: Gunther answers without stopping. Skipped in the "Anna is dead" '
         'version, where the same request is already inside the confrontation.'),
    ]),
    ('3. The search of the hotel (optional)', """If JC goes back inside, he can follow the search. Gunther and one agent cross the lobby
and climb to Paul's apartment; the second agent takes a post at the front desk. Gilbert
Renton is behind the desk: when JC commits to UNATCO, the side story of his daughter is
closed without JC (it would otherwise keep Gilbert upstairs).

Paul is gone. A trail of small blood stains leads from his chair to the bedroom window, a
used medkit lies on the floor. Rule for the writing: nobody deduces *when* Paul left from
the blood or the medkit.""", [
        ('conv', 'UC_GuntherNotNow', 'If JC talks to Gunther on the way up', None),
        ('conv', 'UC_GuntherLobby', 'Crossing the lobby (G03)',
         'Overheard while they walk. If Gilbert has not reached the desk yet, the lines are addressed to JC.'),
        ('conv', 'UC_GuntherRoom', 'Paul\'s room (G06)', 'Starts when JC is close enough to hear it.'),
        ('conv', 'UC_LobbyChat', 'Gilbert and the agent at the desk',
         'Overheard when JC passes the desk after the agent has taken his post.'),
        ('text', '**After the search**, JC can question Gunther. One exchange per click, in this order; '
                 'each plays once.'),
        ('conv', 'UC_GuntherRW1', 'Gunther, after the search',
         'Optional click. If JC avoided Gunther outside, the missing operational exchange plays here.'),
        ('conv', 'UC_GuntherRW2', 'Paul\'s channels and the assignment', 'Optional second click.'),
        ('conv', 'UC_GuntherG17', 'G17 - repeat line', None),
    ]),
    ('4. Hell\'s Kitchen', """The streets are held by UNATCO: friendly patrols, the exits to other districts closed,
the subway to Battery Park open for UNATCO personnel. One trooper recognises JC.""", [
        ('conv', 'UC_GreeterHello', 'The trooper who recognises JC (overheard)', None),
        ('conv', 'UC_GreeterTalk', 'The trooper who recognises JC (if JC talks to him)', None),
        ('say', 'UCSceneJockStreet.uc', 'JockLine', 'Jock calls from Battery Park (InfoLink)',
         'As soon as JC is out of the \'Ton and walking the street towards the subway, after Gunther (or after the '
         'window exit). Jock is still calm, just uneasy: men in suits around the park. New goal: meet Jock in '
         'Battery Park, fast.'),
        ('barks',),
        ('text', """### The subway gate

Anna Navarre guards the gate. **One opening** resolves the meeting, chosen from six by what
Anna knows: who killed Lebedev (JC, Anna, or an outcome she cannot attribute) and whether
Gunther's report "JC spoke to Paul" has reached her. She judges JC's reliability as an
agent; she does not repeat Gunther's threat. If Anna is dead, a trooper stands there instead."""),
        ('conv', 'UC_AnnaA01', 'A01 - JC killed Lebedev, report received', None),
        ('conv', 'UC_AnnaA02', 'A02 - JC killed Lebedev, no report', None),
        ('conv', 'UC_AnnaA03', 'A03 - Anna killed Lebedev, report received', None),
        ('conv', 'UC_AnnaA04', 'A04 - Anna killed Lebedev, no report', None),
        ('conv', 'UC_AnnaA05', 'A05 - outcome not attributable, report received', None),
        ('conv', 'UC_AnnaA06', 'A06 - outcome not attributable, no report', None),
        ('text', '**If JC talks to her again**, one exchange per click:'),
        ('conv', 'UC_AnnaA10', 'A10 - why she is there', None),
        ('conv', 'UC_AnnaA11', 'A11 - Paul\'s records', 'Here Anna can learn from JC himself that he met Paul.'),
        ('conv', 'UC_AnnaA12', 'A12 - about Gunther', None),
        ('conv', 'UC_AnnaA13', 'A13 - repeat line', None),
        ('conv', 'UC_GateGuard', 'T01 - the trooper, if Anna is dead',
         'He does not know who killed Anna and does not mention the 747.'),
        ('conv', 'UC_GateGuardAgain', 'The trooper, repeat line', None),
    ]),
    ('5. Battery Park', """JC was supposed to fly to Hong Kong with Jock. Jock calls as JC comes up from the subway and is
shot mid-call by the Men in Black (shown as "Special Agent"), who hold his helicopter with the police at the
perimeter. His body lies under a tarp behind the vine wall, with Paul's datacube and his flask: finding it is
optional and unlocks the confrontation. The agent who shot him guards it, pistol in hand, and walks up to JC to
send him away. A replacement pilot, Eva, flies JC out: she lands at a flare in the clearing south of the
subway, coming down only when JC comes near. Flags for Missions 6/7: UC_JockDead,
UC_BP_JockBodyFound, UC_BP_PaulCubeRead, UC_BP_MIBConfronted, UC_BP_EvaWallLine.""", [
        ('say', 'UCSceneBatteryPark.uc', 'JockLine', 'Jock\'s call, cut by the gunshot (InfoLink)',
         'Automatic a second and a half after JC is out of the subway kiosk. When the call ends JC hears the gunshot; '
         'the pad is out of sight until JC rounds the vine wall, so nobody sees it. A player who runs to the pad cuts '
         'the call: the shot comes at once. New goal: reach Jock\'s helicopter.'),
        ('conv', 'UC_BPBumBefore', 'A bum at the barrel fire north of the pad, before the shot', None),
        ('conv', 'UC_BPBum', 'The bum, after the shot', 'Said as JC passes, once; it points behind the wall.'),
        ('conv', 'UC_BPBumMore', 'The bum, clicked again', None),
        ('conv', 'UC_BPCop1', 'Police at the end of the vine wall', 'Said as JC passes, once.'),
        ('conv', 'UC_BPCop1More', 'The same officer, clicked again', None),
        ('conv', 'UC_BPCop2', 'Police at the plaza', 'Said as JC passes, once.'),
        ('conv', 'UC_BPCop2More', 'The same officer, clicked again', None),
        ('conv', 'UC_BPShooterStop', 'The agent who shot Jock, as JC comes round the vine wall',
         'He walks up to JC, pistol in hand.'),
        ('conv', 'UC_BPShooterBack', 'The same agent, if JC goes on to the body', None),
        ('conv', 'UC_BPShooterMore', 'The same agent, clicked again before the body', None),
        ('conv', 'UC_BPShooterBody', 'The same agent, once JC has seen the body', None),
        ('conv', 'UC_BPShooterBodyMore', 'The same agent, clicked again after the body', None),
        ('conv', 'UC_BPAgents1', 'The Special Agents at the helicopter', 'Starts when JC comes near.'),
        ('conv', 'UC_BPAgentsAgain1', 'The agents again, before the body', None),
        ('conv', 'UC_BPAgentsAgain2', 'The agents, any later time', None),
        ('conv', 'UC_BPAgentsWall', 'The confrontation, only after the body',
         'The last answer appears only if JC read the datacube. Nothing he says changes anything.'),
        ('say', 'UCSceneBatteryPark.uc', 'AlexLine', 'Alex, cut off by Simons (InfoLink)',
         'After the first talk with the agents; the replacement helicopter flies in over the bay meanwhile and '
         'holds high over the clearing south of the subway. It comes down when JC comes near.'),
        ('conv', 'UC_BPFlareAgent1', 'The Special Agent with the flare, at the clearing',
         'A fourth agent marks the landing zone: when JC comes near he strikes a flare and holds it up high, arm '
         'straight. Clicked, he sends JC on.'),
        ('conv', 'UC_BPFlareAgent2', 'The same agent, clicked again', None),
        ('conv', 'UC_BPAgentsPilot', 'The agents, after Simons\'s call, until Eva has landed',
         'Where the new pilot is setting down, if JC asks.'),
        ('conv', 'UC_BPEva', 'Eva at the helicopter door',
         'JC clicks the helicopter. The extra answer needs the body found. Every answer ends with the takeoff.'),
    ]),
    ('Part II - Hong Kong', None, []),
    ('6. Civilian rooftop and freight arrival', """Eva lands on a civilian Wan Chai roof temporarily requisitioned by
Coalition Special Projects. The original MJ12 helibase is a separate later site. A physical freight lift
connects the roof to the service yard through a matching cabin and map transition.""", [
        ('conv', 'UC_EvaRooftop', 'Eva, the new pilot, on landing', None),
        ('conv', 'UC_EvaRooftopAgain', 'Eva, if JC goes back to her', None),
        ('conv', 'UC_EvaRooftopLast', 'Eva, the second time', None),
        ('conv', 'UC_RoofLiaison', 'The liaison at the checkpoint', 'No early Majestic 12 explanation.'),
        ('say', 'UCSceneSimonsBriefing.uc', 'SimonsLine', 'Simons\' briefing (InfoLink I01 / I02)',
         'One-way InfoLink: only the caller speaks. It starts near the freight lift. The single-line '
         'version is the recovery if JC changed map before the briefing ended.'),
        ('conv', 'UC_YardBriefing', 'The liaison in the loading yard', None),
        ('conv', 'UC_CargoRaidBark', 'Luminous Path cargo raid', 'The target is the case; JC starts neutral. Surviving attackers do not block progression.'),
        ('conv', 'UC_YardAfter', 'The liaison after the diversion', None),
        ('conv', 'UC_WoundedRaider', 'Optional wounded survivor', None),
    ]),
    ('7. Wan Chai market', """Same Hong Kong, reversed relations: to the Triads JC is a UNATCO agent, not a fugitive.""", [
        ('conv', 'UC_Messenger', 'The Red Arrow messenger',
         'He arrives at the exit toward the Market after the cargo raid and speaks when JC walks past. Optional: '
         'everything he says can be learned elsewhere.'),
        ('conv', 'UC_MessengerAgain', 'The messenger, repeat line', None),
    ]),
    ('8. The Lucky Money', """Max Chen sent for JC, so nobody asks him for the entry fee and someone takes him in.""", [
        ('conv', 'UC_LMForeshadow', 'The government agents (overheard)',
         'Two "government agents" lean on a Red Arrow at the entrance and leave when JC approaches. '
         'A hint, not a fight.'),
        ('conv', 'UC_MaxEscort', 'The Red Arrow who takes JC to Max',
         'The same Red Arrow. Then he leads the way: running through the club, walking in the back room, '
         'opening the office doors and stepping aside.'),
        ('conv', 'UC_MaxEscortDoor', 'At the office doors', None),
        ('conv', 'UC_MaxEscortAgain', 'The Red Arrow, if JC talks to him later', None),
        ('conv', 'UC_MaxMeet', 'Max Chen (first meeting)',
         'Max offers a transaction. JC can investigate, decline, or take the evidence directly to Gordon.'),
        ('conv', 'UC_MaxWait', 'Max, while JC investigates', None),
    ]),
    ('9. Queen\'s Tower', None, [
        ('conv', 'UC_MaggieMeet', 'Maggie Chow', None),
        ('conv', 'UC_MaggieAgain', 'Maggie, repeat line', None),
        ('conv', 'M06WaltonHolo', 'The recording in the hidden room',
         'The original Simons hologram, rewritten as a recording of Simons and Maggie. It is suspicious '
         'only because JC finds it there.'),
        ('say', 'UCSceneSimonsSword.uc', 'CallLine', 'Simons answers the explicit Queen\'s Tower report',
         'Requires the player to transmit from a secure terminal. Finding the weapon or leaving the room does not send a report.'),
    ]),
    ('10. Evidence, custody and access', 'Weapon custody, evidence against Maggie, and permission to enter the compound are separate states.', [
        ('conv', 'UC_GordonMeet', 'Gordon Quick at the compound gate', 'Hostile in words; he does not attack.'),
        ('conv', 'UC_GordonWait', 'Gordon, repeat line', None),
        ('conv', 'UC_GordonAgain', 'Gordon, while investigating', None),
        ('conv', 'UC_GordonEvidence', 'Gordon, with the evidence', None),
        ('conv', 'UC_MaxEvidence', 'Max Chen, with the evidence', None),
        ('conv', 'UC_MaxAfter', 'Max Chen, after voluntary delivery', None),
        ('conv', 'UC_GordonFinal', 'Gordon, after granting local access', None),
        ('conv', 'UC_GordonCustody', 'Optional delivery to Gordon', 'Transfers the actual inventory weapon; it does not create a global truce.'),
    ]),
    ('11. Tracer Tong', None, [
        ('conv', 'UC_TongGuardBark', 'The guard at Tong\'s base', None),
        ('conv', 'UC_TongMeet', 'Tracer Tong', None),
        ('conv', 'UC_TongEvidence', 'Tong\'s terminal', None),
        ('text', 'Read the manifest and Paul\'s attributed archive copy at the terminal. Saving an independent copy and transmitting Tong\'s location are separate commands.'),
        ('say', 'UCSceneSPTransfer.uc', 'CallLine', 'Simons authorizes the transfer (InfoLink)',
         'After the explicit location report. The rear loading door stays closed until JC opens it at the laboratory service console.'),
        ('conv', 'UC_EntryWarning', 'The team crosses the rear storeroom loading door',
         'Only physical entry starts the assault. A timer, map exit or Tong\'s death cannot substitute for opening the gate.'),
        ('conv', 'UC_TongAlarm', 'The alarm', None),
        ('conv', 'UC_TongUnderstands', 'Tong understands', None),
        ('conv', 'UC_SPCommanderMeet', 'The Special Projects commander', None),
        ('conv', 'UC_SPTechTalk', 'A Special Projects technician', None),
        ('conv', 'UC_PrisonerBark', 'A prisoner (overheard)', None),
        ('conv', 'UC_PrisonerTalk', 'The prisoner', None),
        ('conv', 'UC_SPCommanderAfter', 'The commander, when the facility is secure', None),
        ('conv', 'UC_SPCommanderAgain', 'The commander, repeat line', None),
        ('say', 'UCSceneSimonsAfterTong.uc', 'CallLine', 'Simons, after the explicit operation report',
         'The reply distinguishes JC\'s independent copy from Special Projects\' extraction. Either requires a manual upload before the VersaLife assignment.'),
    ]),
]

HIDDEN = ('UC_WaltonHoloMark',)   # segnaposto tecnici, senza battute

# condizioni del codice che non sono "storia": come dirle (None = non mostrarle)
CONDS = {
    "LobbyAgent() != None && LobbyAgent().bInWorld": 'if the second agent is with them',
    "Agent() == None || !Agent().bInWorld": 'if the agent who went upstairs is not there',
    "bGuardLine": 'one time',
    "OTHERWISE (not: bGuardLine)": 'the next time',
    "bRecovery": 'recovery version, in place of the three lines below',
    "i == 0": None,
    "!GetF('UC_LMForeshadow_Played')": None,
    "bTongDead": 'if Tong is dead',
    "bDead": 'if Tong is dead',
}
TECHNICAL = ('VSize', 'LineOfSight', 'conPlay', 'HasCon', '!= None', '== None')


def nm(bind):
    return NAMES.get(bind, bind)


def flag_text(flag, value):
    d = FLAGS.get(flag)
    s = '`%s` is %s' % (flag, 'true' if value else 'false')
    if d:
        s += ' (%s%s)' % ('' if value else 'not: ', d)
    return s


def cond_text(c):
    """Una condizione del codice, resa leggibile quanto basta."""
    c = c.strip()
    if c in CONDS:
        return CONDS[c]
    other = re.match(r'OTHERWISE \(not: (.*)\)$', c)
    if other:
        return 'otherwise'
    c = c.replace('!=', ' is not ')
    c = c.replace('Anna747()', 'Anna Navarre died on the 747')
    c = re.sub(r"(?:GetF|flags\.GetBool|P\.FlagBase\.GetBool)\('([A-Za-z0-9_]+)'\)",
               lambda m: FLAGS.get(m.group(1), 'flag ' + m.group(1)), c)
    c = c.replace('&&', 'and').replace('||', 'or')
    c = re.sub(r'!\s*', 'not ', c)
    c = c.replace('bRecovery and i == 0', 'recovery version').replace('bTongDead', 'Tong is dead').replace('bDead', 'Tong is dead')
    c = c.replace('bFired', 'JC fired on Special Projects personnel').replace('bRecording', 'JC saw the recording')
    return 'if ' + c


def render_conv(c, title, note):
    out = ['#### %s' % title, '']
    how = 'overheard (first person, no camera)' if c.first_person else 'cinematic dialogue'
    if c.radius and not c.nofrob:
        trig = 'starts by itself when JC comes within %d units of %s (or when JC talks to %s)' % (
            c.radius, nm(c.owner), nm(c.owner))
    elif c.radius:
        trig = 'starts by itself when JC comes within %d units of %s' % (c.radius, nm(c.owner))
    elif c.passive and c.first_person:
        trig = 'started by the scene script'
    else:
        trig = 'when JC talks to %s' % nm(c.owner)
    out.append('*Conversation `%s` - %s; %s; %s.*' % (c.name, how, trig, 'plays once' if c.once else 'repeatable'))
    if note:
        out += ['', note]
    reqs = [flag_text(f, v) for (f, v) in c.requires if f != 'UC_AnnaMetroOpened' or v]
    code = [cond_text(x) for x in c.code_conds if CONDS.get(x, '') is not None
            and (x in CONDS or not any(k in x for k in TECHNICAL))]
    if reqs or code:
        out += ['', '*Only if:* ' + '; '.join(reqs + code) + '.']
    out.append('')
    last = None
    sets = []
    for kind, d, conds in c.events:
        conds = tuple(conds)
        if kind in ('line', 'dynline', 'choice', 'answer', 'ifflag', 'jump', 'label', 'end') and conds != last:
            if conds:
                out += ['', '*- %s:*  ' % ', '.join(cond_text(x) for x in conds)]
            elif last:
                out += ['', '*- in every case:*  ']
            last = conds
        if kind == 'line':
            out.append('**%s:** %s  ' % (nm(d[0]), d[2]))
        elif kind == 'dynline':
            out.append('**(speaker):** *(one of the patrol lines below)*  ')
        elif kind == 'choice':
            out.append('*JC can answer:* "%s" (go to **[%s]**) or "%s" (go to **[%s]**)  ' % (d[0], d[1], d[2], d[3]))
        elif kind == 'answer':
            only = (' - only if %s' % flag_text(d[2], d[3] == 'True')) if len(d) > 2 and d[2] else ''
            out.append('*JC can answer:* "%s" (go to **[%s]**)%s  ' % (d[0], d[1], only))
        elif kind == 'ifflag':
            out.append('*(if %s, skip to **[%s]**)*  ' % (flag_text(d[0], d[1] == 'True'), d[2]))
        elif kind == 'jump':
            out.append('*(go to **[%s]**)*  ' % d[0])
        elif kind == 'label':
            out.append('**[%s]**  ' % d[0])
        elif kind == 'end':
            out.append('*(end)*  ')
        elif kind == 'setflag':
            s = '`%s`%s' % (d[0], '' if d[1] == 'True' else ' = false')
            if s not in sets:
                sets.append(s)
        elif kind == 'goal':
            out.append('*New objective: %s*  ' % d[1])
    if sets:
        out += ['', '*Sets:* ' + ', '.join(sets) + '.']
    out.append('')
    return out


def render_say(says, src, func, title, note):
    out = ['#### %s' % title, '', '*InfoLink (one-way: only the caller speaks), `%s`.*' % src[:-3]]
    if note:
        out += ['', note]
    out.append('')
    for (f, fn, case, who, text, conds) in says:
        if f != src or fn != func:
            continue
        c = [cond_text(x) for x in conds if CONDS.get(x, '') is not None
             and (x in CONDS or not any(k in x for k in TECHNICAL))]
        pre = ('*(%s)* ' % ', '.join(c)) if c else ''
        out.append('%s**%s:** %s  ' % (pre, nm(who), text))
    out.append('')
    return out


def barks(classes_dir):
    import os
    t = open(os.path.join(classes_dir, 'UCCampaign.uc'), encoding='latin-1').read()
    body = t[t.index('function string BarkLine'):t.index('function BarkTick')]
    return [m.group(1) for m in re.finditer(r'return "((?:[^"\\]|\\.)+)";', body)]


def objectives(classes_dir):
    import glob
    import os
    rows = []
    for f in sorted(glob.glob(os.path.join(classes_dir, '*.uc'))):
        t = open(f, encoding='latin-1').read()
        for m in re.finditer(r"(?:GoalAdd|Goal)\(\s*'([A-Za-z0-9_]+)',\s*\"((?:[^\"\\]|\\.)+)\",\s*(True|False)", t):
            rows.append((m.group(1), m.group(2), m.group(3) == 'True'))
        for m in re.finditer(r"(?:AddNote|Note)\(\s*(?:'[A-Za-z0-9_]+',\s*)?\"((?:[^\"\\]|\\.)+)\"", t):
            rows.append((None, m.group(1), False))
    seen, out = set(), []
    for r in rows:
        if r[1] not in seen:
            seen.add(r[1])
            out.append(r)
    return out


def write(convs, says, intro_path, out_path):
    import os
    classes_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'src', 'UnatcoContinues', 'Classes')
    by = {}
    for c in convs:
        by.setdefault(c.name, c)
    used = set(HIDDEN)
    doc = [open(intro_path, encoding='utf-8').read().rstrip(), '', '---', '', '# The script', '',
           '*Generated from the mod\'s source code by `tools/export_dialogues.py`: this is exactly what the game '
           'plays. Do not edit this part by hand.*', '']
    n_lines = 0
    for title, intro, items in CHAPTERS:
        if not items and intro is None:
            doc += ['## %s' % title, '']
            continue
        doc += ['### %s' % title, '']
        if intro:
            doc += [intro, '']
        for it in items:
            if it[0] == 'conv':
                c = by.get(it[1])
                if c is None:
                    doc += ['*(conversation `%s` is no longer in the code)*' % it[1], '']
                    continue
                used.add(it[1])
                n_lines += sum(1 for e in c.events if e[0] == 'line')
                doc += render_conv(c, it[2], it[3])
            elif it[0] == 'say':
                doc += render_say(says, it[1], it[2], it[3], it[4])
            elif it[0] == 'text':
                doc += [it[1], '']
            elif it[0] == 'barks':
                doc += ['#### Patrol lines', '', '*Friendly UNATCO troopers say one of these when JC walks by.*', '']
                doc += ['- "%s"' % b for b in barks(classes_dir)] + ['']
    rest = [c for c in convs if c.name not in used]
    if rest:
        doc += ['### Not placed yet', '', '*Conversations found in the code but not yet given a place in this document.*', '']
        for c in rest:
            n_lines += sum(1 for e in c.events if e[0] == 'line')
            doc += render_conv(c, c.name, None)
    doc += ['## Objectives and notes', '', '*The mission objectives and notes the mod gives the player.*', '',
            '| Objective | Text |', '|---|---|']
    for name, text, primary in objectives(classes_dir):
        kind = 'note' if name is None else ('primary' if primary else 'secondary')
        doc.append('| %s%s | %s |' % ('`%s` ' % name if name else '', kind, text.replace('|', '/')))
    doc.append('')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    open(out_path, 'w', encoding='utf-8', newline='\n').write('\n'.join(doc))
    print('ok', out_path, '-', len(convs), 'conversations,', n_lines, 'lines of dialogue,', len(says), 'InfoLink lines')
    if rest:
        print('da collocare:', ', '.join(c.name for c in rest))
