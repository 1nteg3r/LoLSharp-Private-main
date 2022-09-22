local common = module.load("int", "Library/util");
local dmgl = module.load('int', 'Library/damageLib');
local ts = module.internal("TS")
local orb = module.internal("orb");
local gpred = module.internal("pred")

local qSpell = {range = 200}
local wSpell = {range = 900}
local eSpell = {range = 1000}
local rSpell = {range = 650}
local QlDmg = {20, 40, 60, 80, 100}

local menu = menu("int", "Int Trundle")
menu:header("serdar", "Core")

menu:menu("combo", "Combo")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:boolean("items", "Use Items", true)
menu.combo:header("esett", "-- E Settings --")
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:slider("emin", "Min. Distance Use", 800, 300, 1000, 1)
menu.combo:header("esett", "-- R Settings --")
menu.combo:boolean("rcombo", "Use R", true)
menu.combo:slider("hpr", "Use R My Min Health  %", 65, 1, 100, 1)
	
menu:menu("harass", "Harass")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("autoq", "Use Auto Q", true)
menu.harass:boolean("eharass", "Use E", true)
menu.harass:boolean("items", "Use Items", true)
menu.harass:slider("hmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("lasthit", "LastHit")
menu.lasthit:boolean("useq", "Use Q to Last Hit", true)
menu.lasthit:slider("mana", "Mana Manager", 30, 0, 100, 30)

menu:menu("laneclear", "LaneClear Settings")
menu.laneclear:boolean("farmq", "Use Q", true)
menu.laneclear:boolean("farmw", "Use W", false)
menu.laneclear:boolean("farme", "Use E", true)
menu.laneclear:boolean("farmt", "Use Tiamat", true)
menu.laneclear:slider("lmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("jungclear", "JungClear Settings")
menu.jungclear:boolean("jungq", "Use Q", true)
menu.jungclear:boolean("jungw", "Use W", false)
menu.jungclear:boolean("junge", "Use E", true)
menu.jungclear:boolean("jungt", "Use Tiamat", true)
menu.jungclear:slider("jmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("killsteal", "Killsteal")
menu.killsteal:boolean("useks", "Use Killsteal Active", true)
menu.killsteal:boolean("qks", "Use Q in Killsteal", true)
menu.killsteal:boolean("wks", "Use W in Killsteal", true)
menu.killsteal:boolean("eks", "Use E in Killsteal", true)

menu:menu("draws", "Display")
menu.draws:boolean("drawq", "Q Range", true)
menu.draws:boolean("draww", "W Range", true)
menu.draws:boolean("drawe", "E Range", true)
menu.draws:boolean("drawr", "R Range", true)

menu:menu("misc", "Misc")
menu.misc:header("esett", "-- Interrupt Settings --")
menu.misc:boolean("inter", "Use E Interupt", true)
menu.misc:boolean("antigap", "Use E Anti Gapcloser", true)

menu:menu("keys", "Keys")
menu.keys:keybind("combokey", "Combo", "Space", nil)
menu.keys:keybind("clearkey", "Clear", "V", nil)
menu.keys:keybind("harasskey", "Harass", "C", nil)
menu.keys:keybind("lasthitkey", "Lasthit", "X", nil)
menu.keys:keybind("fleee", "Flee", "G", nil)

ts.load_to_menu();

local TargetSelection = function(res, obj, dist)
	if dist < rSpell.range then
		res.obj = obj
		return true
	end
end
local GetTarget = function()
	return ts.get_result(TargetSelection).obj
end
local function select_target(res, obj, dist)
	if dist > 1000 then return end
	res.obj = obj
	return true
end
local function Tiamat(target)
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
local function get_target(func)
	return ts.get_result(func).obj
end
local function qHesap(target)
	local qDamage = QlDmg[player:spellSlot(0).level] + (common.GetTotalAD() * 0.2)
	return common.CalculateMagicDamage(target, qDamage)
end

local wp = { delay = 0.25,  radius = 1000, speed = math.huge, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local ep = { delay = 0.25,  radius = 375, speed = math.huge, boundingRadiusMod = 1, collision = { hero = false, minion = false } }

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
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1000 * 1000) then
		local ser = gpred.circular.get_prediction(ep, target)
		local EndPosition = player.pos + (target.pos - player.pos):norm() * (100);
		if ser and ser.startPos:dist(ser.endPos) < 1000 then
			player:castSpell("pos", 2, EndPosition)
		end
	end
end
local function CastR(target)
	if player:spellSlot(3).state == 0 and player.pos:dist(target.pos) < rSpell.range 
		then player:castSpell("obj", 3 ,target)
	end
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

orb.combat.register_f_after_attack(
	function()
		if menu.keys.combokey:get() or menu.keys.harasskey:get() then
			if orb.combat.target then
				if
					menu.combo.items:get() and orb.combat.target and common.IsValidTarget(orb.combat.target) and
						player.pos:dist(orb.combat.target.pos) < common.GetAARange(orb.combat.target)
				 then
					for i = 6, 11 do
						local item = player:spellSlot(i).name
						if item and (item == "ItemTitanicHydraCleave" or item == "ItemTiamatCleave") and player:spellSlot(i).state == 0 then
							player:castSpell("obj", i, player)
							orb.core.set_server_pause()
							orb.combat.set_invoke_after_attack(false)
							player:attack(orb.combat.target)
							orb.core.set_server_pause()
							orb.combat.set_invoke_after_attack(false)
							return "on_after_attack_hydra"
						end
					end
				end
			end
		end
	end
)

local function Combo()
local target = get_target(select_target)
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
		if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= menu.combo.emin:get()
			then CastE(target)
		end		
		if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range
			then CastQ(target)
		end	
		if menu.combo.wcombo:get() and player:spellSlot(1).state == 0 and player.pos:dist(target.pos) <= wSpell.range
			then CastW(target)
		end
		if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 and player.pos:dist(target.pos) <= rSpell.range and
			(player.health / player.maxHealth * 100) <= menu.combo.hpr:get() 
			then CastR(target)
		end	
		
	end	 
end	
local function Harass()	
	if common.GetPercentPar() >= menu.harass.hmana:get() then
		local target = get_target(select_target)
		if target and common.IsValidTarget(target) then
				if menu.harass.items:get() then
			if (target.pos:dist(player) <= 500) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item and (item == "RanduinsOmen") then
						player:castSpell("obj", i, target)
					end
				end
			end
		end
		if menu.harass.items:get() and menu.keys.harasskey:get() then
			if (target.pos:dist(player) <= 1000) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item and (item == "YoumusBlade") then
						player:castSpell("obj", i, target)
					end
				end
			end
		end
		if menu.harass.items:get() and menu.keys.harasskey:get() then
			if (target.pos:dist(player) <= 750) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item and (item == "HextechGunblade") then
						player:castSpell("obj", i, target)
					end
				end
			end
		end
		if menu.harass.items:get() and menu.keys.harasskey:get() then
			if (target.pos:dist(player) <= 650) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item and (item == "ItemSwordOfFeastAndFamine") then
						player:castSpell("obj", i, target)
					end
				end
			end
		end
			if menu.harass.qharass:get() and menu.keys.harasskey:get() then
				if (target.pos:dist(player) < qSpell.range) 
					then CastQ(target)
				end
			end
			if menu.harass.eharass:get() and menu.keys.harasskey:get() then
				if player.pos:dist(target.pos) <= menu.combo.emin:get()
					then CastE(target)
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
					Tiamat(minion)					
				end
				if minionPos:dist(player.pos) <= wSpell.range then
					CastW(minion)
					Tiamat(minion)					
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
					Tiamat(minion)
					end
					if minionPos:dist(player.pos) <= wSpell.range then
					CastW(minion)
					Tiamat(minion)					
					end
				end	
			end
		end
	end			
end
local function LastHit()
	if (player.mana / player.maxMana) * 100 >= menu.lasthit.mana:get() then
		if menu.lasthit.useq:get() then
			local enemyMinions = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinions) do
				if
				minion and not minion.isDead and minion.isVisible and player.pos:dist(minion.pos) < qSpell.range and
				dmglib.GetSpellDamage(0, minion) >= minion.health then
					player:castSpell("obj", 0, minion)
				end
			end
		end
	end
end
local function AutoQ()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then	
		if menu.harass.autoq:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)			 
		end	
	end
end
local function Flee()
local target = get_target(select_target)
	player:move(vec3(mousePos.x, mousePos.y, mousePos.z))
	if target and common.IsValidTarget(target) then	
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1000 * 1000) then
		local ser = gpred.circular.get_prediction(ep, target)
		local EndPosition = player.pos + (target.pos - player.pos):norm() * ((target.pos- player.pos):len() - 100);
		if ser and ser.startPos:dist(ser.endPos) < 1000 then
			player:castSpell("pos", 2, EndPosition)
		end
	end
	end
end


local function OnTick()
	if orb.combat.is_active() then Combo() end
	if menu.keys.harasskey:get() then Harass() end
	if menu.harass.autoq:get() then AutoQ() end
	if menu.keys.lasthitkey:get() then LastHit() end
	if menu.keys.clearkey:get() then JungClear() end	
	if menu.keys.clearkey:get() then LaneClear() end
	if menu.keys.fleee:get() then Flee() end
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