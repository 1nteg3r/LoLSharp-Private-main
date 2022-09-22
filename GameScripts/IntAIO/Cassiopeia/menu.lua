

local menu = menu("dasdsadsaas", "Int Cassiopeia")

menu:header('a1', 'Core')
menu:menu("combo", "Combat")
  menu.combo:menu("q", "Q Settings")
    menu.combo.q:boolean('q', 'Use Q', true)

  menu.combo:menu("w", "W Settings")
    menu.combo.w:boolean('w', 'Use W', true)
    menu.combo.w:boolean('dddw', 'Use Smart W', true)

  menu.combo:menu("e", "E Settings")
    menu.combo.e:dropdown('e', 'Use E', 2, { 'Always', 'Buff Poisoned', 'Never' })

  menu.combo:menu("r", "R Settings")
    menu.combo.r:boolean('r', 'Use R', true)
    menu.combo.r:slider('min_r', 'Min. Enemies to stun (is facing)', 2, 1, 5, 1)
    menu.combo.r:menu("whitelist", "R Whitelist")
      for i = 0, objManager.enemies_n - 1 do
        local enemy = objManager.enemies[i]
        menu.combo.r.whitelist:boolean(enemy.charName, enemy.charName, true)
      end
    menu.combo.r:menu('ONEvONE', 'Over')
      menu.combo.r.ONEvONE:dropdown('use', 'Usage', 3, { 'Always', 'Stun', 'Killable', 'Never' })
      menu.combo.r.ONEvONE:slider('range_check', "Enemy Range check", 1500, 1000, 2500, 100) 

  menu.combo:header('a2', 'Bonus')
  menu.combo:dropdown('path', 'Start Combo with', 2, { 'Q', 'W' })
  menu.combo:slider('no_aa', 'Disable AA after level', 6, 1, 18, 1)
    --menu.combo.no_aa:set('tooltip','Disables auto-attack after (x) level.')

menu:menu("harass", "Harass")
  menu.harass:menu("q", "Q Settings")
    menu.harass.q:boolean('q', 'Use Q', true)

  menu.harass:menu("w", "W Settings")
    menu.harass.w:boolean('w', 'Use W', false)

  menu.harass:menu("e", "E Settings")
    menu.harass.e:dropdown('e', 'Use E', 2, { 'Always', 'Buff Poisoned', 'Never' })

menu:menu("clear", "Clear/Jungle")
  menu.clear:menu("q", "Q Settings")
    menu.clear.q:boolean('q', 'Use Q', true)
    menu.clear.q:slider('min_q', 'Min. minions to hit', 2, 1, 5, 1)

  menu.clear:menu("e", "E Settings")
  menu.clear.e:boolean('lasthit_e', 'Last hit minions  E', true)
    menu.clear.e:dropdown('e', 'Use E', 3, { 'Always', 'Buff Poisoned', 'Never' })

menu:header('a2', 'Misc')
  menu:boolean('auto_q', "Auto Q if dash", true)
  menu:boolean('no_qw', "No Q or W on poisoned", true)
    --menu.no_qw:set('tooltip', "Does not cast Q or W if target is already poisoned.")
  menu:boolean('auto_w', "Auto W / Gapcloser", true)
  menu:boolean('sera', 'Use item Seraphs Embrace', true)
  menu:boolean('zhoyah', 'Use item Zhonyas', true)

   -- menu.lasthit_e:set('tooltip', "Disables AA for Farm and Lane Clear mode only.")

menu:menu("draws", "Display")
    --menu.draws.numpoints:set('tooltip', "Higher = smoother but more FPS usage")
  menu.draws:boolean('q_range', 'Q Range', true)
  menu.draws:boolean('w_range', 'W Range', true)
    --menu.draws.w_range:set('tooltip', "min range = red         max range = blue")
  menu.draws:boolean('e_range', 'E Range', true)
  menu.draws:boolean('r_range', 'R Range', true)


return menu