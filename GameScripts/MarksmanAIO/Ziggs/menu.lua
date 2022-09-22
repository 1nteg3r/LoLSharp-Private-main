local orb = module.internal("orb")
local menu = menu(header.id, "Marksman - Ziggs")

menu:header('a1', 'Core')
menu:menu('combo', 'Combo Settings')
  menu.combo:menu('q', 'Q Settings')
    menu.combo.q:boolean('use', 'Use Bouncing Bomb', true)
    menu.combo.q:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)

  menu.combo:menu('w', 'W Settings')
    menu.combo.w:keybind('switch', 'Mode Switch Key', 'Y', nil)
    menu.combo.w.switch:set('callback', function(var) 
      if menu.combo.w.use:get() == 1 and var then
        menu.combo.w.use:set("value", 2)
        return
      end
      if menu.combo.w.use:get() == 2 and var then
        menu.combo.w.use:set("value", 3)
        return
      end
      if menu.combo.w.use:get() == 3 and var then
        menu.combo.w.use:set("value", 1)
        return
      end
    end)
    menu.combo.w:dropdown('use', 'Use Satchel Charge', 1, { "Pull", "Push", "Disabled" })
    menu.combo.w:slider('mana_mngr', "Minimum Mana %", 25, 0, 100, 5)

  menu.combo:menu('e', 'E Settings')
    menu.combo.e:boolean('use', 'Use Hexplosive Minefield', true)
    menu.combo.e:slider('min_enemies', "Minimum enemies to hit", 2, 1, 5, 1)
    menu.combo.e:slider('mana_mngr', "Minimum Mana %", 40, 0, 100, 5)

  menu.combo:menu('r', 'R Settings')
    menu.combo.r:keybind('switch', 'Mode Switch Key', 'K', nil)
    menu.combo.r.switch:set('callback', function(var)
      if menu.combo.r.use:get() == 1 and var then
        menu.combo.r.use:set("value", 2)
        return
      end
      if menu.combo.r.use:get() == 2 and var then
        menu.combo.r.use:set("value", 3)
        return
      end
      if menu.combo.r.use:get() == 3 and var then
        menu.combo.r.use:set("value", 4)
        return
      end
      if menu.combo.r.use:get() == 4 and var then
        menu.combo.r.use:set("value", 1)
        return
      end
    end)
    menu.combo.r:dropdown("use", "Use Mega Inferno Bomb", 2, { "Always", "Killable", "Min # of Enemies", "Disabled" })
    menu.combo.r:slider('min_enemies', "Minimum # of enemies to hit", 2, 1, 5, 1)
    menu.combo.r:slider('range', "Maximum range to check within", 3000, 100, 5300, 100)
    menu.combo.r:slider('mana_mngr', "Minimum Mana %", 20, 0, 100, 5)

menu:menu('harass', 'Harass Settings')
  menu.harass:menu('q', 'Q Settings')
    menu.harass.q:header('hq', "Set first as orbwalker hybrid key")
    menu.harass.q:header('hq', "Set second to use 'Auto Harass Q'")
    menu.harass.q:keybind('use', 'Use Bouncing Bomb', 'C', 'G')
    menu.harass.q:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)

  menu.harass:menu('e', 'E Settings')
    menu.harass.e:boolean('use', 'Use Hexplosive Minefield', false)
    menu.harass.e:slider('min_enemies', "Minimum enemies to hit", 2, 1, 5, 1)
    menu.harass.e:slider('mana_mngr', "Minimum Mana %", 60, 0, 100, 5)

menu:menu('clear', 'Lane/Jungle Clear Settings')
  menu.clear:menu('q', 'Q Settings')
    menu.clear.q:dropdown("mode", "Use Bouncing Bomb", 3, { "Lane Clear", "Jungle Clear", "Both", "Disabled" })
    menu.clear.q:slider('mana_mngr', "Minimum Mana %", 25, 0, 100, 5)

  menu.clear:menu('w', 'W Settings')
    menu.clear.w:boolean('use', 'Use to demolish turret', true)
    menu.clear.w:slider('mana_mngr', "Minimum Mana %", 15, 0, 100, 5)

  menu.clear:menu('e', 'E Settings')
    menu.clear.e:dropdown("mode", "Use Hexplosive Minefield", 3, { "Lane Clear", "Jungle Clear", "Both", "Disabled" })
    menu.clear.e:slider('min_minions', "Minimum # of minions to hit", 5, 1, 10, 1)
      menu.clear.e.min_minions:set("tooltip", "Jungle Clear ignores this")
    menu.clear.e:slider('mana_mngr', "Minimum Mana %", 25, 0, 100, 5)

menu:menu('autos', 'Auto Settings')
  menu.autos:menu('q', 'Q Settings')
    menu.autos.q:boolean('ondash', 'Use on dash', true)
    menu.autos.q:boolean('onblink', 'Use on blink', true)
    menu.autos.q:boolean('ks', 'Use to killsteal', true)
    menu.autos.q:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)

  menu.autos:menu('w', 'W Settings')
    menu.autos.w:boolean('interupt', 'Use to interupt spells', true)
    menu.autos.w:boolean('flee', 'Use in Flee', true)
    menu.autos.w:slider('mana_mngr', "Minimum Mana %", 10, 0, 100, 5)

  menu.autos:menu('e', 'E Settings')
    menu.autos.e:boolean('ondash', 'Use on dash', true)
    menu.autos.e:boolean('onblink', 'Use on blink', true)
    menu.autos.e:slider('mana_mngr', "Minimum Mana %", 40, 0, 100, 5)

menu:header('a1', 'Misc.')
menu:keybind('flee', 'Flee Key', 'Z', nil)

menu:menu("draws", "Drawings")
  menu.draws:slider("width", "Width/Thickness", 1, 1, 10, 1)
  menu.draws:slider("numpoints", "Numpoints (quality of drawings)", 40, 15, 100, 5)
    menu.draws.numpoints:set("tooltip", "Higher = smoother but more FPS usage")
  menu.draws:boolean("q_range", "Draw Q Range", true)
  menu.draws:color("q", "Q Drawing Color", 255, 255, 255, 255)
  menu.draws:boolean("w_range", "Draw W Range", true)
  menu.draws:color("w", "W Drawing Color", 255, 255, 255, 255)
  menu.draws:boolean("e_range", "Draw E Range", true)
  menu.draws:color("e", "E Drawing Color", 255, 255, 255, 255)
  menu.draws:boolean("r_range", "Draw R Range on minimap", true)
  menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)
  menu.draws:header('a1', 'Other')
  menu.draws:boolean("w_mode", "Draw Combo W Mode", true)
  menu.draws:boolean("r_mode", "Draw Combo R Mode", true)
  menu.draws:boolean("q_status", "Draw Auto Harass Q Status", true)

return menu