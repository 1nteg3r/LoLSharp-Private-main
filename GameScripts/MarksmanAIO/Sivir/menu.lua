local menu = menu(header.id, "Marksman - Sivir")

menu:header('header_combo', 'Combo Mode')
  menu:boolean('combo_q', 'Use Q', true)
  menu:slider('min_mana_cq', 'Minimum Mana to use Q', 30, 0, 100, 5)
  menu:boolean('combo_w', 'Use W', true)
  menu:boolean('combo_botrk', 'Use Cutlass/BotRK', true)
  menu:slider('botrk_at_hp', 'Use if enemy health is below %', 70, 5, 100, 5)

menu:header('header_harass', 'Hybrid/Harass Mode')
  menu:boolean('harass_q', 'Use Q', true)
  menu:slider('min_mana_hq', 'Minimum Mana to use Q', 20, 0, 100, 5)

menu:header('header_clear', 'Lane Clear Mode')
  menu:boolean('clear_w', 'Use W', true)
  menu:slider('min_mana_clw', 'Minimum Mana to use W', 20, 0, 100, 5)
  menu:slider('min_minions', 'Minimum Minions', 5, 1, 30, 1)

menu:header('header_misc', 'Misc.')
  menu:boolean('auto_e', 'Auto E', true)
    menu.auto_e:set('tooltip', "BETA")

menu:header('header_draw', 'Drawings')
  menu:boolean('draw_q_range', 'Draw Q Range', true)
  menu:boolean('draw_r_range', 'Draw R Range', true)

return menu