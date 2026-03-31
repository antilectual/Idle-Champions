#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Overrides.ahk
#include *i %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk
SH_UpdateClass.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_BrivFeatSwap_Class)
SH_UpdateClass.UpdateClassFunctions(g_SF, IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Class)
SH_UpdateClass.AddClassFunctions(g_SF, IC_BrivGemFarm_BrivFeatSwap_SharedFunctions_Added_Class)
SH_UpdateClass.AddClassFunctions(g_SharedData, IC_BrivGemFarm_BrivFeatSwap_IC_SharedData_Added_Class)
g_SharedData.BGFBFS_Init()