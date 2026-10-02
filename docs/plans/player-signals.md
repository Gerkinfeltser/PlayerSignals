# Implementation Plan: PlayerSignals (for SkyrimNet)

Status: The approved captured-target/direct-narration contract is active. Scoped Lua-loader/source-derived adapter smokes passed, both Papyrus scripts compiled, and 15 unittests passed separately. The integrated full build failed at a later Spriggit step; in-game acceptance remains pending.
Updated: 2026-10-01

Authoritative behavior, schema, targeting, narration, and acceptance contracts: [PlayerSignals specification](../specs/player-signals.md). Update that spec first if an approved contract changes.

## Work location and boundaries

- Repository: `D:/gerkgit/SkyrimNet_PlayerSignals`.
- Actual mod root: `PlayerSignals/`; only this child folder is symlinked into MO2.
- Authored plugin records: `PlayerSignals_spriggit/`, outside the mod root.
- Do not change MO2, symlinks, plugin activation, or load order. No commit/push.
- Do not use the former mod-event/YAML external-package installation, editing, or activation procedures as current instructions.

## Active phase — Captured targeting and direct narration

This phase replaces the former `SendModEvent`/external-YAML-trigger path. The controller and Lua loader must follow the frozen specification, including the editable JSON registry and target-feedback maps; the primary owns integration, build, and runtime verification.

### Implementation sequence

1. **Native API readiness:** require both loaded `SkyrimNet.esp` and a nonempty `SkyrimNetApi.GetBuildVersion()` before enabling the feature. Use installed SkyrimNet script imports in the build, ordered after JContainers and before vanilla imports.
2. **Capture and selection:** capture the current crosshair NPC before opening the wheel. Immediately after `Browse` returns a final accepted intent, sample left/right Shift scan codes 42/54 before feedback/catalog lookups. Either held key overrides targeting to group mode; no captured NPC is also group mode.
3. **Submission:** targeted mode checks the captured actor is alive, enabled, and 3D-loaded at submission. Without a Shift override, any failed check ends silently, never redirecting to group or another NPC. Targeted call: `SkyrimNetApi.DirectNarration(text, respondingNPC, player)`. Group call: `SkyrimNetApi.DirectNarration(text, player, None)`. Group text explicitly addresses everyone nearby; witnesses may join, but no response or compliance is guaranteed.
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
- [ ] Verify current behavior in game. The adapter/source smokes do not verify Papyrus VM/native execution, physical Shift timing, in-game notifications, or uninstall behavior.

The latest reviewed runtime archive below is prior-build routing evidence only. It does not verify the current JSON catalog, targeted local notifications, physical Shift timing, or uninstall behavior. No MO2 changes were made.

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

Comparison reference: `C:/Users/vector/ivault/reference/skyrim/skyrim-mid-playthrough-mod-updates.md` (Skyrim Mod Mid-Playthrough Updates). Applied considerations: persisted quest/script state, initialization on existing-save load, and testing updates before release. Do not rely on its claim that execution frames are unsaved; generation guards explicitly protect resumed old menu waits.

- [ ] Verify a new install and an update from the previous release on an existing save through the actual `OnPlayerLoadGame` path.
- [ ] Verify/document removal from a save. There is no shutdown/uninstall cleaner and no guaranteed clean mid-playthrough removal. Recommend restoring a pre-installation save before removing the mod; SkyrimNet may retain separately stored narration history even after Skyrim save rollback.

## Prior-build runtime archive — historical routing evidence

The latest reviewed archive has canonical main-log timestamps **2026-10-01 19:08:25.430–19:23:04.804**, SkyrimNet `0-26-0-0`. It records four PlayerSignals native calls:

| Intent/mode | Recipient | Timestamp |
|---|---|---|
| Greet, targeted | Embry | 19:09:35.552 |
| Offer, group | — | 19:10:39.169 |
| Greet, targeted | Alvor | 19:14:52.752 |
| Think, group | — | 19:22:53.320 |

The trace shows the actual targeted branch skipping the selection step. The four prompts contain the correct Sigma gesture text; the model was `gemma-4-e4b-it`. Review retained 74 current input/output pairs and excluded 6,507 stale outputs; the latest excluded stale output was at **18:51:56.543**.

This archive establishes routing behavior for a prior build only. It does not establish the current JSON catalog or targeted-notification implementation, the physical timing of Shift sampling, local notification behavior, or uninstall safety. Its SkyrimNet attribution output showed the targeted `eventOriginator=NPC, target=player` path reversing gesture `From`/`To`, while group processing substituted the reply speaker into event `To`. This known engine behavior remains unfixed; no engine patch is approved, and do not claim it is fixed.

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
