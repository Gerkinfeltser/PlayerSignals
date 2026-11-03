# Repository Guidelines

## Project overview

PlayerSignals is a JSON-configurable, nonverbal communication wheel for SkyrimNet. Its 24 shipped intent descriptions are direct narration; two shipped hybrid signals also request an eligible target-NPC action and describe compliance only when the action API reports success. They do not prove in-game effect or force NPC responses. The validated JSON registry can define additional IDs. Read [README.md](README.md) first. Internal documentation lives outside this repository at `D:/gerkgit/GerkinStuff/projects/Skyrim/PlayerSignals/docs-dev/`: `specs/player-signals.md` is authoritative for behavior/interfaces, and `plans/player-signals.md` separates active work from historical evidence. Keep internal docs there; do not recreate a repository `docs/` directory. Do not treat planned behavior, old logs, or generated artifacts as current runtime proof.

## Architecture and data flow

- A standalone ESL-flagged quest attaches `PlayerSignals_Controller` and a forced player alias with `PlayerSignals_PlayerAlias`. Alias `OnInit`/`OnPlayerLoadGame` schedule delayed maintenance; do not move save-load handling onto the quest.

- The stable startup quest/SEQ and alias events are designed for new/existing saves; current install/update remains in-game-unverified. Pad support adds private binding/held state reset during maintenance, not quest/FormID/property-default changes. Lua rebuilds native maps from both JSON files on load.
- Startup requires loaded `SkyrimNet.esp`, nonempty `SkyrimNetApi.GetBuildVersion()`, JContainers Lua and ready Magelight. Maintenance invalidates old session/target state, removes old keyboard/pad bindings and invokes `jrequire('PlayerSignals.config')`. Lua validates both sibling layout/catalog JSON files and constructs native containers.
- `UseMagelight()` returns True: Magelight is the enabled twelve-slice renderer. The dormant UIExtensions branch is not a runtime fallback. Capture the crosshair NPC before opening and keep it fixed through iterative submenu/Back browsing. Default opening key is Right Alt 184; optional `input.openGamepadButton` 266–281 is absent by default.
- Signal cores target the capture; tips select Openly. Immediately after final `Browse` return sample Shift 42/54 before catalog/feedback lookups. Either Shift, explicit Openly (including pad X), or no capture means group mode. Otherwise the capture must still be alive/enabled/3D-loaded or fail closed. Shift+hub (pad X+A) uses the current wheel's Back slot when present; otherwise the hub cancels.
- Ordinary targeted signals submit one `DirectNarration(text, recipient, player)`; Openly remains `DirectNarration(text, player, None)`. NPC-origin targeted narration makes the captured NPC the speaker instead of leaving normal responder selection to choose a bystander; history/dashboard therefore labels it From NPC, To player although the text names the player as actor, with possible odd recent-event/memory attribution to watch. Hybrids run their action first only for targeted selections; only action result 0 permits compliance narration. Failure/refusal sends the plain signal if target/session remain valid. Openly skips the action. Pure actions are target-only, no direct narration or Shift conversion; action+event+intent remains legacy action context. No reply, in-game effect or compliance is guaranteed by API acceptance.
- `intents.json` defines the dynamically validated registry and its `narration`, group `notification`, and `targetedNotification` phrases, plus optional `complianceNarration` required when a layout hybrid references that intent. Lua builds native phrase maps from that file. Ordinary phrase values omit the player prefix/final period; `targetedNotification` contains exactly one literal `{target}`. Compliance templates contain one or more `{target}`, optional `{player}`, no other/malformed/nested/unbalanced markers, and no terminal period including trailing whitespace. Safe one-pass substitution prevents actor names containing braces from being reinterpreted. One local player-named `Debug.Notification` is permitted only when DirectNarration returns `0`; group feedback omits the recipient, targeted feedback uses the captured recipient's name, and failures/stale stacks stay silent. Never restore a mod-event, trigger, or alternate narration submission path.
- The optional `SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/` bundle contains only a manifest and `prompts/agent_playersignals_intent_helper.prompt`. It inherits the base agent and drafts JSON from pasted files; standard SkyrimNet agent tools have no general filesystem access or PlayerSignals schema validator. Never claim automatic editing or actual Lua/game validation. This bundle does not own wheel dispatch and must not regain triggers/actions.
- Hotkey slots are non-narration dispatches: ordinary slots use SKSE `Input.HoldKey`/`Input.ReleaseKey`; `raw: true` keyboard slots use only `PlayerSignals_Native.SendRawKey(scanCode, holdMs)` after the wheel closes and Skyrim is foreground. Check `SKSE.GetPluginVersion("PlayerSignals")` before either PlayerSignals native; require `GetNativeVersion() == 1` before sending. Never call an unbound native or fall back to HoldKey for raw slots. No animation or player-control APIs.

## Key directories

| Path | Editing/deployment boundary |
|---|---|
| `PlayerSignals/` | Actual mod root; only this child folder may be installed/symlinked into MO2. |
| `PlayerSignals_native/` | Native SKSE project sources/build files, inside this repository but outside the mod payload; output DLL belongs in `PlayerSignals/SKSE/Plugins/`. |
| `PlayerSignals/Source/Scripts/` | Authored Papyrus controller/alias; generated PEX goes in `PlayerSignals/Scripts/`. |
| `PlayerSignals/SKSE/Plugins/` | Runtime layout and JContainers Lua module/catalog. |
| `PlayerSignals_spriggit/` | Authored plugin records; keep outside the mod payload. |
| `build/`, `tests/` | Repository-only tooling and regressions; internal contracts/evidence live in the external `docs-dev/` folder above. |

## Development commands

Run from the repository root:

```powershell
# Compile all three scripts, build ESP/SEQ; rebuild native DLL if missing/stale. No deployment.
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1
# Force the native step: add -Native to the build command.

# Development-only test dependency and raw-validator suite.
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```

Build import order: feature source → SKSE → JContainers → installed `SkyrimNet/Source/Scripts` → full vanilla → Magelight → UIExtensions declarations → fallback API declarations. The dormant UIExtensions branch still needs compile declarations, not a runtime installation. SkyrimNet script source is a build input, not distributed with the mod.

No dedicated lint/formatter command is configured. Running the mod means launching Skyrim through SKSE in an approved MO2 profile, not invoking a repository dev server. Profile/symlink/plugin activation and load-order changes require explicit approval.

## Code conventions and common patterns

- Follow existing four-space Papyrus/Lua/Python indentation. Prefix scripts with `PlayerSignals_`; intent IDs are exact lowercase catalog IDs. JSON labels never determine intent identity.
- Keep controller state private. Preserve generation/readiness/re-entry guards. External Papyrus calls can yield: recheck generation around registration/menu calls, publish readiness without intervening external calls, and resolve/capture player identity before the final dispatch guard.
- Retain the config root with tag `PlayerSignals`; borrowed children are not separately released. A session retains its config across latent browsing and releases config/history on exit. Do not discard ownership or call release natives when JContainers is unavailable.
- Labels are user-authored text, not intent identity. Lua appends ` >` for submenus and ` <` for Back once; Magelight strips exactly that generated terminal suffix for display. Never duplicate markers, truncate custom labels or infer a hard character limit. Wheels have 1–12 positions; themes are slate/moss/ember and optional slot colour is six-digit `#rrggbb`.
- Raw Lua validation is authoritative. A slot has one primary kind; only an intent slot may additionally carry an action (hybrid), and hybrids cannot carry events. An action+event+intent slot remains a legacy pure action/event context, not a hybrid. Preserve strict integer tokens, exact references, UTF-8, all-wheel validation, and cycle rejection. Canonical internal wheel keys avoid native case-insensitive name collisions.
- The editable JSON catalog owns intent IDs and phrases; do not reintroduce source tables or a fixed-ID Lua registry. IDs are lowercase ASCII matching `[a-z][a-z0-9_]*`; required phrase strings are nonempty and omit the player prefix/final period. Of the three required phrases, only `targetedNotification` contains exactly one literal `{target}`; the optional compliance template follows the marker rules above. Reject malformed authored phrases rather than passing literal markers or doubled punctuation through.
- Target validity is checked at submission: alive, enabled, and 3D-loaded. Shift 42/54 is sampled immediately after final accepted `Browse` return, before feedback/catalog lookups. An invalid captured target fails closed unless Openly is chosen (Shift, the Openly tip, or gamepad X); it never silently redirects.
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
- `PlayerSignals/Magelight/PlayerSignals/manifest.json` and `index.html`: release metadata, active wheel renderer, target/Openly regions, keyboard/pad input and availability-based hint grid.
- Installed SkyrimNet script declarations are a build input for the API; do not copy framework declarations or assets into the mod root.

## Runtime and tooling preferences

Use Windows PowerShell, the installed Papyrus compiler and Spriggit `Spriggit.Yaml.Skyrim` **0.40.0**. Preserve the import order above; stub headers must not shadow full vanilla declarations. Generate SEQ from authored quest FormID, not a load-order-prefixed ID.

Runtime dependencies for the shipped layout: matching SE/AE/VR SKSE/dependency builds, Magelight **1.7.1+** with its matching runtime, JContainers API 4/feature 2 with Lua, and SkyrimNet with direct narration/action APIs. The older manifest/Papyrus host threshold 0.31.2 is not full gamepad compatibility. UIExtensions is superseded as renderer, not a runtime requirement. Shipped raw dashboard additionally requires bundled `PlayerSignals.dll` API 1 and Address Library (VR Address Library on VR); custom layouts without raw slots need neither. Native package version 1.0.0 and native API 1 are independent of mod release 0.2.0. SE/AE/VR build flags do not prove runtime acceptance.

Raw-slot runtime status: Skyrim 1.6.1170 owner-verified in the spike only, not this production DLL; 1.7.104 needs production in-game testing; Skyrim 1.5.97 and VR are build-only, untested.

Backups are recommended before install/update. Do not claim a guaranteed clean mid-playthrough uninstall: saves can retain quest/script state, and no shutdown/uninstall cleaner exists. Direct users to the spec/player-guide rollback guidance. SkyrimNet's separately stored narration history may remain after Skyrim save rollback.

## Testing and QA

`tests/test_config.py` uses standard-library `unittest` and Lupa's LuaJIT to exercise the shipped raw Lua validators, not a Python rewrite. Cover observable boundaries for both layout and catalog schemas: types/ranges, null-slot positions, allowed hybrid combination and rejected combinations, unknown fields/IDs, missing/malformed phrase records, compliance-template markers and terminal periods, target-marker count/location, trailing ASCII whitespace, broken references, unreachable cycles, deep valid graphs, case-distinct names, and Unicode/JSON errors. No coverage-percentage gate is configured.

For feature changes, compile against real declarations, inspect generated PEX/ESP/SEQ and attachments, and audit both JSON files, Lua maps, and dispatch together. Direct-narration checks must cover targeted arguments, captured-recipient notification wording, invalid-target fail-closed behavior, Shift/no-target group paths without the discarded name, exact authored actor/text meaning, one API call, return-`0` notification gating, stale stacks, cancellation, and startup API readiness. For hybrids, in-game owner checks must cover all three actions (eligible targeted success, refused/failed targeted plain signal, and Openly with action skipped), plus invalid target, stale session and cancellation; observe exactly one action and one narration on success. API return `0` is acceptance evidence, not proof of runtime effect or NPC compliance.

The Python suite does **not** exercise Papyrus, installed native Lua/Magelight bridges, UIExtensions dormant code, SkyrimNet processing or NPC reactions. Complete the spec's pending in-game matrix separately, including stick/A/B/X, optional pad open/cancel binding, connect/disconnect hint grid, themes/colours and raw foreground behavior. A browser harness or local notification/API return is not production runtime acceptance.
