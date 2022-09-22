local orb = module.internal("orb");
local menu = module.load("int", "Core/Veigar/menu")
local common = module.load("int", "Library/common")
local q = module.load("int", "Core/Veigar/spells/q")
local w = module.load("int", "Core/Veigar/spells/w")
local e = module.load("int", "Core/Veigar/spells/e")
local r = module.load("int", "Core/Veigar/spells/r")

local ts = module.internal('TS')
local pred = module.internal("pred")

local core = {
    on_end_func = nil,
    on_end_time = 0,
    f_spell_map = {},
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

core.on_recv_spell = function(spell)
    if core.f_spell_map[spell.name] then
        core.f_spell_map[spell.name](spell)
    end
end

core.on_end_q = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end
  
core.on_end_w = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end
  
core.on_end_e = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end
  
core.on_end_r = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end
  
core.on_cast_q = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_q
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end
  
core.on_cast_w = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_w
        core.on_end_time = os.clock() + spell.windUpTime
    end
end
  
core.on_cast_e = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_e
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end
  
core.on_cast_r = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_r
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end

core.get_action_veigar = function()
    if core.on_end_func and os.clock() + network.latency > core.on_end_time then
        core.on_end_func()
    end
    if (orb.menu.lane_clear:get() or orb.menu.last_hit:get()) then
        if (menu.lane.q:get() or menu.lane.last.w:get()) then 
            if q.is_ready() and common.GetPercentPar() >= menu.lane.Mana:get() then
                q.lane_clear()
                return
            end 
        end
    end
    if (orb.menu.lane_clear:get()) then 
        if (menu.lane.w:get()) then 
            if w.is_ready() and common.GetPercentPar() >= menu.lane.Mana:get() then
                w.lane_clear()
                return
            end 
        end
    end
    if (orb.combat.is_active()) then
        if menu.combo.e:get() then 
            if e.is_ready() then 
                e.invoke_action()
                return
            end
        end
        if menu.combo.w:get() then 
            local target = ts.get_result(function(res, obj, dist)
                if dist <= 900 and common.IsValidTarget(obj) then --add invulnverabilty check
                    res.obj = obj
                    return true
                end
            end).obj
            if target then 
                if menu.combo.modew:get() == 2 and (target.buff[5] or target.buff[8] or target.buff[11] or target.buff[18] or target.buff[21] or target.buff[29] or target.buff[30]) then
                    local seg = pred.circular.get_prediction(w.predinput, target)
                    if seg and seg.startPos:dist(seg.endPos) < w.range then
                        player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end 
            end
            if w.get_action_state() and menu.combo.modew:get() == 1 then 
                w.invoke_action()
                return
            end
        end 
        if menu.combo.q:get() then 
            if q.get_action_state() and not e.is_ready() then 
                q.invoke_action()
                return
            end
        end 
        if menu.combo.r:get() then 
            if r.get_action_state() then 
                r.invoke_action()
                return
            end
        end 
    end
    if menu.misc.kill:get() then 
        if r.get_action_state() then 
            r.invoke_action()
            return
        end
    end 
    if (orb.menu.hybrid:get()) and common.GetPercentPar() >= menu.harass.Mana:get() then 
        if menu.harass.e:get() then 
            if e.is_ready() then 
                e.invoke_action()
                return
            end
        end 
        if menu.harass.w:get() then 
            local target = ts.get_result(function(res, obj, dist)
                if dist <= 900 and common.IsValidTarget(obj) then --add invulnverabilty check
                    res.obj = obj
                    return true
                end
            end).obj
            if target then 
                if menu.harass.modew:get() == 2 and (target.buff[5] or target.buff[8] or target.buff[11] or target.buff[18] or target.buff[21] or target.buff[29] or target.buff[30]) then
                    local seg = pred.circular.get_prediction(w.predinput, target)
                    if seg and seg.startPos:dist(seg.endPos) < w.range then
                        player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end 
            end
            if w.get_action_state() and menu.harass.modew:get() == 1 then 
                w.invoke_action()
                return
            end
        end 
        if menu.harass.q:get() then 
            if q.get_action_state() then 
                q.invoke_action()
                return
            end
        end 
    end
    if menu.flee.fleeekey:get() then 
        e.Flee_E()
        return
    end
    if menu.misc.egab:get() then 
        e.Gapclose_dash()
        return 
    end
end

core.f_spell_map["VeigarBalefulStrike"] = core.on_cast_q
core.f_spell_map["VeigarDarkMatter"] = core.on_cast_w
core.f_spell_map["VeigarEventHorizon"] = core.on_cast_e
core.f_spell_map["VeigarR"] = core.on_cast_r

return core