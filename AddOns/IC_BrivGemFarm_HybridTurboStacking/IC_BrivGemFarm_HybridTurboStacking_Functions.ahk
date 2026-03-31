#include %A_LineFile%\..\RNG\IC_BrivGemFarm_HybridTurboStacking_Melf.ahk

; Functions that are used by this Addon.
class IC_BrivGemFarm_HybridTurboStacking_Functions
{
    static FARIDEH_ID := 33
    static WARDEN_ID := 36
    static BRIV_ID := 58
    static MELF_ID := 59
    static TATYANA_ID := 97
    static BrivJumpSlot := 4
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_HybridTurboStacking_Settings.json"

    ; Adds IC_BrivGemFarm_HybridTurboStacking_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_HybridTurboStacking_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    ConvertBitfieldToArray(value)
    {
        array := []
        Loop, 50
            array.Push((value & (2 ** (A_Index - 1))) != 0)
        return array
    }

    GetPreferredBrivStackZones(value)
    {
        array := this.ConvertBitfieldToArray(value)
        ; Disable stacking in a boss zone.
        Loop, 10
            array[5 * A_Index] := 0
        return array
    }

    ; Conditional stack formation
    SetRemovedIdsFromWFavorite(ids := "")
    {
        g_SharedData.BGFHTS_RemovedIdsFromWFavorite := ids
    }

    ; Heal
    ReadHealthPercent(champID := 58)
    {
        if (champID < 1)
            return ""
        obj := g_SF.Memory.GameManager.game.gameInstances[g_SF.Memory.GameInstance].Controller.userData.HeroHandler.heroes[g_SF.Memory.GetHeroHandlerIndexByChampID(champID)].health.QuickClone()
        ; lastHealthPercent
        obj.FullOffsets[obj.FullOffsets.Length()] += 8
        return 100 * obj.Read()
    }

    HealHero(champID := 58)
    {
        if (champID < 1)
            return ""
        ; x10 = full heal
        if (g_SF.Memory.ReadLevelUpAmount() != 10)
            g_SF.DirectedInput(, release := 0, "{Shift}") ;keysdown
        keys := ["{Shift}", "{F" . g_SF.Memory.ReadChampSeatByID(champID) . "}"]
        g_SF.DirectedInput(, release := 0, keys*) ;keysdown
        g_SF.DirectedInput(hold := 0,, keys*) ;keysup
        return true
    }

    CheckBrivHealth()
    {
        static lastPercent := ""

        percent := Max(0, this.ReadHealthPercent())
        if (lastPercent > 0 && percent == 0)
        {
            g_SharedData.BGFHTS_BrivDeaths += 1
            lastPercent := 0
        }
        else if (percent > 0 && percent < g_BrivUserSettingsFromAddons[ "BGFHTS_BrivAutoHeal" ])
        {
            if (IsObject(IC_BrivGemFarm_LevelUp_Class) && !IC_BrivGemFarm_LevelUp_Class.BGFLU_CanAffordUpgrade(ActiveEffectKeySharedFunctions.Briv.HeroID))
                return
            this.HealHero()
            g_SharedData.BGFHTS_BrivHeals += 1
        }
        lastPercent := percent
    }
}