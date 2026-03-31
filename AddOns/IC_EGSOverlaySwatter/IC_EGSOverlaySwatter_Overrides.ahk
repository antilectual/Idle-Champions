class IC_EGSOverlaySwatter_SharedData_Added_Class ; Added to IC_SharedData_Class
{
    EGSOS_UpdateSettingsFromFile(fileName := "")
    {
        if (fileName == "")
            fileName := IC_EGSOverlaySwatter_Functions.SettingsPath
        settings := g_SF.LoadObjectFromJSON(fileName)
        if (!IsObject(settings))
            return false
		for k,v in settings
			g_BrivUserSettingsFromAddons[ "EGSOS_" k ] := v
		this.EGSOS_Settings := settings
    }
}

class IC_EGSOverlaySwatter_SharedFunctions_Added_Class
{
	EGSOS_ToggleOverlayNow()
	{
		previousState := g_SharedData.EGSOS_OverlayCurrentlyDisabled
		setDisabled := g_SharedData.EGSOS_Settings["DisableOverlay"]
		egsFolder := g_SharedData.EGSOS_Settings["EGSFolder"]
		egsFolderDefault := g_SharedData.EGSOS_Settings["CheckDefaultFolder"] ? g_SharedData.EGSOS_Settings["DefaultEGSFolder"] : ""
		returnedStatus := IC_EGSOverlaySwatter_Functions.DisableOverlayFiles(egsFolder, egsFolderDefault, setDisabled)
		if (IsObject(returnedStatus))
		{
			stateText := IC_EGSOverlaySwatter_Functions.GetSetState(setDisabled)
			g_SharedData.EGSOS_Status := "Successfully " . stateText . "d the overlay files."
			g_SharedData.EGSOS_OverlayCurrentlyDisabled := setDisabled
			renamedFilesString := ""
			for k,v in returnedStatus
			{
				if (k>1)
					renamedFilesString .= "|"
				renamedFilesString .= v
			}
			g_SharedData.EGSOS_RenamedFiles := renamedFilesString
		}
		else
		{
			g_SharedData.EGSOS_Status := returnedStatus
			g_SharedData.EGSOS_OverlayCurrentlyDisabled := previousState
			g_SharedData.EGSOS_RenamedFiles := ""
		}
	}
}

class IC_EGSOverlaySwatter_SharedFunctions_Class extends IC_SharedFunctions_Class
{
	OpenIC()
	{
		this.EGSOS_ToggleOverlayNow()
		base.OpenIC()
	}
}