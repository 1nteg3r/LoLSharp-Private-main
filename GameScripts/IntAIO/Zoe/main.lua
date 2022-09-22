local orb = module.internal('orb')

local core = module.load(header.id, 'Core/Zoe/core')

orb.combat.register_f_pre_tick(function()
  core.get_action()
end)

cb.add(cb.spell ,function(spell)
  core.process_spell(spell)
end)

--[[cb.add(cb.updatebuff ,function(buff)
  core.update_buff(buff)
end)

cb.add(cb.removebuff ,function(buff)
  core.remove_buff(buff)
end)]]--

cb.add(cb.draw ,function()
  core.on_draw()
end)

cb.add(cb.create_missile,function(missile)
  core.create_mis(missile)
end)


cb.add(cb.delete_particle ,function(obj)
  core.delete_obj(obj)
end)




