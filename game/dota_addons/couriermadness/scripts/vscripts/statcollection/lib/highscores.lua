--[[ API
    statCollection:SaveHighscore(playerID, value)
    statCollection:GetPersonalHighscores(playerID)
    statCollection:GetTopLeaderboard()
]]

local highscoresSaveError = "Highscores Save Error"
local highscoresSaveSuccess = "Highscores Save Success!"
local highscoresTopSuccess = "Highscores Top Leaderboard:"
local highscoresListSuccess = "Highscores List:"

-- This is for saving a highscore. If you have not secured your highscores, then you do not need the `userAuthKey` field.
function statCollection:SaveHighscore(playerID, highscoreValue)
    local payload = {
        type           = "SAVE",
        modIdentifier  = self.modIdentifier,
        highscoreID    = "322",--self.highscoreID, --TODO
        steamID32      = PlayerResource:GetSteamAccountID(playerID),
        userName       = PlayerResource:GetPlayerName(playerID),
        highscoreValue = highscoreValue,
        userAuthKeystring = "XJAHVAS", --If you have not secured your highscores, then you do not need the `userAuthKey` field.
        schemaVersion  = self.schemaVersion,
    }

    --[[
    {
        "type": "save",
        "result": 0,
        "error": "Invalid JSON",
        "authKey": "XXXXXX",
        "schemaVersion": 1
    }
    ]]
    
    self:sendStage('s2_highscore.php', payload, function(err, res)
        -- Check if we got an error
        if err then
            statCollection:print(highscoresSaveError)
            statCollection:print(err)
            return
        end

        -- Check for an error
        if res.error then
            statCollection:print(highscoresSaveError)
            statCollection:print(res.error)
            return
        end

        -- Tell the user
        statCollection:print(highscoresSaveSuccess)
        DeepPrintTable(res)
    end)
end

-- Gets top 20 players of a highscore type
function statCollection:GetTopLeaderboard()
    local payload = {
        type           = "TOP",
        modIdentifier  = self.modIdentifier,
        highscoreID    = "322",--self.highscoreID, --TODO
        schemaVersion  = self.schemaVersion
    }

    --[[
    {
      "userName": "BMD",
      "steamID32": 28755156,
      "highscoreValue": 12321,
      "date_recorded": "2015-07-11 19:30:03"
    },]]
    
    self:sendStage('s2_highscore.php', payload, function(err, res)
        -- Check if we got an error
        if err then
            statCollection:print(highscoresSaveError)
            statCollection:print(err)
            return
        end

        -- Check for an error
        if res.error then
            statCollection:print(highscoresSaveError)
            statCollection:print(res.error)
            return
        end

        statCollection:print(highscoresTopSuccess)
        DeepPrintTable(res)

        return res
    end)
end

-- Gets all the user's highscores
function statCollection:GetPersonalHighscores()
    local payload = {
        type           = "LIST",
        modIdentifier  = self.modIdentifier,
        steamID32      = PlayerResource:GetSteamAccountID(playerID),
        schemaVersion  = self.schemaVersion
    }

    --[[
    {
      "highscoreID": "h2345kjn52314",
      "highscoreValue": 12321,
      "highscoreAuthKey": "XXXXXXXX",
      "date_recorded": "2015-07-11 19:30:22"
    },
    --]]

    self:sendStage('s2_highscore.php', payload, function(err, res)
        -- Check if we got an error
        if err then
            statCollection:print(highscoresSaveError)
            statCollection:print(err)
            return
        end

        -- Check for an error
        if res.error then
            statCollection:print(highscoresSaveError)
            statCollection:print(res.error)
            return
        end

        statCollection:print(highscoresListSuccess)
        DeepPrintTable(res)

        return obj
    end)
end
