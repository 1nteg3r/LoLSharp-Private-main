#pragma once
#include <exception>
#include "Memory.h"
#define MAKE_DATA(TYPE, NAME, OFFSET) inline TYPE NAME() { \
return (RPM<TYPE>(this + OFFSET)); } \

#define MAKE_DATA2(TYPE, NAME, OFFSET) inline TYPE NAME() { \
return (TYPE)RPM<TYPE>(RPM<uint32_t>(this) + OFFSET); } \

#define MAKE_ASE_DATA(TYPE, NAME, OFFSET) inline TYPE NAME() { \
return (RPM<TYPE>((DWORD)this + OFFSET)); } \

#define MAKE_PTR(TYPE, NAME, OFFSET) inline TYPE NAME() { \
return (TYPE)(this + OFFSET); } \

#define STR_MERGE_IMPL(x, y)				x##y
#define STR_MERGE(x,y)						STR_MERGE_IMPL(x,y)
#define MAKE_PAD(size)						BYTE STR_MERGE(pad_, __COUNTER__) [ size ]

#define DEFINE_MEMBER_0(x, y)				x
#define DEFINE_MEMBER_N(x,offset)			struct { MAKE_PAD(offset); x; }

#define DECLARE_ENUM(enames, ename, ...) \
	namespace enames { \
		enum ename { __VA_ARGS__, COUNT }; \
		static const ename All[] = {__VA_ARGS__}; \
		static std::string _Strings[COUNT]; \
		static const char* ToString(ename e) { \
			if (_Strings[0].empty()) { SplitEnumArgs((#__VA_ARGS__), _Strings, COUNT); } \
			return _Strings[e].c_str(); \
		} \
		static ename FromString(const std::string& strEnum) { \
			if (_Strings[0].empty()) { SplitEnumArgs((#__VA_ARGS__), _Strings, COUNT); } \
			for (int i = 0; i < COUNT; i++) { if (_Strings[i] == strEnum) { return (ename)i; } } \
			return COUNT; \
		} \
	}

static bool IsValid(uint64_t ptr)
{
	if (ptr && ptr > 0x00010000 && ptr < 0x7FFEFFFF && ptr != NULL)
		return true;

	return false;
}

bool replace(std::string& str, const std::string& from, const std::string& to) {
	size_t start_pos = str.find(from);
	if (start_pos == std::string::npos)
		return false;
	str.replace(start_pos, from.length(), to);
	return true;
}

std::string ToLower(std::string str)
{
	std::string strLower;
	strLower.resize(str.size());

	std::transform(str.begin(),
		str.end(),
		strLower.begin(),
		::tolower);

	return strLower;
}

bool ContainsOnlyASCII(const char* buff, int maxSize) {
	for (int i = 0; i < maxSize; ++i) {
		/*if (buff[i] == 0)
			return true;*/
		if (static_cast<unsigned char>(buff[i]) > 127)
			return false;
	}
	return true;
}

/* It is necessary to specify alignment the packing to 4 bytes */
#pragma pack( push, 4 )
/* Obfuscated value type */
template<class Type = DWORD>
class Obfuscation
{
public:
	unsigned char IsFilled;
	unsigned char LengthXor32;
	unsigned char LengthXor8;
	Type Key;
	unsigned char Index;
	Type Values[4];
public:
	inline operator Type()
	{
		Type Result = sizeof(Type) == 1 ? this->Values[(this->Index + 1) & 3] : this->Values[this->Index];
		if (this->LengthXor32)
		{
			for (unsigned char i = 0; i < this->LengthXor32; i++)
			{
				reinterpret_cast<PDWORD>(&Result)[i] ^= ~(reinterpret_cast<PDWORD>(&this->Key)[i]);
			}
		}
		if (this->LengthXor8)
		{
			for (unsigned char i = sizeof(Type) - this->LengthXor8; i < sizeof(Type); i++)
			{
				reinterpret_cast<PBYTE>(&Result)[i] ^= ~(reinterpret_cast<PBYTE>(&this->Key)[i]);
			}
		}
		return Result;
	}
};
#pragma pack( pop )

struct LeagueObfuscationFloat
{
	bool isInit;
	unsigned char xorCount32;
	unsigned char xorCount8;
	float xorKey;
	unsigned char valueIndex;
	float valueTable[4];
};
struct LeagueObfuscationBool
{
	bool isInit;
	unsigned char xorCount32;
	unsigned char xorCount8;
	bool xorKey;
	unsigned char valueIndex;
	bool valueTable[4];
};
struct LeagueObfuscationDword
{
	bool isInit;
	unsigned char xorCount32;
	unsigned char xorCount8;
	DWORD xorKey;
	unsigned char valueIndex;
	DWORD valueTable[4];
};

inline float decrypt_float(LeagueObfuscationFloat data)
{
	if (data.isInit)
	{

		if (data.xorCount8 != 0)
			if (data.xorCount8 > sizeof(float) || data.xorCount8 < 0)
				return 0.f;

		if (data.xorCount32 != 0)
			if (data.xorCount32 > sizeof(float) || data.xorCount32 < 0)
				return 0.f;

		auto tXoredValue = data.valueTable[data.valueIndex];
		auto tXorKeyValue = data.xorKey;
		if (data.xorCount32)
		{
			auto tXorValuePtr = reinterpret_cast<uint32_t*>(&tXorKeyValue);
			for (auto i = 0; i < data.xorCount32; i++)
				*(reinterpret_cast<uint32_t*>(&tXoredValue) + i) ^= ~tXorValuePtr[i];
		}
		if (data.xorCount8)
		{
			auto tXorValuePtr = reinterpret_cast<unsigned char*>(&tXorKeyValue);
			for (auto i = sizeof(float) - data.xorCount8; i < sizeof(float); ++i)
				*(reinterpret_cast<unsigned char*>(&tXoredValue) + i) ^= ~tXorValuePtr[i];
		}
		return tXoredValue;
	}
	return 0.f;
}

inline bool decrypt_bool(LeagueObfuscationBool data)
{
	if (data.isInit)
	{

		if (data.xorCount8 != 0)
			if (data.xorCount8 > sizeof(bool) || data.xorCount8 < 0)
				return false;

		if (data.xorCount32 != 0)
			if (data.xorCount32 > sizeof(bool) || data.xorCount32 < 0)
				return false;

		auto tXoredValue = data.valueTable[data.valueIndex];
		auto tXorKeyValue = data.xorKey;
		if (data.xorCount32)
		{
			auto tXorValuePtr = reinterpret_cast<uint32_t*>(&tXorKeyValue);
			for (auto i = 0; i < data.xorCount32; i++)
				*(reinterpret_cast<uint32_t*>(&tXoredValue) + i) ^= ~tXorValuePtr[i];
		}
		if (data.xorCount8)
		{
			auto tXorValuePtr = reinterpret_cast<unsigned char*>(&tXorKeyValue);
			for (auto i = sizeof(bool) - data.xorCount8; i < sizeof(bool); ++i)
				*(reinterpret_cast<unsigned char*>(&tXoredValue) + i) ^= ~tXorValuePtr[i];
		}
		return tXoredValue;
	}
	return false;
}

inline DWORD decrypt_dword(LeagueObfuscationDword data)
{
	if (data.isInit)
	{

		if (data.xorCount8 != 0)
			if (data.xorCount8 > sizeof(DWORD) || data.xorCount8 < 0)
				return 0x0;

		if (data.xorCount32 != 0)
			if (data.xorCount32 > sizeof(DWORD) || data.xorCount32 < 0)
				return 0x0;

		auto tXoredValue = data.valueTable[data.valueIndex];
		auto tXorKeyValue = data.xorKey;
		if (data.xorCount32)
		{
			auto tXorValuePtr = reinterpret_cast<uint32_t*>(&tXorKeyValue);
			for (auto i = 0; i < data.xorCount32; i++)
				*(reinterpret_cast<uint32_t*>(&tXoredValue) + i) ^= ~tXorValuePtr[i];
		}
		if (data.xorCount8)
		{
			auto tXorValuePtr = reinterpret_cast<unsigned char*>(&tXorKeyValue);
			for (auto i = sizeof(DWORD) - data.xorCount8; i < sizeof(DWORD); ++i)
				*(reinterpret_cast<unsigned char*>(&tXoredValue) + i) ^= ~tXorValuePtr[i];
		}
		return tXoredValue;
	}
	return 0x0;
}

//template<typename T = int>
//inline T decrypt(LeagueObfuscation<T> data)
//{
//	if (!data.isInit)
//		return T(); //throw std::exception("Obfuscation data not initialized!");
//
//	if (data.xorCount8 != 0)
//		if (data.xorCount8 > sizeof(T) || data.xorCount8 < 0)
//			return T(); //throw std::exception("Obfuscation data corrupted!");
//
//	if (data.xorCount32 != 0)
//		if (data.xorCount32 > sizeof(T) || data.xorCount32 < 0)
//			return T(); //throw std::exception("Obfuscation data corrupted!");
//
//	if ((int)data.valueIndex > 4)
//		return T(); //throw std::exception("Obfuscation data corrupted!");
//
//	auto tXoredValue = data.valueTable[data.valueIndex];
//	auto tXorKeyValue = data.xorKey;
//	if (data.xorCount32)
//	{
//		auto tXorValuePtr = reinterpret_cast<uint32_t*>(&tXorKeyValue);
//		for (auto i = 0; i < data.xorCount32; i++)
//			*(reinterpret_cast<uint32_t*>(&tXoredValue) + i) ^= ~tXorValuePtr[i];
//	}
//	if (data.xorCount8)
//	{
//		auto tXorValuePtr = reinterpret_cast<unsigned char*>(&tXorKeyValue);
//		for (auto i = sizeof(T) - data.xorCount8; i < sizeof(T); ++i)
//			*(reinterpret_cast<unsigned char*>(&tXoredValue) + i) ^= ~tXorValuePtr[i];
//	}
//	return T();
//}