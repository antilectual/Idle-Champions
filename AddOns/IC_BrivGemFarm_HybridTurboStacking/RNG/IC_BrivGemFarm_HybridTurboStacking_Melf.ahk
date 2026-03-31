#include %A_LineFile%\..\..\..\..\SharedFunctions\CSharpRNG.ahk

; TODO: take into account preferred zones
Class IC_BrivGemFarm_HybridTurboStacking_Melf
{
    static MAX_ZONE := 2501

    GetCurrentEffectIndex()
    {
        rng := new CSharpRNG(g_SF.Memory.ReadResetsTotal() * 10)
		num := Ceil(g_SF.Memory.ReadCurrentZone() / 50)
	    Loop, % num
		    result := rng.NextRange(0, 3)
	    return result
    }

    IsCurrentEffectSpawnMore()
    {
        return this.GetCurrentEffectIndex() == 0
    }

    GetFirstSpawnMoreEffectRange(reset := "", min := 1, max := 2550)
    {
        if (reset == "")
            reset := g_SF.Memory.ReadResetsTotal()
        if (reset == "")
            return 0
        rng := new CSharpRNG(reset * 10)
        firstZoneInRange := 50 * Floor(min / 50) + 1
        k := 0
        while (true)
        {
            firstZone:= k++ * 50 + 1
            if (firstZone > max)
                break
            lastZone := firstZone + 49
		    result := rng.NextRange(0, 3)
		    if (result == 0 && firstZoneInRange <= firstZone)
		        return [firstZone, lastZone]
		}
		return 0
    }

    GetAllEffects(reset := "")
    {
        if (reset == "")
            reset := g_SF.Memory.ReadResetsTotal()
        if (reset == "")
            return ""
        result := []
        rng := new CSharpRNG(reset * 10)
        num := Ceil(this.MAX_ZONE / 50)
        Loop, % num
		    result[A_Index] := rng.NextRange(0, 3)
		return result
    }

    GetNumberOfSuccessesInRange(resets := "", next := 1000, min := 1, max := 2550)
    {
        if (resets == "")
            resets := g_SF.Memory.ReadResetsTotal()
        successes := 0
        Loop, % next
        {
            reset := resets + A_Index - 1
            range := this.GetFirstSpawnMoreEffectRange(reset, min, max)
            if (range != 0)
                successes += 1
        }
        return successes
    }
}