local cc_spells = module.load("int", "Core/Morgana/cc_spells")
local menu = menu("intmorgana", "Int Morgana")

menu:menu("combo", "Combo")
  menu.combo:menu("q", "Q Settings")
    menu.combo.q:boolean('use', 'Use Q', true)
    --menu.combo.q:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)
	
  menu.combo:menu("w", "W Settings")
    menu.combo.w:boolean('use', 'Use W', true)
    --menu.combo.w:slider('mana_mngr', "Minimum Mana %", 20, 0, 100, 5)
	
  menu.combo:menu("r", "R Settings")
    menu.combo.r:boolean('use', 'Use R', true)
    menu.combo.r:slider('min_enemies', "Minimum Enemies to R", 2, 1, 5, 1)
    --menu.combo.r:slider('mana_mngr', "Minimum Mana %", 30, 0, 100, 5)


menu:menu("harass", "Harass")
  menu.harass:menu("q", "Q Settings")
    menu.harass.q:boolean('use', 'Use Q', true)
	
  menu.harass:menu("w", "W Settings")
    menu.harass.w:boolean('use', 'Use W', true)

menu:boolean('auto_w', 'Auto W on CCed', true)
menu:menu("q_blacklist", "Q Whitelist")
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    menu.q_blacklist:boolean(enemy.charName, enemy.charName, true)
  end
menu:menu('e', "Auto E Settings")
  menu.e:boolean('use', 'Use Black Shield', true)
  menu.e:slider('mana_mngr', "Minimum Mana %", 5, 0, 100, 5)
  menu.e:menu("blacklist", "Ally Whitelist")
    for i = 0, objManager.allies_n - 1 do
      local ally = objManager.allies[i]
      menu.e.blacklist:boolean(ally.charName, ally.charName, true)
    end
  menu.e:menu("spell_list", "Spells to E")
    for i = 0, objManager.enemies_n - 1 do
      local enemy = objManager.enemies[i]
      if cc_spells[enemy.charName] then
        menu.e.spell_list:menu(enemy.charName, enemy.charName)
        for i = 0, 3 do
          local slot = cc_spells[enemy.charName][i]
          if menu.e.spell_list[enemy.charName] and slot then
            menu.e.spell_list[enemy.charName]:boolean(slot, slot, true)
          end
        end
      end
    end

menu:menu("draws", "Drawings")
  menu.draws:boolean('q_range', 'Draw Q Range', true)
  menu.draws:boolean('w_range', 'Draw W Range', true)
  menu.draws:boolean('e_range', 'Draw E Range', true)
  menu.draws:boolean('r_range', 'Draw R Range', true)

return menu