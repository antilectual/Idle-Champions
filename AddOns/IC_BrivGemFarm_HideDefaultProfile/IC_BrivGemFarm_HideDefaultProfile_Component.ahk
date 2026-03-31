global g_BrivGemFarm_HideDefaultProfile := new IC_BrivGemFarm_HideDefaultProfile_Component

if(!IsObject(IC_BrivGemFarm_Component))
{
	MsgBox, 48, Missing Dependency, The HideDefaultProfile addon requires the IC Core (v0.1.1) and Briv Gem Farm (v1.4.7) addons to function. You are either missing one or both of those - or they are not sufficiently updated.
	return
}

g_BrivGemFarm_HideDefaultProfile.Init()

Class IC_BrivGemFarm_HideDefaultProfile_Component
{

	; ================================
	; ===== LOADING AND SETTINGS =====
	; ================================
	
	Init()
	{
		Global
		this.AddHideButtonToBrivGemFarm()
		this.HideDefaultProfile()
		Gui, Submit, NoHide
	}
	
	AddHideButtonToBrivGemFarm()
	{
		Global
		Gui, ICScriptHub:Tab, Briv Gem Farm
		GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmPlayButton
		posY += 95
		Gui, ICScriptHub:Add, Button, x15 y%posY% w160 vBGFHDP_HideButton, Hide Default Profile
		BGFHDP_HideDefaultProfile := ObjBindMethod(IC_BrivGemFarm_HideDefaultProfile_Component, "HideDefaultProfile")
		GuiControl,ICScriptHub: +g, BGFHDP_HideButton, % BGFHDP_HideDefaultProfile
	}
	
	HideDefaultProfile()
	{
		local bgf_hdp_selected
		local bgf_hdp_ddl := ""
		
		bgf_hdp_selected := BrivDropDownSettings
		ControlGet, bgf_hdp_ddl, List, , , ahk_id %BrivDropDownSettingsHWND%
		if (!InStr(bgf_hdp_ddl, "Default"))
			return
		bgf_hdp_newString := "|"
		Loop, Parse, bgf_hdp_ddl, `n
		{
			if (A_LoopField == "Default")
				continue
			bgf_hdp_newString .= A_LoopField "|"
			if (A_LoopField == bgf_hdp_selected)
				bgf_hdp_newString .= "|"
		}
		if (bgf_hdp_newString == "|")
			bgf_hdp_newString .= "Default||"
		GuiControl, ICScriptHub:, BrivDropDownSettings, %bgf_hdp_newString%
	}
	
}