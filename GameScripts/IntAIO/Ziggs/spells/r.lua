local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "Core/Ziggs/menu")
local common = module.load("int", "Library/common")

local r = {
  slot = player:spellSlot(3),
  last = 0,
  range = 5300, --28090000

  result = {
    obj = nil,
    seg = nil
  },

  full = {
    predinput = {
      delay = 0,
      radius = 550,
      speed = 0,
      boundingRadiusMod = 0 --1
    }
  },
  
  epicenter = {
    predinput = {
      delay = 0,
      radius = 275,
      speed = 0,
      boundingRadiusMod = 0 --1
    }
  }
}

r.is_ready = function()
  return r.slot.state == 0
end

r.get_damage = function(target, epicenter)
  local damage = 100 + (100 * r.slot.level) + (common.GetTotalAP() * 0.733)
  if epicenter then
    damage = damage * 1.5
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

r.invoke_killable = function()
  local target = ts.get_result(function(res, obj, dist)
    if (
      dist > menu.combo.r.range:get() or 
      obj.buff["bansheesveil"] or 
      obj.buff["itemmagekillerveil"] or 
      obj.buff["nocturneshroudofdarkness"] or 
      obj.buff["sivire"]
    ) then
      return
    end
    if dist > 2000 then
      r.epicenter.predinput.delay = 0.375
      r.epicenter.predinput.speed = 1550
      local seg = gpred.circular.get_prediction(r.epicenter.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) > 4000000 and seg.startPos:dist(seg.endPos) <= 28090000 then
        res.obj = obj
        res.dist = dist
        res.seg = seg
        return true
      end
    end
    if dist < 2000 then
      r.epicenter.predinput.delay = 1.575
      r.epicenter.predinput.speed = math.huge
      local seg = gpred.circular.get_prediction(r.epicenter.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) < 4000000 and seg.startPos:dist(seg.endPos) <= 28090000 then
        res.obj = obj
        res.dist = dist
        res.seg = seg
        return true
      end
    end
  end)
  if target.obj and target.dist and target.seg then
    if target.dist < common.GetAARange(target.obj) then
      local aa_damage = common.CalculateAADamage(target.obj)
      if (aa_damage * 2) > common.GetShieldedHealth("AD", target.obj) then
        return false
      end
    else
      local hit_time = target.seg.startPos:dist(target.seg.endPos) / r.epicenter.predinput.speed + r.epicenter.predinput.delay
      local pos_after_time = gpred.core.get_pos_after_time(target.obj, hit_time)
      local hardlock = gpred.trace.circular.hardlock(r.epicenter.predinput, target.seg, target.obj)
      local pos = target.obj.path.serverPos2D:distSqr(target.seg.endPos)
      local damage = r.get_damage(target.obj)
      if target.seg.endPos:distSqr(pos_after_time) < 75625 or (hardlock and pos < 75625) then
        damage = r.get_damage(target.obj, epicenter)
      end
      if damage > (common.GetShieldedHealth("AP", target.obj) + (target.obj.healthRegenRate * hit_time)) then
        player:castSpell("pos", 3, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
        orb.core.set_server_pause()
        return true
      end
    end
  end
end

r.mode_check = function()
  if menu.combo.r.use:get() == 1 then
    return true
  end
  if menu.combo.r.use:get() == 3 then
    local enemies = ts.loop(function(res, obj, dist)
      if obj.ptr == r.result.obj.ptr then
        res.hit = res.hit and res.hit + 1 or 1
      else
        local cast_pos = vec3(r.result.seg.endPos.x, r.result.obj.y, r.result.seg.endPos.y)
        local dist = obj.path.serverPos:distSqr(cast_pos)
        if dist < 302500 then
          res.hit = res.hit and res.hit + 1 or 1
        end
      end
    end)
    if enemies.hit and enemies.hit >= menu.combo.r.min_enemies:get() then
      return true
    end
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
    if (
      dist > menu.combo.r.range:get() or 
      obj.buff["bansheesveil"] or 
      obj.buff["itemmagekillerveil"] or 
      obj.buff["nocturneshroudofdarkness"] or 
      obj.buff["sivire"]
    ) then
      return
    end
    if dist > 2000 then
      r.full.predinput.delay = 0.375
      r.full.predinput.speed = 1550
      local seg = gpred.circular.get_prediction(r.full.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) > 4000000 and seg.startPos:dist(seg.endPos) <= 28090000 then
        res.obj = obj
        res.seg = seg
        return true
      end
    end
    if dist < 2000 then
      r.full.predinput.delay = 1.575
      r.full.predinput.speed = math.huge
      local seg = gpred.circular.get_prediction(r.full.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) < 4000000 and seg.startPos:dist(seg.endPos) <= 28090000 then
        res.obj = obj
        res.seg = seg
        return true
      end
    end
  end)
  if r.result.seg and r.mode_check() then
    return r.result 
  end
end

r.on_draw = function()
  if r.slot.level > 0 then
    if menu.draws.r_range:get() then
      minimap.draw_circle(player.pos, r.range, 2, graphics.argb(255, 255, 0, 0), 50)
    end
    if menu.draws.r_mode:get() then
      local pos = graphics.world_to_screen(player.pos)
      if menu.combo.r.use:get() == 1 then
        graphics.draw_text_2D("[" .. menu.combo.r.switch.key .. "]Combo R Mode: Always", 25, pos.x - 95, pos.y + 65, graphics.argb(255, 0, 255, 0))
      end
      if menu.combo.r.use:get() == 2 then
        graphics.draw_text_2D("[" .. menu.combo.r.switch.key .. "]Combo R Mode: Killable", 25, pos.x - 95, pos.y + 65, graphics.argb(255, 0, 255, 0))
      end
      if menu.combo.r.use:get() == 3 then
        graphics.draw_text_2D("[" .. menu.combo.r.switch.key .. "]Combo R Mode: ".. menu.combo.r.min_enemies:get() .. " Enemies", 25, pos.x - 95, pos.y + 65, graphics.argb(255, 0, 255, 0))
      end
      if menu.combo.r.use:get() == 4 then
        graphics.draw_text_2D("[" .. menu.combo.r.switch.key .. "]Combo R Mode: Disabled", 25, pos.x - 95, pos.y + 65, graphics.argb(255, 255, 0, 0))
      end
    end
  end
end

return r