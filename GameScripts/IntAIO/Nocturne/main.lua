local evade = module.seek("evade")
local preds = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")
local common = module.load(header.id, "Library/common")
local database = module.load(header.id, "Core/Nocturne/SpellDatabase")
local spellQ = {
	range = 1150,
	width = 60,
	speed = 1500,
	delay = 0.25,
	boundingRadiusMod = 1
}

local spellW = {range = 400}

local spellE = {
	range = 425
}

local spellR = {
	range = 2500
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
local str = {[-1] = "P", [0] = "Q", [1] = "W", [2] = "E", [3] = "R"}
local menu = menu("IntnnerNocturne", "Int Nocturne")

menu:menu("combo", "Combo")
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("ecombo", "Use W", true)
menu.combo:boolean("rcombo", "Use R", true)
menu.combo:slider("hpr", "Min. R Range >= {0}", 500, 0, 1000, 5)
menu.combo:slider("dontr", "no use R in Enemies", 3, 2, 5, 1)

menu:menu("harass", "Harass")
menu.harass:boolean("qcombo", "Use Q", true)
menu.harass:boolean("ecombo", "Use E", true)

menu:menu("jungleclear", "JungleClear")
menu.jungleclear:boolean("useq", "Use Q", true)
menu.jungleclear:boolean("usee", "Use E", true)

menu:menu("draws", "Drawings")
menu.draws:boolean("drawq", "Q Range", true)
menu.draws:color("colorq", "Color", 255, 255, 255, 255)
menu.draws:boolean("drawe", "E Range", true)
menu.draws:color("colore", "Color", 255, 255, 255, 255)
menu.draws:boolean("drawr", "R Range", true)
menu.draws:color("colorr", "Color", 255, 0x66, 0x33, 0x00)

menu:menu("misc", "Misc")
menu.misc:menu("Gap", "Gapcloser")
menu.misc.Gap:boolean("GapA", "Use E for Anti-Gapclose", true)
menu.misc:menu("interrupt", "Interrupt")
menu.misc.interrupt:boolean("inte", "Use Q to Interrupt", true)
menu.misc:boolean("enable", "W - Enable Shielding", true)
menu.misc:menu("whitelist", "Whitelist Spells")
for _, i in pairs(database) do
	for l, k in pairs(common.GetEnemyHeroes()) do
		-- k = myHero
		if not database[_] then
			return
		end
		if i.charName == k.charName then
			if i.displayname == "" then
				i.displayname = _
			end
			if i.danger == 0 then
				i.danger = 1
			end
			if (menu.misc.whitelist[i.charName] == nil) then
				menu.misc.whitelist:menu(i.charName, i.charName)
			end
			menu.misc.whitelist[i.charName]:menu(_, "" .. i.charName .. " | " .. (str[i.slot] or "?") .. " " .. _)
			menu.misc.whitelist[i.charName][_]:boolean("Dodge", "Spell Blocking Shielding", true)
			menu.misc.whitelist[i.charName][_]:slider("hp", "^~Min. Health for Block", 100, 1, 100, 5)
		end
	end
end
menu.misc:boolean("targeteteteteteed", "W - Shield Targeted", true)

TS.load_to_menu(menu)

local TargetSelection = function(res, obj, dist)
	if dist <= spellQ.range then
		res.obj = obj
		return true
	end
end
local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end

local TargetSelectionE = function(res, obj, dist)
	if dist <= spellE.range then
		res.obj = obj
		return true
	end
end
local GetTargetE = function()
	return TS.get_result(TargetSelectionE).obj
end
local TargetSelectionR = function(res, obj, dist)
	if dist <= spellR.range then
		res.obj = obj
		return true
	end
end
local GetTargetR = function()
	return TS.get_result(TargetSelectionR).obj
end

local function count_enemies_in_range(pos, range)
	local enemies_in_range = {}
	local enemies = common.GetEnemyHeroes()
    for i, enemy in ipairs(enemies) do	
        if enemy and common.IsValidTarget(enemy) then 
			if enemy and pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
				enemies_in_range[#enemies_in_range + 1] = enemy
			end
		end
	end
	return enemies_in_range
end

local RLevelDamage = {150, 275, 400}
function RDamage(target)
	local damage = 0
	local extra = 0
	if player:spellSlot(3).level > 0 then
		damage =
			common.CalculatePhysicalDamage(
			target,
			(RLevelDamage[player:spellSlot(3).level] + (common.GetBonusAD() * 1.2)),
			player
		)
	end
	return damage
end

local QLevelDamage = {65, 110, 155, 200, 245}
function QDamage(target)
	local damage = 0
	if player:spellSlot(0).level > 0 then
		damage =
			common.CalculatePhysicalDamage(
			target,
			(QLevelDamage[player:spellSlot(0).level] + (common.GetBonusAD() * .75)),
			player
		)
	end
	return damage
end
local ELevelDamage = {80, 125, 170, 215, 260}
function EDamage(target)
	local damage = 0
	if player:spellSlot(2).level > 0 then
		damage =
			common.CalculatePhysicalDamage(target, (ELevelDamage[player:spellSlot(2).level] + (common.GetTotalAP() * 1)), player)
	end
	return damage
end

local function AutoInterrupt(spell)
	if menu.misc.targeteteteteteed:get() then
		if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.target == player then
			if not spell.name:find("crit") then
				if not spell.name:find("BasicAttack") then
					if menu.misc.targeteteteteteed:get() then
						player:castSpell("self", 1)
					end
				end
			end
		end
	end
	if menu.misc.interrupt.inte:get() then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			local enemyName = string.lower(spell.owner.charName)
			if interruptableSpells[enemyName] then
				for i = 1, #interruptableSpells[enemyName] do
					local spellCheck = interruptableSpells[enemyName][i]
					if
						
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

local function WGapcloser()
	if menu.misc.Gap.GapA:get() then
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
			local pred_pos = preds.core.lerp(target.path, network.latency, target.path.dashSpeed)
			if pred_pos and pred_pos:dist(player.path.serverPos2D) <= spellE.range then
				--orb.core.set_server_pause()
				player:castSpell("obj", 2, target)
			end
		end
	end
end

local function Combo()
	local target = GetTarget()
	local targetE = GetTargetE()
	local targetR = GetTargetR()
	if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 then
		if common.IsValidTarget(targetE) and targetE then
			if (targetE.pos:dist(player) <= spellE.range) then
				player:castSpell("obj", 2, targetE)			
			end
		end
	end
	if menu.combo.qcombo:get() then
		if common.IsValidTarget(target) and target then
			if (target.pos:dist(player) <= spellQ.range) then
				local seg = preds.linear.get_prediction(spellQ, target)
				if seg and seg.startPos:dist(seg.endPos) <= spellQ.range then
					player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
				end
			end
		end
	end
	if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 then
		if
			common.IsValidTarget(targetR) and targetR and #count_enemies_in_range(targetR.pos, 900) < menu.combo.dontr:get() and
				targetR.pos:dist(player.pos) >= menu.combo.hpr:get()
		 then
			if (targetR.pos:dist(player) <= spellR.range) then
				player:castSpell("obj", 3, targetR)
			end
		end
	end
end

local function JungleClear()
	if menu.jungleclear.useq:get() and player:spellSlot(0).state == 0 then
		for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
			local minion = objManager.minions[TEAM_NEUTRAL][i]
			if
				minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
					minion.pos:dist(player.pos) < spellQ.range
			 then
				local seg = preds.linear.get_prediction(spellQ, minion)
				if seg and seg.startPos:dist(seg.endPos) < spellQ.range then
					player:castSpell("pos", 0, vec3(seg.endPos.x, minion.y, seg.endPos.y))
				end
			end
		end
	end
	if menu.jungleclear.usee:get() and player:spellSlot(2).state == 0 then
		for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
			local minion = objManager.minions[TEAM_NEUTRAL][i]
			if
				minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead and
					minion.pos:dist(player.pos) < spellE.range
			 then
				player:castSpell("obj", 2, minion)
			end
		end
	end
end

local function Harass()
	local target = GetTarget()
	if menu.harass.qcombo:get() then
		if common.IsValidTarget(target) and target then
			if (target.pos:dist(player) <= spellQ.range) then
				local seg = preds.linear.get_prediction(spellQ, target)
				if seg and seg.startPos:dist(seg.endPos) <= spellQ.range then
					player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
				end
			end
		end
	end

	if menu.harass.ecombo:get() and player:spellSlot(2).state == 0 then
		if common.IsValidTarget(target) and target then
			if (target.pos:dist(player) <= spellE.range) then
				
					player:castSpell("obj", 2, target)
				
			end
		end
	end
end

local function OnDraw()
	if player.isOnScreen then
		if menu.draws.drawq:get() then
			graphics.draw_circle(player.pos, spellQ.range, 1, menu.draws.colorq:get(), 100)
		end
		if menu.draws.drawr:get() then
			minimap.draw_circle(player.pos, spellR.range, 1, menu.draws.colorr:get(), 100)
		end
		if menu.draws.drawe:get() then
			graphics.draw_circle(player.pos, spellE.range, 1, menu.draws.colore:get(), 100)
		end
	end
end

local function OnTick()
	if menu.misc.enable:get() then
		if evade then
			for i = 1, #evade.core.active_spells do
				local spell = evade.core.active_spells[i]

				if spell.data.spell_type == "Target" and spell.target == player and spell.owner.type == TYPE_HERO then
					if not spell.name:find("crit") then
						if not spell.name:find("basicattack") then
							if menu.misc.targeteteteteteed:get() then
								player:castSpell("self", 1)
							end
						end
					end
				elseif
					spell.polygon and spell.polygon:Contains(player.path.serverPos) ~= 0 and
						(not spell.data.collision or #spell.data.collision == 0)
				 then
					for _, k in pairs(database) do
						if
					
							spell.name:find(_:lower()) and menu.misc.whitelist[k.charName] and menu.misc.whitelist[k.charName][_].Dodge:get() and
								menu.misc.whitelist[k.charName][_].hp:get() >= (player.health / player.maxHealth) * 100
						 
						 then
							if spell.missile then
								if (player.pos:dist(spell.missile.pos) / spell.data.speed < network.latency + 0.35) then
									player:castSpell("self", 1)
								end
							end
							if spell.name:find(_:lower()) then
								if k.speeds == math.huge or spell.data.spell_type == "Circular" then
									player:castSpell("self", 1)
								end
							end
							if spell.data.speed == math.huge or spell.data.spell_type == "Circular" then
								player:castSpell("self", 1)
							end
						end
					end
				end
			end
		end
	end
	if menu.misc.Gap.GapA:get() then
		WGapcloser()
	end

	if (orb.menu.lane_clear.key:get()) then
		JungleClear()
	end
	if (orb.menu.hybrid.key:get()) then
		Harass()
	end
	if (orb.combat.is_active()) then
		Combo()
	end
end


cb.add(cb.draw, OnDraw)
cb.add(cb.spell, AutoInterrupt)
cb.add(cb.tick, OnTick)