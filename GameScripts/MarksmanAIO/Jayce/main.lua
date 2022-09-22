local common = module.load(header.id, 'common');
local dlib = module.load(header.id, 'damageLib');
local TS = module.internal('TS');
local mainP = module.internal("pred")
local orb = module.internal("orb");
local holdcheckW = false
local countW = 2

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

local IntJayceee = class()

function IntJayceee:__init()
	self.interruptableSpells = {
		["anivia"] = {
			{menuslot = "R", slot = 3, spellname = "glacialstorm", channelduration = 6},
		},
		["caitlyn"] = {
			{menuslot = "R", slot = 3, spellname = "caitlynaceinthehole", channelduration = 1},
		},
		["ezreal"] = {
			{menuslot = "R", slot = 3, spellname = "ezrealtrueshotbarrage", channelduration = 1},
		},
		["fiddlesticks"] = {
			{menuslot = "W", slot = 1, spellname = "drain", channelduration = 5},
			{menuslot = "R", slot = 3, spellname = "crowstorm", channelduration = 1.5},
		},
		["gragas"] = {
			{menuslot = "W", slot = 1, spellname = "gragasw", channelduration = 0.75},
		},
		["janna"] = {
			{menuslot = "R", slot = 3, spellname = "reapthewhirlwind", channelduration = 3},
		},
		["karthus"] = {
			{menuslot = "R", slot = 3, spellname = "karthusfallenone", channelduration = 3},
		},
		["katarina"] = {
			{menuslot = "R", slot = 3, spellname = "katarinar", channelduration = 2.5},
		},
		["lucian"] = {
			{menuslot = "R", slot = 3, spellname = "lucianr", channelduration = 2},
		},
		["lux"] = {
			{menuslot = "R", slot = 3, spellname = "luxmalicecannon", channelduration = 0.5},
		},
		["malzahar"] = {
			{menuslot = "R", slot = 3, spellname = "malzaharr", channelduration = 2.5},
		},
		["masteryi"] = {
			{menuslot = "W", slot = 1, spellname = "meditate", channelduration = 4},
		},
		["missfortune"] = {
			{menuslot = "R", slot = 3, spellname = "missfortunebullettime", channelduration = 3},
		},
		["nunu"] = {
			{menuslot = "R", slot = 3, spellname = "absolutezero", channelduration = 3},
		},
		["pantheon"] = {
			{menuslot = "R", slot = 3, spellname = "pantheonrjump", channelduration = 2},
		},
		["shen"] = {
			{menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3},
		},
		["twistedfate"] = {
			{menuslot = "R", slot = 3, spellname = "gate", channelduration = 1.5},
		},
		["varus"] = {
			{menuslot = "Q", slot = 0, spellname = "varusq", channelduration = 4},
		},
		["warwick"] = {
			{menuslot = "R", slot = 3, spellname = "warwickr", channelduration = 1.5},
		},
		["xerath"] = {
			{menuslot = "R", slot = 3, spellname = "xerathlocusofpower2", channelduration = 3},
		}
	}
	self.version = "1.1.0"
	self.menu = menu("MarksmanAIOJayce", "Marksman - Jayce")
	self.menu:header("title", "Core")
	self.menu:menu("combo", "Combo")
	self.menu:menu("harass", "Harass")
	self.menu:menu("farm", "Farm/Jungle")
	self.menu:menu("misc", "Misc")
	self.menu:menu("draws", "Display")
	self.menu:keybind("useEQ", "E->Q to Mouse", "T", false)
  self.menu:keybind("usezFlee", "Flee Key", "Z", false)
  
	self.menu.combo:header("title", "Combo")
	self.menu.combo:menu("ranged", "Ranged")
	self.menu.combo.ranged:boolean("useQ", "Use Q", true)
	self.menu.combo.ranged:boolean("useW", "Use W", true)
	self.menu.combo.ranged:boolean("useE", "Use E", true)
	self.menu.combo:menu("melee", "Melee")
	self.menu.combo.melee:boolean("useQ", "Use Q", true)
	self.menu.combo.melee:boolean("useW", "Use W", true)
	self.menu.combo.melee:boolean("useE", "Use E", true)
	self.menu.combo:boolean("EtoKill", "Use Melee E to Kill", false)
	self.menu.combo:boolean("useR", "Use R", true)
	self.menu.combo:boolean("chase", "Use R to Chase Target", false)

	self.menu.harass:header("title", "Harass")
	self.menu.harass:boolean("useQ", "Use Q", true)
	self.menu.harass:boolean("useW", "Use W", true)
	self.menu.harass:boolean("useE", "Use E", true)
  self.menu.harass:slider("mana", "Mana Limit %", 40, 10, 100, 5)
  
	self.menu.farm:header("title", "Farm/Jungle")
	self.menu.farm:menu("ranged", "Ranged")
	self.menu.farm.ranged:boolean("useQ", "Use Q", true)
	self.menu.farm.ranged:boolean("useW", "Use W", true)
	self.menu.farm:menu("melee", "Melee")
	self.menu.farm.melee:boolean("useQ", "Use Q", true)
	self.menu.farm.melee:boolean("useW", "Use W", true)
	self.menu.farm.melee:boolean("useE", "Use E", true)
	self.menu.farm:boolean("autoR", "Auto Player", true)
	self.menu.farm:slider("mana", "Mana for Player", 40, 10, 100, 5)

	self.menu.misc:header("title", "Misc")
	self.menu.misc:boolean("autoW", "Melee -> Auto W after Q", true)
	self.menu.misc:boolean("autoE", "Range -> Auto E after Q", true)
	self.menu.misc:boolean("killsteal", "KillSteal with EQ or Q", true)
	self.menu.misc:boolean("gapcloser", "Use E Anti-Gapcloser", true)
	self.menu.misc:boolean("interrupt", "Use E to Interrupt", true)
	self.menu.misc:menu("interruptmenu", "Interrupt Settings")
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
		local name = string.lower(enemy.charName)
		if enemy and self.interruptableSpells[name] then
			for v = 1, #self.interruptableSpells[name] do
				local spell = self.interruptableSpells[name][v]
				self.menu.misc.interruptmenu:boolean(string.format(enemy.charName .. spell.menuslot), "Interrupt " .. enemy.charName .. " " .. spell.menuslot, true)
	    end
		end
	end

	self.menu.draws:header("title", "Display")
	self.menu.draws:boolean("ready", "Draw Only Ready Spells", false)
	self.menu.draws:menu("ranged", "Ranged")
	self.menu.draws.ranged:boolean("drawEQ", "Draw EQ Range", true)
	self.menu.draws.ranged:boolean("drawQ", "Draw Q Range", true)
	self.menu.draws.ranged:boolean("drawE", "Draw E Range", false)
	self.menu.draws:menu("melee", "Melee")
	self.menu.draws.melee:boolean("drawQ", "Draw Q Range", true)
	self.menu.draws.melee:boolean("drawW", "Draw W Range", false)
	self.menu.draws.melee:boolean("drawE", "Draw E Range", false)
	self.CDTracker = {
		["Ranged"] = {
			[0] = { CD = player:spellSlot(0).level < 1 and 8 or player:spellSlot(0).cooldown, CDT = 0, T = 0, ready = false, name = "JayceShockBlast" },
			[1] = { CD = player:spellSlot(1).level < 1 and 13 or (player:spellSlot(1).cooldown + 4), CDT = 0, T = 0, ready = false, name = "JayceHyperCharge" },
			[2] = { CD = player:spellSlot(2).level < 1 and 16 or player:spellSlot(2).cooldown, CDT = 0, T = 0, ready = false, name = "JayceAccelerationGate" }
		},
		["Melee"] = {
			[0] = { CD = player:spellSlot(0).level < 1 and 16 or player:spellSlot(0).cooldown, CDT = 0, T = 0, ready = false, name = "JayceToTheSkies" },
			[1] = { CD = player:spellSlot(1).level < 1 and 10 or player:spellSlot(1).cooldown, CDT = 0, T = 0, ready = false, name = "JayceStaticField" },
			[2] = { CD = player:spellSlot(2).level < 1 and 20 or player:spellSlot(2).cooldown, CDT = 0, T = 0, ready = false, name = "JayceThunderingBlow" }
		}
	}

	self.QR = {
		slot = player:spellSlot(0),
		range = 1070,
		pred = { width = 75, delay = 0.25, speed = 1200, boundingRadiusMod = 1, collision = { hero = false, minion = true } }
	}
	self.EQ = {
		range = 1470,
		manacost = player:spellSlot(0).level > 0 and (({ 55, 60, 65, 70, 75, 80 })[player:spellSlot(0).level] + 50) or 105,
		pred = { width = 100, delay = 0.35, speed = 1890, boundingRadiusMod = 1, collision = { hero = false, minion = true } }
	}
	self.WR = {
		range = 500,
		slot = player:spellSlot(1)
	}
	self.ER = {
		slot = player:spellSlot(2),
		range = 650,
		pred = { delay = 0.1, radius = 120, speed = math.huge, boundingRadiusMod = 0 }
	}
	self.QM = {
		slot = player:spellSlot(0),
		range = 600
	}
	self.WM = {
		slot = player:spellSlot(1),
		range = 300
	}
	self.EM = {
		slot = player:spellSlot(2),
		range = 265
	}
	self.R = {
		slot = player:spellSlot(3)
	}

  orb.combat.register_f_pre_tick(function() self:OnTick() end)
	cb.add(cb.spell, function(spell) self:OnProcessSpell(spell) end)
	cb.add(cb.draw, function() self:OnDraw() end)

end

local function isMelee()
	return player:spellSlot(0).name ~= "JayceShockBlast"
end

function IntJayceee:Cooldowns()
	for i = 0, 2, 1 do
		if player:spellSlot(i).level > 0 then
			-- get last cast time + cooldown and subtract by osclock, if negative, its ready
			self.CDTracker.Ranged[i].T = self.CDTracker.Ranged[i].CDT + self.CDTracker.Ranged[i].CD - game.time
			self.CDTracker.Melee[i].T = self.CDTracker.Melee[i].CDT + self.CDTracker.Melee[i].CD - game.time
			--check Ranged if time negative then spell ready
			if self.CDTracker.Ranged[i].T <= 0 then
				self.CDTracker.Ranged[i].ready = true
				self.CDTracker.Ranged[i].T = 0
			else
				self.CDTracker.Ranged[i].ready = false
			end
			--check melee if time negative then spell ready
			if self.CDTracker.Melee[i].T <= 0 then
				self.CDTracker.Melee[i].ready = true
				self.CDTracker.Melee[i].T = 0
			else
				self.CDTracker.Melee[i].ready = false
			end
		end
	end
end

function IntJayceee:farming()
	if common.GetPercentPar() > self.menu.farm.mana:get() then
		local minions = objManager.minions
    for i = 0, minions.size[TEAM_ENEMY] - 1 do
      local minion = minions[TEAM_ENEMY][i]
			if minion and not minion.isDead and minion.isVisible then
        local dist = player.path.serverPos:dist(minion.path.serverPos)
        if isMelee() then
          if self.menu.farm.melee.useQ:get() and self.QM.slot.state == 0 then
            if dist <= self.QM.range and dlib.GetSpellDamage(0, minion, 2) > minion.health then
              player:castSpell("obj", 0, minion)
            end
          end
          if self.menu.farm.melee.useW:get() and self.WM.slot.state == 0 then
            if dist <= self.WM.range then
              player:castSpell("self", 1)
            end
          end
          if self.menu.farm.melee.useE:get() and self.EM.slot.state == 0 then
            if dist <= self.EM.range then
              local damage = dlib.GetSpellDamage(2, minion)
              local damageCheck = ({ 200, 300, 400, 500, 600, 700 })[self.EM.slot.level]
              if damage > damageCheck then
                damage = damageCheck
              end
              if damage > minion.health then
                player:castSpell("obj", 2, minion)
              end
            end
          end
          if self.menu.farm.autoR:get() and self.R.slot.state == 0 and self.QM.slot.state ~= 0 and self.WM.slot.state ~= 0 then
            player:castSpell("self", 3)
          end
        end
        if not isMelee() then
          if self.menu.farm.ranged.useQ:get() and self.QR.slot.state == 0 then
            if dist <= self.QR.range then
              player:castSpell("pos", 0, minion.pos)
            end
          end
          if self.menu.farm.ranged.useW:get() and self.WR.slot.state == 0 then
            if dist <= self.WR.range then
              player:castSpell("self", 1)
            end
          end
          if self.menu.farm.autoR:get() and self.R.slot.state == 0 and self.QR.slot.state ~= 0 and self.WR.slot.state ~= 0 then
            player:castSpell("self", 3)
          end
        end
      end
		end
	end
end

function IntJayceee:jungling()
	if common.GetPercentPar() > self.menu.farm.mana:get() then
		local minions = objManager.minions
    for i = 0, minions.size[TEAM_NEUTRAL] - 1 do
      local minion = minions[TEAM_NEUTRAL][i]
			if minion and not minion.isDead and minion.isVisible then
        local dist = player.path.serverPos:dist(minion.path.serverPos)
        if isMelee() then
          if self.menu.farm.melee.useQ:get() and self.QM.slot.state == 0 then
            if dist <= self.QM.range then
              player:castSpell("obj", 0, minion)
            end
          end
          if self.menu.farm.melee.useW:get() and self.WM.slot.state == 0 then
            if dist <= self.WM.range then
              player:castSpell("self", 1)
            end
          end
          if self.menu.farm.melee.useE:get() and self.EM.slot.state == 0 then
            if dist <= self.EM.range then
              local damage = dlib.GetSpellDamage(2, minion)
              local damageCheck = ({ 200, 300, 400, 500, 600, 700 })[self.EM.slot.level]
              if damage > damageCheck then
                damage = damageCheck
              end
              if damage > minion.health then
                player:castSpell("obj", 2, minion)
              end
            end
          end
          if self.menu.farm.autoR:get() and self.R.slot.state == 0 and self.QM.slot.state ~= 0 and self.WM.slot.state ~= 0 then
            player:castSpell("self", 3)
          end
        end
        if not isMelee() then
          if self.menu.farm.ranged.useQ:get() and self.QR.slot.state == 0 then
            if dist <= self.QR.range then
              player:castSpell("pos", 0, minion.pos)
            end
          end
          if self.menu.farm.ranged.useW:get() and self.WR.slot.state == 0 then
            if dist <= self.WR.range then
              player:castSpell("self", 1)
            end
          end
          if self.menu.farm.autoR:get() and self.R.slot.state == 0 and self.QR.slot.state ~= 0 and self.WR.slot.state ~= 0 then
            player:castSpell("self", 3)
          end
        end
      end
		end
	end
end

function IntJayceee:EQCombo(target)
  local seg = mainP.linear.get_prediction(self.EQ.pred, target)
  if seg and seg.startPos:dist(seg.endPos) <= self.EQ.range then
    local col = mainP.collision.get_prediction(self.EQ.pred, seg, target)
    if not col then
      local pred_pos = vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y)
      local extRange = 200
      if player.path.serverPos:dist(pred_pos) <= extRange then
        extRange = player.path.serverPos:dist(pred_pos) * 0.65
      end
      local gatepos = player.pos + (pred_pos - player.pos):norm() * extRange
      player:castSpell("pos", 2, vec3(gatepos))
      player:castSpell("pos", 0, pred_pos)
    end
  end
end

function IntJayceee:Harass()
  if self.menu.harass.useQ:get() or self.menu.harass.useW:get() then
    if not isMelee() and common.GetPercentPar() > self.menu.harass.mana:get() then
      local target = GetTarget()
      if target and common.IsValidTarget(target) then
        if self.menu.harass.useQ:get() and self.menu.harass.useE:get() then
          if self.QR.slot.state == 0 and self.ER.slot.state == 0 and player.par >= self.EQ.manacost then
            self:EQCombo(target)
          end
        end
        if self.menu.harass.useQ:get() and self.QR.slot.state == 0 and player.par >= (self.EQ.manacost - 50) then
          if not self.menu.harass.useE:get() or self.ER.slot.state ~= 0 then
            local seg = mainP.linear.get_prediction(self.QR.pred, target)
            if seg and seg.startPos:dist(seg.endPos) <= self.QR.range then
              local col = mainP.collision.get_prediction(self.QR.pred, seg, target)
              if not col then
                player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
              end
            end
          end
        end
        if self.menu.harass.useW:get() and self.WR.slot.state == 0 then
          local dist = player.path.serverPos:dist(target.path.serverPos)
          if dist <= 500 then
            player:castSpell("self", 1)
          end
        end
      end
    end
  end
end

function IntJayceee:Killsteal()
	if not self.menu.misc.killsteal:get() or self.QR.slot.level <= 0 or self.ER.slot.level <= 0 then return end
	local EQBaseDamage = ({ 98, 168, 238, 308, 378, 448 })[self.QR.slot.level] + 1.68 * common.GetBonusAD()
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if enemy and common.IsValidTarget(enemy) then
      local dist = player.path.serverPos:dist(enemy.path.serverPos)
      if dist <= self.EQ.range then
        local QDamage = dlib.GetSpellDamage(0, enemy)
        if self.CDTracker.Ranged[0].ready == true and self.CDTracker.Ranged[2].ready == true and player.par >= self.EQ.manacost then
          local EQDamage = common.CalculatePhysicalDamage(enemy, EQBaseDamage)
          if EQDamage > common.GetShieldedHealth("AD", enemy) then
            if isMelee and self.R.slot.state == 0 then
              player:castSpell("self", 3)
            end
            if not isMelee() then
              self:EQCombo(enemy)
            end
          end
        end
        if dist <= self.QR.range and self.CDTracker.Ranged[2].ready == false and self.CDTracker.Ranged[0].ready == true then
          if QDamage > common.GetShieldedHealth("AD", enemy) and player.par >= (self.EQ.manacost - 50) then
            if isMelee and self.R.slot.state == 0 then
              player:castSpell("self", 3)
            end
            if not isMelee() and self.QR.slot.state == 0 then
              local seg = mainP.linear.get_prediction(self.QR.pred, enemy)
              if seg and seg.startPos:dist(seg.endPos) <= (self.QR.range + enemy.boundingRadius) then
                local col = mainP.collision.get_prediction(self.QR.pred, seg, enemy)
                if not col then
                  player:castSpell("pos", 0, vec3(seg.endPos.x, enemy.y, seg.endPos.y))
                end
              end
            end
          end
        end
      end
    end
	end
end

function IntJayceee:EQtoMouse()
	player:move(game.mousePos)
	if isMelee() and self.R.slot.state == 0 and self.CDTracker.Ranged[0].ready == true and self.CDTracker.Ranged[2].ready == true then
		player:castSpell("self", 3)
	end
	if not isMelee() and self.QR.slot.state == 0 and self.ER.slot.state == 0 and player.par >= self.EQ.manacost then
		local gatepos = player.pos + (game.mousePos - player.pos):norm() * 200
		player:castSpell("pos", 2, vec3(gatepos))
		player:castSpell("pos", 0, game.mousePos)
	end
end

function IntJayceee:Combo()
	local target = GetTarget()
	if orb.combat.target then
		target = orb.combat.target
	end
  if target and common.IsValidTarget(target) then
    local dist = player.path.serverPos:dist(target.path.serverPos)
    if isMelee() then
      if self.menu.combo.melee.useQ:get() and self.QM.slot.state == 0 then
        if dist <= self.QM.range then
          player:castSpell("obj", 0, target)
        end
      end
      if self.menu.combo.melee.useW:get() and self.WM.slot.state == 0 then
        if dist <= self.WM.range then
          player:castSpell("self", 1)
        end
      end
      if self.menu.combo.melee.useE:get() and self.EM.slot.state == 0 then
        if dist <= self.EM.range then
          local EDamage = dlib.GetSpellDamage(2, target)
          local shieldedHealth = common.GetShieldedHealth("AP", target)
          if self.menu.combo.EtoKill:get() and shieldedHealth < EDamage then
            player:castSpell("obj", 2, target)
          elseif not self.menu.combo.EtoKill:get() and ((EDamage > shieldedHealth) or (self.R.slot.state == 0 and self.QM.slot.level > 0 and self.CDTracker.Ranged[0].ready == true)) then
            player:castSpell("obj", 2, target)
          end
        end
      end
    end
    if not isMelee() then
      if self.menu.combo.ranged.useQ:get() and self.menu.combo.ranged.useE:get() then
        if self.QR.slot.state == 0 and self.ER.slot.state == 0 and player.par >= self.EQ.manacost then
          self:EQCombo(target)
        end
      end
      if self.menu.combo.ranged.useQ:get() and self.QR.slot.state == 0 and player.par >= (self.EQ.manacost - 50) then
        if not self.menu.combo.ranged.useE:get() or (self.ER.slot.state ~= 0) or (dlib.GetSpellDamage(0, target) > common.GetShieldedHealth("AD", target)) or (player.par < self.EQ.manacost and self.menu.combo.ranged.useE:get()) then
          local seg = mainP.linear.get_prediction(self.QR.pred, target)
          if seg and seg.startPos:dist(seg.endPos) <= (self.QR.range + target.boundingRadius) then
            local col = mainP.collision.get_prediction(self.QR.pred, seg, target)
            if not col then
              player:castSpell("pos", 0, vec3(seg.endPos.x, target.y, seg.endPos.y))
            end
          end
        end
      end
      if self.menu.combo.ranged.useW:get() and self.WR.slot.state == 0 then
        if dist <= (self.WR.range + target.boundingRadius) then
          player:castSpell("self", 1)
        end
      end
    end
    if self.menu.combo.useR:get() and self.R.slot.state == 0 then
      if isMelee() then
        if (dist > self.QM.range + 50) or (self.CDTracker.Ranged[0].ready == true and self.CDTracker.Ranged[1].ready == true and self.CDTracker.Ranged[2].ready == true) then
          player:castSpell("self", 3)
        end
        if (self.QM.slot.state ~= 0 and self.WM.slot.state ~= 0 and (self.EM.slot.state ~= 0 or (self.EM.slot.state == 0 and self.menu.combo.EtoKill:get()) and dist > self.EM.range)) then
          player:castSpell("self", 3)
        end
      end
      if not isMelee() then
        if (self.QR.slot.state ~= 0 or not self.menu.combo.ranged.useQ:get()) and (self.WR.slot.state ~= 0 or not self.menu.combo.ranged.useW:get()) and self.R.slot.state == 0 and dist <= self.QM.range then
          player:castSpell("self", 3)
        end
        if self.menu.combo.chase:get() and dist > (self.QM.range + 50) and dist <= 750 and self.R.slot.state == 0 and self.WR.slot.state == 0 and self.CDTracker.Melee[0].ready == true and self.QR.slot.state ~= 0 then
          player:castSpell("self", 1)
          player:castSpell("self", 3)
        end
      end
    end
  end
end

function IntJayceee:AntiGapcloser()
	if self.menu.misc.gapcloser:get() and self.CDTracker.Melee[2].ready == true then
    for i = 0, objManager.enemies_n - 1 do
      local enemy = objManager.enemies[i]
      if enemy and not enemy.isDead and enemy.isVisible and enemy.isTargetable and enemy.path.isActive and enemy.path.isDashing then
        local v2 = mainP.core.project(player.path.serverPos2D, enemy.path, 0.1 + network.latency, math.huge, enemy.path.dashSpeed)
        if v2 and v2:dist(player.path.serverPos2D) <= self.EM.range then
          if not isMelee() and self.R.slot.state == 0 then
            player:castSpell("self", 3)
            orb.core.set_server_pause()
            player:castSpell("obj", 2, enemy)
          elseif isMelee() then
            player:castSpell("obj", 2, enemy)
          end
        end
      end
		end
	end
end

function IntJayceee:Flee()
  player:move(game.mousePos)
	if isMelee() and self.R.slot.state == 0 and self.CDTracker.Ranged[2].ready == true then
		player:castSpell("self", 3)
	end
	if not isMelee() and self.QR.slot.state == 0 and self.ER.slot.state == 0 then
		local gatepos = player.pos + (game.mousePos - player.pos):norm() * 300
    player:castSpell("pos", 2, vec3(gatepos))
  end
end 

function IntJayceee:OnTick()
	if player.isDead then return end
	self:Cooldowns()
  self:AntiGapcloser()
  if self.menu.usezFlee:get() then 
    self:Flee()
  elseif self.menu.useEQ:get() then
		self:EQtoMouse()
	elseif orb.combat.is_active() then
		self:Combo()
	elseif orb.menu.hybrid:get() then
		self:Harass()
	elseif orb.menu.lane_clear:get() then
		self:farming()
		self:jungling()
	end
	self:Killsteal()
end

function IntJayceee:OnProcessSpell(spell)
  local owner = spell.owner
	if owner.ptr == player.ptr and not spell.isBasicAttack then
		for i = 0, 2, 1 do
			if spell.name == self.CDTracker.Ranged[i].name then
				self.CDTracker.Ranged[i].CDT = game.time
			elseif spell.name == self.CDTracker.Melee[i].name then
				self.CDTracker.Melee[i].CDT = game.time
			end
		end
		if self.menu.misc.autoE:get() and spell.name == "JayceShockBlast" then
			if not isMelee() and self.ER.slot.state == 0 then
				local gatepos = spell.startPos + (spell.endPos - spell.startPos):norm() * 300
				if gatepos and not isMelee() and self.ER.slot.state == 0 then
					common.DelayAction(function(pos) player:castSpell("pos", 2, pos) end, 0.2, {gatepos})
				end
			end
		end
		if self.menu.misc.autoW:get() and spell.name == "JayceToTheSkies" then
			if isMelee() and self.WM.slot.state == 0 then
				player:castSpell("self", 1)
			end
		end
	end
	if owner.ptr == player.ptr and spell.isBasicAttack and spell.target.team ~= TEAM_ALLY then
		if player.attackSpeedMod >= 2.49000 and countW > 0 then
			holdcheckW = true
			countW = countW - 1
		elseif holdcheckW then
			orb.core.set_pause_move(0)
			orb.core.set_pause_attack(1)
			countW = 2
			holdcheckW = false
		end
	end
	if owner.ptr ~= player.ptr and self.menu.misc.interrupt:get() and self.CDTracker.Melee[2].ready == true then
		if owner.type == TYPE_HERO and owner.team == TEAM_ENEMY then
			local enemyName = string.lower(owner.charName)
			if self.interruptableSpells[enemyName] then
				for i = 1, #self.interruptableSpells[enemyName] do
					local spellCheck = self.interruptableSpells[enemyName][i]
					if self.menu.misc.interruptmenu[owner.charName .. spellCheck.menuslot]:get() and string.lower(spell.name) == spellCheck.spellname then
            local dist = player.path.serverPos:dist(owner.path.serverPos)
						if dist <= self.EM.range and common.IsValidTarget(owner) and self.CDTracker.Melee[2].ready == true then
							if not isMelee() and self.R.slot.state == 0 then
								player:castSpell("self", 3)
                orb.core.set_server_pause()
								player:castSpell("obj", 2, owner)
							elseif isMelee() then
								player:castSpell("obj", 2, owner)
							end
						end
					end
				end
			end
		end
	end
end

function IntJayceee:OnDraw()
  if not player.isDead and player.isOnScreen then
    if self.menu.draws.ready:get() then
      if not isMelee() then
        if self.menu.draws.ranged.drawEQ:get() and self.QR.slot.state == 0 and self.ER.slot.state == 0 then
          graphics.draw_circle(player.pos, self.EQ.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
        if self.menu.draws.ranged.drawQ:get() and self.QR.slot.state == 0 then
          graphics.draw_circle(player.pos, self.QR.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
        if self.menu.draws.ranged.drawE:get() and self.ER.slot.state == 0 then
          graphics.draw_circle(player.pos, self.ER.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
      else
        if self.menu.draws.melee.drawQ:get() and self.QM.slot.state == 0 then
          graphics.draw_circle(player.pos, self.QM.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
        if self.menu.draws.melee.drawW:get() and self.WM.slot.state == 0 then
          graphics.draw_circle(player.pos, self.WM.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
        if self.menu.draws.melee.drawE:get() and self.EM.slot.state == 0 then
          graphics.draw_circle(player.pos, self.EM.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
      end
    else
      if not isMelee() then
        if self.menu.draws.ranged.drawEQ:get() then
          graphics.draw_circle(player.pos, self.EQ.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
        if self.menu.draws.ranged.drawQ:get() then
          graphics.draw_circle(player.pos, self.QR.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
        if self.menu.draws.ranged.drawE:get() then
          graphics.draw_circle(player.pos, self.ER.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
      else
        if self.menu.draws.melee.drawQ:get() then
          graphics.draw_circle(player.pos, self.QM.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
        if self.menu.draws.melee.drawW:get() then
          graphics.draw_circle(player.pos, self.WM.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
        if self.menu.draws.melee.drawE:get() then
          graphics.draw_circle(player.pos, self.EM.range, 2,  graphics.argb(255, 255, 255, 255), 40)
        end
      end
    end
  end
end

if player.charName == "Jayce" then
	IntJayceee()
end