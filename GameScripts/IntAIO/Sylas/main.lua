local common = module.load('int', 'Library/common');
local dlib = module.load('int', 'Library/damageLib');
local database = module.load("int", "Core/Sylas/SpellDatabase");
local GeomLib = module.load(header.id, "Geometry/GeometryLib")
local Vector = GeomLib.Vector 
local TS = module.internal('TS');
local pred = module.internal("pred");

local orb = module.internal("orb");
local str = {[-1] = "P", [0] = "Q", [1] = "W", [2] = "E", [3] = "R"}
local last_execute = 0

local spellQ = {
    range = 725;
    delay = 0.4; 
    width = 70;
    speed = 1800;
    boundingRadiusMod = 1; 
}

local spellE = {
    range = 800;
    delay = 0.25; 
    width = 60;
    speed = 1600;
    boundingRadiusMod = 0; 
    collision = {
		hero = false,
		minion = true,
		wall = true
	}
}

local spellRA = {
    delay = math.huge;
    width = math.huge;
    speed = math.huge;
    boundingRadiusMod = 0; 
    collision = {
		hero = false,
		minion = false,
		wall = true
	}
}

local spellR = {
    range = 950
}

local TargetSelectionQ = function(res, obj, dist) --Range default
	if dist < spellQ.range then
		res.obj = obj
		return true
	end
end

local GetTargetQ = function()
	return TS.get_result(TargetSelectionQ).obj
end

local TargetSelectionw = function(res, obj, dist) --Range default
	if dist < 400 then
		res.obj = obj
		return true
	end
end

local GetTargetW = function()
	return TS.get_result(TargetSelectionw).obj
end

local TargetSelectione = function(res, obj, dist) --Range default
	if dist < spellE.range then
		res.obj = obj
		return true
	end
end

local GetTargetE = function()
	return TS.get_result(TargetSelectione).obj
end


local TargetSelectionR = function(res, obj, dist) --Range default
	if dist < spellR.range then
		res.obj = obj
		return true
	end
end

local GetTargetR = function()
	return TS.get_result(TargetSelectionR).obj
end

local TargetSelectionR2 = function(res, obj, dist) --Range default
	if dist < 3500 then
		res.obj = obj
		return true
	end
end

local GetTargetR2 = function()
	return TS.get_result(TargetSelectionR2).obj
end

local function DivideCircleInPoints(basePos, radius, sides)
    basePos = basePos or myHero.position
    sides = sides or 12
    local retT = {}
    for angle = 0, 180, sides do
        local base_dir = GeomLib.Vector(1, 0, 1):normalized()
        local bp_v = GeomLib.Vector(basePos)
        base_dir:rotateYaxis(angle)
        local pos = bp_v + base_dir *  (radius)
        retT[#retT+1] = pos 
    end
    return retT
end

local menu = menu("intsssSylas", "Int Sylas")
menu:header("comewewebo", "Core")
menu:menu("combo", "Combo")
menu.combo:boolean("q", "Use Q", true);
menu.combo:dropdown('w', 'Use W', 2, {'Healing', 'Always'});
menu.combo:header("dsda", "-- W Healing --")
menu.combo:slider("healthW", "Min. Health <", 75, 1, 100, 1);
menu.combo:boolean("e", "Use E", true);
menu.combo:header("uhhfffffh", "R Settings")
menu.combo:boolean("r", "Use R", true);
menu.combo:dropdown('r2', '^ Use R when: ', 2, {'Always', 'Kill'});
menu.combo:slider("rangetotal", "Max Range ults (SkillShots) {0}", 5000, 1, 25000, 1);
menu.combo:header("uhhh", "-- Spells Targets --")
for _, i in pairs(database) do
	for l, k in pairs(common.GetEnemyHeroes()) do
		-- k = myHero
		if not database[_] then
			return
		end
		if i.charName == k.charName then
			if i.displayname == "" then
				i.displayname = _
			end
			if i.danger == 0 then
				i.danger = 1
			end

			if (i.type == "circular" or i.type == "linear" or i.type == "conic" or i.type == "cross" or i.type == "Ptarget")  and (i.slot == 3) then
				if (menu.combo[i.charName] == nil) then
					menu.combo:menu(i.charName, i.charName)
				end
                menu.combo[i.charName]:menu(_, "" .. i.charName .. " | " .. (str[i.slot] or "?") .. " | " .. _)
                menu.combo[i.charName][_]:boolean("Dodge", "Hijack || R", false)
			end
		end
	end
end

menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("w", "Use W", false);
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 45, 1, 100, 1);

menu:menu("clear", "Jungle Clear");
menu.clear:boolean("q", "Use Q", true);
menu.clear:boolean("w", "Use W", false);
menu.clear:boolean("e", "Use E", true);
--menu.clear:dropdown('modeW', 'Use E', 1, {'Never', 'Kill', 'Always'});
menu.clear:slider("Mana", "Minimum Mana Percent >= {0}", 50, 1, 100, 1);


menu:menu("ddd", "Display");
menu.ddd:boolean("qd", "Q Range", false);
menu.ddd:boolean("wd", "W Range", false);
menu.ddd:boolean("ed", "E Range", true);
menu.ddd:boolean("rd", "R Range", true);

local function Combo()
    local targetE = GetTargetE();
    if targetE and common.IsValidTarget(targetE) then 
        if player:spellSlot(2).name == "SylasE" then 
            if player:spellSlot(2).state == 0 then
                local dist = player.path.serverPos:distSqr(targetE.path.serverPos)
                if dist > 800*800 then return end 
                if common.GetDistance(targetE, mousePos) < 800 then
                    if menu.combo.e:get() then
                        player:castSpell("pos", 2, mousePos)
                    end
                end
            end
        end
        if player:spellSlot(2).name == "SylasE2" then 
            local epred2 = pred.linear.get_prediction(spellE, targetE)
            if epred2 and epred2.startPos:dist(epred2.endPos) < spellE.range then
                local colid = pred.collision.get_prediction(spellE, epred2, targetE)
                if not colid and player.path.serverPos:dist(targetE.path.serverPos) < spellE.range then 
                    if player:spellSlot(2).state == 0 and menu.combo.e:get() then
                        player:castSpell("pos", 2, vec3(epred2.endPos.x, targetE.y, epred2.endPos.y))
                    end
                end 
            end
        end
    end
    local targetQ = GetTargetQ();
    if targetQ and common.IsValidTarget(targetQ) then 
        local qpred2 = pred.linear.get_prediction(spellE, targetQ)
        if qpred2 and qpred2.startPos:dist(qpred2.endPos) < spellQ.range then
            if player.path.serverPos:dist(targetQ.path.serverPos) < spellQ.range then 
                if player:spellSlot(0).state == 0 and menu.combo.q:get() then
                    player:castSpell("pos", 0, vec3(qpred2.endPos.x, targetQ.y, qpred2.endPos.y))
                end
            end 
        end
    end
    local targetW = GetTargetW();
    if targetW and common.IsValidTarget(targetW) then 
        if menu.combo.w:get() == 1 then 
            if player.path.serverPos:dist(targetW.path.serverPos) < 400 then
                if common.GetPercentHealth(player) < menu.combo.healthW:get() and common.GetPercentHealth(targetW) > common.GetPercentHealth(player) then 
                    if menu.combo.w:get() then
                        player:castSpell("obj", 1, targetW)
                    end
                end
            end
        elseif menu.combo.w:get() == 2 then 
            if player.path.serverPos:dist(targetW.path.serverPos) < 400 then
                if menu.combo.w:get() then
                    player:castSpell("obj", 1, targetW)
                end
            end
        end
    end
end

local function Harass()
    local targetQ = GetTargetQ();
    if targetQ and common.IsValidTarget(targetQ) then 
        local qpred2 = pred.linear.get_prediction(spellE, targetQ)
        if qpred2 and qpred2.startPos:dist(qpred2.endPos) < spellQ.range then
            if player.path.serverPos:dist(targetQ.path.serverPos) < spellQ.range then 
                if player:spellSlot(0).state == 0 and menu.harass.q:get() then
                    player:castSpell("pos", 0, vec3(qpred2.endPos.x, targetQ.y, qpred2.endPos.y))
                end
            end 
        end
    end
    local targetW = GetTargetW();
    if targetW and common.IsValidTarget(targetW) then 
        if player.path.serverPos:dist(targetW.path.serverPos) < 400 then
            if common.GetPercentHealth(player) < menu.combo.healthW:get() and common.GetPercentHealth(targetW) > common.GetPercentHealth(player) then 
                if menu.harass.w:get() then
                    player:castSpell("obj", 1, targetW)
                end
            end
        end
    end
end 

local function JungleClear()
    if menu.clear.q:get() and player:spellSlot(0).state == 0 then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.isTargetable and minion.isVisible 
             then
                if minion.pos:dist(player.pos) <= spellQ.range then
                    player:castSpell("pos", 0, minion.pos)
                end
            end
        end
    end
    if menu.clear.w:get() and player:spellSlot(1).state == 0 then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead and minion.isTargetable and minion.isVisible
             then
                if minion.pos:dist(player.pos) <= 400 then
                    player:castSpell("obj", 1, minion)
                end
            end
        end
    end
    if menu.clear.e:get() and player:spellSlot(2).state == 0 then
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if
                minion and not minion.isDead  and minion.isTargetable and minion.isVisible
             then
                if minion.pos:dist(player.pos) <= spellE.range then
                    if player:spellSlot(2).name == "SylasE" then 
                        player:castSpell("pos", 2, minion.pos)
                    end
                    if player:spellSlot(2).name == "SylasE2" then 
                        player:castSpell("pos", 2, minion.pos)
                    end
              
                end
            end
        end
    end
end

local function OnTick() 
    if (orb.combat.is_active()) then
        Combo();
    end
    if orb.menu.hybrid:get() then 
        if (player.mana / player.maxMana) * 100 >= menu.harass.Mana:get() then  
            Harass();
        end
    end
    if (orb.menu.lane_clear:get()) then 
        if (player.mana / player.maxMana) * 100 >= menu.clear.Mana:get() then 
            JungleClear();
        end
    end

    if menu.combo.r:get() then 
        for _, k in pairs(database) do
            local target = GetTargetR();
            if target and common.IsValidTarget(target) then
                if target.buff['sylasr'] then return end
                if menu.combo[k.charName] and menu.combo[k.charName][_] and menu.combo[k.charName][_].Dodge:get() then 
                    if player.path.serverPos:dist(target.path.serverPos) < spellR.range then 
                        if player:spellSlot(3).state == 0 and player:spellSlot(3).name == "SylasR" then
                            --if k.charName == target.charName then
                                player:castSpell("obj", 3, target)
                            --end
                        end
                    end
                end 
            end
            local target2 = GetTargetR2();
            if target2 and common.IsValidTarget(target2) then
                if k.charName == target2.charName then
                    if k.displayname == "" then
                        k.displayname = _
                    end
                    if k.danger == 0 then
                        k.danger = 1
                    end
        
    
                    if (k.type == "linear")  then
                        if player:spellSlot(3).name == "SylasR" then return end
                        if player:spellSlot(3).state == 0 then 
                            local Spelllinear = {
                                delay = k.delay or 0.25;
                                width = k.radius or 100;
                                speed = k.speed or math.huge;
                                boundingRadiusMod = 0; 
                                collision = {
                                    hero = true,
                                    minion = true,
                                    wall = true
                                }
                            }                        
                            local linear_pred = pred.linear.get_prediction(Spelllinear, target2)
                            if linear_pred and linear_pred.startPos:dist(linear_pred.endPos) < menu.combo.rangetotal:get() then
                                if (k.collisionss) then 
                                    --chat.print('Wor2')
                                    if not pred.collision.get_prediction(Spelllinear, linear_pred, target2) and common.GetDistance(target2, player) < k.range then
                                        if (menu.combo.r2:get() == 2) then
                                            if dlib.GetSpellDamage(3, target2, 1, target2)  > target2.health then
                                                player:castSpell("pos", 3, vec3(linear_pred.endPos.x, target2.y, linear_pred.endPos.y))
                                                --chat.print('Work damage')
                                            else 
                                                player:castSpell("pos", 3, vec3(linear_pred.endPos.x, target2.y, linear_pred.endPos.y))
                                            end
                                        elseif menu.combo.r2:get() == 1 then  
                                            player:castSpell("pos", 3, vec3(linear_pred.endPos.x, target2.y, linear_pred.endPos.y))
                                            --chat.print('Work not damage')
                                        end
                                    end 
                                else
                                    if (menu.combo.r2:get() == 2) then
                                        if dlib.GetSpellDamage(3, target2, 1, target2)  > target2.health then
                                            --chat.print('Work3')
                                            player:castSpell("pos", 3, vec3(linear_pred.endPos.x, target2.y, linear_pred.endPos.y))
                                        else 
                                            player:castSpell("pos", 3, vec3(linear_pred.endPos.x, target2.y, linear_pred.endPos.y))
                                        end
                                    elseif menu.combo.r2:get() == 1 then  
                                        player:castSpell("pos", 3, vec3(linear_pred.endPos.x, target2.y, linear_pred.endPos.y))
                                    end
                                end
                            end
                        end
                    elseif (k.type == "circular")  then 
                        if player:spellSlot(3).name == "SylasR" then return end
                        if player:spellSlot(3).state == 0 then 
                            local SpellCircular = {
                                delay = k.delay or 0.25;
                                radius = k.radius or 100;
                                speed = k.speed or math.huge;
                                boundingRadiusMod = 0; 
                                collision = {
                                    hero = true,
                                    minion = true,
                                    wall = true
                                }
                            }                        
                            local circular_pred = pred.circular.get_prediction(SpellCircular, target2)
                            if circular_pred and circular_pred.startPos:dist(circular_pred.endPos) < menu.combo.rangetotal:get() then
                                if (k.collisionss) then 
                                    if not pred.collision.get_prediction(SpellCircular, circular_pred, target2)  and common.GetDistance(target2, player) < k.range then
                                        if (menu.combo.r2:get() == 2) then
                                            if dlib.GetSpellDamage(3, target2, 1, target2)  > target2.health then
                                                player:castSpell("pos", 3, vec3(circular_pred.endPos.x, target2.y, circular_pred.endPos.y))
                                            else 
                                                player:castSpell("pos", 3, vec3(circular_pred.endPos.x, target2.y, circular_pred.endPos.y))
                                            end
                                        elseif menu.combo.r2:get() == 1 then  
                                            player:castSpell("pos", 3, vec3(circular_pred.endPos.x, target2.y, circular_pred.endPos.y))
                                        end
                                    end 
                                else
                                    if (menu.combo.r2:get() == 2) then
                                        if dlib.GetSpellDamage(3, target2, 1, target2)  > target2.health then
                                            player:castSpell("pos", 3, vec3(circular_pred.endPos.x, target2.y, circular_pred.endPos.y))
                                        else 
                                            player:castSpell("pos", 3, vec3(circular_pred.endPos.x, target2.y, circular_pred.endPos.y))
                                        end
                                    elseif menu.combo.r2:get() == 1 then  
                                        player:castSpell("pos", 3, vec3(circular_pred.endPos.x, target2.y, circular_pred.endPos.y))
                                    end
                                end
                            end
                        end
                    elseif (k.type == "cross")  then 
                        if player:spellSlot(3).name == "SylasR" then return end
                        if player:spellSlot(3).state == 0 then 
                            local Spellcross = {
                                delay = k.delay or 0.25;
                                radius = k.radius or 100;
                                speed = k.speed or math.huge;
                                boundingRadiusMod = 0; 
                                collision = {
                                    hero = true,
                                    minion = true,
                                    wall = true
                                }
                            }     
                            local rpred = pred.circular.get_prediction(Spellcross, target2)
                            if not rpred then return end
                            local pred_pos = vec3(rpred.endPos.x, target2.pos.y, rpred.endPos.y);
                            if pred_pos:dist(player.pos) > 700 then return end

                            local x1 = pred_pos + vec3(200,0,200);
	                        local x2 = pred_pos + vec3(-200,0,-200);
	                        local x3 = pred_pos + vec3(200,0,-200);
                            local x4 = pred_pos + vec3(-200,0,200);
                            
                            local ps1, pl1, line1 = common.vector_point_project(x1, x2, target2);
                            local ps2, pl2, line2 = common.vector_point_project(x3, x4, target2);
                            local newpos = vec2(pred_pos.x, pred_pos.z);
                        
                            if (line1 and newpos:dist(ps1) < 50 + target2.boundingRadius) or (line2 and newpos:dist(ps2) < 50 + target2.boundingRadius) then
                                if last_execute > 0 and game.time - last_execute < 1.2 then return end
                                player:castSpell("pos", 3, pred_pos)
                                last_execute = game.time;
                            end
                        end
                    elseif (k.type == "conic")  then 
                        if player:spellSlot(3).name == "SylasR" then return end
                        if player:spellSlot(3).state == 0 then 
                            local Spelllinear = {
                                delay = k.delay or 0.25;
                                width = k.angle or 80;
                                speed = k.speed or math.huge;
                                boundingRadiusMod = 0; 
                                collision = {
                                    hero = true,
                                    minion = true,
                                    wall = true
                                }
                            }                        
                            local conic_pred = pred.linear.get_prediction(Spelllinear, target2)
                            if conic_pred and conic_pred.startPos:dist(conic_pred.endPos) < menu.combo.rangetotal:get() then
                                if (k.collisionss) then 
                                    if not pred.collision.get_prediction(Spelllinear, conic_pred, target2) and common.GetDistance(target2, player) < k.range then
                                        if (menu.combo.r2:get() == 2) then
                                            if dlib.GetSpellDamage(3, target2, 1, target2)  > target2.health then
                                                player:castSpell("pos", 3, vec3(conic_pred.endPos.x, target2.y, conic_pred.endPos.y))
                                            else 
                                                player:castSpell("pos", 3, vec3(conic_pred.endPos.x, target2.y, conic_pred.endPos.y))
                                            end
                                        elseif menu.combo.r2:get() == 1 then  
                                            player:castSpell("pos", 3, vec3(conic_pred.endPos.x, target2.y, conic_pred.endPos.y))
                                        end
                                    end 
                                else
                                    if (menu.combo.r2:get() == 2) then
                                        if dlib.GetSpellDamage(3, target2, 1, target2)  > target2.health then
                                            player:castSpell("pos", 3, vec3(conic_pred.endPos.x, target2.y, conic_pred.endPos.y))
                                        else 
                                            player:castSpell("pos", 3, vec3(conic_pred.endPos.x, target2.y, conic_pred.endPos.y))
                                        end
                                    elseif menu.combo.r2:get() == 1 then  
                                        player:castSpell("pos", 3, vec3(conic_pred.endPos.x, target2.y, conic_pred.endPos.y))
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

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.ddd.qd:get()) then 
            graphics.draw_circle(player.pos, spellQ.range, 1, graphics.argb(255, 185, 139, 86), 100)
        end
        if (player:spellSlot(1).state == 0 and menu.ddd.wd:get()) then 
            graphics.draw_circle(player.pos, 400, 1, graphics.argb(255, 185, 139, 86), 100)
        end
        if (player:spellSlot(2).state == 0 and menu.ddd.ed:get()) then 
            graphics.draw_circle(player.pos, spellE.range, 1, graphics.argb(255, 185, 139, 86), 100)
        end
        if (player:spellSlot(3).state == 0 and menu.ddd.rd:get()) then 
            graphics.draw_circle(player.pos, spellR.range, 2, graphics.argb(255, 185, 139, 86), 50)
        end

        --[[local pts = DivideCircleInPoints(player.pos, 350, 20)
        for it = 1, #pts do
            local point = pts[it]
            local worldPt = point:toDX3()

            graphics.draw_circle(worldPt, 120, 2, graphics.argb(255, 255, 255, 255), 100)
        end]] 
    end
end

--local function OnT_gameick()
    --if not orb.combat.is_active() then return end
--end 

cb.add(cb.draw, OnDraw)
orb.combat.register_f_pre_tick(OnTick);