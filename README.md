# Thanks for the Buff Forever

A small buff-thanking addon for **WoW Forever beta 1.60.1**.

When a nearby player gives you a supported buff, your character uses `/thank` at them. By default, party and raid members are left out.

- Choose thank, cheer, bow, salute, applaud, or a random friendly emote.
- Waits at least 15 seconds between thanks and 90 seconds for the same player.
- Skips combat, login buffs, loading screens, and restricted buff data.
- Saves your settings between sessions.
- No libraries required.

## Install

Download the release ZIP. Put the `ThanksForTheBuffForever` folder inside `_classic_beta_/Interface/AddOns`, then restart WoW. Turn off other automatic buff-thanking addons to avoid duplicate emotes.

## Commands

Use `/tftbf` or `/buffthanks` for help.

| Command | What it does |
| --- | --- |
| `/tftbf on` or `/tftbf off` | Enable or disable thanks |
| `/tftbf thank` | Use the thank emote (default) |
| `/tftbf cheer`, `bow`, `salute`, or `applaud` | Choose another emote |
| `/tftbf random` | Pick from the five friendly emotes |
| `/tftbf group on` or `/tftbf group off` | Include or exclude party and raid members |
| `/tftbf status` | Show settings and the last compatibility issue |

## Supported buffs and limits

Tracks familiar class buffs such as Mark of the Wild, Thorns, Arcane Intellect, Power Word: Fortitude, priest prayers, paladin blessings, Unending Breath, Water Walking, and Water Breathing. Names are read in your client's language to recognize other ranks.

The caster must be available through the game's buff data as a nearby player unit. If the game hides their identity, the addon skips the thank. Refreshing an already active buff does not send another thank. New Forever spells are not guaranteed to be recognized.

**This is an early beta port.** Offline Lua 5.1 checks cover filtering, cooldowns, saved settings, and login/combat behavior. Actual Forever buff detection, directed emotes, and restricted-data behavior still need in-game testing. An offline pass does not prove client compatibility.

## Credits and license

Forever port by **Videocat**. Adapted from **Gogo1951's [Thanks for the Buff](https://github.com/Gogo1951/Thanks-for-the-Buff)**, MIT-licensed revision `e1f7164b8006ace5504168e8356db345d6c7703e`. The port retains its class-buff selection and friendly-emote choices, and replaces the combat-log detector with player-aura scanning for the Forever client.

Upstream acknowledges Runew0lf and vbezhenar in its project history. This port uses Gogo1951's MIT-licensed source; no files were taken from Runew0lf's All Rights Reserved distribution.

The original MIT notice is included in [LICENSE](ThanksForTheBuffForever/LICENSE). See [NOTICE.md](ThanksForTheBuffForever/NOTICE.md) for source and license details. This is an independent port, not an official upstream release.
