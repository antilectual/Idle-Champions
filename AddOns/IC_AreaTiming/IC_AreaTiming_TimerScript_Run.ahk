#SingleInstance Ignore
#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
ListLines Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1

#include %A_LineFile%\..\..\..\AddOns\IC_BrivGemFarm_Performance\IC_BrivGemFarm_Functions.ahk
#include %A_LineFile%\..\..\..\ServerCalls\IC_ServerCalls_Class.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk
#include %A_LineFile%\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\..\IC_Core\IC_SharedFunctions_Class.ahk
#include %A_LineFile%\..\IC_AreaTiming_TimerScriptWorker.ahk
#include %A_LineFile%\..\Data\IC_AreaTiming_RunCollection.ahk
#include %A_LineFile%\..\Data\IC_AreaTiming_SharedData.ahk

global g_UserSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\..\..\Settings.json" )
global g_AT_SharedData := new IC_AreaTiming_SharedData
global g_AreaTimingWorker := new IC_AreaTiming_TimerScriptWorker
; Register COM object
global g_GUID := A_Args[1]
if (g_GUID == "" || g_GUID == 0)
{
    miniscriptsLoc := A_LineFile . "\..\..\..\AddOns\IC_BrivGemFarm_Performance\LastGUID_Miniscripts.json"
    miniscripts := g_SF.LoadObjectFromJSON(miniscriptsLoc)
    ; Delete previous GUID
    for k, v in miniscripts
    {
        if (InStr(v, "IC_AreaTiming_TimerScript_Run.ahk"))
            miniscripts.Delete(k)
    }
    ; Create unique identifier (GUID) for the addon to be used by Script Hub.
    g_GUID := ComObjCreate("Scriptlet.TypeLib").Guid
    miniscripts[g_GUID] := A_ScriptFullPath
    g_SF.WriteObjectToJSON(miniscriptsLoc, miniscripts)
}
ObjRegisterActive(g_AT_SharedData, g_GUID)
OnExit(ObjBindMethod(g_AreaTimingWorker, "ComObjectRevoke"))

g_AT_SharedData.Start()