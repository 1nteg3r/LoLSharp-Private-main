local orb = module.internal("orb");
local evade = module.seek('evade');
local TS = module.internal("TS")
local gpred = module.internal("pred")

local common = module.load(header.id, "Library/common");
local dlib = module.load(header.id, 'Library/damageLib');

local QSide = { }
local Eartch = { }
local youSide = false
--[[
    [26:00] Spell name: TaliyahQ
[26:00] Speed:3600
[26:00] Width: 80
[26:00] Time:0.25
[26:00] Animation: 2
[26:00] false
[26:00] CastFrame: 0.20982241630554

[26:25] Spell name: TaliyahWVC
[26:25] Speed:500
[26:25] Width: 50
[26:25] Time:0.25
[26:25] Animation: 2
[26:25] false
[26:25] CastFrame: 0.20982241630554
[26:25] --------------------------------------

6:32] Spell name: TaliyahE
[26:32] Speed:500
[26:32] Width: 0
[26:32] Time:0.25
[26:32] Animation: 2
[26:32] false
[26:32] CastFrame: 0.20982241630554
[26:32] --------------------------------------
[26:32] Delay: 0.5 Speed: 1700 Width: 0 Range: 651.12899081966
]]

local SpellQ = {
    range = 1000;
    delay = 0.25; 
	width = 100;
	speed = 3600;
	boundingRadiusMod = 1; 
	collision = { hero = true, minion = true, wall = true };
}

local SpellW = {
    range = 900;
    delay = 0.25; 
	radius = 50;
	speed = math.huge;
	boundingRadiusMod = 0; 
}

local SpellE = { 
    range = 800;
    delay = 0.25; 
	radius = 20;
	speed = 1700;
	boundingRadiusMod = 0; 
}

local menu = menu("intnnerTaliyah", "Int - Taliyah")
menu:menu("combo", "Combo Settings")
        menu.combo:menu('qsettings', "Q Settings")
            menu.combo.qsettings:boolean("qcombo", "Use Q", true)
            menu.combo.qsettings:boolean("qside", "Use Q In Side", true)
        menu.combo:menu('wsettings', "W Settings")
        menu.combo.wsettings:boolean('smartW', "Use W In Combo", true)
        menu.combo.wsettings:dropdown('modegab', 'W Mode: ', 3, {'Pull', 'Push', 'Smart'});
        menu.combo:menu('esettings', "E Settings")
            menu.combo.esettings:boolean("ecombo", "Use E", true)
            menu.combo.esettings:boolean("egab", "Use E Gabclose", true)
    menu:menu("harass", "Hybrid/Harass Settings")
        menu.harass:menu('qsettings', "Q Settings")
            menu.harass.qsettings:boolean("qharass", "Use Q", true)
            menu.harass.qsettings:boolean("qside", "Use Q In Side", true)
            menu.harass.qsettings:slider("Mana", "Minimum Mana Percent >= {0}", 25, 0, 100, 1);
    menu:menu("clear", "JungleClear Settings")
            menu.clear:menu('qsettings', "Q Settings")
                menu.clear.qsettings:boolean("qclear", "Use Q", true)
            menu.clear:menu('wsettings', "W Settings")
                menu.clear.wsettings:boolean('wclear', "Use W", true)
            menu.clear:menu('esettings', "E Settings")
                menu.clear.esettings:boolean("eclear", "Use E", true)
            menu.clear:slider("Mana", "Minimum Mana Percent >= {0}", 25, 0, 100, 1);
    menu:header("xd", "Misc Settings")
    menu:keybind("autoq", "Auto Q only in Side", nil, 'G')
    menu.autoq:set("tooltip", "Min Mana Percent 65%")
menu:menu("draws", "Drawings")
    menu.draws:boolean("q_range", "Draw Q Range", true)
    menu.draws:color("q", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("w_range", "Draw W Range", true)
    menu.draws:color("w", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("e_range", "Draw E Range", true)
    menu.draws:color("e", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("r_range", "Draw R Range Minimap", true)
    menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)

local function ObjectCast()
    local obj = nil 

    for i, object in pairs(Eartch) do 
        if object then      
            obj = object
        end 
    end

    return obj
end 

local function CastQ()
    local target = common.GetTarget(1000)

    if not target then 
        return 
    end 

    if target ~= nil and common.IsValidTarget(target) then 

        if player:spellSlot(0).state ~= 0 then 
            return 
        end 

        local seg = gpred.linear.get_prediction(SpellQ, target)

        if not seg then return end 

        if seg.startPos:distSqr(seg.endPos) < (SpellQ.range * SpellQ.range) and player.path.serverPos:dist(target.path.serverPos) <= SpellQ.range then
            
            local collision = gpred.collision.get_prediction(SpellQ, seg, target)

            if collision then 
                return 
            end 

            if (menu.combo.qsettings.qside:get() or not youSide) then 
                player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                return 
            end
        end
    end 
end 

local function CastW()
    local target = common.GetTarget(1100) 

    if not target then
        return 
    end 

    if target ~= nil and common.IsValidTarget(target) then 

        if player:spellSlot(1).state ~= 0 then 
            return 
        end 

        local seg = gpred.circular.get_prediction(SpellW, target)

        if (menu.combo.wsettings.modegab:get() == 1) then 
            if not seg then 
                return 
            end 

            if seg and seg.startPos:distSqr(seg.endPos) < (950 * 950) and player.path.serverPos:dist(target.path.serverPos) <= 950 then --Pull 
                local pre_prediction = vec3(seg.endPos.x, target.y, seg.endPos.y)
                local pred_push = pre_prediction + (player.pos - pre_prediction):norm() * (pre_prediction:dist(player.pos) + 200) 

                if pred_push then   
                    player:castSpell('line', 1, pre_prediction, pred_push)
                    return
                end 
            end 
            
        elseif (menu.combo.wsettings.modegab:get() == 2) then 
            if not seg then 
                return 
            end 

            if seg and seg.startPos:distSqr(seg.endPos) < (950 * 950) and player.path.serverPos:dist(target.path.serverPos) <= 950 then --Push 
                local pre_prediction = vec3(seg.endPos.x, target.y, seg.endPos.y)
                local pred_push = player.pos + (pre_prediction - player.pos):norm() * (pre_prediction:dist(player.pos) + 200)

                if pred_push then   
                    player:castSpell('line', 1, pre_prediction, pred_push)
                    return
                end 
            end 
        elseif (menu.combo.wsettings.modegab:get() == 3) then 
            local E_object = ObjectCast()

            if E_object then 
                if seg and seg.startPos:distSqr(seg.endPos) < (950 * 950) and player.path.serverPos:dist(target.path.serverPos) <= 950 then
                    local pre_prediction = vec3(seg.endPos.x, target.y, seg.endPos.y)
                    local pred_push = pre_prediction + (E_object.pos - pre_prediction):norm() * (pre_prediction:dist(E_object.pos) + 200)

                    if pred_push then   
                        player:castSpell('line', 1, pre_prediction, pred_push)
                        return
                    end 
                end
            else 
                if (player.health > target.health) then 
                    if seg and seg.startPos:distSqr(seg.endPos) < (950 * 950) and player.path.serverPos:dist(target.path.serverPos) <= 950 then
                        local pre_prediction = vec3(seg.endPos.x, target.y, seg.endPos.y)
                        local pred_push = pre_prediction + (player.pos - pre_prediction):norm() * (pre_prediction:dist(player.pos) + 200)
        
                        if pred_push then   
                            player:castSpell('line', 1, pre_prediction, pred_push)
                            return
                        end 
                    end
                else 
                    if seg and seg.startPos:distSqr(seg.endPos) < (950 * 950) and player.path.serverPos:dist(target.path.serverPos) <= 950 then
                        local pre_prediction = vec3(seg.endPos.x, target.y, seg.endPos.y)
                        local pred_push = player.pos + (pre_prediction - player.pos):norm() * (pre_prediction:dist(player.pos) + 200)
        
                        if pred_push then   
                            player:castSpell('line', 1, pre_prediction, pred_push)
                            return
                        end 
                    end
                end 
            end 
        end
    end 
end 

local function CastE()
    local target = common.GetTarget(800)

    if not target then 
        return 
    end 

    if target ~= nil and common.IsValidTarget(target) then 

        if player:spellSlot(2).state ~= 0 then 
            return 
        end 

        local seg = gpred.circular.get_prediction(SpellE, target)

        if not seg then return end 

        if seg.startPos:distSqr(seg.endPos) < (SpellE.range * SpellE.range) and player.path.serverPos:dist(target.path.serverPos) < SpellE.range then
            
            player:castSpell("pos", 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
            return 
        end
    end 
end

local function combo()
    if menu.combo.qsettings.qcombo:get() then 
        CastQ()
    end 

    if menu.combo.esettings.ecombo:get() then 
        CastE()
    end

    if menu.combo.wsettings.smartW:get() then 
        CastW()
    end 

end 

local function Gabclose()
    local obj = common.GetTarget(800)
    if obj and obj.path.isActive and obj.path.isDashing then

        local range = player.attackRange + (player.boundingRadius + obj.boundingRadius) + 200
        if player.pos:dist(obj.pos) <= range then

            local pred_pos = gpred.core.lerp(obj.path, network.latency + 0.25, obj.path.dashSpeed)
            if pred_pos then 
                if pred_pos:dist(player.pos2D) <= range then
                    player:castSpell("pos", 2, obj.pos)
                end
            end 
        end
    end
end

local function harass()
    if menu.harass.qsettings.qharass:get() then     
     
        if common.GetPercentMana(player) >= menu.harass.qsettings.Mana:get()  then 
            local target = common.GetTarget(1000)

            if not target then 
                return 
            end 
        
            if target ~= nil and common.IsValidTarget(target) then 
        
                if player:spellSlot(0).state ~= 0 then 
                    return 
                end 
        
                local seg = gpred.linear.get_prediction(SpellQ, target)
        
                if not seg then return end 
        
                if seg.startPos:distSqr(seg.endPos) < (SpellQ.range * SpellQ.range) and player.path.serverPos:dist(target.path.serverPos) <= SpellQ.range then
                    
                    local collision = gpred.collision.get_prediction(SpellQ, seg, target)
        
                    if collision then 
                        return 
                    end 
        
                    if (menu.harass.qsettings.qside:get() or not youSide) then 
                        player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end
            end 
        end 
    end 
end 

local excluded_minions = {
    ["CampRespawn"] = true,
    ["PlantMasterMinion"] = true,
    ["PlantHealth"] = true,
    ["PlantSatchel"] = true,
    ["PlantVision"] = true
}


local function laneclear()
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local Monsters = objManager.minions[TEAM_NEUTRAL][i]
        if Monsters and common.IsValidTarget(Monsters) and Monsters.health > 0 and Monsters.maxHealth > 100 and Monsters.maxHealth < 10000 and not Monsters.name:find("Ward") and not excluded_minions[Monsters.name] then 

            if player.path.serverPos:dist(Monsters.path.serverPos) <= common.GetAARange(Monsters) then
                local aa_damage = common.CalculateAADamage(Monsters)
                if (aa_damage * 2) >= common.GetShieldedHealth("AD", Monsters) then
                    return
                end
            end


            if common.GetPercentMana(player) >= menu.clear.Mana:get()  then 
                if player:spellSlot(0).state == 0 and menu.clear.qsettings.qclear:get() then 
                    local seg = gpred.linear.get_prediction(SpellQ, Monsters)
            
                    if not seg then return end 
            
                    if seg.startPos:distSqr(seg.endPos) < (SpellQ.range * SpellQ.range) and player.path.serverPos:dist(Monsters.path.serverPos) <= SpellQ.range then
                        player:castSpell("pos", 0, vec3(seg.endPos.x, Monsters.y, seg.endPos.y))
                    end
                end 

                if player:spellSlot(1).state == 0 and menu.clear.wsettings.wclear:get() then 
                    local seg = gpred.linear.get_prediction(SpellQ, Monsters)
            
                    if not seg then return end 
            
                    if seg and seg.startPos:distSqr(seg.endPos) < (950 * 950) and player.path.serverPos:dist(Monsters.path.serverPos) <= 950 then --Push 
                        local pre_prediction = vec3(seg.endPos.x, Monsters.y, seg.endPos.y)
                        local pred_push = player.pos + (pre_prediction - player.pos):norm() * (pre_prediction:dist(player.pos) + 200)
        
                        if pred_push then   
                            player:castSpell('line', 1, pre_prediction, pred_push)
                        end 
                    end 
                end 

                if player:spellSlot(2).state == 0 and menu.clear.esettings.eclear:get() then 
                    local seg = gpred.circular.get_prediction(SpellE, Monsters)

                    if not seg then return end 

                    if seg.startPos:distSqr(seg.endPos) < (SpellE.range * SpellE.range) and player.path.serverPos:dist(Monsters.path.serverPos) <= SpellE.range then
                        
                        player:castSpell("pos", 2, vec3(seg.endPos.x, Monsters.y, seg.endPos.y))
                        return 
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

    if menu.combo.esettings.egab:get() then 
        Gabclose()
    end
    
    --Checking Side 
    for i, Side in pairs(QSide) do  

        if Side then 
            if player.pos:dist(Side) < 445 then 
                youSide = true 
            else 
                youSide = false 
            end
        end 
    end

    if orb.menu.combat.key:get() then 
        combo()
    elseif orb.menu.hybrid.key:get() then  
        harass()
    elseif orb.menu.lane_clear.key:get() then  
        laneclear()
    end 


    if menu.autoq:get() then 
        if common.GetPercentMana(player) >= 65 then 
            local target = common.GetTarget(1000)

            if not target then 
                return 
            end 
        
            if target ~= nil and common.IsValidTarget(target) then 
        
                if player:spellSlot(0).state ~= 0 then 
                    return 
                end 
        
                local seg = gpred.linear.get_prediction(SpellQ, target)
        
                if not seg then return end 
        
                if seg.startPos:distSqr(seg.endPos) < (SpellQ.range * SpellQ.range) and player.path.serverPos:dist(target.path.serverPos) <= SpellQ.range then
                    
                    local collision = gpred.collision.get_prediction(SpellQ, seg, target)
        
                    if collision then 
                        return 
                    end 
        
                    if (youSide) then 
                        player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                    end
                end
            end 
        end 
    end 
end 

local function OnCreateParticle(obj)
    if not obj then 
        return 
    end 

    if obj ~= nil and obj.name:find("Base_E_Mines") then 
        Eartch[obj.ptr] = obj 
    end 

    if obj ~= nil and obj.name:find("Base_Q_aoe_bright") then 
        QSide[obj.ptr] = obj 
    end 

    --[[if obj.name:lower():find("taliyah") then 
        print(obj.name)
    end]]
end 

local function OnDeleteParticle(obj)
    if obj then
        QSide[obj.ptr] = nil
        Eartch[obj.ptr] = nil 
    end 
end 

local function OnDraw()
    if player.isDead then 
        return 
    end 

    if not player.isOnScreen then 
        return 
    end 

    if (player:spellSlot(0).state == 0 and menu.draws.q_range:get()) then 
        graphics.draw_circle(player.pos, 1000, 1, menu.draws.q:get(), 100)
    end 

    if (player:spellSlot(1).state == 0 and menu.draws.w_range:get()) then 
        graphics.draw_circle(player.pos, 900, 1, menu.draws.w:get(), 100)
    end 

    if (player:spellSlot(2).state == 0 and menu.draws.e_range:get()) then 
        graphics.draw_circle(player.pos, 800, 1, menu.draws.e:get(), 100)
    end 


    if (menu.draws.r_range:get() and player:spellSlot(3).level > 0) then 
        minimap.draw_circle(player.pos, ({3000, 4500, 6000})[player:spellSlot(3).level], 1, 0xFFFFFFFF, 16)
    end

    
    local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))

    if menu.autoq:get() then
        graphics.draw_text_2D("Auto Q only Side: ON", 17, pos.x - 45, pos.y + 30, graphics.argb(255, 255, 255, 255))
    else
        graphics.draw_text_2D("Auto Q only Side: OFF", 17, pos.x - 45, pos.y + 30, graphics.argb(255, 255, 255, 255))
    end
end 

orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.draw, OnDraw)

cb.add(cb.create_particle, OnCreateParticle)
cb.add(cb.delete_particle, OnDeleteParticle)