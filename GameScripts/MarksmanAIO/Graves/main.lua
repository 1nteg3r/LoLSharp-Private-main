local orb = module.internal("orb");
local pred = module.internal("pred");
local evade = module.seek('evade');
local common = module.load(header.id, "common");
local TS = module.internal("TS");
local damage = module.load(header.id, 'damageLib');

local pred_q = {
    range = 825,
    delay = 0.25,
    speed = 3000,
    boundingRadiusMod = 0,
    width = 40,
    collision = {
        hero = false,
        minion = false,
        wall = true, 
        terrain = true,
    },
}

local pred_w = {
    range = 915,
    delay = 0.25,
    speed = 1500,
    boundingRadiusMod = 1,
    radius = 225,
    collision = {
        hero = false,
        minion = false,
        wall = true
    },
}

local pred_r = {
    range = 1100,
    delay = 0.25,
    speed = 2100,
    boundingRadiusMod = 0,
    width = 100,
    collision = {
        hero = true,
        minion = false,
        wall = true
    },
}

local r_conel = {
    radius =  (math.pi/180*70),
    delay = 0,
    speed = 2000,
    width = 700,
    boundingRadiusMod = 1,
    collision = { 
        hero = false, 
        minion = false, 
        walls = false 
    };
}

local menu = menu("MarksmanAIOGraves", "Marksman - ".. player.charName)
menu:menu('combo', 'Combo Settings')
menu.combo:menu('qsettings', "Q Settings")
    menu.combo.qsettings:boolean("qcombo", "Use Q", true)
    menu.combo.qsettings:slider("mana_mngr", "Minimum Mana %", 15, 0, 100, 5)
menu.combo:menu('wsettings', "W Settings")
    menu.combo.wsettings:boolean("wcombo", "Use W", true)
    menu.combo.wsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
    menu.combo.wsettings:boolean("EnableInterrupter", "Cast W against interruptible spells", false)
    menu.combo.wsettings:boolean("EnableAntiGapcloser", "Cast W against gapclosers", true)
menu.combo:menu('esettings', "E Settings")
    menu.combo.esettings:boolean("ecombo", "Use E", true)
    menu.combo.esettings:dropdown('modeE', 'Mode E', 1, {'Cursor', 'Side', 'Safe Position'});
    menu.combo.esettings:slider("mana_mngr", "Minimum Mana %", 0, 0, 100, 5)
menu.combo:menu('rsettings', "R Settings")
    menu.combo.rsettings:boolean("rcombo", "Use R", true)
    menu.combo.rsettings:menu("blacklist", "Blacklist!")
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy then 
            menu.combo.rsettings.blacklist:boolean(enemy.charName, "Do not use R on: " .. enemy.charName, false)
        end
    end 
menu:menu('harass', 'Hybrid/Harass Settings')
    menu.harass:menu('qsettings', "Q Settings")
        menu.harass.qsettings:boolean("qharras", "Use Q", true)
        menu.harass.qsettings:slider("mana_mngr", "Minimum Mana %", 75, 0, 100, 5)

menu:menu('lane', 'Lane/Jungle Settings')
        menu.lane:keybind("keyjump", "LaneClear", 'V', nil)
        menu.lane:boolean("useQ", "Use Q", true)
        menu.lane:boolean("useE", "Use E", true)
        menu.lane:slider("mana_mngr", "Minimum Mana %", 45, 0, 100, 5)
menu:header("dsada", "Misc Settings")
       -- menu:keybind("autoe", "Auto E", nil, 'G')
        --menu:keybind("semir", "Semi - R", 'T', nil)
        menu:keybind("keyjump", "Flee", 'Z', nil)
        menu:menu('kill', 'KillSteal Settings')
            menu.kill:boolean("qkill", "Use Q if KillSteal", true)
            menu.kill:boolean("ekill", "Use R if KillSteal", true)
menu:menu("draws", "Drawings")
        menu.draws:boolean("qrange", "Draw Q Range", true)
        menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("wrange", "Draw W Range", false)
        menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("erange", "Draw E Range", false)
        menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("rrange", "Draw R Range", false)
        menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)

local function IsReloading()
    return not player.buff["gravesbasicattackammo1"]
end 

local function GetAmmoCount()
    for i, buff in pairs(player.buff) do
    	if buff and buff.valid and buff.name == 'gravesbasicattackammo2' then
            return buff.stacks
        end
    end
    return 0
end 

local function isInAutoAttackRange(target)
    return player.pos:dist(target.pos) <= common.GetAARange(player) 
end 

local function rTraceFilter(seg, obj)
	if pred.trace.linear.hardlock(pred_r, seg, obj) then
		return true
	end
	if pred.trace.linear.hardlockmove(pred_r, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if pred_r.range < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	if pred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

local function GetMovementBlockedDebuffDuration(target)
    for i, buff in pairs(target.buff) do
        if buff and buff.valid and buff.type == 24 or buff.type == 5 then 
            return (buff.endTime - game.time) * 1000
        end
    end
    return 0
end

local function GetComboDamage(target, allowattack)
    local Samage = 0 
    local allowattack = 1 or allowattack 
    if target and common.IsValidTarget(target) then 
        if player:spellSlot(0).state == 0 then 
            Samage = damage.GetSpellDamage(0, target)
        end 
        if player:spellSlot(1).state == 0 then 
            Samage = damage.GetSpellDamage(1, target)
        end 
        if player:spellSlot(3).state == 0 then 
            Samage = damage.GetSpellDamage(3, target)
        end 
        if isInAutoAttackRange(target) then 
            Samage = common.CalculateAADamage(target) * allowattack
        end
    end 
    return Samage
end 

local function OnDrawing()
    -- body
    if player.isDead and player.buff[17] and not player.isOnScreen then 
        return 
    end 

    if player:spellSlot(0).state == 0 and menu.draws.qrange:get() then 
        graphics.draw_circle(player.pos, pred_q.range, 1, menu.draws['qcolor']:get(), 100)
    end 
    if player:spellSlot(1).state == 0 and menu.draws.wrange:get() then 
        graphics.draw_circle(player.pos, pred_w.range, 1, menu.draws['wcolor']:get(), 100)
    end 
    if player:spellSlot(2).state == 0 and menu.draws.erange:get() then 
        graphics.draw_circle(player.pos, 440, 1, menu.draws['ecolor']:get(), 100)
    end 
    if player:spellSlot(3).state == 0 and menu.draws.rrange:get() then 
        graphics.draw_circle(player.pos, pred_r.range, 1, menu.draws['rcolor']:get(), 100)
    end 
end

local function InAARange(point, target)
    if (orb.combat.is_active()) then
        local targetpos = vec3(target.x, target.y, target.z)
        return common.GetDistance(point, targetpos) < common.GetAARange()
    else 
        return #common.CountEnemiesInRange(point, common.GetAARange()) > 0
    end
end

local function CirclePoints(CircleLineSegmentN, radius, position)
    local points = {}
    for i = 1, CircleLineSegmentN, 1 do
        local angle = i * 2 * math.pi / CircleLineSegmentN
        local point = vec3(position.x + radius * math.cos(angle), position.y + radius * math.sin(angle), position.z);
        table.insert(points, point)
    end 
    return points 
end

local function IsGoodPosition(dashPos)
	local segment = 475 / 5;
	local myHeroPos = vec3(player.x, player.y, player.z)
	for i = 1, 5, 1 do
        local pos = myHeroPos + (dashPos - myHeroPos):norm()  * i * segment
		if navmesh.isWall(pos) and not player.pos:dist(pos) > common.GetAARange() then
			return false
		end
	end

	if common.IsUnderDangerousTower(dashPos) then
		return false
	end

	local enemyCheck = 2 
    local enemyCountDashPos = common.CountEnemiesInRange(dashPos, 600);
    if enemyCheck > #enemyCountDashPos then
    	return true
    end
    local enemyCountPlayer = #common.CountEnemiesInRange(player.pos, 400)
    if #enemyCountDashPos <= enemyCountPlayer then
    	return true
    end
    return false
end

local function CastDash(asap, target)
    asap = asap and asap or false
    local DashMode =  menu.combo.esettings.modeE:get()
    local bestpoint = vec3(0, 0, 0)
    local myHeroPos = vec3(player.x, player.y, player.z)

    if DashMode == 1 then
    	bestpoint = game.mousePos
    end

    if DashMode == 2 then
    	--if (orb.combat.is_active()) then
		    local startpos = vec3(player.x, player.y, player.z)
		    local endpos = vec3(target.x, target.y, target.z)
		    local dir = (endpos - startpos):norm()
		    local pDir = dir:perp1()
		    local rightEndPos = endpos + pDir * common.GetDistance(target)
		    local leftEndPos = endpos - pDir * common.GetDistance(target)
		    local rEndPos = vec3(rightEndPos.x, rightEndPos.y, player.z)
		    local lEndPos = vec3(leftEndPos.x, leftEndPos.y, player.z);
		    if common.GetDistance(game.mousePos, rEndPos) < common.GetDistance(game.mousePos, lEndPos) then
                bestpoint = myHeroPos + (rEndPos - myHeroPos):norm()  * 440
		    else
		        bestpoint = myHeroPos + (lEndPos - myHeroPos):norm()  * 440
		    end
   		--end
  	end

    if DashMode == 3 then
	    local points = CirclePoints(15, 440, myHeroPos)
        bestpoint = myHeroPos + (game.mousePos - myHeroPos):norm()  * 440
        
	    local enemies = #common.CountEnemiesInRange(bestpoint, 440)

	    for i, point in pairs(points) do
		    local count = #common.CountEnemiesInRange(point, 440)
		    if not InAARange(point, target) then
			  	if common.IsUnderAllyTurret(point) then
			        bestpoint = point;
			        enemies = count - 1;
			    elseif count < enemies then
			        enemies = count;
			        bestpoint = point;
			    elseif count == enemies and common.GetDistance(game.mousePos, point) < common.GetDistance(game.mousePos, bestpoint) then
			        enemies = count;
			        bestpoint = point;
			  	end
		    end
		end
  	end

  	if bestpoint == vec3(0, 0, 0) then
    	return vec3(0, 0, 0)
  	end

  	local isGoodPos = IsGoodPosition(bestpoint)

  	if asap and isGoodPos then
    	return bestpoint
  	elseif isGoodPos and InAARange(bestpoint, target) then
    	return bestpoint
  	end
  	return vec3(0, 0, 0)
end

local function Combo()
    if player:spellSlot(0).state == 0 and menu.combo.qsettings.qcombo:get() and common.GetPercentMana(player) >= menu.combo.qsettings.mana_mngr:get() then
        local target = common.GetTarget(pred_q.range)
        if target and target ~= nil and common.IsValidTarget(target) then
            local seg = pred.linear.get_prediction(pred_q, target)
            if seg then
                local SpellendPos = player.pos + (vec3(seg.endPos.x, target.y, seg.endPos.y) - player.pos):norm() * vec3(seg.endPos.x, target.y, seg.endPos.y):dist(player)
                local dir = (target.pos - SpellendPos):norm();
                if (math.abs(dir:dot(SpellendPos)) < 0.01 and not navmesh.isWall(seg.endPos)) then 
                    if not pred.collision.get_prediction(pred_q, seg, target)  then
                        player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                elseif not navmesh.isWall(seg.endPos) and  SpellendPos:dist(player.pos) < 600 then 
                    player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end
            end
        end 
    end
    if player:spellSlot(1).state == 0 and menu.combo.wsettings.wcombo:get() and common.GetPercentMana(player) >= menu.combo.wsettings.mana_mngr:get() then
        local target = TS.get_result(function(res, obj, dist)
            if (dist > pred_w.range or obj.buff["rocketgrab"] or obj.buff["sivire"]or obj.buff["fioraw"]) then
                return
            end
            if obj and common.IsValidTarget(obj) then 
                res.obj = obj
                return true
            end
        end).obj
        if target then 
            if GetMovementBlockedDebuffDuration(target) > 0.5 or target.buff['zhonyasringshield'] or target.buff['bardrstasis']then 
                player:castSpell("pos", 1, target.path.serverPos)
            else 
                local predPos = pred.circular.get_prediction(pred_w, target)
                if predPos and predPos.startPos:dist(predPos.endPos) < pred_w.range then
                    if ((predPos.endPos:dist(target.pos) > 150)) or ((predPos.endPos:dist(target.pos) > 150) and common.IsMovingTowards(target, 500)) then
                        player:castSpell("pos", 1, vec3(predPos.endPos.x, target.y, predPos.endPos.y))
                    end
                end
            end
        end 
    end
    if player:spellSlot(2).state == 0 and menu.combo.esettings.ecombo:get() and common.GetPercentMana(player) >= menu.combo.esettings.mana_mngr:get() and GetAmmoCount() < 1 then
        local target = TS.get_result(function(res, obj, dist)
            if (dist > (common.GetAARange() + 425) or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and common.IsValidTarget(obj) then 
                res.obj = obj
                return true
            end
        end).obj
        if target then 
            local bestpoint = vec3(0, 0, 0)
            local DashMode = menu.combo.esettings.modeE:get()
            if DashMode == 1 then 
                bestpoint = game.mousePos
            end
            if DashMode == 2 then 
                local myHeroPos = vec3(player.x, player.y, player.z)
                    local startpos = vec3(player.x, player.y, player.z)
                    local endpos = vec3(target.x, target.y, target.z)
                    local dir = (endpos - startpos):norm()
                    local pDir = dir:perp1()
                    local rightEndPos = endpos + pDir * common.GetDistance(target)
                    local leftEndPos = endpos - pDir * common.GetDistance(target)
                    local rEndPos = vec3(rightEndPos.x, rightEndPos.y, player.z)
                    local lEndPos = vec3(leftEndPos.x, leftEndPos.y, player.z);
                    if common.GetDistance(game.mousePos, rEndPos) < common.GetDistance(game.mousePos, lEndPos) then
                        bestpoint = myHeroPos + (rEndPos - myHeroPos):norm()  * 150
                    else
                        bestpoint = myHeroPos + (lEndPos - myHeroPos):norm()  * 150
                    end
            end 

            if DashMode == 3 then 
                local points = CirclePoints(15, 440, player.pos)
                bestpoint = player.pos + (game.mousePos - player.pos):norm()  * 440
                
                local enemies = #common.CountEnemiesInRange(bestpoint, 440)
        
                for i, point in pairs(points) do
                    local count = #common.CountEnemiesInRange(point, 440)
                    if not InAARange(point, target) then
                          if common.IsUnderAllyTurret(point) then
                            bestpoint = point;
                            enemies = count - 1;
                        elseif count < enemies then
                            enemies = count;
                            bestpoint = point;
                        elseif count == enemies and common.GetDistance(game.mousePos, point) < common.GetDistance(game.mousePos, bestpoint) then
                            enemies = count;
                            bestpoint = point;
                          end
                    end
                end
                local CastPos = player.pos + (mousePos - player.pos):norm() * 420
                local isGoodPos = IsGoodPosition(CastPos)
                if isGoodPos then 
                    player:castSpell("pos", 2, bestpoint)
                end 
            end 
            if bestpoint ~= vec3(0, 0, 0) then
                player:castSpell("pos", 2, bestpoint)
            end
        end
    end
    if player:spellSlot(3).state == 0 and menu.combo.rsettings.rcombo:get() then 
        local target = common.GetTarget(pred_r.range)
        if target and target ~= nil and common.IsValidTarget(target) then
            --if menu.combo.rsettings.blacklist[target.charName] and not menu.combo.rsettings.blacklist[target.charName]:get() then 
            if player:spellSlot(0).state == 0 and target.pos:dist(player) <= pred_q.range and damage.GetSpellDamage(0, target) > common.GetShieldedHealth("AD", target) then return end 
            if damage.GetSpellDamage(3, target) >= common.GetShieldedHealth("AD", target) then 
                local seg = pred.linear.get_prediction(pred_r, target)
                if seg and seg.startPos:dist(seg.endPos) < pred_r.range  and rTraceFilter(seg, target) then
                    if not pred.collision.get_prediction(pred_r, seg, target) then
                        player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                end
            end 
        end
    end

    if player:spellSlot(3).state == 0 and menu.combo.rsettings.rcombo:get() then 
        local target = common.GetTarget(1700)
        if target and target ~= nil and common.IsValidTarget(target) then
            local seg = pred.linear.get_prediction(r_conel, target)
            if seg and seg.startPos:dist(seg.endPos) >= pred_r.range and player.pos:dist(target.pos) >= 800 and rTraceFilter(seg, target) then
                if damage.GetSpellDamage(3, target) >= common.GetShieldedHealth("AD", target) then 
                    player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end
            end 
        end 
    end
end 

local function Harass()
    if menu.harass.qsettings.qharras:get() and common.GetPercentMana(player) >= menu.harass.qsettings.mana_mngr:get() then 
        if player:spellSlot(0).state == 0 then
            local target = common.GetTarget(pred_q.range)
            if target and target ~= nil and common.IsValidTarget(target) then
                local seg = pred.linear.get_prediction(pred_q, target)
                if seg then
                    local SpellendPos = player.pos + (vec3(seg.endPos.x, target.y, seg.endPos.y) - player.pos):norm() * vec3(seg.endPos.x, target.y, seg.endPos.y):dist(player)
                    local dir = (target.pos - SpellendPos):norm();
                    if (math.abs(dir:dot(SpellendPos)) < 0.01 and not navmesh.isWall(seg.endPos)) then 
                        if not pred.collision.get_prediction(pred_q, seg, target) then
                            player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end 
                    elseif not navmesh.isWall(seg.endPos) and  SpellendPos:dist(player.pos) < 600 then 
                        player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end
            end 
        end
    end 
end 

local function LaneClear()
    local enemyMinions = common.GetMinionsInRange(pred_q.range, TEAM_NEUTRAL)

	for i, minion in pairs(enemyMinions) do
        if minion then
            if common.GetPercentMana(player) >= menu.lane.mana_mngr:get() then 
                if player:spellSlot(0).state == 0 and menu.lane.useQ:get() then 
                    local seg = pred.linear.get_prediction(pred_q, minion)
                    if seg then
                        local SpellendPos = player.pos + (vec3(seg.endPos.x, minion.y, seg.endPos.y) - player.pos):norm() * vec3(seg.endPos.x, minion.y, seg.endPos.y):dist(player)
                        local dir = (minion.pos - SpellendPos):norm();
                        if (math.abs(dir:dot(SpellendPos)) < 0.01 and not navmesh.isWall(vec3(seg.endPos.x, minion.y, seg.endPos.y))) then 
                            if not pred.collision.get_prediction(pred_q, seg, minion) then
                                player:castSpell("pos", 0, vec3(seg.endPos.x, minion.y, seg.endPos.y))
                            end 
                        elseif not navmesh.isWall(vec3(seg.endPos.x, minion.y, seg.endPos.y)) and  SpellendPos:dist(player.pos) < 600 then 
                            player:castSpell("pos", 0, vec3(seg.endPos.x, minion.y, seg.endPos.y))
                        end
                    end
                end 
                if player:spellSlot(2).state == 0 and  menu.lane.useE:get() and GetAmmoCount() < 1 then
                    player:castSpell("pos", 2, mousePos)
                end
            end
        end 
    end
end 
local function OnTick()
    if player.isDead then return end

    if orb.menu.combat.key:get() then
        Combo();
    elseif orb.menu.hybrid.key:get() then
        Harass();
    elseif menu.lane.keyjump:get() then 
        LaneClear();
    end 

    if player:spellSlot(3).state == 0 and menu.kill.ekill:get() then 
        local target = common.GetTarget(pred_r.range)
        if target and target ~= nil and common.IsValidTarget(target) then
        if player:spellSlot(0).state == 0 and target.pos:dist(player) <= pred_q.range and damage.GetSpellDamage(0, target) > common.GetShieldedHealth("AD", target) then return end 
            if damage.GetSpellDamage(3, target) >= common.GetShieldedHealth("AD", target) then 
                local seg = pred.linear.get_prediction(pred_r, target)
                if seg and seg.startPos:dist(seg.endPos) < pred_r.range  and rTraceFilter(seg, target) then
                    if not pred.collision.get_prediction(pred_r, seg, target) then
                        player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end 
                end
            end  
        end
    end
end

local function OnProcessSpell(spell)
    -- body
    if (spell and spell.owner.isMe) then 
        local target = TS.get_result(function(res, obj, dist)
            if (dist > pred_q.range or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and common.IsValidTarget(obj) and common.IsEnemyMortal(obj) then
                res.obj = obj
                return true
            end
        end).obj
        if target and spell.isBasicAttack and (orb.core.is_mode_active(OrbwalkingMode.Combo)) then 
            if player:spellSlot(2).state == 0 and player:spellSlot(3).state == 0 and (player.mana - player.manaCost2 - player.manaCost3 > 0) and #common.CountEnemiesInRange(target.pos, 600) <= 2 and not common.IsUnderDangerousTower(target.pos) then 
                local Damager = GetComboDamage(target, 2) 
                if Damager and Damager >= common.GetShieldedHealth("AD", target) then 
                    local seg = pred.linear.get_prediction(pred_r, target)
                    if seg and seg.startPos:dist(seg.endPos) < pred_r.range and rTraceFilter(seg, target) then
                        if not pred.collision.get_prediction(pred_r, seg, target) then
                            player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.z))
                        end 
                    end
                end 
            end 
        end
    end 

    if spell and spell.owner.isEnemy and spell.name == 'SummonerTeleport'  then 
        if (player:spellSlot(1).state == 0 and (player.mana - player.manaCost1 > player.manaCost2 + player.manaCost3) and menu.combo.wsettings.wcombo:get() and (orb.core.is_mode_active(OrbwalkingMode.Combo))) then 
            if spell.endPos:dist(player.pos) < pred_w.range then 
                player:castSpell("pos", 1, spell.endPos)
            end 
        end 
    end

    if spell.name == "GravesChargeShot" then 
        if player:spellSlot(2).state == 0 then 
            if (mousePos:dist(player.pos) > 440) then 
                local castPos = player.pos + (mousePos - player.pos):norm() * 420
                player:castSpell("pos", 2, castPos)
            else
                player:castSpell("pos", 2, mousePos)
            end
        end
    end  
end


cb.add(cb.draw, OnDrawing)
--
--cb.add(cb.pre_tick, OnPreAttack)
cb.add(cb.tick, OnTick)

--
cb.add(cb.spell, OnProcessSpell)
--cb.add(cb.cast_spell, CastSpell)
--Creat Trap
--cb.add(cb.delete_object, OnDeleObject)
--cb.add(cb.create_object, OnCreateObject)