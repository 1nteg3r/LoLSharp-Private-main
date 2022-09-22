#pragma once

#ifndef _KERNEL_MODE
#ifndef _WIN64
#define USE_LPC6432 // Assume a 64 bit OS
#endif
#include <ntdll.h>
#include <ntstatus.h>
#endif
#include <ntlpcapi.h>

#if defined(__cplusplus) && \
	((defined(_MSC_VER) && (_MSC_VER >= 1900)) || defined(__clang__))
#define CONSTEXPR constexpr
#else
#define CONSTEXPR
#endif

#if defined(__RESHARPER__) || defined(__GNUC__)
#define PRINTF_ATTR(FormatIndex, FirstToCheck) \
	[[gnu::format(printf, FormatIndex, FirstToCheck)]]
#else
#define PRINTF_ATTR(FormatIndex, FirstToCheck)
#endif

#if defined(__RESHARPER__)
#define WPRINTF_ATTR(FormatIndex, FirstToCheck) \
	[[rscpp::format(wprintf, FormatIndex, FirstToCheck)]]
#else
#define WPRINTF_ATTR(FormatIndex, FirstToCheck)
#endif

#define IS_DISCONNECT_STATUS(s) (NT_ERROR(s) && \
	((s) == STATUS_PORT_CLOSED || (s) == STATUS_PORT_DISCONNECTED || (s) == STATUS_INVALID_HANDLE || \
	(s) == STATUS_LPC_REPLY_LOST || (s) == STATUS_MESSAGE_LOST))

#ifdef USE_LPC6432
CONSTEXPR BOOLEAN Lpc6432 = TRUE;
#else
CONSTEXPR BOOLEAN Lpc6432 = FALSE;
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Utility functions
FORCEINLINE
ULONG
RtlNtMajorVersion(
	)
{
	return SharedUserData->NtMajorVersion;
}

FORCEINLINE
ULONG
RtlNtMinorVersion(
	)
{
	return SharedUserData->NtMinorVersion;
}

CONSTEXPR
FORCEINLINE
BOOLEAN
IsWin64(
	)
{
#ifdef _WIN64
	return TRUE;
#else
	return FALSE;
#endif
}

CONSTEXPR
FORCEINLINE
LONGLONG
RtlMsToTicks(
	_In_ ULONG Milliseconds
	)
{
	return 10000LL * (LONGLONG)Milliseconds;
}

FORCEINLINE
VOID
RtlSleep(
	_In_ ULONG Milliseconds
	)
{
	LARGE_INTEGER Timeout;
	Timeout.QuadPart = -1 * RtlMsToTicks(Milliseconds);
#ifndef _KERNEL_MODE
	NtDelayExecution(FALSE, &Timeout);
#else
	KeDelayExecutionThread(KernelMode, FALSE, &Timeout);
#endif
}

#ifndef _KERNEL_MODE
// Ntdll string functions, not in ntdll.h as they are incompatible with the CRT
typedef const WCHAR *LPCWCHAR, *PCWCHAR;

NTSYSAPI
int
__cdecl
_snwprintf(
	_Out_ PWCHAR Buffer,
	_In_ size_t BufferCount,
	_In_ PCWCHAR Format,
	...
);

NTSYSAPI
int
__cdecl
_vsnwprintf(
	_Out_ PWCHAR Buffer,
	_In_ size_t BufferCount,
	_In_ PCWCHAR Format,
	_In_ va_list ArgList
);

// Console functions
inline
VOID
WaitForKey(
	)
{
	const HANDLE StdIn = NtCurrentPeb()->ProcessParameters->StandardInput;
	INPUT_RECORD InputRecord = { 0 };
	ULONG NumRead;
	while (InputRecord.EventType != KEY_EVENT || !InputRecord.Event.KeyEvent.bKeyDown || InputRecord.Event.KeyEvent.dwControlKeyState !=
		(InputRecord.Event.KeyEvent.dwControlKeyState & ~(RIGHT_CTRL_PRESSED | LEFT_CTRL_PRESSED)))
	{
		ReadConsoleInputW(StdIn, &InputRecord, 1, &NumRead);
	}
}
#else
PRINTF_ATTR(1, 2)
VOID
Printf(
	_In_ PCCH Format,
	...
	);
#endif

#ifdef NT_ANALYSIS_ASSUME
// wdm.h's asserts are incompatible with both clang and MS's own analyzer
#undef NT_ANALYSIS_ASSUME
#undef NT_ASSERT_ACTION
#undef NT_ASSERTMSG_ACTION
#undef NT_ASSERTMSGW_ACTION
#undef NT_ASSERT_ASSUME
#undef NT_ASSERTMSG_ASSUME
#undef NT_ASSERTMSGW_ASSUME
#undef NT_ASSERT
#undef NT_ASSERTMSG
#undef NT_ASSERTMSGW
#endif

#ifdef _PREFAST_
#define NT_ANALYSIS_ASSUME
_Analysis_assume_(__VA_ARGS__)
#elif defined(_DEBUG) || defined(DBG)
#define NT_ANALYSIS_ASSUME(...) ((void) 0)
#else
#define NT_ANALYSIS_ASSUME(...) __noop(__VA_ARGS__)
#endif

#if !defined(__clang__)
#if !defined(DbgRaiseAssertionFailure)
#define DbgRaiseAssertionFailure() __int2c()
#endif

#define NT_ASSERT_ACTION(_exp) \
	((!(_exp)) ? \
		(__annotation((PWCHAR)L"Debug", L"AssertFail", L#_exp), \
			DbgRaiseAssertionFailure(), FALSE) : \
		TRUE)

#define NT_ASSERTMSG_ACTION(_msg, _exp) \
	((!(_exp)) ? \
		(__annotation((PWCHAR)L"Debug", L"AssertFail", L##_msg), \
			DbgRaiseAssertionFailure(), FALSE) : \
		TRUE)

#define NT_ASSERTMSGW_ACTION(_msg, _exp) \
	((!(_exp)) ? \
		(__annotation((PWCHAR)L"Debug", L"AssertFail", _msg), \
			DbgRaiseAssertionFailure(), FALSE) : \
		TRUE)
#else
#define NT_ASSERT_ACTION(_exp) \
	((!(_exp)) ? (__debugbreak(), FALSE) : TRUE)
#define NT_ASSERTMSG_ACTION(_msg, _exp) \
	NT_ASSERT_ACTION(_exp)
#define NT_ASSERTMSGW_ACTION(_msg, _exp) \
	NT_ASSERT_ACTION(_exp)
#endif

#if defined(_DEBUG) || defined(DBG)
#define NT_ASSERT_ASSUME(_exp) \
	(NT_ANALYSIS_ASSUME(_exp), NT_ASSERT_ACTION(_exp))

#define NT_ASSERTMSG_ASSUME(_msg, _exp) \
	(NT_ANALYSIS_ASSUME(_exp), NT_ASSERTMSG_ACTION(_msg, _exp))

#define NT_ASSERTMSGW_ASSUME(_msg, _exp) \
	(NT_ANALYSIS_ASSUME(_exp), NT_ASSERTMSGW_ACTION(_msg, _exp))

#define NT_ASSERT					NT_ASSERT_ASSUME
#define NT_ASSERTMSG				NT_ASSERTMSG_ASSUME
#define NT_ASSERTMSGW				NT_ASSERTMSGW_ASSUME
#else
#define NT_ASSERT(_exp)				((void) 0)
#define NT_ASSERTMSG(_msg, _exp)	((void) 0)
#define NT_ASSERTMSGW(_msg, _exp)	((void) 0)
#endif

#ifdef __cplusplus
}
#endif
