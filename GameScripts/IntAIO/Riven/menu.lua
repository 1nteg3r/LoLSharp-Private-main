local menu = menu('IntnnerRiven', 'Int Riven')

menu:header('header_combat', 'Combo Riven')
menu:keybind('e_aa', 'Burting -> Combo', nil, 'T')
menu:keybind('r1', 'Use R1 Always', nil, 'G')
menu:keybind('flee', 'Flee key', 'Z', nil)
menu:keybind('combat', 'Combo key', 'Space', nil)
menu:header('header_combat', 'Combo - Settings')
menu:boolean('useEinCombo', 'Use E - Combat', true)

menu:header('header_push', 'Lane/Jungle')
menu:boolean('push_q', 'Use Q', true)
menu:boolean('push_w', 'Use W', true)
menu:boolean('push_e', 'Use E', true)
menu:keybind('push', 'Lane/Jungle key', 'V', nil)

menu:header('header_flash', 'Flash Burst')
menu:boolean('flash', 'Flash combo -> Selected target', true)
menu:boolean('reset_ts', 'Use next target to leave combo', true)
menu:boolean('flash_only_r', 'Use only combos', false)

menu:header('header_gap', 'Combo Bonus')
menu:boolean('gap_e_w', 'AA Reset Timer', true)
menu:boolean('gap_e_q', 'E > Q for Burst Combo', true)
menu:boolean('gap_e_aa', 'E > AA when Q in CD', true)
menu:boolean('gap_q', 'Smart Q', true)

return menu