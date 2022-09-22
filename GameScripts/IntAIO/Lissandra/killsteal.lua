local common = module.load(header.id, "Library/common");
local dlib = module.load(header.id, 'Library/damageLib');
local e = module.load("int", "Core/Lissandra/spells/e")

local killsteal = { }
local jump = false 
killsteal.KillSteal = function()
    local enemy = common.GetEnemyHeroes()
    for i, enemies in ipairs(enemy) do
        if enemies and common.IsValidTarget(enemies) and common.IsEnemyMortal(enemies) then

            if enemies.pos:dist(player.pos) < 1300 + 725 and (dlib.GetSpellDamage(0, enemies) or dlib.GetSpellDamage(1, enemies) or dlib.GetSpellDamage(3, enemies)) >= common.GetShieldedHealth("AP", enemies) then 
                if not player.buff['lissandrae'] then 
                    player:castSpell('pos', 2, enemies.pos)
                    jump = true
                else
                    for i, object in pairs(e.Missile) do 
                        if object and (object.pos:dist(e.missilepos)) <= 100 and player.buff['lissandrae'] and enemies.pos:dist(player) > enemies.pos:dist(e.missilepos)  and object.pos:dist(enemies.pos) <= 600 and jump then
                            player:castSpell('self', 2) 
                            jump = false
                        end 
                    end
                end 
            end 
        end 
    end 
end

return killsteal