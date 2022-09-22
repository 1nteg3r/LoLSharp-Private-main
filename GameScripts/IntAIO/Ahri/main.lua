local orb = module.internal("orb");
local evade = module.seek('evade');
local common = module.load(header.id, "Library/common");
local TS = module.load(header.id, "TargetSelector/targetSelector")
local TargetPred = module.internal("TS")
local dlib = module.load(header.id, 'Library/damageLib');
local pred = module.internal("pred")

local Q = {
    MinSpeed = 400,
    MaxSpeed = 2500,
    Acceleration = -3200,
    Speed1 = 1400,
    Delay1 = 0.25,
    Range1 = 880,
    Delay2 = 0,
    Range2 = math.huge,
    IsReturning = false,
    Target = { },
    Object = { },
    LastObjectVector = vec3(0,0,0),
    LastObjectVectorTime = 0,
    CatchPosition = vec3(0,0,0)
}

local E = {
    LastCastTime = 0,
    Objects = { }
}

local R = {
    EndTime = 0
}
--[[
    Range Spells: 

    Q = 880
    W = 700
    E = 975
    R = 450

    Spell name: AhriOrbofDeception Q 
    Speed:1100
    Width: 100
    Time:0.25
    Animation: 1
    false
    CastFrame: 0.23058769106865
    --------------------------------------
    Spell name: AhriSeduce
    Speed:1200
    Width: 60
    Time:0.25
    Animation: 1
    false
    CastFrame: 0.23058769106865
]]

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

local menu = menu("IntnnerAhri", "Int Ahri");
    menu:header("xs", "Core");
    TS = TS(menu, 975)
    TS:addToMenu()
    menu:menu('combo', "Combo");
    menu.combo:boolean('q', 'Use Q', true);
    menu.combo:boolean('w', 'Use W', true);
    menu.combo:header("headE", "E - Setting");
    menu.combo:boolean('e', 'Use E', true);
    for i, enemy in pairs(common.GetEnemyHeroes()) do 
        if enemy then 
            for _, spell in pairs(Interspells) do 
                if enemy and spell then 
                    if spell.Name == enemy.charName then 
                        menu.combo:menu('eset', 'Interrupt Spells - E')
                        if spell.displayer == "" then
                            spell.displayer = _
                        end
                        menu.combo.eset:menu(i, enemy.charName.. ' || '.. _);
                        menu.combo.eset[i]:boolean('inter', "Interrupt Spell: ".. spell.displayname, true);
                    end
                end 
            end 
        end 
    end
    menu.combo:header("headrE", "R - Setting");
    menu.combo:menu("ult", "Ultimate - R");
    menu.combo.ult:boolean('r', 'Use R', true);
    menu.combo.ult:boolean('CatchQR', 'Catch the Q with R', true);
    menu.combo.ult:boolean('withR', 'Give Priority to Catch the Q with R', true);
    --menu.combo.ult:dropdown('mode', 'Mode R', 3, {'Never', 'Always', 'Killable'});
    -->>Harass<<--
    menu:menu("harass", "Harass");
    menu.harass:boolean("q", "Use Q", true);
    menu.harass:boolean("w", "Use W", false);
    menu.harass:boolean("e", "Use E", false);
    menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 25, 0, 100, 1);
    -->>Misc<<--
    menu:menu("misc", "Misc");
    menu.misc:boolean("kil", "Killable", true);
    menu.misc:keybind("under", "Do not use R under turret", nil, "G")
    menu.misc:boolean("catha", "Catch the Q with movement", false);
    menu.misc:boolean("egab", "Use E on gapclose spells", true);
    menu.misc:boolean("channeling", "Use E on channeling spells", true);

    menu:menu("ddd", "Display");
    menu.ddd:boolean("qd", "Q Range", true);
    menu.ddd:boolean("wd", "W Range", false);
    menu.ddd:boolean("ed", "E Range", true);
    menu.ddd:boolean("rd", "R Range", false);

local function ArgsBuff()
    local buff = player.buff;
    if buff and buff[string.lower('ahritumble')] then
        if buff.valid then 
            R.EndTime = game.time + buff.endTime - buff.startTime;
        end
    end
end 

local function AnyWallInBetween(startPos, endPos)
    for i = 0, startPos:dist(endPos) do  
        local Extend = startPos + (endPos - startPos):norm() * i 
        local point = navmesh.isWall(Extend)
        if point then 
            return true 
        end 
    end
    return false
end

local function CastQ(Enemy)
    local maxspeed = Q.MaxSpeed;
    local acc = Q.Acceleration;
    local speed = math.sqrt(math.pow(maxspeed, 2) + 2 * acc * player.pos:dist(Enemy));
    local tf = (speed - maxspeed) / acc;
    Q.Speed = (player.pos:dist(Enemy) / tf);
    local Prediction_Q = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        range = 880,
        delay = 0.25, 
        width = 100, 
        speed = Q.Speed,
        type = 'linear',
        collision = { hero = false, minion = false, wall = true };
    };
    local target = TargetPred.get_result(real_target_filter(Prediction_Q).Result) 
    if target.pos then 
        if player:spellSlot(0).state == 0 then
            player:castSpell("pos", 0, vec3(target.pos.x, mousePos.y, target.pos.y))
        end
    end    
    Q.Target = Enemy.pos;
end 

local function CastW(target)
    if player:spellSlot(1).state == 0 and common.IsValidTarget(target) then 
        if orb.combat.target == target then 
            for i, object in pairs(Q.Object) do 
                if object and orb.combat.target then 
                    if player:spellSlot(1).state == 0 then
                        player:castSpell("self", 1)
                    end
                else 
                    player:castSpell("self", 1)
                end
            end
        end
    end
end

local function CastE(enemy)
    if player:spellSlot(2).state == 0 and common.IsValidTarget(enemy) then 
        local Prediction_E = {
            range = 975,
            delay = 0.25, 
            width = 60, 
            speed = 1200,
            collision = {
                hero = true,
                minion = true,
                wall = true,
            },
            boundingRadiusMod = 1,
            type = 'linear'
        };
        local target = TargetPred.get_result(real_target_filter(Prediction_E).Result) 
        if target.pos then 
            if player:spellSlot(2).state == 0 then
                player:castSpell("pos", 2, vec3(target.pos.x, mousePos.y, target.pos.y))
            end
        end
    end
end

local function GetComboDamage(target, slot)
    local comboDamage = 0;
    local manaWasted = 0;

    if target and common.IsValidTarget(target) then 
        for s = 0, 5 do
            local slot = player:spellSlot(s)
            if slot then
                if slot == 0 then 
                    comboDamage = dlib.GetSpellDamage(0, target);
                    manaWasted = player.manaCost0
                end
                if slot == 2 then 
                    comboDamage = dlib.GetSpellDamage(2, target);
                    manaWasted = player.manaCost2
                end
                if slot == 1 then 
                    comboDamage = dlib.GetSpellDamage(1, target);
                    manaWasted = player.manaCost1
                end
                if slot == 3 then 
                    comboDamage = dlib.GetSpellDamage(3, target);
                    manaWasted = player.manaCost3
                end
            end
        end
    end
    return comboDamage * 10 and manaWasted;
end 

local function GetBestCombo(target)
    if target and common.IsValidTarget(target) then 
        local bestdmg = 0;
        local bestmana = 0;
        local ManaCost = 0;
        for i = 0, 3 do
            local Slot = player:spellSlot(i)
            if Slot then 
                if Slot == 0 then 
                    ManaCost = player.manaCost0
                elseif  Slot == 1 then 
                    ManaCost = player.manaCost1
                elseif  Slot == 2 then
                    ManaCost = player.manaCost2
                elseif  Slot == 3 then 
                    ManaCost = player.manaCost3
                end
                local damageI2 = GetComboDamage(target, Slot);
                if (player.mana >= ManaCost) then
                    if (bestdmg >= common.GetShieldedHealth("AP", target)) then
                        if (damageI2 >= common.GetShieldedHealth("AP", target) and (damageI2 < bestdmg or ManaCost < bestmana)) then
                            bestdmg = damageI2;
                            bestmana = ManaCost;
                        end
                    else
                        if (damageI2 >= bestdmg) then
                            bestdmg = damageI2;
                            bestmana = ManaCost;
                        end
                    end
                end
                damageI2 = GetComboDamage(target, Slot);
            end
        end
        return bestdmg
    end 
end

local function CastR(target)
    if player:spellSlot(3).state == 0 and common.IsValidTarget(target) then 
        local damageI = GetComboDamage(target, 3);
        if (menu.combo.ult.withR:get()) then
            if (R.EndTime > 0) then
                for i, object in pairs(Q.Objects) do 
                    if object then 
                        if (Q.IsReturning and player.pos:dist(object.pos) < player.pos:dist(Q.Target)) then
                            player:castSpell("pos", 3, mousePos)
                        end
                        if (player:spellSlot(0).state ~= 0 and (R.EndTime - game.time <= player:spellSlot(3).cooldown)) then
                            player:castSpell("pos", 3, mousePos)
                        end
                        if ((dlib.GetSpellDamage(3, target) + dlib.GetSpellDamage(2, target) + dlib.GetSpellDamage(1, target)+ dlib.GetSpellDamage(0, target)) >= common.GetShieldedHealth("AP", target) and mousePos:dist(target) < player.pos:dist(target)) then
                            if (player.pos:dist(target) > 400) then
                                player:castSpell("pos", 3, mousePos)
                            end 
                        end
                    end 
                end 
            end
        else
            if (player:spellSlot(0).state ~= 0 and (R.EndTime - game.time <= player:spellSlot(3).cooldown)) then
                player:castSpell("pos", 3, mousePos)
            end
            if ((dlib.GetSpellDamage(3, target) + dlib.GetSpellDamage(2, target) + dlib.GetSpellDamage(1, target)+ dlib.GetSpellDamage(0, target)) >= common.GetShieldedHealth("AP", target) and mousePos:dist(target) < player.pos:dist(target)) then
                if (player.pos:dist(target) > 400) then
                    player:castSpell("pos", 3, mousePos)
                end 
            end
        end
    end 
end

local function Combo()
    local target = TS.target 
    local CastingE = false;
    if target then 
        if menu.combo.ult.r:get() then 
            CastR(target);
        end
        if menu.combo.e:get() then 
            CastE(target);
        end 
        for i, object in pairs(E.Objects) do 
            if object then 
                if ((game.time - E.LastCastTime <= (0.25 / 1000 * 1.1))) or  (object and player.pos:dist(target.pos) > player.pos:dist((object.pos))) then 
                    CastingE = true;
                    if menu.combo.q:get() then 
                        CastQ(target)
                    end 
            
                    if menu.combo.w:get() then 
                        CastW(target)
                    end   
                end 
                CastingE = false;
                --chat.print('eheheh')
            end 
        end 
        if CastingE == false then 
            if menu.combo.q:get() then 
                CastQ(target)
            end 
        end
        if menu.combo.w:get() then 
            CastW(target)
        end
    end
end

local function CatchQ()
    for i, object in pairs(Q.Object) do 
        if object then 
            local target = TS.target 
            if target and target ~= nil then  
                local pred_pos = pred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)

                if not pred_pos then 
                    return 
                end 
                local CastPosition = vec3(pred_pos.x, target.y, pred_pos.y)

                if player.pos:dist(CastPosition) <= player.pos:dist(object) then 

                    local TimeLeft = player.pos:dist(target) * Q.Speed;
                    local qObject = object.pos
                    local ExtendedPos = qObject + (CastPosition - qObject):norm() * 1500;

                    local point = mathf.closest_vec_line_seg(player.pos, qObject, ExtendedPos)
                    local isOnSegment = mathf.closest_vec_line_seg(CastPosition, qObject, player.pos)

                    if point and isOnSegment and point:dist(qObject) < CastPosition:dist(qObject) then 

                        if (point:dist(player) < (player.pos:dist(target) * Q.Speed / player.moveSpeed)) then

                            if menu.misc.catha:get() then 
                                if (isOnSegment:dist(CastPosition) > 100) then 
                                    local ponitexte = qObject + (point - qObject):norm() * 875
                                    player:move(ponitexte)
                                end
                            end 
                        elseif (point:dist(player) < 450 + (player.pos:dist(target) * Q.Speed / player.moveSpeed)) then 
                            if menu.combo.ult.CatchQR:get() and orb.combat.is_active() then 
                                if (isOnSegment:dist(CastPosition) > 100) then 
                                    local ponitexte = qObject + (point - qObject):norm() * 875
                                    local rPos = player.pos + (point - player.pos):norm() * player.pos:dist(ponitexte)
                                    if (player:spellSlot(3).state == 0) then
                                        player:castSpell("pos", 3, rPos)
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

local function Harass()
    local target = TS.target 
    if target then 
        if menu.harass.e:get() then 
            CastE(target);
        end 
        if menu.harass.q:get() then 
            CastQ(target)
        end 
        if menu.harass.w:get() then 
            CastW(target)
        end  
    end
end

local function on_tick()
    if player.isDead then return end 

    ArgsBuff();
    CatchQ();

    if not player.buff[string.lower('ahritumble')] then 
        R.EndTime = 0;
    end 

    for i, object in pairs(Q.Object) do 
        if object then 
            Q.CastDelay = Q.Delay2;
            Q.SourcePosition = object.pos 
            if Q.LastObjectVector then 
                Q.Speed = Q.SourcePosition:dist(Q.LastObjectVector) / (game.time - Q.LastObjectVectorTime);
            end
            Q.LastObjectVector = vec3(Q.SourcePosition.x, Q.SourcePosition.y, Q.SourcePosition.z)
            Q.LastObjectVectorTime = game.time;
        else 
            Q.CastDelay = Q.Delay1
            Q.Speed = Q.Speed1
            Q.SourcePosition = player.pos;
        end
    end   
    
    if (orb.combat.is_active()) then
        Combo()
    end
    if (player.mana / player.maxMana) * 100 >= menu.harass.Mana:get() then 
        if orb.menu.hybrid:get()  then
            Harass();
        end
    end
end 
orb.combat.register_f_pre_tick(on_tick);

local lastDebugPrint = 0
local function on_process_spell(spell)
    for _, spellInt in pairs(Interspells) do 
        if spell and spellInt then 
            if spellInt.Name == spell.owner.charName then 
                if spellInt.spellname == spell.name then
                    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.owner.charName == spellInt.Name then 
                        if spell.owner.pos:dist(player) < 975 then
                            local Prediction_E = {
                                range = 975,
                                delay = 0.25, 
                                width = 60, 
                                speed = 1200,
                                collision = {
                                    hero = true,
                                    minion = true,
                                    wall = true,
                                },
                                boundingRadiusMod = 1,
                                type = 'linear'
                            };
                            local seg = pred.linear.get_prediction(Prediction_E, spell.owner)
                            if seg and seg.startPos:dist(seg.endPos) < 975 then
                                player:castSpell("pos", 2, vec3(seg.endPos.x, spell.owner.y, seg.endPos.y))
                            end
                        end
                    end
                end
            end 
        end 
    end
end 
cb.add(cb.spell, on_process_spell)

local function on_create_missile(obj)
    if obj.spell.owner.type == TYPE_HERO and obj.spell.owner.team == TEAM_ALLY and obj.spell.owner.charName == "Ahri" then 
        if obj.name:lower():find("ahriorbmissile") then
            --chat.print('ahriorbmissile')
            Q.Object[obj.ptr] = obj; 
            Q.IsReturning = false;
        elseif obj.name:lower():find("ahriorbreturn") then
            --chat.print('ahriorbreturn')
            Q.Object[obj.ptr] = obj; 
            Q.IsReturning = true;
        elseif obj.name:lower():find("ahriseducemissile") then
            --chat.print('ahriseducemissile')
            E.Objects[obj.ptr] = obj;
        end
    end
end
cb.add(cb.create_missile, on_create_missile)

local function on_delete_missile(obj)
    if obj then 
        Q.Object[obj.ptr] = nil;
        Q.IsReturning = false
        Q.Target = nil;
        Q.LastObjectVector = vec3(0,0,0);
        E.Objects[obj.ptr] = nil;
    end
end
cb.add(cb.delete_missile, on_delete_missile)

local function OnSpellCastSpell(slot, startpos, endpos, nid)
    if slot == 0 then 
        Q.IsReturning = false;
        Q.Object = { };
    elseif slot == 2 then 
        E.Objects = {};
        E.LastCastTime = game.time;
    end
end 
cb.add(cb.castspell, OnSpellCastSpell)

local function on_draw() 
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.ddd.qd:get()) then 
            graphics.draw_circle(player.pos, 880, 1, graphics.argb(255, 145, 70, 197), 30)
        end
        if (player:spellSlot(1).state == 0 and menu.ddd.wd:get()) then 
            graphics.draw_circle(player.pos, 700, 1, graphics.argb(255, 145, 70, 197), 30)
        end
        if (player:spellSlot(2).state == 0 and menu.ddd.ed:get()) then 
            graphics.draw_circle(player.pos, 975, 1, graphics.argb(255, 145, 70, 197), 30)
        end
        if (player:spellSlot(3).state == 0 and menu.ddd.rd:get()) then 
            graphics.draw_circle(player.pos, 475, 1, graphics.argb(255, 145, 70, 197), 30)
        end
        for i, object in pairs(Q.Object) do 
            if object then 
                local posyou = graphics.world_to_screen(vec3(player.x, player.y, player.z))
                local postwo = graphics.world_to_screen(vec3(object.x, object.y, object.z))
                graphics.draw_circle(object.pos, 150, 1, graphics.argb(255, 255, 255, 255), 30)
                graphics.draw_line_2D(posyou.x, posyou.y, postwo.x, postwo.y, 1, graphics.argb(255, 255, 255, 255))
            end 
        end
        
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.misc.under:get() then
            graphics.draw_text_2D("Use R in UnderTower: On", 17, pos.x - 70, pos.y + 15, graphics.argb(255, 255, 255, 255))
        else
            graphics.draw_text_2D("Use R in UnderTower: Off", 17, pos.x - 70, pos.y + 15, graphics.argb(255, 255, 255, 255))
        end
    end
end 
cb.add(cb.draw, on_draw)

