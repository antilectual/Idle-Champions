class IC_ClaimDailyPlatinum_Functions
{
	static SettingsPath := A_LineFile . "\..\ClaimDailyPlatinum_Settings.json"

	TickFrequency := -1

	InjectAddon()
	{
		local splitStr := StrSplit(A_LineFile, "\")
		local addonDirLoc := splitStr[(splitStr.Count()-1)]
		local addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_ClaimDailyPlatinum_Addon.ahk`n"
		FileAppend, %addonLoc%, %g_BrivFarmModLoc%
		local addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_ClaimDailyPlatinum_Servercalls.ahk`n"
		FileAppend, %addonLoc%, %g_BrivFarmServerCallModLoc%
	}

	; ======================
	; ===== MAIN STUFF =====
	; ======================
	
	IsGameClosed()
	{
		if(g_SF.Memory.ReadCurrentZone() == "" && Not WinExist( "ahk_exe " . g_userSettings[ "ExeName"] ))
			return true
		return false
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