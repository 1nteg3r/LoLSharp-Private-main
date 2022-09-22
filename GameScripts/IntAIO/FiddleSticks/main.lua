local orb = module.internal("orb");
local pred = module.internal("pred");
local ts = module.internal('TS');
local dlib = module.load('int', 'Library/damageLib');
local common = module.load('int', 'Library/common');
local evade = module.seek("evade");
local Interrupter = module.load("int", "Library/interrupter");

local fuckW = false;
--[[
    Spell name: FiddleSticksE
    Speed:1800
    Width: 70
    Time:0.40000000596046
    Animation: 1
    CastFrame: 0.41261434555054
]]

local spellE = {
	range = 850,
	width = 70,
	speed = 1800,
	delay = 0.25,
	boundingRadiusMod = 1
}

local TargetSelectionQ = function(res, obj, dist) --Range default
	if dist < 575 then
		res.obj = obj
		return true
	end
end

local GetTargetQ = function()
	return ts.get_result(TargetSelectionQ).obj
end

local TargetSelectionW = function(res, obj, dist) --Range default
	if dist < 650 then
		res.obj = obj
		return true
	end
end

local GetTargetW = function()
	return ts.get_result(TargetSelectionW).obj
end

local TargetSelectionE = function(res, obj, dist) --Range default
	if dist < spellE.range then
		res.obj = obj
		return true
	end
end

local GetTargetE = function()
	return ts.get_result(TargetSelectionE).obj
end

local function IsValidTargetInRage(unit, range) 
    return common.IsValidTarget(unit) and (not range or player.pos:dist(unit.pos) <= range)
end

local function ValidUlt(unit)
	if (unit.buff[16] or unit.buff[15] or unit.buff[17] or unit.buff['kindredrnodeathbuff'] or unit.buff["sionpassivezombie"] or unit.buff[4]) then
		return false
	end
	return true
end

local function InAARange(point, target)
    if (orb.combat.is_active()) then
        local targetpos = vec3(target.x, target.y, target.z)
        return point:dist(targetpos) < common.GetAARange() - 300
    else
        return #common.CountEnemiesInRange(point, common.GetAARange()) > 0
    end
end

local menu = menu("IntnnerFlidle", "Int Fiddlesticks");
--subs menu
menu:header("xs", "Core");
menu:menu("combo", "Combo");
menu.combo:boolean("q", "Use Q", true);
menu.combo:dropdown('modeQ', '^ only Q', 1, {'Buff -> Flee', 'Always'});
menu.combo:dropdown('w', 'Use W', 1, {'Never', 'Flee', 'Always'});
menu.combo:dropdown('e', 'Use E', 3, {'Never', 'Out AA Range', 'Always'});

menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:dropdown('modeQ', '^ only Q', 1, {'Buff -> Flee', 'Always'});
menu.harass:dropdown('w', 'Use W', 2, {'Never', 'Flee', 'Always'});
menu.harass:dropdown('e', 'Use E', 2, {'Never', 'Out AA Range', 'Always'});
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 45, 1, 100, 1);

menu:menu("clear", "Clear");
menu.clear:boolean("q", "Use Q", true);
menu.clear:slider("minW", "Use W if hit >= {0}", 5, 1, 10, 1);
menu.clear:slider("Mana", "Minimum Mana Percent >= {0}", 50, 1, 100, 1);
--Jungle
menu.clear:menu("jungle", "Jungle Clear");
menu.clear.jungle:boolean("q", "Use Q", true);
menu.clear.jungle:boolean("w", "Use W", true);
menu.clear.jungle:boolean("e", "Use E", true);
menu.clear.jungle:slider("Mana", "Minimum Mana Percent >= {0}", 20, 1, 100, 1);

menu:menu("misc", "Misc");
menu.misc:menu('inter', 'Interrupt Targets')
Interrupter.load_to_menu(menu.misc.inter) 
menu.misc:boolean("e", "Use E for dash", true);

menu:menu("ddd", "Display");
menu.ddd:boolean("qd", "Q Range", false);
menu.ddd:boolean("wd", "W Range", false);
menu.ddd:boolean("ed", "E Range", true);

local function GetWNetworkID()
    for i = 0, objManager.maxObjects - 1 do
        local obj = objManager.get(i)
        if obj and (obj.type == TYPE_MINION or obj.type == TEAM_NEUTRAL or obj.type == TYPE_HERO)  and obj.team == TEAM_ENEMY and not obj.isDead and obj.health and obj.health > 0 then 
            if obj then 
                if obj.buff['fiddlestickswdrain'] then 
                    fuckW = true
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
                    fuckW = false
                end
            end
        end
    end

    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local minion = objManager.minions[TEAM_NEUTRAL][i]
        if
            minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                minion.type == TYPE_MINION
         then
            if minion.buff['fiddlestickswdrain'] then 
                fuckW = true
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
                fuckW = false
            end
         end
    end
       

    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
		local enemy = objManager.minions[TEAM_ENEMY][i]
        if
        enemy and not enemy.isDead and enemy.isTargetable and enemy.isVisible and
        enemy.type == TYPE_HERO
         then
            if enemy.buff['fiddlestickswdrain'] then 
                fuckW = true
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
                fuckW = false
            end
         end
    end
end 
local function E_for_gabclose()
    local target =
		ts.get_result(
		function(res, obj, dist)
			if dist <= 575 and obj.path.isActive and obj.path.isDashing and not obj.buff['fiddlesticksqcooldown'] then --add invulnverabilty check
				res.obj = obj

				return true
			end
		end
	).obj
    if target then
        if IsValidTargetInRage(target, 575) then
            player:castSpell("obj", 0, target)
        end
	end
end

local function Combo()
    local targetE = GetTargetE();

    if targetE and common.IsValidTarget(targetE) then 
        if menu.combo.e:get() == 3 then 
            if IsValidTargetInRage(targetE, spellE.range) then 
                local seg = pred.linear.get_prediction(spellE, targetE)
                if seg and seg.startPos:dist(seg.endPos) < spellE.range then
                    if player:spellSlot(2).state == 0 then
                        player:castSpell("pos", 2, vec3(seg.endPos.x, targetE.y, seg.endPos.y))
                    end
                end
            end
        end
    end
    local targetQ = GetTargetQ();
    if targetQ and common.IsValidTarget(targetQ) then 
        if menu.combo.modeQ:get() == 1 then 
            if targetQ.buff[string.lower('fiddlesticksqcooldown')] then return end  
            if IsValidTargetInRage(targetQ, 575) then
                if player:spellSlot(0).state == 0 then
                    player:castSpell("obj", 0, targetQ)
                end
            end
        elseif menu.combo.modeQ:get() == 2 then 
            if IsValidTargetInRage(targetQ, 575) then
                if player:spellSlot(0).state == 0 then
                    player:castSpell("obj", 0, targetQ)
                end
            end
        end
    end
    if #common.CountEnemiesInRange(player.pos, 650) >= 2 then 
        --if IsValidTargetInRage(targetW, 600) then 
            if player:spellSlot(1).state == 0 then
                player:castSpell("self", 1)
            end
        --end
    end
    local targetW = GetTargetW();
    if targetW and common.IsValidTarget(targetW) then 
        if menu.combo.w:get() == 2 then 
            if targetW.buff[string.lower('fiddlesticksqcooldown')] then
                if IsValidTargetInRage(targetW, 650) then 
                    if player:spellSlot(1).state == 0 then
                        player:castSpell("self", 1)
                    end
                end
            end
        elseif menu.combo.w:get() == 3 then 
            if IsValidTargetInRage(targetW, 650) then 
                if player:spellSlot(1).state == 0 then
                    player:castSpell("self", 1)
                end
            end
        end
        if common.GetPercentHealth(player) <= 50 and common.GetPercentHealth(targetE) > 50 then 
            if player:spellSlot(1).state == 0 then
                player:castSpell("self", 1)
            end
        end
    end
end 

local function Harass()
    local targetE = GetTargetE();
    if targetE and common.IsValidTarget(targetE) then 
        if menu.harass.e:get() == 3 then 
            if targetE.buff['fiddlestickswdrain'] then return end
            if IsValidTargetInRage(targetE, spellE.range) then 
                local seg = pred.linear.get_prediction(spellE, targetE)
                if seg and seg.startPos:dist(seg.endPos) < spellE.range then
                    if player:spellSlot(2).state == 0 then
                        player:castSpell("pos", 2, vec3(seg.endPos.x, targetE.y, seg.endPos.y))
                    end
                end
            end
        end
    end
    local targetQ = GetTargetQ();
    if targetQ and common.IsValidTarget(targetQ) then 
        if targetQ.buff['fiddlestickswdrain'] then return end
        if menu.harass.modeQ:get() == 1 then 
            if targetQ.buff[string.lower('fiddlesticksqcooldown')] then return end  
            if IsValidTargetInRage(targetQ, 575) then
                if player:spellSlot(0).state == 0 then
                    player:castSpell("obj", 0, targetQ)
                end
            end
        elseif menu.harass.modeQ:get() == 2 then 
            if IsValidTargetInRage(targetQ, 575) then
                if player:spellSlot(0).state == 0 then
                    player:castSpell("obj", 0, targetQ)
                end
            end
        end
    end
    local targetW = GetTargetW();
    if targetW and common.IsValidTarget(targetW) then 
        if #common.CountEnemiesInRange(player.pos, 650) >= 2 then 
            if IsValidTargetInRage(targetW, 600) then 
                if player:spellSlot(1).state == 0 then
                    player:castSpell("self", 1)
                end
            end
        end
        if menu.harass.w:get() == 2 then 
            if targetW.buff[string.lower('fiddlesticksqcooldown')] then
                if IsValidTargetInRage(targetW, 650) then 
                    if player:spellSlot(1).state == 0 then
                        player:castSpell("self", 1)
                    end
                end
            end
        elseif menu.harass.w:get() == 3 then 
            if IsValidTargetInRage(targetW, 650) then 
                if player:spellSlot(1).state == 0 then
                    player:castSpell("self", 1)
                end
            end
        end
    end
end

local function count_minions_in_range(pos, range)
	local enemies_in_range = {}
	for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
		local enemy = objManager.minions[TEAM_ENEMY][i]
		if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

local function LaneClear()
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if
            minion and minion.moveSpeed > 0 and minion.isTargetable and minion.pos:dist(player.pos) <= 575 and
                minion.path.count == 0 and
                not minion.isDead and
                common.IsValidTarget(minion)
         then
            local minionPos = vec3(minion.x, minion.y, minion.z)
            if minionPos then
                if menu.clear.q:get() then
                    player:castSpell("obj", 0, minion)
                end
            end 
        end
    end
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if
            minion and minion.moveSpeed > 0 and minion.isTargetable and minion.pos:dist(player.pos) <= 650 and
                minion.path.count == 0 and
                not minion.isDead and
                common.IsValidTarget(minion)
         then
            local minionPos = vec3(minion.x, minion.y, minion.z)
            if minionPos then
                if #count_minions_in_range(minionPos, 650) >= menu.clear.minW:get() then
                    player:castSpell("self", 1)
                end
            end
        end
    end
end

local function JungleClear()
    if menu.clear.jungle.q:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= 575 then
                    player:castSpell("obj", 0, minion)
                end
            end
        end
    end
    if menu.clear.jungle.w:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= 650 then
                    player:castSpell("self", 1)
                end
            end
        end
    end
    if menu.clear.jungle.e:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= 700 then
                    player:castSpell("pos", 2, minion.pos)
                end
            end
        end
    end
end

local function ontick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    for i, buff in pairs(player.buff) do
        if buff and buff.valid then 
            print(buff.name)
        end
    end
    if menu.misc.e:get() and player:spellSlot(2).state == 0 then 
        E_for_gabclose();
    end
    --[[local h = common.GetEnemyHeroes()
    for k, v in pairs(h) do --fiddlestickswdrain
        if v then
            for i, buff in pairs(v.buff) do
                if buff and buff.valid then 
                    print(buff.name)
                end
            end
        end
    end]]

    --Q Slow: fiddlesticksqcooldown
    --W Drawing: fiddlestickswdrain

    if orb.menu.combat:get() then
        if fuckW == true then return end
        if GetWNetworkID() then return end
        Combo();
    end

    if orb.menu.hybrid:get() then 
        if (player.mana / player.maxMana) * 100 >= menu.harass.Mana:get() then
            if fuckW == true then return end  
            if GetWNetworkID() then return end
            Harass();
        end
    end

    if (orb.menu.lane_clear:get()) then 
        if (player.mana / player.maxMana) * 100 >= menu.clear.Mana:get() then 
            if fuckW == true then return end
            if GetWNetworkID() then return end
            LaneClear();
        end
        if (player.mana / player.maxMana) * 100 >= menu.clear.jungle.Mana:get() then 
            if fuckW == true then return end
            if GetWNetworkID() then return end
            JungleClear();
        end
    end
end

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.ddd.qd:get()) then 
            graphics.draw_circle(player.pos, 575, 1, graphics.argb(255, 78, 171, 110), 100)
        end
        if (player:spellSlot(1).state == 0 and menu.ddd.wd:get()) then 
            graphics.draw_circle(player.pos, 650, 1, graphics.argb(255, 78, 171, 110), 100)
        end
        if (player:spellSlot(2).state == 0 and menu.ddd.ed:get()) then 
            graphics.draw_circle(player.pos, spellE.range, 1, graphics.argb(255, 78, 171, 110), 100)
        end
    end
end 

local function OnInterruptable(unit, spell)
    if spell.owner.team ~= TEAM_ALLY and menu.misc.inter[spell.name]:get() then 
        if unit and IsValidTargetInRage(unit, 1000) then 
            if player:spellSlot(0).state == 0 then 
                if unit.buff[string.lower('fiddlesticksqcooldown')] then return end  
                player:castSpell("obj", 0, unit)
            end
            if player:spellSlot(2).state == 0 then
                if IsValidTargetInRage(unit, spellE.range) then 
                    local seg = pred.linear.get_prediction(spellE, unit)
                    if seg and seg.startPos:dist(seg.endPos) < spellE.range then
                        if player:spellSlot(2).state == 0 then
                            player:castSpell("pos", 2, vec3(seg.endPos.x, unit.y, seg.endPos.y))
                        end
                    end
                end
            end
        end
    end
end

local function out_of_aa() 
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    if not orb.combat.is_active() then return end
    if not menu.combo.e:get() == 2 then return end
    local target = GetTargetE();
    if target and common.IsValidTarget(target) then 
        if player:spellSlot(2).state == 0 and IsValidTargetInRage(target, spellE.range) then 
            local seg = pred.linear.get_prediction(spellE, target)
            if seg and seg.startPos:dist(seg.endPos) < spellE.range then
                if player:spellSlot(2).state == 0 then
                    player:castSpell("pos", 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end
            end
        end
    end
end


cb.add(cb.draw, OnDraw)
Interrupter(OnInterruptable);

orb.combat.register_f_pre_tick(ontick);
orb.combat.register_f_out_of_range(out_of_aa);