#pragma once


class Zeri : public ModuleManager {
	PredictionInput Q = PredictionInput({ 825, 0.025f,40,2600, true, SkillshotType::SkillshotLine,false });
	//PredictionInput W = PredictionInput({ 1200 - 40, 0.5f,40.f,2200.f, true, SkillshotType::SkillshotLine });
	PredictionInput W = PredictionInput({ 1500.f, 0.6f,60.f,2200.f, true, SkillshotType::SkillshotLine });
	PredictionInput E = PredictionInput({ 300 });
	PredictionInput R = PredictionInput({ 785, 0.25f });

public:
	Zeri()
	{

	}

	~Zeri()
	{

	}

	void Draw()
	{

	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Zeri", "Zeri");
		E.Slot = SpellSlot::E;
		dashcast = new DashCast();
		dashcast->Init2(menu, E);
		dashcast->Add();
	}

	bool HasIgnoreCollisionBuff()
	{
		return me->HasBuff(FNV("ZeriR")) || me->HasBuff(FNV("zeriespecialrounds")) || me->HasItem(kItemID::RunaansHurricane);
	}

	float GetPassiveTime()
	{
		auto buff = me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("ezrealrisingspellforce"));

		if (buff.count > 0)
			return buff.remaintime;

		return 0.f;
	}

	void farmQ()
	{

		auto mobs = Engine::GetJunglesAround(800.f, 1);
		if (mobs.size() > 0)
		{
			auto mob = mobs[0];
			if (IsReady(_Q))
			{
				CastSpell(_Q, mob);
			}
		}


		if (!orbwalker->CanMove(orbwalker->ExtraWindUpTime->Value) || (orbwalker->ShouldWait() && orbwalker->CanAttack()))
		{
			return;
		}

		auto minions = Engine::GetMinionsAround(Q.Range, 1, me->ServerPosition());
		int orbTarget = 0;

		if (orbwalker->GetTarget() != nullptr)
			orbTarget = orbwalker->GetTarget()->NetworkID();

		if (1)//FQ->Value
		{
			for (auto minion : minions)
			{
				if (minion->IsValidTarget() && orbTarget != minion->NetworkID() && !me->IsInAutoAttackRange(minion))
				{
					int delay = (int)((minion->Distance(me) / Q.Speed + Q.Delay) * 1000);
					auto hpPred = orbwalker->GetHealthPrediction(minion, delay);
					if (hpPred > 0 && hpPred < GetSpellDamage(me, minion, SpellSlot::Q, false))
					{
						if (CastSpell(_Q, minion))
							return;
					}
				}
			}
		}

		if (1 && !orbwalker->CanAttack())//farmQ->Value
		{
			auto LCP = true;// LCP->Value
			auto PT = Engine::GameGetTickCount() - GetPassiveTime() > -1.5 || !IsReady(_E);

			for (auto minion : minions)
			{
				if (me->IsInAutoAttackRange(minion))
				{
					int delay = (int)((minion->Distance(me) / Q.Speed + Q.Delay) * 1000);
					auto hpPred = orbwalker->GetHealthPrediction(minion, delay);
					if (hpPred < 20)
						continue;

					auto qDmg = GetSpellDamage(me, minion, SpellSlot::Q, false);
					if (hpPred < qDmg && orbTarget != minion->NetworkID())
					{
						if (CastSpell(_Q, minion))
							return;
					}
					else if (PT || LCP)
					{
						if (minion->HealthPercent() > 80)
						{
							if (CastSpell(_Q, minion))
								return;
						}
					}
				}
			}
		}
	}
	void LaneClear()
	{
		farmQ();
	}

	void CastQ()
	{
		auto orbTarget = orbwalker->GetTarget();
		if (orbTarget != nullptr && orbTarget->IsValidTarget(Q.Range))
		{
			Q.Range = 825.f + (me->HasLethalTempoStacked() ? 75.f : 0.f);


			auto qPred = prediction->GetPrediction(orbTarget, Q);

			if (qPred.HitChance() >= HitChance::Medium || HasIgnoreCollisionBuff() && qPred.HitChance() == HitChance::Collision)
			{
				if (CastSpell(_Q, Engine::WorldToScreen(qPred.CastPosition()), true) && orbwalker->CanAttack())
				{
					orbwalker->IssueAttack(orbTarget);
				}
			}
			else
			{
				auto target = targetselector->GetTarget(Q.Range);
				if (target == nullptr || !target->IsValidTarget(Q.Range))
				{
					return;
				}

				auto qPred = prediction->GetPrediction(target, Q);
				if (qPred.HitChance() >= HitChance::Medium || HasIgnoreCollisionBuff() && qPred.HitChance() == HitChance::Collision)
				{
					if (CastSpell(_Q, Engine::WorldToScreen(qPred.CastPosition()), true) && orbwalker->CanAttack())
					{
						orbwalker->IssueAttack(target);
					}
				}
			}
		}
		else
		{
			auto target = targetselector->GetTarget(Q.Range);
			if (target == nullptr || !target->IsValidTarget(Q.Range))
			{
				return;
			}

			auto qPred = prediction->GetPrediction(target, Q);
			if (qPred.HitChance() >= HitChance::Medium || HasIgnoreCollisionBuff() && qPred.HitChance() == HitChance::Collision)
			{
				if (CastSpell(_Q, Engine::WorldToScreen(qPred.CastPosition()), true) && orbwalker->CanAttack())
				{
					orbwalker->IssueAttack(target);
				}
			}
		}
	}

	void CastW()
	{
		CastSpell(targetselector->GetTarget(W.Range), _W, W);
	}

	void Combo()
	{
		if (IsReady(_Q) && LagFree(1))
		{
			CastQ();
		}

		if (IsReady(_W) && LagFree(2))
		{
			CastW();
		}

		if (IsReady(_R) && LagFree(3))
		{
			auto target = targetselector->GetTarget(R.Range);
			if (target != nullptr && target->IsValidTarget(Q.Range) &&
				me->HealthPercent() < target->HealthPercent() && target->HealthPercent() - me->HealthPercent() > 20)
			{
				CastSpell(_R);
			}
		}

		if (IsReady(_E) && me->Mana() > me->GetSpellBook()->GetSpellSlotByID(_E)->ManaCost() * 2 && LagFree(4))
		{
			auto target = targetselector->GetTarget(800);
			if (target != nullptr && target->IsValidTarget(Q.Range)) 
			{
				if (target->Distance(me) <= me->GetRealAutoAttackRange(target) ||
					target->Distance(me) > me->GetRealAutoAttackRange(target) + E.Range)
				{
					return;
				}

				auto dashPos = dashcast->CastDash();
				if (dashPos.IsValid())
				{
					auto realRange = me->BoundingRadius() + target->BoundingRadius() + me->AttackRange();
					if (me->ServerPosition().Distance(Engine::GetMouseWorldPosition()) > realRange * 0.60 &&
						!me->IsInAutoAttackRange(target) &&
						target->ServerPosition().Distance(dashPos) < realRange - 45)
					{
						CastSpell(2, Engine::WorldToScreen(dashPos));
					}
				}
			}
		}
	}

	void Tick()
	{

		if (global::mode== ScriptMode::Combo)
		{
			Combo();
		}
		else if (global::mode== ScriptMode::LaneClear)
		{
			LaneClear();
		}
	}
};