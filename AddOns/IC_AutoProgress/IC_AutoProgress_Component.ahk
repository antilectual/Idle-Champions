GUIFunctions.AddTab("AutoProgress")

Gui, ICScriptHub:Tab, AutoProgress
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y80, AutoProgress
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, Auto Progress

Gui, ICScriptHub:Add, Button, x15 y+10 w160 gAutoProgress_Run, Run
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gAutoProgress_Stop, Stop

Gui, ICScriptHub:Add, Text, x15 y+10 vAutoProgress_Status w300,

global g_autoProgress := new AutoProgress()
AutoProgress_Run() {
    if (g_autoProgress.IsRunning() == True) {
        MsgBox AutoProgress already running
        return
    }

    ; initialize shared functions for memory reads and directed inputs
    g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName" ])
    g_SF.Memory.OpenProcessReader()

    g_autoProgress.Run()
}

AutoProgress_Stop() {
    if (g_autoProgress.IsRunning() == False) {
        MsgBox AutoProgress isn't running
        return
    }
    g_autoProgress.Stop()
}

class AutoProgress {

    running := false

    IsRunning() {
        return this.running
    }

    Run() {
        this.running := true
        GuiControl, ICScriptHub:, AutoProgress_Status, AutoProgress Started
        loop {
            ; IsToggled be 0 for off or 1 for on. ForceToggle always hits G. ForceState will press G until AutoProgress is read as on (<5s).
            g_SF.ToggleAutoProgress(1)
            Sleep, 100
            if (this.running == false) {
                return
            }
        }
    }

    Stop() {
        this.running := false
        GuiControl, ICScriptHub:, AutoProgress_Status, AutoProgress Stopped
    }
}
