local evade = module.seek("evade");
local TS = module.internal("TS");
local orb = module.internal("orb");
local common = module.load("int", "Library/common");


local card = nil;
local picking = false;
local Lastpick = 0;
local enemies = nil;

local menu = menu("int", "Int TwistedFate");

menu:header("xs", "Core");
menu:menu("combo", "Combo");
menu.combo:boolean("q", "Use Q", true);
menu.combo:dropdown('modeq', '^ Use Q', 2, {'Never', 'IsImmobile', 'Always'});
menu.combo:boolean("w", "Use W", true);
menu.combo:header("xss", "Pick Card");
menu.combo:boolean("r", "Pick Gold Card in Ult", true); 
menu.combo:keybind("cardgold", "Flee - Using card", "Z", nil);
menu.combo:dropdown('cardmode', '^ Use Card:', 2, {'Red', 'Gold', 'Blue'});

menu:menu('harass', "Harass");
menu.harass:boolean("w", "Use W", true);
menu.harass:slider("mana", "Control Mana: > %", 15, 0, 100, 1);

menu:menu("dis", "Display");
menu.dis:boolean("qd", "Q Range", true);
menu.dis:boolean("rd", "R Range - Minimap", true);

--Pink card 
local function PickingCard(card) --select card
    if picking == false then 
        card = card;
        Lastpick = game.time;
        player:castSpell("self", 1);
    end
end

local function CanPickCard() 
    return picking == false and game.time - Lastpick >= 0  
end 

local function AutoSelect()
    --Selectin Card spell
    if player.buff["pickacard_tracker"] then
        picking = true
        local spellName = player:spellSlot(1).name 
        if spellName:lower(card) then
            player:castSpell("self", 1);       
        end
    else
        picking = false
    end 
    --Pick card in ult
    if (menu.combo.r:get()) then 
        if (player.buff['gate'] and CanPickCard()) then 
            PickingCard("Gold")
        end
    end 
end

cb.add(cb.tick, function()
    if (player.isDead and player.isRecalling) then return end 



    enemies = TS.get_result(function(res, obj, dist)
        if dist < 1450 and common.IsValidTarget(obj) then --add invulnverabilty check
            res.obj = obj
            return true
        end
    end).obj

    AutoSelect();
    --Flee 
    if menu.combo.cardgold:get() then 
        --Selec menu why card. 
        local modecard = menu.combo.cardmode:get();
        if (modecard == 1 and CanPickCard()) then --Red
            PickingCard("red");
        elseif (modecard == 2 and CanPickCard()) then --Gold
            PickingCard("gold");
        elseif (modecard == 3 and CanPickCard() or (player.mana/player.maxMana * 100 <= 20)) then --Blue
            PickingCard("blue");
        end
        player:move(mousePos)
    end
end)

cb.add(cb.draw, function()
    if (player and player.isDead and not player.isTargetable and  player.buff[17]) then return end
    if (player.isOnScreen) then
        if (menu.dis.qd:get() and player:spellSlot(0).state == 0) then
            graphics.draw_circle(player.pos, 1450, 2, graphics.argb(255, 255, 255, 255), 100)
        end

        --for i, target in pairs(enemies) do 
            if (enemies and common.IsValidTarget(enemies)) then 
                graphics.draw_circle(enemies.pos, 75, 2, graphics.argb(255, 255, 255, 255), 100)
            end
        --end
    end
    if (menu.dis.rd:get() and player:spellSlot(3).state == 0) then
        minimap.draw_circle(player.pos, 5500, 1, graphics.argb(255, 255, 255, 255), 100)
    end
end)

local function OnTick() 

end

orb.combat.register_f_pre_tick(OnTick)