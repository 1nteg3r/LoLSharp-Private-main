local core = module.load(header.id, "Core/Katarina/core")

module.internal("orb").combat.register_f_pre_tick(core.on_tick)
cb.add(cb.draw, core.on_draw)
cb.add(cb.create_minion, core.create_particle)
cb.add(cb.delete_minion, core.delete_particle)
cb.add(cb.create_particle, core.on_create_particle)
cb.add(cb.delete_particle, core.on_delete_particle)
cb.add(cb.spell, core.on_process_spell)