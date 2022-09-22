local preds = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb");

local common = module.load("int", "Library/common")

local rON = false


local wPred = {
	delay = 0.25,
	width = 40,
	speed = 1800,
	boundingRadiusMod = 1,
	collision = {hero = false, minion = true, wall = true}
}

local ePred = {
	delay = 0.25,
	radius = 60,
	speed = 2500,
	boundingRadiusMod = 0,
	collision = {hero = false, minion = false, wall = true}
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

local menu = menu("IntnnerHeimer", "Int Heisendinger")
menu:header('dd', "Core")

menu:menu("combo", "Combo")
menu.combo:boolean("q", "Use Q", false)
menu.combo:keybind("manual", "^ R + Q manual in target", "G", nil)
menu.combo:boolean("w", "Use W", true)
menu.combo:boolean("e", "Use E", true)
menu.combo:boolean("r", "Use R", true)
menu.combo:slider("rq", "^ R + Q -> if Min. Enemies", 3, 1, 5, 1)

menu:menu("harass", "Harass")
menu.harass:boolean("w", "Use W", true)
menu.harass:boolean("e", "Use E", true)
menu.harass:slider("Mana", "Min. Mana Percent {0} ", 10, 0, 100, 10)

menu:menu("misc", "Misc")
menu.misc:menu("interrupt", "Interrupt")
menu.misc.interrupt:boolean("inte", "Use E", true)
menu.misc.interrupt:menu("interruptmenu", "Interrupt Targets")
for i = 1, #common.GetEnemyHeroes() do
	local enemy = common.GetEnemyHeroes()[i]
	local name = string.lower(enemy.charName)
	if enemy and interruptableSpells[name] then
		for v = 1, #interruptableSpells[name] do
			local spell = interruptableSpells[name][v]
			menu.misc.interrupt.interruptmenu:boolean(
				string.format(tostring(enemy.charName) .. tostring(spell.menuslot)),
				"Interrupt ||" .. tostring(enemy.charName) .. "||" .. tostring(spell.menuslot),
				true
			)
		end
	end
end

menu:menu("draws", "Display")
menu.draws:boolean("drawq", "Q Range", true)
menu.draws:boolean("draww", "W Range", true)
menu.draws:boolean("drawe", "E Range", true)

local TargetSelection = function(res, obj, dist)
	if dist <= 1325 then
		res.obj = obj
		return true
	end
end

local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end

local trace_filterl = function(input, segment, target)
	if preds.trace.linear.hardlock(input, segment, target) then
		return true
	end
	if preds.trace.linear.hardlockmove(input, segment, target) then
		return true
	end
	if segment.startPos:dist(segment.endPos) <= 1300 then
		return true
	end
	if preds.trace.newpath(target, 0.033, 0.5) then
		return true
	end
end

local trace_filter = function(input, segment, target)
	if preds.trace.circular.hardlock(input, segment, target) then
		return true
	end
	if preds.trace.circular.hardlockmove(input, segment, target) then
		return true
	end
	if segment.startPos:dist(segment.endPos) <= 970 then
		return true
	end
	if preds.trace.newpath(target, 0.033, 0.5) then
		return true
	end
end

local ELevelDamage = {60, 100, 140, 180, 220}
local RELevelDamage = {150, 250, 350}
function EDamage(target)
	local damage = (ELevelDamage[player:spellSlot(2).level] + (common.GetTotalAP() * .6))
	return common.CalculateMagicDamage(target, damage)
end

local WLevelDamage = {60, 90, 120, 150, 180}
local RWLevelDamage = {135, 180, 225}
function WDamage(target)
	local damage = (WLevelDamage[player:spellSlot(1).level] + (common.GetTotalAP() * .45))
	return common.CalculateMagicDamage(target, damage)
end

function RWDamage(target)
	local damage = (RWLevelDamage[player:spellSlot(3).level] + (common.GetTotalAP() * .45)) * 3
	return common.CalculateMagicDamage(target, damage)
end

function REDamage(target)
	local damage = (RELevelDamage[player:spellSlot(3).level] + (common.GetTotalAP() * .75))
	return common.CalculateMagicDamage(target, damage)
end

local function AutoInterrupt(spell)
	if menu.misc.interrupt.inte:get() and player:spellSlot(2).state == 0 then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			local enemyName = string.lower(spell.owner.charName)
			if interruptableSpells[enemyName] then
				for i = 1, #interruptableSpells[enemyName] do
					local spellCheck = interruptableSpells[enemyName][i]
					if menu.misc.interrupt.interruptmenu[spell.owner.charName .. spellCheck.menuslot]:get() and string.lower(spell.name) == spellCheck.spellname then
						if player.pos2D:dist(spell.owner.pos2D) < 970 and common.IsValidTarget(spell.owner) then
							player:castSpell("pos", 2, spell.owner.pos)
						end
					end
				end
			end
		end
	end
end

local function launchQ(Qpos)
	if Qpos then
		local vadia = Qpos + (player.pos - Qpos):norm() * 320 
		player:castSpell("pos", 0, vadia);
	end
end

local function CastR()
	if player:spellSlot(3).state == 0 and not rON then
		player:castSpell("self", 3)
	end
end

local function Combo()
	local target = GetTarget()
	if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
		local d = player.path.serverPos:dist(target.path.serverPos)
		local q = player:spellSlot(0).state == 0
		local w = player:spellSlot(1).state == 0
		local e = player:spellSlot(2).state == 0
		local r = player:spellSlot(3).state == 0
		if menu.combo.q:get() and q and d < 520 and not rON then
			launchQ(target.pos)
		end
		if menu.combo.e:get() then
			if (d <= 970) and e and not rON then
				local pos = preds.circular.get_prediction(ePred, target)
				if pos and pos.startPos:dist(pos.endPos) < 970 then
					if trace_filter(ePred, pos, target) then
						player:castSpell("pos", 2, vec3(pos.endPos.x, game.mousePos.y, pos.endPos.y))
					end
				end
			end
		end
		if menu.combo.w:get() then
			if (d < 1280) and w and not rON then
				local seg = preds.linear.get_prediction(wPred, target)
				if seg and seg.startPos:dist(seg.endPos) < 1280 then
					if not preds.collision.get_prediction(wPred, seg, target) then
						if trace_filterl(wPred, seg, target) then
							player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
						end
					end
				end
			end
		end
		if menu.combo.r:get() and player:spellSlot(3).level > 0 then
			if (e or w) and target.health < RWDamage(target) or target.health < REDamage(target) then
				CastR()
				if target.health < RWDamage(target) and rON and w then
					if (d < 1300) then
						local seg = preds.linear.get_prediction(wPred, target)
						if seg and seg.startPos:dist(seg.endPos) < 1300 then
							if not preds.collision.get_prediction(wPred, seg, target) then
								player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
							end
						end
					end
				elseif target.health < REDamage(target) and rON and e then
					if (d <= 970) then
						local pos = preds.circular.get_prediction(ePred, target)
						if pos and pos.startPos:dist(pos.endPos) < 970 then
							player:castSpell("pos", 2, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
						end
					end
				end
			elseif #common.GetEnemyHeroesInRange(400) >= menu.combo.rq:get() and q then
				CastR()
				if rON and d < 450 then
					launchQ(player.pos)
				end
			end
		end
	end
end


local function Harass()
	if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
		local target = GetTarget()
		if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
			local d = player.path.serverPos:dist(target.path.serverPos)
			local q = player:spellSlot(0).state == 0
			local w = player:spellSlot(1).state == 0
			local e = player:spellSlot(2).state == 0
			local r = player:spellSlot(3).state == 0
			if menu.harass.w:get() then
				if (d < 1300) and w then
					local seg = preds.linear.get_prediction(wPred, target)
					if seg and seg.startPos:dist(seg.endPos) < 1300 then
						if not preds.collision.get_prediction(wPred, seg, target) then
							player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
						end
					end
				end
			end
			if menu.harass.e:get() then
				if (d <= 970) and e then
					local pos = preds.circular.get_prediction(ePred, target)
					if pos and pos.startPos:dist(pos.endPos) < 970 then
						player:castSpell("pos", 2, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
					end
				end
			end
		end
	end
end


local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		local d = player.path.serverPos:dist(enemy.path.serverPos)
 		if enemy and common.IsValidTarget(enemy) and not enemy.buff["sionpassivezombie"] and d < 1300 then
  			if player:spellSlot(1).state == 0 and d < 1300 and enemy.health < WDamage(enemy) then
	  			local seg = preds.linear.get_prediction(wPred, enemy)
				if seg and seg.startPos:dist(seg.endPos) < 1300 then
					if not preds.collision.get_prediction(wPred, seg, enemy) then
						player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
					end
				end
	  		end
	  		if player:spellSlot(2).state == 0 and d < 970 and enemy.health < EDamage(enemy) then
	  			local pos = preds.circular.get_prediction(ePred, enemy)
				if pos and pos.startPos:dist(pos.endPos) < 970 then
					player:castSpell("pos", 2, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
				end
	  		end
	  		if player:spellSlot(3).level > 0 and player:spellSlot(3).state == 0 and player:spellSlot(1).state == 0 and enemy.health < RWDamage(enemy) then
	  			CastR()
	  			if rON and d < 1300 then
	  				local seg = preds.linear.get_prediction(wPred, enemy)
					if seg and seg.startPos:dist(seg.endPos) < 1300 then
						if not preds.collision.get_prediction(wPred, seg, enemy) then
							player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
						end
					end
				end
	  		end
	  		if player:spellSlot(3).level > 0 and player:spellSlot(3).state == 0 and player:spellSlot(2).state == 0 and enemy.health < REDamage(enemy) then
	  			CastR()
	  			if rON and d < 970 then
	  				local pos = preds.circular.get_prediction(ePred, enemy)
					if pos and pos.startPos:dist(pos.endPos) < 970 then
						player:castSpell("pos", 2, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
					end
				end
	  		end
  		end
 	end
end


local function OnDraw()
	if player.isOnScreen then
		if menu.draws.drawq:get() and player:spellSlot(0).state == 0 then
			graphics.draw_circle(player.pos, 520, 1, graphics.argb(255, 255, 255, 255), 50)
		end
		if menu.draws.draww:get() and player:spellSlot(1).state == 0 then
			graphics.draw_circle(player.pos, 1325, 1, graphics.argb(255, 255, 255, 255), 50)
		end
		if menu.draws.drawe:get() and player:spellSlot(2).state == 0 then
			graphics.draw_circle(player.pos, 970, 1, graphics.argb(255, 255, 255, 255), 50)
		end
	end
end

local function OnTick()
	if player:spellSlot(2).name == "HeimerdingerEUlt" then
		rON = true
	elseif player:spellSlot(2).name == "HeimerdingerE" then
		rON = false
	end
	KillSteal()
	if orb.menu.hybrid:get() then
		Harass()
	end
	if orb.combat.is_active() then
		Combo()
	end
	if menu.combo.manual:get() then
		player:move(mousePos)
		if player:spellSlot(3).state == 0 then
			CastR()
		end
		if player:spellSlot(0).name == "HeimerdingerQUlt" then
			for i = 0, objManager.enemies_n - 1 do
				local enemy = objManager.enemies[i]
				local d = player.path.serverPos:dist(enemy.path.serverPos)
				if enemy and common.IsValidTarget(enemy) and not enemy.buff["sionpassivezombie"] and d < 1000 then
					if player:spellSlot(0).state == 0 and d < 1300 then
						launchQ(enemy.pos)
					end 
				end
			end
		end
	end
end

cb.add(cb.draw, OnDraw)
cb.add(cb.spell, AutoInterrupt)
orb.combat.register_f_pre_tick(OnTick)
--cb.add(cb.tick, OnTick)
