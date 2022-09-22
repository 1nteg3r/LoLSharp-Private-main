local orb = module.internal("orb");
local pred = module.internal("pred")
local evade = module.seek('evade')
local TS = module.internal("TS")
local common = module.load(header.id, "common");
local damage = module.load(header.id, 'damageLib');

local Feathers = { }
local IsPreAttack = false
--[[
[01:17] Spell name: XayahQ
[01:17] Speed:700
[01:17] Width: 50
[01:17] Time:0.25
[01:17] Animation: 0.25
[01:17] false
[01:17] CastFrame: 0.25044247508049
]]

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

local q_pred_input = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 700,
    width = 50,
    range = 1100,
    collision = { hero = false, minion = false, wall = true },

}

local function trace_filter(Input, seg, obj)
    local totalDelay = (Input.delay + network.latency)

    if seg.startPos:dist(seg.endPos)
            + (totalDelay * obj.moveSpeed)
            + obj.boundingRadius > Input.range then
        return false
    end

    local collision = pred.collision.get_prediction(Input, seg, obj)
    if collision then
        return false
    end

    if pred.trace.linear.hardlock(Input, seg, obj) then
        return true
    end

    if pred.trace.linear.hardlockmove(Input, seg, obj) then
        return true
    end

    local t = obj.moveSpeed / Input.speed

    if pred.trace.newpath(obj, totalDelay, totalDelay + t) then
        return true
    end

    return true
end

local Compute = function(input, seg, obj)
    if input.speed == math.huge then
        input.speed = obj.moveSpeed * 3
    end

    local toUnit = (obj.path.serverPos2D - seg.startPos)

    local cos = obj.direction2D:dot(toUnit:norm())
    local sin = math.abs(obj.direction2D:cross(toUnit:norm()))
    local atan = math.atan(sin, cos)

    local unitVelocity = obj.direction2D * obj.moveSpeed * (1 - cos)
    local spellVelocity = toUnit:norm() * input.speed * (2 - sin)
    local relativeVelocity = (spellVelocity - unitVelocity) * (2 - atan)
    local totalVelocity = (unitVelocity + spellVelocity + relativeVelocity)

    local pos = obj.path.serverPos2D + unitVelocity * (input.delay + network.latency)

    local totalWidth = input.width + obj.boundingRadius

    pos = pos - totalVelocity * (totalWidth / totalVelocity:len())

    local deltaWidth = math.abs(input.width, obj.boundingRadius)
    deltaWidth = deltaWidth * cos + deltaWidth * sin

    local relativeWidth = input.width

    if input.width < obj.boundingRadius then
        relativeWidth = relativeWidth + deltaWidth
    else
        relativeWidth = relativeWidth - deltaWidth
    end

    pos = pos - spellVelocity * (relativeWidth / relativeVelocity:len())
    pos = pos - relativeVelocity * (deltaWidth / spellVelocity:len())

    local toPosition = (pos - seg.startPos)

    local a = unitVelocity:dot(unitVelocity) - spellVelocity:dot(spellVelocity)
    local b = unitVelocity:dot(toPosition) * 2
    local c = toPosition:dot(toPosition)

    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return
    end

    local d = math.sqrt(discriminant)

    local t1 = (2 * c) / (d - b)
    local t2 = (-b - d) / (2 * a)

    return math.min(t1, t2)
end

local real_target_filter = function(input)
    
    local target_filter = function(res, obj, dist)
        if dist > input.range then
            return false
        end

        local seg = pred.linear.get_prediction(input, obj)

        if not seg then
            return false
        end

        res.seg = seg
        res.obj = obj

        if not trace_filter(input, seg, obj) then
            return false
        end

        local t1 = Compute(input, seg, obj)

        if t1 < 0 then
            return false
        end

        res.pos = (pred.core.get_pos_after_time(obj, t1) + seg.endPos) / 2

        local linearTime = (seg.endPos - seg.startPos):len() / input.speed

        local deltaT = (linearTime - t1)
        local totalDelay = (input.delay + network.latency)

        if deltaT < totalDelay then
            return true
        end
        return true
    end
    return
    {
        Result = target_filter,
    }
end

local menu = menu(header.id, "Marksman - Xayah");
menu:header('a1', 'Core');
menu:menu('combo', 'Combo');
menu.combo:menu('qsettings', "Q Settings")
    menu.combo.qsettings:boolean("qcombo", "Use Q", true)
    menu.combo.qsettings:slider("mana_mngr", "Minimum Mana %", 15, 0, 100, 5)
menu.combo:menu('wsettings', "W Settings")
    menu.combo.wsettings:boolean("wcombo", "Use W", true)
    menu.combo.wsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
menu.combo:menu('esettings', "E Settings")
    menu.combo.esettings:boolean("ecombo", "Use E", true)
    menu.combo.esettings:slider("mana_mngr", "Minimum Mana %", 5, 0, 100, 5)
    menu.combo.esettings:header('Another', "Misc Settings")
    menu.combo.esettings:boolean("ecombo", "Use E In Dashing", true)
menu.combo:menu('rsettings', "R Settings")
    menu.combo.rsettings:boolean("rcombo", "Use R", true)
    menu.combo.rsettings:menu("w", "R Evade")
	local enemyList = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		enemyList[enemy.charName:lower()] = true
	end
	for name, spell in pairs(blockSpells) do
		if enemyList[spell.champion] then
			menu.combo.rsettings.w:menu(name,spell.name)
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
			menu.combo.rsettings.w[name]:dropdown("priority", "Priority",defaultPriority,{"Always","In Combat","Poke","Ignore"})
			menu.combo.rsettings.w[name]:dropdown("count", "Count",defaultCount,{"Always","Alone","Near 2 or more enemies","Near 3 or more enemies"})
			menu.combo.rsettings.w[name]:slider("HP", "Min. Health >=", 25 ,1 , 100, 1)
		end
	end
menu:menu("harass", "Harass");
menu.harass:menu('qsettings', "Q Settings")
    menu.harass.qsettings:boolean("Qharass", "Use Q", true)
    menu.harass.qsettings:slider("mana_mngr", "Minimum Mana %", 15, 0, 100, 5)
menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('usee', 'Use E for KillSteal', true)
menu:menu('misc', "Misc");
menu.misc:keybind("autoe", "Auto E", nil, "G")
menu.misc:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 45, 0, 100, 1); 
menu.misc:header('a2a1', 'Allowed champions to use Auto E')
for i=0, objManager.enemies_n-1 do
    local enemy = objManager.enemies[i]
    if enemy then 
        menu.misc:boolean(enemy.charName, "Auto E: " .. enemy.charName, true)
    end
end 
menu:menu('draws', "Drawings");
menu.draws:boolean("qrange", "Draw Q Range", true)
menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
menu.draws:boolean("rrange", "Draw R Range", true)
menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)
menu.draws:boolean("circle", "Circle Feathers", true)
menu.draws:boolean("Fheat", "Line Feathers", true)

local function RootLogic(target, obj)
    if not target then 
        return 
    end 

    if not obj then 
        return 
    end 

    local pred_pos = pred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)

    if not pred_pos then 
        return 
    end 

    if player:spellSlot(2).state == 0 then 

        local myHeroVector = vec3(player.x, player.y, player.z)
        local targetVector = vec3(pred_pos.x, target.y, pred_pos.y)
        local objVector = vec3(obj.x, obj.y, obj.z)

        local distanceToObj = myHeroVector:dist(objVector)
        local endPos = myHeroVector + (objVector - myHeroVector):norm() * distanceToObj


        local point = mathf.closest_vec_line_seg(targetVector, myHeroVector, endPos)
        if point and point:dist(targetVector) < (85 + target.boundingRadius) then
            return true
        end 
    end
    return false
end

local function FeatherCount(target)
    local count = 0

    for i, feather in pairs(Feathers) do
        if feather and RootLogic(target, feather) then
            count = count + 1
        end
    end

    return count
end

local function CanKS(obj)
	if obj.type == TYPE_MINION then
		if obj.buff["exaltedwithbaronnashorminion"] then
			return (damage.GetSpellDamage(3, obj) * 0.3)-5 > common.GetShieldedHealth("ALL", obj)
		elseif not obj.buff["exaltedwithbaronnashorminion"] then
			return (damage.GetSpellDamage(3, obj) > common.GetShieldedHealth("ALL", obj))
		end
	else
		return (damage.GetSpellDamage(3, obj) > common.GetShieldedHealth("ALL", obj))
	end
end

local function EvalPriority(spell)
	if not menu.combo.rsettings.w[spell.name:lower()].priority:get() then
		return false
	end
	local priority = menu.combo.rsettings.w[spell.name:lower()].priority:get()
	if priority == 1 then
		return true
	end
	if priority == 2 then
		if target and (player.pos:dist(target) < player.attackRange + 150  or CanKS(target)) and spell.owner.ptr == target.ptr then
			return true
		end
	end
	if priority == 3 then
		if orb.menu.last_hit.key:get() or orb.menu.lane_clear.key:get() or orb.menu.hybrid:get() and not (target and player.pos:dist(target) < player.attackRange + 150) then
			return true
		end
	end
end

local function EvalCount(spell)
	if not menu.combo.rsettings.w[spell.name:lower()].count:get() then
		return false
	end
	local count = menu.combo.rsettings.w[spell.name:lower()].count:get()
	if count == 1 then
		return true
	end
	local enemiesInRange = common.GetEnemyHeroesInRange(1400, player.pos)
	local enemyCount = 0
	for i, enemy in pairs(enemiesInRange) do
		enemyCount = enemyCount + 1
	end
	if count == 2 and enemyCount <= 1 then
		return true
	end
	if count == 3 and enemyCount >= 2 then
		return true
	end
	if count == 4 and enemyCount >= 3 then
		return true
	end
end

local function EvalHP(spell)
	if not menu.combo.rsettings.w[spell.name:lower()].HP:get() then
		return false
	end
	if common.GetPercentHealth(player) <=menu.combo.rsettings.w[spell.name:lower()].HP:get() then
		return true
	end
end

local function REvade()
    --[[if evade then
		for _, spell in pairs(evade.core.active_spells) do
			if type(spell) == "table" and blockSpells[spell.name:lower()] then
				if spell.missile and spell.missile.speed then
					if (spell.polygon and spell.polygon:Contains(player.pos)==1) or (spell.target and spell.target.ptr == player.ptr) then
						local hitTime = (player.pos:dist(spell.missile.pos)-player.boundingRadius)/spell.missile.speed
						if hitTime > 0 and hitTime < 0.10  and EvalPriority(spell) and EvalCount(spell) and EvalHP(spell) then
							return true
						end
                    end
                end 
            end 
        end 
    end]]
end

local function CountFeatherInSide()
    local count = 0

    for i, feather in pairs(Feathers) do
        if feather then 
            count = count + 1
        end 
    end 
    return count
end

local function CastQ(target, Pred)
    if not target then 
        return 
    end 

    if IsPreAttack then 
        return 
    end 

    if menu.combo.qsettings.qcombo:get() and player:spellSlot(0).state == 0 then 

        if #common.CountEnemiesInRange(player.pos, 400) > 0 then 
            return 
        end 

        if player.pos:dist(target.pos) <= common.GetAARange(player) and orb.core.can_attack() then 
            return 
        end

        player:castSpell('pos', 0, Pred)
    end 
end

local function CastW(target)
    if not target then 
        return 
    end 

    if IsPreAttack then 
        return 
    end 

    if player:spellSlot(0).state == 0 then   
        return 
    end

    if menu.combo.wsettings.wcombo:get() and player:spellSlot(1).state == 0 then     
        if #common.CountEnemiesInRange(player.pos, common.GetAARange(player)) > 0 then 
            player:castSpell('self', 1)
        end 
    end
end 

local function CastE(target)
    if not target then 
        return 
    end 

    if IsPreAttack then 
        return 
    end 

    if player:spellSlot(2).state == 0 then  
        if FeatherCount(target) > 2 then 
            player:castSpell('self', 2)
        end 
    end
end

local function CastR()
    local target = common.GetTarget(99999) 

    if not target then 
        return 
    end 

    --[[if player:spellSlot(3).state == 0 then
        if menu.combo.rsettings.rcombo:get() then 
            if target and target ~= nil and common.IsValidTarget(target) then
                if REvade() then 
                    player:castSpell('pos', 3, target.pos)
                end 
            end 
        end 
    end]]
end 

local function Combo()
    if menu.combo.qsettings.qcombo:get() and player.mana >= (player.manaCost2 + player.manaCost3) then

        local target = TS.get_result(real_target_filter(q_pred_input).Result) 
        if target.obj and target.pos then  
            CastQ(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
        end 

    end 

    if menu.combo.wsettings.wcombo:get() and player.mana >= (player.manaCost2 + player.manaCost0) then

        local target = common.GetTarget(common.GetAARange(player))  
        if target and common.IsValidTarget(target) then 
            CastW(target)
        end 

    end

    if menu.combo.esettings.ecombo:get() and player.mana >= (player.manaCost3) then
        local target = common.GetTarget(2000)  
        if target and common.IsValidTarget(target) then 
            CastE(target)
        end 
    end 
end 

local function Harass()
    if menu.harass.qsettings.Qharass:get() and common.GetPercentMana(player) > menu.harass.qsettings.mana_mngr:get() then 
        local target = TS.get_result(real_target_filter(q_pred_input).Result) 
        if target.obj and target.pos then  
            CastQ(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
        end 
    end 
end 

local function AutoEStun()
    if menu.misc.autoe:get() and common.GetPercentMana(player) >= menu.misc['LaneClear.ManaPercent']:get() then 
        local target = common.GetTarget(4000) 
        if target and common.IsValidTarget(target) then  
            if menu.misc[target.charName] and menu.misc[target.charName]:get() then 
                CastE(target)
            end 
        end 
    end
end

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) and common.IsEnemyMortal(enemies) then

            local DamageQ = damage.GetSpellDamage(2, enemies) * CountFeatherInSide()
            local Hp_hero = common.GetShieldedHealth("AD", enemies)

            if menu.kill.usee:get() and player:spellSlot(2).state == 0 then 
                if (DamageQ > Hp_hero) then 
                    CastE(enemies)
                end 
            end 
        end 
    end

    local target = TS.get_result(real_target_filter(q_pred_input).Result) 
    if target.obj and target.pos and common.IsEnemyMortal(target.obj) then 

        local DamageW = damage.GetSpellDamage(0, target.obj)

        if menu.kill.useQ:get() and player:spellSlot(0).state == 0 then 
            
            if (DamageW > common.GetShieldedHealth("AD", target.obj)) then 
                CastQ(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
            end 

        end 
    end
end

local function OnTick()
if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end 

    IsPreAttack = false

    if player.buff['xayahr'] then 
        orb.core.set_pause_attack(math.huge)
    else 
        orb.core.set_pause_attack(0)
    end  
    
    CastR()
    AutoEStun()
    KillSteal()
    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    end
end 
cb.add(cb.tick, OnTick)

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 1100, 1, menu.draws.qcolor:get(), 40)
        end
        if (menu.draws.rrange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 1000, 1, menu.draws.rcolor:get(), 40)
        end
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.misc.autoe:get() then
			graphics.draw_text_2D("Auto E: On", 16, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Auto E: Off", 16, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
		end
    end
    for i, Feather in pairs(Feathers) do 
        if Feather then 
            if menu.draws.circle:get() then
                graphics.draw_circle(Feather.pos, player.boundingRadius, 1, graphics.argb(255, 145, 70, 197), 30)
            end 
            if menu.draws.Fheat:get() then 
                local Puma = graphics.world_to_screen_xyz(Feather.x, Feather.y, Feather.z)
                local Player = graphics.world_to_screen_xyz(player.x, player.y, player.z)
                graphics.draw_line_2D(Puma.x, Puma.y, Player.x, Player.y, 1, graphics.argb(255, 145, 70, 197))
            end
        end
    end
end 
cb.add(cb.draw, OnDraw);

local function create_particle(obj)
--if obj and obj.name and obj.name:lower():find("xayah") then print("Created "..obj.name) end
    if obj and string.find(obj.name, "Passive_Dagger_indicator8s") then 
        Feathers[obj.ptr] = obj
    end
end 
cb.add(cb.create_particle, create_particle);

local function delete_particle(obj)
    if obj then 
        Feathers[obj.ptr] = nil
    end
end
cb.add(cb.delete_particle, delete_particle);

local function OnPreAttack()
    IsPreAttack = true 
end
orb.combat.register_f_pre_tick(OnPreAttack)