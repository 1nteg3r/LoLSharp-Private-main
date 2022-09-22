local evade = module.seek("evade")
local preds = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")

local common = module.load(header.id, 'Library/common');
local dmglib =  module.load(header.id, 'Library/damageLib');

local spellQ = {
	range = 730
}

local spellW = {
	range = 700,
	radius = 50,
	speed = math.huge,
	delay = 1,
	boundingRadiusMod = 0
}

local spellE = {
	delay = 0.25,
	range = 1150,
	width = 160,
	speed = 1700,
	boundingRadiusMod = 0
}

local spellR = {
	range = 700,
	radius = 325,
	speed = 1000,
	delay = 1,
	boundingRadiusMod = 0
}
local interruptableSpells = {
	["anivia"] = {
		{menuslot = "R", slot = 3, spellname = "glacialstorm", channelduration = 6}
	},
	["caitlyn"] = {
		{menuslot = "R", slot = 3, spellname = "caitlynaceinthehole", channelduration = 1}
	},
	["ezreal"] = {
		{menuslot = "R", slot = 3, spellname = "ezrealtrueshotbarrage", channelduration = 1}
	},
	["fiddlesticks"] = {
		{menuslot = "W", slot = 1, spellname = "drain", channelduration = 5},
		{menuslot = "R", slot = 3, spellname = "crowstorm", channelduration = 1.5}
	},
	["gragas"] = {
		{menuslot = "W", slot = 1, spellname = "gragasw", channelduration = 0.75}
	},
	["janna"] = {
		{menuslot = "R", slot = 3, spellname = "reapthewhirlwind", channelduration = 3}
	},
	["karthus"] = {
		{menuslot = "R", slot = 3, spellname = "karthusfallenone", channelduration = 3}
	}, --common.IsValidTargetTarget will prevent from casting @ karthus while he's zombie
	["katarina"] = {
		{menuslot = "R", slot = 3, spellname = "katarinar", channelduration = 2.5}
	},
	["lucian"] = {
		{menuslot = "R", slot = 3, spellname = "lucianr", channelduration = 2}
	},
	["lux"] = {
		{menuslot = "R", slot = 3, spellname = "luxmalicecannon", channelduration = 0.5}
	},
	["malzahar"] = {
		{menuslot = "R", slot = 3, spellname = "malzaharr", channelduration = 2.5}
	},
	["masteryi"] = {
		{menuslot = "W", slot = 1, spellname = "meditate", channelduration = 4}
	},
	["missfortune"] = {
		{menuslot = "R", slot = 3, spellname = "missfortunebullettime", channelduration = 3}
	},
	["nunu"] = {
		{menuslot = "R", slot = 3, spellname = "absolutezero", channelduration = 3}
	},
	--excluding Orn's Forge Channel since it can be cancelled just by attacking him
	["pantheon"] = {
		{menuslot = "R", slot = 3, spellname = "pantheonrjump", channelduration = 2}
	},
	["shen"] = {
		{menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3}
	},
	["twistedfate"] = {
		{menuslot = "R", slot = 3, spellname = "gate", channelduration = 1.5}
	},
	["varus"] = {
		{menuslot = "Q", slot = 0, spellname = "varusq", channelduration = 4}
	},
	["warwick"] = {
		{menuslot = "R", slot = 3, spellname = "warwickr", channelduration = 1.5}
	},
	["xerath"] = {
		{menuslot = "R", slot = 3, spellname = "xerathlocusofpower2", channelduration = 3}
	}
}
local menu = menu("int", "Int Viktor")
--dts = tSelector(menu, 1100, 1)
--dts:addToMenu()
menu:menu("combo", "Combo")
--menu.combo:menu("qset", "Q Settings")
menu.combo:boolean("qcombo", "Use Q", true)

--menu.combo:menu("wset", "W Settings")
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:dropdown("wusage", " ^~ Usage", 2, {"Always", "Only CC", "Together"})

--menu.combo:menu("eset", "E Settings")
menu.combo:boolean("ecombo", "Use E", true)

menu.combo:menu("rset", "R Settings")
menu.combo.rset:boolean("follow", "Use R", true)
menu.combo.rset:dropdown("rusage", "R Staly:", 2, {"{0%} Health", "Killable"})
menu.combo.rset:boolean("wait", "Smart R", false)
menu.combo.rset:slider("rtick", "Min. Enemys In Range >= {0}", 1, 1, 3, 1)
menu.combo.rset:slider("hitr", "Min. Enemies to Hit", 2, 2, 5, 1)
menu.combo.rset:slider("waster", "Save {R} not use R if Enemy Health <= ", 15, 0, 100, 1)
menu.combo.rset:slider("hpr", "My Life Percent >= {0}", 60, 0, 100, 1)

menu:menu("harass", "Harass")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("eharass", "Use E", true)
menu.harass:slider("mana", "Min. Mana Manager >= {0}", 50, 0, 100, 1)

menu:menu("laneclear", "Lane/Jungle")
menu.laneclear:keybind("clearkey", "Lane Clear Key", "V", nil)
menu.laneclear:boolean("farmq", "Use Q", true)
menu.laneclear:boolean("lastq", "Last hit minions with Q", true)
menu.laneclear:slider("mana", "Mana Manager", 45, 0, 100, 1)
menu.laneclear:menu("jungle", "JungleClear")
menu.laneclear.jungle:boolean("useq", "Use Q", true)
menu.laneclear.jungle:slider("mana", "Min. Mana Manager >= {0}", 10, 0, 100, 1)

menu:menu("misc", "Misc")
menu.misc:boolean("GapA", "Use W for Anti-Dash", true)
menu.misc:boolean("inte", "Interrupt spells if possible", true)
menu.misc:boolean("ksq", "Killsteal Q", true)
menu.misc:boolean("kse", "Killsteal E", true)
menu.misc:keybind("fleekey", "Flee Toogle:", "Z", nil)
menu.misc:boolean("fleeq", "Use Q", true)
menu.misc.fleeq:set('tooltip', "I recommend using Flee when involution the Q")


menu:menu("draws", "Drawings")
menu.draws:boolean("drawq", "Q Range", true)
menu.draws:color("colorq", "Color", 255, 255, 255, 255)
menu.draws:boolean("draww", "W Range", false)
menu.draws:color("colorw", "Color", 255, 255, 255, 255)
menu.draws:boolean("drawe", "E Range", true)
menu.draws:color("colore", "Color", 255, 255, 255, 255)
menu.draws:boolean("drawr", "R Range", false)
menu.draws:color("colorr", "Color", 255, 255, 255, 255)


local TargetSelectionQ = function(res, obj, dist)
	if dist < spellE.range then
		res.obj = obj
		return true
	end
end
local GetTargetQ = function()
	return TS.get_result(TargetSelectionQ).obj
end
local TargetSelectionFollow = function(res, obj, dist)
	if dist < 2000 then
		res.obj = obj
		return true
	end
end
local GetTargetFollow = function()
	return TS.get_result(TargetSelectionFollow).obj
end
local AutoInterrupt = function(spell)
	if menu.misc.inte:get() and  (player:spellSlot(3).state == 0) then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			local enemyName = string.lower(spell.owner.charName)
			if interruptableSpells[enemyName] then
				for i = 1, #interruptableSpells[enemyName] do
					local spellCheck = interruptableSpells[enemyName][i]
					if
					
							string.lower(spell.name) == spellCheck.spellname
					 then
						if
							player.pos2D:dist(spell.owner.pos2D) < spellR.range and common.IsValidTarget(spell.owner) and
								(player:spellSlot(3).state == 0)
						 then
							player:castSpell("pos", 3, spell.owner.pos)
						end
					end
				end
			end
		end
	end
	if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY then
		if spell.name == "ViktorPowerTransfer" then
			orb.core.set_pause_attack(0.2)
			player:move(mousePos)
			if (orb.core.can_attack()) then
				orb.core.set_pause_attack(0)
				orb.core.reset()
			end
		end
	end
end
local function WGapcloser()
	if  (player:spellSlot(1).state == 0) and menu.misc.GapA:get() then
		local enemy = common.GetEnemyHeroes()
    		for i, dasher in ipairs(enemy) do	
			if dasher  then
				if
					common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and
						player.pos:dist(dasher.path.point[1]) < 700
				 then
					if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[1]) then
						if ((player.health / player.maxHealth) * 100 <= 100) then
							player:castSpell("pos", 1, dasher.path.point2D[1])
						end
					end
				end
			end
		end
	end
end
local function count_enemies_in_range(pos, range)
	local enemies_in_range = {}
	local enemyS = common.GetEnemyHeroes()
	for i, enemy in ipairs(enemyS) do	
		if enemy and pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end
local function RFollow()
	if menu.combo.rset.follow:get() then
		if common.CheckBuff(player, "viktorchaosstormtimer") then
			local target = GetTargetFollow()
			if target and target.isVisible then
				if common.IsValidTarget(target) then
					player:castSpell("pos", 3, target.pos)
				end
			end
		end
	end
end
local function Combo()
	local target = GetTargetQ()
	if target then
		if common.IsValidTarget(target) then
			if (player:spellSlot(3).state == 0) then
				if #count_enemies_in_range(target.pos, 300) >= menu.combo.rset.hitr:get() then
					if menu.combo.wusage:get() == 3 and menu.combo.wcombo:get() then
						if target.pos:dist(player.pos) < spellW.range then
							local pos = preds.circular.get_prediction(spellW, target)
							if pos and player.pos:to2D():dist(pos.endPos) <= spellW.range then
								player:castSpell("pos", 1, vec3(pos.endPos.x, target.y, pos.endPos.y))
							end
						end
					end
					local pos = preds.circular.get_prediction(spellR, target)
					if pos and player.pos:to2D():dist(pos.endPos) <= spellR.range then
						player:castSpell("pos", 3, vec3(pos.endPos.x, target.y, pos.endPos.y))
					end
				end
			end
			if menu.combo.rset.rusage:get() == 1 and (player:spellSlot(3).state == 0) then
				if (target.health / target.maxHealth) * 100 > menu.combo.rset.waster:get() then
					if (target.health / target.maxHealth) * 100 <= menu.combo.rset.hpr:get() then
						if not (menu.combo.rset.wait:get()) then
							if menu.combo.wusage:get() == 3 and menu.combo.wcombo:get() then
								if target.pos:dist(player.pos) < spellW.range then
									local pos = preds.circular.get_prediction(spellW, target)
									if pos and player.pos:to2D():dist(pos.endPos) <= spellW.range then
										player:castSpell("pos", 1, vec3(pos.endPos.x, target.y, pos.endPos.y))
									end
								end
							end
							local pos = preds.circular.get_prediction(spellR, target)
							if pos and player.pos:to2D():dist(pos.endPos) <= spellR.range then
								player:castSpell("pos", 3, vec3(pos.endPos.x, target.y, pos.endPos.y))
							end
						end
						if (menu.combo.rset.wait:get()) then
							if ( (player:spellSlot(0).state == 0) or  (player:spellSlot(2).state == 0)) then
								if menu.combo.wusage:get() == 3 and menu.combo.wcombo:get() then
									if target.pos:dist(player.pos) < spellW.range then
										local pos = preds.circular.get_prediction(spellW, target)
										if pos and player.pos:to2D():dist(pos.endPos) <= spellW.range then
											player:castSpell("pos", 1, vec3(pos.endPos.x, target.y, pos.endPos.y))
										end
									end
								end
								local pos = preds.circular.get_prediction(spellR, target)
								if pos and player.pos:to2D():dist(pos.endPos) <= spellR.range then
									player:castSpell("pos", 3, vec3(pos.endPos.x, target.y, pos.endPos.y))
								end
							end
						end
					end
				end
			end
			if menu.combo.rset.rusage:get() == 2 and (player:spellSlot(3).state == 0) then
				if (target.health / target.maxHealth) * 100 > menu.combo.rset.waster:get() then
					if
						(target.health <=
						dmglib.GetSpellDamage(0, target) + dmglib.GetSpellDamage(2, target) +	dmglib.GetSpellDamage(3, target)+
						dmglib.GetSpellDamage(3, target)
						* menu.combo.rset.rtick:get())
					 then
						if not (menu.combo.rset.wait:get()) then
							if menu.combo.wusage:get() == 3 and menu.combo.wcombo:get() then
								if target.pos:dist(player.pos) < spellW.range then
									local pos = preds.circular.get_prediction(spellW, target)
									if pos and player.pos:to2D():dist(pos.endPos) <= spellW.range then
										player:castSpell("pos", 1, vec3(pos.endPos.x, target.y, pos.endPos.y))
									end
								end
							end
							local pos = preds.circular.get_prediction(spellR, target)
							if pos and player.pos:to2D():dist(pos.endPos) <= spellR.range then
								player:castSpell("pos", 3, vec3(pos.endPos.x, target.y, pos.endPos.y))
							end
						end
						if (menu.combo.rset.wait:get()) then
							if ( (player:spellSlot(0).state == 0) or  (player:spellSlot(2).state == 0)) then
								if menu.combo.wusage:get() == 3 and menu.combo.wcombo:get() then
									if target.pos:dist(player.pos) < spellW.range then
										local pos = preds.circular.get_prediction(spellW, target)
										if pos and player.pos:to2D():dist(pos.endPos) <= spellW.range then
											player:castSpell("pos", 1, vec3(pos.endPos.x, target.y, pos.endPos.y))
										end
									end
								end
								local pos = preds.circular.get_prediction(spellR, target)
								if pos and player.pos:to2D():dist(pos.endPos) <= spellR.range then
									player:castSpell("pos", 3, vec3(pos.endPos.x, target.y, pos.endPos.y))
								end
							end
						end
					end
				end
			end
			if menu.combo.qcombo:get() then
				if (target.pos:dist(player.pos) <= spellQ.range) then
					player:castSpell("obj", 0, target)
				end
			end
			if menu.combo.ecombo:get() then
				if (target.pos:dist(player.pos) <= spellE.range) then
					if target.pos:dist(player.pos) > 500 then
						local direction = (target.pos - player.pos):norm()
						local extendedPos = player.pos + direction * 500
						local pos = preds.linear.get_prediction(spellE, target, extendedPos:to2D())
						if pos and player.pos:to2D():dist(pos.endPos) <= spellE.range then
							player:castSpell("line", 2, extendedPos, vec3(pos.endPos.x, target.y, pos.endPos.y))
						end
					end
					if target.pos:dist(player) < 500 then
						local pos = preds.linear.get_prediction(spellE, target, target)
						if pos and player.pos:to2D():dist(pos.endPos) <= spellE.range then
							player:castSpell("line", 2, target.pos, vec3(pos.endPos.x, target.y, pos.endPos.y))
						end
					end
				end
			end
			if menu.combo.wcombo:get() then
				if menu.combo.wusage:get() == 1 then
					if target.pos:dist(player.pos) < spellW.range then
						local pos = preds.circular.get_prediction(spellW, target)
						if pos and player.pos:to2D():dist(pos.endPos) <= spellW.range then
							player:castSpell("pos", 1, vec3(pos.endPos.x, target.y, pos.endPos.y))
						end
					end
				end
				if menu.combo.wusage:get() == 2 then
					if
						(common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or common.CheckBuffType(target, 10) or common.CheckBuffType(target, 11) or common.CheckBuffType(target, 22) or
						common.CheckBuffType(target, 8) or
						common.CheckBuffType(target, 21))
					 then
						if target.pos:dist(player.pos) < spellW.range then
							spellW.delay = 0.8
							local pos = preds.circular.get_prediction(spellW, target)
							if pos and player.pos:to2D():dist(pos.endPos) <= spellW.range then
								player:castSpell("pos", 1, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
							end
						end
					end
				end
			end
		end
	end
end
local function Harass()
	if (player.mana / player.maxMana) * 100 >= menu.harass.mana:get() then
		local target = GetTargetQ()
		if target and target.isVisible then
			if common.IsValidTarget(target) then
				if menu.harass.qharass:get() then
					if (target.pos:dist(player.pos) <= spellQ.range) then
						player:castSpell("obj", 0, target)
					end
				end
				if menu.harass.eharass:get() then
					if (target.pos:dist(player.pos) <= spellE.range) then
						if target.pos:dist(player.pos) > 500 then
							local direction = (target.pos - player.pos):norm()
							local extendedPos = player.pos + direction * 500
							local pos = preds.linear.get_prediction(spellE, target, extendedPos:to2D())
							if pos and player.pos:to2D():dist(pos.endPos) <= spellE.range then
								player:castSpell("line", 2, extendedPos, vec3(pos.endPos.x, target.y, pos.endPos.y))
							end
						end
						if target.pos:dist(player) < 500 then
							local pos = preds.linear.get_prediction(spellE, target, target)
							if pos and player.pos:to2D():dist(pos.endPos) <= spellE.range then
								player:castSpell("line", 2, target.pos, vec3(pos.endPos.x, target.y, pos.endPos.y))
							end
						end
					end
				end
			end
		end
	end
end


local function GetClosestJungle()
--NEUTRAL
	local closestMinion = nil
	local closestMinionDistance = 9999

	local enemyMinionsE = common.GetMinionsInRange(spellQ.range, TEAM_ENEMY)
	for i, minion in pairs(enemyMinionsE) do
		if minion then
			local minionPos = vec3(minion.x, minion.y, minion.z)
			if minionPos:dist(player.pos) < spellQ.range then
				local minionDistanceToMouse = minionPos:dist(player.pos)

				if minionDistanceToMouse < closestMinionDistance then
					closestMinion = minion
					closestMinionDistance = minionDistanceToMouse
				end
			end
		end
	end
	return closestMinion
end
local function GetClosestMinion()
	local closestMinion = nil
	local closestMinionDistance = 9999

	local enemyMinionsE = common.GetMinionsInRange(spellQ.range, TEAM_ENEMY)
	for i, minion in pairs(enemyMinionsE) do
		if minion then
			local minionPos = vec3(minion.x, minion.y, minion.z)
			if minionPos:dist(player.pos) < spellQ.range then
				local minionDistanceToMouse = minionPos:dist(player.pos)

				if minionDistanceToMouse < closestMinionDistance then
					closestMinion = minion
					closestMinionDistance = minionDistanceToMouse
				end
			end
		end
	end
	return closestMinion
end

-- Thanks to Ryan. <3
local function JungleClear()
	if uhh == true then
		if (player.mana / player.maxMana) * 100 >= menu.laneclear.jungle.mana:get() then
			if menu.laneclear.jungle.useq:get() then
				local enemyMinionsE = common.GetMinionsInRange(spellQ.range, TEAM_NEUTRAL)
				for i, minion in pairs(enemyMinionsE) do
					if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead then
						local minionPos = vec3(minion.x, minion.y, minion.z)
						if minionPos:dist(player.pos) <= spellQ.range then
							player:castSpell("obj", 0, minion)
						end
					end
				end
			end
		end
	end
end
local function LastHit()
	if menu.laneclear.lastq:get() then
		local enemyMinionsE = common.GetMinionsInRange(spellQ.range, TEAM_ENEMY)
		for i, minion in pairs(enemyMinionsE) do
			if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
					minion.pos:dist(player.pos) < spellQ.range
			 then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				--delay = player.pos:dist(minion.pos) / 3500 + 0.2
				local delay = player.path.serverPos2D:dist(minion.path.serverPos2D) / 2000 + 0.25 - network.latency
				if dmglib.GetSpellDamage(0, minion) - 10 >= orb.farm.predict_hp(minion, delay, true) then
					player:castSpell("obj", 0, minion)
				end
			end
		end
	end
end
local q_damage = function(target)
	return dmglib.spell(player, target, SpellSlot.Q)- 10
end
local q_hit_time = function(source, target)
	return source.path.serverPos2D:dist(target.path.serverPos2D) / 2000 + 0.25 - network.latency
end
local q_max_range = 700
local function LaneClear()
		if menu.laneclear.farmq:get() then
			local enemyMinionsQ = common.GetMinionsInRange(spellQ.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsQ) do
				if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead then
					local minionPos = vec3(minion.x, minion.y, minion.z)
					if minionPos:dist(player.pos) <= spellQ.range then
						player:castSpell("obj", 0, minion)
					end
				end
			end
		end
end

local function Flee()
	if menu.misc.fleekey:get() then
		player:move(mousePos)
		if menu.misc.fleeq:get() then
			local enemy = common.GetEnemyHeroes()
    		for i, enemies in ipairs(enemy) do	
				if enemies and enemies.isVisible and common.IsValidTarget(enemies) and player.pos:dist(enemies) < spellQ.range then
					player:castSpell("obj", 0, enemies)
				end
			end
			if (GetClosestMinion()) then
				player:castSpell("obj", 0, GetClosestMinion())
			end
			if (GetClosestJungle()) then
				player:castSpell("obj", 0, GetClosestJungle())
			end
		end
	end
end

local OnTick = function()
	if (player.isDead and not player.isTargetable and player.buff[17]) then return end

	spellW.delay = 1
	RFollow()
	Flee()
	if menu.misc.GapA:get() then
		WGapcloser()
	end
	if (orb.combat.is_active())  then
		Combo()
	end 
	if (orb.menu.last_hit.key:get())  then
		LastHit()
	end
	if menu.laneclear.clearkey:get() then
		LaneClear()
		JungleClear()
	end
	if (orb.menu.hybrid.key:get())then
		Harass()
	end
end

local OnDraw = function()
	if player.isOnScreen then
		if menu.draws.drawq:get() then
			graphics.draw_circle(player.pos, spellQ.range, 1, menu.draws.colorq:get(), 100)
		end
		if menu.draws.drawe:get() then
			graphics.draw_circle(player.pos, spellE.range, 1, menu.draws.colore:get(), 100)
		end
		if menu.draws.draww:get() then
			graphics.draw_circle(player.pos, spellW.range, 1, menu.draws.colorw:get(), 100)
		end
		if menu.draws.drawr:get() then
			graphics.draw_circle(player.pos, spellR.range, 1, menu.draws.colorr:get(), 100)
		end
	end
end

cb.add(cb.tick, OnTick)
cb.add(cb.spell, AutoInterrupt)
cb.add(cb.draw, OnDraw)	