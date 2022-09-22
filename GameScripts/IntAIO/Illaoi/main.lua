local core = module.load(header.id, "Core/Illaoi/core")

module.internal("orb").combat.register_f_pre_tick(core.on_tick)
module.internal("orb").combat.register_f_after_attack(core.AfterAttack)
cb.add(cb.create_particle, core.on_create_obj)
cb.add(cb.delete_particle, core.on_delete_obj)
cb.add(cb.draw, core.on_draw)
cb.add(cb.spell, core.on_process_spell)