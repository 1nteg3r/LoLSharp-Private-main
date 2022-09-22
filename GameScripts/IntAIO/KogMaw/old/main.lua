local orb = module.internal("orb")
local core = module.load("int", "KogMaw/core")
local q = module.load("int", "KogMaw/spells/q")
local w = module.load("int", "KogMaw/spells/w")
local e = module.load("int", "KogMaw/spells/e")
local r = module.load("int", "KogMaw/spells/r")

local function on_tick()
  core.get_action()
end
orb.combat.register_f_pre_tick(on_tick)

local function on_recv_spell(spell)
  if spell.owner.ptr == player.ptr then
    core.on_recv_spell(spell)
  end
end


local function on_draw()
  if player.isOnScreen then
    q.on_draw()
    w.on_draw()
    e.on_draw()
    r.on_draw()
  end
end

cb.add(cb.spell, on_recv_spell)
cb.add(cb.draw, on_draw)

return {}