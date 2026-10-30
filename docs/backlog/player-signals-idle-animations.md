# Handoff: JSON-selected PlayerSignals idles

## Task Overview

- User wants certain wheel entries to play an idle animation, selected in JSON by the **Idle record's EditorID**, with a null/type check before attempting playback and both an in-game notification and log entry if lookup fails.
- Discussion assumed the **player** performs the idle, alongside existing gesture narration; the user did not explicitly decide whether a captured NPC should animate instead. This is a backlog/design handoff, **not an implemented feature**.
- Acceptance target if implemented: an entry with a valid configured Idle can play it on selection; an unresolved/non-Idle EditorID never reaches `PlayIdle`, and the failure names the EditorID in a local notification and `[PlayerSignals]` trace. Entries without an idle retain current narration behavior. In-game visibility remains separately testable.

## Completed Work

- No feature code, JSON, plugin, or dependency changes were made in this conversation. Inspected the current controller, Lua loader, API declarations, specification, plan, and iActions animation examples.
- This document is the only file created for the handoff: `docs/backlog/player-signals-idle-animations.md`.
- At inspection, branch `main` tracked `origin/main`; `git diff --stat` showed no tracked changes. An unrelated user-owned untracked `media/default-wheel_0.1.0.jpg` exists; leave it alone. Latest commit was `5681bce` (2026-10-02, licensing/release docs); preceding `d855bf7` modified the controller, compiled PEX, spec, plan, and guides.

## Technical Decisions

- Use a JSON field on an **intent slot**, tentatively `idleEditorId`, not an unvalidated animation graph event name. `Actor.PlayIdle(Idle)` takes a typed Idle form and returns `Bool`; `Debug.SendAnimationEvent(ObjectReference, String)` sends an unchecked graph event and returns nothing. The user preferred the PlayIdle route.
- The installed `powerofthree Papyrus Extender` source declares `PO3_SKSEFunctions.GetFormFromEditorID(string) -> Form`. Cast its result `as Idle`; a missing or wrong-type form yields `None`. Vanilla `Game.GetFormFromFile` uses a numeric FormID, not EditorID. This adds a **new PlayerSignals runtime/build dependency** if adopted; the installed mod has `Scripts/PO3_SKSEFunctions.pex`, source, and `SKSE/Plugins/po3_PapyrusExtender.dll`. Do not copy dependency files into PlayerSignals.
- Reuse the existing `Report(details)` method for lookup failure: it emits `[PlayerSignals]` trace and `PlayerSignals:` notification. Report once per selected invalid idle; never call `PlayIdle(None)`.
- Assistant proposed suppressing narration too on invalid idle, to avoid narrating an animation that could not start. **This fail-closed pairing was proposed, not explicitly confirmed by the user**; resolve before implementation. Similarly, whether to report `PlayIdle` returning `False`, when to play relative to `DirectNarration`, and whether to require an Idle for an action-only entry are not user-decided.
- Earlier question explored optional iActions `drink_alcohol` entries with preset JSON arguments. No feature was approved or coded for that idea; keep it separate. The installed SkyrimNet API does expose `ExecuteAction(name, actor, argsJson)`, which bypasses eligibility and cooldown, but action calling is **not** the scope of this animation handoff.

## Current Status

- Done: feasibility established from installed Papyrus declarations and source; handoff saved.
- Pending: decide the remaining sequencing/failure policy, update the authoritative spec before changing its explicit no-animation contract, implement JSON validation and dispatch, document the new dependency, compile/test, and verify in game.
- Blocked: no current verified EditorID for an appropriate player gesture or evidence of live `PlayIdle` behavior. No MO2/profile/load-order changes are authorized.
- Risk: EditorID lookup may return a wrong type or an ambiguous/wrong form; a valid `Idle` form and `PlayIdle` return value do **not** prove a visible animation under all player states (first-person, furniture, movement, combat). Do not assert runtime success from a declaration or compile.

## Attempts and Failures

- No implementation attempt or test failure in this conversation. A previous integrated build failure documented in `docs/plans/player-signals.md` was due to a locked unchanged ESP, not this feature.
- Search of installed base/SKSE/JContainers Papyrus declarations did not find an EditorID lookup. The installed `powerofthree Papyrus Extender/Source/scripts/PO3_SKSEFunctions.psc:481` did; `D:/git/SkyrimNet-GamePlugin/headers/PO3_SKSEFunctions.psc:189` also declares it. These are declarations, not observed live native binding.

## Implementation Details

- `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json` has ordered wheel slots with exactly one of `intent`, `submenu`, or `control`; consider optional `idleEditorId` only alongside `intent`, with a nonempty string. Keep the 25-ID `intents.json` registry and narration phrases unchanged unless separately requested. Decide whether idle is an auxiliary field or a distinct entry type before coding; the discussion points to auxiliary intent metadata.
- `PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua:159-185` enforces allowed slot keys and exactly one primary action; `:259-273` builds native JMap entries by copying validated slot fields. Extend the slot schema without weakening strict validation, graph checks, null slots, or menu markers. The Lua loader cannot establish that an EditorID resolves to an Idle in the running game.
- `PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc:183-275`: `OnKeyDown` captures the crosshair NPC and a retained config; `Browse` currently returns **only a String intent ID** (`:283-345`), losing which slot was selected. Carry slot-specific idle metadata through the accepted selection, read it while the session lease is alive, and preserve generation/re-entry guards before any external call. `Submit` validates captured NPC availability, then makes exactly one `SkyrimNetApi.DirectNarration` call; its success notification appears only for result `0`. Preserve Shift sampling immediately after accepted Browse return, target fail-closed behavior, and silent navigation/cancellation/stale stacks. `Report` is at `:347-350`.
- Installed declaration paths: `D:/Modlists/ADT/Game Root/Data/Source/Scripts/Actor.psc:470-474` (`PlayIdle` and `PlayIdleWithTarget`), `D:/Modlists/ADT/Game Root/Data/Source/Scripts/Debug.psc:50-52` (graph event), and `D:/Modlists/ADT/mods/powerofthree Papyrus Extender/Source/scripts/PO3_SKSEFunctions.psc:481` (EditorID lookup). `D:/gerkgit/SkyrimNet_iActions_dev/iActions/Source/Scripts/iActions_DrunkAnimation.psc:14-17,105-114` wires Idle properties and calls `PlayIdle`; that is precedent, not a PlayerSignals integration.
- `build/build.ps1:13-20` imports feature, SKSE, JContainers, SkyrimNet, vanilla, UIExtensions, and fallback headers. If compiling against the installed PO3 source, add the actual source directory to ordered imports without shadowing vanilla declarations. No new saved controller fields/quest/FormIDs should be introduced just to carry a selection; preserve existing save-load compatibility where feasible.

## Testing Requirements

- Checks performed here: read source/API declarations; `git status --short --branch` showed `main...origin/main` plus only the untracked image, `git diff --stat` was empty, and `git log -3 --name-status` identified recent commits. **No compiler, unittest, config smoke, game, or MO2 run occurred in this conversation.** Historical build/runtime claims in plan/README are not evidence for this change.
- Required on implementation: exercise JSON validation for absent, valid, empty, wrong-type, and misplaced `idleEditorId`; ensure normal intent, submenu/Back, cancel, Shift/no-target, invalid captured target, and save-load/session invalidation still behave as specified. Verify unresolved and wrong-type EditorIDs produce one trace and one notification, zero `PlayIdle` calls, and the approved narration behavior. Check `PlayIdle(False)` and DirectNarration-return branches according to the chosen sequencing policy.
- Compile both scripts against real declarations and run `python -m unittest discover -s tests -v` and `powershell -NoProfile -ExecutionPolicy Bypass -File build/build.ps1` from repository root. Inspect generated PEX/ESP/SEQ and added dependency guidance. Prior integrated build hit an ESP lock; never report it as successful without a new successful run.
- Run an actual wheel selection with a known-good Idle in a separately approved Skyrim/MO2 runtime and inspect visible player animation, notifications, Papyrus trace, and narration separately. Repository tests cannot establish visible playback or installed native binding. Before any game control, read the shared iVault Skyrim execution contract named in repository guidance; no profile/symlink/plugin changes without explicit approval.

## Next Steps

1. Confirm whether invalid idle suppresses narration, whether `PlayIdle(False)` gets the same notification/log, and whether the idle must play before or after `DirectNarration`. The user explicitly requested notification/log on null; do not silently infer the rest.
2. Update `docs/specs/player-signals.md` to replace the existing explicit no-animation restriction with the approved optional-idle contract and acceptance cases; keep plans/current evidence separate.
3. Extend layout validation/native metadata and controller selection/lookup/guard/dispatch. Add powerofthree Papyrus Extender to build imports and applicable dependency docs, without bundling its assets or altering existing quest/alias/FormIDs.
4. Run targeted JSON regressions, compile/build, and perform an authorized in-game smoke with a verified Idle EditorID. Report code, generated artifact, installed runtime, and observed playback evidence separately.

## Files Created/Modified

- Created: `docs/backlog/player-signals-idle-animations.md` — durable design/status record.
- No other files modified in this conversation. Inspected: `README.md`, `docs/plans/player-signals.md`, `docs/specs/player-signals.md`, `build/build.ps1`, `PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc`, `PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua`, `PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json`, `tests/` listing, installed Papyrus declarations above, and iActions example scripts/YAML. Untracked `media/default-wheel_0.1.0.jpg` predates this handoff and was untouched.

## Context Notes

- Repository/current working directory: `D:/gerkgit/SkyrimNet_PlayerSignals`; actual distributable mod is only `PlayerSignals/`. Git branch at inspection: `main`, tracking `origin/main`. Documentation destination requested by the user: `docs/backlog/` (created for this handoff), not iVault/default `_tmp`.
- `docs/specs/player-signals.md:16,27,254,320,336-338` explicitly disallows animation in the current approved contract; the new request supersedes that prohibition only once documented and implemented. Earlier guidance also forbids forced NPC actions, second narration paths, and UI/control changes; do not fold the drink-action idea into this idle task without its own agreement.
- No credential, private key, or token is required for continuation. No live agent/worktree ownership transfer was made.
