# PlayerSignals (for SkyrimNet)

PlayerSignals is a configurable communication wheel for SkyrimNet. Gesture entries send authored direct narration; target-NPC action entries execute registered SkyrimNet actions. Most gesture requests do not force compliance; the two shipped hybrid signals also narrate NPC compliance only after a successful action API result. Action API acceptance does not prove that an in-game effect occurred.

## Status

**Historical limited-test release (before target-NPC actions).** The 2026-10-02 ASSOS session recorded eight player-originator gestures, seven NPC responses and one expected no-audience result. One ADT removal test retained saved Papyrus remnants; a ReSaver-cleaned copy loaded without missing-script warnings during a short window. These records do not establish action execution, exhaustive runtime acceptance or safe mid-save removal. The older ESP-lock build failure is historical; current offline results are below. See internal `docs-dev/plans/player-signals.md` for evidence and limits.

**Experimental Magelight branch:** the wheel has 12 generated 30° slices clockwise from the top (slot 0), keeps its ChevronKnot as authored SVG artwork, and contains no raster artwork. The gesture destination for everyone nearby is **Openly**, shown with sound-wave ripple arcs and no head. SVG-attribute hover bounce and incoming-only fade honor reduced motion. Labels and badges follow each slice radially, with the straight-up/down slots horizontal and the left half flipped to stay readable; they share an SVG-attribute frame inside the lifted group, with no CSS transform on their foreignObject or HTML content. Fitting allows wrapping and shrinking within the core sides, clear of the hub, cap chord and navigation artwork. Core/tip shapes have dark outer edges and chamfered light inset lines; armed-only top and bottom quarter-screen vignettes aid contrast, with title/help above them. The captured NPC's display name appears in the hub; without a captured NPC it shows **No target · Openly**. Pure action-only entries are disabled; hybrids remain signal entries. UIExtensions remains available for wheels of up to 8 slots and fails closed above that limit. These rendering revisions are browser-verified only; Ultralight rendering and actual game frame cost remain unverified.

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

The mod root contains `PlayerSignals.esp`, startup quest SEQ, three Papyrus scripts and compiled PEX files, the native `PlayerSignals.dll`, four default wheels, sibling layout and intent JSON, and a JContainers Lua loader. An optional prompt-only SkyrimNet bundle supplies the WebUI agent `playersignals_intent_helper`; it generates JSON for users to save from pasted configuration, not automatic file edits. Wheel dispatch does not depend on its manifest or external bundle, and no YAML triggers/actions are shipped. The inherited agent rendered against installed base content with zero validation findings; live WebUI discovery/model behavior remain unverified.

## Dependencies and targeting

Required: SKSE, UIExtensions, JContainers API 4 / feature 2 with working Lua support, and SkyrimNet. Startup requires `SkyrimNet.esp` loaded and a nonempty `SkyrimNetApi.GetBuildVersion()`.

The enabled Magelight backend also requires Magelight host **0.31.2+** and its matching runtime. Action entries require SkyrimNet's `IsActionRegistered`, `ExecuteAction`, `SkyrimNetInternal` built-in eligibility functions and, when configured, persistent/short-lived event APIs.
Only layouts containing a `raw: true` hotkey additionally require `PlayerSignals.dll` (native API version 1) and Address Library for SKSE Plugins (the VR Address Library for Skyrim VR). Layouts without raw slots do not require either; ordinary hotkeys retain Skyrim input dispatch.

Before the wheel opens, PlayerSignals captures the current crosshair NPC. For a targeted selection, SkyrimNet receives direct narration with the player as originator (`From`) and the captured NPC as the explicit target. Ordinary gesture narration addresses that NPC; hybrid signals include a separate compliance sentence only if their action succeeds. Moving the crosshair after opening does not change the submitted recipient. The captured NPC must remain alive, enabled, and 3D-loaded when submitting or the selection fails closed. SkyrimNet selects the responder; this call does not force the captured NPC to respond, and SkyrimNet may replace event `To` with the selected responder.

No NPC captured means narration and feedback are addressed openly to everyone nearby. Magelight labels this destination **Openly** and offers sound-wave ripple arcs without a speaking-head symbol. Holding either Shift (scan code 42 or 54) through selection overrides targeting to group mode. Group narration explicitly addresses everyone nearby; hybrid actions never run in Openly mode. Nearby witnesses may join, but nobody is guaranteed to reply. An invalid captured target is not silently redirected.

An action-only slot executes once on the valid captured NPC, with no direct narration or Shift conversion. Hybrid slots combine an `intent` and `action` (no `event`) and remain ordinary signal entries, enabled without a target because their signal still works openly. In Magelight they keep the signal's exact pie-and-bulb shape and flow; the sole visual difference is badge text `SIGNAL · ACTION` instead of `SIGNAL`, with no extra cue or flow. On a valid captured target with no Shift, the controller checks registration and existing action eligibility, then executes the action before sending exactly one `DirectNarration`. Built-ins `AccompanyTarget`, `StopAccompanying`, and `WaitHere` use SkyrimNet's eligibility checks; other registered actions have no eligibility check. A successful `ExecuteAction` return value of `0` permits adding the catalog's `complianceNarration`; any refusal/failure sends only the ordinary targeted signal, with no compliance sentence or extra notification. The existing local notification remains gated on DirectNarration returning `0`. In Openly mode the action is skipped and only the group signal is narrated. Never interpret API acceptance as proof the NPC complied.

The captured NPC's display name appears in Magelight's hub; an empty display name is shown as **Target NPC**. With no captured NPC, the hub shows **No target · Openly**. Pure action-only entries are disabled up front; hybrid slots remain enabled as signal entries because they still work openly. Submission-time target validity checks remain unchanged.

Pure action-only entries execute once on the valid captured NPC, with no direct narration, nearby region or Shift conversion. Registered built-ins (`AccompanyTarget`, `StopAccompanying`, `WaitHere`) run their eligibility checks; other registered actions run without an eligibility check. PlayerSignals does not enforce action cooldowns. Accepted action failures report one trace and local notification. Optional per-slot events record context only after API success; they do not prove completion. No direct animation or player-control API is used by PlayerSignals itself.

## Installation and first use

Before installing or updating, back up your save and matching SKSE cosave. Install the mod ZIP attached to the [GitHub release](https://github.com/Gerkinfeltser/PlayerSignals/releases) through MO2 and enable `PlayerSignals.esp`. The ZIP root is the mod's Data root: `PlayerSignals.esp`, `Scripts/`, `SEQ/`, and `SKSE/` are directly inside it. GitHub's automatic source archives are not the installable mod ZIP; if using a repository checkout, install only the **`PlayerSignals/` child folder**, not the repository root. Install and enable the dependencies above. Do not install or activate an old PlayerSignals trigger bundle; direct narration uses SkyrimNet's native API.

Launch through SKSE and load a save or start a new game. If SkyrimNet.esp or the native API build version is missing, PlayerSignals will not enable. In normal gameplay, press **Right Alt** to open the wheel and choose a gesture. A local notification confirms the API accepted the submission; SkyrimNet decides whether NPCs speak.

See the [player guide](PlayerSignals/PlayerSignals-README.md) for a quick walkthrough and examples.

### Existing saves, updates, and removal

Back up your save before installing or updating. The stable startup quest/SEQ and player alias `OnInit`/`OnPlayerLoadGame` path are designed to initialize on existing saves. This cutover adds no saved controller fields, changes no property defaults, aliases, quest/FormIDs, or startup SEQ, and rebuilds its private native maps from both JSON files through Lua on load. Existing-save support is by design, but the current install/update path has not been tested in-game.

PlayerSignals does not add gesture spells, edit NPC world records, or toggle player controls. Saves may retain quest/script state, and the mod has no shutdown/uninstall cleaner. One ADT test confirmed that disabling the mod left two unattached instances and two undefined elements; a ReSaver-cleaned copy loaded without PlayerSignals missing-script warnings, but only a short post-load window was captured. Do not treat this as guaranteed clean removal or prescribe ReSaver cleanup as universally safe. Restore a pre-installation save and matching SKSE cosave for the safest rollback. SkyrimNet may retain narration history separately; restoring a Skyrim save does not erase it.

## Configuration

Edit `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json` and, for intent IDs or phrases, `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json` inside the mod, then load a save to apply changes. Right Alt defaults to keyboard scan code `184`; configurable opening-key codes are `1–255`. In Magelight, press the configured open key again to cancel an armed wheel, like Tab/Escape/center, without narration. The page requires an integer `openKey` in its Lua payload and maps known DirectInput scan codes to physical `KeyboardEvent.code` values; unmapped codes warn once per page/code and retain Tab/Escape/center cancellation. Pre-arm keydowns, repeat keydowns and keyups cannot toggle it closed. No live reload or JSON write-back.

Each wheel supports 1–12 ordered slots. Magelight lays out 12 slices of 30° clockwise from slot 0 at the top. UIExtensions supports at most 8 slots; a wheel configured with more than 8 fails closed with an actionable notification rather than being truncated. A slot is `null` (disabled) or has a nonempty label and one primary kind: `intent`, `action`, `submenu`, `control` (`back` / `close`), or `hotkey`. An `intent` slot may additionally have `action: { "name": ..., "args": ... }` to form a hybrid; this is the only additional kind combination and hybrid slots must not have `event`. An action slot may instead carry paired `event` (`persistent`, `shortLived`, or `both`) and catalog `intent` fields for legacy action context; that remains a pure action and does not send direct narration. A hotkey slot may have `hotkey`, `delayMs`, `holdMs`, optional `color`, and optional strict boolean `raw` in addition to `label`; timings apply only to hotkeys. The `hotkey` code is a strict integer 1–263 (1–255 keyboard DirectInput scan codes, 256–263 SKSE mouse buttons: 256 left, 257 right, 258 middle), `delayMs` defaults to 100 (integer 0–2000), and `holdMs` defaults to 50 (integer 1–2000). Its code must differ from `input.openKeyCode`. `raw: true` is keyboard-only and requires scan code 1–255; `raw: false` retains normal hotkey behavior. Every referenced narration/event intent must exist in `intents.json`. All wheels and catalog entries are validated. Unknown fields, wrong types, broken references, cycles and oversized wheels fail closed.

In Magelight, any non-null slot can override its idle colour with a six-digit hex string (`#rrggbb`, either letter case):

```json
{ "label": "Greet", "intent": "greet", "color": "#4a6b5c" }
```

The fill override changes idle colour only, not the standard yellow selected fill, band or white caps; lit labels and badges use the chosen idle colour. Disabled slots keep their shared disabled look, and theme changes do not replace slot colours. Very light or very dark colours can hurt label readability. UIExtensions ignores the colour; the shipped layout colours only Yes (green) and No (red).

Custom-coloured gesture bulbs derive their unlit ripple tint from the slot colour (lower hue, increased HSL lightness); uncoloured ripples stay mint and lit-bulb ripples stay warm yellow, all at the existing `0.12` strength.

### Make the wheel your own

For a custom slot that clicks the **middle mouse button** (SKSE code `258`), add this object to a wheel without exceeding 12 slots:

```json
{ "label": "Middle mouse", "hotkey": 258, "delayMs": 100, "holdMs": 50 }
```

The shipped Extras submenu has one raw hotkey slot: the SkyrimNet dashboard (scan code 64). Hotkeys press only after the wheel/view fully closes, need no target, ignore Shift, and emit no narration or success notification. The code must differ from the configured opening key; timing defaults and strict ranges are listed above. This injected press reaches mods that read Skyrim's own input; mods that poll Windows key state directly see raw hotkeys only.

#### Raw keyboard hotkeys

Set `"raw": true` on a hotkey slot to send a Windows scan-code key press for mods that poll Windows key state. It is valid only for keyboard scan codes 1–255; mouse codes 256–263 cannot be raw. `"raw": false` is allowed but behaves like an ordinary hotkey. Raw dispatch waits until an accepted wheel choice has closed the wheel, and sends only while Skyrim is the foreground process; if focus has moved elsewhere, it fails closed. There is no `HoldKey` fallback. The `"KEY"` badge remains unchanged.

Raw slots require `PlayerSignals.dll` and Address Library for SKSE Plugins (use the VR Address Library for Skyrim VR); these are required only if your layout contains a `raw: true` slot. Without them, ordinary hotkeys continue to use Skyrim input as before. A raw layout with a missing DLL shows one warning per load at maintenance; a missing or incompatible DLL also makes raw selection fail closed with a notification and sends nothing. Restart Skyrim after updating the DLL or controller; load a save after changing JSON so the layout and any missing-DLL load warning apply.

The shipped Extras submenu contains the SkyrimNet dashboard raw hotkey. Add this flat authored slot to a wheel position:

```json
{ "label": "SN Dashboard", "hotkey": 64, "raw": true, "delayMs": 0 }
```

The dashboard raw-key example was owner-verified in the spike, not with this production DLL:

| Skyrim runtime | Evidence / remaining validation |
|---|---|
| AE 1.6.1170 | Dashboard owner-verified in the spike; production cases 1–6 still required. |
| AE 1.7.104 | Production in-game testing still required. |
| SE 1.5.97 | Build-only support; in-game untested. |
| VR | Build-only support; in-game untested. |

Labels, slot order, disabled slots, repeated supported intents, wheel names/submenus, and opening key are customizable without recompiling. UIExtensions supports at most eight slots; Magelight places twelve 30° slices clockwise from the top. Every shipped submenu puts Back at zero-based slot 10. Submenu, Back, Close and target-only actions use merged neckties. Only Submenu/Back neckties scale by 0.85 about the wheel centre, including hits, insets, selected bands, flow and label placement/fit; their stroke widths stay unchanged. Submenu and Back alone show the authored ChevronKnot with its V apex on the smaller outer tip and arms hugging the tip edges. The knot retains its approved absolute size and original stroke widths; tails may extend beyond the shortened outer edges. It lifts with its slice and stays hidden when disabled. Only Submenu/Back show two thin clipped arcs at radii 560 and 610, outside the hub's maximum pop, clipped to the active outline. Hotkeys have a flat-topped trapezoid cap and straight-chord pie with separate borders: either part selects the same key and lights both. Gesture cores and half-disc bulbs share a straight outer-corner chord without a fill gap or overlap sliver; insets, selected bands and flow clips follow it. The upright broadcast icon is centered in the half-disc's bounds at its existing size; ripple motion stays centered on the chord midpoint. Shift previews Openly on a gesture without changing page dispatch. SIGNAL, ACTION and KEY badges remain upright beneath wrapped labels; Submenu, Back, Close and null slots have no badge. Lit badges use their kind's idle fill, and navigation chevrons dim behind the label only; actual visible badges on other kinds remain respected. The selected band is 30 units wide (15 visible units), including the lit cap; its stroke width is 30. Slices lift to 1.06. All disabled slots use the same faint pointed necktie, not a split/trapezoid; actions without a target are disabled. Captured-target names and untampered custom labels are unchanged.

Center Cancel lifts to 1.08 on hover/focus using the same SVG-attribute ease-out-back tween as slices, and returns on leave/blur. The opaque octagon, its native frame and upright text scale together and paint last above all slices, arrows, labels and insets. Its painted paths take Cancel hit priority inside the moving outline; slices remain selectable immediately outside it. Core and merged outlines extend their existing straight sides to concealed inner points, including their inset lines, so no transverse inner cap appears during the bounce. Reduced motion or `--ps-tween: 0ms` snaps both hub and slice lifts, with no idle animation frames. Matching armed-only vignettes fade from 80% black at each screen edge to transparent at 25vh behind the wheel, title and ~20px two-line help, so they do not dim white cap highlights. The help substitutes the configured physical key's short name (or omits it if unmapped):

```text
Slice: target  ·  Tip or Shift: Openly
←/→ choose  ·  Enter select  ·  Esc / Right Alt / center: cancel
```

The shortened help does not remove controls: Up chooses a gesture's Openly bulb, Down returns to its core, Space also selects, and Tab cancels. On navigation, actions and hotkeys, Up and Down stay on the same slice; hotkey cap/pie have no Openly variant.

Optional top-level `"theme": "slate"` selects the Magelight idle palette; `moss` and `ember` are also supported. Unknown/non-string themes reject the layout; UIExtensions ignores this validated setting. Load a save to apply JSON changes. Hotkey cap/pie idle fills use muted teal: slate `#3d5a55`, moss `#3c5560`, ember `#3f5654`. Idle Submenu/Back fills use `--subnav-fill`: slate `#38392f`, moss `#2d3a2f`, ember `#402e2a`; their labels use `--subnav-label` `#bfb8a6` across themes. Without a slot colour override, selected navigation labels retain the existing `--nav-fill` colors. Hot pies/cores use `--selection-outline` bright yellow for fill and inset line, with a 30-unit `--selection-band` darker-yellow band (15 visible units, stroke width 30), including the lit cap. Lit gesture bulbs and hotkey caps instead use a white-centre (`#ffffff`) to pale warm-edge (`#fff4e8`) radial gradient, with no filters; the thin `#d9bd79` band and existing edge lines remain unchanged. The kind's idle fill swaps onto selected labels/badges: gesture blue/green/rust, action red, neutral navigation, teal hotkey, or the slot's custom colour. Core-only gesture selection leaves the bulb in its idle palette; bulb hover or Shift lights both. Reduced motion or zero `--ps-tween` makes lifts instant and flow static; choices dispatch without a fade-out delay. Typed Submenu/Back labels lose exactly one trailing navigation marker, not arbitrary authored text.
**Flow bands:** a selected gesture always animates its bulb, never its core, including the full Openly state. Actions and utilities animate chevrons; hotkey V-shaped flow stays in the inset pie only, while the cap remains lit without flow. Disabled actions and empty slots show none.

| Kind | Marks | Trail in real SVG units | Tint/blend |
|---|---:|---:|---|
| Signal bulb | 2 | `24 * (coreRadius / 320)` = 97.2 | Unlit: mint `#7fe6d4`, additive; lit: pale warm yellow `#fff1b8`, additive |
| Action | 4 | `46 * (coreRadius / 320)` = 186.3 | Warm white `#fff6e0`, additive on yellow |
| Utility/hotkey | 4 | 186.3 | Warm white `#fff6e0`, additive on yellow |

Each filled-gradient band travels for 2400 ms, holds its leading quarter solid, then fades with power 2.2 to a clear gap. Chevron peak `--flow-lit-opacity` is 0.35; bulb peaks `--flow-opacity` and `--flow-lit-signal-opacity` are 0.12. All receive a sine travel envelope. Unsupported additive blending uses normal blending with precomputed clamped tint/fill addition. Chevron half-width is `r * tan(15°) + 14 * (coreRadius / 320)`, height 0.45 times that width. Arc bands use radial gradients; chevrons use per-arm linear gradients, not stacked strokes. Ultralight blend support and repaint cost remain in-game-unverified.

One shared flow loop runs only while selected and stops on leave, blur, selection or disarm. Gesture Shift changes the ripple palette/state without suppressing the ripples. Frames update only SVG attributes, with no filters or per-frame layout reads; text bounds and fallback colors are cached on activation.

`intents.json` defines each supported ID and three required phrases: `narration`, group `notification`, and `targetedNotification`. It may also define `complianceNarration`; it is required for every intent used by a hybrid slot and otherwise optional. The compliance phrase is a full sentence fragment without a final period, contains one or more `{target}` markers and optional `{player}` markers, and permits no other, malformed, nested, or unbalanced brace markers. Each marker is substituted once from the original template; actor names are not reinterpreted as template syntax. Phrase values omit your character's name and final period; the other three phrases retain their existing `{target}` rule. Use plain JSON without comments or trailing commas. Both files are read on load, so changes apply after loading a save.

Shipped catalog: 24 IDs. The four shipped wheels contain 23 IDs; `dismiss` remains in the catalog, with its compliance phrase, but is unplaced and has no attached action in the shipped layout. The main wheel's slot 8 **Wait here** and slot 10 **Follow me** are the two hybrid signals, with `WaitHere` and `AccompanyTarget` actions. Extras slot 3 is the sole shipped action-only slot (`StopAccompanying`).

For exact schema rules and all shipped narration defaults, see the internal `docs-dev/specs/player-signals.md` and the installed [player guide](PlayerSignals/PlayerSignals-README.md).

## Build and checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1
# Rebuild the optional native DLL from PlayerSignals_native/ as well.
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1 -Native
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```
The root build automatically rebuilds the native project when its sources are newer; `-Native` forces that optional native build. Native project prerequisites and build details: [`PlayerSignals_native/README.md`](PlayerSignals_native/README.md).

For browser-only rendering QA, serve the checkout with `python -m http.server` and open `tests/test_magelight_wheel.html`. Run with normal/reduced-motion preferences; `?blend=normal` exercises the unsupported-additive fallback, including hover-color transitions. These checks do not launch Skyrim or prove Ultralight/native behavior.

The build generates 12 clockwise 30° sectors and inset outlines from shared parameters instead of cloning the Affinity 45° `Piece`, retaining vector ChevronKnot, Submenu and Upmenu art from `media/src/RadialUI.svg`. Inset lines use a 20-unit inset and 12-unit corner chamfers; the page renders their 9-unit stroke at about 1.75 px on a 700 px wheel. Export indentation is omitted from generated SVG without stripping authored SVG text spacing. The build rejects any source `<image>` element and checks generated IDs and references. Back is at slot 10 (300°, just above cardinal west) in every shipped submenu. The four shipped wheels are Main, Attitude, Social and Extras; all 24 catalog IDs remain available, while `dismiss` is intentionally unplaced. Main has Wait here at 8 and Follow me at 10 as hybrids; Extras has the SkyrimNet dashboard raw hotkey at 0, Journal at 1 and Stop following action-only at 3. Existing IDs appear once across the other main and submenu slots.

**SVG authoring contract:** keep authored glyphs as vectors in `media/src/RadialUI.svg`; any `<image>` fails the build. Geometry is generated as twelve clockwise 30° slices. Gesture half-discs paint before their opaque cores. Hotkey cap/pie polygons split at the same outer-corner chord and have their own inset outlines; the cap's flat top is 40% of that chord width. Selected bands are clipped to the inset outline interior. `$navScale = 0.85` in `build/build.ps1` emits the Submenu/Back-only geometry variant and publishes its scale for dependent page geometry; other kinds retain their original paths. Knot ancestry and affine tip-edge fitting are baked into path coordinates without scaling stroke widths. The approved 0.56 length fit remains unchanged; only a translation moves its apex from `(1800, 108)` to `(1800, 361.8)`, with arms within 3° of the adjacent edge directions. Tails may overhang the smaller necktie's outer corners. Slot rotation remains around `(1800, 1800)` outside the shared slice lift. Navigation/actions and every disabled slot retain the pointed merged outline. Inner points remain concealed beneath the opaque topmost hub. Utility arcs remain wheel-centered at radii 560 and 610 and lift with their slice. `utility-art-off` hides only legacy Submenu/Upmenu arrows, not typed submenu/back knots. Hidden geometry does not move label anchors.

The controller captures the NPC display name before opening Magelight and passes it through a JContainers value for Lua to read; the name is not interpolated into Lua source. The hub displays the captured name, falling back to **Target NPC** for an empty name. An absent target displays **No target · Openly**; pure action-only entries are disabled, while hybrids stay enabled as signals. Submission-time target validity checks remain unchanged.

Magelight's inspected page contract exposes mouse/keyboard input and `__uimode`, not flat-gamepad events or a controller-in-use signal (`D:/git/MagelightUI/README.md:68–74`, `docs/SDK.md:14–33`). The installed Papyrus API and built-in page examples expose no gamepad delivery API. Controller selection and A/X/Y prompts are therefore not implemented. Offline checks do not establish in-game Magelight or SkyrimNet behavior.

## License

PlayerSignals code and documentation are licensed under the [MIT License](LICENSE), copyright 2026 phospheneoverdrive. The installable mod includes its own copy of the license. Dependencies retain their own licenses and are not bundled.
