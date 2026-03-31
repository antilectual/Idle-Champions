; Based on Idle-Champions\ServerCalls\IC_ServerCalls_Class.ahk.
; Avoids parsing responses with the JSON class to speed up processing data,
; relying on InStr() and RegExMatch() instead.
#include %A_LineFile%\..\..\..\..\..\ServerCalls\SH_ServerCalls.ahk 
class IC_BrivGemFarm_LevelUp_ServerCalls_Class extends SH_ServerCalls
{
    static Timeout := 60000
    WebRoot := "http://ps21.idlechampions.com/~idledragons/"

    GetWebRoot()
    {
        this.WebRoot := "http://master.idlechampions.com/~idledragons/"
        response := this.CallGetPlayServer()
        if (response != "" && (playServer := this.ParsePlayServer(response)) != "")
            return this.WebRoot := playServer
        else
            return "http://ps21.idlechampions.com/~idledragons/"
    }

    ParsePlayServer(response)
    {
        startPos := InStr(response, """play_server"":")
        if (startPos)
        {
            RegExMatch(response, """([^""]+)""", playServer, startPos + 13)
            playServer := StrReplace(playServer1, "\")
        }
        return playServer
    }

    ParseSwitchPlayServer(response)
    {
        startPos := InStr(response, """switch_play_server"":")
        if (startPos)
        {
            RegExMatch(response, """([^""]+)""", playServer, startPos + 20)
            playServer := StrReplace(playServer1, "\")
        }
        return playServer
    }

    ServerCall( callName, parameters, timeout := "", retryNum := 0)
    {
        URLtoCall := this.WebRoot . "post.php?call=" . callName . parameters
        timeout := timeout != "" ? timeout : this.Timeout
        WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        ; https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-settimeouts defaults: 0 (DNS Resolve), 60000 (connection timeout. 60s), 30000 (send timeout), 60000 (receive timeout)
        WR.SetTimeouts(30000, 45000, 30000, timeout)
        if (this.proxy != "")
            WR.SetProxy(2, this.proxy)
        Try
        {
            WR.Open( "POST", URLtoCall, true )
            WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
            WR.Send()
            WR.WaitForResponse(timeout)
            data := WR.ResponseText
            Try
            {
                playServer := this.ParseSwitchPlayServer(data)
                if(playServer != "")
                {
                    retryNum += 1
                    this.WebRoot := playServer
                    if(retryNum <= 3)
                        return this.ServerCall(callName, parameters, timeout, retryNum)
                }
            }
        }
        return data
    }

    ; Get the loadbalanced Play Server.
    CallGetPlayServer() 
    {
        params := "&network_id=11&mobile_client_version=9999&"
        return this.ServerCall("getPlayServerForDefinitions", params)
    }

    ; Sends a server call to verify if table_checksums match previous table_checksums.
    ; Params: - languageID:int - Language.
    ;           1:English, 2:Deutsch, 3:Pусский, 4:Français, 5:Português, 6:Español, 7:中文".
    ;         - table_checksums:str - List of key/value pairs separated by commas.
    CallCheckTableChecksums(languageID := 1, table_checksums := "")
    {
        if languageID is not integer
            languageID := 1
        params := "&language_id=" . languageID
        params .= "&supports_chunked_defs=1"
        params .= "&table_checksums=" . table_checksums . "&"
        return this.ServerCall("getDefinitions", params)
    }

    ; Sends a server call to retrieve the latest definitions.
    ; Params: - languageID:int - Language.
    ;           1:English, 2:Deutsch, 3:Pусский, 4:Français, 5:Português, 6:Español, 7:中文".
    ;         - filter:str - List of keys separated by commas.
    CallGetHeroDefs(languageID := 1, filter := "")
    {
        if languageID is not integer
            languageID := 1
        params := "&language_id=" . languageID
        params .= "&supports_chunked_defs=0"
        if (filter != "")
            params .= "&filter=" . filter . "&"
        return this.ServerCall("getDefinitions", params)
    }
}