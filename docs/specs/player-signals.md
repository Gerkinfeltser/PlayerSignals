# Specification: PlayerSignals (for SkyrimNet)

Status: Source implementation and generated artifacts present; strict configuration/data checks pass. Deployment and in-game acceptance remain unverified.
Updated: 2026-10-01

Release title: **PlayerSignals (for SkyrimNet)**.
Project/repository: `D:/gerkgit/SkyrimNet_PlayerSignals`.
Standalone mod root: `D:/gerkgit/SkyrimNet_PlayerSignals/PlayerSignals/`. Symlink this child folder into MO2 for testing, not the repository root. Documentation and authored Spriggit records stay outside the mod root.

This document is the authoritative behavior and interface contract. Implementation order and delegation live in [the implementation plan](../plans/player-signals.md). Changes to scope or contracts must update this spec before implementation.

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

### User Outcomes

1. Open a communication wheel with Right Alt and select a nonverbal intent without typing or speaking.
2. Have SkyrimNet narrate that chosen roleplay action using the player's identity, with nearby NPC reactions governed by SN.
3. Customize the opening key, labels, ordering, and sub-wheels by editing JSON and loading a save; no MCM or recompilation.
4. Navigate or cancel without accidentally communicating anything, playing animations, or leaving movement disabled.

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

### Schema Requirements

| Field | Type and rule |
|---|---|
| schemaVersion | Required integer, exactly 1 |
| root | Required nonempty string naming an existing wheel |
| input | Required object |
| input.openKeyCode | Required integer, 1–255; JSON booleans/floats are not key codes |
| wheels | Required nonempty object mapping names to slot arrays |
| wheel slot array | 1–8 positions, each null or an entry object |
| entry.label | Required nonempty string; display text only |
| entry.intent | Optional string; one of the 25 catalog IDs |
| entry.submenu | Optional string naming an existing wheel |
| entry.control | Optional string, exactly back or close |

Exactly one of intent/submenu/control must be present on each entry. Validate every wheel, including currently unreachable ones, before registering the key. Reject missing/wrong-type required fields, unsupported schema versions, unknown properties, invalid actions, broken references, and cycles. Duplicate use of a supported intent in separate slots is allowed. Unused trailing positions and explicit null positions are disabled, not selectable blank actions.

Strings must be valid UTF-8 without NUL characters; Papyrus/native string APIs cannot represent embedded NUL. Duplicate object keys are rejected rather than silently selecting a value.

The controller never edits or regenerates the user's JSON. Changing a display label never changes the intent identity; only entry.intent determines which named event is sent.

### Error Behavior

| Failure | Required result |
|---|---|
| File missing, invalid JSON, or invalid schema | No active configuration or key registration; actionable notification and Papyrus trace |
| JContainers unavailable | Do not call its parsing APIs; disable this feature and report the missing dependency |
| UIExtensions menu unavailable/open fails | End the session without an event or control changes; report the failure |
| Out-of-range result or disabled slot | End the session without an event |
| Intent trigger missing/disabled or SN rejects/filters the event | No automatic retry or direct-narration bypass; diagnose through SN's monitor |

Report configuration errors with the file path and offending field/wheel/slot where available. Do not silently replace a bad key, truncate a wheel, reinterpret an action, or send a different intent. SN reaction-disabled state is not an instruction to bypass SN settings.

JContainers API contract:
- **Approved implementation adjustment (2026-10-01):** validate the raw file through JContainers' Lua bridge (`JLua.evalLuaStr`, `jrequire("PlayerSignals.config")`) before building native containers. `JValue.readFromFile` cannot preserve the required raw schema: its decoder converts JSON booleans to integers and reinterprets metadata/reference-like strings. No new runtime dependency is added.
- The shipped `JCData/lua/PlayerSignals/config.lua` reads the file once, validates exact JSON types/properties/actions/references and every wheel, then constructs JMap/JArray containers. Only validated numeric fields use `JValue.objectFromPrototype` to preserve native integer types. Native maps receive strings directly rather than via the special-string JSON decoder.
- Wheel names are exact, case-sensitive JSON references. Internally canonical numeric string keys avoid JContainers' case-insensitive map-name collisions; labels and intent IDs retain their authored values. Cycle checking and browsing use iterative algorithms.
- Validate `JValue.isMap/isArray`, `JMap.hasKey/valueType`, and `JArray.valueType` at the native boundary before typed access. Raw validation is authoritative for the full schema; the Papyrus boundary check does not duplicate it.
- Traverse with `JMap.getObj/getStr/getInt`, `JArray.getObj/count`, and map key iteration. Preserve array order.
- Controller retains the validated root with `JValue.retain(root, "PlayerSignals")`; children remain reachable from it. Release the previous owned root on maintenance replacement. Do not separately release borrowed child handles.
- Confirm JContainers runtime availability before parsing. Compile-time declarations do not establish native availability.
- Installed JContainers Lua support is required. An unavailable module/bridge fails closed with a diagnostic. If JContainers disappears after a save, disable input but preserve the owned handle until the native dependency is restored; do not call unavailable release natives or discard ownership.

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

### State and Dispatch Invariants

| State / input | Transition and effect |
|---|---|
| Disabled → initialization/load | Validate dependencies and full config; become Ready only on success |
| Ready → opening key | Start one session at the configured root if gameplay/menu gates permit |
| Browsing → opening key/repeat | Ignore; never start a second session |
| Browsing → submenu | Push current wheel and open the referenced wheel; no event |
| Browsing → Back | Pop navigation history, or close at root; no event |
| Browsing → Close/Tab/failure | Clear pending intent and end session; no event |
| Browsing → valid intent | Capture the configured ID, end session, then submit that ID once |
| Any → save load/maintenance | Invalidate stale session state, release ownership safely, and reload config/binding |

Do not retain a prior selection as a default result. A selection returning after maintenance must not dispatch against a replacement config; invalidate the old session before reading/dispatching it. Keep JContainers ownership valid across any latent menu wait and release session-owned handles on every exit.

Input registration is idempotent: remove the previously registered feature key before installing the configured key. Do not unregister keys owned by other scripts. Right Alt is an ordinary configurable opening key, not a required modifier held throughout selection. No automatic registration of Left Alt, Ctrl+Alt, or a second fallback key.

The mod emits exactly one SendModEvent call per accepted communication selection, not one call per highlighted slot or menu-close callback. SendModEvent provides no delivery acknowledgement; submission, SN trigger execution, narration, and NPC speech are distinct evidence layers.

## Dependency and Override Preflight

Required: SKSE, UIExtensions with stock compatible wheel scripts/SWF, JContainers, and SkyrimNet with the verified mod-event trigger contract. PapyrusUtil is not a dependency of this implementation.

Selected MO2 profile at inspection: `SkyrimNet_iActions_dev`. It enables `_iSetup_symlink`, UIExtensions, JContainers, PapyrusUtil, `skyrimnet-beta26-rc1`, and Idle Animations Wheel Menu; beta25 packages are disabled.

The original animation mod supplies a loose `UIWheelMenu.pex` that modifies the stock menu and references its ESP globals. Do not assume this is compatible just because the controller avoids its spells. The implementation/proof requires stock UIExtensions to be effective. Resolve the original override in MO2 before the smoke session; do not silently disable mods, reorder dependencies, or redistribute/copy a replacement dependency PEX. Coexistence with the original override is not promised.

Depend on separately installed framework assets rather than bundle them. Check permissions before copying any external source/assets; independent API use is not a blanket redistribution license.

## Files and Build Contract

Implemented feature files:
- `PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc`
- `PlayerSignals/Source/Scripts/PlayerSignals_PlayerAlias.psc`
- `PlayerSignals/Scripts/PlayerSignals_Controller.pex`, `PlayerSignals_PlayerAlias.pex`
- `PlayerSignals/PlayerSignals.esp`, `PlayerSignals/SEQ/PlayerSignals.seq`
- `PlayerSignals_spriggit/` for authored plugin records, outside the mod root
- `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json`
- `PlayerSignals/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/manifest.json`
- `PlayerSignals/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/triggers/player_signals_<intent_id>.yaml`
- `PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua`
- `build/build.ps1`, `build/TESV_Papyrus_Flags.flg` outside the mod root
- `tests/test_config.py` outside the mod root (development-only LuaJIT regression suite)

The authored trigger bundle is shipped from `external/phospheneoverdrive.playersignals/`; its manifest declares package ID `phospheneoverdrive.playersignals` and owner namespace `phospheneoverdrive`. The legacy `overlay/triggers/` directory is for player-authored edits, not the mod's authored shipped bundle. Keep no duplicate authored trigger copies in the overlay after cutover.

### External Package Migration Status

- Source packaging is complete: all 25 authored trigger files were migrated byte-identically by per-file SHA-256 fingerprints to `external/phospheneoverdrive.playersignals/triggers/`; the legacy empty overlay trigger directory was removed.
- The manifest uses version `0.1.0` and `min_skyrimnet_version` `0.26.0`, a conservative beta26 devkit/headless-validation target, not an in-game-tested compatibility minimum.
- The beta26 devkit `content-validate.exe` passed against the external package root: `ok:true`, 25 files, package ID `phospheneoverdrive.playersignals`, 0 errors, 0 warnings, 0 unresolved items, and 0 shadows. No base tree was supplied, so this does not establish base-tree compatibility.
- Runtime installation, trigger loading/activation, and in-game behavior remain unverified and gated; no MO2 changes were made. Package validation does not establish runtime acceptance.

Build from any directory with `build/build.ps1`. It supplies absolute compiler flags from this repository and ordered imports: feature source, full SKSE source, installed JContainers source, full vanilla source, stock UIExtensions source if supplied, then fallback GamePlugin API declarations.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1 -UiExtensionsSources '<temporary stock UIExtensions source directory>'
python -m pip install "lupa==2.8"
python -m unittest discover -s tests -v
```

The default UIExtensions path is a local API-declaration fallback, not proof of framework runtime availability. Implementation verification compiled both scripts against actual stock UIExtensions source extracted from the installed BSA to a disposable external directory. No dependency source or framework PEX/SWF is redistributed.

Pin authored Spriggit records to package `Spriggit.Yaml.Skyrim` 0.40.0, matching the available tool/pattern. Generate the SEQ from the authored startup quest FormID as part of the feature build; do not reuse an unrelated plugin's SEQ.

Compiler finding: putting GamePlugin stub headers before full vanilla imports caused SKSE Quest.psc to fail because the stub GlobalVariable lacks its Value property. Full vanilla imports must precede fallback headers. The repository build owns its flags and avoids unrelated shared-build edits.

Before runtime verification, register the `PlayerSignals/` child folder as its own MO2 symlink and enable `PlayerSignals.esp` in the selected profile. Do not symlink the repository root, put feature artifacts into iPrompts' `_iSetup`, or copy them to another mod root. No symlink, profile, or plugin activation was performed during repository setup.


## Acceptance Criteria and Verification
- Right Alt opens once per press; selecting Confirm emits one player-originated named mod event and one intended direct narration.
- Observe actual NPC reaction under enabled SN reaction settings; do not equate event submission with speech.
- Navigate every submenu; test Back, root Close, Tab cancel, cancel after a prior intent, and blocked/failed menu opening. No navigation/cancellation emits an intent.
- Every supported ID resolves to the correct narration. No animation starts and no movement restriction remains.
- Save/load and new-game initialization restore the binding/config. Changing openKeyCode and loading removes the previous binding; changing layout takes effect at the same load point.
- Malformed/missing JSON, unknown IDs, excess slots, missing submenu targets, and submenu cycles fail closed with no accidental intent.
- Verify stock-framework operation without IdlePlayWheelMenu.esp or its SN bundle enabled, plus the actual winning script/SWF combination.
- Observe named mod events in the SN event monitor. Persisted event history alone is insufficient because mod_event is ephemeral. Use installed event-monitor/harness endpoints only after confirming server availability and version.

Verification strategy:
- Compile against real SKSE/UIExtensions/JContainers declarations and confirm both generated PEX files plus the authored ESP/SEQ.
- Validate actual default JSON and YAML together: 25 supported IDs, matching event names/templates, correct player filter, valid references, eight-slot boundaries. Use a throwaway contract check rather than permanent source-text/wiring tests.
- Exercise the player-facing wheel and SN event monitor in game for the matrix above. Include malformed-config and save-load transitions, not just a successful Confirm.
- Confirm the raw mod event does not independently provoke a reaction, and the matching direct narration does. Missing or multiple NPC replies are evaluated against SN settings, not guessed from publisher success.
- If permanent tests are added, they must catch consumer-visible errors such as wrong intent dispatch, cancellation leakage, stale session dispatch, config precedence, or key rebinding—not copied source text or tautological forwarding.
- Do not mark runtime acceptance complete from compilation, file presence, or API declarations. Record unavailable runtime prerequisites explicitly.

## Implementation Boundaries

- Always: implement the complete agreed 25-intent default, maintain distinct intent meanings, compile with the verified import order, and verify changed runtime behavior.
- Ask before: changing the event/trigger design, adding animation/targeting/modifier features, changing user MO2 activation/order, or copying assets with unresolved redistribution rights.
- Never: copy the original animation mod's files, modify unrelated projects, silently bypass SN reactions with a second submission path, or claim narration proves animation playback.
- Style: use the existing Papyrus event/function and UIExtensions API conventions; keep controller state private except required attachment/alias interfaces. Scripts use PlayerSignals-prefixed names and event names from this spec, not old iPrompts/PlayerCommWheel aliases.

## Verification Evidence and Remaining Runtime Gates

Historical contract-resolution evidence (not current runtime proof):
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

Implementation-session evidence:
- Both feature scripts compiled with zero errors/warnings against real installed SKSE/JContainers/vanilla declarations and stock UIExtensions BSA source, then rebuilt with repository-owned compiler flags.
- Generated standalone ESP serialized back through Spriggit 0.40.0 and passed its round-trip sanity check: ESL `Small` flag, StartGameEnabled quest `000800`, attached controller, alias 0 attached player-alias script, forced player reference `000014:Skyrim.esm`.
- Integrated build generated SEQ bytes `00 08 00 00`, corresponding to startup quest FormID `00000800`. Generated PEX headers and ESP flag were independently inspected.
- Pre-cutover, four eight-slot wheels and exactly 25 local trigger files passed a throwaway joint contract check: catalog IDs, named events, player sender filter, exact narration, nearby audience, enabled/probability/cooldown/priority. Those trigger sources have since been migrated byte-identically into the external package; current package validation is recorded above.
- Seven permanent regression tests execute the shipped raw schema validator on LuaJIT: numeric types/boundaries, disabled positions, exact IDs/references, unknown properties, action exclusivity, unreachable cycles, Unicode/JSON syntax, and 200-level valid navigation graphs.
- A throwaway smoke executed the shipped Lua `load` path using a native-container boundary adapter: shipped defaults loaded; malformed/invalid configurations failed closed; null/reduced layouts and metadata/reference-like strings with case-distinct wheel names loaded. This does **not** verify the installed native bridge.
- Luna implemented layout/triggers with config/narration reviews and performed an adversarial integration review. Primary repaired one malformed YAML indentation and retained ownership on dependency loss; stale maintenance requests are rescheduled. Independent reviewer/scout validation is recorded in the plan.
- Independent reviewer confirmed and then validated repairs to stale readiness publication and post-guard player lookup. Key registration now has pre/post-call generation guards and mismatch cleanup; the final readiness commit has no external calls. Player identity is captured before the opening/dispatch guards. Final rebuilt scripts compiled cleanly; actual scheduler/interleaving behavior still requires the game.
- No Skyrim process was found; `http://127.0.0.1:8080/harness?api=status` could not connect. User explicitly chose to leave MO2 unchanged. No MO2 registration/activation/order or external-project changes were made. Wheel UI, actual native Lua bridge, key behavior, load transitions, event processing/narration and NPC reaction remain runtime gates.
