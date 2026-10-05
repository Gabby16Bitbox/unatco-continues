# UNATCO Continues - Narrative Design Document

*A story mod for Deus Ex: Revision. This document holds the premise, the rules the writing
follows, and every line of dialogue the mod adds, in story order.*

The first part is written by hand. The second part, **The script**, is generated from the
mod's source code, so it is always exactly what the game plays. Voice recordings are not
part of this repository; every line is shown as text.

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
**JC Denton:** He asked me to join him. I refused.  
**Gunther Hermann:** But you did not arrest him.  
**JC Denton:** I'm not stopping you.  
**Gunther Hermann:** Manderley will hear about this. I do not forget the airfield.  
**JC Denton:** Bring Paul in alive.  
**Gunther Hermann:** Get out of the way.  

*- otherwise:*  
**Gunther Hermann:** Denton. You should be on your way to Hong Kong. Did you see Paul?  
**JC Denton:** I spoke to him.  
**Gunther Hermann:** He is wanted by UNATCO. Why is he not in custody?  
**JC Denton:** He tried to recruit me. I turned him down.  
**Gunther Hermann:** And then you left him here.  
**JC Denton:** I'm not stopping you.  
**Gunther Hermann:** Manderley will hear about this. Get out of the way.  

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
**Special Agent:** I'll report to Mr. Simons.  
**Gunther Hermann:** Tell him we need men at the subway exits. Then check the alley.  

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

#### If JC avoided Gunther outside (G07)

*Conversation `UC_GuntherG07` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over); `GuntherKnowsJCMetPaul` is false (not: Gunther knows JC spoke to Paul).

**Gunther Hermann:** Denton. Were you here with Paul?  
**JC Denton:** I spoke to him. He wanted me to join him. I refused.  
**Gunther Hermann:** You left him free. Manderley will hear about this. Go to Hong Kong.  

*Sets:* `GuntherKnowsJCMetPaul`, `UC_PaulContactReportSent`, `GuntherReportedJCConduct`.

#### The reproach (G10)

*Conversation `UC_GuntherReproach` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over); `GuntherKnowsJCMetPaul` is true (Gunther knows JC spoke to Paul).

**Gunther Hermann:** You spoke to him and walked away. Now we have to search the city.  
**JC Denton:** I didn't help him escape.  
**Gunther Hermann:** You did nothing to stop him.  

#### G11

*Conversation `UC_GuntherG11` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over); `GuntherKnowsJCMetPaul` is true (Gunther knows JC spoke to Paul).

**Gunther Hermann:** Did you warn him we were coming?  
**JC Denton:** I didn't know you were coming.  
**Gunther Hermann:** He knows our methods. That will not save him.  

#### G12 - who the agents are

*Conversation `UC_GuntherG12` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over).

**JC Denton:** Who are the men with you?  
**Gunther Hermann:** Mr. Simons sent them. They are supposed to assist with the arrest.  
**JC Denton:** Are they UNATCO?  
**Gunther Hermann:** They have clearance. That is all I was told.  

*Sets:* `SimonsConnectionHinted`.

#### G13 - who gave the address

*Conversation `UC_GuntherG13` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over).

**JC Denton:** Who told you Paul was here?  
**Gunther Hermann:** Command gave me the address.  
**JC Denton:** Did they say who saw him?  
**Gunther Hermann:** No. The report was correct. They should have sent it sooner.  

#### G14 - Paul's claim (Anna alive)

*Conversation `UC_GuntherG14` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over); otherwise.

**JC Denton:** Paul thinks UNATCO has been compromised.  
**Gunther Hermann:** He swore to serve the Coalition. Then he joined the NSF. That is what I know about your brother.  
**JC Denton:** You won't even look at what he found?  
**Gunther Hermann:** He gave information to our enemies. I do not need his explanation for that.  

#### G16 - the airfield (Anna died on the 747)

*Conversation `UC_GuntherG16` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

Replaces G14.

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over); if Anna Navarre died on the 747 and Manderley debriefed JC after the airfield.

**Gunther Hermann:** You were sent into that aircraft. Agent Navarre did not come back. You still owe me an explanation.  
**JC Denton:** I gave Manderley my report.  
**Gunther Hermann:** I will find out what happened, Denton. Do not think this is over.  

#### G15

*Conversation `UC_GuntherG15` - cinematic dialogue; when JC talks to Gunther Hermann; plays once.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over).

**JC Denton:** You still want this assignment?  
**Gunther Hermann:** Yes. I warned them about Paul, and they waited. Again I am sent after he has gone.  
**JC Denton:** What now?  
**Gunther Hermann:** Now I find him. You have your own orders.  

#### G17 - repeat line

*Conversation `UC_GuntherG17` - overheard (first person, no camera); started by the scene script; repeatable.*

*Only if:* `GuntherTonSearchComplete` is true (the search of Paul's room is over).

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

#### Patrol lines

*Friendly UNATCO troopers say one of these when JC walks by.*

- "They've got every unit in Manhattan looking for your brother."
- "Didn't expect to see you here, Agent Denton."
- "Your pilot's waiting past the fort, Agent Denton."
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

Jock waits in the helicopter. JC resumes the assignment he had before Paul: Hong Kong.

#### Jock (first talk)

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

#### Jock (if JC asked for a minute)

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

#### Jock (ready to leave)

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

## Part II - Hong Kong

### 6. The helibase

In the original game the helibase is an MJ12 trap for a fugitive. Here JC is a UNATCO
agent on duty: no alarm, no assault team, the blast doors are open. The base calls itself
"Special Projects"; nobody explains Majestic 12 to him.

#### Jock, on landing

*Conversation `UC_JockHK` - cinematic dialogue; starts by itself when JC comes within 640 units of Jock (or when JC talks to Jock); plays once.*

**Jock:** Looks like they cleared us.  
**JC Denton:** Who?  
**Jock:** Hong Kong operations.  
**JC Denton:** You've been here before.  
**Jock:** I've landed here before.  
**JC Denton:** There's a difference?  
**Jock:** In this business? Usually.  

#### The welcoming officer (H01-H05)

*Conversation `UC_HKOfficer` - cinematic dialogue; starts by itself when JC comes within 220 units of MJ12 Officer (or when JC talks to MJ12 Officer); plays once.*

He runs to JC as soon as Jock has finished. The middle of the exchange depends on what JC already knows about Majestic 12.

**MJ12 Officer:** Agent Denton. Welcome to Hong Kong.  
**JC Denton:** Who's in charge here?  
**MJ12 Officer:** Special Projects handles this facility.  
*(if `UC_HeardLebedevMJ12` is true (JC heard Lebedev name Majestic 12), skip to **[H02]**)*  
*(if `UC_MJ12NameKnown` is true (JC knows the name Majestic 12), skip to **[H03]**)*  
**JC Denton:** MJ12. What is that?  
**MJ12 Officer:** Special Projects. This facility operates under Coalition authority.  
*(go to **[H05]**)*  
**[H02]**  
**JC Denton:** MJ12. Lebedev mentioned Majestic 12.  
**MJ12 Officer:** This facility operates under Coalition authority. Further details are classified.  
*(go to **[H05]**)*  
**[H03]**  
**JC Denton:** MJ12. Majestic 12?  
**MJ12 Officer:** Special Projects. This facility operates under Coalition authority.  
**[H05]**  
**JC Denton:** Part of UNATCO?  
**MJ12 Officer:** Your clearance covers the transit level. Mr. Simons will brief you on the assignment.  

#### The officer, repeat line

*Conversation `UC_HKOfficerAgain` - cinematic dialogue; when JC talks to MJ12 Officer; repeatable.*

*Only if:* `UC_HKOfficer_Played` is true.

**MJ12 Officer:** The lift at the far end of the hangar, Agent Denton. It will take you down to the market.  

#### Simons' briefing (InfoLink I01 / I02)

*InfoLink (one-way: only the caller speaks), `UCSceneSimonsBriefing`.*

One-way InfoLink: only the caller speaks. It starts right after the officer. The single-line version is the recovery if JC changed map before the briefing ended.

*(recovery version, in place of the three lines below)* **Walton Simons:** Denton. Your orders are to locate Tracer Tong and identify his network. Start with Maggie Chow. Special Projects has cleared you to proceed.  
**Walton Simons:** Denton. Special Projects personnel in Hong Kong have been instructed to cooperate with your investigation. Manderley's orders remain in effect: locate Tracer Tong and identify the people protecting him before you move against him.  
**Walton Simons:** Tong has survived this long because very few outsiders know where he operates. Start with Maggie Chow. She has contacts with both Triads and has cooperated with Coalition interests in the past.  
**Walton Simons:** Find Tong's network. Once we know where he is, we'll decide how to proceed.  

### 7. Wan Chai market

Same Hong Kong, reversed relations: to the Triads JC is a UNATCO agent, not a fugitive.

#### The Red Arrow messenger

*Conversation `UC_Messenger` - cinematic dialogue; when JC talks to Red Arrow Messenger; plays once.*

He stands in the corridor outside the freight lift and speaks when JC walks past. Optional: everything he says can be learned elsewhere.

**Red Arrow Messenger:** Denton?  
**JC Denton:** Who's asking?  
**Red Arrow Messenger:** Someone who knows why you're here. Max Chen wants to see you at the Lucky Money.  
**JC Denton:** Why?  
**Red Arrow Messenger:** Ask him.  

*Sets:* `RedArrowMessengerContacted`, `MaxChenMeetingAvailable`.

#### The messenger, repeat line

*Conversation `UC_MessengerAgain` - cinematic dialogue; when JC talks to Red Arrow Messenger; repeatable.*

*Only if:* `UC_Messenger_Played` is true (the Red Arrow messenger spoke to JC).

**Red Arrow Messenger:** The Lucky Money. Mr. Chen does not like to wait.  

### 8. The Lucky Money

Max Chen sent for JC, so nobody asks him for the entry fee and someone takes him in.

#### The government agents (overheard)

*Conversation `UC_LMForeshadow` - overheard (first person, no camera); started by the scene script; plays once.*

Two "government agents" lean on a Red Arrow at the entrance and leave when JC approaches. A hint, not a fight.

**Government Agent:** The shipment was received. Chen accepted the money.  
**Red Arrow:** Max never asked for the shipment.  
**Second Government Agent:** He accepted the money.  
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

*Conversation `UC_MaxMeet` - cinematic dialogue; starts by itself when JC comes within 190 units of Max Chen (or when JC talks to Max Chen); plays once.*

Max speaks first and says why he sent for JC: he wanted to see him before Maggie Chow did.

*Only if:* `Have_Evidence` is false (not: JC found the Dragon's Tooth in Maggie Chow's apartment).

**Max Chen:** Mr. Denton. I wanted to see you before the others do.  
**JC Denton:** What others?  
**Max Chen:** A UNATCO agent arrives in Hong Kong looking for Tracer Tong. Many people will want to tell him where to look.  
**JC Denton:** And you?  
**Max Chen:** I will tell you where not to look. This is the headquarters of the Red Arrow Triad. Mr. Tong works with the Luminous Path.  
**JC Denton:** And Maggie Chow?  
**Max Chen:** Miss Chow has interests everywhere. The Red Arrow, VersaLife, the police... perhaps even UNATCO.  
**JC Denton:** She knows I'm coming.  
**Max Chen:** Yes. That is why I sent for you first.  

*Sets:* `MeetMaxChen_Played`, `KnowsAboutTriads`.

### 9. Queen's Tower

#### Maggie Chow

*Conversation `UC_MaggieMeet` - cinematic dialogue; starts by itself when JC comes within 120 units of Maggie Chow (or when JC talks to Maggie Chow); plays once.*

**Maggie Chow:** Mr. J. C. Denton... in the flesh. As dark and serious as his brother.  
**JC Denton:** You knew him?  
**Maggie Chow:** Everyone who dealt seriously with Tracer Tong knew Paul eventually. He spent a great deal of time in Hong Kong before UNATCO realized where his loyalties had shifted.  
**JC Denton:** That's not what I asked.  
**Maggie Chow:** Yes. I knew him.  
**Maggie Chow:** Paul came here looking for evidence that UNATCO was conspiring against him. Tong gave him exactly what he wanted to hear. That's what Tong does.  
**Maggie Chow:** He finds intelligent people who already distrust authority and convinces them that only he understands the truth.  
**JC Denton:** Paul didn't need much encouragement.  
**Maggie Chow:** Perhaps not. But Tong gave him contacts, protection and a cause. Look at the result. Your brother abandoned his career, his friends and his own government.  
**JC Denton:** What does that have to do with the Triads?  
**Maggie Chow:** Everything. The Red Arrow and Luminous Path were once capable of doing business together. Since Tong became involved, every disagreement has become ideological.  
**Maggie Chow:** Weapons disappear, shipments are attacked, people die, and Tong remains safely hidden while everyone else pays the price.  
*(if `MeetMaxChen_Played` is true (JC met Max Chen), skip to **[MaxMet]**)*  
**JC Denton:** Simons says you have contacts with both sides.  
*(go to **[Sword]**)*  
**[MaxMet]**  
**JC Denton:** Max Chen says you have contacts with both sides.  
**[Sword]**  
**Maggie Chow:** I try to keep this city from destroying itself. Unfortunately, the Luminous Path recently stole something that has made reconciliation almost impossible: a prototype weapon known as the Dragon's Tooth.  
**JC Denton:** Why would they steal it?  
**Maggie Chow:** Power. Prestige. Leverage against Red Arrow. Pick whichever motive you prefer; they're all true.  
**JC Denton:** And you want it recovered.  
**Maggie Chow:** I want the Triads talking again. If you find the weapon, you may find the path to Tong with it.  

*Sets:* `MeetMaggie_Played`, `KnowsAboutMaggie`, `KnowsAboutTriads`, `FoundMaggieChow`.

#### Maggie, repeat line

*Conversation `UC_MaggieAgain` - cinematic dialogue; when JC talks to Maggie Chow; repeatable.*

*Only if:* `UC_MaggieMeet_Played` is true (JC met Maggie Chow).

**Maggie Chow:** Find the Dragon's Tooth, Mr. Denton, and you may find the path to Tong with it.  

#### The recording in the hidden room

*Conversation `M06WaltonHolo` - overheard (first person, no camera); started by the scene script; plays once.*

The original Simons hologram, rewritten as a recording of Simons and Maggie. It is suspicious only because JC finds it there.

**Walton Simons:** Ms. Chow. Denton should be arriving shortly. He's still following UNATCO orders, which makes him useful.  
**Maggie Chow (recording):** And if Paul changed his mind?  
**Walton Simons:** He didn't. Paul made the mistake of confronting his brother before Denton had seen enough evidence to doubt the institution.  
**Maggie Chow (recording):** You're very confident.  
**Walton Simons:** Denton believes in procedure. Give him a procedure to follow.  
**Maggie Chow (recording):** And Tong?  
**Walton Simons:** If Denton gets close enough, we'll know where to look.  
**JC Denton:** Simons...  

*Sets:* `SimonsConvoPlaying` = false, `UC_HoloSeen`.

#### Simons answers JC's report (JC saw the recording)

*InfoLink (one-way: only the caller speaks), `UCSceneSimonsSword`.*

JC reports the Dragon's Tooth when he leaves the hidden room; the report itself is not spoken.

**Walton Simons:** Denton. I received your report from Queen's Tower. Secure the Dragon's Tooth.  
**Walton Simons:** Maggie Chow is a Coalition intelligence asset. Her relationship with Special Projects predates your assignment, and portions of that relationship are classified. Intelligence assets are not required to tell you everything they know.  
**Walton Simons:** Whatever else you found, don't let it distract you from the objective. Chow's activities can be reviewed after Tong is in custody.  
**Walton Simons:** Locate Tracer Tong.  

#### Simons answers JC's report (JC did not see the recording)

*InfoLink (one-way: only the caller speaks), `UCSceneSimonsSword`.*

**Walton Simons:** Denton. I received your report on the Dragon's Tooth. Secure the weapon and continue your investigation.  
**Walton Simons:** Maggie Chow is a Coalition intelligence asset. Assets sometimes withhold information when they believe it protects their position. That doesn't make everything they've provided useless.  
**Walton Simons:** Don't lose sight of the assignment. Resolve the Triad situation and locate Tracer Tong. We'll review Chow afterward.  

### 10. The truce

#### Gordon Quick at the compound gate

*Conversation `UC_GordonMeet` - cinematic dialogue; starts by itself when JC comes within 180 units of Gordon Quick (or when JC talks to Gordon Quick); plays once.*

Hostile in words; he does not attack.

*Only if:* `MaxChenConvinced` is false (not: Max Chen declared the truce).

**Gordon Quick:** Paul Denton trusted you.  
**JC Denton:** Paul made a mistake.  
**Gordon Quick:** Which one?  
**JC Denton:** Choosing terrorists over UNATCO.  
**Gordon Quick:** No. Trusting his brother.  
**Gordon Quick:** Paul worked with us. He took risks for people here, and he earned our confidence. You arrive with a UNATCO badge and orders to find Tong. Don't expect the same treatment.  
**JC Denton:** I don't need your trust. I need Tong.  
**Gordon Quick:** Then you need information, and information has a price.  
**JC Denton:** What's yours?  
**Gordon Quick:** Ask Maggie Chow who killed Yuen Kong.  
**JC Denton:** Why don't you tell me?  
**Gordon Quick:** Because you wouldn't believe me.  

*Sets:* `Gate_Guard2_Played`, `KnowsAboutMaggie`, `KnowsAboutNanoSword`.

#### Gordon, repeat line

*Conversation `UC_GordonWait` - cinematic dialogue; when JC talks to Gordon Quick; repeatable.*

*Only if:* `UC_GordonMeet_Played` is true (JC met Gordon Quick); `Have_Evidence` is false (not: JC found the Dragon's Tooth in Maggie Chow's apartment).

**Gordon Quick:** Ask Maggie Chow who killed Yuen Kong, Agent Denton.  

#### Gordon, with the evidence

*Conversation `UC_GordonEvidence` - cinematic dialogue; when JC talks to Gordon Quick; plays once.*

*Only if:* `Have_Evidence` is true (JC found the Dragon's Tooth in Maggie Chow's apartment); `MaxChenConvinced` is false (not: Max Chen declared the truce).

**JC Denton:** Maggie Chow had the Dragon's Tooth.  
**Gordon Quick:** Then you know who killed Yuen Kong.  
**JC Denton:** I know who had his sword.  
**Gordon Quick:** Show it to Max Chen. If he still wants war after that, nothing will stop it.  

*Sets:* `Gate_Guard2_Played`, `QuickConvinced`.

#### Max Chen, with the evidence

*Conversation `UC_MaxEvidence` - cinematic dialogue; starts by itself when JC comes within 190 units of Max Chen (or when JC talks to Max Chen); plays once.*

*Only if:* `Have_Evidence` is true (JC found the Dragon's Tooth in Maggie Chow's apartment); `MaxChenConvinced` is false (not: Max Chen declared the truce).

**Max Chen:** Miss Chow had the Dragon's Tooth?  
**JC Denton:** Yes.  
**Max Chen:** Then Yuen Kong was right to suspect her. He went to Queen's Tower because he believed Miss Chow was arranging the attacks that kept the Red Arrow and the Luminous Path at war. He never came back.  
**JC Denton:** That's evidence of deception. Not murder.  
**Max Chen:** You are careful with words.  
**JC Denton:** Words are what you have until you get proof.  
**Max Chen:** Hmmm. Perhaps. But if Miss Chow had the sword, the reason for this war is gone. I will call Gordon Quick.  
**JC Denton:** Do it.  
**Max Chen:** There is something I do not understand. You work for UNATCO. Miss Chow works with your people. Yet you bring me evidence against her.  
**JC Denton:** I work for UNATCO. Not Maggie Chow.  
**Max Chen:** Is there a difference?  
**JC Denton:** There should be.  

*Sets:* `MeetMaxChen_Played`, `MadeChenAccusation`, `MaxChenConvinced`.

#### Max Chen, after the truce

*Conversation `UC_MaxAfter` - cinematic dialogue; when JC talks to Max Chen; repeatable.*

*Only if:* `MaxChenConvinced` is true (Max Chen declared the truce).

**Max Chen:** I have called Gordon Quick. The Red Arrow will keep the truce. He is expecting you at the compound.  

#### Gordon, after the truce

*Conversation `UC_GordonFinal` - cinematic dialogue; starts by itself when JC comes within 180 units of Gordon Quick (or when JC talks to Gordon Quick); plays once.*

*Only if:* `MaxChenConvinced` is true (Max Chen declared the truce); `QuickLetPlayerIn` is false (not: Gordon Quick gave JC access to Tong).

**Gordon Quick:** You stopped a war you could have used to weaken both Triads. I did not expect that from UNATCO.  
**JC Denton:** Dead Triads don't tell me where Tong is.  
**Gordon Quick:** Maybe that is all it is.  
**JC Denton:** Does it matter?  
**Gordon Quick:** To Tong, yes.  
**Gordon Quick:** You have shown that you are willing to follow evidence even when it embarrasses your own contacts. Tong has agreed to speak with you.  
**JC Denton:** I didn't ask to speak with him.  
**Gordon Quick:** No. You came here to arrest him.  
**Gordon Quick:** Nineteen ninety-seven. The door in our sparring room. Keep your weapon down until someone gives you a reason not to.  
**JC Denton:** Good advice.  

*Sets:* `Gate_Guard2_Played`, `QuickConvinced`, `QuickLetPlayerIn`.

### 11. Tracer Tong

#### The guard at Tong's base

*Conversation `UC_TongGuardBark` - overheard (first person, no camera); started by the scene script; repeatable.*


*- one time:*  
**Luminous Path Guard:** Tong agreed to see you. That doesn't make you welcome.  

*- the next time:*  
**Luminous Path Guard:** Keep your weapon down and there won't be a problem.  

#### Tracer Tong

*Conversation `UC_TongMeet` - cinematic dialogue; starts by itself when JC comes within 220 units of Tracer Tong (or when JC talks to Tracer Tong); plays once.*

**Tracer Tong:** J.C. Denton.  
**JC Denton:** Tracer Tong.  
**Tracer Tong:** Paul believed you would come here eventually. I don't think this is what he had in mind.  
**JC Denton:** Paul expected me to ask for your help.  
**Tracer Tong:** And instead you have orders to remove me.  
**JC Denton:** Identify your network first. Then take you out.  
**Tracer Tong:** A useful phrase. 'Take out.' It allows a bureaucrat to postpone deciding whether a man is a prisoner or a corpse.  
**JC Denton:** You're still here.  
**Tracer Tong:** Because you came to talk first.  
**JC Denton:** Paul says UNATCO is compromised.  
**Tracer Tong:** And you do not believe him.  
**JC Denton:** I believe he found evidence. I don't believe joining the NSF made the evidence more true.  
**Tracer Tong:** That is the difference between you and your brother. Paul reached the end of the argument before he showed you the beginning. He asked you to accept his conclusions because you trusted him.  
**JC Denton:** I don't.  
**Tracer Tong:** Good. Trust is useful between friends. It is a poor substitute for evidence.  
**JC Denton:** Then show me yours.  
**Tracer Tong:** Exactly.  

*Sets:* `TongMeetingStarted`.

#### Tong's terminal

*Conversation `UC_TongEvidence` - cinematic dialogue; when JC talks to Tracer Tong; plays once.*

**Tracer Tong:** These are shipping records Paul obtained before he left UNATCO. Compare the identifiers with these.  
**JC Denton:** Same Ambrosia shipments.  
**Tracer Tong:** Rerouted through VersaLife subsidiaries. Here are the corresponding laboratory authorizations.  
**JC Denton:** Nanotechnology.  
**Tracer Tong:** Restricted research, below the publicly listed facilities.  
**JC Denton:** This proves VersaLife is involved with the shipments. It doesn't prove UNATCO is.  
**Tracer Tong:** No. So keep looking.  
**JC Denton:** Why give this to me?  
**Tracer Tong:** Because Paul tried to change your allegiance. I'm interested in changing your information.  

*Sets:* `TongEvidenceShown`.

#### Simons calls: the assault

*InfoLink (one-way: only the caller speaks), `UCSceneTongLab`.*

**Walton Simons:** Denton. Hold your position. A Special Projects recovery team is entering the compound.  
*(if Tong is dead)* **Walton Simons:** Tong's death has been confirmed. Do not interfere with the sweep. Secure any intelligence you've already recovered and assist the team only if requested.  
**Walton Simons:** Tong's location has been confirmed. Do not interfere with the sweep. Secure any intelligence you've already recovered and assist the team only if requested.  
**Walton Simons:** You've completed the locating phase of your assignment.  

#### The alarm

*Conversation `UC_TongAlarm` - cinematic dialogue; when JC talks to Tracer Tong; plays once.*

**JC Denton:** What happened?  
**Tracer Tong:** Several armed teams just entered the upper compound. Coalition weapons, coordinated movement.  
**Tracer Tong:** Your friends.  
**JC Denton:** UNATCO?  
**Tracer Tong:** You tell me.  

#### Tong understands

*Conversation `UC_TongUnderstands` - cinematic dialogue; when JC talks to Tracer Tong; plays once.*

**Tracer Tong:** There is your answer.  
**JC Denton:** To what?  
**Tracer Tong:** Why they let you find me.  
**Tracer Tong:** They did not send you here because they trusted you to kill me. They sent you because I would allow Paul Denton's brother through a door I would close to any other UNATCO agent.  
**JC Denton:** They could have followed me from the market.  
**Tracer Tong:** And found another safehouse. Another basement. Another empty room.  
**Tracer Tong:** You were the authentication.  
**Tracer Tong:** Come with me.  
**JC Denton:** No.  
**Tracer Tong:** Then stay here.  
**Tracer Tong:** Paul wanted you to believe him. I don't.  
**Tracer Tong:** Watch what your people do.  

*Sets:* `JCWasTheAuthentication`.

#### The Special Projects commander

*Conversation `UC_SPCommanderMeet` - cinematic dialogue; when JC talks to Special Projects Commander; plays once.*

**Special Projects Commander:** Agent Denton. Special Projects. We'll secure the facility from here.  
*(if `TongEscapedCompound` is true, skip to **[Fled]**)*  
**JC Denton:** Tong is dead.  
**Special Projects Commander:** Then his data is what matters. Your orders are to preserve any intelligence you recovered and stay clear of the sweep.  
*(go to **[Orders]**)*  
**[Fled]**  
**JC Denton:** Tong's moving through the rear section.  
**Special Projects Commander:** Teams are covering the exits. Your orders are to preserve any intelligence you recovered and stay clear of the sweep.  
**[Orders]**  
**JC Denton:** Simons told me to secure the facility.  
**Special Projects Commander:** Then we have compatible objectives.  

#### A Special Projects technician

*Conversation `UC_SPTechTalk` - cinematic dialogue; starts by itself when JC comes within 220 units of Special Projects Technician (or when JC talks to Special Projects Technician); plays once.*

**JC Denton:** What are you doing?  
**Special Projects Technician:** Sanitizing the network. Tong's people had access to restricted Coalition material.  
**JC Denton:** Those systems are evidence.  
**Special Projects Technician:** Anything relevant has already been copied.  
**JC Denton:** By who?  
**Special Projects Technician:** Special Projects.  

*Sets:* `JCSawDataSanitized`.

#### A prisoner (overheard)

*Conversation `UC_PrisonerBark` - overheard (first person, no camera); started by the scene script; repeatable.*

**Prisoner:** I'm unarmed! I'm not security!  

#### The prisoner

*Conversation `UC_PrisonerTalk` - cinematic dialogue; when JC talks to Special Projects Commander; plays once.*

**JC Denton:** Hold your fire.  
**Special Projects Commander:** He's part of Tong's technical staff.  
**JC Denton:** Then arrest him.  
**Special Projects Commander:** We weren't instructed to process prisoners.  
**JC Denton:** You are now.  
**Special Projects Commander:** Take him upstairs.  

*Sets:* `JCObjectedToMJ12Execution`.

#### The commander, when the facility is secure

*Conversation `UC_SPCommanderAfter` - cinematic dialogue; when JC talks to Special Projects Commander; plays once.*

*(if `TongEscapedCompound` is true, skip to **[Fled]**)*  
**Special Projects Commander:** The facility is secure. The network, personnel and data are ours.  
**JC Denton:** Nobody told me that was the objective.  
*(go to **[Door]**)*  
**[Fled]**  
**JC Denton:** Tong got out.  
**Special Projects Commander:** The facility is secure.  
**JC Denton:** Tong was the objective.  
**Special Projects Commander:** Tong was one objective. The network, personnel and data were the others.  
**JC Denton:** Nobody told me that.  
**[Door]**  
**Special Projects Commander:** You weren't part of this operation until you found the door.  

#### The commander, repeat line

*Conversation `UC_SPCommanderAgain` - cinematic dialogue; when JC talks to Special Projects Commander; repeatable.*

*Only if:* `UC_SPCommanderMeet_Played` is true.

**Special Projects Commander:** Stay clear of the sweep, Agent Denton.  

#### Simons, after the operation

*InfoLink (one-way: only the caller speaks), `UCSceneSimonsAfterTong`.*

*(if Tong is dead)* **Walton Simons:** Denton. Tong is dead, and his facility and most of his local network have been compromised. Special Projects is sanitizing the site and preserving whatever intelligence is relevant.  
**Walton Simons:** Denton. Tong escaped during the operation, but his facility and most of his local network have been compromised. Special Projects is sanitizing the site and preserving whatever intelligence is relevant.  
**Walton Simons:** I've reviewed the material recovered from Tong's systems. Several files reference VersaLife, including Ambrosia shipping records and restricted research directories.  
**Walton Simons:** You'll proceed to VersaLife under official authorization. Tong's people penetrated their network; determine what they accessed, recover any compromised research and verify the shipping records while you're there.  
**Walton Simons:** If Tong manufactured the evidence, we'll know soon enough.  
**Walton Simons:** I'm told you fired on Coalition personnel.  
**Walton Simons:** We'll discuss your judgment when you return.  
**Walton Simons:** Report when you have something conclusive.  

## Objectives and notes

*The mission objectives and notes the mod gives the player.*

| Objective | Text |
|---|---|
| `UCMeetMaxChen` secondary | Optional: Max Chen of the Red Arrow Triad wants to see you at the Lucky Money club. |
| `UCInvestigateLumPath` secondary | Investigate the Luminous Path. Gordon Quick will not let a UNATCO agent into their compound: you will have to earn his trust. |
| `UCYuenKong` secondary | Optional: investigate the death of Red Arrow leader Yuen Kong. |
| `UCShowMaxChen` primary | Show Max Chen what you found: the Dragon's Tooth was in Maggie Chow's apartment. |
| `UCTellGordon` primary | Max Chen has declared a truce and called Gordon Quick. Go to the Luminous Path compound. |
| note | Tracer Tong's laboratory is beneath the Luminous Path compound. The door is in the sparring room: code 1997. |
| `SendSignal` primary | Investigate the NSF transmitter and decide whether to send Paul's distress signal. |
| `MeetJockBatteryPark` primary | Resume your original assignment. Meet Jock in Battery Park and proceed to Hong Kong. |
| `FindTracerTong` primary | Locate Tracer Tong, a principal contact for Paul Denton and several terrorist organizations in the region. Find his base and establish who is protecting him before Tong is taken out. |
| `UCReportVersaLife` primary | Walton Simons has authorized an official investigation into the data recovered from Tracer Tong. Report to VersaLife and determine whether its systems or personnel were compromised. |
| note | VersaLife (Wan Chai market, elevator north of the market): employee number 06288. Access authorized by Walton Simons. |
| `ContactMaggieChow` secondary | Contact Maggie Chow, a VersaLife executive with contacts in both Triads who has cooperated with Coalition interests in the past. She lives in Queen's Tower. |
| `UCTongArchives` primary | Tracer Tong is dead. A Special Projects recovery team is sweeping his facility: do not interfere, secure any intelligence you have already recovered and assist the team only if requested. |
| `UCSecureTong` primary | A Special Projects recovery team is sweeping Tracer Tong's facility. Hold your position: do not interfere, secure any intelligence you have already recovered and assist the team only if requested. |
| note | VersaLife data fragment (Tong's terminal): Ambrosia shipments from UNATCO manifests rerouted through VersaLife subsidiaries. Restricted nanotechnology research below the publicly listed facilities. Cross-reference: 'GRAY'. Incomplete. |
