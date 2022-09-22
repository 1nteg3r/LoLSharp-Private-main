local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local evade = module.seek("evade")
local menu = module.load("int", "Core/Ziggs/menu")
local common = module.load("int", "Library/common")

local w = {
  slot = player:spellSlot(1),
  last = 0,
  range = 1000, --1000000,

  predinput = {
    delay = 0.25,
    radius = 325,
    speed = 2000,
    boundingRadiusMod = 0 --1
  }
}

local interruptor = {
    ["FiddleSticks"] = { ["Crowstorm"] = { end_time = 0 } },
    ["Jhin"] = { ["JhinR"] = { end_time = 0 } },
    ["Karthus"] = { ["KarthusFallenOne"] = { end_time = 0 } },
    ["Katarina"] = { ["KatarinaR"] = { end_time = 0 } },
    ["Lucian"] = { ["LucianR"] = { end_time = 0 } },
    ["Malzahar"] = { ["Malzahar"] = { end_time = 0 } },
    ["MissFortune"] = { ["MissFortuneBulletTime"] = { end_time = 0 } },
    ["Nunu"] = { ["AbsoluteZero"] = { end_time = 0 } },
    ["Pantheon"] = { ["PantheonRJump"] = { end_time = 0 } },
    ["Shen"] = { ["ShenR"] = { end_time = 0 } },
    ["VelKoz"] = { ["VelkozR"] = { end_time = 0 } }
}

w.is_ready = function()
  return w.slot.state == 0
end

w.get_damage = function(target)
  local damage = 35 + (35 * w.slot.level) + (common.GetTotalAP() * 0.35)
  return common.CalculateMagicDamage(target, damage)
end

w.get_action_state = function()
  if w.is_ready() then
    return w.get_prediction()
  end
end

w.invoke_action = function()
  player:castSpell("pos", 1, w.result)
  orb.core.set_server_pause()
end

w.invoke_flee = function()
  local pos = (player.path.serverPos - mousePos):norm()
  local cast_pos = vec3(player.x + (pos.x * 80), player.y, player.z + (pos.z * 80))
  if evade and evade.core.is_action_safe(cast_pos, w.speed, w.delay) then
    player:castSpell("pos", 1, cast_pos)
    orb.core.set_server_pause()
    return
  else
    player:castSpell("pos", 1, cast_pos)
    orb.core.set_server_pause()
    return
  end
end

w.invoke_interruptor = function()
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if enemy and not enemy.isDead and enemy.isVisible and interruptor[enemy.charName] and enemy.activeSpell then
      local channeling = interruptor[enemy.charName][enemy.activeSpell.name]
      if channeling and channeling.end_time > os.clock() then
        local seg = gpred.circular.get_prediction(w.predinput, enemy)
        if seg and seg.startPos:dist(seg.endPos) <= 1000000 then
          local hit_time = seg.startPos:dist(seg.endPos) / w.predinput.speed + w.predinput.delay
          local remaining_channel_time = channeling.end_time - os.clock()
          if hit_time < remaining_channel_time then
            player:castSpell("pos", 1, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
            orb.core.set_server_pause()
            return true
          end
        end
      end
    end
  end
end

w.invoke_hexplosion = function()
  for i = 0, objManager.turrets.size[TEAM_ENEMY] - 1 do
    local turret = objManager.turrets[TEAM_ENEMY][i]
    if turret and not turret.isDead and turret.health > 0 then
      local dist = player.path.serverPos:distSqr(turret.pos)
      if dist <= 1000000 then
        local threshold = 22.5 + (2.5 * w.slot.level)
        if common.GetPercentHealth(turret) < threshold then
          player:castSpell("pos", 1, turret.pos)
          orb.core.set_server_pause()
          return true
        end
      end
    else
      turret = nil
    end
  end
end

w.trace_filter = function(temp)
	if gpred.trace.circular.hardlock(w.predinput, temp.seg, temp.obj) then
	  return false
	end
  if w.slot.name == "ZiggsWToggle" and temp.seg.endPos:distSqr(temp.obj.path.serverPos2D) < 105625 then
    return true
  end
	if gpred.trace.circular.hardlockmove(w.predinput, temp.seg, temp.obj) then
	  return true
	end
  if gpred.trace.newpath(temp.obj, 0.033, 0.500) then
	  return true
	end
end

w.get_prediction = function()
  if w.last == game.time then
    return w.result
  end
  w.last = game.time
  w.result = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if (
      dist > 1500 or 
      obj.buff["rocketgrab"] or
      obj.buff["bansheesveil"] or 
      obj.buff["itemmagekillerveil"] or 
      obj.buff["nocturneshroudofdarkness"] or 
      obj.buff["sivire"] or
      obj.buff["fioraw"] or
      obj.buff["blackshield"]
    ) then
      return
    end
    if dist <= common.GetAARange(obj) then
      local aa_damage = common.CalculateAADamage(obj)
      if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
        return
      end
    end
    local seg = gpred.circular.get_prediction(w.predinput, obj)
    if seg and seg.startPos:distSqr(seg.endPos) < 1000000 then
      res.obj = obj
      res.dist = dist
      res.seg = seg
      return true
    end
  end)
  if target.seg and w.trace_filter(target) then
    if menu.combo.w.use:get() == 1 then --pull
      w.result = player.pos + (target.obj.pos - player.pos):norm() * (target.dist + 100)
      return w.result
    end
    if menu.combo.w.use:get() == 2 then --push
      w.result = player.pos + (target.obj.pos - player.pos):norm() * (target.dist - 100)
      return w.result
    end
  end
end

w.on_recv_spell = function(spell)
  if w.is_ready() and common.GetPercentPar() >= menu.autos.w.mana_mngr:get() then
    local owner = spell.owner
    if interruptor[owner.charName] and interruptor[owner.charName][spell.name] and not owner.buff["karthusdeathdefiedbuff"] then
      interruptor[owner.charName][spell.name].end_time = os.clock() + 1.5 - network.latency
    end
  end
end

w.on_draw = function()
  if w.slot.level > 0 then
    if menu.draws.w_range:get() then
      graphics.draw_circle(player.pos, w.range, menu.draws.width:get(), menu.draws.w:get(), menu.draws.numpoints:get())
    end
    if menu.draws.w_mode:get() then
      local pos = graphics.world_to_screen(player.pos)
      if menu.combo.w.use:get() == 1 then
        graphics.draw_text_2D("[" .. menu.combo.w.switch.key .. "]Combo W Mode: Pull", 25, pos.x - 95, pos.y + 40, graphics.argb(255, 0, 255, 0))
      end
      if menu.combo.w.use:get() == 2 then
        graphics.draw_text_2D("[" .. menu.combo.w.switch.key .. "]Combo W Mode: Push", 25, pos.x - 95, pos.y + 40, graphics.argb(255, 0, 255, 0))
      end
      if menu.combo.w.use:get() == 3 then
        graphics.draw_text_2D("[" .. menu.combo.w.switch.key .. "]Combo W Mode: Disabled", 25, pos.x - 95, pos.y + 40, graphics.argb(255, 255, 0, 0))
      end
    end
  end
end

return w