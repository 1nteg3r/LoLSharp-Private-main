local evade = module.seek("evade");
local Interrupter = module.load("int", "interrupter");
local TS = module.internal("TS");
local orb = module.internal("orb");
local common = module.load("int", "common");
local pred = module.internal("pred");

local last_q_time = 0;
local last_q_active = false;
local last_Q_tick = game.time;
local visionTick = game.time;
local Xerath = {
    StackR = 0
}

local function TargetQ(res, obj, dist)
    if dist <= 1350 then
        res.obj = obj
        return true
    end
end

local function TargetW(res, obj, dist)
    if dist <= 1000 then
        res.obj = obj
        return true
    end
end

local function TargetE(res, obj, dist)
    if dist <= 1000 then
        res.obj = obj
        return true
    end
end

local function TargetR(res, obj, dist)
    if dist <= 5000 then
        if obj.pos:dist(mousePos) <= 800 then
            res.obj = obj
            return true
        end
    end
end

local GetTargetQ = function()
	return TS.get_result(TargetQ).obj
end

local GetTargetE = function()
	return TS.get_result(TargetE).obj
end

local GetTargetW = function()
	return TS.get_result(TargetW).obj
end

local GetTargetR = function()
	return TS.get_result(TargetR).obj
end

local function GetDistance2D(p1,p2)
    return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end

local _OnWaypoint = {}
local function OnWaypoint(unit)
    if _OnWaypoint[unit.networkID] == nil then 
        _OnWaypoint[unit.networkID] = {pos = unit.pos , speed = unit.moveSpeed, time = game.time} 
    end
	if _OnWaypoint[unit.networkID].pos ~= unit.pos then 
		--print("OnWayPoint:"..unit.charName.." | "..math.floor(game.time))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.pos , speed = unit.moveSpeed, time = game.time}
        common.DelayAction(function()
				local time = (game.time - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(game.time - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and unit.pos:dist(OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(game.time - _OnWaypoint[unit.networkID].time)
					--print("OnDash: "..unit.charName)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end
local _OnVision = {}
local function OnVision(unit)
    if _OnVision[unit.networkID] == nil then 
        _OnVision[unit.networkID] = {state = unit.isVisible , tick = game.time, pos = unit.pos} 
    end
    if _OnVision[unit.networkID].state == true and not unit.isVisible then 
        _OnVision[unit.networkID].state = false 
        _OnVision[unit.networkID].tick = game.time 
    end
    if _OnVision[unit.networkID].state == false and unit.isVisible then 
        _OnVision[unit.networkID].state = true 
        _OnVision[unit.networkID].tick = game.time 
    end
	return _OnVision[unit.networkID]
end

local predq = {
	pred = {
        range = 750;
		delay = 0.0049999998882413; 
		width = 100;
		speed = 500;
		boundingRadiusMod = 1; 
		collision = { hero = false, minion = false };
	}
}

local prede = {
    renge = 1000;
    delay = 0.25; 
    width = 70;
    speed = 1600;
    boundingRadiusMod = 1; 
    collision = { hero = true, minion = true };
}

local perdW = {
    renge = 1000;
    delay = 0.25; 
    radius = 200;
    speed = 20;
    boundingRadiusMod = 0; 
    collision = { hero = false, minion = false };
}

local perdR = {
    renge = 5000;
    delay = 0.5; 
    radius = 100;
    speed = 500;
    boundingRadiusMod = 0; 
}


local function HasBuff(unit, name)
    local buff = player.buff[string.lower(name)];
    if buff and buff.valid and buff.owner == unit then 
        if game.time <= buff.endTime then
            return true, buff.startTime
        end
    end
    return false
end

--Damages:
local function qDmg(target)
    local damage = 0
    if (player:spellSlot(0).state == 0) then
        damage = common.CalculateMagicDamage(target, ({80, 120, 160, 200, 240})[player:spellSlot(0).level] + common.GetTotalAP()* .75)
    end
    return damage
end

local function wDmg(target)
    local damage = 0
    if (player:spellSlot(1).state == 0) then
        damage = common.CalculateMagicDamage(target, ({60, 90, 120, 150, 180})[player:spellSlot(1).level] + common.GetTotalAP()* .60)
    end
    return damage
end


local function eDmg(target)
    local damage = 0
    if (player:spellSlot(2).state == 0) then
        damage = common.CalculateMagicDamage(target, ({80, 110, 140, 170, 200})[player:spellSlot(2).level] + common.GetTotalAP()* .45)
    end
    return damage
end

local function rDmg(target)
    local damage = 0
    local buff = HasBuff(player, 'XerathLocusOfPower2');
    if (player:spellSlot(3).state == 0) or (buff) then
        damage = common.CalculateMagicDamage(target, ({200, 240, 280})[player:spellSlot(3).level] + common.GetTotalAP()* .43)
    end
    return damage * Xerath.StackR
end


local menu = menu("int", "Int Xerath");
--subs menu
menu:header("xs", "Core");
menu:keybind("combokey", "Combo Key", "Space", nil)
menu:boolean('q', 'Use Q', true);
menu:boolean('w', 'Use W', true);
menu:boolean('e', 'Use E', true);
menu:boolean('gape', '^ Use E Anti-Gapclose', true);
menu:boolean('r', 'Use R', true);
menu:menu('rs', "R Settings");
menu.rs:boolean('sdrq', "Draw Circle range to use", true);
menu.rs:slider('ruse', 'How big should the circle be?', 800, 1, 2000, 1);
menu.rs:boolean("disable_evade", "Disable Evade while R", true);
--Harrasing
menu:menu('hass', "Harras");
menu.hass:keybind("haraskey", "Harass Key", "C", nil)
menu.hass:boolean('q', 'Use Q', true);
menu.hass:boolean('w', 'Use W', true);
menu.hass:boolean('e', 'Use E', false);
--Misc
menu:header("miscmenu", "Misc");
menu:menu("inter", "Interrupt -> Spells Targets", true);
Interrupter.load_to_menu(menu.inter);
--Display
menu:header("dismenu", "Display");
menu:menu('dis', "Display");
menu.dis:boolean('dq', 'Q Range', true);
menu.dis:boolean('dr', 'R Range Minimap', true);


cb.add(cb.spell, function(spell)
    if(spell.owner == player) then
        --print("Spell name: " ..spell.name);
        --print("Speed:" ..spell.static.missileSpeed)
        --print("Width: " ..spell.static.lineWidth)
        --print("Time:" ..spell.windUpTime)
        --print("Animation: " ..spell.animationTime)
        --print(spell.isBasicAttack)
        --print("CastFrame: " ..spell.clientWindUpTime)
    end
end)
--[[ --Spell Q?
    Spell name: XerathArcanopulseChargeUp
    Speed:500
    Width: 100
    Time:0.0049999998882413
    Animation: 3.0050001144409
    Spell name: XerathArcanopulse2
    Speed:3000
    Width: 0
    Time:0

    --Spell E?
    Spell name: XerathMageSpear
    Speed:1600
    Width: 70
    Time:0.25
    Animation: 1
]]

local function q_range()
    local t = game.time - last_q_time;
    local range = 750;

    if t > 0 then
        range = range + 500*(game.time - last_q_time) + t/1000
    end
    
    if range > 1350 then
        return 1350
    end

    return range
end

local function Combo()
    local unit = GetTargetQ();
    local unitW = GetTargetW();
    local unitE = GetTargetE();
    local qcombo = menu.q:get();
    local wcombo = menu.w:get();
    local ecombo = menu.e:get();
    if unitE and common.IsValidTarget(unitE) then
        --E
        if (ecombo) and (player:spellSlot(2).state == 0) then 
            if (unitE.pos:dist(player.pos) < 1000) then 
                if unitE.pos:dist(player.pos) > q_range() then return end
                local epred = pred.linear.get_prediction(prede, unitE)
                if not epred then return end
                    
                if not pred.collision.get_prediction(prede, epred, unitE) then
                    if epred.startPos:dist(epred.endPos) > 1000 then return false end
                    if pred.trace.linear.hardlock(prede, epred, unitE) then
                        return true
                    end
                    if pred.trace.linear.hardlockmove(prede, epred, unitE) then
                        return true
                    end
                    if (unitE.path.active and unitE.path.count > 0) then
                        if pred.trace.newpath(unitE, 0.033, 0.500) then
                            return true
                        end
                    end
                    player:castSpell("pos", 2, vec3(epred.endPos.x, player.pos.y, epred.endPos.y))
                end
            end
        end
    end
    if unitW and common.IsValidTarget(unitW) then
        --W  
        if (wcombo) and (player:spellSlot(1).state == 0) then 
            if (unitW.pos:dist(player.pos) < 1000) then 
                if unitW.pos:dist(player.pos) > q_range() then return end
                local wpred = pred.circular.get_prediction(perdW, unitW)
                if not wpred then return end
                    
                if wpred.startPos:dist(wpred.endPos) < 1000 then 
                    player:castSpell("pos", 1, vec3(wpred.endPos.x, player.pos.y, wpred.endPos.y))
                end
            end
        end
    end 
    if unit and common.IsValidTarget(unit) then
        --Q
        if player:spellSlot(0).state ~= 0 then return end
        if (player:spellSlot(2).state == 0 and unit.pos:dist(player.pos) < 0) and not HasBuff(player, 'XerathArcanopulseChargeUp') then return end
        if unit.pos:dist(player.pos) > q_range() then return end

        local qpred = pred.linear.get_prediction(predq.pred, unit)
        if not qpred then return end
            
        if not pred.collision.get_prediction(predq.pred, qpred, unit) or unit.pos:dist(player.pos) <= 400 then
            if (qcombo) and HasBuff(player, 'XerathArcanopulseChargeUp') then
                if unit.pos:dist(player.pos) + 150 < q_range() - 25 or (unit.pos:dist(player.pos) < 400 and q_range() <= 400) then
                    player:castSpell("release", 0, vec3(qpred.endPos.x, player.pos.y, qpred.endPos.y))
                end
            else
                player:castSpell("pos", 0, unit.pos)
            end
            --[[if HasBuff(player, 'XerathArcanopulseChargeUp') then
                if unit.pos:dist(player.pos) + 150 < q_range() - 25 or (unit.pos:dist(player.pos) < 400 and q_range() <= 400) then
                    if (game.time - OnWaypoint(unit).time > 0.05) then

                        player:castSpell("release", 0, vec3(qpred.endPos.x, player.pos.y, qpred.endPos.y))
                        chat.print('WW')
                    end
                end
            end]]
        end
    end
end

--[[local function CastingQ()
	if last_q_active == true then
		Xerath.Qrange = 750 + 500*(game.time - last_q_time)/1000
		if Xerath.Qrange > 1500 then Xerath.Qrange = 1500 end
    end
    local qbuff = HasBuff(player, 'XerathArcanopulseChargeUp');
	if last_q_active == false and (qbuff) then
		last_q_time = game.time;
		last_q_active = true;
	end
	if last_q_active == true and not (qbuff) then
		last_q_active = false;
		Xerath.Qrange = 750;
	end
end]]


local function R_Tick()
    local Delay = 0;
    local unit = GetTargetR();
    local buff = HasBuff(player, 'XerathLocusOfPower2'); --XerathLocusOfPower2
    if (buff) then
        if unit and common.IsValidTarget(unit) then 
            if unit.pos:dist(mousePos) <= menu.rs.ruse:get() then
                local pos = pred.circular.get_prediction(perdR, unit)
				if pos and pos.startPos:dist(pos.endPos) < 5000 and game.time - Delay > 0 then
                    player:castSpell("pos", 3, vec3(pos.endPos.x, player.pos.y, pos.endPos.y))
                    Delay = game.time + 1
                    --chat.print('1111')
                end
            end
            if game.time - OnWaypoint(unit).time > 0.05 and (((game.time - OnWaypoint(unit).time < 0.15 or game.time - OnWaypoint(unit).time > 1.0) and OnVision(unit).state == true) or (OnVision(unit).state == false)) and (player.pos:dist(unit.pos) < q_range() - unit.boundingRadius) then
                local rpred = pred.circular.get_prediction(perdR, unit)
                if not rpred then return end
				if rpred and rpred.startPos:dist(rpred.endPos) < 5000 and game.time - Delay > 0 then
                    player:castSpell("pos", 3, vec3(rpred.endPos.x, player.pos.y, rpred.endPos.y)) 
                    Delay = game.time + 1
                    --chat.print('Onf')
                end
            end
        end
    end
end

local function OnGame()
    local buff, time = HasBuff(player, 'XerathArcanopulseChargeUp'); --XerathLocusOfPower2
    if buff then 
        last_q_time = time;
        last_q_active = true;
        orb.core.set_pause_attack(math.huge)
    else
        orb.core.set_pause_attack(0)
        last_q_active = false;
    end
    --CastingQ();
    if (game.time - visionTick > 100) then
        for i = 0, objManager.enemies_n - 1 do
            local enemy = objManager.enemies[i]
            if enemy then
                OnVision(enemy)
            end 
        end
    end
        --SpellR:
    if player:spellSlot(3).level > 0 then
        if (player:spellSlot(3).level == 1) then
            Xerath.StackR = 3;
        elseif (player:spellSlot(3).level == 2) then 
            Xerath.StackR = 4;
        elseif (player:spellSlot(3).level == 3) then 
            Xerath.StackR = 5;
        end
    end 
    if (menu.rs.disable_evade:get()) then 
        local buff = HasBuff(player, 'XerathLocusOfPower2'); --XerathLocusOfPower2
        if buff then
            if (evade) then
                evade.core.set_pause(math.huge)
            end
            orb.core.set_pause_move(math.huge)
            orb.core.set_pause_attack(math.huge)
        else 
            if (evade) then
                evade.core.set_pause(0)
            end
            orb.core.set_pause_move(0)
            orb.core.set_pause_attack(0)
        end
    end

    if (menu.r:get()) then
        R_Tick();
    end

    if  (menu.gape:get()) then
        local seg = {}
		local target =
			TS.get_result(
			function(res, obj, dist)
				if dist <= 950 and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
					res.obj = obj
					return true
				end
			end
		).obj
		if target then
			local pred_pos = pred.core.lerp(target.path, network.latency + 0.25, target.path.dashSpeed)
			if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 950 then
				seg.startPos = player.path.serverPos2D
				seg.endPos = vec2(pred_pos.x, pred_pos.y)

				player:castSpell("pos", 2, vec3(pred_pos.x, target.y, pred_pos.y))
			end
		end
    end
end 

local function Harass()
    local unit = GetTargetQ();
    local unitW = GetTargetW();
    local unitE = GetTargetE();
    local qcombo = menu.hass.q:get();
    local wcombo = menu.hass.w:get();
    local ecombo = menu.hass.e:get();
    if unitE and common.IsValidTarget(unitE) then
        --E
        if (player:spellSlot(2).state == 0) then 
            if (unitE.pos:dist(player.pos) < 1000) then 
                if unitE.pos:dist(player.pos) > q_range() then return end
                local epred = pred.linear.get_prediction(prede, unitE)
                if not epred then return end
                    
                if not pred.collision.get_prediction(prede, epred, unitE) then
                    if epred.startPos:dist(epred.endPos) > 1000 then return false end
                    if pred.trace.linear.hardlock(prede, epred, unitE) then
                        return true
                    end
                    if pred.trace.linear.hardlockmove(prede, epred, unitE) then
                        return true
                    end
                    if (unitE.path.active and unitE.path.count > 0) then
                        if pred.trace.newpath(unitE, 0.033, 0.500) then
                            return true
                        end
                    end
                    player:castSpell("pos", 2, vec3(epred.endPos.x, player.pos.y, epred.endPos.y))
                end
            end
        end
    end
    if unitW and common.IsValidTarget(unitW) then
        --W  
        if (wcombo) and (player:spellSlot(1).state == 0) then 
            if (unitW.pos:dist(player.pos) < 1000) then 
                if unitW.pos:dist(player.pos) > q_range() then return end
                local wpred = pred.circular.get_prediction(perdW, unitW)
                if not wpred then return end
                    
                if wpred.startPos:dist(wpred.endPos) < 1000 then 
                    if pred.trace.circular.hardlock(perdW, wpred, unitW) then
                        return true
                    end
                    player:castSpell("pos", 1, vec3(wpred.endPos.x, player.pos.y, wpred.endPos.y))
                end
            end
        end
    end 
    if unit and common.IsValidTarget(unit) then
                --Q
        if player:spellSlot(0).state ~= 0 then return end
        if (player:spellSlot(2).state == 0 and unit.pos:dist(player.pos) < 0) and not HasBuff(player, 'XerathArcanopulseChargeUp') then return end
        if unit.pos:dist(player.pos) > q_range() then return end

        local qpred = pred.linear.get_prediction(predq.pred, unit)
        if not qpred then return end
            
        if not pred.collision.get_prediction(predq.pred, qpred, unit) or unit.pos:dist(player.pos) <= 400 then
            if (qcombo) and HasBuff(player, 'XerathArcanopulseChargeUp') then
                if unit.pos:dist(player.pos) + 150 < q_range() - 25 or (unit.pos:dist(player.pos) < 400 and q_range() <= 400) then
                    if pred.trace.linear.hardlock(predq.pred, qpred, unit) then
                        return true
                    end
                    player:castSpell("release", 0, vec3(qpred.endPos.x, player.pos.y, qpred.endPos.y))
                end
            else
                player:castSpell("pos", 0, vec3(qpred.endPos.x, player.pos.y, qpred.endPos.y))
            end
            --Release spell.
            if game.time - OnWaypoint(unit).time > 0.05 and (((game.time - OnWaypoint(unit).time < 0.15 or game.time - OnWaypoint(unit).time > 1.0) and OnVision(unit).state == true) or (OnVision(unit).state == false)) and (player.pos:dist(unit.pos) < q_range() - unit.boundingRadius) then
                if (qcombo) and HasBuff(player, 'XerathArcanopulseChargeUp') then
                    if unit.pos:dist(player.pos) + 150 < q_range() - 25 or (unit.pos:dist(player.pos) < 400 and q_range() <= 400) then
                        if pred.trace.linear.hardlock(predq.pred, qpred, unit) then
                            return true
                        end
                        player:castSpell("release", 0, vec3(qpred.endPos.x, player.pos.y, qpred.endPos.y))
                    end
                else
                    player:castSpell("pos", 0, vec3(qpred.endPos.x, player.pos.y, qpred.endPos.y))
                end
            end
            --[[if HasBuff(player, 'XerathArcanopulseChargeUp') then
                if unit.pos:dist(player.pos) + 150 < q_range() - 25 or (unit.pos:dist(player.pos) < 400 and q_range() <= 400) then
                    if (game.time - OnWaypoint(unit).time > 0.05) then

                        player:castSpell("release", 0, vec3(qpred.endPos.x, player.pos.y, qpred.endPos.y))
                        chat.print('WW')
                    end
                end
            end]]
        end
    end
end

local function OnTick()
    if keyboard.isKeyDown(0x20) then
        Combo();
    end
    --Harass: 0x43
    if keyboard.isKeyDown(0x43) then
        Harass();
    end
end

local function ondraw()
    local qdraw = menu.dis.dq:get();
    local rdraw = menu.dis.dr:get();
    if (player and player.isDead and not player.isTargetable) then return end
    if (player.isOnScreen) then 
        if (qdraw and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, q_range(), 2, graphics.argb(255, 192, 57, 43), 40)
        end
        if (rdraw and player:spellSlot(3).state == 0) then
            minimap.draw_circle(player.pos, 5000, 2.4, 0xFFFFFFFF, 16);
        end
    end
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and target.isVisible and common.IsValidTarget(target) then
            if target.isOnScreen then 
                local damage = (qDmg(target) + wDmg(target) + eDmg(target) + rDmg(target))
                local barPos = target.barPos                   
                local percentHealthAfterDamage = math.max(0, target.health - damage) / target.maxHealth
                graphics.draw_line_2D(barPos.x + 165 + 103 * target.health/target.maxHealth, barPos.y+123, barPos.x + 165 + 100 * percentHealthAfterDamage, barPos.y+123, 11,  graphics.argb(90, 255, 169, 4))        
            end 
        end 
    end
    if (menu.rs.sdrq:get()) then 
        graphics.draw_circle(mousePos, menu.rs.ruse:get(), 1, 0xFFFFFFFF, 10);
    end
end

local function OnInterruptable(unit, spell)
    if spell.owner.team ~= TEAM_ALLY and menu.inter[spell.name]:get() and common.IsValidTarget(unit, 1000) and player:spellSlot(2).state == 0 then
        local Epred = pred.linear.get_prediction(prede, unit)
        if not Epred then return end
        if not pred.collision.get_prediction(prede, Epred, unit) then 
            player:castSpell("pos", 2, vec3(Epred.endPos.x, player.pos.y, Epred.endPos.y))
        end
    end  
end

cb.add(cb.tick, OnGame)
cb.add(cb.draw, ondraw)
Interrupter(OnInterruptable);
orb.combat.register_f_pre_tick(OnTick)