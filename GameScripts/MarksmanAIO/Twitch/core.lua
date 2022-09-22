local orb = module.internal("orb")
local ts = module.internal("TS")
local menu = module.load(header.id, "Addons/Twitch/menu")
local common = module.load(header.id, "common")
local q = module.load(header.id, "Addons/Twitch/spells/q")
local w = module.load(header.id, "Addons/Twitch/spells/w")
local e = module.load(header.id, "Addons/Twitch/spells/e")
local r = module.load(header.id, "Addons/Twitch/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
  if orb.combat.is_active() then
    if menu.combo.q.use:get() then
      if q.is_ready() and common.GetPercentPar() >= menu.combo.q.mana_mngr:get() then
        q.invoke_action()
        orb.combat.set_invoke_after_attack(false)
        return
      end
    end
    if menu.combo.w.use:get() == 1 then
      if w.is_ready() and common.GetPercentPar() >= menu.combo.w.mana_mngr:get() and w.get_prediction() then
        w.invoke_action()
        orb.combat.set_invoke_after_attack(false)
        return
      end
    end
  end
  if menu.auto.e.aa:get() then
    if e.is_ready() and common.GetPercentPar() >= menu.auto.e.mana_mngr:get() and e.get_prediction_after_aa() then
      e.invoke_action()
      orb.combat.set_invoke_after_attack(false)
      return
    end
  end
end

core.on_out_of_range = function()
end

core.on_end_w = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_end_e = function()
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
  if menu.keys.q_recall:get() and q.is_ready() then
    q.invoke__stealth_recall()
    return
  end
  if menu.auto.e.jungle.steal:get() then
    if e.is_ready() and common.GetPercentPar() >= menu.auto.e.mana_mngr:get() then
      if e.invoke__jungle_steal() then
        return
      end
    end
  end
  if menu.auto.e.killable:get() or menu.auto.e.max_stacks:get() then
    if e.is_ready() and common.GetPercentPar() >= menu.auto.e.mana_mngr:get() and e.get_prediction() then
      e.invoke_action()
      return
    end
  end
  if menu.auto.w.anti_gap:get() then
    if w.is_ready() and common.GetPercentPar() >= menu.auto.w.mana_mngr:get() then
      if (not menu.auto.w.in_stealth:get() and player.buff[q.buff.name]) then
        return
      else
        if w.invoke__anti_gapcloser() then
          return
        end
      end
    end
  end
  if orb.combat.is_active() then
    if menu.combo.w.use:get() == 2 then
      if w.is_ready() and common.GetPercentPar() >= menu.combo.w.mana_mngr:get() and w.get_prediction() then
        w.invoke_action()
        return
      end
    end
    if menu.combo.r.use:get() then
      if r.is_ready() and common.GetPercentPar() >= menu.combo.r.mana_mngr:get() and r.get_prediction() then
        r.invoke_action()
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

core.f_spell_map["TwitchVenomCask"] = core.on_cast_w
core.f_spell_map["TwitchExpunge"] = core.on_cast_e

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core