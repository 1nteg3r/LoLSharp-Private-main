
local common = module.load("int", "Library/util");
local dmgl = module.load('int', 'Library/damageLib');
local ts = module.internal("TS")
local orb = module.internal("orb");
local gpred = module.internal("pred")
local qSpell = {range = 750}
local wSpell = {range = 400} 
local eSpell = {range = 900}
local rSpell = {range = 450}

local QlDmg = {65, 90, 115, 140, 165}
local ElDmg = {70, 95, 120, 145, 170}
local RlDmg = {80, 120, 160}

local menu = menu("IntnnerIlaoi", "Int Illaoi")
menu:header("serdar", "Core")

menu:menu("combo", "Combo")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:boolean("rcombo", "Use R", true)

menu.combo:boolean("useQe", "Use E first if possible", true)
menu.combo:boolean("userg", "Only if Ghost in Range", true)
menu.combo:slider("hitr", "Min Enemy Use R", 2, 0, 5, 1)
menu.combo:boolean("follow", "Auto Follow To Enemy R ", true)
menu.combo:boolean("items", "Use Items", true)

menu:menu("harass", "Harass")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("wharass", "Use W", true)
menu.harass:boolean("eharass", "Use E", true)
menu.harass:boolean("items", "Use Items", true)
menu.harass:slider("hmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("laneclear", "LaneClear")
menu.laneclear:boolean("farmq", "Use Q to Farm", true)
menu.laneclear:slider("minq", "Min Minions to use in LaneClear", 3, 1, 6, 1)
menu.laneclear:boolean("farmw", "Use W to Farm", false)
menu.laneclear:slider("lmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("jungclear", "JungClear")
menu.jungclear:boolean("jungq", "Use Q", true)
menu.jungclear:boolean("jungw", "Use W", true)
menu.jungclear:slider("jmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("killsteal", "Killsteal")
menu.killsteal:boolean("qks", "Use Q in Killsteal", true)
menu.killsteal:boolean("wks", "Use W in Killsteal", true)
menu.killsteal:boolean("rks", "Use R in Killsteal", true)

menu:menu("draws", "Display")
menu.draws:boolean("drawq", "Q Range", true)
menu.draws:boolean("draww", "W Range", true)
menu.draws:boolean("drawe", "W Range", true)
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
local TargetSelectionGap = function(res, obj, dist)
	if dist < eSpell.range * 2 then
		res.obj = obj
		return true
	end
end
local GetTargetGap = function()
	return ts.get_result(TargetSelectionGap).obj
end
local function select_target(res, obj, dist)
	if dist > 900 then return end
	res.obj = obj
	return true
end
local function ult_target(res, obj, dist)
	if dist > 450 then return end
	res.obj = obj
	return true
end
local function count_enemies_in_range(pos, range)
	local enemies_in_range = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end
local function count_minion_in_range(pos, range)
	local minion_in_range = {}
	for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
		local minion = objManager.minions[TEAM_ENEMY][i]
		if minion and not minion.isDead and minion.isVisible then
        local distSqr = minion.path.serverPos:distSqr(target.path.serverPos)
        if distSqr < (585 * 585) 
			then enemies_in_range[#enemies_in_range + 1] = enemy
		end
		end
	end
	return enemies_in_range
end

local function get_target(func)
	return ts.get_result(func).obj
end

local dance = false

local qp = { delay = 0.75, width = 100, speed = math.huge, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local ep = { delay = 0.25, width = 45, speed = 1800, boundingRadiusMod = 1, collision = { hero = true, minion = true } }
local rp = { delay = 0.50, radius = 450, speed = math.huge, boundingRadiusMod = 1, collision = { hero = false, minion = false } }

local function CastQ(target)
	if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (750 * 750) then
		local ser = gpred.linear.get_prediction(qp, target)
		if ser and ser.startPos:dist(ser.endPos) < 750 then
			player:castSpell("pos", 0, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end

local function CastW(target)
	if player:spellSlot(1).state == 0 and player.pos:dist(target.pos) < wSpell.range 
		then player:castSpell("obj", 1 ,target)
	end
end

local function CastE(target)
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (900 * 900) then
		local ser = gpred.linear.get_prediction(ep, target)
		if ser and ser.startPos:dist(ser.endPos) < 900 then
			player:castSpell("pos", 2, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end
local function CastR(target)
	if player:spellSlot(3).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (450 * 450) then
		local ser = gpred.linear.get_prediction(ep, target)
		if ser and ser.startPos:dist(ser.endPos) < 450 then
			player:castSpell("pos", 3, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end

local function Combo()
local target = get_target(select_target)
for i = 0, objManager.enemies_n - 1 do
local enemy = objManager.enemies[i]
if enemy and common.IsValidTarget(enemy) then
local hp = enemy.health
	if target and common.IsValidTarget(target) then
		if menu.combo.items:get() then
			if (target.pos:dist(player) <= 500) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item and (item == "RanduinsOmen") then
						player:castSpell("obj", i, target)
					end
				end
			end
		end
		if menu.combo.items:get() then
			if (target.pos:dist(player) <= 1000) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item and (item == "YoumusBlade") then
						player:castSpell("obj", i, target)
					end
				end
			end
		end
		if menu.combo.items:get() then
			if (target.pos:dist(player) <= 750) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item and (item == "HextechGunblade") then
						player:castSpell("obj", i, target)
					end
				end
			end
		end
		if menu.combo.items:get() then
			if (target.pos:dist(player) <= 650) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item and (item == "ItemSwordOfFeastAndFamine") then
						player:castSpell("obj", i, target)
					end
				end
			end
		end
		if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpell.range 
			then CastE(target)				 				 
		end			
		if menu.combo.qcombo:get() and
		    player:spellSlot(0).state == 0 and 
		    	player.pos:dist(target.pos) <= qSpell.range
			then CastQ(target)		 		 				 
		end		
		if menu.combo.wcombo:get() and player:spellSlot(1).state == 0 and player.pos:dist(target.pos) <= wSpell.range 
			then CastW(target)	 			 				 
		end	
		if menu.combo.rcombo:get() and 
			menu.combo.hitr:get() <= #count_enemies_in_range(target.pos, 450) and
				 player:spellSlot(3).state == 0 and player.pos:dist(target.pos) <= rSpell.range 
			then CastR(target)
		end				
	end	
end
end 	 
end	
local function Harass()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then
		if menu.harass.eharass:get() and menu.keys.harasskey:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpell.range then
			if not common.IsUnderEnemyTower(vec3(target.x, target.y, target.z)) then
				if player.pos:dist(target.pos) <= menu.harass.mine:get()
				    then CastE(target)
				end
			end
		end
		if menu.harass.qharass:get() and menu.keys.harasskey:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)
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
				if minionPos:dist(player.pos) <= qSpell.range 
				 then CastQ(minion)
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


local function KillSteal()
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
		if enemies and common.IsValidTarget(enemies) then
			local hp = common.GetShieldedHealth("ap", enemies)
			if menu.killsteal.qks:get() then
				if
					player:spellSlot(0).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < qSpell.range and
						dmgl.GetSpellDamage(0, enemies) > hp
				 then
					player:castSpell("obj", 0, enemies)
				end
			end
			if menu.killsteal.wks:get() then
				if
					player:spellSlot(1).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < wSpell.range and
						dmgl.GetSpellDamage(1, enemies) > hp
				 then
					player:castSpell("obj", 1, enemies)
				end
			end
			if menu.killsteal.rks:get() then
				if
					player:spellSlot(3).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < rSpell.range and
						dmgl.GetSpellDamage(3, enemies) > hp
				 then
					player:castSpell("obj", 3, enemies)
				end
			end
		end
	end
end
local function OnTick()
	KillSteal()
	if orb.combat.is_active() then Combo() end
	if menu.keys.harasskey:get() then Harass() end
	if menu.keys.clearkey:get() then JungClear() end
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