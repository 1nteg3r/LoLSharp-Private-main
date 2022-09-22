local common = module.load("int", "Library/util");
local dmgl = module.load('int', 'Library/damageLib');
local ts = module.internal("TS")
local orb = module.internal("orb");
local gpred = module.internal("pred")

local qSpell = {range = 600}
local wSpell = {range = 265} 
local eSpell = {range = 850}
local rSpell = {range = 1700}

local QlDmg = {65, 90, 115, 140, 165}
local ElDmg = {70, 95, 120, 145, 170}
local RlDmg = {80, 120, 160}

local menu = menu("intennerRumble", "Int Rumble")
menu:header("serdar", "Core")

menu:menu("combo", "Combo")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:boolean("rcombo", "Use R", true)

menu.combo:slider("autow", "Auto W Heat >", 30, 0, 100, 1)
menu.combo:slider("mine", "Don't Use E Heat >", 80, 0, 100, 1)
menu.combo:slider("hitr", "Min Enemy Use R", 2, 0, 5, 1)
menu.combo:slider("hpr", "Don't Use R if Enemy Health <=", 40, 1, 100, 1)
menu.combo:boolean("items", "Use Items", true)


menu:menu("harass", "Harass")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("wharass", "Use W", true)
menu.harass:boolean("eharass", "Use E", true)
menu.harass:boolean("items", "Use Items", true)
menu.harass:slider("hmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("killsteal", "Killsteal")
menu.killsteal:boolean("qks", "Use Q in Killsteal", true)
menu.killsteal:boolean("wks", "Use W in Killsteal", true)
menu.killsteal:boolean("rks", "Use R in Killsteal", false)

menu:menu("laneclear", "LaneClear")
menu.laneclear:boolean("farmq", "Use Q", true)
menu.laneclear:slider("minq", "Min Minions to use in LaneClear", 3, 1, 6, 1)
menu.laneclear:boolean("farme", "Use E", true)
menu.laneclear:slider("lmana", "Heat Manager", 30, 0, 100, 70)

menu:menu("jungclear", "JungClear")
menu.jungclear:boolean("jungq", "Use Q", true)
menu.jungclear:boolean("junge", "Use E", false)
menu.jungclear:slider("jmana", "Heat Manager", 30, 0, 100, 70)

menu:menu("draws", "Display")
menu.draws:boolean("drawq", "Draw Q Range", true)
menu.draws:boolean("draww", "Draw W Range", true)
menu.draws:boolean("drawe", "Draw W Range", true)
menu.draws:boolean("drawr", "Draw R Range", true)

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

local function get_target(func)
	return ts.get_result(func).obj
end

local ep = { delay = 0.25, width = 70, speed = 2000, boundingRadiusMod = 1, collision = true }
local rp = { delay = 0.583, width = 130, speed = 1600, boundingRadiusMod = 1, collision = false }

local function CastQ(target)
	if player:spellSlot(0).state == 0 and player.pos:dist(target.pos) < qSpell.range 
		then player:castSpell("obj", 0 ,target)
	end
end

local function CastW(target)
	if player:spellSlot(1).state == 0 and player.pos:dist(target.pos) < wSpell.range 
		then player:castSpell("obj", 1 ,target)
	end
end

local function CastE(target)
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (850 * 850) then
		local ser = gpred.linear.get_prediction(ep, target)
		if ser and ser.startPos:dist(ser.endPos) < 900 then
			player:castSpell("pos", 2, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end

local function CastR(target)
	if player:spellSlot(3).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1700 * 1700) then
		local ser = gpred.linear.get_prediction(ep, target)
		if ser and ser.startPos:dist(ser.endPos) < 1700 then
		local c = target.pos
		local l = 130
		local r = 300
		local f = -300
		local s = 1600
		for i = 0, l, 1 do
		local _X = c.x - 50
		local _Z = c.z + 100 
		local RPOS = vec3(_X, 0, _Z)
		
			player:castSpell("pos", 3, RPOS)
		end
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
		if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpell.range and
			(player.mana / player.maxMana) * 100 <= menu.combo.mine:get()	
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
			(target.health / target.maxHealth * 100) <= menu.combo.hpr:get() and
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
if (player.mana / player.maxMana) * 100 <= menu.jungclear.jmana:get() then	
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
	if menu.jungclear.junge:get() and menu.keys.clearkey:get() then	
		local enemyMinionsE = common.GetMinionsInRange(eSpell.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsE) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= eSpell.range then
					CastE(minion)
				end
			end
		end
	end
end
end

local function LaneClear()
if (player.mana / player.maxMana) * 100 <= menu.jungclear.jmana:get() then	
	if menu.laneclear.farmq:get() and menu.keys.clearkey:get() then	
		local minions = objManager.minions
    	for i = 0, minions.size[TEAM_ENEMY] - 1 do
     	 local minion1 = minions[TEAM_ENEMY][i]
      	if minion1 and not minion1.isDead and minion1.isVisible then
        	local dist = player.path.serverPos:distSqr(minion1.path.serverPos)
        	if dist <= 810000 then
          	local hit = 0
          	for i = 0, minions.size[TEAM_ENEMY] - 1 do
           	 local minion2 = minions[TEAM_ENEMY][i]
            	if minion2 then
              	if minion2.ptr == minion1.ptr then
                hit = hit + 1
             	 end
              	if minion2.ptr ~= minion1.ptr and not minion2.isDead and minion2.isVisible then
                	local dist = minion1.path.serverPos:distSqr(minion2.path.serverPos)
                	if dist <= 40000 then
                 	 hit = hit + 1
               	 end
             	end
            	end
          	end
         	 if hit >= menu.laneclear.minq:get() then
            player:castSpell("pos", 0, minion1.pos)
            break
         	 end
        	end
      	end
    	end
	end
	if menu.laneclear.farme:get() and menu.keys.clearkey:get() then
		local enemyMinionsE = common.GetMinionsInRange(eSpell.range, TEAM_ENEMY)
		for i, minion in pairs(enemyMinionsE) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
			local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= eSpell.range then
					CastE(minion)
				end
			end	
		end
	end
end	
end
local function KillSteal()
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
		if enemies and common.IsValidTarget(enemies) and not enemies.buff[17] then
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
local function AutoW()
local target = get_target(select_target)
if target and common.IsValidTarget(target) then	
	if (player.mana / player.maxMana) * 100 <= menu.combo.autow:get() and player.pos:dist(target.pos) <= eSpell.range then
		player:castSpell("self", 1)
	end
end
end

local function OnTick()
	KillSteal()
	if menu.combo.autow:get() then AutoW() end
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