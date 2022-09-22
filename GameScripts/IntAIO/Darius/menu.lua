local menu = menu("IntnnerDarius", "Intnner - Darius")
local t_selector = module.load(header.id, "TargetSelector/targetSelector")

menu:set('icon', player.iconCircle)

local TS = t_selector(menu, 535, 1)
TS:addToMenu()

--core
menu:header("core", "Core - Darius")
--combo 
menu:menu('combo', "Combo - Settings")
--[[
    Decimate
    Crippling Strike
    Apprehend
    Noxian Guillotine
]]
menu.combo:header("q", "Decimate - Q")
menu.combo:boolean("use.q", "Use Q", true)
menu.combo:boolean("use.magnet", "^~ Reposition itself during Decimate", true)
    menu.combo['use.magnet']:set("tooltip", "Recover more health")
    menu.combo:boolean("under", "^~ Not use under the tower (magnet)", true)
--W 
menu.combo:header("w", "Crippling Strike - W")
menu.combo:boolean("use.w", "Use W", true)
menu.combo:boolean("use.w.aa.reset", "Use to reset Auto-Attack", true)
--E 
menu.combo:header("e", "Apprehend - E")
menu.combo:boolean("use.e", "Use E", true)
menu.combo:dropdown("mode.e", "Switch E Mode: ", 1, {"Out AA Range", "Always"})
--R 
menu.combo:header("r", "Noxian Guillotine - R")
menu.combo:boolean("use.r", "Use R", true)
menu.combo:menu("rsettings", "R - Settings")
--R Settings
menu.combo.rsettings:boolean("cast0", "Use R if killed", true)
menu.combo.rsettings:boolean("cast2", "Use R full Hemorrhage(stack)", false)
menu.combo.rsettings:boolean("cast3", "Do not use if killed by orthers spells or AA", true)
    menu.combo.rsettings['cast3']:set("tooltip", "Do not use if killed by orthers spells or AA")
--lower health 
menu.combo.rsettings:boolean("cast1", "Use R if my health is lower than target", false)
    menu.combo.rsettings['cast1']:set("tooltip", "Use R if my health is lower than target")
local visible_menu = function()
    menu.combo.rsettings.lowerHP:set("visible", menu.combo.rsettings['cast1']:get())
    menu.combo.rsettings.minHPMyHero:set("visible", menu.combo.rsettings['cast1']:get())
    menu.combo.rsettings.minHPTarget:set("visible", menu.combo.rsettings['cast1']:get())
end 
menu.combo.rsettings:header("lowerHP", "Health - Settings")
menu.combo.rsettings:slider("minHPMyHero", "Min. Health myHero {%}", 45, 5, 100, 5)
menu.combo.rsettings:slider("minHPTarget", "Min. Health Target {%}", 50, 5, 100, 5)
--Harass 
menu:menu("harass", "Harass/Hybrid - Settings")
--Q
menu.harass:header("q", "Decimate - Q")
menu.harass:boolean("use.q", "Use Q", true)
menu.harass:slider("mana.q", "Min. Mana Percent {%}", 25, 5, 100, 5)
--W
menu.harass:header("w", "Crippling Strike - W")
menu.harass:boolean("use.w", "Use W", true)
menu.harass:boolean("use.w.aa.reset", "Use to reset Auto-Attack", true)
menu.harass:slider("mana.w", "Min. Mana Percent {%}", 0, 0, 100, 5)
--E 
menu.harass:header("e", "Apprehend - E")
menu.harass:boolean("use.e", "Use E", true)
menu.harass:slider("mana.e", "Min. Mana Percent {%}", 10, 5, 100, 5)
--WaveClear
menu:menu("wave", "LastHit - Settings")
menu.wave:header("w", "Crippling Strike - W")
menu.wave:boolean("use.w", "Use W - LastHit", true)
menu.wave['use.w']:set("tooltip", "The logic tends not to lose the minion")
--Misc 
menu:menu("misc", "Miscellaneous - Settings")
menu.misc:boolean("focus", "Focus Target Hemorrhage (Passive)", true)
menu.misc:boolean("focusTotal", "^~ Only Full Stacks", false)
    menu.misc['focus']:set("tooltip", "Will focus on the Target that has the passive")
--KillSteal
menu.misc:header("kill", "Killsteal")
menu.misc:menu("Killsteal", "Killsteal - Settings")
menu.misc.Killsteal:boolean("qKill", "Killsteal with Q", true)
menu.misc.Killsteal:boolean("wKill", "Killsteal with W", true)
menu.misc.Killsteal:boolean("rKill", "Killsteal with R", true)
--Item 
menu.misc:header("item", "Item")
menu.misc:boolean("Item", "Use Stridebreaker", true)
--Evade 
menu.misc:header("ecvade", "Evade")
menu.misc:boolean("disableEvade", "Disable Evade in combo", true)
--Draws
menu:menu("draws", "Drawings - Settings")
menu.draws:header("spells", "Spells - Drawings")
menu.draws:boolean("passive", "Draw Passivel Time", true)
menu.draws:boolean("qrange", "Draw Q Range", true)
menu.draws:boolean("wrange", "Draw W Range", false)
menu.draws:boolean("erange", "Draw E Range", true)
menu.draws:boolean("rrange", "Draw R Range", true)
menu.draws:header("colors", "Color - Settings")
menu.draws:color("qcolor", "Q - Drawing Color", 255, 77, 11, 191)
menu.draws:color("wcolor", "W - Drawing Color", 255, 77, 11, 191)
menu.draws:color("ecolor", "E - Drawing Color", 255, 77, 11, 191)
menu.draws:color("rcolor", "R - Drawing Color", 255, 77, 11, 191)
menu.draws:header("orther", "Orther - Settings")
menu.draws:slider("points_n", "Draw points", 40, 1, 100, 1)
menu.draws['points_n']:set("tooltip", "Helps improve FPS")
menu.draws:slider("widthLine", "Width Circle", 2, 1, 5, 1)

return { 
    menu = menu, 
    TS = TS,
    visible_menu = visible_menu
}