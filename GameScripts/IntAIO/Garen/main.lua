local common = module.load(header.id, "Library/common")
local GeoLib = module.load(header.id, "Geometry/GeometryLib")
local TS = module.internal("TS")
local orb = module.internal("orb")

-- Q range attack
-- W Active 
-- E recast -: E2 
-- R 400
local menu = menu("intnnerGaren", "Int - Garen")

menu:header("here", "Core")
menu:menu("combo", "Combo - Settings")
menu.combo:header("q", "Q - Settings")
menu.combo:boolean("useQ", "Use Q in Combo", true)
menu.combo:slider("delayAA", "Delay (ms) between Q -> AA", 100, 5, 300, 5)

menu.combo:header("w", "W - Settings")
menu.combo:boolean("useW", "Use W in Combo", true)
menu.combo:slider("Distance", "Use when target distance <= {0} units", 525, 200, 875, 5)

menu.combo:header("e", "E - Settings")
menu.combo:boolean("useE", "Use E in Combo", true)
menu.combo:boolean("E.Status", "Use always after Q -> AA", true)

menu.combo:header("r", "R - Settings")
menu.combo:boolean("user", "Use R for Killsteal", true)
menu.combo:slider("Substract", "Subtract {0} from damage calculations", 5, 0, 15, 5)
menu.combo:menu("whitelist", "Whitelist - Settings")
for i=0, objManager.enemies_n-1 do
    local obj = objManager.enemies[i]
    if obj then 
        menu.combo['whitelist']:boolean(obj.charName, "Use R on "..obj.charName, true)
    end 
end 

menu:menu("misc", "Misc - Settings")
menu.misc:boolean("rkill", "KillSteal with R", true)

menu.misc:header('other', "Another - Settings")
menu.misc:boolean("Interrupt", "Enable Interrupter", true)
menu.misc:menu("listInterrupt", "Interrupt - Spells")
for i = 1, #common.GetEnemyHeroes() do
	local enemy = common.GetEnemyHeroes()[i]
	local name = string.lower(enemy.charName)
	if enemy and common.interruptableSpells[name] then
		for v = 1, #common.interruptableSpells[name] do
			local spell = common.interruptableSpells[name][v]
			menu.misc.listInterrupt:boolean(
				string.format(tostring(enemy.charName) .. tostring(spell.menuslot)),
				"Interrupt " .. tostring(enemy.charName) .. " " .. tostring(spell.menuslot),
				true
			)
		end
	end
end
menu.misc:boolean("AutoSlow", "Enable auto Slow Remove", true)
menu.misc:boolean("magnet", "Use E -> Magnet", true)
menu.misc:boolean("under", "^~ Not use under the tower", true)

menu.misc:header("flee", "Flee - Settings")
menu.misc:boolean("qflee", "Q in flee mode", true)
menu.misc:keybind('keybind_a', 'Flee', 'Z', nil)

menu:menu("draws", "Display - Settings")
menu.draws:boolean("e_range", "E Range", true)
menu.draws:boolean("r_range", "R Range", true)

local targetSelector = function(res, obj, dist)
    if dist > menu.combo['Distance']:get() then 
        return 
    end 
  
    if common.IsEnemyMortal(obj) then 
        res.obj = obj
        return true
    end 
end 

local r_damage = function(target)
    if not target then 
      return 
    end 

    if player:spellSlot(3).level == 0 then 
      return 0 
    end 

    local damage = 0 
    if player:spellSlot(3).level > 0 then 
        if not target.buff['gareneshred'] then 
            damage = ({150, 300, 450})[player:spellSlot(3).level] + ({0.2, 0.250, 0.3})[player:spellSlot(3).level] * (target.maxHealth - target.health)
        elseif target.buff['gareneshred']  then 
            local bonus = ({1, 2, 3, 4, 5, 6, 7, 8, 8.25, 8.5, 8.75, 9, 9.25, 9.5, 9.75, 10, 10.25})[player.levelRef - 1] + ({0.4, 0.425, 0.45, 0.475, 0.5})[player:spellSlot(2).level] * common.GetTotalAD()
            damage = (({150, 300, 450})[player:spellSlot(3).level] + ({0.2, 0.250, 0.3})[player:spellSlot(3).level] * (target.maxHealth - target.health)) + bonus
        end 
    end   

    if damage <= 0 then 
      return 0 
    end 

    return common.CalculateMagicDamage(target, damage, player)
end 

local combo = function()
    if target and target ~= nil and common.IsValidTarget(target) then 

        if menu.combo['useQ']:get() and player:spellSlot(0).state == 0 and not player.buff['garene'] then 
            if ((common.GetDistanceSqr(player, target) / (player.moveSpeed * 1.3)) * 1000 < 1300 ^ 2) then 
                player:castSpell('self', 0, player)
                common.DelayAction(function() if target then player:attack(target) end end, (menu.combo['delayAA']:get() * 0.001)) 
            end 
        end 

        if menu.combo['useW']:get() and player:spellSlot(1).state == 0 then 
            if common.GetDistanceSqr(target, player) <= menu.combo['Distance']:get() ^ 2 then 
                player:castSpell('self', 1, player)
            end 
        end 

        if menu.combo['useE']:get() and player:spellSlot(2).state == 0 and not (player.buff['garene'] or player.buff['garenq']) and not player.buff['garenq'] then 

            if player:spellSlot(0).state == 0 and menu.combo['E.Status']:get() then 
                return 
            end 

            if common.GetDistance(player, target) < ((350) + player.boundingRadius) then 
                player:castSpell('self', 2)
            end 
        end 

        if menu.combo['user']:get() and player:spellSlot(3).state == 0 and common.GetDistanceSqr(player, target) <= 400 ^ 2 then 
            if menu.combo['whitelist'][target.charName] and menu.combo['whitelist'][target.charName]:get() then 
                if r_damage(target) >= common.GetShieldedHealth("AP", target) then 

                    if common.GetDistanceSqr(player, target) < 400 ^ 2 and player:spellSlot(0).state == 0 then 
                        if common.GetPercentHealth(target) < 15 then 
                            return 
                        end 
                    end 

                    player:castSpell('obj', 3, target)
                end 
            end 
        end 
    end 
end 

local EnableSlow = function()
    if player.isDead then 
        return 
    end 

    if player.buff[17] then 
        return 
    end 

    if menu.misc['AutoSlow']:get() then 
        if player:spellSlot(0).state == 0 then 
            if player.buff[BUFF_SLOW] then 
                player:castSpell('self', 0)
            end 
        end 
    end 
end 

local magnet = function()
    if not player.buff['garene'] then 
        return 
    end 

    if not target then 
        return 
    end 

    local endPos = (GeoLib.Vector:new(player) - GeoLib.Vector:new(target)):normalized()
    local res = module.internal("pred").core.lerp(target.path, 0.25, target.moveSpeed)
    if not res then 
        return
    end 
    local predPos = vec3(res.x + endPos.x, target.y, res.y + endPos.z)
    if predPos and not navmesh.isWall(predPos) then 
        if (not menu.misc['under']:get() or not common.IsUnderDangerousTower(predPos))  then 
            player:move(predPos)
        end 
    end
end 

local KillSteal = function()
    local enemy = common.GetEnemyHeroes()
    for i, target in ipairs(enemy) do

        if target and target ~= nil and common.IsEnemyMortal(target) and common.IsValidTarget(target) then 
            if menu.misc['rkill']:get() and player:spellSlot(3).state == 0 and common.GetDistance(player, target) <= 400  then 
                if r_damage(target) >= common.GetShieldedHealth("AP", target) then
                    print'jidlsdla' 
                    player:castSpell('obj', 3, target)
                end 
            end
        end 
    end 
end 

local on_tick = function()
    if player.isDead then 
        return 
    end 

    KillSteal()
    if player.buff['garene'] then 
        orb.core.set_pause_attack(math.huge)
    else 
        orb.core.set_pause_attack(0)
    end 

    target = TS.get_result(targetSelector).obj
    --target.buff['gareneshred'] 

    if orb.menu.combat.key:get() then 
        combo()
    end 

    --Magnet 
    if menu.misc['magnet']:get() then 
        magnet()
    end 

    --Flee 
    if menu.misc['keybind_a']:get() then 
        player:move(game.mousePos)

        if menu.misc['qflee']:get() and player:spellSlot(0).state == 0 then 
            player:castSpell('self', 0)
        end 
    end 

    --Slow
    EnableSlow()
end 

local on_draw = function()
    if player.isDead then 
        return 
    end 

    if player.buff[17] then 
        return 
    end 

    if not player.isOnScreen then 
        return 
    end 

    if menu.draws['e_range']:get() and player:spellSlot(2).state == 0 then 
        local range = 0 
        range = (325) + player.boundingRadius 

        graphics.draw_circle_xyz(player.x, player.y, player.z, range, 1, graphics.argb(255, 255, 255, 197), 95)
    end 

    if menu.draws['r_range']:get() and player:spellSlot(3).state == 0 then 
        graphics.draw_circle_xyz(player.x, player.y, player.z, 400, 1, graphics.argb(255, 255, 255, 197), 95)
    end 
end 

orb.combat.register_f_pre_tick(on_tick)
cb.add(cb.draw, on_draw)