# Status and what is next

*5 October 2026.*

## What exists

The UNATCO route from the fork in mission 4 to the end of the Tracer Tong sequence in
Hong Kong: 67 conversations, about 330 lines, 23 InfoLink lines. See the
[narrative design document](NARRATIVE_DESIGN.md) for the content.

## How far each part has been checked

"Seen in game" means watched in the running game, by a person or with the automatic
photos. Everything also passes the checks that run without the game.

| Part | State |
|---|---|
| The fork with Paul | Seen in game. |
| Gunther outside the hotel, both versions | Seen in game. |
| The search of the hotel, Gilbert at the desk | Seen in game. The "Anna is dead" follow-up line (G16) only in code. |
| Subway gate: Anna, the trooper | Openings A01, A03, A04 and the trooper seen in game; A02, A05, A06 and the follow-ups A11-A13 only in code. |
| Battery Park, take-off | Played in earlier builds; not looked at again after the latest changes. |
| Helibase: Jock, officer, Simons | Seen in game, including the "heard Lebedev" variant. The recovery briefing only in code. |
| Market: the messenger | The messenger is in place (seen in game); the exchange itself was not looked at again in the latest passes. |
| Lucky Money: agents, the Red Arrow, Max Chen | The greeting, the run through the club doors and Max's opening seen in game. The last stretch to the office doors was fixed after the test and not seen again. |
| Queen's Tower, the truce, Tong's laboratory | Implemented; need a full playthrough. The checklist is [PLAYTEST_HK.md](PLAYTEST_HK.md) (Italian). |
| Presentation mode | All steps up to Max Chen seen in game. The Tracer Tong step was seen starting; the scene itself was not played through in this mode. |

## Known gaps

- **Voices.** About 130 of the lines have no recording and play as subtitles.
- **The end is open.** The story stops with the objective to report to VersaLife.
- **Gunther's report on JC** is recorded in a flag and never used yet: it is meant for a
  later debriefing with Manderley.
- **The build was run from a fresh clone, but only on the author's machine.** Expect to
  adjust `config.ps1`, and keep the project in a short folder path.
- The source comments and the working notes are in Italian.

## Ideas for whoever continues

- The VersaLife investigation: what does a UNATCO agent find there when he arrives with
  Simons' authorisation instead of breaking in?
- The return to New York and the debriefing, where the flags left along the way (Gunther's
  report, what JC told Anna, whether he fired on Special Projects) should come back.
- The missions before the fork: small changes that make the refusal feel prepared.
- More headless checks for the Hong Kong chain, so less has to be played by hand.
