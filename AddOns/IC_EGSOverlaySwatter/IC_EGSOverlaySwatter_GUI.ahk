GUIFunctions.AddTab("EGS Overlay Swatter")

Gui, ICScriptHub:Tab, EGS Overlay Swatter
GUIFunctions.UseThemeTextColor("DefaultTextColor", 700)
Gui, ICScriptHub:Add, GroupBox, Section x125 y+0 w390 h39 vEGSOS_StatusGroupBox, Status
Gui, ICScriptHub:Font, w400
GUIFunctions.UseThemeTextColor("HeaderTextColor")
Gui, ICScriptHub:Add, Text, xs12 ys16 w366 vEGSOS_StatusText, % IC_EGSOverlaySwatter_GUI.WaitingMessage
GUIFunctions.UseThemeTextColor("DefaultTextColor")

EGSOS_SaveSettings()
{
	global
	g_EGSOverlaySwatter.SaveSettings()
}

EGSOS_DisableOverlayNow()
{
	global
	g_EGSOverlaySwatter.ToggleOverlayNow(true)
}

EGSOS_EnableOverlayNow()
{
	global
	g_EGSOverlaySwatter.ToggleOverlayNow(false)
}

class IC_EGSOverlaySwatter_GUI
{
	static WaitingMessage := "Waiting for Gem Farm to start."
	static UnableConnectMessage := "Unable to connect to the gem farm script."

	Init()
	{
		global
		this.BuildGUI()
		this.CreateTooltips()
	}

	BuildGUI()
	{
		global
		Gui, ICScriptHub:Add, Button, xs-106 ys10 w100 h25 vEGSOS_SaveSettings gEGSOS_SaveSettings, `Save Settings
		
		GuiControlGet, pos, ICScriptHub:Pos, EGSOS_StatusText
		lineHeight := posH
		firstLineY := 20
		col1x := 15
		infoGap := 5
		
		EGSOS_col1w := 180
		EGSOS_col2w := 70
		EGSOS_col3w := 180
		EGSOS_col2x := 205
		EGSOS_col3x := 290
		EGSOS_ypos := 13
		EGSOS_xpos := 15
		
		Gui, ICScriptHub:Font, w700
		gboxhSettings := 25 + firstLineY + (infoGap * 3) + (lineHeight * 6)
		Gui, ICScriptHub:Add, GroupBox, Section x%col1x% y+10 w500 h%gboxhSettings% vEGSOS_SettingsGroupBox, Settings
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Checkbox, xs%col1x% ys%firstLineY% vEGSOS_DisableOverlay, Disable EGS Overlay?
		Gui, ICScriptHub:Add, Text, xs%col1x% y+%infoGap% w200 vEGSOS_EGSFolderLocationHeader, EGS Install Folder:
		GUIFunctions.UseThemeTextColor("InputBoxTextColor")
		Gui, ICScriptHub:Add, Edit, xs%col1x% y+%infoGap% w450 r3 vEGSOS_EGSFolderLocation, 
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		Gui, ICScriptHub:Add, Checkbox, xs25 y+%infoGap% vEGSOS_CheckDefaultFolder, Also Check Default Folder?  (C:\Program Files (x86)\Epic Games)
		
		GUIFunctions.UseThemeTextColor("TableTextColor")
		gboxhSettings += 5
		Gui, ICScriptHub:Add, ListView, x%col1x% ys+%gboxhSettings% w500 r5 vEGSOS_OverlayFilesList, State|Overlay Files
		GUIFunctions.UseThemeListViewBackgroundColor("g_EGSOS_OverlayFilesList")
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		
		Gui, ICScriptHub:Font, w700
		gboxhOnDemand := 52
		Gui, ICScriptHub:Add, GroupBox, Section x%col1x% y+0 w500 h%gboxhOnDemand% vEGSOS_OnDemandGroupBox,
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Button, xs15 ys17 w150 vEGSOS_EnableOverlayNow gEGSOS_EnableOverlayNow, `Enable Overlay Now
		Gui, ICScriptHub:Add, Button, x+10 ys17 w150 vEGSOS_DisableOverlayNow gEGSOS_DisableOverlayNow, `Disable Overlay Now
	}
	
	CreateTooltips()
	{
		; GUIFunctions.AddToolTip("EGSOS_TargetFramerateH", "Settings -> Graphics -> Target Framerate:`nThis sets the upper-limit for FPS for the game.")
	}
	
}