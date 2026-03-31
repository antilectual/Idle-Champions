#include %A_LineFile%\..\IC_EGSOverlaySwatter_Functions.ahk
#include %A_LineFile%\..\IC_EGSOverlaySwatter_GUI.ahk

if(IsObject(IC_BrivGemFarm_Component))
{
	IC_EGSOverlaySwatter_Functions.InjectAddon()
	global g_EGSOverlaySwatter := new IC_EGSOverlaySwatter_Component
	global g_EGSOverlaySwatterGUI := new IC_EGSOverlaySwatter_GUI
	g_EGSOverlaySwatterGUI.Init()
	g_EGSOverlaySwatter.Init()
}
else
{
	GuiControl, ICScriptHub:Text, EGSOS_StatusText, WARNING: This addon needs IC_BrivGemFarm enabled.
	return
}

Class IC_EGSOverlaySwatter_Component
{
	static DisableMessage := "Overlay is disabled."
	static EnableMessage := "Overlay is enabled."
	
	TimerFunctions := {}
	TickFrequency := -1
	DefaultSettings := {"DisableOverlay":true,"EGSFolder":"C:\Program Files (x86)\Epic Games","DefaultEGSFolder":"C:\Program Files (x86)\Epic Games","CheckDefaultFolder":false}
	Settings := {}
	
	InitialisedStatus := false
	DisplayStatusTimeout := 0
	MessageStickyTimer := 6000
	
	OverlayCurrentlyDisabled := false
	PlatformID := ""
	EverythingDisabled := false
	
	; ======================
	; ===== MAIN STUFF =====
	; ======================
	
	UpdateEGSOverlaySwatter()
	{
		this.CheckEGSPlatform()
		try
		{
			SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
			sharedStatus := SharedRunData.EGSOS_Status
			this.UpdateMainStatus(sharedStatus)
			if (sharedStatus != "")
				SharedRunData.EGSOS_Status := ""
				
			sharedOverlayDisabled := SharedRunData.EGSOS_OverlayCurrentlyDisabled
			if (sharedOverlayDisabled == "")
				SharedRunData.EGSOS_OverlayCurrentlyDisabled := this.OverlayCurrentlyDisabled
			else
				this.OverlayCurrentlyDisabled := sharedOverlayDisabled
			if (!this.InitialisedStatus)
			{
				SharedRunData.EGSOS_Status := "Started."
				this.InitialisedStatus := true
			}
			renamedFilesString := SharedRunData.EGSOS_RenamedFiles
			if (renamedFilesString != "")
			{
				renamedFiles := []
				Loop, Parse, renamedFilesString, % "|"
					renamedFiles.push(A_LoopField)
				this.AddFilesToGUIList(renamedFiles)
			}
		}
		catch
			this.UpdateMainStatus(IC_EGSOverlaySwatter_GUI.UnableConnectMessage)
	}
	
	ToggleOverlayNow(setDisabled := true)
	{
		setState := IC_EGSOverlaySwatter_Functions.GetSetState(setDisabled)
		if (!IC_EGSOverlaySwatter_Functions.IsGameClosed())
		{
			MsgBox, 48, Error, % "Cannot " . setState . " the overlay files while the game is running."
			return
		}
		defaultFolder := this.Settings["CheckDefaultFolder"] ? this.Settings["DefaultEGSFolder"] : ""
		returnedStatus := IC_EGSOverlaySwatter_Functions.DisableOverlayFiles(this.Settings["EGSFolder"], defaultFolder, setDisabled)
		if (IsObject(returnedStatus))
		{
			this.UpdateMainStatus("Successfully " . setState . "d the overlay files.")
			this.AddFilesToGUIList(returnedStatus)
		}
		else
			this.UpdateMainStatus(returnedStatus)
	}
	
	CheckEGSPlatform()
	{
		if (this.PlatformID == "")
			this.PlatformID := g_SF.Memory.ReadPlatform()
		if (this.PlatformID != "" && this.PlatformID != IC_EGSOverlaySwatter_Functions.EGSPlatformID)
			this.DisableEverything()
	}

	; ================================
	; ===== LOADING AND SETTINGS =====
	; ================================
	
	Init()
	{
		Global
		this.LoadSettings()
		this.UpdateMainStatus("Waiting for Gem Farm to start.")
		
		overlayFiles := IC_EGSOverlaySwatter_Functions.FilesList(this.Settings["EGSFolder"])
		if (this.Settings["CheckDefaultFolder"])
			for k,v in IC_EGSOverlaySwatter_Functions.FilesList(this.Settings["DefaultEGSFolder"])
				overlayFiles.push(v)
		this.AddFilesToGUIList(overlayFiles)
		for k,v in overlayFiles
		{
			if (InStr(v,".txt"))
			{
				this.OverlayCurrentlyDisabled := true
				break
			}
		}
		
		isEGSPlatform := this.CheckEGSPlatform()
		g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(g_EGSOverlaySwatter, "CreateTimedFunctions"))
		g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(g_EGSOverlaySwatter, "StartTimedFunctions"))
		g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(g_EGSOverlaySwatter, "StopTimedFunctions"))
	}
	
	LoadSettings()
	{
		Global
		writeSettings := false
		this.Settings := g_SF.LoadObjectFromJSON(IC_EGSOverlaySwatter_Functions.SettingsPath)
		if(!IsObject(this.Settings))
		{
			this.SetDefaultSettings()
			writeSettings := true
		}
		if (this.CheckMissingOrExtraSettings())
			writeSettings := true
		if(writeSettings)
			g_SF.WriteObjectToJSON(IC_EGSOverlaySwatter_Functions.SettingsPath, this.Settings)
		GuiControl, ICScriptHub:, EGSOS_DisableOverlay, % this.Settings["DisableOverlay"]
		GuiControl, ICScriptHub:, EGSOS_EGSFolderLocation, % this.Settings["EGSFolder"]
		GuiControl, ICScriptHub:, EGSOS_CheckDefaultFolder, % this.Settings["CheckDefaultFolder"]
		IC_EGSOverlaySwatter_Functions.UpdateSharedSettings()
	}
	
	SaveSettings()
	{
		Global
		GuiControlGet,EGSOS_DisableOverlay, ICScriptHub:, EGSOS_DisableOverlay
		GuiControlGet,EGSOS_EGSFolderLocation, ICScriptHub:, EGSOS_EGSFolderLocation
		GuiControlGet,EGSOS_CheckDefaultFolder, ICScriptHub:, EGSOS_CheckDefaultFolder
		local sanityChecked := this.SanityCheckSettings()
		this.CheckMissingOrExtraSettings()
		
		this.Settings["DisableOverlay"] := EGSOS_DisableOverlay
		this.Settings["EGSFolder"] := EGSOS_EGSFolderLocation
		this.Settings["CheckDefaultFolder"] := EGSOS_CheckDefaultFolder
		
		g_SF.WriteObjectToJSON(IC_EGSOverlaySwatter_Functions.SettingsPath, this.Settings)
		IC_EGSOverlaySwatter_Functions.UpdateSharedSettings()
		if (!sanityChecked)
			this.UpdateMainStatus("Saved settings.")
	}
	
	SanityCheckSettings()
	{
		local sanityChecked := false
		GuiControlGet,EGSOS_DisableOverlay, ICScriptHub:, EGSOS_DisableOverlay
		GuiControlGet,EGSOS_EGSFolderLocation, ICScriptHub:, EGSOS_EGSFolderLocation
		GuiControlGet,EGSOS_CheckDefaultFolder, ICScriptHub:, EGSOS_CheckDefaultFolder
		if (EGSOS_CheckDefaultFolder AND EGSOS_EGSFolderLocation == this.DefaultSettings["EGSFolder"])
		{
			EGSOS_CheckDefaultFolder := false
			GuiControl, ICScriptHub:, EGSOS_CheckDefaultFolder, % EGSOS_CheckDefaultFolder
			this.UpdateMainStatus("Save Error. EGS Folder is default. Disabling Check Default.")
			sanityChecked := true
		}
		folderExists := IC_EGSOverlaySwatter_Functions.IsFolder(EGSOS_EGSFolderLocation)
		if (!folderExists)
		{
			EGSOS_DisableOverlay := false
			GuiControl, ICScriptHub:, EGSOS_DisableOverlay, % EGSOS_DisableOverlay
			this.UpdateMainStatus("Save Error. EGS Folder does not exist. Cannot disable.")
			sanityChecked := true
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
	
	; =====================
	; ===== GUI STUFF =====
	; =====================
	
	UpdateMainStatus(status)
	{
		GuiControlGet,EGSOS_StatusText, ICScriptHub:, EGSOS_StatusText
		EGSOS_TimerIsUp := this.GetTickCount() - this.DisplayStatusTimeout >= this.MessageStickyTimer
		if (status == "" && !EGSOS_TimerIsUp && !InStr(EGSOS_StatusText, this.DisableMessage) && !InStr(EGSOS_StatusText, this.EnableMessage))
			status := EGSOS_StatusText
		if (status != "" && EGSOS_TimerIsUp)
			this.DisplayStatusTimeout := this.GetTickCount()
		if (status == "")
			status := this.OverlayCurrentlyDisabled ? this.DisableMessage : this.EnableMessage
		GuiControl, ICScriptHub:Text, EGSOS_StatusText, % status
		Gui, Submit, NoHide
	}
	
	AddFilesToGUIList(filesRenamed)
	{
		local isTxt
		local dState
		local newV
		local restore_gui_on_return := GUIFunctions.LV_Scope("ICScriptHub", "EGSOS_OverlayFilesList")
		LV_Delete()
		for k,v in filesRenamed
		{
			dState := IC_EGSOverlaySwatter_Functions.GetSetState(InStr(v,".txt"), true) . "d"
			newV := StrReplace(v, "\\", "\")
			LV_Add(,dState,newV)
		}
		if (ObjLength(filesRenamed) > 0)
			LV_ModifyCol()
		else
			LV_ModifyCol(500)
	}
	
	; Called when briv gem farm is started
	DisableEverything()
	{
		this.UpdateMainStatus("Why have you enabled this addon? You're not on the EGS platform.")
		this.StopTimedFunctions()
		if (this.EverythingDisabled)
			return
		GuiControl, ICScriptHub:Move, EGSOS_StatusGroupBox, x15 w500
		GuiControlGet, pos, ICScriptHub:Pos, EGSOS_StatusGroupBox
		posX += 15
		GuiControl, ICScriptHub:Move, EGSOS_StatusText, x%posX% w475
		GuiControl, ICScriptHub:Hide, EGSOS_SaveSettings
		GuiControl, ICScriptHub:Hide, EGSOS_SettingsGroupBox
		GuiControl, ICScriptHub:Hide, EGSOS_DisableOverlay
		GuiControl, ICScriptHub:Hide, EGSOS_EGSFolderLocationHeader
		GuiControl, ICScriptHub:Hide, EGSOS_EGSFolderLocation
		GuiControl, ICScriptHub:Hide, EGSOS_CheckDefaultFolder
		GuiControl, ICScriptHub:Hide, EGSOS_OverlayFilesList
		GuiControl, ICScriptHub:Hide, EGSOS_OnDemandGroupBox
		GuiControl, ICScriptHub:Hide, EGSOS_EnableOverlayNow
		GuiControl, ICScriptHub:Hide, EGSOS_DisableOverlayNow
		this.EverythingDisabled := true
	}
	
	; =======================
	; ===== TIMED STUFF =====
	; =======================
	
	; Adds timed functions (typically to be started when briv gem farm is started)
	CreateTimedFunctions()
	{
		this.TimerFunctions := {}
		fncToCallOnTimer :=  ObjBindMethod(this, "UpdateEGSOverlaySwatter")
		this.TimerFunctions[fncToCallOnTimer] := 2000
	}

	; Starts the saved timed functions (typically to be started when briv gem farm is started)
	StartTimedFunctions()
	{
		if (this.PlatformID != "" && this.PlatformID != IC_EGSOverlaySwatter_Functions.EGSPlatformID)
		{
			this.DisableEverything()
			return
		}
		for k,v in this.TimerFunctions
		{
			SetTimer, %k%, %v%, 0
		}
	}

	; Stops the saved timed functions (typically to be stopped when briv gem farm is stopped)
	StopTimedFunctions()
	{
		for k,v in this.TimerFunctions
		{
			SetTimer, %k%, Off
			SetTimer, %k%, Delete
		}
		this.UpdateMainStatus("Waiting for Gem Farm to start.")
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