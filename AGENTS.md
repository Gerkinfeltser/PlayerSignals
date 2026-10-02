# Repository Guidelines

## Project overview

PlayerSignals is a JSON-configurable, nonverbal communication wheel for SkyrimNet. Its 25 shipped default intent descriptions are direct narration, not animation playback or forced NPC compliance; the validated JSON registry can define additional IDs. Read [README.md](README.md) first; [docs/specs/player-signals.md](docs/specs/player-signals.md) is authoritative for behavior/interfaces, and [docs/plans/player-signals.md](docs/plans/player-signals.md) separates active work from historical evidence. Do not treat planned behavior, old logs, or generated artifacts as current runtime proof.

## Architecture and data flow

- A standalone ESL-flagged quest attaches `PlayerSignals_Controller` and a forced player alias with `PlayerSignals_PlayerAlias`. Alias `OnInit`/`OnPlayerLoadGame` schedule delayed maintenance; do not move save-load handling onto the quest.

- The stable startup quest/SEQ and alias `OnInit`/`OnPlayerLoadGame` path are designed to initialize new and existing saves. The current existing-save install/update path remains in-game-unverified. This cutover adds no saved controller fields, alias/quest/FormID changes, or property-default changes; it rebuilds private native maps from both JSON files at load.
- Startup requires loaded `SkyrimNet.esp` and nonempty `SkyrimNetApi.GetBuildVersion()`. Maintenance invalidates old session/target state, removes the old key binding, and invokes `jrequire('PlayerSignals.config')` through JContainers' Lua bridge. Lua reads `Data/SKSE/Plugins/PlayerSignals/layout.json` and its sibling `intents.json`, validates the layout and entire JSON-defined registry, and constructs native JMap/JArray containers.
- The configured key (default Right Alt, scan code `184`) starts one guarded session. Capture the crosshair NPC before opening the wheel; keep that capture fixed through browsing. `Browse` uses an iterative history stack for submenu/Back navigation.
- Immediately after `Browse` returns a final accepted intent, sample Shift scan codes `42` and `54` before feedback/catalog lookups. Either held key overrides targeting to everyone. No captured NPC also means group mode. Without an override, the captured actor must still be alive, enabled, and 3D-loaded at submission or fail closed.
- Targeted submission is one `SkyrimNetApi.DirectNarration(text, respondingNPC, player)` call. The captured NPC is the responder/originator context, the player is listener, and narration text still describes the player as the gesture actor. Group submission is one `SkyrimNetApi.DirectNarration(text, player, None)` call with text explicitly addressing everyone nearby. Nearby witnesses may join; no reply/compliance is guaranteed.
- `intents.json` defines the dynamically validated registry and its `narration`, group `notification`, and `targetedNotification` phrases. Lua builds native `narrations`, `notifications`, `targetNotificationPrefixes`, and `targetNotificationSuffixes` maps from that file; no hardcoded phrase/ID catalog remains in Lua. Phrase values omit the player prefix/final period; the sole literal `{target}` appears exactly once in `targetedNotification`. One local player-named `Debug.Notification` is permitted only when DirectNarration returns `0`; group feedback omits the recipient, targeted feedback uses the captured recipient's name, and failures/stale stacks stay silent. Never restore a mod-event, trigger, or alternate narration submission path.
- The optional `SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/` bundle contains only a manifest and `prompts/agent_playersignals_intent_helper.prompt`. It inherits the base agent and drafts JSON from pasted files; standard SkyrimNet agent tools have no general filesystem access or PlayerSignals schema validator. Never claim automatic editing or actual Lua/game validation. This bundle does not own wheel dispatch and must not regain triggers/actions.

## Key directories

| Path | Editing/deployment boundary |
|---|---|
| `PlayerSignals/` | Actual mod root; only this child folder may be installed/symlinked into MO2. |
| `PlayerSignals/Source/Scripts/` | Authored Papyrus controller/alias; generated PEX goes in `PlayerSignals/Scripts/`. |
| `PlayerSignals/SKSE/Plugins/` | Runtime layout and JContainers Lua module/catalog. |
| `PlayerSignals_spriggit/` | Authored plugin records; keep outside the mod payload. |
| `build/`, `tests/`, `docs/` | Repository-only tooling, regressions, and contracts/evidence. |

## Development commands

Run from the repository root:

```powershell
# Compile both scripts, build ESP, and regenerate SEQ; does not deploy.
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1

# Development-only test dependency and raw-validator suite.
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```

Build import order: feature source → SKSE → JContainers → installed `SkyrimNet/Source/Scripts` → full vanilla → stock UIExtensions source when supplied → fallback API declarations. The SkyrimNet script source is a build input, not distributed with the mod.

No dedicated lint/formatter command is configured. Running the mod means launching Skyrim through SKSE in an approved MO2 profile, not invoking a repository dev server. Profile/symlink/plugin activation and load-order changes require explicit approval.

## Code conventions and common patterns

- Follow existing four-space Papyrus/Lua/Python indentation. Prefix scripts with `PlayerSignals_`; intent IDs are exact lowercase catalog IDs. JSON labels never determine intent identity.
- Keep controller state private. Preserve generation/readiness/re-entry guards. External Papyrus calls can yield: recheck generation around registration/menu calls, publish readiness without intervening external calls, and resolve/capture player identity before the final dispatch guard.
- Retain the config root with tag `PlayerSignals`; borrowed child handles are not separately released. A session retains its config across latent `OpenMenu` and releases config/history on exit. Do not discard ownership or call release natives when JContainers is unavailable.
- JSON labels are plain user-authored text. Lua appends ` >` for submenus and ` <` for Back once when building the native config; Papyrus uses that label for both option text and hover caption. Do not duplicate markers, change action IDs for label edits, truncate custom labels, or infer a hard character limit.
- Raw Lua validation is authoritative; do not replace it with `JValue.readFromFile`, which normalizes booleans and special strings. Preserve strict integer tokens, exact references, UTF-8, action exclusivity, all-wheel validation, and cycle rejection. Canonical internal wheel keys avoid native case-insensitive name collisions.
- The editable JSON catalog owns intent IDs and all three phrases; do not reintroduce source tables or a fixed 25-ID Lua registry. IDs are lowercase ASCII matching `[a-z][a-z0-9_]*`; all three strings are required/nonempty and omit the player prefix/final period. Only `targetedNotification` contains exactly one literal `{target}`. Plain JSON comments/trailing commas are invalid. Both files apply on save load; adding IDs or changing phrases requires JSON edits, not Lua/Papyrus edits or recompilation. Reject malformed authored phrases rather than passing literal markers or doubled punctuation through.
- Target validity is checked at submission: alive, enabled, and 3D-loaded. Shift 42/54 is sampled immediately after final accepted `Browse` return, before feedback/catalog lookups. An invalid captured target fails closed unless Shift overrides it; it never silently redirects.
- Errors fail closed: no guessed defaults, truncation, retries, or second narration path. Use `[PlayerSignals]` traces and actionable notifications. Lua uses `pcall` to return load errors; PowerShell throws on failed build steps.
- Navigation/cancellation emit no narration. Treat `-1`, `255`, out-of-range results, and disabled slots as exit-only. Never call player-control enable/disable APIs or animation APIs.

## Important files

- `PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc`: lifecycle, ownership, input, crosshair capture, navigation, direct narration.
- `PlayerSignals/Source/Scripts/PlayerSignals_PlayerAlias.psc`: startup/save-load entry events.
- `PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua`: raw parser, layout/catalog validation, native map construction; no editable catalog.
- `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json`: shipped four-wheel layout; reload on save load, never write back.
- `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json`: shipped default phrase catalog and dynamically validated intent-ID registry; reload on save load, never write back.
- `PlayerSignals_spriggit/spriggit-meta.json` and `Quests/PlayerSignals_Quest - 000800_PlayerSignals.esp.yaml`: pinned serialization package and startup attachments/FormID.
- `build/build.ps1`, `build/TESV_Papyrus_Flags.flg`: absolute flags, ordered imports, ESP/SEQ generation.
- Installed SkyrimNet script declarations are a build input for the API; do not copy framework declarations or assets into the mod root.

## Runtime and tooling preferences

Use Windows PowerShell, the installed Papyrus compiler, and Spriggit `Spriggit.Yaml.Skyrim` **0.40.0**. Preserve import order: feature source → SKSE → JContainers → installed SkyrimNet scripts → full vanilla → UIExtensions → fallback headers. Stub headers must not shadow full vanilla declarations. Generate SEQ from the authored quest FormID, not a runtime load-order-prefixed ID.

Runtime dependencies are SKSE64, stock-compatible UIExtensions, JContainers API 4/feature 2 including Lua support, and SkyrimNet with `SkyrimNet.esp`, `GetBuildVersion()`, and `DirectNarration` available. Do not bundle dependency PEX/SWF/source or copy the animation-wheel mod. No MO2 changes are authorized by this document.

Backups are recommended before install/update. Do not claim a guaranteed clean mid-playthrough uninstall: saves can retain quest/script state, and no shutdown/uninstall cleaner exists. Direct users to the spec/player-guide rollback guidance. SkyrimNet's separately stored narration history may remain after Skyrim save rollback.

## Testing and QA

`tests/test_config.py` uses standard-library `unittest` and Lupa's LuaJIT to exercise the shipped raw Lua validators, not a Python rewrite. Cover observable boundaries for both layout and catalog schemas: types/ranges, null-slot positions, action exclusivity, unknown fields/IDs, missing or malformed phrase records, target-marker count/location, terminal periods (including before trailing ASCII whitespace), broken references, unreachable cycles, deep valid graphs, case-distinct names, and Unicode/JSON errors. No coverage-percentage gate is configured.

For feature changes, compile against real declarations, inspect generated PEX/ESP/SEQ and attachments, and audit both JSON files, Lua maps, and dispatch together. Direct-narration checks must cover targeted arguments, captured-recipient notification wording, invalid-target fail-closed behavior, Shift/no-target group paths without the discarded name, exact authored actor/text meaning, one API call, return-`0` notification gating, stale stacks, cancellation, and startup API readiness.

The Python suite does **not** exercise Papyrus, the installed native Lua bridge, UIExtensions, SkyrimNet, direct-narration processing, or NPC reactions. Complete the spec's in-game matrix separately. A local notification/API return does not prove NPC speech or compliance; report only checks actually exercised and never claim runtime acceptance from compilation or file presence.
