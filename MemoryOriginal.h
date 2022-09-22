#pragma once
unsigned long TargetProcessID = 0;
unsigned long LocalProcessID = 0;
uint32_t m_Base = 0;

#ifdef USERMODE

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
					std::cout << szModName << std::endl;
					if (!strcmp(szModName, "League of Legends.exe"))
					{
						std::cout << hMods[i] << " : " << szModName << std::endl;
						lpBase = hMods[i];
						std::cout << "Base Address: 0x" << (DWORD64)lpBase << std::endl;
						break;
					}
				}
				ZeroMemory(szModName, MAX_PATH);
			}
		}
	}

	DWORD_PTR GetBase()
	{
		return (DWORD_PTR)lpBase;
	}

	HANDLE GetHandle()
	{
		return hProcess;
	}
	template<typename T> T RPM(LPCVOID address)
	{
		T buff;
		/*if (!ReadProcessMemory(hProcess, (LPCVOID)address, &buff, bufSize, NULL))
			std::cout << "Error reading: " << GetLastError() << std::endl;*/
		ReadProcessMemory(hProcess, (LPCVOID)address, &buff, sizeof(T), NULL);
		return buff;
	}
	template<typename T> T RPM(SIZE_T address)
	{
		T buff;
		/*if (!ReadProcessMemory(hProcess, (LPCVOID)address, &buff, bufSize, NULL))
			std::cout << "Error reading: " << GetLastError() << std::endl;*/
		ReadProcessMemory(hProcess, (LPCVOID)address, &buff, sizeof(T), NULL);
		return buff;
	}
	template<typename T> T RPM(SIZE_T address, DWORD bufSize)
	{
		T buff;
		/*if (!ReadProcessMemory(hProcess, (LPCVOID)address, &buff, bufSize, NULL))
			std::cout << "Error reading: " << GetLastError() << std::endl;*/
		ReadProcessMemory(hProcess, (LPCVOID)address, &buff, bufSize, NULL);
		return buff;
	}

	BOOL RPMWSTR(SIZE_T address, wchar_t* buff, DWORD bufSize)
	{
		return ReadProcessMemory(hProcess, (LPCVOID)address, buff, bufSize, NULL);
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

template <typename Type>
Type RPM(const void* address)
{
	if (!address)
		return Type();

	Type buffer;
	return ReadProcessMemory(mem->hProcess, (LPCVOID)address, &buffer, sizeof(Type), NULL) ? buffer : Type();
};

template <typename Type>
Type RPM(const DWORD64 address)
{
	if (!address)
		return Type();

	Type buffer;
	return ReadProcessMemory(mem->hProcess, (LPCVOID)address, &buffer, sizeof(Type), NULL) ? buffer : Type();
};

BOOLEAN ReadVirtualMemory(void * Address, const PVOID Buffer, const DWORD_PTR Size) {

	if (!TargetProcessID || !Address || !Buffer || !Size)
		return false;

	return ReadProcessMemory(mem->hProcess, (LPCVOID)Address, Buffer, Size, NULL) ? true : false;
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
		ExitProcess(0);
		//wprintf(L"Connection refused.\n");
	}
	else if (!NT_SUCCESS(Status))
	{
		ExitProcess(0);
		//WCHAR Buffer[512];
		//wprintf(L"NtAlpcConnectPort failed:\n\t%ls", Buffer);
	}
	else
	{
		wprintf(textonce(L"Successful. Server PID: %u\n"),
			static_cast<ULONG>(reinterpret_cast<ULONG_PTR>(ConnectionInfo->ServerProcessId)));
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
Type RPM(const void* address)
{
	if (!address)
		return Type();

	Type buffer;
	ReadVirtualMemory((void*)address, &buffer, sizeof(Type));
	return buffer;
};

template <typename T>
unsigned long WPM(unsigned long long Address, T Buffer)
{
	return WriteVirtualMemory((void*)Address, &Buffer, sizeof(T));
	return 0;
}
#endif

//bool SendDriverMouse(DWORD Flags, int x, int y) {
//
//	INPUT Input{ 0 };
//	Input.type = INPUT_MOUSE;
//	Input.mi.mouseData = 0;
//	Input.mi.time = 0;
//	Input.mi.dx = x;
//	Input.mi.dy = y;
//	Input.mi.dwFlags = Flags;
//
//	return DirectInput::SendInput(1, &Input, sizeof(INPUT));
//}