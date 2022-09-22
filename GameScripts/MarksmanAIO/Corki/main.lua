local orb = module.internal("orb")
local core = module.load(header.id, "Addons/Corki/core")
local q = module.load(header.id, "Addons/Corki/spells/q")
local w = module.load(header.id, "Addons/Corki/spells/w")
local e = module.load(header.id, "Addons/Corki/spells/e")
local r = module.load(header.id, "Addons/Corki/spells/r")

local function on_tick()
  core.get_action()
end
orb.combat.register_f_pre_tick(on_tick)

local function on_recv_spell(spell)
  if spell.owner.ptr == player.ptr then
    core.on_recv_spell(spell)
  end
end

local function on_recv_path(obj)
  if obj.ptr == player.ptr and obj.path.isDashing then
    core.on_recv_self_dash()
  end
end

local function on_draw()
  if not player.isDead and player.isOnScreen then
    q.on_draw()
    w.on_draw()
    r.on_draw()
  end
end

cb.add(cb.spell, on_recv_spell)
cb.add(cb.path, on_recv_path)
cb.add(cb.draw, on_draw)

return {}