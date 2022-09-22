local orb = module.internal("orb");
local evade = module.seek('evade');
local common = module.load("int", "Library/util");
local ts = module.load("int", "TargetSelector/targetSelector");
local dlib = module.load('int', 'Library/damageLib');
local damage = module.load("int", "Core/Warwick/damage");
local pred = module.internal("pred")
-->> Spells <<--
local R_Range = 0;
local StartPos = {}
local EndPos = {}
-->>Inter<<--
local Interrupts = {
    "katarinar",
    "drain",
    "consume",
    "absolutezero", 
    "staticfield",
    "reapthewhirlwind",
    "jinxw",
    "jinxr",
    "shenstandunited",
    "threshe",
    "threshrpenta",
    "threshq",
    "meditate",
    "caitlynpiltoverpeacemaker", 
    "volibearqattack",
    "cassiopeiapetrifyinggaze",
    "ezrealtrueshotbarrage",
    "galioidolofdurand",
    "luxmalicecannon", 
    "missfortunebullettime",
    "infiniteduress",
    "alzaharnethergrasp",
    "lucianq",
    "velkozr",
    "xerathlocusofpower2",
    "warwickr",
    "rocketgrabmissile"
}

local spell_date = { }

local menu = menu("fizedwar", "Int Warwick");
ts = ts(menu, 1200, 2)
menu:header("xs", "Core");
ts:addToMenu();
menu:menu('combo', "Combo");
menu.combo:boolean('q', 'Use Q', true);
menu.combo:boolean('quder', '^~ not use Q UnderTower', true);
menu.combo:header("headW", "W - Setting");
menu.combo:boolean('w', 'Use W (not combo)', true);
menu.combo:boolean('wlocal', 'Use W || Location', true);
menu.combo.wlocal:set('tooltip', 'Works when W is active or passive');
menu.combo:header("headE", "E - Setting");
menu.combo:boolean('e', 'Use E', true);
menu.combo:boolean("engage", "^ Use To Engage", true);
menu.combo:slider("daleu", "Daley E", 100, 0, 250, 1);
menu.combo:slider("blacklisthp", "^~ Auto Shield < HP", 25, 0, 100, 1);
menu.combo:menu("ult", "Ultimate - R");
menu.combo.ult:keybind("keymanu", "Manual - R", "G", nil)
menu.combo.ult:boolean('r', 'Use R', true);
menu.combo.ult:dropdown('moder', 'Use R Mode:', 2, {'Disabled', 'Smart', 'Killable'});
menu.combo.ult:slider("Delay", "Delay R(ms)", 0, 0, 1500, 1);
menu.combo.ult:header("headR", "1v1 || R - Setting");
menu.combo.ult:slider("myhp", "Min. MyHero Health <", 35, 0, 100, 1);
menu.combo.ult:slider("Enemyhp", "Min. Enemy Health <", 50, 0, 100, 1);
menu.combo.ult:boolean('necerr', '^~ Use R if necessary', true);
-->>Harass<<--
menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("e", "Use E", false);
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 25, 0, 100, 1);
-->>LaneClear<<--
menu:menu("clear", "Lane/Jungle");
menu.clear:boolean("q", "Use Q", true);
menu.clear:boolean("q", "^~ Q LastHit (Minion)", true);
menu.clear:boolean("e", "Use E", true);
menu.clear:slider("Mana", "Minimum Mana Percent >= {0}", 10, 1, 100, 1);
-->>Misc<<--
menu:menu("misc", "Misc");
menu.misc:boolean("egab", "Use E on hero inter/dashing", true);
-->>Display<<--
menu:menu("dis", "Display");
menu.dis:boolean("qd", "Q Range", true);
menu.dis:boolean("wd", "W Range", false);
menu.dis:boolean("ed", "E Range", false);
menu.dis:boolean("rd", "R Range", true);

local lastDebugPrint = 0
local function on_process_spells(spell)
    if menu.combo.engage:get() then
        if common.GetPercentHealth(player) < menu.combo.blacklisthp:get() then
            if spell.name:find("BasicAttack") or spell.name:find("CritAttack") then
                if common.GetPercentHealth(player) > 25 then
                    return
                end
            end

            local owner = spell.owner
            if spell.owner.team == TEAM_ENEMY and spell.owner.type == player.type then
                if spell.target and spell.target == player then
                    if player:spellSlot(2).state == 0 and player.pos:dist(owner.pos) <= 385 then
                        player:castSpell("self", 2)
                    end
                end
            end
        end
    end
    -->>Spell Inter<<--
    if not spell or not spell.name or not spell.owner then return end
	if spell.owner.isDead then return end
	if spell.owner.team == player.team then return end
    if player.pos:dist(spell.owner.pos) > player.attackRange + (player.boundingRadius) then return end	
    
    for i = 0, #Interrupts do 
        if (Interrupts[i] == string.lower(spell.name)) then
            spell_date.start = os.clock();
            spell_date.owner = spell.owner;
        end
    end 
end 

local function Combo()
    local target = ts.target;
    if target then 
        if menu.combo.ult.r:get() then 
            local modeR = menu.combo.ult.moder:get(); 
            if (modeR == 2) then 
                local Prediction_R = {
                    range = R_Range,
                    delay = 0.10000000149012, 
                    width = 55, 
                    speed = math.huge,
                    boundingRadiusMod = 1,
                    type = 'linear',
                    collision = {
                        hero = true,
                        minion = false
                    }
                };
                if #common.GetEnemyHeroesInRange(375, target.pos) >= 2 and player.pos2D:dist(target.pos2D) < R_Range then
                    local seg = pred.linear.get_prediction(Prediction_R, target)
                    if seg and seg.startPos:dist(seg.endPos) < R_Range then
                        local col = pred.collision.get_prediction(Prediction_R, seg, target)
                        if not col then
                            player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    end
                elseif player.pos2D:dist(target.pos2D) < R_Range and dlib.GetSpellDamage(3, target) > common.getShieldedHealth("AD", target) then 
                    local seg = pred.linear.get_prediction(Prediction_R, target)
                    if seg and seg.startPos:dist(seg.endPos) < R_Range then
                        local col = pred.collision.get_prediction(Prediction_R, seg, target)
                        if not col and player:spellSlot(3).state == 0 then
                            player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    end
                elseif (#common.GetEnemyHeroesInRange(375, target.pos) >= 2 or #common.GetAllyHeroesInRange(675, target.pos) > 1) and player.pos2D:dist(target.pos2D) < R_Range then
                    local seg = pred.linear.get_prediction(Prediction_R, target)
                    if seg and seg.startPos:dist(seg.endPos) < R_Range then
                        local col = pred.collision.get_prediction(Prediction_R, seg, target)
                        if not col and player:spellSlot(3).state == 0 then
                            player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    end
                end
                if menu.combo.ult.necerr:get() then
                    if common.GetPercentHealth(player) < common.GetPercentHealth(target) then 
                        local seg = pred.linear.get_prediction(Prediction_R, target)
                        if seg and seg.startPos:dist(seg.endPos) < R_Range then
                            local col = pred.collision.get_prediction(Prediction_R, seg, target)
                            if not col and player:spellSlot(3).state == 0 then
                                player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                            end
                        end
                    end
                end
            elseif (modeR == 3) then 
                local Prediction_R = {
                    range = R_Range,
                    delay = 0.10000000149012, 
                    width = 55, 
                    speed = math.huge,
                    boundingRadiusMod = 1,
                    type = 'linear',
                    collision = {
                        hero = true,
                        minion = false
                    }
                };
                if player.pos2D:dist(target.pos2D) < R_Range and dlib.GetSpellDamage(3, target) > common.getShieldedHealth("AD", target) then 
                    local seg = pred.linear.get_prediction(Prediction_R, target)
                    if seg and seg.startPos:dist(seg.endPos) < R_Range then
                        local col = pred.collision.get_prediction(Prediction_R, seg, target)
                        if not col and player:spellSlot(3).state == 0 then
                            player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    end
                end
            end
            if player:spellSlot(3).state == 0 then
                if common.GetPercentHealth(player) < menu.combo.ult.myhp:get() and common.GetPercentHealth(player) < menu.combo.ult.Enemyhp:get() then 
                    local Prediction_R = {
                        range = R_Range,
                        delay = 0.10000000149012, 
                        width = 55, 
                        speed = math.huge,
                        boundingRadiusMod = 1,
                        type = 'linear',
                        collision = {
                            hero = true,
                            minion = false
                        }
                    };
                    local seg = pred.linear.get_prediction(Prediction_R, target)
                    if seg and seg.startPos:dist(seg.endPos) < R_Range then
                        local col = pred.collision.get_prediction(Prediction_R, seg, target)
                        if not col and player:spellSlot(3).state == 0 then
                            player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    end
                end
            end
        end
        if menu.combo.ult.keymanu:get() then 
            if player:spellSlot(3).state == 0 then
                local Prediction_R = {
                    range = R_Range,
                    delay = 0.10000000149012, 
                    width = 55, 
                    speed = math.huge,
                    boundingRadiusMod = 1,
                    type = 'linear',
                    collision = {
                        hero = true,
                        minion = false
                    }
                };
                local seg = pred.linear.get_prediction(Prediction_R, target)
                    if seg and seg.startPos:dist(seg.endPos) < R_Range then
                        local col = pred.collision.get_prediction(Prediction_R, seg, target)
                        if not col and player:spellSlot(3).state == 0 then
                            player:castSpell("pos", 3, vec3(seg.endPos.x, target.y, seg.endPos.y))
                        end
                    end
            end 
        end
        if menu.combo.q:get() then
            if player.pos2D:dist(target.pos2D) < 350 + (player.boundingRadius) and target.pos2D:dist(player.pos2D) > common.GetAARange() then
                local Position = player.pos + (target.pos - player.pos):norm() * 350
                if menu.combo.quder:get() then 
                    --if not common.IsUnderEnemyTower(Position) then
                        if player:spellSlot(0).state == 0 then
                            player:castSpell("obj", 0, target);
                        end
                    --end
                else 
                    if player:spellSlot(0).state == 0 then
                        player:castSpell("obj", 0, target);
                    end
                end
            elseif player.pos2D:dist(target.pos2D) < 350 + (player.boundingRadius) and target.pos2D:dist(player.pos2D) < common.GetAARange() then
                if player:spellSlot(0).state == 0 then
                    player:castSpell("obj", 0, target);
                end
            end
        end
        if menu.combo.e:get() then 
            local buff_e = common.getBuffValid(player, 'WarwickE')
            local buff_start = common.getBuffStartTime(player, 'WarwickE')
            if player.pos2D:dist(target.pos2D) < 375 then 
                if not buff_e then
                    if player:spellSlot(2).state == 0 then
                        player:castSpell("self", 2);
                    end
                elseif buff_e then 
                    if buff_start > menu.combo.daleu:get() then
                        if player:spellSlot(2).state == 0 then
                            player:castSpell("self", 2);
                        end
                    end 
                end
            end
        end
    end
end 

local function Harass()
    local target = ts.target;
    if target then 
        if (menu.harass.q:get()) then
            if player.pos2D:dist(target.pos2D) < 350 + (player.boundingRadius) and target.pos2D:dist(player.pos2D) > common.GetAARange() then
                local Position = player.pos + (target.pos - player.pos):norm() * 350
                if menu.combo.quder:get() then 
                    --if not common.IsUnderEnemyTower(Position) then
                        if player:spellSlot(0).state == 0 then
                            player:castSpell("obj", 0, target);
                        end
                   -- end
                else 
                    if player:spellSlot(0).state == 0 then
                        player:castSpell("obj", 0, target);
                    end
                end
            elseif player.pos2D:dist(target.pos2D) < 350 + (player.boundingRadius) and target.pos2D:dist(player.pos2D) < common.GetAARange() then
                if player:spellSlot(0).state == 0 then
                    player:castSpell("obj", 0, target);
                end
            end
        end
        if (menu.harass.e:get()) then
            local buff_e = common.getBuffValid(player, 'WarwickE')
            local buff_start = common.getBuffStartTime(player, 'WarwickE')
            if player.pos2D:dist(target.pos2D) < 375 then 
                if not buff_e then
                    if player:spellSlot(2).state == 0 then
                        player:castSpell("self", 2);
                    end
                elseif buff_e then 
                    if buff_start > 200 then
                        if player:spellSlot(2).state == 0 then
                            player:castSpell("self", 2);
                        end
                    end 
                end
            end
        end
    end
end 

local function LaneClear()
    for i, minion in pairs(common.GetMinionsInRange(400)) do 
        if minion and minion.isTargetable and not minion.isDead and minion.isVisible and player.path.serverPos:distSqr(minion.path.serverPos) <= (400 * 400) then
            if player:spellSlot(0).state == 0 and damage.q_damage(minion) > minion.health then
                player:castSpell("obj", 0, minion);
            end
        end
    end
end

local function JungleClear()
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local minion = objManager.minions[TEAM_NEUTRAL][i]
        if minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and minion.type == TYPE_MINION then
            if player.path.serverPos:distSqr(minion.path.serverPos) <= (400 * 400) then
                if player:spellSlot(0).state == 0 and damage.q_damage(minion) > minion.health then
                    player:castSpell("obj", 0, minion);
                elseif player:spellSlot(0).state == 0 then 
                    player:castSpell("obj", 0, minion);
                end
                local buff_e = common.getBuffValid(player, 'WarwickE')
                local buff_start = common.getBuffStartTime(player, 'WarwickE')
                if player.pos2D:dist(minion.pos2D) < 375 then 
                    if not buff_e then
                        if player:spellSlot(2).state == 0 then
                            player:castSpell("self", 2);
                        end
                    elseif buff_e then 
                        if buff_start > 200 then
                            if player:spellSlot(2).state == 0 then
                                player:castSpell("self", 2);
                            end
                        end 
                    end
                end
            end
        end 
    end
end 

local function on_tick()
    if (player.isDead) then return end  

    if ts.target and ts.target.pos:dist(player.pos) < common.GetAARange(ts.target) then
        orb.combat.target = ts.target
    end

    R_Range = mathf.round(player.moveSpeed * 1.90, 0)
    --[[if player.buff[string.lower('WarwickE')] then
        print('')
    end]]

    if menu.misc.egab:get() then 
        if spell_date.owner then 
            if player.pos:dist(spell_date.owner.pos) < 375 + (player.boundingRadius) then
                local buff_e = common.getBuffValid(player, 'WarwickE')
                if player:spellSlot(2).state == 0 and not buff_e then 
                    if os.clock() - 0.35 >= spell_date.start then
                        player:castSpell("self", 2);
                        if player.pos:dist(spell_date.owner.pos) < 375 + (player.boundingRadius) and buff_e then 
                            player:castSpell("self", 2);
                            spell_date.owner = false;
                        end
                    end 
                elseif player:spellSlot(2).state == 0 and buff_e then
                    if os.clock() - 0.35 >= spell_date.start then
                        player:castSpell("self", 2);
                    end
                end
            end
        end
    end

    if (orb.combat.is_active()) then 
        Combo();
    end

    if (orb.menu.hybrid:get()) then
        if (player.mana / player.maxMana) * 100 > menu.harass.Mana:get() then 
            Harass();
        end
    end

    if (orb.menu.lane_clear:get()) then 
        if (player.mana / player.maxMana) * 100 >= menu.clear.Mana:get() then 
            LaneClear();
        end
        if (player.mana / player.maxMana) * 100 >= menu.clear.Mana:get() then 
            JungleClear();
        end
    end

    -->>Exploit<<--
    for i, target in pairs(common.getEnemyHeroes()) do 
        if target and common.IsValidTarget(target) then 
            if damage.q_damage(target) > common.getShieldedHealth("AD", target) then 
                if player.pos2D:dist(target.pos2D) < 350 + (player.boundingRadius) then 
                    player:castSpell('line', 0, target.pos, vec3(100000, 60, 100000))
                end
            end
        end
    end
end

--[[52:32] Created Warwick_Base_W_ScentTrail_Self_Path
[52:32] Created Warwick_Base_W_tar_overhead
[52:32] Created Warwick_Base_W_cas
[52:32] Created Warwick_Base_W_tar_overhead
[52:32] Created Warwick_Base_W_CameraBoundVFX_Near
[52:32] Created Warwick_Base_W_CameraBoundVFX_Initial_Near
[52:32] Created Warwick_Base_W_tar_overhead
[52:32] Created Warwick_Base_W_Tar
[52:32] Created Warwick_Base_W_EyeGlow_L
[52:32] Created Warwick_Base_W_EyeGlow_R
[52:32] Created Warwick_Base_R_Range_Ring_Grow
[52:33] Created Warwick_Base_R_Range_Ring
[52:36] Created Warwick_Base_W_ScentTrail_Self_Path
[52:38] Created Warwick_Base_W_ScentTrail_Self_Path
[52:41] Created Warwick_Base_W_ScentTrail_Self_Path --sTARTpos
[52:42] Created Warwick_Base_W_Tar --ENDPOS
[52:42] Created Warwick_Base_R_Range_Ring_Shrink
[52:43] Created Warwick_Base_R_Range_Ring]]
local function on_create_particle(obj)
    if obj then 
        --if obj.name and obj.name:lower():find("warwick") then print("Created "..obj.name) end
        if obj.name:find("Base_W_ScentTrail_Self_Path") then
            StartPos[obj.ptr] = obj
        end
        if obj.name:find("W_Tar") then
            EndPos[obj.ptr] = obj
        end 
    end
end

local function on_delete_particle(obj)
    if obj then 
        StartPos[obj.ptr] = nil
        EndPos[obj.ptr] = nil
    end
end

local function on_draw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.dis.qd:get()) then 
            graphics.draw_circle(player.pos, 350, 1, graphics.argb(255, 172, 236, 128), 30)
        end
        if (player:spellSlot(1).state == 0 and menu.dis.wd:get()) then 
            minimap.draw_circle(player.pos, 4000, 1, graphics.argb(255, 172, 236, 128), 30)
        end
        if (player:spellSlot(2).state == 0 and menu.dis.ed:get()) then 
            graphics.draw_circle(player.pos, 375, 1, graphics.argb(255, 172, 236, 128), 30)
        end
        if (player:spellSlot(3).state == 0 and menu.dis.rd:get()) then 
            graphics.draw_circle(player.pos, R_Range, 1, graphics.argb(255, 172, 236, 128), 30)
        end
    end
    if menu.combo.wlocal:get() then
        for i, Ending in pairs(EndPos) do 
            local PosTo = graphics.world_to_screen(player.pos)
            local EndingPosition = graphics.world_to_screen(Ending.pos)
            graphics.draw_line_2D(PosTo.x, PosTo.y, EndingPosition.x, EndingPosition.y, 2, graphics.argb(255, 0, 255, 255))
            graphics.draw_circle(Ending.pos, 250, 2, graphics.argb(255, 247, 67, 97), 100)
            minimap.draw_circle(Ending.pos, player.moveSpeed, 2, graphics.argb(255, 172, 236, 128), 100)
        end
    end
end 

orb.combat.register_f_pre_tick(on_tick);

cb.add(cb.draw, on_draw);
cb.add(cb.spell, on_process_spells);
cb.add(cb.create_particle, on_create_particle);
cb.add(cb.delete_particle, on_delete_particle);
