local orb = module.internal("orb");
local evade = module.seek('evade');
local common = module.load(header.id, "Library/common");
local TS = module.load(header.id, "TargetSelector/targetSelector")
local TargetEd = module.internal("TS")
local pred = module.internal("pred")
local IsPreAttack = false; 
local Dagger = { }

local menu = menu("asdasasdasdasdasdasdasdadsasdads", "Int Katarina");
menu:header("xs", "Core");
TS = TS(menu, 975)
TS:addToMenu()
menu:menu('combo', "Combat Settings");
    menu.combo:dropdown('Combo.Style', 'Select Priority:', 2, {'Q', 'E'});
    menu.combo:boolean('q', 'Use Q', true);
    menu.combo:boolean('w', 'Use W', true);
    menu.combo:boolean('e', 'Use E', true);
    menu.combo:boolean('esave', '^ Save E if no Daggers', false);
    menu.combo:keybind("Under", " Use E UnderTower", nil, "A")
    menu.combo:dropdown('DaggerUse', 'Select Priority Dagger:', 2, {'Never', 'IsLand', 'Always'});

menu:menu("Ultmate", "Settings - R");
    menu.Ultmate:boolean('r', 'Use R', true);
    menu.Ultmate:dropdown('rmode', 'R Mode', 2, {'Always', 'Only if Killable'});
    menu.Ultmate:boolean('Check', 'Dagger check damage', true);
    menu.Ultmate:slider("dagger", "^~ Daggers enough to calculate {0}", 8, 1, 18, 1);
    menu.Ultmate:header('xd', "Misc - Settings")
    menu.Ultmate:slider("count", "Min. Enemy in range {0}", 1, 1, 5, 1);
    menu.Ultmate:boolean('countEnemy', 'Cancel R if there are no enemies', true);
    menu.Ultmate:boolean('killsteal', 'Cancel R if Killsteal', true);
    menu.Ultmate:slider("nouseR", "Min. Health of enemy {0} >", 25, 1, 100, 1);

menu:menu("harass", "Harass");
    menu.harass:boolean("q", "Use Q", true);
    menu.harass:boolean("w", "Use W", true);
    menu.harass:boolean("e", "Use E", true);

menu:menu("lane", "Clear");
    menu.lane:menu("laneclear", "LaneClear");
        menu.lane.laneclear:boolean("q", "Use Q", true);
        menu.lane.laneclear:slider("LaneClear.Q", "Use Q if hit is greater than", 3, 1, 10, 1);
        menu.lane.laneclear:boolean("w", "Use W", true);
        menu.lane.laneclear:slider("LaneClear.W", "Use W if hit is greater than", 5, 1, 10, 1);
        menu.lane.laneclear:boolean("e", "Use E", true);
        menu.lane.laneclear:slider("LaneClear.E", "Use E if hit is greater than", 4, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.ManaPercent", "Minimum Health Percent", 60, 0, 100, 1);
        menu.lane.laneclear:slider("Lane.Count", "Min. Enemy in range >= {0}", 1, 1, 5, 1);
    menu.lane:menu("jungle", "JungleClear");
    menu.lane.jungle:boolean("q", "Use Q", true);
    menu.lane.jungle:boolean("w", "Use W", true);
    menu.lane:menu("last", "LastHit");
        menu.lane.last:dropdown('LastHit.Q', 'Use Q', 2, {'Never', 'Smartly', 'Always'});

menu:menu('auto', 'Automatic')
    menu.auto:boolean("EGapcloser", "Use W on hero gapclosing / dashing", true);
    menu.auto.EGapcloser:set("tooltip", "If the enemy is coming towards you")

menu:menu('evade', "Evader")
    menu.evade:boolean("BlockR", "Block evade to R", true);

menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useE', 'Use E for KillSteal', true)
    menu.kill:boolean('useDagger', '^ Killsteal with E Dagger', true)
    menu.kill:boolean('egab', 'Gap with E for Q Killsteal', true)

menu:menu('misc', "Misc")
    menu.misc:keybind("autoq", "Auto Q", nil, "G")
    menu.misc:header('a2a1', 'Allowed champions to use Auto Q')
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy then 
            menu.misc:boolean(enemy.charName, "Auto Q: " .. enemy.charName, true)
        end
    end 
    menu.misc:menu('flee', "Flee")
    menu.misc.flee:boolean('fleeE', 'Use E to Flee', true)
    menu.misc.flee:boolean('dagger', '^~ Dagger to Flee', true)
    menu.misc.flee:boolean('fleew', 'Use W to Flee', true)
    menu.misc.flee:keybind("keyFlee", "^ Hot-Key Flee", "Z", nil)

menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", true)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("rrange", "Draw R Range", false)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)
    menu.draws:header('xd', "Misc - Settings")
    menu.draws:boolean("DrawDadagger", "Draw Dagger", true)


local function RotatingIsGood()
    for i, buff in pairs(player.buff) do 
        if buff and buff.valid and string.lower(buff.name) == "katarinarsound" then
            return (buff.endTime - game.time) * 1000
        end 
    end 
    return 0 
end 

local function size()
	local count = 0
	for _ in pairs(Dagger) do
		count = count + 1
	end
	return count
end

local function GetClosestJungle()
	local enemyMinions = common.GetMinionsInRange(725, TEAM_NEUTRAL, mousePos)

	local closestMinion = nil
	local closestMinionDistance = 9999

	for i, minion in pairs(enemyMinions) do
		if minion then
			local minionPos = vec3(minion.x, minion.y, minion.z)
			if minionPos:dist(mousePos) < 200 then
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

local function GetClosestMob()
	local enemyMinions = common.GetMinionsInRange(725, TEAM_ENEMY, mousePos)

	local closestMinion = nil
	local closestMinionDistance = 9999

	for i, minion in pairs(enemyMinions) do
		if minion then
			local minionPos = vec3(minion.x, minion.y, minion.z)
			if minionPos:dist(mousePos) < 200 then
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
					if minionPos:dist(enemies) < 625 then
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
					if minionPos:dist(enemies) < 625 then
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

local function GetMinionsHit(Pos, radius, range)
    local count = 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and minion.pos:dist(player) <= range and common.GetDistance(minion, Pos) < radius then
			count = count + 1
		end
	end
	return count
end


local function CalcMagicDmg(target, amount, from)
	local from = from or player
	local target = target or orb.combat.target
	local amount = amount or 0
	local targetMR = target.spellBlock * math.ceil(from.percentMagicPenetration) - from.flatMagicPenetration
	local dmgMul = 100 / (100 + targetMR)
	if dmgMul < 0 then
		dmgMul = 2 - (100 / (100 - common.MagicalReduction(target, from)))
	end
	amount = amount * dmgMul
	return math.floor(amount)
end


local function DamageVoracity(target)
    local PDamages = {68, 72, 77, 82, 89, 96, 103, 112, 121, 131, 142, 154, 166, 180, 194, 208, 224, 240}
	local damage = 0
    local leveldamage = 0
    
    if not target then 
        return 
    end

	if (player.levelRef >= 1 and player.levelRef < 6) then
		leveldamage = 0.55
	end
	if (player.levelRef >= 6 and player.levelRef < 11) then
		leveldamage = 0.7
	end
	if (player.levelRef >= 11 and player.levelRef < 16) then
		leveldamage = 0.85
	end
	if (player.levelRef >= 16) then
		leveldamage = 1
	end
	for _, objs in pairs(Dagger) do
		if objs then
			if target.pos:dist(objs.pos) < 450 then
				local damage = 0
				if player.levelRef <= 18 then
					damage = CalcMagicDmg(target, (PDamages[player.levelRef] + common.GetBonusAD() + (common.GetTotalAP() * leveldamage)))
				end
				if player.levelRef > 18 then
					damage = CalcMagicDmg(target, (PDamages[18] + common.GetBonusAD() + (common.GetTotalAP() * leveldamage)))
				end
				return damage
			end
		end
	end
	return damage
end

local ElvlDmg = {15, 30, 45, 60, 75}
local function EDamage(target)
	local damage = 0
	if player:spellSlot(2).level > 0 then
		damage =
			CalcMagicDmg(
			target,
			(ElvlDmg[player:spellSlot(2).level] + ((common.GetTotalAD() / 2) * .5) + (common.GetTotalAP() * .25)) - 10
		)
	end
	return damage
end

local RlvlDmg = {25, 37.5, 50}
local function RDamage(target)
	local damage = 0
	if player:spellSlot(3).level > 0 then
		damage =
			CalcMagicDmg(
			target,
			(RlvlDmg[player:spellSlot(3).level] --[[Potato Code]] + ((common.GetBonusAD() - common.GetTotalAD() / 2) * .22) +
				(common.GetTotalAP() * .19))
		)
	end
	return damage * 8
end

local QLevelDamage = {70, 105, 135, 165, 195}
local function QDamage(target)
	local damage = 0
	if player:spellSlot(0).level > 0 then
		damage =
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .3)), player)
	end
	return damage
end

local function Combo()

    if RotatingIsGood() and RotatingIsGood() > 0 then 
        if menu.Ultmate.countEnemy:get() then 
            if #common.CountEnemiesInRange(player.pos, 550 + 25) == 0 then 
                player:move(mousePos)
            end 
        end 
    end



    if RotatingIsGood() and RotatingIsGood() > 0 then 
        return 
    end 

    if menu.combo['Combo.Style']:get() == 1 then --Q Priority
        if menu.combo.q:get() then 

            TS.range = 625
            TS:OnTick()
            local target = TS.target

            if target and target ~= nil then 
                if (not IsPreAttack or not orb.core.can_attack()) and (target.pos2D:dist(player.pos2D) <= 625 and player:spellSlot(0).state == 0) then 
                    player:castSpell("obj", 0, target)
                end 
            end
        end

        if menu.combo.e:get() and player:spellSlot(2).state == 0 then 

            TS.range = 800
            TS:OnTick()
            local target = TS.target

            if target and target ~= nil then 

                if not menu.combo.esave:get() then 
                    for i, Object in pairs(Dagger) do   
                        if Object then 
                            local DaggerPos = Object.pos + (target.pos - Object.pos):norm() * 200

                            if menu.combo.DaggerUse:get() == 2 then 
                                if target.pos:dist(player.pos) <= common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.StartDagger <= game.time then
                                    if (not IsPreAttack or not orb.core.can_attack()) and Object.pos:dist(player) > 230 then 
                                        if not menu.combo.Under:get() then 
                                            if not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, DaggerPos)
                                            end
                                        else 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    end
                                elseif target.pos:dist(player.pos) > common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.pos:dist(player) > 230 then 
                                    if not menu.combo.Under:get() then 
                                        if not common.IsUnderDangerousTower(target.pos) then 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    else 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                else 
                                    if Object.pos:dist(player) > 725 then 
                                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                        if not menu.combo.Under:get() then 
                                            if not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, targetVector)
                                            end
                                        else 
                                            player:castSpell('pos', 2, targetVector)
                                        end
                                    end

                                    if Object.pos:dist(target) > 450 then 
                                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                        if not menu.combo.Under:get() then 
                                            if not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, targetVector)
                                            end
                                        else 
                                            player:castSpell('pos', 2, targetVector)
                                        end
                                    end
                                end
                            elseif menu.combo.DaggerUse:get() == 3 then 
                                if target.pos:dist(Object.pos) < 450 and Object.pos:dist(player) > 230 then
                                    if not menu.combo.Under:get() then 
                                        if not common.IsUnderDangerousTower(target.pos) then 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    else 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                else 
                                    if Object.pos:dist(player) > 725 then 
                                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                        if not menu.combo.Under:get() then 
                                            if not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, targetVector)
                                            end
                                        else 
                                            player:castSpell('pos', 2, targetVector)
                                        end
                                    end

                                    if Object.pos:dist(target) > 450 then 
                                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                        if not menu.combo.Under:get() then 
                                            if  not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, targetVector)
                                            end
                                        else 
                                            player:castSpell('pos', 2, targetVector)
                                        end
                                    end
                                end
                            end 
                        end
                    end
                elseif menu.combo.esave:get() then 

                    for i, Object in pairs(Dagger) do   
                        if Object then 
                            
                            local DaggerPos = Object.pos + (target.pos - Object.pos):norm() * 200

                            if target.pos:dist(player.pos) <= common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.StartDagger <= game.time then
                                if (not IsPreAttack or not orb.core.can_attack()) and Object.pos:dist(player) > 230 then 
                                    if not menu.combo.Under:get() then 
                                        if not common.IsUnderDangerousTower(target.pos) then 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    else 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                end
                            elseif target.pos:dist(player.pos) > common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.pos:dist(player) > 230 then 
                                if not menu.combo.Under:get() then 
                                    if  not common.IsUnderDangerousTower(target.pos) then 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                else 
                                    player:castSpell('pos', 2, DaggerPos)
                                end
                            end 

                        end 
                    end
                end
            end
        end

        if menu.combo.w:get() then 
            TS.range = 400
            TS:OnTick()
            local target = TS.target

            if target and target ~= nil then 

                if player:spellSlot(1).state == 0 and not common.isFleeingFromMe(target) then 
                    if target.pos2D:dist(player.pos2D) < 450 then 
                        player:castSpell('self', 1)
                    end 
                end
            end 
        end

        
        if menu.Ultmate.r:get() then 
            TS.range = 550
            TS:OnTick()
            local target = TS.target

            if target and target ~= nil then 


                if menu.Ultmate.rmode:get() == 1 then 

                    if player:spellSlot(3).state == 0 and target.pos:dist(player) <= 400 then 
                        if target ~= nil and #common.CountEnemiesInRange(player.pos, 550) >= menu.Ultmate.count:get()  then 
                            if common.GetPercentHealth(target) > menu.Ultmate.nouseR:get() and player:spellSlot(0).state ~= 0 and player:spellSlot(1).state ~= 0 then  
                                player:castSpell('self', 3)
                            end 
                        end 
                    end 
                elseif menu.Ultmate.rmode:get() == 2 then 
                    if player:spellSlot(3).state == 0 and target.pos:dist(player) <= 400 then 
                        if target ~= nil and target.health <= (QDamage(target) + EDamage(target) + DamageVoracity(target) + RDamage(target)) * menu.Ultmate.dagger:get() then 
                            if common.GetPercentHealth(target) > menu.Ultmate.nouseR:get() and player:spellSlot(0).state ~= 0 and player:spellSlot(1).state ~= 0 then 
                                player:castSpell('self', 3)
                            end 
                        end 
                    end
                end
            end
        end 
    elseif menu.combo['Combo.Style']:get() == 2 then --E Priority 
        if menu.combo.e:get() and player:spellSlot(2).state == 0 then 

            TS.range = 800
            TS:OnTick()
            local target = TS.target

            if target and target ~= nil then 
                if not menu.combo.esave:get() then 
                    if size() == 0 and target.pos:dist(player.pos) <= 725 then 
                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                        if not menu.combo.Under:get() then 
                            if not common.IsUnderDangerousTower(target.pos) then 
                                player:castSpell('pos', 2, targetVector)
                            end
                        else 
                            player:castSpell('pos', 2, targetVector)
                        end
                    end
                    for i, Object in pairs(Dagger) do   
                        if Object then 
                            local DaggerPos = Object.pos + (target.pos - Object.pos):norm() * 200

                            if menu.combo.DaggerUse:get() == 2 then 
                                if target.pos:dist(player.pos) <= common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.StartDagger <= game.time then
                                    if (not IsPreAttack or not orb.core.can_attack()) and Object.pos:dist(player) > 230 then 
                                        if not menu.combo.Under:get() then 
                                            if not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, DaggerPos)
                                            end
                                        else 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    end
                                elseif target.pos:dist(player.pos) > common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.pos:dist(player) > 230 then 
                                    if not menu.combo.Under:get() then 
                                        if not common.IsUnderDangerousTower(target.pos) then 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    else 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                else 
                                    if Object.pos:dist(player) > 725 then 
                                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                        if not menu.combo.Under:get() then 
                                            if not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, targetVector)
                                            end
                                        else 
                                            player:castSpell('pos', 2, targetVector)
                                        end
                                    end

                                    if Object.pos:dist(target) > 450 then 
                                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                        if not menu.combo.Under:get() then 
                                            if not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, targetVector)
                                            end
                                        else 
                                            player:castSpell('pos', 2, targetVector)
                                        end
                                    end
                                end
                            elseif menu.combo.DaggerUse:get() == 3 then 
                                if target.pos:dist(Object.pos) < 450 and Object.pos:dist(player) > 230 then
                                    if not menu.combo.Under:get() then 
                                        if not common.IsUnderDangerousTower(target.pos) then 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    else 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                else 
                                    if Object.pos:dist(player) > 725 then 
                                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                        if not menu.combo.Under:get() then 
                                            if not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, targetVector)
                                            end
                                        else 
                                            player:castSpell('pos', 2, targetVector)
                                        end
                                    end

                                    if Object.pos:dist(target) > 450 then 
                                        local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                        if not menu.combo.Under:get() then 
                                            if  not common.IsUnderDangerousTower(target.pos) then 
                                                player:castSpell('pos', 2, targetVector)
                                            end
                                        else 
                                            player:castSpell('pos', 2, targetVector)
                                        end
                                    end
                                end
                            end 
                        end
                    end
                elseif menu.combo.esave:get() then 

                    for i, Object in pairs(Dagger) do   
                        if Object then 
                            
                            local DaggerPos = Object.pos + (target.pos - Object.pos):norm() * 200

                            if target.pos:dist(player.pos) <= common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.StartDagger <= game.time then
                                if (not IsPreAttack or not orb.core.can_attack()) and Object.pos:dist(player) > 230 then 
                                    if not menu.combo.Under:get() then 
                                        if not common.IsUnderDangerousTower(target.pos) then 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    else 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                end
                            elseif target.pos:dist(player.pos) > common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.pos:dist(player) > 230 then 
                                if not menu.combo.Under:get() then 
                                    if  not common.IsUnderDangerousTower(target.pos) then 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                else 
                                    player:castSpell('pos', 2, DaggerPos)
                                end
                            end 

                        end 
                    end
                end
            end
        end

        if menu.combo.w:get() then
            TS.range = 400
            TS:OnTick()
            local target = TS.target

            if target and target ~= nil then 

                if player:spellSlot(1).state == 0 and not common.isFleeingFromMe(target) then 
                    
                    if target.pos2D:dist(player.pos2D) <= 450 then 
                        player:castSpell('self', 1)
                    end 
                end
            end
        end

        if menu.combo.q:get() then 
            TS.range = 625
            TS:OnTick()
            local target = TS.target
            if target and target ~= nil then 
                if (not IsPreAttack or not orb.core.can_attack()) and (target.pos2D:dist(player.pos2D) <= 625 and player:spellSlot(0).state == 0) then 
                    player:castSpell("obj", 0, target)
                end 
            end
        end

        if menu.Ultmate.r:get() then 
            TS.range = 550
            TS:OnTick()
            local target = TS.target
            if target and target ~= nil then 
                if menu.Ultmate.rmode:get() == 1 then 

                    if player:spellSlot(3).state == 0 and target.pos:dist(player) <= 400 then 
                        if target ~= nil and #common.CountEnemiesInRange(player.pos, 550) >= menu.Ultmate.count:get()  then 
                            if common.GetPercentHealth(target)  > menu.Ultmate.nouseR:get() and player:spellSlot(0).state ~= 0 and player:spellSlot(1).state ~= 0 then  
                                player:castSpell('self', 3)
                            end 
                        end 
                    end 
                elseif menu.Ultmate.rmode:get() == 2 then 
                    if player:spellSlot(3).state == 0 and target.pos:dist(player) <= 400 then 
                        if target ~= nil and target.health <= (QDamage(target) + EDamage(target) + DamageVoracity(target) + RDamage(target)) * menu.Ultmate.dagger:get() then 
                            if common.GetPercentHealth(target)  > menu.Ultmate.nouseR:get() and player:spellSlot(0).state ~= 0 and player:spellSlot(1).state ~= 0 then 
                                player:castSpell('self', 3)
                            end 
                        end 
                    end
                end
            end
        end 
    end 
       
    
end 

local function Harass()
    if RotatingIsGood() and RotatingIsGood() > 0 then 
        return 
    end 

    local target = TS.target 

    if not target then 
        return 
    end

    --if menu.harass['Combo.Style']:get() == 1 then 
        if menu.harass.q:get() then 
            if (not IsPreAttack or not orb.core.can_attack()) and (target.pos2D:dist(player.pos2D) <= 625 and player:spellSlot(0).state == 0) then 
                player:castSpell("obj", 0, target)
            end 
        end
        if menu.harass.e:get() and player:spellSlot(2).state == 0 then 
            --if not menu.combo.esave:get() then 
                for i, Object in pairs(Dagger) do   
                    if Object then 
                        local DaggerPos = Object.pos + (target.pos - Object.pos):norm() * 200

                        if target.pos:dist(player.pos) <= common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.StartDagger <= game.time then
                            if (not IsPreAttack or not orb.core.can_attack()) and Object.pos:dist(player) > 230 then 
                                if not menu.combo.Under:get() then 
                                    if not common.IsUnderDangerousTower(target.pos) then 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                else 
                                    player:castSpell('pos', 2, DaggerPos)
                                end
                            end
                        elseif target.pos:dist(player.pos) > common.GetAARange(target) and target.pos:dist(Object.pos) < 450 and Object.pos:dist(player) > 230 then 
                            if not menu.combo.Under:get() then 
                                if not common.IsUnderDangerousTower(target.pos) then 
                                    player:castSpell('pos', 2, DaggerPos)
                                end
                            else 
                                player:castSpell('pos', 2, DaggerPos)
                            end
                        else 
                            if Object.pos:dist(player) > 725 then 
                                local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                if not menu.combo.Under:get() then 
                                    if not common.IsUnderDangerousTower(target.pos) then 
                                        player:castSpell('pos', 2, targetVector)
                                    end
                                else 
                                    player:castSpell('pos', 2, targetVector)
                                end
                            end

                            if Object.pos:dist(target) > 450 then 
                                local targetVector = target.pos + (player.pos - target.pos):norm() * -50
                                if not menu.combo.Under:get() then 
                                    if not common.IsUnderDangerousTower(target.pos) then 
                                        player:castSpell('pos', 2, targetVector)
                                    end
                                else 
                                    player:castSpell('pos', 2, targetVector)
                                end
                            end
                        end
                    end 
                end 
            --end 
        end
        if menu.harass.w:get() and player:spellSlot(1).state == 0 and not common.isFleeingFromMe(target) then 
            if target.pos2D:dist(player.pos2D) <= 350 then 
                player:castSpell('self', 1)
            end 
        end
    --elseif  menu.harass['Combo.Style']:get() == 2 then 
end 

local function LaneClear()
    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
        local minion = objManager.minions[TEAM_ENEMY][i] 
        if minion and common.IsValidTarget(minion) then 
            if player:spellSlot(0).state == 0 and menu.lane.laneclear.q:get() and GetMinionsHit(minion, 250, 625) >= menu.lane.laneclear['LaneClear.Q']:get() then 
                player:castSpell('obj', 0, minion)
            end 
            if player:spellSlot(0).state == 0  and menu.lane.laneclear.q:get() and minion.pos:dist(player) <= 625 and (orb.farm.predict_hp(minion, 0.25) < QDamage(minion)) then
                player:castSpell('obj', 0, minion)
            end 

            if player:spellSlot(1).state == 0 and menu.lane.laneclear.w:get() and GetMinionsHit(minion, 250, 375) >= menu.lane.laneclear['LaneClear.W']:get() then 
                player:castSpell('self', 1)
            end

            for i, Object in pairs(Dagger) do   
                if Object then 
                    local DaggerPos = Object.pos + (minion.pos - Object.pos):norm() * 200

                    if player:spellSlot(2).state == 0  and menu.lane.laneclear.e:get() then 
                        if #common.CountEnemiesInRange(player.pos, 1000) <= menu.lane.laneclear['Lane.Count']:get() then 
                            if common.GetPercentHealth(player) >= menu.lane.laneclear['LaneClear.ManaPercent']:get() then 
                                local count = 0
                                for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
                                    local minion = objManager.minions[TEAM_ENEMY][i]
                                    if minion and minion.pos:dist(player) <= 725 and common.GetDistance(minion, DaggerPos) < 350 then
                                        count = count + 1
                                    end
                                end

                                if count >= menu.lane.laneclear['LaneClear.E']:get() then 
                                    if not menu.combo.Under:get() then 
                                        if not common.IsUnderDangerousTower(DaggerPos) then 
                                            player:castSpell('pos', 2, DaggerPos)
                                        end
                                    else 
                                        player:castSpell('pos', 2, DaggerPos)
                                    end
                                end
                            end
                        end 
                    end
                end 
            end
        end 
    end 
end 

local function JungleClear()
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] -1 do 
        local minion = objManager.minions[TEAM_NEUTRAL][i] 
        if minion and common.IsValidTarget(minion) then 
            if menu.lane.jungle.q:get() then 
                if player:spellSlot(0).state == 0 and GetMinionsHit(minion, 250, 625) >= 1 then 
                    player:castSpell('obj', 0, minion)
                end 
            end 

            if menu.lane.jungle.w:get() then 
                if player:spellSlot(1).state == 0 and GetMinionsHit(minion, 250, 375) >= 1 then 
                    player:castSpell('self', 1)
                end
            end 
        end 
    end
end 

local function LastHit()
    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
        local minion = objManager.minions[TEAM_ENEMY][i] 
        if minion and common.IsValidTarget(minion) then 
            if player:spellSlot(0).state == 0 and minion.pos:dist(player) <= 625 and (orb.farm.predict_hp(minion, 0.25) < QDamage(minion)) then
                player:castSpell('obj', 0, minion)
            end 
        end 
    end
end 

local function AutoQ()
    if orb.menu.combat.key:get() or orb.combat.is_active() then 
        return 
    end 

    if RotatingIsGood() and RotatingIsGood() > 0 then 
        return 
    end 

    local target = common.GetTarget(625) 

    if target and target ~= nil then 
        if menu.misc[target.charName] and menu.misc[target.charName]:get() then 
            if (not IsPreAttack or not orb.core.can_attack()) and (target.pos2D:dist(player.pos2D) <= 625 and player:spellSlot(0).state == 0) then 
                player:castSpell("obj", 0, target)
            end 
        end 
    end 
end 

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) and common.IsEnemyMortal(enemies) then
            local hp = common.GetShieldedHealth("ap", enemies)
			if menu.kill.useDagger:get() then
				for _, objs in pairs(Dagger) do
					if objs then
						if (enemies.pos:dist(player.pos) <= 725 and objs.pos:dist(enemies) < 450 and DamageVoracity(enemies) > hp) then
							local direction = (objs.pos - enemies.pos):norm()
							local extendedPos = objs.pos - direction * 200
							player:castSpell("pos", 2, extendedPos)
						end
					end
				end
			end

			if menu.kill.useQ:get() then
				if
					player:spellSlot(0).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < 625 and
                    QDamage(enemies) > hp
				 then
					player:castSpell("obj", 0, enemies)
				end
			end
			if menu.kill.useE:get() then
				if
					player:spellSlot(2).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < 725 and
                    EDamage(enemies) > hp
				 then
					player:castSpell("pos", 2, enemies.pos)
				end
			end

			if menu.kill.egab:get() then
				if
					player:spellSlot(0).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) > 625 and
						vec3(enemies.x, enemies.y, enemies.z):dist(player) < 625 + 725 - 70 and
						EDamage(enemies) - 30 > hp
				 then
					local minion = GetClosestMobToEnemy(enemies)
					if minion then
						player:castSpell("pos", 2, minion.pos)
					end

					local minios = GetClosestJungleEnemy(enemies)
					if minios then
						player:castSpell("pos", 2, minios.pos)
					end
				end
			end
        end 
    end
end

local function WGabcloser()
    --common.IsMovingTowards(target, 500)
    local target = TargetEd.get_result(function(res, obj, dist)
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

local function Flee()
	if menu.misc.flee.keyFlee:get() then
		player:move(vec3(mousePos.x, mousePos.y, mousePos.z))
		if menu.misc.flee.fleew:get() then
			player:castSpell("pos", 1, player.pos)
		end
		if menu.misc.flee.fleeE:get() then
			local minion = GetClosestMob()
			if minion then
				player:castSpell("pos", 2, minion.pos)
			end
			local jungleeeee = GetClosestJungle()
			if jungleeeee then
				player:castSpell("pos", 2, jungleeeee.pos)
			end
		end
		for _, objs in pairs(Dagger) do
            if objs then
                if (objs.pos:dist(mousePos) < 200) then
                    player:castSpell("pos", 2, objs.pos)
                end
            end
        end
	end
end


local function OnTick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end 

    IsPreAttack = false 
    if menu.misc.autoq:get() then 
        AutoQ()
    end 

    KillSteal()
    WGabcloser()
    Flee()

    if RotatingIsGood() and RotatingIsGood() > 0 then 
        if menu.evade.BlockR:get() and (evade) then
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

    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    elseif orb.menu.lane_clear.key:get() then 
        LaneClear()
        JungleClear()
    elseif orb.menu.last_hit.key:get() then 
        LastHit()
    end 
end 
cb.add(cb.tick, OnTick)


local function on_create_particle(obj)
    if obj then 
        if obj.name:find("W_Indicator_Ally") then
            Dagger[obj.ptr] = {
                pos = obj.pos,
                StartDagger = game.time + 1.25 - 0.25,
            };
        end 
    end
end 
cb.add(cb.create_particle, on_create_particle)

local function on_delete_particle(obj)
    if obj then 
        Dagger[obj.ptr] = nil
    end 
end 
cb.add(cb.delete_particle, on_delete_particle)

local function OnDrawing()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 625, 1, menu.draws.qcolor:get(), 40)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 375, 1, menu.draws.wcolor:get(), 40)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 725, 1, menu.draws.ecolor:get(), 40)
        end
        if (menu.draws.rrange:get() and player:spellSlot(3).state == 0) then
            graphics.draw_circle(player.pos, 550, 1, menu.draws.rcolor:get(), 40)
        end

        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.misc.autoq:get() then
			graphics.draw_text_2D("Auto Q: On", 16, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Auto Q: Off", 16, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
        end

        if menu.combo.Under:get() then
            graphics.draw_text_2D("Use E in UnderTower: On", 17, pos.x - 70, pos.y + 15, graphics.argb(255, 255, 255, 255))
        else
            graphics.draw_text_2D("Use E in UnderTower: Off", 17, pos.x - 70, pos.y + 15, graphics.argb(255, 255, 255, 255))
        end
        if menu.draws.DrawDadagger:get() then 
            for i, Object in pairs(Dagger) do  

                if menu.combo.DaggerUse:get() == 2 then 
                    if Object and Object.StartDagger <= game.time then 
                        if (#common.CountEnemiesInRange(Object.pos, 450) > 0) then
                            graphics.draw_circle(Object.pos, 450, 2, graphics.argb(255, 0, 255, 0), 50)
                            graphics.draw_circle(Object.pos, 150, 2, graphics.argb(255, 0, 255, 0), 50)
                        end
                        if (#common.CountEnemiesInRange(Object.pos, 450) == 0) then
                            graphics.draw_circle(Object.pos, 450, 2, graphics.argb(255, 255, 0, 0), 50)
                            graphics.draw_circle(Object.pos, 150, 2, graphics.argb(255, 255, 0, 0), 50)
                        end
                    end
                elseif menu.combo.DaggerUse:get() == 3 then 
                    if Object then 
                        if (#common.CountEnemiesInRange(Object.pos, 450) > 0) then
                            graphics.draw_circle(Object.pos, 450, 2, graphics.argb(255, 0, 255, 0), 50)
                            graphics.draw_circle(Object.pos, 150, 2, graphics.argb(255, 0, 255, 0), 50)
                        end
                        if (#common.CountEnemiesInRange(Object.pos, 450) == 0) then
                            graphics.draw_circle(Object.pos, 450, 2, graphics.argb(255, 255, 0, 0), 50)
                            graphics.draw_circle(Object.pos, 150, 2, graphics.argb(255, 255, 0, 0), 50)
                        end
                    end 
                end 
            end
        end
    end
end 
cb.add(cb.draw, OnDrawing)

local function OnPreTick()
    IsPreAttack = true 
end 
cb.add(cb.pre_tick, OnPreTick)