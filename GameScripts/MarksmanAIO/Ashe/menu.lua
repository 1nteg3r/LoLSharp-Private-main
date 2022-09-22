local Common = module.load(header.id, "common");
local menu = menu("marksmanAshe", "Marksman - ".. player.charName)
    menu:menu('combo', 'Combo Settings')
        menu.combo:menu('qsettings', "Q Settings")
            menu.combo.qsettings:boolean("qcombo", "Use Q", true)
            menu.combo.qsettings:slider("mana_mngr", "Minimum Mana %", 10, 0, 100, 5)
        menu.combo:menu('wsettings', "W Settings")
            menu.combo.wsettings:boolean("wcombo", "Use W", true)
            menu.combo.wsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
        menu.combo:menu('esettings', "E Settings")
            menu.combo.esettings:boolean("ecombo", "Use E", true)
        menu.combo:menu('rsettings', "R Settings")
            menu.combo.rsettings:boolean("rcombo", "Use R", true)
            menu.combo.rsettings:slider("Rrange", "Max. R Range", 2150, 1, 5000, 1);
            menu.combo.rsettings:slider("delayed", "Auto R. Min Health to use R", 30, 1, 100, 1);
            menu.combo.rsettings:header('Another', "Misc Settings")
            menu.combo.rsettings:slider("MinTargetsR", "Use R Min. Targets", 2, 1, 5, 1);
            menu.combo.rsettings:menu("blacklist", "Blacklist!")
            for i=0, objManager.enemies_n-1 do
                local enemy = objManager.enemies[i]
                if enemy then 
                    menu.combo.rsettings.blacklist:boolean(enemy.charName, "Do not use R on: " .. enemy.charName, false)
                end
            end
    menu:menu('harass', 'Hybrid/Harass Settings')
        menu.harass:menu('wsettings', "W Settings")
            menu.harass.wsettings:boolean("eharras", "Use W", true)
            menu.harass.wsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
    menu:menu('lane', 'Lane Clear Settings')
        menu.lane:boolean("useQ", "Use Q In Jungle", true)
        --menu.lane:boolean("useW", "Use W", true)
        menu.lane:slider("mana_mngr", "Minimum Mana %", 10, 0, 100, 5)
    menu:header("", "Misc Settings")
       -- menu:keybind("autoe", "Auto E", nil, 'G')
        menu:keybind("semir", "Semi - R", 'T', nil)
        menu:keybind("keyjump", "Flee", 'Z', nil)
        menu:menu('kill', 'KillSteal Settings')
            menu.kill:boolean("wKill", "Use W if KillSteal", true)
            menu.kill:boolean("rKill", "Use R if KillSteal", true)
        menu:menu("fill", "Interruptible Spells")
        for i=0, objManager.enemies_n-1 do
            local enemy = objManager.enemies[i]
            if enemy then 
                local name = string.lower(enemy.charName)
                if enemy and Common.interruptableSpells[name] then
                    for v = 1, #Common.interruptableSpells[name] do
                        local spell = Common.interruptableSpells[name][v]
                        menu.fill:boolean(string.format(tostring(enemy.charName) .. tostring(spell.menuslot)), "Interrupt " .. tostring(enemy.charName) .. " " .. tostring(spell.menuslot), true)
                    end
                end
            end
        end
    menu:menu("draws", "Drawings")
        menu.draws:boolean("q3_range", "Draw W Range", true)
        menu.draws:color("q3", "W Drawing Color", 255, 10, 106, 138)
        menu.draws:boolean("r_range", "Draw R Range", true)
        menu.draws:color("r", "R Drawing Color", 255, 177, 67, 191)

return menu