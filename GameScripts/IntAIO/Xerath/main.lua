local orb = module.internal("orb");
local evade = module.seek('evade');
local TargetPred = module.internal("TS")
local pred = module.internal("pred")
local common = module.load(header.id, "Library/common");
local TS = module.load(header.id, "TargetSelector/targetSelector")
local damage = module.load(header.id, 'Library/damageLib');

local IsPreAttack = false; 
local LastPing = 0
local RCastTime = 0
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

    if pred.trace.newpath(obj, 0.033, 0.500) then
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

local Interspells = { --ty Deftsu
    ["CaitlynAceintheHole"]         = {Name = "Caitlyn",      displayname = "R | Ace in the Hole", spellname = "CaitlynAceintheHole"},
    ["Crowstorm"]                   = {Name = "FiddleSticks", displayname = "R | Crowstorm", spellname = "Crowstorm"},
    ["DrainChannel"]                = {Name = "FiddleSticks", displayname = "W | Drain", spellname = "DrainChannel"},
    ["GalioIdolOfDurand"]           = {Name = "Galio",        displayname = "R | Idol of Durand", spellname = "GalioIdolOfDurand"},
    ["ReapTheWhirlwind"]            = {Name = "Janna",        displayname = "R | Monsoon", spellname = "ReapTheWhirlwind"},
    ["KarthusFallenOne"]            = {Name = "Karthus",      displayname = "R | Requiem", spellname = "KarthusFallenOne"},
    ["KatarinaR"]                   = {Name = "Katarina",     displayname = "R | Death Lotus", spellname = "KatarinaR"},
    ["LucianR"]                     = {Name = "Lucian",       displayname = "R | The Culling", spellname = "LucianR"},
    ["AlZaharNetherGrasp"]          = {Name = "Malzahar",     displayname = "R | Nether Grasp", spellname = "AlZaharNetherGrasp"},
    ["Meditate"]                    = {Name = "MasterYi",     displayname = "W | Meditate", spellname = "Meditate"},
    ["MissFortuneBulletTime"]       = {Name = "MissFortune",  displayname = "R | Bullet Time", spellname = "MissFortuneBulletTime"},
    ["AbsoluteZero"]                = {Name = "Nunu",         displayname = "R | Absoulte Zero", spellname = "AbsoluteZero"},
    ["PantheonRJump"]               = {Name = "Pantheon",     displayname = "R | Jump", spellname = "PantheonRJump"},
    ["PantheonRFall"]               = {Name = "Pantheon",     displayname = "R | Fall", spellname = "PantheonRFall"},
    ["ShenStandUnited"]             = {Name = "Shen",         displayname = "R | Stand United", spellname = "ShenStandUnited"},
    ["Destiny"]                     = {Name = "TwistedFate",  displayname = "R | Destiny", spellname = "Destiny"},
    ["UrgotSwap2"]                  = {Name = "Urgot",        displayname = "R | Hyper-Kinetic Position Reverser", spellname = "UrgotSwap2"},
    ["VarusQ"]                      = {Name = "Varus",        displayname = "Q | Piercing Arrow", spellname = "VarusQ"},
    ["VelkozR"]                     = {Name = "Velkoz",       displayname = "R | Lifeform Disintegration Ray", spellname = "VelkozR"},
    ["InfiniteDuress"]              = {Name = "Warwick",      displayname = "R | Infinite Duress", spellname = "InfiniteDuress"},
    ["XerathLocusOfPower2"]         = {Name = "Xerath",       displayname = "R | Rite of the Arcane", spellname = "XerathLocusOfPower2"}
}

local menu = menu("IntnnerXerath", "Int - Xerath")
menu:header('a1', 'Core')
TS = TS(menu, 1400)
TS:addToMenu()
menu:menu('combo', 'Combo')
    menu.combo:boolean('Q', 'Use Q', true)
    menu.combo:boolean('W', 'Use W', true)
    menu.combo:boolean('E', 'Use E', true)
    menu.combo:boolean('R', 'Use R', false)
    menu.combo:header("izi", 'Advanced features:')
    menu.combo:slider("extrarange", "Extra range for Q", 200, 1, 200, 1);

menu:menu("ult", "Ultimate");
    menu.ult:dropdown('moder', 'Use R', 3, {'Smart', 'Obvious', 'Near Mouse', 'Automatic'});
    menu.ult:boolean('Onlyaa', "Only attack if it's killable", false);
    menu.ult:slider("Delay", "Delay between R's (in ms)", 0, 0, 1500, 1);
    menu.ult:header('A2', 'Near Mouse Settings')
    menu.ult:boolean('NearMouse.Enabled', "Only select target near mouse", false);
    menu.ult:slider("NearMouse.Radius", "Near mouse radius", 500, 100, 1500, 100);
    menu.ult:boolean('NearMouse.Draw', "Draw near mouse radius", true);

menu:menu("harass", "Harass");
    menu.harass:boolean("q", "Use Q", true);
    menu.harass:boolean("w", "Use W", false);
    menu.harass:boolean("e", "Use E", false);
    menu.harass:slider("extrarange", "Extra range for Q", 200, 1, 200, 1);
    menu.harass:slider("mana", "Minimum Mana Percent", 20, 0, 100, 1);

menu:menu("lane", "Clear");
    menu.lane:menu("laneclear", "LaneClear");
    menu.lane.laneclear:boolean("q", "Use Q", false);
    menu.lane.laneclear:boolean("w", "Use W", true);
        menu.lane.laneclear:slider("LaneClear.Q", "Use Q if hit is greater than", 3, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.W", "Use W if hit is greater than", 4, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 30, 0, 100, 1);
    menu.lane:menu("jungle", "JungleClear");
    menu.lane.jungle:boolean("q", "Use Q", true);
    menu.lane.jungle:boolean("w", "Use W", true);
    menu.lane.jungle:boolean("e", "Use E", true);
    menu.lane.jungle:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 50, 0, 100, 1);

menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useW', 'Use W for KillSteal', true)
    menu.kill:boolean('useE', 'Use E for KillSteal', true)

menu:menu('auto', 'Automatic')
    menu.auto:boolean("E.Gapcloser", "Use E on hero gapclosing", true);
    menu.auto:boolean("W.Gapcloser", "Use W on hero gapclosing", true);
    menu.auto:boolean("Imobile", "Use E on hero immobile", true);

menu:menu('misc', "Misc")
    menu.misc:boolean("miscAlerter", "Altert in Ping when someone is killable with R", true);
    for i, enemy in pairs(common.GetEnemyHeroes()) do 
        if enemy then 
            for _, spell in pairs(Interspells) do 
                if enemy and spell then 
                    if spell.Name == enemy.charName then 
                        menu.misc:menu('eset', 'Interrupt Spells - E')
                        if spell.displayer == "" then
                            spell.displayer = _
                        end
                        menu.misc.eset:menu(i, enemy.charName.. ' || '.. _);
                        menu.misc.eset[i]:boolean('inter', "Interrupt Spell: ".. spell.displayname, true);
                    end
                end 
            end 
        end 
    end

menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 30, 105, 191)
    menu.draws:boolean("wrange", "Draw W Range", true)
    menu.draws:color("wcolor", "W Drawing Color", 255, 30, 105, 191)
    menu.draws:boolean("erange", "Draw E Range", false)
    menu.draws:color("ecolor", "E Drawing Color", 255, 30, 105, 191)
    menu.draws:boolean("rrange", "Draw R Range (MiniMap)", true)
    menu.draws:color("rcolor", "R Drawing Color", 255, 30, 105, 191)
    menu.draws:header("izi", 'Advanced features:')
    menu.draws:boolean("damageoverlay", "Healthbar overlay", true)
    menu.draws:boolean("percent", "Damage percent info", true)

local Q = {
    LastCastTime = 0;
    Range = 0;
    CastRangeGrowthMin = 750;
    CastRangeGrowthMax = 1500;
    CastRangeGrowthStartTime = 0;
    CastRangeGrowthDuration = 1.5;
    CastRangeGrowthEndTime = 3;

    pred_input = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        delay = 0.6,
        speed = 3000,
        width = 100,
        range = 1500,
        collision = { hero = false, minion = false, wall = false },
    };
}

local W = {
    LastCastTime = 0;
    CastRadiusSecondary = 250;
    CastRadius = 100;  

    pred_input = {
        boundingRadiusModSource = 0,
        boundingRadiusMod = 0,
        delay = 0.5,
        speed = math.huge,
        width = 150,
        range = 1000,
        collision = { hero = false, minion = false, wall = false },
    };
}

local E = {
    LastCastTime = 0;
    Missile = { };
    MissileName = "xerathmagespearmissile";

    pred_input = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        delay = 0,
        speed = 1400,
        width = 120,
        range = 1125,
        collision = { hero = true, minion = true, wall = true },
    };
}

local R = {
    LastCastTime = 0;
    Stack = 0;
    rSupporterText = { };

    
    pred_input = {
        boundingRadiusModSource = 0,
        boundingRadiusMod = 0,
        delay = 0.85,
        speed = math.huge,
        width = 190,
        range = 5000,
        collision = { hero = true, minion = true, wall = true },
    };
}

local function IsValidMissile()
    local obj = nil 
    for i, Object in pairs(E.Missile) do
        if Object then 
            obj = Object
        end 
    end
    return obj
end 

local HasPassive = function()
    return player.buff[string.lower('XerathAscended2OnHit')]
end

local IsChargingQ = function()
    return common.getBuffValid(player, 'XerathArcanopulseChargeUp')
end

local IsCastingR = function()
    return common.getBuffValid(player, 'XerathLocusOfPower2')
end

local function OnProcessSpell(spell)
    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Xerath" then 
        ---print("Spell name: " ..spell.name);
        if spell.name == "XerathArcanopulseChargeUp" then 
            Q.LastCastTime = game.time;
        end
        if spell.name == "XerathArcaneBarrage2" then 
            W.LastCastTime = game.time;
        end
        if spell.name == "XerathMageSpear" then 
            E.LastCastTime = game.time;
        end 

        if spell.name == "XerathLocusOfPower2" then 
            R.Stack = ({3, 4, 5})[player:spellSlot(3).level]
        end 
        if spell.name == "XerathLocusPulse" then 
            R.LastCastTime = os.clock() + 0.85;
            R.Stack  = R.Stack -1
        end 
    end
end 
cb.add(cb.spell, OnProcessSpell)

local function CastQ()
    local target = TargetPred.get_result(real_target_filter(Q.pred_input).Result) 
    
    if not target.obj then 
        return 
    end 

    if target.obj and target.pos and player:spellSlot(0).state == 0 then  


        local Object = IsValidMissile()

        if Object and player.pos:dist(Object.pos) <= player.pos:dist(target.obj) then 
            return 
        end



        if IsChargingQ() then 

            local CastPosition = vec3(target.pos.x, mousePos.y, target.pos.y)
            local TargetPosition = (CastPosition + menu.combo.extrarange:get() * (CastPosition - player.pos):norm())
            if common.IsInRange(Q.Range, TargetPosition, player) then
                player:castSpell('release', 0, CastPosition)
            end 

        else 
            player:castSpell('pos', 0, target.obj.pos)
        end 


    end

end

local function CastW()
    local target = TargetPred.get_result(real_target_filter(W.pred_input).Result) 
    
    if not target.obj then 
        return 
    end 

    if target.obj and target.pos and player:spellSlot(1).state == 0 then  


        local Object = IsValidMissile()

        if Object and player.pos:dist(Object.pos) <= player.pos:dist(target.obj) then 
            return 
        end



        if player:spellSlot(1).state == 0 then
            player:castSpell("pos", 1, vec3(target.pos.x, mousePos.y, target.pos.y))
        end

    end 

end 

local function CastE()
 local target = TargetPred.get_result(real_target_filter(E.pred_input).Result) 
    
    if not target.obj then 
        return 
    end 

    if target.obj and target.pos and player:spellSlot(2).state == 0 then  


        local Object = IsValidMissile()

        if Object and player.pos:dist(Object.pos) <= player.pos:dist(target.obj) then 
            return 
        end



        if player:spellSlot(2).state == 0 then
            player:castSpell("pos", 2, vec3(target.pos.x, mousePos.y, target.pos.y))
        end
        
    end 

end

local function Combo()
    if (game.time - W.LastCastTime < 0.75 + 0.5) then 
        return 
    end
    if (game.time - E.LastCastTime < 0.25 + 0.5) then 
        return 
    end

    if menu.combo.E:get() then 
        if IsCastingR() then 
            return 
        end 

        CastE()
    end

    if menu.combo.W:get() then 

        if IsCastingR() then 
            return 
        end 

        CastW()
    end
    
    if menu.combo.Q:get() then

        if IsCastingR() then 
            return 
        end 

        CastQ()
    end 
end 

local function Harass()
    if common.GetPercentMana(player) >= menu.harass.mana:get() then 
        local Weppepr = TS.target

        if not Weppepr then 
            return 
        end 

        if Weppepr and Weppepr ~= nil then 

            if (game.time - W.LastCastTime < 0.75 + 0.5) then 
                return 
            end
            if (game.time - E.LastCastTime < 0.25 + 0.5) then 
                return 
            end

            local Object = IsValidMissile()

            if Object and player.pos:dist(Object) <= player.pos:dist(Weppepr) then 
                return 
            end

            if (IsPreAttack or orb.core.can_attack()) and HasPassive() and player.pos:dist(Weppepr.pos) <= common.GetAARange(player) then 
                return
            end

            if menu.harass.e:get() then 

                if IsCastingR() then 
                    return 
                end 

                local target = TargetPred.get_result(real_target_filter(E.pred_input).Result) 
                if target.pos then  
                    if player:spellSlot(2).state == 0 then
                        player:castSpell("pos", 2, vec3(target.pos.x, mousePos.y, target.pos.y))
                    end
                end 
            end
            
            if menu.harass.w:get() then 

                if IsCastingR() then 
                    return 
                end 

                local target = TargetPred.get_result(real_target_filter(W.pred_input).Result) 
                if target.pos then  
                    if player:spellSlot(1).state == 0 then
                        player:castSpell("pos", 1, vec3(target.pos.x, mousePos.y, target.pos.y))
                    end
                end 


            end

            if menu.harass.q:get() then

                if IsCastingR() then 
                    return 
                end 

                local target = TargetPred.get_result(real_target_filter(Q.pred_input).Result) 
                if target.obj and target.pos and player:spellSlot(0).state == 0  then  

                    if (IsChargingQ()) then 
                        if target.obj.pos:dist(player.pos) + 150 < Q.Range or (target.obj.pos:dist(player.pos) < 750 and Q.Range <= 750) then
                            player:castSpell("release", 0, vec3(target.pos.x, mousePos.y, target.pos.y))
                        end
                    else 
                        player:castSpell("pos", 0, mousePos)
                    end 

                end
            end 
        end
    end
end

local function LaneClear()
    if common.GetPercentMana(player) >= menu.lane.laneclear['LaneClear.ManaPercent']:get() then 

        if menu.lane.laneclear.q:get() then 
            local valid = {}
            local minions = objManager.minions
            for i = 0, minions.size[TEAM_ENEMY] - 1 do

                local minion = minions[TEAM_ENEMY][i]
                if minion and not minion.isDead and minion.isVisible then
                    local dist = player.path.serverPos:distSqr(minion.path.serverPos)
                    if dist <= 1638400 then
                        valid[#valid + 1] = minion
                    end
                end
            end
            local max_count, cast_pos = 0, nil
            for i = 1, #valid do

                local minion_a = valid[i]
                local current_pos = player.path.serverPos + ((minion_a.path.serverPos - player.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos) + 1300))
                local hit_count = 1
                for j = 1, #valid do
                    if j ~= i then
                        local minion_b = valid[j]
                        local point = mathf.closest_vec_line(minion_b.path.serverPos, player.path.serverPos, current_pos)
                        if point and point:dist(minion_b.path.serverPos) < (89 + minion_b.boundingRadius) then
                            hit_count = hit_count + 1
                        end
                    end
                end
                if not cast_pos or hit_count > max_count then
                    cast_pos, max_count = current_pos, hit_count
                end
                if cast_pos and max_count >= menu.lane.laneclear['LaneClear.Q']:get() then
                    if IsChargingQ() then 

                        if cast_pos:dist(player.pos) < Q.Range or (cast_pos:dist(player.pos) < 750 and Q.Range <= 750) then
                            player:castSpell('release', 0, cast_pos)
                        end 
            
                    else 
                        player:castSpell('pos', 0, mousePos)
                    end 

                end
            end
        end

        if menu.lane.laneclear.w:get() then 

            for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
                local minion1 = objManager.minions[TEAM_ENEMY][i]
                if minion1 and common.IsValidTarget(minion1) then 


                    local count = 0
                    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
                        local minion = objManager.minions[TEAM_ENEMY][i]
                        if minion  and minion1 ~= minion and minion.pos:dist(player) <= 750 and common.GetDistance(minion, minion1) < 290 then
                            count = count + 1
                        end
                    end

                    if count >= menu.lane.laneclear['LaneClear.W']:get() then
                        player:castSpell('pos', 1, minion1.pos)
                    end
                end 
            end
        end 

    end
end 

local function JungleClear()
    if common.GetPercentMana(player) >= menu.lane.jungle['LaneClear.ManaPercent']:get() then 
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] -1 do 
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if minion and common.IsValidTarget(minion) then 

                if menu.lane.jungle.q:get() then 
                    if IsChargingQ() then 

                        if minion.pos:dist(player.pos) + 150 < Q.Range or (minion.pos:dist(player.pos) < 750 and Q.Range <= 750 + 150) then
                            player:castSpell('release', 0, minion.pos)
                        end 
            
                    else 
                        player:castSpell('pos', 0, minion.pos)
                    end 
            
                end 

                if menu.lane.jungle.w:get() then 
                    if minion.pos:dist(player.pos) < 1000 then 
                        player:castSpell('pos', 1, minion.pos)
                    end
                end 
        
                if menu.lane.jungle.e:get() then 
                    if minion.pos:dist(player.pos) < 1000 then 
                        player:castSpell('pos', 2, minion.pos)
                    end
                end 

            end 
        end
    end
end 

local function IsGabcloser()
    if IsCastingR() then 
        return 
    end
    local target = TargetPred.get_result(function(res, obj, dist)
        if dist <= 1125 and obj.path.isActive and obj.path.isDashing then 
            res.obj = obj
            return true
        end
    end).obj
    if target and common.IsValidTarget(target) then
        local pathStartPos = target.path.point[0]
        local pathEndPos = target.path.point[target.path.count] 
        if player.pos:dist(pathStartPos) > player.pos:dist(pathEndPos) then 
            if menu.auto['E.Gapcloser']:get() and player.pos:dist(pathEndPos) <= 1125 then 
                player:castSpell('pos', 2, pathEndPos)
            end 
        end 
        if menu.auto['W.Gapcloser']:get() and player.pos:dist(pathEndPos) <= 1125 then 
            player:castSpell('pos', 1, pathEndPos)
        end 
    end
end 

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) and common.IsEnemyMortal(enemies) then
            local DamageQ = damage.GetSpellDamage(0, enemies)
            local Hp_hero = common.GetShieldedHealth("AP", enemies)

            if menu.kill.useQ:get() and player:spellSlot(0).state == 0 then 
                if (DamageQ > Hp_hero) then 
                    CastQ(enemies)
                end 
            end 

            if menu.kill.useW:get() and player:spellSlot(1).state == 0 then 
                if (damage.GetSpellDamage(1, enemies) > Hp_hero) then 
                    CastW(enemies)
                end 
            end
        end 
    end
end

local function CastR()
    local target = TargetPred.get_result(real_target_filter(R.pred_input).Result) 

    if (game.time - W.LastCastTime < 0.75) then 
        return 
    end
    if (game.time - E.LastCastTime < 0.25) then 
        return 
    end
    
    if not target.obj then 
        return 
    end 

    if IsChargingQ() then 
        return 
    end 

    if menu.combo.R:get() and player:spellSlot(3).name == "XerathLocusOfPower2" then 

        if player:spellSlot(3).state ~= 0 then  
            return 
        end

        if #common.CountEnemiesInRange(player.pos, 900) > 0 then 
            return 
        end 

        if target.obj.pos:distSqr(player.pos) < 5000 then 
            if (damage.GetSpellDamage(3, target.obj, 2) > common.GetShieldedHealth("AP", target.obj)) then 
                player:castSpell("self", 3)
            end 
        end 
    end 

    if target.obj and target.pos and player:spellSlot(3).name ~= "XerathLocusOfPower2" then  
        if (damage.GetSpellDamage(3, target.obj, 2) > common.GetShieldedHealth("AP", target.obj)) then 
            if player:spellSlot(3).state == 0 and os.clock() - R.LastCastTime > 0 then
                player:castSpell("pos", 3, vec3(target.pos.x, mousePos.y, target.pos.y))
            end
        else 
            if player:spellSlot(3).state == 0 and os.clock() - R.LastCastTime > 0 and (menu.ult['NearMouse.Enabled']:get() and mousePos:dist(target.obj.pos) <= menu.ult['NearMouse.Radius']:get()) then
                player:castSpell("pos", 3, vec3(target.pos.x, mousePos.y, target.pos.y))
            else 
                if player:spellSlot(3).state == 0 and os.clock() - R.LastCastTime > 0 then
                    player:castSpell("pos", 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                end
            end
        end
    end 
end

local function OnTick()
    if (player.isDead and not player.isTargetable and  player.buff[17]) then return end 

    KillSteal()
    IsGabcloser()
    IsPreAttack = false;
    --Q Rset Time
    if (player:spellSlot(0).state ~= 0) then 
        Q.LastCastTime = 0
    end
    --W Rset Time
    if (player:spellSlot(1).state ~= 0) then 
        W.LastCastTime = 0
    end
    --E Rset Time
    if (player:spellSlot(2).state ~= 0) then 
        E.LastCastTime = 0
    end
    --R Rset Time
    if (player:spellSlot(3).state ~= 0 and not player:spellSlot(3).name == "XerathLocusPulse") then 
        R.LastCastTime = 0
        R.Stack = 0
    end

    if (IsChargingQ()) then 
        local percentGrowth = math.max(0, math.min(1, (1000 * (game.time - Q.LastCastTime) / 1000 - Q.CastRangeGrowthStartTime) / Q.CastRangeGrowthDuration));
        Q.Range = ((Q.CastRangeGrowthMax - Q.CastRangeGrowthMin) * percentGrowth + Q.CastRangeGrowthMin);
    else 
        Q.Range = Q.CastRangeGrowthMax;
    end
    if (IsChargingQ()) then 
        if (evade) then
            evade.core.set_pause(math.huge)
        end
        orb.core.set_pause_attack(math.huge)
    else 
        if (evade) then
            evade.core.set_pause(0)
        end
        orb.core.set_pause_attack(0)
    end  

    CastR()

    if (IsCastingR()) then 
        if (evade) then
            evade.core.set_pause(math.huge)
        end
        orb.core.set_pause_move(math.huge)
        orb.core.set_pause_attack(math.huge)
    else 
        if (evade) then
            evade.core.set_pause(0)
        end
        orb.core.set_pause_move(0)
        orb.core.set_pause_attack(0) 
    end


    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    elseif orb.menu.lane_clear.key:get() then 
        LaneClear()
        JungleClear()
    end

    if menu.misc.miscAlerter:get() and player:spellSlot(3).state == 0 and (os.clock() - LastPing > 30) then 
        local enemy = common.GetEnemyHeroes()
        for i, enemies in ipairs(enemy) do
            if enemies and common.IsValidTarget(enemies) and common.IsEnemyMortal(enemies) then
                if player.pos:dist(enemies.pos) <= 5000 and (damage.GetSpellDamage(3, enemies) * ({3, 4, 5})[player:spellSlot(3).level]) >= common.GetShieldedHealth("AP", enemies) then 
                    for i = 1, 3 do
                    common.DelayAction(function() ping.send(enemies.pos, ping.ALERT, enemies) end,  1000 * 0.3 * i/1000, {enemies.x, enemies.z})
                    end
                    LastPing = os.clock()
                end 
            end 
        end
    end 
end 
cb.add(cb.tick, OnTick)

local function OnPreTick() 
    if (player.isDead and not player.isTargetable and  player.buff[17]) then return end 

    IsPreAttack = true;
end 
cb.add(cb.pre_tick, OnPreTick)

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, Q.Range, 1, menu.draws.qcolor:get(), 100)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 1000, 1, menu.draws.wcolor:get(), 40)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 1125, 1, menu.draws.ecolor:get(), 40)
        end
        
    end

    if (menu.draws.rrange:get() and player:spellSlot(3).state == 0) and not IsCastingR() then
        minimap.draw_circle(player.pos, 5000, 1, menu.draws.rcolor:get(), 100)
    end
    
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and common.IsValidTarget(target) and common.IsEnemyMortal(target) then
            if target.isVisible and not target.isDead then
                local pos = graphics.world_to_screen(target.pos)
                graphics.draw_line_2D(pos.x, pos.y - 30, pos.x + 30, pos.y - 80, 1, graphics.argb(255, 150, 255, 200))
                graphics.draw_line_2D(pos.x + 30, pos.y - 80, pos.x + 50, pos.y - 80, 1, graphics.argb(255, 150, 255, 200))
                graphics.draw_line_2D(pos.x + 50, pos.y - 85, pos.x + 50, pos.y - 75, 1, graphics.argb(255, 150, 255, 200))
                if math.floor((damage.GetSpellDamage(3, target, 2)) / target.health * 100) < 100 then
                    graphics.draw_text_2D("(" .. tostring(math.floor((damage.GetSpellDamage(3, target, 2))/ target.health * 100)) .. "%)" .. "Almost there", 20, pos.x + 55, pos.y - 80, graphics.argb(255, 150, 255, 200))
                else 
                    graphics.draw_text_2D("(" .. "100" .. "%)" .. "Kill", 20, pos.x + 55, pos.y - 80, graphics.argb(255, 255, 0, 0))
                end
            end
        end 
    end
end 
cb.add(cb.draw, OnDraw)

local function on_create_missile(missile)
    if missile then 
        if missile.name == "XerathMageSpearMissile" then 
            E.Missile[missile.ptr] = missile
        end 
    end
end 
cb.add(cb.create_missile, on_create_missile)

local function on_delete_missile(missile)
    if missile then 
        E.Missile[missile.ptr] = nil
    end 
end
cb.add(cb.delete_missile, on_delete_missile)