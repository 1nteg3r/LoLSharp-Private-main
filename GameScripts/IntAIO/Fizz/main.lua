local orb = module.internal("orb");
local pred = module.internal('pred');
local evade = module.seek('evade');
local TS = module.internal('TS');

local cc_spells = module.load("int", "Core/Fizz/cc_spells");
local damageLib = module.load('int', 'Library/damageLib');
local common = module.load('int', 'Library/util');

local str = {[0] = "Q", [1] = "W", [2] = "E", [3] = "R"}

local ePred = { delay = 0.25, radius = 270, speed = 1000, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local spellr = {
    range = 1300;
    delay = 0.25; 
    width = 150;
    speed = 1300;
    boundingRadiusMod = 1; 
    collision = { hero = true, wall = true };
}

local menu = menu("IntnnerFizz", "Int Fizz");
--subs menu
menu:header("xs", "Core");
menu:menu("combo", "Combo");
menu.combo:dropdown('mode', 'Combo Mode:', 1, {'R |-> E (Gap)', 'R |-> Normal', 'R |-> Q (Gap)'});
menu.combo:boolean("q", "Use Q", true);
menu.combo:dropdown('modeq', '^~ Use Q when:', 1, {'Always', 'Out AA Range'});
menu.combo:boolean("w", "Use W", true);
menu.combo:menu("Eset", "E - Settings");
menu.combo.Eset:boolean("e", "Use E", true);
menu.combo.Eset:boolean("e2", "Use E -> Two for more Damage", true);
--menu.combo.Eset:keybind("egab", "E - Gabclose", nil, "T");
menu.combo.Eset:slider("life", "Min. Health to use E save >= {0}", 100, 1, 100, 1);
menu.combo.Eset:slider("Mana", "Min. Mana Percent >= {0}", 65, 1, 100, 1);
menu.combo.Eset:menu("spell_list", "Spells to E")
for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if str then
        menu.combo.Eset.spell_list:menu(enemy.charName, enemy.charName)
        for i = 0, 3 do
            local slot = str[i]
            if slot then
                menu.combo.Eset.spell_list[enemy.charName]:boolean(slot, ""..enemy.charName.."|-> "..slot, false)
            end
        end
    end
end
menu.combo:menu("Rset", "R - Settings");
menu.combo.Rset:keybind("rets", "Manural - R", nil, "T")
menu.combo.Rset:boolean("r", "Use R", true);
menu.combo.Rset:slider("Min", "Min. Range >= {0}", 455, 1, 1300, 1);
menu.combo.Rset:slider("Max", "Max. Range >= {0}", 1150, 1, 1300, 1);

menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("w", "Use W", true);
menu.harass:boolean("e", "Use E", false);
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 55, 1, 100, 1);

menu:menu("lane", "Farming");
menu.lane:header("xs", "Wave-Clear");
menu.lane:boolean("q", "Use Q", false);
menu.lane:boolean("w", "Use W", true);
menu.lane:boolean("e", "Use E", false);
menu.lane:slider("minion", "Min. Minions Range Percent >=", 3, 1, 5, 1);
menu.lane:slider("Mana", "Minimum Mana Percent >= {0}", 55, 1, 100, 1);
menu.lane:header("xddds", "Jungle-Clear");
menu.lane:menu('jug', "Jungle")
menu.lane.jug:boolean("q", "Use Q", true);
menu.lane.jug:boolean("w", "Use W", true);
menu.lane.jug:boolean("e", "Use E", true);
menu.lane.jug:slider("Mana", "Minimum Mana Percent >= {0}", 55, 1, 100, 1);
menu.lane:header("dd", "Last-Hit");
menu.lane:menu('last', "LastHit")
menu.lane.last:boolean("w", "Use W", true);

menu:menu("misc", "Misc");
menu.misc:boolean("kill", "Use killsteal system", true);

menu:menu("flee", "Flee");
menu.flee:boolean("e", "Use E", true);
menu.flee:keybind("fleeekey", "Flee", 'Z', nil)

menu:menu("ddd", "Display");
menu.ddd:boolean("qd", "Q Range", true);
menu.ddd:boolean("ed", "E Range", false);
menu.ddd:boolean("rd", "R Range", true);


local function Filter_Target(res, obj, dist)
    if dist > 1300 then return end 
    local modecombo = menu.combo.mode:get()
    if #common.CountEnemiesInRange(player.pos, 1300) == 1 and modecombo == 2 then 
        if dist < 550 and player:spellSlot(0).state == 0 then
            res.obj = obj 
            return true 
        elseif dist < 700 and player:spellSlot(2).state == 0 then
            res.obj = obj 
            return true 
        end
    elseif #common.CountEnemiesInRange(player.pos, 1300) >= 1 and (modecombo == 1 or modecombo == 3) then
        local hp = common.GetShieldedHealth("AP", obj)
        local dmgtotal = (damageLib.GetSpellDamage(0, obj) + damageLib.GetSpellDamage(1, obj) + damageLib.GetSpellDamage(2, obj)  + damageLib.GetSpellDamage(3, obj))
        if dist < 1300 and dmgtotal > hp then 
            res.obj = obj 
            return true 
        elseif dist < 1300 then 
            res.obj = obj 
            return true 
        end
    else 
        if player:spellSlot(3).state ~= 0 then 
            if dist > common.GetAARange(player) and dist < 900 then 
                res.obj = obj 
                return true 
            end
        end 
    end
end

local function GetClosestEUnit(pos)
    local distance = 2500000;
    local unit = nil;
    local enemyminion = common.GetMinionsInRange(3000, TEAM_ENEMY)
    for i, minion in ipairs(enemyminion) do
        if minion and common.IsValidTarget(minion) and minion.pos:dist(player.pos) < 550 then 
            local DashEndPod = player.path.serverPos + (minion.path.serverPos - player.path.serverPos):norm() * 550 
            if common.IsUnderDangerousTower(DashEndPod) then return end
            local dist = DashEndPod:dist(pos) 
            if (dist <= distance) then 
                distance = dist;
                unit = minion;
            end
        end
    end
    local enemyMobs = common.GetMinionsInRange(3000, TEAM_NEUTRAL)
    for i, JUNGLE in ipairs(enemyMobs) do
        if JUNGLE and common.IsValidTarget(JUNGLE) and JUNGLE.pos:dist(player.pos) < 550 then 
            local DashEndPod = player.path.serverPos + (JUNGLE.path.serverPos - player.path.serverPos):norm() * 550 
            if common.IsUnderDangerousTower(DashEndPod) then return end
            local dist = DashEndPod:dist(pos) 
            if (dist <= distance) then 
                distance = dist;
                unit = JUNGLE;
            end
        end
    end
    if (unit ~= nil) then return unit end
    local enemy = common.GetEnemyHeroes()
    for i, allies in ipairs(enemy) do
        if allies and common.IsValidTarget(allies) and allies.pos:dist(player.pos) < 550 then 
            local DashEndPod = player.path.serverPos + (allies.path.serverPos - player.path.serverPos):norm() * 550 
            if common.IsUnderDangerousTower(DashEndPod) then return end
            local dist = DashEndPod:dist(pos) 
            if (dist <= distance) then 
                distance = dist;
                unit = allies;
            end
        end
    end
    return unit 
end 


local function GetTarget()
    return TS.get_result(Filter_Target).obj
end

local function trace_filter(seg, obj)
    if seg.startPos:dist(seg.endPos) > spellr.range then return false end

    if pred.trace.linear.hardlock(spellr, seg, obj) then return true end
    if pred.trace.linear.hardlockmove(spellr, seg, obj) then return true end
    if pred.trace.newpath(obj, 0.033, 0.500) then return true end
end

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.ddd.qd:get()) then 
            graphics.draw_circle(player.pos, 550, 1, graphics.argb(255, 96, 186, 211), 30)
        end
        if (player:spellSlot(2).state == 0 and menu.ddd.ed:get()) then 
            graphics.draw_circle(player.pos, 400, 1, graphics.argb(255, 96, 186, 211), 30)
        end
        if (player:spellSlot(3).state == 0 and menu.ddd.rd:get()) then 
            graphics.draw_circle(player.pos, 1300, 1, graphics.argb(255, 96, 186, 211), 30)
        end
        --[[local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.combo.Eset.egab:get() == true then
			graphics.draw_text_2D("E Gapclose: On", 18, pos.x - 30, pos.y + 50, graphics.argb(255,90, 178, 74))
		else
			graphics.draw_text_2D("E Gapclose: Off", 18, pos.x - 30, pos.y + 50, graphics.argb(255, 90, 178, 74))
		end]]
    end
end 

local lastDebugPrint = 0
local function OnProcessSpellCast(spell) 
    if spell and player:spellSlot(2).state == 0 and spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO then
        local owner = spell.owner
        if str then
            local slot = str[spell.slot]
            if slot and menu.combo.Eset.spell_list[owner.charName][slot]:get() then
                if (player.health / player.maxHealth) * 100 <= menu.combo.Eset.life:get() and (player.mana / player.maxMana) * 100 >= menu.combo.Eset.Mana:get() then 
                    local dist_to_spell = spell.endPos and player.pos:dist(spell.endPos) or nil
                    if (spell.target and spell.target.ptr == player.ptr) or (dist_to_spell and dist_to_spell <= (player.boundingRadius*2)) then
                        if player:spellSlot(2).name == "FizzETwo" then return end
                        player:castSpell("pos", 2, mousePos)
                        orb.core.set_server_pause()
                    end
                end
            end 
        end
    end
    if menu.combo.w:get() and orb.combat.is_active() and player:spellSlot(1).state == 0 then
		if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner == player and spell.isBasicAttack and  spell.hasTarget then
			if spell.name:find("BasicAttack") then
				player:castSpell("self", 1)
			end
		end
	end
	if menu.harass.w:get() and orb.menu.hybrid:get() and player:spellSlot(1).state == 0 then
		if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner == player and spell.isBasicAttack and  spell.hasTarget then
			if spell.name:find("BasicAttack") then
				player:castSpell("self", 1)
			end
		end
    end
end

local function Flee() 
    player:move(mousePos)
    if player:spellSlot(2).state == 0 then 
        player:castSpell("pos", 2, mousePos)
    end
end

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
	for i, target in ipairs(enemy) do
        if target and common.IsValidTarget(target) then
            if menu.misc.kill:get() then return end
            local Dist2D = player.path.serverPos2D:dist(target.path.serverPos2D);
            local Dist3D = player.path.serverPos:dist(target.path.serverPos);
            local hp = common.GetShieldedHealth("AP", target)
            if (target.path.serverPos:dist(player.path.serverPos) < 550) then
                if (damageLib.GetSpellDamage(0, target) > hp) and player:spellSlot(0).state == 0  then 
                    player:castSpell("obj", 0, target)
                end 
            end
            if (target.path.serverPos:dist(player.path.serverPos) < 550 + 450) then
                if player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then 
                    if (damageLib.GetSpellDamage(0, target) > hp) then 
                        if (Dist2D > common.GetAARange() or Dist3D > 450) and Dist2D < 1300 then 
                            player:castSpell("pos", 2, target.pos)
                        end
                    end
                end 
            end
        end 
    end
end

local function OnTick()

    --Flee 
    if menu.flee.fleeekey:get() then 
        Flee();
    end

    --KillSteal()
    KillSteal();
end 

local function Combo()
    if (orb.combat.is_active()) then
        local Qcombo = menu.combo.q:get(); --Q Combo
        local Ecombo = menu.combo.Eset.e:get(); --E Combo
        local Rcombo = menu.combo.Rset.r:get(); --R Combo
        local Rmin = menu.combo.Rset.Min:get(); -- ~r min range
        local Rmax = menu.combo.Rset.Max:get(); -- ~r max range
        
        local modecombo = menu.combo.mode:get() --Combo mode

        local target = GetTarget();

        if target and common.IsValidTarget(target) then 
            local Dist2D = player.path.serverPos2D:dist(target.path.serverPos2D);
            local Dist3D = player.path.serverPos:dist(target.path.serverPos);
            if (modecombo == 1) then 
                if Rcombo and player:spellSlot(3).state == 0 and Dist2D < (Rmax - (target.boundingRadius+player.boundingRadius)) and Dist3D > Rmin then 
                    local rpred = pred.linear.get_prediction(spellr, target)
                    if rpred and rpred.startPos:dist(rpred.endPos) < (spellr.range - (target.boundingRadius+player.boundingRadius)) then
                        if not pred.collision.get_prediction(spellr, rpred, target) then 
                            local PosTo2D = player.pos + (target.pos - player.pos):norm() * 1300 
                            if trace_filter(rpred, target) then
                                player:castSpell("pos", 3, vec3(rpred.endPos.x, game.mousePos.y, rpred.endPos.y))
                            end
                        end
                    end
                end
                if target.buff['fizzrslow'] and player:spellSlot(2).state == 0 then 
                    if navmesh.isWall(player.pos) then return end
                    if (Dist2D > common.GetAARange() or Dist3D > 700) and Dist2D < 1300 then 
                        player:castSpell("pos", 2, target.pos)
                    end
                    if (player:spellSlot(2).name == "FizzEBuffer" or player:spellSlot(2).name == "FizzETwo") then
                        local res = pred.circular.get_prediction(ePred, target)
                        if res and res.startPos:dist(res.endPos) < 450 and Dist2D < 450 then
                            if menu.combo.Eset.e2:get() then
                                common.DelayAction(function() player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))end, 0.75)
                            elseif not menu.combo.Eset.e2:get() then
                                player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
                            end
                        end
                    elseif (player:spellSlot(2).name == "FizzEBuffer" or player:spellSlot(2).name == "FizzETwo") then
                        if (Dist2D > common.GetAARange() or Dist3D > 450) and Dist2D < 1300 then 
                            player:castSpell("pos", 2, target.pos)
                           
                        end
                    end
                end
                if Ecombo and player:spellSlot(2).name == "FizzE" then 
                    if player:spellSlot(2).state == 0 and vec3(target.x, target.y, target.z):dist(player) < 700 and target.pos:dist(player.pos) > 400 then
                        player:castSpell("pos", 2, target.pos)
                    end
                elseif (player:spellSlot(2).name == "FizzEBuffer" or player:spellSlot(2).name == "FizzETwo")  then
                    if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (700 * 700) then
                        local res = pred.circular.get_prediction(ePred, target)
                        if res and res.startPos:dist(res.endPos) < 700 then
                            if menu.combo.Eset.e2:get() then
                                common.DelayAction(function() player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))end, 0.75)
                            elseif not menu.combo.Eset.e2:get() then
                                player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
                            end
                        end
                    end
                end
                if Qcombo and  player:spellSlot(0).state == 0 then 
                    local DashEndPod = player.path.serverPos + (target.path.serverPos - player.path.serverPos):norm() * 550 
                    if common.IsUnderDangerousTower(DashEndPod) then return end 
                    if (menu.combo.modeq:get() == 2 and Dist2D > common.GetAARange(player) and Dist3D < 550) then 
                        player:castSpell("obj", 0, target)
                    elseif (menu.combo.modeq:get() == 1 and Dist3D < 550) then 
                        player:castSpell("obj", 0, target)
                    end
                end
            end
            if (modecombo == 2) then 
                if Rcombo and player:spellSlot(3).state == 0 and Dist2D < (Rmax - (target.boundingRadius+player.boundingRadius)) and Dist3D > Rmin then 
                    local rpred = pred.linear.get_prediction(spellr, target)
                    if rpred and rpred.startPos:dist(rpred.endPos) < (spellr.range - (target.boundingRadius+player.boundingRadius)) then
                        if not pred.collision.get_prediction(spellr, rpred, target) then 
                            local PosTo2D = player.pos + (target.pos - player.pos):norm() * 1300 
                            if trace_filter(rpred, target) then
                                player:castSpell("pos", 3, vec3(rpred.endPos.x,  game.mousePos.y, rpred.endPos.y))
                            end
                        end
                    end
                end
                if Qcombo and  player:spellSlot(0).state == 0 then 
                    local DashEndPod = player.path.serverPos + (target.path.serverPos - player.path.serverPos):norm() * 550 
                    if common.IsUnderDangerousTower(DashEndPod) then return end 
                    if (menu.combo.modeq:get() == 2 and Dist2D > common.GetAARange(player) and Dist3D < 550) then 
                        player:castSpell("obj", 0, target)
                    elseif (menu.combo.modeq:get() == 1 and Dist3D < 550) then 
                        player:castSpell("obj", 0, target)
                    end
                end
                if player:spellSlot(2).name == "FizzE"  then 
                    if player:spellSlot(2).state == 0 and vec3(target.x, target.y, target.z):dist(player) < 700 and target.pos:dist(player.pos) > 400 then
                        player:castSpell("pos", 2, target.pos)
                    end
                elseif (player:spellSlot(2).name == "FizzEBuffer" or player:spellSlot(2).name == "FizzETwo")  then
                    if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (700 * 700) then
                        local res = pred.circular.get_prediction(ePred, target)
                        if res and res.startPos:dist(res.endPos) < 700 then
                            if menu.combo.Eset.e2:get() then
                                common.DelayAction(function() player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))end, 0.75)
                            elseif not menu.combo.Eset.e2:get() then
                                player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
                            end
                        end
                    end
                end
            end
            if (modecombo == 3) then  
                if Rcombo and player:spellSlot(3).state == 0 and Dist2D < (Rmax - (target.boundingRadius+player.boundingRadius)) and Dist3D > Rmin then 
                    local rpred = pred.linear.get_prediction(spellr, target)
                    if rpred and rpred.startPos:dist(rpred.endPos) < (spellr.range - (target.boundingRadius+player.boundingRadius)) then
                        if not pred.collision.get_prediction(spellr, rpred, target) then 
                            local PosTo2D = player.pos + (target.pos - player.pos):norm() * 1300 
                            if trace_filter(rpred, target) then
                                player:castSpell("pos", 3, vec3(rpred.endPos.x,  game.mousePos.y, rpred.endPos.y))
                            end
                        end
                    end
                end
                local unit = GetClosestEUnit(target.pos)
                if unit and target.buff['fizzrslow'] then
                    if Dist2D < 550 then return end
                    local DashEndPod = player.path.serverPos + (target.path.serverPos - player.path.serverPos):norm() * 550 
                    if (not (DashEndPod:dist(target.pos) < player.pos:dist(target.pos))) then return end 
                    if common.IsUnderDangerousTower(DashEndPod) then return end
                    --DashingManager.SmartE(targetEgab)
                    if evade and evade.core.is_action_safe(DashEndPod, 20, 0.25) then
                        player:castSpell("obj", 0, unit)
                    end
                elseif Qcombo and  player:spellSlot(0).state == 0 then 
                    local DashEndPod = player.path.serverPos + (target.path.serverPos - player.path.serverPos):norm() * 550 
                    if common.IsUnderDangerousTower(DashEndPod) then return end 
                    if (menu.combo.modeq:get() == 2 and Dist2D > common.GetAARange(player) and Dist3D < 550) then 
                        player:castSpell("obj", 0, target)
                    elseif (menu.combo.modeq:get() == 1 and Dist3D < 550) then 
                        player:castSpell("obj", 0, target)
                    end
                end 
                if player:spellSlot(2).name == "FizzE"  then 
                    if player:spellSlot(2).state == 0 and vec3(target.x, target.y, target.z):dist(player) < 700 and target.pos:dist(player.pos) > 400 then
                        player:castSpell("pos", 2, target.pos)
                    end
                elseif (player:spellSlot(2).name == "FizzEBuffer" or player:spellSlot(2).name == "FizzETwo")  then
                    if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (700 * 700) then
                        local res = pred.circular.get_prediction(ePred, target)
                        if res and res.startPos:dist(res.endPos) < 700 then
                            if menu.combo.Eset.e2:get() then
                                common.DelayAction(function() player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))end, 0.75)
                            elseif not menu.combo.Eset.e2:get() then
                                player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
                            end
                        end
                    end
                end
            end
        end
    end
end

local function Harass()
    if not orb.menu.hybrid:get() then return end 
    local Qcombo = menu.harass.q:get(); --Q Harras
    local Ecombo = menu.harass.e:get(); --E Harass

    local target = GetTarget();

    if target and common.IsValidTarget(target) then 
        local Dist2D = player.path.serverPos2D:dist(target.path.serverPos2D);
        local Dist3D = player.path.serverPos:dist(target.path.serverPos);
        if Ecombo then
            if player:spellSlot(2).name == "FizzE"  then 
                if player:spellSlot(2).state == 0 and vec3(target.x, target.y, target.z):dist(player) < 700 and target.pos:dist(player.pos) > 400 then
                    player:castSpell("pos", 2, target.pos)
                end
            elseif (player:spellSlot(2).name == "FizzEBuffer" or player:spellSlot(2).name == "FizzETwo")  then
                if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (700 * 700) then
                    local res = pred.circular.get_prediction(ePred, target)
                    if res and res.startPos:dist(res.endPos) < 700 then
                        player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
                    end
                end
            end
        end
        if Qcombo and  player:spellSlot(0).state == 0 then 
            local DashEndPod = player.path.serverPos + (target.path.serverPos - player.path.serverPos):norm() * 550 
            if common.IsUnderDangerousTower(DashEndPod) then return end 
            if (Dist2D > common.GetAARange(player) and Dist3D < 550) then 
                player:castSpell("obj", 0, target)
            end
        end 
    end
end

local function LaneClear()
    if menu.lane.e:get() then 
        local minions = objManager.minions
        for a = 0, minions.size[TEAM_ENEMY] - 1 do
            local minion1 = minions[TEAM_ENEMY][a]
            if
                minion1 and minion1.moveSpeed > 0 and minion1.isTargetable and not minion1.isDead and minion1.isVisible and
                    player.path.serverPos:distSqr(minion1.path.serverPos) <= (550 * 550)
             then
                local count = 0
                for b = 0, minions.size[TEAM_ENEMY] - 1 do
                    local minion2 = minions[TEAM_ENEMY][b]
                    if
                        minion2 and minion2.moveSpeed > 0 and minion2.isTargetable and minion2 ~= minion1 and not minion2.isDead and
                            minion2.isVisible and
                            minion2.path.serverPos:distSqr(minion1.path.serverPos) <= (400*400)
                     then
                        count = count + 1
                    end
                    if count >= menu.lane.minion:get() then
                        local seg = pred.circular.get_prediction(ePred, minion1)
                        if seg and seg.startPos:dist(seg.endPos) < 500 then
                            player:castSpell("pos", 2, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
                            break
                        end
                    end
                end
            end
        end
    end
    local enemyminion = common.GetMinionsInRange(3000, TEAM_ENEMY)
    for i, minion in ipairs(enemyminion) do
        if minion and common.IsValidTarget(minion) then 
            if player:spellSlot(0).state == 0 and minion.pos:dist(player.pos) < 550 and menu.lane.q:get() then 
                local DashEndPod = player.path.serverPos + (minion.path.serverPos - player.path.serverPos):norm() * 550 
                if common.IsUnderDangerousTower(DashEndPod) then return end 
                player:castSpell("obj", 0, minion)
            end
            if menu.lane.w:get() and player:spellSlot(1).state == 0 then 
                if minion.pos:dist(player.pos) < common.GetAARange() then
                    if (damageLib.GetSpellDamage(1, minion) >= orb.farm.predict_hp(minion, 0.25+network.latency, true)) then
                        player:castSpell("self", 1)
                        player:attack(minion)
                    end
                end
            end
        end 
    end
end

local function JungleClear()
    if menu.lane.jug.q:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= 550 then
                    player:castSpell("obj", 0, minion)
                end
            end
        end
    end
    if menu.lane.jug.w:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= common.GetAARange() then
                    player:castSpell("self", 1)
                end
            end
        end
    end
    if menu.lane.jug.e:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= 700 then
                    player:castSpell("pos", 2, minion.pos)
                end
            end
        end
    end
end

local function on_game_load()
    Combo();

    if menu.combo.Rset.rets:get() then 
        local target = GetTarget();
        local Rcombo = menu.combo.Rset.r:get(); --R Combo
        local Rmin = menu.combo.Rset.Min:get(); -- ~r min range
        local Rmax = menu.combo.Rset.Max:get(); -- ~r max range
        
        if target and common.IsValidTarget(target) then 
            local Dist2D = player.path.serverPos2D:dist(target.path.serverPos2D);
            local Dist3D = player.path.serverPos:dist(target.path.serverPos);
            if Rcombo and player:spellSlot(3).state == 0 and Dist2D < (Rmax - (target.boundingRadius+player.boundingRadius)) and Dist3D > Rmin then 
                local rpred = pred.linear.get_prediction(spellr, target)
                if rpred and rpred.startPos:dist(rpred.endPos) < (spellr.range - (target.boundingRadius+player.boundingRadius)) then
                    if not pred.collision.get_prediction(spellr, rpred, target) then 
                        local PosTo2D = player.pos + (target.pos - player.pos):norm() * 1300 
                        if trace_filter(rpred, target) then
                            player:castSpell("pos", 3, vec3(rpred.endPos.x,  game.mousePos.y, rpred.endPos.y))
                        end
                    end
                end
            end
        end
    end

    if (player.mana / player.maxMana) * 100 >= menu.harass.Mana:get() then 
        Harass();
    end

    if (orb.menu.lane_clear:get()) then 
        if (player.mana / player.maxMana) * 100 >= menu.lane.Mana:get() then 
            LaneClear();
        end
        if (player.mana / player.maxMana) * 100 >= menu.lane.jug.Mana:get() then 
            JungleClear();
        end
    end

    if (orb.menu.last_hit:get()) then 
        local enemyminion = common.GetMinionsInRange(3000, TEAM_ENEMY)
        for i, minion in ipairs(enemyminion) do
            if minion and common.IsValidTarget(minion) then 
                if menu.lane.last.w:get() and player:spellSlot(1).state == 0 then 
                    if minion.pos:dist(player.pos) < common.GetAARange() then
                        if (damageLib.GetSpellDamage(1, minion) >= orb.farm.predict_hp(minion, 0.25+network.latency, true)) then
                            player:castSpell("self", 1)
                            player:attack(minion)
                        end
                    end
                end
            end 
        end
    end
end

orb.combat.register_f_pre_tick(on_game_load)

cb.add(cb.spell, OnProcessSpellCast);
cb.add(cb.tick, OnTick);
cb.add(cb.draw, OnDraw);