GUIFunctions.AddTab("Claim Daily Platinum")

Gui, ICScriptHub:Tab, Claim Daily Platinum
GUIFunctions.UseThemeTextColor("DefaultTextColor", 700)
Gui, ICScriptHub:Add, GroupBox, Section x125 y+0 w390 h39, Status
Gui, ICScriptHub:Font, w400
GUIFunctions.UseThemeTextColor("HeaderTextColor")
Gui, ICScriptHub:Add, Text, xs12 ys16 w366 vCDP_StatusText, % IC_ClaimDailyPlatinum_GUI.WaitingMessage
GUIFunctions.UseThemeTextColor("DefaultTextColor")

CDP_SaveSettings()
{
	global
	g_ClaimDailyPlatinum.SaveSettings()
}

class IC_ClaimDailyPlatinum_GUI
{
	static WaitingMessage := "Waiting for BrivGemFarm to Start."

	Init()
	{
		global
		this.BuildGUI()
	}

	BuildGUI()
	{
		global
		Gui, ICScriptHub:Add, Button, xs-106 ys10 w100 h25 vCDP_SaveSettings gCDP_SaveSettings, `Save Settings
		
		GuiControlGet, pos, ICScriptHub:Pos, CDP_StatusText
		CDP_infoGap := 5
		CDP_infoDist := 15
		CDP_lineHeight := posH
		CDP_firstLineY := 20
		CDP_gbCol1 := 15
		CDP_gbCol2 := 268
		CDP_gbWidth := 247
		CDP_gbHeight1 := 63
		CDP_gbHeight2 := CDP_gbHeight1 + CDP_lineHeight + CDP_infoGap
		CDP_cbDist := 25
		CDP_col1x := 15
		CDP_col1w := 120
		CDP_col2x := CDP_col1x + CDP_col1w + CDP_infoGap
		CDP_col2w := 100
		
		; Claim Daily Platinum - is tall due to daily boost line.
		Gui, ICScriptHub:Font, w700
		Gui, ICScriptHub:Add, GroupBox, Section vCDP_BoxRow1 x%CDP_gbCol1% ys39 w%CDP_gbWidth% h%CDP_gbHeight2%,
		Gui, ICScriptHub:Add, Checkbox, vCDP_ClaimPlatinum xs8 ys2, Claim Daily Platinum
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, xs15 ys%CDP_firstLineY% w%CDP_col1w% +Right, Platinum Days Claimed:
		Gui, ICScriptHub:Add, Text, vCDP_PlatinumDaysCount xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, Time Until Next Check:
		Gui, ICScriptHub:Add, Text, vCDP_PlatinumTimer xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, vCDP_DailyBoostHeader xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, 
		Gui, ICScriptHub:Add, Text, vCDP_DailyBoostExpires xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		
		; Claim Trials Rewards - is tall due to trials status.
		GuiControlGet, pos, ICScriptHub:Pos, CDP_BoxRow1
		Gui, ICScriptHub:Font, w700
		Gui, ICScriptHub:Add, GroupBox, Section x%CDP_gbCol2% y%posY% w%CDP_gbWidth% h%CDP_gbHeight2%,
		Gui, ICScriptHub:Add, Checkbox, vCDP_ClaimTrials xs8 ys2, Claim Trials Rewards
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, xs15 ys%CDP_firstLineY% w%CDP_col1w% +Right, Rewards Claimed:
		Gui, ICScriptHub:Add, Text, vCDP_TrialsRewardsCount xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, Time Until Next Check:
		Gui, ICScriptHub:Add, Text, vCDP_TrialsTimer xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, vCDP_TrialsStatusHeader xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, 
		Gui, ICScriptHub:Add, Text, vCDP_TrialsStatus xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		
		; Claim Free Weekly Shop Offers - is tall due to free rerolls status.
		Gui, ICScriptHub:Font, w700
		Gui, ICScriptHub:Add, GroupBox, Section vCDP_BoxRow2 x%CDP_gbCol1% ys+%CDP_gbHeight2% w%CDP_gbWidth% h%CDP_gbHeight2%,
		Gui, ICScriptHub:Add, Checkbox, vCDP_ClaimFreeOffer xs8 ys2, Claim Free Weekly Shop Offers
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, xs15 ys%CDP_firstLineY% w%CDP_col1w% +Right, Weekly Offers Claimed:
		Gui, ICScriptHub:Add, Text, vCDP_FreeOffersCount xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, Time Until Next Check:
		Gui, ICScriptHub:Add, Text, vCDP_FreeOfferTimer xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, vCDP_FreeOfferRerollsHeader xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, 
		Gui, ICScriptHub:Add, Text, vCDP_FreeOfferRerolls xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		
		; Claim Guide Quest Rewards - is tall because Free Weekly Shop Offers is tall.
		GuiControlGet, pos, ICScriptHub:Pos, CDP_BoxRow2
		Gui, ICScriptHub:Font, w700
		Gui, ICScriptHub:Add, GroupBox, Section x%CDP_gbCol2% y%posY% w%CDP_gbWidth% h%CDP_gbHeight2%,
		Gui, ICScriptHub:Add, Checkbox, vCDP_ClaimGuideQuests xs8 ys2, Claim Guide Quest Rewards
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, xs15 ys%CDP_firstLineY% w%CDP_col1w% +Right, Rewards Claimed:
		Gui, ICScriptHub:Add, Text, vCDP_GuideQuestsCount xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, Time Until Next Check:
		Gui, ICScriptHub:Add, Text, vCDP_GuideQuestsTimer xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, vCDP_GuideQuestsUnclaimedHeader xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, 
		Gui, ICScriptHub:Add, Text, vCDP_GuideQuestsUnclaimed xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		
		; Claim Free Premium Pack Bonus Chests - short.
		Gui, ICScriptHub:Font, w700
		Gui, ICScriptHub:Add, GroupBox, Section vCDP_BoxRow3 x%CDP_gbCol1% ys+%CDP_gbHeight2% w%CDP_gbWidth% h%CDP_gbHeight1%,
		Gui, ICScriptHub:Add, Checkbox, vCDP_ClaimBonusChests xs8 ys2, Claim Free Premium Bonus Chests
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, xs15 ys%CDP_firstLineY% w%CDP_col1w% +Right, Bonus Chests Claimed:
		Gui, ICScriptHub:Add, Text, vCDP_BonusChestsCount xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, Time Until Next Check:
		Gui, ICScriptHub:Add, Text, vCDP_BonusChestsTimer xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		
		; Claim Celebration Rewards - short.
		GuiControlGet, pos, ICScriptHub:Pos, CDP_BoxRow3
		Gui, ICScriptHub:Font, w700
		Gui, ICScriptHub:Add, GroupBox, Section x%CDP_gbCol2% y%posY% w%CDP_gbWidth% h%CDP_gbHeight1%,
		Gui, ICScriptHub:Add, Checkbox, vCDP_ClaimCelebrations xs8 ys2, Claim Celebration Rewards
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, xs15 ys%CDP_firstLineY% w%CDP_col1w% +Right, Rewards Claimed:
		Gui, ICScriptHub:Add, Text, vCDP_CelebrationRewardsCount xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
		Gui, ICScriptHub:Add, Text, xs15 y+%CDP_infoGap% w%CDP_col1w% +Right, Time Until Next Check:
		Gui, ICScriptHub:Add, Text, vCDP_CelebrationsTimer xs%CDP_col2x% y+-%CDP_lineHeight% w%CDP_col2w%, 
	}
	
}