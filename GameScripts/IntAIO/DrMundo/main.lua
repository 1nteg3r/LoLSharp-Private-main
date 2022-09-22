local orb = module.internal("orb")
local evade = module.seek('evade')
local pred = module.internal("pred")

local common = module.load(header.id, "Library/common")
local TS = module.load(header.id, "TargetSelector/targetSelector")
local dlib = module.load(header.id, 'Library/damageLib')

local spellQ = { 
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 2000,
    width = 60,
    range = 990,
    collision = { hero = true, minion = true, wall = true }
}

local menu = menu("IntnnerMundo", "Int - Dr.Mundo")
menu:header("xs", "Core");
TS = TS(menu, 1050)
TS:addToMenu()

menu:menu('combo', "Combat Settings")
    menu.combo:boolean('q', 'Use Q', true)
    --menu.combo:boolean('qpred', '^~ Slow Prediction', true)
    menu.combo:slider("costHealth", "^~ if my % of health is less than {0}", 15, 10, 100, 10)
    menu.combo:boolean('w', 'Use W', true)
    menu.combo:boolean('forceW', '^~ Force Recast?', true)
    menu.combo:boolean('e', 'Use E', true)
        menu.combo:header("izi", 'Advanced features:')
            menu.combo:boolean('r', 'Use R', true)
            menu.combo:slider("minEnemie", "Min. Enemies in Range >=", 2, 1, 5, 1)
            menu.combo:slider("maxHealth", "Max. Health {0}", 35, 10, 100, 10)

menu:menu("harass", "Harass")
menu.harass:boolean('q', 'Use Q', true)
menu.harass:boolean('w', 'Use W', false)
menu.harass:boolean('e', 'Use E', true)
menu.harass:header("izi", 'Advanced features:')
menu.harass:slider("minHealth", "^~ Min. Health {0}", 50, 10, 100, 10)

menu:menu("lane", "LaneClear")
    menu.lane:boolean("useq", "Use Q", true)
    menu.lane:boolean("qlast", "^~ Only Q last-hit", true)
    menu.lane:boolean("usee", "Use E", true)
    menu.lane:header("izi", 'Advanced features:')
    menu.lane:slider("minHealth", "^~ Min. Health {0}", 50, 10, 100, 10)

menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useW', 'Use W Recast for KillSteal', true)
    menu.kill:boolean('useE', 'Use E for KillSteal', true)


menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", true)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)



local q_damage = function(target)
    if not target then 
        return 
    end 

    if player:spellSlot(0).level == 0 then 
        return 0 
    end 

    local damage = 0 
    if player:spellSlot(0).level > 0 then 
        damage = ({0.2, 0.225, 0.25, 0.275, 0.3})[player:spellSlot(0).level] * target.health 
    end 

    if damage <= 0 then 
        return 0 
    end 

    return common.CalculateMagicDamage(target, damage)
end 

local w_recast_damage = function(target)
    if not target then 
        return 
    end 

    if player:spellSlot(1).level == 0 then 
        return 0 
    end 

    local damage = 0 
    if player:spellSlot(1).level > 0 then 
        damage = ({20, 35, 50, 65, 80})[player:spellSlot(1).level] + 0.7 * player.health 
    end 

    if damage <= 0 then 
        return 0 
    end 

    return common.CalculateMagicDamage(target, damage)
end 

local e_damage = function(target)
    if not target then 
        return 
    end 

    if player:spellSlot(2).level == 0 then 
        return 0 
    end 

    local damage = 0 
    if player:spellSlot(2).level > 0 then 
       
        local dgmE = {8, 24, 40, 56, 72}

        damage = dgmE[player:spellSlot(2).level] + 0.112 * player.health 
    end 

    if damage <= 0 then 
        return 0 
    end 

    return common.CalculatePhysicalDamage(target, damage)
end 

local pred_filter = function(input, seg, obj)
    --always cast if the target is 875 or less units away (randomly chosen value)
    local dist = seg.startPos:distSqr(seg.endPos)
    if dist < 990 then
        return true
    end
    --always cast if the target is stunned, knocked up etc
    if pred.trace.linear.hardlock(input, seg, obj) then
        return true
    end
    --always cast if the target is feared, taunted etc
    if pred.trace.linear.hardlockmove(input, seg, obj) then
        return true
    end
    --wait for the target to get on a new path if its more than 875 units away and not stunned
    --arguably higher hitchance. especially arguably for ezreal q because of the long winduptime + travel time
    --very effective on spells like xerath q
    if pred.trace.newpath(obj, 0.033, 0.500) then
      return true
    end

    if dist < 990 and game.mode=='URF' then
        return true
    end
end

local Combo = function()
    local target = TS.target  

    if target and common.IsValidTarget(target) then 

        if menu.combo.q:get() and player:spellSlot(0).state == 0 and common.GetPercentHealth(player) > menu.combo.costHealth:get() then 
            local seg = pred.linear.get_prediction(spellQ, target, vec2(player.x, player.z))

            if not seg then 
                return 
            end 

            if player.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 990 ^ 2 and player.pos2D:dist(target.pos2D) < 990 then
                local col = pred.collision.get_prediction(spellQ, seg, target) 

                if col then 
                    return 
                end 

                if pred_filter(spellQ, seg, target) then 
                    player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                end
            end

        end
        
        if menu.combo.w:get() and player:spellSlot(1).state == 0 then 

            if player:spellSlot(1).name == "DrMundoW" then 

                if target.pos2D:dist(player.pos2D) < 325 then 
                    player:castSpell("self", 1)
                end 
            end 

            if player:spellSlot(1).name == "DrMundoWRecast" then 
                if player.buff['drmundow'] and player.buff['drmundow'].startTime < 0.25 then 
                    player:castSpell("self", 1)
                end 

                if menu.combo.forceW:get() then 
                    if common.GetPercentHealth(player) < common.GetPercentHealth(target) then 
                        player:castSpell("self", 1)
                    end 

                    if #common.CountEnemiesInRange(player.pos, 450) >= 2 then 
                        player:castSpell("self", 1)
                    end 
                end 
            end 
        end

        if menu.combo.e:get() and player:spellSlot(2).state == 0 then 

            if target.pos2D:dist(player.pos2D) <= common.GetAARange(player) and (not orb.core.can_attack() and orb.core.can_action()) then 
                player:castSpell("self", 2)
            end

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
                local current_pos = target.path.serverPos + ((minion_a.path.serverPos - target.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos) + 800))
                local hit_count = 1
                for j = 1, #valid do
                    if j ~= i then
                        local minion_b = valid[j]
                        local point = mathf.closest_vec_line(minion_b.path.serverPos, target.path.serverPos, current_pos)
                        if point and point:dist(minion_b.path.serverPos) < (89 + minion_b.boundingRadius) then
                            hit_count = hit_count + 1
                        end
                    end
                end
                if not cast_pos or hit_count > max_count then
                    cast_pos, max_count = current_pos, hit_count
                end
                if cast_pos and max_count > 0 and minion_a.pos2D:dist(player.pos2D) <= common.GetAARange(player) then
                    if minion_a.health < e_damage(minion_a) then 
                        player:castSpell("self", 2)
                        player:attack(minion_a)
                    end
                end
            end
        end 

        if menu.combo.r:get() and player:spellSlot(3).state == 0 then 
            if common.GetPercentHealth(player) <= menu.combo['maxHealth']:get() and #common.CountEnemiesInRange(player.pos, 900) >= menu.combo.minEnemie:get() then
                player:castSpell("self", 3)
            elseif common.GetPercentHealth(player) <= menu.combo['maxHealth']:get() and #common.CountEnemiesInRange(player.pos, 900) == 1 then
                player:castSpell("self", 3)
            end
        end 
    end 
end 

local function lane_clear()
    if menu.lane.useq:get() then 
        local enemyMinions = common.GetMinionsInRange(1050, TEAM_ENEMY)
        for i, minion in pairs(enemyMinions) do
            if minion and common.IsValidTarget(minion) then

                if minion.pos2D:dist(player.pos2D) <= 1050 then 
                    if menu.lane.qlast:get() then 
                        if (q_damage(minion) > minion.health) then 
                            local seg = pred.linear.get_prediction(spellQ, minion, vec2(player.x, player.z))
                            if seg and player.pos2D:dist(minion.pos2D) < 990 then
                                local col = pred.collision.get_prediction(spellQ, seg, minion) 
                                if not col then 
                                    player:castSpell('pos', 0, vec3(seg.endPos.x, minion.pos.y, seg.endPos.y))
                                end
                            end
                
                        end     
                    end 

                    if not menu.lane.qlast:get() then 
                        local seg = pred.linear.get_prediction(spellQ, minion, vec2(player.x, player.z))
                        if seg and player.pos2D:dist(minion.pos2D) < 990 then
                            local col = pred.collision.get_prediction(spellQ, seg, minion) 
                            if not col then 
                                player:castSpell('pos', 0, vec3(seg.endPos.x, minion.pos.y, seg.endPos.y))
                            end
                        end
                    end 
                end 
            end 
        end 
    end 
    if menu.lane.usee:get() then 
        local enemy = common.GetEnemyHeroes()
        for i, target in ipairs(enemy) do

            if target and target ~= nil and common.IsEnemyMortal(target) and common.IsValidTarget(target) then

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
                    local current_pos = target.pos + (player.pos + target.pos):norm() * 800 
                    local hit_count = 1
                    for j = 1, #valid do
                        if j ~= i then
                            local minion_b = valid[j]
                            local point = mathf.closest_vec_line(minion_b.path.serverPos, target.path.serverPos, current_pos)
                            if point and point:dist(minion_b.path.serverPos) < (minion_b.boundingRadius) then
                                hit_count = hit_count + 1
                            end
                        end
                    end
                    if not cast_pos or hit_count > max_count then
                        cast_pos, max_count = current_pos, hit_count
                    end
                    if cast_pos and max_count > 0 and minion_a.pos2D:dist(player.pos2D) <= common.GetAARange(player) then
                        if minion_a.health < e_damage(minion_a) then 
                            player:castSpell("self", 2)
                            player:attack(minion_a)
                        end
                    end
                end
            end 
        end 
    end
end 

local Harass = function()
    if common.GetPercentHealth(player) < menu.harass.minHealth:get() then 
        return 
    end 

    local target = TS.target  

    if target and common.IsValidTarget(target) then 

        if menu.harass.q:get() and player:spellSlot(0).state == 0 and common.GetPercentHealth(player) > menu.combo.costHealth:get() then 
            local seg = pred.linear.get_prediction(spellQ, target, vec2(player.x, player.z))

            if not seg then 
                return 
            end 

            if player.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 990 ^ 2 and player.pos2D:dist(target.pos2D) < 990 then
                local col = pred.collision.get_prediction(spellQ, seg, target) 

                if col then 
                    return 
                end 

                if pred_filter(spellQ, seg, target) then 
                    player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                end
            end

        end
        
        if menu.harass.w:get() and player:spellSlot(1).state == 0 then 

            if player:spellSlot(1).name == "DrMundoW" then 

                if target.pos2D:dist(player.pos2D) < 325 then 
                    player:castSpell("self", 1)
                end 
            end 

            if player:spellSlot(1).name == "DrMundoWRecast" then 
                if player.buff['drmundow'] and player.buff['drmundow'].startTime < 0.25 then 
                    player:castSpell("self", 1)
                end 

                if menu.combo.forceW:get() then 
                    if common.GetPercentHealth(player) < common.GetPercentHealth(target) then 
                        player:castSpell("self", 1)
                    end 

                    if #common.CountEnemiesInRange(player.pos, 450) >= 2 then 
                        player:castSpell("self", 1)
                    end 
                end 
            end 
        end

        if menu.harass.e:get() and player:spellSlot(2).state == 0 then 

            if target.pos2D:dist(player.pos2D) <= common.GetAARange(player) and (not orb.core.can_attack() and orb.core.can_action()) then 
                player:castSpell("self", 2)
            end

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
                local current_pos = target.pos + (player.pos + target.pos):norm() * 800 
                local hit_count = 1
                for j = 1, #valid do
                    if j ~= i then
                        local minion_b = valid[j]
                        local point = mathf.closest_vec_line(minion_b.path.serverPos, target.path.serverPos, current_pos)
                        if point and point:dist(minion_b.path.serverPos) < (minion_b.boundingRadius) then
                            hit_count = hit_count + 1
                        end
                    end
                end
                if not cast_pos or hit_count > max_count then
                    cast_pos, max_count = current_pos, hit_count
                end
                if cast_pos and max_count > 0 and minion_a.pos2D:dist(player.pos2D) <= common.GetAARange(player) then
                    if minion_a.health < e_damage(minion_a) then 
                        player:castSpell("self", 2)
                        player:attack(minion_a)
                    end
                end
            end

        end 
    end 
end 

local KillSteal = function()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do

        if target and target ~= nil and common.IsEnemyMortal(target) and common.IsValidTarget(target) then 
            if menu.kill.useQ:get() and common.GetShieldedHealth("AP", target) < q_damage(target) then 
                local seg = pred.linear.get_prediction(spellQ, target, vec2(player.x, player.z))

                if not seg then 
                    return 
                end 
    
                if player.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 990 ^ 2 and player.pos2D:dist(target.pos2D) < 990 then
                    local col = pred.collision.get_prediction(spellQ, seg, target) 
    
                    if col then 
                        return 
                    end 
    
                    if pred_filter(spellQ, seg, target) then 
                        player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                    end
                end
            end 
        end 
    end 
end 

local on_tick = function()
    if player.isDead then 
        return 
    end 

    KillSteal()
    if orb.menu.combat.key:get() then 
        Combo()
    end

    if orb.menu.lane_clear.key:get() then 
        lane_clear()
    end

    if orb.menu.hybrid.key:get() then 
        Harass()
    end
    --[[local enemyMinions = common.GetMinionsInRange(1800, TEAM_ENEMY)
    for i, minion in pairs(enemyMinions) do
        if minion and common.IsValidTarget(minion) then
            if minion.pos:dist(player.pos) <= common.GetAARange(player) then 
                if e_damage(minion) > minion.health and player:spellSlot(2).state == 0 and player:spellSlot(2).name == "DrMundoE" then 
                    player:castSpell("self", 2)
                    player:attack(minion)
                end 
            end 
        end 
    end]]
end 

local on_draw = function()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 1050, 1, menu.draws.qcolor:get(), 100)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 325, 1, menu.draws.wcolor:get(), 100)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 800, 1, menu.draws.ecolor:get(), 100)
        end
    end 
end 

orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.draw, on_draw)