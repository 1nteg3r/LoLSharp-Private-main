local EventManager = module.load('int', 'Core/Yasuo/EventManager');
local Extentions = module.load('int', 'Core/Yasuo/Extentions');
local common = module.load('int', 'Library/common');
local damageLib = module.load('int', 'Library/damageLib');
local pred = module.internal('pred');

local dashStartTime  = 0;
local dashEndTime = 0;
local _endPos = vec3(0,0,0);
local _startPos = vec3(0,0,0);

local function GetPlayerPosition(timeModMs)
    if (player.path.isDashing and dashEndTime < os.clock() + timeModMs) then 
        local PlayerPos = _startPos + (_endPos - _startPos):norm()*475*((dashEndTime - (os.clock() + timeModMs))/(math.random((dashStartTime - dashEndTime), (dashStartTime - dashEndTime))))
        return PlayerPos
    end
end

local function GetDashPos(unit)
    local dashPointT = nil
    if common.GetDistance(player, unit) < 410 then
        dashPointT = player.pos + (unit.pos - player.pos):norm() * 475
    else 
        dashPointT =  player.pos + (unit.pos  - player.pos):norm() * (common.GetDistance(player, unit) + 65)
    end
    return dashPointT
end

local function IsFacing(target)
	return player.path.serverPos:distSqr(target.path.serverPos) >
		player.path.serverPos:distSqr(target.path.serverPos + target.direction)
end

local function GetClosestEUnit(pos)
    local distance = 2500000;
    local unit = nil;
    local enemyminion = common.GetMinionsInRange(3000, TEAM_ENEMY)
    for i, minion in ipairs(enemyminion) do
        if minion and common.IsValidTarget(minion) and minion.pos:dist(player.pos) < 475 and EventManager.CanDash(minion) then 
            if Extentions.IsUnderTower(GetDashPos(minion)) then return end
            local dist = GetDashPos(minion):dist(pos) 
            if (dist <= distance) then 
                distance = dist;
                unit = minion;
            end
        end
    end
    local enemyMobs = common.GetMinionsInRange(3000, TEAM_NEUTRAL)
    for i, JUNGLE in ipairs(enemyMobs) do
        if JUNGLE and common.IsValidTarget(JUNGLE) and JUNGLE.pos:dist(player.pos) < 475 and EventManager.CanDash(JUNGLE) then 
            if Extentions.IsUnderTower(GetDashPos(JUNGLE)) then return end
            local dist = GetDashPos(JUNGLE):dist(pos) 
            if (dist <= distance) then 
                distance = dist;
                unit = JUNGLE;
            end
        end
    end
    if (unit ~= nil) then return unit end
    local enemy = common.GetEnemyHeroes()
    for i, allies in ipairs(enemy) do
        if allies and common.IsValidTarget(allies) and allies.pos:dist(player.pos) < 475 and EventManager.CanDash(allies) then 
            if Extentions.IsUnderTower(GetDashPos(allies)) then return end
            local dist = GetDashPos(allies):dist(pos) 
            if (dist <= distance) then 
                distance = dist;
                unit = allies;
            end
        end
    end
    return unit 
end 


local function FindClosestPoint(target)
    local closestPoint, currentPoint = nil, 0
    local targetPos = nil
	if target.type == player.type then
        local predictPos = pred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)
        local unitPos = vec3(predictPos.x, target.y, predictPos.y);
        if predictPos then
		    targetPos = unitPos
        else
 		    targetPos = target
		end
	else
	    targetPos = target
	end
    if targetPos  then
        local enemyminion = common.GetMinionsInRange(3000, TEAM_ENEMY)
        for i, minion in ipairs(enemyminion) do
            if minion and common.IsValidTarget(minion) and common.GetDistance(minion) <= 475 and EventManager.CanDash(minion) then
                --currentPoint = myHero + (Vector(minion) - myHero):normalized() * Ranges.E
                currentPoint =  GetDashPos(minion)
                --if closestPoint then
                    if closestPoint then
                        closestPoint = currentPoint
                        closestUnit = minion
                    elseif currentPoint:dist(targetPos) < currentPoint:dist(targetPos)  then
                        closestPoint = currentPoint
                        closestUnit = minion
                    end
                --end
            end
        end
        local enemyMobs = common.GetMinionsInRange(3000, TEAM_NEUTRAL)
        for i, minion in ipairs(enemyMobs) do
            if minion and common.IsValidTarget(minion) and common.GetDistance(minion) <= 475 and EventManager.CanDash(minion) then
            --currentPoint = myHero + (Vector(minion) - myHero):normalized() * Ranges.E
			currentPoint =  GetDashPos(minion)
                if closestPoint  then
                    closestPoint = currentPoint
                    closestUnit = minion
                elseif currentPoint:dist(targetPos) < currentPoint:dist(targetPos) then
                    closestPoint = currentPoint
                    closestUnit = minion
                end
            end
        end
        local enemyAllied = common.GetEnemyHeroes()
        for i, enemy in ipairs(enemyAllied) do
            if common.IsValidTarget(enemy) and common.GetDistance(enemy) <= 475 and EventManager.CanDash(enemy) then
                --currentPoint = myHero + (Vector(enemy) - myHero):normalized() * Ranges.E
				currentPoint =  GetDashPos(enemy)
                if closestPoint then
                    closestPoint = currentPoint
                    closestUnit = enemy
                elseif currentPoint:dist(targetPos) < currentPoint:dist(targetPos) then
                    closestPoint = currentPoint
                    closestUnit = enemy
                end
            end
        end
    end
    return closestPoint, closestUnit
end

local function SmartE(unit)
    if player:spellSlot(2).state ~= 0 then return end
    if unit and common.IsValidTarget(unit) then 
        local closestPoint, closestUnit = FindClosestPoint(unit)
        if closestUnit and closestPoint and not Extentions.IsUnderTower(closestPoint) then
            if common.GetDistance(closestPoint, unit) < common.GetDistance(unit) then
                local unit = GetClosestEUnit(unit.pos)
                if unit then
                    player:castSpell("obj", 2, unit)
                end
            end
        elseif (not closestUnit or closestPoint and common.GetDistance(closestPoint, unit) > common.GetDistance(unit)) and common.GetDistance(unit) <= 475 and EventManager.CanDash(unit) then
            local dashPos = GetDashPos(unit)
            local eDmg = damageLib.GetSpellDamage(2, unit)
            if common.GetDistance(unit) > 300 and not Extentions.IsUnderTower(dashPos) or unit.health < eDmg + 75 and not IsFacing(unit) then
                local unit = GetClosestEUnit(unit.pos)
                if unit then
                    player:castSpell("obj", 2, unit)
                end
            end
        end
        if common.GetDistance(unit) <= 1300 then
            local unit = GetClosestEUnit(unit.pos)
            if unit then
                player:castSpell("obj", 2, unit)
            end
        end
    end
end 

cb.add(cb.tick, function()
    if (player.path.isDashing and player:spellSlot(2).state ~= 0) then
        _startPos = vec3(0,0,0)
        _endPos = vec3(0,0,0)
        dashEndTime = 0
        dashStartTime = 0
    end
end)

local lastDebugPrint = 0
cb.add(cb.spell, function(spell)
    if(spell.owner == player and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Yasuo") then
        if (spell.name == "YasuoE") then --Fddd
            dashStartTime = os.clock(); --R Workin? 
            dashEndTime = os.clock(); --endsash  0.27
            _startPos = vec3(spell.startPos.x, spell.startPos.y, spell.startPos.z); --Start Pos
            _endPos = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z) --EndPos spell
        end
        --[[if(spell.owner == player) then
            if os.clock() - lastDebugPrint >= 2 then
                print("Spell name: " ..spell.name);
                print("Speed:" ..spell.static.missileSpeed);
                print("Width: " ..spell.static.lineWidth);
                print("Time:" ..spell.windUpTime);
                print("Animation: " ..spell.animationTime);
                print(spell.isBasicAttack);
                print("CastFrame: " ..spell.clientWindUpTime);
                print('--------------------------------------');
                lastDebugPrint = os.clock();
            end
        end]]
    end
end)


return {
    GetPlayerPosition = GetPlayerPosition,
    GetDashPos = GetDashPos, 
    GetClosestEUnit = GetClosestEUnit, 
    _endPos = _endPos, 
    SmartE = SmartE,

}