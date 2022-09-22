local prediction = module.load('int', 'prediction');
local orb = module.internal("orb")
local evade = module.seek('evade');
local common = module.load("int", "Library/util");
local TS = module.load("int", "TargetSelector/targetSelector");
local enemies = common.GetEnemyHeroes()

local Q = {
    LastCastTime = 0;
    Range = 0;
    CastRangeGrowthMin = 750;
    CastRangeGrowthMax = 1400;
    CastRangeGrowthStartTime = 0;
    CastRangeGrowthDuration = 1.5;
    CastRangeGrowthEndTime = 3;
}

local W = {
    LastCastTime = 0;
    CastRadiusSecondary = 250;
    CastRadius = 100;  
}

local E = {
    LastCastTime = 0;
    Missile_e = { };
    MissileName = "xerathmagespearmissile";
}

local R = {
    LastCastTime = 0;
    Stack = 0;
    rSupporterText = { }
}

local HasPassive = function()
    return player.buff[string.lower('XerathAscended2OnHit')]
end

local IsChargingQ = function()
    return common.getBuffValid(player, 'XerathArcanopulseChargeUp')
end

local IsCastingR = function()
    return common.getBuffValid(player, 'XerathLocusOfPower2')
end

local rDmg = function(target)
    local damage = 0
    if (player:spellSlot(3).state == 0) or (IsCastingR) then
        damage = common.CalculateMagicDamage(target, ({200, 240, 280})[player:spellSlot(3).level] + common.GetTotalAP()* .43)
    end
    return damage * R.Stack
end

local Floor = function(number) 
    return math.floor((number) * 100) * 0.01
end

local menu = menu("int", "Int Xerath");
TS = TS(menu, 1400, 2)
menu:header("xs", "Core")
TS:addToMenu()
menu:menu('combo', "Combo")
menu.combo:boolean('q', 'Use Q', true);
menu.combo:boolean('w', 'Use W', true);
menu.combo:boolean('e', 'Use E', true);
--Ultimate
menu.combo:menu("ult", "Ultimate")
menu.combo.ult:dropdown('moder', 'Use R Shot', 3, {'Disabled', 'Manual Key (Space)', 'Automatic'});
menu.combo.ult:slider("near", "Near mouse radius", 500, 100, 1500, 1);
menu.combo.ult:boolean('drawnear', "Draw near mouse radius", true);
menu.combo.ult:boolean('rks', "Only select target near mouse", false);
menu.combo.ult:slider("Delay", "Delay R(ms)", 0, 0, 1500, 1);

menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("w", "Use W", false);
menu.harass:boolean("e", "Use E", false);
menu.harass:slider("mana", "Minimum Mana Percent", 20, 0, 100, 1);

menu:menu("misc", "Misc");
menu.misc:boolean("egab", "Use E on hero gapclosing/dashing", true);
menu.misc:boolean("emob", "Use E on hero immobile", true);

menu:menu("dis", "Display");
menu.dis:boolean("qd", "Q Range", true);
menu.dis:boolean("wd", "W Range", false);
menu.dis:boolean("ed", "E Range", false);
menu.dis:boolean("rd", "R Range |-> MousE", true);
menu.dis:boolean("rkill", "Draw text if target is R killable", true);

--cb.create_missile and cb.delete_missile
cb.add(cb.create_missile, function(missile)
    if missile then 
        if missile.name == "XerathMageSpearMissile" then 
            E.Missile_e[missile.ptr] = missile
        end
        --if missile and missile.name and missile.name:lower():find("xerath") then print("Created "..missile.name) end
    end
end)

cb.add(cb.delete_missile, function(missile)
    if missile then 
        E.Missile_e[missile.ptr] = nil
    end
end)

cb.add(cb.spell, function(spell)
    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Xerath" then 
        ---print("Spell name: " ..spell.name);
        if spell.name == "XerathArcanopulseChargeUp" then 
            Q.LastCastTime = game.time;
        end
        if spell.name == "XerathArcaneBarrage2" then 
            W.LastCastTime = game.time;
        end
        if spell.name == "XerathMageSpear" then 
            E.LastCastTime = game.time;
        end 
        if spell.name == "XerathLocusPulse" then 
            R.LastCastTime = game.time;
        end 
    end
end)

local function Combo()
    local target = TS.target
    if target then
        for i, EMissile in pairs(E.Missile_e) do 
            if (EMissile and player.pos:dist(EMissile) <= player.pos:dist(target)) then return end
            if (orb.core.can_attack() and HasPassive() and common.getAARange(target, player)) then return end
        end
        --E
        if menu.combo.e:get() then 
            if player:spellSlot(2).state == 0 then 
                if (player.path.serverPos2D:dist(target.path.serverPos2D) < 1000) then 
                    local Colison = {
                        minion = 0,
                        enemyhero = 1
                    }
                    local castpos, HitChance, pos = prediction.GetBestCastPosition(target, 0.25, 70, 1000, 1600, player, true, Colison, "line")
                    if (HitChance > 0) then
                        player:castSpell("pos", 2, castpos)
                    end
                end
            end
        end
        --W
        if menu.combo.w:get() then
            if player:spellSlot(1).state == 0 then 
                if (player.path.serverPos2D:dist(target.path.serverPos2D) < 1000) then 
                    local castpos, HitChance, pos = prediction.GetBestCastPosition(target, 0.25, 150, 1000, 20, player, false, "circular")
                    if (HitChance > 1) then
                        player:castSpell("pos", 1, castpos)
                    end
                end 
            end
        end
        --Q
        if player:spellSlot(0).state == 0 and target then 
            if (IsChargingQ()) then
                local castpos, HitChance, pos = prediction.GetBestCastPosition(target, 0.0049999998882413, 100, Q.Range - 250+network.latency, 500, player, false, "linear")
                if (HitChance >= 2) then
                    player:castSpell("release", 0, castpos)
                elseif (game.time - Q.LastCastTime >= Q.CastRangeGrowthEndTime * 1000 * 0.85) then
                    player:castSpell("release", 0, castpos)
                end
            else 
                player:castSpell("pos", 0, target.pos)
            end
        end
    end
end 

local function on_tick()
    if (IsChargingQ()) then 
        local percentGrowth = math.max(0, math.min(1, 1000*((game.time - Q.LastCastTime) / 1000 - Q.CastRangeGrowthStartTime) / Q.CastRangeGrowthDuration));
        Q.Range = ((Q.CastRangeGrowthMax - Q.CastRangeGrowthMin) * percentGrowth + Q.CastRangeGrowthMin);
    else 
        Q.Range = Q.CastRangeGrowthMax;
    end

    --Q Rset Time
    if (player:spellSlot(0).state ~= 0) then 
        Q.LastCastTime = 0
    end
    --W Rset Time
    if (player:spellSlot(1).state ~= 0) then 
        W.LastCastTime = 0
    end
    --E Rset Time
    if (player:spellSlot(2).state ~= 0) then 
        E.LastCastTime = 0
    end
    --R Rset Time
    if (player:spellSlot(3).state ~= 0) then 
        R.LastCastTime = 0
    end
    --Stop Evade and Orb 
    local R_isActive, Q_isActive = common.getBuffValid(player, 'XerathLocusOfPower2'), common.getBuffValid(player, 'XerathArcanopulseChargeUp')
    if R_isActive then 
        if (evade) then
            evade.core.set_pause(math.huge)
        end
        orb.core.set_pause_move(math.huge)
        orb.core.set_pause_attack(math.huge)
    else 
        if (evade) then
            evade.core.set_pause(0)
        end
        orb.core.set_pause_move(0)
        orb.core.set_pause_attack(0)
    end
    if Q_isActive then 
        orb.core.set_pause_attack(math.huge)
    else 
        orb.core.set_pause_attack(0)
    end
    --SpellR 
    if player:spellSlot(3).level > 0 then
        if (player:spellSlot(3).level == 1) then
            R.Stack = 3;
        elseif (player:spellSlot(3).level == 2) then 
            R.Stack = 4;
        elseif (player:spellSlot(3).level == 3) then 
            R.Stack = 5;
        end
    end 
    --Combo
    if (orb.combat.is_active()) then 
        if (IsCastingR()) then return end 
        Combo()
    end
    --R Casting
    if (IsCastingR()) then 
        local enemy = common.GetEnemyHeroes()
        for i, target in ipairs(enemy) do
            if target then 
                if (game.time - R.LastCastTime > menu.combo.ult.Delay:get()) then 
                    if (menu.combo.ult.rks:get()) then 
                        if rDmg(target) > common.GetShieldedHealth("AP", target) and player.path.serverPos:dist(target.path.serverPos) < 5000 then 
                            if target.pos:dist(mousePos) < menu.combo.ult.near:get() then 
                                local Speed = player.pos:dist(target.pos) + 500
                                local castpos, HitChance, pos = prediction.GetBestCastPosition(target, 0.5/1000, 150, 5000, Speed, player, false, "circular")
                                if (HitChance > 0) then
                                    player:castSpell("pos", 3, castpos)
                                end
                            end
                        end
                    else 
                        if rDmg(target) > common.GetShieldedHealth("AP", target) and player.path.serverPos:dist(target.path.serverPos) < 5000 then 
                            if target.pos:dist(player.pos) < 5000 then 
                                local Speed = player.pos:dist(target.pos) + 500
                                local castpos, HitChance, pos = prediction.GetBestCastPosition(target, 0.5/1000, 150, 5000, Speed, player, false, "circular")
                                if (HitChance > 0) then
                                    player:castSpell("pos", 3, castpos)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
orb.combat.register_f_pre_tick(on_tick)

cb.add(cb.draw, function()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        graphics.draw_circle(player.pos, Q.Range, 1, graphics.argb(255, 255, 255, 255), 30)
    end
    if menu.dis.rd:get() then 
        graphics.draw_circle(mousePos, menu.combo.ult.near:get(), 1, graphics.argb(255, 255, 255, 255), 30)
    end
    if menu.dis.rkill:get() then
        local enemy = common.GetEnemyHeroes()
        for i, target in ipairs(enemy) do
            if target and player:spellSlot(3).state == 0 and target.isVisible and common.IsValidTarget(target) and not target.buff[17] then
                if target.isOnScreen then 
                    local damage = (rDmg(target))
                    local barPos = target.barPos                   
                    local percentHealthAfterDamage = math.max(0, target.health - damage) / target.maxHealth
                    graphics.draw_line_2D(barPos.x + 165 + 103 * target.health/target.maxHealth, barPos.y+123, barPos.x + 165 + 100 * percentHealthAfterDamage, barPos.y+123, 11,  graphics.argb(90, 255, 169, 4))        
                end 
            end 
        end
    end
end)