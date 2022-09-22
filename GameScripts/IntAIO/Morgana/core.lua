local orb = module.internal("orb");
local evade = module.seek("evade")
local menu = module.load("int", "Core/Morgana/menu")
local common = module.load("int", "Library/common")
local q = module.load("int", "Core/Morgana/spells/q")
local w = module.load("int", "Core/Morgana/spells/w")
local e = module.load("int", "Core/Morgana/spells/e")
local r = module.load("int", "Core/Morgana/spells/r")

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

core.on_end_r = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_cast_r = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_r
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
  if evade then
    if menu.e.use:get() then
      if e.is_ready() and common.GetPercentPar() >= 10 and e.get_prediction() then
        e.invoke_action()
        return
      end
    end
  end
  if menu.auto_w:get() and w.get_action_state() then
    w.invoke_action()
    return
  end
  if orb.combat.is_active() then
    if common.GetPercentHealth() <= 30 then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and slot.name == 'ZhonyasHourglass' and slot.state == 0 then
          player:castSpell("self", i)
          orb.core.set_server_pause()
          break
        end
      end
    end
    if menu.combo.q.use:get() then
      if q.is_ready() and common.GetPercentPar() >= 10 and q.get_prediction() then
        q.invoke_action()
        return
      end
    end
    if not menu.auto_w:get() and menu.combo.w.use:get() then
      if w.is_ready() and common.GetPercentPar() >= 10 and w.get_prediction() then
        w.invoke_action()
        return
      end
    end
    if menu.combo.r.use:get() and r.get_action_state() then
      r.invoke_action()
      return
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass.q.use:get() then
      if q.is_ready() and common.GetPercentPar() >= 10 and q.get_prediction() then
        q.invoke_action()
        return
      end
    end
    if not menu.auto_w:get() and menu.harass.w.use:get() then
      if w.is_ready() and common.GetPercentPar() >= 10 and w.get_prediction() then
        w.invoke_action()
        return
      end
    end
  end
end

core.on_recv_spell = function(spell)
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["DarkBindingMissile"] = core.on_cast_q
core.f_spell_map["TormentedSoil"] = core.on_cast_w
core.f_spell_map["SoulShackles"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core