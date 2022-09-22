local preds = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")

local common = module.load(header.id, "Library/common")

local spellQ = {
	range = 800,
	radius = 210,
	speed = math.huge,
	boundingRadiusMod = 0,
	delay = 0.76
}

local spellW = {
	range = 950,
	radius = 220,
	speed = math.huge,
	boundingRadiusMod = 0,
	delay = 0.75
}

local spellE = {
	range = 700,
	width = 200,
	speed = 1600,
	boundingRadiusMod = 0,
	delay = 0.25
}

local spellR = {
	range = 675
}

local spellQE = {
	range = 1250,
	width = 200,
	speed = 2000,
	boundingRadiusMod = 0,
	delay = 0.32
}

local spellQE2 = {
	range = 1100,
	width = 22.5,
	speed = 2800,
	boundingRadiusMod = 0,
	delay = 0.15
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
	["xerath"] = {
		{menuslot = "R", slot = 3, spellname = "xerathlocusofpower2", channelduration = 3}
	}
}

local menu = menu("IntnnerSyndra", "Intnner - Syndra")
--KeyBind 
menu:menu("keys", "KeyBind - Settings")
menu:header("core", "Core - Syndra")
menu.keys:keybind("combokey", "Combo", "Space", false)
menu.keys:keybind("harasskey", "Hybrid", "C", false)
menu.keys:keybind("clearkey", "LaneClear", "V", false)
menu.keys:keybind("lastkey", "LastHit", "X", false)
menu.keys:keybind("rkey", "Toggle for Combo R", "A", false)
--Combo
menu:menu("combo", "Combo - Settings")
--Q 
menu.combo:header("combosettigs", "Q - Settings")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("autoq", "^~ Dash in Target", true)
menu.combo:boolean("qecombo", "^~ Shot QE (Long Q)", true)
menu.combo:slider("qerange", "^~ Min. Range for Long Q", 1100, 800, 1150, 1)
menu.combo:boolean("slowpred", "Slow Prediction for Q + E", true)
--W b
menu.combo:header("WSETTINGS", "W - Settings")
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:boolean("wonlyStuncombo", "^~ Only Stun (When enemy is stunned)", true)
--E 
menu.combo:header("ESETTINGS", "E - Settings")
menu.combo:boolean("ecombo", "Use E", true)
--R 
menu.combo:header("rSETTINGS", "R - Settings")
menu.combo:menu("rset", "R - Settings")
menu.combo.rset:boolean("rcombo", "Use R", true)
menu.combo.rset:dropdown("rmod", "R Combo: ", 1, {"Standard", "Combo Kill"})
menu.combo.rset:slider("waster", "Min. Health Percent Enemy for use R", 15, 0, 100, 1)
--Engage Mode 
menu.combo.rset:menu("engage", "Standard - Settings")
menu.combo.rset.engage:boolean("engagemode", "Only if combo can Kill", true)
menu.combo.rset.engage:boolean("CastTarget", "Use if target is between you and the wall", true) --c1 
menu.combo.rset.engage:boolean("castlower", "Use if target low health {%}", true) --c2
menu.combo.rset.engage:boolean("castnot", "Do not use if killed by orthers spells or AA ", true) --c4
menu.combo.rset.engage:boolean("castmoreenemies", "Use more enemies near than allies", true) --c5
menu.combo.rset.engage:slider("castifmana", "Min. Mana for use R {%}", 100, 50, 500, 50) --c6
menu.combo.rset.engage:slider("castMR", "Min. Percent Health Target {%}", 200, 100, 200, 10) --c7
menu.combo.rset.engage:slider("castAround", "Auto R - Min. Enemies around {%}", 2, 1, 5, 1) --c8
menu.combo.rset.engage:slider("castplayer", "Auto R - if your health", 15, 5, 100, 5) --c3
menu.combo.rset.engage:slider("orb", "Min. Orbs for Engage", 5, 3, 7, 1)
--Whitelist 
menu.combo.rset:menu("Whitelist", "R - Whitelist")
local enemy = common.GetEnemyHeroes()
for i, allies in ipairs(enemy) do
	menu.combo.rset.Whitelist:boolean(allies.charName, "Block: " .. allies.charName, false)
end
--Manual Mode 
menu.combo:header("orthe", "Orthes - Settings")
menu.combo:keybind("qekey", "Manual Q + E", "Z", false)
menu.combo:dropdown("qemode", "^~ Manual Direction: ", 1, {"Target", "Mouse"})

menu:menu("harass", "Harass/Hybrid - Settings")
menu.harass:boolean("autoq", "Auto Q", false)
menu.harass:boolean("autoqcc", "Use under special conditions", true) 
	menu.harass.autoqcc:set("tooltip", "When the enemy is stationary or with HardBuffs")

menu.harass:header("qq", "Q - Settings")
menu.harass:boolean("qharass", "Use Q", true)
menu.harass:boolean("qeharass", "^~ Long Q (use Q + E if enemy out range)", true)
menu.harass:header("ww", "W - Settings")
menu.harass:boolean("wharass", "Use W", true)
menu.harass:header("ee", "E - Settings")
menu.harass:boolean("eharass", "Use E", true)
menu.harass:header("here", "Mana - Settings")
menu.harass:slider("mana", "Mana Manager", 30, 0, 100, 1)

menu:menu("laneclear", "WaveClear - Settings")
menu.laneclear:boolean("farmq", "Use Q to Farm", true)
menu.laneclear:slider("hitq", " ^- If Hits", 2, 0, 6, 1)
menu.laneclear:boolean("farmw", "Use W to Farm", true)
menu.laneclear:slider("hitw", " ^- If Hits", 3, 0, 6, 1)
menu.laneclear:boolean("lastq", "Use Q to Last Hit", false)
menu.laneclear:boolean("lastqaa", " ^- Only if out of Auto Attack range", false)
menu.laneclear:boolean("autolasthit", " ^- Use it Automatically", false)

menu.laneclear:header("here", "Mana - Settings")
menu.laneclear:slider("mana", "Mana Manager", 30, 0, 100, 1)

menu:menu("misc", "Misc - Settings")
--Bonus 
menu.misc:header("bonus", "Bonus - Settings")
menu.misc:boolean("disable", "Do not use AA in combo", false)
menu.misc:slider("level", "^~ Min. Level myHero", 7, 1, 18, 1)
menu.misc:boolean("logicSpells", "Do not use spells based on the damage of each spells", true)
menu.misc:header("Anti-gAB", "Anti-Gapclose - Settings")
menu.misc:boolean("GapA", "Use Anti-Gapclose", true)
menu.misc:slider("health", " ^-Only if my Health Percent < X", 50, 1, 100, 1)
menu.misc:header("Anti", "Interrupt - Settings")
menu.misc:menu("interrupt", "Interrupt Settings")
menu.misc.interrupt:boolean("inte", "Use E for Interrupt", true)
menu.misc.interrupt:menu("interruptmenu", "Interrupt - Settings")
for i = 1, #common.GetEnemyHeroes() do
	local enemy = common.GetEnemyHeroes()[i]
	local name = string.lower(enemy.charName)
	if enemy and interruptableSpells[name] then
		for v = 1, #interruptableSpells[name] do
			local spell = interruptableSpells[name][v]
			menu.misc.interrupt.interruptmenu:boolean(
				string.format(tostring(enemy.charName) .. tostring(spell.menuslot)),
				"Interrupt " .. tostring(enemy.charName) .. " " .. tostring(spell.menuslot),
				true
			)
		end
	end
end
menu.misc:header("DDDDDDDD", "Killsteal - Settings")
menu.misc:menu("killsteal", "Killsteal - Settings")
menu.misc.killsteal:boolean("ksq", "Killsteal with Q", true)
menu.misc.killsteal:boolean("ksw", "Killsteal with W", true)
menu.misc.killsteal:boolean("ksr", "Killsteal with R", true)

menu:menu("draws", "Drawings - Settings")
menu.draws:boolean("drawq", "Draw Q Range", true)
menu.draws:boolean("drawqe", "Draw QE Range", true)
menu.draws:boolean("draww", "Draw W Range", false)
menu.draws:boolean("drawe", "Draw E Range", false)
menu.draws:boolean("drawr", "Draw R Range", true)
menu.draws:boolean("drawtoggle", "Draw R Mode", true)
--menu.draws:boolean("drawball", "Draw Ball Timer", true)
menu.draws:slider("width", "Width Line Draw", 30, 10, 100, 1)


TS.load_to_menu(menu)
local MaybeItHelps = 0
local NoIdeaWhatImDoing = {}
local TargetSelectionQ = function(res, obj, dist)
	if dist < spellQ.range then
		res.obj = obj
		return true
	end
end
local TargetSelectionW = function(res, obj, dist)
	if dist < spellW.range then
		res.obj = obj
		return true
	end
end
local TargetSelectionE = function(res, obj, dist)
	if dist < spellE.range then
		res.obj = obj
		return true
	end
end
local TargetSelectionR = function(res, obj, dist)
	if dist < spellR.range then
		res.obj = obj
		return true
	end
end
local TargetSelectionQE = function(res, obj, dist)
	if dist < spellQE.range + 10 then
		res.obj = obj
		return true
	end
end
local uhhh = 0
local test = 0
local GetTargetQ = function()
	return TS.get_result(TargetSelectionQ).obj
end
local GetTargetW = function()
	return TS.get_result(TargetSelectionW).obj
end
local GetTargetE = function()
	return TS.get_result(TargetSelectionE).obj
end
local GetTargetR = function()
	return TS.get_result(TargetSelectionR).obj
end
local GetTargetQE = function()
	return TS.get_result(TargetSelectionQE).obj
end
local LastWCast = 0
local LastWused = 0
local SomePotatoDelays = 0
local Delays = 0
local aaaaaaaaaasdfsaf = 0
function is_turret_near(position)
	local hewwo = false
	if aaaaaaaaaasdfsaf < os.clock() then
		aaaaaaaaaasdfsaf = os.clock() + 0.1
		objManager.loop(
			function(obj)
				if obj and obj.pos:dist(position) < 900 and obj.team == TEAM_ENEMY and obj.type == TYPE_TURRET then
					hewwo = true
				end
			end
		)

		return hewwo
	end
end
local function WGapcloser()
	if player:spellSlot(2).state == 0 and menu.misc.GapA:get() then
		local seg = {}
		local target =
			TS.get_result(
			function(res, obj, dist)
				if dist <= spellE.range and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
					res.obj = obj
					return true
				end
			end
		).obj
		if target then
			local pred_pos = preds.core.lerp(target.path, network.latency + spellE.delay, target.path.dashSpeed)
			if pred_pos and pred_pos:dist(player.path.serverPos2D) <= spellE.range then
				seg.startPos = player.path.serverPos2D
				seg.endPos = vec2(pred_pos.x, pred_pos.y)

				player:castSpell("pos", 2, vec3(pred_pos.x, target.y, pred_pos.y))
			end
		end
	end
end

local uhh = true
local something = 0

local QLevelDamage = {70, 110, 150, 190, 230}
function QDamage(target)
	local damage = 0
	if player:spellSlot(0).level > 0 and player:spellSlot(0).level < 5 then
		damage =
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .65)), player)
	end
	if player:spellSlot(0).level > 0 and player:spellSlot(0).level == 5 then
		damage =
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .65)), player) +
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .65)), player) *
				0.15
	end
	return damage
end

function QDamage2(target)
	local damage = 0
	if player:spellSlot(0).level > 0 then
		damage =
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .65)), player)
	end
	return damage
end
local WLevelDamage = {70, 110, 150, 190, 230}
function WDamage(target)
	local damage = 0
	if player:spellSlot(1).level > 0 then
		damage =
			common.CalculateMagicDamage(target, (WLevelDamage[player:spellSlot(1).level] + (common.GetTotalAP() * .7)), player)
	end
	return damage
end
local ELevelDamage = {70, 115, 160, 205, 250}
function EDamage(target)
	local damage = 0
	if player:spellSlot(2).level > 0 then
		damage =
			common.CalculateMagicDamage(target, (ELevelDamage[player:spellSlot(2).level] + (common.GetTotalAP() * .6)), player)
	end
	return damage
end
local ECasting = 0
local function Toggle()
	if menu.keys.rkey:get() then
		if (uhh == false and os.clock() > something) then
			uhh = true
			something = os.clock() + 0.3
		end
		if (uhh == true and os.clock() > something) then
			uhh = false
			something = os.clock() + 0.3
		end
	end
end

local gapcloserstuff = 0
local uhhfarm = false
local somethingfarm = 0


local zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz = 0
local positionnnn = nil

local zzzzz = 0
local objHolder = {}
local objSomething = {}
local testW = {}
local function DeleteObj(object)
	if object then
		objSomething[object.ptr] = nil
		NoIdeaWhatImDoing[object.ptr] = 0
	end
	if object then
		testW[object.ptr] = nil
	end
end

local function CreateObj(object)
	if object and object.name then
		if (object.name:find("_W_heldTarget_buf_02")) then
			testW[object.ptr] = object
		end
	end

	if object and object.name == "Seed" and object.owner.charName == "Syndra" then
		objSomething[object.ptr] = object
		NoIdeaWhatImDoing[object.ptr] = os.clock() + 7
	end
end
local function AutoInterrupt(spell)
	if menu.misc.interrupt.inte:get() and player:spellSlot(2).state == 0 and player:spellSlot(0).state == 0 then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			local enemyName = string.lower(spell.owner.charName)
			if interruptableSpells[enemyName] then
				for i = 1, #interruptableSpells[enemyName] do
					local spellCheck = interruptableSpells[enemyName][i]
					if
						menu.misc.interrupt.interruptmenu[spell.owner.charName .. spellCheck.menuslot]:get() and
							player.pos2D:dist(spell.owner.pos2D) > spellE.range and
							string.lower(spell.name) == spellCheck.spellname
					 then
						if player.pos2D:dist(spell.owner.pos2D) < spellQE.range and common.IsValidTarget(spell.owner) then
							local pos = player.pos + 700 * (spell.owner - player.pos):norm()
							player:castSpell("pos", 0, pos)
							player:castSpell("pos", 2, pos)
						end
					end
				end
			end
		end
		if menu.misc.interrupt.inte:get() and player:spellSlot(2).state == 0 then
			if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
				local enemyName = string.lower(spell.owner.charName)
				if interruptableSpells[enemyName] then
					for i = 1, #interruptableSpells[enemyName] do
						local spellCheck = interruptableSpells[enemyName][i]
						if
							menu.misc.interrupt.interruptmenu[spell.owner.charName .. spellCheck.menuslot]:get() and
								string.lower(spell.name) == spellCheck.spellname
						 then
							if player.pos2D:dist(spell.owner.pos2D) < spellE.range and common.IsValidTarget(spell.owner) then
								player:castSpell("obj", 2, spell.owner)
							end
						end
					end
				end
			end
		end
	end
	positionnnn = nil

	if spell.owner.charName == "Syndra" then
		if spell.name == "SyndraE" or spell.name == "SyndraE5" then
			ECasting = os.clock()
			LastWCast = os.clock() + 0.4
		end
	end
	local test = 0
	if (os.clock() - zzzzz > 0.10) then
		test = 0.10
	end
	local gapcloseeeee = 0
	if (os.clock() - gapcloserstuff < 0.08) then
		gapcloseeeee = 0.08
	end

	if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY then
		if (os.clock() - MaybeItHelps < 0.5) then
			if spell.owner.charName == "Syndra" then
				if spell.name == "SyndraQ" then
					if (menu.keys.combokey:get()) then
						positionnnn = vec3(spell.endPos)
						if (spell.endPos:dist(player.pos) > 80) then
							common.DelayAction(
								function(pos)
									player:castSpell("pos", 2, pos)
								end,
								0.1 + test + gapcloseeeee,
								{positionnnn}
							)
							SomePotatoDelays = os.clock() + 0.75
						end
					--LastWCast = os.clock() + 0.75
					end
				end
			end
		end
		if menu.combo.qekey:get() then
			if spell.endPos:dist(player.pos) <= 870 then
				if spell.owner.charName == "Syndra" then
					if spell.name == "SyndraQ" then
						if (spell.endPos:dist(player.pos) > 100) then
							positionnnn = vec3(spell.endPos)
							common.DelayAction(
								function(pos)
									player:castSpell("pos", 2, pos)
								end,
								0.1 + test,
								{positionnnn}
							)
							SomePotatoDelays = os.clock() + 0.75
						--LastWCast = os.clock() + 0.75
						end
					end
				end
			end
		end
		if spell.owner.charName == "Syndra" then
			if spell.name == "SyndraW" then
				--LastWCast = os.clock() + 0.4
				LastWused = os.clock() + network.latency + 0.020
				Delays = os.clock() + 1
			end
			if spell.name == "SyndraWCast" then
				uhhh = 0
				zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz = os.clock() + 0.2
			end
		end
	end
end

local function LastHit()
	if menu.laneclear.lastq:get() then
		for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
			local minion = objManager.minions[TEAM_ENEMY][i]
			if
				minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
					minion.pos:dist(player.pos) <= spellQ.range
			 then
				local minionPos = vec3(minion.x, minion.y, minion.z)
				--delay = player.pos:dist(minion.pos) / 3500 + 0.2
				local delay = 1.2

				if (QDamage2(minion) >= orb.farm.predict_hp(minion, delay / 2, true)) then
					if not (menu.laneclear.lastqaa:get()) then
						player:castSpell("obj", 0, minion)
					end
					if (menu.laneclear.lastqaa:get()) and minion.pos:dist(player.pos) > 630 then
						player:castSpell("obj", 0, minion)
					end
				end
			end
		end
	end
end

function Objects()
	local orbs = nil

	local closestMinion = nil
	local closestMinionDistance = 9999
	local lowest = 9999999999

	for _, objsq in pairs(objSomething) do
		if objsq and not objsq.isDead then
			if vec3(objsq.x, objsq.y, objsq.z):dist(player.pos) <= spellW.range then
				local minionPos = vec3(objsq.x, objsq.y, objsq.z)
				local minionDistanceToMouse = minionPos:dist(player.pos)

				if lowest > NoIdeaWhatImDoing[objsq.ptr] then
					lowest = NoIdeaWhatImDoing[objsq.ptr]
					orbs = objsq
					closestMinionDistance = minionDistanceToMouse
				end
			end
		end
	end
	local enemyMinions = common.GetMinionsInRange(spellW.range, TEAM_ENEMY)

	local closestMinion = nil
	local closestMinionDistance = 9999

	for i, minion in pairs(enemyMinions) do
		if minion then
			local minionPos = vec3(minion.x, minion.y, minion.z)

			local minionDistanceToMouse = minionPos:dist(player.pos)

			if minionDistanceToMouse < closestMinionDistance then
				closestMinion = minion
				closestMinionDistance = minionDistanceToMouse
			end
		end
	end
	local jungleMinions = common.GetMinionsInRange(spellW.range, TEAM_NEUTRAL)

	local closestJungle = nil
	local closestJungleDistance = 9999

	for i, minion in pairs(jungleMinions) do
		if minion then
			local minionPos = vec3(minion.x, minion.y, minion.z)

			local minionDistanceToMouse = minionPos:dist(player.pos)

			if minionDistanceToMouse < closestMinionDistance then
				closestJungle = minion
				closestJungleDistance = minionDistanceToMouse
			end
		end
	end
	if (orbs) then
		return orbs
	end
	if not orbs then
		if (closestMinion) then
			return closestMinion
		end
		if (closestJungle) then
			return closestJungle
		end
	end
end
local MainRDamage = {90, 135, 180}
function RDamage(target)
	local damage = 0
	local calculate = 0
	if player:spellSlot(3).level > 0 then
		if (player:spellSlot(3).stacks <= 3) then
			calculate = (MainRDamage[player:spellSlot(3).level] + (common.GetTotalAP() * 0.2)) * 3
		end
		if (player:spellSlot(3).stacks > 3) then
			calculate = (MainRDamage[player:spellSlot(3).level] + (common.GetTotalAP() * 0.2)) * (player:spellSlot(3).stacks)
		end

		damage = common.CalculateMagicDamage(target, calculate)
	end

	return damage - target.healthRegenRate * 10
end

local function Killsteal()
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
		if enemies and enemies.isVisible and common.IsValidTarget(enemies) and not common.CheckBuffType(enemies, 17) then
			local hp = common.GetShieldedHealth("ap", enemies)
			if menu.misc.killsteal.ksq:get() then
				if
					player:spellSlot(0).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < spellQ.range and
						QDamage(enemies) > hp
				 then
					local pos = preds.circular.get_prediction(spellQ, enemies)
					if pos and pos.startPos:dist(pos.endPos) < spellQ.range then
						player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
					end
				end
			end
			if menu.misc.killsteal.ksw:get() then
				if
					player:spellSlot(1).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < spellW.range - 80 and
						WDamage(enemies) > hp
				 then
					if (Objects()) then
						if
							(player:spellSlot(1).name == "SyndraW") and os.clock() - LastWCast > 0.26 + network.latency and
								os.clock() - ECasting > 0.24 + network.latency
						 then
							player:castSpell("pos", 1, Objects().pos)
							LastWCast = os.clock()
							zzzzz = os.clock()
						end

						if player:spellSlot(1).name ~= "SyndraW" then
							if not common.CheckBuff(enemies, "SyndraEDebuff") and not enemies.isDashing then
								local pos = preds.circular.get_prediction(spellW, enemies)
								if pos and pos.startPos:dist(pos.endPos) < spellW.range then
									player:castSpell("pos", 1, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
								end
							end
						end
					end
				end
			end
			if menu.misc.killsteal.ksr:get() then
				if
					player:spellSlot(3).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < spellR.range and
						hp < RDamage(enemies) and
						(enemies.health / enemies.maxHealth) * 100 > 15
				 then
					player:castSpell("obj", 3, enemies)
				end
			end
		end
	end
end

local function count_minions_in_range(pos, range)
	local enemies_in_range = {}
	for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
		local enemy = objManager.minions[TEAM_ENEMY][i]
		if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

local function count_minions_in_range(pos, range)
	local enemies_in_range = {}
	for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
		local enemy = objManager.minions[TEAM_ENEMY][i]
		if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

local function LaneClear()
	local aaa = 0
	if (player:spellSlot(1).name ~= "SyndraW") then
		aaa = 1
	else
		aaa = 0
	end

	if uhhfarm == true then
		if (player.mana / player.maxMana) * 100 >= menu.laneclear.mana:get() then
			if menu.laneclear.farmq:get() then
				local minions = objManager.minions
				for a = 0, minions.size[TEAM_ENEMY] - 1 do
					local minion1 = minions[TEAM_ENEMY][a]
					if
						minion1 and not minion1.isDead and minion1.isVisible and
							player.path.serverPos:distSqr(minion1.path.serverPos) <= (spellQ.range * spellQ.range)
					 then
						local count = 0
						for b = 0, minions.size[TEAM_ENEMY] - 1 do
							local minion2 = minions[TEAM_ENEMY][b]
							if
								minion2 and minion2 ~= minion1 and not minion2.isDead and minion2.isVisible and
									minion2.path.serverPos:distSqr(minion1.path.serverPos) <= (spellQ.radius * spellQ.radius)
							 then
								count = count + 1
							end
							if count >= menu.laneclear.hitq:get() then
								local seg = preds.circular.get_prediction(spellQ, minion1)
								if seg and seg.startPos:dist(seg.endPos) < spellQ.range then
									player:castSpell("pos", 0, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
									--orb.core.set_server_pause()
									break
								end
							end
						end
					end
				end
				local enemyMinionsE = common.GetMinionsInRange(spellQ.range, TEAM_ENEMY)
				for i, minion in pairs(enemyMinionsE) do
					if minion and minion.path.count == 0 and not minion.isDead and common.IsValidTarget(minion) then
						local minionPos = vec3(minion.x, minion.y, minion.z)
						if minionPos then
							if
								#count_minions_in_range(minionPos, spellQ.radius) >= menu.laneclear.hitq:get() and
									#count_minions_in_range(minionPos, spellQ.range) < 7
							 then
								local seg = preds.circular.get_prediction(spellQ, minion)
								if seg and seg.startPos:dist(seg.endPos) < spellQ.range then
									player:castSpell("pos", 0, vec3(seg.endPos.x, minionPos.y, seg.endPos.y))
								end
							end
						end
					end
				end
			end
			if menu.laneclear.farmw:get() then
				local minions = objManager.minions
				for a = 0, minions.size[TEAM_ENEMY] - 1 do
					local minion1 = minions[TEAM_ENEMY][a]
					if
						minion1 and not minion1.isDead and minion1.isVisible and
							player.path.serverPos:distSqr(minion1.path.serverPos) <= (spellW.range * spellW.range)
					 then
						local count = 0
						for b = 0, minions.size[TEAM_ENEMY] - 1 do
							local minion2 = minions[TEAM_ENEMY][b]
							if
								minion2 and minion2 ~= minion1 and not minion2.isDead and minion2.isVisible and
									minion2.path.serverPos:distSqr(minion1.path.serverPos) <= (spellW.radius * spellW.radius)
							 then
								count = count + 1
							end
							if count >= menu.laneclear.hitw:get() then
								if (Objects()) then
									if
										(player:spellSlot(1).name == "SyndraW") and os.clock() - LastWCast > 0.26 + network.latency and
											os.clock() - ECasting > 0.24 + network.latency
									 then
										player:castSpell("pos", 1, Objects().pos)
										LastWCast = os.clock()
										zzzzz = os.clock()
									end
									if (player:spellSlot(1).name ~= "SyndraW") then
										local pos = preds.circular.get_prediction(spellW, minion1)
										if pos and pos.startPos:dist(pos.endPos) < spellW.range then
											player:castSpell("pos", 1, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
										end
									end
								end
							end
							if (#count_minions_in_range(player.pos, spellW.range) == 0) then
								if (player:spellSlot(1).name ~= "SyndraW") then
									player:castSpell("pos", 1, vec3(player.pos))
								end
							end
						end
					end
				end

				local enemyMinionsE = common.GetMinionsInRange(spellW.range, TEAM_ENEMY)
				for i, minion in pairs(enemyMinionsE) do
					if minion and minion.path.count == 0 and not minion.isDead and common.IsValidTarget(minion) then
						local minionPos = vec3(minion.x, minion.y, minion.z)
						if minionPos then
							if
								#count_minions_in_range(minionPos, spellW.radius) + aaa >= menu.laneclear.hitw:get() and
									#count_minions_in_range(minionPos, spellW.range) < 7 + aaa
							 then
								if (Objects()) then
									if
										(player:spellSlot(1).name == "SyndraW") and os.clock() - LastWCast > 0.26 + network.latency and
											os.clock() - ECasting > 0.24 + network.latency
									 then
										player:castSpell("pos", 1, Objects().pos)
										LastWCast = os.clock()
										zzzzz = os.clock()
									end
									if (player:spellSlot(1).name ~= "SyndraW") then
										local pos = preds.circular.get_prediction(spellW, minion)
										if pos and pos.startPos:dist(pos.endPos) < spellW.range then
											player:castSpell("pos", 1, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
										end
									end
								end
							end
							if (#count_minions_in_range(player.pos, spellW.range) == 0) then
								if (player:spellSlot(1).name ~= "SyndraW") then
									player:castSpell("pos", 1, vec3(player.pos))
								end
							end
						end
					end
				end
			end
		end
	end
end
local function QEFilter(seg, obj)
	if preds.trace.linear.hardlock(spellQE2, seg, obj) then
		return true
	end
	if preds.trace.linear.hardlockmove(spellQE2, seg, obj) then
		return true
	end
	if preds.trace.newpath(obj, 0.033, 0.5) then
		return true
	end
end
local function Combo()
	for i = 6, 11 do
		local item = player:spellSlot(i).name

		if item and item == "3907Cast" and player:spellSlot(i).state == 0 then
			local target = GetTargetQ()
			if target and target.isVisible then
				if common.IsValidTarget(target) then
					if (target.pos:dist(player.pos) <= spellQ.range) then
						player:castSpell("self", i)
					end
				end
			end
		end
	end
	if (menu.combo.qcombo:get()) then
		local target = GetTargetQ()
		if target and target.isVisible then
			if common.IsValidTarget(target) then
				
				local seg = { }

				seg.startPos = vec2(player.x, player.z)
				seg.endPos = vec2(target.x, target.z)
	
				if seg.startPos and seg.endPos then 

					if (target.pos:dist(player.pos) <= spellQ.range) then
						local pos = preds.circular.get_prediction(spellQ, target, vec2(player.x, player.z))
						if pos and pos.startPos:distSqr(pos.endPos) <= spellQ.range ^ 2 and pos.endPos and player.pos:distSqr(vec3(pos.endPos.x, target.pos.y, pos.endPos.y)) < spellQ.range ^ 2 then 
							player:castSpell("pos", 0, vec3(pos.endPos.x, target.y, pos.endPos.y))
						end
					end
				end 
			end
		end
	end
	if (menu.combo.wcombo:get()) then
		local target = GetTargetW()
		if target and target.isVisible then
			if common.IsValidTarget(target) then
				if (target.pos:dist(player.pos) <= spellW.range - 30) then
					if target and target.isVisible then
						if (Objects()) then
							local pos = preds.circular.get_prediction(spellW, target)
							if pos and pos.startPos:dist(pos.endPos) < spellW.range then
								if
									(player:spellSlot(1).name == "SyndraW") and os.clock() - LastWCast > 0.26 + network.latency and
										os.clock() - ECasting > 0.24 + network.latency
								 then
									player:castSpell("pos", 1, Objects().pos)
									LastWCast = os.clock()
									zzzzz = os.clock()
								end

								if player:spellSlot(1).name ~= "SyndraW" and not target.isDashing then
									if not common.CheckBuff(target, "SyndraEDebuff") then
										player:castSpell("pos", 1, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if os.clock() - LastWCast > 0.1 + network.latency then
		if menu.combo.ecombo:get() then
			local enemy = common.GetEnemyHeroes()
			for i, target in ipairs(enemy) do
				if target and target.isVisible and common.IsValidTarget(target) and not common.CheckBuffType(target, 17) then
					if common.IsValidTarget(target) then
						if (target.pos:dist(player.pos) <= spellQE.range) then
							for _, objsq in pairs(objSomething) do
								if objsq and not objsq.isDead then
									if vec3(objsq.x, objsq.y, objsq.z):dist(player.pos) <= spellQE.range then
										if
											(vec3(objsq.x, objsq.y, objsq.z):dist(player.pos) <= spellE.range) and
												player.pos:dist(vec3(objsq.x, objsq.y, objsq.z)) >= 100 and
												target.pos:dist(player.pos) <= 1100
										 then
											local pos = preds.linear.get_prediction(spellQE, target)
											if pos and pos.startPos:dist(pos.endPos) <= spellQE.range then
												local BallPosition = vec3(objsq.x, objsq.y, objsq.z)
												local direction = (BallPosition - player.pos):norm()
												local distance = player.pos:dist(vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
												local extendedPos = player.pos + direction * distance
												if
													(extendedPos:dist(vec3(pos.endPos.x, mousePos.y, pos.endPos.y)) <
														spellQE.width + target.boundingRadius - 20) and
														target.pos:dist(player.pos) >= 50 and
														objsq.pos:dist(player.pos) >= 80 and
														player.pos:dist(target.pos) <= spellQE.range
												 then
													player:castSpell("pos", 2, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if menu.combo.qecombo:get() then
		if not menu.combo.slowpred:get() then
			local target = GetTargetQE()
			if target and target.isVisible then
				if common.IsValidTarget(target) and player.mana > player.manaCost0 + player.manaCost2 then
					if (target.pos:dist(player.pos) <= spellQE.range) then
						if target.pos:dist(player.pos) > 1000 then
							spellQE2.delay = 0.24
						end
						if target.pos:dist(player.pos) < 1000 and target.pos:dist(player.pos) > 900 then
							spellQE2.delay = 0.16
						end
						if target.pos:dist(player.pos) < 900 then
							spellQE2.delay = 0.25
						end
						if
							(target.path.count > 0) or
								(common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or
									common.CheckBuffType(target, 11) or
									common.CheckBuffType(target, 22) or
									common.CheckBuffType(target, 21))
						 then
							local pos = preds.linear.get_prediction(spellQE2, target)
							if pos and pos.startPos:dist(pos.endPos) <= spellQE.range then
								local pos = player.pos + 700 * (vec3(pos.endPos.x, mousePos.y, pos.endPos.y) - player.pos):norm()
								if (target.pos:dist(player.pos) > spellE.range) and player:spellSlot(2).state == 0 then
									player:castSpell("pos", 0, pos)

									MaybeItHelps = os.clock()
								end
							end
						end
					end
				end
			end
		end
		if menu.combo.slowpred:get() then
			local target = GetTargetQE()
			if target and target.isVisible then
				if common.IsValidTarget(target) and player.mana > player.manaCost0 + player.manaCost2 then
					if (target.pos:dist(player.pos) <= spellQE.range) then
						if target.pos:dist(player.pos) > 1000 then
							spellQE2.delay = 0.24
						end
						if target.pos:dist(player.pos) < 1000 and target.pos:dist(player.pos) > 900 then
							spellQE2.delay = 0.16
						end
						if target.pos:dist(player.pos) < 900 then
							spellQE2.delay = 0.25
						end
						if
							(target.path.count > 0) or
								(common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or
									common.CheckBuffType(target, 11) or
									common.CheckBuffType(target, 22) or
									common.CheckBuffType(target, 21))
						 then
							local pos = preds.linear.get_prediction(spellQE2, target)
							if pos and QEFilter(pos, target) and pos.startPos:dist(pos.endPos) <= spellQE.range then
								local pos = player.pos + 700 * (vec3(pos.endPos.x, mousePos.y, pos.endPos.y) - player.pos):norm()
								if (target.pos:dist(player.pos) > spellE.range) and player:spellSlot(2).state == 0 then
									player:castSpell("pos", 0, pos)

									MaybeItHelps = os.clock()
								end
							end
						end
					end
				end
			end
		end
	end
	if menu.combo.rset.rcombo:get() then
		local mode = menu.combo.rset.rmod:get()
		local target = GetTargetR()
		if target and target.isVisible then
			if common.IsValidTarget(target) then
				if
					(target.pos:dist(player.pos) <= spellR.range) and
						(target.health / target.maxHealth) * 100 >= menu.combo.rset.waster:get()
				 then
					if (mode == 2) then
						if menu.combo.rset.Whitelist[target.charName] and menu.combo.rset.Whitelist[target.charName]:get() then
							if (RDamage(target) > target.health) then
								player:castSpell("obj", 3, target)
							end
						end
					end
					if (mode == 1) then
						if menu.combo.rset.Whitelist[target.charName] and menu.combo.rset.Whitelist[target.charName]:get() then
							if player:spellSlot(3).stacks >= menu.combo.rset.engage.orb:get() then
								if not menu.combo.rset.engage.engagemode:get() then
									player:castSpell("obj", 3, target)
								end
								if menu.combo.rset.engage.engagemode:get() then
									local damages = RDamage(target) + QDamage(target) + WDamage(target) + EDamage(target)
									if (target.health <= damages) then
										player:castSpell("obj", 3, target)
									end
								end
							end
						end
					end
				end
			end
		end
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

function QEKey()
	if menu.combo.qekey:get() then
		player:move(mousePos)
		local mousesomething = player.pos + (mousePos - player.pos):norm() * 800

		if menu.combo.qemode:get() == 1 then
			local target = GetTargetQE()

			if common.IsValidTarget(target) and player.mana > player.manaCost0 + player.manaCost2 then
				if common.IsValidTarget(target) then
					if (target.pos:dist(player.pos) <= spellQE.range) then
						if target.pos:dist(player.pos) > 1000 then
							spellQE2.delay = 0.24
						end
						if target.pos:dist(player.pos) < 1000 and target.pos:dist(player.pos) > 900 then
							spellQE2.delay = 0.16
						end
						if target.pos:dist(player.pos) < 900 then
							spellQE2.delay = 0.25
						end

						if
							(target.path.count > 0) or
								(common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or
									common.CheckBuffType(target, 11) or
									common.CheckBuffType(target, 22) or
									common.CheckBuffType(target, 21))
						 then
							local pos = preds.linear.get_prediction(spellQE2, target)
							if pos and pos.startPos:dist(pos.endPos) <= spellQE.range then
								local pos = player.pos + 700 * (vec3(pos.endPos.x, mousePos.y, pos.endPos.y) - player.pos):norm()
								if player:spellSlot(2).state == 0 then
									player:castSpell("pos", 0, pos)
								end
							end
						end
					end
				end
			end
		end
		if menu.combo.qemode:get() == 2 then
			if (mousePos:dist(player.pos) > 800) then
				player:castSpell("pos", 0, mousesomething)
			end
			if (mousePos:dist(player.pos) < 800) then
				player:castSpell("pos", 0, mousePos)
			end
		end
		if menu.combo.qemode:get() == 3 then
			if (#count_enemies_in_range(player.pos, spellQE.range) == 0) then
				if (mousePos:dist(player.pos) > 800) then
					player:castSpell("pos", 0, mousesomething)
				end
				if (mousePos:dist(player.pos) < 800) then
					player:castSpell("pos", 0, mousePos)
				end
			end
			if (#count_enemies_in_range(player.pos, spellQE.range) > 0) then
				local target = GetTargetQE()

				if target and target.isVisible then
					if common.IsValidTarget(target) and player.mana > player.manaCost0 + player.manaCost2 then
						if (target.pos:dist(player.pos) <= spellQE.range) then
							if target.pos:dist(player.pos) > 1000 then
								spellQE2.delay = 0.24
							end
							if target.pos:dist(player.pos) < 1000 and target.pos:dist(player.pos) > 900 then
								spellQE2.delay = 0.16
							end
							if target.pos:dist(player.pos) < 900 then
								spellQE2.delay = 0.25
							end

							if
								(target.path.count > 0) or
									(common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or
										common.CheckBuffType(target, 11) or
										common.CheckBuffType(target, 22) or
										common.CheckBuffType(target, 21))
							 then
								local pos = preds.linear.get_prediction(spellQE2, target)
								if pos and pos.startPos:dist(pos.endPos) <= spellQE.range then
									local pos = player.pos + 700 * (vec3(pos.endPos.x, mousePos.y, pos.endPos.y) - player.pos):norm()
									if player:spellSlot(2).state == 0 then
										player:castSpell("pos", 0, pos)
									end
								end
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
		if (menu.harass.qharass:get()) then
			local target = GetTargetQ()
			if target and target.isVisible then
				if common.IsValidTarget(target) then
					if (target.pos:dist(player.pos) <= spellQ.range) then
						local pos = preds.circular.get_prediction(spellQ, target)
						if pos and pos.startPos:dist(pos.endPos) <= spellQ.range then
							player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
						end
					end
				end
			end
		end
		if (menu.harass.wharass:get()) then
			local target = GetTargetW()
			if target and target.isVisible then
				if common.IsValidTarget(target) then
					if (target.pos:dist(player.pos) <= spellW.range - 30) then
						if target and target.isVisible then
							if (Objects()) then
								if
									(player:spellSlot(1).name == "SyndraW") and os.clock() - LastWCast > 0.26 + network.latency and
										os.clock() - ECasting > 0.24 + network.latency
								 then
									player:castSpell("pos", 1, Objects().pos)
									LastWCast = os.clock()
									zzzzz = os.clock()
								end

								if player:spellSlot(1).name ~= "SyndraW" and not target.isDashing then
									if not common.CheckBuff(target, "SyndraEDebuff") then
										local pos = preds.circular.get_prediction(spellW, target, Objects().pos:to2D())
										if pos and pos.startPos:dist(pos.endPos) < spellW.range then
											player:castSpell("pos", 1, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
										end
									end
								end
							end
						end
					end
				end
			end
		end
		if os.clock() - LastWCast > 0.1 + network.latency then
			if menu.harass.eharass:get() then
				for i, target in ipairs(enemy) do
					if target and target.isVisible and common.IsValidTarget(target) and not common.CheckBuffType(target, 17) then
						if common.IsValidTarget(target) then
							if (target.pos:dist(player.pos) <= spellQE.range) then
								for _, objsq in pairs(objSomething) do
									if objsq and not objsq.isDead then
										if vec3(objsq.x, objsq.y, objsq.z):dist(player.pos) <= spellQE.range then
											if
												(vec3(objsq.x, objsq.y, objsq.z):dist(player.pos) <= spellE.range) and
													player.pos:dist(vec3(objsq.x, objsq.y, objsq.z)) >= 170 and
													target.pos:dist(player.pos) <= 1100
											 then
												local pos = preds.linear.get_prediction(spellQE, target)
												if pos and pos.startPos:dist(pos.endPos) <= spellQE.range then
													local BallPosition = vec3(objsq.x, objsq.y, objsq.z)
													local direction = (BallPosition - player.pos):norm()
													local distance = player.pos:dist(vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
													local extendedPos = player.pos + direction * distance
													if
														(extendedPos:dist(vec3(pos.endPos.x, mousePos.y, pos.endPos.y)) <
															spellQE.width + target.boundingRadius - 20) and
															target.pos:dist(player.pos) >= 50 and
															objsq.pos:dist(player.pos) >= 80 and
															player.pos:dist(target.pos) <= spellQE.range
													 then
														player:castSpell("pos", 2, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
		if menu.harass.qeharass:get() then
			local target = GetTargetQE()
			if target and target.isVisible then
				if common.IsValidTarget(target) and player.mana > player.manaCost0 + player.manaCost2 then
					if (target.pos:dist(player.pos) <= spellQE.range) then
						if target.pos:dist(player.pos) > 1000 then
							spellQE2.delay = 0.24
						end
						if target.pos:dist(player.pos) < 1000 and target.pos:dist(player.pos) > 900 then
							spellQE2.delay = 0.16
						end
						if target.pos:dist(player.pos) < 900 then
							spellQE2.delay = 0.25
						end
						if
							(target.path.count > 0) or
								(common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or
									common.CheckBuffType(target, 11) or
									common.CheckBuffType(target, 22) or
									common.CheckBuffType(target, 21))
						 then
							local pos = preds.linear.get_prediction(spellQE2, target)
							if pos and pos.startPos:dist(pos.endPos) <= spellQE.range then
								local pos = player.pos + 700 * (vec3(pos.endPos.x, mousePos.y, pos.endPos.y) - player.pos):norm()
								if (target.pos:dist(player.pos) > spellE.range) and player:spellSlot(2).state == 0 then
									player:castSpell("pos", 0, pos)
								end
							end
						end
					end
				end
			end
		end
	end
end

function DrawDamagesE(target)
	if target.isVisible and not target.isDead then
		local pos = graphics.world_to_screen(target.pos)
		if (math.floor((RDamage(target)) / target.health * 100) < 100) then
			graphics.draw_line_2D(pos.x, pos.y - 30, pos.x + 30, pos.y - 80, 1, graphics.argb(255, 255, 153, 51))
			graphics.draw_line_2D(pos.x + 30, pos.y - 80, pos.x + 50, pos.y - 80, 1, graphics.argb(255, 255, 153, 51))
			graphics.draw_line_2D(pos.x + 50, pos.y - 85, pos.x + 50, pos.y - 75, 1, graphics.argb(255, 255, 153, 51))

			graphics.draw_text_2D(
				tostring("R: " .. math.floor(RDamage(target))) ..
					" (" .. tostring(math.floor((RDamage(target)) / target.health * 100)) .. "%)" .. "Not Killable",
				20,
				pos.x + 55,
				pos.y - 80,
				graphics.argb(255, 255, 153, 51)
			)
		end
		if (math.floor((RDamage(target)) / target.health * 100) >= 100) then
			graphics.draw_line_2D(pos.x, pos.y - 30, pos.x + 30, pos.y - 80, 1, graphics.argb(255, 150, 255, 200))
			graphics.draw_line_2D(pos.x + 30, pos.y - 80, pos.x + 50, pos.y - 80, 1, graphics.argb(255, 150, 255, 200))
			graphics.draw_line_2D(pos.x + 50, pos.y - 85, pos.x + 50, pos.y - 75, 1, graphics.argb(255, 150, 255, 200))
			graphics.draw_text_2D(
				tostring("R: " .. math.floor(RDamage(target))) ..
					" (" .. tostring(math.floor((RDamage(target)) / target.health * 100)) .. "%)" .. "Kilable",
				20,
				pos.x + 55,
				pos.y - 80,
				graphics.argb(255, 150, 255, 200)
			)
		end
	end
end

local function OnDraw()
	if player.isOnScreen then
		if menu.draws.drawq:get() and player:spellSlot(0).state == 0 then
			graphics.draw_circle(player.pos, spellQ.range, 1, 0xFF00FFFF, menu.draws.width:get())
		end
		if menu.draws.drawe:get()  and player:spellSlot(2).state == 0 then
			graphics.draw_circle(player.pos, spellE.range, 1, 0xFF00FFFF, menu.draws.width:get())
		end
		if menu.draws.drawqe:get() and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then
			graphics.draw_circle(player.pos, spellQE.range, 1, 0xFF00FFFF, menu.draws.width:get())
		end
		if menu.draws.draww:get() and player:spellSlot(1).state == 0 then
			graphics.draw_circle(player.pos, spellW.range, 1, 0xFF00FFFF, menu.draws.width:get())
		end
		if menu.draws.drawr:get() and player:spellSlot(3).state == 0 then
			graphics.draw_circle(player.pos, spellR.range, 1, 0xFF00FFFF, menu.draws.width:get())
		end
	end

	if menu.draws.drawtoggle:get() then
		local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
		if uhh == false then
			graphics.draw_text_2D("R Combo: ", 17, pos.x - 20, pos.y + 30, graphics.argb(255, 255, 255, 255))
			graphics.draw_text_2D("Standard", 17, pos.x + 55, pos.y + 30, graphics.argb(255, 9, 214, 63))
		else
			graphics.draw_text_2D("R Combo: ", 17, pos.x - 20, pos.y + 30, graphics.argb(255, 255, 255, 255))
			graphics.draw_text_2D("Killsteal", 17, pos.x + 55, pos.y + 30, graphics.argb(255, 9, 214, 63))
		end
	end
end

local function AutoDash()
	local target =
		TS.get_result(
		function(res, obj, dist)
			if dist <= spellQ.range and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
				res.obj = obj
				return true
			end
		end
	).obj
	if target then
		local pred_pos = preds.core.lerp(target.path, network.latency + spellQ.delay, target.path.dashSpeed)
		if pred_pos and pred_pos:dist(player.path.serverPos2D) <= spellQ.range then
			--orb.core.set_server_pause()
			player:castSpell("pos", 0, vec3(pred_pos.x, target.y, pred_pos.y))
			gapcloserstuff = os.clock()
		end
	end
end

local function OnTick()
	if (os.clock() - zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz > 0) then
		for _, objsw in pairs(testW) do
			if objsw then
				for _, objsq in pairs(objSomething) do
					if objsq and not objsq.isDead then
						if (objsq.pos:dist(objsw.pos) < 80 and uhhh ~= objsq.ptr) then
							uhhh = objsq.ptr

							NoIdeaWhatImDoing[objsq.ptr] = os.clock() + 7
							test = os.clock() + 7
						end
					end
				end
			end
		end
	end

	if (Objects() and player:spellSlot(2).state ~= 0) then
		spellW.delay = 0.15 + Objects().pos:dist(player.pos) / 3000
	end
	QEKey()
	Killsteal()
	if menu.harass.autoqcc:get() then
		if (player.mana / player.maxMana) * 100 >= menu.harass.mana:get() then
			local target = GetTargetQ()
			if target and target.isVisible then
				if common.IsValidTarget(target) then
					if (target.pos:dist(player.pos) <= spellQ.range) then
						local pos = preds.circular.get_prediction(spellQ, target)
						if pos and pos.startPos:dist(pos.endPos) <= spellQ.range then
							if
								(common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or
									common.CheckBuffType(target, 11) or
									common.CheckBuffType(target, 22) or
									common.CheckBuffType(target, 21))
							 then
								player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
									zzzzz = os.clock()
							end
						end
					end
				end
			end
		end
	end
	if menu.harass.autoq:get() then
		if (player.mana / player.maxMana) * 100 >= menu.harass.mana:get() then
			local target = GetTargetQ()
			if target and target.isVisible then
				if common.IsValidTarget(target) then
					if (target.pos:dist(player.pos) <= spellQ.range) then
						local pos = preds.circular.get_prediction(spellQ, target)
						if pos and pos.startPos:dist(pos.endPos) <= spellQ.range then
							player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
						end
					end
				end
			end
		end
	end
	if orb.combat.is_active() and menu.misc.logicSpells:get() then
		if player:spellSlot(2).state ~= 0 and player:spellSlot(1).state ~= 0 and player:spellSlot(0).state ~= 0 then
			orb.core.set_pause_attack(0)
		end
	end
	if (orb.combat.is_active()) then
		if (menu.misc.disable:get() and menu.misc.level:get() <= player.levelRef) and player.mana > 100 then
			if not menu.misc.logicSpells:get() then
				orb.core.set_pause_attack(math.huge)
			end
			if menu.misc.logicSpells:get() then
				if player:spellSlot(2).state == 0 or player:spellSlot(1).state == 0 or player:spellSlot(0).state == 0 then
					orb.core.set_pause_attack(math.huge)
				end
			end
		end
	end
	if orb.combat.is_active() and player.mana < 100 then
		orb.core.set_pause_attack(0)
	end

	if not orb.combat.is_active() then
		if orb.core.is_attack_paused() then
			orb.core.set_pause_attack(0)
		end
	end
	if menu.combo.autoq:get() then
		AutoDash()
	end
	spellQE.range = menu.combo.qerange:get()
	if player:spellSlot(3).level == 3 then
		spellR.range = 750
	end
	Toggle()
	if (uhh == true) and menu.combo.rset.rmod:get() == 1 then
		menu.combo.rset.rmod:set("value", 2)
	end
	if (uhh == false) and menu.combo.rset.rmod:get() == 2 then
		menu.combo.rset.rmod:set("value", 1)
	end
	if menu.misc.GapA:get() then
		WGapcloser()
	end
	if (menu.keys.combokey:get()) then
		Combo()
	end

	if (menu.keys.harasskey:get()) then
		Harass()
	end
	if menu.laneclear.autolasthit:get() then
		if (player.mana / player.maxMana) * 100 >= menu.laneclear.mana:get() then
			LastHit()
		end
	end
	if (menu.keys.lastkey:get()) then
		LastHit()
	end
	if (menu.keys.clearkey:get()) then
		LaneClear()
	end
end

orb.combat.register_f_pre_tick(OnTick)

cb.add(cb.draw, OnDraw)
cb.add(cb.create_minion, CreateObj)
cb.add(cb.delete_minion, DeleteObj)
cb.add(cb.spell, AutoInterrupt)
