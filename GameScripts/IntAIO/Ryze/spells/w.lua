local orb = module.internal("orb");
local ts = module.internal("TS")
local menu = module.load("int", "Core/Ryze/menu")

local w = {
  slot = player:spellSlot(1),
  last = 0,
  range = 615,
  is_rooted = false,
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
  
  local target = ts.get_result(function(res, obj, dist)
    if dist < w.range then
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
	if menu.draw_w_range:get() and w.slot.level > 0 then
	  graphics.draw_circle(player.pos, w.range, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

return w