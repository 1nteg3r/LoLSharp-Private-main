local orb = module.internal("orb")
local menu = module.load("int", "Core/Ziggs/menu")
local common = module.load("int", "Library/common")
local q = module.load("int", "Core/Ziggs/spells/q")
local w = module.load("int", "Core/Ziggs/spells/w")
local e = module.load("int", "Core/Ziggs/spells/e")
local r = module.load("int", "Core/Ziggs/spells/r")

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

core.get_action = function()
  if core.on_end_func and os.clock() + network.latency > core.on_end_time then
    core.on_end_func()
  end
  if menu.autos.w.interupt:get() then
    if w.is_ready() and common.GetPercentPar() >= menu.autos.w.mana_mngr:get() and w.invoke_interruptor() then
      return
    end
  end
  if not menu.flee:get() then
    if menu.autos.e.ondash:get() then
      if e.is_ready() and common.GetPercentPar() >= menu.autos.e.mana_mngr:get() and e.invoke__on_dash() then
        return
      end
    end
    if menu.autos.q.ks:get() then
      if q.is_ready() and common.GetPercentPar() >= menu.autos.q.mana_mngr:get() and q.invoke_killsteal() then
        return
      end
    end
    if menu.autos.q.ondash:get() then
      if q.is_ready() and common.GetPercentPar() >= menu.autos.q.mana_mngr:get() and q.invoke__on_dash() then
        return
      end
    end
  else
    if menu.autos.w.flee:get() and not player.isDashing then
      if w.is_ready() and common.GetPercentPar() >= menu.autos.w.mana_mngr:get() and w.invoke_flee() then
        return
      end
    end
   
      player:move(mousePos)
  end
  if orb.combat.is_active() then
    if menu.combo.w.use:get() ~= 3 then
      if common.GetPercentPar() >= menu.combo.w.mana_mngr:get() and w.get_action_state() then
        w.invoke_action()
        return
      end
    end
    if menu.combo.e.use:get() then
      if common.GetPercentPar() >= menu.combo.e.mana_mngr:get() and e.get_action_state() then
        e.invoke_action()
        return
      end
    end
    if menu.combo.q.use:get() then
      if common.GetPercentPar() >= menu.combo.q.mana_mngr:get() and q.get_action_state() then
        q.invoke_action()
        return
      end
    end
    if menu.combo.r.use:get() ~= 4 then
      if common.GetPercentPar() >= menu.combo.r.mana_mngr:get() then
        if menu.combo.r.use:get() == 2 then
          if r.invoke_killable() then
            return
          end
        end
        if r.get_action_state() then
          r.invoke_action()
          return
        end
      end
    end
  else
    if orb.menu.hybrid:get() then
      if menu.harass.e.use:get() then
        if common.GetPercentPar() >= menu.harass.e.mana_mngr:get() and e.get_action_state() then
          e.invoke_action()
          return
        end
      end
    end
    if menu.harass.q.use:get() then
      if common.GetPercentPar() >= menu.harass.q.mana_mngr:get() and q.get_action_state() then
        q.invoke_action()
        return
      end
    end
  end
  if orb.menu.lane_clear:get() then
    if menu.clear.w.use:get() then
      if w.is_ready() and common.GetPercentPar() >= menu.clear.w.mana_mngr:get() and w.invoke_hexplosion() then
        return
      end
    end
    if menu.clear.e.mode:get() ~= 4 then
      if e.is_ready() and common.GetPercentPar() >= menu.clear.e.mana_mngr:get() then
        e.invoke_clear()
        return
      end
    end
    if menu.clear.q.mode:get() ~= 4 then
      if q.is_ready() and common.GetPercentPar() >= menu.clear.q.mana_mngr:get() then
        q.invoke_clear()
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

core.f_spell_map["ZiggsQ"] = core.on_cast_q
core.f_spell_map["ZiggsW"] = core.on_cast_w
core.f_spell_map["ZiggsE"] = core.on_cast_e
core.f_spell_map["ZiggsR"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core