local orb = module.internal("orb");
local ts = module.internal("TS")
local menu = module.load("int", "Core/Brand/menu")
local common = module.load("int", "Library/common")

local r = {
  slot = player:spellSlot(3),  
  last = 0,
  range = 750,
  bounces = 1,
}

r.is_ready = function()
  return r.slot.state == 0
end

r.get_damage = function()
  return ((r.slot.level * 100) + (common.GetTotalAP() * 0.25)) * r.bounces
end

r.get_action_state = function()
  if r.is_ready() then
    return r.get_prediction()
  end
end

r.invoke_action = function()
  player:castSpell("obj", 3, r.result)
  orb.core.set_server_pause()
end

r.get_prediction = function()
  if r.last == game.time then
    return r.result
  end
  r.last = game.time
  r.result = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if dist <= r.range then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local count = 0
    local enemies_hit = 1
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
      local minion = objManager.minions[TEAM_ENEMY][i]
      if minion and not minion.isDead and minion.isVisible then
        local distSqr = minion.path.serverPos:distSqr(target.path.serverPos)
        if distSqr < (585 * 585) then
          count = count + 1
        end
      end
    end
    for i = 0, objManager.enemies_n - 1 do
      local enemy = objManager.enemies[i]
      if enemy and not enemy.isDead and enemy.isVisible and enemy.isTargetable and enemy.ptr ~= target.ptr then
        local distSqr = enemy.path.serverPos:distSqr(target.path.serverPos)
        if distSqr < (585 * 585) then
          count = count + 1
          enemies_hit = enemies_hit + 1
        end
      end
    end
    if count > 0 then
      r.bounces = 3
    end
    if menu.combo.r.r_kill:get() and menu.combo.r.min_r:get() > 0 then
      local damage = common.CalculateMagicDamage(target, r.get_damage())
      if damage >= common.GetShieldedHealth("AP", target) then
        local dist = player.path.serverPos:dist(target.path.serverPos)
        if dist <= common.GetAARange(target) then
          local aa_damage = common.CalculateAADamage(target)
          if aa_damage > common.GetShieldedHealth("AD", target) then
            return r.result
          end
        end
        r.bounces = 1
        r.result = target
        return r.result
      end
    end
    if enemies_hit >= menu.combo.r.min_r:get() then
      r.result = target
      return r.result
    end
  end

  return r.result
end

r.on_draw = function()
  if menu.draws.display:get() then return end
	if menu.draws.r_range:get() and r.slot.level > 0 then
	  graphics.draw_circle(player.pos, r.range, 1, graphics.argb(255, 255, 255, 255), 40)
	end
end

return r