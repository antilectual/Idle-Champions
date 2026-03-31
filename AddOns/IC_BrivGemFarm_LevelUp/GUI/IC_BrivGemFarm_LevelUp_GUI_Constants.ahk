SM_CXVSCROLL := 2
CBN_DROPDOWN := 7
CBN_SELENDCANCEL := 10
WM_COMMAND := 0x0111
CB_GETCURSEL := 0x147
CB_GETDROPPEDCONTROLRECT := 0x0152
CB_SETITEMHEIGHT := 0x0153
CB_GETDROPPEDSTATE := 0x0157
global CB_SETDROPPEDWIDTH := 0x0160
CB_GETCOMBOBOXINFO := 0x0164
WM_ENTERSIZEMOVE := 0x0231
WM_EXITSIZEMOVE := 0x0232

BGFLU_ColorNameToHexColor(name)
{
    switch name
    {
        case "Black":
            return 0x000000
        case "Silver":
            return 0xC0C0C0
        case "Gray":
            return 0x808080
        case "White":
            return 0xFFFFFF
        case "Maroon":
            return 0x800000
        case "Red":
            return 0xFF0000
        case "Purple":
            return 0x800080
        case "Fuchsia":
            return 0xFF00FF
        case "Green":
            return 0x008000
        case "Lime":
            return 0x00FF00
        case "Olive":
            return 0x808000
        case "Yellow":
            return 0xFFFF00
        case "Navy":
            return 0x000080
        case "Blue":
            return 0x0000FF
        case "Teal":
            return 0x008080
        case "Aqua":
            return 0x00FFFF
    }
}