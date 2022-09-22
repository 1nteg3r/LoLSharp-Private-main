local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "KogMaw/menu")
local common = module.load("int", "common")
local q = {
  slot = player:spellSlot(0),
  last = 0,
  range = 1175, --1380625
  
  result = {
    obj = nil,
    dist = 0,
    seg = nil,
  },
  
  predinput = {
    delay = 0.25,
    width = 70,
    speed = 1650,
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

q.get_damage = function(target)
  local damage = (30 + (50 * q.slot.level)) + (common.GetTotalAP() * 0.5)
  return common.CalculateMagicDamage(target, damage)
end

q.invoke_action = function()
  player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, q.result.obj.y, q.result.seg.endPos.y))
  orb.core.set_server_pause()
end

q.invoke_killsteal = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist > common.GetAARange(obj) and dist < 1500 then
      if q.get_damage(obj) > common.GetShieldedHealth("AP", obj) then
        local seg = gpred.linear.get_prediction(q.predinput, obj)
        if seg and seg.startPos:distSqr(seg.endPos) <= 1380625 then
          local col = gpred.collision.get_prediction(q.predinput, seg, obj)
          if not col then
            res.obj = obj
            res.seg = seg
            return true
          end
        end
      end
    end
  end)
  if target.seg and target.obj then
    player:castSpell("pos", 0, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
    orb.core.set_server_pause()
    return true
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
    graphics.draw_circle(player.pos, q.range,  1, graphics.argb(255, 150, 255, 200), 100)
  end
end

return q