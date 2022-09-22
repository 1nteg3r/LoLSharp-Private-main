#pragma once
#include "Memory.h"
#include "Macros.h"
#include "CBuffEntry.h"

struct BuffCustom {
	CBuffEntry* buffentry = nullptr;
	BuffType type = BuffType::Internal;
	DWORD buffhash = 0x0;
	int count = 0;
	float starttime = 0.f;
	float remaintime = 0.f;
	float endtime = 0.f;
	fnv::hash namehash = 0x0;
	//std::string name = "";
};
BuffCustom ZeroFuck;

//struct BuffCustom {
//	static BuffCustom Zero;
//
//	CBuffEntry* buffentry;
//	BuffType type;
//	DWORD buffhash;
//	int count;
//	float remaintime;
//	float endtime;
//	fnv::hash namehash;
//	//std::string name = "";
//	BuffCustom()
//	{
//		this->buffentry = nullptr;
//		this->type = BuffType::Internal;
//		this->buffhash = 0x0;
//		this->count = 0;
//		this->remaintime = 0;
//		this->endtime = 0;
//		this->namehash = 0x0;
//	}
//	BuffCustom(CBuffEntry* buffentry, BuffType type, DWORD buffhash, int count, float remaintime, float endtime, fnv::hash namehash)
//	{
//		this->buffentry = buffentry;
//		this->type = type;
//		this->buffhash = buffhash;
//		this->count = count;
//		this->remaintime = remaintime;
//		this->endtime = endtime;
//		this->namehash = namehash;
//	}
//	~BuffCustom()
//	{
//		this->buffentry = nullptr;
//		this->type = BuffType::Internal;
//		this->buffhash = 0x0;
//		this->count = 0;
//		this->remaintime = 0.0f;
//		this->endtime = 0.0f;
//		this->namehash = 0x0;
//	}
//};


enum BuffHash : unsigned int {
	HealthPotion = 0x3783119d,
	RefillablePotion = 0xb4d080ff,
	CorruptingPotion = 0xcf223fb3,
	TotalBiscuitofRejuvenation = 0xba861e6d,
	YoneE = 0x2531ef97,
	RiftWalk = 0x87264d20,
};

class CBuffManager {
public:


	MAKE_DATA(DWORD, pStart, 0x10);
	MAKE_DATA(DWORD, pEnd, 0x14);

	std::vector<BuffCustom> Buffs()
	{
		std::vector<BuffCustom> result = {  };

		auto buffBegin = this->pStart();
		auto buffEnd = this->pEnd();
		auto count = (buffEnd - buffBegin) / 4;
		if (count > 200)
			return result;

		for (int i = 0; i < count; i++)
		{
			auto pBuff = (CBuffEntry*)(buffBegin + (i * 4));
			std::string name = pBuff->GetBuffName();
			//std::cout << name << std::endl;

			if (!pBuff) continue;
			if (!pBuff->IsValid()) continue;
			if (pBuff->IsAlive()) {
				std::string name = pBuff->GetBuffName();

				if (ContainsOnlyASCII(name.c_str(), sizeof(name.c_str())) && name.length() > 3)
				{
					BuffCustom buf;
					buf.buffentry = pBuff;
					buf.type = pBuff->getBuffType();
					buf.buffhash = pBuff->GetBuffHash();
					buf.count = pBuff->Count();
					buf.remaintime = pBuff->GetRemainingTime();
					buf.starttime = pBuff->GetBuffStartTime();
					buf.endtime = pBuff->GetBuffEndTime();
					buf.namehash = fnv::hash_runtime(name.c_str());
					//result.push_back(BuffCustom(pBuff, pBuff->getBuffType(), pBuff->GetBuffHash(), pBuff->Count(), pBuff->GetRemainingTime(), pBuff->GetBuffEndTime(), fnv::hash_runtime(name.c_str())));
					result.push_back(buf);
				}
			}
		}
		return result;
	}

	std::vector<BuffCustomCache> BuffsCache()
	{
		std::vector<BuffCustomCache> result = {  };

		auto buffBegin = this->pStart();
		auto buffEnd = this->pEnd();
		auto count = (buffEnd - buffBegin) / 4;
		if (count > 200)
			return result;

		for (int i = 0; i < count; i++)
		{
			auto pBuff = (CBuffEntry*)(buffBegin + (i * 4));
			std::string name = pBuff->GetBuffName();
			//std::cout << name << std::endl;

			if (!pBuff) continue;
			if (!pBuff->IsValid()) continue;
			if (pBuff->IsAlive()) {
				std::string name = pBuff->GetBuffName();

				if (ContainsOnlyASCII(name.c_str(), sizeof(name.c_str())) && name.length() > 3)
				{
					BuffCustomCache buf;
					buf.type = pBuff->getBuffType();
					buf.buffhash = pBuff->GetBuffHash();
					buf.count = pBuff->Count();
					buf.remaintime = pBuff->GetRemainingTime();
					buf.starttime = pBuff->GetBuffStartTime();
					buf.endtime = pBuff->GetBuffEndTime();
					buf.namehash = fnv::hash_runtime(name.c_str());
					//result.push_back(BuffCustom(pBuff, pBuff->getBuffType(), pBuff->GetBuffHash(), pBuff->Count(), pBuff->GetRemainingTime(), pBuff->GetBuffEndTime(), fnv::hash_runtime(name.c_str())));
					result.push_back(buf);
				}
			}
		}
		return result;
	}

	BuffCustom GetBuffCacheByName(unsigned int BuffHash)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.buffhash == BuffHash)
				return buff;
		}
		return ZeroFuck;
	}

	BuffCustom GetBuffCacheByName(const char* BuffName)
	{
		auto hashn = fnv::hash_runtime(BuffName);
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == hashn)
				return buff;
		}
		return ZeroFuck;
	}

	BuffCustom GetBuffCacheByFNVHash(fnv::hash BuffName)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == BuffName)
				return buff;
		}
		return ZeroFuck;
	}

	CBuffEntry* GetBuffEntryByHash(unsigned int BuffHash)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.buffhash == BuffHash)
				return buff.buffentry;
		}
		return nullptr;
	}

	CBuffEntry* GetBuffEntryByName(const char* BuffName)
	{
		auto hashn = fnv::hash_runtime(BuffName);
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == hashn)
				return buff.buffentry;
		}
		return nullptr;
	}

	CBuffEntry* GetBuffEntryByFNVHash(fnv::hash BuffName)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == BuffName)
				return buff.buffentry;
		}
		return nullptr;
	}

	bool HasBuff(unsigned int Buffhash)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.buffhash == Buffhash)
				return true;
		}
		return false;
	}

	bool HasBuff(const char* BuffName)
	{
		auto hashn = fnv::hash_runtime(BuffName);
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == hashn)
				return true;
		}
		return false;
	}

	int BuffCount(const char* BuffName)
	{
		auto hashn = fnv::hash_runtime(BuffName);
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == hashn)
				return buff.count;
		}
		return 0;
	}


	////// FNVHASH FUNCTION /////
	CBuffEntry* GetBuffEntryByName(fnv::hash BuffHash)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == BuffHash)
				return buff.buffentry;
		}
		return nullptr;
	}

	bool HasBuff(fnv::hash BuffHash)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == BuffHash)
				return true;
		}
		return false;
	}

	int BuffCount(unsigned int BuffHash)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.buffhash == BuffHash)
				return buff.count;
		}
		return 0;
	}

	int BuffCount(fnv::hash BuffHash)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.namehash == BuffHash)
				return buff.count;
		}
		return 0;
	}

	bool HasBuffType(BuffType Type)
	{
		for (auto buff : this->Buffs())
		{
			if (buff.type == Type)
				return true;
		}
		return false;
	}
	bool HasBuffType(std::vector<BuffType> offsets) {
		for (auto buff : this->Buffs())
		{
			for (auto type : offsets)
			{
				if (buff.type == type)
					return true;
			}
		}

		return false;
	}

	bool HasBuff(std::vector<fnv::hash> offsets) {
		for (auto buff : this->Buffs())
		{
			for (auto namehash : offsets)
			{
				if (buff.namehash == namehash)
					return true;
			}
		}

		return false;
	}

	//bool isPartOf(const char* w1, const char* w2)
	//{
	//	int i = 0;
	//	int j = 0;


	//	while (w1[i] != '\0') {
	//		if (w1[i] == w2[j])
	//		{
	//			int init = i;
	//			while (w1[i] == w2[j] && w2[j] != '\0')
	//			{
	//				j++;
	//				i++;
	//			}
	//			if (w2[j] == '\0') {
	//				return true;
	//			}
	//			j = 0;
	//		}
	//		i++;
	//	}
	//	return false;
	//}

	//bool IsInvunerable() {
	//	if (this->HasBuffType(BuffType::Invulnerability)) {
	//		return true;
	//	}
	//	return false;
	//}

	//bool IsSlow() {
	//	int i = -1;
	//	for (DWORD pBuffPtr = this->pStart(); pBuffPtr != this->pEnd(); pBuffPtr += 0x8)
	//	{
	//		auto pBuff = (CBuffEntry*)pBuffPtr;
	//		i++;
	//		if (!pBuff) continue;
	//		if (!pBuff->IsValid()) continue;
	//		if (pBuff->IsAlive()) {
	//			if (isPartOf(pBuff->GetBuffName().c_str(), "low")) //slow
	//				return true;
	//		}

	//	}
	//	return false;
	//}

	//bool IsPoisoned() {
	//	int i = -1;
	//	for (DWORD pBuffPtr = this->pStart(); pBuffPtr != this->pEnd(); pBuffPtr += 0x8)
	//	{
	//		auto pBuff = (CBuffEntry*)pBuffPtr;
	//		i++;
	//		if (!pBuff) continue;
	//		if (!pBuff->IsValid()) continue;
	//		if (pBuff->IsAlive()) {
	//			if (isPartOf(pBuff->GetBuffName().c_str(), "grounded")) //oison
	//				return true;
	//		}

	//	}
	//	return false;
	//}

	bool IsImmobile()
	{
		for (auto buff : this->Buffs())
		{
			std::vector<BuffType>::iterator it;

			it = std::find(CCBuffs.begin(), CCBuffs.end(), buff.type);
			if (it != CCBuffs.end())
			{
				return true;
			}
		}
		return false;
	}

	float GetImmobileDuration()
	{
		for (auto buff : this->Buffs())
		{
			std::vector<BuffType>::iterator it;

			it = std::find(CCBuffs.begin(), CCBuffs.end(), buff.type);
			if (it != CCBuffs.end())
			{
				if (buff.count > 0 && buff.remaintime >= 0 && buff.remaintime <= 5)
					return buff.remaintime;
			}
		}
		return -1;
	}

};