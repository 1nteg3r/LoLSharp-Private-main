local orb = module.internal("orb")
local menu = module.load(header.id, "Addons/Tristana/menu")
local common = module.load(header.id, "common")
local q = module.load(header.id, "Addons/Tristana/spells/q")
local w = module.load(header.id, "Addons/Tristana/spells/w")
local e = module.load(header.id, "Addons/Tristana/spells/e")
local r = module.load(header.id, "Addons/Tristana/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
  if orb.combat.is_active() then
    if menu.combo.e.use:get() and common.GetPercentPar() >= menu.combo.e.mana_mngr:get() and e.get_action_state() then
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

core.on_end_r = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_end_dash = function()
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
  if menu.e_focus:get() then
    for i = 0, objManager.enemies_n - 1 do
      local target = objManager.enemies[i]
      if target and player.pos:dist(target.pos) <= common.GetAARange(target) and target.buff["tristanaechargesound"] and target ~= orb.combat.target then
        orb.combat.target = target
        break
      end
    end
  end
  if r.is_ready() then
    r.invoke__anti_gapcloser()
  end
  if menu.r_kill:get() and not orb.combat.is_active() and r.get_action_state() then
    r.invoke_action()
    return
  end

  if menu.semir:get() then  
    player:move(mousePos)
    local canClientHero = common.GetTarget(common.GetAARange())

    if canClientHero and common.IsValidTarget(canClientHero) then
        if canClientHero.pos:dist(player.pos) <= common.GetAARange(canClientHero) then 
          if player:spellSlot(3).state == 0 then 
            player:castSpell("obj", 3, canClientHero)
          end 
        end
    end 
  end 
  if orb.combat.is_active() then
    if menu.combo.r.use:get() and common.GetPercentPar() >= menu.combo.e.mana_mngr:get() and r.get_action_state() then
      r.invoke_action()
      return
    end
    if menu.combo.q.use:get() and q.get_action_state() then
      q.invoke_action()
      return
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass.q.use:get() and q.get_action_state() then
      q.invoke_action()
      return
    end
    if menu.harass.e.use:get() and common.GetPercentPar() >= menu.harass.e.mana_mngr:get() and e.get_action_state() then
      e.invoke_action()
      return
    end
  end
  if orb.menu.lane_clear:get() and menu.eq_tower:get() ~= 3 then
    local has_e = false
    if e.is_ready() then
      for i=0, objManager.turrets.size[TEAM_ENEMY]-1 do
        local turret = objManager.turrets[TEAM_ENEMY][i]
        if turret and not turret.isDead and (turret.health and turret.health > 0) then
          if player.pos:dist(turret.pos) <= common.GetAARange() then
            if menu.eq_tower:get() == 1 then
              local aa_damage = (common.GetTotalAD() * .3334) * (100 / (100 + turret.armor))
              local damage = (50 + (10 * e.slot.level)) + ((0.4 + (0.1 * e.slot.level)) * common.GetBonusAD()) + (0.5 * common.GetTotalAP())
              local total_damage = ((damage + (damage * 0.3 * 4)) * .3334) * (100 / (100 + turret.armor))
              if total_damage >= (turret.health - (aa_damage * 4)) then
                player:castSpell("obj", 2, turret)
                orb.core.set_server_pause()
                has_e = true
                break
              end
            end
            if menu.eq_tower:get() == 2 then
              player:castSpell("obj", 2, turret)
              orb.core.set_server_pause()
              has_e = true
              break
            end
          end
        else
          has_e = false
          turret = nil
        end
      end
    end
    if q.is_ready() and has_e then
      q.invoke_action()
      has_e = false
      return
    end
  end
end

core.on_recv_self_dash = function()
  local t = player.path.serverPos2D:dist(player.path.point2D[1]) / player.path.dashSpeed
  if os.clock() + t > core.on_end_time then
    core.on_end_func = core.on_end_dash
    core.on_end_time = os.clock() + t
    orb.core.set_pause(math.huge)
  end
end

core.on_recv_spell = function(spell)
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["TristanaW"] = core.on_cast_w
core.f_spell_map["TristanaE"] = core.on_cast_e
core.f_spell_map["TristanaR"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core