; Class that allows to group controls under a GroupBox control.
Class IC_BrivGemFarm_LevelUp_GUI_Group extends IC_BrivGemFarm_LevelUp_GUI_Control
{
    static GroupsByName := {}

    ControlID := ""
    Controls := []
    ControlsByName := {}
    Height := 0
    Width := 0
    XSpacing := 10
    YSpacing := 10
    YTitleSpacing := 20
    XSection := 10
    YSection := 10
    Borderless := false
    RightAlignWithMain := true

    ; Creates a new GroupBox.
    ; Parameters: - name:str - The name/reference of the group.
    ;             - title:str - The title of the control that will appear on the outline.
    ;             - group:str - The group that contanis this group.
    ;             - tabS:bool - If true, adds an x offset to this group from the previous control equal to XSection.
    ;             - newLine:bool - If true, position the group under the previous control.
    ;             - previous:str - The reference control that is used to position the new group.
    __New(name, title := "", group := "BGFLU_DefaultSettingsGroup", tabS := true, newLine := true, previous := "")
    {
        this.ControlID := name
        previous := previous != "" ? previous : group
        GuiControlGet, previousPos, ICScriptHub:Pos, %previous%
        groupX := previousPosX + (tabS ? this.XSection : 0) + (newLine ? 0 : previousPosW)
        options := "Section w0 h10 v" . name . " x" . groupX
        ySpacing := previousPosY + previousPosH + (newLine ? this.YSpacing : 0)
        options .= " y" . (newLine ? ySpacing : "s")
        Gui, ICScriptHub:Font, w700
        base.__New(name, "GroupBox", options, title, IC_BrivGemFarm_LevelUp_GUI_Group.GroupsByName[group])
        Gui, ICScriptHub:Font, w400
        IC_BrivGemFarm_LevelUp_GUI_Group.GroupsByName[name] := this
    }

    ; Creates and adds a control to the GroupBox.
    ; Parameters: - controlID:str - The name/reference of the control.
    ;             - controlType:str - The type of the control.
    ;             - options:str - Options to apply to the control. X/Y positionals override the default values.
    ;             - text:str - The initial text of the control.
    ;             - newLine:bool - If true, position the control under the previous ones.
    AddControl(controlID, controlType, options := "", text := "", newLine := false)
    {
        if (controlID == "")
            return
        if (!RegExMatch(options, "\bx(\d+|\+|\-|m|p|s[^\s])"))
        {
            if (newLine)
                options .= " xs+" . this.XSection
            else
                options .= " x+" . this.XSpacing
        }
        if (!RegExMatch(options, "\by(\d+|\+|\-|m|p|s[^\s])"))
        {
            if (this.Controls.Length() == 0)
                options .= " ys+" . this.YTitleSpacing
            else if (newLine)
                options .= " y+" . this.YSpacing
        }
        if (controlType != "")
            control := new IC_BrivGemFarm_LevelUp_GUI_Control(controlID, controlType, options, text, this)
        this.Controls.Push(control)
        this.ControlsByName[controlID] := control
    }

    ; Adds a previously created control to this group.
    AddExistingControl(control)
    {
        this.Controls.Push(control)
        this.ControlsByName[control.ControlID] := control
    }

    ; Creates and adds a CheckBox control to the GroupBox.
    ; The function BGFLU_CheckBoxEvent handles Checkbox events.
    AddCheckBox(controlID, saveSetting := true, options := "", text := "", newLine := false)
    {
        if (saveSetting)
            options .= " gBGFLU_CheckBoxEvent"
        return this.AddControl(controlID, "CheckBox", options, text, newLine)
    }

    ; Creates and adds a Edit control to the GroupBox.
    ; The function BGFLU_EditEvent handles Edit events.
    AddEdit(controlID, saveSetting := true, options := "", text := "", newLine := false)
    {
        if (saveSetting)
            options .= " gBGFLU_EditEvent"
        return this.AddControl(controlID, "Edit", options, text, newLine)
    }

    ; Returns the control that precedes control in this group.
    GetPreviousControl(control)
    {
        for k, v in this.Controls
        {
            if (v == control AND k > 1)
                return this.Controls[k - 1]
        }
        return this
    }

    ; Returns the control that follows control in this group.
    GetNextControl(control)
    {
        for k, v in this.Controls
        {
            if (v == control AND k < this.Controls.Length())
                return this.Controls[k + 1]
        }
        return this
    }

    ; Show the GroupBox outline and its controls.
    Show()
    {
        for k, v in this.Controls
            v.Show()
        if (!this.Borderless)
            base.Show()
    }

    ; Hide the GroupBox outline and its controls.
    Hide()
    {
        for k, v in this.Controls
            v.Hide()
        base.Hide()
    }

    ; Moves the GroupBox outline and its controls to a new position.
    ; Parameters: - x:int - New X postion of the GroupBox.
    ;             - y:int - New Y postion of the GroupBox.
    Move(x := "", y := "")
    {
        controlID := this.ControlID
        GuiControlGet, oldPos, ICScriptHub:Pos, %controlID%
        x := x == "" ? oldPosX : x
        y := y == "" ? oldPosY : y
        if (x == oldPosX AND y == oldPosY)
            return
        GuiControl, ICScriptHub:Move, %controlID%, x%x% y%y%
        ; Bug when using Move in a Tab control
        GuiControlGet, bugPos, ICScriptHub:Pos, %controlID%
        xFixBug := 2 * x - bugPosX
        yFixBug := 2 * y - bugPosY
        xOffset := xFixBug - oldPosX
        yOffset := yFixBug - oldPosY
        GuiControl, ICScriptHub:MoveDraw, %controlID%, x%xFixBug% y%yFixBug%
        this.MoveControls(xOffset, yOffset)
    }

    ; Moves the GroupBox controls to a new position.
    ; Parameters: - xOffset:int - New X postion of the controls.
    ;             - yOffset:int - New Y postion of the controls.
    MoveControls(xOffset := 0, yOffset := 0)
    {
        for k, v in this.ControlsByName
        {
            GuiControlGet, oldPos, ICScriptHub:Pos, %k%
            newX := oldPosX + xOffset
            newY := oldPosY + yOffset
            if (v.ControlsByName)
                v.MoveControls(xOffset, yOffset)
            GuiControl, ICScriptHub:MoveDraw, %k%, x%newX% y%newY%
        }
    }

    ; Returns the control with the lowest Y position within the GroupBox.
    ; Ignores controls that have been previousy hidden.
    GetLowestControl()
    {
        yMax := 0
        lowest := ""
        groupsByName := IC_BrivGemFarm_LevelUp_GUI_Group.GroupsByName
        for k, v in this.ControlsByName
        {
            if (v.Hidden)
                continue
            ; Subgroup
            if (groupsByName.HasKey(k))
            {
                controlID := groupsByName[k].GetLowestControl()
                GuiControlGet, pos, ICScriptHub:Pos, %controlID%
                if (posY + posH > yMax)
                {
                    yMax := posY + posH
                    lowest := controlID
                }
            }
            GuiControlGet, pos, ICScriptHub:Pos, %k%
            if (posY + posH > yMax)
            {
                yMax := posY + posH
                lowest := k
            }
        }
        return lowest
    }

    ; Returns the control with the furthest X position within the GroupBox.
    ; Ignores controls that have been previousy hidden.
    GetRightMostControl()
    {
        xMax := 0
        rightMost := ""
        groupsByName := IC_BrivGemFarm_LevelUp_GUI_Group.GroupsByName
        for k, v in this.ControlsByName
        {
            if (v.Hidden)
                continue
            ; Subgroup
            if (groupsByName.HasKey(k))
            {
                controlID := groupsByName[k].GetRightMostControl()
                GuiControlGet, pos, ICScriptHub:Pos, %controlID%
                if (posX + posW > xMax)
                {
                    xMax := posX + posW
                    rightMost := controlID
                }
            }
            GuiControlGet, pos, ICScriptHub:Pos, %k%
            if (posX + posW > xMax)
            {
                xMax := posX + posW
                rightMost := k
            }
        }
        return rightMost
    }

    ; Calculates the size of this GroupBox's outline that contours all of its controls.
    ; Parameters: - init:bool - If true, resizes the GroupBox outline.
    ; Parameters: - line:bool - If true, displays a thin line instead of a box around controls.
    AutoResize(init := false, border := "")
    {
        if (!init)
            return
        controlID := this.ControlID
        GuiControlGet, posS, ICScriptHub:Pos, %controlID%
        if (border == "Line")
            newHeight := 10
        else if (border == "Borderless")
            newHeight := 0
        else
        {
            lowest := this.GetLowestControl()
            GuiControlGet, posL, ICScriptHub:Pos, %lowest%
            newHeight := posLY + posLH - posSY + this.YSection
        }
        rightMost := this.GetRightMostControl()
        GuiControlGet, posR, ICScriptHub:Pos, %rightMost%
        newWidth := posRX + posRW - posSX + this.XSection
        this.UpdateSize(newHeight, newWidth)
    }

    ; Resizes this GroupBox's outline.
    ; Parameters: - newHeight:int - New height of the GroupBox.
    ;             - newWidth:int - New width of the GroupBox.
    UpdateSize(newHeight := "", newWidth := "")
    {
        controlID := this.ControlID
        if (newHeight != "")
            this.Height := newHeight
        else
            newHeight := this.Height
        if (newWidth != "")
            this.Width := newWidth
        else
            newWidth := this.Width
        GuiControl, ICScriptHub:Move, %controlID%, h%newHeight% w%newWidth%
        ; Resize subgroups
        groupsByName := IC_BrivGemFarm_LevelUp_GUI_Group.GroupsByName
        for k, v in this.ControlsByName
        {
            if (v.Hidden || !v.RightAlignWithMain)
                continue
            ; Subgroup
            if (groupsByName.HasKey(k))
            {
                group := groupsByName[k]
                group.UpdateSize(, newWidth - 2 * this.XSection)
            }
        }
    }

    ; Align this group to the right of its parent group.
    RightAlign()
    {
        controlID := this.ControlID
        groupID := this.Group.ControlID
        previousID := this.PreviousControl.ControlID
        GuiControlGet, oldPos, ICScriptHub:Pos, %controlID%
        GuiControlGet, minPos, ICScriptHub:Pos, %previousID%
        GuiControlGet, maxPosM, ICScriptHub:Pos, ModronTabControl
        GuiControlGet, maxPosG, ICScriptHub:Pos, %groupID%
        leftBound := minPosX + minPosW + (this.Borderless ? 0 : this.Group.XSpacing)
        rightBound := Min(maxPosMX + maxPosMW, maxPosGX + maxPosGW) - oldPosW - this.Group.XSection
        this.Move(Max(leftBound, rightBound))
    }
}

; Class that allows to group controls under a GroupBox control, but doesn't show the outline.
Class IC_BrivGemFarm_LevelUp_GUI_BorderLessGroup extends IC_BrivGemFarm_LevelUp_GUI_Group
{
    ; Creates a new GroupBox.
    ; Parameters: - name:str - The name/reference of the group.
    ;             - title:str - The title of the control that will appear on the outline.
    ;             - group:str - The group that contanis this group.
    ;             - tabS:bool - If true, adds an x offset to this group from the previous control equal to XSection.
    ;             - newLine:bool - If true, position the group under the previous control.
    ;             - previous:str - The reference control that is used to position the new group.
    __New(name, title := "", group := "BGFLU_DefaultSettingsGroup", tabS := true, newLine := true, previous := "")
    {
        this.Borderless := true
        this.XSection := this.YSection := 0
        this.YTitleSpacing := 0
        base.__New(name, title, group, tabS, newLine, previous)
        Gui, ICScriptHub:Font, w700
        this.AddControl(name . "Title", "Text", "x+0", title)
        Gui, ICScriptHub:Font, w400
    }
}

; Class that creates 50 checkboxes into a single group.
Class IC_BrivGemFarm_LevelUp_GUI_Mod50Group extends IC_BrivGemFarm_LevelUp_GUI_BorderLessGroup
{
    ; Creates a new GroupBox.
    ; Parameters: - name:str - The name/reference of the group.
    ;             - title:str - The title of the control that will appear on the outline.
    ;             - group:str - The group that contanis this group.
    ;             - tabS:bool - If true, adds an x offset to this group from the previous control equal to XSection.
    ;             - newLine:bool - If true, position the group under the previous control.
    ;             - previous:str - The reference control that is used to position the new group.
    __New(name, title := "", group := "BGFLU_DefaultSettingsGroup", tabS := true, newLine := true, previous := "")
    {
        base.__New(name, title, group, tabS, newLine, previous)
        GuiControlGet, pos, ICScriptHub:Pos, %name%
        this.BuildModTable(posX, posY, name)
    }

    ; Builds mod50 checkboxes.
    BuildModTable(xLoc, yLoc, name)
    {
        leftAlign := xLoc
        Loop, 50
        {
            if(Mod(A_Index, 10) != 1)
                xLoc += 35
            else
            {
                xLoc := leftAlign
                yLoc += 20
            }
            this.AddCheckBox(name . "_Mod50_" . A_Index, true, "Checked x" . xLoc . " y" . yLoc, A_Index)
        }
    }

    ; Creates and adds a CheckBox control to the GroupBox.
    ; The function BGFLU_Mod50CheckBoxEvent handles Mod50Checkbox events.
    AddCheckBox(controlID, saveSetting := true, options := "", text := "", newLine := false)
    {
        if (saveSetting)
            options .= " gBGFLU_Mod50CheckBoxEvent"
        return this.AddControl(controlID, "CheckBox", options, text, newLine)
    }
}

; Class that contains multiple groups.
Class IC_BrivGemFarm_LevelUp_GUI_Group_Main extends IC_BrivGemFarm_LevelUp_GUI_Group
{
    static Groups := []

    AddGroup(group)
    {
        this.Groups.Push(group)
        this.AddExistingControl(group)
    }

    AutoResize()
    {
        for k, v in this.Controls
        {
            if (!v.Hidden)
                v.AutoResize()
        }
        base.AutoResize(true)
    }
}