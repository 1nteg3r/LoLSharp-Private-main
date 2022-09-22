local orb = module.internal("orb")
local ts = module.internal("TS")
local evade = module.seek("evade")
local common = module.load(header.id, "common")
local menu = module.load(header.id, "Addons/Teemo/menu")
local q = module.load(header.id, "Addons/Teemo/spells/q")
local w = module.load(header.id, "Addons/Teemo/spells/w")
local e = module.load(header.id, "Addons/Teemo/spells/e")
local r = module.load(header.id, "Addons/Teemo/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
  if menu.aa_first:get() then
    if (orb.combat.is_active() and menu.cq:get() ~= 3) or (orb.menu.hybrid:get() and menu.harass_q:get()) then
      if q.get_action_state() and orb.combat.target and not orb.combat.target.isDead then
        local target = orb.combat.target
        local dist = player.path.serverPos:dist(target.path.serverPos)
        if dist <= common.GetAARange(target) and target.isTargetable then
          q.invoke_action()
          player:attack(target)
          orb.core.set_server_pause()
          return
        end
      end
    end
  end
end

core.on_out_of_range = function()
  if orb.combat.is_active() then
    if menu.combo_w:get() and w.get_action_state() then
      w.invoke_action()
      return
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass_w:get() and w.get_action_state() then
      w.invoke_action()
      return
    end
  end
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
    if menu.disable_evade:get() then
      if player.buff["camouflagestealth"] then
        evade.core.set_pause(math.huge)
      else
        evade.core.set_pause(0)
      end
    else
      evade.core.set_pause(0)
    end
  end
  if r.slot.level > 0 and menu.auto_r:get() and (r.map_name == "Summoner's Rift") and r.slot.stacks >= menu.min_autor:get() then
    for i = 1, #r.shroom_spots do
      local shroom_spot = r.shroom_spots[i]
      local dist_to_shroom = player.path.serverPos:dist(shroom_spot)
      if dist_to_shroom < r.range[r.slot.level] then
        local can_place_here = true
        for _, shroom in pairs(r.existing_shrooms) do
          if shroom.pos == shroom_spot or shroom.pos:dist(shroom_spot) <= 60 then
            can_place_here = false
          end
        end
        if can_place_here and os.clock() > r.cast_interval then
          r.cast_interval = os.clock() + 2
          player:castSpell("pos", 3, shroom_spot)
          orb.core.set_server_pause()
          break
        end
      end
    end
  end
  if orb.combat.is_active() then
    if menu.items.botrk:get() then
      local botrk_target = ts.get_result(function(res, obj, dist)
        if dist < 550 then
          res.obj = obj
          return true
        end
      end).obj
      if botrk_target and common.GetPercentHealth(botrk_target) < menu.items.botrk_hp:get() then
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
    if menu.items.gunblade:get() then
      local gunblade_target = ts.get_result(function(res, obj, dist)
        if dist < 770 then
          res.obj = obj
          return true
        end
      end).obj
      if gunblade_target and common.GetPercentHealth(gunblade_target) < menu.items.gunblade_hp:get() then
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
    if menu.combo_r:get() and r.is_ready() then
      r.get_prediction()
      return
    end
    if menu.cq:get() ~= 3 and not menu.aa_first:get() and q.get_action_state() then
      q.invoke_action()
      return
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass_q:get() and not menu.aa_first:get() and q.get_action_state() then
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

core.f_spell_map["BlindingDart"] = core.on_cast_q
--core.f_spell_map["MoveQuick"] = core.on_cast_w
--core.f_spell_map["ToxicShot"] = core.on_cast_e
core.f_spell_map["TeemoRCast"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core