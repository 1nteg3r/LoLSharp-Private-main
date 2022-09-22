local menu = menu("MarksmanKog", "Marksman - Kog'Maw")

menu:header("a1", "Core")
menu:menu("combo", "Combo Settings")
  menu.combo:menu("q", "Q Settings")
    menu.combo.q:boolean("q", "Use Caustic Spittle", true)
    menu.combo.q:slider("mana_mngr", "Minimum Mana %", 10, 0, 100, 5)

  menu.combo:menu("w", "W Settings")
    menu.combo.w:boolean("w", "Use Bio-Arcane Barrage", true)
    menu.combo.w:slider("mana_mngr", "Minimum Mana %", 5, 0, 100, 5)

  menu.combo:menu("e", "E Settings")
    menu.combo.e:dropdown("use", "Use Void Ooze", 1, { "Out of AA Range", "Always", "Never" })
    menu.combo.e:slider("mana_mngr", "Minimum Mana %", 50, 0, 100, 5)

  menu.combo:menu("r", "R Settings")
    menu.combo.r:boolean("r", "Use Living Artillery", true)
    menu.combo.r:slider("stacks", "Max Stacks", 3, 1, 10, 1)
    menu.combo.r:boolean("cced", "Use on CCed", true)
      menu.combo.r.cced:set("tooltip", "Will only use on enemies with <40% health")
    menu.combo.r:slider("at_hp", "Use only if enemy health is below %", 40, 5, 100, 5)
    menu.combo.r:boolean("in_aa", "Use within AA range", false)

  menu.combo:menu("items", "Item Settings")
    menu.combo.items:boolean("botrk", "Use Cutlass/BotRK", true)
    menu.combo.items:slider("botrk_at_hp", "Cutlass/BotRK if enemy health is below %", 70, 5, 100, 5)

menu:menu("harass", "Hybrid/Harass Settings")
  menu.harass:menu("q", "Q Settings")
    menu.harass.q:boolean("q", "Use Caustic Spittle", true)
    menu.harass.q:slider("mana_mngr", "Minimum Mana %", 30, 0, 100, 5)

  menu.harass:menu("w", "W Settings")
    menu.harass.w:boolean("w", "Use Bio-Arcane Barrage", true)
    menu.harass.w:slider("mana_mngr", "Minimum Mana %", 20, 0, 100, 5)

  menu.harass:menu("e", "E Settings")
    menu.harass.e:dropdown("use", "Use Void Ooze", 3, { "Out of AA Range", "Always", "Never" })
    menu.harass.e:slider("mana_mngr", "Minimum Mana %", 50, 0, 100, 5)

  menu.harass:menu("r", "R Settings")
    menu.harass.r:boolean("r", "Use Living Artillery", true)
    menu.harass.r:slider("stacks", "Max Stacks", 1, 1, 10, 1)
    menu.harass.r:boolean("cced", "Use on CCed", true)
      menu.harass.r.cced:set("tooltip", "Will only use on enemies with <40% health")
    menu.harass.r:slider("at_hp", "Use only if enemy health is below %", 40, 5, 100, 5)
    menu.harass.r:boolean("in_aa", "Use within AA range", false)

menu:menu("clear", "Lane Clear Settings")
  menu.clear:menu("w", "W Settings")
    menu.clear.w:boolean("w", "Use Bio-Arcane Barrage", true)
    menu.clear.w:slider("mana_mngr", "Minimum Mana %", 70, 0, 100, 5)
    menu.clear.w:slider("min_minions", "Minimum minions", 3, 1, 5, 1)

  menu.clear:menu("e", "E Settings")
    menu.clear.e:boolean("e", "Use Void Ooze", false)
    menu.clear.e:slider("mana_mngr", "Minimum Mana %", 70, 0, 100, 5)
    menu.clear.e:slider("min_minions", "Minimum minions to hit", 3, 1, 5, 1)

menu:menu("auto", "Auto Settings")
  menu.auto:menu("p", "Passive Settings")
    menu.auto.p:boolean("use", "Chase Lowest HP Target", true)
    menu.auto.p:slider("dist", "Distance to check within", 750, 100, 1500, 100)

  menu.auto:menu("q", "Q Settings")
    menu.auto.q:boolean("kill", "Q if killable", true)
      menu.auto.q.kill:set("tooltip", "This will override all 'Q settings'")

  menu.auto:menu("r", "R Settings")
    menu.auto.r:boolean("dash", "R on dash", true)
    menu.auto.r:boolean("kill", "R if killable", true)
      menu.auto.r.kill:set("tooltip", "This will override all 'R settings'")

menu:header("xd", "Misc.")
menu:keybind("semi_r", "Semi-Manual R", "T", nil)

menu:menu("draws", "Drawings")
  menu.draws:slider("width", "Width/Thickness", 1, 1, 10, 1)
  menu.draws:slider("numpoints", "Quality of drawings", 40, 15, 100, 5)
    menu.draws.numpoints:set("tooltip", "Higher = smoother but more FPS usage")
  menu.draws:boolean("q_range", "Draw Q Range", true)
  menu.draws:color("q", "Q Drawing Color", 255, 255, 255, 255)
  menu.draws:boolean("w_range", "Draw W Extension Range", true)
  menu.draws:color("w", "W Drawing Color", 255, 255, 255, 255)
  menu.draws:boolean("e_range", "Draw E Range", true)
  menu.draws:color("e", "E Drawing Color", 255, 255, 255, 255)
  menu.draws:boolean("r_range", "Draw R Range", true)
  menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)

return menu