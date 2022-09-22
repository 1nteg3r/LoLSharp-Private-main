local common = module.load(header.id, "Library/common");
local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Core/Lissandra/menu")

local q = {
    slot = player:spellSlot(0);
    
    range = 725; 

    result = {
        seg = nil, 
        obj = nil
    };
    pred_input = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        range = 750,
        delay = 0.25,
        width = 75,
        speed = 1200,
        collision = {
            hero = true,
            minion = true,
            wall = true,
        }
    };
}

q.pointOnLine = function(eEnd, eStart, unit, extra)
    local toUnit = {x = unit.x - eStart.x, z = unit.z - eStart.z}
    local toEnd = {x = eEnd.x - eStart.x, z = eEnd.z - eStart.z}

    local magitudeToEnd = toEnd.x ^ 2 + toEnd.z ^ 2
    local dotP = toUnit.x * toEnd.x + toUnit.z * toEnd.z

    local distance = dotP / magitudeToEnd

    return eStart.x + toEnd.x * (distance + extra), eStart.z + toEnd.z * (distance + extra)
end

q.is_ready = function()
    return q.slot.state == 0
end

q.get_action_state = function()
    if q.is_ready() and common.GetPercentPar() > menu.combo.q.mana_mngr:get() then
        return q.get_prediction()
    end
end
  
q.invoke_action = function()
    player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, q.result.obj.y, q.result.seg.endPos.y))
end

q.cast_collision_minion = function()
    local target = ts.get_result(function(res, obj, dist)
        if dist <= 926 then 
            res.obj = obj
        end
    end).obj

    if target and common.IsValidTarget(target) then 
        local collision_minion = false
        local x, z = 0, 0
        local MinionsQ = common.GetMinionsInRange(895, TEAM_ENEMY)
        for i, minion in pairs(MinionsQ) do
            if minion ~= nil and not minion.isDead and common.GetDistance(minion) <= 700 then
                x, z = q.pointOnLine(player, target, minion, 0)
                
                if math.sqrt((minion.x - x) ^ 2 + (minion.z - z) ^ 2) < 75 / 2 then
                    collision_minion = true
                end
            end
        end
        
        if collision_minion == true and common.GetDistance(target) < 825 then
            local pred_pos = gpred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)

            if not pred_pos then 
                return 
            end 
    
            local Position = vec3(pred_pos.x, target.y, pred_pos.y)
        
            local castX = player.x + 725 * ((Position.x - player.x) / common.GetDistance(Position))
            local castZ = player.z + 725 * ((Position.z - player.z) / common.GetDistance(Position))
            
            player:castSpell('pos', 0, vec3(castX, 0, castZ))
        end
    end
end 

q.get_prediction = function()
    if q.last == game.time then
      return q.result.seg
    end
    q.last = game.time
    q.result.obj = nil
    q.result.seg = nil
    
    q.result = ts.get_result(function(res, obj, dist)
        if dist > 600 then
            return
        end
        if dist <= common.GetAARange(obj) then
            local aa_damage = common.CalculateAADamage(obj)
            if (aa_damage * 2) >= common.GetShieldedHealth("AD", obj) then
                return
            end
        end
        local seg, spellPred, predTrace

        spellPred = gpred.linear
        predTrace = gpred.trace.linear

        seg = spellPred.get_prediction(q.pred_input, obj)

        if not seg then
            return
        end

        local hitTime = seg.startPos:dist(seg.endPos) / q.pred_input.speed
        local maxHitTime = q.pred_input.range / q.pred_input.speed
        local hitTimeRatio = hitTime / maxHitTime

        local startedTime = obj.path.point[0]:dist(obj.pos) / obj.moveSpeed
        local arrivalTime = obj.pos:dist(obj.path.point[obj.path.index]) / obj.moveSpeed
        local pathTimeRatio = startedTime / arrivalTime

        q.pred_input.boundingRadiusMod = 1 - (hitTimeRatio * pathTimeRatio)

        if q.pred_input.boundingRadiusMod <= 0 or q.pred_input.boundingRadiusMod >= 1 then
            q.pred_input.boundingRadiusMod = 0
        end

        seg = spellPred.get_prediction(q.pred_input, obj)

        local collision = nil

        if q.pred_input.collision then
            collision = gpred.collision.get_prediction(q.pred_input, seg, obj)
        end

        if collision then
            if seg.startPos:dist(seg.endPos) < q.pred_input.range then
                return true
            end
    
            if seg.startPos:dist(seg.endPos) < q.pred_input.range - (obj.moveSpeed * q.pred_input.delay) and seg.startPos:dist(obj.pos2D) < q.pred_input.range - (obj.moveSpeed * q.pred_input.delay) then
                return true
            end
    
            if gpred.trace.newpath(obj, pathTimeRatio, hitTimeRatio) then
                return true
            end
    
            if predTrace.hardlock(q.pred_input, seg, obj) or predTrace.hardlockmove(q.pred_input, seg, obj) then
                return true
            end

            --[[if dist <= 926 then 
                local collision_minion = false
                local x, z = 0, 0
                local MinionsQ = common.GetMinionsInRange(895, TEAM_ENEMY)
                for i, minion in pairs(MinionsQ) do
                    if minion ~= nil and not minion.isDead and common.GetDistance(minion) <= 700 then
                        x, z = q.pointOnLine(player, obj, minion, 0)
                        
                        if math.sqrt((minion.x - x) ^ 2 + (minion.z - z) ^ 2) < 75 / 2 then
                            collision_minion = true
                        end
                    end
                end
                
                if collision_minion == true and common.GetDistance(obj) < 825 then
                    local pred_pos = gpred.core.lerp(obj.path, network.latency + 0.25, obj.moveSpeed)

                    if not pred_pos then 
                        return 
                    end 
            
                    local Position = vec3(pred_pos.x, obj.y, pred_pos.y)
                
                    local castX = player.x + 725 * ((Position.x - player.x) / common.GetDistance(Position))
                    local castZ = player.z + 725 * ((Position.z - player.z) / common.GetDistance(Position))
                    
                    --player:castSpell('line', 0, castX, castZ)

                    return true
                end
            end]] 
        end


        res.obj = obj
        res.seg = seg
        return true
    end)
    if q.result.seg then
        return q.result
    end
end

q.invoke__lane_clear = function()
    local valid = {}
    local minions = objManager.minions
    for i = 0, minions.size[TEAM_ENEMY] - 1 do
        local minion = minions[TEAM_ENEMY][i]
        if minion and not minion.isDead and minion.isVisible then
            local dist = player.path.serverPos:distSqr(minion.path.serverPos)
            if dist <= 700 * 700 then
                valid[#valid + 1] = minion
            end
        end
    end
    local max_count, cast_pos = 0, nil
    for i = 1, #valid do
        local minion_a = valid[i]
        local current_pos = player.path.serverPos + ((minion_a.path.serverPos - player.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos)))
        local hit_count = 1
        for j = 1, #valid do
            if j ~= i then
                local minion_b = valid[j]
                local point = mathf.closest_vec_line(minion_b.path.serverPos, player.path.serverPos, current_pos)
                if point and point:dist(minion_b.path.serverPos) < (89 + minion_b.boundingRadius) then
                    hit_count = hit_count + 1
                end
            end
        end
        if not cast_pos or hit_count > max_count then
            cast_pos, max_count = current_pos, hit_count
        end
        if cast_pos and max_count > 3 then 
            player:castSpell("pos", 0, cast_pos)
            orb.core.set_server_pause()
            break
        end
    end
end  
--[[
    Spell name: LissandraQ
    Speed:1200
    Width: 75
    Time:0.25
    Animation: 1
    false
    CastFrame: 0.27481988072395
]]

q.on_draw = function()
    if menu.draws.q_range:get() and q.slot.level > 0 and q.slot.state == 0 then
        graphics.draw_circle(player.pos, q.range, menu.draws.width:get(), menu.draws.q:get(), menu.draws.numpoints:get())
    end
end 

return q