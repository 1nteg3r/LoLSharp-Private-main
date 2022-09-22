local orb = module.internal("orb");
local pred = module.internal("pred")
local evade = module.seek('evade')
local TS = module.internal("TS")
local common = module.load(header.id, "common");
local damage = module.load(header.id, 'damageLib');
local Joushima = module.load(header.id, 'Joushima');
local VPred = module.load(header.id, "VP")

local Stacks = 0
local LastBlockTick = 0
local WShouldWaitTick = 0 
local IsCastingR = false 
local RConeStart = vec3(0,0,0)
local RConeEnd = vec3(0,0,0)
local LastCastTime  = 0
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

local Samaritan = {}

function Samaritan.Project(sourcePosition, unitPosition, unitDestination, spellSpeed, unitSpeed)
    local toUnit = unitPosition - sourcePosition
    local toDestination = unitDestination - unitPosition

    local cos = toUnit:norm():dot(toDestination:norm())
    local sin = math.abs(toUnit:norm():cross(toDestination:norm()))

    local unitVelocity = toDestination:norm() * unitSpeed
    local relativeUnitVelocity = toDestination:norm() * unitSpeed * cos

    local pi2 = (math.pi * 0.5)
    local angle = math.min(pi2, math.abs(mathf.angle_between(sourcePosition, unitPosition, unitDestination)))    
    local value = math.max(sin, angle)

    local magicalFormula = pi2 - value

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

local menu = menu("MarksmanAIOJhin", "Marksman - Jhin")
menu:header('a1', 'Core')
menu:menu('combo', 'Combo')
    menu.combo:boolean('useQ', 'Use Q', true)
    menu.combo:boolean('useE', 'Use E', false)
    menu.combo:dropdown('useW', 'Use W', 2, { 'Never', 'Only buffed enemies', 'Always' })
--
menu:menu("ult", "Ultimate");
    menu.ult:dropdown('moder', 'Use R Shot', 3, {'Disabled', 'Using TapKey', 'Automatic'});
    menu.ult.moder:set("tooltip", "If the option is in 'Using TapKey' Precione Space to shoot")--If the option is in "Using TapKey" Precione Space to shoot
    menu.ult:boolean('Onlyaa', "Only attack if it's killable", false);
    menu.ult:slider("Delay", "Delay between R's (in ms)", 0, 0, 1500, 1);
    menu.ult:header('A2', 'Near Mouse Settings')
    menu.ult:boolean('NearMouse.Enabled', "Only select target near mouse", false);
    menu.ult:slider("NearMouse.Radius", "Near mouse radius", 500, 100, 1500, 100);
    menu.ult:boolean('NearMouse.Draw', "Draw near mouse radius", true);

menu:menu("harass", "Harass");
    menu.harass:boolean("q", "Use Q", true);
    menu.harass:boolean("w", "Use W", false);
    menu.harass:boolean("e", "Use E", false);
    menu.harass:slider("mana", "Minimum Mana Percent", 20, 0, 100, 1);

menu:menu("lane", "Clear");
    menu.lane:menu("laneclear", "LaneClear");
        menu.lane.laneclear:slider("LaneClear.Q", "Use Q if hit is greater than", 3, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.W", "Use W if hit is greater than", 5, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.E", "Use E if hit is greater than", 4, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 60, 0, 100, 1);
    menu.lane:menu("jungle", "JungleClear");
    menu.lane.jungle:boolean("q", "Use Q", true);
    menu.lane.jungle:boolean("w", "Use W", true);
    menu.lane.jungle:boolean("e", "Use E", true);
    menu.lane.jungle:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 50, 0, 100, 1);
    menu.lane:menu("last", "LastHit");
        menu.lane.last:dropdown('LastHit.Q', 'Use Q', 2, {'Never', 'Smartly', 'Always'});
        menu.lane.last:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 50, 0, 100, 1);

menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useW', 'Use W for KillSteal', true)

menu:menu('auto', 'Automatic')
    menu.auto:boolean("E.Gapcloser", "Use E on hero gapclosing / dashing", true);
    menu.auto:boolean("Imobile", "Use E on hero immobile", true);

menu:menu('evade', "Evader")
    menu.evade:boolean("BlockW", "Block W to Evade", true);

menu:menu('misc', "Misc")
    menu.misc:keybind("autow", "Auto W", nil, "G")
    menu.misc:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 10, 0, 100, 1); 
    menu.misc:header('a2a1', 'Allowed champions to use Auto W')
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy then 
            menu.misc:boolean(enemy.charName, "Auto W: " .. enemy.charName, true)
        end
    end 

menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", false)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range (MiniMap)", true)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", false)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("rrange", "Draw R Range (MiniMap)", true)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)


local function DrawDamagesE(target)
	if target.isVisible and not target.isDead then
        local pos = graphics.world_to_screen(target.pos)
		graphics.draw_line_2D(pos.x, pos.y - 30, pos.x + 30, pos.y - 80, 1, graphics.argb(255, 150, 255, 200))
		graphics.draw_line_2D(pos.x + 30, pos.y - 80, pos.x + 50, pos.y - 80, 1, graphics.argb(255, 150, 255, 200))
		graphics.draw_line_2D(pos.x + 50, pos.y - 85, pos.x + 50, pos.y - 75, 1, graphics.argb(255, 150, 255, 200))
		if math.floor((damage.GetSpellDamage(3, target) * Stacks) / target.health * 100) < 100 then
			graphics.draw_text_2D("(" .. tostring(math.floor((damage.GetSpellDamage(3, target) * Stacks)/ target.health * 100)) .. "%)" .. "Almost there", 20, pos.x + 55, pos.y - 80, graphics.argb(255, 150, 255, 200))
		else 
			graphics.draw_text_2D("(" .. "100" .. "%)" .. "TIME OF HIS DEATH", 35, pos.x + 55, pos.y - 80, graphics.argb(255, 255, 0, 0))
		end
	end
end

local q_pred_input = {
    delay = 0.25;
    range = 625; 
    radius = 450;
    speed = 1800; 
    dashRadius = 0;
    boundingRadiusModSource = 1;
    boundingRadiusModTarget = 1;
}

local w_pred_input = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.75,
    speed = 5000,
    width = 40,
    range = 2500,
    collision = { hero = true, minion = false, wall = true },

    damage = function(m)
        return damage.GetSpellDamage(1, m)
    end,
}

local e_pred_inupt = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 1200,
    radius = 110,
    range = 750,
}

local r_pred_input = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    range = 3500;
	delay = 0.25; 
	width = 80;
	speed = 1200;
	collision = 
    {   hero = true, 
        minion = false, 
        wall = true
    };
}


local q_pred = function(res, obj, dist)
    if dist > 1000 then return end
    if pred.present.get_prediction(q_pred_input, obj) then
        res.obj = obj
        return true
    end
end

local function IsR1()
    return player:spellSlot(3).name == "JhinR"
end 

local function isInAutoAttackRange(target)
    return player.pos:dist(target.pos) <= common.GetAARange(player) 
end 

local function DeadlyFlor(target)
    local buff = target.buff['jhinespotteddebuff'];
    if buff and buff.valid and buff.owner == target then 
        return (buff.endTime - game.time) * 1000
    end
    return 0
end

local hard_cc = {
  [5] = true, -- stun
  [8] = true, -- taunt
  [11] = true, -- snare
  [18] = true, -- sleep
  [21] = true, -- fear
  [22] = true, -- charm
  [24] = true, -- suppression
  [28] = true, -- flee
  [29] = true, -- knockup
  [30] = true, -- knockback
}

local function GetMovementBlockedDebuffDuration(target)
    for i, buff in pairs(target.buff) do 
        if buff and buff.valid and hard_cc[buff.type] then
            return (buff.endTime - game.time) * 1000
        end 
    end
    return 0
end 

local function Rotated(v, angle)
	local c = math.cos(angle)
	local s = math.sin(angle)
	return vec3(v.x * c - v.z * s, 0, v.z * c + v.x * s)
end

local function CrossProduct(p1, p2)
	return (p2.z * p1.x - p2.x * p1.z)
end


local function JhinRCone(Position)
    if not IsCastingR then 
        return 
    end
    local range = 3500
    local angle = (60 * math.pi / 180)
    local end2 = RConeEnd - RConeStart
    local edge1 = Rotated(end2, -angle / 2)
	local edge2 = Rotated(edge1, angle)
    local point = Position - RConeStart
    if point:distSqr(vec3(0,0,0)) < range * range and CrossProduct(edge1, point) > 0 and CrossProduct(point, edge2) > 0 then
        return true
    end
    return false
end

local function GetBestCircularObject(Position, radius, range)
    local obj, count = nil, 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and common.IsValidTarget(minion) and player.pos:dist(minion) <= range then 
            if Position and Position:distSqr(minion.pos) <= radius * radius and Position:distSqr(minion.pos) > 150 then
                count = count + 1
                obj = minion
            end 
        end 
    end
    return obj, count
end

local function GetMinionsHit(Pos, radius)
    local count = 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and minion.pos:dist(player) <= 750 and common.GetDistance(minion, Pos) < radius then
			count = count + 1
		end
	end
	return count
end

local function OnProcessSpell(spell)
    if(spell.owner == player and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Jhin") then
        if spell.name == "JhinR" then 
            IsCastingR = true
            RConeStart = vec3(spell.startPos.x, spell.startPos.y, spell.startPos.z)
            RConeEnd = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)
            Stacks = 4 
        end 

        if spell.name == "JhinRShot" then 
            --LastCastTime = game.time * 1000
            Stacks = Stacks - 1
        end

        if spell.name == "JhinW" then 
            LastBlockTick = os.clock() 
        end
    end 
end 
cb.add(cb.spell, OnProcessSpell)

local function OnGapcloser()
    if IsCastingR then 
        return 
    end
    local target = TS.get_result(function(res, obj, dist)
        if dist <= 750 and obj.path.isActive and obj.path.isDashing then 
            res.obj = obj
            return true
        end
    end).obj
    if target and common.IsValidTarget(target) then
        local pathStartPos = target.path.point[0]
        local pathEndPos = target.path.point[target.path.count] 
        if player.pos:dist(pathStartPos) > player.pos:dist(pathEndPos) then 
            if menu.auto['E.Gapcloser']:get() and player.pos:dist(pathEndPos) <= 750 then 
                player:castSpell('pos', 2, pathEndPos)
            end 
        end 
        if player.pos:dist(pathEndPos) < player.pos:dist(target.pos) * 1.5 then 
            WShouldWaitTick = game.time
        end 
    end
end

--local obj = TS.get_result(vayne.e_pred).obj;
local function CastQ(target)
    if (IsCastingR) then 
        return 
    end 

    if (player:spellSlot(0).state == 0 and target ~= nil and not IsPreAttack and not orb.core.can_attack()) then 
        if target.pos:dist(player.pos) > 650 then 
            for i=0, objManager.enemies_n-1 do
                local obj = objManager.enemies[i]
                if obj and common.IsValidTarget(obj) then
                    local Minion, Count = GetBestCircularObject(obj.pos, 450, 625)
                    if (Count > 1 and Count < 3) and Minion then 
                        player:castSpell('obj', 0, Minion)
                    end
                end 
            end 
        else 
            if player.buff['jhinpassivereload'] then 
                player:castSpell('obj', 0, target)
            else 
                player:castSpell('obj', 0, target)
            end 
        end
    end
end 

local function CastW(target, pos)
    if (IsCastingR) then 
        return 
    end 

    if (player:spellSlot(1).state == 0 and target ~= nil and not IsPreAttack) then 
        if #common.CountEnemiesInRange(player.pos, 400) > 0 and not DeadlyFlor(target) then 
            return 
        end

        if not DeadlyFlor(target) then  
            if (os.clock() - LastBlockTick < 0.75) then 
                return 
            end 

            if (game.time - WShouldWaitTick < 0.75) then 
                return 
            end 

            if (orb.core.can_attack() and isInAutoAttackRange(target) or (player:spellSlot(2).state == 0 and target.pos:dist(player) <= 750)) then 
                return 
            end
        end 
        player:castSpell('pos', 1, pos)
    end
end

local function CastE(target)
    if (IsCastingR) then 
        return 
    end 

    if target.pos:dist(player) > 750 then 
        return 
    end

    if (player:spellSlot(2).state == 0 and target ~= nil and not IsPreAttack) then 
        if target and target ~= nil and common.IsValidTarget(target) then
            local predPos = pred.circular.get_prediction(e_pred_inupt, target)

            if predPos then 
                if ((predPos.endPos:dist(target.pos) > 150)) or ((predPos.endPos:dist(target.pos) > 150) and common.IsMovingTowards(target, 500)) then
                    player:castSpell("pos", 2, vec3(predPos.endPos.x, target.y, predPos.endPos.y))
                elseif target and (target.pos:dist(player.pos) <= 750) and common.IsMovingTowards(target, 400) then 
                    player:castSpell("pos", 2, player.path.serverPos)
                end 
            end
        end
    end 
end

local function CastR()
    if IsR1() then 
        return 
    end 

    local target = TS.get_result(function(res, obj, dist)
        if (dist > r_pred_input.range or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
            return
        end
        if obj and common.IsValidTarget(obj) and JhinRCone(obj.pos) and ((damage.GetSpellDamage(3, obj) * Stacks) > common.GetShieldedHealth("AD", obj) or (damage.GetSpellDamage(3, obj) * Stacks)) then
            res.obj = obj
            return true
        end
    end).obj

    if target and common.IsValidTarget(target) then 
        local seg = pred.linear.get_prediction(r_pred_input, target)
        if seg and seg.startPos:distSqr(seg.endPos) <= (r_pred_input.range * r_pred_input.range) then
            local col = pred.collision.get_prediction(r_pred_input, seg, target)

            if col then
                return 
            end
            local CastPosition, HitChance, Position = VPred.GetBestCastPosition(target, 0.25, 80, 3500, 1200, player, false, "linear")

            if not CastPosition then 
                return 
            end 

            local castPos = mathf.project(player.pos, target.pos, CastPosition, r_pred_input.speed, target.moveSpeed)

            if castPos then 
                player:castSpell('pos', 3, castPos)
            end 
        end  
    end 
end 

local function AutoW()
    if menu.misc.autow:get() and common.GetPercentMana(player) >= menu.misc['LaneClear.ManaPercent']:get() then 
        local target = TS.get_result(real_target_filter(w_pred_input).Result)
        if target.obj and target.pos then     
            if menu.misc[target.obj.charName] and menu.misc[target.obj.charName]:get() then 
                if DeadlyFlor(target.obj) and DeadlyFlor(target.obj) > 0 and DeadlyFlor(target.obj) * 1000 > 0.75 then 
                    if player:spellSlot(1).state == 0 then 
                        CastW(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
                    end
                end 
            end
        end 
    end
end

local function Combo()
    if menu.combo.useE:get() and player.mana >= (player.manaCost2 + player.manaCost3) then

        local target = common.GetTarget(800)

        if target and common.IsValidTarget(target) then 
            CastE(target)
        end 
    end
    if menu.combo.useW:get() > 0 and player.mana >= (player.manaCost1 + player.manaCost2 + player.manaCost3) then
        
        local target = TS.get_result(real_target_filter(w_pred_input).Result) 
        if target.obj and target.pos then  

            if menu.combo.useW:get() == 2 then  

                if DeadlyFlor(target.obj) and DeadlyFlor(target.obj) > 0 and DeadlyFlor(target.obj) * 1000 > 0.75 then  
                    CastW(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
                end 

            elseif menu.combo.useW:get() == 3 then
                CastW(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
            end 
        end 
    end

    if menu.combo.useQ:get() and player.mana >= (player.manaCost0 + player.manaCost3) then
        local obj = TS.get_result(q_pred).obj;
        if obj and obj ~= nil then 
            CastQ(obj)
        end 
    end
end 

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) and common.IsEnemyMortal(enemies) then

            local DamageQ = damage.GetSpellDamage(0, enemies)
            local Hp_hero = common.GetShieldedHealth("ALL", enemies)

            if menu.kill.useQ:get() and player:spellSlot(0).state == 0 then 
                if (DamageQ > Hp_hero) then 
                    CastQ(enemies)
                end 
            end 
        end 
    end
    local target = TS.get_result(real_target_filter(w_pred_input).Result) 
    if target.obj and target.pos and common.IsEnemyMortal(target.obj) then 

        local DamageW = damage.GetSpellDamage(1, target.obj)

        if menu.kill.useW:get() and player:spellSlot(1).state == 0 then 
            
            if (DamageW > common.GetShieldedHealth("ALL", target.obj)) then 
                CastW(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
            end 

        end 
    end
end 

local function Harass()
    if common.GetPercentMana(player) >= menu.harass.mana:get() then 
        if menu.harass.e:get() then 
            local target = common.GetTarget(800)

            if target and common.IsValidTarget(target) then 
                CastE(target)
            end 
        end 
        if menu.harass.w:get() and menu.combo.useW:get() > 0 then 
            local target = TS.get_result(real_target_filter(w_pred_input).Result) 
            if target.obj and target.pos then  

                if menu.combo.useW:get() == 2 then  

                    if DeadlyFlor(target.obj) and DeadlyFlor(target.obj) > 0 and DeadlyFlor(target.obj) * 1000 > 0.75 then  
                        CastW(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
                    end 

                elseif menu.combo.useW:get() == 3 then
                    CastW(target.obj, vec3(target.pos.x, mousePos.y, target.pos.y))
                end 
            end 
        end 
        if menu.harass.q:get() then 
            local obj = TS.get_result(q_pred).obj;
            if obj and obj ~= nil then 
                CastQ(obj)
            end 
        end 
    end
end 

local function invoke__lane_clear()
    local valid = {}
    local minions = objManager.minions
    for i = 0, minions.size[TEAM_ENEMY] - 1 do

        local minion = minions[TEAM_ENEMY][i]
        if minion and not minion.isDead and minion.isVisible then
            local dist = player.path.serverPos:distSqr(minion.path.serverPos)
            if dist <= 1638400 then
                valid[#valid + 1] = minion
            end
        end
    end
    local max_count, cast_pos = 0, nil
    for i = 1, #valid do

        local minion_a = valid[i]
        local current_pos = player.path.serverPos + ((minion_a.path.serverPos - player.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos) + 1300))
        local hit_count = 1
        for j = 1, #valid do
            if j ~= i then
                local minion_b = valid[j]
                local point = mathf.closest_vec_line(minion_b.path.serverPos, player.path.serverPos, current_pos)
                if point and point:dist(minion_b.path.serverPos) < (89 + minion_b.boundingRadius) then
                    hit_count = hit_count + 1
                end
            end
        end
        if not cast_pos or hit_count > max_count then
            cast_pos, max_count = current_pos, hit_count
        end
        if cast_pos and max_count > menu.lane.laneclear['LaneClear.W']:get() then
            player:castSpell("pos", 1, cast_pos)
        end
    end
end

local function LaneClear()
    if common.GetPercentMana(player) > menu.lane.laneclear['LaneClear.ManaPercent']:get() then
        local count = 0
        for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion and common.IsValidTarget(minion) then 
                if minion.pos:dist(player) < 625 then 
                    count = count + 1
                end 
                if count >= menu.lane.laneclear['LaneClear.Q']:get() then 
                    if (orb.farm.predict_hp(minion, 0.25) < damage.GetSpellDamage(0, minion)) then
                        CastQ(minion)
                    end 
                end

                if GetMinionsHit(minion, 175) >= menu.lane.laneclear['LaneClear.E']:get() then 
                    CastE(minion)
                end 
            end 
        end  
        invoke__lane_clear()
    end 
end 

local function JungleClear()
    if common.GetPercentMana(player) > menu.lane.jungle['LaneClear.ManaPercent']:get() then
        local count = 0
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] -1 do 
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if minion and common.IsValidTarget(minion) then 
                if minion.pos:dist(player) < 625 then 
                    count = count + 1
                end 
                if count >= 0 and menu.lane.jungle.q:get() then 
                    if (orb.farm.predict_hp(minion, 0.25) < damage.GetSpellDamage(0, minion)) then
                        CastQ(minion)
                    end 
                end

                if GetMinionsHit(minion, 175) >= 0 and menu.lane.jungle.e:get() then 
                    CastE(minion)
                end 
            end 
        end  
        if menu.lane.jungle.w:get() then 
            invoke__lane_clear()
        end
    end
end

local function LastHit()
    if common.GetPercentMana(player) > menu.lane.last['LaneClear.ManaPercent']:get() then
        local count = 0
        for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion and common.IsValidTarget(minion) then 
                if minion.pos:dist(player) < 625 then 
                    count = count + 1
                end 
                if count >= 2 and menu.lane.last['LastHit.Q']:get() == 2 then 
                    if (orb.farm.predict_hp(minion, 0.25) < damage.GetSpellDamage(0, minion)) then
                        CastQ(minion)
                    end 
                elseif count > 0 and menu.lane.last['LastHit.Q']:get() == 3 then 
                    if (orb.farm.predict_hp(minion, 0.25) < damage.GetSpellDamage(0, minion)) then
                        CastQ(minion)
                    end 
                end 
            end 
        end
    end
end

local function OnTick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end 

    IsPreAttack = false 

    if IsCastingR then 
        IsCastingR = player:spellSlot(3).name == "JhinRShot"
    end 

    if (player:spellSlot(3).state == 0 and not IsCastingR) then 
        Stacks = 4;
    end 

    if (IsCastingR) then 
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

    CastR()

    OnGapcloser()
    AutoW()
    KillSteal()

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


    if menu.auto.Imobile:get() then 
        local enemy = common.GetEnemyHeroes()
        for i, target in ipairs(enemy) do
            if target  and common.IsValidTarget(target) then
                local time = GetMovementBlockedDebuffDuration(target)
                if time > 0 and time * 1000 > 0.25 then 
                    if player:spellSlot(2).state == 0 and target.pos:dist(player) <= 750 then 
                        player:castSpell("pos", 2, target.path.serverPos)
                    end 
                end 
            end 
        end
    end 
    
end
cb.add(cb.tick, OnTick)

local function OnDrawing()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 625, 1, menu.draws.qcolor:get(), 40)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 750, 1, menu.draws.ecolor:get(), 40)
        end
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.misc.autow:get() then
			graphics.draw_text_2D("Auto W: On", 16, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Auto W: Off", 16, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
		end
    end
    if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
        minimap.draw_circle(player.pos, 2500, 1, menu.draws.wcolor:get(), 40)
    end
    if (menu.draws.rrange:get() and player:spellSlot(3).state == 0) and not IsCastingR then
        minimap.draw_circle(player.pos, 3500, 1, menu.draws.rcolor:get(), 100)
    end
    --[[local target = TS.get_result(real_target_filter(w_pred_input).Result)
    if target.obj then 
        graphics.draw_circle(target.obj.pos, 750, 1, menu.draws.ecolor:get(), 40)
    end]]
    if player:spellSlot(3).state == 0 or IsCastingR then
        local enemy = common.GetEnemyHeroes()
        for i, enemies in ipairs(enemy) do
            if enemies and enemies.isVisible and common.IsValidTarget(enemies) then
                DrawDamagesE(enemies)
            end
        end
    end
end 
cb.add(cb.draw, OnDrawing)

local function OnPreAttack()
    IsPreAttack = true 
end
orb.combat.register_f_pre_tick(OnPreAttack)