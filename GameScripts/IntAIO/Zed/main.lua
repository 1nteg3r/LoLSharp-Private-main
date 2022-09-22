local orb = module.internal("orb");
local evade = module.seek('evade');
local pred = module.internal("pred")
local common = module.load(header.id, "Library/common")
local TS = module.load(header.id, "TargetSelector/targetSelector")
local dlib = module.load(header.id, 'Library/damageLib')

local wshadow = nil 
local rshadow = nil
local LastW = 0
local LastR = 0 
local El = "ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua"
local Data = {"AatroxQ","AhriSeduce","CurseoftheSadMummy","InfernalGuardian","EnchantedCrystalArrow","AzirR","BrandWildfire","CassiopeiaPetrifyingGaze","DariusExecute","DravenRCast","EvelynnR","EzrealTrueshotBarrage","Terrify",
"GalioIdolOfDurand","GarenR","GravesChargeShot","HecarimUlt","LissandraR","LuxMaliceCannon","UFSlash","AlZaharNetherGrasp"
,"OrianaDetonateCommand","LeonaSolarFlare","SejuaniGlacialPrisonStart","SonaCrescendo","VarusR","GragasR","GnarR","FizzMarinerDoom"
,"SyndraR","AkaliShadowSwipe","Pulverize","BandageToss","CurseoftheSadMummy","FlashFrost","InfernalGuardian","EnchantedCrystalArrow"
,"AurelionSolQ","AurelionSolR","AzirR","BardQ","BardR","RocketGrab","BraumRWrapper","CamilleEDash2","CassiopeiaW","CassiopeiaR",
"Rupture","DariusAxeGrabCone","DravenDoubleShot","EkkoW","EkkoR","EliseHumanE","EvelynnR","EzrealR","GalioW","GalioE","GnarBigQ"
,"GnarR","GragasE","GragasR","GravesChargeShot","HecarimUlt","HeimerdingerE","IllaoiE","IreliaTranscendentBlades","IvernQ","JannaQ",
"JarvanIVEQ","JinxR","KarmaQMantra","KledQ","LeblancE","LeonaZenithBlade","LeonaSolarFlare","LissandraW","LuxMaliceCannon","UFSlash"
,"DarkBindingMissile","NamiQ","NamiR","NautilusAnchorDrag","OrianaDetonateCommand-","RengarE","RumbleCarpetBombM","SejuaniGlacialPrisonStart","ShenE","SonaR","TaricE","ThreshQ","ThreshEFlay","UrgotE","UrgotR","Vi-q","XerathMageSpear","WarwickR","ZacE2","ZiggsR","ZyraR","ZyraE","yasuoq3w"}

local spellQ = { 
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 1700,
    width = 50,
    range = 925,
    collision = { hero = false, minion = false, wall = true }
}

local menu = menu("IntnnerZed", "Int - Zed");
    menu:header("xs", "Core");
    TS = TS(menu, 1450)
    TS:addToMenu()
    menu:keybind("Combo2", "Combo without R", false, "A")
    menu:keybind("Harass2", "Harass W > E > Q", false, "S")
menu:menu('combo', "Combat Settings");
    menu.combo:dropdown('Combo.Style', 'R - Combo Priority:', 2, { "Line", "Triangle", "MousePos"});
    menu.combo:boolean('q', 'Use Q', true);
    menu.combo:boolean('w', 'Use W', true);
    menu.combo:boolean('e', 'Use E', true);
    menu.combo:boolean('r', 'Use R', true);
    menu.combo:header("izi", 'Advanced features:')
    menu.combo:boolean('Items', 'Use offensive items', true);
    menu.combo:boolean('SwapDead', 'Use W2/R2 if target will die', false);
    menu.combo:boolean('SwapGapclose', 'Use W2/R2 to get close to target', true);
    menu.combo:slider("SwapHP", "Use W2/R2 if my % of health is less than {0}", 15, 10, 100, 10);
    menu.combo.SwapHP:set("tooltip", "Use W2/R2 if my % of health is less than")
    menu.combo:boolean('Prevent', "Don't use spells before R", true);
    menu.combo:header('a2a1', 'BlackList R')
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy then 
            menu.combo:boolean(enemy.charName, "Don't use R on: " .. enemy.charName, false)
        end
    end 

menu:menu("harass", "Harass");
    menu.harass:boolean("q", "Check collision when casting Q (more damage)", false);
    menu.harass.q:set("tooltip", "Check collision when casting Q (more damage)")
    menu.harass:boolean("WE", "Only harass when combo WE will hit", false);
    menu.harass.WE:set("tooltip", "Only harass when combo WE will hit")
    menu.harass:boolean("SwapGapclose", "Use W2 if target is killable", true);
    menu.harass:slider("mana", "Minimum Mana Percent", 20, 0, 100, 1);

--[[menu:menu("lane", "Clear");
    menu.lane:menu("laneclear", "LaneClear");
        menu.lane.laneclear:slider("LaneClear.Q", "Use Q if hit is greater than", 3, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.E", "Use E if hit is greater than", 4, 1, 10, 1);
        menu.lane.laneclear:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 60, 0, 100, 1);
    menu.lane:menu("jungle", "JungleClear");
    menu.lane.jungle:boolean("q", "Use Q", true);
    menu.lane.jungle:boolean("w", "Use W", true);
    menu.lane.jungle:boolean("e", "Use E", true);
    menu.lane.jungle:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 50, 0, 100, 1);
    menu.lane:menu("last", "LastHit");
        menu.lane.last:dropdown('LastHit.Q', 'Use Q', 2, {'Never', 'Smartly', 'Always'});
        menu.lane.last:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 50, 0, 100, 1);]]

menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useW', 'Use Swap for KillSteal', true)
    menu.kill:boolean('useE', 'Use E for KillSteal', true)

menu:menu('auto', 'Automatic')
    menu.auto:boolean("E.Auto", "Use E", false);
    menu.auto:boolean("SwapDead", "Use W2/R2 if target will die", false);

menu:menu('evade', "Evader")
    --menu.evade:boolean("UseEvade", "Use W1 to Evade", false);
    menu.evade:boolean("W2", "Use W2 to Evade", true);
    menu.evade:boolean("R1", "Use R1 to Evade", true);
    menu.evade:boolean("R2", "Use R2 to Evade", true);

menu:menu('misc', "Misc")
    menu.misc:keybind("autoq", "Auto Q", nil, "G")
    menu.misc:header('a2a1', 'Allowed champions to use Auto Q')
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy then 
            menu.misc:boolean(enemy.charName, "Auto Q: " .. enemy.charName, true)
        end
    end 
--[[    menu.misc:menu('flee', "Flee")
    menu.misc.flee:boolean('fleeW', 'Use W to Flee', true)
    menu.misc.flee:keybind("keyFlee", "^ Hot-Key Flee", "Z", nil)]]

menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", true)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("rrange", "Draw R Range", false)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)


local function IsUnderTurrent(pos)
    if not pos then 
        return 
    end 

    for i=0, objManager.turrets.size[TEAM_ENEMY]-1 do
        local obj = objManager.turrets[TEAM_ENEMY][i]
        if obj and obj.health and obj.health > 0 and common.GetDistanceSqr(obj, pos) <= (915 ^ 2) + player.boundingRadius then
            return true
        end
    end
    return false
end

local IsReady = function(slot)
    if player:spellSlot(slot).state == 0 then 
        return true 
    end 

    return false
end 

local function CastW(target)
    if not target then 
        return 
    end 
    local time = game.time 
    if LastW < time and player:spellSlot(1).name == "ZedW" and player.manaCost0 + player.manaCost1 < player.mana then  

        if player.pos2D:dist(target.pos2D) <= 650 + 350 then 
            local castpos =  target.pos + (player.pos - target.pos):norm() * 100

            if navmesh.isWall(castpos) then 
                return
            end 

            player:castSpell('pos', 1, castpos)  
            LastW = time + 0.25 
        end
    end
end

local function CastW2(target)
    if menu.combo.SwapDead:get() and player.buff[string.lower"ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua"] and IsReady(0) and player.mana > 60 then  
        if player.pos2D:dist(target.pos2D) <= 650 + 100 then 
            local castpos =  target.pos + (player.pos - target.pos):norm() * - 25
           
            if navmesh.isWall(castpos) then 
                return
            end 

            player:castSpell('pos', 1, castpos) 
        end
    else 
        return CastW(target)
    end
end

local Combo = function()
    local gameTime  = game.time 
    local target = TS.target

    if target and target ~= nil and common.IsValidTarget(target) then 
        if (not IsReady(3) or player:spellSlot(3).name == "ZedR2" or not menu.combo.r:get() or (not menu.Combo2:get())) then
            if menu.combo.q:get() and (not IsReady(1) or player:spellSlot(1).name == "ZedW2") then  
                local seg = pred.linear.get_prediction(spellQ, target, vec2(player.x,player.z))
                if seg and player.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and player.pos2D:dist(target.pos2D) < 950 then
                    player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                end

                if wshadow and wshadow ~= nil then 
                    if player.pos2D:dist(target.pos2D) < (950 + player.pos2D:dist(wshadow.pos2D)) then
                        local seg = pred.linear.get_prediction(spellQ, target, vec2(wshadow.x,wshadow.z))
                        if seg and wshadow.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and wshadow.pos2D:dist(target.pos2D) < 950 then
                            player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                        end
                    end 
                end 

                --R 
                if rshadow and rshadow ~= nil then 
                    if player.pos2D:dist(target.pos2D) < (950 + player.pos2D:dist(rshadow.pos2D)) then
                        local seg = pred.linear.get_prediction(spellQ, target, vec2(rshadow.x,rshadow.z))
                        if seg and rshadow.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and rshadow.pos2D:dist(target.pos2D) < 950 then
                            player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                        end
                    end 
                end 

            end 

            if menu.combo.w:get() then 
                CastW2(target)  
            end 
    
            if menu.combo.e:get() and IsReady(2) then 
                if player.pos2D:dist(target.pos2D) < 310 then 
                    player:castSpell('self', 2)
                end 
    
                if wshadow and wshadow ~=nil then 
                    if player.pos2D:dist(target.pos2D) < (310 + player.pos2D:dist(wshadow.pos2D)) then
                        if wshadow.pos2D:dist(target.pos2D) <= 290 then
                            player:castSpell('self', 2)
                        end
                    end
                end
                if rshadow and rshadow ~=nil then 
                    if player.pos2D:dist(target.pos2D) < (310 + player.pos2D:dist(rshadow.pos2D)) then
                        if rshadow.pos2D:dist(target.pos2D) <= 290 then
                            player:castSpell('self', 2)
                        end 
                    end 
                end 
            end
        end

        if menu.combo.r:get() and player:spellSlot(3).name == "ZedR" and LastR < gameTime then 

            if player.mana < 100 then 
                return 
            end

            if not menu.Combo2:get() then 

                if player.pos2D:dist(target.pos2D) < 625 + 310 then 
                    if player.pos2D:dist(target.pos2D) > 625 and player.pos2D:dist(target.pos2D) <= 625 + 650 and IsReady(1) and menu.combo.SwapGapclose:get() then 
                        local Castpos = target.pos + (player.pos - target.pos):norm() * -650 

                        if navmesh.isWall(Castpos) then 
                            return
                        end

                        if player:castSpell('pos', 1, Castpos) then 
                            return
                        end
                    end
                end
            end
            if menu.Combo2:get() then 
                if player.pos2D:dist(target.pos2D) > 625 and target.pos2D:dist(player.pos2D) <= 625 + 650 and IsReady(1) and menu.combo.SwapGapclose:get() then 
                    local Castpos = target.pos + (player.pos - target.pos):norm() * -650 

                    if navmesh.isWall(Castpos) then 
                        return
                    end
                    
                    if player:castSpell('pos', 1, Castpos) then 
                        return
                    end
                end
                if target.pos2D:dist(player.pos2D) <= 625 and player:castSpell('obj', 3, target) then 
                    LastR = gameTime + 0.25  
                    return 
                end
            end
        end 
    end 
    
end 

local function AutoQ()
    local target = common.GetTarget(1400)

    if target then 

        if player:spellSlot(0).state == 0 and target ~= nil then 
            local seg = pred.linear.get_prediction(spellQ, target, vec2(player.x,player.z))
            if seg and player.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and player.pos2D:dist(target.pos2D) < 950 then
                player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
            end

            if wshadow and wshadow ~= nil then 
                if player.pos2D:dist(target.pos2D) < (950 + player.pos2D:dist(wshadow.pos2D)) then
                    local seg = pred.linear.get_prediction(spellQ, target, vec2(wshadow.x,wshadow.z))
                    if seg and wshadow.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and wshadow.pos2D:dist(target.pos2D) < 950 then
                        player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                    end
                end 
            end 

            --R 
            if rshadow and rshadow ~= nil then 
                if player.pos2D:dist(target.pos2D) < (950 + player.pos2D:dist(rshadow.pos2D)) then
                    local seg = pred.linear.get_prediction(spellQ, target, vec2(rshadow.x,rshadow.z))
                    if seg and rshadow.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and rshadow.pos2D:dist(target.pos2D) < 950 then
                        player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                    end
                end 
            end 
        end
    end 
end

local function Harass()
    local target = TS.target

    if target and target ~= nil and common.IsValidTarget(target) then 
        if menu.combo.q:get() and (not IsReady(1) or player:spellSlot(1).name == "ZedW2") then  
            local seg = pred.linear.get_prediction(spellQ, target, vec2(player.x,player.z))
            if seg and player.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and player.pos2D:dist(target.pos2D) < 950 then
                player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
            end

            if wshadow and wshadow ~= nil then 
                if player.pos2D:dist(target.pos2D) < (950 + player.pos2D:dist(wshadow.pos2D)) then
                    local seg = pred.linear.get_prediction(spellQ, target, vec2(wshadow.x,wshadow.z))
                    if seg and wshadow.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and wshadow.pos2D:dist(target.pos2D) < 950 then
                        player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                    end
                end 
            end 

            --R 
            if rshadow and rshadow ~= nil then 
                if player.pos2D:dist(target.pos2D) < (950 + player.pos2D:dist(rshadow.pos2D)) then
                    local seg = pred.linear.get_prediction(spellQ, target, vec2(rshadow.x,rshadow.z))
                    if seg and rshadow.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and rshadow.pos2D:dist(target.pos2D) < 950 then
                        player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                    end
                end 
            end 

        end 

        if menu.combo.w:get() then 
            CastW2(target)  
        end 

        if menu.combo.e:get() and IsReady(2) then 
            if player.pos2D:dist(target.pos2D) < 310 then 
                player:castSpell('self', 2)
            end 

            if wshadow and wshadow ~=nil then 
                if player.pos2D:dist(target.pos2D) < (310 + player.pos2D:dist(wshadow.pos2D)) then
                    if wshadow.pos2D:dist(target.pos2D) <= 290 then
                        player:castSpell('self', 2)
                    end
                end
            end
            if rshadow and rshadow ~=nil then 
                if player.pos2D:dist(target.pos2D) < (310 + player.pos2D:dist(rshadow.pos2D)) then
                    if rshadow.pos2D:dist(target.pos2D) <= 290 then
                        player:castSpell('self', 2)
                    end 
                end 
            end 
        end
    end 
end 

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do

        if target and target ~= nil and common.IsEnemyMortal(target) and common.IsValidTarget(target) then 

            if common.GetShieldedHealth("AD", target) < dlib.GetSpellDamage(0, target) and IsReady(0) then 
                local seg = pred.linear.get_prediction(spellQ, target, vec2(player.x,player.z))
                if seg and player.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and player.pos2D:dist(target.pos2D) < 950 then
                    player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                end
    
                if wshadow and wshadow ~= nil then 
                    if player.pos2D:dist(target.pos2D) < (950 + player.pos2D:dist(wshadow.pos2D)) then
                        local seg = pred.linear.get_prediction(spellQ, target, vec2(wshadow.x,wshadow.z))
                        if seg and wshadow.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and wshadow.pos2D:dist(target.pos2D) < 950 then
                            player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                        end
                    end 
                end 
    
                --R 
                if rshadow and rshadow ~= nil then 
                    if player.pos2D:dist(target.pos2D) < (950 + player.pos2D:dist(rshadow.pos2D)) then
                        local seg = pred.linear.get_prediction(spellQ, target, vec2(rshadow.x,rshadow.z))
                        if seg and rshadow.pos:distSqr(vec3(seg.endPos.x, target.pos.y, seg.endPos.y)) < 900^2 and rshadow.pos2D:dist(target.pos2D) < 950 then
                            player:castSpell('pos', 0, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
                        end
                    end 
                end 

            end 


            if common.GetShieldedHealth("AD", target) < dlib.GetSpellDamage(2, target) and IsReady(2) then 
                if player.pos2D:dist(target.pos2D) < 310 then 
                    player:castSpell('self', 2)
                end 
    
                if wshadow and wshadow ~=nil then 
                    if player.pos2D:dist(target.pos2D) < (310 + player.pos2D:dist(wshadow.pos2D)) then
                        if wshadow.pos2D:dist(target.pos2D) <= 290 then
                            player:castSpell('self', 2)
                        end
                    end
                end
                if rshadow and rshadow ~=nil then 
                    if player.pos2D:dist(target.pos2D) < (310 + player.pos2D:dist(rshadow.pos2D)) then
                        if rshadow.pos2D:dist(target.pos2D) <= 290 then
                            player:castSpell('self', 2)
                        end 
                    end 
                end 
            end 
        end 
    end 
end 

local function on_tick()
    if player.isDead then 
        return 
    end 

    KillSteal()
    if orb.menu.combat.key:get() then 
        Combo()
    end

    if orb.menu.hybrid.key:get() then 
        Harass()
    end


    if menu.misc.autoq:get() and not orb.menu.combat.key:get() then
        AutoQ()
    end 
end 


local oncreateobj = function(obj)
    if obj.name:find("Base_R_cloneswap_buf") then
        rshadow = obj
    end 

    if obj.name:find("Base_W_cloneswap_buf") then 
        wshadow = obj
    end 

    if obj.name:find("Base_R_buf_tell") and player:spellSlot(3).name == "ZedR2" and rshadow and rshadow ~= nil then 
        if not IsUnderTurrent(rshadow.pos) then 
            if #common.CountEnemiesInRange(player.pos, 450) >= #common.CountEnemiesInRange(rshadow.pos, 450) then 
                player:castSpell("self", 3)
            end
        end
    end
end 

local ondeleteobj = function(obj)
    if not obj then 
        return
    end 

    if obj then 
        if rshadow and rshadow == obj then 
            rshadow = nil
        end 

        if wshadow and wshadow == obj then 
            wshadow = nil
        end 
    end 

end 

local on_process_spell = function(spell)
    if not spell then 
        return 
    end 

    if spell and spell.owner.team ~= player.team then 
        if menu.evade.W2:get() then 
            for k,v in pairs(Data) do 
                if v == spell.name then 
                    if player.pos:dist(vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)) < player.boundingRadius * 2 then
                        if wshadow and wshadow ~= nil and not IsUnderTurrent(wshadow.pos) then  
                            if #common.CountEnemiesInRange(player.pos, 450) >= #common.CountEnemiesInRange(wshadow.pos, 300) then 
                                player:castSpell("self", 1)
                            end
                        end
                    end
                end
            end
        end

        if menu.evade.R2:get() then 
            for k,v in pairs(Data) do 
                if v == spell.name then 
                    if player.pos:dist(vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)) < player.boundingRadius * 2 then
                        if rshadow and rshadow ~= nil and not IsUnderTurrent(rshadow.pos) then  
                            if #common.CountEnemiesInRange(player.pos, 450) >= #common.CountEnemiesInRange(rshadow.pos, 300) then 
                                player:castSpell("self", 3)
                            end
                        end
                    end
                end
            end
        end
    end 
end 

local function ondraw()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 925, 1, menu.draws.qcolor:get(), 40)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 650, 1, menu.draws.wcolor:get(), 40)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 315, 1, menu.draws.ecolor:get(), 40)
        end
        if (menu.draws.rrange:get() and player:spellSlot(3).state == 0) then
            graphics.draw_circle(player.pos, 625, 1, menu.draws.rcolor:get(), 40)
        end

        local Window = {x = graphics.res.x * 0.5, y = graphics.res.y * 0.5}
        local pos = {x = Window.x, y = Window.y}

        if menu.misc.autoq:get() then
			graphics.draw_text_2D("["..menu.misc.autoq.toggle.."] Auto Q: On", 18, pos.x + 307, pos.y + 425, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("["..menu.misc.autoq.toggle.."] Auto Q: Off", 18, pos.x + 307, pos.y + 425, graphics.argb(255, 255, 255, 255))
        end

        if menu.Combo2:get() then
			graphics.draw_text_2D("["..menu.Combo2.toggle.."] Combo without R: On", 18, pos.x + 307, pos.y + 450, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("["..menu.Combo2.toggle.."] Combo without R: Off", 18, pos.x + 307, pos.y + 450, graphics.argb(255, 255, 255, 255))
        end


        if menu.Harass2:get() then
			graphics.draw_text_2D("["..menu.Harass2.toggle.."] Harass W > E > Q: On", 18, pos.x + 307, pos.y + 475, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("["..menu.Harass2.toggle.."] Harass W > E > Q: Off", 18, pos.x + 307, pos.y + 475, graphics.argb(255, 255, 255, 255))
        end
    end 
    
end 

orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.create_particle, oncreateobj)
cb.add(cb.delete_particle, ondeleteobj)
cb.add(cb.draw, ondraw)
cb.add(cb.spell, on_process_spell)