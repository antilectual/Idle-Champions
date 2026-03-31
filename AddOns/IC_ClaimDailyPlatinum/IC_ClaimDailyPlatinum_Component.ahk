#include %A_LineFile%\..\IC_ClaimDailyPlatinum_Functions.ahk
#include %A_LineFile%\..\IC_ClaimDailyPlatinum_GUI.ahk
#include %A_LineFile%\..\IC_ClaimDailyPlatinum_Overrides.ahk


global g_ClaimDailyPlatinum := new IC_ClaimDailyPlatinum_Component

if(IsObject(IC_BrivGemFarm_Component))
{
	IC_ClaimDailyPlatinum_Functions.InjectAddon()
	global g_ClaimDailyPlatinum := new IC_ClaimDailyPlatinum_Component
	global g_ClaimDailyPlatinumGUI := new IC_ClaimDailyPlatinum_GUI
	g_ClaimDailyPlatinumGUI.Init()
	g_ClaimDailyPlatinum.Init()
}
else
{
	GuiControl, ICScriptHub:Text, CDP_StatusText, WARNING: This addon needs IC_BrivGemFarm enabled.
	return
}

Class IC_ClaimDailyPlatinum_Component
{
	TimerFunctions := {}
	DefaultSettings := {"Platinum":true,"Trials":true,"FreeOffer":true,"GuideQuests":true,"BonusChests":true,"Celebrations":true}
	Settings := {}
	; The timer for MainLoop:
	MainLoopCD := 60000 ; in milliseconds = 1 minute.
	; The starting cooldown for each type:
	StartingCD := 60000 ; in milliseconds = 1 minute.
	; The delay between when the server says a timer resets and when to check (for safety):
	SafetyDelay := 30000 ; in milliseconds = 30 seconds.
	; No Timer Delay (for when I can't find a timer in the data)
	; The current cooldown for each type:
	CurrentCD := {"Platinum":0,"Trials":0,"FreeOffer":0,"GuideQuests":0,"BonusChests":0,"Celebrations":0}
	; The amount of times each type has been claimed:
	Claimed := {"Platinum":0,"Trials":0,"FreeOffer":0,"GuideQuests":0,"BonusChests":0,"Celebrations":0}
	; The flags to tell the timers to pause if the script is waiting for the game to go offline.
	Claimable := {"Platinum":false,"Trials":false,"FreeOffer":false,"GuideQuests":false,"BonusChests":false,"Celebrations":false}
	; The names of each type
	Names := {"Platinum":"Daily Platinum","Trials":"Trials Rewards","FreeOffer":"Weekly Offers","GuideQuests":"Guide Quests","BonusChests":"Premium Bonus Chests","Celebrations":"Celebration Rewards"}
	DailyBoostExpires := -1
	TrialsPresetStatuses := [["Trials Status","Tiamat Dies in","Trial Joinable in"],["Unknown","Tiamat is Dead","Inactive","Sitting in Lobby",""]]
	TrialsStatus := [1,5]
	FreeWeeklyRerolls := -1
	UnclaimedGuideQuests := -1
	ClaimStatusText := ""
	StaggeredChecks := {"Platinum":1,"Trials":2,"FreeOffer":3,"GuideQuests":4,"BonusChests":5,"Celebrations":6}
	SharedData := ""
	LastServerCallsTime := 0
	; flags for which calls have been made
	CallsMade := {}
	CallsMade.Claimed := {}
	CallsMade.Claimable := {}
	CallsMade.TrialsStatus := False
	FreeOfferIDs := []
	ComsLock := False ; prevents mainloop from running multiple instances at the same time.
	UpdateGUIReady := False ; Flag to allow GUI update after server calls
	CallsRunning := False ; flag to indicate that calls are busy running
	
	SettingsFileLoc := A_LineFile . "\..\ServerCall_Settings.json"
	MemoryReadCheckInstanceIDs := {"Platinum":"","Trials":"","FreeOffer":"","GuideQuests":"","BonusChests":"","Celebrations":""}
	InstanceID := ""
	
	DisplayStatusTimeout := 0
	MessageStickyTimer := 8000
	
	; =======================================
	; ===== Initialisation and Settings =====
	; =======================================

	Init()
	{
		global g_globalTempSettingsFiles
		g_globalTempSettingsFiles.Push(this.SettingsFileLoc)
		this.LoadSettings()
		this.ResetComponentComs()
		g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(g_ClaimDailyPlatinum, "CreateTimedFunctions"))
		g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(g_ClaimDailyPlatinum, "StartTimedFunctions"))
		g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(g_ClaimDailyPlatinum, "StopTimedFunctions"))
	}
	
	LoadSettings()
	{
		Global
		Gui, Submit, NoHide
		writeSettings := false
		this.Settings := g_SF.LoadObjectFromJSON(IC_ClaimDailyPlatinum_Functions.SettingsPath)
		if(!IsObject(this.Settings))
		{
			this.SetDefaultSettings()
			writeSettings := true
		}
		if (this.CheckMissingOrExtraSettings())
			writeSettings := true
		if(writeSettings)
			g_SF.WriteObjectToJSON(IC_ClaimDailyPlatinum_Functions.SettingsPath, this.Settings)
		GuiControl, ICScriptHub:, CDP_ClaimPlatinum, % this.Settings["Platinum"]
		GuiControl, ICScriptHub:, CDP_ClaimTrials, % this.Settings["Trials"]
		GuiControl, ICScriptHub:, CDP_ClaimFreeOffer, % this.Settings["FreeOffer"]
		GuiControl, ICScriptHub:, CDP_ClaimGuideQuests, % this.Settings["GuideQuests"]
		GuiControl, ICScriptHub:, CDP_ClaimBonusChests, % this.Settings["BonusChests"]
		GuiControl, ICScriptHub:, CDP_ClaimCelebrations, % this.Settings["Celebrations"]
		for k,v in this.Settings
			if (!v)
				this.CurrentCD[k] := -1
		IC_ClaimDailyPlatinum_Functions.UpdateSharedSettings()
		this.UpdateGUI()
	}
	
	SaveSettings()
	{
		Global
		Gui, Submit, NoHide
		;local sanityChecked := this.SanityCheckSettings()
		this.CheckMissingOrExtraSettings()
		
		GuiControlGet,CDP_ClaimPlatinum, ICScriptHub:, CDP_ClaimPlatinum
		GuiControlGet,CDP_ClaimTrials, ICScriptHub:, CDP_ClaimTrials
		GuiControlGet,CDP_ClaimFreeOffer, ICScriptHub:, CDP_ClaimFreeOffer
		GuiControlGet,CDP_ClaimGuideQuests, ICScriptHub:, CDP_ClaimGuideQuests
		GuiControlGet,CDP_ClaimBonusChests, ICScriptHub:, CDP_ClaimBonusChests
		GuiControlGet,CDP_ClaimCelebrations, ICScriptHub:, CDP_ClaimCelebrations
		this.Settings["Platinum"] := CDP_ClaimPlatinum
		this.Settings["Trials"] := CDP_ClaimTrials
		this.Settings["FreeOffer"] := CDP_ClaimFreeOffer
		this.Settings["GuideQuests"] := CDP_ClaimGuideQuests
		this.Settings["BonusChests"] := CDP_ClaimBonusChests
		this.Settings["Celebrations"] := CDP_ClaimCelebrations
		
		g_SF.WriteObjectToJSON(IC_ClaimDailyPlatinum_Functions.SettingsPath, this.Settings)
		IC_ClaimDailyPlatinum_Functions.UpdateSharedSettings()
		CDP_LoopCounter := 1
		for k,v in this.Settings
		{
			if (v && this.CurrentCD[k] <= this.GetTickCount())
			{
				this.CurrentCD[k] := this.GetTickCount() + (this.MainLoopCD*CDP_LoopCounter)
				CDP_LoopCounter += 1
			}
			if (!v)
				this.CurrentCD[k] := -1
		}
		this.UpdateMainStatus("Saved settings.")
		this.UpdateGUI()
	}
	
	SetDefaultSettings()
	{
		this.Settings := {}
		for k,v in this.DefaultSettings
			this.Settings[k] := v
	}
	
	CheckMissingOrExtraSettings()
	{
		local madeEdit := false
		for k,v in this.DefaultSettings
		{
			if (this.Settings[k] == "") {
				this.Settings[k] := v
				madeEdit := true
			}
		}
		for k,v in this.Settings
		{
			if (!this.DefaultSettings.HasKey(k)) {
				this.Settings.Delete(k)
				madeEdit := true
			}
		}
		return madeEdit
	}
	
	; ======================
	; ===== MAIN STUFF =====
	; ======================
	
	; This loop gets called once per MainLoopCD.
	MainLoop()
	{
		if(this.CallsRunning)
			return
		if (!IC_ClaimDailyPlatinum_Functions.IsGameClosed())
		{
			runCalls := False
			instanceID := g_SF.Memory.ReadInstanceID()
			this.InstanceID := instanceID != "" ? instanceID : this.InstanceID ; Do not accidentally wipe instance id
			if(this.InstanceID == "") ; Don't make any calls if there is no InstanceID
				return
			if(this.ComsLock OR (this.GetTickCount() - this.LastServerCallsTime) <= this.MainLoopCD)
				return
			if(!IsObject(g_BrivFarmComsObj)) ; check for failed com activation only, not creation
				IC_BrivGemFarm_Component.StartComs()
			this.ComsLock := True
			for k,v in this.CurrentCD
			{
				if (!this.Settings[k])
					continue
				; Memory read stuff that doesn't care about claiming via calls.
				this.MemoryReadSimpleStuff(k)
				; If it's not claimable - check if it can be claimed via memory reads.
				; - Prevent re-checking memory reads if it's been claimed during the current instance.
				; - Because claiming via calls doesn't update the memory read.
				if (!this.Claimable[k] && this.MemoryReadCheckInstanceIDs[k] != this.InstanceID)
					this.CallMemoryReadCheckClaimable(k)
				if (this.CurrentCD[k] <= this.GetTickCount())
				{
					if(k == "Trials")
						this.CallsMade.TrialsStatus := True
					; If it's not claimable - check if it can be claimed.
					if (!this.Claimable[k])
					{
						this.UpdateMainStatus("Checking " . this.Names[k] . ".")
						; servercall check claimable
						this.CallCheckClaimable(k)
						this.CallsMade.Claimable[k] := True ; Tested against k existing, not if tested is True.
						runCalls := True
					}
					; If it is claimable - claim it.
					else
					{
						this.UpdateMainStatus("Claiming " . this.Names[k] . ".")
						this.Claim(k)
						this.CallsMade.Claimed[k] := True
						this.CallsMade.Claimable.delete(k)
						this.CurrentCD[k] := this.GetTickCount() + this.SafetyDelay
						this.Claimable[k] := false
					}

				}
			}
			this.ComsLock := False
			; test for claimable items
			for k,v in this.Claimable
				if (v == True)
					runCalls := True, Break
			if(runCalls)
				this.RunServerCalls()
		}
		this.UpdateGUI()
	}
	
	MemoryReadSimpleStuff(CDP_key)
	{
		if (CDP_key == "FreeOffer")
		{
			; Update Free Reroll count.
			rerollCost := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.ShopHandler.ALaCarteHandler_k__BackingField.RerollCost_k__BackingField.Read()
			rerollsRemaining := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.ShopHandler.ALaCarteHandler_k__BackingField.RerollsRemaining_k__BackingField.Read()
			this.FreeWeeklyRerolls := (rerollCost == 0 && rerollsRemaining > 0) ? rerollsRemaining : 0
		}
	}

	CallMemoryReadCheckClaimable(CDP_key)
	{
		CDP_CheckedClaimable := this.MemoryReadCheckClaimable(CDP_key) ; Check if it is claimable by memory reading.
		if (CDP_CheckedClaimable == "")
			return
		this.Claimable[CDP_key] := CDP_CheckedClaimable[1] ; Claimable
		this.CurrentCD[CDP_key] := CDP_CheckedClaimable[2] ; Claimable Cooldown
	}
	
	MemoryReadCheckClaimable(CDP_key)
	{
		if (CDP_key == "Platinum")
		{
			dayIndex := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.DailyLoginHandler.CurrentDay.Read()
			todayFreeClaimed := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.DailyLoginHandler.RewardsClaimed.Read()
			todayBoostClaimed := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.DailyLoginHandler.PremiumRewardsClaimed.Read()
			if (dayIndex != "" && todayFreeClaimed != "" && todayBoostClaimed != "")
			{
				CDP_num := 1 << dayIndex
				if ((todayFreeClaimed & CDP_num) == 0 || (this.DailyBoostExpires > 0 && (todayBoostClaimed & CDP_num) == 0))
					return [true, 0]
			}
		}
		else if (CDP_key == "Trials")
		{
			unclaimedCampID := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.TrialsHandler.pendingUnclaimedCampaignID.Read()
			if (unclaimedCampID > 0)
			{
				this.TrialsCampaignID := unclaimedCampID
				return [true, 0]
			}
		}
		else if (CDP_key == "GuideQuests")
		{
			numUnclaimedGuideQuests := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Screen.uiController.topBar.dpsMenuBox.menuBox.numberOfUnclaimedQuests.Read()
			this.UnclaimedGuideQuests := numUnclaimedGuideQuests
			if (numUnclaimedGuideQuests > 0)
				return [true, 0]
		}
		return ""
	}
	
	; =======================
	; ===== TIMER STUFF =====
	; =======================
	
	CreateTimedFunctions()
	{
		this.TimerFunctions := {}
		fncToCallOnTimer := ObjBindMethod(this, "MainLoop")
		this.TimerFunctions[fncToCallOnTimer] := this.MainLoopCD
		fncToCallOnTimer := ObjBindMethod(this, "UpdateMainStatus")
		this.TimerFunctions[fncToCallOnTimer] := 1000
	}

	StartTimedFunctions()
	{
		this.Running := true
		this.UpdateMainStatus("Started.")
		for k,v in this.TimerFunctions
			SetTimer, %k%, %v%, 0
		for k,v in this.CurrentCD
			this.CurrentCD[k] := this.GetTickCount() + (this.StartingCD * this.StaggeredChecks[k])
		this.UpdateGUI()
	}

	StopTimedFunctions()
	{
		this.Running := false
		this.UpdateMainStatus(IC_ClaimDailyPlatinum_GUI.WaitingMessage)
		for k,v in this.TimerFunctions
		{
			SetTimer, %k%, Off
			SetTimer, %k%, Delete
		}
		for k,v in this.CurrentCD
		{
			this.CurrentCD[k] := 0
			this.Claimable[k] := false
		}
		this.UpdateGUI(true)
	}
	
	ConvertCNESimpleTimerToSeconds(simpleTimer)
	{
		secondsExpire = 1970
		secondsExpire += (Floor(simpleTimer / 1000) - 62135596800),s
		secondsExpire -= A_NOW,s
		return secondsExpire
	}
	
	UpdateCooldownTimerIfSimpleTimerIsSooner(CDP_key, simpleTimer, addSafetyDelay := true)
	{
		simpleTime := this.ConvertCNESimpleTimerToSeconds(simpleTimer)
		if (simpleTimer > 0)
		{
			simpleTimer := this.GetTickCount() + (simpleTimer * 1000)
			if (addSafetyDelay)
				simpleTimer += this.SafetyDelay
			if (simpleTimer < this.CurrentCD[CDP_key])
				this.CurrentCD[CDP_key] := simpleTimer
		}
	}
	
	; =====================
	; ===== GUI STUFF =====
	; =====================
	
	UpdateMainStatus(status := "")
	{
		if(this.UpdateGUIReady)
		{
			this.UpdateGUI()
			this.CallsRunning := False
			this.UpdateGUIReady := False
		}
		if (status == "")
		{
			CDP_TimerIsUp := this.GetTickCount() - this.DisplayStatusTimeout >= this.MessageStickyTimer
			if (CDP_TimerIsUp)
				status := ""
			else
			{
				GuiControlGet,CDP_StatusText, ICScriptHub:, CDP_StatusText
				status := CDP_StatusText
			}
		}
		else
			this.DisplayStatusTimeout := this.GetTickCount()
		if (status == "")
			status := "Idle."
		GuiControl, ICScriptHub:Text, CDP_StatusText, % status
		Gui, Submit, NoHide
	}
	
	UpdateGUI(CDP_clearStatuses := false)
	{
		if (CDP_clearStatuses || !this.Settings["Platinum"])
			this.DailyBoostExpires := -1
		if (CDP_clearStatuses || !this.Settings["Trials"])
			this.TrialsStatus := [1,5]
		if (CDP_clearStatuses || !this.Settings["FreeOffer"])
			this.FreeWeeklyRerolls := -1
			
		if (this.TrialsStatus[1] == 3 && this.TrialsStatus[2] < this.GetTickCount())
			this.TrialsStatus := [1,3]
	
		GuiControl, ICScriptHub:, CDP_PlatinumTimer, % this.ProduceGUITimerMessage("Platinum")
		GuiControl, ICScriptHub:, CDP_TrialsTimer, % this.ProduceGUITimerMessage("Trials")
		GuiControl, ICScriptHub:, CDP_FreeOfferTimer, % this.ProduceGUITimerMessage("FreeOffer")
		GuiControl, ICScriptHub:, CDP_GuideQuestsTimer, % this.ProduceGUITimerMessage("GuideQuests")
		GuiControl, ICScriptHub:, CDP_BonusChestsTimer, % this.ProduceGUITimerMessage("BonusChests")
		GuiControl, ICScriptHub:, CDP_CelebrationsTimer, % this.ProduceGUITimerMessage("Celebrations")
		GuiControl, ICScriptHub:, CDP_PlatinumDaysCount, % this.ProduceGUIClaimedMessage("Platinum")
		GuiControl, ICScriptHub:, CDP_TrialsRewardsCount, % this.ProduceGUIClaimedMessage("Trials")
		GuiControl, ICScriptHub:, CDP_FreeOffersCount, % this.ProduceGUIClaimedMessage("FreeOffer")
		GuiControl, ICScriptHub:, CDP_GuideQuestsCount, % this.ProduceGUIClaimedMessage("GuideQuests")
		GuiControl, ICScriptHub:, CDP_BonusChestsCount, % this.ProduceGUIClaimedMessage("BonusChests")
		GuiControl, ICScriptHub:, CDP_CelebrationRewardsCount, % this.ProduceGUIClaimedMessage("Celebrations")
		
		GuiControl, ICScriptHub:, CDP_DailyBoostHeader, % "Daily Boost" . ((this.DailyBoostExpires > 0) ? " Expires" : "") . ":"
		GuiControl, ICScriptHub:, CDP_DailyBoostExpires, % (this.DailyBoostExpires > 0) ? this.FmtSecs(this.CeilMillisecondsToNearestMainLoopCDSeconds(this.DailyBoostExpires)) : (this.DailyBoostExpires == 0 ? "Inactive" : "")
		GuiControl, ICScriptHub:, CDP_TrialsStatusHeader, % (this.TrialsPresetStatuses[1][this.TrialsStatus[1]]) . ":"
		GuiControl, ICScriptHub:, CDP_TrialsStatus, % (this.TrialsStatus[1] == 1 ? this.TrialsPresetStatuses[2][this.TrialsStatus[2]] : (this.FmtSecs(this.CeilMillisecondsToNearestMainLoopCDSeconds(this.TrialsStatus[2])) . (this.TrialsStatus[1] == 2 ? " (est)" : "")))
		GuiControl, ICScriptHub:, CDP_FreeOfferRerollsHeader, % "Free Rerolls Remaining:"
		GuiControl, ICScriptHub:, CDP_FreeOfferRerolls, % (this.FreeWeeklyRerolls >= 0) ? this.FreeWeeklyRerolls : ""
		GuiControl, ICScriptHub:, CDP_GuideQuestsUnclaimedHeader, % "Unclaimed Guide Quests:"
		GuiControl, ICScriptHub:, CDP_GuideQuestsUnclaimed, % (this.UnclaimedGuideQuests >= 0 ? this.UnclaimedGuideQuests : "")
		Gui, Submit, NoHide
	}
	
	ProduceGUITimerMessage(CDP_key)
	{
		if (this.Running)
		{
			if (!this.Settings[CDP_key])
				return "Disabled."
			; Ceil the remaining milliseconds to the nearest MainLoopCD so it never shows 00m.
			; Then turn it into seconds to format.
			return this.FmtSecs(this.CeilMillisecondsToNearestMainLoopCDSeconds(this.CurrentCD[CDP_key]))
		}
		return ""
	}
	
	ProduceGUIClaimedMessage(CDP_key)
	{
		Critical, On
		value := ""
		if (this.Running)
			value := this.Claimed[CDP_key]
		Critical, Off
		return value
	}

	Claim(CDP_key)
	{
		jsonObj := this.GetSettingsJsonObj()
		if (!IsObject(jsonObj["Calls"]))
			jsonObj["Calls"] := []
		jsonObj["Calls"].Push({"Claim" : [CDP_key]})
		g_SF.WriteObjectToJSON(this.SettingsFileLoc, jsonObj)
		this.MemoryReadCheckInstanceIDs[CDP_key] := this.InstanceID
		this.ClaimStatusText .= "Claiming " . this.Names[CDP_key] . ".`n"
	}

	CallCheckClaimable(CDP_key)
	{
		jsonObj := this.GetSettingsJsonObj()
		if (!IsObject(jsonObj["Calls"]))
			jsonObj["Calls"] := []
		jsonObj["Calls"].Push({"CallCheckClaimable" : [CDP_key]})
		g_SF.WriteObjectToJSON(this.SettingsFileLoc , jsonObj)
	}

	GetSettingsJsonObj()
	{
		jsonObj := g_SF.LoadObjectFromJSON(this.SettingsFileLoc) ; pull local
		if (jsonObj == "" OR jsonObj == """""")
		{
			jsonObj := g_SF.LoadObjectFromJSON(A_LineFile . "\..\..\IC_BrivGemFarm_Performance\ServerCall_Settings.json") ; pull base
			jsonObj["Calls"] := "" ; clear calls from base if any
		}
		return jsonObj
	}
	
	RunServerCalls()
	{
		try
		{
			serverSettingsLoc := { "loc" : A_LineFile . "\..\..\IC_ClaimDailyPlatinum_Extra\ServerCall_Settings.json"}
			serverOverrideSettingsLoc := A_LineFile . "\..\..\IC_BrivGemFarm_Performance\ServerCallLocationOverride_Settings.json"
			g_SF.WriteObjectToJSON(serverOverrideSettingsLoc, serverSettingsLoc)
			this.UpdateSettingsInstanceID()
			scriptLocation := A_LineFile . "\..\..\IC_BrivGemFarm_Performance\IC_BrivGemFarm_ServerCalls.ahk"
			if(FileExist(serverOverrideSettingsLoc) AND FileExist(scriptLocation) AND FileExist(serverOverrideSettingsLoc))
				Run, %A_AhkPath% "%scriptLocation%"
			this.CallsRunning := True
			this.LastServerCallsTime := this.GetTickCount()
			this.UpdateMainStatus(this.ClaimStatusText)
		}
		catch errVal
		{
			this.LastServerCallsTime := this.GetTickCount() - MainLoopCD ; servercall run failed, allow retries
		}
	}

	UpdateSettingsInstanceID()
	{
		jsonObj := g_SF.LoadObjectFromJSON(this.SettingsFileLoc) ; pull local
		instanceID := g_SF.Memory.ReadInstanceID()
		if(jsonObj != "")
			jsonObj.InstanceID := this.InstanceID := instanceID != "" ? instanceID : this.InstanceID
		g_SF.WriteObjectToJSON(this.SettingsFileLoc , jsonObj)
	}
	
	; ======================
	; ===== MISC STUFF =====
	; ======================
	
	FmtSecs(s) {
		local form
		if (s < 3600)
			form := "mm'm"
		else if (s < 86400)
			form := "h'h 'mm'm"
		else
			form := "d'd 'hh'h 'mm'm"
		VarSetCapacity(t,256),DllCall("GetDurationFormat","uint",2048,"uint",0,"ptr",0,"int64",s*10000000,"wstr",form,"wstr",t,"int",256)
		return t
	}
	
	CeilMillisecondsToNearestMainLoopCDSeconds(CDP_timer)
	{
		if (CDP_timer <= this.GetTickCount())
			return 0
		return (Ceil((CDP_timer - this.GetTickCount()) / this.MainLoopCD) * this.MainLoopCD) / 1000
	}
	
	GetTickCount()
	{
		return IC_ClaimDailyPlatinum_Functions.GetTickCount()
	}
	
}


g_globalTempSettingsFiles.Push(A_LineFile . "\..\LastGUID_ClaimDailyPremium.json") ; to be removed on script hub exit.
SH_UpdateClass.AddClassFunctions(g_BrivFarmComsObj, IC_BrivGemFarmRun_ClaimDailyPlatinum_SharedData_Class)
IC_BrivGemFarm_Component.StartComs() ; restart coms with overridden startcoms function.