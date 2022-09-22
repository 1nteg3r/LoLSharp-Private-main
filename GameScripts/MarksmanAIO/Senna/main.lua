local orb = module.internal("orb");
local pred = module.internal("pred")
local evade = module.seek('evade')
local TS = module.internal("TS")
local common = module.load(header.id, "common");
local damage = module.load(header.id, 'damageLib');

local function trace_filter(Input, seg, obj)
    local totalDelay = (Input.delay + network.latency)

    if seg.startPos:dist(seg.endPos)
            + (totalDelay * obj.moveSpeed)
            + obj.boundingRadius > Input.range then
        return false
    end

    local collision = pred.collision.get_prediction(Input, seg, obj)
    if collision then
        return false
    end

    if pred.trace.linear.hardlock(Input, seg, obj) then
        return true
    end

    if pred.trace.linear.hardlockmove(Input, seg, obj) then
        return true
    end

    local t = obj.moveSpeed / Input.speed

    if pred.trace.newpath(obj, totalDelay, totalDelay + t) then
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

        local seg = pred.linear.get_prediction(input, obj)

        if not seg then
            return false
        end

        res.seg = seg
        res.obj = obj

        if not trace_filter(input, seg, obj) then
            return false
        end

        local t1 = Compute(input, seg, obj)

        if t1 < 0 then
            return false
        end

        res.pos = (pred.core.get_pos_after_time(obj, t1) + seg.endPos) / 2

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
-- local spellQ_extend = 1300
local pred_w_input = {
    --[[
        [01:03] Spell name: SennaW
        [01:03] Speed:1000
        [01:03] Width: 60
        [01:03] Time:0.25
        [01:03] Animation: 0.25
        [01:03] false
        [01:03] CastFrame: 0.43139535188675
    ]]

    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 1000,
    width = 60,
    range = 1300,
    collision = { hero = true, minion = true, wall = true },
};

local pred_r_input = {
    --[[
        [02:35] Spell name: SennaR
        [02:35] Speed:2000
        [02:35] Width: 180
        [02:35] Time:1
        [02:35] Animation: 1
        [02:35] false
        [02:35] CastFrame: 0.43139535188675
    ]]
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 1,
    speed = 2000,
    width = 180,
    range = 250000,
    collision = { hero = false, minion = false, wall = false },
}

local IsPreAttack = false 

local menu = menu(header.id, "Marksman - Senna")
menu:header('a1', 'Core')
menu:menu('combo', 'Combo')
    menu.combo:boolean('useQ', 'Use Q', true)
    menu.combo:boolean('useQextend', ' ^ Use Q out range ', true)
    menu.combo:boolean('useW', 'Use W', true)
    menu.combo:menu('r', "R - Settings")
    menu.combo.r:boolean('useR', 'Use R', true)
    menu.combo.r:dropdown('moder', 'Use R for', 3, {'Shield + Kill', 'KillSteal', 'Whenever possible'});
    menu.combo.r:slider("NearRangeMin", "Min. Range Safe", 650, 100, 1500, 100);
    menu.combo.r:slider("NearRangeMax", "Max. Range", 5000, 100, 250000, 100);
menu:menu("harass", "Harass");
    menu.harass:boolean("q", "Use Q", true);
    menu.harass:boolean("w", "Use W", false);
    menu.harass:slider("mana", "Minimum Mana Percent", 20, 0, 100, 1);
menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useW', 'Use W for KillSteal', true)
    menu.kill:boolean('useR', 'Use R for KillSteal', true)
menu:menu('misc', "Misc")
    menu.misc:boolean("E.Gapcloser", "Use W on hero gapclosing / dashing", true);
    menu.misc:boolean("Imobile", "Use W on hero immobile", true);
    menu.misc:boolean("Shield", "Use Q Shield", true);
    menu.misc:header("DISABLE", "0 - Disabled, 1 - Good, 5 - Lowest")
    local enemy = common.GetAllyHeroes()
    for i, allies in ipairs(enemy) do
        if allies.charName ~= "Senna" then
            menu.misc:slider(allies.charName, "Priority: " .. allies.charName, 1, 0, 5, 1)
            menu.misc:slider(allies.charName .. "hp", " ^- Health Percent: ", 50, 1, 100, 1)
        end
    end
menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", false)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", true)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)

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
	local powCalc = 180
	if Distance(minion.pos, player.pos, target, true, true) <= powCalc then
		return true
	end
	return false
end

local function CountMinionInLine(target)
	local NH = 0
	local minioncollision = nil
    for i = 0, objManager.maxObjects - 1 do
		local obj = objManager.get(i)
		if obj and (obj.type == TYPE_MINION or obj.type == TYPE_HERO) and obj.ptr ~= player.ptr and common.IsValidTarget(obj) then
            if CanHitSkillShot(target, obj) then
                minioncollision = obj
            end
        end 
	end
    return minioncollision
end

local function GetSlotItem(id)
    local tab = {[3144] = "BilgewaterCutlass", [3153] = "ItemSwordOfFeastAndFamine", [3405] = "TrinketSweeperLvl1", [3411] = "TrinketOrbLvl1", [3166] = "TrinketTotemLvl1", [3450] = "OdinTrinketRevive", [2041] = "ItemCrystalFlask", [2054] = "ItemKingPoroSnack", [2138] = "ElixirOfIron", [2137] = "ElixirOfRuin", [2139] = "ElixirOfSorcery", [2140] = "ElixirOfWrath", [3184] = "OdinEntropicClaymore", [2050] = "ItemMiniWard", [3401] = "HealthBomb", [3363] = "TrinketOrbLvl3", [3092] = "ItemGlacialSpikeCast", [3460] = "AscWarp", [3361] = "TrinketTotemLvl3", [3362] = "TrinketTotemLvl4", [3159] = "HextechSweeper", [2051] = "ItemHorn", [3146] = "HextechGunblade", [3187] = "HextechSweeper", [3190] = "IronStylus", [2004] = "FlaskOfCrystalWater", [3139] = "ItemMercurial", [3222] = "ItemMorellosBane", [3180] = "OdynsVeil", [3056] = "ItemFaithShaker", [2047] = "OracleExtractSight", [3364] = "TrinketSweeperLvl3", [3140] = "QuicksilverSash", [3143] = "RanduinsOmen", [3074] = "ItemTiamatCleave", [3800] = "ItemRighteousGlory", [2045] = "ItemGhostWard", [3342] = "TrinketOrbLvl1", [3040] = "ItemSeraphsEmbrace", [3048] = "ItemSeraphsEmbrace", [2049] = "ItemGhostWard", [3345] = "OdinTrinketRevive", [2044] = "SightWard", [3341] = "TrinketSweeperLvl1", [3069] = "shurelyascrest", [3599] = "KalistaPSpellCast", [3185] = "HextechSweeper", [3077] = "ItemTiamatCleave", [2009] = "ItemMiniRegenPotion", [2010] = "ItemMiniRegenPotion", [3023] = "ItemWraithCollar", [3290] = "ItemWraithCollar", [2043] = "VisionWard", [3340] = "TrinketTotemLvl1", [3142] = "YoumusBlade", [3512] = "ItemVoidGate", [3131] = "ItemSoTD", [3137] = "ItemDervishBlade", [3352] = "RelicSpotter", [3350] = "TrinketTotemLvl2", [3085] = "AtmasImpalerDummySpell"}
	local nameID = tab[id]
	for i = 6, 12 do
        local item = player:spellSlot(i).name
		if ((#item > 0) and (item:lower() == nameID:lower())) then
			return i
		end
	end
end 

local function AutoWardItem()
    local WardSlot = nil
    
    if GetSlotItem(2045) and player:spellSlot(GetSlotItem(2045)).state == 0 then
        WardSlot = GetSlotItem(2045);
    elseif GetSlotItem(2049) and player:spellSlot(GetSlotItem(2049)).state == 0  then
        WardSlot = GetSlotItem(2049);
    elseif GetSlotItem(3340) and player:spellSlot(GetSlotItem(3340)).state == 0 or GetSlotItem(3350) and player:spellSlot(GetSlotItem(3350)).state == 0  or GetSlotItem(3361) and player:spellSlot(GetSlotItem(3361)).state == 0  or GetSlotItem(3363) and player:spellSlot(GetSlotItem(3363)).state == 0  or GetSlotItem(3411) and player:spellSlot(GetSlotItem(3411)).state == 0  or GetSlotItem(3342) and player:spellSlot(GetSlotItem(3342)).state == 0  or GetSlotItem(3362) and player:spellSlot(GetSlotItem(3362)).state == 0  then
        WardSlot = 12;
    elseif GetSlotItem(2044) and player:spellSlot(GetSlotItem(2044)).state == 0  then
        WardSlot = GetSlotItem(2044);
    elseif GetSlotItem(2043) and player:spellSlot(GetSlotItem(2043)).state == 0  then
        WardSlot = GetSlotItem(2043);
    elseif GetSlotItem(3362) and player:spellSlot(GetSlotItem(3362)).state == 0 then
        WardSlot = 12;
    elseif GetSlotItem(2043) and player:spellSlot(GetSlotItem(2043)).state == 0 then
        WardSlot = GetSlotItem(2043);
    end
    
    return WardSlot
end 

local function DamageQ(target)
    local damage = 0

    if not target then 
        return 
    end 

    if player:spellSlot(0).level == 0 then 
        return 
    end 

    if player:spellSlot(0).level > 0 then 
        damage = common.CalculatePhysicalDamage(target, ({40, 70, 100, 130, 160})[player:spellSlot(0).level] + (common.GetBonusAD() * .4))
    end
    return damage
end 

local function DamageW(target)
    local damage = 0

    if not target then 
        return 
    end 

    if player:spellSlot(1).level == 0 then 
        return 
    end 

    if player:spellSlot(1).level > 0 then 
        damage = common.CalculatePhysicalDamage(target, ({70, 115, 160, 205, 250})[player:spellSlot(1).level] + (common.GetBonusAD() * 0.70))
    end
    return damage
end 

local function DamageR(target)
    local damage = 0

    if not target then 
        return 
    end 

    if player:spellSlot(3).level == 0 then 
        return 
    end 

    if player:spellSlot(3).level > 0 then 
        damage = common.CalculatePhysicalDamage(target, ({250, 375, 500})[player:spellSlot(3).level] + (common.GetBonusAD() * 1) + (common.GetTotalAP() * .5))
    end
    return damage
end

local function GetBestCircularObject(Position, radius, range)
    local obj, count = nil, 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and common.IsValidTarget(minion) and player.pos:dist(minion) <= range then 
            if Position and Position:distSqr(minion.pos) <= radius * radius and DamageW(minion) > minion.health then
                obj = minion
            end 
        end 
    end
    return obj
end

local function Combo()
    if menu.combo.useW:get() and (player.mana >= player.manaCost0 + player.manaCost3) then 

        local target = TS.get_result(real_target_filter(pred_w_input).Result) 
        if target.obj and target.pos and common.IsValidTarget(target.obj) then 
            if player:spellSlot(1).state == 0 and not IsPreAttack then 

                if #common.CountEnemiesInRange(player.pos, 400) > 0 then 
                    return 
                end

                player:castSpell('pos', 1, vec3(target.pos.x, mousePos.y, target.pos.y))
            end 

            if player:spellSlot(1).state == 0 and common.GetDistance(target.obj) > 650 then 
                if #common.CountEnemiesInRange(player.pos, 400) > 0 then 
                    return 
                end

                local Minion = GetBestCircularObject(target.obj.pos, 150, 1300)
                if Minion then 
                    player:castSpell('pos', 1, Minion.pos)
                end
            end
        end 
    end  

    if menu.combo.useQ:get() and (player.mana >= player.manaCost1 + player.manaCost3) then 
        local target = common.GetTarget(1350)

        if target and target ~= nil and common.IsValidTarget(target) then 
            if target.pos:dist(player.pos) <= 650 and not IsPreAttack then  
                player:castSpell("obj", 0, target)
            elseif target.pos:dist(player.pos) > 650 and common.GetDistance(target) <= 1350 then
                if menu.combo.useQextend:get() and not IsPreAttack then 
                    local pred_pos = pred.core.lerp(target.path, network.latency + 0.34, target.moveSpeed)

                    if not pred_pos then 
                        return 
                    end 
            
                    local targetVector = vec3(pred_pos.x, target.y, pred_pos.y)
                    local minion = CountMinionInLine(targetVector)
                    if minion and minion.pos:dist(player.pos) <= 650 then
                        player:castSpell("obj", 0, minion)
                    end
                end 
            end 
        end 
    end 

    if menu.combo.r.useR:get() and player:spellSlot(3).state == 0 then 

        local target = TS.get_result(real_target_filter(pred_r_input).Result) 
        if target.obj and target.pos and common.IsValidTarget(target.obj) then 
            if menu.combo.r.moder:get() == 1 then 
                for i=0, objManager.allies_n-1 do
                    local obj = objManager.allies[i]
                    if obj and common.IsValidTarget(obj) then 
                        if #common.CountAllysInRange(target.obj.pos, 700) > 0 and common.GetPercentHealth(obj) < common.GetPercentHealth(target.obj) and not DamageR(target.obj) > common.GetShieldedHealth("ALL", target.obj) then  
                            if #common.CountEnemiesInRange(player.pos, menu.combo.r.NearRangeMin:get()) > 0 then 
                                return 
                            end
                            player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                        elseif  #common.CountAllysInRange(target.obj.pos, 700) > 0 and common.GetPercentHealth(obj) > common.GetPercentHealth(target.obj) and DamageR(target.obj) > common.GetShieldedHealth("ALL", target.obj) then  
                            if #common.CountEnemiesInRange(player.pos, menu.combo.r.NearRangeMin:get()) > 0 then
                                return 
                            end
                            player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                        end
                    end 
                end
            elseif menu.combo.r.moder:get() == 2 then 
                if DamageR(target.obj) > common.GetShieldedHealth("ALL", target.obj) then 
                    if #common.CountEnemiesInRange(player.pos, menu.combo.r.NearRangeMin:get()) > 0 then 
                        return 
                    end
                    player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                end
            elseif menu.combo.r.moder:get() == 3 then 
                for i=0, objManager.allies_n-1 do
                    local obj = objManager.allies[i]
                    if obj and common.IsValidTarget(obj) then 
                        if #common.CountAllysInRange(target.obj.pos, 700) > 0 and common.GetPercentHealth(obj) < common.GetPercentHealth(target.obj) and not DamageR(target.obj) > common.GetShieldedHealth("ALL", target.obj) then  
                            if #common.CountEnemiesInRange(player.pos, menu.combo.r.NearRangeMin:get()) > 0 then 
                                return 
                            end
                            player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                        elseif  #common.CountAllysInRange(target.obj.pos, 700) > 0 and common.GetPercentHealth(obj) > common.GetPercentHealth(target.obj) and DamageR(target.obj) > common.GetShieldedHealth("ALL", target.obj) then  
                            if #common.CountEnemiesInRange(player.pos, menu.combo.r.NearRangeMin:get()) > 0 then
                                return 
                            end
                            player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                        end
                    end 
                end
            end
        end
    end 
end 

local function Harass()
    if common.GetPercentMana(player) > menu.harass.mana:get() then 
        if menu.harass.w:get() then 
            local target = TS.get_result(real_target_filter(pred_w_input).Result) 
            if target.obj and target.pos and common.IsValidTarget(target.obj) then 
                if player:spellSlot(1).state == 0 and not IsPreAttack then 
    
                    if #common.CountEnemiesInRange(player.pos, 400) > 0 then 
                        return 
                    end
    
                    player:castSpell('pos', 1, vec3(target.pos.x, mousePos.y, target.pos.y))
                end 
    
                if player:spellSlot(1).state == 0 and common.GetDistance(target.obj) > 650 then 
                    if #common.CountEnemiesInRange(player.pos, 400) > 0 then 
                        return 
                    end
    
                    local Minion = GetBestCircularObject(target.obj.pos, 150, 1300)
                    if Minion then 
                        player:castSpell('pos', 1, Minion.pos)
                    end
                end
            end 
        end 
        
        if menu.harass.q:get() then 

            local target = common.GetTarget(1350)

            if target and target ~= nil and common.IsValidTarget(target) then 
                if target.pos:dist(player.pos) <= 650 and not IsPreAttack then  
                    player:castSpell("obj", 0, target)
                elseif target.pos:dist(player.pos) > 650 and common.GetDistance(target) <= 1350 then
                    if menu.combo.useQextend:get() and not IsPreAttack then 
                        local pred_pos = pred.core.lerp(target.path, network.latency + 0.34, target.moveSpeed)

                        if not pred_pos then 
                            return 
                        end 
                
                        local targetVector = vec3(pred_pos.x, target.y, pred_pos.y)
                        local minion = CountMinionInLine(targetVector)
                        if minion and minion.pos:dist(player.pos) <= 650 then
                            player:castSpell("obj", 0, minion)
                        end
                    end 
                end 
            end 
        end

    end 
end 

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and common.IsValidTarget(target) and common.IsEnemyMortal(target) and DamageQ(target) > common.GetShieldedHealth("AD", target) and player:spellSlot(0).state == 0 then
            local WardPos = AutoWardItem()
            if target.pos:dist(player.pos) > 650 and WardPos then 
                local castPos = player.pos + (target.pos - player.pos):norm() * 625 
                player:castSpell('pos', WardPos, castPos)
            end 
            if target.pos:dist(player.pos) <= 650 and not IsPreAttack then  
                player:castSpell("obj", 0, target)
            elseif target.pos:dist(player.pos) > 650 and common.GetDistance(target) <= 1350 then
                if menu.combo.useQextend:get() and not IsPreAttack then 
                    local pred_pos = pred.core.lerp(target.path, network.latency + 0.34, target.moveSpeed)

                    if not pred_pos then 
                        return 
                    end 
            
                    local targetVector = vec3(pred_pos.x, target.y, pred_pos.y)
                    local minion = CountMinionInLine(targetVector)
                    if minion and minion.pos:dist(player.pos) <= 650 then
                        player:castSpell("obj", 0, minion)
                    end
                end 
            end 
        end
    end 

    if menu.kill.useR:get() then 
        local target = TS.get_result(real_target_filter(pred_r_input).Result) 
        if target.obj and target.pos and common.IsValidTarget(target.obj) and common.IsEnemyMortal(target.obj) then 
            if player:spellSlot(3).state == 0 and DamageR(target.obj) > common.GetShieldedHealth("ALL", target.obj) then 
                player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
            end
        end
    end

    if menu.kill.useW:get() then 
        local target = TS.get_result(real_target_filter(pred_w_input).Result) 
        if target.obj and target.pos and common.IsValidTarget(target.obj) then  
            if player:spellSlot(1).state == 0 and not IsPreAttack and DamageW(target.obj) > common.GetShieldedHealth("AD", target.obj) then 

                if #common.CountEnemiesInRange(player.pos, 400) > 0 then 
                    return 
                end

                player:castSpell('pos', 1, vec3(target.pos.x, mousePos.y, target.pos.y))
            end 
        end
    end
end

local function OnTick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end 

    IsPreAttack = false


    KillSteal()

    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    end
    --[[local target = common.GetTarget(1700)

    if target and common.IsValidTarget(target) then 
        local pred_pos = pred.core.lerp(target.path, network.latency + 0.34, target.moveSpeed)

        if not pred_pos then 
            return 
        end 

        local targetVector = vec3(pred_pos.x, target.y, pred_pos.y)
        if common.GetDistance(target) > 300 and common.GetDistance(target) <= 1600 then
            local minion = CountMinionInLine(targetVector)
            if minion and minion.pos:dist(player.pos) <= 650 then
                player:castSpell("obj", 0, minion)
            end
        end
    end]]
end 
cb.add(cb.tick, OnTick)

local function OnPreTick()
    if (player.isDead) then return end 

    IsPreAttack = true
end 
cb.add(cb.pre_tick, OnPreTick)

local function ondraw()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 1300, 1, menu.draws.qcolor:get(), 100)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 1300, 1, menu.draws.wcolor:get(), 100)
        end
    end 
end
cb.add(cb.draw, ondraw)
