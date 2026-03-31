#include %A_LineFile%\..\IC_EGSOverlaySwatter_Functions.ahk
#include %A_LineFile%\..\IC_EGSOverlaySwatter_Overrides.ahk
#include *i %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk
SH_UpdateClass.AddClassFunctions(g_SharedData, IC_EGSOverlaySwatter_SharedData_Added_Class)
SH_UpdateClass.UpdateClassFunctions(g_SF, IC_EGSOverlaySwatter_SharedFunctions_Class)
SH_UpdateClass.AddClassFunctions(g_SF, IC_EGSOverlaySwatter_SharedFunctions_Added_Class)

g_SharedData.EGSOS_UpdateSettingsFromFile()
