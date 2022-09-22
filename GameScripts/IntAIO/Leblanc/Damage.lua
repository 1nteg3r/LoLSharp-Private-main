local Dano = { }

local function GetTotalAD(obj)
    local obj = obj or player
    return (obj.baseAttackDamage + obj.flatPhysicalDamageMod) * obj.percentPhysicalDamageMod
end 

local function GetBonusAD(obj)
    local obj = obj or player
    return ((obj.baseAttackDamage + obj.flatPhysicalDamageMod) * obj.percentPhysicalDamageMod) - obj.baseAttackDamage
end
  
local function GetTotalAP(obj)
    local obj = obj or player
    return obj.flatMagicDamageMod * obj.percentMagicDamageMod
end

local function MagicReduction(target, damageSource)
    local damageSource = damageSource or player
    local magicResist = (target.spellBlock * damageSource.percentMagicPenetration) - damageSource.flatMagicPenetration
    return magicResist >= 0 and (100 / (100 + magicResist)) or (2 - (100 / (100 - magicResist)))
end

local function PhysicalReduction(target, damageSource)
    local damageSource = damageSource or player
    local armor = ((target.bonusArmor * damageSource.percentBonusArmorPenetration) + (target.armor - target.bonusArmor)) * damageSource.percentArmorPenetration
    local lethality = (damageSource.physicalLethality * .4) + ((damageSource.physicalLethality * .6) * (damageSource.levelRef / 18))
    return armor >= 0 and (100 / (100 + (armor - lethality))) or (2 - (100 / (100 - (armor - lethality))))
end
  
local function DamageReduction(damageType, target, damageSource)
    local damageSource = damageSource or player
    local reduction = 1
    if damageType == "AD" then
    end
    if damageType == "AP" then
    end
    return reduction
end

local function CalculateMagicDamage(target, damage, damageSource)
    local damageSource = damageSource or player
    if target then
      return (damage * MagicReduction(target, damageSource)) * DamageReduction("AP", target, damageSource)
    end
    return 0
end

function Dano.GetAutoAttackDamage(target, damageSource)
    local damageSource = damageSource or player
    if target then
      return GetTotalAD(damageSource) * PhysicalReduction(target, damageSource)
    end
    return 0
end

function Dano.GetIgniteDamage(target)
    local damage = 55 + (25 * player.levelRef)
    if target then
        damage = damage - (GetShieldedHealth("AD", target) - target.health)
    end
    return damage
end 

function Dano.DamageQ(target)
    if target ~= 0 then
		local Damage = 0
		local DamageAP = {55, 80, 105, 130, 155}
        if player:spellSlot(0).state == 0 then
			Damage = (DamageAP[player:spellSlot(0).level] + (GetTotalAP() * .4))
        end
		return CalculateMagicDamage(target, Damage)
	end
	return 0
end

function Dano.DamageW(target)
    if target ~= 0 then
		local Damage = 0
		local DamageSpell = {85, 125, 165, 205, 245}

        if player:spellSlot(1).state == 0 then
			Damage = (DamageSpell[player:spellSlot(1).level] + (GetTotalAP() * .6))
        end
		return CalculateMagicDamage(target, Damage)
	end
	return 0
end

function Dano.DamageE(target)
    if target ~= 0 then
		local Damage = 0
		local DamageSpell = {40, 60, 80, 100, 120}

        if player:spellSlot(2).state == 0 then
			Damage = (DamageSpell[player:spellSlot(2).level] + (GetTotalAP() * .3))
        end
		return CalculateMagicDamage(target, Damage)
	end
	return 0
end

function Dano.DamageRQ(target)
    if target ~= 0 then
        local Damage = 0
        local DamageAP = {70, 140, 210}
        if player:spellSlot(3).level > 0 and player:spellSlot(3).name == "LeblancRQ" and player:spellSlot(3).state == 0 then
			Damage = (DamageAP[player:spellSlot(3).level] + (GetTotalAP() * .4))
        end
		return CalculateMagicDamage(target, Damage)
	end
	return 0
end

function Dano.DamageRW(target)
    if target ~= 0 then
        local Damage = 0
        local DamageAP =  {150, 300, 450}
        if player:spellSlot(3).level > 0 and player:spellSlot(3).name == "LeblancRW" and player:spellSlot(3).state == 0 then
			Damage = (DamageAP[player:spellSlot(3).level] + (GetTotalAP() * .75))
        end
		return CalculateMagicDamage(target, Damage)
	end
	return 0
end
function Dano.DamageRE(target)
    if target ~= 0 then
        local Damage = 0
        local DamageAP = {70, 140, 210}
        if player:spellSlot(3).level > 0  and player:spellSlot(3).name == "LeblancRE" and player:spellSlot(3).state == 0 then
			Damage = (DamageAP[player:spellSlot(3).level] + (GetTotalAP() * .4))
        end
		return CalculateMagicDamage(target, Damage)
	end
	return 0
end


function Dano.GetTotalDamage(target)
    local Dmg = Dano.DamageQ(target)+Dano.DamageE(target)+Dano.DamageW(target)+Dano.DamageRQ(target)+Dano.DamageRW(target)+Dano.DamageRE(target)
    return Dmg
end

function Dano.DrawDamage(hero)
    if hero.isOnScreen and hero and not hero.isDead and hero.isVisible and hero.isTargetable and not hero.buff[17] then 
        local barPos = hero.barPos                   
        local percentHealthAfterDamage = math.max(0, hero.health - (Dano.GetTotalDamage(hero))) / hero.maxHealth
        graphics.draw_line_2D(barPos.x + 165 + 103 * hero.health/hero.maxHealth, barPos.y+123, barPos.x + 165 + 100 * percentHealthAfterDamage, barPos.y+123, 11, graphics.argb(255, 255, 0, 255))        
    end
end

return Dano
