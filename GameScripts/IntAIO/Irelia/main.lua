
local common = module.load(header.id, "Library/common")
local ts = module.internal('TS')
local evade = module.seek("evade")
local orb = module.internal("orb")
local gpred = module.internal("pred")

local zero = vec3(0,0,0)

local q = {range = 625}

local w = {
	delay = 0.25,
	width = 120,
	speed = math.huge,
	boundingRadiusMod = 0,
	range = 825
}

local w_parameters = {
	damageDur = 0.75,
	fullDur = 1.5,
	releaseTime = os.clock(),
	last = os.clock(),
	nonMissileCheck = {},
	castTime = {}
}

local e_parameters = {
	e1Pos = zero*1,
	target2 = nil,
	nextCast = os.clock(),
	missileSpeed = 2000,
	delayFloor = 0.625
}

local e = {
	delay = e_parameters.delayFloor,
	width =70, --originally 70
	speed = math.huge,
	boundingRadiusMod = 1,
	range = 900
}



local e_obj = nil
local b = 0
local a = 0

local r = {
	delay = 0.4,
	width = 100, --originally 160
	speed = 2000,
	boundingRadiusMod = 0,
	collision = {hero = true, minion = false},
	range = 700
}

local debugPos = {
	e1Pos = zero,
	e2Pred = zero,
	closest = zero,
	e2Cast = zero,
	targetPosAtCast = zero,
	targetPathEnd = zero,
}

local interruptSpells = {
	"caitlynaceinthehole",
	"drain",
	"crowstorm",
	"karthusfallenone",
	"katarinar",
	"malzaharr",
	"meditate",
	"missfortunebullettime",
	"absolutezero",
	"shenr",
	"gate",
	"warwickr",
	"sionq",
	"jhinr",
	"pantheonrjump",
	"reapthewhirlwind",
	"xerathlocusofpower2",
}

local blockSpells = { --add passives like braum and talon
	["aatroxq"] = {count = 0, priority = "high", delay = 0.55, name = "Aatrox Q Dark Flight", champion = "aatrox"},
	["pulverize"] = {count = 0, priority = "high", delay = 0, name = "Alistar Q Pulverize", champion = "alistar"},
	["headbutt"] = {count = 0, priority = "high", delay = 0, name = "Alistar W Headbutt", champion = "alistar"},
	["bandagetoss"] = {count = 0, priority = "high", delay = 0, name = "Amumu Q Bandage Toss", champion = "amumu"},
	["flashfrost"] = {count = 0, priority = "high", delay = 0, name = "Anivia Q Flash Frost", champion = "anivia"},
	["frostbite"] = {count = 0, priority = "high", delay = 0, name = "Anivia E Frostbite", champion = "anivia"},
	["infernalguardian"] = {count = 0, priority = "high", delay = 0, name = "Annie R Summoner: Tibbers", champion = "annie"},
	["enchantedcrystalarrow"] = {count = 0, priority = "high", delay = 0, name = "Ashe R Enchanted Crystal Arrow", champion = "ashe"},
	["aurelionsolq"] = {count = 0, priority = "high", delay = 0, name = "Aurelion Sol Q Starsurge", champion = "aurelionsol"},
	["aurelionsolr"] = {count = 0, priority = "high", delay = 0, name = "Aurelion Sol R Voice of Light", champion = "aurelionsol"},
	["azirr"] = {count = 0, priority = "high", delay = 0, name = "Azir R Emperor's Divide", champion = "azir"},
	["bardq"] = {count = 0, priority = "high", delay = 0, name = "Bard Q Cosmic Binding", champion = "bard"},
	["powerfistattack"] = {count = 0, priority = "high", delay = 0, name = "Blitzcrank E Power Fist (empowered auto)", champion = "blitzcrank"},
	--["brandq"] = {count = 0, priority = "high", delay = 0}, --check for buff
	["braumbasicattackpassiveoverride"] = {count = 0, priority = "high", delay = 0, name = "Braum P Concussive Bhighs (stun)", champion = "braum"},
	["braumrwrapper"] = {count = 0, priority = "high", delay = 0, name = "Braum R Glacial Fissure", champion = "braum"},
	["caitlynheadshotmissile"] = {count = 0, priority = "high", delay = 0, name = "Caitlyn P Headshot", champion = "caitlyn" },
	["caitlynpiltoverpeacemaker"] = {count = 0, priority = "high", delay = 0, name = "Caitlyn Q Piltover Peacemaker", champion = "caitlyn"},
	["caitlynaceinthehole"] = {count = 0, priority = "high", delay = 1, name = "Caitlyn R Ace in the Hole", champion = "caitlyn" },
	["camilleqattackempowered"] = {count = 0, priority = "high", delay = 0, name = "Camille Q Precision Protocol (2nd auto)", champion = "camille" },
	--["camillew"] = {count = 0, priority = "high", delay = 0, name = "Camille W Tactical Sweep", champion = "camille" }, --check
	["camilleedash2"] = {count = 0, priority = "high", delay = 0, name = "Camille E Hookshot (2nd dash)", champion = "camille" }, --check
	["cassiopeiar"] = {count = 0, priority = "high", delay = 0.4, name = "Cassiopeia R Petrifying Gaze", champion = "cassiopeia" },
	["rupture"] = {count = 0, priority = "high", delay = 1.0, name = "Cho'Gath Q Rupture", champion = "chogath" },
	["phosphorusbomb"] = {count = 0, priority = "high", delay = 0.4, name = "Corki Q Phosphorus Bomb", champion = "corki"},
	["missilebarrage2"] = {count = 0, priority = "high", delay = 0, name = "Corki R Missile Barrage (Big)", champion = "corki"}, --check
	["dariuscleave"] = {count = 0, priority = "high", delay = 0.55, name = "Darius Q Decimate", champion = "darius"},
	["dariusexecute"] = {count = 0, priority = "high", delay = 0, name = "Darius R Noxian Guillotine", champion = "darius"},
	["masochismattack"] = {count = 0, priority = "high", delay = 0, name = "Dr Mundo E Masochism (empowered auto)", champion = "drmundo"},
	["dravendoubleshot"] = {count = 0, priority = "high", delay = 0, name = "Draven E Stand Aside", champion = "draven"},
	["dravenrcast"] = {count = 0, priority = "high", delay = 0, name = "Draven R Whirling Death", champion = "draven"},
	--["ekkow"] = {count = 0, priority = "high", delay = 0, name = "Ekko W Parallel Convergence", champion = "ekko"},
	--["evelynnq"] = {count = 0, priority = "high", delay = 0}, --check for buff
	["ezrealtrueshotbarrage"] = {count = 0, priority = "high", delay = 0, name = "Ezreal R Trueshot Barrage", champion = "ezreal"},
	["terrify"] = {count = 0, priority = "high", delay = 0, name = "Fiddlesticks Q Terrify", champion = "fiddlesticks"},
	--["fizzw"] = {count = 0, priority = "high", delay = 0}, --check
	--fizz r
	--["crowstorm"] = {count = 0, priority = "high", delay = 0}, --check
	["galiow2"] = {count = 0, priority = "high", delay = 0, name = "Galio W Shield of Durand", champion = "galio"}, --check
	["galioe"] = {count = 0, priority = "high", delay = 0, name = "Galio E Justice Punch", champion = "galio"},
	["galior"] = {count = 0, priority = "high", delay = 2.2, name = "Galio R Hero's Entrance", champion = "galio"}, --check
	["parley"] = {count = 0, priority = "high", delay = 0, name = "Gangplank Q Parley", champion = "gangplank"},
	--barrel q
	["garenqattack"] = {count = 0, priority = "high", delay = 0, name = "Garen Q Decisive Strike", champion = "garen"},
	["garenr"] = {count = 0, priority = "high", delay = 0, name = "Garen R Demacian Justice", champion = "garen"},
	--gnar w passive
	["gnarbigw"] = {count = 0, priority = "high", delay = 0.3, name = "Mega Gnar W Wallop", champion = "gnar"},
	["gnarr"] = {count = 0, priority = "high", delay = 0, name = "Mega Gnar R GNAR!", champion = "gnar"},
	["gragase"] = {count = 0, priority = "high", delay = 0, name = "Gragas E Body Slam", champion = "gragas"},
	["gragasr"] = {count = 0, priority = "high", delay = 0, name = "Gragas R Explosive Cask", champion = "gragas"},
	--["graveschargeshot"] = {count = 0, priority = "high", delay = 0, missile = "gravesqreturn", name = "Graves Q End of the Line (return)", champion = "graves"},
	["graveschargeshot"] = {count = 0, priority = "high", delay = 0, name = "Graves R Collateral Damage", champion = "graves"},
	["hecarimrampattack"] = {count = 0, priority = "high", delay = 0, name = "Hecarim E Devastating Charge", champion = "hecarim"},
	["hecarimultmissile"] = {count = 0, priority = "high", delay = 0, name = "Hecarim R Onslaught of Shadows", champion = "hecarim"},
	["heimerdingerturretenergyblast"] = {count = 0, priority = "high", delay = 0.1, name = "Heimerdinger Q/RQ Turret Energy Blast", champion = "heimerdinger"},
	["heimerdingere"] = {count = 0, priority = "high", delay = 0.1, name = "Heimerdinger E/RE CH-2 Electron Storm Grenade", champion = "heimerdinger"},
	["illaoiq"] = {count = 0, priority = "high", delay = 0.55, name = "Illaoi Q Tentacle Smash", champion = "illaoi"},
	["illaoiwattack"] = {count = 0, priority = "high", delay = 0,  name = "Illaoi W Harsh Lesson", champion = "illaoi"},
	--irelia e detonate
	["ireliar"] = {count = 0, priority = "high", delay = 0, name = "Irelia R Vanguard's Edge", champion = "irelia"},
	["ivernq"] = {count = 0, priority = "high", delay = 0, name = "Ivern Q Rootcaller", champion = "ivern"},
	--ivern pet knockup
	["howlinggale"] = {count = 0, priority = "high", delay = 0, name = "Janna Q Howling Gale", champion = "janna"},
	["jarvanivdragonstrike"] = {count = 0, priority = "high", delay = 0, name = "Jarvan IV Q Dragon Strike", champion = "jarvaniv" },
	["jarvanivdragonstrike2"] = {count = 0, priority = "high", delay = 0, name = "Jarvan IV EQ", champion = "jarvaniv"},
	["jarvanivcataclysm"] = {count = 0, priority = "high", delay = 0, name = "Jarvan IV R Cataclysm", champion = "jarvaniv"},
	["jaxempowertwo"] = {count = 0, priority = "high", delay = 0, name = "Jax W Empower", champion = "jax"},
	--jax w + q
	--jax r
	["jayceshockblastmis"] = {count = 0, priority = "high", delay = 0, name = "Jayce Cannon Q Shock Blast", champion = "jayce"},
	["jayceshockblastwallmis"] = {count = 0, priority = "high", delay = 0, name = "Jayce Cannon E+Q Shock Blast (fast)", champion = "jayce"},
	["jaycetotheskies"] = {count = 0, priority = "high", delay = 0, name = "Jayce Hammer Q To the Skies", champion = "jayce"},
	["jinxwmissile"] = {count = 0, priority = "high", delay = 0, name = "Jinx W Zap!", champion = "jinx"},
	["jinxr"] = {count = 0, priority = "high", delay = 0, name = "Jinx R Super Mega Death Rocket!", champion = "jinx"},
	["jhinpassiveattack"] = {count = 0, priority = "high", delay = 0, name = "Jhin P Whisper (4th)", champion = "jhin"},
	--jhin q
	["jhinw"] = {count = 0, priority = "high", delay = 0.4, name = "Jhin W Deadly Flourish", champion = "jhin"}, --check buff
	["jhinrshot"] = {count = 0, priority = "high", delay = 0 , missile = "jhinrshotmis4", name = "Jhin R Curtain Call (4th)", champion = "jhin"},
	--kaisa maybe?
	["karmaq"] = {count = 0, priority = "high", delay = 0 , name = "Karma Q Inner Flame", champion = "karma"},
	["karmaqmissilemantra"] = {count = 0, priority = "high", delay = 0 , name = "Karma Q Inner Flame (Mantra)", champion = "karma"},
	--karma w
	["karthusfallenone"] = {count = 0, priority = "high", delay = 2, name = "Karthus R Requiem", champion = "karthus"},
	["nulllance"] = {count = 0, priority = "high", delay = 0, name = "Kassadin Q Null Sphere", champion = "kassadin"},
	["riftwalk"] = {count = 0, priority = "high", delay = 0.1, name = "Kassadin R Riftwalk", champion = "kassadin"},
	--["katarinar"] = {count = 0, priority = "high", delay = 0},
	--kayn w, r
	["kennenshurikenhurlmissile1"] = {count = 0, priority = "high", delay = 0, name = "Kennen Q Thundering Shuriken", champion = "kennen"},
	--more kennen shit
	["khazixq"] = {count = 0, priority = "high", delay = 0, name = "Kha'Zix Q Taste Their Fear", champion = "khazix"},
	["khazixqlong"] = {count = 0, priority = "high", delay = 0, name = "Kha'Zix Q Taste Their Fear (evolved)", champion = "khazix"},
	--kindred
	--kog r with health check
	--kled q yank
	--kled r damage portion
	--lb e
	--lb q proc
	["blindmonkqtwo"] = {count = 0, priority = "high", delay = 0, name = "Lee Sin Q2 Resonating Strike", champion = "leesin"},
	["blindmonkrkick"] = {count = 0, priority = "high", delay = 0, name = "Lee Sin R Dragon's Rage", champion = "leesin"},
	["leonashieldofdaybreak"] = {count = 0, priority = "high", delay = 0, name = "Leona Q Shield of Daybreak", champion = "leona"},
	["leonazenithblade"] = {count = 0, priority = "high", delay = 0, name = "Leona E Zenith Blade", champion = "leona"},
	["leonasolarflare"] = {count = 0, priority = "high", delay = 0.425, name = "Leona R Solar Flare", champion = "leona"},
	["lissandraq"] = {count = 0, priority = "high", delay = 0, name = "Lissandra Q Ice Shard", champion = "lissandra"},
	["lissandrar"] = {count = 0, priority = "high", delay = 0, name = "Lissandra R Frozen Tomb", champion = "lissandra"},
	["lucianq"] = {count = 0, priority = "high", delay = 0, name = "Lucian Q Piercing Light", champion = "lucian"},
	["luluwtwo"] = {count = 0, priority = "high", delay = 0, name = "Lulu W Polymorph", champion = "lulu"},
	--lulur
	["luxlightbinding"] = {count = 0, priority = "high", delay = 0, name = "Lux Q Light Binding", champion = "lux"},
	["luxmalicecannon"] = {count = 0, priority = "high", delay = 0.9, name = "Lux R Final Spark", champion = "lux"},--test
	["seismicshard"] = {count = 0, priority = "high", delay = 0, name = "Malphite Q Seismic Shard", champion = "malphite"},
	["ufslash"] = {count = 0, priority = "high", delay = 0, name = "Malphite R Unstoppable Force", champion = "malphite"},
	["malzaharr"] = {count = 0, priority = "high", delay = 0, name = "Malzahar R Nether Grasp", champion = "malzahar"},
	["maokaiq"] = {count = 0, priority = "high", delay = 0, name = "Maokai Q Arcane Smash", champion = "maokai"},
	["maokaiw"] = {count = 0, priority = "high", delay = 0, name = "Maokai W Twisted Advance", champion = "maokai"},
	["maokair"] = {count = 0, priority = "high", delay = 0, name = "Maokai R Nature's Grasp", champion = "maokai"}, --test
	["missfortunershotextra"] = {count = 0, priority = "high", delay = 0, name = "Miss Fortune Q Double Up (bounce)", champion = "missfortune"},
	["mordekaiserqattack2"] = {count = 0, priority = "high", delay = 0, name = "Mordekaiser Q Mace of Spades (3rd)", champion = "mordekaiser"},
	["mordekaiserchildrenofthegrave"] = {count = 0, priority = "high", delay = 0, name = "Mordekaiser R Children of the Grave", champion = "mordekaiser"}, --need to test
	["darkbindingmissile"] = {count = 0, priority = "high", delay = 0, name = "Morgana Q Dark Binding", champion = "morgana"},
	--morgana R
	["namiqmissile"] = {count = 0, priority = "high", delay = 0, name = "Nami Q Aqua Prison", champion = "nami"},
	["namirmissile"] = {count = 0, priority = "high", delay = 0, name = "Nami R Tidal Wave", champion = "nami"},
	["nasusqattack"] = {count = 0, priority = "high", delay = 0, name = "Nasus Q Siphoning Strike", champion = "nasus"},
	["nautilusravagestrikeattack"] = {count = 0, priority = "high", delay = 0, name = "Nautilus P Staggering Bhigh", champion = "nautilus"},
	["nautilusanchordrag"] = {count = 0, priority = "high", delay = 0, name = "Nautilus Q Dredge Line", champion = "nautilus"},
	--naut r
	["javelintoss"] = {count = 0, priority = "high", delay = 0, name = "Nidalee Human Q Javelin Toss", champion = "nidalee"},
	["nidaleetakedownattack"] = {count = 0, priority = "high", delay = 0, name = "Nidalee Cougar Q Takedown", champion = "nidalee"},
	--nocturne w
	["iceblast"] = {count = 0, priority = "high", delay = 0, name = "Nunu E Ice Blast", champion = "nunu"},
	["olafaxethrowcast"] = {count = 0, priority = "high", delay = 0, name = "Olaf Q Axe Throw", champion = "olaf"},
	["olafrecklessstrike"] = {count = 0, priority = "high", delay = 0, name = "Olaf E Reckless Swing", champion = "olaf"},
	["orianadissonancecommand"] = {count = 0, priority = "high", delay = 0, name = "Orianna W Command: Dissonance", champion = "orianna"},
	["orianadetonatecommand"] = {count = 0, priority = "high", delay = 0.4, name = "Orianna R Command: Detonate", champion = "orianna"},
	--ornn w
	["ornne"] = {count = 0, priority = "high", delay = 0, name = "Ornn E Searing Charge", champion = "ornn"},
	["ornnrcharge"] = {count = 0, priority = "high", delay = 0, name = "Ornn R Call of the Forge God", champion = "ornn"}, --check
	["pantheonq"] = {count = 0, priority = "high", delay = 0, name = "Pantheon Q Spear Shot", champion = "pantheon"},
	["pantheonw"] = {count = 0, priority = "high", delay = 0 ,name = "Pantheon W Aegis of Zeonia", champion = "pantheon"},
	--pantheon r
	["poppypassiveattack"] = {count = 0, priority = "high", delay = 0, name = "Poppy P Iron Ambassador", champion = "poppy"},
	["poppye"] = {count = 0, priority = "high", delay = 0, name = "Poppy E Steadfast Presence", champion = "poppy"},
	["poppyrspellinstant"] = {count = 0, priority = "high", delay = 0, name = "Poppy R Keeper's Verdict (knockup)", champion = "poppy"},
	["quinnq"] = {count = 0, priority = "high", delay = 0, name = "Quinn Q Blinding Assault", champion = "quinn"},
	["quinne"] = {count = 0, priority = "high", delay = 0, name = "Quinn E Vault", champion = "quinn"},
	["rakanw"] = {count = 0, priority = "high", delay = 0.55, name = "Rakan W Grand Entrance", champion = "rakan"},
	["puncturingtaunt"] = {count = 0, priority = "high", delay = 0, name = "Rammus E Puncturing Taunt", champion = "rammus"},
	["reksaiwburrowed"] = {count = 0, priority = "high", delay = 0, name = "Rek'Sai W Unburrow", champion = "reksai"},
	["reksaie"] = {count = 0, priority = "high", delay = 0, name = "Rek'Sai E Furious Bite", champion = "reksai"},
	["reksairwrapper"] = {count = 0, priority = "high", delay = 0, name = "Rek'Sai R Void Rush", champion = "reksai"},  --check delay
	["renektonexecute"] = {count = 0, priority = "high", delay = 0, name = "Renekton W Ruthless Predator", champion = "renekton"}, --work
	["renektonsuperexecute"] = {count = 0, priority = "high", delay = 0, name = "Renekton W Ruthless Predator (fury)", champion = "renekton"},
	["rengarq"] = {count = 0, priority = "high", delay = 0, name = "Rengar Q Savagery", champion = "rengar"},
	--rengar q empowered
	--riven third q
	["rivenizunablade"] = {count = 0, priority = "high", delay = 0, name = "Riven R Izuna Blade", champion = "riven"},
	["ryzeqwrapper"] = {count = 0, priority = "high", delay = 0, name = "Ryze Q Overload", champion = "ryze"}, --check for e
	["ryzew"] = {count = 0, priority = "high", delay = 0, name = "Ryze W Rune Prison", champion = "ryze"},
	["sejuaniq"] = {count = 0, priority = "high", delay = 0, name = "Sejuani Q Arctic Assault", champion = "sejuani" },
	["sejuanie"] = {count = 0, priority = "high", delay = 0, name = "Sejuani E Permafrost", champion = "sejuani" },
	["sejuanir"] = {count = 0, priority = "high", delay = 0, name = "Sejuani R Glacial Prison", champion = "sejuani" },
	["twoshivpoison"] = {count = 0, priority = "high", delay = 0, name = "Shaco E Two Shiv Poison", champion = "shaco" },
	--shen q autos
	["shene"] = {count = 0, priority = "high", delay = 0, name = "Shen E Shadow Dash", champion = "shen" },
	["shyvanadoubleattack"] = {count = 0, priority = "high", delay = 0, name = "Shyvana Human Q Twin Bite ", champion = "shyvana" },
	["shyvanadoubleattackdragon"] = {count = 0, priority = "high", delay = 0, name = "Shyvana Dragon Q Twin Bite ", champion = "shyvana"},
	["shyvanafireball"] = {count = 0, priority = "high", delay = 0, name = "Shyvana Human E Flame Breath ", champion = "shyvana"},
	["shyvanafireballdragon2"] = {count = 0, priority = "high", delay = 0, name = "Shyvana Dragon E Flame Breath ", champion = "shyvana"},
	["shyvanatransformcast"] = {count = 0, priority = "high", delay = 0, name = "Shyvana R Dragon's Descent", champion = "shyvana"},
	["fling"] = {count = 0, priority = "high", delay = 0, name = "Singed E Fling", champion = "singed"},
	["sionq"] = {count = 0, priority = "high", delay = 0, name = "Sion Q Decimating Smash", champion = "sion"},
	["sione"] = {count = 0, priority = "high", delay = 0, name = "Sion E Roar of the Slayer", champion = "sion"}, --check
	["sionr"] = {count = 0, priority = "high", delay = 0, name = "Sion R Soul Furnace", champion = "sion"},
	["sivirq"] = {count = 0, priority = "high", delay = 0, name = "Sivir Q Boomerang Blade", champion = "sivir"},
	--skarner e auto
	["skarnerimpale"] = {count = 0, priority = "high", delay = 0, name = "Skarner R Impale", champion = "skarner"},
	["sonar"] = {count = 0, priority = "high", delay = 0, name = "Sona R Crescendo", champion = "sona"},
	["swainpdummycast"] = {count = 0, priority = "high", delay = 0, name = "Swain P Ravenous Flock", champion = "swain"},
	["swaine"] = {count = 0, priority = "high", delay = 0,  name = "Swain E Nevermove", champion = "swain"},
	["swainrsoulflare"] = {count = 0, priority = "high", delay = 0, name = "Swain R Demonflare", champion = "swain"},
	["syndraq"] = {count = 0, priority = "high", delay = 0.4, name = "Syndra Q Dark Sphere", champion = "syndra"},
	["syndrawcast"] = {count = 0, priority = "high", delay = 0, name = "Syndra W Force of Will", champion = "syndra"},
	["syndrae"] = {count = 0, priority = "high", delay = 0, name = "Syndra E Scatter of the Weak", champion = "syndra"},
	["syndrar"] = {count = 0, priority = "high", delay = 0, name = "Syndra R Unleashed Power", champion = "syndra"},
	--tahm kench q stun
	--talon passive
	["talonw"] = {count = 0, priority = "high", delay = 0, name = "Talon W", champion = "talon"},
	["talonwmissile"] = {count = 0, priority = "high", delay = 0, name = "Talon W (return)", champion = "talon"},
	["taliyahwvc"] = {count = 0, priority = "high", delay = 0.250, name = "Taliyah W Seismic Shove", champion = "taliyah"},
	["tarice"] = {count = 0, priority = "high", delay = 0.9, name = "Taric E Dazzle", champion = "taric"},
	["blindingdart"] = {count = 0, priority = "high", delay = 0, name = "Taric Q Blinding Dart", champion = "teemo"},
	["threshq"] = {count = 0, priority = "high", delay = 0, name = "Thresh Q Death Sentence", champion = "thresh"},
	["threshe"] = {count = 0, priority = "high", delay = 0, name = "Thresh E Flay", champion = "thresh"},
	--tristana e detonate
	["tristanar"] = {count = 0, priority = "high", delay = 0, name = "Tristana R Buster Shot", champion = "tristana"},
	["trundleq"] = {count = 0, priority = "high", delay = 0, name = "Trundle Q Chomp", champion = "trundle"},
	["bluecardpreattack"] = {count = 0, priority = "high", delay = 0, name = "Twisted Fate W Pick a Card (blue)", champion = "twistedfate"},
	["redcardpreattack"] = {count = 0, priority = "high", delay = 0, name = "Twisted Fate W Pick a Card (red)", champion = "twistedfate"},
	["goldcardpreattack"] = {count = 0, priority = "high", delay = 0, name = "Twisted Fate W Pick a Card (gold)", champion = "twistedfate"},
	["udyrbearstance"] = {count = 0, priority = "high", delay = 0, name = "Udyr E Bear Stance", champion = "udyr"},
	["urgote"] = {count = 0, priority = "high", delay = 0, name = "Urgot E Disdain", champion = "urgot"},
	--block varus w stacks?
	["varusr"] = {count = 0, priority = "high", delay = 0, name = "Varus R Chain of Corruption", champion = "varus"},
	["vaynecondemnmissile"] = {count = 0, priority = "high", delay = 0, name = "Vayne E Condemn", champion = "vayne"}, --wall check
	["veigarbalefulstrike"] = {count = 0, priority = "high", delay = 0, name = "Veigar Q Baleful Strike", champion = "veigar"},
	["veigardarkmatter"] = {count = 0, priority = "high", delay = 1.0, name = "Veigar W Dark Matter", champion = "veigar"},
	["veigareventhorizon"] = {count = 0, priority = "high", delay = 0.3, name = "Veigar E Event Horizon", champion = "veigar"},
	["veigarr"] = {count = 0, priority = "high", delay = 0, name = "Veigar R Primordial Burst", champion = "veigar"},
	["velkoze"] = {count = 0, priority = "high", delay = 0, name = "Vel'Koz E Tectonic Disruption", champion = "velkoz"},
	--velkoz stacks
	["viqmissile"] = {count = 0, priority = "high", delay = 0, name = "Vi Q Vault Breaker", champion = "vi"},
	--vi w proc
	["vir"] = {count = 0, priority = "high", delay = 0, name = "Vi R Assault and Battery", champion = "vi"},
	["viktorgravitonfield"] = {count = 0, priority = "high", delay = 1.3, name = "Viktor W Gravity Field", champion = "viktor"},
	["viktordeathray3"] = {count = 0, priority = "high", delay = 0.3, name = "Viktor E Death Ray (aftershock)", champion = "viktor"},
	--vlad q special
	--vlad r
	["volibearqattack"] = {count = 0, priority = "high", delay = 0, name = "Volibear Q Rolling Thunder", champion = "volibear"},
	--volibear w frenzy
	--warwick q
	["warwickq"] = {count = 0, priority = "high", delay = 0, name = "Warwick Q Jaws of the Beast", champion = "warwick"},
	["warwickr"] = {count = 0, priority = "high", delay = 0, name = "Warwick R Infinite Duress", champion = "warwick"},
	["monkeykingqattack"] = {count = 0, priority = "high", delay = 0, name = "Wukong Q Crushing Bhigh", champion = "monkeyking"},
	["monkeykingspintowin"] = {count = 0, priority = "high", delay = 0, name = "Wukong R Cyclone", champion = "monkeyking"},
	["xayahe"] = {count = 0, priority = "high", delay = 0, name = "Xayah E Bladecaller", champion = "xayah"},
	["xerathmagespear"] = {count = 0, priority = "high", delay = 0, name = "Xerath E Shocking Orb", champion = "xerath"},
	["xinzhaoqthrust3"] = {count = 0, priority = "high", delay = 0, name = "Xin Zhao Q Three Talon Strike (3rd)", champion = "xinzhao"},
	["xinzhaow"] = {count = 0, priority = "high", delay = 0, name = "Xin Zhao W Wind Becomes Lightning", champion = "xinzhao"},
	["xinzhaor"] = {count = 0, priority = "high", delay = 0, name = "Xin Zhao R Crescent Guard", champion = "xinzhao"},
	["yasuoq3w"] = {count = 0, priority = "high", delay = 0, name = "Yasuo Q Steel Tempest (tornado)", champion = "yasuo"},
	["yorickq"] = {count = 0, priority = "high", delay = 0, name = "Yorick Q Last Rites", champion = "yorick"},--check
	["zace"] = {count = 0, priority = "high", delay = 0, name = "Zac E Elastic Slingshot", champion = "zac"},
	["zacr"] = {count = 0, priority = "high", delay = 0.9, name = "Zac R Let's Bounce!", champion = "zac"}, 	--check
	["zedq"] = {count = 0, priority = "high", delay = 0, name = "Zed Q Deadly Shuriken", champion = "zed"},
	["zedr"] = {count = 0, priority = "high", delay = 0.74, name = "Zed R Death Mark", champion = "zed"},
	["ziggsr"] = {count = 0, priority = "high", delay = 0, name = "Ziggs R Mega Inferno Bomb", champion = "ziggs"},
--zilean bomb 2
	["zoeq"] = {count = 0, priority = "high", delay = 0, name = "Zoe Q Paddle Star", champion = "zoe"},
	["zoeqrecast"] = {count = 0, priority = "high", delay = 0, name = "Zoe Q Paddle Star (recast)", champion = "zoe"},
	--zoe e
	["zyraq"] = {count = 0, priority = "high", delay = 0, name = "Zyra Q Deadly Bloom", champion = "zyra" },
	["zyrae"] = {count = 0, priority = "high", delay = 0, name = "Zyra E Grasping Roots", champion = "zyra" },
	["zyrar"] = {count = 0, priority = "high", delay = 0, name = "Zyra R Strangle Thorns", champion = "zyra" },
}

--[[
special cases

Tahm Kench Stun
Talon passive

Rakan Ult
Skarner E Stun
Zilean Q 2nd
Zoe E
]]


local passiveBaseScale = {4, 4, 5, 6, 7, 7, 8, 9, 10, 10, 11, 12, 13, 13, 14, 15, 16, 17}
local passiveADScale = {4}
local PTAScale = { 0.08, 0.08, 0.08, 0.09, 0.09, 0.09, 0.09, 0.10, 0.10, 0.10, 0.10, 0.11, 0.11, 0.11, 0.11, 0.12, 0.12, 0.12 }
local sheenTimer = os.clock()
local inFountain = true
local target = nil
local target2 = nil

local menu = menu("intnnerIreial", "Int - Irelia")
	ts.load_to_menu()
	menu:header("xd", "Core")
	menu:menu("combo", "Combo Settings")
	menu.combo:header("xd", "Q Settings")
	menu.combo:boolean("q", "Use Q", true)
	menu.combo:boolean("qgab", "^~ Q gabcloser", true)
	--menu.combo:boolean("qb", "Don't use if blinded", true)

	menu.combo:header("xd", "W Settings")
	menu.combo:boolean("w3", "Use W", true)
--[[	menu.combo:menu("w", "W Usage")
	local enemyList = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		enemyList[enemy.charName:lower()] = true
	end
	for name, spell in pairs(blockSpells) do
		if enemyList[spell.champion] then
			menu.combo.w:menu(name,spell.name)
			local defaultPriorityList = {"high", "medium", "low", "ignore"}
			local defaultCountList = {0,1,2,3}
			local defaultPriority = 0
			local defaultCount = 0
			for i = 0, 4 do
				if spell.priority == defaultPriorityList[i] then
					defaultPriority = i
				end
				if spell.count == defaultCountList[i] then
					defaultCount = i
				end
			end
			menu.combo.w[name]:dropdown("priority", "Priority",defaultPriority,{"Always","In Combat","Poke","Ignore"})
			menu.combo.w[name]:dropdown("count", "Count",defaultCount,{"Always","Alone or dueling","Near 2 or more enemies","Near 3 or more enemies"})
			menu.combo.w[name]:slider("HP", "HP under",100,1,100,1)
		end
	end
]]
	menu.combo:header("xd", "E Settings")
	menu.combo:dropdown('modegab', 'E Mode:', 2, {'Fast', 'Delay'});
	menu.combo:boolean("e", "Use E", true)

	menu.combo:header("xd", "R Settings")
	menu.combo:boolean("r", "Use R", true)
	menu.combo:slider("rx", "Use R If Enemies >=", 2, 0, 5, 1)
	menu.combo:keybind("r", "Semir-R", "A", nil)

	menu:menu("harass", "Hybrid/Harass Settings")
	menu.harass:header("xd", "Q Settings")
	menu.harass:boolean("q", "Use Q", true)
	menu.harass:header("xd", "E Settings")
	menu.harass:boolean("e", "use E", true)
	menu.harass:slider("Mana", "Min. Mana Percent >= {0} ", 50, 0, 100, 10)

	menu:menu("lc", "Lane Clear Settings")
	menu.lc:boolean("q", "Use Q as Last Hit", true)
	menu.lc:boolean("tower", "Check Turret", true)
	menu.lc:slider("Mana", "Min. Mana Percent >= {0} ", 50, 0, 100, 10)

	menu:header('xdmisc', "Misc Settings")
	menu:keybind("autoq", "Only Q | Mark", nil, 'G')
    menu:keybind("eturret", "Use E under Turret", nil, "T")
    menu:keybind("keyjump", "Flee", 'Z', nil)
	menu:menu("auto", "Killsteal Settings")
	menu.auto:boolean("uks", "Use Gabcloser Killsteal", true)
	menu.auto:boolean("uksq", "Use Q on Killsteal", true)

	menu:menu("draws", "Drawings")
    menu.draws:boolean("q_range", "Draw Q Range", true)
    menu.draws:color("q", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("w_range", "Draw W Range", true)
    menu.draws:color("w", "Q3 Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("e_range", "Draw E Range", true)
    menu.draws:color("e", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("r_range", "Draw R Range", true)
    menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)



local function toVec3(vec2)
	return vec3(vec2.x, game.mousePos.y, vec2.y)
end

local function toVec2(vec3)
	return vec2(vec3.x, vec3.z)
end 

local TargetSelectionNearMouse = function(res, obj, dist)
	if dist < 2000 and obj.pos:dist(game.mousePos) <= 640 then --add mouse check
	  res.obj = obj
	  return true
	end
end

local TargetSelection = function(res, obj, dist)
	if dist <= e.range then
		if target and obj ~= target then
			res.obj = obj
			return true
		end
	end
end

local function count_enemies_in_range(pos, range)
	local enemies_in_range = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

local function UnderTurret(pos)
    if not pos then 
        return 
    end 

    for i=0, objManager.turrets.size[TEAM_ENEMY]-1 do
        local obj = objManager.turrets[TEAM_ENEMY][i]
        if obj and obj.health and obj.health > 0 and common.GetDistanceSqr(obj, pos) <= (915 ^ 2) + player.boundingRadius then
            return true
        end
    end
    return false
end

local last_item_update = 0
local hasSheen = false
local hasTF = false
local hasBOTRK = false
local hasTitanic = false
local hasWitsEnd = false
local hasRecurve = false
local hasGuinsoo = false
local QLevelDamage = {5, 25, 45, 65, 85}
local QMLevelDamage = {55, 75, 95, 115, 135}
function GetQDamage(target)
	if player:spellSlot(0).level > 0 then
		local totalPhysical = 0
		local totalMagical = 0

		if os.clock() > last_item_update then
			hasSheen = false
			hasTF = false
			hasBOTRK = false
			hasTitanic = false
			hasWitsEnd = false
			hasRecurve = false
			hasGuinsoo = false
			for i = 0, 5 do
				if player:itemID(i) == 3078 then
					hasTF = true
				end
				if player:itemID(i) == 3057 then
					hasSheen = true
				end
			end
			last_item_update = os.clock() + 5
		end

		local onhitPhysical = 0
		local onhitMagical = 0

		if hasTF and (os.clock() >= sheenTimer or common.CheckBuff(player, "sheen")) then
			onhitPhysical = 1.75 * player.baseAttackDamage
		end
		if hasSheen and not hasTF and (os.clock() >= sheenTimer or common.CheckBuff(player, "sheen")) then
			onhitPhysical = onhitPhysical + player.baseAttackDamage - 20
		end
	
		local damagewww = 0

		if target.type == TYPE_MINION then
			if target.team == TEAM_ENEMY then
				damagewww =
					(common.CalculatePhysicalDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAD() * .6) + onhitPhysical), player) +
					(common.CalculatePhysicalDamage(target, (43 + 13 * player.levelRef) + common.CalculateMagicDamage(target, onhitMagical, player))))
			else
				damagewww =
					common.CalculatePhysicalDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAD() * .6) + onhitPhysical), player) - 2
			end
		else
			damagewww =
				common.CalculatePhysicalDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAD() * .6) + onhitPhysical), player) - 2 
				+
				common.CalculateMagicDamage(target, onhitMagical, player)
		end
		return damagewww
	end
	return 0
end


local function TraceFilter(seg, obj, spell, slow)
	if spell.range < player.pos2D:dist(seg.endPos) then
		return false
	end
	
	if gpred.trace.linear.hardlock(spell, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(spell, seg, obj) then
		return true
	end
	
	if not slow then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

local function CastQ(target)
	if (menu.eturret:get() or not UnderTurret(target)) then   
		if player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= q.range then
			player:castSpell("obj", 0, target)
		end
	end
end

local function CanKS(obj)
	if obj.type == TYPE_MINION then
		if obj.buff["exaltedwithbaronnashorminion"] then
			return (GetQDamage(obj) * 0.3)-5 > common.GetShieldedHealth("ALL", obj)
		elseif not obj.buff["exaltedwithbaronnashorminion"] then
			return GetQDamage(obj) > common.GetShieldedHealth("ALL", obj)
		end
	else
		return GetQDamage(obj) > common.GetShieldedHealth("ALL", obj)
	end
end

local function CanKS2(obj)
	return GetQDamage(obj) > common.GetShieldedHealth("ALL", obj)
end

local function GetClosestMobKill()
	local enemyMinions = common.GetMinionsInRange(600, TEAM_ENEMY, mousePos)

	local closestMinion = nil
	local closestMinionDistance = 9999

	for i, minion in pairs(enemyMinions) do
		if minion and CanKS(minion) then
			local minionPos = vec3(minion.x, minion.y, minion.z)
			if minionPos:dist(mousePos) < 400 then
				local minionDistanceToMouse = minionPos:dist(mousePos)

				if minionDistanceToMouse < closestMinionDistance then
					closestMinion = minion
					closestMinionDistance = minionDistanceToMouse
				end
			end
		end
	end
	return closestMinion
end

local function GetClosestJungleKill()
	local enemyMinions = common.GetMinionsInRange(600, TEAM_NEUTRAL, mousePos)

	local closestMinion = nil
	local closestMinionDistance = 9999

	for i, minion in pairs(enemyMinions) do
		if minion and CanKS(minion) then
			local minionPos = vec3(minion.x, minion.y, minion.z)
			if minionPos:dist(mousePos) < 400 then
				local minionDistanceToMouse = minionPos:dist(mousePos)

				if minionDistanceToMouse < closestMinionDistance then
					closestMinion = minion
					closestMinionDistance = minionDistanceToMouse
				end
			end
		end
	end
	return closestMinion
end

local function GetClosestMobMark()
	local enemyMinions = common.GetMinionsInRange(600, TEAM_ENEMY, mousePos)

	local closestMinion = nil
	local closestMinionDistance = 9999

	for i, minion in pairs(enemyMinions) do
		if minion and minion.buff["ireliamark"] then
			local minionPos = vec3(minion.x, minion.y, minion.z)
			if minionPos:dist(mousePos) < 400 then
				local minionDistanceToMouse = minionPos:dist(mousePos)

				if minionDistanceToMouse < closestMinionDistance then
					closestMinion = minion
					closestMinionDistance = minionDistanceToMouse
				end
			end
		end
	end
	return closestMinion
end

local function GetClosestJungleMark()
	local enemyMinions = common.GetMinionsInRange(600, TEAM_NEUTRAL, mousePos)

	local closestMinion = nil
	local closestMinionDistance = 9999

	for i, minion in pairs(enemyMinions) do
		if minion and minion.buff["ireliamark"] then
			local minionPos = vec3(minion.x, minion.y, minion.z)
			if minionPos:dist(mousePos) < 400 then
				local minionDistanceToMouse = minionPos:dist(mousePos)

				if minionDistanceToMouse < closestMinionDistance then
					closestMinion = minion
					closestMinionDistance = minionDistanceToMouse
				end
			end
		end
	end
	return closestMinion
end


local function GetBestQ(pos)
	local minDistance = player.pos:dist(pos)
	local minDistObj = nil
	local minionsInRange = common.GetMinionsInRange(q.range, TEAM_ENEMY)
	for i, minion in pairs(minionsInRange) do
		if minion then
			local minionDist = minion.pos:dist(pos)
			if CanKS(minion) or minion.buff["ireliamark"] then
				if  minionDist < minDistance then
					minDistance = minionDist
					minDistObj = minion
				end
			end
		end
	end

	local monstersInRange = common.GetMinionsInRange(q.range, TEAM_NEUTRAL)

	for i, monster in pairs(monstersInRange) do
		if monster then
			local minionDist = monster.pos:dist(pos)
			if CanKS(monster) or monster.buff["ireliamark"] then
				if  minionDist < minDistance then
					minDistance = minionDist
					minDistObj = monster
				end
			end
		end
	end


	local enemiesInRange = common.GetEnemyHeroesInRange(q.range, player.pos)
	for i, enemy in pairs(enemiesInRange) do
		local enemyDist = enemy.pos:dist(pos)
		if CanKS(enemy) or (not menu.autoq:get() and not enemy.buff["ireliamark"]) then
			if enemyDist < minDistance then
				minDistance = enemyDist
				minDistObj = enemy
			end
		end
	end

	if minDistance < player.pos:dist(pos) - 100 then
		return minDistObj
	else
		return nil
	end
end

local function LastHitQ()
	local minionsInRange = common.GetMinionsInRange(q.range, TEAM_ENEMY)
	for i, minion in pairs(minionsInRange) do
		if minion and minion.pos:dist(game.mousePos) <= 640 and CanKS(minion) then
			if menu.lc.tower:get() and not common.IsUnderDangerousTower(minion.pos) then
				CastQ(minion)
			else
				CastQ(minion)
			end
		end
	end
end


local function EvalCount()
	if player.buff["ireliawdefense"] then
		return true
	end
	local enemiesInRange = common.GetEnemyHeroesInRange(q.range*2, player.pos)
	local enemyCount = 0
	for i, enemy in pairs(enemiesInRange) do
		enemyCount = enemyCount + 1
	end
	if enemyCount <= 1 then
		return true
	end
	if enemyCount >= 2 then
		return true
	end
	if enemyCount >= 3 then
		return true
	end
end

local function EvalHP()
	if player.buff["ireliawdefense"] then
		return true
	end
	if common.GetPercentHealth(player) <= 100 then
		return true
	end
end
--[[
function ReceiveSpell(spell) --want to have a list of castTime
	if blockSpells[spell.name:lower()] and not w_parameters.castTime[spell.name:lower()] then
		local dist = spell.endPos and player.path.serverPos:dist(spell.endPos) or nil
		if (spell.target and spell.target.ptr == player.ptr) or dist < player.boundingRadius then
			w_parameters.castTime[spell.name:lower()] = os.clock() + blockSpells[spell.name:lower()].delay
			print("3")
			print(spell.name)
		end
	end
end
]]
local function WBlock()
	if evade then
		for _, spell in pairs(evade.core.active_spells) do
			if type(spell) == "table" and blockSpells[spell.name:lower()] then
				if spell.missile and spell.missile.speed then
					if (spell.polygon and spell.polygon:Contains(player.pos)==1) or (spell.target and spell.target.ptr == player.ptr) then
						local hitTime = (player.pos:dist(spell.missile.pos)-player.boundingRadius)/spell.missile.speed
						if hitTime > 0 and hitTime < 0.10 and EvalCount() and EvalHP() then
							return true
						end
					end
				else
					if ((spell.polygon and spell.polygon:Contains(player.pos)==1) or (spell.target and spell.target.ptr == player.ptr)) and w_parameters.nonMissileCheck[spell.name:lower()] then
						if ((not player.buff["ireliawdefense"] and os.clock() >= w_parameters.nonMissileCheck[spell.name:lower()]) or
						(player.buff["ireliawdefense"] and os.clock() >= w_parameters.nonMissileCheck[spell.name:lower()] - 0.2)) and EvalCount() and EvalHP() then
							return true
						end
					else
						w_parameters.nonMissileCheck[spell.name:lower()] = os.clock() + blockSpells[spell.name:lower()].delay
					end
				end
			end
		end
	end
	--[[local lowest = 10000000
	for i, spell in pairs(w_parameters.castTime) do
		if spell and spell+1 <= os.clock() then
			spell = nil
		end
		if  spell and spell < lowest then
			lowest = spell
		end
	end

	if (not player.buff["ireliawdefense"] and os.clock() >= lowest) or (player.buff["ireliawdefense"] and os.clock() >= lowest - 0.2) then
		return true
	end]]
end

local function CastW1() --spellblock
	if player:spellSlot(1).state == 0 and not player.buff["ireliawdefense"] then
		player:castSpell("pos", 1, game.mousePos)
		w_parameters.last = os.clock()
	end
end

local function CastW2(target)
	if player.buff["ireliawdefense"] then
		local seg = gpred.linear.get_prediction(w, target)
		if seg and TraceFilter(seg, target, w, false) then
			player:castSpell("release", 1, toVec3(seg.endPos))
		end
	end
end

local function RaySetDist(start, path, center, dist)
	local a = start.x - center.x
	local b = start.y - center.y
	local c = start.z - center.z
	local x = path.x
	local y = path.y
	local z = path.z

	local n1 = a*x+ b*y+ c*z
	local n2 = z^2*dist^2-a^2*z^2-b^2*z^2+2*a*c*x*z+2*b*c*y*z+2*a*b*x*y+dist^2*x^2+dist^2*y^2-a^2*y^2-b^2*x^2-c^2*x^2-c^2*y^2
	local n3 = x^2+y^2+z^2

	local r1 = -(n1+math.sqrt(n2))/n3
	local r2= -(n1-math.sqrt(n2))/n3
	local r = math.max(r1,r2)

	return start + r*path

end

local function CastE1(target)
	if player:spellSlot(2).state == 0 then
		if not target.path.isActive then
			if target.pos:dist(player.pos) <= e.range then
				local cast1 = player.pos + (target.pos-player.pos):norm()*e.range
				player:castSpell("pos", 2, cast1)
				e_parameters.e1Pos = cast1
				e_parameters.target2 = target
				e_parameters.nextCast = os.clock() + 0.25
			end

		else
			local pathStartPos = target.path.point[0]
			local pathEndPos = target.path.point[target.path.count]
			local pathNorm = (pathEndPos - pathStartPos):norm()
			local tempPred = common.GetPredictedPos(target, 1.2)

			if tempPred then
				local dist1 = player.pos:dist(tempPred)
				if dist1 <= e.range then
					local dist2 = player.pos:dist(target.pos)
					if dist1<dist2 then
						pathNorm = pathNorm*-1
					end
					local enough = true -- false
					local cast2 = RaySetDist(target.pos, pathNorm, player.pos, e.range)

					--[[
						if target.pos:dist(cast2) >= target.moveSpeed * e_parameters.delayFloor then
							enough = true
						else
							cast2 = RaySetDist(target.pos, -1*pathNorm, player.pos, e.range)
							if target.pos:dist(cast2) >= target.moveSpeed * e_parameters.delayFloor then
								enough = true
							end
						end]]

					if enough then
						player:castSpell("pos", 2, cast2)
						e_parameters.e1Pos = cast2
						e_parameters.nextCast = os.clock() + 0.25
						e_parameters.target2 = target
					end
				end
			end
		end
	end
end

local function MultiE1(target, nextTarget)
	if player:spellSlot(2).state == 0 then
		local target1Pos = common.GetPredictedPos(target, 1.5)
		local target2Pos = common.GetPredictedPos(nextTarget, 1.5)
		if target1Pos and target2Pos and player.pos:dist(target1Pos) <= e.range and player.pos:dist(target2Pos) < e.range then
			local pathNorm = (target1Pos - target2Pos):norm()
			local castPos = RaySetDist(target1Pos, pathNorm, player.pos, e.range)
			player:castSpell("pos", 2, castPos)
			e_parameters.e1Pos = castPos
			e_parameters.nextCast = os.clock() + 0.25
			e_parameters.target2 = nextTarget
		end
	end
end

local function setDebug(target, e2Cast, e2Pred, closest)
	debugPos.e1Pos = e_parameters.e1Pos*1
	debugPos.targetPosAtCast = target.pos*1
	debugPos.targetPathEnd = target.path.point[target.path.count]*1
	debugPos.e2Cast = e2Cast
	debugPos.e2Pred = e2Pred
	debugPos.closest = closest
end


local function resetE()
	e_parameters.e1Pos = zero
 	--e_parameters.nextCast = os.clock() + 0.25
end
--[[
local function nextCast()
	e_parameters.nextCast = os.clock() + 0.25
end--]]


local function CastE2(target)
	if player:spellSlot(2).state == 0 and player:spellSlot(2).name == "IreliaE2" then
	local castMode = 0
		if target.path.isActive and target.path.isDashing then
			local dashPos = gpred.core.project(player.path.serverPos2D, target.path, network.latency + e_parameters.delayFloor,e_parameters.missileSpeed, target.path.dashSpeed)
			if dashPos and player.pos2D:dist(dashPos) <= e.range then
				player:castSpell("pos", 2, toVec3(dashPos))
				--setDebug(target, toVec3(dashPos)*1, toVec3(dashPos)*1,zero)
				resetE()
			end	
		else
			local short1 = false
			local short2 = false
			e.delay = e_parameters.delayFloor + player.pos:dist(target.pos)/e_parameters.missileSpeed
			local seg1 = gpred.linear.get_prediction(e, target, vec2(e_parameters.e1Pos.x,e_parameters.e1Pos.y ))
			local predPos1 = toVec3(seg1.endPos)
			if seg1 and player.pos:dist(predPos1) <= e.range then
				local tempCastPos = zero
				local closest1 = toVec3(mathf.closest_vec_line(player.pos2D, toVec2(e_parameters.e1Pos), toVec2(predPos1)))
				if closest1:dist(player.pos)>e.range or predPos1:dist(e_parameters.e1Pos) > closest1:dist(e_parameters.e1Pos) or closest1:dist(e_parameters.e1Pos) < target.moveSpeed*e_parameters.delayFloor*1.5 then 
					short1 = true
					local pathNorm = (predPos1-e_parameters.e1Pos):norm()
					local extendPos = e_parameters.e1Pos + pathNorm*(predPos1:dist(e_parameters.e1Pos)+target.moveSpeed*e_parameters.delayFloor*1.5)
					if player.pos:dist(extendPos) < e.range then
						tempCastPos = extendPos
					else
						tempCastPos = RaySetDist(e_parameters.e1Pos, pathNorm, player.pos, e.range)
					end
				else
					tempCastPos = closest1
				end
				if tempCastPos and tempCastPos ~= zero then
					e.delay = e_parameters.delayFloor + player.pos:dist(tempCastPos)/e_parameters.missileSpeed
					local seg2 = gpred.linear.get_prediction(e, target, vec2(e_parameters.e1Pos.x,e_parameters.e1Pos.y ))
					local predPos2 = toVec3(seg2.endPos)
					if seg2 and (menu.combo.modegab:get() == 1 or not TraceFilter(seg2, target,e, true)) then
						local castPos = zero
						local closest2 = toVec3(mathf.closest_vec_line(player.pos2D, toVec2(e_parameters.e1Pos), toVec2(predPos2)))
						if closest2:dist(player.pos)>e.range or predPos2:dist(e_parameters.e1Pos) > closest2:dist(e_parameters.e1Pos) or closest2:dist(e_parameters.e1Pos) <target.moveSpeed*e_parameters.delayFloor*1.5 then 
							short2 = true
							local pathNorm = (predPos2-e_parameters.e1Pos):norm()
							local extendPos = e_parameters.e1Pos + pathNorm*(predPos2:dist(e_parameters.e1Pos)+target.moveSpeed*e_parameters.delayFloor*1.5)
							if player.pos:dist(extendPos)<e.range then
								castPos = extendPos
							else
								castPos = RaySetDist(e_parameters.e1Pos, pathNorm, player.pos, e.range)
							end
						else 
							castPos = closest2
						end
						if short1 == short2 then
							player:castSpell("pos", 2, castPos)
							--setDebug(target, castPos*1,predPos2*1, closest2*1)
							resetE()
						end
					end
				end
			end
		end
	end
end

local function Flee()
	if menu.keyjump:get() then
		local target = ts.get_result(TargetSelection).obj
		player:move(vec3(mousePos.x, mousePos.y, mousePos.z))
		if player:spellSlot(0).state == 0 then
			local minion = GetClosestMobKill()
			if minion then
				player:castSpell("obj", 0, minion)
			end
			local jungle = GetClosestJungleKill()
			if jungle then
				player:castSpell("obj", 0, jungle)
			end
			local minionm = GetClosestMobMark()
			if minionm then
				player:castSpell("obj", 0, minionm)
			end
			local junglem = GetClosestJungleMark()
			if junglem then
				player:castSpell("obj", 0, junglem)
			end
		end
	end
end


local function CastR(target)
	if player:spellSlot(3).state == 0 and player.path.serverPos:dist(target.path.serverPos) < 800 then
		local seg = gpred.linear.get_prediction(r, target)
		if seg and seg.startPos:dist(seg.endPos) < 1150 then
			if not gpred.collision.get_prediction(r, seg, target) then
				if TraceFilter(seg, target, r, false) then
					player:castSpell("pos", 3, toVec3(seg.endPos))
				end
			end
		end
	end
end

local function ManualR()
	if player:spellSlot(3).state == 0 then
		player:move((game.mousePos))
		for i = 0, objManager.enemies_n - 1 do
			local enemy = objManager.enemies[i]
			local d = player.path.serverPos:dist(enemy.path.serverPos)
	 		if enemy and common.IsValidTarget(enemy) and d < 800 then
	 			CastR(enemy)
	 		end
	 	end
	end
end


local function AutoInterrupt(spell)
	if player:spellSlot(2).state == 0 and e_parameters.e1Pos == zero then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			for i, interruptable in pairs(interruptSpells) do
				if string.lower(spell.name) == interruptable and common.IsValidTarget(spell.owner) and player.pos:dist(spell.owner.pos) <= e.range then
					CastE1(spell.owner)
				end
			end
		end
	end
	if spell.owner.charName == "Irelia" then
		if spell.name == "IreliaE" then
			a = os.clock() + 0.25
			b = os.clock() + 0.3
		end
		if spell.name == "IreliaE2" then
			--e_parameters.e1Pos = zero	
		end
	end
end

local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		local d = player.path.serverPos:dist(enemy.path.serverPos)
 		if enemy and common.IsValidTarget(enemy) and menu.auto.uks:get() and d <= 625 then
  			if menu.auto.uksq:get() and player:spellSlot(0).state == 0 and d <= 625 then
  				if CanKS2(enemy) then
  					CastQ(enemy)
  				end
	  		end
  		end
 	end
end


local function OnTick()
	target = ts.get_result(TargetSelectionNearMouse).obj
	target2 = ts.get_result(TargetSelection).obj
	local bestQ = nil
	if target and common.IsValidTarget(target) then
		if orb.menu.combat.key:get() then
			if menu.combo.r:get() then
				if (target.pos:dist(player) < 800) then
					local pos = gpred.linear.get_prediction(r, target)
					if pos and pos.startPos:dist(pos.endPos) < 800 and menu.combo.rx:get() <= #count_enemies_in_range(target.pos, 300) then
						player:castSpell("pos", 3, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
					end
				end
			end
		end
	end
	if target and common.IsValidTarget(target) then
		if orb.menu.combat.key:get() or orb.menu.hybrid.key:get() then
			if menu.combo.q:get() and not target.buff["jaxcounterstrike"] then
				if CanKS(target) or target.buff["ireliamark"] then
					CastQ(target)
				end

				if player.pos:dist(target.pos) > player.attackRange + 100 then
					bestQ = GetBestQ(target.pos)
				end
			end
		end
	else
		if orb.menu.combat.key:get() or orb.menu.hybrid.key:get() then
			bestQ = GetBestQ(game.mousePos)
		end
	end

	if orb.menu.combat.key:get() or orb.menu.hybrid.key:get() then
		if bestQ ~= nil then
			CastQ(bestQ)	
		end
	end

	if orb.menu.lane_clear:get() then
		if menu.lc.q:get() then
			if menu.lc.tower:get() then
				LastHitQ()
			else
				LastHitQ()
			end
		end
	end

	if menu.auto.uks:get() then
		KillSteal()
	end
	if menu.combo.r:get() then
		ManualR()
	end

	if menu.keyjump:get() then
		Flee()
	end

	--if player:spellSlot(2).state == 32 and player:spellSlot(2).cooldown >= 4 then e_parameters.e1Pos = zero end
	if a < os.clock() then
		if player:spellSlot(2).name == "IreliaE" and e_parameters.e1Pos == zero then
			if target and common.IsValidTarget(target) and (not target.buff["ireliamark"] or CanKS(target)) then
				if target2 and common.IsValidTarget(target2) then
					if (orb.menu.combat.key:get() or menu.keyjump:get()) then
						MultiE1(target2,target)
					end
				else
					if (orb.menu.combat.key:get() and ((bestQ ~= nil and bestQ.pos:dist(target.pos) < 825) or
					(bestQ == nil and player.pos:dist(target.pos) < 825)))then
						CastE1(target)
					end
				end
			else
				if target2 and common.IsValidTarget(target2) and (not target2.buff["ireliamark"] or CanKS(target2)) then
					CastE1(target2)
				end
			end
		else
			if player:spellSlot(2).name == "IreliaE2" and (orb.menu.combat.key:get() or menu.keyjump:get()) then
				if common.IsValidTarget(e_parameters.target2) and player.pos:dist(e_parameters.target2.pos)<=e.range then
					if not e_parameters.target2.buff["ireliamark"] or not CanKS(e_parameters.target2) or not e_parameters.target2.buff["sivire"] or not e_parameters.target2.buff["nocturneshroudofdarkness"] then
						CastE2(e_parameters.target2)
					end
				else
					if target and common.IsValidTarget(target) then
						if target.buff["ireliamark"] or not CanKS(target) or not target.buff["sivire"] or not target.buff["nocturneshroudofdarkness"] then
							CastE2(target)	
						end
					else
						if target2 and common.IsValidTarget(target2) then
							if target2.buff["ireliamark"] or not CanKS(target2) or not target2.buff["sivire"] or not target2.buff["nocturneshroudofdarkness"] then
								CastE2(target2)
							end
						end
					end
				end
			end
		end
	end

	if menu.combo.w3:get() and WBlock() and not player.buff["ireliawdefense"] then
		CastW1()
	end

	if player.buff["ireliawdefense"] then
		if not (player.buff[5] or player.buff[8] or player.buff[24] or player.buff[11] or player.buff[22] or player.buff[8] or player.buff[21] or
		WBlock()) or os.clock() >= w_parameters.last + w_parameters.fullDur - 0.05 then
			if w_parameters.releaseTime and w_parameters.releaseTime <= os.clock() then
				if target then
					CastW2(target)
				elseif target2 then
					CastW2(target2)
				end
			else
				w_parameters.releaseTime = math.min(os.clock() + 0.2, w_parameters.last + w_parameters.fullDur - 0.05)
			end
		end
	end

	if player:spellSlot(1).state ~= 0 and os.clock()>= w_parameters.last + w_parameters.fullDur then
		w_parameters.nonMissileCheck = {}
	end

end



local function CreateObj(object)
	if object.name == "Blade" and object.team == TEAM_ALLY then
		e_obj = object
		e_parameters.e1Pos = object.pos
	end
	if object and object.pos:dist(player.pos) < 300 and object.name:find("Glow_buf") then
		sheenTimer = os.clock() + 1.7
	end
end

local function DeleteObj(object)
	if e_obj and object.team == TEAM_ALLY and object.ptr == e_obj.ptr then
		e_obj = nil
		e_parameters.e1Pos = zero
	end
end


local function OnDraw()
	if (player and player.isDead and not player.isTargetable and player.buff[17] ~= nil) then return end
    if (player.isOnScreen) then
        if menu.draws.q_range:get() and player:spellSlot(0).level > 0 then
            graphics.draw_circle(player.pos, 600, 1, menu.draws.q:get(), 100)
        end
        --q3
        if menu.draws.w_range:get() and player:spellSlot(1).level > 0 then
            graphics.draw_circle(player.pos, 825, 1, menu.draws.w:get(), 100)
        end
        if menu.draws.e_range:get() and player:spellSlot(2).level > 0 then
            graphics.draw_circle(player.pos, 775, 1, menu.draws.e:get(), 100)
        end
        if menu.draws.r_range:get() and player:spellSlot(3).level > 0 then
            graphics.draw_circle(player.pos, 1000, 1, menu.draws.r:get(), 100)
        end

        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))

        if menu.eturret:get() then
			graphics.draw_text_2D("Q under The Turret: ON", 17, pos.x - 45, pos.y + 30, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Q under The Turret: OFF", 17, pos.x - 45, pos.y + 30, graphics.argb(255, 255, 255, 255))
        end
        
        if menu.autoq:get() then
			graphics.draw_text_2D("Only Mark: ON", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Only Mark: OFF", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
		end --22, 

		if player:spellSlot(0).state == 0 then
			for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
				local minion = objManager.minions[TEAM_ENEMY][i]
				if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and minion.type == TYPE_MINION and minion.pos:dist(player.pos) < 600 + 300 then
					local minionPos = vec3(minion.x, minion.y, minion.z)
					local targets = ts.get_result(TargetSelectionNearMouse).obj
					if (GetQDamage(minion) > minion.health) then
						graphics.draw_circle(minionPos, 50, 2, graphics.argb(255, 255, 255, 255), 100)
						graphics.draw_line(player, minion, 1, graphics.argb(255, 218, 34, 34))
					end
				end
			end
			for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
				local minion = objManager.minions[TEAM_NEUTRAL][i]
				if
					minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
						minion.type == TYPE_MINION and
						minion.pos:dist(player.pos) < 600 + 300
				 then
					local minionPos = vec3(minion.x, minion.y, minion.z)
					local targets = ts.get_result(TargetSelectionNearMouse).obj

					if (GetQDamage(minion) > minion.health) then
						graphics.draw_circle(minionPos, 50, 2, graphics.argb(255, 255, 255, 255), 100)
						graphics.draw_line(player, minion, 1, graphics.argb(255, 218, 34, 34))
					end
				end
			end
		end
	end
	if player:spellSlot(0).state == 0 then
			for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
				local minion = objManager.minions[TEAM_ENEMY][i]
				if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and minion.type == TYPE_MINION and minion.pos:dist(player.pos) < 600 + 300 then
					local minionPos = vec3(minion.x, minion.y, minion.z)
					local targets = ts.get_result(TargetSelectionNearMouse).obj
					if (GetQDamage(minion) > minion.health) then
						graphics.draw_circle(minionPos, 50, 2, graphics.argb(255, 255, 255, 255), 100)
						graphics.draw_line(player, minion, 1, graphics.argb(255, 218, 34, 34))
					end
				end
			end
			for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
				local minion = objManager.minions[TEAM_NEUTRAL][i]
				if
					minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
						minion.type == TYPE_MINION and
						minion.pos:dist(player.pos) < 600 + 300
				 then
					local minionPos = vec3(minion.x, minion.y, minion.z)
					local targets = ts.get_result(TargetSelectionNearMouse).obj

					if (GetQDamage(minion) > minion.health) then
						graphics.draw_circle(minionPos, 50, 2, graphics.argb(255, 255, 255, 255), 100)
						graphics.draw_line(player, minion, 1, graphics.argb(255, 218, 34, 34))
					end
				end
			end
		end
end



cb.add(cb.create_particle, CreateObj)
cb.add(cb.delete_particle, DeleteObj)
cb.add(cb.spell, AutoInterrupt)
cb.add(cb.draw, OnDraw)
orb.combat.register_f_pre_tick(OnTick)
