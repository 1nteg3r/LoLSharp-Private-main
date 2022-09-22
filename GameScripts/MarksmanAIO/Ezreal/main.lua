local orb = module.internal("orb");
local pred = module.internal("pred")
local evade = module.seek('evade')
local common = module.load(header.id, "common")
local targetSelector = module.internal("TS");
local damage = module.load(header.id, "damageLib")
local VPred = module.load(header.id, "VP")

local Samaritan = {}
local MissileTrue = false
local OverKill = 0

local q_pred_input = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    type = 'linear',
    delay = 0.25,
    speed = 2000,
    width = 60,
    range = 1200,
    collision = { hero = true, minion = true, wall = true },

    damage = function(target)
        if not target then 
            return 
        end 

        if (player:spellSlot(0).level == 0) then 
            return 
        end 

        local dmg = ({20, 45, 70, 95, 120})[player:spellSlot(0).level]
        local damageAP = (common.GetTotalAP(player) * 0.30)
        local damageAD = (common.GetTotalAD(player) * 1.2)

        return (dmg + common.calculatePhysicalDamage(target, damageAD) + common.calculateMagicalDamage(target, damageAP))
    end,
}

local w_pred_input = {
    delay = 0.25,
    speed = 1650,
    width = 160,
    range = 1150,
    boundingRadiusMod = 1,
    collision = {
        hero = true,
        wall = true,
        terrain = true,
    },
}

local r_pred_input = {
    delay = 1.,
    speed = 2000,
    width = 320,
    range = 2000,
    boundingRadiusMod = 1,
    collision = {
        wall = true,
    }
}

function Samaritan.Project(sourcePosition, unitPosition, unitDestination, spellSpeed, unitSpeed)
    local toUnit = unitPosition - sourcePosition
    local toDestination = unitDestination - unitPosition

    local cos = toUnit:norm():dot(toDestination:norm())
    local sin = math.abs(toUnit:norm():cross(toDestination:norm()))

    local atan = math.atan(cos)
    local atan2 = math.atan2(cos, sin)
    local sin2 = atan / atan2

    local unitVelocity = toDestination:norm() * unitSpeed
    local relativeUnitVelocity = toDestination:norm() * unitSpeed * cos

    local speedRatio = unitSpeed / spellSpeed
    local sinDifference = math.abs(sin2 - sin)

    local formula = math.pi * 0.5 - sin2 - cos + sinDifference

    local spellVelocity = toUnit:norm() * spellSpeed
    local relativeSpellVelocity = toUnit:norm() * spellSpeed / formula

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

local menu = menu("IntnnerEzreal", "Marksman - Ezreal")
menu:menu('combo', 'Combo Settings')
menu.combo:header('qq', "Q - Settings")
    menu.combo:boolean("qcombo", "Use Q", true)
    menu.combo:boolean("w.mark", "^~ Q only mark W", false)
    menu.combo:slider("q.range", "Min. Q Range", 1100, 0, 1200, 10)
menu.combo:header('ww', "W - Settings")
    menu.combo:boolean("wcombo", "Use W", true)
    menu.combo:boolean("w.coll", "^~ Ignore collision to Q", false)
    --menu.combo:boolean("w.AA", "^~ W if enemy AA Range", false)
    menu.combo:slider("w.range", "Min. W Range", 1165, 0, 1200, 10)
menu.combo:header('ee', "E - Settings")
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:dropdown('modeE', 'Mode E', 1, {'Cursor', 'Side', 'Safe Position'});
menu.combo:header('Another', "Misc Settings")
menu.combo:boolean("ecombo", "Use E Anti-Melee", true)
menu.combo:header('rr', "R - Settings")
menu.combo:menu('rsettings', "R Settings")
    menu.combo.rsettings:boolean("rcombo", "Use R", true)
    menu.combo.rsettings:slider("RRangeKeybind", "Maximum range to enemy to cast R while keybind is active", 2500, 300, 5000, 100)
    menu.combo.rsettings:menu("blacklist", "Blacklist!")
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy then 
            menu.combo.rsettings.blacklist:boolean(enemy.charName, "Do not use R on: " .. enemy.charName, false)
        end
    end 
    menu.combo.rsettings:boolean("aoe", "Use R AOE - Target", true)
    menu.combo.rsettings:slider("minTarget", "Min. Target AOE", 2, 1, 5, 1)
menu:menu('harass', 'Hybrid/Harass Settings')
    menu.harass:menu('qsettings', "Q Settings")
    menu.harass:keybind("autoQ", "Auto Q", nil, 'G')
        menu.harass.qsettings:boolean("qharras", "Auto Q", true)
        menu.harass.qsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)

menu:menu('lane', 'Lane Clear Settings')
        menu.lane:keybind("keyjump", "LaneClear", 'V', nil)
        menu.lane:boolean("useQ", "Use Q", true)
        menu.lane:slider("mana_mngr", "Minimum Mana %", 45, 0, 100, 5)
menu:header("no", "Misc Settings")
        menu:keybind("semir", "Semi - R", 'T', nil)
        menu:keybind("keyjump", "Flee", 'Z', nil)
        menu:menu('kill', 'KillSteal Settings')
            menu.kill:boolean("qkill", "Use Q if KillSteal", true)
            menu.kill:boolean("rkill", "Use R if KillSteal", true)
menu:menu("draws", "Drawings")
        menu.draws:boolean("qrange", "Draw Q Range", true)
        menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("wrange", "Draw W Range", false)
        menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)

local function CooldownsCD(slot)
    return math.floor((player:spellSlot(slot).cooldown) * 100) * 0.01
end 

local function IsValidTarget(object, distance) 
    return object and common.IsValidTarget(object) 
    and not object.buff[string.lower'SionPassiveZombie']
    and not object.buff[string.lower'KarthusDeathDefiedthen'] 
    and not object.buff[string.lower'KarthusDeathDefiedBuff']
    and not object.buff['fioraw'] 
    and not object.buff['sivire']
    and not object.buff['nocturneshroudofdarkness'] and (not distance or common.GetDistanceSqr(object) <= distance * distance)
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

local function DamageW(target)
    if not target then 
        return 
    end 

    if (player:spellSlot(1).level == 0) then 
        return 
    end 

    --[[
        80 / 135 / 190 / 245 / 300 (+ 60% bonus AD) (+ 70 / 75 / 80 / 85 / 90% AP)
    ]]
    local dmg = ({80, 135, 190, 245, 300})[player:spellSlot(1).level]
    local dmgAD = (common.GetBonusAD(player) * 0.6)
    local dmgAP = ({0.70, 0.75, 0.80, 0.85, 0.90})[player:spellSlot(1).level] * common.GetTotalAP(player)

    return (dmg + common.calculatePhysicalDamage(target, dmgAD) + common.calculateMagicalDamage(target, dmgAP))
end 

local function DamageR(target)
    if not target then 
        return 
    end 

    if (player:spellSlot(3).level == 0) then 
        return 
    end 
    
    local dmg = ({350, 500, 650})[player:spellSlot(3).level]
	local ad = (common.GetBonusAD(player) * 1)
	local ap = (common.GetTotalAP(player) * .9)

	return (dmg + common.calculatePhysicalDamage(target, ad) + common.calculateMagicalDamage(target, ap))
end 

local function InAARange(point, target)
    if (orb.combat.is_active()) then
        local targetpos = vec3(target.x, target.y, target.z)
        return common.GetDistance(point, targetpos) < common.GetAARange()
    else 
        return #common.CountEnemiesInRange(point, common.GetAARange()) > 0
    end
end
--
local function CirclePoints(CircleLineSegmentN, radius, position)
    local points = {}
    for i = 1, CircleLineSegmentN, 1 do
        local angle = i * 2 * math.pi / CircleLineSegmentN
        local point = vec3(position.x + radius * math.cos(angle), position.y + radius * math.sin(angle), position.z);
        table.insert(points, point)
    end 
    return points 
end
--
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
--
local function CastDash(asap, target)
    asap = asap and asap or false
    local DashMode =  menu.combo.modeE:get()
    local bestpoint = vec3(0, 0, 0)
    local myHeroPos = vec3(player.x, player.y, player.z)

    if DashMode == 1 then
    	bestpoint = game.mousePos
    end

    if DashMode == 2 then
    	--if (orb.combat.is_active()) then
		    local startpos = vec3(player.x, player.y, player.z)
		    local endpos = vec3(target.x, target.y, target.z)
		    local dir = (endpos - startpos):norm()
		    local pDir = dir:perp1()
		    local rightEndPos = endpos + pDir * common.GetDistance(target)
		    local leftEndPos = endpos - pDir * common.GetDistance(target)
		    local rEndPos = vec3(rightEndPos.x, rightEndPos.y, player.z)
		    local lEndPos = vec3(leftEndPos.x, leftEndPos.y, player.z);
		    if common.GetDistance(game.mousePos, rEndPos) < common.GetDistance(game.mousePos, lEndPos) then
                bestpoint = myHeroPos + (rEndPos - myHeroPos):norm()  * 475
		    else
		        bestpoint = myHeroPos + (lEndPos - myHeroPos):norm()  * 475
		    end
   		--end
  	end

    if DashMode == 3 then
	    local points = CirclePoints(15, 475, myHeroPos)
        bestpoint = myHeroPos + (game.mousePos - myHeroPos):norm()  * 475
        
	    local enemies = #common.CountEnemiesInRange(bestpoint, 350)

	    for i, point in pairs(points) do
		    local count = #common.CountEnemiesInRange(point, 350)
		    if not InAARange(point, target) then
			  	if common.IsUnderAllyTurret(point) then
			        bestpoint = point;
			        enemies = count - 1;
			    elseif count < enemies then
			        enemies = count;
			        bestpoint = point;
			    elseif count == enemies and common.GetDistance(game.mousePos, point) < common.GetDistance(game.mousePos, bestpoint) then
			        enemies = count;
			        bestpoint = point;
			  	end
		    end
		end
  	end

  	if bestpoint == vec3(0, 0, 0) then
    	return vec3(0, 0, 0)
  	end

  	local isGoodPos = IsGoodPosition(bestpoint)

  	if asap and isGoodPos then
    	return bestpoint
  	elseif isGoodPos and InAARange(bestpoint, target) then
    	return bestpoint
  	end
  	return vec3(0, 0, 0)
end

local function CastQ(target)
    if not target then 
        return 
    end 

    if common.GetDistance(target, player) > menu.combo['q.range']:get() then 
        return 
    end 

    local predq = pred.linear.get_prediction(q_pred_input, target)
    if predq and predq.startPos:dist(predq.endPos) < menu.combo['q.range']:get() then
        local collision = pred.collision.get_prediction(q_pred_input, predq, target) 

        if collision then 
            return
        end

        if player:spellSlot(0).state == 0 and not orb.core.is_spell_locked() then
            local CastPosition = VPred.GetBestCastPosition(target, 0.25, 60, q_pred_input.range, q_pred_input.speed, player, true, "line")

            if CastPosition and common.GetDistance(CastPosition) < menu.combo['q.range']:get() then 
                local castPos = mathf.project(player.pos, target.pos, CastPosition, q_pred_input.speed, target.moveSpeed)
                if castPos then 
                    player:castSpell('pos', 0, castPos)
                end
            end
        end
    end
end 

local function CastW(target)
    if not target then 
        return 
    end 

    if common.GetDistance(target, player) > menu.combo['w.range']:get() then 
        return 
    end 

    local predW = pred.linear.get_prediction(w_pred_input, target)
    if predW and predW.startPos:dist(predW.endPos) < menu.combo['w.range']:get() then
        local collision = pred.collision.get_prediction(w_pred_input, predW, target) 

        if collision then 
            return
        end

        if player:spellSlot(1).state == 0 and not orb.core.is_spell_locked() then
            local CastPosition = VPred.GetBestCastPosition(target, 0.25, 160, w_pred_input.range, w_pred_input.speed, player, false, "line")

            if CastPosition and common.GetDistance(CastPosition) < menu.combo['w.range']:get() then 
                local castPos = mathf.project(player.pos, target.pos, CastPosition, w_pred_input.speed, target.moveSpeed)
                if castPos then 
                    player:castSpell('pos', 1, castPos)
                    orb.core.reset()
                end
            end
        end
    end
end 

local function combo()
    --target 
    local target = targetSelector.get_result(function(res, obj, dist)
        if not obj then 
            return 
        end 

        if dist > 1200 then 
            return 
        end 

        local objBuff = common.getBuffValid(obj, "ezrealwattach")
        if obj and IsValidTarget(obj, 1250) and (objBuff or not objBuff) then 
            res.obj = obj 
            return true 
        end 

    end).obj

    if target and target ~= nil then 
        common.assert(target, "TARGET NIL")

        local res = { }
        res.endTimer = 0 

        if common.getBuffValid(target, "ezrealwattach") then 
            res.endTimer = (math.floor((target.buff['ezrealwattach'].endTime) * 100) * 0.01)
        else 
            res.endTimer = 0 
        end 

        --ezrealwattach
        local DistanceTo = target.path.serverPos:distSqr(player.path.serverPos) 
        local TargetBuff = common.getBuffValid(target, "ezrealwattach")
        local buffEndTime = common.getBuffEndTime(target, "ezrealwattach")

        --AA Range 
        if player.pos:dist(target.pos) <= common.GetAARange(target) then 
            local colli = VPred.CheckMinionCollision(target, target.pos, 0.25, 60, 1350, 2000, player)
            if (TargetBuff and TargetBuff ~= nil) and (player:spellSlot(0).state == 0 or CooldownsCD(0) < 2 or (TargetBuff and TargetBuff ~= nil and CooldownsCD(0) > buffEndTime)) and MissileTrue and (menu.combo['w.coll']:get() or not colli) then 
                orb.core.set_pause_attack(math.huge)
            else  
                orb.core.set_pause_attack(0)
            end
        end 

        --WQ
        local colli = VPred.CheckMinionCollision(target, target.pos, 0.25, 60, 1350, 2000, player)
        if (player:spellSlot(0).state == 0 or CooldownsCD(0) < 3 or (player:spellSlot(0).state ~= 0 and player.pos:dist(target.pos) > common.GetAARange(target) + 100)) and (menu.combo['w.coll']:get() or not colli) then 
            if menu.combo['wcombo']:get() then 
                CastW(target)
            end
        end 

        if ((TargetBuff and TargetBuff ~= nil) or (player.levelRef == 1 and player:spellSlot(0).level > 0) or (CooldownsCD(1) > 3)) then 
            if (not menu.combo["w.mark"]:get() or (TargetBuff and TargetBuff ~= nil)) then
                if menu.combo['qcombo']:get() then  
                    CastQ(target)
                end
            end
        end 

        if menu.combo['ecombo']:get() and player:spellSlot(2).state == 0 then
            local target = common.GetTarget(1000)
            local myHeroPos = vec3(player.x, player.y, player.z)
            if target and common.IsValidTarget(target) and (target.pos:dist(player.pos) <= 475 + common.GetAARange(player)) and common.GetDistance(vec3(target.x, target.y, target.z), game.mousePos) + 300 < common.GetDistance(target) and common.GetDistance(vec3(target.x, target.y, target.z)) > common.GetAARange(player) and (game.time - OverKill) > 0.3 then
                local dashPosition = vec3(player.x, player.y, player.z) + (game.mousePos - myHeroPos):norm() * 475
                if #common.CountEnemiesInRange(target.pos, 900) < 3 then
                    local dmgCombo = 0
                    if target.pos:dist(player.pos) <= 950 then
                        if common.getBuffValid(target, "ezrealwattach") then 
                            dmgCombo = common.CalculateAADamage(target) + damage.GetSpellDamage(2, target) + DamageW(target)
                        else
                            dmgCombo = common.CalculateAADamage(target) + damage.GetSpellDamage(2, target)
                        end 
                    end
                    if player:spellSlot(0).state == 0 then
                        if common.getBuffValid(target, "ezrealwattach") then 
                            dmgCombo = q_pred_input.damage(target) + DamageW(target)
                        else 
                            dmgCombo =  q_pred_input.damage(target)
                        end
                    end
                    if dmgCombo > target.health and common.IsEnemyMortal(target) then
                        player:castSpell("pos", 2, target.pos)
                        OverKill = game.time
                    end
                end
            end
            if target and common.IsValidTarget(target) then
                if target.pos:dist(player.pos) <= 1000 and common.IsValidTarget(target)  then 
                    if common.GetDistance(vec3(target.x, target.y, target.z)) < 250 then
                        local dashPos = CastDash(true, target)
                        if dashPos ~= vec3(0, 0, 0) then
                            player:castSpell("pos", 2, dashPos)
                        end
                    end
                end
            end
        end
    end 

    local canClientHero = common.GetTarget(menu.combo.rsettings['RRangeKeybind']:get())

    if canClientHero and IsValidTarget(canClientHero) then 
        common.assert(target, "TARGET NIL")
        if menu.combo.rsettings['blacklist'][canClientHero.charName] and menu.combo.rsettings['blacklist'][canClientHero.charName]:get() then 
            return 
        end 

        if not menu.combo.rsettings['rcombo']:get() then 
            return 
        end 

        local realDamage = 0
    
        if player:spellSlot(3).state == 0 and #common.CountEnemiesInRange(player.pos, 1150) < 1 then 

            if common.getBuffValid(canClientHero, "ezrealwattach") then 
                realDamage = DamageR(canClientHero) + DamageW(canClientHero)
            else  
                realDamage = DamageR(canClientHero) 
            end 

            
            if common.GetDistance(canClientHero, player) <= menu.combo.rsettings['RRangeKeybind']:get() then 

                if (player:spellSlot(0).state == 0 and common.GetDistance(canClientHero, player) < menu.combo['q.range']:get() and common.GetShieldedHealth("ALL", canClientHero) < q_pred_input.damage(canClientHero)) then
                    return 
                end

                if (common.GetShieldedHealth("ALL", canClientHero) < realDamage) then
                    local CastPosition = VPred.GetBestCastPosition(canClientHero, 1, 320, menu.combo.rsettings['RRangeKeybind']:get(), r_pred_input.speed, player, false, "line")

                    if CastPosition and common.GetDistance(CastPosition) < menu.combo.rsettings['RRangeKeybind']:get() then 
                        local castPos = mathf.project(player.pos, canClientHero.pos, CastPosition, r_pred_input.speed, canClientHero.moveSpeed)
                        if castPos then 
                            player:castSpell('pos', 3, castPos)
                        end
                    end
                end 
            end 
        end

        if menu.combo.rsettings['aoe']:get() and #common.CountEnemiesInRange(player.pos, 900) < 1 and player:spellSlot(3).state == 0 then  
            common.assert(target, "TARGET NIL")
            local castPostionAOE, MaxHit = VPred.GetLineAOECastPosition(canClientHero, 1, 320, menu.combo.rsettings['RRangeKeybind']:get(), r_pred_input.speed, player)
            if castPostionAOE and MaxHit >= menu.combo.rsettings['minTarget']:get() + 1 then  
                player:castSpell('pos', 3, castPostionAOE)
            end
        end
    end 
end 

local function lane_clear()
    local minion = MinionsAndMonsters(player.pos, 1300)
    for i, MinionsMonster in pairs(minion) do
        
        if not MinionsMonster then 
            return     
        end  

        if menu.lane['mana_mngr']:get() > common.GetPercentMana(player) then
            return 
        end

        if MinionsMonster.pos:distSqr(player.pos) <= common.GetAARange(MinionsMonster) ^ 2  and not orb.core.can_attack() then
            local delay = MinionsMonster.pos:distSqr(player.pos) + q_pred_input.delay
            if (q_pred_input.damage(MinionsMonster) >= orb.farm.predict_hp(MinionsMonster, 0.25) - 150) and player:spellSlot(0).state == 0 then
                orb.core.set_pause_attack(1)
            end
            if (q_pred_input.damage(MinionsMonster) >= orb.farm.predict_hp(MinionsMonster, 0.25)) then
                local predq = pred.linear.get_prediction(q_pred_input, MinionsMonster)
                if predq and predq.startPos:dist(predq.endPos) < menu.combo['q.range']:get() then
                    local collision = pred.collision.get_prediction(q_pred_input, predq, MinionsMonster) 
            
                    if collision then 
                        return
                    end
                    if player:spellSlot(0).state == 0 and menu.lane['useQ']:get() then 
                        player:castSpell("pos", 0, vec3(predq.endPos.x, mousePos.y, predq.endPos.y))
                    end
                end 
            end
        else 
            if MinionsMonster.pos:distSqr(player.pos) <= 1150 ^ 2 then 
                local delay = MinionsMonster.pos:distSqr(player.pos) + q_pred_input.delay
                if (q_pred_input.damage(MinionsMonster) >= orb.farm.predict_hp(MinionsMonster, 0.25)) then
                    local predq = pred.linear.get_prediction(q_pred_input, MinionsMonster)
                    if predq and predq.startPos:dist(predq.endPos) < menu.combo['q.range']:get() then
                        local collision = pred.collision.get_prediction(q_pred_input, predq, MinionsMonster) 
                
                        if collision then 
                            return
                        end
                        if player:spellSlot(0).state == 0 and menu.lane['useQ']:get() then 
                            player:castSpell("pos", 0, vec3(predq.endPos.x, mousePos.y, predq.endPos.y))
                        end
                    end 
                end
            end 
        end 
    end 
end

local function harass()
    if menu.harass.qsettings.qharras:get() and common.GetPercentMana(player) >= menu.harass.qsettings.mana_mngr:get() then 
        local res = common.GetTarget(1150)

        if res and IsValidTarget(res) then
            CastQ(res)
        end
    end 
end

local function SemiR()
    local canClientHero = common.GetTarget(menu.combo.rsettings['RRangeKeybind']:get())

    if canClientHero and IsValidTarget(canClientHero) then 
        common.assert(target, "canClientHero NIL")
        local castPostionAOE, MaxHit = VPred.GetLineAOECastPosition(canClientHero, 1, 320, menu.combo.rsettings['RRangeKeybind']:get(), r_pred_input.speed, player)
        if castPostionAOE and MaxHit >= 1 then  
            player:castSpell('pos', 3, castPostionAOE)
        end
    end
end 

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and IsValidTarget(target) and common.IsEnemyMortal(target) then 

            if menu.kill['qkill']:get() and player:spellSlot(0).state == 0 then 

                local realDamage = 0 
                if common.getBuffValid(target, "ezrealwattach") then 
                    realDamage = q_pred_input.damage(target) + DamageW(target)
                else 
                    realDamage = q_pred_input.damage(target)
                end 
        
                if common.GetShieldedHealth("ALL", target) < realDamage then 
                    CastQ(target)
                end 

            end 

            if menu.kill['rkill']:get() and player:spellSlot(3).state == 0 and #common.CountEnemiesInRange(player.pos, 900) < 1 then 

                local realDamage = 0 
                if common.getBuffValid(target, "ezrealwattach") then 
                    realDamage = DamageR(target) + DamageW(target)
                else  
                    realDamage = DamageR(target) 
                end 
    
                
                if common.GetDistance(target, player) <= menu.combo.rsettings['RRangeKeybind']:get() then 
    
                    if (player:spellSlot(0).state == 0 and common.GetDistance(target, player) < menu.combo['q.range']:get() and common.GetShieldedHealth("ALL", target) < q_pred_input.damage(target)) then
                        return 
                    end
    
                    if (common.GetShieldedHealth("ALL", target) < realDamage) then
                        local CastPosition = VPred.GetBestCastPosition(target, 1, 320, menu.combo.rsettings['RRangeKeybind']:get(), r_pred_input.speed, player, false, "line")
    
                        if CastPosition and common.GetDistance(CastPosition) < menu.combo.rsettings['RRangeKeybind']:get() then 
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

local function on_tick()
    --common.assert(target, "OnTick NIL")
    if player.isDead then 
        return 
    end 

    KillSteal()

    local enemy = common.GetEnemyHeroes()
	for i, target in ipairs(enemy) do
        if (player.buff["rocketgrab2"] or player.buff['threshq']) and player:spellSlot(2).state == 0 then
            if target and common.IsValidTarget(target) then
                local dashPos = CastDash(true, target)
                if dashPos ~= vec3(0, 0, 0) then
                    common.DelayAction(function() player:castSpell("pos", 2, dashPos) end, 0.1)
                end
            end
        end
    end

    if menu.harass.autoQ:get() and not (orb.menu.combat.key:get()) and not player.isRecalling  then
        local enemy = common.GetEnemyHeroes()
        for i, target in ipairs(enemy) do
            if target and IsValidTarget(target) then 
                CastQ(target)
            end 
        end 
    end
    --[[    local target = targetSelector.get_result(function(res, obj, dist) 
        if not obj then 
            return 
        end 

        res.obj = obj 
        return true 

    end).obj


    if target and common.isValidTarget(target) then 
        common.assert(target, "TARGET NIL")

        local realDamage = 0 
        if common.getBuffValid(target, "ezrealwattach") then 
            realDamage = q_pred_input.damage(target) + DamageW(target)
        else 
            realDamage = q_pred_input.damage(target)
        end 

        if common.GetShieldedHealth("ALL", target) < realDamage then 
            CastQ(target)
            print'here'
        end 
    end ]]

    if (orb.menu.combat.key:get()) then 
        combo()
    end

    if (orb.menu.hybrid.key:get()) then 
        harass()
    end 

    if (orb.menu.lane_clear.key:get() or orb.menu.last_hit.key:get()) then
        lane_clear()
    end 

    if (menu.keyjump:get()) then 
        player:move(game.mousePos)
    end

    if (menu.semir:get()) then 
        player:move(game.mousePos)
        SemiR()
    end
end

local function OnDrawing()
    if (player and player.isDead and not player.isTargetable and player.buff[17] ~= nil) then return end
    if (player.isOnScreen) then
        if menu.draws.qrange:get() and player:spellSlot(0).level > 0 then
            graphics.draw_circle(player.pos, menu.combo['q.range']:get(), 1, menu.draws.qcolor:get(), 30)
        end
        if menu.draws.wrange:get() and player:spellSlot(1).level > 0 then
            graphics.draw_circle(player.pos,  menu.combo['w.range']:get(), 1, menu.draws.wcolor:get(), 30)
        end
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        
        if menu.harass.autoQ:get() then
            graphics.draw_text_2D("Auto Q: ", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("ON", 17, pos.x + 25, pos.y + 50, graphics.argb(255, 51, 255, 51))
        else
            graphics.draw_text_2D("Auto Q: ", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("OFF", 17, pos.x + 25, pos.y + 50, graphics.argb(255, 255, 0, 0))
        end
    end
end 
--[[orb.combat.register_f_pre_tick(function() 
    if player.isDead then 
        return 
    end 

    --player:move(mousePos)

    local target = targetSelector.get_result(function(res, obj, dist) 
        if not obj then 
            return 
        end 

        res.obj = obj 
        return true 

    end).obj


    if target and common.isValidTarget(target) then 
        common.assert(target, "TARGET NIL")

        local res = { }
        res.endTimer = 0 

        if common.getBuffValid(target, "ezrealwattach") then 
            res.endTimer = (math.floor((target.buff['ezrealwattach'].endTime) * 100) * 0.01)
        else 
            res.endTimer = 0 
        end 

        --ezrealwattach
        local DistanceTo = target.path.serverPos:distSqr(player.path.serverPos) 
        local TargetBuff = common.getBuffValid(target, "ezrealwattach")
        local buffEndTime = common.getBuffEndTime(target, "ezrealwattach")

        --AA Range 
        if player.pos:dist(target.pos) <= common.GetAARange(target) then 
            local colli = VPred.CheckMinionCollision(target, target.pos, 0.25, 60, 1350, 2000, player)
            if (TargetBuff and TargetBuff ~= nil) and (player:spellSlot(0).state == 0 or CooldownsCD(0) < 2 or colli) and MissileTrue then 
                orb.core.set_pause_attack(res.endTimer)
            else  
                orb.core.set_pause_attack(0)
            end
        end 

        --WQ
        if player:spellSlot(0).state == 0 or CooldownsCD(0) < 3 then 
            CastW(target)
        end 

        if ((TargetBuff and TargetBuff ~= nil) or (player.levelRef == 1 and player:spellSlot(0).level > 0) or (CooldownsCD(1) > 3)) then 
            if (not menu.combo["w.mark"]:get() or (TargetBuff and TargetBuff ~= nil)) then 
                CastQ(target)
            end
        end 
    end 
end)]]


local function on_create_missile(obj)
    if obj and obj.name == "EzrealW" then 
        MissileTrue = true
    end
end

local function on_delete_missile(obj)
    if obj then 
        MissileTrue = false
    end 
end

cb.add(cb.create_missile, on_create_missile)
cb.add(cb.delete_missile, on_delete_missile)

--[[

local IsPreAttack = false
local OverKill = 0
local LastQTick = 0

local Samaritan = {}

function Samaritan.Project(sourcePosition, unitPosition, unitDestination, spellSpeed, unitSpeed)
    local toUnit = unitPosition - sourcePosition
    local toDestination = unitDestination - unitPosition
    local angle = mathf.angle_between(sourcePosition, unitPosition, unitDestination)

    local cos = toUnit:norm():dot(toDestination:norm())
    local sin = math.abs(toUnit:norm():cross(toDestination:norm()))

    local unitVelocity = toDestination:norm() * unitSpeed
    local relativeUnitVelocity = toDestination:norm() * unitSpeed * cos

    local magicalFormula = (math.pi * 0.5) - sin

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

local menu = menu("IntnnerEzreal", "Marksman - Ezreal")
--menu:dropdown('use', 'TargetSelector', 2, { 'Marked', 'Always', 'Never' })
menu:menu('combo', 'Combo Settings')
menu.combo:menu('qsettings', "Q Settings")
    menu.combo.qsettings:boolean("qcombo", "Use Q", true)
    --menu.combo.qsettings:boolean("qmob", "Use Q if enemy is mobilized", true)
    menu.combo.qsettings:slider("mana_mngr", "Minimum Mana %", 15, 0, 100, 5)
menu.combo:menu('wsettings', "W Settings")
    menu.combo.wsettings:boolean("wcombo", "Use W", true)
    menu.combo.wsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
menu.combo:menu('esettings', "E Settings")
    menu.combo.esettings:boolean("ecombo", "Use E", true)
    menu.combo.esettings:slider("mana_mngr", "Minimum Mana %", 0, 0, 100, 5)
    menu.combo.esettings:dropdown('modeE', 'Mode E', 1, {'Cursor', 'Side', 'Safe Position'});
    menu.combo.esettings:header('Another', "Misc Settings")
    menu.combo.esettings:boolean("ecombo", "Use E Anti-Melee", true)
menu.combo:menu('rsettings', "R Settings")
    menu.combo.rsettings:boolean("rcombo", "Use R", true)
    menu.combo.rsettings:slider("RRangeKeybind", "Maximum range to enemy to cast R while keybind is active", 1100, 300, 5000, 100)
    menu.combo.rsettings:menu("blacklist", "Blacklist!")
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy then 
            menu.combo.rsettings.blacklist:boolean(enemy.charName, "Do not use R on: " .. enemy.charName, false)
        end
    end 
menu:menu('harass', 'Hybrid/Harass Settings')
    menu.harass:menu('qsettings', "Q Settings")
    menu.harass:keybind("autoQ", "Auto Q", nil, 'G')
        menu.harass.qsettings:boolean("qharras", "Auto Q", true)
        menu.harass.qsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)

menu:menu('lane', 'Lane Clear Settings')
        menu.lane:keybind("keyjump", "LaneClear", 'V', nil)
        menu.lane:boolean("useQ", "Use Q", true)
        menu.lane:slider("mana_mngr", "Minimum Mana %", 45, 0, 100, 5)
menu:header("no", "Misc Settings")
        menu:keybind("semir", "Semi - R", 'T', nil)
        menu:keybind("keyjump", "Flee", 'Z', nil)
        menu:menu('kill', 'KillSteal Settings')
            menu.kill:boolean("qkill", "Use Q if KillSteal", true)
            menu.kill:boolean("rkill", "Use R if KillSteal", true)
menu:menu("draws", "Drawings")
        menu.draws:boolean("qrange", "Draw Q Range", true)
        menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("wrange", "Draw W Range", false)
        menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)


local q_pred_input = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    type = 'linear',
    delay = 0.25,
    speed = 2000,
    width = 60,
    range = 1200,
    collision = { hero = true, minion = true, wall = true },
    damage = function(m)
        return damage.GetSpellDamage(0, m)
    end,
}

local w_pred_input = {
    delay = 0.25,
    speed = 1650,
    width = 160,
    range = 1150,
    boundingRadiusMod = 1,
    collision = {
        hero = true,
        wall = true,
        terrain = true,
    },
}

local r_pred_input = {
    delay = 1.,
    speed = 2000,
    width = 320,
    range = 2000,
    boundingRadiusMod = 1,
    collision = {
        wall = true,
    }
}

local function trace_filter(seg, obj)
    local totalDelay = (q_pred_input.delay + network.latency)

    if seg.startPos:dist(seg.endPos)
            + (totalDelay * obj.moveSpeed)
            + obj.boundingRadius > q_pred_input.range then
        return false
    end

    local collision = pred.collision.get_prediction(q_pred_input, seg, obj)
    if collision then
        return false
    end

    if pred.trace.linear.hardlock(q_pred_input, seg, obj) then
        return true
    end

    if pred.trace.linear.hardlockmove(q_pred_input, seg, obj) then
        return true
    end

    local t = obj.moveSpeed / q_pred_input.speed

    if pred.trace.newpath(obj, totalDelay, totalDelay + t) then
        return true
    end

    return true
end

local Compute = function(input, seg, obj)
    -- FOR input.speed = math.huge spells
    -- I didn't tested this yet.
    -- You can feel free to ignore this.
    if input.speed == math.huge then
        input.speed = obj.moveSpeed * 2
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

local function target_filter(res, obj, dist)
    if dist > q_pred_input.range then
        return false
    end

    local seg = pred.linear.get_prediction(q_pred_input, obj)
    if not seg then
        return false
    end

    if not trace_filter(seg, obj) then
        return false
    end

    local t1 = Compute(q_pred_input, seg, obj)

    res.seg = seg

    if t1 < 0 then
        return false
    end

    --res.pos = (pred.core.get_pos_after_time(obj, t1) + seg.endPos) / 2
    res.pos = pred.core.get_pos_after_time(obj, t1)
    res.pos2 = seg.endPos
end

local function InAARange(point, target)
    if (orb.combat.is_active()) then
        local targetpos = vec3(target.x, target.y, target.z)
        return common.GetDistance(point, targetpos) < common.GetAARange()
    else 
        return #common.CountEnemiesInRange(point, common.GetAARange()) > 0
    end
end
--
local function CirclePoints(CircleLineSegmentN, radius, position)
    local points = {}
    for i = 1, CircleLineSegmentN, 1 do
        local angle = i * 2 * math.pi / CircleLineSegmentN
        local point = vec3(position.x + radius * math.cos(angle), position.y + radius * math.sin(angle), position.z);
        table.insert(points, point)
    end 
    return points 
end
--
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
--
local function CastDash(asap, target)
    asap = asap and asap or false
    local DashMode =  menu.combo.esettings.modeE:get()
    local bestpoint = vec3(0, 0, 0)
    local myHeroPos = vec3(player.x, player.y, player.z)

    if DashMode == 1 then
    	bestpoint = game.mousePos
    end

    if DashMode == 2 then
    	--if (orb.combat.is_active()) then
		    local startpos = vec3(player.x, player.y, player.z)
		    local endpos = vec3(target.x, target.y, target.z)
		    local dir = (endpos - startpos):norm()
		    local pDir = dir:perp1()
		    local rightEndPos = endpos + pDir * common.GetDistance(target)
		    local leftEndPos = endpos - pDir * common.GetDistance(target)
		    local rEndPos = vec3(rightEndPos.x, rightEndPos.y, player.z)
		    local lEndPos = vec3(leftEndPos.x, leftEndPos.y, player.z);
		    if common.GetDistance(game.mousePos, rEndPos) < common.GetDistance(game.mousePos, lEndPos) then
                bestpoint = myHeroPos + (rEndPos - myHeroPos):norm()  * 475
		    else
		        bestpoint = myHeroPos + (lEndPos - myHeroPos):norm()  * 475
		    end
   		--end
  	end

    if DashMode == 3 then
	    local points = CirclePoints(15, 475, myHeroPos)
        bestpoint = myHeroPos + (game.mousePos - myHeroPos):norm()  * 475
        
	    local enemies = #common.CountEnemiesInRange(bestpoint, 350)

	    for i, point in pairs(points) do
		    local count = #common.CountEnemiesInRange(point, 350)
		    if not InAARange(point, target) then
			  	if common.IsUnderAllyTurret(point) then
			        bestpoint = point;
			        enemies = count - 1;
			    elseif count < enemies then
			        enemies = count;
			        bestpoint = point;
			    elseif count == enemies and common.GetDistance(game.mousePos, point) < common.GetDistance(game.mousePos, bestpoint) then
			        enemies = count;
			        bestpoint = point;
			  	end
		    end
		end
  	end

  	if bestpoint == vec3(0, 0, 0) then
    	return vec3(0, 0, 0)
  	end

  	local isGoodPos = IsGoodPosition(bestpoint)

  	if asap and isGoodPos then
    	return bestpoint
  	elseif isGoodPos and InAARange(bestpoint, target) then
    	return bestpoint
  	end
  	return vec3(0, 0, 0)
end


local function Combo()
    if menu.combo.wsettings.wcombo:get() and common.GetPercentMana(player) >= menu.combo.wsettings.mana_mngr:get() and player:spellSlot(1).state == 0 then
        local target = common.GetTarget(1150)
        if target then 
            local seg = pred.linear.get_prediction(w_pred_input, target)
            if seg and seg.startPos:dist(seg.endPos) < 1150 then
                if not pred.collision.get_prediction(w_pred_input, seg, target) and kalman.KalmanFilter(target) then
                    player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end
            end
        end 
    end
    if menu.combo.qsettings.qcombo:get() and common.GetPercentMana(player) >= menu.combo.qsettings.mana_mngr:get()  and player:spellSlot(0).state == 0 and not IsPreAttack then
        local res = TS.get_result(target_filter)

        if res.pos then
            local castPosition = vec3(res.pos.x, mousePos.y, res.pos.y)
            player:castSpell('pos', 0, castPosition)
            LastQTick = os.clock()
        end
    end

    if menu.combo.esettings.ecombo:get() and player:spellSlot(2).state == 0 then
        local target = common.GetTarget(1000)
        local myHeroPos = vec3(player.x, player.y, player.z)
        if target and common.IsValidTarget(target) and (target.pos:dist(player.pos) <= 475 + common.GetAARange(player)) and common.GetDistance(vec3(target.x, target.y, target.z), game.mousePos) + 300 < common.GetDistance(target) and common.GetDistance(vec3(target.x, target.y, target.z)) > common.GetAARange(player) and (game.time - OverKill) > 0.3 then
            local dashPosition = vec3(player.x, player.y, player.z) + (game.mousePos - myHeroPos):norm() * 475
            if #common.CountEnemiesInRange(target.pos, 900) < 3 then
                local dmgCombo = 0
                if target.pos:dist(player.pos) <= 950 then
                    dmgCombo = common.CalculateAADamage(target) + damage.GetSpellDamage(2, target)
                end
                if player:spellSlot(0).state == 0 then
                    dmgCombo =   damage.GetSpellDamage(0, target)
                end
                if dmgCombo > target.health and common.IsEnemyMortal(target) then
                    player:castSpell("pos", 2, target.pos)
                    OverKill = game.time
                end
            end
        end
        if target and common.IsValidTarget(target) then
            if target.pos:dist(player.pos) <= 1000 and common.IsValidTarget(target)  then 
                if common.GetDistance(vec3(target.x, target.y, target.z)) < 250 then
                    local dashPos = CastDash(true, target)
                    if dashPos ~= vec3(0, 0, 0) then
                        player:castSpell("pos", 2, dashPos)
                    end
                end
            end
        end
    end
end 

local function Harass()
    if menu.harass.qsettings.qharras:get() and common.GetPercentMana(player) >= menu.harass.qsettings.mana_mngr:get() then 
        local res = TS.get_result(target_filter)

        if res.pos then
            local castPosition = vec3(res.pos.x, mousePos.y, res.pos.y)
            player:castSpell('pos', 0, castPosition)
            LastQTick = os.clock()
        end
    end 
end 

local function LaneClear()
    if menu.lane.useQ:get() then 
        if orb.menu.lane_clear.key:get() then
            local seg, obj = orb.farm.skill_farm_linear(q_pred_input)
            if seg then
                player:castSpell('pos', 0, vec3(seg.endPos.x, obj.y, seg.endPos.y))
                if (q_pred_input.damage(obj) > obj.health) then
                    orb.farm.set_ignore(obj, seg.endPos:dist(player.pos2D) / q_pred_input.speed + q_pred_input.delay)
                end
            end
        elseif orb.menu.last_hit.key:get() then
            local seg, obj = orb.farm.skill_clear_linear(q_pred_input)
            if seg then
                player:castSpell('pos', 0, vec3(seg.endPos.x, obj.y, seg.endPos.y))
                orb.farm.set_ignore(obj, seg.endPos:dist(player.pos2D) / q_pred_input.speed + q_pred_input.delay)
            end
        end
    end
end 

local function AutoQ()
    local res = TS.get_result(target_filter)

    if res.pos then
        local castPosition = vec3(res.pos.x, mousePos.y, res.pos.y)
        player:castSpell('pos', 0, castPosition)
        LastQTick = os.clock()
    end
end 

local function OnTick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    IsPreAttack = false

    if menu.harass.autoQ:get() and not (orb.menu.combat.key:get()) and not player.isRecalling  then
        AutoQ();
    end

    LaneClear()

    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    elseif menu.keyjump:get() then 
        player:move(mousePos)
    end


    local enemy = common.GetEnemyHeroes()
	for i, target in ipairs(enemy) do
        if target and common.IsValidTarget(target) then
            local seg = pred.linear.get_prediction(w_pred_input, target)
            if seg and seg.startPos:dist(seg.endPos) < 1150 then
                if not pred.collision.get_prediction(w_pred_input, seg, target)  then 
                    local castPosition = mathf.project(player.pos, target.pos, vec3(seg.endPos.x, target.y, seg.endPos.y), q_pred_input.speed, target.moveSpeed)
                    if castPosition then 
                        player:castSpell("pos", 0, castPosition)
                        print'here'
                    end
                end
            end
        end 
    end

    local enemy = common.GetEnemyHeroes()
	for i, target in ipairs(enemy) do
        if player.buff["rocketgrab2"] and player:spellSlot(2).state == 0 then
            if target and common.IsValidTarget(target) then
                local dashPos = e.CastDash(true, target.pos)
                if dashPos ~= vec3(0, 0, 0) then
                    common.DelayAction(function() player:castSpell("pos", 2, dashPos) end, 0.1)
                end
            end
        end
    end

    if player:spellSlot(3).state == 0 and menu.kill.rkill:get() then 
        for i = 0, objManager.enemies_n - 1 do
            local unit = objManager.enemies[i]
            if unit and common.IsValidTarget(unit) and common.IsEnemyMortal(unit) and os.clock() - LastQTick > 1.9 then 
                if player:spellSlot(0).state == 0 and unit.pos:dist(player) <= 1150 and damage.GetSpellDamage(0, unit) > common.GetShieldedHealth("AD", unit) then 
                    return 
                end 
                if damage.GetSpellDamage(3, unit) > common.GetShieldedHealth("ALL", unit) and common.IsInRange(menu.combo.rsettings.RRangeKeybind:get(), player, unit) then
                    if (#common.CountEnemiesInRange(player.pos, 800) == 0) then 
                        local seg = pred.linear.get_prediction(r_pred_input, unit)
                        if seg and seg.startPos:dist(seg.endPos) < r_pred_input.range then
                            if not pred.collision.get_prediction(r_pred_input, seg, unit) then
                                local castPosition = mathf.project(player.pos, unit.pos, vec3(seg.endPos.x, unit.y, seg.endPos.y), r_pred_input.speed, unit.moveSpeed)
                                if castPosition then 
                                    player:castSpell("pos", 3, castPosition)
                                end
                            end 
                        end
                    end 
                end
            end
        end
    end

    if menu.semir:get() and player:spellSlot(3).state == 0 then 
        for i = 0, objManager.enemies_n - 1 do
            local unit = objManager.enemies[i]
            if unit and common.IsValidTarget(unit) and common.IsEnemyMortal(unit) then 
                if common.IsInRange(menu.combo.rsettings.RRangeKeybind:get(), player, unit) then
                    if (#common.CountEnemiesInRange(player.pos, 800) == 0) then 
                        local seg = pred.linear.get_prediction(r_pred_input, unit)
                        if seg and seg.startPos:dist(seg.endPos) < r_pred_input.range then
                            if not pred.collision.get_prediction(r_pred_input, seg, unit) then
                                player:castSpell("pos", 3, vec3(seg.endPos.x, unit.y, seg.endPos.y))
                            end 
                        end
                    end 
                end
            end
        end
    end 
end 
cb.add(cb.tick, OnTick)
local function OnDrawing()
    if (player and player.isDead and not player.isTargetable and player.buff[17] ~= nil) then return end
    if (player.isOnScreen) then
        if menu.draws.qrange:get() and player:spellSlot(0).level > 0 then
            graphics.draw_circle(player.pos, 1150, 1, menu.draws.qcolor:get(), 100)
        end
        if menu.draws.wrange:get() and player:spellSlot(1).level > 0 then
            graphics.draw_circle(player.pos, 1150, 1, menu.draws.wcolor:get(), 100)
        end
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        
        if menu.harass.autoQ:get() then
            graphics.draw_text_2D("Auto Q: ", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("ON", 17, pos.x + 25, pos.y + 50, graphics.argb(255, 51, 255, 51))
        else
            graphics.draw_text_2D("Auto Q: ", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("OFF", 17, pos.x + 25, pos.y + 50, graphics.argb(255, 255, 0, 0))
        end
    end
end 
cb.add(cb.draw, OnDrawing)

local function OnPreAttack()
    IsPreAttack = true 
end
orb.combat.register_f_pre_tick(OnPreAttack)]]
orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.draw, OnDrawing)