; Class that contains methods to perform various GUI commands on controls.
Class IC_BrivGemFarm_LevelUp_GUI_Control
{
    ControlID := ""
    Group := ""
    Hidden := false

    ; Creates a new GUI control.
    ; Parameters: - controlID:str - The name/reference of the control.
    ;             - controlType:str - The type of the control.
    ;             - options:str - Options to apply to the control. The control's target variable is equal to controlID.
    ;             - text:str - The initial text of the control.
    ;             - group:IC_BrivGemFarm_LevelUp_GUI_Group - The group this control belong to.
    __New(controlID, controlType := "", options := "", text := "", group := "")
    {
        global
        this.controlID := controlID
        this.Group := group
        if controlType in ComboBox,DropDownList,Edit,ListBox
            GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        else if controlType in ListView
            GUIFunctions.UseThemeTextColor("TableTextColor")
        options .= " v" . controlID
        Gui, ICScriptHub:Add, %controlType%, %options%, % text
        if controlType in ListView
            GUIFunctions.UseThemeListViewBackgroundColor(controlID)
        GUIFunctions.UseThemeTextColor()
    }

    ; Show the control.
    Show()
    {
        controlId := this.ControlID
        GuiControl, ICScriptHub:Show, %controlId%
        this.Hidden := false
    }

    ; Hide the control.
    Hide()
    {
        controlId := this.ControlID
        GuiControl, ICScriptHub:Hide, %controlId%
        this.Hidden := true
    }

    PreviousControl
    {
        get
        {
            return this.Group.GetPreviousControl(this)
        }
    }

    NextControl
    {
        get
        {
            return this.Group.GetNextControl(this)
        }
    }
}