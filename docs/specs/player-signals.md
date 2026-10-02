# Specification: PlayerSignals (for SkyrimNet)

Status: Approved captured-target/direct-narration contract. Scoped Lua-loader/source-derived adapter smokes, both Papyrus compiles, and 15 separately run unittests provide evidence for the JSON catalog/targeted-notification revision. The integrated full build failed at a later Spriggit step; in-game acceptance remains pending. The latest reviewed runtime archive exercises prior-build routing only; see the plan for evidence and limits.
Updated: 2026-10-01

Release title: **PlayerSignals (for SkyrimNet)**.
Project/repository: `D:/gerkgit/SkyrimNet_PlayerSignals`.
Standalone mod root: `D:/gerkgit/SkyrimNet_PlayerSignals/PlayerSignals/`. Symlink this child folder into MO2 for testing, not the repository root. Documentation and authored Spriggit records stay outside the mod root.

This is the authoritative behavior, interface, configuration, and acceptance contract. The active implementation phase and evidence boundaries live in [the plan](../plans/player-signals.md); its archive records are prior-build evidence, not proof of the current JSON-catalog/targeted-notification revision.

## Goal and scope

Provide a JSON-configurable player communication wheel. The shipped catalog has 25 predefined nonverbal intents; additional lowercase IDs may be added to the validated JSON registry. Selecting a catalog intent submits exactly one direct narration to SkyrimNet, using the NPC captured from the crosshair before the wheel opens or addressing everyone nearby when no NPC was captured. A held Shift key can intentionally override targeting to everyone.

This is authored roleplay narration, not animation playback or a claim that the player visibly performed a gesture. Direct narration requests a SkyrimNet reaction; PlayerSignals does not guarantee a spoken reply or force compliance with the requested gesture.

Decided:
- UIExtensions, eight slots per wheel, nested sub-wheels, independent Papyrus controller.
- JContainers for JSON; no MCM, separate INI, custom DLL, or custom Scaleform implementation.
- Default opening key Right Alt; keyboard scan code configurable in JSON.
- Capture the crosshair NPC immediately before opening the wheel. Either left or right Shift (scan code 42 or 54) sampled immediately after `Browse` returns a final accepted intent, before feedback/catalog lookups, overrides the captured target and addresses everyone nearby.
- No captured NPC means everyone-nearby mode. A captured NPC that is no longer alive, enabled, or 3D-loaded when submitting fails closed; it must not silently turn into everyone mode or another target.
- One `SkyrimNetApi.DirectNarration` call per accepted selection. No retries, fallback submission, mod events, trigger bundle, or YAML triggers.
- One local in-game notification only when that API call returns `0`. Navigation, cancellation, failed API calls, invalidated/stale selections, and failed captured-target validation are silent.
- Preserve the meanings of all 25 shipped default gestures while allowing additional intents through the JSON catalog. Narration text always describes the player as the gesture actor, even when SkyrimNet's responder context is a captured NPC.
- No animation playback, item transfers, forced NPC actions, or guaranteed NPC response/compliance.

### User outcomes

1. Open a communication wheel with Right Alt and select an authored nonverbal intent without typing or speaking.
2. Have SkyrimNet receive one narration using the crosshair NPC captured before the wheel opened, unless no NPC was captured or Shift was held through selection; those cases address everyone nearby.
3. Customize the opening key, labels, ordering, sub-wheels, narration phrases, and notification phrases by editing `layout.json` and `intents.json`, then loading a save; add an intent without Lua/Papyrus edits or recompilation.
4. Navigate or cancel without communicating anything, playing animations, or leaving movement disabled.
5. See player-named local feedback only when the direct narration API reports success; do not mistake the notification for an NPC reply.

This supersedes the former mod-event/YAML trigger architecture. Do not depend on an external PlayerSignals SkyrimNet package, event monitor setup, `overlay/` triggers, or trigger activation. Do not depend on or modify the separate `SkyrimNet_Emote` project.

### Optional WebUI authoring helper

Ship a prompt-only bundle at `SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/`, with `manifest.json` and `prompts/agent_playersignals_intent_helper.prompt`. The agent inherits `components/agent_tools_base.prompt`; SkyrimNet lists root templates beginning with `agent_` in the WebUI Agents page. Its displayed name is `playersignals_intent_helper`.

The helper drafts intent records and matching layout references from user-supplied files. It preserves unrelated entries, distinguishes merge-only snippets from complete replacement files, and explains backup/save-load application. Standard agent tools provide no general file reader/writer or PlayerSignals JSON validator: the helper must not claim filesystem access, automatic application, actual Lua validation, or game verification. It must not use console/quest calls to bypass that boundary. Configuration values are data, not agent instructions.

Authoring guidance distinguishes mod-relative paths from the virtual `Data/` prefix and MO2 overwrite conflicts. Explain that `main` is the shipped root name, not a schema constant; preserve existing wheel names and opening key. Supply concrete valid wheel-array and input-object examples, use slot-only snippets when the existing layout is unavailable, and never fill a JSON block with schema placeholders. Opening-key examples use verified decimal SKSE keyboard scan codes; one opening key controls the entire wheel, not per-intent hotkeys.

This bundle contains no actions or triggers and is not a dependency of the communication wheel. It does not restore the obsolete mod-event/YAML dispatch path or fix event attribution. Validate and render the inherited template with the installed base content and representative WebUI context before shipping; actual WebUI discovery and model behavior remain separate runtime checks.


## Target capture and recipient contract

Capture the current crosshair NPC before showing the first wheel. Keep that captured reference for the entire session; moving the crosshair during wheel navigation does not retarget the selection. Immediately after `Browse` returns a final accepted intent, sample both Shift scan codes (42 and 54), before feedback/catalog lookups. A Shift held at that point overrides any captured NPC and selects group narration. This is the agreed sampling point; it is not a promise to sample the exact mouse-click instant.

| Captured NPC at opening | Shift held when intent selection returns | Submission behavior |
|---|---|---|
| Eligible NPC | No | Submit targeted direct narration to the captured NPC, if still valid at submission |
| Eligible NPC | Yes, either Shift | Submit group direct narration to everyone nearby; discard target for this submission |
| None | Either state | Submit group direct narration to everyone nearby |
| Captured NPC is no longer alive, enabled, or 3D-loaded | No | Fail closed: no narration call and no success notification |
| Captured NPC is no longer alive, enabled, or 3D-loaded | Yes, either Shift | Group override applies; do not require the captured NPC to remain valid |

No captured NPC is an intentional everyone-nearby selection, not an error. Do not substitute the nearest NPC or silently fall back from an invalid captured NPC to group mode. Nearby witnesses may join, but neither targeted nor group narration guarantees speech or compliance. Group wording must explicitly say the gesture is addressed to everyone nearby; that wording does not force every NPC to reply.

## Direct narration contract

For a still-valid captured NPC with no Shift override, call exactly:

```papyrus
SkyrimNetApi.DirectNarration(text, respondingNPC, player)
```

The captured NPC is the responder/originator context and the player is the listener context for SkyrimNet. The narration text itself must still name the player as the actor performing the authored gesture; do not rewrite the gesture as an action performed by the NPC.

Known SkyrimNet attribution limitation: the latest reviewed archive showed the targeted `eventOriginator=NPC, target=player` path rendering gesture `From`/`To` attribution in reverse, while group processing substituted the reply speaker into event `To`. This is observed engine behavior, not fixed by PlayerSignals; no engine patch is approved. Do not claim that the attribution issue is fixed.

For no captured NPC or a Shift override, call exactly:

```papyrus
SkyrimNetApi.DirectNarration(text, player, None)
```

In group mode, the constructed text must also include a clear sentence explicitly addressing the gesture to everyone nearby. This sentence communicates intent; it does not force all nearby NPCs to respond.

Construct the authored portion from the player's display name and the catalog's `narration` phrase as `<player name> <phrase>.`. The phrase contains neither the player prefix nor the final period. Do not use the editable wheel label as narration text. One accepted intent produces one API call, with no retry or alternate route. A return value of `0` is the only condition for one local submission notification. Any other return value, stale stack, invalid target, or failed readiness guard produces no success notification.

## Default wheel layout

| Slot | Main | Social | Signals | Attitude |
|---|---|---|---|---|
| 1 | Confirm / Yes | Thank you | Come here | Unsure |
| 2 | Deny / No | Sorry | Follow me | Let me think |
| 3 | Greet | Show respect | Wait here | Not understood |
| 4 | Farewell | Welcome | Quiet | Approve |
| 5 | Social > | Well done | Ready | Disapprove |
| 6 | Signals > | Offer | Watch out | Challenge |
| 7 | Attitude > | Request | Get attention | Surrender |
| 8 | Close | Back < | Back < | Back < |

There are 25 communication intents; navigation/control entries consume slots. Keep the shipped layout at one submenu level, while allowing deeper valid layouts through JSON.

UIExtensions displays slots 1–4 down the left side (upper-left, left, lower-left, bottom-left), then slots 5–8 down the right side (upper-right, right, lower-right, bottom-right). JSON array order is preserved, not clockwise. The bottom caption repeats the highlighted entry and is not a ninth slot.

Append ` >` to submenu labels and ` <` to Back labels automatically while constructing the native config, once per load. Apply the decorated label to both wheel option text and the highlighted-option caption. Store plain authored labels in JSON. Close and intent labels remain undecorated. Keep shipped labels short; do not impose a guessed hard character limit, truncate, or rewrite user labels.

## Intent catalog and authored narration

The editable catalog is `SKSE/Plugins/PlayerSignals/intents.json`, alongside `layout.json` in the installed mod. Its root contains exactly integer `schemaVersion: 1` and a nonempty `intents` object. Each lowercase ASCII ID (`[a-z][a-z0-9_]*`) has exactly three required nonempty UTF-8 strings: `narration`, `notification`, and `targetedNotification`; records and root allow no extra fields. All three phrases omit the player name and final period. The literal `{target}` marker appears exactly once in `targetedNotification` and nowhere in `narration` or `notification`. JSON comments and trailing commas are invalid. Lua validates every catalog record, including unused ones, before validating layout references, then splits the target template into native prefix/suffix maps. The JSON catalog—not a hardcoded Lua list—defines the registry. The 25 entries below are shipped defaults, not a fixed registry limit; additional valid IDs may be added in JSON.

Every phrase must end without a period. A final period followed only by trailing ASCII whitespace is also invalid, preventing doubled punctuation when the controller adds the final period. A misplaced `{target}` marker or malformed authored template rejects the catalog instead of passing a literal marker into feedback.

| ID | Narration phrase | Untargeted notification phrase |
|---|---|---|
| confirm | `nods in agreement` | `nods in agreement` |
| deny | `shakes their head in disagreement` | `shakes their head in disagreement` |
| greet | `gives a friendly wave in greeting` | `greets` |
| farewell | `waves goodbye` | `waves goodbye` |
| thanks | `bows their head in thanks` | `gives thanks` |
| sorry | `makes an apologetic gesture` | `apologizes` |
| respect | `bows respectfully` | `shows respect` |
| welcome | `opens their arms in welcome` | `welcomes` |
| congratulate | `applauds in congratulations` | `congratulates` |
| offer | `extends an open hand, offering to give something` | `offers something` |
| ask | `holds out an open hand, asking for something` | `asks for something` |
| come_here | `beckons for someone to come closer` | `beckons` |
| follow_me | `gestures for others to follow them` | `asks others to follow` |
| wait_here | `gestures for others to wait here` | `asks others to wait` |
| quiet | `gestures for quiet` | `asks for quiet` |
| ready | `signals that they are ready` | `signals readiness` |
| warn | `makes an urgent warning gesture` | `gives a warning` |
| attention | `waves to get attention` | `seeks attention` |
| unsure | `shrugs, indicating uncertainty` | `is unsure` |
| think | `pauses thoughtfully, asking for a moment to think` | `takes a moment to think` |
| not_understood | `gives a puzzled look, indicating they do not understand` | `does not understand` |
| approve | `gestures approval` | `approves` |
| disapprove | `gestures disapproval` | `disapproves` |
| challenge | `makes a challenging gesture` | `issues a challenge` |
| yield | `raises their hands in surrender` | `signals surrender` |

This is a valid complete one-entry catalog for a layout that references only `greet`; it is not a replacement for the shipped catalog when the shipped layout still references other IDs:

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

For this example, untargeted feedback is `Bill greets.`; targeted feedback to captured NPC Ted is `Bill greets Ted.`. Narration, group notification, and targeted notification phrases are authored without a player-name prefix or final period; the controller adds those at runtime. Preserve distinctions: Confirm vs Approve, Deny vs Disapprove, Greet vs Welcome, Unsure vs Not understood. Offer/Ask do not imply a completed transfer or a specific object. Ready refers only to the player; Warn invents no hazard; Challenge names no opponent.

## JSON configuration contract

File: `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json` relative to the repository; `SKSE/Plugins/PlayerSignals/layout.json` relative to the mod root.
Runtime path: `Data/SKSE/Plugins/PlayerSignals/layout.json`.
Intent catalog: `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json` relative to the repository; `SKSE/Plugins/PlayerSignals/intents.json` relative to the mod root.
Intent catalog runtime path: `Data/SKSE/Plugins/PlayerSignals/intents.json`.

```json
{
  "schemaVersion": 1,
  "root": "main",
  "input": { "openKeyCode": 184 },
  "wheels": {
    "main": [
      { "label": "Confirm / Yes", "intent": "confirm" },
      { "label": "Social", "submenu": "social" },
      { "label": "Close", "control": "close" }
    ],
    "social": [
      { "label": "Thank you", "intent": "thanks" },
      { "label": "Back", "control": "back" }
    ]
  }
}
```

This is a valid reduced layout; the shipped configuration contains all four eight-slot wheels.

- Use numeric `input.openKeyCode`, not a symbolic key name. Right Alt is `0xB8` / 184; Left Alt is a distinct binding. Accept keyboard scan codes 1–255; mouse/gamepad bindings are outside initial scope. Shift targeting uses fixed scan codes 42 and 54 and is not user-configurable.
- Root is a nonempty wheel name present in the wheels map.
- Each wheel is an ordered array with 1–8 positions. A null position is disabled; an entry has a nonempty label and exactly one of intent/submenu/control.
- Intent must name an ID in the validated JSON catalog (including the 25 shipped defaults); submenu must resolve to a wheel; control is back or close. Reject submenu cycles; Back uses navigation history, not a submenu link. Root Back closes.
- Disable all unused positions before opening each wheel. Never truncate oversized wheels or guess an unknown intent.
- Load and fully validate both JSON files at new-game initialization and every save load. File changes take effect on the next load; no live reload, file watcher, or config write-back.
- On a missing, malformed, or unsupported layout or catalog, release the candidate, clear active config, unregister the opening key, notify the user, and do not open or submit a guessed action. Correct the file(s) and load again. No silent default fallback.

### Schema requirements

| Field | Type and rule |
|---|---|
| schemaVersion | Required integer, exactly 1 |
| root | Required nonempty string naming an existing wheel |
| input | Required object |
| input.openKeyCode | Required integer, 1–255; JSON booleans/floats are not key codes |
| wheels | Required nonempty object mapping names to slot arrays |
| wheel slot array | 1–8 positions, each null or an entry object |
| entry.label | Required nonempty string; display text only |
| entry.intent | Optional string naming an ID in the validated intent catalog |
| entry.submenu | Optional string naming an existing wheel |
| entry.control | Optional string, exactly back or close |

Exactly one of intent/submenu/control must be present on each entry. Validate every wheel, including currently unreachable ones, before registering the key. Reject missing/wrong-type required fields, unsupported schema versions, unknown properties, invalid actions, broken references, and cycles. Duplicate use of a supported intent in separate slots is allowed. Unused trailing positions and explicit null positions are disabled, not selectable blank actions.

Strings must be valid UTF-8 without NUL characters; Papyrus/native string APIs cannot represent embedded NUL. Duplicate object keys are rejected rather than silently selecting a value.

The controller never edits or regenerates either JSON file. Changing a display label never changes intent identity. `intents.json` defines the registry and all three phrases; generic native dispatch/validation reads catalog maps by ID. Add a valid catalog record and reference its ID from `layout.json` to add an intent, without Lua/Papyrus edits or recompilation. Both files are read during load; edits apply after loading a save. Use plain JSON without comments or trailing commas. No YAML trigger workflow is used.

### Error behavior

| Failure | Required result |
|---|---|
| File missing, invalid JSON, or invalid schema | No active configuration or key registration; actionable notification and Papyrus trace |
| JContainers unavailable | Do not call its parsing APIs; disable this feature and report the missing dependency |
| SkyrimNet.esp is not loaded or SkyrimNetApi.GetBuildVersion() is empty at startup | Do not enable the feature; report the missing SkyrimNet native API dependency |
| UIExtensions menu unavailable/open fails | End the session without narration or control changes; report the failure |
| Out-of-range result, disabled slot, or stale session | End the session without narration or success notification |
| Captured NPC is invalid at submission | Fail closed without narration or success notification; never redirect to group/another NPC |
| DirectNarration returns nonzero | No success notification; no retry or alternate narration path |
| Malformed phrase/template (terminal period, including before trailing ASCII whitespace, or `{target}` outside `targetedNotification`) | Reject the catalog; report `intents.json` and the offending field; publish no active configuration or guessed fallback |

Report configuration errors with the file path and offending field/wheel/slot where available. Do not silently replace a bad key, truncate a wheel, reinterpret an action, or send a different intent.

### JContainers implementation contract

- Validate raw JSON through JContainers' Lua bridge (`JLua.evalLuaStr`, `jrequire("PlayerSignals.config")`) before building native containers. `JValue.readFromFile` cannot preserve the required raw schema because its decoder normalizes JSON booleans and reinterprets metadata/reference-like strings.
- The shipped `JCData/lua/PlayerSignals/config.lua` reads `layout.json` and its sibling `intents.json` once per load, validates their exact JSON types/properties/references and all wheels/catalog records, then constructs native JMap/JArray containers. Private output maps are `narrations`, `notifications`, `targetNotificationPrefixes`, and `targetNotificationSuffixes`. Prefixes/suffixes are split at the sole literal `{target}` marker in `targetedNotification`; it is forbidden in the other two phrase fields, and either split component may be empty. No editable ID/phrase registry remains in Lua.
- Only validated numeric fields use `JValue.objectFromPrototype` to preserve native integer types. Native maps receive strings directly rather than via the special-string JSON decoder.
- Wheel names are exact, case-sensitive JSON references. Internally canonical numeric string keys avoid JContainers' case-insensitive map-name collisions; intent IDs retain authored values and labels receive only the action-derived navigation suffix. Cycle checking and browsing use iterative algorithms.
- Validate `JValue.isMap/isArray`, `JMap.hasKey/valueType`, and `JArray.valueType` at the native boundary before typed access. Raw validation is authoritative for the full schema; the Papyrus boundary check does not duplicate it.
- Traverse with `JMap.getObj/getStr/getInt`, `JArray.getObj/count`, and map key iteration. Preserve array order.
- Controller retains the validated root with `JValue.retain(root, "PlayerSignals")`; children remain reachable from it. Release the previous owned root on maintenance replacement. Do not separately release borrowed child handles.
- Confirm JContainers runtime availability before parsing. Compile-time declarations do not establish native availability. Installed JContainers Lua support is required; an unavailable module/bridge fails closed with a diagnostic.
- If JContainers disappears after a save, disable input but preserve the owned handle until the native dependency is restored; do not call unavailable release natives or discard ownership.

## Controller, input, and cancellation contract

Plugin: `PlayerSignals.esp`, a standalone ESL-flagged plugin with a StartGameEnabled quest and a forced player reference alias. Generate a matching SEQ file for startup. No override of an existing SkyrimNet quest or wheel script.

- Quest script `PlayerSignals_Controller` owns config, binding, navigation, targeting, and dispatch.
- Alias script `PlayerSignals_PlayerAlias` uses OnInit and OnPlayerLoadGame to schedule maintenance on its owning controller. Use the delayed startup pattern inspected in `SkyrimNet_iActions_dev/Source/Scripts/iActions_BootstrapAlias.psc` as an API/lifecycle reference; do not rely on Quest.OnPlayerLoadGame.
- Startup checks that `SkyrimNet.esp` is loaded and `SkyrimNetApi.GetBuildVersion()` returns a nonempty value before enabling this feature. Maintenance clears stale session/navigation/target state, releases previous config ownership, unregisters the old binding, loads valid config, and registers the configured key.
- Ignore opening while in another menu, while gameplay controls disallow menu/movement interaction, or while this controller already has a wheel session. Guard the entire submenu loop against re-entry.
- Capture the crosshair NPC before opening the root wheel. Keep the capture fixed until the wheel closes. Immediately after `Browse` returns a final accepted intent, sample either Shift scan code 42/54 before feedback/catalog lookups, then apply the group override according to the target table above.
- Get/reset the stock menu with `UIExtensions.GetMenu("UIWheelMenu", true)` for each displayed wheel. Set optionText, optionLabelText, and optionEnabled explicitly for all eight positions.
- Use an iterative navigation loop/stack, not recursive submenu functions. Opening returns only after that wheel closes; one direct narration call is made at most once after leaving the loop.
- Only an index 0–7 addressing a configured enabled slot is dispatchable. Stock SWF Tab cancellation calls closeMenu(-1). Stock Papyrus wait/block failures return 255. Both, and any other out-of-range result, exit without dispatch.
- Back navigates to the previous wheel; Close exits. Cancel exits the session from any level. Confirm cancellation after prior successful selections does not return stale intent data.
- Do not call DisablePlayerControls/EnablePlayerControls; let UIExtensions own menu input handling so this feature does not override another system's control restrictions.
- Do not call animation or item-transfer APIs.

### State and dispatch invariants

| State / input | Transition and effect |
|---|---|
| Disabled → initialization/load | Check required dependencies and full config; become Ready only on success |
| Ready → opening key | Capture crosshair NPC before displaying root; start one session if gameplay/menu gates permit |
| Browsing → opening key/repeat | Ignore; never start a second session |
| Browsing → submenu | Push current wheel and open referenced wheel; no narration |
| Browsing → Back | Pop navigation history, or close at root; no narration |
| Browsing → Close/Tab/failure | Clear pending intent and end session; no narration |
| Browsing → valid intent | Capture configured ID and final result; close wheel; sample Shift before feedback/catalog lookups; validate captured actor is alive, enabled, and 3D-loaded if targeting; submit once |
| Any → save load/maintenance | Invalidate stale session/target state, release ownership safely, and reload config/binding |

Never retain a prior selection as a default result. A selection returning after maintenance must not dispatch against a replacement config or stale captured actor. A stale stack is silent. Keep JContainers ownership valid across any latent menu wait and release session-owned handles on every exit.

Input registration is idempotent: remove the previously registered feature key before installing the configured key. Do not unregister keys owned by other scripts. Right Alt is the opening key, not a modifier held throughout selection. Shift 42 and 54 are sampled only when the final intent selection returns.

### Save and install/remove safety

The stable startup quest/SEQ and player alias `OnInit`/`OnPlayerLoadGame` maintenance path are designed to initialize new and existing saves. This cutover adds no saved controller fields/variables, property-default changes, alias or quest/FormID changes; Lua rebuilds the private native maps from both JSON files at load. Existing-save installation/update is supported by design, but the current path has not been verified in-game. Back up before installing or updating.

PlayerSignals does not add gesture spells, edit NPC world records, or toggle player controls. There is no shutdown/uninstall cleaner, and saves may retain quest/script state; simply deleting files mid-playthrough does not guarantee clean removal. The safest save-state rollback is to restore a backup from before installation, then remove the mod. SkyrimNet may retain narration history separately; restoring a Skyrim save does not erase that history.


### Local submission feedback

For a valid, current selection, call the appropriate targeted or group `SkyrimNetApi.DirectNarration` form exactly once. On return `0`, emit one local notification. Group mode uses `<player> <notification>.`; targeted mode uses `<player><prefix><captured NPC display name><suffix>.`, where prefix and suffix come from the JSON `targetedNotification` split. For `greet`, that yields `Bill greets.` in group mode and `Bill greets Ted.` when the captured recipient is Ted. The name is from the NPC captured before the wheel opened, not the current crosshair; Shift-to-group must omit it. Resolve the recipient name once, reuse it for narration and feedback, then revalidate the actor before the final generation guard and API call. Invalid/stale selections and nonzero API results produce no success notification. Wording comes from the intent catalog, never the wheel label.

This notification is local submission feedback only. It does not prove SkyrimNet processing, narration delivery, an NPC reply, or compliance. Group narration explicitly addresses everyone nearby but does not force all replies.

## Dependency and packaging contract

Required: SKSE, UIExtensions with stock-compatible wheel scripts/SWF, JContainers API 4 / feature 2 with working Lua support, and SkyrimNet with `SkyrimNet.esp` loaded, nonempty `SkyrimNetApi.GetBuildVersion()`, and `SkyrimNetApi.DirectNarration`. PapyrusUtil is not a dependency of this implementation.

Do not modify MO2 activation, symlinks, or load order without explicit approval. The original animation mod's loose `UIWheelMenu.pex` override was observed historically; stock UIExtensions must be effective, and coexistence with the old override is not promised. Do not bundle external framework assets or copy dependency PEX/SWF/source.

Implemented feature files include:
- `PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc`
- `PlayerSignals/Source/Scripts/PlayerSignals_PlayerAlias.psc`
- `PlayerSignals/Scripts/PlayerSignals_Controller.pex`, `PlayerSignals_PlayerAlias.pex`
- `PlayerSignals/PlayerSignals.esp`, `PlayerSignals/SEQ/PlayerSignals.seq`
- `PlayerSignals_spriggit/` for authored plugin records, outside the mod root
- `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json`
- `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json`
- `PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua`
- `build/build.ps1`, `build/TESV_Papyrus_Flags.flg` outside the mod root
- `tests/test_config.py` outside the mod root (development-only LuaJIT regression suite)

No current external manifest, trigger package, or authored YAML activation procedure is part of the design.

## Build contract

Build with `build/build.ps1` from any directory. Its Papyrus import order is feature source → SKSE → JContainers → installed `SkyrimNet/Source/Scripts` → full vanilla source → stock UIExtensions source when supplied → fallback API declarations. The SkyrimNet source is a build input, not a redistributed mod dependency.

Prior build, test, and adapter-smoke evidence is historical and does not verify the JSON catalog/targeted-notification revision. Current scoped smokes and Papyrus compiles are partial evidence; all 15 unittests passed separately. The integrated full build failed at a later Spriggit step on the locked unchanged ESP; ESP/SEQ identity was independently checked, but this is not full-build success. In-game behavior remains pending as recorded in the plan.

## Acceptance criteria and verification

- Right Alt opens once per press; the crosshair NPC is captured before the wheel opens.
- With a still-valid captured NPC and no Shift held at final selection return, exactly one targeted direct narration is submitted with responder/originator context set to that NPC and listener context set to player. Narration text still names the player as gesture actor.
- Holding either Shift scan code 42/54 at the immediate post-`Browse` sample overrides targeting; the no-target case also uses group mode. Both call `DirectNarration(text, player, None)` once and explicitly say everyone nearby is addressed.
- A captured NPC that is no longer alive, enabled, or 3D-loaded before a non-overridden submission causes no API call, no redirection, and no success notification.
- Every selected ID resolves through the dynamically validated JSON registry: it includes the 25 shipped default records and may include additional records. The `narrations`, group `notifications`, and targeted notification prefix/suffix maps are built from JSON phrases; phrase values omit the player prefix/final period.
- Exactly one local player-named submission notification appears only when DirectNarration returns 0. Group wording excludes the recipient; targeted wording uses the display name of the NPC captured before the wheel opened, not the current crosshair. Either Shift key or no captured NPC produces group feedback without the discarded recipient name. Navigation, cancellation, failed calls, invalid targets, and stale stacks stay silent.
- No animation starts, item transfer occurs, or requested NPC action is forced. Direct narration requests a reaction, but speech and compliance are not guaranteed. Nearby witnesses may join.
- Navigate every submenu; test Back, root Close, Tab cancel, cancel after a prior intent, blocked/failed menu opening, invalidated sessions, startup dependency checks, and save-load/rebinding.
- Malformed/missing JSON, unknown IDs, excess slots, missing submenu targets, and submenu cycles fail closed without accidental narration.
- Verify stock-framework operation and actual winning script/SWF combination without changing profile/load order unless approved.
- Do not mark the JSON catalog/targeted-notification revision complete based on prior-build tests, archive routing, scoped source-derived smokes, or successful Papyrus compiles. Although the 15 unittests passed separately, the integrated full build failed; in-game acceptance remains unverified.

Verification strategy:
- Compile against real SKSE/UIExtensions/JContainers declarations and inspect both generated PEX files plus authored ESP/SEQ.
- Audit both shipped JSON files, Lua validation/native-map construction, and controller dispatch together: all 25 shipped defaults and any dynamic IDs, exact narration/group notification phrases, targeted prefix/suffix splitting, target/Shift branches, and one-call/success-notification behavior. Use a throwaway contract check rather than permanent source-text/wiring tests.
- Exercise the player-facing wheel, captured-target validity transitions, Shift group override, no-target group behavior, SkyrimNet API outcomes, notification return gating, save-load, and cancellation in game.
- Observe actual NPC reaction without equating API success with speech or compliance. Group address text is not a broadcast guarantee.
- If permanent tests are added, they must catch consumer-visible behavior such as wrong target, silent-failure regression, cancellation leakage, stale-session dispatch, target invalidation, narration-map mismatch, or notification gating—not copied source text or tautological forwarding.
- Report only checks actually exercised. Prior-build source/build/adapter-smoke evidence and archive routing are historical; current scoped smokes, Papyrus compiles, and separately run 15 unittests are recorded in the plan. The integrated full build failed, and in-game runtime acceptance remains pending.

## Implementation boundaries

- Always: maintain the approved target-capture/Shift behavior, all 25 distinct meanings, direct narration API paths, and silent fail-closed behavior; verify changed runtime behavior.
- Ask before: changing the targeting/direct-narration contract, adding animation/targeting/modifier features beyond this contract, changing user MO2 activation/order, or copying assets with unresolved redistribution rights.
- Never: restore the mod-event/YAML trigger package as a current implementation, add arbitrary narration JSON, silently redirect an invalid captured NPC, use a second submission path, or claim narration proves animation playback or NPC compliance.
- Style: use existing Papyrus event/function and UIExtensions API conventions; keep controller state private except required attachment/alias interfaces. Scripts use PlayerSignals-prefixed names, not old iPrompts/PlayerCommWheel aliases.

## Historical/pre-cutover evidence (not current verification)

The following records document the former `SendModEvent` plus SkyrimNet external YAML trigger architecture. They are retained only as historical evidence. They do not verify captured targeting, Shift override, `SkyrimNetApi.DirectNarration`, the current JSON-sourced native narration/feedback maps, notification return gating, or current build/runtime behavior.

- Before cutover, the inspected SkyrimNet native source established that `Form.SendModEvent` published `mod_event` with an actor sender and that matching YAML triggers could issue `direct_narration`. The former implementation used 25 `PlayerSignals_Intent_<id>` event filters and player sender `00000014`; none of this is the current submission contract.
- The supplied historical archive was `D:/Modlists/ADT/_log-dumps/SkyrimNetOutput_ASSOS-1.1.1_2026-09-30_22-41-47.zip`. Its canonical main log covers **2026-10-01 17:06:18.043–17:09:58.675**, SkyrimNet `0-26-0-0`. It recorded old external package discovery, 25 trigger/filter loads, and controller readiness.
- Historical Confirm at **17:06:52.957** reached direct narration but had no eligible nearby NPC. Historical Unsure at **17:09:40.173** selected Ralof and generated a response to `Sigma shrugs, indicating uncertainty.` Logs show processing/generation/TTS queueing, not that the user heard or saw the output. The archive predates the current direct-API/target-capture behavior and the current notification gating.
- The archive's decision/mood route reported HTTP 401 / missing authentication header at **17:09:41.707**; fallback returned ASSERTIVE and did not block that old Ralof generation. Supplemental OpenRouter files were stale (September 30) and are not evidence for the October 1 turns.
- Historical beta26 devkit validation against the former external package root reported `ok:true`, 25 files, and zero errors/warnings/unresolved/shadows, with no base tree. This is not current content validation or a direct-API runtime test.
- Historical builds compiled both Papyrus scripts with zero errors/warnings; seven LuaJIT raw-validator tests passed; a native-container-adapter Lua load smoke passed; Spriggit round-trip and generated ESP/SEQ bytes were inspected. These results predate this contract change and are not evidence that the current code builds or behaves correctly.
- Historical profile inspection found an enabled animation-wheel loose `UIWheelMenu.pex` override. User-supplied screenshots verified the former wheel's slot order and long-label clipping but predate navigation markers/shortened labels; neither proves current rendering.
- The pre-cutover archive documented above establishes only the old trigger-based paths. A later prior-build archive documents direct-narration routing but does not verify the current JSON catalog/targeted-notification revision. Neither establishes current-build behavior; no engine-attribution fix is claimed.
