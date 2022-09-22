local menu = menu("IntnnerIllaoi", "Intnner - Illaoi")
local t_selector = module.load(header.id, "TargetSelector/targetSelector")

menu:set('icon', player.iconCircle)

local TS = t_selector(menu, 950, 1)
TS:addToMenu()

menu:header("core", "Core - Illaoi")
--combo 
menu:menu("combo", "Combo - Settings")
--Q 
menu.combo:header("q", "Tentacle Smash - Q")
menu.combo:boolean("use.q", "Use Q", true)
menu.combo:boolean("use.q.pred.low", "Use Slow Prediction", true)
menu.combo:slider("max.q.range", "^~ Max. Range Q", 750, 5, 800, 5)
--W 
menu.combo:header("w", "Harsh Lesson - W")
menu.combo:boolean("use.w", "Use W", true)
menu.combo:boolean("use.only", "^~ Use only if Tentacle is nearby", false)
menu.combo:boolean("use.aa.reset", "^~ Use for reset Auto Attack", true)
--E 
menu.combo:header("e", "Test of Spirit - E")
menu.combo:boolean("use.e", "Use E", true)
menu.combo:boolean("use.e.pred.low", "Use Slow Prediction", true)
menu.combo:slider("max.e.range", "^~ Max. Range E", 900, 5, 950, 5)
--R 
menu.combo:header("r", "Leap of Faith - R")
menu.combo:boolean("use.r", "Use R", true)
menu.combo:slider("use.around.enemies", "^~ Min. Enemies Around {%}", 2, 1, 5, 1)
menu.combo:boolean("force.r", "Force R if my health is low", true)
menu.combo:header("healh", "Health - Settings")
menu.combo:slider("healthMy", "Min. Health Percent {%}", 35, 5, 100, 5)
local valid_menu = function()
    menu.combo.healh:set("visible", menu.combo['force.r']:get())
    menu.combo.healthMy:set("visible", menu.combo['force.r']:get())
end 
--harass 
menu:menu("harass", "Harass/Hybrid - Settings")
--Q 
menu.harass:header("q", "Tentacle Smash - Q")
menu.harass:boolean("use.q", "Use Q", true)
menu.harass:slider("max.q.range", "^~ Max. Range Q", 750, 5, 800, 5)
menu.harass:slider("percentMana.q", "Min. Percent Mana {%}", 25, 0, 100, 5)
--W 
menu.harass:header("w", "Harsh Lesson - W")
menu.harass:boolean("use.w", "Use W", false)
menu.harass:slider("percentMana.w", "Min. Percent Mana {%}", 0, 0, 100, 5)
--E 
menu.harass:header("e", "Test of Spirit - E")
menu.harass:boolean("use.e", "Use E", false)
menu.harass:slider("max.e.range", "^~ Max. Range E", 900, 5, 950, 5)
menu.harass:slider("percentMana.e", "Min. Percent Mana {%}", 45, 0, 100, 5)
--wave 
menu:menu("wave", "WaveClear - Settings")
menu.wave:header("q", "Tentacle Smash - Q")
menu.wave:boolean("use.q", "Use Q", true)
menu.wave:slider("use.q.around", "^~ Min. Minion Around {%}", 3, 1, 10, 1)
menu.wave:slider("chance", "Hits chance to hit an enemy in lane {%}", 45, 5, 100, 5)
menu.wave:header("w", "Harsh Lesson - W")
menu.wave:boolean("use.w", "Use W - LastHelp", true)
menu.wave:header("wmana", "Mana - Settings")
menu.wave:slider("percentMana.clear", "Min. Percent Mana {%}", 50, 0, 100, 5)
--misc 
menu:menu("misc", "Miscellaneous - Settings")
--[[menu.misc:boolean("use.w", "Use W in Spirit", true)
menu.misc:boolean("can.attack.spirit", "Attack - Spirit", true)]]
--killsteal
menu.misc:header("kill", "Killsteal")
menu.misc:menu("Killsteal", "Killsteal - Settings")
menu.misc.Killsteal:boolean("qKill", "Killsteal with Q", true)
menu.misc.Killsteal:boolean("wKill", "Killsteal with W", true)
menu.misc.Killsteal:boolean("rKill", "Killsteal with R", true)
--draws
menu:menu("draws", "Drawings - Settings")
menu.draws:header("spells", "Spells - Drawings")
menu.draws:boolean("qrange", "Draw Q Range", true)
menu.draws:boolean("wrange", "Draw W Range", false)
menu.draws:boolean("erange", "Draw E Range", true)
menu.draws:boolean("rrange", "Draw R Range", true)
menu.draws:header("colors", "Color - Settings")
menu.draws:color("qcolor", "Q - Drawing Color", 255, 255, 11, 191)
menu.draws:color("wcolor", "W - Drawing Color", 255, 255, 11, 191)
menu.draws:color("ecolor", "E - Drawing Color", 255, 255, 11, 191)
menu.draws:color("rcolor", "R - Drawing Color", 255, 255, 11, 191)
menu.draws:header("orther", "Orther - Settings")
menu.draws:slider("points_n", "Draw points", 40, 1, 100, 1)
menu.draws['points_n']:set("tooltip", "Helps improve FPS")
menu.draws:slider("widthLine", "Width Circle", 2, 1, 5, 1)
--Tentacle Smash -Q 
--Harsh Lesson -W
--Test of Spirit -E
--Leap of Faith -R

return { 
    menu = menu, 
    TS = TS, 
    valid_menu = valid_menu
}