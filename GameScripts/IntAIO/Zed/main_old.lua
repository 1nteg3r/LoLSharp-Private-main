local orb = module.internal("orb");
local evade = module.seek('evade');
local TargetPred = module.internal("TS")
local pred = module.internal("pred")
local common = module.load(header.id, "Library/common");
local TS = module.load(header.id, "TargetSelector/targetSelector")
local dlib = module.load(header.id, 'Library/damageLib');

local objHolder = {}
local objTimeHolder = {}

local objHolderR = { }
local objHolderRTime = { }
local Range = 0
local EnemyIsDead = false; 
local IsDeadObject = { }

local R_IsDash = false
---[[local Shadow_W = "nil";
local Shawdow_Header_W = "nil"; 
local Shawdow_Time_W = 0;
local Swapped_W = false;
local CloneSwap_W = { }; 

local Shawdow_R = "nil";
local Shawdow_Header_R = "nil"; 
local Shawdow_Time_R = 0;
local Swapped_R = false;
local CloneSwap_R = { }

local CanCastW2 = false

local ShadowSkinName = "ZedShadow";
local IsDeadName = "Zed_Base_R_buf_tell.troy";
local Obj_AI_Minion = { }
local CloneDeath = { }

local Q = {
    Range = 0; 
    _QSource = nil;
    pred_input = {
        boundingRadiusModSource = 1,
        boundingRadiusMod = 1,
        delay = 0.25,
        speed = 1700,
        width = 100,
        range = 925,
        collision = { hero = false, minion = false, wall = true },
    }
}

local W = {
    LastCastTime = 0; 
    LastSentTime = 0;
    LastEndPosition = vec3(0,0,0);
    LastStartPosition = vec3(0,0,0);
}

local E = { 
    pred_input = {
        delay = 0.5,
        radius = player.attackRange,
        dashRadius = 310,
        boundingRadiusModSource = 1,
        boundingRadiusModTarget = 1,
    }
}

local MarkedDamageReceived  = 0 
local EnemyWillDie = false 

local menu = menu("IntnnerZed", "Int Zed");
    menu:header("xs", "Core");
    TS = TS(menu, Range)
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
    menu.combo:boolean('SwapDead', 'Use W2/R2 if target will die', true);
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

menu:menu("lane", "Clear");
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
        menu.lane.last:slider("LaneClear.ManaPercent", "Minimum Mana Percent", 50, 0, 100, 1);

menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useW', 'Use Swap for KillSteal', true)
    menu.kill:boolean('useE', 'Use E for KillSteal', true)

menu:menu('auto', 'Automatic')
    menu.auto:boolean("E.Auto", "Use E", false);
    menu.auto:boolean("SwapDead", "Use W2/R2 if target will die", false);

menu:menu('evade', "Evader")
    menu.evade:boolean("UseEvade", "Use W1 to Evade", false);
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
    menu.misc:menu('flee', "Flee")
    menu.misc.flee:boolean('fleeW', 'Use W to Flee', true)
    menu.misc.flee:keybind("keyFlee", "^ Hot-Key Flee", "Z", nil)

menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", true)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("rrange", "Draw R Range", false)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)

local function GetMinionsHit(Pos, radius)
    local count = 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and minion.pos:dist(player) <= 315 and common.GetDistance(minion, Pos) < radius then
			count = count + 1
		end
	end
	return count
end

local function on_create_minion(minion)
    if minion and minion.team == player.team then 
        --print(minion.name, minion.charName)
        if minion.charName == "ZedShadow" and minion.name == "Shadow" and R_IsDash == false then 
            objHolder[minion.ptr] = minion
            objTimeHolder[minion.ptr] = os.clock() + 6
            if player:spellSlot(3).name == "ZedR2" then
                objHolderR[minion.ptr] = minion
                objHolderRTime[minion.ptr] = os.clock() + 6
            end 
            --print(minion.name, minion.charName)
        end
    end
end

local function CountSoldiers()
   	local soldiers = 0
    for _, obj in pairs(objHolder) do
        if objTimeHolder[obj.ptr] and objTimeHolder[obj.ptr] > os.clock() and common.GetDistance(obj, player) < 2000 and R_IsDash == false then
            soldiers = soldiers + 1
        end
    end
    return soldiers
end

local function GetSoldierR()
    local soldiers = {}
    for _,obj in pairs(objHolderR) do
        if objHolderRTime[obj.ptr] and objHolderRTime[obj.ptr] > os.clock() and R_IsDash == false then
            table.insert(soldiers, obj)
        end
    end
    return soldiers
end

local function GetSoldiers()
    local soldiers = {}
    for _,obj in pairs(objHolder) do
        if objTimeHolder[obj.ptr] and objTimeHolder[obj.ptr] > os.clock() and R_IsDash == false then
            table.insert(soldiers, obj)
        end
    end
    return soldiers
end

local function A2V ( a, m )
	m = m or 1
	local x = math.cos ( a ) * m
	local y = math.sin ( a ) * m
	return x, y
end

local pred_filter = function(seg, input, obj)
    --always cast if the target is 875 or less units away (randomly chosen value)
    local dist = seg.startPos:distSqr(seg.endPos)
    if dist < 925 then
      return true
    end
    --always cast if the target is stunned, knocked up etc
    if pred.trace.linear.hardlock(input, seg, obj) then
      return true
    end
    --always cast if the target is feared, taunted etc
    if pred.trace.linear.hardlockmove(input, seg, obj) then
      return true
    end
    --wait for the target to get on a new path if its more than 875 units away and not stunned
    --arguably higher hitchance. especially arguably for ezreal q because of the long winduptime + travel time
    --very effective on spells like xerath q
    if pred.trace.newpath(obj, 0.033, 0.500) then
      return true
    end
    if dist < 926 and game.mode == 'URF' then
      return true
    end
end

local function GetArrivalTime(target, castdelay, speed)
    local r = 0;
    r = castdelay;
    if (speed ~= math.huge) then 
        r = (1000* player.pos:dist(target)/speed) 
    end
    return r 
end

local function RShawdowIsValid()
    for _, K in pairs(GetSoldierR()) do
        if K then 
            return true
        end 
    end
    return false
end 
local function WShadowIsValid()
    for _, K in pairs(GetSoldiers()) do
        if K then 
            return true
        end 
    end
    return false
end 

local function IsW1()
    return player:spellSlot(1).name == "ZedW"
end 

local function IsR1()
    return player:spellSlot(3).name == "ZedR"
end 

local function IsWaitingShadow()
    return not WShadowIsValid() and W.LastCastTime > 0 and os.clock() - W.LastCastTime <= GetArrivalTime(W.LastEndPosition, 0.25, 1750)
end

local function IsCombo2()
    return menu.Combo2:get(); 
end

local function IsHarass2()
    return menu.Harass2:get();
end

local function TargetHaveR(target)
    return target.buff['zedrtargetmark']
end 

local function ShouldWaitMana()
    return player:spellSlot(1).state == 0 and IsW1() and player.mana < player.manaCost1 + player.manaCost0
end

local function IsDead(target)
    for i, Dead in pairs(IsDeadObject) do  
        if Dead then 
            if TargetHaveR(target) and (Dead and Dead.pos:dist(target.pos) <= 200) or EnemyWillDie then 
                return true 
            end 
        end
    end
    return false
end     

local function OnProcessSpell(spell)
    if(spell.owner == player and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Zed") then
        --print(spell.name)
        if spell.name == "ZedW" then 
            W.LastCastTime = os.clock()
        end

        if spell.name == "ZedR" then 
            MarkedDamageReceived = 0;
            EnemyWillDie = false;
        end
    end 
end 
cb.add(cb.spell, OnProcessSpell)

local function NeedsW(target)
    if (player.pos:distSqr(target) <= 700 and (player.mana < player.manaCost1 + player.manaCost0 or player.mana < player.manaCost1 + player.manaCost2)) then 
        return false 
    end
    return true
end 

local function WillDie(target, sSlot)
    local damage = 0 
    if sSlot == 0 then 
        damage = dlib.GetSpellDamage(0, target)
    elseif sSlot == 2 then 
        damage = dlib.GetSpellDamage(2, target)
    elseif sSlot == 3 then 
        damage = dlib.GetSpellDamage(3, target)
    end
    if target.buff['zedrtargetmark'] then 
        if ((MarkedDamageReceived + damage) * (.2 + player:spellSlot(3).level * 10) / .1 >= common.GetShieldedHealth("ALL", target)) then 
            EnemyWillDie = true;
            return true;
        end 
        return false 
    end 
    return false
end 

local function SwapByCountingEnemies()
    local Range = 0 
    local Count_W = 0
    local Count_R  = 0
    if WShadowIsValid() and player:spellSlot(1).state == 0 then  
        for _, K in pairs(GetSoldiers()) do
            if K then 
                if not common.IsUnderDangerousTower(K.pos) then 
                    Count_W = #common.CountEnemiesInRange(K.pos, 400)
                end
            end 
        end
    end

    if RShawdowIsValid() and player:spellSlot(3).state == 0 then 
        for _, K in pairs(GetSoldierR()) do
            if K then 
                if not common.IsUnderDangerousTower(K.pos) then 
                    Count_R = #common.CountEnemiesInRange(K.pos, 400)
                end
            end 
        end
    end

    local min = math.min(Count_R, Count_W);
    if #common.CountEnemiesInRange(player.pos, 400) > min then 
        if (min == Count_W) then
            player:castSpell('self', 1, player)
        elseif (min == Count_R) then 
            player:castSpell('self', 3, player)
        end
    end
end

local function CastQ(target)    

    if not target then 
        return 
    end

    if player:spellSlot(0).state == 0 and target ~= nil and not IsWaitingShadow() then      

        local seg = pred.linear.get_prediction(Q.pred_input, target)
        if seg and seg.startPos:dist(seg.endPos) <= (Q.Range) then
            if not pred.collision.get_prediction(Q.pred_input, seg, target)  then 
                player:castSpell('pos', 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end 
        end

        if WillDie(target, 0) then 
            SwapByCountingEnemies()
            return 
        end
    end
end 

local function CastW(target) 

    if not target then 
        return 
    end

    if player:spellSlot(1).state == 0 and target ~= nil and IsW1() then 
        W.LastCastTime = os.clock()

        local pre_predPos = pred.core.lerp(target.path, network.latency + 0.25, target.moveSpeed)
        if not pre_predPos then 
            return 
        end 

        local predPos = vec3(pre_predPos.x, target.y, pre_predPos.y)
        local wPos = predPos 
        if (predPos:dist(target) <= Q.Range + 700 and os.clock() - W.LastSentTime  > 175) then  
            if RShawdowIsValid() then 
                for i, clone in pairs(GetSoldierR()) do 
                    if clone then 
                        if menu.combo['Combo.Style']:get() == 1 then 
                            wPos = player.pos + (predPos - clone.pos):norm() * 700
                        elseif menu.combo['Combo.Style']:get() == 2 then 
                            wPos = player.pos + ((predPos - clone.pos):norm() * 700):perp1()
                        elseif menu.combo['Combo.Style']:get() == 3 then 
                            wPos = mousePos
                        end
                    end 
                end
            else
                wPos = player.pos + (predPos - player.pos):norm() * 700;
            end
        end

        if player:castSpell('pos', 1, wPos) then 
            W.LastSentTime  = os.clock()
        end
    end
end 

local function CastE(target)

    if not target then 
        return 
    end

    if player:spellSlot(2).state == 0 and target ~= nil then 
        local Count = 0
        if WShadowIsValid() then 
            for i, clone in pairs(GetSoldiers()) do 
                if clone then 
                    if #common.CountEnemiesInRange(player.pos, 315) > 0 and clone.pos:dist(target) < 310 then 
                        Count = Count + 1
                    end
                end 
            end 
        end  

        if Count > 0 then 
            player:castSpell('self', 2)
        elseif player.pos:dist(target) < 310 then 
            player:castSpell('self', 2)
        end 

        if WillDie(target, 2) then 
            SwapByCountingEnemies()
            return 
        end

    end 
end

local function CastR(target)

    if not target then 
        return 
    end 
    if target.pos:dist(player) <= 625 then 
        if player:spellSlot(3).state == 0 and target ~= nil and IsR1() then 
            player:castSpell('obj', 3, target)
        end
    end
end

local function Combo(target)
    if target ~= nil then 
        if (player:spellSlot(3).state == 0 and IsR1() and menu.combo[target.charName] and not menu.combo[target.charName]:get() and not IsCombo2()) then 
            if menu.combo.r:get() then 
                CastR(target)
            end

            if menu.combo.Prevent:get() then 
                return 
            end 
        end

        if menu.combo.w:get() and NeedsW(target) then 
            CastW(target)
        end 

        if menu.combo.e:get() then 
            CastE(target)
        end

        if menu.combo.e:get() then 
            CastQ(target)
        end
    end 
end 

local function Harass(target)
    if target ~= nil then 
        if (IsHarass2()) then 
            if ShouldWaitMana() then 
                return 
            end

            if (menu.harass.WE:get() and player:spellSlot(1).state == 0 and IsW1() and player:spellSlot(2).state == 0 and not common.IsInRange(700 + 310, target, player)) then 
                return 
            end 

            CastW(target);
            CastE(target);
            CastQ(target);
        else 

            if common.GetPercentMana(player) >=  menu.harass.mana:get() then 
                CastE(target);
                CastQ(target);
            end 

        end

    end 
end 

local function invoke__lane_clear()
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
        if cast_pos and max_count > menu.lane.laneclear['LaneClear.Q']:get() then
            player:castSpell("pos", 0, cast_pos)
        end
    end
end

local function LaneClear()
    if common.GetPercentMana(player) > menu.lane.laneclear['LaneClear.ManaPercent']:get() then
        local count = 0
        for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion and common.IsValidTarget(minion) then 
                if minion.pos:dist(player) < 625 then 
                    count = count + 1
                end 
                if count >= menu.lane.laneclear['LaneClear.E']:get() then 
                    if (orb.farm.predict_hp(minion, 0.25) < dlib.GetSpellDamage(2, minion)) then
                        player:castSpell("self", 2, player)
                    else 
                        player:castSpell("self", 2, player)
                    end 
                end
            end 
        end
        invoke__lane_clear() 
    end
end 

local function JungleClear()
    if common.GetPercentMana(player) > menu.lane.jungle['LaneClear.ManaPercent']:get() then
        local count = 0
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] -1 do 
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if minion and common.IsValidTarget(minion) then 
                if minion.pos:dist(player) < 625 then 
                    count = count + 1
                end 
                if GetMinionsHit(minion, 310) >= 0 and menu.lane.jungle.e:get() then 
                    CastE(minion)
                end 
            end 
        end  
        if menu.lane.jungle.q:get() then 
            invoke__lane_clear()
        end
    end
end 

local function LastHit()
    if common.GetPercentMana(player) > menu.lane.last['LaneClear.ManaPercent']:get() then
        local count = 0
        for i = 0, objManager.minions.size[TEAM_ENEMY] -1 do 
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion and common.IsValidTarget(minion) then 
                if minion.pos:dist(player) < 625 then 
                    count = count + 1
                end 
                if count >= 2 and menu.lane.last['LastHit.Q']:get() == 2 then 
                    if (orb.farm.predict_hp(minion, 0.25) < dlib.GetSpellDamage(0, minion)) then
                        CastQ(minion)
                    end 
                elseif count > 0 and menu.lane.last['LastHit.Q']:get() == 3 then 
                    if (orb.farm.predict_hp(minion, 0.25) < dlib.GetSpellDamage(0, minion)) then
                        CastQ(minion)
                    end 
                end 
            end 
        end
    end
end

local function GetPassiveDamage(target)
    local damage = 0
    if (100 * target.health / target.maxHealth <= 50) then
        if target.buff['zedpassivecd'] then 
            return 0
        end
        damage = common.CalculateMagicDamage(target, player, (target.maxHealth * (player.levelRef - 0.1) / 0.6) * .2 + .6) / 100
    end
    return damage
end

local function Swap(target)
    if target ~= nil then 
        local distanceSqr = player.pos:dist(target);
        local health = common.GetShieldedHealth("AD", target);

        local IsKillable = (dlib.GetSpellDamage(0, target) + dlib.GetSpellDamage(2, target) + dlib.GetSpellDamage(3, target)) + GetPassiveDamage(target)

        local wShadowDistance = 0
        local rShadowDistance = 0
        if (EnemyIsDead and menu.auto.SwapDead:get() or (menu.combo.SwapDead:get() and orb.combat.is_active())) then 
            SwapByCountingEnemies()
        end 

        if (orb.combat.is_active()) then 
            if (menu.combo.SwapHP:get() >= common.GetPercentHealth(player)) then 
                if (IsKillable < health or common.GetPercentHealth(player) < common.GetPercentHealth(target)) then 
                    SwapByCountingEnemies()
                end
            elseif menu.combo.SwapGapclose:get() and distanceSqr >= 315 then 

                if WShadowIsValid() and player:spellSlot(1).state == 0 then  
                    for _, K in pairs(GetSoldiers()) do
                        if K then 
                            if not common.IsUnderDangerousTower(K.pos) then 
                                wShadowDistance = target.pos:dist(K)
                            end
                        end 
                    end
                end
            
                if RShawdowIsValid() and player:spellSlot(3).state == 0 then 
                    for _, K in pairs(GetSoldierR()) do
                        if K then 
                            if not common.IsUnderDangerousTower(K.pos) then 
                                rShadowDistance = target.pos:dist(K)
                            end
                        end 
                    end
                end

                local min = math.min(math.min(wShadowDistance, rShadowDistance), distanceSqr);
                if (min <= 500 and min < distanceSqr) then 
                    if (math.abs(min - wShadowDistance) < 315) then
                        player:castSpell('self', 1, player)
                    elseif (math.abs(min - rShadowDistance) < 315) then 
                        player:castSpell('self', 3, player)
                    end
                end 
            end
        elseif orb.menu.hybrid.key:get() then 
            if menu.harass.SwapGapclose:get() and player:spellSlot(1).state == 0 and not IsW1() and WShadowIsValid() and common.GetPercentHealth(target) <= 50 and GetPassiveDamage(target) > 0 and IsKillable > health then 
                for _, WShadow in pairs(GetSoldiers()) do
                    if WShadow then 
                        if distanceSqr > WShadow.pos:dist(target) and WShadow.pos:distSqr(target) <= 315 ^ 2 and common.GetPercentHealth(target) <= common.GetPercentHealth(player) then 
                            player:castSpell('self', 1, player)
                        end 
                    end 
                end 
            end
        end
    end 
end

local function AutoQ()
    local target = common.GetTarget(915)

    if target then 

        if player:spellSlot(0).state == 0 and target ~= nil then 
            local seg = pred.linear.get_prediction(Q.pred_input, target)
            if seg and seg.startPos:dist(seg.endPos) <= (Q.Range) then
                if not pred.collision.get_prediction(Q.pred_input, seg, target) and pred_filter(seg, Q.pred_input, target) then 
                    player:castSpell('pos', 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end 
            end
        end
    end 
end

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
    for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) and common.IsEnemyMortal(enemies) then

            local health = common.GetShieldedHealth("AD", enemies);

            --local IsKillable = (dlib.GetSpellDamage(0, target) + dlib.GetSpellDamage(2, target) + dlib.GetSpellDamage(3, target)) + GetPassiveDamage(target)

            if menu.kill.useQ:get() and dlib.GetSpellDamage(0, enemies) > health and enemies.pos:dist(player) <= Q.Range then 
                CastQ(enemies)
            end 

            if menu.kill.useW:get() and common.GetPercentHealth(player) < 20 and NeedsW(enemies) and enemies.pos:dist(player) <= 700 then  
                player:castSpell('pos', 1, enemies.pos)
            end

            if menu.kill.useE:get() and dlib.GetSpellDamage(2, enemies) > health and  enemies.pos:dist(player) <= 350 then   
                CastE(enemies)
            end 
        end 
    end 
end 

local function OnTick()
    if (player.isDead and not player.isTargetable and  player.buff[17]) then return end


    KillSteal()
    Range = Q.Range 
    if WShadowIsValid() and RShawdowIsValid() then 
        for _, WShadow in pairs(GetSoldiers()) do
            if WShadow then 
                Range = Q.Range + player.pos:dist(WShadow) 
            end 
        end
    elseif IsW1() and player:spellSlot(1).state == 0 and RShawdowIsValid() then  
        for _, RShadow in pairs(GetSoldierR()) do
            if RShadow then 
                Range = Q.Range + (player.pos:dist(RShadow) + 700);
            end 
        end
    elseif WShadowIsValid() then 
        for _, Sombra in pairs(GetSoldiers()) do
            if Sombra then 
                Range = Q.Range + (player.pos:dist(Sombra))
            end 
        end
    elseif IsW1() and player:spellSlot(1).state == 0 then 
        Range = 900 + 700
    end 

    if (WShadowIsValid()) then 
        for _, Sombra in pairs(GetSoldiers()) do
            if Sombra then 
                Q._QSource = Sombra
            end 
        end
    end
    EnemyIsDead = false
    local enemy = common.GetEnemyHeroes()
    for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) and common.IsEnemyMortal(enemies) then
            if IsDead(enemies) then 
                EnemyIsDead = true
            end
        end 
    end
    if (W.LastCastTime > 0 and WShadowIsValid() and os.clock() - W.LastCastTime <= GetArrivalTime(W.LastEndPosition, 0.25, 1750) and Q._QSource ~= nil) then 
        Q.Range = 916 + W.LastEndPosition:dist(Q._QSource);
    else 
        Q.Range = 916 
    end

    --zedrtargetmark
    --zedrdeathmark
    --GetShadowCreate()
    --[[for i, buff in pairs(player.buff) do 
        if buff and buff.valid then 
            if  buff.name:lower():find("zed") then
                print(buff.name)
            end 
        end --zacqslow, ZacQMissile
    end]]

    local target = TargetPred.get_result(function(res, obj, dist)
        if dist > Range and (obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
            return
        end
        if dist <= Range then 
            if obj and common.IsValidTarget(obj) then
                res.obj = obj
                return true
            elseif obj  and TargetHaveR(obj) and not IsDead(obj) then 
                res.obj = obj
                return true
            end 
        end
    end).obj

    if target and target ~= nil then 
        if orb.menu.combat.key:get() then 
            Combo(target)
        elseif orb.menu.hybrid.key:get() then 
            Harass(target)
        end

        Swap(target)

    end 

    if orb.menu.lane_clear.key:get() then 
        LaneClear()
        JungleClear()
    elseif orb.menu.last_hit.key:get() then 
        LastHit()
    end 
 
    if menu.misc.autoq:get() and not orb.menu.combat.key:get() then
        AutoQ()
    end 
end 
cb.add(cb.tick, OnTick)

local function OnCreate(obj)
    if obj and obj.name:find("R_buf_tell") then --R_buf_tell
        IsDeadObject[obj.ptr] = obj 
    end 
    if obj then 
        if  obj.name:find("_Clone_Idle") then --R_cloneswap_buf R_Dash _Clone_Idle
            R_IsDash = true
        end 
    end
end 
cb.add(cb.create_particle, OnCreate)

local function OnDelente(obj)
    if obj then 
        IsDeadObject[obj.ptr] = nil 
        R_IsDash = false
    end
end
cb.add(cb.delete_particle, OnDelente)

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 916, 1, menu.draws.qcolor:get(), 40)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 700, 1, menu.draws.wcolor:get(), 40)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 315, 1, menu.draws.ecolor:get(), 40)
        end
        if (menu.draws.rrange:get() and player:spellSlot(3).state == 0) then
            graphics.draw_circle(player.pos, 625, 1, menu.draws.rcolor:get(), 40)
        end

        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.misc.autoq:get() then
			graphics.draw_text_2D("Auto Q: On", 18, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Auto Q: Off", 18, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
        end

        if IsCombo2() then
			graphics.draw_text_2D("Combo without R: On", 18, pos.x - 30, pos.y + 55, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Combo without R: Off", 18, pos.x - 30, pos.y + 55, graphics.argb(255, 255, 255, 255))
        end


        if IsHarass2() then
			graphics.draw_text_2D("Harass W > E > Q: On", 18, pos.x - 30, pos.y + 68, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Harass W > E > Q: Off", 18, pos.x - 30, pos.y + 68, graphics.argb(255, 255, 255, 255))
        end
    end

    local pi = math.pi
    local pointsSmall = {}
    local pointsLarge = {}
    local drawPoints = {}
    local resolution = 35
    for i=1,resolution do
        local PX, PZ = A2V(pi*i/(resolution/3.5), 300)
        pointsSmall[#pointsSmall+1] = {x = PX, z = PZ}
        local PX, PZ = A2V(pi*i/(resolution/3.5)+(resolution/70), 325)
        pointsLarge[#pointsLarge+1] = {x = PX, z = PZ}
    end

    if CountSoldiers() > 0 then
        for _,k in pairs(GetSoldiers()) do
            local X,Y,Z = k.x, k.y, k.z
            if k.team == TEAM_ALLY and common.GetDistance(player, k) <= 670 then
                graphics.draw_circle_xyz(k.x, k.y, k.z, 325, 1, graphics.argb(255, 102, 255, 179), 100)
                graphics.draw_circle_xyz(k.x, k.y, k.z, 300, 1, graphics.argb(255, 102, 255, 179), 100)
            elseif k.team == TEAM_ALLY and common.GetDistance(k, player) > 670 then
                graphics.draw_circle_xyz(k.x, k.y, k.z, 325, 1, graphics.argb(255, 234, 153, 153), 100)
                graphics.draw_circle_xyz(k.x, k.y, k.z, 300, 1, graphics.argb(255, 234, 153, 153), 100)
            end
            for i,v in ipairs(pointsSmall) do
                if i > 1 and i < #pointsSmall then
                    local nextPointL = pointsLarge[i-1]
                    local nextPointS = pointsSmall[i+1]
                    if k.team == TEAM_ALLY and common.GetDistance(player, k) <= 670 then
                        graphics.draw_line(vec3(X+v.x, Y, Z+v.z), vec3(X+nextPointL.x, Y, Z+nextPointL.z), 1, graphics.argb(255, 102, 255, 179))
                        graphics.draw_line(vec3(X+nextPointL.x, Y, Z+nextPointL.z), vec3(X+nextPointS.x, Y, Z+nextPointS.z), 1, graphics.argb(255, 102, 255, 179))
                    elseif k.team == TEAM_ALLY and common.GetDistance(player, k) >= 670 then
                        graphics.draw_line(vec3(X+v.x, Y, Z+v.z), vec3(X+nextPointL.x, Y, Z+nextPointL.z), 1, graphics.argb(255, 234, 153, 153))
                        graphics.draw_line(vec3(X+nextPointL.x, Y, Z+nextPointL.z), vec3(X+nextPointS.x, Y, Z+nextPointS.z), 1, graphics.argb(255, 234, 153, 153))
                    end
                end
            end
        end
    end

    for _, obj in pairs(objHolder) do
        if objTimeHolder[obj.ptr] and objTimeHolder[obj.ptr] < math.huge and obj.team == player.team then
            if objTimeHolder[obj.ptr] > os.clock() then
                local pos = graphics.world_to_screen(vec3(obj.x, obj.y, obj.z))
                if obj.name:find("Shadow") and (objTimeHolder[obj.ptr] - os.clock()) >= 4 then
                    graphics.draw_text_2D("Death:" ..math.floor(objTimeHolder[obj.ptr] - os.clock()).."s", 20, pos.x - 20, pos.y + 40, graphics.argb(255, 102, 255, 179))
                elseif obj.name:find("Shadow") and (objTimeHolder[obj.ptr] - os.clock()) < 4 then
                    graphics.draw_text_2D("Death:" ..math.floor(objTimeHolder[obj.ptr] - os.clock()).."s", 20, pos.x - 20, pos.y + 40, graphics.argb(255, 234, 153, 153))
                end
            else
                objHolder[obj.ptr] = nil
                objTimeHolder[obj.ptr] = nil
            end
        end
    end
end 
cb.add(cb.draw, OnDraw)
cb.add(cb.create_minion, on_create_minion)

local function on_cast_spell(slot, startpos, endpos, nid)
    if slot == 1 then 
        W.LastEndPosition = vec3(startpos.x, startpos.y, startpos.z)
    end 
end

cb.add(cb.castspell, on_cast_spell)