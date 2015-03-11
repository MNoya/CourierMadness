life_up_sounds = {
	[1] = "enchantress_ench_ability_enchant_03", --how enchanty
	[2] = "enchantress_ench_ability_enchant_04", --where u goin
	[3] = "enchantress_ench_ability_nature_01", --heal us
	[4] = "enchantress_ench_ability_nature_06", --come get healed
	[5] = "enchantress_ench_move_18", --sproink
	[6] = "enchantress_ench_move_19",
	[7] = "enchantress_ench_move_20"
}

ultimate_sounds = {
	[1] = "omniknight_omni_attack_02", -- I bring the light
	[2] = "omniknight_omni_attack_04", -- say your prayers
	[3] = "omniknight_omni_attack_09", -- knows your sins
	[4] = "omniknight_omni_cast_01", -- judgement comes
	[5] = "CourierMadness.FantasticTeamwork",
	[6] = "omniknight_omni_ability_purif_08", --purified
	[7] = "omniknight_omni_ability_degaura_06", --never scape your sins
	[8] = "omniknight_omni_ability_degaura_10", --cannot flee
	[9] = "CourierMadness.TheyreAllDead",
	[10] = "CourierMadness.WOAW",
}

courier_death_sounds = {
	[1] = "CourierMadness.ArtilleryCorpseExplodeDeath1",
	[2] = "CourierMadness.MooseDeath",
	[3] = "CourierMadness.PigDeath",
	[4] = "CourierMadness.SheepDeath"
}

sheep_death_sounds = {
	[1] = "Hero_ShadowShaman.SheepHex.Target",
	[2] = "CourierMadness.Sheep1",
	[3] = "CourierMadness.Sheep2",
	[4] = "CourierMadness.Sheep3"
}

player_death_trollsounds = {
	[1] = "CourierMadness.BennyHill",
	[2] = "CourierMadness.BestFightEver",
	[3] = "CourierMadness.Disastah",
	[4] = "CourierMadness.TobiLaugh",
	[5] = "CourierMadness.TobiLaugh2",
	[6] = "CourierMadness.Trolololo20"
}

highscore_sounds = {
	[1] = "CourierMadness.SylarToFall",
	[2] = "CourierMadness.HistoryOfDota",
	[3] = "CourierMadness.WOAW"
}

function PlayUltimateSounds()
	-- Basic sound
	EmitGlobalSound("Hero_Zuus.StaticField")
	EmitGlobalSound("CourierMadness.Shockwave")

	-- Check charges
	local charges = GameRules.multiplier or 0	
	if charges >= 5  then
		EmitGlobalSound("Hero_Zuus.GodsWrath.PreCast")
	end

	if charges >= 10 then
		EmitGlobalSound("Hero_Zuus.GodsWrath")
	end

	Timers:CreateTimer(0.5, function() EmitGlobalSound(ultimate_sounds[RandomInt(1,10)]) end)

end

function PlayerFirstTime( )
	EmitGlobalSound("CourierMadness.GameFound")
end

function PlayLifeUpSounds()
	EmitGlobalSound(life_up_sounds[RandomInt(1,7)])
	EmitGlobalSound("Hero_Enchantress.EnchantCast")
end

function PlayMultiplierGainSounds()
	EmitGlobalSound("General.MaleLevelUp")
	local randomGoldSound = RandomInt(1,2)
	if randomGoldSound == 1 then
		EmitGlobalSound("General.Coins")
	elseif randomGoldSound == 2 then
		EmitGlobalSound("DOTA_Item.Hand_Of_Midas")	
	end
end

function PlayPlayerDeathSounds()
	print("RIP PLAYER")

	SendToConsole("stopsound")

	EmitGlobalSound("Hero_Undying.Mausoleum")

	for i=10,19,3 do
		Timers:CreateTimer(i,function() 
			EmitGlobalSound("CourierMadness.Cannibalize")	
		end)
	end
	
	Timers:CreateTimer(1, function() 
		if GameRules.play_highscore_sound == false then
			EmitGlobalSound(player_death_trollsounds[RandomInt(1,6)])
		else
			PlayNewHighscore()
			GameRules.play_highscore_sound = false
		end
	end)

	local ply = PlayerResource:GetPlayer(0)
	Timers:CreateTimer(20, function() ply:PlayMusic() end)
end

function PlayHighDifficultyLevel( )
	print(GameRules.difficulty,"reached!")

	SendToConsole("stopsound")

	if RollPercentage(50) then
		EmitGlobalSound("CourierMadness.AttackOnTitanIntro")
	else
		EmitGlobalSound("CourierMadness.AttackOnTitanOutro")
	end

	-- Apply haste on everything currently on the map
	local couriers = GameRules.couriers
	local donkeys = GameRules.donkeys

	for _,target in pairs(couriers) do
		if IsValidEntity(target) then
			target:SetBaseMoveSpeed(522)
			local particle = ParticleManager:CreateParticle("particles/generic_gameplay/rune_haste_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		end
	end

	for _,target in pairs(donkeys) do
		if IsValidEntity(target) then
			target:SetBaseMoveSpeed(522)
			local particle = ParticleManager:CreateParticle("particles/generic_gameplay/rune_haste_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		end
	end

	local ply = PlayerResource:GetPlayer(0)
	Timers:CreateTimer(20, function() ply:PlayMusic() end)
end

function PlayFluffyTailDeathSounds()
	if RollPercentage(25) then
		EmitGlobalSound("CourierMadness.DryadDeath1")
	else
		local randomPainNumber = RandomInt(1,12)
		local soundName = "enchantress_ench_pain_0"..randomPainNumber
		EmitGlobalSound(soundName)
	end
end

function PlayCourierDeathSounds( )
	EmitGlobalSound(courier_death_sounds[RandomInt(1,4)])
end

function PlayGoldenSheepDeathSound( )
	EmitGlobalSound(sheep_death_sounds[RandomInt(1,4)])
end

function PlayDonkeyDeathSounds( )
	if RollPercentage(50) then
		EmitGlobalSound("omniknight_omni_shitwiz_01")
	else
		EmitGlobalSound("omniknight_omni_crumwiz_01")
	end
end

function PlayLaughSounds()
	local randomLaughNumber = RandomInt(1, 12)
	local soundName = "omniknight_omni_laugh_0"..randomLaughNumber
	EmitGlobalSound(soundName)
end

--when a new highscore would be scored
function PlayNewHighscorePrediction(target)
	EmitGlobalSound(highscore_sounds[RandomInt(1,2)])
	Timers:CreateTimer(4, function() EmitGlobalSound(highscore_sounds[3]) end)

	GameRules.playedHighscorePredictionSound = true

	local player = PlayerResource:GetPlayer(0)
	local hero = player:GetAssignedHero()
	local targetPos = hero:GetAbsOrigin()
    local particle = ParticleManager:CreateParticle( "particles/custom/legion_commander_duel_victories.vpcf", PATTACH_CUSTOMORIGIN, target )
    ParticleManager:SetParticleControl( particle, 3, Vector(targetPos.x, targetPos.y, targetPos.z+322) )

end

-- a new highscore updated
function PlayNewHighscore()
	
	local randomWin = RandomInt(1,3)
	local winSound = "omniknight_omni_win_0"..randomWin
	EmitGlobalSound(winSound)
end