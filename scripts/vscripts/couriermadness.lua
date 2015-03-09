--[[
-> Features Necessary

-- UI for score and multiplier.
-- UI for Highest Score
-- Custom VTEX Splat! Eyes particle
-- Make each game session independant
]]

print ('[COURIERMADNESS] couriermadness.lua' )

COURIERMADNESS_VERSION = "1<font color='#FFC800'>.</font>0<font color='#FFC800'>.</font>0"

CAMERA_DISTANCE_OVERRIDE = 1400.0
DISABLE_FOG_OF_WAR_ENTIRELY = false

USE_CUSTOM_HERO_LEVELS = true           -- Should we allow heroes to have custom levels?
MAX_LEVEL = 50                          -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = true             -- Should we use custom XP values to level up heroes, or the default Dota numbers?

MOUSE_STREAM_ENABLED = false

-- Fill this table up with the required XP per level if you want to change it
XP_PER_LEVEL_TABLE = {}
for i=1,MAX_LEVEL do
	XP_PER_LEVEL_TABLE[i] = i * 100
end

-- Generated from template
if GameMode == nil then
	GameMode = class({})
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:InitGameMode()
	GameMode = self
	print('[COURIERMADNESS] Starting to load couriermadness gamemode...')

	-- Setup rules
	GameRules:SetHeroRespawnEnabled( false )
	GameRules:SetUseUniversalShopMode( false )
	GameRules:SetSameHeroSelectionEnabled( true )
	GameRules:SetHeroSelectionTime( 1.0 )
	GameRules:SetPreGameTime( 0.0 )
	GameRules:SetPostGameTime( 60.0 )
	GameRules:SetGoldPerTick(0)
	GameRules:SetGoldTickTime(0)
	GameRules:SetHeroMinimapIconScale( 1 )
	GameRules:SetCreepMinimapIconScale( 1 )
	GameRules:SetHideKillMessageHeaders( true )

	print('[COURIERMADNESS] GameRules set')

	-- Listeners - Event Hooks
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(GameMode, 'OnPlayerPickHero'), self)

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	-- Initialized tables for tracking state
	self.vUserIds = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}

	self.vPlayers = {}
	self.vRadiant = {}
	self.vDire = {}

	self.bSeenWaitForPlayers = false

	GameRules.rounds_played = 0
	GameRules.highscore = 0
	GameRules.scores_list = {}

	GameRules.score = 0 -- +1 with each enemy is removed, +1*multiplier when using ult
	GameRules.difficulty = 0 -- Increases every 25 seconds, up to 50. Hidden
	GameRules.multiplier = 0 -- Increases every 20 seconds

	GameRules.extraLifeChance = 0 -- Increases every 10 seconds
	GameRules.extraMultiplierChance = 0 -- Increases every 15 seconds
	GameRules.donkeyChance = 0 -- Increases every second and scales with difficulty

	GameRules.couriers = {}
	GameRules.donkeys = {}
	GameRules.fluffy_tails = {}
	GameRules.golden_sheeps = {}

	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	GameRules.Soundtrack = LoadKeyValues("scripts/soundtrack.kv")

	-- 1 HP per bar marker
	SendToServerConsole("dota_health_per_vertical_marker 1")

	GameRules:GetGameModeEntity():SetThink("SetPermanentDaytime", self)
	GameRules:GetGameModeEntity():SetThink( "DisableCheats", self )

	self.leftEdge = Entities:FindByName(nil, "left_edge")
	self.rightEdge = Entities:FindByName(nil, "right_edge")


	print('[COURIERMADNESS] Done loading couriermadness gamemode!\n\n')
end

mode = nil

function GameMode:SetPermanentDaytime()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameRules:SetTimeOfDay( 0.3 )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then		    		
        -- Delete the thinker
        return
	end
	return 10
end

function GameMode:DisableCheats()
	SendToConsole("dota_workshoptest 0")
	SendToConsole("sv_cheats 0")
	return 1
end

-- This function is called 1 to 2 times as the player connects initially but before they have completely connected
function GameMode:PlayerConnect(keys)
	print('[COURIERMADNESS] PlayerConnect')

	if keys.bot == 1 then
		-- This user is a Bot, so add it to the bots table
		self.vBots[keys.userid] = 1
	end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
	print ('[COURIERMADNESS] OnConnectFull')
	GameMode:CaptureGameMode()

	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- Update the user ID table with this user
	self.vUserIds[keys.userid] = ply

	-- Update the Steam ID table
	self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply

	-- If the player is a broadcaster flag it in the Broadcasters table
	if PlayerResource:IsBroadcaster(playerID) then
		self.vBroadcasters[keys.userid] = 1
		return
	end

	-- If there's more than 1 player, put them as spectators.
	for nPlayerID = 1, DOTA_MAX_PLAYERS-1 do
		if PlayerResource:IsValidPlayer(nPlayerID) and not PlayerResource:IsBroadcaster(nPlayerID) then 
			PlayerResource:SetCustomTeamAssignment(nPlayerID, 1 )
		end
	end
end

-- This function is called as the first player loads and sets up the GameMode parameters
function GameMode:CaptureGameMode()
	if mode == nil then
		-- Set GameMode parameters
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled( true ) -- Hide HUD instead
		mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
		mode:SetBuybackEnabled( false )
		mode:SetTopBarTeamValuesOverride ( true )
		mode:SetTopBarTeamValuesVisible( false )
		mode:SetUseCustomHeroLevels ( USE_CUSTOM_HERO_LEVELS )
		mode:SetCustomHeroMaxLevel ( MAX_LEVEL )
		mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

		mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)

		-- Hide some HUD elements
		mode:SetHUDVisible(0, false) --Clock
		mode:SetHUDVisible(1, false)
		mode:SetHUDVisible(2, false)
		mode:SetHUDVisible(6, false)
		mode:SetHUDVisible(7, false) 
		mode:SetHUDVisible(8, false) 
		mode:SetHUDVisible(9, false)
		mode:SetHUDVisible(11, false)
		mode:SetHUDVisible(12, false)

		--mode:SetHUDVisible(3, false) --Action Panel is hidden in flash
		mode:SetHUDVisible(4, false) --Minimap
		mode:SetHUDVisible(5, false) --Inventory
		Convars:SetInt("dota_render_crop_height", 0) -- Renders the bottom part of the screen

		self:OnFirstPlayerLoaded()
	end
end

-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
	print("[COURIERMADNESS] GameRules State Changed")

	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local et = 6
		if self.bSeenWaitForPlayers then
			et = .01
		end
		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
				if PlayerResource:HaveAllPlayersJoined() then
					GameMode:OnAllPlayersLoaded()
					return
				end
				return 1
			end})
	end
end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function GameMode:OnFirstPlayerLoaded()
	print("[COURIERMADNESS] First Player has loaded")

	local player = PlayerResource:GetPlayer(0)
	SendToConsole("dota_camera_pitch_max 50")
	SendToConsole("dota_camera_yaw 90")
	SendToConsole("dota_draw_portrait 0")
	SendToConsole("host_timescale 1")

end

function GameMode:OnAllPlayersLoaded()
	print("[COURIERMADNESS] All Players have loaded into the game")
end

-- Starts the spawns and core logic
function GameMode:OnGameInProgress()
	print("[COURIERMADNESS] The game has officially begun")

	-- ReInitialize scores
	GameRules.score = 0 -- +1 with each enemy is removed, +1*multiplier when using ult
	GameRules.difficulty = 0 -- Increases every 25 seconds, up to 50. Hidden
	GameRules.multiplier = 0 -- Increases every 20 seconds

	GameRules.extraLifeChance = 0 -- Increases every 10 seconds
	GameRules.extraMultiplierChance = 0 -- Increases every 15 seconds
	GameRules.donkeyChance = 0 -- Increases every second and scales with difficulty

	GameRules.couriers = {}
	GameRules.donkeys = {}
	GameRules.fluffy_tails = {}
	GameRules.golden_sheeps = {}

	-- Play Liquid are doing it, WOW, when beating your old score
	GameRules.playedHighscorePredictionSound = false
	-- Play WIN sounds! History of Dota
	GameRules.play_highscore_sound = false

	DIFFICULTY_INCREASE_TIME = 20.0
	MULTIPLIER_INCREASE_TIME = 20.0
	MAX_DIFFICULTY_LEVEL = 50
	COURIER_INTERVAL = 1.0
	DONKEY_INTERVAL = 1.0
	FLUFFY_TAIL_INTERVAL = 10.0
	GOLDEN_INTERVAL = 10.0

	-- Stop All Sounds
	SendToConsole("stopsound")

	-- Play Meme Sounds
	StartSoundTracks()

	-- ?? Ony spawn units if the game is running. 
	-- Game is running if the player 0 hero isn't dead. 
	-- Else there is a cinematic interval and it starts again
	local player = PlayerResource:GetPlayer(0)
	local hero = player:GetAssignedHero()
	local ultimate = hero:FindAbilityByName("dodger_ultimate")
    ultimate:StartCooldown(ultimate:GetCooldown(1))
    Timers:CreateTimer(ultimate:GetCooldown(1), function()
		ultimate:ApplyDataDrivenModifier(hero, hero, "modifier_hammer_glow", {}) 
	end)
	
	-- Stats Collection Highscores
	-- This is for Flash to know its steamID
	j = {}
	for i=0,9 do
		j[i+1] = tostring(PlayerResource:GetSteamAccountID(i))
	end
	local result = table.concat(j, ",")
	j = {ids=result}
	FireGameEvent("stat_collection_steamID", j)

	-- Update scoreboard
	FireGameEvent( 'update_scoreboard', { player_ID = pID, score = GameRules.score } )
	FireGameEvent( 'update_multiplier', { player_ID = pID, multiplier = GameRules.multiplier } )
	Timers:CreateTimer(1,function() FireGameEvent( 'show_highscore', {}) end) --This will check for the highscore in GetDotaStats

	-- Increase Difficulty every DIFFICULTY_INCREASE_TIME up to MAX_DIFFICULTY_LEVEL
	Timers:CreateTimer("IncreaseDifficulty", { 
		endTime = DIFFICULTY_INCREASE_TIME,
		callback = function()
		if GameRules.difficulty < 50 then		
			GameRules.difficulty = GameRules.difficulty + 1
			print("Current difficulty: "..GameRules.difficulty)
			if (GameRules.difficulty % 10 ) == 0 then PlayHighDifficultyLevel() end
		end
		return DIFFICULTY_INCREASE_TIME		
	end } )

	-- Special Move 20 seconds CD, increase multiplier if the player already has it ready.
	-- Using the ultimate ability resets the multiplier GetCooldownTimeRemaining
	Timers:CreateTimer("IncreaseMultiplier", { 
		endTime = MULTIPLIER_INCREASE_TIME,
		callback = function()
		if ultimate:IsFullyCastable() then
			GameRules.multiplier = GameRules.multiplier + 1
			print("Current multiplier: "..GameRules.multiplier)
			-- Play Particle
			local particle = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)

			-- Play Sound
			PlayMultiplierGainSounds()

			-- Update Multiplier score
			FireGameEvent( 'update_multiplier', { player_ID = pID, multiplier = GameRules.multiplier } )

			PopupMultiplierGain(hero, GameRules.multiplier)

			return MULTIPLIER_INCREASE_TIME
		else

			local time_remaining = ultimate:GetCooldownTimeRemaining()
			return time_remaining+0.1
		end
	end })

	-- MakeCouriers()
	Timers:CreateTimer("MakeCouriers", { callback = function()
		local couriers_to_spawn = RandomInt(1, GameRules.difficulty)
		--print("Spawning "..couriers_to_spawn.." couriers")
		for i=1,couriers_to_spawn do
			SpawnCourier()
		end
		return COURIER_INTERVAL
	end })

	-- MakeDonkeys()
	Timers:CreateTimer("MakeDonkeys", { callback = function()
		GameRules.donkeyChance = GameRules.donkeyChance + 1		
		for i=1,4 do
			if RandomInt(1, 125 - GameRules.difficulty) < GameRules.donkeyChance then
				SpawnDonkey()
			end	
		end
		return DONKEY_INTERVAL
	end })

	-- MakeFluffyTails()
	Timers:CreateTimer("MakeFluffyTails", { 
		endTime = FLUFFY_TAIL_INTERVAL,
		callback = function()
		GameRules.extraLifeChance = GameRules.extraLifeChance + 1
		if RandomInt(1,20) <= GameRules.extraLifeChance then
			SpawnFluffyTail()
		end
		return FLUFFY_TAIL_INTERVAL
	end })

	-- MakeGoldenSheeps()
	Timers:CreateTimer("MakeGoldenSheeps", { callback = function()
		GameRules.extraMultiplierChance = GameRules.extraMultiplierChance + 1
		if RandomInt(1,10) <= GameRules.extraMultiplierChance then
			SpawnGoldenCourier()
		end
		return GOLDEN_INTERVAL
	end })
end

-- A player picked a hero.
function GameMode:OnPlayerPickHero(keys)
	print ('[COURIERMADNESS] OnPlayerPickHero')
	
	local heroClass = keys.hero
	local heroEntity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)

end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)
	--print("[COURIERMADNESS] NPC Spawned")
	local npc = EntIndexToHScript(keys.entindex)

	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		print("ID",npc:GetPlayerID())
		GameMode:OnHeroInGame(npc)

	-- Restart
	elseif npc:IsRealHero() then
		print("============= RESTARTED =============")
		GameMode:OnGameInProgress()
		SendToConsole("dota_camera_pitch_max 50")
		SendToConsole("dota_camera_yaw 90")
		GameRules:GetGameModeEntity():SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
		Timers:CreateTimer(function() FireGameEvent( 'toggle_restart', {} ) end)

	end
end

-- Check for Hero Killed, stop the Timers
function GameMode:OnEntityKilled(keys)
	local killedUnit = EntIndexToHScript(keys.entindex_killed)

	if killedUnit:IsRealHero() then

		-- Check to Update the highscore
		FireGameEvent( 'update_highscore', { player_ID = pID, score = GameRules.score } )

		GameRules.rounds_played = GameRules.rounds_played + 1

		-- Track this score
		table.insert(GameRules.scores_list, GameRules.score)

		-- Show Game Restart...
		Timers:CreateTimer(function() FireGameEvent( 'toggle_restart', {} ) end)

		-- Send stats for this round
		Timers:CreateTimer(1, function() statcollection.sendStats() end)

		local heroLoc = killedUnit:GetAbsOrigin()
		
		--Unit to play the blood effects
		GameRules.herodummy = CreateUnitByName("dummy_bloody_unit", heroLoc, false, nil, nil, killedUnit:GetTeamNumber()) 

		killedUnit:SetTimeUntilRespawn(20)
		Timers:CreateTimer(18, function() GameRules.herodummy:RemoveSelf()  end)
		Timers:CreateTimer(20, function() killedUnit:RespawnHero(false, false, false) end)
		Timers:RemoveTimer("IncreaseDifficulty")
		Timers:RemoveTimer("IncreaseMultiplier")
		Timers:RemoveTimer("MakeCouriers")
		Timers:RemoveTimer("MakeDonkeys")
		Timers:RemoveTimer("MakeFluffyTails")
		Timers:RemoveTimer("MakeGoldenSheeps")

		-- Send some nearby units towards the death hero for the cinematic
		for _,courier in pairs(GameRules.couriers) do
			if IsValidEntity(courier) then
				courier:SetBaseMoveSpeed(522)
				ExecuteOrderFromTable({ UnitIndex = courier:entindex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = heroLoc+RandomVector(RandomInt(80,120)), Queue = false})
				courier:SetForwardVector( (courier:GetAbsOrigin() - heroLoc):Normalized() )			
				ApplyDismemberAnimation(courier)
			end
		end

		for _,donkey in pairs(GameRules.donkeys) do
			if IsValidEntity(donkey) then
				ExecuteOrderFromTable({ UnitIndex = donkey:entindex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = killedUnit:GetAbsOrigin()+RandomVector(RandomInt(80,120)), Queue = false})
				donkey:SetForwardVector( (donkey:GetAbsOrigin() - heroLoc):Normalized() )			
				ApplyDismemberAnimation(donkey)				
			end
		end

		for _,ench in pairs (GameRules.fluffy_tails) do
			if IsValidEntity(ench) then
				ench:RemoveSelf()
			end
		end

		for _,sheep in pairs (GameRules.golden_sheeps) do
			if IsValidEntity(sheep) then
				sheep:RemoveSelf()
			end
		end


		-- Particles and shit, remove the units later.

		-- dota_camera_pitch_max default = 50
		-- dota_camera_yaw default = 90
		-- CAMERA_DISTANCE_OVERRIDE = 1400
		local camera_loop = {}
		camera_loop.pitch_max = 50 --{-100 to 100}, 
		camera_loop.yaw = 90 --{0 to 360}, 
		camera_loop.distance = 1400
		SendToConsole("r_farz 5000")

		for i=1,100 do

			Timers:CreateTimer(i*0.03, function()

				camera_loop.pitch_max = camera_loop.pitch_max - 0.2 --up to 10
				camera_loop.yaw = camera_loop.yaw + 1.8 --up to 270
				camera_loop.distance = camera_loop.distance - 6 --1400 to 800

				SendToConsole("dota_camera_pitch_max "..camera_loop.pitch_max)
				SendToConsole("dota_camera_yaw "..camera_loop.yaw)
				mode:SetCameraDistanceOverride( camera_loop.distance )

			end)
		end

		-- 10 sec later, rotate another 180, from 270 to 450
		Timers:CreateTimer(10.0, function() 
			for i=1,100 do
				Timers:CreateTimer(i*0.03, function()

					camera_loop.yaw = camera_loop.yaw + 1.8
					camera_loop.distance = camera_loop.distance + 6 --1400 to 800

					--SendToConsole("dota_camera_pitch_max "..camera_loop.pitch_max)
					SendToConsole("dota_camera_yaw "..camera_loop.yaw)
					mode:SetCameraDistanceOverride( camera_loop.distance )
				end)
			end		
		end)
	end
end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in.
]]
function GameMode:OnHeroInGame(hero)
	print("[COURIERMADNESS] Hero spawned in game for first time -- " .. hero:GetUnitName())

	-- Store a reference to the player handle inside this hero handle.
	hero.player = PlayerResource:GetPlayer(hero:GetPlayerID())
	-- Store the player's name inside this hero handle.
	hero.playerName = PlayerResource:GetPlayerName(hero:GetPlayerID())
	-- Store this hero handle in this table.
	table.insert(self.vPlayers, hero)

	hero.lastCameraUpdateTime = GameRules:GetGameTime()

	--dota_camera_lock_lerp
	--dota_camera_speed

	-- Initialize the hero abilities
	hero:SetAbilityPoints(0)
	for i=0, hero:GetAbilityCount()-1 do
        local abil = hero:GetAbilityByIndex(i)
        if abil ~= nil then
            abil:SetLevel(1)
        end
    end

    local pID = hero:GetPlayerID()

    -- Show the initial popup
    FireGameEvent("show_gamerules_popup", { player_ID = pID })

    -- Initialize the Ultimate UI
    Timers:CreateTimer(function() FireGameEvent( 'show_ultimate_ability', { player_ID = pID } ) end)

end


-- register the 'HighscoreAchieved' command in our console
Convars:RegisterCommand( "HighscoreAchieved", function(name, p)
	print( '******* Highscore Achieved ***************' )
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			--if the player is valid, make the visuals
        	return GameMode:ShowHighscoreAchieved( cmdPlayer , p)
		end
	end
	print( '*********************************************' )
end, "A player gets a new highscore", 0 )

function GameMode:ShowHighscoreAchieved( player, score)

	GameRules.highscore = tonumber(score)
	local hero = player:GetAssignedHero()

	PopupLegion( hero, score )

	-- Enable the highscore sound bool this next death sound
	GameRules.play_highscore_sound = true

	GameRules:SendCustomMessage("NEW HIGHSCORE! <font color='#FFC800'>"..score.."</font>",0,0)

	local s = tonumber(score)
	if s < 500 then
		PopupKillbanner(hero, "firstblood")
	elseif s < 1000 then
		PopupKillbanner(hero, "doublekill")
	elseif s < 2000 then
		PopupKillbanner(hero, "triplekill")
	elseif s < 3000 then
		PopupKillbanner(hero, "multikill_generic")
	else
		PopupKillbanner(hero, "rampage")
	end

end

-- register the 'OldHighscoreDetected' command in our console
Convars:RegisterCommand( "OldHighscoreDetected", function(name, p)
	GameRules.highscore = tonumber(p) -- Keep track of the highscore
	print(GameRules.rounds_played)
	if GameRules.rounds_played == 0 then
		print( '******* Old Highscore Detected  ***************' )
		local cmdPlayer = Convars:GetCommandClient()
		if cmdPlayer then
			local playerID = cmdPlayer:GetPlayerID()
			if playerID ~= nil and playerID ~= -1 then
				--if the player is valid, make the message
	        	return GameMode:ShowWelcomeHighscore( cmdPlayer , p)
			end
		end
		print( '*********************************************' )
	end
end, "A player has an old highscore", 0 )

function GameMode:ShowWelcomeHighscore( player, score)
	GameRules:SendCustomMessage("Welcome back to <font color='#FFC800'>Courier Madness!</font>", 0, 0)
	GameRules:SendCustomMessage("Your all-time highscore is <font color='#FFC800'>"..score.."</font>",0,0)

	Timers:CreateTimer(5, function() GameRules:SendCustomMessage("<font color='#FFC800'>Turn Sounds On</font> for dank music effects!", 0, 0) end)
end

-- register the 'ShowGamerules' command in our console
Convars:RegisterCommand( "ShowFirstTime", function(name, p)
		print( '******* First Time Playing Detected  ***************' )
		local cmdPlayer = Convars:GetCommandClient()
		if cmdPlayer then
			local playerID = cmdPlayer:GetPlayerID()
			if playerID ~= nil and playerID ~= -1 then
				--if the player is valid, make the message
	        	return GameMode:ShowFirstTime( cmdPlayer )
			end
		end
		print( '*********************************************' )
end, "A player runs the game for the first time ever", 0 )

function GameMode:ShowFirstTime( player )
	GameRules:SendCustomMessage("Welcome to <font color='#FFC800'>Courier Madness!</font>", 0, 0)
	GameRules:SendCustomMessage("Created by <font color='#FFC800'>Noya</font>", 0, 0)

	Timers:CreateTimer(5, function() GameRules:SendCustomMessage("<font color='#FFC800'>Turn Sounds On</font> for dank music effects!", 0, 0) end)
end


-- register the 'StartGame' command in our console, when the player clicks OK to start
Convars:RegisterCommand( "StartGame", function(name, p)
		print( '******* GAME START  ***************' )
		local cmdPlayer = Convars:GetCommandClient()
		if cmdPlayer then
			local playerID = cmdPlayer:GetPlayerID()
			if playerID ~= nil and playerID ~= -1 then
				--if the player is valid, make the message
	        	return GameMode:StartGame()
			end
		end
		print( '*********************************************' )
end, "A player runs the game for the first time ever", 0 )

function GameMode:StartGame()
	GameMode:OnGameInProgress()
end


-- register the 'Disconnecting' command in our console
Convars:RegisterCommand( "Disconnecting", function(name, p)
	print( ' Disconnecting !!!' )
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			--if the player is valid, send stats and disconnect
        	return GameMode:EndGame( cmdPlayer )
		end
	end
end, "A player chooses exit", 0 )


Convars:RegisterCommand( "MouseStreamToggle", function(name, p)
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			MouseStreamToggle(cmdPlayer)
		end
	end
end, "", 0 )

function GameMode:EndGame( player, score)
	-- Send stats final
	statcollection.sendStats()
	GameRules:SendCustomMessage("<font color='#FFC800'><br>Game will end in 10 seconds</font>",0,0)
	Timers:CreateTimer(4, function() GameRules:SendCustomMessage("<font color='#FFC800'>Please leave your feedback at our workshop page</font>",0,0) end)
	Timers:CreateTimer(7, function() GameRules:SendCustomMessage("<font color='#FFC800'>3</font>",0,0) end)
	Timers:CreateTimer(8, function() GameRules:SendCustomMessage("<font color='#FFC800'>2</font>",0,0) end)
	Timers:CreateTimer(9, function() GameRules:SendCustomMessage("<font color='#FFC800'>1...</font>",0,0) end)
	Timers:CreateTimer(10, function() SendToConsole("disconnect") end)
end

function MouseStreamToggle( hPlayer )
	local hero = hPlayer:GetAssignedHero()
	if not MOUSE_STREAM_ENABLED then
		print("Enabling MouseStream")
		MOUSE_STREAM_ENABLED = true
		hPlayer.cursorStream = FlashUtil:RequestDataStream( "cursor_position_world", .01, hPlayer:GetPlayerID(), function(playerID, cursorPos)
			local validPos = true
			if cursorPos.x > 30000 or cursorPos.y > 30000 or cursorPos.z > 30000 then
				validPos = false
			end
			if validPos and hero:IsAlive() then
				local event = {caster = hero, offset = 100}
				-- snap cursor to a grid square
				local cursorGridX = GridNav:WorldToGridPosX(cursorPos.x)
				local originGridX = GridNav:WorldToGridPosX(hero:GetAbsOrigin().x)
				local moveRight = true
				if cursorGridX < originGridX then 
					moveRight = false
				end
				if cursorGridX > originGridX+.8 or cursorGridX < originGridX-.8 then
					if moveRight then MoveRight(event)
					else MoveLeft(event) end
				else
					hero:Stop()
				end
			end

		end)
	else
		FlashUtil:StopDataStream( hPlayer.cursorStream )
		MOUSE_STREAM_ENABLED = false
		hPlayer.cursorStream = nil
	end
end