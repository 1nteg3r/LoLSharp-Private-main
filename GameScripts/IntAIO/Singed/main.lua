local orb = module.internal("orb")
local common = module.load("int", "Library/common");
local TS = module.load("int", "TargetSelector/targetSelector");
local HanbotTarget = module.internal("TS");
local pred = module.internal("pred");
local damageLib = module.load('int', 'Library/damageLib');

local isRiot = hanbot.language == 2;

local spellQ = {
	range = 1000,
	radius = 200,
	speed = math.huge,
	boundingRadiusMod = 0,
	delay = 0.25
}

local Interspells = { --ty Deftsu
    ["CaitlynAceintheHole"]         = {Name = "Caitlyn",      displayname = "R | Ace in the Hole", spellname = "CaitlynAceintheHole"},
    ["Crowstorm"]                   = {Name = "FiddleSticks", displayname = "R | Crowstorm", spellname = "Crowstorm"},
    ["DrainChannel"]                = {Name = "FiddleSticks", displayname = "W | Drain", spellname = "DrainChannel"},
    ["GalioIdolOfDurand"]           = {Name = "Galio",        displayname = "R | Idol of Durand", spellname = "GalioIdolOfDurand"},
    ["ReapTheWhirlwind"]            = {Name = "Janna",        displayname = "R | Monsoon", spellname = "ReapTheWhirlwind"},
    ["KarthusFallenOne"]            = {Name = "Karthus",      displayname = "R | Requiem", spellname = "KarthusFallenOne"},
    ["KatarinaR"]                   = {Name = "Katarina",     displayname = "R | Death Lotus", spellname = "KatarinaR"},
    ["LucianR"]                     = {Name = "Lucian",       displayname = "R | The Culling", spellname = "LucianR"},
    ["AlZaharNetherGrasp"]          = {Name = "Malzahar",     displayname = "R | Nether Grasp", spellname = "AlZaharNetherGrasp"},
    ["Meditate"]                    = {Name = "MasterYi",     displayname = "W | Meditate", spellname = "Meditate"},
    ["MissFortuneBulletTime"]       = {Name = "MissFortune",  displayname = "R | Bullet Time", spellname = "MissFortuneBulletTime"},
    ["AbsoluteZero"]                = {Name = "Nunu",         displayname = "R | Absoulte Zero", spellname = "AbsoluteZero"},
    ["PantheonRJump"]               = {Name = "Pantheon",     displayname = "R | Jump", spellname = "PantheonRJump"},
    ["PantheonRFall"]               = {Name = "Pantheon",     displayname = "R | Fall", spellname = "PantheonRFall"},
    ["ShenStandUnited"]             = {Name = "Shen",         displayname = "R | Stand United", spellname = "ShenStandUnited"},
    ["Destiny"]                     = {Name = "TwistedFate",  displayname = "R | Destiny", spellname = "Destiny"},
    ["UrgotSwap2"]                  = {Name = "Urgot",        displayname = "R | Hyper-Kinetic Position Reverser", spellname = "UrgotSwap2"},
    ["VarusQ"]                      = {Name = "Varus",        displayname = "Q | Piercing Arrow", spellname = "VarusQ"},
    ["VelkozR"]                     = {Name = "Velkoz",       displayname = "R | Lifeform Disintegration Ray", spellname = "VelkozR"},
    ["InfiniteDuress"]              = {Name = "Warwick",      displayname = "R | Infinite Duress", spellname = "InfiniteDuress"},
    ["XerathLocusOfPower2"]         = {Name = "Xerath",       displayname = "R | Rite of the Arcane", spellname = "XerathLocusOfPower2"}
}

local menu = menu("intSinged", "Int Singed");
    menu:header("xs", "Core");
    TS = TS(menu, 1000)
    TS:addToMenu()
    menu:boolean('q', 'Use Q', true);
    menu:boolean('off', 'Auto Disable Q', false);
    menu:boolean('w', 'Use W', true);
    menu:boolean('gab', '^ Throw back gapclosers', true);
    menu:header("headE", "E - Setting");
    menu:boolean('e', 'Use E', true);
    for i, enemy in pairs(common.GetEnemyHeroes()) do 
        if enemy then 
            for _, spell in pairs(Interspells) do 
                if enemy and spell then 
                    if spell.Name == enemy.charName then 
                        menu:menu('eset', 'Interrupt Spells - E')
                        if spell.displayer == "" then
                            spell.displayer = _
                        end
                        menu.eset:menu(i, enemy.charName.. ' || '.. _);
                        menu.eset[i]:boolean('inter', "Interrupt Spell: ".. spell.displayname, true);
                    end
                end 
            end 
        end 
    end
    menu:header("headdE", "R - Setting");
    menu:menu("ult", "Ultimate - R");
    menu.ult:boolean('r', 'Use R', true);
    menu.ult:slider("enemy", "Enemies in Range >= {0}", 2, 1, 5, 1);
    --Draws
    menu:menu("ddd", "Display");
    menu.ddd:boolean("wd", "W Range", true);
    menu.ddd:boolean("ed", "E Range", true);


local is_facing = function(unit, target)
    return unit.path.serverPos:distSqr(target.path.serverPos) > unit.path.serverPos:distSqr(target.path.serverPos + target.direction)
end
  

local function on_combat_tick()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end

   --[[ if player.buff['poisontrail'] then 
        print('fffffff')
    end]]
    if menu.gab:get() then 
        if player:spellSlot(1).state == 0 then 
                local target = HanbotTarget.get_result(
		        function(res, obj, dist)
			    if dist <= 1100 and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
				    res.obj = obj
				    return true
                end  
            end).obj
	        if target then
                local pred_pos = pred.core.lerp(target.path, network.latency + 0.25, target.path.dashSpeed)
                if pred_pos and pred_pos:dist(player.path.serverPos2D) <= 1000 then
                    player:castSpell("pos", 1, vec3(pred_pos.x, target.y, pred_pos.y))
                end
	        end
        end
    end

    if (orb.menu.combat:get()) then
        local qTarget = HanbotTarget.get_result(
            function(res, obj, dist)
            if common.IsValidTarget(obj) and obj.pos:dist(player) <= 200 and is_facing(obj, player)
            and not is_facing(player, obj) and player.path.isActive and obj.path.isActive then --add invulnverabilty check
                res.obj = obj
                return true
            end  
        end).obj

        if qTarget and (qTarget ~= nil or qTarget.buff['poisontrailtarget'] or  qTarget.pos:dist(player) <= 500) then 
            if menu.q:get() then 
                if not player.buff['poisontrail'] and player:spellSlot(0).state == 0 then 
                    player:castSpell("self", 0) 
                end 
            end
        end

        local target = TS.target 

        if target then 
            local res = pred.circular.get_prediction(spellQ, target)
            if res and res.startPos:dist(res.endPos) < 1000 then
                if menu.w:get() and player:spellSlot(1).state == 0 then 
                    player:castSpell("pos", 1, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
                end
            end

            if player:spellSlot(3).state == 0 and menu.ult.r:get() and (player.health / player.maxHealth * 100) > 30
            and #common.CountEnemiesInRange(player.pos, 750) >= menu.ult.enemy:get() and
            (player.mana - player.manaCost2 + player.manaCost3) then 
                player:castSpell("self", 3) 
            end

            local towerPos = target.pos + (player.pos - target.pos):norm() * 500
            local allies = common.GetAllyHeroes()
            if player:spellSlot(2).state == 0 and menu.e:get() and (#common.CountAllysInRange(towerPos, 700) > #common.CountAllysInRange(target.pos, 700) and 
            damageLib.GetSpellDamage(0, target) > target.health or not target.buff['poisontrailtarget']) and not common.UnderDangerousTower(towerPos) then 
                if target.pos:dist(player.pos) <= 130 then
                    player:castSpell("obj", 2, target) 
                end
            end
        end 
    end
    if player.buff['poisontrail'] and player:spellSlot(0).state == 0 and menu.off:get() then 
        if #common.CountEnemiesInRange(player.pos, 1500) == 0 then  player:castSpell("self", 0)  end
    end
    local enemy = common.GetEnemyHeroes()
    for i, Target in ipairs(enemy) do
        if Target and common.IsValidTarget(Target) then 
            local hp = common.GetShieldedHealth("ap", Target)
            if (Target.path.serverPos2D:dist(player.path.serverPos2D) < 130) then
               if damageLib.GetSpellDamage(2, Target)  > hp then 
                    player:castSpell("obj", 2, Target) 
                end
            end
        end
    end

    --[[     local hp = common.GetShieldedHealth("ap", target)
            if (target.path.serverPos2D:dist(player.path.serverPos2D) < spellQ.range) then ]]
end 
orb.combat.register_f_pre_tick(on_combat_tick)

local function on_process_spell(spell)
    for _, spellInt in pairs(Interspells) do 
        if spell and spellInt then 
            if spellInt.Name == spell.owner.charName then 
                if spellInt.spellname == spell.name then
                    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.owner.charName == spellInt.Name then 
                        if spell.owner.pos:dist(player) <= 130 then
                            player:castSpell("obj", 2, spell.owner)
                        end
                    end
                end
            end 
        end 
    end
end 
cb.add(cb.spell, on_process_spell)

local function OnDraw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (player:spellSlot(2).state == 0 and menu.ddd.ed:get()) then 
            graphics.draw_circle(player.pos, 135, 1, graphics.argb(255, 145, 70, 197), 30)
        end
        if (player:spellSlot(1).state == 0 and menu.ddd.wd:get()) then 
            graphics.draw_circle(player.pos, 1000, 1, graphics.argb(255, 145, 70, 197), 30)
        end
    end 
end
cb.add(cb.draw, OnDraw)
