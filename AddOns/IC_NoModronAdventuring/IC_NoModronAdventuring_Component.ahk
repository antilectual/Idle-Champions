#include %A_LineFile%\..\IC_NoModronAdventuring_Functions.ahk

GUIFunctions.AddTab("No Modron Adventuring")

global g_NMAHeroDefines
global g_NMAChampsToLevel := {}
global g_NMAPickedSpecs := {}
global g_NMALastChampLvl := {}
global g_NMAResetZone := 500
global g_NMAWallTime := 300000 ; 5 minutes
global g_NMAAlertZone := 201
global g_NMADoAdventuring := True
global g_NMAlvlObj
global NMA_WallRestart
global g_NMAHighestZone := 1
global g_NMATimeAtWall := 0
global NMA_CompleteAlert
global NMA_CompleteAlertBeep

global g_NMASpecSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\SpecSettings.json" )
if !IsObject(g_NMASpecSettings)
{
    g_NMASpecSettings := {}
    g_NMASpecSettings.TimeStamp := ""
}
global g_NMAMaxLvl := g_SF.LoadObjectFromJSON( A_LineFile . "\..\MaxLvl.json" )
if !IsObject(g_NMAMaxLvl)
{
    g_NMAMaxLvl := {}
    g_NMAMaxLvl.TimeStamp := ""
}

Gui, ICScriptHub:Tab, No Modron Adventuring
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, x15 y+10, BETA - No Modron Adventuring
Gui, ICScriptHub:Add, Text, x15 y+2, No Modron Leveling, Specing, Ulting, and Resetting
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, x15 y+5, NOTE: This add on will take control of the mouse to select specializations.
Gui, ICScriptHub:Add, Text, x15 y+10, NOTE: This add on will close the game to restart an adventure.
Gui, ICScriptHub:Add, Text, x15 y+10, NOTE: This add on does not save all settings on script restart.
Gui, ICScriptHub:Add, Text, x15 y+10, Specialization Settings Status: 
Gui, ICScriptHub:Add, Text, x+5 vNMA_Settings w300, % g_NMASpecSettings.TimeStamp ? "Loaded and dated " . g_NMASpecSettings.TimeStamp : "Not Loaded"
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gNMA_SpecSettings, Select/Create Spec. Settings
Gui, ICScriptHub:Add, Text, x15 y+10, Max. Level Data Status: 
Gui, ICScriptHub:Add, Text, x+5 vNMA_MaxLvl w300, % g_NMAMaxLvl.TimeStamp ? "Loaded and dated " . g_NMAMaxLvl.TimeStamp : "Not Loaded"
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gNMA_BuildMaxLvlData, Load Max. Level Data
Gui, ICScriptHub:Add, Text, x15 y+15, Choose area to restart the adventure at:
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNMA_RestartZone x210 y+-17 w60, % g_NMAResetZone
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Checkbox, vNMA_CB1 x15 y+-5 Checked Hidden, "Q"
Gui, ICScriptHub:Add, Checkbox, x15 y+10 vNMA_WallRestart , Reset at Wall after
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNMA_WallTimer x125 y+-17 w60, % g_NMAWallTime
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, x190 y+-17, (ms) has passed on the highest zone
Gui, ICScriptHub:Add, Checkbox, x15 y+10 vNMA_CompleteAlert , Popup when zone
GUIFunctions.UseThemeTextColor("InputBoxTextColor")
Gui, ICScriptHub:Add, Edit, vNMA_AlertZone x125 y+-17 w60, % g_NMAAlertZone
GUIFunctions.UseThemeTextColor()
Gui, ICScriptHub:Add, Text, x190 y+-17, has been reached (it will only do this once)
Gui, ICScriptHub:Add, Checkbox, x15 y+10 vNMA_CompleteAlertBeep , Play a sound when the above zone has been reached

Gui, ICScriptHub:Add, Checkbox, x15 y+20 vNMA_ChooseSpecs , Choose Specialisations
Gui, ICScriptHub:Add, Checkbox, x15 y+5 vNMA_LevelClick , Upgrade Click Damage
Gui, ICScriptHub:Add, Checkbox, x15 y+5 vNMA_FireUlts , Fire Ultimates     Ignore Ults:
Gui, ICScriptHub:Add, Checkbox, x170 y+-13 vNMA_UltsIgnoreSelise , Selise
Gui, ICScriptHub:Add, Checkbox, x230 y+-13 vNMA_UltsIgnoreHavilar , Havilar
Gui, ICScriptHub:Add, Checkbox, x290 y+-13 vNMA_UltsIgnoreNERDs , NERDs
Gui, ICScriptHub:Add, Checkbox, x350 y+-13 vNMA_UltsIgnoreEllywick , Ellywick
Gui, ICScriptHub:Add, Button, x15 y+10 w160 gNMA_RunAdventuring, Start Modronless Adventuring
Gui, ICScriptHub:Add, Text, x15 y+15 w300, Stop Adventuring button may need to be pushed multple times. Click until box pops up.
Gui, ICScriptHub:Add, Button, x15 y+10 w100 gNMA_StopAdventuring, Stop Adventuring
Gui, ICScriptHub:Font, w700
Gui, ICScriptHub:Add, Text, vNMA_Stats x15 y+25 w300, 
Gui, ICScriptHub:Font, w400
Gui, ICScriptHub:Add, Text, vNMA_WallZone x15 y+10 w300,  
Gui, ICScriptHub:Add, Text, vNMA_TimeAtWall x15 y+5 w300,  

NMA_StopAdventuring()
{
    global g_NMADoAdventuring := False
	GuiControl,,NMA_Stats, 
	GuiControl,,NMA_WallZone, 
	GuiControl,,NMA_TimeAtWall, 
}

NMA_RunAdventuring()
{
    global
    g_NMADoAdventuring := True
    g_NMAPickedSpecs := {}   
    if !(g_NMAMaxLvl.TimeStamp)
    {
        msgbox, Max level data not found, click Load Max. Level Data first.
        return
    }
    if !(g_NMASpecSettings.TimeStamp)
    {
        msgbox, Specialization settings not found, click Select/Create Spec. Settings first.
        return
    }   
    g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings["ExeName"])
    g_SF.Memory.OpenProcessReader()
    g_NMAlvlObj := new IC_NMA_Functions   
    Gui, ICScriptHub:Submit, NoHide
    g_NMAResetZone := NMA_RestartZone  
    formationKey := {1:"q"}
    favoriteFormation := 1
    g_NMAChampsToLevel := g_NMAlvlObj.NMA_GetChampionsToLevel(formationKey)
    g_SF.PatronID := 0
    g_ServerCall.activePatronID := 0
    startTime := IC_NMA_Functions.GetTickCount()
    g_NMATimeAtWall := 0
    g_NMAHighestZone := 1
    g_NMAWallTime := NMA_WallTimer
    g_NMAAlertZone := NMA_AlertZone
    while (g_NMADoAdventuring)
    {
        if (NMA_WallRestart)
            NMA_UpdateSettings()
        g_SF.DirectedInput(,, formationKey[favoriteFormation])
        Sleep, 50
        specPickedThisLoop := false
        for champID, isDone in g_NMAChampsToLevel
        {
            if (!g_NMADoAdventuring)
                break
            if (specPickedThisLoop)
                break
            if (champID == -1 OR !champID)
                continue
            if (isDone == True)
                continue
            ; Read level BEFORE leveling
            prevLvl := g_SF.Memory.ReadChampLvlByID(champID)
            ; Level the champ
            seat := g_SF.Memory.ReadChampSeatByID(champID)
            inputKey := "{F" . seat . "}"
            g_SF.DirectedInput(,, inputKey)
            Sleep, 50
            ; Read level AFTER leveling
            champLvl := g_SF.Memory.ReadChampLvlByID(champID)
            ; Only check for spec if THIS champion JUST passed a spec level
            if (NMA_ChooseSpecs && g_NMASpecSettings.HasKey(champID))
            {
                for k, v in g_NMASpecSettings[champID]
                {
                    specKey := champID . "_" . v.RequiredLvl
                    if (g_NMAPickedSpecs.HasKey(specKey))
                        continue
                    ; Only trigger if we JUST crossed the spec level
                    if (prevLvl < v.RequiredLvl && champLvl >= v.RequiredLvl)
                    {
                        Sleep, 200
                        g_NMAlvlObj.PickSpec(champID, v.Choice, v.Choices)
                        g_NMAPickedSpecs[specKey] := true
                        specPickedThisLoop := true
                        Sleep, 200
                        break
                    }
                }
            }
            if (champLvl >= g_NMAMaxLvl[champID])
                g_NMAChampsToLevel[champID] := True
        }
        if (NMA_LevelClick)
            g_SF.DirectedInput(,, "{ClickDmg}")
        if (!Mod(g_SF.Memory.ReadCurrentZone(), 5) AND Mod(g_SF.Memory.ReadHighestZone(), 5) AND !g_SF.Memory.ReadTransitioning())
            g_SF.ToggleAutoProgress(1, true)
        g_SF.ToggleAutoProgress(1, false)
        if (NMA_FireUlts)
            g_NMAlvlObj.NMA_UseUltimates(favoriteFormation)
        g_NMATimeAtWall := IC_NMA_Functions.GetTickCount() - startTime
        if (g_SF.Memory.ReadHighestZone() > g_NMAHighestZone)
        {
            startTime := IC_NMA_Functions.GetTickCount()
            g_NMATimeAtWall := 0
            g_NMAHighestZone := g_SF.Memory.ReadHighestZone()
        }
        if (g_SF.Memory.ReadHighestZone() >= g_NMAAlertZone)
        {
            if (NMA_CompleteAlertBeep)
            {
                loop, 5
                {
                    SoundBeep, 860, 400
                    SoundBeep, 1000, 400
                }
                SoundBeep, 860, 400
                NMA_CompleteAlertBeep := false
            }
            if (NMA_CompleteAlert)
            {
                msgbox, No Modron Adventuring:`n`nYou've reached zone %g_NMAAlertZone%.
                NMA_CompleteAlert := false
            }
        }
        isReset := g_NMAlvlObj.NMA_CheckForReset()
        if (isReset)
        {
            startTime := IC_NMA_Functions.GetTickCount()
            g_NMATimeAtWall := 0
            g_NMAHighestZone := 1
            g_NMAWallTime := NMA_WallTimer
            g_NMAPickedSpecs := {}
            g_SF.SafetyCheck()
            g_SF.Memory.OpenProcessReader()
            g_NMAChampsToLevel := g_NMAlvlObj.NMA_GetChampionsToLevel(formationKey)
        }
        Sleep, 50
    }
    MsgBox, Adventuring Stopped.
    return
}

NMA_UpdateSettings()
{
	GuiControl,,NMA_Stats,Wall Info:
	GuiControl,,NMA_WallZone,Wall Zone: %g_NMAHighestZone%
	GuiControl,,NMA_TimeAtWall,Time at Wall: %g_NMATimeAtWall%
}

NMA_SpecSettings()
{
    GuiControl, ICScriptHub:, NMA_Settings, Processing data, please wait...
    g_NMAHeroDefines := IC_NMA_Functions.GetHeroDefines()
    NMA_BuildSpecSettingsGUI()
    Gui, SpecSettingsGUI:Show
    GUIFunctions.UseThemeTitleBar("SpecSettingsGUI")
    GuiControl, ICScriptHub:, NMA_Settings, % g_NMASpecSettings.TimeStamp ? "Loaded and dated " . g_NMASpecSettings.TimeStamp : "Not Loaded"
}

NMA_BuildMaxLvlData()
{
    GuiControl, ICScriptHub:, NMA_MaxLvl, Processing data, please wait...
    g_NMAHeroDefines := IC_NMA_Functions.GetHeroDefines()
    g_NMAMaxLvl := {}
    for k, v in g_NMAHeroDefines
    {
        if v.MaxLvl
            g_NMAMaxLvl[k] := v.MaxLvl
    }
    g_NMAMaxLvl.TimeStamp := A_MMMM . " " . A_DD . ", " . A_YYYY . ", " . A_Hour . ":" . A_Min . ":" . A_Sec
    g_SF.WriteObjectToJSON(A_LineFile . "\..\MaxLvl.JSON", g_NMAMaxLvl)
    GuiControl, ICScriptHub:, NMA_MaxLvl, % g_NMAMaxLvl.TimeStamp ? "Loaded and dated " . g_NMAMaxLvl.TimeStamp : "Not Loaded"
}

NMA_BuildSpecSettingsGUI()
{
    global
    Gui, SpecSettingsGUI:New
    Gui, SpecSettingsGUI:+Resize -MaximizeBox
    GUIFunctions.LoadTheme("SpecSettingsGUI")
    GUIFunctions.UseThemeBackgroundColor()
    GUIFunctions.UseThemeTextColor()
    Gui, SpecSettingsGUI:Font, q5
    Gui, SpecSettingsGUI:Add, Button, x554 y25 w60 gNMA_SaveClicked, Save
    Gui, SpecSettingsGUI:Add, Button, x554 y+25 w60 gNMA_CloseClicked, Close
    Gui, SpecSettingsGUI:Add, Tab3, x5 y5 w539, Seat 1|Seat 2|Seat 3|Seat 4|Seat 5|Seat 6|Seat 7|Seat 8|Seat 9|Seat 10|Seat 11|Seat 12|
    seat := 1
    loop, 12
    {
        Gui, Tab, Seat %seat%
        Gui, SpecSettingsGUI:Font, w700 s11
        Gui, SpecSettingsGUI:Add, Text, x15 y35, Seat %Seat% Champions:
        Gui, SpecSettingsGUI:Font, w400 s9
        for champID, define in g_NMAHeroDefines
        {
            if (define.Seat == seat)
            {
                name := define.HeroName
                Gui, SpecSettingsGUI:Font, w700
                Gui, SpecSettingsGUI:Add, Text, x15 y+10, Name: %name%    `ID: %champID%
                Gui, SpecSettingsGUI:Font, w400
                prevUpg := 0
                for key, set in define.SpecDefines.setList
                {
                    reqLvl := set.reqLvl
                    ddlString := define.SpecDefines.DDL[reqLvl, prevUpg]
                    choice := 0
                    for k, v in g_NMASpecSettings[champID]
                    {
                        if (v.requiredLvl == reqLvl)
                            choice := v.Choice
                    }
                    if !choice
                        choice := 1
                    Gui, SpecSettingsGUI:Add, DropDownList, x15 y+5 vNMA_%champID%Spec%reqLvl% Choose%choice% AltSubmit gNMA_UpdateDDL, %ddlString%
                    prevUpg := define.SpecDefines.SpecDefineList[reqLvl, prevUpg][choice].UpgradeID
                }
            }
        }
        ++seat
    }
    Return
}

;close spec settings GUI
NMA_CloseClicked()
{
    Gui, SpecSettingsGUI:Hide
    Return
}

;save button function from GUI built as part of NMA_BuildSpecSettingsGUI()
NMA_SaveClicked()
{
    Gui, SpecSettingsGUI:Submit, NoHide
    For champID, define in g_NMAHeroDefines
    {
        g_NMASpecSettings[champID] := {}
        prevUpg := 0
        for k, v in define.SpecDefines.setList
        {
            reqLvl := v.reqLvl
            choice := NMA_%champID%Spec%reqLvl%
            position := g_NMASpecSettings[champID].Push(define.SpecDefines.SpecDefineList[reqLvl, prevUpg][choice].Clone())
            g_NMASpecSettings[champID][position].Choice := choice
            g_NMASpecSettings[champID][position].Choices := define.SpecDefines.SpecDefineList[reqLvl, prevUpg].Count()
            prevUpg := g_NMASpecSettings[champID][position].UpgradeID
        }
    }
    g_NMASpecSettings.TimeStamp := A_MMMM . " " . A_DD . ", " . A_YYYY . ", " . A_Hour . ":" . A_Min . ":" . A_Sec
    g_SF.WriteObjectToJSON(A_LineFile . "\..\SpecSettings.JSON", g_NMASpecSettings)
    GuiControl, ICScriptHub:, NMA_Settings, % g_NMASpecSettings.TimeStamp ? "Loaded and dated " . g_NMASpecSettings.TimeStamp : "Not Loaded"
    Return
}

NMA_UpdateDDL()
{
    Gui, SpecSettingsGUI:Submit, NoHide
    choice := %A_GuiControl%
    foundPos := InStr(A_GuiControl, "S")
    champID := SubStr(A_GuiControl, 5, foundPos - 5) + 0
    foundPos := InStr(A_GuiControl, "Spec")
    reqLvl := SubStr(A_GuiControl, foundPos + 4) + 0
    ;need previous upgrade id to get current upgrade id
    prevUpg := 0
    for k, v in g_NMASpecSettings[champID]
    {
        if (v.requiredLvl < reqLvl)
            prevUpg := v.UpgradeID
    }
    prevUpg := g_NMAHeroDefines[champID].SpecDefines.SpecDefineList[reqLvl, prevUpg][choice].UpgradeID
    for k, v in g_NMAHeroDefines[champID].SpecDefines.setList
    {
        requiredLvl := v.reqLvl
        if (v.listCount > 1 AND requiredLvl > reqLvl)
        {
            ddlString := "|"
            ddlString .= g_NMAHeroDefines[champID].SpecDefines.DDL[requiredLvl, prevUpg]
            GuiControl, SpecSettingsGUI:, NMA_%champID%Spec%requiredLvl%, %ddlString%
            GuiControl, SpecSettingsGUI:Choose, NMA_%champID%Spec%requiredLvl%, 1
            prevUpg := g_NMAHeroDefines[champID].SpecDefines.SpecDefineList[requiredLvl, prevUpg][1].UpgradeID
        }
    } 
}

;$SC045::
;Pause

Hotkey, SC045, NMA_Pause ;numlock to pause

NMA_Pause()
{
    Pause
}
