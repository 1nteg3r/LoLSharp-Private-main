#pragma once
bool justR = false;
class Kaisa : public ModuleManager {
private:
	bool isQEvolved, isWEvolved, isEEvolved;
public:

	PredictionInput Q = PredictionInput({ 600.f, 0.25f });
	PredictionInput W = PredictionInput({ 3000.f, 0.40000000596046f ,100.f,1750.f, true, SkillshotType::SkillshotLine });
	PredictionInput R = PredictionInput({ 3000.f, 0.5f, 140.f, 1500.f, false, SkillshotType::SkillshotCircle });

	CheckBox* autoQ;
	List* c_q;
	List* combo_q;
	CheckBox* farmQ;

	List* combo_w;
	CheckBox* useW;
	Slider* combo_w_slider;
	Slider* w_stacks;
	CheckBox* ks_w;
	Slider* ks_w_slider;

	CheckBox* use_e;

	Kaisa()
	{

	}

	~Kaisa()
	{

	}

	void Draw()
	{

	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("AIOKaisa", "Kai'Sa");
		auto q = menu->AddMenu("q", "[Q] Icathian Rain");

		autoQ = q->AddCheckBox("autoQ", "Auto Q", true);
		autoQ->AddTooltip("Only Isolated Target");
		combo_q = q->AddList("combo_q", "Use Q when:", std::vector<std::string> {"Isolated Target", "Always", "Never" }, 1);
		c_q = q->AddList("c_q", "Use in Combo:", std::vector<std::string> {"Always", "After AA", "Never" }, 0);
		c_q->AddTooltip("atm will only be used if no minion in range");
		farmQ = q->AddCheckBox("farmQ", "Farm Q", true);

		auto w = menu->AddMenu("w", "[W] Void Seeker");
		useW = w->AddCheckBox("useW", "W after AA to pop stack", true);
		combo_w = w->AddList("combo_w", "Use in Combo", std::vector<std::string> {"Only on CC", "Always", "Never" }, 0);
		combo_w->AddTooltip("'Only on CC' ignores stack check");
		combo_w_slider = w->AddSlider("combo_w_slider", "[Combo] Maximum range to check", 1000, 500, 2500, 100);
		w_stacks = w->AddSlider("w_stacks", "Minimum stacks", 3, 0, 4, 1);
		ks_w = w->AddCheckBox("ks_w", "Use to Killsteal", true);
		ks_w->AddTooltip("Ignores stack check");
		ks_w_slider = w->AddSlider("ks_w_slider", "[Killsteal] Maximum range to check", 2000, 500, 2500, 100);


		auto flee = menu->AddMenu("flee", "Flee Settings");
		use_e = flee->AddCheckBox("use_e", "Use E", true);


		AfterAttack();
	}

	float QDamage(CObject* target, int count)
	{
		if (target == nullptr)
		{
			return 0;
		}

		auto first_hit = GetSpellDamage(me, target, SpellSlot::Q);
		auto rest_hits = first_hit * (target->IsHero() ? 0.25f : 1);

		if (!(target->IsHero()) && target->HealthPercent() <= 35)
		{
			first_hit *= 2;
			rest_hits *= 2;
		}

		return first_hit + rest_hits * (count - 1);
	}

	CObject* q_get_prediction()
	{
		if (Q.LastCastAttemptT == Engine::GameGetTickCount())
			return Q.Unit;

		Q.LastCastAttemptT = Engine::GameGetTickCount();
		Q.Unit = nullptr;

		int count = Engine::GetMinionsAround(Q.Range, 1).size();

		CObject* target = nullptr;
		for (auto obj : Engine::GetHerosAround(1000.f))
		{
			auto seg = prediction->GetPrediction(obj, Q);
			if (seg.HitChance() >= HitChance::Low)
			{
				target = obj;
				break;
			}
		}

		if (count == 0 && combo_q->Value == 0)
		{
			if (target != nullptr)
			{
				Q.Unit = target;
				return Q.Unit;
			}
		}
		else if (combo_q->Value == 1)
		{
			if (target != nullptr)
			{
				Q.Unit = target;
				return Q.Unit;
			}
		}

		return Q.Unit;
	}

	bool q_get_action_state()
	{
		if (IsReady(0))
		{
			return q_get_prediction() != nullptr;
		}
		return false;
	}

	bool w_get_action_state()
	{
		if (IsReady(_W))
		{
			return w_get_prediction() != nullptr;
		}
		return false;
	}

	bool w_invoke_killsteal()
	{
		CObject* target = nullptr;
		for (auto obj : Engine::GetHerosAround(ks_w_slider->Value))
		{
			if (me->IsInAutoAttackRange(obj))
			{
				auto aa_damage = me->GetAutoAttackDamage(obj);
				if ((aa_damage * 2) > obj->Health() + obj->PhysicalShield())
					continue;
			}

			if (GetSpellDamage(me, obj, SpellSlot::W) > obj->Health() + obj->MagicalShield())
			{
				auto seg = prediction->GetPrediction(obj, W);
				if (seg.HitChance() >= HitChance::Low)
				{
					target = obj;
					break;
				}
			}
		}
		if (target != nullptr)
		{
			CastSpell(target, _W, W);
			return true;
		}

		return false;
	}

	CObject* w_get_prediction()
	{
		if (W.LastCastAttemptT == Engine::GameGetTickCount())
			return W.Unit;

		W.LastCastAttemptT = Engine::GameGetTickCount();
		W.Unit = nullptr;

		for (auto obj : Engine::GetHerosAround(combo_w_slider->Value))
		{
			if (me->IsInAutoAttackRange(obj))
			{
				auto aa_damage = me->GetAutoAttackDamage(obj);
				if ((aa_damage * 2) > obj->Health() + obj->PhysicalShield())
					continue;
			}

			if (w_stacks->Value > 0)
			{
				if (obj->BuffCount(FNV("kaisapassivemarker")) >= w_stacks->Value)
				{
					auto seg = prediction->GetPrediction(obj, W);
					if (seg.HitChance() >= HitChance::Low)
					{
						W.Unit = obj;
						break;
					}
				}
			}
			else
			{
				auto seg = prediction->GetPrediction(obj, W);
				if (seg.HitChance() >= HitChance::Low)
				{
					W.Unit = obj;
					break;
				}
			}

		}

		if (W.Unit != nullptr && (combo_w->Value == 0 ? W.Unit->GetBuffManager()->IsImmobile() : true))
			return W.Unit;

		return nullptr;
	}

	void AfterAttack()
	{
		SetFunctionCallBack(AfterAttackEvent, [&](CObject* actor) {

			if (global::mode == ScriptMode::Combo && actor->IsHero())
			{

				if (IsReady(_W) && useW->Value && actor->BuffCount(FNV("kaisapassivemarker")) >= (4 - (isWEvolved ? 3 : 2)))
				{
					CastSpell(actor, _W, W);
				}
			}

			return true;
			});
	}

	void get_action()
	{
		if (LagFree(0))
		{
			if (autoQ->Value)
			{
				int count = Engine::GetMinionsAround(Q.Range, 1).size();

				if (count == 0)
				{
					if (q_get_action_state())
					{
						CastSpell(0);
					}
				}
				auto target = targetselector->GetTarget(Q.Range);
				if (target != nullptr && me->IsAutoAttacking())
				{
					if (c_q->Value == 1 && q_get_action_state())
					{
						CastSpell(0);
					}
				}
			}

			if (c_q->Value == 0 && q_get_action_state())
			{
				CastSpell(0);
				return;
			}
		}

		if (LagFree(1))
		{
			if (combo_w->Value != 2 && w_get_action_state())
			{
				CastSpell(W.Unit, _W, W);
				return;
			}
		}

		if (LagFree(2))
		{
			if (use_e->Value)
			{
				if (IsReady(_E) && (!justR || isEEvolved))
				{
					auto cursorPos = Engine::GetMouseWorldPosition();
					auto target = targetselector->GetTarget(900);
					auto aa_target = orbwalker->GetTarget();
					auto moving_direction = XPolygon::To2D(cursorPos - me->Position()).Normalized();

					if (target != nullptr)
					{
						if (aa_target != nullptr && aa_target->Health() > QDamage(aa_target, isQEvolved ? 10 : 6) + me->GetAutoAttackDamage(aa_target))
						{
							if (Engine::GetHerosAround(400).size() > 0 && isEEvolved)
								CastSpell(_E);
							else if (!orbwalker->CanAttack())
								CastSpell(_E);
						}
						else if (aa_target == nullptr)
						{
							if (moving_direction.AngleBetween(XPolygon::To2D(target->Position() - me->Position())) < 30 &&
								target->Position().Distance(cursorPos) < 400)
							{
								if (!Engine::UnderTurret(target->Position()))
								{
									if (me->Mana() > ManaCost(_Q) + ManaCost(_W) + ManaCost(_E) && Engine::GetHerosAround(600, 2, target->Position()).size() == 1)
										CastSpell(_E);
									else if (target->HealthPercent() < 40 || target->Health() < QDamage(target, isQEvolved ? 10 : 6) + me->GetAutoAttackDamage(target) * 4)
										CastSpell(_E);
									else if (Engine::GetHerosAround(600, 2, target->Position()).size() < Engine::GetHerosAround(600, 1, me->Position()).size())
										CastSpell(_E);
								}
							}
						}
					}
				}
			}

			if (LagFree(4))
			{
			}

		}
	}

	void Tick()
	{
		if (LagFree(0))
		{
			isQEvolved = false;
			isWEvolved = false;
			isEEvolved = false;

			for (auto buff : me->GetBuffManager()->Buffs())
			{
				switch (buff.namehash)
				{
				case FNV("KaisaQEvolved"):
					isQEvolved = true;
					break;
				case FNV("KaisaWEvolved"):
					isWEvolved = true;
					break;
				case FNV("KaisaEEvolved"):
					isEEvolved = true;
					break;
				case FNV("kaisarshield"):
				{
					if (!justR)
					{
						justR = true;
						_DelayAction->Add(1000, []() {
							if (ResetSpell.autoaa)
							{
								justR = false;
							}
							});
					}
					break;
				}
				}
			}
		}

		if (LagFree(1))
		{
			auto laneMinions = Engine::GetMinionsAround(1000, 1);
			if (global::mode == ScriptMode::LaneClear && orbwalker->GetTarget() == nullptr && orbwalker->CanAttack() && farmQ->Value)
			{
				if (Engine::GetMinionsAround(600 + 30, 1).size() > 2)
				{
					CastSpell(0);
					return;
				}
			}
		}
		if (LagFree(2))
		{
			if (ks_w->Value)
			{
				if (w_invoke_killsteal())
					return;
			}
		}

		if (global::mode == ScriptMode::Combo)
		{
			get_action();
		}
	}


};