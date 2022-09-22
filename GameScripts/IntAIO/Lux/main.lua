local gpred = module.internal("pred")
local TS = module.internal('TS')
local orb = module.internal("orb");
local common = module.load(header.id, "Library/common")
local damageLib = module.load(header.id, 'Library/damageLib');
local evade = module.seek("evade")
--[[
    Q - Delay: 0.25 Speed: 1200 Width: 70 Range: 1300.0000261845
    Q - Delay: 0.25 Speed: 1200 Width: 50 Range: 1300.0000261845
 
    E - Delay: 0.25 Speed: 1200 Width: 0 Range: 1095.0250784848

    W - Delay: 0.25 Speed: 2174.4855957031 Width: 110 Range: 1173.9999062526
    W - Delay: 0.25 Speed: 166.75285339355 Width: 110 Range: 1173.9999062526

    R -  Delay: 0.25 Speed: 3600 Width: 60 Range: 3296.6085095413


    Buff: LuxIlluminatingFraulein
]]

local Dragons = { "SRU_Dragon_Water", 
"SRU_Dragon_Fire", 
"SRU_Dragon_Earth", 
"SRU_Dragon_Air", 
"SRU_Dragon_Elder" };
local Barons = { "SRU_Baron", "SRU_RiftHerald" };
local Buffs = { "SRU_Red", "SRU_Blue" };

local q_pred = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 1200,
    width = 50,
    range = 1300,
    collision = { hero = true, minion = true, wall = true }
}

local w_spells = {
    range = 1175; 

    protection = {
        speed = 2175;
        delay = 0.25;
        width = 110;
    }; 
}

local e_pred = {
    boundingRadiusModSource = 0,
    boundingRadiusMod = 0,
    delay = 0.25,
    speed = 1200,
    radius = 50,
    range = 1095,
    collision = { hero = false, minion = false, wall = true },
}

local r_pred = {
    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 1,
    speed = 3600,
    width = 60,
    range = 3300, 

    collision = { hero = false, minion = false, wall = false },
}

local core = {
    on_end_func = nil,
    on_end_time = 0,
    f_spell_map = {},
}

local menu = menu("IntnnerLux", "Int Lux")
menu:header("xs", "Core");
menu:menu("combo", "Combo Settings")

menu.combo:header("q_set", "Light Binding"); --Q 
menu.combo:boolean('q', 'Use Q', true);
menu.combo:boolean('ignore', '^ Ignore collision with minion', true);

menu.combo:header("w_set", "Prismatic Barrier"); --W
menu.combo:boolean('w', 'Use W', true);
menu.combo.w:set('tooltip', 'it is necessary to use evade!')

menu.combo:header("e_set", "Lucent Singularity"); --E 
menu.combo:keybind('switch', 'Mode Switch Key', 'G', nil)
menu.combo:boolean('e', 'Use E', true);
menu.combo.switch:set('callback', function(var)
    if menu.combo.use:get() == 1 and var then
        menu.combo.use:set("value", 2)
        return
    end
    if menu.combo.use:get() == 2 and var then
        menu.combo.use:set("value", 3)
        return
    end
    if menu.combo.use:get() == 3 and var then
        menu.combo.use:set("value", 1)
        return
    end
end)
menu.combo:dropdown("use", "Lucent Singularity", 2, { "Always", "Stun", "Disabled" })

menu.combo:header("r_set", "Final Spark"); --R
menu.combo:boolean('r', 'Use R', true);
menu.combo:boolean('rshot', '^~ KillShot', true);
menu.combo:slider("nouseR", "Min. Health of enemy {0} >", 5, 1, 100, 1);

menu:menu("harass", "Harass Settings")
menu.harass:header("q_set", "Light Binding"); --Q 
menu.harass:boolean('q', 'Use Q', true);
menu.harass:boolean('ignore', '^ Ignore collision with minion', true);
menu.harass:slider("mana", "Min. Mana Percent {0} >", 65, 1, 100, 1);

menu:header("misc", "Misc");
menu:boolean("QGapcloser", "Use Q on hero gapclosing / dashing", true);
menu:boolean("EGapcloser", "Use E on hero dashing", true);
menu:boolean('kill', 'Smart KillSteal', true);
menu:header("shi", "Shield Settings");
menu:boolean("use", "Use W for Ally", true)
menu:menu("x", "Ally Selection")
for i = 0, objManager.allies_n - 1 do
	local ally = objManager.allies[i]
	if ally and ally ~= player then
		menu.x:boolean(ally.charName, "Shield: "..ally.charName, false)
	end 
end
menu:slider("ahp", "HP {0%} To Shield Ally", 10, 0, 100, 5)


menu:header("xd", "Others");
menu:boolean("Jesus", "Jesus stealing Dragon/Baron", true)
menu.Jesus:set("tooltip", "Jesus will try to steal the dragon/baron with his ultimate")
menu:menu("draws", "Drawings")
menu.draws:slider("width", "Width/Thickness", 1, 1, 10, 1)
menu.draws:slider("numpoints", "Numpoints (quality of drawings)", 40, 15, 100, 5)
  menu.draws.numpoints:set("tooltip", "Higher = smoother but more FPS usage")
menu.draws:boolean("q_range", "Draw Q Range", true)
menu.draws:color("q", "Q Drawing Color", 255, 255, 255, 255)
menu.draws:boolean("w_range", "Draw W Range", true)
menu.draws:color("w", "W Drawing Color", 255, 255, 255, 255)
menu.draws:boolean("e_range", "Draw E Range", true)
menu.draws:color("e", "E Drawing Color", 255, 255, 255, 255)
menu.draws:boolean("r_range", "Draw R Range on minimap", true)
menu.draws:color("r", "R Drawing Color", 255, 255, 255, 255)

local function ver_trace_filter(Input, seg, obj)
    local totalDelay = (Input.delay + network.latency)
  
    if seg.startPos:dist(seg.endPos)
            + (totalDelay * obj.moveSpeed)
            + obj.boundingRadius > Input.range then
        return false
    end
  
    local collision = gpred.collision.get_prediction(Input, seg, obj)
    if collision then
        return false
    end
  
    if gpred.trace.linear.hardlock(Input, seg, obj) then
        return true
    end
  
    if gpred.trace.linear.hardlockmove(Input, seg, obj) then
        return true
    end
  
    local t = obj.moveSpeed / Input.speed
  
    if gpred.trace.newpath(obj, totalDelay, totalDelay + t) then
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
  
        local seg = gpred.linear.get_prediction(input, obj)
  
        if not seg then
            return false
        end
  
        res.seg = seg
        res.obj = obj
  
        if not ver_trace_filter(input, seg, obj) then
            return false
        end
  
        local t1 = Compute(input, seg, obj)
  
        if t1 < 0 then
            return false
        end
  
        res.pos = (gpred.core.get_pos_after_time(obj, t1) + seg.endPos) / 2
  
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

local hard_cc = {
    [5] = true, -- stun
    [8] = true, -- taunt
    [11] = true, -- snare
    [18] = true, -- sleep
    [21] = true, -- fear
    [22] = true, -- charm
    [24] = true, -- suppression
    [28] = true, -- flee
    [29] = true, -- knockup
    [30] = true, -- knockback
}

local function CanPlayerMove(obj)
    local obj = obj or player

    for _, buff in pairs(obj.buff) do
        if hard_cc[buff.type] then
            return true
        end
    end
    return false
end

local function InAARange(point, target)
    local point = point.pos or player.pos
    if (orb.combat.is_active()) then
        local vecTarget = vec3(target.x, target.y, target.z)
        return point:dist(vecTarget) <= common.GetAARange() + 100
    else
        return #common.CountEnemiesInRange(point, common.GetAARange()) > 0
    end
end

local trace_filter = function(pred_input, seg, obj)
    if gpred.trace.linear.hardlock(pred_input, seg, obj) then
        if obj.path.serverPos:dist(player.path.serverPos) <= common.GetAARange(obj) then
            return false
        end
        return true
    end
    if gpred.trace.linear.hardlockmove(pred_input, seg, obj) then
        return true
    end
    if gpred.trace.newpath(obj, 0.033, 0.500) then
        return true
    end
end

local circular_trace_filter = function(pred_input, seg, obj)
    if menu.combo.use:get() == 2 then
        if gpred.trace.circular.hardlock(pred_input, seg, obj) then
            return true
        end
        if gpred.trace.circular.hardlockmove(pred_input, seg, obj) then
            return true
        end
    end
    if gpred.trace.newpath(obj, 0.033, 0.500) then
        return true
    end
end

core.on_end_q = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end
  
core.on_cast_q = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_q
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end
  
core.on_end_e = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end
  
core.on_cast_e = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_e
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end
  
core.on_end_r = function()
    core.on_end_func = nil
    orb.core.set_pause(0)
end
  
core.on_cast_r = function(spell)
    if os.clock() + spell.windUpTime > core.on_end_time then
        core.on_end_func = core.on_end_r
        core.on_end_time = os.clock() + spell.windUpTime
        orb.core.set_pause(math.huge)
    end
end

local function CastQ(target)
    if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1170 * 1170) then
		local seg = gpred.linear.get_prediction(q_pred, target)
		if seg and seg.startPos:distSqr(seg.endPos) < (1170 * 1170) then
			if not gpred.collision.get_prediction(q_pred, seg, target) then
                if trace_filter(q_pred, seg, target) then 
				    player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end
			else
				if table.getn(gpred.collision.get_prediction(q_pred, seg, target)) == 1 and menu.combo.ignore:get() then
					player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y));
				end
			end
		end
	end
end 

local function CastE(target)
    if player:spellSlot(2).state == 0 and player:spellSlot(2).name ~= "LuxLightstrikeToggle" and player.path.serverPos:distSqr(target.path.serverPos) < (1090 * 1090) then
		local res = gpred.circular.get_prediction(e_pred, target)
		if res and res.startPos:distSqr(res.endPos) < (1090 * 1090)  and circular_trace_filter(e_pred, res, target) then
			player:castSpell("pos", 2, vec3(res.endPos.x, target.y, res.endPos.y))
		end
	end
end 

local function CastR(target)
    if player:spellSlot(3).state == 0 then
		local seg = gpred.linear.get_prediction(r_pred, target)
		if seg and seg.startPos:distSqr(seg.endPos) < (r_pred.range * r_pred.range) then
			if  #common.GetAllyHeroesInRange(500, target.pos) < 1 then
                if trace_filter(r_pred, seg, target) then 
				    player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end
			end
		end
	end
end

local function combo()
    if core.on_end_func and os.clock() + network.latency > core.on_end_time then
        core.on_end_func()
    end

    if menu.combo.use:get() == 1 and menu.combo.e:get() and (player.mana > player.manaCost3 + player.manaCost0) then -- alware
        local target = common.GetTarget(e_pred.range) 

        if target and common.IsValidTarget(target) then 
            CastE(target)
        end

        if player:spellSlot(2).name == "LuxLightstrikeToggle" then 
            player:castSpell('self', 2)
        end
    end 

    if menu.combo.q:get() and (player.mana > player.manaCost3) then 
        local target = TS.get_result(real_target_filter(q_pred).Result) 

        if target.pos and common.IsValidTarget(target.obj) then 
            if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.obj.path.serverPos) < (1170 * 1170) then
                player:castSpell("pos", 0, vec3(target.pos.x, mousePos.y, target.pos.y))

                if menu.combo.ignore:get() then 
                    local seg = gpred.linear.get_prediction(q_pred, target.obj)
                    if seg and seg.startPos:distSqr(seg.endPos) < (1170 * 1170) then
                        if gpred.collision.get_prediction(q_pred, seg, target.obj) then
                            if table.getn(gpred.collision.get_prediction(q_pred, seg, target.obj)) == 1 then
                                player:castSpell("pos", 0, vec3(seg.endPos.x, target.obj.y, seg.endPos.y));
                            end
                        end
                    end
                end
            end
        end
    end 

    if menu.combo.use:get() == 2 and menu.combo.e:get() and (player.mana > player.manaCost3 + player.manaCost0) then
        local target = common.GetTarget(e_pred.range) 
        if player.levelRef > 1 then 

            if target and common.IsValidTarget(target) then 
                if CanPlayerMove(target) then
                    CastE(target)
                end

                if player:spellSlot(2).name == "LuxLightstrikeToggle" then 
                    player:castSpell('self', 2)
                end
            end
        else 
            local target = common.GetTarget(e_pred.range) 

            if target and common.IsValidTarget(target) then 
                CastE(target)
            end
    
            if player:spellSlot(2).name == "LuxLightstrikeToggle" then 
                player:castSpell('self', 2)
            end
        end
    end

    if menu.combo.r:get() then 
        local target = TS.get_result(real_target_filter(r_pred).Result) 

        if target.pos and common.IsValidTarget(target.obj) then 
            if common.GetPercentHealth(target.obj) > menu.combo.nouseR:get() then 
                if damageLib.GetSpellDamage(3, target.obj) > common.GetShieldedHealth("AP", target.obj) then
                    player:castSpell("pos", 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                elseif (damageLib.GetSpellDamage(3, target.obj) + damageLib.GetSpellDamage(2, target.obj))  > common.GetShieldedHealth("AP", target.obj) then 
                    if player:spellSlot(2).name == "LuxLightstrikeToggle" then
                        player:castSpell("pos", 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                    end
                end
            end 
        end 
    end
end

local function harass()
    if menu.harass.q:get() and (common.GetPercentMana(player) > menu.harass.mana:get()) then 
        local target = common.GetTarget(q_pred.range) 

        if target and common.IsValidTarget(target) then 
            if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1170 * 1170) then
                local seg = gpred.linear.get_prediction(q_pred, target)
                if seg and seg.startPos:distSqr(seg.endPos) < (1170 * 1170) then
                    if not gpred.collision.get_prediction(q_pred, seg, target) then
                        if trace_filter(q_pred, seg, target) then 
                            player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    else
                        if table.getn(gpred.collision.get_prediction(q_pred, seg, target)) == 1 and menu.harass.ignore:get() then
                            player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y));
                        end
                    end
                end
            end
        end 
    end 
end

local function autoAllyUlt()
	if menu.use:get() and evade then
		for i = 0, objManager.allies_n - 1 do
			local ally = objManager.allies[i]
			if player:spellSlot(1).state == 0 and ally and not ally.isDead and not player.isDead and ally.pos:dist(player.pos) <= w_spells.range and common.GetPercentHealth(ally) <= menu.ahp:get() and #common.GetEnemyHeroesInRange(800, ally.pos) >= 1 then
				if menu.x[ally.charName] and menu.x[ally.charName]:get() and common.GetPercentHealth(player) > common.GetPercentHealth(ally) then
					player:castSpell("pos", 1, ally.path.serverPos)
				end
            end
            
            if ally and common.IsValidTarget(ally) and ally.pos:dist(player.pos) <= w_spells.range then 
                if menu.x[ally.charName] and menu.x[ally.charName]:get()  then 
                    for i=evade.core.targeted.n, 1, -1 do
                        local spell = evade.core.targeted[i]
                        if spell and spell.owner.team == TEAM_ENEMY  and spell.target.ptr == ally.ptr then 
                            local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(ally)
                            if player:spellSlot(1).state == 0 then 
                                if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", ally) then 
                                    player:castSpell("pos", 1, ally.path.serverPos)
                                end 
            
                                if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", ally) then 
                                    player:castSpell("pos", 1, ally.path.serverPos)
                                end
                            end
                        end
                    end 
            
                    for i=evade.core.skillshots.n, 1, -1 do
                        local spell = evade.core.skillshots[i]
                        if spell and spell.owner.team == TEAM_ENEMY and spell:contains(ally) then 
                            local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(ally)
                            if player:spellSlot(1).state == 0 then 
                                if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", ally) then 
                                    player:castSpell("pos", 1, ally.path.serverPos)
                                end 
            
                                if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", ally) then 
                                    player:castSpell("pos", 1, ally.path.serverPos)
                                end
                            end
                        end
                    end 
                end 
            end 
		end
	end
end

local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and common.IsEnemyMortal(enemy) then
		    local hp = common.GetShieldedHealth("AP", enemy)
      	    local dist = player.path.serverPos:distSqr(enemy.path.serverPos)
			if player:spellSlot(0).state == 0 and dist <= (1180 * 1180) and damageLib.GetSpellDamage(3, enemy) > hp then
				CastQ(enemy)
			elseif player:spellSlot(2).state == 0 and dist <= (1100 * 1100) and damageLib.GetSpellDamage(2, enemy) > hp then
				CastE(enemy)
                if player:spellSlot(2).name == "LuxLightstrikeToggle" then 
                    player:castSpell('self', 2)
                end
			elseif player:spellSlot(3).state == 0 and damageLib.GetSpellDamage(3, enemy) > hp and dist < (r_pred.range * r_pred.range) and player.pos:dist(enemy.pos) >= 600 then
				CastR(enemy)
			end
		end
	end
end

local function gabCloser()
    local target = TS.get_result(function(res, obj, dist)
        if dist > 2500 or common.GetPercentHealth(obj) > 40 then
            return
        end
        if dist <= (1170 + obj.boundingRadius) and obj.path.isActive and obj.path.isDashing then
            res.obj = obj
            return true
        end
    end).obj
    if target then

        if menu.QGapcloser:get() then
            local pred_pos = gpred.core.lerp(target.path, network.latency + q_pred.delay, target.path.dashSpeed)
            if pred_pos and pred_pos:dist(player.path.serverPos2D) > common.GetAARange() and pred_pos:dist(player.path.serverPos2D) <= 1200 then
                player:castSpell("pos", 0, vec3(pred_pos.x, target.y, pred_pos.y))
            end
        end 

        if menu.EGapcloser:get() then 
            local pred_pos = gpred.core.lerp(target.path, network.latency + e_pred.delay, target.path.dashSpeed)
            if pred_pos and pred_pos:dist(player.path.serverPos2D) > common.GetAARange() and pred_pos:dist(player.path.serverPos2D) <= 1200 then
                player:castSpell("pos", 2, vec3(pred_pos.x, target.y, pred_pos.y))
            end
        end
    end
end

local function dragon_selling_baron()
    for i=0, objManager.minions.size[TEAM_NEUTRAL]-1 do
        local object = objManager.minions[TEAM_NEUTRAL][i]

        if object and common.isValidTarget(object) then 
            if object.name:find("Dragon") or object.name:find("Herald") or object.name:find("Baron") then
                local health = orb.farm.predict_hp(object, r_pred.delay)
                if object.path.serverPos:dist(player.path.serverPos) <= r_pred.range then 
                    if (damageLib.GetSpellDamage(3, object) >= health) then 
                        player:castSpell("pos", 3, object.path.serverPos)
                    end 
                end
            end
        end
    end 
end

local function on_tick()
    if (player.isDead) then 
        return 
    end 
    
    if core.on_end_func and os.clock() + network.latency > core.on_end_time then
        core.on_end_func()
    end

    autoAllyUlt()
    if menu.kill:get() then
        KillSteal()
    end

    gabCloser()

    if menu.Jesus:get() then 
        dragon_selling_baron()
    end 

    if orb.combat.is_active() then
        combo()
    elseif orb.menu.hybrid:get() then
        harass() 
    end 

    if menu.combo.w:get() then 
        if evade then 
            for i=evade.core.targeted.n, 1, -1 do
                local spell = evade.core.targeted[i]
                if spell and spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO and spell.target.ptr == player.ptr then 
                    player:castSpell("pos", 1, game.mousePos)
                end 
            end

            for i=evade.core.skillshots.n, 1, -1 do
                local spell = evade.core.skillshots[i]
                if spell.missile and spell.missile.speed then
                    if spell and spell.owner.team == TEAM_ENEMY and spell:contains(player) then  
                        local hit_time = (player.path.serverPos:dist(spell.missile.pos) - player.boundingRadius) / spell.missile.speed
                        if hit_time > (network.latency) and hit_time < (0.25 + network.latency) then 
                            player:castSpell("pos", 1, game.mousePos)
                        end
                    end 
                end
            end
        end
    end

    if #common.CountAllysInRange(player.pos, 1170) == 0 then 
        if evade then 
            for i=evade.core.targeted.n, 1, -1 do
                local spell = evade.core.targeted[i]
                if spell and spell.owner.team == TEAM_ENEMY  and spell.target.ptr == player.ptr then 
                    local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
                    if player:spellSlot(1).state == 0 then 
                        if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                            player:castSpell("pos", 1, game.mousePos)
                        end 

                        if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                            player:castSpell("pos", 1, game.mousePos)
                        end
                    end
                end
            end 

            for i=evade.core.skillshots.n, 1, -1 do
                local spell = evade.core.skillshots[i]
                if spell and spell.owner.team == TEAM_ENEMY and spell:contains(player) then 
                    local ad_damage, ap_damage, true_damage, buff_list = evade.damage.count(player)
                    if player:spellSlot(1).state == 0 then 
                        if ((ad_damage + ap_damage) or (ap_damage) or (ad_damage)) > common.GetShieldedHealth("ALL", player) then 
                            player:castSpell("pos", 1, game.mousePos)
                        end 

                        if (ad_damage + ap_damage + true_damage) > common.GetShieldedHealth("ALL", player) then 
                            player:castSpell("pos", 1, game.mousePos)
                        end
                    end
                end
            end 
        end
    end
end 

local function on_recv_spell(spell)
    if spell.owner.ptr == player.ptr then
        if core.f_spell_map[spell.name] then
            core.f_spell_map[spell.name](spell)
        end

        --[[
            LuxLightBinding Q
            LuxPrismaticWave W
            LuxLightStrikeKugel E
            LuxMaliceCannon R
        ]]
    end
end 

--[[local function on_path()
    for i=0, objManager.maxObjects-1 do
        local unit = objManager.get(i)
        if unit and unit.type == TYPE_HERO then
            if unit.path.isDashing then 
                local dash = {}
                local startPos = unit.path.point[0]
                local endPos = unit.path.point[unit.path.count]
                local latency 	= network.latency
                local distance 	= common.GetDistance(startPos, endPos)

                dash.startPos 	= startPos
                dash.endPos 	= endPos
                dash.speed 	= unit.path.dashSpeed
                dash.startT 	= os.clock() - latency / 2000
                dash.endT 	= dash.startT + (distance / unit.path.dashSpeed)
                dash.Namer = unit.charName

                DashHandler[unit.networkID] = dash
            end 
        end 
    end 
end]]

local function on_draw()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then 
        return 
    end
    if (player.isOnScreen) then
        if menu.draws.q_range:get() and player:spellSlot(0).state == 0 then
            graphics.draw_circle(player.pos, q_pred.range, menu.draws.width:get(), menu.draws.q:get(), menu.draws.numpoints:get())
        end
        if menu.draws.w_range:get() and player:spellSlot(1).state == 0 then
            graphics.draw_circle(player.pos, w_spells.range, menu.draws.width:get(), menu.draws.w:get(), menu.draws.numpoints:get())
        end
        if menu.draws.e_range:get() and player:spellSlot(2).state == 0 then
            graphics.draw_circle(player.pos, e_pred.range, menu.draws.width:get(), menu.draws.e:get(), menu.draws.numpoints:get())
        end

        --Status 
        local pos = graphics.world_to_screen(player.pos)
        if menu.combo.use:get() == 1 then
            graphics.draw_text_2D("[" .. menu.combo.switch.key .. "]Mode E: Always", 25, pos.x - 95, pos.y + 65, graphics.argb(255, 0, 255, 0))
        end
        if menu.combo.use:get() == 2 then
            graphics.draw_text_2D("[" .. menu.combo.switch.key .. "]Mode E: Stun", 25, pos.x - 95, pos.y + 65, graphics.argb(255, 0, 255, 0))
        end
        if menu.combo.use:get() == 3 then
            graphics.draw_text_2D("[" .. menu.combo.switch.key .. "]Mode E: Disabled", 25, pos.x - 95, pos.y + 65, graphics.argb(255, 255, 0, 0))
        end
    end
    if menu.draws.r_range:get() and player:spellSlot(3).state == 0 then
        minimap.draw_circle(player.pos, r_pred.range, 1, menu.draws.r:get(), 100)
    end
end 

core.f_spell_map["LuxLightBinding"] = core.on_cast_q
core.f_spell_map["LuxLightStrikeKugel"] = core.on_cast_e
core.f_spell_map["LuxMaliceCannon"] = core.on_cast_r

orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.draw, on_draw)
cb.add(cb.spell, on_recv_spell)
--cb.add(cb.path, on_path)