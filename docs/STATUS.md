# Status and what is next

*6 October 2026. Earlier playtest observations are identified below.*

## Current campaign revision

The [Special Projects building in Wan Chai](HONGKONG_ROOFTOP_FLOW.md) replaces the initial MJ12 arrival on the new route. Rebuilt from scratch on 8 October 2026 with the headless map toolkit: a civilian rooftop with a worn H pad, edge lights, floodlights, windsock, fuel drums, HVAC plant, water tanks, antenna and billboard, a checkpoint door that opens for JC, a security lobby with the locked store, and a freight lift down to a fully lit street-level loading dock in the same map (bays with shutters and a docked trailer, container, pallet racks, crates and barrels). Harbour, Queen's Tower and VersaLife are visible from the roof. The Market is the original Revision map again: the dock leads to it through the vanilla freight-lift arrival, and the Market lift returns to the dock until the story opens the helibase. Jock stays with the helicopter; the liaison and one-way Simons call introduce Special Projects without an early MJ12 explanation. A cargo diversion permits intervention, label inspection or leaving. The messenger, Max and Tong distinguish these observed events.

All 325 current runtime voice entries are generated and validated: 275 compatible takes reused and 50 new performances for the rooftop/cargo revision. Existing radio-only de-essing, the -2 dB peak ceiling, restrained JC delivery and Max's dedicated balance correction are retained. The private packages pass 325 voice, 49 dialogue, 144 route, 140 rewrite-policy and 168 voice-identity checks: 826 checks with zero failures. The geometry recipe preserves the Market's original actors and baked lighting; the new roof uses dynamic lights.

Latest revision installed on 8 October 2026 after a real-game trial of the whole arrival: 27 checks, zero failures (Jock, pad steps, liaison, checkpoint, Simons call, lift down and up, dock briefing, raid, cargo label, retained knowledge). The security detail now uses the Secret Service body, fixing guards drawn with a stretched face on the chest. The building was then made compact to the original game's measurements (64 x 128 doors, 144-high rooms, 48-high counter, 96-high lockers, textures at native scale; the dock went from 2400 x 2000 x 480 to 1152 x 896 x 256), and the third raider now waits in the docked trailer, out of the guards' sight. Photos: [roof, lobby and dock](../shots/20261008-143550-roof8-compatto/) and [the raid](../shots/20261008-145622-rooftop-play6/). Use a save before the flight or a fresh debug level; already visited maps retain their saved geometry.

An intermediate photographic run was rejected after JC left the intended route and travelled through the compound, repeating part of the probe (38 checks, five failures). Automatic photography now suppresses manual movement input using PlayerPawn's menu-input mode, without opening a menu; native capsule sweeps, Frob and map travel are still tested. The final run above passed with that correction. This control suppression only runs in the opt-in, temporary photographer session.

## Earlier rewrite and Tong installation

The [6 October rewrite](CAMPAIGN_REWRITE_2026_10_06.md) is integrated in the campaign code. Gunther has two optional follow-ups; Max and Maggie make competing offers. Sword location, actual custody and evidence of Yuen Kong's death are distinct. Gordon also grants a supervised meeting on the evidence route, without requiring Max or a global truce.

Paul's records and Tong's archive are readable documents with separate reading/copying flags. JC sends the location report from a terminal, receives Simons' order and explicitly opens the rear loading door from the laboratory's service console. The narrow, slightly recessed door matches the warehouse wall and lowers into the floor. The compact loading room uses the warehouse's dark gray wood floor and ceiling, with a stocked shelf, cargo, a push-cart, a barrel and eight stairs on the right. Its upper INF gate restricts access to the exterior map-loading exit. Special Projects walks down the stairs and physically crosses into the storeroom before the raid starts. The firing range is original and the console uses HKNet without UNATCO branding. Timers, conversations, Tong's death and map exits do not start the raid. The final operation report is also a manual terminal action.

All 279 current runtime voice entries are generated and verified: 270 compatible takes reused and nine new performances for the initial integration; Simons' transfer order was subsequently updated for the warehouse entrance. They include the earlier rewrite recordings. The mix uses de-essing only on radio/InfoLink, a -2 dB peak ceiling on every voice, restrained JC delivery and a targeted 1.5 LU lift plus mild midrange EQ for Max Chen. The preparation commands and previews are documented in [tools/voices/README.md](../tools/voices/README.md).

The installed build passed 279 voice, 49 dialogue, 144 route, 140 rewrite-policy and 168 voice-identity checks: 780 checks, zero failures. Nine map checks passed another 267 assertions, including the real loading door, service-road staging, the INF boundary and the uncut firing bench. Two real-game trials passed 32 checks each: intervention with custody recorded, and the ignored confrontation with no manifest copy and Tong already dead. Both verify JC's actual swept movement: the closed wall blocks him and the fully lowered wall lets him through. Native terminal actions, physical squad entry, selective archive sanitization and the final report were exercised. These checks are not a full campaign playthrough or an in-game listening comparison.

The Tong map recipe preserves the original baked lighting and verifies the input actors after editing a private copy. A separate bridge plan moves the single crate that blocked the new entrance beside the other cargo; the remaining original gameplay properties are preserved. It does not run a global light calculation. Real-game trials use the checked packages and restore the original map, packages, photographer settings and temporary save afterward. Installation uses the separate `Revision/UnatcoMaps` folder; the original Steam map is retained.

The exact tested packages and Tong map were installed on 6 October at 21:05, with backups in `dist/backup`. The original Steam Tong map and the project/game helipad hashes remain unchanged. [The loading-room photograph](../shots/20261006-210410-bridge-36d345c5c1/10_store-detail.png) shows the floor, shelf and stairs. Saves that already contain Tong's map retain their cached geometry; use a save before the first visit, or a fresh debug level, to see the new room and collision.

At 21:29 the exterior INF gate received a recognizable native two-leaf metal-door material. Its actors, geometry, collision hulls and baked lighting remain identical to the preceding map. SDK load/save/reload and the 67 Tong map checks passed. A focused real-game trial shows [the door](../shots/20261006-212851-bridge-8d40ca3900/00_front.png) and [Locked / Lock Str: INF / Door Str: INF after use](../shots/20261006-212851-bridge-8d40ca3900/03_locked.png); the gate stays at key 0. The material-only update was installed with a backup, using this focused proof and rechecking its unchanged gameplay input against the earlier passing trial.

## What exists

The UNATCO route from the fork in mission 4 to the end of the Tracer Tong sequence in
Hong Kong: 70 conversations, 324 conversation lines and 14 InfoLink lines. See the
[narrative design document](NARRATIVE_DESIGN.md) for the content.

## Earlier scene checks â€” 5 October

"Seen in game" means watched in the running game, by a person or with the automatic
photos. Everything also passes the checks that run without the game.

| Part | State |
|---|---|
| The fork with Paul | Seen in game. |
| Gunther outside the hotel, both versions | Seen in game. |
| The search of the hotel, Gilbert at the desk | Seen in the previous build. The revised optional Gunther follow-ups require another full playthrough. |
| Subway gate: Anna, the trooper | Openings A01, A03, A04 and the trooper seen in game; A02, A05, A06 and the follow-ups A11-A13 only in code. |
| Battery Park, take-off | Played in earlier builds; not looked at again after the latest changes. |
| Helibase: Jock, officer, Simons | Seen in game, including the "heard Lebedev" variant. The recovery briefing only in code. |
| Market: the messenger | The messenger is in place (seen in game); the exchange itself was not looked at again in the latest passes. |
| Lucky Money: agents, the Red Arrow, Max Chen | The greeting, the run through the club doors and Max's opening seen in game. The last stretch to the office doors was fixed after the test and not seen again. |
| Queen's Tower and Gordon | Earlier checks preceded the revised evidence/custody route; a full manual investigation playthrough remains useful. The updated checklist is [PLAYTEST_HK.md](PLAYTEST_HK.md) (Italian). |
| Presentation mode | All steps up to Max Chen seen in game. The Tracer Tong step was seen starting; the scene itself was not played through in this mode. |

## Known gaps

- **Cached map geometry.** Previously visited levels remain in the save. Use a save from before the flight, or a fresh debug level, to inspect the new rooftop and loading dock.
- **Coverage.** The automated checks and Tong trials do not certify every save/load combination, all campaign choices or the subjective voice balance against music and effects. The manual checklist remains relevant.
- **Intermittent Tong scene behavior.** An additional extended trial during the door-material update returned 32 checks with two failures: saving the prisoner and reaching/sanitizing the archive. The technicians backed off near the corridor. This result remains recorded in `tools/editor_bridge/trials/packages-4a1c348200a3427e8e369e9f1f1460ef`; the door's focused test passed separately. The material patch changes no actor or collision behavior, but the extended scene cannot be considered consistently passing.
- **The end is open.** The story stops with the objective to report to VersaLife.
- **Gunther's report on JC** is recorded in a flag and never used yet: it is meant for a
  later debriefing with Manderley.
- **The build was run from a fresh clone, but only on the author's machine.** Expect to
  adjust `config.ps1`, and keep the project in a short folder path.
- The source comments and the working notes are in Italian.

## Ideas for whoever continues

The plan for the rest of the campaign is written down in the
[campaign concept](CAMPAIGN_CONCEPT.md): a second Hong Kong mission at VersaLife, a return
to New York, Vandenberg, and an optional finale with four endings. It is indicative, not a
script. In short:

- The VersaLife investigation: what does a UNATCO agent find there when he arrives with
  Simons' authorisation instead of breaking in?
- The return to New York and the debriefing, where the flags left along the way (Gunther's
  report, what JC told Anna, whether he fired on Special Projects) should come back.
- The missions before the fork: small changes that make the refusal feel prepared.
- More headless checks for the Hong Kong chain, so less has to be played by hand.
