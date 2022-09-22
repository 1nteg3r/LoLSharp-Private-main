local evade = module.seek("evade"); 
local TS = module.internal("TS");
local orb = module.internal("orb");
local common = module.load(header.id, "common");
local pred = module.internal('pred');
local damage = module.load(header.id, "damageLib");
local kalman = module.load(header.id, 'kalman_load');
--[[

[25:06] Spell name: LucianE
[25:06] Speed:500
[25:06] Width: 50
[25:06] Time:0.15000000596046
[25:06] Animation: 0.60000002384186
[25:06] false
[25:06] CastFrame: 0.1823156774044
[25:06] --------------------------------------

[25:29] Spell name: LucianW
[25:29] Speed:500
[25:29] Width: 80
[25:29] Time:0.25
[25:29] Animation: 0.25
[25:29] false
[25:29] CastFrame: 0.1823156774044
[25:29] --------------------------------------

[25:42] Spell name: LucianQ
[25:42] Speed:500
[25:42] Width: 65
[25:42] Time:0.30000001192093
[25:42] Animation: 0.30000001192093
[25:42] false
[25:42] CastFrame: 0.1823156774044
[25:42] --------------------------------------

[00:30] 200
[00:53] Spell name: LucianR
[00:53] Speed:500
[00:53] Width: 60
[00:53] Time:0.0099999997764826
[00:53] Animation: 2
[00:53] false
[00:53] CastFrame: 0.20270086824894
[00:53] --------------------------------------

]]
local LastSpellCastTime = 0;
local IsCastingSpell = false;
local IsPreAttack = false;
local IsAfterAttack = false;
local IsPostAttack = false;
local LastETime = 0;
local RDirection = vec3(0,0,0);

local SpellQ = {
    delay = 0.30; 
    range = 650;
    radius = 65; 
    speed = 500;  
    dashRadius = 0;
	boundingRadiusModSource = 1;
    boundingRadiusModTarget = 1;
}

local SpellW = {
    range = 1000,
    delay = 0.25,
    speed = 500,
    boundingRadiusMod = 1,
    width = 80,
    collision = {
        hero = true,
        minion = true,
        wall = true
    },
}

local SpellR = {
    range = 1150,
    delay = 0.25,
    speed = 500,
    boundingRadiusMod = 1,
    width = 60,
    collision = {
        hero = true,
        minion = true,
        wall = true
    },
}

local function HasPassiveBuff()
    return player.buff['lucianpassivebuff']
end 

local function GetPassiveBuff()
    return player.buff['lucianpassivebuff']
end 

local function HasWDebuff(unit)
    return unit.buff['lucianwdebuff']
end 

local function IsCastingQ()
    return IsCastingSpell
end 

local function IsCastingR()
    return player.buff['lucianr']
end

local function HasAnyOrbwalkerFlags()
    return orb.menu.combat.key:get() or orb.menu.lane_clear.key:get() or orb.menu.last_hit.key:get() or orb.menu.hybrid.key:get()
end 

local function Distance(point, segmentStart, segmentEnd, onlyIfOnSegment, squared)
	local isOnSegment, pointSegment = common.ProjectOn(point, segmentStart, segmentEnd)
	if isOnSegment or onlyIfOnSegment == false then
		if squared then
			return common.GetDistanceSqr(pointSegment, point)
		else
			return common.GetDistance(pointSegment, point)
		end
	end
	return math.huge
end

local function CanHitSkillShot(target, minion)
	local powCalc = 120
	if Distance(minion.pos, player.pos, target.pos, true, true) <= powCalc then
		return true
	end
	return false
end

local function CountMinionInLine(target)
	local NH = 0
	local minioncollision = nil
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minions = objManager.minions[TEAM_ENEMY][i]
        if minions and common.IsValidTarget(minions) then
            if CanHitSkillShot(target, minions) then
                NH = NH + 1
                minioncollision = minions
            end
        end
	end
    return NH , minioncollision
end

local function isInAutoAttackRange(target)
    return player.pos:dist(target.pos) <= common.GetAARange(player) 
end 

local function GetComboDamage(unit, attackStack)
    if unit == nil then 
        return 
    end
    local attackStack = attackStack or 1 
    local Wappwer = 0 

    Wappwer = common.CalculateAADamage(unit) * attackStack 

    if unit.pos:dist(player.pos) <= 900 and player:spellSlot(0).state == 0 then 
        Wappwer = damage.GetSpellDamage(0, unit) * attackStack 
    end 

    if unit.pos:dist(player.pos) <= 1000 and player:spellSlot(1).state == 0 then 
        Wappwer = damage.GetSpellDamage(1, unit) * attackStack 
    end 
    return Wappwer
end 

local function PossibleToInterruptQ(target)
    if target == nil then
        return
    end 
    if IsCastingQ() and player:spellSlot(1).state == 0 and isInAutoAttackRange(target) then 
        return true 
    end 
    return false 
end 

local function PossibleEqCombo(target)
    if target == nil then 
        return 
    end 
    return player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0  and not HasPassiveBuff();
end 

local function EnemiesInDirectionOfTheDash(Enemy, dashEndPosition, maxValue)
    if Enemy == nil then 
        return 
    end 

    local dotProduct = (dashEndPosition - player.pos):norm()
    local DotPruct = dotProduct:dot(Enemy.pos:norm())
    return DotPruct >= 65
end 

local function ClosetEnemy()
	local best = nil
	local distance = 10000
    for i = 0, objManager.enemies_n - 1 do
        local enemy = objManager.enemies[i]
        if enemy and common.IsValidTarget(enemy) then
			local axePos = enemy.pos
			if common.GetDistance(player, axePos) < 1300 and  common.GetDistance(axePos, player) < distance then
				best = enemy
				distance =  common.GetDistance(axePos, player)
			end
		end
	end
	return best
end


local menu = menu("MarksmanAIOLucian", "Marksman - Lucian");
--subs menu
menu:header("xs", "Core");
menu:menu('combo', 'Combo Settings')
menu.combo:menu('qsettings', "Q Settings")
    menu.combo.qsettings:boolean("q", "Use Q", true);
    menu.combo.qsettings:boolean("qex", "Use Q Extend", true);
    menu.combo.qsettings:slider("mana", "^ Min. Mana Percent", 25, 1, 100, 1);
menu.combo:menu('wsettings', "W Settings")
    menu.combo.wsettings:boolean("w", "Use W", true);
    menu.combo.wsettings:boolean("ignw", "Ignore collision", true);
    menu.combo.wsettings:slider("mana", "^ Min. Mana Percent", 15, 1, 100, 1);
menu.combo:menu('esettings', "E Settings")
    menu.combo.esettings:boolean("e", "Use E", true);
    menu.combo.esettings:dropdown('mode', 'Mode E', 2, {'Cursor', 'Auto'});
    menu.combo.esettings:slider("e_dist", "^ DistanceTo", 375, 5, 500, 5);
menu.combo:menu('rsettings', "R Settings")
    menu.combo.rsettings:boolean("r", "Use R", false);
    menu.combo.rsettings:boolean("Lock", "Auto Lock - R", true);
    menu.combo.rsettings:header('Another', "Misc Settings")
    menu.combo.rsettings:menu("blacklist", "Blacklist!")
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy then 
            menu.combo.rsettings.blacklist:boolean(enemy.charName, "Do not use R on: " .. enemy.charName, false)
        end
    end 
menu:menu('harass', 'Hybrid/Harass Settings')
    menu.harass:menu('qsettings', "Q Settings")
        menu.harass.qsettings:boolean("qharras", "Use Q", true)
        menu.harass.qsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
menu:menu('lane', 'Lane/Jungle Settings')
    menu.lane:boolean("useQ", "Use Q", true)
    menu.lane:boolean("useW", "Use W (for passive activation only)", true)
    menu.lane:slider("mana_mngr", "Minimum Mana %", 45, 0, 100, 5)
menu:header("", "Misc Settings")
    menu:menu('Flee', 'Flee Settings')
    menu.Flee:keybind("keyjump", "Flee", 'Z', nil)
    menu.Flee:boolean("fleeE", "Use E Flee", true)
menu:menu("draws", "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", false)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("r_range", "Draw R Range", true)
    menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)

    
local function ELogic()
    if player:spellSlot(2).state ~= 0 or IsCastingR() or HasPassiveBuff() or player.buff['sheen'] then return end
 
    if menu.combo.esettings.mode:get() == 1 and not IsPostAttack then 
        return 
    end 

    local target = common.GetTarget(common.GetAARange() + menu.combo.esettings.e_dist:get())

    if target == nil then
        return 
    end

    if (not IsPostAttack and player:spellSlot(0).state ~= 0) and common.GetShieldedHealth("AD", target) >= common.CalculateAADamage(target) * 5  then 
        return 
    end

    if (IsCastingQ() and not PossibleToInterruptQ(target)) then 
        return
    end

    local castTime = player:spellSlot(0).static.castFrame

    if not IsPostAttack and castTime > 0 then 
        return 
    end

    local positionAfterE = common.GetPredictedPos(target)
    local shortEPosition = player.pos + (mousePos - player.pos):norm() * 70 

    if (player:spellSlot(0).state == 0 and not IsPostAttack and common.IsUnderDangerousTower(shortEPosition)) then 
        return 
    end 

    if (GetComboDamage(target, 4) >= common.GetShieldedHealth("AD", target) and #common.CountEnemiesInRange(player.pos, 1300) <= 2) or (#common.CountEnemiesInRange(player.pos, 1300) <= 1) and 
    common.IsInRange(common.GetAARange() - 70, player, positionAfterE) and shortEPosition:dist(target) > 400 then 
        player:castSpell("pos", 2, shortEPosition)
    end

    local damage = GetComboDamage(target, 2);
    local Ispos = nil 
    if mousePos:dist(player.pos) > 470 then 
        Ispos = player.pos + (mousePos - player.pos):norm() * 470 
    else 
        Ispos = mousePos 
    end 
    local enemiesInPosition = #common.CountEnemiesInRange(Ispos, common.GetAARange() + 335);

    if (not IsPostAttack and ((damage < common.GetShieldedHealth("ALL", target)) or not PossibleEqCombo(target) or (enemiesInPosition <= 0) or (enemiesInPosition >= 3))) then 
        return
    end

    local enemies = #common.CountEnemiesInRange(player.pos, 1300);

    if (not common.IsUnderDangerousTower(Ispos)) then 
        if enemies == 1 then 
            local InisRange = 0 
            if target.attackRange < 425 then 
                InisRange = 500 
            else 
                InisRange = 300
            end 

            if not InisRange or (damage > common.GetShieldedHealth("ALL", target)) and EnemiesInDirectionOfTheDash(target, Ispos, 2000) or not common.IsMovingTowards(target, 600) then 
                if ((common.GetPercentHealth(player) >= common.GetPercentHealth(target)) and common.IsInRange(common.GetAARange(), player, target) and
                not common.IsInRange(common.GetAARange() - 50, Ispos, target)) then 
                    return 
                end 
                player:castSpell("pos", 2, Ispos)
            end 
        elseif enemies == 2 and (#common.CountAllysInRange(player.pos, 400) > 1) or (damage > common.GetShieldedHealth("ALL", target) and #common.CountEnemiesInRange(Ispos, common.GetAARange()) == 1) then 
            player:castSpell("pos", 2, Ispos)
        else 
            local range = enemies*150;
            if common.IsInRange(range, Ispos, positionAfterE) then 
                player:castSpell("pos", 2, Ispos)
            end
        end 
    end 

    local closest = ClosetEnemy()
    if closest then 
        local count = 0 
        if common.IsMovingTowards(closest) then  
            count = count + 1 
        end 

        if #common.CountEnemiesInRange(player.pos, 350) >= 1 and count >= 1 and (Ispos:dist(closest) > player.pos:dist(closest)) and (Ispos:dist(player.pos) >= 450) then 
            player:castSpell("pos", 2, Ispos)
        end
    end 
end 

local function CastingW()
    if (player:spellSlot(1).state == 0 and menu.combo.wsettings.w:get() and not IsCastingR() and not HasPassiveBuff() and not player.buff['sheen']) then 
        local target = common.GetTarget(1000)

        if target and target ~= nil and (player.mana > 100) and not player.path.isDashing or damage.GetSpellDamage(1, target) > common.GetShieldedHealth("AP", target) then 
            if menu.combo.wsettings.ignw:get() then 
                local targetorb = orb.combat.target
                if targetorb and common.IsValidTarget(targetorb) then  
                    player:castSpell("pos", 1, targetorb.pos)
                end 
            end

            local seg = pred.linear.get_prediction(SpellW, target)
            if seg and seg.startPos:dist(seg.endPos) < SpellW.range then
                if not pred.collision.get_prediction(SpellW, seg, target) and kalman.KalmanFilter(target) then
                    player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end 
            end
        end
    end 
end

local function CastingR(target)
    if target.health < 0 then 
        return 
    end 

    local shots = ({0, 20, 25, 30 })[player:spellSlot(3).level];

    local pDamage = 0 
    local sigleRShotDamage = damage.GetSpellDamage(3, target)
    local distance = player.pos:dist(target)
    if (player.moveSpeed >= target.moveSpeed) then 
        pDamage = sigleRShotDamage * shots;
    elseif target.path.serverPos:len() > 100 and player.moveSpeed < target.moveSpeed then 
        local difference = target.moveSpeed - target.moveSpeed 

        for i = 1, shots do 
            if ((distance > 1150) or (i >= shots)) then 
                return 
            end
            distance = difference / 1000 * (3.00 / shots * i);
            pDamage = sigleRShotDamage * i;
        end
    end 

    if pDamage > target.health and player:spellSlot(3).name == "LucianR" then 
        local seg = pred.linear.get_prediction(SpellR, target)
        if seg and seg.startPos:dist(seg.endPos) < SpellR.range then
            if not pred.collision.get_prediction(SpellR, seg, target) then
                player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end 
        end
    end 
end 

local function Combo()
    local targetQ = common.GetTarget(925)

    if targetQ and PossibleToInterruptQ(targetQ) then
        local positionAfterE = common.GetPredictedPos(targetQ)
        local Pos = player.pos + (mousePos - player.pos):norm() * (positionAfterE:dist(player) + targetQ.boundingRadius)
        if not common.IsUnderDangerousTower(Pos) then 
            player:castSpell("pos", 2, Pos)
        end 
    end

    ELogic()
    

    if (player:spellSlot(0).state == 0 and menu.combo.qsettings.q:get() and not IsCastingR() and not HasPassiveBuff() and not player.buff['sheen']) then 
        local target = common.GetTarget(650)
        local target2 = common.GetTarget(925)

        if not common.IsValidTarget(target) or not common.IsValidTarget(target2) then 
            return
        end

        if (PossibleEqCombo(target) or PossibleEqCombo(target2)) then
            return
        end

        if (not IsPostAttack and ((orb.core.can_attack()))) then 
            local seg = pred.linear.get_prediction(SpellW, target)
            if seg and seg.startPos:dist(seg.endPos) < SpellW.range then
                if not pred.collision.get_prediction(SpellW, seg, target) then 
                    if (common.IsInRange(seg.endPos, common.GetAARange())) then 
                        CastingW()
                    end 
                end 
            end 
        end 

        if target and player.pos:dist(target) <= 650 and (player.mana > player.manaCost0 + player.manaCost2 + 100)  and not player.path.isDashing or damage.GetSpellDamage(0, target) + (common.CalculateAADamage(target) * 3) > common.GetShieldedHealth("ALL", target) then
            player:castSpell("obj", 0, target)
        end
        
        if menu.combo.qsettings.qex:get() and target2 and target2 ~= nil and (player.mana > player.manaCost0 + player.manaCost2 + 100)  and not player.path.isDashing or damage.GetSpellDamage(0, target) + (common.CalculateAADamage(target) * 3) > common.GetShieldedHealth("ALL", target) then
            if common.GetDistance(target2) > 500 and common.GetDistance(target2) <= 1000 then
                local countMinion, minion = CountMinionInLine(target2)
                if minion and minion.pos:dist(player.pos) <= 650 then
                    player:castSpell("obj", 0, minion)
                end
            end
        end 
    end 

    if (player:spellSlot(1).state == 0 and menu.combo.wsettings.w:get() and not IsCastingR() and not HasPassiveBuff() and not player.buff['sheen']) then 
        local target = common.GetTarget(1000)

        if target and (player.mana > 100)  then 
            if (not player.path.isDashing or damage.GetSpellDamage(1, target) > common.GetShieldedHealth("AP", target)) then 
                if menu.combo.wsettings.ignw:get() then 
                    local targetorb = orb.combat.target
                    if targetorb and common.IsValidTarget(targetorb) then 
                        player:castSpell("pos", 1, targetorb.pos)
                    end 
                end

                local seg = pred.linear.get_prediction(SpellW, target)
                if seg and seg.startPos:dist(seg.endPos) < SpellW.range then
                    if not pred.collision.get_prediction(SpellW, seg, target) and kalman.KalmanFilter(target) then
                        player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                end
            end
        end
    end 

    if (player:spellSlot(3).state == 0 and  menu.combo.rsettings.r:get() and not common.IsUnderDangerousTower(player.pos)) then
        if (#common.CountEnemiesInRange(player.pos, common.GetAARange() + 150) == 0) then  --1150
            local rTarget = common.GetTarget(1150)
            if rTarget and common.IsValidTarget(rTarget) then 
                CastingR(rTarget);
            end
        --[[local rTarget = common.GetTarget(1150)
            if rTarget and common.IsValidTarget(rTarget) then 
                if rTarget.health < 0 then 
                    return 
                end 

                local shots = { 0, 20, 25, 30 };

                local pDamage = 0 
                local sigleRShotDamage = damage.GetSpellDamage(3, rTarget)
                local distance = player.pos:dist(rTarget)
                if (player.moveSpeed >= rTarget.moveSpeed) then 
                    pDamage = sigleRShotDamage * shots[player:spellSlot(3).level];
                elseif rTarget.path.serverPos:len() > 100 and  player.moveSpeed < rTarget.moveSpeed then 
                    local difference = rTarget.moveSpeed - player.moveSpeed 

                    for i = 1, shots[player:spellSlot(3).level] do 
                        if ((distance > 1150) or (i >= shots[player:spellSlot(3).level])) then 
                            return 
                        end
                        distance = difference / 1000 * (3000 / shots[player:spellSlot(3).level] * i);
                        pDamage = sigleRShotDamage * i;
                    end
                end 

                if pDamage > rTarget.health and player:spellSlot(3).name == "LucianR" then 
                    local seg = pred.linear.get_prediction(SpellR, rTarget)
                    if seg and seg.startPos:dist(seg.endPos) < SpellR.range then
                        if not pred.collision.get_prediction(SpellR, seg, rTarget) and kalman.KalmanFilter(rTarget) then
                            player:castSpell("pos", 1, vec3(seg.endPos.x, rTarget.y, seg.endPos.y))
                        end 
                    end
                end 
            end]]
        elseif (#common.CountEnemiesInRange(player.pos, common.GetAARange() + 300) == 1) then 
            local rTarget = common.GetTarget(1150)
            if rTarget and common.IsValidTarget(rTarget) then 
                if HasWDebuff(rTarget) and  player:spellSlot(3).name == "LucianR"  then 
                    if damage.GetSpellDamage(3, rTarget) > common.GetShieldedHealth("AD", rTarget) then 
                        local seg = pred.linear.get_prediction(SpellR, rTarget)
                        if seg and seg.startPos:dist(seg.endPos) < SpellR.range then
                            if not pred.collision.get_prediction(SpellR, seg, rTarget) and kalman.KalmanFilter(rTarget) then
                                player:castSpell("pos", 3, vec3(seg.endPos.x, rTarget.y, seg.endPos.y))
                            end 
                        end
                    end 
                end 
            end
        end 
    end
end 

local function Harass()
    if menu.harass.qsettings.qharras:get() and common.GetPercentMana(player) > menu.harass.qsettings.mana_mngr:get() then 
        local target = common.GetTarget(1000)

        if not common.IsValidTarget(target) then 
            return 
        end 
        if target and player.pos:dist(target) <= 650 and (player.mana > player.manaCost0 + player.manaCost2 + 100)  and not player.path.isDashing or damage.GetSpellDamage(0, target) + (common.CalculateAADamage(target) * 3) > common.GetShieldedHealth("ALL", target) then
            player:castSpell("obj", 0, target)
        end
        
        if menu.combo.qsettings.qex:get() and (player.mana > player.manaCost0 + player.manaCost2 + 100) and not player.path.isDashing then
            if common.GetDistance(target) > 500 and common.GetDistance(target) <= 1000 then
                local countMinion, minion = CountMinionInLine(target)
                if minion and minion.pos:dist(player.pos) <= 650 then
                    player:castSpell("obj", 0, minion)
                end
            end
        end 
    end
end 

local function LaneClear()
    if ((player.mana / player.maxMana * 100) < menu.lane.mana_mngr:get()) then
        return
    end

    local target = common.GetTarget(1000)
    if not common.IsValidTarget(target) then 
        return 
    end 
    
    if menu.combo.qsettings.qex:get() and (player.mana > player.manaCost0 + player.manaCost2 + 100) and not player.path.isDashing then
        if common.GetDistance(target) > 500 and common.GetDistance(target) <= 1000 then
            local countMinion, minion = CountMinionInLine(target)
            if minion and minion.pos:dist(player.pos) <= 650 then
                player:castSpell("obj", 0, minion)
            end
        end
    end 
end

local function JungleClear()
    if ((player.mana / player.maxMana * 100) < menu.lane.mana_mngr:get()) then
        return
    end

    -- Get jungle monsters in AA range
    local minions = common.GetMinions(player.pos, player.attackRange, TEAM_NEUTRAL)

    -- Check there is any monster
    if #minions <= 0 then
        return
    end

    -- Group minions
    local minionsGroups = 0

    for i = 1, #minions do
        if common.CountMinionsInRange(minions[i].pos, 150, TEAM_NEUTRAL) > 0 then
            minionsGroups = minionsGroups + 1
        end
    end


    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local bminions = objManager.minions[TEAM_NEUTRAL][i]
        if #minions > 0 and minionsGroups > 1 and orb.core.can_attack() then
            if bminions and common.IsValidTarget(bminions) then
                if menu.lane.useQ:get() then
                    player:castSpell("obj", 0, bminions)
                end
            end
        elseif orb.core.can_attack() then
            if menu.lane.useW:get() then
                player:castSpell("pos", 1, bminions.pos)
            end
        end
    end 
end


local function OnLockR() -- nil
    local target = common.GetTarget(1200)

    if target and common.IsValidTarget(target) then 
        local pre_predPos = pred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)
        if not pre_predPos then 
            return 
        end
        local endPos = (player.path.serverPos - target.path.serverPos):norm();
        local predPos = vec3(pre_predPos.x, target.y, pre_predPos.y)
        local fullPoint = vec2(predPos.x + endPos.x * 1150 * 0.98, predPos.y + endPos.y * 1150 * 0.98);

        local res = mathf.closest_vec_line(predPos:to2D(), player.path.serverPos2D, fullPoint)
        if res and not navmesh.isWall(res) and res:to3D():dist(target.path.serverPos) < (89 + target.boundingRadius) then 
            player:move(res:to3D())
        elseif (fullPoint and not navmesh.isWall(fullPoint) and predPos:dist(fullPoint) < 1150 and predPos:dist(fullPoint) > 100)  then 
            player:move(fullPoint:to3D())
        end
    end 
end

local function OnTick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    IsPreAttack = false
    IsAfterAttack = true
    IsPostAttack = true

    if player.buff['lucianr'] then 
        orb.core.set_pause_attack(math.huge)
        if menu.combo.rsettings.Lock:get() then 
            OnLockR()
        end
    else 
        orb.core.set_pause_attack(0)
    end

    if player:spellSlot(0).state ~= 0 then 
        IsCastingSpell = false
    end

    if player:spellSlot(2).state ~= 0 then  
        LastETime = 0
    end

    if player:spellSlot(3).state ~= 0 and player:spellSlot(3).name == "LucianR" and  player:spellSlot(3).name ~= "LucianRDisable" then 
        RDirection = vec3(0,0,0)
    end

    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    elseif orb.menu.lane_clear.key:get() then 
        LaneClear()
        JungleClear()
    elseif menu.Flee.keyjump:get() then 
        player:move(mousePos)
        if menu.Flee.fleeE:get() then 
            if not common.IsUnderDangerousTower(mousePos) then
                player:castSpell("pos", 2, mousePos)
            end
        end
    end
end 
cb.add(cb.tick, OnTick)

local GamrT = 0
local function on_process_spell(spell)
    if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Lucian" then
        if (spell.name == "LucianW" or spell.name == "LucianE" or spell.name == "LucianQ") then 
            LastSpellCastTime = game.time 
        end

        if (spell.name == "LucianQ") then
            IsCastingSpell = true
        end 

        if (HasAnyOrbwalkerFlags) then 
            if (IsPreAttack) then 
                return 
            end 
            if (spell.name == "LucianE") then 
                LastETime = game.time 
            end 
        end 
        
        if spell.name == "LucianR" then 
            if game.time - GamrT > 0.25 then 
                RDirection = player.pos + (vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z) - player.pos):norm() * 1130
                GamrT = game.time 
            end
        end 
    end 
end
cb.add(cb.spell, on_process_spell)


local function AfterPos()
    IsAfterAttack = false
    IsPostAttack = false

    if menu.combo.esettings.mode:get() == 1 then 
        local targetorb = orb.combat.target
        if targetorb  and common.IsValidTarget(targetorb) then 
            player:castSpell("pos", 2, mousePos)
        end
    end 
end 
orb.combat.register_f_after_attack(AfterPos)

local function Pre_Tick()
    IsPreAttack = true;

end 
orb.combat.register_f_pre_tick(Pre_Tick)

local function on_create_missile(obj)
    if not HasAnyOrbwalkerFlags then return end

    if obj.name == 'LucianWMissile' then 
        orb.core.reset()
    end
end
cb.add(cb.create_missile, on_create_missile)


local function on_create_particle(obj)
    if obj then 
        if obj.name == "Lucian_Base_Q_laser" then 
            orb.core.reset()
        end 
    end
end
cb.add(cb.create_particle, on_create_particle)


local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (not player.isOnScreen) then return end

    if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
        graphics.draw_circle(player.pos, 650, 1, menu.draws.qcolor:get(), 100)
    end
    if (menu.draws.wrange:get()  and player:spellSlot(1).state == 0) then
        graphics.draw_circle(player.pos, 1000, 1, menu.draws.wcolor:get(), 100)
    end
    if (menu.draws.erange:get()  and player:spellSlot(2).state == 0) then
        graphics.draw_circle(player.pos, 425, 1, menu.draws.ecolor:get(), 100)
    end
    if (menu.draws.r_range:get()  and player:spellSlot(3).state == 0) then
        graphics.draw_circle(player.pos, 1150, 1, menu.draws.r:get(), 100)--979561567.
    end 
    --[[local target = common.GetTarget(1200)

    if target and common.IsValidTarget(target) then 
        local pre_predPos = pred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)
        if not pre_predPos then 
            return 
        end
        local predPos = vec3(pre_predPos.x, target.y, pre_predPos.y)
        local UnitVector1 = (player.pos + predPos):norm():perp1() * 650
        local UnitVector2 =  (player.pos + predPos):norm():perp2() *650
        local pointSegment1, pointLine1, isOnSegment = common.VectorPointProjectionOnLineSegment(player, UnitVector2, target.path.serverPos)
        local pointSegment2, pointLine2, isOnSegment2 = common.VectorPointProjectionOnLineSegment(player, UnitVector1, target.path.serverPos)
        local pointSegment13D = {x=pointSegment1.x, y= player.y, z=pointSegment1.y}
        local pointSegment23D = {x=pointSegment2.x, y= player.y, z=pointSegment2.y}
        if common.GetDistance(pointSegment13D) >= common.GetDistance(pointSegment23D) then
            graphics.draw_circle(pointSegment23D, 130, 1, menu.draws.r:get(), 100)
            graphics.draw_circle(pointSegment13D, 130, 1, menu.draws.r:get(), 100)
        end 
        local pre_predPos = pred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)
        if not pre_predPos then 
            return 
        end
        local predPos = vec3(pre_predPos.x, target.y, pre_predPos.y)
        local UnitVector1 = (player.pos + RD):norm():perp1() * 650
        local UnitVector2 =  (player.pos + predPos):norm():perp2() *650
        local pointSegment1, pointLine1, isOnSegment = common.VectorPointProjectionOnLineSegment(player, UnitVector2, target.path.serverPos)
        local pointSegment2, pointLine2, isOnSegment2 = common.VectorPointProjectionOnLineSegment(player, UnitVector2, target.path.serverPos)
        local pointSegment13D = {x=pointSegment1.x, y= player.y, z=pointSegment1.y}
        local pointSegment23D = {x=pointSegment2.x, y= player.y, z=pointSegment2.y}
        if common.GetDistance(pointSegment13D) >= common.GetDistance(pointSegment23D) then
            player:move(pointSegment23D)
        end
    end]]
end
cb.add(cb.draw, OnDraw)