local menu = menu("MarksmanAIOTristana", "Marksman - Tristana")

menu:header('a1', 'Core')
menu:menu('combo', 'Combo Settings')
  menu.combo:menu('q', 'Q Settings')
    menu.combo.q:boolean('use', 'Use Rapid Fire', true)
    menu.combo.q:slider('x_aa', "Don't use if x AA can kill", 2, 0, 10, 1)
      menu.combo.q.x_aa:set('tooltip', '0 = ignore AA check')

  menu.combo:menu('e', 'E Settings')
    menu.combo.e:boolean('use', 'Use Explosive Charge', true)
    menu.combo.e:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)
    menu.combo.e:slider('x_aa', "Don't use if x AA can kill", 1, 0, 10, 1)
      menu.combo.e.x_aa:set('tooltip', '0 = ignore AA check')
    menu.combo.e:menu("whitelist", "Whitelist")
      for i = 0, objManager.enemies_n - 1 do
        local enemy = objManager.enemies[i]
        if enemy then 
           menu.combo.e.whitelist:boolean(enemy.charName, enemy.charName, true)
        end
      end

  menu.combo:menu('r', 'R Settings')
    menu.combo.r:boolean('use', 'Use Buster Shot (if killable)', true)
    menu.combo.r:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)
    menu.combo.r:slider('x_aa', "Don't use if x AA can kill", 3, 0, 10, 1)
      menu.combo.r.x_aa:set('tooltip', '0 = ignore AA check')
  
menu:menu('harass', 'Hybrid/Harass Settings')
  menu.harass:menu('q', 'Q Settings')
    menu.harass.q:boolean('use', 'Use Rapid Fire', true)

  menu.harass:menu('e', 'E Settings')
    menu.harass.e:boolean('use', 'Use Explosive Charge', true)
    menu.harass.e:slider('mana_mngr', "Minimum Mana %", 20, 0, 100, 5)

menu:header('a2', 'Misc.')
  menu:boolean('e_focus', 'Focus E Target', true)
  menu:boolean('r_kill', 'Auto-R if killable', true)
  menu:keybind("semir", "Semi - R", 'T', nil)
  menu:menu("whitelist", "Auto-R Anti-Gapcloser Whitelist")
    for i = 0, objManager.enemies_n - 1 do
      local enemy = objManager.enemies[i]
      if enemy then 
        menu.whitelist:boolean(enemy.charName, enemy.charName, true)
      end
    end
  menu:dropdown('eq_tower', 'EQ Tower', 2, { 'Killable', 'Always', 'Never' })
    menu.eq_tower:set('tooltip', "Q will not be used unless the tower has E")


return menu