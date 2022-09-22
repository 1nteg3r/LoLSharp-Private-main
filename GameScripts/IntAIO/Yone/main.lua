local orb = module.internal("orb")
local ts = module.internal("TS")
local pred = module.internal("pred")
local common = module.load(header.id, "Library/common");

local shadow = nil
local mark = nil
local death = false
local Q1_MAX_WINDUP = 0.35
local Q1_MIN_WINDUP = 0.175
local LOSS_WINDUP_PER_ATTACK_SPEED = (0.35 - 0.3325) / 0.12

local additional_attack_speed = (player.attackSpeedMod - 1)

local q1_delay = math.max(Q1_MIN_WINDUP, Q1_MAX_WINDUP - (additional_attack_speed * LOSS_WINDUP_PER_ATTACK_SPEED))

local q = {
    range = 450,
    delay = q1_delay,
    speed = math.huge,
    width = 80,
    boundingRadiusMod = 1,
    collision = {
        hero = false,
        minion = false,
        wall = false
    },
}
local q2 = {
    range = 985,
    delay = (0.4 * (1 - math.min((player.attackSpeedMod - 1) * 0.58, 0.66))),
    speed = 1500,
    width = 160,
    boundingRadiusMod = 1,
    collision = {
        hero = false,
        minion = false,
        wall = true
    },
}

local w = {
    range = 600,
    delay = (0.4 * (1 - math.min((player.attackSpeedMod - 1) * 0.58, 0.66))),
    speed = math.huge,
    width = 80,
    boundingRadiusMod = 1,
    collision = {
        hero = false,
        minion = false,
        wall = false
    },
}

local pred_r = {
    range = 1000,
    delay = 0.8,
    speed = math.huge,
    width = 225,
    boundingRadiusMod = 1,
}

local menu = menu("IntnnerYone", "Int - Yone")

menu:menu('combo', 'Combo Settings')
menu.combo:menu('qsettings', "Q Settings")
    menu.combo.qsettings:boolean("q", "Use Q", true)
    menu.combo.qsettings:keybind("q_key", "Stack Q", false, "T")
    menu.combo.qsettings:boolean("q3", "Use Q3", true)
menu.combo:menu('wsettings', "W Settings")
    menu.combo.wsettings:boolean("w", "Use W", true)
menu.combo:menu('rsettings', "R Settings")
    menu.combo.rsettings:keybind("r", "Use R on X Enemys", "Z", false)
    menu.combo.rsettings:slider("rx", "^ R If Enemies >=", 3, 1, 5, 1)


menu:menu("harass", "Hybrid/Harass Settings")
menu.harass:menu('qsettings', "Q Settings")
    menu.harass.qsettings:boolean("q", "Use Q", true)
    menu.harass.qsettings:boolean("q3", "Use Q3", true)
menu.harass:menu('wsettings', "W Settings")
    menu.harass.wsettings:boolean("w", "Use W", true)

menu:menu("clear", "Clear/Lane/Jungle Settings")
    menu.clear:header("xd", "Lane Clear Settings")
    menu.clear:boolean("q", "Use Q", true)
    menu.clear:slider("qx", "Use Q If Minions >=", 3, 1, 12, 1)
    menu.clear:header("xd123", "Last Hit Settings")
    menu.clear:boolean("qlh", "Use Q", true)
menu.clear:menu("junglecler", "Jungle Clear")
    menu.clear.junglecler:header("xd", "Jungle Settings")
    menu.clear.junglecler:boolean("q", "Use Q", true)
    menu.clear.junglecler:boolean("w", "Use W", true)

menu:menu("auto", "Misc")
    menu.auto:boolean("uks", "Use Killsteal", true)
    menu.auto:boolean("uksq", "Use Q in Killsteal", true)
    menu.auto:boolean("uksq3", "Use Q3 in Killsteal", true)
    menu.auto:boolean("urks", "Use R in Killsteal", true)
    menu.auto:header("xd", "Fate Sealed Settings")
    menu.auto:boolean("r", "Use R", true)
    menu.auto:slider("rx", "Min. R If Enemies >=", 2, 1, 5, 1)

menu:menu("draws", "Drawings")
    menu.draws:slider("width", "Width/Thickness", 1, 1, 10, 1)
    menu.draws:slider("numpoints", "Numpoints (quality of drawings)", 40, 15, 100, 5)
    menu.draws.numpoints:set("tooltip", "Higher = smoother but more FPS usage")
    menu.draws:boolean("q_range", "Draw Q Range", true)
    menu.draws:color("q", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("w_range", "Draw W Range", false)
    menu.draws:color("w", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("e_range", "Draw E Range", false)
    menu.draws:color("e", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("r_range", "Draw R Range", true)
    menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("mark", "Draw Mark Killable", true)
--1050
--160

local trace_filter = function(pred_input, seg, obj)
    if seg.startPos:distSqr(seg.endPos) > pred_input.range * pred_input.range then
        return false
    end
    if seg.startPos:distSqr(obj.path.serverPos2D) > pred_input.range * pred_input.range then
        return false
    end
    if pred.trace.linear.hardlock(pred_input, seg, obj) then
        if pred_input.range <= common.GetAARange(obj) then
            return false
        end
        return true
    end
    if pred.trace.linear.hardlockmove(pred_input, seg, obj) then
        return true
    end
    if pred.trace.newpath(obj, 0.033, 0.500) then
        return true
    end
end
local function OnDraw()
    if (player.isOnScreen) then
        if menu.draws.q_range:get() and player:spellSlot(0).state == 0 then
            if player:spellSlot(0).name == "YoneQ" then
                graphics.draw_circle(player.pos, 450, menu.draws.width:get(), menu.draws.q:get(), menu.draws.numpoints:get())
            else
                graphics.draw_circle(player.pos, 1050, menu.draws.width:get(), menu.draws.q:get(), menu.draws.numpoints:get())
            end
        end
        if menu.draws.w_range:get() and player:spellSlot(1).state == 0 then
            graphics.draw_circle(player.pos, w.range, menu.draws.width:get(), menu.draws.w:get(), menu.draws.numpoints:get())
        end
        if menu.draws.e_range:get() and player:spellSlot(2).state == 0 then
            graphics.draw_circle(player.pos, e.range, menu.draws.width:get(), menu.draws.e:get(), menu.draws.numpoints:get())
        end
        if menu.draws.r_range:get() and player:spellSlot(3).state == 0 then
            graphics.draw_circle(player.pos, 1050, menu.draws.width:get(), menu.draws.r:get(), menu.draws.numpoints:get())
        end
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.combo.qsettings.q_key:get() then
			graphics.draw_text_2D("Stack Q: On", 16, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Stack Q: Off", 16, pos.x - 30, pos.y + 30, graphics.argb(255, 255, 255, 255))
        end
        if menu.draws.mark:get() and shadow and mark then
            local myHeroPos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
            graphics.draw_text_2D("Enemy Killable with E", 16, myHeroPos.x-100, myHeroPos.y+800, graphics.argb(255, 255, 255, 255))
        end
    end
end


local function OnCreateObject(obj)
    if not obj or not obj.name then return end
    if  obj.name:lower():find("testcuberender10vision") then
        shadow = obj
    end
    if obj.name:lower():find("yone") and obj.name:lower():find("mark_execute") then
        mark = obj
        death = true
    end
end

--Yone_Base_W_Shield
--Yone_Base_W_Tar
--Yone_Base_Q1_Tar
--Yone_Base_Q3_Tar
--Yone_Base_R_Tar_Residual

local function OnDeleteObject(obj)
    if (obj) then 
        shadow = nil
        mark = nil
        death = false
    end
end
--Yone_Base_BA_Tar_Crit_02  | Yone_base_BA_Tar_02 AP
--Yone_Base_BA_Tar_Crit_01  | Yone_base_BA_Tar_01 AD

local function UnderTurret(unit)
    if not unit or unit.isDead or not unit.isVisible or not unit.isTargetable then
        return true
    end
    for i=0, objManager.turrets.size[TEAM_ENEMY]-1 do
        local obj = objManager.turrets[TEAM_ENEMY][i]
        if obj and obj.health and obj.health > 0 and common.GetDistanceSqr(obj, unit) <= 900 ^ 2 then
            return true
        end
    end
    return false
end

local function qDmg(target)
    local qDamage = ((25 * player:spellSlot(0).level) - 5 + (common.GetTotalAD() * 1))
    return common.CalculatePhysicalDamage(target, qDamage)
end

local function rDmg(target)
    local rDamageAP = ((100 * player:spellSlot(3).level) + (common.GetTotalAD() * 0.4))
    local rDamageAD = ((100 * player:spellSlot(3).level) + (common.GetTotalAD() * 0.4))
    return common.CalculatePhysicalDamage(target, rDamageAD) + common.CalculateMagicDamage(target, rDamageAP)
end

local function IsCollision(from, Position, hero)
    local from = from or player 
    local buffer = 20 

    local proj2, pointLine, isOnSegment = common.VectorPointProjectionOnLineSegment(from.pos, Position, hero.pos)
    if isOnSegment and (common.GetDistanceSqr(hero, proj2) <= (hero.boundingRadius + buffer + pred_r.width) ^ 2) then
        return true
    end
    return false
end 

local function CountEnemiesInR(endPos)
    local count = 0
    for i=0, objManager.enemies_n-1 do
        local enemy = objManager.enemies[i]
        if enemy and common.isValidTarget(enemy) then
            local col = IsCollision(player, endPos, enemy)
            if col then
                count = count + 1
            end
        end
    end
    return count
end

local function CastQ(target)
    if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "YoneQ" and player.path.serverPos:distSqr(target.path.serverPos) < (q.range * q.range) then 
        local seg = pred.linear.get_prediction(q, target)
        if seg and seg.startPos:distSqr(seg.endPos) <= (q.range * q.range) then
            player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
        end 
    end
end

local function CastQ3(target)
    if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "YoneQ3" then
        local seg = pred.linear.get_prediction(q2, target)
        if seg and seg.startPos:distSqr(seg.endPos) <= (q2.range * q2.range) then
            if not pred.collision.get_prediction(q2, seg, target) then
                player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end
        end 
    end
end

local function CastW(target)
    if player:spellSlot(1).state == 0 then
        local seg = pred.linear.get_prediction(w, target)
        if seg and seg.startPos:distSqr(seg.endPos) < (w.range * w.range) then
            if (trace_filter(w, seg, target)) then 
                player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end
        end     
    end
end

local function CastR(target)
    if player:spellSlot(3).state == 0 then
        local seg = pred.linear.get_prediction(pred_r, target)
        if seg and seg.startPos:distSqr(seg.endPos) < (pred_r.range * pred_r.range) and player.path.serverPos:distSqr(target.path.serverPos) > (q.range * q.range) then  
            if (trace_filter(pred_r, seg, target)) then 
                player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end
        end 
    end
end

local function KillSteal()
    for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and common.IsEnemyMortal(enemy) then
            local hp = common.GetShieldedHealth("AD", enemy)
            local d = common.GetDistanceSqr(enemy)
            local q = player:spellSlot(0).state == 0
            local e = player:spellSlot(2).state == 0
            local r = player:spellSlot(3).state == 0
            local qd = qDmg(enemy)
            local rd = rDmg(enemy)
            if menu.auto.uksq:get() and q and hp < qd and d < (450 * 450) and player:spellSlot(0).name == "YoneQ" then
                CastQ(enemy)
            end
            if menu.auto.uksq3:get() and q and hp < qd and d < (985 * 985) and player:spellSlot(0).name == "YoneQ3" then
                CastQ3(enemy)
            end
            if menu.auto.urks:get() and r and hp < rd and d < (1000 * 1000) then
                CastR(enemy)
            end
            if e and player.mana > 0 and death then
                player:castSpell("pos", 2, mousePos)
            end
            if menu.auto.r:get() and r and d < (1000 * 1000) then
                local seg = pred.linear.get_prediction(pred_r, enemy)
                if seg and seg.startPos:distSqr(seg.endPos) <= (1000 * 1000) and player.path.serverPos:distSqr(enemy.path.serverPos) > (450 * 450) then  
                    if CountEnemiesInR(vec3(seg.endPos.x, enemy.y, seg.endPos.y)) >= menu.auto.rx:get() then
                        if (trace_filter(pred_r, seg, enemy)) then 
                            player:castSpell("pos", 3, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
                        end
                    end
                end
            end
        end
    end
end

local function JungleClear()
    for i=0, objManager.minions.size[TEAM_NEUTRAL]-1 do
        local obj = objManager.minions[TEAM_NEUTRAL][i]
        if obj and obj.maxHealth > 5 and not obj.isDead and obj.isTargetable and not (obj.name:lower():find("camprespawn") or obj.name:lower():find("plant") or obj.charName == "S5Test_WardCorpse") then
            local d = common.GetDistanceSqr(obj)
            if d <= (450 * 450) then
                if menu.clear.junglecler.q:get() and player:spellSlot(0).state == 0 and d <= (450 * 450) then
                    CastQ(obj)
                end
                if menu.clear.junglecler.w:get() and player:spellSlot(1).state == 0 then
                    CastW(obj)
                end
            end
        end
    end
end

local function CountMinQ(endPos)
    local count = 0
    for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
        local enemy = objManager.minions[TEAM_ENEMY][i]
        if enemy and enemy.moveSpeed > 0 and enemy.isTargetable and not enemy.isDead and enemy.isVisible then
            local col = IsCollision(player, endPos, enemy)
            if col then
                count = count + 1
            end
        end
    end
    return count
end

local function LaneClear()
    if player:spellSlot(0).state == 0 and menu.clear.q:get() and player:spellSlot(0).name == "YoneQ" then
        for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
            local minion1 = objManager.minions[TEAM_ENEMY][i]
            if minion1 and minion1.isTargetable and not minion1.isDead and minion1.isVisible and minion1.maxHealth > 5 and common.GetDistanceSqr(minion1) <= (450 * 450) then
                local seg = pred.linear.get_prediction(q, minion1)
                if seg and seg.startPos:distSqr(seg.endPos) <= (1000 * 1000) and common.GetDistanceSqr(seg.endPos) < (450 * 450) then
                    if CountMinQ(vec3(seg.endPos.x, minion1.y, seg.endPos.y)) >= menu.clear.qx:get() then
                        player:castSpell("pos", 0, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
                        break
                    end
                end
            end
        end
    end
end

local function LastHit()
    if player:spellSlot(0).state == 0 and menu.clear.qlh:get() and player:spellSlot(0).name == "YoneQ" then
        for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion and minion.isVisible and minion.isTargetable and not minion.isDead and minion.maxHealth > 5 and common.GetDistanceSqr(minion) <= (450 * 450) then 
                if (not orb.core.can_attack() or (common.GetAARange() < common.GetDistance(minion))) and (qDmg(minion) > minion.health) then
                    CastQ(minion)
                end
            end
        end
    end
end

local function OnTick()
    if player.isDead then 
        return 
    end 

    local ranger = 0 
    if player:spellSlot(0).name == "YoneQ" then 
        ranger = 450 
    else 
        ranger = 985 
    end 

    local target = common.GetTarget(ranger)
    local target2 = common.GetTarget(600)

    if orb.combat.is_active() then
        if target and common.isValidTarget(target) then 
            local q = player:spellSlot(0).state == 0
            if menu.combo.qsettings.q:get() and q and not orb.core.can_attack() then
                CastQ(target)
            end
            if menu.combo.qsettings.q3:get() and q then
                CastQ3(target)
            end
        end 

        if target2 and common.isValidTarget(target2) then 
            local w = player:spellSlot(1).state == 0
            if menu.combo.wsettings.w:get() and w and not orb.core.can_attack() then
                CastW(target2)
            end
        end
    end

    if orb.menu.hybrid.key:get() then
        if target and common.isValidTarget(target) then 
            if menu.harass.qsettings.q:get() and player:spellSlot(0).state == 0 then
                CastQ(target)
            end
            if menu.harass.qsettings.q3:get() and player:spellSlot(0).state == 0 then
                CastQ3(target)
            end
            if menu.harass.wsettings.w:get() and player:spellSlot(1).state == 0 then         
                CastW(target)
            end      
        end
    end

    if menu.auto.uks:get() then 
        KillSteal() 
    end

    if orb.menu.lane_clear.key:get() then 
        JungleClear() 
        LaneClear() 
        LastHit() 
    end
    if orb.menu.last_hit.key:get() then 
        LastHit() 
    end
    if menu.combo.rsettings.r:get() and player:spellSlot(3).state == 0 then
        player:move(mousePos)
        for i=0, objManager.enemies_n-1 do
            local enemy = objManager.enemies[i]
            if enemy and common.isValidTarget(enemy) then
                local seg = pred.linear.get_prediction(pred_r, enemy)
                if seg and seg.startPos:distSqr(seg.endPos) <= (1000 * 1000) then
                    if CountEnemiesInR(vec3(seg.endPos.x, enemy.y, seg.endPos.y)) >= menu.auto.rx:get() then
                        player:castSpell("pos", 3, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
                    end
                end
            end
        end
    end
    if menu.combo.qsettings.q_key:get() and not orb.menu.last_hit.key:get() then
        if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "YoneQ" and #common.CountEnemiesInRange(player.pos, 450) == 0 then
            for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
                local obj = objManager.minions[TEAM_ENEMY][i]
                if obj and obj.isTargetable and obj.maxHealth > 5 and not obj.isDead and common.GetDistanceSqr(obj) <= (450 * 450) then
                    CastQ(obj)
                end
            end
        end
    end
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.create_particle, OnCreateObject)
cb.add(cb.delete_particle, OnDeleteObject)