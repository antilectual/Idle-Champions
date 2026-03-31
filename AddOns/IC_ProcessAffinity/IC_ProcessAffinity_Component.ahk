#include %A_LineFile%\..\IC_ProcessAffinity_Functions.ahk

GUIFunctions.AddTab("Process Affinity")
; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Process Affinity

GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
Gui, ICScriptHub:Add, Text, Section vProcessAffinityStatus, Status:
Gui, ICScriptHub:Add, Text, x+5 w170 vProcessAffinityStatusText, Not Running
GUIFunctions.UseThemeTextColor("WarningTextColor", 700)

Gui, ICScriptHub:Add, Text, xs ys+15 Hidden vProcessAffinityStatusWarning, WARNING: Addon was loaded too late. Stop/start Gem Farm to resume.
GUIFunctions.UseThemeTextColor()

xSpacing := 10
Gui, ICScriptHub:Add, Button, xs ys+35 Disabled vProcessAffinityLoad gProcessAffinityLoad, Load
Gui, ICScriptHub:Add, Button, x+%xSpacing% Disabled vProcessAffinitySave gProcessAffinitySave, Save
Gui, ICScriptHub:Add, Text, x+%xSpacing% yp+5 w125 vProcessAffinityText

GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
Gui, ICScriptHub:Add, Text, vProcessAffinityCoreText xs ys+70, Core affinity:
GUIFunctions.UseThemeTextColor()

GUIFunctions.UseThemeTextColor("TableTextColor")
EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
hCols := Min(ProcessorCount + 1, 33)
Gui, ICScriptHub:Add, ListView, AltSubmit Checked Disabled -Hdr -Multi R%hCols% xs y+10 w120 vProcessAffinityView gProcessAffinityView, CoreID
GUIFunctions.UseThemeListViewBackgroundColor("ProcessAffinityView")

OnMessage(0x200, Func("ProcessAffinity_CheckMouseEvent"))

ProcessAffinity_CheckMouseEvent(W)
{
    IC_ProcessAffinity_Component.OnMouseOver(W)
}

; Load button
ProcessAffinityLoad()
{
    restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ProcessAffinityView")
    LV_Delete()
    IC_ProcessAffinity_Component.ReloadCheckboxes()
    Sleep, 50
    GuiControl, ICScriptHub:Text, ProcessAffinityText, Settings loaded.
}

; Save button
ProcessAffinitySave()
{
    IC_ProcessAffinity_Component.SaveSettings()
    GuiControl, ICScriptHub:Text, ProcessAffinityText, Settings saved.
}

; ViewList
ProcessAffinityView()
{
    if (A_GuiEvent == "I")
    {
        if (InStr(ErrorLevel, "C", true))
            IC_ProcessAffinity_Component.Update(A_EventInfo, 1)
        else if (InStr(ErrorLevel, "c", true))
            IC_ProcessAffinity_Component.Update(A_EventInfo, 0)
    }
    GuiControl, ICScriptHub:Text, ProcessAffinityText,
}

; Test to see if BrivGemFarm addon is avaialbe.
if(IsObject(IC_BrivGemFarm_Component))
{
    IC_ProcessAffinity_Functions.InjectAddon()
    global g_ProcessAffinity := new IC_ProcessAffinity_Component
    IC_ProcessAffinity_Component.Init()
}
else
{
    GuiControl, ICScriptHub:Text, ProcessAffinityStatusWarning, WARNING: This addon needs IC_BrivGemFarm enabled.
    GuiControl, ICScriptHub:Show, ProcessAffinityStatusWarning
}

/*  IC_ProcessAffinity_Component

    Class that manages the GUI for process affinity settings.
    The first checkbox is a toggle button.
    The other checkboxes set affinity to any number > 0 of available processor cores (physical/logical) for IdleDragons.exe.
    Overrides ICScriptHub.ahk's "Launch Idle Champions" button.
*/
Class IC_ProcessAffinity_Component
{
    StatusUpdatedOnLaunch := false

    ; Start up the GUI
    Init()
    {
        EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
        if (ProcessorCount == 0)
        {
            GuiControl, ICScriptHub:, ProcessAffinityText, No cores found.
            return
        }
        else if (ProcessorCount > 64) ; TODO: Support for CPU Groups
        {
            GuiControl, ICScriptHub:, ProcessAffinityText, > 64 CPUs not supported.
            return
        }
        GuiControl, ICScriptHub:Enable, ProcessAffinityLoad
        GuiControl, ICScriptHub:Enable, ProcessAffinitySave
        GuiControl, ICScriptHub:Enable, ProcessAffinityView
        IC_ProcessAffinity_Functions.Init(true)
        ProcessAffinityLoad()
        this.SaveSettings(true)
        this.CreateTimedFunctions()
        this.Start()
    }

    ; Adds timed functions to be run when briv gem farm is started or stopped
    CreateTimedFunctions()
    {
        fncToCallOnTimer := ObjBindMethod(this, "UpdateStatusStart")
        g_BrivFarmComsObj.OneTimeRunAtStartFunctions[fncToCallOnTimer] := -1
        fncToCallOnTimer := ObjBindMethod(this, "UpdateStatusStop")
        g_BrivFarmComsObj.OneTimeRunAtEndFunctions[fncToCallOnTimer] := -1
    }

    UpdateStatusStart()
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            if (!SharedRunData.ProcessAffinityRunning())
            {
                this.Stop()
                GuiControl, ICScriptHub:Show, ProcessAffinityStatusWarning
                GuiControl, ICScriptHub:Text, ProcessAffinityStatusText, Not Running
                str := "ProcessAffinity addon was loaded after Briv Gem Farm started.`n"
                MsgBox, % str . "If you want it enabled, press Stop/Start to retry."
            }
            else
                GuiControl, ICScriptHub:Text, ProcessAffinityStatusText, Running
        }
    }

    UpdateStatusStop()
    {
        GuiControl, ICScriptHub:Text, ProcessAffinityStatusText, Waiting for Gem Farm to start
        GuiControl, ICScriptHub:Hide, ProcessAffinityStatusWarning
    }

    ; Builds checkboxes for CoreAffinity
    ReloadCheckboxes()
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ProcessAffinityView")
        processorCount := IC_ProcessAffinity_Functions.ProcessorCount
        LV_Add(, "All processors") ; Create unchecked boxes
        Loop, % processorCount
            LV_Add(, "CPU " . A_Index - 1)
        settings := IC_ProcessAffinity_Functions.Affinity
        Loop, % processorCount ; Check boxes
        {
            checked := (settings & (2 ** (A_Index - 1))) != 0
            if (checked)
                LV_Modify(A_Index + 1, "Check")
        }
        LV_ModifyCol(, 1) ; Hide horizontal scroll bar
    }

    ; Saves settings to addon's setting.json file.
    SaveSettings(firstSave := false)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ProcessAffinityView")
        coreMask := 0, rowNumber := 1
        Loop ; Sum up all checked boxes as an integer || signed int for 64 cores
        {
            nextChecked := LV_GetNext(RowNumber, "C")
            if (not nextChecked)
                break
            rowNumber := nextChecked
            coreMask += 2 ** (rowNumber - 2)
        }
        if (coremask == 0 OR !firstSave AND (coremask == IC_ProcessAffinity_Functions.Affinity))
            return
        ; g_SF.WriteObjectToJSON( A_LineFile . "\..\ProcessAffinitySettings.json", this.Settings ) doesn't work with 64 cores
        str := "{`n`t""ProcessAffinityMask"":""" . coremask . """`n}"
        path := IC_ProcessAffinity_Functions.SettingsPath
        FileDelete, %path%
        FileAppend, % str, %path%
        this.SetAllAffinities(coremask)
    }

    ; Sets the appropriate affinities to the game and scripts
    SetAllAffinities(affinity := 0)
    {
        IC_ProcessAffinity_Functions.UpdateAffinities(affinity, true)
        ; Override ICScriptHub.ahk's "Launch Idle Champions" button to set the game's affinity, check for compatibility
        f := ObjBindMethod(g_ProcessAffinity, "Launch_Clicked_Affinity")
        GuiControl,ICScriptHub: +g, LaunchClickButton, % f
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.ProcessAffinity_UpdateAffinity(affinity)
        }
        catch
        {
            GuiControl, ICScriptHub:Text, ProcessAffinityStatusText, Waiting for Gem Farm to start
        }
    }

    ; Set affinity after clicking ICScriptHub.ahk's "Launch Idle Champions" button
    Launch_Clicked_Affinity()
    {
        Launch_Clicked()
        IC_ProcessAffinity_Functions.SetProcessAffinity(g_SF.PID) ; IdleDragons.exe
    }

    ; Update checkboxes
    Update(checkBoxIndex := 0, on := 1)
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ProcessAffinityView")
        if (checkBoxIndex == 1) ; Toggle all checkbox
            this.ToggleAllCores(on)
        else if (!on)
            LV_Modify(1, "-Check")
        if (this.AreAllCoresChecked() AND (LV_GetNext(,"Checked") == 2))
            LV_Modify(1, "Check")
        if (LV_GetNext(, "Checked") == 0) ; Disable save if no cores are selected
            GuiControl, Disable, ProcessAffinitySave
        else
            GuiControl, Enable, ProcessAffinitySave
    }

    ; Toggle all cores, toggle on if at least one core was previously unchecked
    ToggleAllCores(on := 1)
    {
        if (!on AND !this.AreAllCoresChecked())
            return
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ProcessAffinityView")
        Loop % LV_GetCount() - 1 ; Skip the toggle all checkbox
            LV_Modify(A_Index + 1, on ? "Check" : "-Check")
    }

    ; Returns true if all the core checkboxes are checked
    AreAllCoresChecked()
    {
        restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "ProcessAffinityView")
        rowNumber := 1 ; This causes the first loop iteration to start the search at the top of the list.
        Loop
        {
            nextChecked := LV_GetNext(rowNumber, "C")
            if (nextChecked - rowNumber > 1) ; Skipped over an unchecked box
                return false
            if (not rowNumber OR rowNumber == LV_GetCount()) ; There are no more selected rows.
                return true
            rowNumber := nextChecked ; Resume the search at the row after that found by the previous iteration.
        }
        return false
    }

    ; Update status on script launch
    OnMouseOver(W)
    {
        if (this.StatusUpdatedOnLaunch)
            return
        GuiControlGet, CurrentTab,, ModronTabControl, Tab
        if (CurrentTab == "Process Affinity")
        {
            this.UpdateStatusStart()
            this.StatusUpdatedOnLaunch := true
        }
    }
}