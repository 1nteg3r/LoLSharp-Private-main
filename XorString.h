#pragma once
#ifndef _xorstring_
#define _xorstring_
#include <array>

template <int X> struct EnsureCompileTime {
	enum : int {
		Value = X
	};
};
////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////
//Use Compile-Time as seed
#define Seed ((__TIME__[7] - '0') * 1  + (__TIME__[6] - '0') * 10  + \
                  (__TIME__[4] - '0') * 60   + (__TIME__[3] - '0') * 600 + \
                  (__TIME__[1] - '0') * 3600 + (__TIME__[0] - '0') * 36000)
////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////
constexpr int LinearCongruentGenerator(int Rounds) {
	return 1013904223 + 1664525 * ((Rounds > 0) ? LinearCongruentGenerator(Rounds - 1) : Seed & 0xFFFFFFFF);
}
#define Random() EnsureCompileTime<LinearCongruentGenerator(10)>::Value //10 Rounds
#define RandomNumber(Min, Max) (Min + (Random() % (Max - Min + 1)))
////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////
template <int... Pack> struct IndexList {};
////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////
template <typename IndexList, int Right> struct Append;
template <int... Left, int Right> struct Append<IndexList<Left...>, Right> {
	typedef IndexList<Left..., Right> Result;
};
////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////
template <int N> struct ConstructIndexList {
	typedef typename Append<typename ConstructIndexList<N - 1>::Result, N - 1>::Result Result;
};
template <> struct ConstructIndexList<0> {
	typedef IndexList<> Result;
};
////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////
const char XORKEY = static_cast<char>(RandomNumber(0, 0xFF));

template <typename T, size_t N>
class XorString {
private:
	std::array<T, N> encrypted;

	template<size_t i>
	constexpr __forceinline T enc(const T c, int index) const {
		return c ^ char(XORKEY + index);
	}

	__forceinline T dec(const T c, const size_t i) const {
		return c ^ char(XORKEY + i);
	}
public:
	template <size_t... index>
	constexpr __forceinline XorString(const T(&str)[N], std::index_sequence<index...>) :
		encrypted{ enc<index>(str[index], index) ... }
	{

	}

	T* decrypt() {
		for (size_t i = 0; i < N; ++i)
			encrypted[i] = dec(encrypted[i], i);
		return encrypted.data();
	};

};

#define get_type(t) std::remove_const<std::remove_reference<decltype(t)>::type>::type

#define str_length(s) sizeof(s) / sizeof(get_type(s[0]))

#define textonce(s) \
(XorString<get_type(s[0]), str_length(s)>(s, std::make_index_sequence<str_length(s)>() ).decrypt())

// Helper function that converts a character to lowercase on compile time
constexpr char charToLower(const char c) {
	return (c >= 'A' && c <= 'Z') ? c + ('a' - 'A') : c;
} 

namespace detail {
	template <typename Type, Type OffsetBasis, Type Prime>
	struct size_dependant_data {
		using type = Type;
		constexpr static auto k_offset_basis = OffsetBasis;
		constexpr static auto k_prime = Prime;
	};

	template <size_t Bits>
	struct size_selector;

	template <>
	struct size_selector<32> {
		using type = size_dependant_data<std::uint32_t, 0x811c9dc5ul, 16777619ul>;
	};

	template <>
	struct size_selector<64> {
		using type = size_dependant_data<std::uint64_t, 0xcbf29ce484222325ull, 1099511628211ull>;
	};

	// Implements FNV-1a hash algorithm
	template <std::size_t Size>
	class fnv_hash {
	private:
		using data_t = typename size_selector<Size>::type;

	public:
		using hash = typename data_t::type;

	private:
		constexpr static auto k_offset_basis = data_t::k_offset_basis;
		constexpr static auto k_prime = data_t::k_prime;

	public:
		template <std::size_t N>
		static __forceinline constexpr auto hash_constexpr(const char(&str)[N], const std::size_t size = N) -> hash {
			return static_cast<hash>(1ull * (size == 1
				? (k_offset_basis ^ charToLower(str[0]))
				: (hash_constexpr(str, size - 1) ^ charToLower(str[size - 1]))) * k_prime);
		}

		static auto __forceinline hash_runtime(const char* str) -> hash {
			auto result = k_offset_basis;
			do {
				result ^= charToLower(*str++);
				result *= k_prime;
			} while (*(str - 1) != '\0');

			return result;
		}
	};
}

using fnv = ::detail::fnv_hash<sizeof(void*) * 8>;

#define FNV(str) (std::integral_constant<fnv::hash, fnv::hash_constexpr(str)>::value)
#endif 
