local orb = module.internal("orb")
local ts = module.internal("TS")
local menu = module.load(header.id, "Addons/Tristana/menu")
local common = module.load(header.id, "common")
local e = {
  slot = player:spellSlot(2),
  last = 0,
  turrets = {},
}

e.is_ready = function()
  return e.slot.state == 0
end

e.get_action_state = function()
  if e.is_ready() then
    return e.get_prediction()
  end
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
  
  local target = ts.get_result(function(res, obj, dist)
    if menu.combo.e.whitelist[obj.charName] and not menu.combo.e.whitelist[obj.charName]:get() then
      return
    end
    if dist <= common.GetAARange(obj) then
      if (common.CalculateAADamage(obj) * menu.combo.e.x_aa:get()) > common.GetShieldedHealth("AD", obj) then
        return
      else
        res.obj = obj
        return true
      end
    end
  end)
  if target.obj then
    e.result = target.obj
    return e.result
  end

  return e.result
end

return e