local core = module.load(header.id, "Core/Darius/core")

module.internal("orb").combat.register_f_pre_tick(core.on_tick)
cb.add(cb.draw, core.on_draw)
cb.add(cb.sprite, core.on_draw_sprite)
cb.add(cb.spell, core.on_process_spell)