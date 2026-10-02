# PlayerSignals: a little less talking, a little more nodding

Want to agree, say thanks, or give someone a puzzled look without typing a sentence? PlayerSignals gives you a small communication wheel with 25 shipped gesture defaults, and its JSON catalog can add more intents. SkyrimNet receives an authored direct narration describing what your character means.

That's all it does: submit the narration and show a local notification only when SkyrimNet's API accepts it. Group feedback omits a recipient; targeted feedback names the NPC captured before the wheel opened. Your character will not visibly perform an animation. SkyrimNet handles the dialogue; a reply isn't guaranteed, and requests don't force NPCs to obey.

## Test release status

This is a limited-test beta. Targeted and group gestures have been exercised in game, with the player correctly supplied as the narration originator. A gesture sent with nobody nearby was accepted without producing an NPC response, as expected.

Mid-save removal has been tested on **one ADT save**. Disabling the mod left saved Papyrus remnants; a ReSaver-cleaned copy subsequently loaded without PlayerSignals missing-script warnings. This is limited test evidence, not a guarantee of clean removal or long-term save safety. See [Updating or removing](#updating-or-removing), and back up your saves before testing.

## Before you start

You'll need:

- SKSE64. Launch Skyrim through SKSE.
- UIExtensions with a stock-compatible wheel script and menu.
- JContainers with its Lua support files (API 4 / feature 2).
- SkyrimNet, with `SkyrimNet.esp` loaded and its native API available.

Back up your save and matching SKSE cosave before installing or updating. The startup quest and player-alias save-load handling are designed to initialize PlayerSignals on existing saves. The limited removal test below does not establish installation/update compatibility with every existing save.

Install PlayerSignals with your mod manager and enable **PlayerSignals.esp**. The mod's Data root should contain `PlayerSignals.esp`, `Scripts`, `Seq`, and `SKSE`—this readme belongs alongside them. You don't need the repository's build tools or authoring folders. If you're upgrading an older PlayerSignals install, replace its files rather than merging this version into it, and remove the obsolete PlayerSignals trigger bundle/files so old content cannot be mistaken for current.

Start the game and load a save, or begin a new game. PlayerSignals checks for SkyrimNet.esp and a nonempty native API build version at startup; if either is missing, the feature stays disabled. No MCM setup is required, and there is no separate trigger bundle to install or enable.

## Your first gesture

1. In normal gameplay, look toward the NPC you want to address, if there is one.
2. Press **Right Alt** to open the wheel. PlayerSignals captures the crosshair NPC before showing it.
3. Choose a communication entry, such as **Confirm / Yes** or **Greet**.

If the captured NPC is still alive, enabled, and loaded when you choose, SkyrimNet receives a targeted narration with your character as the originator (`From`) and the captured NPC as the explicit target. The text describes your character making the gesture and addresses that NPC by name. Moving the crosshair while the wheel is open does not change the submitted target. SkyrimNet still chooses who responds; the captured NPC is not guaranteed to be the responder, and Recent Events may show the selected responder under `To`.

You'll see a small notification with your character's name only if SkyrimNet's API accepts the narration. For the **Greet** intent, group feedback looks like `Bill greets.`; targeted feedback to the captured NPC Ted looks like `Bill greets Ted.` Think of it as a receipt—not a promise that an NPC heard you or will answer.

Open a submenu by choosing an entry ending in **`>`**, such as **Social >**. Choose **Back <** to return to the previous wheel. **Close** exits the main wheel, and **Tab** cancels. Opening submenus, going Back, or cancelling doesn't send a narration. Browsing isn't secretly agreeing to everything. Convenient!

The wheel won't open while you're in a blocking menu, another custom menu, or a gameplay state where the required controls are disabled.

## Who are you talking to?

The NPC under your crosshair when the wheel opens is captured for that choice. Moving your crosshair while the wheel is open does not change the captured NPC. If that NPC is no longer alive, enabled, and loaded when you make the selection, PlayerSignals fails closed: it does not silently choose a different NPC or switch to everyone.

If no NPC was captured, the narration is addressed to everyone nearby. You can also choose that mode intentionally: hold either **Left Shift** or **Right Shift** through the selection until the wheel closes. PlayerSignals checks Shift when the final selection returns from the wheel; it does not promise to sample the exact click instant. Shift overrides a captured NPC and uses group narration and feedback without that NPC's name.

Group narration explicitly says the gesture is addressed to everyone nearby. Nearby witnesses may join, but no one is guaranteed to speak or comply. The group wording does not force every nearby NPC to reply.

### A note about Recent Events

PlayerSignals now always supplies your character as the narration originator (**From**), including gestures addressed to a captured NPC. An NPC can still appear under **From** on their own dialogue reply; that is a separate event, not the NPC performing your gesture.

The remaining limitation is **To**: SkyrimNet selects a responder and can put that NPC in the event's target field. A group gesture may therefore appear as Bill → Ted even though the narration explicitly addresses everyone nearby. If nobody is in earshot and no responder is selected, there may be no **To** value and no reply.

Read the narration for the intended audience; it names your character and explicitly addresses the captured NPC or **everyone nearby**. The local notification also distinguishes targeted and group submissions. This version corrects the player-originator arguments, but it does not separate intended audience from selected responder inside SkyrimNet's event metadata.


## What's on the wheel?

| Wheel | Entries |
|---|---|
| Main | Confirm / Yes, Deny / No, Greet, Farewell, Social >, Signals >, Attitude >, Close |
| Social | Thank you, Sorry, Show respect, Welcome, Well done, Offer, Request, Back < |
| Signals | Come here, Follow me, Wait here, Quiet, Ready, Watch out, Get attention, Back < |
| Attitude | Unsure, Let me think, Not understood, Approve, Disapprove, Challenge, Surrender, Back < |

A few distinctions are worth keeping:

- **Confirm** means agreement; **Approve** expresses approval.
- **Deny** means disagreement; **Disapprove** expresses disapproval.
- **Unsure** means you're uncertain; **Not understood** means you didn't understand.
- **Offer** and **Request** suggest giving or asking for something. They don't move items or name a particular object.

Likewise, Follow me, Wait here, and Quiet are requests—not remote controls for NPCs. They still get a say in the matter.

## Make the wheel your own

Open the PlayerSignals folder in your mod manager and find these files:

```text
SKSE/Plugins/PlayerSignals/layout.json
SKSE/Plugins/PlayerSignals/intents.json
```

`layout.json` controls wheels, labels, and the opening key. `intents.json` defines supported IDs and their narration and notification phrases. Back up both files before editing. Use a plain-text editor, save changes, then **load a save** to apply them. Neither file reloads live or gets written back by the mod.

In **MO2**, these are paths inside the installed mod folder—not a `Data` folder inside it. Open the PlayerSignals mod folder and look under `SKSE/Plugins/PlayerSignals/`, typically `<instance>/mods/<installed PlayerSignals folder>/SKSE/Plugins/PlayerSignals/`. If a matching file exists in `overwrite/SKSE/Plugins/PlayerSignals/` or another higher-priority mod, check MO2's Data/conflict view and edit the winning copy. The configs do not automatically belong in overwrite. For a manual install, their game-facing paths are `Data/SKSE/Plugins/PlayerSignals/...`.

You can change labels, reorder entries, move supported intents between wheels, make submenus, disable slots, and change the opening key in `layout.json`. Edit or add IDs and phrase text in `intents.json`. A new ID must also be referenced by a layout entry. These JSON edits need no script recompilation.

### Rename or move an entry

An entry looks like this:

```json
{ "label": "Request", "intent": "ask" }
```

`label` is the text you see. `intent` is what the selection means. Rename the label to suit you, but keep the intent ID unless you want a different gesture.

Move the entire entry to change its position. **Positions 1–4 run down the left side; positions 5–8 run down the right side.** The order isn't clockwise. The text at the bottom of the wheel is the highlighted option's caption, not an extra slot.

Keep labels short. “Request” fits more comfortably than “Ask for something,” and the wheel doesn't automatically shrink or trim long text. Fit depends on the letters, UI scale, and position, not just a fixed character count.

### Submenus and disabled slots

```json
{ "label": "People", "submenu": "social" }
```

This displays **People >** and opens the wheel named `social`. The destination must exist under `wheels`.

```json
{ "label": "Return", "control": "back" }
```

This displays **Return <**. Back returns to the wheel you came from; at the root, it closes the menu. Use `"control": "close"` for a Close entry.

**Leave the arrows out of your JSON labels.** PlayerSignals adds them automatically. A `null` entry disables that position without shifting the later entries.

Each wheel supports **1–8 positions**, and each non-null entry needs a label plus exactly one of `intent`, `submenu`, or `control`. Don't link submenus into a loop. Reusing the same supported intent in more than one slot is fine.

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
| Social | `thanks`, `sorry`, `respect`, `welcome`, `congratulate`, `offer`, `ask` |
| Signals | `come_here`, `follow_me`, `wait_here`, `quiet`, `ready`, `warn`, `attention` |
| Attitude | `unsure`, `think`, `not_understood`, `approve`, `disapprove`, `challenge`, `yield` |

These 25 IDs are shipped defaults; the JSON registry is dynamic, so you can add a valid new ID in `intents.json` and reference it in `layout.json`.

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

If you also have the source repository, its `docs/specs/player-signals.md` has all 25 shipped default narration/group-notification phrases and the exact schema rules.

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
