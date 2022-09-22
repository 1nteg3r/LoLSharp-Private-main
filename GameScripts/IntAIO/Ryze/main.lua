local orb = module.internal("orb");
local menu = module.load("int", "Core/Ryze/menu")
local core = module.load("int", "Core/Ryze/core")
local q = module.load("int", "Core/Ryze/spells/q")
local w = module.load("int", "Core/Ryze/spells/w")
local e = module.load("int", "Core/Ryze/spells/e")
local r = module.load("int", "Core/Ryze/spells/r")

local function on_tick()
  if menu.skill_seq:get() == 1 then
    menu.skill_seq:set('tooltip', "Q E Q W")
  end
  if menu.skill_seq:get() == 2 then
    menu.skill_seq:set('tooltip', 'Q W Q E')
  end
  if menu.skill_seq:get() == 3 then
    menu.skill_seq:set('tooltip', "E W Q")
  end
  
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