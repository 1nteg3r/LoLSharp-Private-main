local script = {}

local orb = module.internal("orb");
local pred = module.internal("pred")
local evade = module.seek('evade')
local common = module.load(header.id, "common");
local TS = module.internal("TS")
local damage = module.load(header.id, 'damageLib');
local kalman = module.load(header.id, 'kalman_load');

local spelle_use = {
    "NamiQ",
    "CaitlynPiltoverPeacemaker",
    "RocketGrab",
    "LucianQ",
    "LucianR",
    "ThreshQ",
    "SennaQ",
    "SennaR",
    "LeonaZenithBlade"
}

local pred_W = {
    range = 1450,
    delay = 0.6,
    speed = 3200,
    boundingRadiusMod = 0,
    width = 75,
    collision = {
        hero = true,
        minion = true,
        wall = true
    },
}

local pred_e = {
    range = 900,
    radius = 100,
    delay = 0.9,
    speed = 5000,
    width = 100,
    boundingRadiusMod = 1,
    collision = {
        hero = true,
        minion = false,
        wall = true
    },
}

local pred_r = {
    range = 30000,
    delay = 0.6,
    speed = 1500,
    boundingRadiusMod = 0,
    width = 140,
    collision = {
        hero = true,
        minion = false,
        wall = true
    },
}

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

local Samaritan = {}

function Samaritan.Project(sourcePosition, unitPosition, unitDestination, spellSpeed, unitSpeed)
    local toUnit = unitPosition - sourcePosition
    local toDestination = unitDestination - unitPosition

    local cos = toUnit:norm():dot(toDestination:norm())
    local sin = math.abs(toUnit:norm():cross(toDestination:norm()))

    local unitVelocity = toDestination:norm() * unitSpeed
    local relativeUnitVelocity = toDestination:norm() * unitSpeed * cos

    local pi2 = (math.pi * 0.5)
    local angle = math.min(pi2, math.abs(mathf.angle_between(sourcePosition, unitPosition, unitDestination)))    
    local value = math.max(sin, angle)

    local magicalFormula = pi2 - value

    local spellVelocity = toUnit:norm() * spellSpeed
    local relativeSpellVelocity = toUnit:norm() * (spellSpeed - relativeUnitVelocity:len()) / magicalFormula

    unitPosition = unitPosition + unitVelocity * network.latency

    local toPos = unitPosition - sourcePosition

    local a = unitVelocity:dot(relativeUnitVelocity) - spellVelocity:dot(relativeSpellVelocity)
    local b = unitVelocity:dot(toPos) * 2
    local c = toPos:dot(toPos)

    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return
    end

    local d = math.sqrt(discriminant)

    local t = 0

    if a ~= 0 then
        t = (2 * c) / (d - b)
    elseif b ~= 0 then
        t = -c / b
    end

    local castPosition = unitPosition + (unitVelocity * t)
    return castPosition, t
end

mathf.project = Samaritan.Project

local LastWTick = 0

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

local IsPreAttack = false;

script.Menu = menu("MarksmanAIOJinx", "Marksman - ".. player.charName)
script.Menu:menu("Combo", "Combo")

script.Menu.Combo:header("", "Switcheroo! (Q) settings :")
script.Menu.Combo:boolean("UseQ", "Use Q", true)

script.Menu.Combo:header("", "Zap! (W) settings :")
script.Menu.Combo:boolean("UseW", "Use W", true)
script.Menu.Combo:slider("WMinDistanceToTarget", "Minimum distance to target to cast", 800, 0, 1500, 50)
script.Menu.Combo.WMinDistanceToTarget:set("tooltip", "Cast W only if distance from player to target is higher than desired value.")

script.Menu.Combo:header("", "Flame Chompers! (E) settings :")
script.Menu.Combo:boolean("UseE", "Use E", false)
script.Menu.Combo:boolean("AutoE", "Automated E usage on certain spells", true)
script.Menu.Combo.AutoE:set("tooltip", "Automated E usage fires traps on enemy champions that are Teleporting or are in Zhonyas. It also searchs for spells with long cast time like Caitlyn's R or Malzahar's R")

script.Menu.Combo:header("", "Super Mega Death Rocket! (R) settings :")
script.Menu.Combo:boolean("UseR", "Use R", true)
script.Menu.Combo:keybind("RKeybind", "R keybind", 'T', false)
script.Menu.Combo:slider("RRangeKeybind", "Maximum range to enemy to cast R while keybind is active", 1100, 300, 5000, 100)

-- Harass settings
script.Menu:menu("Harass", "Harass")

script.Menu.Harass:header("", "Switcheroo! (Q) settings :")
script.Menu.Harass:boolean("UseQ", "Use Q", true)
script.Menu.Harass:slider("MinManaQ", "Minimum mana percentage to use Q", 80, 1, 100, 1)

script.Menu.Harass:header("", "Zap! (W) settings :")
script.Menu.Harass:keybind("UseW", "Auto harass with W", nil, 'G')
script.Menu.Harass.UseW:set("tooltip", "Enables auto harass on enemy champions.")
script.Menu.Harass:slider("MinManaW", "Minimum mana percentage to use W", 50, 1, 100, 1)
script.Menu.Harass:menu("Champions", "W harass enabled for :")
for i = 0, objManager.enemies_n -1 do
    local unit = objManager.enemies[i]
    if unit then
        script.Menu.Harass.Champions:boolean(unit.charName, unit.charName, true)
    end
end
-- Lane Clear settings
script.Menu:menu("LaneClear", "Lane Clear")

script.Menu.LaneClear:header("", "Basic settings :")
script.Menu.LaneClear:boolean("EnableIfNoEnemies", "Enable lane clear only if no enemies nearby", true)
script.Menu.LaneClear:slider("ScanRange", "Range to scan for enemies", 1500, 300, 2500, 50)
script.Menu.LaneClear:slider("AllowedEnemies", "Allowed enemies amount", 1, 0, 5, 1)

script.Menu.LaneClear:header("", "Switcheroo! (Q) settings :")
script.Menu.LaneClear:boolean("UseQInLaneClear", "Use Q in Lane Clear", true)
script.Menu.LaneClear:boolean("UseQInJungleClear", "Use Q in Jungle Clear", true)
script.Menu.LaneClear:slider("MinManaQ", "Minimum mana percentage to use Q", 50, 1, 100, 1)
-- Misc
script.Menu:menu("Misc", "Misc")
--Use Automatic POW-POW

script.Menu.Misc:header("", "Basic settings :")
script.Menu.Misc:boolean("CASTPOW", "Cast Q Automatic POW-POW", false)
script.Menu.Misc:boolean("EnableInterrupter", "Cast E against interruptible spells", false)
script.Menu.Misc:boolean("EnableAntiGapcloser", "Cast E against gapclosers", true)
script.Menu.Misc:boolean("WKillsteal", "Cast W to killsteal", true)
script.Menu.Misc:boolean("RKillsteal", "Cast R to killsteal", true)
script.Menu.Misc:slider("RKillstealMaxRange", "Maximum range to enemy to cast R for killsteal", 2000, 0, 20000, 100)

-- Drawings
script.Menu:menu("Drawings", "Drawings")

script.Menu.Drawings:header("", "Basic settings :")
script.Menu.Drawings:boolean("DrawSpellRangesWhenReady", "Draw spell ranges only when they are ready", true)

script.Menu.Drawings:header("", "Switcheroo! (Q) drawing settings :")
script.Menu.Drawings:boolean("DrawRocketsRange", "Draw Q rockets range", true)
script.Menu.Drawings:color("DrawRocketsRangeColor", "Change color", 0, 255, 191, 255)

script.Menu.Drawings:header("", "Switcheroo! (W) drawing settings :")
script.Menu.Drawings:boolean("DrawW", "Draw W range", true)
script.Menu.Drawings:color("DrawWColor", "Change color", 0, 158, 96, 255)


local function GetTotalAttackDamage(unit)
    return (unit.baseAttackDamage + unit.flatPhysicalDamageMod) * unit.percentPhysicalDamageMod
end

local function GetBonusAttackDamage(unit)
    return ((unit.baseAttackDamage + unit.flatPhysicalDamageMod) * unit.percentPhysicalDamageMod) - unit.baseAttackDamage
end

local function GetPhysicalReduction(target, source)
    local armor = ((target.bonusArmor * source.percentBonusArmorPenetration) + (target.armor - target.bonusArmor)) * source.percentArmorPenetration
    local lethality = (source.physicalLethality * .4) + ((source.physicalLethality * .6) * (source.levelRef / 18))

    return armor >= 0 and (100 / (100 + (armor - lethality))) or (2 - (100 / (100 - (armor - lethality))))
end

local function GetAutoAttackDamage(target)
    local source = player

    if target then
        return GetTotalAttackDamage(source) * GetPhysicalReduction(target, source)
    end

    return 0
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

local function GetMovementBlockedDebuffDuration(target)
    for i, buff in pairs(target.buff) do 
        if buff and buff.valid and hard_cc[buff.type] then
            return (buff.endTime - game.time) * 1000
        end 
    end
    return 0
end 


local function HasItemFirecanon()
    local items = {}
    for i = 0, 6 do
        local id = player:itemID(i)
        if id > 0 then
            items[id] = true
        end
    end
    if items[3094] then 
        return true 
    end 
    return false
end

local function GetFirecanonStacks()
    if not HasItemFirecanon() then
        return 0
    end

    local buffPlayer = player.buff
    for i, buff in pairs(buffPlayer) do
        if buff and buff.name == 'itemstatikshankcharge' then
            return math.max(buff.stacks, buff.stacks2)
        end
    end
    return 0
end

local function HasFirecanonStackedUp()
    return GetFirecanonStacks() == 100
end
local function HasMinigun()
    return player.buff['jinxqicon'] ~= nil
end

local function GetMinigunStacks()
    local buffPlayer = player.buff
    for i, buff in pairs(buffPlayer) do
        if buff and buff.name == 'jinxqramp' then
            return math.max(buff.stacks, buff.stacks2)
        end
    end
    return 0
end

local function HasRocketLauncher()
    return HasMinigun() == false
end

local function GetRealRocketLauncherRange()
    local qRange = 700 + 25 * (player:spellSlot(0).level - 1)
    local additionalRange = 0

    if HasFirecanonStackedUp() then
        additionalRange = math.min(qRange * 0.35, 150)
    end
    return (qRange + additionalRange)
end

local function GetRealMinigunRange()
    if HasFirecanonStackedUp() then
        return math.min(525 * 1.35, 525 + 150)
    end
    return 525
end

local function OnDrawing() 
    if player.isDead and player.buff[17] and not player.isOnScreen then 
        return 
    end 

    if script.Menu.Drawings.DrawSpellRangesWhenReady:get() then 
        if player:spellSlot(0).state == 0 and script.Menu.Drawings.DrawRocketsRange:get() then 
            if (not HasRocketLauncher()) then 
                graphics.draw_circle(player.pos, GetRealRocketLauncherRange(), 1, script.Menu.Drawings['DrawRocketsRangeColor']:get(), 100)
            end
        end 
        if player:spellSlot(1).state == 0 and script.Menu.Drawings.DrawW:get() then 
            graphics.draw_circle(player.pos, pred_W.range, 1, script.Menu.Drawings['DrawWColor']:get(), 100)
        end 
    else 
        if script.Menu.Drawings.DrawRocketsRange:get() then 
            if (HasRocketLauncher()) then 
                graphics.draw_circle(player.pos, GetRealRocketLauncherRange(), 1, script.Menu.Drawings['DrawRocketsRangeColor']:get(), 100)
            end
        end 
        if  script.Menu.Drawings.DrawW:get() then 
            graphics.draw_circle(player.pos, pred_W.range, 1, script.Menu.Drawings['DrawWColor']:get(), 100)
        end 
    end

    local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
    if script.Menu.Harass.UseW:get() then
        graphics.draw_text_2D("Auto W: ", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
        graphics.draw_text_2D("ON", 17, pos.x + 20, pos.y + 50, graphics.argb(255, 51, 255, 51))
    else
        graphics.draw_text_2D("Auto W: ", 17, pos.x - 45, pos.y + 50, graphics.argb(255, 255, 255, 255))
        graphics.draw_text_2D("OFF", 17, pos.x + 20, pos.y + 50, graphics.argb(255, 255, 0, 0))
    end

end 
local function OnPreAttack() 
    IsPreAttack = true;
end 

local function GetEnemyHeroes(range) 
    local result = {}
    for i = 0, objManager.enemies_n - 1 do
        local unit = objManager.enemies[i]

        if common.IsValidTarget(unit) and player.pos:dist(unit.pos) < range then
            result[#result + 1] = unit
        end
    end

    return result
end

local function CountEnemiesInRange(range)
    return #GetEnemyHeroes(range)
end

local function Combo()
    -- Q logic
    if player:spellSlot(0).state == 0 and script.Menu.Combo.UseQ:get() and orb.core.can_attack() and not IsPreAttack then
        local target = common.GetTarget(GetRealRocketLauncherRange())

        if target and target ~= nil and common.IsValidTarget(target) then
            if common.IsInRange(GetRealMinigunRange(), player, target) and HasRocketLauncher() and (common.GetShieldedHealth("AD", target) > (GetAutoAttackDamage(target) * 2.2)) then
                player:castSpell("self", 0)
                return
            end

            if (not common.IsInRange(GetRealMinigunRange(), player, target)) and common.IsInRange(GetRealRocketLauncherRange(), player, target) and (not HasRocketLauncher()) then
                player:castSpell("self", 0)
                return
            end

            if HasMinigun() and (GetMinigunStacks() >= 2) and (common.GetShieldedHealth("AD", target) < (GetAutoAttackDamage(target) * 2.2)) and (common.GetShieldedHealth("AD", target) > (GetAutoAttackDamage(target) * 2)) then
                player:castSpell("self", 0)
                return
            end
        end
    end

    -- W logic
    if player:spellSlot(1).state == 0 and script.Menu.Combo.UseW:get() then 
        if (#common.CountEnemiesInRange(player.pos, script.Menu.Combo.WMinDistanceToTarget:get()) == 0) and (not common.IsUnderDangerousTower(player.pos)) and ((player.mana - (50 + 10 * (player:spellSlot(1).level - 1))) > ((player:spellSlot(3).state == 0) and 100 or 50)) then
            local target = TS.get_result(real_target_filter(pred_W).Result) 

            if target.obj and target.pos and common.IsValidTarget(target.obj) then
                --player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                if kalman.KalmanFilter(target.obj) then
                    player:castSpell('pos', 1, vec3(target.pos.x, mousePos.y, target.pos.y))
                    LastWTick = os.clock()
                end
            end
        end
    end

    -- E logic
    if player:spellSlot(2).state == 0 and script.Menu.Combo.UseE:get() then 
        if (player.mana - 50 > 100) then
            local target = common.GetTarget(pred_e.range)

            if target and target ~= nil and common.IsValidTarget(target) then
                local predPos = pred.circular.get_prediction(pred_e, target)

                if predPos then 
                    if ((predPos.endPos:dist(target.pos) > 150)) or ((predPos.endPos:dist(target.pos) > 150) and common.IsMovingTowards(target, 500)) then
                        player:castSpell("pos", 2, vec3(predPos.endPos.x, target.y, predPos.endPos.y))
                    end
                end
            end
        end
    end

    -- R logic 
    if player:spellSlot(3).state == 0 and script.Menu.Combo.UseR:get() then 
        local target = TS.get_result(real_target_filter(pred_r).Result) 
        if target.obj and target.pos and common.IsValidTarget(target.obj)  and common.IsEnemyMortal(target.obj) and os.clock() - LastWTick > 0.9  then
            if player:spellSlot(1).state == 0 and target.pos:dist(player) <= pred_W.range and damage.GetSpellDamage(1, target.obj) > common.GetShieldedHealth("AD", target.obj) then return end 
            if damage.GetSpellDamage(3, target.obj) > common.GetShieldedHealth("AD", target.obj) then
                if (#common.CountEnemiesInRange(player.pos, script.Menu.Combo.WMinDistanceToTarget:get()) == 0) then 
                    if kalman.KalmanFilter(target.obj) then
                        player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                    end
                end 
            end
        end
    end
end 

local function Harass() 
    if player:spellSlot(0).state == 0 and script.Menu.Harass.UseQ:get() and orb.core.can_attack() and not IsPreAttack then
        local target = common.GetTarget(GetRealRocketLauncherRange())

        if target and target ~= nil and common.IsValidTarget(target) then
            if common.IsInRange(GetRealMinigunRange(), player, target) and HasRocketLauncher() and (common.GetShieldedHealth("AD", target) > (GetAutoAttackDamage(target) * 2.2)) then
                player:castSpell("self", 0)
                return
            end

            if (not common.IsInRange(GetRealMinigunRange(), player, target)) and common.IsInRange(GetRealRocketLauncherRange(), player, target) and (not HasRocketLauncher()) then
                player:castSpell("self", 0)
                return
            end

            if HasMinigun() and (GetMinigunStacks() >= 2) and (common.GetShieldedHealth("AD", target) < (GetAutoAttackDamage(target) * 2.2)) and (common.GetShieldedHealth("AD", target) > (GetAutoAttackDamage(target) * 2)) then
                player:castSpell("self", 0)
                return
            end
        end
    end
end 

local function CanILaneClear() --here tulio
    local menu = script.Menu.LaneClear

    return ((not menu.EnableIfNoEnemies:get()) or (CountEnemiesInRange(menu.ScanRange:get()) <= menu.AllowedEnemies:get()))
end

local function LaneClear()
    local menu = script.Menu.LaneClear

    if (not menu.UseQInLaneClear:get()) or common.IsUnderDangerousTower(player.pos) then
        return
    end

    local laneMinions = common.GetMinions(player.pos, GetRealRocketLauncherRange() + 100, TEAM_ENEMY)
    if not laneMinions or #laneMinions <= 0 then
        return
    end

    local rocketsLanuncherMinions = {}
    for i = 1, #laneMinions do
        local minion = laneMinions[i]

        if common.IsInRange(GetRealRocketLauncherRange(), player, minion) then
            local count = 0

            for c = 1, #laneMinions do
                local cmpMinion = laneMinions[c]

                if i ~= c then
                    if (cmpMinion.pos:dist(minion.pos) <= 150) and (orb.farm.predict_hp(cmpMinion, 350) < GetAutoAttackDamage(cmpMinion) * 1.1) then
                        count = count + 1
                    end
                end
            end

            if count > 3 or ((player.pos:dist(minion.pos) > GetRealMinigunRange()) and (orb.farm.predict_hp(minion, 350) < GetAutoAttackDamage(minion) * 0.95)) then
                rocketsLanuncherMinions[#rocketsLanuncherMinions + 1] = minion
            end
        end
    end

    if HasMinigun() then
        if (#rocketsLanuncherMinions <= 0) or (not CanILaneClear()) or ((player.mana / player.maxMana * 100) < menu.MinManaQ:get()) or (not orb.core.can_attack()) then
            return
        end

        player:castSpell("self", 0)
    elseif (HasRocketLauncher() and (#rocketsLanuncherMinions <= 0)) then
        if orb.core.can_attack() then
            player:castSpell("self", 0)
        end
    end
end 

local function JungleClear()
    if not script.Menu.LaneClear.UseQInJungleClear:get() or ((player.mana / player.maxMana * 100) < script.Menu.LaneClear.MinManaQ:get()) then
        return
    end

    -- Get jungle monsters in AA range
    local minions = common.GetMinions(player.pos, player.attackRange, TEAM_NEUTRAL)

    -- Check there is any monster
    if #minions <= 0 then
        return
    end

    -- Group minions
    local minionsGroups = 0

    for i = 1, #minions do
        if common.CountMinionsInRange(minions[i].pos, 150, TEAM_NEUTRAL) > 0 then
            minionsGroups = minionsGroups + 1
        end
    end

    if HasMinigun() and #minions > 1 and minionsGroups > 1 and orb.core.can_attack() then
        player:castSpell("self", 0)
    elseif HasRocketLauncher() and orb.core.can_attack() then
        player:castSpell("self", 0)
    end
end 

local interrupt_data = {};
local function OnProcessSpell(spell)
    if script.Menu.Misc.EnableInterrupter:get() then 
        if spell and spell.owner.team ~= player.team then 
            for i = 0, #spelle_use do 
                if (spelle_use[i] == spell.name) then
                    if spell.owner and not spell.owner.isDead then 
                        if spell.owner.pos:dist(player.pos) <= pred_e.range then 
                            local predPos = pred.circular.get_prediction(pred_e, spell.owner)
                            if predPos and spell.startPos:dist(spell.owner.pos) <= pred_e.range then
                                player:castSpell("pos", 2, vec3(predPos.endPos.x, spell.owner.y, predPos.endPos.y))
                            end
                        end 
                    end 
                end 
            end 
        end
    end
    --Sspell E
    if not script.Menu.Misc.EnableInterrupter:get() then return end
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

local function OnTick() 
    if player.isDead then return end

    if script.Menu.Misc.CASTPOW:get() then 
        local target = common.GetTarget(pred_W.range)
        if not target then
            if not HasMinigun() then
                player:castSpell("self", 0)
            end
        end
    end 

    IsPreAttack = false;

    if (orb.menu.combat.key:get()) then
        Combo();
    elseif (orb.menu.hybrid.key:get()) then
        Harass();
    elseif (orb.menu.lane_clear.key:get()) then
        JungleClear();
        LaneClear();
    end

    if player:spellSlot(1).state == 0 and script.Menu.Harass.UseW:get() and common.GetPercentMana(player) >= script.Menu.Harass.MinManaW:get() then
        local target = TS.get_result(real_target_filter(pred_W).Result) 

        if target.obj and target.pos and common.IsValidTarget(target.obj) then
            if script.Menu.Harass.Champions[target.obj.charName] and script.Menu.Harass.Champions[target.obj.charName]:get() then
                --player:castSpell('pos', 3, vec3(target.pos.x, mousePos.y, target.pos.y))
                if kalman.KalmanFilter(target.obj) then
                    player:castSpell('pos', 1, vec3(target.pos.x, mousePos.y, target.pos.y))
                    LastWTick = os.clock()
                end
            end
        end
    end

    if script.Menu.Misc.EnableAntiGapcloser:get() then 
        local target = TS.get_result(function(res, obj, dist)

            if dist > 2500 or common.GetPercentHealth(obj) > 40 then
                return
            end

            if dist <= (pred_e.range + obj.boundingRadius) and obj.path.isActive and obj.path.isDashing then
                res.obj = obj
                return true
            end
        end).obj
        if target and player:spellSlot(2).state == 0 then
            local pred_pos = pred.core.lerp(target.path, network.latency + pred_e.delay, target.path.dashSpeed)
            if pred_pos and pred_pos:dist(player.path.serverPos2D) <= pred_e.range then
                player:castSpell("pos", 2,  vec3(pred_pos.x, target.y, pred_pos.y))
            end 
        end
    end 

    --interrupt
    if script.Menu.Misc.EnableInterrupter:get() then 
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

    if script.Menu.Combo.AutoE:get() then 
        for i = 0, objManager.enemies_n - 1 do
            local unit = objManager.enemies[i]
            if unit then 
                for i, buff in pairs(unit.buff) do
                    if buff and buff.name == "zhonyasringshield" or buff.name == "bardrstasis" then 
                        if ((buff.endTime - game.time > 1.25) and player:spellSlot(2).state == 0) then 
                            player:castSpell("pos", 2, unit.path.serverPos)
                        end
                    end 
                end
            end 
        end
    end 

    --Misc R
    if player:spellSlot(3).state == 0 and script.Menu.Misc.RKillsteal:get() then 
        local target = TS.get_result(real_target_filter(pred_r).Result) 
        if target.obj and target.pos and common.IsValidTarget(target.obj) then
            if common.IsEnemyMortal(target.obj) then 
                if player:spellSlot(1).state == 0 and target.obj.pos:dist(player) <= pred_W.range and damage.GetSpellDamage(1, target.obj) > common.GetShieldedHealth("AD", target.obj) then return end 
                if damage.GetSpellDamage(3, target.obj) > common.GetShieldedHealth("AD", target.obj) and common.IsInRange(script.Menu.Misc.RKillstealMaxRange:get(), player, target.obj) then
                    if (#common.CountEnemiesInRange(player.pos, script.Menu.Combo.WMinDistanceToTarget:get()) == 0) then 
                        --if kalman.KalmanFilter(target.obj) then
                        local castPos = mathf.project(player.pos, target.obj.pos, vec3(target.pos.x, mousePos.y, target.pos.y), pred_r.speed, target.obj.moveSpeed)
                        if castPos then 
                            player:castSpell('pos', 3, castPos)
                            LastWTick = 0
                        end
                    end 
                end
            end
        end
    end

    --Misc W 
    if player:spellSlot(1).state == 0 and script.Menu.Misc.WKillsteal:get() then 
        for i = 0, objManager.enemies_n - 1 do
            local unit = objManager.enemies[i]
            if unit and common.IsValidTarget(unit) and common.IsEnemyMortal(unit) then 
                if player:spellSlot(1).state == 0 and unit.pos:dist(player) <= pred_W.range and damage.GetSpellDamage(1, unit) > common.GetShieldedHealth("AD", unit) then 
                    if (#common.CountEnemiesInRange(player.pos, script.Menu.Combo.WMinDistanceToTarget:get()) == 0) then 
                        local seg = pred.linear.get_prediction(pred_W, unit)
                        if seg and seg.startPos:dist(seg.endPos) < pred_W.range then
                            if not pred.collision.get_prediction(pred_W, seg, unit) and kalman.KalmanFilter(unit) then
                                player:castSpell("pos", 1, vec3(seg.endPos.x, unit.y, seg.endPos.y))
                                LastWTick = os.clock()
                            end 
                        end
                    end 
                end
            end
        end
    end

    --keybind
    if script.Menu.Combo.RKeybind:get() and player:spellSlot(3).state == 0 then 
        for i = 0, objManager.enemies_n - 1 do
            local unit = objManager.enemies[i]
            if unit and common.IsValidTarget(unit) and common.IsEnemyMortal(unit) then 
                if common.IsInRange(script.Menu.Misc.RKillstealMaxRange:get(), player, unit) then
                    if (#common.CountEnemiesInRange(player.pos, script.Menu.Combo.WMinDistanceToTarget:get()) == 0) then 
                        local seg = pred.linear.get_prediction(pred_r, unit)
                        if seg and seg.startPos:dist(seg.endPos) < pred_r.range then
                            if not pred.collision.get_prediction(pred_r, seg, unit) then
                                player:castSpell("pos", 3, vec3(seg.endPos.x, unit.y, seg.endPos.y))
                            end 
                        end
                    end 
                end
            end
        end
    end 

    if script.Menu.Combo.AutoE:get() then 
        local enemy = common.GetEnemyHeroes()
        for i, target in ipairs(enemy) do
            if target  and common.IsValidTarget(target) then
                local time = GetMovementBlockedDebuffDuration(target)
                if time > 0 and time * 1000 > 0.25 then 
                    if player:spellSlot(2).state == 0 and target.pos:dist(player) <= 750 then 
                        player:castSpell("pos", 2, target.path.serverPos)
                    end 
                end 
            end 
        end
    end 
end 

cb.add(cb.draw, OnDrawing)

orb.combat.register_f_pre_tick(OnPreAttack)
cb.add(cb.tick, OnTick)
--
cb.add(cb.spell, OnProcessSpell)
--cb.add(cb.cast_spell, CastSpell)
--Creat Trap
--cb.add(cb.delete_object, OnDeleObject)
--cb.add(cb.create_object, OnCreateObject)