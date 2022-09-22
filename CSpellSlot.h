#pragma once
#include "Memory.h"
#include "Macros.h"
#include "CSpellData.h"
class CSpellSlot {

public:
	enum class SpellToggleState
	{
		None,
		NotToggled,
		Toggled
	};

	MAKE_DATA2(float, AdditionalMana, 0x18);
	MAKE_DATA2(int, Level, 0x1C);
	MAKE_DATA2(float, CastEndTime, 0x24); //the time the spell will be available
	MAKE_DATA2(float, GetCD, 0x14);
	MAKE_DATA2(float, CastTime, 0x60); //old 0x64
	MAKE_DATA2(float, GetCastTime, 0x104); //old 0x64
	MAKE_DATA2(SpellToggleState, ToggleState, 0x7C);
	MAKE_DATA2(float, TotalCD, 0x74);
	MAKE_DATA2(int, Ammo, 0x54);
	MAKE_DATA2(int, StackCount, 0x8C)


		bool isLearned()
	{
		return Level() > 0;
	}

	float currentCooldown()
	{
		if (Ammo() > 0)
		{
			float r = CastTime() - GetGameTime();
			if (r <= 0.0f)
				r = 0.0f;

			return r;
		}
		float r = CastEndTime() - GetGameTime();
		if (r <= 0.0f)
			r = 0.0f;

		return r;
	}

	bool isOnCooldown()
	{
		return currentCooldown() > 0.f;
	}

	//bool IsReady()
	//{
	//	if (!isLearned())
	//	{
	//		return false;
	//	}

	//	if (isOnCooldown())
	//	{
	//		return false;
	//	}

	//	// Check for your mana, i read from UnitInfo.json you can use 0x314 (Its ResourceType) enum at bottom
	//	if (!this->GetSpellData()->ManaReady(RPM<float>(RPM<uint32_t>(m_Base + offsets_lol.oLocalPlayer) + offsets_lol.oObjMana), this->Level(), this->AdditionalMana()))
	//	{
	//		return false;
	//	}

	//	return true;
	//}

	float ManaCost()
	{
		return this->GetSpellData()->ManaCost(Level());
	}



	CSpellData* GetSpellData() {
		auto retaddr = RPM<int>(RPM<uint32_t>(this) + oSpellInfo);
		if (retaddr == NULL)
			return NULL;

		auto ret = RPM<uint32_t>(retaddr + oSpellData);
		if (ret == NULL)
			return NULL;

		return (CSpellData*)(ret);
	}

	float GetRange()
	{
		return GetSpellData()->SpellRangeArray(Level());
	}

	static float GetGameTime() {
		return RPM<float>(m_Base + offsets_lol.oGameTime);
	}

	double CoolDown() {
		double calc = 0;
		if (this->Ammo() >= 1 && this->CastEndTime() > 0.0f)
		{
			calc = (double)this->CastEndTime() - (double)GetGameTime();
		}
		else if (this->Ammo() >= 0 && this->CastTime() > 0.0f)
		{
			calc = (double)this->CastTime() - (double)GetGameTime();
		}
		else if (this->CastEndTime() > this->CastTime())
		{
			calc = (double)this->CastEndTime() - (double)GetGameTime();
		}
		else if (this->CastEndTime() > 0.0f)
		{
			calc = (double)this->CastEndTime() - (double)GetGameTime();
		}
		return calc;
	}

	float GetCooldownTotal() {
		float cd = (this->CastEndTime()) - GetGameTime();
		if (cd <= 0.0f)
			cd = 0.0f;
		return cd;
	}



	/*bool IsReadyCD() {
		float calc = this->CoolDownEndTime() - GetGameTime();
		if (calc <= 0.0f)
			return true;
		return false;
	}*/
	//bool IsReady2() {
	//	//printf("CDTIME: %f | Game TIME: %f\n", this->CoolDownEndTime(), GetGameTime());
	//	//if (this->CoolDownEndTime2() == 0)
	//	//{
	//	float calc = (double)this->CoolDownEndTime2() - (double)GetGameTime();
	//	if (calc <= 0.0f && this->Level() > 0 && this->GetSpellData()->ManaReady(RPM<float>(RPM<uint32_t>(m_Base + oLocalPlayer) + oObjMana), this->Level()))
	//		return true;
	//	//}
	//	//else
	//	//{
	//	//	float calc = (double)this->CoolDownEndTime2() - (double)GetGameTime();
	//	//	if (calc <= 0.0f && this->Level() > 0)
	//	//		return true;
	//	//}
	//	return false;
	//}
	bool IsItemReady() {
		//printf("CDTIME: %f | Game TIME: %f\n", this->CoolDownEndTime(), GetGameTime());
		//if (this->CoolDownEndTime2() == 0)
		//{
		float calc = (double)this->CastEndTime() - (double)GetGameTime();
		if (calc <= 0.0f && this->Level() > 0)
			return true;
		//}
		//else
		//{
		//	float calc = (double)this->CoolDownEndTime2() - (double)GetGameTime();
		//	if (calc <= 0.0f && this->Level() > 0)
		//		return true;
		//}
		return false;
	}
	bool IsReady() {
		return GetCooldownTotal() <= 0.0f && this->Level() > 0 && this->GetSpellData()->ManaReady(RPM<float>(RPM<uint32_t>(m_Base + offsets_lol.oLocalPlayer) + offsets_lol.oObjMana), this->Level(), this->AdditionalMana());
	}

	/*bool IsReady() {
		float endtime = 0;
		int ammo = this->Ammo();
		float endtime1 = this->CastEndTime();
		float endtime2 = this->CastTime();
		if (ammo >= 1 && endtime1 > 0.0f)
		{
			endtime = endtime1;
		}
		else if (ammo >= 0 && endtime2 > 0.0f)
		{
			endtime = endtime2;
		}
		else if (endtime1 > 0.0f)
		{
			endtime = endtime1;
		}

		if (ammo == 0 && endtime1 > endtime2)
		{
			endtime = endtime1;
		}

		float calc = endtime - (double)GetGameTime();
		if (endtime > 0.0f)
			if (calc <= 0.0f && this->Level() > 0 && this->GetSpellData()->ManaReady(RPM<float>(RPM<uint32_t>(m_Base + offsets_lol.oLocalPlayer) + offsets_lol.oObjMana), this->Level(), this->AdditionalMana()))
				return true;

		return false;
	}*/

};