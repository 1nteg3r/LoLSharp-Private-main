local orb = module.internal("orb");
local ts = module.internal('TS')
local pred = module.internal("pred")
local menu = module.load("int", "Core/Veigar/menu")

local w = {
    slot = player:spellSlot(1),
    last = 0,
    range = 900,
  
    result = {
      seg = nil,
      obj = nil,
    },
  
    predinput = {
      range = 900,
      delay = 1.35,
      radius  = 225,
      speed = math.huge,
      boundingRadiusMod = 1,
    },
}

local hard_cc = {
    [5] = true, -- stun
    [8] = true, -- taunt
    [11] = true, -- snare
    [18] = true, -- sleep
    [21] = true, -- fear
    [22] = true, -- charm
    [24] = true, -- suppression
    [28] = true, -- flee
    [29] = true, -- knockup
    [30] = true -- knockback
}

w.is_ready = function()
    return w.slot.state == 0
end  

w.invoke_action = function()
    player:castSpell("pos", 1, vec3(w.result.seg.endPos.x, w.result.obj.y, w.result.seg.endPos.y))
    orb.core.set_server_pause()
end

w.get_action_state = function()
    if w.is_ready() then 
        return w.get_prediction()
    end
end

w.trace_filter = function()
    if w.result.seg.startPos:dist(w.result.obj.path.serverPos2D) > 950 then
		return false
	end
    if pred.trace.circular.hardlock(w.predinput, w.result.seg, w.result.obj) then
	    return true
	end
	if pred.trace.circular.hardlockmove(w.predinput, w.result.seg, w.result.obj) then
	    return true
	end
	if pred.trace.newpath(w.result.obj, 0.033, 0.500) then
	    return true
	end
end

w.get_prediction = function()
    if not menu.combo.modew:get() == 1 then return end
    if w.last == game.time then
        return w.result.seg
    end
    w.last = game.time
    w.result.obj = nil
    w.result.seg = nil
      
    w.result = ts.get_result(function(res, obj, dist)
        if dist > 2000 then
            return
        end
        local seg = pred.circular.get_prediction(w.predinput, obj)
        if seg and seg.startPos:dist(seg.endPos) < w.range then
            res.obj = obj
            res.seg = seg
            return true
        end
    end)
    if w.result.seg and w.trace_filter() then
        return w.result
    end
end 

w.lane_clear = function()
    local minions = objManager.minions
    for a = 0, minions.size[TEAM_ENEMY] - 1 do
        local minion1 = minions[TEAM_ENEMY][a]
        if
            minion1 and minion1.moveSpeed > 0 and minion1.isTargetable and not minion1.isDead and minion1.isVisible and
                player.path.serverPos:distSqr(minion1.path.serverPos) <= (w.range * w.range)
         then
            local count = 0
            for b = 0, minions.size[TEAM_ENEMY] - 1 do
                local minion2 = minions[TEAM_ENEMY][b]
                if
                    minion2 and minion2.moveSpeed > 0 and minion2.isTargetable and minion2 ~= minion1 and not minion2.isDead and
                        minion2.isVisible and
                        minion2.path.serverPos:distSqr(minion1.path.serverPos) <= (w.predinput.radius*w.predinput.radius)
                 then
                    count = count + 1
                end
                if count >= menu.lane.minion:get() then
                    local seg = pred.circular.get_prediction(w.predinput, minion1)
                    if seg and seg.startPos:dist(seg.endPos) < w.range then
                        player:castSpell("pos", 1, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
                        break
                    end
                end
            end
        end
    end
    if menu.lane.jug.w:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
            then
                if minion.pos:dist(player.pos) <= w.range then
                    player:castSpell("pos", 1, minion.pos)
                end
            end
        end
    end
end

w.on_draw = function()
    if menu.ddd.wd:get() and w.slot.level > 0 and w.is_ready() then
        graphics.draw_circle(player.pos, w.range, 1, graphics.argb(255, 255, 255, 200), 40)
    end
end

return w