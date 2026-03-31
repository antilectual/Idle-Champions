; Functions that set affinities to processes
class IC_ProcessAffinity_Functions
{
    static SettingsPath := A_LineFile . "\..\ProcessAffinitySettings.json"
    static Affinity := 0
    static ProcessorCount := 0
    static ScriptPID := 0

    ; Adds IC_ProcessAffinity_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_ProcessAffinity_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    ; Set affinity after clicking "Start Gem Farm"
    Init(isSH := false) ; 0:IC_BrivGemFarm_Run.ahk, 1:ICScriptHub.ahk
    {
        EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
        this.ProcessorCount := ProcessorCount
        this.Affinity := affinity := this.LoadAffinitySettings(isSH)
        this.ScriptPID := DllCall("GetCurrentProcessId")
        this.UpdateAffinities(affinity, isSH)
    }

    ; Loads settings from the addon's setting.json file.
    LoadAffinitySettings(isSH := false)
    {
        if (!IsObject(settings := g_SF.LoadObjectFromJSON(this.SettingsPath)) AND !isSH)
            return 0
        if ((coreMask := settings["ProcessAffinityMask"]) == "")
        {
            coreMask := 0
            Loop, % this.ProcessorCount ; Sum up all bits
                coreMask += 2 ** (A_Index - 1)
        }
        return coreMask
    }

    ; Update affinites after saving
    UpdateAffinities(affinity := 0, isSH := false)
    {
        this.Affinity := affinity
        this.SetProcessAffinity(this.ScriptPID, 1) ; IC_BrivGemFarm_Run.ahk / ICScriptHub.ahk
        if (isSH)
        {
            ; Set affinity if the game process exists
            existingProcessID := g_UserSettings[ "ExeName"]
            Process, Exist, %existingProcessID%
            gamePID := ErrorLevel
            this.SetProcessAffinity(gamePID) ; IdleDragons.exe
        }
    }

    /*  SetProcessAffinity - A function to sets the affinity of a process

        Parameters:
            PID - PID of the target process
            inverse - Inverse affinity, if e.g. core 0 is selected for the game, core 0 is unselected for the scripts
        Returns:
    */
    SetProcessAffinity(PID := 0, inverse := 0)
    {
        if (PID == 0 OR (affinity := this.Affinity) == 0)
            return
        affinity := inverse ? this.InverseAffinity(affinity) : affinity
        ProcessHandle := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", False, "UInt", PID)
        size := A_Is64bitOS ? "Int64" : "UInt"
        DllCall("SetProcessAffinityMask", "UInt", ProcessHandle, size, affinity)
        DllCall("CloseHandle", "UInt", ProcessHandle)
    }

    ; Returns the inverse affinity depending on the number of processor cores
    InverseAffinity(affinity := 0)
    {
        EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
        ; -1 >>> (64 - ProcessorCount) only in AHK 1.1.35.00+
        invMask := ProcessorCount == 64 ? -1 : 0x7FFFFFFFFFFFFFFF >> (63 - ProcessorCount)
        invAffinity := affinity ^ invMask
        invAffinity := !invAffinity ? affinity : invAffinity ; If all cores are selected for IdleDragons.exe, identical mask
        return invAffinity
    }
}

; Overrides IC_SharedFunctions_Class.OpenProcessAndSetPID()
; Overrides IC_SharedFunctions_Class.VerifyAdventureLoaded()
class IC_ProcessAffinity_SharedFunctions_Class extends IC_SharedFunctions_Class
{
    ; Set affinity after restart ; (Added but uses base - needs extends)
    OpenProcessAndSetPID(timeoutLeft := 32000)
    {
        base.OpenProcessAndSetPID(timeoutLeft)
        IC_ProcessAffinity_Functions.SetProcessAffinity(this.PID) ; IdleDragons.exe
    }

    ; Set affinity after clicking "Start Gem Farm"
    VerifyAdventureLoaded()
    {
        IC_ProcessAffinity_Functions.SetProcessAffinity(this.PID) ; IdleDragons.exe
        return base.VerifyAdventureLoaded()
    }
}

class IC_ProcessAffinity_SharedData_Added_Class ; Added to IC_SharedData_Class
{
    ; Save new affinity
    ProcessAffinity_UpdateAffinity(affinity := 0)
    {
        IC_ProcessAffinity_Functions.UpdateAffinities(affinity)
    }

    ; Return true if the class has been updated by the addon
    ProcessAffinityRunning()
    {
        return true
    }
}