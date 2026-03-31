#include %A_LineFile%\..\IC_ProcessAffinity_Functions.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\SH_UpdateClass.ahk

SH_UpdateClass.UpdateClassFunctions(g_SF, IC_ProcessAffinity_SharedFunctions_Class)
SH_UpdateClass.UpdateClassFunctions(g_SharedData, IC_ProcessAffinity_SharedData_Class)
SH_UpdateClass.AddClassFunctions(g_SharedData, IC_ProcessAffinity_SharedData_Added_Class)
IC_ProcessAffinity_Functions.Init()