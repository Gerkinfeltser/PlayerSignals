# Spike: MagelightUI wheel

## Decision and evidence boundaries

**[source / runtime-unverified] GO for the disabled, offline prototype; NO-GO for replacing the production UIExtensions backend yet.** Magelight exposes the required Papyrus/view bridge without a PlayerSignals DLL. PlayerSignals still needs its own native input, lifecycle and narration acceptance run. SQOS's ON HOLD decision is not a Magelight defect finding and does not block this separately authorized offline spike.

**[source] Scope:** branch `spike/magelight-wheel`; no push, game launch, installation, deployment, MO2/profile/symlink/plugin/load-order change, or MagelightUI/SQOS worktree edit. Existing unrelated untracked `docs/backlog/` and `media/default-wheel_0.1.0.jpg` are outside this spike.

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

**[source / runtime-unverified]** `UseMagelight()` returns `False` in the committed controller: UIExtensions remains the selected backend. To opt into a later authorized test, change only that function to `True` and rebuild; this document does not authorize installation or live testing. There is no new JSON schema flag, saved property default or automatic fallback between backends.

**[source / runtime-unverified]** `Browse` owns navigation for both backends. For each wheel, the optional adapter sends a fresh request token, the eight validated/decorated labels and their intent IDs via string `Magelight.Call` arguments: `psWheelBegin`, `psWheelLabel0`…`7`, `psWheelIntent0`…`7`. Unused/null slots stay disabled. `psWheelArm(request)` is sent only after matching focus entry. The page renders slots 1–4 down the left and 5–8 down the right; this is a two-column wheel prototype, not a pixel-identical radial SWF replacement.

**[source / runtime-unverified]** The page returns `request|zeroBasedSlot|intentID`. Submenu/Back/Close choices have an empty intent component. Papyrus validates the exact payload against its retained native slots; the page cannot make a label or arbitrary ID authoritative. The existing `Browse` stack pushes/pops submenus, returns a catalog ID only for an accepted intent, and treats root Back, Close, `-1`, `255`, disabled/out-of-range and stale results as exit-only. The page's Tab/Escape emits `request|-1|`; cancellation at any submenu exits the whole session rather than navigating Back.

**[source / runtime-unverified]** The bridge reuses SQOS's request correlation, per-load event registration, named-view lookup, bounded acquisition and yielding wait pattern. Human decision time is not bounded. It claims only one valid result before releasing its own UI mode; completion does not allow a duplicate rearm. No retries, focus theft, new framework, native extension, JS evaluation of labels, frontend dependency or narration path is introduced. `textContent` renders authored labels literally.

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

**[browser-observed]** Served the repository with `python -m http.server 8792 --bind 127.0.0.1`; opened `tests/test_magelight_wheel.html` and the actual `PlayerSignals/Magelight/PlayerSignals/index.html` in Chromium. The permanent runnable HTML check passed the first authored intent's identity in each shipped wheel, pre-arm/stale/duplicate suppression, null/trailing disabled slots, literal Unicode/HTML-like labels, fresh enabled focus and Tab/Escape cancellation. It did not exercise all 25 intents or Papyrus submenu/Back/Close routing. Actual mouse Greet returned `visual|2|greet`; ArrowDown then Enter returned `keyboard|2|farewell`; real Tab returned `cancel|-1|`. The populated two-column surface was visually inspected, with no document overflow at the observed 1349×673 CSS viewport.

**[source / runtime-unverified] Verification limit:** the browser recorder substitutes only the host callback. It does not execute Papyrus `Browse`, the native `Call` queue, paused waits, release ordering, JContainers, Shift sampling, targeting, SkyrimNet, NPC reactions or native Ultralight rendering. The existing Python suite exercises the real raw Lua validators, not these native paths. Nothing in this spike is PlayerSignals game-runtime acceptance.

## Build, regression and review evidence

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

**[source / runtime-unverified] Reproduction:** start the localhost server above and open `/tests/test_magelight_wheel.html` for the browser check. The optional native route requires the separately installed host and manifest/view plus `UseMagelight() == True` and rebuilt controller; no such deployment or live run was performed or authorized by this spike. Browser tabs and the temporary HTTP service were closed after observation. No throwaway runtime harness or framework assets were added to the payload.
