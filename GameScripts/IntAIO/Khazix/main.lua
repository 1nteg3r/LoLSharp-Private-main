
--Update
local gpred = module.internal("pred")
local ts = module.internal('TS')
local orb = module.internal("orb");
local common = module.load("int", "Library/common")

local minionmanager = objManager.minions

local function ST(res, obj, Distancia)
    if Distancia < 1000 then
        res.obj = obj
        return true
    end
end

local function GetTargetSelector()
	return ts.get_result(ST).obj
end

local QlvlDmg = {50, 75, 100, 125, 150}
local WlvlDmg = {85, 115, 145, 165, 205}
local ElvlDmg = {65, 100, 135, 170, 205}
local IsoDmg = {14, 22, 30, 38, 46, 54, 62, 70, 78, 86, 94, 102, 110, 118, 126, 134, 142, 150}
local QRange, ERange = 0, 0
local Isolated = false

local PredE = { delay = 0.25, radius = 300, speed = 1500, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local PredW = { delay = 0.25, width = 70, speed = 1700, boundingRadiusMod = 1, collision = { hero = true, minion = true } }

local menu = menu("IntnnerKhazix", "Int Kha'Zix")
	menu:header("script", "Core");
	menu:keybind("combo", "Combo Key", "Space", nil)
	--Combo
	menu:boolean("q", "Use Q", true);
	menu:boolean("w", "Use W", true);
	menu:header("scripdddt", "E Combat");
	menu:boolean("e", "Use E", true);
	menu:dropdown("ed", "Use E when", 2, {"Always", "Evolved"});
	menu:header("sSSScripdddt", "R Combat");
	menu:boolean("r", "Use R", true);
	menu:dropdown("rm", "Use Ultimate: ", 2, {"Always", "Smart"});

	menu:header("sSSScripdddt", "Orthes");
	menu:menu("harass", "Harass");
	menu.harass:keybind("dd", "Harass Key", "C", nil);
	menu.harass:boolean("q", "Use Q", true);
	menu.harass:boolean("w", "Use W", true);

	menu:menu("jg", "Clear/Jungle");
	menu.jg:keybind("clear", "Clear Key", "V", false);
	menu.jg:boolean("q", "Use Q", true);
	menu.jg:boolean("w", "Use W", true);

	menu:header("xd8", "Smart Automatic")
	menu:boolean("uks", "Use Smart Killsteal", true);
	menu:boolean("ukse", "Use E in Killsteal", true);
    menu.ukse:set("tooltip", "Min. HP to use E is 30%");

	menu:menu("draws", "Display")
	menu.draws:boolean("q", "Draw Q Range", true);
	menu.draws:boolean("e", "Draw E Range", true);

	--Flee
	menu:keybind("run", "Flee", "Z", false)

local function qDmg(target)
	local damage = 0;
	if (player:spellSlot(0).state == 0) then
		if Isolated then
			damage = common.CalculatePhysicalDamage(target, QlvlDmg[player:spellSlot(0).level] + (common.GetBonusAD() * 1.3))
		end
	end
  	return damage
end

local function wDmg(target)
	local damage = 0;
	if (player:spellSlot(1).state == 0) then
		damage = common.CalculatePhysicalDamage(target, WlvlDmg[player:spellSlot(1).level] + (common.GetBonusAD() * 1))
	end
    return damage
end

local function eDmg(target)
	local damage = 0;
	if (player:spellSlot(2).state == 0) then
		damage = common.CalculatePhysicalDamage(target, ElvlDmg[player:spellSlot(2).level] + (common.GetBonusAD() * 0.2))
	end
	return damage
end

local function CastE(target)
	if player:spellSlot(2).state == 0 then
		if player:spellSlot(2).name == "KhazixE" then
			local res = gpred.circular.get_prediction(PredE, target)
			if res and res.startPos:dist(res.endPos) < 600 and res.startPos:dist(res.endPos) > 325  then
				player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		elseif player:spellSlot(2).name == "KhazixELong" then
			local res = gpred.circular.get_prediction(PredE, target)
			if res and res.startPos:dist(res.endPos) < 900 and res.startPos:dist(res.endPos) > 400 then
				player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		end
	end
end

local function CastW(target)
	if player:spellSlot(1).state == 0 then
		local seg = gpred.linear.get_prediction(PredW, target)
		if seg and seg.startPos:dist(seg.endPos) < 970 then
			if not gpred.collision.get_prediction(PredW, seg, target) then
				player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end

local function CastR()
	if player:spellSlot(3).state == 0 then
		player:castSpell("self", 3)
	end
end

local function CastQ(target)
	if player:spellSlot(0).state == 0 then
		if player:spellSlot(0).name == "KhazixQ" then
			if target.pos:dist(player.pos) <= 325 then
				player:castSpell("obj", 0, target)
			end
		elseif player:spellSlot(0).name == "KhazixQLong" then
			if target.pos:dist(player.pos) <= 375 then
				player:castSpell("obj", 0, target)
			end
		end
	end
end

local function PlayerAD()
	if Isolated == false then
    	return player.flatPhysicalDamageMod + player.baseAttackDamage
    else
    	return player.flatPhysicalDamageMod + player.baseAttackDamage + (IsoDmg[player.levelRef] + player.flatPhysicalDamageMod * .2 )
    end
end

local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.uks:get() then
			local hp = enemy.health;
			if hp == 0 then return end
			if player:spellSlot(0).state == 0 and qDmg(enemy) + PlayerAD() > hp and enemy.pos:dist(player.pos) < 325 then
				CastQ(enemy);
			elseif player:spellSlot(1).state == 0 and wDmg(enemy) > hp and enemy.pos:dist(player.pos) < 960 then
				CastW(enemy);
			elseif player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and wDmg(enemy) + qDmg(enemy) > hp and enemy.pos:dist(player.pos) < 500 then
				CastQ(enemy)
				CastW(enemy)
			elseif player:spellSlot(2).state == 0 and player:spellSlot(0).state == 0 and qDmg(enemy) + eDmg(enemy) + PlayerAD() > hp and menu.ukse:get() and common.GetPercentHealth(player) >= 30 and enemy.pos:dist(player.pos) < 990 then
				CastE(enemy)
				CastQ(enemy)
			elseif player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and qDmg(enemy) + eDmg(enemy) + wDmg(enemy) + PlayerAD() > hp and menu.ukse:get() and common.GetPercentHealth(player) >= 30 and enemy.pos:dist(player.pos) < 990 then
				CastE(enemy)
				CastQ(enemy)
				if enemy.pos:dist(player.pos) <= 700 then
					CastW(enemy)
				end
			end
		end
	end
end

local function Combo()
	local target = GetTargetSelector()
	if target and common.IsValidTarget(target) then
		if menu.e:get() then
			if (menu.ed:get() == 1) then
				CastE(target)
			elseif (menu.ed:get() == 2) then
				if (player:spellSlot(2).name == "KhazixELong") then
					CastE(target)
				end
			end
		end
		if menu.q:get() then
			CastQ(target)
		end
		if menu.w:get() and target.pos:dist(player.pos) >= 470 then
			CastW(target)
		elseif menu.w:get() and Isolated == true or player:spellSlot(0).state ~= 0 then
			CastW(target)
		end
		if menu.r:get() and player:spellSlot(3).state == 0 then
			if menu.rm:get() == 2 then
				if player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and target.health <= ((qDmg(target)*2) + wDmg(target) + eDmg(target)) and target.health > (wDmg(target) + eDmg(target)) then
	                if target.pos:dist(player.pos) <= 900 then
	                    if player:spellSlot(2).state == 0 then CastR() end
	                end
	            end
	        elseif menu.rm:get() == 1 then
	            if target.pos:dist(player.pos) <= ERange + 159 then
	                if player:spellSlot(2).state == 0 then CastR() end
	            end
	        end
		end
	end
end

local function Harass()
	local target = GetTargetSelector()
	if target and common.IsValidTarget(target) then
		if menu.harass.dd:get() then
			if player.par / player.maxPar * 100 >= 10 then
				if menu.harass.q:get() then
					CastQ(target)
				end
				if menu.harass.w:get() then
					CastW(target)
				end
			end
		end
	end
end

local function Clear()
	local target = { obj = nil, health = 0, mode = "jungleclear" }
	local aaRange = player.attackRange + player.boundingRadius + 200
	for i = 0, minionmanager.size[TEAM_NEUTRAL] - 1 do
		local obj = minionmanager[TEAM_NEUTRAL][i]
		if player.pos:dist(obj.pos) <= aaRange and obj.maxHealth > target.health then
			target.obj = obj
			target.health = obj.maxHealth
		end
	end
	if target.obj then
		if target.mode == "jungleclear" then
			if menu.jg.q:get() and player:spellSlot(0).state == 0 then
				player:castSpell("obj", 0, target.obj)
			end
			if menu.jg.w:get() and player:spellSlot(1).state == 0 then
				CastW(target.obj)
			end
		end
	end
end


local function Run()
	if menu.run:get() then
		player:move((game.mousePos))
		if player:spellSlot(2).state == 0 then
			player:castSpell("pos", 2, (game.mousePos))
		end
	end
end

local function Evoluir()
    if player:spellSlot(0).name == "KhazixQ" then
        QRange = 325
    elseif player:spellSlot(0).name == "KhazixQLong" then
    	QRange = 375
    end
    if player:spellSlot(2).name == "KhazixE" then
        ERange = 700
    elseif player:spellSlot(2).name == "KhazixELong" then
    	ERange = 900
    end
end

local function ObjCreat(obj)
    if obj then
        if obj.name:find("SingleEnemy_Indicator") then
            Isolated = true
        end
    end
end

local function ObjDelete(obj)
    if obj then
        Isolated = false
    end
end

local function OnTick()
	KillSteal()
    if orb.combat.is_active() then
        Combo()
    end
    if menu.harass.dd:get() then
        Harass()
    end
    if menu.run:get() then
        Run()
    end
    if menu.draws.q:get() or menu.draws.e:get() then
        Evoluir()
    end
	if menu.jg.clear:get() then
		Clear()
	end
end

local function OnDraw()
	if menu.draws.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, QRange, 2, graphics.argb(255, 255, 255, 255), 40)
	end
	if menu.draws.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, ERange, 2, graphics.argb(255, 255, 255, 255), 40)
	end
	local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and target.isVisible and common.IsValidTarget(target) and not target.buff[17] then
            if target.isOnScreen then
                local damage = (qDmg(target) + wDmg(target) + eDmg(target))
                local barPos = target.barPos
                local percentHealthAfterDamage = math.max(0, target.health - damage) / target.maxHealth
                graphics.draw_line_2D(barPos.x + 165 + 103 * target.health/target.maxHealth, barPos.y+123, barPos.x + 165 + 100 * percentHealthAfterDamage, barPos.y+123, 11,  graphics.argb(90, 255, 169, 4))
            end
        end
    end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.create_particle, ObjCreat)
cb.add(cb.delete_particle, ObjDelete)
cb.add(cb.draw, OnDraw)

--[[
	
--Update
local gpred = module.internal("pred")
local ts = module.internal('TS')
local orb = module.internal("orb")
local common = module.load("int", "common")

local minionmanager = objManager.minions

local function ST(res, obj, Distancia)
    if Distancia < 1000 then
        res.obj = obj
        return true
    end
end

local function GetTargetSelector()
	return ts.get_result(ST).obj
end

local QlvlDmg = {50, 75, 100, 125, 150}
local WlvlDmg = {85, 115, 145, 165, 205}
local ElvlDmg = {65, 100, 135, 170, 205}
local IsoDmg = {14, 22, 30, 38, 46, 54, 62, 70, 78, 86, 94, 102, 110, 118, 126, 134, 142, 150}
local QRange, ERange = 0, 0
local Isolated = false

local PredE = { delay = 0.25, radius = 300, speed = 1500, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local PredW = { delay = 0.25, width = 70, speed = 1700, boundingRadiusMod = 1, collision = { hero = true, minion = true } }

local menu = menu("int", "Int Kha'Zix")
	menu:header("script", "Core");
	menu:keybind("combo", "Combo Key", "Space", nil)
	--Combo
	menu:boolean("q", "Use Q", true);
	menu:boolean("w", "Use W", true);
	menu:header("scripdddt", "E Combat");
	menu:boolean("e", "Use E", true);
	menu:dropdown("ed", "Use E when", 2, {"Always", "Evolved"});
	menu:header("sSSScripdddt", "R Combat");
	menu:boolean("r", "Use R", true);
	menu:dropdown("rm", "Use Ultimate: ", 2, {"Always", "Smart"});

	menu:header("sSSScripdddt", "Orthes");
	menu:menu("harass", "Harass");
	menu.harass:keybind("dd", "Harass Key", "C", nil);
	menu.harass:boolean("q", "Use Q", true);
	menu.harass:boolean("w", "Use W", true);

	menu:menu("jg", "Clear/Jungle");
	menu.jg:keybind("clear", "Clear Key", "V", false);
	menu.jg:boolean("q", "Use Q", true);
	menu.jg:boolean("w", "Use W", true);

	menu:header("xd8", "Smart Automatic")
	menu:boolean("uks", "Use Smart Killsteal", true);
	menu:boolean("ukse", "Use E in Killsteal", true);
    menu.ukse:set("tooltip", "Min. HP to use E is 30%");

	menu:menu("draws", "Display")
	menu.draws:boolean("q", "Draw Q Range", true);
	menu.draws:boolean("e", "Draw E Range", true);

	--Flee
	menu:keybind("run", "Flee", "Z", false)

local function qDmg(target)
	local damage = 0;
	if (player:spellSlot(0).state == 0) then
		if Isolated then
			damage = common.CalculatePhysicalDamage(target, QlvlDmg[player:spellSlot(0).level] + (common.GetBonusAD() * 1.3))
		end
	end
  	return damage
end

local function wDmg(target)
	local damage = 0;
	if (player:spellSlot(1).state == 0) then
		damage = common.CalculatePhysicalDamage(target, WlvlDmg[player:spellSlot(1).level] + (common.GetBonusAD() * 1))
	end
    return damage
end

local function eDmg(target)
	local damage = 0;
	if (player:spellSlot(2).state == 0) then
		damage = common.CalculatePhysicalDamage(target, ElvlDmg[player:spellSlot(2).level] + (common.GetBonusAD() * 0.2))
	end
	return damage
end

local function CastE(target)
	if player:spellSlot(2).state == 0 then
		if player:spellSlot(2).name == "KhazixE" then
			local res = gpred.circular.get_prediction(PredE, target)
			if res and res.startPos:dist(res.endPos) < 600 and res.startPos:dist(res.endPos) > 325  then
				player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		elseif player:spellSlot(2).name == "KhazixELong" then
			local res = gpred.circular.get_prediction(PredE, target)
			if res and res.startPos:dist(res.endPos) < 900 and res.startPos:dist(res.endPos) > 400 then
				player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		end
	end
end

local function CastW(target)
	if player:spellSlot(1).state == 0 then
		local seg = gpred.linear.get_prediction(PredW, target)
		if seg and seg.startPos:dist(seg.endPos) < 970 then
			if not gpred.collision.get_prediction(PredW, seg, target) then
				player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end

local function CastR()
	if player:spellSlot(3).state == 0 then
		player:castSpell("self", 3)
	end
end

local function CastQ(target)
	if player:spellSlot(0).state == 0 then
		if player:spellSlot(0).name == "KhazixQ" then
			if target.pos:dist(player.pos) <= 325 then
				player:castSpell("obj", 0, target)
			end
		elseif player:spellSlot(0).name == "KhazixQLong" then
			if target.pos:dist(player.pos) <= 375 then
				player:castSpell("obj", 0, target)
			end
		end
	end
end

local function PlayerAD()
	if Isolated == false then
    	return player.flatPhysicalDamageMod + player.baseAttackDamage
    else
    	return player.flatPhysicalDamageMod + player.baseAttackDamage + (IsoDmg[player.levelRef] + player.flatPhysicalDamageMod * .2 )
    end
end

local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.uks:get() then
			local hp = enemy.health;
			if hp == 0 then return end
			if player:spellSlot(0).state == 0 and qDmg(enemy) + PlayerAD() > hp and enemy.pos:dist(player.pos) < 325 then
				CastQ(enemy);
			elseif player:spellSlot(1).state == 0 and wDmg(enemy) > hp and enemy.pos:dist(player.pos) < 960 then
				CastW(enemy);
			elseif player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and wDmg(enemy) + qDmg(enemy) > hp and enemy.pos:dist(player.pos) < 500 then
				CastQ(enemy)
				CastW(enemy)
			elseif player:spellSlot(2).state == 0 and player:spellSlot(0).state == 0 and qDmg(enemy) + eDmg(enemy) + PlayerAD() > hp and menu.ukse:get() and common.GetPercentHealth(player) >= 30 and enemy.pos:dist(player.pos) < 990 then
				CastE(enemy)
				CastQ(enemy)
			elseif player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and qDmg(enemy) + eDmg(enemy) + wDmg(enemy) + PlayerAD() > hp and menu.ukse:get() and common.GetPercentHealth(player) >= 30 and enemy.pos:dist(player.pos) < 990 then
				CastE(enemy)
				CastQ(enemy)
				if enemy.pos:dist(player.pos) <= 700 then
					CastW(enemy)
				end
			end
		end
	end
end

local function Combo()
	local target = GetTargetSelector()
	if target and common.IsValidTarget(target) then
		if menu.e:get() then
			if (menu.ed:get() == 1) then
				CastE(target)
			elseif (menu.ed:get() == 2) then
				if (player:spellSlot(2).name == "KhazixELong") then
					CastE(target)
				end
			end
		end
		if menu.q:get() then
			CastQ(target)
		end
		if menu.w:get() and target.pos:dist(player.pos) >= 470 then
			CastW(target)
		elseif menu.w:get() and Isolated == true or player:spellSlot(0).state ~= 0 then
			CastW(target)
		end
		if menu.r:get() and player:spellSlot(3).state == 0 then
			if menu.rm:get() == 2 then
				if player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and target.health <= ((qDmg(target)*2) + wDmg(target) + eDmg(target)) and target.health > (wDmg(target) + eDmg(target)) then
	                if target.pos:dist(player.pos) <= 900 then
	                    if player:spellSlot(2).state == 0 then CastR() end
	                end
	            end
	        elseif menu.rm:get() == 1 then
	            if target.pos:dist(player.pos) <= ERange + 159 then
	                if player:spellSlot(2).state == 0 then CastR() end
	            end
	        end
		end
	end
end

local function Harass()
	local target = GetTargetSelector()
	if target and common.IsValidTarget(target) then
		if menu.harass.dd:get() then
			if player.par / player.maxPar * 100 >= 10 then
				if menu.harass.q:get() then
					CastQ(target)
				end
				if menu.harass.w:get() then
					CastW(target)
				end
			end
		end
	end
end

local function Clear()
	local target = { obj = nil, health = 0, mode = "jungleclear" }
	local aaRange = player.attackRange + player.boundingRadius + 200
	for i = 0, minionmanager.size[TEAM_NEUTRAL] - 1 do
		local obj = minionmanager[TEAM_NEUTRAL][i]
		if player.pos:dist(obj.pos) <= aaRange and obj.maxHealth > target.health then
			target.obj = obj
			target.health = obj.maxHealth
		end
	end
	if target.obj then
		if target.mode == "jungleclear" then
			if menu.jg.q:get() and player:spellSlot(0).state == 0 then
				player:castSpell("obj", 0, target.obj)
			end
			if menu.jg.w:get() and player:spellSlot(1).state == 0 then
				CastW(target.obj)
			end
		end
	end
end


local function Run()
	if menu.run:get() then
		player:move((game.mousePos))
		if player:spellSlot(2).state == 0 then
			player:castSpell("pos", 2, (game.mousePos))
		end
	end
end

local function Evoluir()
    if player:spellSlot(0).name == "KhazixQ" then
        QRange = 325
    elseif player:spellSlot(0).name == "KhazixQLong" then
    	QRange = 375
    end
    if player:spellSlot(2).name == "KhazixE" then
        ERange = 700
    elseif player:spellSlot(2).name == "KhazixELong" then
    	ERange = 900
    end
end

local function ObjCreat(obj)
    if obj then
        if obj.name:find("SingleEnemy_Indicator") then
            Isolated = true
        end
    end
end

local function ObjDelete(obj)
    if obj then
        Isolated = false
    end
end

local function OnTick()
	KillSteal()
    if orb.combat.is_active() then
        Combo()
    end
    if menu.harass.dd:get() then
        Harass()
    end
    if menu.run:get() then
        Run()
    end
    if menu.draws.q:get() or menu.draws.e:get() then
        Evoluir()
    end
	if menu.jg.clear:get() then
		Clear()
	end
end

local function OnDraw()
	if menu.draws.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, QRange, 2, graphics.argb(255, 255, 255, 255), 40)
	end
	if menu.draws.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, ERange, 2, graphics.argb(255, 255, 255, 255), 40)
	end
	local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and target.isVisible and common.IsValidTarget(target) and not target.buff[17] then
            if target.isOnScreen then
                local damage = (qDmg(target) + wDmg(target) + eDmg(target))
                local barPos = target.barPos
                local percentHealthAfterDamage = math.max(0, target.health - damage) / target.maxHealth
                graphics.draw_line_2D(barPos.x + 165 + 103 * target.health/target.maxHealth, barPos.y+123, barPos.x + 165 + 100 * percentHealthAfterDamage, barPos.y+123, 11,  graphics.argb(90, 255, 169, 4))
            end
        end
    end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.create_particle, ObjCreat)
cb.add(cb.delete_particle, ObjDelete)
cb.add(cb.draw, OnDraw)

]]