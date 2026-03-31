; Class that contains all text data
Class IC_BrivGemFarm_LevelUp_TextData
{
    GetData(key, default)
    {
        textDefines := g_HeroDefines.HeroDefines.text_defines
        return textDefines.HasKey(key) ? textDefines[key].contents : default
    }

    RarityFromIndex(id)
    {
        Switch id
        {
            Case 0:
                return this.GetData("rarity_trash", "Trash")
            Case 1:
                return this.GetData("rarity_common", "Common")
            Case 2:
                return this.GetData("rarity_uncommon", "Uncommon")
            Case 3:
                return this.GetData("rarity_rare", "Rare")
            Case 4:
                return this.GetData("rarity_epic", "Epic")
            Case 5:
                return this.GetData("rarity_epic", "Legendary")
        }
    }

    TimeString(key)
    {
        Switch key
        {
            case "day":
                return this.GetData("day_word", "day")
            case "hour":
                return this.GetData("hour_word", "hour")
            case "minute":
                return this.GetData("minute_word", "minute")
            case "second":
                return this.GetData("second_word", "second")
            case "dayPlur":
                return this.GetData("day_word_plural", "days")
            case "hourPlur":
                return this.GetData("hour_word_plural", "hours")
            case "minutePlur":
                return this.GetData("minute_word_plural", "minutes")
            case "secondPlur":
                return this.GetData("second_word_plural", "seconds")
            case "dayAbr":
                return this.GetData("day_word_abbreviated", "d")
            case "hourAbr":
                return this.GetData("hour_word_abbreviated", "h")
            case "minuteAbr":
                return this.GetData("minute_word_abbreviated", "m")
            case "secondAbr":
                return this.GetData("second_word_abbreviated", "s")
        }
    }

    EffectTargetDescriptions(key)
    {
        Switch key
        {
            case "self":
                return "$source"
            case "self_slot":
                return "$source"
            case "crusader":
                return "$(hero_name param0)"
            case "by_tags":
                return "BY_TAGS_PLEASE_FILL_IN"
            case "by_most_tags":
                return "BY_MOST_TAGS_PLEASE_FILL_IN"
            case "distance":
                return "WITHIN_DISTANCE_PLEASE_FILL_IN"
            case "pixel_distance":
                return "WITHIN_PIXEL_DISTANCE_PLEASE_FILL_IN"
            case "col":
                return this.GetData("champion_in_same_column", "Champion in the same column as $source")
            case "next_col":
                return this.GetData("champion_in_column_in_front", "Champion in the column in front of $source")
            case "prev_col":
                return this.GetData("champion_in_column_behind", "Champion in the column behind $source")
            case "prev_and_next_col":
                return this.GetData("champion_behind_and_in_front", "Champion in the column behind and in front of $source")
            case "adj":
                return this.GetData("champion_next_to", "Champion next to $source")
            case "non_adj":
                return this.GetData("champion_not_next_to", "Champion not next to $source")
            case "farthest_away":
                return this.GetData("champion_farthest_away", "Champion farthest away from $source")
            case "next_two_col":
                return this.GetData("champion_two_columns_in_front", "Champion in the two columns in front of $source")
            case "next_three_col":
                return this.GetData("champion_three_columns_in_front", "Champion in the three columns in front of $source")
            case "prev_two_col":
                return this.GetData("champion_two_columns_behind", "Champion in the two columns behind $source")
            case "prev_three_col":
                return this.GetData("champion_three_columns_behind", "Champion in the three columns behind $source")
            case "crusaders_col":
                return this.GetData("champion_in_same_column_as_hero", "Champion in the same column as $(hero_name param0)")
            case "front_col":
                return this.GetData("champion_in_front_most_column", "Champion in the front-most column")
            case "front_occupied_col":
                return this.GetData("champion_in_font_most_occupied", "Champion in the front-most occupied column")
            case "behind":
                return this.GetData("champion_behind_source", "Champion behind $source")
            case "ahead":
                return this.GetData("champion_ahead_of_source", "Champion ahead of $source")
            case "col_and_behind":
                return this.GetData("champion_behind_source_and_in_column", "Champion behind $source and in $source's column")
            case "col_and_ahead":
                return this.GetData("champion_ahead_of_source_and_in_column", "Champion ahead of $source and in $source's column")
            case "self_and_behind":
                return this.GetData("source_and_champion_behind", "$source, and Champion behind $source")
            case "self_and_ahead":
                return this.GetData("source_and_champion_ahead_of", "$source, and Champion ahead of $source")
        }
    }

    EffectTargetDescriptionsPlural(key)
    {
        Switch key
        {
            case "col":
                return this.GetData("champions_in_same_column", "Champions in the same column as $source")
            case "next_col":
                return this.GetData("champions_in_column_in_front", "Champions in the column in front of $source")
            case "prev_col":
                return this.GetData("champions_in_column_behind", "Champions in the column behind $source")
            case "prev_and_next_col":
                return this.GetData("champions_behind_and_in_front", "Champions in the column behind and in front of $source")
            case "all":
                return this.GetData("champions_in_formation", "all Champions in the formation")
            case "all_slots":
                return this.GetData("champions_in_formation", "all Champions in the formation")
            case "adj":
                return this.GetData("champions_next_to", "Champions next to $source")
            case "non_adj":
                return this.GetData("champions_not_next_to", "Champions not next to $source")
            case "farthest_away":
                return this.GetData("champions_farthest_away", "Champions farthest away from $source")
            case "next_two_col":
                return this.GetData("champions_two_columns_in_front", "Champions in the two columns in front of $source")
            case "next_three_col":
                return this.GetData("champions_three_columns_in_front", "Champions in the three columns in front of $source")
            case "prev_two_col":
                return this.GetData("champions_two_columns_behind", "Champions in the two columns behind $source")
            case "prev_three_col":
                return this.GetData("champions_three_columns_behind", "Champions in the three columns behind $source")
            case "crusaders_col":
                return this.GetData("champions_in_same_column_as_hero", "Champions in the same column as $(hero_name param0)")
            case "front_col":
                return this.GetData("champions_in_front_most_column", "Champions in the front-most column")
            case "front_occupied_col":
                return this.GetData("champions_in_font_most_occupied", "Champions in the front-most occupied column")
            case "behind":
                return this.GetData("champions_behind_source", "Champions behind $source")
            case "ahead":
                return this.GetData("champions_ahead_of_source", "Champions ahead of $source")
            case "col_and_behind":
                return this.GetData("champions_behind_source_and_in_column", "Champions behind $source and in $source's column")
            case "col_and_ahead":
                return this.GetData("champions_ahead_of_source_and_in_column", "Champions ahead of $source and in $source's column")
            case "self_and_behind":
                return this.GetData("source_and_champions_behind", "$source, and Champions behind $source")
            case "self_and_ahead":
                return this.GetData("source_and_champions_ahead_of", "$source, and Champions ahead of $source")
            case "other":
                return this.GetData("all_other_champions_in_formation", "all other Champions in the formation")
            case "edge":
                return this.GetData("champions_at_edge", "Champions at the edge of the formation")
            case "front_2_columns":
                return this.GetData("champions_in_front_two_columns", "Champions in the front two columns of the formation")
            case "back_2_columns":
                return this.GetData("champions_in_back_two_columns", "Champions in the back two columns of the formation")
            case "front_3_columns":
                return this.GetData("champions_in_front_three_columns", "Champions in the front three columns of the formation")
            case "back_3_columns":
                return this.GetData("champions_in_back_three_columns", "Champions in the back three columns of the formation")
            case "col_num":
                return this.GetData("champions_in_specific_column", "Champions in a specific column")
            case "middle_columns":
                return this.GetData("champions_in_middle_columns", "Champions in the middle columns of the formation")
            case "back_column":
                return this.GetData("champions_in_rearmost_column", "Champions in the rearmost column of the formation")
            case "col_top":
                return this.GetData("champions_in_topmost_slot", "Champions in the topmost slot of each column")
            case "col_bottom":
                return this.GetData("champions_in_bottommost_slot", "Champions in the bottommost slot of each column")
        }
    }
}