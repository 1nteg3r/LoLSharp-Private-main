local orb = module.internal("orb")
local evade = module.seek("evade")
local menu = module.load(header.id, "Addons/Sivir/menu")
local core = module.load(header.id, "Addons/Sivir/core")
local q = module.load(header.id, "Addons/Sivir/spells/q")
local w = module.load(header.id, "Addons/Sivir/spells/w")
local e = module.load(header.id, "Addons/Sivir/spells/e")
local r = module.load(header.id, "Addons/Sivir/spells/r")

local function orb_on_tick()
  core.get_action()
end
orb.combat.register_f_pre_tick(orb_on_tick)

local function on_recv_spell(spell)
  if spell.owner.ptr == player.ptr then
    core.on_recv_spell(spell)
  end
  if not evade and menu.auto_e:get() then
    if spell.owner.team == TEAM_ENEMY then
      e.on_recv_spell(spell)
    end
  end
end

local function on_draw()
  if player.isOnScreen then
    q.on_draw()
    r.on_draw()
  end
end

cb.add(cb.spell, on_recv_spell)
cb.add(cb.draw, on_draw)

print("Avada Sivir loaded")

return {}