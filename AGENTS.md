# Repository Guidelines

## Project Overview

PlayerSignals is a JSON-configurable nonverbal communication wheel for SkyrimNet. Its 25 predefined intents produce authored narration, not animation playback or forced NPC compliance. No MCM, custom DLL, item-transfer, targeting, or arbitrary JSON narration feature is in scope.

Read [README.md](README.md) first. [docs/specs/player-signals.md](docs/specs/player-signals.md) is authoritative for behavior/interfaces; update it before changing contracts. [docs/plans/player-signals.md](docs/plans/player-signals.md) records sequencing, delegation, evidence, and remaining runtime gates. Do not treat planned behavior or generated artifacts as runtime proof.

## Architecture & Data Flow

- A standalone ESL-flagged quest attaches `PlayerSignals_Controller` and a forced player alias with `PlayerSignals_PlayerAlias`. Alias `OnInit`/`OnPlayerLoadGame` schedule delayed maintenance; do not move save-load handling onto the quest.
- Maintenance invalidates the current generation, removes the old key binding, and invokes `jrequire('PlayerSignals.config')` through JContainers' Lua bridge. Lua reads `Data/SKSE/Plugins/PlayerSignals/layout.json`, validates the entire schema/graph, and constructs native JMap/JArray containers. Papyrus checks the typed boundary and publishes readiness.
- The configured key (default Right Alt, scan code `184`) starts one guarded session. `Browse` explicitly initializes all eight UIExtensions slots and uses an iterative history stack for submenu/Back navigation.
- An accepted intent exits the loop, then the **player** sends `PlayerSignals_Intent_<intent_id>` via three-argument `SendModEvent`. Matching SkyrimNet YAML filters `mod_event` by event name and player sender `00000014`, then uses `{{ originator }}` in direct narration. Submission, narration, and NPC speech are separate evidence layers.

## Key Directories

| Path | Editing/deployment boundary |
|---|---|
| `PlayerSignals/` | Actual mod root; only this child folder may be symlinked into MO2. |
| `PlayerSignals/Source/Scripts/` | Authored Papyrus controller/alias; generated PEX goes in `PlayerSignals/Scripts/`. |
| `PlayerSignals/SKSE/Plugins/` | Runtime layout, JContainers Lua module, and SkyrimNet external trigger bundle. |
| `PlayerSignals_spriggit/` | Authored plugin records; keep outside the mod payload. |
| `build/`, `tests/`, `docs/` | Repository-only tooling, regression tests, and contracts/evidence. |

## Development Commands

Run from the repository root:

```powershell
# Compile both scripts, build ESP, and regenerate SEQ; does not deploy.
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1

# Development-only test dependency and raw-validator suite.
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```

Build parameters: `GameRoot`, `ModsRoot`, `UiExtensionsSources`, `FallbackHeaders`, `Spriggit`. Defaults use local `D:/Modlists/ADT` and `D:/git` paths; verify availability rather than inventing portable paths. Supply `-UiExtensionsSources` with stock framework source extracted to a temporary external directory for real-source compilation; the default is API-declaration fallback.

For a packaged SkyrimNet plugin, run `& .\tools\content-validate.exe $PluginDir` from the devkit directory below; `$PluginDir` must contain its manifest and content roots, not just loose overlay triggers. The tool is headless; its CLI accepts `--base-tree`, `--report`, and rendering/context options. `content-convert.exe` is for legacy migration, not validation.

No dedicated lint/formatter command is configured. Running the mod means launching Skyrim through SKSE in an approved MO2 profile, not invoking a repository dev server. Profile/symlink/plugin activation and load-order changes require explicit approval.

## Code Conventions & Common Patterns

- Follow existing four-space Papyrus/Lua/Python indentation and YAML nesting. Prefix scripts with `PlayerSignals_`; intent IDs are exact lowercase catalog IDs. JSON labels never determine event identity.
- Keep controller state private. Preserve `_generation`, `_ready`, `_browsing`, `_held`, and `_maintaining` guards. External Papyrus calls can yield: recheck generation around registration/menu calls; publish readiness without intervening external calls; resolve the player before the final dispatch guard.
- Retain the config root with tag `PlayerSignals`; borrowed child handles are not separately released. A session retains its config across latent `OpenMenu` and releases config/history on exit. Do not discard ownership or call release natives when JContainers is unavailable.
- Raw Lua validation is authoritative; do not replace it with `JValue.readFromFile`, which normalizes booleans and special strings. Preserve strict integer tokens, exact references, UTF-8, action exclusivity, all-wheel validation, and cycle rejection. Canonical internal wheel keys avoid native case-insensitive name collisions.
- Errors fail closed: no guessed defaults, truncation, retries, or second narration path. Use `[PlayerSignals]` traces and actionable notifications. Lua uses `pcall` to return load errors; PowerShell throws on failed build steps.
- Navigation/cancellation emit no intent. Treat `-1`, `255`, out-of-range results, and disabled slots as exit-only. Never call player-control enable/disable APIs or animation APIs.

## Important Files

- `PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc`: lifecycle, ownership, input, navigation, dispatch.
- `PlayerSignals/Source/Scripts/PlayerSignals_PlayerAlias.psc`: startup/save-load entry events.
- `PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua`: raw parser, schema validation, native graph construction.
- `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json`: shipped four-wheel layout; reload on save load, never write back.
- `PlayerSignals/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/`: `manifest.json` and 25 `triggers/player_signals_<id>.yaml` definitions. Keep one authored copy per intent; no shipped overlay duplicates.
- `PlayerSignals_spriggit/spriggit-meta.json` and `Quests/PlayerSignals_Quest - 000800_PlayerSignals.esp.yaml`: pinned serialization package and startup attachments/FormID.
- `build/build.ps1`, `build/TESV_Papyrus_Flags.flg`: absolute flags, ordered imports, ESP/SEQ generation.
- `D:/Modlists/ASSOS-1.1.1/mods/skyrimnet-devkit-beta26-rc1`: supplied SkyrimNet integration reference/toolkit. Consult `docs/modding/CONTENT_ROOTS.md`, `MIGRATING_TO_BETA25.md`, and the trigger/integration workflows; do not ship the devkit in the mod.
- `D:/gerkgit/SkyrimNet_iActions_dev/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.iactions/manifest.json`: verified external-package example. Reuse its layout convention, not its unrelated actions/prompts or dependencies. Its repository root is its mod root; this project's remains `PlayerSignals/`.

## Runtime/Tooling Preferences

Use Windows PowerShell, the installed Papyrus compiler, and Spriggit `Spriggit.Yaml.Skyrim` **0.40.0**. Preserve import order: feature source → SKSE → JContainers → full vanilla → UIExtensions → fallback headers. Stub headers must not shadow full vanilla declarations. Generate SEQ from the authored quest FormID, not a runtime load-order-prefixed ID.

SkyrimNet content owner is **`phospheneoverdrive`**, not `gerkinfeltser`; do not infer namespace ownership from the GitHub account or existing ESP author metadata. Distributed content belongs under `SKSE/Plugins/SkyrimNet/external/{author}.{slug}/` relative to the mod root, with `manifest.json` and content roots such as `triggers/`. PlayerSignals uses `phospheneoverdrive.playersignals`; folder name and manifest `id` must match exactly. IDs are lowercase and manifest `version` is strict semver. The current `0.1.0` manifest targets `min_skyrimnet_version: 0.26.0`; record actual tested compatibility separately rather than treating the declared target as runtime proof. Trigger `name` must match its filename stem.

`overlay/` is for player/dashboard edits and outranks plugin content; do not ship into SkyrimNet-managed `library/`. The authored payload is now external: preserve all 25 definitions and the manifest together, validate changes with the supplied devkit, and never retain duplicate overlay copies. Packaging changes do not authorize MO2 changes.

Runtime dependencies are SKSE64, stock-compatible UIExtensions, JContainers API 4/feature 2 including Lua support, and SkyrimNet with the specified trigger contract. Do not bundle dependency PEX/SWF/source or copy the animation-wheel mod. The recorded profile has an incompatible loose `UIWheelMenu.pex` override; stock script/SWF winners must be verified before game QA. User chose to leave MO2 unchanged; this document grants no activation permission.

For plan-defined independent slices, use explicitly selected Luna when requested; do not label generic scout jobs as Luna. Parallelize frozen-contract layout/trigger work, keep controller/plugin/integration ownership centralized, and run integrated checks after delegated edits settle.

## Testing & QA

`tests/test_config.py` uses standard-library `unittest` and Lupa's LuaJIT 2.1 to execute the shipped `validateText`, not a Python rewrite. Cover observable schema boundaries: types/ranges, null-slot positions, action exclusivity, unknown fields/IDs, broken references, unreachable cycles, deep valid graphs, case-distinct names, and Unicode/JSON errors. No coverage-percentage gate is configured.

For feature changes, compile against real declarations, inspect generated PEX/ESP/SEQ and attachments, and audit layout/trigger contracts together. Permanent tests must catch consumer-visible behavior; use throwaway checks for wiring/source-text audits.

The Python suite does **not** exercise Papyrus, the installed native Lua bridge, UIExtensions, or SkyrimNet reactions. Complete the spec's in-game matrix separately: selection/cancel/Back, stale sessions, save-load/rebinding, malformed config, event monitor, NPC reactions, and input restoration. `mod_event` is ephemeral; persisted history is insufficient. Record unavailable prerequisites explicitly and never claim runtime acceptance from compilation or file presence.
