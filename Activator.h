#pragma once
#include "CastSpell.h"
class Activator : public ModuleManager {
private:
	CheckBox* useBarrier;
	CheckBox* useHeal;
	Slider* HealHealthThreshold;
	Slider* BarrierHealthThreshold;
	CheckBox* useIgnite;
	CheckBox* useSmite;
	CheckBox* useSmiteOnEnemy;
	CheckBox* useSmiteEnemyAround;

	CheckBox* useItem;
	CheckBox* usePotion;
	Slider* PotionHealthThreshold;
	CheckBox* usePotionEnemyAround;

	CheckBox* EnableCleanse;
	Slider* CleanseDelay;
	CheckBox* OnlyuseinCombo;
	CheckBox* Stun;
	CheckBox* Snare;
	CheckBox* Charm;
	CheckBox* Fear;
	CheckBox* Suppression;
	CheckBox* Taunt;
	CheckBox* Blind;
	CheckBox* ClearIgnite;
	CheckBox* ClearExhaust;

	bool ProcessCleanse = false;

public:


	Activator()
	{

	}

	~Activator()
	{

	}
	int ignitedmg()
	{
		auto ignite_lot = me->GetSpellSlotByName("SummonerDot");
		if (ignite_lot == -1 || !IsReady(ignite_lot))
			return 0;

		int clvl = me->Level();
		int igniteint[] = { 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 370, 390, 410 };
		return igniteint[clvl - 1];
	}
	void autoignite(CObject* target, bool overridecast = false)
	{
		auto ignite_lot = me->GetSpellSlotByName("SummonerDot");

		if (ignite_lot == -1 || !IsReady(ignite_lot))
			return;

		if (target != nullptr && target->IsValidTarget(550 + target->BoundingRadius()))
		{
			if (target->Health() <= ignitedmg() || overridecast == true)
			{
				//printf("me_level %i | targethp: %f | ignitedmg %i\n", me->Level(), target->Health(), ignitedmg());
					//printf("casting igntie\n");
				CastSpell(ignite_lot, target);
			}
		}

		if (overridecast)
		{
			if (me->Position().Distance(target->Position()) <= 550 + target->BoundingRadius())
				CastSpell(ignite_lot, target);

		}
	}
	float galeforcedmg(CObject* target)
	{
		if (target)
		{
			if (me->Level() >= 10)
			{
				auto postlevel = me->Level() - 9;
				return me->CalculateDamage(target, (180 + (15 * postlevel) + .45 * me->BonusAttackDamage()) * (1 + floor(target->MissingHealthPercent() / 7) * .05), 2);
			}
			else
			{
				return me->CalculateDamage(target, (180 + .45 * me->BonusAttackDamage()) * (1 + floor(target->MissingHealthPercent() / 7) * .05), 2);
			}
		}
	}
	bool EnemyFocusingMe(float range)
	{
		auto bAtkMe = false;
		for (auto actora : global::enemyheros)
		{
			if (IsValid(actora.actor))
			{
				CObject* enemy = (CObject*)actora.actor;
				if (enemy)
				{
					if (enemy != NULL && enemy->Position().Distance(me->Position()) <= range)
					{
						if (enemy->GetSpellBook()->GetActiveSpellEntry()) {
							if (enemy->GetSpellBook()->GetActiveSpellEntry()->isAutoAttackAll() && enemy->GetSpellBook()->GetActiveSpellEntry()->targetID() == me->Index()) {
								bAtkMe = true;
							}
							if ((!enemy->GetSpellBook()->GetActiveSpellEntry()->isAutoAttackAll()) && enemy->GetSpellBook()->GetActiveSpellEntry()->targetID() == me->Index()) {
								bAtkMe = true;
							}
							if ((!enemy->GetSpellBook()->GetActiveSpellEntry()->isAutoAttackAll()) && me->Position().Distance(enemy->GetSpellBook()->GetActiveSpellEntry()->GetEndPos()) <= 200) {
								bAtkMe = true;
							}
							//if ((!enemy->GetSpellBook()->GetActiveSpellEntry()->isAutoAttackAll()) && IsLineCollisioned(me, enemy->Position(), enemy->GetSpellBook()->GetActiveSpellEntry()->GetEndPos(), 100)) {
							//	bAtkMe = true;
							//}
						}
					}
				}
			}




		}
		return bAtkMe;
	}

	void useDefensiveItems()
	{
		kItemID defensiveItemId[] = { kItemID::ZhonyasHourglass, kItemID::Stopwatch };


		for (kItemID item : defensiveItemId)
		{
			//Console.debug("Cast defensiveItemId");
			if (me->HealthPercent() < 20 && Engine::GetEnemyCount(1000, me->Position()) >= 1 && EnemyFocusingMe(2000))
			{
				//Console.debug("Cast defensiveItemId");
				CastItem(item);
			}
		}
	}
	void useOffensiveItems(CObject* target)
	{
		kItemID gapcloserADItemId[] = { kItemID::ProwlerClaw, kItemID::StrideBreaker }; //range 500 
		kItemID afterAAItemId[] = { kItemID::IronSpikeWhip };// , kItemID::ProwlerClaw, kItemID::StrideBreaker
		kItemID HealItemId[] = { kItemID::GoreDrinker };
		//range 300
		kItemID laneClearItemId[] = { kItemID::IronSpikeWhip, kItemID::GoreDrinker }; //range 300
		kItemID speedBoostItemId[] = { kItemID::ProwlerClaw, kItemID::StrideBreaker, kItemID::TurboChemTank };
		//kItemID logicItemId[] = { (kItemID)0 };
		//kItemID offensiveAPItemId[] = { (kItemID)0 };

		/*if (target != nullptr && target->IsValidTarget())
		{*/
		//printf("im here2\n");
		if (global::mode == ScriptMode::Combo)
		{
			if (me->HasItem(kItemID::HextechProtobelt01) && ((me->Position().Distance(target->Position()) > 225 && me->Position().Distance(target->Position()) <= 500) || orbwalker->AfterAutoAttack()))
			{
				if (!me->GetAIManager()->IsDashing())
				{
					CastItem(kItemID::HextechProtobelt01, target);
				}
			}

			if (me->HasItem(kItemID::ProwlerClaw) && me->Position().Distance(target->Position()) <= 600 + target->BoundingRadius())
			{

				CastItem(kItemID::ProwlerClaw, target);

			}

			if (me->HasItem(kItemID::Galeforce))
			{
				if (orbwalker->CanAttack() && me->Position().Distance(target->Position()) <= me->GetRealAutoAttackRange(target) + 400 && me->Position().Distance(target->Position()) > me->GetRealAutoAttackRange(target) && target->Health() > global::aadmg && target->Health() <= global::qdmg + galeforcedmg(target) + ignitedmg())
				{
					CastItem(kItemID::Galeforce, target);
				}
			}

			if (me->HasItem(kItemID::Everfrost))
			{
				PredictionInput Everfrost = PredictionInput({ 950.0f, .03f,80.0f, FLT_MAX, false, SkillshotType::SkillshotLine });

				if (me->IsInAutoAttackRange(target))
				{
					CastItem(kItemID::Everfrost, target->ServerPosition());

				}
				//if (me->Position().Distance(target->ServerPosition()) <= 950 && (target->GetBuffManager()->IsImmobile() || target->IsSlowed() || target->StatusFlags() ==  kGameObjectStatusFlags::Channeling))
				//{
				//	CastItem(kItemID::Everfrost, target->ServerPosition());

				//}

				if (me->IsInAutoAttackRange(target) || me->Position().Distance(target->Position()) <= 850.0f)
				{
					CastItem(target, kItemID::Everfrost, Everfrost);

				}

				if (me->Position().Distance(target->ServerPosition()) <= 850 && (target->GetBuffManager()->IsImmobile() /*|| target->IsSlowed()*/ || target->StatusFlags() == kGameObjectStatusFlags::Channeling))
				{
					CastItem(target, kItemID::Everfrost, Everfrost);

				}
			}
		}



		if (me->Position().Distance(target->Position()) <= 400 + target->BoundingRadius() && (global::mode == ScriptMode::Combo || global::mode == ScriptMode::Mixed || global::mode == ScriptMode::LaneClear))
		{
			for (kItemID item : HealItemId)
			{
				if (me->HealthPercent() <= 50 || me->CalculateDamage(target, me->TotalAttackDamage() * 1.1f, 1) >= target->Health() || (orbwalker->AfterAutoAttack() && global::mode == ScriptMode::LaneClear))
					CastItem(item);
			}

		}



		//if (me->Position().Distance(target->Position()) <= 600 && (global::mode== ScriptMode::Harass))
		//{
		//	for (kItemID item : logicItemId)
		//	{
		//		CastItem(item, target->Position());
		//	}
		//}
		//}

		if (global::mode == ScriptMode::Combo || global::mode == ScriptMode::Mixed || global::mode == ScriptMode::LaneClear)
		{
			for (kItemID item : afterAAItemId)
			{
				if (orbwalker->AfterAutoAttack())
					CastItem(item);
			}


		}
		//if (CountEnemyMinions(me, 300, me->TotalAD()) >= 2 && (global::mode == ScriptMode::LaneClear || GetAsyncKeyState(global::LastHitKey)))
		//{
		//	for (kItemID item : laneClearItemId)
		//	{
		//		castItem(item);
		//	}
		//}


		if (global::mode == ScriptMode::Combo || global::mode == ScriptMode::Mixed)
		{
			if (me->Position().Distance(target->Position()) > 300 && me->Position().Distance(target->Position()) <= 700)
			{
				for (kItemID item : speedBoostItemId)
				{
					CastItem(item);
				}
			}
		}
	}
	int smite_lot = -1;

	float smitedmg()
	{
		auto smite_lot = me->GetSpellSlotByName("SummonerSmite");

		auto spellhash = me->GetSpellBook()->GetSpellSlotByID(smite_lot)->GetSpellData()->GetSpellNameHash();
		if (spellhash == FNV("S5_SummonerSmitePlayerGanker")
			|| spellhash == FNV("S5_SummonerSmiteDuel"))
			return 900.f;

		return 450.f;
	}

	void autosmite()
	{
		auto smite_lot = me->GetSpellSlotByName("SummonerSmite");
		if (smite_lot == -1 || !IsReady(smite_lot) || !me->IsAlive())
			return;

		auto jungles = Engine::GetJunglesAround(500.f + 120.f);
		for (auto jungle : jungles)
		{
			float Ahealth = jungle->Health();

			if (Ahealth <= smitedmg())
			{
				if (jungle->IsEpicMonster() || (useSmiteEnemyAround->Value ? Engine::GetHerosAround(1000).size() > 0 : true) && jungle->IsLargeMonster())
				{
					Vector3 objectLocation = jungle->Position();
					Vector3 objectScreenLocation2 = Engine::WorldToScreen(objectLocation);
					if (!Engine::IsOutboundScreen(objectScreenLocation2) && objectScreenLocation2.x != 0 && objectScreenLocation2.y != 0)
					{
						if (Engine::GameGetTickCount() - last_smiteorder > humanizer_delay)
						{
							GetCursorPos(&previousMousePos);
							MoveMouse(objectScreenLocation2.x, objectScreenLocation2.y);
							KeyPress(CheckKey(smite_lot));
							std::this_thread::sleep_for(std::chrono::milliseconds(5));
							ResetMouse(previousMousePos.x, previousMousePos.y);
							last_smiteorder = Engine::GameGetTickCount();
						}
					}
				}
			}

		}
		if (IsReady(smite_lot) && useSmiteOnEnemy->Value)
		{
			for (auto object : global::enemyheros)
			{
				auto target = (CObject*)object.actor;
				if (target && global::mode == ScriptMode::Combo)
				{

					auto spellhash = me->GetSpellBook()->GetSpellSlotByID(smite_lot)->GetSpellData()->GetSpellNameHash();
					if (target && target->IsHero() && me->Position().Distance(target->Position()) <= 550 && spellhash == FNV("S5_SummonerSmiteDuel"))
					{
						//printf("i have red smite: hp: %f, smite: %f\n", target->Health(), 43.5 + 4.5 * me->Level());
						//if (!IsReady(me->GetSpellSlotByName("smite")))
						//	printf("smited\n");
						//redsmite	
						CastSpell(smite_lot, target);
					}

					if (target && target->IsHero() && me->Position().Distance(target->Position()) <= 550 && spellhash == FNV("S5_SummonerSmitePlayerGanker"))
					{

						//printf("i have blue smite: hp: %f, smite: %f\n", target->Health(), 19.882 + 8.118 * me->Level());
						//if (!IsReady(me->GetSpellSlotByName("smite")))
						//	printf("smited\n");
						//bluesmite
						if (target->Health() <= 19.882 + 8.118 * me->Level())
						{
							//printf("casitng smite\n");
							CastSpell(smite_lot, target);
						}
					}
				}
			}
		}
	}

	void autoheal()
	{


		if (Engine::GetHerosAround(1000).size() > 0)
		{
			if (me->GetSpellSlotByName("SummonerHeal") != -1 && useHeal->Value && me->HealthPercent() <= HealHealthThreshold->Value)
			{
				//printf("casting heal\n");
				CastSpell(me->GetSpellSlotByName("SummonerHeal"));
			}

			if (me->GetSpellSlotByName("SummonerBarrier") != -1 && useBarrier->Value && me->HealthPercent() <= BarrierHealthThreshold->Value)
			{
				//printf("casting barrier\n");
				CastSpell(me->GetSpellSlotByName("SummonerBarrier"));
			}
		}


	}


	void autopotion()
	{
		if (me->HealthPercent() <= PotionHealthThreshold->Value && (usePotionEnemyAround->Value ? Engine::GetHerosAround(1000).size() > 0 : true))
		{
			if (me->HasItem(kItemID::TotalBiscuitofRejuvenation) && !me->HasBuff(BuffHash::TotalBiscuitofRejuvenation))
			{
				CastItem(kItemID::TotalBiscuitofRejuvenation);
			}
			if (me->HasItem(kItemID::HealthPotion) && !me->HasBuff(BuffHash::HealthPotion))
			{
				CastItem(kItemID::HealthPotion);
			}
			if (me->HasItemStack(kItemID::RefillablePotion) && !me->HasBuff(BuffHash::RefillablePotion))
			{
				CastItem(kItemID::RefillablePotion);
			}
			if (me->HasItemStack(kItemID::CorruptingPotion) && !me->HasBuff(BuffHash::CorruptingPotion))
			{
				CastItem(kItemID::CorruptingPotion);
			}

		}
	}

	void Draw()
	{

	}
	void Init()
	{
		auto Activator = NewMenu::CreateMenu("Activator", "Activator");


		auto ignitesettings = Activator->AddMenu("ignitesettings", "Ignite");
		useIgnite = ignitesettings->AddCheckBox("autoignite", "Enable Ignite", true);


		auto smitesettings = Activator->AddMenu("smitesettings", "Smite");
		useSmite = smitesettings->AddCheckBox("useSmite", "Enable Smite", true);
		useSmiteOnEnemy = smitesettings->AddCheckBox("useSmiteEnemy", "Use Smite to enemies/KS", true);
		useSmiteEnemyAround = smitesettings->AddCheckBox("useSmiteEnemyAround", "Only use Smite when enemies is around", true);

		auto healsettings = Activator->AddMenu("healsettings", "Heal");
		useHeal = healsettings->AddCheckBox("autoheal", "Enable Heal", true);
		HealHealthThreshold = healsettings->AddSlider("HealThreshold", "% Health Threshold to use heal", 30, 20, 100, 5);

		auto barriersettings = Activator->AddMenu("barriersettings", "Barrier");
		useBarrier = barriersettings->AddCheckBox("autobarrier", "Enable Barrier", true);
		BarrierHealthThreshold = barriersettings->AddSlider("HealThreshold", "% Health to use barrier", 30, 20, 100, 5);

		auto exhaustsettings = Activator->AddMenu("exhaustsettings", "Exhaust");
		exhaustsettings->AddCheckBox("autoExhaust", "Enable Exhaust", true);

		auto cleansesettings = Activator->AddMenu("cleansesettings", "Cleanse");
		EnableCleanse = cleansesettings->AddCheckBox("autocleanse", "Enable Cleanse", true);
		OnlyuseinCombo = cleansesettings->AddCheckBox("OnlyuseinCombo", "Only use in Combo", true);
		CleanseDelay = cleansesettings->AddSlider("CleanseDelay", "Reaction time in ms", 200, 50, 750, 10);

		auto cleansetypesettings = cleansesettings->AddMenu("cctypesettings", "CC Type");
		Stun = cleansetypesettings->AddCheckBox("Stun", "Stun", true);
		Snare = cleansetypesettings->AddCheckBox("Snare", "Snare", true);
		Charm = cleansetypesettings->AddCheckBox("Charm", "Charm", true);
		Fear = cleansetypesettings->AddCheckBox("Fear", "Fear", true);
		Suppression = cleansetypesettings->AddCheckBox("Suppression", "Suppression", true);
		Taunt = cleansetypesettings->AddCheckBox("Taunt", "Taunt", true);
		Blind = cleansetypesettings->AddCheckBox("Blind", "Blind", true);
		ClearIgnite = cleansesettings->AddCheckBox("ClearIgnite", "Clear Ignite", true);
		ClearExhaust = cleansesettings->AddCheckBox("ClearExhaust", "Clear Exhaust", true);


		auto itemsettings = Activator->AddMenu("itemsettings", "Use Items");
		useItem = itemsettings->AddCheckBox("autoitem", "Enable Use Item", true);

		auto potionsettings = Activator->AddMenu("potionsettings", "Use Potions");
		usePotion = potionsettings->AddCheckBox("autopotion", "Auto Potion", true);
		PotionHealthThreshold = potionsettings->AddSlider("potionhealththreshold", "% Health to use Potion", 70, 20, 100, 5);
		usePotionEnemyAround = potionsettings->AddCheckBox("usePotionEnemyAround", "Only use Potion when enemies is around", true);

	}

	void autocleanse()
	{
		if (OnlyuseinCombo->Value && !(global::mode == ScriptMode::Combo))
			return;

		auto cleanse_slot = me->GetSpellSlotByName("SummonerBoost");

		std::vector<BuffType> offsets;
		if (Stun->Value)
			offsets.push_back(BuffType::Stun);
		if (Snare->Value)
			offsets.push_back(BuffType::Snare);
		if (Charm->Value)
			offsets.push_back(BuffType::Charm);
		if (Fear->Value)
			offsets.push_back(BuffType::Fear);
		if (Suppression->Value)
			offsets.push_back(BuffType::Suppression);
		if (Taunt->Value)
			offsets.push_back(BuffType::Taunt);
		if (Blind->Value)
			offsets.push_back(BuffType::Blind);

		if ((me->HasBuffOfType(offsets) || me->HasBuff(FNV("veigareventhorizonstun"))) || (ClearExhaust->Value && me->HasBuff(FNV("summonerexhaust"))) || (ClearIgnite->Value && me->HasBuff(FNV("summonerdot"))))
		{
			if (!ProcessCleanse)
			{
				ProcessCleanse = true;

				_DelayAction->Add(CleanseDelay->Value, [=]() {
					if (cleanse_slot != -1 && IsReady(cleanse_slot))
					{
						ProcessCleanse = false;
						CastSpell(cleanse_slot);
					}
					else if (me->HasItem(kItemID::QuicksilverSash))
					{
						ProcessCleanse = false;
						CastItem(kItemID::QuicksilverSash);
					}
					else if (me->HasItem(kItemID::MercurialScimitar))
					{
						ProcessCleanse = false;
						CastItem(kItemID::MercurialScimitar);
					}
					else if (me->HasItem(kItemID::SilverMereDawn))
					{
						ProcessCleanse = false;
						CastItem(kItemID::SilverMereDawn);
					}

					});
			}

		}
	}

	void Tick()
	{
		auto target = targetselector->GetTarget(600);

		if (target && useIgnite->Value)
			autoignite(target);


		if (useSmite->Value)
			autosmite();

		if (EnableCleanse->Value)
			autocleanse();

		if (useItem->Value)
		{
			useOffensiveItems(target);
			useDefensiveItems();
		}

		if (usePotion->Value)
			autopotion();

		if (useHeal->Value || useBarrier->Value)
			autoheal();
	}
};

Activator* activator;