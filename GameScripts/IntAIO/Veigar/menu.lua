local menu = menu("IntnnerVeigar", "Int Veigar");
--subs menu
menu:header("xs", "Core");
menu:menu("combo", "Combo");
menu.combo:boolean("q", "Use Q", true);
menu.combo:boolean("w", "Use W", true);
menu.combo:dropdown('modew', '^ Use W when:', 2, {'Always', 'Unit CC', 'Never'});
menu.combo:boolean("e", "Use E", true);
menu.combo:boolean("e2", "Use MultPrediction", true);
menu.combo:slider("eradius", "^ Radius: ", 250, 1, 375, 1);
menu.combo.eradius:set('tooltip', 'Default Radius: 250. the lower the value but inside the cage the enemy gets')
menu.combo:boolean("r", "Use R |-> Kill", true);

menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("w", "Use W", false);
menu.harass:dropdown('modew', '^ Use W when:', 1, {'Always', 'Unit CC', 'Never'});
menu.harass:boolean("e", "Use E", false);
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 55, 1, 100, 1);

menu:menu("lane", "Farming");
menu.lane:header("xs", "Wave-Clear");
menu.lane:boolean("q", "Use Q", true);
menu.lane:boolean("w", "Use W", false);
menu.lane:slider("minion", "^ Min. Minions Radius W >=", 3, 1, 5, 1);
menu.lane:slider("Mana", "Minimum Mana Percent >= {0}", 55, 1, 100, 1);
menu.lane:header("xddds", "Jungle-Clear");
menu.lane:menu('jug', "Jungle")
menu.lane.jug:boolean("q", "Use Q", true);
menu.lane.jug:boolean("w", "Use W", true);
menu.lane.jug:slider("Mana", "Minimum Mana Percent >= {0}", 55, 1, 100, 1);
menu.lane:header("dd", "Last-Hit");
menu.lane:menu('last', "LastHit")
menu.lane.last:boolean("w", "Use Q", true);

menu:menu("misc", "Misc");
menu.misc:boolean("kill", "Use killsteal system", true);
menu.misc:boolean("egab", "Use E |-> For Dash", true);

menu:menu("flee", "Flee");
menu.flee:boolean("e", "Use E", true);
menu.flee:keybind("fleeekey", "Flee", 'Z', nil)

menu:menu("ddd", "Display");
menu.ddd:boolean("qd", "Q Range", true);
menu.ddd:boolean("wd", "W Range", false);
menu.ddd:boolean("ed", "E Range", false);
menu.ddd:boolean("rd", "R Range", true);

return menu