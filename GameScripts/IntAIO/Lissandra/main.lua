local orb = module.internal("orb");
local menu = module.load(header.id, 'Core/Lissandra/menu');
local e = module.load(header.id, 'Core/Lissandra/spells/e');
local q = module.load(header.id, 'Core/Lissandra/spells/q');
local r = module.load(header.id, 'Core/Lissandra/spells/r');
local w = module.load(header.id, 'Core/Lissandra/spells/w');
local core = module.load(header.id, 'Core/Lissandra/core');
--[[
    Ranges:

    Q - 725 / 825
    W - 450
    E - 1025
    R - 550
    lissandrae buff
]]

local function on_combat_tick()
    core.get_action_core()
end 
orb.combat.register_f_pre_tick(on_combat_tick)

cb.add(cb.create_missile, function(obj)
    e.create_missile(obj)
end)

cb.add(cb.delete_missile, function(obj)
    e.delete_missile(obj)
end)

local function OnDraw()
    if (player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        q.on_draw();
        w.on_draw();
        e.on_draw();
        r.on_draw();
    end
end
cb.add(cb.draw, OnDraw)

local function on_recv_spell(spell)
    if spell.owner.ptr == player.ptr then
        core.on_recv_spell(spell)
        e.spell_end(spell)
        r.spell_interupt(spell)
    end
end
cb.add(cb.spell, on_recv_spell)
return { }