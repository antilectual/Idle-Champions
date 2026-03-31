GUIFunctions.AddTab("Game Settings Fix")

Gui, ICScriptHub:Tab, Game Settings Fix
GUIFunctions.UseThemeTextColor("DefaultTextColor", 700)
Gui, ICScriptHub:Add, GroupBox, Section x125 y+0 w390 h39, Status
Gui, ICScriptHub:Font, w400
GUIFunctions.UseThemeTextColor("HeaderTextColor")
Gui, ICScriptHub:Add, Text, xs12 ys16 w366 vGSF_StatusText, % IC_GameSettingsFix_GUI.WaitingMessage
GUIFunctions.UseThemeTextColor("DefaultTextColor")

GSF_SaveSettings()
{
	global
	g_GameSettingsFix.SaveSettings()
}

GSF_SaveProfile()
{
	global
	g_GameSettingsFix.SaveProfile()
}

GSF_LoadProfile()
{
	global
	g_GameSettingsFix.LoadProfile()
}

GSF_DeleteProfile()
{
	global
	g_GameSettingsFix.DeleteProfile()
}

class IC_GameSettingsFix_GUI
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
		Gui, ICScriptHub:Add, Button, xs-106 ys10 w100 h25 vGSF_SaveSettings gGSF_SaveSettings, `Save Settings
		
		GSF_col1w := 180
		GSF_col2w := 70
		GSF_col3w := 180
		GSF_col1x := 15
		GSF_col2x := 205
		GSF_col3x := 290
		GSF_ypos := 13
		GSF_xpos := 15

		Gui, ICScriptHub:Font, w700
		GSF_gboxhProfiles := 43
		Gui, ICScriptHub:Add, GroupBox, Section x15 ys+39 w500 h%GSF_gboxhProfiles%, Profiles
		Gui, ICScriptHub:Font, w400
		Gui, ICScriptHub:Add, Text, xs%GSF_xpos% ys18 w38 +Right, Profiles:
		GSF_xpos += 48
		Gui, ICScriptHub:Add, DDL, xs%GSF_xpos% ys14 w159 vGSF_Profiles, 
		GSF_xpos += 165
		Gui, ICScriptHub:Add, Button, xs%GSF_xpos% ys13 w85 h23 vGSF_SaveProfile gGSF_SaveProfile, `Save Profile
		GSF_xpos += 90
		Gui, ICScriptHub:Add, Button, xs%GSF_xpos% ys13 w85 h23 vGSF_LoadProfile gGSF_LoadProfile, `Load Profile
		GSF_xpos += 90
		Gui, ICScriptHub:Add, Button, xs%GSF_xpos% ys13 w85 h23 vGSF_DeleteProfile gGSF_DeleteProfile, `Delete Profile

		Gui, ICScriptHub:Font, w700
		GSF_gboxhSettings := 38 + (11 * 25)
		Gui, ICScriptHub:Add, GroupBox, Section x15 ys+%GSF_gboxhProfiles% w500 h%GSF_gboxhSettings%, Settings
		GSF_SettingX := GSF_col1x + 60
		GSF_SettingW := GSF_col1w - 60
		Gui, ICScriptHub:Add, Text, xs%GSF_SettingX% ys%GSF_ypos% w%GSF_SettingW% +Right, Setting
		Gui, ICScriptHub:Add, Text, xs%GSF_col2x% ys%GSF_ypos% w%GSF_col2w%, Value
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% ys%GSF_ypos% w%GSF_col3w%, Recommended
		Gui, ICScriptHub:Font, w400
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_TargetFramerateH, TargetFramerate:
		GUIFunctions.UseThemeTextColor("InputBoxTextColor")
		Gui, ICScriptHub:Add, Edit, xs%GSF_col2x% y+-17 w%GSF_col2w% +Right vGSF_TargetFramerate, 600
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-17 w%GSF_col3w%, 600 (Maybe more - maybe less)
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_PercentOfParticlesSpawnedH, PercentOfParticlesSpawned:
		GUIFunctions.UseThemeTextColor("InputBoxTextColor")
		Gui, ICScriptHub:Add, Edit, xs%GSF_col2x% y+-17 w%GSF_col2w% +Right vGSF_PercentOfParticlesSpawned, 0
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-17 w%GSF_col3w%, 0
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_resolution_xH, resolution_x:
		GUIFunctions.UseThemeTextColor("InputBoxTextColor")
		Gui, ICScriptHub:Add, Edit, xs%GSF_col2x% y+-17 w%GSF_col2w% +Right vGSF_resolution_x, 0
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-17 w%GSF_col3w%, Personal Preference
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_resolution_yH, resolution_y:
		GUIFunctions.UseThemeTextColor("InputBoxTextColor")
		Gui, ICScriptHub:Add, Edit, xs%GSF_col2x% y+-17 w%GSF_col2w% +Right vGSF_resolution_y, 0
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-17 w%GSF_col3w%, Personal Preference
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_resolution_fullscreenH, resolution_fullscreen:
		Gui, ICScriptHub:Add, Checkbox, xs%GSF_col2x% y+-13 vGSF_resolution_fullscreen,
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-13 w%GSF_col3w%, Personal Preference
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_ReduceFramerateWhenNotInFocusH, ReduceFramerateWhenNotInFocus:
		Gui, ICScriptHub:Add, Checkbox, xs%GSF_col2x% y+-13 vGSF_ReduceFramerateWhenNotInFocus,
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-13 w%GSF_col3w%, Unchecked
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_FormationSaveIncludeFeatsCheckH, FormationSaveIncludeFeatsCheck:
		Gui, ICScriptHub:Add, Checkbox, xs%GSF_col2x% y+-13 vGSF_FormationSaveIncludeFeatsCheck,
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-13 w%GSF_col3w%, Unchecked
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_LevelupAmountIndexH, LevelupAmountIndex:
		Gui, ICScriptHub:Add, DDL, xs%GSF_col2x% y+-17 w%GSF_col2w% vGSF_LevelupAmountIndex, x1|x10|x25|x100|Next Upg||
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-17 w%GSF_col3w%, x100
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_UseConsolePortraitsH, UseConsolePortraits:
		Gui, ICScriptHub:Add, Checkbox, xs%GSF_col2x% y+-13 vGSF_UseConsolePortraits,
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-13 w%GSF_col3w%, Personal Preference
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_NarrowHeroBoxesH, NarrowHeroBoxes:
		Gui, ICScriptHub:Add, Checkbox, xs%GSF_col2x% y+-13 vGSF_NarrowHeroBoxes Disabled,
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-13 w%GSF_col3w%, `Mandatory
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_ShowAllHeroBoxesH, ShowAllHeroBoxes:
		Gui, ICScriptHub:Add, Checkbox, xs%GSF_col2x% y+-13 vGSF_ShowAllHeroBoxes,
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-13 w%GSF_col3w%, Personal Preference
		
		Gui, ICScriptHub:Font, w700
		GSF_gboxhHotkeys := 25 + (2 * 25) - 7
		Gui, ICScriptHub:Add, GroupBox, Section x15 ys+%GSF_gboxhSettings% w500 h%GSF_gboxhHotkeys%, Hotkeys
		Gui, ICScriptHub:Font, w400
		GSF_ypos := 18
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_HKsRequiredH, Fix Script Required Hotkeys:
		Gui, ICScriptHub:Add, Checkbox, xs%GSF_col2x% y+-13 vGSF_HKsRequired Disabled,
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-13 w%GSF_col3w%, Mandatory
		GSF_ypos += 25
		Gui, ICScriptHub:Add, Text, xs%GSF_col1x% ys%GSF_ypos% w%GSF_col1w% +Right vGSF_HKsSwap25100H, Swap x25 and x100 Mode Hotkeys:
		Gui, ICScriptHub:Add, Checkbox, xs%GSF_col2x% y+-13 vGSF_HKsSwap25100,
		Gui, ICScriptHub:Add, Text, xs%GSF_col3x% y+-13 w%GSF_col3w%, Required for x25 Hotkey Levelling

		Gui, ICScriptHub:Font, w700
		GUIFunctions.UseThemeTextColor("TableTextColor")
		GSF_gboxhHotkeys += 6
		Gui, ICScriptHub:Add, ListView, Section x15 ys+%GSF_gboxhHotkeys% w499 r2 vGSF_SettingsFileLocation, Settings File Location
		GUIFunctions.UseThemeListViewBackgroundColor("GSF_SettingsFileLocation")
		GuiControlGet, pos, ICScriptHub:Pos, GSF_SettingsFileLocation
		GSF_gboxhSettingsLoc := posH
		GUIFunctions.UseThemeTextColor("DefaultTextColor")
	}
	
	CreateTooltips()
	{
		GUIFunctions.AddToolTip("GSF_TargetFramerateH", "Settings -> Graphics -> Target Framerate:`nThis sets the upper-limit for FPS for the game.")
		GUIFunctions.AddToolTip("GSF_PercentOfParticlesSpawnedH", "Settings -> Graphics -> Particle Amount:`nThe graphics for some abilities can create other little graphical effects`ncalled particles. This sets the proportion of them that can be created.")
		GUIFunctions.AddToolTip("GSF_resolution_xH", "Settings -> Display -> Resolution:`nThe width of your game window in pixels.")
		GUIFunctions.AddToolTip("GSF_resolution_yH", "Settings -> Display -> Resolution:`nThe height of your game window in pixels.")
		GUIFunctions.AddToolTip("GSF_resolution_fullscreenH", "Settings -> Display -> Fullscreen:`nDetermines whether the game covers the entire screen or not.")
		GUIFunctions.AddToolTip("GSF_ReduceFramerateWhenNotInFocusH", "Settings -> Graphics -> Reduce framerate when in background:`nThis will limit the fps of the game (and therefore slow it down) while`nit's hidden behind other windows.")
		GUIFunctions.AddToolTip("GSF_FormationSaveIncludeFeatsCheckH", "Formation Manager -> Include currently equipped Feats with save:`nDetermines whether a formation save will have feats included or not`nwhen saved.")
		GUIFunctions.AddToolTip("GSF_LevelupAmountIndexH", "Level Up Button (Left of BUD/Ultimate bar):`nDetermines how champions are levelled up.")
		GUIFunctions.AddToolTip("GSF_UseConsolePortraitsH", "Settings -> Interface -> Console UI Portraits:`nDetermines whether the portraits for the champions on the bench are the`ncreepy ones that stare into your soul or not.")
		GUIFunctions.AddToolTip("GSF_NarrowHeroBoxesH", "Settings -> Interface -> Narrow Bench Boxes:`nDetermines whether you can see all champions on the bench on low`nresolutions or not.")
		GUIFunctions.AddToolTip("GSF_ShowAllHeroBoxesH", "Settings -> Interface -> Show All Bench Seats:`nDetermines whether you can see all champions on the bench even`nif you can't afford to unlock them yet.")
		GUIFunctions.AddToolTip("GSF_HKsRequiredH", "This will fix any hotkeys required by the script to function.`n  load_formation_1: Q`n  load_formation_2: W`n  load_formation_3: E`n  go_to_previous_area: LeftArrow`n  go_to_next_area: RightArrow`n  toggle_auto_progress: G")
		GUIFunctions.AddToolTip("GSF_HKsSwap25100H", "This will swap the keybindings of x25 level up mode and x100 level`nup mode. It also resets x10 level up mode to default.`n  hero_level_10: LeftShift (Default: LeftShift)`n  hero_level_25: LeftControl (Default: LeftShift + LeftControl)`n  hero_level_100: LeftShift + LeftControl (Default: LeftControl)")
	}
	
}