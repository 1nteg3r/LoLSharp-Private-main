local pMenu = module.load(header.id, "Core/Katarina/menu")
local common = module.load(header.id, "Library/common")
local dmgLib = module.load(header.id, "Library/damageLib")
local GeoLib = module.load(header.id, "Geometry/GeometryLib")

local orb = module.internal("orb")
local evade = module.seek('evade')
local gpred = module.internal("pred")

local menu = pMenu.menu 
--local TS = pMenu.TS 
local Vector = GeoLib.Vector

local Dagger = { }
local QPreparation = nil
local RCastTime = 0 

local Window = {x = graphics.res.x * 0.5, y = graphics.res.y * 0.5}
local pos = {x = Window.x, y = Window.y}

local Q = {
    Range = 650, 
    DamageType = "Magical",

    DamageTable = {75, 105, 135, 165, 195},
    GetTotalAP = 0.30, 

    castTime = os.clock(), 
    IsCasted = false
}

local W = {
    Range = 370, --but is real range 340 
    DamageType = "Magical"
}

local E = {
    Range = 725, 
    DamageType = "Null",

    DamageTable = {15, 30, 45, 60, 75},
    GetTotalAP = 0.25, 
    GetTotalAD = 0.50
}

local R = {
    Range = 550,
    DamageType = "Null",


    DamageTable = {25, 37.5, 50}
}

local ItemPrediction = {
    delay = 0.42,
    speed = 1600,
    width = 55,
    boundingRadiusMod = 1,
    collision = {
        hero = true,
        minion = true,
        wall = true 
    },
}

local DaggerCount = function()
    local Count = { }
    for i, dagger in pairs(Dagger) do 
        if dagger and dagger.obj and dagger.obj.health == 100 and not dagger.obj.isDead then 
            Count[#Count + 1] = dagger.obj 
        end 
    end 
    return #Count
end 

local TargetSelectorE = function(res, obj, dist)
    if DaggerCount() == 0 then 
        if dist and dist <= 775 then 
            res.obj = obj 
            return true 
        end 
    end 

    for i, dagger in pairs(Dagger) do 
        if dagger and dagger.obj and dagger.obj.health == 100 and not dagger.obj.isDead then 
            if common.GetDistanceSqr(dagger.obj, obj) < 450 ^ 2 and player:spellSlot(2).state == 0 then 
                res.obj = obj 
                return true 
            elseif (common.GetDistance(player, obj) < 725 and common.GetDistance(dagger.obj, obj) > 400) then
                if dist and dist <= 775 then 
                    res.obj = obj 
                    return true 
                end 
            elseif common.GetDistance(dagger.obj, obj) > 400 then 
                if dist and dist <= 775 then 
                    res.obj = obj 
                    return true 
                end
            end

            if common.GetDistanceSqr(player, dagger.obj) <= 725 ^ 2 and menu.combo['resetE']:get() then
                if player:spellSlot(2).state == 0 and common.GetDistanceSqr(dagger.obj, obj) < 625 ^ 2 then 
                    res.obj = obj 
                    return true 
                end 
            end
        end 
    end 
end 

local GetTarget = function()
    return orb.ts.get_result(TargetSelectorE).obj
end 

local CanCastE = function(target, pos)
    if not target then 
        return 
    end 

    if not pos then return end 

    if common.IsUnderDangerousTower(pos) then 
        return true 
    end 

    if evade and not evade.core.is_action_safe(pos, 5000, 0.25) then 
        return true 
    end 

    if (target and (target.buff['galiow'] and target.charName == "Galio") or (target.buff['jaxcounterstrike'] and target.charName == "Jax") or 
    (target.buff['warwicke'] and target.charName == "Warwick")) then 
        return true 
    end 

    return false
end 

local IsWallBetween = function(start, endPos, step)
    local start = start or Vector(0,0,0)
    local endPos = endPos or Vector(0,0,0)
    local step = step or 3 

    if (start and start ~= Vector(0,0,0)) and (endPos and endPos ~= Vector(0,0,0)) and step > 0 then 

        local distance = common.GetDistance(start, endPos)
        for i = 0, distance, step do   
            local VecStart = Vector(start)
            local VecEnd = Vector(endPos)

            local extend = VecStart + (VecEnd - VecStart):normalized() * i
            if extend and navmesh.isWall(extend:toDX3()) then  
                return true 
            end 
        end 
    end 
    return false
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


local function PDamage(target)
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
		if objs.obj and objs.obj.health == 100 and not objs.obj.isDead then
			if target.pos:dist(objs.obj.pos) < 450 then
				local damage = 0
                local ad = (common.GetBonusAD() * 0.75)
                local ap = (common.GetTotalAP() * leveldamage)
				if player.levelRef <= 18 then
					damage = (PDamages[player.levelRef] + common.calculatePhysicalDamage(target, ad) + common.calculateMagicalDamage(target, ap))
				end
				if player.levelRef > 18 then
					damage = (PDamages[18] + common.calculatePhysicalDamage(target, ad) + common.calculateMagicalDamage(target, ap))
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
		local ad = (common.GetTotalAD() * .5)
        local ap = (common.GetTotalAP() * .25)
		damage = (ElvlDmg[player:spellSlot(2).level] + common.calculatePhysicalDamage(target, ad) + common.calculateMagicalDamage(target, ap))
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


local Q_is_preparation = function()
    if QPreparation and QPreparation ~= nil then 
        return true 
    end 

    return false
end 

local function GetClosestToEnemy(target)
    if not target then
        return 
    end 

    local closestMinion = nil
	local closestMinionDistance = 9999

    if target and common.IsValidTarget(target) then 
        local minionsInRange = common.GetEnemyMinionsInRange(1500, TEAM_ENEMY)
        for _, minion in ipairs(minionsInRange) do
            if minion and minion.team ~= player.team then 
                local minionPos = Vector(minion.x, minion.y, minion.z)
                if common.GetDistance(minion, target) < Q.Range then
                    local minionDistanceToMouse = common.GetDistance(minion, target)

                    if minionDistanceToMouse < closestMinionDistance then
                        closestMinion = minion
                        closestMinionDistance = minionDistanceToMouse
                    end
                end
            end 
        end
    end 
	return closestMinion
end

local function GetMinionEnemy()
    local Minions = common.GetEnemyMinionsInRange(1500, TEAM_ENEMY)
    local closestMinion = nil
    local closestMinionDistance = 9999
    for i = 1, #Minions do
        local minion = Minions[i]
        if minion and common.IsValidTarget(minion) then
            if common.GetDistance(minion.pos, game.mousePos) < menu.flee.CursorRange:get() then
                local minionDistanceToMouse = common.GetDistance(minion.pos, game.mousePos)

                if minionDistanceToMouse < closestMinionDistance then
                    closestMinion = minion
                    closestMinionDistance = minionDistanceToMouse
                end
            end
        end
    end
    return closestMinion
end

local function GetMinionAlly()
    local Minions = common.GetAllyMinionsInRange(1500)
    local closestMinion = nil
    local closestMinionDistance = 9999
    for i = 1, #Minions do
        local minion = Minions[i]
        if minion and common.IsValidTarget(minion) then
            if common.GetDistance(minion.pos, game.mousePos) < menu.flee.CursorRange:get() then
                local minionDistanceToMouse = common.GetDistance(minion.pos, game.mousePos)

                if minionDistanceToMouse < closestMinionDistance then
                    closestMinion = minion
                    closestMinionDistance = minionDistanceToMouse
                end
            end
        end
    end
    return closestMinion
end

local function GetHeroAlly()
    local Minions = common.GetAllyHeroes()
    local closestMinion = nil
    local closestMinionDistance = 9999
    for i = 1, #Minions do
        local minion = Minions[i]
        if minion and common.IsValidTarget(minion) then
            if common.GetDistance(minion.pos, game.mousePos) < menu.flee.CursorRange:get() then
                local minionDistanceToMouse = common.GetDistance(minion.pos, game.mousePos)

                if minionDistanceToMouse < closestMinionDistance then
                    closestMinion = minion
                    closestMinionDistance = minionDistanceToMouse
                end
            end
        end
    end
    return closestMinion
end

local function ToMoveClosestDagger()
	local GetDagger = nil
	local Distance = 9999
    for i, Object in pairs(Dagger) do
        if Object.obj and not Object.obj.isDead and Object.obj.health == 100 and Object.obj ~= nil then  
			if common.GetDistance(Object.obj, player) < 360 then
				local DaggerDist = common.GetDistance(Object.obj, player)

				if DaggerDist < Distance then
					GetDagger = Object.obj
					Distance = DaggerDist
				end
			end
		end
	end
	return GetDagger
end

local function GetClosestToEnemy_Monster(target)
    if not target then
        return 
    end 

    local closestMinion = nil
	local closestMinionDistance = 9999

    if target and common.IsValidTarget(target) then 
        local minionsInRange = common.GetEnemyMinionsInRange(1500, TEAM_NEUTRAL)
        for _, minion in ipairs(minionsInRange) do
            if minion and minion.team ~= player.team and minion.team == 300 then 
                local minionPos = Vector(minion.x, minion.y, minion.z)
                if common.GetDistance(minion, target) < Q.Range then
                    local minionDistanceToMouse = common.GetDistance(minion, target)

                    if minionDistanceToMouse < closestMinionDistance then
                        closestMinion = minion
                        closestMinionDistance = minionDistanceToMouse
                    end
                end
            end 
        end
    end 
	return closestMinion
end

local function GetClosestToEnemyDagger(target)
    if not target then
        return 
    end 

    local closestMinion = nil
	local closestMinionDistance = 9999

    if target and common.IsValidTarget(target) then 
        local minionsInRange = common.GetEnemyMinionsInRange(1500, TEAM_ENEMY)
        for i, Object in pairs(Dagger) do 
            if Object and Object.obj and Object.obj.health == 100 and not Object.obj.isDead then 
                local minionPos = Vector(Object.x, Object.y, Object.z)
                if common.GetDistance(Object.obj, target) < Q.Range then
                    local minionDistanceToMouse = common.GetDistance(Object.obj, target)

                    if minionDistanceToMouse < closestMinionDistance then
                        closestMinion = Object.obj
                        closestMinionDistance = minionDistanceToMouse
                    end
                end
            end 
        end
    end 
	return closestMinion
end

local function GetEnemyHeroesInRange(position, range)
    local enemies_in_range = {}
    for _, enemy in pairs(common.GetEnemyHeroes()) do
        if enemy and enemy.isTargetable and not enemy.isDead and common.GetDistance(enemy, position) < range then
            enemies_in_range[#enemies_in_range + 1] = enemy
        end
    end
    return enemies_in_range
end

local function count_minions_in_range(position, range)
    local enemies_in_range = {}
    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
        local minion = objManager.minions[TEAM_ENEMY][i] 
        if minion and common.IsValidTarget(minion) and common.GetDistance(minion, position) < range then
            enemies_in_range[#enemies_in_range + 1] = minion
        end
    end
    return enemies_in_range
end


local Combo = function()
    if menu.combo.rset['cancelr']:get() and player.buff['katarinarsound'] then 
        if #GetEnemyHeroesInRange(player.pos, 560) == 0 then 
            player:move(mousePos)
        end 
    end

    if target and target ~= nil and common.IsValidTarget(target) then 
        if common.IsInRange(775, target, player) then 
            if player.buff['katarinarsound'] then 
                if menu.combo.rset.followup:get() then
                    if (common.GetDistance(target, player) >= 550 and player:spellSlot(2).state == 0) then 
                        if (DaggerCount() > 0) then 
                            for i, Object in pairs(Dagger) do 
                                if Object and Object.obj and Object.obj.health == 100 and not Object.obj.isDead then 
                                    if (common.GetDistance(target, Object.obj) <= 450 and common.GetDistance(target, player) <= 725 and player:spellSlot(2).state == 0) then
                                        local ObjVector = Vector(Object.obj)
                                        local DaggerPos = ObjVector:extended(target, 200):toDX3()
                
                                        if (common.IsInRange(450, target, Object.obj)) and common.GetDistanceSqr(DaggerPos, player) > 125 * 125 and (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                            player:castSpell("pos", 2, DaggerPos)

                                        end
                                    end 

                                    if (common.GetDistance(player, Object.obj) > 725 and common.GetDistance(target, player) <= 725 and player:spellSlot(2).state == 0) then
                                        local TargetVector = Vector(target)
                                        local TargetPos = TargetVector:extended(target, -50):toDX3()

                                        if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                            player:castSpell("pos", 2, TargetPos)
                                        end
                                    end

                                    if (common.GetDistance(target, Object.obj) > 450 and common.GetDistance(target, player) <= 725 and player:spellSlot(2).state == 0) then 
                                        local TargetVector = Vector(target)
                                        local TargetPos = TargetVector:extended(target, -50):toDX3()

                                        if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                            player:castSpell("pos", 2, TargetPos)
                                        end
                                    end 

                                    if menu.combo['resetE']:get() then 
                                        if (common.GetDistance(target, Object.obj) < 625 and common.GetDistance(target, Object.obj) > 400 and common.GetDistance(Object.obj, player) <= 725 and player:spellSlot(2).state == 0) then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, Object.obj.pos)) then 
                                                player:castSpell("pos", 2, Object.obj.pos)
                                            end
                                        end 
                                    end 
                                end 
                            end 
                        end 

                        if (DaggerCount() == 0) then 
                            if player:spellSlot(2).state == 0 and common.GetDistance(target, player) <= 725 then    
                                local TargetVector = Vector(target)
                                local TargetPos = TargetVector:extended(target, -50):toDX3()

                                if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                    player:castSpell("pos", 2, TargetPos)
                                end
                            end 
                        end 
                    end 
                end 
            end 
        end
        
        if not player.buff['katarinarsound'] then 
            --items 
            if menu.combo['items']:get() then 
                local target = common.GetTarget(925)

                if target and common.IsValidTarget(target) then 
                    for i = 6, 11 do 
                        local item = player:spellSlot(i).name 
                        if item and item == "3152Active" and player:spellSlot(i).state == 0 then  
                            if common.GetDistanceSqr(player, target) > 50 ^ 2 and common.GetDistanceSqr(player, target) < 925 ^ 2 and not IsWallBetween(player.pos, target.pos) then 
                                local seg = gpred.linear.get_prediction(ItemPrediction, target, vec2(player.x, player.z))
                                if seg and vec3(seg.startPos.x, target.y, seg.startPos.y):distSqr(vec3(seg.endPos.x, target.y, seg.endPos.y)) < 925 ^ 2 then 
                                    if player.pos:distSqr(vec3(seg.endPos.x, target.y, seg.endPos.y)) < 925 ^ 2 then 
                                        if not gpred.collision.get_prediction(ItemPrediction, seg, target) then 
                                            player:castSpell("pos", i, vec3(seg.endPos.x, target.y, seg.endPos.y))
                                        end        
                                    end       
                                end 
                            end 
                        end
                    end
                end 
            end 

            
            if menu.combomode:get() == 1 then -- Q > E
                if menu.combo['combo.q']:get() and player:spellSlot(0).state == 0 then 
                    local target = common.GetTarget(625)

                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if common.IsInRange(Q.Range, target, player) then 
                            player:castSpell("obj", _Q, target)
                        end 
                    end 
                end

                if menu.combo['combo.e']:get() and (player:spellSlot(0).state ~= 0 and not Q_is_preparation()) then  
                    if (DaggerCount() > 0) then 
                        for i, Object in pairs(Dagger) do
                             if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then  
                                if not menu.combo.saved:get() then 
                                    if common.GetDistance(target, Object.obj) < 450 then 
                                        local ObjVector = Vector(Object.obj)
                                        local DaggerPos = ObjVector:extended(target, 200):toDX3()
    
                                        if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 125 ^ 2 and player:spellSlot(2).state == 0 then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                player:castSpell("pos", _E, DaggerPos)
                                            end
                                        end
                                    end 
    
                                    if (player:spellSlot(3).state ~= 0 or player:spellSlot(3).level == 0) then 
                                        if common.GetDistance(Object.obj, player) > E.Range then 
                                            local TargetVector = Vector(target)
                                            local TargetPos = TargetVector:extended(player, 50):toDX3()
        
                                            if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                    player:castSpell("pos", _E, TargetPos)
                                                end
                                            end
                                        end 
    
                                        if common.GetDistance(Object.obj, target) > 450 then 
                                            local TargetVector = Vector(target)
                                            local TargetPos = TargetVector:extended(player, 50):toDX3()
        
                                            if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                    player:castSpell("pos", _E, TargetPos)
                                                end
                                            end
                                        end 
    
                                        if player:spellSlot(3).state == 0 then 
                                            if common.GetDistance(Object.obj, player) > E.Range then 
                                                local TargetVector = Vector(target)
                                                local TargetPos = TargetVector:extended(player, -50):toDX3()
            
                                                if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then  
                                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                        player:castSpell("pos", _E, TargetPos)
                                                    end
                                                end
                                            end 
    
                                            if common.GetDistance(Object.obj, target) > 450 then 
                                                local TargetVector = Vector(target)
                                                local TargetPos = TargetVector:extended(player, -50):toDX3()
            
                                                if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then  
                                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                        player:castSpell("pos", _E, TargetPos)
                                                    end
                                                end
                                            end 
                                        end 
                                    end 
                                end 

                                if menu.combo['resetE']:get() then 
                                    if (common.GetDistance(target, Object.obj) < 625 and common.GetDistance(target, Object.obj) > 400 and common.GetDistance(Object.obj, player) <= 725 and player:spellSlot(2).state == 0) then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, Object.obj.pos)) then 
                                            player:castSpell("pos", 2, Object.obj.pos)
                                        end
                                    end 
                                end 
    
                                if menu.combo.saved:get() then 
                                    if common.GetDistance(target, Object.obj) < 450 then 
                                        local ObjVector = Vector(Object.obj)
                                        local DaggerPos = ObjVector:extended(target, 200):toDX3()
            
                                        if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 150 * 150 and player:spellSlot(2).state == 0 then  
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                player:castSpell("pos", _E, DaggerPos)
                                            end
                                        end
                                    end 
                                end 
                            end 
                        end 
                    end
                    if (DaggerCount() == 0) then 
                        if not menu.combo.saved:get() then 
                            for i, Object in pairs(Dagger) do
                                if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then 
                                    if menu.combo['mode.q']:get() and player.levelRef == 2 and (player:spellSlot(0).level > 0 and player:spellSlot(2).level > 0) then 
                                        if common.GetDistance(target, Object.obj) < 450 then 
                                            local ObjVector = Vector(Object.obj)
                                            local DaggerPos = ObjVector:extended(target, 200):toDX3()
                
                                            if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 125 ^ 2 and player:spellSlot(2).state == 0 then 
                                                if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                    player:castSpell("pos", _E, DaggerPos)
                                                end
                                            end
                                        end 
                                    end
                                end 
                            end 
                            
                            if not menu.combo['mode.q']:get() or player.levelRef > 2 then  
                                if (player:spellSlot(3).state ~= 0 or player:spellSlot(3).level == 0) then  
                                    local TargetVector = Vector(target)
                                    local TargetPos = TargetVector:extended(player, 50):toDX3()
        
                                    if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                            player:castSpell("pos", _E, TargetPos)
                                        end
                                    end
                                end
        
                                if player:spellSlot(3).state == 0 then  
                                    local TargetVector = Vector(target)
                                    local TargetPos = TargetVector:extended(player, -50):toDX3()
        
                                    if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                            player:castSpell("pos", _E, TargetPos)
                                        end
                                    end
                                end 
                            end
                        end 
                    end 
                end 

                if menu.combo['combo.w']:get() then 
                    local target = common.GetTarget(400)
                    if target and common.IsValidTarget(target) and target ~= nil then 
                        if (#common.GetEnemyHeroesInRange(W.Range, player.pos) > 0) then 
                            if target and target.isVisible then 
                                if common.GetDistance(target, player) <= W.Range and player:spellSlot(1).state == 0 then 
                                    player:castSpell("self", _W)
                                end 
                            end
                        end 
                    end 
                end
    
                if (menu.combo.rset.rmod:get() == 1 and player:spellSlot(3).state == 0) then 
                    local target = common.GetTarget(550)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if (common.GetDistance(target, player) <= R.Range - 100) then 
                            if (#common.GetEnemyHeroesInRange(R.Range - 100, player.pos) >= menu.combo.rset.rhit:get()) then 
                                if (common.GetPercentHealth(target) >= menu.combo.rset.notUse:get() and player:spellSlot(0).state ~= 0) then
                                    if (player:spellSlot(1).state ~= 0) then
                                        player:castSpell("pos", _R, player.pos)
                                    end
                                end 
                            end 
                        end 
                    end
                end
    
    
                if (menu.combo.rset.rmod:get() == 2 and player:spellSlot(3).state == 0) then 
                    local target = common.GetTarget(550)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if (common.GetDistance(target, player) <= R.Range - 100) then 
                            if (common.GetShieldedHealth("ALL", target) <= RDamage(target) * 2 + PDamage(target) + EDamage(target) + QDamage(target)) then
                                if (common.GetPercentHealth(target) >= menu.combo.rset.notUse:get() and player:spellSlot(0).state ~= 0) then
                                    if (player:spellSlot(1).state ~= 0) then
                                        player:castSpell("pos", _R, player.pos)
                                    end
                                end
                            end
                        end
                    end
                end   
            end

            if menu.combomode:get() == 2 then -- E > Q 
                if menu.combo['combo.e']:get() then  
                    if (DaggerCount() > 0) then 
                        for i, Object in pairs(Dagger) do
                            if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then  
                                if not menu.combo.saved:get() then 
                                    if common.GetDistance(target, Object.obj) < 450 then 
                                        local ObjVector = Vector(Object.obj)
                                        local DaggerPos = ObjVector:extended(target, 200):toDX3()
    
                                        if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 125 ^ 2 and player:spellSlot(2).state == 0 then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                player:castSpell("pos", _E, DaggerPos)
                                            end
                                        end
                                    end 
    
                                    if (player:spellSlot(3).state ~= 0 or player:spellSlot(3).level == 0) then 
                                        if common.GetDistance(Object.obj, player) > E.Range then 
                                            local TargetVector = Vector(target)
                                            local TargetPos = TargetVector:extended(player, 50):toDX3()
        
                                            if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                    player:castSpell("pos", _E, TargetPos)
                                                end
                                            end
                                        end 
    
                                        if common.GetDistance(Object.obj, target) > 450 then 
                                            local TargetVector = Vector(target)
                                            local TargetPos = TargetVector:extended(player, 50):toDX3()
        
                                            if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                    player:castSpell("pos", _E, TargetPos)
                                                end
                                            end
                                        end 
    
                                        if player:spellSlot(3).state == 0 then 
                                            if common.GetDistance(Object.obj, player) > E.Range then 
                                                local TargetVector = Vector(target)
                                                local TargetPos = TargetVector:extended(player, -50):toDX3()
            
                                                if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                        player:castSpell("pos", _E, TargetPos)
                                                    end
                                                end
                                            end 
    
                                            if common.GetDistance(Object.obj, target) > 450 then 
                                                local TargetVector = Vector(target)
                                                local TargetPos = TargetVector:extended(player, -50):toDX3()
            
                                                if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                        player:castSpell("pos", _E, TargetPos)
                                                    end
                                                end
                                            end 
                                        end 
                                    end 
                                end 

                                if menu.combo['resetE']:get() then 
                                    if (common.GetDistance(target, Object.obj) < 625 and common.GetDistance(target, Object.obj) > 400 and common.GetDistance(Object.obj, player) <= 725 and player:spellSlot(2).state == 0) then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, Object.obj.pos)) then 
                                            player:castSpell("pos", 2, Object.obj.pos)
                                        end
                                    end 
                                end 
    
                                if menu.combo.saved:get() then 
                                    if common.GetDistance(target, Object.obj) < 450 then 
                                        local ObjVector = Vector(Object.obj)
                                        local DaggerPos = ObjVector:extended(target, 200):toDX3()
            
                                        if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 125 ^ 2 and player:spellSlot(2).state == 0 then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                player:castSpell("pos", _E, DaggerPos)
                                            end
                                        end
                                    end 
                                end 
                            end 
                        end 
                    end
                    if (DaggerCount() == 0) then 
                        if not menu.combo.saved:get() then 

                            for i, Object in pairs(Dagger) do
                                if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then 
                                    if menu.combo['mode.q']:get() and player.levelRef == 2 and (player:spellSlot(0).level > 0 and player:spellSlot(2).level > 0) then 
                                        if common.GetDistance(target, Object.obj) < 450 then 
                                            local ObjVector = Vector(Object.obj)
                                            local DaggerPos = ObjVector:extended(target, 200):toDX3()
                
                                            if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 125 ^ 2 and player:spellSlot(2).state == 0 then 
                                                if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                    player:castSpell("pos", _E, DaggerPos)
                                                end
                                            end
                                        end 
                                    end
                                end 
                            end 
                            
                            if not menu.combo['mode.q']:get() or player.levelRef > 2  then  
                                if (player:spellSlot(3).state ~= 0 or player:spellSlot(3).level == 0) then  
                                    local TargetVector = Vector(target)
                                    local TargetPos = TargetVector:extended(player, 50):toDX3()
        
                                    if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                            player:castSpell("pos", _E, TargetPos)
                                        end
                                    end
                                end
        
                                if player:spellSlot(3).state == 0 then  
                                    local TargetVector = Vector(target)
                                    local TargetPos = TargetVector:extended(player, -50):toDX3()
        
                                    if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                            player:castSpell("pos", _E, TargetPos)
                                        end
                                    end
                                end 
                            end
                        end 
                    end 
                end 
                if menu.combo['combo.w']:get() then 
                    local target = common.GetTarget(400)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if (#common.GetEnemyHeroesInRange(W.Range) > 0) then 
                            if target and target.isVisible then 
                                if common.GetDistance(target, player) <= W.Range and player:spellSlot(1).state == 0 then 
                                    player:castSpell("self", _W)
                                end 
                            end
                        end 
                    end 
                end
                if menu.combo['combo.q']:get() and player:spellSlot(0).state == 0 then 
                    local target = common.GetTarget(625)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if common.IsInRange(Q.Range, target, player) then 
                            player:castSpell("obj", _Q, target)
                        end 
                    end
                end

                if (menu.combo.rset.rmod:get() == 1 and player:spellSlot(3).state == 0) then 
                    local target = common.GetTarget(550)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if (common.GetDistance(target, player) <= R.Range - 100) then 
                            if (#common.GetEnemyHeroesInRange(R.Range - 100, player.pos) >= menu.combo.rset.rhit:get()) then 
                                if (common.GetPercentHealth(target) >= menu.combo.rset.notUse:get() and player:spellSlot(0).state ~= 0) then
                                    if (player:spellSlot(1).state ~= 0) then
                                        player:castSpell("pos", _R, player.pos)
                                    end
                                end 
                            end 
                        end 
                    end
                end
    
    
                if (menu.combo.rset.rmod:get() == 2 and player:spellSlot(3).state == 0) then 
                    local target = common.GetTarget(550)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if (common.GetDistance(target, player) <= R.Range - 100) then 
                            if (common.GetShieldedHealth("ALL", target) <= RDamage(target) * 2 + PDamage(target) + EDamage(target) + QDamage(target)) then
                                if (common.GetPercentHealth(target) >= menu.combo.rset.notUse:get() and player:spellSlot(0).state ~= 0) then
                                    if (player:spellSlot(1).state ~= 0) then
                                        player:castSpell("pos", _R, player.pos)
                                    end
                                end
                            end
                        end
                    end
                end    
            end 
            
            if menu.combomode:get() == 3 then -- E > W > R > Q
                if (menu.combo["combo.q"]:get() and player:spellSlot(3).state ~= 0) and RCastTime < os.clock() then
                    local target = common.GetTarget(625)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if common.IsInRange(Q.Range, target, player) and player:spellSlot(0).state == 0 then  
                            player:castSpell("obj", _Q, target)
                        end 
                    end 
                end
                if menu.combo['combo.e']:get() then  
                    if (DaggerCount() > 0) then 
                        for i, Object in pairs(Dagger) do
                            if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then  
                                if not menu.combo.saved:get() then 
                                    if common.GetDistance(target, Object.obj) < 450 then 
                                        local ObjVector = Vector(Object.obj)
                                        local DaggerPos = ObjVector:extended(target, 200):toDX3()
    
                                        if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 125 ^ 2 and player:spellSlot(2).state == 0 then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                player:castSpell("pos", _E, DaggerPos)
                                            end
                                        end
                                    end 

                                    if (player:spellSlot(3).state ~= 0 or player:spellSlot(3).level == 0) then 
                                        if common.GetDistance(Object.obj, player) > E.Range then 
                                            local TargetVector = Vector(target)
                                            local TargetPos = TargetVector:extended(player, 50):toDX3()
        
                                            if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                    player:castSpell("pos", _E, TargetPos)
                                                end
                                            end
                                        end 
    
                                        if common.GetDistance(Object.obj, target) > 450 then 
                                            local TargetVector = Vector(target)
                                            local TargetPos = TargetVector:extended(player, 50):toDX3()
        
                                            if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                    player:castSpell("pos", _E, TargetPos)
                                                end
                                            end
                                        end 
    
                                        if player:spellSlot(3).state == 0 then 
                                            if common.GetDistance(Object.obj, player) > E.Range then 
                                                local TargetVector = Vector(target)
                                                local TargetPos = TargetVector:extended(player, -50):toDX3()
            
                                                if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                        player:castSpell("pos", _E, TargetPos)
                                                    end
                                                end
                                            end 
    
                                            if common.GetDistance(Object.obj, target) > 450 then 
                                                local TargetVector = Vector(target)
                                                local TargetPos = TargetVector:extended(player, -50):toDX3()
            
                                                if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                        player:castSpell("pos", _E, TargetPos)
                                                    end
                                                end
                                            end 
                                        end 
                                    end 
                                end 

                                if menu.combo['resetE']:get() then 
                                    if (common.GetDistance(target, Object.obj) < 625 and common.GetDistance(target, Object.obj) > 400 and common.GetDistance(Object.obj, player) <= 725 and player:spellSlot(2).state == 0) then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, Object.obj.pos)) then 
                                            player:castSpell("pos", 2, Object.obj.pos)
                                        end
                                    end 
                                end 
    
                                if menu.combo.saved:get() then 
                                    if common.GetDistance(target, Object.obj) < 450 then 
                                        local ObjVector = Vector(Object.obj)
                                        local DaggerPos = ObjVector:extended(target, 200):toDX3()
            
                                        if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 125 ^ 2 and player:spellSlot(2).state == 0 then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                player:castSpell("pos", _E, DaggerPos)
                                            end
                                        end
                                    end 
                                end 
                            end 
                        end 
                    end

                    if (DaggerCount() == 0) then 
                        if not menu.combo.saved:get() then 
                            if (player:spellSlot(3).state ~= 0 or player:spellSlot(3).level == 0) then  
                                local TargetVector = Vector(target)
                                local TargetPos = TargetVector:extended(player, 50):toDX3()
    
                                if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                        player:castSpell("pos", _E, TargetPos)
                                    end
                                end
                            end
    
                            if player:spellSlot(3).state == 0 then  
                                local TargetVector = Vector(target)
                                local TargetPos = TargetVector:extended(player, -50):toDX3()
    
                                if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                        player:castSpell("pos", _E, TargetPos)
                                    end
                                end
                            end 
                        end 
                    end 
                end 

                if menu.combo['combo.w']:get() then 
                    local target = common.GetTarget(400)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if (#common.GetEnemyHeroesInRange(W.Range) > 0) then 
                            if target and target.isVisible then 
                                if common.GetDistance(target, player) <= W.Range and player:spellSlot(1).state == 0 then 
                                    player:castSpell("self", _W)
                                end 
                            end
                        end 
                    end 
                end

                if player:spellSlot(3).state == 0 then  
                    local target = common.GetTarget(550)
                    if target and target ~= nil and common.IsValidTarget(target) then 
                        if common.IsInRange(R.Range - 100, target, player) then 
                            if (player:spellSlot(1).state ~= 0) then
                                player:castSpell("pos", _R, player.pos)
                            end
                        end 
                    end 
                end 
            end 

            local qdelay = 0
            if menu.combomode:get() == 4 then -- Q > Dagger
                if menu.combo['combo.q']:get() and player:spellSlot(0).state == 0 then 
                    if common.IsInRange(Q.Range, target, player) then 
                        player:castSpell("obj", 0, target)
                        qdelay = game.time
                    end 
                end
                if menu.combo['combo.e']:get() then  
                    if (DaggerCount() > 0) then 
                        for i, Object in pairs(Dagger) do
                            if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then   
                                if not menu.combo.saved:get() then 
                                    if common.GetDistance(target, Object.obj) < 450 then 
                                        local ObjVector = Vector(Object.obj)
                                        local DaggerPos = ObjVector:extended(target, 200):toDX3()
    
                                        if (common.IsInRange(400, target, DaggerPos)) and common.GetDistanceSqr(DaggerPos, player) > 125 ^ 2 and player:spellSlot(2).state == 0 then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                                player:castSpell("pos", _E, DaggerPos)
                                            end
                                        end
                                    end 
                                end 
                            end 
                        end 
                    end 
                    if (DaggerCount() == 0 and not Q_is_preparation() and player:spellSlot(0).state ~= 0 and player:spellSlot(1).state == 0) and (game.time - qdelay > 1.25) then 
                        if not menu.combo.saved:get() then 
                            if (player:spellSlot(3).state ~= 0 or player:spellSlot(3).level == 0) then  
                                local TargetVector = Vector(target)
                                local TargetPos = TargetVector:extended(target, 50):toDX3()
    
                                if (common.IsInRange(725, target, TargetPos)) and player:spellSlot(2).state == 0 then 
                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                        player:castSpell("pos", _E, TargetPos)
                                        qdelay = 0 
                                    end
                                end
                            end
    
                            if player:spellSlot(3).state == 0 then  
                                local TargetVector = Vector(target)
                                local TargetPos = TargetVector:extended(target, -50):toDX3()
    
                                if (common.IsInRange(725, target, TargetPos)) and player:spellSlot(2).state == 0 then 
                                    if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                        player:castSpell("pos", _E, TargetPos)
                                        qdelay = 0 
                                    end
                                end
                            end 
                        end 
                    end
                end 
                    
                if menu.combo['combo.w']:get() then 
                    if (#common.GetEnemyHeroesInRange(W.Range) > 0) then 
                        if target and target.isVisible then 
                            if common.GetDistance(target, player) <= W.Range and player:spellSlot(1).state == 0 then 
                                player:castSpell("self", _W)
                            end 
                        end
                    end 
                end    

                if (menu.combo.rset.rmod:get() == 1 and player:spellSlot(3).state == 0) then 
                    if (common.GetDistance(target, player) <= R.Range - 100) then 
                        if (#common.GetEnemyHeroesInRange(R.Range - 100, player.pos) >= menu.combo.rset.rhit:get()) then 
                            if (common.GetPercentHealth(target) >= menu.combo.rset.notUse:get() and player:spellSlot(0).state ~= 0) then
                                if (player:spellSlot(1).state ~= 0) then
                                    player:castSpell("pos", _R, player.pos)
                                end
                            end 
                        end 
                    end 
                end
    
    
                if (menu.combo.rset.rmod:get() == 2 and player:spellSlot(3).state == 0) then 
                    if (common.GetDistance(target, player) <= R.Range - 100) then 
                        if (common.GetShieldedHealth("ALL", target) <= RDamage(target) * 2 + PDamage(target) + EDamage(target) + QDamage(target)) then
                            if (common.GetPercentHealth(target) >= menu.combo.rset.notUse:get() and player:spellSlot(0).state ~= 0) then
                                if (player:spellSlot(1).state ~= 0) then
                                    player:castSpell("pos", _R, player.pos)
                                end
                            end
                        end
                    end
                end 
            end 
        end 
    end 
end 

local KillSteal = function()
    local enemies = common.GetEnemyHeroes()
    for i = 1, #enemies do
        local target = enemies[i] 
        if target and common.IsValidTarget(target) and common.IsEnemyMortal(target) then  
            local Health = common.GetShieldedHealth("ALL", target)

            if menu.misc.ksedagger:get() then 
                for i, Object in pairs(Dagger) do
                    if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then
                        if (common.GetDistance(target, player) <= E.Range and common.GetDistance(Object.obj, target) < 450 and PDamage(target) > Health) then
                            local ObjVector = Vector(Object.obj)
                            local DaggerPos = ObjVector:extended(target, 200):toDX3()

                            if (common.IsInRange(450, target, DaggerPos)) and player:spellSlot(2).state == 0 then 
                                player:castSpell("pos", _E, DaggerPos)
                            end
                        end 
                    end 
                end
            end 


            if menu.misc.ksq:get() then 
                if player:spellSlot(0).state == 0 and common.GetDistance(target, player) <= Q.Range and QDamage(target) > common.GetShieldedHealth("AP", target) then 
                    player:castSpell("obj", _Q, target)
                end 
            end 

            if menu.misc.kse:get() then 
                if player:spellSlot(2).state == 0 and common.GetDistance(target, player) <= E.Range and EDamage(target) > common.GetShieldedHealth("AP", target) then 
                    player:castSpell("pos", _E, target.pos)
                end 

                if player:spellSlot(2).state == 0 and player:spellSlot(0).state == 0 and common.GetDistance(target, player) <= E.Range and (QDamage(target) + EDamage(target) > common.GetShieldedHealth("AP", target)) then 
                    player:castSpell("pos", _E, target.pos)
                end
                
                if player:spellSlot(2).state == 0 and orb.core.can_attack() and common.GetDistance(target, player) <= E.Range and (common.calculateFullAADamage(target, player) + EDamage(target) > common.GetShieldedHealth("ALL", target)) then 
                    player:castSpell("pos", _E, target.pos)
                end 
            end 


            if menu.misc.ksegap:get() then 
                if player:spellSlot(0).state == 0 and common.GetDistance(target, player) > Q.Range and common.GetDistance(target, player) < Q.Range + E.Range - 70 and QDamage(target) - 30 > Health then 
                    local minion = GetClosestToEnemy(target)
					if minion and common.GetDistance(player, minion) <= E.Range then
                        player:castSpell("pos", _E, minion.pos)
					end --GetClosestToEnemy_Monster

                    local mobs = GetClosestToEnemy_Monster(target)
					if mobs and common.GetDistance(player, mobs) <= E.Range then
                        player:castSpell("pos", _E, mobs.pos)
					end --GetClosestToEnemyDagger 

                    local Dagger = GetClosestToEnemyDagger(target)
					if Dagger and common.GetDistance(player, Dagger) <= E.Range then
                        player:castSpell("pos", _E, Dagger.pos)
					end
                end 
            end 
        end 
    end 
end 

local Harass = function()
    if target and target ~= nil and common.IsValidTarget(target) then 

        if menu.harass['harass.q']:get() then 
            if common.GetDistance(target, player) <= Q.Range and player:spellSlot(0).state == 0 then 
                player:castSpell("obj", _Q, target)
            end 
        end

        if menu.harass['harass.w']:get() then 
            if (#common.GetEnemyHeroesInRange(W.Range) > 0) then 
                if target and target.isVisible then 
                    if common.GetDistance(target, player) <= W.Range and player:spellSlot(1).state == 0 then 
                        player:castSpell("self", _W)
                    end 
                end
            end 
        end

        if menu.harass['harass.e']:get() then 
            if (DaggerCount() > 0) then 
                for i, Object in pairs(Dagger) do
                    if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then
                        if not menu.harass.saved:get() then 
                            if common.GetDistance(target, Object.obj) < 450 then 
                                local ObjVector = Vector(Object.obj)
                                local DaggerPos = ObjVector:extended(target, 200):toDX3()

                                if (common.IsInRange(375, target, DaggerPos)) and player:spellSlot(2).state == 0 then 
                                    if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                        player:castSpell("pos", _E, DaggerPos)
                                    end
                                end
                            end 

                            if (player:spellSlot(3).state ~= 0 or player:spellSlot(3).level == 0) then 
                                if common.GetDistance(Object.obj, player) > E.Range then 
                                    local TargetVector = Vector(target)
                                    local TargetPos = TargetVector:extended(player, 50):toDX3()

                                    if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                            player:castSpell("pos", _E, TargetPos)
                                        end
                                    end
                                end 

                                if common.GetDistance(Object.obj, target) > 450 then 
                                    local TargetVector = Vector(target)
                                    local TargetPos = TargetVector:extended(player, 50):toDX3()

                                    if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                        if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                            player:castSpell("pos", _E, TargetPos)
                                        end
                                    end
                                end 

                                if player:spellSlot(3).state == 0 then 
                                    if common.GetDistance(Object.obj, player) > E.Range then 
                                        local TargetVector = Vector(target)
                                        local TargetPos = TargetVector:extended(player, -50):toDX3()
    
                                        if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                player:castSpell("pos", _E, TargetPos)
                                            end
                                        end
                                    end 

                                    if common.GetDistance(Object.obj, target) > 450 then 
                                        local TargetVector = Vector(target)
                                        local TargetPos = TargetVector:extended(player, -50):toDX3()
    
                                        if (common.IsInRange(725, player, TargetPos)) and player:spellSlot(2).state == 0 then 
                                            if (not menu.misc['eturret']:get() or not CanCastE(target, TargetPos)) then 
                                                player:castSpell("pos", _E, TargetPos)
                                            end
                                        end
                                    end 
                                end 
                            end 
                        end 

                        if menu.harass.saved:get() then 
                            if common.GetDistance(target, Object.obj) < 450 then 
                                local ObjVector = Vector(Object.obj)
                                local DaggerPos = ObjVector:extended(target, 200):toDX3()
    
                                if (common.IsInRange(375, target, DaggerPos)) and player:spellSlot(2).state == 0 then 
                                    if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                        player:castSpell("pos", _E, DaggerPos)
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

local LaneClear = function()
    if not menu.keys['toggleFarm']:get() then 
        return 
    end 

    local enemyMinions = common.GetEnemyMinionsInRange(800, TEAM_ENEMY, player)
    for i = 1, #enemyMinions do
        local minion = enemyMinions[i]
        if minion and minion.maxHealth > 5 and not minion.isDead  and not (minion.name:lower():find("camprespawn") or minion.name:lower():find("plant") or minion.charName == "TestCubeRender") then

            if menu.wave['wave.q']:get() and menu.wave['lastHit']:get() then
                if common.GetDistance(player, minion) <= Q.Range then 
                    if (QDamage(minion) >= orb.farm.predict_hp(minion, 0.25)) and player:spellSlot(0).state == 0 then 
                        if not (menu.wave.outRange:get()) then
                            player:castSpell("obj", _Q, minion)
                        end
                        if (menu.wave.outRange:get()) and common.GetDistance(player, minion) > common.GetAARange(minion) and player:spellSlot(0).state == 0 then
                            player:castSpell("obj", _Q, minion)
                        end
                    end
                end
            end

            if menu.wave['wave.q']:get() and not menu.wave['lastHit']:get() then
                local minionPos = Vector(minion.x, minion.y, minion.z)
                if common.GetDistance(minionPos, player) <= Q.Range and player:spellSlot(0).state == 0 then
                    player:castSpell("obj", _Q, minion)
                end
            end

            if menu.wave['wave.w']:get() then
                if #count_minions_in_range(player.pos, 450) >= menu.wave.minion:get() and player:spellSlot(1).state == 0 then
                    player:castSpell("self", _W)
                end
            end

            if menu.wave["wave.e"]:get() then 
                if (#GetEnemyHeroesInRange(player.pos, 1300) <= menu.wave.enemyRange:get()) then 
                    if common.GetPercentHealth(player) >= menu.wave.minHealth:get() then
                        for i, Object in pairs(Dagger) do
                             if Object.obj and not Object.obj.isDead and Object.obj.health == 100 then  
                                local minionPos = Vector(minion.x, minion.y, minion.z)
                                local ObjVector = Vector(Object.obj)
                                local DaggerPos = ObjVector:extended(minionPos, 200):toDX3()

                                if #count_minions_in_range(DaggerPos, 450) >= menu.wave.rhit:get() then
                                    if (common.IsInRange(450, minion, DaggerPos))then 

                                        if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                                            player:castSpell("pos", _E, DaggerPos)
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
end

local Magnet = function()
    if player.buff['katarinarsound'] then 
        return 
    end

    if ((menu.misc['catch']:get() == 1 and orb.menu.combat.key:get()) or (menu.misc['catch']:get() == 2)) then 
        local dagger = ToMoveClosestDagger()
        if target and common.IsValidTarget(target) and target.team ~= player.team and common.IsEnemyMortal(target) then  

            if dagger and common.GetDistance(target, player) < 500 then 
                local ObjVector = Vector(dagger)
                local DaggerPos = ObjVector:extended(target, 200):toDX3()
                if common.GetDistance(DaggerPos, player) > 85 then
                    if (not menu.misc['eturret']:get() or not CanCastE(target, DaggerPos)) then 
                        player:move(DaggerPos)
                        orb.core.set_pause_move(math.huge)
                        orb.core.set_server_pause()
                    end
                end
            else
                orb.core.set_pause_move(0)
            end
        end 
    end 
end 

local Flee = function()
    player:move(game.mousePos)

    if not menu.flee['E.Use']:get() then 
        return 
    end 

    local Minions = GetMinionEnemy()
    if Minions and menu.flee['E.Monster']:get() and common.GetPercentHealth(myHero) > menu.flee["minHealth"]:get() then
        if player:spellSlot(2).state == 0 then 
            player:castSpell("pos", _E, Minions.pos)
        end
    end
    local MinionsAlly = GetMinionAlly()
    if MinionsAlly and menu.flee['E.Minion']:get() then
        if player:spellSlot(2).state == 0 then 
            player:castSpell("pos", _E, MinionsAlly.pos)
        end 
    end
    local HerosAlly = GetHeroAlly()
    if HerosAlly and menu.flee['E.Champ']:get() then
        if player:spellSlot(2).state == 0 then 
            player:castSpell("pos", _E, HerosAlly.pos)
        end
    end
    for _, Object in pairs(Dagger) do
        if Object.obj and not Object.obj.isDead and menu.flee['E.Dagger']:get() then
            if (common.GetDistance(game.mousePos, Object.obj.pos) < menu.flee.CursorRange:get()) then
                if player:spellSlot(2).state == 0 then 
                    player:castSpell("pos", _E, Object.obj.pos)
                end
            end
        end
    end
end

local WGabcloser = function()
    --common.IsMovingTowards(target, 500)
    local target = module.internal("TS").get_result(function(res, obj, dist)
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

local on_tick = function()
    KillSteal()

    if menu.misc['magnet']:get() then
        Magnet()
    end

    if menu.combo['gab.w']:get() then 
        WGabcloser()
    end 
    --Target 
    target = GetTarget()
    --Execute TimeCast R 
    if player.buff['katarinarsound'] then 
        orb.core.set_pause_move(math.huge)
        orb.core.set_pause_attack(math.huge)

        if evade then 
            evade.core.set_pause(math.huge)
        end
        
        orb.core.set_server_pause()
    else 
        orb.core.set_pause_move(0)
        orb.core.set_pause_attack(0)

        if evade then 
            evade.core.set_pause(0)
        end
    end 

    if Q.castTime and os.clock() - Q.castTime > 0.1 then 
        Q.castTime = 0 
        Q.IsCasted = false
    end 

    if evade then 
        if orb.menu.combat.key:get() and menu.misc['disableEvade']:get() then 
            evade.core.set_pause(math.huge)
        else 
            evade.core.set_pause(0)
        end 
    end 

    if menu.keys['toggleSafe']:get() then 
        menu.misc['eturret']:set("value", true)
    else 
        menu.misc['eturret']:set("value", false)
    end  
    --[[if target then 
        if (not menu.misc['eturret']:get() or not CanCastE(target, target.pos)) then 
            player:castSpell("pos", 2, target.pos)
        end 
    end ]]

    --Combat 
    if orb.menu.combat.key:get() then 
        Combo()
    end 
    --Harass 
    if orb.menu.hybrid.key:get() then 
        Harass()
    end 
    --Clear
    if orb.menu.lane_clear.key:get() then 
        LaneClear()
    end 

    if menu.flee.fleekey:get() then 
        Flee()
    end 
end 

local create_particle = function(obj)
    if not obj then 
        return 
    end 

    if obj.name == "HiddenMinion" and obj.team == player.team and obj.owner.charName == "Katarina" then
        Dagger[obj.ptr] = { 
            obj = obj, endT = os.clock() + 5.55
        }
    end 
end 

local on_create_particle = function(obj)
    if not obj then 
        return 
    end 

    if obj and (obj.name:find("KatarinaQ") or obj.name:find("Q_mis")) then
        QPreparation = obj 
    end 

    if obj and obj.name:find("R_cas") then 
        RCastTime = os.clock() + 1
    end 
end 

local delete_particle = function(obj)
    if not obj then 
        return 
    end 

    for i, dagger in pairs(Dagger) do 
        if dagger then 
            if dagger.obj == obj then 
                Dagger[obj.ptr] = nil 
            end 
        end 
    end 
end 

local on_delete_particle = function(obj)
    if not obj then 
        return 
    end 

    if QPreparation and QPreparation == obj then 
        QPreparation = nil 
    end 
end 

local on_process_spell = function(spell)
    if spell and spell.owner.team == player.team and spell.owner.charName == "Katarina" then 
        if spell.name == "KatarinaQ" then 
            Q.castTime = os.clock() + spell.clientWindUpTime
            Q.IsCasted = true 
        end 
    end 
end 

local on_draw = function()

    if menu.keys['toogledraw']:get() then 
        if menu.keys.toggleSafe:get() then
			graphics.draw_text_2D("["..menu.keys.toggleSafe.toggle.."] Safe Position: ", 18, pos.x + 307, pos.y + 425, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("On", 18, pos.x + 495, pos.y + 425, graphics.argb(255, 7, 219, 63))
		else
			graphics.draw_text_2D("["..menu.keys.toggleSafe.toggle.."] Safe Position: ", 18, pos.x + 307, pos.y + 425, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("Off", 18, pos.x + 495, pos.y + 425, graphics.argb(255, 219, 7, 7))
        end

        if menu.keys.toggleFarm:get() then
			graphics.draw_text_2D("["..menu.keys.toggleFarm.toggle.."] Farm: ", 18, pos.x + 307, pos.y + 450, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("On", 18, pos.x + 400, pos.y + 450, graphics.argb(255, 7, 219, 63))
		else
			graphics.draw_text_2D("["..menu.keys.toggleFarm.toggle.."] Farm: ", 18, pos.x + 307, pos.y + 450, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("Off", 18, pos.x + 400, pos.y + 450, graphics.argb(255, 219, 7, 7))
        end

        graphics.draw_line_2D(pos.x + 300, pos.y+435, pos.x + 535, pos.y+435, 100, 0xff1f1f1f)
        graphics.draw_line_2D(pos.x + 535, pos.y + 385, pos.x + 300, pos.y + 385, 3, 0xFFFFFFFF)
    end 
    --Draws
    if player.isDead or player.buff[17] then 
        return 
    end 

    if not player.isOnScreen then 
        return 
    end 

    --Color
    local qColor = menu.draws['qcolor']:get()
    local wColor = menu.draws['wcolor']:get()
    local eColor = menu.draws['ecolor']:get()
    local rColor = menu.draws['rcolor']:get()

    --Orther 
    local Points = menu.draws['points_n']:get()
    local WidthCircle = menu.draws['widthLine']:get()

    --Spells 
    if (player:spellSlot(0).state == 0 and menu.draws['qrange']:get()) then 
        graphics.draw_circle(player.pos, 625, WidthCircle, qColor, Points)
    end 

    if (player:spellSlot(1).state == 0 and menu.draws['wrange']:get()) then 
        graphics.draw_circle(player.pos, 400, WidthCircle, wColor, Points)
    end 

    if (player:spellSlot(2).state == 0 and menu.draws['erange']:get()) then 
        graphics.draw_circle(player.pos, 725, WidthCircle, eColor, Points)
    end 

    if (player:spellSlot(3).state == 0 and menu.draws['rrange']:get()) then 
        graphics.draw_circle(player.pos, 550, WidthCircle, rColor, Points)
    end 

    --Dagger
    for i, dagger in pairs(Dagger) do 
        if dagger and dagger.obj and dagger.obj.health == 100 and not dagger.obj.isDead then 

            local pos = graphics.world_to_screen(vec3(dagger.obj.pos.x, dagger.obj.pos.y, dagger.obj.pos.z))

            if menu.draws['daggerTime']:get() then 
                graphics.draw_text_2D("Timer: "..math.ceil(dagger.endT - os.clock()), menu.draws['widthDagger']:get(), pos.x - 25, pos.y, 0xFFFFFFFF)
            end 

            if menu.draws['daggerCircle']:get() then 
                graphics.draw_circle(dagger.obj.pos, 370, 2, 0xffb31307, 100)
            end 
        end 
    end 

    if target and target ~= nil and common.IsValidTarget(target) then 
        graphics.draw_circle(target.pos, target.boundingRadius, 3, 0xFFFFFFFF, 100)
    end 
end 

return {
    on_tick = on_tick,
    create_particle = create_particle,
    delete_particle = delete_particle,
    on_create_particle = on_create_particle, 
    on_delete_particle = on_delete_particle,
    on_process_spell = on_process_spell,
    on_draw = on_draw, 
}