local menu = menu("int", "Int Ryze")

menu:header('header_combo', 'Combo Mode')
  menu:dropdown('skill_seq', 'Combo Sequence', 1, { 'Full Damage', 'Burst', 'Safe Mode' })
  menu:boolean('hourglass', "Use Zhonya's", true)
  menu:slider('glass_hp', "Health to use Zhonya's", 30, 10, 100, 10)
  menu:boolean('use_shield', "Use Seraph's Embrace", true)
  menu:slider('seraph_hp', "Health to use Seraph's", 50, 10, 100, 10)
  menu:slider('no_aa', 'No AA after level', 6, 1, 18, 1)
    --menu.no_aa:set('tooltip','Disables auto-attack in combo mode after (x) level.')

menu:header('header_draw', 'Drawings')
  menu:boolean('draw_q_range', 'Draw Q Range', true)
  menu:boolean('draw_w_range', 'Draw W Range', true)
  menu:boolean('draw_e_range', 'Draw E Range', true)
  menu:boolean('draw_r_range', 'Draw R Range', true)

return menu