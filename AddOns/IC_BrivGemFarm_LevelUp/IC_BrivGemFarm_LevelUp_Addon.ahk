#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_Overrides.ahk
#include *i %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk
SH_UpdateClass.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_LevelUp_Class)
SH_UpdateClass.UpdateClassFunctions(g_SF, IC_BrivGemFarm_LevelUp_SharedFunctions_Class)
SH_UpdateClass.AddClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_LevelUp_Added_Class)
SH_UpdateClass.AddClassFunctions(g_SF, IC_BrivGemFarm_LevelUp_SharedFunctions_Added_Class)
SH_UpdateClass.AddClassFunctions(g_SF.Memory, IC_BrivGemFarm_LevelUp_IC_MemoryFunctions_Added_Class)
SH_UpdateClass.AddClassFunctions(g_SharedData, IC_BrivGemFarm_LevelUp_IC_SharedData_Added_Class)
g_BrivGemFarm["SetupFailedConversionDone"] := True