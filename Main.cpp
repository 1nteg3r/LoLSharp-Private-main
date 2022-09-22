#define SELFUSE 
//#define NEWSYSTEM
//#include <crtdbg.h> 
//#include "tinyformat.h"
#define USERMODE // USERMODE || KERNELMODE || KERNELHOOK
#define CREATEWINDOW //NVIDIAHIJACK | CREATEWINDOW
#define NOMINMAX
#define JSON_NOEXCEPTION


#include <openssl/aes.h>
#include <WS2tcpip.h>
#include <Windows.h>
//#include <winternl.h>
#include <global.h>
#include <math.h>
#include <TlHelp32.h>
#include <functional>
#include <stdint.h>


#include <string>
#include <map>
#include <random>
#include <vector>
#include <memory>
//#define D3D_DEBUG_INFO
#include <d3d9.h>
#include <d3dx9.h>
#include <Dwmapi.h> 
#include <TlHelp32.h>
#include <dinput.h>
#include <iostream>
#include <iomanip>
#include <algorithm>
#include <initializer_list>
#include <list>
#include <functional>
#include <set>
#include <dinput.h>

#include <future>
#include <list>
#include <map>
#include <queue>
#include <deque>
#include <regex>
#include "Vector2.h"
#include "Vector3.h"

#include <sstream>	
#include <aclapi.h>
#include <Shlwapi.h>
#include "XorString.h"
#include <chrono>
#include "IDA.h"
#include "ImGui/imgui.h"
#include "ImGui/imgui_impl_dx9.h"
#include "ImGui/imgui_impl_win32.h"
#include "ImGui/imgui_internal.h"
#include "InputSystem.h"

#include <thread>
#include <fstream>
#include <tchar.h>
#include "Offsets.h"
#include "clipper.hpp"
#include "Renderer.h"

#include <cctype>
#include "VMProtectSDK.h"
#include "d3dfunction.h"

#include "md5.h"
#include "json.hpp"

#include "Anim.h"
#ifdef KERNELMODE
#include <myapi.h>
#endif
#include "cpplinq.h"
using namespace cpplinq;
#include "colorwin.h"
#include "Menu.h"
#include "HudManager.h"
#include "MenuSettings.h"
#include "Keyboard.h"
//#include "linq/linq.h"
#include "CPULimit.h"

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "libcrypto.lib")

#pragma comment(lib, "ws2_32.lib")
#undef MIN
#undef MAX
bool usespoofsendinput = false;
bool usesyscallmem = false;
Offsets_Garena offsets_lol;
HWND in_foreground(HWND HWNDD);
Vector3 walk_position = Vector3::Zero;
int keytime = 0;
int server_tick = GetTickCount() & INT_MAX;

PSECURITY_DESCRIPTOR GetFileSecurityX(LPCSTR filePath, SECURITY_INFORMATION access, DWORD* len = NULL) {

	PSECURITY_DESCRIPTOR security = NULL;
	DWORD security_len = 0;

	// get security_len
	GetFileSecurityA(filePath, access, NULL, 0, &security_len);
	if (security_len == 0) return NULL;

	if (len) *len = security_len;
	security = (PSECURITY_DESCRIPTOR)malloc(security_len);

	if (GetFileSecurityA(filePath, access, security, security_len, &security_len))
		return security;

	free(security);
	return NULL;
}

PSID GetAccountSID(LPCWSTR name) {

	PSID sidPtr = NULL;
	SID_NAME_USE sidUse;
	wchar_t domainbuf[4096];
	DWORD bufSize = 4096, sidSize = 0;

	LookupAccountNameW(NULL, name, NULL, &sidSize, domainbuf, &bufSize, &sidUse);
	if (sidSize == 0) return NULL;

	sidPtr = (PSID)malloc(sidSize);

	if (LookupAccountNameW(NULL, name, sidPtr, &sidSize, domainbuf, &bufSize, &sidUse))
		return sidPtr;

	free(sidPtr);
	return NULL;
}

int SetPrivilege(HANDLE token, const char* privilege, int enable)
{
	TOKEN_PRIVILEGES tp;
	LUID luid;

	if (!LookupPrivilegeValueA(NULL, privilege, &luid)) return 0;

	tp.PrivilegeCount = 1;
	tp.Privileges[0].Luid = luid;
	if (enable) tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
	else tp.Privileges[0].Attributes = 0;

	// Enable the privilege or disable all privileges.
	return AdjustTokenPrivileges(token, 0, &tp, NULL, NULL, NULL);
}

bool SetSePrivilege() {

	HANDLE token;
	if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, &token))
		return false;

	SetPrivilege(token, textonce("SeTakeOwnershipPrivilege"), 1);
	SetPrivilege(token, textonce("SeSecurityPrivilege"), 1);
	SetPrivilege(token, textonce("SeBackupPrivilege"), 1);
	SetPrivilege(token, textonce("SeRestorePrivilege"), 1);
	return true;
}

bool SetTrustedInstallerSecurity(LPCSTR filePath) {
	static PSECURITY_DESCRIPTOR TrustedInstallerSecurity = NULL;

	// copy the TrustedInstaller security from System32\kernel32.dll to target file
	if (TrustedInstallerSecurity == NULL) {

		char kernel32Path[4096];
		GetSystemDirectoryA(kernel32Path, sizeof(kernel32Path) / sizeof(wchar_t));
		PathAppendA(kernel32Path, textonce("kernel32.dll"));

		TrustedInstallerSecurity = GetFileSecurityX(kernel32Path, OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION);
		if (TrustedInstallerSecurity == NULL) return false;
	}


	return SetFileSecurityA(filePath, OWNER_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION, TrustedInstallerSecurity);
}


bool RevokeTrustedInstallerSecurity(LPCSTR filePath) {

	DWORD security_len = 0;
	PSECURITY_DESCRIPTOR oldSecurity = GetFileSecurityX(filePath, DACL_SECURITY_INFORMATION, &security_len);

	if (oldSecurity == NULL) {
		return false;
	}

	// initialize a new security
	PSECURITY_DESCRIPTOR newSecurity = (PSECURITY_DESCRIPTOR)malloc(security_len);
	if (newSecurity == NULL) {
		return false;
	}

	InitializeSecurityDescriptor(newSecurity, SECURITY_DESCRIPTOR_REVISION);

	// get administrator SID
	static PSID AdministratorSID = NULL;
	if (AdministratorSID == NULL) {
		wchar_t wcUsername[4096];
		DWORD usernameSize = 4096;
		GetUserNameW(wcUsername, &usernameSize);

		if ((AdministratorSID = GetAccountSID(wcUsername)) == NULL)
		{
			return false;
		}
	}


	// set security owner to Administrator
	if (!SetSecurityDescriptorOwner(newSecurity, AdministratorSID, false)) {
		return false;
	}
	if (!SetFileSecurityA(filePath, OWNER_SECURITY_INFORMATION, newSecurity)) {
		return false;
	}


	PACL pOldDACL = NULL, pNewDACL = NULL;
	BOOL bDaclPresent = false, bDaclDefaulted = false;

	if (!GetSecurityDescriptorDacl(oldSecurity, &bDaclPresent, &pOldDACL, &bDaclDefaulted))
	{
		return false;
	}



	// loop through all ACL and change permission to Full Access
	ULONG entries_size = pOldDACL->AceCount;
	PEXPLICIT_ACCESSW pListEntries = NULL;
	if (GetExplicitEntriesFromAclW(pOldDACL, &entries_size, &pListEntries) == 0) {
		for (int i = 0; i < entries_size; i++) {
			pListEntries[i].grfAccessPermissions = STANDARD_RIGHTS_ALL | FILE_ALL_ACCESS;

			if (SetEntriesInAclW(1, &pListEntries[i], pOldDACL, &pNewDACL) != 0)
			{
				return false;
			}

			pOldDACL = pNewDACL;
		}
	}

	if (!SetSecurityDescriptorDacl(newSecurity, true, pNewDACL, false))
	{
		return false;
	}

	return SetFileSecurityA(filePath, DACL_SECURITY_INFORMATION, newSecurity);
}


// Structure used to communicate data from and to enumeration procedure
struct EnumData {
	DWORD dwProcessId;
	HWND hWnd;
};

// Application-defined callback for EnumWindows
BOOL CALLBACK EnumProc(HWND hWnd, LPARAM lParam) {
	// Retrieve storage location for communication data
	EnumData& ed = *(EnumData*)lParam;
	DWORD dwProcessId = 0x0;
	// Query process ID for hWnd
	GetWindowThreadProcessId(hWnd, &dwProcessId);
	// Apply filter - if you want to implement additional restrictions,
	// this is the place to do so.
	if (ed.dwProcessId == dwProcessId) {
		// Found a window matching the process ID
		ed.hWnd = hWnd;
		// Report success
		SetLastError(ERROR_SUCCESS);
		// Stop enumeration
		return FALSE;
	}
	// Continue enumeration
	return TRUE;
}


// Main entry
HWND FindWindowFromProcessId(DWORD dwProcessId) {
	EnumData ed = { dwProcessId };
	if (!EnumWindows(EnumProc, (LPARAM)&ed) &&
		(GetLastError() == ERROR_SUCCESS)) {
		return ed.hWnd;
	}
	return NULL;
}

// Helper method for convenience
HWND FindWindowFromProcess(HANDLE hProcess) {
	return FindWindowFromProcessId(GetProcessId(hProcess));
}

HWND in_foreground(HWND HWNDD)
{
	auto hwvip = GetForegroundWindow();

	return (hwvip == HWNDD) ? hwvip : 0;
}

HWND GetLoLWindow()
{
	return FindWindow(L"RiotWindowClass", NULL);
}


#ifdef NEWSYSTEM
#include "TCPS/TCPS.h"
using namespace TCPS;
enum LoaderCommand
{
	cmdTest,
	cmdLoggingError,
	cmdLoggingWarning,
	cmdLoggingInfo,
	cmdHandshake,
	cmdLogin,
	cmdCheckSelfUpdate,
	cmdCheckHackUpdate,
	cmdCookie,

};
enum class LoginResultCode : int
{
	ZERO = 0,
	OK = 200,
	SERVER_INTERNAL_ERROR = 500,
	SERVER_INVALID_RESPONSE = 503,
	SERVER_REQUEST_ERROR = 504,
	INVALID_LOGIN = 403,
	KEY_EXPIRED = 404,
	CLIENT_ERROR = 405,
};

struct LoginData
{
	LoginResultCode code;
	int timeLeft;
	int timeStart;
	int timeExpire;
	char cookie[40];
	LoginData()
	{
		ZeroMemory(this, sizeof(LoginData));
	}
	LoginData(LoginResultCode _code, int _timeLeft, int _timeStart, int _timeExpire)
	{
		code = _code;
		timeLeft = _timeLeft;
		timeStart = _timeStart;
		timeExpire = _timeExpire;
	}
};

void tryConnect(Client* client)
{
	ExitProcess(0);
	/*while (client->connect(5000) != NWSTATUS::OK)
	{

	}*/
}

#endif


std::string s2hex(const std::string& s)
{
	std::ostringstream string;

	unsigned int deci;
	for (std::string::size_type i = 0; i < s.length(); ++i)
	{
		deci = (unsigned int)(unsigned char)s[i];
		string << std::hex << deci;
	}
	return string.str();
}

static const std::string base64_chars =
"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
"abcdefghijklmnopqrstuvwxyz"
"0123456789+/";


static inline bool is_base64(unsigned char c) {
	return (isalnum(c) || (c == '+') || (c == '/'));
}
std::string base64_encode(unsigned char const* bytes_to_encode, unsigned int in_len) {
	std::string ret;
	int i = 0;
	int j = 0;
	unsigned char char_array_3[3];
	unsigned char char_array_4[4];

	while (in_len--) {
		char_array_3[i++] = *(bytes_to_encode++);
		if (i == 3) {
			char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
			char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
			char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
			char_array_4[3] = char_array_3[2] & 0x3f;

			for (i = 0; (i < 4); i++)
				ret += base64_chars[char_array_4[i]];
			i = 0;
		}
	}

	if (i)
	{
		for (j = i; j < 3; j++)
			char_array_3[j] = '\0';

		char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
		char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
		char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
		char_array_4[3] = char_array_3[2] & 0x3f;

		for (j = 0; (j < i + 1); j++)
			ret += base64_chars[char_array_4[j]];

		while ((i++ < 3))
			ret += '=';

	}

	return ret;

}
std::string base64_decode(std::string const& encoded_string) {
	int in_len = encoded_string.size();
	int i = 0;
	int j = 0;
	int in_ = 0;
	unsigned char char_array_4[4], char_array_3[3];
	std::string ret;

	while (in_len-- && (encoded_string[in_] != '=') && is_base64(encoded_string[in_])) {
		char_array_4[i++] = encoded_string[in_]; in_++;
		if (i == 4) {
			for (i = 0; i < 4; i++)
				char_array_4[i] = base64_chars.find(char_array_4[i]);

			char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
			char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
			char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

			for (i = 0; (i < 3); i++)
				ret += char_array_3[i];
			i = 0;
		}
	}

	if (i) {
		for (j = i; j < 4; j++)
			char_array_4[j] = 0;

		for (j = 0; j < 4; j++)
			char_array_4[j] = base64_chars.find(char_array_4[j]);

		char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
		char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
		char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

		for (j = 0; (j < i - 1); j++) ret += char_array_3[j];
	}

	return ret;
}

// Decrypt using AES cbc
std::string AESDecrypt(const unsigned char* apBuffer, size_t aBufferSize, const unsigned char* apKey, size_t aKeySize, unsigned char* apIV)
{
	// Read IVector.

	// Create Key.

	AES_KEY DecryptKey;
	AES_set_decrypt_key(apKey, 128, &DecryptKey);

	// Decrypt.
	unsigned char AES_Decrypted[1024] = { 0 };
	AES_cbc_encrypt(apBuffer, AES_Decrypted, aBufferSize, &DecryptKey, apIV, AES_DECRYPT);
	const std::string Decrypted(reinterpret_cast<const char*>(AES_Decrypted));

	// Finish.
	return Decrypted;
};

void decrypt(unsigned char* buf, size_t length, const AES_KEY* const dec_key, const unsigned char* iv)
{
	unsigned char local_vector[AES_BLOCK_SIZE];
	CopyMemory(local_vector, iv, AES_BLOCK_SIZE);

	AES_cbc_encrypt(buf, buf, length, dec_key, local_vector, AES_DECRYPT);
}

std::string random_string(std::size_t length)
{
	const std::string characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

	std::random_device random_device;
	std::mt19937 generator(random_device());
	std::uniform_int_distribution<> distribution(0, characters.size() - 1);

	std::string random_string;

	for (std::size_t i = 0; i < length; ++i)
	{
		random_string += characters[distribution(generator)];
	}

	return random_string;
}


LONG WINAPI SimplestCrashHandler(EXCEPTION_POINTERS* ExceptionInfo)
{

	std::cout << "[!!] Crash at addr 0x" << ExceptionInfo->ExceptionRecord->ExceptionAddress << " by 0x" << std::hex << ExceptionInfo->ExceptionRecord->ExceptionCode << std::endl;

	return EXCEPTION_EXECUTE_HANDLER;
}


std::string time_in_HH_MM_SS()
{

	// get current time
	auto now = std::chrono::system_clock::now();

	// get number of milliseconds for the current second
	// (remainder after division into seconds)
	auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;

	// convert to std::time_t in order to convert to std::tm (broken time)
	auto timer = std::chrono::system_clock::to_time_t(now);

	// convert to broken time
	std::tm bt = *std::localtime(&timer);

	std::ostringstream oss;
	oss << "[";
	oss << std::put_time(&bt, "%H:%M:%S"); // HH:MM:SS
	oss << textonce("  - YTS++]: ");
	return oss.str();
}

#include "Memory.h"
#include "DelayAction.h"
bool freeTrial = false;
DelayAction* _DelayAction;

#define M_PI	3.14159265358979323846264338327950288419716939937510
#define M_PI2	1.57079632679489661923
#define HR(x) (x)

#define TICKS_DIFF(prev, cur) ((cur) >= (prev)) ? ((cur)-(prev)) : ((0xFFFFFFFF-(prev))+1+(cur))


float MathRad(float deg) {
	return static_cast<float>(deg * M_PI / 180.0f);
}
float MathDeg(float rad) {
	return static_cast<float>(rad * (180.0f / M_PI));
}
int Diffx = 0, Diffy = 0;


HANDLE serverthread;

HWND hWnd;
HWND hWndTar;

InputSystem* g_pInputSystem = new InputSystem();

MARGINS margin = { -1 };

char keynum[1024];
char lolname[1024];
char serialnum[1024];
bool hActivated = false;

#include "lol_reclass.h"

#define _Q 0
#define _W 1
#define _E 2
#define _R 3
#define _D 4
#define _F 5

struct worldtoscreen
{
	D3DXMATRIX viewmatrix;
	D3DXMATRIX projmatrix;
};


namespace global
{
	std::mutex mt;
	//Server server(12345);
	PVOID lolHandle = 0;
	bool mousereset = true;
	bool blockOrbAttack = false;
	bool blockOrbMove = false;
	int resetmosuetick = 0;
	int tickIndex = 0;
	int ping = 0;
	uint64_t entityloop = 0;
	uint64_t orbwalkloop = 0;
	uint64_t renderloop = 0;
	float orbtick = 0;
	float drawtick = 0;
	ScriptMode mode = ScriptMode::None;
	std::vector<actor_struct> enemyheros;
	std::vector<actor_struct> allyheros;
	std::vector<actor_struct> heros;
	std::vector<uint32_t> turrets;
	std::vector<uint32_t> inhi;
	std::vector<uint32_t> objecttests;
	std::vector<ward_struct> wards;
	std::vector<missle_struct> missiles;
	std::vector<missle_struct> missilesDraw;
	std::vector<ward_struct> traps;
	std::vector<jungletimer_struct> jungletimer;
	std::vector<uint32_t> campobject;
	std::vector<uint32_t> barrels;
	std::vector<uint32_t> troyobjects;
	std::unordered_map<fnv::hash, std::vector<BuffCustomCache>> BuffCache = {};
	std::set<int> blacklistedObjects;
	std::map<std::string, UnitInfo*> Units = {};
	uint32_t Objmanager = 0;
	uint32_t ChampionManager = 0;
	uint32_t MinionManager = 0;
	uint32_t Attackable_Unit = 0;
	uint32_t AIBases = 0;
	uint32_t TurretList = 0;
	uint32_t localPlayer = 0;
	uint32_t RendererAddr = 0;
	uint32_t MinimapAddr = 0;
	bool _missileLaunched = false;
	float qdmg = 0;
	float wdmg = 0;
	float edmg = 0;
	float rdmg = 0;
	float pdmg = 0;
	float aadmg = 0;
	float ignitedmg = 0;
	worldtoscreen Matrix;

	std::string LocalChampName;
	fnv::hash LocalChampNameHash;
	UnitInfo* LocalData;

	bool blockmouse = false;


	void setOrbTick()
	{
		std::unique_lock<std::mutex> lck(global::mt);
		global::orbtick = RPM<float>(m_Base + offsets_lol.oGameTime);
	}

	float getOrbTick()
	{
		std::unique_lock<std::mutex> lck(global::mt);
		return global::orbtick;
	}

	void setDrawTick()
	{
		std::unique_lock<std::mutex> lck(global::mt);
		global::drawtick = RPM<float>(m_Base + offsets_lol.oGameTime);
	}

	float getDrawTick()
	{
		std::unique_lock<std::mutex> lck(global::mt);
		return global::drawtick;
	}
}




#include "CObject.h"

struct Barrel
{
	CObject* Bottle = nullptr;
	int CreationTime = 0;
};

struct WindWall
{
	float time = 0;
	Vector2 StartPos = Vector2::Zero;
	Vector2 Pos = Vector2::Zero;
	Vector2 Direction = Vector2::Zero;
	float Level = 0;
};

namespace Cache
{
	std::vector<uint32_t> ObjectListMinion;
	std::vector<Barrel> Barrels;
	WindWall windwall;

	bool ObjectCacheContains(std::vector<uint32_t> list, DWORD actorcheck)
	{
		bool skip = false;
		if ((list.size() > 0) && (list.size() != 0))
		{
			for (int i = 0; i < list.size();)
			{
				auto Actor = list[i];

				if ((DWORD)Actor == actorcheck)
				{
					skip = true;
					break;
				}
				i++;
			}
		}

		return skip;
	}
}

template <class T, class I >
bool vectorContains(const std::vector<T>& v, I& t)
{
	bool found = (std::find(v.begin(), v.end(), t) != v.end());
	return found;
}

bool BarrelsCacheContains(std::vector<Barrel> list, uint32_t actorcheck)
{
	bool skip = false;
	if ((list.size() > 0) && (list.size() != 0))
	{
		for (int i = 0; i < list.size();)
		{
			auto Actor = (uint32_t)list[i].Bottle;

			if (Actor == actorcheck)
			{
				skip = true;
				break;
			}
			i++;
		}
	}

	return skip;
}

bool ActorCacheContains(std::vector<actor_struct> list, uint32_t actorcheck)
{
	bool skip = false;
	if ((list.size() > 0) && (list.size() != 0))
	{
		for (int i = 0; i < list.size();)
		{
			auto Actor = list[i];

			if (Actor.actor == actorcheck)
			{
				skip = true;
				break;
			}
			i++;
		}
	}

	return skip;
}

bool ObjectCacheContains(std::vector<CObject*> list, DWORD actorcheck)
{
	bool skip = false;
	if ((list.size() > 0) && (list.size() != 0))
	{
		for (int i = 0; i < list.size();)
		{
			auto Actor = list[i];

			if ((DWORD)Actor == actorcheck)
			{
				skip = true;
				break;
			}
			i++;
		}
	}

	return skip;
}

void AddBarrelsObjective(uint32_t actor, float time)
{
	if (!BarrelsCacheContains(Cache::Barrels, actor))
	{
		Barrel barrel;
		barrel.Bottle = (CObject*)actor;
		barrel.CreationTime = time;
		Cache::Barrels.push_back(barrel);
	}
}

void AddMinionObjective(uint32_t actor)
{
	auto minion = (CObject*)actor;
	if (minion->Team() == 0)
		return;
	if (minion->Team() != me->Team() && minion->MaxHealth() > 0)
	{
		if (!Cache::ObjectCacheContains(Cache::ObjectListMinion, (DWORD)minion))
			Cache::ObjectListMinion.push_back(actor);
	}
}


#include "CActiveSpellEntry.h"
#include "DamageLibrary.h"

#include "Database.h"


#include "Engine.h"
#include "XPolygon.h"
#include "Devices.h"

typedef std::function<bool(CObject*)> Function_Callback;
Function_Callback BeforeAttackEvent;
Function_Callback AfterAttackEvent;
Function_Callback CastSpellEvent;

void SetFunctionCallBack(Function_Callback& func, const Function_Callback& callback)
{
	func = callback;
}
bool IsReady(int slot);
bool CastSpell(int SlotID, Vector3 pos, bool asap = false, bool blockspell = true);
#include "ModuleManager.h"
#include "InputSimulator.h"
#include "JustEvade.h"
#include "TargetSelector.h"
#include "Orbwalker.h"
#include "Prediction.h"
#include "CastSpell.h"

#include "DashCast.h"
#include "BaseUlt.h"
#include "DebugTool.h"
#include "Activator.h"
#include "Awareness.h"

float GetPriority(fnv::hash name)
{
	if (priorities.count(name) == 0)
		return 1.f;

	int priority = priorities[name];
	return priority == 1 ? 1 :
		priority == 2 ? 1.5f :
		priority == 3 ? 1.75f :
		priority == 4 ? 2.f : 2.5f;
}

bool LagFree(int offset)
{
	if (global::tickIndex == offset)
		return true;
	else
		return false;
}

#include "ChampionScript/AIOTopLane.h"
#include "ChampionScript/AIOJungler.h"
#include "ChampionScript/AIOMidLane.h"
#include "ChampionScript/AIOBottomLane.h"
#include "ChampionScript/AIOSupport.h"





std::string xor_this(std::string stringA, std::string key) {

	std::string string = stringA;
	for (int i = 0; i < string.length(); i++)
		string.at(i) = (string.at(i) ^ key.at(i % key.length()));

	return string;
}

void LoadUnitData(std::string  path)
{
	std::ifstream inputSpellData(path, std::ifstream::binary);

	//if (!inputSpellData.is_open())
	//    throw std::runtime_error("Can't open unit data file");

	std::string strjson((std::istreambuf_iterator<char>(inputSpellData)),
		std::istreambuf_iterator<char>());

	auto js = nlohmann::json::parse(strjson);

	for (json::iterator it = js.begin(); it != js.end(); ++it) {
		auto unitObj = it;

		UnitInfo* unit = new UnitInfo();
		//unit->acquisitionRange = (float)unitObj.value()["acquisitionRange"];
		//unit->attackSpeedRatio = (float)unitObj.value()["attackSpeedRatio"];
		//unit->baseAttackRange = (float)unitObj.value()["attackRange"];
		unit->baseAttackSpeed = (float)unitObj.value()["attackSpeed"];
		//unit->baseMovementSpeed = (float)unitObj.value()["baseMoveSpeed"];
		unit->gameplayRadius = (float)unitObj.value()["gameplayRadius"];
		unit->name = ToLower(unitObj.value()["name"]);
		//unit->pathRadius = (float)unitObj.value()["pathingRadius"];
		//unit->selectionRadius = (float)unitObj.value()["selectionRadius"];
		//unit->healthBarHeight = (float)unitObj.value()["healthBarHeight"];
		unit->basicAttackMissileSpeed = (float)unitObj.value()["basicAtkMissileSpeed"];
		unit->basicAttackWindup = (float)unitObj.value()["basicAtkWindup"];

		auto tags = unitObj.value()["tags"];
		for (json::iterator ita = tags.begin(); ita != tags.end(); ++ita)
			UnitInfoSetTag(unit, fnv::hash_runtime(ita.value().get<std::string>().c_str()));

		global::Units[unit->name] = unit;
	}
	strjson.clear();
	js.clear();
}

void LoadSpellData(std::string path)
{
	std::ifstream inputSpellData(path, std::ifstream::binary);

	//if (!inputSpellData.is_open())
	//    throw std::runtime_error("Can't open unit data file");
	std::string strjson((std::istreambuf_iterator<char>(inputSpellData)),
		std::istreambuf_iterator<char>());

	auto js = nlohmann::json::parse(strjson);

	for (json::iterator it = js.begin(); it != js.end(); ++it) {
		SpellInfo* info = new SpellInfo();
		info->delay = float(it.value()["delay"]);
		info->height = float(it.value()["height"]);
		info->icon = ToLower((it.value()["icon"]));
		info->name = ToLower((it.value()["name"]));
		info->width = float(it.value()["width"]);
		info->castRange = float(it.value()["castRange"]);
		info->castRadius = float(it.value()["castRadius"]);
		info->speed = float(it.value()["speed"]);
		info->travelTime = float(it.value()["travelTime"]);

		GameSpells[info->name] = info;
	}

	strjson.clear();
	js.clear();
}

void cachehero()
{

	auto pListSize = RPM<uint32_t>(global::ChampionManager + 0xC);
	std::vector<DWORD> objarray(pListSize);
	ReadVirtualMemory((void*)RPM<uint32_t>(global::ChampionManager + 0x4), objarray.data(), pListSize * sizeof(DWORD));
	LoadSpellData("spell_data.json");
	LoadSpellData("spell_data_custom.json");
	LoadUnitData("unit_data.json");

	for (auto hero : objarray)
	{
		if (hero != 0)
		{
			auto actor = (CObject*)hero;
			int netId;

			ReadVirtualMemory((void*)(hero + oObjNetworkID), &netId, sizeof(int));
			if (netId - (unsigned int)0x40000000 > 0x100000)
				continue;

			if (actor->IsHero())
			{
				actor_struct actorstrt;

				auto pointerd = actor->GetSpellBook()->GetSpellSlotByID(4);
				auto pointerf = actor->GetSpellBook()->GetSpellSlotByID(5);
				std::string SpellName1 = pointerd->GetSpellData()->GetMissileName();
				std::string SpellName2 = pointerf->GetSpellData()->GetMissileName();

				actorstrt.actor = hero;
				actorstrt.name = actor->ChampionName();
				actorstrt.namehash = fnv::hash_runtime(actorstrt.name.c_str());
				for (int i = 0; i < 4; i++)
				{
					if (GameSpells.count(ToLower(actor->GetSpellBook()->GetSpellSlotByID(i)->GetSpellData()->GetMissileName())) > 0)
						actorstrt.skillrange[i] = GameSpells[ToLower(actor->GetSpellBook()->GetSpellSlotByID(i)->GetSpellData()->GetMissileName())]->castRange;
				}

				actorstrt.ishero = true;
				//std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
				if (global::Units.count(ToLower(actorstrt.name)) == 0)
				{
					std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
					std::cout << "Failed to get " << actorstrt.name << " Data" << std::endl;
					continue;
				}
				actorstrt.unitData = global::Units[ToLower(actorstrt.name)];
				std::string Champion = "";
				if (actorstrt.pTextureChamp == 0)
				{
					Champion = "Champion\\square\\";
					Champion.append(actor->ChampionName(1));
					Champion.append("_square.png");
					D3DXCreateTextureFromFileA(d3ddev, Champion.c_str(), &actorstrt.pTextureChamp);
				}
				if (actorstrt.pTextureChampRounded == 0)
				{
					Champion = "Champion\\circle\\";
					Champion.append(actor->ChampionName(1));
					Champion.append("_circle.png");
					D3DXCreateTextureFromFileA(d3ddev, Champion.c_str(), &actorstrt.pTextureChampRounded);
				}

				std::string Spell1 = "";
				if (actorstrt.pTextureSpell1 == 0)
				{
					Spell1 = "Spell\\square\\";
					if (GameSpells.count(ToLower(SpellName1)) > 0)
						Spell1.append(GameSpells[ToLower(SpellName1)]->icon.c_str());
					Spell1.append(".png");
					D3DXCreateTextureFromFileA(d3ddev, Spell1.c_str(), &actorstrt.pTextureSpell1);
				}

				if (actorstrt.pTextureSpellRounded1 == 0)
				{
					Spell1 = "Spell\\circle\\";
					if (GameSpells.count(ToLower(SpellName1)) > 0)
						Spell1.append(GameSpells[ToLower(SpellName1)]->icon.c_str());
					Spell1.append(".png");
					D3DXCreateTextureFromFileA(d3ddev, Spell1.c_str(), &actorstrt.pTextureSpellRounded1);
				}

				std::string Spell2 = "";
				if (actorstrt.pTextureSpell2 == 0)
				{
					Spell2 = "Spell\\square\\";
					if (GameSpells.count(ToLower(SpellName2)) > 0)
						Spell2.append(GameSpells[ToLower(SpellName2)]->icon.c_str());
					Spell2.append(".png");
					D3DXCreateTextureFromFileA(d3ddev, Spell2.c_str(), &actorstrt.pTextureSpell2);
				}
				if (actorstrt.pTextureSpellRounded2 == 0)
				{
					Spell2 = "Spell\\circle\\";
					if (GameSpells.count(ToLower(SpellName2)) > 0)
						Spell2.append(GameSpells[ToLower(SpellName2)]->icon.c_str());
					Spell2.append(".png");
					D3DXCreateTextureFromFileA(d3ddev, Spell2.c_str(), &actorstrt.pTextureSpellRounded2);
				}

				if (!ActorCacheContains(global::enemyheros, hero) && actor->IsEnemy())
					global::enemyheros.push_back(actorstrt);

				if (!ActorCacheContains(global::allyheros, hero) && actor->IsAlly())
					global::allyheros.push_back(actorstrt);

				if (!ActorCacheContains(global::heros, hero))
					global::heros.push_back(actorstrt);
			}
		}
		else
		{
			break;
		}
	}
}

std::map<int, uint32_t>  objectMap;
std::set<int> updatedThisFrame;

void NodeLoopObjectManager()
{
	std::chrono::high_resolution_clock::time_point readTimeBegin;
	std::chrono::duration<float, std::milli> readDuration;
	readTimeBegin = std::chrono::high_resolution_clock::now();
	/* Object Manager Loop*/
	static const int maxObjects = 500;
	static int pointerArray[maxObjects];

	uint32_t objectManager = RPM<uint32_t>(m_Base + offsets_lol.oObjManager);

	static char buff[0x500];
	ReadVirtualMemory((void*)objectManager, buff, 0x100);

	int ObjectMapCount = 0x2C;
	int ObjectMapRoot = 0x28;
	int ObjectMapNodeNetId = 0x10;
	int ObjectMapNodeObject = 0x14;
	int numMissiles, rootNode;
	memcpy(&numMissiles, buff + ObjectMapCount, sizeof(int));
	memcpy(&rootNode, buff + ObjectMapRoot, sizeof(int));

	std::queue<int> nodesToVisit;
	std::set<int> visitedNodes;
	nodesToVisit.push(rootNode);

	// Read object pointers from tree
	int nrObj = 0;
	int reads = 0;
	int childNode1, childNode2, childNode3, node;
	while (reads < maxObjects && nodesToVisit.size() > 0) {
		node = nodesToVisit.front();
		nodesToVisit.pop();
		if (visitedNodes.find(node) != visitedNodes.end())
			continue;

		reads++;
		visitedNodes.insert(node);
		ReadVirtualMemory((void*)node, buff, 0x30);

		memcpy(&childNode1, buff, sizeof(int));
		memcpy(&childNode2, buff + 4, sizeof(int));
		memcpy(&childNode3, buff + 8, sizeof(int));

		nodesToVisit.push(childNode1);
		nodesToVisit.push(childNode2);
		nodesToVisit.push(childNode3);

		unsigned int netId = 0;
		memcpy(&netId, buff + ObjectMapNodeNetId, sizeof(int));

		// Network ids of the objects we are interested in start from 0x40000000. We do this check for performance reasons.
		if (netId - (unsigned int)0x40000000 > 0x100000)
			continue;

		int addr;
		memcpy(&addr, buff + ObjectMapNodeObject, sizeof(int));
		if (addr == 0)
			continue;

		pointerArray[nrObj] = addr;
		nrObj++;
	}

	// Read objects from the pointers we just read
	for (int i = 0; i < nrObj; ++i) {
		auto object = pointerArray[i];
		auto actor = (CObject*)object;
		auto address = (uint32_t)actor;
		auto netId = actor->NetworkID();
		bool skipObject = false;

		for (int j = 0; j < global::missiles.size(); j++)
		{
			if (global::missiles[j].netId == netId || global::missiles[j].actor == address)
			{
				skipObject = true;
				break;
			}
		}


		if (global::blacklistedObjects.find(netId) != global::blacklistedObjects.end() || skipObject)
			continue;

		if (actor->Index() == me->Index())
			continue;

		std::string s = actor->Name();
		std::string sC = actor->ChampionName();
		auto missileName = s;

		/*if (s.empty() || sC.empty())
			continue;*/

		std::string sLower = ToLower(s);
		std::string sCLower = ToLower(sC);

		auto hash = fnv::hash_runtime(s.c_str());
		auto hashC = fnv::hash_runtime(sC.c_str());

		auto skinhash = actor->GetSkinData()->GetSkinHash();

		if (hash == FNV("Seed") && global::LocalChampNameHash == FNV("Syndra"))
		{
			if (!Engine::ActorCacheContains(syndra->BallsList, address))
			{
				if (round(actor->Mana()) <= 19)
					continue;

				syndra->BallsList.push_back(address);
			}
			continue;
		}


		if (hashC == FNV("gangplankbarrel"))
		{
			if (actor->IsValidTarget())
			{
				auto buffmgr = actor->GetBuffManager()->GetBuffEntryByFNVHash(FNV("gangplankebarrelactive"));
				bool own = false;
				if (global::LocalChampNameHash == FNV("Gangplank"))
				{
					if (buffmgr->CasterId() == me->Index() && buffmgr->CasterId() != 0)
					{
						gangplank->AddBarrel(address, Engine::GameTimeTickCount());
						own = true;
					}
				}

				if (!own)
				{
					bool add = true;

					for (auto kek : Engine::GetHeros(2))
					{
						if (kek->Index() == buffmgr->CasterId() && buffmgr->CasterId() != 0)
						{
							add = false;
							break;
						}
					}

					if (add)
					{
						AddBarrelsObjective(address, Engine::GameTimeTickCount());
					}
				}
			}
			continue;
		}


		if (actor->IsTurret())
		{
			if (!Engine::ActorCacheContains(global::turrets, address))
			{
				global::turrets.push_back(address);
				continue;
			}
		}

		if (global::Units.count(sCLower) > 0 && hashC != FNV("gangplankbarrel"))
		{
			if (actor->IsEnemy() && actor->IsAlive())
			{
				if (actor->IsPet() || actor->IsTrap() || HasUnitTags(global::Units[sCLower], Unit_Special_Trap)/*|| (HasUnitTags(global::Units[sCLower], Unit_Minion) && !actor->IsLaneMinion())*/)
				{
					AddMinionObjective(address);
				}

				if (HasUnitTags(global::Units[sCLower], Unit_Ward))
				{
					if (!Engine::WardCacheContains(global::wards, address))
					{
						ward_struct wardstrt;
						wardstrt.actor = address;
						wardstrt.position = actor->Position();

						if (hashC == FNV("ward") || hashC == FNV("yellowtrinketupgrade") || hashC == FNV("yellowtrinket")
							|| hashC == FNV("visionward") || hashC == FNV("sightward"))
						{
							wardstrt.type = 1.f;
							wardstrt.time = Engine::GameGetTickCount();
							float flPoint = D3DX_PI * 2.0f / 30;
							for (float theta = 0; theta < (D3DX_PI * 2.0f); theta += flPoint)
							{
								Vector3 p = Vector3::Zero;

								for (float i = 20.f; i <= 1100.f; i += 20.f)
								{
									Vector3 p2 = Vector3(wardstrt.position.x + (i * cos(theta)), wardstrt.position.y, wardstrt.position.z - (i * sin(theta)));
									if (!Engine::IsNotWall(p2.x, p2.z, 0) || i == 1100.f)
									{
										p = p2;
										break;
									}
								}
								wardstrt.vision.Add(Vector2(p.x, p.z));
							}
							global::wards.push_back(wardstrt);
						}
						else if (hashC == FNV("jammerdevice"))
						{
							wardstrt.type = 2.f;
							auto d32 = Engine::WorldToScreen(wardstrt.position);

							float flPoint = D3DX_PI * 2.0f / 30;
							for (float theta = 0; theta < (D3DX_PI * 2.0f); theta += flPoint)
							{
								Vector3 p = Vector3::Zero;

								for (float i = 20.f; i <= 1100.f; i += 20.f)
								{
									Vector3 p2 = Vector3(wardstrt.position.x + (i * cos(theta)), wardstrt.position.y, wardstrt.position.z - (i * sin(theta)));
									if (!Engine::IsNotWall(p2.x, p2.z, 0) || i == 1100.f)
									{
										p = p2;
										break;
									}
								}
								wardstrt.vision.Add(Vector2(p.x, p.z));
							}
							global::wards.push_back(wardstrt);
						}
						else if (hashC == FNV("perkszombieward") || hashC == FNV("bluetrinket"))
						{
							wardstrt.type = 3.f;
							auto d32 = Engine::WorldToScreen(wardstrt.position);

							float flPoint = D3DX_PI * 2.0f / 30;
							for (float theta = 0; theta < (D3DX_PI * 2.0f); theta += flPoint)
							{
								Vector3 p = Vector3::Zero;

								for (float i = 20.f; i <= 700.f; i += 20.f)
								{
									Vector3 p2 = Vector3(wardstrt.position.x + (i * cos(theta)), wardstrt.position.y, wardstrt.position.z - (i * sin(theta)));
									if (!Engine::IsNotWall(p2.x, p2.z, 0) || i == 700.f)
									{
										p = p2;
										break;
									}
								}
								wardstrt.vision.Add(Vector2(p.x, p.z));
							}
							global::wards.push_back(wardstrt);
						}
						continue;
					}

				}

				if (HasUnitTags(global::Units[sCLower], Unit_Special_Trap))
				{
					if (!Engine::WardCacheContains(global::traps, address))
					{
						ward_struct wardstrt;
						wardstrt.actor = address;
						wardstrt.position = actor->Position();
						wardstrt.name = sCLower;
						global::traps.push_back(wardstrt);
						continue;
					}
				}
			}
		}


		if (hash == FNV("CampRespawn"))
		{
			if (!vectorContains(global::campobject, address))
				global::campobject.push_back(address);

			continue;
		}


		if (actor->IsTroy() && !s.empty())
		{
			if (!Engine::ActorCacheContains(global::troyobjects, address))
			{
				global::troyobjects.push_back(address);
				//printf("dec : %x   name : %s \n", address, s.c_str());
			}

			if (strstr(s.c_str(), "Xerath_") != NULL && strstr(s.c_str(), "_Q_aoe_") != NULL && strstr(s.c_str(), "_red") != NULL)
			{
				Geometry::Polygon path;
				Geometry::Polygon path2;
				auto data = SpellDatabase[FNV("XerathQ")];

				structspell_evade dataToAdd;
				dataToAdd.type = data.type;
				dataToAdd.cc = data.cc;
				dataToAdd.danger = data.danger;
				dataToAdd.collision = data.collision;
				dataToAdd.windwall = data.windwall;

				Vector3 startPos = RPM<Vector3>(address + 0x224), placementPos = RPM<Vector3>(address + 0x24c);
				Vector3 endPos = placementPos;
				double y = placementPos.y;

				auto paths = justevade->GetPaths(XPolygon::To2D(startPos), XPolygon::To2D(endPos), data, FNV("XerathQ"));
				path = paths[0];
				path2 = paths[1];

				justevade->AddSpell(address, netId, path, path2, startPos, placementPos, endPos, dataToAdd, data.speed, data.range, data.delay, data.radius, "XerathQ", y, Engine::GameGetTickCount(), data.allowdodge, data.allowdraw, data.ignoredodge);
			}
		}
	}

	readDuration = std::chrono::high_resolution_clock::now() - readTimeBegin;
	//std::cout << readDuration.count() << "ms" << std::endl;
}

void CacheBuffInfo()
{
	for (auto objBase : global::enemyheros)
	{
		auto actor = (CObject*)objBase.actor;
		auto hash = actor->ChampionNameHash();
		global::BuffCache[hash] = actor->GetBuffManager()->BuffsCache();
	}
}

void EntityLoopNew()
{
	VMProtectBeginMutation("EntityLoopNew");
	//CreateSandboxSpells();
	NodeLoopObjectManager();
	CacheBuffInfo();
	//NormalLoopObjectManager();
	/*CLEANER*/


	Cache::ObjectListMinion.erase(
		std::remove_if(Cache::ObjectListMinion.begin(), Cache::ObjectListMinion.end(),
			[](uint32_t  o) {CObject* actor = (CObject*)o;
	return !(actor->IsAlive() && actor->IsPet()) && !(actor->IsAlive() && actor->IsPet()); }),
		Cache::ObjectListMinion.end());


	global::turrets.erase(
		std::remove_if(global::turrets.begin(), global::turrets.end(),
			[](uint32_t  o) {CObject* actor = (CObject*)o;
	return !(actor->IsAlive() && actor->IsTurret()); }),
		global::turrets.end());

	global::troyobjects.erase(
		std::remove_if(global::troyobjects.begin(), global::troyobjects.end(),
			[](uint32_t  o) {CObject* actor = (CObject*)o;
	return !actor->IsTroy(); }),
		global::troyobjects.end());

	global::campobject.erase(
		std::remove_if(global::campobject.begin(), global::campobject.end(),
			[](uint32_t  o) {CObject* actor = (CObject*)o;
	return fnv::hash_runtime(actor->Name().c_str()) != FNV("CampRespawn"); }),
		global::campobject.end());

	global::traps.erase(
		std::remove_if(global::traps.begin(), global::traps.end(),
			[](ward_struct  o) {CObject* actor = (CObject*)o.actor;
	return !(global::Units.count(actor->ChampionName(1)) > 0 && actor->IsAlive()); }),
		global::traps.end());

	global::wards.erase(
		std::remove_if(global::wards.begin(), global::wards.end(),
			[](ward_struct  o) {CObject* actor = (CObject*)o.actor;
	return !(global::Units.count(actor->ChampionName(1)) > 0 && actor->IsAlive()); }),
		global::wards.end());





	/*std::erase_if(Cache::AllMinionsObj, [](uint32_t  o) {CObject* x = (CObject*)o; return x->IsDead(); });
	std::erase_if(Cache::MinionsListAlly, [](uint32_t  o) {CObject* x = (CObject*)o; return x->IsDead(); });
	std::erase_if(Cache::MinionsListEnemy, [](uint32_t  o) {CObject* x = (CObject*)o; return x->IsDead(); });
	std::erase_if(Cache::MinionsListNeutral, [](uint32_t  o) {CObject* x = (CObject*)o; return x->IsDead(); });
	std::erase_if(global::turrets, [](uint32_t x) {CObject* actor = (CObject*)x; return actor->IsDead() || !actor->IsTurret(); });
	std::erase_if(global::campobject, [](uint32_t x) {CObject* actor = (CObject*)x; return fnv::hash_runtime(actor->Name().c_str()) != FNV("CampRespawn"); });
	std::erase_if(global::traps, [](ward_struct x) {CObject* actor = (CObject*)x.actor; return global::Units.count(actor->ChampionName(1)) == 0 || !actor->IsAlive(); });
	std::erase_if(global::wards, [](ward_struct x) {CObject* actor = (CObject*)x.actor; return global::Units.count(actor->ChampionName(1)) == 0 || !actor->IsAlive(); });

	std::erase_if(global::missiles, [](missle_struct o) { return (o.timedead + 1.2f) <= Engine::GameGetTickCount() && o.dead || Engine::GameGetTickCount() > o.startTime + 5.f; });*/


	VMProtectEnd();
}

#define oCursorTargetPosition 0x170DC94						// 11.13.382.1241 | 0x1B7DC94

//class TMouseController
//{
//public:
//	MAKE_GET(CursorX, int, 0x34);
//	MAKE_GET(CursorY, int, 0x38);
//
//	MAKE_GET(CursorX1, int, 0x3C);
//	MAKE_GET(CursorY1, int, 0x40);
//	MAKE_GET(DisableSpell, int, 0x3ac);
//
//};
//
//void UpdateMousePosition(Vector2 w2s)
//{
//	auto mouse = (TMouseController*)MAKEPTRX(oCursorTargetPosition);
//	//if (!w2s.IsValid())
//	//	return;
//
//	*mouse->GetCursorX() = w2s.x;
//	*mouse->GetCursorY() = w2s.y;
//}

auto printonce = false;
void debug()
{
	//ImGui::Text(textonce(u8"is dashing : %i"), me->GetAIManager()->IsDashing());
	//ImGui::Text(textonce(u8"is moving : %i"), me->GetAIManager()->IsMoving());
	//ImGui::Text(textonce(u8"dash speed : %.0f"), me->GetAIManager()->DashSpeed());
	//ImGui::Text(textonce(u8"Name: %s "), me->ChampionName().c_str());
	//ImGui::Text(textonce(u8"Team: %i "), me->Team());
	//ImGui::Text(textonce(u8"Level: %i "), me->Level());
	//ImGui::Text(textonce(u8"MaxMana: %.0f "), me->MaxMana());
	//ImGui::Text(textonce(u8"Mana: %.0f "), me->Mana());
	//ImGui::Text(textonce(u8"MaxHealth: %.0f "), me->MaxHealth());
	//ImGui::Text(textonce(u8"Health: %.0f "), me->Health());
	//ImGui::Text(textonce(u8"BaseAttackDamage: %.0f "), me->BaseAttackDamage());
	//ImGui::Text(textonce(u8"BonusAttackDamage: %.0f"), me->BonusAttackDamage());
	//ImGui::Text(textonce(u8"TotalAP: %.0f "), me->TotalAbilityPower());
	//ImGui::Text(textonce(u8"BonusMagicDamage: %.0f "), me->BonusMagicDamage());
	//ImGui::Text(textonce(u8"Armor: %.0f "), me->Armor());
	//ImGui::Text(textonce(u8"mBonusArmor: %.0f "), me->BonusArmor());
	//ImGui::Text(textonce(u8"MRes: %.0f "), me->MRes());
	//ImGui::Text(textonce(u8"BonusMRes: %.0f "), me->BonusMRes());
	//ImGui::Text(textonce(u8"MoveSpeed: %.0f "), me->MoveSpeed());
	//ImGui::Text(textonce(u8"AttackRange: %.0f "), me->AttackRange());
	//ImGui::Text(textonce(u8"AttackSpeed: %.2f "), me->AttackSpeed());
	//ImGui::Text(textonce(u8"ArmorPen: %.0f "), me->ArmorPen());
	//ImGui::Text(textonce(u8"MagicPen: %.0f "), me->MagicPen());
	//ImGui::Text(textonce(u8"ArmorPenPercent: %.2f "), me->ArmorPenPercent());
	//ImGui::Text(textonce(u8"MagicPenPercent: %.2f "), me->MagicPenPercent());
	//ImGui::Text(textonce(u8"BoundingRadius: %.0f "), me->BoundingRadius());
	//ImGui::Text(textonce(u8"AdditionalMana: %.0f "), me->GetSpellBook()->GetSpellSlotByID(3)->AdditionalMana());
	//ImGui::Text(textonce(u8"SkinHash: %x "), me->GetSkinData()->GetSkinHash());

//	if (me->GetSpellBook()->GetActiveSpellEntry())
//	{
//		ImGui::Text(textonce(u8"Start Tick: %.2f "), me->GetSpellBook()->GetActiveSpellEntry()->StartTick());
//		ImGui::Text(textonce(u8"Mid Tick: %.2f "), me->GetSpellBook()->GetActiveSpellEntry()->MidTick());
//		ImGui::Text(textonce(u8"End Tick: %.2f "), me->GetSpellBook()->GetActiveSpellEntry()->EndTick());
//		ImGui::Text(textonce(u8"CastDelay: %.2f "), me->GetSpellBook()->GetActiveSpellEntry()->CastDelay());
//		ImGui::Text(textonce(u8"Delay: %.2f "), me->GetSpellBook()->GetActiveSpellEntry()->Delay());
//		ImGui::Text(textonce(u8"isBasicAttack: %i "), me->GetSpellBook()->GetActiveSpellEntry()->isBasicAttack());
//		ImGui::Text(textonce(u8"IsSpecialAttack: %i "), me->GetSpellBook()->GetActiveSpellEntry()->IsSpecialAttack());
//		ImGui::Text(textonce(u8"isAutoAttackAll: %i "), me->GetSpellBook()->GetActiveSpellEntry()->isAutoAttackAll());
//		ImGui::Text(textonce(u8"Slot: %i "), me->GetSpellBook()->GetActiveSpellEntry()->Slot());
//		ImGui::Text(textonce(u8"CastDelay: %.2f "), me->GetSpellBook()->GetActiveSpellEntry()->CastDelay());
//		ImGui::Text(textonce(u8"IsStopped: %i "), me->GetSpellBook()->GetActiveSpellEntry()->IsStopped());
//		ImGui::Text(textonce(u8"IsInstantCast: %i "), me->GetSpellBook()->GetActiveSpellEntry()->IsInstantCast());
//		ImGui::Text(textonce(u8"SpellWasCast: %i "), me->GetSpellBook()->GetActiveSpellEntry()->SpellWasCast());
//		ImGui::Text(textonce(u8"GetStartPos: %i "), me->GetSpellBook()->GetActiveSpellEntry()->GetStartPos());
//		ImGui::Text(textonce(u8"GetEndPos: %i "), me->GetSpellBook()->GetActiveSpellEntry()->GetEndPos());
//		ImGui::Text(textonce(u8"Ping: %i "), Engine::GetPing());
//		
//
//	}
//	if (!printonce)
//	{
//		printf("%s = %x\n", me->ChampionName().c_str(), me->GetSkinData()->GetSkinHash());
//		printf("SpellBook: %x \n", me->GetSpellBook());
//		printf("AI: %x \n", me->GetAIManager());
//
//		//global::ChampionManager = RPM<uint32_t>(m_Base + offsets_lol.oTemplateManager_HeroList);
////		*x WPM<int>(m_Base + 0x170DC94 +);
//		//auto mouse = (TMouseController*)MAKEPTRX(oCursorTargetPosition);
//		Sleep(1000);
//
//		//*mouse->GetCursorX() = w2s.x;
//		//*mouse->GetCursorY() = w2s.y;
//		//*mouse->GetCursorX1() = w2s.x;
//		//*mouse->GetCursorY1() = w2s.y;
//		printonce = true;
//
//
//
//	}
}

void orbloop()
{
	VMProtectBeginMutation("orbloop");
	std::chrono::system_clock::time_point a = std::chrono::system_clock::now();
	std::chrono::system_clock::time_point b = std::chrono::system_clock::now();
	//CreateSandboxSpells();
	while (true)
	{
		// Maintain designated frequency of 5 Hz (200 ms per frame)
		a = std::chrono::system_clock::now();
		std::chrono::duration<double, std::milli> work_time = a - b;

		if (work_time.count() < 1000.0 / MenuSettings::ComboTicksPerSecond)
		{
			std::chrono::duration<double, std::milli> delta_ms((1000.0 / MenuSettings::ComboTicksPerSecond) - work_time.count());
			auto delta_ms_duration = std::chrono::duration_cast<std::chrono::milliseconds>(delta_ms);
			std::this_thread::sleep_for(std::chrono::milliseconds(delta_ms_duration.count()));
		}

		b = std::chrono::system_clock::now();
		std::chrono::duration<double, std::milli> sleep_time = b - a;

		if (Engine::TickCount() - server_tick > 5000)
			continue;

		global::setOrbTick();
		EntityLoopNew();

		global::orbwalkloop++;

		orbwalker->DetectAutoAttacksAndSpells();

		if (global::mode == ScriptMode::Combo)
		{
			if (global::LocalChampNameHash == FNV("Senna"))
			{
				CastSpell(0, targetselector->GetTarget(SpellDatabase[FNV("SennaQCast")].range));
			}
			if (global::LocalChampNameHash == FNV("missfortune"))
			{
				CastSpell(0, targetselector->GetTarget(550));
			}
			else if (global::LocalChampNameHash == FNV("Ziggs"))
			{
				CastSpell(0, targetselector->GetTarget(SpellDatabase[FNV("ZiggsQSpell")].range));
			}
			else if (global::LocalChampNameHash == FNV("Varus"))
			{
				PredictionInput Q = PredictionInput({ 1510, 0.0f,70.f,1525, false, SkillshotType::SkillshotLine });
				auto pO = prediction->GetPrediction(targetselector->GetTarget(SpellDatabase[FNV("VarusQMissile")].range), Q);
				//std::cout << targetQ->GetAIManager() << std::endl;
				//std::cout << (int)pO.HitChance() << std::endl;
				//Renderer::GetInstance()->DrawLine(Engine::WorldToScreenImVec2(targetQ->Position()), Engine::WorldToScreenImVec2(pO.CastPosition()), D3DCOLOR_RGBA(0, 255, 0, 255), 1);
				if (pO.HitChance() >= HitChance::VeryHigh)
				{
					ReleaseSpell(_Q, Engine::WorldToScreen(pO.CastPosition()));
				}

			}
			else if (global::LocalChampNameHash == FNV("Pyke"))
			{
				PredictionInput Q = PredictionInput({ 1100.0f, 0.25f,70.0f,2000.0f, true, SkillshotType::SkillshotLine });
				auto pO = prediction->GetPrediction(targetselector->GetTarget(1100.0f), Q);

				if (pO.HitChance() >= HitChance::VeryHigh)
				{
					ReleaseSpell(_Q, Engine::WorldToScreen(pO.CastPosition()));
				}

			}
			else if (global::LocalChampNameHash == FNV("TahmKench"))
			{
				CastSpell(0, targetselector->GetTarget(SpellDatabase[FNV("TahmKenchQ")].range));
			}
			else if (global::LocalChampNameHash == FNV("Sivir"))
			{
				CastSpell(0, targetselector->GetTarget(SpellDatabase[FNV("SivirQ")].range));
			}
			else if (global::LocalChampNameHash == FNV("Taliyah"))
			{
				auto target = targetselector->GetTarget(900.f);
				PredictionInput W = PredictionInput({ 900, 0.85f,150.f,FLT_MAX, false, SkillshotType::SkillshotCircle });
				auto pred = prediction->GetPrediction(target, W);
				if (pred.HitChance() >= HitChance::High)
					CastSpell(_W, pred.CastPosition(), me->Position());
			}
			else if (global::LocalChampNameHash == FNV("Jayce"))
			{
				if (IsReady(0) && IsReady(2))
				{
					if (CastSpell(targetselector->GetTarget(SpellDatabase[FNV("JayceShockBlastWallMis")].range), 0, "JayceShockBlastWallMis"))
						CastSpell(2, Engine::WorldToScreen(me->Position()));
				}
				if (IsReady(0) && !IsReady(2))
				{
					CastSpell(targetselector->GetTarget(SpellDatabase[FNV("JayceShockBlast")].range), 0, "JayceShockBlast");
				}
			}
			else if (global::LocalChampNameHash == FNV("Swain"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("SwainQ")].range), 0, "SwainQ");
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("SwainW")].range), 1, "SwainW");
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("SwainE")].range), 2, "SwainE");
			}
			else if (global::LocalChampNameHash == FNV("Lux"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("LuxLightBinding")].range), _Q, "LuxLightBinding");
				//CastSpell(targetselector->GetTarget(SpellDatabase[FNV("LuxLightStrikeKugel")].range), _E, "LuxLightStrikeKugel");
			}
			else if (global::LocalChampNameHash == FNV("MasterYi"))
			{
				CastSpell(0, targetselector->GetTarget(600));
			}
			else if (global::LocalChampNameHash == FNV("Viego"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("ViegoQ")].range), 0, "ViegoQ");
				for (auto actor : global::enemyheros)
				{
					auto enemy = (CObject*)actor.actor;
					if (enemy->IsValidTarget(500 + 270))
					{
						auto dmgR = GetSpellDamage(me, enemy, SpellSlot::R, true) + 3 * me->CalculateDamage(enemy, me->TotalAttackDamage());
						if (dmgR > enemy->Health())
							CastSpell(enemy, _R, "ViegoR");
					}
				}
			}
			else if (global::LocalChampNameHash == FNV("Soraka"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("SorakaQ")].range), 0, "SorakaQ");
			}
			else if (global::LocalChampNameHash == FNV("Thresh"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("ThreshQMissile")].range), 0, "ThreshQMissile");
			}
			else if (global::LocalChampNameHash == FNV("KogMaw"))
			{
				SpellDatabase[FNV("KogMawLivingArtillery")].radius = 100.f;
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("KogMawQ")].range), 0, "KogMawQ");
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("KogMawVoidOozeMissile")].range), 2, "KogMawVoidOozeMissile");
				if (me->AttackRange() == 500.f)
					CastSpell(targetselector->GetTarget(me->GetSpellBook()->GetSpellSlotByID(3)->GetRange()), 3, "KogMawLivingArtillery");
			}
			else if (global::LocalChampNameHash == FNV("Yasuo"))
			{
				auto pointerq = me->GetSpellBook()->GetSpellSlotByID(0);
				auto Spell = fnv::hash_runtime(pointerq->GetSpellData()->GetSpellName().c_str());
				if (Spell == FNV("YasuoQ1Wrapper") || Spell == FNV("YasuoQ2Wrapper"))
					CastSpell(targetselector->GetTarget(SpellDatabase[FNV("YasuoQ1")].range + global::LocalData->gameplayRadius * 2), 0, "YasuoQ1");

				if (Spell == FNV("YasuoQ3Wrapper"))
					CastSpell(targetselector->GetTarget(SpellDatabase[FNV("YasuoQ3")].range + global::LocalData->gameplayRadius), 0, "YasuoQ3");
			}
			else if (global::LocalChampNameHash == FNV("Kayn"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("KaynW")].range), _W, "KaynW");
			}
			else if (global::LocalChampNameHash == FNV("Karthus"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("KarthusLayWasteA1")].range), 0, "KarthusLayWasteA1");
			}
			else if (global::LocalChampNameHash == FNV("LeeSin"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("BlindMonkQOne")].range), 0, "BlindMonkQOne");
			}
			else if (global::LocalChampNameHash == FNV("Corki"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("PhosphorusBomb")].range), 0, "PhosphorusBomb");
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("MissileBarrage")].range), 3, "MissileBarrage");
			}
			else if (global::LocalChampNameHash == FNV("Jhin"))
			{
				if (me->GetSpellBook()->GetSpellSlotByID(3)->GetSpellData()->GetSpellNameHash() == FNV("JhinRShot"))
				{
					CastSpell(targetselector->GetTarget(SpellDatabase[FNV("JhinRShot")].range), 3, "JhinRShot", true);
				}
				else
				{
					CastSpell(targetselector->GetTarget(SpellDatabase[FNV("JhinW")].range), 1, "JhinW");
				}
			}
			else if (global::LocalChampNameHash == FNV("Blitzcrank"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("RocketGrab")].range), 0, "RocketGrab");
			}
			else if (global::LocalChampNameHash == FNV("Morgana"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("MorganaQ")].range), 0, "MorganaQ");
			}
			else if (global::LocalChampNameHash == FNV("DrMundo"))
			{
				CastSpell(targetselector->GetTarget(SpellDatabase[FNV("DrMundoQ")].range), 0, "DrMundoQ");
			}
			else if (global::LocalChampNameHash == FNV("Seraphine"))
			{
				CObject* actor = targetselector->GetTarget(1200);
				CastSpell(actor, 0, "SeraphineQCast", true);
				CastSpell(actor, 2, "SeraphineECastEcho", true);
			}
			else if (global::LocalChampNameHash == FNV("Ryze"))
			{
				CObject* actor = targetselector->GetTarget(700);
				PredictionInput pi;
				auto QsPell = SpellDatabase[FNV("RyzeQ")];
				pi.Aoe = false;
				pi.Collision = true;
				pi.Speed = QsPell.speed;
				pi.Delay = QsPell.delay;
				pi.Range = QsPell.range;
				pi.From(me->ServerPosition());
				pi.Radius = QsPell.radius;
				pi.Unit = actor;
				pi.Type = SkillshotType::SkillshotLine;
				auto pO = prediction->GetPrediction(pi);

				if (pO.HitChance() >= HitChance::Medium)
				{
					std::vector<CObject*> minions = Engine::GetMinionsAround(1000, 1);
					for (auto minion : minions)
					{
						if (IsReady(2) && me->Position().Distance(minion->Position()) <= 615 && actor->Position().Distance(minion->Position()) <= 350)
						{
							CastSpell(2, minion, true);
						}

						if (IsReady(0) && me->Position().Distance(minion->Position()) <= 1000)
						{
							if (minion->HasBuff(FNV("RyzeE")) && actor->HasBuff(FNV("RyzeE")))
							{
								CastSpell(minion, 0, "RyzeQ", true);
							}
						}
					}
				}

				if (IsReady(0) && me->Position().Distance(actor->Position()) <= 1000)
				{
					CastSpell(actor, 0, "RyzeQ", true);
				}
				else if (IsReady(1) && me->Position().Distance(actor->Position()) <= 615)
				{
					CastSpell(1, actor, true);
				}

				if (IsReady(0) && me->Position().Distance(actor->Position()) <= 1000)
				{
					CastSpell(actor, 0, "RyzeQ");
				}
				else if (IsReady(2) && me->Position().Distance(actor->Position()) <= 615)
				{
					CastSpell(2, actor, true);
				}
			}
		}


		ModuleManager::ComponentsEvent_onTick();

		_DelayAction->DelayAction_OnOnUpdate();


		if (!global::mousereset)
		{
			global::resetmosuetick++;
			if (global::resetmosuetick > 500)
			{
				global::mousereset = true;
				global::resetmosuetick = 0;
			}
		}

		global::tickIndex++;
		if (global::tickIndex > 4)
			global::tickIndex = 0;


	}
	VMProtectEnd();
}



void DrawTick()
{
	//std::cout << me->IsInvulnerable() << std::endl;
	//std::cout << me->ChampionName() << std::endl;
	//auto buffs = Engine::GetHeros(1).front()->GetBuffManager()->Buffs();
	auto buffs = me->GetBuffManager()->Buffs();
	/*for (auto buff : buffs)
	{
		std::cout << buff.buffentry->GetBuffName() << "   " << buff.count << std::endl;
		std::cout <<" 0x" << std::hex << (uint32_t)buff.buffentry << std::endl;
	}*/


	//std::cout << global::blockOrbAttack << std::endl;
	//std::cout << me->GetWaypoints3D().size() << std::endl;
	//std::cout << unittracker->GetLastAutoAttackTime(Engine::GetHeros(1).front()) << std::endl;
	/*auto kek = from(Engine::GetTurrets(2)) >>
		orderby([&](const auto& t) { return me->Distance(t, true); }) >> first_or_default();
	std::cout << std::hex << (uint32_t)kek->GetSpellBook() << std::endl;*/
	VMProtectBeginMutation("drawtick");
	//unittracker->IsSpamClick(me, 60, 0.25f);
	//printf("%s\n", Engine::GetVersionGarena() );


	//for (auto buff : me->GetBuffManager()->Buffs())
	//{
	//	if (buff.namehash == FNV("SamiraW") && me->IsRanged())
	//		std::cout << buff.endtime << std::endl;;
	//}
	//std::cout << "GetAttackDelay " << (float)me->AttackDelay() << std::endl;
	//std::cout << "GetAttackCastDelay64 " << (float)me->AttackCastDelay() << std::endl;
	//std::cout << Engine::GetPing() << std::endl;
	/*std::cout << "LeagueGetAttackCastDelay " << (float)Engine::GetLeagueAttackCastDelay() << std::endl;
	std::cout << "GetAttackDelay " << (float)Engine::GetAttackDelay() << std::endl;
	std::cout << "GetAttackCastDelay64 " << (float)Engine::AttackCastDelay((DWORD)me, 64) << std::endl;
	std::cout << "GetAttackCastDelay65 " << (float)Engine::AttackCastDelay((DWORD)me, 65) << std::endl;
	std::cout << "GetAnimationTime " << (float)Engine::GetAnimationTime() << std::endl;
	std::cout << "GetWindUpTime " << (float)Engine::GetWindUpTime() << std::endl;*/
	//if(me->GetSpellBook()->GetActiveSpellEntry())

	global::Matrix = RPM<worldtoscreen>(m_Base + offsets_lol.oW2sStatic);//CC CC CC CC B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? B9
	global::renderloop++;
	int hours = floor(keytime / 3600);
	int minutes = floor((keytime / 60) % 60);
	int seconds = keytime % 60;

	//std::cout << std::hex << me->GetSpellBook() << std::endl;
	//std::cout << "Q " << me->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData() << std::endl;
	//std::cout << "W " << me->GetSpellBook()->GetSpellSlotByID(1)->GetSpellData() << std::endl;
	//std::cout << "E " << me->GetSpellBook()->GetSpellSlotByID(2)->GetSpellData() << std::endl;
	//std::cout << "R " << me->GetSpellBook()->GetSpellSlotByID(3)->GetSpellData() << std::endl;

	Renderer::GetInstance()->BeginScene();

	//auto paths = me->GetWaypoints3D();
	//auto lastclick = Engine::WorldToScreenImVec2(me->ServerPosition());
	//auto lastclicks = Engine::WorldToScreenImVec2(Engine::GetMouseWorldPosition());
	//Renderer::GetInstance()->DrawLine(lastclick, lastclicks, D3DCOLOR_RGBA(255, 255, 255, 255));
	//Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, lastclicks, 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%0.f ", Engine::heightForPosition(Engine::GetMouseWorldPosition()));
	//XPolygon::DrawPolygon(paths, D3DCOLOR_RGBA(255, 0, 0, 170), 1, false, false);

	//if (freeTrial)
	//Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2((s_width / 2), 5), 15, D3DCOLOR_RGBA(0, 255, 0, 255), true, false, "LOLSHARP.COM");

	//ImGui::Text(textonce("FPS : %.0f Tick : %.3f Game Time : %.3f Game Ping : %d\nTime left: %02d:%02d:%02d"), ImGui::GetIO().Framerate, 1000 / ImGui::GetIO().Framerate, Engine::GameGetTickCount(), Engine::GetPing(), hours, minutes, seconds); //
	ImGui::Text(textonce("FPS : %.0f Tick : %.3f Game Time : %.3f Game Ping : %d"), ImGui::GetIO().Framerate, 1000 / ImGui::GetIO().Framerate, Engine::GameGetTickCount(), Engine::GetPing()); //

	//ImGui::Text(textonce(u8"CanAttack : %d CanMove : %d"), me->CanAttack(), me->CanMove());//, hours, minutes, seconds); //\n%02d:%02d:%02d
	//ImGui::Text(textonce(u8"IsMoving : %d IsMovingAI : %d"), me->IsMoving(), me->GetAIManager()->IsMoving());//, hours, minutes, seconds); //\n%02d:%02d:%02d

	/*auto intercept =
		me->Position() +
		(float)(rand() % 100 + 1) * 100 * Vector3(1, 0, 0).Rotated((float)(rand() % 100 + 1) * 2 * M_PI);
	Vector3 startPos = Vector3::Zero;
	Vector3 endPos = Vector3::Zero;

	auto diff = 1000 / 2 * Vector3(1, 0, 0).Rotated((float)(rand() % 100 + 1) * 2 * M_PI);
	startPos = intercept + diff;
	endPos = intercept - diff;

	auto W2S_buffer = Engine::WorldToScreenImVec2(startPos);
	auto W2S_buffer2 = Engine::WorldToScreenImVec2(endPos);
	Renderer::GetInstance()->DrawLine(W2S_buffer, W2S_buffer2, D3DCOLOR_RGBA(0, 255, 0, 255), 1);*/

	NewMenu::OnDraw();

	ModuleManager::ComponentsEvent_onDraw();

	Renderer::GetInstance()->EndScene();

	VMProtectEnd();
}


void ResetDevice()
{
	ImGui_ImplDX9_InvalidateDeviceObjects();
	HRESULT hr = d3ddev->Reset(&d3dpp);
	if (hr == D3DERR_INVALIDCALL)
		IM_ASSERT(0);
	ImGui_ImplDX9_CreateDeviceObjects();
}

void exitCleanup()
{
	d3ddev->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_ARGB(0, 0, 0, 0), 1.0f, 0);
	HRESULT result = d3ddev->Present(NULL, NULL, NULL, NULL);
	Sleep(100);
	ImGui_ImplDX9_Shutdown();
	ImGui_ImplWin32_Shutdown();
	ImGui::DestroyContext();
	if (d3ddev)
		d3ddev->Release();
	if (d3d)
		d3d->Release();

	if (hWnd) {
		DestroyWindow(hWnd);
		hWnd = nullptr;
	}
	ExitProcess(0);
}
bool show_demo_window = true;
bool show_another_window = false;
ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

void PollSystem()
{
	ImGuiIO& io = ImGui::GetIO();
	io.ImeWindowHandle = hWnd;
	int mousex, mousey;
	io.DeltaTime = 1.0f / 60.0f;
	bool keys[256];
	BYTE KeyStates[256];

	int TemScreenW = 0, TempScreenH = 0;

	g_pInputSystem->UpdateMousePos(Diffx, Diffy);
	g_pInputSystem->GetMousePos(mousex, mousey);
	g_pInputSystem->PollInputState(true);

	HudManager::CursorPos2D.x = mousex - s_left;
	HudManager::CursorPos2D.y = mousey - s_top;
	io.MousePos.x = (float)(mousex - s_left);
	io.MousePos.y = (float)(mousey - s_top);
	GetKeyboardState(KeyStates);

	for (int i = VK_BACK; i < VK_RMENU; i++)
	{
		if (KeyStates[i] & 0x80 && !io.KeysDown[i]) //key is down
		{
			if (!Engine::IsChatOpen())
			{
				io.KeysDown[i] = true;
				NewMenu::OnWndProc(WM_KEYDOWN, i);
			}
		}
		else if (!(KeyStates[i] & 0x80) && io.KeysDown[i])
		{
			io.KeysDown[i] = false;
			NewMenu::OnWndProc(WM_KEYUP, i);
		}
	}

	if (g_pInputSystem->InputStates[LBUTTON_DOWN] == true)
	{
		io.MouseDown[0] = true;
	}
	else {
		io.MouseDown[0] = false;
	}
	if (g_pInputSystem->InputStates[LBUTTON_CLICKED] == true)
	{
		io.MouseClicked[0] = true;
	}
	else {
		io.MouseClicked[0] = false;
	}
}

void teststyle()
{
	ImGuiStyle* style = &ImGui::GetStyle();
	style->WindowBorderSize = 0;
}


void rendering() {
	/*if (!forcuswin)
	{
		d3ddev->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_ARGB(0, 0, 0, 0), 1.0f, 0);
		HRESULT result = d3ddev->Present(NULL, NULL, NULL, NULL);
		std::this_thread::sleep_for(std::chrono::milliseconds(100));
		return;
	}*/
	//float delay = static_cast <float>(MenuSettings::TicksPerSecond) / 350.f;
	humanizer_delay = 0.10f + static_cast <float> (rand()) / (static_cast <float> (RAND_MAX / (0.14f - 0.10f)));
	PollSystem();
	d3ddev->Clear(0, NULL, D3DCLEAR_TARGET, D3DCOLOR_ARGB(0, 0, 0, 0), 1.0f, 0);
	if (d3ddev->BeginScene() >= 0)
	{
		ImGui_ImplDX9_NewFrame();
		ImGui_ImplWin32_NewFrame();
		ImGui::NewFrame();
		NewMenu::OnWndProc(WM_MOUSEMOVE, NULL);
		DrawTick();

		ImGui::EndFrame();
		ImGui::Render();
		if (MenuSettings::ShowDraw->Value && GetForegroundWindow() == GetLoLWindow())
			ImGui_ImplDX9_RenderDrawData(ImGui::GetDrawData());

		d3ddev->EndScene();
	}

	HRESULT result = d3ddev->Present(NULL, NULL, NULL, NULL);
	// Handle loss of D3D9 device
	if (result == D3DERR_DEVICELOST && d3ddev->TestCooperativeLevel() == D3DERR_DEVICENOTRESET)
		ResetDevice();
}

void drawloop()
{
	VMProtectBeginMutation("drawloop");


	std::chrono::system_clock::time_point a = std::chrono::system_clock::now();
	std::chrono::system_clock::time_point b = std::chrono::system_clock::now();
	while (true)
	{
		// Maintain designated frequency of 5 Hz (200 ms per frame)
		a = std::chrono::system_clock::now();
		std::chrono::duration<double, std::milli> work_time = a - b;

		if (work_time.count() < 1000.0 / MenuSettings::DrawTicksPerSecond)
		{
			std::chrono::duration<double, std::milli> delta_ms((1000.0 / MenuSettings::DrawTicksPerSecond) - work_time.count());
			auto delta_ms_duration = std::chrono::duration_cast<std::chrono::milliseconds>(delta_ms);
			std::this_thread::sleep_for(std::chrono::milliseconds(delta_ms_duration.count()));
		}

		b = std::chrono::system_clock::now();
		std::chrono::duration<double, std::milli> sleep_time = b - a;

		if (Engine::TickCount() - server_tick > 5000)
			continue;

		// Your code here
		global::setDrawTick();

		rendering();

		//printf("Time: %f \n", (work_time + sleep_time).count());
	}
	VMProtectEnd();
}


#ifdef CREATEWINDOW


extern LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

LRESULT window_procedure(
	HWND   window,
	UINT   message,
	WPARAM wparam,
	LPARAM lparam)
{

	if (ImGui_ImplWin32_WndProcHandler(hWnd, message, wparam, lparam))
		return true;

	switch (message) {
	case WM_SIZE:
		if (d3ddev != NULL && wparam != SIZE_MINIMIZED)
		{
			d3dpp.BackBufferWidth = LOWORD(lparam);
			d3dpp.BackBufferHeight = HIWORD(lparam);
			ResetDevice();
		}
		return 0;
	case WM_SYSCOMMAND:
		if ((wparam & 0xfff0) == SC_KEYMENU) // Disable ALT application menu
			return 0;
		break;
	case WM_DESTROY:
		::PostQuitMessage(0);
		return 0;
	default:
		break;
	}
	return DefWindowProc(
		window,
		message,
		wparam,
		lparam
	);
}
#endif // CREATEWINDOW

#ifdef NVIDIAHIJACK
#define MAX_CLASSNAME 255
#define MAX_WNDNAME 255
// Structs
struct WindowsFinderParams {
	DWORD pidOwner = NULL;
	std::wstring wndClassName = L"";
	std::wstring wndName = L"";
	RECT pos = { 0, 0, 0, 0 };
	POINT res = { 0, 0 };
	float percentAllScreens = 0.0f;
	float percentMainScreen = 0.0f;
	DWORD style = NULL;
	DWORD styleEx = NULL;
	bool satisfyAllCriteria = false;
	std::vector<HWND> hwnds;
};
BOOL CALLBACK EnumWindowsCallback(HWND hwnd, LPARAM lParam) {
	WindowsFinderParams& params = *(WindowsFinderParams*)lParam;

	unsigned char satisfiedCriteria = 0, unSatisfiedCriteria = 0;

	// If looking for windows of a specific PDI
	DWORD pid = 0;
	GetWindowThreadProcessId(hwnd, &pid);
	if (params.pidOwner != NULL)
		if (params.pidOwner == pid)
			++satisfiedCriteria; // Doesn't belong to the process targeted
		else
			++unSatisfiedCriteria;

	// If looking for windows of a specific class
	wchar_t className[MAX_CLASSNAME] = L"";
	GetClassName(hwnd, className, MAX_CLASSNAME);
	std::wstring classNameWstr = className;
	if (params.wndClassName != L"")
		if (params.wndClassName == classNameWstr)
			++satisfiedCriteria; // Not the class targeted
		else
			++unSatisfiedCriteria;

	// If looking for windows with a specific name
	wchar_t windowName[MAX_WNDNAME] = L"";
	GetWindowText(hwnd, windowName, MAX_CLASSNAME);
	std::wstring windowNameWstr = windowName;
	if (params.wndName != L"")
		if (params.wndName == windowNameWstr)
			++satisfiedCriteria; // Not the class targeted
		else
			++unSatisfiedCriteria;


	// If looking for window at a specific position
	RECT pos;
	GetWindowRect(hwnd, &pos);
	if (params.pos.left || params.pos.top || params.pos.right || params.pos.bottom)
		if (params.pos.left == pos.left && params.pos.top == pos.top && params.pos.right == pos.right && params.pos.bottom == pos.bottom)
			++satisfiedCriteria;
		else
			++unSatisfiedCriteria;

	// If looking for window of a specific size
	POINT res = { pos.right - pos.left, pos.bottom - pos.top };
	if (params.res.x || params.res.y)
		if (res.x == params.res.x && res.y == params.res.y)
			++satisfiedCriteria;
		else
			++unSatisfiedCriteria;

	// If looking for windows taking more than a specific percentage of all the screens
	float ratioAllScreensX = res.x / GetSystemMetrics(SM_CXSCREEN);
	float ratioAllScreensY = res.y / GetSystemMetrics(SM_CYSCREEN);
	float percentAllScreens = ratioAllScreensX * ratioAllScreensY * 100;
	if (params.percentAllScreens != 0.0f)
		if (percentAllScreens >= params.percentAllScreens)
			++satisfiedCriteria;
		else
			++unSatisfiedCriteria;

	// If looking for windows taking more than a specific percentage or the main screen
	RECT desktopRect;
	GetWindowRect(GetDesktopWindow(), &desktopRect);
	POINT desktopRes = { desktopRect.right - desktopRect.left, desktopRect.bottom - desktopRect.top };
	float ratioMainScreenX = res.x / desktopRes.x;
	float ratioMainScreenY = res.y / desktopRes.y;
	float percentMainScreen = ratioMainScreenX * ratioMainScreenY * 100;
	if (params.percentMainScreen != 0.0f)
		if (percentAllScreens >= params.percentMainScreen)
			++satisfiedCriteria;
		else
			++unSatisfiedCriteria;

	// Looking for windows with specific styles
	LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
	if (params.style)
		if (params.style & style)
			++satisfiedCriteria;
		else
			++unSatisfiedCriteria;

	// Looking for windows with specific extended styles
	LONG_PTR styleEx = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
	if (params.styleEx)
		if (params.styleEx & styleEx)
			++satisfiedCriteria;
		else
			++unSatisfiedCriteria;

	if (!satisfiedCriteria)
		return TRUE;

	if (params.satisfyAllCriteria && unSatisfiedCriteria)
		return TRUE;

	// If looking for multiple windows
	params.hwnds.push_back(hwnd);
	return TRUE;
}
std::vector<HWND> WindowsFinder(WindowsFinderParams params) {
	EnumWindows(EnumWindowsCallback, (LPARAM)&params);
	return params.hwnds;
}
#endif

void CreateOverlayWindow() {
#ifdef NVIDIAHIJACK
	WindowsFinderParams params;
	params.style = WS_VISIBLE;
	params.styleEx = WS_EX_LAYERED | WS_EX_NOACTIVATE;
	params.pidOwner = Engine::find_process(textonce(L"NVIDIA Share.exe"));
	if (params.pidOwner < 1)
	{
		MessageBox(NULL, textonce(L"NVIDIA Not Found"), L"", MB_SYSTEMMODAL);
		ExitProcess(0);
	}
	params.satisfyAllCriteria = true;
	std::vector<HWND> hwnds = WindowsFinder(params);

	if (hwnds.size() < 1) {
		return;
	}
	hWnd = hwnds[0];

	if (hWnd == 0)
		return;

	SetWindowLongPtr(hWnd, GWL_EXSTYLE, WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE);
	Engine::GetDesktopResolution();

	SetLayeredWindowAttributes(hWnd, RGB(0, 0, 0), 255, LWA_ALPHA);
	SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_SHOWWINDOW);
	DwmExtendFrameIntoClientArea(hWnd, &margin);
#endif

#ifdef CREATEWINDOW

	std::string randomtitlea = random_string(10);
	std::string randomclassa = random_string(10);
	std::wstring wrandomtitle(randomtitlea.begin(), randomtitlea.end());
	std::wstring wrandomclass(randomclassa.begin(), randomclassa.end());
	WNDCLASSEX wcex =
	{
		sizeof(WNDCLASSEX),
		 0,
		(WNDPROC)window_procedure,
		0,
		0,
		GetModuleHandle(NULL),
		nullptr,
		nullptr,
		nullptr,
		nullptr,
		wrandomclass.c_str(),
		nullptr
	};


	if (!RegisterClassEx(&wcex))
	{
		ExitProcess(0);
	}

	RECT rc;
	hWndTar = GetLoLWindow();
	GetWindowRect(hWndTar, &rc);
	s_width = rc.right - rc.left;
	s_height = rc.bottom - rc.top;
	s_left = rc.left;
	s_top = rc.top;

	if (hWndTar) {

		DWORD dwStyle = GetWindowLong(hWndTar, GWL_STYLE);
		if (dwStyle & WS_BORDER)
		{
			s_top += 23; s_height -= 23;
			//wSize.left += 10; rWidth -= 10;
		}
	}

	hWnd = CreateWindowEx(NULL, wrandomclass.c_str(), wrandomtitle.c_str(), WS_POPUP, s_left, s_top, s_width, s_height, NULL, NULL, wcex.hInstance, NULL);
	if (!hWnd) {
		ExitProcess(0);
	}
	ShowWindow(hWnd, SW_SHOW);
	SetWindowLongPtr(hWnd, GWL_EXSTYLE, WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW);
	//SetWindowPos(hWnd, HWND_TOPMOST, s_left, s_top, s_width, s_height, SWP_SHOWWINDOW);

	SetLayeredWindowAttributes(hWnd, 0, 255, LWA_ALPHA);
	if (FAILED(DwmExtendFrameIntoClientArea(hWnd, &margin))) {
		ExitProcess(0);
	}

	UpdateWindow(hWnd);
#endif // CREATEWINDOW

}

enum DarkFlags
{
	Bruh = 1,
	Lmao = 2,
	Lol = 4,
	Top = 8,
	Kek = 1 | 2 | 4 | 8,
};

void CreateWindows()
{
	hWnd = 0;
	CreateOverlayWindow();
	if (hWnd == 0)
	{
		ExitProcess(0);
	}


	if (!initD3D(hWnd))
	{
		exitCleanup();
		ExitProcess(0);
	}

	ImGui::CreateContext();
	ImGuiIO& io = ImGui::GetIO(); (void)io;


	Renderer::GetInstance()->Initialize(io.Fonts->AddFontFromFileTTF(textonce("C:\\Windows\\Fonts\\tahoma.ttf"), 16.f, NULL, io.Fonts->GetGlyphRangesVietnamese()));

	if (pUltimateDot == 0)
	{
		uint8_t circledot[] = { 0x89 ,0x50 ,0x4E ,0x47 ,0x0D ,0x0A ,0x1A ,0x0A ,0x00 ,0x00 ,0x00 ,0x0D ,0x49 ,0x48 ,0x44 ,0x52 ,0x00 ,0x00 ,0x00 ,0x0E ,0x00 ,0x00 ,0x00 ,0x0E ,0x08 ,0x06 ,0x00 ,0x00 ,0x00 ,0x1F ,0x48 ,0x2D ,0xD1 ,0x00 ,0x00 ,0x02 ,0x68 ,0x49 ,0x44 ,0x41 ,0x54 ,0x38 ,0x4F ,0x4D ,0x92 ,0x4F ,0x6B ,0x13 ,0x41 ,0x18 ,0x87 ,0x9F ,0x49 ,0xB2 ,0x9B ,0x6E ,0x63 ,0xFE ,0xB4 ,0x89 ,0xB5 ,0x69 ,0xA3 ,0x0D ,0xB6 ,0x6A ,0x45 ,0x91 ,0x28 ,0xA8 ,0x20 ,0x88 ,0xD1 ,0x5E ,0xA4 ,0x2A ,0xC4 ,0xBB ,0x62 ,0x2B ,0x22 ,0x1E ,0x14 ,0x5A ,0xF0 ,0x03 ,0x08 ,0x1E ,0x3D ,0xF4 ,0xE2 ,0xC1 ,0x83 ,0x60 ,0x05 ,0x3F ,0x40 ,0x0F ,0xDE ,0x9B ,0x9E ,0x04 ,0x2F ,0x46 ,0x44 ,0xAB ,0x88 ,0x35 ,0xB5 ,0xA6 ,0xA1 ,0x4D ,0xDB ,0x6C ,0x4C ,0xB2 ,0xEE ,0x6E ,0x76 ,0x76 ,0x25 ,0x8D ,0xAD ,0x0E ,0xBC ,0x30 ,0xBC ,0x33 ,0xCF ,0xCC ,0xEF ,0x85 ,0x47 ,0xF0 ,0xDF ,0x8A ,0x65 ,0x33 ,0x31 ,0x37 ,0x3D ,0x70 ,0x2B ,0x18 ,0x8F ,0xE6 ,0x7C ,0xDD ,0x5D ,0x19 ,0x02 ,0x3E ,0x9A ,0xA6 ,0x51 ,0x68 ,0x94 ,0xD6 ,0xE7 ,0xF8 ,0xB1 ,0xF9 ,0x92 ,0x7C ,0x41 ,0xDF ,0xB9 ,0x2E ,0x76 ,0x36 ,0xE9 ,0x89 ,0xAB ,0xD9 ,0xD0 ,0xF1 ,0x43 ,0x2F ,0xC2 ,0xFB ,0x93 ,0xE9 ,0x48 ,0xBC ,0x17 ,0x5F ,0x50 ,0xA1 ,0x69 ,0x9B ,0x14 ,0xF5 ,0x35 ,0x56 ,0x4B ,0x3F ,0x91 ,0x2B ,0x95 ,0x22 ,0xE5 ,0xEA ,0x24 ,0xAF ,0xF2 ,0xF9 ,0x36 ,0xB3 ,0x0D ,0x8E ,0x4C ,0xE4 ,0xB2 ,0xFD ,0x63 ,0x67 ,0xE6 ,0x53 ,0x27 ,0x8E ,0x12 ,0x8F ,0x27 ,0xE8 ,0xD2 ,0x34 ,0xCC ,0x96 ,0xCD ,0x52 ,0x69 ,0x85 ,0x0F ,0x6B ,0xDF ,0x29 ,0x37 ,0xAA ,0x48 ,0xBD ,0x0E ,0x95 ,0x1A ,0x94 ,0x6B ,0x17 ,0x79 ,0xFA ,0x3A ,0x2F ,0xDA ,0xF1 ,0xD2 ,0xE3 ,0xD9 ,0x77 ,0xA9 ,0x4B ,0x67 ,0xD3 ,0xC3 ,0x47 ,0x46 ,0x49 ,0x84 ,0x22 ,0xDB ,0x21 ,0x6A ,0xBF ,0x7E ,0xF1 ,0xFE ,0xCB ,0x27 ,0x0A ,0xAB ,0xDF ,0xD8 ,0x14 ,0x26 ,0xAE ,0x61 ,0x41 ,0x45 ,0x07 ,0xDD ,0x28 ,0xF2 ,0xBD ,0x7C ,0x52 ,0x0C ,0xDE ,0xBC ,0x32 ,0x95 ,0xBA ,0x76 ,0x7E ,0x26 ,0x79 ,0xEA ,0x18 ,0x87 ,0x07 ,0x86 ,0x48 ,0x76 ,0x45 ,0xB0 ,0x5D ,0x49 ,0x79 ,0x6B ,0x83 ,0xB7 ,0x5F ,0x3F ,0xF2 ,0x61 ,0x6D ,0x99 ,0x86 ,0x70 ,0xF0 ,0x2C ,0x1B ,0xAA ,0x4D ,0x68 ,0x98 ,0xB0 ,0xD5 ,0x9C ,0x16 ,0xC3 ,0x8F ,0xEE ,0xE6 ,0x07 ,0xC7 ,0xCF ,0x5D ,0xD8 ,0x9B ,0x4E ,0x71 ,0x3C ,0x9C ,0x24 ,0xA5 ,0x84 ,0xD9 ,0x30 ,0xEA ,0x2C ,0xAE ,0x97 ,0x78 ,0x53 ,0xFC ,0xCC ,0x52 ,0x75 ,0x0D ,0x89 ,0x0B ,0x2D ,0x09 ,0x86 ,0xDD ,0xA9 ,0x9A ,0xB9 ,0x20 ,0x86 ,0x9F ,0x3C ,0xD0 ,0x07 ,0xC6 ,0xCE ,0x44 ,0x7B ,0xFB ,0xFB ,0x18 ,0xED ,0x4E ,0x10 ,0xF5 ,0x14 ,0x96 ,0xAA ,0xEB ,0x7C ,0xA9 ,0x94 ,0x59 ,0xAC ,0x94 ,0xD8 ,0xA8 ,0x55 ,0x41 ,0x4A ,0x70 ,0x5C ,0x30 ,0x1D ,0xB0 ,0x24 ,0x58 ,0x2D ,0x5D ,0x0C ,0x3D ,0xBE ,0xA7 ,0x27 ,0x4E ,0x1F ,0x8D ,0x76 ,0xF7 ,0x46 ,0x89 ,0x6B ,0x11 ,0x4C ,0xC7 ,0xA1 ,0xA8 ,0x57 ,0xD8 ,0x34 ,0x1A ,0xD4 ,0x7E ,0x37 ,0xB1 ,0xEB ,0x06 ,0x98 ,0x2D ,0x70 ,0x64 ,0x07 ,0x6C ,0x3F ,0x20 ,0xDD ,0x9A ,0x48 ,0x3E ,0xBC ,0x91 ,0xDF ,0x33 ,0x32 ,0x78 ,0x41 ,0xED ,0xEB ,0xC1 ,0xD6 ,0x54 ,0xB6 ,0x1C ,0x0B ,0xDD ,0x34 ,0x90 ,0x9E ,0x0B ,0xAE ,0x07 ,0x0D ,0x0B ,0x9A ,0x56 ,0x07 ,0xB4 ,0xFE ,0x82 ,0x9E ,0xB7 ,0x20 ,0x62 ,0xB7 ,0xAF ,0x4C ,0x29 ,0x07 ,0xF6 ,0xCD ,0x28 ,0xC9 ,0x5E ,0x8C ,0x3D ,0x2A ,0x75 ,0x1C ,0xA4 ,0xE7 ,0xC1 ,0xDF ,0xF2 ,0xFD ,0xB6 ,0x11 ,0xA6 ,0xD5 ,0xFE ,0xA5 ,0x33 ,0xA7 ,0xF4 ,0xF0 ,0x5C ,0x39 ,0x2D ,0xC8 ,0x65 ,0x62 ,0x6A ,0xFA ,0x60 ,0x41 ,0xC4 ,0x23 ,0x43 ,0x32 ,0xAC ,0xE2 ,0x28 ,0xBE ,0xFF ,0x65 ,0x22 ,0x20 ,0x6D ,0x14 ,0xE1 ,0x20 ,0x76 ,0xDA ,0xAE ,0xB7 ,0x6C ,0x38 ,0xF5 ,0x4C ,0xC7 ,0x9C ,0x3B ,0x97 ,0xB3 ,0xC4 ,0x23 ,0xF3 ,0x84 ,0x82 ,0xA0 ,0x06 ,0x3A ,0x60 ,0xFB ,0x44 ,0x80 ,0xE2 ,0x77 ,0x50 ,0x43 ,0xE0 ,0x0F ,0xAB ,0x10 ,0x10 ,0xB8 ,0x36 ,0x17 ,0x1B ,0x37 ,0x9F ,0xE7 ,0x77 ,0x95 ,0xE3 ,0x7E ,0x2E ,0x4B ,0x4F ,0x68 ,0x16 ,0x25 ,0x30 ,0xB4 ,0x0D ,0xFA ,0xDA ,0x94 ,0x40 ,0xF1 ,0xB7 ,0x08 ,0x46 ,0x04 ,0xFE ,0x84 ,0xB6 ,0x2C ,0x84 ,0x6F ,0x42 ,0xBF ,0xFE ,0xEC ,0x9F ,0x72 ,0xBB ,0xD9 ,0xA6 ,0x72 ,0x31 ,0x34 ,0x6D ,0x82 ,0xA0 ,0x3F ,0x47 ,0x30 ,0x90 ,0x11 ,0x9A ,0x9F ,0x80 ,0x2A ,0x0B ,0xAA ,0xC6 ,0x9C ,0x02 ,0xB3 ,0xFA ,0xE4 ,0xEC ,0xAE ,0xE4 ,0x7F ,0x00 ,0x7B ,0x6A ,0x0F ,0x4D ,0x0B ,0x88 ,0xC1 ,0x2F ,0x00 ,0x00 ,0x00 ,0x00 ,0x49 ,0x45 ,0x4E ,0x44 ,0xAE ,0x42 ,0x60 ,0x82 };
		D3DXCreateTextureFromFileInMemory(d3ddev, circledot, sizeof(circledot), &pUltimateDot);
	}
	//E:\\LoLSharp-Project-Release\\x64\\Release\\/
	if (pControlWard == NULL)D3DXCreateTextureFromFileA(d3ddev, textonce("Ward\\Control_Ward_icon.png"), &pControlWard); //Create image from array
	if (pStealthWard == NULL)D3DXCreateTextureFromFileA(d3ddev, textonce("Ward\\Stealth_Ward_icon.png"), &pStealthWard); //Create image from array
	if (pTotemWard == NULL)D3DXCreateTextureFromFileA(d3ddev, textonce("Ward\\Totem_Ward_icon.png"), &pTotemWard); //Create image from array
	if (pFarsightWard == NULL)D3DXCreateTextureFromFileA(d3ddev, textonce("Ward\\Farsight_Ward_icon.png"), &pFarsightWard); //Create image from array

	//D3DXCreateTextureFromFileEx(d3ddev, L"Ward\\Control_Ward_icon.png", 20, 20, 0, D3DPOOL_DEFAULT, D3DFMT_UNKNOWN, D3DPOOL_DEFAULT, D3DX_DEFAULT, D3DX_DEFAULT, D3DCOLOR_RGBA(255, 255, 255, 0), NULL, NULL, &pControlWard);

	if (pSpriteInterface == NULL)D3DXCreateSprite(d3ddev, &pSpriteInterface); //sprite

	dwShaderFlags |= D3DXSHADER_OPTIMIZATION_LEVEL0;
	// Read the D3DX effect file
	HRESULT hr;

	hr = d3ddev->CreateVertexBuffer(3 * sizeof(Vector4), D3DUSAGE_WRITEONLY, D3DFVF_TEX0, D3DPOOL_MANAGED, &g_list_vb, NULL);

	if (FAILED(hr)) {
		//std::cout << "failed CreateVertext" << std::endl;
		system("pause");
	}

	hr = g_list_vb->Lock(0,            //Offset
		0,            //SizeToLock
		&vb_vertices, //Vertices
		0);           //Flags

	if (FAILED(hr)) {
		//std::cout << "failed Lock" << std::endl;
		system("pause");
	}

	Vector4 data[] = {
						Vector4(-20000.f, 0.f, -20000.f, 1.f),
						Vector4(0.f, 0.f, 20000.f, 1.f),
						Vector4(20000.f, 0.f, -20000.f, 1.f)
	};

	memcpy(vb_vertices, //Destination
		data,        //Source
		sizeof(data)); //Amount of data to copy

	g_list_vb->Unlock();

	hr = D3DXCreateEffect(
		d3ddev,
		effect,
		sizeof(effect),
		NULL, // CONST D3DXMACRO* pDefines,
		NULL, // LPD3DXINCLUDE pInclude,
		dwShaderFlags,
		NULL, // LPD3DXEFFECTPOOL pPool,
		&g_pEffect,
		NULL);

	if (FAILED(hr)) {
		//std::cout << "failed D3DXCreateEffect" << std::endl;
		system("pause");
	}

	D3DXHANDLE technique;
	technique = g_pEffect->GetTechniqueByName("RenderScene"); // "RenderScene" or "Debug"
	g_pEffect->SetTechnique(technique);

	ImGui_ImplWin32_Init(hWnd);
	ImGui_ImplDX9_Init(d3ddev);

	teststyle();

	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	std::cout << textonce("Overlay Created") << std::endl;
}

#include <conio.h>
#include <signal.h>
#include <stdio.h>

std::vector<std::string> split(std::string s, std::string delimiter) {
	size_t pos_start = 0, pos_end, delim_len = delimiter.length();
	std::string token;
	std::vector<std::string> res;

	while ((pos_end = s.find(delimiter, pos_start)) != std::string::npos) {
		token = s.substr(pos_start, pos_end - pos_start);
		pos_start = pos_end + delim_len;
		res.push_back(token);
	}

	res.push_back(s.substr(pos_start));
	return res;
}

//__forceinline bool IsSuspiciousDriverLoaded(std::vector<fnv::hash>& DriverHash)
//{
//	LPVOID drivers[1024];
//	DWORD cbNeeded;
//	int cDrivers, i;
//
//	if (EnumDeviceDrivers(drivers, sizeof(drivers), &cbNeeded) && cbNeeded < sizeof(drivers))
//	{
//		CHAR szDriver[1024];
//		cDrivers = cbNeeded / sizeof(drivers[0]);
//
//		//_tprintf(TEXT("There are %d drivers:\n"), cDrivers);
//		for (i = 0; i < cDrivers; i++)
//		{
//			if (GetDeviceDriverBaseNameA(drivers[i], szDriver, sizeof(szDriver) / sizeof(szDriver[0])))
//			{
//				for (int i = 0; i < DriverHash.size(); i++) {
//					if (fnv::hash_runtime(szDriver) == DriverHash.at(i))
//						return true;
//				}
//			}
//		}
//	}
//	return false;
//}
//__forceinline void WalkDriverList()
//{
//	std::vector<fnv::hash> m_driverList;
//	//m_driverList.push_back(FNV("npf.sys"));
//	m_driverList.push_back(FNV("PROCMON24.SYS"));
//	m_driverList.push_back(FNV("kprocesshacker2.sys"));
//	if (IsSuspiciousDriverLoaded(m_driverList))
//	{
//		MessageBox(GetConsoleWindow(), textonce(L"Error code : 0x500002"), textonce(L"ERROR"), MB_ICONERROR);
//		ExitProcess(0);
//	}
//}
//__forceinline void WalkProcessList()
//{
//	std::vector<std::wstring> m_processList;
//	m_processList.push_back(textonce(L"ollydbg.exe"));
//	m_processList.push_back(textonce(L"wireshark.exe"));
//	m_processList.push_back(textonce(L"lordpe.exe"));
//	m_processList.push_back(textonce(L"hookshark.exe"));
//	m_processList.push_back(textonce(L"idag.exe"));
//	m_processList.push_back(textonce(L"apimonitor-x64.exe"));
//	m_processList.push_back(textonce(L"apimonitor-x86.exe"));
//	m_processList.push_back(textonce(L"dbgview.exe"));
//	m_processList.push_back(textonce(L"x64dbg.exe"));
//	m_processList.push_back(textonce(L"x32dbg.exe"));
//	m_processList.push_back(textonce(L"Procmon.exe"));
//	m_processList.push_back(textonce(L"Wireshark.exe"));
//	m_processList.push_back(textonce(L"rawshark.exe"));
//	m_processList.push_back(textonce(L"tshark.exe"));
//
//	for (unsigned int ax = 0; ax < m_processList.size(); ax++)
//	{
//		std::wstring sProcess = m_processList.at(ax);
//		if (Engine::find_process(sProcess.c_str()) != NULL)
//		{
//			MessageBox(GetConsoleWindow(), textonce(L"Error code : 0x500001"), textonce(L"ERROR"), MB_ICONERROR);
//			ExitProcess(0);
//		}
//	}
//}

void ServerHandle()
{
	VMProtectBeginUltra("server");
	WSADATA wsa_data;
	WSAStartup(MAKEWORD(1, 1), &wsa_data);

	SOCKADDR_IN address{ };

	address.sin_family = AF_INET;
	address.sin_addr.s_addr = htonl(0xac41c2a8);//0x2D77D714
	address.sin_port = htons(54340);//4259

	auto connection = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (connection == INVALID_SOCKET)
	{
		ExitProcess(0);
	}
	else if (connection == SOCKET_ERROR)
	{
		ExitProcess(0);
	}
	else
		1;

	auto res = connect(connection, (SOCKADDR*)&address, sizeof(address));
	if (res != 0)
	{
		ExitProcess(0);
	}
	else
	{
		char buf[100];
#ifdef KERNELHOOK
		sprintf(buf, textonce("key|%s|LOLKR|%s"), keynum, lolname);
#else
		sprintf(buf, textonce("key|%s|LOL|%s"), keynum, lolname);
#endif
		bool reconnect = false;
		while (1)
		{
			Sleep(1000);
			//WalkProcessList();
			//WalkDriverList();
			if (send(connection, buf, sizeof(buf), 0) == SOCKET_ERROR)
			{
				//-1 == send error
				//loseconnect++;
				printf(textonce("[!] Lost connection\n"));
				Sleep(40);
				//bServer = false;
				reconnect = true;
				break;
			}

			char RecvdData[100];
			auto result = recv(connection, RecvdData, 100, 0);

			//cout << RecvdData << endl;
			//cout << buf << endl;
			if (strchr(RecvdData, '|') != NULL)
			{
				std::string delimiter = "|";
				std::vector<std::string> v = split(RecvdData, delimiter);
				if (v[0] == textonce("success"))
				{
					keytime = atoi(v[2].c_str());
					//bServer = true;
				}
				else
				{
					//loseconnect++;
					//bServer = false;
				}
			}
			else if (RecvdData == textonce("hethan"))
			{
				//bServer = false;
				closesocket(connection);
				WSACleanup();
				exitCleanup();
			}
			else if (strstr(RecvdData, textonce("hethan")) != NULL)
			{
				//bServer = false;
				closesocket(connection);
				WSACleanup();
				exitCleanup();
			}
			else
			{
				//loseconnect++;
				//bServer = false;
			}
		}
		closesocket(connection);
		WSACleanup();

		if (reconnect)
			serverthread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)ServerHandle, 0, 0, 0); // Start Worker Thread
	}
	VMProtectEnd();
}


enum WindowsOS {
	NotFind,
	Win2000,
	WinXP,
	WinVista,
	Win7,
	Win8,
	Win10
};

WindowsOS GetOsVersionQuick()
{
	double ret = 0.0;
	NTSTATUS(WINAPI * RtlGetVersion)(LPOSVERSIONINFOEXW);
	OSVERSIONINFOEXW osInfo;

	*(FARPROC*)&RtlGetVersion = GetProcAddress(GetModuleHandle(L"ntdll"),
		"RtlGetVersion");

	if (NULL != RtlGetVersion)
	{
		osInfo.dwOSVersionInfoSize = sizeof(osInfo);
		RtlGetVersion(&osInfo);
		ret = (double)osInfo.dwMajorVersion;
	}

	if (osInfo.dwMajorVersion == 10 && osInfo.dwMinorVersion == 0)
	{
		return Win10;
	}
	else if (osInfo.dwMajorVersion == 6 && osInfo.dwMinorVersion == 3)
	{
		return Win8;
	}
	else if (osInfo.dwMajorVersion == 6 && osInfo.dwMinorVersion == 2)
	{
		return Win8;
	}
	else if (osInfo.dwMajorVersion == 6 && osInfo.dwMinorVersion == 1)
	{
		return Win7;
	}

	return NotFind;
}

void initOffsets()
{
	/*Offsets_Riot offsets_na;
	Offsets_Garena offsets_garena;

	if (strcmp(Engine::GetVersionGarena().c_str(), "12.10") == NULL)
	{
		memcpy(&offsets_lol, &offsets_garena, sizeof(offsets_garena));
	}
	if (strcmp(Engine::GetVersionRiot().c_str(), "12.11") == NULL)
	{
		memcpy(&offsets_lol, &offsets_na, sizeof(offsets_na));
	}*/
}

void initLOL()
{
#ifdef KERNELMODE
	ModuleRequest Module = GetBase();

	m_Base = (uint64_t)Module.ModuleBase;
#endif
#ifdef USERMODE
	global::lolHandle = NewOpenProcess(TargetProcessID, hWndTar); // normal openprocess

	mem = new CMem(global::lolHandle);
	m_Base = mem->GetBase();
#endif // USERMODE
#ifdef KERNELHOOK
	m_driver_control = kernel_control_function();

	if (!m_driver_control)
		ExitProcess(0);

	m_Base = (uint32_t)call_driver_control(
		m_driver_control, ID_GET_PROCESS_BASE, TargetProcessID);
#endif // USERMODE

	initOffsets();


	while (RPM<float>(m_Base + offsets_lol.oGameTime) < 2)
	{
		std::this_thread::sleep_for(std::chrono::milliseconds(500));
	}
	Engine::SetCNavMesh(RPM<DWORD>(m_Base + offsets_lol.oIsWallDWORD));

	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	//std::cout << textonce("Found Game Instance 0x") << std::hex << RPM<uint32_t>(m_Base + offsets_lol.oObjManager) << std::endl;
	std::cout << textonce("Found Game Instance") << std::endl;
	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	//std::cout << textonce("Found LocalPlayer 0x") << std::hex << RPM<uint32_t>(m_Base + offsets_lol.oLocalPlayer) << std::endl;
	std::cout << textonce("Found LocalPlayer") << std::endl;
	global::Objmanager = RPM<uint32_t>(m_Base + offsets_lol.oObjManager);
	global::localPlayer = RPM<uint32_t>(m_Base + offsets_lol.oLocalPlayer);
	global::MinimapAddr = RPM<uint32_t>(RPM<uint32_t>(m_Base + offsets_lol.oMinimap) + offsets_lol.oMiniMapSize);
	global::ChampionManager = RPM<uint32_t>(m_Base + offsets_lol.oTemplateManager_HeroList);
	global::MinionManager = RPM<uint32_t>(m_Base + offsets_lol.oTemplateManager_MinionList);

	global::Attackable_Unit = RPM<uint32_t>(m_Base + offsets_lol.oTemplateManager_AttackableUnitsList);
	global::TurretList = RPM<uint32_t>(m_Base + offsets_lol.oTemplateManager_TurretList);
	global::AIBases = RPM<uint32_t>(m_Base + offsets_lol.oTemplateManager_AIBaseList_2);
	SpellDB();
	SpellDBTest();
	OrbInit();
	SpellEvadeInit();
	PriorityChamp();

	std::string name = me->Name();

	strcpy(lolname, name.c_str());
#ifndef NEWSYSTEM
#ifndef SELFUSE 
	serverthread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)ServerHandle, 0, 0, 0); // Start Worker Thread
#endif
#endif // !NEWSYSTEM



	CreateWindows();
	cachehero();

	if (global::Units.count(me->ChampionName(1)) == 0)
	{
		std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
		std::cout << textonce("Failed to get localPlayer Data") << std::endl;
		Sleep(3000);
		ExitProcess(0);
	}
	global::LocalData = global::Units[me->ChampionName(1)];
	global::LocalData->basicAttackMissileSpeed = global::LocalData->basicAttackMissileSpeed == 0 ? FLT_MAX : global::LocalData->basicAttackMissileSpeed;
	global::LocalChampName = me->ChampionName();
	global::LocalChampNameHash = fnv::hash_runtime(global::LocalChampName.c_str());
	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	std::cout << textonce("Thread Initialized") << std::endl;

	SetFunctionCallBack(BeforeAttackEvent, [&](CObject* actor) {
		return true;
		});
	SetFunctionCallBack(AfterAttackEvent, [&](CObject* actor) {
		return true;
		});

	SetFunctionCallBack(CastSpellEvent, [&](CObject* actor) {
		return true;
		});

	NewMenu::Initialize();
	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	std::cout << textonce("Menu Initialized") << std::endl;
#ifdef SELFUSE
	debugger = new Debugger();
	debugger->Add();
#endif
	inputsimulator = new InputSimulator();
	inputsimulator->Add();
	awareness = new Awareness();
	awareness->Add();
	justevade = new JustEvade();
	justevade->Add();
	targetselector = new TargetSelector();
	targetselector->Add();
	activator = new Activator();
	activator->Add();
	unittracker = new UnitTracker();
	unittracker->Add();
	dash = new Dash();
	dash->Add();
	prediction = new Prediction();
	prediction->Add();

	switch (global::LocalChampNameHash)
	{
	case FNV("Jhin"):
	{
		break;
	}
	case FNV("Kalista"):
	{
		kalista = new Kalista();
		kalista->Add();
		break;
	}
	case FNV("Samira"):
	{
		samira = new Samira();
		samira->Add();
		break;
	}
	case FNV("Ezreal"):
	{
		ezreal = new Ezreal();
		ezreal->Add();
		break;
	}
	case FNV("Cassiopeia"):
	{
		cassiopeia = new Cassiopeia();
		cassiopeia->Add();
		break;
	}
	case FNV("Irelia"):
	{
		irelia = new Irelia();
		irelia->Add();
		break;
	}
	case FNV("Olaf"):
	{
		olaf = new Olaf();
		olaf->Add();
		break;
	}
	case FNV("Yone"):
	{
		yone = new Yone();
		yone->Add();
		break;
	}
	case FNV("Pyke"):
	{
		pyke = new Pyke();
		pyke->Add();
		break;
	}

	case FNV("Hecarim"):
	{
		hecarim = new Hecarim();
		hecarim->Add();
		break;
	}
	case FNV("Darius"):
	{
		darius = new Darius();
		darius->Add();
		break;
	}
	case FNV("Quinn"):
	{
		quinn = new Quinn();
		quinn->Add();
		break;
	}
	case FNV("Khazix"):
	{
		khazix = new Khazix();
		khazix->Add();
		break;
	}
	case FNV("Kaisa"):
	{
		kaisa = new Kaisa();
		kaisa->Add();
		break;
	}
	case FNV("Jinx"):
	{
		jinx = new Jinx();
		jinx->Add();
		break;
	}
	case FNV("Lucian"):
	{
		lucian = new Lucian();
		lucian->Add();
		break;
	}
	case FNV("Vayne"):
	{
		vayne = new Vayne();
		vayne->Add();
		break;
	}
	case FNV("Syndra"):
	{
		syndra = new Syndra();
		syndra->Add();
		break;
	}
	case FNV("Viktor"):
	{
		viktor = new Viktor();
		viktor->Add();
		break;
	}
	case FNV("Xerath"):
	{
		xerath = new Xerath();
		xerath->Add();
		break;
	}
	/*case FNV("Varus"):
	{
		varus = new Varus();
		varus->Add();
		break;
	}*/
	case FNV("Udyr"):
	{
		udyr = new Udyr();
		udyr->Add();
		break;
	}
	case FNV("Riven"):
	{
		riven = new Riven();
		riven->Add();
		break;
	}
	case FNV("Fiora"):
	{
		fiora = new Fiora();
		fiora->Add();
		break;
	}
	case FNV("Gangplank"):
	{
		gangplank = new Gangplank();
		gangplank->Add();
		break;
	}
	case FNV("Talon"):
	{
		talon = new Talon();
		talon->Add();
		break;
	}
	case FNV("Diana"):
	{
		diana = new Diana();
		diana->Add();
		break;
	}
	case FNV("Nidalee"):
	{
		nidalee = new Nidalee();
		nidalee->Add();
		break;
	}
	case FNV("Xinzhao"):
	{
		xinzhao = new XinZhao();
		xinzhao->Add();
		break;
	}
	case FNV("Zeri"):
	{
		zeri = new Zeri();
		zeri->Add();
		break;
	}
	default:
	{
		break;
	}
	}

	baseult = new BaseUlt();
	baseult->Add();
	orbwalker = new Orbwalker();
	orbwalker->Add();

	if (ResetAASpells.count(global::LocalChampName))
	{
		ResetSpell.slot = ResetAASpells[global::LocalChampName];
		ResetSpell.timer = 0;
	}
	else
	{
		ResetSpell.slot = 1998;
		ResetSpell.timer = 0;
	}
	ModuleManager::ComponentEvents_onInit();
	if (_DelayAction == 0)	_DelayAction = new DelayAction();

	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	std::cout << textonce("Loaded all modules") << std::endl;
	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	std::cout << textonce("Finish.") << std::endl;

}

void CheckSerialKey()
{
	VMProtectBeginUltraLockByKey("key");
	hActivated = true;
	VMProtectEnd();
}

int chanwebsiterac()
{
	char HostsPath[260], NoPath[] = "\n127.0.0.1\t";
	HANDLE hFile; DWORD i, dwbw;

	std::string Addresses[] = {
	   textonce("combo1s.com"),
	   textonce("pvlol.com"),
	   textonce("toolpvlol.com"),
	   textonce("chothuesub.com"),
	   textonce("toolhack24h.com"),
	   textonce("toolvl.com"),
	   textonce("lienminhtool.com"),
	   textonce("thuetoolgame.com"),
	   textonce("trumtool.com"),
	   textonce("nickrac.com"),
	   textonce("choitool.com"),
	   textonce("tool5k.com"),
	   textonce("toolvui.com"),
	   textonce("toolhack.vn"),
	   textonce("haytool.com"),
	   textonce("toolgamepro.com"),
	   textonce("bollol.com"),
	   textonce("vntoolgame.com"),
	   textonce("toolgamevn.com"),
	   textonce("vncheat.com"),
	   textonce("hotro.pro"),
	   textonce("lienminh24h.net"),
	   textonce("muatoollol.com"),
	   textonce("thuetoollol.com"),
	   textonce("autolienminh.com"),
	   textonce("pvvip.net"),
	   textonce("thuetool24h.net"),
	   textonce("thuetool247.com"),
	   textonce("legendsen.se"),
	   textonce("whysharp.com"),
	   textonce("trinity-script.com"),
	   textonce("army-cheats.com"),
	   textonce("wadbot.lol"),
	   textonce("memoryhackers.org"),
	   textonce("toir.us"),
	   textonce("elocarry.net"),
	   textonce("zenbot.gg"),
	   textonce("hanbot.gg"),
	   textonce("pumbascript.com"),
	   textonce("gamingonsteroids.com"),
	   textonce("hexlol-script.com"),
	   textonce("lol-script.com"),
	   textonce("nyrexscript.com"),
	   textonce("enfront.io"),
	   textonce("jkshop.gg"),
	   textonce("csaccs.com"),
	   textonce("cyberware24.com"),
	   textonce("holyness.shop"),
	   textonce("robur.lol"),
	   textonce("xorbot.cc"),
	   textonce("xnscript.com"),
	   textonce("forumgamers.net"),
	   textonce("xepher.forumgamers.net"),
	   textonce("hangarscript.com"),
	   textonce("mobillegends.net"),
	   textonce("pumbascript.com"),
	   textonce("vnhack.top"),
	   textonce("www.combo1s.com"),
	   textonce("www.pvlol.com"),
	   textonce("www.toolpvlol.com"),
	   textonce("www.chothuesub.com"),
	   textonce("www.toolhack24h.com"),
	   textonce("www.toolvl.com"),
	   textonce("www.lienminhtool.com"),
	   textonce("www.thuetoolgame.com"),
	   textonce("www.trumtool.com"),
	   textonce("www.nickrac.com"),
	   textonce("www.choitool.com"),
	   textonce("www.tool5k.com"),
	   textonce("www.toolvui.com"),
	   textonce("www.toolhack.vn"),
	   textonce("www.haytool.com"),
	   textonce("www.toolgamepro.com"),
	   textonce("www.bollol.com"),
	   textonce("www.vntoolgame.com"),
	   textonce("www.toolgamevn.com"),
	   textonce("www.vncheat.com"),
	   textonce("www.hotro.pro"),
	   textonce("www.lienminh24h.net"),
	   textonce("www.muatoollol.com"),
	   textonce("www.thuetoollol.com"),
	   textonce("www.autolienminh.com"),
	   textonce("www.pvvip.net"),
	   textonce("www.thuetool24h.net"),
	   textonce("www.thuetool247.com"),
	   textonce("www.legendsen.se"),
	   textonce("www.whysharp.com"),
	   textonce("www.trinity-script.com"),
	   textonce("www.army-cheats.com"),
	   textonce("www.wadbot.lol"),
	   textonce("www.memoryhackers.org"),
	   textonce("www.toir.us"),
	   textonce("www.elocarry.net"),
	   textonce("www.zenbot.gg"),
	   textonce("www.hanbot.gg"),
	   textonce("www.pumbascript.com"),
	   textonce("www.gamingonsteroids.com"),
	   textonce("www.hexlol-script.com"),
	   textonce("www.lol-script.com"),
	   textonce("www.nyrexscript.com"),
	   textonce("www.enfront.io"),
	   textonce("www.jkshop.gg"),
	   textonce("www.csaccs.com"),
	   textonce("www.cyberware24.com"),
	   textonce("www.holyness.shop"),
	   textonce("www.robur.lol"),
	   textonce("www.xorbot.cc"),
	   textonce("www.xnscript.com"),
	   textonce("www.forumgamers.net"),
	   textonce("www.xepher.forumgamers.net"),
	   textonce("www.hangarscript.com"),
	   textonce("www.mobillegends.net"),
	   textonce("www.pumbascript.com"),
	   textonce("www.vnhack.top"),
	};

	GetSystemDirectoryA(HostsPath, MAX_PATH);
	lstrcatA(HostsPath, textonce("\\drivers\\etc\\HOSTS"));
	RevokeTrustedInstallerSecurity(HostsPath);
	SetFileAttributesA(HostsPath, FILE_ATTRIBUTE_NORMAL);

	hFile = CreateFileA(HostsPath, FILE_WRITE_DATA, FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hFile == INVALID_HANDLE_VALUE)
		return 1;

	for (i = 0; i < 114; i++) {
		WriteFile(hFile, NoPath, lstrlenA(NoPath), &dwbw, NULL);
		WriteFile(hFile, Addresses[i].c_str(), Addresses[i].length(), &dwbw, NULL);
		Addresses[i].clear();
	}

	SetFileAttributesA(HostsPath, FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM);
	SetTrustedInstallerSecurity(HostsPath);


	CloseHandle(hFile);
	return 0;
}

void keyfunction()
{
#ifndef SELFUSE
	CHAR szExeFileName[MAX_PATH];
	GetModuleFileNameA(NULL, szExeFileName, MAX_PATH);
	rename(szExeFileName, random_string(10).append(".exe").c_str());
	VMProtectBeginMutation("keyy");
	std::string line;
	std::ifstream myfile(textonce("license.txt"));
	if (myfile.is_open())
	{
		std::getline(myfile, line);
		myfile.close();
		ZeroMemory(keynum, 1024);
		sprintf(keynum, line.c_str());
		if (strcmp(keynum, textonce("LOLSHARPDOTCOMFREE")) == 0)
			freeTrial = true;

		char encryptserial[1024];
		int code = VMProtectActivateLicense(keynum, encryptserial, sizeof(encryptserial));
		if (code)
		{
			if (code == 4)
			{
				MessageBox(NULL, textonce(L"You have been banned"), L"", MB_SYSTEMMODAL);
				ExitProcess(0);
			}
			else if (code == 5)
			{
				MessageBox(NULL, textonce(L"Hacking attempt detected"), L"", MB_SYSTEMMODAL);
				ExitProcess(0);

			}
			else if (code == 6)
			{
				MessageBox(NULL, textonce(L"Key not found"), L"", MB_SYSTEMMODAL);
				ExitProcess(0);

			}
			else if (code == 7)
			{
				MessageBox(NULL, textonce(L"Key is already used"), L"", MB_SYSTEMMODAL);
				ExitProcess(0);

			}
			else if (code == 8)
			{
				MessageBox(NULL, textonce(L"License not found"), L"", MB_SYSTEMMODAL);
				ExitProcess(0);
			}
			else if (code == 9)
			{
				MessageBox(NULL, textonce(L"Key expired"), L"", MB_SYSTEMMODAL);
				ExitProcess(0);

			}
			else {
				MessageBox(NULL, textonce(L"Please download the latest version of YTS++"), L"", MB_SYSTEMMODAL);
				ExitProcess(0);
			}
		}

		/////// DECRYPT ANTI CRACK /////////
		time_t rawtime;
		struct tm* timeinfo;
		char buffer[80];

		time(&rawtime);
		timeinfo = gmtime(&rawtime);

		strftime(buffer, sizeof(buffer), textonce("%Y-%m-%d %H"), timeinfo);
		std::string str(buffer);

		MD5 md5;
		std::string keyplain = md5(str);
		keyplain.append(md5(keyplain));

		BYTE key[100];
		memcpy(key, keyplain.c_str(), keyplain.size());

		//
		// String and Sink setup
		//

		std::string ciphertext = base64_decode(encryptserial);
		std::string decryptedtext = AESDecrypt((const unsigned char*)ciphertext.c_str(), ciphertext.length(), key, sizeof(key), key);


		//
		// Decrypt
		//

		//
		// Dump Decrypted Text
		//
		memcpy(serialnum, decryptedtext.c_str(), sizeof(serialnum));

		///// END ANTI CRACK /////////
		int res = VMProtectSetSerialNumber(serialnum);
		int restu = VMProtectGetSerialNumberState();
		if (restu == SERIAL_STATE_FLAG_DATE_EXPIRED) {
			MessageBox(NULL, textonce(L"License expired"), L"", MB_SYSTEMMODAL);
			ExitProcess(0);
		}
		if (restu == SERIAL_STATE_FLAG_CORRUPTED) {
			MessageBox(NULL, textonce(L"License corrupted"), L"", MB_SYSTEMMODAL);
			ExitProcess(0);
		}
		if (restu == SERIAL_STATE_FLAG_INVALID) {
			MessageBox(NULL, textonce(L"License invalid, remember to check auto time in windows setting"), L"", MB_SYSTEMMODAL);
			ExitProcess(0);
		}
		if (restu == 0) {
			VMProtectSerialNumberData sd = { 0 };
			VMProtectGetSerialNumberData(&sd, sizeof(sd));

			//if (sd.wEMail != nullptr && *sd.wEMail != '\0')
			//	ExitProcess(0);

			//if (sd.wUserName != nullptr && *sd.wUserName != '\0')
			//	ExitProcess(0);

		}
		else {
			ExitProcess(0);
		}
	}
	else {
		ExitProcess(0);
	}
	VMProtectEnd();
#else
	CheckSerialKey();
#endif // SELFUSE
}

bool renderOv()
{
#ifdef CREATEWINDOW
	MSG current_message;
	if (PeekMessage(&current_message, nullptr, 0, 0, PM_REMOVE)) {
		if (current_message.message == WM_QUIT) {
			return false;
		}

		TranslateMessage(&current_message);
		DispatchMessage(&current_message);
	}
#endif // CREATEWINDOW
	return true;
}

int main(int argc, char* argv[])
{
	srand(time(NULL));


	/*for (auto hex : effect)
	{
		printf("%02x ", hex);
	}*/

	//if (!SetSePrivilege()) {
	//	std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
	//	std::cout << textonce("Please run as administrator") << std::endl;
	//	system("pause");
	//	ExitProcess(0);
	//}

#ifndef SELFUSE


#ifdef NEWSYSTEM
	std::string cookie = argv[0];
	InitTCPS();

	Client CACServer(textonce("172.65.231.91"), 3210);
	//Client CACServer(textonce("172.65.237.208"), 38808);

	CACServer.onDisconnect(tryConnect);
	CACServer.connect();
	//tryConnect(&CACServer);

	std::atomic<bool> requestDone = false;
	LoginData loginResult = { LoginResultCode::ZERO,0,0,0 };
	CACServer.packet(cmdCookie, cookie).done([&](Packet result)
		{
			loginResult = result.read<LoginData>();
			requestDone = true;

		}).fail([&]
			{
				requestDone = true;
			}).request();

			while (!requestDone) {
				Sleep(10);
			}


			if (loginResult.code != LoginResultCode::OK)
			{
				std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
				std::cout << textonce("Key not found or expired") << std::endl;
				system("pause");
				ExitProcess(0);
			}
#else
	keyfunction();
	CheckSerialKey();
#endif
#endif // !SELFUSE


	//chanwebsiterac();
	LPVOID NtUserSendInput_Addr;
	auto winver = GetOsVersionQuick();
	if (winver == WindowsOS::Win10)
	{
		NtUserSendInput_Addr = GetProcAddress(GetModuleHandle(L"win32u"), "NtUserSendInput");
		if (!NtUserSendInput_Addr)
		{
			NtUserSendInput_Addr = GetProcAddress(GetModuleHandle(L"user32"), "NtUserSendInput");
			if (!NtUserSendInput_Addr)
				return 1;
		}
		usespoofsendinput = true;
		usesyscallmem = true;
	}
	else if (winver == WindowsOS::Win8)
	{

	}
	else if (winver == WindowsOS::Win7)
	{
		NtUserSendInput_Addr = GetProcAddress(GetModuleHandle(L"user32"), "SendInput");
		usespoofsendinput = true;
	}
	if (usesyscallmem)
	{
		std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
		std::cout << textonce("Bypass Initialized successfully") << std::endl;
	}
	else
	{
		std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
		std::cout << textonce("Bypass init is Failed, contact admin discord scamts#0843") << std::endl;
		std::cout << textonce("without Bypass read memory is detectable");
		std::cout << textonce(", press any key if you want to continue otherwise close it") << std::endl;
		system("pause");
	}

	if (usespoofsendinput)
	{
		memcpy(NtUserSendInput_Bytes, NtUserSendInput_Addr, 30);
		std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
		std::cout << textonce("Spoofed Bypass successfully") << std::endl;
	}
	else
	{
		std::cout << colorwin::color(colorwin::red) << time_in_HH_MM_SS();
		std::cout << textonce("Spoofed Bypass Failed, contact admin discord scamts#0843") << std::endl;
		std::cout << textonce("without spoofed Bypass is detectable");
		std::cout << textonce(", press any key if you want to continue otherwise close it") << std::endl;
		system("pause");
	}

	TargetProcessID = Engine::find_process(textonce(L"nope"));
	if (TargetProcessID == 0)
	{
		std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
		std::cout << textonce("Waiting game") << std::endl;
	}

	while (TargetProcessID == 0)
	{
		TargetProcessID = Engine::find_process(textonce(L"nope"));
	}
	while (hWndTar == 0)
	{
		hWndTar = FindWindowFromProcessId(TargetProcessID);
	}

	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	std::cout << textonce("Hook Installed") << std::endl;

	std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
	std::cout << textonce("Found game") << std::endl;
	LocalProcessID = GetCurrentProcessId();
	//hActivated = true;

#ifdef KERNELMODE


	UNICODE_STRING PortName;
	//RXC7XY3D-73PT-ZW4I-FSWY-Z69IGB0HKJQY
	//ECK4C4KQ-NHYG-35MA-HAQF-PTBFD55C
	RtlInitUnicodeString(&PortName, (L"\\RPC Control\\ECK4C4KQ-NHYG-35MA-HAQF-PTBFD55C"));

	NTSTATUS Status = Connect(&PortName,
		&PortHandle);
	if (!NT_SUCCESS(Status))
		ExitProcess(0);


	// Initialize ALPC message attributes
	SIZE_T BufferSize;
	AlpcInitializeMessageAttribute(ALPC_MESSAGE_VIEW_ATTRIBUTE,
		SendMessageAttributes,
		sizeof(MessageAttributesBuffer), //CKDLFDLFIEF 9A9SD 
		&BufferSize);
#endif // KERNELMODE

	initLOL();

	std::thread t1(orbloop);
	std::thread t2(drawloop);


	while (renderOv())
	{
//#ifdef NEWSYSTEM
//
//		CACServer.packet(cmdCookie, cookie).done([&](Packet result)
//			{
//				server_tick = Engine::TickCount();
//
//			}).fail([&]
//				{
//
//				}).request();
//#else
//		server_tick = Engine::TickCount();
//#endif

		server_tick = Engine::TickCount();
		hWndTar = FindWindow(NULL, textonce(L"League of Legends (TM) Client"));
		if (hWndTar != 0)
		{
			HWND hwnd2 = in_foreground(hWndTar);
			if (hwnd2 != 0)
			{
#ifdef CREATEWINDOW
				HWND hwnd3 = GetWindow(hwnd2, GW_HWNDPREV);
				SetWindowPos(hWnd, hwnd3, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
#endif
			}
		}
		else
		{
			exitCleanup();
		}
		Sleep(200);
	}

	return 0;
}