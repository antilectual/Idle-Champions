class IC_ClaimDailyPlatinum_SharedData_Added_Class ; Added to g_SharedData in BGF_Run
{
	CDP_UpdateSettingsFromFile(fileName := "")
	{
		if (fileName == "")
			fileName := IC_ClaimDailyPlatinum_Functions.SettingsPath
		settings := g_SF.LoadObjectFromJSON(fileName)
		if (!IsObject(settings))
			return false
		for k,v in settings
			g_BrivUserSettingsFromAddons[ "CDP_" k ] := v
	}
}

class IC_BrivGemFarmRun_ClaimDailyPlatinum_SharedData_Class ; Updates IC_BrivGemFarm_Coms which updates g_BrivFarmComsObj
{
	ResetCDPComponentComs()
	{ ; called from CDP servercalls
	
		static ResetComsLock := False
		if(ResetComsLock)
			return
		ResetComsLock := True
		try
		{
			ServerCallGuid := g_SF.LoadObjectFromJSON(A_LineFile . "\..\LastGUID_ClaimDailyPremium.json")
			try
			{
				g_ClaimDailyPlatinum.SharedData := ComObjActive(ServerCallGuid)
				g_ClaimDailyPlatinum.SharedData.Claimed := {}
				for k, v in g_ClaimDailyPlatinum.Claimed
					g_ClaimDailyPlatinum.SharedData.Claimed[k] := v
				g_ClaimDailyPlatinum.SharedData.TrialsCampaignID := g_ClaimDailyPlatinum.TrialsCampaignID
				g_ClaimDailyPlatinum.SharedData.FreeOfferIDs := {}
				g_ClaimDailyPlatinum.SharedData.BonusChestIDs := {}
				g_ClaimDailyPlatinum.SharedData.CelebrationCodes := {}
				g_SF.CopyToComObject(g_ClaimDailyPlatinum.SharedData.FreeOfferIDs, g_ClaimDailyPlatinum.FreeOfferIDs.Clone())
				g_SF.CopyToComObject(g_ClaimDailyPlatinum.SharedData.BonusChestIDs, g_ClaimDailyPlatinum.BonusChestIDs.Clone())
				g_SF.CopyToComObject(g_ClaimDailyPlatinum.SharedData.CelebrationCodes, g_ClaimDailyPlatinum.CelebrationCodes.Clone())
			}
		}
		finally
			ResetComsLock := False
	}

	UpdateCDPComponent()
	{
		Critical, On
		claimedValue := g_SF.ComObjectCopy(g_ClaimDailyPlatinum.SharedData.Claimed)
		if(claimedValue != "") ; should not be empty, should always be an object with items in it.
		{
			g_ClaimDailyPlatinum.Claimed := g_ClaimDailyPlatinum.SharedData.Claimed == "" ? g_ClaimDailyPlatinum.Claimed : this.FilterToCalled(g_ClaimDailyPlatinum.Claimed, g_SF.ComObjectCopy(g_ClaimDailyPlatinum.SharedData.Claimed), g_ClaimDailyPlatinum.CallsMade.Claimed)
			g_ClaimDailyPlatinum.Claimable := g_ClaimDailyPlatinum.SharedData.Claimable == "" ? g_ClaimDailyPlatinum.Claimable : this.FilterToCalled(g_ClaimDailyPlatinum.Claimable, g_SF.ComObjectCopy(g_ClaimDailyPlatinum.SharedData.Claimable), g_ClaimDailyPlatinum.CallsMade.Claimable, false)
			g_ClaimDailyPlatinum.CurrentCD := g_ClaimDailyPlatinum.SharedData.CurrentCD == "" ? g_ClaimDailyPlatinum.CurrentCD : this.FilterToCalled(g_ClaimDailyPlatinum.CurrentCD, g_SF.ComObjectCopy(g_ClaimDailyPlatinum.SharedData.CurrentCD), g_ClaimDailyPlatinum.CallsMade.Claimable)
			g_ClaimDailyPlatinum.TrialsCampaignID := g_ClaimDailyPlatinum.SharedData.TrialsCampaignID == "" ? g_ClaimDailyPlatinum.TrialsCampaignID : g_ClaimDailyPlatinum.SharedData.TrialsCampaignID
			g_ClaimDailyPlatinum.UnclaimedGuideQuests := g_ClaimDailyPlatinum.SharedData.UnclaimedGuideQuests == "" ? g_ClaimDailyPlatinum.UnclaimedGuideQuests : g_ClaimDailyPlatinum.SharedData.UnclaimedGuideQuests
			g_ClaimDailyPlatinum.DailyBoostExpires := g_ClaimDailyPlatinum.SharedData.DailyBoostExpires == "" ? g_ClaimDailyPlatinum.DailyBoostExpires : g_ClaimDailyPlatinum.SharedData.DailyBoostExpires
			g_ClaimDailyPlatinum.FreeWeeklyRerolls := g_ClaimDailyPlatinum.SharedData.FreeWeeklyRerolls == "" ? g_ClaimDailyPlatinum.FreeWeeklyRerolls : g_ClaimDailyPlatinum.SharedData.FreeWeeklyRerolls
			g_ClaimDailyPlatinum.TrialsStatus := !g_ClaimDailyPlatinum.CallsMade.TrialsStatus OR g_ClaimDailyPlatinum.SharedData.TrialsStatus == ""  ? g_ClaimDailyPlatinum.TrialsStatus : g_SF.ComObjectCopy(g_ClaimDailyPlatinum.SharedData.TrialsStatus)
			g_ClaimDailyPlatinum.FreeOfferIDs := g_ClaimDailyPlatinum.SharedData.FreeOfferIDs == "" ? g_ClaimDailyPlatinum.FreeOfferIDs : g_SF.ComObjectCopy(g_ClaimDailyPlatinum.SharedData.FreeOfferIDs)
			g_ClaimDailyPlatinum.BonusChestIDs := g_ClaimDailyPlatinum.SharedData.BonusChestIDs == ""  ? g_ClaimDailyPlatinum.BonusChestIDs : g_SF.ComObjectCopy(g_ClaimDailyPlatinum.SharedData.BonusChestIDs)
			g_ClaimDailyPlatinum.CelebrationCodes := g_ClaimDailyPlatinum.SharedData.CelebrationCodes == ""  ? g_ClaimDailyPlatinum.CelebrationCodes : g_SF.ComObjectCopy(g_ClaimDailyPlatinum.SharedData.CelebrationCodes)
			; updates made, reset flags
			g_ClaimDailyPlatinum.CallsMade.TrialsStatus := False
		}
		g_ClaimDailyPlatinum.HasComsUpdated := this.GetTickCount() - this.MainLoopCD
		g_ClaimDailyPlatinum.UpdateGUIReady := True
		Critical, Off
	}

	; Filters the response down to only call returns that were requested e.g. if e was requested {a:b, c:d, e:f} -> {e:f}
	FilterToCalled(byref objToUpdate, updatedValues, byref callsMade, remove := True)
	{
		keysGoByeBye := []
		for k,v in callsMade
		{
			objToUpdate[k] := updatedValues[k]
			if(remove)
				keysGoByeBye.Push(k)
		}
		for k,v in keysGoByeBye
			callsMade.delete(v)
		return objToUpdate
	}
	
	GetTickCount()
	{
		return IC_ClaimDailyPlatinum_Functions.GetTickCount()
	}
}