local orb = module.load("int", "Orbwalking/Orb");
local ts = module.internal('TS')
local gpred = module.internal("pred")
local menu = module.load("int", "Core/Sivir/menu")
local common = module.load("int", "Library/common")

local q = {
  slot = player:spellSlot(0), 
  last = 0,
  range = 1250, --1562500

  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    delay = 0.25,
    width = 90,
    speed = 1350,
    boundingRadiusMod = 1,
    collision = {
      wall = true,
    },
  },
}

q.is_ready = function()
  return q.slot.state == 0
end

q.invoke_action = function()
  player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, q.result.obj.y, q.result.seg.endPos.y))
  orb.core.set_server_pause()
end

q.trace_filter = function()
  if q.result.seg.startPos:distSqr(q.result.seg.endPos) > 1562500 then
		return false
	end
  if q.result.seg.startPos:distSqr(q.result.obj.path.serverPos2D) > 1562500 then
		return false
	end
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

q.get_prediction = function()
  if q.last == game.time then
    return q.result.seg
  end
  q.last = game.time
  q.result.obj = nil
  q.result.seg = nil
  
  q.result = ts.get_result(function(res, obj, dist)
    if dist > 2000 then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) >= common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    local seg = gpred.linear.get_prediction(q.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) < 1562500 then
      local col = gpred.collision.get_prediction(q.predinput, seg, obj)
      if not col then
        res.obj = obj
        res.seg = seg
        return true
      end
    end
  end)
  if q.result.seg and q.trace_filter() then
    return q.result
  end
end

q.on_draw = function()
	if menu.draw_q_range:get() and q.slot.level > 0 then
	  graphics.draw_circle(player.pos, q.range, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

return q