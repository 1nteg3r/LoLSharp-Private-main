local menu = menu("IntnnerOlaf", "Intnner - Olaf")
local t_selector = module.load(header.id, "TargetSelector/targetSelector")

menu:set('icon', player.iconCircle)

local TS = t_selector(menu, 1000, 1)
TS:addToMenu()
--[[
    Undertow
    Vicious Strikes
    Reckless Swing
    Ragnarok
]]
menu:header("core", "Core - Olaf")
--combo 
menu:menu('combo', "Combo - Settings")
menu.combo:header("q", "Undertow - Q")
menu.combo:boolean("use.q", "Use Q", true)
menu.combo:slider("hitChance", "HitChance - Prediction", 3, 1, 4, 1)
    menu.combo['hitChance']:set("tooltip", "1 - Low | 2 - Medium | 3 - High | 4 - Extreme")
menu.combo:slider("min.range", "^~ Max. Range for Q {%}", 925, 5, 1000, 5)
menu.combo:header("w", "Vicious Strikes - W")
menu.combo:boolean("use.w", "Use W", true)
--E 
menu.combo:header("e", "Reckless Swing - E")
menu.combo:boolean("use.e", "Use E", true)
menu.combo:boolean("use.e.affter.Attack", "^~ Only After Attack", true)
--R 
menu.combo:header("r", "Ragnarok - R")
menu.combo:boolean("use.r", "Use R", true)
menu.combo:boolean("use.force", "Force R if myHero have CC buffs", false)
menu.combo:slider("aroundEnemies", "Min. Enemies around {%}", 2, 1, 5, 1)
menu.combo:slider("minRange", "Range Checke {%}", 1000, 10, 1500, 10)
--Harras 
menu:menu('harass', 'Harass/Hybrid - Settings')
menu.harass:header("keyboard", "Keys - Settings")
menu.harass:keybind("toggleAutoQ", "Auto Q", false, "A")
menu.harass:slider("min.Mana", "Min. Mana Percent {%}", 65, 5, 100, 5)
local valid_menu = function()
    menu.harass['min.Mana']:set("visible", menu.harass["toggleAutoQ"]:get())
end 
menu.harass:header("q", "Undertow - Q")
menu.harass:boolean("use.q", "Use Q", true)
menu.harass:slider("hitChance", "HitChance - Prediction", 3, 1, 4, 1)
    menu.harass['hitChance']:set("tooltip", "1 - Low | 2 - Medium | 3 - High | 4 - Extreme")
menu.harass:slider("min.ManaforQ", "Min. Mana Percent {%}", 15, 5, 100, 5)
menu.harass:header("w", "Vicious Strikes - W")
menu.harass:boolean("use.w", "Use W", true)
menu.harass:slider("min.ManaforW", "Min. Mana Percent {%}", 45, 5, 100, 5)
--E 
menu.harass:header("e", "Reckless Swing - E")
menu.harass:boolean("use.e", "Use E", true)
menu.harass:slider("min.health", "Min. Health Percent {%}", 5, 5, 100, 5)
--Wave/JungleClear
menu:menu('wave', 'Wave/Jungle - Settings')
menu.wave:header("q", "Undertow - Q")
menu.wave:boolean("use.q", "Use Q", true)
menu.wave:slider("mana.q", "Min. Mana Percent {%}", 50, 5, 100, 5)
menu.wave:header("w", "Vicious Strikes - W")
menu.wave:boolean("use.w", "Use W", true)
menu.wave:slider("mana.w", "Min. Mana Percent {%}", 15, 5, 100, 5)
menu.wave:header("e", "Reckless Swing - E")
menu.wave:boolean("use.e", "Use E", true)
menu.wave:slider("min.health", "Min. Health Percent {%}", 5, 5, 100, 5)

menu.wave:header("wave", "Wave - Settings")
menu.wave:boolean('wlastHit', 'Use E - LastHit', true)
--Misc 
menu:menu("misc", "Miscellaneous - Settings")
menu.misc:header("aahahd", "Magnet to Axes")
menu.misc:boolean('magnet', 'Magnet-Axes', false)
menu.misc:dropdown("catch", "Move when: ", 2, {"Combo", "Always"})
menu.misc:header("man", "Magnet to Target")
menu.misc:boolean('magnetTarget', 'Magnet-Target', true)
menu.misc:slider("distance.magnet", "Min. Distance for Magnet {%}", 500, 5, 900, 5)
menu.misc:header('focus', 'Target', true)
menu.misc:boolean('focusTarget', 'Focus Target - In AA Range', true)
--KillSteal
menu.misc:header("kill", "Killsteal")
menu.misc:menu("Killsteal", "Killsteal - Settings")
menu.misc.Killsteal:boolean("qKill", "Killsteal with Q", true)
menu.misc.Killsteal:boolean("wKill", "Killsteal with E", true)
--Item 
menu.misc:header("item", "Item")
menu.misc:boolean("Item", "Use Goredrinker", true)
--Evade 
menu.misc:header("ecvade", "Evade")
menu.misc:boolean("disableEvade", "Disable Evade in combo", true)
menu.misc:boolean("onlyR", "^~ Only with R active", true)

--Draws
menu:menu("draws", "Drawings - Settings")
menu.draws:header("spells", "Spells - Drawings")
menu.draws:boolean("qrange", "Draw Q Range", true)
menu.draws:boolean("erange", "Draw E Range", true)
menu.draws:header("dagger", "Axes - Drawings")
menu.draws:boolean("daggerCircle", "Draw Circle Range", true)
menu.draws:boolean("daggerTime", "Draw Time", true)
menu.draws:slider("widthDagger", "^~ Width Text", 20, 1, 35, 1)
menu.draws:header("colors", "Color - Settings")
menu.draws:color("qcolor", "Q - Drawing Color", 255, 255, 255, 255)
menu.draws:color("ecolor", "E - Drawing Color", 255, 255, 255, 255)
menu.draws:header("orther", "Orther - Settings")
menu.draws:slider("points_n", "Draw points", 40, 1, 100, 1)
menu.draws['points_n']:set("tooltip", "Helps improve FPS")
menu.draws:slider("widthLine", "Width Circle", 2, 1, 5, 1)
menu.draws:boolean("drawtoggles", "Drawings - Toogle", true)
return {
    menu = menu, 
    TS = TS, 
    valid_menu = valid_menu
}