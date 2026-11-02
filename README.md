# PlayerSignals (for SkyrimNet)

PlayerSignals is a configurable communication wheel for SkyrimNet. Gesture entries send authored direct narration; target-NPC action entries execute registered SkyrimNet actions. Gesture requests do not force compliance. Action API acceptance does not prove that an in-game effect occurred.

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

The mod root contains `PlayerSignals.esp`, startup quest SEQ, two Papyrus scripts and compiled PEX files, four default wheels, sibling layout and intent JSON, and a JContainers Lua loader. An optional prompt-only SkyrimNet bundle supplies the WebUI agent `playersignals_intent_helper`; it generates JSON for users to save from pasted configuration, not automatic file edits. Wheel dispatch does not depend on its manifest or external bundle, and no YAML triggers/actions are shipped. The inherited agent rendered against installed base content with zero validation findings; live WebUI discovery/model behavior remain unverified.

## Dependencies and targeting

Required: SKSE, UIExtensions, JContainers API 4 / feature 2 with working Lua support, and SkyrimNet. Startup requires `SkyrimNet.esp` loaded and a nonempty `SkyrimNetApi.GetBuildVersion()`.

The enabled Magelight backend also requires Magelight host **0.31.2+** and its matching runtime. Action entries require SkyrimNet's `IsActionRegistered`, `ExecuteAction`, `SkyrimNetInternal` built-in eligibility functions and, when configured, persistent/short-lived event APIs.

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

Each wheel supports 1–12 ordered slots. Magelight lays out 12 slices of 30° clockwise from slot 0 at the top. UIExtensions supports at most 8 slots; a wheel configured with more than 8 fails closed with an actionable notification rather than being truncated. A slot is `null` (disabled) or has a nonempty label and exactly one primary kind: `intent`, `action`, `submenu`, `control` (`back` / `close`), or `hotkey`. A hotkey slot may have only `hotkey`, `delayMs`, and `holdMs` in addition to `label`; timings apply only to hotkeys. The `hotkey` code is a strict integer 1–263 (1–255 keyboard DirectInput scan codes, 256–263 SKSE mouse buttons: 256 left, 257 right, 258 middle), `delayMs` defaults to 100 (integer 0–2000), and `holdMs` defaults to 50 (integer 1–2000). Its code must differ from `input.openKeyCode`. Actions may additionally supply paired `event` (`persistent`, `shortLived`, or `both`) and catalog `intent` fields for context text. Every narration/event intent must exist in `intents.json`; action names are not catalog IDs. All wheels and catalog entries are validated. Unknown fields, wrong types, broken references, cycles and oversized wheels fail closed.

### Make the wheel your own

For a custom slot that clicks the **middle mouse button** (SKSE code `258`), add this object to a wheel without exceeding 12 slots:

```json
{ "label": "Middle mouse", "hotkey": 258, "delayMs": 100, "holdMs": 50 }
```

The shipped layout has no hotkey slot. A hotkey slot presses the key only after the wheel/view fully closes, needs no target, ignores Shift, and emits no narration or success notification. Its code must differ from the configured opening key; timing defaults and strict ranges are listed above. The injected press reaches only mods that read Skyrim's own input (owner-verified in game for middle mouse); mods that poll Windows key state directly, such as the SkyrimNet (F6) and IntelEngine dashboard hotkeys, do not see it.

Labels, slot order, disabled slots, repeated supported intents, wheel names/submenus, and opening key are customizable without recompiling. UIExtensions supports at most eight slots; Magelight places twelve 30° slices clockwise from the top. Every shipped submenu puts Back at zero-based slot 10. Submenu, Back, Close and target-only actions use merged neckties. Only Submenu/Back neckties scale by 0.85 about the wheel centre, including hits, insets, selected bands, flow and label placement/fit; their stroke widths stay unchanged. Submenu and Back alone show the authored ChevronKnot with its V apex on the smaller outer tip and arms hugging the tip edges. The knot retains its approved absolute size and original stroke widths; tails may extend beyond the shortened outer edges. It lifts with its slice and stays hidden when disabled. Only Submenu/Back show two thin clipped arcs at radii 560 and 610, outside the hub's maximum pop, clipped to the active outline. Hotkeys have a flat-topped trapezoid cap and straight-chord pie with separate borders: either part selects the same key and lights both. Gesture cores and half-disc bulbs share a straight outer-corner chord without a fill gap or overlap sliver; insets, selected bands and flow clips follow it. The upright broadcast icon is centered in the half-disc's bounds at its existing size; ripple motion stays centered on the chord midpoint. Shift previews Openly on a gesture without changing page dispatch. SIGNAL, ACTION and KEY badges remain upright beneath wrapped labels; Submenu, Back, Close and null slots have no badge. Lit badges use their kind's idle fill, and navigation chevrons dim behind the label only; actual visible badges on other kinds remain respected. The selected band is 30 units wide (15 visible units), including the lit cap; its stroke width is 30. Slices lift to 1.06. All disabled slots use the same faint pointed necktie, not a split/trapezoid; actions without a target are disabled. Captured-target names and untampered custom labels are unchanged.

Center Cancel lifts to 1.08 on hover/focus using the same SVG-attribute ease-out-back tween as slices, and returns on leave/blur. The opaque octagon, its native frame and upright text scale together and paint last above all slices, arrows, labels and insets. Its painted paths take Cancel hit priority inside the moving outline; slices remain selectable immediately outside it. Core and merged outlines extend their existing straight sides to concealed inner points, including their inset lines, so no transverse inner cap appears during the bounce. Reduced motion or `--ps-tween: 0ms` snaps both hub and slice lifts, with no idle animation frames. Matching armed-only vignettes fade from 80% black at each screen edge to transparent at 25vh behind the wheel, title and ~20px two-line help, so they do not dim white cap highlights. The help substitutes the configured physical key's short name (or omits it if unmapped):

```text
Slice: target  ·  Tip or Shift: Openly
←/→ choose  ·  Enter select  ·  Esc / Right Alt / center: cancel
```

The shortened help does not remove controls: Up chooses a gesture's Openly bulb, Down returns to its core, Space also selects, and Tab cancels. On navigation, actions and hotkeys, Up and Down stay on the same slice; hotkey cap/pie have no Openly variant.

Optional top-level `"theme": "slate"` selects the Magelight idle palette; `moss` and `ember` are also supported. Unknown/non-string themes reject the layout; UIExtensions ignores this validated setting. Load a save to apply JSON changes. Hotkey cap/pie idle fills use muted teal: slate `#3d5a55`, moss `#3c5560`, ember `#3f5654`. Idle Submenu/Back fills use `--subnav-fill`: slate `#38392f`, moss `#2d3a2f`, ember `#402e2a`; their labels use `--subnav-label` `#bfb8a6` across themes. Selected labels retain the existing `--nav-fill` colors. Hot pies/cores use `--selection-outline` bright yellow for fill and inset line, with a 30-unit `--selection-band` darker-yellow band (15 visible units, stroke width 30), including the lit cap. Lit gesture bulbs and hotkey caps instead use a white-centre (`#ffffff`) to pale warm-edge (`#fff4e8`) radial gradient, with no filters; the thin `#d9bd79` band and existing edge lines remain unchanged. The kind's idle fill swaps onto selected labels/badges: gesture blue/green/rust, action red, neutral navigation, teal hotkey. Core-only gesture selection leaves the bulb in its gesture palette; bulb hover or Shift lights both. Reduced motion or zero `--ps-tween` makes lifts instant and flow static; choices dispatch without a fade-out delay. Typed Submenu/Back labels lose exactly one trailing navigation marker, not arbitrary authored text.
**Flow bands:** a selected gesture always animates its bulb, never its core, including the full Openly state. Actions and utilities animate chevrons; hotkey V-shaped flow stays in the inset pie only, while the cap remains lit without flow. Disabled actions and empty slots show none.

| Kind | Marks | Trail in real SVG units | Tint/blend |
|---|---:|---:|---|
| Signal bulb | 2 | `24 * (coreRadius / 320)` = 97.2 | Unlit: mint `#7fe6d4`, additive; lit: pale warm yellow `#fff1b8`, additive |
| Action | 4 | `46 * (coreRadius / 320)` = 186.3 | Warm white `#fff6e0`, additive on yellow |
| Utility/hotkey | 4 | 186.3 | Warm white `#fff6e0`, additive on yellow |

Each filled-gradient band travels for 2400 ms, holds its leading quarter solid, then fades with power 2.2 to a clear gap. Chevron peak `--flow-lit-opacity` is 0.35; bulb peaks `--flow-opacity` and `--flow-lit-signal-opacity` are 0.12. All receive a sine travel envelope. Unsupported additive blending uses normal blending with precomputed clamped tint/fill addition. Chevron half-width is `r * tan(15°) + 14 * (coreRadius / 320)`, height 0.45 times that width. Arc bands use radial gradients; chevrons use per-arm linear gradients, not stacked strokes. Ultralight blend support and repaint cost remain in-game-unverified.

One shared flow loop runs only while selected and stops on leave, blur, selection or disarm. Gesture Shift changes the ripple palette/state without suppressing the ripples. Frames update only SVG attributes, with no filters or per-frame layout reads; text bounds and fallback colors are cached on activation.

`intents.json` defines each supported ID and its three phrases: `narration`, group `notification`, and `targetedNotification`. Add an ID by adding its catalog record and referencing it from `layout.json`; edit phrases in that record. Phrase values omit your character's name and final period; exactly one literal `{target}` marker appears only in `targetedNotification`. Use plain JSON without comments or trailing commas. Both files are read on load, so changes apply after loading a save. No Lua/Papyrus edit, recompile, YAML narration file, or external trigger bundle is needed.

For exact schema rules and all shipped narration defaults, see the internal `docs-dev/specs/player-signals.md` and the installed [player guide](PlayerSignals/PlayerSignals-README.md).

## Build and checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```

For browser-only rendering QA, serve the checkout with `python -m http.server` and open `tests/test_magelight_wheel.html`. Run with normal/reduced-motion preferences; `?blend=normal` exercises the unsupported-additive fallback, including hover-color transitions. These checks do not launch Skyrim or prove Ultralight/native behavior.

The build generates 12 clockwise 30° sectors and inset outlines from shared parameters instead of cloning the Affinity 45° `Piece`, retaining vector ChevronKnot, Submenu and Upmenu art from `media/src/RadialUI.svg`. Inset lines use a 20-unit inset and 12-unit corner chamfers; the page renders their 9-unit stroke at about 1.75 px on a 700 px wheel. Export indentation is omitted from generated SVG without stripping authored SVG text spacing. The build rejects any source `<image>` element and checks generated IDs and references. Back is at slot 10 (300°, just above cardinal west) in every shipped submenu. The shipped layout gives each entry one home, including `understood` (Attitude 2), `comfort` (Social 8), `not_ready` (Signals 6), `give_space` (Signals 11), `respect` (Social 7) and `calm_down` (Signals 7). Existing unused catalog entries, including the follow/wait gestures, remain available for custom layouts. The main wheel includes Follow / resume (`AccompanyTarget`), Wait here (`WaitHere`), and Stop following (`StopAccompanying`); native runtime acceptance remains unverified.

**SVG authoring contract:** keep authored glyphs as vectors in `media/src/RadialUI.svg`; any `<image>` fails the build. Geometry is generated as twelve clockwise 30° slices. Gesture half-discs paint before their opaque cores. Hotkey cap/pie polygons split at the same outer-corner chord and have their own inset outlines; the cap's flat top is 40% of that chord width. Selected bands are clipped to the inset outline interior. `$navScale = 0.85` in `build/build.ps1` emits the Submenu/Back-only geometry variant and publishes its scale for dependent page geometry; other kinds retain their original paths. Knot ancestry and affine tip-edge fitting are baked into path coordinates without scaling stroke widths. The approved 0.56 length fit remains unchanged; only a translation moves its apex from `(1800, 108)` to `(1800, 361.8)`, with arms within 3° of the adjacent edge directions. Tails may overhang the smaller necktie's outer corners. Slot rotation remains around `(1800, 1800)` outside the shared slice lift. Navigation/actions and every disabled slot retain the pointed merged outline. Inner points remain concealed beneath the opaque topmost hub. Utility arcs remain wheel-centered at radii 560 and 610 and lift with their slice. `utility-art-off` hides only legacy Submenu/Upmenu arrows, not typed submenu/back knots. Hidden geometry does not move label anchors.

The controller captures the NPC display name before opening Magelight and passes it through a JContainers value for Lua to read; the name is not interpolated into Lua source. The hub displays the captured name, falling back to **Target NPC** for an empty name. An absent target displays **No target · Openly** and disables action entries. Submission-time target validity checks remain unchanged.

Magelight's inspected page contract exposes mouse/keyboard input and `__uimode`, not flat-gamepad events or a controller-in-use signal (`D:/git/MagelightUI/README.md:68–74`, `docs/SDK.md:14–33`). The installed Papyrus API and built-in page examples expose no gamepad delivery API. Controller selection and A/X/Y prompts are therefore not implemented. Offline checks do not establish in-game Magelight or SkyrimNet behavior.

## License

PlayerSignals code and documentation are licensed under the [MIT License](LICENSE), copyright 2026 phospheneoverdrive. The installable mod includes its own copy of the license. Dependencies retain their own licenses and are not bundled.
