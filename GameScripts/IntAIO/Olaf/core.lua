local pMenu = module.load(header.id, "Core/Olaf/menu")
local common = module.load(header.id, "Library/common")
local dmgLib = module.load(header.id, "Library/damageLib")
local GeoLib = module.load(header.id, "Geometry/GeometryLib")
local Prediction = module.load(header.id, "iPrediction/main")

local orb = module.internal("orb")
local evade = module.seek('evade')

local menu = pMenu.menu 
local TS = pMenu.TS 
local Vector = GeoLib.Vector

local Axes = { }

local spell_Q = {
    delay = 0.25, 
    width = 90, 
    range = 1000,
    speed = 1600, 
    boundingRadiusMod = 1, 
    collision = {hero = false, minion = false, wall = true}
}

local lastAutoAtacck = nil 
local lastAAtime = game.time 

local MonsterPriorize = {
    ["SRU_Murkwolf"] = true, 
    ["SRU_Gromp"] = true, 
    ["SRU_Red"] = true, 
    ["SRU_Blue"] = true, 
    ["SRU_Razorbeak"] = true, 
    ['SRU_Krug'] = true
}

local Window = {x = graphics.res.x * 0.5, y = graphics.res.y * 0.5}
local pos = {x = Window.x, y = Window.y}

local Magnet_to_axes = function()
    if ((menu.misc['catch']:get() == 1 and orb.menu.combat.key:get()) or (menu.misc['catch']:get() == 2)) then 
        if target and common.IsValidTarget(target) and target.team ~= player.team and common.IsEnemyMortal(target) then  
            for i, object in pairs(Axes) do 
                if object.obj and common.GetDistance(target, player) < 500 then 
                    if target.pos:dist(object.obj.pos) < 400 and player.pos:dist(object.obj.pos) < 500 then 
                        if not common.IsUnderDangerousTower(object.obj.pos) then 
                            if player.pos:dist(object.obj.pos) > 200 then 
                                player:move(object.obj.pos)
                                orb.core.set_pause_move(math.huge)
                                orb.core.set_server_pause()
                            end 
                        else 
                            orb.core.set_pause_move(0)
                        end 
                    else 
                        orb.core.set_pause_move(0)
                    end 
                else 
                    orb.core.set_pause_move(0)
                end 
            end 
        else 
            orb.core.set_pause_move(0)
        end 
    end 
end 

local Combo = function()
    if target and target ~= nil and common.isValidTarget(target) then 
        if menu.combo['use.r']:get() and player:spellSlot(3).state == 0 then 
            if menu.combo['use.force']:get() then 
                if player.buff[BUFF_KNOCKBACK] or player.buff[BUFF_BLIND] or player.buff[BUFF_CHARM] or player.buff[BUFF_SILENCE] or 
                player.buff[BUFF_SUPPRESSION] or player.buff[BUFF_ASLEEP] or player.buff[BUFF_POLYMORPH] or player.buff[BUFF_DISARM] or 
                player.buff[BUFF_STUN] or player.buff[BUFF_TAUNT] or player.buff[BUFF_KNOCKUP] then 
                    player:castSpell("self", 3)
                end 
            end 

            if #common.GetEnemyHeroesInRange(menu.combo['minRange']:get(), player.pos) >= menu.combo['aroundEnemies']:get() then 
                player:castSpell("self", 3)
            end 
        end 

        if menu.combo['use.q']:get() and player:spellSlot(0).state == 0 then 
            local result, castPos, hitChance = Prediction.getPrediction(target, player, spell_Q, "linear", true)
            if result and castPos and player.pos:distSqr(castPos) < menu.combo['min.range']:get() ^ 2 then 

                local predResult = vec3(result.endPos.x, mousePos.y, result.endPos.y)
                local Position = Vector(predResult):extended(Vector(player.pos), -target.boundingRadius):toDX3()

                if common.GetDistance(target, player) > 310 then 
                    player:castSpell("pos", 0, Position)
                else  
                    if hitChance >= menu.combo['hitChance']:get() then 
                        player:castSpell("pos", 0, castPos)
                    end     
                end 
            end 
        end 

        if menu.combo['use.w']:get() and player:spellSlot(1).state == 0 then 
            if target.pos:dist(player.pos) <= (player.attackRange + player.boundingRadius) then 
                player:castSpell("self", 1)
            end 
        end 

        if menu.combo['use.e']:get() and not menu.combo['use.e.affter.Attack']:get() then 
            if not orb.core.can_attack() and player.pos:dist(target.pos) <= 325 then
                if player:spellSlot(2).state == 0 then 
                    player:castSpell("obj", 2, target)
                end 
            end 
        end 

        if common.GetDistance(target, player) < menu.misc['distance.magnet']:get() and menu.misc.magnetTarget:get() and orb.combat.can_action() and (not orb.combat.can_attack() or common.GetDistance(target, player) > common.GetAARange(player)) then
			orb.core.set_pause_move(math.huge)
			local pos = target.pos
			if target.path.isActive then
				pos = target.pos:lerp(target.path.point[0], -75 / target.pos:dist(target.path.point[0]))
			end
			player:move(pos)
		else
			orb.core.set_pause_move(0)
		end
    end 
end 

local Harass = function()
    if target and target ~= nil and common.IsValidTarget(target) then 
        if menu.harass['use.e']:get() and player:spellSlot(2).state == 0 then  
            if not orb.core.can_attack() and player.pos:dist(target.pos) <= 325 then
                if player:spellSlot(2).state == 0 and common.GetPercentHealth(player) >= menu.harass['min.health']:get() then 
                    player:castSpell("obj", 2, target)
                end 
            end 
        end 
        if menu.harass['use.w']:get() and player:spellSlot(1).state == 0 then 
            if target.pos:dist(player.pos) <= (player.attackRange + player.boundingRadius) and common.GetPercentMana(player) >= menu.harass['min.ManaforW']:get() then 
                player:castSpell("self", 1)
            end 
        end 
        if menu.harass['use.q']:get() and player:spellSlot(0).state == 0 and common.GetPercentMana(player) >= menu.harass['min.ManaforQ']:get() then  
            local result, castPos, hitChance = Prediction.getPrediction(target, player, spell_Q, "linear", true)
            if result and castPos and player.pos:distSqr(castPos) < 1000 ^ 2 then 

                local predResult = vec3(result.endPos.x, mousePos.y, result.endPos.y)
                local Position = Vector(predResult):extended(Vector(player.pos), -target.boundingRadius):toDX3()

                if common.GetDistance(target, player) > 310 then 
                    player:castSpell("pos", 0, Position)
                else  
                    if hitChance >= menu.harass['hitChance']:get() then 
                        player:castSpell("pos", 0, castPos)
                    end     
                end 
            end 
        end 
        if common.GetDistance(target, player) < menu.misc['distance.magnet']:get() and menu.misc.magnetTarget:get() and orb.combat.can_action() and (not orb.combat.can_attack() or common.GetDistance(target, player) > common.GetAARange(player)) then
			orb.core.set_pause_move(math.huge)
			local pos = target.pos
			if target.path.isActive then
				pos = target.pos:lerp(target.path.point[0], -75 / target.pos:dist(target.path.point[0]))
			end
			player:move(pos)
		else
			orb.core.set_pause_move(0)
		end
    end 
end

local AutoQ = function()
    if menu.harass['min.Mana']:get() > common.GetPercentMana(player) then
        return 
    end

    if target and target ~= nil and common.IsValidTarget(target) then 
        local result, castPos, hitChance = Prediction.getPrediction(target, player, spell_Q, "linear", true)
        if result and castPos and player.pos:distSqr(castPos) < menu.combo['min.range']:get() ^ 2 then 

            local predResult = vec3(result.endPos.x, mousePos.y, result.endPos.y)
            local Position = Vector(predResult):extended(Vector(player.pos), -target.boundingRadius):toDX3()

            if common.GetDistance(target, player) > 310 then 
                if player:spellSlot(0).state == 0 then 
                    player:castSpell("pos", 0, Position)
                end
            else  
                if hitChance >= menu.combo['hitChance']:get() then 
                    if player:spellSlot(0).state == 0 then 
                        player:castSpell("pos", 0, castPos)
                    end
                end     
            end 
        end 
    end 
end

local WaveClear = function()
    local target = { obj = nil, health = 0, mode = "jungleclear" }
	local aaRange = player.attackRange + player.boundingRadius + 200
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

    if target.obj and target.obj ~= nil and common.isValidTarget(target.obj) then 
        if target.mode == "jungleclear" then
            if menu.wave['use.q']:get() and common.GetPercentMana(player) > menu.wave['mana.q']:get() then 
                local Position = Vector(target.obj):extended(Vector(player.pos), -target.obj.boundingRadius):toDX3()

                if common.GetDistance(target.obj, player) > 310 then 
                    if player:spellSlot(0).state == 0 then 
                        player:castSpell("pos", 0, Position)
                    end
                else  
                    if player:spellSlot(0).state == 0 then 
                        player:castSpell("pos", 0, target.obj.pos)
                    end
                end  
            end
            if menu.wave['use.e']:get() and player:spellSlot(2).state == 0 then  
                if not orb.core.can_attack() and player.pos:dist(target.obj.pos) <= 325 then
                    if player:spellSlot(2).state == 0 and common.GetPercentHealth(player) >= menu.wave['min.health']:get() then 
                        player:castSpell("obj", 2, target.obj)
                    end 
                end 
            end 
            if menu.wave['use.w']:get() and player:spellSlot(1).state == 0 then 
                if target.obj.pos:dist(player.pos) <= (player.attackRange + player.boundingRadius) and common.GetPercentMana(player) >= menu.wave['mana.w']:get() then 
                    player:castSpell("self", 1)
                end 
            end  
        elseif target.mode == "laneclear" then 
            if target.obj and target.obj.isVisible and target.obj.moveSpeed > 0 and target.obj.isTargetable and not target.obj.isDead and target.obj.maxHealth > 5 and (not lastAutoAtacck or lastAutoAtacck ~= target.obj) and
            common.GetDistanceSqr(target.obj) <= (325) ^ 2 and (not orb.core.can_attack() or (common.GetAARange(player) <= common.GetDistance(target.obj))) then 
                local dmg = dmgLib.GetSpellDamage(2, target.obj)
                if dmg > orb.farm.predict_hp(target.obj, 0.25) then
                    player:castSpell("obj", 2, target.obj)
                    player:attack(target.obj)
                end
            end 
        end 
    end 
end 

local KillSteal = function()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and target ~= nil and common.IsEnemyMortal(target) and common.IsValidTarget(target) then 

            if menu.misc.Killsteal['qKill']:get() and player:spellSlot(0).state == 0 and dmgLib.GetSpellDamage(0, target) > common.GetShieldedHealth("AD", target) then 
                local result, castPos, hitChance = Prediction.getPrediction(target, player, spell_Q, "linear", true)
                if result and castPos and player.pos:distSqr(castPos) < 925 ^ 2 then 

                    local predResult = vec3(result.endPos.x, mousePos.y, result.endPos.y)
                    local Position = Vector(predResult):extended(Vector(player.pos), -target.boundingRadius):toDX3()

                    if common.GetDistance(target, player) > 310 then 
                        if player:spellSlot(0).state == 0 then 
                            player:castSpell("pos", 0, Position)
                        end
                    else  
                        if hitChance >= menu.combo['hitChance']:get() then 
                            if player:spellSlot(0).state == 0 then 
                                player:castSpell("pos", 0, castPos)
                            end
                        end     
                    end 
                end 
            end 

            if menu.misc.Killsteal['wKill']:get() and player:spellSlot(2).state == 0 then
                if common.GetDistance(target, player) <= 325 and dmgLib.GetSpellDamage(2, target) > common.GetShieldedHealth("AD", target) then  
                    player:castSpell("obj", 2, target)
                end 
            end 
        end 
    end 
end

local on_tick = function()
    --Combo: R - Q - W - AA - E - AA 
    target = TS.target 
    if menu.misc['focusTarget']:get() and target and target.pos:dist(player.pos) <= common.GetAARange(player) then
        TS.range = common.GetAARange(player)
        TS:OnTick()
    else 
        TS.range = 1000 
        TS:OnTick()
    end 

    pMenu.valid_menu()
    Magnet_to_axes()
    KillSteal()

    if lastAAtime and game.time - lastAAtime > 0.1 then 
        lastAutoAtacck = nil 
    end 

    if menu.harass.toggleAutoQ:get() and not orb.menu.combat.key:get() then
        AutoQ()
    end 

    if evade and (not menu.misc['onlyR']:get() or player.buff['olafragnarok']) then 
        if orb.menu.combat.key:get() and menu.misc['disableEvade']:get() then 
            evade.core.set_pause(math.huge)
        else 
            evade.core.set_pause(0)
        end 
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

local on_process_spell = function(spell)
    if spell and spell.owner.charName == "Olaf" then 
        if spell.isBasicAttack then 
            lastAutoAtacck = spell.target
            lastAAtime = game.time + spell.windUpTime
        end 
    end 
end 

local AfterAttack = function()
    if target and common.isValidTarget(target) and orb.menu.combat.key:get() and not orb.core.can_attack() and player.pos:dist(target.pos) <= 325 then
        local item = nil
		for i = 6, 11 do
			if player:spellSlot(i).name == "6029Active" or player:spellSlot(i).name == "6630Active" then
				item = i
				break
			end
		end
        if menu.misc['Item']:get() and item and player:spellSlot(item).state == 0 then
			player:castSpell("self", item)
        elseif menu.combo['use.e']:get() and menu.combo['use.e.affter.Attack']:get() and player:spellSlot(2).state == 0 then
			player:castSpell("obj", 2, target)
		end
		orb.combat.set_invoke_after_attack(false) 
    end 
end 

local on_create_particle = function(obj)
    if not obj then 
        return 
    end 

    --Q_Axe_Ally
    --Olaf_Base_Q_Axe_Smoke
    if obj and obj.name then 
        if obj.name:find("Q_Axe_Ally") then 
            Axes[obj.ptr] = {
                obj = obj,
                endT = game.time + 8,
                NetworkID = obj.networkID, 
            }
        end 
    end 
end 

local on_delete_particle = function(obj)
    if not obj then 
        return 
    end 

    for i, object in pairs(Axes) do 
        if object.obj and object.obj == obj then 
            Axes[obj.ptr] = nil 
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
    local eColor = menu.draws['ecolor']:get()
    --Orther 
    local Points = menu.draws['points_n']:get()
    local WidthCircle = menu.draws['widthLine']:get()

    if (player:spellSlot(0).state == 0 and menu.draws['qrange']:get()) then 
        graphics.draw_circle(player.pos, menu.combo['min.range']:get(), WidthCircle, qColor, Points)
    end 

    if (player:spellSlot(2).state == 0 and menu.draws['erange']:get()) then 
        graphics.draw_circle(player.pos, 375, WidthCircle, eColor, Points)
    end 

    for i, object in pairs(Axes) do 
        if object.obj then 
            if menu.draws['daggerCircle']:get() then 
                graphics.draw_circle(object.obj.pos, 200, WidthCircle, graphics.argb(255, 94, 235, 52), Points)
            end
            if menu.draws['daggerTime']:get() then 
                local pos = graphics.world_to_screen(vec3(object.obj.pos.x, object.obj.pos.y, object.obj.pos.z))
                graphics.draw_text_2D("Timer: "..math.ceil(object.endT - game.time), menu.draws['widthDagger']:get(), pos.x - 25, pos.y, 0xFFFFFFFF)
            end 
        end 
    end 

    if menu.draws['drawtoggles']:get() then 

        if menu.harass.toggleAutoQ:get() then
            graphics.draw_text_2D("["..menu.harass.toggleAutoQ.toggle.."] Auto: ", 18, pos.x + 307, pos.y + 438, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("On", 18, pos.x + 400, pos.y + 438, graphics.argb(255, 7, 219, 63))
        else
            graphics.draw_text_2D("["..menu.harass.toggleAutoQ.toggle.."] Auto: ", 18, pos.x + 307, pos.y + 438, graphics.argb(255, 255, 255, 255))
            graphics.draw_text_2D("Off", 18, pos.x + 400, pos.y + 438, graphics.argb(255, 219, 7, 7))
        end

        graphics.draw_line_2D(pos.x + 300, pos.y+435, pos.x + 535, pos.y+435, 35, 0xff1f1f1f)
        graphics.draw_line_2D(pos.x + 535, pos.y + 415, pos.x + 300, pos.y + 415, 3, 0xFFFFFFFF)
    end 
end 

return {
    on_tick = on_tick, 
    on_draw = on_draw,
    on_create_particle = on_create_particle,
    on_delete_particle = on_delete_particle, 
    AfterAttack = AfterAttack, 
    on_process_spell = on_process_spell
}