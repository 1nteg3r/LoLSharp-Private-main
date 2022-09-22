local orb = module.internal("orb");
local pred = module.internal("pred");
local ts = module.internal('TS');
local dlib = module.load(header.id, 'damageLib');
local common = module.load(header.id, 'common');
local evade = module.seek("evade");

local MissFortuneBulletTime = 0;
local MissFortuneBulletParticle = false;
local lastDebugPrint = 0;

local StartSpell = vec3(0,0,0);
local EndSpell = vec3(0,0,0);

local spellE = {
	range = 1100,
	radius = 150,
	speed = 500,
	delay = 0.25,
	boundingRadiusMod = 1
}

local TargetSelectionQ = function(res, obj, dist) --Range default
	if dist < 650 then
		res.obj = obj
		return true
	end
end

local GetTargetQ = function()
	return ts.get_result(TargetSelectionQ).obj
end

local TargetSelectionQ2 = function(res, obj, dist) --Range default
	if dist < 1300 then
		res.obj = obj
		return true
	end
end

local GetTargetQ2 = function()
	return ts.get_result(TargetSelectionQ2).obj
end

local TargetSelectionE = function(res, obj, dist) --Range default
	if dist < 1000 then
		res.obj = obj
		return true
	end
end

local GetTargetE = function()
	return ts.get_result(TargetSelectionE).obj
end


local menu = menu("intnnerMissfortune", "Marksman - MissFortune");
menu:header("xs", "Core");
menu:menu("combo", "Combo");
menu.combo:boolean("q", "Use Q", true);
menu.combo:boolean("q2", "Use Double Shot!", true);
menu.combo:dropdown('modeW', 'Use W', 1, {'After Attack', 'Never'});
menu.combo:boolean("e", "Use E", true);
menu.combo:header('exh', 'R Settings')
menu.combo:boolean("r", "Use R", true);
menu.combo:boolean("r", "Use R AOE", false);
menu.combo:slider("min", "^ AOE R if hit >= {0}", 3, 1, 5, 1);

menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("w", "Use W", false);
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 45, 1, 100, 1);

menu:menu("clear", "Lane/Jungle");
menu.clear:boolean("q", "Use Q", true);
menu.clear:boolean("2q", "Use Q LastHit", true);
menu.clear:boolean("w", "Use W", true);
--menu.clear:dropdown('modeW', 'Use E', 1, {'Never', 'Kill', 'Always'});
menu.clear:slider("Mana", "Minimum Mana Percent >= {0}", 50, 1, 100, 1);

menu:menu("misc", "Misc");
menu.misc:boolean("e", "Use E gapclose", true);

menu:menu("ddd", "Display");
menu.ddd:boolean("qd", "Q Range", false);
menu.ddd:boolean("wd", "W Range", false);
menu.ddd:boolean("ed", "E Range", true);
menu.ddd:boolean("rd", "R Range", false);


local function IsINSIDE_TAMGIAC(target, source, pos1, pos2)
	local fAB = (source.z - target.z)*(pos1.x - target.x) - (source.x - target.x)*(pos1.z - target.z)
	local fBC = (source.z - pos1.z)*(pos2.x - pos1.x) - (source.x - pos1.x)*(pos2.z - pos1.z)
	local fCA = (source.z - pos2.z)*(target.x - pos2.x) - (source.x - pos2.x)*(target.z - pos2.z)
    if ((fAB*fBC > 0) and (fBC*fCA > 0)) then 
        return true 
    end
    return false
end

local function CircleCircleIntersectionS(a1, a2, R1, R2)
	local C1 = vec3(a1.x, 0, a1.z)
    local C2 = vec3(a2.x, 0, a2.z)
    local D = common.GetDistance(C1, C2)
    local A = (R1 * R1 - R2 * R2 + D * D ) / (2 * D)
    local H = math.sqrt(R1 * R1 - A * A);
    local Direction = (C2 - C1):norm()
    local PA = C1 + A * Direction

    local S1 = PA + H * Direction:perp1()
    local S2 = PA - H * Direction:perp1()

    return S1, S2
end
--
local function Rotated(v, angle)
	local c = math.cos(angle)
	local s = math.sin(angle)
	return vec3(v.x * c - v.z * s, 0, v.z * c + v.x * s)
end

local function CrossProduct(p1, p2)
	return (p2.z * p1.x - p2.x * p1.z)
end
--
local function Qcone(Position, finishPos, firstPos)
	local range = 475
	local angle = 40 * math.pi / 180
	local end2 = finishPos - firstPos
	local edge1 = Rotated(end2, -angle / 2)
	local edge2 = Rotated(edge1, angle)

	local point = Position - firstPos
	if common.GetDistanceSqr(point, vec3(0,0,0)) < range * range and CrossProduct(edge1, point) > 0 and CrossProduct(point, edge2) > 0 then
		return true
	end
	return false
end 

local function MissRCone(Position)
    if MissFortuneBulletParticle == false then return end
    local range = 1300
	local angle = 60 * math.pi / 180
	local end2 = EndSpell - StartSpell
    local edge1 = Rotated(end2, -angle / 2)
	local edge2 = Rotated(edge1, angle)
	local point = Position - StartSpell
	if point:distSqr(vec3(0,0,0)) < range * range and CrossProduct(edge1, point) > 0 and CrossProduct(point, edge2) > 0 then
		return true
	end
    return false
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

local fuck = 0
local function CreateObj(obj)
    --if obj and obj.name and obj.name:lower():find("missfortune") then print("Created "..obj.name) end

    if obj then
        if obj.name:find("R_Indicator") or obj.name:find("R_cas") or obj.name:find("R_mis") then
            MissFortuneBulletParticle = true
            fuck = os.clock() + 0.5
        end 
    end
    --MissFortune_Base_R_mis
end 

local function DeleteObj(obj)
    if obj then
        MissFortuneBulletParticle = false
    end
end


local function DoubleShot()
    local target = GetTargetQ2()
    if IsValidTargetInRage(target, 1300) then
        if target and common.IsValidTarget(target) then
            local myHeroPos = vec3(player.x, player.y, player.z)
            local targetpos = vec3(target.x, target.y, target.z)
            local posExtQ = targetpos + (myHeroPos - targetpos):norm() * -400
            local p1, p2 = CircleCircleIntersectionS(target, posExtQ, 450, 225)
            if p1 and p2 then
                for i = 0,  objManager.minions.size[TEAM_ENEMY] - 1 do
                    local minion =  objManager.minions[TEAM_ENEMY][i]
                    if minion and common.IsValidTarget(minion) then
                        if IsValidTargetInRage(minion, 1300) then
                            local minionPos = vec3(minion.x, minion.y, minion.z)
                            local posExt = minionPos + (myHeroPos - minionPos):norm() * -400
                            if IsINSIDE_TAMGIAC(minionPos, targetpos, p1, p2) then
                                if minionPos:dist(player.pos) > 150 and minionPos:dist(player.pos) <= 650 and minionPos:dist(targetpos) < 435 then
                                    if Qcone(targetpos, posExt, minionPos) then 
                                        player:castSpell("obj", 0, minion)
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

local function Harass()
    if MissFortuneBulletParticle then return end
    local target_Q1 = GetTargetQ()

    if menu.harass.w:get() and target_Q1 and common.IsValidTarget(target_Q1) then
        if IsValidTargetInRage(target_Q1, common.GetAARange()) then 
            player:castSpell("self", 1)
        end 
    end

    if not menu.combo.q:get() then return end
    if player:spellSlot(0).state ~= 0 then return end

    if target_Q1 and common.IsValidTarget(target_Q1) then
        local qDmg = dlib.GetSpellDamage(0, target_Q1)
        if qDmg + common.CalculateAADamage(target_Q1) > target_Q1.health then
            player:castSpell("obj", 0, target_Q1)
        elseif qDmg + common.CalculateAADamage(target_Q1) * 3 > target_Q1.health  then
            player:castSpell("obj", 0, target_Q1)
        elseif IsValidTargetInRage(target_Q1, common.GetAARange()) then 
            player:castSpell("obj", 0, target_Q1)
        end 
    end 
    DoubleShot()
end 

local function LaneClear()
    local TargetQ2 = GetTargetQ2()
    if TargetQ2 and common.IsValidTarget(TargetQ2) and IsValidTargetInRage(TargetQ2, 1300) then
        if TargetQ2 and common.IsValidTarget(TargetQ2) then
            local myHeroPos = vec3(player.x, player.y, player.z)
            local targetpos = vec3(TargetQ2.x, TargetQ2.y, TargetQ2.z)
            local posExtQ = targetpos + (myHeroPos - targetpos):norm() * -400
            local p1, p2 = CircleCircleIntersectionS(TargetQ2, posExtQ, 450, 225)
            if p1 and p2 then
                for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
                    local minion = objManager.minions[TEAM_ENEMY][i]
                    if minion and common.IsValidTarget(minion) and IsValidTargetInRage(minion, 1300) then
                        if IsValidTargetInRage(minion, 1300) and dlib.GetSpellDamage(0, minion) > minion.health then
                            local minionPos = vec3(minion.x, minion.y, minion.z)
                            local posExt = minionPos + (myHeroPos - minionPos):norm() * -400
                            if IsINSIDE_TAMGIAC(minionPos, targetpos, p1, p2) then
                                if Qcone(targetpos, posExt, minionPos) and minionPos:dist(player.pos) > 150 and minionPos:dist(player.pos) <=  650 and minionPos:dist(targetpos) < 435 then
                                    player:castSpell("obj", 0, minion)
                                end
                            end
                        elseif IsValidTargetInRage(minion, 1300) then
                            local minionPos = vec3(minion.x, minion.y, minion.z)
                            local posExt = minionPos + (myHeroPos - minionPos):norm() * -400
                            if IsINSIDE_TAMGIAC(minionPos, targetpos, p1, p2) then
                                if Qcone(targetpos, posExt, minionPos) and minionPos:dist(player.pos) > 150 and minionPos:dist(player.pos) <= 650 and minionPos:dist(targetpos) < 435 then
                                    player:castSpell("obj", 0, minion)
                                end
                            end
                        end
                    end
                end
            end 
        end
    end
end 

local function JungleClear()
    if menu.clear.q:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= 650 then
                    player:castSpell("obj", 0, minion)
                end
            end
        end
    end
    if menu.clear.w:get() then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                    minion.type == TYPE_MINION
             then
                if minion.pos:dist(player.pos) <= common.GetAARange() then
                    player:castSpell("self", 1)
                end
            end
        end
    end
end

local function ontick()
    if (player.isDead) then return end 

    
    if menu.combo.q2:get() then 
        if orb.combat.is_active() or orb.menu.lane_clear:get() then 
            if player:spellSlot(0).state == 0 then 
                if menu.combo.q2:get() then 
                    if not MissFortuneBulletParticle then
                        DoubleShot();
                    end
                end
            end
        end
    end


    if menu.combo.r:get() then 
        if orb.combat.is_active() then 
            if common.UnderDangerousTower(player.pos) then
                return
            end
            local targetR = GetTargetQ()
            if common.IsValidTarget(targetR) and targetR then
                if ValidUlt(targetR) and player:spellSlot(3).state == 0 then
                    local rDmg = dlib.GetSpellDamage(3, targetR)
                    if #common.CountEnemiesInRange(player.pos, 800) < 2 then
                        local tDis = common.GetDistance(targetR)
                        if (rDmg * 7 > targetR.health and tDis < 800) then
                            player:castSpell("pos", 3, targetR.pos)
                            MissFortuneBulletTime = os.clock();
                        elseif (rDmg * 6 > targetR.health and tDis < 900) then
                            player:castSpell("pos", 3, targetR.pos)
                            MissFortuneBulletTime = os.clock();
                        elseif (rDmg * 5 > targetR.health and tDis < 1000) then
                            player:castSpell("pos", 3, targetR.pos)
                            MissFortuneBulletTime = os.clock();
                        elseif (rDmg * 4 > targetR.health and tDis < 1100) then
                            player:castSpell("pos", 3, targetR.pos)
                            MissFortuneBulletTime = os.clock();
                        elseif (rDmg * 3 > targetR.health and tDis < 1200) then
                            player:castSpell("pos", 3, targetR.pos)
                            MissFortuneBulletTime = os.clock();
                        elseif (rDmg > targetR.health and tDis < 1300) then
                            player:castSpell("pos", 3, targetR.pos)
                            MissFortuneBulletTime = os.clock();
                        end
                    end
                    if (rDmg * 8 > targetR.health and rDmg * 2 < targetR.health and #common.CountEnemiesInRange(player.pos, 300) == 0) then
                        player:castSpell("pos", 2, targetR.pos)
                        MissFortuneBulletTime = os.clock();
                    end
                end
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
            JungleClear();
        end
    end


    if menu.misc.e:get() then 
        if player:spellSlot(2).state == 0 then 
            local target =
		ts.get_result(
		function(res, obj, dist)
			if dist <= 1100 and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
				res.obj = obj

				return true
			end
		end
	).obj
	if target then
		local pred_pos = pred.core.lerp(target.path, network.latency + 0.25, target.path.dashSpeed)
		if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 1100 then

				player:castSpell("pos", 2, vec3(pred_pos.x, target.y, pred_pos.y))
			
		end
	end
        end

    end
end

local function AfterAA_W()
    if not orb.combat.is_active() then return end 
    if player:spellSlot(1).state ~= 0 then return end
    if MissFortuneBulletParticle then return end
    local target_Q1 = GetTargetQ()

    if target_Q1 and common.IsValidTarget(target_Q1) then
        if IsValidTargetInRage(target_Q1, common.GetAARange()) then 
            player:castSpell("self", 1)
        end 
    end
end

local function AffterAA()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    if menu.combo.modeW:get() == 1 then
        AfterAA_W();
    end
    if not orb.combat.is_active() then return end 
    if not menu.combo.q:get() then return end
    if player:spellSlot(0).state ~= 0 then return end
    if MissFortuneBulletParticle then return end
    local target_Q1 = GetTargetQ()

    if target_Q1 and common.IsValidTarget(target_Q1) then
        local qDmg = dlib.GetSpellDamage(1, target_Q1)
        if qDmg + common.CalculateAADamage(target_Q1) > target_Q1.health then
            player:castSpell("obj", 0, target_Q1)
        elseif qDmg + common.CalculateAADamage(target_Q1) * 3 > target_Q1.health  then
            player:castSpell("obj", 0, target_Q1)
        elseif IsValidTargetInRage(target_Q1, common.GetAARange()) then 
            player:castSpell("obj", 0, target_Q1)
        end 
    end 
end 

local function out_of_aa() 
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    if not orb.combat.is_active() then return end
    if MissFortuneBulletParticle then return end
    local target = GetTargetE();
    if target and common.IsValidTarget(target) then 
        if player:spellSlot(2).state == 0 and IsValidTargetInRage(target, 1200) then 
            local pos = pred.circular.get_prediction(spellE, target)
            if pos and pos.startPos:dist(pos.endPos) < spellE.range then
                if menu.combo.e:get() then
                    player:castSpell("pos", 2, vec3(pos.endPos.x, target.y, pos.endPos.y))
                end
            end
        end
    end
end

local function OnProcessSpellCast(spell) 
    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "MissFortune" then 
        --print(spell.name)
        if spell.name == "MissFortuneBulletTime" then 
            MissFortuneBulletTime = os.clock(); 
            StartSpell = vec3(spell.startPos.x, spell.startPos.y, spell.startPos.z); --Start Pos
            EndSpell = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z) --EndPos spell
        end 
    end

    --[[if(spell.owner == player) then
        if os.clock() - lastDebugPrint >= 2 then
            print("Spell name: " ..spell.name);
            print("Speed:" ..spell.static.missileSpeed);
            print("Width: " ..spell.static.lineWidth);
            print("Time:" ..spell.windUpTime);
            print("Animation: " ..spell.animationTime);
            print(spell.isBasicAttack);
            print("CastFrame: " ..spell.clientWindUpTime);
            print('--------------------------------------');
            lastDebugPrint = os.clock();
        end
    end]]
end

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.ddd.qd:get()) then 
            graphics.draw_circle(player.pos, 625, 1, graphics.argb(255, 78, 171, 110), 100)
        end
        if (player:spellSlot(1).state == 0 and menu.ddd.wd:get()) then 
            graphics.draw_circle(player.pos, 650, 1, graphics.argb(255, 78, 171, 110), 100)
        end
        if (player:spellSlot(2).state == 0 and menu.ddd.ed:get()) then 
            graphics.draw_circle(player.pos, 1000, 1, graphics.argb(255, 78, 171, 110), 100)
        end
        if (player:spellSlot(3).state == 0 and menu.ddd.rd:get()) then 
            graphics.draw_circle(player.pos, 1300, 1, graphics.argb(255, 78, 171, 110), 100)
        end
    end
end 

cb.add(cb.spell, OnProcessSpellCast);
cb.add(cb.create_particle, CreateObj);
cb.add(cb.delete_particle, DeleteObj);
cb.add(cb.draw, OnDraw)
cb.add(cb.tick, ontick)
orb.combat.register_f_after_attack(AffterAA);
orb.combat.register_f_out_of_range(out_of_aa);