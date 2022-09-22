local menu = menu(header.id, "Marksman - Teemo")

menu:header("header_combo", "Combo Mode")
  menu:dropdown("cq", "Use Q", 2, { "Smart", "Always", "Never" })
  menu:boolean("combo_w", "Use W", true)
  menu:boolean("combo_r", "Use R", true)
  menu:slider("min_r", "[R] Minimum charges", 2, 1, 3, 1)
  menu:menu("items", "Item Settings")
    menu.items:boolean("botrk", "Use Cutlass/BotRK", true)
    menu.items:slider("botrk_hp", "Use if enemy health is below %", 70, 10, 100, 10)
    menu.items:boolean("gunblade", "Use Hextech Gunblade", true)
    menu.items:slider("gunblade_hp", "Use if enemy health is below %", 70, 10, 100, 10)

menu:header("header_harass", "Hybrid/Harass Mode")
  menu:boolean("harass_q", "Use Q", true)
  menu:boolean("harass_w", "Use W", true)

menu:header("misc", "Misc.")
  menu:boolean("disable_evade", "Disable Evade while invisible", true)
  menu:menu("blacklist", "Q Whitelist")
    for i = 0, objManager.enemies_n - 1 do
      local enemy = objManager.enemies[i]
      menu.blacklist:boolean(enemy.charName, enemy.charName, true)
    end
  menu:boolean("aa_first", "Only Q after AA", true)
  menu:boolean("auto_r", "Auto-R Shroom Spots", true)
    menu.auto_r:set("tooltip", "Used on preset spots. Only available in Summoner's Rift!")
  menu:slider("min_autor", "[Auto-R] Minimum charges", 2, 1, 3, 1)

menu:menu("draws", "Drawings")
  menu.draws:boolean("aa_range", "Satanic AA-Range", false)
  menu.draws:dropdown("q_range", "Draw Q Range", 2, { "Off", "Normal", "Satanic" })
  menu.draws:dropdown("r_range", "Draw R Range", 2, { "Off", "Normal", "Satanic" })
  menu.draws:dropdown("r_spots", "Draw Shroom Spots", 2, { "Off", "Normal", "Satanic" })
    menu.draws.r_spots:set("tooltip", "Only available in Summoner's Rift!")

return menu