local common = module.load(header.id, 'Library/common')
local VPred = module.load(header.id, "Prediction/VP")
local evade = module.seek("evade")
local TS = module.internal('TS')
local orb = module.internal("orb")

local BaseTable = {
    qBaseDamage = {40, 53.75, 67.5, 81.25, 95},
    qStackDamage = {8, 10.75, 13.5, 16.25, 19},
    rStackDamage = {30, 55, 80},
    rStackMultiplier = {1, -1, 3, 5} -- 0, 2, 3 (good one riot)
}

local q_pred_input = {
    range = 450,
    delay = 0.5,
    width = 60,
    speed = math.huge,
    boundingRadiusMod = 1,
    collision = {
        hero = false,
        minion = false,
        wall = false
    }
}

local r_pred_input = {
    range = 1200,
    delay = 0.25,
    width = 100,
    speed = 1800,
    boundingRadiusMod = 1,
    collision = {
        hero = false,
        minion = false,
        wall = false
    }
}

local Samaritan = { }
function Samaritan.Project(sourcePosition, unitPosition, unitDestination, spellSpeed, unitSpeed)
    local toUnit = unitPosition - sourcePosition
    local toDestination = unitDestination - unitPosition
    local angle = math.abs(mathf.angle_between(sourcePosition, unitPosition, unitDestination))

    local cos = toUnit:norm():dot(toDestination:norm())
    local sin = math.abs(toUnit:norm():cross(toDestination:norm()))

    local unitVelocity = toDestination:norm() * unitSpeed
    local relativeUnitVelocity = toDestination:norm() * unitSpeed * cos

    local speedRatio = unitSpeed / spellSpeed
    local atanAverage = math.abs(math.atan(cos) + math.atan2(cos, sin)) * speedRatio

    local magicalFormula = math.pi * 0.5 - sin - math.atan(cos) + atanAverage

    local spellVelocity = toUnit:norm() * spellSpeed
    local relativeSpellVelocity = toUnit:norm() * (spellSpeed - relativeUnitVelocity:len()) / magicalFormula

    unitPosition = unitPosition + unitVelocity * network.latency

    local toPos = unitPosition - sourcePosition

    local a = unitVelocity:dot(relativeUnitVelocity) - spellVelocity:dot(relativeSpellVelocity)
    local b = unitVelocity:dot(toPos) * 2
    local c = toPos:dot(toPos)

    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return
    end

    local d = math.sqrt(discriminant)

    local t = 0

    if a ~= 0 then
        t = (2 * c) / (d - b)
    elseif b ~= 0 then
        t = -c / b
    end

    local castPosition = unitPosition + (unitVelocity * t)
    return castPosition, t
end

mathf.project = Samaritan.Project

local menu = menu("IntnnerGwen", "Int - Gwen")
    menu:dropdown('combo.select', 'Select Priority:', 1, {'E', 'Q'})
menu:menu('combo', 'Combo Settings')
    menu.combo:header('qq', "Snip Snip!")
        menu.combo:boolean("qcombo", "Use Q", true)
        menu.combo:slider("stacks", "Min. Stacks for Q", 4, 1, 4, 1)
    menu.combo:header('ww', "Hallowed Mist")
        menu.combo:boolean("wcombo", "Use W", true)
        menu.combo:boolean("w.evade", "^ Use to defend yourself", true)
        menu.combo['w.evade']:set("tooltip", "Evade 2.0 must be activated!")
    menu.combo:menu('evade', 'Evade Settings')
        menu.combo.evade:header('wp', "W - Settings")
        menu.combo.evade:dropdown('modeUser', 'Based on:', 2, {'My health', 'Damage Spell'})
        menu.combo.evade:header('dsa', "My Health - Settings")
        menu.combo.evade:slider("health", "Min. Health", 25, 0, 100, 10)

    menu.combo:header('ee', "Skip'n Slash")
        menu.combo:boolean("ecombo", "Use E", true)
        menu.combo:boolean("burstE", "Burts E", true) --Ignores the Q stacks to start the combo
        menu.combo['burstE']:set("tooltip", "Ignores the Q stacks to start the combo")
        --menu.combo:dropdown('modeE', 'Mode E', 1, {'Cursor', 'Side', 'Safe Position'});

    menu.combo:header('rr', "Needlework")
    menu.combo:menu('rset', 'R - Settings') --Needlework
        menu.combo.rset:boolean("rcombo", "Use R", true)
        menu.combo.rset:dropdown('useR', 'Mode R:', 2, {'Killsteal', 'Combo', 'Enemy Health', 'Killable with combo'})
        menu.combo.rset:slider("health", "Min. Enemy Health", 50, 0, 100, 10)

    menu:menu('harass', 'Hybrid/Harass Settings')
        menu.harass:header('qq', "Snip Snip!")
            menu.harass:boolean("qharras", "Use Q in Harass", true)
        menu.harass:header('ww', "Hallowed Mist")
            menu.harass:boolean("wharass", "Use W in Harass", true)
        menu.harass:header('ee', "Skip'n Slash")
            menu.harass:boolean("eharass", "Use E in Harass", true)
        menu.harass:slider("minMana", "Min. Mana for Harass >= {0%}", 45, 0, 100, 5)

    menu:menu('clear', 'LaneClear Settings')
    menu.clear:header('clkear', "Is it worth having Laneclear?")

    menu:menu('auto', 'Misc Settings')

        menu.auto:menu('flee', "Flee")
        menu.auto.flee:boolean('fleeE', 'Use E to Flee', true)
        menu.auto.flee:keybind("keyjump", "Flee", 'Z', nil)

        menu.auto:boolean("EGapcloser", "Use E on hero gapclosing / dashing", true);
        menu.auto.EGapcloser:set("tooltip", "If the enemy is coming towards you")
        menu.auto:keybind("safe", "Safe position", nil, 'A')
        menu.auto.safe:set("tooltip", "If this option is active, it will not use E or any dash under enemy towers or in dangerous places")
        menu.auto:menu("kills", "Killsteal Settings")
            menu.auto.kills:boolean("kill.q", "Killsteal with Q", true)
            menu.auto.kills:boolean("kill.e", "^~ With E dash for Q", true)
            menu.auto.kills:boolean("kill.r", "Killsteal with R", false)
        --menu.auto.kills:header('flash', "Flash Settings")
            --menu.auto.kills:boolean("flashQ", "Use Flash for Killsteal", false)
            --menu.auto.kills.flashQ:set("tooltip", "If Q is killable or if Q + E + Flash")

    menu:menu("draws", "Drawings")
        menu.draws:boolean("qrange", "Draw Q Range", true)
            menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("wrange", "Draw W Range", true)
            menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("erange", "Draw E Range", true)
            menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("rrange", "Draw R Range", true)
            menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)
        menu.draws:header('clkear', "Other settings")
        menu.draws:boolean("drwaTogle", "Draw Toggles", true)


local function IsValidTarget(object, distance) 
    return object and common.IsValidTarget(object) 
    and not object.buff[string.lower'SionPassiveZombie']
    and not object.buff[string.lower'KarthusDeathDefiedthen'] 
    and not object.buff[string.lower'KarthusDeathDefiedBuff']
    and not object.buff['fioraw'] 
    and not object.buff['sivire']
    and not object.buff['nocturneshroudofdarkness'] and (not distance or common.GetDistanceSqr(object) <= distance * distance)
end

local function PStacks()
    if player.isDead then 
        return 
    end 

    local stacks = 0
    if player.buff['gwenq'] and player.buff['gwenq'].stacks2 then 
        stacks = player.buff['gwenq'].stacks2
    end

    return stacks
end 

local function get_stacksR()
    if player.isDead then 
        return 
    end 

    local stacks = 0
    if player.buff['gwenrrecast'] and player.buff['gwenrrecast'].stacks2 then 
        stacks = player.buff['gwenrrecast'].stacks2
    end
    return stacks
end 

local function GetPassiveDamage(unit)
    local base = (0.01 + (0.0008 * common.GetTotalAP(player))) * unit.maxHealth
    local total = base

    if unit.type == TYPE_MINION then
        local hpPercent = (unit.health / unit.maxHealth) * 100
        if hpPercent < 40 then
            local max = 10 + (0.25 * common.GetTotalAP(player))
            total = math.max(max, total + (8 + 22 / 17 * (player.levelRef - 1)))
        end
    end
    return common.calculateMagicalDamage(unit, total)
end

local function DamageQ(target)
    if not target then 
        return
    end 

    if (player:spellSlot(0).level == 0) then 
        return 0 
    end 

    local base = BaseTable.qBaseDamage[player:spellSlot(0).level] + 0.25 * common.GetTotalAP(player)
    local stack = BaseTable.qStackDamage[player:spellSlot(0).level] * (PStacks()) + 0.05 * common.GetTotalAP(player)
    local total = base + stack

    if total <= 0 then 
        return 
    end 

    return common.calculateMagicalDamage(target, total)
end 

local function GetEDamage(unit)
    if not unit then 
        return 
    end 

    if (player:spellSlot(1).level == 0) then 
        return 0 
    end 

    local onhit = 10 + (0.15 * common.getTotalAP(player))
    return common.calculateMagicalDamage(unit, onhit)
end

local function GetRDamage(unit)
    if not unit then 
        return
    end 

    if (player:spellSlot(3).level == 0) then 
        return 0 
    end 

    local level = player:spellSlot(3).level

    local base = BaseTable.rStackDamage[level] + (0.08 * common.GetTotalAP(player)) + GetPassiveDamage(unit)

    local stacks = (get_stacksR())
    local total = base * stacks

    return common.calculateMagicalDamage(unit, total)
end

local function DamageR(target)
    if not target then 
        return
    end 

    if (player:spellSlot(3).level == 0) then 
        return 0 
    end 

    --270 / 495 / 720 (+ 72% AP)
    local damage = ({270, 495, 720})[player:spellSlot(3).level] + 0.72 * common.GetTotalAP(player) 

    if damage <= 0 then 
        return 
    end 

    return common.calculateMagicalDamage(target, damage)
end 

local function DamageRForCombo(target)
    if not target then 
        return
    end 

    if (player:spellSlot(3).level == 0) then 
        return 0 
    end 

    --270 / 495 / 720 (+ 72% AP)
    local damage = ({270, 495, 720})[player:spellSlot(3).level] * (target.maxHealth - target.health) + 0.72 * common.GetTotalAP(player) 

    if damage <= 0 then 
        return 
    end 

    return common.calculateMagicalDamage(target, damage)
end 

local function FirstDamageR(target)
    if not target then 
        return
    end 

    if (player:spellSlot(3).level == 0) then 
        return 0 
    end 

    
    local damage = ({30, 55, 80})[player:spellSlot(3).level] + 0.08 * common.GetTotalAP(player) 

    if damage <= 0 then 
        return 
    end 

    return common.calculateMagicalDamage(target, damage)
    --30 / 55 / 80 (+ 8% AP)
end

local function CirclePoints(CircleLineSegmentN, radius, position)
    local points = {}
    for i = 1, CircleLineSegmentN, 1 do
        local angle = i * 2 * math.pi / CircleLineSegmentN
        local point = vec3(position.x + radius * math.cos(angle), position.y, position.z + radius * math.sin(angle));
        table.insert(points, point)
    end 
    return points 
end

local function LoggerAA(target)
    if not target then 
        return 
    end 

    local pathStartPos = player.path.point[0]
    local playerPos = player.pos + (pathStartPos - player.pos):norm() * 450

    if player:spellSlot(2).state == 0 and (player:spellSlot(0).state ~= 0) then 
        if common.GetDistance(target, player) > common.GetAARange(target) then 
            if (menu.auto.safe:get() or not common.IsUnderDangerousTower(playerPos)) then 
                player:castSpell("pos", 2, target.pos)
            end
        end 
    else 
        if common.GetDistance(target, player) <= common.GetAARange(target) then 
            if player:spellSlot(2).state == 0 and player:spellSlot(0).state ~= 0 and player:spellSlot(1).state ~= 0 then 
                if (menu.auto.safe:get() or not common.IsUnderDangerousTower(playerPos)) then 
                    player:castSpell("pos", 2, target.pos)
                end
            end 
        end 
    end 
end 

local function CheckDashPrevention(dashRange)
	local enemiesInRange = common.GetEnemyHeroesInRange(dashRange)
	local closestEnemy, distanceEnemy = nil, math.huge
	for i = 1, #enemiesInRange do
		local check = enemiesInRange[i]
		if check and not check.isDead and check.isVisible then
			local enemyDist = player.path.serverPos:dist(check.path.serverPos)
			if enemyDist < distanceEnemy then
				distanceEnemy = enemyDist
				closestEnemy = check
			end
		end
	end
	if not closestEnemy then return true end
	if closestEnemy and common.IsValidTarget(closestEnemy) then
		return true
	elseif closestEnemy and not closestEnemy.isDead and closestEnemy.buff["zhonyasringshield"] then
		return false
	else
		return true
	end
end

local function UnderTurret(pos)
    if not pos then 
        return 
    end 

    for i=0, objManager.turrets.size[TEAM_ENEMY]-1 do
        local obj = objManager.turrets[TEAM_ENEMY][i]
        if obj and obj.health and obj.health > 0 and common.GetDistanceSqr(obj, pos) <= (915 ^ 2) + player.boundingRadius then
            return true
        end
    end
    return false
end

local function IsGoodPosition(dashPos)
	local segment = 475 / 5;
	local myHeroPos = vec3(player.x, player.y, player.z)
	for i = 1, 5, 1 do
        pos = myHeroPos + (dashPos - myHeroPos):norm()  * i * segment
		if navmesh.isWall(pos) then
			return false
		end
	end

	if common.IsUnderDangerousTower(dashPos) then
		return false
	end

	local enemyCheck = 2 
    local enemyCountDashPos = common.CountEnemiesInRange(dashPos, 600);
    if enemyCheck > #enemyCountDashPos then
    	return true
    end
    local enemyCountPlayer = #common.CountEnemiesInRange(player.pos, 400)
    if #enemyCountDashPos <= enemyCountPlayer then
    	return true
    end
    return false
end

local function InAARange(point, target)
    if (orb.combat.is_active()) then
        local targetpos = vec3(target.x, target.y, target.z)
        return common.GetDistance(point, targetpos) < common.GetAARange()
    else 
        return #common.CountEnemiesInRange(point, common.GetAARange()) > 0
    end
end

local function CanDash(target)
    if not target then 
        return 
    end 

    local bestPoint = vec3(0,0,0)
    local startPos = vec3(player.x, player.y, player.z)
    local endPos = vec3(target.x, target.y, target.z)

    local points = CirclePoints(15, 360, endPos)
    local enemies = #common.CountEnemiesInRange(endPos, 450)
    for i, point in pairs(points) do
        local count = #common.CountEnemiesInRange(point, 450)
        if common.IsUnderAllyTurret(point) then
            bestPoint = point;
            enemies = count - 1;
        elseif count < enemies then
            enemies = count;
            bestPoint = point;
        elseif count == enemies and common.GetDistance(game.mousePos, point) < common.GetDistance(game.mousePos, bestPoint) then
            enemies = count;
            bestPoint = point;
        end
    end

    if bestPoint == vec3(0,0,0) then
        return "NILL POS"
    end 

    local isGoodPos = IsGoodPosition(bestPoint)

    if common.GetDistance(target, player) > common.GetAARange(player) and isGoodPos then
        return bestPoint
    elseif isGoodPos and InAARange(bestPoint, target) then
        return bestPoint
    end

    return bestPoint
end 

local function CastE(target)
    if not target then 
        return 
    end 


    if player:spellSlot(2).state == 0 
    and (player:spellSlot(0).state == 0 or not player.buff['gweneattackbuff']) 
    and (menu.combo.burstE:get() or (player.buff['gwenq'] and PStacks() >= menu.combo.stacks:get())) 
    and (common.GetDistance(target, player) > common.GetAARange(player) or common.GetDistance(target, player) <= common.GetAARange(player) and not player.buff['gweneattackbuff']) then
        if common.GetDistance(target, player) < 700 and menu.combo.ecombo:get() and CheckDashPrevention(700) then  

            local startPos = player.pos 
            local endPos = target.pos 

            local startVector = startPos + (endPos - startPos):norm() * 450 
            local endPosVector = startPos + (startVector - startPos):norm() * 450 

            local bestPoint = CanDash(target)

            if bestPoint ~= vec3(0,0,0) and (menu.auto.safe:get() or not UnderTurret(bestPoint)) and not navmesh.isWall(bestPoint) then 
                player:castSpell("pos", 2, bestPoint)
            end
        end
    end 
end 

local function combo()
    --E 
    local target = common.GetTarget(800)

    if target and target ~= nil and IsValidTarget(target) then 

        local playerPos = player.pos + (mousePos - player.pos):norm() * 450

        if menu['combo.select']:get() == 1 then 
            if menu.combo.ecombo:get() then 
                CastE(target)
            end 

            if menu.combo.wcombo:get() then 
                if player:spellSlot(1).state == 0 and common.GetDistance(target, player) < 345 and player:spellSlot(1).name == "GwenW" then 
                    player:castSpell("self", 1)
                else 
                    if player:spellSlot(1).name == "GwenWRecast" and common.GetDistance(target, player) <= player.boundingRadius then 
                        player:castSpell("self", 1)
                    end
                end
            end 

            if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 and (player.buff['gwenq'] and PStacks() >= menu.combo.stacks:get()) then 
                local CastPosition = VPred.GetBestCastPosition(target, 0.25, 60, q_pred_input.range, q_pred_input.speed, player, true, "line")

                if CastPosition and common.GetDistance(CastPosition) < 450 then 
                    local castPos = mathf.project(player.pos, target.pos, CastPosition, q_pred_input.speed, target.moveSpeed)
                    if castPos then 
                        player:castSpell('pos', 0, castPos)
                    end
                end
            end 

            if menu.combo.rset.rcombo:get() and player:spellSlot(3).state == 0 then 
                if menu.combo.rset.useR:get() == 1 then 
                    if common.GetDistance(target) < 1000  and common.GetShieldedHealth("AP", target) < DamageR(target) then 
                        local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")
    
                        if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                            local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                            if castPos then 
                                player:castSpell('pos', 3, castPos)
                            end
                        end
                    end  
                    
                elseif menu.combo.rset.useR:get() == 2 then  --DamageRForCombo
                    if common.GetDistance(target) < 450 and common.GetShieldedHealth("AP", target) < DamageRForCombo(target) then 
                        local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")
    
                        if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                            local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                            if castPos then 
                                player:castSpell('pos', 3, castPos)
                            end
                        end
                    end  
                elseif menu.combo.rset.useR:get() == 3 then 
                    if common.GetPercentHealth(target) <= menu.combo.rset.health:get() then 
                        if common.GetDistance(target) < 500 then 
                            local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")
        
                            if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                                local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                                if castPos then 
                                    player:castSpell('pos', 3, castPos)
                                end
                            end
                        end  
                    end 
                elseif menu.combo.rset.useR:get() == 4 then   
                    if common.GetDistance(target) < 700 and common.GetShieldedHealth("AP", target) < (GetRDamage(target) + DamageQ(target) + GetEDamage(target) + DamageR(target)) then 
                        local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")
        
                        if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                            local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                            if castPos then 
                                player:castSpell('pos', 3, castPos)
                            end
                        end
                    end 
                end
            end 
        end 

        if menu['combo.select']:get() == 2 then 
            if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 and (player.buff['gwenq'] and PStacks() >= menu.combo.stacks:get()) then 
                local CastPosition = VPred.GetBestCastPosition(target, 0.25, 60, q_pred_input.range, q_pred_input.speed, player, true, "line")

                if CastPosition and common.GetDistance(CastPosition) < 450 then 
                    local castPos = mathf.project(player.pos, target.pos, CastPosition, q_pred_input.speed, target.moveSpeed)
                    if castPos then 
                        player:castSpell('pos', 0, castPos)
                    end
                end
            end 
            if menu.combo.ecombo:get() then 
                CastE(target)
            end 
            if menu.combo.wcombo:get() then 
                if player:spellSlot(1).state == 0 and common.GetDistance(target, player) < 345 and player:spellSlot(1).name == "GwenW" then 
                    player:castSpell("self", 1)
                else 
                    if player:spellSlot(1).name == "GwenWRecast" and common.GetDistance(target, player) <= player.boundingRadius then 
                        player:castSpell("self", 1)
                    end
                end
            end 

            if menu.combo.rset.rcombo:get() and player:spellSlot(3).state == 0 then 
                if menu.combo.rset.useR:get() == 1 then 
                    if common.GetDistance(target) < 1000  and common.GetShieldedHealth("AP", target) < DamageR(target) then 
                        local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")
    
                        if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                            local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                            if castPos then 
                                player:castSpell('pos', 3, castPos)
                            end
                        end
                    end  
                    
                elseif menu.combo.rset.useR:get() == 2 then  --DamageRForCombo
                    if common.GetDistance(target) < 450 and common.GetShieldedHealth("AP", target) < DamageRForCombo(target) then 
                        local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")
    
                        if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                            local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                            if castPos then 
                                player:castSpell('pos', 3, castPos)
                            end
                        end
                    end  
                elseif menu.combo.rset.useR:get() == 3 then 
                    if common.GetPercentHealth(target) <= menu.combo.rset.health:get() then 
                        if common.GetDistance(target) < 500 then 
                            local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")
        
                            if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                                local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                                if castPos then 
                                    player:castSpell('pos', 3, castPos)
                                end
                            end
                        end  
                    end 
                elseif menu.combo.rset.useR:get() == 4 then   
                    if common.GetDistance(target) < 700 and common.GetShieldedHealth("AP", target) < (GetRDamage(target) + DamageQ(target) + GetEDamage(target) + DamageR(target)) then 
                        local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")
        
                        if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                            local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                            if castPos then 
                                player:castSpell('pos', 3, castPos)
                            end
                        end
                    end 
                end 
            end 
        end
    end 
       
end

local function harass()
    if common.GetPercentMana(player) <= menu.harass.minMana:get() then 
        return 
    end 

    local target = common.GetTarget(800)

    if target and target ~= nil and IsValidTarget(target) then 

        local playerPos = player.pos + (mousePos - player.pos):norm() * 450

        if menu.harass.qharras:get() then 
            if player:spellSlot(0).state == 0 then 
                local CastPosition = VPred.GetBestCastPosition(target, 0.25, 60, q_pred_input.range, q_pred_input.speed, player, true, "line")

                if CastPosition and common.GetDistance(CastPosition) < 450 then 
                    local castPos = mathf.project(player.pos, target.pos, CastPosition, q_pred_input.speed, target.moveSpeed)
                    if castPos then 
                        player:castSpell('pos', 0, castPos)
                    end
                end
            end 
        end 

        if menu.harass.wharass:get() and player:spellSlot(1).state == 0 then 
            if player:spellSlot(1).state == 0 and common.GetDistance(target, player) < 345 and player:spellSlot(1).name == "GwenW" then 
                player:castSpell("self", 1)
            else 
                if player:spellSlot(1).name == "GwenWRecast" and common.GetDistance(target, player) <= player.boundingRadius then 
                    player:castSpell("self", 1)
                end
            end
        end 

        if player:spellSlot(2).state == 0 and (player:spellSlot(0).state ~= 0 or (not player.buff['gwenq'] and PStacks() == 0)) and player:spellSlot(1).state == 0 then 
            if (menu.auto.safe:get() or not common.IsUnderDangerousTower(playerPos)) then 
                if common.GetDistance(target, player) < 600 and  menu.harass.eharass:get() and not navmesh.isWall(playerPos) then  
                    local startPos = player.pos 
                    local endPos = target.pos 

                    local startVector = startPos + (endPos - startPos):norm() * 450 
                    local endPosVector = startPos + (startVector - startPos):norm() * 450 

                    if (menu.auto.safe:get() or not UnderTurret(endPosVector)) and not navmesh.isWall(endPosVector) then 
                        player:castSpell("pos", 2, endPosVector)
                    end
                end
            end
        else 
            if  menu.harass.eharass:get() then
                LoggerAA(target)
            end
        end 
    end
end

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and IsValidTarget(target) and common.IsEnemyMortal(target) then
            if menu.auto.kills['kill.q'] and player:spellSlot(0).state == 0 then 
                if common.GetDistance(target) < 450 and common.GetShieldedHealth("AP", target) < DamageQ(target) then 
                    local CastPosition = VPred.GetBestCastPosition(target, 0.25, 60, q_pred_input.range, q_pred_input.speed, player, true, "line")

                    if CastPosition and common.GetDistance(CastPosition) < 450 then 
                        local castPos = mathf.project(player.pos, target.pos, CastPosition, q_pred_input.speed, target.moveSpeed)
                        if castPos then 
                            player:castSpell('pos', 0, castPos)
                        end
                    end
                end 
            end 

            if menu.auto.kills['kill.e'] and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then 
                if common.GetShieldedHealth("AP", target)  < DamageQ(target) * 2 then 
                    local playerPos = player.pos + (mousePos - player.pos):norm() * 450
                    if common.GetDistance(target, player) > common.GetAARange(player) and common.GetDistance(target, player) < 600 and not navmesh.isWall(playerPos) then  
                        player:castSpell("pos", 2, target.pos)
                    end

                    if common.GetDistance(target) < 450 then 
                        local CastPosition = VPred.GetBestCastPosition(target, 0.25, 60, q_pred_input.range, q_pred_input.speed, player, true, "line")
    
                        if CastPosition and common.GetDistance(CastPosition) < 450 then 
                            local castPos = mathf.project(player.pos, target.pos, CastPosition, q_pred_input.speed, target.moveSpeed)
                            if castPos then 
                                player:castSpell('pos', 0, castPos)
                            end
                        end
                    end 
                end 
            end 

            if menu.auto.kills['kill.r'] and player:spellSlot(3).state == 0 then 
                if (common.GetDistance(target) < 1000 and common.GetShieldedHealth("AP", target) < FirstDamageR(target) and player:spellSlot(3).name == "GwenR") then 
                    local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")

                    if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                        local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                        if castPos then 
                            player:castSpell('pos', 3, castPos)
                        end
                    end
                elseif common.GetDistance(target) < common.GetAARange(player) and common.GetShieldedHealth("AP", target) < DamageR(target) and player:spellSlot(3).name == "GwenRRecast" then 
                    local CastPosition = VPred.GetBestCastPosition(target, 0.25, 100, r_pred_input.range, r_pred_input.speed, player, true, "line")

                    if CastPosition and common.GetDistance(CastPosition) < 1200 then 
                        local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)
                        if castPos then 
                            player:castSpell('pos', 3, castPos)
                        end
                    end
                end
            end
        end
    end
end 

local function EGabcloser()
    if not menu.auto.EGapcloser:get() then 
        return 
    end 

    local target = TS.get_result(function(res, obj, dist)
        if dist <= 800 and obj.path.isActive and obj.path.isDashing then 
            res.obj = obj
            return true
        end
    end).obj
    if target and IsValidTarget(target) then
        if common.IsMovingTowards(target, 800)  then 
            local pathStartPos = target.path.point[0]
            local pathEndPos = target.path.point[target.path.count] 
            if pathEndPos:dist(player) <= 500 then 
                local playerPos = player.pos + (pathEndPos - player.pos):norm() * -450
                if player:spellSlot(2).state == 0 then 
                    player:castSpell('pos', 2, playerPos)
                end
            end
        end
    end
end 

local function EvadeW()
    if not menu.combo['w.evade']:get() then 
        return 
    end 

    if menu.combo.evade['modeUser']:get() == 2 then 
        for i=evade.core.targeted.n, 1, -1 do
            local spell = evade.core.targeted[i]
            if spell and spell.owner.team == TEAM_ENEMY  and spell.target.ptr == player.ptr then 
                local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
                if player:spellSlot(1).state == 0 and common.GetDistance(spell.owner.pos) > 450 then 
                    if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                        player:castSpell("self", 1, player)
                    end 

                    if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) and common.GetDistance(spell.owner.pos) > 450 then 
                        player:castSpell("self", 1, player)
                    end
                end
            end
        end 

        for i=evade.core.skillshots.n, 1, -1 do
            local spell = evade.core.skillshots[i]
            if spell and spell.owner.team == TEAM_ENEMY and spell:contains(player) then 
                local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
                if player:spellSlot(1).state == 0 and common.GetDistance(spell.owner.pos) > 450 then  
                    if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                        player:castSpell("self", 1, player)
                    end 

                    if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) and common.GetDistance(spell.owner.pos) > 450 then  
                        player:castSpell("self", 1, player)
                    end
                end
            end
        end 
    elseif menu.combo.evade['modeUser']:get() == 1 then  
        local enemy = common.GetEnemyHeroes()
        for i, target in ipairs(enemy) do
            if target and IsValidTarget(target) and common.IsEnemyMortal(target) then
                if target.pos:dist(player.pos) <= 1200 and common.GetPercentHealth(player) <= menu.combo.evade.health:get() then 
                    player:castSpell("self", 1, player)
                end 
            end 
        end 
    end
end 

local function on_tick()
    if player.isDead then 
        return 
    end 
   
    if not evade then
		print(" ")
		console.set_color(79)
        print("You need to have enabled 'Evade 2.0' for FUNCTIONS scripts.")
        print("You can leave the module activated and turn it off so that the evade does not deviate")
        console.set_color(12)
	end

    EvadeW()
    KillSteal()
    EGabcloser()
    --GwenWRecast
    --GwenW 

    --GwenR 
    --GwenRRecast

    --print(player:spellSlot(3).name)

    if (orb.menu.combat.key:get()) then 
        combo()
    end

    if (orb.menu.hybrid.key:get()) then 
        harass()
    end 

    if menu.auto.flee.keyjump:get() then 
        player:move(mousePos)
        local playerPos = player.pos + (mousePos - player.pos):norm() * 450
        if player:spellSlot(2).state == 0 and menu.auto.flee.fleeE:get() and not navmesh.isWall(playerPos) then 
            player:castSpell('pos', 2, mousePos)
        end 
    end 
end 

local function OnDrawing()
    if (player and player.isDead and not player.isTargetable and player.buff[17] ~= nil) then 
        return 
    end
    if (player.isOnScreen) then
        if menu.draws.qrange:get() and player:spellSlot(0).level > 0 then
            graphics.draw_circle(player.pos, 500, 1, menu.draws.qcolor:get(), 100)
        end
        if menu.draws.wrange:get() and player:spellSlot(1).level > 0 then
            graphics.draw_circle(player.pos,  480, 1, menu.draws.wcolor:get(), 100)
        end
        if menu.draws.erange:get() and player:spellSlot(2).level > 0 then
            graphics.draw_circle(player.pos,  450, 1, menu.draws.ecolor:get(), 100)
        end
        if menu.draws.rrange:get() and player:spellSlot(3).level > 0 then
            graphics.draw_circle(player.pos,  1200, 1, menu.draws.rcolor:get(), 100)
        end

        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.draws.drwaTogle:get() then 
            if menu.auto.safe:get() then
                graphics.draw_text_2D("Safe Dash: ", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
                graphics.draw_text_2D("OFF", 17, pos.x + 45, pos.y + 50, graphics.argb(255, 255, 0, 0)) --graphics.argb(255, 51, 255, 51)
            else
                graphics.draw_text_2D("Safe Dash: ", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
                graphics.draw_text_2D("ON", 17, pos.x + 45, pos.y + 50, graphics.argb(255, 51, 255, 51))
            end
        end
    end 
end 


cb.add(cb.spell, OnSpell)
orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.draw, OnDrawing)

