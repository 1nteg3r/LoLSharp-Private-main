#pragma once
#include "Macros.h"
#include "CSpellData.h"

enum kSpellSlot
{
	SpellSlot_Unknown = -1,
	SpellSlot_Q,
	SpellSlot_W,
	SpellSlot_E,
	SpellSlot_R,
	SpellSlot_Summoner1,
	SpellSlot_Summoner2,
	SpellSlot_Item1,
	SpellSlot_Item2,
	SpellSlot_Item3,
	SpellSlot_Item4,
	SpellSlot_Item5,
	SpellSlot_Item6,
	SpellSlot_Trinket,
	SpellSlot_Recall,
	SpellSlot_SpecialAttack = 45,
	SpellSlot_LucianAttack = 54,
	SpellSlot_BasicAttack = 64,
	SpellSlot_BasicAttack2 = 65,
	SpellSlot_JinxFishBone = 70,
};

class ActiveSpellEntry {
public:

	CSpellData* GetSpellData() {
		auto retaddr = RPM<int>(this + 0x8);
		if (retaddr == NULL)
			return NULL;
		auto ret = RPM<uint32_t>(retaddr + oSpellData);
		if (ret == NULL)
			return NULL;

		return (CSpellData*)(ret);
	}

	MAKE_DATA(Vector3, GetStartPos, 0x84);
	MAKE_DATA(Vector3, GetEndPos, 0x90);
	MAKE_DATA(bool, isAutoAttackAll, 0xC4);

	MAKE_DATA(uint32_t, sourceID, 0x6C); //0x9BF09BE

	bool isValid()
	{
		return RPM<uint32_t>((DWORD)this) != 0;
	}

	uint32_t targetID()
	{
		if (sourceID() > 0)
		{
			uint32_t test = RPM<uint32_t>(RPM<uint32_t>((DWORD)this + 0x00C0) + 0x0)/* + 0x10 * RPM<uint32_t>((DWORD)this + 0x00C0)*/;
			return test;
		}

		return 0;
	}

	MAKE_DATA(float, CastTime, 0x15c);
	MAKE_DATA(float, CastDelay, 0xCC);
	MAKE_DATA(float, Delay, 0xDC);
	MAKE_DATA(bool, IsCastingSpell, 0xE8);
	MAKE_DATA(bool, isBasicAttack, 0xEC);
	MAKE_DATA(bool, IsSpecialAttack, 0xEC + 0x1);
	MAKE_DATA(kSpellSlot, Slot, 0xF4);


	MAKE_DATA(float, MidTick, 0x13C);
	MAKE_DATA(float, EndTick, 0x140);

	MAKE_DATA(bool, IsStopped, 0x14B); //not used ENDTICK + 0x for next 3
	MAKE_DATA(bool, IsInstantCast, 0x149);
	MAKE_DATA(bool, SpellWasCast, 0x151);

	MAKE_DATA(float, StartTick, 0x15c);



	bool IsAutoAttack()
	{
		if (this->isBasicAttack() || this->IsSpecialAttack() /*|| this->Slot() >= SpellSlot_SpecialAttack*/)
		{
			return this->targetID() > 0;
		}
		return false;
	}

	bool IsChanneling()
	{
		return !this->IsInstantCast() && this->SpellWasCast();
	}
};