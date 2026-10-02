Scriptname PlayerSignals_Controller extends Quest

String _path = "Data/SKSE/Plugins/PlayerSignals/layout.json"
Int _config = 0
Int _key = 0
Int _generation = 0
Bool _ready = False
Bool _browsing = False
Bool _held = False
Bool _maintaining = False

; Invalidate before the startup delay, including a suspended menu wait from a save.
Function ScheduleMaintenance(Float delay)
    _generation += 1
    _ready = False
    _browsing = False
    _held = False
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
    If Game.GetModByName("UIExtensions.esp") == 255
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
    If token == _generation
        _browsing = False
    EndIf
EndEvent

Function Submit(String narration, String feedbackPrefix, String feedbackSuffix, Actor player, Actor recipient, Bool targeted, Int token)
    Actor speaker = player
    Actor listener = None
    String failure = ""
    If targeted
        If recipient
            speaker = recipient
            listener = player
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
    Int result = SkyrimNetApi.DirectNarration(narration, speaker, listener)
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
            If i < JArray.count(slots)
                If JArray.valueType(slots, i) == 5
                    Int entry = JArray.getObj(slots, i)
                    label = JMap.getStr(entry, "label")
                    enabled = True
                EndIf
            EndIf
            menu.SetPropertyIndexString("optionText", i, label)
            menu.SetPropertyIndexString("optionLabelText", i, label)
            menu.SetPropertyIndexBool("optionEnabled", i, enabled)
            i += 1
        EndWhile
        If token != _generation || !_ready
            Return ""
        EndIf
        Int selected = menu.OpenMenu(player)
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

Function Report(String details)
    Debug.Trace("[PlayerSignals] " + details, 2)
    Debug.Notification("PlayerSignals: " + details)
EndFunction
