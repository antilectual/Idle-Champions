GUIFunctions.AddTab("AreaSwapper")

global g_AreaSwapperSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\Settings.json" )
if !IsObject(g_AreaSwapperSettings)
    g_AreaSwapperSettings := {}

Gui, ICScriptHub:Tab, AreaSwapper
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y80, AreaSwapper
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, Swap forward/backward between two areas

if ( g_AreaSwapperSettings.SwapDurationSecs == "" )
    g_AreaSwapperSettings.SwapDurationSecs := 60
Gui, ICScriptHub:Add, Text, x15 y+15, Swap after this many seconds:
Gui, ICScriptHub:Add, Edit, vAreaSwapper_SwapDurationSecs x+5 w50, % g_AreaSwapperSettings.SwapDurationSecs
Gui, ICScriptHub:Add, Text, x+5 vAreaSwapper_SwapDurationSecs_Saved w200, % "Saved value: " . g_AreaSwapperSettings.SwapDurationSecs

Gui, ICScriptHub:Add, Button, x15 y+15 w160 gAreaSwapper_Save, Save Settings
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gAreaSwapper_Run, Run
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gAreaSwapper_Stop, Stop

Gui, ICScriptHub:Add, Text, x15 y+10 vAreaSwapper_Status w300,

AreaSwapper_Save() {
    global
    Gui, ICScriptHub:Submit, NoHide

    g_AreaSwapperSettings.SwapDurationSecs := AreaSwapper_SwapDurationSecs
    GuiControl, ICScriptHub:, AreaSwapper_SwapDurationSecs_Saved, % "Saved value: " . g_AreaSwapperSettings.SwapDurationSecs

    g_SF.WriteObjectToJSON(A_LineFile . "\..\Settings.json" , g_AreaSwapperSettings)
}

global g_AreaSwapper := new AreaSwapper()
AreaSwapper_Run() {
    ; initialize shared functions for directed inputs
    g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
    g_SF.Memory.OpenProcessReader()

    g_AreaSwapper.Run(g_AreaSwapperSettings.SwapDurationSecs)
}

AreaSwapper_Stop() {
    if (g_AreaSwapper.IsRunning() == False) {
        MsgBox Area Swapper isn't running
        return
    }
    g_AreaSwapper.Stop()
}

class AreaSwapper {

    swapSecs := 0
    stopping := False
    running := False

    IsRunning() {
        return this.running
    }

    Run(swapSecs) {
        this.swapSecs := swapSecs
        this.running := True

        GuiControl, ICScriptHub:, AreaSwapper_Status, % "Running Area Swapper; Swapping every " this.swapSecs " seconds"
        this.doTimedFarm()
    }

    Stop() {
        this.stopping := True
        GuiControl, ICScriptHub:, AreaSwapper_Status, Area Swapper Stopping
    }

    doTimedFarm()  {
        toggle := 0
        loop {
            input := toggle = 1 ? ( "{Left}", toggle := 0) : ( "{Right}", toggle := 1)
            g_SF.DirectedInput(,,input)
            Loop, % this.swapSecs { ; number of seconds to sleep
                if (this.stopping == True) {
                    this.stopping := False
                    this.running := False
                    GuiControl, ICScriptHub:, AreaSwapper_Status, Area Swapper Stopped
                    return
                }
                Sleep, 1000
            }
        }
    }
}
