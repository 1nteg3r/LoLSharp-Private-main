#pragma once
auto mPos = Vector2::Zero;

bool sortableEvadeDefault(Vector2 a, Vector2 b)
{
	return a.Distance(me->Pos2D()) < b.Distance(me->Pos2D());
}

bool sortableEvadeMouse(Vector2 a, Vector2 b)
{
	return a.Distance(mPos) < b.Distance(mPos);
}

bool sortablePathEvade(Vector2 a, Vector2 b)
{
	return me->Pos2D().Distance(a) < me->Pos2D().Distance(b);
}


struct FoundIntersection
{
	Vector2 ComingFrom;
	float Distance;
	Vector2 Point;
	int Time;
	bool Valid;
};

struct SafePathResult
{
	FoundIntersection Intersection;
	bool IsSafe;
};

class JustEvade : public ModuleManager {
public:
	bool Evading = false;
	bool Block = false;
	bool InDangerousZone = true;
	float Bounding = 65.f;
	bool PathMoveBlock = false;
	Vector2 ExtendedSafePos;
	Vector2 SafePos;
	Vector2 LastSafePos;
	float DodgeTimer;


	float OldTimer;
	float NewTimer;

	CheckBox* SmoothEvade;
	List* Evademode;
	Slider* CQ;
	Slider* DS;
	Slider* DC;

	KeyBind* HoldEvade;
	KeyBind* Evade;
	CheckBox* BlockAttack;
	CheckBox* ComboMode;
	CheckBox* UseDodgeSpells;
	CheckBox* UseDodgeFlash;
	CheckBox* TrackPaths;
	CheckBox* DrawSpell;
	CheckBox* DrawSpellFilled;
	CheckBox* Status;
	CheckBox* DrawSafePos;
	CheckBox* SandBox;
	KeyBind* DD;

	JustEvade()
	{

	}

	~JustEvade()
	{

	}
	float sandboxTimer = 0;

	void CreateSandboxSpells()
	{
		float frequency = 4;
		float offset = 100;
		float delay = 0.25;
		float angle = 90;
		float width = 70;
		float range = 1115;
		float speed = 1800;
		auto list = Engine::GetHeros(1);
		if (list.size() > 0 && Engine::GameGetTickCount() > sandboxTimer)
		{
			sandboxTimer = Engine::GameGetTickCount() + 2 / frequency;

			auto intercept =
				me->Position() +
				((float)(rand() % 10) / 10) * 100 * Vector3(1, 0, 1).Rotated(((float)(rand() % 10) / 10) * 2 * M_PI);

			//auto intercept = Vector3(7183.49, 53.1878, 7089.73);


			Vector3 startPos = Vector3::Zero;
			Vector3 endPos = Vector3::Zero;

			auto diff = 1000 / 2 * Vector3(1, 0, 1).Rotated(((float)(rand() % 10) / 10) * 2 * M_PI);

			//auto diff = Vector3(-698.401, 0, -815.018);


			/*startPos = intercept + diff;
			endPos = intercept - diff;*/

			startPos = list.front()->Position();
			endPos = intercept - diff;

			endPos = startPos.Extended(endPos, 1200);
			Geometry::Polygon path;
			Geometry::Polygon path2;

			path = XPolygon::RectangleToPolygon(XPolygon::To2D(startPos), XPolygon::To2D(endPos), width, global::LocalData->gameplayRadius);
			path2 = XPolygon::RectangleToPolygon(XPolygon::To2D(startPos), XPolygon::To2D(endPos), width, 0);

			/*path = XPolygon::CircleToPolygon(XPolygon::To2D(endPos), width + global::LocalData->gameplayRadius, 20);
			path2 = XPolygon::CircleToPolygon(XPolygon::To2D(endPos), width, 20);*/
			structspell_evade dataToAdd;
			dataToAdd.type = "linear";
			dataToAdd.cc = true;
			dataToAdd.danger = 1;
			dataToAdd.collision = true;
			dataToAdd.windwall = true;

			AddSpell(0, 0, path, path2, startPos, endPos, endPos, dataToAdd, speed, range, delay, width, "RocketGrab", me->Position().y, sandboxTimer, true, true, false);

		}
	}


	void Init()
	{
		auto menu = NewMenu::CreateMenu("Evade", "Evade");
		auto coreSettings = menu->AddMenu("Core", "Core Settings");
		SmoothEvade = coreSettings->AddCheckBox("SmoothEvade", "Enable Smooth Evading", true);
		Evademode = coreSettings->AddList("Mode", "Evade mode :",
			std::vector<std::string> {"Humanizer", "Max power" }, 0);
		CQ = coreSettings->AddSlider("CQ", "Circle Segments Quality", 16, 10, 25, 1);
		DS = coreSettings->AddSlider("DS", "Diagonal Search Step", 20, 5, 100, 5);
		DC = coreSettings->AddSlider("DC", "Diagonal Points Count", 4, 1, 8, 1);

		auto mainSettings = menu->AddMenu("Main", "Main Settings");

		HoldEvade = mainSettings->AddKeyBind("PD", "Hold to Evade", VK_CAPITAL, false, false);
		Evade = mainSettings->AddKeyBind("Evade", "Enable Evade", VK_KEY_K, true, true);

		BlockAttack = mainSettings->AddCheckBox("Block", "Block Attack", true);
		ComboMode = mainSettings->AddCheckBox("ComboMode", "Combo Mode", true);
		ComboMode->AddTooltip("Max Power when holding Combo key");

		UseDodgeSpells = mainSettings->AddCheckBox("Dodge", "Use Dodge Spells", true);
		UseDodgeFlash = mainSettings->AddCheckBox("Flash", "Use Flash", false);
		TrackPaths = mainSettings->AddCheckBox("EvadePath", "Track Paths", true);
		DrawSpell = mainSettings->AddCheckBox("DrawSpell", "Draw Spells", true);
		DrawSpellFilled = mainSettings->AddCheckBox("DrawSpellFilled", "Draw Filled Spells", false);
		Status = mainSettings->AddCheckBox("Status", "Draw Evade Status", true);
		DrawSafePos = mainSettings->AddCheckBox("DrawSafePos", "Draw Safe Position", true);

		DD = mainSettings->AddKeyBind("DD", "Dodge Only Dangerous", 'N', false, true);

		auto spellSettings = menu->AddMenu("Spell", "Spell Settings");
		SandBox = menu->AddCheckBox("SandBox", "Simulate Spells", false);

		for (auto pActor : global::enemyheros)
		{
			CObject* actor = (CObject*)pActor.actor;
			auto menu1 = spellSettings->AddMenu(pActor.name.c_str(), pActor.name.c_str());
			std::unordered_map<std::string, structspell>::iterator it;
			for (it = SpellDatabaseTest[pActor.namehash].begin(); it != SpellDatabaseTest[pActor.namehash].end(); it++)
			{
				auto name = it->first;
				auto data = it->second;
				std::string menustring = name + "Menu";
				auto menu2 = menu1->AddMenu(menustring.c_str(), name.c_str());
				SpellDatabase[fnv::hash_runtime(name.c_str())].allowdodge = menu2->AddCheckBox(name.c_str(), "Dodge", true, [&](CheckBox* checkbox, int value) {
					SpellDatabase[fnv::hash_runtime(checkbox->Name)].allowdodge = value;
					})->Value;
				SpellDatabase[fnv::hash_runtime(name.c_str())].allowdraw = menu2->AddCheckBox(name.c_str(), "Draw", true, [&](CheckBox* checkbox, int value) {
					SpellDatabase[fnv::hash_runtime(checkbox->Name)].allowdraw = value;
					})->Value;
			}
		}

		//auto spellSettings = menu->AddMenu("Spells", "Spell Settings");


		std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
		std::cout << "Evade Loaded" << std::endl;
		sandboxTimer = Engine::GameGetTickCount();

	}
	std::string MissileName(DWORD missile, int type = 0) // 1 = lowercase , 2 nospace
	{
		char nameobj[0x20];
		char chartest[0xC];
		std::string s;
		if (ReadVirtualMemory((void*)(missile + oObjName), &chartest, sizeof(chartest)))
		{
			if (strstr(chartest, "Object") != NULL)
			{
				uint32_t pointer = RPM<uint32_t>(missile + oObjName);
				if (ReadVirtualMemory((void*)(pointer), &nameobj, sizeof(nameobj)))
				{
					s = std::string(nameobj);
				}
			}
			else
			{
				if (ReadVirtualMemory((void*)(missile + oObjName), &nameobj, sizeof(nameobj)))
				{
					s = std::string(nameobj);
				}
			}

			if (type == 1)
			{
				std::transform(s.begin(),
					s.end(),
					s.begin(),
					[](unsigned char const& c) {
						return ::tolower(c);
					});
			}
			else if (type == 2)
			{
				s.erase(std::remove(s.begin(), s.end(), ' '), s.end());
			}
		}
		ZeroMemory(nameobj, 0x20);
		ZeroMemory(chartest, 6);
		return s;
	}

	void LoopMissileMap()
	{
		int objectManager = RPM<uint32_t>(m_Base + offsets_lol.oTemplateManager_MissleMap);
		global::_missileLaunched = false;

		static char buff[0x500];
		ReadVirtualMemory((void*)objectManager, buff, 0x100);

		int ObjectMapCount = 0x8;
		int ObjectMapRoot = 0x4;
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
		//while (reads < maxObjectsMissile && nodesToVisit.size() > 0) {
		while (nodesToVisit.size() > 0 && visitedNodes.size() < numMissiles * 2)
		{
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

			bool skipObject = false;

			for (int j = 0; j < global::missiles.size(); j++)
			{
				if (global::missiles[j].netId == netId || global::missiles[j].actor == addr)
				{
					skipObject = true;
					break;
				}
			}

			if (global::blacklistedObjects.find(netId) != global::blacklistedObjects.end() || skipObject)
				continue;

			if (addr == global::localPlayer)
				continue;

			auto missileName = MissileName(addr);
			//printf("%s", missileName.c_str());
			if (RPM<short>(addr + MissileSrcIdx) == me->Index())
			{
				if (strstr(missileName.c_str(), "ttack") != NULL)
				{
					//std::cout << missileName.c_str() << std::endl;
					global::_missileLaunched = true;

					continue;
				}
			}

			if (RPM<short>(addr + oObjTeam) == me->Team())
				continue;

			//std::cout << addr << std::endl;

			bool skipmissile = false;
			for (size_t i = 0; i < sizeof(blackListSpells) / sizeof(blackListSpells[0]); i++)
			{
				if (strstr(missileName.c_str(), blackListSpells[i]) != NULL)
				{
					skipmissile = true;
					break;
				}
			}

			if (skipmissile)
				continue;

			bool valid = false;
			std::string nameobj = missileName;

			for (int i = 0; i < sizeof(WhiteListSpells) / sizeof(WhiteListSpells[0]); i++)
			{
				if (strstr(missileName.c_str(), WhiteListSpells[i]) != NULL)
				{
					nameobj = WhiteListSpells[i];
					valid = true;
				}
			}

			auto hash = fnv::hash_runtime(nameobj.c_str());
			if (valid)
			{
				bool charge = false;
				Geometry::Polygon path;
				Geometry::Polygon path2;
				auto& data = SpellDatabase[hash];

				structspell_evade dataToAdd;
				dataToAdd.type = data.type;
				dataToAdd.cc = data.cc;
				dataToAdd.danger = data.danger;
				dataToAdd.collision = data.collision;
				dataToAdd.windwall = data.windwall;

				Vector3 startPos = RPM<Vector3>(addr + MissileStartPos), placementPos = RPM<Vector3>(addr + MissileEndPos);

				if (strstr(missileName.c_str(), "HowlingGaleSpell") != NULL) charge = true;
				if (hash == FNV("VarusQMissile")) charge = true;
				if (hash == FNV("ViegoWMis")) charge = true;

				if (charge)
				{
					data.range = startPos.Distance(placementPos);
					data.speed = RPM<float>(RPM<uint32_t>(RPM<uint32_t>(addr + MissileSpellInfo) + oSpellData) + oMissileSpeed);
				}

				if (fnv::hash_runtime(data.type.c_str()) == FNV("linear") && data.speed != HUGE_VAL)
				{
					data.delay = 0;
				}

				Vector3 endPos = data.extend ? startPos.Extended(placementPos, data.range + data.radius) : placementPos;
				double y = placementPos.y;

				auto paths = GetPaths(XPolygon::To2D(startPos), XPolygon::To2D(endPos), data, hash, netId);
				path = paths[0];
				path2 = paths[1];

				if (hash == FNV("VelkozQMissileSplit"))
					SpellExistsThenRemove("VelkozQ");
				else if (hash == FNV("JayceShockBlastWallMis"))
					SpellExistsThenRemove("JayceShockBlast");

				AddSpell(addr, netId, path, path2, startPos, placementPos, endPos, dataToAdd, data.speed, data.range, data.delay, data.radius, nameobj, y, Engine::GameGetTickCount(), data.allowdodge, data.allowdraw, data.ignoredodge);
			}
		}
	}

	void Tick()
	{
		if (SandBox->Value)
		{
			CreateSandboxSpells();
		}
		Bounding = me->BoundingRadius();
		for (auto objBase : global::enemyheros)
		{
			auto actor = (CObject*)objBase.actor;
			auto ActiveSpellEntry = actor->GetSpellBook()->GetActiveSpellEntry();

			if (ActiveSpellEntry && !ActiveSpellEntry->isBasicAttack())
			{
				auto SpellData = ActiveSpellEntry->GetSpellData();

				auto nameobj = SpellData->GetSpellName();
				auto namemissileobj = SpellData->GetMissileName();

				Vector3 startPos = ActiveSpellEntry->GetStartPos();
				Vector3 placementPos = ActiveSpellEntry->GetEndPos();
				bool skipmissile = false;

				//printf("Spellname : %s   MissileName : %s  Time : %f StartPos : %f,%f,%f    EndPos : %f,%f,%f\n", nameobj.c_str(), namemissileobj.c_str(), ActiveSpellEntry->StartTick(), startPos.x, startPos.y, startPos.z, placementPos.x, placementPos.y, placementPos.z);

				fnv::hash namehash = 0x0;

				if (SpellDatabase.count(fnv::hash_runtime(namemissileobj.c_str())) > 0)
				{
					namehash = fnv::hash_runtime(namemissileobj.c_str());
				}
				else if (SpellDatabase.count(fnv::hash_runtime(nameobj.c_str())) > 0)
				{
					namehash = fnv::hash_runtime(nameobj.c_str());
				}

				if (nameobj == "YasuoW")
				{
					if (Engine::GameGetTickCount() - Cache::windwall.time > 0.f)
					{
						auto argsStart = XPolygon::To2D(startPos);
						auto endf = startPos.Extended(placementPos, 350.f);
						auto argsEnd = XPolygon::To2D(endf);

						auto ExtraWidth = 50 + 15 * 2;
						auto Width = ExtraWidth + 350 + 50 * actor->GetSpellBook()->GetSpellSlotByID(1)->Level();

						auto dir = (argsEnd - argsStart).Perpendicular().Normalized();
						auto sP2 = (argsEnd - dir * (Width / 2));
						auto eP2 = (argsEnd + dir * (Width / 2));

						Cache::windwall.Pos = eP2;
						Cache::windwall.StartPos = sP2;
						Cache::windwall.Level = actor->Level();
						Cache::windwall.time = ActiveSpellEntry->StartTick() + 4.f;
					}
					continue;
				}

				if (!namehash)
					continue;

				for (size_t j = 0; j < global::missiles.size(); j++)
				{
					if (global::missiles[j].actor == (DWORD)ActiveSpellEntry + (DWORD)ActiveSpellEntry->StartTick())
					{
						skipmissile = true;
						break;
					}
				}

				for (size_t i = 0; i < (sizeof(blackListSpellsActive) / sizeof(blackListSpellsActive[0])); i++)
				{
					if (namehash == blackListSpellsActive[i])
					{
						skipmissile = true;
						break;
					}
				}

				if (skipmissile)
					continue;

				if (SpellDatabase.count(namehash) > 0)
				{
					Geometry::Polygon path;
					Geometry::Polygon path2;
					auto data = SpellDatabase[namehash];

					structspell_evade dataToAdd;
					dataToAdd.type = data.type;
					dataToAdd.cc = data.cc;
					dataToAdd.danger = data.danger;
					dataToAdd.collision = data.collision;
					dataToAdd.windwall = data.windwall;


					double y = placementPos.y;
					Vector3 endPos = data.extend ? startPos.Extended(placementPos, data.range + data.radius) : placementPos;
					auto typehash = fnv::hash_runtime(data.type.c_str());
					if (typehash == FNV("circular") && namehash != FNV("KogMawLivingArtillery"))
					{
						float dist = startPos.Distance(placementPos);
						if (dist > data.range)
						{
							float dist2 = dist - data.range;
							endPos = startPos.Extended(placementPos, dist - dist2);
						}
					}
					else
					{
						if (!data.extend && startPos.Distance(placementPos) > data.range)
							endPos = startPos.Extended(placementPos, data.range + data.radius);
					}

					if (namehash == FNV("YasuoQ1") || namehash == FNV("YasuoQ2"))
					{
						Vector3 Direction = actor->Direction();

						endPos = XPolygon::To3D(XPolygon::AppendVector(XPolygon::To2D(startPos), XPolygon::Rotate(XPolygon::To2D(startPos), XPolygon::To2D(startPos + Direction), MathRad(1)), data.range + data.radius));
					}
					else if (namehash == FNV("YasuoQ3"))
					{
						Vector3 Direction = actor->Direction();

						endPos = XPolygon::To3D(XPolygon::AppendVector(XPolygon::To2D(startPos), XPolygon::Rotate(XPolygon::To2D(startPos), XPolygon::To2D(startPos + Direction), MathRad(1)), data.range + data.radius));
					}

					if (namehash == FNV("PykeR"))
					{
						auto argsEnd = XPolygon::To2D(endPos);

						auto start2 = argsEnd + Vector2(250, -250);
						auto end2 = argsEnd + Vector2(-250, 250);

						auto start = argsEnd - Vector2(250, 250);
						auto end = argsEnd + Vector2(250, 250);

						std::vector< Geometry::Polygon> polygonList;
						std::vector< Geometry::Polygon> polygonList1;


						auto paths = GetPaths(start2, end2, data, namehash);
						auto paths2 = GetPaths(start, end, data, namehash);

						polygonList.push_back(paths[0]);
						polygonList.push_back(paths2[0]);

						polygonList1.push_back(paths[1]);
						polygonList1.push_back(paths2[1]);

						auto dangerPolygons = Geometry::Polygon().ToPolygons(Geometry::Polygon().ClipPolygons(polygonList));
						auto dangerPolygons1 = Geometry::Polygon().ToPolygons(Geometry::Polygon().ClipPolygons(polygonList1));

						if (dangerPolygons.size() == 0 || dangerPolygons1.size() == 0)
							continue;

						AddSpell((DWORD)ActiveSpellEntry + (DWORD)ActiveSpellEntry->StartTick(), 0, dangerPolygons[0], dangerPolygons1[0], startPos, placementPos, endPos, dataToAdd, data.speed, data.range, data.delay, data.radius, nameobj, y, ActiveSpellEntry->StartTick() ? ActiveSpellEntry->StartTick() : Engine::GameGetTickCount(), data.allowdodge, data.allowdraw, data.ignoredodge);
					}
					else
					{
						auto paths = GetPaths(XPolygon::To2D(startPos), XPolygon::To2D(endPos), data, namehash, 0, data.range);
						path = paths[0];
						path2 = paths[1];

						AddSpell((DWORD)ActiveSpellEntry + (DWORD)ActiveSpellEntry->StartTick(), 0, path, path2, startPos, placementPos, endPos, dataToAdd, data.speed, data.range, data.delay, data.radius, nameobj, y, ActiveSpellEntry->StartTick() ? ActiveSpellEntry->StartTick() : Engine::GameGetTickCount(), data.allowdodge, data.allowdraw, data.ignoredodge);
					}

					if (fnv::hash_runtime(data.type.c_str()) == FNV("threeway"))
					{
						for (int J = 0; J < 2; J++)
						{
							auto eP = J == 0 ? XPolygon::Rotate(XPolygon::To2D(startPos), XPolygon::To2D(endPos), MathRad(data.angle)) : XPolygon::Rotate(XPolygon::To2D(startPos), XPolygon::To2D(endPos), -MathRad(data.angle));
							auto p1 = XPolygon::RectangleToPolygon(XPolygon::To2D(startPos), eP, data.radius, global::LocalData->gameplayRadius);
							auto p2 = XPolygon::RectangleToPolygon(XPolygon::To2D(startPos), eP, data.radius, 0);
							auto endpos = XPolygon::To3D(eP);
							AddSpell((DWORD)ActiveSpellEntry + (DWORD)ActiveSpellEntry->StartTick(), 0, p1, p2, startPos, endpos, endpos, dataToAdd, data.speed, data.range, data.delay, data.radius, nameobj, y, ActiveSpellEntry->StartTick() ? ActiveSpellEntry->StartTick() : Engine::GameGetTickCount(), data.allowdodge, data.allowdraw, data.ignoredodge);
						}
					}
				}
			}
		}

		LoopMissileMap();

		global::missiles.erase(
			std::remove_if(global::missiles.begin(), global::missiles.end(),
				[](missle_struct  o) {
					return /*o.timedead<= Engine::GameGetTickCount() && */o.dead /*|| Engine::GameGetTickCount() > o.startTime + 7.f*/; }),
			global::missiles.end());


		if (global::missiles.size() > 0)
		{
			int result = 0;

			for (auto& missile : global::missiles)
			{
				if (missile.dead)
					continue;

				SpellManager(missile);

				if (me->IsAlive() && missile.dodge)
				{
					mPos = XPolygon::To2D(Engine::GetMouseWorldPosition());

					result = result + CoreManager(missile);
				}
			}

			auto movePath = Engine::GetMouseWorldPosition2D();//GetMovePath();

			if (movePath.IsValid() && TrackPaths->Value && !Evading && (Evade->Value || HoldEvade->Value) && result == 0 && !me->IsWindingUp())
			{
				std::vector<Vector2> ints;
				auto myHeroPos = me->Pos2D();
				for (auto& missile : global::missiles)
				{
					if (missile.dead || missile.ignoredodge || !missile.dodge)
						continue;

					auto poly = missile.path;
					if (!poly.PointInPolygon(myHeroPos))
					{
						auto findInts = XPolygon::FindIntersections(poly, myHeroPos, movePath);

						if (findInts.empty())
							continue;

						for (auto inta : findInts) ints.push_back(inta);
					}
				}

				if (ints.size() > 0)
				{
					if (ints.size() > 1)
					{
						sort(ints.begin(), ints.end(), sortablePathEvade);
					}

					auto movePos = XPolygon::PrependVector(ints[0], myHeroPos, 30);

					if (movePos.Distance(myHeroPos) > 120.f && Engine::IsNotWall(movePos) && !me->IsWindingUp())
					{
						PathMoveBlock = false;
						Engine::DisableMove(false);
					}
					else
					{
						global::blockOrbMove = true;

						if (me->IsMoving() && !me->IsAutoAttacking())
						{
							KeyPress('S');
							Engine::DisableMove(true);
							PathMoveBlock = true;
						}

					}

				}
				else
				{
					global::blockOrbMove = false;
					global::blockOrbAttack = false;
					if (PathMoveBlock)
					{
						PathMoveBlock = false;
						Engine::DisableMove(false);
					}
				}

			}

			if (Evading && (Evade->Value || HoldEvade->Value) && InDangerousZone)
			{
				DodgeSpell();
			}


			if (result == 0) {
				Evading = false;
				SafePos = Vector2::Zero;
				LastSafePos = Vector2::Zero;
				ExtendedSafePos = Vector2::Zero;

				if (!PathMoveBlock && TrackPaths->Value || !TrackPaths->Value)
				{
					global::blockOrbMove = false;
					global::blockOrbAttack = false;
					Engine::DisableMove(false);
				}
			}

			if (result > 0)
			{
				if (!SafePos.IsValid())
				{
					global::blockOrbMove = false;
					global::blockOrbAttack = false;
					Engine::DisableMove(false);
				}
			}
		}
		else
		{
			Evading = false;
			SafePos = Vector2::Zero;
			LastSafePos = Vector2::Zero;
			ExtendedSafePos = Vector2::Zero;
			global::blockOrbMove = false;
			global::blockOrbAttack = false;
			Engine::DisableMove(false);
}

		if (SafePos.IsValid())
		{
			if (SafePos.Distance(me->Pos2D()) <= 20.f)
			{
				SafePos = Vector2::Zero;
				global::blockOrbMove = false;
				global::blockOrbAttack = false;
				Engine::DisableMove(false);
			}
		}

		if ((Evade->Value || HoldEvade->Value) && Block && InDangerousZone && SafePos.IsValid())
		{
			auto ClickPos = me->GetAIManager()->LastClickPosition();
			if (SafePos.Distance(me->Pos2D()) > Bounding)
			{
				if (ClickPos.Distance(XPolygon::To3D(SafePos).SetZ(ClickPos)) < Bounding)
				{
					Engine::DisableMove(true);
				}
			}
		}
		else
		{
			if (!PathMoveBlock)
				Engine::DisableMove(false);

			Block = false;
		}
	}

	void SpellExistsThenRemove(std::string name)
	{
		if (name.empty())
			return;

		for (size_t i = 0; i < global::missiles.size(); i++)
		{
			if (fnv::hash_runtime(global::missiles[i].name.c_str()) == fnv::hash_runtime(name.c_str()))
			{
				global::missiles.erase(global::missiles.begin() + i);
				break;
			}
		}
	}
	void AddSpell(DWORD actor, int netId, Geometry::Polygon p1, Geometry::Polygon p2, Vector3 sP, Vector3 pP, Vector3 eP, structspell_evade data, double speed, double range, double delay, double radius, std::string name, double y, float startTime, bool dodge, bool draw, bool ignoredodge)
	{
		if (pP == Vector3::Zero || (p1.Points.empty() || p2.Points.empty()))
			return;

		global::missiles.push_back(missle_struct(actor, netId, p1, p2, p1, Vector2(sP.x, sP.z), sP, pP, eP, speed, range, delay, radius, radius * 2, 60, name, startTime, data.type, data.danger, data.cc, data.collision, data.windwall, y, dodge, draw, ignoredodge));
		NewTimer = Engine::GameGetTickCount();

	}

	std::vector<Geometry::Polygon> GetPaths(Vector2 startPos, Vector2 endPos, structspell data, fnv::hash namehash, int netID = 0, double range = 0)
	{
		std::vector<Geometry::Polygon> returnPaths;
		Geometry::Polygon path;
		Geometry::Polygon path2;
		auto typehash = fnv::hash_runtime(data.type.c_str());

		if (namehash == FNV("PantheonR"))
		{
			Vector2 sP2 = (endPos).Extended(startPos, 1150), eP2 = XPolygon::AppendVector(startPos, endPos, 200);
			path = XPolygon::RectangleToPolygon(sP2, eP2, data.radius, global::LocalData->gameplayRadius);
			path2 = XPolygon::RectangleToPolygon(sP2, eP2, data.radius, 0);
			goto returnPathRegion;
		}
		else if (namehash == FNV("SionQ"))
		{
			Vector2 sPos = XPolygon::AppendVector(endPos, startPos, -40);
			Vector2 ePos = (sPos).Extended(endPos, data.range);
			Vector2 dir = (ePos - sPos).Perpendicular().Normalized() * data.radius;
			Vector2 s1 = (sPos - dir), s2 = (sPos + dir);
			Vector2 e1 = XPolygon::Rotate(s1, s1.Extended(ePos, data.range), -MathRad(20));
			Vector2 e2 = XPolygon::Rotate(s2, s2.Extended(ePos, data.range), MathRad(20));
			path2.Points = { s1, e1, e2, s2 };
			path = Geometry::Polygon().OffsetPolygon(path2, global::LocalData->gameplayRadius );

			goto returnPathRegion;
		}
		else if (namehash == FNV("SettW"))
		{
			Vector2 sPos = XPolygon::AppendVector(endPos, startPos, -40);
			Vector2 ePos = (sPos).Extended(endPos, data.range);
			Vector2 dir = (ePos - sPos).Perpendicular().Normalized() * data.radius;
			Vector2 s1 = (sPos - dir), s2 = (sPos + dir);
			Vector2 e1 = XPolygon::Rotate(s1, s1.Extended(ePos, data.range), -MathRad(30));
			Vector2 e2 = XPolygon::Rotate(s2, s2.Extended(ePos, data.range), MathRad(30));
			path2.Points = { s1, e1, e2, s2 };
			path = Geometry::Polygon().OffsetPolygon(path2, global::LocalData->gameplayRadius );

			goto returnPathRegion;
		}
		else if (namehash == FNV("SettE"))
		{
			Vector2 sPos = (startPos).Extended(endPos, -data.range);
			path = XPolygon::RectangleToPolygon(sPos, endPos, data.radius, global::LocalData->gameplayRadius );
			path2 = XPolygon::RectangleToPolygon(sPos, endPos, data.radius, 0);
			goto returnPathRegion;
		}
		/*else if (namehash == FNV("ZiggsQSpell"))
		{
			float quality = CQ->Value;
			auto p1 = XPolygon::CircleToPolygon(endPos, data.radius, quality), bp1 = XPolygon::CircleToPolygon(endPos, data.radius + global::LocalData->gameplayRadius, quality);
			Vector2 e1 = startPos.Extended(endPos, 1.4 * startPos.Distance(endPos));
			auto p2 = XPolygon::CircleToPolygon(e1, data.radius, quality),
				bp2 = XPolygon::CircleToPolygon(e1, data.radius + global::LocalData->gameplayRadius, quality);
			Vector2 e2 = endPos.Extended(e1, 1.69 * endPos.Distance(e1));
			auto p3 = XPolygon::CircleToPolygon(e2, data.radius, quality),
				bp3 = XPolygon::CircleToPolygon(e2, data.radius + global::LocalData->gameplayRadius, quality);

			AddSpell(0, netID, bp1, p1, XPolygon::To3D(startPos), XPolygon::To3D(endPos), XPolygon::To3D(endPos), data, data.speed, data.range, 0.25, data.radius, "ZiggsQSpell", 55, Engine::GameGetTickCount());
			AddSpell(0, netID, bp2, p2, XPolygon::To3D(startPos), XPolygon::To3D(endPos), XPolygon::To3D(endPos), data, data.speed, data.range, 0.75, data.radius, "ZiggsQSpell", 55, Engine::GameGetTickCount());
			AddSpell(0, netID, bp3, p3, XPolygon::To3D(startPos), XPolygon::To3D(endPos), XPolygon::To3D(endPos), data, data.speed, data.range, 1.25, data.radius, "ZiggsQSpell", 55, Engine::GameGetTickCount());

			goto returnPathRegion;
		}*/
		/*else if (namehash == FNV("GravesQLineSpell"))
		{
			Vector2 s1 = endPos - (endPos - startPos).Perpendicular().Normalized() * 240;
			Vector2 e1 = endPos + (endPos - startPos).Perpendicular().Normalized() * 240;
			auto p1 = XPolygon::RectangleToPolygon(startPos, endPos, data.radius, 0);
			auto p2 = XPolygon::RectangleToPolygon(s1, e1, 150, 0);
			auto clippath = Geometry::Polygon().ClipPolygons({ p1,p2 });
			path = Geometry::Polygon().ToPolygons(clippath);
			path2 = XPolygon::RectangleToPolygon(sP2, eP2, data.radius, 0);
			goto returnPathRegion;
		}*/
		else if (namehash == FNV("GravesChargeShot"))
		{
			auto p1 = XPolygon::RectangleToPolygon(startPos, endPos, data.radius, 0);
			auto e1 = XPolygon::AppendVector(startPos, endPos, 700);
			auto dir = (endPos - e1).Perpendicular().Normalized() * 350;
			path2.Points = { p1.Points[1], p1.Points[2], (e1 - dir), (e1 + dir), p1.Points[3], p1.Points[0] };
			path = Geometry::Polygon().OffsetPolygon(path2, global::LocalData->gameplayRadius );

			goto returnPathRegion;
		}

		if (typehash == FNV("linear"))
		{
			if (range == 12500)
			{
				auto eP = startPos.Extended(endPos, 2000.f);

				path = XPolygon::RectangleToPolygon(startPos, eP, data.radius, global::LocalData->gameplayRadius);
				path2 = XPolygon::RectangleToPolygon(startPos, eP, data.radius, 0);
			}
			else
			{
				path = XPolygon::RectangleToPolygon(startPos, endPos, data.radius, global::LocalData->gameplayRadius);
				path2 = XPolygon::RectangleToPolygon(startPos, endPos, data.radius, 0);
			}
		}
		else if (typehash == FNV("threeway"))
		{
			path = XPolygon::RectangleToPolygon(startPos, endPos, data.radius, global::LocalData->gameplayRadius);
			path2 = XPolygon::RectangleToPolygon(startPos, endPos, data.radius, 0);
		}
		else if (typehash == FNV("rectangular"))
		{
			auto dir = (endPos - startPos).Perpendicular().Normalized() * 400; // (data.radius2 or 400)
			auto sP2 = (endPos - dir);
			auto eP2 = (endPos + dir);

			path = XPolygon::RectangleToPolygon(sP2, eP2, data.radius, global::LocalData->gameplayRadius);
			path2 = XPolygon::RectangleToPolygon(sP2, eP2, data.radius, 0);
		}
		else if (typehash == FNV("circular"))
		{
			path = XPolygon::CircleToPolygon(endPos, data.radius + global::LocalData->gameplayRadius, CQ->Value);
			path2 = XPolygon::CircleToPolygon(endPos, data.radius, CQ->Value);
		}
		else if (typehash == FNV("conic"))
		{
			path2 = XPolygon::ConeToPolygon(startPos, endPos - startPos, data.angle * (float)M_PI / 180.f, data.range);
			path = path2;// XPolygon::OffsetPolygon(path2, global::LocalData->gameplayRadius);
		}
		else if (typehash == FNV("polygon"))
		{
			path = XPolygon::RectangleToPolygon(startPos, endPos, data.radius, global::LocalData->gameplayRadius * 1.5f);
			path2 = XPolygon::RectangleToPolygon(startPos, endPos, data.radius, 0);
		}

	returnPathRegion:
		returnPaths.push_back(path);
		returnPaths.push_back(path2);
		return returnPaths;
	}

	std::vector<Vector3> GetPath(Vector3 end)
	{

		std::vector<Vector3> path;

		Vector3 playerPosition = me->ServerPosition();
		auto playerBoundingRadius = global::LocalData->gameplayRadius;
		path.push_back(playerPosition);
		int step = 50;
		int lastWaypointIndex = 0;

		for (int i = 1; i * step <= playerPosition.Distance(end); i++)
		{
			auto point = path[lastWaypointIndex].Extended(end, i * step);

			for (auto minion : Engine::GetMinionsAround(500, 3))
			{
				auto minionRange = playerBoundingRadius + minion->BoundingRadius();
				if (point.Distance(minion->Position()) < minionRange)
				{
					auto circlep = Engine::CirclePoints(30, minionRange, point);

					circlep.erase(
						std::remove_if(circlep.begin(), circlep.end(),
							[&](Vector3  x) {
								return (x.Distance(minion->Position()) < minionRange); }),
						circlep.end());

					sort(circlep.begin(), circlep.end(), [&](Vector3 x, Vector3 x1) {
						return x.Distance(end) < x1.Distance(end);
						});

					path.push_back(circlep[0]);

					lastWaypointIndex++;
					break;
				}
			}

			if (Engine::IsWall(point))
			{
				if (playerPosition.Distance(point) < 150)
				{
					auto pointToWall = point.Extended(path[lastWaypointIndex], playerBoundingRadius);
					auto circlep = Engine::CirclePoints(8, 150, point);

					circlep.erase(
						std::remove_if(circlep.begin(), circlep.end(),
							[&](Vector3  x) {
								return Engine::IsWall(x); }),
						circlep.end());

					sort(circlep.begin(), circlep.end(), [&](Vector3 x, Vector3 x1) {
						return x.Distance(end) < x1.Distance(end);
						});

					path.push_back(circlep[0]);
				}
				else
				{
					path.push_back(point);
				}

				return path;
			}

		}
		path.push_back(end);
		return path;
	}
	Vector2 GetClosestOutsidePoint(Vector2 from, std::vector<Geometry::Polygon> polygons)
	{
		auto result = std::vector<Vector2>();

		for (auto poly : polygons)
		{
			for (int i = 0; i <= poly.Points.size() - 1; i++)
			{
				auto sideStart = poly.Points[i];
				auto sideEnd = poly.Points[(i == poly.Points.size() - 1) ? 0 : i + 1];

				result.push_back(Engine::ProjectOn(from, sideStart, sideEnd).SegmentPoint);
			}
		}
		if (result.size() > 1)
		{
			sort(result.begin(), result.end(), [&](Vector2 a1, Vector2 a2) {
				return a1.Distance(from) < a2.Distance(from);
				});
		}

		return result[0];
	}

	bool IsGoodPosition(Vector3 dashPos, float range)
	{

		float segment = range / 5;
		for (int i = 1; i <= 5; i++)
		{
			auto pos = me->Position().Extended(dashPos, i * segment);
			if (Engine::IsWall(pos))
				return false;
		}

		if (IsDangerous(XPolygon::To2D(dashPos)))
			return false;

		if (Engine::UnderTurret(dashPos))
			return false;

		auto enemyCheck = 2;
		auto enemyCountDashPos = Engine::GetEnemyCount(600, dashPos);

		if (enemyCheck > enemyCountDashPos)
			return true;

		auto enemyCountPlayer = Engine::GetEnemyCount(400, me->Position());

		if (enemyCountDashPos <= enemyCountPlayer)
			return true;

		return false;
	}

	std::vector<Vector2> GetBestEvadePos(int mode, bool force, float extra = 0)
	{
		std::vector<Vector2> points = { Vector2::Zero };
		std::vector< Geometry::Polygon> polygonList;
		bool takeClosestPath = false;
		auto MyPos = me->Pos2D();
		for (auto skillshot : global::missiles)
		{
			if (!skillshot.dead)
			{
				if (skillshot.path.PointInPolygon(MyPos))
				{
					auto namehash = fnv::hash_runtime(skillshot.name.c_str());
					if (namehash == FNV("RocketGrab") ||
						namehash == FNV("ThreshQMissile") ||
						namehash == FNV("LeonaZenithBlade") ||
						namehash == FNV("XerathQ") ||
						namehash == FNV("YasuoQ1") ||
						namehash == FNV("YasuoQ2") ||
						namehash == FNV("LucianQ"))
						takeClosestPath = true;
				}
				if (!skillshot.ignoredodge && skillshot.dodge)
					polygonList.push_back(skillshot.path);
			}
		}

		if (polygonList.empty())
		{
			return points;
		}

		//clipping polygons moves them?
		auto dangerPolygons = polygonList;

		//Create the danger polygon:
		/*auto dangerPolygons = Geometry::Polygon().ToPolygons(Geometry::Polygon().ClipPolygons(polygonList));

		if (dangerPolygons.empty())
		{
			return Vector2::Zero;
		}*/
		if (dangerPolygons.empty())
		{
			return points;
		}
		for (auto poly : dangerPolygons)
		{
			for (size_t i = 0; i < poly.Points.size(); ++i)
			{
				auto startPos = poly.Points[i];
				auto endPos = poly.Points[(i == poly.Points.size() - 1) ? 0 : i + 1];
				if (startPos.IsValid() && endPos.IsValid())
				{
					auto original = Engine::ProjectOn(MyPos, startPos, endPos).SegmentPoint;
					auto distance_to_evade_point = original.DistanceSquared(MyPos);
					if (distance_to_evade_point < 600 * 600)
					{
						if (force) // force
						{
							auto candidate = XPolygon::AppendVector(MyPos, original, 5);

							if (candidate.IsValid() && candidate.IsWorldValid())
							{
								if (!IsDangerous(candidate) && Engine::IsNotWall(candidate) && candidate.IsWorldValid())
								{
									points.push_back(candidate);
								}
							}

						}
						else
						{
							auto side_distance = endPos.DistanceSquared(startPos);
							Vector2 direction = Vector2(endPos - startPos).Normalized();
							int step = (distance_to_evade_point < 200 * 200 && side_distance > 90 * 90) ? DC->Value : 0;

							for (int k = -step; k <= step; k++)
							{
								auto candidate = original + direction * (k * DS->Value);
								auto extended = XPolygon::AppendVector(MyPos, candidate, global::LocalData->gameplayRadius + extra);
								candidate = XPolygon::AppendVector(MyPos, candidate, 30);
								if (extended.IsValid() && extended.IsWorldValid())
								{
									if (IsSafePos(candidate) && Engine::IsNotWall(extended) /*&& extended.Distance(MyPos) > Bounding + 20.f*/)
									{
										points.push_back(extended);
									}
								}
							}

						}
					}
				}
			}
		}


		if (points.size() > 0)
		{
			if (mode == 1 || takeClosestPath || Evademode->Value == 1 || (ComboMode->Value && global::mode == ScriptMode::Combo))
			{
				if (points.size() > 1)
					return from(points) >> cpplinq::orderby([&](Vector2 pos) { return pos.Distance(MyPos); }) >> to_vector();

				return points;
			}
			else if (mode == 2)
			{
				if (points.size() > 1)
					return from(points) >> cpplinq::orderby([&](Vector2 pos) {return pos.Distance(MyPos.Extended(mPos, pos.Distance(MyPos))); }) >> to_vector();

				return points;
			}
		}
		else
		{
			return points;
		}
	}

	float GetMovementSpeed(bool extra, evadeSpell evadeSpell)
	{
		float moveSpeed = me->MoveSpeed();
		if (!extra) return moveSpeed;
		if (!evadeSpell.slot) return 9999;

		auto lvl = me->GetSpellBook()->GetSpellSlotByID(evadeSpell.slot)->Level();
		auto name = evadeSpell.name;
		if (lvl == 0) return moveSpeed;

		return moveSpeed;
	}

	float GetSpellHitTime(missle_struct s, Vector2 pos)
	{
		switch (fnv::hash_runtime(s.type.c_str()))
		{
		case FNV("linear"):
		{
			if (s.speed == std::numeric_limits<float>::max())
			{
				auto endTime = s.startTime + (s.startPos.Distance(s.endPos) + global::LocalData->gameplayRadius) / s.speed + s.delay;
				return std::max(0.0, endTime - Engine::GameGetTickCount() - Engine::GetLatency());
			}
			Vector2 currentSpellPosition = s.position;
			return 1000.0f * currentSpellPosition.Distance(pos) / s.speed;
		}
		case FNV("circular"):
		case FNV("conic"):
		case FNV("polygon"):
			return std::max(0.0, (s.startTime + s.delay) - Engine::GameGetTickCount() - Engine::GetLatency());
		default:
			return std::numeric_limits<float>::max();
		}
	}

	bool ShouldNotUseFlash(missle_struct s, float& rEvadeTime, float& rSpellHitTime)
	{
		Vector3 vector = me->ServerPosition();
		float num = 0.0f;
		float num2 = 0.0f;
		float num3 = me->MoveSpeed();
		float num4 = 0.0f;
		auto spellType = fnv::hash_runtime(s.type.c_str());

		num3 += num3 * s.speed / 100.0f;
		num4 += ((s.delay > 0.05f) ? s.delay : 0.0f) + Engine::GetPing();

		if (spellType == FNV("linear"))
		{
			Vector3 segmentPoint = Engine::ProjectOn(vector, s.startPos, s.endPos).SegmentPoint;
			num = 1000.0f * (s.radius - vector.Distance(segmentPoint) + me->BoundingRadius()) / num3;
			num2 = GetSpellHitTime(s, XPolygon::To2D(segmentPoint));
		}
		else if (spellType == FNV("circular"))
		{
			num = 1000.0f * (s.radius - vector.Distance(s.endPos)) / num3;
			num2 = GetSpellHitTime(s, XPolygon::To2D(vector));
		}

		rEvadeTime = num;
		rSpellHitTime = num2;
		return num2 - num4 > num;

	}

	bool IsAboutToHit(missle_struct spell, Vector2 posa)
	{
		float moveSpeed = me->MoveSpeed();
		Vector2 myPos = me->Pos2D();

		double diff = Engine::GameGetTickCount() - spell.startTime;
		auto pos = XPolygon::AppendVector(myPos, posa, 99999);

		if (spell.speed != HUGE_VAL && fnv::hash_runtime(spell.type.c_str()) == FNV("linear") || fnv::hash_runtime(spell.type.c_str()) == FNV("threeway"))
		{
			if (spell.delay > 0 && diff <= spell.delay)
			{
				myPos = myPos.Extended(pos, (spell.delay - diff) * moveSpeed);
				if (!spell.path3.PointInPolygon(myPos))
					return false;
			}

			auto va = (pos - myPos).Normalized() * moveSpeed;
			auto vb = (XPolygon::To2D(spell.endPos) - spell.position).Normalized() * spell.speed;
			auto da = myPos - spell.position;
			auto db = va - vb;
			auto a = db.Dot(db);
			auto b = 2 * da.Dot(db);
			auto c = da.Dot(da) - pow((spell.radius + global::LocalData->gameplayRadius * 2), 2);
			auto delta = b * b - 4 * a * c;
			if (delta >= 0)
			{
				auto rtDelta = sqrt(delta);
				auto t1 = (-b + rtDelta) / (2 * a), t2 = (-b - rtDelta) / (2 * a);
				return std::max(t1, t2) >= 0;
			}
			return false;
		}
		auto t = std::max(0.0, spell.range / spell.speed + spell.delay - diff - 0.07);
		return spell.path3.PointInPolygon(myPos.Extended(pos, moveSpeed * t));
	}

	bool IsDangerous(Vector2 pos)
	{
		for (int i = 0; i < global::missiles.size(); i++)
		{
			if (global::missiles[i].dead)
				continue;

			if (global::missiles[i].path3.PointInPolygon(pos))
				return true;
		}

		return false;
	}
	bool IsSafePos(Vector2 pos)
	{

		for (int i = 0; i < global::missiles.size(); i++)
		{
			if (global::missiles[i].dead)
				continue;

			if (global::missiles[i].path3.PointInPolygon(pos) || IsAboutToHit(global::missiles[i], pos))
				return false;
		}

		/*if (!Engine::UnderTurret(me->Position()) && Engine::UnderTurret(XPolygon::To3D(pos)))
			return false;*/

		return true;
	}

	Vector2 GetExtendedSafePos(Vector2 pos)
	{
		if (!SmoothEvade->Value) return pos;

		auto minions = Engine::GetMinionsAround(me->Pos2D().Distance(pos) + 390, 3);
		for (int i = 2; i < 8; i++)
		{
			bool collision = false;
			auto ext = XPolygon::AppendVector(me->Pos2D(), pos, global::LocalData->gameplayRadius * i);
			if (i > 2 && Engine::IsNotWall(ext.x, ext.y, 0) || i == 2)
			{
				for (auto minion : minions)
				{
					if (ext.Distance(minion->Pos2D()) <= global::LocalData->gameplayRadius)
					{
						collision = true;
						break;
					}
				}
				if (!collision) return ext;
			}
		}
		return Vector2(0, 0);
	}

	bool SpellManager(missle_struct& s)
	{
		if (s.startTime + (s.startPos.Distance(s.endPos)) / s.speed + s.delay > Engine::GameGetTickCount())
		{
			if (s.speed != HUGE_VAL && s.startTime + s.delay < Engine::GameGetTickCount())
			{
				if (fnv::hash_runtime(s.type.c_str()) == FNV("linear") || fnv::hash_runtime(s.type.c_str()) == FNV("threeway"))
				{
					auto rng = s.speed * ((double)Engine::GameGetTickCount() - s.startTime - s.delay);
					auto rng_extra = s.speed * ((double)Engine::GameGetTickCount() - s.startTime - (s.delay + 0.1));
					if (s.range == 12500)
					{
						auto sP = XPolygon::To2D(s.startPos).Extended(XPolygon::To2D(s.endPos), rng);
						auto sP2 = XPolygon::To2D(s.startPos).Extended(XPolygon::To2D(s.endPos), rng_extra);
						auto eP = sP.Extended(XPolygon::To2D(s.endPos), 2000.f);

						s.position = sP;
						s.path = XPolygon::RectangleToPolygon(sP2, eP, s.radius, global::LocalData->gameplayRadius);
						s.path3 = XPolygon::RectangleToPolygon(sP, eP, s.radius, global::LocalData->gameplayRadius);
						s.path2 = XPolygon::RectangleToPolygon(sP, eP, s.radius, 0);
					}
					else
					{
						auto sP = XPolygon::To2D(s.startPos).Extended(XPolygon::To2D(s.endPos), rng);
						auto sP2 = XPolygon::To2D(s.startPos).Extended(XPolygon::To2D(s.endPos), rng_extra);

						s.position = sP;
						s.path = XPolygon::RectangleToPolygon(sP2, XPolygon::To2D(s.endPos), s.radius, global::LocalData->gameplayRadius);
						s.path3 = XPolygon::RectangleToPolygon(sP, XPolygon::To2D(s.endPos), s.radius, global::LocalData->gameplayRadius);
						s.path2 = XPolygon::RectangleToPolygon(sP, XPolygon::To2D(s.endPos), s.radius, 0);
					}
				}
			}
		}
		else
		{
			if (!s.dead)
			{
				s.dead = true;
				s.timedead = Engine::GameGetTickCount();
			}
		}

		return false;
	}

	int CoreManager(missle_struct& s)
	{
		if (s.path.PointInPolygon(me->Pos2D()))
		{
			if (DD->Value && !s.cc || DD->Value && !(s.danger > 4))
				return 0;

			//if (OldTimer != NewTimer) 		
			//if (!s.isdodged)
			{

				float num;
				float num2;

				/*if (ShouldNotUseFlash(s, num, num2))
				{

					printf("Can Dodge\n");
					printf("num : %0.f\nnum2 : %0.f\n", num, num2);*/
				Vector2 safePos = GetBestEvadePos(2, false).front();
				if (safePos.IsValid() && (Evade->Value || HoldEvade->Value))
				{
					Engine::DisableMove(false);
					ExtendedSafePos = GetExtendedSafePos(safePos);
					if (!Block)
					{
						SafePos = safePos;
						Evading = true;
					}
					s.isdodged = true;
				}
				else
				{
					//if (Evade->Value || HoldEvade->Value)
					//{
					//	if (!s.isdodged && EvadeSpells.count(global::LocalChampNameHash) > 0 && UseDodgeSpells->Value || UseDodgeFlash->Value && me->GetSpellSlotByName("SummonerFlash") > -1 && s.path2.PointInPolygon(me->Pos2D()))
					//	{
					//		auto slot = EvadeSpells.count(global::LocalChampNameHash) > 0 ? EvadeSpells[global::LocalChampNameHash].slot : -1;
					//		auto flash_slot = me->GetSpellSlotByName("SummonerFlash");
					//		auto range = 400;

					//		auto dodge_slot = -1;
					//		if (UseDodgeSpells->Value && IsReady(slot))
					//		{
					//			dodge_slot = slot;
					//			range = EvadeSpells[global::LocalChampNameHash].range;
					//		}
					//		else if (UseDodgeFlash->Value && IsReady(flash_slot) && s.danger > 4)
					//		{
					//			dodge_slot = flash_slot;
					//			range = 400;
					//		}

					//		if (IsReady(dodge_slot))
					//		{
					//			auto safePosSpell = GetBestEvadePos(1, true, range).front();


					//			if (safePosSpell.IsValid())
					//			{
					//				Engine::DisableMove(false);
					//				CastSpell(dodge_slot, Engine::WorldToScreen(XPolygon::To3D(safePosSpell)), true, false);
					//				ExtendedSafePos = GetExtendedSafePos(safePosSpell);
					//				if (!Block)
					//				{
					//					//SafePos = safePos;
					//					Evading = true;
					//					DodgeTimer = Engine::GameTimeTickCount();
					//				}
					//				s.isdodged = true;
					//				return 1;
					//			}
					//		}
					//	}
					//}
				}
				//}

				if (!safePos.IsValid())
				{
					SafePos = Vector2::Zero;
					ExtendedSafePos = Vector2::Zero;
				}
				OldTimer = NewTimer;
			}



			return 1;
		}
		else
		{
			s.isdodged = false;
		}
		return 0;
	}

	Vector2 GetMovePath()
	{
		auto movePath = me->GetWaypoints();
		return me->IsMoving() && movePath.back().IsValid() ? movePath.back() : Vector2::Zero;
	}

	void MoveTo(Vector3 pos)
	{
		if (Engine::GameGetTickCount() - last_movetoorderevade < 40 * 0.001f) {
			return;
		}

		auto activeSpell = me->GetSpellBook()->GetActiveSpellEntry();
		if (activeSpell) {
			auto castInfo = activeSpell->GetSpellData();

			//if (activeSpell->IsAutoAttack() && !activeSpell->SpellWasCast() && !castInfo->CanMoveWhileChanneling() /*|| !activeSpell->isAutoAttackAll() && !castInfo->CanMoveWhileChanneling()*/) {
			//	return ;
			//}

			if (!castInfo->CanMoveWhileChanneling() && (!activeSpell->IsInstantCast() || !activeSpell->SpellWasCast())) {
				return;
			}

			/*if (global::LocalChampNameHash == FNV("Xerath"))
			{
				if (activeSpell->GetSpellData()->GetSpellNameHash() == FNV("XerathLocusOfPower2"))
					return ;
			}
			else if (global::LocalChampNameHash == FNV("Jhin"))
			{
				if (activeSpell->GetSpellData()->GetSpellNameHash() == FNV("JhinRShot"))
					return ;
			}
			else if (global::LocalChampNameHash == FNV("MissFortune"))
			{
				if (activeSpell->GetSpellData()->GetSpellNameHash() == FNV("MissFortuneBulletTime"))
					return ;
			}
			else if (global::LocalChampNameHash == FNV("Velkoz"))
			{

			}
			else if (global::LocalChampNameHash == FNV("Katarina"))
			{
				if (activeSpell->GetSpellData()->GetSpellNameHash() == FNV("KatarinaR"))
					return ;
			}*/
		}

		/*if (!me->CanMove())
			return;*/

		Engine::SetTargetOnlyChampions(true);
		if (pos.IsValid() && !Engine::IsOutboundScreen(pos))
		{
			MouseClick(false, pos.x, pos.y);
		}
		else {
			Click();
		}
		Engine::SetTargetOnlyChampions(false);
		last_movetoorderevade = Engine::GameGetTickCount();
	}

	void DodgeSpell()
	{
		if (SafePos.IsValid())
		{
			if (IsSafePos(SafePos))
			{
				/*if (SafePos.Distance(me->Pos2D()) > Bounding)
				{*/
				auto poseva = Engine::WorldToScreen(XPolygon::To3D(SafePos));

				if ((poseva.x != 0 && poseva.y != 0))
				{
					Engine::DisableMove(false);
					MoveTo(poseva);
					Block = true;
					global::blockOrbMove = true;
					global::blockOrbAttack = true;
				}

				/*}
				else
				{
					global::blockOrbAttack = false;
					global::blockOrbMove = true;
				}*/
			}
			else
			{
				Block = false;
				global::blockOrbMove = false;
				global::blockOrbAttack = false;
			}
		}
	}



	Vector2 Closest(Vector2 to, std::vector<Vector2> from)
	{
		auto dist = FLT_MAX;
		Vector2 result = Vector2::Zero;

		for (auto point : from)
		{
			auto distance = point.DistanceSquared(to);
			if (distance < dist)
			{
				dist = distance;
				result = point;
			}
		}

		return result;
	}

	void TestDraw()
	{
		//std::vector< Geometry::Polygon> polygonList;
		//for (auto skillshot : global::missiles)
		//{
		//	if (!skillshot.dead)
		//	{
		//		if (skillshot.path.PointInPolygon(me->Pos2D()))
		//		{
		//			auto namehash = fnv::hash_runtime(skillshot.name.c_str());
		//			/*if (namehash == FNV("RocketGrab") ||
		//				namehash == FNV("ThreshQMissile") ||
		//				namehash == FNV("LeonaZenithBlade") ||
		//				namehash == FNV("XerathQ"))
		//				takeClosestPath = true;*/
		//		}

		//		polygonList.push_back(skillshot.path);
		//	}
		//}

		////Create the danger polygon:
		////auto dangerPolygons = Geometry::Polygon().ToPolygons(Geometry::Polygon().ClipPolygons(polygonList));
		//auto dangerPolygons = polygonList;


		////if (dangerPolygons.size() == 0)
		////{
		////	//std::cout << "NoDanger" << std::endl;
		////	return Vector2::Zero;
		////}

		//for (auto poly : dangerPolygons)
		//{
		//	XPolygon::DrawPolygon(poly, me->Position().y, DrawSpellFilled->Value ? D3DCOLOR_ARGB(70, 76, 255, 255) : D3DCOLOR_ARGB(255, 255, 255, 255), 1, false, DrawSpellFilled->Value);
		//}

		auto movePath = Engine::GetMouseWorldPosition2D();

		if (movePath.IsValid())
		{
			std::vector<Vector2> ints;
			auto myHeroPos = me->Pos2D();
			for (auto& missile : global::missiles)
			{
				if (missile.dead)
					continue;

				auto poly = missile.path;
				if (!poly.PointInPolygon(myHeroPos))
				{
					auto findInts = XPolygon::FindIntersections(poly, myHeroPos, movePath);

					if (findInts.empty())
						continue;

					for (auto inta : findInts) ints.push_back(inta);
				}
			}

			if (ints.size() > 0)
			{
				sort(ints.begin(), ints.end(), sortablePathEvade);
				for (auto intz : ints)
				{
					auto movePos = XPolygon::PrependVector(ints[0], myHeroPos, global::LocalData->gameplayRadius);
					XPolygon::DrawCircle(XPolygon::To3D(ints[0]), global::LocalData->gameplayRadius, ImVec4(255, 0, 255, 0));
					XPolygon::DrawCircle(XPolygon::To3D(movePos), global::LocalData->gameplayRadius, ImVec4(255, 255, 255, 0));
				}

			}
		}


	}

	void Draw()
	{

		//XPolygon::DrawPolygon(me->GetPath3D(), DrawSpellFilled->Value ? D3DCOLOR_ARGB(70, 76, 255, 255) : D3DCOLOR_ARGB(255, 255, 255, 255), 1, false);
		//XPolygon::DrawArrow(me->Pos2D(), Engine::GetMouseWorldPosition2D(), D3DCOLOR_ARGB(255, 255, 0, 0));

		//TestDraw();



		if (Status->Value)
		{
			auto pos = me->Position();
			pos.z -= 75.f;
			auto pos2 = Engine::WorldToScreenImVec2(pos);
			if (Evade->Value || HoldEvade->Value)
			{
				Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, pos2, 15, !DD->Value ? D3DCOLOR_RGBA(0, 255, 0, 255) : D3DCOLOR_RGBA(247, 198, 0, 255), true, false,
					"EVADE");
			}
		}

		if (DrawSpell->Value) {
			global::missilesDraw = global::missiles;
			if (global::missilesDraw.size() > 0)
			{
				/*for (auto missilezz : GetBestEvadePos(2, false))
				{
					XPolygon::DrawCircle(XPolygon::To3D(missilezz), global::LocalData->gameplayRadius / 2, ImVec4(255, 0, 255, 0));
				}*/

				for (auto missile : global::missilesDraw)
				{
					if (missile.dead || !missile.draw)
						continue;

					//XPolygon::DrawPolygon(missile.path, missile.placementPos.y, DrawSpellFilled->Value ? D3DCOLOR_ARGB(70, 76, 255, 255) : D3DCOLOR_ARGB(255, 255, 255, 255), 1, false, DrawSpellFilled->Value);
					if (missile.type == "circular")
					{
						XPolygon::DrawCircle(missile.placementPos, missile.radius, ImVec4(255, 255, 255, 255));
					}
					else
					{
						XPolygon::DrawPolygon(missile.path2, missile.placementPos.y, DrawSpellFilled->Value ? D3DCOLOR_ARGB(70, 76, 255, 255) : D3DCOLOR_ARGB(255, 255, 255, 255), 1, false, DrawSpellFilled->Value);
					}
					//XPolygon::DrawPolygon(missile.path, Engine::heightForPosition(missile.placementPos), DrawSpellFilled->Value ? D3DCOLOR_ARGB(70, 76, 255, 255) : D3DCOLOR_ARGB(255, 255, 255, 255), 1, false, DrawSpellFilled->Value);
				}
			}
		}

		if (DrawSafePos->Value)
		{
			if (SafePos.IsValid())
			{
				XPolygon::DrawCircle(XPolygon::To3D(SafePos), global::LocalData->gameplayRadius, ImVec4(255, 0, 255, 0));
				XPolygon::DrawArrow(me->Pos2D(), SafePos, D3DCOLOR_ARGB(255, 255, 0, 0));
			}
		}


	}
};

JustEvade* justevade;