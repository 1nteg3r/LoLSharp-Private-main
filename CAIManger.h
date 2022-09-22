#pragma once
#include "Offsets.h"
#include <Windows.h>
#include "lol_reclass.h"
#include "Macros.h"
class CAIManager {

public:
	MAKE_DATA(DWORD, pStart, 0x10);
	MAKE_DATA(DWORD, pEnd, 0x14);

	MAKE_DATA(int, PassedWaypoints, O_AIMGR_PASSED_WAYPOINTS);
	MAKE_DATA(bool, IsMoving, O_AIMGR_ISMOVING);
	MAKE_DATA(bool, IsDashing, O_AIMGR_ISDASHING);
	MAKE_DATA(float, DashSpeed, O_AIMGR_DASHSPEED);
	MAKE_DATA(Vector3, LastClickPosition, O_AIMGR_TARGETPOS);
	MAKE_DATA(Vector3, CurrentPosition, O_AIMGR_CURRENTPOS);
	MAKE_DATA(Vector3, Velocity, O_AIMGR_VELOCITY);
	MAKE_DATA(DWORD, GetNavBegin, O_AIMGR_NAVBEGIN);
	MAKE_DATA(DWORD, GetNavEnd, O_AIMGR_NAVEND);
	MAKE_DATA(Vector3, StartPosition, 0x1CC);
	MAKE_DATA(Vector3, EndPosition, 0x1D8);

	uint32_t getWayPointListSize()
	{
		return GetNavEnd();
	}

	/*uint32_t getNumWayPoints()
	{
		return getWayPointListSize() / 0xC;
	}*/

//	std::vector<Vector3> getPathList() {
//		std::vector<Vector3> test;
//
//		auto ppNavStart = this->GetNavBegin();
//		auto ppNavEnd = this->GetNavEnd();
//		auto pPathList = ppNavStart;
//
//
//		for (auto pNavPtr = ppNavStart; pNavPtr != ppNavEnd; pNavPtr++)
//			//for (DWORD pNavPtr = this->pStart; pNavPtr != this->pEnd; pNavPtr += 0x4)
//		{
//			auto pNav = pNavPtr;
//			//if (pNav)
//			//{
//				//render->DrawTxtW2S(*pNav, "green", 15, "current");
////CLogger::GetLogger()->Log("CURRENT: %f , %f , %f \n", pNav->X, pNav->Y, pNav->Z);
//			//}
//			//auto pathsz = *(Vector * *)ppNavStart;
//			auto pNavNext = pNav + 1;
//			if (pNavNext)
//				//{
//					//render->DrawTxtW2S(*pNavNext, "yellow", 15, "current");
//					/*if (bModuleDebug)
//					CLogger::GetLogger()->Log("NEXT: %f , %f , %f \n", pNavNext->X, pNavNext->Y, pNavNext->Z);*/
//					//}
//					//auto pNavEnd = *(Vector * *)ppNavEnd;
//					//if (pNavEnd)
//					//{
//						//render->DrawTxtW2S(*pNavEnd, "red", 15, "current");
//						//CLogger::GetLogger()->Log("END: %f , %f , %f \n", pNavEnd->X, pNavEnd->Y, pNavEnd->Z);
//					//}
//				if (!pNav)
//					continue;
//
//			if (pNav) {
//				//render->DrawTxtW2S(Vector{ pNav->X, pNav->Y, pNav->Z }, "green", 2, "%f , %f , %f \n", pNav->X, pNav->Y, pNav->Z);
//				//if (bModuleDebug)
//				//CLogger::GetLogger()->Log("%f , %f , %f \n", pNav->X, pNav->Y, pNav->Z);
//
//				test.push_back(RPM<Vector3>(pNav));
//			}
//		}
//		return test;
//	}

	//	std::vector<Vec3> getPathList() {
	//		std::vector<Vec3> test;
	//
	//		auto ppNavStart = *(Vector**)this->GetNavBegin();
	//		auto ppNavEnd = *(Vector**)this->GetNavEnd();
	//		auto pPathList = *(Vector**)ppNavStart;
	//
	//
	//		for (auto pNavPtr = ppNavStart; pNavPtr != ppNavEnd; pNavPtr++)
	//			//for (DWORD pNavPtr = this->pStart; pNavPtr != this->pEnd; pNavPtr += 0x4)
	//		{
	//			auto pNav = pNavPtr;
	//			//if (pNav)
	//			//{
	//				//render->DrawTxtW2S(*pNav, "green", 15, "current");
	////CLogger::GetLogger()->Log("CURRENT: %f , %f , %f \n", pNav->X, pNav->Y, pNav->Z);
	//			//}
	//			//auto pathsz = *(Vector * *)ppNavStart;
	//			auto pNavNext = pNav + 1;
	//			if (pNavNext)
	//				//{
	//					//render->DrawTxtW2S(*pNavNext, "yellow", 15, "current");
	//					/*if (bModuleDebug)
	//					CLogger::GetLogger()->Log("NEXT: %f , %f , %f \n", pNavNext->X, pNavNext->Y, pNavNext->Z);*/
	//					//}
	//					//auto pNavEnd = *(Vector * *)ppNavEnd;
	//					//if (pNavEnd)
	//					//{
	//						//render->DrawTxtW2S(*pNavEnd, "red", 15, "current");
	//						//CLogger::GetLogger()->Log("END: %f , %f , %f \n", pNavEnd->X, pNavEnd->Y, pNavEnd->Z);
	//					//}
	//				if (!pNav)
	//					continue;
	//
	//			if (pNav) {
	//				//render->DrawTxtW2S(Vector{ pNav->X, pNav->Y, pNav->Z }, "green", 2, "%f , %f , %f \n", pNav->X, pNav->Y, pNav->Z);
	//				//if (bModuleDebug)
	//				//CLogger::GetLogger()->Log("%f , %f , %f \n", pNav->X, pNav->Y, pNav->Z);
	//
	//				test.push_back(pNav);
	//			}
	//		}
	//		return test;
	//	}

	float PathLength(std::vector<Vector3*>path)
	{
		auto distance = 0.0f;

		for (auto i = 0; i < path.size() - i > 0 ? 1 : 0; i++)
		{
			if (path[i]->x <= 0)
				continue;

			distance += (*path[i]).Distance(*path[i + 1]);
		}
		return distance;
	}

	float AveragePathLength(std::vector<Vector3*>path)
	{
		auto distance = 0.0f;

		for (auto i = 0; i < path.size() - i > 0 ? 1 : 0; i++)
		{
			if (path[i]->x <= 0)
				continue;

			distance += (*path[i]).Distance(*path[i + 1]);
		}
		return distance / path.size();
	}

};