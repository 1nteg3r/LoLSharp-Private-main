local pMenu = module.load(header.id, "Core/Illaoi/menu")
local common = module.load(header.id, "Library/common")
local dmgLib = module.load(header.id, "Library/damageLib")
local GeoLib = module.load(header.id, "Geometry/GeometryLib")

local orb = module.internal("orb")
local evade = module.seek('evade')
local gpred = module.internal("pred")

local menu = pMenu.menu 
local TS = pMenu.TS 
local Vector = GeoLib.Vector

local Tentacle = {
    Avatar = { } 
}

local Spirit = {
    IllaoiSpiritBase =  { }
}

local player_position = player.pos 
local lastAutoAtacck = nil 
local lastAAtime = os.clock()

local q_pred = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.75,
    speed = 2147483647, --2147483647
    width = 100,
    range = 800,
}

local e_pred = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 1900,
    width = 60,
    range = 950, 
    collision = { hero = false, minion = true }
}


local RetanglePoint = function(basePos, targetPosition)
    local rect = GeoLib.Polygon
    local range = 800
    local start_v = Vector(basePos)
    local dir_v = (Vector(targetPosition) - start_v):normalized()
    local end_v = start_v + (dir_v * range)
    local side_v = dir_v:perpendicular() * (225 / 2)
    local p1 = start_v + side_v
    local p2 = start_v - side_v
    local p3 = end_v + side_v
    local p4 = end_v - side_v
    local myR = rect(p1, p2, p4, p3)
    return myR
end

local trace_filter = function(input, seg, obj)
    if seg.startPos:dist(seg.endPos) > input.range then return false end

    if gpred.trace.linear.hardlock(input, seg, obj) then
        return true
    end
    if gpred.trace.linear.hardlockmove(input, seg, obj) then
        return true
    end
    if gpred.trace.newpath(obj, 0.033, 0.500) then
        return true
    end
end

local canCastW = function()
    if player:spellSlot(0).state ~= 0 and player:spellSlot(2).state ~= 0 then 
        return true 
    end 
end 

local Combo = function()
    if target and target ~= nil and common.IsValidTarget(target) then 

        if menu.combo['use.e']:get() and player:spellSlot(2).state == 0 and common.GetDistanceSqr(player, target) < menu.combo['max.e.range']:get() ^ 2 then 
            local seg = gpred.linear.get_prediction(e_pred, target, vec2(player_position.x, player_position.z))
            if seg and player_position:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.combo['max.e.range']:get() ^ 2 
            and vec3(seg.startPos.x, mousePos.y, seg.startPos.y):distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.combo['max.e.range']:get() ^ 2 and target.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.combo['max.e.range']:get() ^ 2 then 
                local col = gpred.collision.get_prediction(e_pred, seg)
                local collision = { }
                if col then 
                    for i = 1, #col do
                        collision[#collision+1] = col
                    end 
                end
                if #collision == 0 then 
                    if (not menu.combo['use.e.pred.low']:get() or trace_filter(e_pred, seg, target)) and not player.buff['illaoiw'] then 
                        player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                    end 
                end 
            end 
        end 

        if menu.combo['use.q']:get() and player:spellSlot(0).state == 0 and common.GetDistanceSqr(player, target) < menu.combo['max.q.range']:get() ^ 2 then 
            local seg = gpred.linear.get_prediction(e_pred, target, vec2(player_position.x, player_position.z))

            if seg and player_position:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.combo['max.q.range']:get() ^ 2 
            and vec3(seg.startPos.x, mousePos.y, seg.startPos.y):distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.combo['max.q.range']:get() ^ 2 and target.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.combo['max.q.range']:get() ^ 2 then 
                for i, Base in pairs(Spirit.IllaoiSpiritBase) do
                    if Base then 

                        local rect = RetanglePoint(player.pos, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        if Vector(Base):insideOf(rect) then
                            player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end
                    end 
                end
                local rect2 = RetanglePoint(player.pos, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                if Vector(player):insideOf(rect2) then
                    if (not menu.combo['use.q.pred.low']:get() or trace_filter(q_pred, seg, target)) and not player.buff['illaoiw'] then  
                        player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                    end
                end
            end 
        end

        if menu.combo['use.w']:get() and player:spellSlot(1).state == 0 then 
            local coutAvatar = { }
            
            for i, Avatar in pairs(Tentacle.Avatar) do
                if Avatar and common.GetDistanceSqr(target, Avatar) < 800 ^ 2 then  
                    coutAvatar[#coutAvatar + 1] = Avatar
                end 
            end 

            if common.GetDistanceSqr(player, target) > common.GetAARange(player) and common.GetDistanceSqr(target, player) <= (((common.GetAARange(player)) + 225) - player.boundingRadius) ^ 2 then 
                player:castSpell("self", 1)
                player:attack(target) 
            end 

            if menu.combo['use.only']:get() and #coutAvatar == 0 then 
                return 
            end 

            if common.GetDistanceSqr(player, target) > common.GetAARange(player) and common.GetDistanceSqr(target, player) <= (((common.GetAARange(player)) + 225) - player.boundingRadius) ^ 2 then 
                player:castSpell("self", 1)
                player:attack(target) 
            end 
        end 

        if menu.combo['use.r']:get() and player:spellSlot(3).state == 0 then 

            local coutAvatar = { }
            local countSpirit = { }

            for i, Avatar in pairs(Tentacle.Avatar) do
                if Avatar and common.GetDistanceSqr(target, Avatar) < 800 ^ 2 then  
                    coutAvatar[#coutAvatar + 1] = Avatar
                end 
            end 

            for i, Base in pairs(Spirit.IllaoiSpiritBase) do
                if Base and common.GetDistanceSqr(player, Base) < 500 then 
                    countSpirit[#countSpirit+1] = Base
                end 
            end 

            if #common.CountEnemiesInRange(player.pos, 700) == 1 then 
                if #coutAvatar > 0 and #countSpirit > 0 and player:spellSlot(0).state == 0 and player:spellSlot(1).state == 0 then 
                    player:castSpell("self", 3)
                end 

                if menu.combo['force.r']:get() and common.GetPercentHealth(player) <= menu.combo['healthMy']:get() then 
                    player:castSpell("self", 3)
                end 
            elseif #common.CountEnemiesInRange(player.pos, 700) >= menu.combo['use.around.enemies']:get() then
                if #coutAvatar > 0 and #countSpirit > 0 and player:spellSlot(0).state == 0 and player:spellSlot(1).state == 0 then 
                    player:castSpell("self", 3)
                elseif #coutAvatar > 0 and player:spellSlot(0).state == 0 and player:spellSlot(1).state == 0 then 
                    player:castSpell("self", 3)
                elseif player:spellSlot(0).state == 0 and player:spellSlot(1).state == 0 then 
                    player:castSpell("self", 3)
                end 
            end
        end 
    end
end 

local Harass = function()
    if target and target ~= nil and common.IsValidTarget(target) then 

        if menu.harass['use.e']:get() and player:spellSlot(2).state == 0 and common.GetDistanceSqr(player, target) < menu.harass['max.e.range']:get() ^ 2 and common.GetPercentMana(player) > menu.harass['percentMana.e']:get() then 
            local seg = gpred.linear.get_prediction(e_pred, target, vec2(player_position.x, player_position.z))
            if seg and player_position:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.harass['max.e.range']:get() ^ 2 
            and vec3(seg.startPos.x, mousePos.y, seg.startPos.y):distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.harass['max.e.range']:get() ^ 2 and target.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.harass['max.e.range']:get() ^ 2 then 
                local col = gpred.collision.get_prediction(e_pred, seg)
                local collision = { }
                if col then 
                    for i = 1, #col do
                        collision[#collision+1] = col
                    end 
                end
                if #collision == 0 then 
                    if (not menu.combo['use.e.pred.low']:get() or trace_filter(e_pred, seg, target)) and not player.buff['illaoiw'] then 
                        player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                    end 
                end 
            end 
        end 

        if menu.harass['use.q']:get() and player:spellSlot(0).state == 0 and common.GetDistanceSqr(player, target) < menu.harass['max.q.range']:get() ^ 2 and common.GetPercentMana(player) > menu.harass['percentMana.q']:get() then  
            local seg = gpred.linear.get_prediction(e_pred, target, vec2(player_position.x, player_position.z))

            if seg and player_position:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.harass['max.q.range']:get() ^ 2 
            and vec3(seg.startPos.x, mousePos.y, seg.startPos.y):distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.harass['max.q.range']:get() ^ 2 and target.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < menu.harass['max.q.range']:get() ^ 2 then 
                for i, Base in pairs(Spirit.IllaoiSpiritBase) do
                    if Base then 

                        local rect = RetanglePoint(player.pos, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        if Vector(Base):insideOf(rect) then
                            player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                        end
                    end 
                end
                local rect2 = RetanglePoint(player.pos, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                if Vector(player):insideOf(rect2) then
                    if (not menu.combo['use.q.pred.low']:get() or trace_filter(q_pred, seg, target)) and not player.buff['illaoiw'] then  
                        player:castSpell("pos", 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                    end
                end
            end 
        end

        if menu.harass['use.w']:get() and player:spellSlot(1).state == 0 and common.GetPercentMana(player) > menu.harass['percentMana.w']:get() then  
   
            if common.GetDistanceSqr(player, target) > common.GetAARange(player) and common.GetDistanceSqr(target, player) <= (((common.GetAARange(player)) + 225) - player.boundingRadius) ^ 2 then 
                player:castSpell("self", 1)
                player:attack(target) 
            end 
        end 
    end 
end

local last_hit = function()
    local enemyMinions = common.GetMinionsInRange(600, TEAM_ENEMY)
    for i, minion in pairs(enemyMinions) do
        if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and minion.maxHealth > 5 and (not lastAutoAtacck or lastAutoAtacck ~= minion) and
        common.GetDistanceSqr(minion) <= (common.GetAARange(player) + minion.boundingRadius) ^ 2 and (not orb.core.can_attack() or (common.GetAARange(player) <= common.GetDistance(minion))) then 
            local dmg = dmgLib.GetSpellDamage(1, minion)
            if dmg > orb.farm.predict_hp(minion, 0.25) then
                player:castSpell("self", 1)
                player:attack(minion)
            end
        end 
    end 
end

local LaneClear = function()
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
        local current_pos = player.path.serverPos + ((minion_a.path.serverPos - player.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos) + 800))
        local hit_count = 1
        for j = 1, #valid do
            if j ~= i then
                local minion_b = valid[j]
                local point = mathf.closest_vec_line(minion_b.path.serverPos, player.path.serverPos, current_pos)
                if point and point:dist(minion_b.path.serverPos) < (50 + minion_b.boundingRadius) then
                    hit_count = hit_count + 1
                end
            end
        end
        if not cast_pos or hit_count > max_count then
            cast_pos, max_count = current_pos, hit_count
        end
        if cast_pos and max_count > menu.wave['use.q.around']:get() then
            player:castSpell("pos", 0, cast_pos)
            break
        end
    end
end


local on_tick = function()
    pMenu.valid_menu()

    local myPos = gpred.core.get_pos_after_time(player, math.floor((network.latency - 0.033) / 0.05) * 0.05)
    player_position = vec3(myPos.x, player.y, myPos.y)

    if lastAAtime and os.clock() - lastAAtime > 0.3 then 
        lastAutoAtacck = nil 
    end 

    target = TS.target 

    if orb.menu.combat.key:get() then 
        Combo()
    end

    if orb.menu.hybrid.key:get() then 
        Harass()
    end 

    if (orb.menu.last_hit.key:get() or orb.menu.lane_clear.key:get()) then 
        if common.GetPercentMana(player) > menu.wave['percentMana.clear']:get() then 
            if menu.wave['use.w']:get() then 
                last_hit()
            end 

            LaneClear()
        end
    end 
end 

local AfterAttack = function()
    if target and target ~= nil and common.IsValidTarget(target) then 

        if menu.combo['use.aa.reset']:get() and player:spellSlot(1).state == 0 then 
            if common.GetDistanceSqr(target, player) <= (((common.GetAARange(player)) + 225) - player.boundingRadius) ^ 2 then 
                player:castSpell("self", 1)
                player:attack(target) 
            end 
        end 
    end 
end 

local on_create_obj = function(obj)
    if obj then 
        if obj.name:find("TentacleAvatarActive") then
            Tentacle.Avatar[obj.ptr] = obj 
        end 

        if obj.name:find("Base_E_SpiritTimer") then
            Spirit.IllaoiSpiritBase[obj.ptr] = obj 
        end 
    end
end 

local on_delete_obj = function(obj)
    if not obj then 
        return 
    end 

    for i, Avatar in pairs(Tentacle.Avatar) do
        if Avatar then 
            if Avatar == obj then 
                Tentacle.Avatar[obj.ptr] = nil
            end 
        end
    end 

    for i, IllaoiSpiritBase in pairs(Spirit.IllaoiSpiritBase) do
        if IllaoiSpiritBase then 
            if IllaoiSpiritBase == obj then 
                Spirit.IllaoiSpiritBase[obj.ptr] = nil
            end 
        end
    end 
end 

local on_process_spell = function(spell)
    if spell and spell.owner.charName == "Illaoi" and spell.owner.team == player.team then 

        if spell.isBasicAttack then 
            lastAutoAtacck = spell.target
            lastAAtime = os.clock() + spell.windUpTime
        end 
    end 
end 

local on_draw = function()
    if player.isDead or player.buff[17] then 
        return 
    end 

    if not player.isOnScreen then 
        return 
    end 

    --Color
    local qColor = menu.draws['qcolor']:get()
    local wColor = menu.draws['wcolor']:get()
    local eColor = menu.draws['ecolor']:get()
    local rColor = menu.draws['rcolor']:get()

    --Orther 
    local Points = menu.draws['points_n']:get()
    local WidthCircle = menu.draws['widthLine']:get()

    if menu.draws['qrange']:get() and player:spellSlot(0).state == 0 then 
        graphics.draw_circle(player.pos, menu.combo['max.q.range']:get(), WidthCircle, qColor, Points)
    end 

    if menu.draws['wrange']:get() and player:spellSlot(1).state == 0 then 
        graphics.draw_circle(player.pos, ((common.GetAARange(player) + 225) - player.boundingRadius), WidthCircle, wColor, Points)
    end 

    if menu.draws['wrange']:get() and player:spellSlot(2).state == 0 then 
        graphics.draw_circle(player.pos, menu.combo['max.e.range']:get(), WidthCircle, eColor, Points)
    end 

    if menu.draws['rrange']:get() and player:spellSlot(3).state == 0 then 
        graphics.draw_circle(player.pos, 500, WidthCircle, rColor, Points)
    end 

end 

return {
    on_tick = on_tick,
    on_create_obj = on_create_obj, 
    on_delete_obj = on_delete_obj,
    on_draw = on_draw, 
    AfterAttack = AfterAttack, 
    on_process_spell = on_process_spell 
}