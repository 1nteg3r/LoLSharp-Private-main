local version = "1.01"

local common = module.load(header.id, "Library/common");
--local enemies = common.GetEnemyHeroes()
--local minionmanager = objManager.minions

local ts = module.internal("TS")
local orb = module.internal("orb")
local gpred = module.internal("pred")

local wPred = {
	delay = 0.25,
	width = 70,
	speed = 2300,
	boundingRadiusMod = 1,
	collision = {hero = false, minion = false}
}
local w2Pred = {
	delay = 0.25,
	width = 40,
	speed = 2300,
	boundingRadiusMod = 1,
	collision = {hero = false, minion = false}
}


local menu = menu("IntnnerTalon", "Int - Talon")

menu:menu("combo", "Combo")
menu.combo:boolean("q", "Use Q", true)
menu.combo:boolean("td", "Smart Tower-Dive", true)
menu.combo:boolean("w", "Smart W", true)
menu.combo:boolean("r", "Use Killable R", true)

menu:menu("harass", "Harass")
menu.harass:boolean("q", "Use Q", true)
menu.harass:boolean("w", "Smart W", true)
menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

menu:menu("auto", "Killsteal")
menu.auto:boolean("uks", "Use Killsteal", true)
menu.auto:boolean("uksq", "Use Q on Killsteal", true)
menu.auto:boolean("uksw", "Use W on Killsteal", true)
menu.auto:boolean("uksr", "Use R on Killsteal", true)

menu:menu("draws", "Drawings")
menu.draws:boolean("q", "Q Range", true)
menu.draws:boolean("e", "E Range", true)
ts.load_to_menu()

menu:menu("keys", "Key Settings")
menu.keys:keybind("run", "Run", "Z", false)
menu.keys:keybind("flowerc", "Combo 2", false, "T")

local function select_target(res, obj, dist)
	if dist > 555 then
		return
	end
	res.obj = obj
	return true
end

local function select_wtarget(res, obj, dist)
	if dist > 650 then
		return
	end
	res.obj = obj
	return true
end

local function get_target(func)
	return ts.get_result(func).obj
end
--local dmg = 65 + (10 * player.levelRef) + (common.GetBonusAD() * 2)
local function qDmg(target)
	if player.path.serverPos:dist(target.path.serverPos) < 555 then 
		local base_damage = 40 + (25 * player:spellSlot(0).level) + (common.GetBonusAD() * 1.10)
		local total = base_damage
		return common.CalculatePhysicalDamage(target, total)
	end
end

local function wDmg(target)
	if player.path.serverPos:dist(target.path.serverPos) < 640 then 
		local base_damage = 35 + (15 * player:spellSlot(1).level) + (common.GetBonusAD() * 0.4)
		local back = 55 + (25 * player:spellSlot(1).level) + (common.GetBonusAD() * 0.6)
		local total = base_damage + back
		--if player.path.serverPos:dist(target.path.serverPos) < 620 then
		return common.CalculatePhysicalDamage(target, total)
		--end
	end
end

local function rDmg(target)
	if player.path.serverPos:dist(target.path.serverPos) < 550 then 
		local base_damage = 45 + (45 * player:spellSlot(3).level) + (common.GetBonusAD() * 1)
		local total = base_damage
		return common.CalculatePhysicalDamage(target, total)
	end
end


local function CastW(target)
	if player:spellSlot(1).state == 0 and player.path.serverPos:dist(target.path.serverPos) < 640 and player.path.serverPos:dist(target.path.serverPos) > 400 then
		local seg = gpred.linear.get_prediction(wPred, target)
		if seg and seg.startPos:dist(seg.endPos) < 640 and seg.startPos:dist(seg.endPos) > 400 then
			if not gpred.collision.get_prediction(wPred, seg, target) then
				player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	elseif player:spellSlot(1).state == 0 and player.path.serverPos:dist(target.path.serverPos) < 400 then
		local seg = gpred.linear.get_prediction(w2Pred, target)
		if seg and seg.startPos:dist(seg.endPos) < 400 then
			if not gpred.collision.get_prediction(w2Pred, seg, target) then
				player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end


local function Combo()
	local target = get_target(select_wtarget)
	if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
		local d = player.path.serverPos:dist(target.path.serverPos)
		local w = player:spellSlot(1).state == 0
		local q = player:spellSlot(0).state == 0
		local r = player:spellSlot(3).state == 0
		if menu.combo.q:get() and q then
			local target = get_target(select_target)
			if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
				if menu.combo.td:get() and not common.IsUnderDangerousTower(target.pos) and d < 555 then
					player:castSpell("obj", 0, target)
				elseif menu.combo.td:get() and common.IsUnderDangerousTower(target.pos) and d < 555 and target.health < (qDmg(target)*1.5) then
					player:castSpell("obj", 0, target)
				end
			end
		end
		if menu.combo.w:get() and w and d < 650 and not player.buff["talonrstealth"] then
			CastW(target)
		end
		if menu.combo.r:get() and r and w and q and d < 550 and rDmg(target) + qDmg(target) + (wDmg(target)) > target.health and not player.buff["talonrstealth"] then
			player:castSpell("self", 3)
		end
	end
end

local function FlowerCombo()
	local target = get_target(select_wtarget)
	if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] and not player.buff["talonrstealth"] then
		local d = player.path.serverPos:dist(target.path.serverPos)
		if menu.combo.w:get() and player:spellSlot(1).state == 0 and d < 650 then
			CastW(target)
		end
		if menu.combo.q:get() and player:spellSlot(0).state == 0 and d < 575 and player:spellSlot(1).state ~= 0 then
			player:castSpell("obj", 0, target)
		end
		if menu.combo.r:get() and player:spellSlot(3).state == 0 and d < 550 and player:spellSlot(0).state ~= 0 then
			player:castSpell("self", 3)
		end
	end
end

local function Harass()
	if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
		local target = get_target(select_wtarget)
		if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
			local d = player.path.serverPos:dist(target.path.serverPos)
			if menu.harass.q:get() and player:spellSlot(0).state == 0 and d < 555 then
				player:castSpell("self", 0)
			end
			if menu.harass.w:get() and player:spellSlot(1).state == 0 and not player.buff["talonrstealth"] then
				CastW(target)
			end
		end
	end
end

local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		local d = player.path.serverPos:dist(enemy.path.serverPos)
 		if enemy and common.IsValidTarget(enemy) and menu.auto.uks:get() and not enemy.buff["sionpassivezombie"] then
  			if menu.auto.uksq:get() and player:spellSlot(0).state == 0 and d < 555 and enemy.health < qDmg(enemy) then
	  			player:castSpell("obj", 0, enemy)
	  		end
   			if menu.auto.uksw:get() and player:spellSlot(1).state == 0 and d < 640 and enemy.health < wDmg(enemy) then 
   				CastW(enemy)
   			elseif player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and d < 550 and enemy.health < wDmg(enemy) + qDmg(enemy) then
   				CastW(enemy)
   				player:castSpell("obj", 0, enemy)
   			end
   			if menu.auto.uksr:get() and player:spellSlot(3).state == 0 and d < 550 and enemy.health < rDmg(enemy) then 
   				player:castSpell("self", 3)
   			end
  		end
 	end
end

local function Run()
	if menu.keys.run:get() then
		player:move((game.mousePos))
		if player:spellSlot(2).state == 0 and navmesh.isWall(game.mousePos) then
			player:castSpell("pos", 2, (game.mousePos))
		end
	end
end


local function OnTick()
	if orb.combat.is_active() then
		if not menu.keys.flowerc:get() then
			Combo()
		else
			FlowerCombo()
		end
	end
	if orb.menu.hybrid.key:get() then
		Harass()
	end
	if menu.auto.uks:get() then
		KillSteal()
	end
	if menu.keys.run:get() then
		Run()
	end
	--if menu.keys.flower:get() then FlowerCombo() end
end

local function OnDraw()
	if menu.draws.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, 500, 2, graphics.argb(255, 7, 141, 237), 50)
	end
	if player:spellSlot(3).level > 0 then
        local pos = graphics.world_to_screen(vec3(player.x-70, player.y, player.z-150))
        if menu.keys.flowerc:get() then
           graphics.draw_text_2D("Flower Combo: On", 15, pos.x, pos.y, graphics.argb(255, 51, 255, 51))
        else
           graphics.draw_text_2D("Flower Combo: Off", 15, pos.x, pos.y, graphics.argb(255, 255, 30, 30))
        end
     end
	--graphics.draw_circle(player.pos, (650), 2, graphics.argb(255, 255, 112, 255), 50)
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.draw, OnDraw)
orb.combat.register_f_after_attack(
	function()
		if orb.combat.is_active() then
			if orb.combat.target then
				if menu.combo.q:get() and orb.combat.target and common.IsValidTarget(orb.combat.target) and player.pos:dist(orb.combat.target.pos) < common.GetAARange(orb.combat.target) then
					if player:spellSlot(0).state == 0 then
						player:castSpell("obj", 0, orb.combat.target)
						orb.core.set_server_pause()
						orb.combat.set_invoke_after_attack(false)
						player:attack(orb.combat.target)
						orb.core.set_server_pause()
						orb.combat.set_invoke_after_attack(false)
						return "on_after_attack_hydra"
					end
				end
			end
			if menu.combo.q:get() and orb.combat.target and common.IsValidTarget(orb.combat.target) and player.pos:dist(orb.combat.target.pos) < common.GetAARange(orb.combat.target) then
          		for i = 6, 11 do
            		local item = player:spellSlot(i).name
            		if item and (item == "ItemTitanicHydraCleave" or item == "ItemTiamatCleave") and player:spellSlot(i).state == 0 then
              			player:castSpell("obj", i, player)
		              	orb.core.set_server_pause()
		              	orb.combat.set_invoke_after_attack(false)
		              	player:attack(orb.combat.target)
		              	orb.core.set_server_pause()
		              	orb.combat.set_invoke_after_attack(false)
              			return on_after_attack_hydra
            		end
          		end
        	end
		end
		if orb.menu.hybrid.key:get() then
			if orb.combat.target then
				if menu.harass.q:get() and orb.combat.target and common.IsValidTarget(orb.combat.target) and player.pos:dist(orb.combat.target.pos) < common.GetAARange(orb.combat.target) then
					if player:spellSlot(0).state == 0 then
						player:castSpell("obj", 0, orb.combat.target)
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
)

--print(player.mana)
--ReksaiQBurrowed
