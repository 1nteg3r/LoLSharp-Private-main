local common = module.load('int', 'Library/common');
local Extentions = module.load('int', 'Core/Yasuo/Extentions')
local DashingManager = module.load('int', 'Core/Yasuo/DashingManager');
local pred = module.internal('pred');

local function GetNewQSpeed()
    return  (1/(1/0.5*player.attackSpeedMod))
end

local Q1 = {
    range = 450,
    delay = math.huge, 
    width = 55, 
    speed = 1500,
    boundingRadiusMod = 1
}

local Q3 = {
    range = 900,
    delay = 0.28, 
    width = 90, 
    speed = 1500,
    boundingRadiusMod = 1
}

local function EDelay()
    return  ({10000, 9000, 8000, 7000, 6000})[player:spellSlot(0).level]
end

local function GetKnockedUpTargets()
    local enemies_in_range = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if player.pos:dist(enemy.pos) < 1400 and common.IsValidTarget(enemy) and enemy.buff[29] then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

local function GetLowestKnockupTime()
    for i = 0, objManager.enemies_n - 1 do
        local target = objManager.enemies[i]
        if target and common.IsValidTarget(target) then 
            local buff = (target.buff[29] or target.buff[30]);
            if buff and buff.valid and buff.owner == target then 
                return (buff.endTime - game.time) * 1000
            end
        end
    end
    return 0
end

local function StackQ()
    if not (player:spellSlot(0).state == 0 or Extentions.HasWhirlwind(player)) then return end 
    for i = 0, objManager.enemies_n - 1 do
        local target = objManager.enemies[i]
        if target and common.IsValidTarget(target) and target.pos:dist(player.pos) < 450 then 
            if not (player.path.isDashing) then  
                local qpred = pred.linear.get_prediction(Q1, target)
                if qpred and qpred.startPos:dist(qpred.endPos) < Q1.range then
                    player:castSpell("pos", 0, vec3(qpred.endPos.x, target.y, qpred.endPos.y))
                end
            end
            if player.path.isDashing and player.pos:dist(target.pos) < 400 then
                player:castSpell("pos", 0, target.pos)
            end
        end 
    end
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        for i = 0, objManager.enemies_n - 1 do
            local target = objManager.enemies[i]
            if minion and common.IsValidTarget(minion) and target and common.IsValidTarget(target) and minion.pos:dist(minion.pos) < 450 and target.pos:dist(player.pos) > 500 then 

                if player.path.isDashing and player.pos:dist(minion.pos) < 400 then
                    player:castSpell("pos", 0, minion.pos)
                end
            end 
        end
    end
end

return {
    Q1 = Q1,
    Q3 = Q3,
    GetNewQSpeed = GetNewQSpeed, 
    EDelay = EDelay, 
    GetLowestKnockupTime = GetLowestKnockupTime,
    GetKnockedUpTargets = GetKnockedUpTargets, 
    StackQ = StackQ
}