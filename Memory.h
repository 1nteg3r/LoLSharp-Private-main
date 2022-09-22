#pragma once
#include <Psapi.h> 
#include <TlHelp32.h> 

unsigned long TargetProcessID = 0;
unsigned long LocalProcessID = 0;
uint32_t m_Base = 0;

#ifdef USERMODE
extern "C" NTSTATUS ZwRVM(HANDLE hProcess, void* lpBaseAddress, void* lpBuffer, SIZE_T nSize, SIZE_T* lpNumberOfBytesRead = NULL);
extern "C" NTSTATUS ZwWVM(HANDLE hProcess, void* lpBaseAddress, void* lpBuffer, SIZE_T nSize, SIZE_T* lpNumberOfBytesRead = NULL);
extern "C" NTSTATUS ZwOpenProcessz(
	OUT PHANDLE ProcessHandle,
	IN ACCESS_MASK DesiredAccess,
	IN POBJECT_ATTRIBUTES ObjectAttributes,
	IN PCLIENT_ID ClientId OPTIONAL);

HANDLE NewOpenProcess(unsigned long pid,HWND www)
{
	if (usesyscallmem)
	{
		CLIENT_ID pid = { };
		if (GetWindowThreadProcessId(www, (PDWORD)&pid.UniqueProcess))
		{
			HANDLE handle;
			static OBJECT_ATTRIBUTES zoa = { sizeof(zoa) };
			if (0 <= ZwOpenProcessz(&handle,
				PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE,
				&zoa, &pid))
			{
				return handle;
			}
		}
	}
	else
	{
		return OpenProcess(PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE, 0, pid);
	}
}

class CMem
{
public:
	CMem() : hProcess(nullptr), hModule(nullptr), lpBase(nullptr)
	{

	}
	CMem(HANDLE hProc) : hProcess(hProc), hModule(nullptr), lpBase(nullptr)
	{
		HMODULE hMods[512];
		DWORD cb;
		DWORD flag;
		if (EnumProcessModulesEx(hProc, hMods, sizeof(hMods), &cb, LIST_MODULES_ALL))
		{
			char szModName[MAX_PATH] = { NULL };
			for (int i = 0; i < cb / sizeof(HMODULE); i++)
			{
				if (GetModuleBaseNameA(hProc, hMods[i], szModName, MAX_PATH))
				{
					//if (!strcmp(szModName, "League of Legends.exe"))
					{
						//std::cout << hMods[i] << " : " << szModName << std::endl;
						lpBase = hMods[i];
						//::cout << "Base Address: 0x" << (DWORD64)lpBase << std::endl;
						break;
					}
				}
				ZeroMemory(szModName, MAX_PATH);
			}
		}
	}

	DWORD GetBase()
	{
		return (DWORD)lpBase;
	}

	HANDLE GetHandle()
	{
		return hProcess;
	}

	void Close()
	{
		CloseHandle(hProcess);
	}

	HANDLE hProcess;
	HMODULE hModule;
	LPVOID lpBase;
};
CMem* mem;

template <typename T>
bool WPM(const void* address, T Buffer)
{
	if (usesyscallmem)
		return NT_SUCCESS(ZwWVM(mem->hProcess, (LPVOID)address, &Buffer, sizeof(T), NULL));
	else
		return NT_SUCCESS(WriteProcessMemory(mem->hProcess, (LPVOID)address, &Buffer, sizeof(T), NULL));
}

template <typename T>
bool WPM(unsigned long long Address, T Buffer)
{
	if (usesyscallmem)
		return NT_SUCCESS(ZwWVM(mem->hProcess, (LPVOID)Address, &Buffer, sizeof(T), NULL));
	else
		return NT_SUCCESS(WriteProcessMemory(mem->hProcess, (LPVOID)Address, &Buffer, sizeof(T), NULL));
}

template <typename Type>
Type RPM(const void* address)
{
	if (!address)
		return Type();

	Type buffer;
	if (usesyscallmem)
		return NT_SUCCESS(ZwRVM(mem->hProcess, (LPVOID)address, &buffer, sizeof(Type), NULL)) ? buffer : Type();
	else
		return NT_SUCCESS(ReadProcessMemory(mem->hProcess, (LPVOID)address, &buffer, sizeof(Type), NULL)) ? buffer : Type();

};



template <typename Type>
Type RPM(const DWORD64 address)
{
	if (!address)
		return Type();

	Type buffer;
	if (usesyscallmem)
		return NT_SUCCESS(ZwRVM(mem->hProcess, (LPVOID)address, &buffer, sizeof(Type), NULL)) ? buffer : Type();
	else
		return NT_SUCCESS(ReadProcessMemory(mem->hProcess, (LPVOID)address, &buffer, sizeof(Type), NULL)) ? buffer : Type();
};

uint32_t ReadChain(uint32_t base, const std::vector<uint32_t>& offsets) {
	uint32_t result = RPM<uint32_t>(base + offsets.at(0));
	if (!result)
		return 0;

	for (int i = 1; i < offsets.size(); i++) {
		result = RPM<uint32_t>(result + offsets.at(i));
		if (!result)
			return 0;
	}
	return result;
}

BOOLEAN ReadVirtualMemory(void * Address, void* Buffer, const DWORD Size) {

	if (!TargetProcessID || !Address || !Buffer || !Size)
		return false;

	if (usesyscallmem)
		return NT_SUCCESS(ZwRVM(mem->hProcess, Address, Buffer, Size, NULL)) ? true : false;
	else
		return NT_SUCCESS(ReadProcessMemory(mem->hProcess, Address, Buffer, Size, NULL)) ? true : false;
}

#define INRANGE(x,a,b)(x >= a && x <= b) 
#define getBits( x )(INRANGE((x&(~0x20)),'A','F') ? ((x&(~0x20)) - 'A' + 0xA) : (INRANGE(x,'0','9') ? x - '0' : 0))
#define getByte( x )(getBits(x[0]) << 4 | getBits(x[1]))

ULONG64 FindPattern(const char* pattern, ULONG64 start, ULONG64 end)
{
	char* pat = const_cast<char*>(pattern);
	int64_t firstMatch = 0;
	for (auto pCur = start; pCur < end; pCur++)   //10000000 - 30000000
	{
		//printf("%d\n", pCur);
		if (!*pat)
			return firstMatch;
		BYTE pCur2 = RPM<BYTE>(pCur);
		if (*(BYTE*)pat == '\?' || pCur2 == getByte(pat))
		{
			//printf("Match: %x \n", pCur2);
			if (!firstMatch)
				firstMatch = pCur;
			if (!pat[2])
				return firstMatch;
			if (*(BYTE*)pat == '\?')
				pat += 2;
			else
				pat += 3;
		}
		else
		{
			pat = const_cast<char*>(pattern);
			firstMatch = 0;
		}
	}
	return 0;
}

#endif

#ifdef KERNELMODE
static HANDLE PortHandle = nullptr;
static MYAPI_MESSAGE ConnectionMessage = { 0 };
static PMYAPI_CONNECTINFO ConnectionInfo = &ConnectionMessage.ConnectionInfo;
static UCHAR MessageAttributesBuffer[sizeof(ALPC_MESSAGE_ATTRIBUTES) + sizeof(ALPC_DATA_VIEW_ATTR)] = { 0 };
static PALPC_MESSAGE_ATTRIBUTES SendMessageAttributes = reinterpret_cast<PALPC_MESSAGE_ATTRIBUTES>(MessageAttributesBuffer);

namespace DirectInput
{

	auto Initialize()
		->HRESULT;

	auto SendInput(UINT32 aCount, LPINPUT aInputs, UINT32 aBytes)
		->UINT;
}

FORCEINLINE
VOID
InitializeApiMessageLengths(
	_Inout_ PMYAPI_MESSAGE Message,
	_In_ SIZE_T TotalMessageLength
)
{
	// Wow64 uses 64 bit types everywhere but here
	const SHORT DataLength = static_cast<SHORT>(TotalMessageLength - sizeof(PORT_MESSAGE) + (Lpc6432 ? sizeof(LPC_CLIENT_ID) : 0));
	Message->Header.u1.s1.TotalLength = static_cast<SHORT>(TotalMessageLength);
	Message->Header.u1.s1.DataLength = DataLength;
}

NTSTATUS
Connect(
	_In_ PUNICODE_STRING ServerPortName,
	_Out_ PHANDLE ClientPortHandle
)
{
	//wprintf(L"Connecting to ALPC server %wZ...\n", ServerPortName);

	SECURITY_QUALITY_OF_SERVICE SecurityQoS;
	SecurityQoS.Length = sizeof(SecurityQoS);
	SecurityQoS.ImpersonationLevel = SecurityImpersonation; // Allow local impersonation
	SecurityQoS.ContextTrackingMode = SECURITY_DYNAMIC_TRACKING; // Lowest overhead
	SecurityQoS.EffectiveOnly = TRUE; // Forbid acquiring of any additional privileges in our security context

	ALPC_PORT_ATTRIBUTES PortAttributes = { 0 };
	PortAttributes.Flags = ALPC_PORFLG_CAN_IMPERSONATE;
	PortAttributes.MaxMessageLength = sizeof(MYAPI_MESSAGE);
	PortAttributes.SecurityQos = SecurityQoS;

	const SIZE_T TotalMessageSize = sizeof(MYAPI_MESSAGE);
	InitializeApiMessageLengths(&ConnectionMessage, TotalMessageSize);

	const NTSTATUS Status = NtAlpcConnectPort(ClientPortHandle,
		ServerPortName,
		nullptr,
		&PortAttributes,
		ALPC_MSGFLG_SYNC_REQUEST,
		nullptr,
		&ConnectionMessage.Header,
		nullptr,
		nullptr,
		nullptr,
		nullptr);

	if (Status == STATUS_PORT_CONNECTION_REFUSED)
	{
		//ExitProcess(0);
		std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
		wprintf(L"Connection refused.\n");
		system("pause");
	}
	else if (!NT_SUCCESS(Status))
	{
		//ExitProcess(0);
		std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
		WCHAR Buffer[512];
		wprintf(L"ConnectPort failed:\n\t%ls", Buffer);
		system("pause");
	}
	else
	{
		std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
		wprintf(textonce(L"Successful. Server\n"));//, // Successful. Server PID: %u
			//static_cast<ULONG>(reinterpret_cast<ULONG_PTR>(ConnectionInfo->ServerProcessId)));
	}
	return Status;
}
namespace DirectInput
{
	//////////////////////////////////////////////////////////////////////////
	struct SendInputArgs
	{
		UINT32  InputCount;
		UINT32  InputBytes;
		UINT64  Inputs;
	};

	//////////////////////////////////////////////////////////////////////////

	auto Initialize()
		->HRESULT
	{
		return E_NOTIMPL;
	}

	static auto SendInputCode(UINT32 aInputCount, LPINPUT aInputs, UINT32 aInputBytes)
		-> UINT
	{

		MYAPI_MESSAGE RequestMessage;
		RtlZeroMemory(&RequestMessage.Header, sizeof(PORT_MESSAGE)); // Always zero the LPC header to prevent rejection by the kernel
		SIZE_T MessageSize;

		PSendInputArgs Request = &RequestMessage.Data.SendInputArgs;
		//RtlZeroMemory(&Request->TargetPID, sizeof(Request->TargetPID));
		Request->InputCount = aInputCount;
		Request->InputBytes = aInputBytes;
		Request->Inputs = (UINT64)aInputs;

		MessageSize = sizeof(*Request);

		// Set the request API number and the initial status
		RequestMessage.ApiNumber = MYAPI_API_NUMBER::SendInput;
		RequestMessage.MagicCommunicate = 0x10111998;
		RequestMessage.Status = STATUS_UNSUCCESSFUL;

		// Fill out the LPC port message header
		const SIZE_T TotalMessageSize = FIELD_OFFSET(MYAPI_MESSAGE, Data) + MessageSize;
		InitializeApiMessageLengths(&RequestMessage, TotalMessageSize);

		// Send the request
		NTSTATUS Status = NtAlpcSendWaitReceivePort(PortHandle,
			ALPC_MSGFLG_SYNC_REQUEST,
			&RequestMessage.Header,
			nullptr, // The attributes are not set because we only use them for views
			&RequestMessage.Header,
			nullptr,
			nullptr,
			nullptr);

		if (!NT_SUCCESS(Status)) // LPC request failure
		{
			if (IS_DISCONNECT_STATUS(Status))
			{
				ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
			}
		}
		else if (!NT_SUCCESS(RequestMessage.Status)) // Server responded with an error status
		{
			Status = RequestMessage.Status;
			ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
		}

		return true;
	}

	auto SendInput(UINT32 aInputCount, LPINPUT aInputs, UINT32 aInputBytes)
		-> UINT
	{
		for (auto i = 0u; i < aInputCount; ++i)
		{
			auto& vInput = aInputs[i];
			if (INPUT_KEYBOARD == vInput.type)
			{
				if (KEYEVENTF_SCANCODE & vInput.ki.dwFlags)
				{
					break;
				}

				vInput.ki.wScan = MapVirtualKey(vInput.ki.wVk, MAPVK_VK_TO_VSC);
				vInput.ki.dwFlags |= KEYEVENTF_SCANCODE;

				switch (vInput.ki.wVk)
				{
				case VK_INSERT:
				case VK_DELETE:
				case VK_HOME:
				case VK_END:
				case VK_PRIOR:	//Page Up
				case VK_NEXT:	//Page Down

				case VK_LEFT:
				case VK_UP:
				case VK_RIGHT:
				case VK_DOWN:

				case VK_DIVIDE:

				case VK_LWIN:
				case VK_RCONTROL:
				case VK_RWIN:
				case VK_RMENU:	//ALT
					vInput.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
					break;
				}
			}
		}

		return SendInputCode(aInputCount, aInputs, aInputBytes);
	}
}

bool WriteVirtualMemory(void * TargetAddress, void* LocalBuffer, unsigned long Size)
{
	MYAPI_MESSAGE RequestMessage;
	RtlZeroMemory(&RequestMessage.Header, sizeof(PORT_MESSAGE)); // Always zero the LPC header to prevent rejection by the kernel
	SIZE_T MessageSize;

	PMemoryInteractionRequest Request = &RequestMessage.Data.MemoryInteractionRequest;

	//RtlZeroMemory(&Request->LocalBuffer, Size);
	Request->LocalBuffer = LocalBuffer;
	Request->TargetBuffer = TargetAddress;
	Request->InteractionSize = Size;

	Request->TargetPID = TargetProcessID;
	Request->LocalPID = LocalProcessID;
	MessageSize = sizeof(*Request);

	// Set the request API number and the initial status
	RequestMessage.ApiNumber = MYAPI_API_NUMBER::WriteRequest;
	RequestMessage.MagicCommunicate = 0x10111998;
	RequestMessage.Status = STATUS_UNSUCCESSFUL;

	// Fill out the LPC port message header
	const SIZE_T TotalMessageSize = FIELD_OFFSET(MYAPI_MESSAGE, Data) + MessageSize;
	InitializeApiMessageLengths(&RequestMessage, TotalMessageSize);

	// Send the request
	NTSTATUS Status = NtAlpcSendWaitReceivePort(PortHandle,
		ALPC_MSGFLG_SYNC_REQUEST,
		&RequestMessage.Header,
		nullptr, // The attributes are not set because we only use them for views
		&RequestMessage.Header,
		nullptr,
		nullptr,
		nullptr);

	if (!NT_SUCCESS(Status)) // LPC request failure
	{
		if (IS_DISCONNECT_STATUS(Status))
		{
			ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
		}
	}
	else if (!NT_SUCCESS(RequestMessage.Status)) // Server responded with an error status
	{
		Status = RequestMessage.Status;
		ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
	}

	return true;
}

bool ReadVirtualMemory(void * TargetAddress, void* LocalBuffer, unsigned long Size)
{
	MYAPI_MESSAGE RequestMessage;
	RtlZeroMemory(&RequestMessage.Header, sizeof(PORT_MESSAGE)); // Always zero the LPC header to prevent rejection by the kernel
	SIZE_T MessageSize;

	PMemoryInteractionRequest Request = &RequestMessage.Data.MemoryInteractionRequest;

	//RtlZeroMemory(&Request->LocalBuffer, Size);
	Request->LocalBuffer = LocalBuffer;
	Request->TargetBuffer = TargetAddress;
	Request->InteractionSize = Size;

	Request->TargetPID = TargetProcessID;
	Request->LocalPID = LocalProcessID;
	MessageSize = sizeof(*Request);

	// Set the request API number and the initial status
	RequestMessage.ApiNumber = MYAPI_API_NUMBER::ReadRequest;
	RequestMessage.MagicCommunicate = 0x10111998;
	RequestMessage.Status = STATUS_UNSUCCESSFUL;

	// Fill out the LPC port message header
	const SIZE_T TotalMessageSize = FIELD_OFFSET(MYAPI_MESSAGE, Data) + MessageSize;
	InitializeApiMessageLengths(&RequestMessage, TotalMessageSize);

	// Send the request
	NTSTATUS Status = NtAlpcSendWaitReceivePort(PortHandle,
		ALPC_MSGFLG_SYNC_REQUEST,
		&RequestMessage.Header,
		nullptr, // The attributes are not set because we only use them for views
		&RequestMessage.Header,
		nullptr,
		nullptr,
		nullptr);

	if (!NT_SUCCESS(Status)) // LPC request failure
	{
		if (IS_DISCONNECT_STATUS(Status))
		{
			return false;// ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
		}
	}
	else if (!NT_SUCCESS(RequestMessage.Status)) // Server responded with an error status
	{
		Status = RequestMessage.Status;
		return false;//ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
	}

	return true;
}

ModuleRequest GetBase()
{
	MYAPI_MESSAGE RequestMessage;
	RtlZeroMemory(&RequestMessage.Header, sizeof(PORT_MESSAGE)); // Always zero the LPC header to prevent rejection by the kernel
	SIZE_T MessageSize;

	PModuleRequest Request = &RequestMessage.Data.ModuleRequest;
	//RtlZeroMemory(&Request->TargetPID, sizeof(Request->TargetPID));
	Request->TargetPID = TargetProcessID;

	MessageSize = sizeof(*Request);

	// Set the request API number and the initial status
	RequestMessage.ApiNumber = MYAPI_API_NUMBER::BaseAddressRequest;
	RequestMessage.MagicCommunicate = 0x10111998;
	RequestMessage.Status = STATUS_UNSUCCESSFUL;

	// Fill out the LPC port message header
	const SIZE_T TotalMessageSize = FIELD_OFFSET(MYAPI_MESSAGE, Data) + MessageSize;
	InitializeApiMessageLengths(&RequestMessage, TotalMessageSize);

	// Send the request
	NTSTATUS Status = NtAlpcSendWaitReceivePort(PortHandle,
		ALPC_MSGFLG_SYNC_REQUEST,
		&RequestMessage.Header,
		nullptr, // The attributes are not set because we only use them for views
		&RequestMessage.Header,
		nullptr,
		nullptr,
		nullptr);

	if (!NT_SUCCESS(Status)) // LPC request failure
	{
		if (IS_DISCONNECT_STATUS(Status))
		{
			ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
		}
	}
	else if (!NT_SUCCESS(RequestMessage.Status)) // Server responded with an error status
	{
		Status = RequestMessage.Status;
		ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
	}

	return *Request;
}

ModuleRequest GetModule(const wchar_t * ModuleName)
{
	MYAPI_MESSAGE RequestMessage;
	RtlZeroMemory(&RequestMessage.Header, sizeof(PORT_MESSAGE)); // Always zero the LPC header to prevent rejection by the kernel
	SIZE_T MessageSize;

	PModuleRequest Request = &RequestMessage.Data.ModuleRequest;
	//RtlZeroMemory(&Request->TargetPID, sizeof(Request->TargetPID));
	memcpy(Request->ModuleName, ModuleName, wcslen(ModuleName) * sizeof(ModuleName[0]));
	Request->TargetPID = TargetProcessID;

	MessageSize = sizeof(*Request);

	// Set the request API number and the initial status
	RequestMessage.ApiNumber = MYAPI_API_NUMBER::ModuleRequest;
	RequestMessage.MagicCommunicate = 0x10111998;
	RequestMessage.Status = STATUS_UNSUCCESSFUL;

	// Fill out the LPC port message header
	const SIZE_T TotalMessageSize = FIELD_OFFSET(MYAPI_MESSAGE, Data) + MessageSize;
	InitializeApiMessageLengths(&RequestMessage, TotalMessageSize);

	// Send the request
	NTSTATUS Status = NtAlpcSendWaitReceivePort(PortHandle,
		ALPC_MSGFLG_SYNC_REQUEST,
		&RequestMessage.Header,
		nullptr, // The attributes are not set because we only use them for views
		&RequestMessage.Header,
		nullptr,
		nullptr,
		nullptr);

	if (!NT_SUCCESS(Status)) // LPC request failure
	{
		if (IS_DISCONNECT_STATUS(Status))
		{
			ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
		}
	}
	else if (!NT_SUCCESS(RequestMessage.Status)) // Server responded with an error status
	{
		Status = RequestMessage.Status;
		ExitProcess(0); // If the port is null, the disconnect was by us (CTRL+C)
	}

	return *Request;
}

template <typename Type>
Type RPM(const DWORD64 address)
{
	if (!address)
		return Type();

	Type buffer;
	ReadVirtualMemory((void*)address, &buffer, sizeof(Type));
	return buffer;
};

template <typename Type>
Type RPM(void* address)
{
	if (!address)
		return Type();

	Type buffer;
	ReadVirtualMemory(address, &buffer, sizeof(Type));
	return buffer;
};

template <typename T>
unsigned long WPM(unsigned long long Address, T Buffer)
{
	return WriteVirtualMemory((void*)Address, &Buffer, sizeof(T));
	return 0;
}
#endif

#ifdef KERNELHOOK
void* m_driver_control;			// driver control function
enum E_COMMAND_CODE
{
	ID_NULL = 0,	//
	ID_READ_PROCESS_MEMORY = 5,	// 
	ID_READ_KERNEL_MEMORY = 6,	// 
	ID_WRITE_PROCESS_MEMORY = 7,	//
	ID_GET_PROCESS = 10,	//
	ID_GET_PROCESS_BASE = 11,	//
	ID_GET_PROCESS_MODULE = 12,	//
	ID_CLEARPIDDB = 13	//

	//..
};

typedef struct _MEMORY_STRUCT
{
	uint64_t	process_id;
	void*		address;
	uint64_t	size;
	uint64_t	size_copied;
	void*		buffer;
	uint64_t	struct_value;
} MEMORY_STRUCT, *PMEMORY_STRUCT;
void* kernel_control_function()
{
	HMODULE hModule = LoadLibraryW(L"win32u.dll");

	if (!hModule)
		return nullptr;

	return reinterpret_cast<void*>(GetProcAddress(hModule, "NtQueryCompositionSurfaceStatistics"));
}
template<typename ... A>
uint64_t call_driver_control(void* control_function, const A ... arguments)
{
	if (!control_function)
		return 0;

	using tFunction = uint64_t(__stdcall*)(A...);
	const auto control = static_cast<tFunction>(control_function);

	return control(arguments ...);
}
__forceinline BOOLEAN KeRtlCopyMemory(const DWORD64 Address, const PVOID Buffer, const DWORD_PTR Size, const BOOLEAN Write) {

	if (!TargetProcessID || !Address || !Buffer || !Size)
		return false;

	E_COMMAND_CODE ioctl;

	if (Write)
		ioctl = E_COMMAND_CODE::ID_WRITE_PROCESS_MEMORY;
	else
		ioctl = E_COMMAND_CODE::ID_READ_PROCESS_MEMORY;

	MEMORY_STRUCT memory_struct = { 0 };
	memory_struct.process_id = TargetProcessID;
	memory_struct.address = reinterpret_cast<void*>(Address);
	memory_struct.size = Size;
	memory_struct.buffer = Buffer;

	return (call_driver_control(m_driver_control, ioctl, &memory_struct)) == 0 ? true : false;
}

template <typename Type>
Type RPM(const void* address)
{
	if (!address)
		return Type();

	Type buffer;
	return KeRtlCopyMemory((DWORD64)address, &buffer, sizeof(Type), FALSE) ? buffer : Type();
};

template <typename Type>
Type RPM(const DWORD64 address)
{
	if (!address)
		return Type();

	Type buffer;
	return KeRtlCopyMemory(address, &buffer, sizeof(Type), FALSE) ? buffer : Type();
};

template <class Type>
void write(const DWORD64 address, Type data)
{
	if (!address)
		return;

	KeRtlCopyMemory(address, &data, sizeof(Type), TRUE);
};

BOOLEAN ReadVirtualMemory(void * Address, void* Buffer, const DWORD_PTR Size) {

	if (!TargetProcessID || !Address || !Buffer || !Size)
		return false;

	return KeRtlCopyMemory((DWORD64)Address, Buffer, Size, FALSE);
}

#endif