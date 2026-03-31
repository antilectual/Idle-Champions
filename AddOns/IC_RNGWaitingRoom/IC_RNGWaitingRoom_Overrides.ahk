; Overrides IC_BrivGemFarm_LevelUp_Class.GemFarmShouldSetFormation()
; Overrides IC_BrivGemFarm_LevelUp_Class.GemFarmResetSetup()
; Overrides IC_BrivGemFarm_LevelUp_Added_Class.BGFLU_DoPartyWaits()
class IC_RNGWaitingRoom_Class extends IC_BrivGemFarm_LevelUp_Class
{
    GemFarmShouldSetFormation()
    {
        ; Prevent Thellora from being put in the formation on z1 before stacking Ellywick
        EllywickEnabled := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ]
        if (EllywickEnabled && g_SF.Memory.ReadResetting() || g_SF.Memory.ReadResetsCount() > this.LastResetCount)
            g_SharedData.RNGWR_Elly.Reset()
        if (!EllywickEnabled OR !g_SF.FormationSwitchLock)
            return base.GemFarmShouldSetFormation()
        return False
    }

    GemFarmResetSetup(formationModron := "", doBasePartySetup := False)
    {
        resetsCount := base.GemFarmResetSetup(formationModron, doBasePartySetup)
        g_SharedData.RNGWR_Elly.Reset()
        return resetsCount
    }

    BGFLU_DoPartyWaits(formation)
    {
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (!g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] AND g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        this.BGFLU_DoPartySetupMin(g_BrivUserSettingsFromAddons[ "BGFLU_ForceBrivEllywick" ])
        g_SF.FormationLevelingLock := False
        if (g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] && g_SF.IsChampInFormation(ActiveEffectKeySharedFunctions.Ellywick.HeroID, formation))
            g_SF.RNGWR_DoEllyWait()
        g_SF.FormationSwitchLock := False
        if (g_SF.IsChampInFormation(ActiveEffectKeySharedFunctions.Thellora.HeroID, formation))
            g_SF.DoRushWait()
    }

    ModronResetCheck()
    {
        g_SF.FormationLevelingLock := True
        g_SF.FormationSwitchLock := True
        base.ModronResetCheck()
    }
}

; Overrides IC_BrivGemFarm_LevelUp_SharedFunctions_Class.GetInitialFormation()
; Overrides IC_BrivSharedFunctions_Class.RestartAdventure()
; Overrides IC_BrivSharedFunctions_Class.SetFormation()
class IC_RNGWaitingRoom_SharedFunctions_Class extends IC_SharedFunctions_Class
{
    ;
    GetInitialFormation()
    {
        modronFormation := g_SF.Memory.GetActiveModronFormation()
        if(this.FormationSwitchLock)
            return modronFormation
        formation := base.GetInitialFormation()
        ; Use extra champions if they're in the modron formation.
        heroIDs := [99,59,97] ; DM / Melf / Tatyana
        for k,heroID in heroIDs
            if (g_SF.IsChampInFormation(heroID, modronFormation))
                formation.Push(heroID)
        return formation
    }

    RestartAdventure( reason := "" )
    {
        g_SF.FormationSwitchLock := True
        g_SharedData.RNGWR_Elly.Reset()
        base.RestartAdventure(reason)
    }

    ; a method to swap formations and cancel briv's jump animation.
    SetFormation(settings := "", forceCheck := False)
    {
        if (!g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] OR !g_SF.FormationSwitchLock)
            return base.SetFormation(settings)
    }
}

class IC_RNGWaitingRoom_SharedFunctions_Added_Class ; Added to IC_BrivSharedFunctions_Class
{
    RNGWR_DoEllyWait()
    {
        g_SF.ToggleAutoProgress( 0, false, true )
        if(g_SharedData.RNGWR_FirstRun) ; no ellywait on first run, get to gem farm first.
        {
            g_SharedData.RNGWR_FirstRun := False
            return g_SharedData.RNGWR_Elly.Stop()
        }
        this.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.EffectKey)
        g_SharedData.RNGWR_Elly.Start()
        if (!g_SharedData.RNGWR_Elly.IsEllyWickOnTheField())
            if(ActiveEffectKeySharedFunctions.Ellywick.HeroID == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(ActiveEffectKeySharedFunctions.Ellywick.HeroID)))
                g_BrivGemFarm.BGFLU_LevelUpChamp(ActiveEffectKeySharedFunctions.Ellywick.HeroID)
        timeout := 60000
        timeoutTimer := new SH_SharedTimers()
        minFailCount := 0
        while(!g_SharedData.RNGWR_Elly.WaitedForEllywickThisRun && !timeoutTimer.IsTimeUp(timeout))
        {
            g_SF.SetFormationForStart()
            g_SharedData.LoopString := "Elly Wait: " . A_TickCount - timeoutTimer.StartTime
            if(g_BrivGemFarm.BGFLU_DoPartySetupMin())
                minFailCount += 1
            if(minFailCount >= 4)
                g_BrivGemFarm.BGFLU_DoPartySetupMax()
            Sleep, 30
        }
        g_SharedData.LoopString := "Elly Wait Done!"
        if (timeoutTimer.IsTimeUp(timeout))
            g_SharedData.RNGWR_Elly.WaitedForEllywickThisRun := true
        g_SharedData.RNGWR_Elly.Stop()
        g_SharedData.RNGWR_FirstRun := false
        g_BrivGemFarm.BGFLU_DoPartySetupMax()
        ; Unlock formation switch
        g_PreviousZoneStartTime := A_TickCount
    }
}

class IC_RNGWaitingRoom_IC_SharedData_Added_Class ; Added to IC_SharedData_Class
{
;    RNGWR_Status := ""
;    RNGWR_Stats := ""
;    RNGWR_Elly := ""
;    RNGWR_FirstRun := ""

    ; Return true if the class has been updated by the addon
    RNGWR_Running()
    {
        return true
    }

    RNGWR_GemFarmEnabled()
    {
        return g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ]
    }

    RNGWR_SetStatus(text := "")
    {
        this.RNGWR_Status := text
    }

    ; Load settings after "Start Gem Farm" has been clicked.
    RNGWR_Init()
    {
        this.RNGWR_FirstRun := true
        this.RNGWR_ResetStats()
        this.RNGWR_Elly := new IC_RNGWaitingRoom_Functions.EllywickHandlerHandler
        this.RNGWR_UpdateSettingsFromFile()
    }

    RNGWR_UpdateStats(bonusGems := 0, redraws := 0, success := true)
    {
        if (this.RNGWR_FirstRun)
            return
        this.Stats["BonusGemsSum"] += bonusGems
        this.Stats["RedrawsSum"] += redraws
        this.Stats["Runs"] += 1
        this.Stats["Success"] += success
    }

    RNGWR_GetStats()
    {
        stats := this.Stats
        return [stats.BonusGemsSum, stats.RedrawsSum, stats.Runs, stats.Success]
    }

    RNGWR_ResetStats()
    {
        stats := {}
        stats.BonusGemsSum := 0
        stats.RedrawsSum := 0
        stats.Runs := 0
        stats.Success := 0
        this.Stats := stats
    }

    ; Load settings from the GUI settings file
    RNGWR_UpdateSettingsFromFile(fileName := "")
    {
        if (fileName == "")
            fileName := IC_RNGWaitingRoom_Functions.SettingsPath
        settings := g_SF.LoadObjectFromJSON(fileName)
        if (!IsObject(settings))
            return false
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFEnabled" ] := settings.EllywickGFEnabled
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemCards" ] := settings.EllywickGFGemCards
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemMaxRedraws" ] := settings.EllywickGFGemMaxRedraws
        g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemWaitFor5Draws" ] := settings.EllywickGFGemWaitFor5Draws
        this.RNGWR_Elly.UpdateGlobalSettings()
    }
}