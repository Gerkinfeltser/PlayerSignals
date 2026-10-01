# Implementation Plan: PlayerSignals (for SkyrimNet)

Status: Source implementation and generated artifacts complete; external trigger-package migration and manifest complete; beta26 devkit content validation passed against the package root only; MO2 deployment and full in-game acceptance remain gated. User chose to leave MO2 unchanged.
Updated: 2026-10-01

Authoritative behavior, schema, event, narration, and acceptance contracts: [PlayerSignals specification](../specs/player-signals.md). Do not duplicate or change those contracts in this plan.

## Work Location

- Repository: `D:/gerkgit/SkyrimNet_PlayerSignals`.
- Actual mod root: `PlayerSignals/`; only this child folder is symlinked into MO2.
- Authored plugin records: `PlayerSignals_spriggit/`, outside the mod root.
- Private GitHub repository: https://github.com/Gerkinfeltser/SkyrimNet_PlayerSignals.

## Phase 1 — Preflight and Attachment

- [ ] Confirm installed runtime schema/monitor behavior against the inspected native source. The observed overlay convention is historical and predates the external-package cutover; exact DLL revision parity remains unproven.
- [ ] Resolve the winning UIExtensions scripts/SWF before game verification. Read-only audit found the enabled original animation wheel's loose script override; user declined profile changes in this session.
- [x] Author standalone ESL-flagged quest/player-alias records and matching SEQ. No edits to SkyrimNet or the separate emote project.
- [x] Establish both script attachments and dependency checks using the lifecycle contracts. Actual startup/save-load scheduling still needs in-game observation.

Acceptance: authored records attach the controller and player alias correctly; new game and save load schedule maintenance. Verify record links and generated ESP/SEQ separately from runtime startup.

## Phase 2 — Config and Input

- [x] Implement strict raw-file validation through approved JContainers Lua, owned native root lifetime, and fail-closed errors.
- [x] Implement Right Alt default registration and JSON-configured rebinding on load (source/compiled evidence; runtime pending).
- [x] Implement session invalidation for maintenance/save-load and guards against another menu or re-entry.

Acceptance: valid config establishes one key binding; invalid config disables it without an intent. Save loading releases previous state and replaces the old binding at the documented point.

## Phase 3 — One Complete Selection Path

- [x] Implement root Confirm/Close through UIExtensions; no animation calls or player-control toggles.
- [x] Add the matching Confirm mod-event trigger.
- [ ] Exercise Confirm, Close, Tab cancel, cancel after a prior selection, and failed opening in game. Compilation passed; no player-facing runtime exercise occurred.

Acceptance: one Confirm emits one player-originated named event and the intended direct narration; cancellation/navigation emits none. Observe nearby NPC behavior under SN reaction settings. This is an integration checkpoint, not the final deliverable or a scope reduction.

## Phase 4 — Complete Default Feature

- [x] Implement iterative sub-wheel navigation, Back, disabled slots, and the complete supported schema.
- [x] Add all four default wheels and 25 supported intent definitions.
- [x] Integrate all 25 authored trigger files in the external package; the earlier joint contract audit confirmed IDs, events, filters, and narrations. Installed activation remains pending.

Acceptance: all defaults match the spec's meaning and layout; custom valid layouts work without recompilation. No duplicate trigger copies or second narration submission path.

## Phase 5 — Verification and Delivery

- [x] Compile with real dependency declarations/stock UIExtensions source and repository-owned flags; build ESP/SEQ and inspect generated artifacts.
- [x] Migrate all 25 authored trigger files byte-identically into `PlayerSignals/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/triggers/`, remove the empty legacy overlay trigger directory, and add the package-root manifest (`phospheneoverdrive.playersignals`, owner `phospheneoverdrive`, version `0.1.0`, target `min_skyrimnet_version` `0.26.0`; not an in-game-tested minimum).
- [x] Run beta26 devkit `content-validate.exe` against the external package root: `ok:true`, 25 files, matching package ID, 0 errors/warnings/unresolved/shadows. No base tree supplied; runtime remains unverified.
- [ ] Register the child-folder symlink and enable the plugin. **User chose to leave MO2 unchanged**; no activation/order changes made.
- [ ] Exercise the full in-game matrix: malformed config, targets, slot limits, cycles, save-load state, rebinding, cancellation and input restoration. No Skyrim runtime/harness available; profile gate also remains.
- [x] Record build/artifact/runtime evidence separately and document activation/configuration instructions in README. Runtime instructions are a pending procedure, not verified behavior.
- [x] Luna adversarial review completed; primary addressed owned-handle loss and stale-maintenance rescheduling. Independent role review findings and resolution are recorded below.

Acceptance: every spec criterion passes or an actual unreachable prerequisite is explicitly reported. No feature completion claim based only on compilation or file presence.

### Current Evidence and Next Runtime Gate

- Generated `PlayerSignals_Controller.pex` and `PlayerSignals_PlayerAlias.pex`: compiler zero errors/warnings. Stock framework source was extracted only to a temporary compile directory and is not shipped.
- Spriggit 0.40.0 built and round-tripped `PlayerSignals.esp`: `Small` flag; StartGameEnabled quest `000800`; controller attachment; alias 0 with player-alias attachment and forced player `000014:Skyrim.esm`.
- Build-generated `PlayerSignals.seq` contains little-endian `00000800` (`00 08 00 00`); PEX/ESP headers and SEQ bytes inspected.
- Seven LuaJIT regression tests passed for raw JSON/schema behavior. Throwaway load-entry smoke passed with a native-container adapter; this is not installed JContainers native-runtime proof.
- The pre-cutover joint content audit covered four eight-slot wheels and all 25 trigger IDs, event names, player filters and exact narrations. All 25 authored trigger files were migrated byte-identically into the external package, with no remaining overlay trigger directory. Beta26 devkit `content-validate.exe` passed against the package root (`ok:true`, 25 files, package ID `phospheneoverdrive.playersignals`, 0 errors, 0 warnings, 0 unresolved, 0 shadows); no base tree was supplied.
- Luna slices executed with explicit `openai-codex/gpt-6-luna`: default layout/config review, triggers/narration review, adversarial integration review. Reviewer/scout task roles were used for independent validation and are not claimed as Luna.
- Independent reviewer confirmed two additional source-level maintenance races: readiness published after yielding key-state/registration calls, and player lookup after the final dispatch guard. Primary moved key/held computation to locals, added pre/post-registration generation guards with cleanup, committed readiness without external calls, resolved/passed the player before final guards, and rechecked key/readiness/re-entry after gameplay gates. Reviewer re-read the fixes and reported no remaining established defect. This is source review, not in-game race verification.
- Read-only scout historically found the enabled animation-wheel loose `UIWheelMenu.pex` override and no active PlayerSignals provider. Its report that the installed `_iSetup_symlink` overlay supported the local trigger convention predates this external-package cutover; installed DLL/source parity and effective virtual SWF remain unproven.
- Runtime status request could not connect, and no Skyrim process was observed. No actual UI selection, named event, narration, NPC speech, save-load/rebinding, or control restoration has been exercised.

Next prerequisite: user authorizes a testing-profile change or supplies an already compatible profile with PlayerSignals activated, then a running SKSE game in normal world view. Do not infer permission from this plan or alter the current profile. Keep all unchecked runtime criteria open.


## Luna Delegation

Verified runner: `omp --model openai-codex/gpt-6-luna --thinking low --no-session --print ...`.

| Slice | Prerequisite | Ownership / output |
|---|---|---|
| Config/default-data review | Frozen spec | Read-only schema/reference findings |
| Default layout implementation | Config contract fixed | `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json` only |
| Trigger implementation | Intent IDs/event contract fixed | 25 `player_signals_<id>.yaml` files in `PlayerSignals/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/triggers/` |
| Narration review | Spec catalog | Read-only meaning/recipient/outcome findings |
| Adversarial integration review | Complete feature | Read-only cancellation/save-load/duplicate-event findings |

Fan independent layout/trigger work together. Primary owns controller, plugin records, architecture, shared interfaces, integration, and final build/runtime verification. Delegate agents skip builds/tests/lint/formatters mid-flight; run integrated checks afterward.

The task tool's scout interface has no per-call model selector; do not claim a scout job used Luna. Use the explicitly selected Luna runner when model identity matters. Use source material via files and restrict tools appropriately for read-only jobs.

## Session Continuity

This spec and plan capture the implementation-relevant decisions from the original iPrompts conversation. An agent opened in the new repository should read the spec, this plan, and README before implementing. It must not reconstruct old conversation assumptions or modify iPrompts' mod root.

The current conversation can continue working against explicit new-project paths. Starting a separate Orca agent is optional; transfer context through these files plus an explicit task brief rather than assume a fresh session inherits the transcript.
