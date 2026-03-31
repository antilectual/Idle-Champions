; Class that contains all attack data
Class IC_BrivGemFarm_LevelUp_AttackData
{
    static AttacksByID := {}

    ID := ""
    Description := ""
    ; Long_description := ""
    Name := ""

    __New(id, data)
    {
        for k, v in data
            this[k] := v
        this.ID := id
    }

    FullDescription(upgrade)
    {
        if (this.id == 359)
            return this.HewMaanUltimateDescription()
        str := g_HeroDefines.EffectDataById("set_ultimate_attack").FullDescription(upgrade, this.id)
        str2 := this.Long_description != "" ? this.Long_description : this.Description
        if (InStr(str2, "$ishi_ult_time"))
            str2 := StrReplace(str2, "$ishi_ult_time", "15")
        else if (InStr(str2, "$(nrakk_ult_buffed 200)"))
            str2 := StrReplace(str2, "$(nrakk_ult_buffed 200)", "200")
        return str . "`n`n" . str2
    }

    HewMaanUltimateDescription()
    {
        str := ""
        for k, attackID in [359, 361, 362]
        {
            Switch attackID
            {
                case 359:
                    str .= IC_BrivGemFarm_LevelUp_TextData.GetData("front_column", "Front column") . " - "
                case 361:
                    str .= IC_BrivGemFarm_LevelUp_TextData.GetData("middle_column", "Middle column") . " - "
                case 362:
                    str .= IC_BrivGemFarm_LevelUp_TextData.GetData("back_column", "Back column") . " - "
            }
            str .= g_HeroDefines.EffectDataById("set_ultimate_attack").FullDescription(upgrade, attackID) . "`n`n"
            attackData := g_HeroDefines.AttackDataById(attackID)
            str2 := attackData.Long_description != "" ? attackData.Long_description : attackData.Description
            str .= str2 != "" ? str2 . "`n`n" : ""
        }
        return str
    }
}