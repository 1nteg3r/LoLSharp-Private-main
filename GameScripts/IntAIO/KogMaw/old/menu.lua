local menu = menu("dasdasdasas", "Int Kog'Maw")

menu:header("a1", "Core")
menu:menu("combo", "Combat")
  menu.combo:menu("q", "Q Settings")
    menu.combo.q:boolean("q", "Use Q", true)

  menu.combo:menu("w", "W Settings")
    menu.combo.w:boolean("w", "Use W", true)
  

  menu.combo:menu("e", "E Settings")
  menu.combo.e:boolean("e", "Use E", true)
    menu.combo.e:dropdown("use", "Mode E:", 1, { "Out of AA Range", "Always", "Never" })

  menu.combo:menu("r", "R Settings")
    menu.combo.r:boolean("r", "Use R", true)
    menu.combo.r:slider("stacks", "Max. Stacks", 2, 1, 10, 1)
    menu.combo.r:boolean("cced", "Use R in CC", true)
    menu.combo.r:slider("at_hp", "Use only if enemy health", 40, 5, 100, 5)
    menu.combo.r:boolean("in_aa", "Use R only AA range", false)
    menu.combo.r:keybind("semi_r", "Manual R", "T", nil)



menu:menu("harass", "Harass")
  menu.harass:menu("q", "Q Settings")
    menu.harass.q:boolean("q", "Use Q", true)

  menu.harass:menu("w", "W Settings")
    menu.harass.w:boolean("w", "Use W", true)

  menu.harass:menu("e", "E Settings")
    menu.harass.e:dropdown("use", "Mode E:", 1, { "Out of AA Range", "Always", "Never" })

  menu.harass:menu("r", "R Settings")
    menu.harass.r:boolean("r", "Use Living Artillery", true)
    menu.harass.r:slider("stacks", "Max Stacks", 1, 1, 10, 1)
    menu.harass.r:boolean("cced", "Use on CCed", true)
      menu.harass.r.cced:set("tooltip", "Will only use on enemies with <40% health")
    menu.harass.r:slider("at_hp", "Use only if enemy health is below %", 40, 5, 100, 5)
    menu.harass.r:boolean("in_aa", "Use within AA range", false)

menu:menu("clear", "Clear/Jungle")
  menu.clear:menu("w", "W Settings")
    menu.clear.w:boolean("w", "Use W", true)
    menu.clear.w:slider("mana_mngr", "Min. Mana {0}", 70, 0, 100, 5)
    menu.clear.w:slider("min_minions", "Min. Mobs", 3, 1, 5, 1)

  menu.clear:menu("e", "E Settings")
    menu.clear.e:boolean("e", "Use E", false)
    menu.clear.e:slider("mana_mngr", "Min. Mana {0}", 70, 0, 100, 5)
    menu.clear.e:slider("min_minions", "Min. Mobs hit", 3, 1, 5, 1)

menu:menu("auto", "Misc")
  menu.auto:menu("p", "Passive")
    menu.auto.p:boolean("use", "Chase Lowest HP", true)
    menu.auto.p:slider("dist", "Distance to >=", 750, 100, 1500, 100)

  menu.auto:menu("q", "Q Settings")
    menu.auto.q:boolean("kill", "Q if killable", true)

  menu.auto:menu("r", "R Settings")
    menu.auto.r:boolean("dash", "R on dash", true)
    menu.auto.r:boolean("kill", "R if killable", true)

menu:menu("draws", "Display")
  menu.draws:boolean("q_range", "Q Range", true)
  menu.draws:boolean("w_range", "W Range", true)
  menu.draws:boolean("e_range", "E Range", true)
  menu.draws:boolean("r_range", "R Range", true)


return menu