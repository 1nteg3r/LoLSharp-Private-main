local orb = module.internal("orb")
local menu = module.load(header.id, "Core/Kayle/menu")

local w = {
  slot = player:spellSlot(1),
  last = 0,
  range = 900,
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
  player:castSpell("obj", 1, w.result)
  orb.core.set_server_pause()
end

w.get_prediction = function()
  if w.last == game.time then
    return w.result
  end
  w.last = game.time
  w.result = nil
  
  w.result = player
  
  return w.result
end

return w