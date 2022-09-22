#pragma once

#include "Devices.h"
#include "buffer.h"
#include <unicorn.h>
#define ADDRESS 0x1000000

typedef struct
{
	HANDLE ProcessHandle;
}UsermodeCall32_Context;

#define PAGE_SIZE 0x1000

#define PAGE_ALIGN_64(Va) (Va) & ~(0x1000ull - 1)


struct ProjectionInfo
{
	bool IsOnSegment;
	Vector2 LinePoint;
	Vector2 SegmentPoint;
};

struct ProjectionInfo3D
{
	bool IsOnSegment;
	Vector3 LinePoint;
	Vector3 SegmentPoint;
};


namespace Engine
{
	bool m_CachePing = false;
	uint32_t cpuPingAddress;
	uint32_t networkPingAddress;
	bool isDisableMove = false;
	bool isTargetChampOnly = false;
	DWORD				 m_NavAddress;

	float				 m_rMaxX;
	float				 m_rMinX;

	float				 m_rMaxZ;
	float				 m_rMinZ;

	float				 m_rOffset1;
	float				 m_rOffset2;

	DWORD				 m_dwOffset3;
	DWORD				 m_dwOffset4;
	DWORD				 m_dwOffset5;

	float				 m_rOffset6;
	DWORD				 m_dwOffset7;
	DWORD				 m_dwOffset8;
	DWORD				 m_dwOffset9;

	std::vector<char>	 m_abHeightBuffer;

	__forceinline float maxX() { return m_rMaxX; }
	__forceinline float minX() { return m_rMinX; }

	__forceinline float maxZ() { return m_rMaxZ; }
	__forceinline float minZ() { return m_rMinZ; }

	void update()
	{
		char abBuff[1500];
		ReadVirtualMemory((void*)m_NavAddress, &abBuff, 1500);

		memcpy(&m_rMaxX, abBuff + ENavMash::NMMaxX, sizeof(float));
		memcpy(&m_rMinX, abBuff + ENavMash::NMMinX, sizeof(float));

		memcpy(&m_rMaxZ, abBuff + ENavMash::NMMaxZ, sizeof(float));
		memcpy(&m_rMinZ, abBuff + ENavMash::NMMinZ, sizeof(float));

		memcpy(&m_rOffset1, abBuff + ENavMash::NMOffset1, sizeof(float));
		memcpy(&m_rOffset2, abBuff + ENavMash::NMOffset2, sizeof(float));

		memcpy(&m_dwOffset3, abBuff + ENavMash::NMOffset3, sizeof(DWORD));
		memcpy(&m_dwOffset4, abBuff + ENavMash::NMOffset4, sizeof(DWORD));
		memcpy(&m_dwOffset5, abBuff + ENavMash::NMOffset5, sizeof(DWORD));

		memcpy(&m_rOffset6, abBuff + ENavMash::NMOffset6, sizeof(float));
		memcpy(&m_dwOffset7, abBuff + ENavMash::NMOffset7, sizeof(DWORD));
		memcpy(&m_dwOffset8, abBuff + ENavMash::NMOffset8, sizeof(DWORD));
		memcpy(&m_dwOffset9, abBuff + ENavMash::NMOffset9, sizeof(DWORD));

		ReadVirtualMemory((void*)m_dwOffset5, m_abHeightBuffer.data(), 1500000);
	}

	void SetCNavMesh(DWORD i_dwAddress)
	{
		m_NavAddress = i_dwAddress;
		m_abHeightBuffer.resize(1500000);
		update();
	}


	class UnitIncomingDamage
	{
	public:
		UnitIncomingDamage()
		{
			this->Damage = 0.0;
			this->Target = nullptr;
			this->Sender = nullptr;
			this->Time = 0;
			this->Damage = 0;
			this->Skillshot = false;
		}
		UnitIncomingDamage(double damage, CObject* targetNetId, float time, bool skillshot, CObject* sender)
		{
			this->Damage = damage;
			this->Target = targetNetId;
			this->Time = time;
			this->Skillshot = skillshot;
			this->Sender = sender;
		}
		bool UseSpellDamages = true;
		CObject* Target;
		CObject* Sender;
		float Time;
		double Damage;
		bool Skillshot;
	};


	std::vector<std::shared_ptr<UnitIncomingDamage>> UnitIncomingDamages;

	Vector3 oldMouse;
	/*void OnUpdate()
	{

		for (auto hero : GetHerosAround(3000.f, 3))
		{
			auto active = hero->GetSpellBook()->GetActiveSpellEntry();
			if (active)
			{
				CObject* target = nullptr;
				for (auto targetz : GetHerosAround(3000.f, 3))
				{
					if (targetz->NetworkID() == active->targetID())
					{
						target = targetz;
						break;
					}
				}
				if (active->isAutoAttackAll())
				{
					auto Damage = std::make_shared<UnitIncomingDamage>(hero->GetAutoAttackDamage(target), target, GameGetTickCount(), false, hero);

					UnitIncomingDamages.push_back(Damage);

				}
				else
				{
					auto Damage = std::make_shared<UnitIncomingDamage>(GetSpellDamage(hero, target, (SpellSlot)hero->GetSpellBook()->GetCastSlot()), target, GameGetTickCount(), false, hero);

					UnitIncomingDamages.push_back(Damage);
				}
			}
		}

		float time = GameGetTickCount() - 2.0f;

		if (UnitIncomingDamages.size() > 0)
			UnitIncomingDamages.erase(std::remove_if(UnitIncomingDamages.begin(), UnitIncomingDamages.end(), [=](std::shared_ptr<UnitIncomingDamage>pt) {return time > pt->Time; }), UnitIncomingDamages.end());

	}*/


	//bool UsermodeCall32_InvalidRwxCallback(uc_engine* uc, uc_mem_type type,
	//	uint64_t address, int size, int64_t value, void* user_data)
	//{
	//	auto ctx = (UsermodeCall32_Context*)user_data;

	//	switch (type) {
	//	case UC_MEM_READ_UNMAPPED:case UC_MEM_FETCH_UNMAPPED: {//case UC_MEM_WRITE_UNMAPPED: 
	//		uint64_t access_base = PAGE_ALIGN_64(address);
	//		uint64_t access_base_end = PAGE_ALIGN_64(address + size);
	//		size_t access_size = (access_base_end != access_base) ? (size_t)(access_base_end - access_base) : PAGE_SIZE;

	//		virtual_buffer_t buf;
	//		if (buf.GetSpace(access_size))
	//		{
	//			if (ReadVirtualMemory((void*)access_base, buf.GetBuffer(), buf.GetLength()))
	//			{
	//				auto err = uc_mem_map(uc, access_base, access_size, UC_PROT_ALL);
	//				if (!err)
	//				{
	//					err = uc_mem_write(uc, access_base, buf.GetBuffer(), access_size);
	//					if (!err)
	//						return true;
	//				}
	//			}
	//			else
	//			{
	//				puts("UsermodeCall32_InvalidRwxCallback faile to read");
	//			}

	//		}
	//		break;
	//	}
	//	}
	//	return false;
	//}

	//void LeagueClick()
	//{

	//	uc_engine* uc;
	//	uc_err err;

	//	err = uc_open(UC_ARCH_X86, UC_MODE_32, &uc);
	//	if (!err) {
	//		uc_hook trace;

	//		uint64_t stack = 0x10000;
	//		size_t stack_size = 0x10000;
	//		uint64_t stack_end = stack + stack_size;
	//		uint64_t my_code_base = stack + stack_size;
	//		int r_esp = (int)stack_end - 0x1000;

	//		uc_mem_map(uc, stack, stack_size, UC_PROT_READ | UC_PROT_WRITE);
	//		uc_mem_map(uc, my_code_base, PAGE_SIZE, UC_PROT_READ | UC_PROT_EXEC);

	//		UsermodeCall32_Context ctx;
	//		ctx.ProcessHandle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, TargetProcessID);

	//		uc_hook_add(uc, &trace, UC_HOOK_MEM_READ_UNMAPPED | UC_HOOK_MEM_WRITE_UNMAPPED | UC_HOOK_MEM_FETCH_UNMAPPED, UsermodeCall32_InvalidRwxCallback, &ctx, 1, 0);


	//		auto mycode_addr = my_code_base;
	//		auto mycode_end = mycode_addr + sizeof(shellshit) - 1;
	//		uc_mem_write(uc, mycode_addr, shellshit, sizeof(shellshit) - 1);

	//		auto err = uc_emu_start(uc, m_Base + mycode_addr, mycode_end, 0, 1000000);


	//		CloseHandle(ctx.ProcessHandle);
	//		uc_close(uc);
	//	}

	//}

	//bool LeagueGetAttackCastDelay(DWORD ObjectAddr, float* castdelay)
	//{
	//	bool success = false;

	//	uc_engine* uc;
	//	uc_err err;

	//	err = uc_open(UC_ARCH_X86, UC_MODE_32, &uc);
	//	if (!err) {
	//		uc_hook trace;

	//		uint64_t stack = 0x10000;
	//		size_t stack_size = 0x10000;
	//		uint64_t stack_end = stack + stack_size;
	//		uint64_t my_code_base = stack + stack_size;
	//		int r_esp = (int)stack_end - 0x1000;

	//		uc_mem_map(uc, stack, stack_size, UC_PROT_READ | UC_PROT_WRITE);
	//		uc_mem_map(uc, my_code_base, PAGE_SIZE, UC_PROT_READ | UC_PROT_EXEC);

	//		UsermodeCall32_Context ctx;
	//		ctx.ProcessHandle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, TargetProcessID);

	//		uc_hook_add(uc, &trace, UC_HOOK_MEM_READ_UNMAPPED | UC_HOOK_MEM_WRITE_UNMAPPED | UC_HOOK_MEM_FETCH_UNMAPPED, UsermodeCall32_InvalidRwxCallback, &ctx, 1, 0);

	//		size_t offset = 0;

	//		unsigned char mycode_buffer[] = {
	//			0xCC, 0xCC, 0xCC//0x51, 0x0F, 0xB6, 0x41, 0x64, 0x56, 0x8D, 0x71, 0x4C, 0x33, 0xC9, 0x57, 0x0F, 0xB6, 0x7E, 0x08, 0x8B, 0x44, 0x86, 0x0C, 0x89, 0x44, 0x24, 0x08, 0x85, 0xFF, 0x74, 0x12, 0x8D, 0x56, 0x04, 0x90, 0x8B, 0x02, 0x8D, 0x52, 0x04, 0x31, 0x44, 0x8C, 0x08, 0x41, 0x3B, 0xCF, 0x72, 0xF2, 0x8A, 0x46, 0x09, 0x84, 0xC0, 0x74, 0x1F, 0x0F, 0xB6, 0xC8, 0xB8, 0x04, 0x00, 0x00, 0x00, 0x2B, 0xC1, 0x83, 0xF8, 0x04, 0x73, 0x10, 0x8A, 0x4C, 0x06, 0x04, 0xF6, 0xD1, 0x30, 0x4C, 0x04, 0x08, 0x40, 0x83, 0xF8, 0x04, 0x72, 0xF0, 0x8B, 0x44, 0x24, 0x08, 0x85, 0x44, 0x24, 0x10, 0x5F, 0x0F, 0x95, 0xC0, 0x5E, 0x59, 0xCC
	//		};
	//		auto mycode_addr = my_code_base + offset;
	//		auto mycode_end = mycode_addr + sizeof(mycode_buffer) - 1;
	//		uc_mem_write(uc, mycode_addr, mycode_buffer, sizeof(mycode_buffer) - 1);
	//		offset += sizeof(mycode_buffer) - 1;

	//		//push obj
	//		r_esp -= 4;
	//		uc_mem_write(uc, r_esp, &ObjectAddr, 4);

	//		//push retaddr
	//		r_esp -= 4;
	//		uc_mem_write(uc, r_esp, &my_code_base, 4);

	//		uc_reg_write(uc, UC_X86_REG_ESP, &r_esp);

	//		auto err = uc_emu_start(uc, m_Base + 0x276D60, mycode_end, 0, 1000000);
	//		if (!err || err == UC_ERR_EXCEPTION) {
	//			uc_reg_read(uc, UC_X86_REG_ESP, &r_esp);
	//			uc_mem_read(uc, r_esp, castdelay, 4);
	//			success = true;
	//		}
	//		CloseHandle(ctx.ProcessHandle);
	//		uc_close(uc);
	//	}

	//	return success;
	//}


	float fastcos(float x) {
		constexpr float tp = 1. / (2. * M_PI);
		x *= tp;
		x -= float(.25) + std::floor(x + float(.25));
		x *= float(16.) * (std::abs(x) - float(.5));
		x += float(.225) * x * (std::abs(x) - float(1.));

		return x;

	}
	float fastsin(float x) {
		x = fmod(x + M_PI, M_PI * 2) - M_PI;
		const float B = 4.0f / M_PI;
		const float C = -4.0f / (M_PI * M_PI);

		float y = B * x + C * x * std::abs(x);

		const float P = 0.225f;

		return P * (y * std::abs(y) - y) + y;
	}

	D3DXMATRIX Matrix(Vector3 rot, Vector3 origin = { 0, 0, 0 })
	{
		float radPitch = rot.x * M_PI / 180.f;
		float radYaw = rot.y * M_PI / 180.f;
		float radRoll = rot.z * M_PI / 180.f;

		float SP = fastsin(radPitch);
		float CP = fastcos(radPitch);
		float SY = fastsin(radYaw);
		float CY = fastcos(radYaw);
		float SR = fastsin(radRoll);
		float CR = fastcos(radRoll);

		D3DMATRIX matrix;
		matrix.m[0][0] = CP * CY;
		matrix.m[0][1] = CP * SY;
		matrix.m[0][2] = SP;
		matrix.m[0][3] = 0.f;

		matrix.m[1][0] = SR * SP * CY - CR * SY;
		matrix.m[1][1] = SR * SP * SY + CR * CY;
		matrix.m[1][2] = -SR * CP;
		matrix.m[1][3] = 0.f;

		matrix.m[2][0] = -(CR * SP * CY + SR * SY);
		matrix.m[2][1] = CY * SR - CR * SP * SY;
		matrix.m[2][2] = CR * CP;
		matrix.m[2][3] = 0.f;

		matrix.m[3][0] = origin.x;
		matrix.m[3][1] = origin.y;
		matrix.m[3][2] = origin.z;
		matrix.m[3][3] = 1.f;

		return matrix;
	}

	void GetDesktopResolution()
	{
		RECT desktop;
		const HWND hDesktop = GetDesktopWindow();
		GetWindowRect(hDesktop, &desktop);

		s_left = desktop.left;
		s_top = desktop.top;
		s_width = desktop.right;
		s_height = desktop.bottom;
	}

	bool IsOutboundScreen2(Vector2 location)
	{
		if (location.x > 0 && location.x < (float)s_width && location.y > 0 && location.y < (float)s_height)
		{
			return false;
		}
		return true;
	}

	bool IsOutboundScreen(Vector3 location)
	{
		if (location.x > 0 && location.x < (float)s_width && location.y > 0 && location.y < (float)s_height)
		{
			return false;
		}
		return true;
	}

	bool in_array(const std::string& value, const std::vector<std::string>& array)
	{
		return std::find(array.begin(), array.end(), value) != array.end();
	}

	std::wstring s2ws(const std::string& s)
	{
		int len;
		int slength = (int)s.length() + 1;
		len = MultiByteToWideChar(CP_ACP, 0, s.c_str(), slength, 0, 0);
		wchar_t* buf = new wchar_t[len];
		MultiByteToWideChar(CP_ACP, 0, s.c_str(), slength, buf, len);
		std::wstring r(buf);
		delete[] buf;
		return r;
	}

	DWORD find_process(const std::wstring& name)
	{
		auto hSnapShot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);
		if (hSnapShot == INVALID_HANDLE_VALUE)
			return NULL;
		PROCESSENTRY32W pe = {};
		pe.dwSize = sizeof(pe);
		if (!Process32FirstW(hSnapShot, &pe)) {
			::CloseHandle(hSnapShot);
			return NULL;
		}
		DWORD dwPID = NULL;
		do {
			if (pe.th32ProcessID == GetCurrentProcessId())
				continue;
			if (name == textonce(L"nope"))
			{
				if (wcsstr(pe.szExeFile, textonce(L"League of Legends.exe"))) {

					dwPID = pe.th32ProcessID;
					break;
				}
			}
			else if (name == std::wstring(pe.szExeFile)) {
				dwPID = pe.th32ProcessID;
				break;
			}
		} while (Process32NextW(hSnapShot, &pe));
		::CloseHandle(hSnapShot);
		return dwPID;
	}

	Vector3 TransformCoordinate(Vector3 coordinate, D3DMATRIX transform)
	{
		Vector4 vector;
		vector.x = (coordinate.x * transform._11) + (coordinate.y * transform._21) + (coordinate.z * transform._31) + transform._41;
		vector.y = (coordinate.x * transform._12) + (coordinate.y * transform._22) + (coordinate.z * transform._32) + transform._42;
		vector.z = (coordinate.x * transform._13) + (coordinate.y * transform._23) + (coordinate.z * transform._33) + transform._43;
		vector.w = 1.f / ((coordinate.x * transform._14) + (coordinate.y * transform._24) + (coordinate.z * transform._34) + transform._44);

		return Vector3(vector.x * vector.w, vector.y * vector.w, vector.z * vector.w);
	}

	Vector3 Project(Vector3 vector, float x, float y, float width, float height, float minZ, float maxZ, D3DMATRIX worldViewProjection)
	{
		Vector3 v = TransformCoordinate(vector, worldViewProjection);

		return Vector3(((1.0f + v.x) * 0.5f * width) + x, ((1.0f - v.y) * 0.5f * height) + y, (v.z * (maxZ - minZ)) + minZ);
	}

	ImVec2 WorldToScreenImVec2(Vector3 objLoc)
	{
		if (objLoc.x == 0 && objLoc.y == 0 && objLoc.z == 0)
			return ImVec2(-1, -1);
		D3DXMATRIX mWorld = D3DXMATRIX(1.0f, 0.0f, 0.0f, 0.0f,
			0.0f, 1.0f, 0.0f, 0.0f,
			0.0f, 0.0f, 1.0f, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);

		//global::viewMatrix = RPM<D3DXMATRIX>(m_Base + oW2sStatic); //CC CC CC CC B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? B9
		//global::projMatrix = RPM<D3DXMATRIX>(m_Base + oW2sStatic + 0x40);

		D3DXMATRIX worldViewProjection = MatrixMultiplication(global::Matrix.viewmatrix, global::Matrix.projmatrix);
		//D3DXMATRIX worldViewProjection = MatrixMultiplication(mWorld, viewProjection);


		//TopLeftCorner of Window
		int x = 0;
		int y = 0;

		Vector4 vector;
		vector.x = (objLoc.x * worldViewProjection._11) + (objLoc.y * worldViewProjection._21) + (objLoc.z * worldViewProjection._31) + worldViewProjection._41;
		vector.y = (objLoc.x * worldViewProjection._12) + (objLoc.y * worldViewProjection._22) + (objLoc.z * worldViewProjection._32) + worldViewProjection._42;
		vector.z = (objLoc.x * worldViewProjection._13) + (objLoc.y * worldViewProjection._23) + (objLoc.z * worldViewProjection._33) + worldViewProjection._43;
		vector.w = 1.f / ((objLoc.x * worldViewProjection._14) + (objLoc.y * worldViewProjection._24) + (objLoc.z * worldViewProjection._34) + worldViewProjection._44);
		Vector3 v = Vector3(vector.x * vector.w, vector.y * vector.w, vector.z * vector.w);

		Vector3 screen = Vector3(((1.0f + v.x) * 0.5f * s_width) + x, ((1.0f - v.y) * 0.5f * s_height) + y, (v.z * (1.0f - 0.0f)) + 0.0f);

		if (global::Matrix.viewmatrix._21 != 0.0f)
			return ImVec2(-1, -1);

		ImVec2 screenout;
		screenout.x = (screen.x) / s_width * s_width;
		screenout.y = (screen.y) / s_height * s_height;

		return screenout;
	}

	Vector2 WorldToScreenvec2(Vector3 objLoc)
	{
		if (objLoc.x == 0 && objLoc.y == 0 && objLoc.z == 0)
			return Vector2(-1, -1);
		D3DXMATRIX mWorld = D3DXMATRIX(1.0f, 0.0f, 0.0f, 0.0f,
			0.0f, 1.0f, 0.0f, 0.0f,
			0.0f, 0.0f, 1.0f, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);

		//global::viewMatrix = RPM<D3DXMATRIX>(m_Base + oW2sStatic); //CC CC CC CC B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? B9
		//global::projMatrix = RPM<D3DXMATRIX>(m_Base + oW2sStatic + 0x40);

		D3DXMATRIX worldViewProjection = MatrixMultiplication(global::Matrix.viewmatrix, global::Matrix.projmatrix);
		//	D3DXMATRIX worldViewProjection = MatrixMultiplication(mWorld, viewProjection);


			//TopLeftCorner of Window
		int x = 0;
		int y = 0;

		Vector4 vector;
		vector.x = (objLoc.x * worldViewProjection._11) + (objLoc.y * worldViewProjection._21) + (objLoc.z * worldViewProjection._31) + worldViewProjection._41;
		vector.y = (objLoc.x * worldViewProjection._12) + (objLoc.y * worldViewProjection._22) + (objLoc.z * worldViewProjection._32) + worldViewProjection._42;
		vector.z = (objLoc.x * worldViewProjection._13) + (objLoc.y * worldViewProjection._23) + (objLoc.z * worldViewProjection._33) + worldViewProjection._43;
		vector.w = 1.f / ((objLoc.x * worldViewProjection._14) + (objLoc.y * worldViewProjection._24) + (objLoc.z * worldViewProjection._34) + worldViewProjection._44);
		Vector3 v = Vector3(vector.x * vector.w, vector.y * vector.w, vector.z * vector.w);

		Vector3 screen = Vector3(((1.0f + v.x) * 0.5f * s_width) + x, ((1.0f - v.y) * 0.5f * s_height) + y, (v.z * (1.0f - 0.0f)) + 0.0f);

		if (global::Matrix.viewmatrix._21 != 0.0f)
			return Vector2(-1, -1);

		Vector2 screenout;
		screenout.x = (screen.x) / s_width * s_width;
		screenout.y = (screen.y) / s_height * s_height;

		return screenout;
	}

	Vector3 WorldToScreenBeta(Vector3 objLoc)
	{
		if (objLoc.x == 0 && objLoc.x == 0 && objLoc.z == 0)
			return Vector3(-1, -1, -1);

		D3DXMATRIX mWorld = D3DXMATRIX(1.0f, 0.0f, 0.0f, 0.0f,
			0.0f, 1.0f, 0.0f, 0.0f,
			0.0f, 0.0f, 1.0f, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);

		//global::viewMatrix = RPM<D3DXMATRIX>(m_Base + oW2sStatic); //CC CC CC CC B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? B9
		//global::projMatrix = RPM<D3DXMATRIX>(m_Base + oW2sStatic + 0x40);

		D3DXMATRIX worldViewProjection = MatrixMultiplication(global::Matrix.viewmatrix, global::Matrix.projmatrix);
		//D3DXMATRIX worldViewProjection = MatrixMultiplication(mWorld, viewProjection);


		//TopLeftCorner of Window
		int x = 0;
		int y = 0;

		Vector4 vector;
		vector.x = (objLoc.x * worldViewProjection._11) + (objLoc.y * worldViewProjection._21) + (objLoc.z * worldViewProjection._31) + worldViewProjection._41;
		vector.y = (objLoc.x * worldViewProjection._12) + (objLoc.y * worldViewProjection._22) + (objLoc.z * worldViewProjection._32) + worldViewProjection._42;
		vector.z = (objLoc.x * worldViewProjection._13) + (objLoc.y * worldViewProjection._23) + (objLoc.z * worldViewProjection._33) + worldViewProjection._43;
		vector.w = 1.f / ((objLoc.x * worldViewProjection._14) + (objLoc.y * worldViewProjection._24) + (objLoc.z * worldViewProjection._34) + worldViewProjection._44);
		Vector3 v = Vector3(vector.x * vector.w, vector.y * vector.w, vector.z * vector.w);

		Vector3 screen = Vector3(((1.0f + v.x) * 0.5f * s_width) + x, ((1.0f - v.y) * 0.5f * s_height) + y, (v.z * (1.0f - 0.0f)) + 0.0f);

		if (global::Matrix.viewmatrix._21 != 0.0f)
			return Vector3(-1, -1, -1);

		Vector3 screenout;
		screenout.x = (screen.x) / s_width * s_width;
		screenout.y = (screen.y) / s_height * s_height;

		return screenout;
	}

	Vector3 WorldToScreen(Vector3 objLoc)
	{
		if (objLoc.x == 0 && objLoc.x == 0 && objLoc.z == 0)
			return Vector3(-1, -1, -1);

		D3DXMATRIX mWorld = D3DXMATRIX(1.0f, 0.0f, 0.0f, 0.0f,
			0.0f, 1.0f, 0.0f, 0.0f,
			0.0f, 0.0f, 1.0f, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);

		//global::viewMatrix = RPM<D3DXMATRIX>(m_Base + oW2sStatic); //CC CC CC CC B9 ?? ?? ?? ?? E8 ?? ?? ?? ?? B9
		//global::projMatrix = RPM<D3DXMATRIX>(m_Base + oW2sStatic + 0x40);

		D3DXMATRIX worldViewProjection = MatrixMultiplication(global::Matrix.viewmatrix, global::Matrix.projmatrix);
		//D3DXMATRIX worldViewProjection = MatrixMultiplication(mWorld, viewProjection);


		//TopLeftCorner of Window
		int x = 0;
		int y = 0;

		Vector4 vector;
		vector.x = (objLoc.x * worldViewProjection._11) + (objLoc.y * worldViewProjection._21) + (objLoc.z * worldViewProjection._31) + worldViewProjection._41;
		vector.y = (objLoc.x * worldViewProjection._12) + (objLoc.y * worldViewProjection._22) + (objLoc.z * worldViewProjection._32) + worldViewProjection._42;
		vector.z = (objLoc.x * worldViewProjection._13) + (objLoc.y * worldViewProjection._23) + (objLoc.z * worldViewProjection._33) + worldViewProjection._43;
		vector.w = 1.f / ((objLoc.x * worldViewProjection._14) + (objLoc.y * worldViewProjection._24) + (objLoc.z * worldViewProjection._34) + worldViewProjection._44);
		Vector3 v = Vector3(vector.x * vector.w, vector.y * vector.w, vector.z * vector.w);

		Vector3 screen = Vector3(((1.0f + v.x) * 0.5f * s_width) + x, ((1.0f - v.y) * 0.5f * s_height) + y, (v.z * (1.0f - 0.0f)) + 0.0f);

		if (global::Matrix.viewmatrix._21 != 0.0f)
			return Vector3(-1, -1, -1);

		Vector3 screenout;
		screenout.x = (screen.x) / s_width * s_width;
		screenout.y = (screen.y) / s_height * s_height;

		return screenout;
	}

	Vector2 WorldToMinimap(Vector3 Location)
	{
		Vector2 screen_size = RPM<Vector2>(global::MinimapAddr + 0x4C);
		Vector2 screen_start = RPM<Vector2>(global::MinimapAddr + 0x44);

		//Vector2 screen_start;
		//float scaling = MenuSettings::MinimapScaling /100;
		//float wsize = 193 + 190.0 * scaling;
		//printf("wsize: %.5f \n", wsize);
		//printf("w: %.0f h: %.0f", s_width, s_height);
	//	Vector2 screen_size = Vector2(wsize, wsize);


		//if (MenuSettings::RightSide)
		//	screen_start = Vector2(s_width - wsize - 10, s_height - wsize - 10);
		//else
		//	screen_start = Vector2(s_width- s_width+10, s_height - wsize-10);


		/*Vector2 bottom_left = screen_start + Vector2(0, screen_size.y);

		Vector2 w2m_scale = Vector2(screen_size.x / 10000, -(screen_size.y / 10000));
		w2m_scale = w2m_scale / 1.5f;

		return bottom_left + Vector2(w2m_scale.x * Location.x, w2m_scale.y * Location.z);*/
		Vector2 result = { Location.x / 15000.f, Location.z / 15000.f };
		result.x = screen_start.x + result.x * screen_size.x;
		result.y = screen_start.y + screen_size.y - (result.y * screen_size.y);

		return result;
	}

	Vector3 WorldToMinimap3D(Vector3 Location)
	{
		Vector2 screen_size = RPM<Vector2>(global::MinimapAddr + 0x4C);
		Vector2 screen_start = RPM<Vector2>(global::MinimapAddr + 0x44);
		/*Vector2 bottom_left = screen_start + Vector2(0, screen_size.y);

		Vector2 w2m_scale = Vector2(screen_size.x / 10000, -(screen_size.y / 10000));
		w2m_scale = w2m_scale / 1.5f;

		return bottom_left + Vector2(w2m_scale.x * Location.x, w2m_scale.y * Location.z);*/
		Vector3 result = { Location.x / 15000.f, Location.z / 15000.f,0 };
		result.x = screen_start.x + result.x * screen_size.x;
		result.y = screen_start.y + screen_size.y - (result.y * screen_size.y);

		return result;
	}

	Vector3 GetBaseDrawPos(CObject* object)
	{
		// E8 ?? ?? ?? ?? 8B 4E ?? 8D 54 ?? ?? 52 8B 01 FF ?? ?? 5E 83 ?? ?? C3
		BYTE v4 = RPM<BYTE>((DWORD)object + offsets_lol.oHPBar_1);  //oHPBar_3 = 8B 84 87 ? ? ? ? 89 44 24 08 85 F6 74 17
		DWORD v32 = RPM<DWORD>((DWORD)object + 4 * RPM<BYTE>((DWORD)object + offsets_lol.oHPBar_2) + offsets_lol.oHPBar_3);
		uint32_t v7 = RPM<uint32_t>((DWORD)object + offsets_lol.oHPBar_4); // 0x3254
		v32 ^= ~v7;

		uint32_t a1 = RPM<uint32_t>(v32 + 0x14); // 0x18 
		uint32_t a2 = RPM<uint32_t>(a1 + 0x4); // 0x4
		uint32_t a3 = RPM<uint32_t>(a2 + 0x1C);

		float delta = RPM<float>(a3 + 0x88);

		Vector3 currentpos = object->Position();

		return Vector3(currentpos.x, currentpos.y + delta, currentpos.z);
	}

	Vector2 GetHealthBarPos(CObject* obj)
	{
		//auto w2s = this->Position.WorldToScreen();
		//return Vector2(w2s.x - 90, w2s.y );


		LeagueObfuscationDword typeobf;
		ReadVirtualMemory((void*)((DWORD)obj + offsets_lol.oHPBar_1 - 1), &typeobf, sizeof(LeagueObfuscationDword));


		auto unit = decrypt_dword(typeobf);

		auto ChampBarActor = RPM<DWORD>(unit + 0x8);
		auto ChampBarActorInstance = RPM<DWORD>(RPM<DWORD>(ChampBarActor + 0x18));
		auto ScaleFactors = RPM<Vector2>(ChampBarActorInstance + 0x64);

		//ENGINE_MSG("Unit %p - ChampBarActorInstance %p - ChampBarActor %p - Scale1 %f Scale2 %f - Sw %d", unit, ChampBarActorInstance, ChampBarActor, ScaleFactors.x, ScaleFactors.y, Game.Width());

		return Vector2(s_width * ScaleFactors.x, (float)s_height * ScaleFactors.y);
	};

	Vector3 HpBarPos(CObject* obj, float custom = 0.f) {
		// E8 ?? ?? ?? ?? 8B 4E ?? 8D 54 ?? ?? 52 8B 01 FF ?? ?? 5E 83 ?? ?? C3
		Vector3 pos = obj->Position();

		auto hpPosz = GetHealthBarPos(obj);

		auto teamOffset = obj->IsAlly() ? Vector2(-9, 14) : Vector2(-9, 17);

		LeagueObfuscationDword typeobf;
		ReadVirtualMemory((void*)((DWORD)obj + offsets_lol.oHPBar_1 - 1), &typeobf, sizeof(LeagueObfuscationDword));


		DWORD dwPtr = decrypt_dword(typeobf);

		DWORD dwBar2 = dwPtr ? RPM<DWORD>(RPM<DWORD>(dwPtr + offsets_lol.oHPBar_dwbar2_1) + offsets_lol.oHPBar_dwbar2_2) : 0;
		float fHPBarOff = RPM<float>(RPM<DWORD>(dwBar2 + offsets_lol.oHPBar_Off_1) + offsets_lol.oHPBar_Off_2) * obj->ObjectScale();

		if (s_width >= 2560)
		{
			teamOffset.x += 247.0f;
		}
		else
		{
			teamOffset.x += 210.0f;
		}

		//BYTE v3 = RPM<BYTE>((DWORD)obj + offsets_lol.oHPBar_1);  //oHPBar_3 = 8B 84 87 ? ? ? ? 89 44 24 08 85 F6 74 17
		//DWORD v33 = RPM<DWORD>((DWORD)obj + 4 * RPM<BYTE>((DWORD)obj + offsets_lol.oHPBar_2) + offsets_lol.oHPBar_3);
		//int v2 = 0;
		//if (v3)
		//{
		//	int* v4 = (int*)((DWORD)obj + offsets_lol.oHPBar_4);
		//	do
		//	{
		//		int v5 = RPM<int>(v4);
		//		++v4;
		//		*(&v33 + (DWORD)v2) ^= ~v5;
		//		++v2;
		//	} while ((unsigned int)v2 < v3);
		//}



		//LeagueObfuscationDword typeobf;
		//ReadVirtualMemory((void*)((DWORD)obj + offsets_lol.oHPBar_1 - 1), &typeobf, sizeof(LeagueObfuscationDword));


		//DWORD dwPtr = decrypt_dword(typeobf);
		//std::cout << std::hex << dwPtr << std::endl;
		//DWORD dwBar2 = dwPtr ? RPM<DWORD>(RPM<DWORD>(dwPtr + offsets_lol.oHPBar_dwbar2_1) + offsets_lol.oHPBar_dwbar2_2) : 0;
		//float fHPBarOff = RPM<float>(RPM<DWORD>(dwBar2 + offsets_lol.oHPBar_Off_1) + offsets_lol.oHPBar_Off_2) * obj->ObjectScale();;

		auto hpPos = pos;
		hpPos.x += custom;
		hpPos.y += fHPBarOff;
		//std::cout << fHPBarOff << std::endl;

		auto w2s = Engine::WorldToScreen(hpPos);

		auto aux1 = RPM<uint32_t>(m_Base + offsets_lol.oZoomClass);

		float fMaxZoom = RPM<float>(aux1 + 0x28);
		//float fMaxZoom = 2250.f;
		float fZoom = RPM<float>(RPM<DWORD>(RPM<DWORD>(m_Base + offsets_lol.oHudInstance) + offsets_lol.oHPBar_Zoom_1) + offsets_lol.oHPBar_Zoom_2);
		float fZoomDelta = fMaxZoom / fZoom;

		w2s.y -= (((s_height) * 0.00083333335f * fZoomDelta) * fHPBarOff);

		if (obj->IsHero())
			return Vector3(hpPosz.x + teamOffset.x - custom, w2s.y, 0);
		else
			return w2s;
	}


	//Vector3 HpBarPos(CObject* obj, actor_struct a) {
	//	Vector3 pos = obj->Position();

	//	auto hpPos = pos;
	//	hpPos.y += a.unitData->healthBarHeight;

	//	auto w2s = Engine::WorldToScreen(hpPos);
	//	float fMaxZoom = 2250.f;
	//	float fZoom = RPM<float>(RPM<DWORD>(RPM<DWORD>(m_Base + offsets_lol.oHudInstance) + 0x0C) + 0x25C);
	//	float fZoomDelta = fMaxZoom / fZoom;

	//	w2s.y -= (((s_height) * 0.00083333335f * fZoomDelta) * a.unitData->healthBarHeight);

	//	return w2s;
	//}

	float GetKsDamage(CObject* t, SpellSlot QWER)
	{
		float totalDmg = GetSpellDamage(me, t, QWER);
		totalDmg -= t->HealthRegen();

		if (totalDmg > t->Health())
		{
			if (me->HasBuff(FNV("summonerexhaust")))
				totalDmg = totalDmg * 0.6f;

			if (t->HasBuff(FNV("ferocioushowl")))
				totalDmg = totalDmg * 0.7f;

			if (t->ChampionNameHash() == FNV("Blitzcrank") && !t->HasBuff(FNV("BlitzcrankManaBarrierCD")) && !t->HasBuff("ManaBarrier"))
			{
				totalDmg -= t->Mana() / 2.f;
			}
		}
		//if (Thunderlord && !Player.HasBuff( "masterylordsdecreecooldown"))
		//totalDmg += (float)Player.CalcDamage(t, Damage.DamageType.Magical, 10 * Player.Level + 0.1 * Player.FlatMagicDamageMod + 0.3 * Player.FlatPhysicalDamageMod);
		// 
		//TO DO
		//totalDmg += (float)GetIncomingDamage(t);

		return totalDmg;
	}

	static bool IsGameEnding()
	{
		auto gamestate = RPM<int>(RPM<DWORD>(m_Base + offsets_lol.oGameClient) + offsets_lol.oGameState);

		return gamestate && gamestate == 3;
	}

	static bool IsChatOpen()
	{
		auto chatstatus = RPM<int>(RPM<DWORD>(m_Base + offsets_lol.oMenuGUI) + oChatOpen);

		return chatstatus && chatstatus != 6;
	}

	std::string GetVersionGarena()
	{
		char nameobj[5];
		std::string s;
		if (ReadVirtualMemory((void*)(m_Base + 0x311D058 + 0x8), &nameobj, 5))
		{
			s = std::string(nameobj);
		}
		return s;
	}

	std::string GetVersionRiot()
	{
		char nameobj[5];
		std::string s;
		if (ReadVirtualMemory((void*)(m_Base + 0x30F5350 + 0x8), &nameobj, 5))
		{
			s = std::string(nameobj);
		}
		return s;
	}

	int GetPing()
	{
		if (!m_CachePing)
		{
			DWORD netClientInstancePtr;
			ReadVirtualMemory((void*)(m_Base + 0x30E9260), &netClientInstancePtr, sizeof(DWORD));

			DWORD unknownAddress1;
			ReadVirtualMemory((void*)(netClientInstancePtr + 0x44), &unknownAddress1, sizeof(DWORD));

			DWORD unknownAddress2;
			ReadVirtualMemory((void*)(unknownAddress1 + 0x4), &unknownAddress2, sizeof(DWORD));

			DWORD unknownAddress3;
			ReadVirtualMemory((void*)(unknownAddress2 + 0x4), &unknownAddress3, sizeof(DWORD));

			networkPingAddress = unknownAddress3 + 0x18 + 0xD8;

			// read cpu client ping value
			DWORD cpuClientInstance;
			ReadVirtualMemory((void*)(m_Base + 0x30E9228), &cpuClientInstance, sizeof(DWORD));

			cpuPingAddress = cpuClientInstance + 0x18;
			m_CachePing = true;
		}

		double netPing;
		ReadVirtualMemory((void*)networkPingAddress, &netPing, sizeof(double));

		double cpuPing;
		ReadVirtualMemory((void*)cpuPingAddress, &cpuPing, sizeof(double));

		global::ping = static_cast<int>((netPing + cpuPing) * 1000.0);

		return global::ping;
	}

	int TickCount()
	{
		return GetTickCount() & INT_MAX;
	}

	float GetLatency()
	{
		return (float)GetPing() / 2000.f;
	}
	int GameTimeTickCount()
	{
		//GameGetTickCount() = RPM<float>(m_Base + oGameTime);
		return RPM<float>(m_Base + offsets_lol.oGameTime) * 1000;
	}
	float GameGetTickCount()
	{
		//GameGetTickCount() = RPM<float>(m_Base + oGameTime);
		return RPM<float>(m_Base + offsets_lol.oGameTime);
	}
	float heightForPosition(float i_rX, float i_rZ)
	{
		float rMaxX = m_rMaxX;
		float rMinX = m_rMinX;

		float rMaxZ = m_rMaxZ;
		float rMinZ = m_rMinZ;

		if (rMaxX < i_rX || i_rX < rMinX)
			return 0;

		if (rMaxZ < i_rZ || i_rZ < rMinZ)
			return 0;

		float rV5 = (float)(i_rZ - rMinZ) / m_rOffset1;
		float rV6 = (float)(i_rX - rMinX) / m_rOffset2;

		signed int iV7 = (signed int)std::floor(rV5);
		signed int iV8 = (signed int)std::floor(rV6);

		int iV9 = iV7;
		int iV30 = iV7;
		static int iV10 = m_dwOffset3 - 1;
		int iV29 = iV9;
		int iV11 = iV8;

		float rV12;
		if (iV8 >= iV10)
		{
			iV11 = iV8 - 1;
			rV12 = 1.0;
		}
		else
		{
			rV12 = rV6 - (float)iV8;
		}

		unsigned __int8 iV14 = __OFSUB__(iV8, iV10);
		bool fV13 = iV8 - iV10 < 0;
		int iV15 = iV8 + 1;
		int iV16 = m_dwOffset4;
		if (!(fV13 ^ iV16))
			iV15 = iV8;
		int iV17 = iV16 - 1;
		float rV18;
		if (iV9 >= iV16 - 1)
		{
			--iV9;
			rV18 = 1.0;
		}
		else
		{
			rV18 = rV5 - (float)iV9;
		}
		int iV19 = iV9 * m_dwOffset3;
		int iV28 = iV19 + iV11;
		int iV20 = iV19 + iV15;
		int iV21 = iV29 + 1;
		iV14 = __OFSUB__(iV29, iV17);
		int iV13 = iV29 - iV17 < 0;
		int iV22 = m_dwOffset3;
		if (!(iV13 ^ iV14))
			iV21 = iV30;
		int iV23 = iV22 * iV21;
		int iV24 = iV22 * iV16;
		int iV25 = iV23 + iV11;
		int iV26 = iV23 + iV15;

		if (iV28 >= iV24 || iV20 >= iV24 || iV25 >= iV24 || iV26 >= iV24)
			return 0;

		DWORD dwOffset5 = m_dwOffset5;

		float rArg1;
		float rArg2;
		float rArg3;
		float rArg4;

		memcpy(&rArg1, m_abHeightBuffer.data() + (4 * iV28), sizeof(float));
		memcpy(&rArg2, m_abHeightBuffer.data() + (4 * iV20), sizeof(float));
		memcpy(&rArg3, m_abHeightBuffer.data() + (4 * iV25), sizeof(float));
		memcpy(&rArg4, m_abHeightBuffer.data() + (4 * iV26), sizeof(float));

		return (float)((float)((float)((float)(rArg1 * (float)(1.0 - rV12))
			+ (float)(rArg2 * rV12))
			* (float)(1.0 - rV18))
			+ (float)((float)((float)(rArg3 * (float)(1.0 - rV12))
				+ (float)(rArg4 * rV12))
				* rV18));
	}
	float heightForPosition(Vector2 pos)
	{
		return heightForPosition(pos.x, pos.y);
	}

	float heightForPosition(Vector3 pos)
	{
		return heightForPosition(pos.x, pos.z);
	}

	Vector3 To3DHigh(Vector2 pos)
	{
		return Vector3(pos.x, heightForPosition(pos), pos.y);
	}

	Vector3 SetHeight(Vector3 pos)
	{
		return Vector3(pos.x, heightForPosition(pos), pos.z);
	}

	bool IsNotWall(float i_rX, float i_rZ, int a222)
	{
		float v2 = m_rOffset6;
		static int v3 = m_dwOffset7;
		int v4; // edx@1
		signed int v5; // edi@1
		int v6; // eax@1
		int v8; // edx@7
		int v9; // eax@8
		__int16 v10; // cx@9
		int v11; // ecx@11


		v4 = v3 - 1;
		v5 = (signed int)floor((float)(i_rZ - m_rMinZ) * v2);
		v6 = (signed int)floor((float)(i_rX - m_rMinX) * v2);
		if (v6 <= v3 - 1)
		{
			v4 = v6;
			if (v6 < 0)
				v4 = 0;
		}
		int v7 = m_dwOffset8 - 1;
		if (v5 <= v7)
		{
			v7 = v5;
			if (v5 < 0)
				v7 = 0;
		}
		DWORD dw1 = m_dwOffset9;
		v8 = dw1 + 8 * (v4 + v7 * v3);
		if (v8)
		{
			char abReadV8[sizeof(DWORD) * 2];
			ReadVirtualMemory((void*)v8, &abReadV8, sizeof(DWORD) * 2);

			DWORD dwReadV8_1;
			DWORD dwReadV8_2;

			memcpy(&dwReadV8_1, abReadV8, sizeof(DWORD));
			memcpy(&dwReadV8_2, abReadV8 + sizeof(DWORD), sizeof(DWORD));

			bool fReadV9 = false;
			DWORD dwReadV9 = 0;

			v9 = dwReadV8_1;
			if (dwReadV8_1)
			{
				fReadV9 = true;
				dwReadV9 = RPM<WORD>(v9 + 6);
				v10 = dwReadV9;
			}
			else
				v10 = dwReadV8_2;

			v11 = v10 & 0xC00;
			if (v11)
			{
				((BYTE*)&v9)[0] = (0 & (unsigned __int16)v11) == (WORD)v11;
			}
			else if (v9)
			{
				if (!fReadV9)
					((BYTE*)&v9)[0] = ~((unsigned __int8)RPM<WORD>(v9 + 6) >> 1) & 1;
				else
					((BYTE*)&v9)[0] = ~((unsigned __int8)dwReadV9 >> 1) & 1;
			}
			else
			{
				v9 = ~((unsigned __int8)dwReadV8_2 >> 1) & 1;
			}
		}
		else
		{
			((BYTE*)&v9)[0] = 0;
		}
		return v9;
	}

	bool IsNotWall(Vector3 i_oPosition)
	{
		return IsNotWall(i_oPosition.x, i_oPosition.z, 0);
	}

	bool IsNotWall(Vector2 i_oPosition)
	{
		return IsNotWall(i_oPosition.x, i_oPosition.y, 0);
	}

	bool IsWall(float i_rX, float i_rZ)
	{
		return !IsNotWall(i_rX, i_rZ, 0);
	}

	bool IsWall(Vector3 i_oPosition)
	{
		return !IsNotWall(i_oPosition);
	}

	bool IsWall(Vector2 i_oPosition)
	{
		return !IsNotWall(i_oPosition);
	}

	//float AttackDelayLastHit(CObject* source)
	//{
	//	return me->GetAttackDelay();
	//	//return (1.f / source->AttackSpeedRaw());// BaseWindUp ? 1.f / (me->AttackSpeed() * BaseWindUp) : Engine::GetAttackCastDelay();
	//}

	//float AttackCastDelayLastHit(CObject* source)
	//{
	//	if (source == me)
	//		return (1.f / source->AttackSpeedRaw()) * global::LocalData->basicAttackWindup;// BaseWindUp ? 1.f / (me->AttackSpeed() * BaseWindUp) : Engine::GetAttackCastDelay();
	//	else
	//	{
	//		return (1.f / source->AttackSpeedRaw()) * global::Units[ToLower(source->ChampionName())]->basicAttackWindup;// BaseWindUp ? 1.f / (me->AttackSpeed() * BaseWindUp) : Engine::GetAttackCastDelay();
	//	}
	//}

	//float AttackCastDelay()
	//{
	//	//std::cout << "AttackCastDelay " << (1.f / me->AttackSpeed()) * global::LocalData->basicAttackWindup << std::endl;
	//	return (1.f / me->AttackSpeed()) * global::LocalData->basicAttackWindup;// BaseWindUp ? 1.f / (me->AttackSpeed() * BaseWindUp) : Engine::GetAttackCastDelay();
	//}

	bool IsCastingInterruptableSpell(CObject* player)
	{
		switch (global::LocalChampNameHash)
		{
		case FNV("Xerath"):
			return player->HasBuff(FNV("XerathLocusOfPower2"));
		case FNV("Jhin"):
			return player->GetSpellBook()->GetSpellSlotByID(3)->GetSpellData()->GetSpellNameHash() == FNV("JhinRShot");
		default:
			break;
		}
		return false;
	}

	void DisableMove(bool state)
	{
		if (isDisableMove != state)
		{
			DWORD HudPtr = (DWORD)m_Base + offsets_lol.oLocalPlayer;
			auto aux1 = RPM<uint32_t>(HudPtr);
			aux1 += oDisableMove;

			WPM<bool>(aux1, state);
			isDisableMove = state;
		}
	}

	bool SetTargetOnlyChampions(bool state)
	{
		if (state)
			KeyDown(VK_KEY_I);
		else
			KeyUp(VK_KEY_I);

		if (isTargetChampOnly != state)
		{
			DWORD HudPtr = (DWORD)m_Base + offsets_lol.oHudInstance;
			auto aux1 = RPM<uint32_t>(HudPtr);
			aux1 += 0x30;
			auto aux2 = RPM<uint32_t>(aux1);
			aux2 += 0x1c;

			WPM<bool>(aux2, state);
			isTargetChampOnly = state;
		}


		return true;
	}

	bool ZoomHack()
	{
		DWORD HudPtr = (DWORD)m_Base + offsets_lol.oZoomClass;
		auto aux1 = RPM<uint32_t>(HudPtr);
		aux1 += 0x28;
		float zoommax = RPM<float>(aux1);
		//printf("zoommax1: %f", zoommax);

		if (zoommax < 2251.f)
		{

			WPM<float>(aux1, 4445.f);

		}

		return true;
	}

	Vector3 GetMouseWorldPosition()
	{
		DWORD HudPtr = (DWORD)m_Base + offsets_lol.oHudInstance;
		auto aux1 = RPM<uint32_t>(HudPtr);
		aux1 += 0x14;
		auto aux2 = RPM<uint32_t>(aux1);

		aux2 += 0x1C;


		if (global::mousereset)
			oldMouse = RPM<Vector3>(aux2);

		return oldMouse;
	}

	void SetMouseWorldPosition(Vector3 kek)
	{
		DWORD HudPtr = (DWORD)m_Base + offsets_lol.oHudInstance;
		auto aux1 = RPM<uint32_t>(HudPtr);
		aux1 += 0x14;
		auto aux2 = RPM<uint32_t>(aux1);
		auto cac = aux2 + 0x10;
		auto cac2 = aux2 + 0x1C;
		//Vector3 kek = Vector3(7183.49, 54.2378, 7089.73);
		WPM<Vector3>(cac, kek);
		WPM<Vector3>(cac2, kek);
	}

	Vector2 GetMouseWorldPosition2D()
	{
		GetMouseWorldPosition();

		return Vector2(oldMouse.x, oldMouse.z);
	}

	std::vector<Vector3> CirclePointsEX(Vector3 vector3_0)
	{
		std::vector<Vector3> list;
		for (int i = 1; i <= 15; i++)
		{
			double num = static_cast<double>(i * 2) * M_PI / 15.0;
			Vector3 item = Vector3(vector3_0.x + 350.0f * static_cast<float>(std::cos(num)), vector3_0.y + 350.0f * static_cast<float>(std::sin(num)), vector3_0.z);
			list.push_back(item);


		}
		return list;
	}

	std::vector<Vector3> CirclePoints(float CircleLineSegmentN, float radius, Vector3 position)
	{
		std::vector<Vector3> points = {};
		for (int i = 1; i <= CircleLineSegmentN; i++)
		{
			auto angle = i * 2 * M_PI / CircleLineSegmentN;
			auto point = Vector3(position.x + radius * (float)fastcos(angle), position.y, position.z + radius * (float)fastsin(angle));
			points.push_back(point);
		}
		return points;
	}

	std::vector<CObject*> GetJunglesAround(float range, int type = 1) // type 1 = large & epic , type 2 = all
	{
		std::vector<CObject*> jungles = {};

		const auto pListSize = RPM<uint32_t>(global::MinionManager + 0xC);
		std::vector<DWORD> objarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::MinionManager + 0x4), objarray.data(), pListSize * sizeof(DWORD));

		for (auto jungle : objarray)
		{
			if (jungle != 0)
			{
				auto actor = (CObject*)jungle;

				if ((type == 1 && (actor->IsNormalMonster() || actor->IsLargeMonster() || actor->IsEpicMonster())) || (type == 2))
				{
					if (actor->Team() == 300 && actor->IsValidTarget() && actor->Health() > 0 && actor->MaxHealth() > 5 && me->Position().Distance(actor->Position()) <= range)
					{
						jungles.push_back(actor);
					}
				}
			}
		}

		return jungles;
	}


	std::vector<CObject*> GetJungles(int type = 1) // type 1 = large & epic , type 2 = all
	{
		std::vector<CObject*> jungles = {};

		const auto pListSize = RPM<uint32_t>(global::MinionManager + 0xC);
		std::vector<DWORD> objarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::MinionManager + 0x4), objarray.data(), pListSize * sizeof(DWORD));

		for (auto jungle : objarray)
		{
			if (jungle != 0)
			{
				auto actor = (CObject*)jungle;

				if ((type == 1 && (actor->IsNormalMonster() || actor->IsLargeMonster() || actor->IsEpicMonster())) || (type == 2))
				{
					if (actor->Team() == 300 && actor->IsValidTarget() && actor->Health() > 0 && actor->MaxHealth() > 5)
					{
						jungles.push_back(actor);
					}
				}
			}
		}

		return jungles;
	}

	std::vector<CObject*> GetObjects() // type 1 = large & epic , type 2 = all
	{
		std::vector<CObject*> objects = {};

		const auto pListSize = RPM<uint32_t>(global::Objmanager + 0x2C);
		std::vector<DWORD> objarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::Objmanager + 0x14), objarray.data(), pListSize * sizeof(DWORD));

		for (auto object : objarray)
		{
			auto actor = (CObject*)object;
			objects.push_back(actor);
		}

		return objects;
	}

	std::vector<CObject*> GetInhib() // type 1 = large & epic , type 2 = all
	{
		std::vector<CObject*> inhibs = {};

		const auto pListSize = RPM<uint32_t>(global::Attackable_Unit + 0xC);
		std::vector<DWORD> objarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::Attackable_Unit + 0x4), objarray.data(), pListSize * sizeof(DWORD));

		for (auto inhib : objarray)
		{
			if (inhib != 0)
			{
				auto actor = (CObject*)inhib;
				if (strstr(actor->Name().c_str(), "Barracks") != NULL)
				{
					inhibs.push_back(actor);
				}
			}
		}

		return inhibs;
	}

	std::vector<CObject*> GetTurrets(int type = 0)
	{
		std::vector<CObject*> AIBases = {};

		for (auto turret_actor : global::turrets)
		{
			auto turret = (CObject*)turret_actor;
			if (turret->IsAlive() && (type == 1 && turret->IsEnemy() || type == 2 && turret->IsAlly() || type == 0))
				AIBases.push_back(turret);
		}

		return AIBases;
	}

	bool UnderTurret(Vector3 position)
	{
		for (auto turret_actor : global::turrets)
		{
			auto turret = (CObject*)turret_actor;
			if (turret->IsAlly() || !turret->IsAlive())
				continue;

			if (turret->Position().IsInRange(position, 950.f))
				return true;
		}
		return false;
	}

	bool UnderAllyTurret(Vector3 position)
	{
		for (auto turret_actor : global::turrets)
		{
			auto turret = (CObject*)turret_actor;
			if (turret->IsEnemy() || !turret->IsAlive())
				continue;

			if (turret->Position().IsInRange(position, 950.f))
				return true;
		}

		return false;
	}

	std::vector<CObject*> GetAIBasesAround(float range)
	{
		std::vector<CObject*> AIBases = {};

		auto pListSize = RPM<uint32_t>(global::AIBases + 0xC);
		std::vector<DWORD> objarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::AIBases + 0x4), objarray.data(), pListSize * sizeof(DWORD));

		for (auto aibase : objarray)
		{
			if (aibase)
			{
				AIBases.push_back((CObject*)aibase);
			}
		}
		return AIBases;
	}

	//type 1 = Enemy, 2 = ally, 3 = all

	/*std::vector<CObject*> GetMinionsAround(float range, int type, Vector3 position = Vector3::Zero)
	{
		std::vector<CObject*> minions = {};

		auto pListSize = RPM<uint32_t>(global::MinionManager + 0xC);
		std::vector<DWORD> objarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::MinionManager + 0x4), objarray.data(), pListSize * sizeof(DWORD));

		for (auto actor : objarray)
		{
			if (actor)
			{
				auto minion = (CObject*)actor;
				if (position.IsValid() ? position.Distance(minion->Position()) <= range : me->Distance(minion) <= range
					&& ((type == 1 && minion->IsEnemy()) || (type == 2 && minion->IsAlly()) || type == 3))

				{
					minions.push_back(minion);
				}
			}
		}
		return minions;
	}*/

	bool CanMove(CObject* target)
	{
		if ((!target->IsWindingUp() && target->IsRooted() && !target->CanMove()) || target->MoveSpeed() < 50 || target->IsStunned() || target->GetBuffManager()->IsImmobile())
		{
			return false;
		}
		else
			return true;
	}

	std::vector<CObject*> GetPetsAround(float range, Vector3 position = Vector3::Zero)
	{
		std::vector<uint32_t> minionlist = {};

		minionlist = Cache::ObjectListMinion;

		std::vector<CObject*> minions = {};
		for (auto actor : minionlist)
		{
			auto minion = (CObject*)actor;
			if (position.IsValid() ? position.Distance(minion->Position()) <= range : me->Distance(minion) <= range && minion->IsAlive())
			{
				minions.push_back(minion);
			}
		}

		return minions;
	}

	/*std::vector<CObject*> GetMinionsAround(float range, int type = 1, Vector3 position = Vector3::Zero)
	{
		std::vector<uint32_t> minionlist = {};
		if (type == 1)
			minionlist = Cache::MinionsListEnemy;
		if (type == 2)
			minionlist = Cache::MinionsListAlly;
		if (type == 3)
			minionlist = Cache::AllMinionsObj;

		std::vector<CObject*> minions = {};
		for (auto actor : minionlist)
		{
			auto minion = (CObject*)actor;
			if (position.IsValid() ? position.Distance(minion->Position()) <= range : me->Distance(minion) <= range && minion->IsAlive())
			{
				minions.push_back(minion);
			}
		}

		return minions;
	}

	std::vector<CObject*> GetMinions(int type = 1)
	{
		std::vector<uint32_t> minionlist = {};
		if (type == 1)
			minionlist = Cache::MinionsListEnemy;
		if (type == 2)
			minionlist = Cache::MinionsListAlly;
		if (type == 3)
			minionlist = Cache::AllMinionsObj;

		std::vector<CObject*> minions = {};
		for (auto actor : minionlist)
		{
			auto minion = (CObject*)actor;
			if (minion->IsAlive())
				minions.push_back(minion);
		}

		return minions;
	}*/

	std::vector<CObject*> GetMinionsAround(float range, int type = 1, Vector3 position = Vector3::Zero) // type 1 = large & epic , type 2 = all
	{
		std::vector<CObject*> minions = {};

		const auto pListSize = RPM<uint32_t>(global::MinionManager + 0xC);
		std::vector<DWORD> objarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::MinionManager + 0x4), objarray.data(), pListSize * sizeof(DWORD));

		for (auto minion : objarray)
		{
			if (minion != 0)
			{
				auto actor = (CObject*)minion;

				if (type == 1 && actor->IsEnemy() && actor->IsLaneMinion() && actor->IsValidTarget() || type == 2 && actor->IsAlly() && actor->IsLaneMinion() || type == 3 && actor->IsLaneMinion())
				{
					if (actor->Health() > 0 && actor->MaxHealth() > 5 && position.IsValid() ? position.Distance(actor->Position()) <= range : me->Distance(actor) <= range)
					{
						minions.push_back(actor);
					}
				}
			}
		}

		return minions;
	}


	std::vector<CObject*> GetMinions(int type = 1) // type 1 = large & epic , type 2 = all
	{

		std::vector<CObject*> minions = {};

		const auto pListSize = RPM<uint32_t>(global::MinionManager + 0xC);
		std::vector<DWORD> objarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::MinionManager + 0x4), objarray.data(), pListSize * sizeof(DWORD));

		for (auto minion : objarray)
		{
			if (minion != 0)
			{
				auto actor = (CObject*)minion;

				if (type == 1 && actor->IsEnemy() && actor->IsLaneMinion() && actor->IsValidTarget() || type == 2 && actor->IsAlly() && actor->IsLaneMinion() || type == 3 && actor->IsLaneMinion())
				{
					if (actor->Health() > 0 && actor->MaxHealth() > 5)
					{
						minions.push_back(actor);
					}
				}
			}
		}

		return minions;
	}


	std::vector<CObject*> GetHerosAround(float range, int type = 1, Vector3 position = Vector3::Zero)
	{
		std::vector<actor_struct> herolist = {};
		if (type == 1)
			herolist = global::enemyheros;
		if (type == 2)
			herolist = global::allyheros;
		if (type == 3)
			herolist = global::heros;

		std::vector<CObject*> actors = {};

		for (auto actor : herolist)
		{
			auto enemy = (CObject*)actor.actor;

			if ((type == 1 && enemy->IsValidTarget()) || (type == 2 && enemy->IsAlive()) || type == 3)
			{
				if (position.IsValid() ? position.Distance(enemy->Position()) <= range : me->Distance(enemy) <= range)
				{
					actors.push_back(enemy);
				}
			}
		}

		return actors;
	}

	std::vector<CObject*> GetHeros(int type = 1)
	{
		std::vector<actor_struct> herolist = {};
		if (type == 1)
			herolist = global::enemyheros;
		if (type == 2)
			herolist = global::allyheros;
		if (type == 3)
			herolist = global::heros;

		std::vector<CObject*> actors = {};

		for (auto actor : herolist)
		{
			auto enemy = (CObject*)actor.actor;

			if ((type == 1 && enemy->IsValidTarget()) || (type == 2 && enemy->IsAlive()) || type == 3)
			{
				actors.push_back(enemy);
			}
		}

		return actors;
	}

	int GetEnemyCount(float range, Vector3 pos)
	{
		int count = 0;
		for (auto actora : global::enemyheros)
		{
			if (IsValid(actora.actor))
			{
				CObject* actor = (CObject*)actora.actor;
				if (actor)
				{
					if (pos.IsInRange(actor->Position(), range) && actor->IsValidTarget())
					{
						count = count + 1;
					}
				}
			}
		}

		return count;
	}

	int GetMinionCount(float range, Vector3 pos)
	{
		return GetMinionsAround(range, 1, pos).size();
	}


	bool ActorCacheContains(std::vector<uint32_t> list, uint32_t actorcheck)
	{
		bool skip = false;
		if ((list.size() > 0) && (list.size() != 0))
		{
			for (int i = 0; i < list.size();)
			{
				auto Actor = list[i];

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

	bool WardCacheContains(std::vector<ward_struct> list, uint32_t actorcheck)
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


	bool CompareTo(float x, float y) {
		if (fabs(x - y) < FLT_EPSILON)
			return true;
		return false;
	}

	ProjectionInfo ProjectOn(Vector2 point, Vector2 segmentStart, Vector2 segmentEnd)
	{
		auto cx = point.x;
		auto cy = point.y;
		auto ax = segmentStart.x;
		auto ay = segmentStart.y;
		auto bx = segmentEnd.x;
		auto by = segmentEnd.y;
		auto rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay))
			/ ((float)pow(bx - ax, 2) + (float)pow(by - ay, 2));
		auto pointLine = Vector2(ax + rL * (bx - ax), ay + rL * (by - ay));
		float rS;
		if (rL < 0)
		{
			rS = 0;
		}
		else if (rL > 1)
		{
			rS = 1;
		}
		else
		{
			rS = rL;
		}

		auto isOnSegment = CompareTo(rS, rL);// rS.CompareTo(rL) == 0;
		auto pointSegment = isOnSegment ? pointLine : Vector2(ax + rS * (bx - ax), ay + rS * (by - ay));
		return ProjectionInfo({ isOnSegment, pointSegment, pointLine });
	}

	ProjectionInfo3D ProjectOn(Vector3 point, Vector3 segmentStart, Vector3 segmentEnd)
	{
		auto cx = point.x;
		auto cy = point.z;
		auto ax = segmentStart.x;
		auto ay = segmentStart.z;
		auto bx = segmentEnd.x;
		auto by = segmentEnd.z;
		auto rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay))
			/ ((float)pow(bx - ax, 2) + (float)pow(by - ay, 2));
		auto pointLine = Vector2(ax + rL * (bx - ax), ay + rL * (by - ay));
		float rS;
		if (rL < 0)
		{
			rS = 0;
		}
		else if (rL > 1)
		{
			rS = 1;
		}
		else
		{
			rS = rL;
		}

		auto isOnSegment = CompareTo(rS, rL);// rS.CompareTo(rL) == 0;
		auto pointSegment = isOnSegment ? pointLine : Vector2(ax + rS * (bx - ax), ay + rS * (by - ay));
		return ProjectionInfo3D({ isOnSegment, Vector3(pointSegment.x,Engine::heightForPosition(pointSegment),pointSegment.y), Vector3(pointLine.x,Engine::heightForPosition(pointLine),pointLine.y) });
	}
	/*void cachewards()
	{
		std::vector<CObject*> attackable = {};

		auto pListSize = RPM<uint32_t>(global::Attackable_Unit + 0xC);
		std::vector<DWORD> objattackarray(pListSize);
		ReadVirtualMemory((void*)RPM<uint32_t>(global::Attackable_Unit + 0x4), objattackarray.data(), pListSize * sizeof(DWORD));

		for (auto attackable : objattackarray)
		{
			if (attackable != 0)
			{
				CObject* actor = (CObject*)attackable;
				if (actor->IsEnemy())
				{
					auto type = actor->GetSkinData()->GetSkinHash();
					if (actor->IsWard())
					{
						ward_struct wardstrt;
						wardstrt.actor = attackable;

						if (type == SkinHash::YellowTrinket || type == SkinHash::SightWard)
						{
							wardstrt.hash = (uint32_t)type;
							wardstrt.type = 1.f;
						}

						if (type == SkinHash::JammerDevice)
						{
							wardstrt.type = 2.f;
						}

						if (type == SkinHash::BlueTrinket)
						{
							wardstrt.type = 3.f;
						}

						wardstrt.position = actor->Position();

						if (!WardCacheContains(global::wards, attackable))
							global::wards.push_back(wardstrt);

					}
				}
			}
		}
	}*/
}