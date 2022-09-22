local pred = module.internal("pred");
local TS = module.internal("TS");
local orb = module.internal("orb");
local common = module.load("int", "Library/common");

local PredPos = module.load('int', 'Library/util');
local prediction = module.load('int', 'Core/Caitlyn/prediction');
local isRiot = hanbot.language == 2
local headshot = 'caitlynheadshot';
local caitlynshot = 'caitlynyordletrapsight';
local caitlynletal = 'caitlynyordletrapinternal';
local preAA = false;
local delaye = 0;
local Caitlyn = player;
local Vision = { };
local HoleMissile = { };

local pred_input_q = {
    delay = 0.625,
    speed = 2200,
    width = 90,
    boundingRadiusMod = 1,
    range = 1250,
    collision = {
      minion = false,
      wall = false,
      hero = false,
    },
    type = "linear",
}

local pred_input_e = {
    delay = 0.25,
    speed = math.huge,
    width = math.huge,
    boundingRadiusMod = 1,
    range = 750,
    collision = {
      minion = true, 
      wall = true, 
      hero = true, 
    },
}

local pred_input_w = {
    range = 800,
	delay = 0.50,
	speed = math.huge,
	radius = 20,
	boundingRadiusMod = 0
}

local function trace_filter(seg, obj)
    if seg.startPos:dist(seg.endPos) > pred_input_e.range then
        return false
    end
    if (obj.path.isActive) then
        if pred.trace.newpath(obj, 0.033, 0.500) then
            return true
        end
    end
    if pred.trace.linear.hardlock(pred_input_e, seg, obj) then
        return true
    end
    if pred.trace.linear.hardlockmove(pred_input_e, seg, obj) then
        return true
    end
end

--[[local function GetIsImmobile(target)
    local gerobuff = target.buff;
    local timebuff = {};
    local debugg = {};
    --if bool then
        if gerobuff and gerobuff.valid and (timebuff <= gerobuff.endTime) then
            debugg[gerobuff.type] = true;
        end
        --return
        if debugg[5] or debugg[8] or debugg[11] or debugg[18] or debugg[24] or debugg[29] then
            return true;
        end
    --end
end]]

local function OnVision(unit)
    if Vision[unit.networkID] == nil then 
        Vision[unit.networkID] = {state = unit.isVisible , tick = os.clock(), pos = unit.pos}
    end
    if Vision[unit.networkID].state == true and not unit.isVisible then
        Vision[unit.networkID].state = false Vision[unit.networkID].tick = os.clock()
    end
    if Vision[unit.networkID].state == false and unit.isVisible then
        Vision[unit.networkID].state = true Vision[unit.networkID].tick = os.clock()
    end
	return Vision[unit.networkID]
end

local function HealthPosition(target, damage)
    if target.health - damage > 0 then
        return (target.health - damage) / target.maxHealth
    end
    return 0
end

local function GetHealthBarPos(target)
    return target.barPos
end

local function EndPostion(target, damage)
    local length = HealthPosition(target, damage) * 104
    local x, y = GetHealthBarPos(target)
    local x = x + length
    return x, y
end

--[[[local function DrawDamage(target, damage, nColor)
    if not target.isVisible and target.isDead then return end
    local fromX, fromY = EndPostion(target, 0)
    local toX,   toY   = EndPostion(target, damage)
    local width = 12
    graphics.draw_line(fromX, fromY + 5, toX, toY + 5, width, nColor)
end]]

local function HeadShot()
    return orb.core.can_attack() and not orb.core.is_paused() and not orb.core.is_attack_paused()
end

local menu = menu("IntnnerCaitlyn", "Int Caitlyn");

if isRiot then 
    menu:menu('combo', 'Combo');
    menu.combo:menu('qset', "Peacemaker Settings"); --Snap Trap(800), Caliber Net(750), Ace in the Hol(3500).
    menu.combo.qset:boolean("comboq", "Use Q in Combo", true);
    menu.combo.qset:header("q1", "Peacemaker modules");
    menu.combo.qset:dropdown("qrange", "^ Min. Q Range", 2, {"Always", "Only out AA"});
    menu.combo.qset:boolean("qcc", "Auto Q on CC", true);
    menu.combo.qset:boolean("qkill", "Q Kill Steal", true);
    menu.combo.qset:header("q2", "Peacemaker Drawing");
    menu.combo.qset:boolean("qdrawing", "Range Q spell", true);

    menu.combo:menu('wset', "Snap Trap");
    menu.combo.wset:boolean("combow", "Use W in Combo", true);
    menu.combo.wset:keybind("xtrap", "Manual-Trap", "G", nil)
    menu.combo.wset:header("w1", "Snap Trap modules");
    menu.combo.wset:boolean("Wcc", "Auto W on hard CC", true);
    menu.combo.wset:boolean("FORCE", "Force W before E", true);
    menu.combo.wset:header("W2", "Snap Trap Drawing");
    menu.combo.wset:boolean("wdra", "Range W spell", false);

    menu.combo:menu('eset', "Caliber Net");
    menu.combo.eset:boolean("comboe", "Use E in Combo", true);
    menu.combo.eset:header("e1", "Caliber Net modules");
    menu.combo.eset:boolean("eim", "Auto E immobile target", false);
    menu.combo.eset:boolean("egp", "Gap Closer", true);
    menu.combo.eset:header("e2", "Caliber Net Drawing");
    menu.combo.eset:boolean("edra", "Range E spell", true);

    menu.combo:menu('rset', "Ace in the Hol");
    menu.combo.rset:boolean("combor", "Use R to finish", true);
    menu.combo.rset:header("r1", "Ace in the Hol modules");
    menu.combo.rset:boolean("eim", "Auto R immobile target", false);
    menu.combo.rset:boolean("CHECK", "Check collision?", false);
    menu.combo.rset:slider("range", " ^ Min. Range safe", 950, 1, 1500, 1)
    menu.combo.rset:header("r2", "Ace in the Hol Drawing");
    menu.combo.rset:boolean("edra", "Range R spell (Minimap)", true);

    menu:menu('harass', 'Harass');
    menu.harass:header("hset", "Caitlyn Harass modules");
    menu.harass:boolean("harassq", "Use Q in Harass", true);
    menu.harass:dropdown("qrange", "^ Min. Q Range", 2, {"Always", "Only out AA"});
    menu.harass:boolean("harasse", "Use E in Harass", true);
    menu.harass:header("hset1", "Caitlyn Harass Mana");
    menu.harass:slider("mana", " ^ Min. Mana", 50, 1, 100, 1);

    menu:menu('misc', 'Misc');
    menu.misc:header("mset", "Caitlyn Misc modules");
    menu.misc:boolean("faa", "Force AA", true);
    menu.misc:boolean("ends", "Auto spell on End Dash", true);
    menu.misc:header("mset1", "Misc special spells");
    menu.misc:boolean("useWs", "Use W for special spells", true);

    menu:menu('key', 'Keys');
    menu.key:header("kset", "Caitlyn keys modules");
    menu.key:keybind("combokey", "Combo Key", "Space", nil)
    menu.key:keybind("harakey", "Harass Key", "C", nil)
    menu.key:keybind("lanekey", "Lane Clear Key", "V", nil)
    menu.key:keybind("lastkey", "Last Hit", "X", nil)
else 
    menu:menu('combo', '组合');
    menu.combo:menu('qset', "Peacemaker 设定值"); --Snap Trap(800), Caliber Net(750), Ace in the Hol(3500).
    menu.combo.qset:boolean("comboq", "在组合中使用Q", true);
    menu.combo.qset:header("q1", "Peacemaker modules");
    menu.combo.qset:dropdown("qrange", "^ Min. Q Range", 2, {"Always", "Only out AA"});
    menu.combo.qset:boolean("qcc", "Auto Q on CC", true);
    menu.combo.qset:boolean("qkill", "Q Kill Steal", true);
    menu.combo.qset:header("q2", "Peacemaker Drawing");
    menu.combo.qset:boolean("qdrawing", "Range Q spell", true);

    menu.combo:menu('wset', "Snap Trap");
    menu.combo.wset:boolean("combow", "Use W in Combo", true);
    menu.combo.wset:keybind("xtrap", "Manual-Trap", "G", nil)
    menu.combo.wset:header("w1", "Snap Trap modules");
    menu.combo.wset:boolean("Wcc", "Auto W on hard CC", true);
    menu.combo.wset:boolean("FORCE", "Force W before E", true);
    menu.combo.wset:header("W2", "Snap Trap Drawing");
    menu.combo.wset:boolean("wdra", "Range W spell", false);

    menu.combo:menu('eset', "Caliber Net");
    menu.combo.eset:boolean("comboe", "Use E in Combo", true);
    menu.combo.eset:header("e1", "Caliber Net modules");
    menu.combo.eset:boolean("eim", "Auto E immobile target", false);
    menu.combo.eset:boolean("egp", "Gap Closer", true);
    menu.combo.eset:header("e2", "Caliber Net Drawing");
    menu.combo.eset:boolean("edra", "Range E spell", true);

    menu.combo:menu('rset', "Ace in the Hol");
    menu.combo.rset:boolean("combor", "Use R to finish", true);
    menu.combo.rset:header("r1", "Ace in the Hol modules");
    menu.combo.rset:boolean("eim", "Auto R immobile target", false);
    menu.combo.rset:boolean("CHECK", "Check collision?", false);
    menu.combo.rset:slider("range", " ^ Min. Range safe", 950, 1, 1500, 1)
    menu.combo.rset:header("r2", "Ace in the Hol Drawing");
    menu.combo.rset:boolean("edra", "Range R spell (Minimap)", true);

    menu:menu('harass', 'Harass');
    menu.harass:header("hset", "Caitlyn Harass modules");
    menu.harass:boolean("harassq", "Use Q in Harass", true);
    menu.harass:dropdown("qrange", "^ Min. Q Range", 2, {"Always", "Only out AA"});
    menu.harass:boolean("harasse", "Use E in Harass", true);
    menu.harass:header("hset1", "Caitlyn Harass Mana");
    menu.harass:slider("mana", " ^ Min. Mana", 50, 1, 100, 1);

    menu:menu('misc', 'Misc');
    menu.misc:header("mset", "Caitlyn Misc modules");
    menu.misc:boolean("faa", "Force AA", true);
    menu.misc:boolean("ends", "Auto spell on End Dash", true);
    menu.misc:header("mset1", "Misc special spells");
    menu.misc:boolean("useWs", "Use W for special spells", true);

    menu:menu('key', 'Keys');
    menu.key:header("kset", "Caitlyn keys modules");
    menu.key:keybind("combokey", "Combo Key", "Space", nil)
    menu.key:keybind("harakey", "Harass Key", "C", nil)
    menu.key:keybind("lanekey", "Lane Clear Key", "V", nil)
    menu.key:keybind("lastkey", "Last Hit", "X", nil)
end

TS.load_to_menu(menu)
local TargetSelection = function(res, obj, dist)
	if dist < 1200 then
		res.obj = obj
		return true
	end
end
local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end


--[[cb.add(cb.tick, function()
    if player.buff[headshot] then 
        print('Working');
    end
    local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) then
            if enemies.buff["caitlynyordletrapinternal"] then 
                print("ddd")
            end
            if enemies.charName == 'Shen' then 
                for i = 0, enemies.buffManager.count - 1 do
                    local buff = enemies.buffManager:get(i)
                    if buff and buff.valid then
                        print(buff.name)
                    end 
                end 
            end
        end 
    end
    return;
end)]]

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.combo.qset.qdrawing:get()) then 
            graphics.draw_circle(player.pos, pred_input_q.range, 1, graphics.argb(255, 89, 64, 147), 40)
        end
        if (player:spellSlot(1).state == 0 and menu.combo.wset.wdra:get()) then 
            graphics.draw_circle(player.pos, pred_input_w.range, 1, graphics.argb(255, 89, 64, 147), 40)
        end
        if (player:spellSlot(2).state == 0 and menu.combo.eset.edra:get()) then 
            graphics.draw_circle(player.pos, 750, 1, graphics.argb(255, 89, 64, 147), 40)
        end
    end
    if player:spellSlot(3).state == 0 and common.IsValidTarget(player) then  
        if menu.combo.rset.edra:get() then
            minimap.draw_circle(player.pos, 3500, 1, 0xFFFFFFFF, 16);
        end
    end

    local target = GetTarget();

    if target and common.IsValidTarget(target) then
        --DrawDamage(target.pos, RDamage, 0xFFFFFFFF)
        graphics.draw_circle(target.pos, 100, 2, 0xFFFFFFFF, 10)
    end
end

local function Combo()
    local target = GetTarget();
    local qmode = menu.combo.qset.qrange:get();
    if target and common.IsValidTarget(target) then
        if (menu.combo.eset.comboe:get()) and vec3(target.x, target.y, target.z):dist(Caitlyn) < 750 --[[and Caitlyn.path.serverPos:distSqr(target.path.serverPos) > Caitlyn.path.serverPos:distSqr(target.path.serverPos + target.direction)]] then
            if Caitlyn:spellSlot(2).state == 0 then
                --pred
                local coliton = {
                    minion = 0
                }
                local castpos, HitChance, pos = prediction.GetBestCastPosition(target, math.huge, 70, 700, math.huge, player, true, coliton, "line")
                if (HitChance > 0) then
                    player:castSpell("pos", 2, castpos)
                end
                local castpos, HitChance, Position = prediction.GetBestCastPosition(target, 20, 70, 800, math.huge, player, false, "circular")
                if (HitChance > 0) then
                    player:castSpell("pos", 1, Position)
                end
                local castpos, HitChance, pos = prediction.GetBestCastPosition(target, 0.625, 90, 1250, 2200, player, false, "line")
                if (HitChance > 0) then
                    player:castSpell("pos", 0, castpos)
                end
            end
        end
        if Caitlyn:spellSlot(1).state == 0 and (menu.combo.wset.combow:get()) then
            --local Distancia = (target.pos - player.pos):len() not recmend
            if vec3(target.x, target.y, target.z):dist(Caitlyn) < 800 then
                if preAA == true and (target.buff[caitlynletal] or Caitlyn.path.isDashing) then 
                    local pos = pred.circular.get_prediction(pred_input_w, target)
                    if pos and pos.startPos:dist(pos.endPos) <= pred_input_w.range then
                        Caitlyn:castSpell("pos", 1, vec3(pos.endPos.x, pos.endPos.y, pos.endPos.y))
                    end
                end
            end
        end
        if (menu.combo.qset.comboq:get()) then
            if qmode == 1 then
                --if (menu.combo.qset.comboq:get()) then
                    if Caitlyn:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(Caitlyn) < 1250 then
                        if (target.buff[caitlynletal] or target.buff[18] or target.buff[5]) then
                            local castpos, HitChance, pos = prediction.GetBestCastPosition(target, 0.625, 90, 1250, 2200, player, false, "line")
                            if (HitChance > 0) then
                                player:castSpell("pos", 0, castpos)
                            end
                        end
                    end
                --end
            elseif qmode == 2 then 
                if Caitlyn:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(Caitlyn) < 1250 and vec3(Caitlyn.x, Caitlyn.y, Caitlyn.z):dist(target) > common.GetAARange(Caitlyn) then
                    if (target.buff[caitlynletal] or target.buff[10] or target.buff[18] or target.buff[5]) then
                        local castpos, HitChance, pos = prediction.GetBestCastPosition(target, 0.625, 90, 1250, 2200, player, false, "line")
                        if (HitChance > 0) then
                            player:castSpell("pos", 0, castpos)
                        end
                    end
                end
            end
        end
        if HeadShot() and Caitlyn.buff[headshot] and Caitlyn:spellSlot(2).state == 0 then 
            orb.core.set_pause_attack(math.huge)
            local pos = pred.linear.get_prediction(pred_input_e, target)
            if pos and pos.startPos:dist(pos.endPos) < pred_input_e.range then
                if pred.collision.get_prediction(pred_input_e, pos, target) then return false end
                Caitlyn:castSpell("pos", 2, vec3(pos.endPos.x, player.pos.y, pos.endPos.y))
            end
            Caitlyn:attack(target);
        end
        orb.core.set_pause_attack(0)
    end
end

local function Harass()
    if common.GetPercentMana(player) >= menu.harass.mana:get() then
        local target = GetTarget();
        local qmode = menu.harass.qrange:get();
        if target == nil then return end
        if target and common.IsValidTarget(target) then
            if (menu.harass.harasse:get()) and vec3(target.x, target.y, target.z):dist(Caitlyn) < 750 and Caitlyn.path.serverPos:distSqr(target.path.serverPos) > Caitlyn.path.serverPos:distSqr(target.path.serverPos + target.direction) then
                if Caitlyn:spellSlot(2).state == 0 then
                    --pred
                    local pos = pred.linear.get_prediction(pred_input_e, target)
                    if pos and pos.startPos:dist(pos.endPos) < pred_input_e.range then
                        if pred.collision.get_prediction(pred_input_e, pos, target) then return false end
                        if trace_filter(pos, target) then
                            Caitlyn:castSpell("pos", 2, vec3(pos.endPos.x, player.pos.y, pos.endPos.y))
                        end
                    end
                end
            end
            if (menu.harass.harassq:get()) then
                if qmode == 1 then
                    --if (menu.combo.qset.comboq:get()) then
                        if Caitlyn:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(Caitlyn) < 1250 then
                            ---if (target.buff[caitlynletal] or target.buff[18] or target.buff[5]) then
                                local pos = pred.linear.get_prediction(pred_input_q, target)
                                if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                                    if pos.startPos:dist(pos.endPos) > pred_input_q.range then return false end
                                    if (target.path.isActive) then
                                        if pred.trace.newpath(target, 0.033, 0.500) then return true end
                                    end
                                    if pred.trace.linear.hardlock(pred_input_q, pos, target) then return true end
                                    if pred.trace.linear.hardlockmove(pred_input_q, pos, target) then return true end
                                    Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,  target.pos.y, pos.endPos.y))
                                end
                            --end
                        end
                    --end
                elseif qmode == 2 then 
                    if Caitlyn:spellSlot(0).state == 0 and vec3(target.x, target.y, target.z):dist(Caitlyn) < 1250 and vec3(Caitlyn.x, Caitlyn.y, Caitlyn.z):dist(target) > common.GetAARange(Caitlyn) then
                        -----if (target.buff[caitlynletal] or target.buff[10] or target.buff[18] or target.buff[5]) then
                            local pos = pred.linear.get_prediction(pred_input_q, target)
                            if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                                if pos.startPos:dist(pos.endPos) > pred_input_q.range then return false end
                                if (target.path.isActive) then
                                    if pred.trace.newpath(target, 0.033, 0.500) then return true end
                                end
                                if pred.trace.linear.hardlock(pred_input_q, pos, target) then return true end
                                if pred.trace.linear.hardlockmove(pred_input_q, pos, target) then return true end
                                Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,   player.pos.y, pos.endPos.y))
                            end
                        --end
                    end
                end
            end
        end
    end
    --chat.print('Press')
end
orb.combat.register_f_after_attack(function()
    if (menu.key.combokey:get()) then
        Combo();
    end
end)

local function SpellEndDash()
    if player:spellSlot(2).state == 0 then
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) and enemiess.path.isActive and enemiess.path.isDashing and Caitlyn.pos:dist(enemiess.path.point[1]) < 800 then
                if Caitlyn.pos2D:dist(enemiess.path.point2D[1]) < Caitlyn.pos2D:dist(enemiess.path.point2D[0]) then
                    player:castSpell("pos", 2, enemiess.path.point2D[1])
                end
            end
            if enemiess.path.isActive and enemiess.path.isDashing and Caitlyn.pos:dist(enemiess.path.point[1]) < 800 then
                if Caitlyn.pos2D:dist(enemiess.path.point2D[1]) < Caitlyn.pos2D:dist(enemiess.path.point2D[0]) then
                    player:castSpell("pos", 1, enemiess.path.point2D[1])
                end
            end
        end
    end
end

local function OnPreTick()
    if Caitlyn.isDead and Caitlyn.buff[17] then return end

    --[[local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do
        if target and common.IsValidTarget(target) then
            local result, predPos, hitChance = PredPos.getPrediction(pred_input_q, target)

            if (hitChance > 2) then 
                Caitlyn:castSpell("pos", 0, predPos)
            end
        end 
    end]]
    local target = GetTarget();

    if target and common.IsValidTarget(target) then
        if vec3(target.x, target.y, target.z):dist(Caitlyn) <= 1300  and HeadShot() then
            if target.buff['caitlynyordletrapinternal'] then
                Caitlyn:attack(target);
                orb.core.set_server_pause();
            end
        end
    end
    --Caitlyn:attack(target)
    if menu.misc.faa:get() then
        if (menu.key.lanekey:get() or menu.key.lastkey:get()) then 
            --print('Attack');
            local enemy = common.GetEnemyHeroes()
            for i, enemies in ipairs(enemy) do
                if enemies and common.IsValidTarget(enemies) then
                    if Caitlyn.buff[headshot] and HeadShot() and vec3(enemies.x, enemies.y, enemies.z):dist(Caitlyn) <= common.GetAARange(Caitlyn) then
                        Caitlyn:attack(enemies);
                        orb.core.set_server_pause();
                    end
                end
            end
        end
    end
    if delaye > 0 then 
        preAA = true;
    else 
        preAA = false;
    end

    if (menu.combo.qset.qcc:get()) then 
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) then
                if Caitlyn:spellSlot(0).state == 0 and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) < 1250 and (vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) > 800 or Caitlyn:spellSlot(1).state ~= 0) then
                    if enemiess.buff[caitlynshot] or (enemiess.buff[5] or enemiess.buff[8] or enemiess.buff[11] or enemiess.buff[18] or enemiess.buff[21] or enemiess.buff[22] or enemiess.buff[24] or enemiess.buff[28] or enemiess.buff[29]) then
                        local pos = pred.linear.get_prediction(pred_input_q, enemiess)
                        if pos and pos.startPos:dist(pos.endPos) < pred_input_q.range - 150 then
                            Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x, enemiess.pos.y, pos.endPos.y))
                        end
                    end
                end
            end
        end
    end

    if (menu.combo.wset.Wcc:get())  then
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) then
                if Caitlyn:spellSlot(1).state == 0 and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) < 800 then
                    if enemiess.buff[caitlynshot] or (enemiess.buff[5] or enemiess.buff[8] or enemiess.buff[11] or enemiess.buff[18] or enemiess.buff[21] or enemiess.buff[22] or enemiess.buff[24] or enemiess.buff[28] or enemiess.buff[29]) then
                        local pos = pred.circular.get_prediction(pred_input_w, target)
                        if pos and pos.startPos:dist(pos.endPos) <= pred_input_w.range then
                            Caitlyn:castSpell("pos", 1, vec3(pos.endPos.x, pos.endPos.y, pos.endPos.y))
                        end
                    end
                end
            end
        end
    end

    if (menu.misc.ends:get()) then 
        SpellEndDash();
    end

    if (menu.key.harakey:get()) then
        Harass();
    end

    if (menu.combo.rset.combor:get() and Caitlyn:spellSlot(3).state == 0) then
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) then
                local RBaseDamage = ({ 250, 475, 700 })[Caitlyn:spellSlot(3).level] + 1  * common.GetTotalAD()
                local RDamage = common.CalculatePhysicalDamage(enemiess, RBaseDamage)
                if RDamage - enemiess.healthRegenRate > common.GetShieldedHealth("AD", enemiess) then
                    if Caitlyn:spellSlot(3).state == 0 and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) > menu.combo.rset.range:get() and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) <= 3500 then 
                        if #common.CountEnemiesInRange(player.pos, menu.combo.rset.range:get()) == 0  and #common.CountAllyChampAroundObject(enemiess.pos, 500) == 0 and not common.UnderDangerousTower(Caitlyn.pos) then
                            Caitlyn:castSpell('obj', 3, enemiess);
                            orb.core.set_server_pause();
                        end
                    end
                end
                if (menu.combo.rset.eim:get()) then
                    if (enemiess.buff[5] or enemiess.buff[8] or enemiess.buff[11] or enemiess.buff[18] or enemiess.buff[21] or enemiess.buff[22] or enemiess.buff[24] or enemiess.buff[28] or enemiess.buff[29])  and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) <= 3500 then 
                        if #common.CountEnemiesInRange(player.pos, menu.combo.rset.range:get()) == 0 and #common.CountAllyChampAroundObject(enemiess.pos, 500) > 0 and not common.UnderDangerousTower(Caitlyn.pos) then
                            Caitlyn:castSpell('obj', 3, enemiess);
                        end
                    end
                end
            end
        end
    end

    if (menu.combo.qset.qkill:get() and Caitlyn:spellSlot(0).state == 0) then
        local enemy = common.GetEnemyHeroes()
        for i, enemiess in ipairs(enemy) do
            if enemiess and common.IsValidTarget(enemiess) then
                local QBaseDamage = ({ 30, 70, 110, 150, 190 })[Caitlyn:spellSlot(0).level] + ({1.3, 1.4, 1.5, 1.6, 1.7})[Caitlyn:spellSlot(0).level]  * common.GetTotalAD()
                local QDamage = common.CalculatePhysicalDamage(enemiess, QBaseDamage)
                if QDamage - enemiess.healthRegenRate > common.GetShieldedHealth("AD", enemiess) then
                    if Caitlyn:spellSlot(0).state == 0 and vec3(enemiess.x, enemiess.y, enemiess.z):dist(Caitlyn) < 1250 and vec3(Caitlyn.x, Caitlyn.y, Caitlyn.z):dist(enemiess) > common.GetAARange(Caitlyn) then
                        local pos = pred.linear.get_prediction(pred_input_q, enemiess)
                        if pos and pos.startPos:dist(pos.endPos) <= pred_input_q.range then
                            if pos.startPos:dist(pos.endPos) > pred_input_q.range then return false end
                            if (enemiess.path.isActive) then
                                if pred.trace.newpath(enemiess, 0.033, 0.500) then return true end
                            end
                            if pred.trace.linear.hardlock(pred_input_q, pos, enemiess) then return true end
                            if pred.trace.linear.hardlockmove(pred_input_q, pos, enemiess) then return true end
                            Caitlyn:castSpell("pos", 0, vec3(pos.endPos.x,  player.pos.y, pos.endPos.y))
                        end
                    end
                end
            end
        end
    end

    if menu.combo.wset.xtrap:get() then 
        local target = GetTarget();

        if  target and common.IsValidTarget(target) then 
            local res_pos = pred.core.project(target.pos, target.path, 0.25, 1450, target.moveSpeed)
            if res_pos and Caitlyn.pos2D:dist(res_pos) < pred_input_w.range then 
                if Caitlyn:spellSlot(1).state == 0 then
                    Caitlyn:castSpell("pos", 1, res_pos)
                end
            end
        end
        player:move(game.mousePos)
    end

end

local lastDebugPrint = 0;
local function WSpell(spell)
    if (menu.misc.useWs:get()) then
        if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.owner.charName == "MasterYi" and (spell.name == "Meditate" or spell.name == "ShenR") then
            if Caitlyn.pos2D:dist(spell.owner.pos2D) < pred_input_w.range and common.IsValidTarget(spell.owner) then 
                if Caitlyn:spellSlot(1).state == 0 then 
                    Caitlyn:castSpell("pos", 1, spell.owner.pos)
                end
            end
        end
    end
end

--[[local function on_create_missile(obj) -----CaitlynAceintheHoleMissile     Speed: 3200    CaitlynAceintheHoleMissile
    if obj.name == "CaitlynAceintheHoleMissile" and obj.spell.name == "CaitlynAceintheHoleMissile" then 
        HoleMissile[obj.ptr] =  ({
            obj = obj,
            speed = obj.speed, 
        })
    end
    --print(obj.name, obj.speed, obj.spell.name) delete_missile
end

local function on_delete_missile(obj)
    if obj then 
        HoleMissile[obj.ptr] = nil
    end
end ]]

--cb.add(cb.create_missile, on_create_missile)
--cb.add(cb.delete_missile, on_delete_missile)

orb.combat.register_f_pre_tick(OnPreTick)
cb.add(cb.draw, OnDraw);
cb.add(cb.spell, WSpell)

