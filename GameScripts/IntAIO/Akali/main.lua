local orb = module.internal("orb");
local evade = module.seek('evade');
local pred = module.internal("pred")
local common = module.load(header.id, "Library/common");
local TS = module.load(header.id, "TargetSelector/targetSelector")

local IsPreAttack = false
local predR = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    range = 750,
    delay = 0.25, 
    width = 100, 
    speed = 3000,
    type = 'linear',
    collision = { hero = false, minion = false, wall = false };
}

local predE = { 
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    range = 825,
    delay = 0.25, 
    width = 120, 
    speed = 1800,
    type = 'linear',
    collision = { hero = true, minion = true, wall = true };
}

local predQ = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    range = 500,
    delay = 0.25, 
    width = 20 * (math.pi / 180), 
    speed = math.huge,
    type = 'linear',
    collision = { hero = true, minion = false, wall = true };
}

local menu = menu("IntnnerAkali", "Int Akali");
menu:header("xs", "Core");
TS = TS(menu, 975)
TS:addToMenu()
menu:menu('combo', "Combat Settings");
    menu.combo:boolean('q', 'Use Q', true);
    menu.combo:boolean('w', 'Use W', true);
    menu.combo:boolean('e', 'Use E', true);
    menu.combo:boolean('esave', '^ Use E2', true);
    menu.combo:keybind("Under", " Use Combo UnderTower", nil, "A")
    menu.combo:header('xd', "Misc - Settings")
    menu.combo:boolean('noAA', 'Do not attack during invisible', true);

menu:menu("Ultmate", "Settings - R");
    menu.Ultmate:boolean('r', 'Use R', true);
    menu.Ultmate:dropdown('rmode', 'R Mode', 2, {'Always', 'Only if Killable'});
    menu.Ultmate:header('xd', "Misc - Settings")
    menu.Ultmate:slider("count", "Min. Enemy in range {0}", 1, 1, 5, 1);
    menu.Ultmate:boolean('killsteal', 'Cancel R if Killsteal', true);
    menu.Ultmate:slider("nouseR", "Min. Health of enemy {0} >", 25, 1, 100, 1);

menu:menu("harass", "Harass Settings");
    menu.harass:boolean("q", "Use Q", true);
    menu.harass:boolean("w", "Use W", false);
    menu.harass:slider("mana", "Min. Mana Percent: {0} >", 65, 1, 100, 1);

menu:menu('auto', 'Automatic')
    menu.auto:boolean("EGapcloser", "Use W on hero gapclosing / dashing", true);
    menu.auto.EGapcloser:set("tooltip", "If the enemy is coming towards you")

menu:menu('evade', "Evader")
    menu.evade:boolean("BlockR", "Block evade to R", true);

menu:menu("kill", "KillSteal");
    menu.kill:boolean('q', 'Use Q for KillSteal', true)
    menu.kill:boolean('e', 'Use E for KillSteal', true)
    menu.kill:boolean('useDagger', '^ Killsteal with E or R Smart', true)
    menu.kill:boolean('egab', 'Gap with E or R for Q Killsteal', true)
    
menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", true)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("rrange", "Draw R Range", false)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)

local function IsUnderTowerEnemy(Position) 
    --local obj = obj or player 

    if not Position then 
        return 
    end 

    for i=0, objManager.turrets.size[TEAM_ENEMY] -1 do
        local Tower = objManager.turrets[TEAM_ENEMY][i]

        if Tower.isDead then 
            return 
        end

        if Tower and Tower.isVisible and Tower.health > 0 then 
            if Tower.pos:dist(Position) <= (800 + player.boundingRadius) then 
                return true 
            end 
        end 
    end 
    return false
end 

local function GetClosestMobToEnemy()
	local enemyMinions = common.GetMinionsInRange(1800, TEAM_ENEMY)

	local closestMinion = nil
	local closestMinionDistance = 9999
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
		if enemies and common.IsValidTarget(enemies) then
			local hp = common.GetShieldedHealth("AP", enemies)

			for i, minion in pairs(enemyMinions) do
				if minion then
					local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(enemies) < 500 and minion.buff['akaliemis'] then
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
	local enemyMinions = common.GetMinionsInRange(1800, TEAM_NEUTRAL)

	local closestMinion = nil
	local closestMinionDistance = 9999
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
		if enemies and common.IsValidTarget(enemies) then
			local hp = common.GetShieldedHealth("AP", enemies)

			for i, minion in pairs(enemyMinions) do
				if minion then
					local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(enemies) < 500 and minion.buff['akaliemis'] then
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

local function IsVisibleStealth()
    return player.buff['akaliwstealth']
end 

local function Marked(target)
    return target.buff['akaliemis'] 
end

local function AttackBuffed()
    return player.buff['akalipmaterialvfx']
end 

local function DamageQ(target)
    local damage = 0 
    local ezDmg = {30, 55, 80, 105, 130}

    if not target then 
        return 
    end 

    if player:spellSlot(0).level > 0 then 
        local dmg = ezDmg[player:spellSlot(0).level]
		local ad = (common.GetTotalAD(player) * 0.65)
		local ap = (common.GetTotalAP(player) * .6)
        damage = (dmg + common.CalculatePhysicalDamage(target, ad) + common.CalculateMagicDamage(target, ap))
    end 
    return damage
end 

local function DamageE(target)
    local damage = 0 
    local ezDmgE1 = {50, 85, 120, 155, 190}
    local ezDmgE2 = {100, 170, 240, 310, 380}

    if not target then 
        return 
    end 


    if player:spellSlot(2).name == "AkaliE" then 
        if player:spellSlot(2).level > 0 then 
            local dmg = ezDmgE1[player:spellSlot(2).level]
            local ad = (common.GetTotalAD(player) * 0.35)
            local ap = (common.GetTotalAP(player) * .5)
            damage = (dmg + common.CalculatePhysicalDamage(target, ad) + common.CalculateMagicDamage(target, ap))
        end
    elseif player:spellSlot(2).name == "AkaliEb" then 
        if player:spellSlot(2).level > 0 then 
            local dmg = ezDmgE2[player:spellSlot(2).level]
            local ad = (common.GetTotalAD(player) * .7)
            local ap = (common.GetTotalAP(player) * 1)
            damage = (dmg + common.CalculatePhysicalDamage(target, ad) + common.CalculateMagicDamage(target, ap))
        end
    end 
    return damage 
end 

local function DamageR(target)
    local damage = 0 
    local ezDmgR1 = {125, 225, 325} --BONUS 50
    local ezDmgR2 = {75, 145, 215}

    if not target then 
        return 
    end 


    if player:spellSlot(3).name == "AkaliR" then 
        if player:spellSlot(3).level > 0 then 
            local dmg = ezDmgR1[player:spellSlot(3).level]
            local ad = (common.GetBonusAD(player) * .5)
            damage = (dmg + common.CalculatePhysicalDamage(target, ad))
        end
    elseif player:spellSlot(3).name == "AkaliRb" then 
        if player:spellSlot(3).level > 0 then 
            local dmg = ezDmgR2[player:spellSlot(3).level]
            local ap = (common.GetTotalAP(player) * .3)
            damage = (dmg + common.CalculateMagicDamage(target, ap))
        end
    end 
    return damage 
end 

local function Combo()

    if IsPreAttack and AttackBuffed() then 
        return 
    end 

    if menu.Ultmate.r:get() and player:spellSlot(3).name == "AkaliR" then 
        TS.range = 675
        TS:OnTick()
        local target = TS.target 

        if target and common.isValidTarget(target) then 
            if menu.Ultmate.rmode:get() == 1 then 
                if player:spellSlot(3).state == 0 and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then 
                    local RPosition = player.pos + (target.pos - player.pos):norm() * 675 
                    if not menu.combo.Under:get() then 
                        if not IsUnderTowerEnemy(RPosition) then 
                            player:castSpell('obj', 3, target)
                        end 
                    else 
                        player:castSpell('obj', 3, target)
                    end
                end 
            elseif menu.Ultmate.rmode:get() == 2 then 
                if player:spellSlot(3).state == 0 and common.GetShieldedHealth("ALL", target) < (DamageQ(target) + DamageE(target) + DamageR(target)) then   
                    local RPosition = player.pos + (target.pos - player.pos):norm() * 675 
                    if not menu.combo.Under:get() then 
                        if not IsUnderTowerEnemy(RPosition) then 
                            player:castSpell('obj', 3, target)
                        end 
                    else 
                        player:castSpell('obj', 3, target)
                    end
                end
            end
        end 
    elseif menu.Ultmate.r:get() and player:spellSlot(3).name == "AkaliRb" then 
        TS.range = 750
        TS:OnTick()
        local target = TS.target

        if target and target ~= nil then 

            if menu.Ultmate.rmode:get() == 1 then 
                if player:spellSlot(3).state == 0 then 
                    local RPosition = player.pos + (target.pos - player.pos):norm() * 750 
                    if common.GetPercentHealth(target) > menu.Ultmate.nouseR:get() then  
                        if not menu.combo.Under:get() then 
                            if not IsUnderTowerEnemy(RPosition) then 
                                local seg = pred.linear.get_prediction(predR, target)
                                if seg and seg.startPos:dist(seg.endPos) < 750 then
                                    if not pred.collision.get_prediction(predR, seg, target) then
                                        player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                                    end
                                end
                            end 
                        else 
                            local seg = pred.linear.get_prediction(predR, target)
                            if seg and seg.startPos:dist(seg.endPos) < 750 then
                                if not pred.collision.get_prediction(predR, seg, target) then
                                    player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                                end
                            end
                        end
                    end 
                end 
            elseif menu.Ultmate.rmode:get() == 2 then 
                if player:spellSlot(3).state == 0 then 
                    local RPosition = player.pos + (target.pos - player.pos):norm() * 750 
                    if common.GetShieldedHealth("ALL", target) < (DamageQ(target) + DamageE(target) + DamageR(target)) then  
                        if not menu.combo.Under:get() then 
                            if not IsUnderTowerEnemy(RPosition) then  
                                local seg = pred.linear.get_prediction(predR, target)
                                if seg and seg.startPos:dist(seg.endPos) < 750 then
                                    if not pred.collision.get_prediction(predR, seg, target) then
                                        player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                                    end
                                end
                            end 
                        else 
                            local seg = pred.linear.get_prediction(predR, target)
                            if seg and seg.startPos:dist(seg.endPos) < 750 then
                                if not pred.collision.get_prediction(predR, seg, target) then
                                    player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                                end
                            end
                        end 
                    end 
                end
            end 
        end
    end 

    if menu.combo.e:get() and player:spellSlot(2).name == "AkaliE" then 
        TS.range = 825
        TS:OnTick()
        local target = TS.target

        if target and target ~= nil and not IsVisibleStealth() then 
            if target.pos:dist(player.pos) <= 825 and (AttackBuffed() and player.pos:dist(target.pos) > 525) then 
                local seg = pred.linear.get_prediction(predE, target)
                if seg and seg.startPos:dist(seg.endPos) < 825 then
                    if not pred.collision.get_prediction(predE, seg, target) then
                        player:castSpell("pos", 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end
            elseif target.pos:dist(player.pos) <= 825 and (not AttackBuffed()) then 
                local seg = pred.linear.get_prediction(predE, target)
                if seg and seg.startPos:dist(seg.endPos) < 825 then
                    if not pred.collision.get_prediction(predE, seg, target) then
                        player:castSpell("pos", 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end
            end
        end 
    elseif menu.combo.esave:get() and player:spellSlot(2).name == "AkaliEb" then 
        TS.range = 1800
        TS:OnTick()
        local target = TS.target

        if target and target ~= nil and Marked(target) then 
            --Logic Segurity--

            if player:spellSlot(2).state == 0 and (common.GetPercentHealth(target) < common.GetPercentHealth(player) or #common.CountEnemiesInRange(target.pos, 875) < 2) then
                if not menu.combo.Under:get() then 
                    if not IsUnderTowerEnemy(target) then  
                        player:castSpell("self", 2) 
                    end 
                else 
                    player:castSpell("self", 2) 
                end
            elseif player:spellSlot(2).state == 0 and common.GetShieldedHealth("ALL", target) < (DamageQ(target) + DamageE(target) + DamageR(target)) then  
                if not menu.combo.Under:get() then 
                    if not IsUnderTowerEnemy(target) then  
                        player:castSpell("self", 2) 
                    end 
                else 
                    player:castSpell("self", 2) 
                end
            end
        end 
    end 

    if menu.combo.w:get() and player:spellSlot(1).state == 0 then 
        TS.range = 743
        TS:OnTick()
        local target = TS.target

        if target and target ~= nil and not IsUnderTowerEnemy(player.pos) then 
            if ((target.pos:dist(player) < 250 + 140) or player.mana < player.manaCost0) then

                local VectorPos = player.pos + (target.pos - player.pos):norm() * 250 
                player:castSpell("pos", 1, mousePos) 
            end
        end 
    end

    if menu.combo.q:get() and player:spellSlot(0).state == 0 then 
        TS.range = 525
        TS:OnTick()
        local target = TS.target

        if target and target ~= nil then 
            if target.pos:dist(player.pos) > 120 and player.pos:dist(target.pos) <= 500 then 
                local seg = pred.linear.get_prediction(predQ, target)
                if seg and seg.startPos:dist(seg.endPos) < 500 then
                    if not pred.collision.get_prediction(predQ, seg, target) then
                        player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end
            end 
        end
    end 
end 

local function Harass()
    if common.GetPercentMana(player) >= menu.harass.mana:get() then 
        if menu.harass.q:get() and player:spellSlot(0).state == 0 then 
            TS.range = 525
            TS:OnTick()
            local target = TS.target

            if target and target ~= nil then 
                if target.pos:dist(player.pos) > 120 and player.pos:dist(target.pos) <= 500 then 
                    local seg = pred.linear.get_prediction(predQ, target)
                    if seg and seg.startPos:dist(seg.endPos) < 500 then
                        if not pred.collision.get_prediction(predQ, seg, target) then
                            player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    end
                end 
            end
        end 

        if menu.harass.w:get() and player:spellSlot(1).state == 0 then 
            TS.range = 743
            TS:OnTick()
            local target = TS.target

            if target and target ~= nil and not IsUnderTowerEnemy(player.pos) then 
                if ((target.pos:dist(player) < 250 + 140) or player.mana < player.manaCost0) then

                    local VectorPos = player.pos + (target.pos - player.pos):norm() * 250 

                    player:castSpell("pos", 1, mousePos) 
                end
            end 
        end
    end 
end

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, target in pairs(enemy) do
        if target and common.IsValidTarget(target) and common.IsEnemyMortal(target) then
            if menu.kill.egab:get() then
				if player:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(player) > 560 and vec3(target.x, target.y, target.z):dist(player) < 500 + 1000 - 70 and
				DamageQ(target) - 30 > common.GetShieldedHealth("AP", target) then
					local minion = GetClosestMobToEnemy(target)
					if minion then
						player:castSpell("self", 2)
					end

					local minios = GetClosestJungleEnemy(target)
					if minios then
						player:castSpell("self", 2)
					end
                end
                
                if player:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(player) > 560 and vec3(target.x, target.y, target.z):dist(player) < 500 + 750 - 70 and
                DamageQ(target) - 30 > common.GetShieldedHealth("AP", target) then
                    if player:spellSlot(3).name == "AkaliRb" then 
                        player:castSpell("pos", 3, target.pos)
                    end 
                end 
            end
            
            if player:spellSlot(0).state == 0 and menu.kill.q:get() then
                if target.pos:dist(player) < 500 then 
                    if DamageQ(target) > common.GetShieldedHealth("AP", target) then
                        local seg = pred.linear.get_prediction(predQ, target)
                        if seg and seg.startPos:dist(seg.endPos) < 500 then
                            if not pred.collision.get_prediction(predQ, seg, target) then
                                player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                            end
                        end
                    end
                end 
            end

            if player:spellSlot(2).state == 0 and menu.kill.e:get() then
                if target.pos:dist(player) < 825 and player:spellSlot(2).name == "AkaliE" then 
                    if DamageE(target) > common.GetShieldedHealth("ALL", target) then
                        local seg = pred.linear.get_prediction(predE, target)
                        if seg and seg.startPos:dist(seg.endPos) < 825 then
                            if not pred.collision.get_prediction(predE, seg, target) then
                                player:castSpell("pos", 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
                            end
                        end
                    end
                elseif player:spellSlot(2).name == "AkaliEb" then 
                    if DamageE(target) > common.GetShieldedHealth("ALL", target) then
                        player:castSpell('self', 2)
                    end
                end 

            end
        end 
    end
end 

local function WGabcloser()
    local target_TS = module.internal("TS")
    --common.IsMovingTowards(target, 500)
    local target = target_TS.get_result(function(res, obj, dist)
        if dist <= 800 and obj.path.isActive and obj.path.isDashing then 
            res.obj = obj
            return true
        end
    end).obj
    if target and common.IsValidTarget(target) then
        if common.IsMovingTowards(target, 800)  then 
            local pathStartPos = target.path.point[0]
            local pathEndPos = target.path.point[target.path.count] 
            if pathEndPos:dist(player) <= 500 then 
                if player:spellSlot(1).state == 0 then 
                    player:castSpell('self', 1)
                end
            end
        end
    end
end

local function EGabcloser()
    if player:spellSlot(2).state == 0 then
		for i = 0, objManager.enemies_n - 1 do
			local dasher = objManager.enemies[i]
			if dasher.type == TYPE_HERO and dasher.team == TEAM_ENEMY then
				if
					dasher and common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and
						player.pos:dist(dasher.path.point[1]) < 850
				 then
					if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[0]) then
                        player:castSpell("pos", 2, dasher.path.point2D[1])
					end
				end
			end
		end
	end
end 

local function OnTick()
    if (player.isDead and not player.isTargetable and  player.buff[17]) then 
        return 
    end

    if menu.auto.EGapcloser:get() then 
        WGabcloser()
        EGabcloser()
    end
    KillSteal()

    IsPreAttack = false

    if IsVisibleStealth() and not AttackBuffed() then 
        orb.core.set_pause_attack(math.huge) 
    else 
        orb.core.set_pause_attack(0)
    end

    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    end
    --AkaliEb [E 2]
    --AkaliE [E]
    --AkaliRb 
end 
cb.add(cb.tick, OnTick)

local function OnDrawing()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 500, 1, menu.draws.qcolor:get(), 40)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 250, 1, menu.draws.wcolor:get(), 40)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 825, 1, menu.draws.ecolor:get(), 40)
        end
        if (menu.draws.rrange:get() and player:spellSlot(3).state == 0 and player:spellSlot(3).name == "AkaliR") then
            graphics.draw_circle(player.pos, 675, 1, menu.draws.rcolor:get(), 40)
        end
        if (menu.draws.rrange:get() and player:spellSlot(3).state == 0 and player:spellSlot(3).name == "AkaliRb") then
            graphics.draw_circle(player.pos, 725, 1, menu.draws.rcolor:get(), 40)
        end

        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.combo.Under:get() then
            graphics.draw_text_2D("Use Combo in UnderTower: On", 17, pos.x - 70, pos.y + 18, graphics.argb(255, 255, 255, 255))
        else
            graphics.draw_text_2D("Use Combo in UnderTower: Off", 17, pos.x - 70, pos.y + 18, graphics.argb(255, 255, 255, 255))
        end
    end
end 
cb.add(cb.draw, OnDrawing)

local function OnPreTick()
    IsPreAttack = true 
end 
cb.add(cb.pre_tick, OnPreTick)