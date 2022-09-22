--[[evade.damage
local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
--these are reduced/modified by armor/buffs
--buff_list contains an array of all incoming buff types

--evade.skillshots
for i=evade.core.skillshots.n, 1, -1 do
  local spell = evade.core.skillshots[i]
  --spell.name
  --spell.start_time
  --spell.end_time
  --spell.owner
  --spell.danger_level
  --spell.start_pos
  --spell.end_pos
  --spell.data -- assorted static data
  
  if spell:contains(game.mousePos2D) then
    --mouse is inside of 'spell'
  end
  
  if spell:contains(player) then
    --player is inside of 'spell', this accounts for obj boundingRadius
  end
  
  if spell:intersection(player.pos2D, game.mousePos2D) then
    --line seg player->mousePos intersects 'spell'
  end
end

--evade.targeted
for i=evade.core.targeted.n, 1, -1 do
  local spell = evade.core.targeted[i]
  --spell.name
  --spell.start_time
  --spell.end_time
  --spell.owner
  --spell.target
  --spell.missile
  --spell.data -- assorted static data
end

evade.core.is_active() --should be checked before casting any movement impairing spells
evade.core.set_pause(t) --pauses evade from issuing movement orders (will still update orbs path)
evade.core.is_paused()]]

local evade = module.seek('evade');
local common = module.load(header.id, "Library/common");
local ts = module.internal("TS")
local orb = module.internal("orb")
local gpred = module.internal("pred")

local enemies = common.GetEnemyHeroes()
--local ally = common.GetAllyHeroes()
--local Bomb = false

local qPred = { delay = 0.75, radius = 130, speed = math.huge, boundingRadiusMod = 1, collision = { hero = false, minion = false, wall = true } }

local QlvlDmg = {75, 115, 165, 230, 300}

local menu = menu("Intnnerzilean", "Int Zilean")
	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Combo Settings")
		menu.combo:dropdown("mode", "Choose Mode: ", 2, {"Mid", "Support"})
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:boolean("w", "Force Q | W |Q", true)
		menu.combo:boolean("e", "Smart E", true)

		menu.combo:header("xd", "R Settings")
			menu.combo:menu("rs", "R Settings")
					menu.combo.rs:header("xd", "Player Settings")
					menu.combo.rs:boolean("r", "Use Smart R", true)
					menu.combo.rs:slider("rx", "R on X Enemys in Range", 1, 0, 5, 1)
					menu.combo.rs:slider("rhp", "What HP% to Ult", 10, 0, 100, 5)

					menu.combo.rs:header("xd", "Ally Settings")
					menu.combo.rs:boolean("use", "Use R for Ally", true)
					menu.combo.rs:menu("x", "Ally Selection")
						for i = 0, objManager.allies_n - 1 do
							local ally = objManager.allies[i]
							if ally and ally ~= player then
								menu.combo.rs.x:boolean(ally.charName, "Revive: "..ally.charName, false)
							end 
						end
					menu.combo.rs:slider("ahp", "HP {0%} To Revive Ally", 10, 0, 100, 5)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("w", "Force Q | W |Q", true)
		menu.harass:boolean("e", "Use E", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "Automatic and KillSteal Settings")
		menu.auto:boolean("Ignite", "Auto Ignite", true)
		menu.auto:menu("ks", "KillSteal")
			menu.auto.ks:header("xd", "Killsteal Settings")
			menu.auto.ks:boolean("uks", "Use Killsteal", true)
			menu.auto.ks:boolean("ksq", "Use Q in Killsteal", true)
			menu.auto.ks:boolean("ksqwq", "Use Q | W |Q in Killsteal", true)

	ts.load_to_menu();

	menu:menu("draws", "Drawing")
		menu.draws:boolean("q", "Draw Q Range", true)
        menu.draws:boolean("e", "Draw R Range", true)
        
    menu:menu("keys", "Key Settings")
		menu.keys:keybind("combo", "Combo", "Space", false)
		menu.keys:keybind("harass", "Harass", "C", false)
		menu.keys:keybind("clear", "Clear", "V", false)
		menu.keys:keybind("run", "Marathon", "S", false)
		menu.keys:keybind("ultself", "Manual Self Ult", "A", false)


local function select_target(res, obj, dist)
	if dist > 900 then return end
	res.obj = obj
	return true
end

local function get_target(func)
	return ts.get_result(func).obj
end

local function qDmg(target)
	local qDamage = QlvlDmg[player:spellSlot(0).level] + (common.GetTotalAP() * .9)
	return common.CalculateMagicDamage(target, qDamage)
end

local function CastQ(target)
	if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (890 * 890) then
		local res = gpred.circular.get_prediction(qPred, target)
		if res and res.startPos:dist(res.endPos) < 890 then
			player:castSpell("pos", 0, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

local QWQCast = false
local function QWQ(target)
	if QWQCast == false then
	    if player.par >= player.manaCost0 * 2 + player.manaCost1 then
	    	CastQ(target)
			if player:spellSlot(0).state ~= 0 and player.path.serverPos:distSqr(target.path.serverPos) < (900 * 900) and player:spellSlot(1).state == 0 then
			    player:castSpell("self", 1)
			end
			if player:spellSlot(1).state ~= 0 and player:spellSlot(0).state == 0 then
				common.DelayAction(function()CastQ(target) end, 0.1)
				QWQCast = true
			end
		else
			common.DelayAction(function() CastQ(target) end, 0.1)
		end
	elseif player:spellSlot(0).state == 0 and player:spellSlot(1).state == 0 then
		QWQCast = false
	end
end

local function QWQ2(target)
	if QWQCast == false then
	    if player.par >= player.manaCost0 * 2 + player.manaCost1 then
	    	common.DelayAction(function() CastQ(target) end, 0.2)
			if player:spellSlot(0).state ~= 0 and player.path.serverPos:distSqr(target.path.serverPos) < (850 * 850) and player:spellSlot(1).state == 0 then
			    player:castSpell("self", 1)
			end
		else
			common.DelayAction(function() CastQ(target) end, 0.2)
		end
	elseif player:spellSlot(0).state == 0 and player:spellSlot(1).state == 0 then
		QWQCast = false
	end
end

local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
 		if enemy and common.IsValidTarget(enemy) and not enemy.buff["sionpassivezombie"] then
  			if menu.auto.ks.ksq:get() and player:spellSlot(0).state == 0 and enemy.health < qDmg(enemy) then
	  			CastQ(enemy)
	  		end
   			if menu.auto.ks.ksqwq:get() and player:spellSlot(0).state == 0 and player:spellSlot(1).state == 0 and enemy.health < 2 * qDmg(enemy) then 
   				QWQ(enemy) 
   			end
  		end
 	end
end

local function Combo()
	local target = get_target(select_target)
	if target and common.IsValidTarget(target) and target.isTargetable then
		if menu.combo.mode:get() == 2 then
			if menu.combo.e:get() and #common.GetAllyHeroesInRange(600, player.pos) >= 1 and target.pos:dist(player.pos) <= 600 and player:spellSlot(2).state == 0 and not target.buff[10] then
				player:castSpell("obj", 2, target)
			end
			if menu.combo.q:get() and not menu.combo.w:get() then
				CastQ(target)
			end
			if menu.combo.q:get() and menu.combo.w:get() and player:spellSlot(1).level >= 4 then
				QWQ(target)
			elseif menu.combo.q:get() and menu.combo.w:get() and player:spellSlot(1).level <= 3 then
				QWQ2(target)
			elseif player:spellSlot(0).state ~= 0 and not menu.combo.w:get() then
				player:castSpell("self", 1)
			end
		elseif menu.combo.mode:get() == 1 then
			if menu.combo.e:get() then
				if target.pos:dist(player.pos) > 900 and target.pos:dist(player.pos) < 1050 and player:spellSlot(0).state == 0 and player:spellSlot(1).state == 0 then
					player:castSpell("obj", 2, player)
				elseif target.pos:dist(player.pos) <= 700 and not target.buff["timewarpslow"] then
					player:castSpell("obj", 2, target)
				end
				for i = 0, objManager.enemies_n - 1 do
					local enemy = objManager.enemies[i]
	    			if enemy ~= target and enemy.pos:dist(player.pos) < 400 then
		    			player:castSpell("obj", 2, enemy)
	    			end
				end
			end
			if menu.combo.q:get() and not menu.combo.w:get() then
				CastQ(target)
			elseif player:spellSlot(0).state ~= 0 and not menu.combo.w:get() then
				player:castSpell("self", 1)
			elseif menu.combo.q:get() and menu.combo.w:get() and player:spellSlot(1).level >= 4 then
				QWQ(target)
			elseif menu.combo.q:get() and menu.combo.w:get() and player:spellSlot(1).level <= 3 then
				QWQ2(target)
			end
		end
	end
end

local function Harass()
	if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
		local target = get_target(select_target)
		if target and common.IsValidTarget(target) and target.isTargetable then
			if menu.harass.q:get() and not menu.harass.w:get() then
				CastQ(target)
			elseif menu.harass.q:get() and menu.harass.w:get() then
				QWQ(target)
			elseif not player:spellSlot(0).state == 0 and not menu.combo.w:get() then
				player:castSpell("self", 1)
			end
			if menu.harass.e:get() and #common.GetAllyHeroesInRange(600, player.pos) >= 1 and target.pos:dist(player.pos) <= 600 and player:spellSlot(2).state == 0 then
				player:castSpell("obj", 2, target)
			end
		end
	end
end


local function autoUlt()
	if player:spellSlot(3).state ~= 0 then return end
	if menu.combo.rs.r:get() and #common.GetEnemyHeroesInRange(800) >= menu.combo.rs.rx:get() and common.GetPercentHealth(player) <=  menu.combo.rs.rhp:get() then
		player:castSpell("obj", 3, player)
	end
end

local function autoAllyUlt()
	if menu.combo.rs.use:get() then
		for i = 0, objManager.allies_n - 1 do
			local ally = objManager.allies[i]
			if player:spellSlot(3).state == 0 and ally and not ally.isDead and not player.isDead and ally.pos:dist(player.pos) <= 900 and common.GetPercentHealth(ally) <= menu.combo.rs.ahp:get() and #common.GetEnemyHeroesInRange(800, ally.pos) >= 1 then
				if menu.combo.rs.x[ally.charName] and menu.combo.rs.x[ally.charName]:get() and common.GetPercentHealth(player) > common.GetPercentHealth(ally) then
					player:castSpell("obj", 3, ally)
				end
            end
            
            if ally and common.IsValidTarget(ally) and ally.pos:dist(player.pos) <= 900 then 
                if menu.combo.rs.x[ally.charName] and menu.combo.rs.x[ally.charName]:get()  then 
                    for i=evade.core.targeted.n, 1, -1 do
                        local spell = evade.core.targeted[i]
                        if spell and spell.owner.team == TEAM_ENEMY  and spell.target.ptr == ally.ptr then 
                            local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(ally)
                            if player:spellSlot(3).state == 0 then 
                                if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", ally) then 
                                    player:castSpell("obj", 3, ally)
                                end 
            
                                if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", ally) then 
                                    player:castSpell("obj", 3, ally)
                                end
                            end
                        end
                    end 
            
                    for i=evade.core.skillshots.n, 1, -1 do
                        local spell = evade.core.skillshots[i]
                        if spell and spell.owner.team == TEAM_ENEMY and spell:contains(ally) then 
                            local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(ally)
                            if player:spellSlot(3).state == 0 then 
                                if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", ally) then 
                                    player:castSpell("obj", 3, ally)
                                end 
            
                                if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", ally) then 
                                    player:castSpell("obj", 3, ally)
                                end
                            end
                        end
                    end 
                end 
            end 
		end
	end
end


local function Run()
	if menu.keys.run:get() then
		player:move((game.mousePos))
		if player:spellSlot(2).state == 0 then
			player:castSpell("obj", 2, player)
		end
		if player:spellSlot(1).state == 0 and player:spellSlot(2).state ~= 0 and not player.buff["timewarp"] then
			player:castSpell("self", 1)
		end
	end
end


local function OnTick()
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid:get() then Harass() end
	if menu.auto.ks.uks:get() then KillSteal() end
	if menu.combo.rs.r:get() then autoUlt() end
	if menu.combo.rs.use:get() then autoAllyUlt() end
	if menu.keys.run:get() then Run() end
    if menu.keys.ultself:get() and player:spellSlot(3).state == 0 and common.GetPercentHealth(player) <= 30 then player:castSpell("obj", 3, player) end
    
    if #common.CountAllysInRange(player.pos, 900) == 0 then 
        for i=evade.core.targeted.n, 1, -1 do
            local spell = evade.core.targeted[i]
            if spell and spell.owner.team == TEAM_ENEMY  and spell.target.ptr == player.ptr then 
                local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
                if player:spellSlot(3).state == 0 then 
                    if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                        player:castSpell("obj", 3, player)
                    end 

                    if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                        player:castSpell("obj", 3, player)
                    end
                end
            end
        end 

        for i=evade.core.skillshots.n, 1, -1 do
            local spell = evade.core.skillshots[i]
            if spell and spell.owner.team == TEAM_ENEMY and spell:contains(player) then 
                local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
                if player:spellSlot(3).state == 0 then 
                    if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                        player:castSpell("obj", 3, player)
                    end 

                    if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                        player:castSpell("obj", 3, player)
                    end
                end
            end
        end 
    end
end


local function OnDraw()
	if not player.isDead and player.isOnScreen then
		if menu.draws.q:get() and player:spellSlot(0).state == 0 then
      		graphics.draw_circle(player.pos, 900, 2, graphics.argb(255, 255, 255, 255), 50)
    	end
    	if menu.draws.e:get() and player:spellSlot(2).state == 0 then
      		graphics.draw_circle(player.pos, 600, 2, graphics.argb(255, 255, 255, 255), 50)
    	end
  	end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.draw, OnDraw)
