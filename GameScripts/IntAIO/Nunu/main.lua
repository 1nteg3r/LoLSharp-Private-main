local common = module.load('int', 'Library/common');
local dlib = module.load('int', 'Library/damageLib');
--//Internal
local TS = module.internal('TS');
local pred = module.internal("pred");
local orb = module.internal("orb");

local menu = menu("IntnnerNunu", "Int Nunu");
menu:header("xs", "Core");
menu:menu('combo', "Combat Settings");
menu:menu("harass", "Hybrid Settings")
menu:menu("lane", "Clear");
    menu.lane:menu("laneclear", "LaneClear");
        menu.lane.laneclear:slider("LaneClear.Q", "Use Q if hit is greater than", 3, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.W", "Use W if hit is greater than", 5, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.E", "Use E if hit is greater than", 4, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.ManaPercent", "Minimum Health Percent", 60, 0, 100, 1);
        menu.lane.laneclear:slider("Lane.Count", "Min. Enemy in range >= {0}", 1, 1, 5, 1);
    menu.lane:menu("jungle", "JungleClear");
    menu.lane.jungle:boolean("q", "Use Q", true);
    menu.lane.jungle:boolean("w", "Use W", true);
    menu.lane:menu("last", "LastHit");
        menu.lane.last:dropdown('LastHit.Q', 'Use Q', 2, {'Never', 'Smartly', 'Always'});
menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", true)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("rrange", "Draw R Range", false)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)