local script = {}


local orb = module.internal("orb");
local evade = module.seek('evade')
local ts = module.internal('TS')
local minionmanager = objManager.minions

local function ST(res, obj, Distancia)
    if Distancia > 1000 then 
        return true
    end 
    res.obj = obj
    return true
end

local function GetTargetSelector()
	return ts.get_result(ST).obj
end


script.target = nil

script.smite = {
	slot = nil,
	dmgs = { 390, 410, 430, 450, 480, 510, 540, 570, 600, 640, 680, 720, 760, 800, 850, 900, 950, 1000 }
}

if player:spellSlot(4).name == "SummonerSmite" or player:spellSlot(4).name == "S5_SummonerSmitePlayerGanker" or player:spellSlot(4).name == "S5_SummonerSmiteDuel" then
	script.smite.slot = 4
elseif player:spellSlot(5).name == "SummonerSmite" or player:spellSlot(5).name == "S5_SummonerSmitePlayerGanker" or player:spellSlot(5).name == "S5_SummonerSmiteDuel" then
	script.smite.slot = 5
end

script.blinksList = {
	["Ekko"] = { 2 },
	["Ezreal"] = { 2 },
	["FiddleSticks"] = { 3 },
	["Kassadin"] = { 3 },
	["Katarina"] = { 2 },
	["Yasuo"] = { 3 }
}

script.menu = menu("IntnnerMaster", "Int MasterYi")
	script.menu:menu("combo", "Combo")
		script.menu.combo:boolean("magnet", "Magnet Movement - BETA", false)
		script.menu.combo:boolean("q", "Use Q", false)
		script.menu.combo:boolean("w", "Use W as AA reset", true)
		script.menu.combo:boolean("e", "Use E", true)
		script.menu.combo:boolean("r", "Use R", true)
	script.menu:menu("jungleclear", "Jungle Clear")
		script.menu.jungleclear:boolean("q", "Use Q", true)
		script.menu.jungleclear:boolean("e", "Use E", true)
		script.menu.jungleclear:boolean("smite", "Use Smite health low", true)
	script.menu:menu("laneclear", "Lane Clear")
		script.menu.laneclear:boolean("q", "Use Q", false)
		script.menu.laneclear:boolean("e", "Use E", false)
	script.menu:menu("misc", "Misc")
		script.menu.misc:boolean("follow", "Use Q to follow dashes", true)
		script.menu.misc:boolean("q", "Use Q to dodge spells", true)
		script.menu.misc:boolean("w", "Use W when you can't dodge", true)

function script.OnTick()
	if evade and evade.core.is_active() then return end

	script.AutoSmite()

	script.target = GetTargetSelector()
	
	if script.target and orb.menu.combat:get() then
		script.Combo(script.target)
	else
		orb.core.set_pause_move(0)
	end
	
	if orb.menu.lane_clear:get() then
		script.Clear()
	end
end

function script.Combo(target)
	if target and target.isVisible and not target.isDead then
		local dist = player.pos:dist(target.pos)
		local aaRange = player.attackRange + player.boundingRadius
		if script.menu.combo.r:get() and player:spellSlot(3).state == 0 and dist <= 1200 then
			player:castSpell("self", 3)
		end
		if script.smite.slot and player:spellSlot(script.smite.slot).state == 0 and (player:spellSlot(script.smite.slot).name == "S5_SummonerSmitePlayerGanker" or player:spellSlot(script.smite.slot).name == "S5_SummonerSmiteDuel") then
			player:castSpell("obj", script.smite.slot, target)
		end
		if dist > aaRange then
			if script.menu.combo.q:get() and player:spellSlot(0).state == 0 then
				player:castSpell("obj", 0, target)
			end
		else
			if script.menu.combo.e:get() and player:spellSlot(2).state == 0 then
				player:castSpell("self", 2)
			end
		end
		for i = 6, 11 do
			local item = player:spellSlot(i).name
			if item == "YoumusBlade" then
				if player:spellSlot(i).state == 0 and dist <= 1200 then
					player:castSpell("self", i)
				end
			elseif item == "ItemTiamatCleave" then
				if player:spellSlot(i).state == 0 and dist <= 400 then
					player:castSpell("self", i)
				end
			elseif item == "BilgewaterCutlass" or item == "ItemSwordOfFeastAndFamine" then
				if player:spellSlot(i).state == 0 then
					player:castSpell("obj", i, target)
				end
			end
		end
		if dist < 900 and script.menu.combo.magnet:get() and orb.combat.can_action() and (not orb.combat.can_attack() or dist > aaRange) then
			orb.core.set_pause_move(math.huge)
			local pos = target.pos
			if target.path.isActive then
				pos = target.pos:lerp(target.path.point[0], -75 / target.pos:dist(target.path.point[0]))
			end
			player:move(pos)
		else
			orb.core.set_pause_move(0)
		end
	end
end

function script.Clear()
	local target = { obj = nil, health = 0, mode = "jungleclear" }
	local aaRange = player.attackRange + player.boundingRadius + 200
	for i = 0, minionmanager.size[TEAM_NEUTRAL] - 1 do
		local obj = minionmanager[TEAM_NEUTRAL][i]
		if player.pos:dist(obj.pos) <= aaRange and obj.maxHealth > target.health then
			target.obj = obj
			target.health = obj.maxHealth
		end
	end
	if not target.obj then
		for i = 0, minionmanager.size[TEAM_ENEMY] - 1 do
			local obj = minionmanager[TEAM_ENEMY][i]
			if player.pos:dist(obj.pos) <= aaRange and obj.maxHealth > target.health then
				target.obj = obj
				target.health = obj.maxHealth
				target.mode = "laneclear"
			end
		end
	end
	if target.obj then
		if target.mode == "jungleclear" then
			if script.menu.jungleclear.e:get() and player:spellSlot(2).state == 0 then
				player:castSpell("self", 2)
			end
			if script.menu.jungleclear.q:get() and player:spellSlot(0).state == 0 and not orb.core.can_attack() then
				player:castSpell("obj", 0, target.obj)
			end
			if script.menu.jungleclear.smite:get() and script.smite.slot and player:spellSlot(script.smite.slot).state == 0 and player.health <= 0.15 * player.maxHealth then
				player:castSpell("obj", script.smite.slot, target.obj)
			end
		else
			if script.menu.laneclear.e:get() and player:spellSlot(2).state == 0 then
				player:castSpell("self", 2)
			end
			if script.menu.laneclear.q:get() and player:spellSlot(0).state == 0 and not orb.core.can_attack() then
				player:castSpell("obj", 0, target.obj)
			end
		end
	end
end

function script.AutoSmite()
	if not player.isDead and script.smite.slot and player:spellSlot(script.smite.slot).state == 0 then
		for i = 0, minionmanager.size[TEAM_NEUTRAL] - 1 do
			local obj = minionmanager[TEAM_NEUTRAL][i]
			if obj and player.pos:dist(obj.pos) < 560 and obj.health <= script.smite.dmgs[player.levelRef] then
				if obj.charName == "SRU_Baron" then
					--if script.menu.smite.baron:get() then
						player:castSpell("obj", script.smite.slot, obj)
					--end
				elseif obj.charName == "SRU_Dragon_Water" or obj.charName == "SRU_Dragon_Fire" or obj.charName == "SRU_Dragon_Earth" or obj.charName == "SRU_Dragon_Air" or obj.charName == "SRU_Dragon_Elder" then
					--if script.menu.smite.dragon:get() then
						player:castSpell("obj", script.smite.slot, obj)
					--end
				end
			end
		end
	end
end

function script.FollowBlink(spell)
	if spell.owner and spell.owner.ptr == script.target.ptr and not spell.isBasicAttack then
		local castQ = false
		local champ = spell.owner
		local name = champ.charName
		if spell.name == "SummonerFlash" then
			castQ = true
		elseif script.blinksList[name] then
			local champBlinks = script.blinksList[name]
			for i = 1, #champBlinks do
				if champBlinks[i] == spell.slot then
					castQ = true
					break
				end
			end
		else
			if name == "Leblanc" then
				if spell.slot == 1 then
					castQ = true
				elseif spell.name == "LeblancRWReturn" then
					castQ = true
				end
			elseif spell.name == "LissandraE" then
				if champ.buff["lissandrae"] and champ.buff["lissandrae"].stacks and champ.buff["lissandrae"].stacks == 1 then
					castQ = true
				end
			elseif name == "Zed" then
				if spell.name == "ZedW2" then
					castQ = true
				elseif spell.name == "ZedR2" then
					castQ = true
				end
			end
		end
		if castQ and champ and champ.isVisible and not champ.isDead then
			player:castSpell("obj", 0, champ)
		end
	end
end

function script.FollowDash(obj)
	if script.menu.misc.follow:get() and orb.menu.combat:get() and script.target and obj.ptr == script.target.ptr and obj.isVisible and not obj.isDead and obj.path and obj.path.isActive and obj.path.isDashing then
		player:castSpell("obj", 0, obj)
	end
end

function script.Dodge(spell)
	if player:spellSlot(0).state == 0 and spell and spell.owner and spell.owner.team == TEAM_ENEMY and not spell.isBasicAttack then
		if spell.target and spell.target.ptr == player.ptr then
			script.CastDodge()
		else
			if player.pos:dist(spell.endPos) <= (150 + player.boundingRadius) / 2 then
				script.CastDodge()
			end
		end
	end
end

function script.CastDodge()
	local target = nil
	local bestchamp = { hero = nil, health = math.huge, maxHealth = math.huge }
	if objManager.enemies_n > 0 then
		for i = 0, objManager.enemies_n - 1 do
			local hero = objManager.enemies[i]
			if hero.isVisible and player.pos:dist(hero.pos) <= 600 then
				if hero.maxHealth < bestchamp.maxHealth then
					bestchamp.hero = hero
					bestchamp.health = hero.health
					bestchamp.maxHealth = hero.maxHealth
				end
			end
		end
		target = bestchamp.hero
	end
	if target then
		local enemiesInRange = 0
		for i = 0, objManager.enemies_n - 1 do
			local hero = objManager.enemies[i]
			if hero.ptr ~= target.ptr and target.pos:dist(hero.pos) < 1000 then
				enemiesInRange = enemiesInRange + 1
			end
		end
		if enemiesInRange > 1 then
			if minionmanager.size[TEAM_ENEMY] > 0 then
				for i = 0, minionmanager.size[TEAM_NEUTRAL] - 1 do
					local obj = minionmanager[TEAM_NEUTRAL][i]
					if obj and player.pos:dist(obj.pos) < 600 then
						target = obj
						break
					end
				end
			end
		end
	else
		if minionmanager.size[TEAM_ENEMY] > 0 then
			for i = 0, minionmanager.size[TEAM_NEUTRAL] - 1 do
				local obj = minionmanager[TEAM_NEUTRAL][i]
				if obj and player.pos:dist(obj.pos) < 600 then
					target = obj
					break
				end
			end
		end
	end
	if target then
		if script.menu.misc.q:get() then
			player:castSpell("obj", 0, target)
		end
	else
		if script.menu.misc.w:get() then
			player:castSpell("self", 1)
		end
	end
end

function script.AfterAttack()
	if script.target and orb.menu.combat:get() and not orb.core.can_attack() and player.pos:dist(script.target.pos) <= player.attackRange + player.boundingRadius then
		local item = nil
		for i = 6, 11 do
			if player:spellSlot(i).name == "ItemTitanicHydraCleave" then
				item = i
				break
			end
		end
		if item and player:spellSlot(item).state == 0 then
			player:castSpell("self", item)
		elseif script.menu.combo.w:get() and player:spellSlot(1).state == 0 then
			player:castSpell("self", 1)
		end
		orb.combat.set_invoke_after_attack(false)
	end
end

function script.OnRecvSpell(spell)
	script.Dodge(spell)
	if script.menu.misc.follow:get() and orb.menu.combat:get() and script.target then
		script.FollowBlink(spell)
	end
end

cb.add(cb.tick, script.OnTick)
cb.add(cb.spell, script.OnRecvSpell)
cb.add(cb.path, script.FollowDash)
orb.combat.register_f_after_attack(script.AfterAttack)
