
local menu = menu("IntnnerKennen", "Int Kennen")

menu:header('header_combo', 'Combo Mode')
menu:boolean('combo_q', 'Use Q', true)
menu:dropdown('combo_w', 'Use W', 2, { 'Never', 'Stun', 'Always' })
menu:boolean('combo_r', 'Use R', true)
menu:slider('min_r', "[R] Minimum Enemies to hit", 2, 1, 5, 1)
menu:boolean('hourglass', "Use Zhonya's Hourglass", true)
menu:slider('glass_hp', "% Health to use Zhonya's Hourglass", 30, 5, 100, 5)

menu:header('header_harass', 'Harass Mode')
menu:boolean('harass_q', 'Use Q', true)
menu:dropdown('harass_w', 'Use W', 2, { 'Never', 'Stun', 'Always' })

menu:header('header_flee', 'Flee Mode')
menu:keybind('flee_key', 'Flee/Escape Key', 'T', nil)
menu:boolean('flee_e', 'Use E', true)

menu:header('header_draw', 'Drawings')
menu:boolean('draw_q_range', 'Draw Q Range', true)
menu:boolean('draw_w_range', 'Draw W Range', true)
menu:boolean('draw_r_range', 'Draw R Range', true)
return menu