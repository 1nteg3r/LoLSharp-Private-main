local Ashe = { }

Ashe.orb = module.internal("orb");
Ashe.evade = module.seek("evade");
Ashe.TS = module.internal("TS");
Ashe.zPred = module.internal("pred");
Ashe.Menu = module.load(header.id, "Addons/Ashe/menu");
Ashe.Common = module.load(header.id, "common");
Ashe.damage = module.load(header.id, 'damageLib');

Ashe.IsPreAttack = false; 
Ashe.Mana = 0;



Ashe.W = {
    width = 20,
    delay = 0.25,
    speed = 1500,
    range = 1200,
    boundingRadiusMod = 1,
    angle = (math.pi/180*40),
    collision = { 
        hero = true, 
        minion = true, 
        walls = true 
    };

    trace_filter = function(seg, obj)
        if seg.startPos:distSqr(seg.endPos) > 1380625 then
            return false
        end
        if seg.startPos:distSqr(obj.path.serverPos2D) > 1380625 then
            return false
        end
        if Ashe.zPred.trace.linear.hardlock(Ashe.W, seg, obj) then
        if 1250 <= Ashe.Common.GetAARange(obj) then
            return false
        end
        return true
        end
        if Ashe.zPred.trace.linear.hardlockmove(Ashe.W, seg, obj) then
            return true
        end
        if Ashe.zPred.trace.newpath(obj, 0.033, 0.500) then
            return true
        end
    end
}

Ashe.R = {
    width = 130,
    delay = 0.25,
    speed = math.huge,
    range = Ashe.Menu.combo.rsettings.Rrange:get(),
    boundingRadiusMod = 1,
    collision = { 
        hero = true, 
        minion = false, 
        walls = false 
    };
    trace_filter = function(seg, obj)
        if seg.startPos:distSqr(seg.endPos) > 1380625 then
            return false
        end
        if seg.startPos:distSqr(obj.path.serverPos2D) > 1380625 then
            return false
        end
        if Ashe.zPred.trace.linear.hardlock(Ashe.R, seg, obj) then
        if 1200 <= Ashe.Common.GetAARange(obj) then
            return false
        end
        return true
        end
        if Ashe.zPred.trace.linear.hardlockmove(Ashe.R, seg, obj) then
            return true
        end
        if Ashe.zPred.trace.newpath(obj, 0.033, 0.500) then
            return true
        end
    end
}

Ashe._OnVision = {}
Ashe.OnVision = function(unit)
	if Ashe._OnVision[unit.networkID] == nil then Ashe._OnVision[unit.networkID] = {state = unit.isVisible , tick = os.clock(), pos = unit.pos} end
	if Ashe._OnVision[unit.networkID].state == true and not unit.isVisible then Ashe._OnVision[unit.networkID].state = false Ashe._OnVision[unit.networkID].tick = os.clock() end
	if Ashe._OnVision[unit.networkID].state == false and unit.isVisible then Ashe._OnVision[unit.networkID].state = true Ashe._OnVision[unit.networkID].tick = os.clock() end
	return Ashe._OnVision[unit.networkID]
end

Ashe.OnDrawing = function()
    if player.isDead and player.buff[17] and not player.isOnScreen then 
        return 
    end 

    if Ashe.Menu.draws['q3_range']:get() and player:spellSlot(1).state == 0 then 
        graphics.draw_circle(player.pos, 1200, 1, Ashe.Menu.draws['q3']:get(), 100)
    end 
end 

Ashe.OnDrawOverlay = function()
    if player.isDead then return end 
    minimap.draw_circle(player.pos, Ashe.Menu.combo.rsettings.Rrange:get(), 1, 0x7fffffff)
end 

Ashe.OnPreAttack = function()
    Ashe.IsPreAttack = true; 
end 

Ashe.Flee = function()
    player:move(mousePos)
end

Ashe.Combo = function()
    if Ashe.Menu.combo.qsettings.qcombo:get() and player:spellSlot(0).state == 0 then
        if Ashe.Common.GetPercentMana(player) >= Ashe.Menu.combo.qsettings.mana_mngr:get() then 
            local Range = Ashe.Common.GetAARange();
            local target = Ashe.TS.get_result(function(res, obj, dist)
                local aa_damage = Ashe.Common.CalculateAADamage(obj)
                if (dist > Range or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                    return
                end
                if (aa_damage * 2) > Ashe.Common.GetShieldedHealth("AD", obj) then
                    return
                end
                if obj and Ashe.Common.IsValidTarget(obj) and Ashe.Common.IsInRange(Range, player, obj) then
                    res.obj = obj
                    return true
                end
            end).obj
            if target then 
                if not Ashe.IsPreAttack then 
                    player:castSpell("self", 0)
                end 
            end
        end 
    end
    --W 
    if Ashe.Menu.combo.wsettings.wcombo:get() and player:spellSlot(1).state == 0 then
        if Ashe.Common.GetPercentMana(player) >= Ashe.Menu.combo.wsettings.mana_mngr:get() and (player.mana - 50 > Ashe.Mana) then 
            local target = Ashe.TS.get_result(function(res, obj, dist)
                local aa_damage = Ashe.Common.CalculateAADamage(obj)
                if (dist > 1200 or obj.buff["rocketgrab"]  or obj.buff["sivire"]  or obj.buff["fioraw"]) then
                    return
                end
                if (aa_damage * 2) > Ashe.Common.GetShieldedHealth("AD", obj) then
                    return
                end
                if obj and Ashe.Common.IsValidTarget(obj) then
                    res.obj = obj
                    return true
                end
            end).obj
            if target then 
                local seg = Ashe.zPred.linear.get_prediction(Ashe.W, target)
                if seg and seg.startPos:dist(seg.endPos) <= 1250 then
                    if not Ashe.zPred.collision.get_prediction(Ashe.W, seg, target) then
                        if not Ashe.IsPreAttack and Ashe.W.trace_filter(seg, target) then
                            player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    end
                end
            end
        end 
    end 
    -- E 
    if Ashe.Menu.combo.esettings.ecombo:get() and player:spellSlot(2).state == 0 then
        for i=0, objManager.enemies_n-1 do
            local unit = objManager.enemies[i]
            if unit and not unit.isDead then 
                Ashe.OnVision(unit)
            end 

            if unit and not unit.isDead and Ashe.OnVision(unit).state == false then 
                if player.pos:dist(unit.pos) <= 1000 then
                    player:castSpell("pos", 2, Ashe.OnVision(unit).pos)
                end
            end
        end
    end
    --R 
    if Ashe.Menu.combo.rsettings.rcombo:get() and player:spellSlot(3).state == 0 then
        local Damage = 0;
        local target = Ashe.TS.get_result(function(res, obj, dist)
            local aa_damage = Ashe.Common.CalculateAADamage(obj)
            if (dist > Ashe.Menu.combo.rsettings.Rrange:get() or obj.buff["rocketgrab"]  or obj.buff["sivire"]  or obj.buff["fioraw"] ) then
                return
            end
            if (aa_damage * 2) > Ashe.Common.GetShieldedHealth("AD", obj) then
                return
            end
            if obj and Ashe.Common.IsValidTarget(obj) and Ashe.Common.IsInRange(Ashe.Menu.combo.rsettings.Rrange:get(), player, obj) then
                res.obj = obj
                return true
            end
        end).obj
        if target and Ashe.Menu.combo.rsettings.blacklist[target.charName] and not Ashe.Menu.combo.rsettings.blacklist[target.charName]:get() then 
            if ((player.mana > 200) and Ashe.Common.IsInRange(1250, player, target)) then 
                Damage = (Ashe.damage.GetSpellDamage(1, target) + Ashe.damage.GetSpellDamage(3, target)) * 1.5
            elseif((player.mana > 150) and Ashe.Common.IsInRange(1250, player, target)) then 
                Damage = Ashe.damage.GetSpellDamage(3, target) * 1.5
            end
            local seg = Ashe.zPred.linear.get_prediction(Ashe.R, target)
            if seg and seg.startPos:dist(seg.endPos) <= 1250 then
                local col = Ashe.zPred.collision.get_prediction(Ashe.R, seg, target)
                if not col then
                    if target.health < Damage or Ashe.Common.GetPercentHealth(player) < Ashe.Menu.combo.rsettings.delayed:get()  and Ashe.R.trace_filter(seg, target) then     
                        player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                end 
            end
        end 
    end
end

Ashe.Harass = function()
    if player:spellSlot(1).state ~= 0 and not Ashe.Menu.harass.wsettings.eharras:get() and not Ashe.Common.GetPercentMana(player) > Ashe.Menu.harass.wsettings.mana_mngr:get() then return end 

    if Ashe.Common.GetPercentMana(player) >= Ashe.Menu.combo.wsettings.mana_mngr:get() and (player.mana - 50 > Ashe.Mana) then 
        local target = Ashe.TS.get_result(function(res, obj, dist)
            local aa_damage = Ashe.Common.CalculateAADamage(obj)
            if (dist > 1200 or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and Ashe.Common.IsValidTarget(obj) then
                res.obj = obj
                return true
            end
        end).obj
        if target then 
            local seg = Ashe.zPred.linear.get_prediction(Ashe.W, target)
            if seg and seg.startPos:dist(seg.endPos) <= 1250 then
                local col = Ashe.zPred.collision.get_prediction(Ashe.W, seg, target)
                if not col then
                    if not Ashe.IsPreAttack and Ashe.W.trace_filter(seg, target) then
                        player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end
            end
        end
    end 
end 

Ashe.Clear = function()
    for minion in objManager.iminions do
        if minion and Ashe.Common.IsValidTarget(minion) then 
            if minion.isEnemy then 
                if Ashe.Common.GetPercentMana(player) > Ashe.Menu.lane.mana_mngr:get() then 
                    if minion.pos:distSqr(player.pos) <= Ashe.Common.GetAARange() * Ashe.Common.GetAARange() then 
                        player:castSpell("self", 0)
                    end
                end
            end 
        end 
    end
end 

Ashe.KillSteal = function()
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy and Ashe.Common.IsValidTarget(enemy) then 
            if Ashe.Menu.kill.wKill:get() and Ashe.damage.GetSpellDamage(1, enemy) > Ashe.Common.GetShieldedHealth("AD", enemy) then
                local seg = Ashe.zPred.linear.get_prediction(Ashe.W, enemy)
                if seg and seg.startPos:dist(seg.endPos) <= 1250 then
                    local col = Ashe.zPred.collision.get_prediction(Ashe.W, seg, enemy)
                    if not col then
                        if not Ashe.IsPreAttack and Ashe.W.trace_filter(seg, enemy) then
                            player:castSpell("pos", 1, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
                        end
                    end
                end
            end
            if Ashe.Menu.kill.rKill:get() and Ashe.damage.GetSpellDamage(1, enemy)> Ashe.Common.GetShieldedHealth("AP", enemy) then
                local seg = Ashe.zPred.linear.get_prediction(Ashe.R, enemy)
                if seg and seg.startPos:dist(seg.endPos) <= 1250 then
                    local col = Ashe.zPred.collision.get_prediction(Ashe.R, seg, enemy)
                    if not col then
                        if Ashe.R.trace_filter(seg, enemy) then     
                            player:castSpell("pos", 3, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
                        end 
                    end 
                end
            end
        end 
    end
end

Ashe.OnProcessSpell = function(spell)
	if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
		local enemyName = string.lower(spell.owner.charName)
		if Ashe.Common.interruptableSpells[enemyName] then
			for i = 1, #Ashe.Common.interruptableSpells[enemyName] do
				local spellCheck = Ashe.Common.interruptableSpells[enemyName][i]
				if Ashe.Menu.fill[spell.owner.charName .. spellCheck.menuslot]:get() and string.lower(spell.name) == spellCheck.spellname then
                    if player:spellSlot(3).state == 0 then
                        if Ashe.Common.GetDistance(player, spell.owner) < 900 and Ashe.Common.IsValidTarget(spell.owner) then
                            local seg = Ashe.zPred.linear.get_prediction(Ashe.R, spell.owner)
                            if seg and seg.startPos:dist(seg.endPos) <= 1250 then
                                local col = Ashe.zPred.collision.get_prediction(Ashe.R, seg, spell.owner)
                                if not col then
                                    if Ashe.R.trace_filter(seg, spell.owner) then     
                                        player:castSpell("pos", 3, vec3(seg.endPos.x, spell.owner.y, seg.endPos.y))
                                    end 
                                end 
                            end
                        end
                    end
				end
			end
		end
	end
end 

Ashe.SemiR = function()
    if player:spellSlot(3).state == 0 then
        local target = Ashe.TS.get_result(function(res, obj, dist)
            if (dist > Ashe.Menu.combo.rsettings.Rrange:get() or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and Ashe.Common.IsValidTarget(obj) and Ashe.Common.IsInRange(Ashe.Menu.combo.rsettings.Rrange:get(), player, obj) and Ashe.Menu.combo.rsettings.blacklist[obj.charName] and not Ashe.Menu.combo.rsettings.blacklist[obj.charName]:get() then 
                res.obj = obj
                return true
            end
        end).obj
        if target then 
            local seg = Ashe.zPred.linear.get_prediction(Ashe.R, target)
            if seg and seg.startPos:dist(seg.endPos) <= 1250 then
                local col = Ashe.zPred.collision.get_prediction(Ashe.R, seg, target)
                if not col then
                    if Ashe.R.trace_filter(seg, target) then     
                        player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                end 
            end
        end 
    end
end


Ashe.OnTick = function()
    Ashe.IsPreAttack = false; 
    
    if player:spellSlot(3).state == 0 then 
        Ashe.Mana = 140 
    else 
        Ashe.Mana = 40
    end
    if Ashe.Menu.keyjump:get() then 
        Ashe.Flee();
    elseif Ashe.orb.menu.combat.key:get() then
        Ashe.Combo();
    elseif Ashe.orb.menu.hybrid.key:get() then
        Ashe.Harass();
    elseif Ashe.Menu.semir:get() then 
        Ashe.SemiR();
    end 

    Ashe.KillSteal();
end

cb.add(cb.draw, Ashe.OnDrawing)
--
Ashe.orb.combat.register_f_pre_tick(Ashe.OnPreAttack)
cb.add(cb.tick, Ashe.OnTick)
--
cb.add(cb.spell, Ashe.OnProcessSpell)

return Ashe 