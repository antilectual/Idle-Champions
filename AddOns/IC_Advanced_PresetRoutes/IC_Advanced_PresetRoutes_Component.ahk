global g_Advanced_PresetRoutes := new IC_Advanced_PresetRoutes_Component

if(!IsObject(IC_BrivGemFarm_AdvancedSettings_Component))
{
	MsgBox, 48, Missing Dependency, The AdvancedSettings Preset Routes addon requires the IC Core (v0.1.1) and BrivGF Advanced (v0.2.5) addons to function. You are either missing one or both of those - or they are not sufficiently updated.
	return
}

g_Advanced_PresetRoutes.Init()

Class IC_Advanced_PresetRoutes_Component
{
	OptKeysOrdered := ["Cursed Farmer","0-1j Mixed LL","100% 1j LL","1-2j Mixed LL","100% 2j LL","2-3j Mixed LL","100% 3j LL","3-4j Mixed TT","100% 4j TT","100% 6j TT","100% 7j TT","100% 8j TT","8-9j Mixed TT","100% 9j TT","100% 11j TT","100% 14j TT"]
	Opts := {"Cursed Farmer":1125899906842623,"0-1j Mixed LL":1125899906842623,"100% 1j LL":1125899906842623,"1-2j Mixed LL":914793668012031,"100% 2j LL":1053332137310143,"2-3j Mixed LL":1020346787427327,"100% 3j LL":1090715500149758,"3-4j Mixed TT":508470925670862,"100% 4j TT":544309226487279,"100% 6j TT":1086144474247034,"100% 7j TT":1108238796846077,"100% 8j TT":985128007367679,"8-9j Mixed TT":16989228054990,"100% 9j TT":17020252302587,"100% 11j TT":853162999544159,"100% 14j TT":36326465504417}

	; ================================
	; ===== LOADING AND SETTINGS =====
	; ================================
	
	Init()
	{
		Global
		this.AddComponentsToAdvanced()
		Gui, Submit, NoHide
	}

	; ==========================
	; ===== MAIN FUNCTIONS =====
	; ==========================
	
	AddComponentsToAdvanced()
	{
		Global
		Gui, ICScriptHub:Tab, BrivGF Advanced
		
		GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmAdvancedSaveButton
		posY -= 20
		Gui, ICScriptHub:Font, w700
		Gui, ICScriptHub:Add, Text, x%posX% y%posY% w200, Route Presets
		Gui, ICScriptHub:Font, w400
		
		posY += 20
		Gui, ICScriptHub:Add, DropDownList, x%posX% y%posY% w175 vAdvanced_PresetRoutes
		choices := ""
		for k,v in this.OptKeysOrdered
			choices .= v . "|"
		GuiControl, ICScriptHub:, Advanced_PresetRoutes, % choices
		newWidth := this.DropDownSize(choices,,, 8)
		GuiControlGet, hnwd, ICScriptHub:Hwnd, Advanced_PresetRoutes
		SendMessage, 0x0160, newWidth, 0,, ahk_id %hnwd% ; CB_SETDROPPEDWIDTH
		
		posY -= 1
		Gui, ICScriptHub:Add, Button, x+2 y%posY% vAPR_Set gAPR_SetAndSave, Set Route and Save
		
		Gui, ICScriptHub:Add, Text, x%posX% y+2 w400, Note: Does not include Feat Swap routes. Use Feat Swap addon for those.
		
		GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmAdvancedStatusText
		GuiControl, ICScriptHub:Move, BrivGemFarmAdvancedStatusText, y%posY%
		GuiControlGet, pos, ICScriptHub:Pos, BrivGemFarmAdvancedSaveButton
		GuiControl, ICScriptHub:Move, BrivGemFarmAdvancedSaveButton, y%posY%
		Gui, ICScriptHub:Submit, NoHide
	}
	
	LoadMod50(value)
	{
		Loop, 50
			GuiControl, ICScriptHub:, PreferredBrivJumpSettingMod_50_%A_Index%, % (value & (2 ** (A_Index - 1))) != 0
		Gui, ICScriptHub:Submit, NoHide
	}
	
}

APR_SetAndSave()
{
	global
	GuiControlGet, apr_presetChoice, ICScriptHub:, Advanced_PresetRoutes
	bitfield := 0
	if (g_Advanced_PresetRoutes.Opts.HasKey(apr_presetChoice))
		bitfield := g_Advanced_PresetRoutes.Opts[apr_presetChoice]
	if (bitfield > 0)
	{
		g_Advanced_PresetRoutes.LoadMod50(bitfield)
		BrivGemFarmAdvancedUpdateStatusAndClick()
	}
}