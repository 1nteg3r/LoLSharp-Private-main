local common = module.load("int", "Library/util");
local dmgl = module.load('int', 'Library/damageLib');
local ts = module.internal("TS")
local orb = module.internal("orb")
local gpred = module.internal("pred")
local qSpell = {range = 800}
local wSpell = {range = 400}
local eSpell = {range = 475}
local rSpell = {range = 1500}
local flashe = {range = 990}
local QlDmg = {25, 70, 115, 160, 205}
local WlDmg = {60, 100, 140, 180, 220}
local RlDmg = {50, 175, 300}


local menu = menu("int", "Int Urgot")
menu:header("serdar", "Core")

menu:menu("combo", "Combo")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:boolean("rcombo", "Use R", true)
--menu.combo:boolean("items", "Use Items", true)

menu:menu("harass", "Harass")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("wharass", "Use W", true)
menu.harass:slider("hmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("laneclear", "LaneClear Settings")
menu.laneclear:boolean("farmq", "Use Q", false)
menu.laneclear:boolean("farmw", "Use W", false)
menu.laneclear:slider("lmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("jungclear", "JungClear")
menu.jungclear:boolean("jungq", "Use Q", true)
menu.jungclear:boolean("jungw", "Use W", true)
menu.jungclear:slider("jmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("killsteal", "Killsteal")
menu.killsteal:boolean("useks", "Use Killsteal", true)
menu.killsteal:boolean("qks", "Use Q in Killsteal", true)
menu.killsteal:boolean("wks", "Use W in Killsteal", true)
menu.killsteal:boolean("rks", "Use R in Killsteal", true)

menu:menu("draws", "Drawings")
menu.draws:boolean("drawq", "Q Range", true)
menu.draws:boolean("draww", "W Range", true)
menu.draws:boolean("drawe", "E Range", true)
menu.draws:boolean("drawr", "R Range", true)

menu:menu("keys", "Keys")
menu.keys:keybind("combokey", "Combo", "Space", nil)
menu.keys:keybind("clearkey", "Clear", "V", nil)
menu.keys:keybind("harasskey", "Harass", "C", nil)


ts.load_to_menu();


local TargetSelection = function(res, obj, dist)
	if dist < qRange.range then
		res.obj = obj
		return true
	end
end

local function select_target(res, obj, dist)
	if dist > 1500 then return end
	res.obj = obj
	return true
end
local function get_target(func)
	return ts.get_result(func).obj
end
local function ult_target(res, obj, dist)
	if dist > 1500 then return end
	res.obj = obj
	return true
end

local qp = { delay = 0.6, radius = 100, speed = math.huge, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local wp = { delay = 0.25, radius = 125, speed = 2200, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local ep = { delay = 0.45, width = 100, speed = 1050, boundingRadiusMod = 2, collision = { hero = false, minion = false } }
local rp = { delay = 0, width = 70, speed = 3200, boundingRadiusMod = 1, collision = { hero = false, minion = false } }

local function qHesap(target)
	local qDamage = QlDmg[player:spellSlot(0).level] + (common.GetTotalAP() * .4)  
	return common.CalculateMagicDamage(target, qDamage)
end
local function wHesap(target)
	local wDamage = QlDmg[player:spellSlot(1).level] + (common.GetTotalAP() * .5)
	return common.CalculateMagicDamage(target, wDamage)
end
local function rHesap(target)
	local rDamage = RlDmg[player:spellSlot(3).level] + (common.GetTotalAP() * .125)
	return common.CalculateMagicDamage(target, rDamage)
end
local function CastQ(target)
	if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (800 * 800) then
		local ser = gpred.circular.get_prediction(qp, target)
		if ser and ser.startPos:dist(ser.endPos) < 800 then
			player:castSpell("pos", 0, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end
local function CastW(target)
	if player:spellSlot(1).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (400 * 400) then
		local ser = gpred.circular.get_prediction(wp, target)
		if ser and ser.startPos:dist(ser.endPos) < 400 then
			player:castSpell("pos", 1, target)
		end
	end
end
local function CastE(target)
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (475 * 475) then
		local ser = gpred.linear.get_prediction(ep, target)
		if ser and ser.startPos:dist(ser.endPos) < 1000 then
			player:castSpell("pos", 2, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end    
local function CastR(target)
	if player:spellSlot(3).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1500 * 1500) then
		local ser = gpred.linear.get_prediction(rp, target)
		if ser and ser.startPos:dist(ser.endPos) < 1500 then
			player:castSpell("pos", 3, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end 

local function CastRL()
if menu.combo.rcombo:get() then
local target = get_target(ult_target)
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) then
		local hp = enemy.health
      	local dist = player.path.serverPos:distSqr(enemy.path.serverPos)
			if player:spellSlot(3).state == 0 and dist <= (1500 * 1500) and rHesap(enemy) > hp  then
				CastR(enemy)
			end
		end
	end
end
end
local function CastRP()
if menu.combo.rcombo:get() then
local target = get_target(ult_target)
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) then
		local hp = enemy.health
      	local dist = player.path.serverPos:distSqr(enemy.path.serverPos)
			if player:spellSlot(3).state == 0 and dist <= (1625 * 1625) and (rHesap(enemy) * 2) + qHesap(enemy) + wHesap(enemy) + 100 > hp  then
				CastR(enemy)
			end
		end
	end
end
end


local function Combo()
	local target = get_target(select_target)
	if target and common.IsValidTarget(target) then 
		if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)
		end
		if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastRP(target)
		end
		if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 and player:spellSlot(1).state == 0  and player.pos:dist(target.pos) <= wSpell.range
		   then CastE(target)
		end
		if menu.combo.wcombo:get() and player:spellSlot(1).state == 0 and player:spellSlot(2).state <= 1 and player.pos:dist(target.pos) <= qSpell.range 
			then CastW(target)
		end
	end
end
local function Harass()
	if common.GetPercentPar() >= menu.harass.hmana:get() then
		local target = get_target(select_target)
		if target and common.IsValidTarget(target) then
		if menu.harass.qharass:get() and menu.keys.harasskey:get() then
			if (target.pos:dist(player) < qSpell.range) 
				then CastQ(target)
			end
		end
		if menu.harass.wharass:get() and menu.keys.harasskey:get() then
			if (target.pos:dist(player) < wSpell.range) 
					then CastW(target)
			end
		end
		end
	end
end
local function JungClear()
if (player.mana / player.maxMana) * 100 >= menu.jungclear.jmana:get() then
	if menu.jungclear.jungq:get() and menu.keys.clearkey:get() then	
		local enemyMinionsQ = common.GetMinionsInRange(qSpell.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsQ) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= qSpell.range then
					CastQ(minion)
				end
			end
		end
	end
	if menu.jungclear.jungw:get() and menu.keys.clearkey:get() then	
		local enemyMinionsW = common.GetMinionsInRange(wSpell.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsW) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= wSpell.range then
					CastW(minion)
				end
			end
		end
	end
end
end
local function LaneClear()
	if (player.mana / player.maxMana) * 100 >= menu.laneclear.lmana:get() then
		if menu.laneclear.farmq:get() and menu.keys.clearkey:get() then
			local enemyMinionsQ = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsQ) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= qSpell.range then
						CastQ(minion)
					end
				end	
			end
		end
		if menu.laneclear.farmw:get() and menu.keys.clearkey:get() then
			local enemyMinionsW = common.GetMinionsInRange(wSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsW) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= wSpell.range then
						CastW(minion)
					end
				end	
			end
		end
	end			
end
local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and menu.killsteal.useks:get() then
		local hp = enemy.health
		local c = player.path.serverPos:distSqr(enemy.path.serverPos)
			if menu.killsteal.qks:get() and menu.killsteal.useks:get() then
				if	player:spellSlot(0).state == 0 and c < qSpell.range and
					dmgl.GetSpellDamage(0, enemies) > hp
					then CastQ(enemy)
				end
				end	
				if menu.killsteal.wks:get() and menu.killsteal.useks:get() then
				if player:spellSlot(1).state == 0 and c < wSpell.range and 
					dmgl.GetSpellDamage(1, enemies) > hp
					then CastW(enemy)
				end
				end	
				if menu.killsteal.rks:get() and menu.killsteal.useks:get() then
				if	player:spellSlot(3).state == 0 and c < rSpell.range and
				dmgl.GetSpellDamage(3, enemies) > hp
				then CastR(enemy)
				end
			end
		end
	end
end
local function OnTick()
	if menu.killsteal.useks:get() then KillSteal() end
	if orb.combat.is_active() then Combo() end
	if menu.keys.harasskey:get() then Harass() end
	if menu.keys.clearkey:get() then JungClear() end	
	if menu.keys.clearkey:get() then LaneClear() end
end

local function OnDraw()
		if menu.draws.drawq:get() and player:spellSlot(0).state == 0 then
      	 graphics.draw_circle(player.pos, qSpell.range, 1, graphics.argb(55, 134, 232, 50), 100)
    	end
    	if menu.draws.draww:get() and player:spellSlot(1).state == 0 then
      		graphics.draw_circle(player.pos, wSpell.range, 1, graphics.argb(55, 134, 232, 50), 100)
    	end 	 	
    	if menu.draws.drawe:get() and player:spellSlot(2).state == 0 then
      		graphics.draw_circle(player.pos, eSpell.range , 1, graphics.argb(55, 149, 232, 50), 100)
    	end
    	if menu.draws.drawr:get() and player:spellSlot(3).state == 0 then
      		graphics.draw_circle(player.pos, rSpell.range , 1, graphics.argb(55, 149, 232, 50), 100)
    	end    	
end 


cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)

return {}