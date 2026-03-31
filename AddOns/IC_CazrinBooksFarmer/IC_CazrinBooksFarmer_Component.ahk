#include %A_LineFile%\..\IC_CazrinBooksFarmer_Functions.ahk
#include %A_LineFile%\..\IC_CazrinBooksFarmer_GUI.ahk

global g_CazrinBooksFarmer := new IC_CazrinBooksFarmer_Component
global g_CazrinBooksFarmerGUI := new IC_CazrinBooksFarmer_GUI
g_SF.hWnd := WinExist("ahk_exe " . g_userSettings[ "ExeName"])
g_SF.Memory.OpenProcessReader()
g_CazrinBooksFarmerGUI.Init()
g_CazrinBooksFarmer.Init()

class IC_CazrinBooksFarmer_Component
{
	static SpecPotionID := 35
	static LostInTheLibraryID := 17680
	static SmellMasteryID := 17682
	static InventoryPotionsCategoryIndex := 3

	Running := false
	TimerFunctions := {}
	DisplayStatusTimeout := -1
	MessageStickyTimer := 6000
	SpecPotsUsed := 0
	
	CurrBooks := 0
	TotalBooks := 0
	MaxBooks := 0
	CurrSpecID := 0
	CurrSpecName := ""
	SpecPotsIndex := 0
	SpecPotsName := ""
	SpecPotsAmount := 0
	
	; ==========================
	; ===== Main Functions =====
	; ==========================
	
	CazrinBooksFarmer()
	{
		this.UpdateMainStatus("Start.")
		if (g_SF.Memory.ReadDialogNameBySlot(1) == "")
		{
			this.UpdateMainStatus("Bad DialogManager pointer - addon can't function. Stopping.")
			Sleep, 6000
			this.StopFarming()
			return
		}
		Loop
		{
			this.UpdateMainStatus("")
			g_SF.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Cazrin.CazrinLibraryOfLoreHandler.EffectKeyString)
			if (!this.Running)
				break
			this.CurrBooks := ActiveEffectKeySharedFunctions.Cazrin.CazrinLibraryOfLoreHandler.ReadCurrentBooks()
			this.TotalBooks := ActiveEffectKeySharedFunctions.Cazrin.CazrinLibraryOfLoreHandler.ReadTotalBooks()
			currSpecData := IC_CazrinBooksFarmer_Functions.GetCurrentSpecialisation(Cazrin.HeroID,15)
			this.CurrSpecID := currSpecData[1]
			this.CurrSpecName := currSpecData[2]
			this.MaxBooks := IC_CazrinBooksFarmer_Functions.CalculateMaxBooks(this.CurrSpecID)
			specPotsData := IC_CazrinBooksFarmer_Functions.GetSpecialisationPotionData()
			this.SpecPotsIndex := specPotsData[1]
			this.SpecPotsName := specPotsData[2]
			this.SpecPotsAmount := specPotsData[3]
			if (this.CurrBooks >= (this.MaxBooks-5) || this.CurrSpecID != this.LostInTheLibraryID)
			{
				successfullySwapped := IC_CazrinBooksFarmer_Functions.SwapSpecialisation(this.SpecPotsIndex)
				msgmsg .= "`n  successfullySwapped:" . successfullySwapped
				if (!successfullySwapped)
				{
					this.UpdateMainStatus("Specialisation swapping failed.")
					IC_CazrinBooksFarmer_Functions.CloseAnyActiveDialogs()
				}
				else
					this.SpecPotsUsed += 1
			}
			this.UpdateGUI()
			Sleep, 100
		}
		this.UpdateMainStatus("Stopped.")
	}
	
	; =======================================
	; ===== Initialisation and Settings =====
	; =======================================

	Init()
	{
		ActiveEffectKeySharedFunctions.Add(Cazrin, "Cazrin")
		this.UpdateMainStatus(IC_CazrinBooksFarmer_GUI.ReadyMessage)
	}
	
	; =====================
	; ===== GUI STUFF =====
	; =====================
	
	UpdateMainStatus(status)
	{
		GuiControlGet,CBF_StatusText, ICScriptHub:, CBF_StatusText
		CBF_TimerIsUp := this.GetTickCount() - this.DisplayStatusTimeout >= this.MessageStickyTimer
		if (status == "" && !CBF_TimerIsUp && !InStr(CBF_StatusText, "specialisation potion"))
			status := CBF_StatusText
		if (status != "" && CBF_TimerIsUp)
			this.DisplayStatusTimeout := this.GetTickCount()
		if (status == "")
			status := this.SpecPotsUsed . " specialisation potion" . (this.SpecPotsUsed == 1 ? " has" : "s have") . " been used so far."
		GuiControl, ICScriptHub:Text, CBF_StatusText, % status
		Gui, Submit, NoHide
	}
	
	UpdateGUI()
	{
		GuiControl, ICScriptHub:, CBF_CurrBooks, % this.CurrBooks . " / " . this.MaxBooks
		GuiControl, ICScriptHub:, CBF_TotalBooks, % this.TotalBooks
		GuiControl, ICScriptHub:, CBF_BooksPerBoss, % (this.CurrSpecID == this.LostInTheLibraryID ? 3 : 1)
		GuiControl, ICScriptHub:, CBF_CurrSpec, % this.CurrSpecName
		GuiControl, ICScriptHub:, CBF_NumSpecPots, % this.SpecPotsAmount
	}
	
	; =========================
	; ===== RUNNING STUFF =====
	; =========================
	
	StartFarming()
	{
		CoordMode, Mouse, Client
		this.Running := True
		this.CazrinBooksFarmer()
	}
	
	StopFarming()
	{
		this.Running := False
	}
	
	GetTickCount()
	{
		return IC_CazrinBooksFarmer_Functions.GetTickCount()
	}

}

class Cazrin
{
	static HeroID := 166
	class CazrinLibraryOfLoreHandler
	{
		static EffectKeyString := "library_of_lore_handler"
		ReadCurrentBooks()
		{
			return g_SF.Memory.ActiveEffectKeyHandler.CazrinLibraryOfLoreHandler.booksCollectedThisAdventure.Read()
		}
		
		ReadTotalBooks()
		{
			return g_SF.Memory.ActiveEffectKeyHandler.CazrinLibraryOfLoreHandler.booksCollected.Read()
		}
		
		ReadMaxBookDivisor()
		{
			return g_SF.Memory.ActiveEffectKeyHandler.CazrinLibraryOfLoreHandler.maxBookDivisor.Read()
		}
	}
}

Hotkey, ^+F3, CBF_StopFarmingBooks

CBF_StopFarmingBooks()
{
    g_CazrinBooksFarmer.StopFarming()
}