#pragma once

template<class T> __int8 __SETS__(T x)
{
	if (sizeof(T) == 1)
		return __int8(x) < 0;
	if (sizeof(T) == 2)
		return __int16(x) < 0;
	if (sizeof(T) == 4)
		return __int32(x) < 0;
	return __int64(x) < 0;
}

template<class T, class U> __int8 __OFSUB__(T x, U y)
{
	if (sizeof(T) < sizeof(U))
	{
		U x2 = x;
		__int8 sx = __SETS__(x2);
		return (sx ^ __SETS__(y)) & (sx ^ __SETS__(x2 - y));
	}
	else
	{
		T y2 = y;
		__int8 sx = __SETS__(x);
		return (sx ^ __SETS__(y2)) & (sx ^ __SETS__(x - y2));
	}
}
