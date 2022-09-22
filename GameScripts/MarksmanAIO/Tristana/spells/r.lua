local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Tristana/menu")
local common = module.load(header.id, "common")

local r = {
  slot = player:spellSlot(3),
  last = 0,
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
  player:castSpell("obj", 3, r.result)
  orb.core.set_server_pause()
end

r.invoke__anti_gapcloser = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist <= 1000 and menu.whitelist[obj.charName]:get() and obj.path.isActive and obj.path.isDashing and not obj.buff["rocketgrab"] then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local pred_pos = gpred.core.project(player.path.serverPos2D, target.path, network.latency + 0.25, 2000, target.path.dashSpeed)
    if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 260 then
      player:castSpell("obj", 3, target)
      orb.core.set_server_pause()
    end
  end
end

r.get_prediction = function()
  if r.last == game.time then
    return r.result
  end
  r.last = game.time
  r.result = nil

  local target = ts.get_result(function(res, obj, dist)
    if dist <= common.GetAARange(obj) then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local aa_dmg = common.CalculateAADamage(target)
    if (aa_dmg * menu.combo.r.x_aa:get()) > common.GetShieldedHealth("AD", target) then
      return r.result
    end
    local damage = (200 + (r.slot.level * 100)) + (common.GetTotalAP() * 1.00)
    local total_damage = common.CalculateMagicDamage(target, damage)
    if total_damage > common.GetShieldedHealth("AP", target) then
      r.result = target
      return r.result
    end
  end
  
  return r.result
end

return r