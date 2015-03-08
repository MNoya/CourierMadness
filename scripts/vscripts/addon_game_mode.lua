-- Required files to be visible from anywhere
require( 'couriermadness' )
require( 'timers' )
require( 'spawn' )
require( 'abilities' )
require( 'camera' )
require( 'popups' )
require( 'sounds' )
require( 'FlashUtil' )
require( 'lib.statcollection' )

statcollection.addStats({
	modID = '70a0be5310f54fa1811657f5d5a0f884'
})

function Precache( context )

	print("[BAREBONES] Performing pre-load precache")

	-- Particles can be precached individually or by folder
	-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
	PrecacheResource("particle", "particles/econ/items/legion/legion_weapon_voth_domosh/legion_duel_start_text_arcana_fire.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/brewmaster/brewmaster_offhand_elixir/brewmaster_thunder_clap_elixir.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_death_explosion.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/techies/techies_arcana/techies_taunt.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/doom/doom_f2p_death_effect/doom_bringer_f2p_death.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_taunt_compendium.vpcf", context)
	PrecacheResource("particle_folder", "particles/econ/events/killbanners", context)
	PrecacheResource("particle_folder", "particles/econ/courier", context)
	PrecacheResource("particle_folder", "particles/custom", context)

	-- Models can also be precached by folder or individually
	-- PrecacheModel should generally used over PrecacheResource for individual models
	PrecacheResource("model_folder", "models/courier", context)
	PrecacheResource("model_folder", "models/items/courier", context)

	-- Sounds can precached here like anything else
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_enchantress.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_enchantress.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_shadowshaman.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_undying.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/custom_sounds.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/music/valve_dota_001/game_sounds_stingers.vsndevts", context)
	--PrecacheResource("soundfile", "soundevents/music/valve_dota_001/stingers/game_sounds_stingers.vsndevts", context)

	-- Entire items can be precached by name
	-- Abilities can also be precached in this way despite the name
	PrecacheItemByNameSync("example_ability", context)
	PrecacheItemByNameSync("item_example_item", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
	PrecacheUnitByNameSync("courier", context)	
	PrecacheUnitByNameSync("fat_courier", context)	
	PrecacheUnitByNameSync("donkey", context)	
	PrecacheUnitByNameSync("golden_courier", context)
	PrecacheUnitByNameSync("fluffy_tail", context)
	PrecacheUnitByNameSync("dummy_bloody_unit", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end
