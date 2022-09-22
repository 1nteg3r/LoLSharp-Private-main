local orb = module.internal("orb")
local TS = module.internal('TS');
local gpred = module.internal('pred')
local common = module.load(header.id, "Library/common")
local GeomLib = module.load(header.id, "Geometry/GeometryLib")
local interrupter = module.load(header.id, "Library/interrupter")


local FlashSlot = nil
if player:spellSlot(4).name == "SummonerFlash" then
	FlashSlot = 4
elseif player:spellSlot(5).name == "SummonerFlash" then
	FlashSlot = 5
end

local Q = {
    Barrel = { },

    prediction_input = {
        range = 850;
        delay = 0.25; 
        radius = 200;
        speed = 1000;
        boundingRadiusMod = 0; 
        collision = {
            hero = false,
            minion = false,
            wall = true
        }
    }
    --[[
        Spell name: GragasQ
        Speed:1000
        Width: 110
        Time:0.25
        Animation: 1
        false
        CastFrame: 0.33898305892944
        --------------------------------------
        Delay: 0.25 Speed: 1000 Width: 110 Range: 847.8277302579
    ]]
}

local W = {
    range_bonus = 250
    --[[
        Spell name: GragasW
        Speed:828.5
        Width: 0
        Time:0.0010000000474975
        Animation: 0.7509999871254
        false
        CastFrame: 0.31721484661102
        --------------------------------------
    ]]
}

local E = { 
    prediction_input = {
        range = 650;
        delay = 0.25; 
        width = 180;
        speed = math.huge;
        boundingRadiusMod = 0; 
        collision = {
            hero = true,
            minion = true,
            wall = false
        }
    }
    --[[
        Spell name: GragasE
        Speed:500
        Width: 50
        Time:0.25
        Animation: 1
        false
        CastFrame: 0.31721484661102
        --------------------------------------
    ]]
}

local R = {
    prediction_input = {
        range = 1150;
        delay = 0.25; 
        radius = 120;
        speed = 1740;
        boundingRadiusMod = 0; 
        collision = {
            hero = false,
            minion = false,
            wall = true
        }
    }
    --[[
        Spell name: GragasR
        Speed:200
        Width: 120
        Time:0.25
        Animation: 1
        false
        CastFrame: 0.31721484661102
        --------------------------------------
        Delay: 0.25 Speed: 1741.5382080078 Width: 120 Range: 957.85134553532
    ]]
}

local menu = menu("IntnnerGragas", "Int - Gragas")
menu:header("core", "Core")
    menu:keybind("semi_r", "Insec - R", "T", nil)
        menu.semi_r:set("tooltip", "Applies the settings of the R combo")
    --menu:keybind("semi_E", "Start - E", "Z", nil)
        --menu.semi_E:set("tooltip", "Use E first, but do not use Q or W")

menu:header("hanbot", "Gragas - Settings")
--Combo
menu:menu("combo", "Combo Settings")
    menu.combo:dropdown('combo.select', 'Select Priority:', 1, {'W', 'E'})
menu.combo:header("hanQ", "Barrel Roll - Settings (Q)")
    menu.combo:boolean("qcombo", "Use Q In Combo", true)
menu.combo:header("hanW", "Drunken Rage - Settings (W)")
    menu.combo:boolean("wcombo", "Use W In Combo", true)
    menu.combo:boolean("WAA", "Use W if E is ready (out AA Range)", true)
    menu.combo:slider("wrange", "^~ Min. Range for W", 650, 10, 1300, 10)
menu.combo:header("hanE", "Body Slam - Settings (E)")
    menu.combo:boolean("ecombo", "Use E In Combo", true)
    menu.combo:boolean("eAA", "Don't use E if enemy is in AA range", false)
    menu.combo.ecombo:set("tooltip", "It will check if it is safe to use E")
menu.combo:header("hanR", "Explosive Cask - Settings (R)")
    menu.combo:menu("rset", "R - Settings", true)
        menu.combo.rset:boolean("rcombo", "Use R In Combo", true)
        menu.combo.rset:dropdown('R.select', 'R When:', 1, {'KillSteal', 'Combo Kill', "Always"})
        menu.combo.rset:header("hanR", "Insec - Settings")
        menu.combo.rset:dropdown('insecmodes', 'Insec Mode:', 3, { "Towards Team", "Towards Tower", "Towards Barrel"})
        menu.combo.rset:slider("circlePoints", "Circle Segment Points", 10, 3, 24, 3)
        menu.combo.rset:slider("angler", "Angle Position", 1, 1, 2, 1)
        menu.combo.rset.angler:set("tooltip", "1 = Angle 180        2 = Angle 360")
        menu.combo.rset:slider("distanceBTW", "Between Barrel and Enemy", 800, 50, 900, 10)

menu:menu("harass", "Harass Settings")
    menu.harass:dropdown('harass.select', 'Select Priority:', 2, {'W', 'E', 'Q'})
menu.harass:header("hanQ", "Barrel Roll - Settings")
    menu.harass:boolean("qharass", "Use Q In Harass", true)
menu.harass:header("hanW", "Drunken Rage - Settings")
    menu.harass:boolean("wharass", "Use W In Harass", true)
    menu.harass:slider("wrange", "^~ Min. Range for W", 850, 10, 1000, 10)
menu.harass:header("hanE", "Body Slam - Settings")
    menu.harass:boolean("eharass", "Use E In Harass", true)
    menu.harass:boolean("eAA", "Don't use E if enemy is in AA range", false)
menu.harass:header("mana", "Mana - Settings")
    menu.harass:slider("minMana", "^~ Min. Mana for Harass", 75, 10, 100, 10)

menu:menu("farm", "Farming")
menu.farm:menu("laneclear", "Wave-Clear")
menu.farm.laneclear:header("mana", "Not yet available")
menu.farm:menu("jungleclear", "Jungle-Clear")
menu.farm.jungleclear:boolean("qjug", "Use Q In Jungle", true)
menu.farm.jungleclear:boolean("wjug", "Use W In Jungle", true)
menu.farm.jungleclear:boolean("ejug", "Use E In Jungle", true)
menu.farm.jungleclear:slider("minMana", "^~ Min. Mana for Jungle-Clear", 50, 10, 100, 10)

menu:menu("misc", "Miscellaneous Settings")
    menu.misc:boolean("EInterrupt", "Use E for Interrupt spells", true)
    menu.misc:boolean("RInterrupt", "Use R for Interrupt spells", false)
    menu.misc:slider("minhealthi", "^~ Min. Health for R Interrupt", 50, 5, 100, 5)
    menu.misc:menu("WhiteList" , "Interrupt Targets")
        interrupter.load_to_menu(menu.misc.WhiteList)    
menu.misc:header("gap", "Dashing - Settings")
    menu.misc:boolean("Egab", "Use E for Gapclose", true)
    menu.misc:boolean("RGab", "Use R for Gapclose", true)
    menu.misc:slider("minhealth", "^~ Min. Health for R Gapclose", 25, 5, 100, 5)
menu.misc:header("kill", "KillSteal - Settings")
    menu.misc:menu("kill" , "KillSteal")
        menu.misc.kill:boolean("Qkill", "Use Q for KillSteal", true)
        menu.misc.kill:boolean("Ekill", "Use E for KillSteal", true)
        menu.misc.kill:boolean("Rkill", "Use R for KillSteal", true)

menu:menu("draws", "Drawings Settings")
menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
menu.draws:boolean("wrange", "Draw W Range", true)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
menu.draws:boolean("erange", "Draw E Range", true)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
menu.draws:boolean("rrange", "Draw R Range", true)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)

local function CirclePoints(CircleLineSegmentN, radius, position)
    local points = {}
    for i = 1, CircleLineSegmentN, 1 do
        local angle = i * menu.combo.rset['angler']:get() * math.pi / CircleLineSegmentN
        local point = vec3(position.x + radius * math.cos(angle), position.y, position.z + radius * math.sin(angle));
        table.insert(points, point)
    end 
    return points 
end

local function IsValidTimer(target)
    if not target then 
        return 
    end 

    for i, buff in pairs(target.buff) do 
        if buff and buff.valid then 

            if (buff.name == "FioraW" or buff.name == "fioraw") or buff.name == "zhonyasringshield" or buff.name == "SivirE" or buff.name == "VladimirSanguinePool" then 
                return game.time - buff.endTime * 1000
            end 
        end 
    end 
    return 0 
end 

local function IsValidTarget(object, distanceSqr, delay, speed)
    return object and not object.isDead and object.isVisible and not object.buff[string.lower'SionPassiveZombie']
    and not object.buff[string.lower'KarthusDeathDefiedthen'] 
    and not object.buff[string.lower'KarthusDeathDefiedBuff']
    and not object.buff['fioraw'] 
    and not object.buff['sivire'] and not object.buff["kogmawicathiansurprise"]
    and not object.buff['nocturneshroudofdarkness'] 
    and (not distanceSqr or common.GetDistanceSqr(object) <= distanceSqr * distanceSqr) 
    and common.IsEnemyMortal(object) 
    and (not delay and not speed or IsValidTimer(object) < (common.GetDistance(player.pos, object.pos) / speed + delay / 1000) * 1000)
end 

local function GetDamage(target, spellSlot)
    local rawDamage = 0
    local dmgType = 1

    local spellLevel = type(spellSlot) == "number" and player:spellSlot(spellSlot).level or 0
    local heroLevel = math.min(18, player.levelRef)

    local charInter = player
    local myBonusAD = charInter.flatPhysicalDamageMod
    local myAD = charInter.baseAttackDamage + myBonusAD
    local myAP = charInter.baseAbilityDamage + charInter.flatMagicDamageMod

    if spellSlot == 0 then
        --80 / 120 / 160 / 200 / 240 (+ 70% AP)
        rawDamage = ({80, 120, 160, 200, 240})[spellLevel] + (0.7 * myAP)
        dmgType = 2
    elseif spellSlot == 1 then
        rawDamage =  ({20, 50, 80, 110, 140})[spellLevel] + (0.6 * myAP) + (0.07 * common.GetPercentHealth(target))
        dmgType = 2

    elseif spellSlot == 2 then
        rawDamage = ({80, 125, 170, 215, 260})[spellLevel] + (0.6 * myAP)
        dmgType = 2

    elseif spellSlot == 3 then
        rawDamage = ({200, 300, 400})[spellLevel] + (0.8 * myAP)
        dmgType = 2
    end

    if dmgType == 2 then
        return common.CalculateMagicDamage(target, rawDamage, player)
    else
        return rawDamage
    end
end

local function GetComboDamage(target)
    if not target then
        return
    end

    local damage = 0 
    if (player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GragasQ" or player.buff['gragasq']) then 
        damage = GetDamage(target, 0)
    end 

    if player:spellSlot(1).state == 0 or player.buff['gragaswattackbuff'] then 
        damage = GetDamage(target, 1)
    end

    if player:spellSlot(2).state == 0 then 
        damage = GetDamage(target, 2)
    end

    if player:spellSlot(3).state == 0 then 
        damage = GetDamage(target, 3)
    end

    return damage
end 

local function filter(seg, obj)
	if gpred.trace.circular.hardlock(Q.prediction_input, seg, obj) then
		return true
	end
	if gpred.trace.circular.hardlockmove(Q.prediction_input, seg, obj) then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.5) then
		return true
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

local TargetSelector_Q = function(res, obj, dist)
    if dist > Q.prediction_input.range then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj and obj ~= nil and IsValidTarget(obj, Q.prediction_input.range) then 
        res.obj = obj 
        return true
    end 
end

local TargetSelector_Q2 = function(res, obj, dist)
    if dist > 99999 then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj and obj ~= nil and IsValidTarget(obj) then 

        for i, object in pairs(Q.Barrel) do  
            if object and object ~= nil then 
                --local res = gpred.core.get_pos_after_time(target, 0.5)
                if object.pos2D:dist(obj.pos2D) < (280+obj.boundingRadius) then 
                    res.obj = obj 
                    return true
                end 
            end 
        end
    end 
end

local TargetSelector_W = function(res, obj, dist)
    if dist > menu.combo['wrange']:get() then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj and obj ~= nil and IsValidTarget(obj, menu.combo['wrange']:get()) then 
        res.obj = obj 
        return true
    end 
end

local TargetSelector_E = function(res, obj, dist)
    if dist > E.prediction_input.range then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj and obj ~= nil and IsValidTarget(obj, E.prediction_input.range) then 
        res.obj = obj 
        return true
    end 
end

local TargetSelector_R = function(res, obj, dist)
    if dist > R.prediction_input.range then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj and obj ~= nil and IsValidTarget(obj, R.prediction_input.range) then 
        res.obj = obj 
        return true
    end 
end
 

local function IsWallBetween(start, endPos, step)
    local start = start or vec3(0,0,0)
    local endPos = endPos or vec3(0,0,0)
    local step = step or 3 

    if (start and start ~= vec3(0,0,0)) and (endPos and endPos ~= vec3(0,0,0)) and step > 0 then 

        local distance = common.GetDistance(start, endPos)
        for i = 0, distance, step do   
            local VecStart = GeomLib.Vector:new(start)
            local VecEnd = GeomLib.Vector:new(endPos)

            local extend = VecStart + (VecEnd - VecStart):normalized() * i
            if extend and (navmesh.isWall(extend)) then  
                return true 
            end 
        end 
    end 
    return false
end 

local function GetRegisterCollision(target)
    if not target then 
        return 
    end 

    local seg = gpred.linear.get_prediction(E.prediction_input, target, vec2(player.x, player.z))

    if not seg then 
        return 
    end 

    local res = gpred.collision.get_prediction(E.prediction_input, seg , target)
    if res then
        for i=1,#res do
            local obj=res[i]
            if obj and obj.pos:distSqr(target)>(50 - obj.boundingRadius) ^ 2 then
                return true
            end
        end
    end 
    return false
end 

local function CastR(target)
    if not target then 
        return 
    end 

    local vecMyHero = GeomLib.Vector:new(player.pos)
    local res = gpred.core.get_pos_after_time(target, 0.25)
    local vecTarget = GeomLib.Vector:new(res:to3D())
    local dist = common.GetDistance(player.pos, res:to3D())

    local endPos = vecMyHero:extended(vecTarget, (R.prediction_input.range + 300)) 
    local insecPosition = vecMyHero:extended(vecTarget, (dist + 200))
    local moving = vecMyHero:extended(vecTarget, (dist + 300))

    local rMode = menu.combo.rset['R.select']:get() -- 1 = KillSteal, 2 = Combo Kill, 3 = awal
    local health = common.GetShieldedHealth("AP", target)

    if common.GetDistance(target, player) <= common.GetAARange(target) then
        local aa_damage = common.CalculateAADamage(target)
        if (aa_damage * 2) >= common.GetShieldedHealth("AD", target) then
            return
        end
    end
    
    if rMode == 1 then 

        if player:spellSlot(1).state == 0 or player.buff["gragaswattackbuff"] and player:spellSlot(3).state == 0 then 
            local rDamage = GetDamage(target, 3)
            local wDamage = GetDamage(target, 1)

            if (rDamage + wDamage) > health and (health > rDamage) then 
                if (not common.IsFacing(target) and target.path.active and common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300) then 
                    player:castSpell("pos", 3, moving:toDX3())
                    --print"moving"
                elseif (common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 and common.IsFacing(target) and target.path.active) then 
                    player:castSpell("pos", 3, endPos:toDX3())
                    print"endPos"
                else 
                    if common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 then 
                        player:castSpell("pos", 3, insecPosition:toDX3())
                        --print"insecPosition"
                    end 
                end 
            end
        elseif (player:spellSlot(1).state == 0 or player:spellSlot(2).state == 0) or player.buff["gragaswattackbuff"] and player:spellSlot(3).state == 0 then  
            local rDamage = GetDamage(target, 3)
            local wDamage = GetDamage(target, 1)
            local eDamage = GetDamage(target, 2)

            if (rDamage + (wDamage or eDamage)) > health  and (health > rDamage) then 
                if (not common.IsFacing(target) and target.path.active and common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300) then 
                    player:castSpell("pos", 3, moving:toDX3())
                    --print"moving2"
                elseif (common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 and common.IsFacing(target) and target.path.active) then 
                    player:castSpell("pos", 3, endPos:toDX3())
                    print"endPos2"
                else 
                    if common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 then 
                        player:castSpell("pos", 3, insecPosition:toDX3())
                        --print"insecPosition2"
                    end 
                end 
            end
        elseif (player:spellSlot(0).state == 0 or player:spellSlot(0).name ~= "GragasQ") or player.buff["gragasQ"] and player:spellSlot(3).state == 0 then  
            local rDamage = GetDamage(target, 3)
            local qDamage = GetDamage(target, 0)

            if (rDamage + qDamage) > health and (health > rDamage) then 
                for i, object in pairs(Q.Barrel) do 
                    if object and object ~= nil then 
                        local Vecobj =  GeomLib.Vector:new(object)
                        local distobj = common.GetDistance(Vecobj, target.pos)
                        local objPosition = Vecobj:extended(vecTarget, (distobj + 300))

                        if objPosition:dist(target) < 900 and target.pos2D:dist(object.pos2D) < 900 and target.pos2D:dist(object.pos2D) > 300 then 
                            if common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 then
                                player:castSpell("pos", 3, objPosition:toDX3())
                                --print"objPosition"
                            end
                        end 
                    end 
                end
            end 
        else 
            if player:spellSlot(3).state == 0 and GetDamage(target, 3) > health then 
                local seg = gpred.circular.get_prediction(R.prediction_input, target, vec2(player.x, player.z))
                if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < R.prediction_input.range ^ 2 then
                    if player.pos2D:distSqr(target.pos2D) < R.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < R.prediction_input.range ^ 2 then 
                        player:castSpell("pos", 3, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                    end 
                end
            end
        end 
    elseif rMode == 2 then  
        if GetComboDamage(target) > health then 
            if (not common.IsFacing(target) and target.path.active and common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300) then 
                player:castSpell("pos", 3, moving:toDX3())
                --print"moving"
            elseif (common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 and common.IsFacing(target) and target.path.active) then 
                player:castSpell("pos", 3, endPos:toDX3())
                print"endPos3"
            else 
                if common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 then 
                    player:castSpell("pos", 3, insecPosition:toDX3())
                    --print"insecPosition"
                end 
            end 

            if (GetDamage(target, 3) + GetDamage(target, 0)) > health and (health > GetDamage(target, 3)) then 
                for i, object in pairs(Q.Barrel) do 
                    if object and object ~= nil then 
                        local Vecobj =  GeomLib.Vector:new(object)
                        local distobj = common.GetDistance(Vecobj, target.pos)
                        local objPosition = Vecobj:extended(vecTarget, (distobj + 300))

                        if objPosition:dist(target) < 900 and target.pos2D:dist(object.pos2D) < 900 and target.pos2D:dist(object.pos2D) > 300 then 
                            if common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 then
                                player:castSpell("pos", 3, objPosition:toDX3())
                                --print"objPosition"
                            end
                        end 
                    end 
                end  
            else 
                if player:spellSlot(3).state == 0 and GetDamage(target, 3) > health then 
                    local seg = gpred.circular.get_prediction(R.prediction_input, target, vec2(player.x, player.z))
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < R.prediction_input.range ^ 2 then
                        if player.pos2D:distSqr(target.pos2D) < R.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < R.prediction_input.range ^ 2 then 
                            player:castSpell("pos", 3, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end 
                    end
                end
            end 
        end 
    elseif rMode == 3 then
        if (health > GetDamage(target, 3)) then 
            if (not common.IsFacing(target) and target.path.active and common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300) then 
                player:castSpell("pos", 3, moving:toDX3())
                --print"moving"
            elseif (common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 and common.IsFacing(target) and target.path.active) then 
                player:castSpell("pos", 3, endPos:toDX3())
                print"endPos4"
            else 
                if common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 then 
                    player:castSpell("pos", 3, insecPosition:toDX3())
                    --print"insecPosition"
                end 
            end 
            for i, object in pairs(Q.Barrel) do 
                if object and object ~= nil then 
                    local Vecobj =  GeomLib.Vector:new(object)
                    local distobj = common.GetDistance(Vecobj, target.pos)
                    local objPosition = Vecobj:extended(vecTarget, (distobj + 300))

                    if objPosition:dist(target) < 900 and target.pos2D:dist(object.pos2D) < 900 and target.pos2D:dist(object.pos2D) > 300 then 
                        if common.GetDistance(insecPosition, player) < R.prediction_input.range and common.GetDistance(insecPosition, target) < 300 then
                            player:castSpell("pos", 3, objPosition:toDX3())
                            print"objPosition"
                        end
                    end 
                end 
            end  
        end
    end
end 

local function Combo() 
    --items 
     
    if menu.combo['combo.select']:get() == 1 then 
        --Priority: W
        if menu.combo['wcombo']:get() and player:spellSlot(1).state == 0 then 
            local target = TS.get_result(TargetSelector_W).obj

            if target and target ~= nil and IsValidTarget(target, menu.combo['wrange']:get()) then 

                if common.GetDistance(target, player) <= common.GetAARange(target) then
                    local aa_damage = common.CalculateAADamage(target)
                    if (aa_damage * 2) >= common.GetShieldedHealth("AD", target) then
                        return
                    end
                end

                if (not menu.combo['WAA']:get() or player:spellSlot(2).state == 0 or player.pos2D:dist(target.pos2D) <= common.GetAARange(player)) then 
                    player:castSpell("self", 1, player)
                end
            end 
        end 

        if menu.combo['ecombo']:get() and player:spellSlot(2).state == 0 then 
            local target = TS.get_result(TargetSelector_E).obj
            if target and target ~= nil and IsValidTarget(target, E.prediction_input.range) then 
                local seg = gpred.linear.get_prediction(E.prediction_input, target, vec2(player.x, player.z))
                if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < E.prediction_input.range ^ 2 then
                    if player.pos2D:distSqr(target.pos2D) < E.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < E.prediction_input.range ^ 2 and not GetRegisterCollision(target) then 

                        if (not menu.combo['eAA']:get() or player.pos2D:dist(target.pos2D) > common.GetAARange(player)) and CheckDashPrevention(700) and IsGoodPosition(target.pos) then 
                            player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end 
                    end 
                end 
            end 
        end 

        if menu.combo['qcombo']:get() then 
            local target = TS.get_result(TargetSelector_Q).obj
            local target_Q = TS.get_result(TargetSelector_Q2).obj
            if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GragasQ" then 
                if target and target ~= nil and IsValidTarget(target) then
                    local seg = gpred.circular.get_prediction(Q.prediction_input, target, vec2(player.x, player.z))
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < Q.prediction_input.range ^ 2 then
                        if player.pos2D:distSqr(target.pos2D) < Q.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                            if filter(seg, target) then 
                                player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                            end
                        end  
                    end 
            
                    --[[if seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                        return true 
                    end ]]
                
                end 
            elseif player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "GragasQ" and player.buff['gragasq'] then 
                if target_Q and target_Q ~= nil and IsValidTarget(target_Q) then
                    for i, object in pairs(Q.Barrel) do  
                        if object and object ~= nil then 
                            --local res = gpred.core.get_pos_after_time(target, 0.5)
                            if object.pos2D:dist(target_Q.pos2D) < (280) then 
                                player:castSpell("self", 0, player)
                            end 
                        end 
                    end 
                end
            end 
        end

        if menu.combo.rset['rcombo']:get() and player:spellSlot(3).state == 0 then
            local target = TS.get_result(TargetSelector_R).obj 
            if target and target ~= nil and IsValidTarget(target) then
                CastR(target)
            end
        end 
    elseif menu.combo['combo.select']:get() == 2 then 
        if menu.combo['ecombo']:get() and player:spellSlot(2).state == 0 then 
            local target = TS.get_result(TargetSelector_E).obj
            if target and target ~= nil and IsValidTarget(target, E.prediction_input.range) then 
                local seg = gpred.linear.get_prediction(E.prediction_input, target, vec2(player.x, player.z))
                if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < E.prediction_input.range ^ 2 then
                    if player.pos2D:distSqr(target.pos2D) < E.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < E.prediction_input.range ^ 2 and not GetRegisterCollision(target) then 

                        if (not menu.combo['eAA']:get() or player.pos2D:dist(target.pos2D) > common.GetAARange(player)) and CheckDashPrevention(700) and IsGoodPosition(target.pos) then 
                            player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end 
                    end 
                end 
            end 
        end 

        if menu.combo['wcombo']:get() and player:spellSlot(1).state == 0 then 
            local target = TS.get_result(TargetSelector_W).obj
            
            if target and target ~= nil and IsValidTarget(target, menu.combo['wrange']:get()) then 

                if common.GetDistance(target, player) <= common.GetAARange(target) then
                    local aa_damage = common.CalculateAADamage(target)
                    if (aa_damage * 2) >= common.GetShieldedHealth("AD", target) then
                        return
                    end
                end

                if (not menu.combo['WAA']:get() or player:spellSlot(2).state == 0 or player.pos2D:dist(target.pos2D) <= common.GetAARange(player)) then 
                    player:castSpell("self", 1, player)
                end
            end 
        end 

        if menu.combo['qcombo']:get() then 
            local target = TS.get_result(TargetSelector_Q).obj
            local target_Q = TS.get_result(TargetSelector_Q2).obj
            if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GragasQ" then 
                if target and target ~= nil and IsValidTarget(target) then
                    local seg = gpred.circular.get_prediction(Q.prediction_input, target, vec2(player.x, player.z))
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < Q.prediction_input.range ^ 2 then
                        if player.pos2D:distSqr(target.pos2D) < Q.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                            if filter(seg, target) then 
                                player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                            end
                        end  
                    end 
            
                    --[[if seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                        return true 
                    end ]]
                
                end 
            elseif player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "GragasQ" and player.buff['gragasq'] then 
                if target_Q and target_Q ~= nil and IsValidTarget(target_Q) then
                    for i, object in pairs(Q.Barrel) do  
                        if object and object ~= nil then 
                            --local res = gpred.core.get_pos_after_time(target, 0.5)
                            if object.pos2D:dist(target_Q.pos2D) < (280) then 
                                player:castSpell("self", 0, player)
                            end 
                        end 
                    end 
                end
            end 
        end

        if menu.combo.rset['rcombo']:get() and player:spellSlot(3).state == 0 then
            local target = TS.get_result(TargetSelector_R).obj 
            if target and target ~= nil and IsValidTarget(target) then
                CastR(target)
            end
        end 
    end 
end

local function Harass()
    if menu.harass['minMana']:get() > common.GetPercentMana(player) then 
        return 
    end 

    local qMode = menu.harass['harass.select']:get()

    if qMode == 1 then --W 
        if menu.harass['wharass']:get() and player:spellSlot(1).state == 0 then 
            local target = TS.get_result(TargetSelector_W).obj

            if target and target ~= nil and IsValidTarget(target, menu.harass['wrange']:get()) then 

                if common.GetDistance(target, player) <= common.GetAARange(target) then
                    local aa_damage = common.CalculateAADamage(target)
                    if (aa_damage * 2) >= common.GetShieldedHealth("AD", target) then
                        return
                    end
                end

                player:castSpell("self", 1, player)
            end 
        end 

        if menu.harass['eharass']:get() and player:spellSlot(2).state == 0 then 
            local target = TS.get_result(TargetSelector_E).obj
            if target and target ~= nil and IsValidTarget(target, E.prediction_input.range) then 
                local seg = gpred.linear.get_prediction(E.prediction_input, target, vec2(player.x, player.z))
                if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < E.prediction_input.range ^ 2 then
                    if player.pos2D:distSqr(target.pos2D) < E.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < E.prediction_input.range ^ 2 and not GetRegisterCollision(target) then 

                        if (not menu.harass['eAA']:get() or player.pos2D:dist(target.pos2D) > common.GetAARange(player)) and CheckDashPrevention(700) and IsGoodPosition(target.pos) then 
                            player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end 
                    end 
                end 
            end 
        end 

        if menu.harass['qharass']:get() then 
            local target = TS.get_result(TargetSelector_Q).obj
            local target_Q = TS.get_result(TargetSelector_Q2).obj
            if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GragasQ" then 
                if target and target ~= nil and IsValidTarget(target) then
                    local seg = gpred.circular.get_prediction(Q.prediction_input, target, vec2(player.x, player.z))
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < Q.prediction_input.range ^ 2 then
                        if player.pos2D:distSqr(target.pos2D) < Q.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                            if filter(seg, target) then 
                                player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                            end
                        end  
                    end 
            
                    --[[if seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                        return true 
                    end ]]
                
                end 
            elseif player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "GragasQ" and player.buff['gragasq'] then 
                if target_Q and target_Q ~= nil and IsValidTarget(target_Q) then
                    for i, object in pairs(Q.Barrel) do  
                        if object and object ~= nil then 
                            --local res = gpred.core.get_pos_after_time(target, 0.5)
                            if object.pos2D:dist(target_Q.pos2D) < (280) then 
                                player:castSpell("self", 0, player)
                            end 
                        end 
                    end 
                end
            end 
        end
    elseif qMode == 2 then --E
        if menu.harass['eharass']:get() and player:spellSlot(2).state == 0 then 
            local target = TS.get_result(TargetSelector_E).obj
            if target and target ~= nil and IsValidTarget(target, E.prediction_input.range) then 
                local seg = gpred.linear.get_prediction(E.prediction_input, target, vec2(player.x, player.z))
                if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < E.prediction_input.range ^ 2 then
                    if player.pos2D:distSqr(target.pos2D) < E.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < E.prediction_input.range ^ 2 and not GetRegisterCollision(target) then 

                        if (not menu.harass['eAA']:get() or player.pos2D:dist(target.pos2D) > common.GetAARange(player)) and CheckDashPrevention(700) and IsGoodPosition(target.pos) then 
                            player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end 
                    end 
                end 
            end 
        end 

        if menu.harass['wharass']:get() and player:spellSlot(1).state == 0 then 
            local target = TS.get_result(TargetSelector_W).obj
            
            if target and target ~= nil and IsValidTarget(target, menu.harass['wrange']:get()) then 

                if common.GetDistance(target, player) <= common.GetAARange(target) then
                    local aa_damage = common.CalculateAADamage(target)
                    if (aa_damage * 2) >= common.GetShieldedHealth("AD", target) then
                        return
                    end
                end

                player:castSpell("self", 1, player)
            end 
        end 

        if menu.harass['qharass']:get() then 
            local target = TS.get_result(TargetSelector_Q).obj
            local target_Q = TS.get_result(TargetSelector_Q2).obj
            if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GragasQ" then 
                if target and target ~= nil and IsValidTarget(target) then
                    local seg = gpred.circular.get_prediction(Q.prediction_input, target, vec2(player.x, player.z))
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < Q.prediction_input.range ^ 2 then
                        if player.pos2D:distSqr(target.pos2D) < Q.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                            if filter(seg, target) then 
                                player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                            end
                        end  
                    end 
            
                    --[[if seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                        return true 
                    end ]]
                
                end 
            elseif player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "GragasQ" and player.buff['gragasq'] then 
                if target_Q and target_Q ~= nil and IsValidTarget(target_Q) then
                    for i, object in pairs(Q.Barrel) do  
                        if object and object ~= nil then 
                            --local res = gpred.core.get_pos_after_time(target, 0.5)
                            if object.pos2D:dist(target_Q.pos2D) < (280) then 
                                player:castSpell("self", 0, player)
                            end 
                        end 
                    end 
                end
            end 
        end
    elseif qMode == 3 then --Q
        if menu.harass['qharass']:get() then 
            local target = TS.get_result(TargetSelector_Q).obj
            local target_Q = TS.get_result(TargetSelector_Q2).obj
            if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GragasQ" then 
                if target and target ~= nil and IsValidTarget(target) then
                    local seg = gpred.circular.get_prediction(Q.prediction_input, target, vec2(player.x, player.z))
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < Q.prediction_input.range ^ 2 then
                        if player.pos2D:distSqr(target.pos2D) < Q.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                            if filter(seg, target) then 
                                player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                            end
                        end  
                    end 
            
                    --[[if seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                        return true 
                    end ]]
                
                end 
            elseif player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "GragasQ" and player.buff['gragasq'] then 
                if target_Q and target_Q ~= nil and IsValidTarget(target_Q) then
                    for i, object in pairs(Q.Barrel) do  
                        if object and object ~= nil then 
                            --local res = gpred.core.get_pos_after_time(target, 0.5)
                            if object.pos2D:dist(target_Q.pos2D) < (280) then 
                                player:castSpell("self", 0, player)
                            end 
                        end 
                    end 
                end
            end 
        end
        if menu.harass['wharass']:get() and player:spellSlot(1).state == 0 then 
            local target = TS.get_result(TargetSelector_W).obj
            
            if target and target ~= nil and IsValidTarget(target, menu.harass['wrange']:get()) then 

                if common.GetDistance(target, player) <= common.GetAARange(target) then
                    local aa_damage = common.CalculateAADamage(target)
                    if (aa_damage * 2) >= common.GetShieldedHealth("AD", target) then
                        return
                    end
                end

                player:castSpell("self", 1, player)
            end 
        end 
        if menu.harass['eharass']:get() and player:spellSlot(2).state == 0 then 
            local target = TS.get_result(TargetSelector_E).obj
            if target and target ~= nil and IsValidTarget(target, E.prediction_input.range) then 
                local seg = gpred.linear.get_prediction(E.prediction_input, target, vec2(player.x, player.z))
                if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < E.prediction_input.range ^ 2 then
                    if player.pos2D:distSqr(target.pos2D) < E.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < E.prediction_input.range ^ 2 and not GetRegisterCollision(target) then 

                        if (not menu.harass['eAA']:get() or player.pos2D:dist(target.pos2D) > common.GetAARange(player)) and CheckDashPrevention(700) and IsGoodPosition(target.pos) then 
                            player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end 
                    end 
                end 
            end 
        end 
    end
end 

local function Insec()
    local target = common.GetTarget(1300)
    local insecMode = menu.combo.rset['insecmodes']:get()
    if target and target ~= nil and IsValidTarget(target) then 
        if insecMode == 1 then --Allies
            for l, alliesHero in pairs(common.GetAllyHeroes()) do
                if alliesHero and alliesHero ~= nil and (alliesHero ~= player) and IsValidTarget(alliesHero, 1300) then 
                    local vecObj = GeomLib.Vector:new(alliesHero.pos)
                    local res = gpred.core.get_pos_after_time(target, 0.25)
                    local vecTarget = GeomLib.Vector:new(res:to3D())
                    local dist = common.GetDistance(alliesHero.pos, res:to3D())
                
                    local endPos = vecObj:extended(vecTarget, (R.prediction_input.range + 300)) 
                    local insecPosition = vecObj:extended(vecTarget, (dist + 200))
                    local moving = vecObj:extended(vecTarget, (dist + 300))

                    if alliesHero.pos:dist(vecTarget) < 1300 and alliesHero.pos:dist(vecTarget) > 400 and not IsWallBetween(vecObj, vecTarget) and player:spellSlot(3).state == 0 then     
                        player:castSpell("pos", 3, insecPosition:toDX3())
                    end
                end
            end 
        elseif insecMode == 2 then --tower 
            for i=0, objManager.turrets.size[TEAM_ALLY]-1 do
                local tower = objManager.turrets[TEAM_ALLY][i]
                if tower and tower ~= nil and tower.health > 0 and not tower.isDead then 
                    local vecObj = GeomLib.Vector:new(tower.pos)
                    local res = gpred.core.get_pos_after_time(target, 0.25)
                    local vecTarget = GeomLib.Vector:new(res:to3D())
                    local dist = common.GetDistance(tower.pos, res:to3D())
                
                    local endPos = vecObj:extended(vecTarget, (R.prediction_input.range + 300)) 
                    local insecPosition = vecObj:extended(vecTarget, (dist + 200))
                    local moving = vecObj:extended(vecTarget, (dist + 300))

                    if tower.pos:dist(vecTarget) < 1300 and tower.pos:dist(vecTarget) > 300 and not IsWallBetween(vecObj, vecTarget) and player:spellSlot(3).state == 0 then    
                        player:castSpell("pos", 3, insecPosition:toDX3())
                    end
                end
            end 
        elseif insecMode == 3 then 
            --Barreal
            local eDash = false
            if player:spellSlot(0).state == 0 and player:spellSlot(3).state == 0 and player:spellSlot(0).name == "GragasQ" and not player.buff["gragasq"] then 
                local points = CirclePoints(menu.combo.rset['circlePoints']:get(), menu.combo.rset['distanceBTW']:get(), target.pos)

                for i = 0, #points do  
                    local point = points[i]

                    if point and common.GetDistance(point, player) < Q.prediction_input.range and not IsWallBetween(point, target.pos) then 
                        player:castSpell("pos", 0, point)
                    end
                end 
            elseif player:spellSlot(0).state == 0 and player:spellSlot(3).state == 0 and player:spellSlot(0).name ~= "GragasQ" and player.buff["gragasq"] then  
                if not player.buff['gragase'] and player:spellSlot(2).state == 0 then 
                    if common.GetDistance(target) < R.prediction_input.range and common.GetDistance(target) > 650 and FlashSlot and player:spellSlot(FlashSlot).state == 0 then
                        if not GetRegisterCollision(target) then 
                            player:castSpell("pos", 2, target.pos)
                            eDash = false
                        end  
                    elseif common.GetDistance(target) < E.prediction_input.range then 
                        if not GetRegisterCollision(target) then 
                            player:castSpell("pos", 2, target.pos)
                            eDash = false
                        end
                    end
                elseif player.buff['gragase'] and common.GetDistance(target) > 500 then 
                    eDash = true
                    common.DelayAction(
                        function()
                            player:castSpell("pos", FlashSlot, target.pos)
                        end,
                        0.50 + network.latency
                    )
                end
            end 
            for i, object in pairs(Q.Barrel) do 
                if object and object ~= nil then 
                    local Vecobj = object.pos
                    local pre_predPos = gpred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)
                    if not pre_predPos then 
                        return 
                    end
                    local vecTarget = vec3(pre_predPos.x, target.y, pre_predPos.y)
                    local distobj = common.GetDistance(Vecobj, target.pos)
                    local objPosition =  Vecobj + (vecTarget - Vecobj):norm() * (distobj + 250)
                    --local vecMyHero = GeomLib.Vector:new(player.pos)
                    --local dist = common.GetDistance(player.pos, target.pos)
                    --local insecPosition = vecMyHero:extended(vecTarget, (dist + 300))
                    local seg = gpred.circular.get_prediction(R.prediction_input, target)
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < R.prediction_input.range ^ 2 then
                        if target.pos2D:dist(object.pos2D) < 900 and target.pos2D:dist(object.pos2D) > 300 and not target.path.isDashing then 
                            if common.GetDistance(objPosition, player) < R.prediction_input.range - 150 and common.GetDistance(objPosition, target) <= 300 and not IsWallBetween(Vecobj, vecTarget)  then
                                common.DelayAction(
                                    function()
                                        player:castSpell("pos", 3, objPosition)
                                    end,
                                    0.5 + network.latency
                                )
                            end 
                        end
                    end

                    if object.pos:dist(target.pos) < (280) then 
                        player:castSpell("self", 0, player)
                    end 
                end 
            end
        end 
    end 
end

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and IsValidTarget(target) and common.IsEnemyMortal(target) then
            local health = common.GetShieldedHealth("AP", target)

            if common.GetDistance(target, player) <= common.GetAARange(target) then
                local aa_damage = common.CalculateAADamage(target)
                if (aa_damage * 2) >= common.GetShieldedHealth("AD", target) then
                    return
                end
            end

            if menu.misc.kill['Qkill']:get() and player:spellSlot(0).state == 0 then 
                if GetDamage(target, 0) > health and common.GetDistance(target) < Q.prediction_input.range then 
                    if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GragasQ" then 
                        local seg = gpred.circular.get_prediction(Q.prediction_input, target, vec2(player.x, player.z))
                        if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < Q.prediction_input.range ^ 2 then
                            if player.pos2D:distSqr(target.pos2D) < Q.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                                if filter(seg, target) then 
                                    player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                                end
                            end  
                        end 
                    elseif player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "GragasQ" and player.buff['gragasq'] then 
                        if target_Q and target_Q ~= nil and IsValidTarget(target_Q) then
                            for i, object in pairs(Q.Barrel) do  
                                if object and object ~= nil then 
                                    --local res = gpred.core.get_pos_after_time(target, 0.5)
                                    if object.pos2D:dist(target_Q.pos2D) < (280) then 
                                        player:castSpell("self", 0, player)
                                    end 
                                end 
                            end 
                        end
                    end
                end
            end 

            if menu.misc.kill['Ekill']:get() and player:spellSlot(2).state == 0 then
                if GetDamage(target, 2) > health and common.GetDistance(target) < Q.prediction_input.range then 
                    local seg = gpred.linear.get_prediction(E.prediction_input, target, vec2(player.x, player.z))
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < E.prediction_input.range ^ 2 then
                        if player.pos2D:distSqr(target.pos2D) < E.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < E.prediction_input.range ^ 2 and not GetRegisterCollision(target) then
                            player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end 
                    end 
                end
            end

            if menu.misc.kill['Rkill']:get() and player:spellSlot(3).state == 0 then
                CastR(target)
            end 
        end 
    end
end 

local function Gapcloser()
    if player:spellSlot(3).state == 0 and menu.misc.RGab:get() and common.GetPercentHealth(player) <= menu.misc['minhealth']:get() then
		for i = 0, objManager.enemies_n - 1 do
			local dasher = objManager.enemies[i]
			if dasher.type == TYPE_HERO and dasher.team == TEAM_ENEMY then
				if
					dasher and common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and
						player.pos:dist(dasher.path.point[1]) < R.prediction_input.range
				 then
					if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[0]) then
                        player:castSpell("pos", 3, dasher.path.point2D[1])
					end
				end
			end
		end
	end
end 

local function JungleClear()
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] -1 do 
        local minion = objManager.minions[TEAM_NEUTRAL][i] 
        if minion and minion ~= nil and IsValidTarget(minion) then 

            if menu.farm.jungleclear['minMana']:get() > common.GetPercentMana(player) then 
                return 
            end 

            if menu.farm.jungleclear['wjug']:get() and player:spellSlot(1).state == 0 then 
                if common.GetDistance(minion, player) <= common.GetAARange(minion) then
                    local aa_damage = common.CalculateAADamage(minion)
                    if (aa_damage * 2) >= common.GetShieldedHealth("AD", minion) then
                        return
                    end
                end

                if minion.pos2D:dist(player.pos2D) < menu.combo['wrange']:get() then 
                    player:castSpell("self", 1, player)
                end
            end

            if menu.farm.jungleclear['ejug']:get() and player:spellSlot(2).state == 0 then  
                local seg = gpred.linear.get_prediction(E.prediction_input, minion, vec2(player.x, player.z))
                if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, minion.pos.y, seg.endPos.y):to2D()) < E.prediction_input.range ^ 2 then
                    if player.pos2D:distSqr(minion.pos2D) < E.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < E.prediction_input.range ^ 2 and not GetRegisterCollision(minion) then 

                        if CheckDashPrevention(700) and IsGoodPosition(minion.pos) then 
                            player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end 
                    end 
                end 
            end

            if menu.farm.jungleclear['qjug']:get() and player:spellSlot(0).state == 0 then 
                if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GragasQ" then 
                    local seg = gpred.circular.get_prediction(Q.prediction_input, minion, vec2(player.x, player.z))
                    if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, minion.pos.y, seg.endPos.y):to2D()) < Q.prediction_input.range ^ 2 then
                        if player.pos2D:distSqr(minion.pos2D) < Q.prediction_input.range ^ 2 and seg.startPos:distSqr(seg.endPos) < Q.prediction_input.range ^ 2 then 
                            player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end  
                    end 
                elseif player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "GragasQ" and player.buff['gragasq'] then 
                    for i, object in pairs(Q.Barrel) do  
                        if object and object ~= nil then 
                            --local res = gpred.core.get_pos_after_time(target, 0.5)
                            if object.pos2D:dist(minion.pos2D) > (200+minion.boundingRadius) then 
                                player:castSpell("self", 0, player)
                            end 
                        end 
                    end
                end 
            end
        end 
    end 
end 

local function on_tick()
    if (player.isDead and not player.isTargetable and player.buff[17]) then 
        return 
    end

    KillSteal()
    Gapcloser()
    --gragaswattackbuff
    -- GragasE
    if menu['semi_r']:get() then 
        player:move(mousePos)
        Insec()
    end 

    if orb.menu.combat.key:get() then 
        Combo() 
    end 

    if orb.menu.hybrid.key:get() then 
        Harass()
    end 

    if orb.menu.lane_clear.key:get() then 
        JungleClear()
    end
end 

local function on_create_particle(obj)
    if obj and obj.name then 
        if obj.name:find("Q_Ally") then
            Q.Barrel[obj.ptr] = obj
        end 
    end
end 

local function on_delete_particle(obj)
    if obj then 
        Q.Barrel[obj.ptr] = nil
    end
end

local function onDraw()
    if (player.isDead and not player.isTargetable and player.buff[17]) then 
        return 
    end

    if (player.isOnScreen) then
        local vecMyHero = graphics.world_to_screen(vec3(player.x, player.y, player.z))

        if menu.draws['qrange']:get() and player:spellSlot(0).state == 0 then 
            graphics.draw_circle_xyz(player.x, player.y, player.z, 850, 1, menu.draws['qcolor']:get(), 50)
        end 
        if menu.draws['wrange']:get() and player:spellSlot(1).state == 0 then 
            graphics.draw_circle_xyz(player.x, player.y, player.z, menu.combo['wrange']:get(), 1, menu.draws['wcolor']:get(), 50)
        end 
        if menu.draws['erange']:get() and player:spellSlot(2).state == 0 then 
            graphics.draw_circle_xyz(player.x, player.y, player.z, 600, 1, menu.draws['ecolor']:get(), 50)
        end 
        if menu.draws['rrange']:get() and player:spellSlot(3).state == 0 then 
            graphics.draw_circle_xyz(player.x, player.y, player.z, 1000, 1, menu.draws['rcolor']:get(), 50)
        end 
    end 

   --[[local target = common.GetTarget(1200)
    if target then 
        for i, object in pairs(Q.Barrel) do 
            if object and object ~= nil then 
                local Vecobj = object.pos
                local pre_predPos = gpred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)
                if not pre_predPos then 
                    return 
                end
                local vecTarget = vec3(pre_predPos.x, target.y, pre_predPos.y)
                local distobj = common.GetDistance(Vecobj, target.pos)
                local objPosition =  Vecobj + (vecTarget - Vecobj):norm() * (distobj + 300)
                --local vecMyHero = GeomLib.Vector:new(player.pos)
                --local dist = common.GetDistance(player.pos, target.pos)
                --local insecPosition = vecMyHero:extended(vecTarget, (dist + 300))
                local seg = gpred.circular.get_prediction(R.prediction_input, target)
                if seg and seg.endPos and vec3(player.x, player.y, player.z):to2D():distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y):to2D()) < R.prediction_input.range ^ 2 then
                    if objPosition:dist(target) < 1200 and target.pos2D:dist(object.pos2D) < 900 and target.pos2D:dist(object.pos2D) > 300 and not target.path.isDashing then 
                        if common.GetDistance(objPosition, player) < R.prediction_input.range and common.GetDistance(objPosition, target) < 300 and not IsWallBetween(Vecobj, vecTarget) then
                            graphics.draw_circle(objPosition, 50, 1, menu.draws['qcolor']:get(), 50)
                            --graphics.draw_circle(:toDX3(), 150, 1, menu.draws['qcolor']:get(), 50)
                            --[[common.DelayAction(
                                function()
                                    player:castSpell("pos", 3, objPosition:toDX3())
                                end,
                                0.5 + network.latency
                            )
                        end 
                    end
                end

               
            end 
        end
    end]]
end 

local function cbInterrupt(owner, spell)
    if not owner then 
        return 
    end 

    if not spell then 
        return 
    end 
    local whitelist = menu.misc.WhiteList[spell.name]
    if whitelist and whitelist:get() then
        if menu.misc.EInterrupt:get() and player:spellSlot(2).state == 0 then 
            if not GetRegisterCollision(owner) and owner.pos:dist(player.pos) < E.prediction_input.range then 
                player:castSpell("pos", 2, owner.pos)
            end 
        end 

        if menu.misc.RInterrupt:get() and common.GetPercentHealth(player) <= menu.misc['minhealthi']:get() then 
            if owner.pos:dist(player.pos) < R.prediction_input.range then 
                if player:spellSlot(3).state == 0 then 
                    player:castSpell("pos", 3, owner.pos)
                end
            end
        end 
    end 
end

cb.add(cb.draw, onDraw)
orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.create_particle, on_create_particle)
cb.add(cb.delete_particle, on_delete_particle)
interrupter(cbInterrupt) 