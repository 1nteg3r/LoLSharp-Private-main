local orb = module.internal("orb");
local ts = module.internal("TS")
local gpred = module.internal("pred")
local common = module.load("int", "Library/common")
local menu = module.load("int", "Core/Morgana/menu")

local w = {
  slot = player:spellSlot(1),
  last = 0,
  range = 900,
  
  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    delay = 0.7,
    radius = 275,
    speed = math.huge,
    boundingRadiusMod = 0,
  },
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
  player:castSpell("pos", 1, vec3(w.result.seg.endPos.x, w.result.obj.y, w.result.seg.endPos.y))
  orb.core.set_server_pause()
end

w.trace_filter = function()
	if gpred.trace.circular.hardlock(w.predinput, w.result.seg, w.result.obj) then
	  return true
	end
	if gpred.trace.circular.hardlockmove(w.predinput, w.result.seg, w.result.obj) then
	  return true
	end
	if menu.auto_w:get() then
	  return false
	end
	if gpred.trace.newpath(w.result.obj, 0.033, 0.500) then
	  return true
  end
end

w.get_prediction = function()
  if w.last == game.time then
    return w.result.seg
  end
  w.last = game.time
  w.result.obj = nil
  w.result.seg = nil
  
  w.result = ts.get_result(function(res, obj, dist)
    if dist <= w.range then
      local seg = gpred.circular.get_prediction(w.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) < (w.range * w.range) then
        res.obj = obj
        res.seg = seg
        return true
      end
    end
  end)
  if w.result.seg and w.trace_filter() then
    return w.result
  end
end

w.on_draw = function()
	if menu.draws.w_range:get() and w.slot.level > 0 then
	  graphics.draw_circle(player.pos, w.range, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

return w