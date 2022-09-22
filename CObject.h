#pragma once
#include "Offsets.h"
#include "Memory.h"
#include "Macros.h"
#include "Assembly.h"

#include "CSpellBook.h"
#include "CInventory.h"
#include "CBuffManager.h"
#include "CAIManger.h"
#include "CSkinData.h"
#include <vector>

typedef uint32_t hash32_t;

constexpr uint32_t val_32_const = 0x811c9dc5;
constexpr uint32_t prime_32_const = 0x1000193;

constexpr char constexpr_ch_to_lower(char c)
{
	if (c >= 'A' && c <= 'Z') return c + 32;

	return c;
}

__forceinline constexpr hash32_t kHash32(const char* const str, const uint32_t value = val_32_const) noexcept
{
	return (str[0] == '\0') ? value : kHash32(&str[1], (value ^ uint32_t(str[0])) * prime_32_const);
}
__forceinline constexpr hash32_t kHash32l(const char* const str, const uint32_t value = val_32_const) noexcept
{
	return (str[0] == '\0') ? value : kHash32l(&str[1], (value ^ uint32_t(constexpr_ch_to_lower(str[0]))) * prime_32_const);
}

int IsFunc(DWORD param1, int param2)
{
	if (!param1)
		return 0;

	int v2;
	int v3;
	int v4;

	v4 = RPM<int>(param1 + 0x5c + (RPM<byte>(param1 + 0x58)) * 4);
	v3 = param1 + 0x54;
	v2 = RPM<int>(v3);
	v4 ^= ~v2;

	return ((param2 & v4) != 0);
}

enum class GameObjectOrder
{
	HoldPosition = 1,
	MoveTo,
	AttackUnit,
	AutoAttackPet,
	AutoAttack,
	MovePet,
	AttackTo,
	Stop = 10
};

enum kDamageType
{
	DamageType_Physical,
	DamageType_Magical,
	DamageType_True,
	DamageType_Adaptive
};

enum CharacterState
{
	CanAttack = 1,
	CanCast = 2,
	CanMove = 4,
	Immovable = 8,
	Unknownz = 16,
	IsStealth = 32,
	Taunted = 64,
	Feared = 128,
	Fleeing = 256,
	Supressed = 512,
	Asleep = 1024,
	NearSight = 2048,
	Ghosted = 4096,
	HasGhost = 8192,
	Charmed = 16384,
	NoRender = 32768,
	DodgePiercing = 131072,
	DisableAmbientGold = 262144,
	DisableAmbientXP = 524288,
	ForceRenderParticles = 65536,
	IsCombatEnchanced = 1048576,
	IsSelectable = 16777216
};

enum CharacterStatez
{
	GameObjectActionState_CanAttack = 1 << 0,
	GameObjectActionState_CanCrit = 1 << 1,
	GameObjectActionState_CanCast = 1 << 2,
	GameObjectActionState_CanMove = 1 << 3,
	GameObjectActionState_Immovable = 1 << 4,  //check caitlyn ult 
	GameObjectActionState_Stealthed = 1 << 5,
	GameObjectActionState_Obscured = 1 << 6,
	GameObjectActionState_Taunted = 1 << 7,
	GameObjectActionState_Feared = 1 << 8,
	GameObjectActionState_Fleeing = 1 << 9,
	GameObjectActionState_Supressed = 1 << 10,
	GameObjectActionState_Sleep = 1 << 11,
	GameObjectActionState_Ghosted = 1 << 13,
	GameObjectActionState_Charmed = 1 << 17,
	GameObjectActionState_Slowed = 1 << 24,
};

enum kGameObjectStatusFlags
{
	GameObjectStatusFlags_Invulnerable = 1 << 0,
	GameObjectStatusFlags_MagicImmune = 1 << 6,
	GameObjectStatusFlags_PhysicalImmune = 1 << 7,
	Invulnerable = 1, //zhonyas, kayle ult, taric can't attack him
	Immune = 4, //olaf R
	//Unkillable = 16, //tryndamere R
	Channeling = 512, //fiddle drain
};

enum ObjectType
{
	//x << y = x*pow(2,y)
	//x >> y = x/pow(2,y)
	GameObjectFlags_GameObject = (1 << 0),  //0x1
	GameObjectFlags_NeutralCamp = (1 << 1),  //0x2
	GameObjectFlags_DeadObject = (1 << 4),  //0x10
	GameObjectFlags_InvalidObject = (1 << 5),  //0x20
	GameObjectFlags_AIBaseCommon = (1 << 7),  //0x80
	GameObjectFlags_AttackableUnit = (1 << 9),  //0x200
	GameObjectFlags_AI = (1 << 10), //0x400
	GameObjectFlags_Minion = (1 << 11), //0x800
	GameObjectFlags_Hero = (1 << 12), //0x1000
	GameObjectFlags_Turret = (1 << 13), //0x2000
	GameObjectFlags_Unknown0 = (1 << 14), //0x4000
	GameObjectFlags_Missile = (1 << 15), //0x8000
	GameObjectFlags_Unknown1 = (1 << 16), //0x10000
	GameObjectFlags_Building = (1 << 17), //0x20000
	GameObjectFlags_Unknown2 = (1 << 18), //0x40000
};

enum class SpellState
{
	Ready = 0,
	DoesNotExist = 2,
	NotAvailable = 4,
	Supressed = 8,
	NotLearned = 12,
	Frozen = 16,
	Processing = 24,
	Stasis = 28,
	Cooldown = 32,
	InZhonyas = 48,
	NoMana = 64,
	Unknown
};

enum class TypeInfoClass : uint32_t
{
	NeutralMinionCamp = 0xFE7449A3,
	AIHeroClient = 0xE260302C,
	AIMarker = 0x11F7583D,
	AIMinionClient = 0xCAA58CB2,
	ObjectAttacher = 0x9E317160,
	LevelPropAIClient = 0x12E24BCD,
	AITurretClient = 0xBEBA9102,
	AITurretCommon = 0x70678BD0,
	obj_GeneralParticleEmitter = 0xDD4DE76F,
	GameObject = 0x1FAC8B64,
	MissileClient = 0x9C8ADE94,
	DrawFX = 0x42D144F5,
	UnrevealedTarget = 0xB98F49AF,
	BarracksDampener = 0x60BB49C0,
	Barracks = 0xD1ED70FE,
	AnimatedBuilding = 0x8F83FB9C,
	BuildingClient = 0x3CCABB2E,
	obj_Levelsizer = 0x6F2E6CAC,
	obj_NavPoint = 0x96B0A5E6,
	obj_SpawnPoint = 0xE3E9B36C,
	GrassObject = 0xAA2B7AB2,
	HQ = 0x503AD0D2,
	obj_InfoPoint = 0xF4753AD3,
	LevelPropGameObject = 0x5A730CB9,
	LevelPropSpawnerPoint = 0x4D8B713A,
	Shop = 0xA847E0A9,
	obj_Turret = 0x3D775D09
};

class CObject {
public:


	MAKE_DATA(short, Index, oObjIndex);
	MAKE_DATA(int, Team, oObjTeam);
	MAKE_DATA(Vector3, Position, oObjPos);
	MAKE_DATA(int, Level, offsets_lol.oObjLevel);
	MAKE_DATA(float, Health, offsets_lol.oObjHealth);
	MAKE_DATA(float, BonusAttackDamage, offsets_lol.oObjFlatAttackDamageMod);
	MAKE_DATA(float, BaseMagicDamage, offsets_lol.oObjBaseAbilityPower);
	MAKE_DATA(float, BonusMagicDamage, offsets_lol.oObjFlatAbilityPowerMod);
	MAKE_DATA(float, MRes, offsets_lol.oObjMagicResist);
	MAKE_DATA(float, ArmorPen, offsets_lol.oObjPhysicalLethality);
	MAKE_DATA(float, MagicPen, offsets_lol.oObjFlatMagicPenetration);
	MAKE_DATA(float, ArmorPenPercent, offsets_lol.oObjPercentArmorPenetration);
	MAKE_DATA(float, MagicPenPercent, offsets_lol.oObjPercentMagicPenetration);
	MAKE_DATA(float, MaxHealth, offsets_lol.oObjMaxHealth);
	MAKE_DATA(bool, IsVisible, oObjVisibility);
	MAKE_DATA(bool, IsTargetable, offsets_lol.oObjTargetable);
	MAKE_DATA(bool, IsUntargetableToAllies, oIsUntargetableToAllies);
	MAKE_DATA(bool, IsUntargetableToEnemies, oIsUntargetableToEnemies);
	MAKE_DATA(float, PhysicalShield, offsets_lol.oObjPhysicalShield);
	MAKE_DATA(float, MagicalShield, offsets_lol.oObjMagicalShield);
	MAKE_DATA(float, Mana, offsets_lol.oObjMana);
	MAKE_DATA(float, MaxMana, offsets_lol.oObjMaxMana);
	MAKE_DATA(Vector3, Direction, offsets_lol.oObjDirection);
	//MAKE_DATA(Vector2, Direction2D, offsets_lol.oObjDirection);
	MAKE_DATA(DWORD, NetworkID, oObjNetworkID);
	MAKE_DATA(int, RecallState, oObjRecallState); //6 recall  //8 is teleport
	MAKE_DATA(int, RecallType, oObjRecallType); //6 recall  //8 is teleport
	MAKE_DATA(float, BonusMRes, offsets_lol.oObjBonusMagicResist);
	MAKE_DATA(float, Exp, offsets_lol.oObjExp);
	MAKE_DATA(bool, IsRecalling, oObjRecallState);
	MAKE_DATA(bool, CombatType, offsets_lol.oObjCombatType);
	MAKE_DATA(float, PercentCooldownMod, offsets_lol.oObjPercentCooldownMod);
	MAKE_DATA(float, PercentCooldownCapMod, offsets_lol.oObjPercentCooldownCapMod);
	MAKE_DATA(float, PassiveCooldownEndTime, offsets_lol.oObjPassiveCooldownEndTime);
	MAKE_DATA(float, PassiveCooldownTotalTime, offsets_lol.oObjPassiveCooldownTotalTime);
	MAKE_DATA(float, PercentDamageToBarracksMinionMod, offsets_lol.oObjPercentDamageToBarracksMinionMod);
	MAKE_DATA(float, FlatDamageReductionFromBarracksMinionMod, offsets_lol.oObjFlatDamageReductionFromBarracksMinionMod);
	MAKE_DATA(float, FlatAttackDamageMod, offsets_lol.oObjFlatAttackDamageMod);
	MAKE_DATA(float, PercentAttackDamageMod, offsets_lol.oObjPercentAttackDamageMod);
	MAKE_DATA(float, PercentBonusAttackDamageMod, offsets_lol.oObjPercentBonusAttackDamageMod);
	MAKE_DATA(float, FlatAbilityPowerMod, offsets_lol.oObjFlatAbilityPowerMod);
	MAKE_DATA(float, PercentAbilityPowerMod, offsets_lol.oObjPercentAbilityPowerMod);
	MAKE_DATA(float, FlatMagicReduction, offsets_lol.oObjFlatMagicReduction);
	MAKE_DATA(float, PercentMagicReduction, offsets_lol.oObjPercentMagicReduction);
	MAKE_DATA(float, AttackSpeedModTotal, offsets_lol.oObjAttackSpeedModTotal);
	MAKE_DATA(float, AttackSpeedMod, offsets_lol.oObjAttackSpeedMod);
	MAKE_DATA(float, BaseAttackDamage, offsets_lol.oObjBaseAttackDamage);
	MAKE_DATA(float, FlatBaseAttackDamageMod, offsets_lol.oObjFlatBaseAttackDamageMod);
	MAKE_DATA(float, PercentBaseAttackDamageMod, offsets_lol.oObjPercentBaseAttackDamageMod);
	MAKE_DATA(float, BaseAbilityPower, offsets_lol.oObjBaseAbilityPower);
	MAKE_DATA(float, CritDamageMultiplier, offsets_lol.oObjCritDamageMultiplier);
	MAKE_DATA(float, Dodge, offsets_lol.oObjDodge);
	MAKE_DATA(float, Crit, offsets_lol.oObjCrit);
	MAKE_DATA(float, Armor, offsets_lol.oObjArmor);
	MAKE_DATA(float, BonusArmor, offsets_lol.oObjBonusArmor);
	MAKE_DATA(float, MagicResist, offsets_lol.oObjMagicResist);
	MAKE_DATA(float, BonusMagicResist, offsets_lol.oObjBonusMagicResist);
	MAKE_DATA(float, HealthRegen, offsets_lol.oObjHealthRegen);
	MAKE_DATA(float, MoveSpeed, offsets_lol.oObjMoveSpeed);
	MAKE_DATA(float, AttackRange, offsets_lol.oObjAttackRange);
	MAKE_DATA(float, PhysicalLethality, offsets_lol.oObjPhysicalLethality);
	MAKE_DATA(float, PercentArmorPenetration, offsets_lol.oObjPercentArmorPenetration);
	MAKE_DATA(float, PercentBonusArmorPenetration, offsets_lol.oObjPercentBonusArmorPenetration);
	MAKE_DATA(float, FlatMagicPenetration, offsets_lol.oObjFlatMagicPenetration);
	MAKE_DATA(float, PercentMagicPenetration, offsets_lol.oObjPercentMagicPenetration);
	MAKE_DATA(float, PercentBonusMagicPenetration, offsets_lol.oObjPercentBonusMagicPenetration);
	MAKE_DATA(float, LifeSteal, offsets_lol.oObjLifeSteal);
	MAKE_DATA(float, SpellVamp, offsets_lol.oObjSpellVamp);
	MAKE_DATA(float, Tenacity, offsets_lol.oObjTenacity);
	MAKE_DATA(float, ResourceRegen, offsets_lol.oObjResourceRegen);
	MAKE_DATA(float, ObjectScale, 0x1740);
	MAKE_DATA(kGameObjectStatusFlags, StatusFlags, oStatusFlag);
	MAKE_PTR(CSpellBook*, GetSpellBook, offsets_lol.oObjSpellBook);
	MAKE_PTR(CInventory*, GetInventory, offsets_lol.oObjInventory);
	MAKE_PTR(CBuffManager*, GetBuffManager, offsets_lol.oObjBuffMgr);



	bool HasBuff(unsigned int buffhash)
	{
		return this->GetBuffManager()->HasBuff(buffhash);
	}
	bool HasBuff(fnv::hash buffname)
	{
		return this->GetBuffManager()->HasBuff(buffname);
	}
	bool HasBuff(std::vector<fnv::hash> offsets)
	{
		return this->GetBuffManager()->HasBuff(offsets);
	}
	bool HasBuffOfType(std::vector<BuffType> bufftype)
	{
		return this->GetBuffManager()->HasBuffType(bufftype);
	}
	bool HasBuff(const char* buffname)
	{
		return this->GetBuffManager()->HasBuff(buffname);
	}

	int BuffCount(const char* buffname)
	{
		return this->GetBuffManager()->BuffCount(buffname);
	}
	int BuffCount(fnv::hash buffname)
	{
		return this->GetBuffManager()->BuffCount(buffname);
	}
	int BuffCount(unsigned int buffhash)
	{
		return this->GetBuffManager()->BuffCount(buffhash);
	}
	bool HasBuffOfType(BuffType bufftype)
	{
		return this->GetBuffManager()->HasBuffType(bufftype);
	}

	bool HasLethalTempoStacked()
	{
		return BuffCount(FNV("ASSETS/Perks/Styles/Precision/LethalTempo/LethalTempo.lua")) == 6;
	}

	bool IsZombie()
	{
		for (auto buff : this->GetBuffManager()->Buffs())
		{
			if (buff.namehash == FNV("kogmawicathiansurprise"))
				return true;
		}
		return false;
	}

	uint16_t ActionState()
	{
		return RPM<uint16_t>(this + offsets_lol.oActionState);
	}

	bool CanAttack()
	{
		return this->ActionState() & CharacterState::CanAttack;
	}

	bool CanCast()
	{
		return this->ActionState() & CharacterState::CanCast;
	}

	bool CanMove()
	{
		return this->ActionState() & CharacterState::CanMove;
	}

	bool IsImmovable()
	{
		return this->ActionState() & CharacterState::Immovable;
	}

	bool IsStealthed()
	{
		return this->ActionState() & CharacterState::IsStealth;
	}

	bool IsTaunted()
	{
		return this->ActionState() & CharacterState::Taunted;
	}

	bool IsFeared()
	{
		return this->ActionState() & CharacterState::Feared;
	}

	bool IsFleeing()
	{
		return this->ActionState() & CharacterState::Fleeing;
	}

	bool IsSupressed()
	{
		return this->ActionState() & CharacterState::Supressed;
	}

	bool IsAsleep()
	{
		return this->ActionState() & CharacterState::Asleep;
	}

	bool IsGhosted()
	{
		return this->ActionState() & CharacterState::Ghosted;
	}

	bool IsCharmed()
	{
		return this->ActionState() & CharacterState::Charmed;
	}

	/*bool IsSlowed()
	{
		return this->ActionState() & CharacterState::Slowed;
	}*/

	bool IsDisarmed()
	{
		return !(this->ActionState() & (CharacterState::CanAttack | CharacterState::Charmed | CharacterState::Fleeing | CharacterState::Taunted | CharacterState::Asleep | CharacterState::Supressed)) && !(this->StatusFlags() & GameObjectStatusFlags_Invulnerable);
	}

	bool IsRooted()
	{
		return !(this->ActionState() & (CharacterState::CanMove | CharacterState::Charmed | CharacterState::Fleeing | CharacterState::Taunted | CharacterState::Asleep | CharacterState::Supressed)) && !(this->StatusFlags() & GameObjectStatusFlags_Invulnerable);
	}

	bool IsSilenced()
	{
		return !(this->ActionState() & (CharacterState::CanCast | CharacterState::Charmed | CharacterState::Fleeing | CharacterState::Taunted | CharacterState::Asleep | CharacterState::Supressed)) && !(this->StatusFlags() & GameObjectStatusFlags_Invulnerable);
	}

	bool IsStunned()
	{
		return !(this->ActionState() & (CharacterState::CanAttack | CharacterState::CanMove | CharacterState::CanCast | CharacterState::Charmed | CharacterState::Fleeing | CharacterState::Taunted | CharacterState::Asleep | CharacterState::Supressed)) && !(this->StatusFlags() & GameObjectStatusFlags_Invulnerable);
	}

	SpellState GetSpellState(int Slot)
	{
		ULONG ActionState = this->ActionState();
		if (ActionState & CharacterState::CanCast)
		{
			CSpellSlot* SpellSlotPtr = this->GetSpellBook()->GetSpellSlotByID(Slot);
			if (!SpellSlotPtr)
				return SpellState::Unknown;

			INT Level = SpellSlotPtr->Level();  //this + 0x20
			if (Level < 1)
				return SpellState::NotLearned;

			FLOAT ManaRequirement = SpellSlotPtr->GetSpellData()->ManaCost(Level);
			if (ManaRequirement > 1.f && this->Mana() < ManaRequirement)
				return SpellState::NoMana;

			if (RPM<float>(m_Base + offsets_lol.oGameTime) < SpellSlotPtr->CastEndTime()) //this + 0x28
				return SpellState::Cooldown;

			/*if (SpellSlotPtr->Ammo() > 0)
			{
				if (RPM<float>(m_Base + offsets_lol.oGameTime) < SpellSlotPtr->CastTime())
					return SpellState::Cooldown;
			}*/

			return SpellState::Ready;
		}
		else
		{
			ULONG FinalMask = 0;

			if (ActionState & CharacterState::Taunted
				|| ActionState & CharacterState::Feared
				|| ActionState & CharacterState::Fleeing
				|| ActionState & CharacterState::Asleep
				|| ActionState & CharacterState::Charmed)
				ActionState |= (ULONG)SpellState::NotAvailable;
			if (ActionState & CharacterState::Supressed)
				ActionState |= (ULONG)SpellState::Supressed;

			if (FinalMask == 0)
				FinalMask = (ULONG)SpellState::Unknown;

			return (SpellState)FinalMask;
		}

		return SpellState::Ready;
	}

	bool IsCasting()
	{
		if (IsChargeing())
			return true;

		if (this->GetSpellBook()->GetActiveSpellEntry() && this->GetSpellBook()->GetActiveSpellEntry()->IsCastingSpell())
		{
			/*auto startwindup = this->GetSpellBook()->GetActiveSpellEntry()->StartTick();
			auto endwindup = this->GetSpellBook()->GetActiveSpellEntry()->MidTick();
			auto gametime = RPM<float>(m_Base + offsets_lol.oGameTime);

			if (gametime < endwindup)*/
			{
				return true;
			}
		}

		return this->GetSpellBook()->GetActiveSpellEntry() ? true : false;
	}

	bool IsChargeing()
	{
		switch (global::LocalChampNameHash)
		{
		case FNV("Varus"):
		{
			return HasBuff(FNV("VarusQ"));
		}
		case FNV("Xerath"):
		{
			return HasBuff(FNV("XerathArcanopulseChargeUp"));
		}
		case FNV("Pyke"):
		{
			return HasBuff(FNV("PykeQ"));
		}
		case FNV("Pantheon"):
		{
			return HasBuff(FNV("PantheonQ"));
		}
		case FNV("Sion"):
		{
			return HasBuff(FNV("SionQ"));
		}
		case FNV("Viego"):
		{
			return HasBuff(FNV("ViegoW"));
		}
		default:
			return false;
		}
	}

	bool IsWindingUp()
	{
		auto activespell = this->GetSpellBook()->GetActiveSpellEntry();
		if (this->GetSpellBook()->GetActiveSpellEntry())
		{
			auto endwindup = activespell->MidTick();
			auto gametime = RPM<float>(m_Base + offsets_lol.oGameTime);

			if (endwindup >= gametime)
			{
				return true;
			}
		}

		return false;
	}
	bool IsAutoAttacking()
	{
		auto activespell = this->GetSpellBook()->GetActiveSpellEntry();
		if (activespell && activespell->IsAutoAttack())
		{
			if (RPM<float>(m_Base + offsets_lol.oGameTime) < (activespell->MidTick() + activespell->CastDelay()))
			{
				return true;
			}
		}
		return false;
	}

	bool HasItemStack(kItemID id) {
		for (int i = 0; i <= 5; i++)
		{
			if (this->GetInventory() != nullptr)
			{
				auto itemID = this->GetInventory()->ItemID(i);
				auto itemStack = this->GetInventory()->Stack(i);
				if (itemID == id && itemStack > 0)
				{
					return true;
				}
			}
		}
		return false;

	}

	bool HasItem(kItemID id) {
		for (int i = 0; i <= 5; i++)
		{
			if (this->GetInventory() != nullptr)
			{
				auto itemID = this->GetInventory()->ItemID(i);

				if (itemID == id)
				{
					return true;
				}
			}
		}
		return false;

	}

	CSkinData* GetSkinData()
	{
		return (CSkinData*)(RPM<DWORD>(this + offsets_lol.oObjSkinData));
	}

	Vector2 Pos2D()
	{
		return Vector2(Position().x, Position().z);
	}

	Vector2 PosServer2D()
	{
		return Vector2(ServerPosition().x, ServerPosition().z);
	}

	std::vector<Vector3> GetPath3D()
	{

		std::vector<Vector3> result;

		auto AIMANAGER = this->GetAIManager();
		auto navBegin = AIMANAGER->GetNavBegin();

		for (int i = 0; i < AIMANAGER->getWayPointListSize(); i++)
			result.push_back(RPM<Vector3>(navBegin + i * 0xC));

		return result;
	}

	std::vector<Vector2> GetPath()
	{
		std::vector<Vector2> result;

		auto AIMANAGER = this->GetAIManager();
		auto navBegin = AIMANAGER->GetNavBegin();

		for (int i = 0; i < AIMANAGER->getWayPointListSize(); i++)
		{
			auto Nav = RPM<Vector3>(navBegin + i * 0xC);
			result.push_back(Vector2(Nav.x, Nav.z));
		}

		return result;
	}

	/*std::vector<Vector3> GetWaypoints3D()
	{
		std::vector<Vector3> result;

		auto AIMANAGER = this->GetAIManager();
		auto navBegin = AIMANAGER->GetNavBegin();

		for (int i = AIMANAGER->PassedWaypoints() - 1; i < AIMANAGER->getNumWayPoints(); i++)
			result.push_back(RPM<Vector3>(navBegin + i * 0xC));

		return result;
	}


	std::vector<Vector2> GetWaypoints()
	{
		std::vector<Vector2> result;

		auto AIMANAGER = this->GetAIManager();
		auto navBegin = AIMANAGER->GetNavBegin();

		for (int i = AIMANAGER->PassedWaypoints() - 1; i < AIMANAGER->getNumWayPoints(); i++)
		{
			auto Nav = RPM<Vector3>(navBegin + i * 0xC);
			result.push_back(Vector2(Nav.x, Nav.z));
		}

		return result;
	}*/

	int GetPathIndex(std::vector<Vector2> path, Vector2 point)
	{
		// find the shortest distance between main point
		// and the closest point on each path segment
		int index = 0;
		float distance = std::numeric_limits<float>::infinity();
		for (int i = 0; i < path.size() - 1; i++)
		{
			Vector2 a = path[i], b = path[i + 1];
			Vector2 ap = point - a, ab = b - a;
			float t = ap.Dot(ab) / ab.LengthSquared();
			Vector2 pt = t < 0.0 ? a : (t > 1.0 ? b : (a + ab * t));
			float dist = point.DistanceSquared(pt);
			if (dist < distance) { distance = dist; index = i + 1; }
		}
		return index;
	}

	std::vector<Vector2> GetWaypoints()
	{
		std::vector<Vector2> result;
		// obviously the first waypoint is his position
		result.push_back(this->PosServer2D());
		auto Paths = this->GetPath();
		int size = Paths.size();
		if (size <= 1) // unit is standing
			return result;
		else if (size == 2) // unit has one moving path
		{
			result.push_back(Paths[1]);
			return result;
		}
		// unit has multi-segment moving path find the index of
		// segment where he's currently on and continue getting waypoints...
		for (int i = GetPathIndex(Paths, result[0]); i < size; i++)
			result.push_back(Paths[i]);

		return result;
	}

	int GetPathIndex(std::vector<Vector3> path, Vector3 point)
	{
		// find the shortest distance between main point
		// and the closest point on each path segment
		int index = 0;
		float distance = std::numeric_limits<float>::infinity();
		for (int i = 0; i < path.size() - 1; i++)
		{
			Vector3 a = path[i], b = path[i + 1];
			Vector3 ap = point - a, ab = b - a;
			float t = ap.Dot(ab) / ab.LengthSquared();
			Vector3 pt = t < 0.0 ? a : (t > 1.0 ? b : (a + ab * t));
			float dist = point.DistanceSquared(pt);
			if (dist < distance) { distance = dist; index = i + 1; }
		}
		return index;
	}

	std::vector<Vector3> GetWaypoints3D()
	{
		std::vector<Vector3> result;
		// obviously the first waypoint is his position
		result.push_back(this->ServerPosition());
		auto Paths = this->GetPath3D();
		int size = Paths.size();
		if (size <= 1) // unit is standing
			return result;
		else if (size == 2) // unit has one moving path
		{
			result.push_back(Paths[1]);
			return result;
		}
		// unit has multi-segment moving path find the index of
		// segment where he's currently on and continue getting waypoints...
		for (int i = GetPathIndex(Paths, result[0]); i < size; i++)
			result.push_back(Paths[i]);

		return result;
	}

	float AttackSpeedRaw()
	{
		float baseattackspeed = RPM<float>(this->CharData() + offsets_lol.oObjBaseAttackSpeed);
		float baseattackspeedratiro = RPM<float>(this->CharData() + offsets_lol.oObjBaseAttackSpeedRatio);
		float attackspeed = baseattackspeed + (baseattackspeedratiro * this->AttackSpeedMod());
		return attackspeed;
	}

	float AttackSpeed()
	{

		if (this->HasBuff({
			FNV("ASSETS/Perks/Styles/Precision/LethalTempo/LethalTempo.lua"),
			FNV("ASSETS/Perks/Styles/Domination/HailOfBlades/HailOfBladesBuff.lua"),
			FNV("jinxpassivekill") }))
			return this->AttackSpeedRaw();

		return std::min(this->AttackSpeedRaw(), 2.5f);
	}

	float AttackDelay()
	{
		float minAttackSpeed = 0.400000006f;	
		float maxAttackSpeed = 5.f;

		LeagueObfuscationFloat attackDelayOffset1enc;

		ReadVirtualMemory((void*)((DWORD)this + 0x2E34), &attackDelayOffset1enc, sizeof(LeagueObfuscationFloat));

		float attackDelayOffset1 = decrypt_float(attackDelayOffset1enc);
		if (attackDelayOffset1 > 0.0000099999997)
			minAttackSpeed = 1.0f / attackDelayOffset1;


		LeagueObfuscationFloat attackDelayOffset2enc;
		ReadVirtualMemory((void*)((DWORD)this + 0x2E50), &attackDelayOffset2enc, sizeof(LeagueObfuscationFloat));



		float attackDelayOffset2 = decrypt_float(attackDelayOffset2enc);
		if (attackDelayOffset2 > 0.0000099999997)
			maxAttackSpeed = 1.0f / attackDelayOffset2;



		const float& attackSpeedMod = this->AttackSpeedModTotal();
		const float& attackSpeedMultiplier = RPM<float>((DWORD)this + offsets_lol.oGetAttackDelayOffset);
		const float& baseAttackSpeed = RPM<float>(this->CharData() + offsets_lol.oObjBaseAttackSpeed);

		//std::cout << "attackDelayOffset1 " << attackDelayOffset1 << std::endl;
		//std::cout << "attackDelayOffset2 " << attackDelayOffset2 << std::endl;
		//std::cout << "attackSpeedMod " << attackSpeedMod << std::endl;
		//std::cout << "attackSpeedMultiplier " << attackSpeedMultiplier << std::endl;
		//std::cout << "baseAttackSpeed " << baseAttackSpeed << std::endl;

		float temp = 1 / (((((attackSpeedMod / attackSpeedMultiplier) - 1.0f)
			* baseAttackSpeed) + baseAttackSpeed) * attackSpeedMultiplier);
		float retValue = 0;
		if (temp <= maxAttackSpeed)
			retValue = fmaxf(temp, minAttackSpeed);
		else
			retValue = maxAttackSpeed;

		return retValue;
	}


	float basicAttackWindup()
	{
		DWORD unitInfoComponent;
		ReadVirtualMemory((void*)((DWORD)this + offsets_lol.oPreCharData - 0x64), &unitInfoComponent, sizeof(DWORD));
		ReadVirtualMemory((void*)(unitInfoComponent + 0x1C), &unitInfoComponent, sizeof(DWORD));

		float attackDelayCastOffsetPercent;
		uint32_t attackDelayCastOffsetPercent2;
		float attackCastTime;
		uint32_t attackCastTime2;
		float attackTotalTime;
		uint32_t attackTotalTime2;

		ReadVirtualMemory((void*)(unitInfoComponent + 0x278), &attackTotalTime, sizeof(float));
		ReadVirtualMemory((void*)(unitInfoComponent + 0x27C), &attackCastTime, sizeof(float));
		ReadVirtualMemory((void*)(unitInfoComponent + 0x280), &attackDelayCastOffsetPercent, sizeof(float));
		ReadVirtualMemory((void*)(unitInfoComponent + 0x278), &attackTotalTime2, sizeof(uint32_t));
		ReadVirtualMemory((void*)(unitInfoComponent + 0x27C), &attackCastTime2, sizeof(uint32_t));
		ReadVirtualMemory((void*)(unitInfoComponent + 0x280), &attackDelayCastOffsetPercent2, sizeof(uint32_t));

		if (attackDelayCastOffsetPercent2 != 0x7F7FFFFF)
			return attackDelayCastOffsetPercent + 0.3;
		else if (attackCastTime2 != 0x7F7FFFFF && attackTotalTime2 != 0x7F7FFFFF)
			return attackCastTime / attackTotalTime;
		return 0.3;
	}

	float windupModifier()
	{
		DWORD unitInfoComponent;
		ReadVirtualMemory((void*)((DWORD)this + offsets_lol.oPreCharData - 0x64), &unitInfoComponent, sizeof(DWORD));

		ReadVirtualMemory((void*)(unitInfoComponent + 0x1C), &unitInfoComponent, sizeof(DWORD));

		float attackDelayCastOffsetPercentAttackSpeedRatio;
		uint32_t attackDelayCastOffsetPercentAttackSpeedRatio2;
		ReadVirtualMemory((void*)(unitInfoComponent + 0x284), &attackDelayCastOffsetPercentAttackSpeedRatio, sizeof(float));
		ReadVirtualMemory((void*)(unitInfoComponent + 0x284), &attackDelayCastOffsetPercentAttackSpeedRatio2, sizeof(uint32_t));
		return attackDelayCastOffsetPercentAttackSpeedRatio2 != 0x7F7FFFFF ? attackDelayCastOffsetPercentAttackSpeedRatio : 1;
	}

	float windupTime()
	{
		float attackTime = AttackDelay();

		float winupPercent = basicAttackWindup();

		float windupTime = (1 / global::LocalData->baseAttackSpeed) * winupPercent;

		float modifier = windupModifier();

		float ret = windupTime + ((attackTime * winupPercent) - windupTime) * modifier;


		return ret;
	}

	float AttackCastDelay()
	{
		return windupTime();
	}


	bool IsMoving()
	{
		return this->Position().x - floor(this->Position().x) != 0 && GetAIManager()->IsMoving();
	}

	bool IsDashing()
	{
		return GetAIManager()->IsDashing() && GetAIManager()->IsMoving() && !this->HasBuffOfType(BuffType::Knockup) && this->GetPath().size() != 0;
	}

	/*float GetAttackDelay()
	{
		float minAttackSpeed = 0.400000006f;
		float maxAttackSpeed = 5.f;

		if (m_data.attackDelayOffset1 > 0.0000099999997)
			minAttackSpeed = 1.0f / m_data.attackDelayOffset1;

		if (m_data.attackDelayOffset2 > 0.0000099999997)
			maxAttackSpeed = 1.0f / m_data.attackDelayOffset2;

		const float& attackSpeedMod = m_data.objectStats.attackSpeedMod;
		const float& attackSpeedMultiplier = m_data.attackDelayMultiplier;
		const float& baseAttackSpeed = m_globalUnitData->baseAttackSpeed.value();

		float temp = 1 / (((((attackSpeedMod / attackSpeedMultiplier) - 1.0f)
			* baseAttackSpeed) + baseAttackSpeed) * attackSpeedMultiplier);
		float retValue = 0;
		if (temp <= maxAttackSpeed)
			retValue = fmaxf(temp, minAttackSpeed);
		else
			retValue = maxAttackSpeed;
		return retValue;
	}*/


	CAIManager* GetAIManager() //    
	{
		LeagueObfuscationDword aiManagerObf;
		ReadVirtualMemory((void*)((DWORD)this + offsets_lol.oGetAIManager_2 - 0x1), &aiManagerObf, sizeof(LeagueObfuscationDword));

		DWORD address = decrypt_dword(aiManagerObf);
		DWORD aiManagerAddress;
		ReadVirtualMemory((void*)((DWORD)address + 0x08), &aiManagerAddress, sizeof(DWORD));
		return (CAIManager*)aiManagerAddress;
	}

	Vector3 ServerPosition()
	{
		if (this->IsHero())
		{
			auto AI_Manager = this->GetAIManager();
			auto pos = AI_Manager->CurrentPosition();
			return pos.IsValid() ? pos : this->Position();
		}

		return this->Position();
	}

	std::string ChampionName(int type = 0) // 1 = lowercase , 2 nospace
	{
		char nameobj[50];
		std::string s;

		if (ReadVirtualMemory((void*)RPM<DWORD>(this + offsets_lol.oObjChampionName), &nameobj, 50))
		{
			s = nameobj;
			if (type == 1)
			{
				s = ToLower(s);
			}
			else if (type == 2)
			{
				s.erase(std::remove(s.begin(), s.end(), ' '), s.end());
			}
		}


		return s;
	}

	fnv::hash ChampionNameHash() // 1 = lowercase , 2 nospace
	{
		char nameobj[50];
		fnv::hash s = 0x0;

		if (ReadVirtualMemory((void*)RPM<DWORD>(this + offsets_lol.oObjChampionName), &nameobj, 50))
		{
			s = fnv::hash_runtime(nameobj);
		}
		return s;
	}

	std::string Name(int type = 0) // 1 = lowercase , 2 nospace
	{
		char nameobj[0x20];
		std::string s;
		if (ReadVirtualMemory((void*)(this + oObjName), &nameobj, sizeof(nameobj)))
		{
			if (strstr(nameobj, "Object") != NULL)
			{
				ZeroMemory(nameobj, 0x20);
				uint32_t pointer = RPM<uint32_t>(this + oObjName);
				if (ReadVirtualMemory((void*)(pointer), &nameobj, sizeof(nameobj)))
				{
					s = std::string(nameobj);
				}
			}
			else
			{
				if (ReadVirtualMemory((void*)(this + oObjName), &nameobj, sizeof(nameobj)))
				{
					s = std::string(nameobj);
				}
			}

			if (type == 1)
			{
				std::transform(s.begin(),
					s.end(),
					s.begin(),
					[](unsigned char const& c) {
						return ::tolower(c);
					});
			}
			else if (type == 2)
			{
				s.erase(std::remove(s.begin(), s.end(), ' '), s.end());
			}
		}
		return s;
	}

	fnv::hash NameHash() // 1 = lowercase , 2 nospace
	{
		char nameobj[0x20];
		fnv::hash s = 0x0;
		if (ReadVirtualMemory((void*)(this + oObjName), &nameobj, sizeof(nameobj)))
		{
			if (strstr(nameobj, "Object") != NULL)
			{
				ZeroMemory(nameobj, 0x20);
				uint32_t pointer = RPM<uint32_t>(this + oObjName);
				if (ReadVirtualMemory((void*)(pointer), &nameobj, sizeof(nameobj)))
				{
					s = fnv::hash_runtime(nameobj);
				}
			}
			else
			{
				if (ReadVirtualMemory((void*)(this + oObjName), &nameobj, sizeof(nameobj)))
				{
					s = fnv::hash_runtime(nameobj);
				}
			}
		}
		return s;
	}

	DWORD GetType() {
		return ReadChain((DWORD)this, { 0x0,0x4,0x1,0x4 });
	}

	DWORD GetType2() {
		LeagueObfuscationDword typeobf;
		ReadVirtualMemory((void*)((DWORD)this + 0x38), &typeobf, sizeof(LeagueObfuscationDword));


		DWORD typed = decrypt_dword(typeobf);
		return typed;
	}
	bool IsTroy()
	{
		//LeagueObfuscationDword typeobf;
		//ReadVirtualMemory((void*)((DWORD)this + 0x04), &typeobf, sizeof(LeagueObfuscationDword));


		//DWORD typed = decrypt_dword(typeobf);

		//return typed == m_Base + 0x3105520; //string: obj_GeneralParticleEmitter

		return ReadChain((DWORD)this, { 0x0,0x4,0x1,0x4 }) == kHash32l("obj_GeneralParticleEmitter");

	}

	bool IsLaneMinion()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_ChaosMinionMelee:
		case SkinHash::SRU_OrderMinionMelee:
		case SkinHash::SRU_ChaosMinionRanged:
		case SkinHash::SRU_OrderMinionRanged:
		case SkinHash::SRU_ChaosMinionSiege:
		case SkinHash::SRU_OrderMinionSiege:
		case SkinHash::SRU_ChaosMinionSuper:
		case SkinHash::SRU_OrderMinionSuper:
		case SkinHash::HA_ChaosMinionMelee:
		case SkinHash::HA_OrderMinionMelee:
		case SkinHash::HA_ChaosMinionRanged:
		case SkinHash::HA_OrderMinionRanged:
		case SkinHash::HA_ChaosMinionSiege:
		case SkinHash::HA_OrderMinionSiege:
		case SkinHash::HA_ChaosMinionSuper:
		case SkinHash::HA_OrderMinionSuper:
			return true;
		default:
			return false;
		}
	}

	bool IsMeleeMinion()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_ChaosMinionMelee:
		case SkinHash::SRU_OrderMinionMelee:
		case SkinHash::SRU_ChaosMinionSuper:
		case SkinHash::SRU_OrderMinionSuper:
		case SkinHash::HA_ChaosMinionMelee:
		case SkinHash::HA_OrderMinionMelee:
		case SkinHash::HA_ChaosMinionSuper:
		case SkinHash::HA_OrderMinionSuper:
			return true;
		default:
			return false;
		}
	}

	bool IsCasterMinion()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_ChaosMinionRanged:
		case SkinHash::SRU_OrderMinionRanged:
		case SkinHash::HA_ChaosMinionRanged:
		case SkinHash::HA_OrderMinionRanged:
			return true;
		default:
			return false;
		}
	}

	bool IsSuperMinion()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_ChaosMinionSuper:
		case SkinHash::SRU_OrderMinionSuper:
		case SkinHash::HA_ChaosMinionSuper:
		case SkinHash::HA_OrderMinionSuper:
			return true;
		default:
			return false;
		}
	}

	bool IsSiegeMinion() {
		switch (this->GetSkinData()->GetSkinHash()) {
		case SkinHash::SRU_ChaosMinionSiege:
		case SkinHash::SRU_OrderMinionSiege:
		case SkinHash::HA_ChaosMinionSiege:
		case SkinHash::HA_OrderMinionSiege:
			return true;
		default:
			return false;
		}
	}

	bool IsPet()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::AnnieTibbers:
		case SkinHash::EliseSpiderling:
		case SkinHash::GangplankBarrel:
		case SkinHash::HeimerTBlue:
		case SkinHash::HeimerTYellow:
		case SkinHash::IvernMinion:
		case SkinHash::MalzaharVoidling:
		case SkinHash::ShacoBox:
		case SkinHash::VoidSpawn:
		case SkinHash::VoidSpawnTracer:
		case SkinHash::YorickGhoulMelee:
		case SkinHash::YorickBigGhoul:
		case SkinHash::ZyraThornPlant:
		case SkinHash::ZyraGraspingPlant:
			return true;
		default:
			return false;
		}
	}
	/*bool IsWard(SkinHash ward)
	{
		return this->GetSkinData()->GetSkinHash() == ward;
	}*/

	bool IsWard()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::JammerDevice:
		case SkinHash::SightWard:
		case SkinHash::BlueTrinket:
		case SkinHash::YellowTrinket:
			return true;
		default:
			return false;
		}
	}

	bool IsPlant()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_Plant_Health:
		case SkinHash::SRU_Plant_Satchel:
		case SkinHash::SRU_Plant_Vision:
			return true;
		default:
			return false;
		}
	}

	bool IsNormalMonster()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_Razorbeak:
		case SkinHash::SRU_Murkwolf:
		case SkinHash::SRU_Gromp:
		case SkinHash::SRU_Krug:
			return true;
		default:
			return false;
		}
	}

	bool IsLargeMonster()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_Red:
		case SkinHash::SRU_Blue:
		case SkinHash::Sru_Crab:
			return true;
		default:
			return false;
		}
	}

	bool IsEpicMonster()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_Dragon_Air:
		case SkinHash::SRU_Dragon_Earth:
		case SkinHash::SRU_Dragon_Fire:
		case SkinHash::SRU_Dragon_Water:
		case SkinHash::SRU_Dragon_Elder:
		case SkinHash::SRU_Dragon_Hextech:
		case SkinHash::SRU_Dragon_Chem:
		case SkinHash::SRU_Baron:
		case SkinHash::SRU_RiftHerald:
			return true;
		default:
			return false;
		}
	}

	bool IsMonster()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_Razorbeak:
		case SkinHash::SRU_Murkwolf:
		case SkinHash::SRU_Gromp:
		case SkinHash::SRU_Krug:
		case SkinHash::SRU_Red:
		case SkinHash::SRU_Blue:
		case SkinHash::Sru_Crab:
		case SkinHash::SRU_Dragon_Air:
		case SkinHash::SRU_Dragon_Earth:
		case SkinHash::SRU_Dragon_Fire:
		case SkinHash::SRU_Dragon_Water:
		case SkinHash::SRU_Dragon_Elder:
		case SkinHash::SRU_Dragon_Hextech:
		case SkinHash::SRU_Dragon_Chem:
		case SkinHash::SRU_Baron:
		case SkinHash::SRU_RiftHerald:
			return true;
		default:
			return false;
		}
	}
	bool IsJungleMonster()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::SRU_Razorbeak:
		case SkinHash::SRU_RazorbeakSmall:
		case SkinHash::SRU_Murkwolf:
		case SkinHash::SRU_Gromp:
		case SkinHash::SRU_Krug:
		case SkinHash::SRU_KrugMedium:
		case SkinHash::SRU_KrugSmall:
		case SkinHash::SRU_Red:
		case SkinHash::SRU_Blue:
		case SkinHash::Sru_Crab:
		case SkinHash::SRU_Dragon_Air:
		case SkinHash::SRU_Dragon_Earth:
		case SkinHash::SRU_Dragon_Fire:
		case SkinHash::SRU_Dragon_Water:
		case SkinHash::SRU_Dragon_Elder:
		case SkinHash::SRU_Dragon_Hextech:
		case SkinHash::SRU_Dragon_Chem:
		case SkinHash::SRU_Baron:
		case SkinHash::SRU_RiftHerald:
			return true;
		default:
			return false;
		}
	}

	bool decryptType(DWORD base, ObjectType type)
	{
		LeagueObfuscationDword typeobf;
		ReadVirtualMemory((void*)((DWORD)this + 0x38), &typeobf, sizeof(LeagueObfuscationDword));


		DWORD typed = decrypt_dword(typeobf);

		return ((type & typed) != 0);
	}

	bool IsHero()
	{
		return this && decryptType((DWORD)this, ObjectType::GameObjectFlags_Hero);
	}
	bool IsMinion()
	{
		return this && decryptType((DWORD)this, ObjectType::GameObjectFlags_Minion);
	}
	bool IsObjectDead()
	{
		return this && decryptType((DWORD)this, ObjectType::GameObjectFlags_DeadObject);
	}
	bool IsTurret()
	{
		return this && decryptType((DWORD)this, ObjectType::GameObjectFlags_Turret);
	}

	bool IsMissile()
	{
		return this && decryptType((DWORD)this, ObjectType::GameObjectFlags_Missile);
	}

	bool IsAI()
	{
		return this && decryptType((DWORD)this, ObjectType::GameObjectFlags_AI);
	}

	CObject* GetLocalObject() {
		return (CObject*)RPM<uint32_t>(m_Base + offsets_lol.oLocalPlayer);
	}

	bool IsDead()
	{
		LeagueObfuscationBool isDeadObf;
		ReadVirtualMemory((void*)((DWORD)this + 0x218), &isDeadObf, sizeof(LeagueObfuscationBool));


		bool isDead = decrypt_bool(isDeadObf);
		return isDead;

	}

	bool IsAlive()
	{
		return !IsDead();
	}

	bool IsTrap()
	{
		switch (this->GetSkinData()->GetSkinHash())
		{
		case SkinHash::Teemo_Trap:
		case SkinHash::Caitlyn_Trap:
		case SkinHash::Jhin_Trap:
		case SkinHash::Jinx_Trap:
		case SkinHash::Nidalee_Trap:
		case SkinHash::Shaco_Trap:
			return true;
		default:
			return false;
		}
	}

	uint32_t CharData()
	{
		return RPM<uint32_t>(RPM<uint32_t>(this + offsets_lol.oPreCharData) + offsets_lol.oCharData);
	}

	float BoundingRadius()
	{
		float BoundingRadius = RPM<float>(CharData() + offsets_lol.oObjBoundingRadius);

		if (BoundingRadius > 300.f)
			return 65.f;

		return 65.f;
	}

	bool IsInAutoAttackRange(CObject* target, float extra = 0) {
		/*if (this == ObjectManager::Player && this->BaseCharacterData->SkinHash == Character::Azir) {
			for (auto soldier : SDK::Orbwalker::AzirSoldiers) {
				if (!soldier->IsDead() && ObjectManager::Player->GetPathController()->ServerPosition.IsInRange(soldier->Position, 790.0f)) {
					auto pathController = soldier->GetPathController();
					if ((!pathController->HasNavigationPath || !pathController->GetNavigationPath()->IsDashing) && soldier->IsInAutoAttackRange(target)) {
						return true;
					}
				}
			}
		}*/
		auto local_pos = this->ServerPosition();
		auto target_pos = target->ServerPosition();

		/*if (!local_pos.IsValid2())
			local_pos = this->Position();
		if (!target_pos.IsValid2())
			target_pos = target->Position();

		if (!local_pos.IsValid2() || !target_pos.IsValid2())
			return false;*/

		return local_pos.IsInRange(target_pos, this->GetRealAutoAttackRange(target) + extra);
	}

	/*bool IsValidTarget(float range)
	{
		if (this == nullptr)
			return false;

		if (this->Health() > 0 && this->IsAlive() && this->IsTargetable() && this->Position().Distance(GetLocalObject()->Position()) < range && this->MaxHealth() > 8)
			return true;

		return false;
	}*/

	bool IsInvulnerable()
	{
		if (!this->IsAlive() || !this->IsVisible() || !this->IsTargetable())
		{
			return false;
		}

		if (this->StatusFlags() & GameObjectStatusFlags_Invulnerable)
			return true;

		if (this->IsHero())
		{
			auto champname = this->ChampionNameHash();
			//if (champname == FNV("Kindred") && champname == FNV("Tryndamere") && champname == FNV("Kayle") && champname == FNV("Fiora"))
			{
				auto buffs = this->GetBuffManager()->Buffs();
				for (auto buff : buffs)
				{
					/*if (buff.type == BuffType::Invulnerability)
						return true;*/

					switch (buff.namehash)
					{
					case FNV("KindredRNoDeathBuff"):
					case FNV("UndyingRage"):
					case FNV("ChronoRevive"):
					case FNV("ChronoShift"):
						if (this->HealthPercent() <= 10)
						{
							return true;
						}
						break;
					case FNV("KayleR"):
					case FNV("VladimirSanguinePool"):
					case FNV("lissandrarself"):
					case FNV("fioraw"):
					{
						return true;
					}
					}
				}
			}
		}

		return false;
	}

	bool IsValidTarget(float range = FLT_MAX, bool checkTeam = true, Vector3 rangeCheckFrom = Vector3::Zero)
	{
		//auto position = this->IsHero() ? this->ServerPosition() : this->Position();

		if (this == nullptr)
			return false;

		if (this->NetworkID() - (unsigned int)0x40000000 > 0x100000)
		{
			if (this->GetType() == kHash32l("BarracksDampener"))
			{

			}
			else
			{
				return false;
			}
		}

		/*if (this->NetworkID() - (unsigned int)0x40000000 > 0x100000)
		{
			return false;
		}*/

		auto position = this->Position();

		if (!position.IsValid())
			return false;

		if (!this->IsAlive() || !this->IsVisible() || !this->IsTargetable())
		{
			return false;
		}

		if (checkTeam && this->Team() == ((CObject*)global::localPlayer)->Team())
		{
			return false;
		}

		if (range != FLT_MAX)
		{
			return rangeCheckFrom.IsValid() ? rangeCheckFrom.DistanceSquared(position) < range * range : ((CObject*)global::localPlayer)->ServerPosition().DistanceSquared(position) < range * range;
		}

		if (this->IsHero())
		{
			/*if (IsInvulnerable())
				return false;*/
			if (this->StatusFlags() & GameObjectStatusFlags_Invulnerable)
				return false;
		}

		/*	if (this->ChampionNameHash() == FNV("Gwen"))
			{
				if (this->Distance(((CObject*)global::localPlayer)) > 373.0f && this->HasBuff(FNV("GwenW")))
					return false;
			}

			if (this->ChampionNameHash() == FNV("Samira"))
			{
				if (this->HasBuff(FNV("SamiraW")))
					return false;
			}

			if (this->ChampionNameHash() == FNV("Senna"))
			{
				if (this->Distance(((CObject*)global::localPlayer)) > 373.0f && this->HasBuff(FNV("SennaE")))
					return false;
			}

			if (this->ChampionNameHash() == FNV("Fiora"))
			{
				if (this->HasBuff(FNV("FioraW")))
					return false;
			}*/


		return true;
	}

	/*bool IsValidTarget(bool IsInvulnerableCheck)
	{
		if (this->IsHero() && IsValidTarget() && IsInvulnerableCheck)
		{
			if (IsInvulnerable())
				return false;

			return true;
		}
		else
		{
			return IsValidTarget();
		}
	}*/

	Vector2 To2D(Vector3 pos)
	{
		return Vector2(pos.x, pos.z);
	}

	bool IsFacing(Vector3 target, float angle = 90)
	{
		if (this == nullptr || !target.IsValid())
		{
			return false;
		}
		return To2D(this->Direction()).AngleBetween(To2D(target - this->Position())) < angle;
	}

	/*bool IsValidTarget()
	{
		if (this == nullptr)
			return false;

		if (this->IsAlive() && this->IsTargetable() && this->IsVisible() && this->Health() > 0 && this->MaxHealth() > 8)
			return true;

		return false;
	}*/

	bool IsAlly()
	{
		if (this == nullptr)
			return false;

		if (this->Team() == GetLocalObject()->Team())
		{
			return true;
		}

		return false;
	}

	bool IsEnemy()
	{
		if (this->Team() != GetLocalObject()->Team())
		{
			return true;
		}

		return false;
	}

	int GetSpellSlotByName(const char* spellname)
	{
		for (int i = 0; i < 6; i++)
		{
			if (strstr(this->GetSpellBook()->GetSpellSlotByID(i)->GetSpellData()->GetSpellName().c_str(), spellname))
			{

				return i;
			}

		}
		return -1;
	}

	float BasicAttackMissileSpeed()
	{

		switch (global::LocalChampNameHash)
		{
		case FNV("Aphelios"):
		{
			switch (fnv::hash_runtime(GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->GetSpellName().c_str()))
			{
			case FNV("ApheliosCalibrumQ"):
				return 3000.0f;
			case FNV("ApheliosGravitumQ"):
				return 1500.0f;
			case FNV("ApheliosInfernumQ"):
				return 1700.0f;
			case FNV("ApheliosCrescendumQ"):
				return 4500.0f;
			case FNV("ApheliosSeverumQ"): // 1.F 
				return 6000.0f;
			}
			break;
		}
		case FNV("Caitlyn"):
			if (HasBuff(FNV("caitlynheadshot")))
			{
				return 4000.0f;
			}
			break;
		case FNV("Jhin"):
			if (HasBuff(FNV("jhinpassiveattackbuff")))
			{
				return 3000.0f;
			}
			break;
		case FNV("Jinx"):
			if (HasBuff(FNV("JinxQ")))
			{
				return 2000.0f;
			}
			break;
		case FNV("Jayce"):
			if (GetSelfAttackRange() > 400.0f)
			{
				return 2000.0f;
			}
			return std::numeric_limits<float>::max();
		case FNV("Kayle"):
			if (GetSelfAttackRange() > 500.0f)
			{
				return 3000.0f;
			}
			return std::numeric_limits<float>::max();
		case FNV("Xayah"):
			if (HasBuff(FNV("XayahPassiveActive")))
			{
				return 4000.0f;
			}
			break;
		}

		/*auto BasicAttack = GetBasicAttack();
		if (!IsMelee2() && BasicAttack != nullptr && BasicAttack->SpellDataRes() != nullptr)
		{
			if (*BasicAttack->SpellDataRes()->GetMissileSpeed() > 1)
				return *BasicAttack->SpellDataRes()->GetMissileSpeed();
			else
				return 2002.0f;
		}

		if (!IsMelee() && BasicAttack == nullptr || BasicAttack->SpellDataRes() == nullptr)
			return 2001.0f;*/

		return std::numeric_limits<float>::max();
	}

	float TotalBaseAttackDamage()
	{
		return (this->BaseAttackDamage() + this->FlatBaseAttackDamageMod()) * (1.0f + this->PercentBaseAttackDamageMod());
	}

	float TotalBonusAttackDamage()
	{
		return this->FlatAttackDamageMod() * (1.0f + this->PercentBonusAttackDamageMod());
	}

	float TotalAttackDamage()
	{
		return (this->TotalBaseAttackDamage() + this->TotalBonusAttackDamage()) * (1.0f + this->PercentAttackDamageMod());
	}

	float TotalAbilityPower()
	{
		return this->BaseAbilityPower() + this->FlatAbilityPowerMod() * (1.0f + this->PercentAbilityPowerMod());
	}

	int HealthPercent()
	{
		float hpp = this->Health() / this->MaxHealth() * 100;
		int hper = (int)hpp;
		return hper;
	}


	int ManaPercent()
	{
		float hpp = this->Mana() / this->MaxMana() * 100;
		int hper = (int)hpp;
		return hper;
	}

	float Distance2D(Vector2 target, bool squared = false)
	{
		return squared
			? this->Pos2D().DistanceSquared(target)
			: this->Pos2D().Distance(target);
	}

	float Distance2D(CObject* target, bool squared = false)
	{
		return squared
			? this->Pos2D().DistanceSquared(target->Pos2D())
			: this->Pos2D().Distance(target->Pos2D());
	}

	float Distance(Vector3 target, bool squared = false)
	{
		return squared
			? this->Position().DistanceSquared(target)
			: this->Position().Distance(target);
	}
	float Distance(CObject* target, bool squared = false)
	{
		return squared
			? this->Position().DistanceSquared(target->Position())
			: this->Position().Distance(target->Position());
	}
	float MissingHealth()
	{
		return this->MaxHealth() - this->Health();
	}
	float GetEffectiveHPAD() {
		return Health() * (100.0f + Armor()) / 100.0f;
	}

	float GetEffectiveHPAP() {
		return Health() * (100.0f + MRes()) / 100.0f;
	}
	float GetEffectiveHPAD(float Armor, float HP) {
		return HP * (100.0f + Armor) / 100.0f;
	}

	float GetEffectiveHPAP(float MRes, float HP) {
		return HP * (100.0f + MRes) / 100.0f;
	}
	float GetTrueHp(CObject* target) {
		if (this->BonusMagicDamage() > this->BonusAttackDamage())
		{
			//you're AP dmg - check effective AP HP
			return GetEffectiveHPAP(target->MRes(), target->Health());
		}
		else
		{
			//you're AD dmg
			return GetEffectiveHPAD(target->Armor(), target->Health());
		}
	}

	float MissingHealthPercent()
	{
		return 100 - this->HealthPercent();
	}

	bool IsMelee()
	{
		return this->CombatType() == 1;  //1 is melee, 2 is ranged
	}

	bool IsRanged()
	{
		return !this->IsMelee();
	}

	float CalculateAutoAttackDamage(CObject* source, CObject* target) {

		auto autoAttackDamageType = DamageType_Physical;
		auto rawPhysicalDamage = 0.0f;
		auto rawMagicalDamage = 0.0f;
		auto rawTrueDamage = 0.0f;
		auto calculatedPhysicalDamage = 0.0f;
		auto calculatedMagicalDamage = 0.0f;
		auto rawTotalDamage = source->TotalAttackDamage();

		if (target->IsLaneMinion()) {
			if (target->MaxHealth() <= 6.0f) {
				return 1.0f;
			}
		}


		float k = 1.f;
		if (source->IsHero())
		{
			if (source->GetSkinData()->GetSkinHash() == SkinHash::Kalista)
			{
				k = 0.9f;
			}
			if (source->GetSkinData()->GetSkinHash() == SkinHash::Kled &&
				source->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->GetSpellNameHash() == FNV("KledRiderQ"))
			{
				k = 0.8f;
			}
			/*auto damageOnHit = ComputeDamageOnHit(source, target);
			rawPhysicalDamage += damageOnHit.PhysicalDamage;
			rawMagicalDamage += damageOnHit.MagicalDamage;
			rawTrueDamage += damageOnHit.TrueDamage;*/
		}

		switch (autoAttackDamageType) {
		case DamageType_Physical:
			rawPhysicalDamage += rawTotalDamage;
			break;
		case DamageType_Magical:
			rawMagicalDamage += rawTotalDamage;
			break;
		}

		// Turrets too. 

		if (source->IsTurret())
		{
			if (target->IsLaneMinion())
			{
				rawPhysicalDamage = target->MaxHealth() * 0.45f;
				if (target->IsSiegeMinion())
				{
					rawPhysicalDamage = target->MaxHealth() * 0.14f;
				}
				else if (target->IsCasterMinion())
				{
					rawPhysicalDamage = target->MaxHealth() * 0.70f;
				}
				return rawPhysicalDamage;
			}
		}

		calculatedPhysicalDamage += source->CalculateDamage(target, rawPhysicalDamage * k, 1);
		calculatedMagicalDamage += source->CalculateDamage(target, rawMagicalDamage, 2);


		return calculatedPhysicalDamage + calculatedMagicalDamage + rawTrueDamage;
	}

	float GetAutoAttackDamage(CObject* target)
	{
		return CalculateAutoAttackDamage(this, target);
	}

	float GetAutoAttackDamage2(
		CObject* target,
		bool includePassive = false)
	{
		auto source = this;
		double result = source->TotalAttackDamage();
		float k = 1.f;
		if (source->GetSkinData()->GetSkinHash() == SkinHash::Kalista)
		{
			k = 0.9f;
		}
		if (source->GetSkinData()->GetSkinHash() == SkinHash::Kled &&
			source->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->GetSpellNameHash() == FNV("KledRiderQ"))
		{
			k = 0.8f;
		}

		if (!includePassive)
		{
			return this->CalculateDamage(target, result * k);
		}

		float reduction = 0.f;

		//var hero = source as Obj_AI_Hero;
		//if (hero != null)
		//{
		//	// Spoils of War
		//	var minionTarget = target as Obj_AI_Minion;
		//	if (hero.IsMelee() && minionTarget != null && minionTarget.IsEnemy
		//		&& minionTarget.Team != GameObjectTeam.Neutral
		//		&& hero.Buffs.Any(buff = > buff.Name == "talentreaperdisplay" && buff.Count > 0))
		//	{
		//		if (
		//			HeroManager.AllHeroes.Any(
		//				h = >
		//				h.NetworkId != source.NetworkId && h.Team == source.Team
		//				&& h.Distance(minionTarget.Position) < 1100))
		//		{
		//			var value = 0;

		//			if (Items.HasItem(3302, hero))
		//			{
		//				value = 200; // Relic Shield
		//			}
		//			else if (Items.HasItem(3097, hero))
		//			{
		//				value = 240; // Targon's Brace
		//			}
		//			else if (Items.HasItem(3401, hero))
		//			{
		//				value = 400; // Face of the Mountain
		//			}

		//			return value + hero.TotalAttackDamage;
		//		}
		//	}

		//	//Champions passive damages:
		//	result +=
		//		AttackPassives.Where(
		//			p = > (p.ChampionName == "" || p.ChampionName == hero.ChampionName) && p.IsActive(hero, target))
		//		.Sum(passive = > passive.GetDamage(hero, target));

		//	// BotRK
		//	if (Items.HasItem(3153, hero))
		//	{
		//		var d = 0.06*target.Health;
		//		if (target is Obj_AI_Minion)
		//		{
		//			d = Math.Min(d, 60);
		//		}

		//		result += d;
		//	}
		//}

		//var targetHero = target as Obj_AI_Hero;
		//if (targetHero != null)
		//{
		//	// Ninja tabi
		//	if (Items.HasItem(3047, targetHero))
		//	{
		//		k *= 0.9d;
		//	}

		//	// Nimble Fighter
		//	if (targetHero.ChampionName == "Fizz")
		//	{
		//		var f = new int[] {4, 6, 8, 10, 12, 14};
		//		reduction += f[(targetHero.Level - 1) / 3];
		//	}
		//}


		if (source->IsLaneMinion())
		{
			k += source->PercentDamageToBarracksMinionMod();
		}

		if (target->IsLaneMinion())
		{
			result -= target->FlatDamageReductionFromBarracksMinionMod();
		}

		//TODO: need to check if there are items or spells in game that reduce magical dmg % or by amount
		if (source->IsHero() && source->GetSkinData()->GetSkinHash() == SkinHash::Corki)
		{
			//return CalcMixedDamage(source, target, (result - reduction)*k, result*k);
		}

		return this->CalcPhysicalDamage(target, (result - reduction) * k + 0); // 0 = PassiveFlatMod(source, target)
	}

	float DamageReductionMod(
		CObject* target,
		double amount,
		kDamageType damageType)
	{
		auto source = this;
		if (source->IsHero())
		{
			// Exhaust:
			// + Exhausts target enemy champion, reducing their Movement Speed and Attack Speed by 30%, their Armor and Magic Resist by 10, and their damage dealt by 40% for 2.5 seconds.
			if (source->HasBuff(FNV("Exhaust")))
			{
				amount *= 0.6f;
			}
		}

		if (target->IsHero())
		{
			//Damage Reduction Masteries

			//DAMAGE REDUCTION 2 %, increasing to 8 % when near at least one allied champion
			//IN THIS TOGETHER 8 % of the damage that the nearest allied champion would take is dealt to you instead.This can't bring you below 15% health.
			//var BondofStones = targetHero.GetMastery(MasteryData.Resolve.BondofStones);
			//if (BondofStones != null && BondofStones.IsActive())
			//{
			//    var closebyenemies =
			//        HeroManager.Enemies.Any(x => x.NetworkId != target.NetworkId && x.Distance(target) <= 500);
			//    //500 is not the real value
			//    if (closebyenemies)
			//    {
			//        amount *= 0.92d;
			//    }
			//    else
			//    {
			//        amount *= 0.98d;
			//    }
			//}

			// Items:

			// Doran's Shield
			// + Blocks 8 damage from single target attacks and spells from champions.
			//if (Items.HasItem(1054, targetHero))
			//{
			//	amount -= 8;
			//}

			//// Passives:

			//// Unbreakable Will
			//// + Alistar removes all crowd control effects from himself, then gains additional attack damage and takes 70% reduced physical and magic damage for 7 seconds.
			//if (target.HasBuff("Ferocious Howl"))
			//{
			//	amount *= 0.3d;
			//}

			//// Tantrum
			//// + Amumu takes reduced physical damage from basic attacks and abilities.
			//if (target.HasBuff("Tantrum") && damageType == DamageType.Physical)
			//{
			//	amount -= new[] {2, 4, 6, 8, 10}[target.Spellbook.GetSpell(SpellSlot.E).Level - 1];
			//}

			//// Unbreakable
			//// + Grants Braum 30% / 32.5% / 35% / 37.5% / 40% damage reduction from oncoming sources (excluding true damage and towers) for 3 / 3.25 / 3.5 / 3.75 / 4 seconds.
			//// + The damage reduction is increased to 100% for the first source of champion damage that would be reduced.
			//if (target.HasBuff("BraumShieldRaise"))
			//{
			//	amount -= amount
			//		* new[] {0.3d, 0.325d, 0.35d, 0.375d, 0.4d}[
			//			target.Spellbook.GetSpell(SpellSlot.E).Level - 1];
			//}

			//// Idol of Durand
			//// + Galio becomes a statue and channels for 2 seconds, Taunt icon taunting nearby foes and reducing incoming physical and magic damage by 50%.
			//if (target.HasBuff("GalioIdolOfDurand"))
			//{
			//	amount *= 0.5d;
			//}

			//// Courage
			//// + Garen gains a defensive shield for a few seconds, reducing incoming damage by 30% and granting 30% crowd control reduction for the duration.
			//if (target.HasBuff("GarenW"))
			//{
			//	amount *= 0.7d;
			//}

			//// Drunken Rage
			//// + Gragas takes a long swig from his barrel, disabling his ability to cast or attack for 1 second and then receives 10% / 12% / 14% / 16% / 18% reduced damage for 3 seconds.
			//if (target.HasBuff("GragasWSelf"))
			//{
			//	amount -= amount
			//		* new[] {0.1d, 0.12d, 0.14d, 0.16d, 0.18d}[
			//			target.Spellbook.GetSpell(SpellSlot.W).Level - 1];
			//}

			//// Void Stone
			//// + Kassadin reduces all magic damage taken by 15%.
			//if (target.HasBuff("VoidStone") && damageType == DamageType.Magical)
			//{
			//	amount *= 0.85d;
			//}

			//// Shunpo
			//// + Katarina teleports to target unit and gains 15% damage reduction for 1.5 seconds. If the target is an enemy, the target takes magic damage.
			//if (target.HasBuff("KatarinaEReduction"))
			//{
			//	amount *= 0.85d;
			//}

			//// Vengeful Maelstrom
			//// + Maokai creates a magical vortex around himself, protecting him and allied champions by reducing damage from non-turret sources by 20% for a maximum of 10 seconds.
			//if (target.HasBuff("MaokaiDrainDefense") && !(source is Obj_AI_Turret))
			//{
			//	amount *= 0.8d;
			//}

			//// Meditate
			//// + Master Yi channels for up to 4 seconds, restoring health each second. This healing is increased by 1% for every 1% of his missing health. Meditate also resets the autoattack timer.
			//// + While channeling, Master Yi reduces incoming damage (halved against turrets).
			//if (target.HasBuff("Meditate"))
			//{
			//	amount -= amount
			//		* new[] {0.5d, 0.55d, 0.6d, 0.65d, 0.7d}[
			//			target.Spellbook.GetSpell(SpellSlot.W).Level - 1] / (source is Obj_AI_Turret ? 2 : 1);
			//}

			//// Shadow Dash
			//// + Shen reduces all physical damage by 50% from taunted enemies.
			//if (target.HasBuff("Shen Shadow Dash") && source.HasBuff("Taunt") && damageType == DamageType.Physical)
			//{
			//	amount *= 0.5d;
			//}
		}
		return amount;
	}

	double PassivePercentMod(CObject* target, double amount)
	{
		auto source = this;
		//Minions and towers passives:
		if (source->IsTurret())
		{
			//Siege minions (caster minions too!) receive 70% damage from turrets
			if (target->IsSiegeMinion() || target->IsCasterMinion())

			{
				amount *= 0.7f;
			}

			//Normal minions take 114% more damage from towers. -- not anymore
			/*else if (MeleeMinionList.Contains(target.CharData.BaseSkinName))
			{
				amount *= 1.14285714285714d;
			}*/
		}

		// Masteries:
		if (source->IsHero())
		{
			// Offensive masteries:

			//INCREASED DAMAGE FROM ABILITIES 0.4/0.8/1.2/1.6/2%

			/*Mastery sorcery = hero.GetMastery(MasteryData.Ferocity.Sorcery);
			if (sorcery != null && sorcery.IsActive())
			{
				amount *= 1 + ((new double[] { 0.4, 0.8, 1.2, 1.6, 2.0 }[sorcery.Points]) / 100);
			}

			//MELEE Deal an additional 3 % damage, but receive an additional 1.5 % damage
			//RANGED Deal an additional 2 % damage, but receive an additional 2 % damage
			Mastery DoubleEdgedSword = hero.GetMastery(MasteryData.Ferocity.DoubleEdgedSword);
			if (DoubleEdgedSword != null && DoubleEdgedSword.IsActive())
			{
				amount *= hero.IsMelee() ? 1.03 : 1.02;
			}

			// Bounty Hunter: TAKING NAMES You gain a permanent 1 % damage increase for each unique enemy champion you kill
			Mastery BountyHunter = hero.GetMastery(MasteryData.Ferocity.BountyHunter);
			if (BountyHunter != null && BountyHunter.IsActive())
			{
				//We need a hero.UniqueChampionsKilled or both the sender and the target for ChampionKilled OnNotify Event
				// amount += amount * Math.Min(hero.ChampionsKilled, 5);
			}*/

			//Opressor: KICK 'EM WHEN THEY'RE DOWN You deal 2.5% increased damage to targets with impaired movement (slows, stuns, taunts, etc)
		   // var Opressor = hero.GetMastery(MasteryData.Ferocity.DoubleEdgedSword);
		   // if (targetHero != null && Opressor != null && Opressor.IsActive() && targetHero.IsMovementImpaired())
		   // {
		   //     amount *= 1.025;
		   // }

			//Merciless DAMAGE AMPLIFICATION 1 / 2 / 3 / 4 / 5 % increased damage to champions below 40 % health
			if (target->IsHero())
			{
				// var Merciless = hero.GetMastery(MasteryData.Cunning.Merciless);
				// if (Merciless != null && Merciless.IsActive() && targetHero.HealthPercent < 40)
				// {
				//     amount *= 1 + Merciless.Points/100f;
				// }
				 //Thunderlord's Decree: Your 3rd ability or basic attack on an enemy champion shocks them, dealing 10 - 180(+0.3 bonus attack damage)(+0.1 ability power) magic damage in an area around them

				 /*var Thunder = hero.GetMastery(MasteryData.Cunning.ThunderlordsDecree);
				 if (Thunder != null && Thunder.IsActive())
				 {
					 if (Orbwalking.LastTargets != null && Orbwalking.LastTargets[0] == targetHero.NetworkId &&
						 Orbwalking.LastTargets[1] == targetHero.NetworkId)
						 amount += 10*hero.Level + (0.3*hero.TotalAttackDamage) + (0.1*hero.TotalMagicalDamage);
				 }*/
			}

			// Double edge sword:
			// Deal an additional 5 % damage, but receive an additional 2.5 % damage
			//var des = hero.GetMastery(MasteryData.Ferocity.DoubleEdgedSword);
			//if (des != null && des.IsActive())
			//{
			//    amount *= 1.05d;
			//}
		}

		return

			amount;
	}

	double CalcPhysicalDamage(CObject* target, float amount)
	{
		auto source = this;

		double armorPenetrationPercent = source->PercentArmorPenetration();
		double armorPenetrationFlat = source->PhysicalLethality();
		double bonusArmorPenetrationMod = source->PercentBonusArmorPenetration();

		// Minions return wrong percent values.
		if (source->IsLaneMinion())
		{
			armorPenetrationFlat = 0.f;
			armorPenetrationPercent = 1.f;
			bonusArmorPenetrationMod = 1.f;
		}

		// Turrets too.
		if (source->IsTurret())
		{
			armorPenetrationFlat = 0.f;
			armorPenetrationPercent = 1.f;
			bonusArmorPenetrationMod = 1.f;
		}

		if (source->IsTurret())
		{
			if (target->IsLaneMinion())
			{
				amount *= 1.25;
				if (target->IsSiegeMinion())
				{
					amount *= 0.7;
				}

				return amount;
			}
		}

		// Penetration can't reduce armor below 0.
		auto armor = target->Armor();
		auto bonusArmor = target->BonusArmor();

		double value;
		if (armor < 0)
		{
			value = 2 - 100 / (100 - armor);
		}
		else if ((armor * armorPenetrationPercent) - (bonusArmor * (1 - bonusArmorPenetrationMod))
			- armorPenetrationFlat < 0)
		{
			value = 1;
		}
		else
		{
			value = 100
				/ (100 + (armor * armorPenetrationPercent) - (bonusArmor * (1 - bonusArmorPenetrationMod))
					- armorPenetrationFlat);
		}

		auto damage = this->DamageReductionMod(
			target,
			PassivePercentMod(target, value) * amount,
			kDamageType::DamageType_Physical);

		// Take into account the percent passives, flat passives and damage reduction.
		return damage;
	}

	//type 0 = true damage; 1 = ad; 2 = ap
	float CalculateDamage(CObject* to, float rawDamage, int type = 1) {

		if (to == nullptr)
			return 0;

		if (type == 0)
			return rawDamage;

		if (type == 1)
		{
			float adMultiplier = 0.0f;
			//    printf("lethality: %.0f", this->PhysicalLethality());
			float flatpen = this->PhysicalLethality() * (0.6 + 0.4 * this->Level() / 18);
			//    printf("flatpen: %.0f", flatpen);
				//float armor = to->Armor();
			float armoraftercalc = (to->Armor() * this->ArmorPenPercent() - flatpen);
			if (armoraftercalc > 0)
				adMultiplier = 100 / (100 + armoraftercalc);
			else
				adMultiplier = 2 - (100 / (100 - armoraftercalc));

			return ((adMultiplier * rawDamage));
		}

		else if (type == 2)
		{
			float adMultiplier = 0.0f;
			float flatpen = this->MagicPen();
			//float percentpen = 1 - this->MagicPenPercent();
			float mres = (to->MRes() * this->MagicPenPercent() - flatpen);

			if (mres > 0)
				adMultiplier = 100 / (100 + mres);
			else
				adMultiplier = 2 - (100 / (100 - mres));

			return ((adMultiplier * rawDamage));
		}
	};



	float GetSelfAttackRange() {
		return this->AttackRange() + this->BoundingRadius();
	}

	float GetRealAutoAttackRange(CObject* target)
	{
		auto Player = (CObject*)global::localPlayer;
		auto result = this->AttackRange() + this->BoundingRadius();
		if (target->IsValidTarget())
		{
			if (global::LocalChampNameHash == FNV("Aphelios"))
			{
				if (target->HasBuff(FNV("aphelioscalibrumbonusrangedebuff")))
					return 1800;
			}

			result -= std::min((global::ping - 40) / 3.f, 10.f);
			result -= 11;
			if (Player->IsMoving() && target->IsMoving())
			{
				if (!target->IsFacing(Player->ServerPosition()))
					result -= 8;
				if (!Player->IsFacing(target->ServerPosition()))
					result -= 8;
			}


			result += target->BoundingRadius();
		}

		return result;
	}


	bool IsReady(int slot)
	{
		return this->GetSpellBook()->GetSpellSlotByID(slot)->IsReady() && (GetSpellState(slot) == SpellState::Ready);
	}
};
CObject* GetLocalObject() {
	return (CObject*)global::localPlayer;
}
#define me GetLocalObject()
