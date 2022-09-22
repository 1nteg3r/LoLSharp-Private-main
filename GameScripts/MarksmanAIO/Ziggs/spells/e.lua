local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Ziggs/menu")
local common = module.load(header.id, "common")

local e = {
  slot = player:spellSlot(2),
  last = 0,
  range = 900, --810000
  
  result = {
    seg = nil,
    obj = nil
  },

  predinput = {
    delay = 0.4, --0.25
    radius = 325,
    speed = 1800,
    boundingRadiusMod = 0 --1
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

e.is_ready = function()
  return e.slot.state == 0
end

e.get_action_state = function()
  if e.is_ready() then
    return e.get_prediction()
  end
end

e.invoke_action = function()
  player:castSpell("pos", 2, vec3(e.result.seg.endPos.x, e.result.obj.y, e.result.seg.endPos.y))
  orb.core.set_server_pause()
end

e.invoke__on_dash = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    if obj.path.isActive and obj.path.isDashing then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local pred_pos = gpred.core.lerp(target.path, network.latency + e.predinput.delay, target.path.dashSpeed)
    if pred_pos and pred_pos:dist(player.path.serverPos2D) < e.range then
      player:castSpell("pos", 2, vec3(pred_pos.x, target.y, pred_pos.y))
      orb.core.set_server_pause()
      return true
    end
  end
end

e.invoke_clear = function()
  local mode = menu.clear.e.mode:get()
  local minions = objManager.minions
  if mode == 1 or mode == 3 then
    for i = 0, minions.size[TEAM_ENEMY] - 1 do
      local minion1 = minions[TEAM_ENEMY][i]
      if minion1 and not minion1.isDead and minion1.isVisible then
        local dist = player.path.serverPos:distSqr(minion1.path.serverPos)
        if dist <= 810000 then
          local hits = 0
          for i = 0, minions.size[TEAM_ENEMY] - 1 do
            local minion2 = minions[TEAM_ENEMY][i]
            if minion2 then
              if minion2.ptr == minion1.ptr then
                hits = hits + 1
              end
              if minion2.ptr ~= minion1.ptr and not minion2.isDead and minion2.isVisible then
                local dist = minion1.path.serverPos:distSqr(minion2.path.serverPos)
                if dist <= 40000 then
                  hits = hits + 1
                end
              end
            end
          end
          if hits >= menu.clear.e.min_minions:get() then
            player:castSpell("pos", 2, minion1.pos)
            orb.core.set_server_pause()
            break
          end
        end
      end
    end
  end
  if mode == 2 or mode == 3 then
    for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
      local minion1 = minions[TEAM_NEUTRAL][i]
      if minion1 and not minion1.isDead and minion1.isVisible and minion1.charName ~= "Sru_Crab" then
        local dist = player.path.serverPos:distSqr(minion1.path.serverPos)
        if dist <= 810000 then
          local hits = 0
          for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
            local minion2 = minions[TEAM_NEUTRAL][i]
            if minion2 then
              if minion2.ptr == minion1.ptr then
                hits = hits + 1
              end
              if minion2.ptr ~= minion1.ptr and not minion2.isDead and minion2.isVisible then
                local dist = minion1.path.serverPos:distSqr(minion2.path.serverPos)
                if dist <= 40000 then
                  hits = hits + 1
                end
              end
            end
          end
          if hits > 0 then
            player:castSpell("pos", 2, minion1.pos)
            orb.core.set_server_pause()
            break
          elseif (minion1.maxHealth < 100 and hits > 2) or (minion1.maxHealth > 100 and hits > 1) then
            if minion1.charName == "SRU_RazorbeakMini" then
              if hits > 2 then
                player:castSpell("pos", 2, minion1.pos)
                orb.core.set_server_pause()
                break
              end
            else
              player:castSpell("pos", 2, minion1.pos)
              orb.core.set_server_pause()
              break
            end
          end
        end
      end
    end
  end
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result.seg
  end
  e.last = game.time
  e.result.obj = nil
  e.result.seg = nil
  
  e.result = ts.get_result(function(res, obj, dist)
    if dist > 1500 then
      return
    end
    local seg = gpred.circular.get_prediction(e.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) < 810000 then
      res.obj = obj
      res.seg = seg
      return true
    end
  end)
  if e.result.seg then
    local cast_pos = vec3(e.result.seg.endPos.x, e.result.obj.y, e.result.seg.endPos.y)
    local radiusSqr = e.predinput.radius * e.predinput.radius
    if orb.combat.is_active() then
      local enemies = ts.loop(function(res, obj, dist)
        if obj.ptr == e.result.obj.ptr then
          res.hit = res.hit and res.hit + 1 or 1
        else
          local dist_to_next = e.result.obj.path.serverPos:distSqr(obj.path.serverPos)
          local next_to_pos = obj.path.serverPos:distSqr(cast_pos)
          if dist_to_next < radiusSqr and next_to_pos < radiusSqr then
            res.hit = res.hit and res.hit + 1 or 1
          end
        end
      end)
      if enemies.hit and enemies.hit >= menu.combo.e.min_enemies:get() then
        return e.result
      end
    end
    if orb.menu.hybrid:get() then
      local enemies = ts.loop(function(res, obj, dist)
        if obj.ptr == e.result.obj.ptr then
          res.hit = res.hit and res.hit + 1 or 1
        else
          local dist_to_next = e.result.obj.path.serverPos:distSqr(obj.path.serverPos)
          local next_to_pos = obj.path.serverPos:distSqr(cast_pos)
          if dist_to_next < radiusSqr and next_to_pos < radiusSqr then
            res.hit = res.hit and res.hit + 1 or 1
          end
        end
      end)
      if enemies.hit and enemies.hit >= menu.harass.e.min_enemies:get() then
        return e.result
      end
    end
  end
end

e.on_recv_spell = function(spell)
  if e.is_ready() and common.GetPercentPar() >= menu.autos.e.mana_mngr:get() then
    if blink_list[spell.name] then
      local endPos = spell.endPos
      if spell.startPos:dist(endPos) > blink_list[spell.name] then
        endPos = spell.startPos:lerp(endPos, blink_list[spell.name] / spell.startPos:dist(endPos))
      end
      if player.path.serverPos:distSqr(endPos) < 810000 then
        player:castSpell("pos", 2, endPos)
        orb.core.set_server_pause()
      end
    end
  end
end

e.on_draw = function()
  if menu.draws.e_range:get() and e.slot.level > 0 then
    graphics.draw_circle(player.pos, e.range, menu.draws.width:get(), menu.draws.e:get(), menu.draws.numpoints:get())
  end
end

return e