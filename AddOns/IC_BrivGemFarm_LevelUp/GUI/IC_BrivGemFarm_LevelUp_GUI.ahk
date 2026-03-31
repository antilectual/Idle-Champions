#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI_Constants.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI_Events.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI_Control.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_GUI_Group.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_ToolTip.ahk

GUIFunctions.AddTab("BrivGF LevelUp")
; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, BrivGF LevelUp

GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
Gui, ICScriptHub:Add, Text, x+8 Section vBGFLU_Status, Status:
Gui, ICScriptHub:Add, Text, x+5 w500 vBGFLU_StatusText, Not Running

GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
Gui, ICScriptHub:Add, Text, xs ys+15 w500 vBGFLU_StatusWarning,
GUIFunctions.UseThemeTextColor() ; WARNING: Addon was loaded too late. Stop/start Gem Farm to resume.

; Create minLevel, maxLevel, order buttons/edits
IC_BrivGemFarm_LevelUp_GUI.SetupGroups()

; Temp settings ListView
Gui, IC_BrivGemFarm_LevelUp_TempSettings:New, -MaximizeBox -Resize, BrivGemFarm LevelUp Settings
GUIFunctions.LoadTheme("IC_BrivGemFarm_LevelUp_TempSettings")
GUIFunctions.UseThemeBackgroundColor()
GUIFunctions.UseThemeTextColor()
;Gui IC_BrivGemFarm_LevelUp_TempSettings:Add, GroupBox, w330 h310, BrivGemFarm LevelUp Settings
Gui IC_BrivGemFarm_LevelUp_TempSettings:Add, ListView, w330 h310 NoSortHdr vBGFLU_TempSettings , Setting|Current|New
GUIFunctions.UseThemeListViewBackgroundColor("BGFLU_TempSettings")
GUIFunctions.LoadTheme()

OnMessage(WM_COMMAND, "BGFLU_CheckMouseEvent")
OnMessage(0x200, Func("BGFLU_CheckMouseEvent"))
OnMessage(WM_ENTERSIZEMOVE, Func("BGFLU_CheckResizeEvent").Bind(WM_ENTERSIZEMOVE))
OnMessage(WM_EXITSIZEMOVE, Func("BGFLU_CheckResizeEvent").Bind(WM_EXITSIZEMOVE))

Class IC_BrivGemFarm_LevelUp_GUI
{
    static MainGroup := ""
    static Groups := []
    static SectionNames := ["Min/Max Settings", "General Settings", "Fail Run Recovery Settings", "GUI Settings"]

    ; Creates all of the groups of settings.
    ; All of the other groups are children of BGFLU_SettingsGroup.
    SetupGroups()
    {
        global
        this.SetupBGFLUSettingsGroup()
        this.SetupBGFLU_MinMaxSettingsGroup()
        this.SetupBGFLU_GeneralSettingsGroup()
        this.SetupBGFLU_FailRunRecoverySettingsGroup()
        this.SetupBGFLU_GUISettingsGroup()
        this.MainGroup.AutoResize()
        local rightMostGroupWidth := this.MainGroup.Width - 2 * this.MainGroup.XSection
        for k, v in this.MainGroup.Groups
        {
            if (v.RightAlignWithMain) ; Exclude BGFLU_DefaultSettingsGroup
                v.UpdateSize(, rightMostGroupWidth)
        }
        this.ShowSection()
    }

    ; Add a group to the main BGFLU_SettingsGroup group.
    AddGroup(group)
    {
        group.AutoResize(true)
        this.MainGroup.AddGroup(group)
    }

    SetupBGFLUSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group_Main("BGFLU_SettingsGroup", "BrivGemFarm LevelUp Settings",, false,, "BGFLU_StatusWarning")
        this.MainGroup := group
        this.SetupBGFLU_DefaultSettingsGroup()
        GuiControlGet, pos, ICScriptHub:Pos, BGFLU_DefaultSettingsGroup
        Gui, ICScriptHub:Font, w700
        group.AddControl("BGFLU_MenuTitle", "Text", "x" . (posX + posW + 5) . " y" . posY, "Menu")
        Gui, ICScriptHub:Font, w400
        GuiControlGet, pos, ICScriptHub:Pos, BGFLU_MenuTitle
        sections := "Min/Max Settings||General Settings|Fail Run Recovery Settings|GUI Settings"
        Gui, ICScriptHub:Font, s11
        group.AddControl("BGFLU_LB_Section", "ListBox", "AltSubmit R4 w180 gBGFLU_LB_Section x" . posX . " y" . (posY + 20), sections, false)
        Gui, ICScriptHub:Font, s9
    }

    SetupBGFLU_DefaultSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_DefaultSettingsGroup", "Default Settings", "BGFLU_SettingsGroup")
        group.RightAlignWithMain := false
        group.AddControl("BGFLU_Default", "Button", "Disabled gBGFLU_Default", "Load default settings", true)
        group.AddControl("BGFLU_SettingsStatusText", "Text", "yp+5 w100", "No settings.")
        group.AddControl("BGFLU_Save", "Button", "xp yp-5 Hidden gBGFLU_Save", "Save")
        group.AddControl("BGFLU_Changes", "Button", "Hidden gBGFLU_Changes", "View changes")
        group.AddControl("BGFLU_Undo", "Button", "Hidden gBGFLU_Undo", "Undo")
        group.AddControl("BGFLU_DefaultMinLevelText", "Text",, "Default min level: ", true)
        group.AddControl("BGFLU_MinRadio0", "Radio", "x+5 gBGFLU_MinDefault", "0")
        group.AddControl("BGFLU_MinRadio1", "Radio", "x+0 gBGFLU_MinDefault", "1")
        group.AddControl("BGFLU_DefaultMaxLevelText", "Text",, "Default max level:", true)
        group.AddControl("BGFLU_MaxRadio1", "Radio", "x+5 gBGFLU_MaxDefault", "1")
        group.AddControl("BGFLU_MaxRadioLast", "Radio", "x+0 gBGFLU_MaxDefault", "Last upgrade")
        this.AddGroup(group)
    }

    SetupBGFLU_MinMaxSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_MinMaxSettingsGroup", "Min/Max Settings",, false)
        group.AddControl("BGFLU_SeatText", "Text", "Center", "Seat", true)
        group.AddControl("BGFLU_NameText", "Text", "Center w104", "Name")
        group.AddControl("BGFLU_MinLevelText", "Text", "Center w60", "MinLevel")
        group.AddControl("BGFLU_MaxLevelText", "Text", "Center w60", "MaxLevel")
        GuiControlGet, pos, ICScriptHub:Pos, BGFLU_SeatText
        Loop, 12
            this.AddSeat(A_Index, group, posW)
        group.AddControl("BGFLU_LoadFormationText", "Text", "y+15", "Formation", true)
        group.AddControl("BGFLU_LoadFormation", "DropDownList", "y+-17 w35 AltSubmit Disabled hwndBGFLU_LoadFormation gBGFLU_LoadFormation", "Q||W|E|M")
        SendMessage, CB_SETITEMHEIGHT, -1, 17,, ahk_id %BGFLU_LoadFormation%
        if (ErrorLevel)
            MsgBox, 16,, Failed to resize BGFLU_LoadFormation.
        ; Spoilers
        group.AddCheckBox("BGFLU_ShowSpoilers",, "y+-17", "Show spoilers")
        GUIFunctions.UseThemeTextColor("ErrorTextColor", 700)
        group.AddControl("BGFLU_NoFormationText", "Text", "w220")
        GUIFunctions.UseThemeTextColor()
        this.AddGroup(group)
    }

    ; Add settings for the next seat
    AddSeat(seat, group, seatW)
    {
        global
        group.AddControl("BGFLU_SeatIDText_" . seat, "Text", "Center w" . seatW, seat, true)
        group.AddControl("BGFLU_DDL_Name_" . seat, "DropDownList", "gBGFLU_Name yp-4 w104")
        group.AddControl("BGFLU_Combo_MinLevel_" . seat, "ComboBox", "Limit6 hwndHBGFLU_MinLevel_" . seat . " gBGFLU_MinMax_Clamp w60")
        group.AddControl("BGFLU_Combo_MaxLevel_" . seat, "ComboBox", "Limit6 hwndHBGFLU_MaxLevel_" . seat . " gBGFLU_MinMax_Clamp w60")
    }

    SetupBGFLU_GeneralSettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_GeneralSettingsGroup", "General Settings",, false)
        ; Force Briv/Ellywick MinLevel
        group.AddCheckBox("BGFLU_ForceBrivEllywick",,, "Level up Briv/Ellywick to MinLevel first", true)
        ; Skip early Dashwait
        group.AddCheckBox("BGFLU_SkipMinDashWait",,, "Skip DashWait after Min Leveling")
        ; Maximum number of simultaneous F keys inputs during BGFLU_DoPartySetupMin()
        group.AddEdit("BGFLU_MaxSimultaneousInputs",, "w50 Limit2",, true)
        group.AddControl("BGFLU_MaxSimultaneousInputsText", "Text", "x+5 yp+4", "Max simultaneous F keys inputs during MinLevel")
        group.AddEdit("BGFLU_MinLevelInputDelay",, "yp-4 w50 Limit3")
        group.AddControl("BGFLU_MinLevelInputDelayText", "Text", "x+5 yp+4", "Delay (ms)")
        ; Timeout during BGFLU_DoPartySetupMin()
        group.AddEdit("BGFLU_MinLevelTimeout",, "w50 Limit5",, true)
        group.AddControl("BGFLU_MinLevelTimeoutText", "Text", "x+5 yp+4", "MinLevel timeout (ms)")
        ; Z1 formation
        group.AddControl("BGFLU_FavoriteFormationZ1", "DropDownList", "yp-5 w35 hwndBGFLU_FavoriteFormationZ1 gBGFLU_FavoriteFormationZ1", "Q||W|E")
        SendMessage, CB_SETITEMHEIGHT, -1, 17,, ahk_id %BGFLU_FavoriteFormationZ1%
        if (ErrorLevel)
            MsgBox, 16,, Failed to resize BGFLU_FavoriteFormationZ1.
        group.AddControl("BGFLU_FavoriteFormationZ1Text", "Text", "x+5 yp+4", "z1 formation")
        ; Low favor mode
        group.AddCheckBox("BGFLU_LowFavorMode",,, "Low favor mode", true)
        ; Click damage settings
        local ClickGroup := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_ClickGroup", "Click damage", "BGFLU_GeneralSettingsGroup", false,, "BGFLU_LowFavorMode")
        ClickGroup.AddControl("BGFLU_ClickDamageText", "Text", "x+0", "Level click damage to level")
        ClickGroup.AddEdit("BGFLU_MinClickDamage",, "x+5 yp-3 w50 Limit4")
        ClickGroup.AddControl("BGFLU_MinClickDamageText", "Text", "x+5 yp+3", "on the initial zone")
        ClickGroup.AddCheckBox("BGFLU_ClickDamageSpam",, "xs+0", "Spam click damage", true)
        ClickGroup.AddCheckBox("BGFLU_ClickDamageMatchArea",,, "Match highest area")
        ClickGroup.AutoResize(true, "Line")
        group.AddExistingControl(ClickGroup)
        ; Briv settings
        local BrivGroup := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_BrivGroup", "Briv", "BGFLU_GeneralSettingsGroup", false,, "BGFLU_ClickDamageSpam")
        BrivGroup.AddControl("BGFLU_Combo_BrivMinLevelStacking", "ComboBox", "x+0 w50 Limit5 hwndHBGFLU_BrivMinLevelStacking gBGFLU_MinMax_Clamp",, true)
        BrivGroup.AddControl("BGFLU_BrivMinLevelStackingText", "Text", "x+5 yp+4", "Briv MinLevel before stacking (offline)")
        BrivGroup.AddControl("BGFLU_Combo_BrivMinLevelStackingOnline", "ComboBox", "yp-4 w50 Limit5 hwndHBGFLU_BrivMinLevelStackingOnline gBGFLU_MinMax_Clamp")
        BrivGroup.AddControl("BGFLU_BrivMinLevelStackingOnlineText", "Text", "x+5 yp+4", "Briv MinLevel before stacking (online)")
        BrivGroup.AddEdit("BGFLU_BrivMinLevelArea",, "xs+0 w50 Limit4",, true)
        BrivGroup.AddControl("BGFLU_BrivMinLevelAreaText", "Text", "x+5 yp+4", "Minimum area to reach before leveling Briv")
        BrivGroup.AddCheckBox("BGFLU_BrivThelloraCombineBossCheck",, "xs+0", "Avoid Briv+Thellora jumping into a boss zone", true)
        local BrivMod50Group := new IC_BrivGemFarm_LevelUp_GUI_Mod50Group("BGFLU_BrivLevelingZones", "Briv Min leveling zones", "BGFLU_BrivGroup", false,, "BGFLU_BrivThelloraCombineBossCheck")
        BrivMod50Group.AutoResize(true, "Borderless")
        BrivGroup.AddExistingControl(BrivMod50Group)
        BrivGroup.AutoResize(true, "Line")
        group.AddExistingControl(BrivGroup)
        this.AddGroup(group)
    }

    SetupBGFLU_FailRunRecoverySettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_FailRunRecoverySettingsGroup", "Fail Run Recovery Settings",, false)
        ; Level champions to soft cap after a failed conversion to reach stack zone faster
        group.AddCheckBox("BGFLU_LevelToSoftCapFailedConversion",,, "Level champions to soft cap after failed conversion", true)
        ; Level champions to soft cap after a failed conversion to reach stack zone faster (Briv is excluded, desireable for early stacking)
        group.AddCheckBox("BGFLU_LevelToSoftCapFailedConversionBriv",,, "Briv included")
        this.AddGroup(group)
    }

    SetupBGFLU_GUISettingsGroup()
    {
        global
        local group := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_GUISettingsGroup", "GUI Settings",, false)
        local definitionsGroup := new IC_BrivGemFarm_LevelUp_GUI_Group("BGFLU_DefinitionsGroup", "Definitions", "BGFLU_GUISettingsGroup")
        languages := "English||Deutsch|Pусский|Français|Português|Español|中文"
        width := IC_BrivGemFarm_LevelUp_Functions.DropDownSize(languages)
        definitionsGroup.AddControl("BGFLU_SelectLanguage", "DropDownList", "x+0 w" . width . " AltSubmit gBGFLU_SelectLanguage", languages, true)
        definitionsGroup.AddControl("BGFLU_LoadDefinitions", "Button", "Disabled h20 gBGFLU_LoadDefinitions", "Load Definitions")
        definitionsGroup.AddControl("BGFLU_LoadDefinitionsProgress", "Progress", "h20 w285 Range0-11")
        definitionsGroup.AddControl("BGFLU_DefinitionsStatus", "Text", "xs+0 w300", "No definitions.", true)
        definitionsGroup.AutoResize(true, "Line")
        group.AddExistingControl(definitionsGroup)
        this.AddGroup(group)
    }

    ; Show the maximum amount of groups.
    ; Always include BGFLU_DefaultSettingsGroup, BGFLU_LB_Section control and at least one group.
    ShowSection(section := 2)
    {
        minY := this.GetDefaultSettingsGroupYPos()
        displayed := this.GetDisplayedSections(section)
        for k, v in this.MainGroup.Groups
        {
            if (k > 1)
            {
                if (displayed.HasKey(k))
                {
                    if (displayed.HasKey(k - 1))
                        v.Move(, displayed[k-1])
                    else
                        v.Move(, minY)
                    v.Show()
                    ; Show tooltip when BGFLU_DefinitionsStatus is visible
                    if (k == 5)
                        IC_BrivGemFarm_LevelUp_ToolTip.UpdateDefsCNETime(, true)
                }
                else
                {
                    v.Hide()
                    v.Move(, minY)
                }
            }
        }
        this.UpdateLBSection(displayed)
        this.MainGroup.AutoResize()
    }

    ; Update indicators showing currently displated sections
    UpdateLBSection(displayed)
    {
        names := this.SectionNames
        selection := ""
        for k, v in names
            selection .= (displayed.HasKey(k + 1) ? "‣" : " ") . v . "|"
        GuiControl, ICScriptHub:, BGFLU_LB_Section, % "|" . selection
    }

    ; Returns an object that contains the groups to display and the new Y position of the group.
    ; Doesn't include the first default group BGFLU_DefaultSettingsGroup.
    ; The maximum of groups that fit into the main window will be displayed.
    ; The groups after the group of firstSection index are prioritized in descending order.
    ; Then the groups above that one are backtracked in ascending order.
    GetDisplayedSections(firstSection := 2)
    {
        displayed := {}
        if (firstSection < 2)
            firstSection := 2
        cursor := this.GetDefaultSettingsGroupYPos()
        maxHeight := this.GetMaxDisplayHeight()
        belowGroupCount := this.MainGroup.Groups.Length() - firstSection + 1
        Loop, % belowGroupCount
        {
            groupIndex := firstSection + A_Index - 1
            cursor += this.GetNextGroupHeight(groupIndex)
            if (cursor < maxHeight OR displayed.Count() == 0)
            {
                cursor += 10
                displayed[groupIndex] := cursor
            }
            else
                return displayed
        }
        Loop, % firstSection - 2
        {
            groupIndex := firstSection - A_Index
            cursor += this.GetNextGroupHeight(groupIndex)
            if (cursor < maxHeight OR displayed.Count() == 0)
            {
                cursor += 10
                displayed[groupIndex] := cursor
            }
            else
                break
        }
        return this.GetMaxDisplayedSections(displayed)
    }

    ; Returns an object that contains the displayed groups in order and their Y positions.
    GetMaxDisplayedSections(displayed)
    {
        cursor := this.GetDefaultSettingsGroupYPos()
        for k, v in displayed
        {
            cursor += this.GetNextGroupHeight(k) + 10
            displayed[k] := cursor
        }
        return displayed
    }

    ; Returns the default position for all of the grousp below BGFLU_DefaultSettingsGroup.
    GetDefaultSettingsGroupYPos()
    {
        GuiControlGet, minPos, ICScriptHub:Pos, BGFLU_DefaultSettingsGroup
        return minPosY + minPosH + 10 ; Second group start pos
    }

    ; Returns the height of the next group to display.
    GetNextGroupHeight(index)
    {
        group := this.MainGroup.Groups[index]
        controlID := group.ControlID
        GuiControlGet, nextGroupPos, ICScriptHub:Pos, %controlID%
        return nextGroupPosH
    }

    ; Returns the maximum visible height of this addon's tab.
    GetMaxDisplayHeight()
    {
        GuiControlGet, maxPos, ICScriptHub:Pos, ModronTabControl
        maxTabHeight := maxPosH + maxPosY
        ; Get monitor height without task bar
        monitor := IC_BrivGemFarm_LevelUp_Functions.GetMonitor("ModronTabControl")
        SysGet, monitorCoords, MonitorWorkArea, %monitor%
        ; Get ICScriptHub window coords
        GuiControlGet, hnwd, ICScriptHub:Hwnd, ModronTabControl
        WinGetPos, x, y, w, h, IC Script Hub
        maxDisplayHeight := monitorCoordsBottom - y - h + maxTabHeight
        maxDisplayHeight := Min(maxTabHeight, maxDisplayHeight)
        return maxDisplayHeight
    }

    ; Update the progress bar during definitions loading.
    ; The bar uses colors from the current theme, or default colors.
    MoveProgressBar(state)
    {
        cl := g_BGFLU_HDL_Constants
        GuiControlGet, currentState, ICScriptHub:, BGFLU_LoadDefinitionsProgress
        if (state != currentState)
        {
            GuiControl, ICScriptHub:, BGFLU_LoadDefinitionsProgress, % state
            if (state >= cl.SERVER_TIMEOUT)
                color := this.GetHexColorFromTheme("ErrorTextColor") ; Red
            else if (state >= cl.HERO_DATA_FINISHED)
                color := this.GetHexColorFromTheme("SpecialTextColor2") ; Green
            else
                color := this.GetHexColorFromTheme("SpecialTextColor1") ; Blue
            GuiControl, ICScriptHub:+c%color%, BGFLU_LoadDefinitionsProgress
        }
    }

    ; Update the text displayed during definitions loading.
    UpdateLoadingText(state)
    {
        cl := g_BGFLU_HDL_Constants
        switch state
        {
            case cl.STOPPED:
                text := ""
            case cl.GET_PLAYSERVER:
                text := "Getting playserver..."
            case cl.CHECK_TABLECHECKSUMS:
                text := "Checking for new definitions..."
            case cl.FILE_PARSING:
                text := "Parsing definitions..."
            case cl.TEXT_DEFS:
                text := "Processing text_defines..."
            case cl.HERO_DEFS:
                text := "Processing hero_defines..."
            case cl.ATTACK_DEFS:
                text := "Processing attack_defines..."
            case cl.UPGRADE_DEFS:
                text := "Processing upgrade_defines..."
            case cl.EFFECT_DEFS:
                text := "Processing effect_defines..."
            case cl.EFFECT_KEY_DEFS:
                text := "Processing effect_key_defines..."
            case cl.FILE_SAVING:
                text := "Saving definitions..."
            case cl.HERO_DATA_FINISHED:
                text := "New definitions loaded."
            case cl.HERO_DATA_FINISHED_NOUPDATE:
                text := "No new definitions."
            case cl.SERVER_TIMEOUT:
                text := "Server timeout."
            case cl.DEFS_LOAD_FAIL:
                text := "Failed to load definitions"
            case cl.LOADER_FILE_MISSING:
                text := "Error: Script not found."
        }
        GuiControl, ICScriptHub:, BGFLU_DefinitionsStatus, % text
    }

    ; Returns the color in hex format from the Themes addon settings.
    ; Parameters: - textType:str - Text type setting (eg:DefaultTextColor).
    GetHexColorFromTheme(textType)
    {
        if ((color := GUIFunctions.CurrentTheme[textType]) * 1 == "")
        {
            if (textType == "ErrorTextColor")
                color := "Red"
            else if (textType == "SpecialTextColor1")
                color := "Blue"
            else if (textType == "SpecialTextColor2")
                color := "Green"
            else if (color == "Default")
                color := "White"
            return BGFLU_ColorNameToHexColor.ColorNameToHexColor(color)
        }
        else
            return Format("{:#x}", color)
    }

    ; Set the state of the mod50 checkboxes for Preferred Briv Jump Zones in BGFBFS tab.
    ; Parameters: value:int - A bitfield that represents the checked state of each checkbox.
    LoadMod50(setting, value)
    {
        rootControlID := "BGFLU_" . setting . "_Mod50_"
        Loop, 50
        {
            checked := (value & (2 ** (A_Index - 1))) != 0
            GuiControl, ICScriptHub:, %rootControlID%%A_Index%, % checked
        }
        Gui, ICScriptHub:Submit, NoHide
    }
}