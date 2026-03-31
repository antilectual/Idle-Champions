class IC_GameSettingsFix_SharedData_Added_Class ; Added to IC_SharedData_Class
{
	GSF_UpdateSettingsFromFile(fileName := "")
	{
		if (fileName == "")
			fileName := IC_GameSettingsFix_Functions.SettingsPath
		settings := g_SF.LoadObjectFromJSON(fileName)
		if (!IsObject(settings))
			return false
		for k,v in settings
			g_BrivUserSettingsFromAddons[ "GSF_" k ] := v
		settings.Delete("CurrentProfile")
		this.GSF_Settings := settings
		if (this.GSF_FixedCounter == "")
			this.GSF_FixedCounter := 0
		this.GSF_HotkeyRequiredReplacements := {"load_formation_1":"Q","load_formation_2":"W","load_formation_3":"E","go_to_previous_area":"LeftArrow","go_to_next_area":"RightArrow","toggle_auto_progress":"G"}
	}
}

; Overrides: OpenIC()
class IC_GameSettingsFix_SharedFunctions_Class extends IC_SharedFunctions_Class
{
	OpenIC()
	{
		Run, "D:\Tools\Idle Champions Scripts\CacheEditModronLimit.vbs"
		this.GSF_FixGameSettings()
		base.OpenIC()
	}
}

class IC_GameSettingsFix_SharedFunctions_Added_Class ; Added to IC_SharedFunctions_Class
{
	GSF_FixGameSettings()
	{
		GSF_CurrSettingsFileLoc := g_SharedData.GSF_GameSettingsFileLocation
		if (GSF_CurrSettingsFileLoc == "")
			return
		if (g_SharedData.GSF_Settings == "")
			return
		if (FileExist(GSF_CurrSettingsFileLoc))
		{
			if (IC_GameSettingsFix_Functions.IsReadOnly(GSF_CurrSettingsFileLoc))
			{
				g_SharedData.GSF_Status := "Game settings file is set to read-only. Please disable that immediately."
				return
			}
			GSF_settingsData := this.GSF_ReadAndEditSettingsString(GSF_CurrSettingsFileLoc)
			if (GSF_settingsData != "")
				this.GSF_WriteSettingsStringToFile(GSF_settingsData)
			else
				g_SharedData.GSF_Status := "Settings didn't need changing."
		}
	}
	
	GSF_ReadAndEditSettingsString(GSF_raessSettingsFileLoc)
	{
		local GSF_settingsFile
		local madeChanges := false
		FileRead, GSF_settingsFile, %GSF_raessSettingsFileLoc%
		for k,v in g_SharedData.GSF_Settings
		{
			if (k == "CurrentProfile")
				continue
			if (k == "HKsRequired")
			{
				for k,v in g_SharedData.GSF_HotkeyRequiredReplacements
				{
					GSF_before := GSF_settingsFile
					GSF_after := RegExReplace(GSF_before, "(""" . k . """: +[^""]+"")[^""]+"",?[`n`r]+(?:[^`n`r\Q]\E]*[`n`r]+)*( +])", "$1" . v . """`r`n$2")
					if (GSF_before != GSF_after) {
						GSF_SettingsFile := GSF_after
						madeChanges := true
					}
				}
			}
			else if (k == "HKsSwap25100" && v)
			{
				GSF_before := GSF_settingsFile
				GSF_after := RegExReplace(GSF_before, "(""hero_level_10"": +\[)([^]]+)]", "$1`r`n            ""LeftShift""`r`n        ]")
				GSF_after := RegExReplace(GSF_after, "(""hero_level_25"": +\[)([^]]+)]", "$1`r`n            ""LeftControl""`r`n        ]")
				GSF_after := RegExReplace(GSF_after, "(""hero_level_100"": +\[)([^]]+)]", "$1`r`n            ""LeftShift"",`r`n            ""LeftControl""`r`n        ]")
				if (GSF_before != GSF_after) {
					GSF_SettingsFile := GSF_after
					madeChanges := true
				}
			}
			else
			{
				GSF_before := GSF_settingsFile
				GSF_after := RegExReplace(GSF_before, """" k """: (false|true)", """" k """: " (v ? "true" : "false"))
				if (GSF_before != GSF_after) {
					GSF_settingsFile := GSF_after
					madeChanges := true
					continue
				}
				GSF_after := RegExReplace(GSF_before, """" k """: ([0-9]+)", """" k """: " v)
				if (GSF_before != GSF_after) {
					GSF_settingsFile := GSF_after
					madeChanges := true
				}
			}
		}
		if (madeChanges)
			return GSF_settingsFile
		return ""
	}
	
	GSF_WriteSettingsStringToFile(GSF_settingsData)
	{
		local GSF_newFile := FileOpen(g_SharedData.GSF_GameSettingsFileLocation, "w")
		if (!IsObject(GSF_newFile))
			return
		GSF_newFile.Write(GSF_settingsData)
		GSF_newFile.Close()
		g_SharedData.GSF_Status := "The game settings file has been fixed."
		g_SharedData.GSF_FixedCounter++
	}
}