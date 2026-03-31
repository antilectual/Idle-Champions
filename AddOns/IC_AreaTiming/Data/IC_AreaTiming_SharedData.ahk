; Class that is used as a COM object between ICScriptHub and this script.
class IC_AreaTiming_SharedData
{
    Sessions := []
    CurrentSession := ""

    ; Returns true if the timer loop is active, false otherwise.
    Running
    {
        get
        {
            return g_AreaTimingWorker.Running
        }
    }

    ; Start executing the main loop.
    Start()
    {
        if (g_AreaTimingWorker.Running)
            return
        this.NewSession()
        g_AreaTimingWorker.Running := true
        ; Delayed start so ICScriptHub is not stuck waiting the loop to finish.
        func := ObjBindMethod(g_AreaTimingWorker, "Loop")
        SetTimer, %func%, -10
    }

    ; Stop executing the main loop.
    Stop()
    {
        running := g_AreaTimingWorker.Running
        g_AreaTimingWorker.Running := false
        ; Delete current session if no run has been recorded.
        if (running && this.CurrentSession.CurrentRun == "")
        {
            if (this.Sessions.Length() == 1)
                return this.Close(true)
            this.CurrentSession.CurrentRun.Clear()
            this.Sessions.RemoveAt(this.CurrentSession.ID)
        }
        this.CurrentSession := ""
    }

    ; Function that simply closes the script.
    ; Params: - force:bool - If true, force exit, else stop the main loop.
    ; ICScriptHub will call this function when pressing "Stop" in the main tab.
    Close(force := false)
    {
        if (!force)
            this.Stop()
        else
            ExitApp
    }

    ; Create a new session and append to the session list.
    ; The session has its own new ID provided.
    NewSession()
    {
        session := new IC_AreaTiming_RunCollection(this.Sessions.Length() + 1)
        this.CurrentSession := session
        this.Sessions.Push(session)
        return session
    }
}