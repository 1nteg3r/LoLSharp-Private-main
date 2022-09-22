local orb = module.internal("orb")
local ts = module.internal('TS')
local gpred = module.internal("pred")
local menu = module.load("int", "Cassiopeia/menu")
local common = module.load("int", "common")

local w = {
  slot = player:spellSlot(1),
  last = 0,
  
  range = {
    min = 0,
    max = 800
  },

  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    delay = 0.7,
    radius = 200,
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

w.is_poisoned = function(obj)
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

w.invoke_action = function()
  player:castSpell("pos", 1, vec3(w.result.seg.endPos.x, w.result.obj.y, w.result.seg.endPos.y))
  orb.core.set_server_pause()
end

w.invoke__anti_gapcloser = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist <= w.range.max and obj.path.isActive and obj.path.isDashing then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local pred_pos = gpred.core.lerp(target.path, network.latency + w.predinput.delay, target.path.dashSpeed)
    if pred_pos and pred_pos:dist(player.path.serverPos2D) > w.range.min and pred_pos:dist(player.path.serverPos2D) <= w.range.max then
      player:castSpell("pos", 1, vec3(pred_pos.x, target.y, pred_pos.y))
      orb.core.set_server_pause()
    end
  end
end

w.trace_filter = function()
  if menu.no_qw:get() and w.is_poisoned(w.result.obj) then
    return false
  end
  if gpred.trace.circular.hardlock(w.predinput, w.result.seg, w.result.obj) then
    return false
  end
  if gpred.trace.circular.hardlockmove(w.predinput, w.result.seg, w.result.obj) then
    return true
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
    if dist <= w.range.max then
      local seg = gpred.circular.get_prediction(w.predinput, obj)
      if seg then
        local distSqr = seg.startPos:distSqr(seg.endPos)
        if distSqr > (w.range.min * w.range.min) and distSqr <= (w.range.max * w.range.max) then
          res.obj = obj
          res.seg = seg
          return true
        end
      end
    end
  end)
  if w.result.seg  then
    return w.result
  end
end

w.on_draw = function()
  if menu.draws.w_range:get() and w.slot.level > 0 then
    graphics.draw_circle(player.pos, w.range.max, 1, graphics.argb(255, 255, 255, 200), 100)
  end
end

return w