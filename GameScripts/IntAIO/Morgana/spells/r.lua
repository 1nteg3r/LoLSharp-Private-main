local orb = module.internal("orb");
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "Core/Morgana/menu")
local common = module.load("int", "Library/common")

local r = {
  slot = player:spellSlot(3),
  last = 0,
  
  predinput = {
    source = player,
    delay = 0.34999999403954,
    radius = 625, --625 Cast Range, 1050 Tether range
    dashRadius = 0,
    boundingRadiusModSource = 0,
    boundingRadiusModTarget = 0,
  }
}

r.is_ready = function()
  return r.slot.state == 0
end

r.get_action_state = function()
  if r.is_ready() and common.GetPercentPar() >= 10 then
    return r.get_prediction()
  end
end

r.invoke_action = function()
  player:castSpell("self", 3)
  orb.core.set_server_pause()
end

r.get_prediction = function()
  if r.last == game.time then
    return r.result
  end
  r.last = game.time
  r.result = nil

  local enemies = ts.loop(function(res, obj, dist)
    if dist < r.predinput.radius then
      if gpred.present.get_prediction(r.predinput, obj) then
        res.num_hits = res.num_hits and res.num_hits + 1 or 1
      end
    end
  end)
  if enemies.num_hits and enemies.num_hits >= menu.combo.r.min_enemies:get() then
    r.result = enemies.num_hits
    return r.result
  end
  
  return r.result
end

r.on_draw = function()
	if menu.draws.r_range:get() and r.slot.level > 0 then
	  graphics.draw_circle(player.pos, r.predinput.radius, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

return r