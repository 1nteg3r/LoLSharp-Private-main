--kart
local menu = menu("MarksmanAIOKaisa", "Marksman - Kai'Sa")

menu:header("q", "[Q] Icathian Rain")
menu:boolean('autoQ', 'Auto Q', true)
  menu.autoQ:set('tooltip', 'Only Isolated Target')
menu:dropdown('combo_q', 'Use Q when:', 2, { 'Isolated Target', 'Always', 'Never' })
menu:dropdown('c_q', 'Use in Combo', 1, { 'Always', 'After AA', 'Never' })
  menu.c_q:set('tooltip', 'atm will only be used if no minion in range')

menu:header("w", "[W] Void Seeker")
menu:dropdown('combo_w', 'Use in Combo', 1, { 'Only on CC', 'Always', 'Never' })
  menu.combo_w:set('tooltip', "'Only on CC' ignores stack check")
menu:slider('combo_w_slider', "[Combo] Maximum range to check", 1000, 500, 2500, 100)
menu:keybind('semiW', 'Semi-W', 'G', nil)
menu:slider('w_stacks', "Minimum stacks", 3, 0, 4, 1)
menu:boolean('ks_w', 'Use to Killsteal', true)
  menu.ks_w:set('tooltip', "Ignores stack check")
menu:slider('ks_w_slider', "[Killsteal] Maximum range to check", 2000, 500, 2500, 100)

menu:header("flee", "Flee Settings")
menu:keybind('flee_key', 'Key', 'T', nil)
menu:boolean('flee_e', 'Use E', true)

return menu