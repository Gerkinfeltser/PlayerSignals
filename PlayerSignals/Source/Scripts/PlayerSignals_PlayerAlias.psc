Scriptname PlayerSignals_PlayerAlias extends ReferenceAlias

Event OnInit()
    PlayerSignals_Controller controller = GetOwningQuest() as PlayerSignals_Controller
    If controller
        controller.ScheduleMaintenance(2.0)
    Else
        Debug.Trace("[PlayerSignals] Missing controller on owning quest", 2)
    EndIf
EndEvent

Event OnPlayerLoadGame()
    PlayerSignals_Controller controller = GetOwningQuest() as PlayerSignals_Controller
    If controller
        controller.ScheduleMaintenance(0.5)
    Else
        Debug.Trace("[PlayerSignals] Missing controller on owning quest", 2)
    EndIf
EndEvent
