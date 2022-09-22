local common = module.load("int", "Library/util");
local dmgl = module.load('int', 'Library/damageLib');
local ts = module.internal("TS")
local orb = module.internal("orb")
local gpred = module.internal("pred")

local qSpell = {range = 315}
local wSpell = {range = 200}
local eSpell = {range = 470}
local rSpell = {range = 175}


local menu = menu("IntnnerRenekton", "Int Renekton")
menu:header("serdar", "Core")

menu:menu("combo", "Combo")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("autoq", "Use Auto Q", true)
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:boolean("e1combo", "Use E1", true)
menu.combo:boolean("e2combo", "Use E2", true)
menu.combo:boolean("gape", " ^-Use E1 Minions for Gapclose", true)
menu.combo:boolean("rcombo", "Use R", true)
menu.combo:boolean("tia", "Use Titanic Hydra", true)

menu:menu("harass", "Harass")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("eharass", "Use W", true)
menu.harass:boolean("wharass", "Use E", true)

menu:menu("killsteal", "KillSteal")
menu.killsteal:boolean("useks", "Use Killsteal", true)
menu.killsteal:boolean("ksq", "Use Q", true)
menu.killsteal:boolean("ksw", "Use W", true)
menu.killsteal:boolean("kse", "Use E", true)

menu:menu("laneclear", "LaneClear")
menu.laneclear:boolean("farmq", "Use Q", true)
menu.laneclear:boolean("farmw", "Use W", false)
menu.laneclear:boolean("farme", "Use E", false)

menu:menu("jungclear", "JungClear")
menu.jungclear:boolean("jungq", "Use Q", true)
menu.jungclear:boolean("jungw", "Use W", true)
menu.jungclear:boolean("junge", "Use E", true)

menu:menu("draws", "Display")
menu.draws:boolean("drawq", "Q Range", true)
menu.draws:boolean("draww", "W Range", true)
menu.draws:boolean("drawe", "E Range", true)
menu.draws:boolean("drawr", "R Range", true)

menu:menu("keys", "Key Settings")
menu.keys:keybind("combokey", "Combo", "Space", nil)
menu.keys:keybind("clearkey", "Clear", "V", nil)
menu.keys:keybind("harasskey", "Harass", "C", nil)

ts.load_to_menu();
local aa = false
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
	if dist > 470 then return end
	res.obj = obj
	return true
end
local function ult_target(res, obj, dist)
	if dist > 450 then return end
	res.obj = obj
	return true
end
local function Rsay()
	return ts.get_result(TargetSelectionR).obj
end
local function get_target(func)
	return ts.get_result(func).obj
end


local function LaneEnemy()
	local enemyMinions = common.GetMinionsInRange(450, TEAM_ENEMY)
	local closestMinion = nil
	local closestMinionDistance = 9999
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do	
		for i, minion in pairs(enemyMinions) do
			if minion then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(enemies) < eSpell.range then
					local minionDistanceToMouse = minionPos:dist(enemies)

					if minionDistanceToMouse < closestMinionDistance then
							closestMinion = minion
							closestMinionDistance = minionDistanceToMouse
					end
				end
		end
	end
end
	return closestMinionDistance
end
local function JungleEnemy()
	local enemyMinions = common.GetMinionsInRange(400, TEAM_NEUTRAL)
	local closestMinion = nil
	local closestMinionDistance = 9999
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
			for i, minion in pairs(enemyMinions) do
				if minion then
					local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(enemies) < eSpell.range then
						local minionDistanceToMouse = minionPos:dist(enemies)
						if minionDistanceToMouse < closestMinionDistance then
						closestMinion = minion
						closestMinionDistance = minionDistanceToMouse
					end
				end
			end
		end	
	end
	return closestMinion
end

local ep = { delay = 0.25, width = 70, speed = 1400, boundingRadiusMod = 1, collision = { hero = false, minion = false } }


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

local function Slince(target)
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (470 * 470) then
	if player:spellSlot(2).name == "RenektonSliceAndDice" then	
		local seg = gpred.linear.get_prediction(ep, target)
		if seg and seg.startPos:distSqr(seg.endPos) < (470 * 470) then
			if not gpred.collision.get_prediction(ep, seg, target) then
				player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
	end
end
local function Dice(target)
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (470 * 470) then
	if player:spellSlot(2).name == "RenektonDice" then	
		local seg = gpred.linear.get_prediction(ep, target)
		if seg and seg.startPos:distSqr(seg.endPos) < (470 * 470) then
			if not gpred.collision.get_prediction(ep, seg, target) then
				player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
	end
end
local function enemy_range(pos, range)
	local enemies_in_range = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if pos:dist(enemy.pos) < eSpell.range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

local function CastR(target)
	if player:spellSlot(3).state == 0 and player.pos:dist(target.pos) < rSpell.range 
		then player:castSpell("obj", 3 ,target)
	end
end
local function Tiamat(target)
if menu.combo.tia:get() then
	if (target.pos:dist(player) <= 175) then
	for i = 6, 11 do
		local item = player:spellSlot(i).name
		if item and (item == "ItemTitanicHydraCleave") then
			player:castSpell("obj", i, target)	
		end
		if item and (item == "ItemTiamatCleave") then
			player:castSpell("obj", i, target)		
		end
	end
	end
end
end
local minion = LaneEnemy(target)
local minions = JungleEnemy(target)
orb.combat.register_f_after_attack(
	function()
		if menu.combo.wcombo:get() and menu.combo.tia:get() then
				player:castSpell("obj", 2, player)
		end
	end )
local function Combo()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then
		if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 and player:spellSlot(1).state >= 1 and player.pos:dist(target.pos) <= eSpell.range + 20
			then CastR(target)
		end		
		if menu.combo.e1combo:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpell.range 
			then Slince(target)
				 player:attack(target)
		end
		if menu.combo.wcombo:get() and menu.combo.tia:get() and player:spellSlot(1).state == 0 and player.pos:dist(target.pos) <= wSpell.range then 
			    player:attack(target)
			    CastW(target)
			    Tiamat(target)
			    			    	 
		end

		if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)
				 
		end	
		if menu.combo.e2combo:get() and player:spellSlot(2).state == 0 and  player:spellSlot(1).state >= 5 and player.pos:dist(target.pos) <= eSpell.range then
			if player:spellSlot(0).state >= 1 then
			 player:attack(target)
			 Dice(target)
		    end
		end		
		if player:spellSlot(2).state == 0 and (target.pos:dist(player) < eSpell.range * 2) and
			(target.pos:dist(player)) > eSpell.range then 
			local minion = LaneEnemy(targets)
		if minion then
			 Slince(target)
		end	
		end					
	end	
end

local function Harass()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then
		if menu.harass.eharass:get() and menu.keys.harasskey:get() then
			if (target.pos:dist(player) < eSpell.range) 
		   		then Slince(target)
		   			 player:attack(target)

			end
		end
		if target and common.IsValidTarget(target) then
		if menu.harass.wharass:get() and menu.keys.harasskey:get() then
			if (target.pos:dist(player) < wSpell.range) then
			    CastW(target)
			    player:attack(target)			    	 
			    Tiamat(target)
			end
		end
		if menu.harass.qharass:get() and menu.keys.harasskey:get() then
			if (target.pos:dist(player) < qSpell.range) 
				then CastQ(target)
			end
		end		
		if menu.harass.eharass:get() and menu.keys.harasskey:get()then
			if (target.pos:dist(player) < eSpell.range and player:spellSlot(1).state >= 2)  
		   		then Dice(target)
			end
		end
	end
end
end
local function JungClear()
	if menu.jungclear.jungq:get() and menu.keys.clearkey:get() then	
		local enemyMinionsQ = common.GetMinionsInRange(qSpell.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsQ) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= qSpell.range then
					CastQ(minion)
					Tiamat(minion)
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
	if menu.jungclear.junge:get() and menu.keys.clearkey:get() then	
		local enemyMinionsE = common.GetMinionsInRange(qSpell.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsE) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= qSpell.range then
					Slince(minion)
					Dice(minion)
				end
			end
		end
	end
end
local function LaneClear()
		if menu.laneclear.farmq:get() and menu.keys.clearkey:get() then
			local enemyMinionsQ = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsQ) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= qSpell.range then
						CastQ(minion)
						Tiamat(minion)
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
		if menu.laneclear.farme:get() and menu.keys.clearkey:get() then
			local enemyMinionsE = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsE) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= qSpell.range then
						Slince(minion)
						Dice(minion)
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
			if menu.killsteal.ksq:get() and menu.killsteal.useks:get() then
				if	player:spellSlot(0).state == 0 and c < qSpell.range and
					dmgl.GetSpellDamage(0, enemies) > hp
					then CastQ(enemy)			
				end
				end	
				if menu.killsteal.ksw:get() and menu.killsteal.useks:get() then
				if player:spellSlot(1).state == 0 and c < wSpell.range and 
					dmgl.GetSpellDamage(1, enemies) > hp
					then CastW(enemy)
				end
				end	
				if menu.killsteal.kse:get() and menu.killsteal.useks:get() then
				if	player:spellSlot(2).state == 0 and c < eSpell.range and
				dmgl.GetSpellDamage(2, enemies) > hp
				then Slince(minion)
					 Dice(minion)
				end
			end
		end
	end
end
local function AutoQ()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then	
		if menu.combo.autoq:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)			 
		end	
	end
end

local function OnTick()
	if menu.killsteal.useks:get() then KillSteal() end
	if orb.combat.is_active() then Combo() end
	if menu.keys.harasskey:get() then Harass() end
	if menu.keys.clearkey:get() then JungClear() end
	if menu.keys.clearkey:get() then LaneClear() end
	if menu.combo.autoq:get() then AutoQ() end
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