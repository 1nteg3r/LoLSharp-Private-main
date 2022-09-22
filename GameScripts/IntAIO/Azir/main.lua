local internalPred = module.internal('pred')
local TS = module.internal('TS')
local common = module.load(header.id, "Library/common");

local enemies = common.GetEnemyHeroes()
local allies = common.GetAllyHeroes()

local objHolder = {}
local objTimeHolder = {}
local t = {}

t.pos = mousePos

local spellQ = {
    range = 740,
    speed = 1600,
    delay = 0.25,
    width = 150,
    mana = 70,
    collision = false,
    boundingRadiusMod = 1
}

local spellW = {
    range = 500,
    speed = math.huge,
    delay = 0.25,
    radius = 315,
    mana = 40,
    collision = false,
    boundingRadiusMod = 1
}

local spellE = {
    range = 1100,
    speed = 1200,
    delay = 0,
    width = 315,
    mana = 60,
    hitbox = 60,
    collision = true,
    boundingRadiusMod = 1
}

local spellR = {
    range = 250,
    speed = 1300,
    delay = 0.5,
    width = 600,
    mana = 100,
    collision = true,
    boundingRadiusMod = 1
}

local azirAA = {
    range = 525
}

local soldierAA = {
    range = 315
}

local menu = menu("IntnnerAzir", "Int Azir")

menu:menu("qsettings", "Q Settings")
    menu.qsettings:boolean("qw", "Use Q If Out Of W Range", true)

menu:menu("rsettings", "R Settings")
	menu.rsettings:header("fill", "Offensive")
	menu.rsettings:boolean("smartr", "Use Smart R For Kill",  true)
	menu.rsettings:header("fill", "Defensive")
	menu.rsettings:boolean("protectcombo", "Protect In Combo Mode Only", true)
	menu.rsettings:boolean("protectgap", "Protect From Gap Closers", true)
	menu.rsettings:boolean("protectenemy", "Protect From Enemies In Range", true)
	menu.rsettings:slider("protectnumenemy", "Protect If X Enemies In Range", 1, 1, 5, 1)

menu:menu("combo", "Combo")
	menu.combo:boolean("qcombo", "Use Q", true)
	menu.combo:slider("qmana", "Q Minimum % Mana", 0, 0, 100, 1)
	menu.combo:boolean("ecombo", "Use E", true)
	menu.combo:slider("emana", "E Minimum % Mana", 0, 0, 100, 1)

menu:menu("harass", "Harass")
	menu.harass:boolean("qharass", "Use Q", true)
	menu.harass:slider("qmana", "Q Minimum % Mana", 40, 0, 100, 1)
	menu.harass:boolean("eharass", "Use E", false)
	menu.harass:dropdown("fill", "", 1, {""})
	menu.harass:slider("emana", "E Minimum % Mana", 40, 0, 100, 1)

menu:menu("laneclear", "Lane Clear")
	menu.laneclear:boolean("qlaneclear", "Use Q", true)
	menu.laneclear:slider("qmana", "Q Minimum % Mana", 60, 0, 100, 1)
	menu.laneclear:boolean("smartclear", "Use Smart Clear", true)
	menu.laneclear:slider("wmana", "W Minimum % Mana", 40, 0, 100, 1)

menu:menu("lasthit", "Last Hit")
	menu.lasthit:boolean("qlasthit", "Use Q", true)

menu:menu("draws", "Draw Settings")
	menu.draws:header("fill", "Spell Draws")
	menu.draws:boolean("drawq", "Draw Q", true)
	menu.draws:color("colorq", "Color Q", 255, 255, 255, 255)
	menu.draws:boolean("draww", "Draw W", true)
	menu.draws:color("colorw", "Color W",  255, 255, 255, 255)
	menu.draws:boolean("drawe", "Draw E", true)
	menu.draws:color("colore", "Color E",  255, 255, 255, 255)
	menu.draws:header("fill", "Miscellaneous Draws")
	menu.draws:boolean("drawsoldier", "Draw Soldiers", true)
	menu.draws:boolean("drawsoldiertime", "Draw Soldier Death Time", true)
    menu.draws:boolean("drawtarget", "Draw Target", true)
    menu.draws:color("colortarget", "Color Target",  255, 255, 255, 255)

menu:menu("key", "Key Settings")
    menu.key:header("fill", "Spell Keys")
    menu.key:keybind("combokey", "Combo Key", "Space", nil)
	menu.key:keybind("harasskey", "Harass Key", "C", nil)
	menu.key:keybind("clearkey", "Lane Clear Key", "V", nil)
	menu.key:keybind("lasthitkey", "Last Hit Key", "X", nil)
    menu.key:header("fill", "Miscellaneous Keys")
	menu.key:keybind("fleekey", "Flee Key", "Z", nil)
	menu.key:keybind("inseckey", "Insec Key", "G", nil)

TS.load_to_menu(menu)

local function GetDistance(one, two)
    if (not one or not two) then
        return math.huge
    end

    return one.pos:dist(two)
end

-- See If Enemy Is Under Tower --
local function UnderTower(unit)
    enemyTowers = common.GetEnemyTowers()
    for i = 1, #enemyTowers do
		local tower = enemyTowers[i]
        if GetDistance(player, tower) < 775 + spellW.range then
            if GetDistance(unit, tower) <= 775 then -- Tower range
                return true
            else
                return false
            end
        end
    end
end

-- Counting Soldiers --
local function CreateObj(object)
    if object and object.name then
        if object.name == "AzirSoldier" then
            if common.IsUnderDangerousTower(object.pos) then
                objHolder[object.ptr] = object
				objTimeHolder[object.ptr] = os.clock() + 6
			else
				objHolder[object.ptr] = object
				objTimeHolder[object.ptr] = os.clock() + 11
			end
        end
    end
end

local function CountSoldiers()
   	local soldiers = 0
    for _, obj in pairs(objHolder) do
        if objTimeHolder[obj.ptr] and objTimeHolder[obj.ptr] > os.clock() and GetDistance(obj, player) < 2000 then
            soldiers = soldiers + 1
        end
    end
    return soldiers
end

local function GetSoldier(i)
    local soldiers = 0
    for _,obj in pairs(objHolder) do
        if objTimeHolder[obj.ptr] and objTimeHolder[obj.ptr] > os.clock() then
            soldiers = soldiers + 1
            if i == soldiers then
                return obj
            end
        end
    end
end

local function GetSoldiers()
    local soldiers = {}
    for _,obj in pairs(objHolder) do
        if objTimeHolder[obj.ptr] and objTimeHolder[obj.ptr] > os.clock() then
            table.insert(soldiers, obj)
        end
    end
    return soldiers
end

local TargetSelection = function(res, obj, dist)
    if dist < 2000 then
      res.obj = obj
      return true
    end
end

local res = {}

local GetTarget = function()
    return TS.get_result(TargetSelection).obj
end

-- Check If Spell Is Ready --
local function IsReady(spell)
    return player:spellSlot(spell).state == 0
end

-- Returns true if @object is valid target --
local function IsValidTarget(object)
    return object and not object.isDead and object.isTargetable and object.isVisible
end

--Damage Calcs --
local function GetDmg(spell, unit)
	local lvl = player:spellSlot(spell).level
	if spell == 0 and IsReady(0) then
		local baseDamageQ = {60, 80, 100, 120, 140}
		local trueDamageQ = (baseDamageQ[lvl] + 0.3 * (player.flatMagicDamageMod * player.percentMagicDamageMod))
		return common.CalculateMagicDamage(unit, trueDamageQ, player)
	elseif spell == 2 and IsReady(2) then
		local baseDamageE = {60, 90, 120, 150, 180}
		local trueDamageE = (baseDamageE[lvl] + 0.4 * (player.flatMagicDamageMod * player.percentMagicDamageMod))
		return common.CalculateMagicDamage(unit, trueDamageE, player)
	elseif spell == 3 and IsReady(3) then
		local baseDamageR = {150, 250, 450}
		local trueDamageR = (baseDamageR[lvl] + 0.6 * (player.flatMagicDamageMod * player.percentMagicDamageMod))
		return common.CalculateMagicDamage(unit, trueDamageR, player)
	end
end

-- Check Percent Health --
local function EnemyHPPercent(range)
	local h = 0
	local mh = 0
	for _,v in pairs(enemies) do
		if v.visible and range > GetDistance(player, v) then
			h = h + v.health
			mh = mh + v.maxHealth
		end
			h = h / #enemies
			mh = mh / #enemies
	return h / mh  *100 -- Percent
	end
end

local function AllyHPPercent(range)
	local h = 0
	local mh = 0
	for _,v in pairs(allies) do
		if v.isVisible and range > GetDistance(player, v) then
			h = h + v.health
			mh = mh + v.maxHealth
		end
			h = h / #allies
			mh = mh / #allies
	return h / mh * 100 -- Percent
	end
end

-- Count # Objects In Circle --
local function CountObjectsInCircle(pos, radius, pos2)
	if not pos then return -1 end
	if not pos2 then return -1 end

	local n = 0
	if GetDistance(pos, pos2) <= radius and not pos2.isDead then
        n = n + 1
    end

    return n
end

-- Gets Best Position To Cast Spell For Farming --
local function CountMinionsInCircle(pos, radius, objects)
    local n = 0
    for i, object in ipairs(objects) do
        if GetDistance(pos, object) <= radius * radius then
            n = n + 1
        end
    end
    return n
end

local function GetBestFarmPosition(range)
    local BestPos
    local BestHit = 0
    local enemyMinions = common.GetMinionsInRange(1000, TEAM_ENEMY)
    for i, object in ipairs(enemyMinions) do
        local hit = CountMinionsInCircle(object, range, enemyMinions)
        if hit > BestHit then
            BestHit = hit
            BestPos = object
            if BestHit == #enemyMinions then
               break
            end
         end
    end
    return BestPos, BestHit
end

local function ClosestMinionToSoldier()
	local distanceMinion = math.huge
    local enemyMinions = common.GetMinionsInRange(1000, TEAM_ENEMY)
	if CountSoldiers() > 0 then
		for _,k in pairs(GetSoldiers()) do
			for i, cminion in ipairs(enemyMinions) do
				if cminion and not cminion.isDead then
					if GetDistance(k, cminion) < distanceMinion then
						distanceMinion = GetDistance(k, cminion)
					end
				end
			end
		end
	end
	return distanceMinion
end

-- Random Calcs --
local function Normalize(pos, start, range)
	local castX = start.x + range * ((pos.x - start.x) / GetDistance(player, pos))
	local castZ = start + range * ((pos.y - start.y) / GetDistance(player, pos))

	return {x = castX, z = castZ}
end

local function VectorPointProjectionOnLineSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

local function CountEnemyOnLineSegment(StartPos, EndPos, width, objects)
    local n = 0
    for i, enemy in ipairs(enemies) do
		if not enemy and not enemy.isDead then
			local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, enemy)
			if isOnSegment and GetDistance(pointSegment, enemy) < width * width and GetDistance(StartPos, EndPos) > GetDistance(StartPos, enemy) then
				n = n + 1
			end
		end
    end
    return n
end

local function CountEnemyHitOnLine(slot, from, target, enemy)
	return CountEnemyOnLineSegment(from, Normalize(target, from, soldierAA.range), spellW.hitbox, enemy)
end

local function A2V ( a, m )
	m = m or 1
	local x = math.cos ( a ) * m
	local y = math.sin ( a ) * m
	return x, y
end

local function ECheck()
    local target = GetTarget()

	if not IsValidTarget(target) then
		return
	end

    for i, enemy in ipairs(enemies) do
        for _, ally in ipairs(allies) do
            if CountObjectsInCircle(target, 2000, ally) >= CountObjectsInCircle(target, 2000, enemy) then
                if AllyHPPercent(2000) - EnemyHPPercent(2000) > 30 then
                  return true
                end
                if EnemyHPPercent(2000) < AllyHPPercent(2000) and EnemyHPPercent(2000) < 50 then
                  return true
                end
            end
        end
    end
    return false
end

local function towerCheck()
    local target = GetTarget()

	if not IsValidTarget(target) then
		return
	end

    if common.IsUnderDangerousTower(target.pos) then
        if target.health > GetDmg(2, target) - 5 then
    		return false
    	elseif target.health < GetDmg(2, target) - 5 and common.GetPercentHealth(player) > 35 then
    		return true
        end
    else
        return true
    end
end

local function qCheck()
    local target = GetTarget()

    if internalPred.trace.newpath(target, 0.033, 0.500) then
      return true
    end
end

local function Combo()
    local target = GetTarget()

	if not IsValidTarget(target) then
		return
	end

    local posBehind = target.pos:lerp(player.pos, -200 / target.pos:dist(player.pos))

    if menu.key.combokey:get() then
		for i, enemy in ipairs(enemies) do
        	-- Casting Soldiers --
			if CountObjectsInCircle(player, 2000, enemy) <= 3 then
				if IsReady(1) and GetDistance(player, posBehind) < (spellW.range) then
                    if posBehind then
                        player:castSpell("pos", 1, vec3(posBehind.x, t.pos.y, posBehind.z))
                        if CountSoldiers() > 0 then
                            for _,k in pairs(GetSoldiers()) do
                                player:attack(target)
                            end
                        end
                    end
                elseif IsReady(1) and GetDistance(player, target) < (spellW.range + (soldierAA.range / 2)) then
                    local pos = internalPred.circular.get_prediction(spellW, target)
					if pos then
						player:castSpell("pos", 1, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        if CountSoldiers() > 0 then
                            for _,k in pairs(GetSoldiers()) do
                                player:attack(target)
                            end
                        end
					end
				elseif IsReady(0) and IsReady(1) and GetDistance(player, target) < (spellQ.range + soldierAA.range) and GetDistance(player, target) > (spellW.range) + (soldierAA.range / 2) then
					if menu.qsettings.qw:get() then
						if player.mana > menu.combo.qmana:get() and player.mana >= (spellQ.mana + spellW.mana) then
							local pos = internalPred.linear.get_prediction(spellQ, target)
							if pos and pos.startPos:dist(pos.endPos) < (spellQ.range + soldierAA.range / 2) and qCheck() then
								player:castSpell("self", 1)
									common.DelayAction(function() player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y)) end, 0.25)
                                if CountSoldiers() > 0 then
                					for _,k in pairs(GetSoldiers()) do
                                        player:attack(target)
                                    end
                                end
							end
						end
					end
				end
			elseif CountObjectsInCircle(player, 2000, enemy) >= 4 then
				if IsReady(1) and GetDistance(player, posBehind) < (spellW.range) then
                    if posBehind then
                        player:castSpell("pos", 1, vec3(posBehind.x, t.pos.y, posBehind.z))
                        if CountSoldiers() > 0 then
                            for _,k in pairs(GetSoldiers()) do
                                player:attack(target)
                            end
                        end
                    end
                elseif IsReady(1) and GetDistance(player, target) < (spellW.range + (soldierAA.range / 2)) then
                    local pos = internalPred.circular.get_prediction(spellW, target)
					if pos then
						player:castSpell("pos", 1, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        if CountSoldiers() > 0 then
                            for _,k in pairs(GetSoldiers()) do
                                player:attack(target)
                            end
                        end
					end
				elseif IsReady(0) and IsReady(1) and GetDistance(player, target) < (spellQ.range) + (soldierAA.range / 2) and GetDistance(player, target) > (spellW.range) + (soldierAA.range / 2) then
					if menu.qsettings.qw:get() then
						if player.mana > menu.combo.qmana:get() and player.mana >= (spellQ.mana + spellW.mana) then
							if CountEnemyHitOnLine(0, player, target, enemy) >= 1 then
								local pos = internalPred.linear.get_prediction(spellQ, target)
								if pos and pos.startPos:dist(pos.endPos) < (spellQ.range) + (soldierAA.range / 2) and qCheck() then
									player:castSpell("self", 1)
										common.DelayAction(function() player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y)) end, 0.25)
                                    if CountSoldiers() > 0 then
                    					for _,k in pairs(GetSoldiers()) do
                                            player:attack(target)
                                        end
                                    end
								end
							end
						end
					end
				end
			end

	-- Actual Combo --
		-- One Champion In Range --
			if CountObjectsInCircle(player, 2000, enemy) >= 1 then
				if CountSoldiers() > 0 then
					for _,k in pairs(GetSoldiers()) do
						if menu.combo.qcombo:get() then
							if IsReady(0) then
								if GetDistance(k, target) > soldierAA.range and GetDistance(player, target) < (spellQ.range + (soldierAA.range / 2)) then
									local pos = internalPred.linear.get_prediction(spellQ, target)
									if pos and pos.startPos:dist(pos.endPos) < (spellQ.range + (soldierAA.range / 2)) and qCheck() then
										player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                                        player:attack(target)
									end
								elseif GetDistance(k, target) < soldierAA.range and GetDistance(player, target) < (spellQ.range + (soldierAA.range / 2)) then
									if target.health < GetDmg(0, target) - 5 then
										local pos = internalPred.linear.get_prediction(spellQ, target)
										if pos and pos.startPos:dist(pos.endPos) < (spellQ.range + (soldierAA.range / 2)) and qCheck() then
											player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                                            player:attack(target)
										end
									end
								end
							end
						end
						if menu.combo.qcombo:get() and menu.combo.ecombo:get() then
							if IsReady(1) and IsReady(3) then
								if player.mana > menu.combo.qmana:get() and player.mana > menu.combo.emana:get() and player.mana >= (spellQ.mana + spellE.mana) then
									if GetDistance(k, target) > soldierAA.range and  GetDistance(player, target) > spellQ.range then
										if GetDistance(k, target) < spellQ.range and GetDistance(k, player) < spellE.range then
											if ECheck() == true and towerCheck() == true then
												player:castSpell("self", 2)
												local pos = internalPred.linear.get_prediction(spellQ, target)
												if pos and pos.startPos:dist(pos.endPos) < spellQ.range then
													player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                                                    player:attack(target)
												end
											end
										end
									end
								end
							end
						end
						-- E For Auto AA --
						if menu.combo.ecombo:get() then
							if IsReady(2) then
								if GetDistance(k, target) < azirAA.range and GetDistance(k, target) > soldierAA.range and GetDistance(k, target) < spellE.range then
									if ECheck() == true and towerCheck() == true then
										player:castSpell("self", 2)
                                        player:attack(target)
									end
								end
							end
							-- Enemy Directly Infront --
							if IsReady(2) then
								if GetDistance(player, enemy) < (player.boundingRadius + 100) then
                                    for i, ally in pairs(allies) do
    									if CountObjectsInCircle(player, azirAA.range, ally) <= 1 and player.health < enemy.health then
    										player:castSpell("self", 2)
    									end
                                    end
								end
							end
                            -- E For Kil --
							if IsReady(2) then
								if GetDistance(player, target) < soldierAA.range then
									if ECheck() == true and towerCheck() == true then
										if target.health < GetDmg(2, target) - 5 then
											local x, y = VectorPointProjectionOnLineSegment(player, k, target)
								        	if y and GetDistance(target, x) < (spellE.hitbox ^ 2) then
												player:castSpell("self", 2)
											end
										end
								    end
								end
							end
                            -- E To Try And Avoid Death --
                            if IsReady(2) then
                                if common.GetPercentHealth(player) < 10 then
                                    player:castSpell("self", 2)
                                end
                            end
						end
					end
				end

                -- R For Kill --
				if menu.rsettings.smartr:get() then
					if IsReady(3) and not IsReady(1) then
						if target.health < GetDmg(3, target) - 5 then
                            if CountSoldiers() == 0 then
								if GetDistance(player, target) < spellR.range then
									player:castSpell("obj", 3, target)
								end
							elseif CountSoldiers() > 0 then
								if GetDistance(player, target) > soldierAA.range then
									if GetDistance(player, target) < spellQ.range and not IsReady(0) then
										if GetDistance(player, target) < spellW.range and not IsReady(1) then
											if GetDistance(player, target) < spellR.range and IsReady(3) then
												player:castSpell("obj", 3, target)
											end
										end
									end
								end
							end
						end
					end
				end
		-- Two Champion In Range --
			--elseif CountObjectsInCircle(myHero, 2000, enemies) >= 2 then
				--if CountSoldiers() > 0 then
					--for _,k in pairs(GetSoldiers()) do

					--end
				--end
			end
		end
	end
end

local function Harass()
    local target = GetTarget()

	if not IsValidTarget(target) then
		return
	end

    local posBehind = target.pos:lerp(player.pos, -200 / target.pos:dist(player.pos))

    if menu.key.harasskey:get() then
		for i, enemy in ipairs(enemies) do

            -- Casting Soldiers --
			if CountObjectsInCircle(player, 2000, enemy) <= 3 then
                if CountSoldiers() > 0 then
                    for _, k in pairs(GetSoldiers()) do
                        if GetDistance(k, target) < soldierAA.range then
                            return
                        end
                    end
                else
    				if IsReady(1) and GetDistance(player, posBehind) < (spellW.range) then
                        if posBehind then
                            player:castSpell("pos", 1, vec3(posBehind.x, t.pos.y, posBehind.z))
                            if CountSoldiers() > 0 then
                                for _,k in pairs(GetSoldiers()) do
                                    player:attack(target)
                                end
                            end
                        end
                    elseif IsReady(1) and GetDistance(player, target) < (spellW.range + (soldierAA.range / 2)) then
                        local pos = internalPred.circular.get_prediction(spellW, target)
    					if pos then
    						player:castSpell("pos", 1, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                            if CountSoldiers() > 0 then
                                for _,k in pairs(GetSoldiers()) do
                                    player:attack(target)
                                end
                            end
    					end
                    elseif IsReady(0) and IsReady(1) and GetDistance(player, posBehind) < (spellQ.range) and GetDistance(player, target) > (spellW.range) + (soldierAA.range / 2) then
                        if CountSoldiers == 0 then
    						if menu.qsettings.qw:get() then
    							if player.mana > menu.harass.qmana:get() and player.mana >= (spellQ.mana + spellW.mana) then
    								if posBehind then
    									player:castSpell("self", 1)
									common.DelayAction(function() player:castSpell("pos", 0, vec3(posBehind.x, t.pos.y, posBehind.z)) end, 0.25)
                                        if CountSoldiers() > 0 then
                        					for _,k in pairs(GetSoldiers()) do
                                                player:attack(target)
                                            end
                                        end
    								end
    							end
    						end
    					end
    				elseif IsReady(0) and IsReady(1) and GetDistance(player, target) < (spellQ.range + soldierAA.range / 2) and GetDistance(player, target) > (spellW.range) + (soldierAA.range / 2) then
    					if CountSoldiers == 0 then
    						if menu.qsettings.qw:get() then
    							if player.mana > menu.harass.qmana:get() and player.mana >= (spellQ.mana + spellW.mana) then
    	                            local pos = internalPred.linear.get_prediction(spellQ, target)
    								if pos and pos.startPos:dist(pos.endPos) < (spellQ.range + soldierAA.range) then
    									player:castSpell("self", 1)
									common.DelayAction(function() player:castSpell("pos", 0, vec3(posBehind.x, t.pos.y, posBehind.z)) end, 0.25)
                                        if CountSoldiers() > 0 then
                        					for _,k in pairs(GetSoldiers()) do
                                                player:attack(target)
                                            end
                                        end
    								end
    							end
    						end
    					end
    				end
                end
			elseif CountObjectsInCircle(player, 2000, enemy) >= 4 then
				if IsReady(1) and GetDistance(player, posBehind) < (spellW.range) then
                    if posBehind then
                        player:castSpell("pos", 1, vec3(posBehind.x, t.pos.y, posBehind.z))
                        if CountSoldiers() > 0 then
                            for _,k in pairs(GetSoldiers()) do
                                player:attack(target)
                            end
                        end
                    end
                elseif IsReady(1) and GetDistance(player, target) < (spellW.range + (soldierAA.range / 2)) then
                    local pos = internalPred.circular.get_prediction(spellW, target)
					if pos then
						player:castSpell("pos", 1, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        if CountSoldiers() > 0 then
                            for _,k in pairs(GetSoldiers()) do
                                player:attack(target)
                            end
                        end
					end
				elseif IsReady(0) and IsReady(1) and GetDistance(player, target) < (spellQ.range) + (soldierAA.range / 2) and GetDistance(player, target) > (spellW.range) + (soldierAA.range / 2) then
					if menu.qsettings.qw:get() then
						if player.mana > menu.harass.qmana:get() and player.mana >= (spellQ.mana + spellW.mana) then
							if CountEnemyHitOnLine(0, player, target, enemy) >= 1 then
                                local pos = internalPred.linear.get_prediction(spellQ, target)
    							if pos and pos.startPos:dist(pos.endPos) < (spellQ.range) + (soldierAA.range / 2) then
    								player:castSpell("self", 1)
										common.DelayAction(function() player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y)) end, 0.25)
                                    if CountSoldiers() > 0 then
                    					for _,k in pairs(GetSoldiers()) do
                                            player:attack(target)
                                        end
                                    end
    							end
							end
						end
					end
				end
			end

	-- Actual Harass --
		-- One Champion In Range --
			if CountObjectsInCircle(player, 2000, enemy) >= 1 then
				if CountSoldiers() > 0 then
					for _,k in pairs(GetSoldiers()) do
						if menu.harass.qharass:get() then
							if IsReady(0) then
								if GetDistance(k, target) > soldierAA.range and GetDistance(player, posBehind) < (spellQ.range) then
                                    if posBehind then
                                        player:castSpell("pos", 0, vec3(posBehind.x, t.pos.y, posBehind.z))
                                        player:attack(target)
                                    end
                                elseif GetDistance(k, target) > soldierAA.range and GetDistance(player, target) < (spellQ.range + (soldierAA.range / 2)) then
                                    local pos = internalPred.linear.get_prediction(spellQ, target)
                                    if pos and pos.startPos:dist(pos.endPos) < (spellQ.range + (soldierAA.range / 2)) then
                                        player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                                        player:attack(target)
                                    end
								elseif GetDistance(k, target) < soldierAA.range and GetDistance(player, target) < (spellQ.range + (soldierAA.range / 2)) then
									if target.health < GetDmg(0, target) - 5 then
                                        local pos = internalPred.linear.get_prediction(spellQ, target)
										if pos and pos.startPos:dist(pos.endPos) < (spellQ.range + (soldierAA.range / 2)) then
											player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                                            player:attack(target)
										end
									end
								end
							end
						end
						if menu.harass.qharass:get() and menu.harass.eharass:get() then
							if IsReady(0) and IsReady(2) then
								if player.mana > menu.harass.qmana:get() and player.mana > menu.harass.emana:get() and player.mana >= (spellQ.mana + spellE.mana) then
									if GetDistance(k, target) > soldierAA.range and  GetDistance(player, target) > spellQ.range then
										if GetDistance(k, target) < spellQ.range and GetDistance(k, player) < spellE.range then
											if ECheck() == true and towerCheck() == true then
                                                player:castSpell("self", 2)
												local pos = internalPred.linear.get_prediction(spellQ, target)
												if pos and pos.startPos:dist(pos.endPos) < spellQ.range then
													player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                                                    player:attack(target)
												end
											end
										end
									end
								end
							end
						end
						-- E For Auto AA --
						if menu.harass.eharass:get() then
							if not IsReady(0) and IsReady(2) then
								if GetDistance(k, target) < azirAA.range and GetDistance(k, target) > soldierAA.range and GetDistance(k, player) < spellE.range then
									if ECheck() == true and towerCheck() == true then
										player:castSpell("self", 2)
                                        player:attack(target)
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

local function LaneClear()
    local enemyMinions = common.GetMinionsInRange(1000, TEAM_ENEMY)

	if not enemyMinions then
		return
	end

	if menu.key.clearkey:get() then
		if menu.laneclear.smartclear:get() then
			if common.GetPercentPar(player) >= menu.laneclear.wmana:get() then

				-- Casting Soldiers --
				for i, minion in pairs(enemyMinions) do
					if CountObjectsInCircle(player, spellW.range, minion) <= 5 and not minion.isDead then
						if CountSoldiers() > 0 then
							for _,k in pairs(GetSoldiers()) do
								if GetDistance(k, minion) < soldierAA.range and CountSoldiers() >= 1 then
									return
								elseif GetDistance(k, minion) > soldierAA.range and not IsReady(0) and CountSoldiers() >= 1 then
									return
								end
							end
						elseif CountSoldiers() == 0 then
							if IsReady(1) then
								local BestPos, BestHit = GetBestFarmPosition(spellW.range + soldierAA.range / 2)
								if BestPos and BestHit >= 2 then
									player:castSpell("pos", 1, vec3(BestPos.x, BestPos.y, BestPos.z))
								end
							end
						end

					elseif CountObjectsInCircle(player, spellW.range, minion) >= 6 and not minion.isDead then

						if CountSoldiers() > 0 then
							for _,k in pairs(GetSoldiers()) do
								if GetDistance(k, minion) < soldierAA.range and CountSoldiers() >= 2 then
									return
								elseif GetDistance(k, minion) > soldierAA.range and not IsReady(0) and CountSoldiers() >= 2 then
									return
								end
							end
						elseif CountSoldiers() == 0 then
							if IsReady(1) then
								local BestPos, BestHit = GetBestFarmPosition(spellW.range + soldierAA.range / 2)
								if BestPos and BestHit >= 3 then
									player:castSpell("pos", 1, vec3(BestPos.x, BestPos.y, BestPos.z))
								end
							end
						end
					end

					-- Lane Clear Logic --
					if CountSoldiers() > 0 then
						for _,k in pairs(GetSoldiers()) do
							for i, enemy in ipairs(enemies) do
								if not enemy or GetDistance(player, enemy) > 2000 and ClosestMinionToSoldier() > soldierAA.range and not minion.isDead then
									if menu.laneclear.qlaneclear:get() and IsReady(0) then
										local BestPos, BestHit = GetBestFarmPosition(spellQ.range + soldierAA.range / 2)
										if BestPos and BestHit >= 2 then
											if CountObjectsInCircle(BestPos, azirAA.range, minion) > CountObjectsInCircle(k, azirAA.range, minion) then
												player:castSpell("pos", 0, vec3(BestPos.x, BestPos.y, BestPos.z))
											end
										end
									end
								end
							end
						end
					end
		        end
			end
		else
			if common.GetPercentPar(player) >= menu.laneclear.wmana:get() then

				-- Casting Soldiers --
				for i, minion in pairs(enemyMinions) do
					if CountSoldiers() > 0 then
						for _,k in pairs(GetSoldiers()) do
							if IsReady(1) then
								local BestPos, BestHit = GetBestFarmPosition(soldierAA.range)
								if BestPos and BestHit >= 0 then
                                    player:castSpell("pos", 1, vec3(BestPos.x, BestPos.y, BestPos.z))
								end
							end
						end
					end

					-- Lane Clear Logic --
					if CountSoldiers() > 0 then
						for _,k in pairs(GetSoldiers()) do
							for i, enemy in ipairs(enemies) do
								if not enemy or GetDistance(player, enemy) > 2000 and GetDistance(k, minion) > soldierAA.range and not minion.isDead then
									if menu.laneclear.qlaneclear:get() and IsReady(0) then
										local BestPos, BestHit = GetBestFarmPosition(spellQ.range + soldierAA.range / 2)
										if BestPos and BestHit >= 1 then
											player:castSpell("pos", 0, vec3(BestPos.x, BestPos.y, BestPos.z))
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

local function LastHit()
    local enemyMinions = common.GetMinionsInRange(1000, TEAM_ENEMY)

	if not enemyMinions then
		return
	end

	if menu.key.lasthitkey:get() and menu.lasthit.qlasthit:get() then
		if CountSoldiers() > 0 then
			for _,k in pairs(GetSoldiers()) do
				for i, minion in pairs(enemyMinions) do
					if GetDistance(k, minion) > soldierAA.range and GetDistance(player, k) > azirAA.range and GetDistance(player, minion) < spellQ.range then
						if IsReady(0) and GetDmg(0, minion) > minion.health then
                            player:castSpell("pos", 0, vec3(minion.x, minion.y, minion.z))
						end
					end
				end
			end
		end
	end
end

local function UltProtect()
	for i, enemy in ipairs(enemies) do
		if menu.rsettings.protectenemy:get() and not menu.rsettings.protectcombo:get() then
			if CountObjectsInCircle(player, spellR.range, enemy) >= menu.rsettings.protectnumenemy:get() then
				if GetDistance(player, enemy) < spellR.range then
					player:castSpell("obj", 3, enemy)
				end
			end
		elseif menu.rsettings.protectenemy:get() and menu.rsettings.protectcombo:get() then
			if menu.key.combokey:get() then
				if CountObjectsInCircle(player, spellR.range, enemy) >= menu.rsettings.protectnumenemy:get() then
					if GetDistance(player, enemy) < spellR.range then
						player:castSpell("obj", 3, enemy)
					end
				end
			end
		end
	end
end

local function InsecR(pos, obj)
	if IsValidTarget(obj) and GetDistance(player, obj) < 250 then
		player:castSpell("pos", 3, vec3(t.pos.x, t.pos.y, t.pos.z))
	else
		common.DelayAction(function() InsecR() end, 0.03)
	end
end

local function Insec()
    local target = GetTarget()

	if not IsValidTarget(target) then
		return
	end

	if menu.key.inseckey:get() then
        if CountSoldiers() == 0 then
            if IsReady(0) and IsReady(1) and IsReady(2) and IsReady(3) then
                local wPos = player.pos:lerp(target.pos, spellW.range / target.pos:dist(player.pos))
                if wPos and GetDistance(player, target) < (spellQ.range + 200) then
                    player:castSpell("pos", 1, vec3(wPos.x, wPos.y, wPos.z))
                end
            end
        else
            local qPos = target.pos:lerp(player.pos, -200 / target.pos:dist(player.pos))
			if qPos then
                if GetDistance(player, qPos) < spellQ.range then
                    player:castSpell("pos", 0, vec3(qPos.x, qPos.y, qPos.z))
                    InsecR(player, target)
					player:castSpell("self", 2)
                end
    		end
        end
    player:move(vec3(t.pos.x, t.pos.y, t.pos.z))
	end
end

local function Flee()
	if menu.key.fleekey:get() then
	    if CountSoldiers() == 0 then
			if IsReady(0) and IsReady(1) and IsReady(2) and player.mana > (spellQ.mana + spellW.mana + spellE.mana) then
			    -- local movePos = player.pos + (vec3(t.pos.x, t.pos.y, t.pos.z) - player.pos) * spellQ.range
			    player:castSpell("pos", 1, vec3(t.pos.x, t.pos.y, t.pos.z))
				player:castSpell("self", 2)
				player:castSpell("pos", 0, vec3(t.pos.x, t.pos.y, t.pos.z))
			end
		elseif CountSoldiers() > 0 then
			if IsReady(0) and IsReady(2) and player.mana > (spellQ.mana + spellE.mana) then
                for _, k in pairs(GetSoldiers()) do
                    if GetDistance(t, k) < spellW.range then
                        player:castSpell("self", 2)
        				player:castSpell("pos", 0, vec3(t.pos.x, t.pos.y, t.pos.z))
                    else
                        player:castSpell("pos", 1, vec3(t.pos.x, t.pos.y, t.pos.z))
        				player:castSpell("self", 2)
        				player:castSpell("pos", 0, vec3(t.pos.x, t.pos.y, t.pos.z))
                    end
                end
			end
		end
    player:move(vec3(t.pos.x, t.pos.y, t.pos.z))
	end
end

-- Drawing Shit --
local function OnDraw()
    if menu.draws.drawq:get() and IsReady(0) then
        graphics.draw_circle(player.pos, spellQ.range, 2, menu.draws.colorq:get(), 100)
	end
	if menu.draws.draww:get() and IsReady(1) then
		graphics.draw_circle(player.pos, spellW.range, 2, menu.draws.colorw:get(), 100)
	end
	if menu.draws.drawe:get() and IsReady(2) then
		graphics.draw_circle(player.pos, spellE.range, 2, menu.draws.colore:get(), 100)
	end

    if menu.draws.drawsoldier:get() then
		local pi = math.pi
		local pointsSmall = {}
		local pointsLarge = {}
		local drawPoints = {}
		local resolution = 35
		for i=1,resolution do
			local PX, PZ = A2V(pi*i/(resolution/3.5), 300)
			pointsSmall[#pointsSmall+1] = {x = PX, z = PZ}
			local PX, PZ = A2V(pi*i/(resolution/3.5)+(resolution/70), 325)
			pointsLarge[#pointsLarge+1] = {x = PX, z = PZ}
		end

		if CountSoldiers() > 0 then
			for _,k in pairs(GetSoldiers()) do
				local X,Y,Z = k.x, k.y, k.z
				if k.team == TEAM_ALLY and GetDistance(player, k) <= 670 then
                    graphics.draw_circle_xyz(k.x, k.y, k.z, 325, 1, graphics.argb(255, 102, 255, 179), 100)
                    graphics.draw_circle_xyz(k.x, k.y, k.z, 300, 1, graphics.argb(255, 102, 255, 179), 100)
				elseif k.team == TEAM_ALLY and GetDistance(k, player) > 670 then
                    graphics.draw_circle_xyz(k.x, k.y, k.z, 325, 1, graphics.argb(255, 234, 153, 153), 100)
                    graphics.draw_circle_xyz(k.x, k.y, k.z, 300, 1, graphics.argb(255, 234, 153, 153), 100)
				end
				for i,v in ipairs(pointsSmall) do
					if i > 1 and i < #pointsSmall then
						local nextPointL = pointsLarge[i-1]
						local nextPointS = pointsSmall[i+1]
						if k.team == TEAM_ALLY and GetDistance(player, k) <= 670 then
                            graphics.draw_line(vec3(X+v.x, Y, Z+v.z), vec3(X+nextPointL.x, Y, Z+nextPointL.z), 1, graphics.argb(255, 102, 255, 179))
                            graphics.draw_line(vec3(X+nextPointL.x, Y, Z+nextPointL.z), vec3(X+nextPointS.x, Y, Z+nextPointS.z), 1, graphics.argb(255, 102, 255, 179))
						elseif k.team == TEAM_ALLY and GetDistance(player, k) >= 670 then
                            graphics.draw_line(vec3(X+v.x, Y, Z+v.z), vec3(X+nextPointL.x, Y, Z+nextPointL.z), 1, graphics.argb(255, 234, 153, 153))
                            graphics.draw_line(vec3(X+nextPointL.x, Y, Z+nextPointL.z), vec3(X+nextPointS.x, Y, Z+nextPointS.z), 1, graphics.argb(255, 234, 153, 153))
						end
					end
				end
			end
		end
	end

    if menu.draws.drawsoldiertime:get() then
		for _, obj in pairs(objHolder) do
		    if objTimeHolder[obj.ptr] and objTimeHolder[obj.ptr] < math.huge and obj.team == player.team then
			    if objTimeHolder[obj.ptr] > os.clock() then
                    local pos = graphics.world_to_screen(vec3(obj.x, obj.y, obj.z))
			    	if obj.name:find("AzirSoldier") and (objTimeHolder[obj.ptr] - os.clock()) >= 4 then
                        graphics.draw_text_2D("Death:" ..math.floor(objTimeHolder[obj.ptr] - os.clock()).."s", 20, pos.x - 20, pos.y + 40, graphics.argb(255, 102, 255, 179))
			    	elseif obj.name:find("AzirSoldier") and (objTimeHolder[obj.ptr] - os.clock()) < 4 then
                        graphics.draw_text_2D("Death:" ..math.floor(objTimeHolder[obj.ptr] - os.clock()).."s", 20, pos.x - 20, pos.y + 40, graphics.argb(255, 234, 153, 153))
					end
				else
					objHolder[obj.ptr] = nil
					objTimeHolder[obj.ptr] = nil
				end
			end
	    end
	end

    if menu.draws.drawtarget:get() then
        local target = GetTarget()

        if not IsValidTarget(target) then
            return
        end

        graphics.draw_circle(target.pos, target.boundingRadius, 2, menu.draws.colortarget:get(), 100)
    end
end

local function OnTick()
    Combo()
    Harass()
    Insec()
    LaneClear()
    LastHit()
    UltProtect()
    Flee()

end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.create_minion, CreateObj)
