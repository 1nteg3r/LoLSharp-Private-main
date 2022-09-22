local common = module.load(header.id, "Library/common");
local orb = module.internal("orb")

local ImmobileHandler 	= {}
local SlowHandler     	= {}
local DashHandler     	= {}
local AutoAttackHandler  = {}
local SpellHandler 	= {}
local DontShoot          = {}

local buffer = 0.02

local DashSpells = {
        {name = "ahritumble", duration = 0.25},			--ahri's r
        {name = "akalishadowdance", duration = 0.25},		--akali r
        {name = "headbutt", duration = 0.25},			--alistar w
        {name = "caitlynentrapment", duration = 0.25},		--caitlyn e
        {name = "carpetbomb", duration = 0.25},			--corki w
        {name = "dianateleport", duration = 0.25},		--diana r
        {name = "fizzpiercingstrike", duration = 0.25},		--fizz q
        {name = "fizzjump", duration = 0.25},			--fizz e
        {name = "gragasbodyslam", duration = 0.25},		--gragas e
        {name = "gravesmove", duration = 0.25},			--graves e
        {name = "ireliagatotsu", duration = 0.25},		--irelia q
        {name = "jarvanivdragonstrike", duration = 0.25},	--jarvan q
        {name = "jaxleapstrike", duration = 0.25},		--jax q
        {name = "khazixe", duration = 0.25},			--khazix e and e evolved
        {name = "leblancslide", duration = 0.25},		--leblanc w
        {name = "leblancslidem", duration = 0.25},		--leblanc w (r)
        {name = "blindmonkqtwo", duration = 0.25},		--lee sin q
        {name = "blindmonkwone", duration = 0.25},		--lee sin w
        {name = "luciane", duration = 0.25},			--lucian e
        {name = "maokaiunstablegrowth", duration = 0.25},	--maokai w
        {name = "nocturneparanoia2", duration = 0.25},		--nocturne r
        {name = "pantheon_leapbash", duration = 0.25},	        --pantheon e?
        {name = "renektonsliceanddice", duration = 0.25},	--renekton e
        {name = "riventricleave", duration = 0.25},		--riven q
        {name = "rivenfeint", duration = 0.25},			--riven e
        {name = "sejuaniarcticassault", duration = 0.25},	--sejuani q
        {name = "shene", duration = 0.25},			--shen e
        {name = "shyvanatransformcast", duration = 0.25},	--shyvana r
        {name = "rocketjump", duration = 0.25},			--tristana w
        {name = "slashcast", duration = 0.25},			--tryndamere e
        {name = "vaynetumble", duration = 0.25},		--vayne q
        {name = "viq", duration = 0.25},			--vi q
        {name = "monkeykingnimbus", duration = 0.25},		--wukong q
        {name = "xenzhaosweep", duration = 0.25},		--xin xhao q
        {name = "yasuodashwrapper", duration = 0.25},		--yasuo e
}

local BlinkSpells = {
        {name = "ezrealarcaneshift", range = 475, delay = 0.25, delay2=0.8},		--Ezreals E
        {name = "deceive", range = 400, delay = 0.25, delay2=0.8}, 			--Shacos Q
        {name = "riftwalk", range = 700, delay = 0.25, delay2=0.8},			--KassadinR
        {name = "gate", range = 5500, delay = 1.5, delay2=1.5},				--Twisted fate R
        {name = "katarinae", range = math.huge, delay = 0.25, delay2=0.8},		--Katarinas E
        {name = "elisespideredescent", range = math.huge, delay = 0.25, delay2=0.8},	--Elise E
        {name = "elisespidere", range = math.huge, delay = 0.25, delay2=0.8},		--Elise insta E
    }

local GetPing = function()
        local latency = network.latency
        return latency / 1000
end

local GetPathCount = function(unit)
	return unit.path.count
end

local HasMovePath = function(unit)
	local pathCount = GetPathCount(unit)
	return pathCount > 1
end

local GetPath = function(unit, index)
	return unit.path.point[unit.path.index - 1]
end

local function GetCurrentWayPoints(object)
    local result = {}

    if object.path.count > 0 then
        table.insert(result, object.pos)
        for i = 1, object.path.count do

            local x,y,z = GetPath(object, i)
            table.insert(result,  vec3(object.x, object.y, object.z))
        end
    else
        table.insert(result, vec3(object.x, object.y, object.z))
    end
    return result
end

--orb.farm.predict_hp(obj, time)
local function CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw)
    if unit.networkID == minion.networkID then
        return false
    end

    --[[Check first if the minion is going to be dead when skillshots reaches his position]]
    if minion.type ~= player.type and orb.farm.predict_hp(minion, delay + common.GetDistance(from, minion) / speed) < 0 then
        return false
    end

    local waypoints = GetCurrentWayPoints(minion)
    local MPos, CastPosition = minion.path.count == 1 and vec3(minion.x, minion.y, minion.z)
    if common.GetDistanceSqr(from, MPos) <= (range)^2 and common.GetDistanceSqr(from, minion) <= (range + 100)^2 then
        local buffer = 0
        if (minion.path.count > 1) then
            buffer = 20
        else
            buffer = 8
        end

        if minion.type == player.type then
            buffer = buffer + minion.boundingRadius
        end

        --[[if draw then
            --Draw:Circle3D(x, y, z, radius, width, quality, color)
            Draw:Circle3D(minion.x, myHero.y, minion.z, self:GetHitBox(minion) + buffer, 1, 10, Lua_ARGB(175, 255, 0, 0))
            Draw:Circle3D(MPos.x, myHero.y, MPos.z, self:GetHitBox(minion) + buffer, 1, 10, Lua_ARGB(175, 0, 0, 255))
            self:DLine(MPos, minion, Lua_ARGB(175, 255, 255, 255))
        end]]

        if minion.path.count > 1 then
            local proj1, pointLine, isOnSegment = common.VectorPointProjectionOnLineSegment(from, Position, MPos)
            if isOnSegment and (common.GetDistanceSqr(MPos, proj1) <= (minion.boundingRadius + radius + buffer) ^ 2) then
                return true
            end
        end

        local proj2, pointLine, isOnSegment = common.VectorPointProjectionOnLineSegment(from, Position, minion)
        if isOnSegment and (common.GetDistanceSqr(minion, proj2) <= (minion.boundingRadius + radius + buffer) ^ 2) then
            return true
        end
    end
    return false
end

local function CheckMinionCollision(unit, Position, delay, radius, range, speed, from, draw, updatemanagers)
    Position = Position
    from = from and vec3(from.x, from.y, from.z) or player
    --local draw = true
    --[[if updatemanagers then
        self.EnemyMinions.range = range + 500 * (delay + range / speed)
        self.JungleMinions.range = self.EnemyMinions.range
        self.OtherMinions.range = self.EnemyMinions.range
        self.EnemyMinions:update()
        self.JungleMinions:update()
        self.OtherMinions:update()
        self.AllyMinions:update()
    end]]
    local result = false
    for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion then
                    if minion and minion.isVisible and not minion.isDead and minion.maxHealth > 5 then
                    --__PrintTextGame(tostring(GetObjName(minion.Addr)))
                    if CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                        if not draw then
                            return true
                        else
                            result = true
                        end
                    end
                end
            end
        end
    for i=0, objManager.minions.size[TEAM_NEUTRAL]-1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if minion then
                    if (minion.name ~= "PlantSatchel" and minion.name  ~= "PlantHealth" and minion.name  ~= "PlantVision") then
                            if CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                            if not draw then
                                    return true
                            else
                                    result = true
                            end
                            end
                    end
            end 
    end
    for i=0, objManager.enemies_n-1 do
            local enemy = objManager.enemies[i]
            if enemy then
                if CheckCol(unit, enemy, Position, delay, radius, range, speed, from, draw) then
                    if not draw then
                        return true
                    else
                        result = true
                end
            end
        end
    end
    return result
end


local Q_Prediction = {
    type = "Linear";
    delay = 0.25,
    range = 1100,
    speed = 2000,
    width = 60,
    collision = false,
    addmyboundingRadius = 1,
    addunitboundingRadius = 1,
    IsLowAccuracy = 0,
    IsVeryLowAccuracy = 0,
}

local function OnUpdateBuff()
    for i=0, objManager.maxObjects-1 do
        local unit = objManager.get(i)
        if unit and unit.type == TYPE_HERO and unit.team == TEAM_ENEMY then
            for i, buff in pairs(unit.buff) do 
                if buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 then
                    ImmobileHandler[unit.networkID] = os.clock() + (buff.endTime - buff.startTime)
                    return
                end

                if buff.type == 10 or buff.type == 22 or buff.type == 21 or buff.type == 8 then
                    SlowHandler[unit.networkID] = os.clock() + (buff.endTime - buff.startTime)
                    return
                end
            end
        end 
    end
end 

local function IsSlowed(unit, delay, speed, from)
    if SlowHandler[unit.networkID] then
        local distance = common.GetDistance(unit, from)
        if SlowHandler[unit.networkID] > (os.clock() + delay + distance / speed) then
             return true
        end
    end
    return false
end

local function IsImmobile(unit, delay, width, speed, from, spelltype)
    local radius = width / 2

    if ImmobileHandler[unit.networkID] then
        local ExtraDelay = speed == math.huge and  0 or (common.GetDistance(from, unit) / speed)
        if (ImmobileHandler[unit.networkID] > (os.clock() + delay + ExtraDelay) and spelltype == 0) then
            return true, vec3(unit.x, unit.y, unit.z), vec3(unit.x, unit.y, unit.z) + (radius / 3) * (vec3(from.x, from.y, from.z) - vec3(unit.x, unit.y, unit.z)):norm()
        elseif (ImmobileHandler[unit.networkID] + (radius / unit.MoveSpeed)) > (os.clock() + delay + ExtraDelay) then
            return true, vec3(unit.x, unit.y, unit.z), vec3(unit.x, unit.y, unit.z)
        end
    end
    return false, vec3(unit.x, unit.y, unit.z),  vec3(unit.x, unit.y, unit.z)
end

local function IsDashing(unit, delay, width, speed, from)
    local radius = width / 2
    local TargetDashing = false
    local CanHit = false
    local Position = vec3(unit.x, unit.y, unit.z)

    if DashHandler[unit.networkID] then
        local dash = DashHandler[unit.networkID]
        if dash and dash.endT >= os.clock() then
            TargetDashing = true
            if dash.isBlink then
                if (dash.endT - os.clock()) <= (delay + common.GetDistance(from, dash.endPos) / speed) then
                    Position = vec3(dash.endPos.x, 0, dash.endPos.z)
                    CanHit   = (unit.moveSpeed * (delay + common.GetDistance(from, dash.endPos) / speed - (dash.endT2 - os.clock()))) < radius
                end

                    if ((dash.endT - os.clock()) >= (delay + common.GetDistance(from, dash.startPos) / speed)) and not CanHit then
                            Position = vec3(dash.startPos.x, 0, dash.startPos.z)
                            CanHit = true
                        end
                    else
                        local t1, p1, t2, p2, dist = common.VectorMovementCollision(dash.startPos, dash.endPos, dash.speed, from, speed, (os.clock() - dash.startT) + delay)
                        t1, t2 = (t1 and 0 <= t1 and t1 <= (dash.endT - os.clock() - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <=  (dash.endT - os.clock() - delay)) and t2 or nil
                        local t = t1 and t2 and math.min(t1, t2) or t1 or t2

                        if t then
                            Position = t == t1 and vec3(p1.x, 0, p1.y) or vec3(p2.x, 0, p2.y)
                            CanHit = true
                        else
                            Position = vec3(dash.endPos.x, 0, dash.endPos.z)
                            CanHit = (unit.moveSpeed * (delay + common.GetDistance(from, Position) / speed - (dash.endT - os.clock()))) < radius
                    end
                end
            end
        end

    return TargetDashing, CanHit, Position
end

local function SRT(unit, unitPredPos, from, type, delay, range, speed, width, radius, angle)
    local result = math.huge

    local hasMovePath = HasMovePath(unit)
    local pathCount = GetPathCount(unit)
    local ping = GetPing()
    local unitMS = unit.moveSpeed
    local boundingRadius = unit.boundingRadius
    local distance = common.GetDistance(unitPredPos, from)

    if type == "Linear" then
            if speed == math.huge then
                    result = delay - (math.min(width / 2, range - distance, distance) + boundingRadius) / unitMS + ping + buffer
            else
                    if hasMovePath and pathCount >= 2 then
                            if speed >= unitMS then
                                    result = delay + math.max(0, distance - boundingRadius) / (speed - unitMS)
                                    - (math.min(width / 2, range - distance, distance) + boundingRadius) / unitMS
                                    + ping + buffer
                            else
                                    result = math.huge
                            end
                    else
                            result = delay + math.max(0, distance - boundingRadius) / speed
                            - (math.min(width / 2, range - distance, distance) + boundingRadius) / unitMS
                            + ping + buffer
                    end
            end
    elseif type == "Circle" then
            if speed == math.huge then
                    result = delay - radius / unitMS + ping + buffer

                    if range == 0 then
                            result = result + distance / unitMS
                    end
            else
                    result = delay + distance / speed - radius / unitMS + ping + buffer
            end
    end

    return result
end

local function GetPredict(spellData, unit, from)
        local type = spellData.type
        local delay = spellData.delay
        local range = spellData.range
        local speed = spellData.speed
        local width = spellData.width
        local collision = spellData.collision
        local addmyboundingRadius = spellData.addmyboundingRadius
        local addunitboundingRadius = spellData.addunitboundingRadius
        local radius = spellData.radius
        local angle = spellData.angle
        local IsLowAccuracy = spellData.IsLowAccuracy
        local IsVeryLowAccuracy = spellData.IsVeryLowAccuracy

    local RT = 0.4

    if IsVeryLowAccuracy then
            RT = 0.6
    elseif IsLowAccuracy then
            RT = 0.5
    end

    local RT_S = RT + 0.3

    local TotalDST = 0

    local unitPredPos = nil
    local unitPredPos_S = nil
    local unitPredPos_E = nil
    local unitPredPos_D = nil
    local unitPredPos_C = nil
    local CastPos = nil
    local HitChance = 0

    local hasMovePath = HasMovePath(unit)
    local pathCount = GetPathCount(unit)
    local pathIndex = unit.path.index
    local unitMS = unit.moveSpeed
    local ping = GetPing()

    if hasMovePath and pathCount >= 2 then
            local unitIndexPos = GetPath(unit, pathIndex)

            if not unitIndexPos then
                    unitIndexPos = GetPath(unit, pathIndex - 1)
            end

            TotalDST = common.GetDistance(unitIndexPos, unit)

            local DST, DST_S, DST_D = common.GetDistance(unitIndexPos, unit), common.GetDistance(unitIndexPos, unit), common.GetDistance(unitIndexPos, unit)
            local ExDST, ExDST_S, ExDST_D = nil, nil, nil
            local LastIndex, LastIndex_S, LastIndex_D = nil, nil, nil

            for i = pathIndex, pathCount do
                    local Path = GetPath(unit, i)
                    local Path2 = GetPath(unit, i + 1)

                    if pathCount == i then
                            Path2 = GetPath(unit, i)
                    end

                    if not LastIndex and DST > RT * unitMS then
                            LastIndex = i
                            ExDST = DST - RT * unitMS
                    end

                    if not LastIndex_S and DST_S > RT_S * unitMS then
                            LastIndex_S = i
                            ExDST_S = DST_S - RT_S * unitMS
                    end

                    if range == 0 and delay < RT and not LastIndex_D and DST_D > delay * unitMS then
                            LastIndex_D = i
                            ExDST_D = DST_D - delay * unitMS
                    end

                    DST = DST + common.GetDistance(Path2, Path)
                    DST_S = DST_S + common.GetDistance(Path2, Path)
                    DST_D = DST_D + common.GetDistance(Path2, Path)
                    TotalDST = TotalDST + common.GetDistance(Path2, Path)
            end

            if LastIndex_S then
                    local LastIndexPos = GetPath(unit, LastIndex)
                    local LastIndexPos2 = GetPath(unit, LastIndex - 1)
                    unitPredPos = LastIndexPos + (LastIndexPos2 - LastIndexPos):norm() * ExDST
                    local LastIndexPos_S = GetPath(unit, LastIndex_S)
                    local LastIndexPos_S2 = GetPath(unit, LastIndex_S - 1)
                    unitPredPos_S = LastIndexPos_S + (LastIndexPos_S2 - LastIndexPos_S):norm() * ExDST_S
            elseif LastIndex then
                    local LastIndexPos = GetPath(unit, LastIndex)
                    local LastIndexPos2 = GetPath(unit, LastIndex - 1)
                    unitPredPos = LastIndexPos + (LastIndexPos2 - LastIndexPos):norm() * ExDST
            else
                    unitPredPos_E = GetPath(unit, pathCount)
            end

            if LastIndex_D then
                    local LastIndexPos_D = GetPath(unit, LastIndex_D)
                    local LastIndexPos_D2 = GetPath(unit, LastIndex_D - 1)
                    unitPredPos_D = LastIndexPos_D + (LastIndexPos_D2 - LastIndexPos_D):norm() * ExDST_D
            end

    else
            unitPredPos = vec3(unit.x, unit.y, unit.z)
            unitPredPos_S = vec3(unit.x, unit.y, unit.z)

            if range == 0 and delay < RT then
                    unitPredPos_D = vec3(unit.x, unit.y, unit.z)
            end

    end

    if unitPredPos_S then
            CastPos = unitPredPos_S

            local SRT_S = SRT(unit, unitPredPos_S, from, type, delay, range, speed, width, radius, angle)

            if SRT_S <= RT_S then
                    SRT_S = math.max(ping + buffer, SRT_S)

                    if hasMovePath and pathCount >= 2 then
                            HitChance = (RT_S - SRT_S) / RT_S + 1
                    else
                            HitChance = (RT_S - SRT_S) / RT_S + 0.5
                    end

            end
    end

    if unitPredPos then
            if not unitPredPos_S then
                    CastPos = unitPredPos
            end

            local SRT = SRT(unit, unitPredPos, from, type, delay, range, speed, width, radius, angle)

            if SRT <= RT then
                    SRT = math.max(ping + buffer, SRT)

                    if hasMovePath and pathCount >= 2 then
                            CastPos = unitPredPos
                            HitChance = (RT - SRT) / RT + 2
                    else
                            CastPos = unitPredPos
                            HitChance = (RT - SRT) / RT + 1.5
                    end

            end
    end

    if unitPredPos_E then
            CastPos = unitPredPos_E

            local SRT_E = SRT(unit, unitPredPos_E, from, type, delay, range, speed, width, radius, angle)

            if SRT_E <= TotalDST / unitMS then
                    SRT_E = math.max(ping + buffer, SRT_E)
                    HitChance = (TotalDST / unitMS - SRT_E) / (TotalDST / unitMS) + 2
            end

    end

    if unitPredPos_D and (not unitPredPos_E or delay <= TotalDST / unitMS) then
            CastPos = unitPredPos_D
            HitChance = 0

            local SRT_D = SRT(unit, unitPredPos_D, from, type, delay, range, speed, width, radius, angle)

            if SRT_D <= delay then
                    SRT_D = math.max(ping + buffer, SRT_D)

                    if hasMovePath and pathCount >= 2 then
                            HitChance = (delay - SRT_D) / delay + 2
                    else
                            HitChance = (delay - SRT_D) / delay + 1.5
                    end
            end
    end

    if unitPredPos_C then
            CastPos = unitPredPos_C

            local SRT_C = SRT(unit, unitPredPos_C, from, type, delay, range, speed, width, radius, angle)
            local Time_C = common.GetDistance(unitPredPos_C, unit) / unitMS

            if SRT_C <= Time_C then
                    SRT_C = math.max(ping + buffer, SRT_C)

                    HitChance = (Time_C - SRT_C) / Time_C + 1
            end
    end

    return CastPos, HitChance
end
--[[

local Q_pred = {

        type = "Linear";
        delay = 0.25;
        range = 1200;
        speed = 1000;
        width = 100;
        collision = true;
        addmyboundingRadius = 0
        addunitboundingRadius = 0
        radius = 100 
        angle = 0 
        IsLowAccuracy = 1 
        IsVeryLowAccuracy = 0
}
]]
local function GetBestCastPosition(spellData, unit, from)
    local type = spellData.type
    local delay = spellData.delay
    local range = spellData.range
    local speed = spellData.speed
    local width = spellData.width
    local collision = spellData.collision
    local addmyboundingRadius = spellData.addmyboundingRadius
    local addunitboundingRadius = spellData.addunitboundingRadius
    local radius = spellData.radius
    local angle = spellData.angle
    local IsLowAccuracy = spellData.IsLowAccuracy
    local IsVeryLowAccuracy = spellData.IsVeryLowAccuracy

    local CastPosition, HitChance = vec3(unit.x, unit.y, unit.z), 0
    local TargetDashing, CanHitDashing, DashPosition = IsDashing(unit, delay, width, speed, from)
    local TargetImmobile, ImmobilePos, ImmobileCastPosition = IsImmobile(unit, delay, width, speed, from, type)

    if DontShoot[unit.NetworkId] and DontShoot[unit.NetworkId] > os.clock() then
        HitChance = -1

        CastPosition = unit.pos
    elseif TargetDashing then
        if CanHitDashing then
            HitChance = 3
        else
            HitChance = 0
        end

            CastPosition = DashPosition
        elseif TargetImmobile then
            CastPosition = ImmobileCastPosition
            HitChance = 3
        else
            CastPosition, HitChance = GetPredict(spellData, unit, from)
    end
    if SpellHandler[unit.networkID] and SpellHandler[unit.networkID] > os.clock() then
            HitChance = 2
    end

    local tempAngle = mathf.angle_between(from.pos:to2D(), unit.pos:to2D(), CastPosition)
    if tempAngle > 60 then
		HitChance = 1
	elseif tempAngle < 10 then
		HitChance = 2
	end

    if AutoAttackHandler[unit.networkID] and AutoAttackHandler[unit.networkID] > os.clock() then
            HitChance = 2
    end

    if IsSlowed(unit, delay, speed, from) then
            HitChance = 2
    end

    if common.GetDistanceSqr(from, CastPosition) >= range * range then
            HitChance = -1
    end

    if CastPosition and collision and CheckMinionCollision(unit, CastPosition, delay, width, range, speed, from, false, false) then
            HitChance = -1
    end

    return CastPosition, HitChance
end


local function OnTick()
    OnUpdateBuff()

    local enemy = common.GetEnemyHeroes()
    for i, target in pairs(enemy) do
        if target and common.IsValidTarget(target) and common.IsEnemyMortal(target) then
            local CastPosition, HitChance = GetBestCastPosition(Q_Prediction, target, player)

            if HitChance >= 2 then 
                if not CastPosition then 
                    return 
                end 

                player:castSpell('pos', 0, CastPosition)
            end
        end     
    end
end 
cb.add(cb.tick, OnTick)

local function OnNewPath()
    for i=0, objManager.maxObjects-1 do
        local unit = objManager.get(i)
        if unit and unit.type == TYPE_HERO and unit.team == TEAM_ENEMY then
            if unit.path.isActive and unit.path.isDashing  then 
                print("IsDash")
                local dash = {}
                local startPos = unit.path.point[0]
                local endPos = unit.path.point[unit.path.count]
                local latency 	= network.latency
                local distance 	= common.GetDistance(startPos, endPos)

                dash.startPos 	= startPos
                dash.endPos 	= endPos
                dash.speed 	= unit.path.dashSpeed
                dash.startT 	= os.clock() - latency / 2000
                dash.endT 	= dash.startT + (distance / unit.path.dashSpeed)

                DashHandler[unit.networkID] = dash
            end 
        end 
    end 
end
cb.add(cb.path, OnNewPath)

local function OnProcessSpell(spell)
    if spell.owner.type == TYPE_HERO then 
        SpellHandler[spell.owner.networkID] = os.clock() + 0.25
        print'here'
        if string.match(spell.name:lower(), "attack") then
            AutoAttackHandler[spell.owner.networkID] = os.clock() + spell.windUpTime
        end
        for i = 1, #BlinkSpells do
            local blinkSpell = BlinkSpells[i]
            if blinkSpell then
                local startPos = vec3(spell.startPos.x, spell.startPos.y, spell.startPos.z)
                local endPos = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)
                local landingPos = common.GetDistanceSqr(spell.owner, endPos) < blinkSpell.range * blinkSpell.range and endPos or vec3(spell.owner.x, spell.owner.y, spell.owner.z) + blinkSpell.range * (endPos -  vec3(spell.owner.x, spell.owner.y, spell.owner.z)):norm()
                if blinkSpell.name == spell.name:lower() and not navmesh.isWall(endPos) then
                    DashHandler[spell.owner.networkID] = {
                        isBlink   = true,
                        duration  = blinkSpell.delay,
                        endT      = os.clock() + blinkSpell.delay,
                        endT2     = os.clock() + blinkSpell.delay2,
                        startPos  = vec3(spell.owner.x, spell.owner.y, spell.owner.z),
                        endPos    = landingPos
                        }
                    end
                end
            end

        for i = 1, #DashSpells do
            local dashSpell = DashSpells[i]
            if dashSpell and dashSpell.name == spell.name:lower() then
                print'DontShoot'
                DontShoot[spell.owner.networkID] = os.clock() + dashSpell.duration
            end
        end
    end
end 
cb.add(cb.spell, OnProcessSpell)