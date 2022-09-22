local orb = module.internal("orb");
local evade = module.seek('evade');
local TS = module.internal("TS")
local gpred = module.internal("pred")

local common = module.load(header.id, "Library/common");
local dlib = module.load(header.id, 'Library/damageLib');

local LastETick = 0
local pred_w = {
    width = (math.pi/180*70),
    delay = 0.25,
    speed = 1750,
    range = 650,
    boundingRadiusMod = 1,
    angle = (math.pi/180*70),
    collision = { 
        hero = true, 
        minion = true, 
        walls = true 
    };
}

local menu = menu("IntnnerCamille", "Int - Camille")
menu:menu("combo", "Combo Settings")
    menu.combo:menu('qsettings', "Q Settings")
        menu.combo.qsettings:boolean("qcombo", "Use Q1", true)
        menu.combo.qsettings:boolean("q2", "Use Q2", true)
    menu.combo:menu('wsettings', "W Settings")
        menu.combo.wsettings:boolean('smartW', "Smart W", true)
    menu.combo:menu('esettings', "E Settings")
        menu.combo.esettings:boolean("ecombo", "Use E in Wall", true)
        menu.combo.esettings:boolean("egab", "Use E2", true)
        menu.combo.esettings:dropdown('modegab', 'E2 Mode:', 2, {'Follow Mouse', 'Target'});
    menu.combo:menu('rsettings', "R Settings")
            menu.combo.rsettings:boolean("rcombo", "Use R", true)
            menu.combo.rsettings:dropdown('modegab', 'R Mode:', 2, {'Combo', 'KillSteal'});
            menu.combo.rsettings:header('Another', "Misc Settings")
            menu.combo.rsettings:slider("MinTargetsR", "Use R Min. Targets", 2, 1, 5, 1);
            menu.combo.rsettings:boolean("killsteal", "Use R if KillSteal", true)
            menu.combo.rsettings:menu("blacklist", "Blacklist!")
            for l, enemy in pairs(common.GetEnemyHeroes()) do
                if enemy then
                    menu.combo.rsettings.blacklist:boolean(enemy.charName, "Do not use R on: " .. enemy.charName, false)
                end
            end
menu:menu("harass", "Hybrid/Harass Settings")
    menu.harass:menu('qsettings', "Q Settings")
    menu.harass.qsettings:boolean("qharass", "Use Q1", true)
    menu.harass.qsettings:boolean("q2harass", "Use Q2", true)
menu:menu("clear", "Lane Clear Settings")
    menu.clear:menu('qsettings', "Q Settings")
        menu.clear.qsettings:boolean("qclear", "Use Q", true)
        menu.clear.qsettings:boolean("q3clear", "Use Q3 ", false)
        menu.clear.qsettings:boolean("qlast", "Use Q LastHit", true)
        menu.clear.qsettings:slider("minlife", "Min. Mana >= {0}", 45, 1, 100, 1);
menu:header("xd", "Misc Settings")
menu:keybind("keyjump", "Flee", 'Z', nil)
menu:menu("draws", "Drawings")
    menu.draws:boolean("q_range", "Draw Q Range", true)
    menu.draws:color("q", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("w_range", "Draw W Range", true)
    menu.draws:color("w", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("e_range", "Draw E Range", true)
    menu.draws:color("e", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("r_range", "Draw R Range", true)
    menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)

local function RotateAroundPoint(v1, v2, angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    local x = ((v1.x - v2.x) * cos) - ((v2.z - v1.z) * sin) + v2.x
    local z = ((v2.z - v1.z) * cos) + ((v1.x - v2.x) * sin) + v2.z
    return vec3(x, v1.y, z or 0)
end

local function Q1dmg(target)
    local damage = 0 

    if not target then 
        return 
    end 

    if player:spellSlot(0).level == 0 or player:spellSlot(0).state ~= 0 then 
        return 
    end 

    if not player.buff['camilleqprimingcomplete'] then 
        damage = dlib.GetSpellDamage(0, target, 1)
    end 

    return damage
end  

local function Q2dmg(target)
    local damage = 0 

    if not target then 
        return 
    end 

    if player:spellSlot(0).level == 0 or player:spellSlot(0).state ~= 0 then 
        return 
    end 

    if player.buff['camilleqprimingcomplete'] then 
        damage = dlib.GetSpellDamage(0, target, 2)
    end 

    return damage
end     

local function CastQ()
    local Cast = 0 

    local target = common.GetTarget(common.GetAARange(player) + 50)

    if not target then 
        return 
    end 

    if target.path.serverPos:dist(player.path.serverPos) > (common.GetAARange(target) + 50) then
        return
    end 

    if player:spellSlot(0).name == "CamilleQ" and not player.buff['camilleqprimingcomplete'] then  
        if player:spellSlot(0).state == 0 and os.clock() - Cast > 1.5 then 
            player:castSpell('self', 0)
            orb.core.reset()
            Cast = os.clock()
        end
    elseif player.buff['camilleqprimingcomplete'] then  
        if player:spellSlot(0).state == 0 then 
            player:castSpell('self', 0)
            orb.core.reset()
        end
    end
end 

local function CastW()
    local pos = vec3(0,0,0)
    local target = common.GetTarget(700)

    if not target then 
        return 
    end 

    if target.path.serverPos:dist(player.path.serverPos) > 700 then
        return
    end 

    if player.buff['camilleedash1'] and player.buff['camilleedash2'] and player.buff['camilleedashtoggle'] and player.buff['camilleeonwall'] then 
        return 
    end


    if player:spellSlot(1).state == 0 and target.path.serverPos:dist(player.path.serverPos) >common.GetAARange(target) + 200 then 
        local seg = gpred.linear.get_prediction(pred_w, target)
        if seg and seg.startPos:distSqr(seg.endPos) < (650 * 650) then
            player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
        end
    end 
    
    if player.buff['camillewconeslashcharge'] then 
        local endPos = (player.path.serverPos - target.path.serverPos):norm()
        local pre_predPos = gpred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)

        if pre_predPos then 
            local predPos = vec3(pre_predPos.x, target.y, pre_predPos.y)
            pos = predPos
        end 

        local fullPoint = vec2(pos.x + endPos.x * 650, pos.y + endPos.y * 650)

        local v1 = player.path.serverPos
        local v2 = pos
        local v3 = fullPoint:to3D()
        local res = mathf.closest_vec_line(v1, v2, v3)

        if res then  
            player:move(res)
        end 
    end
end

local function CastE()
    local target = common.GetTarget(900)

    if not target then 
        return 
    end 

    if target.path.serverPos:dist(player.path.serverPos) > 900 then
        return
    end 

    for i = 0, 15 do  
        local pos = RotateAroundPoint(player.pos + vec3(0, 100, 0), player.pos, math.pi / 8 * i)

        local v1 = player.pos2D
        local v2 = player.pos2D
        local v3 = pos:to2D()
        local res = mathf.closest_vec_line_seg(v1, v2, v3)

        local aim = gpred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)

        local predPos = vec3(aim.x, target.y, aim.y)
        if predPos and common.GetDistance(player, predPos) > 800 then
            predPos = player.pos + (predPos - player.pos):norm() * 800
        end
        if res and navmesh.isWall(res) and common.GetDistance(predPos, pos) < 800 then 
            player:castSpell("pos", 2, res)
        end
    end 
end

local function on_tick()
    if player.isDead then 
        return 
    end 

    --[[for i, target in pairs(common.GetEnemyHeroes()) do 
        if target and common.IsValidTarget(target) then
            if player:spellSlot(2).name == 'CamilleE' and os.clock() - LastETick > 0.25 then
                local extendedPos = player.pos + (target.pos - player.pos):norm() * 1100
                for i = 0, 360, 30.5 do 
                    local myPos = vec3(player.x, player.y, player.z)
                    local tPos = vec3(target.x, target.y, target.z)
            
                    local Position = GetFirstWallHit(myPos, RotateAroundPoint(extendedPos, myPos,  math.deg(i)))
                    if Position then
                        for i = 0, 360, 22.5 do 
                            local extendedPosTow = target.pos  + (player.pos - target.pos):norm() * 450
                            local Pos = GetFirstWallHit(Position, RotateAroundPoint(extendedPosTow, Position, math.deg(i)));
                            if (Pos and navmesh.isWall(Pos)) then 
                                local closestToEnemyPos = vec3(0,0,0)
                                local closestToEnemyPosDistance = player.pos:dist(target); 
                                if (Position:dist(target) < closestToEnemyPosDistance) then
                                    closestToEnemyPos = Pos;
                                    closestToEnemyPosDistance = Position:dist(target);
                                end
                                if closestToEnemyPos ~= vec3(0,0,0) then
                                    player:castSpell("pos", 2, closestToEnemyPos)
                                    LastETick = os.clock()
                                end
                            end
                        end
                        --graphics.draw_circle(Position, 150, 1, graphics.argb(255, 218, 165, 38), 30)
                    end
                end
            elseif  player:spellSlot(2).name == 'CamilleEDash2' and os.clock() - LastETick > 0.1 then
                for i = 0, 360, 22.5 do 
                    local extendedPosTow = target.pos  + (player.pos - target.pos):norm() *450
                    local Pos = GetFirstWallHit(player.pos, RotateAroundPoint(extendedPosTow, player.pos, math.deg(i)));
                    if (Pos) and (navmesh.isWall(Pos))  then 
                        local closestToEnemyPos = vec3(0,0,0)
                        local closestToEnemyPosDistance = player.pos:dist(target); 
                        if (Pos:dist(target) < closestToEnemyPosDistance) then
                            closestToEnemyPos = Pos;
                            closestToEnemyPosDistance = Pos:dist(target);
                        end
                        player:move(target.pos)
                    end
                end
            end
        end
    end]]
    CastQ()
    CastW()
    CastE()
end 

local function onDraw()
    if (player and player.isDead and not player.isTargetable and player.buff[17] ~= nil) then return end
    if (player.isOnScreen) then
        if menu.draws.w_range:get() and player:spellSlot(1).level > 0 then
            graphics.draw_circle(player.pos, 650, 1, menu.draws.w:get(), 100)
        end
        if menu.draws.e_range:get() and player:spellSlot(2).level > 0 then
            graphics.draw_circle(player.pos, 800, 1, menu.draws.e:get(), 100)
        end
        if menu.draws.r_range:get() and player:spellSlot(3).level > 0 then
            graphics.draw_circle(player.pos, 475, 1, menu.draws.r:get(), 100)
        end
    end
end 

cb.add(cb.draw, onDraw)
orb.combat.register_f_pre_tick(on_tick);