#pragma once

class Jinx : public ModuleManager
{
private:
public:
	Jinx()
	{
	}

	~Jinx()
	{
	}
	float QMANA = 0;
	float WMANA = 0;
	float EMANA = 0;
	float RMANA = 0;

	double lag = 0, WCastTime = 0, QCastTime = 0, DragonTime = 0, grabTime = 0;
	float DragonDmg = 0;

	PredictionInput W = PredictionInput({ 1500.f, 0.5f,60.f,3300.f, true, SkillshotType::SkillshotLine });
	PredictionInput E = PredictionInput({ 920.f, 0.9f, 100.f, 1750.f, false, SkillshotType::SkillshotCircle });
	PredictionInput E1 = PredictionInput({ 750.0f, 0.25f, 100.f, 1750.f, false, SkillshotType::SkillshotCircle });
	PredictionInput R = PredictionInput({ 3000.f, 0.5f, 140.f, 1500.f, false, SkillshotType::SkillshotLine });

	CheckBox* noti;
	CheckBox* semi;
	CheckBox* qRange;
	CheckBox* wRange;
	CheckBox* eRange;
	CheckBox* rRange;
	CheckBox* onlyRdy;

	CheckBox* autoQ;
	CheckBox* Qharras;
	CheckBox* QpokeOnMinions;

	CheckBox* autoW;
	CheckBox* Wharras;
	CheckBox* Wlast;

	CheckBox* autoE;
	CheckBox* comboE;
	CheckBox* AGC;
	CheckBox* telE;

	CheckBox* autoR;
	CheckBox* Rjungle;
	CheckBox* Rdragon;
	CheckBox* Rbaron;
	Slider* hitchanceR;
	KeyBind* useR;
	CheckBox* Rturrent;

	CheckBox* farmQout;
	CheckBox* farmQ;

	CheckBox* FarmSpells;
	void Init()
	{
		// Q = new Spell(SpellSlot.Q);
		// W = new Spell(SpellSlot.W, 1500f);
		// E = new Spell(SpellSlot.E, 920f);
		// R = new Spell(SpellSlot.R, 3000f);

		// W.SetSkillshot(0.6f, 60f, 3300f, true, SkillshotType.SkillshotLine);
		// E.SetSkillshot(1.2f, 100f, 1750f, false, SkillshotType.SkillshotCircle);
		// R.SetSkillshot(0.5f, 140f, 1500f, false, SkillshotType.SkillshotLine);
		auto menu = NewMenu::CreateMenu("Jinx", "Jinx");

		/*auto Draw = menu->AddMenu("Draw", "Draw");
		noti = Draw->AddCheckBox("noti", "Show notification", false);
		semi = Draw->AddCheckBox("semi", "Semi-manual R target", false);
		qRange = Draw->AddCheckBox("qRange", "Q range", false);
		wRange = Draw->AddCheckBox("wRange", "W range", false);
		eRange = Draw->AddCheckBox("eRange", "E range", false);
		rRange = Draw->AddCheckBox("rRange", "R range", false);
		onlyRdy = Draw->AddCheckBox("onlyRdy", "Draw only ready spells", true);*/

		auto QConfig = menu->AddMenu("QConfig", "Q Config");
		autoQ = QConfig->AddCheckBox("autoQ", "var Q", true);
		Qharras = QConfig->AddCheckBox("Qharras", "Harass Q", true);
		QpokeOnMinions = QConfig->AddCheckBox("QpokeOnMinions", "Poke Q on minion", true);

		auto WConfig = menu->AddMenu("WConfig", "W Config");
		autoW = WConfig->AddCheckBox("autoW", "var W", true);
		Wharras = WConfig->AddCheckBox("Wharras", "Harass W", true);
		Wlast = WConfig->AddCheckBox("Wlast", "Only W last target", true);

		auto EConfig = menu->AddMenu("EConfig", "E Config");
		autoE = EConfig->AddCheckBox("autoE", "var E on CC", true);
		comboE = EConfig->AddCheckBox("comboE", "var E in Combo BETA", true);
		AGC = EConfig->AddCheckBox("AGC", "AntiGapcloserE", true);
		telE = EConfig->AddCheckBox("telE", "var E teleport", true);

		auto RConfig = menu->AddMenu("RConfig", "R Config");
		autoR = RConfig->AddCheckBox("autoR", "var R", true);

		auto RJungle = RConfig->AddMenu("RJungle", "R Jungle stealer");
		Rjungle = RJungle->AddCheckBox("Rjungle", "R Jungle stealer", false);
		Rdragon = RJungle->AddCheckBox("Rdragon", "Dragon", true);
		Rbaron = RJungle->AddCheckBox("Rbaron", "Baron", true);

		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rjungle", "R Jungle stealer", true);
		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rdragon", "Dragon", true);
		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rbaron", "Baron", true);

		hitchanceR = RConfig->AddSlider("hitchanceR", "Hit Chance R", 5, 3, 8, 1);
		useR = RConfig->AddKeyBind("useR", "OneKeyToCast R", VK_KEY_T, false, false); //32 == space
		Rturrent = RConfig->AddCheckBox("Rturrent", "Don't R under turret", true);

		auto Farm = menu->AddMenu("Farm", "Farm");
		farmQout = Farm->AddCheckBox("farmQout", "Q farm out range AA", true);
		farmQ = Farm->AddCheckBox("farmQ", "Q LaneClear Q", true);

		FarmSpells = menu->AddCheckBox("FarmSpells", "Use Spells Farm", true);
		BeforeAttack();

		// Game.OnUpdate += Game_OnUpdate;
		// Orbwalking.BeforeAttack += BeforeAttack;
		// Obj_AI_Base.OnProcessSpellCast += Obj_AI_Base_OnProcessSpellCast;
		// AntiGapcloser.OnEnemyGapcloser += AntiGapcloser_OnEnemyGapcloser;
		// Drawing.OnDraw += Drawing_OnDraw;
	}
	float bonusRange() { return 665.f + global::LocalData->gameplayRadius + 25 * me->GetSpellBook()->GetSpellSlotByID(0)->Level(); }

	bool FishBoneActive() { return me->HasBuff("JinxQ"); }

	float GetRealPowPowRange(CObject* target)
	{
		return 590.f + global::LocalData->gameplayRadius + target->BoundingRadius();
	}

	float GetRealDistance(CObject* target)
	{
		return me->ServerPosition().Distance(prediction->GetPrediction(target, 0.05f).CastPosition()) + global::LocalData->gameplayRadius + target->BoundingRadius();
	}

	float GetRDamage(CObject* source, CObject* target)
	{
		int level = me->GetSpellBook()->GetSpellSlotByID(_R)->Level();
		if (level == 0 || !IsReady(_R))
		{
			return 0.0f;
		}
		float num = 0.0f;
		num = 250.0f + (level - 1) * 150.0f;
		float percent = 0.25f + (level - 1) * 0.5f;
		auto hp = target->MaxHealth() - target->Health();
		num += me->BonusAttackDamage() * 1.5f + percent * hp;
		return me->CalcPhysicalDamage(target, num);
	}

	bool FarmSpellskek()
	{

		return global::mode == ScriptMode::LaneClear
			&& me->ManaPercent() > 50 && FarmSpells->Value;
	}

	void BeforeAttack()
	{
		SetFunctionCallBack(BeforeAttackEvent, [&](CObject* actor) {
			if (!IsReady(0) || !this->autoQ->Value || !FishBoneActive() || actor == nullptr)
				return true;

			auto t = actor;

			if (t->IsValidTarget() && t->IsHero())
			{
				float realDistance = GetRealDistance(t) - 40;
				if (global::mode == ScriptMode::Combo && (realDistance < GetRealPowPowRange(t) || (me->Mana() < RMANA + 20 && me->GetAutoAttackDamage(t) * 3 < t->Health())))
					CastSpell(0);
				else if (global::mode == ScriptMode::Mixed && this->Qharras->Value && (realDistance > bonusRange() || realDistance < GetRealPowPowRange(t) || me->Mana() < RMANA + EMANA + WMANA + WMANA))
					CastSpell(0);
			}
			else if (!(global::mode == ScriptMode::Combo) || global::mode == ScriptMode::LaneClear)
			{
				auto minion = actor;
				if (global::mode == ScriptMode::LaneClear && minion->IsValidTarget() && minion->IsMinion() && FarmSpellskek())
				{
					auto minions = Engine::GetMinionsAround(300, 1, minion->Position());
					auto realDistance = GetRealDistance(minion);

					if (minions.size() > 1)
						return true;

					if (realDistance + 50 > GetRealPowPowRange(minion))
						return true;
				}
				CastSpell(0);
			}
			return true;
			});
	}


	void SetMana()
	{
		if (me->HealthPercent() < 20)
		{
			QMANA = 0;
			WMANA = 0;
			EMANA = 0;
			RMANA = 0;
			return;
		}

		QMANA = me->GetSpellBook()->GetSpellSlotByID(0)->ManaCost();
		WMANA = me->GetSpellBook()->GetSpellSlotByID(1)->ManaCost();
		EMANA = me->GetSpellBook()->GetSpellSlotByID(2)->ManaCost();

		if (!IsReady(3))
			RMANA = QMANA - me->GetSpellBook()->GetSpellSlotByID(3)->ManaCost();
		else
			RMANA = me->GetSpellBook()->GetSpellSlotByID(3)->ManaCost();
	}

	void LogicQ()
	{
		auto laneMinions = Engine::GetMinionsAround(1000, 1);
		if (global::mode == ScriptMode::LaneClear && !FishBoneActive() && !me->IsWindingUp() && orbwalker->GetTarget() == nullptr && orbwalker->CanAttack() && farmQout->Value && me->Mana() > RMANA + WMANA + EMANA + 10)
		{
			for (auto minion : Engine::GetMinionsAround(bonusRange() + 30, 1, me->Position()))
			{
				if (!me->IsInAutoAttackRange(minion) && GetRealPowPowRange(minion) < GetRealDistance(minion) && bonusRange() < GetRealDistance(minion))
				{
					auto hpPred = orbwalker->GetHealthPrediction(minion, 400, 70);
					if (hpPred < me->GetAutoAttackDamage(minion) * 1.1 && hpPred > 5)
					{
						orbwalker->SetForceTarget(minion);
						CastSpell(0);
						return;
					}
				}
			}
		}


		auto t = targetselector->GetTarget(bonusRange() + 60.f);
		if (t->IsValidTarget())
		{
			if (!FishBoneActive() && (!me->IsInAutoAttackRange(t) || Engine::GetEnemyCount(250.f, t->Position()) > 2) && orbwalker->GetTarget() == nullptr)
			{
				auto distance = GetRealDistance(t);
				if (global::mode == ScriptMode::Combo && (me->Mana() > RMANA + WMANA + 10 || me->GetAutoAttackDamage(t) * 3 > t->Health()))
					CastSpell(0);
				else if (global::mode == ScriptMode::Mixed && !me->IsWindingUp() && orbwalker->CanAttack() && Qharras->Value && !Engine::UnderTurret(me->Position()) && me->Mana() > RMANA + WMANA + EMANA + 20 && distance < bonusRange() + t->BoundingRadius() + global::LocalData->gameplayRadius)
					CastSpell(0);
			}
		}
		else if (!FishBoneActive() && global::mode == ScriptMode::Combo && me->Mana() > RMANA + WMANA + 20 && Engine::GetEnemyCount(2000, me->Position()) > 0)
			CastSpell(0);
		else if (FishBoneActive() && global::mode == ScriptMode::Combo && me->Mana() < RMANA + WMANA + 20)
			CastSpell(0);
		else if (FishBoneActive() && global::mode == ScriptMode::Combo && Engine::GetEnemyCount(2000, me->Position()) == 0)
			CastSpell(0);
		else if (FishBoneActive() && global::mode == ScriptMode::Mixed && !(global::mode == ScriptMode::LaneClear))
			CastSpell(0);

		if (global::mode == ScriptMode::LaneClear && orbwalker->CanMove(50))
		{
			auto tOrb = orbwalker->GetTarget();
			if (!FarmSpellskek() || !farmQ->Value)
			{
				if (FishBoneActive())
					CastSpell(0);
			}
			else if (!FishBoneActive())
			{
				if (tOrb != nullptr && tOrb->IsMinion())
				{
					auto minions = Engine::GetMinionsAround(300.f, 1, tOrb->Position());
					if (minions.size() > 1)
						CastSpell(0);
				}
				else if (laneMinions.size() > 2)
					CastSpell(0);
			}
			else if (tOrb != nullptr && tOrb->IsMinion())
			{
				auto minions = Engine::GetMinionsAround(300.f, 1, tOrb->Position());
				if (minions.size() < 2)
					CastSpell(0);
			}

		}
		else if (global::mode == ScriptMode::Mixed)
		{
			if (farmQout->Value && me->GetSpellBook()->GetSpellSlotByID(0)->Level() >= 3 && !FishBoneActive() && orbwalker->CanAttack())
			{
				for (auto x : laneMinions)
				{
					if (!me->IsInAutoAttackRange(x) && GetRealDistance(x) < bonusRange() + 150)
					{
						auto t2 = me->AttackCastDelay() * 1000.f + 20 + 100;
						auto t3 = t2 + 1000 * std::max(0.f, x->Distance(me) - global::LocalData->gameplayRadius) / global::LocalData->basicAttackMissileSpeed;
						float predicted_minion_health = orbwalker->GetHealthPrediction(x, t3);
						if (predicted_minion_health > 0)
						{
							if (predicted_minion_health - me->CalculateAutoAttackDamage(me, x) * 1.1 <= 0 || x->Health() < me->CalculateAutoAttackDamage(me, x))
							{
								CastSpell(0);
							}
						}
					}
				}
			}
		}

		/*if (QpokeOnMinions->Value && FishBoneActive() && global::mode== ScriptMode::Combo && me->Mana() > RMANA + EMANA + WMANA + WMANA)
		{
			auto tOrb = orbwalker->GetTarget();
			if (tOrb != nullptr)
			{
				auto t2 = targetselector->GetTarget(bonusRange() + 150.f);

				if (t2 != nullptr)
				{
					if (!me->IsInAutoAttackRange(t2))
					{
						CObject* bestMinion = nullptr;
						for (auto minion : laneMinions)
						{
							if (!me->IsInAutoAttackRange(minion))
								continue;

							float delay = me->AttackCastDelay() + 0.3f;
							auto t2Pred = prediction->GetPrediction(t2, delay).CastPosition();
							auto minionPred = prediction->GetPrediction(minion, delay).CastPosition();

							if (t2Pred.Distance(minionPred) < 150.f && t2->Distance(minion) < 150.f)
							{
								if (bestMinion != nullptr)
								{
									if (bestMinion->Distance(t2) > minion->Distance(t2))
										bestMinion = minion;
								}
								else
								{
									bestMinion = minion;
								}
							}
						}
						if (bestMinion != nullptr)
						{
							orbwalker->SetForceTarget(bestMinion);
							return;
						}
					}
				}
			}
			orbwalker->SetForceTarget(nullptr);
		}*/
	}

	void LogicW()
	{
		if (global::mode == ScriptMode::Combo && Wlast->Value)
		{
			auto enemy = orbwalker->LastTarget;
			if (enemy->IsValidTarget() && enemy->IsHero())
			{
				CastSpell(enemy, 1, W);
			}
			return;
		}

		auto t = targetselector->GetTarget(W.Range);

		if (t->IsValidTarget())
		{
			for (auto enemy : from(Engine::GetHerosAround(3000.0f, 1)) >> where([&](CObject* h) {return h->IsValidTarget(W.Range) && h->Distance(me) > bonusRange(); }) >> to_vector())
			{
				auto comboDmg = GetSpellDamage(me, enemy, SpellSlot::W);
				if (IsReady(_R) && me->Mana() > RMANA + WMANA + 20)
				{
					comboDmg += GetRDamage(me, enemy);
				}
				if (comboDmg > enemy->Health())
				{
					CastSpell(enemy, 1, W);
					WCastTime = Engine::GameGetTickCount();
					return;
				}
			}

			if (Engine::GetEnemyCount(bonusRange(), me->Position()) == 0)
			{
				if (global::mode == ScriptMode::Combo && me->Mana() > RMANA + WMANA + 10)
				{
					for (auto enemy : from(Engine::GetHerosAround(3000.0f, 1)) >> where([&](CObject* h) {return h->IsValidTarget(W.Range) && GetRealDistance(h) > bonusRange(); }) >> orderby([&](CObject* h) { return h->Health(); }) >> to_vector())
					{
						CastSpell(enemy, _W, W);
						WCastTime = Engine::GameGetTickCount();
					}

				}
				else if (global::mode == ScriptMode::Mixed && me->Mana() > RMANA + EMANA + WMANA + WMANA + 40 && Wharras->Value)
				{
					for (auto enemy : from(Engine::GetHerosAround(3000.0f, 1)) >> where([&](CObject* h) {return h->IsValidTarget(W.Range); }) >> to_vector())
					{
						CastSpell(enemy, _W, W);
						WCastTime = Engine::GameGetTickCount();
					}
				}
			}
			if (!(global::mode == ScriptMode::Combo) && me->Mana() > RMANA + WMANA && Engine::GetEnemyCount(GetRealPowPowRange(t), me->Position()) == 0)
			{
				for (auto enemy : from(Engine::GetHerosAround(3000.0f, 1)) >> where([&](CObject* h) {return h->IsValidTarget(W.Range) && !Engine::CanMove(h); }) >> to_vector())
				{
					CastSpell(_W, enemy);
					WCastTime = Engine::GameGetTickCount();
				}
			}
		}
	}

	void LogicE()
	{
		if (me->Mana() > RMANA + EMANA && autoE->Value && Engine::GameGetTickCount() - grabTime > 1)
		{
			for (auto actor : global::enemyheros)
			{
				auto enemy = (CObject*)actor.actor;
				if (enemy->IsValidTarget(E.Range + 50) && !Engine::CanMove(enemy))
				{
					CastSpell(2, enemy);
					return;
				}
			}

			if (telE->Value)
			{
				/*var trapPos = OktwCommon.GetTrapPos(E.Range);
				if (!trapPos.IsZero)
					E.Cast(trapPos);*/
			}

			if (global::mode == ScriptMode::Combo && me->IsMoving() && comboE->Value && me->Mana() > RMANA + EMANA + WMANA)
			{
				for (auto actor : global::enemyheros)
				{
					auto t = (CObject*)actor.actor;
					if (t->IsValidTarget(E.Range + 50))
					{
						auto pO = prediction->GetPrediction(t, E);
						if (t->IsValidTarget(E.Range) && pO.CastPosition().Distance(t->Position()) > 200.f)
						{
							if (pO.HitChance() >= HitChance::Low)
							{
								CastSpell(_E, Engine::WorldToScreen(pO.CastPosition()));
								return;
							}

							if (t->HasBuffOfType(BuffType::Slow))
								CastSpell(_E, Engine::WorldToScreen(pO.CastPosition()));
							if (prediction->IsMovingInSameDirection(me, t))
								CastSpell(_E, Engine::WorldToScreen(pO.CastPosition()));
						}
					}
				}
			}
		}
	}

	void LogicR()
	{
		if (Engine::UnderTurret(me->Position()) && Rturrent->Value)
			return;

		if (Engine::GameGetTickCount() - WCastTime > 0.9 && autoR->Value)
		{
			for (auto enemy : from(Engine::GetHerosAround(3000.0f, 1)) >> where([&](CObject* h) {return h->IsValidTarget(R.Range); }) >> to_vector())
			{
				//var predictedHealth = target.Health - OktwCommon.GetIncomingDamage(target);
				auto Rdmg = GetRDamage(me, enemy);
				if (Rdmg > enemy->Health() && GetRealDistance(enemy) > bonusRange() + 200)
				{
					if (GetRealDistance(enemy) > bonusRange() + 300 + enemy->BoundingRadius() && Engine::GetHerosAround(500, 2, enemy->Position()).size() == 0 && Engine::GetEnemyCount(400, me->Position()) == 0)
					{
						CastSpell(enemy, 3, R);
					}
					else if (Engine::GetEnemyCount(200, enemy->Position()) > 2)
					{
						CastSpell(enemy, 3, R);
					}
				}
			}


		}
	}

	float GetUltTravelTime(CObject* source, float speed, float delay, Vector3 targetpos)
	{
		float distance = source->Distance(targetpos);
		float missilespeed = speed;
		if (distance > 1350)
		{
			const float accelerationrate = 0.3f; //= (1500f - 1350f) / (2200 - speed), 1 unit = 0.3units/second
			float acceldifference = distance - 1350.f;
			if (acceldifference > 150.f) //it only accelerates 150 units
				acceldifference = 150.f;
			float difference = distance - 1500.f;
			missilespeed = (1350.f * speed + acceldifference * (speed + accelerationrate * acceldifference) + difference * 2200.f) / distance;
		}
		return (distance / missilespeed + delay);
	}


	void Draw()
	{
		/*	auto t = targetselector->GetTarget(W.Range);
			auto t2Pred = prediction->GetPrediction(t, W).CastPosition();
			auto W2S_buffer = Engine::WorldToScreenImVec2(t->Position());
			auto W2S_buffer2 = Engine::WorldToScreenImVec2(t2Pred);
			Renderer::GetInstance()->DrawLine(W2S_buffer, W2S_buffer2, D3DCOLOR_RGBA(0, 255, 0, 255), 1);*/
	}

	void Tick()
	{
		if (IsReady(3))
		{
			if (this->useR->Value)
			{
				auto t = targetselector->GetTarget(R.Range);
				if (t->IsValidTarget())
					CastSpell(t, 3, R);
			}
		}
		if (LagFree(0))
			SetMana();

		if (global::mode == ScriptMode::Combo || global::mode == ScriptMode::Mixed || global::mode == ScriptMode::LaneClear)
		{
			if (IsReady(2) && orbwalker->CanMove(orbwalker->ExtraWindUpTime->Value))
				LogicE();

			if (IsReady(0) && LagFree(2) && autoQ->Value)
				LogicQ();

			if (IsReady(1) && LagFree(3) && autoW->Value && orbwalker->CanMove(orbwalker->ExtraWindUpTime->Value))
				LogicW();

			if (IsReady(3) && LagFree(4))
				LogicR();
		}

	}
};