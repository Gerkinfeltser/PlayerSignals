# PlayerSignals (for SkyrimNet)

PlayerSignals is a configurable communication wheel for SkyrimNet. Gesture entries send authored direct narration; the experimental Actions category executes registered SkyrimNet actions on the captured NPC. Gesture requests do not force compliance. Action API acceptance does not prove that an in-game effect occurred.

## Status

**Historical limited-test release (before target-NPC actions).** The 2026-10-02 ASSOS session recorded eight player-originator gestures, seven NPC responses and one expected no-audience result. One ADT removal test retained saved Papyrus remnants; a ReSaver-cleaned copy loaded without missing-script warnings during a short window. These records do not establish action execution, exhaustive runtime acceptance or safe mid-save removal. The older ESP-lock build failure is historical; current offline results are below. See internal `docs-dev/plans/player-signals.md` for evidence and limits.

**Experimental branch `feature/target-npc-actions`:** Magelight is enabled in the built payload, using the authored SVG wheel with separate target-NPC bodies and everyone-nearby chevrons for gestures. Action entries are target-only and ignore Shift. Action implementation and offline verification are tracked in the external `openspec/changes/add-target-npc-actions/` change and `docs-dev/plans/player-signals.md`; native action acceptance remains runtime-unverified.

- Internal specification: `docs-dev/specs/player-signals.md` (externally stored development documentation).
- [Player guide](PlayerSignals/PlayerSignals-README.md): friendly setup, wheel customization, targeting, and troubleshooting; this file is inside the packaged mod root.
- Internal implementation plan: `docs-dev/plans/player-signals.md`; design and tasks: `openspec/changes/add-target-npc-actions/`. These ignored, linked directories are not part of this repository's published payload.

## Repository layout

```text
PlayerSignals/              Mod root; only this child folder belongs in MO2
PlayerSignals_spriggit/      Authored plugin records (outside the mod root)
docs-dev/                    Externally linked internal contracts and evidence (not published)
openspec/                    Externally linked change artifacts (not published)
build/                       PowerShell build and local compiler flags
tests/                       Raw JSON/schema regressions executed on LuaJIT
```

The mod root contains `PlayerSignals.esp`, startup quest SEQ, two Papyrus scripts and compiled PEX files, four default wheels, sibling layout and intent JSON, and a JContainers Lua loader. An optional prompt-only SkyrimNet bundle supplies the WebUI agent `playersignals_intent_helper`; it generates JSON for users to save from pasted configuration, not automatic file edits. Wheel dispatch does not depend on its manifest or external bundle, and no YAML triggers/actions are shipped. The inherited agent rendered against installed base content with zero validation findings; live WebUI discovery/model behavior remain unverified.

## Dependencies and targeting

Required: SKSE, UIExtensions, JContainers API 4 / feature 2 with working Lua support, and SkyrimNet. Startup requires `SkyrimNet.esp` loaded and a nonempty `SkyrimNetApi.GetBuildVersion()`.

The enabled Magelight backend also requires Magelight host **0.31.2+** and its matching runtime. Action entries require SkyrimNet's `IsActionRegistered`, `ExecuteAction`, `SkyrimNetInternal` built-in eligibility functions and, when configured, persistent/short-lived event APIs. The shipped `drink_alcohol` example requires separately installed and registered iActions; iActions is optional, not a general PlayerSignals dependency. Without it, selecting that entry reports the unregistered action and does nothing.

Before the wheel opens, PlayerSignals captures the current crosshair NPC. If a valid NPC remains captured when you select a gesture, SkyrimNet receives direct narration with the player as originator (`From`) and the captured NPC as the explicit target. The narration names your character as the gesture actor and explicitly addresses the captured NPC. Moving the crosshair after opening does not change the submitted recipient. The captured NPC must remain alive, enabled, and 3D-loaded when submitting or the selection fails closed. SkyrimNet selects the responder; this call does not force the captured NPC to respond, and SkyrimNet may replace event `To` with the selected responder.

No NPC captured means the gesture is addressed to everyone nearby. Holding either Shift (scan code 42 or 54) through selection overrides a captured target; Shift is sampled immediately after the wheel returns an accepted intent, not at the exact click instant. The group narration explicitly says it is addressed to everyone nearby. Nearby witnesses may join, but nobody is guaranteed to reply. An invalid captured target is not silently redirected to a different NPC or to group mode.

Each accepted gesture makes one `SkyrimNetApi.DirectNarration` call. A local player-named notification appears only if the API returns `0`; group wording omits the recipient, while targeted wording uses the name captured before the wheel opened. Either Shift key forces group feedback without the discarded name. This is a submission receipt, not proof of SkyrimNet delivery or an NPC response. Navigation, cancellation, stale selections, invalid gesture targets, and unsuccessful gesture calls stay silent.

Action entries instead execute once on the valid captured NPC, with no direct narration, nearby region or Shift conversion. Registered built-ins (`AccompanyTarget`, `StopAccompanying`, `WaitHere`) run their eligibility checks; other registered actions run without an eligibility check. PlayerSignals does not enforce action cooldowns. Accepted action failures report one trace and local notification. Optional per-slot events record context only after API success; they do not prove completion. No direct animation or player-control API is used by PlayerSignals itself.

## Installation and first use

Before installing or updating, back up your save and matching SKSE cosave. Install the mod ZIP attached to the [GitHub release](https://github.com/Gerkinfeltser/PlayerSignals/releases) through MO2 and enable `PlayerSignals.esp`. The ZIP root is the mod's Data root: `PlayerSignals.esp`, `Scripts/`, `SEQ/`, and `SKSE/` are directly inside it. GitHub's automatic source archives are not the installable mod ZIP; if using a repository checkout, install only the **`PlayerSignals/` child folder**, not the repository root. Install and enable the dependencies above. Do not install or activate an old PlayerSignals trigger bundle; direct narration uses SkyrimNet's native API.

Launch through SKSE and load a save or start a new game. If SkyrimNet.esp or the native API build version is missing, PlayerSignals will not enable. In normal gameplay, press **Right Alt** to open the wheel and choose a gesture. A local notification confirms the API accepted the submission; SkyrimNet decides whether NPCs speak.

See the [player guide](PlayerSignals/PlayerSignals-README.md) for a quick walkthrough and examples.

### Existing saves, updates, and removal

Back up your save before installing or updating. The stable startup quest/SEQ and player alias `OnInit`/`OnPlayerLoadGame` path are designed to initialize on existing saves. This cutover adds no saved controller fields, changes no property defaults, aliases, quest/FormIDs, or startup SEQ, and rebuilds its private native maps from both JSON files through Lua on load. Existing-save support is by design, but the current install/update path has not been tested in-game.

PlayerSignals does not add gesture spells, edit NPC world records, or toggle player controls. Saves may retain quest/script state, and the mod has no shutdown/uninstall cleaner. One ADT test confirmed that disabling the mod left two unattached instances and two undefined elements; a ReSaver-cleaned copy loaded without PlayerSignals missing-script warnings, but only a short post-load window was captured. Do not treat this as guaranteed clean removal or prescribe ReSaver cleanup as universally safe. Restore a pre-installation save and matching SKSE cosave for the safest rollback. SkyrimNet may retain narration history separately; restoring a Skyrim save does not erase it.

## Configuration

Edit `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json` and, for intent IDs or phrases, `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json` inside the mod, then load a save to apply changes. Right Alt defaults to keyboard scan code `184`; configurable opening-key codes are `1–255`. No live reload or JSON write-back.

Each wheel has 1–8 ordered slots. A slot is `null` (disabled) or has a nonempty label and one primary kind: `intent`, `action`, `submenu`, or `control` (`back` / `close`). An action is `{"name":"drink_alcohol","args":{"drinkName":""}}`; it may additionally supply paired `event` (`persistent`, `shortLived`, or `both`) and catalog `intent` fields for context text. Every narration/event intent must exist in `intents.json`; action names are not catalog IDs. All wheels and catalog entries are validated. Unknown fields, wrong types, broken references, cycles and oversized wheels fail closed.

Labels, slot order, disabled slots, repeated supported intents, wheel names/submenus, and opening key are customizable without recompiling. UIExtensions positions 1–4 run down the left and 5–8 down the right; experimental Magelight positions run clockwise from the top. Submenus display ` >`; Back displays ` <`. Do not duplicate markers in JSON. No custom label is truncated or assigned a hard character limit.

In the experimental Magelight wheel, each non-null slot may also set an optional `icon` string. When omitted, the entry type supplies a default:

| Entry type | Default |
|---|---|
| Intent / gesture | ✦ |
| Action | ❖ |
| Submenu | ◈ |
| Back | ⚐ |
| Close | ✕ |

An explicit icon must contain 1–4 Unicode scalar values (not bytes or grapheme clusters; a supplementary-plane character counts as one) and no ASCII whitespace or C0/C1 control characters. For example: `{ "label": "Yes", "intent": "confirm", "icon": "★" }`. The icon is rendered as literal text; available glyph shapes depend on the fonts installed at runtime. UIExtensions remains text-only: it ignores icons and keeps its existing labels and navigation markers. Invalid, empty, or explicit `null` icons fail shared configuration validation; omit `icon` to use the default. Save the JSON and load a save to apply it. The revised Magelight icon rendering remains runtime-unverified.

`intents.json` defines each supported ID and its three phrases: `narration`, group `notification`, and `targetedNotification`. Add an ID by adding its catalog record and referencing it from `layout.json`; edit phrases in that record. Phrase values omit your character's name and final period; exactly one literal `{target}` marker appears only in `targetedNotification`. Use plain JSON without comments or trailing commas. Both files are read on load, so changes apply after loading a save. No Lua/Papyrus edit, recompile, YAML narration file, or external trigger bundle is needed.

For exact schema rules and all shipped narration defaults, see the internal `docs-dev/specs/player-signals.md` and the installed [player guide](PlayerSignals/PlayerSignals-README.md).

## Build and checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```

The build embeds `media/src/RadialUI.svg` into the Magelight page, preserving its named paths/transforms while omitting the editor background. Edit that SVG for geometry; the marked SVG section in `PlayerSignals/Magelight/PlayerSignals/index.html` is generated. Only the built `PlayerSignals/` payload belongs in MO2.

Current action revision: all **21 configuration tests** pass; source-derived controller/loader smokes and browser interaction checks pass; the full build compiles both scripts with **0 errors and 0 warnings** and completes ESP/SEQ generation. These are offline results, not native action or NPC-effect acceptance. Per the owner's revised decision, short-lived event data and description both contain the same rendered intent phrase; the inspected no-schema formatter can therefore expose the phrase rather than action/FormID metadata.

Wheel-icon revision: **23 configuration tests** pass, including Unicode icon boundaries and payload defaults/overrides. Browser checks cover literal icons, all eight slices' width/separation/hit testing, invalid payload clearing and unchanged selection behavior; the full build succeeds with unchanged ESP/SEQ hashes. These remain offline checks, not in-game icon acceptance.

## License

PlayerSignals code and documentation are licensed under the [MIT License](LICENSE), copyright 2026 phospheneoverdrive. The installable mod includes its own copy of the license. Dependencies retain their own licenses and are not bundled.
