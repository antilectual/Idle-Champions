#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_GUI.ahk

; Test to see if BrivGemFarm addon is available.
if(IsObject(IC_BrivGemFarm_Component))
{
    IC_BrivGemFarm_BrivFeatSwap_Functions.InjectAddon()
    global g_BrivFeatSwap := new IC_BrivGemFarm_BrivFeatSwap_Component
    global g_BrivFeatSwapGui := new IC_BrivGemFarm_BrivFeatSwap_GUI
    g_BrivFeatSwapGui.SetupGroups()
    g_BrivFeatSwap.Init()
}
else
{
    GuiControl, ICScriptHub:Text, BGFBFS_StatusText, WARNING: This addon needs IC_BrivGemFarm enabled.
    return
}

/*  IC_BrivGemFarm_BrivFeatSwap_Component

    Class that manages the GUI for BrivFeatSwap.
    Starts automatically on script launch and waits for Briv Gem Farm to be started,
    then stops/starts every time buttons on the main Briv Gem Farm window are clicked.
*/
Class IC_BrivGemFarm_BrivFeatSwap_Component
{
    DetectedSkipAmount := ""
    DetectedSkipChance := ""
    DetectedResetArea := 2000
    DisableResetAreaUpdate := false
    DisableStacksRequiredUpdate := false
    SavedPreferredAdvancedSettings := 0
    Settings := ""
    TimerFunctions := ""
    CurrentPath := ""
    UpdateFeatSwapDisabled := False

    Init()
    {
        ; Save the state of the mod50 checkboxes for Preferred Briv Jump Zones in Advanced Settings tab.
        this.SavedPreferredAdvancedSettings := this.GetPreferredAdvancedSettings(true)
        this.SetupPresets()
        this.UpdateStatus()
        this.Settings := settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_BrivFeatSwap_Functions.SettingsPath)
        if (IsObject(settings))
        {
            if (!settings.HasKey("Enabled"))
                settings.Enabled := true
            GuiControl, ICScriptHub:, BGFBFS_Enabled, % settings.Enabled
            GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetQ, % settings.targetQ
            GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetE, % settings.targetE
            ; Fix preset settings from version v1.2.0
            settings.Preset == "5J/4J" ? settings.Preset := "5J/4J Tall Tales" : ""
            settings.Preset == "8J/4J" ? settings.Preset := "8J/4J Tall Tales" : ""
            settings.Preset == "8J/4J + walk 1/2/3/4" ? settings.Preset := "8J/4J Tall Tales + walk 1/2/3/4" : ""
            settings.Preset == "9J/4J" ? settings.Preset := "9J/4J Tall Tales" : ""
            GuiControl, ICScriptHub:ChooseString, BGFBFS_Preset, % settings.Preset
            this.LoadPreset(settings.Preset)
            BrivGemFarm_BrivFeatSwap_Save()
            if (settings.Preset)
                this.SaveMod50Preset()
        }
        else
            this.Settings := {}
        this.CreateTimedFunctions()
        g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(this, "Start"))
        g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(this, "Stop"))
        this.Start()
    }

    ; Adds timed functions to be run when briv gem farm is started
    CreateTimedFunctions()
    {
        this.TimerFunctions := {}
        fncToCallOnTimer := ObjBindMethod(this, "UpdateStatus")
        this.TimerFunctions[fncToCallOnTimer] := 185
    }

    Start()
    {
        for k,v in this.TimerFunctions
            SetTimer, %k%, %v%, 0
    }

    Stop()
    {
        for k,v in this.TimerFunctions
        {
            SetTimer, %k%, Off
            SetTimer, %k%, Delete
        }
        GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Not Running
        GuiControl, ICScriptHub:Hide, BGFBFS_StatusWarning
    }

    ; Update the GUI, try to read Q/W/E skip amounts
    UpdateStatus()
    {
        statusStart := A_TickCount
        if (this.UpdateFeatSwapDisabled)
            return
        this.UpdateFeatSwapDisabled := True
        this.UpdateDetectedSkipAmount()	
        this.GetModronResetArea()
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            if (SharedRunData.BGFBFS_Running == "")
            {
                this.Stop()
                GuiControl, ICScriptHub:Show, BGFBFS_StatusWarning
                str := "BrivGemFarm Briv Feat Swap addon was loaded after Briv Gem Farm started.`n"
                MsgBox, % str . "If you want it enabled, press Stop/Start to retry."
            }
            else if (SharedRunData.BGFBFS_Running)
            {
                GuiControl, ICScriptHub:Text, BGFBFS_StatusText, % "Running " . SharedRunData.BGFBFS_CurrentPreset
                GuiControl, ICScriptHub:Text, BrivFeatSwapQValue, % SharedRunData.BGFBFS_savedQSKipAmount
                GuiControl, ICScriptHub:Text, BrivFeatSwapWValue, % SharedRunData.BGFBFS_savedWSKipAmount
                GuiControl, ICScriptHub:Text, BrivFeatSwapEValue, % SharedRunData.BGFBFS_savedESKipAmount
                GuiControl, ICScriptHub:Text, BrivFeatSwapsMadeThisRunValue, % SharedRunData.SwapsMadeThisRun
            }
            else
                GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Disabled
        }
        catch err
        {
            GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Waiting for Gem Farm to start
        }
        statusStop := (A_TickCount - statusStart) / 1000
        this.UpdateFeatSwapDisabled := False
    }

    ; Returns true is the game is open.
    GameIsReady()
    {
        static memReadReady := false

        existingProcessID := g_UserSettings[ "ExeName"]
        Process, Exist, %existingProcessID%
        if (ErrorLevel)
        {
            if (!memReadReady)
            {
                g_SF.Memory.OpenProcessReader()
                memReadReady := true
            }
            return g_SF.Memory.ReadGameStarted()
        }
        else
            memReadReady := false
    }

    ; Update Briv skip amount/chance.
    ; Update messages shown if an incorrect preset is selected of if Briv is not 100% skip chance.
    ; Read the current Modron reset area at the same time.
    UpdateDetectedSkipAmount()
    {
        if (this.GameIsReady())
        {
            this.GetModronResetArea()
            skipValues := IC_BrivGemFarm_Class.BrivFunctions.GetBrivSkipValues()
            skipAmount := skipValues[1]
            skipChance := skipValues[2] * 100
            ; Only update if values changed
            noUpdate := skipAmount == this.LastSkipAmount && skipChance == this.LastSkipChance
            if (g_BrivFeatSwapGui.ToolTipAdded && noUpdate)
                return
            this.LastSkipAmount := skipAmount
            this.LastSkipChance := skipChance
            this.DetectedSkipAmount := skipAmount
            this.DetectedSkipChance := skipChance
            GuiControlGet, targetQ, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetQ
            this.UpdatePresetWarning(targetQ)
            if (skipChance == 100)
                skipStr := Format("{:.2f}", skipChance) . "%"
            else
                skipStr := Format("{:.6f}", skipChance) . "%"
            str := "Briv skip: " . skipAmount . "J" . skipStr
            GuiControl, ICScriptHub:, BGFBFS_DetectedText, % str
            g_BrivFeatSwapGui.AddBrivSkipTooltip()
        }
        else if (this.DetectedSkipAmount == "" || this.DetectedSkipChance == "")
            GuiControl, ICScriptHub:, BGFBFS_DetectedText, Briv skip: Game closed.
    }

    ; Save settings.
    ; Parameters: - targetQ:int - Target Briv skip value to look for when switching to Q formation.
    ;             - targetE:int - Target Briv skip value to look for when switching to E formation.
    Save(targetQ, targetE)
    {
        settings := this.Settings
        GuiControlGet, enabled, ICScriptHub:, BGFBFS_Enabled
        settings.Enabled := enabled
        settings.Preset := this.GetPresetName()
        this.SaveMod50Preset()
        if (IsObject(g_BrivGemFarm_LevelUp))
            g_BrivGemFarm_LevelUp.SaveSettings(true)
        settings.targetQ := targetQ
        settings.targetE := targetE
        g_SF.WriteObjectToJSON(IC_BrivGemFarm_BrivFeatSwap_Functions.SettingsPath, settings)
        GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Settings saved
        ; Apply settings to BrivGemFarm
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.BGFBFS_UpdateSettingsFromFile()
        }
        catch
        {
            GuiControl, ICScriptHub:Text, BGFBFS_StatusText, Waiting for Gem Farm to start
        }
    }

    ; Copy the state of the mod50 checkboxes for Preferred Briv Jump Zones in this addon's tab
    ; into the mod50 checkboxes in Advanced Settings tab, then reload and save.
    ; Doesn't save settings to the current profile.
    SaveMod50Preset()
    {
        g_BrivUserSettings[ "PreferredBrivJumpZones" ] := this.GetPreferredAdvancedSettings(, true)
        IC_BrivGemFarm_AdvancedSettings_Functions.LoadPreferredBrivJumpSettings()
        IC_BrivGemFarm_AdvancedSettings_Component.SaveAdvancedSettings()
    }

    ; Read the state of the mod50 checkboxes for Preferred Briv Jump Zones.
    ; Parameters: - advancedSettings:bool - If true, Advanced Settings, else this addon's settings.
    ;             - toArray:bool - If true, returns an array, else returns a bitfield.
    GetPreferredAdvancedSettings(advancedSettings := false, toArray := false)
    {
        rootControlID := (advancedSettings ? "PreferredBrivJumpSetting" : "BGFBFS_CopyPasteBGFAS_") . "Mod_50_"
        array := []
        value := 0
        Loop, 50
        {
            GuiControlGet, isChecked, ICScriptHub:, %rootControlID%%A_Index%
            array.Push(isChecked)
            if (isChecked)
                value += 2 ** (A_Index - 1)
        }
        return toArray ? array : value
    }

    ; Setup choices for the Presets ListBox.
    SetupPresets() ; TODO: Proper preset settings
    {
        choices := "||5J/4J Tall Tales|6J/4J Resolve Amongst Chaos|6J/4J Tall Tales|7J/4J Tall Tales|8J/4J Tall Tales"
        choices .= "|8J/4J Tall Tales + walk 1/2/3/4|8J/7J Tall Tales|9J/4J Tall Tales"
        choices .= "|12J/11J Tall Tales|14J/9J Tall Tales|16J/15J Tall Tales"
        GuiControl, ICScriptHub:, BGFBFS_Preset, % "|" . choices
        ; Resize
        newWidth := IC_BrivGemFarm_BrivFeatSwap_GUI.DropDownSize(choices,,, 8)
        GuiControlGet, hnwd, ICScriptHub:Hwnd, BGFBFS_Preset
        SendMessage, 0x0160, newWidth, 0,, ahk_id %hnwd% ; CB_SETDROPPEDWIDTH
    }

    ; Returns the name of the currently selected preset.
    GetPresetName()
    {
        GuiControlGet, presetName, ICScriptHub:, BGFBFS_Preset
        return presetName
    }

    ; Apply settings for a specific preset.
    ; Parameters: - name:str - Name of a preset shown in the Presets ListBox.
    LoadPreset(name)
    {
        ; Apply BrivMinLevelArea setting to BGFLU addon
        if (name == "8J/4J Tall Tales + walk 1/2/3/4" && IsObject(IC_BrivGemFarm_LevelUp_Component))
        {
            GuiControl, ICScriptHub:, BGFBFS_BrivMinLevelArea, 5
            GuiControl, ICScriptHub:, BGFLU_BrivMinLevelArea, 5
        }
        else
        {
            if (this.Settings.Preset == "8J/4J Tall Tales + walk 1/2/3/4")
                value := 1
            else
                value := g_BrivGemFarm_LevelUp.Settings.BrivMinLevelArea
            value := value == "" ? 1 : value
            GuiControl, ICScriptHub:, BGFBFS_BrivMinLevelArea, % value
            GuiControl, ICScriptHub:, BGFLU_BrivMinLevelArea, % value
        }
        Switch name
        {
            case "5J/4J Tall Tales":
                this.ApplyPresets(498342527128532, 5, 4)
            case "6J/4J Resolve Amongst Chaos":
                this.ApplyPresets(948417617686362, 6, 4)
            case "6J/4J Tall Tales":
                this.ApplyPresets(800122939009243, 6, 4)
            case "7J/4J Tall Tales":
                this.ApplyPresets(380222613385436, 7, 4)
            case "8J/4J Tall Tales":
                this.ApplyPresets(57952963557919, 8, 4)
            case "8J/4J Tall Tales + walk 1/2/3/4":
                this.ApplyPresets(57952963557919, 8, 4)
            case "8J/7J Tall Tales":
                this.ApplyPresets(878610951932870, 8, 7)
            case "9J/4J Tall Tales":
                this.ApplyPresets(35181131988031, 9, 4)
            case "12J/11J Tall Tales":
                this.ApplyPresets(554220480505760, 12, 11)
            case "14J/9J Tall Tales":
                this.ApplyPresets(1125899805626349, 14, 9)
            case "16J/15J Tall Tales":
                this.ApplyPresets(360709071052808, 16, 15)
            case default:
                this.ApplyPresets(this.SavedPreferredAdvancedSettings, this.Settings.targetQ, this.Settings.targetE)
        }
    }

    ; Apply temporary GUI settings for the selected preset.
    ; Parameters: - mod50Value:int - Bitfield representing checked values for each mod50 checkbox.
    ;             - targetQ:int - Value to apply to the targetQ edit field.
    ;             - targetE:int - Value to apply to the targetE edit field.
    ;             - default:bool - Used to toggle mod50 checkboxes. If true, hide mod50 checkboxes.
    ApplyPresets(mod50Value, targetQ, targetE, default := false)
    {
        GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetQ, % targetQ
        GuiControl, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetE, % targetE
        this.UpdatePresetWarning(targetQ)
        this.LoadMod50(mod50Value)
        this.ToggleMod50(true)
        this.ToggleBrivMinLevelArea()
        this.UpdatePath()
    }

    ; Update warning messages depending on read Briv skip values.
    ; Show a waring if not at perfect 100% chance or if the wrong Briv skip preset has been selected.
    ; Parameters: - targetQ:int - Currently displayed target Briv skip value for Q formation.
    UpdatePresetWarning(targetQ)
    {
        controlID := "BGFBFS_PresetWarningText"
        targetSkipValues := IC_BrivGemFarm_Class.BrivFunctions.GetBrivSkipConfig(1, true).AvailableJumps
        if ((detectedChance := this.DetectedSkipChance) != "" && detectedChance != 100)
        {
            preset := this.GetPresetName()
            if (preset == "8J/7J Tall Tales" || preset == "12J/11J Tall Tales" || preset == "14J/9J Tall Tales" || preset == "16J/15J Tall Tales")
                warningText := ""
            else
            {
                warningText := "WARNING: Briv not at 100" . "%" . " skip chance."
                loot := IC_BrivGemFarm_Class.BrivFunctions.GetBrivLoot()
                if (loot.gild == 1)
                    warningText .= "`n(Shiny can't get perfect jump for even skip values)"
            }
            GuiControl, ICScriptHub:, %controlID%, % warningText
            partialText := "(" . targetSkipValues[1] . "-" . targetSkipValues[2] . ")"
            GuiControl, ICScriptHub:, BrivFeatSwapQPartialText, % partialText
            return
        }
        else if (this.GetPresetName() != "" && (detectedAmount := this.DetectedSkipAmount) != "" && targetQ != detectedAmount)
        {
            GuiControl, ICScriptHub:, %controlID%, WARNING: Wrong preset for current Briv skip.
            partialText := "(" . targetSkipValues[1] . ")"
            GuiControl, ICScriptHub:, BrivFeatSwapQPartialText, % partialText
            return
        }
        GuiControl, ICScriptHub:, %controlID%
        GuiControl, ICScriptHub:, BrivFeatSwapQPartialText
    }

    ; Set the state of the mod50 checkboxes for Preferred Briv Jump Zones in BGFBFS tab.
    ; Parameters: value:int - A bitfield that represents the checked state of each checkbox.
    LoadMod50(value)
    {
        Loop, 50
        {
            checked := (value & (2 ** (A_Index - 1))) != 0
            GuiControl, ICScriptHub:, BGFBFS_CopyPasteBGFAS_Mod_50_%A_Index%, % checked
        }
        Gui, ICScriptHub:Submit, NoHide
    }

    ; Show / hide mod50 checkboxes for Preferred Briv Jump Zones in BGFBFS tab.
    ; Parameters: - show:bool - If true, show Preferred Briv Jump Zones, else hide it.
    ToggleMod50(show := true)
    {
        value := show ? "Show" : "Hide"
        Loop, 50
            GuiControl, ICScriptHub:%value%, BGFBFS_CopyPasteBGFAS_Mod_50_%A_Index%
        GuiControl, ICScriptHub:%value%, BGFBFS_PreferredBrivJumpZones
    }

    ; Show / hide BrivMinLevelArea setting in BGFBFS tab.
    ; If LevelUp addon is not enabled, show link to GitHub.
    ; Parameters: - show:bool - If true, show BrivMinLevelArea, else hide it.
    ToggleBrivMinLevelArea(show := true)
    {
        showSetting := show ? "Show" : "Hide"
        ; BrivMinLevelArea LevelUp setting
        GuiControl, ICScriptHub:%showSetting%, BGFBFS_BrivMinLevelArea
        GuiControl, ICScriptHub:%showSetting%, BGFBFS_BrivMinLevelAreaText
        GuiControl, ICScriptHub:%showSetting%, BGFBFS_BGFLU
        ; Show get LevelUp addon link
        showLink := (show && !IsObject(IC_BrivGemFarm_LevelUp_Component)) ? "Show" : "Hide"
        GuiControl, ICScriptHub:%showLink%, BGFBFS_GetLevelUpAddonText
        GuiControl, ICScriptHub:%showLink%, BGFBFS_GetLevelUpAddonLink
        GuiControl, ICScriptHub:%showLink%, BGFBFS_GetLevelUpAddonText2
    }

    ; Save and return the in-game Modron reset setting.
    ; Update the text next to the reset area dropdown.
    GetModronResetArea()
    {
        if (this.GameIsReady())
        {
            resetArea := g_SF.Memory.GetModronResetArea()
            if (resetArea > 0 && resetArea != this.DetectedResetArea) ; -1 on failure
            {
                this.DetectedResetArea := resetArea
                GuiControl, ICScriptHub:Text, BGFBFS_ResetAreaText, % "Reset area (Modron reset: " . resetArea . ")"
            }
        }
        return this.DetectedResetArea
    }

    ; Update the path from z1 to the reset area.
    ; Parameters: - resetArea:int - Actual zone where the run is reset.
    UpdatePath(resetArea := "")
    {
        static lastResetArea := ""
        static lastMod50Values := ""
        static lastTargetQ := ""
        static lastTargetE := ""
        static lastBrivMinLevel := ""
        static lastBrivMetalborn := ""
        mod50Values := this.GetPreferredAdvancedSettings(, true)
        GuiControlGet, targetQ, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetQ
        GuiControlGet, targetE, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetE
        GuiControlGet, brivMinLevelArea, ICScriptHub:, BGFBFS_BrivMinLevelArea
        GuiControlGet, brivMetalbornArea, ICScriptHub:, BGFBFS_BrivMetalbornArea
        if (resetArea == "")
        {
            resetArea := this.DetectedResetArea
            ; Check if anything changed before recalculating
            mod50String := ""
            for k, v in mod50Values
                mod50String .= v
            if (resetArea == lastResetArea && mod50String == lastMod50Values && targetQ == lastTargetQ && targetE == lastTargetE && brivMinLevelArea == lastBrivMinLevel && brivMetalbornArea == lastBrivMetalborn)
                return ; Nothing changed, skip recalculation
            lastResetArea := resetArea
            lastMod50Values := mod50String
            lastTargetQ := targetQ
            lastTargetE := targetE
            lastBrivMinLevel := brivMinLevelArea
            lastBrivMetalborn := brivMetalbornArea
            path := this.Calcpath(mod50Values, resetArea, targetQ, targetE, brivMinLevelArea, brivMetalbornArea)
            choices := ""
            for k, v in path.path
            {
                choices .= v . "|"
                if (sel == "" && v >= resetArea)
                    sel := v
            }
            GuiControl, ICScriptHub:, BGFBFS_ResetArea, % "|" . choices
            GuiControl, ICScriptHub:ChooseString, BGFBFS_ResetArea, % sel
        }
        else
            path := this.Calcpath(mod50Values, resetArea, targetQ, targetE, brivMinLevelArea, brivMetalbornArea)
        this.CurrentPath := path.Clone()
        GuiControlGet, runs, ICScriptHub:, BGFBFS_Runs
        ; Update text controls
        a := runs * path.noMetalbornJumps
        b := runs * path.metalbornJumps
        totalWalks := runs * path.walks
        this.UpdateWalkJumpText(totalWalks, a, b)
        stacksNeeded := this.CalcBrivStacksNeeded(a, b)
        if (stacksNeeded == "Too many")
            return this.UpdatePath(this.UpdateResetAreaFromStacks(999999999999999))
        this.DisableResetAreaUpdate := true
        GuiControl, ICScriptHub:Text, BGFBFS_StacksRequired, % stacksNeeded
    }

    ; Updates the reset area when user has entered a value for maximum stacks.
    ; Disabled when user selects an area from the ComboBox.
    ; Parameters: - stacks:int - Maximum Briv stacks.
    ; Returns: - resetArea:int - Maximum area reached using all stacks.
    UpdateResetAreaFromStacks(stacks := 50)
    {
        mod50Values := this.GetPreferredAdvancedSettings(, true)
        GuiControlGet, targetQ, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetQ
        GuiControlGet, targetE, ICScriptHub:, BrivGemFarm_BrivFeatSwap_TargetE
        GuiControlGet, brivMinLevelArea, ICScriptHub:, BGFBFS_BrivMinLevelArea
        GuiControlGet, brivMetalbornArea, ICScriptHub:, BGFBFS_BrivMetalbornArea
        maxArea := this.CalcPathStacks(mod50Values, stacks, targetQ, targetE, brivMinLevelArea, brivMetalbornArea)
        GuiControlGet, runs, ICScriptHub:, BGFBFS_Runs
        if (!this.DisableResetAreaUpdate && runs == 1)
            GuiControl, ICScriptHub:Text, BGFBFS_ResetArea, % maxArea
        else if (!this.DisableResetAreaUpdate)
            this.UpdateStacksFromRunCount(runs, stacks)
        ; Update text controls
        if (!this.DisableResetAreaUpdate && runs == 1)
        {
            path := this.CalcPath(mod50values, maxArea, targetQ, targetE, brivMinLevelArea, brivMetalbornArea)
            a := path.noMetalbornJumps
            b := path.metalbornJumps
            totalWalks := path.walks
            this.UpdateWalkJumpText(totalWalks, a, b)
        }
        this.DisableResetAreaUpdate := false
        return maxArea
    }

    ; Update stacks needed depending on a number of runs done stacking only once.
    ; If the number of stacks is too high, lower run count until valid.
    ; Parameters: - runs:int - Number of runs from one restack.
    UpdateStacksFromRunCount(runs := 1, stackLimit := "")
    {
        path := this.CurrentPath
        a := runs * path.noMetalbornJumps
        b := runs * path.metalbornJumps
        stacksNeeded := this.CalcBrivStacksNeeded(a, b)
        ; Increment/decrement run value depending on input stacks
        if (stackLimit != "" && stacksNeeded > stackLimit)
            stacksNeeded := "Too many"
        else if (stackLimit != "")
            return this.UpdateStacksFromRunCount(runs + 2, stackLimit)
        ; Limit runs to the maximum value possible from max stacks
        while (stacksNeeded == "Too many" && runs > 0)
        {
            a := --runs * path.noMetalbornJumps
            b := runs * path.metalbornJumps
            stacksNeeded := this.CalcBrivStacksNeeded(a, b)
        }
        this.DisableResetAreaUpdate := true
        if (!this.DisableStacksRequiredUpdate)
        {
            GuiControl, ICScriptHub:Text, BGFBFS_StacksRequired, % stacksNeeded
            this.UpdateWalkJumpText(runs * path.walks, a, b)
            this.DisableStacksRequiredUpdate := true
            GuiControl, ICScriptHub:Text, BGFBFS_Runs, % runs
            Sleep, 50
        }
        this.DisableStacksRequiredUpdate := false
        return stacksNeeded
    }

    ; Update the text that shows walks, jumps w and w/o Metalborn for the current path.
    ; Parameters: - walks:int - Number of times Briv walks.
    ;             - noMbJumps:int - Number of times Briv jumps without Metalborn.
    ;             - mbJumps:int - Number of times Briv jumps with Metalborn.
    UpdateWalkJumpText(walks, noMbJumps, mbJumps)
    {
        jumpsText := (noMbJumps + mbJumps) . " jump" . this.Plural(noMbJumps + mbJumps)
        jumpsText .= " (" . noMbJumps . " non-Metalborn, " . mbJumps . " Metalborn)"
        GuiControl, ICScriptHub:Text, BGFBFS_JumpsText, % jumpsText
        walksText := walks . " walk" . this.Plural(walks)
        GuiControl, ICScriptHub:Text, BGFBFS_WalksText, % walksText
    }

    ; Returns the text to append for values not equal to 1.
    ; Parameters: - value:int - Value of anything countable.
    Plural(value)
    {
        return value == 1 ? "" : "s"
    }

    ; Return the number of stacks needed to jump noMetalbornJumps + metalbornJumps times.
    ; Parameters: - noMetalbornJumps:int - Number of times Briv jumps without Metalborn.
    ;             - metalbornJumps:int - Number of times Briv jumps with Metalborn.
    CalcBrivStacksNeeded(noMetalbornJumps, metalbornJumps)
    {
        stacks := (noMetalbornJumps + metalbornJumps > 0) * 50
        ; Last jump is always with Metalborn unless Briv never gets to level 170
        ; Metalborn calculations must apply last meaning backtracking starts with Metalborn
        Loop, % (metalbornJumps > 0 ? metalbornJumps - 1 : metalbornJumps)
        {
            stacks := Ceil((stacks - 0.5) / 0.968)
            if (stacks > 999999999999999)
                return "Too many"
        }
        Loop, % (metalbornJumps > 0 ? noMetalbornJumps : noMetalbornJumps - 1)
        {
            stacks := Ceil((stacks - 0.5) / 0.96)
            if (stacks > 999999999999999)
                return "Too many"
        }
        return stacks
    }

    ; Calculates the path from z1 to the reset area.
    ; Parameters: - mod50value:int - If true, show BrivMinLevelArea, else hide it.
    ;             - resetArea:int - Actual zone where the run is reset.
    ;             - skipQ:int - Number of Briv jumps in Q formation.
    ;             - skipE:int - Number of Briv jumps in E formation.
    ;             - brivMinLevelArea:int - Minimum level where Briv can jump (LevelUp addon setting).
    ;             - brivMetalbornArea:int - Minimum level where Briv gets Metalborn (LevelUp addon setting).
    ; Returns:    - object - array:path, int:walks, int:jumps w/o Metalborn, int:jumps w/ Metalborn
    CalcPath(mod50values, resetArea, skipQ, skipE, brivMinLevelArea := 1, brivMetalbornArea := 1)
    {
        preset :=  this.GetPresetName()
        qVal := skipQ != "" ? skipQ + 1 : 1
        eVal := skipE != "" ? skipE + 1 : 1
        noMbJumps := mbJumps := walks := 0
        if (!Isobject(mod50values))
        {
            mod50Int := mod50values
            mod50values := []
            Loop, 50
                mod50values[A_Index] := (mod50Int & (2 ** (A_Index - 1))) != 0
        }
        path := [currentArea := 1]
        ; Walk
        Loop, % brivMinLevelArea - 1
            ++currentArea > resetArea ? break : path.Push(++walks + 1)
        ; Jump
        while (currentArea < resetArea)
        {
            ; Area progress
            mod50Index := Mod(currentArea, 50) == 0 ? 50 : Mod(currentArea, 50)
            mod50Value := mod50values[mod50Index]
            move := mod50Value ? qVal : eVal
            ; Update walk and metalborn jump counters
            if (move == 1)
                ++walks
            else
                currentArea < brivMetalbornArea ? ++noMbJumps : ++mbJumps
            ; Update path
            path.Push(currentArea += move)
        }
        return {path:path, walks:walks, metalbornJumps:mbJumps, noMetalbornJumps:noMbJumps}
    }

    ; Calculates the path from z1 to the area until Briv reaches under 50 stacks.
    ; Parameters: - mod50value:int - If true, show BrivMinLevelArea, else hide it.
    ;             - stacks:int - Briv stacks.
    ;             - skipQ:int - Number of Briv jumps in Q formation.
    ;             - skipE:int - Number of Briv jumps in E formation.
    ;             - brivMinLevelArea:int - Minimum level where Briv can jump (LevelUp addon setting).
    ;             - brivMetalbornArea:int - Minimum level where Briv gets Metalborn (LevelUp addon setting).
    ; Returns:    - int - Maximum area reached.
    CalcPathStacks(mod50values, stacks, skipQ, skipE, brivMinLevelArea := 1, brivMetalbornArea := 1)
    {
        preset :=  this.GetPresetName()
        qVal := skipQ != "" ? skipQ + 1 : 1
        eVal := skipE != "" ? skipE + 1 : 1
        if (!Isobject(mod50values))
        {
            mod50Int := mod50values
            mod50values := []
            Loop, 50
                mod50values[A_Index] := (mod50Int & (2 ** (A_Index - 1))) != 0
        }
        ; Walk
        currentArea := brivMinLevelArea
        ; Jump
        while (stacks >= 50)
        {
            ; Area progress
            mod50Index := Mod(currentArea, 50) == 0 ? 50 : Mod(currentArea, 50)
            move := mod50values[mod50Index] ? qVal : eVal
            currentArea += move
            ; Update stacks
            if (move > 1)
                stacks := Round(stacks * (currentArea < brivMetalbornArea ? 0.96 : 0.968))
        }
        return currentArea
    }
}