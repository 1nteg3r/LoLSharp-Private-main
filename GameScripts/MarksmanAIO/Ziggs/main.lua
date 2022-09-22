local orb = module.internal("orb")
local menu = module.load(header.id, "Addons/Ziggs/menu")
local core = module.load(header.id, "Addons/Ziggs/core")
local q = module.load(header.id, "Addons/Ziggs/spells/q")
local w = module.load(header.id, "Addons/Ziggs/spells/w")
local e = module.load(header.id, "Addons/Ziggs/spells/e")
local r = module.load(header.id, "Addons/Ziggs/spells/r")

local function on_tick()
  core.get_action()
end
orb.combat.register_f_pre_tick(on_tick)

local function on_recv_spell(spell)
  if spell.owner.ptr == player.ptr then
    core.on_recv_spell(spell)
  end
  if spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO then
    if menu.autos.q.onblink:get() then
      q.on_recv_spell(spell)
    end
    if menu.autos.w.interupt:get() then
      w.on_recv_spell(spell)
    end
    if menu.autos.e.onblink:get() then
      e.on_recv_spell(spell)
    end
  end
end

local function on_draw()
  if not player.isDead and player.isOnScreen then
    q.on_draw()
    w.on_draw()
    e.on_draw()
  end
  r.on_draw()
end

cb.add(cb.spell, on_recv_spell)
cb.add(cb.draw, on_draw)

return {}