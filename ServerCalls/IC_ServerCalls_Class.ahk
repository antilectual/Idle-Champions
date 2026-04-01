;=================================
;Class for making server calls
;=================================
/*  Usage: 
        variable := new IC_ServerCalls( userID, userHash ) ;create new object
        variable.method() ;see methods below
    Parameters:
        userID - your unique userID
        userHash - your unique userHash

    Changes:
    See commit History
*/

; json library must be included if this file is used outside of Script Hub
#include %A_LineFile%\..\SH_ServerCalls.ahk 

class IC_ServerCalls_Class extends SH_ServerCalls
{
    userID := 0
    userHash := ""
    instanceID := 0
    networkID := 11
    clientVersion := 9999
    activeModronID := 1
    userDetails := ""
    activePatronID := 0
    dummyData := ""
    webRoot := ""
    timeoutVal := 60000
    playServerExcludes := "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,26"
    settings := ""
    initMaxRetries := 2
    playServerRegex := "^https?://ps\d+\.idlechampions.com/~idledragons/"
    
    __New( userID := 0, userHash := 0, instanceID := 0)
    {
        this.BlankSlate(userID, userHash, instanceID)
        ; Step 1: Try memory read.
        this.webRoot := g_SF.Memory.ReadWebRoot()
        if (RegExMatch(this.webRoot, this.playServerRegex))
            return this
        ; Step 2: Try asking master.
        this.webRoot := "http://master.idlechampions.com/~idledragons/"
        response := this.CallGetPlayServer()
        if (RegExMatch(response.play_server, this.playServerRegex))
        {
            this.webRoot := response.play_server
            return this
        }
        ; Step 3: RNG
        currentPlayServers := [27,28,29,30]
        Random, psIndex , 1, currentPlayServers.Count()
        this.webRoot := "http://ps" . currentPlayServers[psIndex] . ".idlechampions.com/~idledragons/"
        return this
    }
    
    BlankSlate(userID := 0, userHash := 0, instanceID := 0)
    {
        this.userID := userID
        this.userHash := userHash
        this.instanceID := instanceID
        this.shinies := 0
        this.LoadSettings(A_LineFile . "\..\ServerCall_Settings.json")
    }

    GetVersion()
    {
        return "v2.4.7, 2026-04-01"
    }

    UpdateDummyData()
    {
        this.dummyData := "&language_id=1&timestamp=0&request_id=0&network_id=" . this.networkID . "&mobile_client_version=" . this.clientVersion . "&offline_v2_build=1"
    }

    SetServer(serverAddress)
    {

    }

    ;============================================================
    ;Various server call functions that should be pretty obvious.
    ;============================================================
    ;Except this one, it is used internally and shouldn't be called directly.
    ServerCall( callName, parameters := "", timeout := "", retryNum := 0) 
    {
        response := ""
        URLtoCall := this.webRoot . "post.php?call=" . callName . parameters
        timeout := timeout ? timeout : this.timeoutVal
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        ; https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-settimeouts defaults: 0 (DNS Resolve), 60000 (connection timeout. 60s), 30000 (send timeout), 60000 (receive timeout)
        WR.SetTimeouts( 0, 45000, 30000, timeout )  
        ; WR.SetProxy( 2, "IP:PORT" )  Send web traffic through a proxy server. A local proxy may be helpful for debugging web calls.
        if (this.proxy != "")
            WR.SetProxy(2, this.proxy)
        Try {
            WR.Open( "POST", URLtoCall, true )
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.Send()
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            ; dataLB := data . "`n"
            ; FileAppend, %dataLB%, % A_LineFile . "\..\ServerLog.txt"
            Try
            {
                response := JSON.parse(data)
                if(!(response.switch_play_server == ""))
                {
                    retryNum += 1
                    this.WebRoot := response.switch_play_server
                    if(retryNum <= 3) 
                        return this.ServerCall( callName, parameters, timeoutVal, retryNum )
                }
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        ; catch except
        ; {
        ;     exceptMessage := except.Message
        ;     exceptMessage .= " Extra: " . except.Extra
        ;     FileAppend, %exceptMessage%, % A_LineFile . "\..\ErrorLog.txt"
        ; }
        return response
    }

    ; Pulls user details from the server and returns it in a json parsed object.
    CallUserDetails() 
    {
        getUserParams := this.dummyData . "&include_free_play_objectives=true&instance_key=1&user_id=" . this.userID . "&hash=" . this.userHash
        userDetails := this.ServerCall( "getuserdetails", getUserParams )
        return userDetails
    }

    ; Starts a new adventure and returns the response.
    CallLoadAdventure( adventureToLoad ) 
    {
        patronTier := this.activePatronID ? 1 : 0
        advParams := this.dummyData . "&patron_tier=" . patronTier . "&user_id=" . this.userID . "&hash=" . this.userHash . "&instance_id=" . this.instanceID 
            . "&game_instance_id=" . this.activeModronID . "&adventure_id=" . adventureToLoad . "&patron_id=" . this.activePatronID
        return this.ServerCall( "setcurrentobjective", advParams )
    }

    ; Calling this loses everything earned during the adventure, should only be used when stuck.
    CallEndAdventure() 
    {
        advParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&game_instance_id=" this.activeModronID
        return this.ServerCall( "softreset", advParams )
    }

    ;sample: call=convertresetcurrency&language_id=1&user_id=___&hash=___&converted_currency_id=17&target_currency_id=1&timestamp=0&request_id=0&network_id=0&mobile_client_version=999&localization_aware=true&instance_id=___& 
    ; Valid Target Currencies: 1 (Torm), 3 (Kalemvor), 15 (Helm), 22 (Tiamat), 23 (Auril), 25 (Corellon)
    CallConverCurrency(toCurrency := 1, fromCurrency := 24) 
    {
        advParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID
        extraParams := "&converted_currency_id=" . fromCurrency . "&target_currency_id=" . toCurrency
        return this.ServerCall( "convertresetcurrency", (advParams . extraParams))
    }

    ; Buys <chests> number of <chestID> chests. Automatically uses Patron purchase call for patron chests.
    CallBuyChests( chestID, chests, chestType := "")
    {
        if ( chests > 250 )
            chests := 250
        else if ( chests < 1 )
            return
        if(chestType == "eventV2")
        {
            chestParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&chest_type_id=" chestID "&count=" chests "&spend_event_v2_tokens=1"
            return this.ServerCall( "buysoftcurrencychest", chestParams )
        }
        else if(chestID != 152 AND chestID != 153 AND chestID != 219  AND chestID != 311)
        {
            chestParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&chest_type_id=" chestID "&count=" chests
            return this.ServerCall( "buysoftcurrencychest", chestParams )
        }
        else
        {
            switch chestID
            {
                case 152:
                    itemID := 1
                    patronID := 1
                case 153:
                    itemID := 23
                    patronID := 2
                case 219:
                    itemID := 45
                    patronID := 3
                case 311:
                    itemID := 76
                    patronID := 4
                Default:
                    return ""
            }
            chestParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.instanceID "&patron_id=" patronID "&shop_item_id=" itemID
            return this.ServerCall( "purchasepatronshopitem", chestParams )
        }
    }

    ; Open <chests> number of <chestID> chest.
    CallOpenChests( chestID, chests )
    {
        if ( chests > 1000 )
            chests := 1000
        else if ( chests < 1 )
            return
        chestParams := "&gold_per_second=0&checksum=4c5f019b6fc6eefa4d47d21cfaf1bc68&user_id=" this.userID "&hash=" this.userHash 
            . "&instance_id=" this.instanceID "&chest_type_id=" chestid "&game_instance_id=" this.activeModronID "&count=" chests
        return this.ServerCall( "opengenericchest", chestParams, 60000 )
    }

    ;A method to check if the party is on the world map. Necessary state to use callLoadAdventure()
    IsOnWorldMap()
    {
        currentAdventure := 0
        userDetails := this.CallUserDetails()
        if ( !IsObject( userDetails ) )
            return "Failed to fetch or build user details."
        for k, v in userDetails.details.game_instances
        {
            if (v.game_instance_id == this.activeInstanceID) 
            {
                currentAdventure := v.current_adventure_id
            }
        }
        if ( currentAdventure == -1 )
            return 1
        else
            return 0
    }
    
    ; Special server call spcifically for use with saves. saveBody must be encoded before using this call.
    ServerCallSave( saveBody, retryNum := 0 ) 
    {
        response := ""
        URLtoCall := this.webroot . "post.php?call=saveuserdetails&"
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        ; https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-settimeouts defaults: 0 (DNS Resolve), 60000 (connection timeout. 60s), 30000 (send timeout), 60000 (receive timeout)
        WR.SetTimeouts( "0", "15000", "7500", "30000" )
        ; WR.SetProxy( 2, "IP:PORT" )  Send web traffic through a proxy server. A local proxy may be helpful for debugging web calls.
        if (this.proxy != "")
            WR.SetProxy(2, this.proxy)
        Try {
            WR.Open( "POST", URLtoCall, true )
            boundaryHeader = 
            (
                multipart/form-data; boundary="BestHTTP"
            )
            WR.SetRequestHeader( "Content-Type", boundaryHeader )
            WR.SetRequestHeader( "User-Agent", "BestHTTP" )
            ;WR.SetRequestHeader( "Accept-Encoding", "identity" )
            WR.Send(saveBody)
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            Try
            {
                response := JSON.parse(data)
                if(!(response.switch_play_server == ""))
                {
                    retryNum += 1
                    this.WebRoot := response.switch_play_server
                    if(retryNum <= 3) 
                        return this.ServerCallSave( saveBody, retryNum ) 
                }
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        return response
    }

    ; Get the loadbalanced Play Server
    CallGetPlayServer() 
    {
        return this.ServerCall("getPlayServerForDefinitions")
    }

    ; Updates the play server used for server calls.
    UpdatePlayServer()
    {
        OutputDebug, % "Old web root is: " . this.webRoot
        oldWebRoot := this.webRoot
        this.webRoot := "http://master.idlechampions.com/~idledragons/"
        response := this.CallGetPlayServer()
        if (response != "" AND response.play_server != "")
            this.webRoot := response.play_server
        else
            this.webRoot := oldWebRoot
        OutputDebug, % "New web root is: " . this.webRoot
        response := this.CallGetPlayServer()
    }
    
    #include *i %A_LineFile%\..\IC_ServerCalls_Class_Extra.ahk
}