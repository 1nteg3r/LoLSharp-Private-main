#include "CObject.h"
#include <cmath>
#include "XorString.h"

float CalcPhysicalDamageToMinion(CObject* source, CObject* target, int amount, int time = 0)
{
	auto ar = target->Armor() * source->ArmorPenPercent() -
		(source->ArmorPen() * (0.6 + (0.4 * (target->Level() / 18))));
	auto val = ar < 0 ? 2 - 100 / (100 - ar) : 100 / (100 + ar);
	return std::max(0.0, floor(val * amount) - 5 * time);
}



struct DamageInput
{
	float RawPhysicalDamage = 0;
	float RawMagicalDamage = 0;
	float RawTrueDamage = 0;
	bool AppliesOnHitDamage = false;
	bool IsAutoAttack = false;
	bool IsAbility = false;
	bool DontIncludePassives = false;
	bool DontCalculateItemDamage = false;
	bool IsOnHitDamage = false;
	bool DoesntTriggerOnHitEffects = false;
	bool IsCriticalAttack = false;
};
enum class SpellSlot
{
	Invalid = -1,
	Q = 0,
	W,
	E,
	R,
	Summoner1,
	Summoner2,
	Item_1,
	Item_2,
	Item_3,
	Item_4,
	Item_5,
	Item_6,
	Trinket,
	Recall,
	AA
};
struct PerkList
{
	bool PressTheAttack = true;
	bool GraspOfTheUndying = true;
	bool DarkHarvest = true;
	bool Predator = true;
	bool SummonAery = true;
	bool CheapShot = true;
	bool CoupDeGrace = true;
	bool CutDown = true;
	bool BonePlating = true;
};
struct ItemList
{
	float LastUpdateTime;

	bool Dead_Mans_Plate;
	bool Infinity_Edge;
	bool Randuins_Omen;
	bool Blade_of_the_Ruined_King;
	bool Guinsoos_Rageblade;
	bool Nashors_Tooth;
	bool Wits_End;
	bool Skirmishers_Sabre_Enchantment_Bloodrazor;
	bool Stalkers_Blade_Enchantment_Bloodrazor;
	bool Recurve_Bow;
	bool Sheen;
	bool Iceborn_Gauntlet;
	bool Lich_Bane;
	bool Trinity_Force;
	bool Duskblade_of_Draktharr;
	bool Titanic_Hydra;
	bool Statikk_Shiv;
	bool Kircheis_Shard;
	bool Rapid_Firecannon;
	bool Hunters_Machete_Upgraded;
	bool Hunters_Machete;
	bool Guardians_Horn;
	bool Ninja_Tabi;
	bool Muramana;
};
float GetRiotScalar(float min_scalar, float max_scalar, float current_scalar, float min_value, float max_value)
{
	return fmin(max_value, fmax(min_value, ((current_scalar - min_scalar) / (max_scalar - min_scalar) * (min_value - max_value) - min_value) * -1));
}
auto const get_spell_damage_table = [](float const& first, float const& step, int const& level) -> float
{
	return first + step * level;
};
PerkList* GetPerks(CObject* hero)
{
	PerkList* perks;

	return perks;
}
ItemList* GetItems(CObject* hero)
{
	ItemList* perks;

	return perks;
}
float GetSpellDamage(CObject* source, CObject* target, SpellSlot slot, bool return_raw_damage = false, bool isready = true)
{
	auto spellslot = source->GetSpellBook()->GetSpellSlotByID((int)slot);
	if (isready && slot != SpellSlot::AA)
	{
		if (!spellslot->IsReady())
			return 0;
	}

	DamageInput input;
	int buffcount;
	if (slot == SpellSlot::AA)
		input.RawPhysicalDamage = source->TotalAttackDamage();

	auto spell_level = spellslot->Level() - 1;
	auto me_level = me->Level();

	auto champnamehash = source->ChampionNameHash();
	switch (champnamehash)
	{
	case FNV("Aatrox"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(30, 20, spell_level) + (0.55 + 0.05 * spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(30, 10, spell_level) + 0.4 * source->BonusAttackDamage();
			break;
		}
		break; }

	case FNV("Ahri"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(40, 25, spell_level) + 0.35 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(40, 25, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.35 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Akali"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(25, 25, spell_level) + 0.65 * source->TotalAttackDamage() + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(40, 70, spell_level) + 0.35 * source->TotalAttackDamage() + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(85, 65, spell_level) + 0.5 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Alistar"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(55, 55, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(8, 3, spell_level) + 0.04 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Amumu"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 50, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(5, 2.5, spell_level);
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(75, 25, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Anivia"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 25, spell_level) + 0.45 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(50, 25, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(40, 60, spell_level) + 0.125 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Annie"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 35, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 45, spell_level) + 0.85 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(20, 10, spell_level) + 0.2 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 125, spell_level) + 0.65 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Ashe"):
	{
		switch (slot)
		{
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(20, 15, spell_level) + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(200, 200, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }

	case FNV("AurelionSol"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.65 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Azir"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 20, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 75, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Bard"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 45, spell_level) + 0.65 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Blitzcrank"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 55, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(250, 125, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Brand"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 30, spell_level) + 0.55 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(75, 45, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 25, spell_level) + 0.45 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 100, spell_level) + 0.25 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Braum"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.025 * source->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Caitlyn"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(50, 40, spell_level) + get_spell_damage_table(1.3f, 0.1f, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + get_spell_damage_table(0.4, 0.05, spell_level) * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(250, 225, spell_level) + 2 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Cassiopeia"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(75, 35, spell_level) + 0.9f * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(20, 5, spell_level) + 0.15 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = 48 + 4 * source->Level() + 0.1 * source->TotalAbilityPower();

			if (target->GetBuffManager()->HasBuffType(BuffType::Poison))
				input.RawMagicalDamage += get_spell_damage_table(10, 20, spell_level) + 0.6 * source->TotalAbilityPower();

			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Camille"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(0.2f, 0.05f, spell_level) * source->TotalAttackDamage() + source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(70, 30, spell_level) + 0.6 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 35, spell_level) + 0.75 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Chogath"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 55, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(75, 50, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(22, 12, spell_level) + 0.3 * source->TotalAbilityPower() + 0.03 * target->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawTrueDamage = get_spell_damage_table(300, 175, spell_level) + 0.5 * source->TotalAbilityPower(); // + 0.1 bonus HP
			break;
		}
		break; }
	case FNV("Corki"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(75, 45, spell_level) + 0.5 * source->BonusAttackDamage() + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = (get_spell_damage_table(7.5, 3.125, spell_level) + 0.1 * source->BonusAttackDamage()) * 0.5;
			input.RawMagicalDamage = (get_spell_damage_table(7.5, 3.125, spell_level) + 0.1 * source->BonusAttackDamage()) * 0.5;
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(90, 25, spell_level) + get_spell_damage_table(0.15f, 0.3f, spell_level) * source->TotalAttackDamage() + 0.2 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Darius"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(50, 30, spell_level) + get_spell_damage_table(1.f, 0.1f, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(0.5, 0.05, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::R:
			input.RawTrueDamage = get_spell_damage_table(100, 100, spell_level) + 0.75 * source->BonusAttackDamage();
			auto count = 0;

			if (!source->GetSpellBook()->GetSpellSlotByID(0)->IsReady() && !me->GetSpellBook()->GetSpellSlotByID(1)->IsReady())
				count = 2;

			if (!source->GetSpellBook()->GetSpellSlotByID(0)->IsReady() && !me->GetSpellBook()->GetSpellSlotByID(1)->IsReady() && !me->GetSpellBook()->GetSpellSlotByID(2)->IsReady())
				count = 3;

			if (target->HasBuff("dariushemomax"))
				count = 5;

			input.RawTrueDamage = input.RawTrueDamage * (1 + .2 * count);


			break;
		}
		break; }
	case FNV("Diana"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 35, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(18, 12, spell_level) + 0.15 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(40, 20, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(200, 100, spell_level) + 0.6 * source->TotalAbilityPower();// +get_spell_damage_table(35, 25, spell_level) * CountEnemyHeroes(source, 475) + 0.15 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Draven"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(35, 5, spell_level) + get_spell_damage_table(0.65f, 0.1f, spell_level) * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(75, 35, spell_level) + 0.5 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(175, 100, spell_level) + 1.1 * source->BonusAttackDamage();
			break;
		}
		break; }

	case FNV("DrMundo"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = fmax(get_spell_damage_table(80, 50, spell_level), get_spell_damage_table(0.15f, 0.025f, spell_level) * target->Health());

			if (target->IsMinion())//|| target->IsMinion())
				input.RawMagicalDamage = fmin(get_spell_damage_table(300, 50, spell_level), input.RawMagicalDamage);

			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(20, 7.5, spell_level) + 0.1 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(0.03, 0.005, spell_level) * source->MaxHealth();
			break;
		}
		break; }
	case FNV("Ekko"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 15, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(40, 25, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 150, spell_level) + 1.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Elise"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(40, 35, spell_level) + 0.04 * target->Health();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 50, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(10, 10, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Evelynn"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(25, 15, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.AppliesOnHitDamage = TRUE;
			input.RawPhysicalDamage = get_spell_damage_table(75, 25, spell_level) + 0.04 * target->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(125, 125, spell_level) + 0.75 * source->TotalAbilityPower();

			if (target->HealthPercent() < 30)
				input.RawMagicalDamage = input.RawMagicalDamage * 2;

			break;
		}
		break; }
	case FNV("Ezreal"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.AppliesOnHitDamage = TRUE;
			input.RawPhysicalDamage = get_spell_damage_table(20, 25, spell_level) + 1.3f * source->TotalAttackDamage() + 0.15f * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(80, 55, spell_level) + 0.6f * source->BonusAttackDamage() + get_spell_damage_table(0.7f, 0.05f, spell_level) * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 50, spell_level) + 0.75f * source->TotalAbilityPower() + 0.5f * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(350, 150, spell_level) + 1.f * source->BonusAttackDamage() + 0.9f * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Fiddlesticks"):
	{
		switch (slot)
		{
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(400, 125, spell_level) + 2.25 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(65, 20, spell_level) + 0.45 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(625, 500, spell_level) + 2.25 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Fiora"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.AppliesOnHitDamage = TRUE;
			input.RawPhysicalDamage = get_spell_damage_table(65, 10, spell_level) + get_spell_damage_table(0.95f, 0.05000001f, spell_level) * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(90, 40, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Fizz"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(10, 15, spell_level) + 0.55 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(20, 10, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 50, spell_level) + 0.75 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(300, 100, spell_level) + 1.2 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Garen"):
	{
		switch (slot)
		{
		case SpellSlot::R:
			input.RawTrueDamage = get_spell_damage_table(175, 175, spell_level) + get_spell_damage_table(0.286f, 0.06f, spell_level) * (target->MaxHealth() - target->Health());
			break;
		}
		break; }
	case FNV("Galio"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 35, spell_level) + 0.75 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 35, spell_level) + 0.9 * source->TotalAbilityPower();

			if (!target->IsHero())
			{
				input.RawMagicalDamage /= 2;
			}

			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Gangplank"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.AppliesOnHitDamage = TRUE;
			input.RawPhysicalDamage = get_spell_damage_table(20, 25, spell_level) + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(35, 25, spell_level) + 0.1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Gnar"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(5, 30, spell_level) + 1.15 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(10, 10, spell_level) + get_spell_damage_table(0.06f, 0.02f, spell_level) * target->MaxHealth() + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(20, 40, spell_level) + 0.06 * source->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(200, 100, spell_level) + 0.2 * source->BonusAttackDamage() + 0.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Gragas"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 40, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
			/*case SpellSlot::W:
			input.Type = DamageType_Magical;
			input.RawDamage = get_spell_damage_table(20, 30, spell_level) + 0.08 * target->MaxHealth();
			break;*/
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 50, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(200, 100, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Graves"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(80, 30, spell_level) + get_spell_damage_table(0.4f, 0.3f, spell_level) * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 50, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(250, 150, spell_level) + 1.5 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Hecarim"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(50, 40, spell_level) + 0.7 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(20, 10, spell_level) + 0.2 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(40, 35, spell_level) + 0.5 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Heimerdinger"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(12, 6, spell_level) + 0.15 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.45 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 40, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Illaoi"):
	{
		switch (slot)
		{
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(1, 0, spell_level) + get_spell_damage_table(0.03f, 0.005000001f, spell_level) * target->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.5 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Irelia"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.AppliesOnHitDamage = TRUE;
			input.RawPhysicalDamage = get_spell_damage_table(5, 20, spell_level) + 0.6 * source->TotalAttackDamage();

			if (me->HasItem(kItemID::BladeoftheRuinedKing))
				input.RawMagicalDamage = target->Health() * .1;

			if (me->HasItem(kItemID::WitsEnd))
				if (me_level < 9)
					input.RawMagicalDamage = 15;
				else if (me_level >= 9 && me_level < 15)
					input.RawMagicalDamage = 25 + 10 * (me_level-9);
				else if (me_level >= 15)
					input.RawMagicalDamage = 76.25 + 1.25 * (me_level - 15);



			if (target->IsMinion() && !target->IsJungleMonster())
				input.RawPhysicalDamage += get_spell_damage_table(55, 12, me_level-1);

			 //printf("Q raw = %.0f +  minion bonus: %.0f = ", get_spell_damage_table(5, 20, spell_level) + 0.6 * source->TotalAttackDamage(), get_spell_damage_table(55, 12, me_level-1)+ get_spell_damage_table(5, 20, spell_level) + 0.6 * source->TotalAttackDamage(), get_spell_damage_table(55, 12, me_level-1));

			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(10, 15, spell_level) + 0.5 * source->TotalAttackDamage() + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 45, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(125, 125, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Ivern"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 45, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(30, 7.5f, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Janna"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 25, spell_level) + 0.35 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(55, 45, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("JarvanIV"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(70, 40, spell_level) + 1.2 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(200, 125, spell_level) + 1.5 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Jax"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(65, 40, spell_level) + 1 * source->BonusAttackDamage() + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(40, 35, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(50, 25, spell_level) + 0.5 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 60, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Jayce"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(35, 35, spell_level) + 1.2 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(100, 60, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.08f, 0.024f, spell_level) * target->MaxHealth() + 1 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(20, 40, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Jhin"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(50, 25, spell_level) + get_spell_damage_table(0.4f, 0.075f, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(50, 35, spell_level) + 0.5 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(20, 60, spell_level) + 1.2 * source->TotalAttackDamage() + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(40, 60, spell_level) + 0.2 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Jinx"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + 0.1 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(10, 50, spell_level) + 1.4 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 50, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			auto distance = source->Distance(target);
			auto prop = fmin(1.f, distance / 1500.f);
			prop = fmax(0.1f, prop);
			input.RawPhysicalDamage = get_spell_damage_table(250, 150, spell_level) + 1.5 * source->BonusAttackDamage() + get_spell_damage_table(0.25f, 0.05f, spell_level) * (target->MissingHealth());
			input.RawPhysicalDamage *= prop;
			break;
		}
		break; }
	case FNV("Kaisa"):
	{
		switch (slot)
		{

		case SpellSlot::Q:
		{
			constexpr float const dmg_table[] = { 45, 61.25f, 77.5f, 93.75f, 110 };

			input.RawPhysicalDamage = dmg_table[spell_level] + 0.4 * source->BonusAttackDamage() + 0.25 * source->TotalAbilityPower();

			if (target->IsMinion() && target->HealthPercent() <= 35)
				input.RawPhysicalDamage *= 2;

			break;
		}
		case SpellSlot::W:
		{
			input.RawMagicalDamage = get_spell_damage_table(20, 25, spell_level) + (1.5 * source->TotalAttackDamage()) + (0.45 * source->TotalAbilityPower());
			auto stack = 2;
			if (source->HasBuff(FNV("KaisaWEvolved")))
				stack = 3;

			auto kaisapassivemarkercount = target->HasBuff(FNV("kaisapassivemarker")) ? target->BuffCount(FNV("kaisapassivemarker")) : 0;
			if (5 - kaisapassivemarkercount <= stack)
			{
				// passive dmg
				float prc = fmin(20, 15. + 1. * (source->Level() - 1) / 3);
				float ap_prc = 2.5 * source->TotalAbilityPower() / 100;

				input.RawMagicalDamage += (prc + ap_prc) / 100.f * (target->MaxHealth() - target->Health());
			}

			break;
		}
		}
		break;

	}

	case FNV("Kalista"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(20, 65, spell_level) + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.05f, 0.025f, spell_level) * target->MaxHealth();
			break;
		case SpellSlot::E:
		{
			auto count = target->HasBuff(FNV("kalistaexpungemarker")) ? target->BuffCount(FNV("kalistaexpungemarker")) : 0;
			int additionalTable[] = { 10 , 16 , 22 , 28 , 34 };
			float damage_mult[] = { .18f, .21f, .24f, .27f, .3f };
			if (count > 0)
			{
				input.RawPhysicalDamage = .5f * source->TotalAttackDamage();
				input.RawPhysicalDamage += 20 + 10 * spell_level;

				if (count > 1)
				{
					input.RawPhysicalDamage += (additionalTable[spell_level] + damage_mult[spell_level] * source->TotalAttackDamage()) * (count - 1);
				}
			}

			if (target->IsEpicMonster())
			{
				input.RawPhysicalDamage /= 2;
			}

			break;
		}
		}
		break; }
	case FNV("Karma"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 45, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 50, spell_level) + 0.9 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Karthus"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(50, 20, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(30, 20, spell_level) + 0.2 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(250, 150, spell_level) + 0.75 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Kassadin"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(65, 30, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 25, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 25, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(80, 20, spell_level) + 0.2 * source->TotalAbilityPower() + 0.02 * source->MaxMana();
			break;
		}
		break; }
	case FNV("Katarina"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(75, 30, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(68, 15, me_level) + 0.25 * source->TotalAbilityPower() + 0.5 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(15, 15, spell_level) + 0.25 * source->TotalAbilityPower() + 0.5 * source->TotalAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 75, spell_level) + 1.15 * source->TotalAbilityPower() + 1.3 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Kayle"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 50, spell_level) + 1 * source->BonusAttackDamage() + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(10, 5, spell_level) + 0.15 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Kayn"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(55, 20, spell_level) + 0.65 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(80, 45, spell_level) + 1.2 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(150, 100, spell_level) + 1.5 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Samira"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(0, 5, spell_level) + get_spell_damage_table(0.85, 0.10, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(20, 15, spell_level) + 0.8 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(50, 10, spell_level) + 0.2 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Khazix"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(60, 25, spell_level) + 1.3 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(85, 30, spell_level) + 1 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(65, 35, spell_level) + 0.2 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Kindred"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(55, 20, spell_level) + 0.65 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(25, 5, spell_level) + 0.2 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(80, 20, spell_level) + 0.8 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Kled"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(25, 25, spell_level) + 0.6 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(20, 10, spell_level) + get_spell_damage_table(0.04f, 0.005000003f, spell_level) * target->MaxHealth();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(20, 25, spell_level) + 0.6 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.12f, 0.03000001f, spell_level) * target->MaxHealth();
			break;
		}
		break; }
	case FNV("KogMaw"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 50, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 40, spell_level) + 0.65 * source->BonusAttackDamage() + 0.25 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Leblanc"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(55, 35, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(75, 40, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("LeeSin"):
	{
		switch (slot)
		{
		case SpellSlot::Q:

			if (target->HasBuff(("BlindMonkQOne")))
			{
				input.RawPhysicalDamage = get_spell_damage_table(50, 30, spell_level) + 1 * source->BonusAttackDamage();
				input.RawPhysicalDamage = input.RawPhysicalDamage + input.RawPhysicalDamage * (100 - target->HealthPercent()) * 0.01;
			}
			else
				input.RawPhysicalDamage = get_spell_damage_table(50, 30, spell_level) + 1 * source->BonusAttackDamage();
			break;

			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 35, spell_level) + 1 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(150, 150, spell_level) + 2 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Leona"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(30, 25, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(40, 40, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 40, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 75, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Lissandra"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 30, spell_level) + 0.65 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 30, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 35, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Lucian"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(80, 35, spell_level) + get_spell_damage_table(0.6f, 0.15f, spell_level) * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 40, spell_level) + 0.9 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(20, 15, spell_level) + 0.1 * source->TotalAbilityPower() + 0.2 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Lulu"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 45, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 30, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Lux"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 45, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(300, 100, spell_level) + 0.75 * source->TotalAbilityPower();

			if (target->HasBuff(("luxilluminatingfraulein")))
				input.RawMagicalDamage += 10 + 10 * source->Level() + 0.2 * source->TotalAbilityPower();

			break;
		}
		break; }
	case FNV("Malphite"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 50, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(15, 15, spell_level) + 0.15 * source->Armor() + 0.1 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 35, spell_level) + 0.3 * source->Armor() + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(200, 100, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Malzahar"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 35, spell_level) + 0.65 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 35, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(125, 75, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Maokai"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(65, 40, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(50, 25, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(50, 50, spell_level) + get_spell_damage_table(0.07f, 0.0025f, spell_level) * target->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 75, spell_level) + 0.75 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("MasterYi"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(25, 35, spell_level) + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(14, 9, spell_level) + 0.25 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("MissFortune"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.AppliesOnHitDamage = TRUE;
			input.RawPhysicalDamage = get_spell_damage_table(20, 20, spell_level) + 0.35 * source->TotalAbilityPower() + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 35, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + 0.75 * source->TotalAttackDamage() + 0.2 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("MonkeyKing"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(30, 30, spell_level) + 1.1 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 45, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(65, 35, spell_level) + 0.8 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(20, 90, spell_level) + 1.1 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Mordekaiser"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(10, 10, spell_level) + get_spell_damage_table(0.5f, 0.1f, spell_level) * source->TotalAbilityPower() + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(140, 40, spell_level) + 0.9 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(35, 30, spell_level) + 0.6 * source->TotalAttackDamage() + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.25f, 0.05000001f, spell_level) * target->MaxHealth();
			break;
		}
		break; }
	case FNV("Morgana"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 55, spell_level) + 0.9 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(16, 16, spell_level) + 0.22 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 75, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Nami"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(75, 55, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(25, 15, spell_level) + 0.2 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Nasus"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(30, 20, spell_level) + 1 * (target->HasBuff(("NasusQStacks")) ? target->BuffCount(("NasusQStacks")) : 0);
			break;
			//case SpellSlot::E:
			//	input.RawMagicalDamage = get_spell_damage_table(55, 40, spell_level) + 0.6 * source->TotalAbilityPower();
			//	break;
		}
		break; }
	case FNV("Nautilus"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 40, spell_level) + 0.75 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(30, 10, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(55, 30, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(125, 50, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Nidalee"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 15, spell_level) + 0.4 * source->TotalAbilityPower();

			if (source->IsMelee())
			{
				auto const rLevel = source->GetSpellBook()->GetSpellSlotByID((int)SpellSlot::R)->Level() - 1;

				//cat
				std::array<int, 4> const damage_table = { 5, 30, 55, 80 };
				float ad_scalar = 0.75;
				float ap_scalar = 0.4;
				std::array<float, 4> const hp_scalar = { 0, .25, .5, .75 };
				float mul = (100 - target->HealthPercent()) / 100;
				float scale = hp_scalar[rLevel] * mul;

				input.RawMagicalDamage = damage_table[rLevel] * (1.0f + scale) +
					((ad_scalar + scale) * source->TotalAttackDamage()) +
					((ap_scalar + scale) * source->TotalAbilityPower());

				if (target->HasBuff(("NidaleePassiveHunted")))
					input.RawMagicalDamage *= 1.4;
			}
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(40, 40, spell_level) + 0.2 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Nocturne"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.75 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 45, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(150, 100, spell_level) + 1.2 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Nunu"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(340, 160, spell_level);
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 40, spell_level) + 0.9 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(625, 250, spell_level) + 2.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Olaf"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(80, 45, spell_level) + 1 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawTrueDamage = get_spell_damage_table(70, 45, spell_level) + 0.5 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Orianna"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 75, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Pantheon"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(65, 40, spell_level) + 1.4 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 25, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(26, 17, spell_level) + 1 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(400, 300, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Poppy"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(35, 20, spell_level) + 0.8 * source->BonusAttackDamage() + 0.08 * target->MaxHealth();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(50, 20, spell_level) + 0.5 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(200, 100, spell_level) + 0.9 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Quinn"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(20, 25, spell_level) + get_spell_damage_table(0.8f, 0.09999996f, spell_level) * source->BonusAttackDamage() + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(40, 30, spell_level) + 0.2 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + 0.4 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Rakan"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 45, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 45, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 100, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Rammus"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(100, 35, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(25, 10, spell_level) + 0.1 * source->Armor();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(40, 40, spell_level) + 0.2 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("RekSai"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(15, 5, spell_level) + 0.5 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(50, 15, spell_level) + 0.8 * source->BonusAttackDamage();
			break;
		case SpellSlot::E: //40 + (10 * elvl) + me->BonusAttackDamage() * .85;
			input.RawPhysicalDamage = get_spell_damage_table(40, 10, spell_level) + me->BonusAttackDamage() * .85;
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(100, 150, spell_level) + 2 * source->BonusAttackDamage() + get_spell_damage_table(0.2f, 0.05f, spell_level) * (source->MaxHealth() - source->Health());
			break;
		}
		break; }

	case FNV("Renekton"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.8 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(10, 20, spell_level) + 1.5 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(30, 30, spell_level) + 0.9 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(40, 40, spell_level) + 0.1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Rengar"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(30, 30, spell_level) + get_spell_damage_table(0.4f, 0.2f, spell_level) * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(50, 30, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(50, 45, spell_level) + 0.7 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Riven"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(15, 20, spell_level) + 0.8 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(50, 30, spell_level) + 1 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = (get_spell_damage_table(100, 50, spell_level) + 0.6 * source->BonusAttackDamage()) * (1 + fmin(2, (target->MissingHealthPercent() * 2.67) / 100));
			break;
		}
		break; }
	case FNV("Rumble"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(135, 45, spell_level) + 1.1 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 25, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(130, 55, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Ryze"):
	{
		auto baseMana = 350 + source->Level() * 50;
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 25, spell_level) + 0.45 * source->TotalAbilityPower() + 0.03 * (source->MaxMana() - baseMana);

			if (target->HasBuff(("RyzeE")))
				input.RawMagicalDamage = input.RawMagicalDamage + input.RawMagicalDamage * (0.3 + 0.1 * spell_level);

			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(80, 20, spell_level) + 0.6 * source->TotalAbilityPower() + 0.01 * (source->MaxMana() - baseMana);
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 20, spell_level) + 0.3 * source->TotalAbilityPower() + 0.02 * (source->MaxMana() - baseMana);
			break;
		}
		break; }
	case FNV("Sejuani"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 40, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(20, 5, spell_level) + 0.015 * source->MaxHealth();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(40, 40, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 25, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Shen"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.02f, 0.005000001f, spell_level) * target->MaxHealth();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(50, 25, spell_level);
			break;
		}
		break; }
	case FNV("Shyvana"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.4f, 0.15f, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(20, 12, spell_level) + 0.2 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 40, spell_level) + 0.3 * source->TotalAbilityPower() + 0.7 * source->TotalAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Singed"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(22, 12, spell_level) + 0.08 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(50, 15, spell_level) + get_spell_damage_table(0.06f, 0.004999999f, spell_level) * target->MaxHealth() + 0.75 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Sion"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(60, 60, spell_level) + 1.95 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(40, 25, spell_level) + 0.4 * source->TotalAbilityPower() + get_spell_damage_table(0.1f, 0.009999998f, spell_level) * target->MaxHealth();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(65, 35, spell_level) + 0.55 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(150, 150, spell_level) + 0.4 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Sivir"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(55, 20, spell_level) + get_spell_damage_table(0.7f, 0.1f, spell_level) * source->TotalAttackDamage() + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.5f, 0.05000001f, spell_level) * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Skarner"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.33f, 0.03f, spell_level) * source->TotalAttackDamage() + get_spell_damage_table(0.33f, 0.03f, spell_level) * source->TotalAttackDamage() + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(40, 25, spell_level) + 0.2 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(40, 80, spell_level) + 1.2 * source->TotalAttackDamage() + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Sona"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(40, 30, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Soraka"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.35 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Syndra"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 45, spell_level) + 0.65 * source->TotalAbilityPower();
			if (source->GetSpellBook()->GetSpellSlotByID(0)->Level() > 4)
				input.RawMagicalDamage *= 1.25;
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.7 * source->TotalAbilityPower();
			if (source->GetSpellBook()->GetSpellSlotByID(1)->Level() > 4)
				input.RawTrueDamage = input.RawMagicalDamage * .2;
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(85, 45, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(90, 50, spell_level) + 0.2 * source->TotalAbilityPower();
			input.RawMagicalDamage += input.RawMagicalDamage * source->GetSpellBook()->GetSpellSlotByID((int)SpellSlot::R)->Ammo();
			break;
		}
		break; }
	case FNV("TahmKench"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 50, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.2f, 0.03f, spell_level) * target->MaxHealth();
			break;
		}
		break; }
	case FNV("Taliyah"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 25, spell_level) + 0.45 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 20, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 20, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Talon"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(65, 25, spell_level) + 1.1 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(45, 15, spell_level) + 0.4 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(90, 45, spell_level) + 1 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Taric"):
	{
		switch (slot)
		{
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(100, 45, spell_level) + 0.3 * source->Armor() + 0.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Teemo"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 45, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(10, 10, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(200, 125, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Thresh"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 40, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(65, 30, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(250, 150, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Tristana"):
	{
		switch (slot)
		{
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(95, 50, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			buffcount = 0;
			if (target->BuffCount("tristanaecharge") && me->GetSpellBook()->GetSpellSlotByID(3)->IsReady())
			{
				buffcount = target->BuffCount("tristanaecharge") + 1;
			}
			input.RawPhysicalDamage = (get_spell_damage_table(70, 10, spell_level) + (get_spell_damage_table(0.5, .25, spell_level) * source->BonusAttackDamage()) + (.5 * source->TotalAbilityPower()));
			//printf("input.RawPhysicalDamage : %f\n", input.RawPhysicalDamage);
			input.RawMagicalDamage = (get_spell_damage_table(21, 3, spell_level) * buffcount + get_spell_damage_table(.15, .075, spell_level) * buffcount);
			input.RawPhysicalDamage += input.RawMagicalDamage;
			//printf("input.RawPhysicalDamage2 : %f | perstack: %f | count: %i\n", input.RawPhysicalDamage, input.RawMagicalDamage, target->BuffCount("tristanaecharge"));
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(300, 100, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Trundle"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(20, 15, spell_level) + get_spell_damage_table(0.1f, 0.1f, spell_level) * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Tryndamere"):
	{
		switch (slot)
		{
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(70, 30, spell_level) + 1.2 * source->BonusAttackDamage() + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("TwistedFate"):
	{
		//auto SD = spell->SData();
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.65 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
		{
			auto spell_name = fnv::hash_runtime(spellslot->GetSpellData()->GetSpellName().c_str());
			if (spell_name == FNV("bluecardlock"))
				input.RawMagicalDamage = get_spell_damage_table(40.f, 20.f, spell_level) + 1.f * source->TotalAttackDamage() + 0.5f * source->TotalAbilityPower();
			else if (spell_name == FNV("redcardlock"))
				input.RawMagicalDamage = get_spell_damage_table(30.f, 15.f, spell_level) + 1.f * source->TotalAttackDamage() + 0.5f * source->TotalAbilityPower();
			else if (spell_name == FNV("goldcardlock"))
				input.RawMagicalDamage = get_spell_damage_table(15.f, 7.5f, spell_level) + 1.f * source->TotalAttackDamage() + 0.5f * source->TotalAbilityPower();
			else // Assume lowest possible by default?
				input.RawMagicalDamage = get_spell_damage_table(15.f, 7.5f, spell_level) + 1.f * source->TotalAttackDamage() + 0.5f * source->TotalAbilityPower();
			break;
		}
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(55, 25, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Twitch"):
	{
		switch (slot)
		{
		case SpellSlot::E:
			if (target->HasBuff(("TwitchDeadlyVenom")))
			{
				auto buffcount = target->HasBuff(("TwitchDeadlyVenom")) ? target->BuffCount(("TwitchDeadlyVenom")) : 0;
				input.RawPhysicalDamage = get_spell_damage_table(20, 10, spell_level) + buffcount * (get_spell_damage_table(15, 5, spell_level) + 0.35 * source->BonusAttackDamage() + 0.2 * source->TotalAbilityPower());
			}
			break;
		}
		break; }
	case FNV("Udyr"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(30, 30, spell_level) + get_spell_damage_table(1.2f, 0.0999999f, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(60, 50, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Urgot"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(25, 45, spell_level) + 0.7 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(12, 0, spell_level) + get_spell_damage_table(0.2f, 0.03999999f, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(60, 40, spell_level) + 0.5 * source->TotalAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(50, 125, spell_level) + 0.5 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Varus"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(15, 55, spell_level) + 1.5 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(10, 4, spell_level) + 0.25 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(65, 35, spell_level) + 0.6 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 75, spell_level) + 1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Vayne"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(0, 0, spell_level) + get_spell_damage_table(0.6f, 0.04999998f, spell_level) * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			if (source->BuffCount("VayneSilverDebuff") == 2)
				input.RawTrueDamage = fmax(get_spell_damage_table(50.0f, 15.0f, spell_level), get_spell_damage_table(0.04f, 0.025f, spell_level) * target->MaxHealth());
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(45, 35, spell_level) + 0.5 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Veigar"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(100, 50, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(175, 75, spell_level) + 0.75 * source->TotalAbilityPower();
			if (target->HealthPercent() > 33)
				input.RawMagicalDamage = input.RawMagicalDamage + ((100 - target->HealthPercent()) * 1.5 * 0.01 * input.RawMagicalDamage);
			else
				input.RawMagicalDamage = input.RawMagicalDamage * 2;
			break;
		}
		break; }
	case FNV("Velkoz"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 40, spell_level) + 0.8 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(30, 20, spell_level) + 0.15 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 30, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(450, 175, spell_level) + 1.25 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Vi"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(100, 50, spell_level) + 1.6 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(10, 20, spell_level) + 1.15 * source->TotalAttackDamage() + 0.7 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(150, 150, spell_level) + 1.4 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Viktor"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 15, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 40, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 75, spell_level) + .5 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Vladimir"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 20, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 1 * source->TotalAbilityPower() + 0.06 * source->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Volibear"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(30, 30, spell_level) + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(60, 50, spell_level) + 1 * (target->MaxHealth() - target->Health());
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 45, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(75, 40, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Warwick"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(0, 0, spell_level) + 1.2 * source->TotalAttackDamage() + 0.9 * source->TotalAbilityPower() + get_spell_damage_table(0.06f, 0.01f, spell_level) * target->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(175, 175, spell_level) + 1.675 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Xerath"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(80, 40, spell_level) + 0.75 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(60, 30, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(80, 30, spell_level) + 0.45 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(200, 40, spell_level) + 0.43 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Xayah"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(80, 40, spell_level) + 1 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
		{
			input.RawPhysicalDamage = get_spell_damage_table(50, 10, spell_level) + 0.6 * source->BonusAttackDamage() * fmin((1 + source->Crit() / 2.f), 0.5f);

			if (target->IsMinion())
				input.RawPhysicalDamage = input.RawPhysicalDamage / 2;

			break;
		}
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(100, 50, spell_level) + 1 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("XinZhao"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(15, 9, spell_level) + 0.4 * source->BonusAttackDamage();
			break;
		case SpellSlot::W:
			if (target->Position().Distance(me->Position()) < 200)
				input.RawPhysicalDamage = get_spell_damage_table(30, 10, spell_level) + 0.3 * source->TotalAttackDamage();
			input.RawPhysicalDamage += get_spell_damage_table(40, 35, spell_level) + 0.8 * source->TotalAttackDamage() + .5 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(50, 25, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(75, 100, spell_level) + 1 * source->BonusAttackDamage() + 0.15 * target->Health() + 1.1* source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Zoe"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(50, 30, spell_level) + 0.66 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(23, 15, spell_level) + 0.13 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 40, spell_level) + 0.4 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Yasuo"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(20, 20, spell_level) + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 10, spell_level) * (1 + target->HasBuff(("YasuoDashScalar")) ? target->BuffCount(("YasuoDashScalar")) : 0 / 4.f) + 0.2 * source->BonusAttackDamage() + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(200, 100, spell_level) + 1.5 * source->BonusAttackDamage();
			break;
		}
		break; }
	case FNV("Yone"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(20, 20, spell_level) + 1 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawPhysicalDamage = get_spell_damage_table(5, 5, spell_level) + .05 * (.05* spell_level) * target->MaxHealth();
			input.RawMagicalDamage = get_spell_damage_table(5, 5, spell_level) + .05 * (.05 * spell_level) * target->MaxHealth();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(100, 100, spell_level) + 0.4 * source->TotalAbilityPower();
			input.RawPhysicalDamage = get_spell_damage_table(100, 100, spell_level) + 0.4 * source->TotalAttackDamage();

			break;
		}
		break; }
	case FNV("Yorick"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(30, 25, spell_level) + 0.4 * source->TotalAttackDamage();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(70, 35, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Zac"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(40, 15, spell_level) + 0.3 * source->TotalAbilityPower() + 0.025 * source->MaxHealth();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(15, 15, spell_level) + get_spell_damage_table(0.04f, 0.01f, spell_level) * target->MaxHealth();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 50, spell_level) + 0.9 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(150, 100, spell_level) + 0.9 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Zed"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(70, 35, spell_level) + 0.9 * source->BonusAttackDamage();
			break;
		case SpellSlot::E:
			input.RawPhysicalDamage = get_spell_damage_table(65, 25, spell_level) + 0.8 * source->BonusAttackDamage();
			break;
		case SpellSlot::R:
			input.RawPhysicalDamage = get_spell_damage_table(65, 25, spell_level) + 1 * source->TotalAttackDamage();
			break;
		}
		break; }
	case FNV("Ziggs"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(75, 45, spell_level) + 0.65 * source->TotalAbilityPower();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(70, 35, spell_level) + 0.35 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(40, 35, spell_level) + 0.3 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(300, 100, spell_level) + 1.1 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Zilean"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(75, 40, spell_level) + 0.9 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Zyra"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawMagicalDamage = get_spell_damage_table(60, 35, spell_level) + 0.6 * source->TotalAbilityPower();
			break;
		case SpellSlot::E:
			input.RawMagicalDamage = get_spell_damage_table(60, 35, spell_level) + 0.5 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.RawMagicalDamage = get_spell_damage_table(180, 85, spell_level) + 0.7 * source->TotalAbilityPower();
			break;
		}
		break; }
	case FNV("Veigo"):
	{
		switch (slot)
		{
		case SpellSlot::Q:
			input.RawPhysicalDamage = get_spell_damage_table(25, 15, spell_level) + 0.6 * source->TotalAttackDamage();
			break;
		case SpellSlot::W:
			input.RawMagicalDamage = get_spell_damage_table(80, 55, spell_level) + 1 * source->TotalAbilityPower();
			break;
		case SpellSlot::R:
			input.AppliesOnHitDamage = TRUE;
			input.RawPhysicalDamage = (get_spell_damage_table(.15, .05, spell_level) + .03*floor(100 / source->TotalAttackDamage()))*target->MissingHealth();
		}
		break; }
	case FNV("Kennen"):
	{
		//TODO Kennen damageLib
		//break;
		break; }
	case FNV("Ornn"):
	{
		//TODO Ornn damageLib
		//break;
		break; }
	case FNV("Shaco"):
	{
		switch (slot)
		{
		case SpellSlot::E:
			input.RawMagicalDamage = target->HealthPercent() <= 30 ? (get_spell_damage_table(70, 25, spell_level) + 0.7 * source->BonusAttackDamage() + .55 * source->TotalAbilityPower()) * 1.5 : get_spell_damage_table(70, 25, spell_level) + 0.7 * source->BonusAttackDamage() + .55 * source->TotalAbilityPower();
			break;
		}

		//70 / 95 / 120 / 145 / 170 (+70 % bonus AD) (+55 % AP)
			//TODO Shaco damageLib
			//break;
		break; }
	case FNV("Swain"):
	{
		//TODO Swain damageLib
		//break;
		break; }
	case FNV("Pyke"):
	{
		//TODO Pyke damageLib
		//break;
		break; }
	//case FNV("Sylas"):
	//{
	//	switch (slot)
	//	{

	//	case SpellSlot::Q: // 100 / 175 / 250 / 325 / 400 (+120 %
	//		input.RawMagicalDamage = get_spell_damage_table(100, 75, spell_level) + 1.2 * source->TotalAbilityPower();
	//		break;
	//	case SpellSlot::W: //65 / 100 / 135 / 170 / 205 (+ 85% AP)
	//		input.RawMagicalDamage = get_spell_damage_table(65, 35, spell_level) + 0.85 * source->TotalAbilityPower();
	//		break;
	//	case SpellSlot::E: //80 / 130 / 180 / 230 / 280 (+ 100%
	//		input.RawMagicalDamage = get_spell_damage_table(80, 50, spell_level) + 1 * source->TotalAbilityPower();
	//		break;
	//	case SpellSlot::R: //tbd
	//		input.RawMagicalDamage = get_spell_damage_table(180, 85, spell_level) + 0.7 * source->TotalAbilityPower();
	//		break;
	//	}
	//}
	//case FNV("Neeko"):
	//	{
	//		switch (slot)
	//		{
	//		case SpellSlot::Q:
	//			input.RawMagicalDamage = get_spell_damage_table(70, 45, spell_level) + 0.5 * source->TotalAbilityPower();
	//			break;
	//			//neekowpassiveready
	//		case SpellSlot::W:
	//			input.RawMagicalDamage = me->HasBuff("neekowpassiveready") ? get_spell_damage_table(50, 20, spell_level) + 0.6 * source->TotalAbilityPower() : 0;
	//			break;
	//		case SpellSlot::E:
	//			input.RawMagicalDamage = get_spell_damage_table(80, 35, spell_level) + 0.6 * source->TotalAbilityPower();
	//			break;
	//		case SpellSlot::R:
	//			input.RawMagicalDamage = get_spell_damage_table(200, 225, spell_level) + 1.3 * source->TotalAbilityPower();
	//			break;
	//		}
	//
	//		//TODO Pyke damageLib
	//		//break;
	//	}

		// Those also need to be done:
		//	Neeko = 143,
		//	Sylas = 144,
		//	Yuumi = 145,
		//	Qiyana = 146

		//if (return_raw_damage)
		//return input.RawPhysicalDamage + input.RawMagicalDamage + input.RawTrueDamage;
		/*if (menucfg.bDebugDamage)
		{
			printf("RAW champ: %s | spellslot: %i | true: %.0f | Phys: %.0f | magic: %.0f\n", source->ChampionName().c_str(), slot, input.RawTrueDamage, input.RawPhysicalDamage, input.RawMagicalDamage);
			printf("CAL champ: %s | spellslot: %i | true: %.0f | Phys: %.0f | magic: %.0f\n", source->ChampionName().c_str(), slot, source->CalculateDamage(target, input.RawTrueDamage, 0), source->CalculateDamage(target, input.RawPhysicalDamage, 1), source->CalculateDamage(target, input.RawMagicalDamage, 2));
		}*/
	break;
	}
	//TEMP FIX FOR THE ARAM DAMAGE BUG
	if (target->IsMinion() && me->HasBuff("ChampionBalanceBuff"))
	{
		input.RawTrueDamage *= .75;
			input.RawPhysicalDamage *= .75;
			input.RawMagicalDamage *= .75;
	}
	return source->CalculateDamage(target, input.RawTrueDamage, 0) + source->CalculateDamage(target, input.RawPhysicalDamage, 1) + source->CalculateDamage(target, input.RawMagicalDamage, 2);
}







//float CalculateDamageOnUnit(CObject* source, CObject* target, DamageInput* input)
//{
//
//	const auto source_items = GetItems(source);
//	const auto target_items = GetItems(target);
//
//	const auto source_perks = GetPerks(source);
//	const auto target_perks = GetPerks(target);
//
//	auto const spellbook = source->GetSpellBook();
//
//	if (!spellbook)
//		return 0.f;
//
//#pragma region Raw Damage amplifiers
//	if (source->IsHero())
//	{
//		if (target->IsHero())
//		{
//			if (!input->DontIncludePassives && (input->AppliesOnHitDamage || input->IsAutoAttack) && source->IsMelee() && source_items->Dead_Mans_Plate)
//			{
//
//
//				auto slot = source->GetItemSlot(kItemID::DeadMansPlate);
//				if (slot != -1)
//				{
//					auto count = source->GetSpellBook()->GetSpellSlotByID(slot)->Ammo();
//
//					if (count > 0)
//					{
//						input->RawMagicalDamage += (count == 100 ? 2 : 1) * count / 2.0f;
//					}
//				}
//			}
//
//			// UNIQUE � ECHO: Gains charges upon moving or casting. At 100 charges, 
//			// the next instance of ability damage you deal will expend all charges to deal 60 (+ 10% AP) bonus magic damage 
//			// to the first enemy hit and summon up to 3 lesser bolts that target nearby enemies, prioritizing enemies damaged by the ability and champions over minions.
//			if (input->DontCalculateItemDamage == FALSE &&
//				input->IsAbility &&
//				target->HasBuff("itemmagicshankcharge") && target->BuffCount("itemmagicshankcharge") == 100)
//			{
//				input->RawMagicalDamage += (60.0f + source->TotalAbilityPower() * 0.1f) * (target->IsJungle() ? 2.5f : 1.0f);
//			}
//
//			if (!input->DontCalculateItemDamage && input->IsAbility && source->HasBuff("itemserrateddirkprocbuff"))
//			{
//				input->RawPhysicalDamage += 40;
//			}
//
//			if (!input->DontIncludePassives && !input->DoesntTriggerOnHitEffects && (input->IsAbility || input->IsAutoAttack) && source_perks->CheapShot)
//			{
//				if (target->HasBuffOfType(BuffType::Knockup) || target->HasBuffOfType(BuffType::Flee) ||
//					target->HasBuffOfType(BuffType::Charm) || target->HasBuffOfType(BuffType::Taunt) ||
//					target->HasBuffOfType(BuffType::Snare) || target->HasBuffOfType(BuffType::Stun) ||
//					target->HasBuffOfType(BuffType::Suppression) || target->HasBuffOfType(BuffType::Knockback))
//				{
//					constexpr const int cheapshot_damage[] = { 0, 15, 16, 18, 19, 21, 22, 24, 25, 27, 28, 30, 31, 33, 34, 36, 37, 39, 40 };
//					const auto level = static_cast<int>(fmin(18, source->Level()));
//
//					input->RawTrueDamage += cheapshot_damage[level];
//				}
//			}
//
//			//Predator Rune
//			if (!input->DontIncludePassives && !input->DoesntTriggerOnHitEffects && (input->IsAbility || input->IsAutoAttack) &&
//				source_perks->Predator && source->HasBuff("ASSETS/Perks/Styles/Domination/Predator/PredatorActive.lua"))
//			{
//				const auto damage = GetRiotScalar(1, 18, source->Level(), 60, 180) + source->TotalAbilityPower() * 0.25f + source->BonusAttackDamage() * 0.4f;
//
//				// ADAPTIVE DAMAGE: Deals either physical or magic damage depending on your bonus statistics, defaulting to physical damage.
//				if (source->FlatAttackDamageMod() == source->FlatAbilityPowerMod() || source->FlatAttackDamageMod() > source->FlatAbilityPowerMod())
//				{
//					input->RawPhysicalDamage += damage;
//				}
//				else
//				{
//					input->RawMagicalDamage += damage;
//				}
//			}
//
//			// Aery rune
//			if (!input->DontIncludePassives && !input->DoesntTriggerOnHitEffects && (input->IsAbility || input->IsAutoAttack) &&
//				source_perks->SummonAery && source->HasBuff("ASSETS/Perks/Styles/Sorcery/SummonAery/SummonAery.lua"))
//			{
//				const auto damage = GetRiotScalar(1, 18, source->Level(), 15, 40) + source->TotalAbilityPower() * 0.1f + source->BonusAttackDamage() * 0.15f;
//
//				// ADAPTIVE DAMAGE: Deals either physical or magic damage depending on your bonus statistics, defaulting to physical damage.
//				if (source->FlatAttackDamageMod() == source->FlatAbilityPowerMod() || source->FlatAttackDamageMod() > source->FlatAbilityPowerMod())
//				{
//					input->RawPhysicalDamage += damage;
//				}
//				else
//				{
//					input->RawMagicalDamage += damage;
//				}
//			}
//
//			if (!input->DontIncludePassives && input->RawPhysicalDamage > 0 && target->GetSkinData()->GetSkinHash() == SkinHash::Amumu)
//			{
//				input->RawPhysicalDamage -= 2.0f * target->GetSpellBook()->GetSpellSlotByID((int)SpellSlot::E)->Level();
//			}
//
//			if (!input->DontIncludePassives && input->RawPhysicalDamage > 0 && target->GetSkinData()->GetSkinHash() == SkinHash::Fizz)
//			{
//				input->RawPhysicalDamage -= 2.0f * (int)((target->Level() + 2.0f) / 3.0f) + 2.0f;
//			}
//
//			if (!input->DontIncludePassives && source_perks->CoupDeGrace && target->HealthPercent() < 40)
//			{
//				input->RawMagicalDamage *= 1.07f;
//				input->RawPhysicalDamage *= 1.07f;
//			}
//
//			if (!input->DontIncludePassives && source_perks->CutDown)
//			{
//				const auto percent = fmin(1, (target->MaxHealth() - source->MaxHealth()) / source->MaxHealth());
//
//				if (percent >= 0.1f)
//				{
//					auto delta = 1 + (percent >= 1.f ? 0.1f
//						: percent >= .85f ? 0.9f
//						: percent >= .7f ? 0.8f
//						: percent >= .55f ? 0.7f
//						: percent >= .4f ? 0.6f
//						: percent >= .25f ? 0.5f
//						: 0.4f);
//
//					input->RawMagicalDamage *= delta;
//					input->RawPhysicalDamage *= delta;
//				}
//			}
//
//			if (!input->DontIncludePassives && source_perks->PressTheAttack && target->HasBuff("ASSETS/Perks/Styles/Precision/PressTheAttack/PressTheAttackDamageAmp.lua"))
//			{
//				auto const damage_amplifier = 1.07765f + .00235f * source->Level();
//
//				input->RawMagicalDamage *= damage_amplifier;
//				input->RawPhysicalDamage *= damage_amplifier;
//			}
//
//			if (!input->DontCalculateItemDamage)
//			{
//				// Challenging Smite can be cast on enemy champions to mark them for 4 seconds, 
//				// reducing their damage against you by 20%
//
//				//auto smite_challenge_buff = source->GetBuff("itemsmitechallenge");
//
//				//if (smite_challenge_buff.Valid && smite_challenge_buff.Caster == target)
//				//{
//				//	input->RawMagicalDamage *= 0.8f;
//				//	input->RawPhysicalDamage *= 0.8f;
//				//}
//			}
//
//			//if (!input->DontCalculateItemDamage && source->HasPerk("LastStand"))
//			//{
//			//	auto missing_health_percent = 100 - source->HealthPercent();
//
//			//	if (source->IsZombie())
//			//	{
//			//		missing_health_percent = 100;
//			//	}
//
//			//	if (missing_health_percent > 40)
//			//	{
//			//		auto const scalar = GetRiotScalar(40.0f, 70.0f, missing_health_percent, 1.05f, 1.11f);
//
//			//		input->RawMagicalDamage *= scalar;
//			//		input->RawPhysicalDamage *= scalar;
//			//	}
//			//}
//		}
//	}
//
//	//if (!input->DontIncludePassives)
//	//{
//	//	auto buff = source->GetBuff("sonapassivedebuff");
//
//	//	if (buff.Valid && buff.Alive)
//	//	{
//	//		auto caster = buff.Caster;
//
//	//		if (caster && caster->IsValid())
//	//		{
//	//			input->RawPhysicalDamage *= .75f - (.04f * (caster->TotalAbilityPower() / 100.f));
//	//			input->RawPhysicalDamage *= .75f - (.04f * (caster->TotalAbilityPower() / 100.f));
//	//		}
//	//	}
//	//}
//
//	if (!input->DontIncludePassives && input->RawPhysicalDamage > 0 && source->IsMinion() && target->IsMinion())
//	{
//		input->RawPhysicalDamage -= target->FlatDamageReductionFromBarracksMinionMod();
//		input->RawPhysicalDamage *= 1.0f + source->PercentDamageToBarracksMinionMod();
//	}
//
//#pragma endregion 
//
//
//
//	if (!input->DontIncludePassives)
//	{
//		if (target->IsHero())
//		{
//			if (target->GetSkinData()->GetSkinHash() == SkinHash::Kassadin && target->HasBuff("voidstone"))
//				input->RawMagicalDamage *= 0.85f;
//		}
//	}
//
//#pragma region Damage Calculations
//
//	if (input->RawPhysicalDamage > 0)
//	{
//		float flatArmorPenetration = source->PhysicalLethality() * (0.6 + 0.4 * source->Level() / 18);
//		float armorPercentPenetration = source->PercentArmorPenetration();
//		float armorBonusPercentPenetration = source->PercentBonusArmorPenetration();
//
//		float total_armor = target->Armor();
//		float bonusArmor = target->BonusArmor();
//		float baseArmor = total_armor - bonusArmor;
//
//		float bonusArmorScalar = total_armor != 0 ? (bonusArmor / abs(total_armor)) : 0.5f;
//		float baseArmorScalar = total_armor != 0 ? (baseArmor / abs(total_armor)) : 0.5f;
//
//		if (source->IsMinion())
//		{
//			flatArmorPenetration = 0.0f;
//			armorPercentPenetration = 1.0f;
//			armorBonusPercentPenetration = 1.0f;
//		}
//		else if (source->IsTurret())
//		{
//			flatArmorPenetration = 0.0f;
//			armorPercentPenetration = 1.0f;
//			armorBonusPercentPenetration = 1.0f;
//		}
//
//		bonusArmor -= source->ArmorPen() * bonusArmorScalar;
//		baseArmor -= source->ArmorPen() * baseArmorScalar;
//		total_armor = bonusArmor + baseArmor;
//
//		if (total_armor > 0)
//		{
//			bonusArmor *= armorPercentPenetration;
//			baseArmor *= armorPercentPenetration;
//			total_armor = fmax(0, bonusArmor + baseArmor);
//
//			if (total_armor > 0)
//			{
//				bonusArmor *= armorBonusPercentPenetration;
//				total_armor = fmax(0, bonusArmor + baseArmor);
//			}
//
//			if (total_armor > 0)
//			{
//				total_armor = fmax(0, total_armor - flatArmorPenetration);
//			}
//		}
//
//		if (total_armor >= 0)
//		{
//			input->RawPhysicalDamage = input->RawPhysicalDamage * (100.f / (100.0f + total_armor));
//		}
//		else
//		{
//			input->RawPhysicalDamage = input->RawPhysicalDamage * (2.0f - (100.0f / (100.0f - total_armor)));
//		}
//	}
//
//	if (input->RawMagicalDamage > 0)
//	{
//		auto flat_magic_penetration = source->MagicPen() * (0.6 + 0.4 * source->Level() / 18) + source->FlatMagicPenetration();
//		auto percent_magic_penetration = source->PercentMagicPenetration();
//		auto spellblock = target->MagicResist();
//
//		if (source->IsMinion())
//		{
//			flat_magic_penetration = 0.0f;
//			percent_magic_penetration = 1.0f;
//		}
//		else if (source->IsTurret())
//		{
//			flat_magic_penetration = 0.0f;
//			percent_magic_penetration = 1.0f;
//		}
//
//		spellblock -= source->FlatMagicReduction();
//
//		if (spellblock > 0)
//		{
//			spellblock = fmax(0, spellblock * (1 - source->PercentMagicReduction()));
//
//			if (spellblock > 0)
//			{
//				spellblock = fmax(0, spellblock * percent_magic_penetration);
//			}
//
//			if (spellblock > 0)
//			{
//				spellblock = fmax(0, spellblock - flat_magic_penetration);
//			}
//		}
//
//		if (spellblock >= 0)
//		{
//			input->RawMagicalDamage = input->RawMagicalDamage * (100.f / (100.0f + spellblock));
//		}
//		else
//		{
//			input->RawMagicalDamage = input->RawMagicalDamage * (2.0f - (100.0f / (100.0f - spellblock)));
//		}
//	}
//#pragma endregion
//
//	if (!input->DontIncludePassives && source->IsHero())
//	{
//		//Exhaust reduces damage dealt by 40% for 2.5 seconds.
//		if (source->HasBuff("summonerexhaust"))
//		{
//			input->RawMagicalDamage *= .6f;
//			input->RawPhysicalDamage *= .6f;
//		}
//	}
//
//	if (target->IsHero())
//	{
//		auto target_spellbook = target->GetSpellBook();
//
//		if (target_spellbook)
//		{
//			if (!input->DontIncludePassives && target->HasBuff("vladimirhemoplaguedebuff"))
//			{
//				input->RawMagicalDamage *= 1.1f;
//				input->RawPhysicalDamage *= 1.1f;
//			}
//
//			switch (target->GetSkinData()->GetSkinHash())
//			{
//			case FNV("Annie"):
//			{
//				if (!input->DontIncludePassives)
//				{
//					if (target->HasBuff("AnnieE"))
//					{
//						input->RawPhysicalDamage *= .9f - (0.06f * target_spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level());
//						input->RawMagicalDamage *= .9f - (0.06f * target_spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level());
//					}
//				}
//
//				break;
//			}
//
//			case FNV("Alistar"):
//			{
//				if (!input->DontIncludePassives && target->HasBuff("FerociousHowl"))
//				{
//					auto const scalar = 0.55f + 0.1f * target_spellbook->GetSpellSlotByID((int)SpellSlot::R)->Level();
//
//					input->RawPhysicalDamage *= scalar;
//					input->RawMagicalDamage *= scalar;
//				}
//
//				break;
//			}
//
//			case FNV("Braum"):
//			{
//				if (!input->DontIncludePassives && target->HasBuff("braumeshieldbuff"))
//				{
//					auto const scalar = 1.f - (0.3f + 0.025f * target_spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level());
//
//					input->RawPhysicalDamage *= scalar;
//					input->RawMagicalDamage *= scalar;
//				}
//
//				break;
//			}
//
//			case FNV("Garen"):
//			{
//				if (!input->DontIncludePassives && target->HasBuff("GarenW"))
//				{
//					const auto& time_left = target->GetBuffManager()->GetBuffEntryByName("GarenW")->GetRemainingTime();
//
//					if (time_left > 0)
//					{
//						if (time_left > 3.25)
//						{
//							input->RawPhysicalDamage *= .3f;
//							input->RawMagicalDamage *= .3f;
//						}
//						else
//						{
//							input->RawMagicalDamage *= .6f;
//							input->RawPhysicalDamage *= .6f;
//						}
//					}
//				}
//
//				break;
//			}
//
//			case FNV("Gragas"):
//			{
//				if (!input->DontIncludePassives && target->HasBuff("gragaswself"))
//				{
//					auto const scalar = 1.f - (0.1f + 0.02f * target_spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level() + 0.04f * target->TotalAbilityPower());
//
//					input->RawPhysicalDamage *= scalar;
//					input->RawMagicalDamage *= scalar;
//				}
//
//				break;
//			}
//
//			case FNV("MasterYi"):
//			{
//				if (!input->DontIncludePassives && target->HasBuff("Meditate"))
//				{
//					auto const scalar = 1.f - (0.5f + 0.05f * target_spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level()) / (source->IsTurret() ? 2.f : 1.f);
//
//					input->RawPhysicalDamage *= scalar;
//					input->RawMagicalDamage *= scalar;
//				}
//
//				break;
//			}
//			}
//		}
//	}
//
//	if (input->IsCriticalAttack)
//	{
//		if (source_items->Infinity_Edge)
//		{
//			input->RawPhysicalDamage *= 2.25f;
//		}
//		else
//		{
//			input->RawPhysicalDamage *= 2.f;
//		}
//
//		if (target_items->Randuins_Omen)
//		{
//			input->RawPhysicalDamage *= 0.8f;
//		}
//	}
//
//	auto result = input->RawMagicalDamage + input->RawPhysicalDamage;
//
//#pragma region On Hit effects
//	if (!input->IsOnHitDamage && (input->AppliesOnHitDamage || input->IsAutoAttack) && source->IsHero())
//	{
//		DamageInput on_hit_input;
//
//		on_hit_input.IsOnHitDamage = TRUE;
//		on_hit_input.IsAbility = FALSE;
//		on_hit_input.IsAutoAttack = FALSE;
//		on_hit_input.AppliesOnHitDamage = FALSE;
//		on_hit_input.DoesntTriggerOnHitEffects = TRUE;
//
//		//if (!input->DontIncludePassives)
//		//{
//		//	auto namiE = source->GetBuffManager()->GetBuffEntryByName("NamiE");
//		//	if (namiE.Valid)
//		//	{
//		//		auto caster = namiE.Caster;
//
//		//		if (caster && caster->IsValid())
//		//		{
//		//			on_hit_input.RawMagicalDamage += (10.f + 15.f * caster->GetSpellBook()->GetSpellSlotByID((int)SpellSlot::E)->Level()) + .2f * caster->TotalAbilityPower();
//		//		}
//		//	}
//
//		//	auto sonaQ = source->GetBuff("sonaqprocattacker");
//		//	if (sonaQ.Valid)
//		//	{
//		//		auto caster = sonaQ.Caster;
//
//		//		if (caster && caster->IsValid())
//		//		{
//		//			on_hit_input.RawMagicalDamage += (10.f + 15.f * caster->GetSpellBook()->GetSpellSlotByID((int)SpellSlot::E)->Level()) + .2f * caster->TotalAbilityPower();
//		//		}
//		//	}
//		//}
//
//		if (!input->DontCalculateItemDamage && source_items->Blade_of_the_Ruined_King)
//		{
//			auto itemDamage = 0.08f * target->Health();
//
//			if (target->IsMinion() || target->IsJungle())
//				itemDamage = fmax(15.f, fmin(itemDamage, 60.0f));
//
//			on_hit_input.RawPhysicalDamage += itemDamage;
//		}
//
//		if (!input->DontCalculateItemDamage && source_items->Guinsoos_Rageblade)
//		{
//			on_hit_input.RawMagicalDamage += 15;
//		}
//
//		if (!input->DontCalculateItemDamage && source_items->Muramana && source->ManaPercent() > 20)
//		{
//			on_hit_input.RawPhysicalDamage += .06f * source->Mana();
//		}
//
//		if (!input->DontCalculateItemDamage && source_items->Nashors_Tooth)
//		{
//			on_hit_input.RawMagicalDamage += 15.f + .15f * source->TotalAbilityPower();
//		}
//
//		if (!input->DontCalculateItemDamage && source_items->Wits_End)
//		{
//			on_hit_input.RawMagicalDamage += 42.f;
//		}
//
//		if (!input->DontCalculateItemDamage && (source_items->Skirmishers_Sabre_Enchantment_Bloodrazor || source_items->Stalkers_Blade_Enchantment_Bloodrazor))
//		{
//			auto itemDamage = 0.04f * target->MaxHealth();
//
//			if (target->IsMinion() || target->IsJungle())
//				itemDamage = fmin(itemDamage, 75.0f);
//
//			on_hit_input.RawPhysicalDamage += itemDamage;
//		}
//
//		if (!input->DontCalculateItemDamage && source_items->Recurve_Bow)
//		{
//			on_hit_input.RawPhysicalDamage += 15;
//		}
//
//		if (!input->DoesntTriggerOnHitEffects)
//		{
//			if (!input->DontCalculateItemDamage && source_items->Sheen && (source->HasBuff("sheen") || input->IsAbility))
//			{
//				on_hit_input.RawPhysicalDamage += source->BaseAttackDamage();
//			}
//
//			if (!input->DontCalculateItemDamage && source_items->Iceborn_Gauntlet && (source->HasBuff("sheen") || input->IsAbility))
//			{
//				on_hit_input.RawPhysicalDamage += source->BaseAttackDamage();
//			}
//
//			if (!input->DontCalculateItemDamage && source_items->Lich_Bane && (source->HasBuff("lichbane") || input->IsAbility))
//			{
//				on_hit_input.RawMagicalDamage += 0.75f * source->BaseAttackDamage() + 0.5f * source->TotalAbilityPower();
//			}
//
//			if (!input->DontCalculateItemDamage && source_items->Trinity_Force && (source->HasBuff("sheen") || input->IsAbility))
//			{
//				on_hit_input.RawPhysicalDamage += 2.f * source->BaseAttackDamage();
//			}
//
//			if (!input->DontCalculateItemDamage && source_items->Duskblade_of_Draktharr)
//			{
//				//auto const buff = source->GetBuff("itemdusknightstalkerdamageproc");
//
//				//if (buff.Valid && buff.RemainingTime <= 4)
//				//{
//					on_hit_input.RawPhysicalDamage += 22.941f + 7.059f * source->Level();
//				//}
//			}
//
//			if (!input->DontCalculateItemDamage && source->IsMelee())
//			{
//				if (source_items->Titanic_Hydra)
//				{
//					on_hit_input.RawPhysicalDamage += source->HasBuff("itemtitanichydracleavebuff") ? (40.0f + 0.1f * source->MaxHealth()) : (5.0f + 0.01f * source->MaxHealth());
//				}
//			}
//
//			if (!input->DontCalculateItemDamage &&
//				source->HasBuff("itemstatikshankcharge") && source->BuffCount("itemstatikshankcharge") == 100)
//			{
//				float statikk = 0.0f;
//				float kircheis = 0.0f;
//				float rapid = 0.0f;
//
//				if (source_items->Statikk_Shiv)
//				{
//					int temp[] = { 60, 60, 60, 60, 60, 67, 73, 79, 85, 91, 97, 104, 110, 116, 122, 128, 134, 140 };
//					statikk += temp[source->Level() - 1];
//
//					if (input->IsCriticalAttack)
//					{
//						if (source_items->Infinity_Edge)
//						{
//							statikk *= 2.25f;
//						}
//						else
//						{
//							statikk *= 2.f;
//						}
//					}
//				}
//
//				if (source_items->Kircheis_Shard)
//				{
//					kircheis += 50.f;
//				}
//
//				if (source_items->Rapid_Firecannon)
//				{
//					int temp[] = { 60, 60, 60, 60, 60, 67, 73, 79, 85, 91, 97, 104, 110, 116, 122, 128, 134, 140 };
//					rapid += temp[source->Level() - 1];
//				}
//
//				on_hit_input.RawMagicalDamage = fmax(kircheis, fmax(rapid, statikk));
//			}
//		}
//
//		if (target->IsJungle())
//		{
//			if (!input->DontCalculateItemDamage)
//			{
//				if (source_items->Hunters_Machete_Upgraded)
//				{
//					on_hit_input.RawPhysicalDamage += 40;
//				}
//
//				if (source_items->Hunters_Machete)
//				{
//					on_hit_input.RawPhysicalDamage += 35;
//				}
//			}
//		}
//
//		switch (source->GetSkinData()->GetSkinHash())
//		{
//		case FNV("Irelia"):
//		{
//			if (!input->DontIncludePassives && source->HasBuff("ireliapassivestacksmax"))
//			{
//				on_hit_input.RawMagicalDamage += 12 + 3 * source->Level() + .25f * source->BonusAttackDamage();
//			}
//
//			break;
//		}
//		case FNV("MasterYi"):
//		{
//			if (!input->DontIncludePassives && source->HasBuff("wujustylesuperchargedvisual"))
//			{
//				on_hit_input.RawTrueDamage += 8.f * spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level() + 10.f + .35f * source->BonusAttackDamage();
//			}
//
//			break;
//		}
//		case FNV("MissFortune"):
//		{
//			if (!input->DontIncludePassives)
//			{
//				/*auto hasDoubleTap = !(g_ObjectManager->GetByType(EntityType::obj_GeneralParticleEmitter, [target](CObject* a)-> bool
//				{
//					return target->Distance(a) < target->BoundingRadius() * 0.1f && a->Name().find("MissFortune_Base_P_Mark") != std::string::npos;
//				})).empty();
//
//				if (!hasDoubleTap)
//				{
//					auto level = source->Level();
//					auto currentPassive = level >= 13 ? 1.f
//						: level >= 11 ? 0.9f
//						: level >= 9 ? 0.8f
//						: level >= 7 ? 0.7f
//						: level >= 4 ? 0.6f
//						: 0.5f;
//
//					auto bonus = currentPassive * source->TotalAttackDamage();
//					if (target->IsMinion())
//					{
//						bonus /= 2.f;
//					}
//
//					on_hit_input.RawPhysicalDamage += bonus;
//				}
//
//				break;*/
//			}
//		}
//		}
//
//		if (on_hit_input.RawPhysicalDamage || on_hit_input.RawMagicalDamage)
//		{
//			result += CalculateDamageOnUnit(source, target, &on_hit_input);
//		}
//		else if (on_hit_input.RawTrueDamage)
//		{
//			result += on_hit_input.RawTrueDamage;
//		}
//	}
//#pragma endregion
//
//	if (target->IsHero())
//	{
//		// UNIQUE: Blocks 12 damage from all champions sources (3 damage vs. damage over time abilities).
//		if (!input->DontCalculateItemDamage && target_items->Guardians_Horn)
//		{
//			result -= 12;
//		}
//
//		// Bone Plating rune
//		if (!input->DontIncludePassives && (input->IsAbility || input->IsAutoAttack) && target_perks->BonePlating && target->HasBuff("ASSETS/Perks/Styles/Resolve/BonePlating/BonePlating.lua"))
//		{
//			result -= GetRiotScalar(1, 18, source->Level(), 15, 40);
//		}
//	}
//
//#pragma region Percent Damage reductors
//
//	//Baron's buff
//	if (!input->DontIncludePassives && target->IsMinion() && target->HasBuff("exaltedwithbaronnashorminion"))
//	{
//		if (target->IsMelee())
//		{
//			if (source->IsHero() || source->IsMinion())
//			{
//				result *= 0.25f;
//			}
//
//			if (source->IsTurret())
//			{
//				result *= 0.7f;
//			}
//		}
//		else
//		{
//			// caster minion
//			if (source->GetSkinData()->GetSkinHash() == SkinHash::HA_ChaosMinionRanged)
//			{
//				if (source->IsHero())
//				{
//					result *= 0.5f;
//				}
//			}
//		}
//	}
//
//	if (!input->DontIncludePassives && source->IsMinion() && source->HasBuff("exaltedwithbaronnashorminion"))
//	{
//		if (source->IsRanged() && target->IsTurret())
//		{
//			// Siege minion
//			if (source->IsSiegeMinion())
//			{
//				result *= 2.0f;
//			}
//		}
//	}
//
//	// Ninja Tabi
//	// UNIQUE: Reduces incoming damage from all basic attacks by 12% (excluding turret shots). 
//	// Does not reduce damage of on-hit effects, it does however reduce damage of basic attack modifiers.
//	if (!input->DontCalculateItemDamage && !source->IsTurret())
//	{
//		if ((input->IsCriticalAttack || input->IsAutoAttack) && !input->IsOnHitDamage)
//		{
//			if (target_items->Ninja_Tabi)
//			{
//				result *= 0.88;
//			}
//		}
//	}
//
//	if (!input->DontIncludePassives && source->IsTurret() && target->IsMinion())
//	{
//		if (target->IsMelee())
//		{
//			result *= 0.7f;
//		}
//	}
//
//	// Unique Passive - Warming Up: Turrets gain 40% damage each time they strike a champion (Max 120% bonus damage).
//	if (!input->DontIncludePassives && source->IsTurret() && target->IsHero())
//	{
//		result *= 1.4f;
//	}
//
//	// Minions deal 40% reduced damage to turrets and enemy champions
//	if (!input->DontIncludePassives && source->IsMinion() &&
//		(target->IsHero() || target->IsTurret()))
//	{
//		result *= 0.6f;
//	}
//
//	// TODO Galio
//	// ACTIVE: Galio designates the target allied champion's location at the time of cast as his landing spot, 
//	// channels for 1.25 seconds, and then dashes to them, reducing the damage they take until he lands
//	// 20 / 25 / 30% (+ 8% per 100 bonus magic resistance)
//
//#pragma endregion
//
//	return result + input->RawTrueDamage;
//}
//
//float GetAutoAttackDamage(CObject* source, CObject* target, bool respect_passives = false)
//{
//	//if (!source->IsAIBase() || !target->IsAIBase())
//	//	return 0.f;
//
//	// Wards
//	if (target->IsMinion() && target->MaxHealth() >= 0.f && target->MaxHealth() <= 6.f)
//		return 1.f;
//
//	//if (source->IsTurret() && target->IsMinion())
//	//{
//	//	float hp = target->MaxHealth();
//	//	float ar = target->Armor();
//
//	//	bool isMelee = target->IsMelee();
//	//	bool isSiege = target->IsSiegeMinion();
//
//	//	float armor = ar * 0.7f;
//	//	float result = hp * (isMelee ? 0.45f : 0.68f);
//
//	//	//if (isSiege)
//	//	//{
//	//	//	std::string name = source->BaseSkinName();
//	//	//	int turret_id = name.back() - 48;
//
//	//	//	if (turret_id == 1)
//	//	//	{
//	//	//		result = hp * 0.14f;
//	//	//	}
//	//	//	else if (turret_id == 2)
//	//	//	{
//	//	//		result = hp * 0.11f;
//	//	//	}
//	//	//	else
//	//	//	{
//	//	//		result = hp * 0.08f;
//	//	//	}
//	//	//}
//
//	//	//if (strstr(target->BaseSkinName().c_str(), "MinionSuper") != nullptr)
//	//	//{
//	//	//	result = hp * 0.05f;
//	//	//}
//
//	//	//if (armor >= 0)
//	//	//	result = result * (1.0f - (armor / (100.0f + armor)));
//	//	//else
//	//	//	result = result * (1.0f - (armor / (100.0f - armor)));
//
//	//	return result;
//	//}
//
//	float result = 0.f;
//	DamageInput input;
//	input.RawPhysicalDamage = source->TotalAttackDamage();
//	input.IsAutoAttack = true;
//	input.IsAbility = false;
//	input.DontIncludePassives = !respect_passives;
//	input.DontCalculateItemDamage = !respect_passives;
//
//	if (source->IsHero() && source->GetSkinData()->GetSkinHash() == SkinHash::Corki)
//	{
//		input.RawPhysicalDamage = source->TotalAttackDamage() * 0.2f;
//		input.RawMagicalDamage = source->TotalAttackDamage() * 0.8f;
//	}
//
//	if (source->IsHero() && respect_passives)
//	{
//		auto perks = GetPerks(source);
//
//		// Press the Attack rune
//		if (perks->PressTheAttack)
//		{
//			const auto buff = target->BuffCount("ASSETS/Perks/Styles/Precision/PressTheAttack/PressTheAttackStack.lua");
//
//			if (buff)
//			{
//				if (buff == 2)
//				{
//					const auto damage = GetRiotScalar(1, 18, source->Level(), 40, 180);
//
//					// ADAPTIVE DAMAGE: Deals either physical or magic damage depending on your bonus statistics, defaulting to physical damage.
//					if (source->BonusAttackDamage() == source->BonusMagicDamage() || source->BonusAttackDamage() > source->BonusMagicDamage())
//					{
//						input.RawPhysicalDamage += damage;
//					}
//					else
//					{
//						input.RawMagicalDamage += damage;
//					}
//				}
//			}
//		}
//
//		// Grasp of the Undying rune
//		if (perks->GraspOfTheUndying && source->HasBuff("ASSETS/Perks/Styles/Resolve/GraspOfTheUndying/GraspOfTheUndyingONH.lua"))
//		{
//			input.RawMagicalDamage += source->MaxHealth() * (source->IsMelee() ? 0.04f : 0.024f);
//		}
//
//		// Dark Harvest rune
//		if (perks->DarkHarvest && target->HasBuff("ASSETS/Perks/Styles/Domination/DarkHarvest/DarkHarvestSoulcharged.lua"))
//		{
//			const auto buff = source->HasBuff("ASSETS/Perks/Styles/Domination/DarkHarvest/DarkHarvest.lua");
//
//			if (buff)
//			{
//				const auto damage = GetRiotScalar(1, 18, source->Level(), 40, 80) + source->BonusAttackDamage() * 0.25f + source->TotalAbilityPower() * 0.2f;// + //buff->Count();
//
//				// ADAPTIVE DAMAGE: Deals either physical or magic damage depending on your bonus statistics, defaulting to physical damage.
//				if (source->BonusAttackDamage() == source->BonusMagicDamage() || source->BonusAttackDamage() > source->BonusMagicDamage())
//				{
//					input.RawPhysicalDamage += damage;
//				}
//				else
//				{
//					input.RawMagicalDamage += damage;
//				}
//			}
//		}
//
//		// RedBuff
//		if (!source->IsTurret() && source->HasBuff("BlessingoftheLizardElder") && !target->HasBuff("Bruning"))
//		{
//			// we calculate only first TICK
//			input.RawTrueDamage += 2.0f + 2.0f * source->Level();
//		}
//
//		if (target->IsMinion())
//		{
//			if (source->HasItem(kItemID::DoransShield) ||
//				source->HasItem(kItemID::DoransRing))
//			{
//				input.RawPhysicalDamage += 5.f;
//			}
//		}
//
//		const auto spellbook = source->GetSpellBook();
//		if (spellbook)
//		{
//			switch (source->GetSkinData()->GetSkinHash())
//			{
//			case FNV("Aatrox"):
//				if (source->HasBuff("AatroxWONHPowerBuff"))
//				{
//					auto spell_level = spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level();
//					input.RawPhysicalDamage += 10.0f + (35.0f * spell_level) + (source->BonusAttackDamage() * 0.75F);
//				}
//				break;
//			case FNV("Alistar"):
//				if (source->HasBuff("alistartrample"))
//					input.RawMagicalDamage += 40.0f + 10 * source->Level();
//				break;
//			case FNV("Ashe"):
//				if (source->HasBuff("asheqbuff"))
//				{
//					auto spell_level = spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level();
//					input.RawPhysicalDamage += (100.0f + 5.0f * spell_level) / 100.0f * source->TotalAttackDamage();
//				}
//				if (target->HasBuff("ashepassiveslow"))
//				{
//					input.RawPhysicalDamage += (0.1f + source->Crit() / 100.f * (1 + (source->HasItem(kItemID::InfinityEdge) ? 0.5f : 0))) * source->TotalAttackDamage();
//				}
//				break;
//			case FNV("Blitzcrank"):
//				if (source->HasBuff("PowerFist"))
//					input.RawPhysicalDamage += source->TotalAttackDamage();
//				break;
//
//			case FNV("Braum"):
//				if (target->HasBuff("braummarkcounter") && target->BuffCount("braummarkcounter") == 3)
//					input.RawMagicalDamage += 16.0f + 10.0f * source->Level();
//
//				if (target->HasBuff("braummarkstunreduction"))
//					input.RawMagicalDamage += 6.4f + 1.6f * source->Level();
//				break;
//
//			case FNV("Caitlyn"):
//				if (source->HasBuff("caitlynheadshot"))
//				{
//					auto mod = 0.5f;
//
//					if (source->Level() > 13)
//						mod = 1.0f;
//					else if (source->Level() > 7)
//						mod = 0.75f;
//
//					auto has_inifnity = source->HasItem(kItemID::InfinityEdge);
//
//					if (target->IsMinion())
//					{
//						input.RawPhysicalDamage += source->TotalAttackDamage() * (1 + ((1.25f + (has_inifnity ? 0.15625f : 0)) * source->Crit()));
//					}
//					else
//					{
//						input.RawPhysicalDamage += source->TotalAttackDamage() * (mod + ((1.25f + (has_inifnity ? 0.15625f : 0)) * source->Crit()));
//					}
//
//					break;
//				}
//			case FNV("Camille"):
//				if (source->HasBuff("CamilleQ") || source->HasBuff("CamilleQ2"))
//				{
//					auto spell_lvl = spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level();
//					auto qdmg = (0.15f + 0.05f * spell_lvl) * source->TotalAttackDamage();
//
//					if (source->HasBuff("CamilleQPrimingComplete"))
//						input.RawTrueDamage += fmin(1, 0.36f + 0.04f * fmin(16, source->Level())) * qdmg;
//
//					input.RawPhysicalDamage += qdmg;
//				}
//				break;
//			case FNV("Chogath"):
//				if (source->HasBuff("VorpalSpikes"))
//					input.RawMagicalDamage += 10.0f + 10.0f * spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level() + 0.03f * target->MaxHealth();
//				break;
//			case FNV("Darius"):
//				if (source->HasBuff("DariusNoxianTacticsONH"))
//					input.RawPhysicalDamage += (.5f + .05f * (spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level() - 1)) * source->TotalAttackDamage();
//				break;
//			case FNV("Diana"):
//				if (target->HasBuff("dianapassivemarker") && target->BuffCount("dianapassivemarker") == 2)
//				{
//					int tab[] = { 20, 25, 30, 35, 40, 50, 60, 70, 80, 90, 105, 120, 135, 155, 175, 200, 225, 250 };
//
//					input.RawMagicalDamage += tab[source->Level() - 1] + 0.8f * source->BaseAttackDamage();
//				}
//				break;
//			case FNV("Draven"):
//				if (source->HasBuff("dravenspinningattack"))
//				{
//					int spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level();
//					input.RawPhysicalDamage += (25 + 5 * spellLvl) + (source->BonusAttackDamage() * (0.55f + spellLvl * 0.1f));
//				}
//				break;
//			case FNV("Fizz"):
//				if (source->HasBuff("FizzSeastonePassive"))
//				{
//					int spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level();
//
//					input.RawMagicalDamage += 10.0f + 15.0f * spellLvl + 0.333f * source->BaseAttackDamage();
//				}
//				if (source->HasBuff("FizzWActive"))
//				{
//					auto dmg = 10.0f + (15.0f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level()) + (source->TotalAbilityPower() * 0.333f);
//
//					if (target->HasBuff("fizzwdot"))
//						dmg *= 3.0f;
//
//					input.RawMagicalDamage += dmg;
//				}
//				break;
//			case FNV("Garen"):
//				if (source->HasBuff("GarenQ"))
//				{
//					int spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level();
//					input.RawPhysicalDamage += 5.0f + 25.0f * spellLvl + 0.4f * source->TotalAttackDamage();
//				}
//				break;
//			case FNV("Graves"):
//			{
//				int tab[] = { 70, 71, 72, 74, 75, 76, 78, 80, 81, 83, 85, 87, 89, 91, 95, 96, 97, 100 };
//				input.RawPhysicalDamage *= tab[source->Level() - 1] / 100.0f;
//				break;
//			}
//			case FNV("Gnar"):
//				if (target->HasBuff("gnarwproc") && target->BuffCount("gnarwproc") == 2)
//				{
//					auto spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level();
//					input.RawMagicalDamage += 10.0f * spellLvl + fmin(target->MaxHealth() * (4.0f + 2.0f * spellLvl) / 100.0f, 50.0f * spellLvl + 50.0f);
//				}
//				break;
//			case FNV("Gragas"):
//				if (source->HasBuff("gragaswattackbuff"))
//					input.RawMagicalDamage += -10.0f + 30.0f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level() + 0.3f * source->TotalAbilityPower() + 0.08f * target->MaxHealth();
//				break;
//			case FNV("Hecarim"):
//				if (source->HasBuff("HecarimRamp"))
//				{
//					int spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level();
//					input.RawPhysicalDamage += 5.0f + (35.0f * spellLvl) + 0.5f * source->BonusAttackDamage();
//				}
//				break;
//			case FNV("JarvanIV"):
//				if (!target->HasBuff("jarvanivmartialcadencecheck"))
//					input.RawPhysicalDamage += fmin(400.0f, 0.1f * target->Health());
//
//				break;
//			case FNV("Jax"):
//				if (source->HasBuff("JaxEmpowerTwo"))
//				{
//					int spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level();
//					input.RawMagicalDamage += 5.0f + 35.0f * spellLvl + 0.6f * source->BaseAttackDamage();
//				}
//				break;
//			case FNV("Jayce"):
//				if (source->HasBuff("jaycepassivemeleeattack"))
//				{
//					int spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::R)->Level();
//					input.RawMagicalDamage += -20.0f + 40.0f * spellLvl + 0.4f * source->BaseAttackDamage();
//				}
//				break;
//			case FNV("Jinx"):
//				if (source->HasBuff("JinxQ"))
//					input.RawPhysicalDamage *= 1.1f;
//				break;
//			case FNV("Kalista"):
//				input.RawPhysicalDamage *= 0.9f;
//				break;
//			case FNV("Katarina"):
//				if (target->HasBuff("katarinaqmark"))
//					input.RawMagicalDamage += source->Level() / 1.75f + 3.0f * source->Level() + 71.5f + source->BonusAttackDamage() +
//					(0.55f + 0.15f * (int)((source->Level() - 1) / 5)) * source->TotalAbilityPower();
//				break;
//			case FNV("Kassadin"):
//			{
//				int spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level();
//
//				if (spellLvl > 0)
//					input.RawMagicalDamage += 20.0f + 0.1f * source->BaseAttackDamage();
//
//				if (source->HasBuff("NetherBladeArmorPen"))
//					input.RawMagicalDamage += -5.0f + 25.0f * spellLvl + 0.6f * source->BaseAttackDamage();
//
//				break;
//			}
//			case FNV("Kayle"):
//			{
//				int spellLvl = spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level();
//				if (spellLvl > 0)
//				{
//					input.RawMagicalDamage += 5.0f + 5.0f * spellLvl + 0.15f * source->TotalAbilityPower();
//					if (source->HasBuff("JudicatorRighteousFury"))
//						input.RawMagicalDamage += 5.0f + 5.0f * spellLvl + 0.15f * source->TotalAbilityPower();
//
//				}
//				break;
//			}
//			case FNV("Kennen"):
//				if (source->HasBuff("kennendoublestrikelive"))
//					input.RawMagicalDamage += (0.3f + 0.1f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level()) * source->TotalAttackDamage();
//				break;
//			case FNV("Khazix"):
//				if (source->HasBuff("KhazixPDamage") && target->IsHero())
//					input.RawMagicalDamage += 2 + (source->Level() * 8) + 0.4f * source->BonusAttackDamage();
//				break;
//			case FNV("KogMaw"):
//				if (source->HasBuff("KogMawBioArcaneBarrage"))
//				{
//					DamageInput kogW;
//					kogW.IsAbility = false;
//					kogW.RawMagicalDamage = target->MaxHealth() * ((1 + spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level() + (int)(source->TotalAbilityPower() / 100)) / 100.f);
//
//					const auto dmg = CalculateDamageOnUnit(source, target, &kogW);
//
//					if (target->IsMinion())
//						result += fmin(dmg, 100);
//					else
//						result += dmg;
//				}
//				break;
//			case FNV("Leona"):
//				if (source->HasBuff("LeonaShieldOfDaybreak"))
//					input.RawMagicalDamage += 10.0f + 30.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level() + 0.3f * source->BaseAttackDamage();
//				break;
//			case FNV("Lux"):
//				if (target->HasBuff("LuxIlluminatingFraulein"))
//					input.RawMagicalDamage += 10.0f + 10.0f * source->Level() + 0.2f * source->TotalAbilityPower();
//				break;
//			case FNV("Orianna"):
//				input.RawMagicalDamage += 10 + (8 * int((source->Level() - 1) / 3)) + 0.15f * source->TotalAbilityPower();
//
//				break;
//			case FNV("Malphite"):
//				if (source->HasBuff("MalphiteCleave"))
//					input.RawPhysicalDamage += 15.0f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level();
//				break;
//			case FNV("Mordekaiser"):
//			{
//				auto mordQBase = 10.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level() + ((0.4f + 0.1f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level()) * source->TotalAttackDamage()) + 0.6f * source->TotalAbilityPower();
//				if (source->HasBuff("mordekaisermaceofspades1") || source->HasBuff("mordekaisermaceofspades15"))
//					input.RawMagicalDamage += mordQBase;
//
//				if (source->HasBuff("mordekaisermaceofspades2"))
//					input.RawMagicalDamage += mordQBase * 2.0f;
//
//				break;
//			}
//			case FNV("Nasus"):
//				if (source->HasBuff("NasusQ"))
//					input.RawPhysicalDamage += fmax(source->BuffCount("nasusqstacks"), 0.0f) + 10.0f + 20.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level();
//				break;
//			case FNV("Nocturne"):
//				if (source->HasBuff("nocturneumbrablades"))
//					input.RawPhysicalDamage += 1.2f * source->TotalAttackDamage();
//				break;
//			case FNV("Pantheon"):
//				if (target->HealthPercent() < 15)
//				{
//					auto e = spellbook->GetSpellSlotByID((int)SpellSlot::E);
//
//					if (e->Level() > 0)
//						input.IsCriticalAttack = true;
//				}
//				break;
//			case FNV("Riven"):
//				if (target->HasBuff("rivenpassiveaaboost") && target->BuffCount("rivenpassiveaaboost") > 0)
//					input.RawPhysicalDamage += (20.0f + 5.0f * (int)trunc((source->Level() + 2.0f) / 3.0f)) * source->TotalAttackDamage() / 100.0f;
//				break;
//			case FNV("Shaco"):
//				if (source->HasBuff("Deceive"))
//					input.RawPhysicalDamage += 5.0f + 15.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level() + 0.4f * source->BaseAttackDamage();
//				break;
//			case FNV("Teemo"):
//				if (source->HasBuff("ToxicShot"))
//					input.RawMagicalDamage += 0.3f * source->TotalAbilityPower() + 10.0f * spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level();
//				break;
//
//			case FNV("Quinn"):
//				if (target->HasBuff("QuinnW"))
//					input.RawPhysicalDamage += 0.5f * source->TotalAttackDamage();
//				break;
//			case FNV("Kaisa"):
//			{
//
//				auto stacks = target->HasBuff("kaisapassivemarker") ? target->BuffCount("kaisapassivemarker") : 0;
//				auto level = source->Level();
//				auto currentPassive = level >= 17 ? 10
//					: level >= 14 ? 9
//					: level >= 11 ? 8
//					: level >= 9 ? 7
//					: level >= 6 ? 6
//					: level >= 3 ? 5
//					: 4;
//
//				auto perStack = level >= 16 ? 5
//					: level >= 12 ? 4
//					: level >= 8 ? 3
//					: level >= 4 ? 2
//					: 1;
//
//				input.RawMagicalDamage += currentPassive + source->TotalAbilityPower() * (0.1f + 0.025f * stacks) + perStack * stacks;
//
//				if (stacks == 4)
//				{
//					auto missing_health = target->MaxHealth() - target->Health();
//					input.RawMagicalDamage += (.15f + (.025f * (source->TotalAbilityPower() / 100.f))) * missing_health;
//				}
//
//				break;
//			}
//
//			case FNV("Thresh"):
//			{
//				auto elevel = spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level();
//				if (elevel > 0)
//				{
//					auto v = target->HasBuff("threshpassivesoulsgain") ? target->BuffCount("threshpassivesoulsgain") : 0;
//					v += (0.5f + 0.3f * elevel) * source->TotalAttackDamage();
//					if (source->HasBuff("threshepassive4"))
//					{
//						v /= 1.0f;
//					}
//					else if (source->HasBuff("threshepassive3"))
//					{
//						v /= 2.0f;
//					}
//					else if (source->HasBuff("threshepassive2"))
//					{
//						v /= 3.0f;
//					}
//					else
//					{
//						v /= 4.0f;
//					}
//					input.RawMagicalDamage += v;
//				}
//			}
//			break;
//			case FNV("TwistedFate"):
//			{
//				if (source->HasBuff("CardMasterStackParticle"))
//				{
//					input.RawMagicalDamage += 25.0f * spellbook->GetSpellSlotByID((int)SpellSlot::E)->Level() + 30 + 0.5f * source->TotalAbilityPower();
//				}
//				if (source->HasBuff("BlueCardPreAttack"))
//				{
//					input.RawMagicalDamage = input.RawPhysicalDamage;
//					input.RawPhysicalDamage = 0;
//					input.RawMagicalDamage += 20.0f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level() + 20.f + 0.5f * source->TotalAbilityPower();
//				}
//				else if (source->HasBuff("RedCardPreAttack"))
//				{
//					input.RawMagicalDamage = input.RawPhysicalDamage;
//					input.RawPhysicalDamage = 0;
//					input.RawMagicalDamage += 15.0f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level() + 15.f + 0.5f * source->TotalAbilityPower();
//				}
//				else if (source->HasBuff("GoldCardPreAttack"))
//				{
//					input.RawMagicalDamage = input.RawPhysicalDamage;
//					input.RawPhysicalDamage = 0;
//					input.RawMagicalDamage += 7.5f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level() + 7.5f + 0.5f * source->TotalAbilityPower();
//				}
//			}
//			case FNV("Udyr"):
//				if (source->HasBuff("UdyrTigerStance"))
//					input.RawPhysicalDamage += 1.15f * source->TotalAttackDamage();
//				if (source->HasBuff("UdyrTigerPunch"))
//					input.RawPhysicalDamage += -10.0f + (25.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level()) + (0.55f + 0.05f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level()) * source->TotalAttackDamage();
//
//				if (target->HasBuff("UdyrPhoenixStance") && target->BuffCount("UdyrPhoenixStance") > 2)
//					input.RawMagicalDamage += 40.0f * spellbook->GetSpellSlotByID((int)SpellSlot::R)->Level() + 0.45f * source->TotalAbilityPower();
//				break;
//			case FNV("Varus"):
//				if (spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level() > 0)
//					input.RawMagicalDamage += 10.0f + 4.0f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level() + 0.25f * source->TotalAbilityPower();
//				break;
//			case FNV("Yorick"):
//				if (source->HasBuff("YorickQBuff"))
//					input.RawPhysicalDamage += 5.0f + (25.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level()) + 0.4f * source->TotalAttackDamage();
//				break;
//			case FNV("Vayne"):
//			{
//				if (source->HasBuff("VayneTumble"))
//					input.RawPhysicalDamage += (0.25f + 0.05f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level()) * source->TotalAttackDamage();
//
//				if (target->HasBuff("VayneSilverDebuff") && target->BuffCount("VayneSilverDebuff") == 2)
//				{
//					float wDmg[] = { 0, 0.04f, 0.065f, 0.09f, 0.115f, 0.14f };
//					auto wLevel = spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level();
//
//					input.RawTrueDamage = target->IsMinion() ?
//						fmin(200, fmax(50 + wLevel * 15, target->MaxHealth() * wDmg[wLevel])) :
//						fmax(50 + (wLevel - 1) * 15, target->MaxHealth() * wDmg[wLevel]);
//				}
//				break;
//			}
//			case FNV("Volibear"):
//				if (source->HasBuff("VolibearQ"))
//					input.RawPhysicalDamage += 30.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level();
//				break;
//			case FNV("Warwick"):
//				input.RawMagicalDamage += 8 + 2 * source->Level();
//				break;
//			case FNV("MonkeyKing"):
//				if (source->HasBuff("MonkeyKingDoubleAttack"))
//					input.RawPhysicalDamage += 30.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level() + 0.1f * source->TotalAttackDamage();
//				break;
//			case FNV("XinZhao"):
//				if (source->HasBuff("XenZhaoComboTarget"))
//					input.RawPhysicalDamage += 15.0f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level() + 0.2f * source->TotalAttackDamage();
//				break;
//
//			case FNV("Zed"):
//				if (target->HealthPercent() <= 50 && !target->HasBuff("zedpassivecd"))
//					input.RawMagicalDamage += target->MaxHealth() * ((int)trunc((source->Level() - 1.0f) / 6.0f) * 2.0f + 6.0f) / 100.0f;
//
//				break;
//			}
//		}
//	}
//
//	if (source->IsHero() && source->Crit() == 1.f)
//		input.IsCriticalAttack = TRUE;
//
//	result += CalculateDamageOnUnit(source, target, &input);
//
//	/** TODO
//	** SEPARATED AUTOATTACKS CALCULATIONS HAVE
//	** WRONG RESULTS WITH BOTRK AS EACH AUTOATTACK HAPPEN AFTER ANOTHER
//	** SO BOTRK FOR NEXT AUTOATTACK IS CALCULATED AFTER PREVIOUS AUTOATTACK HITS
//	** Expected result:
//	**
//	** first hit: 1000 hp botrk damage: 80
//	** second hit: 920 hp botrk damage: 73.6
//	** in total:						153.6
//	**
//	** instead we get from dmg lib:		160
//	**
//	** temp fix: dont calculate onhiteffects if target is minion so we dont miss cs
//	**/
//	if (respect_passives && source->IsHero())
//	{
//		switch (source->GetSkinData()->GetSkinHash())
//		{
//		case FNV("Fiora"):
//			if (source->HasBuff("fiorae2"))
//				result *= 1.55;
//			break;
//
//		case FNV("MasterYi"):
//			if (source->HasBuff("doublestrike"))
//			{
//				DamageInput double_strike;
//
//				double_strike.IsOnHitDamage = target->IsMinion();
//				double_strike.IsAbility = FALSE;
//				double_strike.IsAutoAttack = TRUE;
//				double_strike.DoesntTriggerOnHitEffects = TRUE;
//				double_strike.RawPhysicalDamage = .5f * source->TotalAttackDamage();
//
//				result += CalculateDamageOnUnit(source, target, &double_strike);
//			}
//			break;
//
//		case FNV("Shyvana"):
//			if (source->HasBuff("ShyvanaDoubleAttack"))
//			{
//				const auto spellbook = source->GetSpellBook();
//				if (spellbook)
//				{
//					DamageInput double_attack;
//
//					double_attack.IsOnHitDamage = target->IsMinion();
//					double_attack.IsAbility = FALSE;
//					double_attack.IsAutoAttack = TRUE;
//					double_attack.DoesntTriggerOnHitEffects = TRUE;
//					double_attack.RawPhysicalDamage = (0.05f + 0.15f * spellbook->GetSpellSlotByID((int)SpellSlot::Q)->Level()) * source->TotalAttackDamage();
//
//					result += CalculateDamageOnUnit(source, target, &double_attack);
//				}
//			}
//			break;
//
//		case FNV("Renekton"):
//			if (source->HasBuff("RenektonExecuteReady"))
//			{
//				const auto spellbook = source->GetSpellBook();
//				if (spellbook)
//				{
//					DamageInput execution;
//
//					execution.IsOnHitDamage = target->IsMinion();
//					execution.IsAbility = FALSE;
//					execution.IsAutoAttack = TRUE;
//					execution.DoesntTriggerOnHitEffects = TRUE;
//					execution.RawPhysicalDamage = (-5.0f + (10.0f * spellbook->GetSpellSlotByID((int)SpellSlot::W)->Level())) + .75f * source->TotalAttackDamage();
//
//					return CalculateDamageOnUnit(source, target, &execution) * (source->Mana() < 50 ? 2 : 3);
//				}
//			}
//			break;
//
//		case FNV("Lucian"):
//			if (source->HasBuff("lucianpassivebuff"))
//			{
//				DamageInput double_attack;
//
//				double_attack.IsOnHitDamage = target->IsMinion();
//				double_attack.IsAbility = FALSE;
//				double_attack.IsAutoAttack = TRUE;
//				double_attack.DoesntTriggerOnHitEffects = TRUE;
//				double_attack.RawPhysicalDamage = (target->IsMinion() ? 1 : (source->Level() >= 13 ? 0.6f : source->Level() >= 7 ? 0.55f : 0.5f)) * source->TotalAttackDamage();
//
//				result += CalculateDamageOnUnit(source, target, &double_attack);
//			}
//			break;
//		}
//	}
//
//	return result;
//}
//