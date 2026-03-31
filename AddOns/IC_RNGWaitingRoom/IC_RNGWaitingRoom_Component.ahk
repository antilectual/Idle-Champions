; Test to see if BrivGemFarm addon is available.
if(IsObject(IC_BrivGemFarm_Component))
{
    IC_RNGWaitingRoom_Functions.InjectAddon()
    global g_RNGWaitingRoom := new IC_RNGWaitingRoom_Component
    global g_RNGWaitingRoomGui := new IC_RNGWaitingRoom_GUI
    g_RNGWaitingRoom.Init()
}

/*  IC_RNGWaitingRoom_Component

    Class that manages the GUI for RNG Waiting Room.
    Starts automatically on script launch and waits for Briv Gem Farm to be started,
    then stops/starts every time buttons on the main Briv Gem Farm window are clicked.
*/
Class IC_RNGWaitingRoom_Component
{
    Settings := ""
    TimerFunction := ObjBindMethod(this, "UpdateStatus")
    SingleRedrawActive := false
    SingleEllywickHandler := ""

    Init()
    {
        g_RNGWaitingRoomGui.Init()
        ; Read settings
        this.LoadSettings()
        this.CompareActiveEffectHandlerVersion()
        ; Update loop
        this.Start()
    }

    Functions
    {
        get
        {
            return IC_RNGWaitingRoom_Functions
        }
    }

    ; Load saved or default settings.
    LoadSettings()
    {
        needSave := false
        default := this.GetDefaultSettings()
        this.Settings := settings := g_SF.LoadObjectFromJSON(this.Functions.SettingsPath)
        if (!IsObject(settings))
            needSave := true, (this.Settings := settings := default)
        else
        {
            postDelSettings := g_SF.DeleteExtraSettings(settings, default)
            needSave := (postDelSettings != "")
            if (needSave)
                settings := postDelSettings
        }
        if (needSave)
            this.SaveSettings()
        ; Set the state of GUI buttons with saved settings.
        g_RNGWaitingRoomGui.UpdateGUISettings(settings)
    }

    ; Returns an object with default values for all settings.
    GetDefaultSettings()
    {
        settings := {}
        settings.EllywickGFEnabled := true
        settings.EllywickGFGemCards := 1
        settings.EllywickGFGemMaxRedraws := 1
        settings.EllywickGFGemWaitFor5Draws := true
        return settings
    }

    UpdateSetting(setting, value)
    {
        this.Settings[setting] := value
    }

    ; Save settings.
    SaveSettings()
    {
        settings := this.Settings
        g_SF.WriteObjectToJSON(IC_RNGWaitingRoom_Functions.SettingsPath, settings)
        GuiControl, ICScriptHub:Text, RNGWR_StatusText, Settings saved
        ; Apply settings to BrivGemFarm
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.RNGWR_UpdateSettingsFromFile()
        }
        catch
        {
            GuiControl, ICScriptHub:Text, RNGWR_StatusText, Waiting for Gem Farm to start
        }
    }

    Start()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, 500, 0
    }

    Stop()
    {
        fncToCallOnTimer := this.TimerFunction
        SetTimer, %fncToCallOnTimer%, Off
    }

    ; GUI update loop.
    UpdateStatus()
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            if (SharedRunData.RNGWR_Running == "")
                this.Stop()
            else if (SharedRunData.RNGWR_Running AND SharedRunData.RNGWR_GemFarmEnabled)
            {
                    status := SharedRunData.RNGWR_Status
                    str := "Running" . (status != "" ? " - " . status : "")
                    GuiControl, ICScriptHub:Text, RNGWR_StatusText, % str
                    stats := SharedRunData.RNGWR_GetStats()
                    g_RNGWaitingRoomGui.UpdateGUI(stats)
                    return
            }
            else
                GuiControl, ICScriptHub:Text, RNGWR_StatusText, Disabled
        }
        catch
        {
            GuiControl, ICScriptHub:Text, RNGWR_StatusText, Waiting for Gem Farm to start
        }
    }

    ResetStats()
    {
        try ; avoid thrown errors when comobject is not available.
        {
            SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.RNGWR_ResetStats()
        }
    }

    CompareActiveEffectHandlerVersion()
    {
        if(isFunc(IC_ActiveEffectKeyHandler_Class.GetVersion))
        {
            RegExMatch(IC_ActiveEffectKeyHandler_Class.GetVersion(), "v\d+.\d+.\d+", version)
            required := this.RequiredVersion()
            if (SH_VersionHelper.IsVersionNewer(this.RequiredVersion(), version))
                MsgBox, % "RNG Waiting Room addon requires ICScriptHub's EffectKeyHandler Memory " . required . "+."
        }
    }

    RequiredVersion()
    {
        return "v2.5.0"
    }

    StartSingle()
    {
        this.SingleRedrawActive := true
        cards := this.GetSingleCardsArray()
        this.SingleEllywickHandler := new IC_RNGWaitingRoom_Functions.EllywickHandlerHandlerSingle(cards)
        this.SingleEllywickHandler.Start()
    }

    StopSingle()
    {
        this.SingleEllywickHandler.Stop()
        this.SingleEllywickHandler := ""
        this.SingleRedrawActive := false
    }

    GetSingleCardsArray()
    {
        array := []
        Loop, 5
        {
            GuiControlGet, value, ICScriptHub:, RNGWR_EllywickSingle%A_Index%
            array.Push(value)
        }
        return array
    }
}