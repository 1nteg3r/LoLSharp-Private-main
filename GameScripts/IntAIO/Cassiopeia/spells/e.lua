local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "Cassiopeia/menu")
local common = module.load("int", "common")

local e = {
  slot = player:spellSlot(2), 
  last = 0,
  
  predinput = {
    delay = 0.125,
    radius = 700,
    dashRadius = 0,
    boundingRadiusModSource = 0,
    boundingRadiusModTarget = 0,
  }
}

e.is_ready = function()
  return e.slot.state == 0
end

e.get_action_state = function()
  if e.is_ready() then
    return e.get_prediction()
  end
end

e.is_poisoned = function(obj)
  if obj and (
    obj.buff["poisontrailtarget"] or 
    obj.buff["twitchdeadlyvenom"] or 
    obj.buff["cassiopeiawpoison"] or 
    obj.buff["cassiopeiaqdebuff"] or 
    obj.buff["toxicshotparticle"] or 
    obj.buff["bantamtraptarget"]
  ) then
    return true
  end
  return false
end

e.get_hit_time = function(source, target)
  return source.path.serverPos:dist(target.path.serverPos) / 2500 + 0.125 - network.latency
end

e.get_damage = function(target)
  local base_damage = (48 + (4 * player.levelRef)) + (common.GetTotalAP() * 0.10)
  local damage = common.CalculateMagicDamage(target, base_damage)
  if e.is_poisoned(target) then
    local bonus_damage = (10 + (20 * (e.slot.level - 1))) + (common.GetTotalAP() * 0.60)
    damage = common.CalculateMagicDamage(target, (base_damage + bonus_damage))
  end
  return damage
end

e.invoke_action = function()
  player:castSpell("obj", 2, e.result)
  orb.core.set_server_pause()
end

e.invoke__lane_clear = function()
  for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
    local minion = objManager.minions[TEAM_ENEMY][i]
    if minion and not minion.isDead and minion.isVisible then
      local dist_to_minion = player.path.serverPos:dist(minion.path.serverPos)
      if dist_to_minion <= e.predinput.radius then
        if menu.clear.e.e:get() == 2 and e.is_poisoned(minion) then
          player:castSpell("obj", 2, minion)
          orb.core.set_server_pause()
          break
        end
        if menu.clear.e.e:get() == 1 then
          player:castSpell("obj", 2, minion)
          orb.core.set_server_pause()
          break
        end
      end
    end
  end
end

e.invoke__last_hit = function()
  for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
    local minion = objManager.minions[TEAM_ENEMY][i]
    if
      minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
        minion.pos:dist(player.pos) < 750
     then
      --local minionPos = vec3(minion.x, minion.y, minion.z)
      --delay = player.pos:dist(minion.pos) / 3500 + 0.2
      delay = 70 / 1000 + player.pos:dist(minion.pos) / 840
      if (e.get_damage(minion) >= orb.farm.predict_hp(minion, delay / 2, true) - 150) then
        orb.core.set_pause_attack(1)
      end
      if (e.get_damage(minion) >= orb.farm.predict_hp(minion, delay / 2, true)) then
        player:castSpell("obj", 2, minion)
      end
    end
  end
end

e.custom_filter = ts.filter.new()
e.custom_filter.index = function(obj, rank_val)
  return common.GetShieldedHealth("AP", obj) / e.get_damage(obj)
end

e.get_target = function(res, obj, dist)
  if dist > 1500 or obj.buff[17] then
    return
  end
  if gpred.present.get_prediction(e.predinput, obj) then
    res.obj = obj
    return true
  end
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result
  end
  e.last = game.time
  e.result = nil
  
  local target = ts.get_result(e.get_target, e.custom_filter).obj
  if target then
    local damage = e.get_damage(target)
    local real_health = common.GetShieldedHealth("AP", target)
    if damage >= real_health then
      e.result = target
      return e.result
    end
    if (orb.combat.is_active() and menu.combo.e.e:get() == 2 and e.is_poisoned(target)) or (orb.menu.hybrid:get() and menu.harass.e.e:get() == 2 and e.is_poisoned(target)) then
      e.result = target
      return e.result
    end
    if (orb.combat.is_active() and menu.combo.e.e:get() == 1) or (orb.menu.hybrid:get() and menu.harass.e.e:get() == 1) then
      e.result = target
      return e.result
    end
  end
  
  return e.result
end

e.on_draw = function()
  if menu.draws.e_range:get() and e.slot.level > 0 then
    graphics.draw_circle(player.pos, (e.predinput.radius + 65), 1, graphics.argb(255, 255, 255, 200), 100)
  end
end

return e