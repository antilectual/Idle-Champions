; Test to see if BrivGemFarm addon is available.

IC_BrivGemFarm_HybridTurboStacking_Functions.InjectAddon()
global g_HybridTurboStacking := new IC_BrivGemFarm_HybridTurboStacking_Component
global g_HybridTurboStackingGui := new IC_BrivGemFarm_HybridTurboStacking_GUI
g_HybridTurboStacking.Init()

/*  IC_BrivGemFarm_HybridTurboStacking_Component

    Class that manages the GUI for HybridTurboStacking.
    Starts automatically on script launch and waits for Briv Gem Farm to be started,
    then stops/starts every time buttons on the main Briv Gem Farm window are clicked.
*/
Class IC_BrivGemFarm_HybridTurboStacking_Component
{
    static MAX_MELF_FORECAST_ROWS := 1000

    Settings := ""
    TimerFunction := ObjBindMethod(this, "UpdateStatus")
    Forecast := ""
    CurrentReset := 1

    Init()
    {
        g_HybridTurboStackingGui.Init()
        this.LoadSettings()
        ; Update loop
        g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(this, "Start"))
        g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(this, "Stop"))
        this.Start()
    }

    ; Load saved or default settings.
    LoadSettings()
    {
        needSave := false
        default := this.GetDefaultSettings()
        this.Settings := settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_HybridTurboStacking_Functions.SettingsPath)
        if (!IsObject(settings))
            needSave := true, (this.Settings := settings := default)
        else
        {
            postDelSettings := g_SF.DeleteExtraSettings(settings, default)
            needSave := (postDelSettings != "")
            if (needSave)
                settings := postDelSettings
        }
        if (needSave)
            this.SaveSettings()
        this.CurrentReset := settings.CurrentReset
        ; Set the state of GUI buttons with saved settings.
        g_HybridTurboStackingGui.UpdateGUISettings(settings)
    }

    ; Returns an object with default values for all settings.
    GetDefaultSettings()
    {
        settings := {}
        settings.Enabled := false
        settings.CompleteOnlineStackZone := true
        settings.WardenUltThreshold := 50
        settings.FaridehUltThreshold := 50
        settings.BrivAutoHeal := 50
        settings.Multirun := false
        settings.MultirunTargetStacks := g_BrivUserSettings[ "TargetStacks" ]
        settings.MultirunDelayOffline := true
        settings.100Melf := false
        settings.MelfMinStackZone := g_BrivUserSettings[ "StackZone" ] + 1
        last := IC_BrivGemFarm_Class.BrivFunctions.GetLastSafeStackZone()
        settings.MelfMaxStackZone := last != "" ? last : 1949
        settings.MelfActiveStrategy := 1
        settings.MelfInactiveStrategy := 1
        settings.PreferredBrivStackZones := 544790277504495
        settings.CurrentReset := 1
        return settings
    }

    UpdateSetting(setting, value)
    {
        this.Settings[setting] := value
    }

    ; Save settings.
    SaveSettings()
    {
        settings := this.Settings
        settings.PreferredBrivStackZones := this.GetPreferredBrivStackZones()
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_HybridTurboStacking_Functions.SettingsPath, settings)
        GuiControl, ICScriptHub:Text, BGFHTS_StatusText, Settings saved
        ; Apply settings to BrivGemFarm
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.BGFHTS_UpdateSettingsFromFile()
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BGFHTS_StatusText, Waiting for Gem Farm to start
        }
        this.UpdateMelfForecast(true)
    }

    SaveGUISettings()
    {
        settings := this.Settings
        settings.CurrentReset := this.CurrentReset
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_HybridTurboStacking_Functions.SettingsPath, settings)
    }

    Start()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, 500, 0
    }

    Stop()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, Off
        GuiControl, ICScriptHub:Text, BGFHTS_StatusText, Not Running
        GuiControl, ICScriptHub:Hide, BGFHTS_StatusWarning
    }

    ; GUI update loop.
    UpdateStatus()
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            if (SharedRunData.BGFHTS_Running == "")
            {
                this.Stop()
                GuiControl, ICScriptHub:Show, BGFHTS_StatusWarning
                str := "BrivGemFarm HybridTurboStacking addon was loaded after Briv Gem Farm started.`n"
                MsgBox, % str . "If you want it enabled, press Stop/Start to retry."
            }
            else if (SharedRunData.BGFHTS_Running)
            {
                data := {}
                data.CurrentRunEffects := SharedRunData.BGFHTS_CurrentRunEffects
                data.CurrentRunStackRange := SharedRunData.BGFHTS_CurrentRunStackRange
                data.PreviousStackZone := SharedRunData.BGFHTS_PreviousStackZone
                data.BrivDeaths := SharedRunData.BGFHTS_BrivDeaths
                data.BrivHeals := SharedRunData.BGFHTS_BrivHeals
                g_HybridTurboStackingGui.UpdateGUI(data)
                status := SharedRunData.BGFHTS_Status
                str := "Running" . (status != "" ? " - " . status : "")
                GuiControl, ICScriptHub:Text, BGFHTS_StatusText, % str
                str := SharedRunData.BGFHTS_StacksPredictionActive ? "On" : "Off"
                GuiControl, ICScriptHub:Text, BGFHTS_StacksPredictActive, % str
                targetStacks := g_BrivUserSettings[ "TargetStacks" ]
                if (SharedRunData.BGFHTS_StacksPredictionActive)
                {
                    stacks := SharedRunData.BGFHTS_SBStacksPredict
                    GuiControl, ICScriptHub:Text, BGFHTS_StacksPredict, % Floor(stacks)
                    settings := this.Settings
                    if (settings.Multirun && stacks - g_SF.Memory.ReadSBStacks() < targetStacks)
                        targetStacks := settings.MultirunTargetStacks
                    value := Max(0, targetStacks - stacks)
                    GuiControl, ICScriptHub:Text, BGFHTS_SBStacksNeeded, % value
                }
                else
                {
                    GuiControl, ICScriptHub:Text, BGFHTS_StacksPredict,
                    stacks := g_SF.Memory.ReadSBStacks() + 48
                    value := Max(0, targetStacks - stacks)
                    GuiControl, ICScriptHub:Text, BGFHTS_SBStacksNeeded, % value
                }
            }
            else
                GuiControl, ICScriptHub:Text, BGFHTS_StatusText, Disabled
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BGFHTS_StatusText, Waiting for Gem Farm to start
        }
        this.UpdateMelfForecast()
    }

    GetCurrentReset()
    {
        resets := g_SF.Memory.ReadResetsTotal()
        if (resets > 0 && resets != this.CurrentReset)
        {
            this.CurrentReset := resets
            this.SaveGUISettings()
        }
        return resets > 0 ? resets : this.CurrentReset
    }

    UpdateMelfForecast(updateRange := false)
    {
        resets := this.GetCurrentReset()
        if (resets == "")
            return
        g_HybridTurboStackingGui.UpdateResets(resets)
        if (!g_HybridTurboStackingGui.AllowForecastUpdate)
            return
        forecast := (this.Forecast == "" || updateRange) ? [] : this.Forecast
        minIndex := forecast[1][1] == "" ? 0 : forecast[1][1]
        ; Don't update when it is not needeed.
        difference := resets - minIndex
        if (difference == 0 && minIndex != 0)
            return
        if (minIndex > 0)
        {
            ; Delete values before current reset.
            Loop, % difference
                forecast.RemoveAt(1)
        }
        ; Update remaining values.
        newValues := []
        maxRows := this.MAX_MELF_FORECAST_ROWS
        firstReset := minIndex == 0 ? resets : resets + maxRows - 1
        Loop, % Min(maxRows, difference)
        {
            reset := firstReset + A_Index - 1
            row := IC_BrivGemFarm_HybridTurboStacking_Melf.GetAllEffects(reset)
            row.InsertAt(1, reset)
            newValues.Push(row)
        }
        forecast.Push(newValues*)
        this.Forecast := forecast
        minZone := this.settings.MelfMinStackZone
        maxZone := this.settings.MelfMaxStackZone
        success := IC_BrivGemFarm_HybridTurboStacking_Melf.GetNumberOfSuccessesInRange(resets, maxRows, minZone, maxZone)
        g_HybridTurboStackingGui.UpdateForecast(newValues, minZone, maxZone, success)
    }

    ; Read the state of the mod50 checkboxes for Preferred Briv Stack Zones.
    ; Parameters: - toArray:bool - If true, returns an array, else returns a bitfield.
    GetPreferredBrivStackZones(toArray := false)
    {
        rootControlID := "BGFHTS_BrivStack_Mod_50_"
        array := []
        value := 0
        Loop, 50
        {
            ; Disable stacking in a boss zone.
            if (Mod(A_Index, 5) == 0)
                isChecked := false
            else
                GuiControlGet, isChecked, ICScriptHub:, %rootControlID%%A_Index%
            array.Push(isChecked)
            if (isChecked)
                value += 2 ** (A_Index - 1)
        }
        return toArray ? array : value
    }
}