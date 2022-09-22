local common = module.load(header.id, "Library/common");
local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Core/Lissandra/menu")

--[[
    Spell name: LissandraE
    Speed:850
    Width: 110
    Time:0.25
    Animation: 1
    false
    CastFrame: 0.27481988072395
]]
local e = {
    Missile = { };
    slot = player:spellSlot(2);
    
    range = 1045; 
    jump = false;
    missilepos = vec2(0,0);

    result = {
        seg = nil, 
        obj = nil
    };
    pred_input = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        range = 1045,
        delay = 0.25,
        width = 110,
        speed = 850,
        collision = {
            hero = false,
            minion = false,
            wall = false,
        }
    };
}

e.is_ready = function()
    return e.slot.state == 0 
end 


-- ts.get_result(e.get_target_result)
e.invoke_action = function()
    if e.is_ready() then
        local result = ts.get_result(e.get_target_result)

        if not player.buff['lissandrae'] then 

            if not result or not result.castPosition then 
                return 
            end 

            if common.GetPercentMana() > menu.combo.e.mana_mngr:get() then 
                player:castSpell("pos", 2, result.castPosition)
                e.jump = true
            end 
        else 
            if result.obj then 
                for i, object in pairs(e.Missile) do 
                    if object and (object.pos:dist(e.missilepos)) <= 100 and player.buff['lissandrae'] and result.obj.pos:dist(player) > result.obj.pos:dist(e.missilepos) and e.jump then
                    
                        if common.IsUnderDangerousTower(object.pos) then 
                            return 
                        end 
                        player:castSpell("self", 2)
                        e.jump = false
                    end 
                end 
            end
        end     
    end 
end 

--[[e.get_result_send_target = function()
    if e.last == game.time then
        return e.result.castPosition
    end
    e.last = game.time
    e.result.obj = nil
    e.result.castPosition = nil

    e.result = ts.get_result(e.get_target_result)
end]]

e.spell_end = function(spell)
    if spell.name == "LissandraE" then 
        e.missilepos = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)
    end 
end

e.get_target_result = function(res, obj, dist)
    if not obj then 
        return  
    end 

    if not player.buff['lissandrae'] and e.slot.state == 0 then 
        if dist > e.range then 
            return 
        end 

        local seg, spellPred, predTrace

        spellPred = gpred.linear
        predTrace = gpred.trace.linear

        seg = spellPred.get_prediction(e.pred_input, obj)

        if not seg then
            return
        end

        
        local hitTime = seg.startPos:dist(seg.endPos) / e.pred_input.speed
        local maxHitTime = e.pred_input.range / e.pred_input.speed
        local hitTimeRatio = hitTime / maxHitTime

        local startedTime = obj.path.point[0]:dist(obj.pos) / obj.moveSpeed
        local arrivalTime = obj.pos:dist(obj.path.point[obj.path.index]) / obj.moveSpeed
        local pathTimeRatio = startedTime / arrivalTime

        e.pred_input.boundingRadiusMod = 1 - (hitTimeRatio * pathTimeRatio)

        if e.pred_input.boundingRadiusMod <= 0 or e.pred_input.boundingRadiusMod >= 1 then
            e.pred_input.boundingRadiusMod = 0
        end

        seg = spellPred.get_prediction(e.pred_input, obj)

        if seg.startPos:dist(seg.endPos) < e.pred_input.range then
            if seg.startPos:dist(seg.endPos) < e.pred_input.range - (obj.moveSpeed * e.pred_input.delay) and seg.startPos:dist(obj.pos2D) < e.pred_input.range - (obj.moveSpeed * e.pred_input.delay) then
                res.castPosition = vec3(seg.endPos.x, obj.y, seg.endPos.y)
                return true
            end 
        end 
    end 

    if not player.buff['lissandrae'] then 
        return 
    end 

    if dist > 4000 then 
        return 
    end 

    if common.IsUnderDangerousTower(obj.pos) then 
        return 
    end

    res.obj = obj 
    return true
end 

e.invoke__lane_clear = function()
    if menu.clear.e.e:get() == 3 then 
        return 
    end 

    local valid = {}
    local minions = objManager.minions
    for i = 0, minions.size[TEAM_ENEMY] - 1 do
        local minion = minions[TEAM_ENEMY][i]
        if minion and not minion.isDead and minion.isVisible then
            local dist = player.path.serverPos:distSqr(minion.path.serverPos)
            if dist <= 1300 * 1300 then
                valid[#valid + 1] = minion
            end
        end
    end
    local max_count, cast_pos = 0, nil
    for i = 1, #valid do
        local minion_a = valid[i]
        local current_pos = player.path.serverPos + ((minion_a.path.serverPos - player.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos) + 1300))
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
        if cast_pos and max_count > 4 and not player.buff['lissandrae'] then 
            player:castSpell("pos", 2, cast_pos)
            orb.core.set_server_pause()
            break
        end
    end
end  


e.create_missile = function(obj)
    if obj then
        if obj.name == "LissandraEMissile" then 
            e.Missile[obj.ptr] = obj
        end 
        --print(obj.name)
        --common.log_file(obj.name)
    end
end

e.delete_missile = function(obj)
    if obj then
        e.Missile[obj.ptr] = nil
    end 
end 

e.on_draw = function()
    if menu.draws.e_range:get() and e.slot.level > 0 and e.slot.state == 0 then
        graphics.draw_circle(player.pos, e.range, menu.draws.width:get(), menu.draws.e:get(), menu.draws.numpoints:get())
    end
    for i, object in pairs(e.Missile) do 
        if object then 
            graphics.draw_circle(object.pos, 150, menu.draws.width:get(), menu.draws.e:get(), menu.draws.numpoints:get())
        end 
    end 
end 

return e