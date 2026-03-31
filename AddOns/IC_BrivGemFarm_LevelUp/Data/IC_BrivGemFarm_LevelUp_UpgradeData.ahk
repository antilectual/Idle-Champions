; Class that contains all upgrades data of a champion
Class IC_BrivGemFarm_LevelUp_UpgradeData
{
    static UpgradesByID := {}

    ID := ""
    Hero_id := ""
    Required_level := ""
    Name := ""
    Upgrade_type := ""
    Effect := ""
    Specialization_name := ""
    Description := ""
    Long_description := ""

    __New(id, data)
    {
        for k, v in data
            this[k] := v
        this.ID := id
        if (data.name == "")
        {
            if (data.specialization_name != "")
                this.Name := data.specialization_name
            else
            {
                effectString := (data.effect != "") ? data.effect : data.effect_string
                baseID := StrSplit(effectString, ",")[3]
                if (baseID > 0)
                    this.Name := g_HeroDefines.UpgradeDataByID(baseID).name
            }
        }
    }

    BuildUpgrades(Byref data)
    {
        lastUpgradeLevel := 0, maxUpgradeLevelDigits := 0, listContents := "", specializations := {}
        for k, upgradeID in (upgrades := data.upgrades)
        {
            if ((level := this.UpgradesByID[upgradeID].required_level) == "")
                continue
            lastUpgradeLevel := Max(level, lastUpgradeLevel)
            maxUpgradeLevelDigits := Max(maxUpgradeLevelDigits, StrLen(level))
        }
        data.LastUpgradeLevel := lastUpgradeLevel
        for k, upgradeID in upgrades
        {
            upgrade := this.UpgradesByID[upgradeID]
            level := levelStr := upgrade.required_level
            if (level == "")
                continue
            s := ""
            if (upgrade.specialization_name)
            {
                if (specializations[level] == "")
                    specializations[level] := 1
                levelStr .=  "." . specializations[level]
                s .= "↰↱ " . specializations[level]++ . "." . upgrade.specialization_name
            }
            else if (upgrade.name)
                s .= "★  " . upgrade.name
            if (upgrade.effect)
            {
                if (IsObject(upgrade.effect))
                    split := StrSplit(upgrade.effect.effect_string, ",")
                else
                    split := StrSplit(upgrade.effect, ",")
                if (split[1] == "health_add")
                    s .= "♥ Health +" . split[2]
                else if (split[1] == "hero_dps_multiplier_mult")
                    s .= "🗡️ Damage +" . split[2] . "%"
                else if (split[1] == "global_dps_multiplier_mult")
                    s .= "⚔️ Global Damage +" . split[2] . "%"
                else if (split[1] == "set_ultimate_attack")
                    s := "⚡️ " . upgrade.name
                else if (split[1] == "buff_ultimate")
                    s := "++ Ultimate damage +" split[2] . "%"
                else if (split[1] == "buff_upgrade")
                    s := "++ " . this.UpgradesByID[split[3]].name . " +" split[2] . "%"
                else if (split[1] == "increase_revive_effect_post_stack")
                    s := "++ " . this.UpgradesByID[split[3]].name . " +" split[2] . "%"
                else if (split[1] == "buff_upgrades")
                {
                    common := StrSplit(this.UpgradesByID[split[3]].name, ":")
                    s := "++ " . common[1] . " +" split[2] . "%"
                }
           }
            p := "" ; Longest number has no padding before ':'
            Loop, % 2 * (maxUpgradeLevelDigits - StrLen(level)) ; 2 pixels per digit
                p .= " "
            listContents .= levelStr . p . ": " . s . "|"
        }
        Sort, listContents, N D|
        return RegExReplace(listContents, "((\d)+)(\.)(\d)+", "$1") ; Remove specialization sort string
    }

    EffectDef
    {
        get
        {
            split := StrSplit(this.effect, ",")
            return g_HeroDefines.EffectDataById(split[2])
        }
    }

    FullDescription()
    {
        str := ""
        if ((effect := this.Effect) != "")
        {
            if (IsObject(effect))
                effect := effect.effect_string
            if (effect != "")
            {
                split := StrSplit(effect, ",")
                if (split[1] == "set_ultimate_attack") ; Ultimate
                {
                    if (split.Length() == 1)
                        split[2] := g_HeroDefines.HeroDataByID[this.hero_id].ultimate_attack_id
                    str .= g_HeroDefines.AttackDataById(split[2]).FullDescription(this)
                }
                else if (split[1] == "effect_def") ; Effect
                {
                    str .= g_HeroDefines.EffectDataById(split[2]).FullDescription(this)
                    Loop, % split.Length() - 2
                        str .= "`n" . g_HeroDefines.EffectDataById(split[A_Index + 2]).FullDescription(this)
                }
                else ; Effect_key
                {
                    effectKey := split.RemoveAt(1)
                    str .= g_HeroDefines.EffectDataById(effectKey).FullDescription(this, split*)
                }
            }
        }
        return this.RemoveHexColorStrings(str)
    }

    RemoveHexColorStrings(str)
    {
        regex := "{([^}]*)}#\w+"
        return RegexReplace(str, regex, "$1")
    }
}