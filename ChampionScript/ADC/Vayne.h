#pragma once
class Vayne : public ModuleManager
{
private:
public:

	PredictionInput Q = PredictionInput({ 300.f });
	PredictionInput W = PredictionInput({ 670.f });
	PredictionInput E = PredictionInput({ 550,0.25f,65.f, 2000.f });
	PredictionInput R = PredictionInput({ 3000.f });

	CheckBox *Range;
	CheckBox *qRange;
	CheckBox *onlyRdy;
	CheckBox *eRange2;
	CheckBox *rRange;
	CheckBox *autoQ;
	Slider *Qstack;
	CheckBox *Qonly;
	CheckBox *QE;
	KeyBind *useE;
	CheckBox *Eks;
	CheckBox *Ecombo;

	CheckBox *autoR;
	CheckBox *visibleR;
	CheckBox *autoQR;

	CheckBox *farmQ;
	CheckBox *farmQjungle;


	Vayne()
	{
	}

	~Vayne()
	{
	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Vayne", "Vayne");

		auto Draw = menu->AddMenu("Draw", "Draw");
		auto QConfig = menu->AddMenu("QConfig", "QConfig");
		auto WConfig = menu->AddMenu("WConfig", "WConfig");
		auto EConfig = menu->AddMenu("EConfig", "EConfig");
		auto RConfig = menu->AddMenu("RConfig", "RConfig");
		auto Farm = menu->AddMenu("Farm", "Farm");


		onlyRdy = Draw->AddCheckBox("onlyRdy", "Draw only ready spells", true);
		qRange = Draw->AddCheckBox("qRange", "Q range", false);
		eRange2 = Draw->AddCheckBox("eRange2", "E push position", false);

		autoQ = QConfig->AddCheckBox("autoQ", "Auto Q", true);
		Qstack = QConfig->AddSlider("Qstack", "Q at X stack", 2, 1, 2, 1);
		QE = QConfig->AddCheckBox("QE", "try Q + E ", true);
		Qonly = QConfig->AddCheckBox("Qonly", "Q only after AA", false);
		 
		useE = EConfig->AddKeyBind("useE", "OneKeyToCast E closest person", VK_KEY_T, false, false); //32 == space
		Eks = EConfig->AddCheckBox("Eks", "E KS", true);
		Ecombo = EConfig->AddCheckBox("Ecombo", "E combo only", false);

		autoR = RConfig->AddCheckBox("autoR", "Auto R", true);
		visibleR = RConfig->AddCheckBox("visibleR", "Unvisable block AA ", true);
		autoQR = RConfig->AddCheckBox("autoQR", "Auto Q when R active ", true);

		farmQ = Farm->AddCheckBox("farmQ", "Q farm helper", true);
		farmQjungle = Farm->AddCheckBox("farmQjungle", "Q jungle", true);

		Q.Slot = SpellSlot::Q;
		dashcast = new DashCast();
		dashcast->Init2(menu, Q);
		dashcast->Add();

		SetFunctionCallBack(BeforeAttackEvent, [&](CObject* actor) {
			if (visibleR->Value && me->HasBuff(FNV("vaynetumblefade")) && Engine::GetEnemyCount(800, me->Position()) > 1)
			{
				auto t = actor;
				if (t != nullptr)
				{
					if (GetWStacks(t) < 2 && t->Health() > 5 * me->CalculateAutoAttackDamage(me, t))
					{
						for (auto target : Engine::GetHerosAround(800, 1))
						{
							if (target->IsValidTarget(800) && GetWStacks(target) == 2)
							{
								if (me->IsInAutoAttackRange(target) && t->Health() > 3 * me->CalculateAutoAttackDamage(me, t))
								{
									orbwalker->SetForceTarget(target);
								}
							}
						}
					}
				}

				if (Engine::UnderTurret(me->Position()))
					return true;

				return false;
			}

			return true;
		});

		SetFunctionCallBack(AfterAttackEvent, [&](CObject* actor) {
			auto t = actor;

			if (t != nullptr)
			{
				if (t->IsHero())
				{
					if (IsReady(_E) && Eks->Value)
					{
						auto dmgE = GetSpellDamage(me, t, SpellSlot::E, false);

						if (GetWStacks(t) == 1)
							dmgE += Wdmg(t);

						if (dmgE > t->Health())
						{
							CastSpell(_E, t);
						}
					}

					if (IsReady(_Q) && !(global::mode == ScriptMode::None) && autoQ->Value && (GetWStacks(t) == Qstack->Value - 1 || t->HasBuff(FNV("vayneinquisition"))))
					{
						auto dashPos = dashcast->CastDash(true);
						if (dashPos.IsValid())
						{
							CastSpell(_Q, Engine::WorldToScreen(dashPos));
						}
					}
				}
			}


			/*auto m = actor;
			if (t->IsMinion())
			{
				if (m != nullptr)
				{
					if (IsReady(_Q) && global::mode== ScriptMode::LaneClear && farmQ->Value)
					{
						auto dashPosition = me->Position().Extended(Engine::GetMouseWorldPosition(), Q.Range);
						if (!dashcast->IsGoodPosition(dashPosition))
							return true;

						if (farmQjungle->Value && m->Team() == 300)
						{
							CastSpell(_Q, Engine::WorldToScreen(dashPosition));
						}

						if (farmQ->Value)
						{
							for (auto minion : Engine::GetMinionsAround(me->GetSelfAttackRange(), 1, dashPosition))
							{
								auto time = (int)(me->AttackCastDelay() * 1000) + Engine::GetPing() / 2 + 1000 * (int)MAX(0, me->Distance(minion) - global::LocalData->gameplayRadius) / (int)global::LocalData->basicAttackMissileSpeed;
								auto predHealth = orbwalker->GetHealthPrediction(minion, time);
								if (predHealth < me->CalculateAutoAttackDamage(me, minion) + GetSpellDamage(me, minion, SpellSlot::Q, false) && predHealth > me->CalculateAutoAttackDamage(me,minion))
								{
									CastSpell(_Q, Engine::WorldToScreen(dashPosition));
									orbwalker->SetForceTarget(minion);
									orbwalker->IssueAttack(minion);
								}
							}
						}
					}
				}
			}*/

			return true;
		});


	}
	double Wdmg(CObject* target)
	{
		return target->MaxHealth() * (4.5 + me->GetSpellBook()->GetSpellSlotByID(1)->Level() * 1.5) * 0.01;
	}
	bool CondemnCheck(Vector3 fromPosition, CObject* target)
	{
		auto prepos = prediction->GetPrediction(target, E);

		float pushDistance = 475;

		if (me->ServerPosition() != fromPosition)
			pushDistance = 450;

		int radius = 45;
		auto start2 = target->ServerPosition();
		auto end2 = prepos.CastPosition().Extended(fromPosition, -pushDistance);

		Vector2 start = XPolygon::To2D(start2);
		Vector2 end = XPolygon::To2D(end2);

		auto dir = (end - start).Normalized();
		auto pDir = dir.Perpendicular();

		auto rightEndPos = end + pDir * radius;
		auto leftEndPos = end - pDir * radius;


		auto rEndPos = Vector3(rightEndPos.x, Engine::heightForPosition(rightEndPos), rightEndPos.y);
		auto lEndPos = Vector3(leftEndPos.x, Engine::heightForPosition(leftEndPos), leftEndPos.y);


		auto step = start2.Distance(rEndPos) / 10;
		for (int i = 0; i < 10; i++)
		{
			auto pr = start2.Extended(rEndPos, step * i);
			auto pl = start2.Extended(lEndPos, step * i);
			if (Engine::IsWall(pr) && Engine::IsWall(pl))
				return true;
		}

		return false;
	}
	int GetWStacks(CObject* target)
	{
		for (auto buff : target->GetBuffManager()->Buffs())
		{
			if (buff.namehash == FNV("vaynesilvereddebuff"))
				return buff.count;
		}
		return 0;
	}

	void Draw()
	{

	}

	void Tick()
	{
		if (global::mode== ScriptMode::Combo || global::mode== ScriptMode::Mixed || global::mode== ScriptMode::LaneClear)
		{

			auto dashPosition = me->Position().Extended(Engine::GetMouseWorldPosition(), Q.Range);

			if (IsReady(_E))
			{
				if (!Ecombo->Value || global::mode== ScriptMode::Combo)
				{

					for (auto target : Engine::GetHerosAround(E.Range, 1))
					{
						if (target->IsValidTarget(E.Range) /*&& target->GetPath3D().size() < 2*/)
						{
							if (CondemnCheck(me->ServerPosition(), target))
								CastSpell(_E, target);
							else if (IsReady(_Q) && dashcast->IsGoodPosition(dashPosition) && QE->Value && CondemnCheck(dashPosition, target))
							{
								CastSpell(_Q, Engine::WorldToScreen(dashPosition));
							}
						}
					}
				}
			}

			if (LagFree(1) && IsReady(_Q))
			{
				if (autoQR->Value && me->HasBuff(FNV("vayneinquisition")) && Engine::GetEnemyCount(1500, me->Position()) > 0 && Engine::GetEnemyCount(670, me->Position()) != 1)
				{
					auto dashPos = dashcast->CastDash();
					if (dashPos.IsValid())
					{
						CastSpell(_Q, Engine::WorldToScreen(dashPos));
					}
				}
				if (global::mode== ScriptMode::Combo && autoQ->Value && !Qonly->Value)
				{
					auto t = targetselector->GetTarget(900);

					if (t->IsValidTarget() && !me->IsInAutoAttackRange(t) && t->Position().Distance(Engine::GetMouseWorldPosition()) < t->Position().Distance(me->Position()) && !t->IsFacing(me->Position()))
					{
						auto dashPos = dashcast->CastDash();
						if (dashPos.IsValid())
						{
							CastSpell(_Q, Engine::WorldToScreen(dashPos));
						}
					}
				}
			}

			if (LagFree(2))
			{
				CObject* bestEnemy = nullptr;
				for (auto target : Engine::GetHerosAround(E.Range, 1))
				{
					if (target->IsValidTarget(250) && target->IsMelee())
					{
						if (IsReady(_Q) && autoQ->Value)
						{
							auto dashPos = dashcast->CastDash(true);
							if (dashPos.IsValid())
							{
								CastSpell(_Q, Engine::WorldToScreen(dashPos));
							}
						}
						else if (IsReady(_E) && me->Health() < me->MaxHealth() * 0.4)
						{
							CastSpell(_E, target);
						}
					}
					if (bestEnemy == nullptr)
						bestEnemy = target;
					else if (me->Distance(target) < me->Distance(bestEnemy))
						bestEnemy = target;
				}
				if (useE->Value && bestEnemy != nullptr)
				{
					CastSpell(_E, bestEnemy);
				}
			}

			if (LagFree(3) && IsReady(_R))
			{
				if (autoR->Value)
				{
					if (Engine::GetEnemyCount(700, me->Position()) > 2)
						CastSpell(_R);
					else if (global::mode== ScriptMode::Combo && Engine::GetEnemyCount(600, me->Position()) > 1)
						CastSpell(_R);
					else if (me->Health() < me->MaxHealth() * 0.5 && Engine::GetEnemyCount(500, me->Position()) > 0)
						CastSpell(_R);
				}
			}
		}

	}
};