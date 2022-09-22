#pragma once
#include <map>
#include <iostream>
// Input & Output

enum SkillshotType
{
	SkillshotLine,
	SkillshotCircle,
	SkillshotCone
};

enum CollisionableObjects
{
	Minions,
	Heroes,
	YasuoWall,
	Walls,
	Allies,
	Building
};

//struct combo_spell
//{
//	float range;
//	float delay;
//	float radius;
//	float speed;
//	bool collision;
//	SkillshotType type = SkillshotType::SkillshotLine;
//	int LastCastAttemptT = GetTickCount();
//};

struct PredictionInput
{
	float Range = FLT_MAX;
	float Delay = 0.25f;
	float Radius = 1.f;
	float Speed = FLT_MAX;
	bool Collision = false;
	SkillshotType Type = SkillshotType::SkillshotLine;
	bool UseBoundingRadius = true;
	int LastCastAttemptT = Engine::TickCount();
	bool Aoe = false;
	std::vector<CollisionableObjects> CollisionObjects = { CollisionableObjects::Minions , CollisionableObjects::YasuoWall };
	CObject* Unit = me;
	SpellSlot Slot = SpellSlot::Invalid;
	Vector3 _from = Vector3::Zero;
	Vector3 _rangeCheckFrom = Vector3::Zero;

	Vector3 From()
	{
		return _from.IsValid() ? _from : me->ServerPosition();
	}
	void From(Vector3 value)
	{
		_from = value;
	}

	Vector3 RangeCheckFrom()
	{
		return XPolygon::To2D(_rangeCheckFrom).IsValid()
			? _rangeCheckFrom
			: (From().IsValid() ? From() : me->ServerPosition());
	}

	bool IsInRange(CObject* target)
	{
		auto local_pos = me->ServerPosition();
		auto target_pos = target->ServerPosition();

		return local_pos.IsInRange(target_pos, this->Range);
	}

	bool IsInRange(Vector3 target)
	{
		auto local_pos = me->ServerPosition();
		auto target_pos = target;

		return local_pos.IsInRange(target_pos, this->Range);
	}

	bool IsInRange(Vector2 target)
	{
		auto local_pos = me->PosServer2D();
		auto target_pos = target;

		return local_pos.IsInRange(target_pos, this->Range);
	}

	void RangeCheckFrom(Vector3 value)
	{
		_rangeCheckFrom = value;
	}

	float RealRadius()
	{
		return UseBoundingRadius ? Radius + Unit->BoundingRadius() : Radius;
	}
};

enum class HitChance
{
	Immobile = 8,

	Dashing = 7,

	VeryHigh = 6,

	High = 5,

	Medium = 4,

	Low = 3,

	Impossible = 2,

	OutOfRange = 1,

	Collision = 0
};

struct PredictionOutput
{
	std::vector<CObject*> AoeTargetsHit = {};
	std::vector<CObject*> CollisionObjects = {};
	int _aoeTargetsHitCount;
	PredictionInput Input;
	Vector3 _castPosition;
	Vector3 _unitPosition;
	float HitchanceFloat = -1.f;
	HitChance _hitchance = HitChance::Impossible;

	DWORD navEnd = 0x0;

	void SetHitChance(HitChance value)
	{
		_hitchance = value;
	}

	std::string HitChanceStr()
	{
		if (_hitchance == HitChance::Low)
		{
			return "Low";
		}
		if (_hitchance == HitChance::Medium)
		{
			return "Medium";
		}
		if (_hitchance == HitChance::High)
		{
			return "High";
		}
		if (_hitchance == HitChance::VeryHigh)
		{
			return "VeryHigh";
		}

		return "NULL";
	}

	HitChance HitChance()
	{
		if (HitchanceFloat < 0)
			return _hitchance;

		if (HitchanceFloat < 0.4)
			return HitChance::Low;

		if (HitchanceFloat < 0.6)
			return HitChance::Medium;

		if (HitchanceFloat < 0.8)
			return HitChance::High;

		return HitChance::VeryHigh;
	}

	int AoeTargetsHitCount()
	{
		return std::max(_aoeTargetsHitCount, (int)AoeTargetsHit.size());
	}

	Vector3 CastPosition()
	{
		return _castPosition.IsValid() && XPolygon::To2D(_castPosition).IsValid()
			? Engine::SetHeight(_castPosition)
			: Engine::SetHeight(Input.Unit->ServerPosition());
	}

	void CastPosition(Vector3 value)
	{
		_castPosition = value;
	}

	Vector3 UnitPosition()
	{
		return XPolygon::To2D(_unitPosition).IsValid() ? Engine::SetHeight(_unitPosition) : Engine::SetHeight(Input.Unit->ServerPosition());
	}

	void UnitPosition(Vector3 value)
	{
		_unitPosition = value;
	}


};

struct DashItem
{
	int Duration;
	Vector2 EndPos;
	int EndTick;
	bool IsBlink;
	std::vector<Vector2> Path;
	float Speed;
	Vector2 StartPos;
	int StartTick;
	CObject* Unit;
};

class Dash : public ModuleManager
{
public:
	std::unordered_map<int, DashItem > DetectedDashes = {};

	Dash()
	{

	}

	~Dash()
	{

	}
	float YasuoTick = 0;
	bool Q3Ready = false;
	void InitCustomData(CObject* unit)
	{
		DetectedDashes[unit->NetworkID()] = DashItem();
	}

	DashItem GetDashInfo(CObject* unit)
	{
		return DetectedDashes.count(unit->NetworkID()) ? DetectedDashes[unit->NetworkID()] : DashItem();
	}

	bool IsDashing(CObject* unit)
	{
		if (DetectedDashes.count(unit->NetworkID()) && !unit->HasBuffOfType(BuffType::Knockup) && unit->GetPath().size() != 0)
		{
			return DetectedDashes[unit->NetworkID()].EndTick != 0;
		}

		return false;
	}
	void Init()
	{
		for (auto hero : global::enemyheros)
		{
			InitCustomData((CObject*)hero.actor);
		}
	}
	void Draw()
	{

		/*auto windwall = Cache::windwall;
		if (Engine::GameGetTickCount() - Cache::windwall.time < 0.1f)
		{
			Renderer::GetInstance()->DrawLine(Engine::WorldToScreenImVec2(XPolygon::To3D(windwall.StartPos)), Engine::WorldToScreenImVec2(XPolygon::To3D(windwall.Pos)), D3DCOLOR_RGBA(0, 255, 0, 255), 1);
		}

		auto target = targetselector->GetTarget(550);
		if (target->IsValidTarget())
		{
			if (Engine::GameGetTickCount() - Cache::windwall.time < 0.1f)
			{
				if (XPolygon::LineSegmentIntersection(windwall.StartPos, windwall.Pos, me->Pos2D(), target->Pos2D()).IsValid())
				{
					Renderer::GetInstance()->DrawLine(Engine::WorldToScreenImVec2(me->Position()), Engine::WorldToScreenImVec2(target->Position()), D3DCOLOR_RGBA(0, 255, 0, 255), 1);
				}
			}
			else
			{
				Renderer::GetInstance()->DrawLine(Engine::WorldToScreenImVec2(me->Position()), Engine::WorldToScreenImVec2(target->Position()), D3DCOLOR_RGBA(0, 255, 0, 255), 1);
			}
		}*/

	}
	void Tick()
	{

		for (auto hero : global::enemyheros)
		{
			CObject* unit = (CObject*)hero.actor;

			auto nid = unit->NetworkID();
			auto args = unit->GetAIManager();
			if (unit->IsDashing() && DetectedDashes[nid].EndTick == 0)
			{
				auto starttick = Engine::GameGetTickCount();// Utils.TickCount;
				DetectedDashes[nid].StartTick = Engine::TickCount();// Utils.TickCount;
				DetectedDashes[nid].Speed = args->DashSpeed();
				DetectedDashes[nid].StartPos = unit->PosServer2D();
				DetectedDashes[nid].Unit = unit;
				DetectedDashes[nid].Path = unit->GetPath();

				if (DetectedDashes[nid].Path.size() > 0)
					DetectedDashes[nid].EndPos = DetectedDashes[nid].Path.back();

				DetectedDashes[nid].EndTick = DetectedDashes[nid].StartTick
					+ (int)
					(1000
						* (DetectedDashes[nid].EndPos.Distance(
							DetectedDashes[nid].StartPos)
							/ DetectedDashes[nid].Speed));

				DetectedDashes[nid].Duration = DetectedDashes[nid].EndTick
					- DetectedDashes[nid].StartTick;

				//std::cout << "DETECTED DASH" << std::endl;


				if (!unit->GetSpellBook()->GetSpellSlotByID(_R)->IsReady() && unit->ChampionNameHash() == FNV("Malphite") &&
					DetectedDashes[nid].Speed > 1600.f && DetectedDashes[nid].Speed < 4500.f)
				{

					float delay = 0.0f;
					float width = 325;
					float range = 1000;
					float speed = 1500.f + unit->MoveSpeed();
					Geometry::Polygon path;
					Geometry::Polygon path2;

					path = XPolygon::CircleToPolygon(DetectedDashes[nid].EndPos, width + global::LocalData->gameplayRadius, 20);
					path2 = XPolygon::CircleToPolygon(DetectedDashes[nid].EndPos, width, 20);

					structspell_evade dataToAdd;
					dataToAdd.type = "circular";
					dataToAdd.cc = true;
					dataToAdd.danger = 5;
					dataToAdd.collision = false;
					dataToAdd.windwall = true;

					justevade->AddSpell((DWORD)unit, 0, path, path2, XPolygon::To3D(DetectedDashes[nid].StartPos), XPolygon::To3D(DetectedDashes[nid].EndPos), XPolygon::To3D(DetectedDashes[nid].EndPos),
						dataToAdd, speed, range, delay, width, "nope", me->Position().y, starttick, true, true, false);

					//std::cout << "DASH : " << DetectedDashes[nid].EndTick - Engine::TickCount() << std::endl;

				}
			}

			if (unit->ChampionNameHash() == FNV("Yasuo"))
			{

				if (unit->GetSpellBook()->GetSpellSlotByID(0)->IsReady() && unit->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->GetSpellNameHash() == FNV("YasuoQ3Wrapper"))
				{
					Q3Ready = true;
				}

				if (IsDashing(unit))
				{
					auto dashinfo = GetDashInfo(unit);
					if (Q3Ready && !unit->GetSpellBook()->GetSpellSlotByID(0)->IsReady() && unit->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->GetSpellNameHash() == FNV("YasuoQ3Wrapper") && YasuoTick != dashinfo.StartTick)
					{

						Q3Ready = false;
						YasuoTick = dashinfo.StartTick;

						float kekw = 1.0 - std::min((unit->AttackSpeedMod() * 100) * 0.0059880239520958f, 0.67f);

						float delay = std::max(0.4f * kekw, 0.133f);
						float width = 215;
						float range = 1000;
						float speed = FLT_MAX;
						Geometry::Polygon path;
						Geometry::Polygon path2;

						path = XPolygon::CircleToPolygon(dashinfo.EndPos, width + global::LocalData->gameplayRadius, 20);
						path2 = XPolygon::CircleToPolygon(dashinfo.EndPos, width, 20);

						structspell_evade dataToAdd;
						dataToAdd.type = "circular";
						dataToAdd.cc = true;
						dataToAdd.danger = 5;
						dataToAdd.collision = false;
						dataToAdd.windwall = false;

						justevade->AddSpell((DWORD)unit, 0, path, path2, XPolygon::To3D(dashinfo.StartPos), XPolygon::To3D(dashinfo.EndPos), XPolygon::To3D(dashinfo.EndPos),
							dataToAdd, speed, range, delay, width, "nope", me->Position().y, Engine::GameGetTickCount(), true, true, false);

					}
				}
			}

			if (DetectedDashes[nid].EndTick != 0 && Engine::TickCount() > DetectedDashes[nid].EndTick)
			{
				//std::cout << "DASH DELETED" << std::endl;
				DetectedDashes[nid].EndTick = 0;
			}
		}
	}
};
Dash* dash;


struct PathInfo
{
	std::vector<Vector3> Position = {};
	float Time = 0;
};

struct Spells
{
	std::string name;
	float duration = 0;
};

struct UnitTrackerInfo
{
	int NetworkId;
	int AaTick;
	int NewPathTick;
	float ClickAvarageTime;
	int StopMoveTick;
	int LastInvisableTick;
	int SpecialSpellFinishTick;
	std::vector<PathInfo> PathBank;

	bool missing = false;
};
class UnitTracker : public ModuleManager
{
public:
	std::vector<UnitTrackerInfo> UnitTrackerInfoList;
	std::vector<CObject*> Champion;
	std::vector<Spells> spells;
	std::vector<PathInfo> PathBank;

	UnitTracker()
	{

	}

	~UnitTracker()
	{

	}


	void Init()
	{
		spells.push_back(Spells({ "katarinar",  1 })); //Katarinas R
		spells.push_back(Spells({ "drain",  1 })); //Fiddle W
		spells.push_back(Spells({ "crowstorm",  1 })); //Fiddle R
		spells.push_back(Spells({ "consume",  0.5 })); //Nunu Q
		spells.push_back(Spells({ "absolutezero",  1 })); //Nunu R
		spells.push_back(Spells({ "staticfield",  0.5 })); //Blitzcrank R
		spells.push_back(Spells({ "cassiopeiapetrifyinggaze",  0.5 })); //Cassio's R
		spells.push_back(Spells({ "ezrealtrueshotbarrage",  1 })); //Ezreal's R
		spells.push_back(Spells({ "galioidolofdurand",  1 })); //Ezreal's R                                                                   
		spells.push_back(Spells({ "luxmalicecannon",  1 })); //Lux R
		spells.push_back(Spells({ "reapthewhirlwind",  1 })); //Jannas R
		spells.push_back(Spells({ "jinxw",  0.6 })); //jinxW
		spells.push_back(Spells({ "jinxr",  0.6 })); //jinxR
		spells.push_back(Spells({ "missfortunebullettime",  1 })); //MissFortuneR
		spells.push_back(Spells({ "shenstandunited",  1 })); //ShenR
		spells.push_back(Spells({ "threshe",  0.4 })); //ThreshE
		spells.push_back(Spells({ "threshrpenta",  0.75 })); //ThreshR
		spells.push_back(Spells({ "threshq",  0.75 })); //ThreshQ
		spells.push_back(Spells({ "infiniteduress",  1 })); //Warwick R
		spells.push_back(Spells({ "meditate",  1 })); //yi W
		spells.push_back(Spells({ "alzaharnethergrasp",  1 })); //Malza R
		spells.push_back(Spells({ "lucianq",  0.5 })); //Lucian Q
		spells.push_back(Spells({ "caitlynpiltoverpeacemaker",  0.5 })); //Caitlyn Q
		spells.push_back(Spells({ "velkozr",  0.5 })); //Velkoz R 
		spells.push_back(Spells({ "jhinr",  2 })); //Velkoz R 

		for (auto hero : global::enemyheros)
		{
			auto actor = (CObject*)hero.actor;
			Champion.push_back(actor);
			UnitTrackerInfo unitTrack;

			unitTrack.NetworkId = actor->NetworkID(), unitTrack.AaTick = Engine::TickCount(),
				unitTrack.StopMoveTick = Engine::TickCount(), unitTrack.NewPathTick = Engine::TickCount(),
				unitTrack.SpecialSpellFinishTick = Engine::TickCount(), unitTrack.LastInvisableTick = Engine::TickCount();
			UnitTrackerInfoList.push_back(unitTrack);
		}
	}

	float GetSpecialSpellEndTime(CObject* unit)
	{
		for (auto TrackerUnit : UnitTrackerInfoList)
			if (TrackerUnit.NetworkId == unit->NetworkID())
				return TrackerUnit.SpecialSpellFinishTick - Engine::TickCount();

		return 0;
	}

	float GetLastAutoAttackTime(CObject* unit)
	{
		for (auto TrackerUnit : UnitTrackerInfoList)
			if (TrackerUnit.NetworkId == unit->NetworkID())
				return Engine::TickCount() - TrackerUnit.AaTick;

		return 0;
	}

	float GetLastNewPathTime(CObject* unit)
	{
		for (auto TrackerUnit : UnitTrackerInfoList)
			if (TrackerUnit.NetworkId == unit->NetworkID())
				return Engine::TickCount() - TrackerUnit.NewPathTick;

		return 0;
	}

	float GetLastVisableTime(CObject* unit)
	{
		for (auto TrackerUnit : UnitTrackerInfoList)
			if (TrackerUnit.NetworkId == unit->NetworkID())
				return Engine::TickCount() - TrackerUnit.LastInvisableTick;

		return 0;
	}

	float GetLastStopMoveTime(CObject* unit)
	{
		for (auto TrackerUnit : UnitTrackerInfoList)
			if (TrackerUnit.NetworkId == unit->NetworkID())
				return Engine::TickCount() - TrackerUnit.StopMoveTick;

		return 0;
	}

	bool IsSpamClick(CObject* unit, float radius, float delay)
	{
		for (auto& x : UnitTrackerInfoList)
		{
			if (x.NetworkId == unit->NetworkID())
			{
				if (x.PathBank.size() < 3)
					return false;

				if (x.PathBank[2].Time - x.PathBank[1].Time < 180 && Engine::TickCount() - x.PathBank[2].Time < 90)
				{
					auto C = x.PathBank[1].Position.back();
					auto A = x.PathBank[2].Position.back();

					auto B = unit->Position();

					auto AB = pow(A.x - B.x, 2) + pow(A.z - B.z, 2);
					auto BC = pow(B.x - C.x, 2) + pow(B.z - C.z, 2);
					auto AC = pow(A.x - C.x, 2) + pow(A.z - C.z, 2);

					auto fixDelay = radius * 2 - unit->MoveSpeed() * delay;

					if (Engine::TickCount() - x.PathBank[2].Time > 100)
						return false;

					if (Engine::TickCount() - x.PathBank[0].Time > 900 + fixDelay)
						return false;


					auto anglez = Engine::fastcos((AB + BC - AC) / (2 * sqrt(AB) * sqrt(BC))) * 180 / M_PI;
					 

					//printf("NOT SPAM ANGLE %0.2f\n", anglez);
					if (x.PathBank[1].Position.back().Distance(x.PathBank[2].Position.back()) < 50)
					{
						//printf("SPAM PLACE\n");
						return false;
					}
					else if (anglez < 31 || anglez > 50 && anglez < 58)
					{
						//printf("SPAM ANGLE %0.2f\n", anglez);
						return true;
					}
					else
						return false;
				}
				else
					return false;

				/*auto pathBank = x.PathBank;

				if (pathBank[0].Position.size() < 2 || pathBank[1].Position.size() < 2 || pathBank[2].Position.size() < 2)
					return false;

				auto fixDelay = radius * 2 - unit->MoveSpeed() * delay;

				if (Engine::TickCount() - pathBank[2].Time > 100)
					return false;

				if (Engine::TickCount() - pathBank[0].Time > 900 + fixDelay)
					return false;

				auto pos1 = XPolygon::To2D(pathBank[0].Position.back()) - XPolygon::To2D(pathBank[0].Position.front());
				auto pos2 = XPolygon::To2D(pathBank[1].Position.back()) - XPolygon::To2D(pathBank[1].Position.front());
				auto pos3 = XPolygon::To2D(pathBank[2].Position.back()) - XPolygon::To2D(pathBank[2].Position.front());

				auto angle1 = pos1.AngleBetween(pos2);
				auto angle2 = pos2.AngleBetween(pos3);


				if (angle1 > 130 && angle2 > 130)
				{
					printf("SPAM ANGLE %0.f  %0.f  \n", angle1, angle2);
					return true;
				}

				auto C = x.PathBank[1].Position.back();
				auto A = x.PathBank[2].Position.back();

				auto B = unit->Position();

				auto AB = pow(A.x - B.x, 2) + pow(A.z - B.z, 2);
				auto BC = pow(B.x - C.x, 2) + pow(B.z - C.z, 2);
				auto AC = pow(A.x - C.x, 2) + pow(A.z - C.z, 2);

				if (Engine::fastcos((AB + BC - AC) / (2 * sqrt(AB) * sqrt(BC))) * 180 / M_PI < 31)
				{
					printf("SPAM ANGLE %0.f\n", Engine::fastcos((AB + BC - AC) / (2 * sqrt(AB) * sqrt(BC))) * 180 / M_PI);
					return true;
				}*/
			}

		}

		return false;
	}

	void Tick()
	{
		for (auto hero : global::enemyheros)
		{
			auto unit = (CObject*)hero.actor;
			for (auto& x : UnitTrackerInfoList)
			{
				if (x.NetworkId == unit->NetworkID())
				{
					if (unit->IsVisible())
					{
						auto Path = unit->GetPath3D();
						//OnNewPath
						if (x.PathBank.size() > 2)
						{
							float time0 = Engine::TickCount() - x.PathBank[2].Time;
							float time1 = x.PathBank[2].Time - x.PathBank[1].Time;
							float time2 = x.PathBank[1].Time - x.PathBank[0].Time;
							int i = 1;
							float sum = 0;
							if (time0 < 400 && Path.size() > 1)
							{
								sum += time0;
								i++;
							}
							if (time1 < 400 && x.PathBank[2].Position.size() > 1)
							{
								sum += time1;
								i++;
							}
							if (time2 < 400 && x.PathBank[1].Position.size() > 1)
							{
								sum += time2;
								i++;
							}
							x.ClickAvarageTime = (x.ClickAvarageTime + sum) / i;
						}

						if (Path.size() > 0)
							x.PathBank.push_back(PathInfo({ Path, (float)Engine::TickCount() }));

						if (x.PathBank.size() > 3)
							x.PathBank.erase(x.PathBank.begin());

						if (Path.size() > 1 && Path.back().Distance(Path.front()) > 1) // STOP MOVE DETECTION
						{
							x.NewPathTick = Engine::TickCount();
						}
						else
							x.StopMoveTick = Engine::TickCount();

						//OnProcessSpellCast
						auto activespell = unit->GetSpellBook()->GetActiveSpellEntry();
						if (activespell)
						{
							if (activespell->IsAutoAttack())
							{
								x.AaTick = Engine::TickCount();
							}
							else
							{
								auto foundSpell = std::find_if(spells.begin(), spells.end(), [&](Spells x) { return ToLower(x.name) == ToLower(activespell->GetSpellData()->GetSpellName()); });
								if (foundSpell != spells.end())
								{
									x.SpecialSpellFinishTick = Engine::TickCount() + (int)(foundSpell->duration * 1000);
								}
								else if (unit->IsWindingUp() || unit->IsRooted() || !unit->CanMove())
								{
									x.SpecialSpellFinishTick = Engine::TickCount() + 100;
								}
							}
						}
					}

					if (!unit->IsVisible())
					{
						x.LastInvisableTick = Engine::TickCount();
					}
				}
			}
		}
	}

	void Draw()
	{

	}
};

// Prediction
struct VectorMovementCollisionObject
{
	float _1;
	Vector2 _2;
};

UnitTracker* unittracker;
class Prediction : public ModuleManager
{
public:
	Slider* PredMaxRange;

	std::vector<std::string> hitchancename = {

		"Low",

		"Medium",

		"High",

		"VeryHigh",

		"Dashing",

		"Immobile " };
	CObject* SamiraInGame = nullptr;
	CObject* YasuoInGame = nullptr;

	HitChance hitQ;
	HitChance hitW;
	HitChance hitE;
	HitChance hitR;
	CheckBox* NewPaths;

	int method = 1;
	bool IreliaIngame = false;
	Prediction()
	{

	}

	~Prediction()
	{

	}


	void Init()
	{
		auto menu = NewMenu::CreateMenu("Prediction", "Prediction");

		std::string namesetting = global::LocalChampName;
		namesetting.append("Hitchance");

		auto Hitchancesetting = menu->AddMenu(namesetting.c_str(), global::LocalChampName.c_str());

		auto qMenu = Hitchancesetting->AddMenu("QHitchance", "Q Hitchance");
		hitQ = (HitChance)qMenu->AddList("HitChance", "Hit Chance", hitchancename, 2, [&](List*, int value)
			{
				hitQ = (HitChance)value;
			})->Value;

		auto wMenu = Hitchancesetting->AddMenu("WHitchance", "W Hitchance");
		hitW = (HitChance)wMenu->AddList("HitChance", "Hit Chance", hitchancename, 2, [&](List*, int value)
			{
				hitW = (HitChance)value;
			})->Value;

		auto eMenu = Hitchancesetting->AddMenu("EHitchance", "E Hitchance");
		hitE = (HitChance)eMenu->AddList("HitChance", "Hit Chance", hitchancename, 2, [&](List*, int value)
			{
				hitE = (HitChance)value;
			})->Value;

		auto rMenu = Hitchancesetting->AddMenu("RHitchance", "R Hitchance");
		hitR = (HitChance)rMenu->AddList("HitChance", "Hit Chance", hitchancename, 2, [&](List*, int value)
			{
				hitR = (HitChance)value;
			})->Value;

		NewPaths = menu->AddCheckBox("NewPaths", "Check OnNewPath", true);
		NewPaths->AddTooltip("Enable for better hits, but will cast slow");

		PredMaxRange = menu->AddSlider("PredMaxRange", "Max Range %", 100, 50, 100);

		/*method = (int)menu->AddList("Method", "Prediction Method",
			std::vector<std::string> {"LSharp", "YTS", }
		, 0, [&](List*, int value)
		{
			method = (int)value + 1;
		})->Value + 1;*/

		if (global::LocalChampNameHash == FNV("Irelia"))
		{
			IreliaIngame = true;
		}

		for (auto actor : Engine::GetHeros(1))
		{
			if (actor->ChampionNameHash() == FNV("Samira"))
			{
				SamiraInGame = actor;
			}
			else if (actor->ChampionNameHash() == FNV("Yasuo"))
			{
				YasuoInGame = actor;
			}
		}
	}
	void Tick()
	{

	}

	void Draw()
	{
		/*combo_spell E = combo_spell({ 920.f, 1.2f, 100.f, 1750.f, false, SkillshotType::SkillshotCircle });

		for (auto hero : global::objects)
		{
			CObject* unit = (CObject*)hero.actor;

			PredictionInput pi;
			pi.Aoe = false;
			pi.Collision = E.collision;
			pi.Delay = E.delay;
			pi.Range = E.range;
			pi.From(me->ServerPosition());
			pi.Radius = E.radius;
			pi.Unit = unit;
			pi.Speed = E.speed;
			pi.Type = E.type;


			auto W2S_buffer = Engine::WorldToScreenImVec2(unit->Position());
			auto W2S_buffer2 = Engine::WorldToScreenImVec2(GetPrediction(pi).CastPosition());
			Renderer::GetInstance()->DrawLine(W2S_buffer, W2S_buffer2, D3DCOLOR_RGBA(0, 255, 0, 255), 1);

		}*/
	}

	PredictionOutput GetPrediction(CObject* unit, float delay)
	{
		PredictionInput pi;
		pi.Unit = unit;
		pi.Delay = delay;
		return GetPrediction(pi);
	}

	PredictionOutput GetPrediction(CObject* unit, float delay, float radius)
	{
		PredictionInput pi;
		pi.Unit = unit;
		pi.Delay = delay;
		pi.Radius = radius;
		return GetPrediction(pi);
	}

	PredictionOutput GetPrediction(CObject* unit, float delay, float radius, float speed)
	{
		PredictionInput pi;
		pi.Unit = unit;
		pi.Delay = delay;
		pi.Radius = radius;
		pi.Speed = speed;
		return GetPrediction(pi);
	}

	/* PredictionOutput GetPrediction(
	   Obj_AI_Base unit,
	   float delay,
	   float radius,
	   float speed,
	   CollisionableObjects[] collisionable)
   {
	   return
		   GetPrediction(
			   new PredictionInput
			   { Unit = unit, Delay = delay, Radius = radius, Speed = speed, CollisionObjects = collisionable });
   }*/

	PredictionOutput GetPrediction(CObject* unit, PredictionInput input)
	{
		input.Unit = unit;
		return GetPrediction(input, true, true);
	}

	/*PredictionOutput GetPredictionNew(CObject* unit, PredictionInput input)
	{
		auto mePos = me->Position();
		auto Q1 = GetPrediction(unit, input);

		if (Q1.HitChance() == HitChance::Collision)
		{
			auto dir = (Q1.CastPosition() - mePos).Normalized();
			auto perp = (input.Radius + me->BoundingRadius()) * dir.Perpendicular();


			auto calcq = Q1.CastPosition() - perp + unit->BoundingRadius() * dir;
			auto calcq1 = Q1.CastPosition() + perp + unit->BoundingRadius() * dir;

			auto positions = std::vector<Vector3>({ Q1.CastPosition(),calcq.SetZ(unit->Position()),calcq1.SetZ(unit->Position()) });

			for (auto pred : GetCollisionTest(positions, input))
			{
				if (IsAboutToHit(unit, input, XPolygon::To2D(pred)))
				{
					auto output = PredictionOutput();
					output.Input = input;
					output.UnitPosition(unit->Position());
					output.CastPosition(pred);
					output.SetHitChance(HitChance::High);
					return output;
				}
			}
		}

		return Q1;
	}*/

	PredictionOutput GetPrediction(PredictionInput input)
	{
		return GetPrediction(input, true, true);
	}

	float SpeedFromVelocity(CObject* unit)
	{
		return unit->MoveSpeed();
		/*auto aimanager = unit->GetAIManager();
		if (unit->IsDashing())
			return aimanager->DashSpeed();

		Vector3 realVelocity = Vector3
		(
			aimanager->Velocity().x * 20,
			aimanager->Velocity().y * 20,
			aimanager->Velocity().z * 20
		);

		float velocitySpeed = Vector3::Zero.Distance(realVelocity);

		return velocitySpeed == 0.0f ? unit->MoveSpeed() : velocitySpeed;*/
	}


	Vector3 PredictUnitPosition(CObject* unit, int time)
	{
		float num = time / 1000.f * unit->MoveSpeed();
		auto waypoints = unit->GetWaypoints();
		for (int i = 0; i < waypoints.size() - 1; i++)
		{
			auto v = waypoints[i];
			auto to = waypoints[i + 1];
			float num2 = v.Distance(to);
			if (num2 > num)
			{
				return XPolygon::To3D(v.Extended(to, num));
			}
			num -= num2;
		}
		if (waypoints.size() != 0)
		{
			return XPolygon::To3D(waypoints.back());
		}
		return unit->ServerPosition();
	}

	VectorMovementCollisionObject VectorMovementCollision(
		Vector2 startPoint1,
		Vector2 endPoint1,
		float v1,
		Vector2 startPoint2,
		float v2,
		float delay = 0.f)
	{
		float sP1x = startPoint1.x,
			sP1y = startPoint1.y,
			eP1x = endPoint1.x,
			eP1y = endPoint1.y,
			sP2x = startPoint2.x,
			sP2y = startPoint2.y;

		float d = eP1x - sP1x, e = eP1y - sP1y;
		float dist = (float)sqrt(d * d + e * e), t1 = NAN;
		float S = abs(dist) > FLT_EPSILON ? v1 * d / dist : 0,
			K = (abs(dist) > FLT_EPSILON) ? v1 * e / dist : 0.f;

		float r = sP2x - sP1x, j = sP2y - sP1y;
		auto c = r * r + j * j;

		if (dist > 0.f)
		{
			if (abs(v1 - FLT_MAX) < FLT_EPSILON)
			{
				auto t = dist / v1;
				t1 = v2 * t >= 0.f ? t : NAN;
			}
			else if (abs(v2 - FLT_MAX) < FLT_EPSILON)
			{
				t1 = 0.f;
			}
			else
			{
				float a = S * S + K * K - v2 * v2, b = -r * S - j * K;

				if (abs(a) < FLT_EPSILON)
				{
					if (abs(b) < FLT_EPSILON)
					{
						t1 = (abs(c) < FLT_EPSILON) ? 0.f : NAN;
					}
					else
					{
						float t = -c / (2 * b);
						t1 = (v2 * t >= 0.f) ? t : NAN;
					}
				}
				else
				{
					auto sqr = b * b - a * c;
					if (sqr >= 0)
					{
						auto nom = (float)sqrt(sqr);
						auto t = (-nom - b) / a;
						t1 = v2 * t >= 0.f ? t : NAN;
						t = (nom - b) / a;
						auto t2 = (v2 * t >= 0.f) ? t : NAN;

						if (!isnan(t2) && !isnan(t1))
						{
							if (t1 >= delay && t2 >= delay)
							{
								t1 = std::min(t1, t2);
							}
							else if (t2 >= delay)
							{
								t1 = t2;
							}
						}
					}
				}
			}
		}
		else if (abs(dist) < FLT_EPSILON)
		{
			t1 = 0.f;
		}

		return VectorMovementCollisionObject({ t1, (!isnan(t1)) ? Vector2(sP1x + S * t1, sP1y + K * t1) : Vector2::Zero });
	}
	float PathLength(std::vector<Vector2> path)
	{
		auto distance = 0.f;
		for (int i = 0; i < path.size() - 1; i++)
		{
			distance += path[i].Distance(path[i + 1]);
		}
		return distance;
	}
	std::vector<Vector2> CutPath(std::vector<Vector2> path, float distance)
	{
		std::vector<Vector2> result;
		float Distance = distance;
		if (distance < 0)
		{
			path[0] = path[0] + distance * (path[1] - path[0]).Normalized();
			return path;
		}

		for (int i = 0; i < path.size() - 1; i++)
		{
			float dist = path[i].Distance(path[i + 1]);
			if (dist > Distance)
			{
				result.push_back(path[i] + Distance * (path[i + 1] - path[i]).Normalized());
				for (int j = i + 1; j < path.size(); j++)
				{
					result.push_back(path[j]);
				}

				break;
			}
			Distance -= dist;
		}
		return result.size() > 0 ? result : std::vector<Vector2>({ path.back() });
	}
	PredictionOutput GetPositionOnPath(PredictionInput input, std::vector<Vector2> path, float speed = -1)
	{
		speed = (abs(speed - (-1)) < FLT_EPSILON) ? SpeedFromVelocity(input.Unit) : speed;

		auto pLength = PathLength(path);

		if (pLength < 5)
		{
			auto output = PredictionOutput();
			output.Input = input;
			output.UnitPosition(input.Unit->ServerPosition());
			output.CastPosition(input.Unit->ServerPosition());
			output.SetHitChance(HitChance::High);
			return output;
		}

		//Skillshots with only a delay
		float tDistance = input.Delay * speed - input.RealRadius();
		if (pLength >= tDistance && abs(input.Speed - FLT_MAX) < FLT_EPSILON)
		{
			for (int i = 0; i < path.size() - 1; i++)
			{
				auto a = path[i];
				auto b = path[i + 1];
				auto d = a.Distance(b);

				if (d >= tDistance)
				{
					auto direction = (b - a).Normalized();

					auto cp = a + direction * tDistance;
					auto p = a +
						direction *
						((i == path.size() - 2)
							? std::min(tDistance + input.RealRadius(), d)
							: (tDistance + input.RealRadius()));


					auto output = PredictionOutput();
					output.Input = input;
					output.CastPosition(XPolygon::To3D(cp));
					output.UnitPosition(XPolygon::To3D(p));
					output.SetHitChance(HitChance::High);

					return output;
				}

				tDistance -= d;
			}
		}

		//Skillshot with a delay and speed.
		if (pLength >= tDistance && abs(input.Speed - FLT_MAX) > FLT_EPSILON)
		{
			auto d = tDistance;
			if (input.Type == SkillshotType::SkillshotLine || input.Type == SkillshotType::SkillshotCone)
			{
				if (input.From().DistanceSquared(input.Unit->Position()) < 200 * 200)
				{
					d = input.Delay * speed;
				}
			}

			path = CutPath(path, d);

			float tT = 0.f;
			for (int i = 0; i < path.size() - 1; i++)
			{
				auto a = path[i];
				auto b = path[i + 1];
				auto tB = a.Distance(b) / speed;
				auto direction = (b - a).Normalized();
				a = a - speed * tT * direction;
				auto sol = VectorMovementCollision(a, b, speed, XPolygon::To2D(input.From()), input.Speed, tT);
				auto t = (float)sol._1;
				auto pos = (Vector2)sol._2;

				if (pos.IsValid() && t >= tT && t <= tT + tB)
				{
					if (pos.DistanceSquared(b) < 20)
						break;
					auto p = pos + input.RealRadius() * direction;

					if (input.Type == SkillshotType::SkillshotLine && false)
					{
						auto alpha = (XPolygon::To2D(input.From()) - p).AngleBetween(a - b);
						if (alpha > 30 && alpha < 180 - 30)
						{
							auto beta = (float)asin(input.RealRadius() / p.Distance(XPolygon::To2D(input.From())));
							auto cp1 = XPolygon::To2D(input.From()) + (p - XPolygon::To2D(input.From())).Rotated(beta);
							auto cp2 = XPolygon::To2D(input.From()) + (p - XPolygon::To2D(input.From())).Rotated(-beta);

							pos = cp1.Distance(pos) < cp2.Distance(pos) ? cp1 : cp2;
						}
					}

					auto output = PredictionOutput();
					output.Input = input;
					output.CastPosition(XPolygon::To3D(pos));
					output.UnitPosition(XPolygon::To3D(p));
					output.SetHitChance(HitChance::High);

					return output;
				}
				tT += tB;
			}
		}

		auto position = path.back();
		auto output = PredictionOutput();
		output.Input = input;
		output.CastPosition(XPolygon::To3D(position));
		output.UnitPosition(XPolygon::To3D(position));
		output.SetHitChance(HitChance::Medium);

		return output;
	}


	float DistanceSegment(
		Vector2 point,
		Vector2 segmentStart,
		Vector2 segmentEnd,
		bool onlyIfOnSegment = false,
		bool squared = false)
	{
		auto objects = Engine::ProjectOn(point, segmentStart, segmentEnd);

		if (objects.IsOnSegment || onlyIfOnSegment == false)
		{
			return squared
				? objects.SegmentPoint.DistanceSquared(point)
				: objects.SegmentPoint.Distance(point);
		}
		return FLT_MAX;
	}

	float DistanceSegment(
		Vector3 point,
		Vector3 segmentStart,
		Vector3 segmentEnd,
		bool onlyIfOnSegment = false,
		bool squared = false)
	{
		return DistanceSegment(Vector2(point.x, point.z), Vector2(segmentStart.x, segmentStart.z), Vector2(segmentEnd.x, segmentEnd.z), onlyIfOnSegment, squared);
	}

	PredictionOutput GetDashingPrediction(PredictionInput input)
	{
		auto dashData = dash->GetDashInfo(input.Unit);
		auto result = PredictionOutput();
		result.Input = input;

		//Normal dashes.
		if (!dashData.IsBlink)
		{
			//Mid air:
			auto endP = dashData.Path.back();
			auto dashPred = GetPositionOnPath(input, std::vector<Vector2>({ input.Unit->PosServer2D(), endP }), dashData.Speed);

			if (dashPred.HitChance() >= HitChance::High && DistanceSegment(XPolygon::To2D(dashPred.UnitPosition()), input.Unit->Pos2D(), endP, true) < 200)
			{
				dashPred.CastPosition(dashPred.UnitPosition());
				dashPred.SetHitChance(HitChance::Dashing);
				return dashPred;
			}

			//At the end of the dash:
			if (PathLength(dashData.Path) > 200)
			{
				auto timeToPoint = input.Delay / 2.f + XPolygon::To2D(input.From()).Distance(endP) / input.Speed - 0.25f;
				if (timeToPoint <= input.Unit->Pos2D().Distance(endP) / dashData.Speed + input.RealRadius() / input.Unit->MoveSpeed())
				{
					auto output = PredictionOutput();
					output.CastPosition(XPolygon::To3D(endP));
					output.UnitPosition(XPolygon::To3D(endP));
					output.SetHitChance(HitChance::Dashing);
					return output;
				}
			}

			result.CastPosition(XPolygon::To3D(dashData.Path.back()));
			result.UnitPosition(result.CastPosition());

			//Figure out where the unit is going.
		}

		return result;
	}
	PredictionOutput GetImmobilePrediction(PredictionInput input, double remainingImmobileT)
	{
		auto timeToReachTargetPosition = input.Delay + input.Unit->Position().Distance(input.From()) / input.Speed;

		if (timeToReachTargetPosition <= remainingImmobileT + input.RealRadius() / input.Unit->MoveSpeed())
		{
			auto output = PredictionOutput();
			output.CastPosition(input.Unit->ServerPosition());
			output.UnitPosition(input.Unit->ServerPosition());
			output.SetHitChance(HitChance::Immobile);
			return output;
		}

		auto output = PredictionOutput();
		output.Input = input;
		output.CastPosition(input.Unit->ServerPosition());
		output.UnitPosition(input.Unit->ServerPosition());
		output.SetHitChance(HitChance::High);
		return output;
		/*timeToReachTargetPosition - remainingImmobileT + input.RealRadius / input.Unit.MoveSpeed < 0.4d ? HitChance.High : HitChance.Medium*/
	}

	std::vector<Vector2> CutWaypoints(std::vector<Vector2> waypoints, float dist)
	{
		// cut the path at the given distance and return the remaining points
		if (dist < 0)
		{
			// if the distance is negative, extend the first segment
			waypoints[0] = waypoints[0].Extended(waypoints[1], dist);
			return waypoints;
		}
		std::vector<Vector2> result;
		float distance = dist;
		int size = waypoints.size();
		for (int i = 0; i < size - 1; i++)
		{
			float d = waypoints[i].Distance(waypoints[i + 1]);
			if (d > distance)
			{
				// found!
				result.push_back(waypoints[i].Extended(
					waypoints[i + 1], distance));
				for (int j = i + 1; j < size; j++)
					result.push_back(waypoints[j]);
				break;
			}
			distance -= d;
		}
		if (result.size() > 0) return result;
		// if the given distance is longer than path length,
		// then return the vector with last waypoint
		result.push_back(waypoints.back());
		return result;
	}

	bool smethod_1(CObject* aibaseClient_0, CObject* aibaseClient_1)
	{
		Vector2 left = aibaseClient_0->GetWaypoints().back();
		if (left == aibaseClient_0->Pos2D() || !aibaseClient_0->IsMoving())
		{
			return false;
		}
		Vector2 left2 = aibaseClient_1->GetWaypoints().back();
		if (!(left2 == aibaseClient_1->Pos2D()) && aibaseClient_1->IsMoving())
		{
			Vector2 vector = left - aibaseClient_0->Pos2D();
			Vector2 toVector = left2 - aibaseClient_1->Pos2D();
			return vector.AngleBetween(toVector) < 20.0f;
		}
		return false;
	}

	float smethod_9(PredictionInput& predictionInput_0, bool bool_0)
	{
		if (IreliaIngame)
		{
			return predictionInput_0.RealRadius();
		}
		/*if (predictionInput_0)
		{
			return predictionInput_0.RealRadius();
		}*/
		float num = predictionInput_0.Radius;
		if ((predictionInput_0.Type == SkillshotType::SkillshotCircle || predictionInput_0.Type == SkillshotType::SkillshotCone) && predictionInput_0.Radius >= 100.0f)
		{
			num *= 0.4f;
		}
		if (bool_0 && predictionInput_0.UseBoundingRadius)
		{
			if (std::abs(predictionInput_0.Speed - std::numeric_limits<float>::max()) < std::numeric_limits<float>::epsilon())
			{
				num += predictionInput_0.Unit->BoundingRadius() * 0.4f;
			}
			else
			{
				num += predictionInput_0.Unit->BoundingRadius();
			}
		}
		return num;
	}

	Vector3 GetWallPoint(Vector3 vector3_0, float float_0)
	{
		int count = 30;
		auto points = Engine::CirclePoints(30.0f, float_0, vector3_0);
		Vector3 first = Vector3();
		Vector3 last = Vector3();
		for (int i = 0; i < count; i++)
		{
			if (Engine::IsWall(points[i]))
			{
				if (!first.IsValid())
				{
					if (i == count - 1)
					{
						if (Engine::IsNotWall(points[0]))
						{
							first = points[i];
						}
					}
					else if (Engine::IsNotWall(points[i + 1]))
					{
						first = points[i];
					}
				}
				if (!last.IsValid())
				{
					if (i == 0)
					{
						if (Engine::IsNotWall(points[count - 1]))
						{
							last = points[i];
						}
					}
					else if (Engine::IsNotWall(points[i - 1]))
					{
						last = points[i];
					}
				}
			}
		}
		if (first.IsValid() && last.IsValid())
		{
			Vector3 finnaly = Vector3((last.x + first.x) / 2.0f, (last.y + first.y) / 2.0f, (last.z + first.z) / 2.0f);
			Vector3 vector4 = finnaly;
			int num2 = 0;
			while (static_cast<float>(num2) < float_0)
			{
				vector4 = vector3_0.Extended(finnaly, static_cast<float>(num2 * 3));
				if (Engine::IsWall(vector4))
				{
					break;
				}
				num2++;
			}


			return vector4;
		}
		return Vector3();
	}

	PredictionOutput GetPrediction(PredictionInput& input, bool ft, bool checkCollision)
	{
		//input.Radius /= 1.8f;
		bool debug = false;
		PredictionOutput result;

		if (!input.Unit->IsValidTarget())
		{
			return result;
		}

		if (ft)
		{
			//Increase the delay due to the latency and server tick:
			input.Delay += Engine::GetPing() / 2000.f + 0.06f;
			if (std::abs(input.Range - std::numeric_limits<float>::max()) > std::numeric_limits<float>::epsilon())
			{
				input.Range *= PredMaxRange->Value / 100.f;
				//	std::cout << input.Range << std::endl;
			}
			if (input.Aoe)
			{
				//return AoePrediction.GetPrediction(input);
			}
		}

		//Target too far away.
		if (abs(input.Range - FLT_MAX) > FLT_EPSILON && input.Unit->ServerPosition().Distance(input.RangeCheckFrom()) > pow(input.Range * 1.5, 2))
		{
			auto output = PredictionOutput();
			output.Input = input;
			//std::cout << "Too far" << std::endl;
			return output;
		}

		bool useGetStandardPrediction = false;
		//Unit is dashing.
		if (dash->IsDashing(input.Unit))
		{
			if (debug) printf(textonce("PRED D: DASHING\n"));
			result = GetDashingPrediction(input);
			useGetStandardPrediction = true;
		}
		else
		{
			//Unit is immobile.
			auto remainingImmobileT = UnitIsImmobileUntil(input.Unit);
			//if (debug) printf(textonce("PRED RN: %0.0f\n"), remainingImmobileT);
			if (remainingImmobileT >= 0.0f)
			{
				if (debug) printf(textonce("PRED I: IMMOBILE\n"));
				result = GetImmobilePrediction(input, remainingImmobileT);
				useGetStandardPrediction = true;
			}
		}

		//Normal prediction
		if (!useGetStandardPrediction)
		{
			{
				if (debug) printf(textonce("PRED N: NORMAL PREDICTION\n"));
				result = GetStandardPrediction(input, method);
			}
		}

		if (input.Unit->IsHero() && input.Radius > 1 && (result.HitChance() >= HitChance::Medium || result.HitChance() <= HitChance::VeryHigh))
		{
			auto moveOutWall = input.Unit->BoundingRadius() + input.Radius / 2 + 10;
			if (input.Type == SkillshotType::SkillshotCircle)
				moveOutWall = input.Unit->BoundingRadius();

			auto wallPoint = GetWallPoint(result.CastPosition(), moveOutWall);
			if (wallPoint.IsValid())
			{
				if (debug) printf(textonce("PRED: Near WALL\n"));
				result.CastPosition(wallPoint.Extended(result.CastPosition(), moveOutWall));
			}
		}

		if (input.Unit->IsHero() && smethod_9(input, false) > 1.0f && (result.HitChance() >= HitChance::Medium || result.HitChance() <= HitChance::VeryHigh))
		{
			auto num2 = input.Unit->BoundingRadius() / 2.0f + smethod_9(input, false) / 2.0f + 20.0f;
			if (input.Type == SkillshotType::SkillshotCircle)
			{
				num2 = input.Unit->BoundingRadius();
			}
			auto castPosition = result.CastPosition();
			auto WallPoint = GetWallPoint(castPosition, 200.0f);


			if (WallPoint.IsValid() && WallPoint.Distance(castPosition) < num2 && WallPoint.Distance(input.Unit->Position()) < num2)
			{
				Vector2 vector2 = input.Unit->Pos2D() - XPolygon::To2D(WallPoint);
				Vector2 toVector = XPolygon::To2D(castPosition) - XPolygon::To2D(WallPoint);
				float num3 = vector2.AngleBetween(toVector);

				if (num3 > 70.0f && num3 < 90.0f)
				{
					if (debug) printf(textonce("PRED VR: WALL PREDICTION\n"));
					result.SetHitChance(HitChance::VeryHigh);
					result.CastPosition(WallPoint.Extended(castPosition, num2));
				}
			}
		}

		//Check if the unit position is in range
		if (/*input.Type == SkillshotType::SkillshotLine && input.Unit->IsMoving() && !IsAboutToHit(input, XPolygon::To2D(result.CastPosition())) ||*/ std::abs(input.Range - std::numeric_limits<float>::max()) > std::numeric_limits<float>::epsilon() && static_cast<double>(input.RangeCheckFrom().DistanceSquared(result.CastPosition())) > std::pow((double)(input.Range + ((input.Type == SkillshotType::SkillshotCircle) ? input.RealRadius() : 0.0f)), 2.0f))
		{
			result.SetHitChance(HitChance::OutOfRange);
		}

		//Check for collision
		if (checkCollision && input.Collision && result.HitChance() > HitChance::Impossible)
		{
			auto positions = std::vector<Vector3>({ result.CastPosition() });
			auto originalUnit = input.Unit;
			if (GetCollision(positions, input))
			{
				result.CollisionObjects = GetCollisionObjects(positions, input);

				result.CollisionObjects.erase(
					std::remove_if(result.CollisionObjects.begin(), result.CollisionObjects.end(),
						[&](CObject* x) {
							return x == originalUnit; }),
					result.CollisionObjects.end());

				//std::erase_if(result.CollisionObjects, [&](CObject* x) { return x == originalUnit; });
				result.SetHitChance(result.CollisionObjects.size() > 0 ? HitChance::Collision : result.HitChance());
			}
		}

		if (result.HitChance() == HitChance::Collision)
		{
			/*auto mePos = me->Position();
			auto dir = (result.CastPosition() - mePos).Normalized();
			auto perp = (input.Radius + me->BoundingRadius() / 2) * dir.Perpendicular();


			auto calcq = result.CastPosition() - perp * dir;
			auto calcq1 = result.CastPosition() + perp * dir;
			auto calcq2 = result.CastPosition() - perp + (input.Unit->BoundingRadius() / 4) * dir;
			auto calcq3 = result.CastPosition() + perp + (input.Unit->BoundingRadius() / 4) * dir;

			auto positions = std::vector<Vector3>({ result.CastPosition(), calcq.SetZ(input.Unit->Position()) , calcq1.SetZ(input.Unit->Position()), calcq2.SetZ(input.Unit->Position()) , calcq3.SetZ(input.Unit->Position()) });

			for (auto pred : GetCollisionTest(positions, input))
			{
				if (IsAboutToHit(input, XPolygon::To2D(pred)))
				{
					result.CastPosition(pred);
					result.SetHitChance(HitChance::High);
					return result;
				}
			}*/
		}

		//Set hit chance
		if ((result.HitChance() >= HitChance::Medium && result.HitChance() <= HitChance::VeryHigh))
		{
			result = WayPointAnalysis(result, input);
		}

		return result;
	}

	PredictionOutput WayPointAnalysis(PredictionOutput result, PredictionInput input)
	{
		bool debug = false;

		if (!input.Unit->IsHero() || input.Radius == 1)
		{
			result.SetHitChance(HitChance::VeryHigh);
			return result;
		}


		if (result.CastPosition().Distance(input.Unit->ServerPosition()) > 400.f)
		{
			result.SetHitChance(HitChance::Medium);
			return result;
		}

		// CAN'T MOVE SPELLS ///////////////////////////////////////////////////////////////////////////////////

		if (unittracker->GetSpecialSpellEndTime(input.Unit) > 100 || input.Unit->HasBuff(FNV("recall")) || (unittracker->GetLastStopMoveTime(input.Unit) < 100 && input.Unit->IsRooted()))
		{
			if (debug) printf(textonce("CAN'T MOVE SPELLS , Time : %0.0f \n"), unittracker->GetSpecialSpellEndTime(input.Unit));
			result.SetHitChance(HitChance::VeryHigh);
			result.CastPosition(input.Unit->Position());
			return result;
		}

		// NEW VISABLE ///////////////////////////////////////////////////////////////////////////////////
		if (unittracker->GetLastVisableTime(input.Unit) < 100)
		{
			if (debug) printf(textonce("PRED M: NEW VISABLE\n"));
			result.SetHitChance(HitChance::Medium);
			return result;
		}

		// PREPARE MATH ///////////////////////////////////////////////////////////////////////////////////
		auto wayPoints = input.Unit->GetWaypoints3D();

		auto lastWaypiont = wayPoints.back();

		if (!input.Unit->IsMoving())
		{
			lastWaypiont = input.Unit->ServerPosition();
		}

		auto distanceUnitToWaypoint = lastWaypiont.Distance(input.Unit->ServerPosition());
		auto distanceFromToUnit = input.From().Distance(input.Unit->ServerPosition());
		auto distanceFromToWaypoint = lastWaypiont.Distance(input.From());
		auto speedDelay = distanceFromToUnit / input.Speed;

		if (abs(input.Speed - FLT_MAX) < FLT_EPSILON)
			speedDelay = 0;

		float totalDelay = speedDelay + input.Delay;
		float moveArea = SpeedFromVelocity(input.Unit) * totalDelay;
		float fixRange = moveArea * 0.25f;

		auto LastNewPathTime = unittracker->GetLastNewPathTime(input.Unit);
		Vector3 pos1 = lastWaypiont - input.Unit->ServerPosition();
		Vector3 pos2 = input.From() - input.Unit->ServerPosition();
		auto getAngle = pos1.AngleBetween(pos2);


		if (NewPaths->Value && unittracker->GetLastNewPathTime(input.Unit) > 250.f && (double)input.Delay < 0.3)
		{
			if (debug) printf(textonce("PRED VH: OnNewPaths\n"));
			result.SetHitChance(HitChance::VeryHigh);
			return result;
		}


		if (input.Type == SkillshotType::SkillshotCircle)
		{
			moveArea -= input.Radius / 2;
		}
		/*if (!NavMesh.IsWallOfGrass(input.Unit.ServerPosition, 10) && NavMesh.IsWallOfGrass(input.From, 10))
		{
			if (debug) Console.WriteLine("PRED VH: BUSH CAST");
			result.Hitchance = HitChance.VeryHigh;
			return result;
		}*/

		if (input.Type == SkillshotType::SkillshotLine && getAngle > 30.f && getAngle < 150.f && input.Speed <= 1500.f && speedDelay > 0.2f)
		{
			if (debug) printf(textonce("PRED M: DogShit 1\n"));
			result.SetHitChance(HitChance::Medium);
			return result;
		}

		/*if (distanceFromToWaypoint <= distanceFromToUnit && distanceFromToUnit > input.Range - moveArea)
		{
			if (debug) printf(textonce("PRED M: DogShit 2\n"));
			result.SetHitChance(HitChance::Medium);
			return result;
		}*/

		if ((double)(totalDelay - input.Radius / 2.f / input.Speed) > 0.6 && (input.Unit->IsAutoAttacking() || !input.Unit->CanMove() || input.Unit->IsRooted()))
		{
			result.SetHitChance(HitChance::High);
			return result;
		}

		if (distanceUnitToWaypoint > 0.f)
		{
			if (getAngle < 20.f || (getAngle > 160.f && distanceUnitToWaypoint > 500.f) || smethod_1(me, input.Unit))
			{
				result.SetHitChance(HitChance::VeryHigh);
				return result;
			}
			// WALL LOGIC  ///////////////////////////////////////////////////////////////////////////////////

			auto points = from(Engine::CirclePoints(15, 300, input.Unit->Position())) >> where([&](Vector3 x)
				{
					return Engine::IsWall(x);
				}) >> to_vector();

				if (points.size() > 2)
				{
					bool runOutWall = true;
					for (auto toVector2 : points)
					{
						if (input.Unit->Position().Distance(toVector2) > lastWaypiont.Distance(toVector2))
						{
							runOutWall = false;
						}
					}
					if (runOutWall)
					{
						result.SetHitChance(HitChance::VeryHigh);
						return result;
					}

				}
				else if (unittracker->GetLastNewPathTime(input.Unit) > 250.f && (double)input.Delay < 0.3)
				{
					result.SetHitChance(HitChance::VeryHigh);
					return result;
				}
		}
		// FIX RANGE ///////////////////////////////////////////////////////////////////////////////////
		if (distanceFromToUnit > input.Range - fixRange)
		{
			if (input.Type != SkillshotType::SkillshotCircle)
			{
				if (wayPoints.size() <= 1 || getAngle < 150)
				{
					if (debug) printf(textonce("PRED M: Fix Range\n"));
					result.SetHitChance(HitChance::Medium);
					return result;
				}
			}
		}

		if (unittracker->IsSpamClick(input.Unit, input.Radius, input.Delay))
		{
			if (debug) printf(textonce("PRED VH: SPAM CLICK\n"));
			result.SetHitChance(HitChance::VeryHigh);
			result.CastPosition(input.Unit->Position());
			return result;
		}

		// SHORT CLICK DETECTION ///////////////////////////////////////////////////////////////////////////////////
		if (distanceUnitToWaypoint > 0 && distanceUnitToWaypoint < 100)
		{
			if (debug) printf(textonce("PRED M: SMALL WAYPOINT\n"));
			result.SetHitChance(HitChance::Medium);
			return result;
		}

		/*if (input.Unit->Health() < me->MaxHealth() * 0.2f + me->TotalAttackDamage() + me->TotalAbilityPower())
		{
			if (debug) printf(textonce("PRED VH: LOW HP ENEMY\n"));
			result.SetHitChance(HitChance::VeryHigh);
			return result;
		}*/

		if (me->HealthPercent() < 20)
		{
			if (debug) printf(textonce("PRED VH: LOW HP MY HERO\n"));
			result.SetHitChance(HitChance::VeryHigh);
			return result;
		}

		// SPECIAL CASES ///////////////////////////////////////////////////////////////////////////////////
		if (distanceFromToUnit < 250)
		{
			if (debug) printf(textonce("PRED VH: Near\n"));
			result.SetHitChance(HitChance::VeryHigh);
			return result;
		}
		else if (distanceFromToWaypoint < 250)
		{
			if (debug) printf(textonce("PRED VH: on way\n"));
			result.SetHitChance(HitChance::VeryHigh);
			return result;
		}

		if (input.Unit->HealthPercent() < 20.f)
		{
			if (debug) printf(textonce("PRED VR: LOW HEALTH\n"));
			result.SetHitChance(HitChance::VeryHigh);
			return result;
		}

		// SLOW LOGIC /////////////////////////////////////////////////////////////////////////////////// 
		auto remainingSlowT = UnitIsSlowed(input.Unit);
		if (remainingSlowT > 0.0f)
		{
			auto timeToReachTargetPosition = input.Delay + input.Unit->Position().Distance(input.From()) / input.Speed;

			if (timeToReachTargetPosition <= remainingSlowT + input.RealRadius() / SpeedFromVelocity(input.Unit))
			{
				if (debug) printf(textonce("PRED VH: SLOW\n"));
				result.SetHitChance(HitChance::VeryHigh);
				return result;
			}
			else
			{
				if (debug) printf(textonce("PRED M: SLOW BAD\n"));
				result.SetHitChance(HitChance::High);
				return result;
			}
		}

		if (input.Unit->MoveSpeed() < 250.f)
		{
			if (debug) printf(textonce("PRED VR: LOW MOVE SPEED\n"));
			result.SetHitChance(HitChance::VeryHigh);
			return result;
		}

		// DON'T MOVE
		if (wayPoints.size() <= 1)
		{
			auto stoptime = unittracker->GetLastStopMoveTime(input.Unit);
			if (stoptime < 1000)
			{
				//std::cout << unittracker->GetLastAutoAttackTime(input.Unit) << std::endl;
				//std::cout << totalDelay << std::endl;
				auto acitveSpell = input.Unit->GetSpellBook()->GetActiveSpellEntry();
				if (acitveSpell && acitveSpell->IsCastingSpell() && totalDelay <= acitveSpell->CastDelay())
				{
					if (debug) printf(textonce("PRED VH: Spell Cast Detection\n"));
					result.SetHitChance(HitChance::High);
					return result;
				}
				else if (acitveSpell && !acitveSpell->isAutoAttackAll() && acitveSpell->CastDelay() <= 0.1f)
				{
					if (debug) printf(textonce("PRED M: STOP CAST SPELL SOON \n"));
					result.SetHitChance(HitChance::High);
					return result;
				}
				else if (unittracker->GetLastAutoAttackTime(input.Unit) < 60 && totalDelay < 0.7f)
				{
					if (debug) printf(textonce("PRED VH: AA detection\n"));
					result.SetHitChance(HitChance::VeryHigh);
					return result;
				}
				else if (input.Unit->IsWindingUp())
				{
					if (debug) printf(textonce("PRED H: WindingUp\n"));
					result.SetHitChance(HitChance::High);
					return result;
				}
				else
				{
					if (debug) printf(textonce("PRED M: STOP HIGH \n"));
					result.SetHitChance(HitChance::High);
					return result;
				}
			}
			else
			{
				if (debug) printf(textonce("PRED VH: STOP LOGIC\n"));
				result.SetHitChance(HitChance::VeryHigh);
				return result;
			}
		}
		else //MOVE 
		{
			//if (Game.IsFogOfWar(input.Unit.Position.Extend(wayPoints.back(), 100)))
			//{
			//    OktwCommon.debug( "PRED VH: FOW cast");
			//    result.Hitchance = HitChance.VeryHigh;
			//    return result;
			//}

			if (distanceUnitToWaypoint > 1200)
			{
				if (debug) printf(textonce("PRED VH: LONG CLICK DETECTION\n"));
				result.SetHitChance(HitChance::VeryHigh);
				return result;
			}

			if (getAngle < 110 && getAngle > 40 && LastNewPathTime < 200)
			{
				if (debug) printf(textonce("PRED M: Bad Click\n"));
				result.SetHitChance(HitChance::Medium);
				return result;
			}

			if (getAngle > 105 && getAngle < 150 && distanceUnitToWaypoint < 600)
			{
				if (debug) printf(textonce("PRED M: Bad Click Angle\n"));
				result.SetHitChance(HitChance::Medium);
				return result;
			}

			if (distanceUnitToWaypoint > 500)
			{
				if (getAngle > 170 || getAngle < 10)
				{
					if (debug) printf(textonce("PRED VH: Angle run long cast\n"));
					result.SetHitChance(HitChance::VeryHigh);
					return result;
				}
			}

			if (input.Radius >= 90 && input.Speed > 3000 && input.Delay < 0.7)
			{
				if (debug) printf(textonce("PRED VH: RADIUS GOOD\n"));
				result.SetHitChance(HitChance::VeryHigh);
				return result;
			}

			if (distanceUnitToWaypoint > 500)
			{
				// RUN IN LANE DETECTION /////////////////////////////////////////////////////////////////////////////////// 
				for (auto x : Engine::GetTurrets())
				{
					if (x->Team() == input.Unit->Team() && x->IsAlive() && x->Position().Distance(input.From()) < 2500 && x->Position().Distance(input.Unit->Position()) > 400)
					{
						auto pos3 = x->Position() - input.Unit->Position();
						auto getAngle2 = pos1.AngleBetween(pos3);
						if (getAngle2 < 10)
						{
							if (debug) printf(textonce("PRED VH: Angle TURRET\n"));
							result.SetHitChance(HitChance::VeryHigh);
							return result;
						}
					}
				}
			}
			auto inSameDriection = IsMovingInSameDirection(input.Unit, me);
			if (inSameDriection || distanceUnitToWaypoint > 600)
			{
				if (getAngle > 130 || getAngle < 15)
				{
					if (debug) printf(textonce("PRED VH: Angle run\n"));
					result.SetHitChance(HitChance::VeryHigh);
					return result;
				}
			}

			if (wayPoints.size() == 2 && LastNewPathTime < 80 && totalDelay < 0.25)
			{
				if (debug) printf(textonce("PRED VH: NEW PATH\n"));
				result.SetHitChance(HitChance::VeryHigh);
				return result;
			}
		}

		return result;
	}

	float Interception(const Vector2 startPos, const Vector2 endPos,
		const Vector2 source, int speed, int missileSpeed, float delay = 0.0)
	{
		// dynamic circle-circle collision
		// https://ericleong.me/research/circle-circle/
		Vector2 dir = endPos - startPos;
		float magn = dir.Length();
		Vector2 vel = dir * float(speed) / magn;
		dir = startPos - source;
		float a = vel.LengthSquared() - missileSpeed * missileSpeed;
		float b = 2.0 * vel.Dot(dir);
		float c = dir.LengthSquared();
		float delta = b * b - 4.0 * a * c;
		if (delta >= 0.0) // at least one solution exists
		{
			delta = sqrtf(delta);
			float t1 = (-b + delta) / (2.0 * a),
				t2 = (-b - delta) / (2.0 * a);
			float t = 0.0;
			if (t2 >= delay)
				t = (t1 >= delay) ?
				fmin(t1, t2) : fmax(t1, t2);
			return t; // the final solution
		}
		return 0.0; // no solutions found
	}

	PredictionOutput GetStandardPredictionTest(PredictionInput input, int method = 1)
	{
		auto speed = input.Unit->MoveSpeed();
		auto speed2 = input.Unit->MoveSpeed();
		auto unit = input.Unit;

		if (unit->IsHero())
		{
			speed2 = SpeedFromVelocity(unit);

			if (input.Unit->Position().DistanceSquared(input.From()) < 230 * 230)
			{
				input.Delay /= 2;
				speed2 /= 1.5f;
			}
		}

		auto result1 = GetPositionOnPath(input, unit->GetWaypoints(), speed2);




		auto waypoints = unit->GetWaypoints();
		waypoints = CutWaypoints(waypoints,
			input.Delay * speed - input.RealRadius());
		// here is the part for handling dynamic prediction
		// for each path segment we calculate interception time
		float totalTime = 0;
		for (int i = 0; i < waypoints.size() - 1; i++)
		{
			Vector2 a = waypoints[i], b = waypoints[i + 1];
			float tB = a.Distance(b) / speed;
			a = a.Extended(b, -speed * totalTime);
			float t = Interception(a, b, me->Pos2D(),
				speed, input.Speed, totalTime);
			if (t > 0 && t >= totalTime && t <= totalTime + tB)
			{
				// interception time is valid, we found the solution
				float threshold = t * speed;
				//auto w2s = Engine::WorldToScreen(Vector3(output.CastPos.x, 0, output.CastPos.y));
				//auto w2s1 = Engine::WorldToScreen(Vector3(output.PredPos.x, 0, output.PredPos.y));
				//Renderer::GetInstance()->DrawLine(ImVec2(w2s.x, w2s.y), ImVec2(w2s1.x, w2s1.y), D3DCOLOR_ARGB(150, 10, 255, 10));
				result1.CastPosition((result1.CastPosition() + XPolygon::To3D(CutWaypoints(waypoints, threshold)[0])) / 2);
				result1.UnitPosition(unit->Position());
				result1.SetHitChance(HitChance::High);
				break;
			}
			else
			{
			}
			// if any segment didn't pass the test, we add unit's arrival
			// time on segment to the total time and use it for further tests
			totalTime += tB;
		}

		return result1;

	}

	PredictionOutput PredictPosition(PredictionInput input, std::vector<Vector2> waypoints, float speed)
	{
		auto output = PredictionOutput();
		output.Input = input;

		if (waypoints.size() <= 1)
		{
			output.CastPosition(input.Unit->ServerPosition());
			output.UnitPosition(input.Unit->ServerPosition());
			output.SetHitChance(HitChance::VeryHigh);
			output.navEnd = input.Unit->GetAIManager()->GetNavEnd();
			return output;
		}
		// calculate max boundary offset for cast position
		int offset = input.Radius +
			(input.UseBoundingRadius ? input.Unit->BoundingRadius() : 0);
		if (input.Speed == 0 || input.Speed >= 9999)
		{
			// our spell isn't a missile, so we cut waypoints based on
			// delay and movement speed, then we return the first point
			float threshold = input.Delay * input.Unit->MoveSpeed();
			/*output.CastPos = CutWaypoints(waypoints, threshold - offset)[0];
			output.PredPos = CutWaypoints(waypoints, threshold)[0];*/
			output.CastPosition(Engine::To3DHigh(CutWaypoints(waypoints, threshold - offset)[0]));
			output.UnitPosition(Engine::To3DHigh(CutWaypoints(waypoints, threshold)[0]));
			output.SetHitChance(HitChance::High);
			output.navEnd = input.Unit->GetAIManager()->GetNavEnd();
			return output;
		}
		// predict the unit path when spell windup already completed;
		// we subtract the offset this time - just in case if unit is going
		// to complete the path we'll have perfectly calculated positions;
		// run the drawing simulation, then you'll see what i mean ;)
		waypoints = CutWaypoints(waypoints,
			input.Delay * speed - input.RealRadius());
		// here is the part for handling dynamic prediction
		// for each path segment we calculate interception time
		float totalTime = 0;
		for (int i = 0; i < waypoints.size() - 1; i++)
		{
			Vector2 a = waypoints[i], b = waypoints[i + 1];
			float tB = a.Distance(b) / speed;
			a = a.Extended(b, -speed * totalTime);
			float t = Interception(a, b, me->Pos2D(),
				speed, input.Speed, totalTime);
			if (t > 0 && t >= totalTime && t <= totalTime + tB)
			{
				// interception time is valid, we found the solution
				float threshold = t * speed;
				output.CastPosition(Engine::To3DHigh(CutWaypoints(waypoints, threshold)[0]));
				output.UnitPosition(Engine::To3DHigh(CutWaypoints(waypoints, threshold + offset)[0]));
				output.SetHitChance(HitChance::High);
				output.navEnd = input.Unit->GetAIManager()->GetNavEnd();
				return output;
			}

			// if any segment didn't pass the test, we add unit's arrival
			// time on segment to the total time and use it for further tests
			totalTime += tB;
		}
		// no solution found, so unit is completing his path...
		Vector2 pos = waypoints.back();
		output.CastPosition(Engine::To3DHigh(pos));
		output.UnitPosition(Engine::To3DHigh(pos));
		output.SetHitChance(HitChance::Medium);
		output.navEnd = input.Unit->GetAIManager()->GetNavEnd();
		return output;
	}

	PredictionOutput GetStandardPrediction(PredictionInput input, int method = 1)
	{
		float speed = SpeedFromVelocity(input.Unit);
		auto kek = PredictPosition(input, input.Unit->GetWaypoints(), speed);
		return kek;
		/*auto speed = input.Unit->MoveSpeed();
		auto unit = input.Unit;
		if (method == 1)
		{
			if (unit->IsHero())
			{
				speed = SpeedFromVelocity(unit);

				if (input.Unit->Position().DistanceSquared(input.From()) < 230 * 230)
				{
					input.Delay /= 2;
					speed /= 1.5f;
				}
			}

			auto result = GetPositionOnPath(input, unit->GetWaypoints(), speed);

			return result;
		}
		if (method == 2)
		{


			return GetStandardPrediction(input, 1);
		}

		return GetStandardPrediction(input, 1);*/

	}

	float UnitIsImmobileUntil(CObject* unit)
	{
		return unit->GetBuffManager()->GetImmobileDuration();
	}

	float UnitIsSlowed(CObject* unit)
	{
		float t = 0.f;
		for (auto buff : unit->GetBuffManager()->Buffs())
		{
			if (buff.type == BuffType::Asleep || buff.type == BuffType::Slow)
				t = buff.remaintime;
		}

		return t;
	}

	bool IsMovingInSameDirection(CObject* source, CObject* target)
	{
		auto sourceLW = XPolygon::To3D(source->GetWaypoints().back());

		if (sourceLW == source->Position() || !source->IsMoving())
			return false;

		auto targetLW = XPolygon::To3D(target->GetWaypoints().back());

		if (targetLW == target->Position() || !target->IsMoving())
			return false;

		Vector2 pos1 = XPolygon::To2D(sourceLW) - XPolygon::To2D(source->Position());
		Vector2 pos2 = XPolygon::To2D(targetLW) - XPolygon::To2D(target->Position());
		auto getAngle = pos1.AngleBetween(pos2);

		if (getAngle < 20)
			return true;
		else
			return false;
	}

	std::vector<CObject*> GetCollisionObjects(std::vector<Vector3> positions, PredictionInput input)
	{
		auto list = std::vector<CObject*>();
		for (auto position : positions)
		{
			for (auto objectType : input.CollisionObjects)
			{
				switch (objectType)
				{
				case CollisionableObjects::Heroes:
				{
					auto targets = Engine::GetHeros(1);
					for (auto hero : from(targets) >> where([&](CObject* h) {
						return h->IsValidTarget(std::min(input.Range + input.Radius + 100.0f, 2000.0f), true, input.RangeCheckFrom());
						}) >> to_vector())
					{
						input.Unit = hero;
						auto prediction = Prediction::GetPrediction(input, false, false);

						if (DistanceSegment(prediction.UnitPosition(), input.From(), position, true, true) <= std::pow((input.Radius + 50.0f + hero->BoundingRadius()), 2.0f))
						{
							list.push_back(hero);

						}
					}
						break;
				}
				case CollisionableObjects::Minions: // minionmgr
				{
					auto minions = Engine::GetMinions(1);
					for (auto minion : from(minions) >> where([&](CObject* minion) {return minion != input.Unit && minion->IsValidTarget(std::min(input.Range + input.Radius + 100.0f, 2000.0f), true, input.From()); }) >> to_vector())
					{
						auto distanceFromToUnit = minion->ServerPosition().Distance(input.From());

						input.Unit = minion;
						PredictionOutput prediction3 = GetPrediction(input, false, false);

						if (DistanceSegment(prediction3.UnitPosition(), input.From(), position, true, true) <= std::pow(input.Radius + (minion->IsMoving() ? 50.0f : 15.0f) + minion->BoundingRadius(), 2.0f) && !MinionIsDead(input, minion, distanceFromToUnit))
						{
							list.push_back(minion);
						}


					}
					auto jungles = Engine::GetJungles(2);
					for (auto minion : from(jungles) >> where([&](CObject* minion) {return minion != input.Unit && minion->IsValidTarget(std::min(input.Range + input.Radius + 100.0f, 2000.0f), true, input.From()); }) >> to_vector())
					{
						auto distanceFromToUnit = minion->ServerPosition().Distance(input.From());

						input.Unit = minion;
						PredictionOutput prediction3 = GetPrediction(input, false, false);

						if (DistanceSegment(prediction3.UnitPosition(), input.From(), position, true, true) <= std::pow(input.Radius + (minion->IsMoving() ? 50.0f : 15.0f) + minion->BoundingRadius(), 2.0f) && !MinionIsDead(input, minion, distanceFromToUnit))
						{
							list.push_back(minion);
						}


					}
					break;
				}
				case CollisionableObjects::Building:
				{
					auto turrets = Engine::GetTurrets(0);
					for (auto minion : from(turrets) >> cpplinq::where([&](CObject* minion) {return minion->IsValidTarget(std::min(input.Range + input.Radius + 100.0f, 2000.0f), true, input.From()); }) >> to_vector())
					{

						float num8 = input.RealRadius() + minion->BoundingRadius() + 50.f;
						ProjectionInfo projectionInfo2 = Engine::ProjectOn(XPolygon::To2D(position), XPolygon::To2D(input.From()), minion->Pos2D());
						if (projectionInfo2.IsOnSegment && (projectionInfo2.SegmentPoint.Distance(XPolygon::To2D(position)) <= num8 || projectionInfo2.LinePoint.Distance(XPolygon::To2D(position)) <= num8))
						{
							list.push_back(minion);
						}
					}
					/*for (auto minion : from(ObjectManager.GetCrystals(true)) >> cpplinq::where([&](Obj_BarracksDampener* minion) {return minion->IsValidTarget(std::min(input->Range + input->Radius + 100.0f, 2000.0f), true, input->getFrom()); }) >> cpplinq::to_vector())
					{

						float num8 = input->getRealRadius() + minion->getBoundingRadius() + 50.f;
						ProjectionInfo projectionInfo2 = position.ProjectOn(input->getFrom(), minion->Position);
						if (projectionInfo2.IsOnSegment && (projectionInfo2.SegmentPoint.To2D().Distance(position.To2D()) <= num8 || projectionInfo2.LinePoint.To2D().Distance(position.To2D()) <= num8))
						{
							list.push_back((AIBaseClient*)minion);
						}
					}*/
					break;
				}
				case CollisionableObjects::Allies:
				{
					auto allies = Engine::GetHeros(2);
					for (auto hero : from(allies) >> cpplinq::where([&](CObject* h) {
						return h->Index() != me->Index() && h->IsValidTarget(std::min(input.Range + input.Radius + 100.0f, 2000.0f), true, input.RangeCheckFrom());
						}) >> cpplinq::to_vector())
					{
						input.Unit = hero;
						auto prediction = Prediction::GetPrediction(input, false, false);
						if (DistanceSegment(prediction.UnitPosition(), input.From(), position, true, true) <= std::pow((input.Radius + 50.0f + hero->BoundingRadius()), 2.0f))
						{
							list.push_back(hero);

						}
					}
						break;
				}
				case CollisionableObjects::Walls:

					for (auto i = 0; i < 20; i++)
					{
						auto step = position.Distance(input.From()) / 20;
						auto p = input.From().Extended(position, step * i);
						//if ((int)Game.GetCollisionFlags(p) & static_cast<int>(CollisionFlags::Wall)) // HasFlag(CollisionFlags::Wall)
						//{
						//	list.push_back(ObjectManager.Player);
						//}
					}

					break;
				case CollisionableObjects::YasuoWall:
					if (SamiraInGame != nullptr)
					{
						if (SamiraInGame != nullptr && SamiraInGame->IsValidTarget() && SamiraInGame->HasBuff(FNV("SamiraW")))
						{
							float num12 = 325.0f + input.RealRadius();
							if (SamiraInGame->Position().Distance(input.From()) <= num12)
							{
								list.push_back(SamiraInGame);
							}
							else if (position.Distance(SamiraInGame->ServerPosition()) <= num12)
							{
								list.push_back(SamiraInGame);
							}
							else
							{
								auto projectionInfo4 = Engine::ProjectOn(position, input.From(), SamiraInGame->ServerPosition());
								if (projectionInfo4.IsOnSegment && (projectionInfo4.SegmentPoint.Distance(position) <= num12 || projectionInfo4.LinePoint.Distance(position) <= num12))
								{
									list.push_back(SamiraInGame);
								}
							}
						}

					}
					if (YasuoInGame != nullptr)
					{
						if (Engine::GameGetTickCount() - Cache::windwall.time < 0.1f)
						{
							auto windwall = Cache::windwall;
							if (XPolygon::LineSegmentIntersection(windwall.StartPos, windwall.Pos, XPolygon::To2D(input.From()), XPolygon::To2D(position)).IsValid())
							{
								list.push_back(YasuoInGame);
							}
						}
					}

					break;
				}
			}

		}


		std::vector<CObject*> result = cpplinq::from(list) >> cpplinq::distinct() >> cpplinq::to_vector();
		return result;
	}

	bool GetCollision(std::vector<Vector3> positions, PredictionInput input)
	{
		auto origUnit = input.Unit;
		for (auto position : positions)
		{
			for (auto objectType : input.CollisionObjects)
			{
				switch (objectType)
				{
				case CollisionableObjects::Minions: // minionmgr
				{
					auto minions = Engine::GetMinions(1);
					for (auto minion : cpplinq::from(minions) >> cpplinq::where([&](CObject* minion) {return minion != input.Unit && minion->IsValidTarget(std::min(input.Range + input.Radius + 100, 2000.0f), true, input.From()); }) >> cpplinq::to_vector())
					{
						auto distanceFromToUnit = minion->ServerPosition().Distance(input.From());
						auto bOffset = minion->BoundingRadius() + input.Unit->BoundingRadius();
						if (distanceFromToUnit < bOffset)
						{
							if (MinionIsDead(input, minion, distanceFromToUnit))
							{
								continue;
							}
							else
							{
								return true;
							}
						}
						else if (minion->ServerPosition().Distance(position) < bOffset)
						{
							if (MinionIsDead(input, minion, distanceFromToUnit))
							{
								continue;
							}
							else
							{
								return true;
							}
						}
						else if (minion->ServerPosition().Distance(input.Unit->Position()) < bOffset)
						{
							if (MinionIsDead(input, minion, distanceFromToUnit))
							{
								continue;
							}
							else
							{
								return true;
							}
						}
						else
						{
							auto minionPos = minion->ServerPosition();
							int bonusRadius = 15;
							if (minion->IsMoving())
							{
								auto predInput2 = PredictionInput();
								predInput2.Collision = false;
								predInput2.Speed = input.Speed;
								predInput2.Delay = input.Delay;
								predInput2.Range = input.Range;
								predInput2.From(input.From());
								predInput2.Radius = input.Radius;
								predInput2.Unit = minion;
								predInput2.Type = input.Type;
								minionPos = GetPrediction(predInput2).CastPosition();
								bonusRadius = 50 + static_cast<int>(input.Radius);
							}

							if (DistanceSegment(minionPos, input.From(), position, true, true) <= std::pow((input.Radius + bonusRadius + minion->BoundingRadius()), 2.0f))
							{
								if (MinionIsDead(input, minion, distanceFromToUnit))
								{
									continue;
								}
								else
								{
									return true;
								}
							}
						}

					}
					auto jungles = Engine::GetJungles(2);
					for (auto minion : cpplinq::from(jungles) >> cpplinq::where([&](CObject* minion) {return minion != input.Unit && minion->IsValidTarget(std::min(input.Range + input.Radius + 100, 2000.0f), true, input.From()); }) >> cpplinq::to_vector())
					{
						auto distanceFromToUnit = minion->ServerPosition().Distance(input.From());
						auto bOffset = minion->BoundingRadius() + input.Unit->BoundingRadius();
						if (distanceFromToUnit < bOffset)
						{
							if (MinionIsDead(input, minion, distanceFromToUnit))
							{
								continue;
							}
							else
							{
								return true;
							}
						}
						else if (minion->ServerPosition().Distance(position) < bOffset)
						{
							if (MinionIsDead(input, minion, distanceFromToUnit))
							{
								continue;
							}
							else
							{
								return true;
							}
						}
						else if (minion->ServerPosition().Distance(input.Unit->Position()) < bOffset)
						{
							if (MinionIsDead(input, minion, distanceFromToUnit))
							{
								continue;
							}
							else
							{
								return true;
							}
						}
						else
						{
							auto minionPos = minion->ServerPosition();
							int bonusRadius = 15;
							if (minion->IsMoving())
							{
								auto predInput2 = PredictionInput();
								predInput2.Collision = false;
								predInput2.Speed = input.Speed;
								predInput2.Delay = input.Delay;
								predInput2.Range = input.Range;
								predInput2.From(input.From());
								predInput2.Radius = input.Radius;
								predInput2.Unit = minion;
								predInput2.Type = input.Type;
								minionPos = GetPrediction(predInput2).CastPosition();
								bonusRadius = 50 + static_cast<int>(input.Radius);
							}

							if (DistanceSegment(minionPos, input.From(), position, true, true) <= std::pow((input.Radius + bonusRadius + minion->BoundingRadius()), 2.0f))
							{
								if (MinionIsDead(input, minion, distanceFromToUnit))
								{
									continue;
								}
								else
								{
									return true;
								}
							}
						}

					}
					break;
				}
				case CollisionableObjects::Heroes:
				{
					auto heros = Engine::GetHeros(1);
					for (auto hero : cpplinq::from(heros) >> cpplinq::where([&](CObject* h) {
						return  h != origUnit && h->IsValidTarget(std::min(input.Range + input.Radius + 100.0f, 2000.0f), true, input.RangeCheckFrom());
						}) >> cpplinq::to_vector())
					{
						input.Unit = hero;

						auto prediction = Prediction::GetPrediction(input, false, false);

						if (DistanceSegment(prediction.UnitPosition(), input.From(), position, true, true) <= std::pow((input.Radius + 50.0f + hero->BoundingRadius()), 2.0f))
						{
							return true;
						}
					}
						break;
				}
				case CollisionableObjects::Walls:

					for (auto i = 0; i < 20; i++)
					{
						auto step = position.Distance(input.From()) / 20;
						auto p = input.From().Extended(position, step * i);
						//if ((int)Game.GetCollisionFlags(p) & static_cast<int>(CollisionFlags::Wall)) // HasFlag(CollisionFlags::Wall)
						//{
						//	return true;
						//}
					}

					break;

				case CollisionableObjects::YasuoWall:
					if (SamiraInGame != nullptr)
					{
						if (SamiraInGame != nullptr && SamiraInGame->IsValidTarget() && SamiraInGame->HasBuff(FNV("SamiraW")))
						{
							float num12 = 325.0f + input.RealRadius();
							if (SamiraInGame->Position().Distance(input.From()) <= num12)
							{
								return true;
							}
							else if (position.Distance(SamiraInGame->ServerPosition()) <= num12)
							{
								return true;
							}
							else
							{
								auto projectionInfo4 = Engine::ProjectOn(position, input.From(), SamiraInGame->ServerPosition());
								if (projectionInfo4.IsOnSegment && (projectionInfo4.SegmentPoint.Distance(position) <= num12 || projectionInfo4.LinePoint.Distance(position) <= num12))
								{
									return true;
								}
							}
						}
					}

					if (YasuoInGame != nullptr)
					{
						if (Engine::GameGetTickCount() - Cache::windwall.time < 0.1f)
						{
							auto windwall = Cache::windwall;
							if (XPolygon::LineSegmentIntersection(windwall.StartPos, windwall.Pos, XPolygon::To2D(input.From()), XPolygon::To2D(position)).IsValid())
							{
								return true;
							}
						}
					}

					break;
				}
			}
		}
		return false;
	}

	std::vector<Vector3> GetCollisionTest(std::vector<Vector3> positions, PredictionInput input)
	{
		std::vector<Vector3> result;
		for (auto position : positions)
		{
			auto positions = std::vector<Vector3>({ position });
			auto obj = GetCollisionObjects(positions, input);
			if (obj.size() == 0)
			{
				result.push_back(position);
				break;
			}
		}


		return result;
	}

	bool MinionIsDead(PredictionInput input, CObject* minion, float distance)
	{
		if (minion->Team() == 3)
			return minion->IsDead();

		float delay = (distance / input.Speed) + input.Delay;


		if (std::abs(input.Speed - std::numeric_limits<float>::max()) < std::numeric_limits<float>::epsilon())
		{
			delay = input.Delay;
		}

		int convert = static_cast<int>(delay * 1000) - Engine::GetPing();

		if (orbwalker->GetHealthPrediction(minion, convert, 0) <= 0)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	bool IsAboutToHit(PredictionInput input, Vector2 castpos)
	{
		auto target = input.Unit;
		float moveSpeed = target->MoveSpeed();
		Vector2 targetPos = target->Pos2D();

		auto castposz = me->Pos2D().Extended(castpos, input.Range);
		auto pos = XPolygon::AppendVector(targetPos, castpos, 99999);

		auto path = XPolygon::RectangleToPolygon(me->Pos2D(), castposz, input.Radius, target->BoundingRadius() / 2);
		if (input.Speed != FLT_MAX)
		{

			auto va = (pos - targetPos).Normalized() * moveSpeed;
			auto vb = (castpos - me->Pos2D()).Normalized() * input.Speed;
			auto da = targetPos - me->Pos2D();
			auto db = va - vb;
			auto a = db.Dot(db);
			auto b = 2 * da.Dot(db);
			auto c = da.Dot(da) - pow((input.Radius + target->BoundingRadius() * 2), 2);
			auto delta = b * b - 4 * a * c;
			if (delta >= 0)
			{
				auto rtDelta = sqrt(delta);
				auto t1 = (-b + rtDelta) / (2 * a), t2 = (-b - rtDelta) / (2 * a);
				return std::max(t1, t2) >= 0;
			}
			return false;
		}

		return path.PointInPolygon(targetPos.Extended(pos, moveSpeed));
	}
};

//-----------------------------------------------------------------------------------------
Prediction* prediction;
//-----------------------------------------------------------------------------------------