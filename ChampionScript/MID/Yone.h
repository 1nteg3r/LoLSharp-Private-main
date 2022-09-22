#pragma once
class Yone : public ModuleManager {
public:
	CheckBox* UseQ;
	CheckBox* StackQ;
	CheckBox* UseQ3;
	CheckBox* UseW;
	CheckBox* UseE;
	CheckBox* UseR;
	Slider* HitR;
	CheckBox* RCC;
	CheckBox* RCanKill;

	CheckBox* HarrassUseQ;
	CheckBox* HarrassUseW;
	CheckBox* HarrassUseE;

	CheckBox* LaneClearUseQ;
	CheckBox* LaneClearUseW;


	CheckBox* LastHitUseQ;
	CheckBox* LastHitUseW;

	int maxRangeE = 1225;
	int lengthE = 700;
	int speedE = 1050;
	int rangeE = 500;
	int lasttick = 0;

	float Q1_MAX_WINDUP = 0.35f;
	float Q1_MIN_WINDUP = 0.175f;
	float LOSS_WINDUP_PER_ATTACK_SPEED = (0.35 - 0.3325) / 0.12;
	float additional_attack_speed = (me->AttackSpeedMod() - 1);
	float q1_delay = std::max(Q1_MIN_WINDUP, Q1_MAX_WINDUP - (additional_attack_speed * LOSS_WINDUP_PER_ATTACK_SPEED));

	PredictionInput Q = PredictionInput({ 450.0f, q1_delay,80.0f, FLT_MAX, false, SkillshotType::SkillshotLine });
	PredictionInput Q2 = PredictionInput({ 985.0f,(float)(0.4 * (1 - std::min((me->AttackSpeedMod() - 1) * 0.58, 0.66))),160.0f,1500.0f, false, SkillshotType::SkillshotLine });
	PredictionInput W = PredictionInput({ 600.0f, (float)(0.4 * (1 - std::min((me->AttackSpeedMod() - 1) * 0.58, 0.66))), 80.0f, FLT_MAX, false, SkillshotType::SkillshotLine });
	PredictionInput E = PredictionInput({ 750.0f, 0.25f,750.0f,FLT_MAX,false, SkillshotType::SkillshotLine });
	PredictionInput E2 = PredictionInput({ 1285.0f, 0.25f,1285.0f,FLT_MAX,false, SkillshotType::SkillshotLine });
	PredictionInput R = PredictionInput({ 1000.0f, 0.8f,225,FLT_MAX,false, SkillshotType::SkillshotLine });

	Yone()
	{

	}

	~Yone()
	{

	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Yone", "Yone");
		auto ComboSet = menu->AddMenu("ComboSet", "Combo Settings");
		UseQ = ComboSet->AddCheckBox("UseQ", "Use Q", true);
		UseW = ComboSet->AddCheckBox("UseW", "Use W", true);
		UseE = ComboSet->AddCheckBox("UseE", "Use E", true);
		UseR = ComboSet->AddCheckBox("UseR", "Use R", true);

		auto Rconfig = menu->AddMenu("Rconfig", "R config");
		HitR = Rconfig->AddSlider("HitR", "Auto R on enemies ", 3, 1, 5, 1);
		RCC = Rconfig->AddCheckBox("RCC", "Use R on CC", true);
		RCanKill = Rconfig->AddCheckBox("RCanKill", "Use R if can kill combo", true);

		auto HarassSet = menu->AddMenu("HarassSet", "Harass Settings");
		HarrassUseQ = HarassSet->AddCheckBox("harassUseQ", "Use Q", true);
		HarrassUseW = HarassSet->AddCheckBox("harassUseW", "Use W", true);
		HarrassUseW = HarassSet->AddCheckBox("harassUseE", "Use E", true);

		auto LaneClearSet = menu->AddMenu("LaneClearSet", "Harass Settings");
		LaneClearUseQ = LaneClearSet->AddCheckBox("LaneClearUseQ", "Use Q", true);
		LaneClearUseW = LaneClearSet->AddCheckBox("LaneClearUseW", "Use W", true);

		auto LastHitSet = menu->AddMenu("LastHitSet", "LastHit Settings");
		LastHitUseQ = LastHitSet->AddCheckBox("LastHitUseQ", "Use Q", true);
		LastHitUseW = LastHitSet->AddCheckBox("LastHitUseW", "Use W", true);
		//auto MiscSet = menu->AddMenu("MiscSet", "Misc Settings");
		//autoW = MiscSet->AddCheckBox("autoW", "Use W to continue CC", true);
		//spPriority = MiscSet->AddCheckBox("spPriority", "Prioritize kill over dmg", true);

		SetFunctionCallBack(AfterAttackEvent, [&](CObject* actor) {

			auto Qspellname = me->GetSpellBook()->GetSpellSlotByID(_Q)->GetSpellData()->GetSpellName();
			if (actor)
			{
				CastSpell(actor, _W, W);
			}

			if (actor && Qspellname == "YoneQ")
			{
				CastSpell(actor, _Q, Q);

				//				CastSpell(_Q, Engine::WorldToScreen(Qtarget->Position()));
			}
			if (actor && Qspellname == "YoneQ3")
			{
				CastSpell(actor, _Q, Q2);
			}

			return true;
			});

	}

	


	Vector3 RHit()
	{

		int RHitCount = 0;
		Vector3 castpos;

		std::vector<CObject*> heroes = Engine::GetHerosAround(R.Range, 1);
		for (auto target : heroes)
		{

			if (PointOnLineSegment(me->Pos2D(), XPolygon::To2D(me->Position().Extended(target->Position(), R.Range)), target->Pos2D(), R.Radius + target->BoundingRadius()))
			{
				++RHitCount;
			}
			castpos = target->Position();
		}

		if (RHitCount > HitR->Value)
			return castpos;
		else
			return Vector3::Zero;

		//return RHitCount;
	}

	void Draw()
	{

	}

	float TotalDmg(CObject* enemy, bool useQ, bool useE, bool useR, bool qRange)
	{

	}

	float GetComboDamage(CObject* enemy)
	{

		return TotalDmg(enemy, true, true, true, false);
	}

	void PredictCastE(CObject* target)
	{



	}

	void CastE(Vector3 source1, Vector3 destination1)
	{

	}
	void AutoR()
	{
		int RHitCount = 0;

		auto enemiesR = Engine::GetHerosAround(R.Range, 1);
		CObject* Rcasttarget = nullptr;

		for (auto target : enemiesR)
		{

			if (target->StatusFlags() == 512 && target->IsValidTarget())
				if (CastSpell(_R, target))
					return;

			if (PointOnLineSegment(me->Pos2D(), XPolygon::To2D(me->Position().Extended(target->Position(), R.Range)), target->Pos2D(), R.Radius + target->BoundingRadius()))
			{
				++RHitCount;
			}
			Rcasttarget = target;


		}
		if (RHitCount >= HitR->Value && Rcasttarget != nullptr && UseR->Value)
			CastSpell(Rcasttarget, _R, R);

	}
	bool CanKill(CObject* target)
	{
		if (target)
		{
			auto Qdmg = GetSpellDamage(me, target, SpellSlot::Q);
			auto Wdmg = GetSpellDamage(me, target, SpellSlot::W);
			auto Edmg = GetSpellDamage(me, target, SpellSlot::E);
			auto Rdmg = GetSpellDamage(me, target, SpellSlot::R);
			auto AAdmg = GetSpellDamage(me, target, SpellSlot::AA);

			//printf("%.0f | %.0f | %.0f | %.0f \n", Qdmg, Wdmg, Edmg, Rdmg);
			if (target->Health() <= Qdmg + Wdmg + Edmg + Rdmg + AAdmg + activator->ignitedmg() + activator->smitedmg())
			{
				return true;
			}
		}
		return false;
	}
	void onCombo()
	{
		auto Q2target = targetselector->GetTarget(Q2.Range);
		auto Wtarget = targetselector->GetTarget(W.Range);
		auto Qtarget = targetselector->GetTarget(Q.Range);
		auto Rtarget = targetselector->GetTarget(R.Range);
		auto EQtarget = targetselector->GetTarget(E.Range);
		auto EQ2target = targetselector->GetTarget(E2.Range);
		auto Qspellname = me->GetSpellBook()->GetSpellSlotByID(_Q)->GetSpellData()->GetSpellName();

		if (EQtarget && IsReady(_Q) && Qspellname == "YoneQ" && me->Position().Distance(EQtarget->Position()) >= Q.Range + 50 && !me->HasBuff("YoneE") && UseE->Value)
		{
			//printf("ok1");

			CastSpell(_E, Engine::WorldToScreen(EQtarget->Position()));
		}

		if (EQ2target && IsReady(_Q) && Qspellname == "YoneQ3" && me->Position().Distance(EQ2target->Position()) >= Q2.Range + 50 && !me->HasBuff("YoneE") && UseE->Value)
		{
			//printf("ok2");

			CastSpell(_E, Engine::WorldToScreen(EQ2target->Position()));
		}

		if (Qtarget && Qspellname == "YoneQ"  && UseQ->Value)
		{
			CastSpell(Qtarget, _Q, Q);
		}
		if (Q2target && Qspellname == "YoneQ3" && (!me->IsInAutoAttackRange(Qtarget)) && UseQ->Value)
		{
			CastSpell(Q2target, _Q, Q2);
		}

		if (Wtarget && (!me->IsInAutoAttackRange(Wtarget)) && UseW->Value)
		{
			CastSpell(Wtarget, _W, W);
		}


		if (Rtarget && Rtarget->GetBuffManager()->IsImmobile() && UseR->Value && RCC->Value)
		{
			CastSpell(_R, Engine::WorldToScreen(Rtarget->ServerPosition()));
		}

		if (CanKill(Rtarget) && UseR->Value && RCanKill->Value)
			CastSpell(_R, Engine::WorldToScreen(Rtarget->ServerPosition()));


		//if (Etoggle == CSpellSlot::SpellToggleState::None)
		//CastSpell(EQtarget, _E, E);


		//if (orbwalker->AfterAutoAttack())
//		{
//			if (Wtarget)
//			{
//				CastSpell(Wtarget, _W, W);
//			}
//
//			if (Qtarget && Qspellname == "YoneQ")
//			{
//				CastSpell(Qtarget, _Q, Q);
//
////				CastSpell(_Q, Engine::WorldToScreen(Qtarget->Position()));
//			}
//			if (Q2target && Qspellname == "YoneQ3")
//			{
//				CastSpell(Q2target, _Q, Q2);
//			}
//		}
	}


	void AutoW()
	{

	}
	float EDuration(CObject* unit)
	{
		for (auto buff : unit->GetBuffManager()->Buffs())
		{
			if (buff.namehash == FNV("YoneE") && buff.count > 0)
			{
				return buff.remaintime;
			}
			else if (buff.namehash == FNV("YoneE") && buff.count > 0)
			{
				return buff.remaintime;
			}
		}
		return 0;
	}

	void CalculateEDamage()
	{

		if (me->HasBuff("YoneE") && me->GetBuffManager()->GetBuffEntryByName("YoneE")->GetBuffStartTime() + 10.0f <= Engine::GameGetTickCount())
		{
			//get target health
		}
	}
	void onHarass()
	{
		auto Q2target = targetselector->GetTarget(Q2.Range);
		auto Wtarget = targetselector->GetTarget(W.Range);
		auto Qtarget = targetselector->GetTarget(Q.Range);
		auto Rtarget = targetselector->GetTarget(R.Range);
		auto EQtarget = targetselector->GetTarget(E.Range);
		auto EQ2target = targetselector->GetTarget(E2.Range);
		auto Qspellname = me->GetSpellBook()->GetSpellSlotByID(_Q)->GetSpellData()->GetSpellName();

		if (EQtarget && IsReady(_Q) && Qspellname == "YoneQ" && me->Position().Distance(EQtarget->Position()) >= Q.Range + 50 && !me->HasBuff("YoneE") && HarrassUseE->Value)
		{
			//printf("ok1");

			CastSpell(_E, Engine::WorldToScreen(EQtarget->Position()));
		}

		if (EQ2target && IsReady(_Q) && Qspellname == "YoneQ3" && me->Position().Distance(EQ2target->Position()) >= Q2.Range + 50 && !me->HasBuff("YoneE") && HarrassUseE->Value)
		{
			//printf("ok2");

			CastSpell(_E, Engine::WorldToScreen(EQ2target->Position()));
		}

		if (Qtarget && Qspellname == "YoneQ" && (!me->IsInAutoAttackRange(Qtarget)) && HarrassUseQ->Value)
		{
			CastSpell(Qtarget, _Q, Q);
		}
		if (Q2target && Qspellname == "YoneQ3" && (!me->IsInAutoAttackRange(Qtarget)) && HarrassUseQ->Value)
		{
			CastSpell(Q2target, _Q, Q2);
		}

		if (Wtarget && (!me->IsInAutoAttackRange(Wtarget) || !orbwalker->CanAttack()) && HarrassUseW->Value)
		{
			CastSpell(Wtarget, _W, W);
		}
		if (orbwalker->AfterAutoAttack())
		{
			if (Wtarget)
			{
				CastSpell(Wtarget, _W, W);
			}

			if (Qtarget && Qspellname == "YoneQ")
			{
				CastSpell(Qtarget, _Q, Q);

				//				CastSpell(_Q, Engine::WorldToScreen(Qtarget->Position()));
			}
			if (Q2target && Qspellname == "YoneQ3")
			{
				CastSpell(Q2target, _Q, Q2);
			}
		}
	}
	void onLaneClear()
	{
		auto minions = Engine::GetMinionsAround(Q.Range, 1, me->Position());
		int orbTarget = 0;

		if (orbwalker->GetTarget() != nullptr)
			orbTarget = orbwalker->GetTarget()->NetworkID();

		auto Qspellname = me->GetSpellBook()->GetSpellSlotByID(_Q)->GetSpellData()->GetSpellName();

		for (auto minion : minions)
		{
			if (1)
			{

				auto Qdmg = GetSpellDamage(me, minion, SpellSlot::Q);
				auto Wdmg = GetSpellDamage(me, minion, SpellSlot::W);
				//printf("Q: %.0f\n", Qdmg);
				if (minion->IsValidTarget() && orbTarget != minion->NetworkID())
				{
					int delay = (int)((minion->Distance(me) / Q.Speed + Q.Delay) * 1000);
					auto hpPred = orbwalker->GetHealthPrediction(minion, delay);
					if (hpPred > 0 && hpPred <= Qdmg && (minion->IsSiegeMinion() || minion->IsSuperMinion()) && Qspellname == "YoneQ" && LaneClearUseQ->Value)
					{
						if (CastSpell(_Q, minion))
							return;
					}


					if (hpPred > 0 && hpPred <= Qdmg && Qspellname == "YoneQ" && LaneClearUseQ->Value)
						if (CastSpell(_Q, Engine::WorldToScreen(minion->Position())))
							return;

					if (hpPred > 0 && hpPred <= Wdmg && orbwalker->AfterAutoAttack() && LaneClearUseW->Value)
						if (CastSpell(_W, Engine::WorldToScreen(minion->Position())))
							return;

				}
				if (Qdmg >= minion->Health() && minion->IsSiegeMinion() && LaneClearUseQ->Value)
				{
					CastSpell(_Q, Engine::WorldToScreen(minion->Position()));
				}
				if (minion->Health() <= Wdmg && orbwalker->CanAttack() && LaneClearUseW->Value)
				{
					CastSpell(_W, Engine::WorldToScreen(minion->Position()));

				}
			}
		}

		std::vector<CObject*> jungles = Engine::GetJunglesAround(Q.Range, 2);
		for (auto jungle : jungles)
		{
			auto Qdmg = GetSpellDamage(me, jungle, SpellSlot::Q);
			auto Wdmg = GetSpellDamage(me, jungle, SpellSlot::W);
			if (IsReady(_Q))
			{


				if (Qdmg >= jungle->Health() && (jungle->IsLargeMonster() || jungle->IsEpicMonster()) && LaneClearUseQ->Value)
				{
					CastSpell(_Q, Engine::WorldToScreen(jungle->Position()));
				}

				if (Qdmg >= jungle->Health() && jungle->IsSiegeMinion() && LaneClearUseQ->Value)
				{
					CastSpell(_Q, Engine::WorldToScreen(jungle->Position()));
				}

			}
			if (jungle->Health() <= Wdmg && orbwalker->CanAttack() && LaneClearUseW->Value)
			{
				CastSpell(_W, Engine::WorldToScreen(jungle->Position()));

			}
			if (orbwalker->AfterAutoAttack())
			{
				//printf("wtf");
				CastSpell(_Q, Engine::WorldToScreen(jungle->Position()));
				CastSpell(_W, Engine::WorldToScreen(jungle->Position()));

			}
		}

	}

	void onLastHit()
	{
		auto minions = Engine::GetMinionsAround(Q.Range, 1, me->Position());
		int orbTarget = 0;
		auto Qspellname = me->GetSpellBook()->GetSpellSlotByID(_Q)->GetSpellData()->GetSpellName();

		if (orbwalker->GetTarget() != nullptr)
			orbTarget = orbwalker->GetTarget()->NetworkID();

		for (auto minion : minions)
		{
			if (1)
			{
				auto Qdmg = GetSpellDamage(me, minion, SpellSlot::Q);
				auto Wdmg = GetSpellDamage(me, minion, SpellSlot::W);

				if (minion->IsValidTarget() && orbTarget != minion->NetworkID())
				{
					int delay = (int)((minion->Distance(me) / Q.Speed + Q.Delay) * 1000);
					auto hpPred = orbwalker->GetHealthPrediction(minion, delay);
					if (hpPred > 0 && hpPred <= Qdmg && (minion->IsSiegeMinion() || minion->IsSuperMinion()) && Qspellname == "YoneQ" && LastHitUseQ->Value)
					{
						if (CastSpell(_Q, Engine::WorldToScreen(minion->Position())));
						return;
					}

					if (hpPred > 0 && hpPred <= Qdmg && !orbwalker->CanAttack() && orbwalker->AfterAutoAttack() && Qspellname == "YoneQ" && LastHitUseQ->Value)
						if (CastSpell(_Q, Engine::WorldToScreen(minion->Position())));
					return;

					if (hpPred > 0 && hpPred <= Wdmg && !orbwalker->CanAttack() && orbwalker->AfterAutoAttack() && LastHitUseW->Value)
						if (CastSpell(_W, Engine::WorldToScreen(minion->Position())));
					return;
					//}
				}
				//if (Qdmg >= minion->Health() && minion->IsSiegeMinion())
				//{
				//	CastSpell(_Q, minion);
				//}
				//if (minion->Health() <= Wdmg && orbwalker->CanAttack())
				//{
				//	CastSpell(_W, minion);

				//}
			}
		}
	}
	float ranger;
	void Tick()
	{
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


	}
};