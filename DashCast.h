#pragma once
class DashCast : public ModuleManager {
private:
public:
	enum class DashingMode
	{
		GameCursor,

		Side,

		Safeposition
	};

	enum class GapingcloserMode
	{
		GameCursor,

		Awaysafeposition,

		Disable
	};
	NewMenu* menu;
	std::vector<std::string> dashmodename = { "Game Cursor", "Side", "Safe position" };

	std::vector<std::string> gapclosermodename = { "Game Cursor", "Away - safe position", "Disable" };

	DashingMode DashModeSetting = DashingMode::GameCursor;
	GapingcloserMode GapMode = GapingcloserMode::GameCursor;
	PredictionInput DashSpell;

	Slider* EnemyCheck;

	CheckBox* WallCheck;
	CheckBox* TurretCheck;
	CheckBox* AAcheck;

	DashCast()
	{

	}

	~DashCast()
	{

	}

	void Draw()
	{

	}
	void Init()
	{
	}
	void Init2(NewMenu* menu, PredictionInput spell)
	{
		DashSpell = spell;
		auto Dash = menu->AddMenu("Dash", "Dash Cast");// NewMenu::CreateMenu("Dash", "Dash Cast");
		DashModeSetting = (DashingMode)Dash->AddList("DashMode", "Dash MODE", dashmodename, 0, [&](List*, int value)
			{
				DashModeSetting = (DashingMode)value;
			})->Value;
		EnemyCheck = Dash->AddSlider("EnemyCheck", "Block dash in x enemies", 3, 0, 5, 1);

		WallCheck = Dash->AddCheckBox("WallCheck", "Block dash in wall", true);
		TurretCheck = Dash->AddCheckBox("TurretCheck", "Block dash under turret", true);
		AAcheck = Dash->AddCheckBox("AAcheck", "Dash only in AA range", false);
		GapMode = (GapingcloserMode)Dash->AddList("GapcloserMode", "Gapcloser MODE", gapclosermodename, 0, [&](List*, int value)
			{
				GapMode = (GapingcloserMode)value;
			})->Value;
	}

	Vector3 CastDash(bool asap = false)
	{
		int DashMode = (int)DashModeSetting;

		Vector3 bestpoint = Vector3::Zero;
		if (DashMode == 0)
		{
			bestpoint = me->Position().Extended(Engine::GetMouseWorldPosition(), DashSpell.Range);
		}
		else if (DashMode == 1)
		{
			auto orbT = orbwalker->GetTarget();
			if (orbT != nullptr && orbT->IsHero())
			{
				Vector2 start = me->Pos2D();
				Vector2 end = orbT->Pos2D();
				auto dir = (end - start).Normalized();
				auto pDir = dir.Perpendicular();

				auto rightEndPos = end + pDir * me->Distance(orbT);
				auto leftEndPos = end - pDir * me->Distance(orbT);

				auto rEndPos = Vector3(rightEndPos.x, me->Position().y, rightEndPos.y);
				auto lEndPos = Vector3(leftEndPos.x, me->Position().y, leftEndPos.y);

				if (Engine::GetMouseWorldPosition().Distance(rEndPos) < Engine::GetMouseWorldPosition().Distance(lEndPos))
				{
					bestpoint = me->Position().Extended(rEndPos, DashSpell.Range);
				}
				else
				{
					bestpoint = me->Position().Extended(lEndPos, DashSpell.Range);
				}
			}
		}
		else if (DashMode == 2)
		{
			auto points = Engine::CirclePoints(15, DashSpell.Range, me->Position());
			bestpoint = me->Position().Extended(Engine::GetMouseWorldPosition(), DashSpell.Range);
			int enemies = Engine::GetEnemyCount(350, bestpoint);
			for (auto point : points)
			{
				int count = Engine::GetEnemyCount(350, point);
				if (!InAARange(point))
					continue;

				if (justevade->IsDangerous(XPolygon::To2D(point)))
					continue;

				if (Engine::UnderAllyTurret(point))
				{
					bestpoint = point;
					enemies = count - 1;
				}
				else if (count < enemies)
				{
					enemies = count;
					bestpoint = point;
				}
				else if (count == enemies && Engine::GetMouseWorldPosition().Distance(point) < Engine::GetMouseWorldPosition().Distance(bestpoint))
				{
					enemies = count;
					bestpoint = point;
				}
			}
		}

		if (!bestpoint.IsValid())
			return Vector3::Zero;


		auto isGoodPos = IsGoodPosition(bestpoint);

		if (asap && isGoodPos)
		{
			return bestpoint;
		}
		else if (isGoodPos && InAARange(bestpoint))
		{
			return bestpoint;
		}

		return Vector3::Zero;
	}

	bool InAARange(Vector3 point)
	{
		if (!AAcheck->Value)
			return true;
		
		auto target = orbwalker->GetTarget();

		if (target != nullptr && target->IsHero())
		{
			return point.Distance(target->Position()) < me->AttackRange() - 65.f;
		}
		else
		{
			return Engine::GetEnemyCount(me->AttackRange(),point) > 0;
		}
	}

	bool IsGoodPosition(Vector3 dashPos)
	{
		if (WallCheck->Value)
		{
			float segment = DashSpell.Range / 5;
			for (int i = 1; i <= 5; i++)
			{
				auto pos = me->Position().Extended(dashPos, i * segment);
				if (Engine::IsWall(pos))
					return false;
			}
		}

		if (justevade->IsDangerous(XPolygon::To2D(dashPos)))
			return false;

		if (TurretCheck->Value)
		{
			if (Engine::UnderTurret(dashPos))
				return false;
		}

		auto enemyCheck = EnemyCheck->Value;
		auto enemyCountDashPos = Engine::GetEnemyCount(600, dashPos);

		if (enemyCheck > enemyCountDashPos)
			return true;

		auto enemyCountPlayer = Engine::GetEnemyCount(700, me->Position());

		if (enemyCountDashPos < enemyCountPlayer)
			return true;

		return false;
	}

	void Tick()
	{
		for (auto unit : Engine::GetHeros())
		{

			if (dash->IsDashing(unit))
			{
				auto dashData = dash->GetDashInfo(unit);
				if (IsReady((int)DashSpell.Slot) && me->Pos2D().Distance(dashData.EndPos) < 200)
				{
					if (GapMode == GapingcloserMode::GameCursor)
					{
						auto bestpoint = me->Position().Extended(Engine::GetMouseWorldPosition(), DashSpell.Range);
						if (IsGoodPosition(bestpoint))
							CastSpell((int)DashSpell.Slot, Engine::WorldToScreen(bestpoint));
					}
					else if (GapMode == GapingcloserMode::Awaysafeposition)
					{
						auto points = Engine::CirclePoints(15, DashSpell.Range, me->Position());
						auto bestpoint = me->Position().Extended(XPolygon::To3D(dashData.EndPos), -DashSpell.Range);
						int enemies = Engine::GetEnemyCount(DashSpell.Range, bestpoint);
						for (auto point : points)
						{
							if (justevade->IsDangerous(XPolygon::To2D(point)))
								continue;

							int count = Engine::GetEnemyCount(DashSpell.Range, point);
							if (count < enemies)
							{
								enemies = count;
								bestpoint = point;
							}
							else if (count == enemies && Engine::GetMouseWorldPosition().Distance(point) < Engine::GetMouseWorldPosition().Distance(bestpoint))
							{
								enemies = count;
								bestpoint = point;
							}
						}
						if (IsGoodPosition(bestpoint))
							CastSpell((int)DashSpell.Slot, Engine::WorldToScreen(bestpoint));
					}
				}
			}
		}

	}
};

DashCast* dashcast;