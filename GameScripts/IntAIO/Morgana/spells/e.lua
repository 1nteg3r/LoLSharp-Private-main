local orb = module.internal("orb");
local evade = module.seek("evade")
local menu = module.load("int", "Core/Morgana/menu")
local common = module.load("int", "Library/common")
local cc_spells = module.load("int", "Core/Morgana/cc_spells")

local e = {
  slot = player:spellSlot(2),
  last = 0,
  range = 800,
  delay = 0.51525002717972,
}

e.is_ready = function()
  return e.slot.state == 0
end

e.invoke_action = function()
  player:castSpell("obj", 2, e.result)
  orb.core.set_server_pause()
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result
  end
  e.last = game.time
  e.result = nil

  for _, spell in pairs(evade.core.active_spells) do
    if type(spell) == "table" then
      local owner = spell.owner
      if cc_spells[owner.charName] then
        local slot = cc_spells[owner.charName][spell.data.slot]
        if slot and menu.e.spell_list[owner.charName][slot]:get() then
          for i = 0, objManager.allies_n - 1 do
            local ally = objManager.allies[i]
            if menu.e.blacklist[ally.charName]:get() and not ally.isDead and ally.isVisible then
              local dist_to_ally = player.path.serverPos:distSqr(ally.path.serverPos)
              if dist_to_ally < (e.range * e.range) then
                if spell.missile and spell.missile.speed then
                  if (spell.target and spell.target.ptr == ally.ptr) or (spell.polygon and spell.polygon:Contains(ally.path.serverPos)) then
                    local hit_time = (ally.path.serverPos:dist(spell.missile.pos) - ally.boundingRadius) / spell.missile.speed
                    if hit_time > (e.delay + network.latency) and hit_time < (e.delay + 0.25 + network.latency) then
                      e.result = ally
                      return e.result
                    end
                  end
                else
                  if spell.target and spell.target.ptr == ally.ptr then
                    e.result = ally
                    return e.result
                  end
                end
              end
            end
          end
        end
      end
    end
  end
    
  return e.result
end

e.on_recv_spell = function(spell)
  if e.is_ready() and common.GetPercentPar() >= menu.e.mana_mngr:get() then
    local owner = spell.owner
    if cc_spells[owner.charName] then
      local slot = cc_spells[owner.charName][spell.slot]
      if slot and menu.e.spell_list[owner.charName][slot]:get() then
        for i = 0, objManager.allies_n - 1 do
          local ally = objManager.allies[i]
          if menu.e.blacklist[ally.charName]:get() and not ally.isDead and ally.isVisible then
            local dist_to_ally = player.path.serverPos:distSqr(ally.path.serverPos)
            if dist_to_ally < (e.range * e.range) then
              local dist_to_spell = spell.endPos and ally.path.serverPos:distSqr(spell.endPos) or nil
              if (spell.target and spell.target.ptr == ally.ptr) or (dist_to_spell and dist_to_spell <= (666 * 666)) then
                player:castSpell("obj", 2, ally)
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

e.on_draw = function()
  if menu.draws.e_range:get() and e.slot.level > 0 then
    graphics.draw_circle(player.pos, e.range, 1, graphics.argb(255, 255, 255, 255), 50)
  end
end

return e