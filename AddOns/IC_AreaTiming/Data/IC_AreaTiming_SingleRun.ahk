#include %A_LineFile%\..\IC_AreaTiming_TimeObject.ahk

Class IC_AreaTiming_SingleRun
{
    ID := 0
    SessionID := 0
    Items := []
    StackItems := []
    StartTime := 0
    CurrentZone := 0
    Ended := false

    ; Create a new object that contains data for a single run.
    ; Params: - id:int - Run identifier for the session.
    ;         - session:IC_AreaTiming_RunCollection - Session where the run is being recoded.
    __New(id, session)
    {
        this.StartTime := IC_AreaTiming_TimeObject.GetCurrentMSecTime()
        this.ID := ID
        this.SessionID := session.ID
    }

    ; Add a time object to the current run.
    ; Params: - obj:IC_AreaTiming_TimeObject - Time object that contains
    ;           timestamps for area start, zone clear and transition end.
    AddItem(ByRef obj)
    {
        this.CurrentZone := obj.EndZone ? obj.EndZone : obj.StartZone
        timeStamp := obj.AreaStartTimeStamp
        VarSetCapacity(buffer%timeStamp%, 36, 0)
        this.ConvertObjToStruct(obj, buffer%timeStamp%)
        this.Items.Push(&buffer%timeStamp%)
        g_AT_SharedData.CurrentSession.UpdateTotals(this, &buffer%timeStamp%)
    }

    ; Add a stacks time object to the current run.
    ; Params: - obj:IC_AreaTiming_StacksTimeObject - Time object that contains
    ;           timestamps for area start, zone clear and transition end.
    AddStacksItem(ByRef obj)
    {
        timeStamp := obj.AreaStartTimeStamp
        VarSetCapacity(buffer%timeStamp%, 40, 0)
        this.ConvertObjToStruct(obj, buffer%timeStamp%, true)
        this.StackItems.Push(&buffer%timeStamp%)
        g_AT_SharedData.CurrentSession.UpdateTotalsStack(this, &buffer%timeStamp%)
    }

    ; Struct - TimeObject: 28 bytes | StacksTimeObject: 32 bytes
    ; - TimeObject
    ; ?? - 2 bytes
    ; Zones:UInt - 4 bytes (Max area = 65535)
    ; AreaStartTimeStamp:UInt+UShort - 6 bytes
    ; AreaCompleteTimeStamp:UInt+UShort - 6 bytes
    ; AreaTransitionedTimeStamp:UInt+UShort - 6 bytes
    ; GameSpeed:Float - 4 bytes
    ; - StacksTimeObject
    ; Stacks:UInt - 4 bytes
    ConvertObjToStruct(ByRef obj, ByRef buffer, isStackItem := false)
    {
        NumPut(obj.EndZone, buffer, 2, "UShort")
        NumPut(obj.StartZone, buffer, 4, "UShort")
        timestamp := obj.GetSplittedTimeStamp(obj.AreaStartTimeStamp)
        NumPut(timestamp[1], buffer, 6, "UInt")
        NumPut(timestamp[2], buffer, 10, "UShort")
        timestamp := obj.GetSplittedTimeStamp(obj.AreaCompleteTimeStamp)
        NumPut(timestamp[1], buffer, 12, "UInt")
        NumPut(timestamp[2], buffer, 16, "UShort")
        timestamp := obj.GetSplittedTimeStamp(obj.AreaTransitionedTimeStamp)
        NumPut(timestamp[1], buffer, 18, "UInt")
        NumPut(timestamp[2], buffer, 22, "UShort")
        NumPut(obj.GameSpeed, buffer, 24, "Float")
        NumPut(obj.HStacks, buffer, 28, "UInt")
        NumPut(obj.SBStacks, buffer, 32, "UInt")
        if (isStackItem)
            NumPut(obj.Stacks, buffer, 36, "UInt")
    }

    GetItemStartZone(index)
    {
        return NumGet(this.Items[index], 4, "UShort")
    }

    GetItemEndZone(index)
    {
        return NumGet(this.Items[index], 2, "UShort")
    }

    GetItemZones(index)
    {
        return NumGet(this.Items[index], 2, "UInt")
    }

    GetItemMod50StartZone(index)
    {
        mod50Start := Mod(this.GetItemStartZone(index), 50)
        mod50Start := mod50Start ? mod50Start : 50
        return mod50Start
    }

    GetItemMod50EndZone(index)
    {
        mod50End := Mod(this.GetItemEndZone(index), 50)
        mod50End := mod50End ? mod50End : 50
        return mod50End
    }

    GetItemMod50Zones(index)
    {
        return (this.GetItemMod50StartZone(index) << 16) + this.GetItemMod50EndZone(index)
    }

    GetItemAreaStartTimeStamp(index)
    {
        return NumGet(this.Items[index], 6, "UInt") * 1000 + NumGet(this.Items[index], 10, "UShort")
    }

    GetItemAreaCompleteTimeStamp(index)
    {
        return NumGet(this.Items[index], 12, "UInt") * 1000 + NumGet(this.Items[index], 16, "UShort")
    }

    GetItemAreaTransitionedTimeStamp(index)
    {
        return NumGet(this.Items[index], 18, "UInt") * 1000 + NumGet(this.Items[index], 22, "UShort")
    }

    GetItemAreaTime(index)
    {
        return this.GetItemAreaCompleteTimeStamp(index) - this.GetItemAreaStartTimeStamp(index)
    }

    GetItemTransitionTime(index)
    {
        return this.GetItemAreaTransitionedTimeStamp(index) - this.GetItemAreaCompleteTimeStamp(index)
    }

    GetItemTotalTime(index)
    {
        return this.GetItemAreaTransitionedTimeStamp(index) - this.GetItemAreaStartTimeStamp(index)
    }

    GetItemGameSpeed(index)
    {
        return NumGet(this.Items[index], 24, "Float")
    }

    GetItemHStacks(index)
    {
        return NumGet(this.Items[index], 28, "UInt")
    }

    GetItemSBStacks(index)
    {
        return NumGet(this.Items[index], 32, "UInt")
    }

    GetStackItemStartZone(index)
    {
        return NumGet(this.StackItems[index], 4, "UShort")
    }

    GetStackItemEndZone(index)
    {
        return NumGet(this.StackItems[index], 2, "UShort")
    }

    GetStackItemZones(index)
    {
        return NumGet(this.StackItems[index], 2, "UInt")
    }

    GetStackItemMod50StartZone(index)
    {
        mod50Start := Mod(this.GetStackItemStartZone(index), 50)
        mod50Start := mod50Start ? mod50Start : 50
        return mod50Start
    }

    GetStackItemMod50EndZone(index)
    {
        mod50End := Mod(this.GetStackItemEndZone(index), 50)
        mod50End := mod50End ? mod50End : 50
        return mod50End
    }

    GetStackItemMod50Zones(index)
    {
        return (this.GetStackItemMod50StartZone(index) << 16) + this.GetStackItemMod50EndZone(index)
    }

    GetStackItemAreaStartTimeStamp(index)
    {
        return NumGet(this.StackItems[index], 6, "UInt") * 1000 + NumGet(this.StackItems[index], 10, "UShort")
    }

    GetStackItemAreaCompleteTimeStamp(index)
    {
        return NumGet(this.StackItems[index], 12, "UInt") * 1000 + NumGet(this.StackItems[index], 16, "UShort")
    }

    GetStackItemAreaTransitionedTimeStamp(index)
    {
        return NumGet(this.StackItems[index], 18, "UInt") * 1000 + NumGet(this.StackItems[index], 22, "UShort")
    }

    GetStackItemAreaTime(index)
    {
        return this.GetStackItemAreaCompleteTimeStamp(index) - this.GetStackItemAreaStartTimeStamp(index)
    }

    GetStackItemTransitionTime(index)
    {
        return this.GetStackItemAreaTransitionedTimeStamp(index) - this.GetStackItemAreaCompleteTimeStamp(index)
    }

    GetStackItemTotalTime(index)
    {
        return this.GetStackItemAreaTransitionedTimeStamp(index) - this.GetStackItemAreaStartTimeStamp(index)
    }

    GetStackItemGameSpeed(index)
    {
        return NumGet(this.StackItems[index], 24, "Float")
    }

    GetStackItemHStacks(index)
    {
        return NumGet(this.StackItems[index], 28, "UInt")
    }

    GetStackItemSBStacks(index)
    {
        return NumGet(this.StackItems[index], 32, "UInt")
    }

    GetStackItemStacks(index)
    {
        return NumGet(this.StackItems[index], 36, "UInt")
    }

    ; Dispose of all timeObjects.
    Clear()
    {
        items := this.Items
        Loop, % items.Length()
            items[A_Index] := ""
        VarSetCapacity(items, 0)
        items := this.StackItems
        Loop, % items.Length()
            items[A_Index] := ""
        VarSetCapacity(items, 0)
    }

    ; Mark this run as finished.
    EndRun()
    {
        this.Ended := true
    }
}