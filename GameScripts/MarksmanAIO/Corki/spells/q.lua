local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Corki/menu")
local common = module.load(header.id, "common")

local q = {
  slot = player:spellSlot(0),
  last = 0,
  range = 825,
  
  result = {
    seg = nil,
    obj = nil,
	},
  
  predinput = {
		delay = 0.5,
		radius = 200,
		speed = 1000, --
		boundingRadiusMod = 0,
	},
}

q.is_ready = function()
  return q.slot.state == 0
end

q.get_damage = function(target)
  local damage = (30 + (45 * q.slot.level)) + (common.GetBonusAD() * 0.5) + (common.GetTotalAP() * 0.5)
  return common.CalculateMagicDamage(target, damage)
end

q.get_action_state = function()
  if q.is_ready() and common.GetPercentPar() > menu.q_mana_mngr:get() then
    return q.get_prediction()
  end
end

q.invoke_action = function()
  player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, q.result.obj.y, q.result.seg.endPos.y))
end

q.invoke_killsteal = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist < common.GetAARange(obj) or dist > 1500 then
      return
    end
    if q.get_damage(obj) > common.GetShieldedHealth("AP", obj) then
      local seg = gpred.circular.get_prediction(q.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) < 680625 then
        res.obj = obj
        res.seg = seg
        return true
      end
    end
  end)
  if target.seg and target.obj then
    player:castSpell("pos", 0, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
    return true
  end
end

q.trace_filter = function()
  if menu.q_on_cc:get() then
    if gpred.trace.circular.hardlock(q.predinput, q.result.seg, q.result.obj) then
      return true
    end
    if gpred.trace.circular.hardlockmove(q.predinput, q.result.seg, q.result.obj) then
      return true
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
  
  q.result = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) >= common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    local seg = gpred.circular.get_prediction(q.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) < 680625 then
      res.obj = obj
      res.seg = seg
      return true
    end
  end)
  if q.result.seg and q.trace_filter() then
    return q.result
  end
end

q.on_draw = function()
  if menu.q_range:get() and q.slot.level > 0 then
    graphics.draw_circle(player.pos, q.range, menu.width:get(), menu.q:get(), menu.numpoints:get())
  end
end

return q