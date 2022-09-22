local script = {}

local common = module.load(header.id, "Library/common");
local ts = module.load(header.id, "TargetSelector/targetSelector")
local orb = module.internal("orb")
local gpred = module.internal("pred")

script.rPred = { delay = 0.25, width = 140, speed = 2400, boundingRadiusMod = 0, collision = { hero = false, minion = false } }

script.menu = menu("intnnerSona", "Int Sona")
	script.menu:menu("q", "> >    Hymn of Valor (Q) Settings")
		script.menu.q:boolean("combo", "Use in Combo Mode", true)
		script.menu.q:boolean("harass", "Use in Harass Mode", true)
	script.menu:menu("w", "> >    Aria of Perseverance (W) Settings")
		script.menu.w:boolean("on", "Use W to Heal Allies", true)
		script.menu.w:slider("health", "Cast W if ally health is < to %", 75, 1, 100, 1)
	script.menu:menu("e", "> >    Song of Celerity (E) Settings")
		script.menu.e:boolean("combo", "Use in Combo Mode", true)
		script.menu.e:boolean("harass", "Use in Harass Mode", true)
	script.menu:menu("r", "> >    Crescendo (R) Settings")
		script.menu.r:boolean("combo", "Use in Combo Mode", true)
	ts = ts(script.menu, 2000)
	ts:addToMenu()

function script.CastQ(target)
	if player:spellSlot(0).state == 0 then
		if (script.menu.q.combo:get() and orb.combat.active) or (script.menu.q.harass:get() and orb.menu.hybrid:get()) then
			if target.pos:dist(player.pos) <= 825 then
				player:castSpell("self", 0)
			end
		end
	end
end

function script.CastW()
	if player:spellSlot(1).state == 0 and script.menu.w.on:get() then
		for i = 0, objManager.allies_n - 1 do
			local hero = objManager.allies[i]
			if hero and not hero.isDead and (hero.health / hero.maxHealth * 100) < script.menu.w.health:get() and hero.pos:dist(player.pos) <= 1000 then
				player:castSpell("self", 1)
				break
			end
		end
	end
end

function script.CastE(target)
	if player:spellSlot(2).state == 0 then
		if (script.menu.e.combo:get() and orb.combat.active) or (script.menu.e.harass:get() and orb.menu.hybrid:get()) then
			if target.pos:dist(player.pos) <= 1500 then
				player:castSpell("self", 2)
			end
		end
	end
end

function script.CastR(target)
	if player:spellSlot(3).state == 0 then
		if script.menu.r.combo:get() and orb.combat.active then
			local seg = gpred.linear.get_prediction(script.rPred, target)
			if seg and seg.startPos:dist(seg.endPos) <= 900 then
				if not gpred.collision.get_prediction(script.rPred, seg, target) then
					player:castSpell("pos", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
				end
			end
		end
	end
end

local function OnTick()
	script.CastW()

	local target = ts.target
	if target then
		script.CastQ(target)
		script.CastE(target)
		script.CastR(target)
	end
end

cb.add(cb.tick, OnTick)
