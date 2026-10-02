# PlayerSignals (for SkyrimNet)

PlayerSignals is a small configurable communication wheel for Skyrim. Pick one of 25 shipped nonverbal gesture defaults—or add a supported intent through the editable JSON catalog—and send its authored description to SkyrimNet as direct narration. A local notification confirms successful submission, with targeted wording for a captured recipient. It never plays an animation or forces requested NPC actions. SkyrimNet handles dialogue; a reply or compliance is not guaranteed.

## Status

Current scoped proof: Lua+JSON loader and source-derived `OnKeyDown`/`Submit` smokes passed, all 25 shipped narration/group-notification phrases matched their prior defaults, and both Papyrus scripts compiled with 0 errors/warnings. All 15 unittests passed in a separate run. **The full build did not succeed:** Spriggit could not move the unchanged ESP because the file was locked; a separate temporary deserialize confirmed the generated ESP matched the existing file and the SEQ was unchanged, but this is not full-build success. No live-game proof: physical Shift timing, in-game notifications, Papyrus VM/native/UI/Flash behavior, and uninstall remain unverified. See the [plan](docs/plans/player-signals.md) for evidence and limits.

- [Specification](docs/specs/player-signals.md): behavior, JSON schemas, 25 shipped narration/group-notification defaults, dynamic registry, targeting contract, and acceptance criteria.
- [Player guide](PlayerSignals/PlayerSignals-README.md): friendly setup, wheel customization, targeting, and troubleshooting; this file is inside the packaged mod root.
- [Implementation plan](docs/plans/player-signals.md): active direct-API cutover and separately labeled historical evidence.

## Repository layout

```text
PlayerSignals/              Mod root; only this child folder belongs in MO2
PlayerSignals_spriggit/      Authored plugin records (outside the mod root)
docs/specs/                  Authoritative feature contract
docs/plans/                  Active work and historical evidence
build/                       PowerShell build and local compiler flags
tests/                       Raw JSON/schema regressions executed on LuaJIT
```

The mod root contains `PlayerSignals.esp`, startup quest SEQ, two Papyrus scripts and compiled PEX files, four default wheels, sibling layout and intent JSON, and a JContainers Lua loader. An optional prompt-only SkyrimNet bundle supplies the WebUI agent `playersignals_intent_helper`; it generates JSON for users to save from pasted configuration, not automatic file edits. Wheel dispatch does not depend on its manifest or external bundle, and no YAML triggers/actions are shipped. The inherited agent rendered against installed base content with zero validation findings; live WebUI discovery/model behavior remain unverified.

## Dependencies and targeting

Required: SKSE, UIExtensions, JContainers API 4 / feature 2 with working Lua support, and SkyrimNet. Startup requires `SkyrimNet.esp` loaded and a nonempty `SkyrimNetApi.GetBuildVersion()`.

Before the wheel opens, PlayerSignals captures the current crosshair NPC. If a valid NPC remains captured when you select a gesture, SkyrimNet receives targeted direct narration with that captured NPC as responder and you as listener; the narration still describes your character as the gesture actor. Moving the crosshair after opening does not change the recipient. The captured NPC must remain alive, enabled, and 3D-loaded when submitting or the selection fails closed.

No NPC captured means the gesture is addressed to everyone nearby. Holding either Shift (scan code 42 or 54) through selection overrides a captured target; Shift is sampled immediately after the wheel returns an accepted intent, not at the exact click instant. The group narration explicitly says it is addressed to everyone nearby. Nearby witnesses may join, but nobody is guaranteed to reply. An invalid captured target is not silently redirected to a different NPC or to group mode.

Each accepted selection makes one `SkyrimNetApi.DirectNarration` call. A local player-named notification appears only if the API returns `0`; group wording omits the recipient, while targeted wording uses the name captured before the wheel opened. Either Shift key forces group feedback without the discarded name. This is a submission receipt, not proof of SkyrimNet delivery or an NPC response. Navigation, cancellation, stale selections, invalid targets, and unsuccessful calls stay silent.

No animation playback, item transfer, or forced NPC action is performed.

## Installation and first use

Before installing or updating, back up your save. Install the **`PlayerSignals/` child folder** as its own mod in MO2—not the repository root—and enable `PlayerSignals.esp`. Install and enable the dependencies above. Do not install or activate an old PlayerSignals trigger bundle; direct narration uses SkyrimNet's native API.

Launch through SKSE and load a save or start a new game. If SkyrimNet.esp or the native API build version is missing, PlayerSignals will not enable. In normal gameplay, press **Right Alt** to open the wheel and choose a gesture. A local notification confirms the API accepted the submission; SkyrimNet decides whether NPCs speak.

See the [player guide](PlayerSignals/PlayerSignals-README.md) for a quick walkthrough and examples.

### Existing saves, updates, and removal

Back up your save before installing or updating. The stable startup quest/SEQ and player alias `OnInit`/`OnPlayerLoadGame` path are designed to initialize on existing saves. This cutover adds no saved controller fields, changes no property defaults, aliases, quest/FormIDs, or startup SEQ, and rebuilds its private native maps from both JSON files through Lua on load. Existing-save support is by design, but the current install/update path has not been tested in-game.

PlayerSignals does not add gesture spells, edit NPC world records, or toggle player controls. Saves may still retain quest/script state, and the mod has no shutdown/uninstall cleaner. This does not mean removal is necessarily unsafe; it means a clean mid-playthrough removal is not guaranteed. The safest save-state rollback is to restore a backup from before installation, then remove the mod. SkyrimNet may retain narration history separately; restoring a Skyrim save does not erase it.

## Configuration

Edit `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json` and, for intent IDs or phrases, `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json` inside the mod, then load a save to apply changes. Right Alt defaults to keyboard scan code `184`; configurable opening-key codes are `1–255`. No live reload or JSON write-back.

Each wheel has 1–8 ordered slots. A slot is `null` (disabled) or a nonempty label and exactly one of `intent`, `submenu`, or `control` (`back` / `close`). The catalog ships 25 default intent IDs, but the validated lowercase-ASCII ID registry is dynamic. Every layout ID must exist in `intents.json`; every wheel and catalog entry is validated. Unknown properties/IDs, wrong types, broken submenu references, cycles, and oversized wheels fail closed.

Labels, slot order, disabled slots, repeated supported intents, wheel names/submenus, and opening key are customizable without recompiling. Positions 1–4 run down the left side; positions 5–8 run down the right. Submenus display ` >`; Back displays ` <`. Leave these markers out of JSON. Keep labels short—there is no automatic truncation.

`intents.json` defines each supported ID and its three phrases: `narration`, group `notification`, and `targetedNotification`. Add an ID by adding its catalog record and referencing it from `layout.json`; edit phrases in that record. Phrase values omit your character's name and final period; exactly one literal `{target}` marker appears only in `targetedNotification`. Use plain JSON without comments or trailing commas. Both files are read on load, so changes apply after loading a save. No Lua/Papyrus edit, recompile, YAML narration file, or external trigger bundle is needed.

For exact schema rules and all 25 shipped default narration/group-notification phrases, see the [specification](docs/specs/player-signals.md).

## Build and checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```

Scoped source-derived smokes, separately passed unittests, and the failed full-build attempt are summarized above and detailed in the plan; none establish in-game behavior.
