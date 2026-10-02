# Implementation Plan: PlayerSignals (for SkyrimNet)

Status: Limited-test GitHub release preparation. Scoped loader/submission smokes, both Papyrus compiles, and 15 configuration tests passed. Current archived runtime evidence verifies player-originator targeted/group submissions and NPC responses. A limited removal test and short post-ReSaver load are documented; exhaustive runtime acceptance and long-term removal safety remain unverified. The earlier integrated build failed at a locked, unchanged ESP, separately verified by generation.
Updated: 2026-10-02

Authoritative behavior, schema, targeting, narration, and acceptance contracts: [PlayerSignals specification](../specs/player-signals.md). Update that spec first if an approved contract changes.

## Work location and boundaries

- Repository: `D:/gerkgit/SkyrimNet_PlayerSignals`.
- Actual mod root: `PlayerSignals/`; only this child folder is symlinked into MO2.
- Authored plugin records: `PlayerSignals_spriggit/`, outside the mod root.
- Do not change MO2, symlinks, plugin activation, or load order. Commit/push only when explicitly requested by the user.
- Do not use the former mod-event/YAML external-package installation, editing, or activation procedures as current instructions.

## Active phase — Captured targeting and direct narration

This phase replaces the former `SendModEvent`/external-YAML-trigger path. The controller and Lua loader must follow the frozen specification, including the editable JSON registry and target-feedback maps; the primary owns integration, build, and runtime verification.

### Implementation sequence

1. **Native API readiness:** require both loaded `SkyrimNet.esp` and a nonempty `SkyrimNetApi.GetBuildVersion()` before enabling the feature. Use installed SkyrimNet script imports in the build, ordered after JContainers and before vanilla imports.
2. **Capture and selection:** capture the current crosshair NPC before opening the wheel. Immediately after `Browse` returns a final accepted intent, sample left/right Shift scan codes 42/54 before feedback/catalog lookups. Either held key overrides targeting to group mode; no captured NPC is also group mode.
3. **Submission:** targeted mode checks the captured actor is alive, enabled, and 3D-loaded at submission. Without a Shift override, any failed check ends silently, never redirecting to group or another NPC. Targeted call: `SkyrimNetApi.DirectNarration(text, player, capturedNPC)`. Group call: `SkyrimNetApi.DirectNarration(text, player, None)`. The player is always the originator. Targeted text explicitly addresses the captured NPC; group text explicitly addresses everyone nearby. SkyrimNet selects the responder in both modes; the captured NPC is not guaranteed to respond, and no response or compliance is guaranteed.
4. **Catalog and feedback:** `PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json` is the editable ID registry and phrase source. The shipped catalog has 25 default IDs, but valid new lowercase IDs are defined and validated dynamically in JSON. Each record has exactly the nonempty UTF-8 strings `narration`, `notification`, and `targetedNotification`; the sole literal `{target}` occurs exactly once in the targeted template and nowhere in the other fields. All phrases omit player prefix/final period. The Lua loader reads both JSON files, validates every catalog record before layout references, and builds native `narrations`, group `notifications`, and targeted-notification prefix/suffix maps. Changing or adding an ID/phrase is JSON-only; reference new IDs from `layout.json`, then load a save. No Lua/Papyrus edit or recompilation is needed.
5. **Cutover and docs:** keep obsolete YAML trigger/action content and its installation/activation guidance removed. The separately requested prompt-only WebUI helper may use a new manifest, but cannot restore the old dispatch bundle. Keep useful old-runtime facts only in sections explicitly labeled historical/pre-cutover.

### Active acceptance and evidence gate

Scoped current-source observations:

- [x] Lua+JSON loader smoke: the new native maps validated at the boundary; a custom ID loaded without Lua edits; empty target-template prefix/suffix and Unicode prefix/suffix worked, including a recipient name containing literal `{target}` without recursive substitution; missing/empty catalogs failed closed with the path and no published config/fallback. All 25 shipped narration and untargeted-notification phrases exactly matched the captured previous defaults. A direct file-load smoke rejected a narration ending in a period, `{target}` in a group notification, and a targeted template ending in a period before trailing whitespace; errors named `intents.json` and the offending field.
- [x] Source-derived `OnKeyDown`/`Submit` smoke: captured Ted remained the recipient after the crosshair moved to Sven; targeted feedback was `Bill greets Ted`; either Shift key, no captured NPC, and Shift override feedback were `Bill greets` without Ted. The submenu sample produced `Bill asks Ted to follow`. Death, disablement, or unload during name lookup prevented API/feedback; API return `1` produced no feedback; generation change during the API call suppressed feedback.
- [x] Both Papyrus scripts compiled with 0 errors and 0 warnings.

The integrated full-build attempt did not succeed: after the Papyrus compiles, Spriggit failed to move the unchanged ESP because the file was locked. A fresh Spriggit deserialize into an owned temporary directory succeeded; the generated and existing packaged ESP SHA-256 values both matched `e43f0e7cf612d9b9140ed14ff90df2b2a95ac8da6a0c487ec8530a8315596c35`, and the existing SEQ bytes were `00 08 00 00`. This confirms the ESP/SEQ are unchanged, not that the full build succeeded.

- [x] All 15 unittests passed when run separately. The chained build/test command did not reach tests because the Spriggit stage failed on the locked ESP.
- [ ] Complete a successful integrated build after the ESP file lock is released; the separate generated-file comparison is already complete.
- [x] Scoped in-game evidence: eight player-originator gestures, seven NPC responses, and one expected no-audience result; see current runtime evidence below. Physical Shift timing, notification display, exhaustive cancellation/error transitions, upgrade coverage, and long-term removal behavior are not established by these logs.

Current runtime evidence is separated below from the older prior-build archive. No assistant-initiated MO2/profile/load-order changes were made; the user performed the save/removal tests.

### Player-originator correction — implemented and runtime-observed

- Approved tradeoff: the player must always be the narration originator (`From`), even though targeted submissions no longer force the captured NPC to respond.
- `Submit` passes the player directly as originator, with the captured NPC as explicit target or `None` for group mode. Capture, Shift override, recipient validation, authored text, local feedback, and one-call/no-retry behavior are unchanged.
- Source trace: `D:/git/SkyrimNet/src/Skyrim/Papyrus/PapyrusLLMUtils.cpp:18–67` registers the supplied originator/target. `src/Skyrim/DialogueManager.cpp:491–560` does not bypass responder selection for player-origin direct narration and subsequently replaces event target/listener with the selected responder. This is source evidence, not installed-native or runtime verification.
- Before/after source-derived `Submit` smoke reproduced the old NPC/player argument ordering and confirmed the new player/NPC targeted call and player/`None` group call, including exact recipient/audience text and local feedback. Missing, dead, disabled, or unloaded targets and stale generations remained fail-closed; API failure did not retry or notify, and generation change during submission suppressed success feedback.
- Both Papyrus scripts compiled into a temporary directory with 0 errors and 0 warnings using the existing build script's compiler, flags, and imports. Only the packaged controller PEX was updated; SHA-256 `dbc9cc6b072ee92caffee8e2bf90dd4039d130f10fc7ccce8d49d1bc93a64367`. Alias PEX, ESP, and SEQ were not changed.
- All 15 existing Lua/config unittests passed in a fresh Python process (`python -B -m unittest discover -s tests`). Initial in-process discovery used a retained Magelight-era test module with five extra callback tests absent from current source; the fresh process removed that stale-module mismatch without changing tests.
- The ASSOS archive below verifies native player-originator arguments and responses, including the targeted Faendal gesture. The correction does not preserve the intended recipient/audience in event `To`; no engine patch or exhaustive UI display proof is claimed.

### Current runtime evidence — 2026-10-02

- `SkyrimNetOutput_ASSOS-1.1.1_2026-10-02_17-43-40.zip`, canonical session 17:38:49.754–17:44:03.175, SkyrimNet `0-26-0-0` / `ea1bc28eec68`: eight native calls, all originator B-man, eight successful registrations, seven generated NPC responses. At 17:42:48.742, `SkyrimNet.log:18093–18095` records B-man as originator and Faendal as explicit target; Faendal responded to B-man. At 17:43:42.139, `:21246–21251` records no eligible NPCs and ends selection. The user confirmed nobody was in earshot and no UI `To` appeared for that last gesture.
- Complete-file correlation retained 50 current request/response IDs and rejected 130 stale input and 5,150 stale output records; newest rejected timestamp 17:37:04.625. This establishes the listed submissions/responses, not every menu, modifier, notification, or update case.
- The ADT archive path `SkyrimNetOutput_ADT_2026-10-02_18-05-40.zip` was reused for two distinct snapshots. The first-read 18:04:54.409–18:05:52.079 session loaded a disabled-mod save, changed location, and saved at 18:05:48.163. It logged no native direct-narration calls; `Papyrus.0.log:177–182` still referenced the missing PlayerSignals script classes. ReSaver showed two definitions and two instances; the user identified and removed two unattached instances and two undefined elements.
- The replacement ADT snapshot spans 18:08:43.710–18:09:13.279, SkyrimNet `0-26-0-0` / `0c57e39fda7b`, ZIP SHA-256 `3b1c4230a33b699f5166f9da805b0c04aa7ed81403364c8150336432cae38d0e`. `SkyrimNet.log:3375` loads `Save6_resaver.ess`; `:3567–3568` reaches post-load/Running at 18:09:05.363. There are no PlayerSignals Papyrus mentions or native narration calls. All 39 supplemental input/output records predate this session.
- This is a short successful cleaned-save load, approximately eight seconds after post-load. It does not include another post-cleanup save/reload cycle or establish unassisted clean removal/long-term safety. ReSaver cleanup is not a universally safe uninstall prescription. Preserve a pre-installation ESS/SKSE save pair.



### Optional intent-authoring agent — implemented and locally rendered

- Packaged `SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/manifest.json` and `prompts/agent_playersignals_intent_helper.prompt`; no actions/triggers. The name follows the source-observed WebUI `agent_` discovery rule.
- Mirrors the supplied iActions helper's generate-and-save workflow. The file-awareness revision offers suggestions without files, requests one record for phrase edits, the full catalog for catalog replacement, and both complete files for placement/rename/removal. It preserves unrelated configuration, scopes reviews to supplied data, labels partial records merge-only, and warns that unsupplied IDs/slots cannot be checked. Standard agent tools cannot read/write these files or execute the PlayerSignals validator; no automatic application or runtime validation is claimed.
- Ran the local `content-validate.exe` against the actual packaged bundle with installed `store/skyrimnet.base` and representative `availableTools`, `chatHistory`, and `userInput` context. Result: `ok:true`, one prompt, zero errors, warnings, unresolved references, or shadows. Observed rendered inherited role, literal `{target}`, tool list, and user context. Validated its JSON example through the actual Lua catalog validator.
- Re-rendered the file-awareness revision against installed base content with no available tools and a suggestion request. Result: `ok:true`, zero errors, warnings, unresolved references, or shadows. Observed the no-filesystem-access workflow and current request in the rendered prompt; its record example passed the actual Lua catalog validator. This checks template rendering and example validity, not LLM adherence.
- User-tested a helper with a local model: it correctly disclosed missing config access and drafted an intent record, but invented an invalid layout shape (`input` as string, wheel as object). The tested template revision and UI discovery were not independently identified.
- Strengthened guidance with MO2 mod-relative/virtual Data/overwrite distinctions, preservation of custom root names, concrete valid input/wheel/slot shapes, navigation behavior, and decimal opening-key examples. Values were checked against CommonLibSSE-NG `RE/B/BSKeyboardDevice.h` (Right Alt 0xB8, Left Alt 0x38, F8/F9/F10 0x42/0x43/0x44; Tab 0x0F, Shift 0x2A/0x36).
- Rendered the revised agent against installed base content with an MO2/thumbs-up/F9 request and no tools: zero errors, warnings, unresolved references, or shadows. All four rendered helper JSON examples and all six player-guide JSON examples passed the actual Lua validators in their stated full-file/fragment contexts. Model adherence to this revision remains unverified. No MO2/load-order changes were made.


### Existing-save compatibility and safe removal

Source comparison confirms the cutover adds no saved controller fields or variables, changes no property defaults, aliases, quest/FormIDs, or startup SEQ; private native maps are rebuilt from both JSON files at load. The stable startup quest plus alias `OnInit`/`OnPlayerLoadGame` maintenance is designed to support new and existing saves, but current existing-save installation/update has not been verified in-game.

Save-update review considerations: persisted quest/script state, initialization on existing-save load, and testing updates before release. Generation guards explicitly protect resumed old menu waits; do not assume saved execution frames disappear.

- [ ] Verify a new install and an update from the previous release on an existing save through the actual `OnPlayerLoadGame` path.
- [x] Document the limited removal test and short cleaned-save load above. Saved remnants persisted without cleanup; there is no shutdown/uninstall cleaner or guaranteed clean mid-playthrough removal. Recommend restoring a pre-installation ESS/SKSE pair; SkyrimNet may retain separately stored narration history.

## Prior-build runtime archive — historical routing evidence

The latest reviewed archive has canonical main-log timestamps **2026-10-01 19:08:25.430–19:23:04.804**, SkyrimNet `0-26-0-0`. It records four PlayerSignals native calls:

| Intent/mode | Recipient | Timestamp |
|---|---|---|
| Greet, targeted | Embry | 19:09:35.552 |
| Offer, group | — | 19:10:39.169 |
| Greet, targeted | Alvor | 19:14:52.752 |
| Think, group | — | 19:22:53.320 |

The trace shows the actual targeted branch skipping the selection step. The four prompts contain the correct Sigma gesture text; the model was `gemma-4-e4b-it`. Review retained 74 current input/output pairs and excluded 6,507 stale outputs; the latest excluded stale output was at **18:51:56.543**.

This archive establishes routing behavior for a prior build only. It does not establish the current JSON catalog or targeted-notification implementation, the physical timing of Shift sampling, local notification behavior, or uninstall safety. Its SkyrimNet attribution output showed the former targeted `eventOriginator=NPC, target=player` path reversing gesture `From`/`To`, while group processing substituted the reply speaker into event `To`. The NPC-originator targeted call is now superseded by the player-originator correction above; this archive does not verify that correction in game. SkyrimNet's responder-based `To` metadata remains unchanged, and no engine patch is approved.

## Historical implementation plan — pre-cutover only

This section preserves the former implementation sequence and runtime evidence for context. Its event/YAML architecture is superseded and must not be followed as current setup guidance.

### Historical phases

- **Preflight and attachment:** authored a standalone ESL-flagged quest/player-alias record and SEQ; checked startup/save-load lifecycle by source review. MO2/profile changes were not made.
- **Configuration and input:** implemented strict raw JSON validation through JContainers Lua, native container ownership, Right Alt default registration, JSON rebinding, and maintenance invalidation. Those source/build results predate this cutover.
- **Former one-selection path:** the earlier controller submitted player-originated `PlayerSignals_Intent_<id>` mod events, and a matching Confirm YAML trigger issued direct narration. This path is obsolete.
- **Former full feature:** authored the four default wheels, 25 shipped intent defaults, external YAML trigger bundle, and player-named local notifications. Trigger text and event filtering are archival only; current editable ID/phrase data is in `intents.json`, as specified above.
- **Former verification:** built PEX/ESP/SEQ, migrated 25 authored triggers into `phospheneoverdrive.playersignals`, and ran beta26 devkit validation. Those checks apply only to the former package and do not validate the current direct-API contract.

### Historical evidence archive

All evidence in this pre-cutover subsection is not evidence for current controller code, target capture, Shift behavior, direct API readiness, API return handling, or notifications:

- Earlier Papyrus builds reported zero errors/warnings against installed SKSE/JContainers/vanilla declarations and stock UIExtensions source. Spriggit 0.40.0 round-tripped the standalone ESP; generated SEQ bytes were `00 08 00 00` for startup quest FormID `00000800`.
- Seven LuaJIT raw-schema regression tests passed; a disposable native-container-adapter smoke exercised the former Lua load path. These do not verify installed native JContainers behavior or this cutover.
- Historical beta26 `content-validate.exe` against the former external package root reported `ok:true`, 25 files, package ID `phospheneoverdrive.playersignals`, and zero errors/warnings/unresolved/shadows; no base tree was supplied.
- The historical archive `D:/Modlists/ADT/_log-dumps/SkyrimNetOutput_ASSOS-1.1.1_2026-09-30_22-41-47.zip` has canonical log timestamps **2026-10-01 17:06:18.043–17:09:58.675**, SkyrimNet `0-26-0-0`. Logs recorded old package discovery/25 filter loads and controller readiness.
- Historical Confirm at **17:06:52.957** reached direct narration but found no eligible nearby NPC. Historical Unsure at **17:09:40.173** selected Ralof and generated a response to `Sigma shrugs, indicating uncertainty.` Generation/TTS queuing was logged, but not that the user heard or saw the output. The archive predates the captured-target/direct-API contract.
- The old decision/mood route reported HTTP 401 / missing authentication header at **17:09:41.707**; its fallback did not block the old Ralof generation. Supplemental OpenRouter logs were stale (September 30), not evidence for the October 1 turns.
- Historical notification/catalog and wheel-label adapter smokes verified constructed values only. The archive predates the current API-return notification rule; old screenshots predate navigation markers and shortened labels.
- The earlier profile inspection found an animation-wheel loose `UIWheelMenu.pex` override. Its winning script/SWF in a later session was not identified. A previous implementation session had no observed Skyrim process and could not connect to the local harness; these limitations/evidence are historical.

## Session continuity

For current work, read the authoritative spec and the active phase above. Historical phases, external-package records, old runtime logs, and old test/build outcomes must not be reconstructed as current behavior or used to claim current verification.
