#include %A_LineFile%\..\IC_AreaTiming_GUI.ahk
#include %A_LineFile%\..\Data\IC_AreaTiming_RunCollection.ahk
#include %A_LineFile%\..\Data\IC_AreaTiming_SharedData.ahk

global g_AreaTimingGui := new IC_AreaTiming_GUI
global g_AreaTiming := new IC_AreaTiming_Component
OnExit(ObjBindMethod(g_AreaTimingGui, "Close"), -1)

/*  IC_AreaTiming_Component

    Class that manages the GUI for area timing.
    Based on IC_BrivGemFarm_Stats_Functions.ahk.
*/
Class IC_AreaTiming_Component
{
    ; File locations
    static SettingsPath := A_LineFile . "\..\AreaTiming_Settings.json"
    static LastGUIDPath := A_LineFile . "\..\LastGUID_AreaTiming.json"
    static MiniscriptsPath := A_LineFile . "\..\..\IC_BrivGemFarm_Performance\LastGUID_Miniscripts.json"
    static TimerScriptFileName := "IC_AreaTiming_TimerScript_Run.ahk"
    ; Constants (might differ depending on game version)
    static CAPPED_GAMESPEED := 10

    Settings := ""
    TimerFunctions := ""
    TimerScriptGUID := ""
    TimerScriptLoc := ""
    FirstSessionID := 0
    TotalSessions := 0
    FirstRunID := 0
    TotalRuns := 0
    Session := ""
    Run := ""
    RunEnded := false
    LastSelectRunText := ""

    __New()
    {
        this.GetTimerScriptLoc()
        ; Read settings
        this.Settings := settings := g_SF.LoadObjectFromJSON(this.SettingsPath)
        if (!IsObject(settings))
        {
            settings := this.GetDefaultSettings()
            this.Settings := settings
            this.SaveSettings()
        }
        ; Set the state of GUI buttons with saved settings.
        GuiControl, ICScriptHub:, AreaTimingBGFSync, % settings.BrivGemFarmSync
        GuiControl, ICScriptHub:, AreaTimingUncappedSpeed, % settings.ShowUncappedGameSpeed
        GuiControl, ICScriptHub:, AT_ExcludeMod50Outliers, % settings.ExcludeMod50Outliers
        this.BGFSync(settings.BrivGemFarmSync)
        ; Try to reconnect if the timer script was already launched.
        this.UpdateLastGUID()
        this.CreateTimedFunctions()
        for k, v in this.TimerFunctions
            SetTimer, %k%, %v%, 0
    }

    GetTimerScriptLoc()
    {
        split := StrSplit(A_LineFile, "\")
        root := SubStr(A_LineFile, 1, StrLen(A_LineFile) - StrLen(split[split.Length()]))
        this.TimerScriptLoc := root . this.TimerScriptFileName
    }

    ; Returns an object with default values for all settings.
    GetDefaultSettings()
    {
        settings := {}
        settings.BrivGemFarmSync := false
        settings.ShowUncappedGameSpeed := false
        settings.ExcludeMod50Outliers := true
        return settings
    }

    ; Save the addon settings to the settings file.
    SaveSettings()
    {
        g_SF.WriteObjectToJSON(this.SettingsPath, this.Settings)
    }

    ; Add timed functions to be run when BrivGemFarm_Run is started.
    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer := ObjBindMethod(this, "Update")
        this.TimerFunctions[fncToCallOnTimer] := 1000
    }

    Start()
    {
        this.StartTimerScript()
        for k, v in this.TimerFunctions
            SetTimer, %k%, %v%, 0
    }

    ; Synchronise start/stop buttons with the buttons in the Briv Gem Farm tab.
    ; Parameters: - sync:bool - If true, start/stop the timer script when
    ;               the buttons are clicked in the BrivGemFarm tab.
    ;               If false, remove the script from the Miniscripts list.
    BGFSync(sync)
    {
        static boundStart := ""
        static boundStop := ""

        this.Settings.BrivGemFarmSync := sync
        this.SaveSettings()
        if(IsObject(IC_BrivGemFarm_Component))
        {
            if (sync)
            {
                boundStart := ObjBindMethod(this, "Start")
                boundStop := ObjBindMethod(this, "StopFromBrivGemFarmStop")
                g_BrivFarmAddonStartFunctions.Push(boundStart)
                g_BrivFarmAddonStopFunctions.Push(boundStop)
                this.AddScriptToMiniscripts()
            }
            else
            {
                this.DeleteScriptFromMiniscripts()
                ; Remove button sync
                for k, v in g_BrivFarmAddonStartFunctions
                    if (v == boundStart)
                        g_BrivFarmAddonStartFunctions.Delete(k)
                for k, v in g_BrivFarmAddonStopFunctions
                    if (v == boundStop)
                        g_BrivFarmAddonStopFunctions.Delete(k)
                boundStart := boundStop := ""
            }
        }
    }

    ; Show uncapped timescale multiplier (for speeds over x10).
    ; Params: - capped:bool - If true, show uncapped speed, else up to 10x.
    ToggleUncappedGameSpeed(capped)
    {
        this.Settings.ShowUncappedGameSpeed := capped
        this.SaveSettings()
        ; Reload view.
        this.LoadRun(,, true)
    }

    ; Checkbox to show mod50 values with or without outliers.
    ; Params: - exclude:bool - If true, filter out z1, stack zone and reset area.
    ToggleExcludeMod50Outliers(exclude)
    {
        this.Settings.ExcludeMod50Outliers := exclude
        this.SaveSettings()
        ; Reload view.
        this.LoadRun(,, true)
    }

    ; Returns the COM object associated to the timer script's shared data class.
    TimerScript
    {
        get
        {
            try
            {
                return ComObjActive(this.TimerScriptGUID)
            }
            catch
            {
                return ""
            }
        }
    }

    IsTimerScriptRunning()
    {
        return this.GetScriptPID(this.TimerScriptFileName)
    }

    ; Returns the PID from an ahk script.
    ; Params: - ScriptName:str - Name of the script.
    GetScriptPID(ScriptName)
    {
        DHW := A_DetectHiddenWindows
        TMM := A_TitleMatchMode
        DetectHiddenWindows, On
        SetTitleMatchMode, 2
        WinGet, PID, PID, \%ScriptName% - ahk_class AutoHotkey
        DetectHiddenWindows, %DHW%
        SetTitleMatchMode, %TMM%
        Return PID
    }

    ; If not found, launch a new instance of the timer script.
    StartTimerScript()
    {
        if (this.IsTimerScriptRunning())
        {
            if(this.UpdateLastGUID() == "")
            {
                this.Stop()
                this.StartTimerScript()
            }
            else
            {
                try
                {
                    sharedData := this.TimerScript
                    sharedData.Start()
                }
            }
        }
        else
        {
            this.AddScriptToMiniscripts()
            ; Start the script
            scriptLocation := this.TimerScriptLoc
            guid := this.TimerScriptGUID
            Run, %scriptLocation% %guid%
        }
    }

    ; Retrieve the saved GUID of the timer script in the Miniscripts file.
    ; If not found, use the GUID saved in the LastGUID_AreaTiming.json file.
    UpdateLastGUID()
    {
        miniscripts := g_SF.LoadObjectFromJSON(this.MiniscriptsPath)
        for k, v in miniscripts
        {
            if (InStr(v, this.TimerScriptFileName))
            {
                this.TimerScriptGUID := k
                g_Miniscripts[k] := v
                return k
            }
        }
        ; GUID not found in miniscripts.
        guid := this.GetLastGUID()
        if (guid != "")
        {
            this.TimerScriptGUID := guid
            if (this.Settings.BrivGemFarmSync)
            {
                g_Miniscripts[guid] := this.TimerScriptLoc
                g_SF.WriteObjectToJSON(this.MiniscriptsPath, g_Miniscripts)
            }
        }
        return guid
    }

    ; Returns the saved GUID of the timer script in this addons folder.
    ; Should be the same as the one in the Miniscripts file except for edge cases.
    GetLastGUID()
    {
        settings := g_SF.LoadObjectFromJSON(this.LastGUIDPath)
        return settings.GUID_IC_AreaTiming_TimerScript_Run
    }

    ; Add this script's GUID to the Miniscripts file.
    AddScriptToMiniscripts()
    {
        ; Delete previous GUID
        this.DeleteScriptFromMiniscripts()
        if (this.IsTimerScriptRunning())
            guid := this.GetLastGUID()
        if (guid == "")
        {
            ; Create unique identifier (GUID) for the addon to be used by Script Hub.
            this.TimerScriptGUID := guid := ComObjCreate("Scriptlet.TypeLib").Guid
            obj := {GUID_IC_AreaTiming_TimerScript_Run:guid}
            g_SF.WriteObjectToJSON(this.LastGUIDPath, obj)
        }
        if (!this.Settings.BrivGemFarmSync)
            return
        ; Added the script to be run when play is pressed to the list of scripts to be run.
        g_Miniscripts[guid] := this.TimerScriptLoc
        g_SF.WriteObjectToJSON(this.MiniscriptsPath, g_Miniscripts)
    }

    ; Remove this script's GUID from the Miniscripts file.
    DeleteScriptFromMiniscripts()
    {
        for k, v in g_Miniscripts
        {
            if (InStr(v, this.TimerScriptFileName))
                g_Miniscripts.Delete(k)
        }
        g_SF.WriteObjectToJSON(this.MiniscriptsPath, g_Miniscripts)
    }

    Stop()
    {
        for k, v in this.TimerFunctions
        {
            SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        if (this.TimerScript.Running)
        {
            this.Reset()
            this.Update(true)
        }
        ; Remove reference in LastGUID_Miniscripts.json.
        if (!this.Settings.BrivGemFarmSync)
            this.DeleteScriptFromMiniscripts()
    }

    ; Function called when the stop button in the BrivGemFarm tab has been clicked
    ; on. It will prevent the timer script from being closed if the stop button
    ; is clicked on multiple times in a row.
    StopFromBrivGemFarmStop()
    {
        this.Stop()
    }

    ; Reset ListViews / DDLs.
    Reset()
    {
        this.DeleteView("AreaTimingView")
        this.DeleteView("ModAreaTimingView")
        this.DeleteView("StacksAreaTimingView")
        GuiControl, ICScriptHub:, AreaTimingSelectSession, % "| "
        g_AreaTimingGui.UpdateSelectSessionText()
        GuiControl, ICScriptHub:, AreaTimingSelectRun, % "| "
        g_AreaTimingGui.UpdateSelectRunText()
        GuiControl, ICScriptHub:Text, AT_SelectSessionID,
        GuiControl, ICScriptHub:Text, AT_SelectRunID,
        this.FirstSessionID := 0
        this.TotalSessions := 0
        this.FirstRunID := 0
        this.TotalRuns := 0
        this.Session := ""
        this.Run := ""
    }

    DeleteView(controlID)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", controlID)
        LV_Delete()
    }

    ; Close the timer script.
    ; If the saved GUID doesn't match the script GUID, force close.
    CloseTimerScript()
    {
        try
        {
             script := ComObjActive(this.TimerScriptGUID)
             script.Close(true)
        }
        catch
        {
            PID := this.IsTimerScriptRunning()
            if (PID)
                Process, Close, %PID%
        }
        g_AreaTimingGui.UpdateButtons(3)
        this.Reset()
        this.Stop()
    }

    ; Returns true if the script's current session start time matches the input session's start time.
    IsCurrentSession(session := "")
    {
        try
        {
            sharedData := ComObjActive(this.TimerScriptGUID)
            if (session == "")
                session := this.Session
            return session.StartTime == sharedData.CurrentSession.StartTime
        }
    }

    ; Returns true if the script's current run start time matches the input session's start time.
    IsCurrentRun(run := "")
    {
        try
        {
            sharedData := ComObjActive(this.TimerScriptGUID)
            if (run == "")
                run := this.Run
            return run.StartTime == sharedData.CurrentSession.CurrentRun.StartTime
        }
    }

    ; Main update for this addons GUI.
    ; Params: - stop:bool - If true, stop the timer script's loop, then update DDLs.
    Update(stop := false)
    {
        try
        {
            sharedData := ComObjActive(this.TimerScriptGUID)
            if (stop)
                sharedData.Stop()
            running := sharedData.Running
            ; Read sessions
            sessions := sharedData.Sessions
            sessionCount := sessions.Length()
            firstSessionID := sessions[1].ID
            if (!running || this.NewSessionExists(sessionCount, firstSessionID))
            {
                this.TotalSessions := sessionCount
                this.FirstSessionID := firstSessionID
                this.UpdateSelectSession(sessions, running)
            }
            ; Read current session
            session := sharedData.CurrentSession
            runs := session.Runs
            runCount := runs.Length()
            currentRun := session.CurrentRun
            firstID := runs[1].ID
            hasNewRun := runCount != this.TotalRuns || this.FirstRunID != firstID
            if (!running || hasNewRun && firstID != 0 && firstID != "" && runCount != "")
            {
                this.TotalRuns := runCount
                this.FirstRunID := firstID
                ; Update only if the selected session is the same as the session being recorded
                if (this.IsCurrentSession() && running)
                    this.UpdateSelectRun(runs)
                else if (!running)
                    this.UpdateSelectRun(this.Session.runs, false)
            }
            ; Update DDLs on first load.
            if (this.Session == "" && session)
            {
                this.Session := session
                if (this.Run == "" && runs[1])
                    this.Run := runs[1]
                GuiControl, ICScriptHub:Choose, AreaTimingSelectSession, |1
                GuiControl, ICScriptHub:Choose, AreaTimingSelectRun, |1
            }
            ; Stop updating if the timer script is not running.
            if (!running)
            {
                for k, v in this.TimerFunctions
                {
                    SetTimer, %k%, Off
                    SetTimer, %k%, Delete
                }
                g_AreaTimingGui.UpdateButtons(2)
            }
            else
                g_AreaTimingGui.UpdateButtons(1)
        }
        catch
        {
            if (!this.IsTimerScriptRunning())
            {
                this.Reset()
                g_AreaTimingGui.UpdateButtons(3)
            }
            this.UpdateLastGUID()
        }
    }

    ; Returns true when a new session has started.
    ; Params: - count:int - Number of sessions in the shared data object.
    ;         - firstSessionID:int - ID of the first session object.
    NewSessionExists(count, firstSessionID)
    {
        if (firstSessionID == 0 || firstSessionID == "" || count == "")
            return false
        sessionCountDiff := count != this.TotalSessions
        firstSessionIDDiff := firstSessionID != this.FirstSessionID
        return sessionCountDiff || firstSessionIDDiff
    }

    ; Update choices for the "select session" DDL.
    ; Params: - sessions:list - List of sessions.
    ;         - showCurrent:bool - If true, show "Current session" as a choice.
    ; If showCurrent is true, 1:"Current session", 2+:list of sessions.
    ; If showCurrent is false, 1+:list of runs.
    UpdateSelectSession(sessions, showCurrent := true)
    {
        sessionCount := sessions.Length()
        ; Build list of choices with or without current session item
        if (showCurrent)
            choices := "Current session|" . this.GetFormattedTimeStamp(sessions[1].StartTime)
        else
            choices := this.GetFormattedTimeStamp(sessions[1].StartTime)
        Loop, % sessionCount - 1
            choices .= "|" . this.GetFormattedTimeStamp(sessions[A_Index + 1].StartTime)
        ; Remember current selection
        if (showCurrent)
        {
            GuiControlGet, sel, ICScriptHub:, AreaTimingSelectSession
            sel := (sel == "" || sel == 1) ? sessionCount + 1 : Min(sel + 1, sessionCount + 1)
        }
        else
            sel := sessionCount
        ; Update choices
        GuiControl, ICScriptHub:, AreaTimingSelectSession, % "|" . choices
        GuiControl, ICScriptHub:Choose, AreaTimingSelectSession, % sel
        ; Update counter
        this.LoadSession(sel)
    }

    ; Update choices for the "select run" DDL.
    ; Params: - runs:list - List of runs.
    ;         - showCurrent:bool - If true, show "Current run" as a choice.
    ; If showCurrent is true, 1:"All", 2:"Current session", 3+:list of sessions.
    ; If showCurrent is false, 1:"All", 2+:list of runs.
    UpdateSelectRun(runs, showCurrent := true)
    {
        runCount := runs.Length()
        ; Build list of choices with or without current run item
        choices := "All runs" . (showCurrent ? "|Current run" : "")
        Loop, % runCount
            choices .= "|" . this.GetFormattedTimeStamp(runs[A_Index].StartTime)
        ; Remember current selection, default to last run
        if (showCurrent)
        {
            GuiControlGet, sel, ICScriptHub:, AreaTimingSelectRun
            sel := sel == "" || sel == 2 ? runCount + 2 : Min(sel, runCount + 2)
        }
        else ; Default to first run
            sel := 2
        ; Update choices
        GuiControl, ICScriptHub:, AreaTimingSelectRun, % "|" . choices
        if ((ctrlID := g_AreaTimingGui.GetCurrentlyDroppedCombo()) == "")
            GuiControl, ICScriptHub:Choose, AreaTimingSelectRun, % sel
        else
        {
            text := this.LastSelectRunText
            GuiControl, ICScriptHub:ChooseString, AreaTimingSelectRun, % text
            GuiControlGet, hwnd, ICScriptHub:Hwnd, %ctrlID%
            SendMessage, 0x014f, 1, 0,, ahk_id %hwnd% ; CB_SHOWDROPDOWN
            GuiControlGet, runID, ICScriptHub:, AT_SelectRunID
            g_AreaTimingGui.UpdateSelectRunText(runID, runCount)
            return
        }
        ; Update counter
        runID := showCurrent ? Min(sel - 2, runCount) : 1
        runID := (runID < 1 ) ? "-" : runID
        g_AreaTimingGui.UpdateSelectRunText(runID, runCount)
    }

    ; Return a date/time format timestamp.
    ; Params: timestamp:int - Unix epoch time.
    GetFormattedTimeStamp(timestamp)
    {
        mSec := Mod(timestamp, 1000)
        unixTime := Round((timestamp - mSec) / 1000)
        time := this.UnixToUTC(unixTime)
        FormatTime, timeStrDate, % time, ShortDate
        FormatTime, timeStrHHmmss, % time, HH:mm:ss
        return timeStrDate . " " . timeStrHHmmss
    }

    UnixToUTC(unixTime)
    {
        time := 1970
        time += unixTime, s
        return time
    }

    ; Load ListViews with values from the run chosen in the DDL.
    ; Params: - choice:int - List index. If viewing current session,
    ;           index starts at 2, with 1 being the current session.
    ;         - retry:bool - If true, on failure, retry in 30ms.
    ;         - sessionID:int - ID of the session to load (overrides choice).
    LoadSession(choice := 1, retry := true, sessionID := "")
    {
        try
        {
            sharedData := this.TimerScript
            sessions := sharedData.Sessions
            sessionCount := sessions.Length()
            running := sharedData.Running
            if (sessionID > 0)
            {
                session := sessions[sessionID]
                sel := sessionID + running
                GuiControl, ICScriptHub:Choose, AreaTimingSelectSession, % sel
            }
            else if (running)
            {
                session := (choice == 1) ? sharedData.CurrentSession : sessions[choice - 1]
                sessionID := (choice == 1) ? sessionCount : choice - 1
            }
            else
            {
                session := sessions[choice]
                sessionID := choice
            }
            g_AreaTimingGui.UpdateSelectSessionText(sessionID, sessionCount)
            ; Update only if another session has been chosen.
            if (session.StartTime != this.Session.StartTime)
            {
                g_AreaTimingGui.ToggleSelection(false)
                this.Session := session
                ; Load runs
                showCurrent := running && sharedData.CurrentSession.ID == session.ID
                this.UpdateSelectRun(session.Runs, showCurrent)
                this.LoadRun(, false)
            }
        }
        catch
        {
            ; Retry once if the COM object is busy.
            if (retry)
            {
                params := [choice, false]
                func := ObjBindMethod(this, "RetryLoadSession", params*)
                SetTimer, %func%, -30
            }
        }
        g_AreaTimingGui.ToggleSelection(true)
    }

    RetryLoadSession(params*)
    {
        this.LoadSession(params*)
    }

    ; Load ListViews with values from the run chosen in the DDL.
    ; Params: - choice:int - List index. If viewing current session,
    ;           index starts at 2, with 1 being the current run.
    ;         - retry:bool - If true, on failure, retry in 30ms.
    ;         - reload:bool - If true, reload currently selected run.
    ;         - runID:int - ID of the run to load (overrides choice).
    LoadRun(choice := 2, retry := true, reload := false, runID := "")
    {
        try
        {
            session := this.Session
            if (session.StartTime == "")
                return
            sharedData := this.TimerScript
            isCurrentSession := this.IsCurrentSession()
            runs := session.Runs
            runCount := runs.Length()
            running := sharedData.Running
            if (runID > 0)
            {
                run := runs[runID]
                sel := runID + 1 + (running && isCurrentSession)
                GuiControl, ICScriptHub:Choose, AreaTimingSelectRun, % sel
            }
            ; All runs
            else if (choice == 1)
            {
                g_AreaTimingGui.ToggleSelection(false)
                this.Run := ""
                this.LastSelectRunText := "All"
                g_AreaTimingGui.UpdateSelectRunText("-", runCount)
                this.UpdateListViews(session)
                return g_AreaTimingGui.ToggleSelection(true)
            }
            else if (reload)
            {
                run := this.Run
                if (run == "")
                    return this.LoadRun(1,, true)
            }
            else if (running && isCurrentSession)
                run := (choice == 2) ? session.CurrentRun : runs[choice - 2]
            else
                run := runs[choice - 1]
            runID := run.ID
            ; Update only if another run has been chosen or run is not finished.
            if (reload || run.StartTime != this.Run.StartTime || running && !this.RunEnded && isCurrentSession)
            {
                g_AreaTimingGui.ToggleSelection(false)
                this.Run := run
                this.RunEnded := run.Ended
                if (!reload)
                    g_AreaTimingGui.UpdateSelectRunText(runID, runCount)
                this.UpdateListViews(session, run)
            }
            else
                g_AreaTimingGui.UpdateSelectRunText(runID, runCount)
        }
        catch
        {
            ; Retry once if the COM object is busy.
            if (retry)
            {
                params := [choice, false]
                func := ObjBindMethod(this, "RetryLoadRun", params*)
                SetTimer, %func%, -30
            }
        }
        ; Remember current selection
        GuiControlGet, sel, ICScriptHub:, AreaTimingSelectRun, Text
        this.LastSelectRunText := sel
        g_AreaTimingGui.ToggleSelection(true)
    }

    RetryLoadRun(params*)
    {
        this.LoadRun(params*)
    }

    ; Update the currently active ListView.
    UpdateListViews(session := "", run := "")
    {
        if (session == "")
            return this.UpdateListViews(this.Session, this.Run)
        controlID := g_AreaTimingGui.CurrentView
        if (controlID == "AreaTimingView")
            this.UpdateRunGUI(session, run)
        else if (controlID == "ModAreaTimingView")
            this.UpdateMod50GUI(session, run)
        else if (controlID == "StacksAreaTimingView")
            this.UpdateStacksGUI(session, run)
    }

    ; Function that updates the AreaTiming GUI.
    ; Area|Next|T_area|T_tran|T_time|AvgT_area|AvgT_tran|AvgT_time|T_run|AvgT_run|Count|Game speed|AvgGame speed
    ; Area|Next|AvgT_area|AvgT_tran|AvgT_time|AvgT_run|CountGame speed|AvgGame speed (All)
    UpdateRunGUI(session, run := "")
    {
        data := []
        isAll := !IsObject(run)
        if (isAll)
        {
            totals := session.GetAllTotals()
            keys := totals[1]
            items := totals[2]
            Loop, % keys.Length()
            {
                key := keys[A_Index]
                area := key >> 16
                next := key & 0xFFFF
                ; Average
                total := items[A_Index]
                count := total[1]
                avgAreaTime := this.FormatMilliSToS(total[2] / count)
                avgTransitionTime := this.FormatMilliSToS(total[3] / count)
                avgTime := this.FormatMilliSToS(total[4] / count)
                avgRunTime := this.FormatMilliSToS(total[5] / count)
                avgGameSpeed := this.FormatGameSpeed(total[6] / count)
                data.Push([area, next, avgAreaTime, avgTransitionTime, avgTime, avgRunTime, count, avgGameSpeed])
            }
        }
        else
        {
            totals := session.GetAllTotals(run)
            keys := totals[1]
            items := totals[2]
            runTime := 0
            runItems := run.Items
            Loop, % items.Length()
            {
                key := keys[A_Index]
                area := key >> 16
                next := key & 0xFFFF
                areaTime := this.FormatMilliSToS(run.GetItemAreaTime(A_Index))
                transitionTime := this.FormatMilliSToS(run.GetItemTransitionTime(A_Index))
                time := this.FormatMilliSToS(run.GetItemTotalTime(A_Index))
                runTime += run.GetItemTotalTime(A_Index)
                runTimeRounded := this.FormatMilliSToS(runTime)
                gameSpeed := this.FormatGameSpeed(run.GetItemGameSpeed(A_Index))
                HStacks := run.GetItemHStacks(A_Index)
                SBStacks := run.GetItemSBStacks(A_Index)
                ; Average
                total := items[A_Index]
                count := total[1]
                avgAreaTime := this.FormatMilliSToS(total[2] / count)
                avgTransitionTime := this.FormatMilliSToS(total[3] / count)
                avgTime := this.FormatMilliSToS(total[4] / count)
                avgRunTime := this.FormatMilliSToS(total[5] / count)
                avgGameSpeed := this.FormatGameSpeed(total[6] / count)
                data.Push([area, next, areaTime, transitionTime, time, avgAreaTime, avgTransitionTime, avgTime, runTimeRounded, avgRunTime, count, gameSpeed, avgGameSpeed, HStacks, SBStacks])
            }
        }
        g_AreaTimingGui.UpdateListView("AreaTimingView", data, isAll)
    }

    ; Function that updates the AreaTiming Mod50 GUI.
    ; Area|Next|T_area|T_tran|T_time|AvgT_area|AvgT_tran|AvgT_time|Count
    ; Area|Next|AvgT_area|AvgT_tran|AvgT_time|Count (All)
    UpdateMod50GUI(session, run := "")
    {
        data := []
        isAll := !IsObject(run)
        excludeOutliers := this.Settings.ExcludeMod50Outliers
        keys := session.GetAllMod50ItemKeys()
        Loop, % keys.Length()
        {
            key := keys[A_Index]
            area := key >> 16
            next := key & 0xFFFF
            if (isAll)
            {
                ; Average
                totals := session.GetTotalsMod50(key,, excludeOutliers)
                count := totals[1]
                if (count == 0)
                    continue
                avgAreaTime := this.FormatMilliSToS(totals[2] / count)
                avgTransitionTime := this.FormatMilliSToS(totals[3] / count)
                avgTime := this.FormatMilliSToS(totals[4] / count)
                data.Push([area, next, avgAreaTime, avgTransitionTime, avgTime, count])
            }
            else
            {
                ; Run average
                totals := session.GetTotalsMod50(key, [run], excludeOutliers)
                countRun := totals[1]
                if (countRun == 0)
                    continue
                areaTime := this.FormatMilliSToS(totals[2] / countRun)
                transitionTime := this.FormatMilliSToS(totals[3] / countRun)
                time := this.FormatMilliSToS(totals[4] / countRun)
                ; Session average
                totals := session.GetTotalsMod50(key,, excludeOutliers)
                count := totals[1]
                avgAreaTime := this.FormatMilliSToS(totals[2] / count)
                avgTransitionTime := this.FormatMilliSToS(totals[3] / count)
                avgTime := this.FormatMilliSToS(totals[4] / count)
                data.Push([area, next, areaTime, transitionTime, time, countRun, avgAreaTime, avgTransitionTime, avgTime, count])
            }
        }
        g_AreaTimingGui.UpdateListView("ModAreaTimingView", data, isAll)
    }

    ; Function that updates the AreaTiming Stacks GUI.
    ; Area|Next|T_time|AvgT_Time|Stacks|AvgStacks|Count|Stacks/s|AvgStacks/s|Jumps/s|AvgJumps/s|Game speed
    ; Run ID|Area|Next|T_time|AvgT_Time|Stacks|AvgStacks|Count|Stacks/s|AvgStacks/s|Jumps/s|AvgJumps/s|Game speed (All)
    UpdateStacksGUI(session, run := "")
    {
        data := []
        isAll := !IsObject(run)
        runs := isAll ? session.Runs : [run]
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            Loop, % run.StackItems.Length()
            {
                area := run.GetStackItemStartZone(A_Index)
                next := run.GetStackItemEndZone(A_Index)
                time := run.GetStackItemTotalTime(A_Index)
                ; Average
                totals := session.GetTotalsStack(run.GetStackItemZones(A_Index))
                count := totals[1]
                averageTime := totals[4] / count
                stacks := run.GetStackItemStacks(A_Index)
                averageStacks := Round(totals[7] / count)
                rate := Round(1000 * stacks / time)
                averageRate := Round(1000 * averageStacks / averageTime)
                jumpEqRate := Round((1000 * this.GetJumpsFromStacks(stacks) / time), 2)
                averageJumpEqRate := Round((1000 * this.GetJumpsFromStacks(averageStacks) / averageTime), 2)
                gameSpeed := this.FormatGameSpeed(run.GetStackItemGameSpeed(A_Index))
                if (isAll)
                    data.Push([run.ID, area, next, this.FormatMilliSToS(time), this.FormatMilliSToS(averageTime), stacks, averageStacks, count, rate, averageRate, jumpEqRate, averageJumpEqRate, gameSpeed])
                else
                    data.Push([area, next, this.FormatMilliSToS(time), this.FormatMilliSToS(averageTime), stacks, averageStacks, count, rate, averageRate, jumpEqRate, averageJumpEqRate, gameSpeed])
            }
        }
        g_AreaTimingGui.UpdateListView("StacksAreaTimingView", data, isAll)
    }

    FormatMilliSToS(time, decimals := 2)
    {
        return Round(time / 1000, decimals)
    }

    FormatGameSpeed(speed, decimals := 3, uncapped := "")
    {
        if (uncapped == "")
            uncapped := this.Settings.ShowUncappedGameSpeed
        return Round(uncapped ? speed : Min(speed, this.CAPPED_GAMESPEED), decimals)
    }

    ; Compute the number of Briv jumps from a number stacks (Metalborn active).
    ; Params: stacks:int - Number of Briv Haste stacks.
    ; Returns: - jumps:int - Maximum number of jumps.
    GetJumpsFromStacks(stacks)
    {
        while (stacks >= 50)
        {
            ++jumps
            stacks := Round(stacks * 0.968)
        }
        return jumps
    }
}