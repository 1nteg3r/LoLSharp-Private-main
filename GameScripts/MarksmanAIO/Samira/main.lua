math.randomseed(os.time())

local orb = module.internal("orb")
local evade = module.seek("evade")
local ts = module.internal("TS")
local pred = module.internal("pred")
local clip = module.internal('clipper')
local common = module.load(header.id, "common");
local polygon = clip.polygon
local polygons = clip.polygons
local clipper = clip.clipper
local clipper_enum = clip.enum

--[[
Spell name: SamiraQ
Speed:500
Width: 80
Time:0.25
Animation: 0.25
false
CastFrame: 0.15599516034126
]]
local osTime = 0;
local castR = false;
local pred_q1 = {
    range = 950,
    delay = 0.25,
    speed = 2600,
    width = 80,
    boundingRadiusMod = 1,
    collision = {
        hero = true,
        minion = true,
        wall = true
    },
}

local pred_q2 = {
    range = 350,
    delay = 0.25,
    speed = 500,
    width = (math.pi/180*70),
    boundingRadiusMod = 1,
}

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

local _Q = 0;
local _W = 1; 
local _E = 2;
local _R = 3;

local MathHuge = math.huge
local CCSpells = {
	["AatroxW"] = {charName = "Aatrox", displayName = "Infernal Chains", slot = _W, type = "linear", speed = 1800, range = 825, delay = 0.25, radius = 80, collision = true},
	["AhriSeduce"] = {charName = "Ahri", displayName = "Seduce", slot = _E, type = "linear", speed = 1500, range = 975, delay = 0.25, radius = 60, collision = true},
	["AkaliR"] = {charName = "Akali", displayName = "Perfect Execution [First]", slot = _R, type = "linear", speed = 1800, range = 525, delay = 0, radius = 65, collision = false},
	["AkaliE"] = {charName = "Akali", displayName = "Shuriken Flip", slot = _E, type = "linear", speed = 1800, range = 825, delay = 0.25, radius = 70, collision = true},	
	["Pulverize"] = {charName = "Alistar", displayName = "Pulverize", slot = _Q, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 365, collision = false},
	["BandageToss"] = {charName = "Amumu", displayName = "Bandage Toss", slot = _Q, type = "linear", speed = 2000, range = 1100, delay = 0.25, radius = 80, collision = true},
	["CurseoftheSadMummy"] = {charName = "Amumu", displayName = "Curse of the Sad Mummy", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 550, collision = false},
	["FlashFrostSpell"] = {charName = "Anivia", displayName = "Flash Frost",missileName = "FlashFrostSpell", slot = _Q, type = "linear", speed = 850, range = 1100, delay = 0.25, radius = 110, collision = false},
	["EnchantedCrystalArrow"] = {charName = "Ashe", displayName = "Enchanted Crystal Arrow", slot = _R, type = "linear", speed = 1600, range = 25000, delay = 0.25, radius = 130, collision = false},
	["AurelionSolQ"] = {charName = "AurelionSol", displayName = "Starsurge", slot = _Q, type = "linear", speed = 850, range = 25000, delay = 0, radius = 110, collision = false},
	["AzirR"] = {charName = "Azir", displayName = "Emperor's Divide", slot = _R, type = "linear", speed = 1400, range = 500, delay = 0.3, radius = 250, collision = false},
	["ApheliosR"] = {charName = "Aphelios", displayName = "Moonlight Vigil", slot = _R, type = "linear", speed = 2050, range = 1600, delay = 0.5, radius = 125, collision = false},	
	["BardQ"] = {charName = "Bard", displayName = "Cosmic Binding", slot = _Q, type = "linear", speed = 1500, range = 950, delay = 0.25, radius = 60, collision = true},	
	["BardR"] = {charName = "Bard", displayName = "Tempered Fate", slot = _R, type = "circular", speed = 2100, range = 3400, delay = 0.5, radius = 350, collision = false},
	["BrandQ"] = {charName = "Brand", displayName = "Sear", slot = _Q, type = "linear", speed = 1600, range = 1050, delay = 0.25, radius = 60, collision = true},	
	["RocketGrab"] = {charName = "Blitzcrank", displayName = "Rocket Grab", slot = _Q, type = "linear", speed = 1800, range = 1150, delay = 0.25, radius = 140, collision = true},
	["BraumQ"] = {charName = "Braum", displayName = "Winter's Bite", slot = _Q, type = "linear", speed = 1700, range = 1000, delay = 0.25, radius = 70, collision = true},
	["BraumR"] = {charName = "Braum", displayName = "Glacial Fissure", slot = _R, type = "linear", speed = 1400, range = 1250, delay = 0.5, radius = 115, collision = false},
	["CaitlynYordleTrap"] = {charName = "Caitlyn", displayName = "Yordle Trap", slot = _W, type = "circular", speed = MathHuge, range = 800, delay = 0.25, radius = 75, collision = false},
	["CaitlynEntrapment"] = {charName = "Caitlyn", displayName = "Entrapment", slot = _E, type = "linear", speed = 1600, range = 750, delay = 0.15, radius = 70, collision = true},
	["CassiopeiaW"] = {charName = "Cassiopeia", displayName = "Miasma", slot = _W, type = "circular", speed = 2500, range = 800, delay = 0.75, radius = 160, collision = false},
	["Rupture"] = {charName = "Chogath", displayName = "Rupture", slot = _Q, type = "circular", speed = MathHuge, range = 950, delay = 1.2, radius = 250, collision = false},
	["InfectedCleaverMissile"] = {charName = "DrMundo", displayName = "Infected Cleaver", slot = _Q, type = "linear", speed = 2000, range = 975, delay = 0.25, radius = 60, collision = true},
	["DravenDoubleShot"] = {charName = "Draven", displayName = "Double Shot", slot = _E, type = "linear", speed = 1600, range = 1050, delay = 0.25, radius = 130, collision = false},
	["DravenRCast"] = {charName = "Draven", displayName = "Whirling Death", slot = _R, type = "linear", speed = 2000, range = 12500, delay = 0.25, radius = 160, collision = false},	
	["DianaQ"] = {charName = "Diana", displayName = "Crescent Strike", slot = _Q, type = "circular", speed = 1900, range = 900, delay = 0.25, radius = 185, collision = true},	
	["EkkoQ"] = {charName = "Ekko", displayName = "Timewinder", slot = _Q, type = "linear", speed = 1650, range = 1175, delay = 0.25, radius = 60, collision = false},
	["EkkoW"] = {charName = "Ekko", displayName = "Parallel Convergence", slot = _W, type = "circular", speed = MathHuge, range = 1600, delay = 3.35, radius = 400, collision = false},
	["EliseHumanE"] = {charName = "Elise", displayName = "Cocoon", slot = _E, type = "linear", speed = 1600, range = 1075, delay = 0.25, radius = 55, collision = true},
	["EzrealR"] = {charName = "Ezreal", displayName = "Trueshot Barrage", slot = _R, type = "linear", speed = 2000, range = 12500, delay = 1, radius = 160, collision = true},	
	["FizzR"] = {charName = "Fizz", displayName = "Chum the Waters", slot = _R, type = "linear", speed = 1300, range = 1300, delay = 0.25, radius = 150, collision = false},
	["GalioE"] = {charName = "Galio", displayName = "Justice Punch", slot = _E, type = "linear", speed = 2300, range = 650, delay = 0.4, radius = 160, collision = false},
	["GnarQMissile"] = {charName = "Gnar", displayName = "Boomerang Throw", slot = _Q, type = "linear", speed = 2500, range = 1125, delay = 0.25, radius = 55, collision = false},
	["GnarBigQMissile"] = {charName = "Gnar", displayName = "Boulder Toss", slot = _Q, type = "linear", speed = 2100, range = 1125, delay = 0.5, radius = 90, collision = true},
	["GnarBigW"] = {charName = "Gnar", displayName = "Wallop", slot = _W, type = "linear", speed = MathHuge, range = 575, delay = 0.6, radius = 100, collision = false},
	["GnarR"] = {charName = "Gnar", displayName = "GNAR!", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 475, collision = false},
	["GragasQ"] = {charName = "Gragas", displayName = "Barrel Roll", slot = _Q, type = "circular", speed = 1000, range = 850, delay = 0.25, radius = 275, collision = false},
	["GragasR"] = {charName = "Gragas", displayName = "Explosive Cask", slot = _R, type = "circular", speed = 1800, range = 1000, delay = 0.25, radius = 400, collision = false},
	["GravesSmokeGrenade"] = {charName = "Graves", displayName = "Smoke Grenade", slot = _W, type = "circular", speed = 1500, range = 950, delay = 0.15, radius = 250, collision = false},
	["HeimerdingerE"] = {charName = "Heimerdinger", displayName = "CH-2 Electron Storm Grenade", slot = _E, type = "circular", speed = 1200, range = 970, delay = 0.25, radius = 250, collision = false},
	["HeimerdingerEUlt"] = {charName = "Heimerdinger", displayName = "CH-2 Electron Storm Grenade", slot = _E, type = "circular", speed = 1200, range = 970, delay = 0.25, radius = 250, collision = false},
	["IreliaW2"] = {charName = "Irelia", displayName = "Defiant Dance", slot = _W, type = "linear", speed = MathHuge, range = 775, delay = 0.25, radius = 120, collision = false},
	["IreliaR"] = {charName = "Irelia", displayName = "Vanguard's Edge", slot = _R, type = "linear", speed = 2000, range = 950, delay = 0.4, radius = 160, collision = false},
	["IvernQ"] = {charName = "Ivern", displayName = "Rootcaller", slot = _Q, type = "linear", speed = 1300, range = 1075, delay = 0.25, radius = 80, collision = true},
	["IllaoiE"] = {charName = "Illaoi", displayName = "Test of Spirit", slot = _E, type = "linear", speed = 1900, range = 900, delay = 0.25, radius = 50, collision = true},	
	["IvernQ"] = {charName = "Ivern", displayName = "Rootcaller", slot = _Q, type = "linear", speed = 1300, range = 1075, delay = 0.25, radius = 80, collision = true},		
	["HowlingGaleSpell"] = {charName = "Janna", displayName = "Howling Gale", slot = _Q, type = "linear", speed = 667, range = 1750, delay = 0, radius = 100, collision = false},			
	["JarvanIVDragonStrike"] = {charName = "JarvanIV", displayName = "Dragon Strike", slot = _Q, type = "linear", speed = MathHuge, range = 770, delay = 0.4, radius = 70, collision = false},
	["JhinW"] = {charName = "Jhin", displayName = "Deadly Flourish", slot = _W, type = "linear", speed = 5000, range = 2550, delay = 0.75, radius = 40, collision = false},
	["JhinRShot"] = {charName = "Jhin", displayName = "Curtain Call", slot = _R, type = "linear", speed = 5000, range = 3500, delay = 0.25, radius = 80, collision = false},
	["JhinE"] = {charName = "Jhin", displayName = "Captive Audience", slot = _E, type = "circular", speed = 1600, range = 750, delay = 0.25, radius = 130, collision = false},
	["JinxWMissile"] = {charName = "Jinx", displayName = "Zap!", slot = _W, type = "linear", speed = 3300, range = 1450, delay = 0.6, radius = 60, collision = true},
	["KarmaQ"] = {charName = "Karma", displayName = "Inner Flame", slot = _Q, type = "linear", speed = 1700, range = 950, delay = 0.25, radius = 60, collision = true},
	["KarmaQMantra"] = {charName = "Karma", displayName = "Inner Flame [Mantra]", slot = _Q, origin = "linear", type = "linear", speed = 1700, range = 950, delay = 0.25, radius = 80, collision = true},
	["KayleQ"] = {charName = "Kayle", displayName = "Radiant Blast", slot = _Q, type = "linear", speed = 2000, range = 850, delay = 0.5, radius = 60, collision = false},
	["KaynW"] = {charName = "Kayn", displayName = "Blade's Reach", slot = _W, type = "linear", speed = MathHuge, range = 700, delay = 0.55, radius = 90, collision = false},
	["KhazixWLong"] = {charName = "Khazix", displayName = "Void Spike [Threeway]", slot = _W, type = "threeway", speed = 1700, range = 1000, delay = 0.25, radius = 70,angle = 23, collision = true},
	["KledQ"] = {charName = "Kled", displayName = "Beartrap on a Rope", slot = _Q, type = "linear", speed = 1600, range = 800, delay = 0.25, radius = 45, collision = true},
	["KogMawVoidOozeMissile"] = {charName = "KogMaw", displayName = "Void Ooze", slot = _E, type = "linear", speed = 1400, range = 1360, delay = 0.25, radius = 120, collision = false},
	["BlindMonkQOne"] = {charName = "Leesin", displayName = "Sonic Wave", slot = _Q, type = "linear", speed = 1800, range = 1100, delay = 0.25, radius = 60, collision = true},	
	["LeblancE"] = {charName = "Leblanc", displayName = "Ethereal Chains [Standard]", slot = _E, type = "linear", speed = 1750, range = 925, delay = 0.25, radius = 55, collision = true},
	["LeblancRE"] = {charName = "Leblanc", displayName = "Ethereal Chains [Ultimate]", slot = _E, type = "linear", speed = 1750, range = 925, delay = 0.25, radius = 55, collision = true},
	["LeonaZenithBlade"] = {charName = "Leona", displayName = "Zenith Blade", slot = _E, type = "linear", speed = 2000, range = 875, delay = 0.25, radius = 70, collision = false},
	["LeonaSolarFlare"] = {charName = "Leona", displayName = "Solar Flare", slot = _R, type = "circular", speed = MathHuge, range = 1200, delay = 0.85, radius = 300, collision = false},
	["LissandraQMissile"] = {charName = "Lissandra", displayName = "Ice Shard", slot = _Q, type = "linear", speed = 2200, range = 750, delay = 0.25, radius = 75, collision = false},
	["LuluQ"] = {charName = "Lulu", displayName = "Glitterlance", slot = _Q, type = "linear", speed = 1450, range = 925, delay = 0.25, radius = 60, collision = false},
	["LuxLightBinding"] = {charName = "Lux", displayName = "Light Binding", slot = _Q, type = "linear", speed = 1200, range = 1175, delay = 0.25, radius = 50, collision = false},
	["LuxLightStrikeKugel"] = {charName = "Lux", displayName = "Light Strike Kugel", slot = _E, type = "circular", speed = 1200, range = 1100, delay = 0.25, radius = 300, collision = true},
	["Landslide"] = {charName = "Malphite", displayName = "Ground Slam", slot = _E, type = "circular", speed = MathHuge, range = 0, delay = 0.242, radius = 400, collision = false},
	["MalzaharQ"] = {charName = "Malzahar", displayName = "Call of the Void", slot = _Q, type = "rectangular", speed = 1600, range = 900, delay = 0.5, radius = 400, radius2 = 100, collision = false},
	["MaokaiQ"] = {charName = "Maokai", displayName = "Bramble Smash", slot = _Q, type = "linear", speed = 1600, range = 600, delay = 0.375, radius = 110, collision = false},
	["MorganaQ"] = {charName = "Morgana", displayName = "Dark Binding", slot = _Q, type = "linear", speed = 1200, range = 1250, delay = 0.25, radius = 70, collision = true},
	["NamiQ"] = {charName = "Nami", displayName = "Aqua Prison", slot = _Q, type = "circular", speed = MathHuge, range = 875, delay = 1, radius = 180, collision = false},
	["NamiRMissile"] = {charName = "Nami", displayName = "Tidal Wave", slot = _R, type = "linear", speed = 850, range = 2750, delay = 0.5, radius = 250, collision = false},
	["NautilusAnchorDragMissile"] = {charName = "Nautilus", displayName = "Dredge Line", slot = _Q, type = "linear", speed = 2000, range = 925, delay = 0.25, radius = 90, collision = true},
	["NeekoQ"] = {charName = "Neeko", displayName = "Blooming Burst", slot = _Q, type = "circular", speed = 1500, range = 800, delay = 0.25, radius = 200, collision = false},
	["NeekoE"] = {charName = "Neeko", displayName = "Tangle-Barbs", slot = _E, type = "linear", speed = 1400, range = 1000, delay = 0.25, radius = 65, collision = false},
	["NunuR"] = {charName = "Nunu", displayName = "Absolute Zero", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 3, radius = 650, collision = false},
	["OlafAxeThrowCast"] = {charName = "Olaf", displayName = "Undertow", slot = _Q, type = "linear", speed = 1600, range = 1000, delay = 0.25, radius = 90, collision = false},
	["OrnnQ"] = {charName = "Ornn", displayName = "Volcanic Rupture", slot = _Q, type = "linear", speed = 1800, range = 800, delay = 0.3, radius = 65, collision = false},
	["OrnnE"] = {charName = "Ornn", displayName = "Searing Charge", slot = _E, type = "linear", speed = 1600, range = 800, delay = 0.35, radius = 150, collision = false},
	["OrnnRCharge"] = {charName = "Ornn", displayName = "Call of the Forge God", slot = _R, type = "linear", speed = 1650, range = 2500, delay = 0.5, radius = 200, collision = false},
	["PoppyQSpell"] = {charName = "Poppy", displayName = "Hammer Shock", slot = _Q, type = "linear", speed = MathHuge, range = 430, delay = 0.332, radius = 100, collision = false},
	["PoppyRSpell"] = {charName = "Poppy", displayName = "Keeper's Verdict", slot = _R, type = "linear", speed = 2000, range = 1200, delay = 0.33, radius = 100, collision = false},
	["PykeQMelee"] = {charName = "Pyke", displayName = "Bone Skewer [Melee]", slot = _Q, type = "linear", speed = MathHuge, range = 400, delay = 0.25, radius = 70, collision = false},
	["PykeQRange"] = {charName = "Pyke", displayName = "Bone Skewer [Range]", slot = _Q, type = "linear", speed = 2000, range = 1100, delay = 0.2, radius = 70, collision = true},
	["PykeE"] = {charName = "Pyke", displayName = "Phantom Undertow", slot = _E, type = "linear", speed = 3000, range = 25000, delay = 0, radius = 110, collision = false},
	["QiyanaR"] = {charName = "Qiyana", displayName = "Supreme Display of Talent", slot = _R, type = "linear", speed = 2000, range = 950, delay = 0.25, radius = 190, collision = false},	
	["RakanW"] = {charName = "Rakan", displayName = "Grand Entrance", slot = _W, type = "circular", speed = MathHuge, range = 650, delay = 0.7, radius = 265, collision = false},
	["RengarE"] = {charName = "Rengar", displayName = "Bola Strike", slot = _E, type = "linear", speed = 1500, range = 1000, delay = 0.25, radius = 70, collision = true},
	["RumbleGrenade"] = {charName = "Rumble", displayName = "Electro Harpoon", slot = _E, type = "linear", speed = 2000, range = 850, delay = 0.25, radius = 60, collision = true},
	["SejuaniR"] = {charName = "Sejuani", displayName = "Glacial Prison", slot = _R, type = "linear", speed = 1600, range = 1300, delay = 0.25, radius = 120, collision = false},
	["ShyvanaTransformLeap"] = {charName = "Shyvana", displayName = "Transform Leap", slot = _R, type = "linear", speed = 700, range = 850, delay = 0.25, radius = 150, collision = false},
	["SionQ"] = {charName = "Sion", displayName = "Decimating Smash", slot = _Q, origin = "", type = "linear", speed = MathHuge, range = 750, delay = 2, radius = 150, collision = false},
	["SionE"] = {charName = "Sion", displayName = "Roar of the Slayer", slot = _E, type = "linear", speed = 1800, range = 800, delay = 0.25, radius = 80, collision = false},
	["SkarnerFractureMissile"] = {charName = "Skarner", displayName = "Fracture", slot = _E, type = "linear", speed = 1500, range = 1000, delay = 0.25, radius = 70, collision = false},
	["SonaR"] = {charName = "Sona", displayName = "Crescendo", slot = _R, type = "linear", speed = 2400, range = 1000, delay = 0.25, radius = 140, collision = false},
	["SorakaQ"] = {charName = "Soraka", displayName = "Starcall", slot = _Q, type = "circular", speed = 1150, range = 810, delay = 0.25, radius = 235, collision = false},
	["SwainW"] = {charName = "Swain", displayName = "Vision of Empire", slot = _W, type = "circular", speed = MathHuge, range = 3500, delay = 1.5, radius = 300, collision = false},
	["SwainE"] = {charName = "Swain", displayName = "Nevermove", slot = _E, type = "linear", speed = 1800, range = 850, delay = 0.25, radius = 85, collision = false},
	["SylasE2"] = {charName = "Sylas", displayName = "Abduct", slot = _E, type = "linear", speed = 1600, range = 850, delay = 0.25, radius = 60, collision = true},	
	["TahmKenchQ"] = {charName = "TahmKench", displayName = "Tongue Lash", slot = _Q, type = "linear", speed = 2800, range = 800, delay = 0.25, radius = 70, collision = true},
	["TaliyahWVC"] = {charName = "Taliyah", displayName = "Seismic Shove", slot = _W, type = "circular", speed = MathHuge, range = 900, delay = 0.85, radius = 150, collision = false},
	["TaliyahR"] = {charName = "Taliyah", displayName = "Weaver's Wall", slot = _R, type = "linear", speed = 1700, range = 3000, delay = 1, radius = 120, collision = false},
	["ThreshE"] = {charName = "Thresh", displayName = "Flay", slot = _E, type = "linear", speed = MathHuge, range = 500, delay = 0.389, radius = 110, collision = true},
	["TristanaW"] = {charName = "Tristana", displayName = "Rocket Jump", slot = _W, type = "circular", speed = 1100, range = 900, delay = 0.25, radius = 300, collision = false},
	["UrgotQ"] = {charName = "Urgot", displayName = "Corrosive Charge", slot = _Q, type = "circular", speed = MathHuge, range = 800, delay = 0.6, radius = 180, collision = false},
	["UrgotE"] = {charName = "Urgot", displayName = "Disdain", slot = _E, type = "linear", speed = 1540, range = 475, delay = 0.45, radius = 100, collision = false},
	["UrgotR"] = {charName = "Urgot", displayName = "Fear Beyond Death", slot = _R, type = "linear", speed = 3200, range = 1600, delay = 0.4, radius = 80, collision = false},
	["VarusE"] = {charName = "Varus", displayName = "Hail of Arrows", slot = _E, type = "linear", speed = 1500, range = 925, delay = 0.242, radius = 260, collision = false},
	["VarusR"] = {charName = "Varus", displayName = "Chain of Corruption", slot = _R, type = "linear", speed = 1950, range = 1200, delay = 0.25, radius = 120, collision = false},
	["VelkozQ"] = {charName = "Velkoz", displayName = "Plasma Fission", slot = _Q, type = "linear", speed = 1300, range = 1050, delay = 0.25, radius = 50, collision = true},
	["VelkozE"] = {charName = "Velkoz", displayName = "Tectonic Disruption", slot = _E, type = "circular", speed = MathHuge, range = 800, delay = 0.8, radius = 185, collision = false},
	["ViktorGravitonField"] = {charName = "Viktor", displayName = "Graviton Field", slot = _W, type = "circular", speed = MathHuge, range = 800, delay = 1.75, radius = 270, collision = false},
	["WarwickR"] = {charName = "Warwick", displayName = "Infinite Duress", slot = _R, type = "linear", speed = 1800, range = 3000, delay = 0.1, radius = 55, collision = false},
	["XerathArcaneBarrage2"] = {charName = "Xerath", displayName = "Arcane Barrage", slot = _W, type = "circular", speed = MathHuge, range = 1000, delay = 0.75, radius = 235, collision = false},
	["XerathMageSpear"] = {charName = "Xerath", displayName = "Mage Spear", slot = _E, type = "linear", speed = 1400, range = 1050, delay = 0.2, radius = 60, collision = true},
	["XinZhaoW"] = {charName = "XinZhao", displayName = "Wind Becomes Lightning", slot = _W, type = "linear", speed = 5000, range = 900, delay = 0.5, radius = 40, collision = false},
	["ZacQ"] = {charName = "Zac", displayName = "Stretching Strikes", slot = _Q, type = "linear", speed = 2800, range = 800, delay = 0.33, radius = 120, collision = false},
	["ZiggsW"] = {charName = "Ziggs", displayName = "Satchel Charge", slot = _W, type = "circular", speed = 1750, range = 1000, delay = 0.25, radius = 240, collision = false},
	["ZiggsE"] = {charName = "Ziggs", displayName = "Hexplosive Minefield", slot = _E, type = "circular", speed = 1800, range = 900, delay = 0.25, radius = 250, collision = false},
	["ZileanQ"] = {charName = "Zilean", displayName = "Time Bomb", slot = _Q, type = "circular", speed = MathHuge, range = 900, delay = 0.8, radius = 150, collision = false},
	["ZoeE"] = {charName = "Zoe", displayName = "Sleepy Trouble Bubble", slot = _E, type = "linear", speed = 1700, range = 800, delay = 0.3, radius = 50, collision = true},
	["ZyraE"] = {charName = "Zyra", displayName = "Grasping Roots", slot = _E, type = "linear", speed = 1150, range = 1100, delay = 0.25, radius = 70, collision = false},
	["ZyraR"] = {charName = "Zyra", displayName = "Stranglethorns", slot = _R, type = "circular", speed = MathHuge, range = 700, delay = 2, radius = 500, collision = false},
	["BrandConflagration"] = {charName = "Brand", slot = _R, type = "targeted", displayName = "Conflagration", range = 625,cc = true},
	["JarvanIVCataclysm"] = {charName = "JarvanIV", slot = _R, type = "targeted", displayName = "Cataclysm", range = 650},
	["JayceThunderingBlow"] = {charName = "Jayce", slot = _E, type = "targeted", displayName = "Thundering Blow", range = 240},
	["BlindMonkRKick"] = {charName = "LeeSin", slot = _R, type = "targeted", displayName = "Dragon's Rage", range = 375},
	["LissandraR"] = {charName = "Lissandra", slot = _R, type = "targeted", displayName = "Frozen Tomb", range = 550},
	["SeismicShard"] = {charName = "Malphite", slot = _Q, type = "targeted", displayName = "Seismic Shard", range = 625,cc = true},
	["AlZaharNetherGrasp"] = {charName = "Malzahar", slot = _R, type = "targeted", displayName = "Nether Grasp", range = 700},
	["MaokaiW"] = {charName = "Maokai", slot = _W, type = "targeted", displayName = "Twisted Advance", range = 525},
	["NautilusR"] = {charName = "Nautilus", slot = _R, type = "targeted", displayName = "Depth Charge", range = 825},
	["PoppyE"] = {charName = "Poppy", slot = _E, type = "targeted", displayName = "Heroic Charge", range = 475},
	["RyzeW"] = {charName = "Ryze", slot = _W, type = "targeted", displayName = "Rune Prison", range = 615},
	["Fling"] = {charName = "Singed", slot = _E, type = "targeted", displayName = "Fling", range = 125},
	["SkarnerImpale"] = {charName = "Skarner", slot = _R, type = "targeted", displayName = "Impale", range = 350},
	["TahmKenchW"] = {charName = "TahmKench", slot = _W, type = "targeted", displayName = "Devour", range = 250},
	["TristanaR"] = {charName = "Tristana", slot = _R, type = "targeted", displayName = "Buster Shot", range = 669}
}


local menu = menu("marksmanSmira", "Marksman - ".. player.charName)
menu:menu('combo', 'Combo Settings')
    menu.combo:menu('qsettings', "Q Settings")
        menu.combo.qsettings:boolean("qcombo", "Use Q", true)
        menu.combo.qsettings:slider("mana_mngr", "Minimum Mana %", 10, 0, 100, 5)
    menu.combo:menu('wsettings', "W Settings")
        menu.combo.wsettings:boolean("wcombo", "Use W", true)
        menu.combo.wsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
        menu.combo.wsettings:menu('dodge_spell', "Dodge Spells")
        for _, i in pairs(CCSpells) do
            for l, k in pairs(common.GetEnemyHeroes()) do
                -- k = myHero
                if not CCSpells[_] then
                    return
                end
                if i.charName == k.charName then
                    if i.displayname == "" then
                        i.displayname = _
                    end 
                    if (menu.combo.wsettings.dodge_spell[i.charName] == nil) then
                        menu.combo.wsettings.dodge_spell:menu(i.charName, i.charName)
                    end
                    menu.combo.wsettings.dodge_spell[i.charName]:menu(_, "" .. i.charName .. " | " .. _)
                    menu.combo.wsettings.dodge_spell[i.charName][_]:boolean("Dodge", "Dodge || W", true)
                end 
            end 
        end
    menu.combo:menu('esettings', "E Settings")
        menu.combo.esettings:boolean("ecombo", "Use E", true)
        menu.combo.esettings:boolean("gab", "Use E gabclose in combo", true)
    menu.combo:menu('rsettings', "R Settings")
        menu.combo.rsettings:boolean("rcombo", "Use R", true)
        menu.combo.rsettings:slider("delayed", "Auto R. Min Health to use R", 30, 1, 100, 1);
        menu.combo.rsettings:header('Another', "Misc Settings")
        menu.combo.rsettings:slider("MinTargetsR", "Use R Min. Targets", 2, 1, 5, 1);
menu:menu('harass', 'Hybrid/Harass Settings')
    menu.harass:menu('wsettings', "Q Settings")
        menu.harass.wsettings:boolean("qharras", "Use Q", true)
        menu.harass.wsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
menu:header("", "Misc Settings")
menu:boolean("ignw", "Ignore collision", false);
menu:menu('kill', 'KillSteal Settings')
    menu.kill:boolean("qKill", "Use Q if KillSteal", true)
    menu.kill:boolean("wKill", "Use W if KillSteal", true)
    menu.kill:boolean("eKill", "Use E Smart Kill", true)
    menu.kill:boolean("rKill", "Use R if KillSteal", true)
menu:menu("draws", "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", false)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("r_range", "Draw R Range", true)
    menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)

core.on_end_q = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end

core.on_end_w = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end

core.on_end_e = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end

core.on_end_r = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end
core.on_cast_q = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_q
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end

core.on_cast_w = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_w
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end

core.on_cast_e = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_e
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end

core.on_cast_r = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_r
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end

local function GetClosestMobToEnemy()
	local enemyMinions = common.GetMinionsInRange(725, TEAM_ENEMY)

	local closestMinion = nil
	local closestMinionDistance = 9999
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
		if enemies and common.IsValidTarget(enemies) then
			local hp = common.GetShieldedHealth("ap", enemies)
			for i, minion in pairs(enemyMinions) do
				if minion then
                    local minionPos = vec3(minion.x, minion.y, minion.z)
                    local poss = player.pos + (minion.pos - player.pos):norm() * 650
					if  minionPos:dist(player.pos) < 650 and (minionPos:dist(enemies) < 600 or enemies.pos:dist(poss) < 600) then
						local minionDistanceToMouse = minionPos:dist(enemies)

						if minionDistanceToMouse < closestMinionDistance then
							closestMinion = minion
							closestMinionDistance = minionDistanceToMouse
						end
					end
				end
			end
		end
	end

	return closestMinion
end
local function GetClosestJungleEnemy()
	local enemyMinions = common.GetMinionsInRange(725, TEAM_NEUTRAL)

	local closestMinion = nil
	local closestMinionDistance = 9999
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
		if enemies and common.IsValidTarget(enemies) then
			local hp = common.GetShieldedHealth("ap", enemies)
			for i, minion in pairs(enemyMinions) do
				if minion then
                    local minionPos = vec3(minion.x, minion.y, minion.z)
                    local poss = player.pos + (minionPos - player.pos):norm() * 650
					if  minionPos:dist(player.pos) < 650 and (minionPos:dist(enemies) < 600 or enemies.pos:dist(poss) < 600) then
						local minionDistanceToMouse = minionPos:dist(enemies)

						if minionDistanceToMouse < closestMinionDistance then
							closestMinion = minion
							closestMinionDistance = minionDistanceToMouse
						end
					end
				end
			end
		end
	end

	return closestMinion
end

local trace_filter = function(pred_INUPUT, seg, obj)
    if seg.startPos:distSqr(seg.endPos) > 1380625 then
        return false
    end
    if seg.startPos:distSqr(obj.path.serverPos2D) > 1380625 then
        return false
    end
    if pred.trace.linear.hardlock(pred_INUPUT, seg, obj) then
        return true
    end

    if pred.trace.linear.hardlockmove(pred_INUPUT, seg, obj) then
        return true
    end
    if pred.trace.newpath(obj, 0.033, 0.500) then
        return true
    end
end

local q_target = function(res, obj, dist)
    if dist > 960 or (obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then 
        return 
    end

    if dist <= common.GetAARange(obj) then
        local aa_damage = common.CalculateAADamage(obj)
        if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
            return
        end
    end

    res.obj = obj 
    return true 
end 

local r_target  = function(res, obj, dist)
    if dist > 650 or (obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then 
        return 
    end

    res.obj = obj 
    return true 
end

local w_target = function(res, obj, dist)
    if dist > 350 or (obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then 
        return 
    end

    res.obj = obj 
    return true 
end

local e_target = function(res, obj, dist)
    if dist > 650 or (obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then 
        return 
    end

    res.obj = obj 
    return true 
end

local e_target_gab = function(res, obj, dist)
    if dist > 1500 or (obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then 
        return 
    end

    res.obj = obj 
    return true 
end


local function CastQ(target)
    if not target then 
        return 
    end 

    if player:spellSlot(0).state == 0 then 
        if player.path.serverPos:distSqr(target.path.serverPos) > (350 * 350) and player.path.serverPos:distSqr(target.path.serverPos) < (950 * 950) then 
            local seg = pred.linear.get_prediction(pred_q1, target)
            if seg and seg.startPos:distSqr(seg.endPos) <= (pred_q1.range * pred_q1.range) then
                local col = pred.collision.get_prediction(pred_q1, seg, target)
                if not col and trace_filter(pred_q1, seg, target) then
                    player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    orb.combat.set_invoke_after_attack(true)
                    return true
                end 
            end
        elseif player.path.serverPos:distSqr(target.path.serverPos) <= (350 * 350) then  
            local seg = pred.linear.get_prediction(pred_q2, target)
            if seg and seg.startPos:distSqr(seg.endPos) <= (pred_q2.range * pred_q2.range) then
                player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                orb.combat.set_invoke_after_attack(true)
                return true
            end
        end
    end 
end

local function CastW(target)
    if not target then 
        return 
    end 

    if player:spellSlot(1).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (350 * 350) then  
        player:castSpell("self", 1)
        orb.combat.set_invoke_after_attack(false)
        return true
    end
end 

local function IsDashPosTurret(unit)
    local myPos = vec3(player.x, player.y, player.z)
    local endPos = vec3(unit.x, player.y, unit.z)
    local pos = myPos + (endPos - myPos):norm() * 650
	
    for i= 1, objManager.turrets.size[TEAM_ENEMY]-1 do
        local tower = objManager.turrets[TEAM_ENEMY][i]
        if tower and not tower.isDead and tower.health > 0 then
            local range = (tower.boundingRadius + 750 + player.boundingRadius / 2)
            if tower.pos:distSqr(pos) < 925 * 925 then
				return true
			end
		end
	end	
    return false
end

local E_cast = 0
local function CastE(target)
    if not target then 
        return 
    end

    if player:spellSlot(2).state == 0 then 
        if player.path.serverPos:distSqr(target.path.serverPos) < (650 * 650) then  
            local poss = player.pos + (target.pos - player.pos):norm() * 650
            if (common.IsUnderDangerousTower(poss) or common.IsUnderDangerousTower(target.pos)) then 
                return 
            end 
            --if not IsDashPosTurret(target.pos) then 
                if player:spellSlot(0).state == 0 and  os.clock() -  E_cast > 1 then 
                    CastQ(target)
                else 
                    player:castSpell("obj", 2, target)
                end
            --end
        end 
                    
    end 
end 

local function combo()
    if menu.combo.rsettings.rcombo:get() then
        if #common.CountEnemiesInRange(player.pos, 600) > 0 then 
            if player:spellSlot(3).state == 0 then 
                local target = ts.get_result(r_target).obj

                if target and common.isValidTarget(target) then 
                    if common.GetPercentHealth(player) < menu.combo.rsettings.delayed:get() or common.GetPercentHealth(player) > common.GetPercentHealth(target) then 
                        if os.clock() - E_cast > 1 then 
                            castR = true
                            player:castSpell("self", 3)
                        end
                    end
                end
            else 
                if player:spellSlot(3).state == 0 then 
                    local target = ts.get_result(r_target).obj

                    if target and common.isValidTarget(target) then 
                        if common.GetPercentHealth(player) < menu.combo.rsettings.delayed:get() then 
                            castR = true
                            player:castSpell("self", 3)
                        end 
                    end
                end
            end
        elseif #common.CountEnemiesInRange(player.pos, 600) >= 2 then 
            if player:spellSlot(3).state == 0 then 
                for i = 0, objManager.enemies_n - 1 do
                    local target = objManager.enemies[i]

                    if target and common.isValidTarget(target) then 
                        castR = true
                        player:castSpell("self", 3)
                    end
                end
            end
        end
    end 

    if castR then 
        return 
    end 

    if menu.combo.esettings.ecombo:get() and player.mana > player.manaCost3 + player.manaCost0  then
        local target = ts.get_result(e_target).obj

        if target and common.isValidTarget(target) then 
            CastE(target)
        end


        local targetgab = ts.get_result(e_target_gab).obj

        if targetgab and common.isValidTarget(targetgab) then

            if menu.combo.esettings.gab:get() and player.path.serverPos:distSqr(targetgab.path.serverPos) > 650 * 650 then 
                if common.IsUnderDangerousTower(targetgab.pos) then 
                    return 
                end 

                local minion = GetClosestMobToEnemy(targetgab)
                if minion and player.pos:distSqr(minion.pos) < (650 * 650) and not common.IsUnderDangerousTower(minion.pos)   then
                    player:castSpell("obj", 2, minion)
                end

                local minios = GetClosestJungleEnemy(targetgab)
                if minios and  player.pos:distSqr(minios.pos) < (650 * 650) and not common.IsUnderDangerousTower(minios.pos)   then
                    player:castSpell("obj", 2, minios)
                end
            end
        end
    end 

    if menu.combo.qsettings.qcombo:get() and common.GetPercentPar() >= menu.combo.qsettings.mana_mngr:get() then
        local target = ts.get_result(q_target).obj

        if target and common.isValidTarget(target) then 
            CastQ(target)
        end 
    end 

    if menu.combo.wsettings.wcombo:get() and common.GetPercentPar() >= menu.combo.wsettings.mana_mngr:get() then
        local target = ts.get_result(w_target).obj

        if target and common.isValidTarget(target) then 
            CastW(target)
        end 
    end 
end

local function harass()
    if menu.harass.wsettings.qharras:get() and common.GetPercentPar() >= menu.harass.wsettings.mana_mngr:get() then
        local target = ts.get_result(q_target).obj

        if target and common.isValidTarget(target) then 
            CastQ(target)
        end 
    end 
end 

local function AutoDoged()
    for i=evade.core.targeted.n, 1, -1 do
        local spell = evade.core.targeted[i]
        if spell and spell.owner.team == TEAM_ENEMY  and spell.target.ptr == player.ptr then 
            local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
            if player:spellSlot(1).state == 0 then 
                if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                    player:castSpell("self", 1)
                end 

                if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                    player:castSpell("self", 1)
                end
            end
        end
    end 

    for i=evade.core.skillshots.n, 1, -1 do
        local spell = evade.core.skillshots[i]
        if spell and spell.owner.team == TEAM_ENEMY and spell:contains(player) then 
            local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
            if player:spellSlot(1).state == 0 then 
                if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                    player:castSpell("self", 1)
                end 

                if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                    player:castSpell("self", 1)
                end
            end
        end
    end 
end 

local function OnTick()
    if player.isRecalling or player.isDead then 
        return 
    end 

    if core.on_end_func then
        if os.clock() + network.latency > core.on_end_time then
            core.on_end_func()
        end
    end

    if player:spellSlot(2).cooldown > 0.2 then 
        E_cast = 0
    end

    if player.buff['samirar'] then 
        orb.core.set_pause_attack(math.huge)
    else 
        castR = false
        E_cast = 0
        orb.core.set_pause_attack(0)
    end

    if player.buff['samiraw'] then 
        orb.core.set_pause_attack(math.huge)
    else 
        orb.core.set_pause_attack(0)
    end

    if orb.menu.combat.key:get() then 
        combo()
    end

    if orb.menu.hybrid.key:get() then 
        harass()
    end

    AutoDoged()
end 

local function OnDraw()
    if osTime > 1 then 
        if (player and player.isDead and not player.isTargetable and  player.buff[17]) then 
            return 
        end

        if (not player.isOnScreen) then 
            return 
        end

        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, pred_q1.range, 1, menu.draws.qcolor:get(), 100)
        end
        if (menu.draws.wrange:get()  and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 325, 1, menu.draws.wcolor:get(), 100)
        end
        if (menu.draws.erange:get()  and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 650, 1, menu.draws.ecolor:get(), 100)
        end
        if (menu.draws.r_range:get()  and player:spellSlot(3).state == 0) then
            graphics.draw_circle(player.pos, 600, 1, menu.draws.r:get(), 100)--979561567.
        end 
    end
    osTime = os.clock()
end 

local function on_recv_spell(spell)
    if core.f_spell_map[spell.name] then
        core.f_spell_map[spell.name](spell)
    end

    if spell.name == "SamiraE" then 
        E_cast = os.clock()
    end 

    for _, k in pairs(CCSpells) do
        if menu.combo.wsettings.dodge_spell[k.charName] and menu.combo.wsettings.dodge_spell[k.charName][_] and menu.combo.wsettings.dodge_spell[k.charName][_].Dodge:get() then
            if player:spellSlot(1).state == 0 and common.GetPercentPar() >= menu.combo.wsettings.mana_mngr:get() then
                for i=evade.core.targeted.n, 1, -1 do
                    local spell = evade.core.targeted[i]
                    if spell and spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO and spell.target.ptr == player.ptr and spell.name == _ then 
                        player:castSpell("self", 1)
                    end 
                end

                for i=evade.core.skillshots.n, 1, -1 do
                    local spell = evade.core.skillshots[i]
                    if spell.missile and spell.missile.speed then
                        if spell and spell.owner.team == TEAM_ENEMY and spell:contains(player) and spell.name == _ then  
                            local hit_time = (player.path.serverPos:dist(spell.missile.pos) - player.boundingRadius) / spell.missile.speed
                            if hit_time > (network.latency) and hit_time < (0.25 + network.latency) then 
                                player:castSpell("self", 1)
                            end
                        end 
                    end
                end
            end
        end 
    end
end 

core.f_spell_map["SamiraQ"] = core.on_cast_q
core.f_spell_map["SamiraW"] = core.on_cast_w
core.f_spell_map["SamiraE"] = core.on_cast_e
core.f_spell_map["SamiraR"] = core.on_cast_r


cb.add(cb.spell, on_recv_spell)
cb.add(cb.draw, OnDraw)
orb.combat.register_f_pre_tick(OnTick)