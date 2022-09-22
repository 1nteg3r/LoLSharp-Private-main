local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Twitch/menu")
local common = module.load(header.id, "common")

local e = {
  slot = player:spellSlot(2),
  last = 0,
  
  predinput = {
    delay = 0.25,
    radius = 1200,
    dashRadius = 0,
    boundingRadiusModSource = 0,
    boundingRadiusModTarget = 0
  }
}

e.is_ready = function()
  return e.slot.state == 0
end

local press_the_attack_scale = { 0.08, 0.08, 0.08, 0.09, 0.09, 0.09, 0.09, 0.10, 0.10, 0.10, 0.10, 0.11, 0.11, 0.11, 0.11, 0.12, 0.12, 0.12 }
e.get_damage = function(target)
  local base_damage = 10 + (10 * e.slot.level)
  local stack_damage = (10 + (5 * e.slot.level)) + (common.GetBonusAD() * 0.25) + (common.GetTotalAP() * 0.2)
  local bonus_damage = stack_damage * target.buff["twitchdeadlyvenom"].stacks2
  local total = base_damage + bonus_damage
  
  if target.buff["assets/perks/styles/precision/pressthreeattacks/pressthreeattacksdamageamp.lua"] then --press the attack
    total = total * (1 + press_the_attack_scale[player.levelRef])
  end
  if menu.coupe:get() then
    if common.GetPercentHealth(target) < 40 then --coupe de grace
      total = total * 1.07
    end
  end
  
  return total
end

e.get_multiplier = function(target)
  local multiplier = 1
  
  --increased damage
  if target.buff["vladimirhemoplaguedebuff"] then
    multiplier = multiplier * 1.10
  end
  
  --decreased damage
  if player.buff["summonerexhaust"] then
    multiplier = multiplier * 0.6
  end
  if player.buff["itemphantomdancerdebuff"] then
    multiplier = multiplier * 0.88
  end
  if player.buff["itemsmitechallenge"] then
    multiplier = multiplier * 0.8
  end
  if target.buff["ferocioushowl"] then
    multiplier = multiplier * (0.55 - (target:spellSlot(3).level * 0.1))
  end
  if target.buff["garenw"] then --first 0.75 seconds reduces 60%
    multiplier = multiplier * 0.7
  end
  if target.buff["gragaswself"] then
    multiplier = multiplier * (0.92 - (target:spellSlot(1).level * 0.02))
  end
  if target.buff["galiorallybuff"] then
    multiplier = multiplier * ((0.85 - (target:spellSlot(3).level * 0.05)) - (0.08 * (target.bonusSpellBlock / 100)))
  end
  if target.buff["moltenshield"] then
    multiplier = multiplier * (0.90 - (target:spellSlot(2).level * 0.06))
  end
  if target.buff["meditate"] then
    multiplier = multiplier * (0.55 - (target:spellSlot(1).level * 0.05))
  end
  if target.buff["sonapassivedebuff"] then
    multiplier = multiplier * (0.75 - (0.04 * (common.GetTotalAP(target) / 100)))
  end
  if target.buff["malzaharpassiveshield"] then
    multiplier = multiplier * 0.1
  end
  if target.buff["warwicke"] then
    multiplier = multiplier * (0.70 - (target:spellSlot(2).level * 0.05))
  end
  if target.buff["ireliawdefense"] then
    multiplier = multiplier * ((0.60 - (target:spellSlot(1).level * 0.05)) - (0.07 * (common.GetTotalAP(target) / 100)))
  end
  
  return multiplier
end

e.invoke_action = function()
  player:castSpell("self", 2)
  local target = orb.combat.target
  if target and not target.isDead and target.isTargetable and target.isVisible then
    if player.path.serverPos:dist(target.path.serverPos) <= common.GetAARange(target) then
      orb.core.set_server_pause()
      player:attack(target)
    end
  end
  orb.core.set_server_pause()
end

e.invoke__jungle_steal = function()
  for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
    local monster = objManager.minions[TEAM_NEUTRAL][i]
    if monster and not monster.isDead and monster.isVisible and monster.buff["twitchdeadlyvenom"] then
      local dist_to_mob = player.path.serverPos:distSqr(monster.path.serverPos)
      if dist_to_mob <= (e.predinput.radius * e.predinput.radius) and (menu.auto.e.jungle.whitelist[monster.charName] or monster.charName:find("SRU_Dragon_")) then
        if (menu.auto.e.jungle.whitelist.dragon:get() and monster.charName:find("SRU_Dragon_")) or menu.auto.e.jungle.whitelist[monster.charName]:get() then
          local damage = monster.charName ~= "SRU_Red" and common.CalculatePhysicalDamage(monster, e.get_damage(monster)) or e.get_damage(monster)
          if damage > monster.health then
            player:castSpell("self", 2)
            orb.core.set_server_pause()
            return true
          end
        end
      end
    end
  end
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result
  end
  e.last = game.time
  e.result = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if (
      dist > 2000 or 
      not obj.buff["twitchdeadlyvenom"] or 
      obj.buff["bansheesveil"] or 
      obj.buff["itemmagekillerveil"] or 
      obj.buff["fioraw"] or 
      obj.buff["nocturneshroudofdarkness"] or 
      obj.buff["sivire"]
    ) then
      return
    end
    if gpred.present.get_prediction(e.predinput, obj) then
      local damage = common.CalculatePhysicalDamage(obj, e.get_damage(obj)) * e.get_multiplier(obj)
      if obj.charName == "Amumu" and obj.buff["tantrum"] then
        damage = damage - (2 * obj:spellSlot(2).level)
      end
      if damage > common.GetShieldedHealth("AD", obj) then
        res.obj = obj
        return true
      end
      if menu.auto.e.max_stacks:get() and obj.buff["twitchdeadlyvenom"].stacks2 == 6 then
        res.obj = obj
        return true
      end
    end
  end).obj
  if target then
    e.result = target
    return e.result
  end

  return e.result
end

e.get_prediction_after_aa = function()
  e.result_after_aa = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if (
      dist > 2000 or 
      not obj.buff["twitchdeadlyvenom"] or  
      obj.buff["bansheesveil"] or 
      obj.buff["itemmagekillerveil"] or 
      obj.buff["fioraw"] or 
      obj.buff["nocturneshroudofdarkness"] or 
      obj.buff["sivire"]
    ) then
      return
    end
    if gpred.present.get_prediction(e.predinput, obj) then
      local ad_reduction_multiplier = e.get_multiplier(obj) 
      local aa_dmg = common.CalculateAADamage(obj) * ad_reduction_multiplier
      local e_damage = common.CalculatePhysicalDamage(obj, e.get_damage(obj)) * ad_reduction_multiplier
      if obj.charName == "Fizz" then
        aa_dmg = ((common.GetTotalAD() - (4 + math.floor((obj.levelRef - 1) / 3) * 2)) * common.PhysicalReduction(obj)) * ad_reduction_multiplier
      end
      for i = 0, 5 do --Ninja Tabi check
        local id = obj:itemID(i)
        if id and id == 3047 then
          aa_dmg = aa_dmg - (aa_dmg * 0.12)
        end
      end
      if obj.charName == "Braum" and obj.buff["braumshieldraise"] then
        aa_dmg = aa_dmg * (0.725 - (obj:spellSlot(2).level * 0.025))
      end
      if obj.charName == "Amumu" and obj.buff["tantrum"] then
        e_damage = e_damage - (2 * obj:spellSlot(2).level)
        aa_dmg = aa_dmg - (2 * obj:spellSlot(2).level)
      end
      if (e_damage + aa_dmg) > common.GetShieldedHealth("AD", obj) and dist < common.GetAARange() then
        res.obj = obj
        return true
      end
    end
  end).obj
  if target then
    e.result = target
    return e.result
  end
  
  return e.result_after_aa
end

e.on_lose_vision = function(obj)
  if e.is_ready() then
    if (
      player.path.serverPos:distSqr(obj.path.serverPos) > 2250000 or 
      not obj.buff["twitchdeadlyvenom"] or 
      obj.buff["bansheesveil"] or 
      obj.buff["itemmagekillerveil"] or 
      obj.buff["fioraw"] or 
      obj.buff["nocturneshroudofdarkness"] or 
      obj.buff["sivire"]
    ) then
      return
    end
    local damage = common.CalculatePhysicalDamage(obj, e.get_damage(obj)) * e.get_multiplier(obj)
    if obj.charName == "Amumu" and obj.buff["tantrum"] then
      damage = damage - (2 * obj:spellSlot(2).level)
    end
    if damage > (common.GetShieldedHealth("AD", obj) + ((obj.healthRegenRate * e.predinput.delay) * 2)) then
      player:castSpell("self", 2)
      orb.core.set_server_pause()
    end
  end
end

e.on_draw = function()
  if menu.draws.e_range:get() and e.slot.level > 0 then
    graphics.draw_circle(player.pos, e.predinput.radius, menu.draws.width:get(), menu.draws.e:get(), menu.draws.numpoints:get())
  end
  if menu.draws.e2_range:get() then 
    for i=0, objManager.enemies_n-1 do
      local target = objManager.enemies[i]
      if target and target.buff['twitchdeadlyvenom'] then 
        local pos = graphics.world_to_screen(target.pos)
		if (math.floor((e.get_damage(target)) / target.health * 100) < 100) then
			graphics.draw_line_2D(pos.x, pos.y - 30, pos.x + 30, pos.y - 80, 1, graphics.argb(255, 255, 153, 51))
			graphics.draw_line_2D(pos.x + 30, pos.y - 80, pos.x + 50, pos.y - 80, 1, graphics.argb(255, 255, 153, 51))
			graphics.draw_line_2D(pos.x + 50, pos.y - 85, pos.x + 50, pos.y - 75, 1, graphics.argb(255, 255, 153, 51))

			graphics.draw_text_2D(
				tostring(math.floor((e.get_damage(target)))) ..
					" (" ..
						tostring(math.floor((e.get_damage(target)) / target.health * 100)) ..
							"%)" .. "Not Killable",
				20,
				pos.x + 55,
				pos.y - 80,
				graphics.argb(255, 255, 153, 51)
			)
		end
		if (math.floor((e.get_damage(target)) / target.health * 100) >= 100) then
			graphics.draw_line_2D(pos.x, pos.y - 30, pos.x + 30, pos.y - 80, 1, graphics.argb(255, 150, 255, 200))
			graphics.draw_line_2D(pos.x + 30, pos.y - 80, pos.x + 50, pos.y - 80, 1, graphics.argb(255, 150, 255, 200))
			graphics.draw_line_2D(pos.x + 50, pos.y - 85, pos.x + 50, pos.y - 75, 1, graphics.argb(255, 150, 255, 200))
			graphics.draw_text_2D(
				tostring(math.floor((e.get_damage(target)))) ..
					" (" ..
						tostring(math.floor((e.get_damage(target)) / target.health * 100)) ..
							"%)" .. "Kilable",
				20,
				pos.x + 55,
				pos.y - 80,
				graphics.argb(255, 150, 255, 200)
			)
		end
      end
    end
  end
end

return e