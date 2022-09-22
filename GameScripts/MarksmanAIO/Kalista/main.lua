local script = {}
local orb = module.internal("orb");
local pred = module.internal("pred")
local evade = module.seek('evade')
local common = module.load(header.id, "common")

local LastAATick = 0

script.partner = nil

script.heroesStacks = { }
script.objectivesStacks = { }
script.minionsStacks = { }

script.qPred = { delay = 0.25, width = 40, speed = 1700, boundingRadiusMod = 1, collision = { hero = true, minion = true, wall = true } }

script.colors = {
	spearDmgs = graphics.argb(255, 150, 255, 200),
	spearDmgs_End = graphics.argb(255, 255, 0, 0)
}


script.menu = menu("MarksmanAIOKalista", "Marksman - Kalista [Beta]")
	script.menu:header('dd', 'Core')
	script.menu:menu("combo", "Combo")
		script.menu.combo:boolean("q", "Use Q", true)
		script.menu.combo:boolean("e", "Use E if can kill", true)
		script.menu.combo:boolean("eslow", "^ Use E for slow target", true)
		script.menu.combo:boolean("botrk", "Use Item", true)
	script.menu:menu("harass", "Harass")
		script.menu.harass:boolean("q", "Use Q", true)
		script.menu.harass:boolean("e", "Use E", true)
		script.menu.harass:slider("e_hits", "Use if can kill {0} minions", 1, 0, 7, 1)
	script.menu:menu("farm", "Lane/Jungle Clear")
		script.menu.farm:boolean("e", "Use E", true)
		script.menu.farm:slider("e_hits", "Use if can kill {0} minions", 3, 1, 7, 1)
	script.menu:menu("lasthit", "Last Hit")
		script.menu.lasthit:boolean("e", "Use E if can't kill minion", true)
	script.menu:menu("flee", "Flee")
		script.menu.flee:keybind("on", "Flee Key", "Z", nil)
		script.menu.flee:boolean("q", "Use Q", true)
	script.menu:menu("misc", "Misc")
		script.menu.misc:header("", "E Settings")
			script.menu.misc:boolean("e", "Use if can kill -> MMO", false)
		script.menu.misc:header("", "R Settings")
			script.menu.misc:boolean("r", "Use to save linked ally", true)
			script.menu.misc:slider("r_hp", "Use if linked ally under {X %} health", 15, 1, 100, 1)
	script.menu:menu("drawings", "Display")
		script.menu.drawings:boolean("qRange", "Draw Q Range", true)
		script.menu.drawings:boolean("eRange", "Draw E Range", true)
		script.menu.drawings:boolean("eDmgs", "Draw E Damages", true)
		script.menu.drawings:boolean("partner", "Partner Infos", true)

function script.CastQ(target)
	local seg = pred.linear.get_prediction(script.qPred, target)
	if seg and seg.startPos:dist(seg.endPos) < 1150 then
		if not pred.collision.get_prediction(script.qPred, seg, target) then
			player:castSpell("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			player:move(game.mousePos)
		end
	end
end

function script.CalcDamagesE(target)
	local spellLevel = player:spellSlot(2).level
	local myAD = common.getTotalAD()
	local spellDmgs = 0.6 * myAD + ({ 20, 30, 40, 50, 60 })[spellLevel]
	local spearDmgs = myAD * ({ 0.2, 0.225, 0.25, 0.275, 0.3 })[spellLevel] + ({ 10, 14, 19, 25, 32 })[spellLevel]
	local dmgs = spellDmgs + ((target.stacks - 1) * spearDmgs)
	return common.CalculatePhysicalDamage(target.obj, dmgs)
end

function script.CirclePoints(CircleLineSegmentN, radius, position)
    local points = {}
    for i = 1, CircleLineSegmentN, 1 do
        local angle = i * 2 * math.pi / CircleLineSegmentN
        local point = vec3(position.x + radius * math.cos(angle), position.y + radius * math.sin(angle), position.z);
        table.insert(points, point)
    end 
    return points 
end

function script.RotateAroundPoint(v1, v2, angle)
    cos, sin = math.cos(angle), math.sin(angle)
    x = ((v1.x - v2.x) * cos) - ((v2.z - v1.z) * sin) + v2.x
    z = ((v2.z - v1.z) * cos) + ((v1.x - v2.x) * sin) + v2.z
    return vec3(x, v1.y, z or 0)
end

function script.DoubleJumpObjecti(unit)

end 

function script.CastE()
	if script.menu.misc.e:get() then
		for i, objective in pairs(script.objectivesStacks) do
			objective.dmgs = script.CalcDamagesE(objective)
			if not objective.obj.isDead and objective.obj.pos:dist(player.pos) <= 1000 and objective.obj.health <= objective.dmgs then
				player:castSpell("self", 2)
				return
			end
		end
	end

	for i, enemy in pairs(script.heroesStacks) do
		if not enemy.obj.isDead and enemy.obj.pos:dist(player.pos) <= 1000 then
			enemy.dmgs = script.CalcDamagesE(enemy)
			if enemy.obj.health <= enemy.dmgs then
				if script.menu.combo.e:get() then
					player:castSpell("self", 2)
					return
				end
			else
				if script.menu.harass.e:get() then
					local hits = 0
					for i, minion in pairs(script.minionsStacks) do
						if not minion.obj.isDead and minion.obj.pos:dist(player.pos) <= 1000 then
							minion.dmgs = script.CalcDamagesE(minion)
							if minion.obj.health <= minion.dmgs then
								hits = hits + 1
							end
						end
					end
					if hits >= script.menu.harass.e_hits:get() then
						player:castSpell("self", 2)
						return
					end
				end
			end
		end
	end
	
	if not orb.combat.is_active() and (script.menu.farm.e:get() or script.menu.lasthit.e:get()) then
		local hits = 0
		for i, minion in pairs(script.minionsStacks) do
			if not minion.obj.isDead and minion.obj.pos:dist(player.pos) <= 1000 then
				minion.dmgs = script.CalcDamagesE(minion)
				if minion.obj.health <= minion.dmgs then
					hits = hits + 1
					if (script.menu.lasthit.e:get() and orb.menu.last_hit:get()) then
						local hp = orb.farm.predict_hp(minion.obj, 0.25)
						if hp <= 0 then
							player:castSpell("self", 2)
							return
						end
					end
				end
				if minion.obj.charName == "SRU_ChaosMinionSiege" then 
					minion.dmgs = script.CalcDamagesE(minion)
					if minion.obj.health <= minion.dmgs then
						player:castSpell("self", 2)
						return
					end 
				end
			end
		end
		if script.menu.farm.e:get() and hits >= script.menu.farm.e_hits:get() then
			player:castSpell("self", 2)
			return
		end
	end
end

function script.CastR()
	if script.partner and script.menu.misc.r:get() then
		if script.partner.health / script.partner.maxHealth * 100 <= script.menu.misc.r_hp:get() then
			player:castSpell("self", 3)
		end
	end
end

function script.Combo(target)
	local targetDist = target.pos:dist(player.pos)
	for i = 6, 11 do
		local item = player:spellSlot(i)
		if item and item.name then
			if script.menu.combo.botrk:get() and targetDist <= 550 and (item.name == "BilgewaterCutlass" or item.name == "ItemSwordOfFeastAndFamine") then
				player:castSpell("obj", i, target)
			end
			if item.name == "YoumusBlade" then
				player:castSpell("self", i)
			end
		end
	end
	if player:spellSlot(0).state == 0 and (not orb.core.can_attack() or targetDist > 615) then
		script.CastQ(target)
	else
		if targetDist > 615 then
			local bestTarget = { obj = nil, dist = 615 }
			for i = 0, objManager.enemies_n - 1 do
				local enemy = objManager.enemies[i]
				if enemy.pos:dist(player.pos) <= 615 then
					local dist = enemy.pos:dist(player.pos)
					if bestTarget.obj then
						if dist < bestTarget.dist then
							bestTarget.obj = enemy
							bestTarget.dist = dist
						end
					else
						bestTarget.obj = enemy
						bestTarget.dist = dist
					end
				end
			end
			if not bestTarget.obj then
			 	local minions = objManager.minions
				for i = 0, minions.size[TEAM_ENEMY] - 1 do
					local minion = minions[TEAM_ENEMY][i]
					if minion.pos:dist(player.pos) <= 615 then
						local dist = minion.pos:dist(player.pos)
						if bestTarget.obj then
							if dist < bestTarget.dist then
								bestTarget.obj = minion
								bestTarget.dist = dist
							end
						else
							bestTarget.obj = minion
							bestTarget.dist = dist
						end
					end
				end
				for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
					local minion = minions[TEAM_NEUTRAL][i]
					if minion.pos:dist(player.pos) <= 615 then
						local dist = minion.pos:dist(player.pos)
						if bestTarget.obj then
							if dist < bestTarget.dist then
								bestTarget.obj = minion
								bestTarget.dist = dist
							end
						else
							bestTarget.obj = minion
							bestTarget.dist = dist
						end
					end
				end
			end
			if bestTarget.obj then
				player:attack(bestTarget.obj)
			end
		end
	end
end

function script.Flee()
	if player:spellSlot(0).state == 0 then
		player:castSpell("pos", 0, player.pos:lerp(mousePos, -10))
		player:move(mousePos)
	else
		local bestTarget = { obj = nil, dist = 615 }
		for i = 0, objManager.enemies_n - 1 do
			local enemy = objManager.enemies[i]
			if enemy.pos:dist(player.pos) <= 615 then
				local dist = enemy.pos:dist(player.pos)
				if bestTarget.obj then
					if dist < bestTarget.dist then
						bestTarget.obj = enemy
						bestTarget.dist = dist
					end
				else
					bestTarget.obj = enemy
					bestTarget.dist = dist
				end
			end
		end
		if not bestTarget.obj then
			local minions = objManager.minions
			for i = 0, minions.size[TEAM_ENEMY] - 1 do
				local minion = minions[TEAM_ENEMY][i]
				if minion.pos:dist(player.pos) <= 615 then
					local dist = minion.pos:dist(player.pos)
					if bestTarget.obj then
						if dist < bestTarget.dist then
							bestTarget.obj = minion
							bestTarget.dist = dist
						end
					else
						bestTarget.obj = minion
						bestTarget.dist = dist
					end
				end
			end
			for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
				local minion = minions[TEAM_NEUTRAL][i]
				if minion.pos:dist(player.pos) <= 615 then
					local dist = minion.pos:dist(player.pos)
					if bestTarget.obj then
						if dist < bestTarget.dist then
							bestTarget.obj = minion
							bestTarget.dist = dist
						end
					else
						bestTarget.obj = minion
						bestTarget.dist = dist
					end
				end
			end
		end
		if bestTarget.obj then
			player:attack(bestTarget.obj)
		end 
	end
end

local function HasBuff(unit, name)
    local buff = unit.buff[string.lower(name)];
    if buff and buff.valid and buff.owner == unit then 
        if game.time <= buff.endTime then
            return true, buff.stacks
        end
    end
    return false, 0
end

local function GetSttackE_Buff_Minions()
	for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
		local minion = objManager.minions[TEAM_ENEMY][i]
		if minion then
			local buff, stacks = HasBuff(minion, 'kalistaexpungemarker');
			if buff then
				local res = {
					obj = minion,
					dmgs = 0,
					stacks = math.min(254, stacks),
				}
				res.dmgs = script.CalcDamagesE(res)
				if minion.type == TYPE_MINION then 
					script.minionsStacks[minion.ptr] = res
				end
			else 
				if script.minionsStacks[minion.ptr] ~= nil then
					script.minionsStacks[minion.ptr] = nil
				end
			end
		end 
	end
end

local function GetSttackE_Buff_MONSTER()
	for i=0, objManager.minions.size[TEAM_NEUTRAL]-1 do
		local minion = objManager.minions[TEAM_NEUTRAL][i]
		if minion then
			local buff, stacks = HasBuff(minion, 'kalistaexpungemarker');
			if buff then
				local res = {
					obj = minion,
					dmgs = 0,
					stacks = math.min(254, stacks),
				}
				res.dmgs = script.CalcDamagesE(res)
				if minion.team == TEAM_NEUTRAL then 
					if minion.charName == "SRU_Baron" or
					minion.charName == "SRU_Dragon_Water" or
					minion.charName == "SRU_Dragon_Fire" or
					minion.charName == "SRU_Dragon_Earth" or
					minion.charName == "SRU_Dragon_Air" or
					minion.charName == "SRU_Dragon_Elder" or
				   minion.charName == "SRU_RiftHerald" or
				   minion.charName == "SRU_Red" or
				   minion.charName == "SRU_Blue" or
				   minion.charName == "Sru_Crab" then
					script.objectivesStacks[minion.ptr] = res
				   end
				end
			else 
				if script.objectivesStacks[minion.ptr] ~= nil then
					script.objectivesStacks[minion.ptr] = nil
				end
			end
		end 
	end
end

local function OnTick()
	if evade and evade.core.is_active() then
		return
	end

	if player:spellSlot(2).state == 0 then
		script.CastE()
	end

	if player:spellSlot(3).state == 0 then
		script.CastR()
	end

	local target = common.GetTarget(1400)
	if target then
		if orb.combat.active then
			script.Combo(target)
		end

		if orb.menu.hybrid:get() and player:spellSlot(0).state == 0 then
			script.CastQ(target)
		end
	end

	if script.menu.flee.on:get() then
		script.Flee()
	end

	if script.partner == nil then
		for i = 0, objManager.allies_n - 1 do
			local hero = objManager.allies[i]
			if hero then
				if hero.buff["kalistacoopstrikeally"] then
					script.partner = hero
				end
			end
		end
	end
	--Enemys
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if (enemy) then
			local buff, stacks = HasBuff(enemy, 'kalistaexpungemarker');
			if buff then
				local res = {
					obj = enemy,
					dmgs = 0,
					stacks = math.min(254, stacks),
				}
				res.dmgs = script.CalcDamagesE(res)
				if enemy.type == TYPE_HERO then
					script.heroesStacks[enemy.ptr] = res
				end
			else
				script.resetStacks(enemy.ptr)
				if script.partner == nil then
					for i = 0, objManager.allies_n - 1 do
						local hero = objManager.allies[i]
						if hero then
							local buff = hero.buff[string.lower('kalistapaltarbuff')] or hero.buff[string.lower('kalistapaltarbuffrise')]  or hero.buff[string.lower('kalistavobindally')] ;
							if buff then
								script.partner = buff.owner
							end
						end
					end
				end
			end
		end	
	end
	--monster
	GetSttackE_Buff_Minions();
	GetSttackE_Buff_MONSTER();
end

cb.add(cb.tick, OnTick)

function script.DrawDamagesE(target)
	if target.obj.isVisible and not target.obj.isDead then
		local pos = graphics.world_to_screen(target.obj.pos)
		graphics.draw_line_2D(pos.x, pos.y - 30, pos.x + 30, pos.y - 80, 1, script.colors.spearDmgs)
		graphics.draw_line_2D(pos.x + 30, pos.y - 80, pos.x + 50, pos.y - 80, 1, script.colors.spearDmgs)
		graphics.draw_line_2D(pos.x + 50, pos.y - 85, pos.x + 50, pos.y - 75, 1, script.colors.spearDmgs)
		if math.floor(target.dmgs / target.obj.health * 100) < 100 then
			graphics.draw_text_2D("(" .. tostring(math.floor(target.dmgs / target.obj.health * 100)) .. "%)", 20, pos.x + 55, pos.y - 80, script.colors.spearDmgs)
		else 
			graphics.draw_text_2D("(" .. "100" .. "%)", 20, pos.x + 55, pos.y - 80, script.colors.spearDmgs_End)
		end
	end
end

local function OnDraw()
	if not player.isDead then
		if script.menu.drawings.eDmgs:get() then
			for i, enemy in pairs(script.heroesStacks) do
				script.DrawDamagesE(enemy)
			end

			for i, enemy in pairs(script.objectivesStacks) do
				script.DrawDamagesE(enemy)
			end

			for i,enemy in pairs(script.minionsStacks) do
				script.DrawDamagesE(enemy)
			end
		end

		if player.isOnScreen then
			if script.menu.drawings.partner:get() then
				local pos = graphics.world_to_screen(player.pos)
				if script.partner then
					graphics.draw_text_2D("Linked: "..script.partner.charName, 16, pos.x - 50, pos.y + 40, script.colors.spearDmgs, "center")
				else
					graphics.draw_text_2D("Where is the Linked ally?", 16, pos.x - 65, pos.y + 30, script.colors.spearDmgs, "center")
				end
			end
			--Where is the Linked ally?
			if script.menu.drawings.qRange:get() and (player:spellSlot(0).state == 0) then
				graphics.draw_circle(player.pos, 1150, 1, script.colors.spearDmgs, 40)
			end
			if script.menu.drawings.eRange:get() and (player:spellSlot(2).state == 0) then
				graphics.draw_circle(player.pos, 1000, 1, script.colors.spearDmgs, 40)
			end
		end
	end
end
cb.add(cb.draw, OnDraw)

local function AfterAttack()
	player:move(game.mousePos)
end
orb.combat.register_f_after_attack(AfterAttack)

function script.resetStacks(id)
	if script.heroesStacks[id] ~= nil then
		script.heroesStacks[id] = nil
	end
end

local function OnDeleteMinion(obj)
	if obj then 
		if script.minionsStacks[obj.ptr] ~= nil then
			script.minionsStacks[obj.ptr] = nil
		end
		if script.objectivesStacks[obj.ptr] ~= nil then 
			script.objectivesStacks[obj.ptr] = nil 
		end
	end
end

cb.add(cb.delete_minion, OnDeleteMinion)
