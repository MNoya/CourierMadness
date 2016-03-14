--[[ API
    statCollection:SaveHighscore(playerID, value)
    statCollection:GetPersonalHighscores(playerID)
    statCollection:GetTopLeaderboard()
]]

function statCollection:SaveHighscore(playerID, highscoreValue)
    local payload = {
        type           = "SAVE",
        modIdentifier  = self.modIdentifier,
        highscoreID    = "322",--self.highscoreID, --TODO
        steamID32      = PlayerResource:GetSteamAccountID(playerID),
        userName       = PlayerResource:GetPlayerName(playerID),
        highscoreValue = highscoreValue
        schemaVersion  = self.schemaVersion
    }
    
    self:sendStage('s2_highscore.php', payload, function(err, res)
        -- Check if we got an error
        if err then
            print("err")
            return
        end

        -- Check for an error
        if res.error then
            print('res.error')
            return
        end

        -- Tell the user
        print("SaveHighscore")
        DeepPrintTable(res)
    end)
end

function statCollection:GetPersonalHighscores()
    local payload = {
        type           = "LIST",
        modIdentifier  = self.modIdentifier,
        steamID32      = PlayerResource:GetSteamAccountID(playerID),
        schemaVersion  = self.schemaVersion
    }

    self:sendStage('s2_highscore.php', payload, function(err, res)
        -- Check if we got an error
        if err then
            print("err")
            return
        end

        -- Check for an error
        if res.error then
            print('res.error')
            return
        end

        -- Tell the user
        print("GetPersonalHighscores")
        DeepPrintTable(res)

        return obj
    end)
end

function statCollection:GetTopLeaderboard() {
    local payload = {
        type           = "TOP",
        modIdentifier  = self.modIdentifier,
        schemaVersion  = self.schemaVersion
    }
    
    self:sendStage('s2_highscore.php', payload, function(err, res)
        -- Check if we got an error
        if err then
            print("err")
            return
        end

        -- Check for an error
        if res.error then
            print('res.error')
            return
        end

        print("GetTopLeaderboard")
        DeepPrintTable(res)

        return res
    end)
}