local orb = module.internal("orb");
local ts = module.internal('TS')
local pred = module.internal("pred")
local menu = module.load("int", "Core/Veigar/menu")
local common = module.load("int", "Library/common")
local damageLib = module.load('int', 'Library/damageLib');

local r = {
    slot = player:spellSlot(3),
    last = 0,
    range = 650,
  
    result = {
      seg = nil,
      obj = nil,
    },
}

r.validult = function(unit)
	if (unit.buff[16] or unit.buff[15] or unit.buff[17] or unit.buff['kindredrnodeathbuff'] or unit.buff["sionpassivezombie"] or unit.buff[4]) then
		return false
	end
	return true
end

r.is_ready = function()
    return r.slot.state == 0
end  

r.invoke_action = function()
    player:castSpell("obj", 3, r.result.obj)
    orb.core.set_server_pause()
end

r.get_action_state = function()
    if r.is_ready() then 
        return r.get_prediction()
    end
end

r.get_prediction = function()
    if r.last == game.time then
        return r.result.seg
    end
    r.last = game.time
    r.result.obj = nil
    --r.result.seg = nil
      
    r.result = ts.get_result(function(res, obj, dist)
        if dist > 2000 then
            return
        end
        if obj and obj.path.serverPos2D:dist(player.path.serverPos2D) <= r.range then 
            if (damageLib.GetSpellDamage(3, obj)) > common.GetShieldedHealth("AP", obj) and r.validult(obj) then
                res.obj = obj
                return true
            end
        end 
    end)
    if r.result.obj then
        return r.result
    end
end 

r.on_draw = function()
    if menu.ddd.rd:get() and r.slot.level > 0 and r.is_ready() then
        graphics.draw_circle(player.pos, r.range, 1, graphics.argb(255, 255, 255, 200), 40)
    end
end


return r
