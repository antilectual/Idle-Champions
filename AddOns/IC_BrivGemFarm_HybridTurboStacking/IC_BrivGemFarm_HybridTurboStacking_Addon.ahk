#include %A_LineFile%\..\IC_BrivGemFarm_HybridTurboStacking_Functions.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_HybridTurboStacking_Overrides.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk

; Update Base Class
SH_UpdateClass.UpdateClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_HybridTurboStacking_Class)
SH_UpdateClass.AddClassFunctions(g_BrivGemFarm, IC_BrivGemFarm_HybridTurboStacking_Added_Class)
SH_UpdateClass.UpdateClassFunctions(g_SF.Memory, IC_BrivGemFarm_HybridTurboStacking_IC_MemoryFunctions_Class)
; Add functions
SH_UpdateClass.AddClassFunctions(g_SharedData, IC_BrivGemFarm_HybridTurboStacking_IC_SharedData_Added_Class)
; Addon Startup 
g_SharedData.BGFHTS_Init()