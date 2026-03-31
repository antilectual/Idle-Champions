class IC_Oi_IC_CloseNow_ImWarningYou_SharedFunctions_Class extends IC_SharedFunctions_Class 
{
    ;===================================
    ;Functions for closing or opening IC
    ;===================================
    ;A function that closes IC. If IC takes longer than 60 seconds to save and close then the script will force it closed.
    CloseIC( string := "" )
    {
        g_SharedData.LastCloseReason := string
        ; check that server call object is updated before closing IC in case any server calls need to be made
        ; by the script before the game restarts
        this.ResetServerCall()
        if ( string != "" )
            string := ": " . string
        g_SharedData.LoopString := "Closing IC" . string
        ahkIcId := "ahk_exe " . g_userSettings["ExeName"]
        pid := g_SF.PID
        if (!pid) {
            Process, Exist, % g_userSettings["ExeName"]
            pid := ErrorLevel
        }       
        hwnd := WinExist( ahkIcId )
        if (hwnd) {
            SendMessage, 0x112, 0xF060,,, %ahkIcId%,,,, 10000 ; WinClose
            ; WinGet, pid, PID, ahk_id %hwnd% ; get PID in case we need it
        }
        StartTime := A_TickCount
        ElapsedTime := 0
        while ( WinExist( ahkIcId ) AND pid )
        {
            if (ElapsedTime < 10000) {
                Sleep, 200
            } else if (ElapsedTime < 30000) {
                WinKill
                Sleep, 10 ; Not too slow in case spamming WinKill actually helps like in original code
            } else if (ElapsedTime < 40000) {
                Process, Close, %pid%
                Sleep, 1000
            } else if (ElapsedTime < 50000) {
                hProc := DllCall("OpenProcess", "UInt", 1, "Int", 0, "UInt", pid, "Ptr")
                if (hProc)
                {
                    DllCall("TerminateProcess", "Ptr", hProc, "UInt", 0)
                    DllCall("CloseHandle", "Ptr", hProc)
                }
                Sleep, 1000
            } else {
                ; POP UP AN ERROR AND BREAK
                Sleep, 1000
            }
            ElapsedTime := A_TickCount - StartTime
        }
        return
    }

	InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_Oi_IC_CloseNow_ImWarningYou_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }
}