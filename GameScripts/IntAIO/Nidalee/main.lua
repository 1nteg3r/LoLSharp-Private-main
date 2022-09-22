local common = module.load('int', 'Library/common');
local dlib = module.load('int', 'Library/damageLib');
local TS = module.internal('TS');
local mainP = module.internal("pred")
local evade = module.seek("evade")
local orb = module.internal("orb");

local function class()
	local cls = {}
	cls.__index = cls
	return setmetatable(cls, { __call = function (c, ...)
		local instance = setmetatable({}, cls)
		if cls.__init then
			cls.__init(instance, ...)
		end
		return instance
	end})
end

local TargetSelection = function(res, obj, dist) --Range default
	if dist < 1500 then
		res.obj = obj
		return true
	end
end

local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end

local function trace_filter(Input, seg, obj)
  local totalDelay = (Input.delay + network.latency)

  if seg.startPos:dist(seg.endPos)
          + (totalDelay * obj.moveSpeed)
          + obj.boundingRadius > Input.range then
      return false
  end

  local collision = mainP.collision.get_prediction(Input, seg, obj)
  if collision then
      return false
  end

  if mainP.trace.linear.hardlock(Input, seg, obj) then
      return true
  end

  if mainP.trace.linear.hardlockmove(Input, seg, obj) then
      return true
  end

  local t = obj.moveSpeed / Input.speed

  if mainP.trace.newpath(obj, totalDelay, totalDelay + t) then
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

      local seg = mainP.linear.get_prediction(input, obj)

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

      res.pos = (mainP.core.get_pos_after_time(obj, t1) + seg.endPos) / 2

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

local IntNidalleee = class()

function IntNidalleee:__init()
	self.version = "1.5.0"
	self.menu = menu("IntnnerNidalee", "Int Nidalee")
	self.menu:header("title", "Core")
	self.menu:dropdown("pSet", "Combo:", 1, {"Kite", "Mode Nidalee"})
	self.menu:keybind("flee", "Flee", "Z", false)
	self.menu:menu("combo", "Combo")
	self.menu:menu("harass", "Harass")
	self.menu:menu("farm", "Farm/Jungle")
	self.menu:menu("heal", "Heal")
	self.menu:menu("misc", "Misc")
	self.menu:menu("draws", "Display")

	-- Combo section
	self.menu.combo:header("title", "Combo")
	self.menu.combo:menu("human", "Human")
	self.menu.combo.human:boolean("useQ", "Use Q", true)
	self.menu.combo.human:boolean("useW", "Use W", true)
	self.menu.combo:menu("cougar", "Cougar")
	self.menu.combo.cougar:boolean("useQ", "Use Q", true)
	self.menu.combo.cougar:boolean("useW", "Use W", true)
	self.menu.combo.cougar:boolean("useE", "Use E", true)
	self.menu.combo:boolean("useR", "Use R", true)

	-- Harass section
	self.menu.harass:header("title", "Harass")
	self.menu.harass:boolean("useQ", "Use Q", true)
	self.menu.harass:slider("mana", "Mana Limit", 30, 10, 100, 5)

	-- Farm/Jungle section --
	self.menu.farm:header("title", "Farm/Jungle")
	self.menu.farm:menu("human", "Human Spells")
	self.menu.farm.human:boolean("useQ", "Use Q", true)
	self.menu.farm.human:boolean("useW", "Use W", true)
	self.menu.farm:menu("cougar", "Cougar Spells")
	self.menu.farm.cougar:boolean("useQ", "Use Q", true)
	self.menu.farm.cougar:boolean("useW", "Use W", true)
	self.menu.farm.cougar:boolean("useE", "Use E", true)
	self.menu.farm:boolean("autoR", "Auto Player", true)
	self.menu.farm:slider("mana", "Mana for Player ", 30, 10, 100, 5)

	-- Heal section
	self.menu.heal:header("title", "Heal")
	self.menu.heal:boolean("useSelf", "Use E to Heal", true)
	self.menu.heal:slider("manaSelf", "Heal if Mana", 40, 10, 100, 5)
	self.menu.heal:slider("hpSelf", "Heal if HP", 60, 10, 100, 5)
	self.menu.heal:header("info2", "Ally Mode")
	self.menu.heal:boolean("useAlly", "Use E to Heal", true)
	self.menu.heal:slider("manaAlly", "Heal if Mana", 60, 10, 100, 5)
	self.menu.heal:slider("hpAlly", "Heal if HP", 50, 10, 100, 5)
	self.menu.heal:boolean("autoR", "Auto Switch Form", true)

	-- Misc section
	self.menu.misc:header("title", "Misc")
	self.menu.misc:boolean("killsteal", "KS Logic", true)

	-- Draw section
	self.menu.draws:header("title", "Display")
	--self.menu.draws:boolean("drawCD", "Draw Cooldowns", true)
	self.menu.draws:menu("human", "Human")
	self.menu.draws.human:boolean("drawQ", "Draw Q Range", true)
	self.menu.draws.human:boolean("drawW", "Draw W Range", false)
	self.menu.draws.human:boolean("drawE", "Draw E Range", false)
	self.menu.draws:menu("cougar", "Cougar")
	self.menu.draws.cougar:boolean("drawQ", "Draw Q Range", false)
	self.menu.draws.cougar:boolean("drawW", "Draw W Range", false)
	self.menu.draws.cougar:boolean("drawE", "Draw E Range", true)
	
	self.CDTracker = {
		["Human"] = {
			[0] = { CD = player:spellSlot(0).cooldown <= 0 and 6 or player:spellSlot(0).cooldown, CDT = 0, T = 0, ready = false, name = "JavelinToss" },
			[1] = { CD = player:spellSlot(1).cooldown <= 0 and 13 or player:spellSlot(1).cooldown, CDT = 0, T = 0, ready = false, name = "Bushwhack" },
			[2] = { CD = player:spellSlot(2).cooldown <= 0 and 12 or player:spellSlot(2).cooldown, CDT = 0, T = 0, ready = false, name = "PrimalSurge" }
		},
		["Cougar"] = {
			[0] = { CD = player:spellSlot(0).cooldown <= 0 and 6 or player:spellSlot(0).cooldown, CDT = 0, T = 0, ready = false, name = "Takedown" },
			[1] = { CD = player:spellSlot(1).cooldown <= 0 and 6 or player:spellSlot(1).cooldown, CDT = 0, T = 0, ready = false, name = "Pounce" },
			[2] = { CD = player:spellSlot(2).cooldown <= 0 and 6 or player:spellSlot(2).cooldown, CDT = 0, T = 0, ready = false, name = "Swipe" }
		}
	}

	self.spells = {
		["Human"] = {
			[0] = {
				slot = player:spellSlot(0),
				range = 1500,
				cpre = { range = 1500,  width = 40, delay = 0.25, speed = 1300, boundingRadiusMod = 1, collision = { hero = true, minion = true } },
				--apre = aPred.new_data{delay = 0.25, radius = 50, speed = 1300, collision = bit.bor(11), addBoundingRadius = true}
			}, --collision = aPred.enum.collisionType.minion | aPred.enum.collisionType.champion | aPred.enum.collisionType.yasuoWall
			[1] = {
				slot = player:spellSlot(1),
				range = 900,
				cpre = { delay = 1, radius = 80, speed = math.huge, boundingRadiusMod = 0 }
			},
			[2] = {
				slot = player:spellSlot(2),
				range = 600
			},
			[3] = {
				slot = player:spellSlot(3)
			}
		},
		["Cougar"] = {
			[0] = { slot = player:spellSlot(0), range = 200 },
			[1] = { slot = player:spellSlot(1), range = 375 },
			[2] = { slot = player:spellSlot(2), range = 300 },
			[3] = { slot = player:spellSlot(3) }
		}
	}
	
	--initialize callbacks
  orb.combat.register_f_pre_tick(function()
    local target = GetTarget()
    if target and target.pos:dist(player.pos) < common.GetAARange(target) then
      orb.combat.target = target
    end
    self:OnTick()
    return false
  end)

	cb.add(cb.spell, function(spell) self:OnProcessSpell(spell) end)
	cb.add(cb.draw, function() self:OnDraw() end)
end

local function roundNum(num, idp)
	local mult = 10 ^ (idp or 0)
	if num >= 0 then
		return math.floor(num * mult + 0.5) / mult
	else
		return math.ceil(num * mult - 0.5) / mult
	end
end

local function isHuman()
	return player:spellSlot(0).name == "JavelinToss"
end

local function isHunted(unit)
	return unit.buff["nidaleepassivehunted"]
end

function IntNidalleee:Cooldowns()
	for i = 0, 2, 1 do
		if player:spellSlot(i).level > 0 then
			self.CDTracker.Human[i].T = self.CDTracker.Human[i].CDT + self.CDTracker.Human[i].CD - game.time
			self.CDTracker.Cougar[i].T = self.CDTracker.Cougar[i].CDT + self.CDTracker.Cougar[i].CD - game.time
			
			if self.CDTracker.Human[i].T <= 0 then
				self.CDTracker.Human[i].ready = true
				self.CDTracker.Human[i].T = 0
			else
				self.CDTracker.Human[i].ready = false
			end
			
			if self.CDTracker.Cougar[i].T <= 0 then
				self.CDTracker.Cougar[i].ready = true
				self.CDTracker.Cougar[i].T = 0
			else
				self.CDTracker.Cougar[i].ready = false
			end
		end
	end
end

function IntNidalleee:GetQDmg(unit, poss)
	if player:spellSlot(0).level < 1 or not unit or unit.isDead or not unit.isVisible or not unit.isTargetable or unit.buff[17] then return 0 end
	-- default + (25% per 96.875 units traveled) capped at 200% at 1300 units
	-- 525 = default, 621.875 = 25%, 718.75 = 50%, 815.625 = 75%, 912.5 = 100%, 1009.375 = 125%, 1106.25 = 150%, 1203.125 = 175%, 1300 = 200%
	local d = poss and player.path.serverPos:dist(poss) or player.path.serverPos:dist(unit.path.serverPos)
	local pctIncrease = 1
	if d >= 622 then
		if d >= 1300 then
			pctIncrease = 3
		else
			local hold = (d - 525) / 96.875
			pctIncrease = ({ 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3 })[math.floor(hold)]
		end
	end
	local damage = (({ 70, 85, 100, 115, 130 })[player:spellSlot(0).level] + (0.4 * common.GetTotalAP())) * pctIncrease
	return common.CalculateMagicDamage(unit, damage)
end

function IntNidalleee:FleeKiteLogic()
	player:move(game.mousePos)
  local target = GetTarget()
  if target then
    local dist = player.path.serverPos:dist(target.path.serverPos)
    local Qlevel = player:spellSlot(0).level
    local manaSpear = Qlevel > 0 and ({ 50, 60, 70, 80, 90 })[Qlevel] or 0
    if isHuman() then
      if player:spellSlot(0).state == 0 and common.IsValidTarget(target) and dist < 1500 then
        if self.menu.pSet:get() == 1 or self.menu.pSet:get() == 2 then
          local seg = mainP.linear.get_prediction(self.spells.Human[0].cpre, target)
          if seg and seg.startPos:dist(seg.endPos) < self.spells.Human[0].range then
            local col = mainP.collision.get_prediction(self.spells.Human[0].cpre, seg, target)
            if not col and self.spells.Human[0].slot.state == 0 then
              player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end
          end
        --[[elseif common.IsValidTarget(target) and self.menu.pSet:get() == 2 then
          local p = aPred.get(target, self.spells.Human[0].apre)
          if common.IsValidTarget(target) and p and p.pos:dist(player.pos) < self.spells.Human[0].range and not p:collision(0) and self.spells.Human[0].slot.state == 0 then
            game.cast("pos", 0, p.pos)
          end]]
        end
      elseif (player:spellSlot(0).state ~= 0 or not common.IsValidTarget(target) or (common.IsValidTarget(target) and dist >= 1500)) and player:spellSlot(3).state == 0 then
        player:castSpell("self", 3)
        -- change to cougar
      end
    end
    if not isHuman() then
      if self.CDTracker.Human[0].ready == true and common.IsValidTarget(target) and player:spellSlot(3).state == 0 and player.par >= manaSpear then
        if common.IsValidTarget(target) and dist < 1500 then
          player:castSpell("self", 3)
        end
        -- change to human to spear
      elseif player:spellSlot(1).state == 0 then
        if self.CDTracker.Human[0].ready == false or player:spellSlot(3).state ~= 0 or not common.IsValidTarget(target) or player.par < manaSpear or (common.IsValidTarget(target) and dist >= 1500) then
          local jumpPos = player.pos + (game.mousePos - player.pos):norm() * 400
          player:castSpell("pos", 1, jumpPos)
          -- cast W to mouse
        end
      end
    end
  end
end

function IntNidalleee:farming()
	local manaCheck = common.GetPercentPar() > self.menu.farm.mana:get()
  local minions = objManager.minions
  for i = 0, minions.size[TEAM_ENEMY] - 1 do
    local minion = minions[TEAM_ENEMY][i]
		if minion and not minion.isDead and minion.isVisible and minion.isTargetable and not minion.buff[17] and minion.baseAttackDamage > 5 then
      local dist = player.path.serverPos:dist(minion.path.serverPos)
      if not isHuman() then
        if self.menu.farm.cougar.useQ:get() and self.spells.Cougar[0].slot.state == 0 and dist <= 400 then
          player:castSpell("self", 0)
        end
        if self.menu.farm.cougar.useW:get() and self.spells.Cougar[1].slot.state == 0 then
          if dist <= self.spells.Cougar[1].range and (dlib.GetSpellDamage(1, minion, 2) + common.CalculateAADamage(minion)) > minion.health then
            player:castSpell("pos", 1, minion.pos)
          end
        end
        if self.menu.farm.cougar.useE:get() and self.spells.Cougar[2].slot.state == 0 then
          if dist < (self.spells.Cougar[2].range + minion.boundingRadius) then
            player:castSpell("pos", 2, minion.pos)
          end
        end
        if self.menu.farm.autoR:get() and player:spellSlot(3).state == 0 then
          if self.spells.Cougar[0].slot.state ~= 0 and self.spells.Cougar[1].slot.state ~= 0 and self.spells.Cougar[2].slot.state ~= 0 and manaCheck then
            player:castSpell("self", 3)
          end
        end
      end
      if isHuman() then
        if self.menu.farm.human.useQ:get() and self.spells.Human[0].slot.state == 0 and manaCheck and dist <= self.spells.Human[0].range then
          if self.menu.pSet:get() == 1 or self.menu.pSet:get() == 2 then
            local seg = mainP.linear.get_prediction(self.spells.Human[0].cpre, minion)
            if seg and seg.startPos:dist(seg.endPos) < self.spells.Human[0].range then
              local col = mainP.collision.get_prediction(self.spells.Human[0].cpre, seg, minion)
              if not col then
                player:castSpell("pos", 0, vec3(seg.endPos.x, minion.y, seg.endPos.y))
              end
            end
          --[[elseif can_target_minion(minion) and self.menu.pSet:get() == 2 then
            local p = aPred.get(minion, self.spells.Human[0].apre)
            if can_target_minion(minion) and p and p.pos:dist(player.pos) < self.spells.Human[0].range and not p:collision(0) then
              game.cast("pos", 0, p.pos)
            end]]
          end
        end
        if self.menu.farm.human.useW:get() and self.spells.Human[1].slot.state == 0 and dist < self.spells.Human[1].range and manaCheck then
          if dlib.GetSpellDamage(1, minion) > minion.health and not minion.path.isActive then
            player:castSpell("pos", 1, minion.pos)
          end
        end
        if self.menu.farm.autoR:get() and player:spellSlot(3).state == 0 and (self.spells.Human[0].slot.state ~= 0 or not manaCheck or not self.menu.farm.human.useQ:get()) then
          player:castSpell("self", 3)
        end
      end
    end
	end
end

function IntNidalleee:GetClosestJungleMob()
	local closestMob, distanceMob = nil, math.huge
  local minions = objManager.minions
  for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
    local check = minions[TEAM_NEUTRAL][i]
		if check and not check.isDead and check.isVisible then
			local mobDist = player.path.serverPos:dist(check.path.serverPos)
			if mobDist < distanceMob then
				distanceMob = mobDist
				closestMob = check
			end
		end
	end
	return closestMob
end

function IntNidalleee:jungling()
	local manaCheck = common.GetPercentPar() > self.menu.farm.mana:get()
  local minions = objManager.minions
  for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
    local minion = minions[TEAM_NEUTRAL][i]
		if minion and not minion.isDead and minion.isVisible and minion.isTargetable and not minion.buff[17] and minion.baseAttackDamage > 5 then
      local dist = player.path.serverPos:dist(minion.path.serverPos)
      if not isHuman() then
        if self.menu.farm.cougar.useQ:get() and self.spells.Cougar[0].slot.state == 0 and dist <= 400 then
          player:castSpell("self", 0)
        end
        if self.menu.farm.cougar.useW:get() and self.spells.Cougar[1].slot.state == 0 then
          if dist <= 750 and isHunted(minion) then
            player:castSpell("pos", 1, minion.pos)
          elseif dist <= self.spells.Cougar[1].range then
            player:castSpell("pos", 1, minion.pos)
          end
        end
        if self.menu.farm.cougar.useE:get() and self.spells.Cougar[2].slot.state == 0 then
          if dist < (self.spells.Cougar[2].range + minion.boundingRadius) then
            player:castSpell("pos", 2, minion.pos)
          end
        end
        if self.menu.farm.autoR:get() and player:spellSlot(3).state == 0 and manaCheck then
          if self.spells.Cougar[0].slot.state ~= 0 and self.spells.Cougar[1].slot.state ~= 0 and self.spells.Cougar[2].slot.state ~= 0 then
            player:castSpell("self", 3)
          end
        end
      end
      if isHuman() then
        if self.menu.farm.human.useQ:get() and self.spells.Human[0].slot.state == 0 and manaCheck then
          local closeMob = self:GetClosestJungleMob()
          if closeMob and closeMob.ptr == minion.ptr and dist <= self.spells.Human[0].range then
            if self.menu.pSet:get() == 1 or self.menu.pSet:get() == 2 then
              local seg = mainP.linear.get_prediction(self.spells.Human[0].cpre, minion)
              if seg and seg.startPos:dist(seg.endPos) < self.spells.Human[0].range then
                local col = mainP.collision.get_prediction(self.spells.Human[0].cpre, seg, minion)
                if not col then
                  player:castSpell("pos", 0, vec3(seg.endPos.x, minion.y, seg.endPos.y))
                end
              end
            --[[elseif can_target_minion(minion) and self.menu.pSet:get() == 2 then
              local p = aPred.get(minion, self.spells.Human[0].apre)
              if can_target_minion(minion) and p and p.pos:dist(player.pos) < self.spells.Human[0].range and not p:collision(0) then
                game.cast("pos", 0, p.pos)
              end]]
            end
          end
        end
        if self.menu.farm.human.useW:get() and self.spells.Human[1].slot.state == 0 then
          if dist < self.spells.Human[1].range and manaCheck and not isHunted(minion) and not minion.path.isActive then
            player:castSpell("pos", 1, minion.pos)
          end
        end
        if self.menu.farm.autoR:get() and player:spellSlot(3).state == 0 then
          if not self.menu.farm.human.useQ:get() or self.spells.Human[0].slot.state ~= 0 or not manaCheck then
            player:castSpell("self", 3)
          end
        end
      end
    end
	end
end

function IntNidalleee:healing()
	if player.isRecalling or player.isDead then return end
	if self.CDTracker.Human[2].ready == true then
		if self.menu.heal.useSelf:get() and common.GetPercentHealth() < self.menu.heal.hpSelf:get() and common.GetPercentPar() > self.menu.heal.manaSelf:get() then
			if isHuman() and player:spellSlot(2).state == 0 then
				player:castSpell("self", 2)
			end
			if not isHuman() and self.menu.heal.autoR:get() and player:spellSlot(3).state == 0 and not orb.combat.is_active() and not orb.menu.lane_clear:get() then
				player:castSpell("self", 3)
        orb.core.set_server_pause()
				player:castSpell("self", 2)
			end
		end
		if self.menu.heal.useAlly:get() and common.GetPercentPar() > self.menu.heal.manaAlly:get() then
      for i = 0, objManager.allies_n - 1 do
        local ally = objManager.allies[i]
				if ally and not ally.isDead and ally.isVisible and not ally.buff[17] then
          local dist = player.path.serverPos:dist(ally.path.serverPos)
          if dist <= 600 and common.GetPercentHealth(ally) < self.menu.heal.hpAlly:get() then
            if isHuman() and player:spellSlot(2).state == 0 then
              player:castSpell("obj", 2, ally)
            end
            if not isHuman() and self.menu.heal.autoR:get() and player:spellSlot(3).state == 0 and not orb.combat.is_active() and not orb.menu.lane_clear:get() then
              player:castSpell("self", 3)
              orb.core.set_server_pause()
              player:castSpell("obj", 2, ally)
            end
          end
				end
			end
		end
	end
end

function IntNidalleee:KS()
	if not self.menu.misc.killsteal:get() or player:spellSlot(0).level < 1 or self.CDTracker.Human[0].ready == false then return end
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if enemy and common.IsValidTarget(enemy) and enemy.pos:dist(player.pos) <= 1500 then
      if isHuman() and player:spellSlot(0).state == 0 and self.CDTracker.Human[0].ready == true then
        if self:GetQDmg(enemy) > common.GetShieldedHealth("AP", enemy) then
          if self.menu.pSet:get() == 1 or self.menu.pSet:get() == 2 then
            local seg = mainP.linear.get_prediction(self.spells.Human[0].cpre, enemy)
            if seg and seg.startPos:dist(seg.endPos) <= self.spells.Human[0].range then
              local col = mainP.collision.get_prediction(self.spells.Human[0].cpre, seg, enemy)
              if not col and self:GetQDmg(enemy, vec3(seg.endPos.x, enemy.y, seg.endPos.y)) > common.GetShieldedHealth("AP", enemy) then
                player:castSpell("pos", 0, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
              end
            end
          --[[elseif common.IsValidTarget(e) and self.menu.pSet:get() == 2 then
            local p = aPred.get(e, self.spells.Human[0].apre)
            if common.IsValidTarget(e) and p and p.pos:dist(player.pos) <= self.spells.Human[0].range and not p:collision(0) and self.spells.Human[0].slot.state == 0 and self:GetQDmg(e, p.pos) > common.GetShieldedHealth("ap", e) then
              game.cast("pos", 0, p.pos)
            end]]
          end
        end
      end
    end
  end
end

function IntNidalleee:Harass()
	if common.GetPercentPar() < self.menu.harass.mana:get() or not isHuman() then return end
	if self.menu.harass.useQ:get() and isHuman() and player:spellSlot(0).state == 0 then
		local target = GetTarget();
		if target and common.IsValidTarget(target) and target.pos:dist(player.pos) <= 1500 then
			if self.menu.pSet:get() == 1 or self.menu.pSet:get() == 2 then
				local seg = mainP.linear.get_prediction(self.spells.Human[0].cpre, target)
				if seg and seg.startPos:dist(seg.endPos) <= self.spells.Human[0].range then
					local col = mainP.collision.get_prediction(self.spells.Human[0].cpre, seg, target)
					if not col and self.spells.Human[0].slot.state == 0 then
						player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
					end
				end
			--[[elseif common.IsValidTarget(target) and self.menu.pSet:get() == 2 then
				local p = aPred.get(target, self.spells.Human[0].apre)
				if common.IsValidTarget(target) and p and p.pos:dist(player.pos) <= self.spells.Human[0].range and not p:collision(0) and self.spells.Human[0].slot.state == 0 then
					game.cast("pos", 0, p.pos)
				end]]
			end
		end
	end
end

function IntNidalleee:Combo()
	local target = GetTarget()
	if orb.combat.target then
		target = orb.combat.target
	end
  if target and common.IsValidTarget(target) then
    local dist = player.path.serverPos:dist(target.path.serverPos)
    if isHuman() then
      if self.menu.combo.human.useQ:get() and self.spells.Human[0].slot.state == 0 and dist <= 1500 then
        if self.menu.pSet:get() == 1 or self.menu.pSet:get() == 2 then
              local target = TS.get_result(real_target_filter(self.spells.Human[0].cpre).Result) 
              if target.pos then 
                  player:castSpell("pos", 0, vec3(target.pos.x, mousePos.y, target.pos.y))
              end
            
          
        --[[elseif common.IsValidTarget(target) and self.menu.pSet:get() == 2 then
          local p = aPred.get(target, self.spells.Human[0].apre)
          if common.IsValidTarget(target) and p and p.pos:dist(player.pos) <= self.spells.Human[0].range and not p:collision(0) and self.spells.Human[0].slot.state == 0 then
            game.cast("pos", 0, p.pos)
          end]]
        end
      end
      if self.menu.combo.human.useW:get() and self.spells.Human[1].slot.state == 0 then
        if dist <= self.spells.Human[1].range then
          local seg = mainP.circular.get_prediction(self.spells.Human[1].cpre, target)
          if seg and seg.startPos:dist(seg.endPos) <= self.spells.Human[1].range then
            player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
          end
        end
      end
      if self.menu.combo.useR:get() and player:spellSlot(3).state == 0 then
        if dist <= 375 or (isHunted(target) and dist <= 750 and self.CDTracker.Cougar[1].ready == true) then
          player:castSpell("self", 3)
        end
      end
    end
    if not isHuman() then
      if self.menu.combo.cougar.useW:get() and player:spellSlot(1).state == 0 then
        if isHunted(target) and dist <= 750 then
          player:castSpell("pos", 1, target.pos)
        elseif dist <= self.spells.Cougar[1].range then
          player:castSpell("pos", 1, target.pos)
        end
      end
      if self.menu.combo.cougar.useE:get() and player:spellSlot(2).state == 0 then
        if dist < (self.spells.Cougar[2].range + target.boundingRadius) then
          player:castSpell("pos", 2, target.pos)
        end
      end
      if self.menu.combo.cougar.useQ:get() and player:spellSlot(0).state == 0 and dist < 400 then
        player:castSpell("self", 0)
        orb.core.reset()
      end
      if self.menu.combo.useR:get() and player:spellSlot(3).state == 0 then
        local Qlevel = player:spellSlot(0).level
        local manaSpear = Qlevel > 0 and ({ 50, 60, 70, 80, 90 })[Qlevel] or 0
        if isHunted(target) and dist > 750 and player.par >= manaSpear and self.CDTracker.Human[0].ready == true then
          player:castSpell("self", 3)
        elseif dist > 375 then
          player:castSpell("self", 3)
        elseif player:spellSlot(0).state ~= 0 and player:spellSlot(1).state ~= 0 and player:spellSlot(2).state ~= 0 then
          if player.par >= manaSpear and self.CDTracker.Human[0].ready == true then
            player:castSpell("self", 3)
          end
        end
      end
    end
  end
end

function IntNidalleee:OnProcessSpell(spell)
	if spell.owner.ptr == player.ptr and not spell.isBasicAttack then
		for i = 0, 2, 1 do
			if spell.name == self.CDTracker.Human[i].name then
				self.CDTracker.Human[i].CDT = game.time
			elseif spell.name == self.CDTracker.Cougar[i].name then
				self.CDTracker.Cougar[i].CDT = game.time
			end
		end
	end
end

function IntNidalleee:OnDraw()
	if not player.isDead and player.isOnScreen then
    --if self.menu.draws.drawCD:get() then
      --local wtspos = graphics.world_to_screen(player.pos)
      --[[if isHuman() then
        for i = 0, 2 do
          local slot = ({ "Q", "W", "E" })[(i + 1)]
          local color = self.CDTracker.Cougar[i].ready == true and graphics.argb(255, 0, 255, 10) or graphics.argb(255, 255, 0, 0)
          graphics.draw_text_2D(tostring(slot)..": "..tostring(roundNum(self.CDTracker.Cougar[i].T > 0 and self.CDTracker.Cougar[i].T or 0)), 20, (wtspos.x - 60 + (i * 40)), (wtspos.y + 50), color)
        end
      else
        for i = 0, 2 do
          local slot = ({ "Q", "W", "E" })[(i + 1)]
          local color = self.CDTracker.Human[i].ready == true and graphics.argb(255, 0, 255, 10) or graphics.argb(255, 255, 0, 0)
          graphics.draw_text_2D(tostring(slot)..": "..tostring(roundNum(self.CDTracker.Human[i].T > 0 and self.CDTracker.Human[i].T or 0)), 20, (wtspos.x - 60 + (i * 40)), (wtspos.y + 50), color)
        end
      end
    end]]
    if isHuman() then
      if self.menu.draws.human.drawQ:get() then
        graphics.draw_circle(player.pos, self.spells.Human[0].range, 2, graphics.argb(255, 255, 255, 255), 40)
      end
      if self.menu.draws.human.drawW:get() then
        graphics.draw_circle(player.pos, self.spells.Human[1].range, 2, graphics.argb(255, 255, 255, 255), 40)
      end
      if self.menu.draws.human.drawE:get() then
        graphics.draw_circle(player.pos, self.spells.Human[2].range, 2, graphics.argb(255, 255, 255, 255), 40)
      end
    else
      if self.menu.draws.cougar.drawQ:get() then
        graphics.draw_circle(player.pos, self.spells.Cougar[0].range, 2,  graphics.argb(255, 255, 255, 255), 40)
      end
      if self.menu.draws.cougar.drawW:get() then
        graphics.draw_circle(player.pos, self.spells.Cougar[1].range, 2,  graphics.argb(255, 255, 255, 255), 40)
      end
      if self.menu.draws.cougar.drawE:get() then
        graphics.draw_circle(player.pos, self.spells.Cougar[2].range, 2,  graphics.argb(255, 255, 255, 255), 40)
      end
    end
  end
end

function IntNidalleee:OnTick()
	if player.isDead or (evade and evade.core.is_active()) then return end
	self:Cooldowns()
	if self.menu.flee:get() then
		self:FleeKiteLogic()
  end 
  if orb.combat.is_active() then
		self:Combo()
  end 
  if orb.menu.hybrid:get() then
		self:Harass()
  end 
  if orb.menu.lane_clear:get() then
		self:farming()
		self:jungling()
	end
	self:KS()
	self:healing()
end

--Execute the Class
if player.charName == "Nidalee" then
	IntNidalleee()
end