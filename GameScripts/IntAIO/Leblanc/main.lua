local Dano = module.load("int", "Core/Leblanc/Damage")
local common = module.load("int", "Library/util")
local prediction = module.internal("pred")
local orbwalker = module.internal("orb");
local TargetSelector = module.internal("TS")
local WBoot = { }
local RWBoot = { } 
local Clone = nil
local QlasTick = 0
local ePred = { delay = 0.25, width = 54, speed = 1750, boundingRadiusMod = 1, collision = {hero = true, minion = true, wall = true} }
local rSupporterText = { }

local delayedActions, delayedActionsExecuter = {}, nil
local function DelayAction(func, delay, args) 
    if not delayedActionsExecuter then
        function delayedActionsExecuter()
            for t, funcs in pairs(delayedActions) do
                if t <= game.time then
                    for i = 1, #funcs do
                        local f = funcs[i]
                        if f and f.func then
                            f.func(unpack(f.args or {}))
                        end 
                    end 
                    delayedActions[t] = nil
                end 
            end 
        end 
        cb.add(cb.tick, delayedActionsExecuter)
    end 
    local t = game.time + (delay or 0)
    if delayedActions[t] then
        delayedActions[t][#delayedActions[t] + 1] = {func = func, args = args}
    else
        delayedActions[t] = {{func = func, args = args}}
    end
end

local function Floor(number) 
    return math.floor((number) * 100) * 0.01
end
local function Definity(res, object, Distancia)
    if object and not object.isDead and object.isVisible and object.isTargetable and not object.buff[17] then
        if Distancia < 600 * 2 then 
            res.object = object
            return true
        end 
    end 
end

local wPred = {
	delay = 0.6,
	radius = 260,
	speed = 1450,
    boundingRadiusMod = 0,
    range = 695,
	collision = {hero = false, minion = false}
}

local spells = {
    ["W"] = {
        slot = 1,
        type = "circular",
        delay = 0.25,
        range = 695,
        speed = 1800,
        width = 260,
        collision = {hero = false, minion = false, wall = false}
    };
    ["RW"] = {
        slot = 3,
        type = "circular",
        delay = 0.25,
        range = 695,
        speed = 1800,
        width = 260,
        collision = {hero = false, minion = false, wall = false}
    };
    ["E"] = {
        slot = 2,
        type = "linear",
        delay = 0.5,
        range = 860,
        speed = 1750,
        width = 70,
        collision = {hero = true, minion = true, wall = true}
    };
    ["RE"] = {
        slot = 3,
        type = "linear",
        delay = 0.5,
        range = 860,
        speed = 1750,
        width = 70,
        collision = {hero = true, minion = true, wall = true}
    };

}
local function IsUnderTurretEnemy(pos)
    if not pos then 
        return false 
    end
    for i = 0, objManager.turrets.size[TEAM_ENEMY] - 1 do
        local tower = objManager.turrets[TEAM_ENEMY][i]
        if  tower and not tower.isDead and tower.health > 0 then
            local turretPos = vec3(tower.x, tower.y, tower.z)
			if turretPos:dist(pos) < 900 then
				return true
            end
        else 
            tower = nil
		end
	end
    return false

end
local function TargetSelection()
	return TargetSelector.get_result(Definity).object
end

local function GetDistanceSqr(p1, p2)
    local p2 = p2 or player
    local dx = p1.x - p2.x
    local dz = (p1.z or p1.y) - (p2.z or p2.y)
    return dx * dx + dz * dz
end

local function GetDistance(p1, p2)
    local squaredDistance = GetDistanceSqr(p1, p2)
    return math.sqrt(squaredDistance)
end

local function IsValidTarget(object)
    return (object and not object.isDead and object.isVisible and object.isTargetable and not object.buff[17])
end

local function ValidTargetRange(unit, range)
    return unit and unit.isVisible and not unit.isDead and unit.isTargetable and not unit.buff[17] and (not range or player.pos:dist(unit.pos) <= range)
end

local function GetCircularFarmLocation(pos, range)
    local n = 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local object = objManager.minions[TEAM_ENEMY][i]
        if object and IsValidTarget(object) then
            if IsValidTarget(object) then
                local objectPos = vec3(object.x, object.y, object.z)
                if GetDistanceSqr(pos, objectPos) <= math.pow(range, 2) then
                    n = n + 1
                end
            end
        end
    end
    return n
end

local function PredLinear(target, delay, speed, range, width)
    local sourcePosition = vec2(player.pos.x, player.pos.z)
    local targetPosition = vec2(target.pos.x, target.pos.z)
    
    if not target.path.isActive then
        return vec3(targetPosition.x, game.mousePos.y, targetPosition.y)
    end
    
    local ping = network.latency
    local targetDirection = vec2(target.path.serverVelocity.x, target.path.serverVelocity.z):norm()
    local toTargetDirection = (targetPosition - sourcePosition):norm()
    local meanDirection = ((targetDirection + toTargetDirection) / 2):norm()
    
    sourcePosition = sourcePosition - toTargetDirection * player.boundingRadius
    
    local simulatedPos = targetPosition + targetDirection * ((ping + delay) * target.moveSpeed)
    simulatedPos = simulatedPos - meanDirection * target.boundingRadius
    simulatedPos = simulatedPos + meanDirection * width
    
    local distance = sourcePosition:dist(simulatedPos)
    local interceptTime = distance / speed
    
    local castPosition = targetPosition + targetDirection * (interceptTime * target.moveSpeed)
    
    return vec3(castPosition.x, game.mousePos.y, castPosition.y)
end

local function InitializeSpellFunctions()
    for _, self in pairs(spells) do
        self.boundingRadiusMod = 1
        
        self.width = self.width --! Adjusting little bit for minion collision.
        self.radius = self.width --! Circular spells works with radius.
        
        if self.speed == math.huge then self.delay = 0 end
        
        --* Gets spell's maximum hit/intercept time.
        self.maxHitTime = self.range / self.speed
        
        --* Returns prediction module for spell.(linear, circular, etc...)
        self.GetPrediction = function()
            if self.type == "linear" then return prediction.linear
            elseif self.type == "circular" then return prediction.circular
            end
        end
        
        --* Returns prediction trace module for spell.(linear, circular, etc...)
        self.GetTrace = function()
            if self.type == "linear" then return prediction.trace.linear
            elseif self.type == "circular" then return prediction.trace.circular
            end
        end
        
        --* Returns is spell ready.
        self.IsReady = function() return player:spellSlot(self.slot).state == 0 end
        
        --* Returns spell cost.
        self.GetCost = function()
            if self.slot == 0 then return player.manaCost0
            elseif self.slot == 1 then return player.manaCost1
            elseif self.slot == 2 then return player.manaCost2
            elseif self.slot == 3 then return player.manaCost3
            end
        end
        
        --* Returns is spell castable.
        self.IsCastable = function()
            if not self.IsReady() or player.mana < self.GetCost() then return false end
            return true
        end
        
        --* Returns optimal target.
        self.GetTarget = function(percantageRange)
            local targetFilter = function(res, obj, dist)
                    --? Checking is target in spell's range.
                    if dist > self.range then return end
                    
                    --? Checking is target in spell's percentile.
                    if percantageRange and dist > ((self.range / 100) * percantageRange) then return end
                    
                    --? Checking is target is valid.
                    if not obj or obj.isDead or not obj.isVisible or not obj.isTargetable then return end
                    
                    -- local HasProtectiveBuffs = function()
                    --     local result = false
                    --     for i = 0, obj.buffManager.count - 1 do
                    --         local buff = obj.buffManager:get(i)
                    --         if buff and buff.name == "empathizeaura" then result = true end
                    --     end
                    --     return result
                    -- end
                    --? Checking spellshield.
                    --TODO Will check this again.
                    -- if HasProtectiveBuffs() then return end
                    res.obj = obj
                    return true
            end
            
            return TargetSelector.get_result(targetFilter).obj
        end
        
        --* Returns prediction segment.
        self.GetSegment = function(target)
                -- local spellPred = self.GetPrediction()
                -- local seg = spellPred.get_prediction(self, target)
                -- if not seg then return end
                -- if seg.startPos:dist(seg.endPos) > self.range then return end
                -- local castPosition = vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y)
                -- return seg, castPosition
                local castPosition = PredLinear(target, self.delay, self.speed, self.range, self.width)
                
                if not castPosition then return end
                
                local seg =
                    {
                        startPos = vec2(player.pos.x, player.pos.z),
                        endPos = vec2(castPosition.x, castPosition.z)
                    }
                
                if seg.startPos:dist(seg.endPos) > self.range then return end
                
                return seg, castPosition
        end
        
        --* Returns spells hit time to target.
        self.GetHitTime = function(segment) return segment.startPos:dist(segment.endPos) / self.speed end
        
        --* Returns hit time ratio.
        self.hitTimeRatio = function(segment)
            return self.GetHitTime(segment) / self.maxHitTime
        end
        
        --* Checks collision.
        self.GetCollision = function(segment, target)
            local collisionTable = prediction.collision.get_prediction(self, segment, target)
            
            if not collisionTable then return false end
            
            --TODO  Will look into it.
            if self.collision.wall then return true end
            
            local collisionCount = 0
            
            for _, object in pairs(collisionTable) do
                if object.type == TYPE_HERO and self.collision.hero then collisionCount = collisionCount + 1
                elseif object.type == TYPE_MINION and self.collision.minion then collisionCount = collisionCount + 1
                end
            end
            
            --? Checks allowed collision count. (For spells like Lux's Q)
            if collisionCount <= (self.collision.allowedCount or 0) then return false end
            
            return true
        end
        
        --* Checks conditions that spell is good to cast at that time.
        self.GetCastCondition = function(segment, target)
            local optimumCastRange = self.range - (self.delay * target.moveSpeed) - target.boundingRadius
            local spellTrace = self.GetTrace()
            
            --? Stun/Snare Check
            if spellTrace.hardlock(self, segment, target) then return true end
            
            --? Dash/Fear Check
            if spellTrace.hardlockmove(self, segment, target) then return true end
            
            --? Path Check
            if prediction.trace.newpath(target, self.delay / self.maxHitTime, self.delay) or
                --? Extra Range Check
                segment.startPos:dist(segment.endPos) < optimumCastRange then
                return true
            end
            
            return false
        end
        
        --* Casts spell at optimal target.
        self.Cast = function(percantageRange)
            if not self.IsCastable() then return end
            
            local target = self.GetTarget(percantageRange)
            
            if not target then return end
            
            local seg, castPosition = self.GetSegment(target)
            
            if not seg or not castPosition then return end
            
            local collision = self.GetCollision(seg, target)
            
            if collision then return end
            
            local condition = self.GetCastCondition(seg, target)
            
            if not condition then return end
            
            player:castSpell("pos", self.slot, castPosition)
        end
    end
end

InitializeSpellFunctions()

local function IsUnderTurretEnemyActive(pos)
    if not pos then 
        return false 
    end
    for i = 0, objManager.turrets.size[TEAM_ENEMY] - 1 do
        local tower = objManager.turrets[TEAM_ENEMY][i]
        if  tower and not tower.isDead and tower.health > 0 then
            if tower.activeSpell and tower.activeSpell.target.ptr == player.ptr then
                if tower.pos:dist(pos) < 900 then
                    return true
                end 
            end
        else
            tower = nil
        end 
    end 
    return false
end

local function OnCreatObj(obj)
    --[[if obj and obj.name and obj.name:lower():find("leblanc") then 
        print("Created "..obj.name);
    end]]
    if obj and obj.type then
        if (obj.name:find("Q_mis") or obj.name:find("RQ_mis")) then
            QlasTick = game.time + 500
        end
    end
    if obj.type then
        if obj.name:find("W_return_indicator") then
            WBoot[obj.ptr] = obj
        end
        if obj.name:find("RW_return_indicator") then
            RWBoot[obj.ptr] = obj
        end
    end
end

local function OnDeleteObj(obj)
    if obj  then
    
            QlasTick = 0
    end
    if obj then
       
            WBoot[obj.ptr]  = nil
        
       
            RWBoot[obj.ptr] = nil
        
    end
    if obj then
        Clone = nil
    end
end 


local function GetShieldedHealth(damageType, target)
    local shield = 0
    if damageType == "AD" then
      shield = target.physicalShield
    elseif damageType == "AP" then
      shield = target.magicalShield
    elseif damageType == "ALL" then
      shield = target.allShield
    end
    return target.health + shield
end

local MenuLeBlanc = menu("IntnnerLeblanc", "Int LeBlanc")
MenuLeBlanc:menu("lb", "Combo")
MenuLeBlanc.lb:header("xd", "Combo")
MenuLeBlanc.lb:boolean("CQ", "Use Q", true)
MenuLeBlanc.lb:boolean("CW", "Use W", true)
MenuLeBlanc.lb:menu("LBW", "Mimic Settings")
MenuLeBlanc.lb.LBW:boolean("CWGapCombo", "Use W to Gapclose", false)
MenuLeBlanc.lb.LBW:boolean("turretC", "Don't W Under Turret", true)
MenuLeBlanc.lb:boolean("CE", "Use E", true)
MenuLeBlanc.lb:boolean("SlowE", "^~ Use Prediction Slow", true)
MenuLeBlanc.lb:boolean("CrEr", "Use Double Stun", true)
MenuLeBlanc.lb:menu("LBR", "Mimic Settings")
MenuLeBlanc.lb.LBR:boolean("CR", "Use R ", true)
MenuLeBlanc.lb.LBR:boolean("CQR", "Use [R > Q]", true)
MenuLeBlanc.lb.LBR:boolean("CWR", "Use [R > W]", false)
MenuLeBlanc.lb.LBR:boolean("CER", "Use [R > E]", false)

MenuLeBlanc:menu("hlb", "Harass")
MenuLeBlanc.hlb:header("xd", "Harass")
MenuLeBlanc.hlb:boolean("HQ", "Use Q", true)
MenuLeBlanc.hlb:slider("QMana", "Min mana % to Q", 40, 0, 100, 1)
MenuLeBlanc.hlb:boolean("HW", "Use W", true)
MenuLeBlanc.hlb:boolean("CWGap", "<W to Gapclose> (Extended W)", false)
MenuLeBlanc.hlb:boolean("AuW", "Auto W", true)
MenuLeBlanc.hlb:slider("WMana", "Min mana % to W", 40, 0, 100, 1)
MenuLeBlanc.hlb:boolean("HE", "Use E", true)
MenuLeBlanc.hlb:slider("EMana", "Min mana % to E", 40, 0, 100, 1)
MenuLeBlanc.hlb:keybind("Hak", "Harass Key:", "C", nil)

MenuLeBlanc:menu("llb", "WaveClear")
MenuLeBlanc.llb:header("xd", "WaveClear")
MenuLeBlanc.llb:boolean("LQ", "Use Q", true)
MenuLeBlanc.llb:slider("QMana", "Min mana % to Q", 20, 0, 100, 1)
MenuLeBlanc.llb:boolean("LW", "Use W", true)
MenuLeBlanc.llb:boolean("LRW", "Use RW", false)
MenuLeBlanc.llb:slider("WMana", "Min mana % to W", 20, 0, 100, 1)
MenuLeBlanc.llb:header("xd1", "Min Minions")
MenuLeBlanc.llb:slider("MCount", "Min minions to W", 4, 0, 10, 1)
MenuLeBlanc.llb:boolean("ALW2", "Auto W2", true)
MenuLeBlanc.llb:keybind("KeyV", "Wave Key:", "V", nil)

MenuLeBlanc:menu("alb", "AntiGapclose")
MenuLeBlanc.alb:header("xd", "AntiGapclose")
MenuLeBlanc.alb:boolean("CAE", "E Anti-Gapclose", true)
MenuLeBlanc.alb:boolean("CAER", "R (E) Anti-Gapclose", false)

MenuLeBlanc:menu("flb", "Flee")
MenuLeBlanc.flb:header("xd", "Flee")
MenuLeBlanc.flb:boolean("Fleee", "Use E", true)
MenuLeBlanc.flb:boolean("Fleew", "Use W to cursor pos", true)
MenuLeBlanc.flb:boolean("Fleerw", "Use R (W) to cursor pos", false)
MenuLeBlanc.flb:keybind("KeyF", "Flee Key:", "Z", nil)

MenuLeBlanc:menu("klb", "Killsteal")
MenuLeBlanc.klb:header("xd", "Killsteal")
MenuLeBlanc.klb:boolean("qk", "Use Q KS", true)
MenuLeBlanc.klb:boolean("wk", "Use W KS", true)
MenuLeBlanc.klb:boolean("yext", "Use extended W (or R) to KS (W + Q or E)", true)
MenuLeBlanc.klb:boolean("wr", "Use W+R + Q/E to KS", true)
MenuLeBlanc.klb:boolean("eks", "Use E KS", true)
MenuLeBlanc.klb:boolean("rks", "Use R KS", true)

MenuLeBlanc:menu("mlb", "Misc")
MenuLeBlanc.mlb:header("xd", "Misc")
MenuLeBlanc.mlb:boolean("wrs", "Use W2 Return", false)
MenuLeBlanc.mlb:slider("ATW2", "Auto W2 when your health is lower than", 0, 0, 100, 1)
MenuLeBlanc.mlb:boolean("UnderW", "Auto Save W2 Return UnderTurren", false)

MenuLeBlanc:menu("dlb", "Drawing")
MenuLeBlanc.dlb:header("xd", "Drawing")
MenuLeBlanc.dlb:boolean("DQ", "Draw Q range", true)
MenuLeBlanc.dlb:boolean("DW", "Draw W range", false)
--MenuLeBlanc.dlb:boolean("DE", "Draw W Position", false)
MenuLeBlanc.dlb:boolean("DE", "Draw E range", false)
MenuLeBlanc.dlb:header("xd13", "Drawing Damage")

local function PredSlow(input, segment, target)
	if prediction.trace.linear.hardlock(input, segment, target) then
		return true
	end
	if prediction.trace.linear.hardlockmove(input, segment, target) then
		return true
	end
	if segment.startPos:dist(segment.endPos) <= 865 then
		return true
	end
	if prediction.trace.newpath(target, 0.033, 0.5) then
		return true
	end
end
--[[local function Obj_AI_Base_OnProcessSpellCast(slot, vec3, vec3, networkID, isInjected)
    if networkID > 0 and isInjected == true then
        if (player) then
            local Hero = TargetSelection()
            if (slot == 0 and player.activeSpell == Hero) then
                QlasTick = game.time + 500
            elseif (slot == 3 and player:spellSlot(3).name == "LeblancRQ" and player.activeSpell == Hero) then
                QlasTick = game.time + 500
            end
        end
    end
end]]
local function UsedW() 
	if player:spellSlot(1).name == "LeblancWReturn" then 
		return true
	else 
		return false
	end
end
--
local function UsedRW() 
	if player:spellSlot(1).name == "LeblancRWReturn" then 
		return true
	else 
		return false
	end
end
--
local function UseQR()
	if player:spellSlot(3).name == "LeblancRQ" then 
		return true
	else 
		return false
	end
end
--
local function UseWR()
	if player:spellSlot(3).name == "LeblancRW" then 
		return true
	else 
		return false
	end
end
--
local function UseER()
	if player:spellSlot(3).name == "LeblancRE" then 
		return true
	else 
		return false
	end
end

local function CountEnemyChampionsInRange(pos, range) 
	local enemies_in_range = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if pos:dist(enemy.pos) < range and IsValidTarget(enemy)  then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

local function CountAlliesChampionsInRange(pos, range) 
	local enemies_in_range = {}
	for i = 0, objManager.allies_n - 1 do
		local enemy = objManager.allies[i]
		if pos:dist(enemy.pos) < range and IsValidTarget(enemy)  then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

function GetMinionsHit(Pos, radius)
	local count = 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local object = objManager.minions[TEAM_ENEMY][i]
		if GetDistance(object, Pos) < radius then
			count = count + 1
		end
	end
	return count
end

local function GetPercentHealth(obj)
    local obj = obj or player
    return (obj.health / obj.maxHealth) * 100
end


local function On_Draw()
    if player and not player.isDead and player.isVisible and player.isTargetable and not player.buff[17] then
        local playerPos = vec3(player.x, player.y, player.z)
        if MenuLeBlanc.dlb.DQ:get() and player:spellSlot(0).state == 0 then
            graphics.draw_circle(playerPos, 700, 2, graphics.argb(255, 153, 0, 153), 100) 
        end 
        if MenuLeBlanc.dlb.DW:get() and player:spellSlot(1).state == 0 then
            graphics.draw_circle(player.pos, 600, 2, graphics.argb(255, 153, 0, 153), 100) 
        end
        if MenuLeBlanc.dlb.DE:get() and player:spellSlot(2).state == 0 then
            graphics.draw_circle(player.pos, 825, 2, graphics.argb(255, 153, 0, 153), 100) 
        end
    end
end

local function KillSteal()
    for i = 0, objManager.enemies_n - 1 do
        local target = objManager.enemies[i]
        if not target.isDead and target.isVisible and target.isTargetable and IsValidTarget(target) and not target.buff["sionpassivezombie"] then
            if GetPercentHealth() < MenuLeBlanc.mlb.ATW2:get() then
                if player:spellSlot(1).name == "LeblancWReturn" then
                    player:castSpell("pos", 1, player.pos)
                end
            end
            if ValidTargetRange(target, 600*2+700) then
                RReady = player:spellSlot(3).name == "LeblancRQ" or player:spellSlot(3).name == "LeblancRW"  or player:spellSlot(3).name == "LeblancRE";
                WReady = player:spellSlot(1).name ~= "LeblancWReturn" and player:spellSlot(1).state == 0;
                wpos = player.pos + (target.pos - player.pos):norm() * 600;
                QDmg = Dano.DamageQ(target);
                WDmg = Dano.DamageW(target);
                EDmg = Dano.DamageE(target);
                RDmg = Dano.DamageRQ(target) or Dano.DamageRW(target) or Dano.DamageRE(target);
                if player:spellSlot(3).state == 0 and MenuLeBlanc.klb.rks:get() and target.pos:dist(player.pos) < 700 then
                    if QDmg < target.health or not player:spellSlot(0).state == 0 then
                        if RDmg > target.health then
                            if ValidTargetRange(target, 700) and player:spellSlot(3).name == "LeblancRQ" and player:spellSlot(3).state == 0 then
                                player:castSpell("obj", 3, target)
                            elseif ValidTargetRange(target, 600) and player:spellSlot(3).name == "LeblancRW" and player:spellSlot(3).state == 0 then
                                player:castSpell("pos", 3, target.pos)
                            elseif ValidTargetRange(target, 860) and player:spellSlot(3).name == "LeblancRE" and player:spellSlot(3).state == 0 then
                                ePred = { delay = 0.25, width = 54, speed = 1750, boundingRadiusMod = 1, collision = {hero = true, minion = true, wall = true} }
                                local seg = prediction.linear.get_prediction(ePred, target)
                                if seg and seg.startPos:dist(seg.endPos) < 860 and player:spellSlot(2).state == 0 then
                                    if not prediction.collision.get_prediction(ePred, seg, target) then
                                        player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                                    end
                                end
                            end
                        end
                    end
                end
                if (QDmg + WDmg + EDmg > target.health) then
                    if ValidTargetRange(target, 700) and player:spellSlot(0).state == 0 and MenuLeBlanc.klb.qk:get() then
                        player:castSpell("obj", 0, target)
                    end
                    if ValidTargetRange(target, 600) and player:spellSlot(1).name ~= "LeblancWReturn" and player:spellSlot(1).state == 0 and MenuLeBlanc.klb.wk:get() then
                        player:castSpell("pos", 1, target.pos)
                    end
                    if ValidTargetRange(target, 860) and player:spellSlot(2).state == 0 and MenuLeBlanc.klb.eks:get() then
                        ePred = { delay = 0.25, width = 54, speed = 1750, boundingRadiusMod = 1, collision = {hero = true, minion = true, wall = true} }
                        local seg = prediction.linear.get_prediction(ePred, target)
                        if seg and seg.startPos:dist(seg.endPos) < 860 and player:spellSlot(2).state == 0 then
                            if not prediction.collision.get_prediction(ePred, seg, target) then
                                player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                            end
                        end
                    end
                end
                if player:spellSlot(0).state == 0 and MenuLeBlanc.klb.qk:get() and QDmg > target.health then
                    if ValidTargetRange(target, 700+600) then
                        if ValidTargetRange(target, 700) then
                            player:castSpell("obj", 0, target)
                        elseif (WReady) then
                            if (600 + 700 > player.pos:dist(target.pos) and MenuLeBlanc.klb.wk:get() and MenuLeBlanc.klb.yext:get()) then
                                if player:spellSlot(1).name ~= "LeblancWReturn" then
                                    player:castSpell("pos", 1, wpos)
                                end
                            end 
                        elseif (RReady) then
                            if (600 + 700 > player.pos:dist(target.pos) and MenuLeBlanc.klb.rks:get() and MenuLeBlanc.klb.yext:get()) then
                                if player:spellSlot(3).name ~= "LeblancRWReturn" and player:spellSlot(3).name == "LeblancRW" then
                                    player:castSpell("pos", 3, wpos)
                                end
                            end
                        end
                    elseif ValidTargetRange(target, 700+600*2) and player:spellSlot(0).state == 0 and WReady and RReady then
                        if ValidTargetRange(target, 700) then
                            player:castSpell("obj", 0, target)
                        elseif player:spellSlot(1).name ~= "LeblancRWReturn" then
                            player:castSpell("pos", 1, wpos)
                            Delyas = player.pos:dist(wpos) / 1800 + network.latency / 2
                            DelayAction(function() player:castSpell("pos", 3, wpos)  end, Delyas)
                        end
                    end
                elseif (player:spellSlot(2).state == 0 and MenuLeBlanc.klb.eks:get() and EDmg > target.health) then
                    if (860 + 700 > player.pos:dist(target.pos)) then
                        if (player:spellSlot(2).state == 0) then
                            ePred = { delay = 0.25, width = 54, speed = 1750, boundingRadiusMod = 1, collision = {hero = true, minion = true, wall = true} }
                            local seg = prediction.linear.get_prediction(ePred, target)
                            if seg and seg.startPos:dist(seg.endPos) < 860 and player:spellSlot(2).state == 0 then
                                if not prediction.collision.get_prediction(ePred, seg, target) then
                                    player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                                end
                            end
                        elseif (WReady) then
                            if (860 + 700 > player.pos:dist(target.pos) and MenuLeBlanc.klb.wk:get() and MenuLeBlanc.klb.yext:get()) then
                                if player:spellSlot(1).name ~= "LeblancWReturn" then
                                    player:castSpell("pos", 1, wpos)
                                end
                            end 
                        elseif (RReady) then
                            if (860 + 700 > player.pos:dist(target.pos) and MenuLeBlanc.klb.rks:get() and MenuLeBlanc.klb.yext:get()) then
                                if player:spellSlot(3).name ~= "LeblancRWReturn" and player:spellSlot(3).name == "LeblancRW" then
                                    player:castSpell("pos", 3, wpos)
                                end
                            end
                        end 
                    elseif ValidTargetRange(target, 860+600*2) and player:spellSlot(2).state == 0 and WReady and RReady then 
                        if (ValidTargetRange(target, 860)) then
                            ePred = { delay = 0.25, width = 54, speed = 1750, boundingRadiusMod = 1, collision = {hero = true, minion = true, wall = true} }
                            local seg = prediction.linear.get_prediction(ePred, target)
                            if seg and seg.startPos:dist(seg.endPos) < 860 and player:spellSlot(2).state == 0 then
                                if not prediction.collision.get_prediction(ePred, seg, target) then
                                    player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                                end
                            end
                        elseif player:spellSlot(1).name ~= "LeblancWReturn" then
                            player:castSpell("pos", 1, wpos)
                            if player:spellSlot(1).name ~= "LeblancWReturn" then
                                Delyas = player.pos:dist(wpos) / 1800 + network.latency / 2
                                DelayAction(function() player:castSpell("pos", 3, wpos)  end, Delyas)
                            end
                        end 
                    end
                elseif (WReady and WDmg > target.health) then
                    if ValidTargetRange(target, 600) then
                        if player:spellSlot(1).name ~= "LeblancWReturn" then
                            player:castSpell("pos", 1, target.pos)
                        elseif player:spellSlot(1).name ~= "LeblancWReturn" then
                            if ValidTargetRange(target, 600*2) then
                                player:castSpell("pos", 3, wpos)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function WaveClear()
    if MenuLeBlanc.llb.LQ:get() then
        MinionsQ = common.GetMinionsInRange(700, TEAM_ENEMY)
        for i, minion in pairs(MinionsQ) do
            if minion then
                local minionPos = vec3(minion.x, minion.y, minion.z)
                if (player.mana / player.maxMana) * 100 >= MenuLeBlanc.llb.QMana:get() then
                    if player:spellSlot(0).state == 0 and minionPos:dist(player.pos) < 700 and (Dano.DamageQ(minion) >= orbwalker.farm.predict_hp(minion, 0.25, true)) then
                        player:castSpell("obj", 0, minion)
                    end 
                end
            end 
        end
    end
    if MenuLeBlanc.llb.LW:get() then
        MinionsW = common.GetMinionsInRange(600, TEAM_ENEMY)
        for i, minion in pairs(MinionsW) do
            if minion then
                local minionPos = vec3(minion.x, minion.y, minion.z)
                if (player.mana / player.maxMana) * 100 >= MenuLeBlanc.llb.WMana:get() and not IsUnderTurretEnemy(minionPos) then
                    if player:spellSlot(1).state == 0 and player:spellSlot(1).name ~= "LeblancWReturn"  and minionPos:dist(player.pos) < 700 and GetMinionsHit(minion, 260) >= MenuLeBlanc.llb.MCount:get() then
                        player:castSpell("pos", 1, minionPos)
                    end
                end
            end
        end
    end
    if MenuLeBlanc.llb.LRW:get() then
        MinionsW = common.GetMinionsInRange(600, TEAM_ENEMY)
        for i, minion in pairs(MinionsW) do
            if minion then
                local minionPos = vec3(minion.x, minion.y, minion.z)
                if not IsUnderTurretEnemy(minionPos) then
                    if player:spellSlot(3).state == 0 and player:spellSlot(3).name == "LeblancRW" and minionPos:dist(player.pos) < 700 and GetMinionsHit(minion, 260) >= MenuLeBlanc.llb.MCount:get() then
                        player:castSpell("pos", 3, minionPos)
                    end
                end
            end
        end
    end
    if MenuLeBlanc.llb.ALW2:get() then
        if player:spellSlot(1).name == "LeblancWReturn" then
            player:castSpell("pos", 1, player.pos)
        end
    end
end

local function AntiGapclose()
    if MenuLeBlanc.alb.CAE:get() then
        if player:spellSlot(2).state == 0 then
            for i = 0, objManager.enemies_n - 1 do
                local dasher = objManager.enemies[i]
                if dasher.type == TYPE_HERO and dasher.team == TEAM_ENEMY then 
                    if dasher and IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and  player.pos:dist(dasher.path.point[1]) < 825 then
                        if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[0]) then
                            if ((player.health / player.maxHealth) * 100 <= 100) then
                                local seg = prediction.linear.get_prediction(ePred, dasher)
                                if seg and seg.startPos:dist(seg.endPos) < 865 then

                                    if not prediction.collision.get_prediction(ePred, seg, dasher) then
                                        player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                                    end 
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if MenuLeBlanc.alb.CAER:get() then
        if player:spellSlot(3).state == 0 and player:spellSlot(3).name == "LeblancRE" then
            for i = 0, objManager.enemies_n - 1 do
                local dasher = objManager.enemies[i]
                if dasher.type == TYPE_HERO and dasher.team == TEAM_ENEMY then 
                    if dasher and IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and  player.pos:dist(dasher.path.point[1]) < 825 then
                        if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[0]) then
                            if ((player.health / player.maxHealth) * 100 <= 100) then
                                local seg = prediction.linear.get_prediction(ePred, dasher)
                                if seg and seg.startPos:dist(seg.endPos) < 865 then

                                    if not prediction.collision.get_prediction(ePred, seg, dasher) then
                                        player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
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

local function HarassMode()
    target = TargetSelection()
    if target == nil then return end
    _Q = MenuLeBlanc.hlb.HQ:get() and player:spellSlot(0).state == 0  and (player.mana / player.maxMana) * 100 >= MenuLeBlanc.hlb.QMana:get();
    _W = MenuLeBlanc.hlb.HW:get() and player:spellSlot(1).name ~= "LeblancWReturn" and player:spellSlot(2).state == 0 and (player.mana / player.maxMana) * 100 >= MenuLeBlanc.hlb.WMana:get();
    _E = MenuLeBlanc.hlb.HE:get() and player:spellSlot(2).state == 0  and (player.mana / player.maxMana) * 100 >= MenuLeBlanc.hlb.EMana:get();
    _IzW = MenuLeBlanc.hlb.CWGap:get();
    wpos = player.pos + (target.pos - player.pos):norm() * 600
    if MenuLeBlanc.hlb.AuW:get() then
        if player:spellSlot(1).name == "LeblancWReturn" and not _Q and not _E and not target.buff["leblance"] then
            player:castSpell("pos", 1, player.pos)
        end
    end
    if (_Q) then
        if ValidTargetRange(target, 700) then
            player:castSpell("obj", 0, target)
        elseif (_IzW and ValidTargetRange(target, 700+600)) and player:spellSlot(1).name ~= "LeblancWReturn" then
            player:castSpell("pos", 1, wpos)
        end
    elseif (_W) then
        if player:spellSlot(1).name == "LeblancW" and ValidTargetRange(target, 600) then
            player:castSpell("pos", 1, target.pos)
        end
    elseif (_E) then
        ePred = { delay = 0.25, width = 54, speed = 1750, boundingRadiusMod = 1, collision = {hero = true, minion = true, wall = true} }
        local seg = prediction.linear.get_prediction(ePred, target)
        if seg and seg.startPos:dist(seg.endPos) < 860 and player:spellSlot(2).state == 0 then
            if not prediction.collision.get_prediction(ePred, seg, target) then
                player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
            end
        end
    end
end

local function Combo()
    target = TargetSelection()
    if target and IsValidTarget(target) then
        if target ~= nil then
            if MenuLeBlanc.lb.CQ:get() then
                if player:spellSlot(0).state == 0 then
                    if (not UsedW() or player:spellSlot(2).state == 0 or player:spellSlot(3).state == 0 or target.buff["leblance"] or QlasTick > game.time  or player.levelRef == 1 or target.buff["leblancrqmark"] or (player:spellSlot(1).cooldown > 0 and player:spellSlot(1).cooldown < 4) or (player:spellSlot(2).cooldown > 0 and player:spellSlot(2).cooldown < 4)) then
                        if ValidTargetRange(target, 700) then
                            player:castSpell("obj", 0, target)
                        end
                    end
                end
            end
            if MenuLeBlanc.lb.CW:get() then
                if MenuLeBlanc.lb.LBW.CWGapCombo:get() and player.pos:dist(target.pos) > 700 then
                    if (not UsedW()) then
                        local wpos = player.pos + (target.pos - player.pos):norm() * 600
                        if (player:spellSlot(0).state == 0 and MenuLeBlanc.lb.CQ:get()) then
                            if 700 + 600 > player.pos:dist(target.pos) then
                                player:castSpell("pos", 1, wpos)
                            end
                        elseif (player:spellSlot(2).state == 0 and MenuLeBlanc.lb.CE:get()) then
                            if 800 + 600 > player.pos:dist(target.pos) then
                                player:castSpell("pos", 1, wpos)
                            end
                        end
                    end
                else
                    if (not UsedW()) then
                        if ValidTargetRange(target, 715) then
                            if (target.buff["leblancqmark"] or target.buff["leblance"] or QlasTick > game.time or player.levelRef == 1 or target.buff["leblancrqmark"] or target.buff["leblancre"]) then
                                local res = prediction.circular.get_prediction(wPred, target)
                                if res and res.startPos:dist(res.endPos) < 800 and not navmesh.isWall(vec3(res.endPos.x, game.mousePos.y, res.endPos.y)) then
                                    player:castSpell("pos", 1, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
                                end
                            end
                        end
                    end
                end
            end
            if MenuLeBlanc.lb.CE:get() then
                if (player:spellSlot(2).state == 0 and (UsedW() or player.levelRef == 1)) then
                    --if(MenuLeBlanc.lb.LBR.CWR:get() and player:spellSlot(3).name == "LeblancRW" and player:spellSlot(3).state == 0) then return end
                    local seg = prediction.linear.get_prediction(ePred, target)
                    if seg and seg.startPos:dist(seg.endPos) < 865 then
                        if not prediction.collision.get_prediction(ePred, seg, target) and PredSlow(ePred, seg, target) then
                            player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                        end
                    end
                elseif (player:spellSlot(2).state == 0 and (player:spellSlot(1).state ~= 0)) then
                    --if(MenuLeBlanc.lb.LBR.CWR:get() and player:spellSlot(3).name == "LeblancRW" and player:spellSlot(3).state == 0) then return end
                    local seg = prediction.linear.get_prediction(ePred, target)
                    if seg and seg.startPos:dist(seg.endPos) < 865 then
                        if not prediction.collision.get_prediction(ePred, seg, target) and PredSlow(ePred, seg, target) then
                            player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                        end
                    end
                end
                if MenuLeBlanc.lb.CrEr:get() then
                    if target.buff["leblanceroot"] and player:spellSlot(3).name == "LeblancRE" then
                        local seg = prediction.linear.get_prediction(ePred, target)
                        if seg and seg.startPos:dist(seg.endPos) < 865 then
                            if not prediction.collision.get_prediction(ePred, seg, target) and PredSlow(ePred, seg, target) then
                                player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                            end
                        end
                    end
                end
            end
            if MenuLeBlanc.lb.LBR.CR:get() then
                if MenuLeBlanc.lb.LBR.CQR:get() then
                    if player:spellSlot(3).name == "LeblancRQ" then
                        if (not UsedW() or player:spellSlot(2).state == 0 or player:spellSlot(0).state == 0 or target.buff["leblance"] or QlasTick > game.time  or target.buff["leblancqmark"]  or (player:spellSlot(1).cooldown > 0 and player:spellSlot(1).cooldown <= 4) or (player:spellSlot(2).cooldown > 0 and player:spellSlot(2).cooldown <= 4)) then
                            if ValidTargetRange(target, 700) then
                                player:castSpell("obj", 3, target)
                            end
                        end
                    end 
                end
                if MenuLeBlanc.lb.LBR.CWR:get() then
                    if player:spellSlot(3).name == "LeblancRW" then
                        if ValidTargetRange(target, 700) then
                            if (#CountEnemyChampionsInRange(target.pos, 210) > 1) then
                                spells["RW"].Cast()
                            elseif (player:spellSlot(0).state ~= 0 and player:spellSlot(2).state ~= 0) then
                                spells["RW"].Cast()
                            end
                        end
                    end
                end
                if MenuLeBlanc.lb.LBR.CER:get() then
                    if player:spellSlot(3).name == "LeblancRE" then
                        if (player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0) then
                            if ValidTargetRange(target, 865) then
                                local seg = prediction.linear.get_prediction(ePred, target)
                                if seg and seg.startPos:dist(seg.endPos) < 865 then
                                    if not prediction.collision.get_prediction(ePred, seg, target) and PredSlow(ePred, seg, target) then
                                        player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
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

local function LB_CastW_2()
    if player:spellSlot(1).name == "LeblancWReturn" then
        player:castSpell("pos", 1, player.pos)
    end
end

local function LB_CastW_3()
    if player:spellSlot(3).name == "LeblancRWReturn" then
        player:castSpell("pos", 3, player.pos)
    end
end
local function LB_Return()
	if (player:spellSlot(3).name == "LeblancRWReturn" or player:spellSlot(1).name == "LeblancWReturn") then
        for i = 0, objManager.enemies_n - 1 do
            local Enemy = objManager.enemies[i]
            if Enemy and Enemy.isDead and Enemy.buff[17] then return end
            for _, W in pairs(WBoot) do
                if W then
                    if Enemy.buff["leblance"] or Enemy.buff["leblancre"] or ValidTargetRange(Enemy, 830) then return false end

                    local EPos  = #CountEnemyChampionsInRange(player.pos, 650)
                    local EWPos = #CountEnemyChampionsInRange(W.pos, 650)
                    local APos  = #CountAlliesChampionsInRange(player.pos, 650)
                    local AWPos = #CountAlliesChampionsInRange(W.pos, 650)
    
                    if (EPos > APos) or (EWPos > AWPos) or IsUnderTurretEnemy(W.pos) then return false end
    
                    LB_CastW_2()
                    return true
                end	
			end
            for _, RW in pairs(RWBoot) do
                if RW then
                    if  Enemy.buff["leblance"] or  Enemy.buff["leblancre"] or  ValidTargetRange(Enemy, 865) then return false end

				local EPos  = #CountEnemyChampionsInRange(player.pos, 650)
				local EWPos = #CountEnemyChampionsInRange(RW.pos, 650)
				local APos  = #CountAlliesChampionsInRange(player.pos, 650)
				local AWPos = #CountAlliesChampionsInRange(RW.pos, 650)

				if (EPos < APos) or (EWPos < AWPos) or IsUnderTurretEnemy(RW.pos) then return false end

				LB_CastW_3()
				return true	
                end	
			end
		end
	end
	return false
end

local Togle = 0
local function OnTick()
    if player.isDead and player.buff[17] then return end 
    --FindKillableR();
    if Clone ~= nil then
    player:altmove(mousePos) 
end
    KillSteal();
    if MenuLeBlanc.mlb.wrs:get() and not (MenuLeBlanc.flb.KeyF:get()) then
        if orbwalker.combat.is_active() then
            LB_Return();
        end
    end
    if MenuLeBlanc.mlb.UnderW:get() then
        for i = 0, objManager.turrets.size[TEAM_ENEMY] - 1 do
            local tower = objManager.turrets[TEAM_ENEMY][i]
            for _, W in pairs(WBoot) do
                if W  and tower then
                    if IsUnderTurretEnemyActive(player.pos) then
                        if player:spellSlot(1).name == "LeblancW" then
                            wpos = tower.pos + (player.pos - tower.pos):norm() * 950
                            player:castSpell("pos", 1, game.mousePos)
                        else
                            if not IsUnderTurretEnemy(W.pos) and player:spellSlot(3).state ~= 0 and player:spellSlot(0).state ~= 0 and player:spellSlot(2).state ~= 0 then
                                LB_CastW_2()
                            end
                        end
                    end
                end
            end
        end
    end
    if MenuLeBlanc.llb.KeyV:get() then 
        WaveClear();
    end
    --> Gap
    AntiGapclose();
    --> Flee

    if MenuLeBlanc.flb.KeyF:get() then
        if MenuLeBlanc.flb.Fleee:get() then
            for i = 0, objManager.enemies_n - 1 do
                local target = objManager.enemies[i]
                if target and target.isDead and target.buff[17] then return end
                ePred = { delay = 0.25, width = 54, speed = 1750, boundingRadiusMod = 1, collision = {hero = true, minion = true, wall = true} }
                local seg = prediction.linear.get_prediction(ePred, target)
                if seg and seg.startPos:dist(seg.endPos) < 860 and player:spellSlot(2).state == 0 then
                    if not prediction.collision.get_prediction(ePred, seg, target) then
                        player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                    end
                end
            end
            if MenuLeBlanc.flb.Fleew:get() then
                if player:spellSlot(1).state == 0 and player:spellSlot(1).name ~= "LeblancWReturn" then
                    wpos = player.pos + (game.mousePos - player.pos):norm() * 600
                    if not navmesh.isWall(wpos) then
                        player:castSpell("pos", 1, wpos)
                    end   
                end
            end
            if MenuLeBlanc.flb.Fleerw:get() then
                if player:spellSlot(3).state == 0 and player:spellSlot(3).name == "LeblancRW" and player:spellSlot(1).name ~= "LeblancRWReturn" then
                    wpos = player.pos + (game.mousePos - player.pos):norm() * 600
                    if not navmesh.isWall(wpos) then
                        player:castSpell("pos", 3, wpos)
                    end   
                end
            end
        end
        player:move(game.mousePos)
    end
    if MenuLeBlanc.hlb.Hak:get() then 
        HarassMode();
    end

    if not orbwalker.combat.is_active() then return end
    Combo();

end

orbwalker.combat.register_f_pre_tick(OnTick)
--cb.add(cb.castspell, Obj_AI_Base_OnProcessSpellCast)
cb.add(cb.draw, On_Draw)
cb.add(cb.create_particle, OnCreatObj)
cb.add(cb.delete_particle, OnDeleteObj)