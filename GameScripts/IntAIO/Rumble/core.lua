local pMenu = module.load(header.id, "Core/Rumble/menu")
local common = module.load(header.id, "Library/common")
local dmgLib = module.load(header.id, "Library/damageLib")
local GeoLib = module.load(header.id, "Geometry/GeometryLib")
local Prediction = module.load(header.id, "iPrediction/main")

local orb = module.internal("orb")
local evade = module.seek('evade')
local gpred = module.internal("pred")

local menu = pMenu.menu 
local Vector = GeoLib.Vector

local Window = {x = graphics.res.x * 0.5, y = graphics.res.y * 0.5}
local pos = {x = Window.x, y = Window.y}


local E = {
    delay = 0.25, 
    width = 120, 
    range = 840,
    speed = 2000, 
    boundingRadiusMod = 1, 
    collision = {hero = true, minion = true, wall = true},
}

local R = {
    delay = 0.25, 
    width = 90, 
    range = 1700,
    speed = 1600, 
    boundingRadiusMod = 1, 
}

local TargetSelectorQ = function(res, obj, dist)
    if dist > 625 then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj.buff[BUFF_INVULNERABILITY] then 
        return false 
    end 

    res.obj = obj 
    return true 
end 

local TargetSelectorW = function(res, obj, dist)
    if dist > menu.combo['min.rangeW']:get() then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj.buff[BUFF_INVULNERABILITY] then 
        return false 
    end 

    res.obj = obj 
    return true 
end 

local TargetSelectorE = function(res, obj, dist)
    if dist > 950 then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj.buff[BUFF_INVULNERABILITY] then 
        return false 
    end 

    res.obj = obj 
    return true 
end 

local TargetSelectorR = function(res, obj, dist)
    if dist > menu.combo['min.range']:get() then 
        return 
    end 

    if not obj then 
        return 
    end 

    if obj.buff[BUFF_INVULNERABILITY] then 
        return false 
    end 

    res.obj = obj 
    return true 
end 

local GetTargetFlamespitter = function() --q 
    return orb.ts.get_result(TargetSelectorQ).obj
end 

local GetTargetW = function()
    return orb.ts.get_result(TargetSelectorW).obj
end 

local GetTargetElectro = function() --e 
    return orb.ts.get_result(TargetSelectorE).obj
end 

local GetTargetEqualizer = function() --r
    return orb.ts.get_result(TargetSelectorR).obj
end 

local IsReady = function(spell)
    if player:spellSlot(spell).state == 0 then 
        return true 
    end 
    return false 
end 

local OverLoad = function(spellSlot)
    if spellSlot == "Q" then 
        return not IsReady(1) and not IsReady(2) and not IsReady(3)
    elseif spellSlot == "W" then 
        return not IsReady(0) and not IsReady(2) and  not IsReady(3)
    elseif spellSlot == "E" then 
        return not IsReady(0) and not IsReady(1) and  not IsReady(3)
    elseif spellSlot == "R" then 
        return not IsReady(0) and not IsReady(1) and not IsReady(2)
    end 
end 

local IsFacing = function(source, target, angle)
    source = source or player
    angle = angle or 90 

    if not target then 
        return 
    end 

   
    local unitPosition = Vector(target.pos)

    local DirectionSource = Vector(player.direction):normalized()
    local DirectionReal = Vector(player.pos) + (player.boundingRadius * DirectionSource:toDX3())
    
    if Vector(DirectionReal:toDX3()):AngleBetween(Vector(unitPosition - Vector(player.pos)), Vector(player)) < angle then 
        return true 
    end 
    return false
end

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

--[[Thinking...]]
local function BestPosition(enemies, width, range, minenemies, Position)
    local enemyCount = 0
    local startPos = Position
    local result = Vector(0,0,0)
end

local Combo = function()
    if menu.combo['use.e']:get() and player:spellSlot(2).state == 0 then 
        local targetE = GetTargetElectro()
        if targetE and targetE ~= nil and common.IsValidTarget(targetE) then 
            local result, castPos, hitChance = Prediction.getPrediction(targetE, player, E, "linear", true)
            if result and castPos and player.pos:distSqr(castPos) < 840 ^ 2 and (OverLoad("E") or player.mana < 80) then  
                if hitChance >= 3 and not module.internal("pred").collision.get_prediction(E, result, targetE) then 
                    player:castSpell("pos", 2, castPos)
                end 
            end 
        end
    end 

    if menu.combo['use.w']:get() and not menu.combo['use.only.q']:get() then 
        local targetW = GetTargetW()

        if targetW and targetW ~= nil and common.IsValidTarget(targetW) then 
            if targetW.activeSpell and targetW.activeSpell.isBasicAttack and targetW.activeSpell.target == player then 
                player:castSpell("self", 1, player)
            end 
        end 
    end

    if menu.combo['use.q']:get() and player:spellSlot(0).state == 0 then 
        local targetQ = GetTargetFlamespitter()
        if targetQ and targetQ ~= nil and common.IsValidTarget(targetQ) then 
            if IsFacing(player, targetQ, 64) and (OverLoad("Q") or player.mana < 80) then 
                player:castSpell("pos", 0, targetQ.pos)
            end 

            if player.buff[string.lower"RumbleFlameThrower"] and player:spellSlot(1).state == 0 then 
                if menu.combo['use.w']:get() and menu.combo['use.only.q']:get() and player.mana >= 80 then 
                    player:castSpell("self", 1, player)
                end 
            end 
        end 
    end
    
    if menu.combo['use.r']:get() and player:spellSlot(3).state == 0 then 
        local target = GetTargetEqualizer()
        if target and target ~= nil and common.IsValidTarget(target) then 
            local result, castPos, hitChance = Prediction.getPrediction(target, player, R, "linear", false)
            if result and castPos and player.pos:distSqr(castPos) < menu.combo['min.range']:get() ^ 2 and (not menu.combo['no.use.underTower']:get() or common.IsUnderDangerousTower(target.pos)) then  
                if #common.GetEnemyHeroesInRange(1200, player.pos) == 1 and target.pos:distSqr(player.pos) > E.range then 
                    if menu.combo['use.rforkill']:get() and (dmgLib.GetSpellDamage(0, target) + dmgLib.GetSpellDamage(2, target) + dmgLib.GetSpellDamage(3, target)) >= common.GetShieldedHealth("AP", target) then 

                        local c = target.pos
                        local l = 130
                        local r = 300
                        local f = -300
                        local s = 1600
                        local cPosNotPath = Vector(target.pos):extended(Vector(target.path.point[target.path.count]), 360):toDX3()

                        for i = 0, l, 1 do
                            local _X = c.x - 50
                            local _Z = c.z + 100 
                            local RPOS = vec3(_X, 0, _Z)

                            local startPos = target.path.point[0]
                            local endPos = target.path.point[target.path.count]
            
                            if target.path.isActive then 
                                player:castSpell("line", 3, RPOS, endPos)
                            else 
                                player:castSpell("line", 3, cPosNotPath, target.pos)
                            end 
                        end 
                    end     
                elseif #common.GetEnemyHeroesInRange(1200, player.pos) >= menu.combo['min.enemies.Around']:get() then 
                    for i=0, objManager.enemies_n-1 do
                        local obj = objManager.enemies[i]

                        if obj and obj ~= nil and common.IsValidTarget(obj) and obj.ptr ~= target.ptr then 
                            if common.GetDistance(player, obj) < menu.combo['min.range']:get() and common.GetDistance(obj, target) < 1100 then 
                                player:castSpell("line", 3, target.path.point[target.path.count], obj.path.point[obj.path.count])
                            end 
                        end 
                    end 
                end 
            end 
        end 
    end 
end 

local AutoE = function()
    if common.GetPercentMana(player) > menu.harass['min.Mana']:get() then 
        return 
    end 

    if player:spellSlot(2).state == 0 then 
        local targetE = GetTargetElectro()
        if targetE and targetE ~= nil and common.IsValidTarget(targetE) then 
            local result, castPos, hitChance = Prediction.getPrediction(targetE, player, E, "linear", true)
            if result and castPos and player.pos:distSqr(castPos) < 840 ^ 2 and (OverLoad("E") or player.mana < 80) then  
                if hitChance >= 3 and not module.internal("pred").collision.get_prediction(E, result, targetE) then 
                    player:castSpell("pos", 2, castPos)
                end 
            end 
        end
    end 
end

local CastR = function()
    if player:spellSlot(3).state ~= 0 then 
        return
    end 

    local target = GetTargetEqualizer()
    if target and target ~= nil and common.IsValidTarget(target) then 
        local result, castPos, hitChance = Prediction.getPrediction(target, player, R, "linear", false)
        if result and castPos and player.pos:distSqr(castPos) < menu.combo['min.range']:get() ^ 2 and (not menu.combo['no.use.underTower']:get() or common.IsUnderDangerousTower(target.pos)) then  
            local c = target.pos
            local l = 130
            local r = 300
            local f = -300
            local s = 1600

            local cPosNotPath = Vector(target.pos):extended(Vector(target.path.point[target.path.count]), 360):toDX3()
            for i = 0, l, 1 do
                local _X = c.x - 50
                local _Z = c.z + 100 
                local RPOS = vec3(_X, 0, _Z)

                local startPos = target.path.point[0]
                local endPos = target.path.point[target.path.count]

                if target.path.isActive then 
                    player:castSpell("line", 3, RPOS, endPos)
                else 
                    player:castSpell("line", 3, cPosNotPath, target.pos)
                end 
            end 
        end 
    end 
end 

local KillSteal = function()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and target ~= nil and common.IsEnemyMortal(target) and common.IsValidTarget(target) then 
            if menu.misc.Killsteal['qKill']:get() and player:spellSlot(0).state == 0 and common.GetDistance(player, target) < 600 then 
                if dmgLib.GetSpellDamage(0, target) >= common.GetShieldedHealth("AP", target) then 
                    if IsFacing(player, target, 64) then 
                        player:castSpell("pos", 0, target.pos)
                    end 
                end 
            end 
            if menu.misc.Killsteal['eKill']:get() and player:spellSlot(2).state == 0 and common.GetDistance(player, target) < 840 then 
                local result, castPos, hitChance = Prediction.getPrediction(target, player, E, "linear", true)
                if result and castPos and player.pos:distSqr(castPos) < 840 ^ 2 then  
                    if hitChance >= 3 and not module.internal("pred").collision.get_prediction(E, result, target) then 
                        if dmgLib.GetSpellDamage(2, target) >= common.GetShieldedHealth("AP", target) then 
                            player:castSpell("pos", 2, castPos)
                        end 
                    end 
                end 
            end 
            if menu.misc.Killsteal['rKill']:get() and player:spellSlot(3).state == 0 and common.GetDistance(player, target) < 1700 then 
                local result, castPos, hitChance = Prediction.getPrediction(target, player, R, "linear", false)
                if result and castPos and player.pos:distSqr(castPos) < 1700 ^ 2 then  
                    local c = target.pos
                    local l = 130
                    local r = 300
                    local f = -300
                    local s = 1600
        
                    local cPosNotPath = Vector(target.pos):extended(Vector(target.path.point[target.path.count]), 360):toDX3()
                    for i = 0, l, 1 do
                        local _X = c.x - 50
                        local _Z = c.z + 100 
                        local RPOS = vec3(_X, 0, _Z)
        
                        local startPos = target.path.point[0]
                        local endPos = target.path.point[target.path.count]
                        if dmgLib.GetSpellDamage(3, target) >= common.GetShieldedHealth("AP", target) then 
                            if target.path.isActive then 
                                player:castSpell("line", 3, RPOS, endPos)
                            else 
                                player:castSpell("line", 3, cPosNotPath, target.pos)
                            end 
                        end 
                    end 
                end 
            end 
        end 
    end 
end

local Harass = function()
    if menu.harass['use.e']:get() and player:spellSlot(2).state == 0 and common.GetPercentMana(player) < menu.harass['min.ManaforE']:get() then 
        local targetE = GetTargetElectro()
        if targetE and targetE ~= nil and common.IsValidTarget(targetE) then 
            local result, castPos, hitChance = Prediction.getPrediction(targetE, player, E, "linear", true)
            if result and castPos and player.pos:distSqr(castPos) < 840 ^ 2 and (OverLoad("E") or player.mana < 80) then  
                if hitChance >= 3 and not module.internal("pred").collision.get_prediction(E, result, targetE) then 
                    player:castSpell("pos", 2, castPos)
                end 
            end 
        end
    end 

    if menu.harass['use.q']:get() and player:spellSlot(0).state == 0 and common.GetPercentMana(player) < menu.harass['min.ManaforQ']:get() then  
        local targetQ = GetTargetFlamespitter()
        if targetQ and targetQ ~= nil and common.IsValidTarget(targetQ) then 
            if IsFacing(player, targetQ, 64) and (OverLoad("Q") or player.mana < 80) then 
                player:castSpell("pos", 0, targetQ.pos)
            end 
        end 
    end
end 

local WaveClear = function()
    local target = { obj = nil, health = 0, mode = "jungleclear" }
	local aaRange = 600
	for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
		local obj = objManager.minions[TEAM_NEUTRAL][i]
		if player.pos:dist(obj.pos) <= aaRange and obj.maxHealth > target.health then
			target.obj = obj
			target.health = obj.maxHealth
		end
	end

    if not target.obj then
		for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
			local obj = objManager.minions[TEAM_ENEMY][i]
			if player.pos:dist(obj.pos) <= aaRange and obj.maxHealth > target.health then
				target.obj = obj
				target.health = obj.maxHealth
				target.mode = "laneclear"
			end
		end
	end

    if target.obj and target.mode == "jungleclear" then 
        if menu.wave['use.q']:get() and player.mana < menu.wave['mana.q']:get() then 
            if target.obj and target.obj ~= nil and common.GetDistance(target.obj, player) then 
                if player:spellSlot(0).state == 0 then 
                    player:castSpell("pos", 0, target.obj.pos)
                end 
            end 
        end 

        if menu.wave['use.e']:get() and player.mana < menu.wave['min.e']:get() then 
            local result, castPos, hitChance = Prediction.getPrediction(target.obj , player, E, "linear", true)
            if result and castPos and player.pos:distSqr(castPos) < 840 ^ 2 and (OverLoad("E") or player.mana < 80) then  
                if hitChance >= 3 and not module.internal("pred").collision.get_prediction(E, result, target.obj ) then 
                    player:castSpell("pos", 2, castPos)
                end 
            end 
        end
    end 
end

local on_tick = function()
    KillSteal()
    if menu.harass['toggleAutoE']:get() then 
        AutoE()
    end 

    if menu.combo['SemiR']:get() then 
        player:move(mousePos)
        CastR()
    end 

    if orb.menu.combat.key:get() then 
        Combo()
    end 

    if orb.menu.hybrid.key:get() then 
        Harass()
    end 

    if orb.menu.lane_clear.key:get() then 
        WaveClear()
    end 
end 

local on_draw = function()
    if menu.draws['drawtoggles']:get() then 

        if menu.harass.toggleAutoE:get() then
            graphics.draw_text_2D("["..menu.harass.toggleAutoE.toggle.."] Auto E: ", 18, pos.x + 307, pos.y + 438, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("On", 18, pos.x + 420, pos.y + 438, graphics.argb(255, 7, 219, 63))
        else
            graphics.draw_text_2D("["..menu.harass.toggleAutoE.toggle.."] Auto E: ", 18, pos.x + 307, pos.y + 438, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("Off", 18, pos.x + 420, pos.y + 438, graphics.argb(255, 219, 7, 7))
        end

        graphics.draw_line_2D(pos.x + 300, pos.y+435, pos.x + 535, pos.y+435, 35, 0xff1f1f1f)
        graphics.draw_line_2D(pos.x + 535, pos.y + 415, pos.x + 300, pos.y + 415, 3, 0xFFFFFFFF)
    end 

    if player.isDead or player.buff[17] then 
        return 
    end 

    if not player.isOnScreen then 
        return 
    end 

    --Color
    local qColor = menu.draws['qcolor']:get()
    local eColor = menu.draws['ecolor']:get()
    local rColor = menu.draws['rcolor']:get()

    --Orther 
    local Points = menu.draws['points_n']:get()
    local WidthCircle = menu.draws['widthLine']:get()

    if (player:spellSlot(0).state == 0 and menu.draws['qrange']:get()) then 
        graphics.draw_circle(player.pos, 600, WidthCircle, qColor, Points)
    end 

    if (player:spellSlot(2).state == 0 and menu.draws['erange']:get()) then 
        graphics.draw_circle(player.pos, 950, WidthCircle, eColor, Points)
    end 

    if (player:spellSlot(3).state == 0 and menu.draws['rrange']:get()) then 
        graphics.draw_circle(player.pos, 1700, WidthCircle, rColor, Points)
    end 
end 

return {
    on_tick = on_tick, 
    on_draw = on_draw
}