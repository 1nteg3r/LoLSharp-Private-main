local orb = module.internal("orb");
local pred = module.internal('pred');
local evade = module.seek('evade');
local TS = module.internal('TS');
--lib
local common = module.load('int', 'Library/common');
local damageLib = module.load('int', 'Library/damageLib');
local database = module.load("int", "Core/Lux/SpellDatabase");

local str = {[-1] = "P", [0] = "Q", [1] = "W", [2] = "E", [3] = "R"}

local LuxELight = { }
local LightETime = 0 

local q = {
    slot = player:spellSlot(0),
    last = 0,
    range = 1170,
  
    result = {
      seg = nil,
      obj = nil,
    },
  
    predinput = {
        range = 1170,
        delay = 0.25,
        width = 80,
        speed = 1200,
        boundingRadiusMod = 1,
        collision = { hero = true, minion = true, wall = true };
    },
}

local TargetSelectionQ = function(res, obj, dist) --Range default
    if q.last == game.time then
        return q.result.seg
    end

    q.last = game.time
    q.result.obj = nil
    q.result.seg = nil

    if dist <= q.range then
        local seg = pred.linear.get_prediction(q.predinput, obj)
        if seg and seg.startPos:dist(seg.endPos) <= (q.range - obj.boundingRadius) then
            res.obj = obj
            res.seg = seg
            return true
        end
    end
    if q.result.seg then
        return q.result
    end
end

local GetTargetQ = function() 
    return TS.get_result(TargetSelectionQ).obj
end

local spellE = {
    range = 1100;
    delay = 0.25; 
    radius = 50;
    speed = 1300;
    boundingRadiusMod = 0; 
    collision = { hero = false, minion = false, wall = true };
}

local TargetSelectionE = function(res, obj, dist)
    if dist <= spellE.range then
        local seg = pred.circular.get_prediction(spellE, obj)
        if seg and seg.startPos:dist(seg.endPos) <= (spellE.range - obj.boundingRadius) then
            res.obj = obj
            res.seg = seg
            return true
        end
    end
end

local GetTargetE = function() 
    return TS.get_result(TargetSelectionE).obj
end

local spellR = {
    range = 3340;
    delay = 1.375; 
    width = 190;
    speed = 3000;
    boundingRadiusMod = 1; 
}

local TargetSelectionR = function(res, obj, dist)
    if dist <= spellR.range then
        local seg = pred.linear.get_prediction(spellR, obj)
        if seg and seg.startPos:dist(seg.endPos) <= (spellR.range - obj.boundingRadius) then
            res.obj = obj
            res.seg = seg
            return true
        end
    end
end

local GetTargetR = function() 
    return TS.get_result(TargetSelectionR).obj
end

local menu = menu("hemiss", "Int Lux")
menu:header("xs", "Core");
menu:menu("combo", "Combo");
menu.combo:boolean("q", "Use Q", true);
menu.combo:menu('wset', "Settings W");
menu.combo.wset:boolean("w", "Use W", true);
menu.combo.wset:slider("dontjump", "Shield if Health for >=", 25, 1, 100, 1)
menu.combo.wset:header("uhhh", "-- Spells Targets --")
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

			if (i.type == "circular" or i.type == "linear" or i.type == "conic" or i.type == "cross" or i.type == "Ptarget") then
				if (menu.combo.wset[i.charName] == nil) then
					menu.combo.wset:menu(i.charName, i.charName)
				end
                menu.combo.wset[i.charName]:menu(_, "" .. i.charName .. " |-> " .. (str[i.slot] or "?"))
                menu.combo.wset[i.charName][_]:boolean("Dodge", "Use W", false)
			end
		end
	end
end
menu.combo:boolean("e", "Use E", true);
menu.combo:boolean("e2", "Cancel Two E:", true);
menu.combo:dropdown('modeEW', '^ Use E when', 1, {'Slow', 'Blood', 'Never'});
menu.combo.modeEW:set('tooltip', "Blood: Use E Instantly");
menu.combo:header('exh', 'R Settings')
menu.combo:boolean("r", "Use R", true);

menu:menu("dis", "Display");
menu.dis:boolean("qd", "Q Range", true);
menu.dis:boolean("ed", "E Range", true);
menu.dis:boolean("rd", "R Range -> Minimap", true);

local function ValidUlt(unit)
	if (unit.buff[16] or unit.buff[15] or unit.buff[17] or unit.buff['kindredrnodeathbuff'] or unit.buff["sionpassivezombie"] or unit.buff[4]) then
		return false
	end
	return true
end

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.dis.qd:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, q.range, 1, graphics.argb(255, 255, 255, 255), 100)
        end
        if (menu.dis.ed:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, spellE.range, 1, graphics.argb(255, 255, 255, 255), 100)
        end
    end
    if (menu.dis.rd:get() and player:spellSlot(3).state == 0)  then
        minimap.draw_circle(player.pos, spellR.range, 1, graphics.argb(255, 255, 255, 255), 100)
    end
end

local function Combo() 
    if not orb.combat.is_active() then return end

    --menu 
    local q_on = menu.combo.q:get();
    local e_mode = menu.combo.modeEW:get();
    local e_on = menu.combo.e:get();
    --return 

    if player.isDead then return end 

    --target 
    local target_q = GetTargetQ();
    local target_e = GetTargetE();
    local target_r = GetTargetR();

    if target_e and common.IsValidTarget(target_e) then
        ---if e_mode ~= 1 or e_mode ~= 2 then return end
        if (e_on) then 
            --if (e_mode == 1) then -- slow mode
                local pos = pred.circular.get_prediction(spellE, target_e)
                if pos and pos.startPos:dist(pos.endPos) < spellE.range then
                    if player:spellSlot(2).state == 0 and player:spellSlot(2).name ~= "LuxLightstrikeToggle" then 
                        if target_e.path.serverPos2D:dist(player.path.serverPos2D) >= q.range then return end
                        player:castSpell("pos", 2, vec3(pos.endPos.x, target_e.y, pos.endPos.y))
                    end 
                end
            --end
        end
    end
    for _, Light in pairs(LuxELight) do
        if Light then
            if (e_mode == 1) then 
                local Target = TS.get_result(function(res, obj, dist)
                    if dist <= 99999 and common.IsValidTarget(obj) then --add invulnverabilty check
                        res.obj = obj
                        return true
                    end
                end).obj
                if Target and common.IsValidTarget(Target) then 
                    if player:spellSlot(2).state == 0 and player:spellSlot(2).name == "LuxLightstrikeToggle" then 
                        if Light.pos:dist(Target.pos) > 290 - Target.boundingRadius then 
                            player:castSpell('self', 2)
                        elseif (Light.pos:dist(Target.pos) > 350 and menu.combo.e2:get())then
                            player:castSpell('self', 2)
                        end
                    end
                end
            elseif (e_mode == 2) then 
                local Target = TS.get_result(function(res, obj, dist)
                    if dist <= 99999 and common.IsValidTarget(obj) then --add invulnverabilty check
                        res.obj = obj
                        return true
                    end
                end).obj
                if Target and common.IsValidTarget(Target) then 
                    if player:spellSlot(2).state == 0 and player:spellSlot(2).name == "LuxLightstrikeToggle" then 
                        if Light.pos:dist(Target.pos) <= 310 - Target.boundingRadius then 
                            player:castSpell('self', 2)
                        elseif (Light.pos:dist(Target.pos) > 350 and menu.combo.e2:get())then
                            player:castSpell('self', 2)
                        end
                    end
                end
            end
        end 
    end
    if target_q and common.IsValidTarget(target_q) then
        if (q_on) then 
            if target_q.path.serverPos2D:dist(player.path.serverPos2D) >= q.range then return end
            local qpred = pred.linear.get_prediction(q.predinput, target_q)
            if qpred and qpred.startPos:dist(qpred.endPos) < q.range then
                local colid = pred.collision.get_prediction(q.predinput, qpred, target_q)
                if not colid and  player:spellSlot(0).state == 0 then 
                    player:castSpell("pos", 0, vec3(qpred.endPos.x, target_q.y, qpred.endPos.y))
                end
            end
        end
    end
end 

orb.combat.register_f_pre_tick(function()  
    Combo();

    if (player.health / player.maxHealth) * 100 >= menu.combo.wset.dontjump:get() then
		if not player.isRecalling then
			if menu.combo.wset.w:get() then
				for i = 1, #evade.core.active_spells do
					local spell = evade.core.active_spells[i]

					local allies = common.GetAllyHeroes()
					for z, ally in ipairs(allies) do
						if ally then
							--if menu.SpellsMenu.blacklist[ally.charName] and not menu.SpellsMenu.blacklist[ally.charName]:get() then
								if spell.data.spell_type == "Target" and spell.target == ally and spell.owner.type == TYPE_HERO then
									if not spell.name:find("crit") then
										if not spell.name:find("basicattack") then
											--if menu.SpellsMenu.targeteteteteteed:get() then
												if ally.pos:dist(player.pos) <= 1100 then
													player:castSpell("pos", 1, ally.pos)
												end
												if ally.pos:dist(player.pos) <= 200 then
													player:castSpell("pos", 2, spell.owner.pos)
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
											spell.name:find(_:lower()) and menu.combo.wset[k.charName] and menu.combo.wset[k.charName][_] and
												menu.combo.wset[k.charName][_].Dodge:get() and
												100 >= (ally.health / ally.maxHealth) * 100
										 then
											if ally.pos:dist(player.pos) <= 1100 and player.mana > player.manaCost1 then
												if spell.missile then
													if
														(ally.pos:dist(spell.missile.pos) / spell.data.speed < network.latency + player.pos:dist(ally.pos) / 1700)
													 then
														player:castSpell("pos", 1, ally.pos)

														player:castSpell("pos", 1, spell.missile.startPos)
													end
												end
											end
											if ally.pos:dist(player.pos) <= 200 then
												if spell.missile then
													if (ally.pos:dist(spell.missile.pos) / spell.data.speed < network.latency + 0.2) then
														if ally.pos:dist(player.pos) <= 200 then
															player:castSpell("pos", 1, spell.missile.startPos)
														end
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
			end
		end
    end
      local enemy = common.GetEnemyHeroes()
	for i, target in ipairs(enemy) do
        if target and common.IsValidTarget(target) and ValidUlt(target) then
            local heathly = common.GetShieldedHealth("ap", target)
            if damageLib.GetSpellDamage(3, target) > heathly and player.pos:dist(target) < (spellR.range - target.boundingRadius) then
                local qpred = pred.linear.get_prediction(spellR, target)
                if qpred and qpred.startPos:dist(qpred.endPos) < (spellR.range - target.boundingRadius) then
                    --if not pred.collision.get_prediction(spellR, qpred, target) then 
                        player:castSpell("pos", 3, vec3(qpred.endPos.x, target.y, qpred.endPos.y))
                    --end
                end
            end 
        end 
    end
end)

cb.add(cb.create_particle, function(obj) 
    if obj and obj.name then 
        if string.find(obj.name, "E_tar_aoe_green") then
            LuxELight[obj.ptr] = obj 
            LightETime = game.time
        end 
    end
end)

cb.add(cb.delete_particle, function(obj) 
    if obj then
        LuxELight[obj.ptr] = nil
        LightETime = game.time
    end
end)

cb.add(cb.draw, OnDraw);