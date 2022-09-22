local KoreaKarthus = {}

-- Script Information Part

-- Script Var

KoreaKarthus.pState = false
KoreaKarthus.pStartTime = 0
KoreaKarthus.pEndTime = 0
KoreaKarthus.pLeftTime = 0

KoreaKarthus.eState = false
KoreaKarthus.eDelayStart = 0
KoreaKarthus.eDelayEnd = 0
KoreaKarthus.eOnDelay = false

KoreaKarthus.target = nil
KoreaKarthus.predQPosition = nil

KoreaKarthus.rSupporterText = {}


local orb = module.internal("orb");
local gpred = module.internal("pred")
local damageLib = module.load(header.id, 'Library/damageLib')
local common = module.load(header.id, "Library/common");
local TS = module.load(header.id, "TargetSelector/targetSelector")
local prediction = module.load('int', 'Core/Caitlyn/prediction');
local VP = module.load("int", "Prediction/VP")
local TargetPred = module.internal("TS")
local pred = module.internal("pred")
local enemies = common.GetEnemyHeroes()
local allies = common.GetAllyHeroes()

local function LoadScript()
    KoreaKarthus:CreateMenu()
end

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
    local angle = mathf.angle_between(sourcePosition, unitPosition, unitDestination)

    local cos = toUnit:norm():dot(toDestination:norm())
    local sin = math.abs(toUnit:norm():cross(toDestination:norm()))

    local unitVelocity = toDestination:norm() * unitSpeed
    local relativeUnitVelocity = toDestination:norm() * unitSpeed * cos

    local magicalFormula = (math.pi * 0.5) - sin

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

-- Menu
function print_r ( t ) 
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"  ")
end


function KoreaKarthus:CreateMenu()
    self.menu = menu('IntKarthus', 'Int Karthus')
    self.menu:header("Healdeprediction",'Prediction')
    self.menu:dropdown("prediction", "Prediction Mode", 1, {"Prediction Q", "Beta"})
    self.menu:header("headTitle",'Core')

    -- Combo setting
    self.menu:menu("combo", "Combo")
    -- Passive Combo Setting
        self.menu.combo:menu("passive", "Passive Combo Setting")
            self.menu.combo.passive:boolean("r", "Use Auto R on Passive", true)
            self.menu.combo.passive:slider("rDamage", "R Damge Multiplier (%)", 120, 80, 150, 5)
        self.menu.combo:boolean("w", "Use W", true)
        self.menu.combo:slider("wMana", "^ Mana Percent", 10, 0, 100, 5)
        self.menu.combo:slider("wDistance", "Use W if enemy farther than", 650, 100, 1000, 50)
        self.menu.combo:boolean("e", "Use Auto E", true)
        self.menu.combo:slider("eMana", "^ Mana Percent", 10, 0, 100, 5)
        self.menu.combo:dropdown("controlAA", "AA Mode", 2, {"Never", "AA Logic", "No use Q"})
    
    -- Harass Setting
    self.menu:menu("harass", "Harass")
        self.menu.harass:boolean("q", "Use Q", true)
        self.menu.harass:boolean("e", "Use Auto E", true)
        self.menu.harass:slider("eMana", "^ Mana Percent", 35, 0, 100, 5)
        self.menu.harass:dropdown("controlAA", "AA Mode", 3, {"Never", "AA Logic", "No use Q"})
        self.menu.harass:boolean("doOnClear", "Do Harass", true)

    -- Clear Setting (WIP)
    self.menu:menu("clear", "Lane/Jungle")
        self.menu.clear:boolean("q", "Use Q", true)
        self.menu.clear:boolean("qlast", "Use Q LastHit", true)
        self.menu.clear:slider("minQ", "Use Q if hit >= {0}", 3, 1, 5, 1);
        self.menu.clear:boolean("e", "Use E", true)
        self.menu.clear:slider("minW", "Use E if hit >= {0}", 5, 1, 10, 1);
        self.menu.clear:slider("Mana", "Mini. Mana Percent", 50, 1, 100, 1);
    -- Msic Setting
    self.menu:menu("msic", "Misc")
        self.menu.msic:boolean("autoQ", "Use Auto Q", true)
        self.menu.msic:boolean("disableE", "Auto disable E if no enemy", true)
        self.menu.msic:slider("disableEDelay", "E Delay", 500, 0, 1000, 50)
        self.menu.msic:slider("useERange", "E Range", 600, 450, 700, 10)

    self.menu:menu("drawing", "Display")
        self.menu.drawing:header("drawSpell", "Draw Spell Range")
        self.menu.drawing:boolean("drawQ", "Q Range", true)
        self.menu.drawing:boolean("drawW", "W Range", false)
        self.menu.drawing:boolean("drawE", "E Range", true)
        self.menu.drawing:header("drawExtra", "Misc Drawing")
        self.menu.drawing:boolean("drawR", "Draw Killable Enemy with R", true)
        self.menu.drawing:slider("drawRHide", "Hide R text after (s)", 20, 0, 60, 1)
    
    -- Target Selector
       -- Target Selector
       TS = TS(self.menu, 1200)
       TS:addToMenu()

    cb.add(cb.tick, function() self:OnTick() end)
    cb.add(cb.draw, function() self:OnDraw() end)
    cb.add(cb.spell, function(spell) self:OnSpell(spell) end)

    self.wPred = {delay = 0.25, radius = 100, speed = math.huge, boundingRadiusMod = 0, range = 1000}
end

function KoreaKarthus:OnTick()
    -- Tick start
    TS.range = 1200
    self.target = TS.target
    -- Passive Combo First
    if self.pState then
        self:PassiveCombo()
    else
        -- Do other combo
        if orb.combat.is_active() then
            self:Combo()
        elseif orb.menu.hybrid:get() then
            self:Harass()
        elseif orb.menu.lane_clear:get() then
            if self.menu.harass.doOnClear then
                self:Harass()
            end
            self:Clear()
        elseif orb.menu.last_hit:get() then
            self:Lasthit()
        end

        if self.menu.msic.disableE:get() then
            self:AutoDisableE()
        end
    end

    if self.menu.drawing.drawR:get() then
        self:FindKillableR()
    end
    self:OnBuff();
end

function KoreaKarthus:Combo()
    -- Control AA
    if self.menu.combo.controlAA:get() == 2 and player.mana > 50 and player:spellSlot(0).level ~= 0 then
        orb.core.set_server_pause_attack()
    end

    -- W Logic first
    if self.menu.combo.w:get() and orb.core.can_action() and self.target then
        if player.pos:dist(self.target.pos) >= self.menu.combo.wDistance:get() then
            self:CastW(self.menu.combo.wMana:get())
        end
    end

    -- Q Logic
    if self.menu.combo.controlAA:get() ~= 3 or (self.menu.combo.controlAA:get() == 3 and orb.core.can_action()) then
        self:CastQ()
    end

    -- E Logic
    if self.menu.combo.e:get() then
        if self:IsEnemyHeroInE() and self:CheckMana(self.menu.combo.eMana:get()) then
            self:EnableE()
        else
            self:DisableE()
        end
    end
end

function KoreaKarthus:Harass()
    -- Control AA
    if self.menu.harass.controlAA:get() == 2 and not orb.menu.lane_clear:get() and player.mana > 50 and player:spellSlot(0).level ~= 0  then
        orb.core.set_server_pause_attack()
    end

    -- No W for Harass. If you need W, just use combo mode.

    -- Q Logic
    if self.menu.harass.controlAA:get() ~= 3 or (self.menu.harass.controlAA:get() == 3 and orb.core.can_action()) then
        self:CastQ()
    end

    -- E Logic
    if self.menu.harass.e:get() then
        if orb.menu.lane_clear:get() then
            if self:IsEnemyHeroInE() and self:CheckMana(self.menu.harass.eMana:get()) then
                self:EnableE()
            elseif not self:IsEnemyInE() then
                self:DisableE()
            end
        else
            if self:IsEnemyHeroInE() and self:CheckMana(self.menu.harass.eMana:get()) then
                self:EnableE()
            else
                self:DisableE()
            end
        end
    end
end

local function count_minions_in_range(pos, range)
	local enemies_in_range = {}
	for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
		local enemy = objManager.minions[TEAM_ENEMY][i]
		if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

function KoreaKarthus:Clear()
    if (player.mana / player.maxMana) * 100 <= self.menu.clear.Mana:get() then return end
    if self.menu.clear.q:get() then
     local minions = objManager.minions
     for a = 0, minions.size[TEAM_ENEMY] - 1 do
         local minion1 = minions[TEAM_ENEMY][a]
         if
             minion1 and minion1.moveSpeed > 0 and minion1.isTargetable and not minion1.isDead and minion1.isVisible and
                 player.path.serverPos:distSqr(minion1.path.serverPos) <= (825 * 825)
          then
             local count = 0
             for b = 0, minions.size[TEAM_ENEMY] - 1 do
                 local minion2 = minions[TEAM_ENEMY][b]
                 if
                     minion2 and minion2.moveSpeed > 0 and minion2.isTargetable and minion2 ~= minion1 and not minion2.isDead and
                         minion2.isVisible and
                         minion2.path.serverPos:distSqr(minion1.path.serverPos) <= (220 * 220)
                  then
                     count = count + 1
                 end
                 if count >= self.menu.clear.minQ:get() then
                     local seg = gpred.circular.get_prediction(self:GetQPred(), minion1)
                     if seg and seg.startPos:dist(seg.endPos) < 825 then
                         player:castSpell("pos", 0, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
                         --orb.core.set_server_pause()
                         break
                     end
                 end
             end
         end
     end
     for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local minion = objManager.minions[TEAM_NEUTRAL][i]
        if
            minion and not minion.isDead and minion.moveSpeed > 0 and minion.isTargetable and minion.isVisible and
                minion.type == TYPE_MINION
         then
            if minion.pos:dist(player.pos) <= 825 then
                local pos = gpred.circular.get_prediction(self:GetQPred(), minion)
                if pos and pos.startPos:dist(pos.endPos) < 825 then
                    player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
                end
            end
        end
    end
    end
     if self.menu.clear.e:get() then
        for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if
                minion and minion.moveSpeed > 0 and minion.isTargetable and minion.pos:dist(player.pos) < 500 and
                    minion.path.count == 0 and
                    not minion.isDead and
                    common.IsValidTarget(minion)
            then
                local minionPos = vec3(minion.x, minion.y, minion.z)
                if minionPos then
                    if #count_minions_in_range(minionPos, 500) >= self.menu.clear.minW:get() then
                        player:castSpell("self", 2)
                    end
                end
            end
        end
    end
    if self.menu.clear.qlast:get() then 
        local minions = objManager.minions
        for a = 0, minions.size[TEAM_ENEMY] - 1 do
            local minion1 = minions[TEAM_ENEMY][a]
            if
                minion1 and minion1.moveSpeed > 0 and minion1.isTargetable and not minion1.isDead and minion1.isVisible and
                    player.path.serverPos:distSqr(minion1.path.serverPos) <= (825 * 825) then 
                        if damageLib.GetSpellDamage(0, minion1) >= minion1.health then 

                            local seg = gpred.circular.get_prediction(self:GetQPred(), minion1)
                            if seg and seg.startPos:dist(seg.endPos) < 825 then
                                player:castSpell("pos", 0, vec3(seg.endPos.x, minion1.y, seg.endPos.y))
                                --orb.core.set_server_pause()
                                break
                            end
                        end
                    end
                end 
    end
 --end
end

function KoreaKarthus:Lasthit()
    
end

function KoreaKarthus:PassiveCombo()
    if self.pEndTime < game.time then
        self.pState = false
        return
    end
    
    TS.range = 825
    TS:OnTick()
    self.target = TS.target

    self.pLeftTime = self:Floor(self.pEndTime - game.time)

    -- R Logic
    if player:spellSlot(3).state == 0 and self.pLeftTime <= 4 and self.pLeftTime >= 3 and self.menu.combo.passive.r:get() then
        for i = 1, #enemies do
            local enemy = enemies[i]
            if not enemy.isDead then
                local damage = damageLib.GetSpellDamage(3, enemy, 1, player)

                if common.getShieldedHealth("AP", enemy) <= damage * (self.menu.combo.passive.rDamage:get() * 0.01) then
                    player:castSpell("self", 3)
                    break
                end
            end
        end
    end

    -- W Logic
    self:CastW(0)

    -- Q Logic
    self:CastQ()
end

function KoreaKarthus:FindKillableR()
    for i = 1, #enemies do
        local enemy = enemies[i]
        if enemy.isVisible then
            local damage = damageLib.GetSpellDamage(3, enemy, 1, player)
            local enemyHP = common.getShieldedHealth("AP", enemy)
            

            if enemyHP * 0.8 <= damage then

                local infoText = enemy.charName
                local infoDamage = self:Floor((damage / enemyHP) * 100 )
                local infoColor

                if enemyHP * 1.2 <= damage then
                    infoText = infoText.." is killable."
                    infoColor = graphics.argb(255, 255, 0, 0)
                elseif enemyHP <= damage then
                    infoText = infoText.." is killable."
                    infoColor = graphics.argb(255, 255, 255, 255)
                else
                    infoText = infoText.."..."
                    infoColor = graphics.argb(255, 180, 180, 180)
                end

                if math.floor(enemy.maxHealth / enemy.health * 100) < 100 then
                    infoText = infoText.." ("..tostring(infoDamage).."%)"
                else 
                    infoText = infoText..(" 100".. "%")
                end

                self.rSupporterText[i] = {true, infoText, infoColor, game.time}
            else
                self.rSupporterText[i] = {false}
            end
        end

        if enemy.isDead then
            self.rSupporterText[i] = {false}
        end
    end
end

function KoreaKarthus:OnDraw()
    -- Spell Drawing
    if player.isVisible then
        if self.menu.drawing.drawQ:get() then
            graphics.draw_circle(player.pos, 875, 1, graphics.argb(255, 156, 164, 147), 30)
        end
        if self.menu.drawing.drawW:get() then
            graphics.draw_circle(player.pos, 1000, 1, graphics.argb(255, 156, 164, 147), 30)
        end
        if self.menu.drawing.drawE:get() then
            graphics.draw_circle(player.pos, 550, 1, graphics.argb(255, 156, 164, 147), 30)
        end
    end

    if self.menu.drawing.drawR:get() then
        local ii = 0

        for i, info in ipairs(self.rSupporterText) do
            if info[1] == true and (info[4] + self.menu.drawing.drawRHide:get()) > game.time then

                graphics.draw_text_2D(info[2], 20, 200, 100 + (ii * 30), info[3])
                ii = ii + 1
            end
        end
    end

    --[[Debug
    if self.menu.msic.debug:get() then
        graphics.draw_text_2D("Now: "..tostring(game.time), 18, 200, 200, 0xFFffffff)
        graphics.draw_text_2D("Core.can_action: "..(orb.core.can_action() and "true" or "false").." Core.can_attack: "..(orb.core.can_attack() and "true" or "false"), 18, 200, 220, 0xFFffffff)
        graphics.draw_text_2D("Core.is_attack_paused: "..(orb.core.is_attack_paused() and "true" or "false"), 18, 200, 240, 0xFFffffff)
        graphics.draw_text_2D("E ON/OFF: "..(self.eState and "true" or "false"), 18, 200, 260, 0xFFffffff)
        graphics.draw_text_2D("Passive: "..(self.pState and "true" or "false").." "..tostring(self.pStartTime).." to "..tostring(self.pEndTime), 18, 200, 280, 0xFFffffff)
        graphics.draw_text_2D("Is Enemy in E: "..(self:IsEnemyHeroInE() and "true" or "false").." Is Minion in E: "..(self:IsEnemyInE() and "true" or "false"), 18, 200, 300, 0xFFffffff)
        graphics.draw_text_2D("E on delay: "..(self.eOnDelay and "true" or "false").." "..tostring(self.eDelayStart).." to "..tostring(self.eDelayEnd), 18, 200, 320, 0xFFffffff)
    end]]

    if player:spellSlot(0).state == 0 and self.target then
        if self.menu.prediction:get() == 1 then 
            local CastPosition, HitChance, Position = prediction.GetBestCastPosition(self.target, 0.75, 175, 825, math.huge, player, false, "circular")
            if  CastPosition and Position and common.IsInRange(825, player, self.target) then
                --local castPos = mathf.project(player.pos, Position, CastPosition, math.huge, self.target.moveSpeed)
                if CastPosition and common.IsInRange(825, player, CastPosition) then 
                    graphics.draw_circle(CastPosition, 124, 1, graphics.argb(255, 156, 164, 147), 30)
                end
            end
        elseif self.menu.prediction:get() == 2 then 

            local CastPosition, HitChance, Position = VP.GetBestCastPosition(self.target, 0.75, 155, 800, math.huge, player, false, "circular")

            if CastPosition and Position then 
                --local castPos = mathf.project(player.pos, Position, CastPosition, math.huge, self.target.moveSpeed)
                if CastPosition and common.IsInRange(825, player, CastPosition) then 
                    --player:castSpell("pos", 0, CastPosition)
                    graphics.draw_circle(CastPosition, 124, 1, graphics.argb(255, 156, 164, 147), 30)
                end
            end 
        end 
	end
end

function KoreaKarthus:OnSpell(spell)
    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.owner == player and spell.startPos:dist(player.pos) then
        if string.lower(spell.name) == "karthusdefile" then
            self.eState = false
        elseif string.lower(spell.name) == "karthusdefilesounddummy2" then
            self.eState = true
        end
    end
end

function KoreaKarthus:OnBuff()
    if player.buff['karthusdeathdefiedbuff'] then
        self.pState = true
        self.pStartTime = game.time
        self.pEndTime = game.time + 7
        self.pLeftTime = 7
    end
end

function KoreaKarthus:GetQPred()
    return {delay = 750 * 0.001, radius = 200, speed = math.huge, boundingRadiusMod = 0, range = 825}
end

local pred_input = {
    boundingRadiusModSource = 0,
    boundingRadiusMod = 0,
    range = 825,
    delay = math.huge, 
    radius = 75, 
    speed = math.huge,
    type = 'circular',
    collision = { hero = false, minion = false, wall = false };
}

function KoreaKarthus:CastQ()
    if player:spellSlot(0).state == 0 and self.target then
        if self.menu.prediction:get() == 1 then 
            local CastPosition, HitChance, Position = prediction.GetBestCastPosition(self.target, 0.75, 175, 825, math.huge, player, false, "circular")
            if  CastPosition and Position and common.IsInRange(825, player, self.target) then
                --local castPos = mathf.project(player.pos, Position, CastPosition, math.huge, self.target.moveSpeed)
                if CastPosition and common.IsInRange(800, player, CastPosition) then 
                    player:castSpell("pos", 0, CastPosition)
                end
            end
        elseif self.menu.prediction:get() == 2 then 

            local CastPosition = VP.GetCircularAOEPrediction(self.target, 0.75, 175, 800, math.huge, player, false, "circular")

            if CastPosition then 
                --local castPos = mathf.project(player.pos, Position, CastPosition, math.huge, self.target.moveSpeed)
                if CastPosition and common.IsInRange(800, player, CastPosition) then 
                    player:castSpell("pos", 0, CastPosition)
                    print'(Qpos.x, Qpos.z)'
                end
            end 
        end 
	end
end

function KoreaKarthus:CastW(manaPersent)
    if not manaPersent then manaPersent = 0 end
    if player:spellSlot(1).state == 0 and self.target and orb.core.can_action() then
        local predPos = gpred.circular.get_prediction(self.wPred, self.target)
        if self:CheckMana(manaPersent) and predPos and predPos.startPos:dist(predPos.endPos) <= 1000 then
            player:castSpell("pos", 1, vec3(predPos.endPos.x, self.target.pos.y, predPos.endPos.y))
        end
	end
end

function KoreaKarthus:EnableE()
    if self.eOnDelay == true then
        self.eOnDelay = false
    end

    if player:spellSlot(3).state == 0 and self.eState == false then
        player:castSpell("self", 2)
	end
end

function KoreaKarthus:DisableE()
    if player:spellSlot(3).state == 0 and self.eState == true then

        if self.eOnDelay == false then
            self.eOnDelay = true
            self.eDelayStart = game.time
            self.eDelayEnd = game.time + (self.menu.msic.disableEDelay:get() * 0.001)
        else
            if self.eDelayEnd ~= 0 and self.eDelayEnd <= game.time then
                self.eOnDelay = false
                self.eState = false
                player:castSpell("self", 2)
            end
        end
	end
end

function KoreaKarthus:AutoDisableE()
    if not self:IsEnemyHeroInE() and not self:IsEnemyInE() then
        self:DisableE()
    end
end

function KoreaKarthus:IsEnemyInE()
    if #(common.GetMinionsInRange(550, TEAM_ENEMY)) > 0 or #(common.GetMinionsInRange(550, TEAM_NEUTRAL)) > 0 then
        return true
    else
        return false
    end
end

function KoreaKarthus:IsEnemyHeroInE()
    if #(common.GetEnemyHeroesInRange(self.menu.msic.useERange:get())) > 0 then
        return true
    else
        return false
    end
end

function KoreaKarthus:CheckMana(persent)
    return (player.mana / player.maxMana) >= (persent * 0.01)
end

function KoreaKarthus:Floor(number) 
    return math.floor((number) * 100) * 0.01
end

-- Checking Update

-- updated checked

LoadScript()
