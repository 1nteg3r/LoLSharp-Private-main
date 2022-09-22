local vayne = { }

local orb = module.internal("orb");
local pred = module.internal("pred")
local evade = module.seek('evade')
local common = module.load("marksman", "common")
local TS = module.internal("TS");

vayne.IsPreAttack = false; 
vayne.IsPostAttack = false;
vayne.StartTime = 0
vayne.EndTime = 0 
vayne.LifeTime = 0 

vayne.menu = menu("dasjhdashdashda", "Marksman - Vayne")
    --Q:
    vayne.menu:header('XWDD', 'Tumble - Q');
    vayne.menu:boolean('q', 'Use Q', true);
    vayne.menu:dropdown("emode", "^ Q Tuble", 4, {"Mouse", "Auto", "Position", "Smart"})
    vayne.menu:dropdown("direc", "Q - Direction", 3, {"Everywhere", "Only to side", "Only forward/backward"})
    vayne.menu:boolean('BlockQsOutOfAARange', '^ Block Q Out Of AA-Range', false);
    vayne.menu:boolean('ae', '^ Q To E Position If Possible', true); --BlockQsOutOfAARange 
    vayne.menu:boolean('qoutaa', '^ Use Q out AA range', true);
    vayne.menu:boolean('safecheck', 'Enable safety checks', false);
    --W:
    vayne.menu:header('XWD', 'Silver Bolts - W');
    vayne.menu:boolean('force', 'Force Target?', false);
    --E:
    vayne.menu:header('XED', 'Condemn - E');
    vayne.menu:boolean('e', 'Use E', true);
    vayne.menu:dropdown('mode', 'Mode E:', 2, {'Is Position', 'Smart'});
    vayne.menu:boolean('dsad', '^ Anti-Melee?', true);
    vayne.menu:boolean('int', '^ Interrupt spells', true);
    vayne.menu:boolean('close', '^ Gapclosing spells', true);
    --R:
    vayne.menu:header('XED', 'Final Hour - R');
    vayne.menu:boolean('r', 'Use R', true);
    vayne.menu:boolean('block', '^ Disable AA while invisible', true);
    vayne.menu:slider('dist', "^~ Distance AA Range?", 350, 1, 550, 1);
    vayne.menu:slider('range', "^ Max enemies range", 2, 1, 5, 1);

local e_pred = {
    delay = 0.25; 
    radius = common.GetAARange();
    speed = 2200; 
    dashRadius = 0;
    boundingRadiusModSource = 1;
    boundingRadiusModTarget = 1;
};

vayne.e_pred = function(res, obj, dist)
	if dist > 1000 then return end
	if pred.present.get_prediction(e_pred, obj) then
      	res.obj = obj
      	return true
    end
end

local function Floor(number) 
    return math.floor((number) * 100) * 0.01
end

local function IsECastableOnEnemy(unit, checkFrom)
    if player:spellSlot(2).state == 0  and common.IsValidTarget(unit) and unit:dist(checkFrom) <= 550 and (not unit.buff["rocketgrab"] or not unit.buff["sivire"]  or not unit.buff["fioraw"]) then 
        return true 
    end
    return false
end

local function HasSilverDebuff(unit)
    return unit.buff['VayneSilveredDebuff']
end 

local function IsAheadOfPlayer(point)
    if (player.path.serverPos  - player.pos):norm():dot((point - player.pos):norm()) > 0.55 then 
        return true 
    end 
    return false
end 

local function IsBehindPlayer(point)
    if (player.path.serverPos - player.pos):norm():dot((point - player.pos):norm()) < -0.55 then 
        return true 
    end 
    return false
end

local function IsDangerousPosition(pos)
    if common.IsUnderDangerousTower(pos) then return true 
    end
  	for i = 0, objManager.enemies_n - 1 do
        local unit = objManager.enemies[i] 
        if unit then
            if not unit.isDead and common.GetDistance(pos, unit) < 300 then 
                return true 
            end
        end
    end
    return false
end

local function GetAggressiveTumblePos(target)
    local targetPos = vec3(target.x, target.y, target.z)
    if common.GetDistance(targetPos, mousePos) < common.GetDistance(targetPos) then 
        return game.mousePos 
    end
end

local function GetKitingTumblePos(target)
    local targetPos = vec3(target.x, target.y, target.z)
    local myHeroPos = vec3(player.x, player.y, player.z) 
    local possiblePos = myHeroPos + (mousePos - myHeroPos):norm() * 300
    if not IsDangerousPosition(possiblePos) and common.GetDistance(targetPos, possiblePos) > common.GetDistance(targetPos) then return possiblePos end
end

local function GetSmartTumblePos(target)
    local myHeroPos = vec3(player.x, player.y, player.z) or vec3(0,0,0)
    local possiblePos = myHeroPos + (mousePos - myHeroPos):norm() * 300 or vec3(0,0,0)
    local targetPos = vec3(target.x, target.y, target.z) or vec3(0,0,0)   
    local p0 = myHeroPos    
    local points= {
    [1] = p0 + vec3(300,0,0),
    [2] = p0 + vec3(277,0,114),
    [3] = p0 + vec3(212,0,212),
    [4] = p0 + vec3(114,0,277),
    [5] = p0 + vec3(0,0,300),
    [6] = p0 + vec3(-114,0,277),
    [7] = p0 + vec3(-212,0,212),
    [8] = p0 + vec3(-277,0,114),
    [9] = p0 + vec3(-300,0,0),
    [10] = p0 + vec3(-277,0,-114),
    [11] = p0 + vec3(-212,0,-212),
    [12] = p0 + vec3(-114,0,-277),
    [13] = p0 + vec3(0,0,-300),
    [14] = p0 + vec3(114,0,-277),
    [15] = p0 + vec3(212,0,-212),
    [16] = p0 + vec3(277,0,-114)}
    ---
    for i=1,#points do      
        if IsDangerousPosition(points[i]) == false and common.GetDistanceSqr(points[i], targetPos) < 500 * 500 then
            if (navmesh.isWall(targetPos + (myHeroPos - targetPos):norm() * -450)) then
                return points[i]
            end 
        end
    end
    if IsDangerousPosition(possiblePos) == false then
        return possiblePos
    end 
    for i=1,#points do
        if IsDangerousPosition(points[i]) == false and common.GetDistanceSqr(points[i], targetPos) < 500 * 500  then --and GetDistance(points[i],mousePos) <= GetDistance(bestPos, mousePos)
            return points[i]
        end
    end     
end

local spells = { }
spells.interrupt = {}

spells.interrupt.names = { -- names of dangerous spells
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

spells.interrupt.times = {6, 1, 1, 5, 1.5, 0.75, 3, 3, 2.5, 2, 0.5, 2.5, 4, 3, 3, 2, 3, 1.5, 4, 1.5, 3};

local interrupt_data = { }
local function on_spell(spell) 
    if not vayne.menu.int:get() then return end
    if not spell or not spell.name or not spell.owner then return end
    if spell.owner.isDead then return end
    if spell.owner.team == player.team then return end
    if player.pos:dist(spell.owner.pos) > player.attackRange + (player.boundingRadius) then return end	

    for i = 0, #spells.interrupt.names do
        if (spells.interrupt.names[i] == string.lower(spell.name)) then
            interrupt_data.start = os.clock();
            interrupt_data.channel = spells.interrupt.times[i];
            interrupt_data.owner = spell.owner;
        end
    end
end 

local function IsValidDashDirection(dashPosition)
    if (vayne.menu.direc:get() == 1) then
        return true
    end

    if (((vayne.menu.direc:get() == 2) and math.abs((player.path.serverPos - player.pos):norm():dot((dashPosition - player.pos):norm())) < 0.55)) then 
        return true
    end

    if (vayne.menu.direc:get() == 3) and (IsAheadOfPlayer(dashPosition) or IsBehindPlayer(dashPosition)) then 
        return true 
    end
end

local function GetMovementBlockedDebuffDuration(target)
    local buff = target.buff
    if buff and buff.valid and buff.type == 24 or buff.type == 5 then 
        return (buff.endTime - game.time) * 1000
    end
    return 0
end

local function GetNumberInRangeFromProcent(percent, min, max)
    return (percent / 100 * (min - max) - min) * -1;
end

local function WillEStun(target, from, customHitchance, customPushDistance)
    local from = from or player 

    if IsECastableOnEnemy(target.pos, from) then return true end 

    local customPushDistance = customPushDistance or 400
    local customHitchance = customHitchance or 50
    local obj = TS.get_result(vayne.e_pred).obj;
	local checks = 5;
	local dist_check = customPushDistance / checks;
    local range = player.attackRange + (player.boundingRadius + target.boundingRadius);

    if vayne.menu.mode:get() == 1 then  
        if not obj then return end 
        local pred_pos = pred.core.lerp(obj.path, network.latency + 0.25, obj.moveSpeed)
        --pred.core.project(obj, obj.path, network.latency + 0.5, 2200, obj.moveSpeed) -- return vc2??
        --pred.core.project(target, target.path, 0.5, 1200, target.moveSpeed)
        local unitPos = vec3(pred_pos.x, obj.y, pred_pos.y);
        if player.pos:dist(unitPos) <= range then
            for k = 1, 5, 1 do
                local e_source = unitPos + (dist_check*k) * (unitPos - player.pos):norm()
                local e_last = os.clock();
                if navmesh.isWall(e_source) then
                    return true
                end
            end
        else 
            return nil
        end
    end
    if vayne.menu.mode:get() == 2 then  
        local pP = player.pos
        local eP =  target.pos
        local pD = 450
        local Brik = (eP + (pP - eP):norm() * -pD) or (eP + (pP - eP):norm() * -pD/2) or (eP + (pP - eP):norm()*-pD/3)
        if (navmesh.isWall(Brik)) then
            if GetMovementBlockedDebuffDuration(target)  > dist_check/1000 then
                return true
            end
        
            local enemiesCount = #common.CountEnemiesInRange(player.pos, 1200) 
            if enemiesCount > 1 and enemiesCount <= 3 then
                for i=15, pD, 75 do
                    local vec33 = eP + (pP - eP):norm() * -i
                    if navmesh.isWall(vec33) then
                        return true
                    end
                end
            else
                local hitchance = customHitchance
                local angle = 0.2 * hitchance
                local travelDistance = 0.5
                local alpha = vec3((eP.x + travelDistance * math.cos(math.pi/180 * angle)),eP.y ,(eP.z + travelDistance * math.sin(math.pi/180 * angle)))
                local beta = vec3((eP.x	- travelDistance * math.cos(math.pi/180 * angle)),eP.y, (eP.z - travelDistance * math.sin(math.pi/180 * angle)))
                for i=15, pD, 100 do
                    local col1 = alpha + (pP - alpha):norm() * -i
                    local col2 = beta + (pP - beta):norm() * -i
                    if i>pD then return end
                    if navmesh.isWall(col1) and navmesh.isWall(col2) then 
                        return true 
                    end
                end
                return false
            end
        end
    end
end 

local function OnPreAttack()
    vayne.IsPreAttack = true
end 

local function isInAutoAttackRange(target)
    return player.pos:dist(target.pos) <= common.GetAARange(player) 
end 
local function Combo()
    if (vayne.menu.e:get()) and player:spellSlot(2).state == 0 then 
        local target = TS.get_result(function(res, obj, dist)
            if (dist > 560 or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and common.IsValidTarget(obj) then
                res.obj = obj
                return true
            end 
        end).obj 
        if target then 
            if WillEStun(target) then 
                player:castSpell("obj", 2, target)
            end
        end 
    end
    if (vayne.menu.ae:get() and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and (#common.CountEnemiesInRange(player.pos, 1100) == 1) and (player.mana >= 120)) then
        local target = TS.get_result(function(res, obj, dist)
            if (dist > common.GetAARange() or obj.buff["rocketgrab"] or obj.buff["sivire"] or obj.buff["fioraw"]) then
                return
            end
            if obj and common.IsValidTarget(obj) then
                res.obj = obj
                return true
            end 
        end).obj 
        if target then 
            local CastPosE = player.pos + (mousePos - player.pos):norm() * 300
            if (WillEStun(target, CastPosE, 100, 440)) then
                player:castSpell("pos", 0, player.pos + (mousePos - player.pos):norm() * 285)
            end 

            for i= 0, 360, 45 do
                local angle = i * math.pi/180
                local targetPosition = vec3(target.x, target.y, target.z)
                local targetRotated = vec3(targetPosition.x + 400, targetPosition.y, targetPosition.z)
                local pos = vec3(common.RotateAroundPoint(targetRotated, targetPosition, angle))
                if pos and WillEStun(target, pos, 100, 440, 370) and common.IsUnderDangerousTower(pos) then
                    player:castSpell("pos", 0, player.pos + (mousePos - player.pos):norm() * 285)
                end
            end 
        end
    end 
    if (not vayne.IsPreAttack and player:spellSlot(0).state == 0 and vayne.menu.q:get() and vayne.menu.qoutaa:get()) then
        local enemies = #common.CountEnemiesInRange(player.pos, 2000)
        local target = common.GetTarget(common.GetAARange() + 320)
        local position = player.pos + (mousePos - player.pos):norm() * 299
        if ((target) and not common.IsMovingTowards(target, 300) and not common.IsUnderDangerousTower(position) and (common.GetPercentHealth(player) > common.GetPercentHealth(target)) and not isInAutoAttackRange(target) and (enemies == 1)) then
            local targetPos = TS.get_result(vayne.e_pred).obj;
            if targetPos then
                if (not common.IsInRange(300, targetPos, position) and common.IsInRange(common.GetAARange(), position, targetPos)) then
                    player:castSpell("pos", 0, position)
                end 
            end
        end  
    end

    if player:spellSlot(3).state == 0 and vayne.menu.r:get() then 
        local target = common.GetTarget(common.GetAARange() + 330)
        if target and common.IsValidTarget(target) and not common.IsUnderDangerousTower(target) then 
            local enemies = #common.CountEnemiesInRange(player.pos, common.GetAARange() + 330)
            if enemies < 3 and common.GetPercentHealth(player) >  25 then 
                player:castSpell("self", 3) 
            end
        end 
    end
end

local function OnTick()
    vayne.IsPreAttack = false
    vayne.IsPostAttack = false

    for i, buff in pairs(player.buff) do 
        if buff and buff.valid and buff.name == "VayneInquisition" then 
            vayne.StartTime = buff.startTime
            vayne.EndTime = buff.endTime 
            vayne.LifeTime = 8
        end 
    end 
    if not player.buff['vayneinquisition'] then 
        vayne.StartTime = 0
        vayne.EndTime = 0
        vayne.LifeTime = 0
    end

    vayne.LifeTime = Floor(vayne.EndTime - game.time)

    if player:spellSlot(2).state == 0 and vayne.menu.int:get() then 
        if interrupt_data.owner then 
            if player.pos:dist(interrupt_data.owner.pos) > player.attackRange + (player.boundingRadius) then return end


            if os.clock() - interrupt_data.channel >= interrupt_data.start then
                interrupt_data.owner = false;
                return
            end

            if os.clock() - 0.35 >= interrupt_data.start then
                player:castSpell("obj", 2, interrupt_data.owner);
                interrupt_data.owner = false;
            end
        end
    end

    if player:spellSlot(2).state == 0 and vayne.menu.close:get() then 
        local obj = TS.get_result(vayne.e_pred).obj;
        if obj and obj.path.isActive and obj.path.isDashing then

            local range = player.attackRange + (player.boundingRadius + obj.boundingRadius)
            if player.pos:dist(obj.pos) <= range then

                local pred_pos = pred.core.lerp(obj.path, network.latency + 0.25, obj.path.dashSpeed)
                if pred_pos then 
                    if pred_pos:dist(player.pos2D) <= range then
                        player:castSpell("obj", 2, obj)
                    end
                end 
            end
        end
    end

    if (orb.combat.is_active()) then
        Combo();
    end

end 

local function OnAfterAttack()
    local target = orb.combat.target
    if target and target.type == TYPE_HERO then 
        if (player:spellSlot(0).state == 0 and vayne.menu.q:get() and (not vayne.menu.force:get() or ((target) and HasSilverDebuff(target)))) then 
            --print'common' -- here
            local enemies = #common.CountEnemiesInRange(player.pos, 2000)
            local target = common.GetTarget(common.GetAARange() + 320)
            if (not vayne.menu.safecheck) then 
                local CastPosition = player.pos + (mousePos - player.pos):norm() * 300
                if not common.IsUnderDangerousTower(CastPosition) then 
                    local obj = TS.get_result(vayne.e_pred).obj;
                    if obj then
                        if common.IsInRange(common.GetAARange(), obj, player) and IsValidDashDirection(CastPosition) then 
                            player:castSpell("pos", 0, player.pos + (mousePos - player.pos):norm() * 285)
                        end 
                    end 
                end
            else 
                local ModeE = vayne.menu.emode:get() 
                if ModeE == 1 then 
                    if target then 
                        --print'dasdasdadd'
                        if ((player.health / player.maxHealth * 100) > target.health / target.maxHealth * 100) and common.GetPercentHealth(player) > 10 and #common.CountEnemiesInRange(target.pos, 1000) <= 2 then 
                            if not common.IsUnderDangerousTower(player.pos + (mousePos - player.pos):norm() * 285) and not target.isMelee or not common.IsInRange(common.GetAARange(),player.pos + (mousePos - player.pos):norm() * 285, target) or common.IsMovingTowards(target, 300) then 
                                local qPosition = player.pos + (mousePos - player.pos):norm() * 300
                                local obj = TS.get_result(vayne.e_pred).obj;
                                if not obj then return end
                                if (vayne.menu.BlockQsOutOfAARange:get() and not common.IsInRange(common.GetAARange(), qPosition, obj)) then return end 
                                if (IsValidDashDirection(qPosition)) then 
                                    --print'11'
                                    player:castSpell("pos", 0, qPosition)
                                end 
                            end 
                        end 
                    end
                elseif ModeE == 2 then 
                    if target and common.IsValidTarget(target) then 
                        local tpos = GetAggressiveTumblePos(target)
                        if tpos then 
                            player:castSpell("pos", 0, tpos)
                        end 
                    end
                elseif ModeE == 3 then 
                    if target and common.IsValidTarget(target) then 
                        local Tpos = GetKitingTumblePos(target)
                        if Tpos then 
                            player:castSpell("pos", 0, Tpos)
                        end 
                    end
                elseif ModeE == 4 then 
                    if target and common.IsValidTarget(target) then 
                        local Smartpos = GetSmartTumblePos(target)
                        if Smartpos then 
                            player:castSpell("pos", 0, Smartpos)
                        end 
                    end   
                end 
            end
        end 
    end
end 

local function on_issue_order(order, pos, target_ptr)
    if order == 3 then 
        local Target = TS.get_result(function(res, obj, dist)
            if dist <= vayne.menu.dist:get() and common.IsValidTarget(obj) then --add invulnverabilty check
                res.obj = obj
                return true
            end
        end).obj
        if Target ~= nil then 
            if (vayne.menu.block:get()) then    
                if player.buff['vaynetumblefade'] then 
                    core.block_input()
                end 
            end
        end
    end
end

local function OnDraw()
    if game.time > vayne.StartTime and game.time < vayne.EndTime then
        vayne.LifeTime = Floor(vayne.EndTime - game.time)
        local playerPos = graphics.world_to_screen(player.pos)
        local textWidth = graphics.text_area("1.00", 30)
        graphics.draw_text_2D(tostring(vayne.LifeTime), 30, playerPos.x - (textWidth / 2), playerPos.y, 0xFFffffff)
    end
end 
cb.add(cb.draw, OnDraw)

cb.add(cb.issueorder, on_issue_order)
cb.add(cb.spell, on_spell);
orb.combat.register_f_pre_tick(OnPreAttack)
cb.add(cb.tick, OnTick)
orb.combat.register_f_after_attack(OnAfterAttack)