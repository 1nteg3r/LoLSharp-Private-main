local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/KogMaw/menu")
local common = module.load(header.id, "common");

local r = {
  slot = player:spellSlot(3),
  last = 0,
  range = { 1200, 1500, 1800 },
  stacks = 0,
  
  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    delay = 1.1,
    radius = 241,
    speed = math.huge,
    boundingRadiusMod = 0,
  },
}

r.is_ready = function()
  return r.slot.state == 0
end

r.get_action_state = function()
  if r.is_ready() then
    return r.get_prediction()
  end
end

r.invoke_action = function()
  player:castSpell("pos", 3, vec3(r.result.seg.endPos.x, r.result.obj.y, r.result.seg.endPos.y))
  --orb.core.set_server_pause()
end

r.get_damage = function(target)
  local damage = (60 + (40 * r.slot.level)) + (common.GetBonusAD() * 0.65) + (common.GetTotalAP() * 0.25)
  local target_health_scaling = (1 - (target.health / target.maxHealth)) * 0.833
  target_health_scaling = (target_health_scaling * 100) > 50 and 0.5 or target_health_scaling
  return (damage + (target_health_scaling * damage)) * common.MagicReduction(target)
end

r.invoke_killsteal = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist > 2500 then
      return
    end
    if dist <= r.range[r.slot.level] and dist > common.GetAARange(obj) then
      if r.get_damage(obj) > common.GetShieldedHealth("AP", obj) then
        res.obj = obj
        return true
      end
    end
  end, ts.filter_set[8]).obj
  if target then
    local seg = gpred.circular.get_prediction(r.predinput, target)
    local range = r.range[r.slot.level] * r.range[r.slot.level]
    if seg and seg.startPos:distSqr(seg.endPos) <= range then
      player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
      --orb.core.set_server_pause()
      return true
    end
  end
end

r.invoke__on_dash = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist > 2500 or common.GetPercentHealth(obj) > 40 then
      return
    end
    if dist <= (r.range[r.slot.level] + obj.boundingRadius) and obj.path.isActive and obj.path.isDashing then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local pred_pos = gpred.core.lerp(target.path, network.latency + r.predinput.delay, target.path.dashSpeed)
    if pred_pos and pred_pos:dist(player.path.serverPos2D) > common.GetAARange() and pred_pos:dist(player.path.serverPos2D) <= 1200 then
      player:castSpell("pos", 3, vec3(pred_pos.x, target.y, pred_pos.y))
      --orb.core.set_server_pause()
      return true
    end
  end
end

r.trace_filter = function()
  if menu.combo.r.cced:get() then
    if gpred.trace.circular.hardlock(r.predinput, r.result.seg, r.result.obj) then
      return true
    end
    if gpred.trace.circular.hardlockmove(r.predinput, r.result.seg, r.result.obj) then
      return true
    end
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
    if dist > 2500 then
      return
    end
    if dist <= common.GetAARange(obj) then
      if (orb.combat.is_active() and not menu.combo.r.in_aa:get()) or (orb.menu.hybrid:get() and not menu.harass.r.in_aa:get()) then
        return
      end
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 3) > common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    if (orb.combat.is_active() and common.GetPercentHealth(obj) < menu.combo.r.at_hp:get()) or (orb.menu.hybrid:get() and common.GetPercentHealth(obj) < menu.harass.r.at_hp:get()) then
      local seg = gpred.circular.get_prediction(r.predinput, obj)
      local range = r.range[r.slot.level] * r.range[r.slot.level]
      if seg and seg.startPos:distSqr(seg.endPos) <= range then
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

local function HasBuff(unit, name)
  local buff = unit.buff[string.lower(name)];
  if buff and buff.owner == unit then 
      if game.time <= buff.endTime then
          return true, buff.stacks
      end
  end
  return false, 0
end

r.on_update_buff = function()
  local buff, stacks = HasBuff(player, 'kogmawlivingartillerycost');
  if buff then
    r.stacks = math.min(10, stacks + 1)
  else 
    r.stacks = 0
  end
end


r.on_draw = function()
  if menu.draws.r_range:get() and r.slot.level > 0 then
    graphics.draw_circle(player.pos, r.range[r.slot.level], menu.draws.width:get(), menu.draws.r:get(), menu.draws.numpoints:get())
  end
end

return r