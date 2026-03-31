GUIFunctions.AddTab("Area Timing")

; Recording
Gui, ICScriptHub:Tab, Area Timing
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, Section y+10 vRecordingText, Recording:
Gui, ICScriptHub:Font, w400
GuiControlGet, xAlign, ICScriptHub:Pos, RecordingText
Gui, ICScriptHub:Add, Button, x+10 yp-4 vAreaTimingStart gAreaTimingStart, Start
Gui, ICScriptHub:Add, Button, x+10 vAreaTimingStop gAreaTimingStop, Stop
Gui, ICScriptHub:Add, Button, x+10 vAreaTimingClose gAreaTimingClose, Close
Gui, ICScriptHub:Add, Checkbox, x+10 yp+5 vAreaTimingBGFSync gAreaTimingBGFSync, Start/stop along with BrivGemFarm

; Select session
ctrlH:= 21
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, xs+%xAlign% y+20 h%ctrlH% 0x200 vAreaTimingSelectSessionText, Session:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, DropDownList, x+10 AltSubmit vAreaTimingSelectSession gAreaTimingSelectSession
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, x+1 w55 h%ctrlH% 0x200 Right vAT_SelectSessionID gAT_SelectSessionID
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, UpDown, Left Range0-0 Wrap vAT_SelectSessionUpDown
Gui, ICScriptHub:Add, Text, x+0 yp-1 w55 h%ctrlH% 0x200 vAT_SelectSessionIDText
GuiControl, ICScriptHub:Text, AT_SelectSessionID,

; Select run
GuiControlGet, pos, ICScriptHub:Pos, AreaTimingSelectSession
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, xs+%xAlign% y+5 h%ctrlH% 0x200 vAreaTimingSelectRunText, Run:
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, DropDownList, x%posX% yp AltSubmit vAreaTimingSelectRun gAreaTimingSelectRun
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, x+1 w55 h%ctrlH% 0x200 Right vAT_SelectRunID gAT_SelectRunID
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, UpDown, Left Range0-0 Wrap vAT_SelectRunUpDown
Gui, ICScriptHub:Add, Text, x+0 yp-1 w55 h%ctrlH% 0x200 vAT_SelectRunIDText
GuiControl, ICScriptHub:Text, AT_SelectRunID,

Gui, ICScriptHub:Add, Radio, xs+%xAlign% y+10 h26 vAreaTimingShowAllAreas gAreaTimingShow, % "All areas  "
Gui, ICScriptHub:Add, Radio, x+0 h26 vAreaTimingShowMod50 gAreaTimingShow, % "Mod50  "
Gui, ICScriptHub:Add, Radio, x+0 h26 vAreaTimingShowStacks gAreaTimingShow, % "Stacks  "
Gui, ICScriptHub:Add, Checkbox, x+10 yp+6 vAreaTimingUncappedSpeed gAreaTimingUncappedSpeed, Show uncapped game speed

; Listviews
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, Section xs+%xAlign% y+10 vAreaTimingViewHeader, Run:
Gui, ICScriptHub:Font, w400

GUIFunctions.UseThemeTextColor("TableTextColor")
Gui, ICScriptHub:Add, ListView, AltSubmit R25 xs+%xAlign% y+10 w475 vAreaTimingView gAreaTimingView
GUIFunctions.UseThemeListViewBackgroundColor("AreaTimingView")

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, xs+%xAlign% ys vModAreaTimingViewHeader, Mod 50
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Checkbox, x+10 vAT_ExcludeMod50Outliers gAT_ExcludeMod50Outliers, Excluding area 1, offline stack area and reset

GUIFunctions.UseThemeTextColor("TableTextColor")
Gui, ICScriptHub:Add, ListView, AltSubmit R8 xs+%xAlign% y+10 w475 vModAreaTimingView gModAreaTimingView
GUIFunctions.UseThemeListViewBackgroundColor("ModAreaTimingView")

Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, xs+%xAlign% ys vStacksAreaTimingViewHeader, Stacks:
Gui, ICScriptHub:Font, w400

GUIFunctions.UseThemeTextColor("TableTextColor")
Gui, ICScriptHub:Add, ListView, AltSubmit R2 xs+%xAlign% y+10 w475 vStacksAreaTimingView gStacksAreaTimingView
GUIFunctions.UseThemeListViewBackgroundColor("StacksAreaTimingView")

; Resize events
; WM_ENTERSIZEMOVE := 0x0231
; WM_EXITSIZEMOVE := 0x0232
OnMessage(0x0231, Func("AreaTiming_CheckResizeEvent").Bind(0x0231))
OnMessage(0x0232, Func("AreaTiming_CheckResizeEvent").Bind(0x0232))

AreaTiming_CheckResizeEvent(WM)
{
    g_AreaTimingGui.CheckResizeEvent(WM)
}

AreaTiming_DoResizeEvent()
{
    g_AreaTimingGui.DoResizeEvent()
}

; Start button
AreaTimingStart()
{
    g_AreaTiming.Start()
}

; Stop button
AreaTimingStop()
{
    g_AreaTiming.Stop()
}

; Close button
AreaTimingClose()
{
    g_AreaTiming.CloseTimerScript()
}

; Synchronise start/stop buttons with the buttons in the Briv Gem Farm tab.
AreaTimingBGFSync()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_AreaTiming.BGFSync(value)
}

; Select session dropdown
AreaTimingSelectSession()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_AreaTiming.LoadSession(value)
}

; Select run dropdown
AreaTimingSelectRun()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_AreaTiming.LoadRun(value)
}

; Select session edit
AT_SelectSessionID()
{
    global
    local beforeSubmit := % %A_GuiControl%
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    if (value == "" || value == 0)
        return
    if value is not digit
        return AT_Undo(A_GuiControl)
    if (beforeSubmit == value)
        return
    g_AreaTiming.LoadSession(,,value)
}

; Select run edit
AT_SelectRunID()
{
    global
    local beforeSubmit := % %A_GuiControl%
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    if (value == "" || value == 0)
        return
    if value is not digit
        return AT_Undo(A_GuiControl)
    if (beforeSubmit == value)
        return
    g_AreaTiming.LoadRun(,,,value)
}

; Checkbox to show or hide uncapped timescale.
AreaTimingUncappedSpeed()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_AreaTiming.ToggleUncappedGameSpeed(value)
}

; Checkbox to show mod50 values with or without outliers
AT_ExcludeMod50Outliers()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_AreaTiming.ToggleExcludeMod50Outliers(value)
}

AreaTimingShow()
{
    global
    local beforeSubmit := % %A_GuiControl%
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    if (beforeSubmit == value)
        return
    g_AreaTimingGui.ShowListView(A_GuiControl)
    g_AreaTiming.UpdateListViews()
}

AreaTimingView()
{
    g_AreaTimingGui.ListViewEvent("AreaTimingView")
}

ModAreaTimingView()
{
    g_AreaTimingGui.ListViewEvent("ModAreaTimingView")
}

StacksAreaTimingView()
{
    g_AreaTimingGui.ListViewEvent("StacksAreaTimingView")
}

; Resize window to trigger automatic resize
AT_RefreshSize()
{
    Gui, ICScriptHub:Show, % "w" . g_TabControlWidth . " h" . (g_TabControlHeight + 1) . " NA"
    Sleep, 100
    g_AreaTimingGui.DoResizeEvent()
    Gui, ICScriptHub:Show, % "w" . g_TabControlWidth . " h" . (g_TabControlHeight) . " NA"
}

; Undo last operation
AT_Undo(ctrlID)
{
    GuiControlGet, hwnd, ICScriptHub:Hwnd, %ctrlID%
    SendMessage, 0x0304, 0, 0,, ahk_id %hwnd% ; WM_UNDO
}

Class IC_AreaTiming_GUI
{
    LastMaxTabHeight := 0
    LastMaxTabWidth := 0
    LastEditControlID := ""

    __New()
    {
        this.AddToolTips()
        GuiControl, ICScriptHub:, AreaTimingShowAllAreas, 1
        this.ShowListView("AreaTimingShowAllAreas")
        this.ApplySortingOptions()
        this.DoResizeEvent()
        ; Trigger resize event to show LV scrollbars.
        SetTimer, AT_RefreshSize, -150
    }

    ; Show a message box asking whether or not to close the timer script on exit.
    Close()
    {
        if (A_ExitReason == "Reload" || !g_AreaTiming.IsTimerScriptRunning())
            return
        MsgBox 4,, IC_AreaTiming_TimerScript_Run.ahk is running. Do you want to close it? Saved data will be lost.
        IfMsgBox Yes
            g_AreaTiming.CloseTimerScript()
    }

    ; Show tooltips on mouseover.
    AddToolTips()
    {
        GUIFunctions.AddToolTip("AreaTimingStart", "Start recording a new session.")
        GUIFunctions.AddToolTip("AreaTimingStop", "Stop recording the current session.")
        GUIFunctions.AddToolTip("AreaTimingClose", "Close the timer script. Sessions/runs will be cleared.")
        GUIFunctions.AddToolTip("AreaTimingBGFSync", "Clicking on Start/Stop in Briv Gem farm tab will trigger recording/stopping recording a session.")
        GUIFunctions.AddToolTip("AreaTimingUncappedSpeed", "Game speed is capped at 10x.")
    }

    ; Modify the sort/align column options for each ListView.
    ApplySortingOptions()
    {
        this.BuildAreaTimingView()
        this.BuildModAreaTimingView()
        this.BuildStacksAreaTimingView()
    }

    BuildAreaTimingView(all := false)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "AreaTimingView")
        cols := LV_GetCount("Col")
        if (cols == 15 && !all || cols == 8 && all)
            return
        Loop, % cols
            LV_DeleteCol(1)
        ; Area
        pos := LV_InsertCol(1, "Integer", "Area")
        LV_ModifyCol(1, "Integer") ; ??
        ; Next
        pos := LV_InsertCol(pos + 1, "NoSort Left", "Next")
        ; T_area
        pos := all ? pos : LV_InsertCol(pos + 1, "Float Center", "T_area")
        ; T_tran
        pos := all ? pos : LV_InsertCol(pos + 1, "Float Center", "T_tran")
        ; T_time
        pos := all ? pos : LV_InsertCol(pos + 1, "Float Center", "T_time")
        ; AvgT_area
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgT_area")
        ; AvgT_tran
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgT_tran")
        ; AvgT_time
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgT_time")
        ; T_run
        pos := all ? pos : LV_InsertCol(pos + 1, "Float Center", "T_run")
        ; AvgT_run
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgT_run")
        ; Count
        pos := LV_InsertCol(pos + 1, "Integer Center", "Count")
        ; Game speed
        pos := all ? pos : LV_InsertCol(pos + 1, "Float Center", "Game speed")
        ; AvgGame speed
        align := all ? "Float Left " : "Float Center"
        pos := LV_InsertCol(pos + 1, align, "AvgGame speed")
        ; HStacks
        pos := all ? pos : LV_InsertCol(pos + 1, "Integer Center", "HStacks")
        ; SBStacks
        pos := all ? pos : LV_InsertCol(pos + 1, "Integer Left", "SBStacks")
        Loop % LV_GetCount("Col") ; Resize column headers
            LV_ModifyCol(A_Index, "AutoHdr")
    }

    BuildModAreaTimingView(all := false)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ModAreaTimingView")
        cols := LV_GetCount("Col")
        if (cols == 10 && !all || cols == 6 && all)
            return
        Loop, % cols
            LV_DeleteCol(1)
        ; Area
        pos := LV_InsertCol(1, "Integer", "Area")
        LV_ModifyCol(pos, "Integer") ; ??
        ; Next
        pos := LV_InsertCol(pos + 1, "Integer Left", "Next")
        ; T_area
        pos := all ? pos : LV_InsertCol(pos + 1, "Float Center", "T_area")
        ; T_tran
        pos := all ? pos : LV_InsertCol(pos + 1, "Float Center", "T_tran")
        ; T_time
        pos := all ? pos : LV_InsertCol(pos + 1, "Float Center", "T_time")
        ; Count_run
        pos := all ? pos : LV_InsertCol(pos + 1, "Integer Center", "Count_run")
        ; AvgT_area
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgT_area")
        ; AvgT_tran
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgT_tran")
        ; AvgT_time
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgT_time")
        ; Count
        pos := LV_InsertCol(pos + 1, "Integer Left", "Count")
        Loop % LV_GetCount("Col") ; Resize column headers
            LV_ModifyCol(A_Index, "AutoHdr")
    }

    BuildStacksAreaTimingView(all := false)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "StacksAreaTimingView")
        cols := LV_GetCount("Col")
        if (cols == 12 && !all || cols == 13 && all)
            return
        Loop, % cols
            LV_DeleteCol(1)
        ; Run ID
        pos := all ? LV_InsertCol(1, "Integer Center", "Run ID") : 0
        LV_ModifyCol(1, "Integer Center") ; ??
        ; Area
        pos := LV_InsertCol(pos + 1, "Integer", "Area")
        LV_ModifyCol(pos, "Integer") ; ??
        ; Next
        pos := LV_InsertCol(pos + 1, "Integer Left", "Next")
        ; T_time
        pos := LV_InsertCol(pos + 1, "Float Center", "T_time")
        ; AvgT_Time
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgT_Time")
        ; Stacks
        pos := LV_InsertCol(pos + 1, "Integer Center", "Stacks")
        ; AvgStacks
        pos := LV_InsertCol(pos + 1, "Integer Center", "AvgStacks")
        ; Count
        pos := LV_InsertCol(pos + 1, "Integer Center", "Count")
        ; Stacks/s
        pos := LV_InsertCol(pos + 1, "Float Center", "Stacks/s")
        ; AvgStacks/s
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgStacks/s")
        ; Jumps/s
        pos := LV_InsertCol(pos + 1, "Float Center", "Jumps/s")
        ; AvgJumps/s
        pos := LV_InsertCol(pos + 1, "Float Center", "AvgJumps/s")
        ; Game speed
        pos := LV_InsertCol(pos + 1, "Float Left", "Game speed")
        Loop % LV_GetCount("Col") ; Resize column headers
            LV_ModifyCol(A_Index, "AutoHdr")
    }

    ; Show/hide ListViews depending on which radio button is currently selected.
    ; Params: - controlID:str - Name of the ListView's control variable.
    ShowListView(controlID)
    {
        this.ToggleAllAreasView(controlID == "AreaTimingShowAllAreas")
        this.ToggleMod50View(controlID == "AreaTimingShowMod50")
        this.ToggleStacksView(controlID == "AreaTimingShowStacks")
        this.ToggleAreaTimingUncappedSpeed(controlID != "AreaTimingShowMod50")
    }

    ToggleAllAreasView(show := true)
    {
        showSetting := show ? "Show" : "Hide"
        GuiControl, ICScriptHub:%showSetting%, AreaTimingViewHeader
        GuiControl, ICScriptHub:%showSetting%, AreaTimingView
    }

    ToggleMod50View(show := true)
    {
        showSetting := show ? "Show" : "Hide"
        GuiControl, ICScriptHub:%showSetting%, ModAreaTimingViewHeader
        GuiControl, ICScriptHub:%showSetting%, ModAreaTimingView
        GuiControl, ICScriptHub:%showSetting%, AT_ExcludeMod50Outliers
    }

    ToggleStacksView(show := true)
    {
        showSetting := show ? "Show" : "Hide"
        GuiControl, ICScriptHub:%showSetting%, StacksAreaTimingViewHeader
        GuiControl, ICScriptHub:%showSetting%, StacksAreaTimingView
    }

    ToggleAreaTimingUncappedSpeed(show := true)
    {
        showSetting := show ? "Show" : "Hide"
        GuiControl, ICScriptHub:%showSetting%, AreaTimingUncappedSpeed
    }

    CurrentView
    {
        get
        {
            GuiControlGet, value, ICScriptHub:, AreaTimingShowAllAreas
            if (value)
                return "AreaTimingView"
            GuiControlGet, value, ICScriptHub:, AreaTimingShowMod50
            if (value)
                return "ModAreaTimingView"
            GuiControlGet, value, ICScriptHub:, AreaTimingShowStacks
            if (value)
                return "StacksAreaTimingView"
            else
                return ""
        }
    }

    ; Update ListView contents.
    ; Params: - controlID:str - Name of the ListView's control variable.
    ;         - data:arr - Array that contains data for all rows.
    ;           Every row should contain one or multiple values in an array.
    ;         - isAll:bool - True if showing data from all runs.
    UpdateListView(controlID, data, isAll)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", controlID)
        LV_Delete()
        if (controlID == "AreaTimingView")
            this.BuildAreaTimingView(isAll)
        else if (controlID == "ModAreaTimingView")
            this.BuildModAreaTimingView(isAll)
        else if (controlID == "StacksAreaTimingView")
            this.BuildStacksAreaTimingView(isAll)
        else
            return
        ; Add rows
        Loop, % data.Length()
            LV_Add(, data[A_Index]*)
        ; Resize columns
        Loop % LV_GetCount("Col")
            LV_ModifyCol(A_Index, "AutoHdr")
        if (controlID == "StacksAreaTimingView")
            LV_ModifyCol(1, "Sort")
    }

    ; Resize ListViews up to the maximum size of ICScriptHub's main tab.
    ; Params: - controlID:str - Name of the ListView's control variable.
    ResizeView(controlID)
    {
        maxH := this.GetMaxTabHeight()
        maxW:= this.GetMaxTabWidth()
        GuiControlGet, pos, ICScriptHub:Pos, %controlID%
        newH := maxH - posY - 10
        newW:= maxW - posX - 10
        GuiControl, ICScriptHub:MoveDraw, %controlID%, h%newH% w%newW%
    }

    ; Checks performed on GUI resize event.
    ; Resize the UI on mouse release if this addon's tab is not focused.
    CheckResizeEvent(WM)
    {
        global
        GuiControlGet, currentTab, ICScriptHub:, ModronTabControl, Tab
        if (WM == 0x0231 AND currentTab == "Area Timing")
            SetTimer, AreaTiming_DoResizeEvent, 200
        else if (WM == 0x0232)
        {
            SetTimer, AreaTiming_DoResizeEvent, Delete
            this.DoResizeEvent()
        }
    }

    ; Action performed on GUI resize event.
    DoResizeEvent()
    {
        maxH := this.GetMaxTabHeight()
        maxW := this.GetMaxTabWidth()
        ; Only resize when ICScriptHub has been resized.
        if (maxH != this.LastMaxTabHeight || maxW != this.LastMaxTabWidth)
        {
            this.LastMaxTabHeight := maxH
            this.LastMaxTabWidth := maxW
            this.ResizeView("AreaTimingView")
            this.ResizeView("ModAreaTimingView")
            this.ResizeView("StacksAreaTimingView")
        }
    }

    ; Returns the height of ICScriptHub's main tab control.
    GetMaxTabHeight()
    {
        GuiControlGet, maxPos, ICScriptHub:Pos, ModronTabControl
        return maxPosH + maxPosY
    }

    ; Returns the width of ICScriptHub's main tab control.
    GetMaxTabWidth()
    {
        GuiControlGet, maxPos, ICScriptHub:Pos, ModronTabControl
        return maxPosW + maxPosX
    }

    ; Handle ListView events.
    ; Params: - controlID:str - Name of the ListView's control variable.
    ListViewEvent(controlID)
    {
        static keys := {}
        static comboDelay := A_TickCount

        Switch A_GuiEvent
        {
            case "RightClick": ; Right-Clicked on ListView item
                this.OpenContextMenu(controlID)
            case "DoubleClick": ; Double-Clicked on ListView item
                this.SelectAllRows(controlID)
            case "K": ; Keyboard event while ListView has focus
            {
                if (A_TickCount - comboDelay >= 150)
                {
                    keys := {}
                    comboDelay := A_TickCount
                }
                key := GetKeyName(Format("vk{:x}", A_EventInfo))
                keys[key] := true
                if key in Control,a,c
                {
                    if (keys.Control && keys.a) ; CTRL-A
                    {
                        keys := {}
                        this.SelectAllRows(controlID)
                    }
                    else if (keys.Control && keys.c) ; CTRL-C
                    {
                        keys := {}
                        this.ContextCopyRows(controlID)
                    }
                }
            }
        }
    }

    ; Displays a context menu after a right-click on the ListView.
    ; Copy: Copy rows into the clipboard.
    ; Delete: Delete selected rows.
    ; Params: - controlID:str - Name of the ListView's control variable.
    OpenContextMenu(controlID)
    {
        func := ObjBindMethod(this, "ContextCopyRows", controlID)
        Menu, AT_LogContextMenu, Add, Copy, %func%
        Menu AT_LogContextMenu, Show
    }

    ; Copy selected rows of the ListView into the clipboard.
    ; Rows are separated by a newline.
    ; Params: - controlID:str - Name of the ListView's control variable.
    ContextCopyRows(controlID)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", controlID)
        selectedRows := this.GetSelectedRows(controlID)
        if (selectedRows.Length() == 0)
            return clipboard := ""
        cols := LV_GetCount("Col")
        ; Headers
        LV_GetText(text, 0, 1)
        Loop, % cols - 1
        {
            LV_GetText(header, 0, A_Index + 1)
            text .= " " . header
        }
        text .= "`r`n"
        ; Row contents
        for k, v in selectedRows
        {
            LV_GetText(rowText, v, 1)
            text .= rowText
            Loop, % cols - 1
            {
                LV_GetText(rowText, v, A_Index + 1)
                text .= " " . rowText
            }
            text .= "`r`n"
        }
        clipboard := text
    }

    ; Select all rows after the user presses CTRL-A.
    ; Params: - controlID:str - Name of the ListView's control variable.
    SelectAllRows(controlID)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", controlID)
        LV_Modify(0, "Select")
    }

    ; Returns an array that contains the indexes of all the currently selected rows in the ListView.
    ; Params: - controlID:str - Name of the ListView's control variable.
    GetSelectedRows(controlID)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", controlID)
        selectedRows := []
        rowNumber := 0
        Loop
        {
            rowNumber := LV_GetNext(rowNumber)
            if not rowNumber
                break
            else
                selectedRows.Push(rowNumber)
        }
        return selectedRows
    }

    ; Allows to disable controls during session/run loading.
    ; Params: - enable:bool - If true, enable controls, else disable them.
    ToggleSelection(enable)
    {
        if (!enable && this.LastEditControlID == "")
        {
            try
            {
                GuiControlGet, controlID, FocusV
                this.LastEditControlID := controlID
            }
        }
        value := enable ? "Enable" : "Disable"
        GuiControl, ICScriptHub:%value%, AreaTimingSelectSession
        GuiControl, ICScriptHub:%value%, AT_SelectSessionID
        GuiControl, ICScriptHub:%value%, AT_SelectSessionUpDown
        GuiControl, ICScriptHub:%value%, AreaTimingSelectRun
        GuiControl, ICScriptHub:%value%, AT_SelectRunID
        GuiControl, ICScriptHub:%value%, AT_SelectRunUpDown
        GuiControl, ICScriptHub:%value%, AreaTimingUncappedSpeed
        GuiControl, ICScriptHub:%value%, AT_ExcludeMod50Outliers
        if (enable)
        {
            if (this.LastEditControlID == "AT_SelectSessionID")
                GuiControl, ICScriptHub:Focus, AT_SelectSessionID
            else if (this.LastEditControlID == "AT_SelectRunID")
                GuiControl, ICScriptHub:Focus, AT_SelectRunID
            this.LastEditControlID := ""
        }
    }

    ; Update the text shown next to the "select session" DDL.
    ; Temporarily disables edit gLabel from firing to prevent feedback loops.
    UpdateSelectSessionText(id := 0, count := 0)
    {
        if (count > 0)
            text := " / " . count
        else
            text := ""
        this.ToggleSelectEvents(false)
        minRange := count > 0
        GuiControl, ICScriptHub:+Range%minRange%-%count%, AT_SelectSessionUpDown
        GuiControl, ICScriptHub:Text, AT_SelectSessionID, % id
        GuiControl, ICScriptHub:Text, AT_SelectSessionIDText, % text
        this.ToggleSelectEvents()
    }

    ; Update the text shown next to the "select run" DDL.
    ; Temporarily disables edit gLabel from firing to prevent feedback loops.
    UpdateSelectRunText(id := 0, count := 0)
    {
        if (count > 0)
            text := " / " . count
        else
            text := ""
        this.ToggleSelectEvents(false)
        minRange := count > 0
        GuiControl, ICScriptHub:+Range%minRange%-%count%, AT_SelectRunUpDown
        GuiControl, ICScriptHub:Text, AT_SelectRunID, % id
        GuiControl, ICScriptHub:Text, AT_SelectRunIDText, % text
        this.ToggleSelectEvents()
    }

    ; Temporarily disable Edit gLabels from firing to prevent feedback loops.
    ; Params: - on:bool - If true, enable edit events, else disable them.
    ToggleSelectEvents(on := true)
    {
        if (on)
        {
            GuiControl, ICScriptHub:+gAT_SelectSessionID, AT_SelectSessionID
            GuiControl, ICScriptHub:+gAT_SelectRunID, AT_SelectRunID
        }
        else
        {
            GuiControl, ICScriptHub:-g, AT_SelectSessionID
            GuiControl, ICScriptHub:-g, AT_SelectRunID
        }
    }

    ; Returns the controlID of the currently dropped combo (session/run).
    GetCurrentlyDroppedCombo()
    {
        GuiControlGet, currentTab, ICScriptHub:, ModronTabControl, Tab
        if (currentTab != "Area Timing")
            return
        GuiControlGet, hwnd, ICScriptHub:Hwnd, AreaTimingSelectSession
        SendMessage, 0x0157, 0, 0,, ahk_id %hwnd% ; CB_GETDROPPEDSTATE
        if (Errorlevel)
            return "AreaTimingSelectSession"
        GuiControlGet, hwnd, ICScriptHub:Hwnd, AreaTimingSelectRun
            SendMessage, 0x0157, 0, 0,, ahk_id %hwnd% ; CB_GETDROPPEDSTATE
        if (Errorlevel)
            return "AreaTimingSelectRun"
    }
    
    ; Enable or disable the Start/Stop/Close buttons.
    ; Timerscript: IC_AreaTiming_TimerScript_Run.ahk
    ; 1: Script started = Stop/Close enabled.
    ; 2: Script stopped = Start/Close enabled.
    ; 3: Script closed = Start enabled.
    UpdateButtons(state := 1)
    {
        valueStart := state == 1 ? "Disable" : "Enable"
        valueStop := state == 2 || state == 3 ? "Disable" : "Enable"
        valueClose := state == 3 ? "Disable" : "Enable"
        GuiControl, ICScriptHub:%valueStart%, AreaTimingStart
        GuiControl, ICScriptHub:%valueStop%, AreaTimingStop
        GuiControl, ICScriptHub:%valueClose%, AreaTimingClose
    }
}