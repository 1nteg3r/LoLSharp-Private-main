local orb = module.internal("orb");
local evade = module.seek('evade');
local common = module.load("int", "lib/util");
local ts = module.internal("TS")
local dlib = module.load('int', 'damageLib');
local pred = module.internal('pred')
local prediction = module.load("int", "Zoe/prediction");

local qCanCast = true;
local rAfterQ = false;
local rBeforeQ = false;
local Q2Range = 0;
local Sleep_Particle = { };

local Items = { 
    ["Blade of the Ruined King"] = {
        ID = 3153 
    };
    ["Hextech GLP-800"] = {
        ID = 3030
    };
    ["Hextech Gunblade"] = {
        ID = 3146
    };
    ["Hextech Protobelt"] = {
        ID = 3152
    };
    ["Randuin's Omen"] = {
        ID = 3143
    };
    ["Redemption"] = {
        ID = 3107
    };
    ["Righteous Glory"] = {
        ID = 3800
    };
    ["Twin Shadows"] = {
        ID = 3905
    };
    ["Youmuu's Ghostblade"] = {
        ID = 3142
    };
    ["Zhonya's Hourglass"] = {
        ID = 3157
    }
}

local TargetSelectionR = function(res, obj, dist)
	if dist < 800+575  then
		res.obj = obj
		return true
	end
end

local menu = menu("fizedwar", "Int Zoe");
menu:header("xs", "Core");
menu:menu('combo', "Combo");
menu.combo:header("headQ", "Q - Setting");
menu.combo:boolean('q', 'Use Q', true);
menu.combo:boolean('q2', '^ Use Q2', true);
menu.combo:slider("daleu", "^~ Daley Q2", 100, 0, 500, 1);
menu.combo:header("headW", "W - Setting");
menu.combo:boolean('w', 'Use W', true);
menu.combo:menu('winte', 'Items - W');
for i, item in pairs(Items) do 
    if item.displayname == "" then
        item.displayname = i
    end
    menu.combo.winte:menu(i, ""..i, true)
    if item.ID == 3153 then 
        menu.combo.winte[i]:boolean('3153canuse', 'Use Item', true);
        menu.combo.winte[i]:slider("3153", "Min. Enemy Health", 75, 0, 100, 1);
    end
    if item.ID == 3030 then
        menu.combo.winte[i]:boolean('3030canuse', 'Use Item', true);
        menu.combo.winte[i]:slider("3030", "Min. Enemy Health", 100, 0, 100, 1);
    end
    if item.ID == 3146 then
        menu.combo.winte[i]:boolean('3146canuse', 'Use Item', true);
        menu.combo.winte[i]:slider("3146", "Min. Enemy Health", 50, 0, 100, 1);
    end
    if item.ID == 3152 then 
        menu.combo.winte[i]:boolean('3152canuse', 'Use Item', true);
        menu.combo.winte[i]:slider("3152", "Min. Enemy Health", 65, 0, 100, 1);
    end
    if item.ID == 3143 then 
        menu.combo.winte[i]:boolean('3143canuse', 'Use Item', true);
        menu.combo.winte[i]:slider("3143", "Min. Myhero Health", 65, 0, 100, 1);
    end
    if item.ID == 3107 then 
        menu.combo.winte[i]:boolean('3107canuse', 'Use Item for kill enemy', true);
        menu.combo.winte[i]:boolean('3107save', 'Use Item for save player/allys', true);
        menu.combo.winte[i]:slider("3143", "Min. Myhero/Allys Health", 35, 0, 100, 1);
    end
    if item.ID == 3800 then 
        menu.combo.winte[i]:boolean('3800canuse', 'Use Item', true);
    end
    if item.ID == 3905 then 
        menu.combo.winte[i]:boolean('3905canuse', 'Use Item', true);
    end
    if item.ID == 3142 then 
        menu.combo.winte[i]:boolean('3905canuse', 'Use Item', true);
    end
    if item.ID == 3157 then 
        menu.combo.winte[i]:boolean('3157canuse', 'Use Item', true);
        menu.combo.winte[i]:slider("3143", "Min. Myhero Health", 20, 0, 100, 1);
    end
end
menu.combo:header("headE", "E - Setting");
menu.combo:boolean('e', 'Use E', true);
menu.combo:boolean('ewall', 'Use W in wall', false);
menu.combo:header("headR", "R - Setting");
menu.combo:menu("ult", "Ultimate - R");
menu.combo.ult:keybind("keyactive", "Key || R", nil, "T")
menu.combo.ult:boolean('r', 'Use R', true);
-->>Harass<<--
menu:menu("harass", "Harass");
menu.harass:boolean("q", "Use Q", true);
menu.harass:boolean("e", "Use E", false);
menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 25, 0, 100, 1);
-->>Misc<<--
menu:menu("misc", "Misc");
menu.misc:boolean("egab", "Use E on hero inter/dashing", true);
-->>Display<<--
menu:menu("dis", "Display");
menu.dis:boolean("qd", "Q Range", true);
menu.dis:boolean("wd", "W Range || Minimap", false);
menu.dis:boolean("ed", "E Range", false);
menu.dis:boolean("rd", "R Range || Engage", true);

local RotateAroundPoint = function(v1, v2, angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    local x = ((v1.x - v2.x) * cos) - ((v2.z - v1.z) * sin) + v2.x
    local z = ((v2.z - v1.z) * cos) + ((v1.x - v2.x) * sin) + v2.z
    return vec3(x, v1.y, z or 0)
end

local function CirclePoints(CircleLineSegmentN, radius, position)
    local points = {}
    for i = 1, CircleLineSegmentN, 1 do
        local angle = i * 2 * math.pi / CircleLineSegmentN
        local point = vec3(position.x + radius * math.cos(angle), position.y + radius * math.sin(angle), position.z);
        table.insert(points, point)
    end 
    return points 
end

local TargetSelectionQ = function(res, obj, dist)
    if menu.combo.ult.keyactive:get() == true and player:spellSlot(3).state == 0 then
        if dist < 800+575 then
            res.obj = obj
            return true
        end
    else
        if dist < 800 then
            res.obj = obj
            return true
        end
    end
end

--[[
    [12:05] Spell name: ZoeQ
[12:05] Speed:1200
[12:05] Width: 70
[12:05] Time:0.25
[12:05] Animation: 1
[12:05] false
[12:05] CastFrame: 0.2351156771183

    [12:05] Spell name: ZoeQMissile
[12:05] Speed:1200
[12:05] Width: 50
[12:05] Time:0.25
[12:05] Animation: 0.25
[12:05] false
[12:05] CastFrame: 0.2351156771183


local lastDebugPrint = 0
cb.add(cb.spell, function(spell)
    if(spell.owner == player) then
        if os.clock() - lastDebugPrint >= 2 then
            print("Spell name: " ..spell.name);
            print("Speed:" ..spell.static.missileSpeed);
            print("Width: " ..spell.static.lineWidth);
            print("Time:" ..spell.windUpTime);
            print("Animation: " ..spell.animationTime);
            print(spell.isBasicAttack);
            print("CastFrame: " ..spell.clientWindUpTime);
            print('--------------------------------------');
            lastDebugPrint = os.clock();
        end
    end
end)]]

local function CastQ(target)
    if player:spellSlot(0).name == "ZoeQ" then 
        local PlayerToPos = vec3(player.x, player.y, player.z);
        PlayerToPos = player.pos + (target.pos - player.pos):norm() * -800
        local Pos = PlayerToPos;
        local PosCast = false;
        local argsColision = {
            minion = 0,
            enemyHeros = 1
        }
        for i = 0, 359, 22.5 do
            local angle = i * (math.pi/180)
  
            local myPos = vec3(player.x, player.y, player.z)
            local tPos = vec3(target.x, target.y, target.z)
  
            local rot = RotateAroundPoint(Pos, myPos, angle)
            local pred_input = {
                delay = 0.25,
                speed = 1200,
                width = 70,
                boundingRadiusMod = 1,
                range = 800,
                collision = {
                  minion = true, --checks collision for minions
                  wall = true, --checks collision for yasuo wall or braum shield
                  hero = true, --no need to check for hero collision
                },
            }
            local seg = pred.linear.get_prediction(pred_input, target)
            if not pred.collision.get_prediction(pred_input, seg, target) then
                if rot then
                    --local Check = prediction.CheckMinionCollision(target.pos, target.pos, 0.25, 70, 800+575, true, argsColision, 1200, player)
                    --if not Check then
                        local CheckCollision = prediction.CheckMinionCollision(target.pos, rot, 0.25, 70, 800+575, true, argsColision, 1200, player)
                        if not CheckCollision then
                            player:castSpell("pos", 0, rot)
                            PosCast = true;
                        end
                    --end
                end 
            end
        end 

        if (PosCast) then 
            local argsColision = {
                minion = 0,
                enemyHeros = 1
            }
            local CheckCollision = prediction.CheckMinionCollision(target.pos, PlayerToPos, 0.25, 70, 800+575, true, argsColision, 1200, player)
            if player.pos:dist(target) > 800 and not CheckCollision then 
                if (rBeforeQ) then
                    local posCastR = player.pos + (target.pos - player.pos):norm() * -575
                    --Player.Position.Extend(target.Position, -r.Range);
                    player:castSpell("pos", 3, posCastR);
                    rBeforeQ = false;
                    common.setDelayAction(function() 
                        common.setDelayAction(function() 
                            qCanCast = true;
                        end, 0.25+ network.latency)
                    end,0.25)
                else
                    qCanCast = false;
                    common.setDelayAction(function() 
                        if (rAfterQ) then 
                            local posCastR = player.pos + (target.pos - player.pos):norm() * 575
                            --Player.Position.Extend(target.Position, r.Range);
                            player:castSpell("pos", 3, posCastR)
                            rAfterQ = false;
                        end
                        qCanCast = true;
                    end, 0)
                end
            end
            PosCast = false;
        end
    elseif (qCanCast) then 
        local pred_input = {
            delay = 0.25,
            speed = 1200,
            width = 70,
            boundingRadiusMod = 1,
            range = 800,
            collision = {
              minion = true, --checks collision for minions
              wall = true, --checks collision for yasuo wall or braum shield
              hero = true, --no need to check for hero collision
            },
        }
        local seg = pred.linear.get_prediction(pred_input, target)
        if seg and seg.startPos:dist(seg.endPos) < 800 then 
            if not pred.collision.get_prediction(pred_input, seg, target) then
                player:castSpell('pos', 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end
        end
    end
end

local function CastE(target)
    local pred_input = {
        delay = 0.30000001192093,
        speed = 1700,
        width = 40,
        boundingRadiusMod = 1,
        range = 800,
        collision = {
          minion = true, --checks collision for minions
          wall = true, --checks collision for yasuo wall or braum shield
          hero = true, --no need to check for hero collision
        },
    }
    local seg = pred.linear.get_prediction(pred_input, target)
    if seg and seg.startPos:dist(seg.endPos) < 800 then 
        if not pred.collision.get_prediction(pred_input, seg, target) then
            player:castSpell('pos', 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
        end 
    end
end

local function Combo()
    local target = ts.get_result(TargetSelectionQ).obj;
    if target and common.IsValidTarget(target) then 
        if player:spellSlot(3).state == 0 then
            if (target == nil) then 
                local target = ts.get_result(TargetSelectionR).obj;
                if  (target == nil) then
                    return;
                else
                    rAfterQ = true;
                end
            else
                rBeforeQ = true;
            end
        end
        if (target == nil) then 
            return 
        end
        if player:spellSlot(0).state == 0 then
            if (menu.combo.e:get()) then
                CastE(target)
            end 
            if menu.combo.ewall:get() then 
                for i = 0, 800, 150 do 
                    local pred_input = {
                        delay = 0.30000001192093,
                        speed = 1700,
                        width = 40,
                        boundingRadiusMod = 1,
                        range = 800,
                        collision = {
                          minion = true, --checks collision for minions
                          wall = true, --checks collision for yasuo wall or braum shield
                          hero = true, --no need to check for hero collision
                        },
                    }
                    local seg = pred.linear.get_prediction(pred_input, target)
                    if seg and seg.startPos:dist(seg.endPos) < 1500 then 
                        if not pred.collision.get_prediction(pred_input, seg, target) then
                            local Unitpos = vec3(seg.endPos.x, target.y, seg.endPos.y)
                            local PosToTarger = player.pos + (Unitpos - player.pos):norm() * i 
                            local PosToTwo = Unitpos + (PosToTarger - Unitpos):norm() * i
                            local Wallpos = navmesh.isWall(PosToTarger) 
                            if navmesh.isWall(PosToTarger) then
                                player:castSpell('pos', 2, PosToTarger)
                            end
                        end 
                    end
                end
            end
        end
        if player:spellSlot(0).state == 0 and menu.combo.q:get() then
            CastQ(target);
            rBeforeQ = false;
            rAfterQ = false;
        end
    end
    if player:spellSlot(3).state == 0 and (menu.combo.ult.keyactive:get() == true and menu.combo.ult.r:get())  then
        target = ts.get_result(TargetSelectionR).obj;
        if target and common.IsValidTarget(target) then 
            if (player:spellSlot(0).name == "ZoeQRecast") then 
                local pred_input = {
                    delay = 0.25,
                    speed = 1200,
                    width = 70,
                    boundingRadiusMod = 1,
                    range = 800,
                    collision = {
                        minion = true, --checks collision for minions
                        wall = true, --checks collision for yasuo wall or braum shield
                        hero = true, --no need to check for hero collision
                    },
                }
                local seg = pred.linear.get_prediction(pred_input, target)
                if seg and seg.startPos:dist(seg.endPos) < 800+575 and target.pos:dist(player.pos) > 800 then 
                    if not pred.collision.get_prediction(pred_input, seg, target) then
                        player:castSpell('pos', 3, target.pos)
                    end 
                end
            elseif common.getBuffValid(target, 'zoeesleepcountdown')  then 
                local posCastR = player.pos + (target.pos - player.pos):norm() * -575
                --Player.Position.Extend(target.Position, r.Range);
                if player:spellSlot(0).state == 0 and  player:spellSlot(0).name == "ZoeQ" then
                    player:castSpell("pos", 3, posCastR)
                    player:castSpell("pos", 0, mousePos)
                end
            end
        end
    end
    local target_not_invisible = ts.get_result(TargetSelectionR).obj;
    if target_not_invisible and not target_not_invisible.isVisible then 
        for _, obj in pairs(Sleep_Particle) do 
            if obj then 
                if obj.pos:dist(target.pos) < 800 then
                    CastQ(obj)
                end
            end
        end
    end
end 

local function Harass()
  
end

local function on_tick()
    if (player.isDead) then return end  

    if menu.misc.egab:get() then 
        for i = 0, objManager.enemies_n - 1 do
			local dasher = objManager.enemies[i]
			if dasher.type == TYPE_HERO and dasher.team == TEAM_ENEMY then
				if dasher and common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and player.pos:dist(dasher.path.point[1]) < 800 then
					if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[0]) then
						if ((player.health / player.maxHealth) * 100 <= 100) then
							player:castSpell("pos", 2, dasher.path.point2D[1])
						end
					end
				end
			end
        end
    end

    if (orb.combat.is_active()) then 
        Combo();
    end

    if orb.menu.hybrid.key:get() then 
        if (player.mana / player.maxMana) * 100 >= menu.harass.Mana:get() then  
            Harass();
        end
    end
    --[[for i, target in pairs(common.getEnemyHeroes()) do 
        if target then
            if common.getBuffValid(target, 'zoeesleepcountdown') then 
                chat.print('ehehe')
            end
        end 
    end]]
end

local function on_create_particle(obj) --E_Tar_Sleep
    --if obj.name and obj.name:lower():find("zoe") then print("Created: "..obj.name) end
    if obj then 
        --if obj.name and obj.name:lower():find("warwick") then print("Created "..obj.name) end
        if obj.name:find("E_Tar_Sleep") then
            Sleep_Particle[obj.ptr] = obj
        end
    end
end 

local function on_delete_particle(obj)
    if obj then 
        Sleep_Particle[obj.ptr] = nil
    end
end

local function on_draw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(0).state == 0 and menu.dis.qd:get()) then 
            graphics.draw_circle(player.pos, 800, 1, graphics.argb(255, 139, 81, 254), 30)
        end
        if (player:spellSlot(1).state == 0 and menu.dis.wd:get()) then 
            minimap.draw_circle(player.pos, 2200, 1, graphics.argb(255,139, 81, 254), 30)
        end
        if (player:spellSlot(2).state == 0 and menu.dis.ed:get()) then 
            graphics.draw_circle(player.pos, 800, 1, graphics.argb(255,139, 81, 254), 30)
        end
        if (player:spellSlot(3).state == 0 and menu.dis.rd:get()) then 
            graphics.draw_circle(player.pos, 800+575, 2, graphics.argb(255,139, 81, 254), 30)
        end
        local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
        if menu.combo.ult.keyactive:get() == true then
			graphics.draw_text_2D("Use R In Combo: On", 18, pos.x - 60, pos.y + 30, graphics.argb(255,233, 200, 23))
		else
			graphics.draw_text_2D("Use R In Combo: Off", 18, pos.x - 60, pos.y + 30, graphics.argb(255, 233, 200, 23))
        end
    end
    local target = ts.get_result(TargetSelectionQ).obj;
    if target and common.IsValidTarget(target) then 
        local PlayerToPos = vec3(player.x, player.y, player.z);
        PlayerToPos = player.pos + (target.pos - player.pos):norm() * -800
        local Pos = PlayerToPos;
        local PosCast = false;
        local argsColision = {
            minion = 0,
            enemyHeros = 1
        }
        for i = 0, 360, 22.5 do
            local angle = i * (math.pi/180)
  
            local myPos = vec3(player.x, player.y, player.z)
            local tPos = vec3(target.x, target.y, target.z)
  
            local rot = RotateAroundPoint(Pos, myPos, angle)
            local rot2 = RotateAroundPoint(tPos, rot, angle)
            local pred_input = {
                delay = 0.25,
                speed = 1200,
                width = 70,
                boundingRadiusMod = 1,
                range = 800,
                collision = {
                  minion = true, --checks collision for minions
                  wall = true, --checks collision for yasuo wall or braum shield
                  hero = true, --no need to check for hero collision
                },
            }

                if rot then
                    graphics.draw_circle(rot, 150, 1, graphics.argb(255,139, 81, 254), 30)
                end 
            
        end
    end
end 

orb.combat.register_f_pre_tick(on_tick);

cb.add(cb.draw, on_draw);
cb.add(cb.create_particle, on_create_particle);
cb.add(cb.delete_particle, on_delete_particle);