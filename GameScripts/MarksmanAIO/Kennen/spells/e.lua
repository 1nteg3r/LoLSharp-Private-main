local orb = module.internal("orb")
local menu = module.load(header.id, "Addons/Kennen/menu")
local common = module.load(header.id, "common");

local e = {
  slot = player:spellSlot(2),
}

e.is_ready = function()
  return e.slot.state == 0
end

e.invoke_action = function()
  player:castSpell("self", 2)
  orb.core.set_server_pause()
end

return e