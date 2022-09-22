local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "KogMaw/menu")
local common = module.load("int", "common")

local e = {
  slot = player:spellSlot(2),
  last = 0,
  range = 1280, --1638400

  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    delay = 0.25,
    width = 120,
    speed = 1400,
    boundingRadiusMod = 0,
    collision = {
      wall = true,
    },
  },
}

e.is_ready = function()
  return e.slot.state == 0
end

e.invoke_action = function()
  player:castSpell("pos", 2, vec3(e.result.seg.endPos.x, e.result.obj.y, e.result.seg.endPos.y))
  orb.core.set_server_pause()
end

e.invoke__lane_clear = function()
  local valid = {}
  local minions = objManager.minions
  for i = 0, minions.size[TEAM_ENEMY] - 1 do
    local minion = minions[TEAM_ENEMY][i]
    if minion and not minion.isDead and minion.isVisible then
      local dist = player.path.serverPos:distSqr(minion.path.serverPos)
      if dist <= 1638400 then
        valid[#valid + 1] = minion
      end
    end
  end
  local max_count, cast_pos = 0, nil
  for i = 1, #valid do
    local minion_a = valid[i]
    local current_pos = player.path.serverPos + ((minion_a.path.serverPos - player.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos) + 1300))
    local hit_count = 1
    for j = 1, #valid do
      if j ~= i then
        local minion_b = valid[j]
        local point = mathf.closest_vec_line(minion_b.path.serverPos, player.path.serverPos, current_pos)
        if point and point:dist(minion_b.path.serverPos) < (89 + minion_b.boundingRadius) then
          hit_count = hit_count + 1
        end
      end
    end
    if not cast_pos or hit_count > max_count then
      cast_pos, max_count = current_pos, hit_count
    end
    if cast_pos and max_count > menu.clear.e.min_minions:get() then
      player:castSpell("pos", 2, cast_pos)
      orb.core.set_server_pause()
      break
    end
  end
end

e.trace_filter = function()
  if e.result.seg.startPos:distSqr(e.result.obj.path.serverPos2D) > 1638400 then
		return false
	end
  if gpred.trace.linear.hardlock(e.predinput, e.result.seg, e.result.obj) then
	  return false
	end
  if gpred.trace.linear.hardlockmove(e.predinput, e.result.seg, e.result.obj) then
    return true
  end
  if e.result.seg.startPos:distSqr(e.result.seg.endPos) < (420 * 420) then
    return true
  end
  if gpred.trace.newpath(e.result.obj, 0.033, 0.500) then
    return true
  end
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result.seg
  end
  e.last = game.time
  e.result.obj = nil
  e.result.seg = nil
  
  e.result = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) >= common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    local seg = gpred.linear.get_prediction(e.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) < 1638400 then
      local col = gpred.collision.get_prediction(e.predinput, seg, obj)
      if not col then
        res.obj = obj
        res.seg = seg
        return true
      end
    end
  end)
  if e.result.seg and e.trace_filter() then
    return e.result
  end
end

e.on_draw = function()
  if menu.draws.e_range:get() and e.slot.level > 0 then
    graphics.draw_circle(player.pos, e.range, 1, graphics.argb(255, 150, 255, 200), 100)
  end
end

return e