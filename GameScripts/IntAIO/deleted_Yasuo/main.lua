local WallJump = module.load('int', 'Core/Yasuo/WallJump');
local SpellManager = module.load('int', 'Core/Yasuo/SpellManager');

local EventManager = module.load('int', 'Core/Yasuo/EventManager');
local DashingManager = module.load('int', 'Core/Yasuo/DashingManager');
local Extentions = module.load('int', 'Core/Yasuo/Extentions');
local damageLib = module.load('int', 'Library/damageLib');
local common = module.load('int', 'Library/common');

local database = module.load("int", "Core/Yasuo/SpellDatabase")

local orb = module.internal("orb")
local pred = module.internal('pred');
local evade = module.seek('evade');
local TS = module.internal('TS');

local str = {[-1] = "P", [0] = "Q", [1] = "W", [2] = "E", [3] = "R"}

local enemies = common.GetEnemyHeroes()

local TargetSelectionQ1 = function(res, obj, dist) --Range default
	if dist <= SpellManager.Q1.range then
		res.obj = obj
		return true
	end
end

local GetTargetQ1 = function()
	return TS.get_result(TargetSelectionQ1).obj
end

local TargetSelectionQ3 = function(res, obj, dist) --Range default
	if dist <= SpellManager.Q3.range then
		res.obj = obj
		return true
	end
end

local GetTargetQ3 = function()
	return TS.get_result(TargetSelectionQ3).obj
end

local TargetSelectionE = function(res, obj, dist) --Range default
	if dist <= 475 then
		res.obj = obj
		return true
	end
end

local GetTargetE = function()
	return TS.get_result(TargetSelectionE).obj
end

local TargetSelectionR = function(res, obj, dist) --Range default
	if dist <= 1500 then
		res.obj = obj
		return true
	end
end

local GetTargetR = function()
	return TS.get_result(TargetSelectionR).obj
end

local Focus = nil
local menu = menu("int", "Int Yasuo");
--subs menu
menu:header("xs", "Core");
menu:menu("combo", "Combo");
menu.combo:boolean("q", "Use Q", true);
menu.combo:boolean("stackq", "^~ Stack |-> Q", true); --Left Click Rape
menu.combo:menu("WIND", "WindWall - W");
menu.combo.WIND:header("uhhh", "-- Spells Specials --")
for _, i in pairs(database) do
	for l, k in pairs(common.GetEnemyHeroes()) do
		-- k = myHero
		if not database[_] then
			return
		end
		if i.charName == k.charName then
			if i.displayname == "" then
				i.displayname = _
			end
			if i.danger == 0 then
				i.danger = 1
			end

			if (i.type == "circular" or i.type == "linear" or i.type == "conic" or i.type == "cross" or i.type == "Ptarget")  then
				if (menu.combo.WIND[i.charName] == nil) then
					menu.combo.WIND:menu(i.charName, i.charName)
				end
                menu.combo.WIND[i.charName]:menu(_, "" .. i.charName .. " | " .. (str[i.slot] or "?") .. " | " .. _)
                menu.combo.WIND[i.charName][_]:boolean("Dodge", "Block Spell || Spells", false)
			end
		end
	end
end
menu.combo:boolean("e", "Use E", true);
menu.combo:boolean("SmartE", "^ Smart E", false);
menu.combo:boolean("leftclickRape", "Left Click Rape", true);
menu.combo:header('dddd', "Ultimate")
menu.combo:boolean("r", "Use R", true);
menu.combo:boolean("RTarget", " ^ Use R always on Selected Target", true);
menu.combo:boolean("RKillable", "Use R |-> KillSteal", true);
menu.combo:slider("MinTargetsR", "Use R Min. Targets", 2, 1, 5, 1);
--Harass
menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("stackq", "^~ Stack |-> Q", false);
menu.harass:boolean("e", "Use E", true);
--Farm
menu:menu("lane", "Farming");
menu.lane:header("xs", "Wave-Clear");
menu.lane:boolean("q", "Use Q", true);
menu.lane:boolean("e", "Use E", true);
menu.lane:boolean("EUnderTower", "Use E Under Tower", false);
menu.lane:header("xddds", "Jungle-Clear");
menu.lane:menu('jug', "Jungle")
menu.lane.jug:boolean("q", "Use Q", true);
menu.lane.jug:boolean("e", "Use E", true);
menu.lane:header("dd", "Last-Hit");
menu.lane:menu('last', "LastHit")
menu.lane.last:boolean("q", "Use Q", true);
menu.lane.last:boolean("e", "Use E", true);
menu.lane.last:boolean("EUnderTower", "Use E Under Tower", false);
--WallJump
menu:menu('walljump', 'WallJump')
menu.walljump:keybind("keyjump", "WallJump - Key", 'Z', nil)
menu.walljump:boolean("dde", "WallJump Drawing", true);
--Misc
menu:menu("misc", "Misc");
menu.misc:boolean("kill", "Killsteal", true);
menu.misc:boolean("q3", "Auto Q3", true);
menu.misc:keybind("autoq", "Auto Q Enemy", nil, 'M')
menu.misc:header("xs", "Flee");
menu.misc:keybind("flee", "Flee", 'Z', nil)
--Draw
menu:menu("dis", "Display");
menu.dis:boolean("qd", "Q Range", true);
menu.dis:boolean("ed", "E Range", false);
menu.dis:boolean("rd", "R Range", true);

cb.add(cb.tick, function()
    for i = 1, #evade.core.active_spells do
        local spell = evade.core.active_spells[i]
        local allies = common.GetAllyHeroes()
        for z, ally in ipairs(allies) do
            if ally then
                -------ifmenu.combo.WIND.blacklist[ally.charName] and notmenu.combo.WIND.blacklist[ally.charName]:get() then
                    if  spell.data.spell_type == "Target"  and (spell.target == ally or spell.target == player) and spell.owner.type == TYPE_HERO then
                        if not spell.name:find("crit") then
                            if not spell.name:find("basicattack") then
                                ---ifmenu.combo.WIND.targeteteteteteed:get() then
                                    if ally.pos:dist(player.pos) <= 400 then
                                        player:castSpell("pos", 1, spell.owner.pos)
                                    end
                                    if (ally.pos:dist(player.pos) <= 200 and player.pos:dist(spell.owner.pos) <= (player.boundingRadius*player.boundingRadius*2)) then
                                        player:castSpell("pos", 1, spell.owner.pos)
                             
                                    end
                                --end
                            end
                        end
                    elseif
                        spell.polygon and spell.polygon:Contains(ally.path.serverPos) ~= 0 and
                            (not spell.data.collision or #spell.data.collision == 0)
                     then
                        for _, k in pairs(database) do
                            if
                                spell.name:find(_:lower()) and menu.combo.WIND[k.charName] and menu.combo.WIND[k.charName][_] and
                                   menu.combo.WIND[k.charName][_].Dodge:get()
                             then
                                if (ally.pos:dist(player.pos) <= 450 or player.pos:dist(spell.owner.pos) <= 450) then
                                    if spell.missile then
                                        player:castSpell("pos", 1, spell.missile.startPos)
                                    end
                                end
                                if spell.owner.pos:dist(player.pos) <= 900 then
                                    if spell.missile then
                                        
                                            if spell.owner.pos:dist(player.pos) <= 900 then
                                                player:castSpell("pos", 1, spell.missile.startPos)
        
                                            end
                                        
                                    end
                                end
                            end
                        end
                    end
                --end
            end
        end
    end
end) 

cb.add(cb.draw, function() 
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.dis.qd:get() and player:spellSlot(0).state == 0) then
            if player:spellSlot(0).name ~= "YasuoQ3Wrapper" then
                graphics.draw_circle(player.pos, SpellManager.Q1.range, 1, graphics.argb(255, 23, 33, 55), 40)
            else 
                graphics.draw_circle(player.pos, SpellManager.Q3.range, 1, graphics.argb(255, 23, 33, 55), 40)
            end
        end
        if (menu.dis.ed:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 475, 1, graphics.argb(255, 23, 33, 55), 40)
        end
        if (menu.dis.rd:get() and player:spellSlot(3).state == 0) then
            graphics.draw_circle(player.pos, 1400, 1, graphics.argb(255, 23, 33, 55), 40)
        end
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.misc.autoq:get() == true then
			graphics.draw_text_2D("Auto Q |-> Wrapper: On", 18, pos.x - 59, pos.y + 50, graphics.argb(255, 255, 255, 255))
		else
			graphics.draw_text_2D("Auto Q |-> Wrapper: Off", 18, pos.x - 59, pos.y + 50, graphics.argb(255,  255, 255, 255))
		end
    end
    if menu.walljump.dde:get() and menu.walljump.keyjump:get() then
        if not (player.isOnScreen) then return end 
		local Spots = WallJump.JumpSpots
        if Spots then
            for i, spot in ipairs(Spots) do
                graphics.draw_circle(spot.To, 130, 1, graphics.argb(255, 255, 255, 255), 40)
            end
        end 
    end
end);

local function AutoQ()
    if menu.misc.autoq:get() == true and menu.misc.q3:get() then 
        if (orb.combat.is_active()) then return end
        if player.path.isDashing then return end
        for i = 0, objManager.enemies_n - 1 do
            local target = objManager.enemies[i]
            if target and common.IsValidTarget(target) and target.pos:dist(player.pos) < 900 then 
                local qpred = pred.linear.get_prediction(SpellManager.Q3, target)
                if qpred and qpred.startPos:dist(qpred.endPos) < SpellManager.Q3.range then
                    if player:spellSlot(0).state == 0 then
                        if not Extentions.HasWhirlwind(player) then return end
                        player:castSpell("pos", 0, vec3(qpred.endPos.x, target.y, qpred.endPos.y))
                    end
                end 
            end 
        end
    end
end 

local function KillSteal()
    local enemy = common.GetEnemyHeroes()
	for i, target in ipairs(enemy) do
		if target and target.isVisible and common.IsValidTarget(target) then
            local hp = common.GetShieldedHealth("ad", target)
            if (player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "YasuoQ3Wrapper") and damageLib.GetSpellDamage(0, target) > hp then 
                local qpred = pred.linear.get_prediction(SpellManager.Q1, target)
                if qpred and qpred.startPos:dist(qpred.endPos) < SpellManager.Q1.range - target.boundingRadius then
                    player:castSpell("pos", 0, vec3(qpred.endPos.x, target.y, qpred.endPos.y))
                end
            end
            if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "YasuoQ3Wrapper" and not player.path.isDashing then 
                local qpred = pred.linear.get_prediction(SpellManager.Q3, target)
                if qpred and qpred.startPos:dist(qpred.endPos) < SpellManager.Q3.range and damageLib.GetSpellDamage(0, target) > hp then
                    player:castSpell("pos", 0, vec3(qpred.endPos.x, target.y, qpred.endPos.y))
                end
            end
            if player:spellSlot(0).state == 0 and target.pos:dist(player.pos) <= 475 and  EventManager.CanDash(target) and damageLib.GetSpellDamage(2, target) > hp then 
                player:castSpell("obj", 2, target)
            end
        end 
    end
end

local r_time = 0
orb.combat.register_f_pre_tick(function() 
    for i = 0, objManager.enemies_n - 1 do
        local target = objManager.enemies[i]
        if target and common.IsValidTarget(target) and target.pos:dist(player.pos) < 475 then 
            if player:spellSlot(0).name == "YasuoQ2Wrapper" and player:spellSlot(0).state == 0 and EventManager.CanDash(target) then
                player:castSpell("obj", 2, target)
                if player.path.isDashing then
                    player:castSpell("pos", 0, vec3(100000, 60, 100000))
                end
            end
        end 
    end
    KillSteal();
    AutoQ();
    if menu.walljump.keyjump:get() then
        WallJump.WallDash();
        player:move(mousePos)
    end
    if (orb.combat.is_active()) then
        local target = (menu.combo.RTarget:get() and Focus) or (GetTargetR())

        if target and common.IsValidTarget(target) then
            if player:spellSlot(3).state == 0 and SpellManager.GetLowestKnockupTime() <= 250 + network.latency and 
            menu.combo.r:get() and (menu.combo.RTarget:get() and target.buff[29] and Focus ~= target) or 
            (menu.combo.RKillable:get() and target.health <= damageLib.GetSpellDamage(3, target) and target.health > damageLib.GetSpellDamage(0, target)) or 
            (#SpellManager.GetKnockedUpTargets() >= menu.combo.MinTargetsR:get()) then 
                player:castSpell("pos", 3, target.pos)
            end
        end 
        local targetQ = (GetTargetQ1())
        if targetQ and common.IsValidTarget(targetQ) then
            if targetQ.pos:dist(player.pos) <= 450 and menu.combo.q:get() then 
                if (player.path.isDashing) then 
                    local Position = DashingManager.GetPlayerPosition(300)
                    if (player:spellSlot(0).state == 0 and Position) then 
                        player:castSpell("pos", 0, targetQ.pos)
                        orb.core.set_server_pause()
                  
                    end
                elseif (player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "YasuoQ3Wrapper") then 
                    local qpred = pred.linear.get_prediction(SpellManager.Q1, targetQ)
                    if qpred and qpred.startPos:dist(qpred.endPos) < SpellManager.Q1.range - targetQ.boundingRadius then
                        player:castSpell("pos", 0, vec3(qpred.endPos.x, mousePos.y, qpred.endPos.y))
                        orb.core.set_server_pause()
                    end
                end
            end
        end
        local targetQ3 = GetTargetQ3()
        if targetQ3 and common.IsValidTarget(targetQ3) then
            if targetQ3.pos:dist(player.pos) <= 1200 and menu.combo.q:get() then 
                if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "YasuoQ3Wrapper" and not player.path.isDashing then 
                    local qpred = pred.linear.get_prediction(SpellManager.Q3, targetQ3)
                    if qpred and qpred.startPos:dist(qpred.endPos) < SpellManager.Q3.range then
                        player:castSpell("pos", 0, vec3(qpred.endPos.x, mousePos.y, qpred.endPos.y))
                        orb.core.set_server_pause()
                    end
                    if (player.path.isDashing) then 
                        local Position = DashingManager.GetPlayerPosition(300)
                        if (player:spellSlot(0).state == 0 and Position) then 
                            player:castSpell("pos", 0, targetQ3.pos)
                            orb.core.set_server_pause()
                       
                        end
                    end
                end
            end
        end
        local targetE = GetTargetE()
        if targetE and common.IsValidTarget(targetE) then
            if menu.combo.e:get() and DashingManager.GetDashPos(targetE):dist(targetE.pos) < 400 and EventManager.CanDash(targetE) and targetE.pos:dist(player.pos) > common.GetAARange() then
                if player:spellSlot(0).state == 0 and targetE.pos:dist(player.pos) <= 475 then 
                    if Extentions.IsUnderTower(DashingManager.GetDashPos(targetE)) then return end
                    if evade and evade.core.is_action_safe(DashingManager.GetDashPos(targetE), 20, SpellManager.EDelay()) then
                        player:castSpell("obj", 2, targetE)
                    end
                end
            end
        end
        local targetEgab = (GetTargetR())
        if targetEgab and common.IsValidTarget(targetEgab) then
            if menu.combo.e:get() and targetEgab.pos:dist(player.pos) > common.GetAARange() and not player.path.isDashing then 
                local unit = DashingManager.GetClosestEUnit(targetEgab.pos)
                if unit and not menu.combo.SmartE:get() then
                    if (not (DashingManager.GetDashPos(unit):dist(targetEgab.pos) < player.pos:dist(targetEgab.pos))) then return end 
                    if Extentions.IsUnderTower(DashingManager.GetDashPos(unit)) then return end
                    --DashingManager.SmartE(targetEgab)
                    if evade and evade.core.is_action_safe(DashingManager.GetDashPos(unit), 20, SpellManager.EDelay()) then
                        if player:spellSlot(0).name == "YasuoQ2Wrapper" and player:spellSlot(0).state == 0 then
                            player:castSpell("obj", 2, unit)
                            player:castSpell("pos", 0, vec3(100000, 60, 100000))
                        else 
                            player:castSpell("obj", 2, unit)
                        end
                    end
                end 
                if menu.combo.SmartE:get() then  
                    if (not (DashingManager.GetDashPos(targetEgab):dist(targetEgab.pos) < player.pos:dist(targetEgab.pos))) then return end 
                    if Extentions.IsUnderTower(DashingManager.GetDashPos(targetEgab)) then return end
                    if evade and evade.core.is_action_safe(DashingManager.GetDashPos(targetEgab), 20, SpellManager.EDelay()) then
                        DashingManager.SmartE(targetEgab)
                    end
                end
            end
            if Extentions.HasWhirlwind(player) then return end 
            if (menu.combo.stackq:get() and targetEgab.pos:dist(player.pos) > 450) then 
                SpellManager.StackQ();
            end
        end
    end

    if (orb.menu.hybrid:get()) then 
        local target = (GetTargetR())

        if target and common.IsValidTarget(target) then
            if target.pos:dist(player.pos) <= 450 and menu.harass.q:get() then 
                if (player.path.isDashing) then 
                    local Position = DashingManager.GetPlayerPosition(300)
                    if (player:spellSlot(0).state == 0 and Position) then 
                        player:castSpell("pos", 0, target.pos)
                    end
                elseif (player:spellSlot(0).state == 0 and player:spellSlot(0).name ~= "YasuoQ3Wrapper") then 
                    local qpred = pred.linear.get_prediction(SpellManager.Q1, target)
                    if qpred and qpred.startPos:dist(qpred.endPos) < SpellManager.Q1.range then
                        player:castSpell("pos", 0, vec3(qpred.endPos.x, target.y, qpred.endPos.y))
                    end
                end
            end
            if target.pos:dist(player.pos) <= 1200 and menu.harass.q:get() then 
                if player:spellSlot(0).state == 0 and player:spellSlot(0).name == "YasuoQ3Wrapper" and not player.path.isDashing then 
                    local qpred = pred.linear.get_prediction(SpellManager.Q3, target)
                    if qpred and qpred.startPos:dist(qpred.endPos) < SpellManager.Q3.range then
                        player:castSpell("pos", 0, vec3(qpred.endPos.x, target.y, qpred.endPos.y))
                    end
                    if (player.path.isDashing) then 
                        local Position = DashingManager.GetPlayerPosition(300)
                        if (player:spellSlot(0).state == 0 and Position) then 
                            player:castSpell("pos", 0, target.pos)
                        end
                    end
                end
            end


            if menu.harass.e:get() and DashingManager.GetDashPos(target):dist(target.pos) < 400 and EventManager.CanDash(target) and target.pos:dist(player.pos) > common.GetAARange() then
                if player:spellSlot(0).state == 0 and target.pos:dist(player.pos) <= 475 then 
                    player:castSpell("obj", 2, target)
                end
            end

            if menu.harass.e:get() and target.pos:dist(player.pos) > common.GetAARange() and not player.path.isDashing then 
                for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
                    local minion = objManager.minions[TEAM_ENEMY][i]
                    if (not (DashingManager.GetDashPos(minion):dist(target.pos) < player.pos:dist(target.pos)) or (Extentions.IsUnderTower(DashingManager.GetDashPos(minion)))) then return end 
                    player:castSpell("obj", 2, minion)
                end

            end

            if Extentions.HasWhirlwind(player) then return end 
            if (menu.harass.stackq:get()) then 
                SpellManager.StackQ();
            end

        end
    end
    if (orb.menu.lane_clear:get()) then 
        for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            local MinionOn = nil 
            if minion and common.IsValidTarget(minion) then 
                if menu.lane.q:get() and player.path.isDashing then 
                    local Position = DashingManager.GetPlayerPosition(300)
                    if (player:spellSlot(0).state == 0 and Position) and ((damageLib.GetSpellDamage(0, minion) > minion.health) or #common.CountMinioAroundObject(DashingManager._endPos, 400) > 1) then 
                        player:castSpell("pos", 0, minion.pos)
                    end
                end
                if menu.lane.e:get() and player:spellSlot(2).state == 0 and (not Extentions.IsUnderTower(DashingManager.GetDashPos(minion)) or menu.lane.EUnderTower:get()) then 
                    if damageLib.GetSpellDamage(2, minion) > minion.health and minion.pos:dist(player.pos) < 475 then
                        player:castSpell("obj", 2, minion)
                    end
                end
                if (menu.lane.q:get() and  player:spellSlot(0).name ~= "YasuoQ3Wrapper" and player:spellSlot(0).state == 0 and not player.path.isDashing and damageLib.GetSpellDamage(0, minion) > minion.health) and minion.pos:dist(player.pos) < 450 then 
                    player:castSpell("pos", 0, minion.pos)
                end
                
                if (menu.lane.q:get() and menu.lane.e:get() and  player:spellSlot(0).name ~= "YasuoQ3Wrapper" and not player.path.isDashing  and player:spellSlot(2).state == 0) and player:spellSlot(0).state == 0 and damageLib.GetSpellDamage(2, minion) + damageLib.GetSpellDamage(0, minion) > minion.health and not Extentions.IsUnderTower(DashingManager.GetDashPos(minion)) and minion.pos:dist(player.pos) < 450 then
                    player:castSpell("pos", 0, minion.pos)
                end
            end
        end

        --> Jungle <--
        for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
            local minion = objManager.minions[TEAM_NEUTRAL][i]
            if minion and common.IsValidTarget(minion) then 
                if minion.pos:dist(player.pos) > 475 then return end
                if menu.lane.jug.q:get() and player.path.isDashing then 
                    local Position = DashingManager.GetPlayerPosition(300)
                    if (player:spellSlot(0).state == 0 and Position) and ((damageLib.GetSpellDamage(2, minion) > minion.health) or #common.CountMinioAroundObject(Position, 475) > 1) then 
                        player:castSpell("pos", 0, minion.pos)
                    end
                end
                if menu.lane.jug.e:get() and player:spellSlot(2).state == 0 and (not Extentions.IsUnderTower(DashingManager.GetDashPos(minion)) or menu.lane.EUnderTower:get()) then 
                    if damageLib.GetSpellDamage(2, minion) > minion.health then
                        player:castSpell("obj", 2, minion)
                    end
                    if damageLib.GetSpellDamage(2, minion) + common.CalculateAADamage(minion) > minion.health then
                        orb.farm.set_clear_target(minion)
                    end
                end
                if (menu.lane.jug.q:get() and player:spellSlot(0).state == 0) then 
                    player:castSpell("pos", 0, minion.pos)
                end
                
                if (menu.lane.jug.q:get() and menu.lane.jug.e:get() and player:spellSlot(2).state == 0) and player:spellSlot(0).state == 0 and damageLib.GetSpellDamage(2, minion) + damageLib.GetSpellDamage(0, minion) > minion.health and not Extentions.IsUnderTower(DashingManager.GetDashPos(minion)) then
                    player:castSpell("pos", 0, minion.pos)
                end
            end 
        end
    end
    if (orb.menu.last_hit:get()) then 
        for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if minion and common.IsValidTarget(minion) then 
                if minion.pos:dist(player.pos) > 475 then return end
                if (menu.lane.last.q:get() and player:spellSlot(0).name ~= "YasuoQ3Wrapper" and player:spellSlot(0).state == 0 and damageLib.GetSpellDamage(0, minion) > minion.health) then 
                    player:castSpell("pos", 0, minion.pos)
                end
                if menu.lane.jug.e:get() and player:spellSlot(2).state == 0 and (not Extentions.IsUnderTower(DashingManager.GetDashPos(minion)) or menu.lane.EUnderTower:get()) then 
                    if damageLib.GetSpellDamage(2, minion) > minion.health then
                        player:castSpell("obj", 2, minion)
                    end
                end
            end
        end
    end
    if menu.misc.flee:get() then 
        local unit = DashingManager.GetClosestEUnit(mousePos)
        if unit and DashingManager.GetDashPos(unit):dist(mousePos) < player.pos:dist(mousePos) then 
            player:move(mousePos)
            player:castSpell("obj", 2, unit)
        end
        player:move(mousePos)
    end
end)


cb.add(cb.keydown, function(key) 
    if key == 1 and menu.combo.RTarget:get() then
		local enemy, distance = closestEnemy(vec2.clone(game.mousePos2D))
		if distance < 62500 then -- 250
			if Focus and common.IsValidTarget(Focus) and Focus.networkID == enemy.networkID then
				Focus = nil
			else
				Focus = enemy
			end
		end
	end
end)


function closestEnemy(pos)
	local closestEnemy, distanceEnemy = nil, math.huge
	for i=1, #enemies do
		local hero = enemies[i]
		if hero and not hero.isDead and hero.isVisible then
			if pos:distSqr(hero.pos2D) < distanceEnemy then
				distanceEnemy = pos:distSqr(hero.pos2D)
				closestEnemy = hero
			end
		end
	end
	return closestEnemy, distanceEnemy
end