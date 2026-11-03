# PlayerSignals 0.2.0 (for SkyrimNet)

PlayerSignals is a configurable communication wheel for SkyrimNet. Gesture entries send authored direct narration; target-NPC action entries run registered SkyrimNet actions. Most gesture requests do not make NPCs respond. The two shipped hybrid signals add a compliance sentence when SkyrimNet agrees to run the action, but an NPC may not act straight away.

## Status

**Release status: 0.2.0 is not yet published.** Install from a published [GitHub release](https://github.com/Gerkinfeltser/PlayerSignals/releases) when available; do not use a GitHub source archive as the mod ZIP.

Magelight is the enabled renderer: twelve clockwise 30° slices, captured-target cores and **Openly** tips, with no-target Openly and Shift+hub Back. The old UIExtensions renderer is superseded and is not an alternative renderer.

- [Configuration](#configuration): supported slot kinds, schema constraints and authored phrases.
- [Player guide](PlayerSignals/PlayerSignals-README.md): packaged setup, customization and troubleshooting.
- [AI configuration helper](PlayerSignals/PlayerSignals-AI-Helper.md): copy-paste prompt, validator rules and worked merge instructions.
- [Build and checks](#build-and-checks): development commands and browser preview.

## What's new in 0.2.0

- Magelight twelve-slice wheel, target/Openly split, no-target Openly and Shift+hub Back.
- Intent, action, ordinary/raw hotkey and hybrid slots; per-slot colours and slate/moss/ember themes.
- Follow me and Wait here hybrids run the target action first; only API success adds compliance narration. Openly never runs the action.
- Bundled raw-key DLL with foreground guard and no HoldKey fallback.
- Stick aiming, A/B/X controls, optional `openGamepadButton`, and keyboard-always/pad-when-connected hint grid.
- 24 shipped catalog IDs (23 placed; `dismiss` remains available for customization).

Not included: hotkey slots with an alternate key, SkyrimNet status toggles, or JSON idle animations.

## Repository layout

```text
PlayerSignals/              Mod root; only this child folder belongs in MO2
PlayerSignals_spriggit/      Authored plugin records (outside the mod root)
PlayerSignals_native/        Native SKSE project, outside the installable payload
build/                       PowerShell build and local compiler flags
tests/                       Raw JSON/schema regressions executed on LuaJIT
```

The mod root contains `PlayerSignals.esp`, startup quest SEQ, three Papyrus scripts and compiled PEX files, the native `PlayerSignals.dll`, four default wheels, sibling layout and intent JSON, and a JContainers Lua loader. An optional prompt-only SkyrimNet bundle supplies the WebUI agent `playersignals_intent_helper`; it generates JSON for users to save from pasted configuration, not automatic file edits. Wheel dispatch does not depend on its manifest or external bundle, and no YAML triggers/actions are shipped.

## Dependencies and targeting

Required for the shipped layout: matching Skyrim SKSE and dependency versions, **Magelight 1.7.1+**, JContainers API 4 / feature 2 with Lua, SkyrimNet, the bundled **PlayerSignals.dll**, and **Address Library for SKSE Plugins** (use VR Address Library for Skyrim VR).

PlayerSignals needs `SkyrimNet.esp` loaded. Actions must be registered with SkyrimNet. Magelight 1.7.1 or newer is needed for the page's gamepad bridge. UIExtensions is not needed by players; its declarations remain a build input for dormant code.
Custom layouts without `raw: true` slots do not need the native DLL or Address Library. The shipped dashboard is raw, so the default layout needs both.

Before the wheel opens, PlayerSignals captures the current crosshair NPC. Moving the crosshair after opening does not change the recipient. The captured NPC must remain alive, enabled, and 3D-loaded when submitting; otherwise the selection is rejected. To make the NPC you aimed at the one chosen to answer, a targeted signal is sent as coming from that NPC, so SkyrimNet's event history may show it as from them, to you; the text still describes your character's gesture, and a reply is not guaranteed.

With no NPC captured, narration and feedback are addressed openly to everyone nearby. Magelight labels this destination **Openly** and offers sound-wave ripple arcs without a speaking-head symbol. Holding either Shift key through selection switches narration to group mode; hybrid actions do not run in Openly mode. Nearby witnesses may join, but nobody is guaranteed to reply.

Action-only slots run once on a valid captured NPC, with no direct narration or Shift conversion. Built-in `AccompanyTarget`, `StopAccompanying`, and `WaitHere` actions use SkyrimNet's eligibility checks; other registered actions have no eligibility check. PlayerSignals does not enforce action cooldowns. A local notification reports when an action request is refused or fails. An optional event records context after an action request succeeds; it does not confirm what happened in-game. PlayerSignals itself does not use direct animation or player-control APIs.

Hybrid slots combine an `intent` and `action` (without an `event`) and remain enabled as signal entries even without a target. Magelight shows them with a pointed bulb; plain signals have semicircular bulbs. The badge reads `SIGNAL · ACTION` when selecting the core would run the action, and `SIGNAL` otherwise. On a valid captured target without Shift, the action runs before the targeted narration. When SkyrimNet agrees to run the action, the catalog's compliance sentence is added; an NPC may not act straight away. A refused or failed request sends only the ordinary signal. In Openly mode, the action is skipped and only the group signal is narrated.

The captured NPC's display name appears in Magelight's hub; an empty name appears as **Target NPC**. With no captured NPC, the hub shows **No target · Openly**. Pure action-only entries are disabled up front; hybrid slots remain enabled because their signal still works openly.

## Installation and first use

Before installing or updating, back up your save and matching SKSE cosave, and preserve customized JSON. Install the mod ZIP from a published [GitHub release](https://github.com/Gerkinfeltser/PlayerSignals/releases) through MO2 and enable `PlayerSignals.esp`. Its Data root includes `PlayerSignals.esp`, `Scripts/`, `SEQ/`, `SKSE/` and `Magelight/`. GitHub source archives are not installable mod ZIPs; from a checkout install only **`PlayerSignals/`**, never the repository root. Install matching dependencies first. Replace old payload files, remove obsolete PlayerSignals dispatch triggers, and merge custom JSON against the current schema rather than blindly overwriting it. Restart Skyrim after DLL/scripts change, then load a save for maintenance/config reload. The optional prompt helper is not a dispatch trigger bundle.

Launch through SKSE and load a save or start a new game. If `SkyrimNet.esp` is not loaded, the PlayerSignals wheel stays off. In normal gameplay, press **Right Alt** to open the wheel and choose a gesture. A local notification confirms SkyrimNet received the request; SkyrimNet decides whether NPCs speak.

See the [player guide](PlayerSignals/PlayerSignals-README.md) for a quick walkthrough and examples.

### Existing saves, updates, and removal

Back up your save and matching SKSE cosave before installing, updating, or removing PlayerSignals. Startup is designed to initialize on existing saves. The mod rebuilds its private native maps from both JSON files when a save loads.

PlayerSignals does not add gesture spells, edit NPC world records, or toggle player controls. Saves may retain quest or script state, and the mod does not remove that state when uninstalled. For the safest rollback, restore a save and matching SKSE cosave from before installation. SkyrimNet may retain narration history separately; restoring a Skyrim save does not erase it.

## Configuration


Optional `input.openGamepadButton` binds one button as an alternate open/cancel key. It is absent from the shipped layout; if set, use a distinct integer `266–281` (SKSE `InputMap.h`):

| Button | Code | Button | Code |
|---|---:|---|---:|
| D-pad Up | 266 | D-pad Down | 267 |
| D-pad Left | 268 | D-pad Right | 269 |
| Start | 270 | Back | 271 |
| Left Thumb | 272 | Right Thumb | 273 |
| Left Shoulder | 274 | Right Shoulder | 275 |
| A | 276 | B | 277 |
| X | 278 | Y | 279 |
| Left Trigger | 280 | Right Trigger | 281 |

The game may still perform its normal action for the configured button.

Each wheel supports 1–12 ordered slots, placed clockwise from slot 0 at the top. A slot is `null` (disabled) or has a nonempty label and one primary kind: `intent`, `action`, `submenu`, `control` (`back` / `close`), or `hotkey`. An intent plus action without event is a hybrid; action+event+intent is legacy pure-action context and sends no direct narration. Hotkeys accept integer codes 1–263 (keyboard 1–255, mouse 256–263), `delayMs` 0–2000 (default 100) and `holdMs` 1–2000 (default 50); their code must differ from `input.openKeyCode`. Optional `raw` is a strict boolean and true permits keyboard codes only. All referenced intents/wheels and catalog records are checked; unknown fields, wrong types, broken references, cycles and oversized wheels stop the layout from loading. Exact rules are in the specification.

In Magelight, any non-null slot can override its idle colour with a six-digit hex string (`#rrggbb`, either letter case):

```json
{ "label": "Greet", "intent": "greet", "color": "#4a6b5c" }
```

The fill override changes idle colour only, not the standard yellow selected fill, band or white caps; lit labels and badges use the chosen idle colour. Disabled slots keep their shared disabled look, and theme changes do not replace slot colours. Very light or very dark colours can hurt label readability. The shipped layout colours only Yes/Agree (green) and No/Disagree (red).

Custom-coloured gesture bulbs derive their unlit ripple tint from the slot colour (lower hue, increased HSL lightness); uncoloured ripples stay mint and lit-bulb ripples stay warm yellow, all at the existing `0.12` strength.

### Make the wheel your own

For a custom slot that clicks the **middle mouse button** (SKSE code `258`), add this object to a wheel without exceeding 12 slots:

```json
{ "label": "Middle mouse", "hotkey": 258, "delayMs": 100, "holdMs": 50 }
```

The shipped Extras submenu has one raw hotkey slot: the SkyrimNet dashboard (scan code 64). Hotkeys press only after the wheel/view fully closes, need no target, ignore Shift, and emit no narration or success notification. The code must differ from the configured opening key; timing defaults and strict ranges are listed above. This injected press reaches mods that read Skyrim's own input; mods that poll Windows key state directly see raw hotkeys only.

#### Raw keyboard hotkeys

Set `"raw": true` on a hotkey slot to send a Windows scan-code key press for mods that poll Windows key state. It is valid only for keyboard scan codes 1–255; mouse codes 256–263 cannot be raw. `"raw": false` is allowed but behaves like an ordinary hotkey. Raw input is sent after you select a slot and the wheel closes, and only while Skyrim is the foreground window; if focus has moved elsewhere, nothing is sent. There is no `HoldKey` fallback. The `"KEY"` badge remains unchanged.

Raw slots need `PlayerSignals.dll` and Address Library for SKSE Plugins (use VR Address Library for Skyrim VR); these are needed only if your layout contains a `raw: true` slot. Without them, ordinary hotkeys continue to use Skyrim input. If the DLL is missing or incompatible, a raw selection shows a notification and sends nothing. Restart Skyrim after updating the DLL or controller; load a save after changing JSON so the layout is reloaded.

The shipped Extras submenu contains the SkyrimNet dashboard raw hotkey. Add this flat authored slot to a wheel position:

```json
{ "label": "SN Dashboard", "hotkey": 64, "raw": true, "delayMs": 0 }
```

Labels, order, disabled slots, repeated intents, wheel names/submenus and opening inputs are customizable without recompiling. Every shipped submenu has Back at zero-based slot 10. Submenu/Back use 0.85-scale narrowed neckties and vector ChevronKnot art; actions, hotkeys and signals have distinct geometry. Hotkey cap and pie select the same key, never Openly. Signals use round Openly bulbs; hybrids show pointed bulbs only while the core would run an action, with a stable pointed hit envelope during the visible Openly-round transition. Label fitting wraps/shrinks without truncation. See the player guide for detailed artwork and motion behavior.

Center Cancel lifts to 1.08 on hover/focus using the same SVG-attribute ease-out-back tween as slices, and returns on leave/blur. The opaque octagon, its native frame and upright text scale together and paint last above all slices, arrows, labels and insets. Its painted paths take Cancel hit priority inside the moving outline; slices remain selectable immediately outside it. Core and merged outlines extend their existing straight sides to concealed inner points, including their inset lines, so no transverse inner cap appears during the bounce. Reduced motion or `--ps-tween: 0ms` snaps both hub and slice lifts, with no idle animation frames. Matching armed-only vignettes fade from 80% black at each screen edge to transparent at 25vh behind the wheel, title and ~20px two-line help, so they do not dim white cap highlights. The help substitutes the configured physical key's short name (or omits it if unmapped):

```text
Slice: target  ·  Tip: Openly
Choose [←/→] (Stick)    Select [Enter] (A)
Openly [Shift] (X)      Cancel [Esc] [Right Alt] (B)
```

The shortened help does not remove controls: Up chooses a gesture's Openly bulb, Down returns to its core, Space also selects, and Tab cancels. On navigation, actions and hotkeys, Up and Down stay on the same slice; hotkey cap/pie have no Openly variant.

Keyboard keycaps are always shown in the two-column action hint; Stick and muted Xbox-colour A/B/X badges appear inline only while a controller is available, and Cancel names the configured opening key. The left stick aims at twelve angles above a `0.35` deadzone; returning inside it focuses the hub after a **100 ms** release grace. Aim and press **A** while deflected to select a slot; a quick A during spring-back still selects it. A at the hub cancels, or goes Back while X is held in a submenu. D-pad Up/Left steps backward, Down/Right forward and retains focus through neutral stick events. Hold X for Openly signals, hybrid badge/tint and hub Back preview; B cancels. Empty and disabled slots are not focused.

Optional top-level `"theme": "slate"` selects the idle palette; `moss` and `ember` are also supported. Unknown/non-string themes reject the layout. Load a save to apply changes. Explicit per-slot colours survive theme changes, disabled slots keep their shared look, and common yellow selected fills/white caps are preserved. Reduced motion or zero `--ps-tween` makes lifts instant and flow static; selection has no fade-out delay. Magelight strips exactly one generated Submenu/Back navigation suffix, never arbitrary authored text.
**Flow bands:** a selected gesture always animates its bulb, never its core, including the full Openly state. Actions and utilities animate chevrons; hotkey V-shaped flow stays in the inset pie only, while the cap remains lit without flow. Disabled actions and empty slots show none.

| Kind | Marks | Trail in real SVG units | Tint/blend |
|---|---:|---:|---|
| Signal bulb | 2 | `24 * (coreRadius / 320)` = 97.2 | Unlit: mint `#7fe6d4`, additive; lit: pale warm yellow `#fff1b8`, additive |
| Action | 4 | `46 * (coreRadius / 320)` = 186.3 | Warm white `#fff6e0`, additive on yellow |
| Utility/hotkey | 4 | 186.3 | Warm white `#fff6e0`, additive on yellow |

Each filled-gradient band travels for 2400 ms, holds its leading quarter solid, then fades with power 2.2 to a clear gap. Chevron peak `--flow-lit-opacity` is 0.35; bulb peaks `--flow-opacity` and `--flow-lit-signal-opacity` are 0.12. All receive a sine travel envelope. Unsupported additive blending uses normal blending with precomputed clamped tint/fill addition. Chevron half-width is `r * tan(15°) + 14 * (coreRadius / 320)`, height 0.45 times that width. Arc bands use radial gradients; chevrons use per-arm linear gradients, not stacked strokes. Additive blending may vary by renderer.

One shared flow loop runs only while selected and stops on leave, blur, selection or disarm. Gesture Shift changes the ripple palette/state without suppressing the ripples. Frames update only SVG attributes, with no filters or per-frame layout reads; text bounds and fallback colors are cached on activation.

`intents.json` defines each supported ID and three required phrases: `narration`, group `notification`, and `targetedNotification`. It may also define `complianceNarration`; it is required for every intent used by a hybrid slot and otherwise optional. The compliance phrase is a full sentence fragment without a final period, contains one or more `{target}` markers and optional `{player}` markers, and permits no other, malformed, nested, or unbalanced brace markers. Each marker is substituted once from the original template; actor names are not reinterpreted as template syntax. Phrase values omit your character's name and final period; the other three phrases retain their existing `{target}` rule. Use plain JSON without comments or trailing commas. Both files are read on load, so changes apply after loading a save.

Shipped catalog: 24 IDs. The four shipped wheels contain 23 IDs; `dismiss` remains in the catalog, with its compliance phrase, but is unplaced and has no attached action in the shipped layout. The main wheel's slot 8 **Wait here** and slot 10 **Follow me** are the two hybrid signals, with `WaitHere` and `AccompanyTarget` actions. Extras slot 3 is the sole shipped action-only slot (`StopAccompanying`).

See [Configuration](#configuration) for schema constraints; authored narration defaults remain in `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json`. The [player guide](PlayerSignals/PlayerSignals-README.md#make-the-wheel-your-own) includes customization examples.

## Build and checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1
# Rebuild the optional native DLL from PlayerSignals_native/ as well.
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1 -Native
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```
The root build automatically rebuilds the native project when its sources are newer; `-Native` forces that optional native build. Native project prerequisites and build details: [`PlayerSignals_native/README.md`](PlayerSignals_native/README.md).

To preview the wheel outside the game, serve the checkout with `python -m http.server` and open `tests/test_magelight_wheel.html`. Run with normal/reduced-motion preferences; `?blend=normal` previews the normal-blending fallback, including hover-colour transitions. This browser preview does not run Skyrim.

The build generates 12 clockwise 30° sectors and inset outlines from shared parameters instead of cloning the Affinity 45° `Piece`, retaining vector ChevronKnot, Submenu and Upmenu art from `media/src/RadialUI.svg`. Inset lines use a 20-unit inset and 12-unit corner chamfers; the page renders their 9-unit stroke at about 1.75 px on a 700 px wheel. Export indentation is omitted from generated SVG without stripping authored SVG text spacing. The build rejects any source `<image>` element and checks generated IDs and references. Back is at slot 10 (300°, just above cardinal west) in every shipped submenu. The four shipped wheels are Main, Attitude, Social and Extras; all 24 catalog IDs remain available, while `dismiss` is intentionally unplaced. Main has Wait here at 8 and Follow me at 10 as hybrids; Extras has the SkyrimNet dashboard raw hotkey at 0, Journal at 1 and Stop following action-only at 3. Existing IDs appear once across the other main and submenu slots.

**SVG authoring contract:** keep authored glyphs as vectors in `media/src/RadialUI.svg`; any `<image>` fails the build. Geometry is generated as twelve clockwise 30° slices. Gesture half-discs paint before their opaque cores. Hotkey cap/pie polygons split at the same outer-corner chord and have their own inset outlines; the cap's flat top is 40% of that chord width. Selected bands are clipped to the inset outline interior. `$navScale = 0.85` in `build/build.ps1` emits the Submenu/Back-only geometry variant and publishes its scale for dependent page geometry; other kinds retain their original paths. Knot ancestry and affine tip-edge fitting are baked into path coordinates without scaling stroke widths. The approved 0.56 length fit remains unchanged; only a translation moves its apex from `(1800, 108)` to `(1800, 361.8)`, with arms within 3° of the adjacent edge directions. Tails may overhang the smaller necktie's outer corners. Slot rotation remains around `(1800, 1800)` outside the shared slice lift. Navigation/actions and every disabled slot retain the pointed merged outline. Inner points remain concealed beneath the opaque topmost hub. Utility arcs remain wheel-centered at radii 560 and 610 and lift with their slice. `utility-art-off` hides only legacy Submenu/Upmenu arrows, not typed submenu/back knots. Hidden geometry does not move label anchors.

Submenu/Back cores use `$navWidth = 0.7`: shoulders are 30% narrower and slide along the unchanged knot arms, preserving the inner point, outward tip and knot artwork. Hits, inset edges, selected bands and clips use that outline; label fitting derives its side slope from the narrowed core without truncation. Other slot kinds retain their original geometry.

The controller captures the NPC display name before opening Magelight and passes it through a JContainers value for Lua to read; the name is not interpolated into Lua source. The hub displays the captured name, falling back to **Target NPC** for an empty name. An absent target displays **No target · Openly**; pure action-only entries are disabled, while hybrids stay enabled as signals. Submission-time target validity checks remain unchanged.

Pad support uses the gamepad bridge embedded in the installed Magelight **1.7.1** DLL: `magelight.gamepad.getState()`, `onStateChange()` and `onAction()`. The manifest uses `"gamepad": "navigation"` because the bridge dispatches raw action/vector callbacks only for that style; `"keys"` is keyboard emulation. PlayerSignals consumes `leftStick` change vectors (positive Y up), D-pad controls, `west` (X), and accept/cancel actions directly, with no generic navigation scope or stick-generated arrows. Older public SDK typings do not describe this bridge.

## License

PlayerSignals code and documentation are licensed under the [MIT License](LICENSE), copyright 2026 phospheneoverdrive. The installable mod includes its own copy of the license. Dependencies retain their own licenses and are not bundled.
