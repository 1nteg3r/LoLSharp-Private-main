local orb = module.internal("orb")
local core = module.load(header.id, "Addons/Twitch/core")
local menu = module.load(header.id, "Addons/Twitch/menu")
local q = module.load(header.id, "Addons/Twitch/spells/q")
local w = module.load(header.id, "Addons/Twitch/spells/w")
local e = module.load(header.id, "Addons/Twitch/spells/e")
local r = module.load(header.id, "Addons/Twitch/spells/r")

local function on_tick()
  core.get_action()
end
orb.combat.register_f_pre_tick(on_tick)

local function on_recv_spell(spell)
  if spell.owner.ptr == player.ptr then
    core.on_recv_spell(spell)
  end
  if menu.auto.w.on_blink:get() then
    w.on_recv_spell(spell)
  end
end

local function on_lose_vision(obj)
  if menu.auto.e.killable:get() then
    if obj.type == TYPE_HERO and obj.team == TEAM_ENEMY and not obj.isDead then
      e.on_lose_vision(obj)
    end
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