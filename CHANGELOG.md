# 0.3.0-beta

- Added configurable overall and per-player thanks cooldowns (0–3600 seconds), applied immediately and saved between sessions.

- Added a comma-separated extra-emote field for Random mode, with client emote/alias validation, deduplication, and saved choices.

- Random emotes now use a saved selection of checked emotes, with at least one required. Random off restores the last single choice.

- Moved all settings into the native AddOns page; /tftbf and /buffthanks open that category directly.

- Added a 10-second Buff back prompt for newly received supported buffs, with recipient identity checks and missing-buff filtering.

- Added a configurable Buff mouseover key-binding entry with missing-buff checks and no target fallback, out of combat only.

- Removed recipient-class and self exclusions from mage buff suggestions; added buff-helper diagnostics to `/tftbf status`.

- Added a small missing-buff spell icon in the selected friendly player's target-frame aura row, with a gold + and click tooltip.
- Matches supported ranks and names; hides while the buff is present, aura data is unreadable, the target is unsuitable, or combat is active.
- Selects learned single-target buffs for mage, priest, druid and paladin with simple class presets.
- Uses the next free aura slot, or the side of the row if occupied; never moves existing auras.
- Explicit clicks only, with a final target and buff check before casting. Existing thanks preferences are preserved.
- Offline checks passed; live casting, placement and combat/taint checks remain pending.

# 0.2.0-beta

- Added a movable settings window with an on/off checkbox and clear status.
- Choose random or a specific friendly emote, and include or exclude group members.
- Open it with /tftbf, /buffthanks, or the game's AddOns settings page.
- GUI and slash commands share saved settings. Existing choices are preserved.
- In-game layout and behavior still need verification.

# 0.1.0-beta

- First independent Forever port from Gogo1951's MIT-licensed TFTB.
- Player-aura detection with restricted-data checks, instead of combat-log events.
- Friendly emote choices, optional group thanks, and persistent settings.
- 15-second overall and 90-second per-player cooldowns.
- Offline checks passed. In-game Forever testing is still pending.
