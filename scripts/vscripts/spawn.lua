-- Return a random position inside the Spawn Zone rectangle
function RandomSpawnPosition()
	SpawnX1 = -1024
	SpawnX2 = 1280
	SpawnY1 = 1536
	SpawnY2 = 4611
	SpawnZ  = 128

	local randomPos = Vector( RandomInt(SpawnX1, SpawnX2), RandomInt(SpawnY1, SpawnY2), SpawnZ)

	return randomPos
end

-- Return a random position inside the Death Zone rectangle
function RandomDeathPosition()
	DeathX1 = -1024
	DeathX2 = 1280
	DeathY1 = -2816
	DeathY2 = -2048
	DeathZ  = 128

	local randomPos = Vector( RandomInt(DeathX1, DeathX2), RandomInt(DeathY1, DeathY2), DeathZ)

	return randomPos
end

-- Removes units after touching the trigger
function OnTouchDeathZone( trigger )
	local unit = trigger.activator
	local unit_name = unit:GetUnitName()

	if unit_name == "fluffy_tail" then
		-- Play special death sound
		PlayFluffyTailDeathSounds()

	elseif unit_name == "courier"
		or unit_name == "fat_courier" then

		-- Give 1 point and update score
		GameRules.score = GameRules.score + 1
		--print("SCORE: "..GameRules.score.."(+ 1)")

		-- Laugh Sound in one every 100 deaths
		if RollPercentage(1) then
			PlayLaughSounds()
		end

		FireGameEvent( 'update_scoreboard', { player_ID = pID, score = GameRules.score } )	

		-- Remove from table

	elseif unit_name == "donkey" then
		-- Give 1 point and update score

		GameRules.score = GameRules.score + 1
		--print("SCORE: "..GameRules.score.."(+ 1)")

		-- Remove from table

	elseif unit_name == "golden_courier" then
		-- Play special death sound
		PlayGoldenSheepDeathSound()
	end


	Timers:CreateTimer(0.5, function()
		if IsValidEntity(unit) then
			unit:RemoveSelf()
		end
	end)

	-- WOW
	if GameRules.highscore > 0 and not GameRules.playedHighscorePredictionSound then
		if GameRules.score > GameRules.highscore then
			print("NEW HIGHSCORE REACHED, WOW")
			PlayNewHighscorePrediction()
		end
	end
end

-- Spawns one unit, moving towards the death region.
function SpawnCourier()
	local spawn_pos = RandomSpawnPosition()
	local move_pos = RandomDeathPosition()

	-- Unit has a chance to be fat, slow moving with higher collision.
	local unit	
	local chance = 15 + GameRules.difficulty
	if RollPercentage(chance) then
		unit = CreateUnitByName("fat_courier", spawn_pos, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit:SetBaseMoveSpeed(RandomInt(100,200))
		unit:SetModelScale(1.8)
	else
		unit = CreateUnitByName("courier", spawn_pos, true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit:SetBaseMoveSpeed(RandomInt(200,522))
	end

	local new_model = RandomCourierModel()
	unit:SetModel(new_model)
	unit:SetOriginalModel(new_model)
	ExecuteOrderFromTable({ UnitIndex = unit:entindex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = move_pos, Queue = true})

	table.insert(GameRules.couriers, unit)
end

-- Spawns an unpredictable unit, which has a passive to change change its speed & destination.
function SpawnDonkey()
	GameRules.donkeyChance = 0
	local spawn_pos = RandomSpawnPosition()
	local move_pos = RandomDeathPosition()

	local unit = CreateUnitByName("donkey", spawn_pos, true, nil, nil, DOTA_TEAM_NEUTRALS)
	unit:SetBaseMoveSpeed(RandomInt(200,522))
	
	local new_model = RandomDonkeyModel()
	unit:SetModel(new_model)
	unit:SetOriginalModel(new_model)
	ExecuteOrderFromTable({ UnitIndex = unit:entindex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = move_pos, Queue = true})

	table.insert(GameRules.donkeys, unit)
end

-- Donkeys will change if there are more than 1 spawned at the time, check every second. Random Pos and MS each time.
function ShittyDonkeyMove( event )
	local unit = event.caster
	local spawn_pos = RandomSpawnPosition()
	local move_pos = RandomDeathPosition()

	local donkey_count = #(GameRules.donkeys)
	if donkey_count > 1 then
		unit:SetBaseMoveSpeed(RandomInt(200,522))
		ExecuteOrderFromTable({ UnitIndex = unit:entindex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = move_pos, Queue = false})
	end
end

-- Spawns one extra life unit, moving towards the death region
function SpawnFluffyTail()
	GameRules.extraLifeChance = 0
	local spawn_pos = RandomSpawnPosition()
	local move_pos = RandomDeathPosition()

	local unit = CreateUnitByName("fluffy_tail", spawn_pos, true, nil, nil, DOTA_TEAM_GOODGUYS)
	unit:SetBaseMoveSpeed(RandomInt(150,250))
	
	ExecuteOrderFromTable({ UnitIndex = unit:entindex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = move_pos, Queue = true})

	table.insert(GameRules.fluffy_tails, unit)
end

-- Spawns one extra multiplier unit, moving towards the death region
function SpawnGoldenCourier()
	GameRules.extraMultiplierChance = 0
	local spawn_pos = RandomSpawnPosition()
	local move_pos = RandomDeathPosition()

	local unit = CreateUnitByName("golden_courier", spawn_pos, true, nil, nil, DOTA_TEAM_GOODGUYS)
	unit:SetBaseMoveSpeed(RandomInt(200,300))
	
	ExecuteOrderFromTable({ UnitIndex = unit:entindex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = move_pos, Queue = true})

	table.insert(GameRules.golden_sheeps, unit)
end

-- Returns one of many possible courier models
courier_table = { 
 	[1] = "models/courier/baby_rosh/babyroshan.vmdl",
	[2] = "models/courier/badger/courier_badger.vmdl",
	[3] = "models/courier/defense3_sheep/defense3_sheep.vmdl",
	[4] = "models/courier/lockjaw/lockjaw.vmdl",
	[5] = "models/courier/mechjaw/mechjaw.vmdl",
	[6] = "models/courier/doom_demihero_courier/doom_demihero_courier.vmdl",
	[7] = "models/courier/drodo/drodo.vmdl",
	[8] = "models/courier/frog/frog.vmdl",
	[9] = "models/courier/juggernaut_dog/juggernaut_dog.vmdl",
	[10] = "models/courier/mighty_boar/mighty_boar.vmdl",
	[11] = "models/courier/minipudge/minipudge.vmdl",
	[12] = "models/courier/otter_dragon/otter_dragon.vmdl",
	[13] = "models/courier/sillydragon/sillydragon.vmdl",
	[14] = "models/courier/skippy_parrot/skippy_parrot.vmdl",
	[15] = "models/courier/smeevil/smeevil.vmdl",
	[16] = "models/courier/smeevil_bird/smeevil_bird.vmdl",
	[17] = "models/courier/smeevil_crab/smeevil_crab.vmdl",
	[18] = "models/courier/smeevil_magic_carpet/smeevil_magic_carpet.vmdl",
	[19] = "models/courier/smeevil_mammoth/smeevil_mammoth.vmdl",
	[20] = "models/courier/trapjaw/trapjaw.vmdl",
	[21] = "models/courier/tegu/tegu.vmdl",
	[22] = "models/courier/turtle_rider/turtle_rider.vmdl",
	[23] = "models/courier/yak/yak.vmdl",
	[24] = "models/items/courier/arneyb_rabbit/arneyb_rabbit.vmdl",
	[25] = "models/items/courier/azuremircourierfinal/azuremircourierfinal.vmdl",
	[26] = "models/items/courier/baekho/baekho.vmdl",
	[27] = "models/items/courier/bearzky/bearzky.vmdl",
	[28] = "models/items/courier/beaverknight/beaverknight.vmdl",
	[29] = "models/items/courier/beaverknight_s1/beaverknight_s1.vmdl",
	[30] = "models/items/courier/beaverknight_s2/beaverknight_s2.vmdl",
	[31] = "models/items/courier/blotto_and_stick/blotto.vmdl",
	[32] = "models/items/courier/blue_lightning_horse/blue_lightning_horse.vmdl",
	[33] = "models/items/courier/bookwyrm/bookwyrm.vmdl",
	[34] = "models/items/courier/boooofus_courier/boooofus_courier.vmdl",
	[35] = "models/items/courier/butch_pudge_dog/butch_pudge_dog.vmdl",
	[36] = "models/items/courier/captain_bamboo/captain_bamboo.vmdl",
	[37] = "models/items/courier/coco_the_courageous/coco_the_courageous.vmdl",
	[38] = "models/items/courier/courier_janjou/courier_janjou.vmdl",
	[39] = "models/items/courier/d2l_steambear/d2l_steambear.vmdl",
	[40] = "models/items/courier/deathbringer/deathbringer.vmdl",
	[41] = "models/items/courier/defense4_dire/defense4_dire.vmdl",
	[42] = "models/items/courier/defense4_radiant/defense4_radiant.vmdl",
	[43] = "models/items/courier/dokkaebi_nexon_courier/dokkaebi_nexon_courier.vmdl",
	[44] = "models/items/courier/el_gato_beyond_the_summit/el_gato_beyond_the_summit.vmdl",
	[45] = "models/items/courier/el_gato_hero/el_gato_hero.vmdl",
	[46] = "models/items/courier/g1_courier/g1_courier.vmdl",
	[47] = "models/items/courier/gnomepig/gnomepig.vmdl",
	[48] = "models/items/courier/grim_wolf/grim_wolf.vmdl",
	[49] = "models/items/courier/grim_wolf_radiant/grim_wolf_radiant.vmdl",
	[50] = "models/items/courier/ig_dragon/ig_dragon.vmdl",
	[51] = "models/items/courier/itsy/itsy.vmdl",
	[52] = "models/items/courier/jilling_ben_courier/jilling_ben_courier.vmdl",
	[53] = "models/items/courier/jin_yin_black_fox/jin_yin_black_fox.vmdl",
	[54] = "models/items/courier/jin_yin_white_fox/jin_yin_white_fox.vmdl",
	[55] = "models/items/courier/jumo/jumo.vmdl",
	[56] = "models/items/courier/jumo_dire/jumo_dire.vmdl",
	[57] = "models/items/courier/kupu_courier/kupu_courier.vmdl",
	[58] = "models/items/courier/livery_llama_courier/livery_llama_courier.vmdl",
	[59] = "models/items/courier/lgd_golden_skipper/lgd_golden_skipper.vmdl",
	[60] = "models/items/courier/mei_nei_rabbit/mei_nei_rabbit.vmdl",
	[61] = "models/items/courier/mighty_chicken/mighty_chicken.vmdl",
	[62] = "models/items/courier/mok/mok.vmdl",
	[63] = "models/items/courier/nilbog/nilbog.vmdl",
	[64] = "models/items/courier/premier_league_wyrmeleon/premier_league_wyrmeleon.vmdl",
	[65] = "models/items/courier/pumpkin_courier/pumpkin_courier.vmdl",
	[66] = "models/items/courier/pw_ostrich/pw_ostrich.vmdl",
	[67] = "models/items/courier/pw_zombie/pw_zombie.vmdl",
	[68] = "models/items/courier/raidcall_ems_one_turtle/raidcall_ems_one_turtle.vmdl",
	[69] = "models/items/courier/raiq/raiq.vmdl",
	[70] = "models/items/courier/royal_griffin_cub/royal_griffin_cub.vmdl",
	[71] = "models/items/courier/scribbinsthescarab/scribbinsthescarab.vmdl",
	[72] = "models/items/courier/scuttling_scotty_penguin/scuttling_scotty_penguin.vmdl",
	[73] = "models/items/courier/shagbark/shagbark.vmdl",
	[74] = "models/items/courier/shroomy/shroomy.vmdl",
	[75] = "models/items/courier/snaggletooth_red_panda/snaggletooth_red_panda.vmdl",
	[76] = "models/items/courier/snail/courier_snail.vmdl",
	[77] = "models/items/courier/snapjaw/snapjaw.vmdl",
	[78] = "models/items/courier/snowl/snowl.vmdl",
	[79] = "models/items/courier/starladder_grillhound/starladder_grillhound.vmdl",
	[80] = "models/items/courier/teron/teron.vmdl",
	[81] = "models/items/courier/throe/throe.vmdl",
	[82] = "models/items/courier/tory_the_sky_guardian/tory_the_sky_guardian.vmdl",
	[83] = "models/items/courier/vigilante_fox_green/vigilante_fox_green.vmdl",
	[84] = "models/items/courier/vigilante_fox_red/vigilante_fox_red.vmdl",
	[85] = "models/items/courier/virtus_werebear_t1/virtus_werebear_t1.vmdl",
	[86] = "models/items/courier/virtus_werebear_t3/virtus_werebear_t3.vmdl",
	[87] = "models/items/courier/waldi_the_faithful/waldi_the_faithful.vmdl",
	[88] = "models/courier/godhorse/godhorse.vmdl",
	[89] = "models/courier/frull/frull_courier.vmdl",
	[90] = "models/courier/imp/courier_imp.vmdl",
	[91] = "models/courier/octopus/octopus.vmdl",
	[92] = "models/courier/navi_courier/navi_courier.vmdl",
	[93] = "models/items/courier/billy_bounceback/billy_bounceback.vmdl",
	[94] = "models/items/courier/bucktooth_jerry/bucktooth_jerry.vmdl",
	[95] = "models/items/courier/courier_faun/courier_faun.vmdl",
	[96] = "models/items/courier/echo_wisp/echo_wisp.vmdl",
	[97] = "models/items/courier/deathripper/deathripper.vmdl",
	[98] = "models/items/courier/vaal_the_animated_constructdire/vaal_the_animated_constructdire.vmdl",
	[99] = "models/courier/f2p_courier/f2p_courier.vmdl",
	[100] = "models/courier/mega_greevil_courier/mega_greevil_courier.vmdl"

	-- Fying and some other couriers are ignored
	-- [] = "",
}

-- Donkeys are full of bullshit
donkey_table = {
	[1] = "models/courier/donkey_unicorn/donkey_unicorn.vmdl",
	[2] = "models/courier/donkey_crummy_wizard_2014/donkey_crummy_wizard_2014.vmdl",
	[3] = "models/courier/sw_donkey/sw_donkey.vmdl",
	[4] = "models/props_gameplay/donkey.vmdl",
	[5] = "models/props_gameplay/donkey_dire.vmdl"
}

function RandomCourierModel()
	return courier_table[RandomInt(1,100)]
end

function RandomDonkeyModel()
	return donkey_table[RandomInt(1,5)]
end

function ApplyDismemberAnimation( unit )
	unit:RemoveModifierByName("modifier_courier_run")
	local animations = CreateItem("item_apply_modifiers", nil, nil)
	local start_time = GameRules:GetGameTime()
	local time_until_restart = 20
	animations:ApplyDataDrivenModifier(unit, unit, "modifier_courier_capture", {duration=time_until_restart})
	animations:RemoveSelf()

	Timers:CreateTimer(time_until_restart-0.1, function() 
		if IsValidEntity(unit) then unit:RemoveSelf()	
	end end) 

end

function BloodParticles( event )
	local targetLoc = event.target:GetAbsOrigin()

	local centaur_blood_fx = "particles/custom/centaur_double_edge_bloodspray_src.vpcf"
	local riki_blood_fx = "particles/units/heroes/hero_riki/riki_backstab_hit_blood.vpcf"
	local nyx_blood = "particles/custom/nyx_assassin_spiked_carapace_hit_blood.vpcf"

	local lifestealer_blood_fx1 = "particles/custom/life_stealer_infest_emerge_bloody_low.vpcf"
	local lifestealer_blood_fx2 = "particles/custom/life_stealer_infest_emerge_bloody_mid.vpcf"

	local pa_blood_fx = "particles/custom/phantom_assassin_crit_impact.vpcf"

	local random_blood_splatter = RandomInt(1,3)
	if random_blood_splatter == 1 then
		local blood = ParticleManager:CreateParticle(centaur_blood_fx, PATTACH_CUSTOMORIGIN, event.target)
		ParticleManager:SetParticleControl(blood, 0, targetLoc)
		ParticleManager:SetParticleControl(blood, 2, targetLoc+RandomVector(RandomInt(100,200)))
		ParticleManager:SetParticleControl(blood, 4, targetLoc+RandomVector(RandomInt(100,200)))
		ParticleManager:SetParticleControl(blood, 5, targetLoc+RandomVector(RandomInt(100,200)))

	elseif random_blood_splatter == 2 then
		local blood = ParticleManager:CreateParticle(riki_blood_fx, PATTACH_CUSTOMORIGIN, event.target)
		ParticleManager:SetParticleControl(blood, 0, targetLoc)

	elseif random_blood_splatter == 3 then	
		local blood = ParticleManager:CreateParticle(nyx_blood, PATTACH_CUSTOMORIGIN, event.target)
		ParticleManager:SetParticleControl(blood, 0, targetLoc)
		ParticleManager:SetParticleControl(blood, 1, targetLoc)
	end

	if RollPercentage(75) then
		local blood = ParticleManager:CreateParticle(lifestealer_blood_fx1, PATTACH_CUSTOMORIGIN, event.target)
		ParticleManager:SetParticleControl(blood, 0, targetLoc)
	else
		local blood = ParticleManager:CreateParticle(lifestealer_blood_fx2, PATTACH_CUSTOMORIGIN, event.target)
		ParticleManager:SetParticleControl(blood, 0, targetLoc)
	end
	
	if RollPercentage(50) then
		local blood = ParticleManager:CreateParticle(pa_blood_fx, PATTACH_CUSTOMORIGIN, event.target)
		ParticleManager:SetParticleControl(blood, 0, targetLoc)
		ParticleManager:SetParticleControl(blood, 1, targetLoc+RandomVector(RandomInt(0,500)))
	end	

end

function PlayExtraCourierDeathParticle(target)

	-- Extra particle for model
	if target:GetModelName() == "models/courier/mechjaw/mechjaw.vmdl" then
		local particle = ParticleManager:CreateParticle("particles/econ/courier/courier_mechjaw/mechjaw_death.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )

	elseif target:GetModelName() == "models/courier/doom_demihero_courier/doom_demihero_courier.vmdl" then
		local particle = ParticleManager:CreateParticle("particles/econ/items/doom/doom_f2p_death_effect/doom_bringer_f2p_death.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )

	elseif target:GetModelName() == "models/courier/trapjaw/trapjaw.vmdl" then
		local particle = ParticleManager:CreateParticle("particles/econ/courier/courier_trapjaw/courier_trapjaw_ambient_death.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
		
	elseif target:GetModelName() == "models/courier/drodo/drodo.vmdl" then
		local particle = ParticleManager:CreateParticle("particles/econ/courier/courier_drodo/courier_drodo_ambient_death.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )

	elseif target:GetModelName() == "models/items/courier/vaal_the_animated_constructdire/vaal_the_animated_constructdire.vmdl" then
		local particle = ParticleManager:CreateParticle("particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_death_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )

	elseif target:GetModelName() == "models/courier/f2p_courier/f2p_courier.vmdl" then
		local particle = ParticleManager:CreateParticle("particles/econ/items/techies/techies_arcana/techies_taunt.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )

	elseif target:GetModelName() == "models/items/courier/deathripper/deathripper.vmdl" then
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
	
	elseif target:GetModelName() == "models/courier/donkey_unicorn/donkey_unicorn.vmdl" or
		   target:GetModelName() == "models/courier/donkey_crummy_wizard_2014/donkey_crummy_wizard_2014.vmdl" or
		   target:GetModelName() == "models/courier/sw_donkey/sw_donkey.vmdl" then
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_taunt_compendium.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
	end
end

