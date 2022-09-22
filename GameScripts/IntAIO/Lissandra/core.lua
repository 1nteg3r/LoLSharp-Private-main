local orb = module.internal("orb")
local ts = module.internal('TS')
local menu = module.load("int", "Core/Lissandra/menu")
local common = module.load("int", "Library/common")
local q = module.load("int", "Core/Lissandra/spells/q")
local w = module.load("int", "Core/Lissandra/spells/w")
local e = module.load("int", "Core/Lissandra/spells/e")
local r = module.load("int", "Core/Lissandra/spells/r")
local ks = module.load("int", "Core/Lissandra/killsteal")

local core = {
    on_end_func = nil,
    on_end_time = 0,
    f_spell_map = {},
}

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
        orb.core.set_pause(math.huge)
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
  

core.get_action_core = function()
    if core.on_end_func and os.clock() + network.latency > core.on_end_time then
        core.on_end_func()
    end

    ks.KillSteal(); 

    if menu.auto_w:get() and w.is_ready() then
        w.invoke__anti_gapcloser()
    end

    if orb.combat.is_active() then
        if menu.combo.items.hourglass:get() and common.GetPercentHealth() <= menu.combo.items.glass_hp:get() then
            for i = 6, 11 do
                local slot = player:spellSlot(i)
                if slot.isNotEmpty and slot.name == 'ZhonyasHourglass' and slot.state == 0 then
                    player:castSpell("self", i)
                    orb.core.set_server_pause()
                    break
                end
            end
        end
        if menu.combo.items.seraph:get() and common.GetPercentHealth() <= menu.combo.items.seraph_hp:get() then
            for i = 6, 11 do
                local slot = player:spellSlot(i)
                if slot.isNotEmpty and slot.name == 'ItemSeraphsEmbrace' and slot.state == 0 then
                    player:castSpell("self", i)
                    orb.core.set_server_pause()
                    break
                end
            end
        end

        if menu.combo.r.r:get() and common.GetPercentMana() >= menu.combo.r.mana_mngr:get() and r.get_action_state() then
            r.invoke_action()
            return
        end

        if menu.combo.path:get() == 1 then --Q
            if menu.combo.q.q:get() and common.GetPercentMana() >= menu.combo.q.mana_mngr:get() and q.get_action_state() then
                q.invoke_action()
                q.cast_collision_minion()
                return
            end

            if menu.combo.w.w:get() and common.GetPercentMana() >= menu.combo.w.mana_mngr:get() and w.get_action_state() then
                w.invoke_action()
                return
            end

            if menu.combo.e.e:get() and e.is_ready() then 
                e.invoke_action()
                return
            end
        elseif menu.combo.path:get() == 2 then --E 

            if menu.combo.e.e:get() and e.is_ready() then 
                e.invoke_action()
                return
            end
            
            if menu.combo.w.w:get() and common.GetPercentMana() >= menu.combo.w.mana_mngr:get() and w.get_action_state() then
                w.invoke_action()
                return
            end

            if menu.combo.q.q:get() and common.GetPercentMana() >= menu.combo.q.mana_mngr:get() and q.get_action_state() then
                q.invoke_action()
                q.cast_collision_minion()
                return
            end

        end
    elseif orb.menu.hybrid.key:get() then 
        if menu.harass.q.q:get() and common.GetPercentMana() >= menu.harass.q.mana_mngr:get() and q.get_action_state() then
            q.invoke_action()
            q.cast_collision_minion()
            return
        end
    elseif orb.menu.lane_clear.key:get() then 
        if e.is_ready() and menu.clear.e.e:get() and common.GetPercentMana() >= menu.clear.e.mana_mngr:get() then 
            e.invoke__lane_clear()
            return
        end 

        if q.is_ready() and menu.clear.q.q:get() and common.GetPercentMana() >= menu.clear.q.mana_mngr:get() then 
            q.invoke__lane_clear()
            return
        end 
    end
end

core.on_recv_spell = function(spell)
    if core.f_spell_map[spell.name] then
        core.f_spell_map[spell.name](spell)
    end
end
  
core.f_spell_map["LissandraQ"] = core.on_cast_Q
core.f_spell_map["LissandraW"] = core.on_cast_w
core.f_spell_map["LissandraE"] = core.on_cast_e
core.f_spell_map["LissandraR"] = core.on_cast_r

return core 