local orb = module.internal("orb");
local ts = module.internal('TS')
local pred = module.internal("pred")
local menu = module.load("int", "Core/Veigar/menu")
local common = module.load("int", "Library/common")
local isFle = module.load("int", "Library/util")

local e = {
    slot = player:spellSlot(2),
    last = 0,
    range = 800,
  
    result = {
      seg = nil,
      obj = nil,
    },
  
    predinput = {
      range = 800,
      delay = 0.8,
      radius  = 300,
      speed = math.huge,
      boundingRadiusMod = 1,
    },
}

e.is_ready = function()
    return e.slot.state == 0
end  

e.CalculateEcastPoints = function(target1, target2)
    local CenterPoint = vec3((target1.x + target2.x)/2,0,(target1.z + target2.z)/2)
	local Perpendicular = vec3(target1.x - target2.x, 0, target1.z - target2.z):norm():perp()
	local D = common.GetDistance(target1, target2) / 2
	local A = math.sqrt(350 * 350 - D * D)
	local S1 = CenterPoint + A * Perpendicular
	local S2 = CenterPoint - A * Perpendicular
	return S1, S2
end

e.ProdictionECallback = function(unit, pos)
    if not e.is_ready() then return end
	local PredictedPosition = vec3(pos.x, pos.y, pos.z)
	local myPos = vec3(player.x, player.y, player.z)
	local Targets = {}
	--[[if menu.combo.e2:get() then 
		for i, enemy in ipairs(common.GetEnemyHeroes()) do
            if common.IsValidTarget(enemy) and (enemy.charName ~= unit.charName) then
                local Position = pred.circular.get_prediction(e.predinput, enemy)
				if Position and (common.GetDistance(Position.endPos) <= 650 + 350) then
					table.insert(Targets, Position)
				end
			end
		end
		
		At the moment only 2 targets supported
		while #Targets > 1 do
			table.remove(Targets, 1)
		end
		
		--[[The main target and another 1
		if #Targets == 1 then
			PredictedTargetPos = PredictedPosition -- for debugging
			SecondaryPos = vec3(Targets[1].x, Targets[1].y, Targets[1].z)
			if (common.GetDistance(PredictedPosition, SecondaryPos) <= 350 * 2) and (common.GetDistance(PredictedPosition, SecondaryPos) ~= 0) then
				--Get the point(s) to get the two targets 
				Solution1, Solution2 = e.CalculateEcastPoints(SecondaryPos, PredictedPosition)
				if common.GetDistance(Solution1) <= 600 then
					ECastPosition = Solution1
				elseif common.GetDistance(Solution2) <= 600 then
					ECastPosition = Solution2
				else--[[Solutions out of range, calculate the solution for the main target
					table.remove(Targets, 1)
				end
			else --Cant get the two targets, calculate the solution for the main target
				table.remove(Targets, 1)
			end
		end
	end]]
	
	--[[Only 1 target in range, cast E in our direction]]
	if #Targets == 0 then
		local DirectionVector = menu.combo.eradius:get() * (myPos - PredictedPosition):norm()
		ECastPosition = vec3(PredictedPosition.x + DirectionVector.x, 0, PredictedPosition.z + DirectionVector.z)
	end
	
	if ECastPosition and (common.GetDistance(ECastPosition) < 625) then
        player:castSpell("pos", 2, ECastPosition)
	end
end

e.invoke_action = function()
    e.result = ts.get_result(function(res, obj, dist)
        if dist > e.range then
            return
        end
        local Position = pred.circular.get_prediction(e.predinput, obj)
        local pred_pos = pred.core.lerp(obj.path, network.latency + 0.25, obj.moveSpeed)
        --pred.core.project(obj, obj.path, network.latency + 0.5, 2200, obj.moveSpeed) -- return vc2??
        --pred.core.project(target, target.path, 0.5, 1200, target.moveSpeed)
        if Position  then
            local unitPos = vec3(Position.endPos.x, obj.y, Position.endPos.y);
            if unitPos and not isFle.isFleeingFromMe(obj) then
                e.ProdictionECallback(obj, unitPos)
                res.obj = obj
                return true
            end
        end
    end)
end

e.get_action_state = function()
    if e.is_ready() then 
        return e.get_prediction()
    end
end

e.trace_filter = function()
    if e.result.seg.startPos:dist(e.result.obj.path.serverPos2D) > 950 then
		return false
	end
    if pred.trace.circular.hardlock(e.predinput, e.result.seg, e.result.obj) then
	    return true
	end
	if pred.trace.circular.hardlockmove(e.predinput, e.result.seg, e.result.obj) then
	    return true
	end
	if pred.trace.newpath(e.result.obj, 0.033, 0.500) then
	    return true
	end
end


e.Flee_E = function()
    player:move(mousePos)
    if menu.flee.e:get() and e.is_ready() then
        player:castSpell("pos", 2, player.pos)
    end
end

e.Gapclose_dash = function()
    for i = 0, objManager.enemies_n - 1 do
        local dasher = objManager.enemies[i]
        if dasher.type == TYPE_HERO and dasher.team == TEAM_ENEMY then
            if dasher and common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and player.pos:dist(dasher.path.point[1]) < e.range then
                if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[0]) then
                    player:castSpell("pos", 2, dasher.path.point2D[1])
                end
            end 
        end 
    end
end

e.on_draw = function()
    if menu.ddd.ed:get() and e.slot.level > 0 and e.is_ready() then
        graphics.draw_circle(player.pos, e.range, 1, graphics.argb(255, 255, 255, 200), 40)
    end
end

return e 