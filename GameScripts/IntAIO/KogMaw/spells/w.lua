local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "Core/KogMaw/menu")
local common = module.load("int", "Library/common")

local w = {
  slot = player:spellSlot(1),
  last = 0,
  range = { 630, 650, 670, 690, 710 },
  
  predinput = {
    delay = 0.25,
    dashRadius = 0,
    boundingRadiusModSource = 1,
    boundingRadiusModTarget = 1,
  }
}

w.is_ready = function()
  return w.slot.state == 0
end

w.invoke_action = function()
  player:castSpell("self", 1)
  orb.core.set_server_pause()
end

w.invoke__lane_clear = function()
  local extended_range = w.range[w.slot.level] + 65
  local count = 0
  local minions = objManager.minions
  for i = 0, minions.size[TEAM_ENEMY] - 1 do
    local minion = minions[TEAM_ENEMY][i]
    if minion and not minion.isDead and minion.isVisible then
      local dist_to_minion = player.path.serverPos:distSqr(minion.path.serverPos)
      if dist_to_minion <= (extended_range * extended_range) then
        count = count + 1
      end
    end
    if count == menu.clear.w.min_minions:get() then
      player:castSpell("self", 1)
      orb.core.set_server_pause()
      break
    end
  end
end

w.get_prediction = function()
  if w.last == game.time then
    return w.result
  end
  w.last = game.time
  w.result = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    w.predinput.radius = w.range[w.slot.level]
    if gpred.present.get_prediction(w.predinput, obj) then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    w.result = target
    return w.result
  end
  
  return w.result
end

w.on_draw = function()
  if menu.draws.w_range:get() and w.slot.level > 0 then
    local extended_range = w.range[w.slot.level] + 65
    graphics.draw_circle(player.pos, extended_range,  1, graphics.argb(255, 150, 255, 200), 100)
  end
end

return w