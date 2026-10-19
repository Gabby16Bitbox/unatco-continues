# UNATCO Continues - Narrative Design Document

*A story mod for Deus Ex: Revision. This document holds the premise, the rules the writing
follows, and every line of dialogue the mod adds, in story order.*

The first part is written by hand. The second part, **The script**, is generated from the
mod's source code, so it is always exactly what the game plays. Voice recordings are not
part of this repository; every line is shown as text.

## Narrative revision of 6 October 2026

The [6 October rewrite](CAMPAIGN_REWRITE_2026_10_06.md) is integrated in the current source: competing Triad offers, actual weapon custody, independent records, manual reports and the physical north entry. Work on the helipad is deferred. The script below is generated from these sources; [STATUS.md](STATUS.md) records build, installation and playtest coverage.

## Premise

In the original game JC Denton leaves UNATCO in mission 4: whatever the player does at the
'Ton hotel, the story takes him to the rebels. *UNATCO Continues* asks the other question.
**What if JC says no to his brother and stays?**

From that one refusal the mod keeps the same world and the same places, and changes who JC
is in them. He flies to Hong Kong as planned, but as a UNATCO agent on duty: the MJ12
helibase is friendly, the Triads look at him with different eyes, and Tracer Tong is no
longer the man who will save him. He is the target.

The player is never told he chose the wrong side. The institutions he works for stay
polite, efficient and compartmented. What is wrong with them is shown through what they do
and what they refuse to explain, never through a confession.

## Structure

| # | Where | What happens |
|---|---|---|
| 1 | 'Ton hotel, New York | The fork. JC refuses Paul. |
| 2 | Outside the hotel | Gunther and two "Special Agents" arrive for Paul. |
| 3 | Inside the hotel (optional) | The search of Paul's room. Paul is gone. |
| 4 | Hell's Kitchen | UNATCO holds the streets. Anna Navarre guards the subway. |
| 5 | Battery Park | Jock flies JC to Hong Kong. |
| 6 | Hong Kong helibase | A friendly MJ12 base. Simons gives the assignment: find Tong. |
| 7 | Wan Chai market | A Red Arrow messenger: Max Chen wants to see JC. |
| 8 | The Lucky Money | Government agents lean on the Red Arrow. Max Chen. |
| 9 | Queen's Tower | Maggie Chow, the Dragon's Tooth, a recording JC was not meant to find. |
| 10 | The Triads | JC brings the evidence. Max Chen and Gordon Quick make a truce. |
| 11 | Tong's laboratory | Tong shows JC what Paul found. Then Special Projects arrives: JC led them there. |

Chapters 3 and 7 are optional: everything needed to go on can be learned elsewhere, and
the story holds if a character involved is dead or was avoided.

Where the story could go from here (VersaLife, the return to New York, Vandenberg, the
endings) is in the [campaign concept](CAMPAIGN_CONCEPT.md).

## Rules of the writing

**One refusal, then consequences.** After the fork the player is not asked again which side
he is on. Attacking UNATCO personnel ends the loyalist route; nothing else does.

**Characters only know what they could know.** Gunther has no proof that JC killed Anna
(the logs were erased), so he can be angry but cannot accuse. The trooper at the subway
does not know how Anna died. Nobody deduces when Paul left from the blood in his room.
What a character has learned is tracked with flags and changes what they say next.

**The past is remembered.** Who killed Lebedev, whether Anna is alive, whether Gunther saw
JC leave the hotel, what JC heard about Majestic 12: each of these changes lines later on.
The variants are listed with their conditions in the script below.

**InfoLinks are one-way.** On the InfoLink only the caller speaks; JC never answers. His
questions are kept for face-to-face scenes.

**Scripted characters never vanish in view.** A character who has to leave stops in a
sensible, visible place and goes only when JC is not looking.

**Nothing is essential twice.** Optional characters (the messenger, Maggie Chow) can be
skipped or killed: every piece of information the player needs arrives by another road too.

## How each character talks

The mod's lines were checked against the way each character speaks in the original game.

| Character | Voice |
|---|---|
| Gunther Hermann | Almost no contractions; short, stiff sentences. Says "Agent Navarre", "Mr. Simons", "Command". Resentful of command. Exclaims in German, does not swear in English. |
| Anna Navarre | Formal, cold, always evaluating. No contractions. To JC she says "Agent Hermann". |
| JC Denton | Dry, uses contractions, no winning one-liners. |
| Men in Black | Clinical: "the subject", "please", sentences that sound like procedure. |
| UNATCO troopers | Colloquial, contractions, "Agent" or "sir". |
| Gilbert Renton | An ordinary man, nervous. |
| Walton Simons | Smooth, bureaucratic. To Maggie he says "Ms. Chow". |
| Max Chen | Formal, proud, almost no contractions. Always "Miss Chow", "the Red Arrow". |
| Maggie Chow | Theatrical, formal; "Mr. Denton". |
| Jock | Easy-going, few words. |

Spelling follows the game's subtitles: "Majestic 12", not "Majestic Twelve".

## Reading the script

- **Cinematic dialogue** is the game's normal conversation, with cameras. **Overheard**
  lines play in first person while the game goes on.
- *Only if* lists the conditions for a conversation to exist. Names in `code font` are the
  game flags that carry the state; the text in brackets says what they mean.
- Inside a conversation, **[Label]** marks a branch point and *(if ..., skip to [Label])*
  a jump taken when a condition holds.
- Codes such as G01, A03, H02, I01 are the identifiers used in the dialogue specification
  the lines were written against.

---

# The script

*Generated from the mod's source code by `tools/export_dialogues.py`: this is exactly what the game plays. Do not edit this part by hand.*

## Part I - New York

### 1. The fork: Paul at the 'Ton

Mission 4 of the original game. Paul asks JC to send the NSF distress signal from the
transmitter. In the original game the player can refuse and go back to Paul, and a short
exchange plays (conversation `M04PlayerLikesUNATCO`, voiced, part of the original script:
JC says UNATCO is not perfect but he is not a terrorist; Paul answers that then they go
their separate ways). There it changes nothing: the raid happens anyway. **In the mod that
exchange is the fork**: if JC found the evidence at NSF headquarters, did not send the
signal and tells Paul no, the UNATCO route is committed. The original lines are not
reproduced here; everything below is new.

Paul stays in his chair. If JC talks to him again:

#### Paul, after the refusal (1)

*Conversation `UC_PaulAfter1` - cinematic dialogue; when JC talks to Paul Denton; plays once.*

*Only if:* `M04PlayerLikesUNATCO_Played` is true.

**Paul Denton:** There's nothing else I can tell you.  

#### Paul, after the refusal (2)

*Conversation `UC_PaulAfter2` - cinematic dialogue; when JC talks to Paul Denton; plays once.*

*Only if:* `UC_PaulAfter1_Played` is true.

**Paul Denton:** You should go. Jock won't wait forever.  

#### Paul, after the refusal (3)

*Conversation `UC_PaulAfter3` - cinematic dialogue; when JC talks to Paul Denton; plays once.*

*Only if:* `UC_PaulAfter2_Played` is true.

**Paul Denton:** Be careful in Hong Kong, JC.  
**JC Denton:** You too.  

#### Paul, repeat line

*Conversation `UC_PaulAfter4` - cinematic dialogue; when JC talks to Paul Denton; repeatable.*

*Only if:* `UC_PaulAfter3_Played` is true.

**Paul Denton:** There's nothing else I can tell you.  

Paul disappears from the hotel the moment JC leaves the building. Nobody sees him go.

### 2. Gunther outside the 'Ton

JC leaves through the front door. Gunther Hermann and two "Special Agents" (Men in
Black) are standing at the foot of the steps. They do not walk up to JC: the exchange
starts when JC comes down to them. Afterwards they climb the steps in single file and go
in; they stop at the hotel door while JC is looking and enter only when he is not.

Leaving through the bedroom window skips the scene. Attacking Gunther or the agents ends
the loyalist route.

#### The confrontation (G01 / G02)

*Conversation `UC_GuntherTon1` - cinematic dialogue; starts by itself when JC comes within 250 units of Gunther Hermann (or when JC talks to Gunther Hermann); plays once.*

Two versions, chosen when the scene is set up. Gunther never has proof that JC killed Anna (Alex erased the logs), so even in the harsher version it is anger, not an accusation.


*- if Anna Navarre died on the 747:*  
**Gunther Hermann:** Denton. Agent Navarre is dead. Your brother has betrayed UNATCO. And now I find you leaving his hotel.  
**JC Denton:** I spoke to Paul.  

*- otherwise:*  
**Gunther Hermann:** Denton. You should be on your way to Hong Kong. Did you see Paul?  
**JC Denton:** I spoke to him.  

*- in every case:*  
**Gunther Hermann:** And you left him here.  
**JC Denton:** He tried to recruit me. I refused.  
**Gunther Hermann:** You should have arrested him. Manderley will hear about this. Get out of the way.  

*Sets:* `GuntherKnowsJCMetPaul`, `GuntherReportedJCConduct`, `SpecialAgentsSeenAtTon`, `UC_PaulContactReportSent`, `GuntherTonEncounterPlayed`.

#### As Gunther walks away

*Conversation `UC_GuntherTon2` - overheard (first person, no camera); starts by itself when JC comes within 1200 units of Gunther Hermann (or when JC talks to Gunther Hermann); plays once.*

Overheard, no cinematic camera: Gunther answers without stopping. Skipped in the "Anna is dead" version, where the same request is already inside the confrontation.

**JC Denton:** Bring him in alive.  
**Gunther Hermann:** You had your chance.  

### 3. The search of the hotel (optional)

If JC goes back inside, he can follow the search. Gunther and one agent cross the lobby
and climb to Paul's apartment; the second agent takes a post at the front desk. Gilbert
Renton is behind the desk: when JC commits to UNATCO, the side story of his daughter is
closed without JC (it would otherwise keep Gilbert upstairs).

Paul is gone. A trail of small blood stains leads from his chair to the bedroom window, a
used medkit lies on the floor. Rule for the writing: nobody deduces *when* Paul left from
the blood or the medkit.

#### If JC talks to Gunther on the way up

*Conversation `UC_GuntherNotNow` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `GuntherTonSearchComplete` is false (not: the search of Paul's room is over); `UC_GuntherNotNowCD` is false (not: (cooldown of the line)).

**Gunther Hermann:** Not now, Denton.  

*Sets:* `UC_GuntherNotNowCD`.

#### Crossing the lobby (G03)

*Conversation `UC_GuntherLobby` - overheard (first person, no camera); starts by itself when JC comes within 1100 units of Gilbert Renton (or when JC talks to Gilbert Renton); plays once.*

Overheard while they walk. If Gilbert has not reached the desk yet, the lines are addressed to JC.

**Gilbert Renton:** What's going on? You can't just come in here.  
**Gunther Hermann:** UNATCO. We are looking for Paul Denton. Stay downstairs.  

*- if the second agent is with them:*  
**Special Agent:** Keep the stairs clear.  

#### Paul's room (G06)

*Conversation `UC_GuntherRoom` - overheard (first person, no camera); starts by itself when JC comes within 900 units of Gunther Hermann (or when JC talks to Gunther Hermann); plays once.*

Starts when JC is close enough to hear it.


*- if the agent who went upstairs is not there:*  
**Gunther Hermann:** Unglaublich! He was here. We came too late.  

*- in every case:*  
**Special Agent:** Bedroom clear. No sign of the subject.  
**Gunther Hermann:** Unglaublich! He was here. We came too late.  
**Special Agent:** I will report to Mr. Simons.  
**Gunther Hermann:** Then check the alley. We need men at the subway exits.  

*Sets:* `SimonsConnectionHinted`.

#### Gilbert and the agent at the desk

*Conversation `UC_LobbyChat` - overheard (first person, no camera); starts by itself when JC comes within 380 units of Gilbert Renton; plays once.*

Overheard when JC passes the desk after the agent has taken his post.

*Only if:* `UC_LobbyAgentPosted` is true (the Special Agent took his post at the front desk).

**Gilbert Renton:** How long are you people going to be here?  
**Special Agent:** Until the operation is concluded.  
**Gilbert Renton:** I've got guests upstairs. I don't want any trouble.  
**Special Agent:** Stay calm, please. Do not interfere with this operation.  

**After the search**, JC can question Gunther. One exchange per click, in this order; each plays once.

#### Gunther, after the search

*Conversation `UC_GuntherRW1` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

Optional click. If JC avoided Gunther outside, the missing operational exchange plays here.

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over).

*(if `GuntherKnowsJCMetPaul` is true (Gunther knows JC spoke to Paul), skip to **[Reproach]**)*  
**Gunther Hermann:** Were you here with Paul?  
**JC Denton:** I spoke to Paul.  
**[Reproach]**  
**Gunther Hermann:** You spoke to him and walked away. Now we search the city.  
**JC Denton:** I didn't help him escape.  
**Gunther Hermann:** You did nothing to stop him.  

*Sets:* `GuntherKnowsJCMetPaul`, `UC_PaulContactReportSent`, `GuntherReportedJCConduct`.

#### Paul's channels and the assignment

*Conversation `UC_GuntherRW2` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

Optional second click.

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over); `UC_GuntherRW1_Played` is true.

**JC Denton:** Paul says UNATCO is compromised.  
**Gunther Hermann:** His clearance is revoked. He gave classified information to the NSF and ran.  
**Gunther Hermann:** If he had evidence, he had channels. He chose terrorists.  
**Gunther Hermann:** Put whatever he showed you in your report. Then go to Hong Kong.  

#### G17 - repeat line

*Conversation `UC_GuntherG17` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over); `UC_GuntherRW2_Played` is true.

**Gunther Hermann:** Go to Hong Kong, Denton.  

### 4. Hell's Kitchen

The streets are held by UNATCO: friendly patrols, the exits to other districts closed,
the subway to Battery Park open for UNATCO personnel. One trooper recognises JC.

#### The trooper who recognises JC (overheard)

*Conversation `UC_GreeterHello` - overheard (first person, no camera); starts by itself when JC comes within 320 units of UNATCO Trooper; plays once.*

*Only if:* `UC_GreeterTalk_Played` is false.

**UNATCO Trooper:** Agent Denton.  

#### The trooper who recognises JC (if JC talks to him)

*Conversation `UC_GreeterTalk` - cinematic dialogue; when JC talks to UNATCO Trooper; plays once.*

**UNATCO Trooper:** Agent Denton.  
**JC Denton:** What's going on?  
**UNATCO Trooper:** Search operation. Orders from headquarters.  
**JC Denton:** Looking for Paul?  
**UNATCO Trooper:** Among others.  

#### Jock calls from Battery Park (InfoLink)

*InfoLink (one-way: only the caller speaks), `UCSceneJockStreet`.*

As soon as JC is out of the 'Ton and walking the street towards the subway, after Gunther (or after the window exit). Jock is still calm, just uneasy: men in suits around the park. New goal: meet Jock in Battery Park, fast.

**Jock:** JC, it's Jock. I'm on the pad at Battery Park, rotors warm.  
**Jock:** Something's off down here. Cars I don't know, guys in suits walking the park like they own it.  
**Jock:** I don't like it. Grab the subway and get here fast. We need to be in the air.  

#### Patrol lines

*Friendly UNATCO troopers say one of these when JC walks by.*

- "They've got every unit in Manhattan looking for your brother."
- "Didn't expect to see you here, Agent Denton."
- "Heard you're shipping out to Hong Kong. Good luck."

### The subway gate

Anna Navarre guards the gate. **One opening** resolves the meeting, chosen from six by what
Anna knows: who killed Lebedev (JC, Anna, or an outcome she cannot attribute) and whether
Gunther's report "JC spoke to Paul" has reached her. She judges JC's reliability as an
agent; she does not repeat Gunther's threat. If Anna is dead, a trooper stands there instead.

#### A01 - JC killed Lebedev, report received

*Conversation `UC_AnnaA01` - cinematic dialogue; starts by itself when JC comes within 200 units of Anna Navarre (or when JC talks to Anna Navarre); plays once.*

*Only if:* `UC_AnnaPaulReportReceived` is true (Anna received Gunther's report); `PlayerKilledLebedev` is true (JC killed Lebedev).

**Anna Navarre:** Agent Denton. Agent Hermann reports that you spoke to Paul at the hotel. You were more decisive with Lebedev.  
**JC Denton:** Paul asked me to join him. I refused.  
**Anna Navarre:** That was expected. Arresting him would have been useful.  
**JC Denton:** My orders are to find Tong. Gunther is handling Paul.  
**Anna Navarre:** Then complete your assignment. Do not leave another agent to finish that one for you.  
**JC Denton:** Is the line to Battery Park open?  
**Anna Navarre:** For UNATCO personnel. Get to your helicopter.  

*Sets:* `UC_AnnaMetroOpened`.

#### A02 - JC killed Lebedev, no report

*Conversation `UC_AnnaA02` - cinematic dialogue; starts by itself when JC comes within 200 units of Anna Navarre (or when JC talks to Anna Navarre); plays once.*

*Only if:* `UC_AnnaPaulReportReceived` is false (not: Anna received Gunther's report); `PlayerKilledLebedev` is true (JC killed Lebedev).

**Anna Navarre:** Agent Denton. Have your orders for Hong Kong changed?  
**JC Denton:** No. I'm heading for Battery Park.  
**Anna Navarre:** You performed well at the airfield. I expect the same when you find Tong.  
**JC Denton:** Is the line open?  
**Anna Navarre:** For UNATCO personnel. Get moving.  

*Sets:* `UC_AnnaMetroOpened`.

#### A03 - Anna killed Lebedev, report received

*Conversation `UC_AnnaA03` - cinematic dialogue; starts by itself when JC comes within 200 units of Anna Navarre (or when JC talks to Anna Navarre); plays once.*

*Only if:* `UC_AnnaPaulReportReceived` is true (Anna received Gunther's report); `PlayerKilledLebedev` is false (not: JC killed Lebedev); `AnnaKilledLebedev` is true (Anna killed Lebedev).

**Anna Navarre:** Agent Hermann says you spoke to Paul and left him at the hotel. I had to deal with Lebedev myself. Now Agent Hermann has to deal with your brother.  
**JC Denton:** I refused to join Paul. My assignment is Tong.  
**Anna Navarre:** Then complete it. This time, do not wait for someone else to act.  
**JC Denton:** Is the line to Battery Park open?  
**Anna Navarre:** For UNATCO personnel. Get to your helicopter.  

*Sets:* `UC_AnnaMetroOpened`.

#### A04 - Anna killed Lebedev, no report

*Conversation `UC_AnnaA04` - cinematic dialogue; starts by itself when JC comes within 200 units of Anna Navarre (or when JC talks to Anna Navarre); plays once.*

*Only if:* `UC_AnnaPaulReportReceived` is false (not: Anna received Gunther's report); `PlayerKilledLebedev` is false (not: JC killed Lebedev); `AnnaKilledLebedev` is true (Anna killed Lebedev).

**Anna Navarre:** Agent Denton. Why are you still in New York?  
**JC Denton:** I'm heading for Battery Park. Jock is taking me to Hong Kong.  
**Anna Navarre:** At the airfield, I had to finish your assignment. Do not expect me to follow you to Hong Kong and do it again.  
**JC Denton:** I know my orders.  
**Anna Navarre:** Then carry them out. The line is open.  

*Sets:* `UC_AnnaMetroOpened`.

#### A05 - outcome not attributable, report received

*Conversation `UC_AnnaA05` - cinematic dialogue; starts by itself when JC comes within 200 units of Anna Navarre (or when JC talks to Anna Navarre); plays once.*

*Only if:* `UC_AnnaPaulReportReceived` is true (Anna received Gunther's report); `PlayerKilledLebedev` is false (not: JC killed Lebedev); `AnnaKilledLebedev` is false (not: Anna killed Lebedev).

**Anna Navarre:** Agent Hermann reports that you spoke to Paul and left him at the hotel.  
**JC Denton:** He asked me to join him. I refused.  
**Anna Navarre:** Then stop delaying your assignment. Agent Hermann will handle Paul. You have orders for Hong Kong.  
**JC Denton:** Is the line to Battery Park open?  
**Anna Navarre:** For UNATCO personnel. Go.  

*Sets:* `UC_AnnaMetroOpened`.

#### A06 - outcome not attributable, no report

*Conversation `UC_AnnaA06` - cinematic dialogue; starts by itself when JC comes within 200 units of Anna Navarre (or when JC talks to Anna Navarre); plays once.*

*Only if:* `UC_AnnaPaulReportReceived` is false (not: Anna received Gunther's report); `PlayerKilledLebedev` is false (not: JC killed Lebedev); `AnnaKilledLebedev` is false (not: Anna killed Lebedev).

**Anna Navarre:** Agent Denton. You have orders for Hong Kong.  
**JC Denton:** I'm on my way to Battery Park.  
**Anna Navarre:** Then keep moving. The line is open to UNATCO personnel.  

*Sets:* `UC_AnnaMetroOpened`.

**If JC talks to her again**, one exchange per click:

#### A10 - why she is there

*Conversation `UC_AnnaA10` - cinematic dialogue; when JC talks to Anna Navarre; plays once.*

*Only if:* `UC_AnnaMetroOpened` is true (Anna's first exchange at the subway gate was played).

**JC Denton:** Why are you down here?  
**Anna Navarre:** Paul knows our checkpoints. We are watching the routes out of the district, not just the hotel.  
**JC Denton:** You expect him to come through here?  
**Anna Navarre:** I expect him to look for an exit we have neglected. This will not be one of them.  

#### A11 - Paul's records

*Conversation `UC_AnnaA11` - cinematic dialogue; when JC talks to Anna Navarre; plays once.*

Here Anna can learn from JC himself that he met Paul.

*Only if:* `UC_AnnaMetroOpened` is true (Anna's first exchange at the subway gate was played).

**JC Denton:** Paul showed me records that were worth checking.  
**Anna Navarre:** And you checked them. Have they changed your orders?  
**JC Denton:** No. They raised questions.  
**Anna Navarre:** Then put them in your report. Manderley can read it while you complete your assignment.  

*Sets:* `UC_AnnaKnowsJCMetPaul`.

#### A12 - about Gunther

*Conversation `UC_AnnaA12` - cinematic dialogue; when JC talks to Anna Navarre; plays once.*

*Only if:* `UC_AnnaMetroOpened` is true (Anna's first exchange at the subway gate was played); `GuntherTonEncounterPlayed` is true (JC met Gunther outside the hotel); `UC_AnnaKnowsJCMetPaul` is true (Anna knows JC spoke to Paul).

**JC Denton:** Gunther is taking this personally.  
**Anna Navarre:** Paul knew our agents and our operations. He has put all of us at risk. Agent Hermann has reason to be angry.  
**JC Denton:** Anger won't help him bring Paul in.  
**Anna Navarre:** Neither did your visit, apparently.  

#### A13 - repeat line

*Conversation `UC_AnnaA13` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_AnnaMetroOpened` is true (Anna's first exchange at the subway gate was played).

**Anna Navarre:** Your assignment is in Hong Kong, Agent Denton.  

#### T01 - the trooper, if Anna is dead

*Conversation `UC_GateGuard` - cinematic dialogue; starts by itself when JC comes within 200 units of UNATCO Trooper (or when JC talks to UNATCO Trooper); plays once.*

He does not know who killed Anna and does not mention the 747.

**UNATCO Trooper:** Agent Denton. We're checking the stations for your brother.  
**JC Denton:** I'm heading for Battery Park.  
**UNATCO Trooper:** The line is open to UNATCO personnel. Go ahead.  

#### The trooper, repeat line

*Conversation `UC_GateGuardAgain` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_GateGuard_Played` is true.

**UNATCO Trooper:** The line is open to UNATCO personnel. Go ahead.  

### 5. Battery Park

JC was supposed to fly to Hong Kong with Jock. Jock calls as JC comes up from the subway and is
shot mid-call by the Men in Black (shown as "Special Agent"), who hold his helicopter with the police at the
perimeter. His body lies under a tarp behind the vine wall, with Paul's datacube and his flask: finding it is
optional and unlocks the confrontation. The agent who shot him guards it, pistol in hand, and walks up to JC to
send him away. A replacement pilot, Eva, flies JC out: she lands at a flare in the clearing south of the
subway, coming down only when JC comes near. Flags for Missions 6/7: UC_JockDead,
UC_BP_JockBodyFound, UC_BP_PaulCubeRead, UC_BP_MIBConfronted, UC_BP_EvaWallLine.

#### Jock's call, cut by the gunshot (InfoLink)

*InfoLink (one-way: only the caller speaks), `UCSceneBatteryPark`.*

Automatic a second and a half after JC is out of the subway kiosk. When the call ends JC hears the gunshot; the pad is out of sight until JC rounds the vine wall, so nobody sees it. A player who runs to the pad cuts the call: the shot comes at once. New goal: reach Jock's helicopter.

**Jock:** JC! Thank God. Listen, I'm at the pad, there's cops all over the chopper--  
**Jock:** They pulled me out of the cockpit. Said it's routine. It's not routine, JC, they've got guys in suits with them--  
**Jock:** [muffled] Hey, I'm talking to an agent, you can't-- [muffled] What are you doing with that--  

#### A bum at the barrel fire north of the pad, before the shot

*Conversation `UC_BPBumBefore` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_JockDead` is false.

**Bum:** Cold night, friend. Cops everywhere tonight.  

#### The bum, after the shot

*Conversation `UC_BPBum` - overheard (first person, no camera); started by the scene script; plays once.*

Said as JC passes, once; it points behind the wall.

*Only if:* `UC_JockDead` is true.

**Bum:** Heard a shot by the chopper. Then them suits dragged somebody off south, behind the wall. I ain't seen nothing, friend.  

#### The bum, clicked again

*Conversation `UC_BPBumMore` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_BPBum_Played` is true.

**Bum:** Told you what I heard. I ain't seen nothing else.  

#### Police at the end of the vine wall

*Conversation `UC_BPCop1` - overheard (first person, no camera); started by the scene script; plays once.*

Said as JC passes, once.

**Police Officer:** Feds took over. We're just holding the tape.  

#### The same officer, clicked again

*Conversation `UC_BPCop1More` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_BPCop1_Played` is true.

**Police Officer:** Talk to the suits, Agent. It's their show.  

#### Police at the plaza

*Conversation `UC_BPCop2` - overheard (first person, no camera); started by the scene script; plays once.*

Said as JC passes, once.

**Police Officer:** Since when do feds wear sunglasses at night?  

#### The same officer, clicked again

*Conversation `UC_BPCop2More` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_BPCop2_Played` is true.

**Police Officer:** Keep moving, sir. Nothing for you here.  

#### The agent who shot Jock, as JC comes round the vine wall

*Conversation `UC_BPShooterStop` - overheard (first person, no camera); started by the scene script; plays once.*

He walks up to JC, pistol in hand.

*Only if:* `UC_BP_JockBodyFound` is false.

**Special Agent (the shooter):** Nothing to see here, Denton.  

#### The same agent, if JC goes on to the body

*Conversation `UC_BPShooterBack` - overheard (first person, no camera); started by the scene script; plays once.*

*Only if:* `UC_BPShooterStop_Played` is true; `UC_BP_JockBodyFound` is false.

**Special Agent (the shooter):** Your mission is at the helicopter, Agent. Get back to it.  

#### The same agent, clicked again before the body

*Conversation `UC_BPShooterMore` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_BPShooterBack_Played` is true; `UC_BP_JockBodyFound` is false.

**Special Agent (the shooter):** Move along, Agent.  

#### The same agent, once JC has seen the body

*Conversation `UC_BPShooterBody` - overheard (first person, no camera); started by the scene script; plays once.*

*Only if:* `UC_BP_JockBodyFound` is true.

**Special Agent (the shooter):** He was a terrorist, Denton. Go to work.  

#### The same agent, clicked again after the body

*Conversation `UC_BPShooterBodyMore` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_BPShooterBody_Played` is true.

**Special Agent (the shooter):** Go to work, Agent Denton.  

#### The Special Agents at the helicopter

*Conversation `UC_BPAgents1` - cinematic dialogue; starts by itself when JC comes within 260 units of Special Agent (or when JC talks to Special Agent); plays once.*

Starts when JC comes near.

*Only if:* `UC_JockDead` is true; `UC_BP_MIBMet` is false.

**Special Agent:** Agent Denton. The pilot has been neutralized.  
*JC can answer:* "Neutralized. Is he alive?" (go to **[Alive]**)  
*JC can answer:* "On whose orders?" (go to **[Orders]**)  
*JC can answer:* "I'll wait." (go to **[Wait]**)  
**[Alive]**  
**JC Denton:** Neutralized. Is he alive?  
**Special Agent:** ...  
*(end)*  
**[Orders]**  
**JC Denton:** On whose orders?  
**Special Agent:** Yours are to stand by. Your transport has been reassigned.  
*(end)*  
**[Wait]**  
**JC Denton:** I'll wait.  
**Special Agent:** Correct.  

*Sets:* `UC_BP_MIBMet`.

#### The agents again, before the body

*Conversation `UC_BPAgentsAgain1` - cinematic dialogue; when JC talks to owner; plays once.*

*Only if:* `UC_BP_MIBMet` is true; `UC_BP_JockBodyFound` is false; `UC_BP_EvaLanded` is false.

**Special Agent:** Stand by, Agent Denton.  

#### The agents, any later time

*Conversation `UC_BPAgentsAgain2` - cinematic dialogue; when JC talks to owner; repeatable.*

*Only if:* `UC_BPAgentsAgain1_Played` is true; `UC_BP_JockBodyFound` is false; `UC_BP_EvaLanded` is false.

**Special Agent:** There is nothing here for you.  

#### The confrontation, only after the body

*Conversation `UC_BPAgentsWall` - cinematic dialogue; starts by itself when JC comes within 260 units of Special Agent (or when JC talks to Special Agent); plays once.*

The last answer appears only if JC read the datacube. Nothing he says changes anything.

*Only if:* `UC_BP_JockBodyFound` is true.

**Special Agent:** You went behind the wall, Agent Denton.  
*JC can answer:* "He was one of ours. You shot him and hid him behind a wall." (go to **[Ours]**)  
*JC can answer:* "Who gave the order? Manderley? Simons?" (go to **[Order]**)  
*JC can answer:* "He was a pilot, not a terrorist." (go to **[Pilot]**) - only if `UC_BP_PaulCubeRead` is false  
*JC can answer:* "He flew Paul out. You could have arrested him." (go to **[Arrest]**) - only if `UC_BP_PaulCubeRead` is true  
**[Ours]**  
**JC Denton:** He was one of ours. You shot him and hid him behind a wall.  
**Special Agent:** Pilot Flanagan assisted a fugitive. The matter is closed.  
*(go to **[Close]**)*  
**[Order]**  
**JC Denton:** Who gave the order? Manderley? Simons?  
**Special Agent:** The order was given. That is sufficient.  
*(go to **[Close]**)*  
**[Pilot]**  
**JC Denton:** He was a pilot, not a terrorist.  
**Special Agent:** He chose a side. You chose another. We noted both.  
*(go to **[Close]**)*  
**[Arrest]**  
**JC Denton:** He flew Paul out. You could have arrested him.  
**Special Agent:** Arrests generate records, Agent Denton.  
**[Close]**  
**Special Agent:** Your loyalty has been noted. Do not give us reason to note anything else.  

*Sets:* `UC_BP_MIBMet`, `UC_BP_MIBConfronted`.

#### Alex, cut off by Simons (InfoLink)

*InfoLink (one-way: only the caller speaks), `UCSceneBatteryPark`.*

After the first talk with the agents; the replacement helicopter flies in over the bay meanwhile and holds high over the clearing south of the subway. It comes down when JC comes near.

**Alex Jacobson:** JC... I just heard about Jock. I don't-- He was--  
**Walton Simons:** Agent Jacobson, clear this channel.  
**Alex Jacobson:** ...Yes, sir.  
**Walton Simons:** Agent Denton. A replacement pilot is inbound. Hong Kong hasn't moved. Neither has your target.  

#### The Special Agent with the flare, at the clearing

*Conversation `UC_BPFlareAgent1` - overheard (first person, no camera); when JC talks to UCSpecialAgent4; plays once.*

A fourth agent marks the landing zone: when JC comes near he strikes a flare and holds it up high, arm straight. Clicked, he sends JC on.

**UCSpecialAgent4:** The helicopter, Agent Denton. Move. Don't waste our time.  

#### The same agent, clicked again

*Conversation `UC_BPFlareAgent2` - overheard (first person, no camera); when JC talks to UCSpecialAgent4; repeatable.*

*Only if:* `UC_BPFlareAgent1_Played` is true.

**UCSpecialAgent4:** Move, Agent.  

#### The agents, after Simons's call, until Eva has landed

*Conversation `UC_BPAgentsPilot` - cinematic dialogue; when JC talks to owner; repeatable.*

Where the new pilot is setting down, if JC asks.

*Only if:* `UC_BP_EvaCall` is true; `UC_BP_EvaLanded` is false.

*JC can answer:* "Where is it setting down?" (go to **[Where]**)  
*JC can answer:* "Understood." (go to **[Ok]**)  
**[Where]**  
**JC Denton:** Where is it setting down?  
*(end)*  
**[Ok]**  
**JC Denton:** Understood.  

#### Eva at the helicopter door

*Conversation `UC_BPEva` - cinematic dialogue; when JC talks to Eva; plays once.*

JC clicks the helicopter. The extra answer needs the body found. Every answer ends with the takeoff.

**Eva:** Strand. I'm your pilot now.  
*JC can answer:* "You knew Jock?" (go to **[Knew]**)  
*JC can answer:* "That was fast." (go to **[Fast]**) - only if `UC_BP_JockBodyFound` is false  
*JC can answer:* "They left him behind a wall." (go to **[Wall]**) - only if `UC_BP_JockBodyFound` is true  
*JC can answer:* "[Get in without a word]" (go to **[Silent]**)  
**[Knew]**  
**JC Denton:** You knew Jock?  
**Eva:** I know his file. Get in.  
*(end)*  
**[Fast]**  
**JC Denton:** That was fast.  
**Eva:** I was told to be ready. Get in.  
*(end)*  
**[Wall]**  
**JC Denton:** They left him behind a wall.  
**Eva:** ... Then don't give them a reason to do the same with you.  
*(end)*  
**[Silent]**  

*Sets:* `UC_EvaGo`, `UC_BP_EvaWallLine`.

## Part II - Hong Kong

### 6. Civilian rooftop and freight arrival

Eva lands on a civilian Wan Chai roof temporarily requisitioned by
Coalition Special Projects. The original MJ12 helibase is a separate later site. A physical freight lift
connects the roof to the service yard through a matching cabin and map transition.

#### Eva, the new pilot, on landing

*Conversation `UC_EvaRooftop` - cinematic dialogue; starts by itself when JC comes within 680 units of Eva (or when JC talks to Eva); plays once.*

**Eva:** Harbourline Tower. I'm dropping you here and staying with the chopper.  
**JC Denton:** Copy that.  
**Eva:** My orders are to log when you come back. And who with.  
**JC Denton:** Simons' orders?  
**Eva:** Orders. Get out, Denton.  

#### Eva, if JC goes back to her

*Conversation `UC_EvaRooftopAgain` - cinematic dialogue; when JC talks to Eva; plays once.*

*Only if:* `UC_EvaRooftop_Played` is true.

**Eva:** I've got nothing to say to you, Denton.  

#### Eva, the second time

*Conversation `UC_EvaRooftopLast` - cinematic dialogue; when JC talks to Eva; repeatable.*

*Only if:* `UC_EvaRooftopAgain_Played` is true.

**Eva:** Go. It's your brother's clock that's running, not mine.  

#### The liaison at the checkpoint

*Conversation `UC_RoofLiaison` - cinematic dialogue; starts by itself when JC comes within 180 units of Special Projects Liaison (or when JC talks to Special Projects Liaison); plays once.*

No early Majestic 12 explanation.

**Special Projects Liaison:** Agent Denton? Hong Kong Operations. Your briefing is downstairs.  
**JC Denton:** UNATCO?  
**Special Projects Liaison:** Coalition Special Projects.  
**JC Denton:** Never heard of it.  
**Special Projects Liaison:** Most people haven't. Use the freight lift beyond the checkpoint.  

*Sets:* `UC_RoofLiaisonMet`.

#### Simons' briefing (InfoLink I01 / I02)

*InfoLink (one-way: only the caller speaks), `UCSceneSimonsBriefing`.*

One-way InfoLink: only the caller speaks. It starts near the freight lift. The single-line version is the recovery if JC changed map before the briefing ended.

*(recovery version, in place of the three lines below)* **Walton Simons:** Start with the Red Arrow. Your objective remains Tracer Tong.  
**Walton Simons:** Denton. Tong's network intersects with both Triads, but most of the commercial traffic passes through Wan Chai. Special Projects has been monitoring several contacts in the district.  
**Walton Simons:** Start with the Red Arrow. Establish who is moving material for Tong and identify a route into the Luminous Path.  
**Walton Simons:** Your objective remains Tracer Tong.  

#### The liaison in the loading yard

*Conversation `UC_YardBriefing` - cinematic dialogue; starts by itself when JC comes within 200 units of Special Projects Liaison (or when JC talks to Special Projects Liaison); plays once.*

*Only if:* `UCHongKongRaidStarted` is false.

**Special Projects Liaison:** We have a convoy moving through the service yard. Your local intelligence package is being transferred with it.  
**JC Denton:** What's in the shipment?  
**Special Projects Liaison:** Restricted equipment.  
**JC Denton:** For the Tong operation?  
**Special Projects Liaison:** Among other things.  
**JC Denton:** You people like that phrase.  

*Sets:* `UC_YardBriefingHeard`.

*(conversation `UC_CargoRaidBark` is no longer in the code)*

#### The liaison after the diversion

*Conversation `UC_YardAfter` - cinematic dialogue; when JC talks to Special Projects Liaison; repeatable.*

*Only if:* `UCHongKongRaidResolved` is true.

**Special Projects Liaison:** They were going for the secured case. The local investigation is still your assignment.  
**JC Denton:** What was worth the risk?  
**Special Projects Liaison:** That equipment is restricted. Find Tong. He can explain why his people want it.  

*(conversation `UC_WoundedRaider` is no longer in the code)*

### 7. Wan Chai market

Same Hong Kong, reversed relations: to the Triads JC is a UNATCO agent, not a fugitive.

#### The Red Arrow messenger

*Conversation `UC_Messenger` - cinematic dialogue; when JC talks to Red Arrow Messenger; plays once.*

He arrives at the exit toward the Market after the cargo raid and speaks when JC walks past. Optional: everything he says can be learned elsewhere.

**Red Arrow Messenger:** Denton?  
**JC Denton:** Who's asking?  
**Red Arrow Messenger:** Max Chen. He wants to see you before you speak to Miss Chow.  
**JC Denton:** Why?  
*(if `UCHongKongRooftopArrival` is false, skip to **[OldMessage]**)*  
**Red Arrow Messenger:** Because Maggie Chow will tell you this was about Tong. Max thinks it was about the cargo.  
**[OldMessage]**  
**Red Arrow Messenger:** Ask him. The Lucky Money.  

*Sets:* `RedArrowMessengerContacted`, `MaxChenMeetingAvailable`, `UC_HK_MessengerDone`.

#### The messenger, repeat line

*Conversation `UC_MessengerAgain` - cinematic dialogue; when JC talks to Red Arrow Messenger; repeatable.*

*Only if:* `UC_Messenger_Played` is true (the Red Arrow messenger spoke to JC).

**Red Arrow Messenger:** The Lucky Money. Mr. Chen does not like to wait.  

### 8. The Lucky Money

Max Chen sent for JC, so nobody asks him for the entry fee and someone takes him in.

#### The government agents (overheard)

*Conversation `UC_LMForeshadow` - overheard (first person, no camera); started by the scene script; plays once.*

Two "government agents" lean on a Red Arrow at the entrance and leave when JC approaches. A hint, not a fight.

**Government Agent:** The payment cleared.  
**Red Arrow:** Max didn't authorize the shipment.  
**Second Government Agent:** He accepted the transfer.  
**Government Agent:** We'll continue this later.  

#### The Red Arrow who takes JC to Max

*Conversation `UC_MaxEscort` - cinematic dialogue; when JC talks to Red Arrow; plays once.*

The same Red Arrow. Then he leads the way: running through the club, walking in the back room, opening the office doors and stepping aside.

*Only if:* `MeetMaxChen_Played` is false (not: JC met Max Chen).

*(if `UC_Messenger_Played` is true (the Red Arrow messenger spoke to JC), skip to **[Told]**)*  
**Red Arrow:** Denton. Max Chen wants to see you.  
**JC Denton:** I didn't ask for a meeting.  
**Red Arrow:** Mr. Chen did.  
*(go to **[Agents]**)*  
**[Told]**  
**Red Arrow:** Mr. Denton. Mr. Chen is expecting you.  
**[Agents]**  
*(if `UC_LMForeshadow_Played` is false (not: JC overheard the government agents at the Lucky Money), skip to **[Go]**)*  
**JC Denton:** Friends of yours?  
**Red Arrow:** Not friends.  
**[Go]**  
**Red Arrow:** This way.  

*Sets:* `PaidForLuckyMoney`, `KnowsAboutMaxChen`, `ClubTriadBackroomMeet_Played`, `MaxChenMeetingAvailable`.

#### At the office doors

*Conversation `UC_MaxEscortDoor` - overheard (first person, no camera); starts by itself when JC comes within 330 units of Red Arrow; plays once.*

*Only if:* `UC_MaxEscortDone` is true (the Red Arrow reached Max Chen's doors); `MeetMaxChen_Played` is false (not: JC met Max Chen).

**Red Arrow:** Mr. Chen is inside.  

#### The Red Arrow, if JC talks to him later

*Conversation `UC_MaxEscortAgain` - cinematic dialogue; when JC talks to Red Arrow; repeatable.*

*Only if:* `UC_MaxEscort_Played` is true (the Red Arrow greeted JC at the Lucky Money).

*(if `MeetMaxChen_Played` is true (JC met Max Chen), skip to **[Met]**)*  
**Red Arrow:** Mr. Chen is waiting.  
*(end)*  
**[Met]**  
**Red Arrow:** You have Mr. Chen's answer.  

#### Max Chen (first meeting)

*Conversation `UC_MaxMeet` - cinematic dialogue; starts by itself when JC comes within 190 units of Max Chen (or when JC talks to Max Chen); repeatable.*

Max offers a transaction. JC can investigate, decline, or take the evidence directly to Gordon.

*Only if:* `UC_MaxDealOffered` is false.

*(if `UCHongKongRaidStarted` is false, skip to **[OldArrival]**)*  
**Max Chen:** Mr. Denton. You arrive with government men, and within minutes the Luminous Path is shooting at them.  
**JC Denton:** They attacked a shipment.  
**Max Chen:** Yes. A shipment Maggie Chow arranged through Red Arrow channels.  
**JC Denton:** What was in it?  
**Max Chen:** If I knew that, I would not need you. Yuen Kong wanted those transfers stopped. Now he is dead, and the Dragon's Tooth is missing.  
*(go to **[Suspect]**)*  
**[OldArrival]**  
**Max Chen:** Mr. Denton. You want Tong. I want this war finished.  
**JC Denton:** What's the connection?  
**Max Chen:** Miss Chow. Yuen Kong went to Queen's Tower to question her about the attacks. He never returned.  
**[Suspect]**  
**JC Denton:** That makes her a suspect.  
**Max Chen:** The Dragon's Tooth passed through the same building. The Luminous Path claims they never took it.  
**JC Denton:** And you believe them?  
**Max Chen:** I believe someone benefits while we kill each other.  
**Max Chen:** Bring me the sword and evidence of what happened to Yuen Kong. Then I will arrange a meeting with Gordon Quick.  
**JC Denton:** You're asking a UNATCO agent to rob Maggie Chow.  
**Max Chen:** I am asking Paul Denton's brother how badly he wants to find Tong.  
*JC can answer:* "I'll investigate. No promise to deliver the weapon." (go to **[Investigate]**) or "I want information, not a job." (go to **[Decline]**)  
**[Investigate]**  
**JC Denton:** I'll look into Chow. I haven't agreed to hand you a weapon.  
**Max Chen:** Then investigate. We will discuss the weapon when you have it.  
*(end)*  
**[Decline]**  
**JC Denton:** I want information, not a job.  
**Max Chen:** Then ask Miss Chow why Yuen Kong never came home.  

*Sets:* `UC_MaxDealOffered`, `MeetMaxChen_Played`, `KnowsAboutTriads`.

#### Max, while JC investigates

*Conversation `UC_MaxWait` - cinematic dialogue; when JC talks to Max Chen; repeatable.*

*Only if:* `UC_MaxDealOffered` is true; `UC_SwordGivenMax` is false.

**Max Chen:** Bring me the sword and evidence of what happened to Yuen Kong. Then I will arrange a meeting with Gordon Quick.  

### 9. Queen's Tower

#### Maggie Chow

*Conversation `UC_MaggieMeet` - cinematic dialogue; starts by itself when JC comes within 120 units of Maggie Chow (or when JC talks to Maggie Chow); repeatable.*

*Only if:* `UC_MaggieRWPlayed` is false.

**Maggie Chow:** Mr. Denton. Mr. Simons said you would be coming.  
**JC Denton:** I'm looking for Tong.  
**Maggie Chow:** Then you need Gordon Quick. Unfortunately, his people are keeping the Triads at war.  
**JC Denton:** Over the Dragon's Tooth.  
**Maggie Chow:** A weapon the Luminous Path stole. Recover it, and I can persuade the Red Arrow to negotiate.  
*(if `MeetMaxChen_Played` is true (JC met Max Chen), skip to **[MaxMet]**)*  
**JC Denton:** Why would the Red Arrow listen to you?  
**Maggie Chow:** Because I have done business with both sides. They still need someone they can speak to.  
*(go to **[Yuen]**)*  
**[MaxMet]**  
**JC Denton:** Chen thinks the sword came through this building.  
**Maggie Chow:** It did. Before it was stolen. Mr. Chen has chosen to forget that distinction.  
**[Yuen]**  
**JC Denton:** What happened to Yuen Kong?  
**Maggie Chow:** He died in a conflict Gordon Quick could have ended.  
*(if `MeetMaxChen_Played` is false (not: JC met Max Chen), skip to **[MaxAbsent]**)*  
**JC Denton:** Max says he came here.  
*(go to **[Grave]**)*  
**[MaxAbsent]**  
**JC Denton:** Did he come here?  
**[Grave]**  
**Maggie Chow:** He came here often. That does not make this his grave.  
**JC Denton:** Where should I start?  
**Maggie Chow:** The police have records of the dispute. You may find them more useful than Mr. Chen's suspicions.  

*Sets:* `UC_MaggieRWPlayed`, `UC_MaggieMeet_Played`, `MeetMaggie_Played`, `KnowsAboutMaggie`, `KnowsAboutTriads`, `FoundMaggieChow`.

#### Maggie, repeat line

*Conversation `UC_MaggieAgain` - cinematic dialogue; when JC talks to Maggie Chow; repeatable.*

*Only if:* `UC_MaggieRWPlayed` is true.

**Maggie Chow:** The police have records of the dispute. You may find them more useful than Mr. Chen's suspicions.  

#### The recording in the hidden room

*Conversation `M06WaltonHolo` - overheard (first person, no camera); started by the scene script; plays once.*

The original Simons hologram, rewritten as a recording of Simons and Maggie. It is suspicious only because JC finds it there.

**Walton Simons:** Ms. Chow. Denton is arriving under UNATCO orders. Give him what he needs to continue the investigation.  
**Maggie Chow (recording):** And if he questions my involvement?  
**Walton Simons:** His assignment is Tong. Keep it there.  
**Maggie Chow (recording):** The Red Arrow may approach him first.  
**Walton Simons:** Then you should be ready with your account of the dispute.  
**JC Denton:** Simons.  

*Sets:* `SimonsConvoPlaying` = false, `UC_HoloSeen`.

#### Simons answers the explicit Queen's Tower report

*InfoLink (one-way: only the caller speaks), `UCSceneSimonsSword`.*

Requires the player to transmit from a secure terminal. Finding the weapon or leaving the room does not send a report.

**Walton Simons:** Your report from Queen's Tower has been received. Chow's account will be reviewed.  
**Walton Simons:** Secure the weapon if you can. Do not let either Triad decide how you conduct the investigation. Your objective remains Tong.  

### 10. Evidence, custody and access

Weapon custody, evidence against Maggie, and permission to enter the compound are separate states.

#### Gordon Quick at the compound gate

*Conversation `UC_GordonMeet` - cinematic dialogue; starts by itself when JC comes within 180 units of Gordon Quick (or when JC talks to Gordon Quick); plays once.*

Hostile in words; he does not attack.

*Only if:* `UC_ChowSwordVerified` is false; `UC_LPMeetingGranted` is false.

**Gordon Quick:** Paul came here as a friend. You came here with orders.  
**JC Denton:** I'm looking for Tong.  
**Gordon Quick:** We know.  
*(if `UC_MaggieRWPlayed` is false, skip to **[MaggieAbsent]**)*  
**JC Denton:** Chow says your people stole the Dragon's Tooth.  
*(go to **[Answer]**)*  
**[MaggieAbsent]**  
**JC Denton:** I need to know what happened to the Dragon's Tooth.  
**[Answer]**  
**Gordon Quick:** Then ask her why Yuen Kong went to Queen's Tower. Bring an answer, not another accusation.  

*Sets:* `Gate_Guard2_Played`, `KnowsAboutMaggie`, `KnowsAboutNanoSword`.

#### Gordon, repeat line

*Conversation `UC_GordonWait` - cinematic dialogue; when JC talks to Gordon Quick; repeatable.*

*Only if:* `UC_GordonMeet_Played` is true (JC met Gordon Quick); `UC_ChowSwordVerified` is false.

**Gordon Quick:** Then ask her why Yuen Kong went to Queen's Tower. Bring an answer, not another accusation.  

#### Gordon, while investigating

*Conversation `UC_GordonAgain` - cinematic dialogue; when JC talks to Gordon Quick; repeatable.*

*Only if:* `UC_LPMeetingGranted` is true.

**Gordon Quick:** He has agreed to a meeting. Nothing more. Nineteen ninety-seven. The door in our sparring room.  

#### Gordon, with the evidence

*Conversation `UC_GordonEvidence` - cinematic dialogue; when JC talks to Gordon Quick; repeatable.*

*Only if:* `UC_ChowSwordVerified` is true; `UC_SwordGivenMax` is false; `UC_LPMeetingGranted` is false.

*JC can answer:* "Share the records with the Red Arrow." (go to **[Copy]**) or "Retain the weapon; submit the records." (go to **[Retain]**)  
**[Copy]**  
*(if `UC_YuenCaseCorroborated` is false, skip to **[OnlySword]**)*  
**JC Denton:** The sword was in Chow's apartment. These are her records on Yuen Kong.  
**Gordon Quick:** And Chen has seen them?  
**JC Denton:** He can have a copy. He doesn't need the weapon to read it.  
**Gordon Quick:** Then he can decide whether he wants an answer or an excuse to keep fighting.  
*(go to **[Permit]**)*  
**[OnlySword]**  
**JC Denton:** I can prove she had the sword. Not that she killed him.  
*(go to **[Permit]**)*  
**[Retain]**  
*(if `UC_HasSword` is false, skip to **[SwordAbsent]**)*  
**JC Denton:** I'm retaining the weapon as evidence.  
**Gordon Quick:** UNATCO gets the sword. What do we get?  
*(go to **[Records]**)*  
**[SwordAbsent]**  
*(if `UC_SwordAtChow` is false, skip to **[OnlySword]**)*  
*(if `UC_YuenCaseCorroborated` is false, skip to **[OnlySword]**)*  
**JC Denton:** The sword is still at Queen's Tower. I brought the records.  
**[Records]**  
*(if `UC_YuenCaseCorroborated` is false, skip to **[OnlySword]**)*  
**JC Denton:** Chow's records. And a chance to tell Tong what I'm actually here to do.  
**Gordon Quick:** He already knows. He wants to hear it from you.  
**[Permit]**  
**Gordon Quick:** You expose Chow and expect us to forget why you're here.  
**JC Denton:** I'm here for Tong.  
**Gordon Quick:** Exactly.  
**Gordon Quick:** Paul came here as a friend. You came here with orders.  
**JC Denton:** Then let Tong hear them himself.  
**Gordon Quick:** He has agreed to a meeting. Nothing more. Nineteen ninety-seven. The door in our sparring room.  

*Sets:* `UC_ChowEvidenceSentGordon`, `UC_LPMeetingGranted`, `QuickLetPlayerIn`, `Gate_Guard2_Played`.

#### Max Chen, with the evidence

*Conversation `UC_MaxEvidence` - cinematic dialogue; when JC talks to Max Chen; repeatable.*

*Only if:* `UC_ChowSwordVerified` is true; `UC_HasSword` is true; `UC_SwordGivenMax` is false; `UC_SwordGivenGordon` is false.

*JC can answer:* "Deliver the Dragon's Tooth to Max Chen." (go to **[Deliver]**) or "Keep the weapon as evidence." (go to **[Keep]**)  
**[Keep]**  
**JC Denton:** I'll look into Chow. I haven't agreed to hand you a weapon.  
**Max Chen:** Then investigate. We will discuss the weapon when you have it.  
*(end)*  
**[Deliver]**  
*(if `UC_SwordGivenMax` is true, skip to **[Transferred]**)*  
*(end)*  
**[Transferred]**  
**Max Chen:** You brought it.  
*(if `UC_YuenCaseCorroborated` is false, skip to **[Incomplete]**)*  
**JC Denton:** And the records on Yuen Kong.  
**Max Chen:** Miss Chow will answer for him.  
*(go to **[Agreement]**)*  
**[Incomplete]**  
**JC Denton:** I can prove she had the sword. Not that she killed him.  
**[Agreement]**  
**JC Denton:** Gordon first. That was the agreement.  
**Max Chen:** I will call him. The Red Arrow will suspend its attacks.  
**JC Denton:** And after I leave?  
**Max Chen:** That depends on Gordon Quick.  

#### Max Chen, after voluntary delivery

*Conversation `UC_MaxAfter` - cinematic dialogue; when JC talks to Max Chen; repeatable.*

*Only if:* `UC_SwordGivenMax` is true.

**Max Chen:** I will call him. The Red Arrow will suspend its attacks.  

#### Gordon, after granting local access

*Conversation `UC_GordonFinal` - cinematic dialogue; when JC talks to Gordon Quick; repeatable.*

*Only if:* `UC_SwordGivenMax` is true; `UC_LPMeetingGranted` is false.

**Gordon Quick:** You expose Chow and expect us to forget why you're here.  
**JC Denton:** I'm here for Tong.  
**Gordon Quick:** Exactly.  
**Gordon Quick:** Paul came here as a friend. You came here with orders.  
**JC Denton:** Then let Tong hear them himself.  
**Gordon Quick:** He has agreed to a meeting. Nothing more. Nineteen ninety-seven. The door in our sparring room.  

*Sets:* `UC_LPMeetingGranted`, `QuickLetPlayerIn`, `Gate_Guard2_Played`.

#### Optional delivery to Gordon

*Conversation `UC_GordonCustody` - cinematic dialogue; when JC talks to Gordon Quick; repeatable.*

Transfers the actual inventory weapon; it does not create a global truce.

*Only if:* `UC_LPMeetingGranted` is true; `UC_HasSword` is true; `UC_SwordGivenGordon` is false; `UC_SwordGivenMax` is false.

*JC can answer:* "Transfer the Dragon's Tooth to Gordon." (go to **[Give]**) or "Keep the weapon as evidence." (go to **[Keep]**)  
**[Give]**  
*(end)*  
**[Keep]**  
**JC Denton:** I'm retaining the weapon as evidence.  

### 11. Tracer Tong

#### The guard at Tong's base

*Conversation `UC_TongGuardBark` - overheard (first person, no camera); started by the scene script; repeatable.*


*- one time:*  
**Luminous Path Guard:** One wrong move and you don't leave this place.  

*- the next time:*  
**Luminous Path Guard:** Keep your weapon down and there won't be a problem.  

#### Tracer Tong

*Conversation `UC_TongMeet` - cinematic dialogue; starts by itself when JC comes within 220 units of Tracer Tong (or when JC talks to Tracer Tong); plays once.*

**Tracer Tong:** Paul said you might come.  
**JC Denton:** Paul expected me to ask for help.  
**Tracer Tong:** Instead you brought an arrest order.  
**JC Denton:** You're coming with me.  
*(if `UCHongKongRaidStarted` is false, skip to **[PaulRecords]**)*  
*(if `UCHongKongShipmentDefended` is false, skip to **[ObservedShipment]**)*  
**Tracer Tong:** You protected a shipment when you arrived in Hong Kong.  
*(go to **[ShipmentQuestion]**)*  
**[ObservedShipment]**  
**Tracer Tong:** You were at the shipment when you arrived in Hong Kong.  
**[ShipmentQuestion]**  
**JC Denton:** Your people attacked it.  
**Tracer Tong:** Yes. Did you ever ask why?  
*(if `HongKongShipmentInspected` is false, skip to **[UninspectedShipment]**)*  
**JC Denton:** VersaLife.  
**Tracer Tong:** Good.  
**JC Denton:** What's in the container?  
**Tracer Tong:** That's the right question. Compare the identifiers with the records in the archive.  
*(go to **[PaulRecords]**)*  
**[UninspectedShipment]**  
**JC Denton:** Why?  
**Tracer Tong:** Because your people were moving something they did not want examined. Their transfer records are in the archive.  
**[PaulRecords]**  
**Tracer Tong:** You can try. First, look at what brought your brother here.  
*(if `UC_PaulManifestRead` is false, skip to **[Unread]**)*  
**JC Denton:** I've already seen his records.  
**Tracer Tong:** Then compare them.  
*(go to **[Ready]**)*  
**[Unread]**  
**JC Denton:** Then show me his records.  
**Tracer Tong:** There is a copy in the archive. Read it for yourself.  
**[Ready]**  

*Sets:* `TongMeetingStarted`.

#### Tong's terminal

*Conversation `UC_TongEvidence` - cinematic dialogue; when JC talks to Tracer Tong; plays once.*

*(if `UC_PaulManifestRead` is false, skip to **[TongCopy]**)*  
**JC Denton:** These shipment IDs match Paul's records.  
*(go to **[Compare]**)*  
**[TongCopy]**  
**JC Denton:** This copy has the same shipment identifiers.  
**[Compare]**  
**Tracer Tong:** The receiving accounts belong to VersaLife.  
**JC Denton:** Level Two. Restricted nanotechnology.  
**Tracer Tong:** Below the laboratories they show their visitors.  
*(if `UC_SPHelibaseAuthRead` is false, skip to **[UnknownAuthorization]**)*  
**JC Denton:** These are the same authorization codes I saw at the helibase.  
**Tracer Tong:** Special Projects.  
*(go to **[Limits]**)*  
**[UnknownAuthorization]**  
**JC Denton:** What is this authorization?  
**Tracer Tong:** Special Projects. Compare it with the field authorization your hosts issued.  
**[Limits]**  
**JC Denton:** Your records say Simons has access to VersaLife. They don't prove UNATCO is involved.  
**Tracer Tong:** I didn't say they did.  
**JC Denton:** I want the originals.  
**Tracer Tong:** Then keep looking.  

*Sets:* `TongEvidenceShown`, `TongEvidenceConversationComplete`.

Read the manifest and Paul's attributed archive copy at the terminal. Saving an independent copy and transmitting Tong's location are separate commands.

#### Simons authorizes the transfer (InfoLink)

*InfoLink (one-way: only the caller speaks), `UCSceneSPTransfer`.*

After the explicit location report. The rear loading door stays closed until JC opens it at the laboratory service console.


#### The team crosses the rear storeroom loading door

*Conversation `UC_EntryWarning` - overheard (first person, no camera); started by the scene script; repeatable.*

Only physical entry starts the assault. A timer, map exit or Tong's death cannot substitute for opening the gate.


*- if guard is not None and guard.IsA('TriadLumPath') and guard.Health>0:*  
**Luminous Path Guard:** Stop. This is Luminous Path territory.  

*- in every case:*  
**Special Projects Commander:** Separate the personnel from the systems.  

*Sets:* `UC_EntryWarning_Played`.

#### The alarm

*Conversation `UC_TongAlarm` - overheard (first person, no camera); started by the scene script; repeatable.*

**Tracer Tong:** They didn't send you to kill me.  
**Tracer Tong:** They sent you to open the door.  
**Tracer Tong:** Now watch what comes through it.  

*Sets:* `JCWasTheAuthentication`.

#### Tong understands

*Conversation `UC_TongUnderstands` - overheard (first person, no camera); started by the scene script; repeatable.*

**Tracer Tong:** Come with me.  
**JC Denton:** No.  
**Tracer Tong:** Then watch.  

#### The Special Projects commander

*Conversation `UC_SPCommanderMeet` - cinematic dialogue; when JC talks to Special Projects Commander; plays once.*

**Special Projects Commander:** Agent Denton. We have the facility from here.  
*(if `TracerTong_Dead` is true, skip to **[Dead]**)*  
**JC Denton:** Tong is supposed to be taken alive.  
*(go to **[Orders]**)*  
**[Dead]**  
**JC Denton:** Tong is dead.  
**[Orders]**  
**Special Projects Commander:** Our orders include his network. Keep clear of the sweep.  

#### A Special Projects technician

*Conversation `UC_SPTechTalk` - cinematic dialogue; starts by itself when JC comes within 220 units of Special Projects Technician (or when JC talks to Special Projects Technician); plays once.*

**JC Denton:** Those systems are evidence.  
**Special Projects Technician:** The authorized copies have been secured.  
**JC Denton:** Authorized by whom?  
**Special Projects Technician:** Special Projects.  

*Sets:* `JCSawDataSanitized`.

#### A prisoner (overheard)

*Conversation `UC_PrisonerBark` - overheard (first person, no camera); started by the scene script; repeatable.*

**Prisoner:** I'm unarmed!  

#### The prisoner

*Conversation `UC_PrisonerTalk` - cinematic dialogue; when JC talks to Special Projects Commander; plays once.*

**JC Denton:** Hold your fire.  
**Special Projects Commander:** Step back, Agent Denton.  
**JC Denton:** Arrest him.  
**Special Projects Commander:** He is not cleared for transfer.  
**JC Denton:** Then clear him.  
**Special Projects Commander:** Take him.  

*Sets:* `JCObjectedToMJ12Execution`.

#### The commander, when the facility is secure

*Conversation `UC_SPCommanderAfter` - cinematic dialogue; when JC talks to Special Projects Commander; plays once.*

**Special Projects Commander:** The facility is secure.  
**JC Denton:** Those systems are evidence.  
**Special Projects Commander:** The authorized copies have been secured. Submit your report from the terminal.  

#### The commander, repeat line

*Conversation `UC_SPCommanderAgain` - cinematic dialogue; when JC talks to Special Projects Commander; repeatable.*

*Only if:* `UC_SPCommanderMeet_Played` is true.

**Special Projects Commander:** Stay clear of the sweep, Agent Denton.  

#### Simons, after the explicit operation report

*InfoLink (one-way: only the caller speaks), `UCSceneSimonsAfterTong`.*

The reply distinguishes JC's independent copy from Special Projects' extraction. Either requires a manual upload before the VersaLife assignment.

**Walton Simons:** Tong escaped during the operation. The recovery team has secured his facility.  
*(if flag UC_VLManifestCopied)* **Walton Simons:** I have reviewed the transfer records you recovered. You will proceed to VersaLife under official authorization.  
**Walton Simons:** The recovery team extracted a transfer index from Tong's systems. You will proceed to VersaLife under official authorization.  
**Walton Simons:** Verify the shipment identifiers and the Level Two access records. Recover any research Tong's people obtained from their systems. Your clearance will be waiting at reception.  
**Walton Simons:** I'm told you fired on Coalition personnel.  
**Walton Simons:** We'll discuss your judgment when you return.  

### Not placed yet

*Conversations found in the code but not yet given a place in this document.*

#### UC_JockHK

*Conversation `UC_JockHK` - cinematic dialogue; starts by itself when JC comes within 640 units of Jock (or when JC talks to Jock); plays once.*

**Jock:** Looks like they cleared us.  
**JC Denton:** Who?  
**Jock:** Hong Kong operations.  
**JC Denton:** You've been here before.  
**Jock:** I've landed here before.  
**JC Denton:** There's a difference?  
**Jock:** In this business? Usually.  

#### UC_HKOfficerAgain

*Conversation `UC_HKOfficerAgain` - cinematic dialogue; when JC talks to Special Projects Liaison; repeatable.*

*Only if:* `UC_HKOfficer_Played` is true.

**Special Projects Liaison:** The lift at the far end of the hangar, Agent Denton. It will take you down to the market.  

#### UC_HKOfficer

*Conversation `UC_HKOfficer` - cinematic dialogue; starts by itself when JC comes within 220 units of Special Projects Liaison (or when JC talks to Special Projects Liaison); plays once.*

**Special Projects Liaison:** Agent Denton. Welcome to Hong Kong.  
**JC Denton:** Who's in charge here?  
**Special Projects Liaison:** Special Projects handles this facility.  
*(if `UC_HeardLebedevMJ12` is true (JC heard Lebedev name Majestic 12), skip to **[H02]**)*  
*(if `UC_MJ12NameKnown` is true (JC knows the name Majestic 12), skip to **[H03]**)*  
**JC Denton:** MJ12. What is that?  
**Special Projects Liaison:** Special Projects. This facility operates under Coalition authority.  
*(go to **[H05]**)*  
**[H02]**  
**JC Denton:** MJ12. Lebedev mentioned Majestic 12.  
**Special Projects Liaison:** This facility operates under Coalition authority. Further details are classified.  
*(go to **[H05]**)*  
**[H03]**  
**JC Denton:** MJ12. Majestic 12?  
**Special Projects Liaison:** Special Projects. This facility operates under Coalition authority.  
**[H05]**  
**JC Denton:** Part of UNATCO?  
**Special Projects Liaison:** Your clearance covers the transit level. Mr. Simons will brief you on the assignment.  

#### UC_JockBP

*Conversation `UC_JockBP` - cinematic dialogue; starts by itself when JC comes within 620 units of Jock (or when JC talks to Jock); plays once.*

**Jock:** Where's Paul?  
**JC Denton:** He's not coming.  
**Jock:** Couldn't convince him?  
**JC Denton:** He couldn't convince me.  
**Jock:** So what now?  
**JC Denton:** Hong Kong.  
**Jock:** You're still going after Tong.  
**JC Denton:** Those are my orders.  
**Jock:** Yeah.  
**Jock:** All right. Get in.  
*JC can answer:* "Let's go." (go to **[Ready]**) or "Give me a minute." (go to **[Wait]**)  
**[Ready]**  
**JC Denton:** Let's go.  
*(end)*  
**[Wait]**  
**JC Denton:** Give me a minute.  
**Jock:** Make it fast.  

*Sets:* `UC_JockGo`.

#### UC_JockBPExtra

*Conversation `UC_JockBPExtra` - cinematic dialogue; starts by itself when JC comes within 560 units of Jock (or when JC talks to Jock); plays once.*

*Only if:* `UC_JockBP_Played` is true.

**Jock:** Paul put a lot on the line getting that information.  
**JC Denton:** That doesn't make him right.  
**Jock:** No.  
**Jock:** Guess it doesn't.  
*JC can answer:* "Let's go." (go to **[Ready]**) or "Give me a minute." (go to **[Wait]**)  
**[Ready]**  
**JC Denton:** Let's go.  
*(end)*  
**[Wait]**  
**JC Denton:** Give me a minute.  
**Jock:** Make it fast.  

*Sets:* `UC_JockGo`.

#### UC_JockBPReady

*Conversation `UC_JockBPReady` - cinematic dialogue; starts by itself when JC comes within 560 units of Jock (or when JC talks to Jock); repeatable.*

*Only if:* `UC_JockBP_Played` is true; `UC_JockBPExtra_Played` is true.

**Jock:** Ready?  
*JC can answer:* "Let's go." (go to **[Ready]**) or "Give me a minute." (go to **[Wait]**)  
**[Ready]**  
**JC Denton:** Let's go.  
*(end)*  
**[Wait]**  
**JC Denton:** Give me a minute.  
**Jock:** Make it fast.  

*Sets:* `UC_JockGo`.

#### UC_HBLamGreet

*Conversation `UC_HBLamGreet` - overheard (first person, no camera); started by the scene script; plays once.*

**UCHBLam:** Agent Denton. Mr. Kwan is waiting for you on the ground floor. The elevator is past the control room.  

#### UC_HBLam

*Conversation `UC_HBLam` - cinematic dialogue; when JC talks to UCHBLam; repeatable.*

*(if `UC_HBLamGreet_Played` is true, skip to **[Ask]**)*  
**UCHBLam:** Agent Denton. Mr. Kwan is waiting for you on the ground floor. The elevator is past the control room.  
**[Ask]**  
*JC can answer:* "What are you shipping?" (go to **[Cargo]**) - only if `UC_HBLamAskedCargo` is false  
*JC can answer:* "How long have you worked here?" (go to **[Years]**) - only if `UC_HBLamAskedYears` is false  
*JC can answer:* "Thanks." (go to **[Thanks]**)  
**[Cargo]**  
**JC Denton:** What are you shipping?  
**UCHBLam:** Refrigerated goods. Medicine, I think. I watch the roof, not the containers.  
*(go to **[Ask]**)*  
**[Years]**  
**JC Denton:** How long have you worked here?  
**UCHBLam:** Long enough not to ask questions. I'd recommend the same, agent.  
*(go to **[Ask]**)*  
**[Thanks]**  
**JC Denton:** Thanks.  
**UCHBLam:** Enjoy your stay in Hong Kong.  

*Sets:* `UC_HBLamGreet_Played`, `UC_HBLamAskedCargo`, `UC_HBLamAskedYears`.

#### UC_HBGuard1Line

*Conversation `UC_HBGuard1Line` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_HBGuardsTalk_Played` is true.

**UCHBGuard1:** Hear those drums down at the market? The Path's been holding ceremonies for three nights.  

#### UC_HBGuard2Line

*Conversation `UC_HBGuard2Line` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_HBGuardsTalk_Played` is true.

**UCHBGuard2:** Stay away from the railing, the wind up here is treacherous.  

#### UC_HBGuardsTalk

*Conversation `UC_HBGuardsTalk` - overheard (first person, no camera); started by the scene script; plays once.*

**UCHBGuard1:** Big shipment going out tonight?  
**UCHBGuard2:** Five a.m. And Kwan wants everyone awake until the last container's gone.  
**UCHBGuard1:** A UNATCO agent... I thought they'd send the other one. The one who got himself in trouble.  
**UCHBGuard2:** Keep your voice down. That's his brother.  

#### UC_HBSmokerLine

*Conversation `UC_HBSmokerLine` - overheard (first person, no camera); started by the scene script; repeatable.*

**[Lift]**  
**UCHBSmoker:** The elevator? On the left as you came in. Can't miss it.  
*(end)*  
**[Break]**  
**UCHBSmoker:** This is my cigarette break, agent. Five minutes. That's all I get all night.  
*(end)*  
**[Bother]**  
**UCHBSmoker:** Don't bother me. I'm on my break.  
*(end)*  
**[Lam]**  
**UCHBSmoker:** Whatever it is, ask Lam. I'm smoking.  

#### UC_HBKwanWelcome

*Conversation `UC_HBKwanWelcome` - cinematic dialogue; when JC talks to VictorKwan; plays once.*

*Only if:* `UC_HB_BreachStarted` is false.

**VictorKwan:** Agent Denton. Victor Kwan, Harbourline security. Welcome to Hong Kong.  
**JC Denton:** I was told you have a vehicle for me.  
**VictorKwan:** Ready and fueled. And I have a man who knows the area around the airstrip where your bro-  

#### UC_HBKwanBreach

*Conversation `UC_HBKwanBreach` - overheard (first person, no camera); started by the scene script; repeatable.*

**VictorKwan:** The Path! Everyone to the containers!  

#### UC_HBKwanOpens

*Conversation `UC_HBKwanOpens` - overheard (first person, no camera); started by the scene script; repeatable.*

**VictorKwan:** If one of those opens, nobody walks out of here!  

#### UC_HBKwanFour

*Conversation `UC_HBKwanFour` - overheard (first person, no camera); started by the scene script; repeatable.*

**VictorKwan:** They're going for number four. Number four!  

#### UC_HBKwanContainers

*Conversation `UC_HBKwanContainers` - overheard (first person, no camera); started by the scene script; repeatable.*

**VictorKwan:** The containers, Denton! Not my men, the containers!  

#### UC_HBKwanBlew

*Conversation `UC_HBKwanBlew` - overheard (first person, no camera); started by the scene script; repeatable.*

**VictorKwan:** Get away from that container! Nobody breathe near that stuff!  

#### UC_HBKwanAfter

*Conversation `UC_HBKwanAfter` - cinematic dialogue; when JC talks to VictorKwan; plays once.*

*Only if:* `UC_HB_BreachOver` is true.

**VictorKwan:** Is it over? ...Good. We have maybe ten minutes before the military police get here. What you saw tonight didn't happen.  
**JC Denton:** They wanted to destroy the shipment. Why?  
**VictorKwan:** Because they're fanatics, agent. The Path sees demons everywhere. It's medicine. I'm sure you were told.  
*(if `UC_HB_ContainerBlew` is true, skip to **[Blew]**)*  
**VictorKwan:** The client will be relieved. So will Simons, I imagine.  
*(go to **[Mail]**)*  
**[Blew]**  
**VictorKwan:** You let a container go up, agent. That goes in my report. It's not a threat, it's my job.  
**[Mail]**  
*(if `UC_HB_Mail4Read` is false, skip to **[Airstrip]**)*  
*JC can answer:* "Container 4. They were after it by number." (go to **[Four]**)  
*JC can answer:* "Tell me about the airstrip." (go to **[Ask]**)  
**[Four]**  
**JC Denton:** Container 4. They were after it by number.  
**VictorKwan:** ...You read other people's mail, Agent Denton.  
*(go to **[Airstrip]**)*  
**[Ask]**  
**JC Denton:** Tell me about the airstrip.  
**[Airstrip]**  
**VictorKwan:** The airstrip you're looking for is past the harbor, to the north. The pilot's name is Lo. If he's still alive.  
*New objective: Find the private airstrip north of the harbor where Paul's plane landed. Kwan's pilot is Lo.*  

*Sets:* `UC_HB_AirstripKnown`.

#### UC_HBKwanAgain

*Conversation `UC_HBKwanAgain` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `UC_HBKwanAfter_Played` is true.

**VictorKwan:** Past the harbor, to the north. Ask for Lo.  

#### UC_HBGuardPhoto

*Conversation `UC_HBGuardPhoto` - overheard (first person, no camera); started by the scene script; plays once.*

**UCHBGuardA:** Is that him? He looked younger in the photo.  

#### UC_HBPathBurn

*Conversation `UC_HBPathBurn` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** Burn the poison! All of it!  

#### UC_HBPathForPath

*Conversation `UC_HBPathForPath` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** For the Luminous Path!  

#### UC_HBPathSpot1

*Conversation `UC_HBPathSpot1` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** An American! UNATCO!  

#### UC_HBPathSpot2

*Conversation `UC_HBPathSpot2` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** It's the other Denton. The one who obeys.  

#### UC_HBPathSpot3

*Conversation `UC_HBPathSpot3` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** The wrong brother. Take him!  

#### UC_HBPathCharges

*Conversation `UC_HBPathCharges` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** Charges on the cold containers, move!  

#### UC_HBPathThirty

*Conversation `UC_HBPathThirty` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** Thirty seconds! Get clear!  

#### UC_HBPathSensors

*Conversation `UC_HBPathSensors` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** The sensors heard us, the police are coming!  

#### UC_HBPathCanal

*Conversation `UC_HBPathCanal` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** Fall back to the canal!  

#### UC_HBPathForget

*Conversation `UC_HBPathForget` - overheard (first person, no camera); when JC talks to UCHBPath; repeatable.*

**UCHBPath:** The Path does not forget.  

#### UC_HBLeaderDoctor

*Conversation `UC_HBLeaderDoctor` - overheard (first person, no camera); when JC talks to UCHBPathLeader; repeatable.*

**UCHBPathLeader:** The doctor was right, it's in here!  

#### UC_HBLeaderCharges

*Conversation `UC_HBLeaderCharges` - overheard (first person, no camera); when JC talks to UCHBPathLeader; repeatable.*

**UCHBPathLeader:** Charges on the cold containers, move!  

#### UC_HBLeaderFour

*Conversation `UC_HBLeaderFour` - overheard (first person, no camera); started by the scene script; repeatable.*

**UCHBPathLeader:** Number four! The doctor said number four!  

#### UC_HBLeaderTalk

*Conversation `UC_HBLeaderTalk` - cinematic dialogue; when JC talks to UCHBPathLeader; plays once.*

*Only if:* `UC_HB_BreachOver` is true; `UC_HBKwanAfter_Played` is true; `UC_HB_LeaderToKwan` is false; `UC_HB_LeaderFreed` is false.

**UCHBPathLeader:** You stopped us tonight. You won't stop what's in those crates.  
**JC Denton:** Who told you about the shipment?  
**UCHBPathLeader:** The doctor. He sees what you refuse to see.  
**JC Denton:** Where's the doctor?  
**UCHBPathLeader:** Where your brother went to die. Or to live. That's up to you, Denton.  
*JC can answer:* "Hand him over to Kwan." (go to **[Kwan]**)  
*JC can answer:* "Let him go." (go to **[Free]**)  
**[Kwan]**  
**JC Denton:** Hand him over to Kwan.  
**VictorKwan:** We'll take care of it.  
*(end)*  
**[Free]**  
**JC Denton:** Let him go.  
**UCHBPathLeader:** The Path will remember this night.  

*Sets:* `UC_HB_LeaderToKwan`, `UC_HB_LeaderFreed`.

#### UC_HBGuardBodies

*Conversation `UC_HBGuardBodies` - overheard (first person, no camera); when JC talks to fromName; repeatable.*

**UCHBGuardA:** Move the Path bodies into the cold room before the police get here.  
**UCHBGuardB:** Move the Path bodies into the cold room before the police get here.  
**UCHBGuardC:** Move the Path bodies into the cold room before the police get here.  
**UCHBGateGuard1:** Move the Path bodies into the cold room before the police get here.  

#### UC_HBGuardsCount

*Conversation `UC_HBGuardsCount` - overheard (first person, no camera); when JC talks to fromName; repeatable.*

**UCHBGuardA:** How many of ours?  
**UCHBGuardB:** How many of ours?  
**UCHBGuardC:** How many of ours?  
**UCHBGateGuard1:** How many of ours?  
**UCHBGuardA:** Three. Kwan says the report will say two.  
**UCHBGuardB:** Three. Kwan says the report will say two.  
**UCHBGuardC:** Three. Kwan says the report will say two.  
**UCHBGateGuard1:** Three. Kwan says the report will say two.  

#### UC_HBGuardMoved

*Conversation `UC_HBGuardMoved` - overheard (first person, no camera); when JC talks to fromName; repeatable.*

**UCHBGuardA:** Did you see how he moved? UNATCO people aren't human.  
**UCHBGuardB:** Did you see how he moved? UNATCO people aren't human.  
**UCHBGuardC:** Did you see how he moved? UNATCO people aren't human.  
**UCHBGateGuard1:** Did you see how he moved? UNATCO people aren't human.  

#### UC_HBGuardLook

*Conversation `UC_HBGuardLook` - overheard (first person, no camera); when JC talks to fromName; repeatable.*

**UCHBGuardA:** Ten years here and I've never looked inside a container. I'm not starting tonight.  
**UCHBGuardB:** Ten years here and I've never looked inside a container. I'm not starting tonight.  
**UCHBGuardC:** Ten years here and I've never looked inside a container. I'm not starting tonight.  
**UCHBGateGuard1:** Ten years here and I've never looked inside a container. I'm not starting tonight.  

#### UC_HBGuardGloves

*Conversation `UC_HBGuardGloves` - overheard (first person, no camera); started by the scene script; repeatable.*

**UCHBGuardA:** Don't touch that liquid! Wait for the gloves!  
**UCHBGuardB:** Don't touch that liquid! Wait for the gloves!  
**UCHBGuardC:** Don't touch that liquid! Wait for the gloves!  
**UCHBGateGuard1:** Don't touch that liquid! Wait for the gloves!  

## Objectives and notes

*The mission objectives and notes the mod gives the player.*

| Objective | Text |
|---|---|
| note | Datacube on Jock's body:/n |
| `SendSignal` primary | Investigate the NSF transmitter and decide whether to send Paul's distress signal. |
| `MeetJockBatteryPark` primary | Jock is waiting with the helicopter in Battery Park, and he doesn't like what he's seeing. Take the Hell's Kitchen subway and get there fast. |
| note | Lam's note in the Harbourline control room:/n |
| `UCMeetMaxChen` secondary | Contact Max Chen at the Lucky Money. Special Projects believes the Red Arrow can identify Tong's local network. |
| `UCInvestigateChow` secondary | Check the claims about Maggie Chow, Yuen Kong and the Dragon's Tooth. Examine Queen's Tower and the police records. |
| `UCYuenKong` secondary | Compare the Queen's Tower transcript with the police report concerning Yuen Kong's death. |
| `ContactMaggieChow` secondary | Optional: question Maggie Chow at Queen's Tower about the Triad dispute. Verify her claims. |
| `UCRecoverForMax` secondary | Optional: Max Chen offers an introduction to Gordon Quick in exchange for the Dragon's Tooth and evidence on Yuen Kong. Delivery is your decision. |
| `UCRecoverForChow` secondary | Optional: Maggie Chow claims the Luminous Path stole the weapon. Verify her claim before acting on it. |
| `UCTellGordon` primary | Present your verified evidence to Gordon Quick at the compound. Delivering the weapon to Max is optional. |
| `UCSubmitOperationReport` primary | Submit the Special Projects operation report from a secure terminal: Tong's archive, the compound office, Queen's Tower or the Wan Chai police station. |
| note | Tong has agreed to a guarded meeting. Sparring room door: 1997. Permission to speak is not permission to search the compound. |
| note | Special Projects operation continued after I left the base. Personnel and archive results are team reports, not my eyewitness account. |
| `UCCopyVLManifest` secondary | Optional: copy Tong's transfer index before the archive is sanitized. Preserve the original shipment and authorization identifiers for comparison at VersaLife. |
| note | Inspected Tong's laboratory transfer index. Source: Tong archive. No independent field copy saved by this reading; use the explicit copy command to preserve the source identifiers. |
| note | Dragon's Tooth voluntarily transferred to  |
| note | Independent field copy, saved before the sweep:  |
| `UCBPReachHeli` primary | Reach Jock's helicopter. |
| `UCBPBoardHeli` primary | A replacement pilot is coming in at the flare south of the subway entrance. Board the helicopter and proceed to Hong Kong. |
| `UCDefendShipment` secondary | A raid is targeting the secured shipment in the service yard. Protect it, inspect the cargo or continue into Wan Chai. |
| `UCMeetLiaison` secondary | Meet the Special Projects liaison and take the freight lift down to Wan Chai. |
| `UCHBAirstrip` secondary | Find the private airstrip north of the harbor where Paul's plane landed. Kwan's pilot is Lo. |
| `FindTracerTong` primary | Locate Tracer Tong, a principal contact for Paul Denton and several terrorist organizations in the region. Find his base, verify the records and report his location from a secure terminal to request a transfer team. |
| `UCReportVersaLife` primary | Walton Simons has authorized an official investigation into the data recovered from Tracer Tong. Compare the Ambrosia shipment identifiers and Special Projects access records with VersaLife's original systems. |
| note | Operation report: independent copy of Tong's transfer index attached. Content and issuing authority still require verification at VersaLife. |
| note | Operation report: no independent field copy attached. Transfer index supplied by Special Projects. Compare this team extraction with the originals at VersaLife. |
| note | VersaLife (Wan Chai market, elevator north of the market): employee number 06288. Access authorized by Walton Simons. |
| `UCTongArchives` primary | Tracer Tong is dead. A Special Projects recovery team is sweeping his facility: do not interfere, secure any intelligence you have already recovered and assist the team only if requested. |
| `UCSecureTong` primary | A Special Projects recovery team is sweeping Tracer Tong's facility. Hold your position: do not interfere, secure any intelligence you have already recovered and assist the team only if requested. |
| note | Independent field copy:  |
| note | Detainee LP-T17: Tong laboratory technician, taken alive after my objection. Special Projects custody. Request his transfer record and testimony at VersaLife. |
