local script = {}

local gpred = module.internal("pred")
local TS = module.internal("TS");
local orb = module.internal("orb");
--Common
local common = module.load("int", "Library/common");

script.qPred = { delay = 0.25, width = 160, speed = 2400, boundingRadiusMod = 0, collision = { hero = false, minion = false } }

local function ItemTarget(res, obj, dist)
    if dist <= 1500 then
        res.obj = obj
        return true
    end
end

local GetTarget = function()
	return TS.get_result(ItemTarget).obj
end

script.spellsToSilence = {
	["Anivia"] = { 3 },
	["Caitlyn"] = { 3 },
	["Darius"] = { 3 },
	["FiddleSticks"] = { 1, 3 },
	["Gragas"] = { 1 },
	["Janna"] = { 3 },
	["Karthus"] = { 3 },
	["Katarina"] = { 3 },
	["Malzahar"] = { 3 },
	["MasterYi"] = { 1 },
	["MissFortune"] = { 3 },
	["Nunu"] = { 3 },
	["Pantheon"] = { 2, 3 },
	["Sion"] = { 0 },
	["TwistedFate"] = { 3 },
	["Varus"] = { 0 },
	["Vi"] = { 0, 3 },
	["Warwick"] = { 3 },
	["Xerath"] = { 0, 3 }
}

script.menu = menu("intsoerajdeja", "Int Soraka")
	script.menu:menu("q", "Q Settings")
		script.menu.q:boolean("combo", "Use in Combo", true)
		script.menu.q:boolean("harass", "Use in Harass", true)
	script.menu:menu("w", "W Settings")
		script.menu.w:boolean("on", "Use to Heal Allies", true)
		script.menu.w:slider("allyHealth", "Cast if ally health is < to %", 75, 1, 100, 1)
		script.menu.w:slider("myHealth", "Cast if my health is > to %", 20, 1, 100, 1)
	script.menu:menu("e", "E Settings")
		script.menu.e:boolean("combo", "Use in Combo", true)
		script.menu.e:boolean("harass", "Use in Harass", true)
		script.menu.e:boolean("isCC", "Use only if target is CC", true)
		script.menu.e:boolean("silence", "Use to Interrupt Spells", true)
	script.menu:menu("r", "R Settings")
		script.menu.r:boolean("on", "Use to Save Allies", true)
		script.menu.r:slider("health", "Cast if ally health is < to %", 10, 1, 100, 1)

function script.CastQ(target)
	if player:spellSlot(0).state == 0 then
		if (script.menu.q.combo:get() and orb.combat.active) or (script.menu.q.harass:get() and orb.menu.hybrid:get()) then
			local seg = gpred.linear.get_prediction(script.qPred, target)
			if seg and seg.startPos:dist(seg.endPos) <= 800 then
				if not gpred.collision.get_prediction(script.qPred, seg, target) then
					player:castSpell("pos", 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
				end
			end
		end
	end
end

function script.CastW()
	if player:spellSlot(1).state == 0 then
		if not player.isDead and (player.health / player.maxHealth * 100) > script.menu.w.myHealth:get() then
			for i = 0, objManager.allies_n - 1 do
				local hero = objManager.allies[i]
				if hero and hero.ptr ~= player.ptr and not hero.isDead and hero.pos:dist(player.pos) < 600 and (hero.health / hero.maxHealth * 100) < script.menu.w.allyHealth:get() then
					player:castSpell("obj", 1, hero)
					break
				end
			end
		end
	end
end

function script.CastE(target)
	if player:spellSlot(2).state == 0 then
		if (script.menu.e.combo:get() and orb.combat.active) or (script.menu.e.harass:get() and orb.menu.hybrid:get()) then
			--if not script.menu.e.isCC:get() then
				player:castSpell("pos", 2, target.pos)
			--end
		end
	end
end

function script.CastR()
	if player:spellSlot(3).state == 0 then
		for i = 0, objManager.allies_n - 1 do
			local hero = objManager.allies[i]
			if hero and not hero.isDead and (hero.health / hero.maxHealth * 100) < script.menu.r.health:get() then
				if #common.GetEnemyHeroesInRange(1000, hero.pos) > 0 then
					player:castSpell("self", 3)
					break
				end
			end
		end
	end
end

function script.AutoSilence(spell)
	if player:spellSlot(2).state == 0 and script.menu.e.silence:get() then
		local champ = spell.owner
		if champ.team == TEAM_ENEMY then
			local slot = spell.slot
			if player.pos:dist(champ.pos) <= 925 then
				if spell.name == "SummonerTeleport" then
					player:castSpell("pos", 2, spell.owner.pos)
				else
					local spells = script.spellsToSilence[champ.charName]
					if spells then
						for i = 1, #spells do
							if slot == spells[i] then
								player:castSpell("pos", 2, spell.owner.pos)
								break
							end
						end
					end
				end
			end
		end
	end
end

cb.add(cb.spell, script.AutoSilence)

local function OnTick()
	script.CastW()
	script.CastR()

	local target = GetTarget();
	if target then
		script.CastQ(target)
		script.CastE(target)
	end
end

cb.add(cb.tick, OnTick)
