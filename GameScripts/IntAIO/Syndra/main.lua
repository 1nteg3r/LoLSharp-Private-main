local function class()
    return setmetatable(
        {},
        {
            __call = function(self, ...)
                local result = setmetatable({}, {__index = self})
                result:__init(...)

                return result
            end
        }
    )
end

local Syndra = class()

local Vector
local gpred = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")

local common = module.load(header.id, "Library/common")
local GeometryLib = module.load(header.id, "Geometry/GeometryLib")
local LineSegment = GeometryLib.LineSegment
local Vector 

local myHero = player


local byte, match, floor, min, max, abs, rad, huge, clock, insert, remove =
    string.byte,
    string.match,
    math.floor,
    math.min,
    math.max,
    math.abs,
    math.rad,
    math.huge,
    os.clock,
    table.insert,
    table.remove

local function GetDistanceSqr(p1, p2)
    p2 = p2 or myHero
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx * dx + dz * dz
end

function Syndra:__init()
    Vector = GeometryLib.Vector
    function Vector:angleBetweenFull(v1, v2)
        local p1, p2 = (-self + v1), (-self + v2)
        local theta = p1:polar() - p2:polar()
        if theta < 0 then
            theta = theta + 360
        end
        return theta
    end
    self.unitsInRange = {}
    self.enemyHeroes = common.GetEnemyHeroes()
    self.allyHeroes = common.GetAllyHeroes()
    self.spell = {
        q = {
            type = "circular",
            range = 800,
            rangeSqr = 800 * 800,
            delay = 0.65,
            radius = 210,
			boundingRadiusMod = 0,
            speed = huge
        },
        w = {
            type = "circular",
            range = 950,
            grabRangeSqr = 925 * 925,
            delay = 0.75,
            radius = 220,
            speed = huge,
			boundingRadiusMod = 0,
            heldInfo = nil,
            useHeroSource = true,
            blacklist = {}, -- for orbs
            blacklist2 = nil -- for champions
        },
        e = {
            type = "linear",
            speed = 1600,
            rangeSqr = 700 * 700,
            range = 700,
            delay = 0.25,
            width = 200,
            widthMax = 200,
            angle = 40,
            angle1 = 40,
			boundingRadiusMod = 0,
            angle2 = 60,
            blacklist = {},
            next = nil,
            collision = {
                ["wall"] = true,
                ["hero"] = false,
                ["minion"] = false
            }
        },
        qe = {
            pingPongSpeed = 2000,
            range = 1150,
            delay = 0.32,
            speed = 2000,
            width = 200,
			boundingRadiusMod = 1,
            collision = {
                ["wall"] = true,
                ["hero"] = false,
                ["minion"] = false
            }
        },
        r = {
            type = "targetted",
            speed = 2000,
            delay = 0,
            range = 2000,
            castRange = 675,
			boundingRadiusMod = 0,
            collision = {
                ["wall"] = true,
                ["hero"] = false,
                ["minion"] = false
            }
        }
    }
    self.myHeroPred = myHero.pos
	self.HeanderW_target = { }
    self.last = {
        q = nil,
        w = nil,
        e = nil,
        r = nil
    }
	self.ignite = nil
	if player:spellSlot(4).name == "SummonerDot" then
		self.ignite = 4
	elseif player:spellSlot(5).name == "SummonerDot" then
		self.ignite = 5
	else 
		self.ignite = nil 
	end 

    self.igniteDamage = nil
    self.wGrabList = {
        ["SRU_ChaosMinionSuper"] = true,
        ["SRU_OrderMinionSuper"] = true,
        ["HA_ChaosMinionSuper"] = true,
        ["HA_OrderMinionSuper"] = true,
        ["SRU_ChaosMinionRanged"] = true,
        ["SRU_OrderMinionRanged"] = true,
        ["HA_ChaosMinionRanged"] = true,
        ["HA_OrderMinionRanged"] = true,
        ["SRU_ChaosMinionMelee"] = true,
        ["SRU_OrderMinionMelee"] = true,
        ["HA_ChaosMinionMelee"] = true,
        ["HA_OrderMinionMelee"] = true,
        ["SRU_ChaosMinionSiege"] = true,
        ["SRU_OrderMinionSiege"] = true,
        ["HA_ChaosMinionSiege"] = true,
        ["HA_OrderMinionSiege"] = true,
        ["SRU_Krug"] = true,
        ["SRU_KrugMini"] = true,
        ["TestCubeRender"] = true,
        ["SRU_RazorbeakMini"] = true,
        ["SRU_Razorbeak"] = true,
        ["SRU_MurkwolfMini"] = true,
        ["SRU_Murkwolf"] = true,
        ["SRU_Gromp"] = true,
        ["Sru_Crab"] = true,
        ["SRU_Red"] = true,
        ["SRU_Blue"] = true,
        ["EliseSpiderling"] = true,
        ["HeimerTYellow"] = true,
        ["HeimerTBlue"] = true,
        ["MalzaharVoidling"] = true,
        ["ShacoBox"] = true,
        ["YorickGhoulMelee"] = true,
        ["YorickBigGhoul"] = true

    }

    self.interruptableSpells = {
        ["anivia"] = {
            {menuslot = "R", slot = 3, spellname = "glacialstorm", channelduration = 6}
        },
        ["caitlyn"] = {
            {menuslot = "R", slot = 3, spellname = "caitlynaceinthehole", channelduration = 1}
        },
        ["ezreal"] = {
            {menuslot = "R", slot = 3, spellname = "ezrealtrueshotbarrage", channelduration = 1}
        },
        ["fiddlesticks"] = {
            {menuslot = "W", slot = 1, spellname = "drain", channelduration = 5},
            {menuslot = "R", slot = 3, spellname = "crowstorm", channelduration = 1.5}
        },
        ["janna"] = {
            {menuslot = "R", slot = 3, spellname = "reapthewhirlwind", channelduration = 3}
        },
        ["karthus"] = {
            {menuslot = "R", slot = 3, spellname = "karthusfallenone", channelduration = 3}
        }, --common.IsValidTargetTarget will prevent from casting @ karthus while he's zombie
        ["katarina"] = {
            {menuslot = "R", slot = 3, spellname = "katarinar", channelduration = 2.5}
        },
        ["lucian"] = {
            {menuslot = "R", slot = 3, spellname = "lucianr", channelduration = 2}
        },
        ["lux"] = {
            {menuslot = "R", slot = 3, spellname = "luxmalicecannon", channelduration = 0.5}
        },
        ["malzahar"] = {
            {menuslot = "R", slot = 3, spellname = "malzaharr", channelduration = 2.5}
        },
        ["masteryi"] = {
            {menuslot = "W", slot = 1, spellname = "meditate", channelduration = 4}
        },
        ["missfortune"] = {
            {menuslot = "R", slot = 3, spellname = "missfortunebullettime", channelduration = 3}
        },
        ["nunu"] = {
            {menuslot = "R", slot = 3, spellname = "absolutezero", channelduration = 3}
        },
        --excluding Orn's Forge Channel since it can be cancelled just by attacking him
        ["pantheon"] = {
            {menuslot = "R", slot = 3, spellname = "pantheonrjump", channelduration = 2}
        },
        ["shen"] = {
            {menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3}
        },
        ["twistedfate"] = {
            {menuslot = "R", slot = 3, spellname = "gate", channelduration = 1.5}
        },
        ["xerath"] = {
            {menuslot = "R", slot = 3, spellname = "xerathlocusofpower2", channelduration = 3}
        }
    }
    self.orbs = {}
    self.rDamages = {}
    self.electrocuteTracker = {}
    self:Menu()

    self.uhh = true
    self.something = 0

	cb.add(cb.tick, function()
        self:OnTick()
    end)

    cb.add(cb.create_minion, function(obj)
        self:OnCreateObj(obj)
    end)

	cb.add(cb.create_particle, function(obj)
		self:OnCreateParticle(obj)
	end)

    cb.add(cb.delete_minion, function(obj)
        self:OnDeleteObj(obj)
    end)

	cb.add(cb.delete_particle, function(obj)
		self:OnDeletedParticle(obj)
	end)

    cb.add(cb.spell,function(spell)
        self:OnProcessSpell(spell)
    end)

    cb.add(cb.draw, function()
        self:OnDraw()
    end)
end

function Syndra:Menu()
   --[[ self.menu = menu("IntnnerSyndra", "Intnner - Syndra")
    self.menu:header("xs", "Core")
    self.menu:keybind("comboQE", "Q -> E Combo", false, "A")
    self.menu:keybind("AutoE", "Auto E", false, "G")
    self.menu:menu("combo", "Combo")
    self.menu.combo:boolean("qcombo", "Use Q", true)
    self.menu.combo:boolean("wcombo", "Use W", true)
    self.menu.combo:boolean("ecombo", "Use E", true)
    self.menu.combo:menu("antigap", "Anti-Gapcloser")
    for _, enemy in ipairs(common.GetEnemyHeroes()) do
        self.menu.combo.antigap:boolean(enemy.charName, enemy.charName, true)
    end

    self.menu.combo:menu("rset", "R")
    self.menu.combo.rset:boolean("rcombo", "Use R", true)
    for _, enemy in ipairs(self.enemyHeroes) do
        self.menu.combo.rset:boolean(tostring(enemy.networkID), enemy.charName, true)
    end
    self.menu.combo.rset:boolean("c0", "Cast regardless of below conditions", false)
    self.menu.combo.rset:boolean("c1", "Cast if target in wall", true)
    self.menu.combo.rset:boolean("c2", "Cast if lower health% than target", true)
    self.menu.combo.rset:slider("c3", "Cast if player % health < x", 15, 5, 100, 5)
    self.menu.combo.rset:boolean("c4", "Do not cast if killed by Q ", true)
    self.menu.combo.rset:boolean("c5", "Cast if more enemies near than allies", true)
    self.menu.combo.rset:slider("c6", "Cast if mana less than", 100, 50, 500, 50)
    self.menu.combo.rset:slider("c7", "Cast if target MR less than", 200, 100, 200, 10)
    self.menu.combo.rset:slider("c8", "Cast if enemies around player <= x", 2, 1, 5, 1)]]

    self.menu = menu("IntnnerSyndraRework", "Intnner - Syndra")
    --KeyBind 
    self.menu:menu("keys", "KeyBind - Settings")
    self.menu:header("core", "Core - Syndra")
    self.menu.keys:keybind("combokey", "Combo", "Space", false)
    self.menu.keys:keybind("harasskey", "Hybrid", "C", false)
    self.menu.keys:keybind("clearkey", "LaneClear", "V", false)
    self.menu.keys:keybind("lastkey", "LastHit", "X", false)
    self.menu.keys:keybind("rkey", "Toggle for Combo R", "A", false)
    self.menu.keys:keybind("comboQE", "Short E Combo", false, "T")
    self.menu.keys:keybind("AutoE", "Auto E", false, "G")
    --Combo
    self.menu:menu("combo", "Combo - Settings")
    --Q 
    self.menu.combo:header("combosettigs", "Q - Settings")
    self.menu.combo:boolean("qcombo", "Use Q", true)
    self.menu.combo:boolean("autoq", "^~ Dash in Target", true)
    self.menu.combo:slider("qerange", "^~ Min. Range for Long Q", 1100, 800, 1150, 1)
    self.menu.combo:boolean("slowpred", "Slow Prediction for Q + E", true)
    --W 
    self.menu.combo:header("WSETTINGS", "W - Settings")
    self.menu.combo:boolean("wcombo", "Use W", true)
    self.menu.combo:boolean("wonlyStuncombo", "^~ Only Stun (When enemy is stunned)", true)
    --E 
    self.menu.combo:header("ESETTINGS", "E - Settings")
    self.menu.combo:boolean("ecombo", "Use E", true)
    --R 
    self.menu.combo:header("rSETTINGS", "R - Settings")
    self.menu.combo:menu("rset", "R - Settings")
    self.menu.combo.rset:boolean("rcombo", "Use R", true)
    self.menu.combo.rset:dropdown("rmod", "R Combo: ", 1, {"Standard", "Combo Kill"})
    self.menu.combo.rset:slider("waster", "Min. Health Percent Enemy for use R", 15, 0, 100, 1)
    --Engage Mode 
    self.menu.combo.rset:menu("engage", "Standard - Settings")
    self.menu.combo.rset.engage:boolean("engagemode", "Only if combo can Kill", true)
    self.menu.combo.rset.engage:boolean("CastTarget", "Use if target is between you and the wall", true) --c1 
    self.menu.combo.rset.engage:boolean("castlower", "Use if target low health {%}", true) --c2
    self.menu.combo.rset.engage:boolean("castnot", "Do not use if killed by orthers spells or AA ", true) --c4
    self.menu.combo.rset.engage:boolean("castmoreenemies", "Use more enemies near than allies", true) --c5
    self.menu.combo.rset.engage:slider("castifmana", "Min. Mana for use R {%}", 100, 50, 500, 50) --c6
    self.menu.combo.rset.engage:slider("castMR", "Min. Percent Health Target {%}", 200, 100, 200, 10) --c7
    self.menu.combo.rset.engage:slider("castAround", "Auto R - Min. Enemies around {%}", 2, 1, 5, 1) --c8
    self.menu.combo.rset.engage:slider("castplayer", "Auto R - if your health", 15, 5, 100, 5) --c3
    self.menu.combo.rset.engage:slider("orb", "Min. Orbs for Engage", 5, 3, 7, 1)
    --Whitelist 
    self.menu.combo.rset:menu("Whitelist", "R - Whitelist")
    local enemy = common.GetEnemyHeroes()
    for i, allies in ipairs(enemy) do
        self.menu.combo.rset.Whitelist:boolean(allies.charName, "Block: " .. allies.charName, false)
    end

    self.menu:menu("harass", "Harass/Hybrid - Settings")
    self.menu.harass:boolean("autoq", "Auto Q", false)
    self.menu.harass:boolean("autoqcc", "Use under special conditions", true) 
    self.menu.harass.autoqcc:set("tooltip", "When the enemy is stationary or with HardBuffs")

    self.menu.harass:header("qq", "Q - Settings")
    self.menu.harass:boolean("qharass", "Use Q", true)
    self.menu.harass:boolean("qeharass", "^~ Long Q (use Q + E if enemy out range)", true)
    self.menu.harass:header("here", "Mana - Settings")
    self.menu.harass:slider("mana", "Mana Manager", 30, 0, 100, 1)

--[[    self.menu:menu("laneclear", "WaveClear - Settings")
    self.menu.laneclear:boolean("farmq", "Use Q to Farm", true)
    self.menu.laneclear:slider("hitq", " ^- If Hits", 2, 0, 6, 1)
    self.menu.laneclear:boolean("farmw", "Use W to Farm", true)
    self.menu.laneclear:slider("hitw", " ^- If Hits", 3, 0, 6, 1)
    self.menu.laneclear:boolean("lastq", "Use Q to Last Hit", false)
    self.menu.laneclear:boolean("lastqaa", " ^- Only if out of Auto Attack range", false)
    self.menu.laneclear:boolean("autolasthit", " ^- Use it Automatically", false)

    self.menu.laneclear:header("here", "Mana - Settings")
    self.menu.laneclear:slider("mana", "Mana Manager", 30, 0, 100, 1)]]

    self.menu:menu("misc", "Misc - Settings")
    --Bonus 
    self.menu.misc:header("bonus", "Bonus - Settings")
    self.menu.misc:boolean("disable", "Do not use AA in combo", false)
    self.menu.misc:slider("level", "^~ Min. Level myHero", 7, 1, 18, 1)
    self.menu.misc:boolean("logicSpells", "Do not use spells based on the damage of each spells", true)
    self.menu.misc:header("Anti-gAB", "Anti-Gapclose - Settings")
    self.menu.misc:boolean("GapA", "Use Anti-Gapclose", true)
    self.menu.misc:slider("health", " ^-Only if my Health Percent < X", 50, 1, 100, 1)
    self.menu.misc:header("Anti", "Interrupt - Settings")
    self.menu.misc:menu("interrupt", "Interrupt Settings")
    self.menu.misc.interrupt:boolean("inte", "Use E for Interrupt", true)
    self.menu.misc.interrupt:menu("interruptmenu", "Interrupt - Settings")
    for i = 1, #common.GetEnemyHeroes() do
        local enemy = common.GetEnemyHeroes()[i]
        local name = string.lower(enemy.charName)
        if enemy and self.interruptableSpells[name] then
            for v = 1, #self.interruptableSpells[name] do
                local spell = self.interruptableSpells[name][v]
                self.menu.misc.interrupt.interruptmenu:boolean(
                    string.format(tostring(enemy.charName) .. tostring(spell.menuslot)),
                    "Interrupt " .. tostring(enemy.charName) .. " " .. tostring(spell.menuslot),
                    true
                )
            end
        end
    end
    self.menu.misc:header("DDDDDDDD", "Killsteal - Settings")
    self.menu.misc:menu("killsteal", "Killsteal - Settings")
    self.menu.misc.killsteal:boolean("ksq", "Killsteal with Q", true)
    self.menu.misc.killsteal:boolean("ksw", "Killsteal with W", true)
    self.menu.misc.killsteal:boolean("ksr", "Killsteal with R", true)

    self.menu:menu("draws", "Drawings - Settings")
    self.menu.draws:boolean("drawq", "Draw Q Range", true)
    self.menu.draws:boolean("drawqe", "Draw QE Range", true)
    self.menu.draws:boolean("draww", "Draw W Range", false)
    self.menu.draws:boolean("drawe", "Draw E Range", false)
    self.menu.draws:boolean("drawr", "Draw R Range", true)
    self.menu.draws:boolean("drawtoggle", "Draw Toglles", true)
    --menu.draws:boolean("drawball", "Draw Ball Timer", true)
    self.menu.draws:slider("width", "Width Line Draw", 30, 10, 100, 1)
end

function Syndra:Toglle()
    if self.menu.keys.rkey:get() then
		if (self.uhh == false and os.clock() > self.something) then
			self.uhh = true
			self.something = os.clock() + 0.3
		end
		if (self.uhh == true and os.clock() > self.something) then
			self.uhh = false
			self.something = os.clock() + 0.3
		end
	end
end 

function Syndra:QEFilter(seg, obj)
	if gpred.trace.linear.hardlock(self.spell.qe, seg, obj) then
		return true
	end
	if gpred.trace.linear.hardlockmove(self.spell.qe, seg, obj) then
		return true
	end
	if gpred.trace.newpath(obj, 0.033, 0.5) then
		return true
	end
end

local TargetSelectionQ = function(res, obj, dist)
	if dist < 800 then
		res.obj = obj
		return true
	end
end

function Syndra:GetTargetQ()
	return TS.get_result(TargetSelectionQ).obj
end

function Syndra:OnTick()
    self:TrackWObject()
    self:Toglle()
    
	self:Killsteal()

    local myPos = gpred.core.get_pos_after_time(player, network.latency / 2000 + 0.06)
    self.myHeroPred = vec3(myPos.x, player.y, myPos.y)

    self.spell.e.angle = player:spellSlot(2).level < 5 and self.spell.e.angle1 or self.spell.e.angle2

    if self.spell.w.blacklist2 and clock() >= self.spell.w.blacklist2.time + 0.8 then
        self.spell.w.blacklist2 = nil
    end
    for _, stacks in pairs(self.electrocuteTracker) do
        for i, time in pairs(stacks) do
            if clock() >= time + 2.75 - 0.06 - network.latency / 2000 then
                stacks[i] = nil
            end
        end
    end

    for i in ipairs(self.spell.w.blacklist) do
        if not self.orbs[i] then
            self.spell.w.blacklist[i] = nil
        elseif self.spell.w.blacklist[i].nextCheckTime and clock() >= self.spell.w.blacklist[i].nextCheckTime then
            if
                clock() >= self.spell.w.blacklist[i].interceptTime and
                    GetDistanceSqr(self.orbs[i].obj.pos, self.spell.w.blacklist[i].pos) == 0
             then
                self.spell.w.blacklist[i] = nil
            else
                self.spell.w.blacklist[i].pos = self.orbs[i].obj.pos
                self.spell.w.blacklist[i].nextCheckTime = clock() + 0.3
            end
        end
    end

    for orb in pairs(self.spell.e.blacklist) do
        if self.spell.e.blacklist[orb].time <= clock() then
            if
                not (self.spell.w.heldInfo and orb == self.spell.w.heldInfo.obj) and
                    GetDistanceSqr(self.spell.e.blacklist[orb].pos, orb.pos) == 0
             then
                self.spell.e.blacklist[orb] = nil
			 end
        end
    end

    for i in ipairs(self.orbs) do
        local orb = self.orbs[i]
        if clock() >= orb.endT or (orb.obj.health and orb.obj.health ~= 1) then
            remove(self.orbs, i)
        end
    end

    if self.menu.harass.autoqcc:get() then
		if (player.mana / player.maxMana) * 100 >= self.menu.harass.mana:get() then
			local target = self:GetTargetQ()
			if target and target.isVisible then
				if common.IsValidTarget(target) then
					if (target.pos:dist(player.pos) <= self.spell.q.range) then
						local pos = gpred.circular.get_prediction(self.spell.q, target)
						if pos and pos.startPos:dist(pos.endPos) <= self.spell.q.range then
							if
								(common.CheckBuffType(target, 5) or common.CheckBuffType(target, 8) or common.CheckBuffType(target, 24) or
									common.CheckBuffType(target, 11) or
									common.CheckBuffType(target, 22) or
									common.CheckBuffType(target, 21))
							 then
								player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
                                self.last.q = clock() + 0.5
                                self.orbs[#self.orbs + 1] = {
                                    obj = {pos = vec3(pos.endPos.x, mousePos.y, pos.endPos.y)},
                                    isInitialized = false,
                                    isCasted = false,
                                    endT = clock() + 0.25
                                }
                                return true
							end
						end
					end
				end
			end
		end
	end
	if self.menu.harass.autoq:get() then
		if (player.mana / player.maxMana) * 100 >= self.menu.harass.mana:get() then
			local target = self:GetTargetQ()
			if target and target.isVisible then
				if common.IsValidTarget(target) then
					if (target.pos:dist(player.pos) <= self.spell.q.range) then
						local pos = gpred.circular.get_prediction(self.spell.q, target)
						if pos and pos.startPos:dist(pos.endPos) <= self.spell.q.range then
							player:castSpell("pos", 0, vec3(pos.endPos.x, mousePos.y, pos.endPos.y))
                            self.last.q = clock() + 0.5
                                self.orbs[#self.orbs + 1] = {
                                    obj = {pos = vec3(pos.endPos.x, mousePos.y, pos.endPos.y)},
                                    isInitialized = false,
                                    isCasted = false,
                                    endT = clock() + 0.25
                                }
                            return true 
						end
					end
				end
			end
		end
	end
	if orb.combat.is_active() and self.menu.misc.logicSpells:get() then
		if player:spellSlot(2).state ~= 0 and player:spellSlot(1).state ~= 0 and player:spellSlot(0).state ~= 0 then
			orb.core.set_pause_attack(0)
		end
	end
	if (orb.combat.is_active()) then
		if (self.menu.misc.disable:get() and self.menu.misc.level:get() <= player.levelRef) and player.mana > 100 then
			if not self.menu.misc.logicSpells:get() then
				orb.core.set_pause_attack(math.huge)
			end
			if self.menu.misc.logicSpells:get() then
				if player:spellSlot(2).state == 0 or player:spellSlot(1).state == 0 or player:spellSlot(0).state == 0 then
					orb.core.set_pause_attack(math.huge)
				end
			end
		end
	end
	if orb.combat.is_active() and player.mana < 100 then
		orb.core.set_pause_attack(0)
	end

	if not orb.combat.is_active() then
		if orb.core.is_attack_paused() then
			orb.core.set_pause_attack(0)
		end
	end
	if self.menu.combo.autoq:get() then
		self:AutoDash()
	end

    if (self.uhh == true) and self.menu.combo.rset.rmod:get() == 1 then
		self.menu.combo.rset.rmod:set("value", 2)
	end
	if (self.uhh == false) and self.menu.combo.rset.rmod:get() == 2 then
		self.menu.combo.rset.rmod:set("value", 1)
	end

	if self.menu.misc.GapA:get() then
		self:WGapcloser()
	end

    if self:ShouldCast() then
        self:Combo()
    end
end

function Syndra:Combo()
    self.qTarget = nil
    for _, enemy in ipairs(self.enemyHeroes) do
        self.unitsInRange[enemy.networkID] = enemy.pos and not enemy.isDead and GetDistanceSqr(enemy) < 4000000 --2000 range
    end

    local q = player:spellSlot(0).state == 0
    local notQ = player:spellSlot(0).state ~= 0
    local w = player:spellSlot(1).state == 0
    local w1 = w and player:spellSlot(1).name == "SyndraW" and not self.spell.w.heldInfo
    local e = player:spellSlot(2).state == 0
    local notE = player:spellSlot(2).state ~= 0

    if w1 and self:AutoGrab() then
        return
    end

    local canHitOrbs = self:GetHitOrbs()
    local canE = false

    if e then
        self.spell.e.delay = 0.32
        local weTarget = TS.get_result(function(res, obj, dist)
			if dist > self.spell.e.range then 
				return 
			end 

			if not self.unitsInRange[obj.networkID] then
				return
			end

			if self:CalcQEShort(obj, self.spell.e.widthMax, "w") then
				res.obj = obj 
				return true 
			end 
		end).obj
        if weTarget and weTarget ~= nil and common.isValidTarget(weTarget) then
            canE = true
			local seg = gpred.linear.get_prediction(self.spell.e, weTarget, vec2(player.x, player.z))
            if seg and (orb.menu.combat.key:get() or (weTarget.path.isDashing)) then
                if self:CastWEShort(vec3(seg.endPos.x, mousePos.y, seg.endPos.y), canHitOrbs) then
                    self.spell.w.blacklist2 = {target = weTarget.networkID, time = clock()}
                    return true
                end
            end
        end
        local qeTarget = TS.get_result(function(res, obj, dist)
			if dist > self.spell.e.range then 
				return 
			end 

			if not self.unitsInRange[obj.networkID] then
				return
			end
                
			if self:CalcQEShort(obj, self.spell.e.widthMax, "q") then
				res.obj = obj
				return true
			end
		end).obj 
        if qeTarget and qeTarget ~= nil and common.isValidTarget(qeTarget) then
            canE = true
			local segtwo = gpred.linear.get_prediction(self.spell.e, qeTarget, vec2(player.x, player.z))
            if segtwo and (orb.menu.combat.key:get() or (qeTarget.path.isDashing)) then
                if self:CastQEShort(vec3(segtwo.endPos.x, mousePos.y, segtwo.endPos.y), canHitOrbs) then
                    self.spell.w.blacklist2 = {target = qeTarget.networkID, time = clock()}
                    return true
                end
            end
        end

        local eTargets = common.GetTarget(self.spell.qe.range)
        if eTargets and common.IsValidTarget(eTargets) then 
            if (self.menu.combo.ecombo:get() and not player.isRecalling) or orb.menu.combat.key:get() then
                if self:CastE(eTargets, canHitOrbs) then
                    return true
                end
            end
        end
    end
    self.igniteDamage = 50 + 20 * myHero.levelRef
    local igniteTargets = common.GetTarget(650)
    if igniteTargets and common.IsValidTarget(igniteTargets) then 
        if self:UseIgnite(igniteTargets) then
            return
        end
    end
    self.rDamages = {}
    self.spell.r.castRange = 675 + (player:spellSlot(3).level / 3) * 75
    --self:CalcRDamage()
    local rTargets = common.GetTarget(1500)
    if self.menu.combo.rset.rcombo:get() then
        if rTargets then 
            if self:CastR(rTargets) then
                return
            end
        end
    end

	if orb.menu.combat.key:get() then
        if w then
            local wTarget = TS.get_result(function(res, obj, dist)
				if dist > self.spell.w.range then 
					return 
				end 
	
				if self.unitsInRange[obj.networkID] then
					res.obj = obj 
					return true 
				end
			end).obj 
			
            local _, isOrb = self:GetGrabTarget()
            if wTarget and wTarget ~= nil and common.IsValidTarget(wTarget) then
				local pos = gpred.circular.get_prediction(self.spell.w, wTarget, vec2(player.x, player.z))
				if pos and pos.startPos:dist(pos.endPos) < self.spell.w.range then
					if w1 and (notE or (isOrb or q) or not self:WaitToInitialize()) and self:CastW1() then
						return
					end
					if not (self.spell.w.blacklist2 and wTarget.networkID == self.spell.w.blacklist2.target) and self.spell.w.heldInfo and
					(notE or not self.spell.w.heldInfo.isOrb) and self:CastW2(vec3(pos.endPos.x, wTarget.pos.y, pos.endPos.y)) then
						return
					end
				end
            end
        end
        if e and not canE then

			local eTarget = TS.get_result(function(res, obj, dist)
				if dist > self.spell.qe.range then 
					return 
				end 
	
				if self.unitsInRange[obj.networkID] and self:CalcQELong(obj, self.spell.q.range - 100) then
					res.obj = obj 
					return true 
				end
			end).obj 

            if eTarget and eTarget ~= nil and common.IsValidTarget(eTarget) then
				local ePred = gpred.linear.get_prediction(self.spell.qe, eTarget, vec2(player.x, player.z))
				if ePred and (GetDistanceSqr(player, vec3(ePred.endPos.x,mousePos.y, ePred.endPos.y)) <= self.spell.e.rangeSqr or self.menu.keys.comboQE:get()) then 
					if (q and self:CastQELong(vec3(ePred.endPos.x, mousePos.y, ePred.endPos.y), canHitOrbs)) then
						return
					end
				end
            end
        end
    end

    if q then

		local qTarget = TS.get_result(function(res, obj, dist)
			if dist > self.spell.q.range then 
				return 
			end 

			if self.unitsInRange[obj.networkID] then
				res.obj = obj 
				return true 
			end
		end).obj 
		
        if qTarget then
            self.qTarget = qTarget
        end
        if qTarget and qTarget ~= nil and common.isValidTarget(qTarget) and not (self.spell.w.blacklist2 and qTarget.networkID == self.spell.w.blacklist2.target) then
			local pos = gpred.circular.get_prediction(self.spell.q, qTarget, vec2(player.x, player.z))

            if pos and pos.endPos and player.pos:distSqr(vec3(pos.endPos.x, qTarget.pos.y, pos.endPos.y)) < 875^2 then 
				if ((orb.menu.combat.key:get() and (notE or GetDistanceSqr(vec3(pos.endPos.x, qTarget.pos.y, pos.endPos.y)) >= self.spell.e.rangeSqr)) or orb.menu.hybrid.key:get()) and self.menu.combo.qcombo:get() and self:CastQ(vec3(pos.endPos.x, qTarget.pos.y, pos.endPos.y)) then
					return
				end
			end 
        end
    end
end

function Syndra:WGapcloser()
    if player:spellSlot(2).state == 0 and self.menu.misc.GapA:get() then
		local seg = {}
		local target =
			TS.get_result(
			function(res, obj, dist)
				if dist <= self.spell.e.range and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
					res.obj = obj
					return true
				end
			end
		).obj
		if target then
			local pred_pos = gpred.core.lerp(target.path, network.latency + self.spell.e.delay, target.path.dashSpeed)
			if pred_pos and pred_pos:dist(player.path.serverPos2D) <= self.spell.e.range then
				seg.startPos = player.path.serverPos2D
				seg.endPos = vec2(pred_pos.x, pred_pos.y)

				player:castSpell("pos", 2, vec3(pred_pos.x, target.y, pred_pos.y))
			end
		end
	end
end 

function Syndra:Killsteal()
	local enemy = common.GetEnemyHeroes()
	for i, enemies in ipairs(enemy) do
		if enemies and enemies.isVisible and common.IsValidTarget(enemies) and not common.CheckBuffType(enemies, 17) then
			local hp = common.GetShieldedHealth("AP", enemies)
			if self.menu.misc.killsteal.ksr:get() then
				if
					player:spellSlot(3).state == 0 and vec3(enemies.x, enemies.y, enemies.z):dist(player) < self.spell.r.castRange and
						hp < self:RDamage(enemies) and
						(enemies.health / enemies.maxHealth) * 100 > 15
				 then
					player:castSpell("obj", 3, enemies)
                    return true
				end
			end
		end
	end
end

function Syndra:AutoDash()
	local target =
		TS.get_result(
		function(res, obj, dist)
			if dist <= self.spell.q.range and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
				res.obj = obj
				return true
			end
		end
	).obj
	if target then
		local pred_pos = gpred.core.lerp(target.path, network.latency +  self.spell.q.delay, target.path.dashSpeed)
		if pred_pos and pred_pos:dist(player.path.serverPos2D) <=  self.spell.q.range then
			--orb.core.set_server_pause()
			player:castSpell("pos", 0, vec3(pred_pos.x, target.y, pred_pos.y))
            self.last.q = clock() + 0.5
            self.orbs[#self.orbs + 1] = {
                obj = {pos = vec3(pred_pos.x, target.y, pred_pos.y)},
                isInitialized = false,
                isCasted = false,
                endT = clock() + 0.25
            }
            return true
		end
	end
end

function Syndra:OnDraw()
    for i in pairs(self.orbs) do
        local orb = self.orbs[i]
		if orb then 
			graphics.draw_circle(orb.obj.pos, 40, 1, (orb.isInitialized and 0xff34ebcc or 0xffde0707), 100)
			local pos = graphics.world_to_screen(vec3(orb.obj.pos.x, orb.obj.pos.y, orb.obj.pos.z))
			graphics.draw_text_2D("Timer: "..math.ceil(orb.endT - os.clock()), 14, pos.x, pos.y, 0xFFFFFFFF)
		end 
    end

	--[[local wTarget = TS.get_result(function(res, obj, dist)
		if dist > 1600 then 
			return
		end 

		res.obj = obj
		return true 
	end).obj

	if wTarget then 
		local ePred = gpred.linear.get_prediction(self.spell.qe, wTarget, vec2(player.x, player.z))
		if ePred and (GetDistanceSqr(player, vec3(ePred.endPos.x, wTarget.pos.y, ePred.endPos.y)) <= self.spell.e.rangeSqr or self.menu.comboQE:get()) then
            local canHitOrbs = self:GetHitOrbs()
            if myHero.mana >= 80 + 10 * player:spellSlot(0).level then
                local predPosition = vec3(ePred.endPos.x, wTarget.pos.y, ePred.endPos.y)
                local qPos = Vector(self.myHeroPred):extended(Vector(predPosition), (self.spell.q.range - 100)):toDX3()
                local canHitOrbAngles, collOrbAngles = {}, {}
                for i = 1, #canHitOrbs do
                    local orb = canHitOrbs[i]
                    local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(qPos), Vector(orb.obj.pos))
                    canHitOrbAngles[i] = angle
                end
                canHitOrbAngles[#canHitOrbAngles + 1] = 0
                collOrbAngles[0] = true
                table.sort(canHitOrbAngles)
                local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
                if best then
                    local castPosition = (Vector(self.myHeroPred) +  (Vector(qPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()
        			graphics.draw_circle(qPos, wTarget.boundingRadius, 1, 0xFFfcba03, 100)
                    player:castSpell("pos", 0, qPos)
                    common.DelayAction(function() player:castSpell("pos", 2, castPosition) end, 0.25)
        
                    self.last.q = clock() + 0.5
                    self.last.e = clock() + 0.5
                    self.orbs[#self.orbs + 1] = {
                        obj = {pos = qPos},
                        isInitialized = false,
                        isCasted = false,
                        endT = clock() + 0.25
                    }

                end
            end
		end 
	end ]]

    if self.menu.draws.drawq:get() and player:spellSlot(0).state == 0 then
        graphics.draw_circle(player.pos, self.spell.q.range, 1, 0xFFFFFFFF, self.menu.draws.width:get())
    end
    if self.menu.draws.drawe:get()  and player:spellSlot(2).state == 0 then
        graphics.draw_circle(player.pos, self.spell.e.range, 1, 0xFFFFFFFF, self.menu.draws.width:get())
    end
    if self.menu.draws.drawqe:get() and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 then
        graphics.draw_circle(player.pos, self.spell.qe.range, 1, 0xFFFFFFFF, self.menu.draws.width:get())
    end
    if self.menu.draws.draww:get() and player:spellSlot(1).state == 0 then
        graphics.draw_circle(player.pos, self.spell.w.range, 1, 0xFFFFFFFF, self.menu.draws.width:get())
    end
    if self.menu.draws.drawr:get() and player:spellSlot(3).state == 0 then
        graphics.draw_circle(player.pos, self.spell.r.castRange, 1, 0xFFFFFFFF, self.menu.draws.width:get())
    end

    if self.menu.draws.drawtoggle:get() then
		local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
		if self.uhh == false then
			graphics.draw_text_2D("R Combo: ", 17, pos.x - 20, pos.y + 30, graphics.argb(255, 255, 255, 255))
			graphics.draw_text_2D("Standard", 17, pos.x + 55, pos.y + 30, graphics.argb(255, 9, 214, 63))
		else
			graphics.draw_text_2D("R Combo: ", 17, pos.x - 20, pos.y + 30, graphics.argb(255, 255, 255, 255))
			graphics.draw_text_2D("Killsteal", 17, pos.x + 55, pos.y + 30, graphics.argb(255, 9, 214, 63))
		end

        local text = (self.menu.keys.comboQE:get() and "Short On" or "Short Off")
        graphics.draw_text_2D(text, 17, graphics.world_to_screen(player.pos).x - 20, graphics.world_to_screen(player.pos).y, 0xFFFFFFFF)

        local texte = (self.menu.keys.AutoE:get() and "Auto E: On" or "Auto E: Off")
        graphics.draw_text_2D(texte, 17, graphics.world_to_screen(player.pos).x - 20, graphics.world_to_screen(player.pos).y + 15, 0xFFFFFFFF)
	end
end

function Syndra:TrackWObject()
    if not self.spell.w.heldInfo and player.buff['syndrawtooltip'] then
        local minions = common.GetMinionsInRange(1800, TEAM_ENEMY, mousePos)
        for i = 1, #minions do
            local minion = minions[i]
            if minion and not minion.isDead then
                if minion.buff["syndrawbuff"] then
					self.spell.w.heldInfo = {obj = minion, isOrb = false}
					return
				end
            end
        end
        for i in ipairs(self.orbs) do
            local orb = self.orbs[i]
            if orb.isInitialized then
				for i, headweW in pairs(self.HeanderW_target) do
                    if headweW then 
						self.spell.w.heldInfo = {obj = orb.obj, isOrb = true}
						orb.endT = clock() + 6.25
						self.spell.e.blacklist[orb.obj] = {
							pos = orb.obj.pos,
							time = clock() + 0.06
						}
						return
					end
                end
            end
        end
    end
end

function Syndra:WaitToInitialize()
    for i in ipairs(self.orbs) do
        local orb = self.orbs[i]
        if not orb.isInitialized and GetDistanceSqr(orb.obj.pos) <= self.spell.w.grabRangeSqr then
            return true
        end
    end
end

function Syndra:ShouldCast()
    for spell, time in pairs(self.last) do
        if time and clock() < time then
            return false
        end
    end
    return true
end

function Syndra:AutoGrab()
    if not player.isRecalling then
		for i=0, objManager.minions.size[TEAM_ENEMY]-1 do
            local minion = objManager.minions[TEAM_ENEMY][i]
            if
                (minion.name == "Tibbers" or minion.name == "IvernMinion" or minion.name == "H-28G Evolution Turret") and
                    GetDistanceSqr(minion) < self.spell.w.grabRangeSqr
             then
        
				player:castSpell("pos", 1, minion.pos)
                self.last.w = clock() + 0.5
                return true
            end
        end
    end
end

function Syndra:CastQ(pred)
    if player:spellSlot(_Q).state == 0 then
        if pred then 
            player:castSpell("pos", 0, pred)
            self.last.q = clock() + 0.5
            self.orbs[#self.orbs + 1] = {
                obj = {pos = pred},
                isInitialized = false,
                isCasted = false,
                endT = clock() + 0.25
            }
            --PrintChat("q")
            return true
        end
    end
end

function Syndra:GetGrabTarget()
    local lowTime = huge
    local lowOrb = nil
    for i in ipairs(self.orbs) do
        local orb = self.orbs[i]
        if
            not self.spell.w.blacklist[i] and orb.isInitialized and orb.endT < lowTime and
                GetDistanceSqr(orb.obj.pos) <= self.spell.w.grabRangeSqr
         then
            lowTime = orb.endT
            lowOrb = orb.obj
        end
    end
    if lowOrb then
        return lowOrb, true
    end

    local minionsInRange = common.GetMinionsInRange(self.spell.w.range, TEAM_ENEMY, player)
    local lowHealth = huge
    local lowMinion = nil
    for _, minion in ipairs(minionsInRange) do
        if
            minion and self.wGrabList[minion.charName] and common.IsValidTarget(minion) and
                GetDistanceSqr(minion.pos) <= self.spell.w.grabRangeSqr
         then
            if minion.health < lowHealth then
                lowHealth = minion.health
                lowMinion = minion
            end
        end
    end
    if lowMinion then
        return lowMinion, false
    end
end

function Syndra:CastW1()
    local target = self:GetGrabTarget()
    if target then
        player:castSpell("pos", 1, target.pos)
        self.last.w = clock() + 0.5
        --PrintChat("w1" .. target.name .. GetDistance(target.position))
        return true
    end
end

function Syndra:CastW2(pred)
    if not self.spell.w.heldInfo then
        return
    end
    if pred then
		player:castSpell("pos", 1, pred)
        self.last.w = clock() + 0.5
        --PrintChat("w2")
        return true
    end
end


function Syndra:GetHitOrbs()
    local canHitOrbs = {}
    for i in ipairs(self.orbs) do
        local orb = self.orbs[i]
        local distToOrb = common.GetDistance(orb.obj.pos)
        if distToOrb <= self.spell.q.range then
            local timeToHitOrb = self.spell.e.delay + (distToOrb / self.spell.e.speed)
            local expectedHitTime = clock() + timeToHitOrb - 0.1
            local canHitOrb =
                orb.isCasted and
                (orb.isInitialized and (expectedHitTime + 0.1 < orb.endT) or (expectedHitTime > orb.endT)) and
                (not orb.isInitialized or (orb.obj and not self.spell.e.blacklist[orb.obj])) and
                (not self.spell.w.heldInfo or orb.obj ~= self.spell.w.heldInfo.obj)
            if canHitOrb then
                canHitOrbs[#canHitOrbs + 1] = orb
            end
        end
    end
    return canHitOrbs
end

function Syndra:CanEQ(qPos, pred, target)
    --wall check
    local interval = 50
    local castPosition = (pred)
    local count = floor(common.GetDistance(castPosition, qPos:toDX3()) / interval)
    local diff = (Vector(castPosition) - qPos):normalized()
    for i = 0, count do
        local pos = (Vector(qPos) + diff * i * interval):toDX3()
        if navmesh.isWall(pos) then
            return false
        end
    end

    --cc check
    return true
end

function Syndra:CheckForSame(list)
    if #list > 2 then
        local last = list[#list]
        for i = #list - 1, 1, -1 do
            if abs(last - list[i]) < 0.01 then
                local maxInd = 0
                local maxVal = -huge
                for j = i + 1, #list do
                    if list[j] > maxVal then
                        maxInd = j
                        maxVal = list[j]
                    end
                end
                return maxVal
            end
        end
    end
end

function Syndra:CheckHitOrb(castPos)
    for i in ipairs(self.orbs) do
        if
            GetDistanceSqr(self.myHeroPred, self.orbs[i].obj.pos) <= self.spell.q.rangeSqr and
                Vector(self.myHeroPred):AngleBetween(Vector(castPos), Vector(self.orbs[i].obj.pos)) <=
                    (self.spell.e.angle + 10) / 2
         then
            self.spell.w.blacklist[i] = {
                interceptTime = clock() + common.GetDistance(self.myHeroPred, self.orbs[i].obj.pos) / self.spell.e.speed +
                    0.5,
                nextCheckTime = clock() + 0.3,
                pos = self.orbs[i].obj.pos
            }
        end
    end
end

function Syndra:CalcQELong(target, dist)
    local dist = dist or self.spell.e.range
    self.spell.qe.speed = self.spell.qe.pingPongSpeed
    local pred
    local lasts = {}
    local check = nil
    while not check do
        local pos = gpred.linear.get_prediction(self.spell.qe, target, vec2(player.x, player.z))
		local pred = vec3(pos.endPos.x, target.pos.y, pos.endPos.y)
        if pred and GetDistanceSqr(target.pos) >= self.spell.e.rangeSqr then
            local castPosition = (pred)
            local offset = -target.boundingRadius or 0
            local distToCast = common.GetDistance(castPosition)
            self.spell.qe.speed =
                (self.spell.e.speed * dist + self.spell.qe.pingPongSpeed * (distToCast + offset - dist)) /
                (distToCast + offset)
            lasts[#lasts + 1] = self.spell.qe.speed
            check = self:CheckForSame(lasts)
        else
            return
        end
    end
    self.spell.qe.speed = check
    return true
end

function Syndra:CalcQEShort(target, widthMax, spell)
    self.spell.e.width = widthMax
    local pred = nil
    local lasts = {}
    local check = nil
    while not check do
        local seg = gpred.linear.get_prediction(self.spell.e, target, vec2(player.x, player.z))
		pred = vec3(seg.endPos.x, target.pos.y, seg.endPos.y)
        if not seg and (pred) then
            return
        end
        self.spell.e.width =
            -target.boundingRadius +
            (common.GetDistance(pred) + target.boundingRadius) /
                (common.GetDistance(self:GetQPos(pred, spell):toDX3()) + target.boundingRadius) *
                (widthMax + target.boundingRadius)
        lasts[#lasts + 1] = self.spell.e.width
        check = self:CheckForSame(lasts)
    end
    self.spell.e.width = check
    if not self:CanEQ(self:GetQPos(pred, "q"), pred, target) then
        return
    end
    return pred
end

function Syndra:CalcBestCastAngle(colls, all)
    local maxCount = 0
    local maxStart = nil
    local maxEnd = nil
    for i = 1, #all do
        local base = all[i]
        local endAngle = base + self.spell.e.angle
        local over360 = endAngle > 360
        if over360 then
            endAngle = endAngle - 360
        end
        local function isContained(count, angle, base, over360, endAngle)
            if angle == base and count ~= 0 then
                return
            end
            if not over360 then
                if angle <= endAngle and angle >= base then
                    return true
                end
            else
                if angle > base and angle <= 360 then
                    return true
                elseif angle <= endAngle and angle < base then
                    return true
                end
            end
        end
        local angle = base
        local j = i
        local count = 0
        local hasColl = colls[angle]
        local endDelta = angle
        while (isContained(count, angle, base, over360, endAngle)) do
            if count > 10 then
            end
            if colls[angle] then
                hasColl = true
            end
            endDelta = all[j]
            count = count + 1
            j = j + 1
            if j > #all then
                j = 1
            end
            angle = all[j]
        end
        if hasColl and count > maxCount then
            maxCount = count
            maxStart = base
            maxEnd = endDelta
        end
    end
    if maxStart and maxEnd then
        if maxStart + self.spell.e.angle > 360 then
            maxEnd = maxEnd + 360
        end
        local res = (maxStart + maxEnd) / 2
        if res > 360 then
            res = res - 360
        end
        --PrintChat("count: " .. maxCount .. " res: " .. res)
        return rad(res)
    end
end

function Syndra:CastE(target, canHitOrbs)
    if player:spellSlot(_E).state == 0 and #canHitOrbs >= 1 then
        local checkPred = gpred.linear.get_prediction(self.spell.qe, target, vec2(self.myHeroPred.x, self.myHeroPred.z))
        if not checkPred then
            return
        end
        local collOrbs, maxHit, maxOrb = {}, 0, nil
        --check which orb can be hit
        local checkWidth = checkPred.realHitChance == 1 and self.spell.e.widthMax or 100
        local checkSpell =
            setmetatable(
            {
                width = self.spell.qe.width - checkWidth / 2
            },
            {__index = self.spell.qe}
        )
        checkPred = gpred.linear.get_prediction(checkSpell, target, vec2(self.myHeroPred.x, self.myHeroPred.z))
        if checkPred and checkPred:length() < self.spell.qe.range and player.pos:distSqr(vec3(checkPred.endPos.x, mousePos.y, checkPred.endPos.y)) < self.spell.qe.range * self.spell.qe.range 
		and checkPred.startPos:distSqr(checkPred.endPos) < self.spell.qe.range * self.spell.qe.range then 
            --check which orbs can hit enemy
            for i = 1, #canHitOrbs do
                local orb = canHitOrbs[i]
                local castPosition = (vec3(checkPred.endPos.x, mousePos.y, checkPred.endPos.y))
                if GetDistanceSqr(castPosition) > GetDistanceSqr(orb.obj.pos) then
                    self:CalcQELong(target, common.GetDistance(orb.obj.pos))
                    local seg =
                        LineSegment(
                        Vector(self.myHeroPred):extended(Vector(orb.obj.pos), self.spell.qe.range),
                        Vector(self.myHeroPred)
                    )
                    if seg:distanceTo(Vector(castPosition)) <= checkWidth / 2 then
                        collOrbs[orb] = 0
                    end
                else
                    self.spell.e.delay = 0.25
                    local pred = self:CalcQEShort(target, checkWidth, "q")
                    if pred then
                        local castPosition = (pred)
                        if GetDistanceSqr(castPosition, orb.obj.pos) <= 160000 then -- 400 range
                            local seg =
                                LineSegment(
                                Vector(self.myHeroPred):extended(Vector(orb.obj.pos), self.spell.qe.range),
                                Vector(self.myHeroPred)
                            )
                            if
                                seg:distanceTo(self:GetQPos(castPosition)) <=
                                    self.spell.e.widthMax / common.GetDistance(orb.obj.pos) * common.GetDistance(castPosition)
                             then
                                collOrbs[orb] = 0
                            end
                        end
                    end
                end
            end

            -- look for cast with most orbs hit
            local basePosition = canHitOrbs[1].obj.pos
            local canHitOrbAngles, collOrbAngles = {}, {}
            for i = 1, #canHitOrbs do
                local orb = canHitOrbs[i]
                local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(basePosition), Vector(orb.obj.pos))
                canHitOrbAngles[i] = angle
                if collOrbs[orb] then
                    collOrbAngles[angle] = true
                end
            end
            table.sort(canHitOrbAngles)
            local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
            if best then
                local castPosition =
                    (Vector(self.myHeroPred) +
                    (Vector(basePosition) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() *
                        self.spell.e.range):toDX3()
				player:castSpell("pos", 2, castPosition)
                self.last.e = clock() + 0.5
                --PrintChat("e")
                return true
            end
        end
    end
end

function Syndra:CastQEShort(pred, canHitOrbs)
    if player:spellSlot(_Q).state == 0 and player:spellSlot(_E).state == 0 and myHero.mana >= 80 + 10 * player:spellSlot(0).level and
        (not self.spell.e.next or GetDistanceSqr(self.spell.e.next.pos) > self.spell.e.rangeSqr or self.spell.e.next.time <=  clock() + self.spell.e.delay + common.GetDistance(pred) / self.spell.e.speed) then
        local qPos = self:GetQPos(pred, "q"):toDX3()
        local canHitOrbAngles, collOrbAngles = {}, {}
        for i = 1, #canHitOrbs do
            local orb = canHitOrbs[i]
            local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(qPos), Vector(orb.obj.pos))
            canHitOrbAngles[i] = angle
        end
        canHitOrbAngles[#canHitOrbAngles + 1] = 0
        collOrbAngles[0] = true
        table.sort(canHitOrbAngles)
        local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
        if best then
            local castPosition =
                (Vector(self.myHeroPred) +
                (Vector(qPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()
			
			player:castSpell("pos", 0, qPos) 
			common.DelayAction(function() player:castSpell("pos", 2, castPosition) end, 0.25)
			
            self.last.e = clock() + 0.5
            self.orbs[#self.orbs + 1] = {
                obj = {pos = qPos},
                isInitialized = false,
                isCasted = false,
                endT = clock() + 0.25
            }
            self:CheckHitOrb(castPosition)
            return true
        end
    end
end

function Syndra:CastQELong(pred, canHitOrbs)
    if myHero.mana >= 80 + 10 * player:spellSlot(0).level then
        local predPosition = pred
        local qPos = Vector(self.myHeroPred):extended(Vector(predPosition), (self.spell.q.range - 100)):toDX3()
        local canHitOrbAngles, collOrbAngles = {}, {}
        for i = 1, #canHitOrbs do
            local orb = canHitOrbs[i]
            local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(qPos), Vector(orb.obj.pos))
            canHitOrbAngles[i] = angle
        end
        canHitOrbAngles[#canHitOrbAngles + 1] = 0
        collOrbAngles[0] = true
        table.sort(canHitOrbAngles)
        local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
        if best then
            local castPosition = (Vector(self.myHeroPred) +  (Vector(qPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()

            player:castSpell("pos", 0, qPos)
            common.DelayAction(function() player:castSpell("pos", 2, castPosition) end, 0.25)

            self.last.q = clock() + 0.5
            self.last.e = clock() + 0.5
            self.orbs[#self.orbs + 1] = {
                obj = {pos = qPos},
                isInitialized = false,
                isCasted = false,
                endT = clock() + 0.25
            }
            self:CheckHitOrb(castPosition)


            return true
        end
    end
end

function Syndra:CastWELong(pred, canHitOrbs)
    if myHero.mana >= 100 + 10 * player:spellSlot(1).level then
        local predPosition = (pred)
        local target, isOrb
        if self.spell.w.heldInfo then
            if not self.spell.w.heldInfo.isOrb then
                return
            end
        else
            --return
            target, isOrb = self:GetGrabTarget()
            if target and isOrb then
                player:castSpell("pos", 1, target.pos)
            else
                return
            end
        end
        local wPos = Vector(self.myHeroPred):extended(Vector(predPosition), (self.spell.q.range - 100)):toDX3()
        local canHitOrbAngles, collOrbAngles = {}, {}
        for i = 1, #canHitOrbs do
            local orb = canHitOrbs[i]
            if orb.obj == target then
                local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(wPos), Vector(orb.obj.pos))
                canHitOrbAngles[i] = angle
            end
        end
        canHitOrbAngles[#canHitOrbAngles + 1] = 0
        collOrbAngles[0] = true
        table.sort(canHitOrbAngles)
        local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
        if best then
            local castPosition =
                (Vector(self.myHeroPred) +
                (Vector(wPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()

			player:castSpell("pos", 1, wPos)
            common.DelayAction(function() player:castSpell("pos", 2, castPosition) end, 0.25)


            self.last.w = clock() + 0.5
            self.last.e = clock() + 0.5
            self:CheckHitOrb(castPosition)
            --PrintChat("we long")
            return true
        end
    end
end

function Syndra:GetQPos(predPos, spell)
    local dist = common.GetDistance(predPos)
    if spell == "q" then
        return Vector(self.myHeroPred):extended(Vector(predPos), min(dist + 450, max(dist + 50, 700)))
    elseif spell == "w" then
        return Vector(self.myHeroPred):extended(Vector(predPos), min(dist + 450, max(dist + 50, 700)))
    end
    return Vector(self.myHeroPred):extended(Vector(predPos), min(dist + 450, 850))
end

function Syndra:CastWEShort(pred, canHitOrbs)
    if player:spellSlot(_W).state == 0 and player:spellSlot(_E).state == 0 and myHero.mana >= 100 + 10 * player:spellSlot(1).level then
        local target, isOrb
        if self.spell.w.heldInfo then
            if not self.spell.w.heldInfo.isOrb then
                return
            end
        else
            target, isOrb = self:GetGrabTarget()
            if target and isOrb then
                player:castSpell("pos", 1, target.pos)
            else
                return
            end
        end
        local wPos = self:GetQPos(pred, "w"):toDX3()
        local canHitOrbAngles, collOrbAngles = {}, {}
        for i = 1, #canHitOrbs do
            local orb = canHitOrbs[i]
			local angle = Vector(self.myHeroPred):angleBetweenFull(Vector(wPos), Vector(orb.obj.pos))
			canHitOrbAngles[i] = angle
        end
        canHitOrbAngles[#canHitOrbAngles + 1] = 0
        collOrbAngles[0] = true
        table.sort(canHitOrbAngles)
        local best = self:CalcBestCastAngle(collOrbAngles, canHitOrbAngles)
        if best then
            local castPosition = (Vector(self.myHeroPred) + (Vector(wPos) - Vector(self.myHeroPred)):rotated(0, best, 0):normalized() * self.spell.e.range):toDX3()

			if player:castSpell("pos", 1, wPos) then 
				player:castSpell("pos", 2, castPosition)
			end 
            self.last.w = clock() + 0.5
            self.last.e = clock() + 0.5
            --PrintChat("we")
            return true
        end
    end
end

function Syndra:GetIgnite(target)
    return ((self.ignite and player:spellSlot(self.ignite).state == 0 and
        GetDistanceSqr(target) <= 360000) and --600 range
        true) or
        nil
end

function Syndra:UseIgnite(target)
    local ignite = self:GetIgnite(target)
    if
        ignite and
            (self.igniteDamage > target.health + target.allShield and
                player:spellSlot(3).state ~= 0 and
                ((player:spellSlot(0).state == 0 and 1 or 0) +
                    (player:spellSlot(1).state == 0 and 1 or 0) +
                    (player:spellSlot(2).state == 0 and 1 or 0) <=
                    1 or
                    myHero.health / myHero.maxHealth < 0.2))
     then
        player:castSpell("obj", self.ignite, target)
        return true
    end
end

function Syndra:CalcRDamage()
    local r = myHero.spellbook:Spell(SpellSlot.R)
    self.spell.r.baseDamage = r.currentAmmoCount * (50 + 45 * r.level + 0.2 * self:GetTotalAp())
end

function Syndra:RExecutes(target)
    local base = self.spell.r.baseDamage
	if player.buff["itemmagicshankcharge"] and player.buff["itemmagicshankcharge"].stacks >= 90 then
		base = base + 100 + 0.1 * self:GetTotalAp()
	elseif player.buff[string.lower"ASSETS/Perks/Styles/Sorcery/SummonAery/SummonAery.lua"] then
		base = base + 8.235 + 1.765 * myHero.experience.level + 0.1 * self:GetTotalAp()
	elseif player.buff[string.lower"ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua"] then
		if self.electrocuteTracker[target.networkId] and #self.electrocuteTracker[target.networkId] >= 1 then
			base = base + 21.176 + 8.824 * myHero.experience.level + 0.25 * self:GetTotalAp()
		end
	end
    base = common.CalculateMagicDamage(target, base)
    self.rDamages[target] = base + (self:GetIgnite(target) and self.igniteDamage or 0)
    local diff = target.health - base
    if diff <= 0 then
        return true, false
    elseif self.ignite and diff <= self.ignite then
        return true, true
    else
        return false, false
    end
end

local MainRDamage = {90, 135, 180}
function Syndra:RDamage(target)
	local damage = 0
	local calculate = 0
	if player:spellSlot(3).level > 0 then
		if (player:spellSlot(3).stacks <= 3) then
			calculate = (MainRDamage[player:spellSlot(3).level] + (common.GetTotalAP() * 0.2)) * 3
		end
		if (player:spellSlot(3).stacks > 3) then
			calculate = (MainRDamage[player:spellSlot(3).level] + (common.GetTotalAP() * 0.2)) * (player:spellSlot(3).stacks)
		end

		damage = common.CalculateMagicDamage(target, calculate)
	end

	return damage - target.healthRegenRate * 10
end

local QLevelDamage = {70, 110, 150, 190, 230}
function Syndra:QDamage(target)
	local damage = 0
	if player:spellSlot(0).level > 0 and player:spellSlot(0).level < 5 then
		damage =
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .65)), player)
	end
	if player:spellSlot(0).level > 0 and player:spellSlot(0).level == 5 then
		damage =
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .65)), player) +
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .65)), player) *
				0.15
	end
	return damage
end

function Syndra:QDamage2(target)
	local damage = 0
	if player:spellSlot(0).level > 0 then
		damage =
			common.CalculateMagicDamage(target, (QLevelDamage[player:spellSlot(0).level] + (common.GetTotalAP() * .65)), player)
	end
	return damage
end
local WLevelDamage = {70, 110, 150, 190, 230}
function Syndra:WDamage(target)
	local damage = 0
	if player:spellSlot(1).level > 0 then
		damage =
			common.CalculateMagicDamage(target, (WLevelDamage[player:spellSlot(1).level] + (common.GetTotalAP() * .7)), player)
	end
	return damage
end
local ELevelDamage = {70, 115, 160, 205, 250}
function Syndra:EDamage(target)
	local damage = 0
	if player:spellSlot(2).level > 0 then
		damage =
			common.CalculateMagicDamage(target, (ELevelDamage[player:spellSlot(2).level] + (common.GetTotalAP() * .6)), player)
	end
	return damage
end

function Syndra:RConditions(target)
    local canExecute, needIgnite = self:RExecutes(target)
    if not canExecute then
        return false
    end
    
    if not (orb.menu.combat.key:get() and player:spellSlot(3).state == 0 and
    self.menu.combo.rset[tostring(target.networkId)] and
    self.menu.combo.rset[tostring(target.networkId)]:get() and
    GetDistanceSqr(target.pos) <= self.spell.r.castRange * self.spell.r.castRange) then
        return false
    end
    if self.menu.combo.rset.c0:get() then
        return true, needIgnite
    end
    if self.menu.combo.rset.c1:get() and navmesh.isWall(target.pos) then
        return true, needIgnite
    end
    if self.menu.combo.rset.c2:get() and myHero.health / myHero.maxHealth <= target.health / target.maxHealth then
        return true, needIgnite
    end
    if self.menu.combo.rset.c3:get() and myHero.health / myHero.maxHealth <= self.menu.combo.rset.c3:get() / 100 then
        return true, needIgnite
    end
    if
	self.menu.combo.rset.c4:get() and player:spellSlot(0).state == 0 and
            target.health -
                common.CalculateMagicDamage(
                    target,
                    30 + 40 * player:spellSlot(0).level + 0.65 * self:GetTotalAp()
                ) <=
                0
     then
        return false
    end
    
	local enemiesInRange1, enemiesInRange2, alliesInRange = 0, 0, 0
    for _, enemy in ipairs(self.enemyHeroes) do
        if GetDistanceSqr(enemy.pos) <= 640000 then -- 800 range
            enemiesInRange1 = enemiesInRange1 + 1
        end
        if GetDistanceSqr(enemy.pos) <= 6250000 then --2500 range
            enemiesInRange2 = enemiesInRange2 + 1
        end
    end
    for _, ally in ipairs(self.allyHeroes) do
        if GetDistanceSqr(ally.pos) <= 640000 then -- 800 range
            alliesInRange = alliesInRange + 1
        end
    end
    if self.menu.combo.rset.c5:get() and enemiesInRange1 > alliesInRange then
        return true, needIgnite
    end
    if self.menu.combo.rset.c6:get() and myHero.mana < 200 then
        return true, needIgnite
    end
    if target.characterIntermediate.spellBlock < self.menu.combo.rset.c7:get() then
        return true, needIgnite
    end
    if enemiesInRange2 <= self.menu.combo.rset.c8:get() then
        return true, needIgnite
    end
end

function Syndra:CastR(target)
    local shouldCast, needIgnite = self:RConditions(target)
    if (target.pos:dist(player.pos) <= 675) and (target.health / target.maxHealth) * 100 >= self.menu.combo.rset.waster:get() then
		if (self.menu.combo.rset.rmod:get() == 2) then
			if self.menu.combo.rset.Whitelist[target.charName] and self.menu.combo.rset.Whitelist[target.charName]:get() then
				if (self:RDamage(target) > target.health) then
					player:castSpell("obj", 3, target)
                    self.last.r = clock() + 0.5
                    return true
				end
			end
		end
		if (self.menu.combo.rset.rmod:get() == 1) then
			if self.menu.combo.rset.Whitelist[target.charName] and self.menu.combo.rset.Whitelist[target.charName]:get() then
				if player:spellSlot(3).stacks >= self.menu.combo.rset.engage.orb:get() then
					if not self.menu.combo.rset.engage.engagemode:get() then
						player:castSpell("obj", 3, target)
                        self.last.r = clock() + 0.5
                        return true
					end
					if self.menu.combo.rset.engage.engagemode:get() then
						local damages = self:RDamage(target) + self:QDamage(target) + self:WDamage(target) + self:EDamage(target)
						if (target.health <= damages) then
							player:castSpell("obj", 3, target)
                            self.last.r = clock() + 0.5
                            return true
						end
					end
				end
			end
		end
	end
end

function Syndra:OnCreateParticle(obj)
	if not obj then 
		return 
	end 

	if (obj.name:find("_W_heldTarget_buf_02")) then
        self.HeanderW_target[obj.ptr] = obj
    end 
end 

function Syndra:OnDeletedParticle(obj)
	if not obj then 
		return 
	end

	for i, headweW in pairs(self.HeanderW_target) do
		if headweW then 
			if headweW == obj then 
				self.HeanderW_target[obj.ptr] = nil
			end 
		end 
	end 
end 

function Syndra:OnCreateObj(obj)
    if obj.name == "Seed" and obj.team == myHero.team and obj.owner.charName == "Syndra" then
        local replaced = false
        for i in ipairs(self.orbs) do
            local orb = self.orbs[i]
            if not orb.isInitialized and GetDistanceSqr(obj.pos, orb.obj.pos) == 0 then
                self.orbs[i] = {obj = obj, isInitialized = true, isCasted = true, endT = clock() + 6.25}
                replaced = true
            end
        end
        if not replaced then
            self.orbs[#self.orbs + 1] = {obj = obj, isInitialized = true, isCasted = true, endT = clock() + 6.25}
        end
    end
    if match(obj.name, "Syndra") then
        if
            match(obj.name, "Q_tar_sound") or
                match(obj.name, "W_tar") and
                    player.buff[string.lower"ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua"]
         then
            for _, enemy in ipairs(self.enemyHeroes) do
                if enemy.isVisible and GetDistanceSqr(enemy.pos, obj.pos) < 1 then
                    if not self.electrocuteTracker[enemy.networkId] then
                        self.electrocuteTracker[enemy.networkId] = {}
                    end
                    insert(self.electrocuteTracker[enemy.networkId], clock())
                end
            end
        elseif match(obj.name, "E_tar") then
            local isOrb = false
            for i in ipairs(self.orbs) do
                if GetDistanceSqr(self.orbs[i].obj.pos, obj.pos) < 1 then
                    isOrb = true
                end
            end
            if not isOrb then
                local electrocute =
                    player.buff[string.lower"ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua"]
                for _, enemy in ipairs(self.enemyHeroes) do
                    if electrocute and enemy.isVisible and GetDistanceSqr(enemy.pos, obj.pos) < 1 then
                        if not self.electrocuteTracker[enemy.networkId] then
                            self.electrocuteTracker[enemy.networkId] = {}
                        end
                        insert(self.electrocuteTracker[enemy.networkId], clock())
                    end
                    if self.spell.w.blacklist2 and enemy.networkId == self.spell.w.blacklist2.target then
                        self.spell.w.blacklist2 = nil
                    --PrintChat("e detected")
                    end
                end
            end
        end
    end
end

function Syndra:OnDeleteObj(obj)
    if obj then
        for i in ipairs(self.orbs) do
            if self.orbs[i].obj == obj then
                remove(self.orbs, i)
            end
        end
    end
end

function Syndra:OnProcessSpell(spell)
	if spell and spell.owner.team == player.team and spell.owner.charName == "Syndra" then
        if spell.name == "SyndraQ" then
            self.last.q = clock() + 0.15
            local replaced = false
            for i in pairs(self.orbs) do
                local orb = self.orbs[i]
                if not orb.isInitialized and not orb.isCasted and GetDistanceSqr(spell.owner.pos, orb.obj.pos) == 0 then
                    self.orbs[i] = {
                        obj = {pos = Vector(spell.endPos):toDX3()},
                        isInitialized = false,
                        isCasted = true,
                        endT = clock() + 0.625
                    }
                    replaced = true
                end
            end
            if not replaced then
                self.orbs[#self.orbs + 1] = {
                    obj = {pos = Vector(spell.endPos):toDX3()},
                    isInitialized = false,
                    isCasted = true,
                    endT = clock() + 0.625
                }
            end
        elseif spell.name == "SyndraW" then
            self.last.w = clock() + 0.15
        elseif spell.name == "SyndraWCast" then
            self.last.w = clock() + 0.15
            self.spell.e.next = {
                time = clock() + self.spell.w.delay,
                pos = Vector(spell.endPos):toDX3()
            }
        elseif spell.name == "SyndraE" then
            self:CheckHitOrb(Vector(spell.endPos):toDX3())
        elseif spell.name == "SyndraR" then
            self.timer = clock() + 0.15
        end
    end
end

function Syndra:GetTotalAp()
    return myHero.baseAbilityDamage +
        myHero.flatMagicDamageMod * (1 + myHero.percentMagicDamageMod)
end

cb.add(cb.error, function(msg)
    local log, e = io.open(hanbot.path..'/SyndraLogs.txt', 'w+')
    if not log then
      print(e)
      return
    end
    log:write(msg)
    log:close()
end)

return Syndra:__init()