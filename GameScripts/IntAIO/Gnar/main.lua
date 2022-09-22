local common = module.load("int", "Library/util");
local dmgl = module.load('int', 'Library/damageLib');
local ts = module.internal("TS")
local orb = module.internal("orb");
local gpred = module.internal("pred")

local qSpell = {range = 1100}
local qSpellr = {range = 3000}
local eSpell = {range = 475} 
local qSpellm = {range = 1100}
local wSpellm = {range = 550}
local eSpellm = {range = 600}
local rSpell = {range = 475}

local QlDmgt = {65, 90, 115, 140, 165}
local ElDmgt = {70, 95, 120, 145, 170}

local QlDmgm = {65, 90, 115, 140, 165}
local WlDmgm = {65, 90, 115, 140, 165}
local ElDmgm = {70, 95, 120, 145, 170}
local RlDmgm = {65, 90, 115, 140, 165}


local menu = menu("IntnnerGnar", "Int Gnar")
menu:header("serdar", "Core")

menu:menu("combo", "Combo")
menu.combo:header("tiny", "-- Tiny Gnar --")
menu.combo:boolean("qcombot", "Use Q", true)
menu.combo:boolean("ecombot", "Use E", true)
menu.combo:slider("ehpt", " Use E if Enemy Health % ", 30, 0, 100, 30)
menu.combo:boolean("turrett", "Don't Use E Under the Turret", true)

menu.combo:header("mega", "-- Mega Gnar --")
menu.combo:boolean("qcombom", "Use Q", true)
menu.combo:boolean("wcombom", "Use W", true)
menu.combo:boolean("ecombom", "Use E", true)
menu.combo:boolean("rcombo", "Use R", true)
menu.combo:slider("ehpm", "Use E if Enemy Health % ", 30, 0, 100, 30)
menu.combo:boolean("turretm", "Don't Use E Under the Turret", true)
menu.combo:slider("hitr", "Min Enemy Use R", 1, 0, 5, 1)
menu.combo:slider("autor", "Auto R Min Enemy ", 1, 0, 5, 3)
menu.combo:boolean("items", "Use Items", true)

menu:menu("harass", "Harass")
menu.harass:header("tiny", "-- Tiny Gnar --")
menu.harass:boolean("qharasst", "Use Q", true)
menu.harass:boolean("autoq", "Use Auto Q", true)
menu.harass:boolean("eharasst", "Use E", true)
menu.harass:boolean("turrett", "Don't Use E Under the Turret", true)
menu.harass:header("tiny", "-- Mega Gnar --")
menu.harass:boolean("qharassm", "Use Q", true)
menu.harass:boolean("wharassm", "Use W", true)
menu.harass:boolean("eharassm", "Use E", true)
menu.harass:boolean("turretm", "Don't Use E Under the Turret", true)

menu:menu("laneclear", "LaneClear")
menu.laneclear:header("tiny", "-- Tiny Gnar --")
menu.laneclear:boolean("farmqt", "Use Q", true)
menu.laneclear:boolean("farmet", "Use E", false)
menu.laneclear:header("tiny", "-- Mega Gnar --")
menu.laneclear:boolean("farmqm", "Use Q", true)
menu.laneclear:boolean("farmwm", "Use W", true)
menu.laneclear:boolean("farmem", "Use E", false)
menu.laneclear:slider("lmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("jungclear", "JungClear")
menu.jungclear:header("tiny", "-- Tiny Gnar --")
menu.jungclear:boolean("jungqt", "Use Q to Jung", true)
menu.jungclear:boolean("junget", "Use E to Jung", false)
menu.jungclear:header("tiny", "-- Mega Gnar --")
menu.jungclear:boolean("jungqm", "Use Q to Jung", true)
menu.jungclear:boolean("jungwm", "Use W to Jung", true)
menu.jungclear:boolean("jungem", "Use E to Jung", true)
menu.jungclear:slider("jmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("killsteal", "Killsteal")
menu.killsteal:boolean("useks", "Use Killsteal Active", true)
menu.killsteal:boolean("qks", "Use Q in Killsteal", true)
menu.killsteal:boolean("eks", "Use E in Killsteal", true)

menu:menu("draws", "Display")
menu.draws:boolean("drawqt", "Tinny Q Range", true)
menu.draws:boolean("drawet", "Tinny E Range", true)
menu.draws:boolean("drawqm", "Mega Q Range", true)
menu.draws:boolean("drawwm", "Mega W Range", true)
menu.draws:boolean("drawem", "Mega E Range", true)
menu.draws:boolean("drawrm", "Mega R Range", true)

menu:menu("keys", "Keys")
menu.keys:keybind("combokey", "Combo", "Space", nil)
menu.keys:keybind("clearkey", "Clear", "V", nil)
menu.keys:keybind("harasskey", "Harass", "C", nil)
menu.keys:keybind("lasthitkey", "Lasthit", "X", nil)
ts.load_to_menu();

local TargetSelection = function(res, obj, dist)
	if dist < qRange.range then
		res.obj = obj
		return true
	end
end
local function select_target(res, obj, dist)
	if dist > 1100 then return end
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


local qpt = { delay = 0.25, width = 55, speed = 1700, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local qprt = { delay = 0.25, width = 70, speed = 1700, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local ept = { delay = 0.25, radius = 160, speed = 900, boundingRadiusMod = 1, collision = { hero = false, minion = false } }

local qpm = { delay = 0.50, width = 90, speed = 2100, boundingRadiusMod = 1, collision = { hero = false, minion = true } }
local wpm = { delay = 0.60, radius = 125, speed = math.huge, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local epm = { delay = 0.25, radius = 375, speed = 800, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local rpm = { delay = 0.25, width = 475, speed = math.huge, boundingRadiusMod = 1, collision = { hero = false, minion = false } }


local function qHesapt(target)
	local qDamage = QlDmg[player:spellSlot(0).level] + (common.GetTotalAP() * .4)  
	return common.CalculateMagicDamage(target, qDamage)
end
local function qHesaprt(target)
	local qDamage = QlDmg[player:spellSlot(0).level] + (common.GetTotalAP() * .4)  
	return common.CalculateMagicDamage(target, qDamage)
end
local function qHesapm(target)
	local wDamage = QlDmg[player:spellSlot(1).level] + (common.GetTotalAP() * .5)
	return common.CalculateMagicDamage(target, wDamage)
end
local function wHesapm(target)
	local wDamage = QlDmg[player:spellSlot(1).level] + (common.GetTotalAP() * .5)
	return common.CalculateMagicDamage(target, wDamage)
end
local function eHesapm(target)
	local wDamage = QlDmg[player:spellSlot(1).level] + (common.GetTotalAP() * .5)
	return common.CalculateMagicDamage(target, wDamage)
end
local function rHesapm(target)
	local wDamage = QlDmg[player:spellSlot(1).level] + (common.GetTotalAP() * .5)
	return common.CalculateMagicDamage(target, wDamage)
end

local function CreateObj(object)
	if object and object.name then
		if object.name:find("GnarQReturn") then
			objHolder[object.ptr] = object
		end
	end
end
local function DeleteObj(object)
	if object and object.name then
		if object.name:find("GnarQReturn") then
			objHolder[object.ptr] = object
		end
	end
end

local function CastQt(target)
	if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GnarQ" and player.path.serverPos:distSqr(target.path.serverPos) < (1100 * 1100) then
		local ser = gpred.linear.get_prediction(qpt, target)
		if ser and ser.startPos:dist(ser.endPos) < 1100 then
			player:castSpell("pos", 0, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
			--player:move("GnarQReturn")
		end
	end
end
local function CastEt(target)
	if player:spellSlot(2).state == 0 and player:spellSlot(2).name == "GnarE" and player.path.serverPos:distSqr(target.path.serverPos) < (475 * 475) then
		local ser = gpred.linear.get_prediction(qpm, target)
		if ser and ser.startPos:dist(ser.endPos) < 475 then
			player:castSpell("pos", 2, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end



local function CastQm(target)
	if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GnarBigQ" and player.path.serverPos:distSqr(target.path.serverPos) < (1100 * 1100) then
		local ser = gpred.linear.get_prediction(qpm, target)
		if ser and ser.startPos:dist(ser.endPos) < 1100 then
			player:castSpell("pos", 0, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end   
local function CastWm(target)
	if player:spellSlot(1).state == 0 and player:spellSlot(1).name == "GnarBigW" and player.path.serverPos:distSqr(target.path.serverPos) < (550 * 550) then
		local ser = gpred.circular.get_prediction(wpm, target)
		if ser and ser.startPos:dist(ser.endPos) < 550 then		
			player:castSpell("pos", 1, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end 
local function CastEm(target)
	if player:spellSlot(2).state == 0 and player:spellSlot(2).name == "GnarBigE" and player.path.serverPos:distSqr(target.path.serverPos) < (600 * 600) then
		local ser = gpred.circular.get_prediction(epm, target)
		if ser and ser.startPos:dist(ser.endPos) < 600 then
			player:castSpell("pos", 2, vec3(ser.endPos.x, game.mousePos.y, ser.endPos.y))
		end
	end
end  
local function CastR(target)
	if player:spellSlot(3).state == 0 and player:spellSlot(3).name == "GnarR" and player.path.serverPos:distSqr(target.path.serverPos) < (300 * 300) then
		local ser = gpred.linear.get_prediction(rpm, target)
		local c = player.pos
		local p = 36
		local r = 300
		local s = 2 * math.pi / p

	for i = 0, p, 1 do
		local angle = s * i
		local _X = c.x + r * math.cos(angle)
		local _Z = c.z + r * math.sin(angle)
		local RPOS = vec3(_X, 0, _Z)

		if navmesh.isWall(RPOS) then
		  		player:castSpell("pos", 3, RPOS)
		end
	end
	end
end  

local function Combo()
local target = get_target(select_target)
for i = 0, objManager.enemies_n - 1 do
local enemy = objManager.enemies[i]
if enemy and common.IsValidTarget(enemy) and menu.killsteal.useks:get() then
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
		if menu.combo.qcombot:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range then
			CastQt(target)
		end	
		if menu.combo.ecombot:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= (475 * 475) and 
			(target.health / target.maxHealth * 100) <= menu.combo.ehpt:get() then
			if menu.combo.turrett:get() and not common.UnderDangerousTower(vec3(target.x, target.y, target.z))
			 	then CastEt(target)
			end
		end	
		if menu.combo.qcombom:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpellm.range 
			then CastQm(target)
		end			
		if menu.combo.wcombom:get() and player:spellSlot(1).state == 0 and player.pos:dist(target.pos) <= wSpellm.range
			then CastWm(target)
		end	
		if menu.combo.ecombom:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpellm.range and 
			(target.health / target.maxHealth * 100) <= menu.combo.ehpm:get() then
			if menu.combo.turretm:get() and not common.UnderDangerousTower(vec3(target.x, target.y, target.z))
				then CastEm(target)
			end
		end	
		if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 and menu.combo.hitr:get() <= #count_enemies_in_range(target.pos, 400) and player.pos:dist(target.pos) <= (300 * 300 )
				then CastR(target)
		end					
	end	
end
end 	 
end


local function Harass()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then
		if menu.harass.qharasst:get() and menu.keys.harasskey:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range then
			CastQt(target)
		end
		if (target.health / target.maxHealth * 100) <= menu.combo.ehpt:get() then
		if menu.harass.eharasst:get() and menu.keys.harasskey:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= (475 * 475) then
			if menu.harass.turrett:get() and not common.UnderDangerousTower(vec3(target.x, target.y, target.z))
			 	then CastEt(target)
			end
		end	
		end
		if menu.harass.qharassm:get() and menu.keys.harasskey:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpellm.range 
			then CastQm(target)
		end			
		if menu.harass.wharassm:get() and menu.keys.harasskey:get() and player:spellSlot(1).state == 0 and player.pos:dist(target.pos) <= wSpellm.range
			then CastWm(target)
		end	
		if (target.health / target.maxHealth * 100) <= menu.combo.ehpm:get() then
		if menu.harass.eharassm:get() and menu.keys.harasskey:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpellm.range then
			if menu.harass.turretm:get() and not common.UnderDangerousTower(vec3(target.x, target.y, target.z))
				then CastEm(target)
			end
		end	
		end
	end			
end
local function JungClear()
if (player.mana / player.maxMana) * 100 >= menu.jungclear.jmana:get() then	
	if menu.jungclear.jungqt:get() and menu.keys.clearkey:get() then	
		local enemyMinionsQ = common.GetMinionsInRange(qSpell.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsQ) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= qSpell.range then
					CastQt(minion)
				end
			end
		end
	end
	if menu.jungclear.jungqt:get() and menu.keys.clearkey:get() then	
		local enemyMinionsE = common.GetMinionsInRange(eSpell.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsE) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= eSpell.range then
					CastEt(minion)
				end
			end
		end
	end
	if menu.jungclear.jungqm:get() and menu.keys.clearkey:get() then	
		local enemyMinionsQ = common.GetMinionsInRange(qSpellm.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsQ) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= qSpellm.range then
					CastQm(minion)
				end
			end
		end
	end
	if menu.jungclear.jungwm:get() and menu.keys.clearkey:get() then	
		local enemyMinionsW = common.GetMinionsInRange(wSpellm.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsW) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= wSpellm.range then
					CastWm(minion)
				end
			end
		end
	end
	if menu.jungclear.jungem:get() and menu.keys.clearkey:get() then	
		local enemyMinionsE = common.GetMinionsInRange(eSpellm.range, TEAM_NEUTRAL)
		for i, minion in pairs(enemyMinionsE) do
			if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				if minionPos:dist(player.pos) <= eSpellm.range then
					CastEm(minion)
				end
			end
		end
	end
end
end
local function LaneClear()
	if (player.mana / player.maxMana) * 100 >= menu.laneclear.lmana:get() then
		if menu.laneclear.farmqt:get() and menu.keys.clearkey:get() then
			local enemyMinionsQ = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsQ) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= qSpell.range then
						CastQt(minion)
					end
				end	
			end
		end
		if menu.laneclear.farmet:get() and menu.keys.clearkey:get() then
			local enemyMinionsE = common.GetMinionsInRange(eSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsE) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= eSpell.range then
						CastEt(minion)
					end
				end	
			end
		end	
		if menu.laneclear.farmqm:get() and menu.keys.clearkey:get() then
			local enemyMinionsQ = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsQ) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= qSpell.range then
						CastQm(minion)
					end
				end	
			end
		end	
		if menu.laneclear.farmwm:get() and menu.keys.clearkey:get() then
			local enemyMinionsW = common.GetMinionsInRange(wSpellm.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsW) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= wSpellm.range then
						CastWm(minion)
					end
				end	
			end
		end	
		if menu.laneclear.farmem:get() and menu.keys.clearkey:get() then
			local enemyMinionsE = common.GetMinionsInRange(eSpellm.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsE) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= eSpellm.range then
						CastEm(minion)
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

				if menu.killsteal.eks:get() and menu.killsteal.useks:get() then
				if	player:spellSlot(2).state == 0 and c < eSpell.range and
				dmgl.GetSpellDamage(2, enemies) > hp
				then CastE(enemy)
				end
			end
		end
	end
end
local function AutoQ()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then	
		if menu.harass.autoq:get() and player:spellSlot(0).state == 0 and player:spellSlot(0).name == "GnarQ" and player.pos:dist(target.pos) <= qSpell.range 
			then CastQt(target)	 
		end	
	end
end
local FlashSlot = nil
if player:spellSlot(4).name == "SummonerFlash" then
	FlashSlot = 4
elseif player:spellSlot(5).name == "SummonerFlash" then
	FlashSlot = 5
end
local function AutoRf()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then	
		if menu.combo.autor:get() <= #count_enemies_in_range(target.pos, 400) and player:spellSlot(3).state == 0 and player.pos:dist(target.pos) <= (420 * 420) 
			then CastR(target)		 
			CastR(target)
		end
		if menu.combo.autor:get() <= #count_enemies_in_range(target.pos, 400) and player:spellSlot(FlashSlot).state and player:spellSlot(3).state == 0 and player.pos:dist(target.pos) >= 950 then
			if player.pos:dist(target.pos) <= (400 * 400) then
			CastR(target)
			player:castSpell("pos", FlashSlot, target.pos)
			end
		end

	end
end
local function OnTick()
	if orb.combat.is_active() then Combo() end
	if menu.combo.autor:get() then AutoRf() end
	if menu.harass.autoq:get() then AutoQ() end
	if menu.keys.harasskey:get() then Harass() end
	if menu.keys.clearkey:get() then JungClear() end
	if menu.keys.clearkey:get() then LaneClear() end
end
local function OnDraw() 	
		if menu.draws.drawqt:get() and player:spellSlot(0).state and player:spellSlot(0).name == "GnarQ" then
      	 graphics.draw_circle(player.pos, qSpell.range, 1, graphics.argb(55, 134, 232, 50), 100)
    	end
    	if menu.draws.drawqm:get() and player:spellSlot(0).state and player:spellSlot(0).name == "GnarBigQ" then
      	 graphics.draw_circle(player.pos, qSpellm.range, 1, graphics.argb(55, 134, 232, 50), 100)
    	end
    	 if menu.draws.drawwm:get() and player:spellSlot(1).state and player:spellSlot(1).name == "GnarBigW" then
      	 graphics.draw_circle(player.pos, wSpellm.range, 1, graphics.argb(55, 134, 232, 50), 100)
    	end
    	if menu.draws.drawet:get() and player:spellSlot(2).state == 0 and player:spellSlot(2).name == "GnarE" then 
      		graphics.draw_circle(player.pos, eSpell.range, 1, graphics.argb(55, 134, 232, 50), 100)
    	end 	 	
    	if menu.draws.drawem:get() and player:spellSlot(2).state == 0 and player:spellSlot(2).name == "GnarBigE" then
      		graphics.draw_circle(player.pos, eSpellm.range , 1, graphics.argb(55, 149, 232, 50), 100)
    	end
    	if menu.draws.drawrm:get() and player:spellSlot(3).state == 0 and player:spellSlot(3).name == "GnarR" then
      		graphics.draw_circle(player.pos, rSpell.range , 1, graphics.argb(55, 149, 232, 50), 100)
      	end
    	
end 
cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
return {}