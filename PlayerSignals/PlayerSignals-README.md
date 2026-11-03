# PlayerSignals 0.2.0: a little less talking, a little more nodding

Want to agree, say thanks, or give someone a puzzled look without typing a sentence? PlayerSignals gives you a small communication wheel with 24 shipped intent defaults; the JSON catalog can add more intents. SkyrimNet receives authored direct narration describing what your character means.

Most signals are requests, not forced compliance. Two shipped hybrid signals—Follow me and Wait here—also request a target-NPC action. On eligible targeted selections, the action runs first; if SkyrimNet's `ExecuteAction` returns `0`, one direct narration includes a compliance sentence. This API acceptance does not prove an in-game effect or NPC response.

## What's new in 0.2.0

- Magelight 1.7.1+ is the enabled twelve-slice wheel renderer, with per-slot colours and slate/moss/ember themes. UIExtensions is superseded, not a runtime fallback or requirement.
- Hybrid Follow me and Wait here run their action before narration; compliance wording is included only after action API success.
- Targeted slice cores and Openly tips, no-target Openly, Shift+hub Back, raw dashboard keys with foreground guard/no fallback, optional gamepad opening and stick/A/B/X navigation.
- 24 catalog IDs, 23 placed in the shipped layout; `dismiss` is available for customization. Hotkey alternate keys, SkyrimNet status toggles and JSON idle animations are not included.

## Test release status

This is 0.2.0 release preparation, not a newly published release or exhaustive runtime acceptance. Targeted/group gestures and an expected no-audience result were observed on the older 2026-10-02 build, with the player as narration originator. Those historical observations do not verify the production Magelight wheel, hybrid actions, raw DLL or gamepad paths.

Mid-save removal has been tested on **one ADT save**. Disabling the mod left saved Papyrus remnants; a ReSaver-cleaned copy subsequently loaded without PlayerSignals missing-script warnings. This is limited test evidence, not a guarantee of clean removal or long-term save safety. See [Updating or removing](#updating-or-removing), and back up your saves before testing.

## Before you start

You'll need:

- Matching SKSE and dependency builds for your Skyrim SE/AE/VR runtime. Launch through SKSE; native target flags are not runtime acceptance on every version.
- JContainers with its Lua support files (API 4 / feature 2).
- SkyrimNet, with `SkyrimNet.esp` loaded and its native API available.
- Magelight **1.7.1+** with its matching runtime for the wheel and embedded gamepad bridge. The older `minHost: 0.31.2` manifest/Papyrus check remains a host-API threshold, not full-feature compatibility.
- For action entries, SkyrimNet with `IsActionRegistered`, `ExecuteAction`, the built-in `SkyrimNetInternal` eligibility functions, and optional persistent/short-lived event APIs.
- The bundled **PlayerSignals.dll** (native API 1, DLL package 1.0.0) and **Address Library for SKSE Plugins**, or VR Address Library on VR. The shipped dashboard slot is raw and requires both; a custom layout with no raw hotkeys does not.

Back up your save and matching SKSE cosave before installing or updating. The startup quest and player-alias save-load handling are designed to initialize PlayerSignals on existing saves. The limited removal test below does not establish installation/update compatibility with every existing save.

Install the release mod ZIP with your mod manager and enable **PlayerSignals.esp**. Its Data root contains `PlayerSignals.esp`, `Scripts`, `Seq`, `SKSE` and `Magelight`; this readme belongs alongside them. From a checkout install only the `PlayerSignals/` child, never the repository root or GitHub source archive. Before upgrading, preserve custom JSON, replace old payload files, then merge customizations against the shipped schema. Remove obsolete PlayerSignals dispatch YAML triggers; the optional prompt-only helper is separate. Restart Skyrim after DLL/script updates, then load a save so maintenance reloads the configuration.

Start the game and load a save, or begin a new game. PlayerSignals checks for SkyrimNet.esp and a nonempty native API build version at startup; if either is missing, the feature stays disabled. No MCM setup is required, and no external trigger bundle is needed.


## Your first gesture

1. In normal gameplay, look toward the NPC you want to address, if there is one.
2. Press **Right Alt** to open the wheel. PlayerSignals captures the crosshair NPC before showing it.
3. Choose a communication entry, such as **Yes** or **Greet**.

If the captured NPC is still alive, enabled, and loaded when you choose, SkyrimNet receives a targeted narration with your character as the originator (`From`) and the captured NPC as the explicit target. The text describes your character making the gesture and addresses that NPC by name. Moving the crosshair while the wheel is open does not change the submitted target. SkyrimNet still chooses who responds; the captured NPC is not guaranteed to be the responder, and Recent Events may show the selected responder under `To`. Magelight's hub displays the captured NPC's display name, or **Target NPC** if that name is empty.

You'll see a small notification with your character's name only if SkyrimNet's API accepts the narration. For the **Greet** intent, group feedback looks like `Bill greets.`; targeted feedback to the captured NPC Ted looks like `Bill greets Ted.` Think of it as a receipt—not a promise that an NPC heard you or will answer.

Choose **Social** to open a submenu and **Back** to return. Back occupies zero-based slot 10 (300°, just above cardinal west) in every shipped submenu. **Tab**, center-click, **Escape**, or a fresh press of the configured opening key cancels once armed (default **Right Alt**). Holding/repeating or the initial pre-arm opening press does not cancel. An unmapped browser opening code produces one console warning; Tab/Escape/center still work. Navigation/cancellation sends no narration.

In Magelight, holding either **Shift** changes the hub to **Back** when the current wheel has a Back entry. Click the hub, or focus it and press **Enter/Space**, to use that same Back entry. Releasing Shift restores Cancel; the root wheel and wheels without a Back entry stay Cancel. **Escape**, **Tab**, and the configured opening key still cancel even with Shift held. Gesture Openly preview is unchanged.

**Magelight wheel:** twelve 30° slices run clockwise from the top. Gesture cores target the captured NPC; semicircular bulbs select Openly. Core and bulb share a straight outer-corner chord without a fill gap or overlap sliver. Their insets, selected bands and flow clips follow that outline; the upright broadcast icon is centered in the half-disc's bounds, while ripple motion retains its chord-midpoint pivot. Shift previews Openly without changing page dispatch. A selected core turns bright yellow with a darker-yellow inner band; its idle kind colour moves onto the label/badge. Bulb hover/Shift lights both pieces; only the bulb uses a white-centre (`#ffffff`) to pale warm-edge (`#fff4e8`) radial gradient, with no filters and its thin `#d9bd79` band. Navigation/actions retain pointed neckties; hotkeys instead split into a flat trapezoid cap and chord-edged pie. Both hotkey parts are muted teal when idle. Either part lights both and dispatches the same key; the cap lights with the same white-centre-to-warm-edge gradient while the pie remains bright yellow with a darker-yellow inner band, and only the inset pie carries V-shaped flow. The selected cap's thin band remains unchanged. Labels and their SIGNAL (gesture), ACTION or KEY badges run along each slice; straight-up/down slots stay horizontal, and left-half text is flipped to remain readable. Badges stay directly beneath wrapped labels in the same rotated frame, and use their kind's idle colour when lit. Text wraps or shrinks to fit clear of the hub, cap chord and navigation artwork, without truncation. Submenu, Back, Close and null slots have no badge. Navigation chevrons dim behind the label only; actual visible badges on other kinds remain respected. Every disabled slot uses the same faint pointed necktie, including disabled hotkeys. Slices lift to 1.06; choices dispatch immediately. Reduced-motion preferences are honored. The wheel, title and help paint above the backdrop vignettes. These browser-facing details do not prove in-game acceptance.

Two fixed white diagonal diameters divide every wheel into four groups of three slices. They sit behind all wheel artwork, remain still when slices lift, and do not take clicks. Their stroke is 1.75 px at a 700 px wheel, at 90% opacity in all three themes.

Center Cancel lifts to 1.08 and always paints above the slices, concealing their inner points. Only Submenu and Back show two thin clipped arcs at radii 560 and 610, outside the hub's maximum pop; hotkey, Close, gesture, action and empty slots show none. Only Submenu and Back neckties are 0.85× about the wheel centre; their hits, insets, selected bands, flow, labels and utility clips follow the smaller outline, without changing stroke widths. They display the owner's knot at its approved absolute size, translated so its V apex caps the new outer tip and both arms hug the tip edges like an arrowhead. Tails may overhang the shortened outer edges. The knot lifts with the slice and hides when disabled. Close/hotkeys/actions show no knot and keep their original geometry, as do empty slots. Legacy Submenu/Upmenu arrows remain hidden. Matching top/bottom vignettes cover the outer quarter-screen while armed; title/help remain above them. The two-line help reads `Slice: target · Tip or Shift: Openly` and `←/→ choose · Enter select · Esc / Right Alt / center: cancel`, substituting the configured key's name. Tab, Up/Down and Space remain available; actions are target-only.

Selected gestures show two scaled arc bands only in the bulb, including Openly/Shift full selection. With only the core selected, the blue bulb uses subtle additive mint bands; a lit bulb uses pale warm-yellow additive ripples at the same low 0.12 peak. The selected band is 30 units wide (15 visible units), including the lit cap; its stroke width is 30. Only actually visible badges contribute to flow dimming, so navigation chevrons dim behind the label alone. Actions and other utilities use four warm-white (`#fff6e0`) additive chevrons at peak 0.35, with clamped-addition normal-blend fallback. Hotkey V-shaped flow stays in the inset pie only; the cap remains lit without flow. Labels/badges remain readable. Bands travel every 2.4 seconds, stop on leave/blur/close/selection, and stay static under reduced motion or zero tween. Disabled actions and empty slots show none.

Click a gesture's core for the captured target or its bulb for **Openly**. **Left/Right** moves among available entries; **Up** chooses a gesture's bulb, **Down** its core; **Enter/Space** confirms. Up/Down stays on the same navigation/action/hotkey slice. Both hotkey parts dispatch the same key, never Openly. Merged neckties remain selectable at their pointed end; actions stay target-only.

With Magelight's 1.7.1 gamepad bridge, the **left stick** aims at a slot; returning within the `0.35` deadzone focuses the hub after **100 ms**, allowing quick A during spring-back. Aim and press **A** to select; A at the hub cancels or goes Back while X is held in a submenu. **D-pad Up/Left** chooses previous, **Down/Right** next, retaining focus through neutral stick events. **B** cancels; hold **X** for Openly signals and submenu hub Back. Actions/hotkeys never become Openly signals. The two-column hint grid always shows keyboard keycaps; Stick and A/B/X badges appear inline only while a controller is available. Cancel names the configured keyboard opening key. Prior browser checks are not production in-game proof.

The wheel won't open while you're in a blocking menu, another custom menu, or a gameplay state where the required controls are disabled.

## Who are you talking to?

The NPC under your crosshair when the wheel opens is captured for that choice. Moving your crosshair while the wheel is open does not change the captured NPC. For a targeted selection, if that NPC is no longer alive, enabled, and loaded, PlayerSignals fails closed: it does not silently choose a different NPC or switch to everyone. Shift or the Magelight gesture's explicit **Openly** destination intentionally chooses group mode instead.

If no NPC was captured, the Magelight hub shows **No target · Openly** and gesture narration is addressed to everyone nearby. You can also choose that mode intentionally: hold either **Left Shift** or **Right Shift** through the selection until the wheel closes. PlayerSignals checks Shift when the final selection returns from the wheel; it does not promise to sample the exact click instant. Shift overrides a captured NPC and uses group narration and feedback without that NPC's name.

With no captured NPC, selecting either part of a gesture lights both the core and its bright white Openly bulb without Shift. With a captured NPC, core selection leaves the bulb unlit unless Shift is held; selecting the bulb still shows Openly.

Action-only entries require a captured NPC and have no Openly destination; without a target they are disabled before selection, and Shift does not convert them to group mode. Hybrid signal+action entries are different: they stay selectable without a target because they still work as ordinary signals. In Magelight hybrids keep the signal's pie, straight chord and existing flow, but use a pointed teardrop/onion bulb; plain signals keep semicircular bulbs. A lit hybrid bulb is white through its point with the existing warm rim. The badge reads `SIGNAL · ACTION` only when selecting that slot's core would run its action: a captured target is available, neither Shift key is held, and that slot's tip is not hovered/focused. Otherwise it reads `SIGNAL`. The badge swaps back immediately without changing its reserved frame. There is no added notch, crust or flow. With a valid captured target and no Shift, the controller applies registration and built-in eligibility checks, runs the action once, then sends exactly one `DirectNarration`. Only an `ExecuteAction` result of `0` adds the `complianceNarration` sentence. If the action is refused or fails, narration is exactly the ordinary targeted signal, with no compliance sentence and no extra notification. For hybrids in Openly mode (no target or either Shift held), the action is skipped and only the group signal is narrated. The local player-named receipt remains governed by `DirectNarration` returning `0`; failures, stale targets/sessions and cancellation do not create a second narration or notification.

The shipped hybrid signals are Main slot 8 **Wait here** (`WaitHere`) and Main slot 10 **Follow me** (`AccompanyTarget`). The catalog also includes `dismiss` and its compliance phrase, but Dismiss is unplaced and has no action attached in the shipped layout; the owner checklist below covers it only for a custom hybrid placement. Extras has one action-only entry, Stop following (`StopAccompanying`), at slot 3.

### A note about Recent Events

PlayerSignals now always supplies your character as the narration originator (**From**), including gestures addressed to a captured NPC. An NPC can still appear under **From** on their own dialogue reply; that is a separate event, not the NPC performing your gesture.

The remaining limitation is **To**: SkyrimNet selects a responder and can put that NPC in the event's target field. A group gesture may therefore appear as Bill → Ted even though the narration explicitly addresses everyone nearby. If nobody is in earshot and no responder is selected, there may be no **To** value and no reply.

Read the narration for the intended audience; it names your character and explicitly addresses the captured NPC or **everyone nearby**. The local notification also distinguishes targeted and group submissions. This version corrects the player-originator arguments, but it does not separate intended audience from selected responder inside SkyrimNet's event metadata.


## What's on the wheel?

These are the displayed Magelight labels, with zero-based positions:

| Wheel | Entries |
|---|---|
| Main | 0 Greet, 1 Thank you, 2 Sorry, 3 No/Disagree, 4 Social, 5 Attitude, 6 Farewell, 7 Extras, 8 Wait here, 9 Yes/Agree, 10 Follow me, 11 Come here |
| Attitude | 0 Challenge, 2 Quiet, 3 Not understood, 4 Unsure, 6 Surrender, 8 Let me think, 9 Understood, 10 Back |
| Social | 0 Offer, 2 Comfort, 3 Watch out, 4 Calm down, 6 Request, 8 Well done, 9 Give space, 10 Back |
| Extras | 0 SN Dashboard (raw key 64), 1 Journal (key 36, J), 3 Stop following (`StopAccompanying`), 10 Back |

Positions are zero-based and unlisted positions are null.

A few distinctions are worth keeping:

- **Yes** (`confirm`) covers both agreement and approval; **No** (`deny`) covers disagreement and disapproval.
- **Unsure** means you're uncertain; **Understood** and **Not understood** say whether you followed.
- **Give space** asks for distance, the opposite of **Come here**.
- **Comfort** offers reassurance; **Well done** congratulates.
- **Offer** and **Request** suggest giving or asking for something. They don't move items or name a particular object.

Quiet and the other gestures are requests, not remote controls for NPCs. Follow me and Wait here are the shipped hybrids: they narrate as signals in every mode, and request the corresponding action only for an eligible captured target without Shift. Compliance wording is included only after action API success. `dismiss` is available in the catalog but unplaced; adding it to a custom hybrid slot requires its matching action and compliance phrase. The Extras submenu has one action-only slot, Stop following.

## Make the wheel your own

Open the PlayerSignals folder in your mod manager and find these files:

```text
SKSE/Plugins/PlayerSignals/layout.json
SKSE/Plugins/PlayerSignals/intents.json
```

`layout.json` controls wheels, labels, and the opening key. `intents.json` defines supported IDs and their narration and notification phrases. Back up both files before editing. Use a plain-text editor, save changes, then **load a save** to apply them. Neither file reloads live or gets written back by the mod.

In **MO2**, these are paths inside the installed mod folder—not a `Data` folder inside it. Open the PlayerSignals mod folder and look under `SKSE/Plugins/PlayerSignals/`, typically `<instance>/mods/<installed PlayerSignals folder>/SKSE/Plugins/PlayerSignals/`. If a matching file exists in `overwrite/SKSE/Plugins/PlayerSignals/` or another higher-priority mod, check MO2's Data/conflict view and edit the winning copy. The configs do not automatically belong in overwrite. For a manual install, their game-facing paths are `Data/SKSE/Plugins/PlayerSignals/...`.

You can change labels, reorder entries, move supported intents between wheels, make submenus, disable slots, and change the opening key in `layout.json`. Edit or add IDs and phrase text in `intents.json`. A new ID must also be referenced by a layout entry. These JSON edits need no script recompilation.

### Hotkey slots

A hotkey slot normally presses its DirectX scan code after the wheel has fully closed; it needs no captured target, ignores Shift, and does not narrate or notify. For example, add this entry to click the **middle mouse button** (SKSE code `258`):

```json
{ "label": "Middle mouse", "hotkey": 258, "delayMs": 100, "holdMs": 50 }
```

`hotkey` must be a strict integer from 1–263 (1–255 keyboard scan codes; 256–263 SKSE mouse buttons, e.g. 258 = middle mouse) and cannot equal the configured `input.openKeyCode`. `delayMs` is optional (default `100`, integer 0–2000); `holdMs` is optional (default `50`, integer 1–2000). These timing fields are hotkey-only. A hotkey is exclusive with `intent`, `submenu`, `control`, and `action`. Dispatch occurs only after the browsing session and Magelight view have fully released.

For keyboard hotkeys, optional `"raw": true` sends a Windows scan-code key press for mods that poll Windows key state. It is allowed only for hotkeys with scan codes 1–255; `raw: false` is allowed and leaves ordinary hotkey behavior unchanged. Raw presses are sent only after an accepted wheel choice closes and only while Skyrim is the foreground process. If focus has moved elsewhere, dispatch fails closed; there is no `HoldKey` fallback. A raw layout with a missing DLL gets one warning per load at maintenance; a missing or incompatible DLL also fails raw selection closed with a notification and sends nothing. The badge remains **KEY**. Raw slots require `PlayerSignals.dll` and Address Library for SKSE Plugins (the VR Address Library for Skyrim VR), but these dependencies are needed only when a layout has a `raw: true` slot. Layouts without raw slots continue to use normal Skyrim input; mods polling Windows key state directly do not receive those ordinary injected keys.

Add the example to a wheel position. The authored `raw` flag is flat beside `hotkey`; the page payload carries it in its fourth extras object as `{ "raw": true }`, combined with an optional color as `{ "color": "#aabbcc", "raw": true }`. `raw: false` is omitted from page extras.

```json
{ "label": "SN Dashboard", "hotkey": 64, "raw": true, "delayMs": 0 }
```

The owner verified the dashboard raw-key example in the spike, not this production DLL:

| Skyrim runtime | Current evidence |
|---|---|
| AE 1.6.1170 | Dashboard owner-verified in the spike; this production DLL still needs in-game testing. |
| AE 1.7.104 | Production in-game testing still required. |
| SE 1.5.97 | Build-only support; in-game untested. |
| VR | Build-only support; in-game untested. |

Restart Skyrim after a DLL or controller update. Load a save after JSON edits to apply the layout and missing-DLL load warning.

### Wheel colour theme (Magelight)

Add one optional top-level property in `layout.json`, alongside `schemaVersion`, `root`, `input` and `wheels`:

```json
"theme": "moss",
```

Choose `slate` (default grey/blue-slate and gold), `moss` (muted green) or `ember` (muted rust). Keep the comma between JSON properties; unknown names/non-strings reject the layout. Load a save to apply it. Submenu/Back idle fills are slate `#38392f`, moss `#2d3a2f`, ember `#402e2a`, with `#bfb8a6` labels. Without a slot override, selected navigation labels retain their theme's navigation colour. Cream text and Chevron/Knot line colours remain common.

### Per-slot colours (Magelight)

Any non-null entry can add `color` as exactly `#` plus six hexadecimal digits, using either letter case:

```json
{ "label": "Greet", "intent": "greet", "color": "#4a6b5c" }
```

This changes idle colour on both gesture/hotkey parts or the action/navigation necktie, plus lit label/badge colour. Selected fills stay yellow with the common band/white caps; disabled entries keep their shared look. Slot colours survive theme changes. Very light/dark colours can impair readability. Names, short hex codes, `rgb()` and non-strings reject the layout. The shipped overrides are Yes/Agree green and No/Disagree red.

Custom-coloured gesture bulbs also derive their unlit ripple tint from the slot colour, with a lower hue and increased HSL lightness at the same strength. Uncoloured bulbs keep mint ripples, and lit bulbs keep warm yellow ripples.

### Rename or move an entry

An entry looks like this:

```json
{ "label": "Request", "intent": "ask" }
```

`label` is the text you see. `intent` is what the selection means. Rename the label to suit you, but keep the intent ID unless you want a different gesture.

Move the entire entry to change its position. Magelight positions 1–12 run clockwise from the top in 30° slices; slot 0 is at the top, and the center repeats the highlighted label and destination.

Keep labels short for comfortable reading. Magelight wraps and shrinks sector text and shows the complete highlighted label in a wrapping caption. Authored labels are not truncated.

### Submenus and disabled slots

```json
{ "label": "People", "submenu": "social" }
```

This opens existing wheel `social`. Magelight shows **People** with hub-adjacent arcs and a knot hugging the outer tip; Back shares that styling. Idle navigation labels are `#bfb8a6` on the darker theme fill; selected labels retain the theme navigation colour. Legacy Submenu/Upmenu arrows remain hidden.

```json
{ "label": "Return", "control": "back" }
```

This displays **Return**. Back returns to the prior wheel; at root it closes. Use `"control": "close"` for Close.

**Leave navigation arrows out of JSON labels.** Lua decorates submenu/Back labels internally; Magelight removes exactly one generated terminal ` >` / ` <`, preserving other authored text. A `null` disables its position without shifting later entries. The root ships without Close, but custom layouts can include it.

Each wheel supports **1–12 positions**, clockwise from top slot 0 in 30° slices. Each non-null entry needs a label and one primary kind: intent, action, submenu, control or hotkey. Intent+action without event is a hybrid; action+event+intent is legacy pure-action context, not a hybrid. Reject submenu loops; repeated supported IDs are allowed.

### Target-NPC actions (experimental; runtime-unverified)

Action entries are marked **ACTION**, use the captured NPC only and have no Openly destination. No target disables them before selection. A captured target that becomes dead/disabled/unloaded fails closed with a local action error; Shift never redirects it.

Configure an action directly in `layout.json`; it is not a narration ID in `intents.json`:

```json
{
  "label": "Follow / resume",
  "action": { "name": "AccompanyTarget", "args": {} }
}
```

This example uses a built-in action on the shipped main wheel. For another registered action, its name and argument fields must match that registering mod's contract; PlayerSignals does not invent argument defaults. Nested argument values, booleans, Unicode and number tokens are preserved.

PlayerSignals checks registration and SkyrimNet's own eligibility functions for `AccompanyTarget`, `StopAccompanying` and `WaitHere`. **Other registered actions run without an eligibility check, and PlayerSignals does not enforce action cooldowns.** Direct execution can therefore differ from ordinary AI-selected behavior. Configure only actions whose effects and prerequisites you understand.

Accepted action-only failures show one local notification and one `[PlayerSignals]` trace naming the action and reason. A successful API request is not proof that the NPC completed the action. Hybrid dispatch is distinct and follows the signal semantics above. Navigation, cancellation and stale sessions remain silent.

Legacy action/event/intent example:

```json
{
  "label": "Follow / resume",
  "action": { "name": "AccompanyTarget", "args": {} },
  "event": "both",
  "intent": "follow_me"
}
```

This is a legacy pure action slot, not a hybrid: its intent supplies event context only after action API success and it does not send direct narration. Modes are `persistent`, `shortLived` or `both`. A short-lived event stores the intent phrase as its description and data; it lasts 60 seconds and repeat use of the same action on the same NPC replaces the previous event. Persistent events remain in SkyrimNet's history. No pair means no event; failed action requests register none. Event-registration failure is reported without retrying the action. Events do not use direct narration and do not guarantee passive processing. A registered action may already record its own context. Never add `event` to an intent+action hybrid.

Historical offline verification counts and results are not current evidence for this 12-slice change. Do not treat browser checks, build results or prior test counts as proof of in-game Magelight, action acceptance, SkyrimNet delivery or NPC effects.

### A small, complete example

This is a valid replacement layout with a main wheel and a Social submenu:

```json
{
  "schemaVersion": 1,
  "root": "main",
  "input": { "openKeyCode": 184 },
  "wheels": {
    "main": [
      { "label": "Yes", "intent": "confirm" },
      { "label": "Social", "submenu": "social" },
      { "label": "Close", "control": "close" }
    ],
    "social": [
      { "label": "Thanks", "intent": "thanks" },
      null,
      { "label": "Back", "control": "back" }
    ]
  }
}
```

Unused positions are disabled. Keep the quotes and commas intact; JSON is friendly right up until it meets a trailing comma.

`"root": "main"` names the first wheel to open. `main` is the shipped default, not a required name: keep your existing root if you've renamed it, and make sure the matching wheel exists. Each wheel is an array (`[...]`), and `input` is an object (`{...}`). To add just one gesture, merge its slot into an existing wheel rather than replacing your full layout with this small example.

### Change the opening key

`input.openKeyCode` uses a **SKSE keyboard scan code**. This binds the opening key for the whole wheel, not a separate key for each gesture. Keep the rest of your layout unchanged.

| Key | Decimal scan code |
|---|---:|
| Right Alt (default) | 184 |
| Left Alt | 56 |
| F8 | 66 |
| F9 | 67 |
| F10 | 68 |

For example, to use **F9**, change only the existing `input.openKeyCode` value to `67`. This fragment shows the shape; it is not a complete `layout.json`:

```json
{ "input": { "openKeyCode": 67 } }
```

Use an integer from `1` to `255` that corresponds to a keyboard scan code—not a key name, ASCII value, Windows virtual-key code, or mouse/gamepad button. Check for conflicting bindings in other mods. Avoid Tab (the menu's cancel key) and either Shift key (the group-targeting override). Save your edit, then **load a save** to replace the old opening-key registration. Changing the opening key does not change Shift's targeting behavior.

### Optional gamepad opening button

`input.openGamepadButton` is optional and omitted from the shipped layout. Add it inside the existing `input` object to register one SKSE gamepad button as an alternate open/cancel key:

```json
{ "input": { "openKeyCode": 184, "openGamepadButton": 266 } }
```

Use an integer from `266` to `281`, different from `openKeyCode`. These are SKSE gamepad codes from [`InputMap.h`](https://github.com/ianpatt/skse64/blob/master/skse64/InputMap.h); the header defines the 16-button range as 266–281. These are not keyboard scan codes:

| Button | SKSE code |
|---|---:|
| D-pad Up | 266 |
| D-pad Down | 267 |
| D-pad Left | 268 |
| D-pad Right | 269 |
| Start | 270 |
| Back | 271 |
| Left Thumb | 272 |
| Right Thumb | 273 |
| Left Shoulder | 274 |
| Right Shoulder | 275 |
| A | 276 |
| B | 277 |
| X | 278 |
| Y | 279 |
| Left Trigger | 280 |
| Right Trigger | 281 |

On save load, PlayerSignals registers the configured button and unregisters it during maintenance; with the field absent it registers no gamepad open key. Buttons that the game also uses still perform their game action. Changing the setting requires loading a save.

### Supported intent IDs

Use these exact IDs in your entries:

| Group | IDs |
|---|---|
| Main | `confirm`, `deny`, `greet`, `sorry`, `farewell`, `thanks`, `come_here`, `follow_me`, `wait_here` |
| Social | `congratulate`, `offer`, `ask`, `comfort`, `warn`, `calm_down`, `give_space` |
| Attitude | `quiet`, `unsure`, `think`, `understood`, `not_understood`, `challenge`, `yield` |
| Unplaced | `dismiss` |

These 24 IDs are shipped catalog defaults; the four shipped wheels reference 23, leaving `dismiss` unplaced. `follow_me` and `wait_here` are shipped hybrid signals with target-only actions; `dismiss` retains a compliance template but has no attached action until you place it in a custom layout. The JSON registry is dynamic, so you can add a valid new ID in `intents.json` and reference it in `layout.json`.
`calm_down` uses narration `slowly lowers both open hands, palms down, asking for calm`, notification `gestures for calm`, and targeted notification `gestures to {target} for calm`.

### Change phrases or add an intent

Edit the intent catalog here:

```text
SKSE/Plugins/PlayerSignals/intents.json
```

The file is plain JSON with root `schemaVersion: 1` and an `intents` object. Each ID maps to exactly three required, nonempty strings: `narration`, `notification`, and `targetedNotification`. An optional fourth string, `complianceNarration`, is required if the ID appears on a hybrid slot with an action. All phrases omit your character's name and final period. `targetedNotification` contains exactly one literal `{target}` marker; neither of the other required fields may contain it.

`complianceNarration` has no terminal period (including before trailing whitespace), contains one or more exact `{target}` markers and optional exact `{player}` markers. Unknown, malformed, nested, or unbalanced brace markers are rejected. Templates substitute once from the original phrase so names containing braces remain literal. Comments and trailing commas are invalid.

### In-game hybrid dispatch checklist (owner)

Check the two shipped hybrid actions, **Follow me** (`AccompanyTarget`) and **Wait here** (`WaitHere`). Test **Dismiss** (`StopAccompanying`) only after adding it as a hybrid in a custom layout; it is not placed in the shipped layout:

- [ ] Eligible captured target, no Shift: action runs once before exactly one targeted `DirectNarration`; compliance sentence appears only when `ExecuteAction` returns `0`.
- [ ] Refused/ineligible target and action failure: one ordinary targeted signal narration; no compliance sentence and no extra notification. Confirm the local receipt still follows only the `DirectNarration` return-`0` rule.
- [ ] Openly with no target and with either Shift held: no action; one group signal narration only.
- [ ] Invalid captured target without Shift (dead, disabled, unloaded): fail closed; no redirection/action/narration. Also check stale session and cancellation remain silent. Shift may intentionally override to Openly.
- [ ] No path produces more than one action or one narration per selection. API return `0` is not proof of runtime effect or NPC compliance.

This is a **complete one-entry catalog** that works only with a layout that references `greet` and no other IDs. It is not a partial replacement for the shipped catalog: if the layout still uses other IDs, keep those records in the file when editing it.

```json
{
  "schemaVersion": 1,
  "intents": {
    "greet": {
      "narration": "gives a friendly wave in greeting",
      "notification": "greets",
      "targetedNotification": "greets {target}"
    }
  }
}
```

The `greet` narration describes your character waving. A successful group submission displays `Bill greets.`; targeting the captured NPC Ted displays `Bill greets Ted.` If you hold either Shift key, the group notification omits Ted even if an NPC was captured. The recipient name comes from the NPC captured before the wheel opened—not the current crosshair.

To change a phrase or add an intent, edit `intents.json`; for a new ID, also add a wheel entry referencing it in `layout.json`. Both files are read when a save loads, so your edits take effect on the next load. No Lua/Papyrus edits, script recompilation, YAML narration files, or external trigger bundle are needed.

The shipped default narration and notification phrases are in `SKSE/Plugins/PlayerSignals/intents.json`. See [Make the wheel your own](#make-the-wheel-your-own) for layout constraints and [Change phrases or add an intent](#change-phrases-or-add-an-intent) for catalog rules.

### A little help from the WebUI

The mod also includes an optional SkyrimNet agent named **`playersignals_intent_helper`**, built like the iActions configuration helper. After installing the full updated mod and restarting SkyrimNet with the game, look for it in the WebUI **Agents** page. This packaged prompt has been validated and rendered locally; its appearance and responses in your live WebUI have not yet been verified.

Tell it what gesture you want. It can suggest wording immediately, without seeing your files. For a phrase edit, paste the current intent record; for a complete catalog replacement, paste the full `intents.json`. For wheel placement or an intent rename/removal, paste both complete files so it can check occupied slots and references. Find them in the winning PlayerSignals mod's `SKSE/Plugins/PlayerSignals` folder and label each pasted file with its filename.

Like the iActions helper, it **generates JSON for you to save**. Your configuration files are not automatically visible to the agent just because it appears in SkyrimNet's WebUI. It cannot read or write them through standard agent tools, and SkyrimNet's prompt editor/reload tools do not manage them. Its review covers only the JSON you provide—not the installed files or actual Lua validation. Record snippets are merge-only or replace-one-record suggestions, never whole-catalog replacements; without your files, ID collisions and wheel placement remain unchecked. Review its output, back up your files, save or merge the changes, then load a save. The wheel works without this helper; it adds no actions or triggers.


## FAQ

### How do I change the hotkey?

1. Open the winning installed copy of `SKSE/Plugins/PlayerSignals/layout.json`. In MO2, open the mod folder and check for higher-priority overrides as described under [Make the wheel your own](#make-the-wheel-your-own).
2. Change only the existing `input.openKeyCode` value. **F9 is `67`; Right Alt is `184`.** Use a decimal SKSE keyboard scan code, not `"F9"` or a Windows key code, and keep the rest of the file.
3. Save the file, then **load a save** to apply the new binding. Check for other mods using that key.

There is no MCM hotkey setting. Avoid Tab and either Shift key; they already serve as cancel and group-targeting controls. See [Change the opening key](#change-the-opening-key) for more codes.

### How do I customize actions or add a new gesture?

- To rename, reorder, move, hide, or place an entry in a submenu, edit `layout.json`. The visible `label` does not change the narration; the `intent` ID chooses the catalog record. Use `null` to disable a slot without shifting later entries.
- To change what a gesture means or what its notification says, edit its record in `intents.json`.
- To add a new gesture, add a lowercase intent ID with all three required phrase fields—`narration`, `notification`, and `targetedNotification`—then add a layout slot with a `label` and that same `intent` ID. If the intent/action hybrid is requested, also add `action` to the intent slot and `complianceNarration` to its catalog record; do not add `event`. Merge into your existing files; do not discard unrelated entries.
- Keep your character's name and final period out of the required phrases. Only `targetedNotification` contains exactly one literal `{target}`. `complianceNarration` (when used) also omits the final period and must contain one or more `{target}` markers; `{player}` is optional.

Back up both files, save valid JSON without comments or trailing commas, then **load a save**. No recompilation is needed. See [Change phrases or add an intent](#change-phrases-or-add-an-intent) for an example.

These “actions” are narration requests, not executable NPC commands. Adding a follow, trade, or animation-themed phrase does not implement that behavior.

### Why doesn't the wheel open?

Check that you launched through SKSE, enabled PlayerSignals.esp, and installed Magelight, JContainers (including its Lua files), and SkyrimNet with SkyrimNet.esp and its native API available. Try again in normal gameplay with other menus closed. If you changed the key, load a save first and check for a conflicting binding. Invalid configuration fails closed; restore your backed-up JSON and reload if the problem started after an edit.

If Magelight rejects the wheel data or throws while building/arming it, PlayerSignals cancels that request, releases UI mode, and reports one local error plus a `[PlayerSignals]` trace. Check `layout.json`; for a build/arm exception, also check the Magelight page log. No gesture or hotkey is submitted. This release path is browser/build-verified only; in-game confirmation is pending and requires a game restart for the updated Papyrus script.

### Why does the wheel look wrong?

Check the Magelight page log and confirm the host/runtime version and packaged `Magelight/PlayerSignals/index.html` are present. If only a label is clipped, try shorter wording.

### Why didn't I get a notification?

The notification appears only when SkyrimNet's API reports success. Check the reported PlayerSignals/API error and dependency setup. An invalid captured NPC fails closed unless you held Shift for group mode. Navigation and cancellation intentionally produce no submission notification.

### Why didn't an NPC reply after I got a notification?

The notification is a local submission receipt, not a response. SkyrimNet's settings and conversation rules determine whether NPCs speak; the captured NPC is not guaranteed to respond. With nobody eligible nearby, no reply is expected. Hold either Shift through selection until the wheel closes to address everyone nearby, but that still does not force a response.

### Does this play animations or force NPC actions?

No. PlayerSignals describes nonverbal intent to SkyrimNet; it does not animate your character, transfer items, or force an NPC to follow, wait, or obey. The gesture text is roleplaying context for SkyrimNet.

### Can I enable or remove it during a playthrough?

Existing-save initialization is designed into the mod. Removal was tested on one ADT save: disabling PlayerSignals left saved script data, and a ReSaver-cleaned copy loaded without PlayerSignals missing-script warnings. That does not establish clean removal without intervention or long-term safety. Preserve a pre-installation save and matching SKSE cosave; see [Updating or removing](#updating-or-removing) for the findings and recommended rollback.

## Updating or removing

When updating an older PlayerSignals version, replace its files rather than merging the new version over them. Remove old PlayerSignals YAML trigger/action files; this version uses SkyrimNet's native API instead. Keep the new prompt-only helper bundle if you want its WebUI agent—it is not the old dispatch bundle.

PlayerSignals doesn't add gesture spells, edit NPC world records, or change player controls. A save can still retain quest/script state, and there is no shutdown/uninstall cleaner.

### What the removal test showed

On one ADT test save:

- With PlayerSignals disabled, the save loaded, gameplay continued, and another save was made. No new PlayerSignals narration calls were logged, but missing-plugin/script warnings and saved Papyrus remnants remained.
- ReSaver identified **two unattached instances and two undefined elements** associated with PlayerSignals.
- After those remnants were removed from a copy, `Save6_resaver.ess` loaded without PlayerSignals missing-class/type warnings. The captured post-load window was approximately **eight seconds**; it did not include another save/reload cycle after cleanup.

This demonstrates a short successful load after cleanup, **not guaranteed clean removal or long-term safety**. ReSaver cleaning is not a required or universally safe uninstall procedure for this beta. If you investigate saved remnants, work on copies and preserve the originals.

### Recommended rollback

The safest save-state rollback remains restoring a **save and matching SKSE cosave from before PlayerSignals was installed**, with the mod disabled. Disabling a mod does not automatically erase its saved script data. SkyrimNet may store narration history separately; restoring a Skyrim save does not erase that history.

And that's it: a nod, a wave, a very Skyrim-flavoured misunderstanding. Make the labels yours, keep the gestures clear, and let the conversation take it from there.

## License and source

PlayerSignals code and documentation are licensed under the [MIT License](LICENSE), copyright 2026 phospheneoverdrive. You may use, modify, and redistribute them under those terms; retain the copyright and permission notice. This does not change the licenses of SKSE, UIExtensions, JContainers, or SkyrimNet.

Source and releases: [PlayerSignals on GitHub](https://github.com/Gerkinfeltser/PlayerSignals).
