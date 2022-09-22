local orb = module.internal("orb");
local ts = module.internal("TS")
local menu = module.load("int", "Core/Brand/menu")

local e = {
  slot = player:spellSlot(2), 
  last = 0,
  range = 625,
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
  player:castSpell("obj", 2, e.result)
  orb.core.set_server_pause()
end

e.ts_filter = function(obj, dist)
  return dist < e.range
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result
  end
  e.last = game.time
  e.result = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if dist <= e.range then
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