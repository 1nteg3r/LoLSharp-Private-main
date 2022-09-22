local orb = module.internal("orb");
local gongPred = module.internal("pred")
local common = module.load(header.id, "common");
local TS = module.internal("TS");
----------------------------------------------------------------
-- Draven Main Script
----------------------------------------------------------------

--spells listed are channels with longer durations than Dravens E delay. Example is Darius Ult, the channel is 0.25 so by the time I
--try to cast E to intterupt it, it will have already finished the cast >.< (however it is possible to interrupt with other spells)
local interruptableSpells = {
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
	}, --IsValidTarget will prevent from casting @ karthus while he's zombie
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
	--excluding Orn's Forge Channel since it can be cancelled just by attacking him
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

-- menu initialization
local menu = menu("MarksmanAIODraven", "Marksman - Draven")
menu:header("comewewebo", "Core")
menu:menu("combo", "Combo")
menu:menu("axe", "Axe")
menu:menu("drawing", "Display")
menu:menu("misc", "Misc")

--combo submenu options
menu.combo:boolean("comboQ", "Use Q", true)
menu.combo:boolean("comboW", "Use W", true)
menu.combo:slider("wmana", "Don't Use W if Mana % < ", 35, 1, 100, 1)
menu.combo:boolean("comboE", "Use E", true)
menu.combo:boolean("comboR", "Use R", true)
menu.combo:slider("Rrange", "Max. R Range", 5000, 1000, 10000, 500)
menu.combo:slider("R1range", "Min. R Range", 100, 1, 550, 1)
menu.combo:keybind('semir', 'Semi-R', 'G', nil)
menu.combo:boolean("slowpred", "^ Slow Prediction R?", true)

--axe submenu options
menu.axe:dropdown("catchMode", "Catch Axe's", 2, {"Combat", "Always", "Never"})
menu.axe:slider("catchRange", "Catch Range", 630, 100, 3000, 10)
menu.axe:slider("max", "Max Axe's to Clear", 2, 1, 7, 1)
menu.axe:boolean("turret", "Dont Catch Axe's Under Turret", true)

--draw submenu options
menu.drawing:boolean("drawAxe", "Draw Axe Drop Position", true)
menu.drawing:boolean("drawAxeRange", "Draw Axe Catch Range", true)

--misc submenu options
menu.misc:boolean("QNotCombo", "Use Q During Farm/Harass", true)
menu.misc:boolean("wifslowed", "Use W if slowed", true)
menu.misc:boolean("gapcloser", "Use E on Gapclosers", true)
menu.misc:boolean("interrupt", "Use E to Interrupt Casts", true)
menu.misc:menu("interruptmenu", "Interrupt Settings")
menu.misc.interruptmenu:header("lol", "Interrupt Settings")
for i = 0, objManager.enemies_n - 1 do
  	local enemy = objManager.enemies[i]
	local name = string.lower(enemy.charName)
	if enemy and interruptableSpells[name] then
		for v = 1, #interruptableSpells[name] do
			local spell = interruptableSpells[name][v]
			menu.misc.interruptmenu:boolean(string.format(enemy.charName .. spell.menuslot), "Interrupt " .. enemy.charName .. " " .. spell.menuslot, true)
    	end
	end
end


local function TargetR(res, obj, dist)
    if dist <= 1500 then 
    	res.obj = obj
    	return true
    end
end

local GetTarget = function()
	return TS.get_result(TargetR).obj
end

local EPrediction = { -- range is 1050
  width = 130,
  delay = 0.25,
  speed = 1400,
  boundingRadiusMod = 0
}

local RPrediction = { -- range is global
  width = 160,
  delay = 0.4,
  speed = 2000,
  boundingRadiusMod = 1
}

local trace_filter = function(seg, obj)
    if gongPred.trace.linear.hardlock(RPrediction, seg, obj) then
	    return true
	end
	if gongPred.trace.linear.hardlockmove(RPrediction, seg, obj) then
	    return true
	end
	if gongPred.trace.newpath(obj, 0.033, 0.500) then
	    return true
	end
end

local axesTable = {}
local myHeroBuffs = {}
local Qpause = 0
local AxeCount = { }
-- Returns distance*distance from @p1 to @p2
local function GetDistanceSqr(p1, p2)
    if (not p1 or not p2) then
        return math.huge
    end
    local dx = p1.x - p2.x
    local dz = (p1.z or p1.y) - (p2.z or p2.y)
    return dx*dx + dz*dz
end

-- Returns distance from @p1 to @p2
local function GetDistance(p1, p2)
    return math.sqrt(GetDistanceSqr(p1, p2))
end

local function set_server_pause()
	Qpause = os.clock() + network.latency + 0.25
end

local function is_Q_paused()
	return Qpause > os.clock()
end

local function size()
    local count = 0;
    for _, objs in pairs(axesTable) do
        if objs then
            count = count + 1
        end
	end
	return count
end

local function CountQs()
	for i, buff in pairs(player.buff) do
		if buff and buff.valid and buff.name == "DravenSpinningAttack" then
			return buff.stacks + size()
		end
	end
	return size()
end

local function FuryCount()
	for i, buff in pairs(player.buff) do
		if buff and buff.valid and string.lower(buff.name) == "dravenfurybuff" then
			return buff.stacks
		end
	end
	return 0
end

local function FindKillableR()
	-- draven R is 175/275/375 + 110% Bonus AD on first target hit then drops immensely, so will multiply by 0.9 on calc to suffice and ensure kill
	local damage = (player:spellSlot(3).level * 100 + 75) + (common.GetBonusAD() * 1.1)
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) then
      local dist = player.path.serverPos:dist(enemy.path.serverPos)
      if dist <= menu.combo.Rrange:get() and (dist > 600 or #common.GetEnemyHeroesInRange(1100) > 2) then
        if (common.CalculatePhysicalDamage(enemy, damage) * 0.9) > common.GetShieldedHealth("AD", enemy) then
          return enemy
        end
      end
		end
	end
	return nil
end


local function InEnemyTowerRange(object)
	if not object then return true end
	for i= 1, objManager.turrets.size[TEAM_ENEMY]-1 do
		local tower = objManager.turrets[TEAM_ENEMY][i]
		if tower and not tower.isDead and tower.health > 0 then
			if tower and GetDistance(tower.pos, object.pos) <= 915 then
				return true
			end
		end
	end
	return false
end

local function BestAxe()
	local best = nil
	local distance = 10000
	for _, axe in pairs(axesTable) do
		if axe then
			local axePos = axe.pos
			if GetDistance(player, axePos) < menu.axe.catchRange:get() and GetDistance(axePos, player) < distance then
				best = axe
				distance = GetDistance(axePos, player)
			end
		end
	end
	return best
end

local function GoFetch()
	local method = menu.axe.catchMode:get()
	if (method == 1 and orb.combat.is_active()) or (method == 2) then
		local axe = BestAxe()
		if axe and GetDistance(axe.pos, player) > 85 then
			if menu.axe.turret:get() then
				if not InEnemyTowerRange(axe) and orb.core.can_action() and not orb.core.can_attack() then
					player:move(axe.pos)
				end
			elseif orb.core.can_action() and not orb.core.can_attack() then
				player:move(axe.pos)
			end
		end
	end
end

local function Combo()
	local target = GetTarget();
	if target then
    if GetDistance(target, player) <= 1200 then
      if menu.combo.comboQ:get() and player:spellSlot(0).state == 0 and common.IsValidTarget(target) and orb.core.can_attack() and CountQs() < menu.axe.max:get() then
        player:castSpell("self", 0)
      end
      if menu.combo.comboW:get() and player:spellSlot(1).state == 0 and common.IsValidTarget(target) and FuryCount() < 1 and common.GetPercentMana() > (menu.combo.wmana:get()) and player.manaCost3 then
        player:castSpell("self", 1)
      end
    end
		if menu.combo.comboE:get() and player:spellSlot(2).state == 0 then
      local c_target = orb.combat.target
			if c_target and common.IsValidTarget(c_target) and GetDistance(c_target, player) <= common.GetAARange(c_target) then
				target = c_target
			end
			local seg = gongPred.linear.get_prediction(EPrediction, target)
			if seg and seg.startPos:distSqr(seg.endPos) < (950 * 950) then
        player:castSpell("pos", 2, vec3(seg.endPos.x, target.y, seg.endPos.y))
			end
		end
	end
  if menu.combo.comboR:get() and player:spellSlot(3).state == 0 then
    local killem = FindKillableR()
    if killem and common.IsValidTarget(killem) then
			local seg2 = gongPred.linear.get_prediction(RPrediction, killem)
			if seg2 and seg2.startPos:dist(seg2.endPos) < menu.combo.Rrange:get() then
				if menu.combo.slowpred:get() then
					if trace_filter(seg2, killem) then
						player:castSpell("pos", 3, vec3(seg2.endPos.x, killem.y, seg2.endPos.y))
					end
				else 
					player:castSpell("pos", 3, vec3(seg2.endPos.x, killem.y, seg2.endPos.y))
				end
			end
		end
	end
end

local function UseQOutsideCombo()
	if menu.misc.QNotCombo:get() and player:spellSlot(0).state == 0 and orb.core.can_attack() and not is_Q_paused() and CountQs() < 1 then
		player:castSpell("self", 0)
	end
end

local function AntiGapcloser()
	if menu.misc.gapcloser:get() and player:spellSlot(2).state == 0 then
    for i = 0, objManager.enemies_n - 1 do
      local enemy = objManager.enemies[i]
      if enemy and common.IsValidTarget(enemy) and enemy.path.isActive and enemy.path.isDashing and not enemy.buff["rocketgrab"] then
        local v2 = gongPred.core.project(player.path.serverPos2D, enemy.path, 0.25 + network.latency, 1400, enemy.path.dashSpeed)
        if v2 and v2:dist(player.path.serverPos2D) <= 260 then
          player:castSpell("pos", 2, vec3(v2.x, enemy.y, v2.y))
        end
      end
		end
	end
end

local function OnInterruptable(unit, spell)
	if menu.misc.interrupt:get() and player:spellSlot(2).state == 0 then
		if spell.owner.team ~= TEAM_ALLY and menu.misc.interruptmenu[spell.name]:get() then
			if common.IsValidTarget(unit) and GetDistance(unit, player) < 950 then
				player:castSpell('pos', 2, vec3(unit.x, game.mousePos.y, unit.z))
			end 
		end
	end
end

local function OnUpdateBuff()
	for i, buff in pairs(player.buff) do 
		if buff and buff.valid then 
			print(buff.name)
		end 
	end
end

local function AutoInterrupt(spell)
	if menu.misc.interrupt:get() and player:spellSlot(2).state == 0 then
    local owner = spell.owner
		if owner.type == TYPE_HERO and owner.team == TEAM_ENEMY then
			local enemyName = string.lower(owner.charName)
			if interruptableSpells[enemyName] then
				for i = 1, #interruptableSpells[enemyName] do
					local spellCheck = interruptableSpells[enemyName][i]
					if menu.misc.interruptmenu[owner.charName .. spellCheck.menuslot]:get() and string.lower(spell.name) == spellCheck.spellname then
						if common.IsValidTarget(enemy) and common.GetDistance(owner, player) < 950 then
							player:castSpell('pos', 2, vec3(owner.x, game.mousePos.y, owner.z))
						end
					end
				end
			end
		end
	end
end

local function ManualR()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) then 
			local seg2 = gongPred.linear.get_prediction(RPrediction, enemy)
			if seg2 and seg2.startPos:dist(seg2.endPos) < menu.combo.Rrange:get() then
				if menu.combo.slowpred:get() then
					if trace_filter(seg2, enemy) then
						player:castSpell("pos", 3, vec3(seg2.endPos.x, enemy.y, seg2.endPos.y))
					end
				else 
					player:castSpell("pos", 3, vec3(seg2.endPos.x, enemy.y, seg2.endPos.y))
				end
			end
		end 
	end
end 

local function OnEachTick()
	if player.isDead then return end

	GoFetch()

	if player:spellSlot(1).state == 0 and menu.misc.wifslowed:get() and player.buff[10] then
		player:castSpell("self", 1)
	end

	if orb.combat.is_active() then
		Combo()
	elseif orb.menu.lane_clear:get() or orb.menu.hybrid:get() or orb.menu.last_hit:get() then
		UseQOutsideCombo()
	elseif menu.combo.semir:get() then 
		player:move(mousePos)
		ManualR()
	end

	AntiGapcloser()
	--OnUpdateBuff();
	--OnRemoveBuff();
end
orb.combat.register_f_pre_tick(OnEachTick)

local function Drawing()
	if menu.drawing.drawAxe:get() then
		for _, axe in pairs(axesTable) do
			if axe then
				local color = GetDistance(axe, player) <= 100 and graphics.argb(255, 255, 0, 0) or graphics.argb(255, 255, 255, 255) --255, 100, 255, 100
				graphics.draw_circle(axe.pos, 100, 1, color, 40)
			end
		end

		if BestAxe() then
			local axe = BestAxe()
			graphics.draw_line(player.pos, axe.pos, 1, graphics.argb(255, 255, 255, 0))
		end
	end

	if menu.drawing.drawAxeRange:get() then
		graphics.draw_circle(game.mousePos, menu.axe.catchRange:get(), 1, graphics.argb(255, 255, 255, 255), 40)
	end
end

local function OnAxeCreation(obj)
	if string.find(obj.name, "Draven") and string.find(obj.name, "reticle_self") then
		axesTable[obj.ptr] = obj
		set_server_pause()
	end
end

local function OnAxeDeletion(obj)
	if obj then
		axesTable[obj.ptr] = nil
		set_server_pause()
	end
end

cb.add(cb.draw, Drawing)
cb.add(cb.create_particle, OnAxeCreation)
cb.add(cb.delete_particle, OnAxeDeletion)
cb.add(cb.spell, AutoInterrupt)