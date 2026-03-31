#SingleInstance Ignore
#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
ListLines Off
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines, -1

#include %A_LineFile%\..\..\..\..\..\SharedFunctions\json.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_HeroDefinesLoaderWorker.ahk

global g_BGFLU_Worker := new IC_BrivGemFarm_LevelUp_HeroDefinesLoaderWorker
global g_LanguageID := A_Args[1]
global g_GUID := A_Args[2]
; Read args from file if they were incorrectly passed by ICScriptHub.
if (g_LanguageID == "" || g_GUID == "" || g_GUID == 0)
    g_BGFLU_Worker.UpdateArgsFromFile()

g_BGFLU_Worker.Start(g_LanguageID)