--no q bounce logic yet
local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "Core/Ziggs/menu")
local common = module.load("int", "Library/common")

local q = {
  slot = player:spellSlot(0),
  last = 0,
  
  range = {
    min = 850, --722500
    max = 1400 --1960000
  },
  
  result = {
    seg = nil,
    obj = nil
  },
  
  killsteal = {
    predinput = {
      delay = 0.4, --0.25
      width = 180, --120
      speed = 1700,
      boundingRadiusMod = 1,
      collision = {
        hero = true,
        minion = true,
        wall = true
      },
    }
  },

  normal = {
    predinput = {
      delay = 0.4, --0.25
      radius = 240, --57600  --1st and 2nd bounce = math.max(151, 75 + obj.boundingRadius), 3rd = 240
      speed = 1700,
      boundingRadiusMod = 0 --1
    }
  }
}

local blink_list = {
  ["AkaliSmokeBomb"] = 270,
  ["Deceive"] = 400,
  ["EkkoEAttack"] = 325,
  ["EzrealArcaneShift"] = 475,
  ["KatarinaE"] = 725,
  ["RiftWalk"] = 500,
  ["SummonerFlash"] = 400
}

q.is_ready = function()
  return q.slot.state == 0
end

q.get_damage = function(target)
  local damage = 30 + (45 * q.slot.level) + (common.GetTotalAP() * 0.65)
  return common.CalculateMagicDamage(target, damage)
end

q.get_action_state = function()
  if q.is_ready() then
    return q.get_prediction()
  end
end

q.invoke_action = function()
  player:castSpell("pos", 0, vec3(q.result.seg.endPos.x, q.result.obj.y, q.result.seg.endPos.y))
  orb.core.set_server_pause()
end

q.invoke_killsteal = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist > 2000 then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    if q.get_damage(obj) > common.GetShieldedHealth("AP", obj) then
      local seg = gpred.linear.get_prediction(q.killsteal.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) <= 1960000 then
        local col = gpred.collision.get_prediction(q.killsteal.predinput, seg, obj)
        if not col then
          res.obj = obj
          res.seg = seg
          return true
        end
      end
    end
  end)
  if target.seg and target.obj then
    player:castSpell("pos", 0, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
    orb.core.set_server_pause()
    return true
  end
end

q.invoke_clear = function()
  local mode = menu.clear.q.mode:get()
  local minions = objManager.minions
  if mode == 1 or mode == 3 then
    for a = 0, minions.size[TEAM_ENEMY] - 1 do
      local minion1 = minions[TEAM_ENEMY][a]
      if minion1 and not minion1.isDead and minion1.isVisible then
        local dist_to_minion1 = player.path.serverPos:distSqr(minion1.path.serverPos)
        if dist_to_minion1 < 722500 then
          local count = 0
          for b = 0, minions.size[TEAM_ENEMY] - 1 do
            local minion2 = minions[TEAM_ENEMY][b]
            if minion2 and minion2 ~= minion1 and not minion2.isDead and minion2.isVisible then
              local dist_to_minion2 = minion2.path.serverPos:distSqr(minion1.path.serverPos)
              if dist_to_minion2 < 32400 then
                count = count + 1
              end
            end
            if count > 1 then
              q.normal.predinput.radius = math.max(151, 75 + minion1.boundingRadius)
              local seg = gpred.circular.get_prediction(q.normal.predinput, minion1)
              if seg and seg.startPos:distSqr(seg.endPos) < 1960000 then
                player:castSpell("pos", 0, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
                orb.core.set_server_pause()
                break
              end
            end
          end
        end
      end
    end
  end
  if mode == 2 or mode == 3 then
    for a = 0, minions.size[TEAM_NEUTRAL] - 1 do
      local minion1 = minions[TEAM_NEUTRAL][a]
      if minion1 and not minion1.isDead and minion1.isVisible then
        local dist_to_minion1 = player.path.serverPos:distSqr(minion1.path.serverPos)
        if dist_to_minion1 < 722500 then
          local count = 0
          for b = 0, minions.size[TEAM_NEUTRAL] - 1 do
            local minion2 = minions[TEAM_NEUTRAL][b]
            if minion2 and minion2 ~= minion1 and not minion2.isDead and minion2.isVisible then
              local dist_to_minion2 = minion2.path.serverPos:distSqr(minion1.path.serverPos)
              if dist_to_minion2 < 32400 then
                count = count + 1
              end
            end
            if count > 1 then
              q.normal.predinput.radius = math.max(151, 75 + minion1.boundingRadius)
              local seg = gpred.circular.get_prediction(q.normal.predinput, minion1)
              if seg and seg.startPos:distSqr(seg.endPos) < 1960000 then
                player:castSpell("pos", 0, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
                orb.core.set_server_pause()
                break
              end
            end
          end
        end
      end
    end
  end
end

q.invoke__on_dash = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist <= q.range.max and obj.path.isActive and obj.path.isDashing then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local pred_pos = gpred.core.lerp(target.path, network.latency + q.normal.predinput.delay, target.path.dashSpeed)
    if pred_pos and pred_pos:dist(player.path.serverPos2D) <= q.range.min then
      player:castSpell("pos", 0, vec3(pred_pos.x, target.y, pred_pos.y))
      orb.core.set_server_pause()
      return true
    end
  end
end

q.trace_filter = function()
	if gpred.trace.circular.hardlock(q.normal.predinput, q.result.seg, q.result.obj) then
	  return true
	end
	if gpred.trace.circular.hardlockmove(q.normal.predinput, q.result.seg, q.result.obj) then
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
    if dist > 1500 then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if aa_damage > common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    q.normal.predinput.radius = math.max(151, 75 + obj.boundingRadius)
    local seg = gpred.circular.get_prediction(q.normal.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) <= 722500 then
      res.obj = obj
      res.seg = seg
      return true
    end
  end)
  if q.result.seg and q.trace_filter() then
    return q.result
  end
end

q.on_recv_spell = function(spell)
  if q.is_ready() and common.GetPercentPar() >= menu.autos.q.mana_mngr:get() then
    if blink_list[spell.name] then
      local endPos = spell.endPos
      if spell.startPos:dist(endPos) > blink_list[spell.name] then
        endPos = spell.startPos:lerp(endPos, blink_list[spell.name] / spell.startPos:dist(endPos))
      end
      if player.path.serverPos:distSqr(endPos) <= 722500 then
        player:castSpell("pos", 0, endPos)
        orb.core.set_server_pause()
      end
    end
  end
end

q.on_draw = function()
  if q.slot.level > 0 then
    if menu.draws.q_range:get() then
      graphics.draw_circle(player.pos, q.range.min, menu.draws.width:get(), menu.draws.q:get(), menu.draws.numpoints:get())
    end
    if menu.draws.q_status:get() then
      local pos = graphics.world_to_screen(player.pos)
      if not menu.harass.q.use.toggleValue then
        graphics.draw_text_2D("[" .. menu.harass.q.use.toggle .. "]Auto Harass Q: OFF", 25, pos.x - 95, pos.y + 90, graphics.argb(255, 255, 0, 0))
      else
        graphics.draw_text_2D("[" .. menu.harass.q.use.toggle .. "]Auto Harass Q: ON", 25, pos.x - 95, pos.y + 90, graphics.argb(255, 0, 255, 0))
      end
    end
  end
end

return q