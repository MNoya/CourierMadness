function MoveLeft( event )
	local caster = event.caster
	local offset = event.offset
	if not offset then offset = 200 end

	local origin = caster:GetAbsOrigin()
	local pos = Vector(origin.x-offset, origin.y, origin.z)
	ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = pos, Queue = false})
	UpdateCamera(caster,origin.x-offset)
	--print("Moving to "..origin.x-offset)
end

function MoveRight( event )
	local caster = event.caster
	local offset = event.offset
	if not offset then offset = 200 end

	local origin = caster:GetAbsOrigin()
	local pos = Vector(origin.x+offset, origin.y, origin.z)
	ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = pos, Queue = false}) 
	UpdateCamera(caster,origin.x+offset)
	--print("Moving to "..origin.x+offset)
end

function CheckCollision( event )
	local caster = event.caster
	local position = caster:GetAbsOrigin()
	local targets = event.target_entities
	local unit_table = GameRules.UnitKV

	for _,target in pairs(targets) do
		local distance = (position - target:GetAbsOrigin()):Length()
		local name = target:GetUnitName()
		local collision_size = unit_table[name].RingRadius
		
		if distance <= collision_size then
			print("Got hit by a "..name)
			local currentLives = caster:GetHealth()
			local maxHP = caster:GetMaxHealth()

			if name == "fluffy_tail" then
				print("+ 1 life")
				-- Play Particle
				local particle = ParticleManager:CreateParticle("particles/generic_gameplay/screen_arcane_drop.vpcf", PATTACH_EYES_FOLLOW, caster)
				Timers:CreateTimer(2, function() ParticleManager:DestroyParticle(particle, true) end)

				-- Play Sound
				PlayLifeUpSounds()

				-- Update Lives. Adjust HP per bars, 1 live = 1 bar.
				if currentLives < maxHP then
					caster:Heal(1, caster)
				else
					local item = CreateItem("item_apply_modifiers", caster, caster)
					item:ApplyDataDrivenModifier(caster, caster, "modifier_extra_hp", {})
					caster:Heal(1, caster)
					item:RemoveSelf()
				end
				PopupHealing(caster, 1)
				-- Fluffy Tail Touched

			elseif name == "golden_courier" then
				print("+ 1 multiplier")
				GameRules.multiplier = GameRules.multiplier + 1

				-- Play Particle
				local particle = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

				-- Play Sound
				PlayMultiplierGainSounds()

				-- Update Multiplier score
				FireGameEvent( 'update_multiplier', { player_ID = pID, multiplier = GameRules.multiplier } )

				PopupMultiplierGain(caster, GameRules.multiplier)

			else
				print("- 1 life")

				-- Play Damage Particles
				local particle = ParticleManager:CreateParticle("particles/generic_gameplay/screen_damage_indicator.vpcf", PATTACH_EYES_FOLLOW, caster)

				local blood = ParticleManager:CreateParticle("particles/custom/life_stealer_infest_emerge_bloody_low.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(blood, 0, caster:GetAbsOrigin())

				PlayExtraCourierDeathParticle(target)

				-- Update Lives
				local damage_table = {}
				damage_table.victim = caster
				damage_table.attacker = target					
				damage_table.damage_type = DAMAGE_TYPE_PURE
				damage_table.damage = 1

				ApplyDamage(damage_table)

				-- Extra Splat particle, don't show when dying
				if caster:GetHealth() >= 1 then
					local particle2 = ParticleManager:CreateParticle("particles/custom/splat_screen.vpcf", PATTACH_EYES_FOLLOW, caster)

					--Splat sound
					if name == "donkey" then
						PlayDonkeyDeathSounds()
					else
						PlayCourierDeathSounds()
					end
				else
					--Kill Sound
					PlayPlayerDeathSounds()
				end

				-- Remove from table
			end
			-- Short invulnerability after any collisions
			event.ability:ApplyDataDrivenModifier(caster, caster, "modifier_collision_invulnerability", {duration=0.03})

			-- Finally remove the unit
			target:RemoveSelf()
		end
	end
end

function Ultimate( event )
	local caster = event.caster
	local ability = event.ability
	local couriers = GameRules.couriers
	local donkeys = GameRules.donkeys

	-- Play Sound
	PlayUltimateSounds()

	-- Remove the glow particle and set it to re-create itself after 20 seconds
	caster:RemoveModifierByName("modifier_hammer_glow")
	Timers:CreateTimer(ability:GetCooldown(1), function()
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_hammer_glow", {})
		local randomSoundLevel = RandomInt(1, 12)
		local soundName = "omniknight_omni_level_0"..randomSoundLevel
		EmitSoundOn(soundName, caster)
	end)

	local couriers_killed = 0
	for _,target in pairs(couriers) do
		-- Kill and explosion particle
		if IsValidEntity(target) then
			if target:GetUnitName() == "fat_courier" then
				local particle = ParticleManager:CreateParticle("particles/custom/life_stealer_infest_emerge_bloody.vpcf", PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
			else
				local particle = ParticleManager:CreateParticle("particles/custom/life_stealer_infest_emerge_bloody_mid.vpcf", PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )
			end
			PlayExtraCourierDeathParticle(target)		

			-- Disabled this one because it lags too hard
			--local particle = ParticleManager:CreateParticle("particles/econ/items/brewmaster/brewmaster_offhand_elixir/brewmaster_thunder_clap_elixir.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

			target:RemoveSelf()
			couriers_killed = couriers_killed + 1

		end
	end

	for _,target in pairs(donkeys) do
		-- Kill and explosion particle
		if IsValidEntity(target) then
			local particle = ParticleManager:CreateParticle("particles/custom/life_stealer_infest_emerge_bloody.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin() )

			PlayExtraCourierDeathParticle(target)

			target:RemoveSelf()
			couriers_killed = couriers_killed + 1
		end
	end

	-- Give points and update scoreboard
	local bonus_points = couriers_killed * GameRules.multiplier
	print("KILLED "..couriers_killed.." with ultimate at multiplier level "..GameRules.multiplier)
	GameRules.score = GameRules.score + bonus_points
	print("SCORE: "..GameRules.score.."(+ "..bonus_points.." )")

	PopupMultiplier(caster, bonus_points)

	FireGameEvent( 'update_scoreboard', { player_ID = pID, score = GameRules.score } )

	-- WOW
	if GameRules.highscore > 0 and not GameRules.playedHighscorePredictionSound then
		if GameRules.score > GameRules.highscore then
			print("NEW HIGHSCORE REACHED, WOW")
			PlayNewHighscorePrediction()
		end
	end

	-- Reset multiplier and enemy tables
	GameRules.multiplier = 0
	GameRules.couriers = {}
	GameRules.donkeys = {}
	print("Multiplier Reset "..GameRules.multiplier)

	-- Update Multiplier score
	FireGameEvent( 'update_multiplier', { player_ID = pID, multiplier = GameRules.multiplier } )

	-- Slow the game down for 2 seconds
	SendToConsole("host_timescale 0.5")

	Timers:CreateTimer(1.0, function()
		SendToServerConsole("host_timescale 1")
	end)

end