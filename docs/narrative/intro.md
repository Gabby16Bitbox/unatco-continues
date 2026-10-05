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
