local orb = module.internal("orb");
local pred = module.internal("pred");
local common = module.load('int', 'Library/common');
local TS = module.load("int", "TargetSelector/targetSelector")
local TargetPred = module.internal("TS")
local VP = module.load("int", "Prediction/VP")
local spellQ = {
	boundingRadiusModSource = 1,
	boundingRadiusMod = 1,
	range = 1000,
	delay = 0.25,
	width = 70,
	speed = 1800,
	collision = {
		hero = true,
        minion = true,
        wall = true,
	}
}

local q_collision = {
	minion = 0,
	enemyhero = 1
}

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


local menu = menu("IntnnerBlitz", "Int Blitzcrank")
TS = TS(menu, 1100)
TS:addToMenu()
menu:header("xs", "Core");
menu:boolean("q", "Use Q", true);
menu:menu("blacklist", "Blacklist - No Grab!")
local enemy = common.GetEnemyHeroes()
for i, allies in ipairs(enemy) do
	menu.blacklist:boolean(allies.charName, "Not grab: " .. allies.charName, false)
end
menu:boolean("ecombo", "Use E", true)
menu:boolean("rcombo", "Use R", true)
menu:slider("hitr", " ^~ Min. Enemies {0} >=", 2, 1, 5, 1)

menu:menu("ddd", "Display");
menu.ddd:boolean("qd", "Q Range", true);

orb.combat.register_f_pre_tick(function()
    --IsUnderAllyTurretRockedGrab(player) 
    if not orb.combat.is_active() then return end
    local target = TS.target 

    if target and common.IsValidTarget(target) and common.IsEnemyMortal(target) then 
		if menu.q:get() then
			if menu.blacklist[target.charName] and not menu.blacklist[target.charName]:get() then 
                if target.pos:dist(player.pos) >= 300 then
                    
                    local CastPosition, HitChance, Position = VP.GetBestCastPosition(target, 0.25, 110, 990, 1800, player, true, "line")

                    if not CastPosition then 
                        return 
                    end 

                    if HitChance >= 2 then 
                        player:castSpell('pos', 0, CastPosition)
                    end 
				end
			end
        end
        if menu.ecombo:get() then 
            if target.buff['rocketgrab2'] and player:spellSlot(2).state == 0 then 
                player:castSpell("self", 2)
            elseif player:spellSlot(2).state == 0 then 
                if orb.combat.target then
                    if common.IsValidTarget(orb.combat.target) and player.pos:dist(orb.combat.target.pos) < common.GetAARange(orb.combat.target) then
                        player:castSpell("self", 2)
                    end
                end
            end
        end
        if menu.rcombo:get() then
            if #common.CountEnemiesInRange(player.pos, 600) >= menu.hitr:get() then
                player:castSpell("self", 3)
            end
        end
    end 
end);


local function OnDraw() 
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.ddd.qd:get()) then 
            graphics.draw_circle(player.pos, 1100, 1, graphics.argb(255, 218, 165, 38), 30)
        end     
    end
end



cb.add(cb.draw, OnDraw)