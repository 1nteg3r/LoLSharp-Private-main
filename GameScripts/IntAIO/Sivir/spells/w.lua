local orb = module.load("int", "Orbwalking/Orb");
local menu = module.load("int", "Core/Sivir/menu")

local w = {
  slot = player:spellSlot(1),
  last = 0,
}

w.is_ready = function()
  return w.slot.state == 0
end

w.invoke_action = function()
  player:castSpell("self", 1)
  orb.core.set_server_pause()
end

w.invoke__lane_clear = function()
  local minions_in_range = {}
  local minions = objManager.minions
  for i = 0, minions.size[TEAM_ENEMY] - 1 do
    local minion = minions[TEAM_ENEMY][i]
    if minion and not minion.isDead and minion.isVisible then
      local distSqr = player.path.serverPos:distSqr(minion.path.serverPos)
      if distSqr <= (1000 * 1000) then
        minions_in_range[#minions_in_range + 1] = minion
      end
    end
    if #minions_in_range == menu.min_minions:get() then
      w.invoke_action()
      break
    end
  end
end

return w