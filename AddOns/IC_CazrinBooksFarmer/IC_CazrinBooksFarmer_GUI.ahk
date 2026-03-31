GUIFunctions.AddTab("Cazrin Books Farmer")

Gui, ICScriptHub:Tab, Cazrin Books Farmer
GUIFunctions.UseThemeTextColor("DefaultTextColor", 700)
Gui, ICScriptHub:Add, GroupBox, Section x15 y+0 w500 h39, Status
Gui, ICScriptHub:Font, w400
GUIFunctions.UseThemeTextColor("HeaderTextColor")
Gui, ICScriptHub:Add, Text, xs12 ys16 w366 vCBF_StatusText, % IC_CazrinBooksFarmer_GUI.InitMessage
GUIFunctions.UseThemeTextColor("DefaultTextColor")

CBF_StartFarm()
{
	global
	g_CazrinBooksFarmer.StartFarming()
}

CBF_StopFarm()
{
	global
	g_CazrinBooksFarmer.StopFarming()
}

/*
CBF_TestButton()
{
	global
	CoordMode, Mouse, Client
	specPotsData := IC_CazrinBooksFarmer_Functions.GetSpecialisationPotionData()
	SpecPotsIndex := specPotsData[1]
	SpecPotsName := specPotsData[2]
	SpecPotsAmount := specPotsData[3]
	IC_CazrinBooksFarmer_Functions.SwapSpecialisation(SpecPotsIndex)
	;IC_CazrinBooksFarmer_Functions.ChooseCazrin(99)
	; IC_CazrinBooksFarmer_Functions.ClickConfirmRespec("Dungeon Master")
	; IC_CazrinBooksFarmer_Functions.GetCurrentSpecialisation(99)
	;indexes := IC_CazrinBooksFarmer_Functions.FindHeroSpecialisationUpgradeIDs(166)
	;msgmsg := ""
	;for k,v in indexes
	;{
	;	msgmsg .= k . ": " . v . "`n"
	;}
	;MsgBox, % msgmsg
}

CBF_TestButton1()
{
	global
	CoordMode, Mouse, Client
    msglog := A_LineFile . "\..\logTheStuff.csv"
	size:=g_SF.Memory.DialogManager.dialogs.size.Read()
	msgmsg := "List size=[" . size . "]"
	loop %size%
	{
		dialogIndex:=A_Index-1
		name:=g_SF.Memory.DialogManager.dialogs[dialogIndex].sprite.gameObjectName.Read()
		active:=g_SF.Memory.DialogManager.dialogs[dialogIndex].Active.Read()
		msgmsg .= "`n" . dialogIndex . ": " . name . " (" . (active?"Active":"Inactive") . ")"
		x := g_SF.Memory.DialogManager.dialogs[dialogIndex]._x.Read()
		y := g_SF.Memory.DialogManager.dialogs[dialogIndex]._y.Read()
		if (name == "SpecializationDialog" && active)
		{
			heroName := g_SF.Memory.DialogManager.dialogs[dialogIndex].heroDef.name.Read()
			heroID := g_SF.Memory.DialogManager.dialogs[dialogIndex].heroDef.ID.Read()
			numOptions := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.numOptions.Read()
			panelX := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel._x.Read()
			panelY := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel._y.Read()
			specSelected := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.specializationSelected.Read()
			msgmsg .= "`n  " . Round(x,0) . "," . Round(y,0) . " / " . heroName . " (" . heroID . ") / " . numOptions . " / " . specSelected . " / " . Round(panelX,0) . "," . Round(panelY,0)
			loop %numOptions%
			{
				specID := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1].currentDef.ID.Read()
				specName := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1].currentDef.specializationName.Read()
				specX := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1]._x.Read()
				specY := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1]._y.Read()
				buttonX := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1].button._x.Read()
				buttonY := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1].button._y.Read()
				msgmsg .= "`n    " . specName . " (" . specID . ") / " . Round(specX,0) . "," . Round(specY,0) . " / " . Round(buttonX,0) . "," . Round(buttonY,0)
				actualX := x + panelX + specX + buttonX
				actualY := y + panelY + specY + buttonY
			}
		}
		else if (name == "InventoryDialogV2" && active)
		{
			selectorItemsSize := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems.size.Read()
			msgmsg .= "`n  SelectorItems: " . Round(x,0) . "," . Round(y,0) . " / " . selectorItemsSize
			loop %selectorItemsSize%
			{
				selectItemX := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1]._x.Read()
				selectItemY := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1]._y.Read()
				selectItemSelected := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1].isSelected.Read()
				selectItemText := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1].text.lastSetText.Read()
				msgmsg .= "`n    " . selectItemX . "," . selectItemY . " / " . selectItemSelected . " / " . selectItemText
				actualX := x + selectItemX
				actualY := y + selectItemY
			}
			itemCategory := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.itemCategory.Read()
			activePage := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.activePageIndex.Read()
			pages := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.pages.Read()
			maxCols := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.maxCols.Read()
			maxRows := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.maxRows.Read()
			msgmsg .= "`n  InventoryPanel: " . itemCategory . " / " . activePage . " / " . pages . " / " . maxCols . " / " . maxRows
			pageX := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector._x.Read()
			pageY := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector._y.Read()
			leftArrowX := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector.leftArrow._x.Read()
			leftArrowY := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector.leftArrow._y.Read()
			rightArrowX := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector.rightArrow._x.Read()
			rightArrowY := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector.rightArrow._y.Read()
			leftActualX := x + pageX + leftArrowX
			leftActualY := y + pageY + leftArrowY
			rightActualX := x + pageX + rightArrowX
			rightActualY := y + pageY + rightArrowY
			msgmsg .= "`n  PageSelector: " . leftActualX . "," . leftActualY . " / " . rightActualX . "," . rightActualY
		}
		else if (name == "HeroSelectorDialog" && active)
		{
			activeItems := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems.size.Read()
			panelX := g_SF.Memory.DialogManager.dialogs[dialogIndex].scrollBorder._x.Read()
			panelY := g_SF.Memory.DialogManager.dialogs[dialogIndex].scrollBorder._y.Read()
			msgmsg .= "`n  " . x . "," . y . " / " . activeItems . " / " . panelX . "," . panelY
			loop %activeItems%
			{
				heroID := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems[A_Index-1].hero.def.ID.Read()
				heroName := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems[A_Index-1].hero.def.name.Read()
				heroX := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems[A_Index-1]._x.Read()
				heroY := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems[A_Index-1]._y.Read()
				msgmsg .= "`n    " . heroID . " / " . heroName . " / " . heroX . "," . heroY
			}
		}
		else if (name == "PrettyMessageBox" && active)
		{
			okButtonX := g_SF.Memory.DialogManager.dialogs[dialogIndex].okButton._x.Read()
			okButtonY := g_SF.Memory.DialogManager.dialogs[dialogIndex].okButton._y.Read()
			actualX := x + okButtonX
			actualY := y + okButtonY
			msgBoxText := g_SF.Memory.DialogManager.dialogs[dialogIndex].text.lastSetText.Read()
			msgmsg .= "`n  " . Round(x,0) . "," . Round(y,0) . " / " . Round(okButtonX,0) . "," . Round(okButtonY,0) . " / " . Round(actualX,0) . "," . Round(actualY,0) . " / " . MsgBoxText
		}
	}
	file := FileOpen(msglog, "w")
	file.write(msgmsg)
	file.close()
}
*/

class IC_CazrinBooksFarmer_GUI
{
	static InitMessage := "Initialising..."
	static ReadyMessage := "Ready to start farming."

	Init()
	{
		global
		this.BuildGUI()
		this.CreateTooltips()
	}

	BuildGUI()
	{
		global
		GuiControlGet, pos, ICScriptHub:Pos, CBF_StatusText
		CBF_lineHeight := posH
		CBF_lineDiff := 4
		CDP_initLineDiff := 15
		CBF_col1w := 150
		CBF_col2w := 250
		CBF_col2x := 15 + CBF_col1w + 15

		Gui, ICScriptHub:Font, w700
		CBF_gboxhInfo := 108
		GUIFunctions.UseThemeTextColor("HeaderTextColor")
		Gui, ICScriptHub:Add, GroupBox, Section x15 ys+39 w500 h%CBF_gboxhInfo%,
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, vCBF_CurrBooksH xs15 ys+%CDP_initLineDiff% w%CBF_col1w% +Right, Current Books:
		Gui, ICScriptHub:Add, Text, vCBF_CurrBooks xs%CBF_col2x% y+-%CBF_lineHeight% w%CBF_col2w%, 
		Gui, ICScriptHub:Add, Text, vCBF_TotalBooksH xs15 y+%CBF_lineDiff% w%CBF_col1w% +Right, Total Lifetime Books:
		Gui, ICScriptHub:Add, Text, vCBF_TotalBooks xs%CBF_col2x% y+-%CBF_lineHeight% w%CBF_col2w%, 
		Gui, ICScriptHub:Add, Text, vCBF_BooksPerBossH xs15 y+%CBF_lineDiff% w%CBF_col1w% +Right, Books Per Drop:
		Gui, ICScriptHub:Add, Text, vCBF_BooksPerBoss xs%CBF_col2x% y+-%CBF_lineHeight% w%CBF_col2w%, 
		Gui, ICScriptHub:Add, Text, vCBF_CurrSpecH xs15 y+%CBF_lineDiff% w%CBF_col1w% +Right, Specialisation:
		Gui, ICScriptHub:Add, Text, vCBF_CurrSpec xs%CBF_col2x% y+-%CBF_lineHeight% w%CBF_col2w%, 
		Gui, ICScriptHub:Add, Text, vCBF_NumSpecPotsH xs15 y+%CBF_lineDiff% w%CBF_col1w% +Right, Specialisation Potions:
		Gui, ICScriptHub:Add, Text, vCBF_NumSpecPots xs%CBF_col2x% y+-%CBF_lineHeight% w%CBF_col2w%, 
		
		Gui, ICScriptHub:Font, w700
		CBF_gboxhButtons := 52
		GUIFunctions.UseThemeTextColor("HeaderTextColor")
		Gui, ICScriptHub:Add, GroupBox, Section x15 ys+%CBF_gboxhInfo% w500 h%CBF_gboxhButtons%,
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Button, xs15 ys17 w150 vCBF_StartFarm gCBF_StartFarm, `Start Farming
		Gui, ICScriptHub:Add, Button, x+10 ys17 w150 vCBF_StopFarm gCBF_StopFarm, `Stop Farming
		;Gui, ICScriptHub:Add, Button, x+10 ys17 w150 vCBF_TestButton gCBF_TestButton, `Test
		
		Gui, ICScriptHub:Font, w700
		CBF_gboxhHotkey := 40
		GUIFunctions.UseThemeTextColor("HeaderTextColor")
		Gui, ICScriptHub:Add, GroupBox, Section x15 ys+%CBF_gboxhButtons% w500 h%CBF_gboxhHotkey%,
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, xs15 ys+%CDP_initLineDiff% w450, Ctrl+Shift+F3 will stop the farming for if you run into issues.
	}
	
	CreateTooltips()
	{
		GUIFunctions.AddToolTip("CBF_CurrBooksH", "The number of books Cazrin has in this adventure`nas well as the maximum Cazrin can get this adventure.")
		GUIFunctions.AddToolTip("CBF_TotalBooksH", "The total number of books Cazrin has ever collected.")
		GUIFunctions.AddToolTip("CBF_BooksPerBossH", "The amount of books that will drop when a boss drops books.")
		GUIFunctions.AddToolTip("CBF_CurrSpecH", "Cazrin's current specialisation choice.")
		GUIFunctions.AddToolTip("CBF_NumSpecPotsH", "The number of Potion of Specialisation that you have remaining.")
	}
	
}