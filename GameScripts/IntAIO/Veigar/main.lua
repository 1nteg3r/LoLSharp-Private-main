local orb = module.internal("orb");
local menu = module.load("int", "Core/Veigar/menu")
local core = module.load("int", "Core/Veigar/core")
local q = module.load("int", "Core/Veigar/spells/q")
local w = module.load("int", "Core/Veigar/spells/w")
local e = module.load("int", "Core/Veigar/spells/e")
local r = module.load("int", "Core/Veigar/spells/r")

local function on_tick()
    core.get_action_veigar()
end
orb.combat.register_f_pre_tick(on_tick)

local lastDebugPrint = 0
local function on_recv_spell(spell)
    if spell and spell.owner == player and spell.owner.type == TYPE_HERO  then
        core.on_recv_spell(spell)
    end
    --[[if(spell.owner == player) then
        if os.clock() - lastDebugPrint >= 2 then
            print("Spell name: " ..spell.name);
            print("Speed:" ..spell.static.missileSpeed);
            print("Width: " ..spell.static.lineWidth);
            print("Time:" ..spell.windUpTime);
            print('--------------------------------------');
            lastDebugPrint = os.clock();
        end
    end]]
end
cb.add(cb.spell, on_recv_spell)

local function on_draw()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        q.on_draw();
        w.on_draw();
        e.on_draw();
        r.on_draw();
    end
end
cb.add(cb.draw, on_draw)

return {}