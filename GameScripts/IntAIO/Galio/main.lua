--[[
    TARGET RANGE: 825 - Q
    TARGET RANGE: 650 - W
    TARGET RANGE: 4000 / 4750 / 5500 
]]
local Interrupter = module.load("int", "Library/interrupter");
local evade = module.seek("evade");
local TS = module.internal("TS");
local orb = module.internal("orb");
local common = module.load("int", "Library/common");
local pred = module.internal("pred");

local R_range = 0;
local last_W_charge = 0;

local Prediction = {
    SpellQ = {
        range = 825;
		delay = 0.25; 
		width = 100;
		speed = 1300;
		boundingRadiusMod = 0; 
    },
    SpellE = {
        range = 650;
		delay = 0.40000000596046; 
		width = 160;
		speed = math.huge;
		boundingRadiusMod = 1; 
		collision = { hero = true, minion = false, wall = true };
	},
}

local TargetSelection = function(res, obj, dist)
	if dist < 850 then
		res.obj = obj
		return true
	end
end

local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end

local function trace_filter(seg, obj, dist)
    if seg.startPos:dist(seg.endPos) > Prediction.SpellE.range then
        return false
    end
    if pred.trace.newpath(obj, 0.033, 0.500) and dist < 1000 then
        return true
    end
    if pred.trace.linear.hardlock(Prediction.SpellE, seg, obj) then
        return true
    end
    if pred.trace.linear.hardlockmove(Prediction.SpellE, seg, obj) then
        return true
    end
end

local function HasBuff(unit, name)
    local buff = player.buff[string.lower(name)];
    if buff and buff.valid and buff.owner == unit then 
        if game.time <= buff.endTime then
            return true, buff.startTime
        end
    end
    return false, 0
end

local function width_range()
    local t = game.time - last_W_charge;
    local range = 275;

    if t > 0 then
        range = range + (t/.1 * 62);
    end
    
    if range > 475 then
        return 475
    end

     return range
end

local function qDmg(target)
    local damage = 0
    if (player:spellSlot(0).state == 0) then
        damage = common.CalculateMagicDamage(target, ({80, 115, 150, 185, 220})[player:spellSlot(0).level] + common.GetTotalAP()* .75)
    end
    return damage
end

local function eDmg(target) 
    local damage = 0
    if (player:spellSlot(2).state == 0) then
        damage = common.CalculateMagicDamage(target, ({90, 130, 170, 210, 250})[player:spellSlot(2).level] + common.GetTotalAP()* .90)
    end
    return damage
end

local menu = menu("IntnnerGalio", "Int Galio");
--subs menu
menu:header("xs", "Core");
menu:dropdown("pri", "Retreat Spell", 1, {'E', 'Q'});
menu:header("combomenu", "Combat Galio");
menu:keybind("combokey", "Combo Key", "Space", nil)
menu:boolean('q', 'Use Q', true);
menu:boolean('w', 'Use W', true);
menu:boolean('e', 'Use E', true);
menu:boolean('rede', ' ^ Use Slow Prediction', false);
menu:boolean('r', 'Use R', true);
menu:menu('rs', "R Settings");
menu.rs:boolean('sdrq', "Draw Green Circle", true);
menu.rs:slider('ruse', 'How big should the circle be?', 800, 1, 2000, 1);
menu.rs:slider('renemy', 'if greater or equal enemies, cast R', 3, 1, 5, 1);
menu.rs.renemy:set('tooltip', 'this is to cast your ult when X enemies around it');
--Misc
menu:header("miscmenu", "Misc");
menu:menu("inter", "Interrupt -> Spells Targets", true);
Interrupter.load_to_menu(menu.inter);
--Display
menu:header("dismenu", "Display");
menu:menu('dis', "Display");
menu.dis:boolean('dq', 'Q Range', true);
menu.dis:boolean('de', 'E Range', true);
menu.dis:boolean('dr', 'R Range Minimap', true);

local function OnInterruptable(unit, spell)
    if menu.inter[spell.name]:get() and common.IsValidTarget(unit, 600) and player:spellSlot(2).state == 0 then
        local Epred = pred.linear.get_prediction(Prediction.SpellE, unit)
        if not Epred then return end
        if not pred.collision.get_prediction(Prediction.SpellE, Epred, unit) then 
            player:castSpell("pos", 2, vec3(Epred.endPos.x, game.mousePos.y, Epred.endPos.y))
        end
    end  
end

--[[cb.add(cb.spell, function(spell)
    if(spell.owner == player) then
        print("Spell name: " ..spell.name);
        --print("Speed:" ..spell.static.missileSpeed)
        --print("Width: " ..spell.static.lineWidth)
        --print("Time:" ..spell.windUpTime)
        --print("Animation: " ..spell.animationTime)
        --print(spell.isBasicAttack)
        --print("CastFrame: " ..spell.clientWindUpTime)
    end
end)]]

local function Combo()
    local target = GetTarget();
    local cmode = menu.pri:get();
    local qcombo = menu.q:get();
    local wcombo = menu.w:get();
    local ecombo = menu.e:get();
    if target == nil then return end
    if target and common.IsValidTarget(target) then
        --E
        if (cmode == 1) then
            if (ecombo) and (player:spellSlot(2).state == 0 and target.pos:dist(player.pos) < 600) then 
                local Epred = pred.linear.get_prediction(Prediction.SpellE, target)
                if not Epred then return end
                if not pred.collision.get_prediction(Prediction.SpellE, Epred, target) and not (navmesh.isWall(vec3(Epred.endPos.x, game.mousePos.y, Epred.endPos.y))) then  
                    if (trace_filter(Epred, target, 600) and (menu.rede:get())) then
                        player:castSpell("pos", 2, vec3(Epred.endPos.x, game.mousePos.y, Epred.endPos.y))
                    else 
                        player:castSpell("pos", 2, vec3(Epred.endPos.x, game.mousePos.y, Epred.endPos.y))
                    end
                end
            end
            if (qcombo) and (player:spellSlot(0).state == 0 and target.pos:dist(player.pos) < 825) then 
                local SpellQ = pred.linear.get_prediction(Prediction.SpellQ, target)
                if not SpellQ then return end
                if SpellQ.startPos:dist(SpellQ.endPos) < 825 then
                    if (player:spellSlot(2).state ~= 0) then
                        player:castSpell("pos", 0, vec3(SpellQ.endPos.x, game.mousePos.y, SpellQ.endPos.y))
                    elseif (player:spellSlot(0).state == 0 and player:spellSlot(2).state ~= 0) then
                        player:castSpell("pos", 0, vec3(SpellQ.endPos.x, game.mousePos.y, SpellQ.endPos.y))
                    end
                end
            end
            if (wcombo) then
                if target.pos:dist(player.pos) > width_range() then return end
                if HasBuff(player, "GalioW") then
                    if target.pos:dist(player.pos) < width_range() or (target.pos:dist(player.pos) < 400 and width_range() <= 400) then
                        player:castSpell("release", 1, player.pos)
                    end
                else
                    player:castSpell("pos", 1, player.pos)
                end
            end
        elseif (cmode == 2) then
            if (qcombo) and (player:spellSlot(0).state == 0 and target.pos:dist(player.pos) < 825) then 
                local SpellQ = pred.linear.get_prediction(Prediction.SpellQ, target)
                if not SpellQ then return end
                if SpellQ.startPos:dist(SpellQ.endPos) < 825 then
                    player:castSpell("pos", 0, vec3(SpellQ.endPos.x, game.mousePos.y, SpellQ.endPos.y))
                end
            end
            if (ecombo) and (player:spellSlot(2).state == 0 and target.pos:dist(player.pos) < 600) then 
                local Epred = pred.linear.get_prediction(Prediction.SpellE, target)
                if not Epred then return end
                if not pred.collision.get_prediction(Prediction.SpellE, Epred, target) and not (navmesh.isWall(vec3(Epred.endPos.x, game.mousePos.y, Epred.endPos.y)))  then 
                    if (trace_filter(Epred, target, 600) and (menu.rede:get())) then
                        player:castSpell("pos", 2, vec3(Epred.endPos.x, game.mousePos.y, Epred.endPos.y))
                    else 
                        player:castSpell("pos", 2, vec3(Epred.endPos.x, game.mousePos.y, Epred.endPos.y))
                    end
                end
            end
            if (wcombo) then
                if target.pos:dist(player.pos) > width_range() then return end
                if HasBuff(player, "GalioW") then
                    if target.pos:dist(player.pos) < width_range() or (target.pos:dist(player.pos) < 400 and width_range() <= 400) then
                        player:castSpell("release", 1, player.pos)
                    end
                else
                    player:castSpell("pos", 1, player.pos)
                end
            end
        end
    end
end

local function OnPreTick()
    --SpellW:
    local buff, time = HasBuff(player, "GalioW");
	if buff then
        last_W_charge = time;
        orb.core.set_pause_attack(math.huge)
    else 
        orb.core.set_pause_attack(0)
    end
    --SpellR:
    if player:spellSlot(3).level > 0 then
        if (player:spellSlot(3).level == 1) then
            R_range = 4000;
        elseif (player:spellSlot(3).level == 2) then 
            R_range = 4750;
        elseif (player:spellSlot(3).level == 3) then 
            R_range = 5500;
        end
    end 
    if (menu.combokey:get()) then 
        Combo();
    end
    if (menu.r:get()) then 
        for i = 0, objManager.allies_n-1 do
            local obj = objManager.allies[i]
            if obj and common.IsValidTarget(obj) then 
                if (#common.CountEnemiesInRange(player.pos, 1200) == 0 and player:spellSlot(3).state == 0) then 
                    if (#common.CountEnemiesInRange(obj.pos, menu.rs.ruse:get()) >= menu.rs.renemy:get()) then 
                        if (common.GetPercentHealth(obj) <= 30 and common.GetPercentHealth(player) > common.GetPercentHealth(obj)) then
                            player:castSpell("obj", 3, obj)
                        elseif (common.GetPercentHealth(obj) <= 50 and #common.CountAllyChampAroundObject(obj.pos, 1000)) then
                            player:castSpell("obj", 3, obj)
                        end
                    end
                end
            end
        end
    end
end

local function OnDraw()
    qdraw = menu.dis.dq:get();
    edraw = menu.dis.de:get();
    rdraw = menu.dis.dr:get();
    if (player and player.isDead and not player.isTargetable and not player.buff[17]) then return end
    if not (player.isOnScreen) then return end
    if (qdraw and player:spellSlot(0).state == 0) then
        graphics.draw_circle(player.pos, 825, 2, graphics.argb(215, 255, 113, 255), 40)
    end
    if (edraw and player:spellSlot(2).state == 0) then
        graphics.draw_circle(player.pos, 600, 2, graphics.argb(215, 255, 113, 255), 40)
    end
    if (rdraw and player:spellSlot(3).state == 0) then
        minimap.draw_circle(player.pos, R_range, 2.4, 0xFFFFFFFF, 16);
    end
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and target.isVisible and common.IsValidTarget(target) and not target.buff[17] then
            if target.isOnScreen then 
                local damage = (qDmg(target) + eDmg(target))
                local barPos = target.barPos                   
                local percentHealthAfterDamage = math.max(0, target.health - damage) / target.maxHealth
                graphics.draw_line_2D(barPos.x + 165 + 103 * target.health/target.maxHealth, barPos.y+123, barPos.x + 165 + 100 * percentHealthAfterDamage, barPos.y+123, 11,  graphics.argb(90, 255, 169, 4))        
            end 
        end 
    end
    for i = 0, objManager.allies_n-1 do
        local obj = objManager.allies[i]
        if obj and common.IsValidTarget(obj) then 
            if (#common.CountEnemiesInRange(player.pos, 1200) == 0 and player:spellSlot(3).state == 0) then 
                if (#common.CountEnemiesInRange(obj.pos, menu.rs.ruse:get()) >= menu.rs.renemy:get()) then 
                    if (common.GetPercentHealth(obj) <= 100 and common.GetPercentHealth(player) > common.GetPercentHealth(obj)) then
                        minimap.draw_circle(obj.pos, R_range, 2.4, 0xFF00BB4F, 16);
                    end 
                end
            end 
        end 
    end
end

Interrupter(OnInterruptable);
orb.combat.register_f_pre_tick(OnPreTick);
cb.add(cb.draw, OnDraw);