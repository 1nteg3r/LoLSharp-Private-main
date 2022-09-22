local orb = module.internal("orb");
local evade = module.seek('evade');
local TS = module.internal("TS")
local gpred = module.internal("pred")
local common = module.load(header.id, "Library/common");

local IsPreAttack = false;
--[[ 
Spell name: ViegoQ 
Speed:20
Width: 70
Time:0.1924884468317
Animation: 0.1924884468317
false
CastFrame: 0.13749174773693
 --------------------------------------
[04:22] Spell name: ViegoW
[04:22] Speed:500
[04:22] Width: 0
[04:22] Time:0
[04:22] Animation: 1
[04:22] false
[04:22] CastFrame: 0.13749174773693
[04:22] --------------------------------------
[04:27] Spell name: ViegoE
[04:27] Speed:1200
[04:27] Width: 70
[04:27] Time:0
[04:27] Animation: 0
[04:27] false
[04:27] CastFrame: 0.13607893884182
[04:27] --------------------------------------
[04:39] Spell name: ViegoR
[04:39] Speed:500
[04:39] Width: 0
[04:39] Time:0.5
[04:39] Animation: 0.5
[04:39] false
[04:39] CastFrame: 0.13164450228214
[04:39] --------------------------------------
]]

local menu = menu("IntnnerViego", "Int Viego");
menu:header("xs", "Core");
menu:menu('combo', "Combat Settings");

menu.combo:header('xd', "Blade of the Ruined King") --Q
    menu.combo:boolean('q', 'Use Ruined King', true);

menu.combo:header('xxd', "Spectral Maw") --W
    menu.combo:boolean('w', 'Use Spectral Maw', true);
    menu.combo:boolean('wadvance', '^~ Advance Maw', false);

menu.combo:header('xxE', "Harrowed Path") --E
    menu.combo:boolean('e', 'Use Harrowed Path', true);
    menu.combo:slider("e.count", "^ Min. Enemy in range {0}", 2, 1, 5, 1);
    menu.combo:boolean('erun', '^ if enemy running away', true);

menu.combo:header('xxER', "Heartbreaker") --R
    menu.combo:dropdown('Combo.Style', 'Select Priority:', 2, {'Advance', 'Best Damage'});
    menu.combo:boolean('r', 'Use Heartbreaker', true);
    menu.combo:boolean('rtower', 'Dont R IsUnderTower', true);

menu:menu("harass", "Hybrid Settings")
    menu.harass:header('xd', "Blade of the Ruined King") --Q
    menu.harass:boolean('q', 'Use Ruined King', true);

menu:menu("clear", "Lane Clear Settings")
    menu.clear:menu("q", "Q Settings")
    menu.clear.q:boolean('q', 'Use Blade of the Ruined King', true)
    menu.clear.q:slider('min_q', 'Minimum minions to hit', 3, 1, 5, 1)

menu:menu("kill", "KillSteal");
    menu.kill:boolean('useQ', 'Use Q for KillSteal', true)
    menu.kill:boolean('useE', 'Use W for KillSteal', true)
    menu.kill:boolean('egab', 'Use R for KillSteal', true)

menu:menu('flee', "Flee")
    menu.flee:boolean('fleeE', 'Use E to Flee', true)
    menu.flee:keybind("keyFlee", "^ Hot-Key Flee", "Z", nil)

menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("rrange", "Draw R Range", false)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)


local scale = {250, 290, 330, 370, 400, 430, 450, 470, 490, 510, 530, 540, 550};
local function r_damage()
	if player.levelRef < 6 then return 0 end
	local dmg = scale[player.levelRef - 5];
	local bonus = player.flatPhysicalDamageMod;
	return (dmg + (bonus * 0.6));
end

local function trace_filter(pred_input, seg, obj)
    if seg.startPos:distSqr(seg.endPos) > 1380625 then
		return false
	end
    if seg.startPos:distSqr(obj.path.serverPos2D) > 1380625 then
		return false
	end
	if gpred.trace.linear.hardlock(pred_input, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(pred_input, seg, obj) then
		return true
	end
	if not obj.path.isActive then
		if pred_input.range < seg.startPos:dist(obj.pos2D) + (obj.moveSpeed * 0.333) then
			return false
		end
	end
	if gpred.trace.newpath(obj, 0.033, 0.500) then
		return true
	end
end

local Q = {
    predinput = {
        range = 600,
        delay = 0.19,
        width = 70,
        speed = math.huge,
        boundingRadiusMod = 1,
        collision = {
            hero = false,
            minion = false,
            wall = false,
        },
    },
}
local W = {
    LastCastTime = 0;
    Range = 0;
    CastRangeGrowthMin = 300;
    CastRangeGrowthMax = 900;
    CastRangeGrowthStartTime = 0;
    CastRangeGrowthDuration = 1;
    CastRangeGrowthEndTime = 5;

    w_time = 0;


    predinput = {
        range = 900,
        delay = math.huge,
        width = 120,
        speed = math.huge,
        boundingRadiusMod = 1,
        collision = {
            hero = true,
            minion = true,
            wall = true,
        },
    },
} 

local R = {
    predinput = {
        range = 600,
        delay = 0.5,
        radius = 315,
        speed = 500,
        boundingRadiusMod = 0,
    },
}


local function CastQ(target)
    if not target then 
        return 
    end

    if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (600 * 600) then 
        local seg = gpred.linear.get_prediction(Q.predinput, target)
        if not seg then 
            return  
        end

        if seg and seg.startPos:distSqr(seg.endPos) < (600 * 600) then

            if not trace_filter(Q.predinput, seg, target) then 
                return false 
            end

            player:castSpell("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
            orb.core.set_server_pause()
            return true
        end
    end
end 

local function CastW(target)
    if not target then 
        return 
    end 

    if player:spellSlot(1).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (W.Range * W.Range) then 

        local seg = gpred.linear.get_prediction(W.predinput, target)
        if not seg then 
            return  
        end
        
        local col = gpred.collision.get_prediction(W.predinput, seg, target)
        if col then
            return  
        end

        if seg and seg.startPos:distSqr(seg.endPos) < (W.Range * W.Range) then

            local CastPosition = vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y)
            if (common.getBuffValid(player, 'ViegoW')) then 
                if CastPosition:distSqr(player.pos) <= W.Range * W.Range then
                    player:castSpell('release', 1, CastPosition)
                    orb.core.set_server_pause()
                    return true
                end 
    
            else 
                player:castSpell('pos', 1, mousePos)
            end 
        end
    end
end

local function CastE(target)
    if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1000 * 1000) then 
        if menu.combo.erun:get() and not common.IsFacing(target) and not common.IsMovingTowards(target) then 
            player:castSpell('pos', 2, target.path.serverPos)
        end
        if #common.CountEnemiesInRange(player.pos, 1000) >= menu.combo["e.count"]:get() then 
            player:castSpell('pos', 2, mousePos)
        end 
    end 
end

local function combo()
    local target = common.GetTarget(900)

    if target and common.IsValidTarget(target) then
        if menu.combo.w:get() and not IsPreAttack then 
            CastW(target)
        end 
        if menu.combo.q:get() then 
            CastQ(target)
        end 
        if menu.combo.e:get() then 
            CastE(target)
        end

        if player:spellSlot(3).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (700 * 700) then 
            local seg = gpred.circular.get_prediction(R.predinput, target)
            if not seg then 
                return  
            end
    
            if seg and seg.startPos:distSqr(seg.endPos) < (700 * 700) then
                if common.IsUnderDangerousTower(target.pos) then 
                    return 
                end 

                if r_damage() > common.GetShieldedHealth("AD", target) then 
                    player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                    orb.core.set_server_pause()
                    return true
                end 
            end 
        end
    end
    --[[if menu.combo.w:get() then 
        if player:spellSlot(1).state == 0 then
            local res = TS.get_result(w.filter)
            if res.pos and res.obj then
                local CastPosition = vec3(res.pos.x, res.obj.y, res.pos.y)
                if (common.getBuffValid(player, 'ViegoW')) then 
                    if common.IsInRange(W.Range, CastPosition, player) then
                        player:castSpell('release', 1, CastPosition)
                    end 

                else 
                    player:castSpell('pos', 1, CastPosition)
                end 

            end
        end
    end

    if menu.combo.q:get() then 
        if player:spellSlot(0).state == 0 then 

            if W.w_time > os.clock() then 
                return true 
            end

            local res = TS.get_result(q.filter)
            if res.pos and res.obj then
                player:castSpell('pos', 0, vec3(res.pos.x, res.obj.y, res.pos.y))
                orb.core.set_server_pause()
                return
            end
        end
    end 

    if menu.combo.e:get() then 
        if player:spellSlot(2).state == 0 then 
            if #common.CountEnemiesInRange(player.pos, 1000) >= menu.combo["e.count"]:get() then 
                player:castSpell('pos', 2, mousePos)
            end 

            if menu.combo.erun:get() then 
                local res = TS.get_result(e.filter)
                if res.obj then  
                    if res.obj.pos:dist(player.pos) > 400 then 
                        player:castSpell('pos', 2, res.obj.path.serverPos)
                    end
                end
            end
        end 
    end

    if menu.combo.r:get() then 
        if player:spellSlot(3).state == 0 then 
            local res = TS.get_result(r.filter)
            if res.pos and res.obj then
                player:castSpell('pos', 3, vec3(res.pos.x, res.obj.y, res.pos.y))
                orb.core.set_server_pause()
            end
        end
    end]]
end 

local function harrass()
    if menu.harass.q:get() then
        if player:spellSlot(0).state == 0 then 

            local target = common.GetTarget(600)

            if target and common.IsValidTarget(target) then
                CastQ(target)
            end
        end
    end
end

local function LaneClear()
    if menu.clear.q.q:get() then 
        local valid = {}
        local minions = objManager.minions
        for i = 0, minions.size[TEAM_ENEMY] - 1 do
            local minion = minions[TEAM_ENEMY][i]
            if minion and not minion.isDead and minion.isVisible then
                local dist = player.path.serverPos:distSqr(minion.path.serverPos)
                if dist <= 700 * 700 then
                    valid[#valid + 1] = minion
                end
            end
        end
        local max_count, cast_pos = 0, nil
        for i = 1, #valid do
            local minion_a = valid[i]
            local current_pos = player.path.serverPos + ((minion_a.path.serverPos - player.path.serverPos):norm() * (minion_a.path.serverPos:dist(player.path.serverPos)))
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
            if cast_pos and max_count > 3 then 
                player:castSpell("pos", 0, cast_pos)
            end
        end
    end
end 

local function jungleclear()
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] -1 do 
        local minion = objManager.minions[TEAM_NEUTRAL][i] 
        if minion and common.IsValidTarget(minion) then 
            if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(minion.path.serverPos) < (600 * 600) then 
                local seg = gpred.linear.get_prediction(Q.predinput, minion)
                if not seg then 
                    return  
                end
        
                if seg and seg.startPos:distSqr(seg.endPos) < (600 * 600) then
                    player:castSpell("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                end 
            end 

            if player:spellSlot(1).state == 0 and player.path.serverPos:distSqr(minion.path.serverPos) < (W.Range * W.Range) then 

                local seg = gpred.linear.get_prediction(W.predinput, minion)
                if not seg then 
                    return  
                end
                
        
                if seg and seg.startPos:distSqr(seg.endPos) < (W.Range * W.Range) then
        
                    local CastPosition = vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y)
                    if (common.getBuffValid(player, 'ViegoW')) then 
                        if CastPosition:distSqr(player.pos) > 300 * 300 and CastPosition:distSqr(player) <= W.Range * W.Range then
                            player:castSpell('release', 1, CastPosition)
                            orb.core.set_server_pause()
                            return true
                        end 
            
                    else 
                        player:castSpell('pos', 1, CastPosition)
                    end 
                end
            end
        end 
    end
end 
local function Flee()
    if not menu.flee.keyFlee:get() then 
        return 
    end 

    if menu.flee.fleeE:get() then 
        if player:spellSlot(2).state == 0 then 
            player:castSpell('pos', 2, mousePos)
        end
    end 
end 

local function on_tick()
    if player.isDead then 
        return 
    end 

    IsPreAttack = false
    Flee()

    -- ViegoW
    if (common.getBuffValid(player, 'ViegoW')) then 
        orb.core.set_pause_attack(math.huge)
        local percentGrowth = math.max(0, math.min(1, (1000 * (game.time - W.LastCastTime) / 1000 - W.CastRangeGrowthStartTime) / W.CastRangeGrowthDuration));
        W.Range = ((W.CastRangeGrowthMax - W.CastRangeGrowthMin) * percentGrowth + W.CastRangeGrowthMin);
    else 
        W.Range = W.CastRangeGrowthMax;
        orb.core.set_pause_attack(0)
    end

    if orb.combat.is_active() then
        combo()
    elseif orb.menu.hybrid.key:get() then  
        harrass()
    elseif orb.menu.lane_clear.key:get() then 
        LaneClear()
        jungleclear()
    end 

end 

local function OnProcessSpell(spell)
    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner.charName == "Viego" then 
        --print("Spell name: " ..spell.name);
        if spell.name == "ViegoW" then 
            W.LastCastTime = game.time;
            W.w_time = os.clock() + 1
        end
    end
end 

local function OnPreAttack() 
    IsPreAttack = true;

    
    --[[if player.buff["viegopassivetransform"] then
        if (player.buff["viegopassivetransform"].startTime + 0.25 < game.time) then
            for i = 0, 16 do
                player:sellItem(i)
            end
        elseif (player.buff["viegopassivetransform"].startTime + 0.25 < game.time) then
            for i = 0, 16 do

                player:sellItem(i)
            end
        end
    end]]
end 

local function on_draw()
    if (player and player.isDead and not player.isTargetable and player.buff[17]) then 
        return 
    end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 600, 1, menu.draws.qcolor:get(), 40)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, W.Range, 1, menu.draws.wcolor:get(), 40)
        end
        if (menu.draws.rrange:get() and player:spellSlot(3).state == 0) then
            graphics.draw_circle(player.pos, 500, 1, menu.draws.rcolor:get(), 40)
        end
    end
end

cb.add(cb.tick, on_tick)
orb.combat.register_f_pre_tick(OnPreAttack)
cb.add(cb.spell, OnProcessSpell)
cb.add(cb.draw, on_draw)