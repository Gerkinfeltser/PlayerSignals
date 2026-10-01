# PlayerSignals (for SkyrimNet)

A JSON-configurable communication wheel for SkyrimNet. Select a nonverbal intent such as agreement, greeting, or thanks; matching SkyrimNet triggers narrate the authored roleplay action so nearby NPCs can react. No animation playback is required.

## Status

Source implementation and generated PEX/ESP/SEQ artifacts are present. Strict configuration tests and data/artifact checks pass. The external bundle passed the beta26 devkit validator: 25 files, zero errors/warnings/unresolved references/shadows. **Not installed or in-game verified**; event submission, narration, NPC reaction, cancellation, save-load, and rebinding still require the runtime matrix.

- [Specification](docs/specs/player-signals.md): behavior, JSON schema, default 25-intent layout, event/narration contracts, and acceptance criteria.
- [Implementation plan](docs/plans/player-signals.md): build order, Luna delegation, runtime gates, and session continuity.

## Repository Layout

```text
PlayerSignals/             Mod root; symlink this folder into MO2 for testing
PlayerSignals_spriggit/     Authored plugin records (outside the mod root)
docs/specs/                Authoritative feature specification
docs/plans/                Implementation sequence and delegation
build/                     PowerShell build and local compiler flags
tests/                     Raw JSON/schema regressions executed on LuaJIT
```

The mod root contains the standalone ESL-flagged `PlayerSignals.esp`, startup quest SEQ, two Papyrus scripts and compiled PEX files, four default wheels, a JContainers Lua validator, and the `phospheneoverdrive.playersignals` SkyrimNet external bundle with 25 triggers.

## Dependencies

- SKSE
- UIExtensions
- JContainers API 4 / feature 2, including its Lua files and working Lua bridge
- SkyrimNet with the specified mod-event trigger support

Default opening key: Right Alt, configurable through JSON. No MCM layout configuration.

Do not symlink the repository root as the mod: documentation and authoring/build files stay outside `PlayerSignals/`.

SkyrimNet content lives in `PlayerSignals/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/`: `manifest.json` plus `triggers/player_signals_<id>.yaml`. Owner/author is `phospheneoverdrive`; package version is `0.1.0`, with a conservative beta26 target (`min_skyrimnet_version: 0.26.0`). This is not a claim of in-game-tested compatibility. No shipped trigger copies remain in `overlay/`, which is reserved for player/dashboard edits.

## Installation Gate

No MO2 symlink, activation, or ordering changes have been made. Installation requires approval.

1. Register only `PlayerSignals/` as its own MO2 symlink/mod; never the repository root.
2. Enable this mod and `PlayerSignals.esp` with the dependencies loaded.
3. Ensure **stock UIExtensions** `UIWheelMenu.pex` and `wheelmenu.swf` win. The currently enabled Idle Animations Wheel Menu supplies an incompatible loose wheel-script override. Resolve it through an approved profile change; do not copy framework PEX files into PlayerSignals.
4. Start Skyrim through SKSE, then load a save or start a new game. Confirm `phospheneoverdrive.playersignals` appears as an enabled External plugin in SkyrimNet. Check Papyrus `[PlayerSignals]` traces and the SN live event monitor.
5. Exercise the [runtime acceptance matrix](docs/specs/player-signals.md#acceptance-criteria-and-verification), including NPC reactions under enabled SN settings. Compiled artifacts do not establish runtime success.

## Configuration

Edit `SKSE/Plugins/PlayerSignals/layout.json` inside the mod, then load a save. Right Alt defaults to scan code `184`; only keyboard codes `1–255` are supported. No live reload or JSON write-back.

Each wheel has 1–8 ordered slots. Slots are null (disabled), or a nonempty label plus exactly one catalog `intent`, resolved `submenu`, or `control` (`back`/`close`). All wheels, including unreachable ones, are validated; unknown properties, wrong types, broken references, cycles, and oversized wheels disable the feature. Errors identify the file and field/slot where available.

The raw Lua validator preserves strict JSON types: `true`, `184.0`, and `184e0` are not integer key codes. It prevents JContainers metadata/reference-string reinterpretation and preserves case-distinct wheel names through internal canonical IDs. Strings must be valid UTF-8 without NUL characters, which Papyrus cannot represent.

Navigation and cancellation submit no intent. A selected intent is sent once from the player as `PlayerSignals_Intent_<id>` after leaving the wheel loop. There are no retries, animation calls, item transfers, or forced NPC responses.

## Build and Checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v

# Headless external-content validation; does not install or start the game.
& 'D:/Modlists/ASSOS-1.1.1/mods/skyrimnet-devkit-beta26-rc1/tools/content-validate.exe' 'PlayerSignals/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals'
```

`build/build.ps1` accepts `GameRoot`, `ModsRoot`, `UiExtensionsSources`, `FallbackHeaders`, and `Spriggit` paths. It uses repository-owned flags, ordered imports, Spriggit 0.40.0 metadata, and generates SEQ from the authored quest FormID `00000800`; it does not deploy or alter MO2.

The default `UiExtensionsSources` path is the local GamePlugin API declaration fallback. For real framework-source compilation, supply stock UIExtensions source extracted to a temporary external directory. Both feature scripts were compiled against stock BSA source with zero errors/warnings; dependency sources/assets are not bundled. The Python tests execute the shipped raw validator on LuaJIT without emulating Skyrim or the native JContainers bridge.
