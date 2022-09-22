local orb = module.internal("orb")
local TS = module.internal('TS');
local pred = module.internal('pred')
local common = module.load(header.id, "Library/common")
local GeomLib = module.load(header.id, "Geometry/GeometryLib")
local Vector = GeomLib.Vector 
local Samaritan = {}

local spells = {
    Q = {
        type = "Linear",
        delay = 0.25,
        speed = math.huge, -- 2000
        range = 400, --450
        width = 120,

        prediction_input = {
            range = 400;
            delay = 0.25; 
            width = 120;
            speed = 1600;
            boundingRadiusMod = 0; 
            collision = {
                hero = false,
                minion = false,
                wall = false
            }
        }
    },
    Q2 = {
        type = "Linear",
        delay = 0.25,
        speed = 1600,
        range = 850, -- Full Range --900
        rangeSecondHalf = 300, --400
        width = 165, --150

        prediction_input = {
            range = 850;
            delay = 0.25; 
            width = 165;
            speed = 1600;
            boundingRadiusMod = 0; 
            collision = {
                hero = false,
                minion = false,
                wall = false
            }
        }
    },
    W = {
        type = "Targetted",
        delay = 0,
        range = 1100 --1100
    },
    E = {
        type = "Targetted",
        delay = 0,
        range = 640,
    },
    R = {
        type = "Linear",
        delay = 0.25,
        speed = 2000,
        range = 950, --950
        width = 280,
        pushRange = 300, --320

        prediction_input = {
            range = 950;
            delay = 0.25; 
            width = 280;
            speed = 2000;
            boundingRadiusMod = 0; 
            collision = {
                hero = false,
                minion = false,
                wall = false
            }
        }
    }
}

local Damages = {
    Passive = {
        BaseDamages = function(heroLevel)
            return 11 + 4 * heroLevel
        end,
        BonusAD = 0.55,
        TotalAP = 0.3,
    },
    Q = {
        BaseDamages = {60, 85, 110, 135, 160},
        BonusAD = 0.9,
        RockExtra = {
            MaxEnemyHPPercent = 50,
            BaseDamages = {36, 51, 66, 81, 96},
            BonusAD = 0.54
        }
    },
    W = {
        BaseDamages = {8, 16, 24, 32, 40},
        BonusAD = 0.2,
        TotalAP = 0.3,
    },
    E = {
        BaseDamages = {60, 95, 130, 165, 200},
        BonusAD = 0.7,
    },
    R = {
        BaseDamages = {100, 170, 240},
        BonusAD = 1.7,
        TargetMaxHealth = 0.1,
    }
}

local Targets = {
    Q = {unit = nil, pred = nil},
    W = {unit = nil, pred = nil},
    E = {unit = nil, pred = nil},
    R = {unit = nil, pred = nil},
}

local River = {
    Top = {
        {3048, -25.488565444946, 11904},
        {3430, -63.276065826416, 11726},
        {3736, -60.225284576416, 11522},
        {3784, -70.918266296387, 10944},
        {3850, -78.907920837402, 10552},
        {4346, -71.240600585938, 10128},
        {4514, -71.240600585938, 10142},
        {4574, -71.240600585938, 10284},
        {4484, -71.240600585938, 10536},
        {4654, -71.240600585938, 10750},
        {5052, -78.487075805664, 10862},
        {5356, -71.240600585938, 10646},
        {5362, -71.240600585938, 10238},
        {5182, -71.240600585938, 10016},
        {4924, -71.240600585938, 9996},
        {4840, -70.387908935547, 9820},
        {5096, -69.851135253906, 9668},
        {5516, -71.181427001953, 9474},
        {6072, -68.877799987793, 9326},
        {6288, -71.240600585938, 9062},
        {6326, -71.240600585938, 8938},
        {7016, -71.240600585938, 8364},
        {6448, -49.922626495361, 7896},
        {5866, -70.283508300781, 8328},
        {5298, -65.726959228516, 8572},
        {4790, -44.610748291016, 8716},
        {4768, -69.819557189941, 8890},
        {4274, -66.105194091797, 9116},
        {3900, -67.920196533203, 9442},
        {3770, -1.6699202060699, 9204},
        {3522, -65.373352050781, 9790},
        {3358, -65.332664489746, 10254},
        {3160, -67.455421447754, 10710},
        {2738, -43.222412109375, 11498},
        {2666, -7.1835269927979, 11688},
        {2866, 7.1607427597046, 11910}
    },
    TopPoly = nil,

    Bottom = {
        {7920, -68.054618835449, 6308},
        {8450, -71.240600585938, 6844},
        {9364, -71.240600585938, 6308},
        {10016, -16.135112762451, 6238},
        {10046, -71.240600585938, 5996},
        {10746, -62.810199737549, 5482},
        {11034, -70.854095458984, 5402},
        {11446, -71.240600585938, 4810},
        {11806, -71.240600585938, 4302},
        {11950, -66.245162963867, 3518},
        {11356, -68.348770141602, 3152},
        {10992, -46.506671905518, 3430},
        {11070, -71.240600585938, 4044},
        {10914, -71.240600585938, 4338},
        {10392, -69.378196716309, 4818},
        {10238, -71.240600585938, 4672},
        {10284, -71.240600585938, 4282},
        {10074, -71.240600585938, 3958},
        {9680, -70.833366394043, 3964},
        {9364, -71.240600585938, 4408},
        {9500, -71.240600585938, 4676},
        {10014, -71.240600585938, 4878},
        {10090, -68.042984008789, 5070},
        {9954, -66.324920654297, 5226},
        {9798, -70.990257263184, 5190},
        {9354, -71.240600585938, 5450},
        {8824, -71.240600585938, 5622},
        {8590, -71.240600585938, 5970},
        {8336, -71.240600585938, 6054}
    },
    BottomPoly = nil
}

local menu = menu("IntnnerQiyana", "Int - Qiyana")
menu:header("core", "Core") --:keybind("semi_r", "Manual R", "T", nil)
menu:keybind("semi_r", "Force R against wall", "T", nil)
menu:keybind('switchW', 'W - Switch Key', 'A', nil)
menu.switchW:set('callback', function(var)
    if menu.combo.useW:get() == 1 and var then
        menu.combo.useW:set("value", 2)
        return
    end
    if menu.combo.useW:get() == 2 and var then
        menu.combo.useW:set("value", 3)
        return
    end
    if menu.combo.useW:get() == 3 and var then
        menu.combo.useW:set("value", 1)
        return
    end
end)
menu:keybind('switchDir', 'Direction - Switch Key', 'K', nil)
menu.switchDir:set('callback', function(var)
    if menu.combo.useWDir:get() == 1 and var then
        menu.combo.useWDir:set("value", 2)
        return
    end
    if menu.combo.useWDir:get() == 2 and var then
        menu.combo.useWDir:set("value", 1)
        return
    end
end)
menu:keybind('switchPrio', 'Priority - Switch Key', 'G', nil)
menu.switchPrio:set('callback', function(var)
    if menu.combo.useWPrio:get() == 1 and var then
        menu.combo.useWPrio:set("value", 2)
        return
    end
    if menu.combo.useWPrio:get() == 2 and var then
        menu.combo.useWPrio:set("value", 3)
        return
    end
    if menu.combo.useWPrio:get() == 3 and var then
        menu.combo.useWPrio:set("value", 1)
        return
    end
end)
menu:keybind('switchmethod', 'Method - Switch Key', 'Z', nil)
menu.switchmethod:set('callback', function(var)
    if menu.combo.mechW.method:get() == 1 and var then
        menu.combo.mechW.method:set("value", 2)
        return
    end
    if menu.combo.mechW.method:get() == 2 and var then
        menu.combo.mechW.method:set("value", 1)
        return
    end
end)
menu:header("ha", "Qiyana - Settings")
--Combo
menu:menu("combo", "Combo Settings")
menu.combo:header("xd1", "Q - Edge of Ixtal") 
menu.combo:boolean("use.Q", "Use Q in Combo", true)
--W 
menu.combo:header("XD2", "W - Terrashape") 
menu.combo:boolean("use.W", "Use W in Combo", true)
menu.combo:dropdown("useW", "Use W", 1, {"Reset Q", "Always"})
menu.combo:dropdown("useWDir", "^~ Cast it towards", 2, {"Target", "Mouse"})
menu.combo:dropdown("useWPrio", "^~ Element to prioritize", 2, {"Brush", "River", "Terrain"})
menu.combo:slider("useWOverride", "^~ Force Terrain if target HP% <", 50, 5, 100, 5)
--Mecha 
menu.combo:header("XD23", "W - Mechanics") 
menu.combo:menu("mechW", "W - Mechanics")
menu.combo.mechW:dropdown("method", "Method:", 2, {"Distance", "Prediction"})
menu.combo.mechW:slider("targetConeArea", "Hitchance Towards target", 20, 1, 90, 1)
menu.combo.mechW:slider("radiusChecks", "How many checkpoints", 10, 5, 15, 5) -- menu.combo.r:keybind('switch', 'Mode Switch Key', 'K', nil)
menu.combo.mechW:slider("circChecks", "Dot size", 15, 5, 20, 5)
menu.combo.mechW:slider("Min.", "Min. enemies in range", 1, 1, 5, 1)
--E 
menu.combo:header("XD3", "E - Audacity") 
menu.combo:boolean("use.E", "Use E in Combo", true)
menu.combo:boolean("safe", "Use E under Turret", true)
--R
menu.combo:header("XD4", "R - Supreme Display of Talent") 
menu.combo:boolean("use.R", "Use R in Combo", true)
menu.combo:slider("stun", "^~ Stun min X enemies", 2, 1, 5, 1)
menu.combo:boolean("Dashing",   "Use W/R while dashing", true)
--Harras 
menu:menu("harass", "Harass Settings")
menu.harass:header("xd1", "Q - Edge of Ixtal") 
menu.harass:boolean("use.Q", "Use Q", true)
menu.harass:header("XD2", "W - Terrashape") 
menu.harass:boolean("use.W", "Use W", true)
menu.harass['use.W']:set("tooltip", "the logic of W in harass applies to the combo settings")
menu.harass:header("s3ad", "Orthes") 
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 50, 1, 100, 1)
--Miscellaneous
menu:menu("misc", "Miscellaneous Settings")
menu.misc:boolean("useQ", "Use Q with killable", true)
menu.misc:boolean("useE", "Use E with killable", false)
menu.misc:boolean("useR", "Use R with killable", true)
menu.misc:header("s3ad", "Orthes") 
menu.misc:boolean("DisableAA", "Disable AA while invisible burst", true)
menu.misc:boolean("disablecombo", "^~ Disable Combo while invisible", false)
menu.misc:slider("min_enemies", "Min. Enemies Percent >= {0}", 1, 1, 5, 1)
menu.misc:slider("min_range", "Dist. Enemies in Range >= {0}", 650, 10, 1000, 10)
--Draws
menu:menu("draws", "Drawings Settings");
menu.draws:boolean("qd", "Q Range", true)
menu.draws:boolean("wd", "W Range", true)
menu.draws:boolean("ed", "E Range", true)
menu.draws:boolean("rd", "R Range", true)
menu.draws:header("s3ad", "Orthes") 
menu.draws:boolean("toggle", "Drawings Toggles", true)

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
    return object and not object.isDead and object.isVisible and object.team ~= player.team and not object.buff[string.lower'SionPassiveZombie']
    and not object.buff[string.lower'KarthusDeathDefiedthen'] 
    and not object.buff[string.lower'KarthusDeathDefiedBuff']
    and not object.buff['fioraw'] 
    and not object.buff['sivire'] and not object.buff["kogmawicathiansurprise"]
    and not object.buff['nocturneshroudofdarkness'] 
    and (not distanceSqr or common.GetDistanceSqr(object) <= distanceSqr * distanceSqr) 
    and common.IsEnemyMortal(object) 
    and (not delay and not speed or IsValidTimer(object) < (common.GetDistance(player.pos, object.pos) / speed + delay / 1000) * 1000)
end 

local dmgValues = Damages
local dmgP = dmgValues.Passive
local dmgQ = dmgValues.Q
local dmgW = dmgValues.W
local dmgE = dmgValues.E
local dmgR = dmgValues.R

local function GetDamage(target, spellSlot)
    local rawDamage = 0
    local dmgType = 1

    local spellLevel = type(spellSlot) == "number" and player:spellSlot(spellSlot).level or 0
    local heroLevel = math.min(18, player.levelRef)

    local charInter = player
    local myBonusAD = charInter.flatPhysicalDamageMod
    local myAD = charInter.baseAttackDamage + myBonusAD
    local myAP = charInter.baseAbilityDamage + charInter.flatMagicDamageMod

    if spellSlot == "Passive" then
        rawDamage = dmgP.BaseDamages(heroLevel) + (dmgP.BonusAD * myBonusAD) + (dmgP.TotalAP * myAP)
        dmgType = 1

    elseif spellSlot == 0 then
        rawDamage = dmgQ.BaseDamages[spellLevel] + (dmgQ.BonusAD * myBonusAD)
        if common.GetPercentHealth(target) < dmgQ.RockExtra.MaxEnemyHPPercent then
            rawDamage = rawDamage + dmgQ.RockExtra.BaseDamages[spellLevel] + (dmgQ.RockExtra.BonusAD * myBonusAD)
        end
        dmgType = 1

    elseif spellSlot == 1 then
        rawDamage = dmgW.BaseDamages[spellLevel] + (dmgW.BonusAD * myBonusAD) + (dmgW.TotalAP * myAP)
        dmgType = 2

    elseif spellSlot == 2 then
        rawDamage = dmgE.BaseDamages[spellLevel] + (dmgE.BonusAD * myBonusAD)
        dmgType = 1

    elseif spellSlot == 3 then
        rawDamage = dmgR.BaseDamages[spellLevel] + (dmgR.BonusAD * myBonusAD) + (dmgR.TargetMaxHealth *  common.GetPercentHealth(target) )
        dmgType = 1
    end

    if dmgType == 1 then
        return common.CalculatePhysicalDamage(target, rawDamage, player)
    elseif dmgType == 2 then
        return common.CalculateMagicDamage(target, rawDamage, player)
    else
        return rawDamage
    end
end


local function GetPosAfterDash(target)
    return player.path.serverPos + (target.path.serverPos - player.path.serverPos):norm() * spells.E.range
end

local function GetSafe(target) 
    return not target.buff['jaxcounterstrike'] and not target.buff['galiow'] 
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

local function trace_filter(seg, obj)
    if seg.startPos:dist(seg.endPos) > spells.Q2.prediction_input.range then return false end

    if pred.trace.linear.hardlock(spells.Q2.prediction_input, seg, obj) then
        return true
    end
    if pred.trace.linear.hardlockmove(spells.Q2.prediction_input, seg, obj) then
        return true
    end
    if pred.trace.newpath(obj, 0.033, 0.500) then
        return true
    end
end

local function target_resultQ1(res, obj, dist)
    if dist > spells.Q.range then 
        return 
    end 

    local seg = pred.linear.get_prediction(spells.Q.prediction_input, obj, vec2(player.x, player.z))
    if not seg then 
        return false 
    end
    local castPos = mathf.project(player.pos, vec3(seg.endPos.x, obj.pos.y, seg.endPos.y), obj.direction, spells.Q.speed, obj.moveSpeed)
    if not castPos then 
        return false
    end 

    res.obj = obj 
    res.pos = castPos
    return true
end

local function target_resultQ2(res, obj, dist)
    if dist > spells.Q2.range then 
        return 
    end 

    local seg = pred.linear.get_prediction(spells.Q2.prediction_input, obj, vec2(player.x, player.y))
    if not seg then 
        return false 
    end

    if trace_filter(seg, obj) then 
        return true 
    end

    res.obj = obj 
    res.pos = vec3(seg.endPos.x, obj.pos.y, seg.endPos.y)
    return true
end 

local function target_resultW(res, obj, dist)
    if dist > spells.W.range then 
        return 
    end 

    res.obj = obj 
    return true 
end 

local function target_resultE(res, obj, dist)
    if dist > spells.E.range then 
        return 
    end 

    res.obj = obj 
    return true 
end 

local function target_resultR(res, obj, dist)
    if dist > spells.R.range then 
        return 
    end 

    local seg = pred.linear.get_prediction(spells.R.prediction_input, obj, vec2(player.x, player.y))
    if not seg then 
        return false 
    end


    res.obj = obj 
    res.pos = vec3(seg.endPos.x, obj.pos.y, seg.endPos.y)
    return true
end 

local function GetTargets()
    if player:spellSlot(0).name == "QiyanaQ" then 
        Targets.Q.unit = TS.get_result(target_resultQ1)
    else 
        Targets.Q.unit = TS.get_result(target_resultQ2)
    end 

    Targets.W.unit = TS.get_result(target_resultW)
    Targets.E.unit = TS.get_result(target_resultE)
    Targets.R.unit = TS.get_result(target_resultR)
end 

local function LoadRiverPolygons()
    local tempTop = {}
    local tempBottom = {}

    for i=1, #River.Top do
        local curElement = River.Top[i]
        tempTop[i] = GeomLib.Vector:new(curElement[1], curElement[2], curElement[3])
    end

    for i=1, #River.Bottom do
        local curElement = River.Bottom[i]
        tempBottom[i] = GeomLib.Vector:new(curElement[1], curElement[2], curElement[3])
    end

    River.TopPoly = GeomLib.Polygon:new(unpack(tempTop))
    River.BottomPoly = GeomLib.Polygon:new(unpack(tempBottom))
end

local function IsRiver(point)
    local vector = GeomLib.Vector:new(point)
    return vector:insideOf(River.TopPoly) or vector:insideOf(River.BottomPoly)
end

local function GetPointType(point)
    if navmesh.isWall(point) then
        return "Terrain"
    elseif navmesh.isGrass(point) then
        return "Brush"
    elseif IsRiver(point) then
        return "River"
    else
        return "None"
    end
end

local function ShouldCastWhileDashing()
    local useWRDashing = menu.combo['Dashing']:get()
    return player.path.isDashing and useWRDashing or not player.path.isDashing
end

local maxRChecks = 6
local function WillRStun(target)
    if target then
        local vecCP = GeomLib.Vector:new(Targets.R.unit.pos)
        local vecMyPos = GeomLib.Vector:new(player.pos)

        local distToCP = vecMyPos:dist(vecCP)

        local finalExtended = vecMyPos:extended(vecCP, distToCP + spells.R.pushRange + 25)

        local interval = vecCP:dist(finalExtended) / maxRChecks
        for i = 1, maxRChecks do
            local posToCheck = vecCP:extended(finalExtended, interval * i)
            if GetPointType(posToCheck:toDX3()) ~= "None" then
                return true
            end
        end
    end
    return false
end

local function DegToRad(deg)
    return (deg * math.pi) / 180
end

local function RadToDeg(rad)
    return (rad / math.pi) * 180
end

local function IsOutside(point, cone)
    local center, direction, angle, radius = cone.center, cone.direction, cone.angle, cone.radius

    if center:dist(point) > radius then return true end

    local halfAngle = RadToDeg(angle * 0.5)
    halfAngle = angle * 0.5

    local pointSegment = point - center
    if direction:angle(pointSegment) <= halfAngle then
        return false
    end

    return true
end

local function IsInside(point, cone)
    return not IsOutside(point, cone)
end

local function GetWLinearPositions(from, radiusC, points, coneInfo)
    local result = {}

    local coneRadius = coneInfo.radius
    local interval = coneRadius / radiusC

    for r = interval, coneRadius, interval do
        local rPoints = 2 * math.pi / points
        local theta = 0
        while theta < 2 * math.pi + rPoints do
            local possiblePoint = vec3(from.x + r * math.cos(theta), from.y, from.z + r * math.sin(theta))
            local vecPoint = GeomLib.Vector:new(possiblePoint)

            if IsInside(vecPoint, coneInfo) then
                result[#result+1] = possiblePoint
            end

            theta = theta + rPoints
        end
    end

    return result
end

local PosRadius = spells.W.range / 7 / 2
local function GetWUniformPositions(from, maxPosToCheck, coneInfo)
    local result = {}

    local posChecked, radiusIndex, posRadius = 0, 0, PosRadius --150 15

    while posChecked < maxPosToCheck do
        radiusIndex = radiusIndex + 1

        local curRadius = radiusIndex * 2 * posRadius
        local curCircleChecks = math.ceil(math.pi * curRadius / posRadius)
        for i = 1, curCircleChecks-1 do
            posChecked = posChecked + 1
            local cRadians = (2 * math.pi / (curCircleChecks - 1)) * i

            local possiblePoint = vec3(from.x + curRadius * math.cos(cRadians), from.y, from.z + curRadius * math.sin(cRadians))
            local vecPoint = GeomLib.Vector:new(possiblePoint)

            if IsInside(vecPoint, coneInfo) then
                result[#result+1] = possiblePoint
            end
        end
    end

    return result
end

local function GetBestWPos()
    local prio = menu.combo.useWPrio:get()
    local dir = menu.combo.useWDir:get()
    local overrideAmt = menu.combo.useWOverride:get()
    local analysisMethod = menu.combo.mechW.method:get()
    local coneAngle = menu.combo.mechW.targetConeArea:get()

    local prioString = nil

    local from = player.pos
    local to = mousePos

    local wTarget = Targets.W.unit.obj
    if not wTarget then
        return 
    end

    if dir == 1 and wTarget then
        to = wTarget.pos
    end

    local vecCenter = GeomLib.Vector:new(from)
    local vecTo = GeomLib.Vector:new(to)
    local coneData = {
        center = vecCenter,
        direction = (vecTo - vecCenter):normalized(),
        angle = DegToRad(coneAngle),
        radius = spells.W.range
    }

    local pointsToAnalyse = {}

    if analysisMethod == 1 then
        local radiusC = menu.combo.mechW.radiusChecks:get()
        local circumferenceC = menu.combo.mechW.circChecks:get()
        pointsToAnalyse = GetWLinearPositions(from, radiusC, circumferenceC, coneData)
    elseif analysisMethod == 2 then
        pointsToAnalyse = GetWUniformPositions(from, 150, coneData)
    end

    if prio == 1 then
        prioString = "Brush"
    elseif prio == 2 then
        prioString = "River"
    elseif prio == 3 then
        prioString = "Terrain"
    end

    if wTarget and common.GetPercentHealth(wTarget) < overrideAmt then
        prioString = "Terrain"
    end

    local fallbackPoint = nil
    for i = #pointsToAnalyse, 1, -1 do
        local currentPoint = pointsToAnalyse[i]
        local pointType = GetPointType(currentPoint)

        if pointType ~= "None" and fallbackPoint == nil then
            fallbackPoint = currentPoint
        end

        if pointType == prioString then
            return currentPoint
        end
    end

    return fallbackPoint
end

local function CanQ2Hit(target)
    if not target then 
        return 
    end
    local seg = pred.linear.get_prediction(spells.Q2.prediction_input, target, vec2(player.x, player.z))
    if target and seg then
        local minionCollision = pred.collision.get_prediction(spells.Q2.prediction_input, seg, target)
        if not minionCollision then
            return true
        end

        for i=1,#minionCollision do
            local colPos = minionCollision[1]
            local vecMinionPos = GeomLib.Vector:new(vec3(colPos.x, colPos.y, colPos.z))
    
            local vecMyPos = GeomLib.Vector:new(player.pos)
            local targetPos = GeomLib.Vector:new(target.pos)
            local segment = GeomLib.LineSegment:new(vecMyPos, targetPos)
    
            local closestToCol = segment:closest(vecMinionPos)
            return closestToCol:dist(targetPos) < spells.Q2.rangeSecondHalf
        end
    end
    return false
end


local function CastE(target)
    if not target then 
        return 
    end 

    player:castSpell("obj", 2, target)
    return true
end 

local function CastR(target)
    if not target then 
        return 
    end 

    if Targets.R.unit.obj and IsValidTarget(Targets.R.unit.obj) then 
        if Targets.R.unit.pos then 
            player:castSpell("pos", 3, Targets.R.unit.pos)
            return true
        end 
    end 
end 

local function CastW(pos)
    player:castSpell("pos", 1, pos)
    return true
end 

local function CastQ(target)
    if not target then 
        return 
    end 

    if Targets.Q.unit.obj and IsValidTarget(Targets.Q.unit.obj) then 
        if Targets.Q.unit.pos then 
            player:castSpell("pos", 0, Targets.Q.unit.pos)
            orb.core.set_server_pause()
            return true
        end 
    end 
end 


local function Combo()
    local target = Targets 


    if menu.combo['use.E']:get() and player:spellSlot(2).state == 0 and target.E.unit.obj then 
        if target.E.unit.obj ~= nil and IsValidTarget(target.E.unit.obj) and GetSafe(target.E.unit.obj) and common.GetDistance(target.E.unit.obj, GetPosAfterDash(target.E.unit.obj)) <= common.GetAARange(player) then 
            if (menu.combo.safe:get() or not UnderTurret(GetPosAfterDash(target.E.unit.obj))) then 
                CastE(target.E.unit.obj)
                return
            end
        end
    end 

    if menu.combo['use.R']:get() and player:spellSlot(3).state == 0 and target.R.unit.obj then
        if target.R.unit.obj ~= nil and IsValidTarget(target.R.unit.obj) then 
            if #common.CountEnemiesInRange(target.R.unit.obj.pos, 175) >= menu.combo['stun']:get() and WillRStun(target) then 
                CastR(target)
                return
            end 
        end 
    end 

    if menu.combo['use.W']:get() and player:spellSlot(1).state == 0 and player:spellSlot(0).name == "QiyanaQ" then
        local extraQCheck = function()
            return (player:spellSlot(0).state ~= 0) and (player:spellSlot(0).level >= 1)
        end

        if ((menu.combo['useW']:get() == 1 and extraQCheck()) or menu.combo['useW']:get() == 2) and ShouldCastWhileDashing() then
            local bestWPos = GetBestWPos()
            if bestWPos then
                CastW(bestWPos)
                return
            end
        end
    end
    
    if menu.combo['use.Q']:get() and player:spellSlot(0).state == 0 then
        if target.Q.unit.obj and IsValidTarget(target.Q.unit.obj) then 
            if player:spellSlot(0).name ~= "QiyanaQ" then 
                if CanQ2Hit(target.Q.unit.obj) then 
                    CastQ(target)
                    return
                end
            else 
                CastQ(target)
                return
            end 
        end 
    end
end 

local function ForceRStun()
    if player:spellSlot(3).state == 0 and Targets.R.unit.obj then
        if Targets.R.unit.obj ~= nil and IsValidTarget(Targets.R.unit.obj) then 
            if WillRStun(Targets) then 
                CastR(Targets)
                return
            end
        end
    end
end

local function Harass()
    if common.GetPercentMana(player) < menu.harass.Mana:get() then 
        return 
    end     

    local target = Targets

    if menu.harass['use.W']:get() and player:spellSlot(1).state == 0 then
        local extraQCheck = function()
            return (player:spellSlot(0).state ~= 0) and (player:spellSlot(0).level >= 1)
        end

        if ((menu.combo['useW']:get() == 1 and extraQCheck()) or menu.combo['useW']:get() == 2) and ShouldCastWhileDashing() then
            local bestWPos = GetBestWPos()
            if bestWPos then
                CastW(bestWPos)
                return
            end
        end
    end

    if menu.harass['use.Q']:get() and player:spellSlot(0).state == 0 then
        if target.Q.unit.obj and IsValidTarget(target.Q.unit.obj) then 
            if player:spellSlot(0).name ~= "QiyanaQ" then 
                if CanQ2Hit(target.Q.unit.obj) then 
                    CastQ(target)
                    return
                end
            else 
                CastQ(target)
                return
            end 
        end 
    end
end 

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and IsValidTarget(target) and common.IsEnemyMortal(target) then
            local enemyHealth = common.GetShieldedHealth("ALL", target)

            if menu.misc['useQ']:get() and player:spellSlot(0).state == 0 then
                if player:spellSlot(0).name == "QiyanaQ" then
                    if common.GetDistance(target) < spells.Q.range and (GetDamage(target, 0) > enemyHealth) then
                        CastQ(target)
                        return
                    end
                else
                    if common.GetDistance(target) < spells.Q2.range and (GetDamage(target, 0) > enemyHealth) then
                        CastQ(target)
                        return
                    end
                end
            end 

            if menu.misc['useE']:get() and player:spellSlot(2).state == 0 then
                if target ~= nil and IsValidTarget(target) and GetSafe(target) then 
                    if (GetDamage(target, 2) > enemyHealth + 150) then 
                        CastE(target)
                        return
                    end
                end
            end

            if menu.misc['useR']:get() and player:spellSlot(3).state == 0 then
                if common.GetDistance(target) < spells.R.range and (GetDamage(target, 3) > enemyHealth) then
                    if WillRStun(Targets) then
                        CastR(target)
                        return
                    end
                end
            end
        end 
    end
end

local function on_tick()
    if player.isDead then 
        return 
    end 

    GetTargets()
    LoadRiverPolygons()
    KillSteal()

    if menu.semi_r:get() then 
        player:move(mousePos)
        ForceRStun()
    end 

    if menu.misc['DisableAA']:get() then 
        if player.buff['qiyanaq_grass_stealth_buff'] and #common.CountEnemiesInRange(player.pos, menu.misc['min_range']:get()) >= menu.misc['min_enemies']:get() then 
            orb.core.set_pause_attack(math.huge)
        else 
            orb.core.set_pause_attack(0)
        end 
    end 

    if (orb.menu.combat.key:get()) then
        if not player.buff['qiyanaq_grass_stealth_buff'] or not menu.misc['disablecombo']:get() then 
            Combo()
        end
    end 

    if (orb.menu.hybrid.key:get()) then 
        Harass()
    end 
end 

local function on_draw()
    if player.isDead and not player.isTargetable and  player.buff[17] then 
        return 
    end 

    if not (player.isOnScreen) then
        return 
    end 

    local color = (player:spellSlot(0).name == "QiyanaQ_Grass" and graphics.argb(255,50,205,50)) or 
    (player:spellSlot(0).name == "QiyanaQ_Water" and graphics.argb(255,127,255,212)) or (player:spellSlot(0).name == "QiyanaQ_Rock" and graphics.argb(255, 185, 139, 86)) or graphics.argb(255, 255,255,255)

    if menu.draws['qd']:get() and player:spellSlot(0).state == 0 then 
        graphics.draw_circle(player.pos, spells.Q.range, 1, color, 100)
    end 

    if menu.draws['wd']:get() and player:spellSlot(1).state == 0 then
        graphics.draw_circle(player.pos, spells.W.range, 1, color, 100)
    end

    if menu.draws['ed']:get() and player:spellSlot(2).state == 0 then
        graphics.draw_circle(player.pos, spells.E.range, 1, color, 100)
    end

    if menu.draws['rd']:get() and player:spellSlot(3).state == 0 then
        graphics.draw_circle(player.pos, spells.R.range, 1, color, 100)
    end

    --[[    if Targets.Q.unit.obj and IsValidTarget(Targets.Q.unit.obj) then 
        if Targets.Q.unit.pos then 
            graphics.draw_circle(vec3(Targets.Q.unit.pos.x, mousePos.y, Targets.Q.unit.pos.y), Targets.Q.unit.obj.boundingRadius, 1, graphics.argb(255, 255,255,255), 100)
        end
        --graphics.draw_circle(Targets.Q.unit.obj.pos, Targets.Q.unit.obj.boundingRadius, 1, graphics.argb(255, 255,255,255), 100)
    end ]]

    if menu.draws.toggle:get() then
        local pos = graphics.world_to_screen(player.pos)
        if menu.combo.useW:get() == 1 then
            graphics.draw_text_2D("[" .. menu.switchW.key .. "]W Mode: Reset Q", 20, pos.x - 70, pos.y + 65, graphics.argb(255, 0, 255, 0))
        end
        if menu.combo.useW:get() == 2 then
            graphics.draw_text_2D("[" .. menu.switchW.key .. "]W Mode: Always", 20, pos.x - 70, pos.y + 65, graphics.argb(255, 0, 255, 0))
        end
        if menu.combo.useW:get() == 3 then
            graphics.draw_text_2D("[" .. menu.switchW.key .. "]W Mode: Disabled", 20, pos.x - 70, pos.y + 65, graphics.argb(255, 255, 0, 0))
        end
        --Dir
        if menu.combo.useWDir:get() == 1 then
            graphics.draw_text_2D("[" .. menu.switchDir.key .. "]Direction: Target", 20, pos.x - 70, pos.y + 90, graphics.argb(255, 0, 255, 0))
        end
        if menu.combo.useWDir:get() == 2 then
            graphics.draw_text_2D("[" .. menu.switchDir.key .. "]Direction: Mouse", 20, pos.x - 70, pos.y + 90, graphics.argb(255, 0, 255, 0))
        end
        --Swift 
        if menu.combo.useWPrio:get() == 1 then
            graphics.draw_text_2D("[" .. menu.switchPrio.key .. "]Priority: Brush", 20, pos.x - 70, pos.y + 115, graphics.argb(255,50,205,50))
        end
        if menu.combo.useWPrio:get() == 2 then
            graphics.draw_text_2D("[" .. menu.switchPrio.key .. "]Priority: River", 20, pos.x - 70, pos.y + 115, graphics.argb(255,127,255,212))
        end
        if menu.combo.useWPrio:get() == 3 then
            graphics.draw_text_2D("[" .. menu.switchPrio.key .. "]Priority: Terrain", 20, pos.x - 70, pos.y + 115,  graphics.argb(255, 185, 139, 86))
        end
        --Method 
        if menu.combo.mechW.method:get() == 1 then
            graphics.draw_text_2D("[" .. menu.switchmethod.key .. "]Method: Distance", 20, pos.x - 70, pos.y + 135, graphics.argb(255, 0, 255, 0))
        end
        if menu.combo.mechW.method:get() == 2 then
            graphics.draw_text_2D("[" .. menu.switchmethod.key .. "]Method: Prediction", 20, pos.x - 70, pos.y + 135, graphics.argb(255, 0, 255, 0))
        end
    end
end 

orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.draw, on_draw)