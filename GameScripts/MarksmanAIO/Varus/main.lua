local script = {}

local common = module.load(header.id, "common");
local damage = module.load(header.id, 'damageLib');
local ts = module.internal('TS')
local orb = module.internal("orb")
local gpred = module.internal("pred")

script.q = {delay = 0, width = 70, speed = 1850, boundingRadiusMod = 0, minRange = 925, maxRange = 1600, active = false, start = 0, chargetime = os.clock(), target = nil, releasedelay = 0.15} 
script.e = {delay = 1.25, radius = 235, speed = math.huge, boundingRadiusMod = 0, range = 925}
script.r = {delay = 0.25, width = 120, speed = 1850, boundingRadiusMod = 1, collision = {hero = true, minion = false }, range = 1075}
script.aa = {range = 575, speed = 2000, delay = 1}
script.nextcast = os.clock()
script.preQ = {time = os.clock(),target = nil}
script.preE = {time = os.clock(),target = nil}
script.guinsoos = false

script.menu = menu(header.id, "Marksman - ".. player.charName)
	ts.load_to_menu(script.menu)
	script.menu:header("", "Combo Settings")
	script.menu:boolean("qcombo", "Use Q In Combo", true)
	script.menu:boolean("ecombo", "Use E In Combo", true)
	script.menu:header("", "Harass Settings")
	script.menu:boolean("harass", "Use E In Harass", true)
	script.menu:header("", "Misc Settings")
	script.menu:keybind("ult", "Semi-R", "Z", nil)
	script.menu:menu("antigap", "Anti-gapcloser R")
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		script.menu.antigap:boolean(enemy.charName, enemy.charName, false)
	end
	script.menu:dropdown("sp_priority", "Priority", 1, {"E","Q"})
	script.menu:boolean("experimental", "Experimental Fast Combo", true)
	script.menu:header("", "Drawings Settings")
	script.menu:boolean("drawings", "Drawings", true)

local function get_stacks(unit)
	local stacks = 0;
	if unit.buff["varuswdebuff"] then
		stacks = unit.buff["varuswdebuff"].stacks
	end
	return stacks;
end


-- Return W stacks
local function getQRange()
	local t = os.clock() - script.q.start + network.latency
	return math.min(script.q.maxRange, script.q.minRange + t/2.0*script.q.minRange)
end

local function qTraceFilter(seg, obj)
	if gpred.trace.linear.hardlock(script.q, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(script.q, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if getQRange() < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	if getQRange()<1300 then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

local function rTraceFilter(seg, obj, slow)
	if gpred.trace.linear.hardlock(script.r, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(script.r, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if script.r.range < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	if not slow then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

function script.CastQ(target)
	if player:spellSlot(0).state == 0 then
		if target then
			local seg = gpred.linear.get_prediction(script.q, target)
			if seg and qTraceFilter(seg, target) then
				player:castSpell("release", 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end 
		end
	end
end
	
function script.CastE(target)
	if player:spellSlot(2).state == 0  then
		local seg = gpred.circular.get_prediction(script.e, target)
		if seg and seg.startPos:dist(seg.endPos) <= script.e.range then
			player:castSpell("pos", 2, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
		end
	end
end	
	
function script.CastR(target, slow)
	if player:spellSlot(3).state == 0  then
		local seg = gpred.linear.get_prediction(script.r, target)
		if seg and rTraceFilter(seg, target, slow) then
			if not gpred.collision.get_prediction(script.r, seg, target) then
				player:castSpell("pos", 3, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
			end
		end
	end
end

local function BufferQ(enemy)
	if os.clock() >= script.q.chargetime and script.q.target == nil then
		player:castSpell("pos", 0, game.mousePos)
		script.q.chargetime = os.clock()+script.q.releasedelay
		script.q.target = enemy
	end
end

local function DetonateBlight()
	for i=0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if get_stacks(enemy) and get_stacks(enemy) == 3 and player.pos:dist(enemy.pos) <= 1000 and os.clock() >= script.nextcast then
			if player:spellSlot(0).state == 0 and player:spellSlot(2).state ~= 0 then
				BufferQ(enemy)
			end
			if player:spellSlot(0).state ~= 0 and player:spellSlot(2).state == 0 then
				script.CastE(enemy)
				script.nextcast = os.clock() + 1.175
			end
			if player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then
				if script.menu.sp_priority:get() == 1 then 
					script.CastE(enemy)
					script.nextcast = os.clock() + 1.175
				else
					BufferQ(enemy)
				end
			end
		elseif player.pos:dist(enemy.pos) <= 1000 and os.clock() >= script.nextcast then
			if player:spellSlot(0).state == 0 and (player.levelRef == 1 or player:spellSlot(1).state ~= 0) then
				BufferQ(enemy)
			end
			if player:spellSlot(0).state == 0 then
				if damage.GetSpellDamage(0, enemy) > common.GetShieldedHealth("AD", enemy) then
					BufferQ(enemy)
				end 
			end
		end 
	end
end

local function AntiGap()
	if player:spellSlot(3).state == 0  then
		for i=0, objManager.enemies_n - 1 do
			local enemy = objManager.enemies[i]
			if common.IsValidTarget(enemy) and enemy.path.isActive and enemy.path.isDashing then
				local name = enemy.charName
				if script.menu.antigap[name]:get() then
					local pred_pos = gpred.core.project(player.path.serverPos2D, enemy.path, network.latency + script.r.delay, script.r.speed, enemy.path.dashSpeed)
					if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 850 then
						player:castSpell("pos", 3, vec3(pred_pos.x, enemy.y, pred_pos.z))
					end
				end
			end
		end
	end
end

local function UltMultiple()
	local ultcount = 3
	if player:spellSlot(3).state == 0  then
		for i=0, objManager.enemies_n - 1 do
			local enemy = objManager.enemies[i]
			local hit = 0
			for j=0, objManager.enemies_n - 1 do
				local near = objManager.enemies[j]
				if near then 
					if enemy and common.IsValidTarget(enemy) and enemy.pos:dist(near.pos) <= 500 then
						hit = hit + 1
					end
				end
			end
			if hit >= ultcount then
				script.CastR(enemy, true)
			end
		end
	end
end

local TargetSelection = function(res, obj, dist)
    if dist < 2000 then
      res.obj = obj
      return true
    end
end

local function preCastQ(target, aatraveltime, animationTime)
	local qtraveltime = player.pos:dist(target.pos)/script.q.speed
	local offset = aatraveltime+animationTime-qtraveltime-script.q.releasedelay+0.2
	script.preQ.time = os.clock()+offset
	script.preQ.target=target
end

local function preCastE(target, aatraveltime,animationTime)
	local offset = aatraveltime+animationTime-script.e.delay + 0.7  
	script.preE.time = os.clock()+offset
	script.preE.target=target
end

local function checkAA(missile)
	if missile then 
		if script.menu.experimental:get() and missile.spell.owner.ptr == player.ptr and missile.spell.isBasicAttack then
			local enemy = orb.core.cur_attack_target
			if enemy and (orb.combat.is_active()) and common.IsValidTarget(enemy) and player.pos:dist(enemy.pos) <= script.aa.range-100 and os.clock() >= script.nextcast then
				if (get_stacks(enemy) and not script.guinsoos and get_stacks(enemy) == 1) or (script.guinsoos and not get_stacks(enemy)) then
					local aatraveltime = player.pos:dist(enemy.pos)/script.aa.speed
					if player:spellSlot(0).state == 0 and player:spellSlot(2).state ~= 0 then
						preCastQ(enemy, aatraveltime, missile.spell.animationTime)
					end
					if player:spellSlot(0).state ~= 0 and player:spellSlot(2).state == 0 then
						preCastE(enemy, aatraveltime, missile.spell.animationTime)
					end
					if player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then
						if script.menu.sp_priority:get() == 1 then 
							preCastE(enemy, aatraveltime, missile.spell.animationTime)
						else
							preCastQ(enemy, aatraveltime, missile.spell.animationTime)
						end
					end 
					if orb.core.can_attack() and player.pos:dist(enemy.pos) <= script.aa.range then
						player:attack(enemy)
					end
				end
			end
		end
	end
end

local function KillSteal()
	for i=0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and common.IsEnemyMortal(enemy) then 
			if player.pos:dist(enemy.pos) <= 1000 and os.clock() >= script.nextcast then
				if player:spellSlot(0).state == 0 then
					if damage.GetSpellDamage(0, enemy) > common.GetShieldedHealth("AD", enemy) then
						BufferQ(enemy)
					end 
				end
			end
			if player:spellSlot(2).state == 0 and damage.GetSpellDamage(2, enemy) > common.GetShieldedHealth("AD", enemy) then 
				script.CastE(enemy)
			end 
		end
	end 
end 
		
local function OnTick()
	local target = ts.get_result(TargetSelection).obj
	AntiGap()
	if (orb.combat.is_active()) then
		if os.clock() >= script.q.chargetime and script.q.target ~= nil then
			if not common.IsValidTarget(script.q.target) then
				script.q.target = target
			end
			script.CastQ(script.q.target)
			script.q.target = nil
			script.nextcast = os.clock() + 0.5
		end
		if os.clock() >= script.preQ.time and os.clock() - script.preQ.time <= 1 and script.preQ.target ~= nil and player:spellSlot(0).state == 0 then
			if common.IsValidTarget(script.preQ.target) then
				BufferQ(script.preQ.target)
				script.preQ.target = nil
			else
				script.q.target = nil
			end
		end
		if os.clock() >= script.preE.time and os.clock() - script.preE.time <= 1 and script.preE.target ~= nil and player:spellSlot(2).state == 0 then
			if common.IsValidTarget(script.preE.target) then
				script.CastE(script.preE.target)
			end
				script.nextcast = os.clock() + script.e.delay
			script.preE.target = nil
		end
		if script.q.active and target and script.q.target == nil then
		script.CastQ(target)	
		end
		UltMultiple()
		DetonateBlight()
	end
	if target then
		if script.menu.ult:get() then
			script.CastR(target, false)
		end
		if (orb.menu.hybrid.key:get()) then
			script.CastE(target)
		end
	end
	KillSteal();
	checkAA()
	--Buff

	if player.buff['varusq'] then 
		script.q.active = true
		script.q.start = os.clock()
		orb.core.set_pause_attack(math.huge)
	else 
		script.q.active = false
		orb.core.set_pause_attack(0)
	end 

	if player.buff['rageblade'] then 
		if player.buff['rageblade'].stacks == 6 then 
			script.guinsoos = true
		end
	else 
		script.guinsoos = false 
	end 
end


local function OnDraw()
	if script.menu.drawings:get() then
		graphics.draw_circle(player.pos, script.e.range, 1, graphics.argb(255, 255, 255, 255), 50)
		graphics.draw_circle(player.pos, script.q.maxRange, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.create_missile , checkAA)
