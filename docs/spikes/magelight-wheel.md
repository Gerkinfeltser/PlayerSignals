# Spike: MagelightUI wheel

## Authored SVG and target regions — 2026-10-29

**[source / built]** The owner's `media/src/RadialUI.svg` now has clockwise `slot-0` through `slot-7`, separate named `target`/`nearby` groups and solid hit paths, plus the center hit path. Geometry, transforms and editor background remain in the source artwork. `build/build.ps1` embeds it into the runtime page between `RADIAL_ART` markers, omitting only the editor background; no external image/resource load or new dependency is required. Upright literal labels and ALL badges overlay the existing geometry without intercepting input.

**[UI wording / browser-observed]** At the owner's request, the targeted region now displays **Target NPC** in its center feedback and accessibility label, with matching help wording. The browser interaction check still passes, and the saved preview was refreshed. Target capture and dispatch behavior are unchanged; no Papyrus rebuild was needed for this HTML-only copy change.

**[source / built]** Gray gesture bodies use captured-NPC targeting; their outer chevrons explicitly choose everyone nearby without a modifier. The center shows the hovered label and generic destination, not a transported NPC name. Navigation/control chevrons are hidden. Left/Right changes position, Up chooses inner, Down chooses nearby where available, and Enter/Space selects; center/Tab/Escape cancels. Shift still overrides a final inner choice. No captured NPC still means nearby; an invalid captured target fails closed unless nearby/Shift was intentionally selected.

**[source]** The population batch is unchanged. Callback cutover is exact `request|slot|intent|target` / `nearby`, `request|slot||navigate`, or `request|-1||cancel`; old three-field and incompatible slot/ID/mode combinations are rejected. Nearby uses private slot+8 and `nearby|` browsing-result encodings, decoded before catalog lookup and only after the original immediate Shift sample. UIExtensions retains its original behavior, and no saved controller fields or second narration path were added. The preceding continuous-focus lifecycle is retained.

**[browser-observed / source-derived model / built]** The permanent browser check passes authored clockwise/non-box hit geometry, all shipped target/nearby/navigation choices, literal Unicode labels, null gaps, keyboard destination selection, cancellation, malformed/stale/duplicate/blurred input and native-mode reset/reopening through a modeled host boundary. Trusted pointer clicks returned `art-preview|2|greet|target` and `actual-nearby|2|greet|nearby`; trusted keyboard returned both modes and cancellation. A long caption initially overflowed its hub by 17 SVG units; bounded remeasurement fixed it, and the permanent check now rejects sector/hub text overflow. At 800×600 the full long caption remained intact with hub height/scroll-height both 560 and no document overflow; the default layout also fits 1280×900. Chromium's corrected checks and actual page reported no errors. A throwaway syntax-lowered execution of the actual Papyrus callback and result-decoding block passed both modes, submenu/Back/Close/cancel, malformed/stale/wrong-view/wrong-ID/empty/navigation-mode/duplicate rejection, prefix stripping and captured/Shift/no-target routing. Its native APIs were modeled, not executed in Skyrim. All 16 Lua/Python tests passed; both Papyrus scripts compiled with zero errors/warnings, and ESP/SEQ generation completed.

**[source review / modeled regression / generated artifact]** Independent UI/build and native reviews completed with no unresolved confirmed findings after corrections. A modeled interleaving reproduced late cancellation overwriting an intent already claimed while a Magelight query yielded; restoring the final empty-result guard made that same source-derived check pass. Native source review independently confirmed the correction. Final controller PEX: 27,252 bytes, SHA-256 `28966460d1dc8c0b65e843718a002822a5fbe8f73b66a9f6a4d0e222d4b0a03b`; both generated scripts have PEX magic `fa57c0de`. The final full build and regenerated-page browser check passed. Temporary model/server/tabs were removed or stopped after verification.

**[rendered artifact / runtime-unverified]** Preview: [`media/radial-ui-nearby.png`](../../media/radial-ui-nearby.png), rendered from the actual generated page with shipped labels and Greet's nearby chevron hovered; it is not a game screenshot. The built payload is exposed through the existing ADT symlink. No game launch/control, MO2 change, commit or push was performed. Native target/nearby dispatch, Shift timing, current-build camera/control restoration and save-load behavior remain acceptance gates; the owner's earlier camera success applies to the preceding revision, not automatically this one.

## Continuous-focus revision — 2026-10-29

**[owner-reported runtime — PlayerSignals/ADT, radial/batch revision]** The owner reports that the radial revision is faster, but the mouse still controls the camera while opening and changing submenus. This is a reported acceptance failure, not an agent-measured latency result.

**[source / built]** Native focus is now acquired before the first reload and retained across the entire iterative `BrowseWheels` session, including submenu/Back transitions. Each page still reloads and validates its request/slots; it does not release/reacquire focus. The outer `Browse` releases once at terminal selection/cancellation and observes release before returning an intent. Failure invalidation retains the old view ID only for that release observation. Generation changes cannot release a replacement session.

**[source]** The page stays invisible until `psWheelArm` after confirmed native ownership and DOM population. Choosing an entry immediately hides/disarms the old document. Native `__uimode` entry/exit messages also reset it without emitting a choice, preventing a force-closed armed page from remaining selectable on reopening. Escape capture is off while blank; use native Escape during loading/navigation. Tab cancellation applies while choices are armed. No saved fields, player-control APIs or cosmetic changes were added.

**[browser-observed / offline model / built]** The permanent HTML check passes, including hidden-before-arm/hidden-after-choice checks. An actual-page browser fixture delivered native mode-exit/entry messages: exit hid/disarmed the page, Enter emitted nothing, re-entry stayed hidden, and fresh Begin/Arm plus pointer selection returned `fresh-after-forced|2|greet`; Chromium reported no errors. A throwaway source-derived controller smoke passed nested/Back traversal with one acquisition/release, reloads under retained ownership, root/submenu cancellation, forced exit without reacquisition, denial, entry/DOM timeout, generation replacement and blocked dispatch when release was unobserved. Its native boundaries were modeled, not executed in Skyrim. The 16-test Lua/Python suite passed. Both Papyrus scripts compiled with zero errors/warnings and ESP/SEQ regeneration succeeded. Current controller PEX: 26,171 bytes, SHA-256 `1564b6e4fe70966c8bf0fe1dafd469efd6242b178d923395542116f056de28bd`.

**[installed boundary / owner-reported runtime — PlayerSignals/ADT]** The rebuilt payload is exposed through the existing ADT symlink. After this fix, the owner reports: “Worked better. No errant camera moves.” This establishes the owner's camera-behavior smoke result, not agent-observed runtime proof or separate confirmation of every cancellation/forced-close/control-restoration case. Renderer timing and zero-frame presentation remain unmeasured. No agent game launch, MO2 change, commit or push was performed. Earlier build hashes and lifecycle observations below belong to their stated revisions.

## Radial and batch revision — 2026-10-29 (before continuous focus)

**[source / built]** The approved revision replaces the two-column prototype with eight fixed SVG sectors, starting at 12 o'clock and proceeding clockwise in JSON order. Null/trailing positions are never compacted. Hover/focus shows the complete literal label in a wrapping caption; sector labels wrap and shrink without truncating authored text. Arrows skip empty positions; Enter/Space requires live sector focus; center, Tab and Escape cancel the whole session. Submenu/Back/Close routing remains in Papyrus `Browse`.

**[source]** Initialization now makes one state-population `Magelight.Call` instead of 17 for a full wheel. Its argument is `<request>|<JSON>`, splitting only the first pipe; JSON contains exactly eight null-or-`[decoratedLabel,intentID]` entries. `config.lua`'s wheel-specific `wheelPayload` encoder reads already-validated retained native slots and escapes JSON strings with Lua standard string functions. No configuration reread, second catalog or dependency is introduced. `psWheelArm` and the exact `request|slot|intent` callback remain unchanged; obsolete per-slot setters are removed.

**[source]** Per-wheel reload, bounded DOM/focus acquisition, confirmed native entry, generation/request/view checks, native slot validation and release observation remain. A malformed batch with a known request arms only cancellation; a missing token releases native Escape capture. No new saved fields, records, retries or narration routes were added. Target capture, immediate post-`Browse` Shift sampling and player-originator dispatch are unchanged.

**[runtime-observed — PlayerSignals/ADT, pre-revision only]** Offline inspection of the owner's completed session found Magelight 1.6.0 / Ultralight 2.0.0 on Skyrim 1.6.1170, 12 matched wheel focus/release cycles with controls restored, seven successfully registered narrations and seven local gesture receipts. Gestures: agreement, goodbye, confusion, greeting Hrasvard, asking Faendal to follow, congratulating Faendal and respect. Sources: `~/Documents/My Games/Skyrim Special Edition/SKSE/Magelight.log:1-10,207-240,572-595`; sibling `SkyrimNet.log:7466-7483,7497-7514,7545-7562,8405-8460,11571-11616,13394-13414,14548-14583`; `D:/Modlists/ADT/overwrite/SKSE/Plugins/AdvancedNotificationLog/current.log:8-15`. These rotating logs describe the earlier two-column checkpoint, not this revision. The owner reports exiting with `qqq`.

**[runtime-observed baseline / INFERENCE]** Across those 12 openings, reload-to-DOM took 19–23 ms, DOM-ready-to-UI-mode-request took 478–481 ms, and release-request-to-UI-mode-off took 16–17 ms. The larger initialization gap motivates batching; individual-call costs and full keypress latency were not measured. No post-revision native timing exists. Retaining the inexpensive reload avoids changing lifecycle assumptions before a measured need.

**[browser-observed / built]** The updated permanent HTML check passed radial hit regions/identity, authored intents, pre-arm/stale/duplicate suppression, holes, literal labels, focus/caption, keyboard selection/navigation, empty-intent navigation, null-only center cancel, malformed-batch cancellation and root/submenu Tab/Escape. Actual pointer Greet returned `mouse-smoke|2|greet`; ArrowDown/Enter returned `keyboard-smoke|1|deny`; real Escape returned `screenshot|-1|`. The surface had no document overflow at 1280×720 and 800×600; a long Unicode/quote/pipe label remained complete in its caption and fitted its sector. Chromium reported no page errors. All 16 Python tests passed, including the real Lua encoder round trip. The full build completed with zero Papyrus errors/warnings and Spriggit 0.40.0 ESP/SEQ generation. Browser/generated-artifact evidence does not prove the native bridge, Ultralight layout, Shift timing or speed improvement.

**[source review]** Independent native/data and radial/input reviews identified two reproduced input defects: Enter could submit a previously focused but now unhighlighted sector, and malformed data disabled ordinary cancellation. Both were corrected with live-focus selection and correlated cancel-only state, with permanent browser regressions. The original unbounded completed-token set was reduced to a last-completed-token guard; native request correlation remains authoritative.

**[source review / generated artifacts]** Both independent reviewers rechecked the fixes and reported no unresolved source-proven findings. Actual browser input confirmed blurred Enter emits nothing and malformed-batch Escape returns cancellation. Generated controller PEX is 25,306 bytes, SHA-256 `3abada9e5675aefba4e33d073247b091aeb60cd6d5fc803317a06438e3a3b0da`; both scripts have PEX magic `fa57c0de`. The 451-byte ESL ESP retains SHA-256 `e43f0e7cf612d9b9140ed14ff90df2b2a95ac8da6a0c487ec8530a8315596c35`; SEQ remains quest `0x00000800`. Temporary browser tabs and the HTTP service were closed after verification.

**[installed boundary / runtime-unverified]** The rebuilt payload is exposed through the owner's ADT symlink. No game launch, MO2 change, commit or push was performed for this revision. Restart Skyrim through the usual ADT SKSE entry before testing, because the JContainers Lua module is cached within the process. Repeat opening/submenu/Back/cancel and targeted/group/Shift checks; compare the same host-log intervals before claiming a native performance gain.

## Earlier enabled two-column checkpoint — 2026-10-29

**[source / built]** At the owner's request, `UseMagelight()` now returns `True`. Both Papyrus scripts were rebuilt with 0 errors / 0 warnings; ESP/SEQ generation completed. The owner reports the payload directory is symlinked into ADT, so rebuilding it updates files exposed to that installation; no separate copy/deploy command is necessary. Earlier no-deployment wording below describes the absence of a separate deployment operation, not isolation from that symlink.

**[owner-reported runtime — PlayerSignals/ADT, pre-radial]** The owner reported “Works” and “a bit slow … compared to the wheel.” This establishes the initial reported smoke, not the detailed targeting, Shift, callback, lifecycle or control-restoration matrix. The later offline log inspection above adds scoped runtime evidence for that same pre-radial session.

**[historical plan — now implemented above]** Radial presentation and performance work was deferred until after the enabled checkpoint's commit/push (`f1e72a0`), then separately approved. The installed SeverActions 4.6 reference was inspected read-only at `D:/Modlists/ADT/mods/SeverActions-4.6.0-FOMOD/Magelight/SeverActions/views/SeverActionsWheel/index.html`. Its generic annular-sector/polar-layout pattern informed the original PlayerSignals renderer; no reference assets or dispatch code were copied.

## Decision and evidence boundaries

**[source / runtime-unverified] GO for the experimental prototype; NO-GO for replacing the production UIExtensions backend yet.** Magelight exposes the required Papyrus/view bridge without a PlayerSignals DLL. The owner's ADT smoke above does not close the native input, lifecycle and narration acceptance matrix. SQOS's ON HOLD decision is not a Magelight defect finding.

**[source] Initial offline scope:** the first checkpoint (`65db3b2`) used branch `spike/magelight-wheel` with no push, agent game launch, separate deployment operation, MO2/profile/symlink/plugin/load-order change, or MagelightUI/SQOS worktree edit. The owner subsequently authorized enabling/rebuilding Magelight and committing/pushing that state. Existing unrelated untracked `docs/backlog/` and `media/default-wheel_0.1.0.jpg` remain outside this spike.

Evidence labels apply to every claim in their paragraph/table row:

- **source**: inspected source/docs or implemented source, not proof of native operation.
- **built**: this session's compiler/generated artifacts only, not installation or gameplay.
- **browser-observed**: Chromium running the actual HTML; not Ultralight, SKSE or Papyrus.
- **runtime-observed — SQOS only**: immutable historical SQOS receipts, never PlayerSignals acceptance.
- **runtime-unverified**: PlayerSignals game behavior or a remaining acceptance requirement.
- **[INFERENCE]**: recommendation, estimate or consequence not directly observed.

**[source] Research locators:** Magelight paths below are relative to `D:/git/MagelightUI`, source revision `ca4338dcc45fecbaeab79e218f703bd2d9417f6d`. SQOS paths refer to `git show` snapshots in `D:/gerkgit/SQOS-SkyrimNet-Patcher`; neither that branch nor its worktree was checked out or edited. PlayerSignals baseline touchpoints refer to the pre-spike controller, using the original line numbers recorded during discovery. Current implementation is identified by symbol below.

## Magelight capabilities mapped to this wheel

| Evidence | Capability and exact source locator | Application |
|---|---|---|
| source | `docs/MANIFEST.md:3-23,55-77,84-99`; `examples/Magelight.Badge/manifest.json:23-43` | Ship `Data/Magelight/PlayerSignals/manifest.json` and `index.html`; named fullscreen hidden popup. No host hotkey: Papyrus must capture the crosshair before opening. |
| source | `papyrus/Magelight.psc:32-53`; `docs/PAPYRUS.md:10-15,56-67,75-95` | Register/adopt script-owned slug, find/create named view, show/request UI mode, release owned focus. Resolve IDs again after loads; they are not saved authority. |
| source | `papyrus/Magelight.psc:47-53`; `api/MagelightUI_API.h:150-152`; `docs/PAPYRUS.md:170-180` | Host owns cursor/input and optional paused UI. Entry submission is not observed entry; await `UIModeEntered`. Use `Utility.WaitMenuMode`, not `Utility.Wait`, while paused. World-freeze semantics still require a PlayerSignals live check. |
| source | `papyrus/Magelight.psc:13-23,56-62,86-89`; `src/MagelightPapyrus.cpp:51-89,360-364,450-455` | `Call(view, function, argument)` sends strings to JS. Registered `window.psWheelChoice(payload)` returns a game-thread SKSE ModEvent with payload and view ID. These are UI callbacks only, not an alternate narration route. |
| source | `README.md:75-93`; `docs/PAPYRUS.md:119-152,155-180` | Page cannot fetch the existing `Data/SKSE/Plugins/PlayerSignals/layout.json` outside its sandbox. Feed already validated data from Papyrus instead; do not copy/reread configuration or enable networking. Keep isolated storage and no DLL adoption. |
| source | `src/Magelight.cpp:6600-6658`; `CLAUDE.md:119-133` | Keyboard events are suppressed while focused, but buffered events update both held-key arrays (`curState`/`prevState`, lines 6635-6650). Suppression alone is **not** evidence that held Shift is broken. Native `Input.IsKeyPressed(42/54)` timing and opening-key rearm remain runtime-unverified. |
| source | `docs/PAPYRUS.md:98-117,170-180`; `papyrus/Magelight.psc:13-19` | Filter lifecycle events by view/slug, re-register on load, abort a primed pending request on reload/failure/destruction/render death/focus loss. Never reuse a prior result or rearm the same completed request. |

## PlayerSignals touchpoints

**[source] Original controller:** `PlayerSignals/Source/Scripts/PlayerSignals_Controller.psc` before this branch's edits:

| Original lines | Existing responsibility | Spike boundary |
|---|---|---|
| 12-37,39-100 | Generation invalidation, maintenance, dependency/config/key setup | Add optional host setup/invalidation; retain the alias-driven load entry. |
| 183-210 | Gameplay/re-entry gates, crosshair capture, retained session/history | Keep capture before either backend opens. |
| 210-235 | `Browse` return, immediate Shift 42/54, catalog lookup, submit | Keep the Shift sampling point and one final submission path. |
| 241-275 | Target validity, authored narration, `DirectNarration`, return-0 feedback | Unchanged dispatch semantics. Actual source/spec use player as originator: `DirectNarration(text, player, capturedNPC/None)`; see `docs/specs/player-signals.md:64-84`. |
| 283-345 | Eight slots, `OpenMenu`, iterative submenu/Back history, cancellation | Switch only the presentation call; preserve native slot validation and navigation in `Browse`. |

**[source] Unchanged configuration/startup contracts:** Lua reads and validates both authored JSON files, builds canonical internal wheel keys and decorates navigation labels once (`PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua:214-274`). The alias calls `ScheduleMaintenance` on initialization/load (`PlayerSignals/Source/Scripts/PlayerSignals_PlayerAlias.psc:3-18`). No frontend catalog, second validator, JSON write-back, alias change or new plugin record is needed.

## Prototype architecture

**[source / built]** `UseMagelight()` now returns `True` in the controller and rebuilt PEX. To return to UIExtensions, change that function to `False` and rebuild with Skyrim closed. The original `65db3b2` checkpoint selected `False`; its offline evidence below remains historical. There is no new JSON schema flag, saved property default or automatic fallback between backends.

**[source / native-runtime-unverified]** `Browse` owns navigation for both backends. Each Magelight wheel receives the fresh token and eight validated/decorated label/intent pairs in one `psWheelBegin` payload, then `psWheelArm(request)` only after matching focus entry. Null/trailing slots remain disabled at their original angular positions. JSON order runs clockwise from the top in Magelight; UIExtensions retains its original left/right order. The earlier per-slot, two-column prototype is superseded.

**[source / runtime-unverified]** The page returns the exact four-field intent/navigation/cancellation payload documented above. Papyrus validates it against retained native slots; labels and arbitrary IDs cannot authorize dispatch. The existing browsing stack pushes/pops submenus and treats root Back, Close, cancellation, `255`, disabled/out-of-range and stale results as exit-only. A final nearby intent is temporarily tagged in the private browsing result; that tag is stripped after Shift sampling, before catalog lookup. Cancellation at any submenu exits the whole session rather than navigating Back.

**[source / runtime-unverified]** The bridge reuses SQOS's request correlation, per-load event registration, named-view lookup, bounded acquisition and yielding wait pattern. Human decision time is not bounded. It claims one result per page, retains native ownership through navigation, and releases only when the browsing session terminates; completion does not allow a duplicate rearm. No retries, focus theft, new framework, native extension, JS evaluation of labels, frontend dependency or narration path is introduced. `textContent` renders authored labels literally.

**[source / runtime-unverified]** Crosshair capture remains outside the UI adapter. After the final accepted `Browse` return, the original Shift 42/54 sample still precedes feedback/catalog lookup. Target liveness/enabled/3D checks, generation fences, player-originator arguments, one `DirectNarration` and return-0 local notification remain in the existing path. A UI callback is not evidence of SkyrimNet processing, NPC speech or compliance.

## Prior art: SQOS spike

**[source] Why it stopped:** `ed2ba52:docs/IMPLEMENTATION_STATUS.md:221` and `ed2ba52:openspec/changes/replace-sqos-messagebox-with-magelight/tasks.md:1` explicitly put Magelight **ON HOLD on 2026-10-15 because the owner found an alternative message-box mod for Skyrim 1.7.104**. Its name/version/link and `SkyMessage.Show` compatibility were not established. This was an owner alternative/priority decision, **not a finding that Magelight was unusable**. The separate production failure was the existing SkyMessage call (`tasks.md:15`), not a Magelight test. This spike does not resume SQOS work.

**[runtime-observed — SQOS only]** Commit `267d2da` preserves the isolated live popup evidence, also present in `ed2ba52`:

- `docs/evidence/magelight-popup-20261012T193906Z/result.json:2-16,17-56`: owner-reported STD 1.7.104, host **0.31.2**, request `probe-508.949036-427082968`, real Tab/Enter, visible Accept, popup closure and later native TweenMenu open/close.
- `docs/evidence/magelight-popup-20261012T193906Z/Papyrus-probe-window.log:31-37`: same request enters UI, callback/waiter/wrapper return Accept with `menuMode=TRUE`, then `released=TRUE` and `probe_finished=Accept`.
- `docs/evidence/magelight-popup-20261012T193906Z/mcp-receipt.json:2-18,20-27`: probe invocation succeeded and player identity was read. Invocation alone does not prove display or choice.
- `result.json:57-73`: movement/camera/controller, independent frozen-world physics, other choices, Dialogue Menu overlap, forced closure, pending save/load, exact profile/VFS and installed artifact/build identity remain unverified. No save/load, quest action or production migration was performed in that run.

**[browser-observed — historical SQOS only]** `ed2ba52:docs/evidence/magelight-layout-20261012T212357Z/result.json:2-24,25-160,175-189` records the compact-layout fix, failing-before geometry, passing behavior/short-and-long layout at 1920×1080, 1280×720 and 800×600, and explicitly excludes native compositing/Papyrus/pause/controller acceptance. This is not a native-layout pass.

**[source] Patterns actually reused:** `ed2ba52:SQOSPatcher/Source/Scripts/SQOSQuestRegistryScript.psc:1689-1817` supplies token/busy handling, event setup, 10-second DOM and 5-second focus acquisition, `WaitMenuMode`, result-before-release and an unbounded player-decision wait. Lines `1819-1905` supply load invalidation, named-view cleanup, reload abort and callback/view correlation. `SQOSPatcher/Magelight/SQOSPatcher/offer.html:31-68,83-95` supplies explicit choices, request rearm and literal text. PlayerSignals adapts these patterns rather than copying SQOS quest effects or its three-choice schema.

**[source / runtime-unverified] Applicability:** SQOS's alternative-messagebox rationale does not replace PlayerSignals's configurable eight-slot wheel. Shared unresolved native gates **do** apply: host entry/release, callback ordering, forced exit, save/load, composition, actual input/control restoration and artifact identity. PlayerSignals additionally needs fixed-target and Shift tests; SQOS did not test either. SQOS's Dialogue Menu and quest-offer reconciliation requirements are not silently imported into a wheel whose gameplay gates refuse opening over menus. Reviewed SQOS intended behavior is in `ed2ba52:openspec/changes/replace-sqos-messagebox-with-magelight/design.md:9-21,44-84`, `specs/sqos-offer-ui/spec.md:37-65` and `tasks.md:7,17-25,70-72`; it is not evidence of a completed production migration.

## Dependencies, records and save impact

**[source]** Require Magelight as a separate installation, not bundled assets: host `Magelight.dll`, its complete namespaced Ultralight/GPU runtime/resources, focus SWF and `Magelight.pex` come from the host distribution (`docs/DISTRIBUTION.md:3-18,29-35,88-106`). This repository ships only its own view/manifest and controller artifacts. There is no PlayerSignals-specific DLL or Node/npm runtime requirement. Build imports the real `D:/git/MagelightUI/papyrus` declarations via `build/build.ps1`'s `MagelightSources` parameter; it does not copy the framework script.

**[source / runtime-unverified]** The manifest and controller use **0.31.2 as this spike's candidate floor**, matching the one SQOS-observed host version; this is not an experimentally discovered minimum or proof that every later build works. Magelight's requirements are SKSE64 plus matching Address Library for SE/AE (SKSE64 2.3.0+ for 1.7.x), or SKSEVR plus VR Address Library, and VC++ 2015–2022 x64 (`README.md:31-41`). PlayerSignals still requires JContainers API 4/feature 2 with Lua and SkyrimNet. UIExtensions remains required for the default backend; it is not removed from this spike's source/build surface.

**[source / runtime-unverified] Optional-host qualification:** `UseMagelight() == False` selects the UIExtensions source branch; it does not prove that Skyrim's VM loads the compiled controller when `Magelight.pex` or its native host is absent. Fresh-process UIExtensions startup/open/submission without Magelight is an explicit remaining live gate. Neither guaranteed optional-install safety nor a hard runtime requirement for the disabled backend follows from compilation alone.

**[source / runtime-unverified]** No authored ESL flag, quest/alias/FormID/attachment, SEQ identity, script name or property-default change. **New private `_ml*` controller fields are saved Papyrus state.** Earlier README/spec statements about adding no saved fields describe the previous JSON/catalog cutover, not this experimental adapter. Maintenance must invalidate them and suspended stacks. No existing-save install/update, rollback or uninstall safety is established here; use disposable copied saves for future tests and preserve pre-install ESS/SKSE backups. Host objects are session state (`docs/PAPYRUS.md:10-15`), while browser storage is install-wide and not rolled back by saves (`docs/MANIFEST.md:101-115`); the view stores no decisions there.

## Remaining gates and effort

**[runtime-unverified] Before production replacement:**

1. Identify the exact loaded host/runtime, effective assets and PEX/ESP winners in an explicitly approved disposable fixture; observe this actual wheel, transparency, scale, labels and focus.
2. Exercise intent/submenu/Back/root-Back/Close, all disabled/null/out-of-range/cancel cases, reopening without stale focus, repeated key presses and missing/busy/render-dead host behavior. Verify forced exit, pending reload and pending save/load cannot dispatch or strand focus.
3. Hold left and right Shift separately through final acceptance, including press/release while the view is focused. Verify no-target and both override paths omit the captured name; invalid captured targets fail closed without Shift. Verify crosshair movement never retargets the session and the opening key rearms after closure.
4. Observe exactly one player-originator direct narration and return-0 feedback for accepted selections; verify cancellation/stale/invalid/API-failure paths remain silent. NPC reply/compliance is a separate observation.
5. Verify keyboard/mouse and required controller/VR support on actual hardware before advertising parity; verify movement/camera restoration and independently observe pause behavior. This prototype does not implement a controller-forwarding layer or claim controller/VR acceptance.
6. Run the default UIExtensions backend in a fresh process without the Magelight script/DLL, establishing whether the VM can resolve this experimental controller's unexecuted global references. Do not ship the disabled adapter as a proven dependency-free update before this check.

**[INFERENCE] Estimate:** the offline investigation/prototype is bounded work; production readiness likely needs **1–2 engineering days** for integration hardening/presentation, plus **1–2 separately authorized live-test sessions** if the existing bridge works. Host defects, required controller forwarding, unavailable hardware or save/load failures can expand that substantially. These are planning estimates, not observed durations or an approval for live work. A full in-view navigation rewrite, new native DLL and frontend framework are unnecessary until an observed requirement defeats this boundary.

## Offline browser verification

**[browser-observed — historical two-column revision]** The initial localhost check exercised first-intent identity in each shipped wheel, pre-arm/stale/duplicate suppression, null/trailing slots, literal Unicode/HTML-like labels, focus and Tab/Escape. Mouse Greet returned `visual|2|greet`; ArrowDown/Enter returned `keyboard|2|farewell`; Tab returned `cancel|-1|`. The current radial revision's separate checks are recorded above. Neither browser check executes Papyrus submenu/Back/Close routing or establishes native acceptance.

**[source / runtime-unverified] Verification limit:** browser recorders substitute only the host callback. They do not execute Papyrus `Browse`, the native `Call` queue, paused waits, release ordering, JContainers, Shift sampling, targeting, SkyrimNet, NPC reactions or native Ultralight rendering. Python checks exercise the real Lua validators/encoder, not the native bridge. Browser and Lua checks do not establish game-runtime acceptance; pre-revision game logs are labeled separately above.

## Initial two-column build, regression and review evidence — historical

**[source]** Pre-spike PlayerSignals baseline: `5681bceae48c9fba3029840841b761fb67222c8d`. The touchpoint table above uses that revision's controller lines, not the expanded prototype's line numbers. Current adapter symbols are `UseMagelight`, `InvalidateMagelight`, `PrimeMagelight`, `BrowseMagelight` and `OnMagelight*` in the same controller; `Browse`, `OnKeyDown` and `Submit` retain navigation/dispatch ownership.

**[built]** Ran `pwsh -NoProfile -Command "& ./build/build.ps1"` from the repository root. The final run exited **0**; both controller and alias compiled against real declarations with **0 errors / 0 warnings**, and Spriggit **0.40.0** regenerated ESP/SEQ. Final command-output tail:

```text
[09:46:46.109 INF] [09:46:46 INF] Finished deserializing
[09:46:46.128 INF] Finished deserializing with D:\gerkgit\SkyrimNet_PlayerSignals\PlayerSignals_spriggit to temp output PlayerSignals.esp => C:\Users\vector\AppData\Local\Temp\Spriggit\Translations\qdtzswpt.bm4\PlayerSignals.esp with SpriggitModKeyMeta { Source = Spriggit.Yaml.Skyrim.0.40.0, Release = SkyrimSE, ModKey = PlayerSignals.esp }
[09:46:46.129 INF] Creating output directory D:\gerkgit\SkyrimNet_PlayerSignals\PlayerSignals
[09:46:46.129 INF] Moving file to final output D:\gerkgit\SkyrimNet_PlayerSignals\PlayerSignals\PlayerSignals.esp
[09:46:46.138 INF] Moved file to final output D:\gerkgit\SkyrimNet_PlayerSignals\PlayerSignals\PlayerSignals.esp
Built PlayerSignals PEX/ESP/SEQ; startup quest 00000800. No deployment or MO2 changes.
```

**[built]** Binary checks on the final generated files found PEX magic `fa57c0de` in both scripts (controller **25,873 bytes**, alias **975 bytes**); both generated PEX differ from baseline. The **451-byte ESP is byte-identical to baseline**, has TES4 magic and ESL flag `0x200`; the **4-byte SEQ is byte-identical to baseline** and decodes to startup quest `0x00000800`. No authored records changed. These are generated-artifact checks, not proof of packaging, installation, VM binding or gameplay. Alias source is unchanged; the build regenerates its PEX.

**[source validation]** Ran `python -m unittest discover -s tests -v`; exit **0**, all **15** existing raw-Lua tests passed. Output tail:

```text
test_unused_catalog_records_are_still_validated (test_config.ConfigValidation.test_unused_catalog_records_are_still_validated) ... ok

----------------------------------------------------------------------
Ran 15 tests in 0.067s

OK
```

**[source] Review outcome:** a `reviewer` inspected the design, evidence claims and final stable adapter. Confirmed findings were fixed: begin-before-label ordering, menu-mode waits, DOM reload/reacquisition, detailed/plain failure routing, stale-entry guards, result-claim guards after yielding calls, lifecycle/polling preservation of the first terminal result, delayed prior-wheel exit rejection until current entry, held-key resampling generation fence, bounded release observation and a compiler-detected local variable shadow. The final review reports **no unresolved source-proven findings**. An earlier compile failed on the shadowed `view` variable; it was corrected before the successful final build. Review/compilation do not close any native acceptance gate.

**[source / runtime-unverified] Reproduction:** start the localhost server above and open `/tests/test_magelight_wheel.html` for the browser check. The native route requires the separately installed host and manifest/view plus the enabled rebuilt controller. The original offline investigation did not run the game; the later owner-reported ADT smoke is recorded separately above. Browser tabs and the temporary HTTP service were closed after observation. No throwaway runtime harness or framework assets were added to the payload.
