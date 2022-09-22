#pragma once
class Samira : public ModuleManager {
private:

public:

	PredictionInput Q = PredictionInput({ 950, 0.25f, 60.f,2600.f, true, SkillshotType::SkillshotLine });
	PredictionInput E = PredictionInput({ 475 });
	Samira()
	{

	}

	~Samira()
	{

	}

	void Draw()
	{

	}

	float Dmg;

	CheckBox* QCombo;
	CheckBox* WCombo;
	CheckBox* Eks;
	CheckBox* ECombo;
	CheckBox* FastCombo;
	CheckBox* QFarm;
	CheckBox* Econdition;

	CheckBox* RCombo;

	void Init()
	{
		SetFunctionCallBack(BeforeAttackEvent, [&](CObject* actor) {
			////put this code in Init()

			return true;
			});

		auto menu = NewMenu::CreateMenu("Samira", "Samira");
		auto ComboMode = menu->AddMenu("ComboMode", "ComboMode");
		auto QConfig = menu->AddMenu("QConfig", "QConfig");
		auto WConfig = menu->AddMenu("WConfig", "WConfig");
		auto EConfig = menu->AddMenu("EConfig", "EConfig");
		auto RConfig = menu->AddMenu("RConfig", "RConfig");
		auto laneclear = menu->AddMenu("laneclear", "laneclear");

		FastCombo = ComboMode->AddCheckBox("FastCombo", "Try Fast Combo", true);

		QCombo = QConfig->AddCheckBox("QCombo", "Use Q in Combo", true);
		QFarm = laneclear->AddCheckBox("QFarm", "Use Q in laneclear", true);


		WCombo = WConfig->AddCheckBox("WCombo", "Use W in Combo", true);

		Eks = EConfig->AddCheckBox("Eks", "E when killable", true);
		ECombo = EConfig->AddCheckBox("Ecombo", "Smart E", true);
		Econdition = EConfig->AddCheckBox("Econdition", "Auto use E when passive is ready", true);
		//Eclear = EConfig->AddCheckBox("Eclear", "Use E farm", true);
		//Eminions = EConffig->AddSlider("Eminions", "R at X stack", 3, 1, 7);

		RCombo = RConfig->AddCheckBox("RCombo", "Use R in Combo", true);



	}

	void farmQ()
	{

		auto mobs = Engine::GetJunglesAround(950.f, 1);
		if (mobs.size() > 0)
		{
			auto mob = mobs[0];
			if (IsReady(_Q))
			{
				CastSpell(_Q, mob);
			}
		}


		if (!(orbwalker->ShouldWait() && orbwalker->CanAttack()))
		{
			return;
		}

		auto minions = Engine::GetMinionsAround(Q.Range, 1);
		int orbTarget = 0;
		auto lastTarget = orbwalker->LastTarget;
		if (orbwalker->GetTarget() != nullptr)
			orbTarget = orbwalker->GetTarget()->NetworkID();

		if (1)//FQ->Value
		{
			for (auto minion : minions)
			{
				if (minion->IsValidTarget() && orbTarget != minion->NetworkID() && !me->IsInAutoAttackRange(minion))
				{
					if (lastTarget->NetworkID() == minion->NetworkID())
					{
						if (!lastTarget->IsValidTarget())
							continue;
					}

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

		if (1 && !orbwalker->CanAttack())
		{
			for (auto minion : minions)
			{
				if (me->IsInAutoAttackRange(minion))
				{
					if (lastTarget->NetworkID() == minion->NetworkID())
					{
						if (!lastTarget->IsValidTarget())
							continue;
					}

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
				}
			}
		}
	}

	void QCombo_()
	{
		for (auto object : global::enemyheros)
		{
			CObject* actor = (CObject*)object.actor;

			if (actor->IsValidTarget())
			{

				if (me->Distance(actor) <= 950.f)
				{
					CastSpell(actor, _Q, Q);
				}
				else if (me->Distance(actor) <= 325.f)
				{
					Q.Collision = false;
					CastSpell(actor, _Q, Q);
				}
			}
		}
	}


	void EKs()
	{
		for (auto object : global::enemyheros)
		{
			CObject* actor = (CObject*)object.actor;

			if (actor->IsValidTarget())
			{
				global::edmg = IsReady(2) ? GetSpellDamage(me, actor, SpellSlot::E) : 0;

				if (actor->Health() < global::edmg && me->Distance(actor) <= 550.f)
				{
					CastSpell(_E, actor, true);
				}
			}
		}
	}



	void ELogic()
	{
		for (auto object : global::enemyheros)
		{
			CObject* actor = (CObject*)object.actor;

			if (actor->IsValidTarget())
			{
				if (IsReady(_Q) && QCombo->Value && IsReady(_E) && ECombo->Value && IsReady(_W) && WCombo->Value)
				{
					Dmg = GetSpellDamage(me, actor, SpellSlot::E) + GetSpellDamage(me, actor, SpellSlot::Q) + GetSpellDamage(me, actor, SpellSlot::W);
					if (actor->Health() < Dmg && me->Distance(actor) <= 550.f)
					{
						CastSpell(actor, _E, E);
						CastSpell(1);
					}
				}
				if (Econdition->Value)
				{
					if (IsReady(_E) && me->HasBuff(FNV("SamiraPassiveCombo")) && IsReady(_R))
					{
						if (me->Distance(actor) <= 550.f)
						{
							CastSpell(actor, _E, E);
						}
					}

				}
			}
		}
	}

	void FastCombo_()
	{
		if (orbwalker->AfterAutoAttack())
		{
			auto target = orbwalker->LastTarget;
			if (target->IsValidTarget() && target->IsHero() && me->Distance(target) <= 550.f)
			{
				if (/*IsReady(_Q) &&*/ QCombo->Value && IsReady(_E) && ECombo->Value && IsReady(_W) && WCombo->Value)
				{
					CastSpell(_W, true);
					CastSpell(_E, target, true);

				}
			}
		}
	}

	void RCombo_()
	{
		if (me->HasBuff(FNV("SamiraPassiveCombo")) && IsReady(_R))
		{
			auto target = targetselector->GetTarget(600.f);

			if (me->Distance(target) <= 600.f)
			{
				CastSpell(_R, true);
			}
		}
	}


	void Tick()
	{
		if (global::mode == ScriptMode::LaneClear)
		{
			if (QFarm->Value)
			{
				farmQ();
			}
		}

		if (global::mode == ScriptMode::Combo)
		{
			if (IsReady(_E) && Eks->Value)
			{
				EKs();
			}
			if (FastCombo->Value)
			{
				FastCombo_();
			}
			if (RCombo->Value)
			{
				RCombo_();
			}
			if (ECombo->Value)
			{
				ELogic();
			}
			if (IsReady(_Q) && QCombo->Value)
			{
				QCombo_();
			}

		}
	}
};
