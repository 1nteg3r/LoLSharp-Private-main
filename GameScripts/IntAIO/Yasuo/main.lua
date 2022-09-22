local orb = module.internal("orb");
local evade = module.seek('evade');
local TS = module.internal("TS")
local gpred = module.internal("pred")

local common = module.load(header.id, "Library/common");
local dlib = module.load(header.id, 'Library/damageLib');

local QDelay = 0.39 
local Q2Delay = 0.35 
local QDelays = 0.22
local Q2Delays = 0.315

local haveQ3 = false
local cDash = 0
local lastE = 0
local isDash = false
local posDash = vec3(0,0,0)

local StartTime = 0
local EndTime = 0 
local LifeTime = 0 

local Q1_MAX_WINDUP = 0.35
local Q1_MIN_WINDUP = 0.175
local LOSS_WINDUP_PER_ATTACK_SPEED = (0.35 - 0.3325) / 0.12

local additional_attack_speed = (player.attackSpeedMod - 1)

local q1_delay = math.max(Q1_MIN_WINDUP, Q1_MAX_WINDUP - (additional_attack_speed * LOSS_WINDUP_PER_ATTACK_SPEED))

local FlashSlot = nil
if player:spellSlot(4).name == "SummonerFlash" then
	FlashSlot = 4
elseif player:spellSlot(5).name == "SummonerFlash" then
	FlashSlot = 5
end


local SpellSlot = { }

SpellSlot.Q = {

    pred_input_Q = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        type = 'linear',
        delay = q1_delay,
        speed = math.huge,
        width = 20,
        range = 510,
        collision = { hero = false, minion = false, wall = false }
    },

    pred_input_Q2 = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        type = 'linear',
        delay = q1_delay,
        speed = 1200,
        width = 90,
        range = 1100,
        collision = { hero = false, minion = false, wall = true }
    },

    pred_input_Q3 = {
        boundingRadiusModSource = 0,
        boundingRadiusMod = 0,
        type = 'circular',
        delay = 0.001,
        speed = math.huge,
        radius = 220,
        range = 250,
    }
}

SpellSlot.W = {
    pred_input = {
        boundingRadiusModSource = 0,
        boundingRadiusMod = 0,
        delay = 0.001,
        speed = math.huge,
        width = math.huge,
        range = 475,
        collision = { hero = false, minion = false, wall = false }
    },

}

SpellSlot.E = {
    pred_input = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        type = 'linear',
        delay = 0.001,
        speed = 1200,
        width = 20,
        range = 475,
        collision = { hero = false, minion = false, wall = false }
    },

}


local function ver_trace_filter(Input, seg, obj)
    local totalDelay = (Input.delay + network.latency)
  
    if seg.startPos:dist(seg.endPos)
            + (totalDelay * obj.moveSpeed)
            + obj.boundingRadius > Input.range then
        return false
    end
  
    local collision = gpred.collision.get_prediction(Input, seg, obj)
    if collision then
        return false
    end
  
    if gpred.trace.linear.hardlock(Input, seg, obj) then
        return true
    end
  
    if gpred.trace.linear.hardlockmove(Input, seg, obj) then
        return true
    end
  
    local t = obj.moveSpeed / Input.speed
  
    if gpred.trace.newpath(obj, totalDelay, totalDelay + t) then
        return true
    end
  
    return true
end
  
local Compute = function(input, seg, obj)
    if input.speed == math.huge then
        input.speed = obj.moveSpeed * 3
    end
  
    local toUnit = (obj.path.serverPos2D - seg.startPos)
  
    local cos = obj.direction2D:dot(toUnit:norm())
    local sin = math.abs(obj.direction2D:cross(toUnit:norm()))
    local atan = math.atan(sin, cos)
  
    local unitVelocity = obj.direction2D * obj.moveSpeed * (1 - cos)
    local spellVelocity = toUnit:norm() * input.speed * (2 - sin)
    local relativeVelocity = (spellVelocity - unitVelocity) * (2 - atan)
    local totalVelocity = (unitVelocity + spellVelocity + relativeVelocity)
  
    local pos = obj.path.serverPos2D + unitVelocity * (input.delay + network.latency)
  
    local totalWidth = input.width + obj.boundingRadius
  
    pos = pos - totalVelocity * (totalWidth / totalVelocity:len())
  
    local deltaWidth = math.abs(input.width, obj.boundingRadius)
    deltaWidth = deltaWidth * cos + deltaWidth * sin
  
    local relativeWidth = input.width
  
    if input.width < obj.boundingRadius then
        relativeWidth = relativeWidth + deltaWidth
    else
        relativeWidth = relativeWidth - deltaWidth
    end
  
    pos = pos - spellVelocity * (relativeWidth / relativeVelocity:len())
    pos = pos - relativeVelocity * (deltaWidth / spellVelocity:len())
  
    local toPosition = (pos - seg.startPos)
  
    local a = unitVelocity:dot(unitVelocity) - spellVelocity:dot(spellVelocity)
    local b = unitVelocity:dot(toPosition) * 2
    local c = toPosition:dot(toPosition)
  
    local discriminant = b * b - 4 * a * c
  
    if discriminant < 0 then
        return
    end
  
    local d = math.sqrt(discriminant)
  
    local t1 = (2 * c) / (d - b)
    local t2 = (-b - d) / (2 * a)
  
    return math.min(t1, t2)
end
  
local real_target_filter = function(input)
    
    local target_filter = function(res, obj, dist)
        if dist > input.range then
            return false
        end
  
        local seg = gpred.linear.get_prediction(input, obj)
  
        if not seg then
            return false
        end
  
        res.seg = seg
        res.obj = obj
  
        if not ver_trace_filter(input, seg, obj) then
            return false
        end
  
        local t1 = Compute(input, seg, obj)
  
        if t1 < 0 then
            return false
        end
  
        res.pos = (gpred.core.get_pos_after_time(obj, t1) + seg.endPos) / 2
  
        local linearTime = (seg.endPos - seg.startPos):len() / input.speed
  
        local deltaT = (linearTime - t1)
        local totalDelay = (input.delay + network.latency)
  
        if deltaT < totalDelay then
            return true
        end
        return true
    end
    return
    {
        Result = target_filter,
    }
end


local str = {[0] = "Q", [1] = "W", [2] = "E", [3] = "R"}

local menu = menu("intnnerYasuo", "Int - Yasuo")
menu:menu("combo", "Combo Settings")
        menu.combo:menu('qsettings', "Q Settings")
            menu.combo.qsettings:boolean("qcombo", "Use Q", true)
            menu.combo.qsettings:boolean("qdash", "Use Q In Dash", true)
        menu.combo:menu('wsettings', "Wind Wall")
        menu.combo.wsettings:boolean('smartW', "Use W In Combo", true)
            menu.combo.wsettings:boolean('wspell', "Use Wind Wall", true)
            menu.combo.wsettings:slider("daggerSpell", "Level Spell >", 2, 1, 5, 1);
            menu.combo.wsettings.daggerSpell:set("tooltip", "1 - Low | 2 - Medium | 3 - Danger")
        menu.combo:menu('esettings', "E Settings")
            menu.combo.esettings:boolean("ecombo", "Use E", true)
            menu.combo.esettings:boolean("egab", "Use E Gabclose", true)
            menu.combo.esettings:dropdown('modegab', 'Gab Mode:', 2, {'Follow Mouse', 'Target'});
        menu.combo:menu('rsettings', "R Settings")
            menu.combo.rsettings:boolean("rcombo", "Use R", true)
            menu.combo.rsettings:dropdown('modegab', 'R Mode:', 2, {'Fast', 'Delay'});
            menu.combo.rsettings:header('delay', "Delay Mode")
            menu.combo.rsettings:slider("delayed", "Delay to use R", 0, 1, 1000, 1);
            menu.combo.rsettings:header('Another', "Misc Settings")
            menu.combo.rsettings:slider("MinTargetsR", "Use R Min. Targets", 2, 1, 5, 1);
            menu.combo.rsettings:boolean("killsteal", "Use R if KillSteal", true)
            menu.combo.rsettings:menu("blacklist", "Blacklist!")
            for l, enemy in pairs(common.GetEnemyHeroes()) do
                if enemy then
                    menu.combo.rsettings.blacklist:boolean(enemy.charName, "Do not use R on: " .. enemy.charName, false)
                end
            end
    menu:menu("harass", "Hybrid/Harass Settings")
        menu.harass:menu('qsettings', "Q Settings")
            menu.harass.qsettings:boolean("qharass", "Use Q", true)
            menu.harass.qsettings:boolean("qdash", "Use Q3", true)
    menu:menu("clear", "Lane Clear Settings")
        menu.clear:menu('qsettings', "Q Settings")
            menu.clear.qsettings:boolean("qclear", "Use Q", true)
            menu.clear.qsettings:boolean("q3clear", "Use Q3 ", true)
        menu.clear:menu('esettings', "E Settings")
            menu.clear.esettings:boolean("eclear", "Use E", true)
            menu.clear.esettings:slider("minlife", "My health to use E", 45, 1, 100, 1);
            menu.clear.esettings:slider("MinTarget", "Use E in Lane | Min. Targets", 1, 1, 5, 1);
    menu:header("xd", "Misc Settings")
    menu:keybind("autoq", "Auto Q | Stack", nil, 'G')
    menu:keybind("eturret", "Use E|R under Turret", nil, "T")
    menu:keybind("keyjump", "Flee", 'Z', nil)
    menu:boolean("autoQ3", "Auto Q3", true)
menu:menu("draws", "Drawings")
    menu.draws:boolean("q_range", "Draw Q Range", true)
    menu.draws:color("q", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("q3_range", "Draw Q Extension Range", true)
    menu.draws:color("q3", "Q3 Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("e_range", "Draw E Range", true)
    menu.draws:color("e", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("r_range", "Draw R Range", true)
    menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)

local function CountEnemiesInRange()
    local enemies_in_range = {}
    for i = 0, objManager.enemies_n - 1 do
        local enemy = objManager.enemies[i]
        if  enemy and common.isValidTarget(enemy) and player.path.serverPos:dist(enemy.path.serverPos) < 600 and (enemy.buff[29] or enemy.buff[30]) then
            enemies_in_range[#enemies_in_range + 1] = enemy
        end
    end
    return enemies_in_range
end

local excluded_minions = {
    ["CampRespawn"] = true,
    ["PlantMasterMinion"] = true,
    ["PlantHealth"] = true,
    ["PlantSatchel"] = true,
    ["PlantVision"] = true
}

local function MinionsAndMonsters(pos, range)
    pos = pos or player.pos
    range = range or math.huge 
    local result = {}
    local Count = 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and common.IsValidTarget(minion) and minion.health > 0 and minion.maxHealth > 100 and minion.maxHealth < 10000 and not minion.name:find("Ward") and not excluded_minions[minion.name] then 
            if minion.pos:dist(pos) < range then
                result[#result + 1] = minion
            end
        end
    end 

    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local Monsters = objManager.minions[TEAM_NEUTRAL][i]
        if Monsters and common.IsValidTarget(Monsters) and Monsters.health > 0 and Monsters.maxHealth > 100 and Monsters.maxHealth < 10000 and not Monsters.name:find("Ward") and not excluded_minions[Monsters.name] then 
            if Monsters.pos:dist(pos) < range then
                result[#result + 1] = Monsters
            end
        end
    end 
    return result
end

local function IsReady(extraTime, slot)
    extraTime = 0 

    if extraTime == 0 then 
        return player:spellSlot(slot).state == 0 
    else 
        return player:spellSlot(slot).cooldown + extraTime/0.001 - game.time < 0
    end
end 

local function CanCastQCir()
    if posDash then 
        if player.pos:dist(posDash) < 150 then 
            return true
        end
    end
    return false 
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
	local powCalc = 220
	if Distance(minion.pos, player.pos, target.pos, true, true) <= powCalc then
		return true
	end
	return false
end

local function IsDashing()
    return os.clock() - lastE <= 100 or player.path.isDashing
end 

local function OltData(target)
    if (IsDashing()) then 

        local bestHit = 0
        local bestPos = vec3(0,0,0)

        for i = 0, 360, 33.5 do
            angle = i * (math.pi/180)

            myPos = player.pos
            tPos = target.pos
        
            rot = common.RotateAroundPoint(tPos, myPos, angle)
            for i = 0, objManager.enemies_n - 1 do
                local enemy = objManager.enemies[i]
                if enemy and common.isValidTarget(enemy) and enemy.pos:dist(rot) < 220 then 
                    bestHit = bestHit + 1
                    bestPos = rot
                end 
            end
        end 

        if bestHit > 0 and bestPos then 
            player:castSpell('pos', 0, target.path.serverPos)
            common.DelayAction(function() player:castSpell('pos', FlashSlot, bestPos) end)
        end
    end 
end 

local function GetLineFarmPosition(target)
	local NH = 0
	local minioncollision = nil
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and common.IsValidTarget(minion) then 
            if CanHitSkillShot(target, minion) then
                NH = NH + 1
                minioncollision = minion
            end
        end
	end

    local enemies = common.GetEnemyHeroes()
    for i, enemy in ipairs(enemies) do	
        if enemy and common.IsValidTarget(enemy) then 
            if CanHitSkillShot(target, enemy) then
                NH = NH + 1
                minioncollision = enemy
            end
        end 
    end

    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local minion1 = objManager.minions[TEAM_NEUTRAL][i]
        if minion1 and common.IsValidTarget(minion1) then 
            if CanHitSkillShot(target, minion1) then
                NH = NH + 1
                minioncollision = minion1
            end
        end
	end

    return NH , minioncollision
end

local function LisTEnemy()
    local minioncollision = nil
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and common.IsValidTarget(minion) then 
            --if CanHitSkillShot(target, minion) then
                minioncollision = minion
            --end
        end
	end

    local enemies = common.GetEnemyHeroes()
    for i, enemy in ipairs(enemies) do	
        if enemy and common.IsValidTarget(enemy) then 
            --if CanHitSkillShot(target, enemy) then
                minioncollision = enemy
            --end
        end 
    end

    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local minion1 = objManager.minions[TEAM_NEUTRAL][i]
        if minion1 and common.IsValidTarget(minion1) then 
            --if CanHitSkillShot(target, minion1) then
                minioncollision = minion1
            --end
        end
	end
    return minioncollision
end

local function GetMinionsHit(Pos, radius)
	local count = 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minions = objManager.minions[TEAM_ENEMY][i]
        if minions then 
            if common.GetDistance(minions, Pos) < radius then
                count = count + 1
            end
        end
	end
	return count
end

local function Floor(number) 
    return math.floor((number) * 100) * 0.01
end

--GetLineFarmPosition(source, range, radius, objects, count)
local function GetQCirObj()
    local result = nil
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and common.IsValidTarget(minion) then 
            local countMinion, BestPos = GetLineFarmPosition(minion)
            if BestPos and BestPos.pos:dist(player.pos) < 220 then
                result = BestPos
            end
        end
	end

    local enemies = common.GetEnemyHeroes()
    for i, enemy in ipairs(enemies) do	
        if enemy and common.IsValidTarget(enemy) then 
            local countMinion, BestPos = GetLineFarmPosition(enemy)
            if BestPos and BestPos.pos:dist(player.pos) < 220 then
                result = BestPos
            end
        end 
    end
    return result
end

local function GetQCirTarget()
    local result = nil
    local enemies = common.GetEnemyHeroes()
    for i, enemy in ipairs(enemies) do	
        if enemy and common.IsValidTarget(enemy) then 
            if enemy.path.serverPos:distSqr(posDash) < SpellSlot.Q.pred_input_Q3.radius + 20 then 
                result = enemy
            end
        end
    end
    return result
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

local function CanCastDelayR(target, isAirBlade)
    local delayTime = 0 

    if not isAirBlade then 
        delayTime = 0.89 
    else 
        delayTime = 0.85
    end 
    
    if target.buff[30] then 
        return true 
    end 

    if target.buff[29] and game.time - target.buff[29].startTime >= delayTime * (target.buff[29].endTime - target.buff[29].startTime) then 
        return true 
    end 
    return false
end

local function HaveR(target)
    return target.buff[29] or target.buff[30]
end

local function GetPosAfterDash(target)
    return player.path.serverPos + (target.path.serverPos- player.path.serverPos):norm() * 475
end

local function HaveE(target)
    return target.buff['yasuoe']
end 

local function CanDash(target, inQCir, underTower, pos, isAirBlade)
    if not target then 
        return
    end 

    if HaveE(target) then 
        return 
    end 

    --print'valid target'

    if not pos then 
        local pre_predPos = gpred.core.lerp(target.path, network.latency + 0.001, target.moveSpeed)

        if pre_predPos then 
            local predPos = vec3(pre_predPos.x, target.y, pre_predPos.y)
            pos = predPos
        end 
    end 

    local posAfterE = GetPosAfterDash(target)

    if (underTower or not UnderTurret(posAfterE)) then 
        --print'under or not'
        if inQCir then 
            --print'circle'
            local enemies = common.GetEnemyHeroes()
            for i, enemy in ipairs(enemies) do	
                if enemy and common.IsValidTarget(enemy) then 
                    local countMinion, BestPos = GetLineFarmPosition(enemy)
                    if BestPos and BestPos.pos:dist(player.pos) <= 300 then
                        return true 
                    end 
                end 
            end
        else 
            if not isAirBlade then 
                if posAfterE:dist(pos) < pos:dist(player.pos) then 
                    --print'not isAirBlade'
                    return true 
                end 
            else 
                if posAfterE:dist(pos) < 1400 then 
                    --print'isAirBlade'
                    return true 
                end
            end
        end
        
        if evade.core.is_action_safe(posAfterE, player.moveSpeed, 0.001) then 
            -- print'safe'
            return true 
        end 
    end 
    return false
end

local function CastQ3()
    local target = TS.get_result(real_target_filter(SpellSlot.Q.pred_input_Q2).Result) 

    if not target.obj then 
        return 
    end 

    if target.obj.path.serverPos:dist(player.path.serverPos) > 1100 then
        return
    end 

    if target.pos and common.IsValidTarget(target.obj) then 
        if player:spellSlot(0).state == 0 and target.seg.startPos:distSqr(target.seg.endPos) < (1100 * 1100) then
            player:castSpell("pos", 0, vec3(target.pos.x, mousePos.y, target.pos.y))
        end
    end 
end

local function CastQ()
    local target = common.GetTarget(505)

    if not target then 
        return 
    end 

    if target.path.serverPos:dist(player.path.serverPos) > 450 then
        return
    end 

    if target and common.IsValidTarget(target) then 
        local seg = gpred.linear.get_prediction(SpellSlot.Q.pred_input_Q, target)
        if seg and seg.startPos:distSqr(seg.endPos) < (450 * 450) then
            player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
        end
    end 
end

local function CastQCir(obj)
    if not obj then 
        return 
    end

    if obj and common.isValidTarget(obj) then 
        local pre_predPos = gpred.core.lerp(obj.path, network.latency + 0.001, obj.moveSpeed)

        if pre_predPos then 
            local predPos = vec3(pre_predPos.x, obj.y, pre_predPos.y)
            if predPos and predPos:distSqr(obj.pos) < (220 * 220) then
                player:castSpell("pos", 0, predPos)
                --print'now'
            end
        end
    end 
end 

local function GetClosestEUnit(pos)
    local distance = 0
    local unit = nil 

    for i=0, objManager.maxObjects-1 do
        local enemy = objManager.get(i)
        if enemy and common.IsValidTarget(enemy) and enemy.team == TEAM_ENEMY and (enemy ~= pos) then 
            if CanDash(enemy, false, menu.eturret:get(), pos, false) and enemy.path.serverPos:dist(player.path.serverPos) < 475 and common.GetDistance(GetPosAfterDash(enemy), pos) < common.GetDistance(pos) and distance < common.GetDistance(enemy) then 
                local distance =  GetPosAfterDash(enemy):dist(pos)
                --if (dist <= distance) then 
                    distance = dist;
                    unit = enemy;
                --end
            end
        end 
    end
    return unit
end

local function GetBestDashObjToUnit(target, inQCir, underTower, isAirBlade)
    local pos = vec3(0,0,0)
    local result = nil 
    local closest = 0
    if not isAirBlade then 
        local res = gpred.linear.get_prediction(SpellSlot.E.pred_input, target)
        if res then 
            pos = vec3(res.endPos.x, target.y, res.endPos.y)
        end
    else 
        pos = target.path.serverPos
    end

    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and common.IsValidTarget(minion) then 
            if common.GetDistance(minion) <= SpellSlot.E.pred_input.range and GetPosAfterDash(minion):dist(target) < player.pos:dist(target) and closest < player.pos:dist(minion.pos) and CanDash(minion, inQCir, underTower, pos, isAirBlade) then
                closest = GetPosAfterDash(minion):dist(pos)
                result = minion
            end 
        end
	end

    local enemies = common.GetEnemyHeroes()
    for i, enemy in ipairs(enemies) do	
        if enemy and common.IsValidTarget(enemy) then 
            if common.GetDistance(enemy) <= SpellSlot.E.pred_input.range and GetPosAfterDash(enemy):dist(target) < player.pos:dist(target) and closest < player.pos:dist(enemy.pos) and (enemy ~= target) and CanDash(enemy, inQCir, underTower, pos, isAirBlade) then
                closest = GetPosAfterDash(enemy):dist(pos)
                result = enemy
            end 
        end 
    end
    return result
end 

local function GetRTarget(isAirBlade)
    local result = nil
    --local result_list2 = nil

    local nears = nil 
    local nears_cout = 0
    
    local target = common.GetTarget(1400)

    if not target then  
        return
    end 

    if not HaveR(target) then
        return 
    end

    local enemies = common.GetEnemyHeroes()
    for i, enemy in ipairs(enemies) do	
        if enemy and common.IsValidTarget(enemy) then     
            if enemy.path.serverPos:dist(target.path.serverPos) < 400 and (enemy ~= target) and HaveR(enemy) then 
                nears = enemy 
                nears_cout = nears_cout + 1
            end 
        end 
    end

    if nears and nears_cout > 0 then 
        if (dlib.GetSpellDamage(0, nears) +  dlib.GetSpellDamage(3, nears) >= common.GetShieldedHealth("AD", nears) or nears_cout >= menu.combo.rsettings.MinTargetsR:get()) then 
            result = nears
        end
    end 

    if #CountEnemiesInRange() == 0 then 
        local enemies = common.GetEnemyHeroes()
        for j, i in ipairs(enemies) do	
            if i and (menu.combo.rsettings.modegab:get() == 2 and CanCastDelayR(i, isAirBlade)) then 
                result = i
            end 
        end
    end 
    return result
end

local function GetBestDashObj(underTower)
    local dist = 0 
    local result_target = nil 

    if menu.combo.rsettings.rcombo:get() and player:spellSlot(3).state == 0 and IsReady(50, 0) then 
        local target = GetRTarget(true)

        if target then 
            if common.IsInRange(475, target, player) and CanDash(target, true, underTower, target.path.serverPos, true) then 
                result_target = target
            else 
                result_target = GetBestDashObjToUnit(target, true, underTower, true) 
                --print'here'
            end
        end
    end

    if menu.combo.esettings.ecombo:get() and player:spellSlot(2).state == 0 then 
        local target = common.GetTarget(475)

        if target and haveQ3 and IsReady(50, 0) then 
            local nearObj = GetBestDashObjToUnit(target, true, underTower);
            if nearObj then 
                --_Player.CountEnemiesInRange(Manager.SpellManager.Q.Range + Manager.SpellManager.E.Range / 2) == 1))
                if #common.CountEnemiesInRange(nearObj.pos, 220) > 1 or #common.CountEnemiesInRange(player.pos, 505+475/2) == 1 then 
                    result_target = nearObj
                    --print'result_target'
                end 
            end
        end

        if (target and ((cDash > 0 and CanDash(target, false, underTower)) or (haveQ3 and IsReady(50, 0) and CanDash(target, true, underTower)))) then 
            result_target = target
            --print'vad'
        end 

        local target_q = common.GetTarget(1400)

        if target_q and common.GetPercentHealth(player) > 40 then 
            
            local nearObj = GetBestDashObjToUnit(target_q, false, underTower)
            local canDash = false

            if (IsReady(50, 0)) then 
                local nearObjQ3 = GetBestDashObjToUnit(target_q, true, underTower);
                if (nearObjQ3) then 
                
                    result_target = nearObjQ3
                    canDash = true
                    --print'nearObjQ3'
                
                end 
            end

            if (not cDash and nearObj and not HaveE(target_q) and common.GetDistance(target_q, player) > common.GetAARange() * 0.7) then 
                canDash = true
                --print'true'
            end 

            if (canDash) then 
                if (not nearObj and common.IsInRange(475, target_q, player) and CanDash(target_q, false, underTower)) then 
                    result_target = target;
                end 
                if (nearObj) then 
                    --print'nearObj'
                    result_target = nearObj;
                    canDash = false
                end
            end 
        end 
    end 
    return result_target
end

local function GetDashObj(underTower)
    local result = nil 

    for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
        local enemy = objManager.minions[TEAM_ENEMY][i]
        if enemy and common.IsValidTarget(enemy) then    
            if common.IsInRange(475, player, enemy) and (underTower or not UnderTurret(GetPosAfterDash(enemy))) then 
                result = enemy
            end
        end 
    end
    return result
end

local function GetBestObjToMouse(underTower)
    local pos = mousePos
    local result = nil 
    local target = GetDashObj(underTower)
    if target then 
        if CanDash(target, false, true, pos) then 
            result = target
        end
    end
    return result
end

local function Killsteal()
    for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and common.IsEnemyMortal(enemy) then
		    local hp = common.GetShieldedHealth("AD", enemy)
      	    local dist = player.path.serverPos:distSqr(enemy.path.serverPos)
			if player:spellSlot(0).state == 0 and dist < (450 * 450) and not haveQ3 and dlib.GetSpellDamage(0, enemy) > hp and not IsDashing() then
                local seg = gpred.linear.get_prediction(SpellSlot.Q.pred_input_Q, enemy)
                if seg and seg.startPos:distSqr(seg.endPos) < (450 * 450) then
                    player:castSpell("pos", 0, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
                end
            end 

            if player:spellSlot(0).state == 0 and dist < (1100 * 1100) and haveQ3 and dlib.GetSpellDamage(0, enemy) > hp and not IsDashing() then
                local seg = gpred.linear.get_prediction(SpellSlot.Q.pred_input_Q2, enemy)
                if seg and seg.startPos:distSqr(seg.endPos) < (1100 * 1100) then
                    player:castSpell("pos", 0, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
                end
            end 
        end 
    end
end

local function on_tick()
    if player.isDead then 
        return 
    end 

    Killsteal()

    if player:spellSlot(0).state == 0 and haveQ3 and FlashSlot and player:spellSlot(FlashSlot).state == 0 then 
        local range = 425 + 220
        local target = common.GetTarget(range)

        if target then 
            if ((common.GetPercentHealth(player) > 40 and common.GetPercentHealth(target) < 50 or dlib.GetSpellDamage(0, target) > target.health) and target.pos:dist(player.pos) > 400) then 
                --print'here'
                OltData(target)
            end
        end

    end

    if menu.combo.wsettings.wspell:get() and player:spellSlot(1).state == 0 then 
        for i=evade.core.targeted.n, 1, -1 do
            local spell = evade.core.targeted[i]
            if spell and spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO and spell.target.ptr == player.ptr then 
                local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
                if player:spellSlot(1).state == 0 then 
                    if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                        player:castSpell("pos", 1, spell.owner.pos)
                    end 

                    if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                        player:castSpell("pos", 1, spell.owner.pos)
                    end
                end
            end 
        end

        for i=evade.core.skillshots.n, 1, -1 do
            local spell = evade.core.skillshots[i]
            if spell.missile and spell.missile.speed then
                if spell and spell.owner.team == TEAM_ENEMY and spell:contains(player) then  
                    local hit_time = (player.path.serverPos:dist(spell.missile.pos) - player.boundingRadius) / spell.missile.speed
                    if hit_time > (network.latency) and hit_time < (0.25 + network.latency) then 
                        player:castSpell("pos", 1, spell.owner.pos)
                    end
                end 
            end
        end
    end
    --print(IsReady(50, 0))
    if player:spellSlot(0).name == 'YasuoQ3Wrapper' then 
        haveQ3 = true;
    else
        haveQ3 = false;
    end

    if (player.isDead) then 
        if (isDash) then
        
            isDash = false;
            posDash = vec3(0,0,0);
            lastE = 0
            return 
        end
    end

    if (isDash and not player.path.isDashing) then
    
        isDash = false
        common.DelayAction(
            function() 
                if not isDash then 
                    posDash = vec3(0,0,0);
                    lastE = 0
                end 
            end,
            0.50
        )
    end 

    if orb.menu.combat.key:get() then 

        if menu.combo.rsettings.rcombo:get() and player:spellSlot(3).state == 0 then 
            local target = GetRTarget()
            if target and common.isValidTarget(target) and (menu.eturret:get() or not UnderTurret(GetPosAfterDash(target))) then 
                player:castSpell('pos', 3, target.pos)
            end 


            local enemy = common.GetTarget(1400) 
            if #common.CountEnemiesInRange(player.pos, 1400) > 0 then
                if enemy and common.isValidTarget(enemy) and (menu.eturret:get() or not UnderTurret(GetPosAfterDash(enemy))) then 
                    if enemy.path.serverPos:dist(player.path.serverPos) < 500 and HaveR(enemy) then 
                        if CanCastDelayR(enemy, true) then 
                            player:castSpell('pos', 3, enemy.pos)
                        end 
                    end 
                end 
            end
        end

        if menu.combo.wsettings.smartW:get() and player:spellSlot(1).state == 0 then  
            local target = common.GetTarget(475) 

            if target and common.isValidTarget(target) then 
                if common.GetPercentHealth(target) > common.GetPercentHealth(player) then 
                    if #common.CountAllysInRange(player.pos, 500) < #common.CountEnemiesInRange(player.pos, 700) then 
                        local predPos = gpred.linear.get_prediction(SpellSlot.W.pred_input, target)

                        if predPos then
                            if (common.GetDistance(predPos.endPos) > 100 and common.GetDistance(predPos.endPos) < 330) then
                                player:castSpell("pos", 1, vec3(predPos.endPos.x, target.y, predPos.endPos.y))
                            end 
                        end
                    end
                else 
                    if common.GetPercentHealth(player) <= 30 then
                        local predPos = gpred.linear.get_prediction(SpellSlot.W.pred_input, target)

                        if predPos then
                            if (common.GetDistance(predPos.endPos, player) > 100 and common.GetDistance(predPos.endPos, player) < 330) then
                                player:castSpell("pos", 1, vec3(predPos.endPos.x, target.y, predPos.endPos.y))
                            end 
                        end
                    end 
                end
            end
        end

        if menu.combo.esettings.ecombo:get() and player:spellSlot(2).level > 0 then  
            local target = common.GetTarget(475)
            if target and common.isValidTarget(target) then 
                if not HaveE(target) then 
                    local enemy = LisTEnemy()
                    if enemy and common.IsValidTarget(enemy) then 
                        if common.IsInRange(475 * 2, enemy, player) and not HaveE(enemy) and GetPosAfterDash(enemy) then 
                            if (common.GetDistance(enemy, target) < common.GetDistance(target, player) or common.GetDistance(enemy, target) < common.GetAARange(target) + 100) then 
                                if (menu.eturret:get() or not UnderTurret(GetPosAfterDash(target))) then 
                                    player:castSpell("obj", 2, target)
                                end
                            end
                        end
                    end
                end
            end
        end

        local targetE = GetBestDashObj(menu.eturret:get()) 

        if targetE and common.IsValidTarget(targetE) then 
            player:castSpell("obj", 2, targetE)
        end

        --[[if menu.combo.esettings.egab:get() then 
            local target = common.GetTarget(475 * 2)

            if target and common.isValidTarget(target) then 
                local unit = GetClosestEUnit(target.path.serverPos)

                if unit then 
                    player:castSpell("obj", 2, unit)
                end 
            end 
        end ]]

        if (player:spellSlot(0).state == 0) then

            if (IsDashing()) then
                local target = GetRTarget(true)

                if target then 
                    if CastQCir(target) then 
                        common.DelayAction(function() player:castSpell("pos", 3, target.pos) end, 0.50)
                    end 
                end 
            end
            if (IsDashing()) then
                if (CanCastQCir()) then
                    local enemies = common.GetEnemyHeroes()
                    for i, enemy in ipairs(enemies) do	
                        if enemy and common.IsValidTarget(enemy) then 
                            if enemy.pos:dist(posDash) < SpellSlot.Q.pred_input_Q3.radius + 20 then 
                                CastQCir(enemy)
                            end 

                            if (not haveQ3 and menu.combo.esettings.ecombo:get() and menu.autoq:get() and #common.CountEnemiesInRange(player.pos, 700) == 0) then 
                                if enemy.pos:dist(posDash) < SpellSlot.Q.pred_input_Q3.radius + 20 then 
                                    CastQCir(enemy)
                                end 
                            end
                        end 
                    end
                    
                end
            elseif (not targetE)  then 
                if not haveQ3 then 
                    CastQ()
                else
                    CastQ3()
                end
            end
        end 
    end 

    if orb.menu.hybrid.key:get() then 
        if (player:spellSlot(0).state == 0) and not IsDashing() then

            if (not haveQ3) then 
                if menu.harass.qsettings.qharass:get() then
                    CastQ();
                end

                for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
                    local minions = objManager.minions[TEAM_ENEMY][i]
                    if common.IsInRange(475, minions, player) then 
                        if minions.health <= dlib.GetSpellDamage(0, minions) then 
                            player:castSpell("pos", 0, minions.path.serverPos)
                        end 
                    end
                end
            elseif (menu.harass.qsettings.qdash:get()) then 
                CastQ3();
            end 
        end 
    end

    if orb.menu.lane_clear.key:get() then 
        local minion = MinionsAndMonsters(player.pos, 475)
        for i, MinionsMonster in pairs(minion) do
            
            if not MinionsMonster then 
                return     
            end  

            if menu.clear.qsettings['qclear']:get() and IsDashing() and (not haveQ3 or menu.clear.qsettings['q3clear']:get()) then 

                if player:spellSlot(0).state == 0 and MinionsMonster.path.serverPos:dist(GetPosAfterDash(MinionsMonster)) < 475 and 
                dlib.GetSpellDamage(0, MinionsMonster) > orb.farm.predict_hp(MinionsMonster, q1_delay) or #minion > 1 then 
                    player:castSpell('pos', 0, MinionsMonster.path.serverPos)
                end
            end 

            if menu.clear.esettings['eclear']:get() and player:spellSlot(2).state == 0 and not HaveE(MinionsMonster) and (menu.eturret:get() or not UnderTurret(GetPosAfterDash(MinionsMonster))) then 
                if dlib.GetSpellDamage(2, MinionsMonster) > MinionsMonster.health then 
                    if #common.CountEnemiesInRange(player.pos, 1400) == 1 and common.GetPercentHealth(player) > 40 then 
                        player:castSpell('obj', 2, MinionsMonster)
                    end
                end
            end

            if menu.clear.qsettings['qclear']:get() and player:spellSlot(0).state == 0 and (not haveQ3 or menu.clear.qsettings['q3clear']:get()) and dlib.GetSpellDamage(0, MinionsMonster)  > orb.farm.predict_hp(MinionsMonster, q1_delay) then 
                player:castSpell('pos', 0, MinionsMonster.path.serverPos)
            end


            if menu.clear.qsettings['qclear']:get() and menu.clear.esettings['eclear']:get() and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and (menu.eturret:get() or not UnderTurret(GetPosAfterDash(MinionsMonster))) then
                if  dlib.GetSpellDamage(0, MinionsMonster)  + dlib.GetSpellDamage(2, MinionsMonster) > MinionsMonster.health then 
                    player:castSpell('obj', 2, MinionsMonster)
                end
            end
        end
    end

    if player.buff['yasuodashscalar'] then 
        if game.time <= player.buff['yasuodashscalar'].endTime then
            cDash = 1
        end
    else 
        cDash = 0
    end 

    for i, buff in pairs(player.buff) do 
        if buff and buff.valid and buff.name == "YasuoQ2" then 
            StartTime = buff.startTime
            EndTime = buff.endTime 
            LifeTime = 8
        end 
    end 
    if not player.buff['yasuoq2'] then 
        StartTime = 0
        EndTime = 0
        LifeTime = 0
    end
    LifeTime = Floor(EndTime - game.time)


    if menu.keyjump:get() then 
        player:move(mousePos)
        local mouse = GetClosestEUnit(mousePos)

        if mouse then 
            player:castSpell("obj", 2, mouse)
        end 
    end 

end 

local function OnNewPath(unit)
    if unit == player then 
        if unit.path.isDashing then 

            local startPos = unit.path.point[0]
            local endPos = unit.path.point[unit.path.count]

            isDash = true
            posDash = endPos
            lastE = os.clock();
        end 
    end 
end 

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and player.buff[17] ~= nil) then return end
    if (player.isOnScreen) then
        if menu.draws.q_range:get() and player:spellSlot(0).level > 0 and not haveQ3 then
            graphics.draw_circle(player.pos, 450, 1, menu.draws.q:get(), 100)
        end
        --q3
        if menu.draws.q3_range:get() and player:spellSlot(0).level > 0 and haveQ3 then
            graphics.draw_circle(player.pos, SpellSlot.Q.pred_input_Q2.range, 1, menu.draws.q3:get(), 100)
        end
        if menu.draws.e_range:get() and player:spellSlot(2).level > 0 then
            graphics.draw_circle(player.pos, 475, 1, menu.draws.e:get(), 100)
        end
        if menu.draws.r_range:get() and player:spellSlot(3).level > 0 then
            graphics.draw_circle(player.pos, 1400, 1, menu.draws.r:get(), 100)
        end

        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))

        if menu.eturret:get() then
			graphics.draw_text_2D("E|R under The Turret: ON", 17, pos.x - 45, pos.y + 30, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("E|R under The Turret: OFF", 17, pos.x - 45, pos.y + 30, graphics.argb(255, 255, 255, 255))
        end
        
        if menu.autoq:get() then
			graphics.draw_text_2D("Stack Q: ON", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Stack Q: OFF", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
		end --22, 128, 14

        LifeTime = Floor(EndTime - game.time)
        local playerPos = graphics.world_to_screen(player.pos)
        local textWidth = graphics.text_area("1.00", 30)

        if game.time < EndTime - 3.0 then
            graphics.draw_text_2D(tostring(LifeTime), 30, playerPos.x - (textWidth / 2), playerPos.y, graphics.argb(255, 27, 250, 10))
        elseif game.time < EndTime + 3.0 then 
            graphics.draw_text_2D(tostring(LifeTime), 30, playerPos.x - (textWidth / 2), playerPos.y, graphics.argb(255, 247, 5, 5))
        end
    end
end


orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.path, OnNewPath)
cb.add(cb.draw, OnDraw)