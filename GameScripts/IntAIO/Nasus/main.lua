local common = module.load('int', 'Library/common');
local ts = module.internal("TS")
local orb = module.internal("orb")
local gpred = module.internal("pred")
local dmgl = module.load('int', 'Library/damageLib');

local qSpell = {range = 200}
local wSpell = {range = 600} 
local eSpell = {range = 650}
local rSpell = {range = 200}

local menu = menu("IntnnerNasus", "Int Nasus")
menu:header("coreeee", "Core")
menu:menu("combo", "Combo")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("wcombo", "Use W for slow", true)
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:boolean("rcombo", "Use R", true)
menu.combo:slider("hpr", "^  R -> Min. Health {0}", 70, 1, 100, 1)
menu.combo:boolean("items", "Use Items", true)

menu:menu("harass", "Harass")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("wharass", "Use W", true)
menu.harass:boolean("eharass", "Use E", true)
menu.harass:boolean("items", "Use Items", true)
menu.harass:slider("hmana", "Min. Mana {0}", 30, 0, 100, 30)

menu:menu("laneclear", "LaneClear")
menu.laneclear:boolean("farmq", "Use Q", true)
menu.laneclear:boolean("farme", "Use E", true)
menu.laneclear:slider("mine", "^ for E Min. Minions", 3, 1, 6, 1)
menu.laneclear:slider("lmana", "Min. Mana {0}", 30, 0, 100, 30)

menu:menu("jungclear", "JungClear")
menu.jungclear:boolean("jungq", "Use Q", true)
menu.jungclear:boolean("junge", "Use E ", true)
menu.jungclear:slider("jmana", "Min. Mana {0}", 30, 0, 100, 30)

menu:menu("lasthit", "LastHit")
menu.lasthit:boolean("qlasthit", "Use Q", true)
menu.lasthit:boolean("autoq", "Use Auto Q", true)
menu.lasthit:slider("lmana", "Min. Mana {0}", 30, 0, 100, 30)

menu:menu("draws", "Display")
menu.draws:boolean("draww", "W Range", true)
menu.draws:boolean("drawe", "E Range", true)

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
local QlDmg = {30, 50, 70, 90, 110}
local function qHesap()
    if not player.buff["nasusqstacks"] then return 0 end
	local base = QlDmg[player:spellSlot(0).level];
	local stack = player.buff["nasusqstacks"].stacks2;
	--local damage = player.baseAttackDamage + player.flatPhysicalDamageMod + base + stack
	return player.baseAttackDamage + player.flatPhysicalDamageMod + base + stack
end
local function get_target(func)
	return ts.get_result(func).obj
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
	if player:spellSlot(3).state == 0 and player.pos:dist(target.pos) < rSpell.range 
		then player:castSpell("obj", 3 ,target)
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
		if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 and player.pos:dist(target.pos) <= rSpell.range and
			 (player.health / player.maxHealth * 100) <= menu.combo.hpr:get() 
			then CastR(target)				 				 
		end			
		if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpell.range 
			then CastE(target)				 				 
		end			
		if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)
		end		
		if menu.combo.wcombo:get() and player:spellSlot(1).state == 0 and player.pos:dist(target.pos) <= wSpell.range 
			then CastW(target)
		end			
	end	
end
end 	 
end	
local function Harass()
local target = get_target(select_target)
	if target and common.IsValidTarget(target) then
		if menu.harass.eharass:get() and orb.menu.hybrid.key:get() and player:spellSlot(2).state == 0 and player.pos:dist(target.pos) <= eSpell.range then
			if not common.is_under_tower(vec3(target.x, target.y, target.z)) then
				if player.pos:dist(target.pos) <= menu.harass.mine:get()
				    then CastE(target)
				end
			end
		end
		if menu.harass.qharass:get() and orb.menu.hybrid.key:get() and player:spellSlot(0).state == 0 and player.pos:dist(target.pos) <= qSpell.range 
			then CastQ(target)
		end
	end
end
local function JungClear()
if (player.mana / player.maxMana) * 100 >= menu.jungclear.jmana:get() then	
	if menu.jungclear.jungq:get() and orb.menu.lane_clear.key:get()then
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
	if menu.jungclear.junge:get() and orb.menu.lane_clear.key:get() then	
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
if (player.mana / player.maxMana) * 100 >= menu.laneclear.lmana:get() then	
	if menu.laneclear.farme:get() and orb.menu.lane_clear.key:get() then	
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
         	 if hit >= menu.laneclear.mine:get() then
            player:castSpell("pos", 2, minion1.pos)
            break
         	 end
        	end
      	end
    	end
	end
	if menu.laneclear.farmq:get() and orb.menu.lane_clear.key:get() then
		local enemyMinions = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
		for i, minion in pairs(enemyMinions) do
			if minion and not minion.isDead and minion.isVisible and player.pos:dist(minion.pos) < qSpell.range and
				qHesap() >= orb.farm.predict_hp(minion, 0.31, true) then
				CastQ(minion)
				if player.buff['nasusq'] then
					player:attack(minion)
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
			--if menu.killsteal.qks:get() then
				if
					player:spellSlot(0).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < qSpell.range and
						dmgl.GetSpellDamage(0, enemies) > hp
				 then
					player:castSpell("obj", 0, enemies)
				end
			--end
			--if menu.killsteal.eks:get() then
				if
					player:spellSlot(2).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < eSpell.range and
						dmgl.GetSpellDamage(2, enemies) > hp
				 then
					player:castSpell("obj", 2, enemies)
				end
			--end
		end
	end
end
local function LastHit()
	if (player.mana / player.maxMana) * 100 >= menu.lasthit.lmana:get() then
		if menu.lasthit.qlasthit:get() and  orb.menu.last_hit.key:get() then
			local enemyMinions = common.GetMinionsInRange(qSpell.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinions) do
				if minion and not minion.isDead and minion.isVisible and player.pos:dist(minion.pos) < qSpell.range and
					qHesap() >= orb.farm.predict_hp(minion, 0.31, true) then
					CastQ(minion)
				end
			end
		end
	end
end

local function OnTick()
	KillSteal()
	if orb.menu.last_hit.key:get() then LastHit() end
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid.key:get() then Harass() end
	if orb.menu.lane_clear.key:get() then JungClear() end
	if orb.menu.lane_clear.key:get() then LaneClear() end
end


local function OnDraw()
    	if menu.draws.draww:get() and player:spellSlot(1).state == 0 then
      		graphics.draw_circle(player.pos, wSpell.range, 2, graphics.argb(55, 134, 232, 50), 100)
    	end 	 	
    	if menu.draws.drawe:get() and player:spellSlot(2).state == 0 then
      		graphics.draw_circle(player.pos, eSpell.range , 2, graphics.argb(55, 149, 232, 50), 100)
    	end	
end 
local lastDebugPrint = 0
local function OnProcessSpellCast(spell) 


    if(spell.owner == player) then
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
    end
end
cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.spell, OnProcessSpellCast);