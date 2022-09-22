local pred = module.internal('pred')
local Turret={}

for i = 0 , objManager.maxObjects - 1 do 
	local obj = objManager.get(i)
	if obj and obj.name:lower():find("turret") and obj.team ~= player.team then 
		Turret[#Turret+1] = obj
	end
end

local delayedActions, delayedActionsExecuter = {}, nil
local DelayAction=function(func, delay, args) --delay in seconds
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

		cb.add(cb.tick,delayedActionsExecuter)
       
    end
    local t = game.time + (delay or 0)
    if delayedActions[t] then
        delayedActions[t][#delayedActions[t] + 1] = { func = func, args = args }
    else
        delayedActions[t] = { { func = func, args = args } }
    end
end
local CountEnemiesInQ=function(delay,Radius, speed, startPos, endPos, Cmp)
	local input = {
		  delay = delay,
		  speed = speed,
		  width = Radius,
		  boundingRadiusMod = 0,
		  collision = {
			hero = true,
			minion = true,
		  },
	}
	local seg={}
	seg.startPos=vec2(startPos.x,startPos.z)
	seg.endPos=vec2(endPos.x,endPos.y)
	if seg.startPos and seg.endPos then
	local res=pred.collision.get_prediction(input, seg, Cmp)
	if res then
		return true
	end
	end
	return false
end
local CircleCircleIntersection=function(unit, source)
	local D = unit.pos:dist(source.pos)
	local A = (D * D) / (2 * D)/2
	local H = math.sqrt(800*800 + A * A)
	local Direction = (source.pos - unit.pos):norm()
	local PA = unit - A * Direction
	local S1 = PA + H * Direction:perp1()
	local S2 = PA - H * Direction:perp1()	
	return S1,S2
end
local CountEnemiesInQ2=function(delay,Radius, speed, startPos, endPos, Cmp)
	local input = {
		  delay = delay,
		  speed = speed,
		  width = Radius,
		  boundingRadiusMod = 0,
		  collision = {
			hero = true,
			minion = true,
		  },
	}
	local seg={}
	seg.startPos=vec2(startPos.x,startPos.z)
	seg.endPos=vec2(endPos.x,endPos.y)
	if seg.startPos and seg.endPos then
	local res=pred.collision.get_prediction(input, seg , Cmp)
	local count=0
	if res then
			for i=1,#res do
			local obj=res[i]
				if obj and obj.pos:distSqr(Cmp)>(150-obj.boundingRadius)^2 then
					return true
				end
			end
	end
	end
	return false
end

local QKDmg=function(target)
	if player:spellSlot(0).level == 0 then return 0 end  
	local multi = {18,30,33,37,42,46,52,58,65,72,80,88,97,106,117,127,138,150}
	local Qlv=player:spellSlot(0).level
	local ap = player.flatMagicDamageMod

	local Defense = 100/(100+target.spellBlock)
	local damage = ((multi[Qlv]+Qlv*30+ap*0.66)  * Defense) 
	return damage 
end
local QDmg=function(target)
	if player:spellSlot(0).level == 0 then return 0 end  
	local multi = {18,30,33,37,42,46,52,58,65,72,80,88,97,106,117,127,138,150}
	local Qlv=player:spellSlot(0).level
	local ap = player.flatMagicDamageMod

	local Defense = 100/(100+target.spellBlock)
	local damage = ((multi[Qlv]+Qlv*30+ap*0.66) * 2.5 * Defense) 
	return damage 
end

local EDmg=function(target)
	if player:spellSlot(2).level == 0 then return 0 end  
	
	local multi = {60, 100, 140, 180, 220}
	local Elv=player:spellSlot(2).level
	local ap = player.flatMagicDamageMod

	local Defense = 100/(100+target.spellBlock)

	local damage = ((multi[Elv]+ap*0.4)* Defense) 
	
	return damage
	
end


local UnderTurret=function(unit)
	if not unit or unit.isDead or not unit.isVisible or not unit.isTargetable then return true end
	for i = 1, #Turret do
		local obj=Turret[i]
		if obj and obj.health and obj.health>0 and obj.pos:distSqr(unit.pos)<=900^2 then
		return true
		end
	end
	return false
end

local CountEnemiesNear=function(source,range)
local count=0
for i = 0 , objManager.enemies_n - 1 do
		local obj = objManager.enemies[i]
		if obj and not obj.isDead and obj.isTargetable and obj.isVisible and obj.team ~= player.team and obj.pos:distSqr(source)<range^2 then
		count=count+1
		end
end
return count
end



local isValid=function(unit)
	if not unit.isDead and unit.isTargetable and not unit.buff[17] and not unit.buff['FioraW'] and unit.isVisible then
		return true
	end
end
local WardName=function(unit)
	local Cmp = {"ward","trink","trap","spear","device", "room", "box", "plant","poo","barrel"}
	for i = 1, #Cmp do
		if unit and unit.name:lower():find(Cmp[i]) then
		return true
		end
	end
end
return {
	QDmg = QDmg,
	QKDmg = QKDmg,
	EDmg = EDmg,
	CountEnemiesNear = CountEnemiesNear,
	UnderTurret = UnderTurret,
	DelayAction=DelayAction,
	isValid=isValid,
	WardName=WardName,
	CountEnemiesInQ2=CountEnemiesInQ2,
	CountEnemiesInQ=CountEnemiesInQ,
	CircleCircleIntersection=CircleCircleIntersection,
}