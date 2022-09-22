local common = module.load("int", "Library/util");

local function q_damage(target)
    local damage = 0 
    if (player:spellSlot(0).level > 0) then 
        damage = common.calculateMagicalDamage(target, (1.2 * common.getTotalAD()) + (0.9 * common.getTotalAP()) + ({0.06,0.07,0.08,0.09,0.1})[player:spellSlot(0).level] * target.maxHealth)
    end 
    return damage 
end 

return {
    q_damage = q_damage
}