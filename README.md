# PlayerSignals (for SkyrimNet)

PlayerSignals is a configurable communication wheel for SkyrimNet. Gesture entries send authored direct narration; the experimental Actions category executes registered SkyrimNet actions on the captured NPC. Gesture requests do not force compliance. Action API acceptance does not prove that an in-game effect occurred.

## Status

**Historical limited-test release (before target-NPC actions).** The 2026-10-02 ASSOS session recorded eight player-originator gestures, seven NPC responses and one expected no-audience result. One ADT removal test retained saved Papyrus remnants; a ReSaver-cleaned copy loaded without missing-script warnings during a short window. These records do not establish action execution, exhaustive runtime acceptance or safe mid-save removal. The older ESP-lock build failure is historical; current offline results are below. See internal `docs-dev/plans/player-signals.md` for evidence and limits.

**Experimental Magelight branch:** the wheel has 12 generated 30° slices clockwise from the top (slot 0), keeps its ChevronKnot as authored SVG artwork, and contains no raster artwork. The gesture destination for everyone nearby is **Openly**, shown with sound-wave ripple arcs and no head. SVG-attribute hover bounce and incoming-only fade honor reduced motion; labels are upright inside the lifted SVG group, with no CSS transform on their foreignObject or HTML content. Core/tip shapes have dark outer edges and chamfered light inset lines; armed-only top and bottom quarter-screen vignettes aid contrast, with title/help above them. The captured NPC's display name appears in the hub; without a captured NPC it shows **No target · Openly** and action entries are disabled. UIExtensions remains available for wheels of up to 8 slots and fails closed above that limit. These rendering revisions are browser-verified only; Ultralight rendering and actual game frame cost remain unverified.

- Internal specification: `docs-dev/specs/player-signals.md` (external linked development documentation; not edited here).
- [Player guide](PlayerSignals/PlayerSignals-README.md): friendly setup, wheel customization, targeting, and troubleshooting; this file is inside the packaged mod root.
- Internal implementation plan: `docs-dev/plans/player-signals.md`; design and tasks: `openspec/changes/add-target-npc-actions/`. These linked directories are not in this worktree and were left unchanged.

## Repository layout

```text
PlayerSignals/              Mod root; only this child folder belongs in MO2
PlayerSignals_spriggit/      Authored plugin records (outside the mod root)
docs-dev/                    Externally linked internal contracts and evidence (not published)
openspec/                    Externally linked change artifacts (not published)
build/                       PowerShell build and local compiler flags
tests/                       Raw JSON/schema regressions executed on LuaJIT
```

The mod root contains `PlayerSignals.esp`, startup quest SEQ, two Papyrus scripts and compiled PEX files, five default wheels, sibling layout and intent JSON, and a JContainers Lua loader. An optional prompt-only SkyrimNet bundle supplies the WebUI agent `playersignals_intent_helper`; it generates JSON for users to save from pasted configuration, not automatic file edits. Wheel dispatch does not depend on its manifest or external bundle, and no YAML triggers/actions are shipped. The inherited agent rendered against installed base content with zero validation findings; live WebUI discovery/model behavior remain unverified.

## Dependencies and targeting

Required: SKSE, UIExtensions, JContainers API 4 / feature 2 with working Lua support, and SkyrimNet. Startup requires `SkyrimNet.esp` loaded and a nonempty `SkyrimNetApi.GetBuildVersion()`.

The enabled Magelight backend also requires Magelight host **0.31.2+** and its matching runtime. Action entries require SkyrimNet's `IsActionRegistered`, `ExecuteAction`, `SkyrimNetInternal` built-in eligibility functions and, when configured, persistent/short-lived event APIs. The shipped `drink_alcohol` example requires separately installed and registered iActions; iActions is optional, not a general PlayerSignals dependency. Without it, selecting that entry reports the unregistered action and does nothing.

Before the wheel opens, PlayerSignals captures the current crosshair NPC. If a valid NPC remains captured when you select a gesture, SkyrimNet receives direct narration with the player as originator (`From`) and the captured NPC as the explicit target. The narration names your character as the gesture actor and explicitly addresses the captured NPC. Moving the crosshair after opening does not change the submitted recipient. The captured NPC must remain alive, enabled, and 3D-loaded when submitting or the selection fails closed. SkyrimNet selects the responder; this call does not force the captured NPC to respond, and SkyrimNet may replace event `To` with the selected responder.

No NPC captured means gesture narration and feedback are addressed openly to everyone nearby. Magelight labels this destination **Openly** and offers sound-wave ripple arcs without a speaking-head symbol. Holding either Shift (scan code 42 or 54) through selection overrides a captured target; Shift is sampled immediately after the wheel returns an accepted intent. Group narration explicitly addresses everyone nearby. Nearby witnesses may join, but nobody is guaranteed to reply. An invalid captured target is not silently redirected.

The captured NPC's display name appears in Magelight's hub; an empty display name is shown as **Target NPC**. With no captured NPC, the hub shows **No target · Openly**, and action entries are disabled up front. Action submission still uses the existing validity checks.

Action entries instead execute once on the valid captured NPC, with no direct narration, nearby region or Shift conversion. Registered built-ins (`AccompanyTarget`, `StopAccompanying`, `WaitHere`) run their eligibility checks; other registered actions run without an eligibility check. PlayerSignals does not enforce action cooldowns. Accepted action failures report one trace and local notification. Optional per-slot events record context only after API success; they do not prove completion. No direct animation or player-control API is used by PlayerSignals itself.

## Installation and first use

Before installing or updating, back up your save and matching SKSE cosave. Install the mod ZIP attached to the [GitHub release](https://github.com/Gerkinfeltser/PlayerSignals/releases) through MO2 and enable `PlayerSignals.esp`. The ZIP root is the mod's Data root: `PlayerSignals.esp`, `Scripts/`, `SEQ/`, and `SKSE/` are directly inside it. GitHub's automatic source archives are not the installable mod ZIP; if using a repository checkout, install only the **`PlayerSignals/` child folder**, not the repository root. Install and enable the dependencies above. Do not install or activate an old PlayerSignals trigger bundle; direct narration uses SkyrimNet's native API.

Launch through SKSE and load a save or start a new game. If SkyrimNet.esp or the native API build version is missing, PlayerSignals will not enable. In normal gameplay, press **Right Alt** to open the wheel and choose a gesture. A local notification confirms the API accepted the submission; SkyrimNet decides whether NPCs speak.

See the [player guide](PlayerSignals/PlayerSignals-README.md) for a quick walkthrough and examples.

### Existing saves, updates, and removal

Back up your save before installing or updating. The stable startup quest/SEQ and player alias `OnInit`/`OnPlayerLoadGame` path are designed to initialize on existing saves. This cutover adds no saved controller fields, changes no property defaults, aliases, quest/FormIDs, or startup SEQ, and rebuilds its private native maps from both JSON files through Lua on load. Existing-save support is by design, but the current install/update path has not been tested in-game.

PlayerSignals does not add gesture spells, edit NPC world records, or toggle player controls. Saves may retain quest/script state, and the mod has no shutdown/uninstall cleaner. One ADT test confirmed that disabling the mod left two unattached instances and two undefined elements; a ReSaver-cleaned copy loaded without PlayerSignals missing-script warnings, but only a short post-load window was captured. Do not treat this as guaranteed clean removal or prescribe ReSaver cleanup as universally safe. Restore a pre-installation save and matching SKSE cosave for the safest rollback. SkyrimNet may retain narration history separately; restoring a Skyrim save does not erase it.

## Configuration

Edit `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json` and, for intent IDs or phrases, `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json` inside the mod, then load a save to apply changes. Right Alt defaults to keyboard scan code `184`; configurable opening-key codes are `1–255`. In Magelight, press the configured open key again to cancel an armed wheel, like Tab/Escape/center, without narration. The page requires an integer `openKey` in its Lua payload and maps known DirectInput scan codes to physical `KeyboardEvent.code` values; unmapped codes warn once per page/code and retain Tab/Escape/center cancellation. Pre-arm keydowns, repeat keydowns and keyups cannot toggle it closed. No live reload or JSON write-back.

Each wheel supports 1–12 ordered slots. Magelight lays out 12 slices of 30° clockwise from slot 0 at the top. UIExtensions supports at most 8 slots; a wheel configured with more than 8 fails closed with an actionable notification rather than being truncated. A slot is `null` (disabled) or has a nonempty label and one primary kind: `intent`, `action`, `submenu`, or `control` (`back` / `close`). An action is `{"name":"drink_alcohol","args":{"drinkName":""}}`; it may additionally supply paired `event` (`persistent`, `shortLived`, or `both`) and catalog `intent` fields for context text. Every narration/event intent must exist in `intents.json`; action names are not catalog IDs. All wheels and catalog entries are validated. Unknown fields, wrong types, broken references, cycles and oversized wheels fail closed.

Labels, slot order, disabled slots, repeated supported intents, wheel names/submenus, and opening key are customizable without recompiling. UIExtensions positions 1–4 run down the left and 5–8 down the right; it rejects wheels over 8 slots. Magelight positions run clockwise from the top in 12 slices of 30°, with slot 0 at the top. Every shipped submenu puts Back at zero-based slot 10 (300°, just above cardinal west); Social puts Show respect at 7, Signals puts Calm down at 7, and Attitude/Actions leave 7 empty. Submenu, Back, Close and target-only actions use one merged necktie fill, outline, inset edge and target hit region, including the former tip. Navigation retains the authored ChevronKnot; actions omit knot/ripple art. Only Submenu and Back show their respective uniformly scaled, hub-flush vector arrows. Gesture cores use the gesture palette, navigation uses the neutral palette and actions use a muted reddish palette. Only gestures retain separate core/tip regions, upright ripple arcs and their idle hollow tip fill. Holding either Shift key previews Openly on a focused/hovered gesture: both regions light up, the ripple becomes fully visible and the hub says Openly. Release, window blur and disarm clear this preview; page dispatch is unchanged because Papyrus still samples Shift after Browse. Action badges sit directly below their actual wrapped label text, centered and upright. Hover lifts the selected slice and counter-rotated label to 1.06 scale using the bounded 160 ms SVG-attribute tween; no animation-frame loop runs at idle or after disarm. Empty slots remain inert at .5 opacity, using the merged necktie with one faint outer stroke and no inset or knot. The armed-only bottom vignette covers 25vh with an 80%-to-transparent gradient; help text stacks above it. The hub shows the captured NPC's display name (or **Target NPC** for an empty name); without a captured NPC it shows **No target · Openly**, and action entries are disabled up front. No custom label is truncated or assigned a hard character limit.

Center Cancel lifts to 1.08 on hover/focus using the same SVG-attribute ease-out-back tween as slices, and returns on leave/blur. The opaque octagon, its native frame and upright text scale together and paint last above all slices, arrows, labels and insets. Its painted paths take Cancel hit priority inside the moving outline; slices remain selectable immediately outside it. Core and merged outlines extend their existing straight sides to concealed inner points, including their inset lines, so no transverse inner cap appears during the bounce. Reduced motion or `--ps-tween: 0ms` snaps both hub and slice lifts, with no idle animation frames. Matching armed-only vignettes fade from 80% black at each screen edge to transparent at 25vh; title and ~20px two-line help paint above them, substituting the configured physical key's short name (or omitting it if unmapped):

```text
Slice: target  ·  Tip or Shift: Openly
←/→ choose  ·  Enter select  ·  Esc / Right Alt / center: cancel
```

The shortened help does not remove controls: Up chooses the captured-target region, Down chooses a gesture's Openly tip, Space also selects, and Tab still cancels. Merged actions remain target-only despite the compact generic hint.

Optional top-level `"theme": "slate"` in `layout.json` selects the Magelight palette. Choices are `slate` (original grey/blue-slate and gold, default when omitted), `moss` (muted dark green), and `ember` (muted dark red/rust). Unknown values or non-string values reject the layout; UIExtensions ignores the validated setting. The shipped layout omits it. Load a save to apply changes. The page defines `--nav-fill`, `--gesture-fill` and `--action-fill` per theme near the top; cream text and Chevron/Knot line colours are unchanged. Hover uses plain fill/stroke colours, not SVG/CSS filters. Selection/hover overrides every kind's idle palette. Only fill, opacity and SVG lift transform animate; `--ps-tween: 0ms` and reduced motion make the lift instant. All choices dispatch without waiting for a fade; only the incoming wheel fades in. The bottom quarter fades to black at 80% opacity at the bottom while armed. Magelight removes exactly one final ` >` suffix from typed submenu payloads and one final ` <` suffix from typed Back payloads, including caption and accessible label; other authored text is unchanged. Inline glyphs can be typed directly into labels; no separate icon field exists.

`intents.json` defines each supported ID and its three phrases: `narration`, group `notification`, and `targetedNotification`. Add an ID by adding its catalog record and referencing it from `layout.json`; edit phrases in that record. Phrase values omit your character's name and final period; exactly one literal `{target}` marker appears only in `targetedNotification`. Use plain JSON without comments or trailing commas. Both files are read on load, so changes apply after loading a save. No Lua/Papyrus edit, recompile, YAML narration file, or external trigger bundle is needed.

For exact schema rules and all shipped narration defaults, see the internal `docs-dev/specs/player-signals.md` and the installed [player guide](PlayerSignals/PlayerSignals-README.md).

## Build and checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```

The build generates 12 clockwise 30° sectors and inset outlines from shared parameters instead of cloning the Affinity 45° `Piece`, retaining vector ChevronKnot, Submenu and Upmenu art from `media/src/RadialUI.svg`. Inset lines use a 20-unit inset and 12-unit corner chamfers; the page renders their 9-unit stroke at about 1.75 px on a 700 px wheel. Export indentation is omitted from generated SVG without stripping authored SVG text spacing. The build rejects any source `<image>` element and checks generated IDs and references. Back is at slot 10 (300°, just above cardinal west) in every shipped submenu. The shipped layout gives each entry one home, including `understood` (Attitude 2), `comfort` (Social 8), `not_ready` (Signals 6), `give_space` (Signals 11), `respect` (Social 7) and `calm_down` (Signals 7). Existing unused catalog entries, including the follow/wait gestures, remain available for custom layouts. The Actions wheel includes Follow / resume (`AccompanyTarget`), Drink alcohol (`drink_alcohol`), Wait here (`WaitHere`), and Stop following (`StopAccompanying`); native runtime acceptance remains unverified.

**SVG authoring contract:** keep ChevronKnot, Submenu and Upmenu authored as vectors in `media/src/RadialUI.svg`; any `<image>` element fails the build, including unused definitions. Slice geometry is generated as 12 clockwise 30° slices, slot 0 at the top. Only gestures retain separate core/tip hits sharing radius 1296; navigation, actions and empty slots use their merged outer outline without the internal arc. Core/merged side lines converge to a point roughly 69.519 units from the wheel center; their inset sides converge roughly 146.591 units out. Both stay concealed by the opaque native octagon during slice lift and hub pop. The simple arrow fit uses the octagon circumradius (470 units) plus 6, centered on each slice line, and one uniform scale per glyph type: 80% of the visible slice width at that radius divided by the authored glyph width. This deliberately leaves extra clearance over the octagon's flat faces. An anchor translation follows hub/slice scale during the shared tween; no per-frame path measurements or per-slot fit table remain. Hidden apex geometry does not move labels: their anchor retains 1.2 times the original core-bounds-center radius. The harness checks hub paint/hit priority, concealed caps, arrow angle/aspect/containment and both vignettes. Changed artwork requires checking the simple source dimensions and browser rendering.

The controller captures the NPC display name before opening Magelight and passes it through a JContainers value for Lua to read; the name is not interpolated into Lua source. The hub displays the captured name, falling back to **Target NPC** for an empty name. An absent target displays **No target · Openly** and disables action entries. Submission-time target validity checks remain unchanged.

Magelight's inspected page contract exposes mouse/keyboard input and `__uimode`, not flat-gamepad events or a controller-in-use signal (`D:/git/MagelightUI/README.md:68–74`, `docs/SDK.md:14–33`). The installed Papyrus API and built-in page examples expose no gamepad delivery API. Controller selection and A/X/Y prompts are therefore not implemented. Offline checks do not establish in-game Magelight or SkyrimNet behavior.

## License

PlayerSignals code and documentation are licensed under the [MIT License](LICENSE), copyright 2026 phospheneoverdrive. The installable mod includes its own copy of the license. Dependencies retain their own licenses and are not bundled.
