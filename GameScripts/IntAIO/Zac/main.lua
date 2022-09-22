local orb = module.internal("orb");
local evade = module.seek('evade');
local TargetPred = module.internal("TS")
local pred = module.internal("pred")
local common = module.load(header.id, "Library/common");
local TS = module.load(header.id, "TargetSelector/targetSelector")
local damage = module.load(header.id, 'Library/damageLib');

local IsPreAttack = false

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


local Q = {
    pred_input = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        delay = 0.25,
        speed = 2800,
        width = 160,
        range = 951,
        collision = { hero = true, minion = true, wall = true },
    };
}

local E = {
    LastCastTime = 0;
    Range = 0;
    CastRangeGrowthMin = 150;
    CastRangeGrowthMax = ({1200, 1350, 1500, 1650, 1800})[player:spellSlot(2).level];
    CastRangeGrowthStartTime = 0;
    CastRangeGrowthDuration =  ({0.9, 1, 1.1, 1.2, 1.3})[player:spellSlot(2).level];
    CastRangeGrowthEndTime = 4.5;

    EConeStart = vec3(0,0,0);
    EConeEnd = vec3(0,0,0);


    pred_input = {
        boundingRadiusModSource = 0,
        boundingRadiusMod = 0,
        delay = 0.5,
        speed = math.huge,
        width = 150,
        range = 1800,
        collision = { hero = false, minion = false, wall = false },
    };
}

local menu = menu("IntnnerZac", "Int - Zac")
menu:header('a1', 'Core')
TS = TS(menu, 1400)
TS:addToMenu()
menu:menu('combo', 'Combo')
    menu.combo:boolean('Q', 'Use Q', true)
    menu.combo:boolean('W', 'Use W', true)
    menu.combo:boolean('E', 'Use E', true)
    menu.combo:boolean('R', 'Use R', false)

menu:menu("harass", "Harass");
    menu.harass:boolean("q", "Use Q", true);
    menu.harass:boolean("w", "Use W", false);
    menu.harass:boolean("e", "Use E", false);
    menu.harass:slider("extrarange", "Extra range for E", 200, 1, 200, 1);
    menu.harass:slider("mana", "Minimum Health Percent", 20, 0, 100, 1);

menu:menu("jungle", "JungleClear");
    menu.jungle:boolean("q", "Use Q", true);
    menu.jungle:boolean("w", "Use W", true);
    menu.jungle:boolean("e", "Use E", true);
    menu.jungle:slider("LaneClear.ManaPercent", "Minimum Health Percent", 50, 0, 100, 1);

menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useW', 'Use W for KillSteal', true)
    menu.kill:boolean('useE', 'Use E for KillSteal', true)

menu:menu('auto', 'Automatic')
    menu.auto:boolean("E.Gapcloser", "Q2 - Pull enemy", true);

menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 105, 255)
    menu.draws:boolean("wrange", "Draw W Range", true)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 105, 255)
    menu.draws:boolean("erange", "Draw E Range", false)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 105, 255)

local function OnProcessSpell(spell)
    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Zac" then 
        --print("Spell name: " ..spell.name);
        if spell.name == "ZacE" then 
            E.LastCastTime = game.time;
            E.EConeStart = vec3(spell.startPos.x, spell.startPos.y, spell.startPos.z)
            E.EConeEnd = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)
        end
    end
end 
cb.add(cb.spell, OnProcessSpell)

local function Rotated(v, angle)
	local c = math.cos(angle)
	local s = math.sin(angle)
	return vec3(v.x * c - v.z * s, 0, v.z * c + v.x * s)
end

local function CrossProduct(p1, p2)
	return (p2.z * p1.x - p2.x * p1.z)
end

local function E_Cone(Position)
    local range = E.Range
    local angle = (85 * math.pi / 180)
    local end2 = E.EConeEnd - E.EConeStart
    local edge1 = Rotated(end2, -angle / 2)
	local edge2 = Rotated(edge1, angle)
    local point = Position - E.EConeStart
    if point:distSqr(vec3(0,0,0)) < range * range and CrossProduct(edge1, point) > 0 and CrossProduct(point, edge2) > 0 then
        return true
    end
    return false
end

local function CastQ() 
    if IsPreAttack then 
        return 
    end 
 
    if (common.getBuffValid(player, 'ZacE')) then 
        return 
    end 

    local target = TargetPred.get_result(real_target_filter(Q.pred_input).Result) 
    if target.obj then 
        if not target.obj.buff['zacqmissile'] then  

            local targetDist = target.obj.pos:dist(player.pos)

            if player:spellSlot(0).state == 0  then 
                if not target.pos then 
                    return 
                end 

                player:castSpell("pos", 0, vec3(target.pos.x, mousePos.y, target.pos.y))
            end 
        else 
            if target.obj.buff['zacqmissile'] then   
                local bestTarget = { obj = nil, dist = common.GetAARange(player) }
                for i = 0, objManager.enemies_n - 1 do
                    local enemy = objManager.enemies[i]
                    if enemy.pos:dist(player.pos) <= common.GetAARange(player) then
                        local dist = enemy.pos:dist(player.pos)
                        if bestTarget.obj then
                            if dist < bestTarget.dist then
                                bestTarget.obj = enemy
                                bestTarget.dist = dist
                            end
                        else
                            bestTarget.obj = enemy
                            bestTarget.dist = dist
                        end
                    end
                end
                if not bestTarget.obj then
                    local minions = objManager.minions
                    for i = 0, minions.size[TEAM_ENEMY] - 1 do
                        local minion = minions[TEAM_ENEMY][i]
                        if minion.pos:dist(player.pos) <= common.GetAARange(player) then
                            local dist = minion.pos:dist(player.pos)
                            if bestTarget.obj then
                                if dist < bestTarget.dist then
                                    bestTarget.obj = minion
                                    bestTarget.dist = dist
                                end
                            else
                                bestTarget.obj = minion
                                bestTarget.dist = dist
                            end
                        end
                    end
                    for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
                        local minion = minions[TEAM_NEUTRAL][i]
                        if minion.pos:dist(player.pos) <= common.GetAARange(player) then
                            local dist = minion.pos:dist(player.pos)
                            if bestTarget.obj then
                                if dist < bestTarget.dist then
                                    bestTarget.obj = minion
                                    bestTarget.dist = dist
                                end
                            else
                                bestTarget.obj = minion
                                bestTarget.dist = dist
                            end
                        end
                    end
                end
                if bestTarget.obj then
                    player:attack(bestTarget.obj)
                end
            end
        end 
    end
end 

local function CastE()
    if IsPreAttack then 
        return 
    end 

    local target = TargetPred.get_result(real_target_filter(E.pred_input).Result) 
    if target.obj then 
        if player:spellSlot(2).state == 0  then 
            if not target.pos then 
                return 
            end 

        
            local CastPosition = vec3(target.pos.x, mousePos.y, target.pos.y)
            if (common.getBuffValid(player, 'ZacE')) then 

                local TargetPosition = (CastPosition + 200 * (CastPosition - player.pos):norm())
                if common.IsInRange(E.Range, TargetPosition, player) then
                    player:castSpell('release', 2, CastPosition)
                end 

            else 
                player:castSpell('pos', 2, CastPosition)
            end 
        end
    end
end

local function Combo()
    if menu.combo.E:get() then 
        CastE()
    end 
    if menu.combo.Q:get() then 
        CastQ()
    end 
    if menu.combo.W:get() then 
        local target = common.GetTarget(350)

        if not target then 
            return 
        end 

        if player:spellSlot(1).state == 0 then 
            player:castSpell('self', 1)
        end 
    end
end 

local function Harass()
    if common.GetPercentHealth(player) >= menu.harass.mana:get() then 
        if menu.harass.q:get() then 
            CastQ()
        end

        if menu.harass.w:get() then 
            local target = common.GetTarget(350)

            if not target then 
                return 
            end 
    
            if player:spellSlot(1).state == 0 then 
                player:castSpell('self', 1)
            end 
        end

        if menu.harass.e:get() then 
            CastE()
        end
    end
end 

local function JungleClear()
    if common.GetPercentHealth(player) >= menu.jungle['LaneClear.ManaPercent']:get() then 
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] -1 do 
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if minion and common.IsValidTarget(minion) then 
                if menu.jungle.q:get() then 
                    if minion.pos:dist(player) < 951 and player:spellSlot(0).state == 0 then 
                        player:castSpell('pos', 0, minion.pos)
                    end
                end 


                if menu.jungle.w:get() then 
                    if not minion then 
                        return 
                    end 

                    if minion.pos:dist(player) < 350 and player:spellSlot(1).state == 0 then 
                        player:castSpell('self', 1)
                    end
                    
                end 

                if menu.jungle.e:get() then 
                    if (common.getBuffValid(player, 'ZacE')) then 

                        local TargetPosition = (minion.pos + 200 * (minion.pos - player.pos):norm())
                        if common.IsInRange(E.Range, TargetPosition, player) then
                            player:castSpell('release', 2, minion.pos)
                        end 
        
                    else 
                        player:castSpell('pos', 2, minion.pos)
                    end 
                end 
            end 
        end 
    end
end

local function OnTick()
    if (player.isDead and not player.isTargetable and  player.buff[17]) then return end 

    IsPreAttack = false 

    E.CastRangeGrowthMax = ({1200, 1350, 1500, 1650, 1800})[player:spellSlot(2).level];
    E.CastRangeGrowthDuration = ({0.9, 1, 1.1, 1.2, 1.3})[player:spellSlot(2).level];

    if (common.getBuffValid(player, 'ZacE')) then 
        local percentGrowth = math.max(0, math.min(1, (1000 * (game.time - E.LastCastTime) / 1000 - E.CastRangeGrowthStartTime) / E.CastRangeGrowthDuration));
        E.Range = ((E.CastRangeGrowthMax - E.CastRangeGrowthMin) * percentGrowth + E.CastRangeGrowthMin);
    else 
        E.Range = E.CastRangeGrowthMax;
    end

    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    elseif orb.menu.lane_clear.key:get() then 
        JungleClear()
    end

    if (common.getBuffValid(player, 'ZacE')) then 
        if (evade) then
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


    --[[local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and common.IsValidTarget(target) and common.IsEnemyMortal(target) then
            for i, buff in pairs(target.buff) do 
                if buff and buff.valid then 
                    if buff.name:lower():find("zac") then
                        print(buff.name)
                    end 
                end --zacqslow, ZacQMissile
            end
            if target.buff['zacqmissile'] then 
                print'here'
            end 
        end 
    end]]
end
cb.add(cb.tick, OnTick)

local function OnPreTick() 
    if (player.isDead and not player.isTargetable and  player.buff[17]) then return end 

    IsPreAttack = true;
end 
cb.add(cb.pre_tick, OnPreTick)


local function OnDraw()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 951, 1, menu.draws.qcolor:get(), 100)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 350, 1, menu.draws.wcolor:get(), 40)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, E.Range, 1, menu.draws.ecolor:get(), 40)
        end
    end
end
cb.add(cb.draw, OnDraw)