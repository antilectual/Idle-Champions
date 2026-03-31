; Overrides IC_BrivGemFarm_Class.GemFarmDoZone()
; Overrides IC_BrivGemFarm_Class.GemFarmPreLoopSetup()
; Overrides IC_BrivGemFarm_Class.GemFarmResetSetup()
; Overrides IC_BrivGemFarm_Class.GemFarmDoNonModronActions()
; Overrides IC_BrivGemFarm_Class.StackFarmSetup()
class IC_BrivGemFarm_LevelUp_Class extends IC_BrivGemFarm_Class
{
    Levelupx25 := {}
    ChampIDs := {}
    ExtraChamps := {}
	SeenStopSign := 0

    InitChamps()
    {
        this.ChampIDs := {}
        this.ChampIDs[Briv := "58"] := 58 ; must be in quotes so object is treated as dict and not an array that will modify keys.
        this.ChampIDs[Widdle := 91] := 91
        this.ChampIDs[Ellywick := 83] := 83
        this.ChampIDs[HewMaan := 75] := 75
        this.ChampIDs[Tatyana := 97] := 97
        this.ChampIDs[Melf := 59] := 59
        this.ChampIDs[Dynaheir := 145] := 145
        this.ChampIDs[Diana := 148] := 148
        this.ChampIDs[BBEG  := 125] := 125
        this.ChampIDs[Dungeon_Master := 99] := 99
        this.ChampIDs[Imoen := 117] := 117
        this.ChampIDs[Laezel  := 128] := 128
        this.ChampIDs[Deekin := 28] := 28
        this.ChampIDs[Virgil := 115] := 115
        this.ChampIDs[Sentry := 52] := 52
        this.ChampIDs[Nahara := 102] := 102
        this.ChampIDs[Dhani := 89] := 89
        this.ChampIDs[Kent := 114] := 114
        this.ChampIDs[Gazrick := 98] := 98
        this.ChampIDs[Alyndra := 79] := 79
        this.ChampIDs[Selise := 81] := 81
        this.ChampIDs[Vi := 95] := 95
        this.ChampIDs[Havilar := 56] := 56
        this.ChampIDs[Shandie := 47] := 47
        this.ChampIDs[Minsc := 7] := 7
        this.ChampIDs[Baldric := 165] := 165 
        this.ChampIDs[Thellora := 139] := 139
    }
    ;=====================================================
    ;Primary Functions for Briv Gem Farm
    ;=====================================================
    GemFarmDoZone(formationModron := "")
    {
        this.DoKeySpam := False
        base.GemFarmDoZone(formationModron)
    }
    
    ; returns 0 on normal exit, otherwise error number < 0
    GemFarmPreLoopSetup()
    {
        isFailed := base.GemFarmPreLoopSetup(True)
        if(!isFailed)
        {
            this.InitChamps()
            g_SF.BGFLU_CalcLastUpgradeLevels()
            g_SharedData.BGFLU_UpdateSettingsFromFile(true)
            g_SharedData.BGFLU_SaveFormations()
        }
        return isFailed
    }

    GemFarmResetSetup(formationModron := "", doBasePartySetup := False)
    {
        g_SharedData.BGFLU_SetStatus("Leveling champions to the minimum level")
        this.FormationLevelingLock := false
        this.SetupFailedConversionDone := true
        resetsCount := base.GemFarmResetSetup(formationModron, doBasePartySetup := False)
        if(this.GemFarmShouldSetFormation())
            g_SF.SetFormationForStart()
        this.BGFLU_DoPartySetupMin(g_BrivUserSettingsFromAddons[ "BGFLU_ForceBrivEllywick" ]) ; level forced champions (briv/ellywick), then other minlevel champs
        this.Levelupx25 := {} 
        this.ExtraChamps := {}
        this.BGFLU_DoPartyWaits(formationModron)
        g_SF.FormationSwitchLock := False
        this.BGFLU_DoBackgroundPartyWaits()
        g_SF.ToggleAutoProgress( 1, false, true )
        return resetsCount
    }
    
    BGFLU_DoBackgroundPartyWaits(bgflu_dbpw_timeout := 900000) ; 15 minute timeout
    {
        bgflu_dbpw_stop := A_LineFile . "\..\stop.txt"
        bgflu_dbpw_start := A_LineFile . "\..\start.txt"
        if (FileExist(bgflu_dbpw_start))
            FileDelete, %bgflu_dbpw_start%
        if (FileExist(bgflu_dbpw_stop))
        {
			if (this.SeenStopSign < 1)
			{
				this.SeenStopSign += 1
				return
			}
            g_SharedData.LoopString := "Background Runner said STOP."
            FileDelete, %bgflu_dbpw_stop%
            ; Wait until start exists.
            bgflu_dbpw_fellback := false
            bgflu_dbpw_begin := A_TickCount
            g_SF.DirectedInput(,, "{p}")
            bgflu_dbpw_elapsedTime := 0
			bgflu_dbpw_currZone := g_SF.Memory.ReadCurrentZone()
            while (!FileExist(bgflu_dbpw_start) && bgflu_dbpw_elapsedTime < bgflu_dbpw_timeout)
            {
                if (!bgflu_dbpw_fellback || !g_SF.IsCurrentFormationLazy(g_SF.Memory.GetFormationByFavorite(1)))
                {
					bgflu_dbpw_counter := 0
                    while (g_SF.Memory.ReadCurrentZone() >= bgflu_dbpw_currZone && bgflu_dbpw_counter < 5)
					{
						g_SF.DirectedInput(,, "{Left}")
						bgflu_dbpw_counter++
						Sleep, 10
					}
					if (g_SF.Memory.ReadCurrentZone() < bgflu_dbpw_currZone)
						bgflu_dbpw_fellback := true
                    loop, 10
                        g_SF.DirectedInput(,, "{q}" ) ; ditch w so Tatyana stops spawning enemies
                }
                Sleep, 50
                bgflu_dbpw_elapsedTime := A_TickCount - bgflu_dbpw_begin
            }
            if (elapsedTime >= bgflu_dbpw_timeout)
                g_SharedData.LoopString := "Timed out waiting for Background Runner."
            else
                g_SharedData.LoopString := "Background Runner said START."
            FileDelete, %bgflu_dbpw_start%
        }
		this.SeenStopSign := 0
    }

    GemFarmDoNonModronActions(currentZone := "")
    {
        static lastTick := 0
        needToStack := this.BGFLU_NeedToStack()
        ; Level up Briv to MaxLevel after stacking
        if (!needToStack AND g_SF.Memory.ReadChampLvlByID(ActiveEffectKeySharedFunctions.Briv.HeroID) < g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ].maxLevels[ActiveEffectKeySharedFunctions.Briv.HeroID])
            this.FormationLevelingLock := false
        ; Check for failed stack conversion
        if (g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversion" ] AND g_SF.Memory.ReadHasteStacks() < 50 AND needToStack)
            this.SetupFailedConversionDone := false
        if (currentZone > 5 AND !g_SF.FormationLevelingLock) ; ignore doing max at setup since this method runs first.
            this.BGFLU_DoPartySetupMax() ; Level up all champs to the specified max level
        else if (!this.SetupFailedConversionDone)
            this.SetupFailedConversionDone := this.BGFLU_DoPartySetupFailedConversion() ; Level up all champs to soft cap (including Briv if option checked)
        if (g_SharedData.BGFLU_UpdateMaxLevels) 
        {
            this.FormationLevelingLock := false ; Trigger start max leveling
            g_SharedData.BGFLU_UpdateMaxLevels := false
            ; Stop click spam
            if (!g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ])
                g_SF.BGFLU_StopSpamClickDamage()
        }
        if(A_TickCount - lastTick < g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ])
            return
        ; Click damage
        if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ])
            g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel())
        else if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ])
            g_SF.BGFLU_DoClickDamageSetup(g_BrivUserSettingsFromAddons[ "BGFLU_MaxSimultaneousInputs" ])
        else
            g_SF.BGFLU_DoClickDamageSetup(1)
    }

    ; Stops progress and switches to appropriate party to prepare for stacking Briv's SteelBones.
    StackFarmSetup(setUIString := False)
    {
        if(setUIString)
            g_SharedData.LoopString := "Switching to stack farm formation."
        if (!this.BossKillAttempt AND !g_SF.KillCurrentBoss() ) ; Previously/Alternatively FallBackFromBossZone()
            this.BossKillAttempt := True, g_SF.FallBackFromBossZone() ; Boss kill Timeout
        inputValues := "{w}" ; Stack farm formation hotkey
        g_SF.DirectedInput(,, inputValues )
        keyspam := this.BGFLU_GetMinLevelingKeyspam(g_SF.Memory.GetFormationByFavorite(2))
        g_SF.WaitForTransition( inputValues )
        g_SF.DirectedInput(,, keyspam*)
        g_SF.ToggleAutoProgress( 0 , false, true )
        timeout := 5000
        counter := 0
        sleepTime := g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ]
        if(setUIString)
            g_SharedData.LoopString := "Setting stack farm formation."
        stackFormation := g_SF.Memory.GetFormationByFavorite(2)
        if(g_SF.IsCurrentFormationLazy(g_SF.Memory.GetFormationByFavorite(2)))
            isFormation2 := True
        timeoutTimer := new SH_SharedTimers()
        while (!isFormation2 AND !timeoutTimer.IsTimeUp(timeout) )
        {
            if (!timeoutTimer.IsTimeUp(sleepTime * counter)) ; input limiter..
                g_SF.DirectedInput(,,inputValues)
            if (timeoutTimer.IsTimeUp(1000) AND !isFormation2 && (g_SF.Memory.ReadNumAttackingMonstersReached() > 10 || g_SF.Memory.ReadNumRangedAttackingMonsters()))
            {
                 ; not W formation or briv is benched
                if (g_SF.Memory.ReadChampBenchedByID(ActiveEffectKeySharedFunctions.Briv.HeroID) OR !(g_SF.Memory.ReadMostRecentFormationFavorite() == 2))
                    g_SF.FallBackFromZone()
            }
            else
                this.BGFLU_DoPartySetupMax(stackFormation)
            if(g_SF.IsCurrentFormationLazy(stackFormation))
                isFormation2 := True
            counter++
        }
        g_SharedData.LoopString := "Stack farm formation set."
        return
    }
}

class IC_BrivGemFarm_LevelUp_Added_Class ; Added to IC_BrivGemFarm_Class
{
    /*  BGFLU_DoPartySetupMin - When gem farm is started or an adventure is reloaded, this is called to set up the primary party.
                          This will only level champs to the minimum target specified in BrivGemFarm_LevelUp_Settings.json.
                          This will not level champs whose minimum level is set to 0.
                          It will wait for Shandie dash / Thellora Rush if necessary.
                          It will only level up at a time the number of champions specified in the MaxSimultaneousInputs setting.
        Parameters:       forceBrivEllywick: bool - If true, force Briv/Ellywick to minLevel before leveling other champions
                          timeout: integer - Time in ms before abandoning the initial leveling

        Returns:
    */
    BGFLU_DoPartySetupMin(forceBrivEllywick := false, timeout := 10000, initialFormation := "")
    {
        currentZone := g_SF.Memory.ReadCurrentZone()
        if(!g_SF.FormationSwitchLock) ; don't show leveling string before ellywait.
        {
            this.SetPreviousLoopString()
            g_SharedData.LoopString .= " - Party setup Min"
        }
        if (forceBrivEllywick || currentZone == 1)
            g_SF.ToggleAutoProgress( 0, false, true )
        if(initialFormation == "")
            formation := g_SF.GetInitialFormation()
        g_SF.SetFormationForStart()
        ; Level up speed champs first, priority to getting Briv, Ellywick, Hew Maan, Nahara, Sentry, Virgil speed effects
        ; Set formation
        StartTime := A_TickCount
        ; If low favor mode is active, cheapest upgrade first
        if (!g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ])
            keyspam := this.BGFLU_DoPartySetupMin_NoLowFavor(formation, forceBrivEllywick, timeout, currentZone)
        else {
            formationInOrder := this.BGFLU_OrderByCheapestUpgrade(formation)
            keyspam := this.BGFLU_GetMinLevelingKeyspamLowFavor(formationInOrder, forceBrivEllywick)
        }
        if(keyspam != "" AND keyspam != {})
            remainingTime := timeout ; reset timeout
        else
            remainingTime := timeout - (A_TickCount - StartTime)
        g_SF.DirectedInput(hold := 0,, keyspam*) ; keysup
        if (forceBrivEllywick AND remainingTime > 0)
        {
            this.ResetToPreviousLoopString()
            this.BGFLU_DoPartySetupMin(false, remainingTime, formation) ; do normal after do forced.
        }
        if (currentZone == 1 || g_SharedData.TriggerStart)
            g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel(), Max(remainingTime, 2000))
        ; Click damage (should be enough to kill monsters at the area Thellora jumps to unless using x1)
        this.ResetToPreviousLoopString()
        return keyspam == {}
    }

    BGFLU_DoPartySetupMin_NoLowFavor(formation, forceBrivEllywick := false, timeout := "", currentZone := 1)
    {
        timeout := timeout == "" ? g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelTimeout" ] : timeout
        timeout := timeout == "" ? 10000 : timeout
        keyspam := {}
        keyspam.Push("")
        loopCount := 0
        allowClick := False
        timeoutTimer := new SH_SharedTimers()
        while(keyspam.Length() != 0 AND !timeoutTimer.IsTimeUp(timeout)) {
            if(2 < loopCount++) 
                allowClick := True
            keyspam := this.BGFLU_DoPartySetupMinInnerLoop_NoLowFavor(formation, forceBrivEllywick, currentZone, allowClick)
        }
        return keyspam
    }

    BGFLU_DoPartySetupMinInnerLoop_NoLowFavor(formation, forceBrivEllywick := false, currentZone := 1, allowClick := True)
    {
        keyspam := {}
        ; Update formation on zone change
        if (currentZone < g_SF.Memory.ReadCurrentZone()) {
            currentZone := g_SF.Memory.ReadCurrentZone()
            formation := g_SF.GetInitialFormation()
        }
        keyspam := this.BGFLU_GetMinLevelingKeyspam(formation, forceBrivEllywick, currentZone)
        ; Level up speed champions once
        g_SF.DirectedInput(,, keyspam*)
        ; Set formation
        g_SF.SetFormationForStart()
        Sleep, % g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ]
        ; Level Clicks
        if(allowClick OR currentZone > 1)
        {
            if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ])
                g_SF.BGFLU_DoClickDamageSetup(, this.BGFLU_GetClickDamageTargetLevel())
            g_SF.BGFLU_DoClickDamageSetup(1, this.BGFLU_GetClickDamageTargetLevel())
        }
        return keyspam
    }

    BGFLU_DoPartyWaits(formation)
    {
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea()
        if (!g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] AND g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        this.BGFLU_DoPartySetupMin(g_BrivUserSettingsFromAddons[ "BGFLU_ForceBrivEllywick" ])
        g_SF.FormationLevelingLock := False
        if (g_SF.IsChampInFormation(ActiveEffectKeySharedFunctions.Thellora.HeroID, formation))
            g_SF.DoRushWait()
    }

    ; Returns a list of FKeys that are spammed during min leveling.
    ; Params: formation:array - List of champion IDs.
    ;         forceBrivEllywick:bool - If true, only Briv and Ellywick are leveled.

    BGFLU_GetMinLevelingKeyspam(formation, forceBrivEllywick := false, currentZone := 0)
    {
        keyspam := [], nonSpeedIDs := {}
        allowBrivLeveling := this.BGFLU_AllowBrivLeveling()
        ; Need to walk while Briv is in all formations
        if (!forceBrivEllywick)
            for k, champID in formation
                if (champID > 0 AND (champID != 58 OR allowBrivLeveling)) ; Need to walk while Briv is in all formations
                    nonSpeedIDs[champID] := champID
        ; Get Fkeys for speed champs
        while (keyspam.Length() < g_BrivUserSettingsFromAddons[ "BGFLU_MaxSimultaneousInputs" ])
        {
            for k, champID in formation
            {
                isEllywickAndForce := forceBrivEllywick AND champID == ActiveEffectKeySharedFunctions.Ellywick.HeroID
                isBrivAndForce := forceBrivEllywick AND champID == ActiveEffectKeySharedFunctions.Briv.HeroID
                IsNotForce := !forceBrivEllywick AND this.ChampIDs[champID] == champID
                if (isBrivAndForce OR isEllywickAndForce OR IsNotForce)
                {
                    if((champID == ActiveEffectKeySharedFunctions.Briv.HeroID && !allowBrivLeveling))
                        continue
                    if (this.BGFLU_ChampUnderTargetLevel(champID, this.BGFLU_GetTargetLevel(champID, "Min")) AND (champID == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(champID))))
                        keyspam.Push(this.BGFLU_GetFKey(champID))
                    if (!forceBrivEllywick)
                        nonSpeedIDs.Delete(champID)
                }
            }
            if (keyspam.Length() == 0) ; no champs to add, length cannot reach MaxSimultaneousInputs > 0 here.
                break
        }
        ; Get Fkeys for other champs
        for k, champID in nonSpeedIDs ; nonspeedIDs empty if !forceEllywick (if that were not the case, check !forceEllywick before this)
        {
            if (g_SF.FormationLevelingLock) ; waits until formation lock
                break
            if (this.BGFLU_ChampUnderTargetLevel(champID, this.BGFLU_GetTargetLevel(champID, "Min")) AND (champID == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(champID))))
                keyspam.Push(this.BGFLU_GetFKey(champID))
        }
        return keyspam
    }

    ; Returns a list of FKeys that are spammed during min leveling.
    ; The low favor version doesn't use the priority list of speed champions,
    ; rather the list of champions ordered by lowest upgrade cost first.
    ; If a champion upgrade can't be afforded, the champion won't be leveled up.
    ; Params: formation:array - List of champion IDs.
    ;         forceBrivEllywick:bool - If true, only Briv and Ellywick are leveled.
    BGFLU_GetMinLevelingKeyspamLowFavor(formation, forceBrivEllywick := false)
    {
        keyspam := []
        if (forceBrivEllywick)
        {
            champIDs := []
            for k, champID in formation
            {
                ; Need to walk while Briv is in all formations
                if (champID == 58 && this.BGFLU_AllowBrivLeveling())
                    champIDs.Push(champID)
                else if (champID == 47)
                    champIDs.Push(champID)
            }
            formation := champIDs
        }
        for k, champID in formation
            if (this.BGFLU_ChampUnderTargetLevel(champID, this.BGFLU_GetTargetLevel(champID, "Min")))
                if this.BGFLU_CanAffordUpgrade(champID)
                    keyspam.Push(this.BGFLU_GetFKey(champID))
        return keyspam
    }

    /*  BGFLU_DoPartySetupMax - Level up all champs to the specified max level.
        This will not level champs whose maximum level is set at 0.
        Returns: bool - True if all champions in Q formation are at or past their target level, false otherwise.
    */
    BGFLU_DoPartySetupMax(formation := "")
    {
        if(this.FormationLevelingLock)
            return
        levelBriv := True
        ; Speed champions without Briv
        updateLoopString := !g_SF.FormationSwitchLock AND g_SF.Memory.ReadMostRecentFormationFavorite() != 2
        this.SetPreviousLoopString()
        if(updateLoopString) ; don't show leveling string before ellywait finishes or when stacking.
            g_SharedData.LoopString .= " - Party setup Max" ; Will be added multiple times if not cleared in previous function after returning.
        if (!formation)
        {
            formation := g_SF.GetInitialFormation() ; probably modron
            if(this.ExtraChamps.Count() == 0 and formation != "")
            {  
                qFormation := g_SF.Memory.GetFormationByFavorite(1)
                for k,v in qFormation
                    if(v > 0 AND !g_SF.IsChampInFormation(v, formation))
                        this.ExtraChamps.push(v)
            }
        }
        formation := this.BGFLU_GetFormationNoEmptySlots(formation)
        if (this.BGFLU_ChampUnderTargetLevel(ActiveEffectKeySharedFunctions.Briv.HeroID, this.BGFLU_GetTargetLevel(ActiveEffectKeySharedFunctions.Briv.HeroID, "Min")))
        {
            levelBriv := false
            if (this.BGFLU_AllowBrivLeveling()) ; Level Briv to be able to skip areas
                this.BGFLU_DoPartySetupMin_NoLowFavor(formation, forceBrivEllywick := True) 
        }
        ; Speed champions are leveled up first (without Briv)
        ; If low favor mode is active, cheapest upgrade first
        if (g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ])
            formation := this.BGFLU_OrderByCheapestUpgrade(formation)
        else
            for k, champID in formation
                if (this.ChampIDs[champID] == champID) ; Is speed champ
                {
                    if (g_SF.FormationLevelingLock)
                        return this.ResetToPreviousLoopString()
                    targetLevel := this.CalculateTargetLevel(champID)
                    if (champID == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(champID)) && !this.BGFLU_LevelUpChamp(champID, targetLevel)) ; champ in seat and leveling them is successful (at or over target level)
                        break ; do once per call
                }
        ; Now do x25 levelling.
        levelBriv := levelBriv AND this.DoX25Leveling() 
        ; Complete leveling
        for k, champID in formation
        {
            if (champID != g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(champID)))
                continue
            targetLevel := this.CalculateTargetLevel(champID)
            ; Briv
            if (champID == 58 AND !levelBriv)
                continue
            if (champID == 58 AND this.BGFLU_NeedToStack())
                targetLevel := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelStacking" . (g_BrivGemFarm.ShouldOfflineStack() ? "" : "Online") ]
            if (!this.BGFLU_LevelUpChamp(champID, targetLevel))
                return this.ResetToPreviousLoopString()
        }
        ; complete extra champion leveling
        for k, champID in this.ExtraChamps
        {
            if (champID != g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(champID)))
                continue
            targetLevel := this.CalculateTargetLevel(champID)
            if (this.BGFLU_LevelUpChamp(champID, targetLevel))
            {
                this.ExtraChamps.delete(k)
                return this.ResetToPreviousLoopString()
            }
        }
        levelBriv := levelBriv AND this.DoX25Leveling() AND this.ExtraChamps.Count() == 0
        if (levelBriv)
        {
            this.FormationLevelingLock := True
            g_SharedData.BGFLU_SetStatus("All champions leveled up.")
        }
        return this.ResetToPreviousLoopString()
    }

    ; Returns True if all champs are done with x25, false if champs still need leveling.
    DoX25Leveling()
    {
        levelBriv := false
        if (!g_SF.ArrSize(this.Levelupx25) > 0) ; nothing to level
            return true       
        for champID, targetLevel in this.Levelupx25
        {
            champSeat := g_SF.Memory.ReadChampSeatByID(champID)
            champIDInSeat := g_SF.Memory.ReadSelectedChampIDBySeat(champSeat)
            if (!this.BGFLU_ChampUnderTargetLevel(champID, targetLevel))
            {
                this.Levelupx25.delete(champID) 
                continue
            }
            if (champID != champIDInSeat)
                continue
            else if(((targetLevel - g_SF.Memory.ReadChampLvlByID(champID)) / 100 >= 1) AND !this.BGFLU_LevelUpChamp(champID, targetLevel, False))
                return false ; return false if leveled up conventionally and is still underleveled.
            else if (!this.BGFLU_LevelUpChamp(champID, targetLevel, True)) 
                return false ; return false if still under leveled
            this.Levelupx25.delete(champID)
        }
        if (!g_SF.ArrSize(this.Levelupx25) > 0) ; done leveling
            return true
        return levelBriv
    }

    CalculateTargetLevel(champID)
    {
            targetLevel := this.BGFLU_GetTargetLevel(champID)
            targetLevelMod := Mod(targetLevel, 100)
            if (targetLevelMod > 0 && this.BGFLU_ChampUnderTargetLevel(champID, targetLevel))
            {
                this.Levelupx25[champID] := targetLevel
                targetLevel := targetLevel - targetLevelMod
            }
            return targetLevel
    }

    ToggleShift(shiftKeyDown := false)
    {
        g_SF.DirectedInput(shiftKeyDown, !shiftKeyDown, "{Shift}")
        timeoutTimer := new SH_SharedTimers()
        while (this.ClickDamageLevelAmount() == 10 AND !timeoutTimer.IsTimeUp(100)) ;Allow 100ms for the keypress to apply at maximum to avoid getting stuck. On a fast PC it only took AHK tick (15ms) extra when needed
            Sleep 1
    }
    
    ToggleControl(controlKeyDown := false)
    {
        g_SF.DirectedInput(controlKeyDown, !controlKeyDown, "{RCtrl}")
        timeoutTimer := new SH_SharedTimers()
        while (this.ClickDamageLevelAmount() == 25 AND !timeoutTimer.IsTimeUp(100)) ;Allow 100ms for the keypress to apply at maximum to avoid getting stuck. On a fast PC it only took AHK tick (15ms) extra when needed
            Sleep 1
    }
    
	ClickDamageLevelAmount() ;This is the base amount set per levelling seletion, e.g. always 1/10/25/100
    {
        return this.GameManager.game.gameInstances[0].Screen.uiController.bottomBar.heroPanel.clickDamageBox.levelUpAmount.Read()
    }
    
    /*  BGFLU_DoPartySetupFailedConversion - Level up all champs to soft cap after a failed conversion.
        If the setting LevelToSoftCapFailedConversionBriv is set to true, also level Briv.

        Returns: bool - True if all champions in Q formation are soft capped, false otherwise
    */
    BGFLU_DoPartySetupFailedConversion(formation := "")
    {
        if (!formation)
            formation := g_SF.GetInitialFormation()
        else
            formation := this.BGFLU_GetFormationNoEmptySlots(formation)
        if (g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ])
            formation := this.BGFLU_OrderByCheapestUpgrade(formation)
        modronFormation := g_SF.Memory.GetActiveModronFormation() ; required as a champ not in modron will never be seen as max because it can't upgrade past its specialization.
        for k, champID in formation
            if (g_SF.IsChampInFormation(champID, formation) AND g_SF.IsChampInFormation(champID, modronFormation) AND (champID != 58 OR g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversionBriv" ]))
                if (!this.BGFLU_LevelUpChamp(champID, g_SF.BGFLU_GetLastUpgradeLevel(champID)))
                    return false
        g_SharedData.BGFLU_SetStatus("Finished leveling champions.")
        return true
    }

    ; Returns the minimum / maximum level a champion should be leveled at.
    ; Params: champID:int - ID of the champion.
    ;         minOrMax:str - If equal to "Min", level up the champion to minLevel,
    ;                        or to 0 or 1 depending on default settings.
    ;                        If equal to "Max", level up the champion to maxLevel,
    ;                        or to 1 or last upgrade depending on default settings.
    BGFLU_GetTargetLevel(champID := 0, minOrMax := "Max")
    {
        if (champID < 1)
            return 0
        levelSettings := g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ]
        if (minOrMax == "Min")
        {
            if (levelSettings.minLevels[champID] != "")
                return levelSettings.minLevels[champID]
            minLevel := g_BrivUserSettingsFromAddons[ "BGFLU_DefaultMinLevel" ]
            return (minLevel == "") ? 0 : minLevel
        }
        else if (minOrMax == "Max")
        {
            if (levelSettings.maxLevels[champID] != "")
                return levelSettings.maxLevels[champID]
            maxLevel := g_BrivUserSettingsFromAddons[ "BGFLU_DefaultMaxLevel" ]
            if (maxLevel == "Last")
                return g_SF.BGFLU_GetLastUpgradeLevel(champID)
            else
                return (maxLevel == "") ? 1 : maxLevel
        }
        else
            return 0
    }

    ; Returns true if the champion needs to be leveled.
    BGFLU_ChampUnderTargetLevel(champID := 0, target := 0)
    {
        if (champID < 1)
            return false
        if target is not integer
            return false
        return target != 0 && g_SF.Memory.ReadChampLvlByID(champID) < target
    }

    ; Returns the target value for click damage level.
    ; Min click damage value should be 1 after resetting.
    BGFLU_GetClickDamageTargetLevel()
    {
        setting := g_BrivUserSettingsFromAddons[ "BGFLU_MinClickDamage" ]
        if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ])
            return Max(setting, ((highestLvl := g_SF.Memory.ReadHighestZone()) > 1000 ? highestLvl + 100 : highestLvl))
        return Max(1, setting)
    }

    ; Returns true if stacking Briv is necessary during this run.
    BGFLU_NeedToStack()
    {
        stacks := this.GetNumStacksFarmed()
        return stacks < g_BrivUserSettings[ "TargetStacks" ]
    }

    ; List of conditions that enable or disable Briv leveling.
    ; If Briv is under level 80, he can't jump. Then walking is possible even
    ; Briv is in the field formation, e.g. for feat swapping.
    BGFLU_AllowBrivLeveling()
    {
        ; Briv can't skip zones if he has under 50 stacks
        if (g_SF.Memory.ReadHasteStacks() < 50)
            return true
        highestZone := g_SF.Memory.ReadHighestZone()
        brivMinLevelArea := g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ]
        if (highestZone < brivMinLevelArea)
            return false
        if (g_BrivUserSettingsFromAddons[ "BGFLU_BrivThelloraCombineBossCheck" ] && IC_BrivGemFarm_LevelUp_Functions.ThelloraBrivCombineHitsBoss())
            return false
        ; Wait for transition to highestZone before leveling during DoRushWait()
        if (highestZone == brivMinLevelArea && !g_SF.Memory.ReadTransitioning())
        {
            if (g_SF.Memory.ReadCurrentZone() < highestZone)
                return false
        }
        mod50Index := Mod(highestZone, 50) == 0 ? 50 : Mod(highestZone, 50)
        mod50Zones := g_BrivUserSettingsFromAddons[ "BGFLU_BrivLevelingZones" ]
        if (mod50Zones[mod50Index] == 0 && this.BGFLU_ChampUnderTargetLevel(ActiveEffectKeySharedFunctions.Briv.HeroID, 80))
            return false
        return true
    }

    ; Returns the list of champion IDs sorted by cheapast upgrade first.
    ; Params: champIDs:array - List of champion IDs.
    ;         num:int - Number of champions that need to be returned.
    BGFLU_GetCheapestUpgrade(champIDs, num := 1)
    {
        if (num == 1 && champIDs.Length() == num)
            return champIDs
        cheapest := []
        costs := {}
        for k, champID in champIDs
        {
            if (champID < 1)
                continue
            seat := g_SF.Memory.ReadChampSeatByID(champID)
            cost := g_SF.Memory.ReadLevelUpCostBySeat(seat)
            i := IC_BrivGemFarm_LevelUp_Functions.ConvertNumberStringToInt(cost)
            costs[i] := champID
        }
        for k, v in costs
        {
            if (num-- < 1)
                break
            cheapest.Push(v)
        }
        return cheapest
    }

    BGFLU_OrderByCheapestUpgrade(formation)
    {
        return this.BGFLU_GetCheapestUpgrade(formation, formation.Length())
    }

    BGFLU_GetFormationNoEmptySlots(formation)
    {
        ids := {}
        for k, champID in formation
        {
            if (champID > 0)
                ids.Push(champID)
        }
        return ids
    }

    ; Returns TRUE if champ has leveled to completion. Otherwise false.
    BGFLU_LevelUpChamp(champID, target, isX25 := False)
    {
        if (this.BGFLU_ChampUnderTargetLevel(champID, target))
        {
            ; Level up a single champion once
            text := "Leveling " . g_SF.Memory.ReadChampNameByID(champID) . " to the maximum level (" . target . ")"
            g_SharedData.BGFLU_SetStatus(text)
            if(isX25)
                this.ToggleControl(true) ; To go back to x10 - change to ToggleShift
            g_SF.DirectedInput(,, this.BGFLU_GetFKey(champID))
            if(isX25)
                this.ToggleControl(false) ; To go back to x10 - change to ToggleShift
            needsLeveling := this.BGFLU_ChampUnderTargetLevel(champID, target)
            if (!needsLeveling)
                return true
            else
                return false
        }
        return true
    }

    BGFLU_GetFKey(champID)
    {
        if (champID < 1)
            return ""
        return "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}"
    }

    BGFLU_CanAffordUpgrade(champID)
    {
        if (champID < 1)
            return false
        seat := g_SF.Memory.ReadChampSeatByID(champID)
        cost := g_SF.Memory.ReadLevelUpCostBySeat(seat)
        gold := g_SF.Memory.ReadGoldString()
        compareIntCost := IC_BrivGemFarm_LevelUp_Functions.ConvertNumberStringToInt(cost)
        compareIntGold := IC_BrivGemFarm_LevelUp_Functions.ConvertNumberStringToInt(gold)
        return compareIntCost < compareIntGold
    }
}

; Overrides IC_BrivSharedFunctions_Class.GetInitialFormation()
; Overrides IC_BrivSharedFunctions_Class.DoRushWait()
; Overrides IC_BrivSharedFunctions_Class.InitZone()
; Overrides IC_SharedFunctions_Class.DoDashWaitingIdling()
; Overrides IC_SharedFunctions_Class.SetFormationForStart()
class IC_BrivGemFarm_LevelUp_SharedFunctions_Class extends IC_SharedFunctions_Class
{
    ; Special case for Thellora+Briv combined jump on z1 if z1 is set to walk in advanced settings.
    GetInitialFormation()
    {
        currentZone := this.Memory.ReadCurrentZone()
        if (currentZone == 1)
        {
            Switch this.BGFLU_GetZ1FormationKey()
            {
                case "q":
                    favorite := 1
                case "w":
                    favorite := 2
                case "e":
                    favorite := 3
                default:
                    favorite := 1
            }
        }
        else
        {
            settings := g_BrivUserSettings[ "PreferredBrivJumpZones" ]
            mod50Index := Mod(currentZone, 50) == 0 ? 50 : Mod(currentZone, 50)
            favorite := settings[mod50Index] ? 1 : 3
        }
        ; Without empty slots
        return this.Memory.GetFormationSaveBySlot(this.Memory.GetSavedFormationSlotByFavorite(favorite), true)
    }

    DoDashWaitingIdling(startTime := 1, estimate := 1)
    {
        this.ToggleAutoProgress(0)
        this.SetFormationForStart()
        g_BrivGemFarm.BGFLU_DoPartySetupMin() ; min before ellywait.Get DM out.
        this.BGFLU_DoClickDamageSetup(1, this.BGFLU_GetClickDamageTargetLevel())
        ElapsedTime := A_TickCount - StartTime
        g_SharedData.LoopString := "Dash Wait: " . ElapsedTime . " / " . estimate
        percentageReducedSleep := Max(Floor((1-(ElapsedTime/estimate))*estimate/10 + 15), 15)
        Sleep, %percentageReducedSleep%
    }

    ; Special case for Thellora+Briv combined jump on z1 if z1 is set to walk in advanced settings.
    SetFormationForStart()
    {
        if (this.Memory.ReadCurrentZone() == 1 AND "q" != (key := this.BGFLU_GetZ1FormationKey())) ; walk formation exception
            this.DirectedInput(,, "{" . key . "}") ; do before check ?
        else if ( this.Memory.ReadCurrentZone() == 1 )
            return
        else 
            this.SetFormation(g_BrivUserSettings)
    }

    BGFLU_SecondWindActive()
    {
        feats := this.Memory.GetHeroFeats(ActiveEffectKeySharedFunctions.Shandie)
        for k, v in feats
            if (v == 1035)
                return true
        return false
    }

    DoRushWaitIdling(StartTime, estimate)
    {
        this.ToggleAutoProgress(0)
        this.SetFormationForStart()
        g_BrivGemFarm.BGFLU_DoPartySetupMax() ; max after.
        this.BGFLU_DoClickDamageSetup(1, this.BGFLU_GetClickDamageTargetLevel())
        ElapsedTime := A_TickCount - StartTime
        g_SharedData.LoopString := "Rush Wait: " . ElapsedTime . " / " . estimate
        Sleep, 30
        return ElapsedTime - 30
    }

    ; Does once per zone tasks like pressing leveling keys
    InitZone( spam )
    {
        global g_PreviousZoneStartTime
        Critical, On
        if (g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ] AND !g_SF.FormationLevelingLock)
        {
            ; Level up click damage once
            this.BGFLU_DoClickDamageSetup(1)
            ; turn Fkeys off/on again
            this.DirectedInput(hold := 0,, spam*) ;keysup
            this.DirectedInput(,release := 0, spam*) ;keysdown
        }
        ; try to progress
        this.DirectedInput(,,"{Right}")
        this.ToggleAutoProgress(1)
        this.ModronResetZone := this.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        g_PreviousZoneStartTime := A_TickCount
        Critical, Off
    }
}

class IC_BrivGemFarm_LevelUp_SharedFunctions_Added_Class ; Added to IC_BrivSharedFunctions_Class
{
;    BGFLU_LastUpgradeLevelByID := ""

    BGFLU_GetZ1FormationKey()
    {
        z1Formation := g_BrivUserSettingsFromAddons[ "BGFLU_FavoriteFormationZ1" ]
        if (z1Formation == "")
            z1Formation := "q"
        z1Formation := Format("{:L}", z1Formation)
        return z1Formation
    }

    ; LevelUp click damage.
    ; Params: numClicks:int - Number of clicks on level click damage.
    ;                         If set to 0, levels up to clickLevel.
    ;         clickLevel:int - If set at higher than 0, click damage is leveled up to this value.
    ;                          If numClicks is set at 1, will exit after 1 click.
    ;         timeout:int - Maximum waiting time.
    BGFLU_DoClickDamageSetup(numClicks := 0, clickLevel := 0, timeout := 100)
    {
        ; Don't level up click damage if the is not enough gold for at least one upgrade.
        maxAmount := g_SF.Memory.BGFLU_ReadClickLevelUpAllowed()
        if (maxAmount == 0)
            return
        if (this.Memory.ReadClickLevel() >= clickLevel)
            return
        if (numClicks == 1)
            return this.BGFLU_LevelClickDamage(1)
        if (clickLevel > 0)
        {
            timeoutTimer := new SH_SharedTimers()
            while (this.Memory.ReadClickLevel() < clickLevel && !timeoutTimer.IsTimeUp(timeout))
            {
                ; Stop leveling up if not enough gold for a full upgrade.
                maxAmount := g_SF.Memory.BGFLU_ReadClickLevelUpAllowed()
                this.BGFLU_LevelClickDamage(1)
                levelUpAmount := g_SF.Memory.ReadLevelUpAmount()
                if (levelUpAmount > 1 && maxAmount < levelUpAmount)
                    return
            }
        }
        else if (numClicks > 0)
            this.BGFLU_LevelClickDamage(numClicks)
    }

    ; Level up click damage.
    ; Params: numClicks:int - Number of clicks on level click damage.
    BGFLU_LevelClickDamage(numClicks := 1)
    {
        Critical, On
        Loop, % numClicks
        {
            this.DirectedInput(,release := 0, "{ClickDmg}") ;keysdown
            this.DirectedInput(hold := 0,, "{ClickDmg}") ;keysup
        }
        Critical, Off
    }

    ; Stop click damage input.
    BGFLU_StopSpamClickDamage()
    {
        Critical, On
        this.DirectedInput(hold := 0,, "{ClickDmg}") ;keysup
        Critical, Off
    }

    ; Retrieves the required level of the last upgrade of a champion.
    BGFLU_GetLastUpgradeLevel(champID)
    {
        if (champID == "" || champID < 1)
            return 0
        ; Look for value in cache.
        ; The actual value could change because of definitions being updated
        ; when a new event starts, balance patch or level cap increase.
        cachedLevels := this.BGFLU_LastUpgradeLevelByID
        if !IsObject(cachedLevels)
            this.BGFLU_LastUpgradeLevelByID := cachedLevels := {}
        if (cachedLevels.HasKey(champID) && cachedLevels[champID] != "")
            return cachedLevels[champID]
        ; Loop upgrades until the upgrade with the highest level is found.
        size := this.Memory.ReadHeroUpgradesSize(champID)
        ; Sanity check
        if (size < 1 || size > 1000)
            return 0
        maxUpgradeLevel := 0
        Loop, %size%
        {
            requiredLevel := this.Memory.ReadHeroUpgradeRequiredLevelByIndex(champID, A_Index - 1) ;bugfix
            if (requiredLevel != "" AND requiredLevel != 9999)
                maxUpgradeLevel := Max(requiredLevel, maxUpgradeLevel)
        }
        cachedLevels[champID] := maxUpgradeLevel
        return maxUpgradeLevel
    }
}

class IC_BrivGemFarm_LevelUp_IC_SharedData_Added_Class ; Added to IC_SharedData_Class
{
;    BGFLU_Status := ""
;    BGFLU_UpdateMaxLevels := false ; Update max level immediately

    ; Return true if the class has been updated by the addon
    BrivGemFarmLevelUpRunning()
    {
        return true
    }

    ; Return true if the class has been updated by the addon
    BGFLU_Running()
    {
        return true
    }

    BGFLU_SetStatus(text := "")
    {
        this.BGFLU_Status := text
    }

    ; Load settings from the GUI settings file
    BGFLU_UpdateSettingsFromFile(updateMaxLevels := false, fileName := "")
    {
        if (fileName == "")
            fileName := IC_BrivGemFarm_LevelUp_Functions.SettingsPath
        settings := g_SF.LoadObjectFromJSON(fileName)
        if (!IsObject(settings))
            return false
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivGemFarm_LevelUp_Settings" ] := settings.BrivGemFarm_LevelUp_Settings
        g_BrivUserSettingsFromAddons[ "BGFLU_DefaultMinLevel" ] := settings.DefaultMinLevel
        g_BrivUserSettingsFromAddons[ "BGFLU_DefaultMaxLevel" ] := settings.DefaultMaxLevel
        g_BrivUserSettingsFromAddons[ "BGFLU_ForceBrivEllywick" ] := settings.ForceBrivEllywick
        g_BrivUserSettingsFromAddons[ "BGFLU_SkipMinDashWait" ] := settings.SkipMinDashWait
        g_BrivUserSettingsFromAddons[ "BGFLU_MaxSimultaneousInputs" ] := settings.MaxSimultaneousInputs
        g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelInputDelay" ] := settings.MinLevelInputDelay
        g_BrivUserSettingsFromAddons[ "BGFLU_MinLevelTimeout" ] := settings.MinLevelTimeout
        g_BrivUserSettingsFromAddons[ "BGFLU_FavoriteFormationZ1" ] := settings.FavoriteFormationZ1
        g_BrivUserSettingsFromAddons[ "BGFLU_LowFavorMode" ] := settings.LowFavorMode
        g_BrivUserSettingsFromAddons[ "BGFLU_MinClickDamage" ] := settings.MinClickDamage
        g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageMatchArea" ] := settings.ClickDamageMatchArea
        g_BrivUserSettingsFromAddons[ "BGFLU_ClickDamageSpam" ] := settings.ClickDamageSpam
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelStacking" ] := settings.BrivMinLevelStacking
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelStackingOnline" ] := settings.BrivMinLevelStackingOnline
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivMinLevelArea" ] := settings.BrivMinLevelArea
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivThelloraCombineBossCheck" ] := settings.BrivThelloraCombineBossCheck
        mod50Zones := IC_BrivGemFarm_LevelUp_Functions.ConvertBitfieldToArray(settings.BrivLevelingZones)
        g_BrivUserSettingsFromAddons[ "BGFLU_BrivLevelingZones" ] := mod50Zones
        g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversion" ] := settings.LevelToSoftCapFailedConversion
        g_BrivUserSettingsFromAddons[ "BGFLU_LevelToSoftCapFailedConversionBriv" ] := settings.LevelToSoftCapFailedConversionBriv
        if (updateMaxLevels)
            this.BGFLU_UpdateMaxLevels := true
    }

    ; Save full Q,W,E formations to BrivGemFarm_LevelUp_Settings.json
    BGFLU_SaveFormations()
    {
        static formationsFromIndex := {1: "Q", 2: "W", 3: "E", 4: "M"}
        static lastFormations := ""
        static lastFormationsNotSaved := true

        CurrentObjID := g_SF.Memory.ReadCurrentObjID() ; VerifyAdventureLoaded()
        if (CurrentObjID == "" OR CurrentObjID <= 0)
            return
        settings := g_SF.LoadObjectFromJSON(IC_BrivGemFarm_LevelUp_Functions.SettingsPath)
        if (!IsObject(settings))
            settings := {}
        savedFormations := settings.SavedFormations
        if (!IsObject(savedFormations))
        {
            savedFormations := {}
            settings["SavedFormations"] := savedFormations
            save := true
        }
        if (lastFormations == "")
            lastFormations := {}
        if (!save) ; Compare the last known formation to the current in-game formation, then current formation to saved formation
        {
            Loop, 4
            {
                if(A_Index == 4)
                    currentFormation := g_SF.Memory.GetActiveModronFormation()
                else
                    currentFormation := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(A_Index), true) ; without empty slots
                lastFormation := lastFormations[formationsFromIndex[A_Index]]
                if (!IC_BrivGemFarm_LevelUp_Functions.AreObjectsEqual(currentFormation, lastFormation))
                {
                    lastFormations[formationsFromIndex[A_Index]] := currentFormation
                    if (!lastFormationsNotSaved)
                    {
                        save := true
                        break
                    }
                }
                savedFormation := savedFormations[formationsFromIndex[A_Index]]
                if (!IC_BrivGemFarm_LevelUp_Functions.AreObjectsEqual(currentFormation, savedFormation))
                {
                    save := true
                    break
                }
            }
            lastFormationsNotSaved := false
        }
        if (save)
        {
            savedFormations.Q := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(1), true)
            savedFormations.W := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(2), true)
            savedFormations.E := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetSavedFormationSlotByFavorite(3), true)
            savedFormations.M := g_SF.Memory.GetFormationSaveBySlot(g_SF.Memory.GetActiveModronFormationSaveSlot(), true)
            settings["SavedFormations"] := savedFormations
            g_SF.WriteObjectToJSON(IC_BrivGemFarm_LevelUp_Functions.SettingsPath, settings)
        }
    }
}

class IC_BrivGemFarm_LevelUp_IC_MemoryFunctions_Added_Class ; Added to IC_MemoryFunctions_Class
{
    BGFLU_ReadClickLevelUpAllowed()
    {
        value := this.GameManager.game.gameInstances[this.GameInstance].Screen.uiController.bottomBar.heroPanel.clickDamageBox.maxLevelUpAllowed.Read()
        return value == "" ? 1 : value
    }
}