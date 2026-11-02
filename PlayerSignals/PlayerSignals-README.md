# PlayerSignals: a little less talking, a little more nodding

Want to agree, say thanks, or give someone a puzzled look without typing a sentence? PlayerSignals gives you a small communication wheel with 28 reachable shipped gesture defaults; the JSON catalog contains 30 defaults, including the older Follow me and Wait here gestures, which are not in a shipped wheel, and can add more intents. SkyrimNet receives an authored direct narration describing what your character means.

Gesture entries submit narration and show a local receipt only when SkyrimNet's API accepts it. Group feedback omits a recipient; targeted feedback names the NPC captured before the wheel opened. Gestures do not visibly animate your character or force NPC compliance. Target-NPC action entries instead request a registered SkyrimNet action on that NPC, without guaranteeing completion.

## Test release status

This is a limited-test beta. Targeted and group gestures have been exercised in game, with the player correctly supplied as the narration originator. A gesture sent with nobody nearby was accepted without producing an NPC response, as expected.

Mid-save removal has been tested on **one ADT save**. Disabling the mod left saved Papyrus remnants; a ReSaver-cleaned copy subsequently loaded without PlayerSignals missing-script warnings. This is limited test evidence, not a guarantee of clean removal or long-term save safety. See [Updating or removing](#updating-or-removing), and back up your saves before testing.

## Before you start

You'll need:

- SKSE64. Launch Skyrim through SKSE.
- UIExtensions with a stock-compatible wheel script and menu.
- JContainers with its Lua support files (API 4 / feature 2).
- SkyrimNet, with `SkyrimNet.esp` loaded and its native API available.
- Magelight host 0.31.2+ and its matching runtime when using the enabled experimental radial backend.
- For action entries, SkyrimNet with `IsActionRegistered`, `ExecuteAction`, the built-in `SkyrimNetInternal` eligibility functions, and optional persistent/short-lived event APIs.
- Only for layouts containing a `raw: true` hotkey: `PlayerSignals.dll` (native API version 1) and Address Library for SKSE Plugins; Skyrim VR requires the VR Address Library. Ordinary hotkeys do not require either.

Back up your save and matching SKSE cosave before installing or updating. The startup quest and player-alias save-load handling are designed to initialize PlayerSignals on existing saves. The limited removal test below does not establish installation/update compatibility with every existing save.

Install PlayerSignals with your mod manager and enable **PlayerSignals.esp**. The mod's Data root should contain `PlayerSignals.esp`, `Scripts`, `Seq`, and `SKSE`—this readme belongs alongside them. You don't need the repository's build tools or authoring folders. If you're upgrading an older PlayerSignals install, replace its files rather than merging this version into it, and remove the obsolete PlayerSignals trigger bundle/files so old content cannot be mistaken for current.

Start the game and load a save, or begin a new game. PlayerSignals checks for SkyrimNet.esp and a nonempty native API build version at startup; if either is missing, the feature stays disabled. No MCM setup is required, and there is no separate trigger bundle to install or enable.

## Your first gesture

1. In normal gameplay, look toward the NPC you want to address, if there is one.
2. Press **Right Alt** to open the wheel. PlayerSignals captures the crosshair NPC before showing it.
3. Choose a communication entry, such as **Yes** or **Greet**.

If the captured NPC is still alive, enabled, and loaded when you choose, SkyrimNet receives a targeted narration with your character as the originator (`From`) and the captured NPC as the explicit target. The text describes your character making the gesture and addresses that NPC by name. Moving the crosshair while the wheel is open does not change the submitted target. SkyrimNet still chooses who responds; the captured NPC is not guaranteed to be the responder, and Recent Events may show the selected responder under `To`. Magelight's hub displays the captured NPC's display name, or **Target NPC** if that name is empty.

You'll see a small notification with your character's name only if SkyrimNet's API accepts the narration. For the **Greet** intent, group feedback looks like `Bill greets.`; targeted feedback to the captured NPC Ted looks like `Bill greets Ted.` Think of it as a receipt—not a promise that an NPC heard you or will answer.

Open a submenu by choosing **Social** (**Social >** in UIExtensions), for example. Choose **Back** (**Back <** in UIExtensions) to return to the previous wheel; it occupies zero-based slot 10 (300°, just above cardinal west) in every shipped submenu. **Tab** cancels; Magelight also offers center-click, **Escape**, or a fresh press of the configured opening key once the wheel is armed (default **Right Alt**). Holding/repeating the key or its initial pre-arm opening press does not close it. If its scan code has no standard browser mapping, one console warning explains the Tab/Escape fallback; center still works. Opening submenus, going Back, or cancelling doesn't send a narration.

**Experimental Magelight branch:** twelve 30° slices run clockwise from the top. Gesture cores target the captured NPC; semicircular bulbs select Openly. Core and bulb share a straight outer-corner chord without a fill gap or overlap sliver. Their insets, selected bands and flow clips follow that outline; the upright broadcast icon is centered in the half-disc's bounds, while ripple motion retains its chord-midpoint pivot. Shift previews Openly without changing page dispatch. A selected core turns bright yellow with a darker-yellow inner band; its idle kind colour moves onto the label/badge. Bulb hover/Shift lights both pieces; only the bulb uses a white-centre (`#ffffff`) to pale warm-edge (`#fff4e8`) radial gradient, with no filters and its thin `#d9bd79` band. Navigation/actions retain pointed neckties; hotkeys instead split into a flat trapezoid cap and chord-edged pie. Both hotkey parts are muted teal when idle. Either part lights both and dispatches the same key; the cap lights with the same white-centre-to-warm-edge gradient while the pie remains bright yellow with a darker-yellow inner band, and only the inset pie carries V-shaped flow. The selected cap's thin band remains unchanged. SIGNAL (gesture), ACTION and KEY badges stay upright beneath wrapped labels and use their kind's idle colour when lit. Submenu, Back, Close and null slots have no badge. Navigation chevrons dim behind the label only; actual visible badges on other kinds remain respected. Every disabled slot uses the same faint pointed necktie, including disabled hotkeys. Slices lift to 1.06; choices dispatch immediately. Reduced-motion preferences are honored. The wheel, title and help paint above the backdrop vignettes. These browser-facing details do not prove in-game acceptance.

Center Cancel lifts to 1.08 and always paints above the slices, concealing their inner points. Only Submenu and Back show two thin clipped arcs at radii 560 and 610, outside the hub's maximum pop; hotkey, Close, gesture, action and empty slots show none. Only Submenu and Back neckties are 0.85× about the wheel centre; their hits, insets, selected bands, flow, labels and utility clips follow the smaller outline, without changing stroke widths. They display the owner's knot at its approved absolute size, translated so its V apex caps the new outer tip and both arms hug the tip edges like an arrowhead. Tails may overhang the shortened outer edges. The knot lifts with the slice and hides when disabled. Close/hotkeys/actions show no knot and keep their original geometry, as do empty slots. Legacy Submenu/Upmenu arrows remain hidden. Matching top/bottom vignettes cover the outer quarter-screen while armed; title/help remain above them. The two-line help reads `Slice: target · Tip or Shift: Openly` and `←/→ choose · Enter select · Esc / Right Alt / center: cancel`, substituting the configured key's name. Tab, Up/Down and Space remain available; actions are target-only.

Selected gestures show two scaled arc bands only in the bulb, including Openly/Shift full selection. With only the core selected, the blue bulb uses subtle additive mint bands; a lit bulb uses pale warm-yellow additive ripples at the same low 0.12 peak. The selected band is 30 units wide (15 visible units), including the lit cap; its stroke width is 30. Only actually visible badges contribute to flow dimming, so navigation chevrons dim behind the label alone. Actions and other utilities use four warm-white (`#fff6e0`) additive chevrons at peak 0.35, with clamped-addition normal-blend fallback. Hotkey V-shaped flow stays in the inset pie only; the cap remains lit without flow. Labels/badges remain readable. Bands travel every 2.4 seconds, stop on leave/blur/close/selection, and stay static under reduced motion or zero tween. Disabled actions and empty slots show none.

Click a gesture's core for the captured target or its bulb for **Openly**. **Left/Right** moves among available entries; **Up** chooses a gesture's bulb, **Down** its core; **Enter/Space** confirms. Up/Down stays on the same navigation/action/hotkey slice. Both hotkey parts dispatch the same key, never Openly. Merged neckties remain selectable at their pointed end; actions stay target-only. Controller navigation is not implemented because the inspected Magelight contract exposes no flat-gamepad delivery.

The wheel won't open while you're in a blocking menu, another custom menu, or a gameplay state where the required controls are disabled.

## Who are you talking to?

The NPC under your crosshair when the wheel opens is captured for that choice. Moving your crosshair while the wheel is open does not change the captured NPC. For a targeted selection, if that NPC is no longer alive, enabled, and loaded, PlayerSignals fails closed: it does not silently choose a different NPC or switch to everyone. Shift or the Magelight gesture's explicit **Openly** destination intentionally chooses group mode instead.

If no NPC was captured, the Magelight hub shows **No target · Openly** and gesture narration is addressed to everyone nearby. You can also choose that mode intentionally: hold either **Left Shift** or **Right Shift** through the selection until the wheel closes. PlayerSignals checks Shift when the final selection returns from the wheel; it does not promise to sample the exact click instant. Shift overrides a captured NPC and uses group narration and feedback without that NPC's name.

Action entries require a captured NPC; without one they are disabled before selection. Actions do not have an Openly destination, and Shift does not convert them to group mode. The existing submission-time validity checks are unchanged.

Group narration explicitly says the gesture is addressed to everyone nearby. Nearby witnesses may join, but no one is guaranteed to speak or comply. The group wording does not force every nearby NPC to reply.

### A note about Recent Events

PlayerSignals now always supplies your character as the narration originator (**From**), including gestures addressed to a captured NPC. An NPC can still appear under **From** on their own dialogue reply; that is a separate event, not the NPC performing your gesture.

The remaining limitation is **To**: SkyrimNet selects a responder and can put that NPC in the event's target field. A group gesture may therefore appear as Bill → Ted even though the narration explicitly addresses everyone nearby. If nobody is in earshot and no responder is selected, there may be no **To** value and no reply.

Read the narration for the intended audience; it names your character and explicitly addresses the captured NPC or **everyone nearby**. The local notification also distinguishes targeted and group submissions. This version corrects the player-originator arguments, but it does not separate intended audience from selected responder inside SkyrimNet's event metadata.


## What's on the wheel?

The entries below use UIExtensions' navigation markers. Magelight shows the same labels without the generated ` >` and ` <` suffixes.

| Wheel | Entries |
|---|---|
| Main | 0 Yes, 1 No, 2 Thank you, 3 Greet, 4 Social >, 5 Signals >, 6 Attitude >, 7 Sorry, 8 Wait here, 9 Farewell, 10 Follow me, 11 Come here |
| Attitude | 0 Approve, 2 Understood, 3 Challenge, 4 Unsure, 5 Let me think, 6 Disapprove, 8 Not understood, 9 Surrender, 10 Back < |
| Social | 0 Offer, 2 Well done, 4 Welcome, 6 Request, 7 Show respect, 8 Comfort, 10 Back < |
| Signals | 0 Ready, 3 Get attention, 4 Watch out, 6 Not ready, 7 Calm down, 9 Quiet, 10 Back <, 11 Give space |

Positions are zero-based and unlisted positions are null.

A few distinctions are worth keeping:

- **Confirm** means agreement; **Approve** expresses approval.
- **Deny** means disagreement; **Disapprove** expresses disapproval.
- **Unsure** means you're uncertain; **Understood** and **Not understood** say whether you followed.
- **Ready** and **Not ready** say whether you're prepared to go; **Give space** asks for distance, the opposite of **Come here**.
- **Comfort** offers reassurance; **Well done** congratulates.
- **Offer** and **Request** suggest giving or asking for something. They don't move items or name a particular object.

Quiet and the other gestures are requests, not remote controls for NPCs. **Follow me** and **Wait here** are gestures too: the NPC may react, but nothing forces them to follow or wait. The shipped layout has no action slots; to call registered SkyrimNet actions such as `AccompanyTarget`, add them to a custom layout (see below).

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

Add either example to a wheel position. The authored `raw` flag is flat beside `hotkey`; the page payload carries it in its fourth extras object as `{ "raw": true }`, combined with an optional color as `{ "color": "#aabbcc", "raw": true }`. `raw: false` is omitted from page extras.

```json
[
  { "label": "SN Dashboard", "hotkey": 64, "raw": true, "delayMs": 0 },
  { "label": "IE Dashboard", "hotkey": 11, "raw": true, "delayMs": 0 }
]
```

The owner verified the two dashboards in the spike, not this production DLL:

| Skyrim runtime | Current evidence |
|---|---|
| AE 1.6.1170 | Dashboards owner-verified in the spike; this production DLL still needs in-game testing. |
| AE 1.7.104 | Production in-game testing still required. |
| SE 1.5.97 | Build-only support; in-game untested. |
| VR | Build-only support; in-game untested. |

Restart Skyrim after a DLL or controller update. Load a save after JSON edits to apply the layout and missing-DLL load warning.

### Wheel colour theme (Magelight)

Add one optional top-level property in `layout.json`, alongside `schemaVersion`, `root`, `input` and `wheels`:

```json
"theme": "moss",
```

Choose `slate` for the original grey/blue-slate and gold, `moss` for muted dark green, or `ember` for muted dark red/rust. Omit the property to use `slate` (as the shipped layout does). Keep the comma between JSON properties. Unknown names and non-string values reject the layout. Save the file, then load a save to apply it; no recompilation is needed. UIExtensions ignores this setting. The idle Submenu/Back fill uses `--subnav-fill`: slate `#38392f`, moss `#2d3a2f`, ember `#402e2a`; their labels use `--subnav-label` `#bfb8a6` in every theme. Without a slot colour override, selected navigation labels retain the existing `--nav-fill` colors. All themes keep cream text and the same Chevron/Knot line colours.

### Per-slot colours (Magelight)

Any non-null entry can add `color` as exactly `#` plus six hexadecimal digits, using either letter case:

```json
{ "label": "Greet", "intent": "greet", "color": "#4a6b5c" }
```

This changes the idle colour only: both gesture parts, both hotkey parts, or the action/navigation necktie. Selected fills stay yellow with the standard band and white caps; the lit label and badge use your chosen idle colour. Disabled entries, including actions without a target, keep their shared disabled look. Slot colours survive theme changes. Very light or very dark colours can hurt label readability. Names, short hex codes, `rgb()` and non-string values are rejected. UIExtensions ignores this option. The shipped layout has no colours.

Custom-coloured gesture bulbs also derive their unlit ripple tint from the slot colour, with a lower hue and increased HSL lightness at the same strength. Uncoloured bulbs keep mint ripples, and lit bulbs keep warm yellow ripples.

### Rename or move an entry

An entry looks like this:

```json
{ "label": "Request", "intent": "ask" }
```

`label` is the text you see. `intent` is what the selection means. Rename the label to suit you, but keep the intent ID unless you want a different gesture.

Move the entire entry to change its position. **UIExtensions:** positions 1–4 run down the left side and 5–8 down the right; the order isn't clockwise and wheels over 8 slots fail closed with an actionable notification. **Experimental Magelight:** positions 1–12 run clockwise from the top in 30° slices; slot 0 is at the top, and the center repeats the highlighted label and destination.

Keep labels short for comfortable reading. UIExtensions does not automatically shrink or trim long text. Experimental Magelight wraps and shrinks sector text and shows the complete highlighted label in a wrapping caption. Neither backend imposes a fixed character limit or truncates authored labels.

### Submenus and disabled slots

```json
{ "label": "People", "submenu": "social" }
```

This opens the wheel named `social`; that destination must exist under `wheels`. Magelight shows **People** with two hub-adjacent arcs and a knot hugging its outer tip; Back uses the same utility styling. Idle Submenu/Back labels use muted `--subnav-label` `#bfb8a6`, and their fill uses the darker per-theme `--subnav-fill`; selected labels retain the existing `--nav-fill` colors. Legacy Submenu/Upmenu arrows remain hidden. UIExtensions displays **People >**.

```json
{ "label": "Return", "control": "back" }
```

This displays **Return** in Magelight and **Return <** in UIExtensions. Back returns to the wheel you came from; at the root, it closes the menu. Use `"control": "close"` for a Close entry.

**Leave the navigation arrows out of your JSON labels.** Lua adds them for UIExtensions; Magelight strips exactly one generated terminal ` >` from submenu entries and ` <` from Back entries. Authored text and other entry kinds are unchanged. The shipped root has no Close entry; custom layouts may still put Close anywhere, without the special darker Submenu/Back idle fill. A `null` entry disables that position without shifting the later entries. Inline glyphs can be typed directly into labels.

Each wheel supports **1–12 positions**. Magelight uses 12 slices of 30°; UIExtensions supports at most 8 positions and fails closed above that limit. Each non-null entry needs a label plus one primary kind: `intent`, `action`, `submenu`, or `control`. An action may additionally carry the paired `event` and catalog `intent` fields described below. Don't link submenus into a loop. Reusing the same supported intent in more than one slot is fine.

### Target-NPC actions (experimental; runtime-unverified)

Action entries are marked **ACTION** and have no everyone-nearby chevron. They always use the NPC captured when the wheel opened. Shift does not convert them to group mode. No target, or a target that is dead, disabled or no longer loaded, produces a local failure message rather than selecting someone else.

Configure an action directly in `layout.json`; it is not a narration ID in `intents.json`:

```json
{
  "label": "Follow / resume",
  "action": { "name": "AccompanyTarget", "args": {} }
}
```

This example uses a built-in action on the shipped main wheel. For another registered action, its name and argument fields must match that registering mod's contract; PlayerSignals does not invent argument defaults. Nested argument values, booleans, Unicode and number tokens are preserved.

PlayerSignals checks registration and the captured target. It also checks SkyrimNet's own eligibility functions for `AccompanyTarget`, `StopAccompanying` and `WaitHere`. **Other registered actions run without an eligibility check, and PlayerSignals does not enforce action cooldowns.** Direct execution can therefore differ from ordinary AI-selected behavior. Configure only actions whose effects and prerequisites you understand.

Accepted action failures show one local notification and one `[PlayerSignals]` trace naming the action and reason. A successful API request is not proof that the NPC completed the action. Navigation, cancellation and stale sessions remain silent. PlayerSignals does not call direct narration for action entries.

Optionally, record context after the action API returns success by adding **both** an `event` mode and an existing catalog `intent`:

```json
{
  "label": "Follow / resume",
  "action": { "name": "AccompanyTarget", "args": {} },
  "event": "both",
  "intent": "follow_me"
}
```

Modes are `persistent`, `shortLived` or `both`. The intent's narration phrase supplies the text, rendered with your character as actor and the captured NPC addressed; choose or author a phrase that actually matches the interaction. A short-lived event stores that exact phrase as both its description and its data, not action/FormID JSON, so SkyrimNet's no-schema formatter can display the phrase. It lasts 60 seconds and repeat use of the same action on the same NPC replaces the previous event. Persistent events remain in SkyrimNet's history. No pair means no event; failed action requests register none. Event-registration failure is reported without retrying the action. Events do not use direct narration, but short-lived events can be observed by matching SkyrimNet triggers; this is not a guarantee of passive processing. A registered action may already record its own context.

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

### Supported intent IDs

Use these exact IDs in your entries:

| Group | IDs |
|---|---|
| Main gestures | `confirm`, `deny`, `greet`, `farewell` |
| Social | `thanks`, `sorry`, `respect`, `welcome`, `congratulate`, `offer`, `ask`, `comfort` |
| Signals | `come_here`, `quiet`, `ready`, `not_ready`, `warn`, `attention`, `calm_down`, `give_space` |
| Attitude | `unsure`, `think`, `understood`, `not_understood`, `approve`, `disapprove`, `challenge`, `yield` |
| Unplaced | `follow_me`, `wait_here` |

These 30 IDs are shipped catalog defaults. The shipped wheels reach 28 of them; `follow_me` and `wait_here` remain valid for custom layouts but are not placed, because the main wheel covers following and waiting with actions. The JSON registry is dynamic, so you can add a valid new ID in `intents.json` and reference it in `layout.json`.
`calm_down` uses narration `slowly lowers both open hands, palms down, asking for calm`, notification `gestures for calm`, and targeted notification `gestures to {target} for calm`.

### Change phrases or add an intent

Edit the intent catalog here:

```text
SKSE/Plugins/PlayerSignals/intents.json
```

The file is plain JSON with root `schemaVersion: 1` and an `intents` object. Each lowercase ID maps to exactly three required, nonempty strings: `narration`, `notification`, and `targetedNotification`. All three phrase values omit your character's name and final period. `targetedNotification` contains exactly one literal `{target}` marker; neither of the other fields may contain it. Comments and trailing commas are invalid.

The validator rejects any field ending in a period, even when only trailing ASCII whitespace follows; it also rejects `{target}` outside `targetedNotification`. Malformed phrase templates fail closed rather than passing a literal marker through or adding doubled punctuation.

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

If you also have the source repository, its `docs/specs/player-signals.md` has the shipped default narration/group-notification phrases and the exact schema rules.

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
- To add a new gesture, add a new lowercase intent ID with all three phrase fields—`narration`, `notification`, and `targetedNotification`—then add a layout slot with a `label` and that same `intent` ID. Merge these into your existing files; do not discard unrelated entries.
- Keep your character's name and final period out of the three phrase values. Only `targetedNotification` contains the literal `{target}`, exactly once.

Back up both files, save valid JSON without comments or trailing commas, then **load a save**. No recompilation is needed. See [Change phrases or add an intent](#change-phrases-or-add-an-intent) for an example.

These “actions” are narration requests, not executable NPC commands. Adding a follow, trade, or animation-themed phrase does not implement that behavior.

### Why doesn't the wheel open?

Check that you launched through SKSE, enabled PlayerSignals.esp, and installed UIExtensions and JContainers—including its Lua files. Confirm SkyrimNet.esp is enabled and its native API is available. Try again in normal gameplay with other menus closed. If you changed the key, load a save first and check for a conflicting binding. Invalid configuration fails closed; restore your backed-up JSON and reload if the problem started after an edit.

If Magelight rejects the wheel data or throws while building/arming it, PlayerSignals cancels that request, releases UI mode, and reports one local error plus a `[PlayerSignals]` trace. Check `layout.json`; for a build/arm exception, also check the Magelight page log. No gesture or hotkey is submitted. This release path is browser/build-verified only; in-game confirmation is pending and requires a game restart for the updated Papyrus script.

### Why does the wheel look wrong?

Another mod may replace UIExtensions' wheel script or menu. Check which files win in your mod manager; PlayerSignals needs a stock-compatible pair. If only a label is clipped, try shorter wording.

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
