local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Kaisa/menu")


local q = {
  slot = player:spellSlot(0),
  last = 0,
  
  predinput = {
    delay = 0.25,
    radius = 600,
    dashRadius = 0,
    boundingRadiusModSource = 1,
    boundingRadiusModTarget = 0,
  },
}

q.is_ready = function()
  return q.slot.state == 0
end

q.get_action_state = function()
  if q.is_ready() then
    return q.get_prediction()
  end
end

q.invoke_action = function()
  player:castSpell("self", 0)
  orb.core.set_server_pause()
end

q.get_prediction = function()
  if q.last == game.time then
    return q.result
  end
  q.last = game.time
  q.result = nil
  
  local count = 0
  for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
    local minion = objManager.minions[TEAM_ENEMY][i]
    if minion and not minion.isDead and minion.isVisible then
      local distSqr = player.path.serverPos:distSqr(minion.path.serverPos)
      if distSqr <= (q.predinput.radius * q.predinput.radius) then
        count = count + 1
      end
    end
  end
  
    local target = ts.get_result(function(res, obj, dist)
      if dist > 1000 then
        return
      end
      if gpred.present.get_prediction(q.predinput, obj) then
        res.obj = obj
        return true
      end
    end).obj
    if count == 0 and menu.combo_q:get() == 1 then 
      if target then
        q.result = target
        return q.result
      end
    elseif menu.combo_q:get() == 2 then 
      if target then
        q.result = target
        return q.result
      end
    end 
  return q.result
end

return q