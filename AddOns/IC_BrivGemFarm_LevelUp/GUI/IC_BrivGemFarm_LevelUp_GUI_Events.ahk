BGFLU_CheckResizeEvent(WM)
{
    IC_BrivGemFarm_LevelUp_GUI_Events.CheckResizeEvent(WM)
}

BGFLU_DoResizeEvent()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.DoResizeEvent()
}

BGFLU_CheckMouseEvent(W)
{
    IC_BrivGemFarm_LevelUp_GUI_Events.CheckMouseEvent(W)
}

BGFLU_CheckBoxEvent()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.CheckBoxEvent()
}

BGFLU_Mod50CheckBoxEvent()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.Mod50CheckBoxEvent()
}

BGFLU_EditEvent()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.EditEvent()
}

BGFLU_LB_Section()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.LB_SectionClicked()
}

BGFLU_Name()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.NameClicked()
}

BGFLU_MinMax_Clamp()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.MinMax_Clamp()
}

BGFLU_LoadFormation()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.LoadFormationEvent()
}

BGFLU_FavoriteFormationZ1()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.FavoriteFormationZ1Selected()
}

BGFLU_Default()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.DefaultClicked()
}

BGFLU_Save()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.SaveClicked()
}

BGFLU_Changes()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.ChangesClicked()
}

BGFLU_Undo()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.UndoClicked()
}

BGFLU_MinDefault()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.MinDefaultClicked()
}

BGFLU_MaxDefault()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.MaxDefaultClicked()
}

BGFLU_SelectLanguage()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.SelectLanguageClicked()
}

BGFLU_LoadDefinitions()
{
    IC_BrivGemFarm_LevelUp_GUI_Events.LoadDefinitionsClicked()
}

Class IC_BrivGemFarm_LevelUp_GUI_Events
{
    static LoadDefinitionsTrigger := false

    ; Checked/ unchecked
    CheckBoxEvent()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        local setting := StrReplace(A_GuiControl, "BGFLU_")
        local value := % %A_GuiControl%
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting(setting, value)
        if (setting == "ShowSpoilers")
            g_BrivGemFarm_LevelUp.ToggleSpoilers(value) ; Effect is immediate
    }

    ; Checked/ unchecked (mod50)
    Mod50CheckBoxEvent()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        RegExMatch(A_GuiControl, "BGFLU_([^_]+)_Mod50_\d+", setting)
        rootControlID := "BGFLU_" . setting1 . "_Mod50_"
        value := 0
        Loop, 50
        {
            GuiControlGet, isChecked, ICScriptHub:, %rootControlID%%A_Index%
            if (isChecked)
                value += 2 ** (A_Index - 1)
        }
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting(setting1, value)
    }

    ; Keyboard or c/p input
    EditEvent()
    {
        global
        local beforeSubmit := % %A_GuiControl%
        Gui, ICScriptHub:Submit, NoHide
        local setting := StrReplace(A_GuiControl, "BGFLU_")
        local value := % %A_GuiControl%
        if value is not digit
        {
            GuiControl, ICScriptHub:Text, %A_GuiControl%, % beforeSubmit
            return
        }
        local currMin := ""
        if (setting == "MinLevelInputDelay")
            currMin := 0
        else if (setting != "MinLevelTimeout" && setting != "ClickDamageMatchArea")
            currMin := 1
        if (currMin != "" && value < currMin)
        {
            value := currMin
            GuiControl, ICScriptHub:Text, %A_GuiControl%, % value
        }
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting(setting, value)
    }

    ; Moves a MsgBox window after a short delay to create a new thread.
    ; Should be called right before showing a MsgBox window.
    ; Params: controlID:str - Name of the control where the MsgBox should be moved near.
    SetupMoveMsgBox(controlID)
    {
        params := [controlID]
        func := ObjBindMethod(this, "MoveMsgBox", params*)
        SetTimer, %func%, -1
    }

    ; Moves the currently active window after it has appeared on screen.
    ; Params: controlID:str - Name of the control where the MsgBox should be moved near.
    MoveMsgBox(controlID)
    {
        targetPos := this.GetPopupPos(controlID)
        newX := targetPos[1]
        newY := targetPos[2]
        WinGetActiveTitle, title
        if (title == "" || title == "IC Script Hub")
            return this.SetupMoveMsgBox(controlID)
        WinMove, %title%,, %newX%, %newY%
        this.MoveIfOutOfBounds(title, newX, newY)
    }

    ; Moves the target window inside the bounds of the current monitor.
    MoveIfOutOfBounds(winTitle, xLoc, yLoc)
    {
        WinGetPos, x, y, w, h, %winTitle%
        monitor := IC_BrivGemFarm_LevelUp_Functions.GetMonitor(winTitle)
        SysGet, monitorCoords, MonitorWorkArea, %monitor%
        if ((xLoc + w) > monitorCoordsRight)
            xLoc := monitorCoordsRight - w
        if ((yLoc + h) > monitorCoordsBottom)
            yLoc := monitorCoordsBottom - h
        WinMove, %winTitle%,, xLoc, yLoc
    }

    ; Returns the position where the MsgBox / new window should appear.
    ; Params: controlID:str - Name of the control where the MsgBox should be moved near.
    GetPopupPos(controlID)
    {
        WinGetPos, x, y, w, h, IC Script Hub
        GuiControlGet, hwnd, ICScriptHub:Hwnd, %controlID%
        ControlGetPos, posX, posY, posW, posH,, ahk_id %hwnd%
        xLoc := x + posX
        yLoc := y + posY + posH
        return [xLoc, yLoc]
    }

    ; Jump to section
    LB_SectionClicked()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        local value := % %A_GuiControl%
        IC_BrivGemFarm_LevelUp_GUI.ShowSection(value + 1)
    }

    ; Switch names
    NameClicked()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        local name := % %A_GuiControl%
        local heroData := g_HeroDefines.HeroDataByName[name]
        IC_BrivGemFarm_LevelUp_Seat.Seats[heroData.seat_id].UpdateMinMaxLevels(name)
    }

    ; Input upgrade level when selected from DDL, then verify that min/max level inputs are in 0-999999 range
    MinMax_Clamp()
    {
        global
        local beforeSubmit := % %A_GuiControl%
        Gui, ICScriptHub:Submit, NoHide
        local value := % %A_GuiControl%
        local clamped := value
        Loop, Parse, clamped, :, " "
        {
            clamped := A_LoopField
            break
        }
        if clamped is not digit
        {
            GuiControl, ICScriptHub:Text, %A_GuiControl%, % beforeSubmit
            Gui, ICScriptHub:Submit, NoHide
            return
        }
        if (clamped != value)
            GuiControl, ICScriptHub:Text, %A_GuiControl%, % clamped
        local split := StrSplit(A_GuiControl, "_")
        local heroId := IC_BrivGemFarm_LevelUp_Seat.Seats[split[4]].GetCurrentHeroData().id
        Switch split[3]
        {
            Case "MinLevel":
            {
                g_BrivGemFarm_LevelUp.TempSettings.AddSetting(["BrivGemFarm_LevelUp_Settings", "minLevels", heroId], clamped)
                if (g_BrivGemFarm_LevelUp.GetLevelSettings().maxLevels[heroId] == "")
                    g_BrivGemFarm_LevelUp.TempSettings.AddSetting(["BrivGemFarm_LevelUp_Settings", "maxLevels", heroId], g_BrivGemFarm_LevelUp.GetSetting("DefaultMaxLevel"))
            }
            Case "MaxLevel":
            {
                g_BrivGemFarm_LevelUp.TempSettings.AddSetting(["BrivGemFarm_LevelUp_Settings", "maxLevels", heroId], clamped)
                if (g_BrivGemFarm_LevelUp.GetLevelSettings().minLevels[heroId] == "")
                    g_BrivGemFarm_LevelUp.TempSettings.AddSetting(["BrivGemFarm_LevelUp_Settings", "minLevels", heroId], g_BrivGemFarm_LevelUp.GetSetting("DefaultMinLevel"))
            }
            Case "BrivMinLevelStacking":
                g_BrivGemFarm_LevelUp.TempSettings.AddSetting("BrivMinLevelStacking", clamped)
            Case "BrivMinLevelStackingOnline":
                g_BrivGemFarm_LevelUp.TempSettings.AddSetting("BrivMinLevelStackingOnline", clamped)
            Default:
                return
        }
    }

    ; Load formation to the GUI
    LoadFormationEvent()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        GuiControl, ICScriptHub:Disable, BGFLU_LoadFormation
        Sleep, 20
        g_BrivGemFarm_LevelUp.LoadFormation(%A_GuiControl%)
        GuiControl, ICScriptHub:Enable, BGFLU_LoadFormation
    }

    ; Favorite formation on z1 button
    FavoriteFormationZ1Selected()
    {
        global
        local beforeSubmit := % %A_GuiControl%
        Gui, ICScriptHub:Submit, NoHide
        local value := % %A_GuiControl%
        if (value != beforeSubmit)
            g_BrivGemFarm_LevelUp.TempSettings.AddSetting("FavoriteFormationZ1", BGFLU_FavoriteFormationZ1)
    }

    ; Default settings button
    DefaultClicked()
    {
        global
        this.SetupMoveMsgBox("BGFLU_Default")
        MsgBox, 4, BrivGemFarm LevelUp, Restore Default settings?, 10
        IfMsgBox, No
            Return
        IfMsgBox, Timeout
            Return
        GuiControl, ICScriptHub:Disable, BGFLU_Default
        g_BrivGemFarm_LevelUp.LoadSettings(true)
        GuiControl, ICScriptHub:Enable, BGFLU_Default
    }

    ; Save settings button
    SaveClicked()
    {
        global
        this.SetupMoveMsgBox("BGFLU_Save")
        MsgBox, 4, BrivGemFarm LevelUp, Save and apply changes?, 10
        IfMsgBox, No
            Return
        IfMsgBox, Timeout
            Return
        Gui, IC_BrivGemFarm_LevelUp_TempSettings:Hide
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.SaveSettings(true)
    }

    ; TempSettings changes
    ChangesClicked()
    {
        global
        g_BrivGemFarm_LevelUp.TempSettings.ReloadTempSettingsDisplay()
        ; Show the window under the "View changes" button
        targetPos := this.GetPopupPos("BGFLU_Changes")
        xLoc := targetPos[1]
        yLoc := targetPos[2]
        Gui, IC_BrivGemFarm_LevelUp_TempSettings:Show, x%xLoc% y%yLoc%
        ; Move window if out of monitor bounds
        this.MoveIfOutOfBounds("BrivGemFarm LevelUp Settings", xLoc, yLoc)
    }

    ; Undo temp settings button
    UndoClicked()
    {
        global
        this.SetupMoveMsgBox("BGFLU_Undo")
        MsgBox, 4, BrivGemFarm LevelUp, Undo all changes?, 10
        IfMsgBox, No
            Return
        IfMsgBox, Timeout
            Return
        g_BrivGemFarm_LevelUp.UndoTempSettings()
        Gui, IC_BrivGemFarm_LevelUp_TempSettings:Hide
    }

    ; Default min values for champions without default parameters.
    MinDefaultClicked()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("DefaultMinLevel", BGFLU_MinRadio0 ? 0 : 1)
        g_BrivGemFarm_LevelUp.ResetNonSpeedSettings()
        g_BrivGemFarm_LevelUp.LoadFormation(g_BrivGemFarm_LevelUp.GetFormationFromGUI())
    }

    ; Default max values for champions without default parameters.
    MaxDefaultClicked()
    {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivGemFarm_LevelUp.TempSettings.AddSetting("DefaultMaxLevel", BGFLU_MaxRadio1 ? 1 : "Last")
        g_BrivGemFarm_LevelUp.ResetNonSpeedSettings()
        g_BrivGemFarm_LevelUp.LoadFormation(g_BrivGemFarm_LevelUp.GetFormationFromGUI())
    }

    ; Select language used for defintions.
    ; Doesn't save to temp settings, loads a new language immediately.
    SelectLanguageClicked()
    {
        global
        local beforeSubmit := % %A_GuiControl%
        Gui, ICScriptHub:Submit, NoHide
        local value := % %A_GuiControl%
        if (value != beforeSubmit)
        {
            g_BrivGemFarm_LevelUp.SetSetting("DefinitionsLanguage", BGFLU_SelectLanguage)
            this.LoadDefinitionsClicked()
        }
    }

    ; Load new definitions
    LoadDefinitionsClicked()
    {
        global
        GuiControl, ICScriptHub:Disable, BGFLU_SelectLanguage
        GuiControl, ICScriptHub:Disable, BGFLU_LoadDefinitions
        g_DefinesLoader.Start(false, true)
    }

    ; Checks performed on GUI resize event
    CheckResizeEvent(WM)
    {
        global
        if (WM == WM_ENTERSIZEMOVE AND this.IsCurrentTabLevelUp())
            SetTimer, BGFLU_DoResizeEvent, 200
        else if (WM == WM_EXITSIZEMOVE)
        {
            SetTimer, BGFLU_DoResizeEvent, Delete
            this.DoResizeEvent()
        }
    }

    ; Action performed on GUI resize event
    DoResizeEvent()
    {
        global
        IC_BrivGemFarm_LevelUp_GUI.ShowSection(BGFLU_LB_Section + 1)
    }

    CheckMouseEvent(W)
    {
        ; Startup
        if (this.IsCurrentTabLevelUp() && !this.LoadDefinitionsTrigger)
        {
            this.LoadDefinitionsTrigger := true
            func := ObjBindMethod(g_DefinesLoader, "LoadDefinitions")
            SetTimer, %func%, -100
        }
        else
            this.CheckComboStatus(W)
    }

    ; Checks performed on combo mouseover / selection cancel
    CheckComboStatus(W)
    {
        global
        local arr := this.GetCurrentlyDroppedCombo()
        if (local seat_ID := arr[1])
        {
            if ((W >> 16) & 0xFFFF == CBN_SELENDCANCEL) ; Refresh min/max values after a ComboBox sends a selection cancel event to the parent tab
            {
                ToolTip
                if (seat_ID == "58Off" || seat_ID == "58On")
                {
                    local setting := "BrivMinLevelStacking" . (seat_ID == "58On" ? "Online" : "")
                    local controlID := "BGFLU_Combo_" . setting
                    local value := g_BrivGemFarm_LevelUp.GetSetting(setting)
                }
                else
                {
                    local controlID := "BGFLU_DDL_Name_" . seat_ID
                    GuiControlGet, value,, %controlID%
                }
                GuiControl, ICScriptHub:ChooseString, %controlID%, % "|" . value
            }
            else if (this.MouseOverComboBoxList(ctrlH := arr[2])) ; Show current selection as tooltip
            {
                OnMessage(0x200, "CheckControlForToolTip",0)
                func := ObjBindMethod(this, "RemoveToolTip")
                SetTimer, %func%, -500
                SendMessage, CB_GETCURSEL, 0, 0,, ahk_id %ctrlH%
                local currentSel := ErrorLevel ; 0 based
                local trueSeatID := (seat_ID == "58Off" || seat_ID == "58On") ? 5 : seat_ID
                local heroData := IC_BrivGemFarm_LevelUp_Seat.Seats[trueSeatID].GetCurrentHeroData()
                ToolTip, % IC_BrivGemFarm_LevelUp_Functions.WrapText(heroData.UpgradeDescriptionFromIndex(currentSel + 1))
                SetTimer, HideToolTip, Delete
                OnMessage(0x200, "CheckControlForToolTip")
            }
        }
    }

    ; Remove comboBox toolip when not hovering
    RemoveToolTip()
    {
        arr := this.GetCurrentlyDroppedCombo()
        MouseGetPos,,,, VarControl ; CheckControlForToolTip()
        if (!VarControl AND !(arr[1] AND this.MouseOverComboBoxList(arr[2])))
            ToolTip
    }

    ; Returns an array containing the corresponding seatID / control Hwnd of the currently dropped combo
    GetCurrentlyDroppedCombo()
    {
        global
        if (!this.IsCurrentTabLevelUp())
            return
        Loop, 12
        {
            local ctrlHwnd := HBGFLU_MinLevel_%A_Index%
            SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlHwnd%
            if (Errorlevel)
                return [A_Index, ctrlHwnd]
            ctrlHwnd := HBGFLU_MaxLevel_%A_Index%
            SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlHwnd%
            if (Errorlevel)
                return [A_Index, ctrlHwnd]
        }
        ctrlHwnd := HBGFLU_BrivMinLevelStacking
        SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlHwnd%
        if (Errorlevel)
            return ["58Off", ctrlHwnd]
        ctrlHwnd := HBGFLU_BrivMinLevelStackingOnline
        SendMessage, CB_GETDROPPEDSTATE, 0, 0,, ahk_id %ctrlHwnd%
        if (Errorlevel)
            return ["58On", ctrlHwnd]
    }

    ; Returns true if the mouse is within the rectangle of a combobox's item list
    MouseOverComboBoxList(controlID)
    {
        global
        SysGet, scrollW, %SM_CXVSCROLL% ; Scrollbar width
        VarSetCapacity(COMBOBOXINFO, size := 40 + A_PtrSize*3, 0)
        NumPut(size, COMBOBOXINFO)
        SendMessage, CB_GETCOMBOBOXINFO,, &COMBOBOXINFO,, ahk_id %controlID%
        local yMaxEdit := NumGet(COMBOBOXINFO, 16, "Int") ; Combo edit height
        VarSetCapacity(RECT, 16, 0)
        NumPut(16, RECT)
        SendMessage, CB_GETDROPPEDCONTROLRECT,, &RECT,, ahk_id %controlID% ; Full combo rect
        local xMin := NumGet(RECT, 0, "Int")
        local yMin := NumGet(RECT, 4, "Int") + yMaxEdit
        local xMax := NumGet(RECT, 8, "Int") - scrollW
        local yMax := NumGet(RECT, 12, "Int")
        local height := yMax - yMin
        local monitor := IC_BrivGemFarm_LevelUp_Functions.GetMonitor(controlID)
        SysGet, monitorCoords, Monitor, %monitor%
        if (height >= monitorCoordsBottom) ; List bigger than screen height
        {
            yMin := 0
            yMax := monitorCoordsBottom
        }
        else if (yMax > monitorCoordsBottom) ; List opens upwards instead of downwards
        {
            yMax := yMin - yMaxEdit
            yMin := yMax - height
        }
        CoordMode, Mouse, Screen
        MouseGetPos, xPos, yPos
        CoordMode, Mouse, Client
        return (xMin <= xPos) AND (xPos <= xMax) AND (yMin <= yPos) AND (yPos <= yMax)
    }

    IsCurrentTabLevelUp()
    {
        global
        GuiControlGet, CurrentTab,, ModronTabControl, Tab
        return CurrentTab == "BrivGF LevelUp"
    }
}