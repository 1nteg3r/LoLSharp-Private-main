local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Twitch/menu")
local common = module.load(header.id, "common")

local w = {
  slot = player:spellSlot(1),
  last = 0,
  range = 950,
  
  result = {
    seg = nil,
    obj = nil,
  },
  
  predinput = {
    delay = 0.25,
    radius = 120,
    speed = 1400,
    boundingRadiusMod = 1
  }
}

local blink_list = {
  ["AkaliSmokeBomb"] = 270,
  ["Deceive"] = 400,
  ["EkkoEAttack"] = 325,
  ["EzrealArcaneShift"] = 475,
  ["KatarinaE"] = 725,
  ["RiftWalk"] = 500,
  ["SummonerFlash"] = 400,
}

w.is_ready = function()
  return w.slot.state == 0
end

w.invoke_action = function()
  player:castSpell("pos", 1, vec3(w.result.seg.endPos.x, w.result.obj.y, w.result.seg.endPos.y))
  orb.core.set_server_pause()
end

w.invoke__anti_gapcloser = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    if obj.path.isActive and obj.path.isDashing then
      local pred_pos = gpred.core.lerp(obj.path, network.latency + w.predinput.delay, obj.path.dashSpeed)
    --local pred_pos = gpred.core.project(player.path.serverPos2D, obj.path, network.latency + w.predinput.delay, w.predinput.speed, obj.path.dashSpeed)
      if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 300 then
        res.obj = obj
        res.seg = pred_pos
        return true
      end
    end
  end)
  if target.seg and target.obj then
    player:castSpell("pos", 1, vec3(target.seg.x, target.obj.y, target.seg.y))
    orb.core.set_server_pause()
    return true
  end
end

w.trace_filter = function()
  if menu.combo.w.use:get() == 1 then
    local dist = player.path.serverPos:dist(w.result.obj.path.serverPos)
    if dist > common.GetAARange(w.result.obj) then
      return true
    end
  end
  if menu.combo.w.use:get() == 2 then
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
end

w.get_prediction = function()
  if w.last == game.time then
    return w.result.seg
  end
  w.last = game.time
  w.result.obj = nil
  w.result.seg = nil
  
  w.result = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    if not menu.combo.w.w_tur:get() then
      if common.UnderDangerousTower(obj.pos) or common.UnderDangerousTower(player.pos) then
        return
      end
    end
    if not menu.combo.w.while_r:get() then
      if player.buff["twitchfullautomatic"] then
        return
      end
    end
    if menu.combo.w.aa_w:get() then
      if dist < common.GetAARange(obj) then
        local aa_dmg = common.CalculateAADamage(obj)
        if (aa_dmg * menu.combo.w.x_aa_w:get()) > common.GetShieldedHealth("AD", obj) then
          return
        end
      end
    end
    local seg = gpred.circular.get_prediction(w.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) <= (w.range * w.range) then	  
      res.obj = obj
      res.seg = seg
      return true
    end
  end)
  if w.result.seg and w.trace_filter() then
    return w.result
  end
end

w.on_recv_spell = function(spell)
  if w.is_ready() and spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO then
    if (not menu.auto.w.in_stealth:get() and player.buff["twitchhideinshadows"]) then
      return
    end
    if blink_list[spell.name] then
      local endPos = spell.endPos
      if spell.startPos:dist(endPos) > blink_list[spell.name] then
        endPos = spell.startPos:lerp(endPos, blink_list[spell.name] / spell.startPos:dist(endPos))
      end
      if player.path.serverPos:distSqr(endPos) <= (w.range * w.range) then
        player:castSpell("pos", 1, endPos)
        orb.core.set_server_pause()
      end
    end
  end
end

w.on_draw = function()
  if menu.draws.w_range:get() and w.slot.level > 0 then
    graphics.draw_circle(player.pos, w.range, menu.draws.width:get(), menu.draws.w:get(), menu.draws.numpoints:get())
  end
end

return w