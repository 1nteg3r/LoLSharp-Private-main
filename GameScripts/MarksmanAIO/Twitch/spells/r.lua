local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Twitch/menu")
local common = module.load(header.id, "common")

local r = {
  slot = player:spellSlot(3),
  last = 0,
  
  predinput = {
    delay = 0.25,
    radius = 0,
    dashRadius = 0,
    boundingRadiusModSource = 1,
    boundingRadiusModTarget = 1
  }
}

r.is_ready = function()
  return r.slot.state == 0
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
    if dist > 1500 then
      return
    end
    r.predinput.radius = player.attackRange + 300
    if gpred.present.get_prediction(r.predinput, obj) then
      res.in_range = res.in_range and res.in_range + 1 or 1
    end
  end)
  if enemies.in_range and enemies.in_range >= menu.combo.r.min_enemies:get() then
    r.result = enemies.in_range
    return r.result
  end

  return r.result
end

r.on_draw = function()
  if menu.draws.r_range:get() and r.slot.level > 0 then
    graphics.draw_circle(player.pos, (player.attackRange + player.boundingRadius + 300), menu.draws.width:get(), menu.draws.r:get(), menu.draws.numpoints:get())
  end
end

return r