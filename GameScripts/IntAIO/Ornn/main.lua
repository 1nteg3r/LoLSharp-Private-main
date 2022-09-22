local orb = module.internal("orb");
local pred = module.internal("pred");
local TS = module.load(header.id, "TargetSelector/targetSelector")
local common = module.load(header.id, 'Library/common');
local damageLib = module.load(header.id, 'Library/damageLib');
local TargetPred = module.internal("TS")

local Pillar = { }
local Body = { }

local pred_w_input = {
    --[[
    [01:07] Spell name: OrnnW
[01:07] Speed:1600
[01:07] Width: 0
[01:07] Time:0.25
[01:07] Animation: 1
[01:07] CastFrame: 0.30973452329636
    ]]

    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.25,
    speed = 1600,
    width = 125,
    range = 500,
    collision = { hero = false, minion = false, wall = false },
};


local pred_q_input = {
    --[[
[01:20] Spell name: OrnnQ
[01:20] Speed:1800
[01:20] Width: 65
[01:20] Time:0.30000001192093
[01:20] Animation: 1
[01:20] CastFrame: 0.30583712458611
    ]]

    boundingRadiusModSource = 1,
    boundingRadiusMod = 1,
    delay = 0.30,
    speed = 1800,
    width = 65,
    range = 800,
    collision = { hero = false, minion = false, wall = true },
};

local function trace_filter(Input, seg, obj)
    local totalDelay = (Input.delay + network.latency)

    if seg.startPos:dist(seg.endPos)
            + (totalDelay * obj.moveSpeed)
            + obj.boundingRadius > Input.range then
        return false
    end

    local collision = pred.collision.get_prediction(Input, seg, obj)
    if collision then
        return false
    end

    if pred.trace.linear.hardlock(Input, seg, obj) then
        return true
    end

    if pred.trace.linear.hardlockmove(Input, seg, obj) then
        return true
    end

    local t = obj.moveSpeed / Input.speed

    if pred.trace.newpath(obj, totalDelay, totalDelay + t) then
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

        local seg = pred.linear.get_prediction(input, obj)

        if not seg then
            return false
        end

        res.seg = seg
        res.obj = obj

        if not trace_filter(input, seg, obj) then
            return false
        end

        local t1 = Compute(input, seg, obj)

        if t1 < 0 then
            return false
        end

        res.pos = (pred.core.get_pos_after_time(obj, t1) + seg.endPos) / 2

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

local menu = menu("IntnnerOrnn", "Int Ornn");
    menu:header("xs", "Core");
    TS = TS(menu, 2550)
    TS:addToMenu()
    menu:menu('combo', "Combo");
    menu.combo:boolean('q', 'Use Q', true);
    menu.combo:boolean('w', 'Use W', true);
    menu.combo:boolean('e', 'Use E', true);
    menu.combo:header("headrE", "R - Setting");
    menu.combo:menu("ult", "Ultimate - R");
    menu.combo.ult:boolean('r', 'Use R', true);
    menu.combo.ult:keybind("under", "Semi-R", "G", false)
    --menu.combo.ult:dropdown('mode', 'Mode R', 3, {'Never', 'Always', 'Killable'});
    -->>Harass<<--
    menu:menu("harass", "Harass");
    menu.harass:boolean("q", "Use Q", true);
    menu.harass:boolean("w", "Use W", false);
    menu.harass:boolean("e", "Use E", false);
    menu.harass:slider("Mana", "Minimum Mana Percent >= {0}", 25, 0, 100, 1);
    -->>Misc<<--
    menu:menu("misc", "Misc");
    menu.misc:boolean("kil", "Killable", true);
    menu.misc:boolean("egab", "Use E on gapclose spells", true);
    menu.misc:boolean("channeling", "Use E on channeling spells", true);

    menu:menu('draws', "Drawings")
    menu.draws:boolean("qrange", "Draw Q Range", true)
    menu.draws:color("qcolor", "Q Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("wrange", "Draw W Range", false)
    menu.draws:color("wcolor", "W Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("erange", "Draw E Range", false)
    menu.draws:color("ecolor", "E Drawing Color", 255, 255, 255, 255)
    menu.draws:boolean("rrange", "Draw R Range (MiniMap)", true)
    menu.draws:color("rcolor", "R Drawing Color", 255, 255, 255, 255)


local function CreateObj(obj)
    if obj then
        if obj.name:find("Q_tar") then
            Pillar[obj.ptr] = obj
        end
        if obj.name:find("R_Wave_Mis") then
            Body[obj.ptr] = obj
		end
    end
    --if obj and obj.name:lower():find("ornn") then print("Created: "..obj.name) end
end

local function DeleteObj(obj)
	if obj then
        Pillar[obj.ptr] = nil
        Body[obj.ptr] = nil
	end
end


local function Combo()
    if menu.combo.e:get() then 
        TS.range = 800
        TS:OnTick()
        local target = TS.target

        if target and target ~= nil then 
            for i, Pilar in pairs(Pillar) do 
                if Pilar then 

                    local pred_pos = pred.core.lerp(target.path, network.latency + 0.30, target.moveSpeed)

                    if not pred_pos then 
                        return 
                    end 

                    local CastPosition = vec3(pred_pos.x, target.y, pred_pos.y)
                    if Pilar.pos:dist(CastPosition) <= 350 then 
                        player:castSpell("pos", 2, Pilar.pos)
                    end
                end 
            end 

            for k = 1, 5, 1 do
                local e_source = target.pos + (400/5*k) * (target.pos - player.pos):norm()
                if navmesh.isWall(e_source) and e_source:dist(target) < 350 and player.pos:dist(e_source) < 800 then
                    player:castSpell("pos", 2, e_source)
                end 
            end 
        end 
    end 

    if menu.combo.w:get() then 
        local target = TargetPred.get_result(real_target_filter(pred_w_input).Result) 
        if target.obj and target.pos and common.IsValidTarget(target.obj) then 
            if player:spellSlot(1).state == 0 then 
                player:castSpell('pos', 1, vec3(target.pos.x, mousePos.y, target.pos.y))
            end 
        end
    end 

    if menu.combo.q:get() then 
        local target = TargetPred.get_result(real_target_filter(pred_q_input).Result) 
        if target.obj and target.pos and common.IsValidTarget(target.obj) then 
            if player:spellSlot(0).state == 0 then 
                player:castSpell('pos', 0, vec3(target.pos.x, mousePos.y, target.pos.y))
            end 
        end
    end 

    if menu.combo.ult.r:get() then 

        TS.range = 2550
        TS:OnTick()
        local target = TS.target

        if target and target ~= nil then 


            for i, Caba in pairs(Body) do 
                if Caba then

                    local pred_pos = pred.core.lerp(target.path, network.latency + 0.30, target.moveSpeed)
        
                    if not pred_pos then 
                        return 
                    end 

                    local CastPosition = vec3(pred_pos.x, target.y, pred_pos.y)

                    if player:spellSlot(3).name == "OrnnRCharge" and player.pos:dist(Caba.pos) <= 350 then 
                        player:castSpell('line', 3, CastPosition, Caba.pos)
                    end
                end 
            end

        end
    end
end 


local function Harass()
    if common.GetPercentMana(player) >= menu.harass.Mana:get() then 
        
        if menu.harass.q:get() then 
            local target = TargetPred.get_result(real_target_filter(pred_q_input).Result) 
            if target.obj and target.pos and common.IsValidTarget(target.obj) then 
                if player:spellSlot(0).state == 0 then 
                    player:castSpell('pos', 0, vec3(target.pos.x, mousePos.y, target.pos.y))
                end 
            end
        end 

        if menu.harass.w:get() then 
            local target = TargetPred.get_result(real_target_filter(pred_w_input).Result) 
            if target.obj and target.pos and common.IsValidTarget(target.obj) then 
                if player:spellSlot(1).state == 0 then 
                    player:castSpell('pos', 1, vec3(target.pos.x, mousePos.y, target.pos.y))
                end 
            end
        end 
    
        if menu.harass.e:get() then 
            TS.range = 800
            TS:OnTick()
            local target = TS.target
    
            if target and target ~= nil then 
                for i, Pilar in pairs(Pillar) do 
                    if Pilar then 
    
                        local pred_pos = pred.core.lerp(target.path, network.latency + 0.30, target.moveSpeed)
    
                        if not pred_pos then 
                            return 
                        end 
    
                        local CastPosition = vec3(pred_pos.x, target.y, pred_pos.y)
                        if Pilar.pos:dist(CastPosition) <= 350 then 
                            player:castSpell("pos", 2, Pilar.pos)
                        end
                    end 
                end 
    
                for k = 1, 5, 1 do
                    local e_source = target.pos + (400/5*k) * (target.pos - player.pos):norm()
                    if navmesh.isWall(e_source) and e_source:dist(target) < 350 and player.pos:dist(e_source) < 800 then
                        player:castSpell("pos", 2, e_source)
                    end 
                end 
            end 
        end 

    end 
end 

local function SemiR()
    player:move(mousePos)
    TS.range = 2550
    TS:OnTick()
    local target = TS.target

    if target and target ~= nil then 
        
        local pred_pos = pred.core.lerp(target.path, network.latency + 0.30, target.moveSpeed)
    
        if not pred_pos then 
            return 
        end 

        local CastPosition = vec3(pred_pos.x, target.y, pred_pos.y)

        if player:spellSlot(3).name ~= "OrnnRCharge" and target.pos:dist(player) < 2550 then 
            player:castSpell('pos', 3, CastPosition)
        end 


        for i, Caba in pairs(Body) do 
            if Caba then

                if player:spellSlot(3).name == "OrnnRCharge" and player.pos:dist(Caba.pos) <= 350 then 
                    player:castSpell('line', 3, CastPosition, Caba.pos)
                end
            end 
        end
    end 
end 

--buff name W: OrnnVulnerableDebuff
-- Execute tar

local function Ontick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

    if orb.menu.combat.key:get() then 
        Combo()
    elseif orb.menu.hybrid.key:get() then 
        Harass()
    elseif menu.combo.ult.under:get() then 
        SemiR()
    end 
end 

local function ondraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.draws.qrange:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 800, 1, menu.draws.qcolor:get(), 40)
        end
        if (menu.draws.wrange:get() and player:spellSlot(1).state == 0) then
            graphics.draw_circle(player.pos, 500, 1, menu.draws.wcolor:get(), 40)
        end
        if (menu.draws.erange:get() and player:spellSlot(2).state == 0) then
            graphics.draw_circle(player.pos, 650, 1, menu.draws.ecolor:get(), 40)
        end
        if (menu.draws.rrange:get() and player:spellSlot(3).state == 0) then
            minimap.draw_circle(player.pos, 2550, 1, menu.draws.rcolor:get(), 100)
        end
    end
end


--[[cb.add(cb.tick, function()
    local target =
		ts.get_result(
		function(res, obj, dist)
			if dist <= 1000 then --add invulnverabilty check
				res.obj = obj

				return true
			end
		end
	).obj
    if target then
        local timerbuff = game.time
        for i, buff in pairs(target.buff) do
            if buff and buff.valid then
                if buff.name == 'OrnnVulnerableDebuff' then
                --if buff.name:lower():find("ornn") then --OrnnVulnerableDebuff
                    
                    chat.print('asdjasdhasdahsdah')
                    timerbuff = game.time
                end
            end
        end
    end

    [01:07] Spell name: OrnnW
[01:07] Speed:1600
[01:07] Width: 0
[01:07] Time:0.25
[01:07] Animation: 1
[01:07] CastFrame: 0.30973452329636
[01:07] --------------------------------------
[01:20] Spell name: OrnnQ
[01:20] Speed:1800
[01:20] Width: 65
[01:20] Time:0.30000001192093
[01:20] Animation: 1
[01:20] CastFrame: 0.30583712458611
[01:20] --------------------------------------
[01:27] Spell name: OrnnR
[01:27] Speed:1600
[01:27] Width: 0
[01:27] Time:0.5
[01:27] Animation: 1
[01:27] CastFrame: 0.28527182340622
[01:27] --------------------------------------
[01:30] Spell name: OrnnRCharge
[01:30] Speed:1600
[01:30] Width: 0
[01:30] Time:0
[01:30] Animation: 1
[01:30] CastFrame: 0.28527182340622
[01:30] --------------------------------------
end)]]

orb.combat.register_f_pre_tick(Ontick);

cb.add(cb.draw, ondraw)
cb.add(cb.create_particle, CreateObj)
cb.add(cb.delete_particle, DeleteObj)