#pragma once
class BaseUlt : public ModuleManager
{
private:
public:

	struct UltSpellDataS
	{
		int SpellStage;
		float DamageMultiplicator;
		float Width;
		float Delay;
		float Speed;
		bool Collision;
		float MaxSpeed;
	};

	PredictionInput Ultimate;
	int LastUltCastT = 0;
	bool compatibleChamp = false;

	std::map<fnv::hash, UltSpellDataS> UltSpellData;

	CheckBox* baseUlt;

	BaseUlt()
	{
	}

	~BaseUlt()
	{
	}
	void Draw()
	{

	}
	float recallTimers[5] = { 0  ,0 ,0 ,0 ,0 };
	void Init()
	{

		UltSpellData[FNV("Jinx")] = UltSpellDataS({ 1 ,1.0f,112.5, 0.6f ,1700.f,true ,2500 });
		UltSpellData[FNV("Ashe")] = UltSpellDataS({ 0 ,1.0f,130.f, 0.25f ,1600.f,true });
		UltSpellData[FNV("Draven")] = UltSpellDataS({ 0 ,0.7f,160.f, 0.4f ,2000.f,true });
		UltSpellData[FNV("Ezreal")] = UltSpellDataS({ 0 ,0.7f,160.f, 1 ,2000.f,false });

		compatibleChamp = IsCompatibleChamp(global::LocalChampNameHash);

		if (!compatibleChamp)
			return;

		auto menu = NewMenu::CreateMenu("BaseUlt", "Base Ult");
		baseUlt = menu->AddCheckBox("BaseUlt", "Base Ult", true);

	}
	bool IsCompatibleChamp(fnv::hash championName)
	{
		return UltSpellData.count(championName) > 0;
	}

	float GetUltTravelTime(CObject* source, float speed, float delay, Vector2 targetpos)
	{

		float distance = source->Distance2D(targetpos);
		float missilespeed = speed;

		if (global::LocalChampNameHash == FNV("Jinx") && distance > 1350)
		{
			float accelerationrate = 0.3f; //= (1500f - 1350f) / (2200 - speed), 1 unit = 0.3units/second
			float acceldifference = distance - 1350.f;

			if (acceldifference > 150.f) //it only accelerates 150 units
				acceldifference = 150.f;

			auto difference = distance - 1700;

			missilespeed = (
				1350 * speed
				+ acceldifference * (speed + accelerationrate * acceldifference)
				+ difference * 2700
				) / distance;
			 
		}

		return distance / missilespeed + delay;
	}

	float GetTargetHealth(CObject* enemyInfo, int additionalTime)
	{
		//if (enemyInfo->IsVisible())
		return enemyInfo->Health();

		float predictedHealth = enemyInfo->Health() + enemyInfo->HealthRegen();// *((GetTickCount() - enemyInfo.last_visible_tick + additionalTime) / 1000.f);

		return predictedHealth > enemyInfo->MaxHealth() ? enemyInfo->MaxHealth() : predictedHealth;
	}

	void HandleUltTarget(CObject* enemyInfo, int i)
	{

		//std::cout << "HandleUltTarget Loaded" << std::endl;


		/*if (UltSpellData[global::LocalChampNameHash].Collision && IsCollidingWithChamps(champ, OktwCommon.EnemySpawnPoint.Position, UltSpellData[global::LocalChampNameHash].Width))
		{
			continue;
		}*/

		Vector2 EnemySpawnPoint = Vector2(394.000, 462.000);

		if (enemyInfo->Team() == 200)
			EnemySpawnPoint = Vector2(14340.000, 14390.000);

		auto timeneeded = GetUltTravelTime(enemyInfo, UltSpellData[global::LocalChampNameHash].Speed, UltSpellData[global::LocalChampNameHash].Delay, EnemySpawnPoint);
		float recall_cooldown = recallTimers[i] - Engine::GameGetTickCount();// std::max(0.f, recallTimers[i] - Engine::GameGetTickCount());



	/*	std::cout << "timeneeded " << timeneeded << std::endl;
		std::cout << "recall_cooldown " << recall_cooldown << std::endl;
		std::cout << "total " << timeneeded - recall_cooldown << std::endl;*/


		if (timeneeded - recall_cooldown >= 0.05)
		{

			float totalUltDamage = GetSpellDamage(me, enemyInfo, SpellSlot::R, UltSpellData[global::LocalChampNameHash].SpellStage) * UltSpellData[global::LocalChampNameHash].DamageMultiplicator;
			float recall_cooldown = std::max(0.f, recallTimers[i] - Engine::GameGetTickCount());
			float targetHealth = GetTargetHealth(enemyInfo, (int)(recall_cooldown * 1000));
			int time = Engine::TickCount();;

			if (totalUltDamage < targetHealth)
			{
				return;
			}

			CastSpellMM(3, Engine::WorldToMinimap3D(XPolygon::To3D(EnemySpawnPoint)));
		}
	}

	void Tick()
	{
		compatibleChamp = IsCompatibleChamp(global::LocalChampNameHash);

		if (!compatibleChamp)
			return;

		if (!baseUlt->Value || !me->IsAlive())
			return;

		int i = -1;
		for (auto object : global::enemyheros)
		{
			CObject* target = (CObject*)object.actor;
			if (target->IsEnemy())
			{
				i++;
				if (target->RecallState() == 6)
				{
					if (recallTimers[i] - Engine::GameGetTickCount() <= 0)
					{
						recallTimers[i] = Engine::GameGetTickCount() + 8.1f;
					}
					HandleUltTarget(target, i);
					//std::cout << "Base Ult Loaded  " << i << std::endl;
				}
			}
		}
	}
};

BaseUlt* baseult = nullptr;