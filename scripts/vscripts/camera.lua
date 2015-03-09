-- Because of how SetCameraTarget works, we have to constantly update the camera to snap it on a unit, by removing and recreating it
-- While SetCameraTarget is doing its 1~2 second repositioning, it's not possible to move with edge panning
-- All units will be unselectable so its not possible to lose selection of the hero
function CameraFollow( event )
	local initial_pos = Vector(120,-1180,128)
	local hero = event.caster
	hero.camera = Entities:FindByName(nil, "camera_guy") -- Initial camera unit on the map, has the initial Y and Z which should never change

	if hero.camera == nil then
		hero.camera = CreateUnitByName("camera_guy", initial_pos, false, nil, nil, hero:GetTeamNumber())
	end

	PlayerResource:SetCameraTarget(0, hero.camera)
	--DebugDrawCircle(hero.camera:GetAbsOrigin(), Vector(255,0,0), 255, 10, true, 2)


	-- Camera Updater
	-- Every second the camera is put in front of the hero pos
	-- This might interact wrongly with some Move Left/Right combination,
	-- Needs testing to find the best time interval 
	Timers:CreateTimer(2.0, function()
		local newX = hero:GetAbsOrigin().x
		--print("Updating camera to "..newX)
		UpdateCamera(hero, newX)
		return 2.0	
	end)
end

-- When a MoveLeft/MoveRight order is executed, the hero.camera will be set to spawn +/-200 X away from the hero's original position
-- This does't take care of the player using Stop/Hold or change the movement direction, but should help in making it less choppy
function UpdateCamera( hero, newX )

	-- make this function be called a max of once per 2 secs for each player.
	if GameRules:GetGameTime()-hero.lastCameraUpdateTime < 2 then
		return
	end

	local old_camera = hero.camera:GetAbsOrigin()

	local heroPos = hero:GetAbsOrigin()
	local offset = math.abs(heroPos.x-newX)+200
	-- invert the x if the hero is at an edge.
	local re = GameMode.rightEdge:GetAbsOrigin()
	local le = GameMode.leftEdge:GetAbsOrigin()

	if re.x-heroPos.x < offset then
		newX = heroPos.x-offset
	elseif math.abs(le.x)-math.abs(heroPos.x) < offset then
		newX = heroPos.x+offset
	end

	local pos_camera = Vector(newX , old_camera.y, old_camera.z)

	local new_camera = CreateUnitByName(hero.camera:GetUnitName(), pos_camera, false, nil, nil, hero.camera:GetTeamNumber())
	hero.camera:RemoveSelf()
	hero.camera = new_camera

	if hero:IsAlive() then
		PlayerResource:SetCameraTarget(0, hero.camera)
		--DebugDrawCircle(hero.camera:GetAbsOrigin(), Vector(255,0,0), 255, 10, true, 1)
	else
		PlayerResource:SetCameraTarget(0, hero)
	end
	hero.lastCameraUpdateTime = GameRules:GetGameTime()
end

	