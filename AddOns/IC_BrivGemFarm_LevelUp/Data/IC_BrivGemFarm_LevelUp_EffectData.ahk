; Class that contains all effect data
Class IC_BrivGemFarm_LevelUp_EffectData
{
    static descriptionRegex := "\$\(([^\)]+)\)|(?:\$(\w+))"
    static EffectsByID := {}

    ID := ""

    __New(id, data)
    {
        for k, v in data
            this[k] := v
        this.ID := id
    }

    RawDescriptionFromConditions(descriptions)
    {
        text := ""
        if (descriptions.HasKey("pre"))
            text .= this.RawDescriptionFromCondition(descriptions, "pre")
        if (descriptions.HasKey("desc"))
            text .= this.RawDescriptionFromCondition(descriptions, "desc")
        else if (descriptions.HasKey("conditions"))
        {
            conditionsTrue := ["static_desc", "not short_form", "spurt_is_spirit_v2"] ; TODO: Display conditions as radio/checkboxes
            if (this.id == 980 OR this.id == 1126) ; Perfect Imitation / Meat Grinder
                conditionsTrue.Push("not static_desc")
            if (this.id == 1126) ; Meat Grinder
            {
                effect := this.effect_keys[1].effect_string
                split := StrSplit(effect, ",")
                if (split[1] == "set_ultimate_attack") ; Ultimate
                    text .= g_HeroDefines.AttackDataById(split[2]).FullDescription("")
            }
            for k, dictionary in descriptions.conditions
            {
                if this.CheckConditionsTrue(dictionary, conditionsTrue)
                {
                    text .= this.RawDescriptionFromConditions(dictionary)
                    if (this.id == 980 OR this.id == 1126)
                        text .= (k >= dictionary.Count()) ? "" : "`n`n"
                    else
                        break
                }
            }
        }
        if (descriptions.HasKey("post"))
            text .= this.RawDescriptionFromCondition(descriptions, "post")
        return text
    }

    RawDescriptionFromCondition(descriptions, key)
    {
        isObj := IsObject(desc := descriptions[key])
        return isObj? this.RawDescriptionFromConditions(desc) : desc
    }

    CheckConditionsTrue(dictionary, conditions)
    {
        cd := dictionary.HasKey("desc") AND !dictionary.HasKey("condition")
        condition := dictionary.condition
        for k, v in conditions
            if (v == condition)
                cd2 := true
        return cd OR cd2
    }

    GetDescriptionString(upgrade)
    {
        if (IsObject(upgrade.effect) AND upgrade.effect.HasKey("description"))
            description := upgrade.effect.description
        else
        {
            if (this.HasKey("descriptions"))
                descriptionStr := this.descriptions
            else if (this.HasKey("description"))
                descriptionStr := this.description
            else
                descriptionStr := ""
            description := this.RawDescriptionFromConditions(descriptionStr)
        }
        return this.ParseConditionalDescription(description)
    }

    ParseConditionalDescription(description)
    {
        str := ""
        pushCurrent := true
        regex := this.descriptionRegex
        subStartPos := nextPos := 1
        activeBranch := false
        while (nextPos := RegExMatch(description, "O)" . regex, matchO, nextPos))
        {
            match := (matchO[1] != "") ? matchO[1] : matchO[2]
            if (match == "only_when_purchased" AND !(this.id == 441)) ; Jim's Wand Of Wonder
            {
                description := SubStr(description, 1, RegExMatch(description, match) - 2)
                break
            }
            if (match == "fi")
                activeBranch := false
            if (pushCurrent)
            {
                subString := SubStr(description, subStartPos, nextPos - subStartPos + matchO.len())
                if match in if not incoming_desc,else,fi,only_when_purchased
                    subString := StrReplace(subString, matchO[0], "")
                str .= subString
            }
            if (match == "if not incoming_desc")
                activeBranch := true
            else if (match == "else")
                pushCurrent := false
            else if (!activeBranch)
                pushCurrent := true
            subStartPos := nextPos += matchO.len()
        }
        str .= SubStr(description, subStartPos, StrLen(description) - subStartPos + 1)
        return Trim(StrReplace(str, "^", "`n"))
    }

    GetBaseEffectKeyValuePairs(values*)
    {
        if (!(paramsCount := values.Length()))
            return ""
        kvps := {}
        if (this.HasKey("param_names"))
        {
            param_names := StrSplit(this.param_names, ",")
            Loop, % paramsCount
            {
                type := ""
                paramName := StrSplit(param_names[A_Index], " ")
                if (paramName.Length() == 1)
                    paramName := paramName[1]
                else
                    type := paramName[1], paramName := paramName[2]
                ; base is a default object property in .ahk
                paramName := (paramName == "base") ? paramName . "®" : paramName
                if (RegExMatch(type, "\[[a-zA-Z]+\]"))
                {
                    values.RemoveAt(1, A_Index - 1)
                    kvps[paramName] := values
                    break
                }
                else
                    kvps[paramName] := values[A_Index]
            }
        }
        else
            kvps.amount := values[1]
        return kvps
    }

    GetEffectKeyValuePairs(values*)
    {
        if (this.HasKey("effect_keys") AND (keys := this.effect_keys) != "")
        {
            indexed := this.properties.indexed_effect_properties
            for k, v in keys
            {
                vals := this.ParseEffectKeys(v)
                indexString := indexed ? ("___" . k) : ""
                for k1, v1 in vals ; Replace indexes
                {
                    paramName := (k > 1) ? (k1 . indexString) : k1
                    values[paramName] := v1
                }
            }
        }
        return values
    }

    ParseEffectKeys(keys)
    {
        values := {}
        for k, v in keys
            values[k] := v
        if ((effectString := values.effect_string) != "")
        {
            vals := StrSplit(effectString, ",")
            baseEffect := g_HeroDefines.EffectDataById(vals.RemoveAt(1))
            if (IsObject(baseEffect))
                kvps := baseEffect.GetBaseEffectKeyValuePairs(vals*)
            else if (vals.Length())
                kvps := {amount:vals[1]}
            else
                kvps := ""
            for k, v in kvps ; Replace indexes
                values[k] := v
        }
        return values
    }

    FullDescription(upgrade, values*)
    {
        description := this.GetDescriptionString(upgrade)
        if (values.Length() == 0)
            kvps := this.GetEffectKeyValuePairs(values*)
        else
            kvps := this.GetBaseEffectKeyValuePairs(values*)
        return this.MakeReplacements(upgrade, description, kvps)
    }

    MakeReplacements(upgrade, replace, kvps)
    {
        str := replace, nextPos := 1, regex := this.descriptionRegex
        while (nextPos := RegExMatch(replace, "O)" . regex, matchO, nextPos))
        {
            match := (matchO[1] != "") ? matchO[1] : matchO[2]
            replacement := this.MakeReplacement(upgrade, match, kvps)
            if replacement is float
                replacement :=  Format("{:.4g}", replacement)
            if (replacement == "NOREPL")
                StringUpper, replacement, match
            str := StrReplace(str, matchO[0], replacement,, 1)
            nextPos += matchO.len()
        }
        return str
    }

    MakeReplacement(upgrade, replace, kvps)
    {
        params := StrSplit(replace, " ")
        switch params.Length()
        {
            case 1:
                return this.MakeReplacement1(upgrade, replace, kvps)
            case 2:
                return this.MakeReplacement2(upgrade, replace, kvps)
            case 3:
                return this.MakeReplacement3(upgrade, replace, kvps)
        }
    }

    MakeReplacement3(upgrade, replace, kvps)
    {
        params := StrSplit(replace, " ")
        param1 := params[1], param2 := params[2], param3 := params[3]
        if (param1 == "active_upgrade_value_with_bonuses")
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("unknown", "Unknown")
        else if (param1 == "current_scavenge_cap" && param2 == "diana_electrum_scavenger")
        {
            startTime := RegExReplace(kvps.start_date, "[:-\s]")
            EnvAdd, startTime, 7, H
            EnvSub, startTime, A_NowUTC, D
            repl := Floor(kvps.initial_cap + kvps.cap_increase_per_day * Abs(startTime))
        }
        else if (kvps[param2] != "")
            repl := kvps[param2]
        else if (kvps.HasKey(param1))
            repl := kvps[param1]
        else
            repl := "NOREPL"
        return repl
    }

    MakeReplacement2(upgrade, replace, kvps)
    {
        params := StrSplit(replace, " ")
        param1 := params[1], param2 := params[2], param2Val := kvps[param2]
        repl := "NOREPL"
        if(param1 == "at_percent_damage")
        {
            if (kvps.HasKey(param2))
            {
                dataKey := IC_BrivGemFarm_LevelUp_TextData.GetData("at_percent_percent", "at $percent percent")
                repl := " " . StrReplace(dataKey, "$percent", param2Val)
            }
            else
                repl := ""
        }
        else if (param1 == "upgrade_value") ; ++
        {
            split := StrSplit(param2, ",")
            effectDef := g_HeroDefines.UpgradeDataByID(split[1]).effectDef
            effectString := effectDef.effect_keys[split[2] + 1].effect_string
            repl := StrSplit(effectString, ",")[2]
        }
        else if (param1 == "attack_name")
        {
            if (this.ValueIfKeyExists(kvps, param2) == "NOREPL")
            {
                heroData := g_HeroDefines.HeroDataByID[upgrade.hero_id]
                param2Val := heroData.ultimate_attack_id
            }
            repl := g_HeroDefines.AttackDataByID(param2Val).name
        }
        else if (param1 == "round")
        {
            if (this.ValueIfKeyExists(kvps, param2) != "NOREPL")
                repl := param2Val
        }
        else if (param1 == "text_key")
        {
            if ((dataKey := this.ValueIfKeyExists(kvps, param2)) != "NOREPL")
                repl := IC_BrivGemFarm_LevelUp_TextData.GetData(dataKey, "Text Not Found")
        }
        else if (param1 == "buffed_number")
            repl := (param2 != "") ? param2 : "NOREPL"
        else if param1 in upgrade_bonus,upgrade_stacks_num,active_upgrade_value
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("unknown", "Unknown")
        else if (param1 == "ability_list")
        {
            ids := []
            for k, v in param2Val
                ids.Push(g_HeroDefines.UpgradeDataByID(v).name)
            dataKey := k == 1 ? "ability" : "abilities"
            finalKey := IC_BrivGemFarm_LevelUp_TextData.GetData(dataKey, dataKey)
            repl := g_HeroDefines.ListString(ids, "and") . " " . finalKey
        }
        else if (param1 == "upgrade_hero")
        {
            upgradeID := IsObject(param2Val) ? param2Val[1] : param2Val
            if (upgradeID > 0)
            {
                upgradeData := g_HeroDefines.UpgradeDataByID(upgradeID)
                repl := g_HeroDefines.HeroDataByID[upgradeData.hero_id].name
            }
        }
        else if(param1 == "sources_favored_foe_list_and")
        {
            ; Might have multiple tags in the future
            dataKey := "tag_" . param2 . "_plural"
            tags := IC_BrivGemFarm_LevelUp_TextData.GetData(dataKey, dataKey)
            repl := g_HeroDefines.ListString(tags, "and")
        }
        else if(param1 == "shaka_locked_tag")
        {
            effectKey := param2 . "_expressions"
            ; shaka_celestial_puzzle
            baseEffect := g_HeroDefines.EffectDataById(821)
            for k, v in baseEffect["effect_keys"]
            {
                if (v["effect_string"] == "shaka_celestial_puzzle")
                {
                    effect_string := v
                    break
                }
            }
            for k, v in effect_string
            {
                if (k == effectKey)
                {
                    expressions := v
                    break
                }
            }
            tags := []
            for k, v in expressions
            {
                firstTag := StrSplit(v, "|")[1]
                tag := IC_BrivGemFarm_LevelUp_TextData.GetData(firstTag, "???")
                if v contains male
                    tag .= " / " . IC_BrivGemFarm_LevelUp_TextData.GetData(non_binary, "Nonbinary")
                tags.Push(tag)
            }
            repl := g_HeroDefines.ListString(tags, "or")
        }
        else if (param2Val != "")
        {
            if (param1 == "not_buffed")
                repl := param2Val
            else if (param1 == "upgrade_name")
                repl := g_HeroDefines.UpgradeDataByID(param2Val).name
            else if (param1 == "describe_rarity")
                repl := IC_BrivGemFarm_LevelUp_TextData.RarityFromIndex(param2Val)
            else if (param1 == "attack_names_and")
            {
                for k, v in param2Val
                    param2Val[k] := g_HeroDefines.AttackDataByID(v).name
                dataKey := k == 0 ? "attack" : "attacks" ; CNE's off by one error
                finalKey := IC_BrivGemFarm_LevelUp_TextData.GetData(dataKey, (k == 0) ? "Attack" : "Attacks")
                repl := g_HeroDefines.ListString(param2Val, "and") . " " . finalKey
            }
            else if param1 in list_or,describe_tag_list_or
                repl := g_HeroDefines.ListString(param2Val, "or")
            else if (param1 == "describe_tag_list_and")
                repl := g_HeroDefines.ListString(param2Val, "and")
            else if (param1 == "describe_tags")
                repl := g_HeroDefines.ListString(param2Val)
            else if (param1 == "time_str")
                repl := g_HeroDefines.TimeFormat(param2Val, "second", false, 2)
            else if (param1 == "tmp_hp_cooldown") ; - temporary_hp_cooldown_reduce
                repl := param2Val
            else if (param1 == "value")
                repl := param2Val
            else if (param1 == "buffed_ki_points") ; ++
                repl := IC_BrivGemFarm_LevelUp_TextData.GetData("1_extra_ki_point", "1 extra Ki Point")
            else if (param1 == "as_multiplier")
                repl := (param2Val + 100) / 100
            else if (param1 == "seconds_plural")
            {
                if (param2Val == 0)
                    repl := "NOREPL"
                else if (param2Val == 1)
                    repl := IC_BrivGemFarm_LevelUp_TextData.GetData("1_second", "1 second")
                else
                {
                    str := IC_BrivGemFarm_LevelUp_TextData.GetData("amount_seconds", "$amount seconds")
                    repl := StrReplace(str, "$amount", param2Val)
                }
            }
            else if (param1 == "targets_desc_plural")
            {
                if ((target := this.ValueIfKeyExists(kvps, param2)) != "NOREPL")
                {
                    subDescription := IC_BrivGemFarm_LevelUp_TextData.EffectTargetDescriptionsPlural(target[1])
                    repl := this.MakeReplacements(upgrade, subDescription, kvps)
                }
            }
        }
        return repl
    }

    MakeReplacement1(upgrade, replace, kvps)
    {
        param1 := replace
        repl := "NOREPL"
        if (param1 == "target" OR param1 == "source" OR param1 == "source_hero")
            repl := g_HeroDefines.HeroDataByID[upgrade.hero_id].name
        else if (param1 == "pluralize_targets")
        {
            dataKey := (kvps["amount"] == 1) ? "target" : "targets"
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData(dataKey, dataKey)
        }
        else if (param1 == "shen_state_description")
        {
            dataKey := "dragonbait_shen_state_desc"
            defaultText := "Dragonbait increases the damage of Champions within 1 slot by $amount%"
            description := IC_BrivGemFarm_LevelUp_TextData.GetData(dataKey, defaultText)
            repl := StrReplace(description, "$amount", kvps["amount"])
        }
        else if param1 in shen_state_roasted_vegetables_description,shen_state_meat_sauce_description
            repl := ""
        else if (param1 == "echo_description")
        {
            resolutionEffect := g_HeroDefines.EffectDataById(495)
            amplificationEffect := g_HeroDefines.EffectDataById(496)
            healingEffect := g_HeroDefines.EffectDataById(494)
            desc1 := resolutionEffect.FullDescription("")
            desc2 := amplificationEffect.FullDescription("")
            desc3 := healingEffect.FullDescription("")
            repl := "`n`n" . (resolutionEffect.properties.effect_name) . ": " . desc1
            repl .= "`n" . (amplificationEffect.properties.effect_name) . ": " . desc2
            repl .= "`n" . (healingEffect.properties.effect_name) . ": " . desc3
        }
        else if (param1 == "plague_description")
        {
            pilferEffect := g_HeroDefines.EffectDataById(501)
            painEffect := g_HeroDefines.EffectDataById(502)
            traitorEffect := g_HeroDefines.EffectDataById(503)
            desc1 := pilferEffect.FullDescription("")
            desc2 := painEffect.FullDescription("")
            desc3 := traitorEffect.FullDescription("")
            repl := "`n" . (pilferEffect.properties.effect_name) . ": " . desc1
            repl .= "`n" . (painEffect.properties.effect_name) . ": " . desc2
            repl .= "`n" . (traitorEffect.properties.effect_name) . ": " . desc3
        }
        else if (param1 == "mirror_image_desc")
        {
            repl := ""
            for k, v in kvps
                if (k == "tagged_effects")
                    break
            for k1, v1 in v
            {
                split := StrSplit(v1, ",")
                if (k1 == "dps")
                    repl .= IC_BrivGemFarm_LevelUp_TextData.GetData("mirror_image_desc_dps", "DPS: Increases the Champion's Damage by $amount%")
                else if (k1 == "support")
                    repl .= IC_BrivGemFarm_LevelUp_TextData.GetData("mirror_image_desc_support", "Support: Increases the damage of all Champions by $amount%")
                else if (k1 == "tanking")
                    repl .= IC_BrivGemFarm_LevelUp_TextData.GetData("mirror_image_desc_tanking", "Tanking: Increases all incoming healing by $amount HP")
                repl := StrReplace(repl, "$amount", split[2]) . "`n"
            }
        }
        else if (param1 == "hordesperson_description")
        {
            for k, v in kvps
            {
                split := StrSplit(v, ",")
                effectKey := split.RemoveAt(1)
                if (effectKey == "kthriss_hordesperson") ; Incoming
                    repl := "`n`n" . g_HeroDefines.EffectDataById(effectKey).FullDescription("", split*)
            }
        }
        else if (param1 == "tatyana_find_a_feast_range")
        {
            if ((value := this.ValueIfKeyExists(kvps, "amount")) != NOREPL)
            {
                min := Floor(value / 100)
                max := Ceil(value / 100)
                repl := min . (min != max ? "-" . max : "")
            }
        }
        else if (param1 == "blooshi_spirit_carries_on_bonus_health")
            repl := this.ValueIfKeyExists(kvps, "amount___2")
        else if (param1 == "blooshi_grave_base")
            repl := this.ValueIfKeyExists(kvps, "base®")
        else if (param1 == "blooshi_grave_boss")
            repl := this.ValueIfKeyExists(kvps, "boss")
        else if (param1 == "talin_weakness_max_stacks")
            repl := this.ValueIfKeyExists(kvps, "max_stacks")
        else if param1 in torogar_zealot_desc,torogar_synergy_desc
            repl := ""
        else if (param1 == "torogar_blood_rage_desc")
        {
            textDefineByKey := IC_BrivGemFarm_LevelUp_TextData.GetData("amount_stacks", "$amount Stacks")
            repl := "`n`n" . IC_BrivGemFarm_LevelUp_TextData.GetData("zealot_stack_bonuses", "Zealot Stack Bonuses") . ": "
            repl .= "`n- " . StrReplace(textDefineByKey, "$amount", "250")
            repl .= ": " . IC_BrivGemFarm_LevelUp_TextData.GetData("zealot_bonus_250", "Mark of Tiamat Stuns Enemies for 2 seconds")
            repl .= "`n- " . StrReplace(textDefineByKey, "$amount", "2,500")
            repl .= ": " . IC_BrivGemFarm_LevelUp_TextData.GetData("zealot_bonus_2500", "Torogar add a small AOE to his base attack at 50% damage")
            repl .= "`n- " . StrReplace(textDefineByKey, "$amount", "25,000")
            repl .= ": " . IC_BrivGemFarm_LevelUp_TextData.GetData("zealot_bonus_25000", "Enemies with Mark of Tiamat have their attack cooldown increased by 1 second")
            repl .= "`n- " . StrReplace(textDefineByKey, "$amount", "250,000")
            repl .= ": " . IC_BrivGemFarm_LevelUp_TextData.GetData("zealot_bonus_250000", "Torogar reduces his base attack cooldown by 1 second")
            repl .= "`n- " . StrReplace(textDefineByKey, "$amount", "2,500,000")
            repl .= ": " . IC_BrivGemFarm_LevelUp_TextData.GetData("zealot_bonus_2500000", "Damage bonus from mark of Timat increased 200% (multiplicative)")
        }
        else if (param1 == "power_armor_max_stacks")
            repl := this.ValueIfKeyExists(kvps, "max_stacks")
        else if param1 in tiny_bulwark_cooldown,lighting_launcher_cooldown,lazaapz_power_armor_desc
            repl := ""
        else if (param1 == "freely_luck_of_yondalla_desc")
        {
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("yondalla_desc", "Each Champion that attacks with the Luck of Yondalla applies a random Lucky Break to enemies they hit for 15 seconds") . ":"
            repl .= "`n- " . IC_BrivGemFarm_LevelUp_TextData.GetData("yondalla_desc_opportunity_1", "Opportunity (Cornucopia): The target takes $amount% more damage per application (stacks multiplicitively).")
            repl := StrReplace(repl, "$amount", this.ValueIfKeyExists(kvps, "opportunity_amount", 0))
            repl .= " " . IC_BrivGemFarm_LevelUp_TextData.GetData("yondalla_desc_opportunity_2", "The total effect is increased by an additional $amount%.")
            repl := StrReplace(repl, "$amount", this.ValueIfKeyExists(kvps, "opportunity_amount", 0))
            repl .= "`n- " . IC_BrivGemFarm_LevelUp_TextData.GetData("yondalla_desc_requisition", "Requisition (Fruit): The target drops $amount% more gold per application (stacks multiplicitively).")
            repl := StrReplace(repl, "$amount", this.ValueIfKeyExists(kvps, "amount", 0))
            repl .= "`n- " . IC_BrivGemFarm_LevelUp_TextData.GetData("yondalla_desc_follow_through", "Follow Through (Border): Any Champion who attacks the target will have their next base attack cooldown reduced by $timeInSeconds per application.")
            repl := StrReplace(repl, "$timeInSeconds", this.ValueIfKeyExists(kvps, "follow_through_amount", 0) . IC_BrivGemFarm_LevelUp_TextData.GetData("second_word_abbreviated", "s"))
            repl .= "`n- " . IC_BrivGemFarm_LevelUp_TextData.GetData("yondalla_desc_stagger", "Stagger (Shield): The target has $amount% per application (stacks additively) chance of being stunned when they are attacked by any champion.")
            repl := StrReplace(repl, "$amount", this.ValueIfKeyExists(kvps, "stagger_amount", 0))
        }
        else if (param1 == "hitch_ricochet_chance")
            repl := this.ValueIfKeyExists(kvps, "ricochet_chance")
        else if (param1 == "hitch_ricochet_reduction_time")
            repl := ""
        else if param1 in speedy_suppliment_description,adaptive_support_description,augmented_support_description
            repl := ""
        else if (param1 == "adaptive_support_base_value")
            repl := this.ValueIfKeyExists(kvps, "amount")
        else if (param1 == "treasure_hunter_active")
            repl := ""
        else if param1 in unnatural_haste_description,healing_phlo_description
            repl := ""
        else if (param1 == "selise_thunderous_smite_cooldown")
            repl := this.ValueIfKeyExists(kvps, "amount")
        else if (param1 == "corazon_max_grease_puddle_count")
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("unknown", "Unknown")
        else if (param1 == "generous_djinn_desc")
            repl := ""
        else if (param1 == "halo_of_spores_description")
            repl := ""
        else if (param1 == "paid_up_front_bonus")
            repl := ""
        else if param1 in leadership_summit_description,demon_sickness_description
        {
            effectIDs := (param1 == "leadership_summit_description") ? [546, 547, 548, 549] : [551, 552, 553, 554]
            repl := ""
            for k, v in effectIDs
                repl .= "`n" . (g_HeroDefines.EffectDataById(v).FullDescription("")) . "`n"
        }
        else if (RegExMatch(param1, "voronika_inner_circle_(\d)", match))
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("UPGRADETIP_SPECIALIZATION_CHOICE_TEXT", "Specialization Choice") . " " . match1 + 1
        else if (param1 == "artemis_effect_description")
            repl := ""
        else if (param1 == "dash_time_until_bonus_desc")
            repl := ""
        else if (param1 == "lucius_elemental_adept_timer")
            repl := this.ValueIfKeyExists(kvps, "explosion_delay_timer")
        else if (param1 == "beadle_grimm_long_rest")
            repl := ""
        else if (param1 == "korth_resurrection_charges")
            repl := ""
        else if (RegExMatch(param1, "hewmaan(\w)+inactive"))
            repl := ""
        else if (param1 == "hewmaan_front_x_columns")
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("front_column", "Front column")
        else if (param1 == "hewmaan_middle_x_columns")
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("middle_column", "Middle column")
        else if (param1 == "hewmaan_back_x_columns")
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("back_column", "Back column")
        else if (param1 == "orisha_max_stacks")
            repl := this.ValueIfKeyExists(kvps, "max_stacks")
        else if (param1 == "orisha_flaming_buff_base_amount")
            repl := this.ValueIfKeyExists(kvps, "base_amount")
        else if (param1 == "orisha_flaming_buff_stack_amount")
            repl := this.ValueIfKeyExists(kvps, "stack_amount")
        else if (param1 == "upgrade_base_stack")
            repl := this.ValueIfKeyExists(kvps, "amount")
        else if (param1 == "azaka_attacks")
            repl := this.ValueIfKeyExists(kvps, "attacks")
        else if (param1 == "azaka_time")
            repl := this.ValueIfKeyExists(kvps, "time")
        else if param1 in weretiger_description,omin_contractual_obligation_desc,shadow_council_bonus_desc
            repl := ""
        else if param1 in chwinga_mask_healing_charm_stacks,chwinga_mask_tools_charm_stacks
            repl := ""
        else if (param1 == "miria_zombie_bodyguards_remaining_amount")
            repl := (value := this.ValueIfKeyExists(kvps, "amount")) != "NOREPL" ? 100 - value : value
        else if (param1 == "upgrade_stacks_num")
            repl := IC_BrivGemFarm_LevelUp_TextData.GetData("unknown", "Unknown")
        else if (param1 == "jangsao_stellar_nursery_target_count")
            repl := this.ValueIfKeyExists(kvps, "amount___2")
        else if param1 in sisaspia_spores_used,halo_of_spores_description2
            repl := ""
        else if (param1 == "dhani_gold_bonus")
        {
            ; dhani_splash_of_yellow
            effectKey := "effect_string___2"
            split := StrSplit(kvps[effectKey], ",")
            repl := 200 * split[2] / 100
        }
        else if (param1 == "dhani_aoe_damage")
        {
            ; dhani_stroke_of_green
            effectKey := "effect_string___2"
            split := StrSplit(kvps[effectKey], ",")
            repl := 50 * split[2] / 100
        }
        else if (param1 == "dhani_stun_duration")
        {
            ; stun_mult
            effectKey := "effect_string___2"
            split := StrSplit(kvps[effectKey], ",")
            stunTime := kvps["stun_time___3"]
            stunMult := split[2] / 100
            repl := stunMult * stunTime
        }
        else if (param1 == "dhani_boss_damage_bonus")
        {
            ; dhani_blotch_of_blue
            effectKey := "effect_string___3"
            split := StrSplit(kvps[effectKey], ",")
            repl := 800 * split[2] / 100
        }
        else if (param1 == "karlach_rage_max_stacks")
            repl := this.ValueIfKeyExists(kvps, "default_max_stacks___2")
        else if (param1 == "karlach_rage_reduce_percent")
            repl := this.ValueIfKeyExists(kvps, "default_reduce_percent___2")
        else if (param1 == "presto_component_scavenger_max")
        {
            startTime := "20240131120000"
            EnvSub, startTime, A_NowUTC, D
            repl := 2000 + 20 * Abs(startTime)
        }
        else if (param1 == "presto_component_scavenger_description")
            repl := ""
        else if (param1 == "strongheart_token_scavenger_max")
        {
            startTime := "20230628120000"
            EnvSub, startTime, A_NowUTC, D
            repl := 50000 + 300 * Abs(startTime)
        }
        else if (param1 == "strongheart_event_token_scavenger_description")
            repl := ""
        else if (param1 == "gromma_circle_of_the_mountain_target")
            repl := "Neutral (feat:Good)"
        else if (kvps.HasKey(param1)) ; amount
            repl := kvps[param1]
        return repl
    }

    ValueIfKeyExists(kvps, key, default := "NOREPL")
    {
        return kvps.HasKey(key) ? kvps[key] : default
    }
}