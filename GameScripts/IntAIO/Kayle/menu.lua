local menu = menu("intnnerkayle", "Int - Kayle")

menu:header('a1', 'Core')
menu:menu("combo", "Combo Settings")
  menu.combo:menu("q", "Q Settings")
    menu.combo.q:dropdown('use', 'Use Radiant Blast', 1, { 'Out of AA Range', 'Always', 'Never' })
    menu.combo.q:slider('mana_mngr', "Minimum Mana %", 20, 0, 100, 5)
    
  menu.combo:menu("w", "W Settings")
    menu.combo.w:boolean('use', 'Use Celestial Blessing', true)
      menu.combo.w.use:set('tooltip', "Used after AA if target leaves AA range.")
    menu.combo.w:slider('mana_mngr', "Minimum Mana %", 30, 0, 100, 5)

  menu.combo:menu("e", "E Settings")
    menu.combo.e:boolean('use', 'Use Starfire Spellblade', true)
    menu.combo.e:slider('mana_mngr', "Minimum Mana %", 0, 0, 100, 5)

  menu.combo:menu('items', "Item Settings")
    menu.combo.items:boolean('botrk', 'Use Cutlass/BotRK', true)
    menu.combo.items:slider('botrk_at_hp', 'Cutlass/BotRK if enemy health is below %', 70, 5, 100, 5)
    menu.combo.items:boolean('gunblade', 'Use Hextech Gunblade', true)
    menu.combo.items:slider('gunblade_at_hp', 'Gunblade if enemy health is below %', 70, 5, 100, 5)

menu:menu("harass", "Hybrid/Harass Settings")
  menu.harass:menu("q", "Q Settings")
    menu.harass.q:boolean('use', 'Use Radiant Blast', true)
    menu.harass.q:slider('mana_mngr', "Minimum Mana %", 30, 0, 100, 5)

  menu.harass:menu("e", "E Settings")
    menu.harass.e:boolean('use', 'Use Starfire Spellblade', true)
    menu.harass.e:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)

menu:menu("autos", "Auto Settings")
  menu.autos:menu("q", "[Q] Anti-Gapcloser Settings")
    menu.autos.q:boolean('use', 'Use Radiant Blast', true)
    menu.autos.q:header('a1', 'Enemies to use on')
      for i = 0, objManager.enemies_n - 1 do
        local enemy = objManager.enemies[i]
        menu.autos.q:boolean(enemy.charName, enemy.charName, true)
      end

  menu.autos:menu("w", "W Settings")
    menu.autos.w:boolean('use', 'Use Celestial Blessing', true)
    menu.autos.w:slider('health', "Minimum Health %", 30, 5, 100, 5)
    menu.autos.w:boolean('flee', 'Use for Flee/Escape', true)

  menu.autos:menu("r", "R Settings")
    menu.autos.r:boolean('use', 'Use Divine Judgment', true)
    menu.autos.r:slider('health', "Minimum Health %", 10, 5, 100, 5)
    menu.autos.r:slider('enemies', "Minimum Enemies Near", 1, 0, 5, 1)

menu:header('a1', 'Misc.')
  menu:keybind('flee', 'Flee/Escape Key', 'T', nil)

menu:menu("draws", "Drawings")
  menu.draws:slider('width', "Width/Thickness", 1, 1, 10, 1)
  menu.draws:slider('numpoints', "Numpoints (quality of drawings)", 40, 15, 100, 5)
    menu.draws.numpoints:set('tooltip', "Higher = smoother but more FPS usage")
  menu.draws:boolean('q_range', 'Draw Q Range', true)
  menu.draws:color('q', 'Q Drawing Color', 255, 255, 255, 255)
  menu.draws:boolean('e_range', 'Draw E Extension Range', true)
  menu.draws:color('e', 'E Drawing Color', 50, 255, 255, 255)

return menu