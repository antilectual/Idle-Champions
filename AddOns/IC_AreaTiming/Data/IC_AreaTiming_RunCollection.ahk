#include %A_LineFile%\..\IC_AreaTiming_SingleRun.ahk

Class IC_AreaTiming_RunCollection
{
    ID := 0
    StartTime := 0
    Runs := []
    CurrentRun := ""
    ; Higher that that and read/write operations become much slower.
    MaxRuns := 4000
    ; Cached totals
    Totals := {}
    TotalsMod50 := {}
    TotalsStack := {}

    __New(id)
    {
        this.StartTime := IC_AreaTiming_TimeObject.GetCurrentMSecTime()
        this.ID := id
    }

    NewRun()
    {
        runCount := this.Runs.Length()
        if (runCount >= this.MaxRuns)
            return g_AT_SharedData.NewSession().NewRun()
        run := new IC_AreaTiming_SingleRun(runCount + 1, this.ID)
        this.CurrentRun := run
        this.Runs.Push(run)
        return run
    }

    ; Dispose of all runs.
    Clear()
    {
        this.CurrentRun := ""
        items := this.Runs
        Loop, % items.Length()
        {
            items[A_Index].Clear()
            items[A_Index] := ""
        }
        VarSetCapacity(items, 0)
    }

    ; Update cached totals for all items.
    UpdateTotals(run, ptr)
    {
        totals := this.Totals
        key := this.GetItemZones(ptr)
        if (!totals.HasKey(key))
            totals[key] := [0, 0, 0, 0, 0, 0]
        arr := totals[key]
        arr[1] += 1
        arr[2] += this.GetItemAreaTime(ptr)
        arr[3] += this.GetItemTransitionTime(ptr)
        arr[4] += this.GetItemTotalTime(ptr)
        ; Prevent overflow
        runTime := this.GetItemAreaTransitionedTimeStamp(ptr) - run.StartTime
        arr[5] += runTime
        arr[6] += this.GetItemGameSpeed(ptr)
        ; Mod50
        mod50Totals:= this.TotalsMod50
        key := this.GetItemMod50Zones(ptr)
        if (!mod50Totals.HasKey(key))
            mod50Totals[key] := [0, 0, 0, 0, 0, 0]
        arr := mod50Totals[key]
        arr[1] += 1
        arr[2] += this.GetItemAreaTime(ptr)
        arr[3] += this.GetItemTransitionTime(ptr)
        arr[4] += this.GetItemTotalTime(ptr)
    }

    ; Update cached totals for all stack items.
    UpdateTotalsStack(run, ptr)
    {
        totals := this.TotalsStack
        key := this.GetStackItemZones(ptr)
        if (!totals.HasKey(key))
            totals[key] := [0, 0, 0, 0, 0, 0, 0]
        arr := totals[key]
        arr[1] += 1
        arr[2] += this.GetStackItemAreaTime(ptr)
        arr[3] += this.GetStackItemTransitionTime(ptr)
        arr[4] += this.GetStackItemTotalTime(ptr)
        ; Prevent overflow
        runTime := this.GetStackItemAreaTransitionedTimeStamp(ptr) - run.StartTime
        arr[5] += runTime
        arr[6] += this.GetStackItemGameSpeed(ptr)
        arr[7] += this.GetStackItemStacks(ptr)
    }

    FindItemFromZones(run, key)
    {
        items := run.Items
        low := 1
        high := items.Length()
        while (low <= high && key >= run.GetItemZones(low) && key <= run.GetItemZones(high))
        {
            pos := low + Floor(((key - run.GetItemZones(low)) * (high - low)) / (run.GetItemZones(high) - run.GetItemZones(low)))
            if (run.GetItemZones(pos) == key)
                return items[pos]
            if (run.GetItemZones(pos) > key)
                high := pos - 1
            else
                low := pos + 1
        }
        return ""
    }

    FindItemFromStartZone(run, key)
    {
        items := run.Items
        low := 1
        high := items.Length()
        while (low <= high && key >= run.GetItemStartZone(low) && key <= run.GetItemStartZone(high))
        {
            pos := low + Floor(((key - run.GetItemStartZone(low)) * (high - low)) / (run.GetItemStartZone(high) - run.GetItemStartZone(low)))
            if (run.GetItemStartZone(pos) == key)
                return items[pos]
            if (run.GetItemStartZone(pos) > key)
                high := pos - 1
            else
                low := pos + 1
        }
        return ""
    }

    ; Get all unique IC_AreaTiming_TimeObject.Zones keys from all runs.
    ; Returns: - array - All keys (IC_AreaTiming_TimeObject.Zones).
    GetAllItemKeys()
    {
        keys := []
        keysObj := {}
        runs := this.Runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            Loop, % run.Items.Length()
            {
                key := run.GetItemZones(A_Index)
                if (!keysObj.HasKey(key))
                    keysObj[key] := ""
            }
        }
        ; Return sorted keys
        for k, v in keysObj
            keys.Push(k)
        VarSetCapacity(keysObj, 0)
        return keys
    }

    ; Get all unique IC_AreaTiming_TimeObject.Zones keys from all runs.
    ; Returns: - array - All keys (IC_AreaTiming_TimeObject.Zones).
    GetAllMod50ItemKeys(run := "")
    {
        keys := []
        if (IsObject(run))
        {
            keysObj := {}
            Loop, % run.Items.Length()
            {
                key := run.GetItemMod50Zones(A_Index)
                if (!keysObj.HasKey(key))
                    keysObj[key] := ""
            }
            ; Return sorted keys
            for k, v in keysObj
                keys.Push(k)
            VarSetCapacity(keysObj, 0)
            return keys
        }
        else
        {
            for k in this.TotalsMod50
                keys.Push(k)
            return keys
        }
    }

    ; Get all unique IC_AreaTiming_StacksTimeObject.Zones keys from all runs.
    ; Returns: - array:keys - All keys (IC_AreaTiming_StacksTimeObject.Zones).
    GetAllStackItemKeys()
    {
        keys := []
        keysObj := {}
        runs := this.Runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            Loop, % run.StackItems.Length()
            {
                key := run.GetStackItemZones(A_Index)
                if (!keysObj.HasKey(key))
                    keysObj[key] := ""
            }
        }
        ; Return sorted keys
        for k, v in keysObj
            keys.Push(k)
        VarSetCapacity(keysObj, 0)
        return keys
    }

    ; Get total stats from all runs.
    ; Params: - key:int - IC_AreaTiming_TimeObject.Zones.
    GetTotals(key)
    {
        return this.Totals[key]
    }

    ; Get total stats from all runs.
    ; Params: - run:IC_AreaTiming_SingleRun - Get key/values in <run> only.
    ; Returns: - array: keys - All allTotals keys (IC_AreaTiming_TimeObject.Zones)
    ;                   allTotals - All object data.
    GetAllTotals(run := "")
    {
        allTotals := []
        keys := []
        if (IsObject(run))
        {
            totals := this.Totals
            for k, v in run.Items
            {
                key := this.GetItemZones(v)
                if (totals.Haskey(key))
                {
                    keys.Push(key)
                    allTotals.Push(totals[key])
                }
            }
        }
        else
        {
            for k, v in this.Totals
            {
                keys.Push(k)
                allTotals.Push(v)
            }
        }
        ; Return value
        return [keys, allTotals]
    }

    ; Get average mod50 stats from all runs.
    ; Params: key:int - IC_AreaTiming_TimeObject.Mod50Zones.
    ;         runs:array - List of runs, default to all runs from this session.
    ; Returns: - arr:array - All mod50 average data.
    GetTotalsMod50(key, runs := "", excludeOutliers := false)
    {
        if (excludeOutliers)
            return this.GetTotalsMod50Ex(key, runs)
        if (!IsObject(runs))
            return this.TotalsMod50[key]
        count := 0
        sumAreaTime := 0
        sumTransitionTime := 0
        sumTime := 0
        ; Loop all runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            ; Loop all items
            Loop, % run.Items.Length()
            {
                if (run.GetItemMod50Zones(A_Index) == key)
                {
                    ++count
                    sumAreaTime += run.GetItemAreaTime(A_Index)
                    sumTransitionTime += run.GetItemTransitionTime(A_Index)
                    sumTime += run.GetItemTotalTime(A_Index)
                }
            }
        }
        ; Return value
        return [count, sumAreaTime, sumTransitionTime, sumTime]
    }

    ; Get average mod50 stats from all runs.
    ; Exclude z1, stacking area and reset from result.
    ; Params: key:int - IC_AreaTiming_TimeObject.Mod50Zones.
    ;         runs:array - List of runs, default to all runs from this session.
    ; Returns: - arr:array - All mod50 average data.
    GetTotalsMod50Ex(key, runs := "")
    {
        totals := this.GetTotalsMod50(key, runs)
        runs := IsObject(runs) ? runs : this.Runs
        count := totals[1]
        sumAreaTime := totals[2]
        sumTransitionTime := totals[3]
        sumTime := totals[4]
        ; Loop all runs
        Loop, % runs.Length()
        {
            run := runs[A_Index]
            ; Exclude start area
            if (run.GetItemStartZone(1) == 1 && run.GetItemMod50Zones(1) == key)
            {
                --count
                sumAreaTime -= run.GetItemAreaTime(1)
                sumTransitionTime -= run.GetItemTransitionTime(1)
                sumTime -= run.GetItemTotalTime(1)
            }
            ; Exclude reset area
            maxIndex :=  run.Items.Length()
            if (run.GetItemEndZone(maxIndex) == 1 && run.GetItemMod50Zones(maxIndex) == key)
            {
                --count
                sumAreaTime -= run.GetItemAreaTime(maxIndex)
                sumTransitionTime -= run.GetItemTransitionTime(maxIndex)
                sumTime -= run.GetItemTotalTime(maxIndex)
            }
            ; Exclude stack areas
            stackKeys := {}
            Loop, % run.StackItems.Length()
            {
                itemStartZone := run.GetStackItemStartZone(A_Index)
                if (!stackKeys.HasKey(itemStartZone))
                {
                    stackKeys[itemStartZone] := ""
                    ptr := this.FindItemFromStartZone(run, itemStartZone)
                    if (ptr && this.GetItemMod50Zones(ptr) == key)
                    {
                        --count
                        sumAreaTime -= this.GetItemAreaTime(ptr)
                        sumTransitionTime -= this.GetItemTransitionTime(ptr)
                        sumTime -= this.GetItemTotalTime(ptr)
                    }
                }
            }
        }
        VarSetCapacity(stackKeys, 0)
        ; Return value
        return [count, sumAreaTime, sumTransitionTime, sumTime]
    }

    ; Get total stack stats from all runs.
    ; Params: key:int - IC_AreaTiming_StackTimeObject.Zones.
    GetTotalsStack(key)
    {
        return this.TotalsStack[key]
    }

    ; Get total stack stats from all runs.
    ; Returns: - arr: keys - All allTotals keys (IC_AreaTiming_StackTimeObject.Zones)
    ;                 allTotals - All object data.
    GetAllTotalsStack()
    {
        allTotals := []
        keys := []
        for k, v in this.TotalsStack
        {
            keys.Push(k)
            allTotals.Push(v)
        }
        ; Return value
        return [keys, allTotals]
    }

    GetItemStartZone(ptr)
    {
        return NumGet(ptr+0, 4, "UShort")
    }

    GetItemEndZone(ptr)
    {
        return NumGet(ptr+0, 2, "UShort")
    }

    GetItemZones(ptr)
    {
        return NumGet(ptr+0, 2, "UInt")
    }

    GetItemMod50StartZone(ptr)
    {
        mod50Start := Mod(this.GetItemStartZone(ptr), 50)
        mod50Start := mod50Start ? mod50Start : 50
        return mod50Start
    }

    GetItemMod50EndZone(ptr)
    {
        mod50End := Mod(this.GetItemEndZone(ptr), 50)
        mod50End := mod50End ? mod50End : 50
        return mod50End
    }

    GetItemMod50Zones(ptr)
    {
        return (this.GetItemMod50StartZone(ptr) << 16) + this.GetItemMod50EndZone(ptr)
    }

    GetItemAreaStartTimeStamp(ptr)
    {
        return NumGet(ptr+0, 6, "UInt") * 1000 + NumGet(ptr+0, 10, "UShort")
    }

    GetItemAreaCompleteTimeStamp(ptr)
    {
        return NumGet(ptr+0, 12, "UInt") * 1000 + NumGet(ptr+0, 16, "UShort")
    }

    GetItemAreaTransitionedTimeStamp(ptr)
    {
        return NumGet(ptr+0, 18, "UInt") * 1000 + NumGet(ptr+0, 22, "UShort")
    }

    GetItemAreaTime(ptr)
    {
        return this.GetItemAreaCompleteTimeStamp(ptr) - this.GetItemAreaStartTimeStamp(ptr)
    }

    GetItemTransitionTime(ptr)
    {
        return this.GetItemAreaTransitionedTimeStamp(ptr) - this.GetItemAreaCompleteTimeStamp(ptr)
    }

    GetItemTotalTime(ptr)
    {
        return this.GetItemAreaTransitionedTimeStamp(ptr) - this.GetItemAreaStartTimeStamp(ptr)
    }

    GetItemGameSpeed(ptr)
    {
        return NumGet(ptr+0, 24, "Float")
    }

    GetItemHStacks(ptr)
    {
        return NumGet(ptr+0, 28, "UInt")
    }

    GetItemSBStacks(ptr)
    {
        return NumGet(ptr+0, 32, "UInt")
    }

    GetStackItemStartZone(ptr)
    {
        return NumGet(ptr+0, 4, "UShort")
    }

    GetStackItemEndZone(ptr)
    {
        return NumGet(ptr+0, 2, "UShort")
    }

    GetStackItemZones(ptr)
    {
        return NumGet(ptr+0, 2, "UInt")
    }

    GetStackItemMod50StartZone(ptr)
    {
        mod50Start := Mod(this.GetStackItemStartZone(ptr), 50)
        mod50Start := mod50Start ? mod50Start : 50
        return mod50Start
    }

    GetStackItemMod50EndZone(ptr)
    {
        mod50End := Mod(this.GetStackItemEndZone(ptr), 50)
        mod50End := mod50End ? mod50End : 50
        return mod50End
    }

    GetStackItemMod50Zones(ptr)
    {
        return (this.GetStackItemMod50StartZone(ptr) << 16) + this.GetStackItemMod50EndZone(ptr)
    }

    GetStackItemAreaStartTimeStamp(ptr)
    {
        return NumGet(ptr+0, 6, "UInt") * 1000 + NumGet(ptr+0, 10, "UShort")
    }

    GetStackItemAreaCompleteTimeStamp(ptr)
    {
        return NumGet(ptr+0, 12, "UInt") * 1000 + NumGet(ptr+0, 16, "UShort")
    }

    GetStackItemAreaTransitionedTimeStamp(ptr)
    {
        return NumGet(ptr+0, 18, "UInt") * 1000 + NumGet(ptr+0, 22, "UShort")
    }

    GetStackItemAreaTime(ptr)
    {
        return this.GetStackItemAreaCompleteTimeStamp(ptr) - this.GetStackItemAreaStartTimeStamp(ptr)
    }

    GetStackItemTransitionTime(ptr)
    {
        return this.GetStackItemAreaTransitionedTimeStamp(ptr) - this.GetStackItemAreaCompleteTimeStamp(ptr)
    }

    GetStackItemTotalTime(ptr)
    {
        return this.GetStackItemAreaTransitionedTimeStamp(ptr) - this.GetStackItemAreaStartTimeStamp(ptr)
    }

    GetStackItemGameSpeed(ptr)
    {
        return NumGet(ptr+0, 24, "Float")
    }

    GetStackItemHStacks(ptr)
    {
        return NumGet(ptr+0, 28, "UInt")
    }

    GetStackItemSBStacks(ptr)
    {
        return NumGet(ptr+0, 32, "UInt")
    }

    GetStackItemStacks(ptr)
    {
        return NumGet(ptr+0, 36, "UInt")
    }
}