local orb = module.internal("orb")
local menu = module.load(header.id, "Addons/Teemo/menu")
local core = module.load(header.id, "Addons/Teemo/core")
local q = module.load(header.id, "Addons/Teemo/spells/q")
local w = module.load(header.id, "Addons/Teemo/spells/w")
local e = module.load(header.id, "Addons/Teemo/spells/e")
local r = module.load(header.id, "Addons/Teemo/spells/r")

local function orb_on_tick()
  core.get_action()
end
orb.combat.register_f_pre_tick(orb_on_tick)

local function on_recv_spell(spell)
  if spell.owner.ptr == player.ptr then
    core.on_recv_spell(spell)
  end
end

local function on_create_obj(obj)
  r.on_create_obj(obj)
end

local function on_delete_obj(obj)
  r.on_delete_obj(obj)
end

local function on_draw()
  if player.isOnScreen then
    if menu.draws.aa_range:get() then
      local pos = {}
      local range = common.GetAARange()
      for i = 0, 4 do
        local theta = i * 2 * math.pi / 5 + os.clock()
        pos[i] = vec3(player.x + range * math.sin(theta), player.y, player.z + range * math.cos(theta))
      end
      for i = 0, 4 do
        graphics.draw_line(pos[i], pos[i > 2 and i - 3 or i + 2], 3, 0xFFFF0000)
      end
      graphics.draw_circle(player.pos, range, 4, 0xFFFF0000, 128)
    end
    q.on_draw()
    r.on_draw()
  end
end

cb.add(cb.spell, on_recv_spell)
cb.add(cb.create_particle, on_create_obj)
cb.add(cb.delete_particle, on_delete_obj)
cb.add(cb.draw, on_draw)

return {}