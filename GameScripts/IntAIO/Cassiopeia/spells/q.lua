local orb = module.internal("orb")
local ts = module.internal('TS')
local gpred = module.internal("pred")
local menu = module.load("int", "Cassiopeia/menu")
local common = module.load("int", "common")

local q = {
  slot = player:spellSlot(0),
  last = 0,
  range = 850,

  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    range = 850,
    delay = 0.75,
    radius = 170,
    speed = math.huge,
    boundingRadiusMod = 0,
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

q.is_poisoned = function(obj)
  if obj and (
    obj.buff["poisontrailtarget"] or 
    obj.buff["twitchdeadlyvenom"] or 
    obj.buff["cassiopeiawpoison"] or 
    obj.buff["cassiopeiaqdebuff"] or 
    obj.buff["toxicshotparticle"] or 
    obj.buff["bantamtraptarget"]
  ) then
    return true
  end
  return false
end

q.invoke_action = function()
  player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, game.mousePos.y, q.result.seg.endPos.y))
  --orb.core.set_server_pause()
end

q.invoke__lane_clear = function()
  local minions = objManager.minions
  for a = 0, minions.size[TEAM_ENEMY] - 1 do
    local minion1 = minions[TEAM_ENEMY][a]
    if minion1 and not minion1.isDead and minion1.isVisible then
      local dist_to_minion1 = player.path.serverPos:distSqr(minion1.path.serverPos)
      if dist_to_minion1 < (q.range * q.range) then
        local count = 0
        for b = 0, minions.size[TEAM_ENEMY] - 1 do
          local minion2 = minions[TEAM_ENEMY][b]
          if minion2 and minion2 ~= minion1 and not minion2.isDead and minion2.isVisible then
            local dist_to_minion2 = minion2.path.serverPos:distSqr(minion1.path.serverPos)
            if dist_to_minion2 <= (q.predinput.radius * q.predinput.radius) then
              count = count + 1
            end
          end
          if count == menu.clear.q.min_q:get() then
            local seg = gpred.circular.get_prediction(q.predinput, minion1)
            if seg and seg.startPos:dist(seg.endPos) < q.range then
              player:castSpell("pos", 0, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
              --orb.core.set_server_pause()
              break
            end
          end
        end
      end
    end
  end
end

q.invoke__on_dash = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist <= q.range and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local pred_pos = gpred.core.lerp(target.path, network.latency + q.predinput.delay, target.path.dashSpeed)
    if pred_pos and pred_pos:dist(player.path.serverPos2D) <= q.range then
      player:castSpell("pos", 0, vec3(pred_pos.x, target.y, pred_pos.y))
      --orb.core.set_server_pause()
    end
  end
end

q.trace_filter = function()
  if menu.no_qw:get() and q.is_poisoned(q.result.obj) then
    return false
  end
  if gpred.trace.circular.hardlock(q.predinput, q.result.seg, q.result.obj) then
    return true
  end
  if gpred.trace.circular.hardlockmove(q.predinput, q.result.seg, q.result.obj) then
    return true
  end
  if not q.result.obj.path.isActive then
    if q.range < q.result.seg.startPos:dist(q.result.obj.pos2D) + (q.result.obj.moveSpeed * 0.333) then
      return false
    end
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
  
  q.result = ts.get_result(function(res, obj, dist) --add invulnverabilty check
    if dist <= q.range then
      local seg = gpred.circular.get_prediction(q.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) <= (q.range * q.range) then
        res.obj = obj
        res.seg = seg
        return true
      end
    end
  end)
  if q.result.seg  then
    return q.result
  end
end

q.on_draw = function()
  if menu.draws.q_range:get() and q.slot.level > 0 then
    graphics.draw_circle(player.pos, q.range, 1, graphics.argb(255, 255, 255, 200), 100)
  end
end

return q