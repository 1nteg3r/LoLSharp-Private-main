local common = module.load("int", "Library/util");
local dmgl = module.load('int', 'Library/damageLib');
local ts = module.internal("TS")
local orb = module.load("int", "Orbwalking/Orb");
local gpred = module.internal("pred")

local qSpell = {range = 300}
local wSpell = {range = 1000} 
local eSpell = {range = 650}
local rSpell = {range = 375}
local fallowr = {range = 5}
local QlDmg = {65, 90, 115, 140, 165}
local ElDmg = {70, 95, 120, 145, 170}
local RlDmg = {80, 120, 160}

local menu = menu("int", "Int Wukong")
menu:header("serdar", "Core")

menu:menu("combo", "Combo")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:boolean("rcombo", "Use R", true)
menu.combo:boolean("wgap", "Use W Gapcloser", true)
menu.combo:slider("mine", "Min. E Range", 250, 0, 650,650)
menu.combo:boolean("turret", "Don't Use E Under the Turret", true)
menu.combo:slider("saver", "Use R Enemy Health %", 10, 1, 100, 30)
menu.combo:slider("hitr", "Min Enemy Use R", 1, 0, 5, 1)
menu.combo:boolean("follow", "Auto Follow To Enemy R ", true)
menu.combo:boolean("items", "Use Items", true)

menu:menu("harass", "Harass")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("autoq", "Use Auto Q", true)
menu.harass:boolean("eharass", "Use E", true)
menu.harass:slider("mine", "Min. E Range", 250, 0, 650,650)
menu.harass:boolean("turret", "Don't Use E Under the Turret", true)
menu.harass:boolean("items", "Use Items", true)
menu.harass:slider("hmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("lasthit", "LastHit")
menu.lasthit:boolean("qlasthit", "Use Q in LastHit", true)
menu.lasthit:slider("lmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("killsteal", "Killsteal")
menu.killsteal:boolean("useks", "Use Killsteal Active", true)
menu.killsteal:boolean("qks", "Use Q in Killsteal", true)
menu.killsteal:boolean("eks", "Use E in Killsteal", true)

menu:menu("laneclear", "LaneClear")
menu.laneclear:boolean("farmq", "Use Q", true)
menu.laneclear:boolean("farme", "Use E", false)
menu.laneclear:slider("lmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("jungclear", "JungClear")
menu.jungclear:boolean("jungq", "Use Q", true)
menu.jungclear:boolean("junge", "Use E", true)
menu.jungclear:slider("jmana", "Mana Manager", 30, 0, 100, 30)

menu:menu("draws", "Display")
menu.draws:boolean("drawq", "Q Range", true)
menu.draws:boolean("draww", "W Range", true)
menu.draws:boolean("drawe", "W Range", true)
menu.draws:boolean("drawr", "R Range", true)

menu:menu("keys", "Keys")
menu.keys:keybind("combokey", "Combo", "Space", nil)
menu.keys:keybind("clearkey", "Clear", "V", nil)
menu.keys:keybind("harasskey", "Harass", "C", nil)
menu.keys:keybind("lasthitkey", "Lasthit", "X", nil)
menu.keys:keybind("fleekey", "Flee", "Z", nil)
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
	if dist > 470 then return end
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
local function rsay(func)
	return ts.get_result(TargetSelectionR).obj
end


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
	if player:spellSlot(2).state == 0 and player.pos:dist(target.pos) < eSpell.range 
		then player:castSpell("obj", 2 ,target)
	end
end
local function CastR(target)
	if player:spellSlot(3).state == 0 and player:spellSlot(3).name == "MonkeyKingSpinToWin" and player.pos:dist(target.pos) < rSpell.range 
		then player:castSpell("obj", 3 ,target)
	end
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
		if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpell.range then
			if menu.combo.turret:get() and not common.IsUnderEnemyTower(vec3(target.x, target.y, target.z)) then
				if player.pos:dist(target.pos) <= menu.combo.mine:get()
				    then CastE(target)
				end
			end
		end
		if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)			 		 				 
		end
		if menu.combo.wcombo:get() and player:spellSlot(1).state == 0 and player.pos:dist(target.pos) <= wSpell.range 
			then CastW(target)				 				 
		end	
		if menu.combo.rcombo:get() and menu.combo.follow:get() and (enemy.health / enemy.maxHealth) * 100 >= menu.combo.saver:get() and menu.combo.hitr:get() <= #count_enemies_in_range(target.pos, 400) and player:spellSlot(3).state == 0 and player.pos:dist(target.pos) <= fallowr.range
				then CastR(target)
					 player:move(target)
				elseif menu.combo.rcombo:get() and not menu.combo.follow:get() 
				then  CastR(target)
					player:castSpell("pos", FlashSlot, target.pos)
		end						
	end	
end
end 	 
end	
local function Harass()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then
		if menu.harass.eharass:get() and menu.keys.harasskey:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpell.range then
			if menu.harass.turret:get() and not common.IsUnderEnemyTower(vec3(target.x, target.y, target.z)) then
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
				if minionPos:dist(player.pos) <= qSpell.range then
					CastQ(minion)
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
					CastE(minion)
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
		if menu.laneclear.farme:get() and menu.keys.clearkey:get() then
			local enemyMinionsE = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsE) do
				if minion and not minion.isDead and common.IsValidTarget(minion) then
				local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= qSpell.range then
						CastE(minion)
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
		if menu.harass.autoq:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)
				 CastQ(target)		 
		end	
	end
end

local function OnTick()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then	
		if menu.combo.wgap:get() and player.pos:dist(target.pos) < 300 then
			CastW(target)
		end
	end
	if menu.killsteal.useks:get() then KillSteal() end
	if orb.combat.is_active() then Combo() end
	if menu.keys.harasskey:get() then Harass() end
	if menu.keys.clearkey:get() then JungClear() end
	if menu.keys.clearkey:get() then LaneClear() end
	if menu.harass.autoq:get() then AutoQ() end
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