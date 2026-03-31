#include %A_LineFile%\..\IC_GameSettingsFix_Functions.ahk
#include %A_LineFile%\..\IC_GameSettingsFix_GUI.ahk

if(IsObject(IC_BrivGemFarm_Component))
{
	IC_GameSettingsFix_Functions.InjectAddon()
	global g_GameSettingsFix := new IC_GameSettingsFix_Component
	global g_GameSettingsFixGUI := new IC_GameSettingsFix_GUI
	g_GameSettingsFixGUI.Init()
	g_GameSettingsFix.Init()
}
else
{
	GuiControl, ICScriptHub:Text, GSF_StatusText, WARNING: This addon needs IC_BrivGemFarm enabled.
	return
}

class IC_GameSettingsFix_Component
{

	TimerFunctions := {}
	DefaultSettings := {"TargetFramerate":600,"PercentOfParticlesSpawned":0,"resolution_x":1280,"resolution_y":720,"resolution_fullscreen":false,"ReduceFramerateWhenNotInFocus":false,"LevelupAmountIndex":3,"UseConsolePortraits":false,"FormationSaveIncludeFeatsCheck":false,"NarrowHeroBoxes":true,"ShowAllHeroBoxes":true,"HKsRequired":true,"HKsSwap25100":true,"CurrentProfile":""}
	Settings := {}
	CurrentProfile := this.DefaultSettings["CurrentProfile"]
	ReadOnly := false
	
	GameSettingsFileLocation := ""
	FixedCounter := 0
	
	InitialisedStatus := false
	DisplayStatusTimeout := 0
	MessageStickyTimer := 6000
	
	; ==========================
	; ===== Main Functions =====
	; ==========================
	
	UpdateGameSettingsFix()
	{
		if (this.GameSettingsFileLocation == "")
			this.FindSettingsFile()
		try
		{
			SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
			this.FixedCounter := SharedRunData.GSF_FixedCounter
			if (!this.InitialisedStatus)
			{
				SharedRunData.GSF_Status := "Started."
				this.InitialisedStatus := true
			}
			sharedStatus := SharedRunData.GSF_Status
			this.UpdateMainStatus(sharedStatus)
			if (sharedStatus != "")
				SharedRunData.GSF_Status := ""
			if (SharedRunData.GSF_GameSettingsFileLocation != this.GameSettingsFileLocation)
				SharedRunData.GSF_GameSettingsFileLocation := this.GameSettingsFileLocation
		}
		catch
			this.UpdateMainStatus(IC_GameSettingsFix_GUI.UnableConnectMessage)
	}
	
	JsonifyObject(obj)
	{
		if (!IsObject(obj))
			return obj
		psJsonObj := "{"
		psFirst := true
		for k,v in obj
		{
			if (psFirst)
				psFirst := false
			else
				psJsonObj .= ","
			if (IsObject(v))
				psJsonObj .= """" k """:" (this.JsonifyObject(v))
			else
				psJsonObj .= """" k """:" v
		}
		psJsonObj .= "}"
		return psJsonObj
	}
	
	FindSettingsFile()
	{
		installPath := g_UserSettings["InstallPath"] ;Contains filename
		SplitPath, installPath,, settingsFileLoc
		settingsFileLoc .= "\IdleDragons_Data\StreamingAssets\localSettings.json"
		if (!FileExist(settingsFileLoc))
		{
			if (IC_GameSettingsFix_Functions.IsGameClosed())
				return
			webRequestLogLoc := g_SF.Memory.GetWebRequestLogLocation()
			if (!InStr(webRequestLogLoc, "webRequestLog"))
				return
			settingsFileLoc := StrReplace(webRequestLogLoc, "downloaded_files\webRequestLog.txt", "localSettings.json")
		}
		if (settingsFileLoc == "" || !FileExist(settingsFileLoc))
			return
		this.GameSettingsFileLocation := settingsFileLoc
		IC_GameSettingsFix_Functions.AddFileToGUIList(settingsFileLoc)
	}
	
	; =======================================
	; ===== Initialisation and Settings =====
	; =======================================

	Init()
	{
		this.LoadSettings()
		IC_GameSettingsFix_Functions.UpdateProfilesDDL(this.CurrentProfile)
		this.FindSettingsFile()
		this.UpdateMainStatus(IC_GameSettingsFix_GUI.WaitingMessage)
		g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(g_GameSettingsFix, "CreateTimedFunctions"))
	}
	
	LoadSettings(pathToGetGSFSettings := "")
	{
		Global
		writeSettings := false
		if (pathToGetGSFSettings == "")
			pathToGetGSFSettings := IC_GameSettingsFix_Functions.SettingsPath
		this.Settings := g_SF.LoadObjectFromJSON(pathToGetGSFSettings)
		if(!IsObject(this.Settings))
		{
			this.SetDefaultSettings()
			writeSettings := true
		}
		if (this.CheckMissingOrExtraSettings())
			writeSettings := true
		if (!this.Settings["NarrowHeroBoxes"] || !this.Settings["HKsRequired"])
		{
			this.Settings["NarrowHeroBoxes"] := true
			this.Settings["HKsRequired"] := true
			writeSettings := true
		}
		if(writeSettings)
			g_SF.WriteObjectToJSON(pathToGetGSFSettings, this.Settings)
		GuiControl, ICScriptHub:, GSF_TargetFramerate, % this.Settings["TargetFramerate"]
		GuiControl, ICScriptHub:, GSF_PercentOfParticlesSpawned, % this.Settings["PercentOfParticlesSpawned"]
		GuiControl, ICScriptHub:, GSF_resolution_x, % this.Settings["resolution_x"]
		GuiControl, ICScriptHub:, GSF_resolution_y, % this.Settings["resolution_y"]
		GuiControl, ICScriptHub:, GSF_resolution_fullscreen, % this.Settings["resolution_fullscreen"]
		GuiControl, ICScriptHub:, GSF_ReduceFramerateWhenNotInFocus, % this.Settings["ReduceFramerateWhenNotInFocus"]
		GuiControl, ICScriptHub:Choose, GSF_LevelupAmountIndex, % IC_GameSettingsFix_Functions.ConvertLevelUpIndexToUI(this.Settings["LevelupAmountIndex"])
		GuiControl, ICScriptHub:, GSF_UseConsolePortraits, % this.Settings["UseConsolePortraits"]
		GuiControl, ICScriptHub:, GSF_FormationSaveIncludeFeatsCheck, % this.Settings["FormationSaveIncludeFeatsCheck"]
		GuiControl, ICScriptHub:, GSF_NarrowHeroBoxes, % this.Settings["NarrowHeroBoxes"]
		GuiControl, ICScriptHub:, GSF_ShowAllHeroBoxes, % this.Settings["ShowAllHeroBoxes"]
		GuiControl, ICScriptHub:, GSF_HKsRequired, % this.Settings["HKsRequired"]
		GuiControl, ICScriptHub:, GSF_HKsSwap25100, % this.Settings["HKsSwap25100"]
		this.CurrentProfile := this.Settings["CurrentProfile"]
		IC_GameSettingsFix_Functions.UpdateSharedSettings()
	}
	
	SaveSettings()
	{
		Global
		Gui, Submit, NoHide
		GuiControlGet,GSF_TargetFramerate, ICScriptHub:, GSF_TargetFramerate
		GuiControlGet,GSF_PercentOfParticlesSpawned, ICScriptHub:, GSF_PercentOfParticlesSpawned
		GuiControlGet,GSF_resolution_x, ICScriptHub:, GSF_resolution_x
		GuiControlGet,GSF_resolution_y, ICScriptHub:, GSF_resolution_y
		GuiControlGet,GSF_resolution_fullscreen, ICScriptHub:, GSF_resolution_fullscreen
		GuiControlGet,GSF_ReduceFramerateWhenNotInFocus, ICScriptHub:, GSF_ReduceFramerateWhenNotInFocus
		GuiControlGet,GSF_LevelupAmountIndex, ICScriptHub:, GSF_LevelupAmountIndex
		GuiControlGet,GSF_UseConsolePortraits, ICScriptHub:, GSF_UseConsolePortraits
		GuiControlGet,GSF_FormationSaveIncludeFeatsCheck, ICScriptHub:, GSF_FormationSaveIncludeFeatsCheck
		GuiControlGet,GSF_NarrowHeroBoxes, ICScriptHub:, GSF_NarrowHeroBoxes
		GuiControlGet,GSF_HKsRequired, ICScriptHub:, GSF_HKsRequired
		GuiControlGet,GSF_HKsSwap25100, ICScriptHub:, GSF_HKsSwap25100
		local sanityChecked := this.SanityCheckSettings()
		this.CheckMissingOrExtraSettings()
		this.Settings["TargetFramerate"] := GSF_TargetFramerate
		this.Settings["PercentOfParticlesSpawned"] := GSF_PercentOfParticlesSpawned
		this.Settings["resolution_x"] := GSF_resolution_x
		this.Settings["resolution_y"] := GSF_resolution_y
		this.Settings["resolution_fullscreen"] := GSF_resolution_fullscreen
		this.Settings["ReduceFramerateWhenNotInFocus"] := GSF_ReduceFramerateWhenNotInFocus
		this.Settings["LevelupAmountIndex"] := IC_GameSettingsFix_Functions.ConvertLevelUpIndexFromUI(GSF_LevelupAmountIndex)
		this.Settings["UseConsolePortraits"] := GSF_UseConsolePortraits
		this.Settings["FormationSaveIncludeFeatsCheck"] := GSF_FormationSaveIncludeFeatsCheck
		this.Settings["NarrowHeroBoxes"] := GSF_NarrowHeroBoxes
		this.Settings["ShowAllHeroBoxes"] := GSF_ShowAllHeroBoxes
		this.Settings["HKsRequired"] := GSF_HKsRequired
		this.Settings["HKsSwap25100"] := GSF_HKsSwap25100
		this.Settings["CurrentProfile"] := this.CurrentProfile
		g_SF.WriteObjectToJSON(IC_GameSettingsFix_Functions.SettingsPath, this.Settings)
		IC_GameSettingsFix_Functions.UpdateSharedSettings()
		if (!sanityChecked)
			this.UpdateMainStatus("Saved settings.")
	}
	
	SanityCheckSettings()
	{
		local sanityChecked := false
		GuiControlGet,GSF_TargetFramerate, ICScriptHub:, GSF_TargetFramerate
		GuiControlGet,GSF_PercentOfParticlesSpawned, ICScriptHub:, GSF_PercentOfParticlesSpawned
		GuiControlGet,GSF_resolution_x, ICScriptHub:, GSF_resolution_x
		GuiControlGet,GSF_resolution_y, ICScriptHub:, GSF_resolution_y
		if (!IC_GameSettingsFix_Functions.IsNumber(GSF_TargetFramerate) || GSF_TargetFramerate <= 20)
		{
			GSF_TargetFramerate := this.DefaultSettings["TargetFramerate"]
			GuiControl, ICScriptHub:, GSF_TargetFramerate, % GSF_TargetFramerate
			sanityChecked := true
			this.UpdateMainStatus("Save Error. TargetFramerate was an invalid number.")
		}
		if (!IC_GameSettingsFix_Functions.IsNumber(GSF_PercentOfParticlesSpawned) || GSF_PercentOfParticlesSpawned < 0 || GSF_PercentOfParticlesSpawned > 100)
		{
			GSF_PercentOfParticlesSpawned := this.DefaultSettings["PercentOfParticlesSpawned"]
			GuiControl, ICScriptHub:, GSF_PercentOfParticlesSpawned, % GSF_PercentOfParticlesSpawned
			sanityChecked := true
			this.UpdateMainStatus("Save Error. PercentOfParticlesSpawned was an invalid number.")
		}
		if (!IC_GameSettingsFix_Functions.IsNumber(GSF_resolution_x) || GSF_resolution_x < 0)
		{
			GSF_resolution_x := this.DefaultSettings["resolution_x"]
			GuiControl, ICScriptHub:, GSF_resolution_x, % GSF_resolution_x
			sanityChecked := true
			this.UpdateMainStatus("Save Error. resolution_x was an invalid number.")
		}
		if (!IC_GameSettingsFix_Functions.IsNumber(GSF_resolution_y) || GSF_resolution_y < 0)
		{
			GSF_resolution_y := this.DefaultSettings["resolution_y"]
			GuiControl, ICScriptHub:, GSF_resolution_y, % GSF_resolution_y
			sanityChecked := true
			this.UpdateMainStatus("Save Error. resolution_y was an invalid number.")
		}
		return sanityChecked
	}
	
	SetDefaultSettings()
	{
		this.Settings := {}
		for k,v in this.DefaultSettings
			this.Settings[k] := v
	}
	
	CheckMissingOrExtraSettings()
	{
		local madeEdit := false
		for k,v in this.DefaultSettings
		{
			if (this.Settings[k] == "") {
				this.Settings[k] := v
				madeEdit := true
			}
		}
		for k,v in this.Settings
		{
			if (!this.DefaultSettings.HasKey(k)) {
				this.Settings.Delete(k)
				madeEdit := true
			}
		}
		return madeEdit
	}
	
	SaveProfile()
	{
		local profileName
		local defaultText := this.CurrentProfile
		WinGetPos, xPos, yPos,,, 
		InputBox, profileName, Profile Name, Input the profile name:,,375,129,,,,,%defaultText%
		isCanceled := ErrorLevel
		while (!isCanceled && (!GUIFunctions.TestInputForAlphaNumericDash(profileName) || profileName == ""))
		{
			if (profileName == "")
				errMsg := "Cannot use an empty name."
			else
				errMsg := "Can only contain letters numbers or dashes."
			InputBox, profileName, Profile Name, %errMsg%`nInput the profile name:,,375,144,,,,,%defaultText%
			isCanceled := ErrorLevel
		}
		if (isCanceled)
		{
			this.UpdateMainStatus("Cancelled saving profile.")
			return
		}
		local profilePath := IC_GameSettingsFix_Functions.ProfilesPath . profileName . ".json"
		if (FileExist(profilePath))
		{
			MsgBox, 52, Overwrite?, This profile already exists. Overwrite it?
			IfMsgBox, No
			{
				this.UpdateMainStatus("Cancelled saving profile.")
				return
			}
		}
		this.CurrentProfile := profileName
		this.SaveSettings()
		if (!IC_GameSettingsFix_Functions.IsFolder(IC_GameSettingsFix_Functions.ProfilesPath))
			FileCreateDir, % IC_GameSettingsFix_Functions.ProfilesPath
		g_SF.WriteObjectToJSON(profilePath, this.Settings)
		IC_GameSettingsFix_Functions.UpdateProfilesDDL(profileName)
		this.UpdateMainStatus("Saved profile: " profileName)
	}
	
	LoadProfile()
	{
		Global
		Gui, Submit, NoHide
		GuiControlGet,GSF_Profiles, ICScriptHub:, GSF_Profiles
		currProfilePath := IC_GameSettingsFix_Functions.ProfilesPath GSF_Profiles ".json"
		profileSettings := g_SF.LoadObjectFromJSON(currProfilePath)
		this.Settings := {}
		for k,v in profileSettings
		{
			this.Settings.push(k, v)
		}
		this.LoadSettings(currProfilePath)
		this.SaveSettings()
		this.UpdateMainStatus("Loaded profile: " GSF_Profiles)
	}
	
	DeleteProfile()
	{
		Global
		Gui, Submit, NoHide
		GuiControlGet,GSF_Profiles, ICScriptHub:, GSF_Profiles
		MsgBox, 52, Delete?, Are you sure you want to delete the '%GSF_Profiles%' profile?
		IfMsgBox, No
		{
			this.UpdateMainStatus("Cancelled deleting profile.")
			return
		}
		currProfilePath := IC_GameSettingsFix_Functions.ProfilesPath GSF_Profiles ".json"
		FileDelete, % currProfilePath
		if (ErrorLevel > 0)
			this.UpdateMainStatus("Failed to delete profile for unknown reasons.")
		else
		{
			if (GSF_Profiles == this.CurrentProfile)
			{
				this.CurrentProfile := ""
				this.SaveSettings()
			}
			this.UpdateMainStatus("Deleted profile: " GSF_Profiles)
		}
		IC_GameSettingsFix_Functions.UpdateProfilesDDL(this.CurrentProfile)
	}
	
	; =====================
	; ===== GUI STUFF =====
	; =====================
	
	UpdateMainStatus(status)
	{
		GuiControlGet,GSF_StatusText, ICScriptHub:, GSF_StatusText
		GSF_TimerIsUp := A_TickCount - this.DisplayStatusTimeout >= this.MessageStickyTimer
		if (status == "" && !GSF_TimerIsUp && !InStr(GSF_StatusText, "The settings file has been fixed"))
			status := GSF_StatusText
		if (status != "" && GSF_TimerIsUp)
			this.DisplayStatusTimeout := A_TickCount
		if (status == "")
			status := "The settings file has been fixed " . (this.FixedCounter == 1 ? "once" : (this.FixedCounter == 2 ? "twice": (this.FixedCounter . " times"))) . "."
		GuiControl, ICScriptHub:Text, GSF_StatusText, % status
		Gui, Submit, NoHide
	}
	
	; =======================
	; ===== TIMER STUFF =====
	; =======================
	
	CreateTimedFunctions()
	{
		fncToCallOnTimer := ObjBindMethod(this, "UpdateGameSettingsFix")
		g_BrivFarmComsObj.OneTimeRunAtResetStartFunctions["UpdateGameSettingsFix"] := fncToCallOnTimer
		g_BrivFarmComsObj.OneTimeRunAtResetStartFunctionsTimes["UpdateGameSettingsFix"] := -500
	}
}