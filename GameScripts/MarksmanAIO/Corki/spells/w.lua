local menu = module.load(header.id, "Addons/Corki/menu")
local common = module.load(header.id, "common")
local r = module.load(header.id, "Addons/Corki/spells/r")
local ts = module.internal("TS")

local w = {
  slot = player:spellSlot(1),
  range = 600,
}

w.is_ready = function()
  return w.slot.state == 0
end

w.invoke_killsteal = function()
  if player.buff["corkiloadedspeed"] or player.buff["corkiloadedsound"] then
    w.range = 1800
  else
    w.range = 600
  end

  local target = ts.get_result(function(res, obj, dist)
    if dist < common.GetAARange(obj) or dist > 1800 then
      return
    end
    if menu.w_killsteal:get() and (r.get_damage(obj) * 2 or common.CalculateAADamage(obj)) > common.GetShieldedHealth("ALL", obj) then
        res.obj = obj
        return true
    elseif dist > common.GetAARange(obj) then 
      res.obj = obj
      return true
    end 
  end)
  if target.obj then 
    player:castSpell("pos", 1, target.obj.pos)
  end 
end 

w.get_action_state = function()
  if w.is_ready() then
    return w.invoke_killsteal()
  end
end

w.on_draw = function()
  if menu.w_range:get() and w.slot.level > 0 then
    if player.buff["corkiloadedspeed"] or player.buff["corkiloadedsound"] then
      w.range = 1800
    else
      w.range = 600
    end
    graphics.draw_circle(player.pos, w.range, menu.width:get(), menu.w:get(), menu.numpoints:get())
  end
end

return w