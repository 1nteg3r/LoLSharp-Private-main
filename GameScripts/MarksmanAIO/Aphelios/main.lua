--ApheliosSeverumQ [Vermelho laminas]
--ApheliosGravitumQ [Gravitum é roxo]
--ApheliosInfernumQ [Foguinho]
--ApheliosCrescendumQ [Arma com robos]
--ApheliosCalibrumQ [Arma longa]

--Segunda Arma: apheliosoffhandbuffgravitum, Severum, Infernum, Crescendum,
--Buff Gavitum: apheliosgravitumdebuff
local orb = module.internal("orb");
local evade = module.seek("evade");
local TS = module.internal("TS");
local pred = module.internal("pred");
local common = module.load("marksman", "common");
local VPred = module.load(header.id, "VP")

local Guns = {
    main = nil, 
    off = nil 
}
local CD = { }

local preds = {
    Infernum = {
        width = 0,
        delay = 0.4,
        speed = math.huge,
        range = 600,
        boundingRadiusMod = 1,
        angle = (math.pi/180*45),
    };

    Calibrum = {
        width = 120,
        delay = 0.35,
        speed = 1800,
        range = 1450,
        boundingRadiusMod = 1,
        collision = { 
            hero = true, 
            minion = true, 
            walls = true 
        };
    };

    MoonLight = {
        width = 110,
        delay = 0.5,
        speed = 1000,
        range = 1300,
        boundingRadiusMod = 1,
        collision = { 
            hero = true, 
            minion = false, 
            walls = true 
        };
    }

}
local menu = menu("marksman", "Marksman - ".. player.charName)
    menu:menu('aphe', "Aphelios Settings")
    menu.aphe:boolean("qcombo", "Use Weapon's", true)
    --R
    menu.aphe:header('Another', "Misc Settings")
    menu.aphe:boolean("rcombo", "Use Moonlight Vigil", true)
    menu.aphe:keybind("semiR", "Semi-R", "T", nil)
    --Draw 
    menu.aphe:header('ha', "Drawings Settings")
    menu.aphe:boolean("qdraw", "Drawings", true)
    menu.aphe:color("qcolor", "Drawing Color", 255, 255, 255, 255)


local CDTracker = { 
    [1] = { CD = player:spellSlot(1).cooldown <= 0 and 12 or player:spellSlot(1).cooldown, CDT = 0, T = 0, ready = false, name = "ApheliosW" },
}

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

local function Rotated(v, angle)
	local c = math.cos(angle)
	local s = math.sin(angle)
	return vec3(v.x * c - v.z * s, 0, v.z * c + v.x * s)
end


local function CalcBestCastAngle(angles)
    local maxCount = 0
    local maxStart = nil
    local maxEnd = nil
    for i = 1, #angles do
        local base = angles[i]
        local endAngle = base + 45
        local over360 = endAngle > 360
        if over360 then
            endAngle = endAngle - 360
        end
        local function isContained(count, angle, base, over360, endAngle)
            if angle == base and count ~= 0 then
                return
            end
            if not over360 then
                if angle <= endAngle and angle >= base then
                    return true
                end
            else
                if angle > base and angle <= 360 then
                    return true
                elseif angle <= endAngle and angle < base then
                    return true
                end
            end
        end
        local angle = base
        local j = i
        local count = 0
        local endDelta = angle
        while (isContained(count, angle, base, over360, endAngle)) do
            endDelta = angles[j]
            count = count + 1
            j = j + 1
            if j > #angles then
                j = 1
            end
            angle = angles[j]
        end
        if count > maxCount then
            maxCount = count
            maxStart = base
            maxEnd = endDelta
        end
    end
    if maxStart and maxEnd then
        if maxStart + 45 > 360 then
            maxEnd = maxEnd + 360
        end
        local res = (maxStart + maxEnd) / 2
        if res > 360 then
            res = res - 360
        end
        return math.rad(res)
    end
end

local function GetFuns()
    local byName = player:spellSlot(0).name
    if byName == "ApheliosCalibrumQ" then
        Guns.main = "Calibrum"
    elseif byName == "ApheliosSeverumQ" then
        Guns.main = "Severnum"
    elseif byName == "ApheliosGravitumQ" then
        Guns.main = "Gravitum"
    elseif byName == "ApheliosInfernumQ" then
        Guns.main = "Infernum"
    elseif byName == "ApheliosCrescendumQ" then
        Guns.main = "Crescendum"
    end

    for i, buff in pairs(player.buff) do
        if buff then
            if buff.name == "ApheliosOffHandBuffCalibrum" then
                Guns.off = "Calibrum"
            elseif buff.name == "ApheliosOffHandBuffSeverum" then
                Guns.off = "Severnum"
            elseif buff.name == "ApheliosOffHandBuffGravitum" then
                Guns.off = "Gravitum"
            elseif buff.name == "ApheliosOffHandBuffInfernum" then
                Guns.off = "Infernum"
            elseif buff.name == "ApheliosOffHandBuffCrescendum" then
                Guns.off = "Crescendum"
            end
        end
    end 
end 

local function CalibrumQPred(target)
    if not target then 
        return 
    end 

    local predQ = pred.linear.get_prediction(preds.Calibrum, target)
    if predQ and predQ.startPos:distSqr(predQ.endPos) <= (preds.Calibrum.range * preds.Calibrum.range) then
        local col = pred.collision.get_prediction(preds.Calibrum, predQ, target)

        if col then
            return 
        end

        local castPos = mathf.project(player.pos, target.pos, vec3(predQ.endPos.x, target.pos.y, predQ.endPos.y), preds.Calibrum.speed, target.moveSpeed)

        if castPos then 
            player:castSpell('pos', 0, castPos)
        end
    end 
end 

local function CalibrumSwitch()
    local target = orb.combat.target
    if target and target.pos:dist(player.pos) <= (player.attackRange + player.boundingRadius + 100) then
        local dist = player.attackRange + player.boundingRadius
        local targetPred = pred.core.get_pos_after_time(target, 0.5)
        local myHeroPred = pred.core.get_pos_after_time(player, 0.5)
        if common.GetDistanceSqr(targetPred, myHeroPred) >= dist * dist then
            player:castSpell('pos', 1, game.mousePos)
            return true
        end
    end
    local targetCalibrum = common.GetTarget(1350)
    if not CD[Guns.off] and targetCalibrum and not targetCalibrum.buff["aphelioscalibrumbonusrangedebuff"] then
        player:castSpell('pos', 1, game.mousePos)
        return true
    end
end

local function SevernumQ()
    local target = common.GetTarget(player.attackRange + player.boundingRadius)

    if target then 
        player:castSpell('pos', 0, game.mousePos)
    end
end 

local function ShouldGravitumQ()
    local targets = common.GetTarget(player.attackRange + player.boundingRadius + 100)

    if targets and targets ~= nil then 
        local hasTarget = false
        local shouldCast = true
        local dist = player.attackRange + player.boundingRadius
        if targets.buff['apheliosgravitumdebuff'] then
            hasTarget = true
        else
            if common.GetDistanceSqr(targets, player) <= dist * dist then
                shouldCast = false
            end
        end
        return hasTarget, shouldCast
    end 
end 

local function ShouldCrescendumQ()
    local targets = common.GetTarget(1000)

    if targets and targets ~= nil then 
        local delay = (0.06 + network.latency / 1000 + 0.25)
        local points = {}
        for _, point in pairs(points) do
            point[#point + 1] = pred.core.get_pos_after_time(targets, delay)
        end
        if common.GetDistanceSqr(player) <= 450 * 450 then
            return true
        end
    end 
end

local function NearEnemiesCount()
    local enemy = { }
    for i=0, objManager.enemies_n-1 do
        local obj = objManager.enemies[i]
        if obj and common.IsValidTarget(obj) then
            enemy[#enemy+1] = obj

        end         
    end 

    return enemy
end

local function InfernumQ()
    local target = common.GetTarget(600)
    if target and common.IsValidTarget(target) then 
        local angles = {}
        local basePosition = nil
        local res = pred.linear.get_prediction(preds.Infernum, target)
        if res then 
            if not basePosition then
                angles[1] = 0
                basePosition = vec3(res.endPos.x, target.pos.y, res.endPos.y)
            else
                angles[#angles + 1] = mathf.angle_between(player, basePosition, target)
            end
        end 
        local best = CalcBestCastAngle(angles)
        if best then
            local castPosition =
                (player.pos +
                (basePosition - player.pos):rotate(best):norm() *
                    (600 - 10))
            player:castSpell('pos', 0, basePosition)
        end
    end
end

local function PercentGun()
    for gun, cd in pairs(CD) do
        if game.time > cd then
            CD[gun] = nil
        end
    end
end 

local function CastR()
    if player:spellSlot(3).state == 0 then 

        local target = common.GetTarget(1500)

        if not target then 
            return 
        end 

        local maxTarget = nil
        local maxHit = 0
        local hit = 0 
        for i=0, objManager.enemies_n-1 do
            local obj = objManager.enemies[i]
            if obj and common.IsValidTarget(obj) then
                local pred = pred.core.get_pos_after_time(obj, network.latency / 1000 + 0.06)
                if target == obj or common.GetDistanceSqr(target, obj) <= 350 ^2 then 
                    hit = hit + 1
                end 
            end 

            if hit > maxHit then
                maxTarget = target
                maxHit = hit
            end
        end 

        if maxTarget  then
            local predr = pred.linear.get_prediction(preds.MoonLight, maxTarget)
            if predr and predr.startPos:distSqr(predr.endPos) <= (preds.MoonLight.range * preds.Calibrum.range) then
                local col = pred.collision.get_prediction(preds.MoonLight, predr, maxTarget)
        
                if col then
                    return 
                end
        
                local castPos = mathf.project(player.pos, maxTarget.pos, vec3(predr.endPos.x, maxTarget.pos.y, predr.endPos.y), preds.MoonLight.speed, maxTarget.moveSpeed)
        
                if castPos then 
                    player:castSpell('pos', 3, castPos)
                end
            end 
        end
    end 
end 

local function OnTick()
    if player.isDead then 
        return 
    end 

    if player.buff['apheliosseverumq'] then 
        orb.core.set_pause_attack(math.huge)
    else 
        orb.core.set_pause_attack(0)
    end 

    GetFuns()
    PercentGun()

    local target = common.GetTarget(1350)
    if target and common.GetDistanceSqr(target, player) <= 1300 ^ 2 and target.buff["aphelioscalibrumbonusrangedebuff"] then 
        player:attack(target)
    end

    if menu.aphe.rcombo:get() and menu.aphe.semiR:get() then
        player:move(mousePos)
        CastR()
    end

    if orb.menu.combat.key:get() then 
        if Guns.main == "Calibrum" then
            local targetCalibrum = common.GetTarget(1350)
            if targetCalibrum and not targetCalibrum.buff["aphelioscalibrumbonusrangedebuff"] and player:spellSlot(0).state == 0 then
                CalibrumQPred(targetCalibrum)
            elseif player:spellSlot(1).state == 0 then
                local target = orb.combat.target
                if target and target ~= nil then
                    local dist = player.attackRange + player.boundingRadius - 100
                    local targetPred = pred.core.get_pos_after_time(target, 0.5)
                    local myHeroPred = pred.core.get_pos_after_time(player, 0.5)
                    if common.GetDistanceSqr(targetPred, myHeroPred) <= dist * dist then
                        player:castSpell('pos', 1, game.mousePos)
                    end
                end
            end
        elseif Guns.main == "Severnum" then
            if Guns.off == "Calibrum" and player:spellSlot(1).state == 0 and CalibrumSwitch() then
                return
            elseif player:spellSlot(0).state == 0 then
                SevernumQ()
            else
                local target = orb.combat.target
                local useSpell = player:spellSlot(1).state == 0
                if useSpell then
                    if Guns.off == "Gravitum" and (not CD[Guns.off] and (ShouldGravitumQ() or target) or (target and not target.buff['apheliosgravitumdebuff'])) then
                        player:castSpell('pos', 1, game.mousePos)
                    elseif Guns.off == "Infernum" and not CD[Guns.off] and target then
                        player:castSpell('pos', 1, game.mousePos)
                    elseif Guns.off == "Crescendum" and not CD[Guns.off] and (ShouldCrescendumQ() or (target and common.GetDistanceSqr(target) <= 300 * 300)) then
                        player:castSpell('pos', 1, game.mousePos)
                    end
                end
            end
        elseif Guns.main == "Gravitum" then
            if Guns.off == "Calibrum" and player:spellSlot(1).state == 0 and CalibrumSwitch() then
                return
            elseif player:spellSlot(0).state == 0 then
                local hasTarget, shouldCast = ShouldGravitumQ()
                if shouldCast and hasTarget then
                    player:castSpell('pos', 0, game.mousePos)
                end
            else
                local target = orb.combat.target
                local useSpell = player:spellSlot(1).state == 0
                if target and target.buff['apheliosgravitumdebuff'] and useSpell then
                    player:castSpell('pos', 1, game.mousePos)
                end
            end
        elseif Guns.main == "Infernum" then
            if Guns.off == "Calibrum" and player:spellSlot(1).state == 0 and CalibrumSwitch() then
                return
            elseif player:spellSlot(0).state == 0 then
                InfernumQ()
            else
                local target = orb.combat.target
                local useSpell = player:spellSlot(1).state == 0
                if useSpell then
                    if Guns.off == "Severnum" and target and (CD[Guns.off] or player.health / player.maxHealth < 0.30) then
                        player:castSpell('pos', 1, game.mousePos)
                    elseif Guns.off == "Gravitum" and  (not CD[Guns.off] and (ShouldGravitumQ() or target) or (target and not target.buff['apheliosgravitumdebuff'])) then
                        player:castSpell('pos', 1, game.mousePos)
                    elseif Guns.off == "Crescendum" and ((ShouldCrescendumQ() and not CD[Guns.off]) or #NearEnemiesCount() <= 2 or (target and common.GetDistanceSqr(target) <= 300 * 300)) then
                        player:castSpell('pos', 1, game.mousePos)
                    end
                end
            end
        elseif Guns.main == "Crescendum" then
            if Guns.off == "Calibrum" and player:spellSlot(1).state == 0 and CalibrumSwitch() then
                return
            else
                local _, castPos = ShouldCrescendumQ()
                if player:spellSlot(0).state == 0 and castPos then
                    player:castSpell('pos', 0, castPos)
                else
                    local target = orb.combat.target
                    local useSpell = player:spellSlot(1).state == 0
                    if useSpell then
                        if
                            Guns.off == "Severnum" and
                                (not CD[Guns.off] or player.health / player.maxHealth < 0.3) and
                                target
                         then
                                player:castSpell('pos', 1, game.mousePos)
                        elseif
                            Guns.off == "Gravitum" and
                                (not CD[Guns.off] and (ShouldGravitumQ() or target) or
                                    (target and not target.buff['apheliosgravitumdebuff']))
                         then
                                player:castSpell('pos', 1, game.mousePos)
                        elseif
                            Guns.off == "Infernum" and target and
                                (not CD[Guns.off] or #NearEnemiesCount() > 2)
                         then
                                player:castSpell('pos', 1, game.mousePos)
                        end
                    end
                end
            end
        end
    end 
end 

local function OnProcessSpell(spell)
    --local spell = spell 
    local obj = spell.owner

    if spell.owner == player and spell.name == 'ApheliosW' then
        local cd = player:spellSlot(0).cooldown
        if cd > 0 then
            CD[Guns.main] = game.time + cd
        end
    end 
end 

local OnDraw = function()
    if (player and player.isDead and not player.isTargetable and player.buff[17]  and not player.isOnScreen) then 
        return 
    end
    

    if menu.aphe.qdraw:get() then
        if player:spellSlot(3).state == 0 then 
            graphics.draw_circle(player.pos, 1300, 1, menu.aphe['qcolor']:get(), 100)
        end
        if player:spellSlot(0).name == 'ApheliosInfernumQ' and player:spellSlot(0).state == 0 then 
            graphics.draw_circle(player.pos, 650, 1, menu.aphe['qcolor']:get(), 100)
        end
        if player:spellSlot(0).name == 'ApheliosCrescendumQ' and player:spellSlot(0).state == 0 then 
            graphics.draw_circle(player.pos, 475, 1, menu.aphe['qcolor']:get(), 100)
        end
        if player:spellSlot(0).name == 'ApheliosCalibrumQ ' and player:spellSlot(0).state == 0 then 
            graphics.draw_circle(player.pos, 1450, 1, menu.aphe['qcolor']:get(), 100)
        end
    end

end


orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.spell, OnProcessSpell)
cb.add(cb.draw, OnDraw)

cb.add(cb.error, function(msg)
    local log, e = io.open(hanbot.path..'/MARKSMANSHDH.txt', 'w+')
    if not log then
      print(e)
      return
    end
    log:write(msg)
    log:close()
end)