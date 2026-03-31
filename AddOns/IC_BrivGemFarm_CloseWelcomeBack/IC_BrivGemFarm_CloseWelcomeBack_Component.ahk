#include %A_LineFile%\..\IC_BrivGemFarm_CloseWelcomeBack_TimerScript.ahk

; timer script on start
g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(IC_BrivGemFarm_CloseWelcomeBack_TimerScript, "CreateTimedFunctions"))
g_BrivFarmAddonStartFunctions.Push(ObjBindMethod(IC_BrivGemFarm_CloseWelcomeBack_TimerScript, "StartTimedFunctions"))
; timer script on stop
g_BrivFarmAddonStopFunctions.Push(ObjBindMethod(IC_BrivGemFarm_CloseWelcomeBack_TimerScript, "StopTimedFunctions"))
