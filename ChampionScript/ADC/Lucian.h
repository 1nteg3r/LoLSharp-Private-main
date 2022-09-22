#pragma once
class Lucian : public ModuleManager
{
private:
public:
	CObject* targetR = nullptr;
	int moveorder = 0;
	bool passRdy = false;
	bool spellLock = false;
	float castR = Engine::GameGetTickCount();
	float lastDash = 0;

	float QMANA = 0;
	float WMANA = 0;
	float EMANA = 0;
	float RMANA = 0;

	CheckBox* onlyRdy;
	CheckBox* qRange;
	CheckBox* wRange;
	CheckBox* eRange;
	CheckBox* rRange;

	CheckBox* autoQ;
	CheckBox* harassQ;

	CheckBox* autoW;
	CheckBox* ignoreCol;
	CheckBox* wInAaRange;

	CheckBox* autoE;
	CheckBox* slowE;

	CheckBox* autoR;
	KeyBind* useR;

	CheckBox* farmQ;
	CheckBox* farmW;
	Lucian()
	{
	}

	~Lucian()
	{
	}

	PredictionInput Q = PredictionInput({ 575.f, 0.25f,100.f,FLT_MAX, true, SkillshotType::SkillshotLine });
	PredictionInput Q1 = PredictionInput({ 1000.f, 0.4f,100.f,1600.f, true, SkillshotType::SkillshotLine });
	PredictionInput W = PredictionInput({ 1100.f, 0.30f,110.f,1600.f, true, SkillshotType::SkillshotLine });
	PredictionInput E = PredictionInput({ 425.f });
	PredictionInput R = PredictionInput({ 1200.f, 0.1f,200.f,2800.f, true, SkillshotType::SkillshotLine });
	PredictionInput R1 = PredictionInput({ 1200.f, 0.1f,200.f,2800.f, false, SkillshotType::SkillshotLine });

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Lucian", "Lucian");

		auto Draw = menu->AddMenu("Draw", "Draw");
		auto QConfig = menu->AddMenu("QConfig", "QConfig");
		auto WConfig = menu->AddMenu("WConfig", "WConfig");
		auto EConfig = menu->AddMenu("EConfig", "EConfig");
		auto RConfig = menu->AddMenu("RConfig", "RConfig");
		auto Farm = menu->AddMenu("Farm", "Farm");

		onlyRdy = Draw->AddCheckBox("onlyRdy", "Draw only ready spells", true);
		qRange = Draw->AddCheckBox("qRange", "Q range", false);
		wRange = Draw->AddCheckBox("wRange", "W range", false);
		eRange = Draw->AddCheckBox("eRange", "E range", false);
		rRange = Draw->AddCheckBox("rRange", "R range", false);

		autoQ = QConfig->AddCheckBox("autoQ", "Auto Q", true);
		harassQ = QConfig->AddCheckBox("harassQ", "Use Q on minion", true);

		autoW = WConfig->AddCheckBox("autoW", "Auto W", true);
		ignoreCol = WConfig->AddCheckBox("ignoreCol", "Ignore collision", true);
		wInAaRange = WConfig->AddCheckBox("wInAaRange", "Cast only in AA range", false);

		autoE = EConfig->AddCheckBox("autoE", "Auto E", true);
		//slowE = EConfig->AddCheckBox("slowE", "Auto SlowBuff E", true);

		autoR = RConfig->AddCheckBox("autoR", "Auto R", true);
		useR = RConfig->AddKeyBind("useR", "Semi-manual cast R key", VK_KEY_T, false, false);

		farmQ = Farm->AddCheckBox("farmQ", "LaneClear Q", true);
		farmW = Farm->AddCheckBox("farmW", "LaneClear W", true);

		E.Slot = SpellSlot::E;
		dashcast = new DashCast();
		dashcast->Init2(menu, E);
		dashcast->Add();

		// Game.OnUpdate += Game_OnGameUpdate;
		// Drawing.OnDraw += Drawing_OnDraw;
		// Orbwalking.AfterAttack += afterAttack;
		// Obj_AI_Base.OnProcessSpellCast += Obj_AI_Base_OnProcessSpellCast;
		// Spellbook.OnCastSpell +=Spellbook_OnCastSpell;
		SetFunctionCallBack(AfterAttackEvent, [&](CObject* actor) {

			if (LagFree(0) && passRdy)
				passRdy = false;

			return true;
			});

		SetFunctionCallBack(CastSpellEvent, [&](CObject* actor) {
			passRdy = true;

			return true;
			});

		SetFunctionCallBack(BeforeAttackEvent, [&](CObject* actor) {

			if (actor->IsHero())
			{
				if (me->Distance(actor) > 450 && me->IsFacing(actor->ServerPosition()) && !actor->IsFacing(me->ServerPosition()))
				{
					CastSpell(0, actor, true);
				}
			}

			return true;
			});
	}
	void Draw()
	{
		/*auto t1 = targetselector->GetTarget(Q1.Range);
		auto prepos = prediction->GetPrediction(t1, Q1.Delay);
		if ((int)prepos.HitChance() < 5)
			return;
		auto distance = me->Position().Distance(prepos.CastPosition());
		auto minions = Engine::GetMinionsAround(Q.Range, 1);

		for (auto minion : minions)
		{
			if (minion->IsValidTarget(Q.Range))
			{
				auto W2S_buffer = Engine::WorldToScreenImVec2(me->Position());
				auto W2S_buffer2 = Engine::WorldToScreenImVec2(me->Position().Extended(minion->Position(), Q1.Range));
				if (prepos.CastPosition().Distance(me->Position().Extended(minion->Position(), distance)) < 50)
				{
					Renderer::GetInstance()->DrawLine(W2S_buffer, W2S_buffer2, D3DCOLOR_RGBA(255, 0, 0, 255), 1);
				}
				else
				{
					Renderer::GetInstance()->DrawLine(W2S_buffer, W2S_buffer2, D3DCOLOR_RGBA(0, 255, 0, 255), 1);
				}
			}
		}
*/
/*auto dashPos = dashcast->CastDash();
auto W2S_buffer = Engine::WorldToScreenImVec2(me->Position());
auto W2S_buffer2 = Engine::WorldToScreenImVec2(dashPos);
Renderer::GetInstance()->DrawLine(W2S_buffer, W2S_buffer2, D3DCOLOR_RGBA(0, 255, 0, 255), 1);*/
	}
	bool SpellLock()
	{
		return me->HasBuff(FNV("lucianpassivebuff"));
	}

	bool LucianCastingR()
	{
		if (me->HasBuff(FNV("lucianr")))
			castR = Engine::GameGetTickCount();

		return me->HasBuff(FNV("lucianr"));
	}

	/*void UpdatePassive()
	{
		auto activespell = me->GetSpellBook()->GetActiveSpellEntry();
		if (activespell)
		{
			if (activespell->IsCastingSpell())
			{
				passRdy = true;
			}
			else if (activespell->IsAutoAttack())
				passRdy = false;
		}
	}*/

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
			RMANA = QMANA - me->ResourceRegen() * me->GetSpellBook()->GetSpellSlotByID(0)->CoolDown();
		else
			RMANA = me->GetSpellBook()->GetSpellSlotByID(3)->ManaCost();
	}
	double AaDamage(CObject* target)
	{
		if (me->Level() > 12)
			return me->CalculateDamage(target, me->TotalAttackDamage()) * 1.3;
		else if (me->Level() > 6)
			return me->CalculateDamage(target, me->TotalAttackDamage()) * 1.4;
		else if (me->Level() > 0)
			return me->CalculateDamage(target, me->TotalAttackDamage()) * 1.5;
		return 0;
	}

	void LogicQ()
	{
		if (me->IsDashing() || Engine::GameTimeTickCount() - lastDash < 400)
			return;

		auto t = targetselector->GetTarget(Q.Range);
		auto t1 = targetselector->GetTarget(Q1.Range);


		if (me->IsInAutoAttackRange(t) && passRdy)
			return;

		if (t->IsValidTarget(Q.Range) && !passRdy)
		{
			if (GetSpellDamage(me, t, SpellSlot::Q, false, true) + AaDamage(t) > t->Health())
			{
				CastSpell(_Q, t, true);
			}
			else if (global::mode == ScriptMode::Combo && me->Mana() > RMANA + QMANA)
			{
				if (orbwalker->CanAttack() && !passRdy)
				{
					if (CastSpell(0, t))
					{
						return;
					}
				}
				else if (!orbwalker->CanAttack() && orbwalker->CanMove(orbwalker->ExtraWindUpTime->Value))
				{
					if (CastSpell(0, t))
					{
						return;
					}
				}
				else if (orbwalker->AfterAutoAttack())
				{
					if (CastSpell(0, t))
					{
						return;
					}
				}
			}
			else if (global::mode == ScriptMode::Mixed && me->Mana() > RMANA + QMANA + EMANA + WMANA)
			{
				if (!orbwalker->CanAttack() || orbwalker->CanMove(orbwalker->ExtraWindUpTime->Value))
				{
					if (CastSpell(0, t))
					{
						return;
					}
				}
				CastSpell(0, t);
			}
		}
		else if (harassQ->Value && t1->IsValidTarget(Q1.Range) && me->ServerPosition().Distance(t1->ServerPosition()) > Q.Range + 50.f)
		{
			if (global::mode == ScriptMode::Combo && me->Mana() < RMANA + QMANA)
				return;
			if (global::mode == ScriptMode::Mixed && me->Mana() < RMANA + QMANA + EMANA + WMANA)
				return;
			if (!orbwalker->CanHarras())
				return;

			auto t1 = targetselector->GetTarget(Q1.Range);
			auto prepos = prediction->GetPrediction(t1, Q1.Delay);
			if (prepos.HitChance() > HitChance::Low && prepos.HitChance() <= HitChance::VeryHigh)
			{
				auto distance = me->Position().Distance(prepos.CastPosition());
				auto minions = Engine::GetMinionsAround(Q.Range, 1);

				for (auto minion : minions)
				{
					if (minion->IsValidTarget(Q.Range))
					{
						if (prepos.CastPosition().Distance(me->Position().Extended(minion->Position(), distance)) < 25)
						{
							if (CastSpell(0, minion))
							{
								return;
							}
						}
					}
				}
			}
		}
	}

	void LogicW()
	{
		if (me->IsDashing() || Engine::GameTimeTickCount() - lastDash < 400)
			return;

		auto t = targetselector->GetTarget(W.Range);
		if (t->IsValidTarget())
		{
			if (ignoreCol->Value && me->IsInAutoAttackRange(t))
				W.Collision = false;
			else
				W.Collision = true;

			auto qDmg = GetSpellDamage(me, t, SpellSlot::Q, false);
			auto wDmg = GetSpellDamage(me, t, SpellSlot::W, false);

			if (me->IsInAutoAttackRange(t))
			{
				qDmg += (float)AaDamage(t);
				wDmg += (float)AaDamage(t);
			}

			if (wDmg > t->Health())
			{
				CastSpell(t, 1, W, false, HitChance::Low);
			}
			else if (wDmg + qDmg > t->Health() && IsReady(0) && me->Mana() > RMANA + WMANA + QMANA)
			{
				CastSpell(t, 1, W, false, HitChance::Low);
			}

			auto orbT = orbwalker->GetTarget();
			if (orbT == nullptr)
			{
				if (wInAaRange->Value)
				{
					return;
				}
			}
			else if (orbT->IsValidTarget())
			{
				t = orbT;
			}


			if (global::mode == ScriptMode::Combo && me->Mana() > RMANA + WMANA + EMANA + QMANA)
			{
				if (me->IsInAutoAttackRange(t))
				{
					if (orbwalker->CanMove(orbwalker->ExtraWindUpTime->Value))
					{
						if (CastSpell(t, 1, W, false, HitChance::Low))
						{
							return;
						}
					}
				}
				else
				{
					if (CastSpell(t, 1, W, false, HitChance::Low))
					{
						return;
					}
				}
			}
			else if (global::mode == ScriptMode::Mixed && !Engine::UnderTurret(me->Position()) && me->Mana() > me->MaxMana() * 0.8 && me->Mana() > RMANA + WMANA + EMANA + QMANA + WMANA)
			{
				CastSpell(t, 1, W);
			}
			else if ((global::mode == ScriptMode::Combo || global::mode == ScriptMode::Mixed) && me->Mana() > RMANA + WMANA + EMANA)
			{
				for (auto actor : global::enemyheros)
				{
					auto enemy = (CObject*)actor.actor;
					if (enemy->IsValidTarget(W.Range) && !enemy->CanMove())
					{
						CastSpell(t, 1, W, false, HitChance::Low);
					}
				}
			}
		}
	}

	void LogicE()
	{
		if (me->Mana() < RMANA + EMANA || !autoE->Value)
			return;

		if (!(global::mode == ScriptMode::Combo) || passRdy || SpellLock())
			return;

		auto dashPos = dashcast->CastDash();
		if (dashPos.IsValid())
		{
			auto orbT = targetselector->GetTarget(me->GetSelfAttackRange());
			if (orbT != nullptr)
			{
				if (orbwalker->AfterAutoAttack() || (!orbwalker->CanAttack() && orbwalker->CanMove(orbwalker->ExtraWindUpTime->Value)))
				{
					if (orbT->Distance(me) > 270.f && orbT->Distance(me) > 400.f)
					{
						CastSpell(2, Engine::WorldToScreen(me->Position().Extended(dashPos, 150.f)));

						lastDash = Engine::GameTimeTickCount();
					}
					else
					{
						CastSpell(2, Engine::WorldToScreen(dashPos));

						lastDash = Engine::GameTimeTickCount();
					}

				}
			}
			else
			{
				CastSpell(2, Engine::WorldToScreen(dashPos));
				lastDash = Engine::GameTimeTickCount();
			}
		}

	}

	void LogicR()
	{
		auto t = targetselector->GetTarget(R.Range);

		if (t->IsValidTarget(R.Range) && (!me->IsInAutoAttackRange(t) || !IsReady(0) && !IsReady(1) && !IsReady(2)))
		{
			auto basicrDmg = GetSpellDamage(me, t, SpellSlot::R, false);
			auto rDmg = basicrDmg * 20;

			auto tDis = me->Distance(t);
			if (rDmg > t->Health() && me->IsInAutoAttackRange(t) && Engine::GetMinionsAround(300, 1, t->Position()).size() < 3)
			{
				CastSpell(3, t);
				targetR = t;
			}
			else if (rDmg /** 0.8*/ > t->Health() && tDis < 700 && !IsReady(0))
			{
				CastSpell(t, 3, R);
				targetR = t;
			}
			else if (rDmg /** 0.7*/ > t->Health() && tDis < 800)
			{
				CastSpell(t, 3, R);
				targetR = t;
			}
			else if (rDmg /** 0.6*/ > t->Health() && tDis < 900)
			{
				CastSpell(t, 3, R);
				targetR = t;
			}
			else if (rDmg /** 0.5*/ > t->Health() && tDis < 1000)
			{
				CastSpell(t, 3, R);
				targetR = t;
			}
			else if (rDmg /** 0.4*/ > t->Health() && tDis < 1100)
			{
				CastSpell(t, 3, R);
				targetR = t;
			}
			else if (rDmg /** 0.3*/ > t->Health() && tDis < 1200)
			{
				CastSpell(t, 3, R);
				targetR = t;
			}
		}
	}
	void farm()
	{
		if (global::mode == ScriptMode::LaneClear && me->Mana() > RMANA + QMANA)
		{
			auto mobs = Engine::GetJunglesAround(Q.Range, 1);
			if (mobs.size() > 0)
			{
				auto mob = mobs.front();
				if (IsReady(_Q))
				{
					if (CastSpell(_Q, mob))
					{
						return;
					}
				}

				if (IsReady(_W))
				{
					if (CastSpell(_W, mob))
					{
						return;
					}
				}
			}

			//if (FarmSpells)
			{

				if (IsReady(_Q) && farmQ->Value)
				{
					auto minions = Engine::GetMinionsAround(Q1.Range, 1, me->ServerPosition());
					for (auto minion : minions)
					{
						auto poutput = prediction->GetPrediction(minion, Q1);
						auto col = poutput.CollisionObjects;

						if (poutput.CollisionObjects.size() > 2)
						{
							auto minionQ = col.front();
							if (minionQ->IsValidTarget(Q.Range))
							{
								if (CastSpell(_Q, minion))
								{
									return;
								}
							}
						}
					}
				}
				if (IsReady(_W) && farmW->Value)
				{
					/*auto minions = Engine::GetMinionsAround(Q1.Range, 1, me->ServerPosition());
					var Wfarm = W.GetCircularFarmLocation(minions, 150);
					if (Wfarm.MinionsHit > 3)
						W.Cast(Wfarm.Position);*/
				}
			}
		}
	}
	void Tick()
	{
		spellLock = SpellLock();
		if (useR->Value)
		{
			if (IsReady(3) && Engine::GameGetTickCount() - castR > 5)
			{
				auto t = targetselector->GetTarget(R.Range);
				if (t->IsValidTarget())
				{
					CastSpell(t, 3, R);
					targetR = t;
				}
			}
		}

		if (LagFree(0))
		{
			SetMana();
			//UpdatePassive();
			/*if (SpellLock())
			{
				passRdy = true;
			}*/
			LucianCastingR();
		}


		if (IsReady(1) && LagFree(1) && !passRdy && !spellLock && autoW->Value)
		{
			LogicW();
		}

		if (IsReady(2) && LagFree(2) && !LucianCastingR() && !passRdy && !spellLock)
		{
			LogicE();
		}

		if (IsReady(0) && LagFree(3))
		{
			LogicQ();
			//UpdatePassive();
		}

		if (LagFree(4))
		{
			if (IsReady(3) && Engine::GameGetTickCount() - castR > 5 && autoR->Value)
				LogicR();

			if (!passRdy && !spellLock)
				farm();
		}

	}
};