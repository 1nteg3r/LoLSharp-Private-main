local orb = module.internal("orb")
local menu = module.load(header.id, "Core/Kayle/menu")
local evade = module.seek('evade');
local common = module.load(header.id, "Library/common");

local r = {
  slot = player:spellSlot(3),
  last = 0,
  range = 900,
}

r.is_ready = function()
  return r.slot.state == 0
end

r.get_action_state = function()
  if r.is_ready() then
    return r.get_prediction()
  end
end

r.inove_evade_save = function()
  for i=evade.core.targeted.n, 1, -1 do
    local spell = evade.core.targeted[i]
    if spell and spell.owner.team == TEAM_ENEMY  and spell.target.ptr == player.ptr then 
        local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
        if player:spellSlot(3).state == 0 then 
            if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                player:castSpell("obj", 3, player)
            end 

            if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                player:castSpell("obj", 3, player)
            end
        end
    end
end 

for i=evade.core.skillshots.n, 1, -1 do
    local spell = evade.core.skillshots[i]
    if spell.missile and spell.missile.speed then
      if spell and spell.owner.team == TEAM_ENEMY and spell:contains(player) then 
          local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
          if player:spellSlot(3).state == 0 then 
              local hit_time = (player.path.serverPos:dist(spell.missile.pos) - player.boundingRadius) / spell.missile.speed
              if hit_time > (network.latency) and hit_time < (0.25 + network.latency) then 
              if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                  player:castSpell("obj", 3, player)
              end 

              if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                  player:castSpell("obj", 3, player)
              end
            end
          end
        end
    end
  end 
end 
r.invoke_action = function()
  player:castSpell("obj", 3, r.result)
  orb.core.set_server_pause()
end

r.get_prediction = function()
  if r.last == game.time then
    return r.result
  end
  r.last = game.time
  r.result = nil
  
  local enemies_in_range = 0
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if enemy and not enemy.isDead and player.path.serverPos:distSqr(enemy.path.serverPos) <= (1000 * 1000) then
        enemies_in_range = enemies_in_range + 1
    end
    if enemies_in_range == menu.autos.r.enemies:get() then
      r.result = player
      break
    end
  end

  return r.result
end

r.on_draw = function()
  if r.slot.level > 0 and player.buff["kayler"] then
    local buffTime = player.buff["kayler"].startTime
    local factor = (game.time - (({ 2, 2.5, 3 })[r.slot.level] + buffTime)) - network.latency
    graphics.draw_circle(player.pos, (300 * factor), menu.draws.width:get(), graphics.argb(255, 255, 0, 0), menu.draws.numpoints:get())
  end
end

return r