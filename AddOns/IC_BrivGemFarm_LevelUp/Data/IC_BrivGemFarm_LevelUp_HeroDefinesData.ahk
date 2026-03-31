#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_AttackData.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_EffectData.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_HeroData.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_TextData.ahk
#include %A_LineFile%\..\IC_BrivGemFarm_LevelUp_UpgradeData.ahk

; Class that contains the data of a champion
Class IC_BrivGemFarm_LevelUp_HeroDefinesData
{
    static HeroDefines := ""
    static HeroDataByID := {}
    static HeroDataByName := {}
    static HeroDataBySeat := [{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}]

    Init(Byref heroDefines)
    {
        this.HeroDefines := heroDefines
        for k, v in heroDefines.attack_defines
            this.AddAttackData(k, v)
        for k, v in heroDefines.effect_defines
            this.AddEffectData(k, v)
        for k, v in heroDefines.effect_key_defines
            this.AddEffectData(k, v)
        for k, v in heroDefines.upgrade_defines
            this.AddUpgradeData(k, v)
        for k, v in heroDefines.hero_defines
            this.AddHeroData(k, v)
    }

    AddAttackData(id, data)
    {
        attackData := new IC_BrivGemFarm_LevelUp_AttackData(id, data)
        IC_BrivGemFarm_LevelUp_AttackData.AttacksByID[id] := attackData
    }

    AddEffectData(id, data)
    {
        effectData := new IC_BrivGemFarm_LevelUp_EffectData(id, data)
        IC_BrivGemFarm_LevelUp_EffectData.EffectsByID[id] := effectData
    }

    AddUpgradeData(id, data)
    {
        upgradeData := new IC_BrivGemFarm_LevelUp_UpgradeData(id, data)
        IC_BrivGemFarm_LevelUp_UpgradeData.UpgradesByID[id] := upgradeData
    }

    AddHeroData(id, heroData)
    {
        data := new IC_BrivGemFarm_LevelUp_HeroData(id, heroData)
        this.HeroDataByID[id] := data
        this.HeroDataByName[heroData.name] := data
        this.HeroDataBySeat[heroData.seat_id][id] := data
        IC_BrivGemFarm_LevelUp_Seat.Seats[heroData.seat_id].UpdateHasSpoilers(data)
    }

    AttackDataById(id)
    {
        return IC_BrivGemFarm_LevelUp_AttackData.AttacksByID[id]
    }

    EffectDataById(id)
    {
        return IC_BrivGemFarm_LevelUp_EffectData.EffectsByID[id]
    }

    UpgradeDataByID(id)
    {
        if id is not integer
            return
        upgradeDataClass := IC_BrivGemFarm_LevelUp_UpgradeData
        if (!upgradeDataClass.UpgradesByID.HasKey(id))
            this.AddUpgradeData(id, this.HeroDefines.upgrade_defines[id])
        return upgradeDataClass.UpgradesByID[id]
    }

    ListString(list, type := "and")
    {
        if (!IsObject(list))
            list := [list]
        if ((count := list.Length()) == 0)
            return ""
        if (count == 1)
            return list[1]
        if (count == 2)
        {
            key := type == "or" ? "list_or" : "list_and"
            keyStr := IC_BrivGemFarm_LevelUp_TextData.GetData(key, "Text Not Found")
            return list[1] . " " . keyStr . " " . list[2]
        }
        str := list[1]
        Loop, % count - 2
            str .= ", " . list[A_Index + 1]
        lastKey := type == "or" ? "list_or_ending" : "list_ending"
        lastKeyStr := IC_BrivGemFarm_LevelUp_TextData.GetData(lastKey, "Text Not Found")
        return str . StrReplace(lastKeyStr, "$(item)", list[count])
    }

    TimeFormat(timeInSeconds, maxRes := "second", useAbbr := false, maxDivs := 2)
    {
        static baseTimeStr := ["day", "hour", "minute", "second"]
        static textDataClass := IC_BrivGemFarm_LevelUp_TextData

        str := ""
        d := Floor(timeInSeconds / 86400)
        sd := timeInSeconds - d * 86400
        h := Floor(sd / 3600)
        sh := sd - h * 3600
        m := Floor(sh / 60)
        s := sh - m * 60
        arr := [], maxResInt := 4
        for k, v in baseTimeStr
        {
            if (v == maxRes)
                maxResInt := k
            if (useAbbr)
            {
                one := textDataClass.TimeString(v . "Abr")
                arr.Push([one . " ", one . " "])
            }
            else
            {
                one := textDataClass.TimeString(v)
                two := textDataClass.TimeString(v . "Plur")
                arr.Push([" " . one . " ", " " . two . " "])
            }
        }
        divCount := 0
        maxDivs := maxDivs != "" ? maxDivs : 4
        for k, v in [d, h, m, s]
        {
            if ((v > 0 OR divCount > 0) AND maxResInt >= k AND divCount < maxDivs)
            {
                str .= v . arr[k][2 - (v == 1)]
                ++divCount
            }
        }
        return Trim(divCount > 0 ? str : "0" . arr[4][2])
    }
}