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
    If token == _generation
        _mlView = 0
    EndIf
EndFunction

Event OnMagelightDomReady(string eventName, string strArg, float numArg, Form sender)
    If UseMagelight() && strArg == "PlayerSignals" && numArg as Int == _mlView && _mlRequest != "" && _mlResult == ""
        If _mlPrimed
            _mlResult = _mlRequest + "|-1|"
        Else
            _mlDomReady = True
        EndIf
    EndIf
EndEvent

Event OnMagelightUIModeEntered(string eventName, string strArg, float numArg, Form sender)
    If UseMagelight() && strArg == "PlayerSignals" && numArg as Int == _mlView && _mlRequest != "" && _mlPrimed
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
            _mlResult = request + "|-1|"
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
    If _mlResult == "" && strArg == request + "|-1|"
        _mlResult = strArg
        Return
    EndIf
    Int i = 0
    While i < JArray.count(_mlSlots) && i < 8 && token == _generation && request == _mlRequest
        If JArray.valueType(_mlSlots, i) == 5
            Int slot = JArray.getObj(_mlSlots, i)
            String intent = ""
            If JMap.hasKey(slot, "intent")
                intent = JMap.getStr(slot, "intent")
            EndIf
            If token == _generation && request == _mlRequest && _mlResult == "" && strArg == request + "|" + i + "|" + intent
                _mlResult = strArg
                Return
            EndIf
        EndIf
        i += 1
    EndWhile
EndEvent

Function PrimeMagelight(Int token)
    If token != _generation || _mlRequest == ""
        Return
    EndIf
    Magelight.Call(_mlView, "psWheelBegin", _mlRequest)
    If token != _generation || _mlRequest == ""
        Return
    EndIf
    Int i = 0
    While i < 8 && token == _generation && _mlRequest != ""
        If i < JArray.count(_mlSlots) && JArray.valueType(_mlSlots, i) == 5
            Int slot = JArray.getObj(_mlSlots, i)
            Magelight.Call(_mlView, "psWheelLabel" + i, JMap.getStr(slot, "label"))
            If token != _generation || _mlRequest == ""
                Return
            EndIf
            String intent = ""
            If JMap.hasKey(slot, "intent")
                intent = JMap.getStr(slot, "intent")
            EndIf
            Magelight.Call(_mlView, "psWheelIntent" + i, intent)
        EndIf
        If token != _generation || _mlRequest == ""
            Return
        EndIf
        i += 1
    EndWhile
    If token != _generation || _mlRequest == ""
        Return
    EndIf
    _mlPrimed = True
    Magelight.ShowView(_mlView, True)
EndFunction
Event OnMagelightViewFailure(string eventName, string strArg, float numArg, Form sender)
    If !UseMagelight() || _mlRequest == ""
        Return
    EndIf
    Int token = _generation
    String request = _mlRequest
    Bool ownEvent = strArg == "PlayerSignals" || StringUtil.Substring(strArg, 0, 14) == "PlayerSignals|"
    If token == _generation && request == _mlRequest && _mlResult == "" && ownEvent && (numArg as Int == _mlView || (eventName == "Magelight_RenderDead" && numArg as Int == 0))
        _mlResult = request + "|-1|"
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
                ElseIf JMap.hasKey(entry, "submenu")
                    If JMap.valueType(entry, "submenu") != 6 || !JMap.hasKey(wheels, JMap.getStr(entry, "submenu"))
                        Return False
                    EndIf
                ElseIf JMap.valueType(entry, "control") != 6
                    Return False
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
    Bool targeted = recipient != None
    ; A local lease keeps the old graph alive across latent OpenMenu, even after reload.
    Int session = JValue.retain(_config, "PlayerSignals")
    Int history = JValue.retain(JArray.object(), "PlayerSignals")
    String pending = Browse(session, history, token, player)
    Bool broadcast = False
    If pending != ""
        ; Hold Shift through selection; stock UIExtensions does not return click modifiers.
        broadcast = Input.IsKeyPressed(42) || Input.IsKeyPressed(54)
    EndIf
    targeted = targeted && !broadcast
    String feedbackPrefix = ""
    String feedbackSuffix = "."
    String narration = ""
    If pending != "" && token == _generation && _ready
        ; Capture text while the session lease is alive, before the final dispatch guard.
        String name = player.GetDisplayName()
        If targeted
            feedbackPrefix = name + " " + JMap.getStr(JMap.getObj(session, "targetNotificationPrefixes"), pending)
            feedbackSuffix = JMap.getStr(JMap.getObj(session, "targetNotificationSuffixes"), pending) + "."
        Else
            feedbackPrefix = name + " " + JMap.getStr(JMap.getObj(session, "notifications"), pending)
        EndIf
        narration = name + " " + JMap.getStr(JMap.getObj(session, "narrations"), pending) + "."
    EndIf
    history = JValue.release(history)
    session = JValue.release(session)
    If token == _generation && _ready && pending != ""
        Submit(narration, feedbackPrefix, feedbackSuffix, player, recipient, targeted, token)
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

Event OnKeyUp(Int keyCode, Float holdTime)
    If keyCode == _key
        _held = False
    EndIf
EndEvent

String Function Browse(Int config, Int history, Int token, Actor player)
    Int wheels = JMap.getObj(config, "wheels")
    String current = JMap.getStr(config, "root")
    While token == _generation && _ready
        Int slots = JMap.getObj(wheels, current)
        Int selected = -1
        If UseMagelight()
            selected = BrowseMagelight(slots, token)
        Else
            UIMenuBase menu = UIExtensions.GetMenu("UIWheelMenu", True)
            ; GetMenu/reset may wait in another framework version; recheck before opening.
            If token != _generation || !_ready
                Return ""
            EndIf
            If !menu
                Report("UIExtensions UIWheelMenu is unavailable.")
                Return ""
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
                Return ""
            EndIf
            selected = menu.OpenMenu(player)
        EndIf
        ; Never inspect the result against replacement configuration.
        If token != _generation || !_ready
            Return ""
        EndIf
        If selected < 0 || selected > 7 || selected >= JArray.count(slots)
            If selected == 255
                Report("UIExtensions wheel opening/wait failed; no intent submitted.")
            EndIf
            Return ""
        EndIf
        If JArray.valueType(slots, selected) != 5
            Return ""
        EndIf
        Int choice = JArray.getObj(slots, selected)
        If JMap.hasKey(choice, "intent")
            Return JMap.getStr(choice, "intent")
        ElseIf JMap.hasKey(choice, "submenu")
            JArray.addStr(history, current)
            current = JMap.getStr(choice, "submenu")
        ElseIf JMap.getStr(choice, "control") == "back" && JArray.count(history) > 0
            Int last = JArray.count(history) - 1
            current = JArray.getStr(history, last)
            JArray.eraseIndex(history, last)
        Else
            Return ""
        EndIf
    EndWhile
    Return ""
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
    _mlRequest = request
    _mlResult = ""
    _mlSlots = slotLease
    _mlDomReady = False
    _mlEntered = False
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
    Magelight.ReloadView(view)
    If token != _generation || !_ready || _mlRequest != request
        Return -1
    EndIf
    Magelight.ShowView(view, True)
    If token != _generation || !_ready || _mlRequest != request
        Return -1
    EndIf
    Float deadline = Utility.GetCurrentRealTime() + 10.0
    While token == _generation && _mlRequest != "" && !_mlDomReady && Utility.GetCurrentRealTime() < deadline
        Utility.WaitMenuMode(0.1)
    EndWhile
    If token != _generation || _mlRequest == ""
        Return -1
    EndIf
    If !_mlDomReady
        InvalidateMagelight()
        Return -1
    EndIf
    PrimeMagelight(token)
    If token != _generation || _mlRequest == ""
        Return -1
    EndIf
    If _mlResult != ""
        InvalidateMagelight()
        Return -1
    EndIf
    Bool requested = Magelight.RequestUIMode(_mlView, True)
    If token != _generation || _mlRequest == ""
        Return -1
    EndIf
    If !requested
        InvalidateMagelight()
        Return -1
    EndIf
    deadline = Utility.GetCurrentRealTime() + 5.0
    While token == _generation && _mlRequest != "" && _mlResult == "" && !_mlEntered && Utility.GetCurrentRealTime() < deadline
        Utility.WaitMenuMode(0.1)
    EndWhile
    If token != _generation || _mlRequest == ""
        Return -1
    EndIf
    If !_mlEntered || _mlResult != ""
        InvalidateMagelight()
        Return -1
    EndIf
    Magelight.Call(_mlView, "psWheelArm", _mlRequest)
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
    If result == _mlRequest + "|-1|"
        selected = -1
    Else
        Int i = 0
        While i < JArray.count(slots) && i < 8
            If JArray.valueType(slots, i) == 5
                Int slot = JArray.getObj(slots, i)
                String intent = ""
                If JMap.hasKey(slot, "intent")
                    intent = JMap.getStr(slot, "intent")
                EndIf
                If result == _mlRequest + "|" + i + "|" + intent
                    selected = i
                    i = 8
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
        Magelight.ReleaseUIMode("PlayerSignals")
        If token == _generation
            deadline = Utility.GetCurrentRealTime() + 5.0
            Bool stillOwned = Magelight.IsUIModeActive()
            If token != _generation
                Return -1
            EndIf
            Int activeView = Magelight.GetUIModeView()
            If token != _generation
                Return -1
            EndIf
            While token == _generation && stillOwned && activeView == _mlView && Utility.GetCurrentRealTime() < deadline
                Utility.WaitMenuMode(0.1)
                If token != _generation
                    Return -1
                EndIf
                stillOwned = Magelight.IsUIModeActive()
                If token != _generation
                    Return -1
                EndIf
                activeView = Magelight.GetUIModeView()
                If token != _generation
                    Return -1
                EndIf
            EndWhile
            If stillOwned && activeView == _mlView
                selected = -1
            EndIf
            view = Magelight.FindView("PlayerSignals", "wheel")
            If token == _generation && view != 0
                Magelight.ShowView(view, False)
            EndIf
        EndIf
    EndIf
    Return selected
EndFunction

Function Report(String details)
    Debug.Trace("[PlayerSignals] " + details, 2)
    Debug.Notification("PlayerSignals: " + details)
EndFunction
