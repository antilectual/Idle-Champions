#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_HeroDefinesLoaderConstants.ahk

global g_BGFLU_HDL_Constants := IC_BrivGemFarm_LevelUp_HeroDefinesLoaderConstants

; Functions used to load hero definitions into the GUI.
class IC_BrivGemFarm_LevelUp_HeroDefinesLoader
{
    CurrentState := 0
    GUID := ""
    HeroDefines := ""
    TimerFunction := ObjBindMethod(this, "WaitForDefs")

    Start()
    {
        state := this.CurrentState
        if (state > g_BGFLU_HDL_Constants.STOPPED && state < g_BGFLU_HDL_Constants.HERO_DATA_FINISHED)
            return
        ; Check if worker script exists
        scriptLocation := g_BGFLU_HDL_Constants.WorkerPath
        if (!FileExist(scriptLocation))
        {
            state := g_BGFLU_HDL_Constants.LOADER_FILE_MISSING
            g_BrivGemFarm_LevelUpGui.MoveProgressBar(state)
            return g_BrivGemFarm_LevelUpGui.UpdateLoadingText(state)
        }
        this.GUID := guid := ComObjCreate("Scriptlet.TypeLib").Guid
        ObjRegisterActive(this, guid)
        OnExit(ObjBindMethod(this, "ComObjectRevoke"))
        languageID := g_BrivGemFarm_LevelUp.GetSetting("DefinitionsLanguage")
        ; Save args passed to the script to a file
        loaderSettings := g_SF.LoadObjectFromJSON(g_BGFLU_HDL_Constants.LastGUIDPath)
        if (!IsObject(loaderSettings))
            loaderSettings := {}
        loaderSettings.GUID := guid
        loaderSettings.LanguageID := languageID
        g_SF.WriteObjectToJSON(g_BGFLU_HDL_Constants.LastGUIDPath, loaderSettings)
        ; Start worker
        Run, %scriptLocation% %languageID% %guid%
        ; Update loop
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, 50, 0
        this.CurrentState := g_BGFLU_HDL_Constants.GET_PLAYSERVER
    }

    Stop()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, Off
        this.UnregisterComObject()
        this.CurrentState := g_BGFLU_HDL_Constants.STOPPED
    }

    ; Unregister the shared data object.
    UnregisterComObject()
    {
        ObjRegisterActive(this, "")
    }

    ; Unregister the shared data object on exit.
    ComObjectRevoke()
    {
        this.UnregisterComObject()
        ExitApp
    }

    ; Update loop while IC_BrivGemFarm_LevelUp_HeroDefinesLoader_Run is busy.
    WaitForDefs()
    {
        state := this.CurrentState
        g_BrivGemFarm_LevelUpGui.MoveProgressBar(state)
        g_BrivGemFarm_LevelUpGui.UpdateLoadingText(state)
        if (state >= g_BGFLU_HDL_Constants.HERO_DATA_FINISHED)
        {
            this.Stop()
            if (state == g_BGFLU_HDL_Constants.HERO_DATA_FINISHED)
                this.LoadDefinitions()
            else
                IC_BrivGemFarm_LevelUp_Seat.OnHeroDefinesFinished(state < g_BGFLU_HDL_Constants.SERVER_TIMEOUT)
        }
    }

    ; Called by IC_BrivGemFarm_LevelUp_HeroDefinesLoader_Run.
    UpdateState(state)
    {
        this.CurrentState := state
        return true
    }

    ; Load definitions from file.
    ; The server timestamp is shown as a tooltip.
    ; LoadObjectFromJSON() is memory intensive and needs cleanup afterwards.
    LoadDefinitions()
    {
        defs := g_SF.LoadObjectFromJSON(g_BGFLU_HDL_Constants.HeroDefsPath)
        if (defs)
        {
            this.HeroDefines := defs
            g_HeroDefines.Init(defs)
            IC_BrivGemFarm_LevelUp_ToolTip.UpdateDefsCNETime(this.HeroDefines.current_time)
            IC_BrivGemFarm_LevelUp_Seat.OnHeroDefinesFinished()
            ; Clear memory bloat
            g_SF.EmptyMem()
        }
        else
            IC_BrivGemFarm_LevelUp_Seat.OnHeroDefinesFinished(false)
    }
}