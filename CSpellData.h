#pragma once
#include "Memory.h"
#include "Macros.h"

class SpellBooleans //
{
public:
	bool AmmoNotAffectedByCDR; //0x0000
	bool AmmoNotAffectedByCDR2; //0x0001
	bool CostAlwaysShownInUI; //0x0002
	bool CannotBeSuppressed; //0x0003
	bool CanCastWhileDisabled; //0x0004
	bool CanCastOrQueueWhileCasting; //0x0005
	bool CanOnlyCastWhileDisabled; //0x0006
	bool CantCancelWhileWindingUp; //0x0007
	bool CantCancelWhileChanneling; //0x0008
	bool CantCastWhileRooted; //0x0009
	bool ApplyAttackDamage; //0x000A
	bool ApplyAttackEffect; //0x000B
	bool ApplyMaterialOnHitSound; //0x000C
	bool DoesntBreakChannels; //0x000D
	bool BelongsToAvatar; //0x000E
	bool IsDisabledWhileDead; //0x000F
	bool CanOnlyCastWhileDead; //0x0010
	bool CursorChangesInGrass; //0x0011
	bool CursorChangesInTerrain; //0x0012
	bool LineMissileEndsAtTargetPoint; //0x0013
	bool SpellRevealsChampion; //0x0014
	bool LineMissileTrackUnitsAndContinues; //0x0015
	bool UseMinimapTargeting; //0x0016
	bool CastRangeUseBoundingBoxes; //0x0017
	bool MinimapIconRotation; //0x0018
	bool UseChargeChanneling; //0x0019
	bool UseChargeTargeting; //0x001A
	bool CanMoveWhileChanneling; //0x001B
	bool DisableCastBar; //0x001C
	bool ShowChannelBar; //0x001D
	bool AlwaysSnapFacing; //0x001E
	bool UseAnimatorFramerate; //0x001F
	bool HaveHitEffect; //0x0020
	bool HaveHitBone; //0x0021
	bool HaveAfterEffect; //0x0022
	bool HavePointEffect; //0x0023
	bool IsToggleSpell; //0x0024
	bool LineMissileBounces; //0x0025
	bool LineMissileUsesAccelerationForBounce; //0x0026
	bool MissileFollowsTerrainHeight; //0x0027
	bool DoNotNeedToFaceTarget; //0x0028
	bool NoWinddownIfCancelled; //0x0029
	bool IgnoreRangeCheck; //0x002A
	bool OrientRadiusTextureFromPlayer; //0x002B
	bool UseAutoattackCastTime; //0x002C
	bool IgnoreAnimContinueUntilCastFrame; //0x002D
	bool HideRangeIndicatorWhenCasting; //0x002E
	bool UpdateRotationWhenCasting; //0x002F
	bool ConsideredAsAutoAttack; //0x0030
	bool MinimapIconDisplayFlag; //0x0031
}; //Size: 0x0044

class CSpellData
{
public:
	MAKE_DATA(bool, CantCancelWhileWindingUp, oCantCancelWhileWindingUp); // 
	MAKE_DATA(bool, CanMoveWhileChanneling, oCanMoveWhileChanneling); // 
	MAKE_DATA(bool, CantCancelWhileChanneling, oCantCancelWhileChanneling); // 
	MAKE_DATA(bool, ChannelIsInterruptedByAttacking, oChannelIsInterruptedByAttacking);


	float DataCastDelay()
	{
		return RPM<float>(this + 0x250) / 10.f;
	}

	MAKE_DATA(float, CastTime, 0x270);

	MAKE_DATA(float, MissileSpeed, oMissileSpeed); //works only with basic attacks
	MAKE_DATA(float, MissileWidth, oMissileWidth); //0x3D4 0x3A8 0x38C
	MAKE_DATA(float, SpellRadiusArray, oCastRadius); //0x3D4 0x3A8 0x38C
	MAKE_DATA(float, SpellRadiusSecondary, oCastRadiusSecondary); //0x3D4 0x3A8 0x38C

	float ManaCost(int Level)
	{
		if (Level == 1)
			return RPM<float>(this + oManaCost);
		if (Level == 2)
			return RPM<float>(this + oManaCost + 1 * 0x4);
		if (Level == 3)
			return RPM<float>(this + oManaCost + 2 * 0x4);
		if (Level == 4)
			return RPM<float>(this + oManaCost + 3 * 0x4);
		if (Level == 5)
			return RPM<float>(this + oManaCost + 4 * 0x4);
		if (Level == 6)
			return RPM<float>(this + oManaCost + 5 * 0x4);
	}

	float SpellRangeArray(int level = 1)
	{
		return (RPM<float>(this + oSpellRangeArray) > 2000.f || RPM<float>(this + oSpellRangeArray + (level - 1) * 0x4) == 0) ? RPM<float>(this + oSpellRangeArrayOverride + (level - 1) * 0x4) : RPM<float>(this + oSpellRangeArray + (level - 1) * 0x4);
	}

	bool ManaReady(float curmana, int Level, float additionalmana)
	{
		return (curmana - (ManaCost(Level) + additionalmana)) >= 0;
	}

	std::string GetMissileName() {
		uint32_t ptr = RPM<uint32_t>(this + 0x6C);
		if (!IsValid(ptr) || ptr == 0x0)
			return std::string("");

		char nameobj[0x20];
		if (ReadVirtualMemory((void*)ptr, &nameobj, sizeof(nameobj)))
		{
			std::string s = std::string(nameobj);
			//printf("string: %s\n", s.c_str());
			ZeroMemory(nameobj, 0x20);
			return s;
		}
		return std::string("");
	}
	fnv::hash GetMissileNameHash() {
		uint32_t ptr = RPM<uint32_t>(this + 0x6C);
		if (!IsValid(ptr) || ptr == 0x0)
			return 0x0;

		char nameobj[0x20];
		if (ReadVirtualMemory((void*)ptr, &nameobj, sizeof(nameobj)))
		{
			std::string s = std::string(nameobj);
			//printf("string: %s\n", s.c_str());
			ZeroMemory(nameobj, 0x20);
			return fnv::hash_runtime(s.c_str());
		}
		return 0x0;
	}

	fnv::hash GetSpellNameHash() {
		uint32_t ptr = RPM<uint32_t>(this + 0x90);
		if (!IsValid(ptr) || ptr == 0x0)
			return 0x0;

		char nameobj[0x20];
		if (ReadVirtualMemory((void*)ptr, &nameobj, sizeof(nameobj)))
		{
			std::string s = std::string(nameobj);
			//printf("string: %s\n", s.c_str());
			ZeroMemory(nameobj, 0x20);
			return fnv::hash_runtime(s.c_str());
		}
		return 0x0;
	}

	std::string GetSpellName() {
		uint32_t ptr = RPM<uint32_t>(this + 0x90);
		if (!IsValid(ptr) || ptr == 0x0)
			return std::string("");

		char nameobj[0x20];
		if (ReadVirtualMemory((void*)ptr, &nameobj, sizeof(nameobj)))
		{
			std::string s = std::string(nameobj);
			//printf("string: %s\n", s.c_str());
			ZeroMemory(nameobj, 0x20);
			return s;
		}
		return std::string("");
	}

	std::string GetDescription() {
		uint32_t ptr = RPM<uint32_t>(this + 0x94);
		if (!IsValid(ptr) || ptr == 0x0)
			return std::string("");

		char nameobj[0x20];
		if (ReadVirtualMemory((void*)ptr, &nameobj, sizeof(nameobj)))
		{
			std::string s = std::string(nameobj);
			//printf("string: %s\n", s.c_str());
			ZeroMemory(nameobj, 0x20);
			return s;
		}
		return std::string("");
	}

};