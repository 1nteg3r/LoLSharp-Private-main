local function trace_filter(Input, seg, obj)
  local totalDelay = (Input.delay + network.latency)

  if seg.startPos:dist(seg.endPos)
          + (totalDelay * obj.moveSpeed)
          + obj.boundingRadius > Input.range then
      return false
  end

  local collision = mainP.collision.get_prediction(Input, seg, obj)
  if collision then
      return false
  end

  if mainP.trace.linear.hardlock(Input, seg, obj) then
      return true
  end

  if mainP.trace.linear.hardlockmove(Input, seg, obj) then
      return true
  end

  local t = obj.moveSpeed / Input.speed

  if mainP.trace.newpath(obj, totalDelay, totalDelay + t) then
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

      local seg = mainP.linear.get_prediction(input, obj)

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

      res.pos = (mainP.core.get_pos_after_time(obj, t1) + seg.endPos) / 2

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
