#include %A_LineFile%\..\IC_RNGWaitingRoom_Functions.ahk
#include %A_LineFile%\..\IC_RNGWaitingRoom_Overrides.ahk
#include *i %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk

SH_UpdateClass.UpdateClassFunctions(g_BrivGemFarm, IC_RNGWaitingRoom_Class)
SH_UpdateClass.UpdateClassFunctions(g_SF, IC_RNGWaitingRoom_SharedFunctions_Class)
SH_UpdateClass.AddClassFunctions(g_SF, IC_RNGWaitingRoom_SharedFunctions_Added_Class)
SH_UpdateClass.AddClassFunctions(g_SharedData, IC_RNGWaitingRoom_IC_SharedData_Added_Class)

g_SharedData.RNGWR_Init()