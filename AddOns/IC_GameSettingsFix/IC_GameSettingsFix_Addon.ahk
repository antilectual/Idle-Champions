#include %A_LineFile%\..\IC_GameSettingsFix_Functions.ahk
#include %A_LineFile%\..\IC_GameSettingsFix_Overrides.ahk
#include *i %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk
SH_UpdateClass.UpdateClassFunctions(g_SF, IC_GameSettingsFix_SharedFunctions_Class)
SH_UpdateClass.AddClassFunctions(g_SF, IC_GameSettingsFix_SharedFunctions_Added_Class)
SH_UpdateClass.AddClassFunctions(g_SharedData, IC_GameSettingsFix_SharedData_Added_Class)
g_SharedData["GSF_HotkeyRequiredReplacements"] := {}
g_SharedData.GSF_UpdateSettingsFromFile()