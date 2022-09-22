local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Corki/menu")
local common = module.load(header.id, "common")

local r = {
  slot = player:spellSlot(3),
  last = 0,
  range = 1225, --
  
  result = {
    seg = nil,
    obj = nil,
	},
  
  predinput = {
		delay = 0.17500001192093,
		width = 40,
		speed = 2000,
		boundingRadiusMod = 0, --1
		collision = {
			hero = true,
			minion = true,
      wall = true,
		},
	},
}

r.is_ready = function()
  return r.slot.state == 0
end

r.get_damage = function(target)
  local damage =  (50 + (25 * r.slot.level)) + (common.GetTotalAD() * ((r.slot.level * 0.3) - .15)) + (common.GetTotalAP() * 0.2)
  if player.buff["mbcheck2"] then
    damage = damage * 2
  end
  return common.CalculateMagicDamage(target, damage)
end

r.get_action_state = function()
  if r.is_ready() then
    return r.get_prediction()
  end
end

r.invoke_action = function()
  player:castSpell("pos", 3, vec3(r.result.seg.endPos.x, r.result.obj.y, r.result.seg.endPos.y))
  orb.core.set_server_pause()
end

r.invoke_killsteal = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist < common.GetAARange(obj) or dist > 2000 then
      return
    end
    if (r.get_damage(obj) * 2) > common.GetShieldedHealth("AP", obj) then
      local seg = gpred.linear.get_prediction(r.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) < 1500625 then
        local col = gpred.collision.get_prediction(r.predinput, seg, obj)
        if not col then
          res.obj = obj
          res.seg = seg
          return true
        end
      end
    end
  end)
  if target.seg and target.obj then
    player:castSpell("pos", 3, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
    orb.core.set_server_pause()
  end
end

r.trace_filter = function()
  if player.sar == menu.r_mana_mngr:get() then
    return false
  end
  if r.result.seg.startPos:distSqr(r.result.obj.path.serverPos2D) > 1500625 then
		return false
	end
	if gpred.trace.linear.hardlock(r.predinput, r.result.seg, r.result.obj) then
	  return true
	end
	if gpred.trace.linear.hardlockmove(r.predinput, r.result.seg, r.result.obj) then
	  return true
	end
	if gpred.trace.newpath(r.result.obj, 0.033, 0.500) then
	  return true
	end
end

r.get_prediction = function()
  if r.last == game.time then
    return r.result.seg
  end
  r.last = game.time
  r.result.obj = nil
  r.result.seg = nil
  
  r.result = ts.get_result(function(res, obj, dist)
    if dist > 2000 then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    local seg = gpred.linear.get_prediction(r.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) < 1500625 then
      local col = gpred.collision.get_prediction(r.predinput, seg, obj)
      if not col then
        res.obj = obj
        res.seg = seg
        return true
      end
    end
  end)
  if r.result.seg and r.trace_filter() then
    return r.result
  end
end

r.on_draw = function()
  if menu.r_range:get() and r.slot.level > 0 then
    graphics.draw_circle(player.pos, r.range, menu.width:get(), menu.r:get(), menu.numpoints:get())
  end
end

return r