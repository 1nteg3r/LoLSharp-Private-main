#pragma once
class Irelia : public ModuleManager {
private:
	//ComboMenu  
	KeyBind* LogicQ;
	CheckBox* UseQ;
	CheckBox* UseW;
	CheckBox* UseE;
	CheckBox* UseR;
	CheckBox* UseRCount;
	CheckBox* farmturret;
	Slider* RCount;
	CheckBox* Gap;
	CheckBox* Stack;
	Vector3 ECatPos;

	KeyBind* StartB;
	Slider* Lvl;

	KeyBind* NinjaQ;
public:
	Irelia()
	{

	}

	~Irelia()
	{

	}

	void Draw()
	{
	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Irelia", "Irelia");
		auto ComboSet = menu->AddMenu("ComboSet", "Combo Settings");


		//ComboMenu 
		auto Combo = ComboSet->AddMenu("Combo", "Combo Mode");
		Combo->AddTooltip("E1, W, R, Q, E2, Q + (Q when kill / almost kill)");

		LogicQ = Combo->AddKeyBind("LogicQ", "Last[Q]Almost Kill or Kill", 0x61, false, true);
		UseQ = Combo->AddCheckBox("UseQ", "[Q]", true);
		UseW = Combo->AddCheckBox("UseW", "[W]", false);
		UseE = Combo->AddCheckBox("UseE", "[E]", true);
		UseR = Combo->AddCheckBox("UseR", "[R]Single Target if almost killable", true);

		UseRCount = Combo->AddCheckBox("UseRCount", "Auto[R] Multiple Enemys", true);
		RCount = Combo->AddSlider("RCount", "Multiple Enemys", 2, 2, 5, 1);

		Gap = Combo->AddCheckBox("Gap", "Gapclose [Q]", true);
		Stack = Combo->AddCheckBox("Stack", "Stack Passive near Target/Minion", true);
		farmturret = Combo->AddCheckBox("IreliaDiveTurretKeyFarm", "Dive Turret Farm", false);

		//BurstModeMenu
		auto Burst = ComboSet->AddMenu("Burst", "Burst Mode");

		Burst->AddTooltip("If Burst Active then Combo Mode is Inactive");
		StartB = Burst->AddKeyBind("StartB", "Use Burst Mode", 0x62, false, true);
		Lvl = Burst->AddSlider("Lvl", "Irelia Level to Start Burst", 6, 6, 18, 1);

		//BurstModeMenu
		auto Ninja = ComboSet->AddMenu("Ninja", "Ninja Mode");

		NinjaQ = Ninja->AddKeyBind("NinjaQ", "Q on all Marked Enemys", 0x62, true, true);
	}

	float CalcExtraDmg(CObject* unit)
	{
		float total = 0;
		bool Passive = me->HasBuff("ireliapassivestacksmax");
		auto PassiveDmg = me->CalculateDamage(unit, (10 + 3 * me->Level()-1) + (0.20 * me->BonusAttackDamage()));

		if (Passive)
			total = PassiveDmg;
		else
			total = 0;

		return total;
	}

	void AutoQ()
	{
	}

	void Gapclose(CObject* unit)
	{
		std::vector<CObject*> minions = Engine::GetMinionsAround(600, 1);
		for (auto minion : minions)
		{
			if (IsReady(_Q))
			{
				auto QDmg = GetSpellDamage(me, minion, SpellSlot::Q) + CalcExtraDmg(minion);
				if (QDmg > minion->Health() && me->Position().Distance(unit->Position()) > unit->Position().Distance(minion->Position()) && !me->IsDashing())
				{
					CastSpell(_Q, minion);
				}
			}
		}
	}

	void CastE(CObject* unit)
	{
		if (me->GetSpellBook()->GetSpellSlotByID(_E)->GetSpellData()->GetSpellName() == "IreliaE" && !unit->HasBuff("ireliamark"))
		{
			//Unit u;
			//u.unit = unit;
			//u.Paths = unit->GetWaypoints();

			PredictionInput Pi;
			Pi.Delay = 0.25 + Engine::GetLatency();
			Pi.Speed = HUGE_VAL;

			//auto aimpos = prediction->GetPrediction(unit, Pi);
			auto aimpos = prediction->PredictUnitPosition(unit, 200);

			if (aimpos.Distance(me->Position()) < 850.f - 200.0f)
			{
				auto vector2 = aimpos;
				for (int i = 50; i <= 800; i += 50)
				{
					vector2 = aimpos.Extended(me->Position(), -i);
					if (vector2.Distance(me->Position()) >= 850.f)
					{
						break;
					}
					aimpos = vector2;
				}
				if (CastSpell(_E, Engine::WorldToScreen(aimpos)))
				{
				 ECatPos = aimpos;
					return;
				}
			}
			else if (me->Distance(unit) < 600)
			{
				auto position = unit->ServerPosition().Extended(me->ServerPosition(), me->Distance(unit) + 850.f);

				if (CastSpell(_E, Engine::WorldToScreen(position)))
				{
					 ECatPos = position;
					return;
				}
			}
		}
		if (IsReady(_E) && me->GetSpellBook()->GetSpellSlotByID(_E)->GetSpellData()->GetSpellName() != "IreliaE" && ECatPos.IsValid())
		{

			auto vector3 = prediction->PredictUnitPosition(unit, 600);

			if (vector3.Distance(me->ServerPosition()) < 850.f - 200.0f)
			{
				auto v2 = vector3;
				int slider = 500;
				for (int j = 50; j <= slider; j += 50)
				{
					auto vector4 = vector3.Extended(ECatPos, -j);
					if (vector4.Distance(me->Position()) >= 850.f)
					{
						break;
					}
					v2 = vector4;
				}

				if (CastSpell(_E,Engine::WorldToScreen(v2)))
				{
					return;
				}
			}
		}
	/*	if (me->GetSpellBook()->GetSpellSlotByID(_E)->GetSpellData()->GetSpellName() == "IreliaE2")
		{
			CastSpell(_E, me);

		}*/

		/*if (me->GetSpellBook()->GetSpellSlotByID(_E)->GetSpellData()->GetSpellName() == "IreliaE" && !unit->HasBuff("ireliamark"))
		{
			if (me->Position().Distance(unit->Position()) <= 725)
			{
				auto aimpos = Prediction().GetPrediction(unit, SpellDatabase["IreliaEParticleMissile"]);
				if (aimpos.CastPos.IsValid())
				{
					auto Epos = unit->Pos2D() + (me->Pos2D() - aimpos.CastPos).Normalized() * -150;
					QueueTimer = Engine::GameGetTickCount();
					CastSpell(_E, Engine::WorldToScreen(XPolygon::To3D(Epos)));
				}
			}
		}
		if (me->GetSpellBook()->GetSpellSlotByID(_E)->GetSpellData()->GetSpellName() == "IreliaE2" && !unit->HasBuff("ireliamark"))
		{

			= Engine::GameGetTickCount();
			CastSpell(_E, me);
		}*/
	}

	void CastE2()
	{
	}
	void KillSteal()
	{
	}
	void LaneClear()
	{
		if (IsReady(_Q))
		{
			std::vector<CObject*> minions = Engine::GetMinionsAround(600, 1);
			for (auto minion : minions)
			{
				if (IsReady(_Q))
				{
					auto QDmg = GetSpellDamage(me, minion, SpellSlot::Q) + CalcExtraDmg(minion);

					if ((QDmg > minion->Health() || minion->HasBuff("ireliamark")) && (!Engine::UnderTurret(minion->Position()) || farmturret->Value))
					{
						orbwalker->UseOrbWalker = false;
						CastSpell(_Q, minion);
					}
				}
			}
		}

		std::vector<CObject*> jungles = Engine::GetJunglesAround(600, 2);
		for (auto jungle : jungles)
		{
			if (IsReady(_Q))
			{
				auto QDmg = GetSpellDamage(me, jungle, SpellSlot::Q) + CalcExtraDmg(jungle);

				if ((QDmg > jungle->Health() || jungle->HasBuff("ireliamark")) && !me->IsDashing())
				{
					CastSpell(_Q, jungle);
				}
			}
		}
	}

	void LastHit()
	{
		if (IsReady(_Q))
		{
			std::vector<CObject*> minions = Engine::GetMinionsAround(600, 1);
			for (auto minion : minions)
			{
				auto QDmg = GetSpellDamage(me, minion, SpellSlot::Q) + CalcExtraDmg(minion);
				if (QDmg > minion->Health() && (!Engine::UnderTurret(minion->Position()) || farmturret->Value))
				{
					orbwalker->UseOrbWalker = false;
					CastSpell(_Q, minion);
				}
			}
		}
	}
	void Ninja()
	{
		auto target1 = targetselector->GetTarget(1100);
		if (NinjaQ->Value)
		{
			for (auto actor : global::enemyheros)
			{
				auto target2 = (CObject*)actor.actor;
				if (IsReady(_Q) && Engine::GetEnemyCount(2000, me->Position()) >= 2)
				{
					if ((uint32_t)target1 && (uint32_t)target2 && target2 != target1)
					{
						if (me->Position().Distance(target2->Position()) <= 600 && IsReady(_Q) && target2->IsValidTarget() && target2->Health() <= global::qdmg + CalcExtraDmg(target2))
							CastSpell(_Q, target2);

						else if (me->Position().Distance(target2->Position()) <= 600 && IsReady(_Q) && target2->HasBuff("ireliamark") && target2->IsValidTarget() && target2->Health() <= (global::qdmg + CalcExtraDmg(target2)) * 2)
							CastSpell(_Q, target2);

						if (me->Position().Distance(target2->Position()) <= 600 && IsReady(_Q) && target2->HasBuff("ireliamark") && target2->IsValidTarget())
						{
							auto time2 = me->Position().Distance(target2->Position()) / (1500 + me->MoveSpeed());
							auto buff = target2->GetBuffManager()->GetBuffEntryByName("ireliamark");
							float duration = 0;
							if (buff && target2->BuffCount("ireliamark") > 0)
							{
								duration = buff->GetBuffEndTime();
							}

							if (duration > time2)
							{
								CastSpell(_Q, target2);
							}
						}
						if ((me->Position().Distance(target2->Position()) > 600 || !target2->HasBuff("ireliamark")) && me->Position().Distance(target1->Position()) <= 600 && IsReady(_Q) && target1->HasBuff("ireliamark") && target1->IsValidTarget())
						{
							auto time1 = me->Position().Distance(target1->Position()) / (1500 + me->MoveSpeed());
							auto buff = target1->GetBuffManager()->GetBuffEntryByName("ireliamark");
							float duration = 0;
							if (buff && target1->BuffCount("ireliamark") > 0)
							{
								duration = buff->GetBuffEndTime();
							}

							if (duration > time1)
							{
								CastSpell(_Q, target1);
							}
						}
					}
				}
			}
		}


		Combo();
	}

	void Combo()
	{

		auto target = targetselector->GetTarget(850);
		if (target != nullptr)
		{
			auto count = Engine::GetEnemyCount(1500, me->Position());

			auto QDmg = GetSpellDamage(me, target, SpellSlot::Q) + CalcExtraDmg(target);
			auto RDmg = GetSpellDamage(me, target, SpellSlot::R);
			auto AADmg = GetSpellDamage(me, target, SpellSlot::AA);
			auto EDmg = GetSpellDamage(me, target, SpellSlot::E);
			auto WDmg = GetSpellDamage(me, target, SpellSlot::W);

			if (IsReady(_R) && UseR->Value)
			{
				if (me->Position().Distance(target->Position()) <= 850 && count == 1)
				{


					if ((QDmg * 2 + RDmg * 2 + AADmg * 2 + EDmg + WDmg + activator->ignitedmg()) >= target->Health())
					{
						CastSpell(target, _R, "IreliaR");
					}
				}
			}
			if (IsReady(_R) && me->Position().Distance(target->Position()) <= 850)
			{
				auto count = Engine::GetEnemyCount(400, target->Position());

				if (count >= RCount->Value)
				{
					CastSpell(target, _R, "IreliaR");
				}
			}

			if (IsReady(_E) && UseE->Value)
			{
				if (me->Position().Distance(target->Position()) <= 725)
				{
					CastE(target);
				}
			}

			if (me->Position().Distance(target->Position()) <= 600 && IsReady(_Q) && target->HasBuff("ireliamark") && !me->IsDashing() && UseQ->Value)
			{
				CastSpell(_Q, target);
			}

			if (IsReady(_W) && !IsReady(2) && !IsReady(0) && UseW->Value)
			{
				if (orbwalker->AfterAutoAttack() && me->Position().Distance(target->Position()) <= 825)
				{
					CastSpell(target, _W, "IreliaW2");
				}
			}


			if (LogicQ->Value) // LogicQ
			{
				if (me->HealthPercent() < 20)
				{
					CastSpell(_Q, target);

				}
				if (me->Position().Distance(target->Position()) <= 600 && IsReady(_Q))
				{
					if (QDmg >= target->Health())
					{
						CastSpell(_Q, target);
					}
				}

				if (me->Position().Distance(target->Position()) <= 600)
				{
					if (target->Health() <= QDmg * 2 + AADmg)
					{
						CastSpell(_Q, target);
					}
				}
			}
			else
			{
				if (me->Position().Distance(target->Position()) <= 600 && IsReady(_Q))
				{
					if (QDmg >= target->Health())
					{
						CastSpell(_Q, target);
					}
				}
			}

			if (Gap->Value)
			{
				Gapclose(target);
			}

		}
	}

	void Tick()
	{
		orbwalker->UseOrbWalker = true;
		if (global::mode== ScriptMode::Combo)
		{
			Ninja();
		}
		else if (global::mode== ScriptMode::LaneClear)
		{
			LaneClear();
		}
		else if (global::mode== ScriptMode::LastHit)
		{
			LastHit();
		}

		KillSteal();
		CastE2();
	}
};
