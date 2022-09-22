#pragma once
#include <bitset>

bool PointOnLineSegment(Vector2 pt1, Vector2 pt2, Vector2 pt, double epsilon = 0.001)
{
	if (pt.x - std::fmax(pt1.x, pt2.x) > epsilon ||
		std::fmin(pt1.x, pt2.x) - pt.x > epsilon ||
		pt.y - std::fmax(pt1.y, pt2.y) > epsilon ||
		std::fmin(pt1.y, pt2.y) - pt.y > epsilon)
		return false;

	if (abs(pt2.x - pt1.x) < epsilon)
		return abs(pt1.x - pt.x) < epsilon || abs(pt2.x - pt.x) < epsilon;
	if (abs(pt2.y - pt1.y) < epsilon)
		return abs(pt1.y - pt.y) < epsilon || abs(pt2.y - pt.y) < epsilon;

	double x = pt1.x + (pt.y - pt1.y) * (pt2.x - pt1.x) / (pt2.y - pt1.y);
	double y = pt1.y + (pt.x - pt1.x) * (pt2.y - pt1.y) / (pt2.x - pt1.x);

	return abs(pt.x - x) < epsilon || abs(pt.y - y) < epsilon;
}

D3DMATRIX MatrixMultiplication(D3DMATRIX pM1, D3DMATRIX pM2)
{
	D3DMATRIX pOut;
	pOut._11 = pM1._11 * pM2._11 + pM1._12 * pM2._21 + pM1._13 * pM2._31 + pM1._14 * pM2._41;
	pOut._12 = pM1._11 * pM2._12 + pM1._12 * pM2._22 + pM1._13 * pM2._32 + pM1._14 * pM2._42;
	pOut._13 = pM1._11 * pM2._13 + pM1._12 * pM2._23 + pM1._13 * pM2._33 + pM1._14 * pM2._43;
	pOut._14 = pM1._11 * pM2._14 + pM1._12 * pM2._24 + pM1._13 * pM2._34 + pM1._14 * pM2._44;
	pOut._21 = pM1._21 * pM2._11 + pM1._22 * pM2._21 + pM1._23 * pM2._31 + pM1._24 * pM2._41;
	pOut._22 = pM1._21 * pM2._12 + pM1._22 * pM2._22 + pM1._23 * pM2._32 + pM1._24 * pM2._42;
	pOut._23 = pM1._21 * pM2._13 + pM1._22 * pM2._23 + pM1._23 * pM2._33 + pM1._24 * pM2._43;
	pOut._24 = pM1._21 * pM2._14 + pM1._22 * pM2._24 + pM1._23 * pM2._34 + pM1._24 * pM2._44;
	pOut._31 = pM1._31 * pM2._11 + pM1._32 * pM2._21 + pM1._33 * pM2._31 + pM1._34 * pM2._41;
	pOut._32 = pM1._31 * pM2._12 + pM1._32 * pM2._22 + pM1._33 * pM2._32 + pM1._34 * pM2._42;
	pOut._33 = pM1._31 * pM2._13 + pM1._32 * pM2._23 + pM1._33 * pM2._33 + pM1._34 * pM2._43;
	pOut._34 = pM1._31 * pM2._14 + pM1._32 * pM2._24 + pM1._33 * pM2._34 + pM1._34 * pM2._44;
	pOut._41 = pM1._41 * pM2._11 + pM1._42 * pM2._21 + pM1._43 * pM2._31 + pM1._44 * pM2._41;
	pOut._42 = pM1._41 * pM2._12 + pM1._42 * pM2._22 + pM1._43 * pM2._32 + pM1._44 * pM2._42;
	pOut._43 = pM1._41 * pM2._13 + pM1._42 * pM2._23 + pM1._43 * pM2._33 + pM1._44 * pM2._43;
	pOut._44 = pM1._41 * pM2._14 + pM1._42 * pM2._24 + pM1._43 * pM2._34 + pM1._44 * pM2._44;
	return pOut;
}

enum class BuffType {//68 ? ? ? ? 50 E8 ? ? ? ? 6A 01 8D 44 24 38
	Internal = 0,
	Aura = 1,
	CombatEnchancer = 2,
	CombatDehancer = 3,
	SpellShield = 4,
	Stun = 5,
	Invisibility = 6,
	Silence = 7,
	Taunt = 8,
	Berserk = 9,
	Polymorph = 10,
	Slow = 11,
	Snare = 12,
	Damage = 13,
	Heal = 14,
	Haste = 15,
	SpellImmunity = 16,
	PhysicalImmunity = 17,
	Invulnerability = 18,
	AttackSpeedSlow = 19,
	NearSight = 20,
	Fear = 22,
	Charm = 23,
	Poison = 24,
	Suppression = 25,
	Blind = 26,
	Counter = 27,
	Currency = 21,
	Shred = 28,
	Flee = 29,
	Knockup = 30,
	Knockback = 31,
	Disarm = 32,
	Grounded = 33,
	Drowsy = 34,
	Asleep = 35,
	Obscured = 36,
	ClickProofToEnemies = 37,
	Unkillable = 38
};

std::vector<BuffType> CCBuffs = { BuffType::Stun , BuffType::Taunt , BuffType::Snare , BuffType::Asleep , BuffType::Fear ,
BuffType::Snare , BuffType::Charm, BuffType::Suppression , BuffType::Flee, BuffType::Knockup };

struct BuffCustomCache {
	BuffType type = BuffType::Internal;
	DWORD buffhash = 0x0;
	int count = 0;
	float starttime = 0.f;
	float remaintime = 0.f;
	float endtime = 0.f;
	fnv::hash namehash = 0x0;
};

struct evadeSpell
{
	std::string name;
	int slot;
};

struct struct_slotspell
{
	float range;
	int danger;
	int slot;
};

struct structspell_evade
{
	std::string type;
	double danger;
	bool cc;
	bool collision;
	bool windwall;
};

struct structspell
{
	std::string type;
	double speed;
	double range;
	double delay;
	double radius;
	double danger;
	bool cc;
	bool collision;
	bool windwall;
	bool hitbox;
	bool fow;
	bool exception;
	bool extend;
	double angle;
	bool allowdodge = true;
	bool allowdraw = true;
	bool ignoredodge = false;
};

struct newstructspell
{
	std::string missileName;
	std::string displayName;
	int slot;
	std::string type;
	double speed;
	double range;
	double delay;
	double radius;
	double danger;
	bool cc;
	bool collision;
	bool windwall;
	bool hitbox;
	bool fow;
	bool exception;
	bool extend;
	double angle;
};

enum UnitTag {
	Unit_ = 1,
	Unit_Champion = 2,
	Unit_Champion_Clone = 3,
	Unit_IsolationNonImpacting = 4,
	Unit_KingPoro = 5,
	Unit_Minion = 6,
	Unit_Minion_Lane = 7,
	Unit_Minion_Lane_Melee = 8,
	Unit_Minion_Lane_Ranged = 9,
	Unit_Minion_Lane_Siege = 10,
	Unit_Minion_Lane_Super = 11,
	Unit_Minion_Summon = 12,
	Unit_Minion_SummonName_game_character_displayname_ZyraSeed = 13,
	Unit_Minion_Summon_Large = 14,
	Unit_Monster = 15,
	Unit_Monster_Blue = 16,
	Unit_Monster_Buff = 17,
	Unit_Monster_Camp = 18,
	Unit_Monster_Crab = 19,
	Unit_Monster_Dragon = 20,
	Unit_Monster_Epic = 21,
	Unit_Monster_Gromp = 22,
	Unit_Monster_Krug = 23,
	Unit_Monster_Large = 24,
	Unit_Monster_Medium = 25,
	Unit_Monster_Raptor = 26,
	Unit_Monster_Red = 27,
	Unit_Monster_Wolf = 28,
	Unit_Plant = 29,
	Unit_Special = 30,
	Unit_Special_AzirR = 31,
	Unit_Special_AzirW = 32,
	Unit_Special_CorkiBomb = 33,
	Unit_Special_EpicMonsterIgnores = 34,
	Unit_Special_KPMinion = 35,
	Unit_Special_MonsterIgnores = 36,
	Unit_Special_Peaceful = 37,
	Unit_Special_SyndraSphere = 38,
	Unit_Special_TeleportTarget = 39,
	Unit_Special_Trap = 40,
	Unit_Special_Tunnel = 41,
	Unit_Special_TurretIgnores = 42,
	Unit_Special_UntargetableBySpells = 43,
	Unit_Special_Void = 44,
	Unit_Special_YorickW = 45,
	Unit_Structure = 46,
	Unit_Structure_Inhibitor = 47,
	Unit_Structure_Nexus = 48,
	Unit_Structure_Turret = 49,
	Unit_Structure_Turret_Inhib = 50,
	Unit_Structure_Turret_Inner = 51,
	Unit_Structure_Turret_Nexus = 52,
	Unit_Structure_Turret_Outer = 53,
	Unit_Structure_Turret_Shrine = 54,
	Unit_Ward = 55,
};

struct UnitInfo {

public:
	std::string name;
	/*float healthBarHeight;
	float baseMovementSpeed;
	float baseAttackRange;
	float attackSpeedRatio;

	float acquisitionRange;
	float selectionRadius;
	float pathRadius;*/
	float baseAttackSpeed;
	float gameplayRadius;

	float basicAttackMissileSpeed;
	float basicAttackWindup;

	std::bitset<128> tags;

	static std::map<fnv::hash, UnitTag> TagMapping;
};

std::map<fnv::hash, UnitTag> UnitInfo::TagMapping = {
	{FNV("Unit_"), Unit_},
	{FNV("Unit_Champion"), Unit_Champion},
	{FNV("Unit_Champion_Clone"), Unit_Champion_Clone},
	{FNV("Unit_IsolationNonImpacting"), Unit_IsolationNonImpacting},
	{FNV("Unit_KingPoro"), Unit_KingPoro},
	{FNV("Unit_Minion"), Unit_Minion},
	{FNV("Unit_Minion_Lane"), Unit_Minion_Lane},
	{FNV("Unit_Minion_Lane_Melee"), Unit_Minion_Lane_Melee},
	{FNV("Unit_Minion_Lane_Ranged"), Unit_Minion_Lane_Ranged},
	{FNV("Unit_Minion_Lane_Siege"), Unit_Minion_Lane_Siege},
	{FNV("Unit_Minion_Lane_Super"), Unit_Minion_Lane_Super},
	{FNV("Unit_Minion_Summon"), Unit_Minion_Summon},
	{FNV("Unit_Minion_SummonName_game_character_displayname_ZyraSeed"), Unit_Minion_SummonName_game_character_displayname_ZyraSeed},
	{FNV("Unit_Minion_Summon_Large"), Unit_Minion_Summon_Large},
	{FNV("Unit_Monster"), Unit_Monster},
	{FNV("Unit_Monster_Blue"), Unit_Monster_Blue},
	{FNV("Unit_Monster_Buff"), Unit_Monster_Buff},
	{FNV("Unit_Monster_Camp"), Unit_Monster_Camp},
	{FNV("Unit_Monster_Crab"), Unit_Monster_Crab},
	{FNV("Unit_Monster_Dragon"), Unit_Monster_Dragon},
	{FNV("Unit_Monster_Epic"), Unit_Monster_Epic},
	{FNV("Unit_Monster_Gromp"), Unit_Monster_Gromp},
	{FNV("Unit_Monster_Krug"), Unit_Monster_Krug},
	{FNV("Unit_Monster_Large"), Unit_Monster_Large},
	{FNV("Unit_Monster_Medium"), Unit_Monster_Medium},
	{FNV("Unit_Monster_Raptor"), Unit_Monster_Raptor},
	{FNV("Unit_Monster_Red"), Unit_Monster_Red},
	{FNV("Unit_Monster_Wolf"), Unit_Monster_Wolf},
	{FNV("Unit_Plant"), Unit_Plant},
	{FNV("Unit_Special"), Unit_Special},
	{FNV("Unit_Special_AzirR"), Unit_Special_AzirR},
	{FNV("Unit_Special_AzirW"), Unit_Special_AzirW},
	{FNV("Unit_Special_CorkiBomb"), Unit_Special_CorkiBomb},
	{FNV("Unit_Special_EpicMonsterIgnores"), Unit_Special_EpicMonsterIgnores},
	{FNV("Unit_Special_KPMinion"), Unit_Special_KPMinion},
	{FNV("Unit_Special_MonsterIgnores"), Unit_Special_MonsterIgnores},
	{FNV("Unit_Special_Peaceful"), Unit_Special_Peaceful},
	{FNV("Unit_Special_SyndraSphere"), Unit_Special_SyndraSphere},
	{FNV("Unit_Special_TeleportTarget"), Unit_Special_TeleportTarget},
	{FNV("Unit_Special_Trap"), Unit_Special_Trap},
	{FNV("Unit_Special_Tunnel"), Unit_Special_Tunnel},
	{FNV("Unit_Special_TurretIgnores"), Unit_Special_TurretIgnores},
	{FNV("Unit_Special_UntargetableBySpells"), Unit_Special_UntargetableBySpells},
	{FNV("Unit_Special_Void"), Unit_Special_Void},
	{FNV("Unit_Special_YorickW"), Unit_Special_YorickW},
	{FNV("Unit_Structure"), Unit_Structure},
	{FNV("Unit_Structure_Inhibitor"), Unit_Structure_Inhibitor},
	{FNV("Unit_Structure_Nexus"), Unit_Structure_Nexus},
	{FNV("Unit_Structure_Turret"), Unit_Structure_Turret},
	{FNV("Unit_Structure_Turret_Inhib"), Unit_Structure_Turret_Inhib},
	{FNV("Unit_Structure_Turret_Inner"), Unit_Structure_Turret_Inner},
	{FNV("Unit_Structure_Turret_Nexus"), Unit_Structure_Turret_Nexus},
	{FNV("Unit_Structure_Turret_Outer"), Unit_Structure_Turret_Outer},
	{FNV("Unit_Structure_Turret_Shrine"), Unit_Structure_Turret_Shrine},
	{FNV("Unit_Ward"), Unit_Ward},
};

bool HasUnitTags(UnitInfo* unit, UnitTag type1) {
	return unit->tags.test(type1);
}

void UnitInfoSetTag(UnitInfo* unit, fnv::hash tagStr)
{
	unit->tags.set(unit->TagMapping[tagStr]);
}

namespace Geometry
{
	class Polygon
	{
	public:
		std::vector<Vector2> Points = std::vector<Vector2>();

		void Add(Vector2 point)
		{
			Points.push_back(point);
		}

		ClipperLib::Path ToClipperPath(std::vector<Vector2> Points)
		{
			ClipperLib::Path result;


			for (auto point : Points)
			{
				result.push_back(ClipperLib::IntPoint(point.x, point.y));
			}

			return result;
		}

		ClipperLib::Path ToClipperPath()
		{
			ClipperLib::Path result;

			for (auto point : Points)
			{
				result.push_back(ClipperLib::IntPoint(point.x, point.y));
			}

			return result;
		}

		//Clipper
		std::vector<Polygon> ToPolygons(ClipperLib::Paths v)
		{
			std::vector<Polygon> result;

			for (auto path : v)
			{
				result.push_back(ToPolygon(path));
			}

			return result;
		}

		Polygon ToPolygon(ClipperLib::Path v)
		{
			Polygon polygon;
			for (auto point : v)
			{
				polygon.Add(Vector2(point.X, point.Y));
			}
			return polygon;
		}

		Geometry::Polygon OffsetPolygon(Geometry::Polygon originalPath, double offset)
		{
			Geometry::Polygon resultOffsetPath;

			std::vector<ClipperLib::IntPoint> polygon;
			for (auto point : originalPath.Points)
			{
				polygon.push_back(ClipperLib::IntPoint(point.x, point.y));
			}

			ClipperLib::ClipperOffset* co = new ClipperLib::ClipperOffset();
			co->AddPath(polygon, ClipperLib::JoinType::jtMiter, ClipperLib::EndType::etClosedPolygon);

			std::vector<std::vector<ClipperLib::IntPoint>> solution;
			co->Execute(solution, offset);

			for (auto offsetPath : solution)
			{
				for (auto offsetPathPoint : offsetPath)
				{
					resultOffsetPath.Add(Vector2(offsetPathPoint.X, offsetPathPoint.Y));
				}
			}

			return resultOffsetPath;
		}


		ClipperLib::Paths ClipPolygons(std::vector<Polygon> polygons)
		{
			ClipperLib::Paths subj;
			ClipperLib::Paths clip;

			for (auto polygon : polygons)
			{
				subj.push_back(polygon.ToClipperPath());
				clip.push_back(polygon.ToClipperPath());
			}

			ClipperLib::Paths solution;
			ClipperLib::Clipper* c = new ClipperLib::Clipper();
			c->AddPaths(subj, ClipperLib::PolyType::ptSubject, true);
			c->AddPaths(clip, ClipperLib::PolyType::ptClip, true);
			c->Execute(ClipperLib::ClipType::ctUnion, solution, ClipperLib::PolyFillType::pftPositive, ClipperLib::PolyFillType::pftEvenOdd);

			return solution;
		}

		bool IsOutside(Vector2 point)
		{
			auto p = ClipperLib::IntPoint(point.x, point.y);
			return ClipperLib::PointInPolygon(p, ToClipperPath()) != 1;
		}
		int PointInPolygon(Vector2 point)
		{
			auto p = ClipperLib::IntPoint(point.x, point.y);
			return ClipperLib::PointInPolygon(p, ToClipperPath());
		}
	};
}



struct actor_struct
{
	uint32_t actor = 0;
	bool KSable = false;
	Vector3 oldLocation = Vector3::Zero;
	DWORD pushedTime = 0;
	float avgMoveClick = 0;
	Vector3 lastMoveTargetPosition = Vector3::Zero;
	DWORD pushedTimeLastMoveClick = 0;
	float lastexp = 0;
	float expdiff = 0;
	DWORD pushedTimeR = 0;
	DWORD pushedTimeD = 0;
	DWORD pushedTimeF = 0;
	DWORD pushedTimeGank = 0;
	LPDIRECT3DTEXTURE9 pTextureChamp = NULL;
	LPDIRECT3DTEXTURE9 pTextureChampRounded = NULL;

	LPDIRECT3DTEXTURE9 pTextureSpell1 = NULL;
	LPDIRECT3DTEXTURE9 pTextureSpell2 = NULL;

	LPDIRECT3DTEXTURE9 pTextureSpellRounded1 = NULL;
	LPDIRECT3DTEXTURE9 pTextureSpellRounded2 = NULL;

	DWORD missTime = 0;
	bool missing = false;
	DWORD inviTime = 0;
	bool ishero = false;

	float priority = 1;
	float skillrange[4];
	DWORD v33 = 0;
	std::vector<Vector3> path;
	UnitInfo* unitData;
	fnv::hash namehash = 0x0;
	std::string name = "";
};

struct minion_struct
{
	uint32_t actor;
};
struct jungle_struct
{
	uint32_t actor;
	std::string name;
};
struct ward_struct
{
	uint32_t actor;
	float time;
	float type;
	Vector3 position;
	std::string name;
	Geometry::Polygon vision;
};
struct trap_struct
{
	uint32_t actor;
};

struct ExpStruct
{
	float lastexp;
	float currexp;
};


struct ActiveAttackstruct
{
	uint32_t source;
	short target;
	float startTime;
	float endTime;
	float Delay;
	float animationTime;
	float projectileSpeed;
	bool isTurret;
	bool isHero;
	bool dead;
};

class SpellInfo {

public:
	// Values from game's data files
	std::string name;
	std::string icon;

	float delay;
	float castRange;
	float castRadius;
	float width;
	float height;
	float speed;
	float travelTime;
};

struct missle_struct
{
	uint32_t actor;
	int netId;
	Geometry::Polygon path;
	Geometry::Polygon path2;
	Geometry::Polygon path3;
	Geometry::Polygon path4;
	Vector2 position;
	Vector3 startPos;
	Vector3 placementPos;
	Vector3 endPos;
	double speed;
	double range;
	double delay;
	double radius;
	double radius2;
	double angle;
	std::string name;
	double startTime;
	std::string type;
	bool danger;
	bool cc;
	bool collision;
	bool windwall;
	double y;
	bool dodge = true;
	bool draw = true;
	bool ignoredodge = false;
	bool dead = false;
	float timedead = 0;
	bool isdodged = false;

	missle_struct(uint32_t actor, int netId, Geometry::Polygon path, Geometry::Polygon path2, Geometry::Polygon path3, Vector2 position, Vector3 startPos,
		Vector3 placementPos, Vector3 endPos, double speed, double range, double delay, double radius, double radius2, double angle, std::string name, double startTime,
		std::string type, bool danger, bool cc, bool collision, bool windwall, double y, bool dodge, bool draw, bool ignoredodge)
	{
		this->actor = actor;
		this->netId = netId;
		this->path = path;
		this->path2 = path2;
		this->path3 = path3;
		this->position = position;
		this->startPos = startPos;
		this->placementPos = placementPos;
		this->endPos = endPos;
		this->speed = speed;
		this->range = range;
		this->delay = delay;
		this->radius = radius;
		this->radius2 = radius2;
		this->angle = angle;
		this->name = name;
		this->startTime = startTime;
		this->type = type;
		this->danger = danger;
		this->cc = cc;
		this->collision = collision;
		this->windwall = windwall;
		this->y = y;
		this->dodge = dodge;
		this->draw = draw;
		this->ignoredodge = ignoredodge;

	}
	~missle_struct()
	{
		this->actor = 0;
		this->netId = 0;
		this->path = Geometry::Polygon();
		this->path2 = Geometry::Polygon();
		this->path3 = Geometry::Polygon();
		this->position = Vector2(0, 0);
		this->startPos = Vector3(0, 0, 0);
		this->placementPos = Vector3(0, 0, 0);
		this->endPos = Vector3(0, 0, 0);
		this->speed = 0;
		this->range = 0;
		this->delay = 0;
		this->radius = 0;
		this->radius2 = 0;
		this->angle = 0;
		this->name = std::string("");
		this->startTime = 0;
		this->type = std::string("");
		this->danger = 0;
		this->cc = 0;
		this->collision = 0;
		this->windwall = 0;
		this->y = 0;
		this->dodge = true;
		this->draw = true;
		this->ignoredodge = false;
	}
};

enum JungleCamps
{
	Gromp,
	BlueBuff,
	Wolves,
	Raptors,
	RedBuff,
	Golems,
	Baron,
	Dragon,
	Scuttler,
	Herald
};

struct jungletimer_struct
{
	uint32_t actor;
	bool currentlyAlive = true;
	int timeWhenKilled = 0;
	int respawnTime = 0; // in seconds
	int initialSpawnTime = 0; // in seconds
	std::string campName; // the name to display on the camp timer
	int timeUntilRespawn = 0; // used for display purposes only: in seconds
	JungleCamps campType;
};

enum class UnitType
{
	NeutralMinionCamp,
	FollowerObject,
	FollowerObjectWithLerpMovement,
	AIHeroClient,
	AIMarker,
	AIMinionClient,
	AIMinionCommon,
	LevelPropAI,
	AITurretClient,
	AITurretCommon,
	obj_GeneralParticleEmitter,
	MissileClient,
	DrawFX,
	UnrevealedTarget,
	obj_Barracks,
	obj_BarracksDampener,
	obj_Lake,
	obj_AnimatedBuilding,
	Building,
	obj_Levelsizer,
	obj_NavPoint,
	obj_SpawnPoint,
	obj_LampBulb,
	GrassObject,
	HQ,
	obj_InfoPoint,
	BasicLevelProp,
	LevelPropGameObject,
	LevelPropSpawnerPoint,
	obj_Shop,
	obj_Turret,
	Unknown
};

enum ScriptMode
{
	None = 0,
	Combo = 1,
	Mixed = 2,
	LastHit = 3,
	LaneClear = 4,
	JungleClear = 5,
	Fly = 6
};

enum OrbwalkerTargetType {
	Hero,
	Monster,
	Minion,
	Structure
};