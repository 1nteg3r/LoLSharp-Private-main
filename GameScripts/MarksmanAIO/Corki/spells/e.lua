local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")

local e = {
  slot = player:spellSlot(2),
  last = 0,

  predinput = {
    delay = 0.25,
    radius = player.attackRange,
    dashRadius = 0,
    boundingRadiusModSource = 1,
    boundingRadiusModTarget = 1,
  },
}

e.is_ready = function()
  return e.slot.state == 0
end

e.get_action_state = function()
  if e.is_ready() then
    return e.get_prediction()
  end
end

e.invoke_action = function()
  player:castSpell("pos", 2, e.result)
  orb.core.set_server_pause()
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result
  end
  e.last = game.time
  e.result = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    if gpred.present.get_prediction(e.predinput, obj) then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    e.result = target
    return e.result
  end
  
  return e.result
end

return e