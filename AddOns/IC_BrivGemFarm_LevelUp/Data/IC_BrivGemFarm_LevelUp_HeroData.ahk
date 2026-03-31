; Class that contains all hero data
Class IC_BrivGemFarm_LevelUp_HeroData
{
    ID := ""
    Name := ""
    Seat_id := ""
    Last_rework_date := ""
    Upgrades := ""
    LastUpgradeLevel := ""
    UpgradesList := ""
    Ultimate_attack_id := ""

    __New(id, data)
    {
        for k, v in data
            this[k] := v
        this.ID := id
        upgradeDataClass := IC_BrivGemFarm_LevelUp_UpgradeData
        this.UpgradesList := upgradeDataClass.BuildUpgrades(this) ; + LastUpgradeLevel
    }

    UpgradeFromIndex(index)
    {
        upgradeID := this.Upgrades[index]
        upgradeData := g_HeroDefines.UpgradeDataByID(upgradeID)
        return upgradeData
    }

    UpgradeDescriptionFromIndex(index)
    {
        return this.UpgradeFromIndex(index).FullDescription()
    }
}