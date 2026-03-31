; Functions that are used by this Addon.
class IC_RNGWaitingRoom_Functions
{
    static SettingsPath := A_LineFile . "\..\RNGWaitingRoom_Settings.json"

    ; Adds IC_RNGWaitingRoom_Addon.ahk to the startup of the Briv Gem Farm script.
    InjectAddon()
    {
        splitStr := StrSplit(A_LineFile, "\")
        addonDirLoc := splitStr[(splitStr.Count()-1)]
        addonLoc := "#include *i %A_LineFile%\..\..\" . addonDirLoc . "\IC_RNGWaitingRoom_Addon.ahk`n"
        FileAppend, %addonLoc%, %g_BrivFarmModLoc%
    }

    ; Returns the text to append for values not equal to 1.
    ; Parameters: - value:int - Value of anything countable.
    Plural(value)
    {
        return value == 1 ? "" : "s"
    }

    GetExeName()
    {
        default := "IdleDragons.exe"
        exeName := g_UserSettings[ "ExeName" ]
        return (exeName != default && exeName != "") ? exeName : default
    }

    ; Ellywick

    class EllywickHandlerHandler
    {
        LoopTimer := ObjBindMethod(this, "MainLoop")
        GemCardsNeeded := 0
        MaxRedraws := 0
        WaitForAllCards := false
        WaitedForEllywickThisRun := false
        Redraws := 0
        UsedUlt := false

        __New(gemCardsNeeded := 1, maxRedraws := 1, wait := false)
        {
            this.GemCardsNeeded := gemCardsNeeded
            this.MaxRedraws := maxRedraws
            this.WaitForAllCards := wait
            this.WaitedForEllywickThisRun := false
        }

        UpdateGlobalSettings()
        {
            this.GemCardsNeeded := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemCards" ]
            this.MaxRedraws := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemMaxRedraws" ]
            this.WaitForAllCards := g_BrivUserSettingsFromAddons[ "RNGWR_EllywickGFGemWaitFor5Draws" ]
        }

        Start()
        {
            fncToCallOnTimer := this.LoopTimer
            SetTimer, %fncToCallOnTimer%, 200, 0
        }

        Stop()
        {
            fncToCallOnTimer := this.LoopTimer
            SetTimer, %fncToCallOnTimer%, Off
            this.Reset()
        }

        Reset()
        {
            this.WaitedForEllywickThisRun := false
            this.Redraws := 0
            this.UsedUlt := false
        }
        
        SetStatus(text := "")
        {
            g_SharedData.RNGWR_SetStatus(text)
        }

        MainLoop()
        {
            if (g_SF.Memory.ReadResetting() || g_SF.Memory.ReadCurrentZone() == "" || this.GetNumCards() == "")
                return
            if (this.WaitedForEllywickThisRun)
            {
                ; Use ultimate to redraw cards if Ellywick doesn't have any gem cards.
                if (this.CanUseEllyWickUlt() && this.GetNumGemCards() == 0 && !this.UsedUlt && this.GetNumCards() == 5)
                    this.UseEllywickUlt()
            }
            else if (this.ShouldDrawMoreCards())
            {
                numCards := this.GetNumCards()
                ; Use ultimate if it's not on cooldown and there are redraws left.
                if (this.RedrawsLeft)
                {
                    shouldRedraw := this.ShouldRedraw()
                    if (!this.UsedUlt && shouldRedraw && this.CanUseEllyWickUlt())
                        this.UseEllywickUlt()
                    if (!shouldRedraw)
                        this.SetStatus("Waiting for card #" . (numCards + 1))
                }
                ; (Not waiting) has full hand and does not allow redraws - or - (Not waiting) Redraws > 0 - or - (Waiting) has full hand with no redraws left
                else if ((!this.WaitForAllCards && numCards == 5 && this.Redraws == 0) || (!this.WaitForAllCards && this.Redraws) || (this.WaitForAllCards && numCards == 5 && !this.RedrawsLeft))
                {
                    this.WaitedForEllywickThisRun := true
                    success := this.IsSuccess()
                    this.SetStatus(this.GetResultString(success))
                    bonusGems := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadGemMult()
                    g_SharedData.RNGWR_UpdateStats(bonusGems, this.Redraws, success)
                }
                else if (numCards < 5)
                    this.SetStatus("Waiting for card #" . (numCards + 1))
            }
            else
            {
                this.WaitedForEllywickThisRun := true
                success := this.IsSuccess()
                this.SetStatus(this.GetResultString(success))
                bonusGems := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadGemMult()
                g_SharedData.RNGWR_UpdateStats(bonusGems, this.Redraws, success)
            }
            this.UpdateRedraws()
        }

        DrawsLeft
        {
            get
            {
                return 5 - this.GetNumCards()
            }
        }

        RedrawsLeft
        {
            get
            {
                return this.MaxRedraws - this.Redraws
            }
        }

        ShouldDrawMoreCards()
        {
            if (this.DrawsLeft && this.WaitForAllCards)
                return true
            return this.GetNumGemCards() < this.GemCardsNeeded
        }

        ShouldRedraw()
        {
            numCards := this.GetNumCards()
            if (numCards == 5)
                return true
            else if (numCards == 0)
                return false
            return this.DrawsLeft < this.GemCardsNeeded - this.GetNumGemCards()
        }

        IsSuccess()
        {
            return this.GetNumGemCards() >= this.GemCardsNeeded
        }

        GetResultString(success := true)
        {
            redraws := this.Redraws
            str := success ? "Success" : "Failure"
            str .= " - Used " . redraws . " redraw" . IC_RNGWaitingRoom_Functions.Plural(redraws)
            return str
        }

        GetNumCards()
        {
            size := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.cardsInHand.size.Read()
            if (size == "" && this.IsEllyWickOnTheField())
            {
                g_SF.Memory.ActiveEffectKeyHandler.Refresh(ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.EffectKeyString)
                size := g_SF.Memory.ActiveEffectKeyHandler.EllywickCallOfTheFeywildHandler.deckOfManyThingsHandler.cardsInHand.size.Read()
            }
            return size == "" ? 0 : size
        }

        GetNumGemCards()
        {
            return this.GetNumCardsOfType(3)
        }

        GetNumCardsOfType(cardType := 3)
        {
            numCards := 0
            cards := ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadCardsInHand()
            for _, cardTypeInHand in cards
            {
                if (cardTypeInHand == cardType)
                    ++numCards
            }
            return numCards
        }

        UseEllywickUlt()
        {
            heroID := ActiveEffectKeySharedFunctions.Ellywick.HeroID
            if (this.CanUseEllyWickUlt())
            {
                this.SetStatus("Using Ellywick's ultimate to redraw cards")
                g_SF.DirectedInput(,, "{" . g_SF.GetUltimateButtonByChampID(heroID) . "}")
            }
        }

        IsEllywickUltReady()
        {
            heroID := ActiveEffectKeySharedFunctions.Ellywick.HeroID
            ultButton := g_SF.GetUltimateButtonByChampID(heroID)
            ultCd := g_SF.Memory.ReadUltimateCooldownByItem(ultButton - 1)
            return ultCd <= 0 ; any <= 0 means it's not on cd
        }

        CanUseEllyWickUlt()
        {
            return this.IsEllyWickOnTheField() && this.IsEllywickUltReady() && !this.IsEllywickUltActive()
        }

        IsEllyWickOnTheField()
        {
            return g_SF.IsChampInFormation(ActiveEffectKeySharedFunctions.Ellywick.HeroID, g_SF.Memory.GetCurrentFormation())
        }

        IsEllywickUltActive()
        {
            return ActiveEffectKeySharedFunctions.Ellywick.EllywickCallOfTheFeywildHandler.ReadUltimateActive()
        }
        
        UseDMUlt()
        {
            heroID := 99
            if (this.CanUseDMUlt())
            {
                this.SetStatus("Using Dungeon Master's ultimate")
                g_SF.DirectedInput(,, "{" . g_SF.GetUltimateButtonByChampID(heroID) . "}")
            }
        }

        IsDMUltReady()
        {
            heroID := 99
            ultButton := g_SF.GetUltimateButtonByChampID(heroID)
            ultCd := g_SF.Memory.ReadUltimateCooldownByItem(ultButton - 1)
            return ultCd <= 0 ; any <= 0 means it's not on cd
        }

        CanUseDMUlt()
        {
            return this.IsDMOnTheField() && this.IsDMUltReady()
        }

        IsDMOnTheField()
        {
            return g_SF.IsChampInFormation(99, g_SF.Memory.GetCurrentFormation())
        }

        UpdateRedraws()
        {
            if (!this.UsedUlt && !this.IsEllywickUltReady())
            {
                this.Redraws += 1
                this.UsedUlt := true
            }
            else if (this.UsedUlt && this.IsEllywickUltReady())
                this.UsedUlt := false
            if (this.IsEllyWickOnTheField() && !this.IsEllywickUltReady())
                this.UseDMUlt()
        }
    }

    class EllywickHandlerHandlerSingle extends IC_RNGWaitingRoom_Functions.EllywickHandlerHandler
    {
        __New(cardsNeeded := "")
        {
            ; 5 Moon cards
            if (cardsNeeded == "")
                cardsNeeded := [0, 5, 0, 0, 0]
            this.CardsNeeded := cardsNeeded
        }

        Stop()
        {
            if (!this.WaitedForEllywickThisRun)
                this.SetStatus("Idle")
            base.Stop()
        }

        SetStatus(text := "")
        {
            g_RNGWaitingRoomGui.SetEllyWickSingleStatus(text)
        }

        MainLoop()
        {
            if (g_SF.Memory.ReadResetting() || g_SF.Memory.ReadCurrentZone() == "" || this.GetNumCards() == "")
                return
            remaining := this.GetRemainingCardsToDraw()
            if (remaining == 0)
            {
                this.WaitedForEllywickThisRun := true
                this.SetStatus(this.GetResultString())
                this.StopGlobal()
            }
            else if (this.DrawsLeft < remaining)
            {
                ; Use ultimate to redraw cards
                if (this.CanUseEllyWickUlt() && !this.UsedUlt)
                    this.UseEllywickUlt()
                else
                {
                    numCards := this.GetNumCards()
                    if (numCards < 5)
                        this.SetStatus("Waiting for card #" . (numCards + 1))
                    else
                        this.SetStatus("Waiting for Ellywick's ult being available")
                }
            }
            this.UpdateRedraws()
        }

        StopGlobal()
        {
            g_RNGWaitingRoom.StopSingle()
            GuiControl, ICScriptHub: Disable, RNGWR_EllywickSingleStop
            g_RNGWaitingRoomGui.UpdateWarningText()
        }

        UseEllywickUlt()
        {
            exeName := IC_RNGWaitingRoom_Functions.GetExeName()
            g_SF.Hwnd := WinExist("ahk_exe " . exeName)
            base.UseEllywickUlt()
        }

        GetRemainingCardsToDraw()
        {
            num := 0
            for cardType, numCards in this.CardsNeeded
                num += Max(0, numCards - this.GetNumCardsOfType(cardType))
            return num
        }
    }

    GetFavoriteFormationSlot(key)
    {
        key := Trim(key, "{}")
        StringLower, key, key
        Switch key
        {
            case "q":
                slot := 1
            case "w":
                slot := 2
            case "e":
                slot := 3
            default:
                slot := 0
        }
        return slot
    }

    ; Checks if Thellora is in Q/W/E formation
    IsThelloraInFavoriteFormation(favorite := 1)
    {
        formationFavorite := g_SF.Memory.GetFormationByFavorite(favorite)
        heroID := ActiveEffectKeySharedFunctions.Thellora.HeroID
        return g_SF.IsChampInFormation(heroID, formationFavorite)
    }
}