local pMenu = module.load(header.id, "Core/Darius/menu")
local common = module.load(header.id, "Library/common")
local dmgLib = module.load(header.id, "Library/damageLib")
local GeoLib = module.load(header.id, "Geometry/GeometryLib")

local orb = module.internal("orb")
local evade = module.seek('evade')
local gpred = module.internal("pred")

local menu = pMenu.menu 
local TS = pMenu.TS 
local Vector = GeoLib.Vector

local TargetSelector = {
    Range = 0, 
}

local Passive = {
    Count = 0, startTime = 0, endTime = 0, _time = 0
}

local spellQ = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 1500,
    width = 50,
    range = 535,
}
--[[local Window = {x = graphics.res.x * 0.5, y = graphics.res.y * 0.5}
local pos = {x = Window.x, y = Window.y}]]
local textWidth = graphics.text_area("1.00", 30)
local cleaveIsCasted = false 
local castedTime = os.clock()
local lastAutoAtacck = nil 
local lastAAtime = os.clock()

local PassiveDamage = function(target)
    if not target then 
        return 
    end 

    local damage = 0 

    if target.buff['dariushemo'] then 
        if target.buff['dariushemo'].stacks > 0 and target.buff['dariushemo'].stacks < 5 then 
            damage = ((3 + 0.25) * player.levelRef) + 0.075 * common.GetBonusAD()
        elseif target.buff['dariushemo'].stacks == 5 then 
            damage = ((15 + 1.25) * player.levelRef) + 0.375 * common.GetBonusAD()
        end 
    end 
        
    if (damage <= 0) then 
        return 0 
    end 

    return common.CalculatePhysicalDamage(target, damage)
end 

local RDamage = function(target, stacks)
    if not target then 
        return 
    end 

    if stacks <= 1 then 
        stacks = 1 
    end 

    if player:spellSlot(3).level == 0 then 
        return 0 
    end 

    local bonus = stacks * ({20, 40, 60})[player:spellSlot(3).level] + 0.15 * common.GetBonusAD(player)
    local damage = 0 
    if player:spellSlot(3).level > 0 then 
        damage = ({100, 200, 300})[player:spellSlot(3).level] + 0.75 * common.GetBonusAD(player)
    end 

    if damage <= 0 then 
        return 0 
    end 

    return common.CalculatePhysicalDamage(target, bonus) + common.CalculatePhysicalDamage(target, damage)
end 

local LoadPassiveTarget = function()
    if not target then 
        return 
    end 

    if target.buff['dariushemo'] then 
        Passive.Count = target.buff['dariushemo'].stacks 
        Passive.startTime = target.buff['dariushemo'].startTime 
        Passive.endTime = target.buff['dariushemo'].endTime 
    end 

    if not target.buff['dariushemo'] then 
        Passive.Count = 0
        Passive.startTime = 0 
        Passive.endTime = 0
    end 
end 

local CirclePoints = function(CircleLineSegmentN, radius, position)
    local points = {}
    for i = 1, CircleLineSegmentN, 1 do
        local angle = i * 2 * math.pi / CircleLineSegmentN
        local point = vec3(position.x + radius * math.cos(angle), position.y, position.z + radius * math.sin(angle));
        table.insert(points, point)
    end 
    return points 
end

local CanCastQ = function(target)
    if not target then 
        return 
    end 

    if target.buff[BUFF_INVULNERABILITY] or target.buff[BUFF_SPELLSHIELD] then 
        return false 
    end 

    if player:spellSlot(3).state == 0 and player.mana - player.manaCost0 < player.manaCost3 then 
        return false 
    end 

    if (player:spellSlot(1).state == 0 or player.buff['dariusnoxiantacticsonh']) and common.GetDistanceSqr(player, target) <= 350 ^ 2 then 
        return false 
    end 

    if player.path.serverPos2D:distSqr(target.path.serverPos2D) > 450 ^ 2 then 
        return false 
    end 

    if player:spellSlot(3).state == 0 and common.GetDistanceSqr(target, player) <= 475 ^ 2 and (RDamage(target, Passive.Count) - PassiveDamage(target)) >= common.GetShieldedHealth("ALL", target) then 
        return false 
    end 

    if common.GetDistance(target, player) <= common.GetAARange(target) and (common.CalculateAADamage(target) * 2) > common.GetShieldedHealth("AD", target) then
        return false 
    end 

    return true 
end 

local CanCastR = function(target)
    if not target then 
        return 
    end 

    if player:spellSlot(3).state == 0 and common.GetDistanceSqr(target, player) <= 475 ^ 2 and (dmgLib.GetSpellDamage(3, target)) >= common.GetShieldedHealth("AD", target) then 
        if menu.combo.rsettings['cast0']:get() then 
            return true 
        end 
    end 

    if player:spellSlot(3).state == 0 and common.GetDistanceSqr(target, player) <= 475 ^ 2 then 
        if menu.combo.rsettings['cast2']:get() and Passive.Count == 5 then 
            return true 
        end 
    end 

    if menu.combo.rsettings['cast3']:get() then 
        if common.GetDistance(target, player) <= common.GetAARange(target) and (common.CalculateAADamage(target) * 2) < common.GetShieldedHealth("AD", target) then
            return false 
        end 
    end 

    if menu.combo.rsettings['cast1']:get() then 
        if player:spellSlot(3).state == 0 and common.GetDistanceSqr(target, player) <= 475 ^ 2 then 
            if common.GetPercentHealth(player) <= menu.combo.rsettings['minHPMyHero']:get() and common.GetPercentHealth(target) <= menu.combo.rsettings['minHPTarget']:get() then 
                return true 
            end 
        end 
    end

    return false 
end 

local Combo = function()
    if target and target ~= nil and common.IsValidTarget(target) then 
        if menu.misc['Item']:get() then 
            for i = 6, 11 do
                local item = player:spellSlot(i).name
                if item and item == "6631Active" and common.GetDistance(target, player) < 445 then 
                    if cleaveIsCasted then 
                        player:castSpell("self", i)
                    end 
                end 
            end 
        end 
        if menu.combo['use.e']:get() and common.GetDistanceSqr(player, target) <= 535 ^ 2 then 
            local seg = gpred.linear.get_prediction(spellQ, target, vec2(player.x, player.z))
            if menu.combo['mode.e']:get() == 1 then 
                if common.GetDistanceSqr(player, target) > common.GetAARange(player) ^ 2 then 
                    if seg and seg.endPos and player.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < 525 ^ 2 and seg.startPos:distSqr(seg.endPos) < 525 ^ 2 and 
                    target.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < 525 ^ 2 then  
                        player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                    end 
                end 
            elseif menu.combo['mode.e']:get() == 2 then 
                if seg and seg.endPos and player.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < 525 ^ 2 and seg.startPos:distSqr(seg.endPos) < 525 ^ 2 and 
                target.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < 525 ^ 2 then  
                    player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
                end 
            end 
        end 

        if menu.combo['use.w']:get() and common.GetDistanceSqr(player, target) <= ((common.GetAARange(player)) + 25) ^ 2 then 
            if menu.combo['use.w.aa.reset']:get() and player:spellSlot(1).state == 0 then 
                if lastAutoAtacck and lastAutoAtacck == target and lastAAtime and os.clock() - lastAAtime > 0 then  
                    player:castSpell("self", 1)
                    player:attack(target)
                    orb.core.set_server_pause()
                    orb.combat.set_invoke_after_attack(false)
                end 
            elseif not menu.combo['use.w.aa.reset']:get() then 
                player:castSpell("self", 1)
                player:attack(target)
            end 
        end 

        if menu.combo['use.q']:get() and CanCastQ(target) and player.path.serverPos:distSqr(target.path.serverPos) < 450 ^ 2 then 
            if player:spellSlot(0).state == 0 then 
                player:castSpell("self", 0)
            end 
        end 

        if menu.combo['use.r']:get() and CanCastR(target) then 
            player:castSpell("obj", 3, target)
        end 
    end 
end 

local Harass = function()
    if target and target ~= nil and common.IsValidTarget(target) then 

        if menu.harass['use.e']:get() and common.GetDistanceSqr(player, target) <= 535 ^ 2 and common.GetPercentMana(player) > menu.harass['mana.e']:get() then 
            local seg = gpred.linear.get_prediction(spellQ, target, vec2(player.x, player.z))
            if seg and seg.endPos and player.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < 525 ^ 2 and seg.startPos:distSqr(seg.endPos) < 525 ^ 2 and 
            target.pos:distSqr(vec3(seg.endPos.x, mousePos.y, seg.endPos.y)) < 525 ^ 2 then  
                player:castSpell("pos", 2, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
            end 
        end 

        if menu.harass['use.w']:get() and common.GetDistanceSqr(player, target) <= ((common.GetAARange(player)) + 25) ^ 2 and common.GetPercentMana(player) > menu.harass['mana.w']:get() then 
            if menu.harass['use.w.aa.reset']:get() and player:spellSlot(1).state == 0 then 
                if lastAutoAtacck and lastAutoAtacck == target and lastAAtime and os.clock() - lastAAtime > 0 then  
                    player:castSpell("self", 1)
                    player:attack(target)
                    orb.core.set_server_pause()
                    orb.combat.set_invoke_after_attack(false)
                end 
            elseif not menu.harass['use.w.aa.reset']:get() then 
                player:castSpell("self", 1)
                player:attack(target)
            end 
        end 

        if menu.harass['use.q']:get() and CanCastQ(target) and player.path.serverPos:distSqr(target.path.serverPos) < 450 ^ 2 and common.GetPercentMana(player) > menu.harass['mana.q']:get() then  
            if player:spellSlot(0).state == 0 then 
                player:castSpell("self", 0)
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
            if dmg > orb.farm.predict_hp(minion, 0.36) then
                player:castSpell("self", 1)
                player:attack(minion)
            end
        end 
    end 
end

local Magnet = function()
    if not menu.combo['use.magnet']:get() then 
        return 
    end 

    if not target then 
        return 
    end 

    if player.buff[BUFF_STUN] then 
        return 
    end 
    
    local endPos = (Vector:new(player) - Vector:new(target)):normalized()
    local res = gpred.core.lerp(target.path, 0.25, target.moveSpeed)
    if not res then 
        return
    end 
    local predPos = vec3(res.x + endPos.x * 400, target.y, res.y + endPos.z * 400)
    if predPos and not navmesh.isWall(predPos) then 
        if (not menu.combo['under']:get() or not common.IsUnderDangerousTower(predPos)) then 
            player:move(predPos)
        end
    end 
end 

local KillSteal = function()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do

        if target and target ~= nil and common.IsEnemyMortal(target) and common.IsValidTarget(target) then 
            if player:spellSlot(3).state == 0 and common.GetDistanceSqr(target, player) <= 475 ^ 2 and (dmgLib.GetSpellDamage(3, target)) >= common.GetShieldedHealth("AD", target) then 
                if menu.misc.Killsteal['rKill']:get() then 
                    player:castSpell("obj", 3, target)
                end 
            end 
        end 
    end 
end 

local on_tick = function()
    pMenu.visible_menu()
    KillSteal()
    --dariusnoxiantacticsonh

    if cleaveIsCasted and os.clock() - castedTime > 1 then 
        cleaveIsCasted = false 
    end 

    if lastAAtime and os.clock() - lastAAtime > 0.3 then 
        lastAutoAtacck = nil 
    end 

    if cleaveIsCasted then 
        Magnet()
    end 
    
    if evade then 
        if orb.menu.combat.key:get() and menu.misc['disableEvade']:get() then 
            evade.core.set_pause(math.huge)
        else 
            evade.core.set_pause(0)
        end 
    end 

    target = TS.target 
    --Focus Target 
    if menu.misc['focus']:get() and target then 
        if target.buff['dariushemo'] and target.buff['dariushemo'].stacks > 0 and not menu.misc['focusTotal']:get() then 
            target = TS.target 
            TS:OnTick()
        elseif menu.misc['focusTotal']:get() and target.buff['dariushemo'] and target.buff['dariushemo'].stacks == 5 then 
            target = TS.target 
            TS:OnTick()
        end
    end 
    
    LoadPassiveTarget()
    Passive._time = math.floor((Passive.endTime - game.time) * 100) * 0.01

    --DariusNoxonTactictsONH
    if orb.menu.combat.key:get() then 
        Combo()
    end 

    if orb.menu.hybrid.key:get() then 
        Harass()
    end 

    if (orb.menu.last_hit.key:get() or orb.menu.lane_clear.key:get()) then 
        last_hit()
    end     
end 

local on_process_spell = function(spell)
    if spell and spell.owner.charName == "Darius" and spell.owner.team == player.team then 
        if spell.name == "DariusCleave" then 
            cleaveIsCasted = true
            castedTime = os.clock() 
        end 

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

    if (player:spellSlot(0).state == 0 and menu.draws['qrange']:get()) then 
        graphics.draw_circle(player.pos, 460, WidthCircle, qColor, Points)
    end 

    if (player:spellSlot(1).state == 0 and menu.draws['wrange']:get()) then 
        local widthW = (common.GetAARange()) + 25 
        graphics.draw_circle(player.pos, widthW, WidthCircle, wColor, Points)
    end 

    if (player:spellSlot(2).state == 0 and menu.draws['erange']:get()) then 
        graphics.draw_circle(player.pos, 535, WidthCircle, eColor, Points)
    end 

    if (player:spellSlot(3).state == 0 and menu.draws['rrange']:get()) then 
        graphics.draw_circle(player.pos, 475, WidthCircle, rColor, Points)
    end 

    --Passive time
    if not menu.draws['passive']:get() then 
        return 
    end 

    if target and target ~= nil and common.IsEnemyMortal(target) and common.IsValidTarget(target) then 
        if target.buff['dariushemo'] and game.time > Passive.startTime and game.time < Passive.endTime then
            graphics.draw_text_2D(tostring(Passive._time), 30, graphics.world_to_screen(target.pos).x - (textWidth / 2), graphics.world_to_screen(target.pos).y, 0xFFffffff)
        end 
    end 
end 

return { 
    on_tick = on_tick, 
    on_draw = on_draw,
    on_process_spell = on_process_spell
}