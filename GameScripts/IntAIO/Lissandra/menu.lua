local menu = menu("IntnnerLissandra", "Int Lissandra")

menu:header('a1', 'Core')
menu:menu("combo", "Combat Settings")
  menu.combo:menu("q", "Q Settings")
    menu.combo.q:boolean('q', 'Use Ice Shard', true)
    menu.combo.q:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)

  menu.combo:menu("w", "W Settings")
    menu.combo.w:boolean('w', 'Use Ring of Frost', true)
    menu.combo.w:slider('mana_mngr', "Minimum Mana %", 30, 0, 100, 5)

  menu.combo:menu("e", "E Settings")
    menu.combo.e:dropdown('e', 'Use Glacial Path', 2, { 'Always', 'Logic', 'Never' })
    menu.combo.e:slider('mana_mngr', "Minimum Mana %", 0, 0, 100, 5)

  menu.combo:menu("r", "R Settings")
    menu.combo.r:boolean('r', 'Use Frozen Tomb', true)
    menu.combo.r:slider('min_r', 'Minimum enemies in range', 2, 1, 5, 1)
    menu.combo.r:slider('mana_mngr', "Minimum Mana %", 30, 0, 100, 5)
    menu.combo.r:menu("whitelist", "R Whitelist")
    for i = 0, objManager.enemies_n - 1 do
        local enemy = objManager.enemies[i]
        menu.combo.r.whitelist:boolean(enemy.charName, enemy.charName, true)
    end
    menu.combo.r:menu('ONEvONE', 'ONEvONE Settings')
    menu.combo.r.ONEvONE:header('a1', 'This will override minimum enemy check to 1')
    menu.combo.r.ONEvONE:keybind('switch', 'Mode Switch Key', 'K', nil)
    menu.combo.r.ONEvONE.switch:set('callback', function(var)
      if menu.combo.r.ONEvONE.use:get() == 1 and var then
          menu.combo.r.ONEvONE.use:set("value", 2)
          return
      end
      if menu.combo.r.ONEvONE.use:get() == 2 and var then
          menu.combo.r.ONEvONE.use:set("value", 3)
          return
      end
      if menu.combo.r.ONEvONE.use:get() == 3 and var then
          menu.combo.r.ONEvONE.use:set("value", 4)
          return
      end
      if menu.combo.r.ONEvONE.use:get() == 4 and var then
          menu.combo.r.ONEvONE.use:set("value", 1)
          return
      end
    end)
    menu.combo.r.ONEvONE:dropdown('use', 'Usage', 2, { "Always", "Killable", "Min # of Enemies", "Disabled" })
    menu.combo.r.ONEvONE:slider('range_check', "Enemy Range check", 1500, 1000, 2500, 100) 

    menu.combo:menu('items', "Item Settings")
    menu.combo.items:boolean('hourglass', "Use Zhonya's Hourglass", true)
    menu.combo.items:slider('glass_hp', "% Health to use Zhonya's Hourglass", 30, 10, 100, 5)
    menu.combo.items:boolean('seraph', "Use Seraph's Embrace", true)
    menu.combo.items:slider('seraph_hp', "% Health to use Seraph's Embrace", 60, 10, 100, 5)

    menu.combo:header('a2', 'Extra')
    menu.combo:dropdown('path', 'Start Combo with', 1, { 'Q', 'E' })

    menu:menu("harass", "Hybrid Settings")
  menu.harass:menu("q", "Q Settings")
    menu.harass.q:boolean('q', 'Use Ice Shard', true)
    menu.harass.q:slider('mana_mngr', "Minimum Mana %", 30, 0, 100, 5)

menu:menu("clear", "Lane Clear Settings")
  menu.clear:menu("q", "Q Settings")
    menu.clear.q:boolean('q', 'Use Ice Shard', true)
    menu.clear.q:slider('min_q', 'Minimum minions to hit', 2, 1, 5, 1)
    menu.clear.q:slider('mana_mngr', "Minimum Mana %", 30, 0, 100, 5)

  menu.clear:menu("e", "E Settings")
    menu.clear.e:dropdown('e', 'Use Glacial Path', 3, { 'Always', 'Logic', 'Never' })
    menu.clear.e:slider('mana_mngr', "Minimum Mana %", 20, 0, 100, 5)

menu:header('a2', 'Misc.')
  menu:boolean('auto_q', "Auto-W on dash", true)
  menu:boolean('auto_w', "Auto-W Anti-Gapcloser", true)

menu:menu("draws", "Drawings")
  menu.draws:slider('width', "Width/Thickness", 1, 1, 10, 1)
  menu.draws:slider('numpoints', "Numpoints (quality of drawings)", 40, 15, 100, 5)
    menu.draws.numpoints:set('tooltip', "Higher = smoother but more FPS usage")
  menu.draws:boolean('q_range', 'Draw Q Range', true)
  menu.draws:color('q', 'Q Drawing Color', 255, 255, 255, 255)
  menu.draws:boolean('w_range', 'Draw W Range', true)
  menu.draws:color('w', 'W Drawing Color', 255, 255, 255, 255)
  menu.draws:boolean('e_range', 'Draw E Range', true)
  menu.draws:color('e', 'E Drawing Color', 255, 255, 255, 255)
  menu.draws:boolean('r_range', 'Draw R Range', true)
  menu.draws:color('r', 'R Drawing Color', 255, 255, 255, 255)

return menu