local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Kaisa/menu")
local common = module.load(header.id, "common");

local w = {
  slot = player:spellSlot(1),
  last = 0,
  range = 3000,
  
  result = {
    seg = nil,
    obj = nil,
	},
  
  predinput = {
		delay = 0.40000000596046,
		width = 130,
		speed = 1750,
		boundingRadiusMod = 1,
    collision = {
      hero = true,
      minion = true,
      wall = true,
    },
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

w.get_damage = function(target)
  local damage = (20 + (25 * (player.levelRef - 1))) + (common.GetTotalAD() * 1.5) + (common.GetTotalAP() * 0.45)
  return common.CalculateMagicDamage(target, damage)
end

w.invoke_action = function()
  player:castSpell("pos", 1, vec3(w.result.seg.endPos.x, w.result.obj.y, w.result.seg.endPos.y))
  --orb.core.set_server_pause()
end

w.invoke_killsteal = function() --beta
  local target = ts.get_result(function(res, obj, dist)
    if dist >= menu.ks_w_slider:get() then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    if w.get_damage(obj) > common.GetShieldedHealth("AP", obj) then
      local seg = gpred.linear.get_prediction(w.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) <= (w.range * w.range) then
        local col = gpred.collision.get_prediction(w.predinput, seg, obj)
        if not col then
          res.obj = obj
          res.seg = seg
          return true
        end
      end
    end
  end)
  if target.obj and target.seg then
    player:castSpell("pos", 1, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
    --orb.core.set_server_pause()
    return true
  end
end

w.trace_filter = function()
  if menu.combo_w:get() == 1 then
    if gpred.trace.linear.hardlock(w.predinput, w.result.seg, w.result.obj) then
      return true
    end
    if gpred.trace.linear.hardlockmove(w.predinput, w.result.seg, w.result.obj) then
      return true
    end
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
    if dist >= menu.combo_w_slider:get() then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    if menu.w_stacks:get() > 0 then
      if obj.buff["kaisapassivemarker"] and obj.buff["kaisapassivemarker"].stacks >= menu.w_stacks:get() then
        local seg = gpred.linear.get_prediction(w.predinput, obj)
        if seg and seg.startPos:distSqr(seg.endPos) <= (w.range * w.range) then
          local col = gpred.collision.get_prediction(w.predinput, seg, obj)
          if not col then
            res.obj = obj
            res.seg = seg
            return true
          end
        end
      end
    else
      local seg = gpred.linear.get_prediction(w.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) <= (w.range * w.range) then
        local col = gpred.collision.get_prediction(w.predinput, seg, obj)
        if not col then
          res.obj = obj
          res.seg = seg
          return true
        end
      end
    end
  end)
  if w.result.seg and w.trace_filter() then
    return w.result
  end
end

return w