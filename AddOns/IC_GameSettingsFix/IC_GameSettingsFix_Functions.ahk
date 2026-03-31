class IC_GameSettingsFix_Functions
{
	static SettingsPath := A_LineFile . "\..\GameSettingsFix_Settings.json"
	static ProfilesPath := A_LineFile . "\..\profiles\"
	
	InjectAddon()
	{
		local splitStr := StrSplit(A_LineFile, "\")
		local addonDirLoc := splitStr[(splitStr.Count()-1)]
		local addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_GameSettingsFix_Addon.ahk`n"
		FileAppend, %addonLoc%, %g_BrivFarmModLoc%
	}
	
	UpdateSharedSettings()
	{
		try {
			SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
			SharedRunData.GSF_UpdateSettingsFromFile(this.SettingsPath)
			return true
		}
		return false
	}
	
	UpdateProfilesDDL(nameToSelect := "")
	{
		local ddlList := ""
		local foundName := false
		for k,v in this.ProfilesList(this.ProfilesPath)
		{
			local profileName := StrReplace(v, ".json", "")
			ddlList .= profileName "|"
			if (profileName == nameToSelect)
			{
				ddlList .= "|"
				foundName := true
			}
		}
		GuiControl, ICScriptHub:, GSF_Profiles, |
		GuiControl, ICScriptHub:, GSF_Profiles, % ddlList
		Gui, Submit, NoHide
	}
	
	ProfilesList(dir)
	{
		local list := []
		if (!this.IsFolder(dir))
			return list
		Loop, Files, %dir%\*.json, DRF
		{
			list.push(A_LoopFileName)
		}
		return list
	}
	
	AddFileToGUIList(GSF_settingsFileLoc)
	{
		local restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "GSF_SettingsFileLocation")
		LV_Delete()
		LV_Add(,GSF_settingsFileLoc)
		LV_ModifyCol(1)
	}
	
	IsGameClosed()
	{
		if(g_SF.Memory.ReadCurrentZone() == "" AND Not WinExist( "ahk_exe " . g_userSettings[ "ExeName"] ))
			return true
		return false
	}
	
	IsFolder(GSF_inputFolder)
	{
		return InStr(FileExist(GSF_inputFolder),"D")
	}
	
	IsReadOnly(settingsFileLoc)
	{
		FileGetAttrib, fileAttributes, %settingsFileLoc%
		if (InStr(fileAttributes, "R"))
			return true
		return false
	}
	
	ConvertLevelUpIndexFromUI(levelUpIndexUI)
	{
		switch levelUpIndexUI
		{
			case "x1": return 0
			case "x10": return 1
			case "x25": return 2
			case "x100": return 3
			default: return 4
		}
	}
	
	ConvertLevelUpIndexToUI(levelUpIndexVal)
	{
		switch levelUpIndexVal
		{
			case 0: return "x1"
			case 1: return "x10"
			case 2: return "x25"
			case 3: return "x100"
			default: return "Next Upg"
		}
	}
	
	IsNumber(inputText)
	{
		if inputText is number
			return true
		return false
	}
	
}