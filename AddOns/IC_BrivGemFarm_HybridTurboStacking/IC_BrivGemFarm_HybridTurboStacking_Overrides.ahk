; Overrides IC_BrivGemFarm_Class.TestForSteelBonesStackFarming()
; Overrides IC_BrivGemFarm_Class.ShouldOfflineStack()
; Overrides IC_BrivGemFarm_Class.GemFarmResetSetup()
; Overrides IC_BrivGemFarm_Class.GetNumStacksFarmed()
; Overrides IC_BrivGemFarm_Class.StackRestart()
; Overrides IC_BrivGemFarm_Class.StackNormal()
class IC_BrivGemFarm_HybridTurboStacking_Class extends IC_BrivGemFarm_Class
{
    static FARIDEH_ID := 33
    static WARDEN_ID := 36
    static MELF_ID := 59
   BGFHTS_DelayedOffline := false
   BGFHTS_LastOfflineReset := 0

    ; Stacking offline uses g_BrivUserSettings[ "StackZone" ].
    ; While online uses BGFHTS_MelfMinStackZone.
    TestForSteelBonesStackFarming()
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ] || this.ShouldOfflineStack())
            return base.TestForSteelBonesStackFarming()
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_100Melf" ])
            return base.TestForSteelBonesStackFarming()
        if (g_SF.Memory.ReadHasteStacks() < 50)
            return base.TestForSteelBonesStackFarming()
        if (!Mod( g_SF.Memory.ReadCurrentZone(), 5)) ; melf stacking + land on boss zone = do not stack here.
            return 0
        ; If no Melf +spawn effect until reset, stack offline.
        range := g_SharedData.BGFHTS_CurrentRunStackRange
        if (range[1] == "" || range[2] == "")
            return base.TestForSteelBonesStackFarming()
        ; Use Melf Min StackZone settings.
        savedStackZone := g_BrivUserSettings[ "StackZone" ]
        g_BrivUserSettings[ "StackZone" ] := g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMinStackZone" ] - 1
        r := base.TestForSteelBonesStackFarming()
        g_BrivUserSettings[ "StackZone" ] := savedStackZone
        return r
    }

    ; Determines if offline stacking is expected with current settings and conditions.
    ShouldOfflineStack()
    {
        rushStacks := ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.ReadRushStacks()
        highestZone := g_SF.Memory.ReadHighestZone()
        if (rushStacks < 310 && highestZone > 1100 && !g_SF.AlreadyOfflineStackedThisRun)
            return true
        shouldOfflineStack := base.ShouldOfflineStack()
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ])
            return shouldOfflineStack
        ; If no Melf +spawn effect until reset, stack offline.
        range := g_SharedData.BGFHTS_CurrentRunStackRange
        ; if ((range[1] == "" || range[2] == "") && g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] == 2)
        ;     return True
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_MultirunDelayOffline" ])
            return shouldOfflineStack
        ; Delay offline until last restart for multiple runs.
        targetStacks := g_BrivUserSettings[ "TargetStacks" ]
        combinedStacks := g_SF.Memory.ReadHasteStacks() + g_SF.Memory.ReadSBStacks()
        if (shouldOfflineStack)
        {
            resetCount := g_SF.Memory.ReadResetsCount()
            if (lastOfflineReset == resetCount)
                return False
            lastOfflineReset := this.BGFHTS_LastOfflineReset
            this.BGFHTS_LastOfflineReset := resetCount
            if (!this.BGFHTS_DelayedOffline && combinedStacks >= targetStacks && resetCount != lastOfflineReset)
            {
                this.BGFHTS_DelayedOffline := True
                return False
            }
        }
        if (this.BGFHTS_DelayedOffline && combinedStacks < targetStacks)
        {
            this.BGFHTS_DelayedOffline := False
            return True
        }
        return shouldOfflineStack && !this.BGFHTS_DelayedOffline
    }

    GemFarmResetSetup(formationModron := "", doBasePartySetup := False)
    {
            resetsCount := base.GemFarmResetSetup(formationModron, doBasePartySetup)
            g_SharedData.BGFHTS_UpdateMelfStackZoneAfterReset()
            this.BGFHTS_UpdateMelfStackZoneAfterReset(true)
            return resetsCount
    }

    GetNumStacksFarmed(afterReset := false)
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ])
            return base.GetNumStacksFarmed()
        if (this.ShouldOfflineStack())
            this.StackRestart()
        if (afterReset || IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive())
        {
            sbStacks := g_SF.Memory.ReadSBStacks()
            hasteStacksAfterReset := IC_BrivGemFarm_Class.BrivFunctions.PredictStacks(False,False,True)
            stacksAfterReset := g_SF.BrivHasThunderStep() ? sbStacks * 1.2 + hasteStacksAfterReset: sbStacks + hasteStacksAfterReset
            ; thunderstep recalc.
            g_SharedData.BGFHTS_SBStacksPredict := stacksAfterReset
            return stacksAfterReset
        }
        else
            return g_SF.Memory.ReadSBStacks() + 48
    }

    StackRestart()
    {
        IC_BrivGemFarm_HybridTurboStacking_Functions.SetRemovedIdsFromWFavorite([36, 59, 97])
        g_SF.AlreadyOfflineStackedThisRun := True
        stacks := g_SF.Memory.ReadSBStacks()
        g_SharedData.LoopString := "FORT Restart"
        g_SF.CurrentZone := g_SF.Memory.ReadCurrentZone() ; record current zone before saving for bad progression checks
        g_SF.ToggleAutoProgress(0)
        g_PreviousZoneStartTime := A_TickCount ; reset zone start time after stacking
        if(g_SharedData.TotalRunsCount > 0)
            g_SF.CloseIC( "FORT Restart" )
        ; save stacks in case close IC fails at doing it properly ? ; g_ServerCall.CallPreventStackFail(stacks) - only saves Haste, deletes SB. Only for resets.
        g_SF.SafetyCheck(stackRestart := True)
        if (g_SF.Memory.ReadNumAttackingMonstersReached() > 10 || g_SF.Memory.ReadNumRangedAttackingMonsters())
            g_SF.FallBackFromZone() ; don't get stuck getting attacked.
        if (g_SF.UnBenchBrivConditions(g_BrivUserSettings))
            g_SF.DirectedInput(,, "{q}")
        else if (g_SF.BenchBrivConditions(g_BrivUserSettings))
            g_SF.DirectedInput(,, "{e}")
        IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun := True
        ; SetFormation effectively called here after returning from this function by way of Stack continuing StackFarm()
    }

    ; Tries to complete the zone before online stacking.
    ; TODO:: Update target stacks if Thellora doesn't have enough stacks for the next run.
    StackNormal(maxOnlineStackTime := 300000, targetStacks := 0, ignoreMelf := False)
    {
        if (!g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ])
            return base.StackNormal(maxOnlineStackTime)
        ; Melf stacking
        if (g_BrivUserSettingsFromAddons[ "BGFHTS_100Melf" ] && this.BGFHTS_PostponeStacking() && !ignoreMelf)
            return 0
        predictStacks := IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive()
        stacks := this.GetNumStacksFarmed(predictStacks)
        targetStacks := targetStacks ? targetStacks : g_BrivUserSettings[ "TargetStacks" ]
        ; first checks should short circuit last check if failed.
        if (this.ShouldAvoidRestack(stacks, targetStacks) AND !ignoreMelf) {
            g_SharedData.LoopString .= " - Rejected by HybridTurbo. Already Stacked"
            return 0
        }
        ; Check if offline stack is needed
        if(this.StackNormalExtraSetup())
            return
        this.StackFarmSetup(setUIString := True)
        ; Start online stacking
        g_SharedData.LoopString := "Stack Normal"
        ; Turn on Briv auto-heal
        fncToCallOnTimer := this.StackNormalAutoHeal()
        ; Stacking
        this.StackNormalStacking(targetStacks, stacks, maxOnlineStackTime)
        ; Turn off Briv auto-heal
        if (autoHeal)
            SetTimer, %fncToCallOnTimer%, Off
        if ( ElapsedTime >= maxOnlineStackTime)
        {
            this.RestartAdventure( "Online stacking took too long (> " . (maxOnlineStackTime / 1000) . "s) - z[" . g_SF.Memory.ReadCurrentZone() . "].")
            this.SafetyCheck()
            g_PreviousZoneStartTime := A_TickCount
            return ""
        }
        ; Update stats
        if (g_BrivUserSettingsFromAddons[ "BGFHTS_100Melf" ])
        {
            g_SharedData.BGFHTS_PreviousStackZone := g_SF.Memory.ReadCurrentZone()
            g_SharedData.BGFHTS_CurrentRunStackRange := ["", ""]
        }
        g_PreviousZoneStartTime := A_TickCount
        ; Go back to z-1 if failed to complete the current zone
        if (g_SF.Memory.ReadQuestRemaining() > 0)
            g_SF.FallBackFromZone()
        g_SF.ToggleAutoProgress( 1, false, true )
        ; StackFarm won't be able to switch back to Q/E from W if the formation on the field isn't the exact
        ; formation saved in the second favorite formationslot.
        g_SF.SetFormation(g_BrivUserSettings)
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        ; Update stats
        if (IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive())
            g_SharedData.BGFHTS_SBStacksPredict := IC_BrivGemFarm_Class.BrivFunctions.PredictStacks(True,False,False)
        g_SharedData.BGFHTS_Status := "Online stacking done"
        return ""
    }
}


class IC_BrivGemFarm_HybridTurboStacking_Added_Class ; Added to IC_BrivGemFarm_Class
{
    
    StackNormalAutoHeal()
    {
        fncToCallOnTimer := ""
        autoHeal := g_BrivUserSettingsFromAddons[ "BGFHTS_BrivAutoHeal" ] > 0
        if (autoHeal)
        {
            fncToCallOnTimer := g_SharedData.BGFHTS_TimerFunctionHeal
            SetTimer, %fncToCallOnTimer%, Off       ; avoid running timer multiple times.
            SetTimer, %fncToCallOnTimer%, 1000, 0
        }
        return fncToCallOnTimer
    }

    ; Extra setup for HTS online stacking.
    StackNormalExtraSetup()
    {
        if (g_BrivUserSettingsFromAddons[ "BGFHTS_Multirun" ])
            targetStacks := g_BrivUserSettingsFromAddons[ "BGFHTS_MultirunTargetStacks" ]
        g_SF.ToggleAutoProgress( 0, false, true )
        ; Complete the current zone
        completed := g_BrivUserSettingsFromAddons[ "BGFHTS_CompleteOnlineStackZone" ] && this.BGFHTS_WaitForZoneCompleted()
        ; Conditional stack formation
        isMelfActive := IC_BrivGemFarm_HybridTurboStacking_Melf.IsCurrentEffectSpawnMore()
        removedIds := ""
        if (!isMelfActive && g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] == 1)
            removedIds := [59] ; Melf
        else if (isMelfActive && g_BrivUserSettingsFromAddons[ "BGFHTS_MelfActiveStrategy" ] == 1)
            removedIds := [36] ; Warden/Tatyana
        IC_BrivGemFarm_HybridTurboStacking_Functions.SetRemovedIdsFromWFavorite(removedIds)
        return false
    }

    StackNormalGetMoreBrivLeveling()
    {
        currentZone:= g_SF.Memory.ReadCurrentZone()
        amountToLevelBriv := 0
        if (currentZone >= 1500)
            amountToLevelBriv := 815
        else if (currentZone >= 1400)
            amountToLevelBriv := 695
        else if (currentZone >= 1300)
            amountToLevelBriv := 575
        else if (currentZone >= 1200)
            amountToLevelBriv := 455
        else if (currentZone >= 1100)
            amountToLevelBriv := 400
        else
            amountToLevelBriv := this.BGFLU_GetTargetLevel(ActiveEffectKeySharedFunctions.Briv.HeroID, minOrMax := "Max") 
        return amountToLevelBriv
        
    }

    StackNormalStacking(targetStacks, stacks, maxOnlineStackTime)
    {
        ; Incremental Briv Leveling vars
        amountToLevelBriv := this.StackNormalGetMoreBrivLeveling()
        levelBrivSomeMore := amountToLevelBriv > 340
        SBStacksStart := g_SF.Memory.ReadSBStacks()
        usedWardenUlt := false
        usedFaridehUlt := false
        StartTime := A_TickCount
        ElapsedTime := 0
        MelfID := 59
        FaridehId := 33
        if (!IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive())  ; Haste stacks are taken into account
        {
            remainder := targetStacks - stacks
            SBStacksFarmed := 0
            stackFormation := g_SF.Memory.GetFormationByFavorite(2)
            defaultLevelingFormation := g_SF.Memory.GetFormationByFavorite(1)
            levelingFormation := {}
            ; add leveling keys not in stack formation - to level formation champs without leveling stacking team.
            for k,v in defaultLevelingFormation
            {
                foundKey := false
                for key,value in stackFormation
                    if (v == value)
                        foundKey := True
                if (!foundKey)
                    levelingFormation[k] := v
            }
            while (SBStacksFarmed < remainder AND ElapsedTime < maxOnlineStackTime )
            {
                if (g_SF.Memory.ReadCurrentZone() < 1)
                    return g_SharedData.BGFHTS_Status := "Stacking interrupted due to game closed or reset"
                g_SharedData.BGFHTS_Status := "Stacking: " . (stacks + SBStacksFarmed ) . "/" . targetStacks
                g_SF.FallBackFromBossZone()
                isMelfInParty := MelfID == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(MelfID))
                if (isMelfInParty)
                {
                    targetLevel := this.BGFLU_GetTargetLevel(MelfID)
                    this.BGFLU_LevelUpChamp(MelfID, targetLevel, true) ; special redundant level melf x25
                }
                isFaridehInParty := FaridehId == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(FaridehId))
                if (isFaridehInParty)
                {
                    targetLevel := this.BGFLU_GetTargetLevel(FaridehId)
                    this.BGFLU_LevelUpChamp(FaridehId, targetLevel, true) ; special redundant level Farideh x25
                }
                this.BGFLU_DoPartySetupMax(stackFormation)
                this.BGFLU_DoPartySetupMax(levelingFormation)
                this.BGFLU_LevelUpChamp(ActiveEffectKeySharedFunctions.Briv.HeroID, amountToLevelBriv)
                if (levelBrivSomeMore)
                    this.BGFLU_LevelUpChamp(ActiveEffectKeySharedFunctions.Briv.HeroID, amountToLevelBriv)
                ; Warden ultimate
                wardenThreshold := g_BrivUserSettingsFromAddons[ "BGFHTS_WardenUltThreshold" ]
                if (!usedWardenUlt && wardenThreshold > 0)
                    usedWardenUlt := this.BGFHTS_TestWardenUltConditions(wardenThreshold)
                ; Farideh ultimate
                faridehThreshold := g_BrivUserSettingsFromAddons[ "BGFHTS_FaridehUltThreshold" ]
                if (!usedFaridehUlt && faridehThreshold > 0)
                    usedFaridehUlt := this.BGFHTS_TestFaridehUltConditions(faridehThreshold)
                if (IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun AND g_SF.Memory.ReadMostRecentFormationFavorite() != 2) ; not in formation 2 still
                    this.StackFarmSetup()
                else if (!this.IsCurrentFormationLazy(this.Memory.GetFormationByFavorite(2)))
                    this.StackFarmSetup()                
                else if (SBStacksFarmed < (remainder / 10) and ElapsedTime > 10000 ) ; not gaining stacks 
                    this.StackFarmSetup()
                Sleep, 30
                ElapsedTime := A_TickCount - StartTime
                SBStacksFarmed := g_SF.Memory.ReadSBStacks() - SBStacksStart
            }
        }
        else
        {
            while ( stacks < targetStacks AND ElapsedTime < maxOnlineStackTime )
            {
                if (g_SF.Memory.ReadCurrentZone() < 1)
                    return g_SharedData.BGFHTS_Status := "Stacking interrupted due to game closed or reset"
                g_SharedData.BGFHTS_Status := "Stacking: " . stacks . "/" . targetStacks
                g_SF.FallBackFromBossZone()
                isMelfInParty := MelfID == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(MelfID))
                if (isMelfInParty)
                {
                    targetLevel := this.BGFLU_GetTargetLevel(MelfID)
                    this.BGFLU_LevelUpChamp(MelfID, targetLevel, true) ; level melf x25
                }
                isFaridehInParty := FaridehId == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(FaridehId))
                if (isFaridehInParty)
                {
                    targetLevel := this.BGFLU_GetTargetLevel(FaridehId)
                    this.BGFLU_LevelUpChamp(FaridehId, targetLevel, true) ; special redundant level Farideh x25
                }
                if (levelBrivSomeMore)
                    this.BGFLU_LevelUpChamp(ActiveEffectKeySharedFunctions.Briv.HeroID, amountToLevelBriv)
                ; Warden ultimate
                wardenThreshold := g_BrivUserSettingsFromAddons[ "BGFHTS_WardenUltThreshold" ]
                if (!usedWardenUlt && wardenThreshold > 0)
                    usedWardenUlt := this.BGFHTS_TestWardenUltConditions(wardenThreshold)
                ; Farideh ultimate
                faridehThreshold := g_BrivUserSettingsFromAddons[ "BGFHTS_FaridehUltThreshold" ]
                if (!usedFaridehUlt && faridehThreshold > 0)
                    usedFaridehUlt := this.BGFHTS_TestFaridehUltConditions(faridehThreshold)
                if (IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun AND g_SF.Memory.ReadMostRecentFormationFavorite() != 2) ; not in formation 2 still
                    this.StackFarmSetup()
                else if (!this.IsCurrentFormationLazy(this.Memory.GetFormationByFavorite(2)))
                    this.StackFarmSetup()
                Sleep, 30
                ElapsedTime := A_TickCount - StartTime
                stacks := this.GetNumStacksFarmed()
            }
        }
    }

    BGFHTS_WaitForZoneCompleted(maxTime := 3000)
    {
        g_SF.SetFormation(g_BrivUserSettings)
        highestZone := g_SF.Memory.ReadHighestZone()
        StartTime := A_TickCount
        ElapsedTime := 0
        g_SharedData.BGFHTS_Status := "Stacking: Waiting for transition"
        g_SF.WaitForTransition()
        quest := g_SF.Memory.ReadQuestRemaining()
        while (quest > 0 && ElapsedTime < maxTime)
        {
            quest := g_SF.Memory.ReadQuestRemaining()
            g_SharedData.BGFHTS_Status := "Stacking: Waiting for area completion " . quest
            if(ElapsedTime > maxTime / 2)
                g_SF.SetFormation(g_BrivUserSettings, forceCheck := True)
            else
                g_SF.SetFormation(g_BrivUserSettings)
            Sleep, 30
            ElapsedTime := A_TickCount - StartTime
        }
        return ElapsedTime < maxTime
    }

    BGFHTS_TestWardenUltConditions(threshold := 0)
    {
        champID := IC_BrivGemFarm_HybridTurboStacking_Class.WARDEN_ID
        champInWFormation := g_SF.IsChampInFormation(champID, g_SF.Memory.GetFormationByFavorite(2))
        if (champInWFormation && this.BGFHTS_CheckMaxEnemies(threshold))
            return this.BGFHTS_UseWardenUlt()
        return false
    }

    BGFHTS_TestFaridehUltConditions(threshold := 0)
    {
        champID := IC_BrivGemFarm_HybridTurboStacking_Class.FARIDEH_ID
        champInWFormation := g_SF.IsChampInFormation(champID, g_SF.Memory.GetFormationByFavorite(2))
        if (champInWFormation && this.BGFHTS_CheckMaxEnemies(threshold))
            return this.BGFHTS_UseFaridehUlt()
        return false
    }

    BGFHTS_CheckMaxEnemies(threshold := 0)
    {
        if (threshold == 0 || threshold == "")
            return true
        if (g_SF.Memory.ReadActiveMonstersCount() > threshold)
            return true
        return false
    }

    BGFHTS_UseWardenUlt()
    {
        champID := IC_BrivGemFarm_HybridTurboStacking_Class.WARDEN_ID
        g_SF.DirectedInput(,, "{" . g_SF.GetUltimateButtonByChampID(champID) . "}")
        return true
    }

    BGFHTS_UseFaridehUlt()
    {
        champID := IC_BrivGemFarm_HybridTurboStacking_Class.FARIDEH_ID
        g_SF.DirectedInput(,, "{" . g_SF.GetUltimateButtonByChampID(champID) . "}")
        return true
    }

    BGFHTS_PostponeStacking()
    {
        ; Stack immediately if Briv can't jump anymore.
        if (g_SF.Memory.ReadHasteStacks() < 50)
            return false
        currentZone := g_SF.Memory.ReadCurrentZone()
        ; Stack as soon as possible if not inside range.
        range := g_SharedData.BGFHTS_CurrentRunStackRange
        if (range[1] == "" || range[2] == "")
        {
            ; Offline stack after StackZone has been reached
            if (g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] == 2)
                return currentZone < g_BrivUserSettings[ "StackZone" ] + 1
            return false
        }
        stackZone := range[1]
        ; Stack immediately to prevent resetting before stacking.
        if (currentZone > IC_BrivGemFarm_Class.BrivFunctions.GetLastSafeStackZone() && currentZone > range[2])
            return false
        if (stackZone)
        {
            highestZone := g_SF.Memory.ReadHighestZone()
            mod50Zones := g_BrivUserSettingsFromAddons[ "BGFHTS_PreferredBrivStackZones" ]
            mod50Index := Mod(highestZone, 50) == 0 ? 50 : Mod(highestZone, 50)
            if (mod50Zones[mod50Index] == 0)
                return true
            if (!IC_BrivGemFarm_HybridTurboStacking_Melf.IsCurrentEffectSpawnMore())
                return true
        }
        ; Offline stack after StackZone has been reached
        if (this.BGFHTS_DelayedOffline)
            return currentZone < g_BrivUserSettings[ "StackZone" ] + 1
        return false
    }
}

; Overrides IC_MemoryFunctions_Class.GetFormationByFavorite()
class IC_BrivGemFarm_HybridTurboStacking_IC_MemoryFunctions_Class extends IC_MemoryFunctions_Class
{
    GetFormationByFavorite(favorite := 0 )
    {
        version := this.GameManager.game.gameInstances[this.GameInstance].FormationSaveHandler.formationSavesV2.__version.Read()
        if (this.FavoriteFormations[favorite] != "" AND version != "" AND version == this.LastFormationSavesVersion[favorite])
            return this.FavoriteFormations[favorite] 
        slot := this.GetSavedFormationSlotByFavorite(favorite)
        formation := this.GetFormationSaveBySlot(slot)
        if (favorite == 2) ; don't test stack formation for champions are still benched.
            for k, v in formation
                for _, champID in g_SharedData.BGFHTS_RemovedIdsFromWFavorite
                    if (v == champID)
                        if (g_SF.Memory.ReadChampBenchedByID(v) < 1) 
                            formation[k] := - 1
        this.FavoriteFormations[favorite] := formation.Clone()
        this.LastFormationSavesVersion[favorite] := version                            
        return formation
    }
}

class IC_BrivGemFarm_HybridTurboStacking_IC_SharedData_Added_Class ;Added to IC_SharedData_Class
{
;    BGFHTS_CurrentRunStackRange := ""
;    BGFHTS_PreviousStackZone := 0
;    BGFHTS_BrivDeaths := 0
;    BGFHTS_BrivHeals := 0
;    BGFHTS_Status := ""
;    BGFHTS_TimerFunction := ""
;    BGFHTS_TimerFunctionHeal := ""
;    BGFHTS_SBStacksPredict := 0
;    BGFHTS_StacksPredictionActive := false
;    BGFHTS_RemovedIdsFromWFavorite := ""

    ; Return true if the class has been updated by the addon.
    ; Returns "" if not properly loaded.
    BGFHTS_Running()
    {
        return g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ]
    }

    ; Load settings after "Start Gem Farm" has been clicked.
    BGFHTS_Init()
    {
        this.BGFHTS_BrivDeaths := 0
        this.BGFHTS_BrivHeals := 0
        this.BGFHTS_TimerFunction := ObjBindMethod(this, "BGFHTS_UpdateMelfStackZoneAfterReset")
        this.BGFHTS_TimerFunctionHeal := ObjBindMethod(IC_BrivGemFarm_HybridTurboStacking_Functions, "CheckBrivHealth")
        this.BGFHTS_UpdateSettingsFromFile()
    }

    ; Load settings from the GUI settings file.
    BGFHTS_UpdateSettingsFromFile(fileName := "")
    {
        if (fileName == "")
            fileName := IC_BrivGemFarm_HybridTurboStacking_Functions.SettingsPath
        settings := g_SF.LoadObjectFromJSON(fileName)
        if (!IsObject(settings))
            return false
        g_BrivUserSettingsFromAddons[ "BGFHTS_Enabled" ] := settings.Enabled
        g_BrivUserSettingsFromAddons[ "BGFHTS_CompleteOnlineStackZone" ] := settings.CompleteOnlineStackZone
        g_BrivUserSettingsFromAddons[ "BGFHTS_WardenUltThreshold" ] := settings.WardenUltThreshold
        g_BrivUserSettingsFromAddons[ "BGFHTS_FaridehUltThreshold" ] := settings.FaridehUltThreshold
        g_BrivUserSettingsFromAddons[ "BGFHTS_BrivAutoHeal" ] := settings.BrivAutoHeal
        g_BrivUserSettingsFromAddons[ "BGFHTS_Multirun" ] := settings.Multirun
        g_BrivUserSettingsFromAddons[ "BGFHTS_MultirunTargetStacks" ] := settings.MultirunTargetStacks
        g_BrivUserSettingsFromAddons[ "BGFHTS_MultirunDelayOffline" ] := settings.MultirunDelayOffline
        g_BrivUserSettingsFromAddons[ "BGFHTS_100Melf" ] := settings.100Melf
        g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMinStackZone" ] := settings.MelfMinStackZone
        g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMaxStackZone" ] := settings.MelfMaxStackZone
        g_BrivUserSettingsFromAddons[ "BGFHTS_MelfActiveStrategy" ] := settings.MelfActiveStrategy
        g_BrivUserSettingsFromAddons[ "BGFHTS_MelfInactiveStrategy" ] := settings.MelfInactiveStrategy
        mod50Zones := IC_BrivGemFarm_HybridTurboStacking_Functions.GetPreferredBrivStackZones(settings.PreferredBrivStackZones)
        g_BrivUserSettingsFromAddons[ "BGFHTS_PreferredBrivStackZones" ] := mod50Zones
    }

    BGFHTS_UpdateMelfStackZoneAfterReset(forceUpdate := false)
    {
        static lastResets := 0

        resets := g_SF.Memory.ReadResetsTotal()
        if (forceUpdate || resets > lastResets || !IsObject(this.BGFHTS_CurrentRunStackRange))
        {
            this.BGFHTS_Status := ""
            this.BGFHTS_CurrentRunStackRange := this.BGFHTS_CheckMelf()
            lastResets := resets
        }
        this.BGFHTS_UpdateStacksPredict()
    }

    BGFHTS_CheckMelf()
    {
        resets := g_SF.Memory.ReadResetsTotal()
        maxZone := g_SF.Memory.GetModronResetArea() - 1
        currentZone := g_SF.Memory.ReadCurrentZone()
        ; Modron reset happened but currentZone hasn't been reset to 1 yet.
        minZone := (currentZone == -1 || currentZone > maxZone) ? 1 : currentZone
        minZone := Max(minZone, g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMinStackZone" ])
        maxZone := Min(maxZone, g_BrivUserSettingsFromAddons[ "BGFHTS_MelfMaxStackZone" ])
        range := IC_BrivGemFarm_HybridTurboStacking_Melf.GetFirstSpawnMoreEffectRange(, minZone, maxZone)
        this.BGFHTS_CurrentRunStackRange := range ? range : ["", ""]
        return range
    }

    BGFHTS_UpdateStacksPredict()
    {
        predictStacks := IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive()
        this.BGFHTS_StacksPredictionActive := predictStacks
        if (predictStacks)
            g_SharedData.BGFHTS_SBStacksPredict := IC_BrivGemFarm_Class.BrivFunctions.PredictStacks(True,False,False)
    }

}