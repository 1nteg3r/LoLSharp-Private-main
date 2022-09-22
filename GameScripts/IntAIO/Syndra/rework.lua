local gpred = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")

local common = module.load(header.id, "Library/common")
local GeometryLib = module.load(header.id, "Geometry/GeometryLib")
local LineSegment = GeometryLib.LineSegment
local Vector 

local function class()
    return setmetatable(
        {},
        {
            __call = function(self, ...)
                local result = setmetatable({}, {__index = self})
                result:__init(...)

                return result
            end
        }
    )
end

local Syndra = class()

local byte, match, floor, min, max, abs, rad, huge, clock, insert, remove =
    string.byte,
    string.match,
    math.floor,
    math.min,
    math.max,
    math.abs,
    math.rad,
    math.huge,
    os.clock,
    table.insert,
    table.remove

    local function GetDistanceSqr(p1, p2)
    p2 = p2 or player
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx * dx + dz * dz
end

local function QEFilter(iput, seg, obj)
	if gpred.trace.linear.hardlock(iput, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(iput, seg, obj) then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.5) then
		return true
	end
end

function Syndra:__init()
    Vector = GeometryLib.Vector
    function Vector:angleBetweenFull(v1, v2)
        local p1, p2 = (-self + v1), (-self + v2)
        local theta = p1:polar() - p2:polar()
        if theta < 0 then
            theta = theta + 360
        end
        return theta
    end
    self.unitsInRange = {}
    self.enemyHeroes = common.GetEnemyHeroes()
    self.allyHeroes = common.GetAllyHeroes()
    self.HeanderW_target = { }
    self.spell = {
        q = {
            type = "circular",
            range = 800,
            rangeSqr = 800 * 800,
            delay = 0.65,
            radius = 210,
            boundingRadiusMod = 0,
            speed = huge
        },
        w = {
            type = "circular",
            range = 950,
            grabRangeSqr = 925 * 925,
            delay = 0.75,
            radius = 220,
            speed = huge,
            heldInfo = nil,
            useHeroSource = true,
            boundingRadiusMod = 0,
            blacklist = {}, -- for orbs
            blacklist2 = nil -- for champions
            
        },
        e = {
            type = "linear",
            speed = 1600,
            rangeSqr = 700 * 700,
            range = 700,
            delay = 0.25,
            width = 200,
            boundingRadiusMod = 0,
            widthMax = 200,
            angle = 40,
            angle1 = 40,
            angle2 = 60,
            blacklist = {},
            next = nil,
            collision = {
                ["wall"] = true,
                ["hero"] = false,
                ["minion"] = false
            }
        },
        qe = {
            type = "linear",
            pingPongSpeed = 2000,
            range = 1250,
            delay = 0.32,
            speed = 2000,
            boundingRadiusMod = 0,
            width = 200,
            collision = {
                ["wall"] = true,
                ["hero"] = false,
                ["minion"] = false
            }
        },
        r = {
            type = "targetted",
            speed = 2000,
            delay = 0,
            range = 2000,
            boundingRadiusMod = 0,
            castRange = 675,
            collision = {
                ["wall"] = true,
                ["hero"] = false,
                ["minion"] = false
            }
        }
    }
    self.myHeroPred = player.pos
    self.last = {
        q = nil,
        w = nil,
        e = nil,
        r = nil
    }
    self.ignite =
        player:spellSlot(4).name == "SummonerDot" or
        player:spellSlot(5).name == "SummonerDot" or
        nil
    self.igniteDamage = nil
    self.wGrabList = {
        ["SRU_ChaosMinionSuper"] = true,
        ["SRU_OrderMinionSuper"] = true,
        ["HA_ChaosMinionSuper"] = true,
        ["HA_OrderMinionSuper"] = true,
        ["SRU_ChaosMinionRanged"] = true,
        ["SRU_OrderMinionRanged"] = true,
        ["HA_ChaosMinionRanged"] = true,
        ["HA_OrderMinionRanged"] = true,
        ["SRU_ChaosMinionMelee"] = true,
        ["SRU_OrderMinionMelee"] = true,
        ["HA_ChaosMinionMelee"] = true,
        ["HA_OrderMinionMelee"] = true,
        ["SRU_ChaosMinionSiege"] = true,
        ["SRU_OrderMinionSiege"] = true,
        ["HA_ChaosMinionSiege"] = true,
        ["HA_OrderMinionSiege"] = true,
        ["SRU_Krug"] = true,
        ["SRU_KrugMini"] = true,
        ["TestCubeRender"] = true,
        ["SRU_RazorbeakMini"] = true,
        ["SRU_Razorbeak"] = true,
        ["SRU_MurkwolfMini"] = true,
        ["SRU_Murkwolf"] = true,
        ["SRU_Gromp"] = true,
        ["Sru_Crab"] = true,
        ["SRU_Red"] = true,
        ["SRU_Blue"] = true,
        ["EliseSpiderling"] = true,
        ["HeimerTYellow"] = true,
        ["HeimerTBlue"] = true,
        ["MalzaharVoidling"] = true,
        ["ShacoBox"] = true,
        ["YorickGhoulMelee"] = true,
        ["YorickBigGhoul"] = true
    }
    self.orbs = {}
    self.rDamages = {}
    self.electrocuteTracker = {}
    self:Menu()

    cb.add(cb.tick, function()
        self:OnTick()
    end)

    cb.add(cb.create_minion, function(obj)
        self:OnCreateObj(obj)
    end)

    cb.add(cb.delete_particle, function(obj)
        self:OnDeleteObj(obj)
    end)

    cb.add(cb.spell,function(spell)
        self:OnProcessSpell(spell)
    end)

    cb.add(cb.draw, function()
        self:OnDraw()
    end)

end

function Syndra:Menu()
    self.menu = menu("IntnnerSyndra", "Intnner - Syndra")
    self.menu:header("xs", "Core")
    self.menu:keybind("comboQE", "Q -> E Combo", false, "A")
    self.menu:keybind("AutoE", "Auto E", false, "G")
    self.menu:menu("combo", "Combo")
    self.menu.combo:boolean("qcombo", "Use Q", true)
    self.menu.combo:boolean("wcombo", "Use W", true)
    self.menu.combo:boolean("ecombo", "Use E", true)
    self.menu.combo:menu("antigap", "Anti-Gapcloser")
    for _, enemy in ipairs(common.GetEnemyHeroes()) do
        self.menu.combo.antigap:boolean(enemy.charName, enemy.charName, true)
    end

    self.menu.combo:menu("rset", "R")
    self.menu.combo.rset:boolean("rcombo", "Use R", true)
    for _, enemy in ipairs(self.enemyHeroes) do
        self.menu.combo.rset:boolean(tostring(enemy.networkID), enemy.charName, true)
    end
    self.menu.combo.rset:boolean("c0", "Cast regardless of below conditions", false)
    self.menu.combo.rset:boolean("c1", "Cast if target in wall", true)
    self.menu.combo.rset:boolean("c2", "Cast if lower health% than target", true)
    self.menu.combo.rset:slider("c3", "Cast if player % health < x", 15, 5, 100, 5)
    self.menu.combo.rset:boolean("c4", "Do not cast if killed by Q ", true)
    self.menu.combo.rset:boolean("c5", "Cast if more enemies near than allies", true)
    self.menu.combo.rset:slider("c6", "Cast if mana less than", 100, 50, 500, 50)
    self.menu.combo.rset:slider("c7", "Cast if target MR less than", 200, 100, 200, 10)
    self.menu.combo.rset:slider("c8", "Cast if enemies around player <= x", 2, 1, 5, 1)
end

function Syndra:OnTick()
    self:TrackWObject()

    local myPos = gpred.core.get_pos_after_time(player, network.latency / 2000 + 0.06)
    self.myHeroPred = vec3(myPos.x, player.y, myPos.y)

    self.spell.e.angle = player:spellSlot(2).level < 5 and self.spell.e.angle1 or self.spell.e.angle2

    if self.spell.w.blacklist2 and clock() >= self.spell.w.blacklist2.time + 0.8 then
        self.spell.w.blacklist2 = nil
    end
    for _, stacks in pairs(self.electrocuteTracker) do
        for i, time in pairs(stacks) do
            if clock() >= time + 2.75 - 0.06 - network.latency / 2000 then
                stacks[i] = nil
            end
        end
    end
    for i in ipairs(self.spell.w.blacklist) do
        if not self.orbs[i] then
            self.spell.w.blacklist[i] = nil
        elseif self.spell.w.blacklist[i].nextCheckTime and clock() >= self.spell.w.blacklist[i].nextCheckTime then
            if
                clock() >= self.spell.w.blacklist[i].interceptTime and
                    GetDistanceSqr(self.orbs[i].obj.pos, self.spell.w.blacklist[i].pos) == 0
             then
                self.spell.w.blacklist[i] = nil
            else
                self.spell.w.blacklist[i].pos = self.orbs[i].obj.pos
                self.spell.w.blacklist[i].nextCheckTime = clock() + 0.3
            end
        end
    end

    for orb in pairs(self.spell.e.blacklist) do
        if self.spell.e.blacklist[orb].time <= clock() then
            if
                not (self.spell.w.heldInfo and orb == self.spell.w.heldInfo.obj) and
                    GetDistanceSqr(self.spell.e.blacklist[orb].pos, orb.pos) == 0
             then
                self.spell.e.blacklist[orb] = nil
            else
                self.spell.e.blacklist[orb] = {pos = orb.pos, time = clock() + 0.1 + network.latency / 1000}
            end
        end
    end

    for i in ipairs(self.orbs) do
        local orb = self.orbs[i]
        if clock() >= orb.endT or (orb.obj.health and orb.obj.health ~= 1) then
            remove(self.orbs, i)
        end
    end

    if self:ShouldCast() then
        self:Combo()
    end
end

function Syndra:Combo()
    self.qTarget = nil
    for _, enemy in ipairs(self.enemyHeroes) do
        self.unitsInRange[enemy.networkID] = enemy.pos and not enemy.isDead and GetDistanceSqr(enemy) < 4000000 --2000 range
    end
    local q = player:spellSlot(0).state == 0
    local w = player:spellSlot(1).state == 0
    local w1 = w and player:spellSlot(1).name == "SyndraW" and not self.spell.w.heldInfo
    local e = player:spellSlot(2).state == 0
    local notE = player:spellSlot(2).state ~= 0

    if w1 and self:AutoGrab() then
        return
    end

    local canHitOrbs = self:GetHitOrbs()
    local canE = false
 
    if orb.menu.combat.key:get() then
   
        if q then
            local qres = TS.get_result(function(res, obj, dist)
                local seg = gpred.circular.get_prediction(self.spell.q, obj, vec2(player.x, player.z))
                if seg then 
                    res.pos = vec3(seg.endPos.x, obj.y, seg.endPos.y)
                end 
    
                if self.unitsInRange[obj.networkID] then 
                    res.obj = obj 
                end 
    
                return true  
            end)
            if qres.pos and qres.obj  then
                if ((orb.menu.combat.key:get() and (notE or GetDistanceSqr(qres.pos) >= self.spell.e.rangeSqr)) or orb.menu.hybrid.key:get())  then
                    self:CastQ(qres.pos)
                end
            end
        end
    end 
end

function Syndra:OnDraw()
    graphics.draw_circle(player.pos, self.spell.q.range, 1, 0xFFFFFFFF, 100)
    graphics.draw_circle(player.pos, self.spell.qe.range, 1, 0xFFFFFFFF, 100)

    for i in pairs(self.orbs) do
        local orb = self.orbs[i]
        --graphics.draw_circle(v1, radius, width, color, pts_n)
        graphics.draw_circle((orb.obj.pos or orb.obj.position), 40, 1, (orb.isInitialized and 0xff34ebcc or 0xffde0707), 100)
    end
    local text =
        (self.menu.comboQE:get() and "Stun On" or "Stun Off") ..
        "\n" ..
            (self.menu.AutoE:get() and "Auto E: On" or "Auto E: Off") ..
                "\n" .. (self.menu.combo.rset.rcombo:get() and "Use R: On" or "Use R: Off")

    graphics.draw_text_2D(text, 14, graphics.world_to_screen(player.pos).x, graphics.world_to_screen(player.pos).y, 0xFFFFFFFF)
    --graphics.world_to_screen(v1)
    --graphics.draw_text_2D(str, size, x, y, color)
end

function Syndra:TrackWObject()
    if not self.spell.w.heldInfo and player.buff['syndrawtooltip'] then
        for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion and not minion.isDead then
                if minion.buff['syndrawbuff'] then
                    self.spell.w.heldInfo = {obj = minion, isOrb = false}
                    return
                end
            end
        end
        for i in ipairs(self.orbs) do
            local orb = self.orbs[i]
            if orb.isInitialized then
                for headweW in ipairs(self.HeanderW_target) do
                    if headweW then 
                        self.spell.w.heldInfo = {obj = orb.obj, isOrb = true}
                        orb.endT = clock() + 6.25
                        self.spell.e.blacklist[orb.obj] = {
                            pos = (orb.obj.pos or orb.obj.position),
                            time = clock() + 0.06
                        }
                        return
                    end
                end
            end
        end
    end
end

function Syndra:WaitToInitialize()
    for i in ipairs(self.orbs) do
        local orb = self.orbs[i]
        if not orb.isInitialized and GetDistanceSqr((orb.obj.pos or orb.obj.position)) <= self.spell.w.grabRangeSqr then
            return true
        end
    end
end

function Syndra:ShouldCast()
    for spell, time in pairs(self.last) do
        if time and clock() < time then
            return false
        end
    end
    return true
end

function Syndra:AutoGrab()
    if not player.isRecalling then
        for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if
                (minion.name == "Tibbers" or minion.name == "IvernMinion" or minion.name == "H-28G Evolution Turret") and
                    GetDistanceSqr(minion) < self.spell.w.grabRangeSqr
             then
               player:castSpell("pos", 1, minion.pos)
                self.last.w = clock() + 0.5
                return true
            end
        end
    end
end

function Syndra:CastQ(pred)
    if player:spellSlot(0).state == 0  then
        if pred then
            player:castSpell("pos", 0, pred)
            self.last.q = clock() + 0.5
            self.orbs[#self.orbs + 1] = {
                obj = {pos = pred},
                isInitialized = false,
                isCasted = false,
                endT = clock() + 0.25
            }
            --PrintChat("q")
            return true
        end
    end
end

function Syndra:GetGrabTarget()
    local lowTime = huge
    local lowOrb = nil
    for i in ipairs(self.orbs) do
        local orb = self.orbs[i]
        if
            not self.spell.w.blacklist[i] and orb.isInitialized and orb.endT < lowTime and
                GetDistanceSqr((orb.obj.pos or orb.obj.position)) <= self.spell.w.grabRangeSqr
         then
            lowTime = orb.endT
            lowOrb = orb.obj
        end
    end
    if lowOrb then
        return lowOrb, true
    end

    local minionsInRange = common.GetMinionsInRange(1500)
    local lowHealth = huge
    local lowMinion = nil
    for _, minion in ipairs(minionsInRange) do
        if
            minion and self.wGrabList[minion.charName] and common.IsValidTarget(minion) and
                GetDistanceSqr(minion.pos) <= self.spell.w.grabRangeSqr
         then
            if minion.health < lowHealth then
                lowHealth = minion.health
                lowMinion = minion
            end
        end
    end
    if lowMinion then
        return lowMinion, false
    end
end

function Syndra:CastW1()
    local target = self:GetGrabTarget()
    if target then
        player:castSpell("obj", 1, target)
        self.last.w = clock() + 0.5
        return true
    end
end

function Syndra:CastW2(pred)
    if not self.spell.w.heldInfo then
        return
    end
    if pred and not navmesh.isWall(pred) then
        player:castSpell("pos", 1, pred)
        self.last.w = clock() + 0.5
        return true
    end
end

function Syndra:GetHitOrbs()
    local canHitOrbs = {}
    for i in ipairs(self.orbs) do
        local orb = self.orbs[i]
        local distToOrb = common.GetDistance((orb.obj.pos or orb.obj.position))
        if distToOrb <= self.spell.q.range then
            local timeToHitOrb = self.spell.e.delay + (distToOrb / self.spell.e.speed)
            local expectedHitTime = clock() + timeToHitOrb - 0.1
            local canHitOrb =
                orb.isCasted and
                (orb.isInitialized and (expectedHitTime + 0.1 < orb.endT) or (expectedHitTime > orb.endT)) and
                (not orb.isInitialized or (orb.obj and not self.spell.e.blacklist[orb.obj])) and
                (not self.spell.w.heldInfo or orb.obj ~= self.spell.w.heldInfo.obj)
            if canHitOrb then
                canHitOrbs[#canHitOrbs + 1] = orb
            end
        end
    end
    return canHitOrbs
end

function Syndra:CanEQ(qPos, pred, target)
    --wall check
    local interval = 50
    local castPosition = pred
    local count = floor(common.GetDistance(castPosition, qPos:toDX3()) / interval)
    local diff = (Vector(castPosition) - qPos):normalized()
    for i = 0, count do
        local pos = (Vector(qPos) + diff * i * interval):toDX3()
        if navmesh.isWall(pos) then
            return false
        end
    end

    return true
end

function Syndra:CheckForSame(list)
    if #list > 2 then
        local last = list[#list]
        for i = #list - 1, 1, -1 do
            if abs(last - list[i]) < 0.01 then
                local maxInd = 0
                local maxVal = -huge
                for j = i + 1, #list do
                    if list[j] > maxVal then
                        maxInd = j
                        maxVal = list[j]
                    end
                end
                return maxVal
            end
        end
    end
end

function Syndra:CheckHitOrb(castPos)
    for i in ipairs(self.orbs) do
        if
            GetDistanceSqr(self.myHeroPred, self.orbs[i].obj.pos) <= self.spell.q.rangeSqr and
                Vector(self.myHeroPred):angleBetween(Vector(castPos), Vector(self.orbs[i].obj.pos)) <=
                    (self.spell.e.angle + 10) / 2
         then
            self.spell.w.blacklist[i] = {
                interceptTime = clock() + common.GetDistance(self.myHeroPred, self.orbs[i].obj.pos) / self.spell.e.speed +
                    0.5,
                nextCheckTime = clock() + 0.3,
                pos = self.orbs[i].obj.pos
            }
        end
    end
end

function Syndra:CalcQELong(target, dist)
    local dist = dist or self.spell.e.range
    self.spell.qe.speed = self.spell.qe.pingPongSpeed
    local pred
    local lasts = {}
    local check = nil
    while not check do
        local sub = gpred.linear.get_prediction(self.spell.qe, target, vec2(player.x, player.z))
        pred = vec3(sub.endPos.x, target.y, sub.endPos.y)
        if pred and GetDistanceSqr(pred) >= self.spell.e.rangeSqr then
            local offset = -target.boundingRadius or 0
            local distToCast = common.GetDistance(pred)
            self.spell.qe.speed =
                (self.spell.e.speed * dist + self.spell.qe.pingPongSpeed * (distToCast + offset - dist)) /
                (distToCast + offset)
            lasts[#lasts + 1] = self.spell.qe.speed
            check = self:CheckForSame(lasts)
        else
            return
        end
    end
    self.spell.qe.speed = check
    return true
end

function Syndra:CalcQEShort(target, widthMax, spell)
    self.spell.e.width = widthMax
    local pred = nil
    local lasts = {}
    local check = nil
    while not check do
        local sub = gpred.linear.get_prediction(self.spell.e, target, vec2(player.x, player.z))
        pred = vec3(sub.endPos.x, target.y, sub.endPos.y)

        if not (pred) then
            return
        end
        self.spell.e.width =
            -target.boundingRadius +
            (common.GetDistance(pred) + target.boundingRadius) /
                (common.GetDistance(self:GetQPos(pred, spell):toDX3()) + target.boundingRadius) *
                (widthMax + target.boundingRadius)
        lasts[#lasts + 1] = self.spell.e.width
        check = self:CheckForSame(lasts)
    end
    self.spell.e.width = check
    if not self:CanEQ(self:GetQPos(pred, "q"), pred, target) then
        return
    end
    return pred
end

function Syndra:CalcBestCastAngle(colls, all)
    local maxCount = 0
    local maxStart = nil
    local maxEnd = nil
    for i = 1, #all do
        local base = all[i]
        local endAngle = base + self.spell.e.angle
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
        local hasColl = colls[angle]
        local endDelta = angle
        while (isContained(count, angle, base, over360, endAngle)) do
            if count > 10 then
            end
            if colls[angle] then
                hasColl = true
            end
            endDelta = all[j]
            count = count + 1
            j = j + 1
            if j > #all then
                j = 1
            end
            angle = all[j]
        end
        if hasColl and count > maxCount then
            maxCount = count
            maxStart = base
            maxEnd = endDelta
        end
    end
    if maxStart and maxEnd then
        if maxStart + self.spell.e.angle > 360 then
            maxEnd = maxEnd + 360
        end
        local res = (maxStart + maxEnd) / 2
        if res > 360 then
            res = res - 360
        end
        --PrintChat("count: " .. maxCount .. " res: " .. res)
        return rad(res)
    end
end

function Syndra:CastE(target, canHitOrbs)
    if player:spellSlot(2).state == 0 and #canHitOrbs >= 1 then
        local sub = gpred.linear.get_prediction(self.spell.qe, target, vec2(self.myHeroPred.x, self.myHeroPred.z))
        local checkPred = vec3(sub.endPos.x, target.y, sub.endPos.y)
        if not checkPred then
            return
        end
        local collOrbs, maxHit, maxOrb = {}, 0, nil
        --check which orb can be hit
        local checkWidth = checkPred.realHitChance == 1 and self.spell.e.widthMax or 100
        local checkSpell =
            setmetatable(
            {
                width = self.spell.qe.width - checkWidth / 2
            },
            {__index = self.spell.qe}
        )
        local sub2 = gpred.linear.get_prediction(checkSpell, target,  vec2(self.myHeroPred.x, self.myHeroPred.z))
        checkPred = vec3(sub2.endPos.x, target.y, sub2.endPos.y)
        if checkPred and QEFilter(checkSpell, sub2, target) then
            --check which orbs can hit enemy
            for i = 1, #canHitOrbs do
                local orb = canHitOrbs[i]
                if GetDistanceSqr(checkPred) > GetDistanceSqr(orb.obj.pos) then
                    self:CalcQELong(target, common.GetDistance(orb.obj.pos))
                    local seg =
                        LineSegment(
                        Vector(self.myHeroPred):extended(Vector(orb.obj.pos), self.spell.qe.range),
                        Vector(self.myHeroPred)
                    )
                    if seg:distanceTo(Vector(checkPred)) <= checkWidth / 2 then
                        collOrbs[orb] = 0
                    end
                else
                    self.spell.e.delay = 0.25
                    local pred = self:CalcQEShort(target, checkWidth, "q")
                    if pred then
                        local castPosition = pred
                        if GetDistanceSqr(castPosition, orb.obj.pos) <= 160000 then -- 400 range
                            local seg =
                                LineSegment(
                                Vector(self.myHeroPred):extended(Vector(orb.obj.pos), self.spell.qe.range),
                                Vector(self.myHeroPred)
                            )
                            if
                                seg:distanceTo(self:GetQPos(castPosition)) <=
                                    self.spell.e.widthMax / common.GetDistance(orb.obj.pos) * common.GetDistance(castPosition)
                             then
                                collOrbs[orb] = 0
                            end
                        end
                    end
                end
            end

            -- look for cast with most orbs hit
            local basePosition = canHitOrbs[1].obj.pos
            local canHitOrbAngles, collOrbAngles = {}, {}
            for i = 1, #canHitOrbs do
                local orb = canHitOrbs[i]
                local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(basePosition), Vector(orb.obj.pos))
                canHitOrbAngles[i] = angle
                if collOrbs[orb] then
                    collOrbAngles[angle] = true
                end
            end
            table.sort(canHitOrbAngles)
            local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
            if best then
                local castPosition =
                    (Vector(self.myHeroPred) +
                    (Vector(basePosition) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() *
                        self.spell.e.range):toDX3()
                player:castSpell("pos", 2, castPosition)
                self.last.e = clock() + 0.5
                --PrintChat("e")
                return true
            end
        end
    end
end

function Syndra:CastQEShort(pred, target, canHitOrbs)
    if
    player:spellSlot(0).state == 0 and
    player:spellSlot(2).state  == 0 and
            player.mana >= 80 + 10 * player:spellSlot(0).level and
            (not self.spell.e.next or GetDistanceSqr(self.spell.e.next.pos) > self.spell.e.rangeSqr or
                self.spell.e.next.time <=
                    clock() + self.spell.e.delay + common.GetDistance(pred) / self.spell.e.speed)
     then
        local qPos = self:GetQPos(pred, "q"):toDX3()
        local canHitOrbAngles, collOrbAngles = {}, {}
        for i = 1, #canHitOrbs do
            local orb = canHitOrbs[i]
            local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(qPos), Vector(orb.obj.pos))
            canHitOrbAngles[i] = angle
        end
        canHitOrbAngles[#canHitOrbAngles + 1] = 0
        collOrbAngles[0] = true
        table.sort(canHitOrbAngles)
        local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
        if best then
            local castPosition =
                (Vector(self.myHeroPred) +
                (Vector(qPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()
            player:castSpell("pos", 0, qPos)
            player:castSpell("pos", 2, castPosition)
            self.last.e = clock() + 0.5
            self.orbs[#self.orbs + 1] = {
                obj = {position = qPos},
                isInitialized = false,
                isCasted = false,
                endT = clock() + 0.25
            }
            self:CheckHitOrb(castPosition)

            return true
        end
    end
end

function Syndra:CastQELong(pred, canHitOrbs)
    if player.mana >= 80 + 10 * player:spellSlot(0).level then
        local predPosition = pred
        local qPos = Vector(self.myHeroPred):extended(Vector(predPosition), (self.spell.q.range - 100)):toDX3()
        local canHitOrbAngles, collOrbAngles = {}, {}
        for i = 1, #canHitOrbs do
            local orb = canHitOrbs[i]
            local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(qPos), Vector(orb.obj.pos))
            canHitOrbAngles[i] = angle
        end
        canHitOrbAngles[#canHitOrbAngles + 1] = 0
        collOrbAngles[0] = true
        table.sort(canHitOrbAngles)
        local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
        if best then
            local castPosition =
                (Vector(self.myHeroPred) +
                (Vector(qPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()
                player:castSpell("pos", 0, qPos)
                if castPosition then 
                    player:castSpell("pos", 2, castPosition)
                end

            self.last.q = clock() + 0.5
            self.last.e = clock() + 0.5
            self.orbs[#self.orbs + 1] = {
                obj = {position = qPos},
                isInitialized = false,
                isCasted = false,
                endT = clock() + 0.25
            }
            self:CheckHitOrb(castPosition)
            return true
        end
    end
end

function Syndra:CastWELong(pred, castTarget, canHitOrbs)
    if player.mana >= 100 + 10 * player:spellSlot(0).level then
        local predPosition = pred
        local target, isOrb
        if self.spell.w.heldInfo then
            if not self.spell.w.heldInfo.isOrb then
                return
            end
        else
            --return
            target, isOrb = self:GetGrabTarget()
            if target and isOrb then
                --PrintChat("hold and throw 1 tick")
                player:castSpell("obj", 1, target)
            else
                return
            end
        end
        local wPos = Vector(self.myHeroPred):extended(Vector(predPosition), (self.spell.q.range - 100)):toDX3()
        local canHitOrbAngles, collOrbAngles = {}, {}
        for i = 1, #canHitOrbs do
            local orb = canHitOrbs[i]
            if not orb.obj == target then
                local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(wPos), Vector(orb.obj.pos))
                canHitOrbAngles[i] = angle
            end
        end
        canHitOrbAngles[#canHitOrbAngles + 1] = 0
        collOrbAngles[0] = true
        table.sort(canHitOrbAngles)
        local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
        if best then
            local castPosition =
                (Vector(self.myHeroPred) +
                (Vector(wPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()

            player:castSpell("pos", 1, wPos)
            player:castSpell("pos", 2, castPosition)
            self.last.w = clock() + 0.5
            self.last.e = clock() + 0.5
            self:CheckHitOrb(castPosition)
            --PrintChat("we long")
            return true
        end
    end
end

function Syndra:GetQPos(predPos, spell)
    local dist = common.GetDistance(predPos)
    if spell == "q" then
        return Vector(self.myHeroPred):extended(Vector(predPos), min(dist + 450, max(dist + 50, 700)))
    elseif spell == "w" then
        return Vector(self.myHeroPred):extended(Vector(predPos), min(dist + 450, max(dist + 50, 700)))
    end
    return Vector(self.myHeroPred):extended(Vector(predPos), min(dist + 450, 850))
end

function Syndra:CastWEShort(pred, canHitOrbs)
    if
        player:spellSlot(1).state == 0 and
        player:spellSlot(2).state  == 0 and
            player.mana >= 100 + 10 * player:spellSlot(1).level
     then
        local target, isOrb
        if self.spell.w.heldInfo then
            if not self.spell.w.heldInfo.isOrb then
                return
            end
        else
            target, isOrb = self:GetGrabTarget()
            if target and isOrb then
                --PrintChat("hold and throw 1 tick")
                player:castSpell("obj", 1, target)
            else
                return
            end
        end
        local wPos = self:GetQPos(pred, "w"):toDX3()
        local canHitOrbAngles, collOrbAngles = {}, {}
        for i = 1, #canHitOrbs do
            local orb = canHitOrbs[i]
            if not orb.obj == target then
                local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(wPos), Vector(orb.obj))
                canHitOrbAngles[i] = angle
            end
        end
        canHitOrbAngles[#canHitOrbAngles + 1] = 0
        collOrbAngles[0] = true
        table.sort(canHitOrbAngles)
        local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
        if best then
            local castPosition =
                (Vector(self.myHeroPred) +
                (Vector(wPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()
            player:castSpell("pos", 1, wPos)
            player:castSpell("pos", 2, castPosition)
            self.last.w = clock() + 0.5
            self.last.e = clock() + 0.5
            --PrintChat("we")
            return true
        end
    end
end

function Syndra:GetIgnite(target)
    return ((self.ignite  and
        GetDistanceSqr(target) <= 360000) and --600 range
        true) or
        nil
end

function Syndra:UseIgnite(target)
    local ignite = self:GetIgnite(target)
    if
        ignite and
            (self.igniteDamage > target.health + target.allShield and
            player:spellSlot(3).state ~= 0 and
                ((player:spellSlot(0) == 0 and 1 or 0) +
                    (player:spellSlot(1) == 0 and 1 or 0) +
                    (player:spellSlot(2) == 0 and 1 or 0) <=
                    1 or
                    player.health / player.maxHealth < 0.2))
     then
        player:castSpell("obj", self.ignite, target)
        return true
    end
end

function Syndra:CalcRDamage()
    local r = player:spellSlot(3)
    self.spell.r.baseDamage = (50 + 45 * r.level + 0.2 * self:GetTotalAp())
end

function Syndra:RExecutes(target)
    local base = self.spell.r.baseDamage

    if player.buff['itemmagicshankcharge'] and player.buff['itemmagicshankcharge'].stacks2 >= 90 then
        base = base + 100 + 0.1 * self:GetTotalAp()
    elseif player.buff[string.lower"ASSETS/Perks/Styles/Sorcery/SummonAery/SummonAery.lua"] then
        base = base + 8.235 + 1.765 * player.levelRef + 0.1 * self:GetTotalAp()
    elseif player.buff[string.lower"ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua"] then
        if self.electrocuteTracker[target.networkID] and #self.electrocuteTracker[target.networkID] >= 1 then
            base = base + 21.176 + 8.824 * player.levelRef + 0.25 * self:GetTotalAp()
        end
    end

    base = common.CalculateMagicDamage(target, player, base)
    self.rDamages[target] = base + (self:GetIgnite(target) and self.igniteDamage or 0)
    local diff = target.health - base
    if diff <= 0 then
        return true, false
    elseif ignite and diff <= ignite then
        return true, true
    else
        return false, false
    end
end

function Syndra:RConditions(target)
    local canExecute, needIgnite = self:RExecutes(target)
    if not canExecute then
        return false
    end

    if
        target and
            not (orb.menu.combat.key:get()and player:spellSlot(3).state == 0 and
                self.menu.combo.rset[tostring(target.networkId)] and
                self.menu.combo.rset[tostring(target.networkId)]:get() and
                GetDistanceSqr(target.pos) <= self.spell.r.castRange * self.spell.r.castRange)
     then
        return false
    end
    if self.menu.combo.rset.c0:get() then
        return true, needIgnite
    end
    if self.menu.combo.rset.c1:get() and navmesh.isWall(target.pos) then
        return true, needIgnite
    end
    if self.menu.combo.rset.c2:get() and player.health / player.maxHealth <= target.health / target.maxHealth then
        return true, needIgnite
    end
    if self.menu.combo.rset.c3:get() and player.health / player.maxHealth <= self.menu.combo.rset.c3:get() / 100 then
        return true, needIgnite
    end
    if
        self.menu.combo.rset.c4:get() and player:spellSlot(0).state == 0 and
            target.health -
                common.CalculateMagicDamage(
                    
                    target,
                    30 + 40 * player:spellSlot(0).level + 0.65 * self:GetTotalAp()
                ) <=
                0
     then
        return false
    end
    enemiesInRange1, enemiesInRange2, alliesInRange = 0, 0, 0
    for _, enemy in ipairs(self.enemyHeroes) do
        if GetDistanceSqr(enemy.pos) <= 640000 then -- 800 range
            enemiesInRange1 = enemiesInRange1 + 1
        end
        if GetDistanceSqr(enemy.pos) <= 6250000 then --2500 range
            enemiesInRange2 = enemiesInRange2 + 1
        end
    end
    for _, ally in ipairs(self.allyHeroes) do
        if GetDistanceSqr(ally.pos) <= 640000 then -- 800 range
            alliesInRange = alliesInRange + 1
        end
    end
    if self.menu.combo.rset.c5:get() and enemiesInRange1 > alliesInRange then
        return true, needIgnite
    end
    if self.menu.combo.rset.c6:get() and player.mana < 200 then
        return true, needIgnite
    end
    if target.characterIntermediate.spellBlock < self.menu.combo.rset.c7:get() then
        return true, needIgnite
    end
    if enemiesInRange2 <= self.menu.combo.rset.c8:get() then
        return true, needIgnite
    end
end

function Syndra:CastR(target)
    local shouldCast, needIgnite = self:RConditions(target)
    if shouldCast then
        player:castSpell("obj", 3, target)
        if needIgnite then
            player:castSpell("obj", self.ignite, target)
        end
        self.last.r = clock() + 0.5
        --PrintChat("r")
        return true
    end
end

function Syndra:OnCreateObj(obj)
    if obj and obj.name == "Seed" and obj.owner.charName == "Syndra" then
        local replaced = false
        for i in ipairs(self.orbs) do
            local orb = self.orbs[i]
            if not orb.isInitialized and GetDistanceSqr(obj.pos, orb.obj.pos) == 0 then
                self.orbs[i] = {obj = obj, isInitialized = true, isCasted = true, endT = clock() + 6.25}
                replaced = true
            end
        end
        if not replaced then
            self.orbs[#self.orbs + 1] = {obj = obj, isInitialized = true, isCasted = true, endT = clock() + 6.25}
        end
    end
    if match(obj.name, "Syndra") then
        if
            match(obj.name, "Q_tar_sound") or
                match(obj.name, "W_tar") and
                   player.buff[string.lower("ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua")]
         then
            for _, enemy in ipairs(self.enemyHeroes) do
                if enemy.isVisible and GetDistanceSqr(enemy.pos, obj.pos) < 1 then
                    if not self.electrocuteTracker[enemy.networkID] then
                        self.electrocuteTracker[enemy.networkID] = {}
                    end
                    insert(self.electrocuteTracker[enemy.networkID], clock())
                end
            end
        elseif match(obj.name, "E_tar") then
            local isOrb = false
            for i in ipairs(self.orbs) do
                if GetDistanceSqr(self.orbs[i].obj.pos, obj.pos) < 1 then
                    isOrb = true
                end
            end
            if not isOrb then
                local electrocute =
                player.buff[string.lower("ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua")]
                for _, enemy in ipairs(self.enemyHeroes) do
                    if electrocute and enemy.isVisible and GetDistanceSqr(enemy.pos, obj.pos) < 1 then
                        if not self.electrocuteTracker[enemy.networkID] then
                            self.electrocuteTracker[enemy.networkID] = {}
                        end
                        insert(self.electrocuteTracker[enemy.networkID], clock())
                    end
                    if self.spell.w.blacklist2 and enemy.networkID == self.spell.w.blacklist2.target then
                        self.spell.w.blacklist2 = nil
                    --PrintChat("e detected")
                    end
                end
            end
        end
    end

    if (obj.name:find("_W_heldTarget_buf_02")) then
        self.HeanderW_target[obj.ptr] = obj
    end 
end

function Syndra:OnDeleteObj(obj)
    if obj then
        for i in ipairs(self.orbs) do
            if self.orbs[i].obj == obj then
                remove(self.orbs, i)
            end
        end
    end
end

function Syndra:OnProcessSpell(spell)
    if spell and spell.owner.team == player.team and spell.owner.charName == "Syndra" then
        if spell.name == "SyndraQ" then
            self.last.q = clock() + 0.15
            local replaced = false
            for i in pairs(self.orbs) do
                local orb = self.orbs[i]
                if not orb.isInitialized and not orb.isCasted and GetDistanceSqr(spell.owner.pos, orb.obj.pos) == 0 then
                    self.orbs[i] = {
                        obj = {position = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)},
                        isInitialized = false,
                        isCasted = true,
                        endT = clock() + 0.625
                    }
                    replaced = true
                end
            end
            if not replaced then
                self.orbs[#self.orbs + 1] = {
                    obj = {position = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)},
                    isInitialized = false,
                    isCasted = true,
                    endT = clock() + 0.625
                }
            end
        elseif spell.name == "SyndraW" then
            self.last.w = clock() + 0.15
        elseif spell.name == "SyndraWCast" then
            self.last.w = clock() + 0.15
            self.spell.e.next = {
                time = clock() + self.spell.w.delay,
                pos = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)
            }
        elseif spell.name == "SyndraE" then
            self:CheckHitOrb(vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z))
            self.last.e = clock()
        elseif spell.name == "SyndraR" then
            self.timer = clock() + 0.15
        end
    end
end

function Syndra:GetTotalAp()
    return player.baseAbilityDamage +
    player.flatMagicDamageMod * (1 + player.percentMagicDamageMod)
end

cb.add(cb.error, function(msg)
    local log, e = io.open(hanbot.path..'/SyndraLogs.txt', 'w+')
    if not log then
      print(e)
      return
    end
    log:write(msg)
    log:close()
end)

return Syndra:__init()