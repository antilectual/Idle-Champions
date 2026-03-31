#include *i %A_LineFile%\..\..\IC_BrivGemFarm_BrivFeatSwap_Extra\IC_BrivGemFarm_BrivFeatSwap_Functions.ahk

; Functions used by this addon
class IC_BrivGemFarm_LevelUp_Functions
{
    static SettingsPath := A_LineFile . "\..\BrivGemFarm_LevelUp_Settings.json"
    static Injected := false

    ; Adds IC_BrivGemFarm_LevelUp_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        if (this.Injected)
            return
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_BrivGemFarm_LevelUp_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
        if (this.CheckForBrivFeatSwapAddon()) ; Load Briv Feat Swap after this addon
            IC_BrivGemFarm_BrivFeatSwap_Functions.InjectAddon(true)
        this.Injected := true
    }

    ; Returns true if the BrivGemFarm Briv Feat Swap addon is enabled in Addon Management or in the AddOnsIncluded.ahk file
    CheckForBrivFeatSwapAddon()
    {
        static AddOnsIncludedConfigFile := % A_LineFile . "\..\..\AddOnsIncluded.ahk"
        static AddonName := "BrivGemFarm Briv Feat Swap"

        if (IsObject(AM := AddonManagement)) ; Look for enabled BrivGemFarm Briv Feat Swap addon
            for k, v in AM.EnabledAddons
                if (v.Name == AddonName)
                    return true
        if (FileExist(AddOnsIncludedConfigFile)) ; Try in the AddOnsIncluded file
            Loop, Read, %AddOnsIncludedConfigFile%
                if InStr(A_LoopReadLine, "#include *i %A_LineFile%\..\IC_BrivGemFarm_BrivFeatSwap_Extra\IC_BrivGemFarm_BrivFeatSwap_Component.ahk")
                    return true
        return false
    }

    ; Returns true if the two objects have identical key/value pairs.
    AreObjectsEqual(obj1 := "", obj2 := "")
    {
        if (obj1.Count() != obj2.Count())
            return false
        if (!IsObject(obj1))
            return !IsObject(obj2) && (obj1 == obj2)
        for k, v in obj1
        {
            if (IsObject(v) && !this.AreObjectsEqual(obj2[k], v))
                return false
            else if (!IsObject(v) && obj2[k] != v && obj2.HasKey(k))
                return false
        }
        return true
    }

    ; Returns true if the two values are identical, false otherwise.
    ; Returns an object that contains all the differences between the
    ; key/value pairs of both objects.
    ; Return object format: {key:[value(obj1),value(obj2)], ...}
    AreObjectsEqualDiff(obj1 := "", obj2 := "", key := "")
    {
        static diff := {}

        if (key == "")
            diff := {}
        if (!IsObject(obj1) && !IsObject(obj2))
        {
            if (obj1 != obj2)
                diff[key] := [obj1, obj2]
        }
        for k, v in obj1
        {
            subKey := (key != "") ? key . "." . k : k
            if (IsObject(v))
                this.AreObjectsEqualDiff(v, obj2[k], subKey)
            else if (!IsObject(v) && obj2[k] != v)
            {
                if (!diff.HasKey(subKey))
                    diff[subKey] := [v, obj2[k]]
            }
        }
        for k, v in obj2
        {
            subKey := (key != "") ? key . "." . k : k
            if (IsObject(v))
                this.AreObjectsEqualDiff(obj1[k], v, subKey)
            else if (!IsObject(v) && obj1[k] != v)
            {
                if (!diff.HasKey(subKey))
                    diff[subKey] := [obj1[k], v]
            }
        }
        if (key != "")
            return diff.Count()
        ret := diff.Count() ? this.ObjFullyClone(diff) : true
        diff := {}
        return ret
    }

    ; Creates a deep clone of an object
    ObjFullyClone(obj)
    {
        nobj := obj.Clone()
        for k, v in nobj
        {
            if IsObject(v)
                nobj[k] := this.ObjFullyClone(v)
        }
        return nobj
    }

    ; Returns the width of DDL accomodating the longest item in list
    DropDownSize(List, Font:="", FontSize:=10, Padding:=24)
    {
        Loop, Parse, List, |
        {
            if Font
                Gui DropDownSize:Font, s%FontSize%, %Font%
            Gui DropDownSize:Add, Text, R1, %A_LoopField%
            GuiControlGet T, DropDownSize:Pos, Static%A_Index%
            TW > X ? X := TW :
        }
        Gui DropDownSize:Destroy
        return X + Padding
    }

    ; Returns the text with added line wraps if a line is longer than maxLength
    ; TODO: Use text width
    WrapText(text, maxLength := 60)
    {
        if (StrLen(text) <= maxLength)
            return Trim(text)
        str := ""
        lineLength := position := 0
        Loop, Parse, text, " `r`n"
        {
            wordLength := StrLen(A_LoopField)
            position += wordLength + 1
            separator := SubStr(text, position, 1)
            if ((lineLength += wordLength) > maxLength) ; Force new line
            {
                str := RTrim(str) . "`n"
                lineLength := wordLength + (separator == " " ? 1 : 0)
            }
            else if (separator == "`n") ; New line
                lineLength := 0
            else ; Space
                lineLength += 1
            str .= A_LoopField . separator
        }
        return Trim(str)
    }

    ; Returns the index of the active monitor of a given window handle
    ; https://www.autohotkey.com/board/topic/94735-get-active-monitor/
    GetMonitor(hwnd := 0) {
    ; If no hwnd is provided, use the Active Window
        if (hwnd)
            WinGetPos, winX, winY, winW, winH, ahk_id %hwnd%
        else
            WinGetActiveStats, winTitle, winW, winH, winX, winY

        SysGet, numDisplays, MonitorCount
        SysGet, idxPrimary, MonitorPrimary

        Loop %numDisplays%
        {	SysGet, mon, MonitorWorkArea, %a_index%
        ; Left may be skewed on Monitors past 1
            if (a_index > 1)
                monLeft -= 10
        ; Right overlaps Left on Monitors past 1
            else if (numDisplays > 1)
                monRight -= 10
        ; Tracked based on X. Cannot properly sense on Windows "between" monitors
            if (winX >= monLeft && winX < monRight)
                return %a_index%
        }
    ; Return Primary Monitor if can't sense
        return idxPrimary
    }

    UnixToUTC(unixTime)
    {
        time := 1970
        time += unixTime, s
        return time
    }

    ; Converts a integer to an boolean array.
    ; Params: value:int - Integer (64-bit limit).
    ;         associative:array - If true, returns an associative array {}.
    ;                             If false, returns a linear array [].
    ConvertBitfieldToArray(value, associative := false)
    {
        array := associative ? {} : []
        Loop, 50
        {
            if (associative)
                array[A_Index] := (value & (2 ** (A_Index - 1))) != 0
            else
                array.Push((value & (2 ** (A_Index - 1))) != 0)
        }
        return array
    }

    ; Converts a symbol to the corresponding integer exponent.
    ConvertNumberSymbolToInt(name)
    {
        static symbols := {"K":3, "M":6, "B":9, "t":12, "q":15, "Q":18, "s":21, "S":24
                           , "o":27, "n":30, "d":33, "U":36, "D":39, "T":42, "Qt":45
                           , "Qd":48, "Sd":51, "St":54, "O":57, "N":60, "v":63, "c":66}

        return symbols[name]
    }

    ; Converts a number string in scientific notation or symbol notation
    ; to an integer for comparison.
    ; Returns an integer equal to 1000 * exponent plus 100 * significand.
    ; This works only when the number format has less than 3 significant digits.
    ConvertNumberStringToInt(numStr)
    {
        split := StrSplit(numStr, "e")
        if split[2] is integer
        {
            significand := split[1]
            exponent := split[2]
        }
        else
        {
            regex := "(.*\d)([a-zA-Z]+)"
            RegExMatch(numStr, regex, out)
            significand := out1
            exponent := this.ConvertNumberSymbolToInt(out2)
        }
        return Round(exponent * 1000 + significand * 100)
    }

    ; Returns true if combining Briv and Thellora jumps lands in a boss zone.
    ThelloraBrivCombineHitsBoss()
    {
        maxRushArea := ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.ReadMaxRushArea()
        rushStacks := Floor(ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.ReadRushStacks())
        rushZone := Min(maxRushArea, rushStacks)
        if (g_SF.Memory.ReadHighestZone() >= rushZone)
            return false
        QCfg := IC_BrivGemFarm_Class.BrivFunctions.GetBrivSkipConfig(1)
        availableJumps := QCfg.AvailableJumps
        for _, skips in availableJumps
        {
            if (Mod(rushZone + 1 + skips, 5) == 0)
                return true
        }
        return false
    }
}