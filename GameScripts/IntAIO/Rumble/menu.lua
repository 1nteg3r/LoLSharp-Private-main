--[[
    Flamespitter
    Scrap Shield
    Electro Harpoon
    The Equalizer
]]
local menu = menu("IntnnerRumble", "Intnner - Rumble")

menu:set('icon', player.iconCircle)
--core
menu:header("core", "Core - Rumble")
menu:menu("combo", "Combo - Settings")
menu.combo:header("q", "Flamespitter - Q")
menu.combo:boolean("use.q", "Use Q", true)
--W 
menu.combo:header("w", "Scrap Shield - W")
menu.combo:boolean("use.w", "Use W", true)
menu.combo:slider("min.rangeW", "^~ Max. Enemy around {%}", 700, 5, 1000, 5)
menu.combo:boolean("use.only.q", "^~ Only use if Q is active", true)
--E 
menu.combo:header("e", "Electro Harpoon - E")
menu.combo:boolean("use.e", "Use E", true)
--R 
menu.combo:header("r", "The Equalizer - R")
menu.combo:boolean("use.r", "Use R", true)
menu.combo:keybind("SemiR", "Semi - R", "G", false)
menu.combo:boolean("use.rforkill", "Use R if it will kill at least one", true)
menu.combo:boolean("no.use.underTower", "Do not use under tower", true)
menu.combo:slider("min.range", "^~ Max. Range for R {%}", 1650, 5, 1700, 5)
menu.combo:slider("min.enemies.Around", "Min. enemies to use R {%}", 2, 1, 5, 1)
--Harass 
menu:menu('harass', 'Harass/Hybrid - Settings')
menu.harass:header("keyboard", "Keys - Settings")
menu.harass:keybind("toggleAutoE", "Auto E", false, "A")
menu.harass:slider("min.Mana", "Min. Heat Percent {%}", 50, 10, 100, 10)
local valid_menu = function()
    menu.harass['min.Mana']:set("visible", menu.harass["toggleAutoE"]:get())
end 
menu.harass:header("q", "Flamespitter - Q")
menu.harass:boolean("use.q", "Use Q", true)
menu.harass:slider("min.ManaforQ", "^~ Min. Heat Percent {%}", 30, 10, 100, 10)
--W 
menu.harass:header("w", "Scrap Shield - W")
menu.harass:boolean("use.w", "Use W", true)
menu.harass:slider("min.ManaforW", "^~ Min. Heat Percent {%}", 10, 10, 100, 10)
--E 
menu.harass:header("e", "Electro Harpoon - E")
menu.harass:boolean("use.e", "Use E", true)
menu.harass:slider("min.ManaforE", "^~ Min. Heat Percent {%}", 80, 10, 100, 10)
--WaveClear 
--Wave/JungleClear
menu:menu('wave', 'Jungle - Settings')
menu.wave:header("q", "Flamespitter - Q")
menu.wave:boolean("use.q", "Use Q", true)
menu.wave:slider("mana.q", "Min. Heat Percent {%}", 100, 10, 100, 10)
menu.wave:header("e", "Electro Harpoon - E")
menu.wave:boolean("use.e", "Use E", true)
menu.wave:slider("min.e", "Min. Heat Percent {%}", 80, 10, 100, 10)
--Misc 
menu:menu("misc", "Miscellaneous - Settings")
--KillSteal
menu.misc:header("kill", "Killsteal")
menu.misc:menu("Killsteal", "Killsteal - Settings")
menu.misc.Killsteal:boolean("qKill", "Killsteal with Q", true)
menu.misc.Killsteal:boolean("eKill", "Killsteal with E", true)
menu.misc.Killsteal:boolean("rKill", "Killsteal with R", true)
--Draws
menu:menu("draws", "Drawings - Settings")
menu.draws:header("spells", "Spells - Drawings")
menu.draws:boolean("qrange", "Draw Q Range", true)
menu.draws:boolean("wrange", "Draw W Range", true)
menu.draws:boolean("erange", "Draw E Range", true)
menu.draws:boolean("rrange", "Draw R Range", true)
menu.draws:header("colors", "Color - Settings")
menu.draws:color("qcolor", "Q - Drawing Color", 255, 255, 255, 255)
menu.draws:color("wcolor", "W - Drawing Color", 255, 255, 255, 255)
menu.draws:color("ecolor", "E - Drawing Color", 255, 255, 255, 255)
menu.draws:color("rcolor", "R - Drawing Color", 255, 255, 255, 255)
menu.draws:header("orther", "Orther - Settings")
menu.draws:slider("points_n", "Draw points", 40, 1, 100, 1)
menu.draws['points_n']:set("tooltip", "Helps improve FPS")
menu.draws:slider("widthLine", "Width Circle", 2, 1, 5, 1)
menu.draws:boolean("drawtoggles", "Drawings - Toogle", true)

return {
    menu = menu,
    valid_menu = valid_menu
}