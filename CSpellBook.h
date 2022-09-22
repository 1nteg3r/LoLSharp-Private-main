#pragma once
#include "Memory.h"
#include "CActiveSpellEntry.h"
#include "CSpellSlot.h"
class CSpellBook
{
public:
	ActiveSpellEntry* GetActiveSpellEntry() {
		return (ActiveSpellEntry*)(RPM<DWORD>(this + 0x20));
	}
	bool GetActiveSpellValid() {
		return RPM<DWORD>(this + 0x20) != 0x0;
	}
	/*void SetCastSlot() {
		int a = 65;
		WPM<int>(this + 8, a);
	}*/
	int GetCastSlot() {
		return (RPM<int>(this + 8));
	}
	std::bitset<4> GetCastState() {
		return (RPM<std::bitset<4>>(this + 0x38));
	}
	CSpellSlot* GetSpellSlotByID(int ID) {
		return (CSpellSlot*)(this + oSpellSlotArrayStart + (0x4 * ID));
	}
};