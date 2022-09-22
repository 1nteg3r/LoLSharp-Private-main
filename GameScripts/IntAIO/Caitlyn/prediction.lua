local common = module.load("int", "Library/common")

function CutWaypoints(Waypoints, distance)
	local result = {}
	local remaining = distance
	if distance > 0 then
		for i = 1, #Waypoints -1 do
			local A, B = Waypoints[i], Waypoints[i + 1]
			if A and B then 
				local dist = GetDistance(A, B)
				if dist >= remaining then
					result[1] = A + remaining * (B - A):norm()
					
					for j = i + 1, #Waypoints do
						result[j - i + 1] = Waypoints[j]
					end
					remaining = 0
					break
				else
					remaining = remaining - dist
				end
			end
		end
	else
		local A, B = Waypoints[1], Waypoints[2]
		result = Waypoints
		result[1] = A - distance * (B - A):norm()
	end
	return result
end

function VectorMovementCollision(startPoint1, endPoint1, v1, startPoint2, v2, delay)
	local sP1x, sP1y, eP1x, eP1y, sP2x, sP2y = startPoint1.x, startPoint1.z, endPoint1.x, endPoint1.z, startPoint2.x, startPoint2.z
	local d, e = eP1x-sP1x, eP1y-sP1y
	local dist, t1, t2 = math.sqrt(d*d+e*e), nil, nil
	local S, K = dist~=0 and v1*d/dist or 0, dist~=0 and v1*e/dist or 0
	local function GetCollisionPoint(t) return t and {x = sP1x+S*t, y = sP1y+K*t} or nil end
	if delay and delay~=0 then sP1x, sP1y = sP1x+S*delay, sP1y+K*delay end
	local r, j = sP2x-sP1x, sP2y-sP1y
	local c = r*r+j*j
	if dist>0 then
		if v1 == math.huge then
			local t = dist/v1
			t1 = v2*t>=0 and t or nil
		elseif v2 == math.huge then
			t1 = 0
		else
			local a, b = S*S+K*K-v2*v2, -r*S-j*K
			if a==0 then 
				if b==0 then --c=0->t variable
					t1 = c==0 and 0 or nil
				else --2*b*t+c=0
					local t = -c/(2*b)
					t1 = v2*t>=0 and t or nil
				end
			else --a*t*t+2*b*t+c=0
				local sqr = b*b-a*c
				if sqr>=0 then
					local nom = math.sqrt(sqr)
					local t = (-nom-b)/a
					t1 = v2*t>=0 and t or nil
					t = (nom-b)/a
					t2 = v2*t>=0 and t or nil
				end
			end
		end
	elseif dist==0 then
		t1 = 0
	end
	return t1, GetCollisionPoint(t1), t2, GetCollisionPoint(t2), dist
end


function GetCurrentWayPoints(object)
	local result = {}
	if object.path.isActive then
		table.insert(result, vec3(object.pos.x, object.pos.y, object.pos.z))
		for i = object.path.index, object.path.count do
			local pathPos = object.path.point[i]
			table.insert(result, vec3(pathPos.x, pathPos.y, pathPos.z))
		end
	else
		table.insert(result, object and vec3(object.pos.x, object.pos.y, object.pos.z) or vec3(object.pos.x, object.pos.y, object.pos.z))
	end
	return result
end
function GetDistanceSqr(p1, p2)
	return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

function GetDistance(p1, p2)
	return math.sqrt(GetDistanceSqr(p1, p2))
end

function GetWaypointsLength(Waypoints)
	local result = 0
	for i = 1, #Waypoints -1 do
		result = result + GetDistance(Waypoints[i], Waypoints[i + 1])
	end
	return result
end

function CanMove(unit, delay)
	if not unit then 
		return 
	end
    for i, buff in pairs(unit.buff) do
		if buff then
			if (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11) then
				return false -- block everything
			end
		end
	end
	return true
end

function IsImmobile(unit, delay, radius, speed, from, spelltype)
	local ExtraDelay = speed == math.huge and 0 or (from and unit and unit.pos and (GetDistance(from, unit.pos) / speed))
	if (CanMove(unit, delay + ExtraDelay) == false) then
		return true
	end
	return false
end

function CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)
	local Waypoints = {}
	local Position, CastPosition = vec3(unit.x, unit.y, unit.z), vec3(unit.x, unit.y, unit.z)
	local t
	
	Waypoints = GetCurrentWayPoints(unit)
	local Waypointslength = GetWaypointsLength(Waypoints)
	local movementspeed = unit.path.isDashing and unit.path.dashSpeed or unit.moveSpeed
	if #Waypoints == 1 then
		Position, CastPosition = vec3(Waypoints[1].x, Waypoints[1].y, Waypoints[1].z), vec3(Waypoints[1].x, Waypoints[1].y, Waypoints[1].z)
		return Position, CastPosition
	elseif (Waypointslength - delay * movementspeed + radius) >= 0 then
		local tA = 0
		Waypoints = CutWaypoints(Waypoints, delay * movementspeed - radius)
		
		if speed ~= math.huge then
			for i = 1, #Waypoints - 1 do
				local A, B = Waypoints[i], Waypoints[i+1]
				if i == #Waypoints - 1 then
					B = B + radius * (B - A):norm()
				end
				
				local t1, p1, t2, p2, D = VectorMovementCollision(A, B, movementspeed, vec3(from.x,from.y,from.z), speed)
				local tB = tA + D / movementspeed
				t1, t2 = (t1 and tA <= t1 and t1 <= (tB - tA)) and t1 or nil, (t2 and tA <= t2 and t2 <= (tB - tA)) and t2 or nil
				t = t1 and t2 and math.min(t1, t2) or t1 or t2
				if t then
					CastPosition = t==t1 and vec3(p1.x, 0, p1.y) or vec3(p2.x, 0, p2.y)
					break
				end
				tA = tB
			end
		else
			t = 0
			CastPosition = vec3(Waypoints[1].x, Waypoints[1].y, Waypoints[1].z)
		end
		
		if t then
			if (GetWaypointsLength(Waypoints) - t * movementspeed - radius) >= 0 then
				Waypoints = CutWaypoints(Waypoints, radius + t * movementspeed)
				Position = vec3(Waypoints[1].x, Waypoints[1].y, Waypoints[1].z)
			else
				Position = CastPosition
			end
		elseif unit.type ~= player.type then
			CastPosition = vec3(Waypoints[#Waypoints].x, Waypoints[#Waypoints].y, Waypoints[#Waypoints].z)
			Position = CastPosition
		end
		
	elseif unit.type ~= player.type then
		CastPosition = vec3(Waypoints[#Waypoints].x, Waypoints[#Waypoints].y, Waypoints[#Waypoints].z)
		Position = CastPosition
	end
	
	return Position, CastPosition
end

function VectorPointProjectionOnLineSegment(v1, v2, v)
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end


function CheckCol(unit, minion, Position, delay, radius, range, speed, from)
	if unit.networkID == minion.networkID then 
		return false
	end
	
	local waypoints = GetCurrentWayPoints(minion)
	local MPos, CastPosition = #waypoints == 1 and minion.pos or CalculateTargetPosition(minion, delay, radius, speed, from, "line")
	
	if from and MPos and GetDistanceSqr(from, MPos) <= (range)^2 and GetDistanceSqr(from, minion.pos) <= (range + 100)^2 then
		local buffer = (#waypoints > 1) and 8 or 0 
		
		if minion.type == player.type then
			buffer = buffer + minion.boundingRadius
		end
		
		if #waypoints > 1 then
			local proj1, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(from, Position, MPos)
			if proj1 and isOnSegment and (GetDistanceSqr(MPos, proj1) <= (minion.boundingRadius + radius + buffer) ^ 2) then
				return true
			end
		end
		
		local proj2, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(from, Position, minion.pos)
		if proj2 and isOnSegment and (GetDistanceSqr(minion.pos, proj2) <= (minion.boundingRadius + radius + buffer) ^ 2) then
			return true
		end
	end
end

function CheckMinionCollision(unit, Position, delay, radius, range, colison, argsColision, speed, from)
	Position = vec3(Position.x, Position.y, Position.z)
	from = from and vec3(from.x, from.y, from.z) or player.pos
    local result = false
    if colison then
        for i, colType in pairs(argsColision) do
			for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
				local minion = objManager.minions[TEAM_ENEMY][i]
				if minion then
					if colType == 0 and CheckCol(unit, minion, Position, delay, radius, range, speed, from) then
						return true
					end
				end
            end
			for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
				local minion = objManager.minions[TEAM_NEUTRAL][i]
				if minion then
					if colType == 0 and CheckCol(unit, minion, Position, delay, radius, range, speed, from) then
						return true
					end
				end
            end
            local enemy = common.GetEnemyHeroes()
			for i, minion in ipairs(enemy) do
				if minion then
					if colType == 1 and minion.team ~= player.team and CheckCol(unit, minion, Position, delay, radius, range, speed, from) then
						return true
					end
				end
            end
        end
    end
        
	return false
end

function isSlowed(unit, delay, speed, from)
    for i, buff in pairs(unit.buff) do
		if from and unit and buff and buff.stacks > 0 and buff.startTime >= (delay + GetDistance(unit.pos, from) / speed) then
			if (buff.type == 10) then
				return true
			end
		end
	end
	return false
end

function GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = delay + GetDistance(startPos, endPos) / speed
	return interceptTime
end

function TryGetBuff(unit, buffname)	
    for i, buff in pairs(unit.buff) do
		if buff.name == buffname and buff.startTime > 0 then
			return buff, true
		end
	end
	return nil, false
end

function HasBuff(unit, buffname,D,s)
	local D = D or 1 
	local s = s or 1 
    for i, Buff in pairs(unit.buff) do
		if Buff.name == buffname and Buff.stacks > 0 and game.time + D/s < Buff.endTime then
			return true
		end
	end
	return false
end

--Used to find target that is currently in stasis so we can hit them with spells as soon as it ends
--Note: This has not been fully tested yet... It should be close to right though
function GetStasisTarget(source, range, delay, speed, timingAccuracy)
	local target	
    for h = 0, objManager.enemies_n - 1 do
        local t = objManager.enemies[h]
		local buff, success = TryGetBuff(t, "zhonyasringshield")
		if success and buff then
			if GetDistance(source, t) <= range then	
				local deltaInterceptTime = GetSpellInterceptTime(player.pos, t.pos, delay, speed) - buff.endTime
				if deltaInterceptTime > - network.latency / 2000 and deltaInterceptTime < timingAccuracy then
					target = t
					return target
				end
			end
		end
	end
end

--Used to cast spells onto targets that are dashing. 
--Can target enemies that are dashing into range. Does not currently account for dashes which render the user un-targetable though.
function GetInteruptTarget(source, range, delay, speed, timingAccuracy)
	local target	
    for h = 0, objManager.enemies_n - 1 do
        local t = objManager.enemies[h]
		if t and t.path.isActive and t.path.isDashing and t.path.dashSpeed > 500  then
			local dashEndPosition = t.path.point[1]
			if GetDistance(source, dashEndPosition) <= range then				
				--The dash ends within range of our skill. We now need to find if our spell can connect with them very close to the time their dash will end
				local dashTimeRemaining = GetDistance(t.pos, dashEndPosition) / t.path.dashSpeed
				local skillInterceptTime = GetSpellInterceptTime(player.pos, dashEndPosition, delay, speed)
				local deltaInterceptTime = math.abs(skillInterceptTime - dashTimeRemaining)
				if deltaInterceptTime < timingAccuracy then
					target = t
					return target
				end
			end			
		end
	end
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


function GetBestCastPosition(unit, delay, radius, range, speed, from, collision, argsColision, spelltype, timeThreshold)
	assert(unit, " Target can't be nil")
	local pred
    pred = pred or module.internal("pred")
	
	if not timeThreshold then
		timeThreshold = .35
	end	
	range = range and range - 4 or math.huge
	radius = radius == 0 and 1 or radius - 4
	speed = speed and speed or math.huge
	
	if not from then
		from = player.pos
	end
	local IsFromMyHero = GetDistanceSqr(from, player.pos) < 50*50 and true or false
	
	delay = delay + (0.07 + network.latency / 2000)
	
	local Position, CastPosition = CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)
	local HitChance = 1
	local Waypoints = GetCurrentWayPoints(unit)
	if (#Waypoints == 1) then
		HitChance = 2
	end

	
	if GetDistance(player.pos, unit.pos) < 250 then
		HitChance = 2
		Position, CastPosition = CalculateTargetPosition(unit, delay*0.5, radius, speed*2, from, spelltype)
		Position = CastPosition
    end
	local tempAngle = mathf.angle_between(from.pos:to2D(), unit.pos:to2D(), CastPosition)
    if tempAngle > 60 then
		HitChance = 1
	elseif tempAngle < 10 then
		HitChance = 2
	end
  
	if (unit.activeSpell) then
		HitChance = 2
		local timeToAvoid = radius / unit.moveSpeed +  unit.activeSpell.animationTime + unit.activeSpell.windUpTime - game.time
		local timeToIntercept = GetSpellInterceptTime(from, unit.pos, delay, speed)
		local deltaInterceptTime = timeToIntercept - timeToAvoid		
		if deltaInterceptTime < timeThreshold then
			HitChance = 4
			CastPosition = unit.pos
		end		
	end

	local buff, success = TryGetBuff(unit, "zhonyasringshield")
	if success and buff then
		if GetDistance(unit, from) <= range then	
			local deltaInterceptTime = GetSpellInterceptTime(from.pos, unit.pos, delay, speed) - buff.endTime
			local timingAccuracy = from.pos:dist(unit.pos)
			if deltaInterceptTime > - network.latency / 2000 and deltaInterceptTime < timingAccuracy then
				if deltaInterceptTime < timeThreshold then
					HitChance = 5
					CastPosition = unit.pos
				end
			end 
		end
	end
	
	if (IsImmobile(unit, delay, radius, speed, from, spelltype)) then
		HitChance = 5
		CastPosition = unit.pos
	end
	
	--[[Out of range]]
	if IsFromMyHero then
		if (spelltype == "line" and GetDistanceSqr(from, Position) >= range * range) then
			HitChance = 0
		end
		if (spelltype == "circular" and (GetDistanceSqr(from, Position) >= (range + radius)^2)) then
			HitChance = 0
		end
		if from and Position and (GetDistanceSqr(from, Position) > range ^ 2) then
			HitChance = 0
		end
	end
	radius = radius*2
	
	if collision and HitChance > 0 then
		if collision and CheckMinionCollision(unit, unit.pos, delay, radius, range, collision, argsColision, speed, from) then
			HitChance = -1
		elseif CheckMinionCollision(unit, Position, delay, radius, range, collision, argsColision, speed, from) then
			HitChance = -1
		elseif CheckMinionCollision(unit, CastPosition, delay, radius, range, collision, argsColision, speed, from) then
			HitChance = -1
		end
	end
	if not CastPosition or not Position then
		HitChance = -1
	end
	return CastPosition, HitChance, Position
end


return {
	GetBestCastPosition = GetBestCastPosition,
	CheckMinionCollision = CheckMinionCollision,
}