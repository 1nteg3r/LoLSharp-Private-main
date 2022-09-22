local orb = module.internal("orb")
local gpred = module.internal("pred")
local ts = module.internal("TS")
local menu = module.load(header.id, "Addons/KogMaw/menu")
local common = module.load(header.id, "common");
local q = module.load(header.id, "Addons/KogMaw/spells/q")
local w = module.load(header.id, "Addons/KogMaw/spells/w")
local e = module.load(header.id, "Addons/KogMaw/spells/e")
local r = module.load(header.id, "Addons/KogMaw/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
  if (orb.combat.is_active() and menu.combo.e.use:get() == 1) or (orb.menu.hybrid:get() and menu.harass.e.use:get() == 1) then
    if e.is_ready() and e.get_prediction() and (e.result.obj and e.result.seg) then
      local dist = player.path.serverPos:dist(e.result.obj.path.serverPos)
      if dist > common.GetAARange() then
        e.invoke_action()
        orb.combat.set_invoke_after_attack(false)
        return
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

core.get_passive_target = function(res, obj, dist)
  if dist > (menu.auto.p.dist:get() + 500) then
    return
  end
  if (dist < menu.auto.p.dist:get() and (100 + (25 * player.levelRef)) > obj.health) then
    res.obj = obj
    return true
  else
    if dist < menu.auto.p.dist:get() then
      res.obj = obj
      return true
    end
  end
end

core.get_action = function()
  if core.on_end_func and os.clock() + network.latency > core.on_end_time then
    core.on_end_func()
  end
  if menu.auto.p.use:get() and player.buff["kogmawicathiansurprise"] then
    local target = ts.get_result(core.get_passive_target, ts.filter_set[8], true, true)
    if target.obj then
      local pos = target.obj.path.serverPos
      local dist = player.path.serverPos:dist(pos)
      if dist < (menu.auto.p.dist:get() - 50) then
        orb.core.set_pause_move(5)
        player:move(pos)
      end
    end
  end
  if menu.auto.q.kill:get() and q.is_ready() then
    if q.invoke_killsteal() then
      return
    end
  end
  if menu.auto.r.kill:get() and r.is_ready() then
    if r.invoke_killsteal() then
      return
    end
  end
  if menu.auto.r.dash:get() and r.is_ready() then
    if r.invoke__on_dash() then
      return
    end
  end
  if menu.semi_r:get() and r.is_ready() then
    local target = ts.get_result(function(res, obj, dist)
      if dist > 2500 then
        return
      end
      local seg = gpred.circular.get_prediction(r.predinput, obj)
      local range = r.range[r.slot.level] * r.range[r.slot.level]
      if seg and seg.startPos:distSqr(seg.endPos) <= range then
        res.obj = obj
        res.seg = seg
        return true
      end
    end)
    if target.seg and target.obj then
      player:castSpell("pos", 3, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
      orb.core.set_server_pause()
    end
  end
  if orb.combat.is_active() then
    if menu.combo.items.botrk:get() then
      local target = ts.get_result(function(res, obj, dist)
        if dist > 1000 or common.GetPercentHealth(target) > menu.combo.items.botrk_at_hp:get() then
          return
        end
        if dist <= common.GetAARange(obj) then
          local aa_damage = common.CalculateAADamage(obj)
          if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
            return
          end
        end
        if dist < 550 then
          res.obj = obj
          return true
        end
      end).obj
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
    if menu.combo.e.use:get() == 2 then
      if e.is_ready() and common.GetPercentPar() >= menu.combo.e.mana_mngr:get() and e.get_prediction() then
        e.invoke_action()
        return
      end
    end
    if menu.combo.q.q:get() then
      if q.is_ready() and common.GetPercentPar() >= menu.combo.q.mana_mngr:get() and q.get_prediction() then
        q.invoke_action()
        return
      end
    end
    if menu.combo.w.w:get() and orb.core.can_attack() then
      if w.is_ready() and common.GetPercentPar() >= menu.combo.w.mana_mngr:get() and w.get_prediction() then
        w.invoke_action()
        return
      end
    end
    if menu.combo.r.r:get() and not orb.core.is_attack_paused() then
      if r.is_ready() and r.stacks <= menu.combo.r.stacks:get() and r.get_prediction() then
        r.invoke_action()
        return
      end
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass.e.use:get() == 2 then
      if e.is_ready() and common.GetPercentPar() >= menu.harass.e.mana_mngr:get() and e.get_prediction() then
        e.invoke_action()
        return
      end
    end
    if menu.harass.q.q:get() then
      if q.is_ready() and common.GetPercentPar() >= menu.harass.q.mana_mngr:get() and q.get_prediction() then
        q.invoke_action()
        return
      end
    end
    if menu.harass.w.w:get() and orb.core.can_attack() then
      if w.is_ready() and common.GetPercentPar() >= menu.harass.w.mana_mngr:get() and w.get_prediction() then
        w.invoke_action()
        return
      end
    end
    if menu.harass.r.r:get() and not orb.core.is_attack_paused() then
      if r.is_ready() and r.stacks <= menu.harass.r.stacks:get() and r.get_prediction()then
        r.invoke_action()
        return
      end
    end
  end
  if orb.menu.lane_clear:get() then
    if menu.clear.e.e:get() then
      if e.is_ready() and common.GetPercentPar() >= menu.clear.w.mana_mngr:get() then
        e.invoke__lane_clear()
        return
      end
    end
    if menu.clear.w.w:get() then
      if w.is_ready() and common.GetPercentPar() >= menu.clear.w.mana_mngr:get() then
        w.invoke__lane_clear()
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

core.f_spell_map["KogMawQ"] = core.on_cast_q
core.f_spell_map["KogMawVoidOoze"] = core.on_cast_e
core.f_spell_map["KogMawLivingArtillery"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core