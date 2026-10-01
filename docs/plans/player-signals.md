# PlayerSignals (for SkyrimNet)

Status: Implementation specification — source/API contracts resolved; feature not implemented or runtime-verified.
Updated: 2026-10-01

Release title: **PlayerSignals (for SkyrimNet)**.
Project/repository: `D:/gerkgit/SkyrimNet_PlayerSignals`.
Standalone mod root: `D:/gerkgit/SkyrimNet_PlayerSignals/PlayerSignals/`. Symlink this child folder into MO2 for testing, not the repository root. Documentation and authored Spriggit records stay outside the mod root.

## Goal and Scope

Provide a JSON-configurable player communication wheel. Selecting an entry submits an authored roleplay action to SkyrimNet through an intent event and matching narration trigger. No animation playback is required.

Example: Confirm narrates that the player nods in agreement. This is an authored roleplay action, not a claim that a visible animation was observed.

Decided:
- UIExtensions, eight slots per wheel, nested sub-wheels, independent Papyrus controller.
- JContainers for JSON; no MCM, separate INI, custom DLL, or custom Scaleform implementation.
- Default opening key Right Alt; keyboard scan code configurable in JSON.
- One intent event per communication selection. Back, Close, submenus, and cancellation emit none.
- Predefined intent IDs; narration lives in SN YAML triggers, not arbitrary user text in JSON.
- No animation spells, event playback, gesture mappings, lifecycle management, item transfers, forced NPC actions, explicit recipient selection, or modifier-selection actions.
- Requests communicate intent, not NPC compliance.

This supersedes the proposal to patch Idle Animations WheelMenu SE. Do not depend on its ESP/bundle, copy its scripts/assets, or change the separate `SkyrimNet_Emote` project. The old animation triggers need not be disabled: this controller never casts their matching spells.

## Resolved Architecture

```text
Right Alt → controller → UIExtensions wheel
  submenu / Back → navigation only
  Close / Tab / invalid result → exit only
  intent selection → close → player.SendModEvent
    → SN mod_event monitor → matching trigger → direct_narration
```

### Intent Publisher and Trigger Contract

Use one distinct SKSE mod event per supported ID:
`PlayerSignals_Intent_<intent_id>` (lowercase IDs exactly as catalogued below).

```papyrus
Game.GetPlayer().SendModEvent("PlayerSignals_Intent_confirm", "", 0.0)
```

`Form.SendModEvent` takes three arguments; the receiver is the sender. Calling it on the player, rather than the controller quest, supplies actor identity to SN. Do not pass a fourth Actor argument or substitute the variable-argument `ModEvent` API.

Confirmed in the inspected native source:
- `ModEventHandler` resolves an Actor sender to the event originator and publishes `mod_event` with top-level `event_name`, `str_arg`, `num_arg`, and sender metadata.
- TriggerManager collects `event_name` conditions from enabled triggers and updates the mod-event name filter. Loading/enabling the matching triggers is therefore required before events can be observed/processed; no separate Papyrus registration is required.
- `mod_event` is ephemeral, processing-enabled, and defaults to no autonomous NPC reaction. Only the matching direct-narration response should request a reaction.
- Do not use `RegisterEvent("custom", ...)`: the custom schema defaults to autonomous reactions and could produce an extra response before the trigger's narration.
- Direct narration's ordinary path performs nearby actor discovery. It does not use the incomplete `DetermineAudience` nearby branch.
- `{{ originator }}` is the originator's display name. Match the player sender explicitly, then use that variable in narration.

Concrete Confirm trigger:

```yaml
name: player_signals_confirm
description: PlayerSignals - Confirm
eventCriteria:
  - eventType: mod_event
    schemaConditions:
      - fieldPath: event_name
        operator: equals
        value: PlayerSignals_Intent_confirm
      - fieldPath: sender_form_id
        operator: equals
        value: "00000014"
response:
  type: direct_narration
  content: "{{ originator }} nods in agreement."
audience: nearby_npcs
enabled: true
probability: 1.0
cooldownSeconds: 0
priority: 5
```

Use this pattern for all 25 intents. No feature-level cooldown or automatic retries: one deliberate selection means one submission. SN's own processing/reaction settings still apply; this does not guarantee exactly one spoken NPC response.

## Default Wheel Layout

| Slot | Main | Social | Signals | Attitude |
|---|---|---|---|---|
| 1 | Confirm / Yes | Thank you | Come here | Unsure / I don't know |
| 2 | Deny / No | Sorry | Follow me | Let me think |
| 3 | Greet | Show respect | Wait here | I don't understand |
| 4 | Farewell | Welcome | Quiet / Be silent | Approve |
| 5 | Social submenu | Congratulations / Well done | Ready | Disapprove |
| 6 | Signals submenu | Offer something | Watch out | Challenge / Provoke |
| 7 | Attitude submenu | Ask for something | Get attention | Yield / Surrender |
| 8 | Close | Back | Back | Back |

25 communication intents; navigation/control entries consume slots. Keep the shipped layout at one submenu level, while allowing deeper valid layouts through JSON.

Look over there and Look down here remain excluded. Narration-only operation still cannot identify what is being pointed at without a targeting contract.

## Intent Catalog and Authored Narration

Each template begins with the verified `{{ originator }}` identity variable. These are the initial default wordings, editable in the corresponding YAML definitions.

| ID | Narration |
|---|---|
| confirm | `{{ originator }} nods in agreement.` |
| deny | `{{ originator }} shakes their head in disagreement.` |
| greet | `{{ originator }} gives a friendly wave in greeting.` |
| farewell | `{{ originator }} waves goodbye.` |
| thanks | `{{ originator }} bows their head in thanks.` |
| sorry | `{{ originator }} makes an apologetic gesture.` |
| respect | `{{ originator }} bows respectfully.` |
| welcome | `{{ originator }} opens their arms in welcome.` |
| congratulate | `{{ originator }} applauds in congratulations.` |
| offer | `{{ originator }} extends an open hand, offering to give something.` |
| ask | `{{ originator }} holds out an open hand, asking for something.` |
| come_here | `{{ originator }} beckons for someone to come closer.` |
| follow_me | `{{ originator }} gestures for others to follow them.` |
| wait_here | `{{ originator }} gestures for others to wait here.` |
| quiet | `{{ originator }} gestures for quiet.` |
| ready | `{{ originator }} signals that they are ready.` |
| warn | `{{ originator }} makes an urgent warning gesture.` |
| attention | `{{ originator }} waves to get attention.` |
| unsure | `{{ originator }} shrugs, indicating uncertainty.` |
| think | `{{ originator }} pauses thoughtfully, asking for a moment to think.` |
| not_understood | `{{ originator }} gives a puzzled look, indicating they do not understand.` |
| approve | `{{ originator }} gestures approval.` |
| disapprove | `{{ originator }} gestures disapproval.` |
| challenge | `{{ originator }} makes a challenging gesture.` |
| yield | `{{ originator }} raises their hands in surrender.` |

Preserve distinctions: Confirm vs Approve, Deny vs Disapprove, Greet vs Welcome, Unsure vs Not understood. Offer/Ask do not imply a completed transfer or a specific object. Ready refers only to the player; Warn invents no hazard; Challenge names no opponent.

## JSON Configuration Contract

File: `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json` relative to the repository; `SKSE/Plugins/PlayerSignals/layout.json` relative to the mod root.
Runtime path: `Data/SKSE/Plugins/PlayerSignals/layout.json`.

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

The example is a valid reduced layout; the shipped configuration contains all four eight-slot wheels above.

- Use numeric `input.openKeyCode`, not the earlier illustrative symbolic `openKey`. Right Alt is `0xB8` / 184; Left Alt is a distinct binding. Accept keyboard scan codes 1–255; mouse/gamepad bindings are outside initial scope.
- Root is a nonempty wheel name present in the wheels map.
- Each wheel is an ordered array with 1–8 positions. A null position is disabled; an entry has a nonempty label and exactly one of intent/submenu/control.
- Intent must be a catalog ID; submenu must resolve to a wheel; control is back or close. Reject submenu cycles; Back uses navigation history, not a submenu link. Root Back closes.
- Disable all unused positions before opening each wheel. Never truncate oversized wheels or guess an unknown intent.
- Load and fully validate configuration at new-game initialization and every save load. File changes take effect on the next load; no live reload, file watcher, or config write-back.
- On missing/malformed/unsupported configuration, release the candidate, clear active config, unregister the opening key, notify the user, and do not open/submit a guessed action. Correct the file and load again. No silent default fallback.

JContainers API contract:
- Parse with `JValue.readFromFile`; validate `JValue.isMap/isArray`, `JMap.hasKey/valueType`, and `JArray.valueType` before typed access.
- Traverse with `JMap.getObj/getStr/getInt`, `JArray.getObj/count`, and map key iteration. Preserve array order.
- Controller retains the validated root with `JValue.retain(root, "PlayerSignals")`; children remain reachable from it. Release the previous owned root on maintenance replacement. Do not separately release borrowed child handles.
- Confirm JContainers runtime availability before parsing. Compile-time declarations do not establish native availability.

## Controller, Input, and Cancellation Contract

Plugin: `PlayerSignals.esp`, a standalone ESL-flagged plugin with a StartGameEnabled quest and a forced player reference alias. Generate a matching SEQ file for startup. No override of an existing SkyrimNet quest or wheel script.

- Quest script `PlayerSignals_Controller` owns config, binding, navigation, and dispatch.
- Alias script `PlayerSignals_PlayerAlias` uses OnInit and OnPlayerLoadGame to schedule maintenance on its owning controller. Use the delayed startup pattern inspected in `SkyrimNet_iActions_dev/Source/Scripts/iActions_BootstrapAlias.psc` as an API/lifecycle reference; do not rely on Quest.OnPlayerLoadGame.
- Maintenance clears stale session/navigation state, releases previous config ownership, unregisters the old binding, loads valid config, and registers the configured key.
- Ignore opening while in another menu, while gameplay controls disallow menu/movement interaction, or while this controller already has a wheel session. Guard the entire submenu loop against re-entry.
- Get/reset the stock menu with `UIExtensions.GetMenu("UIWheelMenu", true)` for each displayed wheel. Set optionText, optionLabelText, and optionEnabled explicitly for all eight positions.
- Use an iterative navigation loop/stack, not recursive submenu functions. Opening returns only after that wheel closes; an intent is dispatched once after leaving the loop.
- Only an index 0–7 addressing a configured enabled slot is dispatchable. Stock SWF Tab cancellation calls closeMenu(-1). Stock Papyrus wait/block failures return 255. Both, and any other out-of-range result, exit without dispatch.
- Back navigates to the previous wheel; Close exits. Cancel exits the session from any level. Confirm cancellation after prior successful selections does not return stale intent data.
- Do not call DisablePlayerControls/EnablePlayerControls; let UIExtensions own menu input handling so this feature does not override another system's control restrictions.
- Verify Right Alt/AltGr and mod-hotkey conflicts in game; registering a key does not claim exclusive ownership.

## Dependency and Override Preflight

Required: SKSE, UIExtensions with stock compatible wheel scripts/SWF, JContainers, and SkyrimNet with the verified mod-event trigger contract. PapyrusUtil is not a dependency of this implementation.

Selected MO2 profile at inspection: `SkyrimNet_iActions_dev`. It enables `_iSetup_symlink`, UIExtensions, JContainers, PapyrusUtil, `skyrimnet-beta26-rc1`, and Idle Animations Wheel Menu; beta25 packages are disabled.

The original animation mod supplies a loose `UIWheelMenu.pex` that modifies the stock menu and references its ESP globals. Do not assume this is compatible just because the controller avoids its spells. The implementation/proof requires stock UIExtensions to be effective. Resolve the original override in MO2 before the smoke session; do not silently disable mods, reorder dependencies, or redistribute/copy a replacement dependency PEX. Coexistence with the original override is not promised.

Depend on separately installed framework assets rather than bundle them. Check permissions before copying any external source/assets; independent API use is not a blanket redistribution license.

## Files and Build Contract

Planned feature files:
- `PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc`
- `PlayerSignals/Source/Scripts/PlayerSignals_PlayerAlias.psc`
- `PlayerSignals/Scripts/PlayerSignals_Controller.pex`, `PlayerSignals_PlayerAlias.pex`
- `PlayerSignals/PlayerSignals.esp`, `PlayerSignals/SEQ/PlayerSignals.seq`
- `PlayerSignals_spriggit/` for authored plugin records, outside the mod root
- `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json`
- `PlayerSignals/SKSE/Plugins/SkyrimNet/overlay/triggers/player_signals_<intent_id>.yaml`

The existing overlay/triggers location is the local content convention. Public-release packaging may use the supported SN bundle format after its manifest/loading contract is checked; do not duplicate active trigger copies in overlay and a bundle.

Compile from the repo root with absolute flags and ordered imports. A disposable API probe compiled successfully with this order:

```powershell
$compiler = 'D:/Modlists/ADT/Game Root/Papyrus Compiler/PapyrusCompiler.exe'
$imports = 'D:/gerkgit/SkyrimNet_PlayerSignals/PlayerSignals/Source/Scripts;D:/Modlists/ADT/mods/Skyrim Script Extender (SKSE64)/Scripts/Source;D:/Modlists/ADT/mods/JContainers SE/scripts/source;D:/Modlists/ADT/Game Root/Data/Source/Scripts;D:/git/SkyrimNet-GamePlugin/headers'
& $compiler 'PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc' '-flags=D:/gerkgit/SkyrimNet_iPrompts/_build_tools/TESV_Papyrus_Flags.flg' "-import=$imports" '-output=D:/gerkgit/SkyrimNet_PlayerSignals/PlayerSignals/Scripts'
& $compiler 'PlayerSignals/Source/Scripts/PlayerSignals_PlayerAlias.psc' '-flags=D:/gerkgit/SkyrimNet_iPrompts/_build_tools/TESV_Papyrus_Flags.flg' "-import=$imports" '-output=D:/gerkgit/SkyrimNet_PlayerSignals/PlayerSignals/Scripts'
& 'D:/SkyrimMisc/SpriggitCLI/Spriggit.CLI.exe' deserialize -i 'PlayerSignals_spriggit' -o 'PlayerSignals/PlayerSignals.esp'
```

The flags path above references an existing workstation build resource, not a dependency on iPrompts' mod files. A distributable build workflow must document/provide appropriate compiler flags separately.

Pin authored Spriggit records to package `Spriggit.Yaml.Skyrim` 0.40.0, matching the available tool/pattern. Generate the SEQ from the authored startup quest FormID as part of the feature build; do not reuse an unrelated plugin's SEQ.

Compiler finding: putting GamePlugin stub headers before full vanilla imports caused SKSE Quest.psc to fail because the stub GlobalVariable lacks its Value property. Full vanilla imports must precede fallback GamePlugin headers. The generic wrapper also supplies a relative flags path; the explicit command above avoids both problems without unrelated shared-build edits.

Before runtime verification, register the `PlayerSignals/` child folder as its own MO2 symlink and enable `PlayerSignals.esp` in the selected profile. Do not symlink the repository root, put feature artifacts into iPrompts' `_iSetup`, or copy them to another mod root. No symlink, profile, or plugin activation was performed during repository setup.

## Delegation Using Luna

Runner verified: `omp --model openai-codex/gpt-6-luna --thinking low --no-session --print ...` executed successfully. Use read-only `--tools read,grep,glob,bash` for investigations or `--no-tools` with supplied source material for bounded content review. Do not claim the task tool's scout model is Luna; its interface has no per-call model selector.

| Independent slice | Delegated deliverable / ownership |
|---|---|
| UI/config contract review | Read-only review against fixed schema and wheel API |
| Narration catalog review | Check distinctions and avoid invented referents/outcomes |
| Trigger definitions | Own the 25 YAML files after IDs/event contract are fixed |
| Default layout | Own layout.json after schema and IDs are fixed |
| Adversarial review | Read-only cancellation, save-load, config-error, duplicate-event review |

Fan independent slices together; no shared controller edits. Primary owns controller/plugin architecture, integration, and final verification. Delegates skip builds/tests/lint/formatters mid-flight; compile and verify after integration.

Research for this revision used two read-only scout jobs, followed by primary source/binary checks. A separate Luna completion reviewed all 25 narration candidates; its suggestions to turn Offer/Ask into help requests were rejected to preserve the agreed meanings.

## Implementation Sequence and Acceptance

- [ ] Implement controller/alias attachment and configuration loader using the contracts above.
- [ ] Implement one complete Confirm/Cancel path with one installed matching trigger. This is a checkpoint, not reduced final scope.
- [ ] Implement all four default wheels, Back/Close, binding changes on load, and config errors.
- [ ] Add all 25 trigger definitions and final default layout; integrate delegated files.
- [ ] Compile feature scripts, build ESP/SEQ, confirm generated files, and activate in MO2 with stock UIExtensions effective.
- [ ] Exercise the complete runtime acceptance matrix; document results and configuration procedure in the existing repository docs.

Required runtime matrix:
- Right Alt opens once per press; selecting Confirm emits one player-originated named mod event and one intended direct narration.
- Observe actual NPC reaction under enabled SN reaction settings; do not equate event submission with speech.
- Navigate every submenu; test Back, root Close, Tab cancel, cancel after a prior intent, and blocked/failed menu opening. No navigation/cancellation emits an intent.
- Every supported ID resolves to the correct narration. No animation starts and no movement restriction remains.
- Save/load and new-game initialization restore the binding/config. Changing openKeyCode and loading removes the previous binding; changing layout takes effect at the same load point.
- Malformed/missing JSON, unknown IDs, excess slots, missing submenu targets, and submenu cycles fail closed with no accidental intent.
- Verify stock-framework operation without IdlePlayWheelMenu.esp or its SN bundle enabled, plus the actual winning script/SWF combination.
- Observe named mod events in the SN event monitor. Persisted event history alone is insufficient because mod_event is ephemeral. Use installed event-monitor/harness endpoints only after confirming server availability and version.

## Verification Evidence and Remaining Runtime Gates

Observed during contract resolution:
- Selected profile and enabled dependencies read from MO2 configuration.
- Right Alt 0xB8/184 verified in local CommonLib `RE/B/BSKeyboardDevice.h:112` and `REX/W32/DINPUT.h:134`.
- Stock UIExtensions BSA source and wheelmenu.swf decoded in memory. Flash handleInput's Tab branch calls closeMenu(-1); closeMenu sends close/choice callbacks and closes CustomMenu. Enabled selections pass their slot index.
- Mod-event schema/filter/publisher/narration contracts verified in `D:/git/SkyrimNet/src/EventSchemaRegistry.cpp:1484-1528`, `TriggerManager.cpp:697-721,1716-1781,1190-1220`, and `Skyrim/EventHandlers/ModEventHandler.cpp:174-257`.
- JContainers parse/access/ownership signatures verified in installed JValue/JMap/JArray sources.
- Disposable Papyrus API probe compiled with 0 errors and 0 warnings; its source and generated artifacts were removed. This proves compile-time API compatibility, not runtime behavior.
- Proposed default data passed a JSON round-trip and reference audit: four eight-slot wheels, 25 distinct supported intents, all submenu references resolved.
- Luna runner and narration review executed; Spriggit deserialize help executed and identified installed version 0.40.0.
- No SkyrimSE/SkyrimVR process or listener on the checked common server ports was present. No live event, wheel, narration, or NPC behavior was exercised.

The native checkout's exact revision parity with the installed beta26 DLL is unproven. Confirm installed runtime schema/monitor behavior during the first integration smoke. Current profile's original wheel override remains a preflight issue, not permission to alter user load order. These are runtime/deployment gates, not unresolved feature-design choices.

No feature implementation, profile changes, external-project changes, or CHANGELOG changes were made during this specification revision.
