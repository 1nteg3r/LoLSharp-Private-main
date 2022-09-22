local evade = module.seek("evade");
local preds = module.internal("pred");
local TS = module.internal("TS");
local orb = module.internal("orb");
local common = module.load("int", "Library/common");

local mana = 0;
local StartSpell = vec3(0,0,0);
local EndSpell = vec3(0,0,0);

local spellQ = {
	range = 850,
	delay = 0.75,
	speed = math.huge,
	radius = 170,
	boundingRadiusMod = 0
}

local spellW = {
	range = 750,
	radius = 150,
	speed = 3000,
	delay = 0.7,
	boundingRadiusMod = 0
}

local spellR = {
	range = 825,
	delay = 0.5,
	width = 100,
	speed = math.huge,
	boundingRadiusMod = 0
}

local IsW = { 
    LastCastTime = 0,
    LastEndPosition = vec3(0, 0, 0),
    LastSentTime = 0,
    LastStartPosition = vec3(0, 0, 0),
}

local IsQ = { 
    LastCastTime = 0,
    LastEndPosition = vec3(0, 0, 0),
    LastSentTime = 0,
    LastStartPosition = vec3(0, 0, 0),
}

local TargetSelectionQ = function(res, obj, dist) --Range default
	if dist < spellQ.range then
		res.obj = obj
		return true
	end
end

local TargetSelectionW = function(res, obj, dist) --Range default
	if dist < spellW.range then
		res.obj = obj
		return true
	end
end

local TargetSelectionE = function(res, obj, dist) --Range default
	if dist < 750 then
		res.obj = obj
		return true
	end
end

local TargetSelectionR = function(res, obj, dist) --Range default
	if dist < 850 then
		res.obj = obj
		return true
	end
end

local GetTargetQ = function()
	return TS.get_result(TargetSelectionQ).obj
end

local GetTargetW = function()
	return TS.get_result(TargetSelectionW).obj
end

local GetTargetE = function()
	return TS.get_result(TargetSelectionE).obj
end

local GetTargetR = function()
	return TS.get_result(TargetSelectionR).obj
end

local menu = menu("IntnnerCassiopeia", "Int Cassiopeia");
--subs menu
menu:header("xs", "Core");
menu:keybind("ClearKey", "LastHit E", nil, "L");
menu:keybind("AutoHarassKey", "AutoHarass", nil, "T");

menu:menu("combo", "Combo");
menu.combo:boolean("q", "Use Q", true);
menu.combo:boolean("w", "Use W", true);
menu.combo:dropdown('modeE', 'Use E', 2, {'Never', 'Is Poisoned', 'Always'});
menu.combo:header('exh', 'R Settings')
menu.combo:boolean("r", "Use R", true);
menu.combo:keybind("keySemi", "Semi - R", 'G', false);
    menu.combo.r:set('tooltip', "Logic 1vs1");
menu.combo:slider("min", "Use R if hit >= {0}", 2, 1, 5, 1);

menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("w", "Use W", true);
menu.harass:dropdown('modeW', 'Use E', 2, {'Never', 'Is Poisoned', 'Always'});
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 45, 1, 100, 1);

menu:menu("clear", "Clear");
menu.clear:slider("minQ", "Use Q if hit >= {0}", 3, 1, 5, 1);
menu.clear:slider("minW", "Use W if hit >= {0}", 5, 1, 10, 1);
menu.clear:dropdown('modeW', 'Use E', 2, {'Never', 'Is Poisoned', 'Always'});
menu.clear:slider("Mana", "Minimum Mana Percent >= {0}", 50, 1, 100, 1);
--Jungle
menu.clear:menu("jungle", "Jungle Clear");
menu.clear.jungle:boolean("q", "Use Q", true);
menu.clear.jungle:boolean("w", "Use W", true);
menu.clear.jungle:boolean("e", "Use E", true);
menu.clear.jungle:slider("Mana", "Minimum Mana Percent >= {0}", 20, 1, 100, 1);
--LastHit
menu.clear:menu("last", "LastHit");
menu.clear.last:boolean("e", "Use E", true);
menu.clear.last:slider("Mana", "Minimum Mana Percent >= {0}", 50, 1, 100, 1);

menu:menu("misc", "Misc");
menu.misc:boolean("r", "Use R At risky occasions", true);
menu.misc:menu("blacklist", "Blacklist -> R")
local enemy = common.GetEnemyHeroes()
for i, allies in ipairs(enemy) do
	menu.misc.blacklist:boolean(allies.charName, "Do not use in: " .. allies.charName, false)
end

menu:menu("ddd", "Display");
menu.ddd:boolean("qd", "Q Range", true);
menu.ddd:boolean("wd", "W Range", false);
menu.ddd:boolean("ed", "E Range", true);
menu.ddd:boolean("rd", "R Range", false);

local function IsFacing(target)
    if player.path.serverPos:distSqr(target.path.serverPos) > player.path.serverPos:distSqr(target.path.serverPos + target.direction) then
        return player.pos + (target.pos - player.pos):norm() * (80 * math.pi / 180)
    end
end
 
local function GetTimeTive(target, castdelay, speed)
    local r = 0;
    r = castdelay;
    if (speed ~= math.huge) then 
        r = (1000* player.pos:dist(target)/speed) 
    end
    return r 
end

local function InAARange(point, target)
    if (orb.combat.is_active()) then
        local targetpos = vec3(target.x, target.y, target.z)
        return point:dist(targetpos) <= common.GetAARange() + 100
    else
        return #common.CountEnemiesInRange(point, common.GetAARange()) > 0
    end
end

local function Rotated(v, angle)
	local c = math.cos(angle)
	local s = math.sin(angle)
	return vec3(v.x * c - v.z * s, 0, v.z * c + v.x * s)
end

local function CrossProduct(p1, p2)
	return (p2.z * p1.x - p2.x * p1.z)
end

local function UtimateRCone(Position)
    local range = spellR.range
	local angle = 80 * math.pi / 180
	local end2 = EndSpell - StartSpell
    local edge1 = Rotated(end2, -angle / 2)
	local edge2 = Rotated(edge1, angle)
	local point = Position - StartSpell
	if point:distSqr(vec3(0,0,0)) < range * range and CrossProduct(edge1, point) > 0 and CrossProduct(point, edge2) > 0 then
		return true
	end
    return false
end

local function IsPoisoned(target)
    local buff = (target.buff[string.lower('poisontrailtarget')] or target.buff[string.lower('TwitchDeadlyVenom')] or target.buff[string.lower('cassiopeiawpoison')] or target.buff[string.lower('cassiopeiaqdebuff')] or target.buff[string.lower('ToxicShotParticle')] or target.buff[string.lower('bantamtraptarget')]);
    if buff and buff.valid and buff.owner == target then 
        if buff.endTime > 0 and game.time <= buff.endTime then 
            if (buff.endTime >= GetTimeTive(target, 0.25, 1900) / 1000) then 
                return true, buff.startTime
            end 
        end
    end
    return false, 0
end

local function QDamage(target)
    local damage = 0
    if player:spellSlot(0).level > 0 then 
        local QLevelDamage = {75, 110, 145, 180, 215}
        damage = common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .9)), player)
    end 
    return damage
end

local function RDamage(target)
    local damage = 0
    if player:spellSlot(3).level > 0 then
        local RLevelDamage = {150, 250, 350}
        damage = common.CalculateMagicDamage(target, (RLevelDamage[player:spellSlot(3).level] + (common.GetTotalAP() * .5)), player)
    end
    return damage
end 

local function EDamage(target)
	local damage = 0
    if player:spellSlot(2).level > 0 then
        local ElvlDmgBonus = {10, 30, 50, 70, 90}
        local ElvlDamage = 4
		if IsPoisoned(target) then
			damage = CalcMagicDmg(target, (((52 + ElvlDamage * (player.levelRef - 1)) + (common.GetTotalAP() * .1)) + ElvlDmgBonus[player:spellSlot(2).level] +(common.GetTotalAP() * .6)))
		else
			damage = CalcMagicDmg(target, ((52 + ElvlDamage * (player.levelRef - 1)) + (common.GetTotalAP() * .1)))
		end
	end
	return damage - 5
end

local GetNumberOfHits = function(res, obj, dist)
	if dist > spellR.range then
		return
	end
	local target = GetTargetR()
	local aaa = preds.linear.get_prediction(spellR, obj)
	--if menu.combo.rset.facer:get() then
		if obj and IsFacing(obj) and UtimateRCone(obj) and target and target.pos:dist(obj.pos) < 350 and obj.pos:dist(vec3(aaa.endPos.x, mousePos.y, aaa.endPos.y)) < 350 and obj.pos:dist(player.pos) > 350 then
			res.num_hits = res.num_hits and res.num_hits + 1 or 1
		end
	--end
end

local GetPred = function()
	local res = TS.loop(GetNumberOfHits)
	if res.num_hits and res.num_hits > 1 then
		return res.num_hits
	end
end

function CalcMagicDmg(target, amount, from)
	local from = from or player
	local target = target or orb.combat.target
	local amount = amount or 0
	local targetMR = target.spellBlock * math.ceil(from.percentMagicPenetration) - from.flatMagicPenetration
	local dmgMul = 100 / (100 + targetMR)
	if dmgMul < 0 then
		dmgMul = 2 - (100 / (100 - magicResist))
	end
	amount = amount * dmgMul
	return math.floor(amount)
end

local function ValidUlt(unit)
	if (unit.buff[16] or unit.buff[15] or unit.buff[17] or unit.buff['kindredrnodeathbuff'] or unit.buff["sionpassivezombie"] or unit.buff[4]) then
		return false
	end
	return true
end
--[[local function GetSpellDamage(slot, target)
    if (target and common.IsValidTarget(target)) then 
        local damage = 0
        local slot = player:spellSlot(slot);
        if slot == 0 then 
            if player:spellSlot(0).level > 0 then 
                local QLevelDamage = {75, 110, 145, 180, 215}
                damage = common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .9)), player)
            end 
        end

        if slot == 3 then 
            if player:spellSlot(3).level > 0 then
                local RLevelDamage = {150, 250, 350}
                damage = common.CalculateMagicDamage(target, (RLevelDamage[player:spellSlot(3).level] + (common.GetTotalAP() * .5)), player)
            end
        end
        return damage
    end
end ]]

local function CastQ(target)
    if (player:spellSlot(0).state == 0 and target ~= nil) then
        if (IsPoisoned(target) and player:spellSlot(2).state == 0) then return end
        if (IsW.LastSentTime > 0) then
            local arrivalTime = GetTimeTive(IsW.LastEndPosition, 0.25, 3000);
            if (os.clock() - IsW.LastSentTime <= arrivalTime) then return end
            if (IsW.LastCastTime > 0 and os.clock() - IsW.LastCastTime <= arrivalTime) then return end
        end
        local pos = preds.circular.get_prediction(spellQ, target)
		if pos and pos.startPos:dist(pos.endPos) < spellQ.range  then
			player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
        end
    end
end

local function CastW(target)
    if (player:spellSlot(1).state == 0 and target ~= nil) then
        if (IsPoisoned(target) and player:spellSlot(2).state == 0) then return end
        if (IsQ.LastSentTime > 0) then
            local arrivalTime = GetTimeTive(IsQ.LastEndPosition, 0.4, math.huge);
            if (os.clock() - IsQ.LastSentTime <= arrivalTime) then return end
            if (IsQ.LastCastTime > 0 and os.clock() - IsQ.LastCastTime <= arrivalTime) then return end
        end
        local pos = preds.circular.get_prediction(spellW, target)
		if pos and pos.startPos:dist(pos.endPos) < spellW.range then
			player:castSpell("pos", 1, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
        end
    end
end

local function CastE(target)
    if (player:spellSlot(2).state == 0 and target) then 
        local canCast = true;
        if (not IsPoisoned(target)) then
            canCast = false;
            local timeToArriveE = GetTimeTive(target, 0.125, 1900);
            local timeToArriveW = GetTimeTive(target, 0.25, 3000) - (os.clock() - IsW.LastCastTime);
            local timeToArriveQ = GetTimeTive(target, 0.4, math.huge) - (os.clock() - IsQ.LastCastTime);
            if (timeToArriveW >= 0) then
                if (timeToArriveE >= timeToArriveW) then
                    local pos = preds.circular.get_prediction(spellW, target)
                    if pos and pos.startPos:dist(pos.endPos) < spellW.range and IsW.LastEndPosition:dist(IsW.LastEndPosition) <= target.boundingRadius / 2 + spellW.radius then
                        canCast = true;
                    end
                end
            end
            if (timeToArriveQ >= 0) then 
                if (timeToArriveE >= timeToArriveQ) then 
                    local pos = preds.circular.get_prediction(spellQ, target)
                    if pos and pos.startPos:dist(pos.endPos) < spellQ.range and IsQ.LastEndPosition:dist(IsQ.LastEndPosition) <= target.boundingRadius / 2 + spellQ.radius then
                        canCast = true;
                    end
                end
            end
        end
        if (canCast) then
            player:castSpell("obj", 2, target)
        end
    end
end

local function CastR(target)
    if (player:spellSlot(3).state == 0 and target) then
        if not common.IsValidTarget(target) then
            return
        end
        if EDamage(target) * 3 + QDamage(target) >= target.health then return end 
        if target and (target.health / target.maxHealth) * 100 <= 60 then 
            if menu.misc.blacklist[target.charName] and not menu.misc.blacklist[target.charName]:get() then
                local pos = preds.linear.get_prediction(spellR, target)
                if pos and pos.startPos:dist(pos.endPos) < spellR.range and #common.CountEnemiesInRange(player.pos, 900) == 1 then
                    if (IsFacing(target) and UtimateRCone(target)) then
                        player:castSpell("pos", 3, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
                    end
                end 
            end
        end
        if target and target.health < EDamage(target) * 3 + RDamage(target) + QDamage(target) then 
            if menu.misc.blacklist[target.charName] and not menu.misc.blacklist[target.charName]:get() then
                local pos = preds.linear.get_prediction(spellR, target)
                if pos and pos.startPos:dist(pos.endPos) < spellR.range and #common.CountEnemiesInRange(player.pos, 900) == 1 then
                    if (IsFacing(target) and UtimateRCone(target)) then
                        player:castSpell("pos", 3, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
                    end
                end 
            end
        end
        if GetPred() and GetPred() >= menu.combo.min:get() then
            local pos = preds.linear.get_prediction(spellR, target)
            if pos and pos.startPos:dist(pos.endPos) < spellR.range then
                player:castSpell("pos", 3, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
            end
        end
    end
end

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.ddd.qd:get()) then 
            graphics.draw_circle(player.pos, spellQ.range, 1, graphics.argb(255, 78, 171, 110), 30)
        end
        if (player:spellSlot(1).state == 0 and menu.ddd.wd:get()) then 
            graphics.draw_circle(player.pos, spellW.range, 1, graphics.argb(255, 78, 171, 110), 30)
        end
        if (player:spellSlot(2).state == 0 and menu.ddd.ed:get()) then 
            graphics.draw_circle(player.pos, 750, 1, graphics.argb(255, 78, 171, 110), 30)
        end
        if (player:spellSlot(3).state == 0 and menu.ddd.rd:get()) then 
            graphics.draw_circle(player.pos, spellR.range, 1, graphics.argb(255, 78, 171, 110), 30)
        end
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.AutoHarassKey:get() == true then
			graphics.draw_text_2D("AutoHarass: On", 18, pos.x - 30, pos.y + 30, graphics.argb(255,90, 178, 74))
		else
			graphics.draw_text_2D("AutoHarass: Off", 18, pos.x - 30, pos.y + 30, graphics.argb(255, 90, 178, 74))
        end
        
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.ClearKey:get() == true then
			graphics.draw_text_2D("LastHit E: On", 18, pos.x - 30, pos.y + 50, graphics.argb(255,90, 178, 74))
		else
			graphics.draw_text_2D("LastHit E: Off", 18, pos.x - 30, pos.y + 50, graphics.argb(255, 90, 178, 74))
		end
    end
end 

local function PermaActive()
    local Range = spellQ.range + spellQ.radius;
    local target = TS.get_result(function(res, obj, dist)
        if dist <= Range and common.IsValidTarget(obj)  then --add invulnverabilty check
            res.obj = obj
            return true
        end
    end).obj

    if orb.menu.combat:get() then 
        if target and InAARange(player.pos, target) and mana >= player.manaCost2 and (player:spellSlot(2).state == 0 or  player:spellSlot(2).cooldown < 1) and IsPoisoned(target) then
            orb.core.set_pause_attack(math.huge);
        else 
            orb.core.set_pause_attack(0)
        end
    end
end

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
	for i, target in ipairs(enemy) do
        if target and common.IsValidTarget(target) and ValidUlt(target) then 
            local hp = common.GetShieldedHealth("ap", target)
            if (target.path.serverPos2D:dist(player.path.serverPos2D) < spellQ.range) then 
                if (QDamage(target) >= hp) then 
                    CastQ(target);
                end
            end 

            if (target.path.serverPos2D:dist(player.path.serverPos2D) < 750) then 
                if (EDamage(target) >= hp) then 
                    CastE(target);
                end
            end 
        end 
    end
end

local function LastHitE()
    if menu.clear.last.e:get() then
		for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
			local minion = objManager.minions[TEAM_ENEMY][i]
			if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and minion.pos:dist(player.pos) < 750 then
				--delay = player.pos:dist(minion.pos) / 3500 + 0.2
				local delay = 70 / 1000 + player.pos:dist(minion.pos) / 840;
				if (EDamage(minion) >= orb.farm.predict_hp(minion, delay / 2, true) - 150 and mana > player.manaCost2) then
					orb.core.set_pause_attack(1)
				end
				if (EDamage(minion) >= orb.farm.predict_hp(minion, delay / 2, true)) then
					player:castSpell("obj", 2, minion)
				end
			end
		end
	end
end

local function AutoHarassQ()
    local target = TS.get_result(function(res, obj, dist)
        if dist <= spellQ.range and common.IsValidTarget(obj)  then --add invulnverabilty check
            res.obj = obj
            return true
        end
    end).obj

    if (target and common.IsValidTarget(target)) then 
        CastQ(target);
    end
end

local function Combo()
    local targetE = GetTargetE();
    if targetE and common.IsValidTarget(targetE) then 
        --
        if (player.levelRef == 1 and player:spellSlot(2).state == 0) then 
            player:castSpell("obj", 2, targetE)
        end

        if (menu.combo.modeE:get() == 2) then
            CastE(targetE)
        elseif menu.combo.modeE:get() == 3 then 
            player:castSpell("obj", 2, targetE)
        end
    end
    if menu.combo.q:get() then
        local targetQ = GetTargetQ();
        if targetQ and common.IsValidTarget(targetQ) then 
            CastQ(targetQ)
        end
    end

    if menu.combo.w:get() then
        local targetW = GetTargetW();
        if targetW and common.IsValidTarget(targetW) then 
            CastW(targetW)
        end
    end

    if menu.combo.r:get() then
        local targetR = GetTargetR();
        if targetR and common.IsValidTarget(targetR) then 
            CastR(targetR)
        end
    end
end

local function Harass()
    local targetE = GetTargetE();
    if targetE and common.IsValidTarget(targetE) then 
        --
        if (player.levelRef == 1 and player:spellSlot(2).state == 0) then 
            player:castSpell("obj", 2, targetE)
        end

        if (menu.harass.modeW:get() == 2) then
            CastE(targetE)
        elseif menu.harass.modeW:get() == 3 then 
            player:castSpell("obj", 2, targetE)
        end
    end
    if menu.harass.q:get() then
        local targetQ = GetTargetQ();
        if targetQ and common.IsValidTarget(targetQ) then 
            CastQ(targetQ)
        end
    end

    if menu.harass.w:get() then
        local targetW = GetTargetW();
        if targetW and common.IsValidTarget(targetW) then 
            CastW(targetW)
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
    --if menu.clear.q:get() then
        local minions = objManager.minions
        for a = 0, minions.size[TEAM_ENEMY] - 1 do
            local minion1 = minions[TEAM_ENEMY][a]
            if
                minion1 and minion1.moveSpeed > 0 and minion1.isTargetable and not minion1.isDead and minion1.isVisible and
                    player.path.serverPos:distSqr(minion1.path.serverPos) <= (spellQ.range * spellQ.range)
             then
                local count = 0
                for b = 0, minions.size[TEAM_ENEMY] - 1 do
                    local minion2 = minions[TEAM_ENEMY][b]
                    if
                        minion2 and minion2.moveSpeed > 0 and minion2.isTargetable and minion2 ~= minion1 and not minion2.isDead and
                            minion2.isVisible and
                            minion2.path.serverPos:distSqr(minion1.path.serverPos) <= (spellQ.radius * spellQ.radius)
                     then
                        count = count + 1
                    end
                    if count >= menu.clear.minQ:get() then
                        local seg = preds.circular.get_prediction(spellQ, minion1)
                        if seg and seg.startPos:dist(seg.endPos) < spellQ.range then
                            player:castSpell("pos", 0, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
                            --orb.core.set_server_pause()
                            break
                        end
                    end
                end
            end
        end
        for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if
                minion and minion.moveSpeed > 0 and minion.isTargetable and minion.pos:dist(player.pos) <= spellQ.range and
                    minion.path.count == 0 and
                    not minion.isDead and
                    common.IsValidTarget(minion)
             then
                local minionPos = vec3(minion.x, minion.y, minion.z)
                if minionPos then
                    if #count_minions_in_range(minionPos, 150) >= menu.clear.minW:get() then
                        local seg = preds.circular.get_prediction(spellQ, minion)
                        if seg and seg.startPos:dist(seg.endPos) < spellQ.range then
                            player:castSpell("pos", 1, vec3(seg.endPos.x, minionPos.y, seg.endPos.y))
                        end
                    end
                end
            end
        end
    --end
end

local function JungleClear()
    if menu.clear.jungle.q:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= spellQ.range then
                    local pos = preds.circular.get_prediction(spellQ, minion)
                    if pos and pos.startPos:dist(pos.endPos) < spellQ.range then
                        player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
                    end
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
                if minion.pos:dist(player.pos) <= spellW.range then
                    local pos = preds.circular.get_prediction(spellW, minion)
                    if pos and pos.startPos:dist(pos.endPos) < spellW.range then
                        player:castSpell("pos", 1, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
                    end
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
                    player:castSpell("obj", 2, minion)
                end
            end
        end
    end
end

local function OnTick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    if player.mana > player.maxMana then
		mana = player.maxMana
	else
		mana = player.mana
    end

    if (player:spellSlot(0).state ~= 0) then 
        IsQ.LastCastTime = 0
        IsQ.LastEndPosition = vec3(0,0,0)
        IsQ.LastSentTime = 0
    end

    if (player:spellSlot(1).state ~= 0) then 
        IsW.LastCastTime = 0
        IsW.LastEndPosition = vec3(0,0,0)
        IsW.LastSentTime = 0
    end
    
    PermaActive();
    KillSteal();

    if (menu.ClearKey:get() == true or orb.menu.last_hit:get()) then 
        if orb.menu.combat:get() or orb.menu.hybrid:get() then return end
        LastHitE();
    end

    if (menu.AutoHarassKey:get() == true) then 
        if orb.menu.combat:get() then return end
        if (player.mana / player.maxMana) * 100 <= menu.harass.Mana:get() then return end
        AutoHarassQ();
    end
end 

local function OnProcessSpellCast(spell)
    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Cassiopeia" then 
        if spell.name == "CassiopeiaW" then 
            IsW.LastCastTime = os.clock();
            IsW.LastEndPosition = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z);
        end

        if spell.name == "CassiopeiaQ" then 
            IsQ.LastCastTime = os.clock();
            IsQ.LastEndPosition = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z);
        end

        if (player:spellSlot(3).state == 0) then 
            StartSpell = vec3(spell.startPos.x, spell.startPos.y, spell.startPos.z); --Start Pos
            EndSpell = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z) 
        end
    end
end 

local function OnSpellCastSpell(slot, startpos, endpos, nid)
    if slot == 0 then 
        IsQ.LastSentTime = os.clock();
        IsQ.LastEndPosition = vec3(endpos.x, endpos.y, endpos.z);
    end

    if slot == 1  then 
        IsW.LastSentTime = os.clock();
        IsW.LastEndPosition = vec3(endpos.x, endpos.y, endpos.z);
    end
end

local function OnCombat()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    if (orb.menu.combat:get()) then
        Combo()
    end

    if menu.combo.keySemi:get() then 
        player:move(mousePos)
        local target = GetTargetR();
        if target and common.IsValidTarget(target) then 
            local pos = preds.linear.get_prediction(spellR, target)
            if pos and pos.startPos:dist(pos.endPos) < spellR.range then
                player:castSpell("pos", 3, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
            end
        end
    end

    if orb.menu.hybrid:get() then 
        if (player.mana / player.maxMana) * 100 >= menu.harass.Mana:get() then  
            Harass();
        end
    end
    if (orb.menu.lane_clear:get()) then 
        if (player.mana / player.maxMana) * 100 >= menu.clear.Mana:get() then 
            LaneClear();
        end
        if (player.mana / player.maxMana) * 100 >= menu.clear.jungle.Mana:get() then 
            JungleClear();
        end
    end
end

orb.combat.register_f_pre_tick(OnCombat)

cb.add(cb.draw, OnDraw)
cb.add(cb.tick, OnTick)
cb.add(cb.spell, OnProcessSpellCast)
cb.add(cb.castspell, OnSpellCastSpell)
