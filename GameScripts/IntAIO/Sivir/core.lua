local orb = module.load("int", "Orbwalking/Orb");
local ts = module.internal('TS')
local menu = module.load("int", "Core/Sivir/menu")
local common = module.load("int", "Library/common")
local q = module.load("int", "Core/Sivir/spells/q")
local w = module.load("int", "Core/Sivir/spells/w")
local e = module.load("int", "Core/Sivir/spells/e")
local r = module.load("int", "Core/Sivir/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
  if orb.combat.is_active() then
    if menu.combo_w:get() and w.is_ready() then
      local target = orb.combat.target
      if target and not target.isDead and not target.buff[17] then
        local dist_to_target = player.path.serverPos:dist(target.path.serverPos)
        if dist_to_target <= common.GetAARange(target) then
          w.invoke_action()
          player:attack(orb.combat.target)
          orb.core.set_server_pause()
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

core.get_botrk_target = function(res, obj, dist)
  if dist > 1000 or obj.buff[17] then
    return
  end
  if dist < 550 then
    if common.GetPercentHealth(obj) <= menu.botrk_at_hp:get() then
      res.obj = obj
      return true
    end
  end
end

core.get_action = function()
  if core.on_end_func then
    if os.clock() + network.latency > core.on_end_time then
      core.on_end_func()
    end
  end
  if menu.auto_e:get() and e.get_action_state() then
    e.invoke_action()
  end
  if orb.combat.is_active() then
    if menu.combo_botrk:get() then
      local target = ts.get_result(core.get_botrk_target).obj
      if target then
        for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and (slot.name == 'BilgewaterCutlass' or slot.name == 'ItemSwordOfFeastAndFamine') and slot.state == 0 then
            player:castSpell("obj", i, target)
            orb.core.set_server_pause()
            break
          end
        end
      end
    end
    if menu.combo_q:get() then
      if q.is_ready() and common.GetPercentPar() >= menu.min_mana_cq:get() and q.get_prediction() then
        q.invoke_action()
        return
      end
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass_q:get() then
      if q.is_ready() and common.GetPercentPar() >= menu.min_mana_hq:get() and q.get_prediction() then
        q.invoke_action()
        return
      end
    end
  end
  if orb.menu.lane_clear:get() then
    if menu.clear_w:get() and w.is_ready() and common.GetPercentPar() >= menu.min_mana_clw:get() then
      w.invoke__lane_clear()
      return
    end
  end
end

core.on_recv_spell = function(spell)
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["SivirQ"] = core.on_cast_q

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core