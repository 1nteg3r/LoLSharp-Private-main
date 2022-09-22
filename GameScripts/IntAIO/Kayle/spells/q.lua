local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Core/Kayle/menu"); 
local common = module.load(header.id, "Library/common")

local q = {
  slot = player:spellSlot(0),
  last = 0,
  range = 650,

  result = {
    obj = nil,
    dist = 0,
    seg = nil,
  },
  
  predinput = {
    delay = 0.10,
    width = 80,
    speed = 1600,
    boundingRadiusMod = 1,
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

q.invoke_action = function()
  player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, q.result.obj.y, q.result.seg.endPos.y))
  orb.core.set_server_pause()
end

q.invoke__anti_gapcloser = function()
  local target = ts.get_result(function(res, obj, dist)
    if menu.autos.q[obj.charName]:get() and dist <= q.range and obj.path.isActive and obj.path.isDashing then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local pred_pos = gpred.core.lerp(target.path, network.latency + 0.25, target.path.dashSpeed)
    if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 300 then
      player:castSpell("pos", 0, vec3(pred_pos.x, target.y, pred_pos.y))
    end
  end
end

q.trace_filter = function()
  if q.result.seg.startPos:distSqr(q.result.seg.endPos) > 1380625 then
		return false
	end
  if q.result.seg.startPos:distSqr(q.result.obj.path.serverPos2D) > 1380625 then
		return false
	end
	if gpred.trace.linear.hardlock(q.predinput, q.result.seg, q.result.obj) then
    if q.result.dist <= common.GetAARange(q.result.obj) then
      return false
    end
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
  q.result.dist = 0
  q.result.seg = nil
  
  q.result = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    local seg = gpred.linear.get_prediction(q.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) < 1380625 then
      local col = gpred.collision.get_prediction(q.predinput, seg, obj)
      if not col then
        res.obj = obj
        res.dist = dist
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
  if menu.draws.q_range:get() and q.slot.level > 0 then
    graphics.draw_circle(player.pos, q.range, menu.draws.width:get(), menu.draws.q:get(), menu.draws.numpoints:get())
  end
end

return q