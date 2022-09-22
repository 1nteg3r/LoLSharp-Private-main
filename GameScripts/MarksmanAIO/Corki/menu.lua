local menu = menu("MarksmanAIOCorki", "Marksman - Corki")

menu:header("qh", "Q Settings")
  menu:boolean("use_q", "Use Phosphorus Bomb", true)
  menu:boolean("q_on_cc", "Use on CC", true)
  menu:slider("q_mana_mngr", "Minimum Mana %", 10, 0, 100, 5)
  menu:boolean("q_ks", "Auto if killable", true)
    menu.q_ks:set("tooltip", "This will override all settings")

  menu:header("wh", "W Settings")
    menu:boolean("use_w", "Use Valkyrie", true)
    menu:boolean("w_killsteal", "Use Only KillSteal", true)
    menu:slider("w_mana_mngr", "Minimum Mana %", 35, 0, 100, 5)

menu:header("eh", "E Settings")
  menu:boolean("use_e", "Use Gatling Gun", true)

menu:header("rh", "R Settings")
  menu:keybind("semi_r", "Semi-Manual Key", "T", nil)
  menu:boolean("use_r", "Use Missile Barrage", true)
  menu:slider("r_mana_mngr", "Minimum Rockets", 1, 0, 7, 1)
  menu:boolean("r_ks", "Auto if killable", true)
    menu.r_ks:set("tooltip", "This will override all settings")

menu:header("dh", "Draw Settings")
  menu:slider("width", "Width/Thickness", 1, 1, 10, 1)
  menu:slider("numpoints", "Numpoints (quality of drawings)", 40, 15, 100, 5)
    menu.numpoints:set("tooltip", "Higher = smoother but more FPS usage")
  menu:boolean("q_range", "Draw Q Range", true)
  menu:color("q", "Q Drawing Color", 255, 255, 255, 255)
  menu:boolean("w_range", "Draw W Range", false)
  menu:color("w", "W Drawing Color", 255, 255, 255, 255)
  menu:boolean("r_range", "Draw R Range", true)
  menu:color("r", "R Drawing Color", 255, 255, 255, 255)

return menu