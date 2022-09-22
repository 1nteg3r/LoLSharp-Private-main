local orb = module.internal("orb");
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "Core/Brand/menu")

local q = {
  slot = player:spellSlot(0), 
  last = 0,
  range = 1050,

  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    range = 1050,
    delay = 0.25,
    width = 60,
    speed = 1600,
    boundingRadiusMod = 1, --1
    collision = {
      hero = true,
      minion = true,
      wall = true,
    },
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
  player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, q.result.obj.y, q.result.seg.endPos.y))
  orb.core.set_server_pause()
end

q.trace_filter = function()
  if (orb.combat.is_active() and menu.combo.q:get() == 2) or (orb.menu.hybrid:get() and menu.harass.q:get() == 2) or menu.misc.auto_q:get() then
    if q.result.obj.buff["brandablaze"] then
      return true
    end
  end
  if (orb.combat.is_active() and menu.combo.q:get() == 3) or (orb.menu.hybrid:get() and menu.harass.q:get() == 3) then
    if gpred.trace.linear.hardlock(q.predinput, q.result.seg, q.result.obj) then
      return true
    end
    if gpred.trace.linear.hardlockmove(q.predinput, q.result.seg, q.result.obj) then
      return true
    end
    if gpred.trace.newpath(q.result.obj, 0.033, 0.500) then
      return true
    end
  end
end

q.get_prediction = function()
  if q.last == game.time then
    return q.result.seg
  end
  q.last = game.time
  q.result.obj = nil
  q.result.seg = nil
  
  q.result = ts.get_result(function(res, obj, dist)
    if dist <= q.range then
      local seg = gpred.linear.get_prediction(q.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) < (q.range * q.range) then
        if not gpred.collision.get_prediction(q.predinput, seg, obj) then
          res.obj = obj
          res.seg = seg
          return true
        end
      end
    end
  end)
  if q.result.seg and q.trace_filter() then
    return q.result
  end
end

q.on_draw = function()
  if menu.draws.display:get() then return end
	if menu.draws.q_range:get() and q.slot.level > 0 then
	  graphics.draw_circle(player.pos, q.range, 1, graphics.argb(233, 250, 255, 250), 40)
	end
end

return q