class IC_CazrinBooksFarmer_Functions
{
	static MaxRetries := 4
	
	TickFrequency := -1
	
	; ==================================
	; ===== CAZRIN BOOKS FUNCTIONS =====
	; ==================================
	
	CalculateMaxBooks(currSpecID)
	{
		maxZone := g_SF.Memory.ReadHighestZone()
		booksDivisor := ActiveEffectKeySharedFunctions.Cazrin.CazrinLibraryOfLoreHandler.ReadMaxBookDivisor()
		if (booksDivisor == "" || booksDivisor == 0)
			return 0
		booksMult := 3
		if (currSpecID != IC_CazrinBooksFarmer_Component.LostInTheLibraryID)
			booksMult := 1
		return Floor(maxZone / booksDivisor) * booksMult
	}
	
	; ==========================================
	; ===== SWAP SPECIALISATIONS FUNCTIONS =====
	; ==========================================

	SwapSpecialisation(SpecPotsIndex, CazrinHeroID := 166, SpecID1 := 17680, SpecID2 := 17682)
	{
		if !(SpecPotsIndex is number)
			return False
		; Step 1: Open the inventory.
		IC_CazrinBooksFarmer_Component.UpdateMainStatus("Opening inventory.")
		openedInv := this.OpenInventory()
		if (!openedInv)
			return False
		; Step 2: Change to the Potion tab.
		IC_CazrinBooksFarmer_Component.UpdateMainStatus("Swapping to Potions tab.")
		clickedPotionsTab := this.SwapInventoryTab(IC_CazrinBooksFarmer_Component.InventoryPotionsCategoryIndex)
		if (!clickedPotionsTab)
			return False
		; Step 3: Click the Spec potion.
		IC_CazrinBooksFarmer_Component.UpdateMainStatus("Using specialisation potion.")
		specPotionUsed := this.UseSpecPotion(SpecPotsIndex)
		if (!specPotionUsed)
			return False
		; Step 4: Choose Cazrin from the HeroSelectorDialog.
		IC_CazrinBooksFarmer_Component.UpdateMainStatus("Choosing Cazrin.")
		cazrinChosen := this.ChooseCazrin(CazrinHeroID)
		if (!cazrinChosen)
			return False
		; Step 5: Choose the specialisation.
		IC_CazrinBooksFarmer_Component.UpdateMainStatus("Choosing Lost in the Library specialisation.")
		clickChooseSpec := this.ChooseSpecialisation(CazrinHeroID, SpecID1)
		if (!clickChooseSpec)
			return False
		; Step 6: Choose the second specialisation.
		IC_CazrinBooksFarmer_Component.UpdateMainStatus("Choosing Smell Mastery specialisation.")
		clickChooseSpec := this.ChooseSpecialisation(CazrinHeroID, SpecID2)
		if (!clickChooseSpec)
			return False
		; Step 7: Kill all remaining dialogs.
		IC_CazrinBooksFarmer_Component.UpdateMainStatus("Closing all remaining dialogs.")
		this.CloseAnyActiveDialogs()
		return True
	}

	OpenInventory()
	{
		global
		attempts := 0
		loop
		{
			g_SF.DirectedInput(,, "{i}" )
			Sleep, 50
			inventoryActive := this.ConfirmDialogActive("InventoryDialogV2")
			if (inventoryActive)
				return True
			attempts += 1
		}
		until attempts >= this.MaxRetries
		return False
	}
	
	SwapInventoryTab()
	{
		size := g_SF.Memory.DialogManager.dialogs.size.Read()
		loop %size%
		{
			dialogIndex := A_Index-1
			name := g_SF.Memory.DialogManager.dialogs[dialogIndex].sprite.gameObjectName.Read()
			active := g_SF.Memory.DialogManager.dialogs[dialogIndex].Active.Read()
			if (name != "InventoryDialogV2" || !active)
				continue
			this.WaitDialogNotTransitioning(dialogIndex)
			x := g_SF.Memory.DialogManager.dialogs[dialogIndex]._x.Read()
			y := g_SF.Memory.DialogManager.dialogs[dialogIndex]._y.Read()
			selectorItemsSize := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems.size.Read()
			if (selectorItemsSize == "" || selectorItemsSize < 0 || selectorItemsSize > 20)
				continue
			loop %selectorItemsSize%
			{
				selectItemText := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1].text.lastSetText.Read()
				if (selectItemText != "Potions")
					continue
				selectItemSelected := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1].isSelected.Read()
				if (selectItemSelected)
					return True
				selectItemX := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1]._x.Read()
				selectItemY := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1]._y.Read()
				actualX := x + selectItemX + 5
				actualY := y + selectItemY + 5
				attempts := 0
				loop
				{
					this.ClickTheMouse(actualX, actualY)
					Sleep, 50
					selectItemSelected := g_SF.Memory.DialogManager.dialogs[dialogIndex].selectorItems[A_Index-1].isSelected.Read()
					if (selectItemSelected)
						return True
					attempts += 1
				}
				until attempts >= this.MaxRetries
			}
		}
		return False
	}
	
	UseSpecPotion(SpecPotsIndex)
	{
		size := g_SF.Memory.DialogManager.dialogs.size.Read()
		loop %size%
		{
			dialogIndex := A_Index-1
			name := g_SF.Memory.DialogManager.dialogs[dialogIndex].sprite.gameObjectName.Read()
			active := g_SF.Memory.DialogManager.dialogs[dialogIndex].Active.Read()
			if (name != "InventoryDialogV2" || !active)
				continue
			this.WaitDialogNotTransitioning(dialogIndex)
			x := g_SF.Memory.DialogManager.dialogs[dialogIndex]._x.Read()
			y := g_SF.Memory.DialogManager.dialogs[dialogIndex]._y.Read()
			itemCategory := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.itemCategory.Read()
			activePage := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.activePageIndex.Read()
			pages := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.pages.Read()
			maxCols := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.maxCols.Read()
			maxRows := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.maxRows.Read()
			potPage := Floor(SpecPotsIndex/(maxCols*maxRows))
			if (potPage != activePage)
			{
				directionOfTravel := potPage - activePage
				pageX := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector._x.Read()
				pageY := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector._y.Read()
				arrowX := 0
				arrowY := 0
				if (directionOfTravel > 0)
				{
					; Press right ->
					arrowX := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector.rightArrow._x.Read()
					arrowY := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector.rightArrow._y.Read()
				}
				else
				{
					; Press left <-
					arrowX := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector.leftArrow._x.Read()
					arrowY := g_SF.Memory.DialogManager.dialogs[dialogIndex].pageSelector.leftArrow._y.Read()
				}
				actualX := x + pageX + arrowX
				actualY := y + pageY + arrowY
				attempts := 0
				loop
				{
					this.ClickTheMouse(actualX, actualY)
					Sleep, 50
					activePage := g_SF.Memory.DialogManager.dialogs[dialogIndex].inventoryPanel.activePageIndex.Read()
					if (activePage == potPage)
						break
					attempts += 1
					if (attempts >= this.MaxRetries)
						return False
				}
			}
			potOffsetX := Mod(SpecPotsIndex,maxCols) * 80
			potOffsetY := Mod(Floor(SpecPotsIndex/maxCols),maxRows) * 80
			actualX := x + 254 + potOffsetX
			actualY := y +  93 + potOffsetY
			attempts := 0
			loop
			{
				this.ClickTheMouse(actualX, actualY)
				Sleep, 50
				if (this.ConfirmDialogActive("HeroSelectorDialog"))
					return True
				attempts += 1
			}
			until attempts >= this.MaxRetries
		}
		return False
	}
	
	ChooseCazrin(heroID)
	{
		size := g_SF.Memory.DialogManager.dialogs.size.Read()
		loop %size%
		{
			dialogIndex := A_Index-1
			name := g_SF.Memory.DialogManager.dialogs[dialogIndex].sprite.gameObjectName.Read()
			active := g_SF.Memory.DialogManager.dialogs[dialogIndex].Active.Read()
			if (name != "HeroSelectorDialog" || !active)
				continue
			activeItemsSize := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems.size.Read()
			if (activeItemsSize == "" || activeItemsSize < 0 || activeItemsSize > 200)
				continue
			this.WaitDialogNotTransitioning(dialogIndex)
			x := g_SF.Memory.DialogManager.dialogs[dialogIndex]._x.Read()
			y := g_SF.Memory.DialogManager.dialogs[dialogIndex]._y.Read()
			panelX := g_SF.Memory.DialogManager.dialogs[dialogIndex].scrollBorder._x.Read()
			panelY := g_SF.Memory.DialogManager.dialogs[dialogIndex].scrollBorder._y.Read()
			loop %activeItemsSize%
			{
				currHeroID := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems[A_Index-1].hero.def.ID.Read()
				if (heroID != currHeroID)
					continue
				heroName := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems[A_Index-1].hero.def.name.Read()
				heroX := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems[A_Index-1]._x.Read()
				heroY := g_SF.Memory.DialogManager.dialogs[dialogIndex].activeItems[A_Index-1]._y.Read()
				actualX := x + panelX + heroX + 26
				actualY := y + panelY + heroY + 26
				attempts := 0
				loop
				{
					this.ClickTheMouse(actualX, actualY)
					Sleep, 50
					if (this.ConfirmDialogActive("PrettyMessageBox"))
						return this.ClickConfirmRespec(heroName)
					attempts += 1
				}
				until attempts >= this.MaxRetries
				
			}
		}
		return False
	}
	
	ClickConfirmRespec(heroName)
	{
		expectedText := "Are you sure you want to reset Specialization choices for " . heroName . "?"
		size := g_SF.Memory.DialogManager.dialogs.size.Read()
		loop %size%
		{
			dialogIndex := A_Index-1
			name := g_SF.Memory.DialogManager.dialogs[dialogIndex].sprite.gameObjectName.Read()
			active := g_SF.Memory.DialogManager.dialogs[dialogIndex].Active.Read()
			if (name != "PrettyMessageBox" || !active)
				continue
			msgBoxText := g_SF.Memory.DialogManager.dialogs[dialogIndex].text.lastSetText.Read()
			if (msgBoxText != expectedText)
				continue
			this.WaitDialogNotTransitioning(dialogIndex)
			x := g_SF.Memory.DialogManager.dialogs[dialogIndex]._x.Read()
			y := g_SF.Memory.DialogManager.dialogs[dialogIndex]._y.Read()
			okButtonX := g_SF.Memory.DialogManager.dialogs[dialogIndex].okButton._x.Read()
			okButtonY := g_SF.Memory.DialogManager.dialogs[dialogIndex].okButton._y.Read()
			actualX := x + okButtonX + 5
			actualY := y + okButtonY + 5
			attempts := 0
			loop
			{
				this.ClickTheMouse(actualX, actualY)
				Sleep, 50
				if (this.ConfirmDialogActive("SpecializationDialog"))
					return True
				attempts += 1
			}
			until attempts >= this.MaxRetries
		}
		return False
	}
	
	ChooseSpecialisation(cazrinHeroID, specToChoose)
	{
		size := g_SF.Memory.DialogManager.dialogs.size.Read()
		loop %size%
		{
			dialogIndex := A_Index-1
			name := g_SF.Memory.DialogManager.dialogs[dialogIndex].sprite.gameObjectName.Read()
			active := g_SF.Memory.DialogManager.dialogs[dialogIndex].Active.Read()
			if (name != "SpecializationDialog" || !active)
				continue
			heroID := g_SF.Memory.DialogManager.dialogs[dialogIndex].heroDef.ID.Read()
			if (heroID != cazrinHeroID)
				continue
			this.WaitDialogNotTransitioning(dialogIndex)
			x := g_SF.Memory.DialogManager.dialogs[dialogIndex]._x.Read()
			y := g_SF.Memory.DialogManager.dialogs[dialogIndex]._y.Read()
			numOptions := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.numOptions.Read()
			panelX := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel._x.Read()
			panelY := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel._y.Read()
			loop %numOptions%
			{
				specID := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1].currentDef.ID.Read()
				if (specID != specToChoose)
					continue
				specX := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1]._x.Read()
				specY := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1]._y.Read()
				buttonX := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1].button._x.Read()
				buttonY := g_SF.Memory.DialogManager.dialogs[dialogIndex].panel.options[A_Index-1].button._y.Read()
				actualX := x + panelX + specX + buttonX + 5
				actualY := y + panelY + specY + buttonY + 5
				attempts := 0
				loop
				{
					this.ClickTheMouse(actualX, actualY)
					Sleep, 50
					active := g_SF.Memory.DialogManager.dialogs[dialogIndex].Active.Read()
					if (!active)
						return True
					attempts += 1
				}
				until attempts >= this.MaxRetries
			}
		}
		return False
	}
	
	GetCurrentSpecialisation(heroID,upgradeIndex)
	{
		currSpecID := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.HeroHandler.heroes[g_SF.Memory.GetHeroHandlerIndexByChampID(heroID)].upgradeHandler.PurchasedUpgrades[upgradeIndex].Read()
		currSpecName := g_SF.Memory.ReadHeroUpgradeSpecializationName(heroID,currSpecID)
		return [currSpecID, currSpecName]
	}
	
	FindHeroSpecialisationUpgradeIDs(heroID)
	{
		purchasedSize := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.HeroHandler.heroes[g_SF.Memory.GetHeroHandlerIndexByChampID(heroID)].upgradeHandler.PurchasedUpgrades.size.Read()
		if (purchasedSize == "" || purchasedSize < 0 || purchasedSize > 2000)
			return False
		indexes := []
		loop %purchasedSize%
		{
			upgradeIndex := A_Index-1
			upgradeID := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.HeroHandler.heroes[g_SF.Memory.GetHeroHandlerIndexByChampID(heroID)].upgradeHandler.PurchasedUpgrades[upgradeIndex].Read()
			isSpec := g_SF.Memory.ReadHeroUpgradeIsSpec(heroID, upgradeID)
			if (!isSpec)
				continue
			indexes.Push(upgradeIndex)
		}
		return indexes
	}
	
	; ===========================
	; ===== MOUSE FUNCTIONS =====
	; ===========================
	
	ClickTheMouse(xClick,yClick)
	{
		hWnd := g_SF.hWnd
		WinActivate, ahk_id %hWnd%
		Sleep, 40
		MouseMove, %xClick%, %yClick%
		Sleep, 10
		MouseClick, Left, %xClick%, %yClick%, 1, 0, D
		Sleep, 80
		MouseClick, Left, %xClick%, %yClick%, 1, 0, U
	}
	
	; =================================
	; ===== MISC HELPER FUNCTIONS =====
	; =================================
	
	GetSpecialisationPotionData()
	{
		size := g_SF.Memory.ReadInventoryItemsCount()
		specPotIndex := 0
		buffId := -1
		buffName := ""
		buffAmount := -1
		loop %size%
		{
			buffIndex := A_Index-1
			buffId := g_SF.Memory.ReadInventoryBuffIDBySlot(buffIndex)
			buffName := g_SF.Memory.ReadInventoryBuffNameBySlot(buffIndex)
			if (buffId == IC_CazrinBooksFarmer_Component.SpecPotionID)
			{
				buffAmount := g_SF.Memory.ReadInventoryBuffCountBySlot(buffIndex)
				return [specPotIndex, buffName, buffAmount]
			}
			if (InStr(buffName,"Potion"))
				specPotIndex += 1
		}
	}
	
	ConfirmDialogActive(dialogName := "")
	{
		size := g_SF.Memory.DialogManager.dialogs.size.Read()
		if (dialogName == "" || size == "" || size < 0 || size > 2000)
			return ""
		loop %size%
		{
			dialogIndex := A_Index-1
			name := g_SF.Memory.DialogManager.dialogs[dialogIndex].sprite.gameObjectName.Read()
			active := g_SF.Memory.DialogManager.dialogs[dialogIndex].Active.Read()
			if (name == dialogName && active)
				return True
		}
		return False
	}
	
	WaitDialogNotTransitioning(dialogIndex, waitTimeout := 1000)
	{
		startTime := this.GetTickCount()
		elapsedTime := startTime
		loop
		{
			transitioning := g_SF.Memory.DialogManager.dialogs[dialogIndex].dt.Active_k__BackingField.Read()
			if (!transitioning)
				return True
			Sleep, 50
			elapsedTime := this.GetTickCount()
		}
		until elapsedTime > (startTime + waitTimeout)
		return False
	}
	
	CloseAnyActiveDialogs()
	{
		size := g_SF.Memory.DialogManager.dialogs.size.Read()
		if (size == "" || size < 0 || size > 2000)
			return
		loop %size%
		{
			if (g_SF.Memory.DialogManager.dialogs[A_Index-1].Active.Read())
			{
				this.ToggleShift(True)
				g_SF.DirectedInput(,, "{Esc}" )
				this.ToggleShift()
				return
			}
		}
		return
	}
	
	ToggleShift(shiftKeyDown := false)
	{
		g_SF.DirectedInput(shiftKeyDown ? 1 : 0, shiftKeyDown ? 0 : 1, "{Shift}")
		startTime := this.GetTickCount()
		elapsedTime := 0
		while (g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Screen.uiController.bottomBar.heroPanel.activeBoxes[0].levelUpInfoHandler.OverrideLevelUpAmount.Read() AND elapsedTime < 100) ;Allow 100ms for the keypress to apply at maximum to avoid getting stuck. On a fast PC it only took AHK tick (15ms) extra when needed
		{
			Sleep, 1
			elapsedTime := this.GetTickCount() - startTime
		}
	}
	
	GetTickCount()
	{
		if (this.TickFrequency < 0)
		{
			DllCall("QueryPerformanceFrequency", "Int64*", freq)
			this.TickFrequency := freq / 1000
		}
		DllCall("QueryPerformanceCounter", "Int64*", tick)
		return tick / this.TickFrequency
	}
	
}