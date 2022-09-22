local orb = module.internal("orb")
local core = module.load(header.id, "Core/Kayle/core")
local q = module.load(header.id, "Core/Kayle/spells/q")
local w = module.load(header.id, "Core/Kayle/spells/w")
local e = module.load(header.id, "Core/Kayle/spells/e")
local r = module.load(header.id, "Core/Kayle/spells/r")

local function on_tick()
  core.get_action()
end
orb.combat.register_f_pre_tick(on_tick)

local lastDebugPrint = 0
local function on_recv_spell(spell)
  if spell.owner.ptr == player.ptr then
    core.on_recv_spell(spell)
  end
end

local function on_draw()
  if player.isOnScreen then
    q.on_draw()
    e.on_draw()
    r.on_draw()
  end
end

cb.add(cb.spell, on_recv_spell)
cb.add(cb.draw, on_draw)


return {}