local orb = module.internal("orb");
local ts = module.internal("TS")

local w = {
  slot = player:spellSlot(1),
  last = 0,
}

w.is_ready = function()
  return w.slot.state == 0
end

w.get_action_state = function()
  if w.is_ready() then
    return w.get_prediction()
  end
end

w.invoke_action = function()
  player:castSpell("self", 1)
  orb.core.set_server_pause()
end

w.get_prediction = function()
  if w.last == game.time then
    return w.result
  end
  w.last = game.time
  w.result = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if dist > 900 then
      return
    end
    if dist > 555 then
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

return w