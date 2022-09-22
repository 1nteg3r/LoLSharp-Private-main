local orb = module.internal("orb");
local menu = module.load("int", "Core/Ryze/menu")
local common = module.load("int", "Library/common")
local q = module.load("int", "Core/Ryze/spells/q")
local w = module.load("int", "Core/Ryze/spells/w")
local e = module.load("int", "Core/Ryze/spells/e")
local r = module.load("int", "Core/Ryze/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
end

core.on_out_of_range = function()
end

core.on_end_q = function()
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

core.on_end_w = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_cast_w = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_w
    core.on_end_time = os.clock() + spell.windUpTime
    orb.core.set_pause(math.huge)
  end
end

core.on_end_e = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_cast_e = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_e
    core.on_end_time = os.clock() + spell.windUpTime
    orb.core.set_pause(math.huge)
  end
end

core.get_action = function()
  if core.on_end_func then
    if os.clock() + network.latency > core.on_end_time then
      core.on_end_func()
    end
  end
  
  if orb.combat.is_active() then
    if player.levelRef >= menu.no_aa:get() then
      if (not q.is_ready() and not w.is_ready() and not e.is_ready()) and orb.core.is_attack_paused() then
        orb.core.set_pause_attack(math.huge)
      end
      orb.core.set_pause_attack(0)
    end
    if menu.hourglass:get() and common.GetPercentHealth() <= menu.glass_hp:get() then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and slot.name == 'ZhonyasHourglass' and slot.state == 0 then
          player:castSpell("self", i)
          orb.core.set_server_pause()
          break
        end
      end
    end
    if menu.use_shield:get() and common.GetPercentHealth() <= menu.seraph_hp:get() then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and slot.name == 'ItemSeraphsEmbrace' and slot.state == 0 then
          player:castSpell("self", i)
          orb.core.set_server_pause()
          break
        end
      end
    end
    if not orb.core.is_paused() then
      if menu.skill_seq:get() == 1 then --QEQW
        if q.get_action_state() then
          q.invoke_action()
          return
        elseif not orb.core.is_paused() then 
          if e.get_action_state() then
            e.invoke_action()
            return
          end
          if w.get_action_state() then
            w.invoke_action()
            
            return
          end
        end
      end
      if menu.skill_seq:get() == 2 then --QWQE
        if q.get_action_state() then
          q.invoke_action()
          return
        elseif not orb.core.is_paused() then 
          if w.get_action_state() then
            w.invoke_action()
            return
          end
          if e.get_action_state() then
            e.invoke_action()
            return
          end
        end
      end
      if menu.skill_seq:get() == 3 then --EWQ
        if e.get_action_state() then
          e.invoke_action()
          return
        elseif not orb.core.is_paused() then
          if w.get_action_state() then
            w.invoke_action()
            return
          end
          if q.get_action_state() then
            q.invoke_action()
            return
          end
        end
      end
    end
  end
end

core.on_recv_spell = function(spell)
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["RyzeQ"] = core.on_cast_q
core.f_spell_map["RyzeW"] = core.on_cast_w
core.f_spell_map["RyzeE"] = core.on_cast_e

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core