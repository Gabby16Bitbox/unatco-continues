# Mission scripts: Battery Park and the Hong Kong opening

> **Status: to be improved.** This is the story of the part of the mod that is already playable,
> as it was written before building it. The game follows it closely, with small changes made
> along the way. The writing, the pacing and the lore can all be improved, and so can the maps.

## Wanted: people to finish the project

UNATCO Continues is a work in progress and we are looking for passionate people who would like to
help finish it:

- **Mappers**: to build and dress the levels still to come (Hong Kong after the butcher's shop,
  VersaLife, New York, Vandenberg) with the DeusEdix map editor or UnrealEd.
- **Story writers**: to improve this script and write the missions after it, in the voice of the
  original game.
- **Game dev generalists**: UnrealScript, scenes, conversations, testing; whatever the next
  mission needs.

News on the YouTube channel **GABROCHACHO**. Discord: [https://discord.gg/GRNcZf8PM](https://discord.gg/GRNcZf8PM).

---

## Mission 5 – Battery Park

JC was supposed to fly to Hong Kong with Jock. He finds Jock already executed by MJ12's Men in
Black, and a new pilot already assigned.

### Lore note

The Men in Black are the right executioners: they are MJ12 agents who already work alongside
UNATCO in canon.

- In the original game, the Men in Black raid the 'Ton Hotel together with UNATCO to capture Paul
  and JC. Their presence in New York is established.
- They are augmented, speak in a flat, almost robotic way, and explode when killed. JC can't fight
  them here without breaking with UNATCO.
- Jock, real name Brian Flanagan, already disobeyed in canon: instead of flying JC to Hong Kong
  after LaGuardia, he took him to Hell's Kitchen to see Paul. In the mod, this plus the getaway
  flight for Paul is why MJ12 eliminates him.

Sources: ['Ton Hotel raid](https://deusex.fandom.com/wiki/%27Ton_Hotel) ·
[Jock diverts JC to Hell's Kitchen](https://www.gamegrin.com/articles/deus-ex-diaries-part-four/) ·
[Jock (Brian Flanagan)](https://giantbomb.com/wiki/Characters/Jock)

### Phase 1 – Arrival and Jock's call

JC comes up from the Battery Park subway station. Before he can take a step, Jock's InfoLink fires
automatically.

**Jock's InfoLink (automatic, on leaving the subway)**

**JOCK:** JC! Thank God. Listen, I'm at the pad, there's cops all over the chopper—  
**JOCK:** They pulled me out of the cockpit. Said it's routine. It's not routine, JC, they've got guys in suits with them—  
**JOCK:** *[muffled]* Hey, I'm talking to an agent, you can't— *[muffled]* What are you doing with that—

*[Gunshot. Static. The InfoLink cuts out.]*

**New objective:** Reach Jock's helicopter.

**Ambient barks on the way**

- **BUM:** Heard a shot from over by the water. Then suits. Nobody saw nothing, friend.
- **COP:** Feds took over. We're just holding the tape.
- **COP 2:** Since when do feds wear sunglasses at night?

Note: the call stays short and chaotic. The player only hears the shot, never sees it, so the
doubt on Jock's fate holds until Phase 3.

### Phase 2 – The helicopter and the Men in Black

Jock's helicopter sits on the pad, cockpit door open, a smear of blood on the step. Two Men in
Black stand by it; police keep the perimeter. No sign of Jock.

**MIB 1 (automatic, when JC approaches)**

**MIB 1:** Agent Denton. The pilot has been neutralized.

**Dialogue options**

- **JC:** Neutralized. Is he alive? → *[MIB 1 stares at him. No answer.]*
- **JC:** Where is he? → **MIB 1:** That information is not relevant to your mission.
- **JC:** On whose orders? → **MIB 2:** Yours are to stand by. Your transport has been reassigned.
- **JC:** I'll wait. → **MIB 1:** Correct.

**If JC talks to them again before finding the body**

- **MIB 2:** Stand by, Agent Denton.
- **MIB 1:** There is nothing here for you.

Note: the silence after "Is he alive?" is the key beat. It's a non-answer that tells the player
everything, so the search in Phase 3 feels like JC's own decision.

### Phase 3 – The hidden body

Optional. Behind a low wall near the pad, out of the police's line of sight, Jock's body lies under
a tarp. The player finds it only by looking around.

**What's on the body**

- Jock's flask: a pickup with no gameplay value, there for weight.
- A datacube, readable on the spot:

> Jock – thanks for the ride. You didn't have to. Lie low for a while, they'll come asking. – P.

**JC's line on finding him (no choice)**

**JC:** *[quietly]* You flew him out. Of course you did.

Note: the datacube confirms what the MIBs won't say. Jock helped Paul escape, and JC now knows
exactly why he died. If JC left a door open at the hotel, part of that weight is his.

### Phase 4 – Confronting the Men in Black

Available only after finding the body. JC can vent, but nothing he says changes anything: the MIBs
stay flat and in control.

**MIB 1 (greeting this time)**

**MIB 1:** You went behind the wall, Agent Denton.

**Dialogue options**

- **JC:** He was one of ours. You shot him and hid him behind a wall. → **MIB 1:** Pilot Flanagan assisted a fugitive. The matter is closed.
- **JC:** A tarp. That's the best you could do? → **MIB 2:** Cleanup is scheduled. You arrived early.
- **JC:** Who gave the order? Manderley? Simons? → **MIB 1:** The order was given. That is sufficient.
- **JC:** He was a pilot, not a terrorist. → **MIB 2:** He chose a side. You chose another. We noted both.

*Extra option, only if JC read the datacube:*

- **JC:** He flew Paul out. You could have arrested him. → **MIB 1:** Arrests generate records, Agent Denton.

**Closing line (after any option)**

**MIB 1:** Your loyalty has been noted. Do not give us reason to note anything else.

Note: JC can't attack them without breaking with UNATCO, and the mod has no hostile option here.
That's the point: the loyal agent can only swallow it.

### Phase 5 – Eva arrives

The trigger is either JC's first talk with the MIBs (if he skips the body) or the confrontation in
Phase 4. A second UNATCO helicopter lands on a nearby pad.

**Alex's InfoLink (as the helicopter approaches)**

**ALEX:** JC… I just heard about Jock. I don't— He was—  
**SIMONS:** Agent Jacobson, clear this channel.  
**ALEX:** …Yes, sir.  
**SIMONS:** Agent Denton. A replacement pilot is on site. Hong Kong hasn't moved. Neither has your target.

*[End InfoLink]*

**Eva (at the helicopter door)**

**EVA:** Strand. I'm your pilot now.

**Dialogue options**

- **JC:** You knew Jock? → **EVA:** I know his file. Get in.
- **JC:** That was fast. → **EVA:** I was told to be ready. Get in.
- **JC:** *[Get in without a word]* → *(Eva nods. Silence for the whole flight.)*

*If JC found the body:*

- **JC:** They left him behind a wall. → **EVA:** *[a beat]* Then don't give them a reason to do the same with you.

*[Cutscene: takeoff. Transition to Mission 6, Hong Kong.]*

Note: this is Simons' first direct appearance on the InfoLink. He cuts Alex off mid-sentence,
which starts Alex's growing distrust.

### Summary: choices and consequences

The mission is linear and ends the same way for everyone. What changes is how much JC knows when
he leaves.

| Choice | Options | Consequence |
|---|---|---|
| Jock's body | Not found | JC never knows for sure. In Mission 7, when Paul asks about Jock, JC can only answer "I don't know." |
| Jock's body | Found | Unlocks the confrontation with the MIBs and an extra line with Eva. In Mission 7 JC can tell Paul the truth. |
| Paul's datacube | Read | Extra MIB line about arrests. In Mission 7 Paul learns Jock died for flying him out. |
| Confronting the MIBs | Any option | No effect on the mission. The MIBs note JC's words, and that note can come back in Act II. |

---

## Mission 6 – Hong Kong: Opening

### Lore check: can the Luminous Path attack Harbourline?

Yes, it's plausible, but it's an escalation from canon. It has to be justified by intel coming from
Tong.

**What makes it believable**

- Tong is an influential member of the Luminous Path and a sworn enemy of MJ12. In the original
  game he sends JC to steal the sword schematic from VersaLife to arm MJ12's opponents.
- Paul had already paid someone in Hong Kong to steal blueprints and gadgets from VersaLife. The
  Paul–Tong network was already hitting the Coalition.
- The Luminous Path is losing ground in the war with the Red Arrow. It needs a big, visible strike.

**The limit to respect**

- In canon the Triad war hits small businesses, while the big conglomerates stay untouched.
  Attacking a Coalition company is a leap, and it only makes sense if Tong told them what's in the
  shipment.
- Since 2051 the city has acoustic sensors that detect gunfire, which is why the Triads switched to
  swords.

**What this changes in the design**

- Luminous Path enemies fight mostly with swords. Only a few carry firearms.
- The door explosion trips the sensors: the military police will come. The aftermath gets a
  narrative deadline, and the guards have a reason to clean up fast.
- The Luminous Path wants to destroy the shipment, not steal it. It's a traditional, almost
  mystical Triad, so its barks have a ritual tone.

Sources: [Tracer Tong and the Dragon's Tooth sword](https://wikipedia.classicistranieri.com/en/articles/i/n/v/Deus_Ex%7E_Invisible_War_characters_550b.html) ·
[Hong Kong and the acoustic sensors](https://deusex.fandom.com/wiki/File:Wan_Chai_district_map.jpg) ·
[Paul and the VersaLife thefts](https://www.gamegrin.com/articles/deus-ex-diaries-part-eight/) ·
[Luminous Path losing influence](https://www.ludo.guide/guide/deus-ex-remastered/deus-ex-remastered-part-43)

### Phase 1 – Landing

Short cutscene: night, rain, neon. The helicopter sets down on the Harbourline tower helipad. Eva
hasn't said a word the whole flight.

**Cockpit dialogue, before JC steps out**

**EVA:** Harbourline Tower. I'm dropping you here and staying with the chopper.  
**JC:** Copy that.  
**EVA:** My orders are to log when you come back. And who with.  
**JC:** Simons' orders?  
**EVA:** Orders. Get out, Denton.

**Alex's InfoLink, as soon as JC sets foot on the roof**

**ALEX:** JC, it's Alex. Paul's plane touched down at a private airstrip north of the harbor, about six hours ago.  
**ALEX:** If the killswitch numbers are right, he's only got a few hours left.  
**JC:** Enough to reach Tong.  
**ALEX:** If Tong is really here. The Coalition has a vehicle for you on the ground floor. Your contact is Victor Kwan, head of security.  
**ALEX:** One more thing, JC.  
**JC:** Yes?  
**ALEX:** …Nothing. Watch your back. All of it.

*[End InfoLink]*

Note: Alex's last line stays ambiguous. The player can't tell whether he means Eva, Kwan or UNATCO.

### Phase 2 – The rooftop

Three Harbourline guards watch the helipad. The shift leader greets JC; the other two have ambient
barks the player overhears walking past.

**Shift leader Lam (greeting, automatic)**

**LAM:** Agent Denton. Mr. Kwan is waiting for you on the ground floor. The elevator is past the control room.

**If JC talks to him again:**

- **JC:** What are you shipping? → **LAM:** Refrigerated goods. Medicine, I think. I watch the roof, not the containers.
- **JC:** How long have you worked here? → **LAM:** Long enough not to ask questions. I'd recommend the same, agent.
- **JC:** Thanks. → **LAM:** Enjoy your stay in Hong Kong.

**Ambient barks (two guards talking, triggered on approach)**

**GUARD 1:** Big shipment going out tonight?  
**GUARD 2:** Five a.m. And Kwan wants everyone awake until the last container's gone.  
**GUARD 1:** A UNATCO agent… I thought they'd send the other one. The one who got himself in trouble.  
**GUARD 2:** Keep your voice down. That's his brother.

**Single lines (if JC talks to the guards afterwards)**

- **GUARD 1:** Hear those drums down at the market? The Path's been holding ceremonies for three nights.
- **GUARD 2:** Stay away from the railing, the wind up here is treacherous.

**Eva, if JC goes back to her**

- First time: **EVA:** I've got nothing to say to you, Denton.
- Second time: **EVA:** Go. It's your brother's clock that's running, not mine.

Note: the Luminous Path drums foreshadow the attack, and the line about Paul reminds the player
that his name is known in Hong Kong.

### Phase 3 – Helipad control room

An optional room before the elevator: a locked door with extra ammo, a datalog with the
credentials, a wall terminal, and a desk computer with emails about the shipment.

**Datalog (on a shelf, next to the tea machine)**

> Wu, stop calling me at three in the morning for the storeroom password. I change it every week,
> and this week's is below. If Kwan finds out we're writing it on notes, we're both in trouble.
>
> Login: HBSEC Password: FROSTLINE
>
> – Lam

**Wall terminal (login HBSEC / FROSTLINE)**

- Unlock helipad storeroom → opens the door with the ammo.
- Rooftop cameras → turns the cameras on or off.

**Desk computer: emails**

The emails never say what's in the containers. The attentive player only notices that everyone
avoids the subject.

**1. From:** V. Kwan **To:** Harbourline Security **Subject:** Lot 7 departure

> Departure has been moved up to 05:00. Nobody opens the containers for any reason, not even for
> temperature checks: the client's staff handles those. Anyone with questions keeps them to
> themselves.

**2. From:** M. Ho, Shipping **To:** V. Kwan **Subject:** Re: temperatures

> Victor, container 4 had a two-degree spike last night. The client says it's not a problem for the
> contents, but wants whoever opened it removed from the shift. I didn't know you could remove
> someone from the night shift like that. Should I be worried?

> **Kwan's reply:** No. You just need to forget the number 4.

**3. From:** V. Kwan **To:** Rooftop Security **Subject:** Guest tonight

> A UNATCO agent is arriving from the States. Maximum courtesy, minimum conversation. Nobody talks
> to him about the shipment. If he asks, it's medicine.

**4. From:** Lam **To:** V. Kwan **Subject:** The market

> I've seen two Path kids photographing the garage gate. Three times this week. The police say it's
> none of their business. Requesting reinforcements on the ground floor, at least until Lot 7 ships.

Note: container 4 from email 2 is one of the containers the Luminous Path rigs with charges. A
player who read the email recognizes the number during the fight.

### Phase 4 – The warehouse: the welcome

JC steps out of the elevator on the ground floor. Kwan and three guards are waiting among the
refrigerated containers. The dialogue starts on a proximity trigger and is cut off by the explosion.

**Ambient bark as JC approaches**

**GUARD:** Is that him? He looked younger in the photo.

**Dialogue with Kwan**

**KWAN:** Agent Denton. Victor Kwan, Harbourline security. Welcome to Hong Kong.  
**JC:** I was told you have a vehicle for me.  
**KWAN:** Ready and fueled. And I have a man who knows the area around the airstrip where your bro—

*[The garage doors explode. Kwan dives behind a container.]*

**KWAN:** The Path! Everyone to the containers!

**To build**

1. Trigger when JC gets within a few meters of Kwan.
2. Short dialogue, then the explosion on the cut-off word.
3. Doors blow, one guard dies instantly, enemies pour in.
4. Kwan moves to a fixed cover point and stays there for the whole fight.

Note: the line cut off on "brother" tells the player Kwan knows more about Paul than he should.

### Phase 5 – The breach

The Luminous Path storms in to destroy the shipment. Only a few fighters carry firearms; most use
swords. Three charges get planted on containers 2, 4 and 6.

**Objectives**

1. Repel the attack.
2. Defuse the charges on the containers: they're interactable objects with a timer.
3. Kill or capture the squad leader.

**Luminous Path barks**

*On entry*

- Burn the poison! All of it!
- For the Luminous Path!
- The doctor was right, it's in here!

*On spotting JC*

- An American! UNATCO!
- It's the other Denton. The one who obeys.
- The wrong brother. Take him!

*While planting the charges*

- Charges on the cold containers, move!
- Number four! The doctor said number four!
- Thirty seconds! Get clear!

*Retreat and wounded*

- The sensors heard us, the police are coming!
- Fall back to the canal!
- The Path does not forget.

**Kwan's barks from cover**

- The containers, Denton! Not my men, the containers!
- If one of those opens, nobody walks out of here!
- They're going for number four. Number four!

**If a charge goes off**

The container tears open and an icy mist spills out. Kwan loses his composure:

**KWAN:** Get away from that container! Nobody breathe near that stuff!

Note: the "number four" line ties the fight to the email in the control room. The squad leader
shouts "the doctor" twice: it's the first clue pointing to Tong.

### Phase 6 – After the fight

The military police logged the explosion. Kwan and the guards have a few minutes to clean up
before they arrive.

**Kwan comes out of cover**

**KWAN:** Is it over? …Good. We have maybe ten minutes before the military police get here. What you saw tonight didn't happen.  
**JC:** They wanted to destroy the shipment. Why?  
**KWAN:** Because they're fanatics, agent. The Path sees demons everywhere. It's medicine, I told you.

*If all charges were defused:*

**KWAN:** The client will be relieved. So will Simons, I imagine.

*If at least one container blew:*

**KWAN:** You let a container go up, agent. That goes in my report. It's not a threat, it's my job.

*Extra option, only if JC read the container 4 email:*

**JC:** Container 4. They were after it by number.  
**KWAN:** …You read other people's mail, Agent Denton. *[pause]* The airstrip you're looking for is past the harbor, to the north. The pilot's name is Lo. If he's still alive.

If JC doesn't use the extra option, Kwan gives the airstrip info at the end of the normal dialogue.

**The captured squad leader**

**SQUAD LEADER:** You stopped us tonight. You won't stop what's in those crates.  
**JC:** Who told you about the shipment?  
**SQUAD LEADER:** The doctor. He sees what you refuse to see.  
**JC:** Where's the doctor?  
**SQUAD LEADER:** Where your brother went to die. Or to live. That's up to you, Denton.

*Choice:*

- **Hand him over to Kwan** → **KWAN:** We'll take care of it. *(He's never seen again.)*
- **Let him go** → **SQUAD LEADER:** The Path will remember this night. *(He turns up later guarding the compound.)*

**Guards in the garage (ambient barks)**

- Move the Path bodies into the cold room before the police get here.
- How many of ours? — Three. Kwan says the report will say two.
- Did you see how he moved? UNATCO people aren't human.
- Ten years here and I've never looked inside a container. I'm not starting tonight.
- *(Only if a container blew)* Don't touch that liquid! Wait for the gloves!

**Alex's InfoLink, when JC approaches the vehicle**

**ALEX:** JC, I just saw Harbourline's preliminary report. A Luminous Path attack. Are you okay?  
**JC:** They wanted to destroy the shipment. What's in those containers, Alex?  
**ALEX:** *[long pause]* That's above my clearance. *[pause]* And I don't think it's within yours.

*If a container blew:*

**ALEX:** The report also says you let a container blow. Three people in New York have already read it.

**ALEX:** Sending you the airstrip coordinates. Eva's already been told. *[End InfoLink, abrupt cut]*

### Summary: choices and consequences

Four choices in this phase, all in the original game's style: no meters, just marks that resurface
later.

| Choice | Options | Consequence |
|---|---|---|
| Charges on the containers | All defused | The shipment leaves at dawn. In Act II, at VersaLife, JC finds out where it ended up and what it did. |
| Charges on the containers | At least one goes off | Kwan puts it in his report, Alex points it out. In Mission 7 Simons throws it back at JC. |
| Squad leader | Killed | The "doctor" lead is lost: only the airstrip and Maggie remain. |
| Squad leader captured | Handed to Kwan | He disappears from the story. |
| Squad leader captured | Let go | He turns up guarding the Luminous Path compound and lets JC through without a fight. |
| Container 4 email | Read | Extra line with Kwan after the fight, and Kwan knows JC has been snooping. |
| Datalog with password | Found | Extra ammo in the helipad storeroom. No effect on the story. |
