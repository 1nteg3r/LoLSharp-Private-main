local core = module.load(header.id, "Core/Gangplank/core")

module.internal("orb").combat.register_f_pre_tick(core.on_tick)
cb.add(cb.draw, core.on_draw)
cb.add(cb.create_minion, core.create_barriel)
cb.add(cb.delete_minion, core.delete_barriel)