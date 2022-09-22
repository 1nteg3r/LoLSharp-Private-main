local orb = module.internal("orb");
local ts = module.internal("TS")
local pred = module.internal("pred")
local common = module.load("int", "Library/common")
local menu = module.load("int", "Core/Morgana/menu")

local function trace_filter(Input, seg, obj)
  local totalDelay = (Input.delay + network.latency)

  if seg.startPos:dist(seg.endPos)
          + (totalDelay * obj.moveSpeed)
          + obj.boundingRadius > Input.range then
      return false
  end

  local collision = pred.collision.get_prediction(Input, seg, obj)
  if collision then
      return false
  end

  if pred.trace.linear.hardlock(Input, seg, obj) then
      return true
  end

  if pred.trace.linear.hardlockmove(Input, seg, obj) then
      return true
  end

  local t = obj.moveSpeed / Input.speed

  if pred.trace.newpath(obj, totalDelay, totalDelay + t) then
      return true
  end

  return true
end

local Compute = function(input, seg, obj)
  if input.speed == math.huge then
      input.speed = obj.moveSpeed * 3
  end

  local toUnit = (obj.path.serverPos2D - seg.startPos)

  local cos = obj.direction2D:dot(toUnit:norm())
  local sin = math.abs(obj.direction2D:cross(toUnit:norm()))
  local atan = math.atan(sin, cos)

  local unitVelocity = obj.direction2D * obj.moveSpeed * (1 - cos)
  local spellVelocity = toUnit:norm() * input.speed * (2 - sin)
  local relativeVelocity = (spellVelocity - unitVelocity) * (2 - atan)
  local totalVelocity = (unitVelocity + spellVelocity + relativeVelocity)

  local pos = obj.path.serverPos2D + unitVelocity * (input.delay + network.latency)

  local totalWidth = input.width + obj.boundingRadius

  pos = pos - totalVelocity * (totalWidth / totalVelocity:len())

  local deltaWidth = math.abs(input.width, obj.boundingRadius)
  deltaWidth = deltaWidth * cos + deltaWidth * sin

  local relativeWidth = input.width

  if input.width < obj.boundingRadius then
      relativeWidth = relativeWidth + deltaWidth
  else
      relativeWidth = relativeWidth - deltaWidth
  end

  pos = pos - spellVelocity * (relativeWidth / relativeVelocity:len())
  pos = pos - relativeVelocity * (deltaWidth / spellVelocity:len())

  local toPosition = (pos - seg.startPos)

  local a = unitVelocity:dot(unitVelocity) - spellVelocity:dot(spellVelocity)
  local b = unitVelocity:dot(toPosition) * 2
  local c = toPosition:dot(toPosition)

  local discriminant = b * b - 4 * a * c

  if discriminant < 0 then
      return
  end

  local d = math.sqrt(discriminant)

  local t1 = (2 * c) / (d - b)
  local t2 = (-b - d) / (2 * a)

  return math.min(t1, t2)
end

local real_target_filter = function(input)
  
  local target_filter = function(res, obj, dist)
      if dist > input.range then
          return false
      end

      local seg = pred.linear.get_prediction(input, obj)

      if not seg then
          return false
      end

      res.seg = seg
      res.obj = obj

      if not trace_filter(input, seg, obj) then
          return false
      end

      local t1 = Compute(input, seg, obj)

      if t1 < 0 then
          return false
      end

      res.pos = (pred.core.get_pos_after_time(obj, t1) + seg.endPos) / 2

      local linearTime = (seg.endPos - seg.startPos):len() / input.speed

      local deltaT = (linearTime - t1)
      local totalDelay = (input.delay + network.latency)

      if deltaT < totalDelay then
          return true
      end
      return true
  end
  return
  {
      Result = target_filter,
  }
end


local q = {
  slot = player:spellSlot(0),
  last = 0,
  range = 1175, --1380625
  
  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    range = 1175,
    delay = 0.25,
    width = 70,
    speed = 1200,
    boundingRadiusMod = 1,
    collision = {
      hero = false,
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
  player:castSpell("pos", 0, vec3(q.result.seg.x, q.result.obj.y, q.result.seg.y))
  orb.core.set_server_pause()
end

q.trace_filter = function()
  if q.result.seg.startPos:distSqr(q.result.seg.endPos) > 1380625 then
		return false
	end
  if q.result.seg.startPos:distSqr(q.result.obj.path.serverPos2D) > 1380625 then
		return false
	end
	if gpred.trace.linear.hardlock(q.predinput, q.result.seg, q.result.obj) then
	  return false
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
    if dist > 1500 or not menu.q_blacklist[obj.charName]:get() then
      return
    end
    local target = ts.get_result(real_target_filter(q.predinput).Result) 
        if target.obj and target.pos then 
          res.obj = target.obj 
          res.seg = target.pos
                --player:castSpell("pos", 2, vec3(target.pos.x, mousePos.y, target.pos.y))
          
        end
      
    
  end)
  if q.result.seg then
    return q.result
  end
end

q.on_draw = function()
	if menu.draws.q_range:get() and q.slot.level > 0 then
	  graphics.draw_circle(player.pos, q.range, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

return q