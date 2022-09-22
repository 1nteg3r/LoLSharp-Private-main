local orb = module.internal("orb");
local ts = module.internal('TS')
local pred = module.internal("pred")
local menu = module.load("int", "Core/Veigar/menu")
local common = module.load("int", "Library/common")
local damageLib = module.load('int', 'Library/damageLib');

local q = {
    slot = player:spellSlot(0),
    last = 0,
    range = 850,
  
    result = {
      seg = nil,
      obj = nil,
    },
  
    predinput = {
      range = 850,
      delay = 0.25,
      width  = 70,
      speed = 1700,
      boundingRadiusMod = 1,
        collision = {
            hero = false,
            minion = true
        }
    },
    predinput_lane = {
        range = 850,
        delay = 0.25,
        radius  = 70,
        speed = 1700,
        boundingRadiusMod = 1,
          collision = {
              hero = false,
              minion = true
          }
      },
}

q.is_ready = function()
    return q.slot.state == 0
end  

q.invoke_action = function()
    player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, q.result.obj.y, q.result.seg.endPos.y))
    orb.core.set_server_pause()
end

q.get_action_state = function()
    if q.is_ready() then 
        return q.get_prediction()
    end
end

q.trace_filter = function()
    if q.result.seg.startPos:dist(q.result.obj.path.serverPos2D) > 950 then
		return false
	end
    if pred.trace.linear.hardlock(q.predinput, q.result.seg, q.result.obj) then
	    return true
	end
	if pred.trace.linear.hardlockmove(q.predinput, q.result.seg, q.result.obj) then
	    return true
	end
	if pred.trace.newpath(q.result.obj, 0.033, 0.500) then
	    return true
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
        if dist > 2000 then
            return
        end
        local seg = pred.linear.get_prediction(q.predinput, obj)
        if seg and seg.startPos:dist(seg.endPos) < q.range then
            local col = pred.collision.get_prediction(q.predinput, seg, obj)
            if not col then
                res.obj = obj
                res.seg = seg
                return true
            end
        end
    end)
    if q.result.seg and q.trace_filter() then
        return q.result
    end
end 

q.check_cout_colision = function(obj)
    local check = { }
    local seg = pred.linear.get_prediction(q.predinput, obj)
    if seg then 
        local Col = pred.collision.get_prediction(q.predinput, seg, obj)
        if not Col then 
            check[#check] = obj
        end 
    end
    return check
end 

q.lane_clear = function()
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
            if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and common.IsValidTarget(minion) then
            local minionPos = vec3(minion.x, minion.y, minion.z)
            local delay = 0.25 + player.pos:dist(minion.pos) / 3000
            if minionPos and not common.IsUnderAllyTurret(minionPos) then 
                local seg = pred.linear.get_prediction(q.predinput, minion)
                if seg and seg.startPos:dist(seg.endPos) < q.range and not (#q.check_cout_colision(minion) >= 1) then 
                    if (damageLib.GetSpellDamage(0, minion)  >= orb.farm.predict_hp(minion, delay / 2, true)) then
                        player:castSpell("pos", 0, vec3(seg.endPos.x, minionPos.y, seg.endPos.y))
                    end   
                end
            end
            if common.IsUnderAllyTurret(minionPos) then 
                local seg = pred.linear.get_prediction(q.predinput, minion)
                if seg and seg.startPos:dist(seg.endPos) < q.range and not (#q.check_cout_colision(minion) >= 1) then
                    if (damageLib.GetSpellDamage(0, minion)  >= minion.health) then
                        player:castSpell("pos", 0, vec3(seg.endPos.x, minionPos.y, seg.endPos.y))
                    end   
                end
            end
        end
    end
    if menu.lane.jug.q:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
            then
                if minion.pos:dist(player.pos) <= q.range then
                    player:castSpell("pos", 0, minion.pos)
                end
            end
        end
    end
end

q.on_draw = function()
    if menu.ddd.qd:get() and q.slot.level > 0 and q.is_ready() then
        graphics.draw_circle(player.pos, q.range, 1, graphics.argb(255, 255, 255, 200), 40)
    end
end

return q 