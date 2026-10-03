# Thanks for the Buff Forever

A small buff-thanking addon for **WoW Forever beta 1.60.1**.

When a nearby player gives you a supported buff, your character uses `/thank` at them. By default, party and raid members are left out.

- Choose thank, cheer, bow, salute, applaud, or a random friendly emote.
- Configurable waits between thanks and for the same player (defaults: 15 and 90 seconds).
- Skips combat, login buffs, loading screens, and restricted buff data.
- Saves your settings between sessions.
- No libraries required.

## Install

Download the release ZIP. Put the `ThanksForTheBuffForever` folder inside `_classic_beta_/Interface/AddOns`, then restart WoW. Turn off other automatic buff-thanking addons to avoid duplicate emotes.

## Commands

Use `/tftbf` or `/buffthanks` to open the addon’s page in WoW’s settings. You can also find it under **Options > AddOns > Thanks for the Buff Forever** to edit the controls directly.

The page has an **Enable automatic thanks** checkbox, a party/raid checkbox, and emote choices including **Random from selected**. Changes save automatically. The addon starts enabled; existing choices are kept.

Use `/tftbf help` for text commands.

| Command | What it does |
| --- | --- |
| `/tftbf on` or `/tftbf off` | Enable or disable thanks |
| `/tftbf thank` | Use the thank emote (default) |
| `/tftbf cheer`, `bow`, `salute`, or `applaud` | Choose another emote |
| `/tftbf random` | Pick only from your checked emotes |
| `/tftbf group on` or `/tftbf group off` | Include or exclude party and raid members |
| `/tftbf status` | Show settings, compatibility issues, and why the buff helper is shown or hidden |

## Supported buffs and limits

### Buff back

When someone gives you a newly detected supported buff, a rounded 36-pixel spell icon appears below the centre of the screen for 10 seconds. Hover to see the recipient and time remaining. Click to cast your suggested buff on that player. It skips players who already have it, unreadable buff data, and unidentified casters. Offers disappear in combat or when leaving the world. A visible offer keeps its recipient until it expires, so another incoming buff cannot switch it under your mouse. This feature is independent of automatic-thanks group filters and the target-frame icon checkbox.

### Click to buff

For a mouseover key, open **Options > Key Bindings**, find **Thanks for the Buff Forever**, and assign **Buff mouseover (out of combat)**. Hover a friendly player or their unit frame and press your key. It uses the same spell selection and skips existing buffs, dead/hostile units, and unreadable buff data. It never falls back to your selected target. The binding works independently of the target-frame icon checkbox; no key is assigned automatically.

Select a friendly player. A rounded, full-colour 36-pixel spell icon appears in the next free slot beside their target-frame buffs when they are missing your suggested buff. Click it once to cast. If the next slot overlaps a real aura, the helper sits just beside the row. It follows the default target frame and compatible skins, including buffs-on-top layouts; replacement unit frames are not supported.

The helper starts enabled and can be turned off with **Show missing buff on target frame** in `/tftbf`. It is independent of automatic thanks and its party/raid filter. It hides and disables its action in combat.

Current presets use learned Classic spell ranks: mage Intellect (all friendly player classes, including yourself), priest Fortitude, druid Mark, and paladin Wisdom for mages/priests/warlocks or Might for other classes, falling back to the other learned blessing. These are simple class presets, not specialization or Forever-build recommendations. Other classes and new Forever-only spells are not supported yet. The helper hides when the player already has the suggested buff, including other supported ranks, and returns after it expires. Unreadable buff data also hides the helper. Normal range, mana, cooldown and spell-rank restrictions still apply.

The icon's actual target-frame placement, casting and combat transitions require testing in the Forever client. Offline checks cannot verify protected casting or rendering.

Tracks familiar class buffs such as Mark of the Wild, Thorns, Arcane Intellect, Power Word: Fortitude, priest prayers, paladin blessings, Unending Breath, Water Walking, and Water Breathing. Names are read in your client's language to recognize other ranks.

The caster must be available through the game's buff data as a nearby player unit. If the game hides their identity, the addon skips the thank. Refreshing an already active buff does not send another thank. New Forever spells are not guaranteed to be recognized.

**This is an early beta port.** Offline Lua 5.1 checks cover filtering, cooldowns, saved settings, and login/combat behavior. Actual Forever buff detection, directed emotes, and restricted-data behavior still need in-game testing. An offline pass does not prove client compatibility.

## Credits and license

Forever port by **Videocat**. Adapted from **Gogo1951's [Thanks for the Buff](https://github.com/Gogo1951/Thanks-for-the-Buff)**, MIT-licensed revision `e1f7164b8006ace5504168e8356db345d6c7703e`. The port retains its class-buff selection and friendly-emote choices, and replaces the combat-log detector with player-aura scanning for the Forever client.

Upstream acknowledges Runew0lf and vbezhenar in its project history. This port uses Gogo1951's MIT-licensed source; no files were taken from Runew0lf's All Rights Reserved distribution.

The original MIT notice is included in [LICENSE](ThanksForTheBuffForever/LICENSE). See [NOTICE.md](ThanksForTheBuffForever/NOTICE.md) for source and license details. This is an independent port, not an official upstream release.

With **Random from selected** enabled, check any combination of Thank, Cheer, Bow, Salute and Applaud. At least one stays selected. Turning Random off restores your last single emote; your random selection is saved for next time.

Use **Extra random emotes (comma-separated)** for additional commands, for example `wave, smile, dance`. Press Enter or click Save; slashes are added automatically. These are added to checked emotes while Random is enabled. Duplicates are counted once, unknown commands are rejected, and a blank field clears the extras.

**Thanks cooldowns:** set the overall and per-player waits in seconds (0–3600; 0 disables that wait). Press Enter or click outside the field to save. Changes apply immediately, including to existing cooldowns.

Delay before thanks waits after receiving a buff before sending the emote (default 2 seconds, 0 sends immediately). The two cooldowns separately limit repeat thanks. Pending thanks are cancelled when disabled, entering combat, leaving the world, or changing the delay.

Delayed thanks rechecks the caster's identity across available target, focus, mouseover, group and nameplate units. If the caster is no longer available, it skips the emote. `/tftbf status` now includes the configured delay, last detection result, thanks result and last buff-back check to help diagnose missed buffs.
