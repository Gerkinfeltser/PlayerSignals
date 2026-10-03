Title: PlayerSignals (for SkyrimNet)

Tagline: A little less talking, a little more nodding.

Description (markdown ok):

> **⚠️Limited-test beta.** Targeted and group narration have been exercised in game. One mid-save removal test retained saved Papyrus remnants; a ReSaver-cleaned copy loaded without PlayerSignals missing-script warnings. Clean removal and long-term safety are not guaranteed. Back up your saves before installing or updating.
>
> **🙅Does not play animations**. The signals (nods, waves, puzzled looks, etc.) happen in the narration, not on your character model.

Give your character something to say without saying a word. **PlayerSignals** adds a configurable communication wheel with 25 shipped nonverbal gesture defaults, including agreement, greetings, thanks, warnings, and surrender. Open it with **Right Alt**, choose a gesture, and PlayerSignals submits authored direct narration to SkyrimNet. A local notification appears only when the API accepts the submission. 

Look at an NPC before opening the wheel to address them, or **hold either Shift while choosing, until the wheel closes**, to address everyone nearby. With no NPC captured, the gesture addresses the group. Your character is always supplied as the narration originator (**From**). SkyrimNet selects who responds; the captured NPC is not guaranteed to answer, nearby witnesses may join, and requests remain requests. This is a roleplaying tool, not an NPC remote control.

**Requires:**
- SkyrimNet with `SkyrimNet.esp` loaded and its native API available (runtime-tested with **0-26-0-0**)
- SKSE64
- UIExtensions
- JContainers (with API 4 / feature 2 and Lua support)

Install through your mod manager, enable `PlayerSignals.esp`, and launch through SKSE. For a manual installation, the archive's mod contents belong under the game's `Data` folder. The included **PlayerSignals-README.md** has installation guidance, configuration examples, and a FAQ.

**Customization:**
- Edit `SKSE/Plugins/PlayerSignals/layout.json` inside the installed mod to change labels, order, submenus, disabled slots, or the opening hotkey. Each wheel supports up to eight positions.
- The hotkey uses a decimal SKSE keyboard scan code: **Right Alt = 184; F9 = 67**. Change the existing `input.openKeyCode` value, keep the rest of the layout, save, and **load a save**.
- Edit `SKSE/Plugins/PlayerSignals/intents.json` to change phrases or add custom gesture IDs, then reference any new ID in a layout slot. No script recompilation is needed.
- In MO2, edit the winning file if another mod or overwrite overrides your configuration. Back up your JSON files before editing; changes apply on save load, not live.

An optional SkyrimNet WebUI agent, **`playersignals_intent_helper`**, can draft configuration JSON for you to review and save. It does not automatically read or write your installed configuration, and the wheel works without it.

**Known limits:**
- The notification confirms local API acceptance, not delivery, an NPC reply, or compliance. A gesture with nobody eligible nearby may produce no reply.
- SkyrimNet can put the selected responder under event **To** instead of preserving the intended recipient or everyone-nearby audience. Read the narration for the intended audience. An NPC's own dialogue reply correctly has that NPC as **From**.
- No gesture animations, item transfers, or forced NPC actions are performed.
- Existing-save initialization is designed into the mod. On one ADT save, disabling PlayerSignals left two unattached instances and two undefined elements. A ReSaver-cleaned copy loaded without PlayerSignals missing-script warnings, but the recorded post-load window was only about eight seconds. This is not guaranteed clean removal or a universal ReSaver procedure; preserve a pre-installation save and matching SKSE cosave for rollback. SkyrimNet may retain narration history separately.

Version: 0.1.0

What changed: Initial limited-test release with a UIExtensions wheel, JSON layout and gesture customization, player-originator targeted/group narration, and an optional intent-authoring helper. In-game testing confirmed the player as originator for all eight gestures in the reviewed session; seven received NPC responses and the final no-audience gesture correctly produced none. A limited removal/cleaned-save load test is documented; comprehensive save compatibility and long-term removal safety remain unverified.

Tags: roleplay, communication, immersion, utility

Submission type: **Listing**. PlayerSignals requires manually installed ESP/PEX and JContainers Lua files; it is not a hub-delivered prompt/action/trigger bundle.

Adult content: No explicit sexual content.