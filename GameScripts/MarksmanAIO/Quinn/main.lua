local script = { }

local orb = module.internal("orb");
local pred = module.internal("pred")
local evade = module.seek('evade')
local common = module.load(header.id, "common");
local TS = module.internal("TS")
local damage = module.load(header.id, 'damageLib');

local IsPreAttack = false;

script.interrupt = {}

script.interrupt.names = { -- names of dangerous spells
	"glacialstorm";
	"caitlynaceinthehole";
	"ezrealtrueshotbarrage";
	"drain";
	"crowstorm";
	"gragasw";
	"reapthewhirlwind";
	"karthusfallenone";
	"katarinar";
	"lucianr";
	"luxmalicecannon";
	"malzaharr";
	"meditate";
	"missfortunebullettime";
	"absolutezero";
	"pantheonrjump";
	"shenr";
	"gate";
	"varusq";
	"warwickr";
	"xerathlocusofpower2";
}

script.interrupt.times = {6, 1, 1, 5, 1.5, 0.75, 3, 3, 2.5, 2, 0.5, 2.5, 4, 3, 3, 2, 3, 1.5, 4, 1.5, 3}; -- channel times of dangerous spells

local pred_q = {
    range = 1025,
    delay = 0.25,
    speed = 1550,
    boundingRadiusMod = 0,
    width = 60,
    collision = {
        hero = true,
        minion = true,
        wall = true
    },
}

local menu = menu("MarksmanAIOQuinn", "Marksman - ".. player.charName)
menu:menu('combo', 'Combo Settings')
menu.combo:menu('qsettings', "Q Settings")
    menu.combo.qsettings:boolean("qcombo", "Use Q", true)
    menu.combo.qsettings:slider("mana_mngr", "Minimum Mana %", 15, 0, 100, 5)
menu.combo:menu('wsettings', "W Settings")
    menu.combo.wsettings:boolean("wcombo", "Use W", true)
    menu.combo.wsettings:boolean("CCcombo", "Auto W Vision", true)
    menu.combo.wsettings:slider("mana_mngr", "Minimum Mana %", 25, 0, 100, 5)
menu.combo:menu('esettings', "E Settings")
    menu.combo.esettings:boolean("ecombo", "Use E", true)
    menu.combo.esettings:slider("mana_mngr", "Minimum Mana %", 0, 0, 100, 5)
    menu.combo.esettings:header('Another', "Misc Settings")
    menu.combo.esettings:boolean("EnableInterrupter", "Cast E against interruptible spells", false)
    menu.combo.esettings:boolean("EnableAntiGapcloser", "Cast E against gapclosers", true)

menu:menu('harass', 'Hybrid/Harass Settings')
    menu.harass:menu('qsettings', "Q Settings")
        menu.harass.qsettings:boolean("qharras", "Use Q", true)
        menu.harass.qsettings:slider("mana_mngr", "Minimum Mana %", 75, 0, 100, 5)

menu:header("gfff", "Misc Settings")
       -- menu:keybind("autoe", "Auto E", nil, 'G')
        --menu:keybind("semir", "Semi - R", 'T', nil)
        menu:keybind("keyjump", "Flee", 'Z', nil)
        menu:menu('kill', 'KillSteal Settings')
            menu.kill:boolean("qkill", "Use Q if KillSteal", true)
            --menu.kill:boolean("ekill", "Use E if KillSteal", true)
menu:menu("draws", "Drawings")
        menu.draws:boolean("qrange", "Draw Q Range", true)
        menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("wrange", "Draw W Range", false)
        menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
        menu.draws:boolean("erange", "Draw E Range", false)
        menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)

local function HasWBuff(unit)
    return unit.buff['quinnw'] 
end 

local function HasRBuff()
    return player.buff['quinnr'] 
end 

local function OnPreAttack()
    IsPreAttack = true;
end 

local interrupt_data = {};
local function OnProcessSpell(spell)
    if not menu.combo.esettings.EnableInterrupter:get() then return end
    if not spell or not spell.name or not spell.owner then return end
    if spell.owner.isDead then return end
    if spell.owner.team == player.team then return end
    if player.pos:dist(spell.owner.pos) > player.attackRange + (player.boundingRadius + spell.owner.boundingRadius) then return end	

    for i = 0, #script.interrupt.names do
        if (script.interrupt.names[i] == string.lower(spell.name)) then
            interrupt_data.start = os.clock();
            interrupt_data.channel = script.interrupt.times[i];
            interrupt_data.owner = spell.owner;
        end
    end
end 

local _OnVision = {}
local OnVision = function(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.isVisible , tick = os.clock(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.isVisible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = os.clock() end
	if _OnVision[unit.networkID].state == false and unit.isVisible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = os.clock() end
	return _OnVision[unit.networkID]
end

local function Combo()
    -- body
    if menu.combo.qsettings.qcombo:get() and player:spellSlot(0).state == 0 and common.GetPercentMana(player) >= menu.combo.qsettings.mana_mngr:get() then
        local target = TS.get_result(function(res, obj, dist)
            if (dist > pred_q.range or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"] ~= nil) then
                return
            end
            if obj and common.IsValidTarget(obj) and common.IsEnemyMortal(obj) and not HasWBuff(obj) then
                res.obj = obj
                return true
            end
        end).obj
        --Q 

        if target and not HasRBuff() then 
            local seg = pred.linear.get_prediction(pred_q, target)
            if seg and seg.startPos:dist(seg.endPos) < pred_q.range then
                if not pred.collision.get_prediction(pred_q, seg, target) then
                    player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end 
            end
        end 
    end

    --W 
    if menu.combo.wsettings.wcombo:get() and player:spellSlot(1).state == 0 and common.GetPercentMana(player) >= menu.combo.wsettings.mana_mngr:get() then
        local CastOnVision = 0
        for i=0, objManager.enemies_n-1 do
            local unit = objManager.enemies[i]
            if unit and not unit.isDead then 
                if os.clock() - CastOnVision > 100 then 
                    OnVision(unit)
                    CastOnVision = os.clock()
                end
            end 

            if unit and not unit.isDead and OnVision(unit).state == false then 
                if player.pos:dist(unit.pos) <= 2100 then
                    player:castSpell("self", 1)
                end
            end
        end
    end
    --E 
    if menu.combo.esettings.ecombo:get() and player:spellSlot(2).state == 0 and common.GetPercentMana(player) >= menu.combo.esettings.mana_mngr:get() then
        local target = TS.get_result(function(res, obj, dist)
            if (dist > 760 or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"] ~= nil) then
                return
            end
            if obj and common.IsValidTarget(obj) and common.IsEnemyMortal(obj) and not HasWBuff(obj) then 
                res.obj = obj
                return true
            end
        end).obj
        if target then 
            if (damage.GetSpellDamage(0, target) + damage.GetSpellDamage(2, target))  > common.GetShieldedHealth("AD", target) then
                player:castSpell("obj", 2, target)
            elseif HasRBuff() and #common.CountEnemiesInRange(target.pos, 600) <= 2 then 
                player:castSpell("obj", 2, target)
            end
        end
    end
end

local function Harass()
    if menu.harass.qsettings.qharras:get() and player:spellSlot(0).state == 0 and common.GetPercentMana(player) >= menu.harass.qsettings.mana_mngr:get() then
        local target = TS.get_result(function(res, obj, dist)
            if (dist > pred_q.range or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"] ~= nil) then
                return
            end
            if obj and common.IsValidTarget(obj) and common.IsEnemyMortal(obj) and not HasWBuff(obj) then
                res.obj = obj
                return true
            end
        end).obj
        --Q 

        if target and not HasRBuff() then 
            local seg = pred.linear.get_prediction(pred_q, target)
            if seg and seg.startPos:dist(seg.endPos) < pred_q.range then
                if not pred.collision.get_prediction(pred_q, seg, target) then
                    player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
                end 
            end
        end 
    end
end

local function OnAttack(last_target)
    if menu.combo.esettings.ecombo:get() and player:spellSlot(2).state == 0 and common.GetPercentMana(player) >= menu.combo.esettings.mana_mngr:get() then 
        if last_target and last_target.isHero and common.IsValidTarget(last_target) and common.IsEnemyMortal(last_target) then 
            if #common.CountEnemiesInRange(last_target.pos, 600) <= 1 and common.IsInRange(760, player, last_target) then 
                player:castSpell("obj", 2, last_target)
            end 
        end 
    end
end

local function OnTick()
    if player.isDead then return end

    IsPreAttack = false;

    --interrupt
    if menu.combo.esettings.EnableInterrupter:get() then 
        if not interrupt_data.owner then return end
        if player.pos:dist(interrupt_data.owner.pos) > player.attackRange + (player.boundingRadius + interrupt_data.owner.boundingRadius) then return end
        
        if os.clock() - interrupt_data.channel >= interrupt_data.start then
            interrupt_data.owner = false;
            return
        end

        if os.clock() - 0.35 >= interrupt_data.start then
            player:castSpell("pos", 2, interrupt_data.owner.pos);
            interrupt_data.owner = false;
        end
    end

    --Gab
    if menu.combo.esettings.EnableAntiGapcloser:get() then 
        local target = TS.get_result(function(res, obj, dist)

            if dist > 2500 or common.GetPercentHealth(obj) > 40 then
                return
            end

            if dist <= (760 + obj.boundingRadius) and obj.path.isActive and obj.path.isDashing then
                res.obj = obj
                return true
            end
        end).obj
        if target and player:spellSlot(2).state == 0 then
            if target.pos:dist(player.pos) <= 760 then
                player:castSpell("obj", 2, target)
            end 
        end
    end 

    --OnVision
    if menu.combo.wsettings.CCcombo:get() and player:spellSlot(1).state == 0 and common.GetPercentMana(player) >= menu.combo.wsettings.mana_mngr:get() then
        local CastOnVision = 0
        for i=0, objManager.enemies_n-1 do
            local unit = objManager.enemies[i]
            if unit and not unit.isDead then 
                if os.clock() - CastOnVision > 100 then 
                    OnVision(unit)
                    CastOnVision = os.clock()
                end
            end 

            if unit and not unit.isDead and OnVision(unit).state == false then 
                if player.pos:dist(unit.pos) <= 2100 then
                    player:castSpell("self", 1)
                end
            end
        end
    end

    for i=0, objManager.enemies_n-1 do
        local unit = objManager.enemies[i]
        if unit and common.IsValidTarget(unit) and not unit.isDead then 
            if menu.kill.qkill:get() and player:spellSlot(0).state == 0 then 
                local seg = pred.linear.get_prediction(pred_q, unit)
                if seg and seg.startPos:dist(seg.endPos) < pred_q.range and damage.GetSpellDamage(0, unit) > common.GetShieldedHealth("AD", unit) then
                    if not pred.collision.get_prediction(pred_q, seg, unit) then
                        player:castSpell("pos", 0, vec3(seg.endPos.x, unit.y, seg.endPos.y))
                    end 
                end
            end 
        end 
    end

    if orb.menu.combat.key:get() then
        Combo();
    elseif orb.menu.hybrid.key:get() then
        Harass();
    end
end 

local function OnDrawing()
    if player.isDead and player.buff[17]and not player.isOnScreen then 
        return 
    end 

    if player:spellSlot(0).state == 0 and menu.draws.qrange:get() then 
        graphics.draw_circle(player.pos, pred_q.range, 1, menu.draws['qcolor']:get(), 100)
    end 
    if player:spellSlot(1).state == 0 and menu.draws.wrange:get() then 
        graphics.draw_circle(player.pos, 2100, 1, menu.draws['wcolor']:get(), 100)
    end 
    if player:spellSlot(2).state == 0 and menu.draws.erange:get() then 
        graphics.draw_circle(player.pos, 760, 1, menu.draws['ecolor']:get(), 100)
    end 
end 

cb.add(cb.draw, OnDrawing)
--
cb.add(cb.pre_tick, OnPreAttack)
cb.add(cb.tick, OnTick)
orb.combat.register_f_after_attack(OnAttack)
--
cb.add(cb.spell, OnProcessSpell)
--cb.add(cb.cast_spell, CastSpell)
--Creat Trap
--cb.add(cb.delete_object, OnDeleObject)
--cb.add(cb.create_object, OnCreateObject)