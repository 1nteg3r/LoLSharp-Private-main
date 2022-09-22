local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Core/Kayle/menu")
local common = module.load(header.id, "Library/common");

local e = {
  slot = player:spellSlot(2),
  last = 0,
  
  predinput = {
    delay = 0.25,
    radius = 525,
    dashRadius = 0,
    boundingRadiusModSource = 1,
    boundingRadiusModTarget = 1,
  }
}

e.is_ready = function()
  return e.slot.state == 0
end

e.invoke_action = function()
  player:castSpell("self", 2)
  orb.core.set_server_pause()
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result
  end
  e.last = game.time
  e.result = nil
  
  local target = ts.get_result(function(res, obj, dist) --add invulnverabilty check
    if dist < 1000 then
      res.obj = obj
      return true
    end
  end).obj
  if target and gpred.present.get_prediction(e.predinput, target) then
    e.result = target
    return e.result
  end
  
  return e.result
end

e.on_draw = function()
  if menu.draws.e_range:get() and e.slot.level > 0 then
    graphics.draw_circle(player.pos, (e.predinput.radius + 65), menu.draws.width:get(), menu.draws.e:get(), menu.draws.numpoints:get())
  end
end

return e