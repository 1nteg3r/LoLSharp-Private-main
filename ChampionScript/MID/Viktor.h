#pragma once
class Viktor : public ModuleManager {
public:
	CheckBox* UseQ;
	CheckBox* UseW;
	CheckBox* UseE;
	CheckBox* UseR;

	CheckBox* AutoFollowR;
	CheckBox* RkS;
	KeyBind* forceR;
	Slider* HitR;
	Slider* rTick;


	CheckBox* harassUseQ;
	CheckBox* harassUseE;
	CheckBox* spPriority;
	CheckBox* autoW;
	Slider* harassMana;
	Slider* eDistance;


	float maxRangeE = 1225;
	float lengthE = 700;
	float speedE = 1050;
	float rangeE = 500;
	float lasttick = 0;

	PredictionInput Q = PredictionInput({ 700.f, 0.25f,100.f,2000.f, false, SkillshotType::SkillshotLine });
	PredictionInput W = PredictionInput({ 800.f, 0.5f,300.f,FLT_MAX, false, SkillshotType::SkillshotCircle });
	PredictionInput E = PredictionInput({ rangeE, 0,80.f,speedE, false, SkillshotType::SkillshotLine });
	PredictionInput R = PredictionInput({ 700.f, 0.25f,300.f,FLT_MAX,false,SkillshotType::SkillshotCircle });

	Viktor()
	{

	}

	~Viktor()
	{

	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Viktor", "Viktor");
		auto ComboSet = menu->AddMenu("ComboSet", "Combo Settings");
		UseQ = ComboSet->AddCheckBox("UseQ", "Use Q", true);
		UseW = ComboSet->AddCheckBox("UseW", "Use W", true);
		UseE = ComboSet->AddCheckBox("UseE", "Use E", true);
		UseR = ComboSet->AddCheckBox("UseR", "Use R", true);

		auto Rconfig = menu->AddMenu("Rconfig", "R config");
		HitR = Rconfig->AddSlider("HitR", "Auto R on enemies ", 3, 1, 5, 1);
		AutoFollowR = Rconfig->AddCheckBox("AutoFollowR", "Auto Follow R", true);
		rTick = Rconfig->AddSlider("rTicks", "Ultimate ticks to count ", 2, 1, 14, 1);

		auto ROneTarget = menu->AddMenu("ROneTarget", "R One Target");
		forceR = ROneTarget->AddKeyBind("forceR", "Force R on target", 84, false, false); // 0x61 vk keycode
		RkS = ROneTarget->AddCheckBox("RkS", "R KS", true);

		auto HarassSet = menu->AddMenu("HarassSet", "Harass Settings");
		harassUseQ = HarassSet->AddCheckBox("harassUseQ", "Use Q", true);
		harassUseE = HarassSet->AddCheckBox("harassUseE", "Use W", true);
		harassMana = HarassSet->AddSlider("harassMana", "Mana usage in percent (%) ", 30, 1, 100, 1);
		eDistance = HarassSet->AddSlider("eDistance", "Harass range with E ", maxRangeE, rangeE, maxRangeE, 1);

		auto MiscSet = menu->AddMenu("MiscSet", "Misc Settings");
		autoW = MiscSet->AddCheckBox("autoW", "Use W to continue CC", true);
		spPriority = MiscSet->AddCheckBox("spPriority", "Prioritize kill over dmg", true);

	}

	void Draw()
	{

	}

	float TotalDmg(CObject* enemy, bool useQ, bool useE, bool useR, bool qRange)
	{
		float damage = 0;
		int rTicks = rTick->Value;
		bool inQRange = ((qRange && me->IsInAutoAttackRange(enemy)) || qRange == false);
		//Base Q damage
		if (useQ && IsReady(_Q) && inQRange)
		{
			auto Qprocdmg = me->IsReady(_Q) || me->HasBuff("ViktorPowerTransferReturn") ? me->CalculateDamage(enemy, get_spell_damage_table(20, 25, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.6 * me->TotalAbilityPower() + me->TotalAttackDamage(), 2) : 0;
			auto Qdmg = GetSpellDamage(me, enemy, SpellSlot::Q) + Qprocdmg;
			damage += Qdmg;
		}

		// Q damage on AA
		if (useQ && !IsReady(_Q) && me->HasBuff(FNV("viktorpowertransferreturn")) && inQRange)
		{
			damage += me->CalculateDamage(enemy, get_spell_damage_table(20, 25, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.6 * me->TotalAbilityPower() + me->TotalAttackDamage(), 2);
		}

		//E damage
		if (useE && IsReady(_E))
		{
			auto E2dmg = me->IsReady(_E) && (me->HasBuff("viktoreaug") || me->HasBuff("viktorqeaug") || me->HasBuff("viktorqweaug")) ? me->CalculateDamage(enemy, get_spell_damage_table(20, 30, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.8 * me->TotalAbilityPower(), 2) : 0;
			auto Edmg = GetSpellDamage(me, enemy, SpellSlot::E) + E2dmg;
			damage += Edmg;
		}

		//R damage + 2 ticks
		if (useR && me->GetSpellBook()->GetSpellSlotByID(_R)->Level() > 0 && IsReady(_R) && me->GetSpellBook()->GetSpellSlotByID(_R)->GetSpellData()->GetMissileNameHash() == FNV("ViktorChaosStorm"))
		{
			auto Rtickdmg = me->IsReady(_R) ? me->CalculateDamage(enemy, (get_spell_damage_table(65, 40, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.45 * me->TotalAbilityPower()) * rTicks, 2) : 0;
			auto Rdmg = GetSpellDamage(me, enemy, SpellSlot::R) + Rtickdmg;
			damage += Rdmg;
		}

		return (float)damage;
	}

	float GetComboDamage(CObject* enemy)
	{

		return TotalDmg(enemy, true, true, true, false);
	}

	void PredictCastE(CObject* target)
	{
		// Helpers
		bool inRange = target->PosServer2D().DistanceSquared(me->Pos2D()) < E.Range * E.Range;
		PredictionOutput predictionO;
		bool spellCasted = false;

		// Positions
		Vector3 pos1, pos2;

		// Champs
		auto nearChamps = Engine::GetHerosAround(maxRangeE, 1);
		std::vector<CObject*> innerChamps = {};
		std::vector<CObject*> outerChamps = {};
		for (auto champ : nearChamps)
		{
			if (champ->PosServer2D().DistanceSquared(me->Pos2D()) < E.Range * E.Range)
				innerChamps.push_back(champ);
			else
				outerChamps.push_back(champ);
		}

		// Minions
		auto nearMinions = Engine::GetMinionsAround(maxRangeE, 1);
		std::vector<CObject*> innerMinions = {};
		std::vector<CObject*> outerMinions = {};

		for (auto minion : nearMinions)
		{
			if (minion->PosServer2D().DistanceSquared(me->Pos2D()) < E.Range * E.Range)
				innerMinions.push_back(minion);
			else
				outerMinions.push_back(minion);
		}

		// Main target in close range
		if (inRange)
		{
			// Get prediction reduced speed, adjusted sourcePosition
			E.Speed = speedE * 0.9f;
			E.From(target->ServerPosition() + ((me->Position() - target->ServerPosition()).Normalized() * (lengthE * 0.1f)));
			predictionO = prediction->GetPrediction(target, E);
			E.From(me->Position());

			// Prediction in range, go on
			if (predictionO.CastPosition().Distance(me->Position()) < E.Range)
				pos1 = predictionO.CastPosition();
			// Prediction not in range, use exact position
			else
			{
				pos1 = target->ServerPosition();
				E.Speed = speedE;
			}

			// Set new sourcePosition
			E.From(pos1);
			E.RangeCheckFrom(pos1);

			// Set new range
			E.Range = lengthE;

			// Get next target
			if (nearChamps.size() > 0)
			{
				// Get best champion around
				std::vector<CObject*> closeToPrediction = {};
				for (auto enemy : nearChamps)
				{
					// Get prediction
					predictionO = prediction->GetPrediction(enemy, E);
					// Validate target
					if (predictionO.HitChance() >= HitChance::High && XPolygon::To2D(pos1).DistanceSquared(XPolygon::To2D(predictionO.CastPosition())) < (E.Range * E.Range) * 0.8)
						closeToPrediction.push_back(enemy);
				}

				// Champ found
				if (closeToPrediction.size() > 0)
				{
					// Sort table by health DEC
					if (closeToPrediction.size() > 1)
					{
						sort(closeToPrediction.begin(), closeToPrediction.end(), [&](CObject* enemy1, CObject* enemy2) {
							return enemy1->Health() < enemy2->Health();
						});
					}

					// Set destination
					predictionO = prediction->GetPrediction(closeToPrediction[0], E);
					pos2 = predictionO.CastPosition();

					// Cast spell
					CastSpell(_E, pos1, pos2);
					spellCasted = true;
				}
			}

			// Spell not casted
			if (!spellCasted)
			{
				CastSpell(_E,pos1, prediction->GetPrediction(target, E).CastPosition());
			}

			// Reset spell
			E.Speed = speedE;
			E.Range = rangeE;
			E.From(me->Position());
			E.RangeCheckFrom(me->Position());
		}

		// Main target in extended range
		else
		{
			// Radius of the start point to search enemies in
			float startPointRadius = 150;

			// Get initial start point at the border of cast radius
			Vector3 startPoint = me->Position() + (target->ServerPosition() - me->Position()).Normalized() * rangeE;

			// Potential start from postitions
			std::vector<CObject*> targets = {};
			for (auto champ : nearChamps)
			{
				if (XPolygon::To2D(champ->ServerPosition()).DistanceSquared(XPolygon::To2D(startPoint)) < startPointRadius * startPointRadius && me->Pos2D().DistanceSquared(champ->PosServer2D()) < rangeE * rangeE)
					targets.push_back(champ);
			}


			if (targets.size() > 0)
			{
				// Sort table by health DEC
				if (targets.size() > 1)
				{
					sort(targets.begin(), targets.end(), [&](CObject* enemy1, CObject* enemy2) {
						return enemy1->Health() < enemy2->Health();
					});
				}

				// Set target
				pos1 = targets[0]->ServerPosition();
			}
			else
			{
				std::vector<CObject*> minionTargets = {};
				for (auto minion : nearMinions)
				{
					if (XPolygon::To2D(minion->ServerPosition()).DistanceSquared(XPolygon::To2D(startPoint)) < startPointRadius * startPointRadius && me->Pos2D().DistanceSquared(minion->PosServer2D()) < rangeE * rangeE)
						nearMinions.push_back(minion);
				}

				if (minionTargets.size() > 0)
				{
					// Sort table by health DEC
					if (minionTargets.size() > 1)
					{
						sort(minionTargets.begin(), minionTargets.end(), [&](CObject* enemy1, CObject* enemy2) {
							return enemy1->Health() < enemy2->Health();
						});
					}

					// Set target
					pos1 = minionTargets[0]->ServerPosition();
				}
				else
					// Just the regular, calculated start pos
					pos1 = startPoint;
			}

			// Predict target position
			E.From(pos1);
			E.Range = lengthE;
			E.RangeCheckFrom(pos1);
			predictionO = prediction->GetPrediction(target, E);

			// Cast the E
			if (predictionO.HitChance() >= HitChance::High)
				CastSpell(_E,pos1, predictionO.CastPosition());

			// Reset spell
			E.Range = rangeE;
			E.From(me->Position());
			E.RangeCheckFrom(me->Position());
		}

	}

	void AutoR()
	{
		auto enemiesR = Engine::GetHerosAround(R.Range, 1);

		for (auto enemy : enemiesR)
		{
			if (enemy->StatusFlags() == 512 && enemy->IsValidTarget())
				if (CastSpell(_R, enemy))
					return;

		}
	}

	void onCombo()
	{

		auto Etarget = targetselector->GetTarget(maxRangeE);
		auto Qtarget = targetselector->GetTarget(Q.Range);
		auto RTarget = targetselector->GetTarget(R.Range);

		//if (!IsReady(0) && !IsReady(1) && !IsReady(2) && !me->HasBuff("ViktorPowerTransferReturn") && Engine::GetEnemyCount(300, me->Position()) > 0)
		//{
		//	orbwalker->UseOrbWalker = false;
		//}
		//else
		//{
		//	orbwalker->UseOrbWalker = true;

		//}
		bool killpriority = spPriority->Value && IsReady(_R);
		bool rKillSteal = RkS->Value;

		if (killpriority && Qtarget != nullptr & Etarget != nullptr && Etarget != Qtarget && ((Etarget->Health() > TotalDmg(Etarget, false, true, false, false)) || (Etarget->Health() > TotalDmg(Etarget, false, true, true, false) && Etarget == RTarget)) && Qtarget->Health() < TotalDmg(Qtarget, true, true, false, false))
		{
			Etarget = Qtarget;
		}

		if (UseQ->Value && LagFree(2))//UseQ
		{
			if (Qtarget != nullptr)
			{
				if (CastSpell(_Q, Qtarget, true))
				{
					//_DelayAction->Add((int)(Q.Delay * 1200), []() {
					//	if (me->HasBuff(FNV("viktorpowertransferreturn")))
					//	{
					//		//orbwalker->IssueMove();
					//		orbwalker->ResetAutoAttacks();

					//	}
					//});
				}

				if (Qtarget->IsInAutoAttackRange(Qtarget) && me->HasBuff(FNV("viktorpowertransferreturn")) && orbwalker->CanAttack())
				{
					//orbwalker->IssueAttack(Qtarget);
				}
			}
		}

		if (RTarget != nullptr && rKillSteal && UseR)
		{
			if (TotalDmg(RTarget, true, true, false, false) < RTarget->Health() && TotalDmg(RTarget, true, true, true, true) > RTarget->Health())
			{
				CastSpell(_R, Engine::WorldToScreen(RTarget->Position()));
			}
		}
		if (UseE->Value && LagFree(1) && IsReady(_E))//UseE
		{
			if (Etarget != nullptr)
			{
				if (!me->IsAutoAttacking())
				{
					orbwalker->Attack = false;
					PredictCastE(Etarget);
				}
			}
		}



		if (UseW->Value && LagFree(3))//useW
		{
			auto t = targetselector->GetTarget(W.Range);

			if (t != nullptr)
			{
				if (t->GetPath().size() < 2)
				{
					if (t->HasBuffOfType(BuffType::Slow))
					{
						if (prediction->GetPrediction(t, W).HitChance() >= HitChance::VeryHigh)
							if (CastSpell(_W, t))
								return;
					}
					if (Engine::GetEnemyCount(250, t->Position()) >= 2)
					{
						if (prediction->GetPrediction(t, W).HitChance() >= HitChance::VeryHigh)
							if (CastSpell(_W, t))
								return;
					}
				}
			}
		}
	}

	void AutoW()
	{
		if (!IsReady(_W) || !autoW->Value)
			return;

		auto enemiesW = Engine::GetHerosAround(W.Range, 1);

		for (auto tPanth : enemiesW)
		{
			if (tPanth->HasBuff(FNV("Pantheon_GrandSkyfall_Jump")))
				if (CastSpell(_W, tPanth))
					return;

		}

		for (auto enemy : enemiesW)
		{

			auto Qprocdmg = me->IsReady(_Q) || me->HasBuff("ViktorPowerTransferReturn") ? me->CalculateDamage(enemy, get_spell_damage_table(20, 25, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.6 * me->TotalAbilityPower() + me->TotalAttackDamage(), 2) : 0;
			auto Qdmg = GetSpellDamage(me, enemy, SpellSlot::Q) + Qprocdmg;
			auto E2dmg = me->IsReady(_E) && (me->HasBuff("viktoreaug") || me->HasBuff("viktorqeaug") || me->HasBuff("viktorqweaug")) ? me->CalculateDamage(enemy, get_spell_damage_table(20, 30, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.8 * me->TotalAbilityPower(), 2) : 0;
			auto Edmg = GetSpellDamage(me, enemy, SpellSlot::E) + E2dmg;
			auto Rtickdmg = me->IsReady(_R) ? me->CalculateDamage(enemy, (get_spell_damage_table(65, 40, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.45 * me->TotalAbilityPower()) * rTick->Value, 2) : 0;
			auto Rdmg = GetSpellDamage(me, enemy, SpellSlot::R) + Rtickdmg;
			auto AAdmg = GetSpellDamage(me, enemy, SpellSlot::AA);
			//viktorqweaug
			//printf("AA: %.2f | %.2f | %.2f | %.2f \n", AAprocdmg, get_spell_damage_table(20, 25, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1), me->GetTotalAP(), me->GetTotalAD());
			//printf("AA: %.2f | %.2f | %.2f | %.2f \n", AAprocdmg, get_spell_damage_table(20, 25, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1), me->GetTotalAP(), me->GetTotalAD());

			if (Qdmg + Edmg + Rdmg + AAdmg + Qprocdmg + activator->ignitedmg() >= enemy->Health() && (!IsReady(_Q) || me->HealthPercent() < 50))
			{
				//printf("DMG: %.2f | HP: %.2f\n", Qdmg + Edmg + Rdmg + AAdmg + Qprocdmg + activator->ignitedmg(), enemy->Health());
				//if (prediction->GetPrediction(enemy, W).HitChance() == HitChance::VeryHigh)

				Vector3 Pred;
				Pred = enemy->Position().Extended(enemy->ServerPosition(), enemy->Position().Distance(enemy->ServerPosition()) + 50);

				Vector3 W2S_buffer = Engine::WorldToScreen(Pred);
				CastSpell(_W, W2S_buffer);

				CastItem(kItemID::Everfrost, W2S_buffer);
			}



			if (Engine::GetEnemyCount(300, enemy->ServerPosition()) >= 2)
				if (CastSpell(_W, enemy))
					return;

			if (enemy->IsMelee() && enemy->Position().Distance(me->Position()) <= enemy->AttackRange() + 150)
				if (CastSpell(_W, me))
					return;

			if (enemy->IsMelee() && enemy->Position().Distance(me->Position()) <= enemy->AttackRange() + 400)
			{

				CastItem(kItemID::Everfrost, enemy);
			}

			if (enemy->GetBuffManager()->IsImmobile())
			{
				CastItem(kItemID::Everfrost, enemy);

			}
			if (enemy->HasBuff("rocketgrab2"))
			{
				auto Allies = Engine::GetHerosAround(W.Range, 2);
				for (auto ally : Allies)
				{
					if (ally->ChampionNameHash() == FNV("blitzcrank"))
					{
						if (CastSpell(_W, ally))
							return;
					}
				}
			}

			if (enemy->GetBuffManager()->IsImmobile())
			{
				if (CastSpell(_W, enemy))
					return;
			}
			if (prediction->GetPrediction(enemy, W).HitChance() == HitChance::Immobile)
			{
				if (CastSpell(_W, enemy))
					return;
			}
		}
	}

	void onHarass()
	{
		// Mana check
		if ((me->Mana() / me->MaxMana()) * 100 < harassMana->Value)
			return;
		bool useE = harassUseE->Value && IsReady(_E);
		bool useQ = harassUseQ->Value && IsReady(_Q);
		if (useQ)
		{
			auto qtarget = targetselector->GetTarget(Q.Range);
			if (qtarget != nullptr)
				CastSpell(_Q, qtarget, true);
		}
		if (useE)
		{
			auto harassrange = eDistance->Value;
			auto target = targetselector->GetTarget(harassrange);

			if (target != nullptr)
				PredictCastE(target);
		}
	}
	void onLaneClear()
	{
		auto minions = Engine::GetMinionsAround(Q.Range, 1, me->ServerPosition());
		int orbTarget = 0;

		if (orbwalker->GetTarget() != nullptr)
			orbTarget = orbwalker->GetTarget()->NetworkID();

		for (auto minion : minions)
		{
			if (1)
			{

				auto Qprocdmg = me->HasBuff("ViktorPowerTransferReturn") ? me->CalculateDamage(minion, get_spell_damage_table(20, 25, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.6 * me->TotalAbilityPower() + me->TotalAttackDamage(), 2) : 0;
				auto Qdmg = GetSpellDamage(me, minion, SpellSlot::Q);
				if (minion->IsValidTarget() && orbTarget != minion->NetworkID())
				{
					int delay = (int)((minion->Distance(me) / Q.Speed + Q.Delay) * 1000);
					auto hpPred = orbwalker->GetHealthPrediction(minion, delay);
					if (hpPred > 0 && hpPred <= Qdmg && (minion->IsSiegeMinion() || minion->IsSuperMinion()))
					{
						if (CastSpell(_Q, minion))
							return;
					}

					if (minion->Health() <= Qprocdmg && orbwalker->CanAttack())
					{
						orbwalker->IssueAttack(minion);
					}
					else
					{
						if (hpPred > 0 && hpPred <= Qdmg && !orbwalker->CanAttack() && IsReady(0) && orbwalker->AfterAutoAttack())
							if (CastSpell(_Q, minion))
								return;

					}
				}
				//if (Qdmg >= minion->Health() && minion->IsSiegeMinion())
				//{
				//	CastSpell(_Q, minion);
				//}
				//if (minion->Health() <= Qprocdmg && orbwalker->CanAttack())
				//{
				//	orbwalker->IssueAttack(minion);
				//}
			}
		}

		std::vector<CObject*> jungles = Engine::GetJunglesAround(Q.Range, 2);
		for (auto jungle : jungles)
		{
			if (IsReady(_Q))
			{
				auto Qprocdmg = me->IsReady(_Q) || me->HasBuff("ViktorPowerTransferReturn") ? me->CalculateDamage(jungle, get_spell_damage_table(20, 25, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.6 * me->TotalAbilityPower() + me->TotalAttackDamage(), 2) : 0;
				auto Qdmg = GetSpellDamage(me, jungle, SpellSlot::Q) + Qprocdmg;

				if (Qdmg >= jungle->Health() && (jungle->IsLargeMonster() || jungle->IsEpicMonster()))
				{
					CastSpell(_Q, jungle);
				}
				if (jungle->Health() <= Qprocdmg && orbwalker->CanAttack())
				{
					orbwalker->IssueAttack(jungle);
				}
			}
		}

	}

	void onLastHit()
	{
		auto minions = Engine::GetMinionsAround(Q.Range, 1, me->ServerPosition());
		int orbTarget = 0;

		if (orbwalker->GetTarget() != nullptr)
			orbTarget = orbwalker->GetTarget()->NetworkID();

		for (auto minion : minions)
		{
			if (1)
			{
				auto Qprocdmg = me->HasBuff("ViktorPowerTransferReturn") ? me->CalculateDamage(minion, get_spell_damage_table(20, 25, me->GetSpellBook()->GetSpellSlotByID(0)->Level() - 1) + 0.6 * me->TotalAbilityPower() + me->TotalAttackDamage(), 2) : 0;
				auto Qdmg = GetSpellDamage(me, minion, SpellSlot::Q);
				if (minion->IsValidTarget() && orbTarget != minion->NetworkID())
				{
					int delay = (int)((minion->Distance(me) / Q.Speed + Q.Delay) * 1000);
					auto hpPred = orbwalker->GetHealthPrediction(minion, delay);
					if (hpPred > 0 && hpPred <= Qdmg && (minion->IsSiegeMinion() || minion->IsSuperMinion()))
					{
						if (CastSpell(_Q, minion))
							return;
					}

					if (minion->Health() <= Qprocdmg && orbwalker->CanAttack())
					{
						orbwalker->IssueAttack(minion);
					}
					else
					{
						if (hpPred > 0 && hpPred <= Qdmg && !orbwalker->CanAttack() && IsReady(0) && orbwalker->AfterAutoAttack())
							if (CastSpell(_Q, minion))
								return;

					}
				}
				//if (Qdmg >= minion->Health() && minion->IsSiegeMinion())
				//{
				//	CastSpell(_Q, minion);
				//}
				//if (minion->Health() <= Qprocdmg && orbwalker->CanAttack())
				//{
				//	orbwalker->IssueAttack(minion);
				//}
			}
		}
		/*std::vector<CObject*> minions = Engine::GetMinionsAround(Q.Range, 1);
		for (auto minion : minions)
		{
			if (IsReady(_Q))
			{
				auto QDmg = GetSpellDamage(me, minion, SpellSlot::Q);

				if (QDmg >= minion->Health() && minion->IsSiegeMinion())
				{
					CastSpell(_Q, minion);
				}
			}
		}*/
	}

	void Tick()
	{
		//AutoW();
		AutoR();

		if (global::mode== ScriptMode::Combo)
		{
			onCombo();
		}
		else if (global::mode== ScriptMode::Mixed)
		{
			onHarass();
		}
		else if (global::mode== ScriptMode::LaneClear)
		{
			onLaneClear();
		}
		else if (global::mode== ScriptMode::LastHit)
		{
			onLastHit();
		}

		if (forceR->Value)
		{
			if (IsReady(_R))
			{
				auto RTarget = targetselector->GetTarget(R.Range);
				if (RTarget->IsValidTarget())
				{
					CastSpell(_R, Engine::WorldToScreen(RTarget->ServerPosition()));
				}
			}
		}
		// Ultimate follow
		if (me->GetSpellBook()->GetSpellSlotByID(_R)->GetSpellData()->GetMissileNameHash() != FNV("ViktorChaosStorm") && AutoFollowR->Value && Engine::TickCount() - lasttick > 0)
		{
			auto stormT = targetselector->GetTarget(1500);
			if (stormT != nullptr)
			{
				CastSpell(_R, Engine::WorldToScreen(stormT->Position()));
				lasttick = Engine::TickCount() + 500;
			}
		}
	}
};