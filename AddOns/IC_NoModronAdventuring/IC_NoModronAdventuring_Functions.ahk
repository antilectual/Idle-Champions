class IC_NMA_Functions
{
    endScript := false
    TickFrequency := -1

    GetHeroDefines()
    {
        start := this.GetTickCount()
        defines := {}
        g_SF.Memory.OpenProcessReader()
        g_SF.Memory.GetChampIDToIndexMap()
        heroCount := g_SF.Memory.ReadChampListSize()
        if (heroCount < 0 || heroCount > 500)
            return {}
        champID := 0
        Loop, %heroCount%
        {
            ++champID
            isOwned := g_SF.Memory.ReadHeroIsOwned(champID)
            if (!isOwned OR champID == 107)
                continue
            name := g_SF.Memory.ReadChampNameByID(champID)
            seat := g_SF.Memory.ReadChampSeatByID(champID)
            defines[champID] := new IC_NMA_Functions.HeroDefine(champID, name, seat)
            heroIndex := g_SF.Memory.GetHeroHandlerIndexByChampID(champID)
            heroObj := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.HeroHandler.heroes[heroIndex]
            upgradeCount := heroObj.upgradeHandler.upgradesByUpgradeId.size.Read()
            if (upgradeCount < 0 || upgradeCount > 200)
                continue
            upgIndex := 0
            Loop, %upgradeCount%
            {
                valObj := heroObj.upgradeHandler.upgradesByUpgradeId["value", upgIndex]
                defObj := valObj.Def
                reqLvl := valObj.RequiredLevel.Read()
                if (reqLvl != "" && reqLvl < 9999)
                    defines[champID].MaxLvl := Max(reqLvl, defines[champID].MaxLvl)
                rawGraphic := defObj.defaultSpecGraphic.Read()
                if (rawGraphic && rawGraphic != "")
                {
                    upgradeID := heroObj.upgradeHandler.upgradesByUpgradeId["key", upgIndex].Read()
                    requiredUpgradeID := defObj.RequiredUpgradeID.Read()
                    specName := defObj.SpecializationName.Read()
                    if (specName == "")
                        specName := "Spec " . upgradeID
                    defines[champID].SpecDefines.AddSpec(upgradeID, reqLvl, requiredUpgradeID, specName)
                }
                ++upgIndex
                ; OutputDebug, % "upgIndex " upgIndex . ": " . (this.GetTickCount() - upgStartTimer) / 1000 . "s"
                ; upgStartTimer := this.GetTickCount()
            }
            OutputDebug, % "Champ " champID . ": " . (this.GetTickCount() - champStartTimer) / 1000 . "s"
            if(!foundSpec[champID])
                OutputDebug, % name . " (" . champID . ") failed to find a specialization."
            champStartTimer := this.GetTickCount()
            defines[champID].SpecDefines.SortSpecList()
        }
        OutputDebug, % "TotalTime: " . (this.GetTickCount() - startTimer) / 1000 . "s"
        defines.TimeStamp := A_MMMM . " " . A_DD . ", " . A_YYYY . " at " . A_Hour . ":" . A_Min . ":" . A_Sec
        defines.LoadTime := this.GetTickCount() - start
        ;a bit easier to debug from json file
        g_SF.WriteObjectToJSON(A_LineFile . "\..\HeroDefines.JSON", defines)
        return defines
    }

    class HeroDefine
    {
        __new(heroID, heroName, seat)
        {
            this.HeroID := heroID
            this.HeroName := heroName
            this.MaxLvl := 1
            this.Seat := seat
            this.SpecDefines := new IC_NMA_Functions.SpecDefineSets
            return this
        }
    }

    class SpecDefine
    {
        __new(upgradeID, requiredLvl, requiredUpgradeID, specName)
        {
            this.UpgradeID := upgradeID
            this.RequiredLvl := requiredLvl
            this.RequiredUpgradeID := requiredUpgradeID
            this.SpecName := specName
            return this
        }
    }

    class SpecDefineSets
    {
        ;each item is an array of spec upgrades associated with a given level and required upgrade.
        specList := {}
        specListSize := 0
        ;an array that mimics specList, but consists of strings for drop down list gui elements.
        ddlList := {}
        ;each item is an object of data to know which items from specList to use based on level and required upgrade data.
        setList := {}
        setListSize := 0

        AddSpec(upgID, reqLvl, reqUpgID, specName)
        {
            isNewSet := true
            for k, v in this.setList
            {
                if (reqLvl == v.reqLvl)
                {
                    isNewSet := false
                    ;this handles spec sets like Morg and Selise that change based on previous choices
                    if !v.listIndex.HasKey(reqUpgID)
                    {
                        index := this.createNewSpecListEntry()
                        v.AddNewReqUpgID(index, reqUpgID)
                    }
                    else
                        index := v.listIndex[reqUpgID]
                    ;following should not be possible, but leaving here just in case
                    ;if !IsObject(this.specList[index])
                    ;    this.createNewSpecListEntry(index)
                    this.pushSpec(index, upgID, reqLvl, reqUpgID, specName, k)
                    break
                }
            }
            if isNewSet
            {
                index := this.createNewSpecListEntry()
                this.setList.Push(new IC_NMA_Functions.SetData(index, reqLvl, reqUpgID))
                this.setListSize := this.setList.Count()
                this.pushSpec(index, upgID, reqLvl, reqUpgID, specName, k)
            }
        }

        pushSpec(index, upgID, reqLvl, reqUpgID, specName, k)
        {
            this.specList[index].Push(new IC_NMA_Functions.SpecDefine(upgID, reqLvl, reqUpgID, specName))
        }

        createNewSpecListEntry()
        {
            this.specListSize += 1
            this.specList[this.specListSize] := {}
            this.ddlList[this.specListSize] := ""
            return this.specListSize
        }

        SortSpecList()
        {
            for k, v in this.specList
            {
                ;insertion sort
                i := 1
                while (i <= v.Count())
                {
                    j := i
                    while (j > 1 AND v[j-1].UpgradeID > v[j].UpgradeID)
                    {
                        temp := v[j].Clone()
                        v[j] := v[j-1].Clone()
                        v[j-1] := temp.Clone()
                        --j
                    }
                    ++i
                }
            }
        }

        SpecDefineList[reqLvl, reqUpgID]
        {
            get
            {
                index := this.getIndex(reqLvl, reqUpgID)
                if (index == -1)
                    return ""
                else
                    return this.specList[index]
            }
        }

        DDL[reqLvl, reqUpgID]
        {
            get
            {
                index := this.getIndex(reqLvl, reqUpgID)
                if (index == -1)
                    return ""
                else
                {
                    string := ""
                    for k, v in this.specList[index]
                    {
                        string .= v.SpecName . "|"
                    }
                    return string
                }
            }
        }

        getIndex(reqLvl, reqUpgID)
        {
            for k, v in this.setList
            {
                if (reqLvl == v.reqLvl)
                {
                    if v.listIndex.HasKey(0)
                        return v.listIndex[0]
                    else
                        return v.listIndex[reqUpgID]
                }
            }
            return -1
        }
    }

    ;an object for all the spec upgrades associated with a particular level.
    class SetData
    {
        listIndex := {}
        listCount := 0

        __new(index, reqLvl, reqUpgID)
        {
            this.reqLvl := reqLvl
            this.AddNewReqUpgID(index, reqUpgID)
            return this
        }

        AddNewReqUpgID(index, reqUpgID)
        {
            this.listIndex[reqUpgID] := index
            this.listCount += 1
        }
    }

    LevelAndSpec(champID, targetLvl, maxLvlData, specSettings)
    {
        seat := g_SF.Memory.ReadChampSeatByID(champID)
        inputKey := "{F" . seat . "}"
        if !targetLvl
            targetLvl := maxLvlData[champID]
        global NMA_ChooseSpecs
        while (targetLvl > (currChampLevel := g_SF.Memory.ReadChampLvlByID(champID)) AND !(this.endScript))
        {
            if(currChampLevel == lastChampLevel) ; leveling failed, wait for next call
                break
            lastChampLevel := currChampLevel
            g_SF.DirectedInput(,, inputKey)
            for k, v in specSettings[champID]
            {
                if (v.RequiredLvl == g_SF.Memory.ReadChampLvlByID(champID) AND NMA_ChooseSpecs)
                    this.PickSpec(v.Choice, v.Choices, v.UpgradeID)
            }
        }
        return
    }

 IsSpec(champID, champLvl, specSettings)
{
    if (!specSettings.HasKey(champID))
        return false
    
    for k, v in specSettings[champID]
    {
        if (champLvl >= v.RequiredLvl && champLvl <= v.RequiredLvl + 10)
            return true
    }
    return false
}

 PickSpec(champID, choice, choices)
{
    if (!choice || !choices)
        return   
    ScreenCenterX := (g_SF.Memory.ReadScreenWidth() / 2)
    ScreenCenterY := (g_SF.Memory.ReadScreenHeight() / 2)  
    if (!ScreenCenterX || !ScreenCenterY)
        return   
    yOffset := 245
    spacingX := 250    
    rowCenterX := ScreenCenterX
    rowCenterY := ScreenCenterY + yOffset
    xClick := rowCenterX + spacingX * (choice - ((choices + 1) / 2.0))
    yClick := rowCenterY   
    gameExe := g_UserSettings["ExeName"]
    WinActivate, ahk_exe %gameExe%
    WinWaitActive, ahk_exe %gameExe%,, 1
    Sleep, 200  
    MouseMove, xClick, yClick
    Click
    return
}
        
    NMA_CheckForReset()
    {
        if(g_SF.Memory.ReadCurrentZone() > g_NMAResetZone OR (NMA_WallRestart AND g_NMATimeAtWall >= g_NMAWallTime))
        {
            g_SF.ResetServerCall()
            g_SF.CurrentAdventure := g_SF.Memory.ReadCurrentObjID()
            g_SF.RestartAdventure("Adventure Complete")
            return True
        }
        return False
    }

    NMA_GetChampionsToLevel(formationKey)
    {
        for k,v in formationKey
        {
            if(NMA_CB%k%)
            {
                champArray := g_SF.Memory.GetFormationByFavorite(k)
                size := champArray.MaxIndex()
                Loop, %size%
                {
                    g_NMAChampsToLevel[champArray[A_Index]] := False
                }
            }
        }
        return g_NMAChampsToLevel
    }

 NMA_LevelAndSpec(formationID, champID)
{
    champLvl := g_SF.Memory.ReadChampLvlByID(champID)
    seat := g_SF.Memory.ReadChampSeatByID(champID)
    inputKey := "{F" . seat . "}"
    g_SF.DirectedInput(,, inputKey)
    Sleep, 50
    global g_NMAlvlObj
    global NMA_ChooseSpecs    
    ; Check and pick spec if needed
    if (NMA_ChooseSpecs && g_NMAlvlObj.IsSpec(champID, champLvl, g_NMASpecSettings))
    {
        g_NMAlvlObj.PickSpec(champID, champLvl, g_NMASpecSettings)
        return  ; Exit after picking spec, will check again next loop
    }   
    ; Only mark done if at max level AND no pending specs
    if (champLvl >= g_NMAMaxLvl[champID])
        g_NMAChampsToLevel[champID] := True
}

    NMA_UseUltimates(formation)
    {
        global NMA_FireUlts
        global NMA_UltsIgnoreSelise
        global NMA_UltsIgnoreHavilar
        global NMA_UltsIgnoreNERDs
        global NMA_UltsIgnoreEllywick
        for k,v in g_NMAChampsToLevel
        {
            if ((NMA_UltsIgnoreSelise AND k == 81) OR (NMA_UltsIgnoreHavilar AND k == 56) OR (NMA_UltsIgnoreNERDs AND k == 87) OR (NMA_UltsIgnoreEllywick AND k == 83))
                continue
            if(k AND k != -1 AND NMA_FireUlts)
            {
                ultButton := g_SF.GetUltimateButtonByChampID(k)
                g_SF.DirectedInput(,, ultButton)
            }   
        }
    }

    ; Unused test for if champions are finished leveling.
    NMA_CheckForLevelingDone()
    {
        for k,v in g_NMAChampsToLevel
        {
            if(k AND k != -1 AND v == False)
                return False
        }
        return True
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