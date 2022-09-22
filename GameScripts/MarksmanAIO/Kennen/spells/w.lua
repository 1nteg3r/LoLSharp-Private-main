local orb = module.internal("orb")
local menu = module.load(header.id, "Addons/Kennen/menu")

local w = {
  slot = player:spellSlot(1),
  last = 0,
  range = 775,
  marked = {},
}

w.is_ready = function()
  return w.slot.state == 0
end

w.get_action_state = function()
  if w.is_ready() then
    return w.get_prediction()
  end
end

w.invoke_action = function()
  player:castSpell("self", 1)
  orb.core.set_server_pause()
end

w.get_prediction = function()
  if w.last == game.time then
    return w.result
  end
  w.last = game.time
  w.result = nil
  
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if enemy and not enemy.isDead and enemy.isVisible and enemy.isTargetable then
      if player.path.serverPos:distSqr(enemy.path.serverPos) <= (w.range * w.range) then
        if ((orb.combat.is_active() and menu.combo_w:get() == 2) or (orb.menu.hybrid:get() and menu.harass_w:get() == 2)) then
          if enemy.buff["kennenmarkofstorm"] and enemy.buff["kennenmarkofstorm"].stacks == 2 then
            w.result = enemy
            break
          end
        end
        if ((orb.combat.is_active() and menu.combo_w:get() == 3) or (orb.menu.hybrid:get() and menu.harass_w:get() == 3)) then
          w.result = enemy
          break
        end
      end
    end
  end

  return w.result
end

w.on_draw = function()
  if menu.draw_w_range:get() and w.slot.level > 0 then
    graphics.draw_circle(player.pos, w.range, 1, graphics.argb(255, 255, 255, 255), 50)
  end
end

return w