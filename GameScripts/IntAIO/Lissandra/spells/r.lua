local common = module.load(header.id, "Library/common");
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Core/Lissandra/menu")
local orb = module.internal("orb")
local dlib = module.load(header.id, 'Library/damageLib');
local q = module.load(header.id, 'Core/Lissandra/spells/q');

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

local r = {
    slot = player:spellSlot(3), 
    last = 0,
    
    range = 505, 
    result = {
        obj = nil;
    }; 

    predinput = {
      delay = 0.375,
      radius = 550,
      dashRadius = 0,
      boundingRadiusModSource = 0,
      boundingRadiusModTarget = 0,
    }
}

r.invoke_action = function()
    player:castSpell("obj", 3, r.result)
end

r.is_ready = function()
    return r.slot.state == 0
end 

r.trace_filter = function(target)
    if menu.combo.r.ONEvONE.use:get() ~= 4 then
        local mode = menu.combo.r.ONEvONE.use:get()
        local enemies = ts.loop(function(res, obj, dist)
            if dist <= menu.combo.r.ONEvONE.range_check:get() then
                res.in_range = res.in_range and res.in_range + 1 or 1
            end
        end)

        if enemies.in_range and enemies.in_range == 1 then
            local dist_to_target = player.path.serverPos:distSqr(target.path.serverPos)
            if q.is_ready() and dist_to_target <= 700 * 700 then
                if dlib.GetSpellDamage(0, target) >= common.GetShieldedHealth("AP", target) or common.GetPercentHealth(target) < 25 then
                    return false
                end
            end

            if mode == 1 then
                return true
            end
            if mode == 2 and dlib.GetSpellDamage(3, target) >= common.GetShieldedHealth("AP", target) then
                return true
            end
        end
    end

    if menu.combo.r.ONEvONE.use:get() == 3 then
        local count = 0
        for i = 0, objManager.enemies_n - 1 do

            local enemy = objManager.enemies[i]
            if enemy and not enemy.isDead and enemy.isTargetable and enemy.isVisible then
                if player.path.serverPos:dist(enemy.path.serverPos) < (r.range - enemy.boundingRadius) then
                    count = count + 1
                end
            end
            if count == menu.combo.r.min_r:get() then
                player:castSpell('self', 3)
            end
        end
    end
end

r.get_target = function(res, obj, dist)
    if dist > 1500 or obj.buff[17] then
        return
    end
    if gpred.present.get_prediction(r.predinput, obj) then
        if menu.combo.r.whitelist[obj.charName]:get() then
            res.obj = obj
            return true
        end
    end
end
  
r.get_action_state = function()
    if r.last == game.time then
      return r.result
    end
    r.last = game.time
    r.result = nil
    
    local target = ts.get_result(r.get_target).obj
    if target and r.trace_filter(target) then
        r.result = target
        return r.result
    end 
end

r.spell_interupt = function(spell)
    for _, spellInt in pairs(Interspells) do 
        if spell and spellInt then 
            if spellInt.Name == spell.owner.charName then 
                --print("spellInt na,E")
                if spellInt.spellname == spell.name then
                    --print("spellIntRRRRR")
                    if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.owner.charName == spellInt.Name then 
                        --print("huhuhu")
                        if spell.owner.pos:dist(player.pos) < 550 then 
                            player:castSpell("obj", 3, spell.owner)
                        end
                    end     
                end 
            end 
        end 
    end
end 

r.on_draw = function()
    if menu.draws.r_range:get() and r.slot.level > 0 and r.slot.state == 0 then
        graphics.draw_circle(player.pos, r.range, menu.draws.width:get(), menu.draws.r:get(), menu.draws.numpoints:get())
    end

    local pos = graphics.world_to_screen(player.pos)
    if menu.combo.r.ONEvONE.use:get() == 1 then
        graphics.draw_text_2D("[" .. menu.combo.r.ONEvONE.switch.key .. "]Combo R Mode: Always", 18, pos.x - 125, pos.y + 65, graphics.argb(255, 0, 255, 0))
    end
    if menu.combo.r.ONEvONE.use:get() == 2 then
        graphics.draw_text_2D("[" .. menu.combo.r.ONEvONE.switch.key .. "]Combo R Mode: Killable", 18, pos.x - 125, pos.y + 65, graphics.argb(255, 0, 255, 0))
    end
    if menu.combo.r.ONEvONE.use:get() == 3 then
        graphics.draw_text_2D("[" .. menu.combo.r.ONEvONE.switch.key .. "]Combo R Mode: ".. menu.combo.r.min_r:get() .. " Enemies", 18, pos.x - 125, pos.y + 65, graphics.argb(255, 0, 255, 0))
    end
    if menu.combo.r.ONEvONE.use:get() == 4 then
        graphics.draw_text_2D("[" .. menu.combo.r.ONEvONE.switch.key .. "]Combo R Mode: Disabled", 18, pos.x - 125, pos.y + 65, graphics.argb(255, 255, 0, 0))
    end
    if menu.combo.r.ONEvONE.use:get() == 5 then
        graphics.draw_text_2D("[" .. menu.combo.r.ONEvONE.switch.key .. "]Combo R Mode: Stun", 18, pos.x - 125, pos.y + 65, graphics.argb(255, 255, 0, 0))
    end
end 


return r 