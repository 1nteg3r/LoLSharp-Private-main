local core = module.load(header.id, "Core/Rumble/core")

module.internal("orb").combat.register_f_pre_tick(core.on_tick)
cb.add(cb.draw, core.on_draw)