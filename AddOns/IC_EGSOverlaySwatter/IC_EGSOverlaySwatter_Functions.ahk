class IC_EGSOverlaySwatter_Functions
{
	static SettingsPath := A_LineFile . "\..\EGSOverlaySwatter_Settings.json"
	static EGSPlatformID := 21

	InjectAddon()
	{
		local splitStr := StrSplit(A_LineFile, "\")
		local addonDirLoc := splitStr[(splitStr.Count()-1)]
		local addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_EGSOverlaySwatter_Addon.ahk`n"
		FileAppend, %addonLoc%, %g_BrivFarmModLoc%
	}
	
	; ======================
	; ===== MAIN STUFF =====
	; ======================
	
	DisableOverlayFiles(primaryFolder, secondaryFolder, setDisabled)
	{
		primaryFolderExists := this.IsFolder(primaryFolder)
		if (!primaryFolderExists)
			return "EGS Install Folder does not exist."
		secondaryFolderExists := secondaryFolder != "" ? this.IsFolder(secondaryFolder) : false
		overlayFiles := this.FilesList(primaryFolder)
		if (secondaryFolderExists)
			for k,v in this.FilesList(secondaryFolder)
				overlayFiles.push(v)
		if (ObjLength(overlayFiles) == 0)
		{
			if (setDisabled)
				return "No overlay files can be found - already disabled."
			else
				return "Cannot enable overlay because no overlay files exist."
		}
		else
		{
			returnObj := this.ToggleOverlayFiles(overlayFiles,setDisabled)
			if (returnObj["errorState"] > 0)
				return "One or more overlay files could not be renamed. Need to run as admin."
			if (returnObj["changesMade"])
				return returnObj["renamedFiles"]
		}
	}
	
	ToggleOverlayFiles(overlayFiles,setDisabled)
	{
		if (ObjLength(overlayFiles) == 0)
			return
		returnObj := {"errorState":0,"changesMade":false,"renamedFiles":[]}
		for k,v in overlayFiles
		{
			egsosAdded := false
			if (setDisabled AND !InStr(v, ".txt")) ; Overlay file is not disabled.
			{
				vWithTxt := % v ".txt"
				FileMove, %v%, %vWithTxt%, 1
				if (ErrorLevel == 0)
				{
					returnObj["changesMade"] := true
					returnObj["renamedFiles"].push(vWithTxt)
					egsosAdded := true
				}
				else
					returnObj["errorState"] := 1
			}
			else if (!setDisabled AND InStr(v, ".txt")) ; Overlay is disabled.
			{
				vWithoutTxt := SubStr(v, 1, -4)
				FileMove, %v%, %vWithoutTxt%, 1
				if (ErrorLevel == 0)
				{
					returnObj["changesMade"] := true
					returnObj["renamedFiles"].push(vWithoutTxt)
					egsosAdded := true
				}
				else
					returnObj["errorState"] := 1
			}
			if (!egsosAdded)
				returnObj["renamedFiles"].push(v)
		}
		return returnObj
	}
	
	; ======================
	; ===== UTIL STUFF =====
	; ======================
	
	IsGameClosed()
	{
		if(g_SF.Memory.ReadCurrentZone() == "" AND Not WinExist( "ahk_exe " . g_userSettings[ "ExeName"] ))
			return true
		return false
	}
	
	IsFolder(inputFolder)
	{
		return InStr(FileExist(inputFolder),"D")
	}
	
	FilesList(dir) {
		local list := []
		Loop, Files, %dir%\*.*, DRF
		{
			if (!RegExMatch(A_LoopFileExt, "i)(txt|exe)"))
				continue
			local currFile := A_LoopFileFullPath
			if (InStr(currFile, "SelfUpdateStaging"))
				continue
			if (RegExMatch(A_LoopFileName, "EOSOverlayRenderer-Win(32|64)-Shipping"))
				list.push(currFile)
		}
		return list
	}
	
	GetSetState(setDisabled := true, capitalise := false)
	{
		if (setDisabled)
			return capitalise ? "Disable" : "disable"
		return capitalise ? "Enable" : "enable"
	}
	
}