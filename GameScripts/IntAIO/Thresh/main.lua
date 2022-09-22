local pred = module.internal('pred')
local TS = module.internal('TS')
local common = module.load("int", "Library/common");
local Interrupter = module.load("int", "Library/interrupter");
local enemies = common.GetEnemyHeroes()
local allies = common.GetAllyHeroes()
local VP = module.load("int", "Prediction/VP")

local t = {}

t.pos = mousePos

local spellQ = {
    range = 1100,
    delay = 0.5,
    width = 60,
    speed = 1200,
    boundingRadiusMod = 1,
    collision = {
        hero = false,
        minion = true,
        wall = true
    }
}

local spellW = {
    range = 950,
    delay = 0,
    radius = 150,
    speed = 1000,
    boundingRadiusMod = 0
}

local spellE = {
    range = 450,
    delay = 0.33,
    width = 100,
    speed = 1200,
    boundingRadiusMod = 0
}

local spellR = {
    range = 500
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
	},
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
	["pantheon"] = {
		{menuslot = "R", slot = 3, spellname = "pantheonrjump", channelduration = 2}
	},
	["shen"] = {
		{menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3}
	},
    ["tristana"] = {
		{menuslot = "W", slot = 1, spellname = "tristanaw", channelduration = 1.5}
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

local function trace_filter(Input, seg, obj)
    local totalDelay = (Input.delay + network.latency)

    if seg.startPos:dist(seg.endPos)
            + (totalDelay * obj.moveSpeed)
            + obj.boundingRadius > Input.range then
        return false
    end

    local collision = pred.collision.get_prediction(Input, seg, obj)
    if collision then
        return false
    end

    if pred.trace.linear.hardlock(Input, seg, obj) then
        return true
    end

    if pred.trace.linear.hardlockmove(Input, seg, obj) then
        return true
    end

    local t = obj.moveSpeed / Input.speed

    if pred.trace.newpath(obj, totalDelay, totalDelay + t) then
        return true
    end

    return true
end

local Compute = function(input, seg, obj)
    if input.speed == math.huge then
        input.speed = obj.moveSpeed * 3
    end

    local toUnit = (obj.path.serverPos2D - seg.startPos)

    local cos = obj.direction2D:dot(toUnit:norm())
    local sin = math.abs(obj.direction2D:cross(toUnit:norm()))
    local atan = math.atan(sin, cos)

    local unitVelocity = obj.direction2D * obj.moveSpeed * (1 - cos)
    local spellVelocity = toUnit:norm() * input.speed * (2 - sin)
    local relativeVelocity = (spellVelocity - unitVelocity) * (2 - atan)
    local totalVelocity = (unitVelocity + spellVelocity + relativeVelocity)

    local pos = obj.path.serverPos2D + unitVelocity * (input.delay + network.latency)

    local totalWidth = input.width + obj.boundingRadius

    pos = pos - totalVelocity * (totalWidth / totalVelocity:len())

    local deltaWidth = math.abs(input.width, obj.boundingRadius)
    deltaWidth = deltaWidth * cos + deltaWidth * sin

    local relativeWidth = input.width

    if input.width < obj.boundingRadius then
        relativeWidth = relativeWidth + deltaWidth
    else
        relativeWidth = relativeWidth - deltaWidth
    end

    pos = pos - spellVelocity * (relativeWidth / relativeVelocity:len())
    pos = pos - relativeVelocity * (deltaWidth / spellVelocity:len())

    local toPosition = (pos - seg.startPos)

    local a = unitVelocity:dot(unitVelocity) - spellVelocity:dot(spellVelocity)
    local b = unitVelocity:dot(toPosition) * 2
    local c = toPosition:dot(toPosition)

    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return
    end

    local d = math.sqrt(discriminant)

    local t1 = (2 * c) / (d - b)
    local t2 = (-b - d) / (2 * a)

    return math.min(t1, t2)
end

local real_target_filter = function(input)
    
    local target_filter = function(res, obj, dist)
        if dist > input.range then
            return false
        end

        local seg = pred.linear.get_prediction(input, obj)

        if not seg then
            return false
        end

        res.seg = seg
        res.obj = obj

        if not trace_filter(input, seg, obj) then
            return false
        end

        local t1 = Compute(input, seg, obj)

        if t1 < 0 then
            return false
        end

        res.pos = (pred.core.get_pos_after_time(obj, t1) + seg.endPos) / 2

        local linearTime = (seg.endPos - seg.startPos):len() / input.speed

        local deltaT = (linearTime - t1)
        local totalDelay = (input.delay + network.latency)

        if deltaT < totalDelay then
            return true
        end
        return true
    end
    return
    {
        Result = target_filter,
    }
end

local menu = menu("IntnnerThresh", "Int Thresh")
menu:header("xs", "Core");

menu:menu("combo", "Combo")
    menu.combo:keybind("combokey", "Combat Key", "Space", nil)
    menu.combo:boolean("qcombo", "Use Q", true)
    menu.combo:menu("qsettings", "Q Settings")
    menu.combo.qsettings:boolean("q2", "Use Q2 - Smart", true)
    menu.combo.qsettings:boolean("blacklisttoggle", "Use Blacklist", true)
    menu.combo.qsettings:menu('blackkkk', "Blacklist");
    for i, enemy in pairs(enemies) do
        menu.combo.qsettings.blackkkk:boolean(enemy.charName, "No use Grab: "..enemy.charName, false)
    end
    menu.combo:menu("wsettings", "W Settings")
    menu.combo.wsettings:boolean("autow", "Auto W", true)
    for i, ally in pairs(allies) do
        menu.combo.wsettings:boolean(ally.charName, "No use Shield ".. ally.charName, false)
        menu.combo.wsettings:slider("shieldbelowhp", "Shield < HP", 75, 0, 100, 1)
    end
    menu.combo.wsettings:slider("blacklisthp", "Shield Blacklist < HP", 10, 0, 100, 1)
    menu.combo.wsettings:boolean("engage", "Use To Engage", true)
    menu.combo.wsettings:boolean("saveally", "Save Ally From Enemies", true)

	menu.combo:boolean("ecombo", "Use E", true)
    menu.combo:boolean("rcombo", "Use R", true)
    menu.combo:menu("rsettings", "R Settings")
    menu.combo.rsettings:slider("rmin", "Min. Enemies", 2, 0, 5, 1)
    menu.combo.rsettings:boolean("autor", "Automatically Ult", true)
    menu.combo.rsettings:slider("autornum", "Min. Enemies Auto Ult", 2, 0, 5, 1)

menu:menu("harass", "Harass")
    menu.harass:keybind("harasskey", "Harass", "C", nil)
	menu.harass:boolean("qharass", "Use Q", true)
	menu.harass:boolean("eharass", "Use E", true)
    menu.harass:boolean("rharass", "Use R", true)

    menu:menu("interrupt", "Interrupt")
menu.interrupt:boolean("useq", "Use Q Interrupt", true)
menu.interrupt:boolean("usee", "Use E Interrupt", true)
menu.interrupt:header("fill", "Interruptible Spells")
    for i = 1, #common.GetEnemyHeroes() do
        local enemy = common.GetEnemyHeroes()[i]
        local name = string.lower(enemy.charName)
        if enemy and interruptableSpells[name] then
            for v = 1, #interruptableSpells[name] do
                local spell = interruptableSpells[name][v]
                menu.interrupt:boolean(string.format(tostring(enemy.charName) .. tostring(spell.menuslot)), "Interrupt " .. tostring(enemy.charName) .. " " .. tostring(spell.menuslot), true)
            end
        end
    end

menu:menu("draws", "Display")
	menu.draws:boolean("drawq", "Draw Q", true)
	menu.draws:boolean("draww", "Draw W", false)
	menu.draws:boolean("drawe", "Draw E", false)
    menu.draws:boolean("drawr", "Draw R", false)

menu:keybind("desperationKey", "Flee -> Auto W", "Z", nil)

TS.load_to_menu(menu)

-- Miscellaneous fucntions --
local function IsReady(spell)
    return player:spellSlot(spell).state == 0
end

local function GetDistance(one, two)
    if (not one or not two) then
        return math.huge
    end

    return one.pos:dist(two)
end

local function IsValidTarget(object)
    return object and not object.isDead and object.isTargetable and object.isVisible
end

local function TargetSelection(res, obj, dist)
    if dist < 1100 then
      res.obj = obj
      return true
    end
end

local function GetTarget()
    return TS.get_result(TargetSelection).obj
end

local function AngleDifference(from, p1, p2)
	local p1Z = p1.z - from.z
	local p1X = p1.x - from.x
	local p1Angle = math.atan2(p1Z , p1X) * 180 / math.pi

	local p2Z = p2.z - from.z
	local p2X = p2.x - from.x
	local p2Angle = math.atan2(p2Z , p2X) * 180 / math.pi

	return math.sqrt((p1Angle - p2Angle) ^ 2)
end

local function CountObjectsInCircle(pos, radius, array)
	if not pos then return -1 end
	if not array then return -1 end

	local n = 0
	for _, object in pairs(array) do
		if GetDistance(pos, object) <= radius and not object.isDead then
            n = n + 1
        end
	end

    return n
end

local function GetLowestAlly(range)
	local lowestAlly = nil
	for _, ally in pairs(allies) do
		if ally.team == player.team and not ally.isDead and GetDistance(player ,ally) <= range then
			if lowestAlly == nil then
				lowestAlly = ally
			elseif not lowestAlly.isDead and (ally.health/ally.maxHealth) < (lowestAlly.health/lowestAlly.maxHealth) then
				lowestAlly = ally
			end
		end
	end
	return lowestAlly
end

local function Interrupt(spell)
	if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
		local enemyName = string.lower(spell.owner.charName)
		if interruptableSpells[enemyName] then
			for i = 1, #interruptableSpells[enemyName] do
				local spellCheck = interruptableSpells[enemyName][i]
				if menu.interrupt[spell.owner.charName .. spellCheck.menuslot]:get() and string.lower(spell.name) == spellCheck.spellname then
                    if menu.interrupt.usee:get() and IsReady(2) then
                        if GetDistance(player, spell.owner) < spellE.range and common.IsValidTarget(spell.owner) then
                            local pos = player.pos:lerp(spell.owner.pos, -200 / player.pos:dist(spell.owner.pos))
                            player:castSpell("pos", 2, vec3(pos.x, pos.y, pos.z))
                        end
                    elseif menu.interrupt.useq:get() and IsReady(0) then
                        if GetDistance(player, spell.owner) < spellQ.range and common.IsValidTarget(spell.owner) then
                            local pos = pred.linear.get_prediction(spellQ, spell.owner)
                            player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
                        end
					end
				end
			end
		end
	end
end

local function QCheck(pos)
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if not pred.collision.get_prediction(spellQ, pos, target) then
      return true
    end

end

local function CastQ2(target)
	if IsReady(0) and menu.combo.qsettings.q2:get() and player:spellSlot(0).name == "threshqleap" then
        if menu.combo.comboKey:get() or menu.harass.harassKey:get() then
            if common.UnderDangerousTower(target.pos) then return end 
            if target.buff['threshq'] then
                player:castSpell("self", 0)
            end
		end
	end
end

local function AutoW(spell)
    for _, ally in pairs(allies) do
        if ally.type == player.type and ally.charName ~= "Thresh" and not ally.isDead and not player.isRecalling then
            if menu.combo.wsettings.autow:get() and not menu.combo.wsettings[ally.charName]:get() then
                if IsReady(1) and GetDistance(player, ally) <= spellW.range then

                    -- For hard cc --
                    if (ally.buff[5] or ally.buff[8] or ally.buff[11] or ally.buff[18] or ally.buff[24] or ally.buff[29]) then
                       player:castSpell("obj", 1, ally)
                    end
                end
            elseif menu.combo.wsettings.autow:get() and menu.combo.wsettings[ally.charName]:get() and menu.combo.wsettings.blacklisthp:get() <  common.GetPercentHealth(ally) then
                if IsReady(1) and GetDistance(player, ally) <= spellW.range then

                    -- For hard cc --
                    if (ally.buff[5] or ally.buff[8] or ally.buff[11] or ally.buff[18] or ally.buff[24] or ally.buff[29]) then
                        player:castSpell("obj", 1, ally)
                    end
                end
            end

            -- Low HP --
            if common.GetPercentHealth(ally) < 25 and GetDistance(player, ally) < spellW.range then
                player:castSpell("obj", 1, ally)
            end
        end
    end
end
local lastDebugPrint = 0
local function OnProcessSpell(spell)
    if spell then
        for _, ally in pairs(allies) do
            if ally.type == player.type and not ally.isDead and not player.isRecalling then
                if menu.combo.wsettings.autow:get() and menu.combo.wsettings.shieldbelowhp:get() > common.GetPercentHealth(ally) and not menu.combo.wsettings[ally.charName]:get() then

                    if spell.name:find("BasicAttack") or spell.name:find("CritAttack") then
                        if common.GetPercentHealth(ally) > 10 then
                            return
                        end
                    end

                    local owner = spell.owner
                    if spell.owner.team == TEAM_ENEMY and spell.owner.type == player.type then
                        if spell.target and spell.target.ptr == ally.ptr then
                            if IsReady(1) and GetDistance(player, ally) <= spellW.range then
                                player:castSpell("obj", 1, ally)
                            end
                        end
                    end
                elseif menu.combo.wsettings.autow:get() and menu.combo.wsettings.shieldbelowhp:get() > common.GetPercentHealth(ally) and menu.combo.wsettings[ally.charName]:get() then
                    if common.GetPercentHealth(ally) < menu.combo.wsettings.blacklisthp:get() then
                        if spell.name:find("BasicAttack") or spell.name:find("CritAttack") then
                            if common.GetPercentHealth(ally) > 10 then
                                return
                            end
                        end

                        local owner = spell.owner
                        if spell.owner.team == TEAM_ENEMY and spell.owner.type == player.type then
                            if spell.target and spell.target.ptr == ally.ptr then
                                if IsReady(1) and GetDistance(player, ally) <= spellW.range then
                                    player:castSpell("obj", 1, ally)
                                end
                            end
                        end
                    end
                end
            end
        end
        Interrupt(spell)
    end
end

local function EngageW()
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if menu.combo.combokey:get() and IsReady(1) then
        if GetDistance(player, target) < spellE.range or player:spellSlot(0).name == "threshqleap" then
            for _, ally in pairs(allies) do
                if GetDistance(ally, target) < spellW.range + spellE.range and ally.charName ~= "Thresh" then
                    player:castSpell("obj", 1, ally)
                end
            end
        end
    end
end

local function SaveAllyW()
    if menu.combo.wsettings.saveally:get() and IsReady(1) then
        for _, ally in pairs(allies) do
            if not ally.isDead and GetDistance(player, ally) < spellW.range then
                if CountObjectsInCircle(ally, 600, allies) < CountObjectsInCircle(ally, 600, enemies) then
                    if common.GetPercentHealth(ally) < 50 then
                        player:castSpell("obj", 1, ally)
                    end
                end
            end
        end
    end
end

local function DesperationW()
	if menu.desperationKey:get() then
        if IsReady(1) then
            for _, ally in pairs(allies) do
    			if ally.type == player.type and not ally.isDead and GetDistance(player, ally) < spellW.range + 500 and CountObjectsInCircle(ally, 600, enemies) > CountObjectsInCircle(ally, 600, allies) and GetDistance(player, ally) > 800 then
                    player:castSpell("obj", 1, ally)
                else
                    local lowAlly = GetLowestAlly(spellW.range)
                    player:castSpell("obj", 1, lowAlly)
                end
            end
        end
        player:move(vec3(t.pos.x, t.pos.y, t.pos.z))
    end
end

local function CastE()
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if player:spellSlot(0).name == "threshqleap" then
        return
    end

    for _, ally in pairs(allies) do
        if ally and GetDistance(player, ally) > 300 and not ally.isDead then
            if target and GetDistance(player, target) < spellE.range and not target.isDead then
                local predPos = pred.linear.get_prediction(spellE, target)
                if AngleDifference(target, ally, player) > 90 then
                    local pos = player.pos:lerp(target.pos, -200 / player.pos:dist(target.pos))
                    player:castSpell("pos", 2, vec3(pos.x, pos.y, pos.z))
                    --print('Sed:1')
                else
                    player:castSpell("pos", 2, vec3(predPos.endPos.x, t.pos.y, predPos.endPos.y))
                    --print('Sed:2')
                end
            end
        else
            if player.health > target.health then
                local pos = player.pos:lerp(target.pos, -200 / player.pos:dist(target.pos))
                player:castSpell("pos", 2, vec3(pos.x, pos.y, pos.z))
                --print('Sed:3')
            else
                local predPos = pred.linear.get_prediction(spellE, target)
                player:castSpell("pos", 2, vec3(predPos.endPos.x, t.pos.y, predPos.endPos.y))
                --print('Sed:4')
            end
        end
    end
end

local function AutoR()
    if menu.combo.rsettings.autor:get() and IsReady(3) then
        for i, enemy in ipairs(enemies) do
			if CountObjectsInCircle(player, spellR.range, enemies) >= menu.combo.rsettings.autornum:get() then
				if GetDistance(player, enemy) < spellR.range then
					player:castSpell("self", 3)
				end
			end
        end
    end
end

local trace_filter = function(input, segment, target)
	if pred.trace.linear.hardlock(input, segment, target) then
		return true
	end
	if pred.trace.linear.hardlockmove(input, segment, target) then
		return true
	end
	if segment.startPos:dist(segment.endPos) <= 925 then
		return true
	end
	if pred.trace.newpath(target, 0.033, 0.5) then
		return true
	end
end

-- Combo --
local function Combo()
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if menu.combo.combokey:get() then

        -- E logic --
        if IsReady(2) and GetDistance(player, target) < spellE.range then
            if menu.combo.ecombo:get() then
                CastE()
            end
        end

        -- Q logic --
        if IsReady(0) and GetDistance(player, target) < spellQ.range - (100+target.boundingRadius) then
            if menu.combo.qcombo:get() then
                if IsReady(2) and GetDistance(player, target) < spellE.range then
                    return
                end

                if menu.combo.qsettings.blacklisttoggle:get() and not menu.combo.qsettings.blackkkk[target.charName]:get() then

                    --if pos and QCheck(pos) and pos.startPos:dist(pos.endPos) < spellQ.range then
                        if player:spellSlot(0).name ~= "threshqleap" then 
                            local CastPosition, HitChance, Position = VP.GetBestCastPosition(target, 0.5, 60, 1000, 1200, player, true, "line")

                            if not CastPosition then 
                                return 
                            end 
        
        
        
                            if HitChance >= 2 then 
                                player:castSpell('pos', 0, CastPosition)
                            end 
                        end
                        if player:spellSlot(0).name == "threshqleap" then 
                            common.DelayAction(CastQ2(target), 1.4 + spellQ.delay)
                        end
                    --end
                elseif not menu.combo.qsettings.blacklisttoggle:get() then
                    ---if pos and QCheck(pos) and pos.startPos:dist(pos.endPos) < spellQ.range then
                        if player:spellSlot(0).name ~= "threshqleap" then 
                            local CastPosition, HitChance, Position = VP.GetBestCastPosition(target, 0.5, 60, 1000, 1200, player, true, "line")

                            if not CastPosition then 
                                return 
                            end 
        
        
                            if HitChance >= 2 then 
                                player:castSpell('pos', 0, CastPosition)
                            end 
                        end
                        if player:spellSlot(0).name == "threshqleap" then 
                            common.DelayAction(CastQ2(target), 1.4 + spellQ.delay)
                        end
                    --end
                end

                -- Q if target below % --
                if menu.combo.qsettings.blacklisttoggle:get() and menu.combo.qsettings.blackkkk[target.charName]:get() and (100 * target.health / target.maxHealth) <= 10 then
                    local CastPosition, HitChance, Position = VP.GetBestCastPosition(target, 0.5, 60, 1000, 1200, player, true, "line")

                            if not CastPosition then 
                                return 
                            end 

                            if HitChance >= 2 then 
                                player:castSpell('pos', 0, CastPosition)
                            end 
                        
                            if player:spellSlot(0).name == "threshqleap" then 
                                common.DelayAction(CastQ2(target), 1.4 + spellQ.delay)
                            end
                end
            end
        end

        -- W logic --
        if IsReady(1) and menu.combo.wsettings.engage:get() then
            for _, ally in pairs(allies) do
                if ally.type == player.type and GetDistance(player, ally) < spellW.range then
    		        EngageW()
                end
            end
    	end

        -- R logic --
        if menu.combo.rcombo:get() and menu.combo.rsettings.rmin:get() <= CountObjectsInCircle(player, spellR.range, enemies) then
            if IsReady(3) and GetDistance(player, target) < spellR.range then
    			player:castSpell("self", 3)
    		end
        end
    end
end

-- Harass --
local function Harass()
    local target = GetTarget()

    if not IsValidTarget(target) then
        return
    end

    if menu.harass.harasskey:get() then

        -- E logic --
        if IsReady(2) and GetDistance(player, target) < spellE.range then
            if menu.harass.eharass:get() then
                CastE()
            end
        end

        -- Q logic --
        if IsReady(0) and GetDistance(player, target) < spellQ.range then
            if menu.harass.qharass:get() then

                if IsReady(2) and GetDistance(player, target) < spellE.range then
                    return
                end

                if menu.combo.qsettings.blacklisttoggle:get() and not menu.combo.qsettings.blackkkk[target.charName]:get() then
                    local target = TS.get_result(real_target_filter(spellQ).Result) 
                            if target.pos then  
                                player:castSpell('pos', 0, vec3(target.pos.x, mousePos.y, target.pos.y))
                            end
                            if player:spellSlot(0).name == "threshqleap" then 
                                common.DelayAction(CastQ2(target), 1.4 + spellQ.delay)
                            end
                    
                elseif not menu.combo.qsettings.blacklisttoggle:get() then
                    local target = TS.get_result(real_target_filter(spellQ).Result) 
                            if target.pos then  
                                player:castSpell('pos', 0, vec3(target.pos.x, mousePos.y, target.pos.y))
                            end
                            if player:spellSlot(0).name == "threshqleap" then 
                                common.DelayAction(CastQ2(target), 1.4 + spellQ.delay)
                            end
                    
                end

                -- Q if target below % --
                if menu.combo.qsettings.blacklisttoggle:get() and menu.combo.qsettings.blackkkk[target.charName]:get() and (100 * target.health / target.maxHealth) <= menu.combo.qsettings.blacklisthp:get() then
                    local target = TS.get_result(real_target_filter(spellQ).Result) 
                    if target.pos then  
                        player:castSpell('pos', 0, vec3(target.pos.x, mousePos.y, target.pos.y))
                    end
                    if player:spellSlot(0).name == "threshqleap" then 
                        common.DelayAction(CastQ2(target), 1.4 + spellQ.delay)
                    end
                    
                end
            end
        end

        -- W logic --
        if IsReady(1) and menu.combo.wsettings.engage:get() then
            for _, ally in pairs(allies) do
                if ally.type == player.type and GetDistance(player, ally) < spellW.range then
    		        EngageW()
                end
            end
    	end

        -- R logic --
        if menu.harass.rharass:get() and menu.combo.rsettings.rmin:get() <= CountObjectsInCircle(player, spellR.range, enemies) then
            if IsReady(3) and GetDistance(player, target) < spellR.range then
    			player:castSpell("self", 3)
    		end
        end
    end
end


local function OnDraw()
    if menu.draws.drawq:get() and IsReady(0) then
        graphics.draw_circle(player.pos, spellQ.range, 1,  graphics.argb(255, 255, 255, 255), 100)
	end
	if menu.draws.draww:get() and IsReady(1) then
		graphics.draw_circle(player.pos, spellW.range, 1,  graphics.argb(255, 255, 255, 255), 100)
	end
	if menu.draws.drawe:get() and IsReady(2) then
		graphics.draw_circle(player.pos, spellE.range, 1, graphics.argb(255, 255, 255, 255), 100)
	end
    if menu.draws.drawr:get() and IsReady(3) then
		graphics.draw_circle(player.pos, spellR.range, 1,  graphics.argb(255, 255, 255, 255), 100)
	end

    --if menu.draws.drawtarget:get() then
        local target = GetTarget()

        if not IsValidTarget(target) then
            return
        end

        graphics.draw_circle(target.pos, target.boundingRadius, 2,  graphics.argb(255, 255, 0, 0), 100)
    --end
end



local function OnTick()
    AutoW()
    AutoR()
    Combo()
    DesperationW()
    Harass()
    --OnProcessSpell(spell)
    SaveAllyW()
end

cb.add(cb.tick, OnTick)
cb.add(cb.spell, OnProcessSpell)
cb.add(cb.draw, OnDraw)
