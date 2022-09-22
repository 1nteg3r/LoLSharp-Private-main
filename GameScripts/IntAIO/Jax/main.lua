-- Updated for zeitgeist by ryan

local common = module.load('int', 'Library/common');
local dlib = module.load('int', 'Library/damageLib');
local evade = module.seek("evade")
local TS = module.internal('TS');
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
	if dist < 700 then
		res.obj = obj
		return true
	end
end

local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end

local IntJump = class()

function IntJump:__init()
	self.version = "2.3.0"
	self.aggroTable = {}
  self.enemyTowers = {}
	self.Sticky = false
	self.LastAATarget = nil
	self.BaronUnit = nil
	self.menu = menu("IntnnerJax", "Int Jax")
	self.menu:header("title", "Core")
	self.menu:menu("combo", "Combo")
	self.menu:menu("harass", "Harass")
	self.menu:menu("farm", "Lane Clear")
	self.menu:menu("auto", "Misc")
	self.menu:menu("draws", "Display")
	self.menu:slider("magR", "Magnet Lock Range", 300, 100, 1000, 50)
	self.menu:keybind("jump", "Jump Key", "T", false)
	self.menu:menu("jumper", "Jump")

	self.menu.combo:header("title", "Combo")
	self.menu.combo:boolean("useQ", "Use Q", true) -- done
	self.menu.combo:boolean("useE", "Use E", true) -- done
	self.menu.combo:dropdown("Emode", "E Mode:", 2, {"Stun", "Block"}) --done
	self.menu.combo:boolean("useR", "Use R", true) -- done
	self.menu.combo:slider("Rcount", "Min Enemies", 2, 1, 5, 1) -- done
	self.menu.combo:header("eeee", "Misc combo")
	self.menu.combo:boolean("use1", "Use Titanic Hydra", true) -- done
	self.menu.combo:boolean("use2", "Use Tiamat/Rav. Hydra", true) -- done
	self.menu.combo:boolean("use3", "Use BOTRK", true) -- done
	self.menu.combo:boolean("use4", "Use Bilgewater Cutlass", true) -- done
	self.menu.combo:boolean("use5", "Use Hextech Gunblade", true)

	self.menu.harass:header("title", "Harass")
	self.menu.harass:boolean("useQ", "Use Q to Harass", true)
	self.menu.harass:slider("mana", "Min Mana %", 30, 1, 100, 1)

	self.menu.farm:header("title", "Lane Clear")
	self.menu.farm:boolean("useQ", "Use Q", true)
	self.menu.farm:dropdown("useW", "Use W to: ", 1, {"Kill Only", "Always", "Never"})
	self.menu.farm:slider("mana", "Min Mana %", 30, 1, 100, 1)

	self.menu.auto:header("title", "Misc")
	self.menu.auto:boolean("autoE", "Auto E", true) -- done
	self.menu.auto:slider("Eaggro", "Aggro Count", 3, 1, 10, 1) -- done
	self.menu.auto:slider("Elowhp", "Health < ", 15, 1, 100, 1) -- done
	self.menu.auto:boolean("autoW", "Auto W", true) -- done

	self.menu.draws:header("title", "Display")
	self.menu.draws:boolean("drawQ", "Q Range", true) --done
	self.menu.draws:boolean("drawE", "E Range", false) -- done

	self.menu.jumper:header("title", "Jump")
	self.menu.jumper:boolean("castWard", "Cast Normal Wards to Jump?", true)
	self.menu.jumper:boolean("castTrinket", "Cast Trinket Ward to Jump?", true)
	self.menu.jumper:boolean("castJammer", "Cast Pink Ward to Jump?", false)


	orb.combat.register_f_pre_tick(function()
	local target = GetTarget()
    if target and target.pos:dist(player.pos) < common.GetAARange(target) then
      orb.combat.target = target
    end
    self:onTick()
    return false
	end)
	orb.combat.register_f_after_attack(function()
    if evade and evade.core.is_active() then return end
    if orb.menu.last_hit:get() then return end
    local enemyCreep = false
    if orb.menu.lane_clear:get() and self.LastAATarget and self.LastAATarget.type == TYPE_MINION and self.LastAATarget.type == TYPE_TURRET and self.LastAATarget.type == TYPE_INHIB and self.LastAATarget.team == TEAM_ENEMY and string.find(string.lower(self.LastAATarget.charName), "minion") then
      enemyCreep = true
      if self.menu.farm.useW:get() ~= 2 or common.GetPercentPar() <= self.menu.farm.mana:get() then
        return
      end
    end
    if ((self.menu.auto.autoW:get() and not enemyCreep) or (self.menu.farm.useW:get() == 2 and enemyCreep)) and player:spellSlot(1).state == 0 and self.LastAATarget and not self.LastAATarget.isDead and self.LastAATarget.isVisible and self.LastAATarget.isTargetable and player.pos:dist(self.LastAATarget.pos) <= common.GetAARange(self.LastAATarget) and self.LastAATarget.health and self.LastAATarget.health > common.CalculateAADamage(self.LastAATarget) then
      player:castSpell("self", 1)
      orb.core.set_server_pause()
      orb.combat.set_invoke_after_attack(false)
      if self.LastAATarget and self.LastAATarget and not self.LastAATarget.isDead and self.LastAATarget.isVisible and self.LastAATarget.isTargetable then
        player:attack(self.LastAATarget)
        orb.core.set_server_pause()
        orb.combat.set_invoke_after_attack(false)
      end
      return "on_after_attack_w"
    elseif orb.combat.is_active() and orb.combat.target then
      if self.menu.combo.use1:get() then
        local c_target = orb.combat.target
        if common.IsValidTarget(c_target) and player.pos:dist(c_target.pos) < common.GetAARange(c_target) then
          for i = 6, 11 do
            local slot = player:spellSlot(i)
            if slot.isNotEmpty and (slot.name == "ItemTitanicHydraCleave" or slot.name == "ItemTiamatCleave") and slot.state == 0 then
              player:castSpell("self", i)
              orb.core.set_server_pause()
              orb.combat.set_invoke_after_attack(false)
              player:attack(c_target)
              orb.core.set_server_pause()
              orb.combat.set_invoke_after_attack(false)
              return "on_after_attack_hydra"
            end
          end
        end
      end
    end
  end)
	cb.add(cb.draw, function() self:onDraw() end)
	cb.add(cb.spell, function(spell) self:ProcessSpell(spell) end)
	cb.add(cb.path, function(unit) self:onNewPath(unit) end)
	cb.add(cb.loseaggro, function(spell, reset) self:onLoseAggro(spell, reset) end)
	cb.add(cb.issueorder, function(order, pos, target) self:OnIssueOrder(order, pos, target) end)
end

function IntJump:is_E_active()
	return player.buff["jaxcounterstrike"]
end

function IntJump:Combo()
	local target = GetTarget()
	if target and common.IsValidTarget(target) then
    local dist = player.path.serverPos:dist(target.path.serverPos)
    if orb.combat.target and target.ptr == orb.combat.target.ptr then
      if dist < 550 then
        if self.menu.combo.use3:get() then
          for i = 6, 11 do
            local slot = player:spellSlot(i)
            if slot.isNotEmpty and slot.name == "ItemSwordOfFeastAndFamine" and slot.state == 0 then
              player:castSpell("obj", i, target)
              break
            end
          end
        end
        if self.menu.combo.use4:get() then
          for i = 6, 11 do
            local slot = player:spellSlot(i)
            if slot.isNotEmpty and slot.name == "BilgewaterCutlass" and slot.state == 0 then
              player:castSpell("obj", i, target)
              break
            end
          end
        end
      end
      if self.menu.combo.use5:get() and dist < 700 then
        for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and slot.name == "HextechGunblade" and slot.state == 0 then
            player:castSpell("obj", i, target)
            break
          end
        end
      end
    end
		if self.menu.combo.useE:get() and self.menu.combo.Emode:get() == 1 and dist < 300 and player:spellSlot(2).state == 0 and self:is_E_active() then
			player:castSpell("self", 2)
		end
		if self.menu.combo.useQ:get() and dist < 700 and player:spellSlot(0).state == 0 and ((dist >= common.GetAARange(target) and self:CheckDashPrevention(700)) or dlib.GetSpellDamage(0, target) > common.GetShieldedHealth("AD", target)) then
			player:castSpell("obj", 0, target)
		end
		if self.menu.combo.useE:get() and dist < (target.attackRange + target.boundingRadius) and player:spellSlot(2).state == 0 and not self:is_E_active() then
			player:castSpell("self", 2)
		end
		if self.menu.combo.useR:get() and player:spellSlot(3).state == 0 then
			if #common.GetEnemyHeroesInRange(700) >= self.menu.combo.Rcount:get() and #self.aggroTable >= 1 then
				player:castSpell("self", 3)
			end
		end
		if self:is_E_active() then
			if player:spellSlot(2).state == 0 and target.path.isActive and target.path.point[1]:to2D():dist(player.path.serverPos:to2D()) > 300 and target.path.point[0]:to2D():dist(player.path.serverPos:to2D()) < 300 and dist < 300 then
				player:castSpell("self", 2)
			end
		end 
	end
end

function IntJump:AutoUseE()
	if player:spellSlot(2).state == 0 and not self:is_E_active() then
		if self.menu.auto.Eaggro:get() <= #self.aggroTable and not self:is_E_active() then
			player:castSpell("self", 2)
		elseif self.menu.auto.Elowhp:get() >= common.GetPercentHealth() and not self:is_E_active() then
			player:castSpell("self", 2)
		end
	end
end

function IntJump:Magnet()
	if evade and evade.core.is_active() then
		self.Sticky = false
		return
	end
	if orb.combat.is_active() or orb.menu.hybrid:get() then
		if orb.combat.target and common.IsValidTarget(orb.combat.target) and orb.combat.target.pos:dist(player.pos) <= common.GetAARange(orb.combat.target) then
			if game.mousePos:dist(orb.combat.target.pos) <= self.menu.magR:get() then
				self.Sticky = true
				return
			end
		end
	end
	if self.Sticky then
		self.Sticky = false
	end
end

function IntJump:CheckBaron()
	if not self.BaronUnit or self.BaronUnit.isDead or self.BaronUnit.charName ~= "SRU_Baron" then
    local minions = objManager.minions
    for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
      local minion = minions[TEAM_NEUTRAL][i]
			if minion and not minion.isDead and minion.charName == "SRU_Baron" then
				self.BaronUnit = minion
				return
			end
		end
		self.BaronUnit = nil
	elseif self.BaronUnit and self.BaronUnit.charName == "SRU_Baron" then
		if common.IsValidTarget(self.BaronUnit) and self.BaronUnit.pos:dist(player.pos) < 300 and (not evade or not evade.core.is_active()) then
			if not orb.core.is_attack_paused() then
				orb.core.set_pause_attack(math.huge)
			end
			if orb.core.can_attack() then
				player:attack(self.BaronUnit)
				orb.core.set_server_pause()
			end
		elseif orb.core.is_attack_paused() then
			orb.core.set_pause_attack(0)
		end
	end
end

function IntJump:CheckDashPrevention(dashRange)
	local enemiesInRange = common.GetEnemyHeroesInRange(dashRange)
	local closestEnemy, distanceEnemy = nil, math.huge
	for i = 1, #enemiesInRange do
		local check = enemiesInRange[i]
		if check and not check.isDead and check.isVisible then
			local enemyDist = player.path.serverPos:dist(check.path.serverPos)
			if enemyDist < distanceEnemy then
				distanceEnemy = enemyDist
				closestEnemy = check
			end
		end
	end
	if not closestEnemy then return true end
	if closestEnemy and common.IsValidTarget(closestEnemy) then
		return true
	elseif closestEnemy and not closestEnemy.isDead and closestEnemy.buff["zhonyasringshield"] then
		return false
	else
		return true
	end
end

function IntJump:PositionUnderDangerousTower(pos)
  if not pos then return false end
  for i=0, objManager.turrets.size[TEAM_ENEMY]-1 do
	local tower = objManager.turrets[TEAM_ENEMY][i]
    if tower and not tower.isDead and tower.health > 0 then
      if (not tower.activeSpell or tower.activeSpell.target.isDead or tower.activeSpell.target.pos:dist(tower.pos) > 900) or (tower.activeSpell and tower.activeSpell.target.ptr == player.ptr) then
        if tower.pos:dist(pos) < 900 then
          return true
        end
      end
    else
      tower = nil
    end
  end
  return false
end

function IntJump:GetJumpObject(pos, rad)
	local distance = math.huge
	local objToJump = nil
	local radi = rad or 200
	for i = 0, objManager.maxObjects - 1 do
		local obj = objManager.get(i)
		if obj and (obj.type == TYPE_MINION or obj.type == TYPE_HERO) and obj.ptr ~= player.ptr and common.IsValidTarget(obj) then
			if obj.pos:dist(pos) <= radi and obj.pos:dist(pos) < distance then
				distance = obj.pos:dist(pos)
				objToJump = obj
			end
		end
	end
	return objToJump
end

function IntJump:JumpToStuff()
	player:move(game.mousePos)
	if player:spellSlot(0).state == 0 then
		local jumpPos = game.mousePos
		if jumpPos:dist(player.pos) > 500 then
			jumpPos = player.pos + (jumpPos - player.pos):norm() * 500
		end
		local jumpObject = self:GetJumpObject(jumpPos)
		if jumpObject and common.IsValidTarget(jumpObject) then
			player:castSpell("obj", 0, jumpObject)
		elseif self.menu.jumper.castWard:get() or self.menu.jumper.castTrinket:get() or self.menu.jumper.castJammer:get() then
			local wardslot = nil
			if self.menu.jumper.castTrinket:get() and player:spellSlot(12).name and player:spellSlot(12).name == "TrinketTotemLvl1" and player:spellSlot(12).state == 0 then
				wardslot = 12
			else
				if self.menu.jumper.castWard:get() then
					for i = 6, 11 do
						local slot = player:spellSlot(i)
            if slot.isNotEmpty and slot.name == "ItemGhostWard" and slot.state == 0 and slot.stacks ~= 0 then
              wardslot = i
              break
            end
					end
				end
				if not wardslot and self.menu.jumper.castJammer:get() then
					for i = 6, 11 do
						local slot = player:spellSlot(i)
						if slot.isNotEmpty and slot.name == "JammerDevice" and slot.state == 0 then
              wardslot = i
              break
            end
					end
				end
			end
			if wardslot and player:spellSlot(wardslot).state == 0 then
				jumpPos = game.mousePos
				if jumpPos:dist(player.pos) > 600 then
					jumpPos = player.pos + (jumpPos - player.pos):norm() * 600
				end
				player:castSpell("pos", wardslot, jumpPos)
			end
		end
	end
end

function IntJump:Clear()
  if (self.menu.farm.useQ:get() or self.menu.farm.useW:get() == 1) and common.GetPercentPar() > self.menu.farm.mana:get() then
    local minions = objManager.minions
    for i = 0, minions.size[TEAM_ENEMY] - 1 do
      local minion = minions[TEAM_ENEMY][i]
      if minion and not minion.isDead and minion.isVisible then
        local dist = player.path.serverPos:dist(minion.path.serverPos)
        if self.menu.farm.useQ:get() and player:spellSlot(0).state == 0 then
          if dist > common.GetAARange(minion) and dist < 700 and not self:PositionUnderDangerousTower(minion.pos) and dlib.GetSpellDamage(0, minion) > minion.health then
            player:castSpell("obj", 0, minion)
            break
          end
        end
        if self.menu.farm.useW:get() == 1 and player:spellSlot(1).state == 0 then
          if dist <= common.GetAARange(minion) and orb.core.can_attack() and minion.health > common.CalculateAADamage(minion) and dlib.GetSpellDamage(1, minion) > minion.health then
            player:castSpell("self", 1)
            orb.core.set_server_pause()
            player:attack(minion)
            orb.core.set_server_pause()
            break
          end
        end
      end
    end
  end
end

function IntJump:Harass()
  if self.menu.harass.useQ:get() and player:spellSlot(0).state == 0 then
	local target = GetTarget()
    if target and common.IsValidTarget(target) then
      local dist = player.path.serverPos:dist(target.path.serverPos)
      if dist < 700 and (dist > common.GetAARange(target) or dlib.GetSpellDamage(0, target) > common.GetShieldedHealth("AD", target)) and common.GetPercentPar() > self.menu.harass.mana:get() then
        player:castSpell("obj", 0, target)
      end
    end
  end
end

function IntJump:onNewPath(unit)
	if orb.combat.is_active() and unit.type == TYPE_HERO and orb.combat.target then
		if self.menu.combo.useQ:get() and player:spellSlot(0).state == 0 and unit.ptr == orb.combat.target.ptr and unit.path.serverPos:dist(player.path.serverPos) < 700 then
			if unit.path.isActive and unit.path.isDashing and not unit.buff[29] then
				if unit.path.point[1]:to2D():dist(player.pos:to2D()) > 700 and unit.path.point[1]:to2D():dist(player.pos:to2D()) > unit.path.point[0]:to2D():dist(player.pos:to2D()) then
					player:castSpell("obj", 0, unit)
				end
			end
		end
	end
end

function IntJump:onGainAggro(spell)
	if spell.owner.team ~= TEAM_ALLY and spell.target and spell.target.ptr == player.ptr then
		self.aggroTable[#self.aggroTable + 1] = spell.owner
	end
end

function IntJump:onLoseAggro(spell, reset)
	if #self.aggroTable > 0 then
		for i=1, #self.aggroTable do
			local unit = self.aggroTable[i]
			if not unit or unit.isDead or unit.ptr == spell.owner.ptr then
				table.remove(self.aggroTable, i)
			end
		end
	end
end

function IntJump:onTick()
	if player.isDead then
		if #self.aggroTable > 0 then
			for i=1, #self.aggroTable do
				table.remove(self.aggroTable, i)
			end
		end
		return
	end
	if #self.aggroTable > 0 then
		for i=1, #self.aggroTable do
			local hold = self.aggroTable[i]
			if hold and (hold.isDead or not hold.isVisible or hold.pos:dist(player.pos) > 1000) then
				table.remove(self.aggroTable, i)
			end
		end
	end
	if not orb.menu.lane_clear:get() and orb.core.is_attack_paused() then
		orb.core.set_pause_attack(0)
	end
	self:Magnet()
	if self.menu.jump:get() then
		self:JumpToStuff()
	elseif orb.combat.is_active() then
		self:Combo()
	elseif orb.menu.hybrid:get() then
		self:Harass()
	elseif orb.menu.lane_clear:get() then
		if player.pos:dist(vec3(4949, -71, 10436)) < 1000 and (not evade or not evade.core.is_active()) then
			self:CheckBaron()
		elseif orb.core.is_attack_paused() then
			orb.core.set_pause_attack(0)
		end
		self:Clear()
	end
	if self.menu.auto.autoE:get() and not player.isRecalling then
		self:AutoUseE()
	end
end

function IntJump:OnIssueOrder(order, pos, target)
	if orb.combat.target and self.Sticky and order == 2 and orb.combat.target.path.serverPos2D:dist(player.path.serverPos2D) >= player.boundingRadius then
		pos.x = orb.combat.target.x
		--pos.y = orb.combat.target.y
		pos.z = orb.combat.target.z
		--core.blockorder()
	end
end

function IntJump:ProcessSpell(spell)
	if spell.owner and spell.owner.ptr == player.ptr and spell.isBasicAttack and spell.target and spell.target.team ~= TEAM_ALLY then
		self.LastAATarget = spell.target
	end
end

function IntJump:onDraw()
  if not player.isDead then
    if player.isOnScreen then
      if self.menu.draws.drawQ:get() then
        graphics.draw_circle(player.pos, 700, 2, graphics.argb(255, 0, 255, 150), 40)
      end
      if self.menu.draws.drawE:get() then
        graphics.draw_circle(player.pos, 300, 2, graphics.argb(255, 0, 255, 150), 40)
      end
    end
  end
end

if player.charName == "Jax" then
	IntJump()
end