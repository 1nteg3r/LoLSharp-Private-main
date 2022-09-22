#pragma once

/*
 * Example dummy API
 */

 // Name of the ALPC port
//static UNICODE_STRING PortName = RTL_CONSTANT_STRING(L"\\RPC Control\\RXC7XY3D-73PT-ZW4I-FSWY-Z69IGB0HKJQY");

#define RTL_MAX_DRIVE_LETTERS 32

// Possible API request message numbers
enum class MYAPI_API_NUMBER : ULONG
{
	ReadRequest,
	WriteRequest,
	ModuleRequest,
	BaseAddressRequest,
	TestComm,
	SendInput,
	MyApiMaximumNumber,
	MyApiUnloadDriverNumber // Request to unload the driver. Not part of the API proper
};

typedef struct _MemoryInteractionRequest
{
	unsigned long long TargetPID; // IN
	unsigned long long LocalPID; // IN

	void * LocalBuffer; // IN
	void * TargetBuffer; // IN
	unsigned long InteractionSize; // IN OUT

} MemoryInteractionRequest, *PMemoryInteractionRequest;

typedef struct _ModuleRequest
{
	unsigned long TargetPID; // IN
	void * ModuleBase; // OUT
	wchar_t ModuleName[200]; // IN
} ModuleRequest, *PModuleRequest;

typedef struct _UPCASE_STRING_MESSAGE
{
	unsigned long TargetPID; // IN
	void * Value; // IN
	void * TargetBuffer; // IN
	unsigned long InteractionSize; // IN OUT
} UPCASE_STRING_MESSAGE, *PUPCASE_STRING_MESSAGE;

typedef struct _MULTIPLY_NUMBERS_MESSAGE
{
	ULONG X;
	ULONG Y;
	ULONG Result;
} MULTIPLY_NUMBERS_MESSAGE, *PMULTIPLY_NUMBERS_MESSAGE;

typedef struct _LONG_RUNNING_COMPUTATION_MESSAGE
{
	ULONG AmountOfTimeToWork;
} LONG_RUNNING_COMPUTATION_MESSAGE, *PLONG_RUNNING_COMPUTATION_MESSAGE;

typedef struct _SendInputArgs
{
	UINT32  InputCount;
	UINT32  InputBytes;
	UINT64  Inputs;
} SendInputArgs, *PSendInputArgs;

// Connection info received after server accepts connection
typedef struct _MYAPI_CONNECTINFO
{
	HANDLE ServerProcessId;
} MYAPI_CONNECTINFO, *PMYAPI_CONNECTINFO;

// Complete API message struct
typedef struct _MYAPI_MESSAGE
{
	PORT_MESSAGE Header;
	union
	{
		MYAPI_CONNECTINFO ConnectionInfo;
		struct
		{
			MYAPI_API_NUMBER ApiNumber;
			unsigned long long MagicCommunicate;
			NTSTATUS Status;
			union
			{
				UPCASE_STRING_MESSAGE UpcaseStringMessage;
				MemoryInteractionRequest MemoryInteractionRequest;
				ModuleRequest ModuleRequest;
				SendInputArgs SendInputArgs;
			} Data;
		};
	};
} MYAPI_MESSAGE, *PMYAPI_MESSAGE;

static_assert(sizeof(MYAPI_MESSAGE) <= PORT_TOTAL_MAXIMUM_MESSAGE_LENGTH, "Maximum ALPC");
