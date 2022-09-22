local common = module.load(header.id, "Library/common");
local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Core/Lissandra/menu")

local w = {
    slot = player:spellSlot(1), 
    last = 0,
    
    range = 450, 
    result = {
        obj = nil;
    }; 

    predinput = {
        delay = 0.5,
        radius = 300,
        dashRadius = 0,
        boundingRadiusModSource = 0,
        boundingRadiusModTarget = 0,
    }
}

w.is_ready = function()
    return w.slot.state == 0
end 

w.get_action_state = function()
    if w.is_ready() and common.GetPercentPar() > menu.combo.w.mana_mngr:get() then
        return w.get_prediction()
    end
end
  
w.invoke_action = function()
    player:castSpell("obj", 1, w.result.obj)
end

w.invoke__anti_gapcloser = function()
    local target = ts.get_result(function(res, obj, dist)
        if dist <= 450 and obj.path.isActive and obj.path.isDashing then
            res.obj = obj
            return true
        end
    end).obj

    if target then
        local pred_pos = gpred.core.lerp(target.path, network.latency + w.predinput.delay, target.path.dashSpeed)
        if pred_pos and pred_pos:dist(player.path.serverPos2D) < 300 then
            player:castSpell("pos", 1, vec3(pred_pos.x, target.y, pred_pos.y))
        end
    end
end

w.get_prediction = function()
    if w.last == game.time then
        return w.result.obj
    end
    w.last = game.time
    w.result.obj = nil

    w.result = ts.get_result(function(res, obj, dist) 
        if dist > 500 or obj.buff[17] then
            return
        end
        if gpred.present.get_prediction(w.predinput, obj) then
            res.obj = obj
            return true
        end
    end)
    if w.result.obj then 
        return w.result 
    end
end

w.on_draw = function()
    if menu.draws.r_range:get() and w.slot.level > 0 and w.slot.state == 0 then
        graphics.draw_circle(player.pos, w.range, menu.draws.width:get(), menu.draws.r:get(), menu.draws.numpoints:get())
    end
end 

return w