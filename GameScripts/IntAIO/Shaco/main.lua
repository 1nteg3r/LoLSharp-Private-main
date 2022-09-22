local orb = module.internal("orb");
local evade = module.seek('evade');
local common = module.load("int", "Library/util");
local TS = module.load("int", "TargetSelector/targetSelector");
local TargetTed = module.internal("TS")
local pred = module.internal('pred');
local dlib = module.load('int', 'Library/damageLib');

--[[
    Q = new Spell.Targeted(SpellSlot.Q, 400);
    W = new Spell.Skillshot(SpellSlot.W, 425, SkillShotType.Circular);
    E = new Spell.Targeted(SpellSlot.E, 625);
    R = new Spell.Targeted(SpellSlot.R, 400);
    R = new Spell.Targeted(SpellSlot.R, 2200);
    R2 = new Spell.Active(SpellSlot.R);
]]
local RangeTarget = 0
local TargetedCC = {
    "TristanaR", "BlindMonkRKick", "AlZaharNetherGrasp", "VayneCondemn", "JayceThunderingBlow", "Headbutt",
    "Drain", "BlindingDart", "RunePrison", "IceBlast", "Dazzle", "Fling", "MaokaiUnstableGrowth",
    "MordekaiserChildrenOfTheGrave", "ZedUlt", "LuluW", "PantheonW", "ViR", "JudicatorReckoning",
    "IreliaEquilibriumStrike", "InfiniteDuress", "SkarnerImpale", "SowTheWind", "PuncturingTaunt",
    "UrgotSwap2", "NasusW", "VolibearW", "Feast", "NocturneUnspeakableHorror", "Terrify", "VeigarPrimordialBurst"
}

local CloneTroy = { }

local menu = menu("int", "Int Shaco");
menu:header("xs", "Core");
TS = TS(menu, 635)
TS:addToMenu()
menu:menu('combo', "Combo");
menu.combo:boolean('q', 'Use Q', true);
menu.combo:boolean('useQ', '^ Out range', true);
menu.combo:boolean('w', 'Use W', true);
menu.combo:boolean('e', 'Use E', true);
menu.combo:header("headrE", "R - Setting");
menu.combo:menu("ult", "Ultimate - R");
menu.combo.ult:keybind("keyactive", "Key || R", nil, "R")
menu.combo.ult:boolean('r', 'Use R - Combo', true); --Use R when Low
menu.combo.ult:boolean('lowr', 'Use R when "HP" Low', true); 
menu.combo.ult:boolean('blckspell', 'Block spells in stealth', true); 
menu.combo.ult:slider("helath", "Min. Health < {0}", 30, 1, 100, 1);
menu.combo.ult:header("headrR", "Clone - Setting");
menu.combo.ult:boolean('clonemover', 'Clone Mover', true);
menu.combo.ult:boolean('cloneattack', 'Clone Attack', true);
-->>Harass<<--
menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", false);
menu.harass:boolean("w", "Use W", false);
menu.harass:boolean("e", "Use E", true);
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 25, 0, 100, 1);
-->>LaneClear<<--
menu:menu("clear", "JungleClear");
menu.clear:boolean("w", "Use W", true);
menu.clear:boolean("e", "Use E", true);
menu.clear:slider("Mana", "Minimum Mana Percent >= {0}", 45, 1, 100, 1);
-->>Misc<<--
menu:menu("misc", "Misc");
menu.misc:boolean("egab", "Killable", true);
menu.misc:menu("evade", "Evade");
menu.misc.evade:boolean("useE", "Use Evade", true);
menu.misc.evade:boolean("doglecc", "Dodge targeted cc", true);

menu:menu("ddd", "Display");
menu.ddd:boolean("qd", "Q Range", false);
menu.ddd:boolean("wd", "W Range", false);
menu.ddd:boolean("ed", "E Range", true);

local IsFacing = function(target)
	return player.path.serverPos:distSqr(target.path.serverPos) >
		player.path.serverPos:distSqr(target.path.serverPos + target.direction)
end

local enemyHeroes
local function GetTurrentEnemy()
    if enemyHeroes then
        return enemyHeroes
    end
    enemyHeroes = {}
    for i= 1, objManager.turrets.size[TEAM_ENEMY]-1 do
        local tower = objManager.turrets[TEAM_ENEMY][i]
        enemyHeroes[#enemyHeroes + 1] = tower
    end
    return enemyHeroes
end
 
local function Distance(p1, p2)
    local dx, dy = p2.x - p1.x, p2.z - p1.z
    return math.sqrt(dx * dx + dy * dy)
end

local function GetWaypoints(unit) 
    local waypoints = {}
    local pathData = unit.path
    table.insert(waypoints, unit.pos)
    if pathData.isActive and pathData.count > 0 then
        for i = pathData.index, pathData.count do
            table.insert(waypoints, unit.path.point[i])
        end
    end
    return waypoints
end

local function GetUnitPositionAfterTime(unit, time)
    local waypoints = GetWaypoints(unit)
    if #waypoints == 1 then
        return unit.pos -- we have only 1 waypoint which means that unit is not moving, return his position
    end
    local max = unit.moveSpeed * time -- calculate arrival distance
    for i = 1, #waypoints - 1 do
        local a, b = waypoints[i], waypoints[i + 1]
        local dist = Distance(a, b)
        if dist >= max then
            return a + (b - a):norm() * dist ---- Extended(b, dist) -- distance of segment is bigger or equal to maximum distance, so the result is point A extended by point B over calculated distance
        end
        max = max - dist -- reduce maximum distance and check next segments
    end
    return waypoints[#waypoints] -- all segments have been checked, so the final result is the last waypoint
end

local function CastW(target, from, toObject)
    if player:spellSlot(1).state ~= 0 then return end
    from = from or player.pos
    local positions; 
    for i = 0, 11, 1 do 
        positions = from.pos + (toObject - from.pos):norm() * (42 * i)
    end 
    if not navmesh.isWall(positions) and positions:dist(player.pos) < 425 and positions:dist(target.pos) > 350 then
        player:castSpell('pos', 1, positions)
    end
end

--[[local function CloneCreate()
    for i = 0, objManager.maxObjects-1 do
        local obj = objManager.get(i)
        if obj  then
            if (obj.team == TEAM_ALLY) and (obj.type == TYPE_MINION) and not obj.isDead then
                if (obj.name == player.name and obj.charName == 'Shaco') then 
                    CloneTroy[obj.ptr] = ({
                        ptr = obj.ptr,
                        pos = obj.pos,
                        isValidClose = common.IsValidTarget(obj),
                        isMove = obj.path.isActive,
                        isDashing = obj.path.isDashing,
                    })
                end
            end
        end
    end
end ]]

local function CheckWalls(target)
    local step = player.pos:dist(target) / 15
    for i = 0, 16, 1 do
        local CheckIsWall = player.pos + (target - player.pos):norm() * (step * i)
        if navmesh.isWall(CheckIsWall) then 
            return true
        end 
    end
    return false
end 

local function Combo()
    local target = TS.target 

    if target then 
        if menu.combo.ult.clonemover:get() then 
            if player:spellSlot(3).name == 'HallucinateGuide' then 
                player:castSpell('obj', 3, target)
            end
        end
        if menu.combo.w:get() then 
            local Estrutc = GetTurrentEnemy();
            for i, tower in pairs(Estrutc) do 
                if tower and not tower.isDead and tower.health > 0 and tower.pos:dist(target.pos) < 3000 then
                    CastW(target, player, tower.pos)
                else 
                    if (target.path.isActive) then
                        local PositionTarget = GetUnitPositionAfterTime(target, target.moveSpeed*0.25)
                        local unitPos = vec3(PositionTarget.x, target.y, PositionTarget.y);
                        if PositionTarget then 
                            CastW(target, target, PositionTarget)
                        end
                    else 
                        local castW = player.pos + (target.pos - player.pos):norm() * (425)
                        if castW then
                            player:castSpell('pos', 1, castW)
                        end
                    end
                end
            end
        end
        if menu.combo.q:get() then 
            if player:spellSlot(0).state == 0 then
                local PositionTarget = GetUnitPositionAfterTime(target, target.moveSpeed*0.25)
                if not CheckWalls(PositionTarget) and PositionTarget:dist(player) < (400 + player.moveSpeed * 2.5) then 
                    local PlayerPositionPos = player.pos + (target.pos - player.pos):norm() * 400
                    player:castSpell('pos', 0, PlayerPositionPos)
                end
            end
            if menu.combo.useQ:get() and player:spellSlot(0).state == 0 then 
                local target = TargetTed.get_result(function(res, obj, dist)
                    if dist < 800 then
                        res.obj = obj
                        return true
                    end
                end).obj
                if target then 
                    player:castSpell('pos', 0, target.pos)
                end
            end
        end
        if menu.combo.e:get() then 
            if player:spellSlot(2).state == 0 then
                if not player.buff['deceive'] and player.pos:dist(target) < 625 then 
                    player:castSpell('obj', 2, target)
                elseif player:spellSlot(1).state ~= 0 and player.buff['deceive'] then 
                    if player.pos:dist(target) <= common.GetAARange() + target.boundingRadius then 
                        player:castSpell('obj', 2, target)
                    end
                end
            end
        end
        if menu.combo.ult.r:get() then 
            if player:spellSlot(3).state == 0 and  player:spellSlot(3).name ~= 'HallucinateGuide' then
                if common.GetPercentHealth(target) < 60 and (dlib.GetSpellDamage(3, target)+dlib.GetSpellDamage(2, target)) > common.getShieldedHealth("AD", target) and 
                    common.GetPercentHealth(target) > (dlib.GetSpellDamage(3, target)+dlib.GetSpellDamage(2, target)) and common.GetPercentHealth(target) > 25 then 
                        player:castSpell('self', 3)
                end
            end
            if menu.combo.ult.lowr:get() and player:spellSlot(3).state == 0 and  player:spellSlot(3).name ~= 'HallucinateGuide' then
                if common.GetPercentHealth(player) < menu.combo.ult.helath:get() then 
                    player:castSpell('self', 3)
                end
            end
        end
    end
end 

local function KillAble()
    for i, target in pairs(common.getEnemyHeroes()) do 
        if target and common.IsValidTarget(target) then 
            if player:spellSlot(2).state == 0 and player.pos:dist(target) < 625 then
                if dlib.GetSpellDamage(2, target) >  common.getShieldedHealth("AD", target) then 
                    player:castSpell('obj', 2, target)
                end
            end
        end  
    end
end 

local function Harass()
    local target = TS.target 

    if target then 
        if menu.harass.w:get() then 
            local Estrutc = GetTurrentEnemy();
            for i, tower in pairs(Estrutc) do 
                if tower and not tower.isDead and tower.health > 0 and tower.pos:dist(target.pos) < 3000 then
                    CastW(target, player, tower.pos)
                else 
                    if (target.path.isActive) then
                        local pred_pos = pred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)
                        local unitPos = vec3(pred_pos.x, target.y, pred_pos.y);
                        if unitPos then 
                            CastW(target, target, unitPos)
                        end
                    else 
                        local castW = player.pos + (target.pos - player.pos):norm() * (425)
                        if castW then
                            player:castSpell('pos', 1, castW)
                        end
                    end
                end
            end
        end
        if menu.harass.q:get() then 
            if player:spellSlot(0).state == 0 then
                local PositionTarget = GetUnitPositionAfterTime(target, target.moveSpeed*0.25)
                if not CheckWalls(PositionTarget) and PositionTarget:dist(player) < (400 + player.moveSpeed * 2.5) then 
                    local PlayerPositionPos = player.pos + (target.pos - player.pos):norm() * 400
                    player:castSpell('pos', 0, PlayerPositionPos)
                end
            end
        end
        if menu.harass.e:get() then 
            if player:spellSlot(2).state == 0 then
                if not player.buff['deceive'] and player.pos:dist(target) < 625 then 
                    player:castSpell('obj', 2, target)
                elseif player:spellSlot(1).state ~= 0 and player.buff['deceive'] then 
                    if player.pos:dist(target) <= common.GetAARange() + target.boundingRadius then 
                        player:castSpell('obj', 2, target)
                    end
                elseif player:spellSlot(1).state ~= 0 and player.buff['deceive'] then 
                    if player.pos:dist(target) < 600 then
                        player:castSpell('obj', 2, target)
                    end
                end
            end
        end
    end
end 

local function JungleClear()
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local minion = objManager.minions[TEAM_NEUTRAL][i]
        if minion and minion.isVisible and minion.isTargetable and not minion.isDead and common.IsValidTarget(minion) then
            if menu.clear.w:get() and minion.pos:dist(player) < 425 then 
                local castW = player.pos + (minion.pos - player.pos):norm() * (425)
                if castW then
                    player:castSpell('pos', 1, minion.pos )
                end
            end
            if menu.clear.e:get() and minion.pos:dist(player) < 625  then 
                if dlib.GetSpellDamage(2, minion) > minion.health then 
                    player:castSpell('obj', 2, minion)
                elseif minion.charName == "SRU_Razorbeak" or minion.charName == "SRU_Red" or minion.charName == "SRU_Krug" or minion.charName == "SRU_Murkwolf" or minion.charName == "SRU_Blue" or minion.charName == "SRU_Gromp"  then 
                    player:castSpell('obj', 2, minion)
                end
            end
        end 
    end
end 

local function on_tick()
    if player.isDead then return end
    --CloneCreate();
    KillAble();

    if (orb.menu.combat:get()) then
        Combo();
    end

    if (orb.menu.hybrid:get()) then
        if (player.mana / player.maxMana) * 100 > menu.harass.Mana:get() then 
            Harass();
        end
    end

    if (orb.menu.lane_clear:get()) then 
        if (player.mana / player.maxMana) * 100 >= menu.clear.Mana:get() then 
            JungleClear();
        end
    end
end 

local function on_process_spell(spell)
    --[[if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then  
        local spellName = spell.name or string.lower(spell.name);
        if (spell.name == "CurseofTheSadMummy") then
            if (player.pos:dist(spell.owner.pos) <= 600) then
                if player:spellSlot(3).state == 0 and player:spellSlot(3).name ~= 'HallucinateGuide' then
                    player:castSpell('self', 3)
                end
            end
        end 
        if (IsFacing(spell.owner) and (spellName == "EzrealR" or spellName == "rivenizunablade" or
            spellName == "EzrealQ" or spellName == "JinxR" or spellName == "sejuaniglacialprison")) then
            if (player.pos:dist(spell.endPos) <= player.boundingRadius * 2) then
                if player:spellSlot(3).state == 0 and player:spellSlot(3).name ~= 'HallucinateGuide' then
                    player:castSpell('self', 3)
                end
            end
        end
        if (spellName == "InfernalGuardian" or spellName == "UFSlash" or (spellName == "RivenW" and common.GetPercentHealth(player) < 25)) then
            if (player.pos:dist(spell.endPos) <= 270) then
                if player:spellSlot(3).state == 0 and player:spellSlot(3).name ~= 'HallucinateGuide' then
                    player:castSpell('self', 3)
                end
            end
        end 
        if (spellName == "BlindMonkRKick" or spellName == "SyndraR" or spellName == "VeigarPrimordialBurst" or spellName == "AlZaharNetherGrasp" or spellName == "LissandraR") then
            if spell.target and spell.target == player then
                if player:spellSlot(3).state == 0 and player:spellSlot(3).name ~= 'HallucinateGuide' then
                    player:castSpell('self', 3)
                end
            end
        end
        if (spellName == "TristanaR" or spellName == "ViR") then
            if spell.target and spell.target == player and player.pos:dist(spell.owner.pos) < 100 then
                if player:spellSlot(3).state == 0 and player:spellSlot(3).name ~= 'HallucinateGuide' then
                    player:castSpell('self', 3)
                end
            end
        end
        if (spellName == "GalioIdolOfDurand") then
            if (player.pos:dist(spell.owner.pos) <= 600) then
                if player:spellSlot(3).state == 0 and player:spellSlot(3).name ~= 'HallucinateGuide' then
                    player:castSpell('self', 3)
                end
            end
        end 
    
        if (spell.target and spell.target == player) then
            if (TargetedCC[spellName] and spellName ~= "NasusW" and spellName ~= "ZedUlt") then
                if player:spellSlot(3).state == 0 and player:spellSlot(3).name ~= 'HallucinateGuide' then
                    player:castSpell('self', 3)
                end
            end
        end
    end]]
end

--[[local function OnDeleteMinion(obj)
    if obj then
        for i, missile in pairs(CloneTroy) do
            if missile then
                CloneTroy[obj.ptr] = nil
            end
        end
    end
end]]

local function onDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.ddd.qd:get()) then 
            graphics.draw_circle(player.pos, 400, 1, graphics.argb(255, 145, 255, 197), 30)
        end
        if (player:spellSlot(1).state == 0 and menu.ddd.wd:get()) then 
            graphics.draw_circle(player.pos, 425, 1, graphics.argb(255, 145, 255, 197), 30)
        end
        if (player:spellSlot(2).state == 0 and menu.ddd.ed:get()) then 
            graphics.draw_circle(player.pos, 625, 1, graphics.argb(255, 145, 255, 197), 30)
        end
    end
end

orb.combat.register_f_pre_tick(on_tick);
cb.add(cb.draw, onDraw);
--cb.add(cb.delete_minion, OnDeleteMinion);
cb.add(cb.spell, on_process_spell);