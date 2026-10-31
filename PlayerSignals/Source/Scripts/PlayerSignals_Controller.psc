Scriptname PlayerSignals_Controller extends Quest

String _path = "Data/SKSE/Plugins/PlayerSignals/layout.json"
Int _config = 0
Int _key = 0
Int _generation = 0
Bool _ready = False
Bool _browsing = False
Bool _held = False
Bool _maintaining = False
Int _mlView = 0
Int _mlSlots = 0
String _mlRequest = ""
String _mlResult = ""
Bool _mlDomReady = False
Bool _mlEntered = False
Bool _mlPrimed = False
Int _mlSequence = 0

Bool Function UseMagelight()
    Return True
EndFunction

Function InvalidateMagelight()
    If !UseMagelight()
        Return
    EndIf
    Int token = _generation
    _mlRequest = ""
    _mlResult = ""
    _mlDomReady = False
    _mlEntered = False
    _mlPrimed = False
    If JContainers.isInstalled() && _mlSlots != 0
        _mlSlots = JValue.release(_mlSlots)
    EndIf
    Magelight.ReleaseUIMode("PlayerSignals")
    If token != _generation
        Return
    EndIf
    Int view = Magelight.FindView("PlayerSignals", "wheel")
    If token == _generation && view != 0
        Magelight.ShowView(view, False)
    EndIf
    ; Keep the last view only as the outer session's release-observation identity.
EndFunction

Event OnMagelightDomReady(string eventName, string strArg, float numArg, Form sender)
    If UseMagelight() && strArg == "PlayerSignals" && numArg as Int == _mlView && _mlRequest != "" && _mlResult == ""
        If _mlPrimed
            _mlResult = _mlRequest + "|-1||cancel"
        Else
            _mlDomReady = True
        EndIf
    EndIf
EndEvent

Event OnMagelightUIModeEntered(string eventName, string strArg, float numArg, Form sender)
    If UseMagelight() && strArg == "PlayerSignals" && numArg as Int == _mlView && _mlRequest != ""
        Int token = _generation
        String request = _mlRequest
        Bool active = Magelight.IsUIModeActive()
        If token != _generation || request != _mlRequest || !active
            Return
        EndIf
        Int activeView = Magelight.GetUIModeView()
        If token == _generation && request == _mlRequest && activeView == _mlView
            _mlEntered = True
        EndIf
    EndIf
EndEvent

Event OnMagelightUIModeExited(string eventName, string strArg, float numArg, Form sender)
    If UseMagelight() && strArg == "PlayerSignals" && numArg as Int == _mlView && _mlRequest != "" && _mlEntered
        Int token = _generation
        String request = _mlRequest
        Bool active = Magelight.IsUIModeActive()
        If token != _generation || request != _mlRequest
            Return
        EndIf
        Int activeView = Magelight.GetUIModeView()
        If token == _generation && request == _mlRequest && _mlResult == "" && (!active || activeView != _mlView)
            _mlResult = request + "|-1||cancel"
        EndIf
    EndIf
EndEvent
Event OnMagelightWheelChoice(string eventName, string strArg, float numArg, Form sender)
    If !UseMagelight() || !JContainers.isInstalled() || eventName != "Magelight_JS_psWheelChoice" || numArg as Int != _mlView || _mlRequest == "" || _mlResult != ""
        Return
    EndIf
    Int token = _generation
    String request = _mlRequest
    Bool active = Magelight.IsUIModeActive()
    If token != _generation || request != _mlRequest || !active
        Return
    EndIf
    Int activeView = Magelight.GetUIModeView()
    If token != _generation || request != _mlRequest || activeView != _mlView
        Return
    EndIf
    If _mlResult == "" && strArg == request + "|-1||cancel"
        _mlResult = strArg
        Return
    EndIf
    Int count = JArray.count(_mlSlots)
    If count > 8
        count = 8
    EndIf
    Int i = 0
    While i < count && token == _generation && request == _mlRequest
        If JArray.valueType(_mlSlots, i) == 5
            Int slot = JArray.getObj(_mlSlots, i)
            String kind = JMap.getStr(slot, "kind")
            String identity = ""
            If kind == "intent"
                identity = JMap.getStr(slot, "intent")
            ElseIf kind == "action"
                identity = JMap.getStr(slot, "actionName")
            EndIf
            If kind == "intent" || kind == "action"
                If token == _generation && request == _mlRequest && _mlResult == "" && (strArg == request + "|" + i + "|" + identity + "|target" || (kind == "intent" && strArg == request + "|" + i + "|" + identity + "|nearby"))
                    _mlResult = strArg
                    Return
                EndIf
            ElseIf kind == "submenu" || kind == "control"
                If token == _generation && request == _mlRequest && _mlResult == "" && strArg == request + "|" + i + "||navigate"
                    _mlResult = strArg
                    Return
                EndIf
            EndIf
        EndIf
        i += 1
    EndWhile
EndEvent

Function PrimeMagelight(Int token)
    If token != _generation || _mlRequest == ""
        Return
    EndIf
    String request = _mlRequest
    String payload = JValue.evalLuaStr(_mlSlots, "return jrequire('PlayerSignals.config').wheelPayload(jobject, '" + JMap.getStr(_config, "theme") + "')")
    If token != _generation || request != _mlRequest
        Return
    EndIf
    If payload == ""
        InvalidateMagelight()
        Return
    EndIf
    Magelight.Call(_mlView, "psWheelBegin", request + "|" + payload)
    If token != _generation || request != _mlRequest
        Return
    EndIf
    _mlPrimed = True
EndFunction
Event OnMagelightViewFailure(string eventName, string strArg, float numArg, Form sender)
    If !UseMagelight() || _mlRequest == ""
        Return
    EndIf
    Int token = _generation
    String request = _mlRequest
    Bool ownEvent = strArg == "PlayerSignals" || StringUtil.Substring(strArg, 0, 14) == "PlayerSignals|"
    If token == _generation && request == _mlRequest && _mlResult == "" && ownEvent && (numArg as Int == _mlView || (eventName == "Magelight_RenderDead" && numArg as Int == 0))
        _mlResult = request + "|-1||cancel"
    EndIf
EndEvent
Function ScheduleMaintenance(Float delay)
    _generation += 1
    _ready = False
    _browsing = False
    _held = False
    If UseMagelight()
        InvalidateMagelight()
    EndIf
    If _key > 0
        UnregisterForKey(_key)
        _key = 0
    EndIf
    RegisterForSingleUpdate(delay)
EndFunction

Event OnUpdate()
    If _maintaining
        RegisterForSingleUpdate(0.5)
        Return
    EndIf
    _maintaining = True
    Int token = _generation
    Maintenance(token)
    _maintaining = False
    If token != _generation
        RegisterForSingleUpdate(0.5)
    EndIf
EndEvent

Function Maintenance(Int token)
    If SKSE.GetVersion() < 2
        Report("SKSE64 is unavailable; launch through SKSE.")
        Return
    EndIf
    If !JContainers.isInstalled()
        ; Keep the owned handle for release if the native dependency is restored.
        ; Calling release while its DLL is unavailable cannot safely clear ownership.
        Report("JContainers API 4 / feature 2 is unavailable.")
        Return
    EndIf
    If _config != 0
        _config = JValue.release(_config)
    EndIf
    If UseMagelight()
        If Magelight.GetVersion() < 3102 || !Magelight.IsReady()
            Report("Magelight host 0.31.2+ is unavailable or not ready.")
            Return
        EndIf
        RegisterForModEvent("Magelight_ViewDomReady", "OnMagelightDomReady")
        RegisterForModEvent("Magelight_UIModeEntered", "OnMagelightUIModeEntered")
        RegisterForModEvent("Magelight_UIModeExited", "OnMagelightUIModeExited")
        RegisterForModEvent("Magelight_JS_psWheelChoice", "OnMagelightWheelChoice")
        RegisterForModEvent("Magelight_ViewLoadFailed", "OnMagelightViewFailure")
        RegisterForModEvent("Magelight_FocusDenied", "OnMagelightViewFailure")
        RegisterForModEvent("Magelight_RenderDead", "OnMagelightViewFailure")
        RegisterForModEvent("Magelight_ViewDestroyed", "OnMagelightViewFailure")
        Bool registered = Magelight.RegisterMod("PlayerSignals", "PlayerSignals")
        If token != _generation
            Return
        EndIf
        If !registered
            Report("Magelight PlayerSignals mod registration failed.")
            Return
        EndIf
        _mlView = Magelight.FindView("PlayerSignals", "wheel")
        If token != _generation
            Return
        EndIf
        If _mlView == 0
            Report("Magelight wheel view/listener is unavailable.")
            Return
        EndIf
        Bool listening = Magelight.RegisterListener(_mlView, "psWheelChoice")
        If token != _generation
            Return
        EndIf
        If !listening
            Report("Magelight wheel view/listener is unavailable.")
            Return
        EndIf
    ElseIf Game.GetModByName("UIExtensions.esp") == 255
        Report("UIExtensions.esp is not loaded.")
        Return
    EndIf
    If Game.GetModByName("SkyrimNet.esp") == 255 || SkyrimNetApi.GetBuildVersion() == ""
        Report("SkyrimNet native API is unavailable; check its installation and SKSE log.")
        Return
    EndIf
    Int transport = JValue.retain(JMap.object(), "PlayerSignals")
    JMap.setStr(transport, "path", _path)
    String failure = JLua.evalLuaStr("local m = jrequire('PlayerSignals.config'); return m.load(args)", transport, "Lua validator unavailable; check JContainers Lua support and PlayerSignals/config.lua.", False)
    Int candidate = 0
    If failure == "" && JMap.valueType(transport, "config") == 5
        candidate = JMap.getObj(transport, "config")
        If candidate != 0
            candidate = JValue.retain(candidate, "PlayerSignals")
        EndIf
    EndIf
    transport = JValue.release(transport)
    If failure != "" || candidate == 0
        Report(_path + ": " + failure)
        Return
    EndIf
    ; The raw validator builds native containers; verify their typed boundary before use.
    If !ValidateNative(candidate)
        candidate = JValue.release(candidate)
        Report(_path + ": invalid native validator result")
        Return
    EndIf
    Int newKey = JMap.getInt(JMap.getObj(candidate, "input"), "openKeyCode")
    Bool newHeld = Input.IsKeyPressed(newKey)
    If token != _generation
        candidate = JValue.release(candidate)
        Return
    EndIf
    RegisterForKey(newKey)
    If token != _generation
        UnregisterForKey(newKey)
        candidate = JValue.release(candidate)
        Return
    EndIf
    ; No external calls between the final generation guard and publishing readiness.
    _config = candidate
    _key = newKey
    _held = newHeld
    _ready = True
    Debug.Trace("[PlayerSignals] Ready: " + _path + "; key " + _key)
EndFunction

Bool Function ValidateNative(Int config)
    If !JValue.isMap(config) || JMap.valueType(config, "schemaVersion") != 2 || JMap.getInt(config, "schemaVersion") != 1
        Return False
    EndIf
    If JMap.valueType(config, "root") != 6 || JMap.valueType(config, "input") != 5 || JMap.valueType(config, "wheels") != 5
        Return False
    EndIf
    If JMap.valueType(config, "notifications") != 5 || JMap.valueType(config, "narrations") != 5
        Return False
    EndIf
    If JMap.valueType(config, "targetNotificationPrefixes") != 5 || JMap.valueType(config, "targetNotificationSuffixes") != 5
        Return False
    EndIf
    Int notifications = JMap.getObj(config, "notifications")
    Int narrations = JMap.getObj(config, "narrations")
    Int targetPrefixes = JMap.getObj(config, "targetNotificationPrefixes")
    Int targetSuffixes = JMap.getObj(config, "targetNotificationSuffixes")
    If !JValue.isMap(notifications) || !JValue.isMap(narrations)
        Return False
    EndIf
    If !JValue.isMap(targetPrefixes) || !JValue.isMap(targetSuffixes)
        Return False
    EndIf
    Int inputConfig = JMap.getObj(config, "input")
    Int wheels = JMap.getObj(config, "wheels")
    If !JValue.isMap(inputConfig) || !JValue.isMap(wheels) || JMap.valueType(inputConfig, "openKeyCode") != 2
        Return False
    EndIf
    Int code = JMap.getInt(inputConfig, "openKeyCode")
    If code < 1 || code > 255 || !JMap.hasKey(wheels, JMap.getStr(config, "root"))
        Return False
    EndIf
    String name = JMap.nextKey(wheels)
    While name != ""
        If JMap.valueType(wheels, name) != 5
            Return False
        EndIf
        Int slots = JMap.getObj(wheels, name)
        If !JValue.isArray(slots) || JArray.count(slots) < 1 || JArray.count(slots) > 8
            Return False
        EndIf
        Int i = 0
        While i < JArray.count(slots)
            Int kind = JArray.valueType(slots, i)
            If kind != 1
                If kind != 5
                    Return False
                EndIf
                Int entry = JArray.getObj(slots, i)
                If !JValue.isMap(entry) || JMap.valueType(entry, "label") != 6
                    Return False
                EndIf
                If JMap.valueType(entry, "kind") != 6
                    Return False
                EndIf
                String entryKind = JMap.getStr(entry, "kind")
                If entryKind == "action"
                    If JMap.valueType(entry, "actionName") != 6 || JMap.getStr(entry, "actionName") == "" || JMap.valueType(entry, "argsJson") != 6 || JMap.getStr(entry, "argsJson") == ""
                        Return False
                    EndIf
                    If JMap.hasKey(entry, "event")
                        If JMap.valueType(entry, "event") != 6 || JMap.valueType(entry, "intent") != 6
                            Return False
                        EndIf
                        String eventMode = JMap.getStr(entry, "event")
                        If eventMode != "persistent" && eventMode != "shortLived" && eventMode != "both"
                            Return False
                        EndIf
                    ElseIf JMap.hasKey(entry, "intent")
                        Return False
                    EndIf
                ElseIf entryKind == "intent"
                    If JMap.valueType(entry, "intent") != 6
                        Return False
                    EndIf
                ElseIf entryKind == "submenu"
                    If JMap.valueType(entry, "submenu") != 6 || !JMap.hasKey(wheels, JMap.getStr(entry, "submenu"))
                        Return False
                    EndIf
                ElseIf entryKind == "control"
                    If JMap.valueType(entry, "control") != 6
                        Return False
                    EndIf
                Else
                    Return False
                EndIf
                If JMap.hasKey(entry, "intent")
                    If JMap.valueType(entry, "intent") != 6
                        Return False
                    EndIf
                    String intent = JMap.getStr(entry, "intent")
                    If JMap.valueType(notifications, intent) != 6 || JMap.getStr(notifications, intent) == ""
                        Return False
                    EndIf
                    If JMap.valueType(narrations, intent) != 6 || JMap.getStr(narrations, intent) == ""
                        Return False
                    EndIf
                    If JMap.valueType(targetPrefixes, intent) != 6 || JMap.valueType(targetSuffixes, intent) != 6
                        Return False
                    EndIf
                EndIf
            EndIf
            i += 1
        EndWhile
        name = JMap.nextKey(wheels, name)
    EndWhile
    Return True
EndFunction

Event OnKeyDown(Int keyCode)
    If keyCode != _key || _held
        Return
    EndIf
    _held = True
    If !_ready || _browsing || Utility.IsInMenuMode() || UI.IsMenuOpen("CustomMenu")
        Return
    EndIf
    If !Game.IsMenuControlsEnabled() || !Game.IsMovementControlsEnabled()
        Return
    EndIf
    Actor player = Game.GetPlayer()
    ; External gameplay gates/player lookup can yield to maintenance or another key stack.
    If keyCode != _key || !_ready || _browsing
        Return
    EndIf
    _browsing = True
    Int token = _generation
    ; Capture once before the first wheel; navigation never retargets this session.
    Actor recipient = Game.GetCurrentCrosshairRef() as Actor
    If recipient == player
        recipient = None
    EndIf
    ; A local lease keeps the old graph alive across latent OpenMenu, even after reload.
    Int session = JValue.retain(_config, "PlayerSignals")
    Int history = JValue.retain(JArray.object(), "PlayerSignals")
    Int selection = Browse(session, history, token, player)
    Bool broadcast = False
    If selection != 0
        ; Preserve immediate post-Browse Shift sampling before catalog lookups.
        broadcast = Input.IsKeyPressed(42) || Input.IsKeyPressed(54)
    EndIf
    String kind = ""
    String pending = ""
    If selection != 0
        kind = JMap.getStr(selection, "kind")
        pending = JMap.getStr(selection, "identity")
    EndIf
    Bool nearby = selection != 0 && JMap.getInt(selection, "nearby") == 1
    Bool targeted = recipient != None && !broadcast && !nearby
    String feedbackPrefix = ""
    String feedbackSuffix = "."
    String narration = ""
    String actionName = ""
    String argsJson = ""
    String eventMode = ""
    String eventIntent = ""
    If selection != 0 && token == _generation && _ready
        If kind == "intent"
            ; Capture text while the session lease is alive, before the final dispatch guard.
            String name = player.GetDisplayName()
            If targeted
                feedbackPrefix = name + " " + JMap.getStr(JMap.getObj(session, "targetNotificationPrefixes"), pending)
                feedbackSuffix = JMap.getStr(JMap.getObj(session, "targetNotificationSuffixes"), pending) + "."
            Else
                feedbackPrefix = name + " " + JMap.getStr(JMap.getObj(session, "notifications"), pending)
            EndIf
            narration = name + " " + JMap.getStr(JMap.getObj(session, "narrations"), pending) + "."
        ElseIf kind == "action"
            actionName = JMap.getStr(selection, "actionName")
            argsJson = JMap.getStr(selection, "argsJson")
            eventMode = JMap.getStr(selection, "event")
            eventIntent = JMap.getStr(selection, "intent")
            If eventMode != "" && recipient
                String actorName = player.GetDisplayName()
                If token == _generation && _ready
                    String recipientName = recipient.GetDisplayName()
                    If token == _generation && _ready
                        narration = actorName + " " + JMap.getStr(JMap.getObj(session, "narrations"), eventIntent) + ". This gesture is addressed to " + recipientName + "."
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
    history = JValue.release(history)
    session = JValue.release(session)
    If token == _generation && _ready && selection != 0
        If kind == "action"
            DispatchAction(actionName, argsJson, eventMode, narration, player, recipient, token)
        ElseIf kind == "intent"
            Submit(narration, feedbackPrefix, feedbackSuffix, player, recipient, targeted, token)
        EndIf
    EndIf
    If selection != 0
        selection = JValue.release(selection)
    EndIf
    If token == _generation && UseMagelight()
        ; The overlay may suppress keyup while it owns keyboard focus.
        Bool held = Input.IsKeyPressed(_key)
        If token == _generation
            _held = held
        EndIf
    EndIf
    If token == _generation
        _browsing = False
    EndIf
EndEvent

Function Submit(String narration, String feedbackPrefix, String feedbackSuffix, Actor player, Actor recipient, Bool targeted, Int token)
    Actor targetActor = None
    String failure = ""
    If targeted
        If recipient
            targetActor = recipient
            String recipientName = recipient.GetDisplayName()
            narration += " This gesture is addressed to " + recipientName + "."
            feedbackPrefix += recipientName
        EndIf
        ; Validate after resolving text: the display-name lookup may yield.
        If !recipient || recipient.IsDead() || recipient.IsDisabled() || !recipient.Is3DLoaded()
            failure = "Captured NPC is no longer available; no narration submitted."
        EndIf
    Else
        narration += " This gesture is addressed to everyone nearby."
    EndIf
    ; Actor queries can yield. No external lookup between this guard and dispatch.
    If token != _generation || !_ready
        Return
    EndIf
    If failure != ""
        Debug.Trace("[PlayerSignals] " + failure, 1)
        Return
    EndIf
    Int result = SkyrimNetApi.DirectNarration(narration, player, targetActor)
    If token != _generation || !_ready
        Return
    EndIf
    If result == 0
        Debug.Notification(feedbackPrefix + feedbackSuffix)
    Else
        Debug.Trace("[PlayerSignals] DirectNarration failed: " + result + "; no success notification.", 1)
    EndIf
EndFunction
Function DispatchAction(String actionName, String argsJson, String eventMode, String eventText, Actor player, Actor recipient, Int token)
    String failure = ""
    If !recipient
        failure = "no captured NPC"
    ElseIf recipient.IsDead() || recipient.IsDisabled() || !recipient.Is3DLoaded()
        failure = "captured NPC is no longer available"
    EndIf
    If token != _generation || !_ready
        Return
    EndIf
    If failure == ""
        Bool registered = SkyrimNetApi.IsActionRegistered(actionName)
        If token != _generation || !_ready
            Return
        EndIf
        If !registered
            failure = "action is not registered"
        EndIf
    EndIf
    If failure == "" && actionName == "AccompanyTarget"
        Bool eligibleStart = SkyrimNetInternal.StartFollow_IsEligible(recipient, "{}", argsJson)
        If token != _generation || !_ready
            Return
        EndIf
        If !eligibleStart
            failure = "captured NPC is not eligible"
        EndIf
    ElseIf failure == "" && actionName == "StopAccompanying"
        Bool eligibleStop = SkyrimNetInternal.StopFollow_IsEligible(recipient, "{}", argsJson)
        If token != _generation || !_ready
            Return
        EndIf
        If !eligibleStop
            failure = "captured NPC is not eligible"
        EndIf
    ElseIf failure == "" && actionName == "WaitHere"
        Bool eligiblePause = SkyrimNetInternal.PauseFollow_IsEligible(recipient, "{}", argsJson)
        If token != _generation || !_ready
            Return
        EndIf
        If !eligiblePause
            failure = "captured NPC is not eligible"
        EndIf
    EndIf
    If failure != ""
        If token == _generation && _ready
            Report("Action " + actionName + " not dispatched: " + failure + ".", token)
        EndIf
        Return
    EndIf
    ; Revalidate immediately before the final generation guard and single API call.
    If !recipient || recipient.IsDead() || recipient.IsDisabled() || !recipient.Is3DLoaded()
        failure = "captured NPC is no longer available"
    EndIf
    If token != _generation || !_ready
        Return
    EndIf
    If failure != ""
        Report("Action " + actionName + " not dispatched: " + failure + ".", token)
        Return
    EndIf
    Int result = SkyrimNetApi.ExecuteAction(actionName, recipient, argsJson)
    If token != _generation || !_ready
        Return
    EndIf
    If result != 0
        Report("Action " + actionName + " request rejected (" + result + ").", token)
        Return
    EndIf
    If eventMode == ""
        Return
    EndIf
    Bool eventFailed = False
    If eventMode == "persistent" || eventMode == "both"
        Int persistentResult = SkyrimNetApi.RegisterPersistentEvent(eventText, player, recipient)
        If token != _generation || !_ready
            Return
        EndIf
        If persistentResult != 0
            eventFailed = True
        EndIf
    EndIf
    If eventMode == "shortLived" || eventMode == "both"
        Int targetFormID = recipient.GetFormID()
        If token != _generation || !_ready
            Return
        EndIf
        String eventId = "playersignals_" + actionName + "_" + targetFormID
        Int shortResult = SkyrimNetApi.RegisterShortLivedEvent(eventId, "playersignals_action", eventText, eventText, 60000, player, recipient)
        If token != _generation || !_ready
            Return
        EndIf
        If shortResult != 0
            eventFailed = True
        EndIf
    EndIf
    If eventFailed && token == _generation && _ready
        Report("Action " + actionName + " was dispatched, but its event was not recorded.", token)
    EndIf
EndFunction

Event OnKeyUp(Int keyCode, Float holdTime)
    If keyCode == _key
        _held = False
    EndIf
EndEvent

Int Function Browse(Int config, Int history, Int token, Actor player)
    Int result = BrowseWheels(config, history, token, player)
    If UseMagelight() && token == _generation
        If !FinishMagelight(token)
            If result != 0
                result = JValue.release(result)
            EndIf
            Return 0
        EndIf
    EndIf
    Return result
EndFunction

Int Function BrowseWheels(Int config, Int history, Int token, Actor player)
    Int wheels = JMap.getObj(config, "wheels")
    String current = JMap.getStr(config, "root")
    While token == _generation && _ready
        Int slots = JMap.getObj(wheels, current)
        Int selected = -1
        If UseMagelight()
            selected = BrowseMagelight(slots, token)
        Else
            UIMenuBase menu = UIExtensions.GetMenu("UIWheelMenu", True)
            If token != _generation || !_ready
                Return 0
            EndIf
            If !menu
                Report("UIExtensions UIWheelMenu is unavailable.")
                Return 0
            EndIf
            Int i = 0
            While i < 8
                String label = ""
                Bool enabled = False
                If i < JArray.count(slots) && JArray.valueType(slots, i) == 5
                    Int entry = JArray.getObj(slots, i)
                    label = JMap.getStr(entry, "label")
                    enabled = True
                EndIf
                menu.SetPropertyIndexString("optionText", i, label)
                menu.SetPropertyIndexString("optionLabelText", i, label)
                menu.SetPropertyIndexBool("optionEnabled", i, enabled)
                i += 1
            EndWhile
            If token != _generation || !_ready
                Return 0
            EndIf
            selected = menu.OpenMenu(player)
        EndIf
        If token != _generation || !_ready
            Return 0
        EndIf
        If selected == 255
            Report("UIExtensions wheel opening/wait failed; no selection submitted.")
            Return 0
        EndIf
        If selected < 0 || selected > 15
            Return 0
        EndIf
        Bool nearby = UseMagelight() && selected >= 8
        If nearby
            selected -= 8
        EndIf
        If selected > 7 || selected >= JArray.count(slots) || JArray.valueType(slots, selected) != 5
            Return 0
        EndIf
        Int choice = JArray.getObj(slots, selected)
        String kind = JMap.getStr(choice, "kind")
        If kind == "intent" || kind == "action"
            If nearby && kind != "intent"
                Return 0
            EndIf
            Int selection = JValue.retain(JMap.object(), "PlayerSignals")
            JMap.setStr(selection, "kind", kind)
            If kind == "intent"
                JMap.setStr(selection, "identity", JMap.getStr(choice, "intent"))
            Else
                JMap.setStr(selection, "identity", JMap.getStr(choice, "actionName"))
                JMap.setStr(selection, "actionName", JMap.getStr(choice, "actionName"))
                JMap.setStr(selection, "argsJson", JMap.getStr(choice, "argsJson"))
                JMap.setStr(selection, "event", JMap.getStr(choice, "event"))
                JMap.setStr(selection, "intent", JMap.getStr(choice, "intent"))
            EndIf
            If nearby
                JMap.setInt(selection, "nearby", 1)
            EndIf
            Return selection
        ElseIf nearby
            Return 0
        ElseIf kind == "submenu"
            JArray.addStr(history, current)
            current = JMap.getStr(choice, "submenu")
        ElseIf kind == "control" && JMap.getStr(choice, "control") == "back" && JArray.count(history) > 0
            Int last = JArray.count(history) - 1
            current = JArray.getStr(history, last)
            JArray.eraseIndex(history, last)
        Else
            Return 0
        EndIf
    EndWhile
    Return 0
EndFunction
Int Function BrowseMagelight(Int slots, Int token)
    If token != _generation || !_ready
        Return -1
    EndIf
    _mlSequence += 1
    String request = token + "_" + Utility.GetCurrentRealTime() + "_" + Utility.RandomInt(0, 1000000) + "_" + _mlSequence
    Int slotLease = JValue.retain(slots, "PlayerSignals")
    If token != _generation || !_ready
        slotLease = JValue.release(slotLease)
        Return -1
    EndIf
    Bool firstWheel = !_mlEntered
    _mlRequest = request
    _mlResult = ""
    _mlSlots = slotLease
    _mlDomReady = False
    _mlPrimed = False
    Int view = Magelight.FindView("PlayerSignals", "wheel")
    If token != _generation || !_ready || _mlRequest != request
        Return -1
    EndIf
    If view == 0
        InvalidateMagelight()
        Return -1
    EndIf
    _mlView = view
    If firstWheel
        ; The host shows the page while acquiring focus; it stays blank until armed.
        Bool requested = Magelight.RequestUIMode(view, True)
        If token != _generation || _mlRequest != request
            Return -1
        EndIf
        If !requested
            InvalidateMagelight()
            Return -1
        EndIf
        Float entryDeadline = Utility.GetCurrentRealTime() + 5.0
        While token == _generation && _mlRequest == request && _mlResult == "" && !_mlEntered && Utility.GetCurrentRealTime() < entryDeadline
            Utility.WaitMenuMode(0.1)
        EndWhile
    Else
        ; Never reacquire after a forced exit between wheels.
        Bool active = Magelight.IsUIModeActive()
        If token != _generation || _mlRequest != request
            Return -1
        EndIf
        Int activeView = Magelight.GetUIModeView()
        If token != _generation || _mlRequest != request
            Return -1
        EndIf
        If !active || activeView != view
            InvalidateMagelight()
            Return -1
        EndIf
    EndIf
    If token != _generation || _mlRequest != request
        Return -1
    EndIf
    If !_mlEntered || _mlResult != ""
        InvalidateMagelight()
        Return -1
    EndIf
    _mlDomReady = False
    Magelight.ReloadView(view)
    If token != _generation || _mlRequest != request
        Return -1
    EndIf
    Float deadline = Utility.GetCurrentRealTime() + 10.0
    While token == _generation && _mlRequest == request && _mlResult == "" && !_mlDomReady && Utility.GetCurrentRealTime() < deadline
        Utility.WaitMenuMode(0.1)
    EndWhile
    If token != _generation || _mlRequest != request
        Return -1
    EndIf
    If !_mlDomReady || _mlResult != ""
        InvalidateMagelight()
        Return -1
    EndIf
    PrimeMagelight(token)
    If token != _generation || _mlRequest != request
        Return -1
    EndIf
    If _mlResult != ""
        InvalidateMagelight()
        Return -1
    EndIf
    Magelight.Call(view, "psWheelArm", request)
    While token == _generation && _mlRequest != "" && _mlResult == ""
        Utility.WaitMenuMode(0.1)
        If token != _generation || _mlRequest == ""
            Return -1
        EndIf
        If _mlResult == ""
            Bool hostReady = Magelight.IsReady()
            If token != _generation || _mlRequest == ""
                Return -1
            EndIf
            Bool modeActive = Magelight.IsUIModeActive()
            If token != _generation || _mlRequest == ""
                Return -1
            EndIf
            Int modeView = Magelight.GetUIModeView()
            If token != _generation || _mlRequest == ""
                Return -1
            EndIf
            If _mlResult == "" && (!hostReady || !modeActive || modeView != _mlView)
                InvalidateMagelight()
                Return -1
            EndIf
        EndIf
    EndWhile
    If token != _generation || _mlRequest == ""
        Return -1
    EndIf
    String result = _mlResult
    Int selected = -1
    If result == _mlRequest + "|-1||cancel"
        selected = -1
    Else
        Int i = 0
        While i < JArray.count(slots) && i < 8
            If JArray.valueType(slots, i) == 5
                Int slot = JArray.getObj(slots, i)
                String kind = JMap.getStr(slot, "kind")
                If kind == "intent" || kind == "action"
                    String identity = JMap.getStr(slot, "intent")
                    If kind == "action"
                        identity = JMap.getStr(slot, "actionName")
                    EndIf
                    If result == _mlRequest + "|" + i + "|" + identity + "|target"
                        selected = i
                        i = 8
                    ElseIf kind == "intent" && result == _mlRequest + "|" + i + "|" + identity + "|nearby"
                        selected = i + 8
                        i = 8
                    EndIf
                ElseIf kind == "submenu" || kind == "control"
                    If result == _mlRequest + "|" + i + "||navigate"
                        selected = i
                        i = 8
                    EndIf
                EndIf
            EndIf
            i += 1
        EndWhile
    EndIf
    If token == _generation && _mlRequest != ""
        _mlRequest = ""
        _mlResult = ""
        _mlPrimed = False
        If JContainers.isInstalled() && _mlSlots != 0
            _mlSlots = JValue.release(_mlSlots)
        EndIf
    EndIf
    Return selected
EndFunction

Bool Function FinishMagelight(Int token)
    If token != _generation
        Return False
    EndIf
    ; Only the outer browse session releases input, including all failure/exit paths.
    Int view = _mlView
    _mlRequest = ""
    _mlResult = ""
    _mlEntered = False
    _mlPrimed = False
    If JContainers.isInstalled() && _mlSlots != 0
        _mlSlots = JValue.release(_mlSlots)
    EndIf
    Magelight.ReleaseUIMode("PlayerSignals")
    If token != _generation
        Return False
    EndIf
    Float deadline = Utility.GetCurrentRealTime() + 5.0
    Bool stillOwned = Magelight.IsUIModeActive()
    If token != _generation
        Return False
    EndIf
    Int activeView = Magelight.GetUIModeView()
    If token != _generation
        Return False
    EndIf
    While stillOwned && activeView == view && Utility.GetCurrentRealTime() < deadline
        Utility.WaitMenuMode(0.1)
        If token != _generation
            Return False
        EndIf
        stillOwned = Magelight.IsUIModeActive()
        If token != _generation
            Return False
        EndIf
        activeView = Magelight.GetUIModeView()
        If token != _generation
            Return False
        EndIf
    EndWhile
    If stillOwned && activeView == view
        Return False
    EndIf
    view = Magelight.FindView("PlayerSignals", "wheel")
    If token != _generation
        Return False
    EndIf
    If view != 0
        Magelight.ShowView(view, False)
    EndIf
    If token != _generation
        Return False
    EndIf
    _mlView = 0
    Return True
EndFunction

Function Report(String details, Int token = -1)
    If token >= 0 && (token != _generation || !_ready)
        Return
    EndIf
    Debug.Trace("[PlayerSignals] " + details, 2)
    If token >= 0 && (token != _generation || !_ready)
        Return
    EndIf
    Debug.Notification("PlayerSignals: " + details)
EndFunction
