; Constants used by IC_BrivGemFarm_LevelUp_HeroDefinesLoader
Class IC_BrivGemFarm_LevelUp_HeroDefinesLoaderConstants
{
    ; Parser version
    static Version := "1.3.3"
    ; File locations
    static HeroDefsPath := A_LineFile . "\..\..\HeroDefines.json"
    static LastGUIDPath := A_LineFile . "\..\LastGUID_BrivGemFarm_LevelUp.json"
    static WorkerPath := A_LineFile . "\..\IC_BrivGemFarm_LevelUp_HeroDefinesLoader_Run.ahk"
    static LoaderTempPath := A_LineFile . "\..\LastTableChecksums.txt"
    ; Filters
    static TableFilter := "table_checksums"
    static HeroFilter := "hero_defines"
    static UpgradeFilter := "upgrade_defines"
    static EffectFilter := "effect_defines"
    static EffectKeyFilter := "effect_key_defines"
    static AttackFilter := "attack_defines"
    static TextFilter := "text_defines"
    ; Loader states
    static STOPPED := 0
    static GET_PLAYSERVER := 1
    static CHECK_TABLECHECKSUMS := 2
    static FILE_PARSING := 3
    static TEXT_DEFS := 4
    static HERO_DEFS := 5
    static ATTACK_DEFS := 6
    static UPGRADE_DEFS := 7
    static EFFECT_DEFS := 8
    static EFFECT_KEY_DEFS := 9
    static FILE_SAVING := 10
    static HERO_DATA_FINISHED := 100
    static HERO_DATA_FINISHED_NOUPDATE := 101
    static SERVER_TIMEOUT := 200
    static DEFS_LOAD_FAIL := 201
    static LOADER_FILE_MISSING := 202
}