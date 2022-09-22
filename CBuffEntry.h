#pragma once
#include "Memory.h"
#include "Macros.h"


class BuffScriptInstance {
public:
	MAKE_DATA(unsigned short, CasterId, 0x4);

};


class CBuffEntry {
public:

	MAKE_DATA2(BuffType, getBuffType, O_BUFFMGR_BUFFTYPE);
	MAKE_DATA(DWORD, BuffInfo, O_BUFFMGR_BUFFINFO);
	MAKE_DATA(bool, IsPermanent, O_BUFFMGR_IsPermanent);

	DWORD strptr;

	int Count()
	{
		if (this->GetBuffCountInt() >= this->GetBuffCountAlt() && this->GetBuffCountInt() > 0)
		{
			return this->GetBuffCountInt();
		}
		else
		{
			if (this->GetBuffCountAlt() > 0)
			{
				return this->GetBuffCountAlt();
			}
		}

		return 0;
	}

	short CasterId() {
		return RPM<short>(RPM<DWORD>(RPM<DWORD>(RPM<DWORD>(this) + O_BUFFMGR_BUFFINFO)) + 0x4);
	}

	float GetBuffStartTime() {
		return RPM<float>(RPM<DWORD>(this) + O_BUFFMGR_STARTTIME);
	}

	float GetBuffEndTime() {
		return RPM<float>(RPM<DWORD>(this) + O_BUFFMGR_ENDTIME);
	}
	float GetRemainingTime()
	{
		return RPM<float>(RPM<DWORD>(this) + O_BUFFMGR_ENDTIME) - RPM<float>(m_Base + offsets_lol.oGameTime);
	}
	int GetBuffCountAlt() {
		return RPM<int>(RPM<DWORD>(this) + 0x24);// (RPM<int>(RPM<DWORD>(this) + 0x24) - RPM<int>(RPM<DWORD>(this) + 0x20)) >> 3;
	}

	/*float GetBuffCountFloat() {
		return RPM<float>(RPM<DWORD>(this) + O_BUFFMGR_flBUFFCOUNT);
	}*/

	int GetBuffCountInt() {
		return RPM<int>(RPM<DWORD>(this) + O_BUFFMGR_iBUFFCOUNT);
	}
	bool IsValid() {
		//if (this == NULL || (DWORD)this <= 0x1000)
		//    return false;
		//return true;
		return /*strcmp(GetBuffName().c_str(), "NULL") &&*/!GetBuffName().empty() && GetBuffCountAlt() > 0;
		//return true;
	}

	bool IsAlive()
	{
		auto time = RPM<float>(m_Base + offsets_lol.oGameTime);

		return time < this->GetBuffEndTime() && time > this->GetBuffStartTime();
	}

	BuffScriptInstance* GetScriptInstance()
	{
		return (BuffScriptInstance*)BuffInfo();
	}

	std::string GetBuffName() {
		auto aux = RPM<DWORD>((DWORD)this + 0x0); //oBuffname = 0x8
		if (!aux)
		{
			return "";
		}

		auto aux2 = RPM<DWORD>((DWORD)aux + 0x8);
		if (!aux2)
		{
			return "";
		}

		char nameobj[0x80];
		if (ReadVirtualMemory((void*)(aux2 + 0x4), &nameobj, sizeof(nameobj)))
		{
			std::string s = nameobj;

			return s;
		}
		return "";
	}
	unsigned int GetBuffHash()
	{
		auto aux = RPM<DWORD>((DWORD)this + 0x0); //oBuffname = 0x8
		//if (menucfg.bDebugBuffs)
		//    printf("VALID buff1: %x\n", aux);
		if (aux == 0x0)
		{
			return 0x0;
			//if (menucfg.bDebugBuffs)
			//    printf("NULL1 buff: %x\n", aux);
		}
		auto aux2 = RPM<DWORD>((DWORD)aux + 0x8);
		//if (menucfg.bDebugBuffs)
			//pBuffPtrprintf("VALID buff2:  %x | %x\n", aux, aux2);
		if (aux2 == 0x0)
		{

			//if (menucfg.bDebugBuffs)
			//    printf("NULL2 buff: %x | %x\n", aux, aux2);
			return 0x0;
		}
		return RPM<unsigned int>((DWORD)aux2 + 0x84);

	}
};