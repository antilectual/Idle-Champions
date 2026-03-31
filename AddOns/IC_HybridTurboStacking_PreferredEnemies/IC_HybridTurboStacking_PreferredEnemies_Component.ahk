global g_HybridTurboStacking_PreferredEnemies := new IC_HybridTurboStacking_PreferredEnemies_Component

if(!IsObject(IC_BrivGemFarm_HybridTurboStacking_Component))
{
	MsgBox, 48, Missing Dependency, The Hybrid Turbo Stacking Preferred Enemies addon requires the IC Core (v0.1.1) and BrivGemFarm HybridTurboStacking (v1.1.5) addons to function. You are either missing one or both of those - or they are not sufficiently updated.
	return
}

g_HybridTurboStacking_PreferredEnemies.Init()

Class IC_HybridTurboStacking_PreferredEnemies_Component
{

	; ================================
	; ===== LOADING AND SETTINGS =====
	; ================================
	
	Init()
	{
		Global
		this.AddComponentsToHybridTurboStacking()
		Gui, Submit, NoHide
	}

	; ==========================
	; ===== MAIN FUNCTIONS =====
	; ==========================
	
	AddComponentsToHybridTurboStacking()
	{
		Global
		Gui, ICScriptHub:Tab, BrivGF HybridTurboStacking
		
		GuiControlGet, pos, ICScriptHub:Pos, BGFHTS_MelfGroup
		posH += 80
		GuiControl, ICScriptHub:Move, BGFHTS_MelfGroup, h%posH%
		
		GuiControlGet, pos, ICScriptHub:Pos, BGFHTS_BrivStack_Mod_50_41
		
		posY += 25
		Gui, ICScriptHub:Font, w700
		Gui, ICScriptHub:Add, Text, x%posX% y%posY% w400, Quick Select Preferred Enemy Types:
		Gui, ICScriptHub:Font, w400
		
		posY += 20
		Gui, ICScriptHub:Add, CheckBox, x%posX% y%posY% vHTSPE_AvoidBossIssues, Avoid issues with routes that land on z5 bosses?
		posY += 25
		Gui, ICScriptHub:Add, DropDownList, x%posX% y%posY% AltSubmit w175 vHTSPE_PreferredEnemies
		choices := "All||TT: Ranged-only|TT: Mixed-only|TT: Melee-only|TT: Ranged+Mixed|TT: Mixed+Melee|TT: 14/9j z21+ Ranged+Mixed"
		GuiControl, ICScriptHub:, HTSPE_PreferredEnemies, % "|" . choices
		newWidth := this.DropDownSize(choices,,, 8)
		GuiControlGet, hnwd, ICScriptHub:Hwnd, HTSPE_PreferredEnemies
		SendMessage, 0x0160, newWidth, 0,, ahk_id %hnwd% ; CB_SETDROPPEDWIDTH
		
		posY -= 2
		Gui, ICScriptHub:Add, Button, x+10 y%posY% vHTSPE_Set gHTSPE_SetAndSave, Set Preferred Enemies and Save
	}
	
}

HTSPE_SetAndSave()
{
	GuiControlGet, htspe_bossIssues, ICScriptHub:, HTSPE_AvoidBossIssues
	GuiControlGet, htspe_prefChoice, ICScriptHub:, HTSPE_PreferredEnemies
	bitfield := 0
	switch htspe_prefChoice
	{
		case 1: bitfield := htspe_bossIssues ? 544785982521359 : 544785982537199
		case 2: bitfield := 101711872
		case 3: bitfield := htspe_bossIssues ? 387142985482252 : 387142985497612
		case 4: bitfield := htspe_bossIssues ? 157642895327235 : 157642895327715
		case 5: bitfield := htspe_bossIssues ? 387143087194124 : 387143087209484
		case 6: bitfield := htspe_bossIssues ? 544785880809487 : 544785880825327
		case 7: bitfield := 387143087161344
	}
	if (bitfield > 0)
	{
		IC_BrivGemFarm_HybridTurboStacking_GUI.LoadMod50(bitfield)
		BGFHTS_Save()
	}
}