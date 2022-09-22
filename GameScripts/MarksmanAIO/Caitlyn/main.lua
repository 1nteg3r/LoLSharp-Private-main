local menu = module.load(header.id, 'Addons/Caitlyn/menu')
local orb = module.internal("orb");
local evade = module.seek("evade");
local TS = module.internal("TS");
local zPred = module.internal("pred");
local common = module.load(header.id, "common");
local damage = module.load(header.id, 'damageLib');
local kalman = module.load(header.id, 'kalman_load');

local W_Trap_troy = { }
local _lastWCastTime = 0;
local IsPreAttack = false; 

local pred_e = {
    width = 80,
    delay = 0.150,
    speed = 1600,
    range = 800,
    boundingRadiusMod = 1,
    collision = { 
        hero = true, 
        minion = true, 
        walls = true 
    };
}

local pred_q = { 
    width = 90,
    delay = 0.62,
    speed = 2200,
    range = 1250,
    boundingRadiusMod = 1,
    collision = { 
        hero = true, 
        minion = true, 
        walls = true 
    };
}

local pred_w = {
    radius = 50,
    delay = 0.75,
    speed = 1600,
    range = 800,
    boundingRadiusMod = 0
}

local pred_r = {
    width = 150,
    delay = 0.325,
    speed = 3200,
    range = 3500,
    boundingRadiusMod = 0,
    collision = { 
        hero = true, 
        minion = false, 
        walls = true 
    };
}


local  trace_filter = function(seg, obj)
    if seg.startPos:distSqr(seg.endPos) > 1380625 then
        return false
    end
    if seg.startPos:distSqr(obj.path.serverPos2D) > 1380625 then
        return false
    end
    if zPred.trace.linear.hardlock(pred_q, seg, obj) then
        return true
    end
    if zPred.trace.linear.hardlockmove(pred_q, seg, obj) then
        return true
    end
    if zPred.trace.newpath(obj, 0.033, 0.500) then
        return true
    end
end

local function IsUnitNetted(unit)
    if unit.buff['caitlynyordletrapinternal'] then 
        return true 
    end
    return false
end 

local function IsUnitImmobilizedByTrap(unit)
    if unit.buff['caitlynyordletrapdebuff'] then 
        return true 
    end 
    return false
end 

local function HasAutoAttackRangeBuff()
    if player.buff['caitlynheadshotrangecheck'] then 
        return true
    end 
    return false
end 

local function HasAutoAttackRangeBuffOnChamp() 
    if player.buff['caitlynheadshotrangecheck'] then 
        for i=0, objManager.enemies_n-1 do
            local unit = objManager.enemies[i]
            if unit and common.IsValidTarget(unit) then
                if unit.pos:dist(player) <= 1350 and IsUnitNetted(unit) then 
                    return true 
                end 
            end 
        end
    end 
    return false
end

local function rTraceFilter(seg, obj)
	if zPred.trace.linear.hardlock(pred_q, seg, obj) then
		return true
	end
	if zPred.trace.linear.hardlockmove(pred_q, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if pred_q.range < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	if zPred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

local function GetMovementBlockedDebuffDuration(target)
    for i = 0, target.buffManager.count - 1 do
        local buff = target.buffManager:get(i)
        if buff and buff.valid and buff.type == 24 or buff.type == 5 then 
            return (buff.endTime - game.time) * 1000
        end
    end
    return 0
end

local function GetTrapsInRange(position, range)
    for i, obj in pairs(W_Trap_troy) do 
        if obj then 
            return obj.pos:dist(position) < range 
        end 
    end 
end 

local function IsValidWCast(castPosition, minRange, time)
    local minRange = 200 or minRange
    local time = 2.00 or time
    if not GetTrapsInRange(castPosition, minRange) and game.time - _lastWCastTime >= time then 
        return true 
    end 
    return false
end 

local function GetTotalComboDamage(target)
    if player.isDead then return end 
    if target == nil then return end 
    local Samage = 0
    if player:spellSlot(0).state == 0 then 
        Samage = damage.GetSpellDamage(0, target)
    end 
    if player:spellSlot(1).state == 0 then 
        Samage = damage.GetSpellDamage(1, target)
    end 
    if player:spellSlot(2).state == 0 then 
        Samage = damage.GetSpellDamage(2, target)
    end 
    if player:spellSlot(3).state == 0 then 
        Samage = damage.GetSpellDamage(3, target)
    end 
    return Samage
end 

local function OnDrawing()   
    if player.isDead and player.buff[17] and not player.isOnScreen then 
        return 
    end 

    if menu.draws['qrange']:get() and player:spellSlot(0).state == 0 then 
        graphics.draw_circle(player.pos, pred_q.range, 1, menu.draws['qcolor']:get(), 100)
    end 

    if menu.draws['wrange']:get() and player:spellSlot(1).state == 0 then 
        graphics.draw_circle(player.pos, 800, 1, menu.draws['wcolor']:get(), 100)
    end 

    if menu.draws['erange']:get() and player:spellSlot(2).state == 0 then 
        graphics.draw_circle(player.pos, pred_e.range, 1, menu.draws['ecolor']:get(), 100)
    end 
    
    --Test objec
    for i, obj in pairs(W_Trap_troy) do 
        if obj then 
            graphics.draw_circle(obj.pos, 150, 1, graphics.argb(255, 255, 255, 0), 100)
        end 
    end
end 


local function OnGabcloser()
    local target = TS.get_result(function(res, obj, dist)
        if dist > 2500 or common.GetPercentHealth(obj) > 40 then
            return
        end
        if dist <= (800 + obj.boundingRadius) and obj.path.isActive and obj.path.isDashing then
            res.obj = obj
            return true
        end
    end).obj
    if target then
        local pred_pos = zPred.core.lerp(target.path, network.latency + 0.25, target.path.dashSpeed)
        if pred_pos and pred_pos:dist(player.path.serverPos2D) > common.GetAARange() and pred_pos:dist(player.path.serverPos2D) <= 1200 then
            player:castSpell("pos", 1,  vec3(pred_pos.x, target.y, pred_pos.y))
        end 
        local seg = zPred.linear.get_prediction(pred_e, target)
        if seg and seg.startPos:dist(seg.endPos) <= 800 then
            local col = zPred.collision.get_prediction(pred_e, seg, target)
            if not col then
                local pred_pos = vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y)
                local GetDashEndPos = player.pos + (pred_pos - player.pos):norm() * -400
                if not common.IsUnderDangerousTower(GetDashEndPos) then     
                    player:castSpell("pos", 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end 
            end 
        end
    end 
    --Epecial 
    local targetgab = TS.get_result(function(res, obj, dist)
        if dist > 2500 or common.GetPercentHealth(obj) > 40 then
            return
        end
        if obj.path.isActive and obj.path.isDashing then
            res.obj = obj
            return true
        end
    end).obj
    if targetgab then 
        local pathStartPos = targetgab.path.point[0]
        local pathEndPos = targetgab.path.point[targetgab.path.count] 
        if pathEndPos and pathEndPos:dist(player) <= 800 then 
            if IsValidWCast(pathEndPos) then 
                player:castSpell("pos", 1, pathEndPos)
            end
        end 
    end 
end

local function OnPreAttack()
    IsPreAttack = true 
end 

local function Flee()
    player:move(mousePos)
    if menu.Flee.fleeE:get() and common.GetPercentHealth(player) <= menu.Flee.mana_mngr:get() then 
        local DashEndPos = player.pos + (mousePos - player.pos):norm() * -800
        if player:spellSlot(2).state == 0 then 
            player:castSpell("pos", 2, DashEndPos)
        end
    end 
end 

local function Combo()
    if (menu.combo.esettings.ecombo:get() and player:spellSlot(2).state == 0 and not HasAutoAttackRangeBuffOnChamp() and common.GetPercentMana(player) >= menu.combo.esettings.mana_mngr:get()) then 
        local target = TS.get_result(function(res, obj, dist)
            if (dist > 1300 or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and common.IsValidTarget(obj) then
                res.obj = obj
                return true
            end
        end).obj
        if target and target.pos:dist(player) <= common.GetAARange() and (common.IsMovingTowards(target) or common.IsInRange(common.GetAARange() - 150, player, target)) then 
            local seg = zPred.linear.get_prediction(pred_e, target)
            if seg and seg.startPos:dist(seg.endPos) <= 800 then
                local col = zPred.collision.get_prediction(pred_e, seg, target)
                if not col then
                    local pred_pos = vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y)
                    local GetDashEndPos = player.pos + (pred_pos - player.pos):norm() * -400
                    if not common.IsUnderDangerousTower(GetDashEndPos) then     
                        player:castSpell("pos", 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                end 
            end
        end 
        if target and common.IsValidTarget(target) then
            local ePrediciton = zPred.linear.get_prediction(pred_e, target)
            local pred_pos = vec3(ePrediciton.endPos.x, game.mousePos.y, ePrediciton.endPos.y)
            local GetDashEndPos = player.pos + (pred_pos - player.pos):norm() * -400
            if ePrediciton and not common.IsUnderDangerousTower(GetDashEndPos) then    
                local Samage = 0; 
                Samage = damage.GetSpellDamage(2, target)

                local endPos = GetDashEndPos;

                local predictiedUnitPosition = target.pos + (target.path.serverPos - target.pos):norm() * (target.moveSpeed * 0.5 * 0.35)
                local unitPosafterAfter = predictiedUnitPosition + (target.path.serverPos - predictiedUnitPosition):norm() * (target.moveSpeed  * 0.25);

                if (common.IsInRange(1300, endPos, predictiedUnitPosition)) then 
                    Samage =  common.CalculateAADamage(target)
                end 

                if (player:spellSlot(0).state == 0 and common.IsInRange(1200, endPos, unitPosafterAfter)) then 
                    Samage = damage.GetSpellDamage(0, target)
                end

                if ( common.IsInRange(common.GetAARange() - 100, endPos, target) or (target.combatType == 1 and target.pos:dist(player.pos) <= 400)) then 
                    player:castSpell("pos", 2, ePrediciton.endPos)
                end
            end 
        end
    end 
    --W 
    if (menu.combo.wsettings.wcombo:get() and player:spellSlot(1).state == 0 and not IsPreAttack) and common.GetPercentMana(player) >= menu.combo.wsettings.mana_mngr:get() then 
        local target = TS.get_result(function(res, obj, dist)
            if (dist > 800 or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and common.IsValidTarget(obj) and not common.IsUnderDangerousTower(obj.pos) then
                res.obj = obj
                return true
            end
        end).obj
        if target and target.combatType == 1 and (target.pos:dist(player.pos) <= 500) and common.IsInRange(common.GetAARange(), player, target) and common.IsMovingTowards(target, 400) and IsValidWCast(player.path.serverPos) then 
            player:castSpell("pos", 1, player.path.serverPos)
        end 
        if target ~= nil then 
            local seg = zPred.circular.get_prediction(pred_w, target)
            if seg and (seg.endPos:dist(target) > 50) and IsValidWCast(vec3(seg.endPos.x, target.y, seg.endPos.y)) then 
                player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end
        end 
    end
    --Q 
    if (menu.combo.qsettings.qcombo:get() and not IsPreAttack and player:spellSlot(0).state == 0 and not common.IsUnderDangerousTower(player.pos)  and not HasAutoAttackRangeBuffOnChamp()) and common.GetPercentMana(player) >= menu.combo.qsettings.mana_mngr:get() then 
        local target = TS.get_result(function(res, obj, dist)
            if (dist > pred_q.range or obj.buff["rocketgrab"]or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if dist <= common.GetAARange(obj) then
                local aa_damage = common.CalculateAADamage(obj, player)
                if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
                    return
                end
            end
            if obj and common.IsValidTarget(obj) then
                res.obj = obj
                return true
            end
        end).obj
        if target and target.pos:dist(player) > common.GetAARange() then 
            local seg = zPred.linear.get_prediction(pred_q, target)
            if seg and seg.startPos:dist(seg.endPos) < 1350 and kalman.KalmanFilter(target) then
                if menu.combo.qsettings.qonly:get()  then 
                    if rTraceFilter(seg, target) and #common.CountEnemiesInRange(player.pos, common.GetAARange(player)) == 0 then     
                        player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                elseif not menu.combo.qsettings.qonly:get() then 
                    if rTraceFilter(seg, target) then     
                        player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                end
            end
        end
    end
    --R
    if menu.combo.rsettings.rcombo:get() and not IsPreAttack and player:spellSlot(3).state == 0 and not common.IsUnderDangerousTower(player.pos) then 
        local target = TS.get_result(function(res, obj, dist)
            if (dist > 3500 or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and common.IsValidTarget(obj) and damage.GetSpellDamage(3, obj) > common.GetShieldedHealth("AD", obj) then
                res.obj = obj
                return true
            end
        end).obj

        if target then 
            if player:spellSlot(0).state == 0 and target.pos:dist(player) <= 1300 and damage.GetSpellDamage(0, target) > common.GetShieldedHealth("AD", target) then return end 
            if (menu.combo.rsettings.safe:get() and #common.CountEnemiesInRange(player.pos, menu.combo.rsettings.Rrange:get()) == 0 and #common.CountEnemiesInRange(target.pos, 550) == 0) and not IsPreAttack then 
                player:castSpell("obj", 3, target)
            end 
        end
    end 
end 

local function Harass()
    if (not menu.harass.qsettings.qharras:get() or player:spellSlot(0).state ~= 0 or (common.GetPercentMana(player) < menu.harass.qsettings.mana_mngr:get()) or
    common.IsUnderDangerousTower(player.pos) or HasAutoAttackRangeBuffOnChamp() or #common.CountEnemiesInRange(player.pos, common.GetAARange()) ~= 0) then return end
    
    local target = TS.get_result(function(res, obj, dist)
        if (dist > pred_q.range or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
            return
        end
        if dist <= common.GetAARange(obj) then
            local aa_damage =  common.CalculateAADamage(obj, player)
            if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
                return
            end
        end
        if obj and common.IsValidTarget(obj) then
            res.obj = obj
            return true
        end
    end).obj
    if target then 
        local seg = zPred.linear.get_prediction(pred_q, target)
        if seg and seg.startPos:dist(seg.endPos) <= 1350 then
            player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
        end
    end
end

local function Clear()
    if menu.lane.useQ:get() and common.GetPercentMana(player) >=  menu.lane.mana_mngr:get() then
        local valid = {}
        for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion then
                local dist = player.path.serverPos:distSqr(minion.path.serverPos)
                if dist <= 1638400 then
                    valid[#valid + 1] = minion
                end
            end
        end
        local max_count, cast_pos = 0, nil
        for i = 1, #valid do
            local minion_a = valid[i]
            local current_pos = player.path.serverPos + ((minion_a.path.serverPos - player.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos) + 1300))
            local hit_count = 1
            for j = 1, #valid do
                if j ~= i then
                    local minion_b = valid[j]
                    local point = mathf.closest_vec_line(minion_b.path.serverPos, player.path.serverPos, current_pos)
                    if point and point:dist(minion_b.path.serverPos) < (minion_b.boundingRadius) then
                        hit_count = hit_count + 1
                    end
                end
            end
            if not cast_pos or hit_count > max_count then
                cast_pos, max_count = current_pos, hit_count
            end
            if cast_pos and max_count > 3 then
                player:castSpell("pos", 0, cast_pos)
            end
        end
    end
end 

local function KillSteal() 
    for i=0, objManager.enemies_n-1 do
        local unit = objManager.enemies[i]
        if unit and common.IsValidTarget(unit) then 
            if menu.kill.rkill:get() and player.pos:dist(unit) <= 3500 and damage.GetSpellDamage(3, unit) > common.GetShieldedHealth("AD", unit) then
                if player:spellSlot(0).state == 0 and unit.pos:dist(player) <= 1300 and damage.GetSpellDamage(0, unit) > common.GetShieldedHealth("AD", unit) then return end 
                if (menu.combo.rsettings.safe:get() and #common.CountEnemiesInRange(player.pos, menu.combo.rsettings.Rrange:get()) == 0 and #common.CountEnemiesInRange(unit.pos, 550) == 0) and not IsPreAttack then 
                    player:castSpell("obj", 3, unit)
                end 
            end
        end 
    end
end

local function OnTick() 
    if player.isDead then return end

    for i=0, objManager.enemies_n-1 do
        local unit = objManager.enemies[i]
        if unit and common.IsValidTarget(unit) and HasAutoAttackRangeBuffOnChamp() then 
            if unit.buff['caitlynyordletrapinternal'] then 
                player:attack(unit)
            end 
        end 
    end

    IsPreAttack = false; 
    if player:spellSlot(0).state ~= 0 then 
        _lastWCastTime = 0 
    end 

    if menu.Flee.keyjump:get() then 
        Flee();
    elseif orb.menu.combat.key:get() then
        Combo();
    elseif orb.menu.hybrid.key:get() then
        Harass();
    elseif orb.menu.lane_clear.key:get() then
        Clear();
    end
    KillSteal();
    OnGabcloser();
end 

local function OnProcessSpell(spell) 
    --log(spell.name) --
    --CaitlynYordleTrap
    if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Caitlyn" then 
        if spell.name == 'CaitlynYordleTrap' then 
            _lastWCastTime = game.time 
        end 
    end 
    --[[if spell and spell.owner.isMe then 
        if spell.name == 'SummonerTeleport' then 
            spellend = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)
        end 
    end]] 
end 

local function OnCreateObject(object) 
    if object then
        if object.name:find("W_Indicator") then
            W_Trap_troy[object.ptr] = object
        end 
    end
end 
local function OnDeleObject(object) 
    if object then 
        W_Trap_troy[object.ptr] = nil
    end 
end 

cb.add(cb.draw, OnDrawing)
--
orb.combat.register_f_pre_tick(OnPreAttack)
cb.add(cb.tick, OnTick)
--
cb.add(cb.spell, OnProcessSpell)
--cb.add(cb.cast_spell, CastSpell)
--Creat Trap
cb.add(cb.delete_particle, OnDeleObject)
cb.add(cb.create_particle, OnCreateObject)
