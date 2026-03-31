class IC_BrivGemFarm_CloseWelcomeBack_TimerScript
{
    TimerFunctions := ""

    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer :=  ObjBindMethod(this, "CloseWelcomeBack")
        this.TimerFunctions[fncToCallOnTimer] := 3000 ; every 3 seconds
    }

    StartTimedFunctions()
    {
        for func,timer in this.TimerFunctions
        {
            SetTimer, %func%, %timer%, 0
        }
    }

    StopTimedFunctions()
    {
        for func,timer in this.TimerFunctions
        {
            SetTimer, %func%, Off ; Off tells the function to stop repeating.
            SetTimer, %func%, Delete ; Delete removes the timer from the functions AHK is calling on timers.
        }
    }

    CloseWelcomeBack() 
    {
        if (g_SF.Memory.ReadWelcomeBackActive()) {
            g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
            g_SF.DirectedInput(,,"{Esc}")
            Loop 100 { ; active tasks will appear after we close welcome back - wait for it then close it
                if (this.IsActiveTasksVisible()) {
                    break
                }
                Sleep, 100 ; wait 100ms, looping 100 times = 10 seconds total max
            }
        }
        this.CloseActiveTasks()
    }

    IsActiveTasksVisible()
    {
        dialogSlot := g_SF.Memory.GetDialogSlotByName("ActiveTasksDialog")
        if (dialogSlot != "" && g_SF.Memory.ReadDialogActiveBySlot(dialogSlot)) {
            Return, True
        }
        Return, False
    }
    
    CloseActiveTasks()
    {
        if (this.IsActiveTasksVisible()) {
            g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
            g_SF.DirectedInput(,,"{Esc}")
        }
    }
}
