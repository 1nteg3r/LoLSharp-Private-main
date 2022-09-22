local orb = module.internal("orb")
local ts = module.internal("TS")
local menu = module.load(header.id, "Core/Kayle/menu")
local common = module.load(header.id, "Library/common");
local q = module.load(header.id, "Core/Kayle/spells/q")
local w = module.load(header.id, "Core/Kayle/spells/w")
local e = module.load(header.id, "Core/Kayle/spells/e")
local r = module.load(header.id, "Core/Kayle/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
  if orb.combat.is_active() then
    if menu.combo.q.use:get() == 1 then
      if q.is_ready() and common.GetPercentPar() >= menu.combo.q.mana_mngr:get() and q.get_prediction() then
        local dist = player.path.serverPos:dist(q.result.obj.path.serverPos)
        local dist_check = 125
        if player.buff["judicatorrighteousfury"] then
          dist_check = 525
        end
        if dist > dist_check and dist <= q.range then
          q.invoke_action()
          orb.combat.set_invoke_after_attack(false)
          return
        end
      end
    end
    if menu.combo.w.use:get() and orb.combat.target then
      if w.is_ready() and common.GetPercentPar() >= menu.combo.w.mana_mngr:get() and w.get_prediction() then
        local dist = player.path.serverPos:dist(orb.combat.target.path.serverPos)
        local dist_check = 125
        if player.buff["judicatorrighteousfury"] then
          dist_check = 525
        end
        if dist > dist_check and dist <= 1000 then
          w.invoke_action()
          orb.combat.set_invoke_after_attack(false)
          return
        end
      end
    end
  end
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
  if core.on_end_func and os.clock() + network.latency > core.on_end_time then
    core.on_end_func()
  end
  if menu.autos.r.use:get() then 
    r.inove_evade_save()
  end
  if menu.flee:get() then
    if not orb.menu.movement.minimap:get() and minimap.on_map(game.cursorPos) then
      orb.combat.move_to_cursor()
    else
      player:move(mousePos)
    end
    if menu.autos.w.flee:get() and w.get_action_state() then
      w.invoke_action()
      return
    end
  end
  if menu.autos.r.use:get() and r.is_ready() and common.GetPercentHealth() < menu.autos.r.health:get() and r.get_prediction() then
    r.invoke_action()
    return
  end
  if menu.autos.q.use:get() and q.is_ready() and q.invoke__anti_gapcloser() then
    q.invoke_action()
    return
  end
  if menu.autos.w.use:get() and w.is_ready() and common.GetPercentHealth() < menu.autos.w.health:get() and w.get_prediction() then
    w.invoke_action()
    return
  end
  if orb.combat.is_active() then
    if menu.combo.items.botrk:get() then
      local botrk_target = ts.get_result(function(res, obj, dist)
        if dist < 550 then
          res.obj = obj
          return true
        end
      end).obj
      if botrk_target and common.GetPercentHealth(botrk_target) < menu.combo.items.botrk_at_hp:get() then
        for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and (slot.name == 'BilgewaterCutlass' or slot.name == 'ItemSwordOfFeastAndFamine') and slot.state == 0 then
            player:castSpell("obj", i, botrk_target)
            orb.core.set_server_pause()
            break
          end
        end
      end
    end
    if menu.combo.items.gunblade:get() then
      local gunblade_target = ts.get_result(function(res, obj, dist)
        if dist < 770 then
          res.obj = obj
          return true
        end
      end).obj
      if gunblade_target and common.GetPercentHealth(gunblade_target) < menu.combo.items.gunblade_at_hp:get() then
        for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and slot.name == 'HextechGunblade' and slot.state == 0 then
            player:castSpell("obj", i, gunblade_target)
            orb.core.set_server_pause()
            break
          end
        end
      end
    end
    if menu.combo.q.use:get() == 2 and q.is_ready() and common.GetPercentPar() >= menu.combo.q.mana_mngr:get() and q.get_prediction() then
      q.invoke_action()
      return
    end
    if menu.combo.e.use:get() and e.is_ready() and common.GetPercentPar() >= menu.combo.e.mana_mngr:get() and e.get_prediction() then
      e.invoke_action()
      return
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass.e.use:get() and e.is_ready() and common.GetPercentPar() >= menu.harass.e.mana_mngr:get() and e.get_prediction() then
      e.invoke_action()
      return
    end
    if menu.harass.q.use:get() and q.is_ready() and common.GetPercentPar() >= menu.harass.q.mana_mngr:get() and q.get_prediction() then
      q.invoke_action()
      return
    end
  end
end

core.on_recv_spell = function(spell)
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["JudicatorReckoning"] = core.on_cast_q
core.f_spell_map["JudicatorDivineBlessing"] = core.on_cast_w
core.f_spell_map["JudicatorRighteousFury"] = core.on_cast_e
core.f_spell_map["JudicatorIntervention"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core