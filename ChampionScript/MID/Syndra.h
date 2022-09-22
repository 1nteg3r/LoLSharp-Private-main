#pragma once

class Syndra : public ModuleManager
{
public:
	CheckBox* notif;
	CheckBox* noti;
	CheckBox* showcd;
	CheckBox* onlyRdy;
	CheckBox* qRange;
	CheckBox* wRange;
	CheckBox* eRange;
	CheckBox* rRange;
	CheckBox* rRangeMini;
	CheckBox* semi;

	CheckBox* autoQ;
	CheckBox* harassQ;

	CheckBox* autoW;
	CheckBox* harassE;

	CheckBox* autoE;
	CheckBox* autoR;

	CheckBox* EInterrupter;
	CheckBox* harassW;
	Slider* QHarassMana;

	KeyBind* useQE;

	CheckBox* Rcombo;
	CheckBox* farmQout;
	CheckBox* farmQ;
	CheckBox* farmW;
	CheckBox* jungleE;
	CheckBox* jungleW;
	CheckBox* jungleQ;

	CheckBox* FarmSpells;
	int LastEQCast = Engine::TickCount();
	Vector3 SyndraQEnd = Vector3::Zero;

	std::vector<uint32_t> BallsList;
	bool EQcastNow = false;
	float QMANA = 0;
	float WMANA = 0;
	float EMANA = 0;
	float RMANA = 0;

	PredictionInput Q = PredictionInput({ 800, 0.6f,125.f,FLT_MAX, false, SkillshotType::SkillshotCircle });
	PredictionInput W = PredictionInput({ 950.f, 0.25f,140.f,1600.f, false, SkillshotType::SkillshotCircle });
	PredictionInput E = PredictionInput({ 700, 0.25f,100,2500, false, SkillshotType::SkillshotLine });
	PredictionInput EQ = PredictionInput({ Q.Range + 500, 0.6f,100.f,2500, false, SkillshotType::SkillshotLine });
	PredictionInput Eany = PredictionInput({ Q.Range + 500, 0.30f,50,2500, false, SkillshotType::SkillshotLine });
	PredictionInput R = PredictionInput({ 675 });

	Syndra()
	{
	}

	~Syndra()
	{
	}

	void Init()
	{

		auto menu = NewMenu::CreateMenu("Syndra", "Syndra");

		auto Draw = menu->AddMenu("Draw", "Draw");
		auto QConfig = menu->AddMenu("QConfig", "QConfig");
		auto WConfig = menu->AddMenu("WConfig", "WConfig");
		auto EConfig = menu->AddMenu("EConfig", "EConfig");
		auto RConfig = menu->AddMenu("RConfig", "RConfig");
		auto Farm = menu->AddMenu("Farm", "Farm");

		qRange = Draw->AddCheckBox("qRange", "Q range", false);
		wRange = Draw->AddCheckBox("wRange", "W range", false);
		eRange = Draw->AddCheckBox("eRange", "E range", false);
		rRange = Draw->AddCheckBox("rRange", "R range", false);
		onlyRdy = Draw->AddCheckBox("onlyRdy", "Draw when skill rdy", true);

		autoQ = QConfig->AddCheckBox("autoQ", "Auto Q", true);
		harassQ = QConfig->AddCheckBox("harassQ", "Harass Q", true);
		QHarassMana = QConfig->AddSlider("QHarassMana", "Harass Mana", 30, 0, 100, 0);

		autoW = WConfig->AddCheckBox("autoW", "Auto W", true);
		harassW = WConfig->AddCheckBox("harassW", "Harass W", true);

		autoE = EConfig->AddCheckBox("autoE", "Auto Q + E combo, ks", true);
		harassE = EConfig->AddCheckBox("harassE", "Harass Q + E", false);
		EInterrupter = EConfig->AddCheckBox("EInterrupter", "Auto Q + E Interrupter", true);
		useQE = EConfig->AddKeyBind("useQE", "Semi-manual Q + E near mouse key", VK_KEY_T, false, false); //32 == space

		// foreach (var enemy in HeroManager.Enemies)
		//     HeroMenu.SubMenu("E Config").SubMenu("Auto Q + E Gapcloser").AddItem(new MenuItem("Egapcloser" + enemy.ChampionName, enemy.ChampionName, true);

		// foreach (var enemy in HeroManager.Enemies)
		//     HeroMenu.SubMenu("E Config").SubMenu("Use Q + E on").AddItem(new MenuItem("Eon" + enemy.ChampionName, enemy.ChampionName, true);

		autoR = RConfig->AddCheckBox("autoR", "Auto R KS", true);
		Rcombo = RConfig->AddCheckBox("Rcombo", "Extra combo dmg calculation", true);

		// foreach (var enemy in HeroManager.Enemies)
		//     HeroMenu.SubMenu("R Config").SubMenu("Use on").AddItem(new MenuItem("Rmode" + enemy.ChampionName, enemy.ChampionName, true).SetValue(new StringList(new[] { "KS ", "Always ", "Never " }, 0)));

		farmQout = Farm->AddCheckBox("farmQout", "Last hit Q minion out range AA", true);
		farmQ = Farm->AddCheckBox("farmQ", "Lane clear Q", true);
		farmW = Farm->AddCheckBox("farmW", "Lane clear W", true);

		jungleQ = Farm->AddCheckBox("jungleQ", "Jungle clear Q", true);
		jungleW = Farm->AddCheckBox("jungleW", "Jungle clear W", true);

		FarmSpells = menu->AddCheckBox("FarmSpells", "Use Spells Farm", true);

		// Game.OnUpdate += Game_OnGameUpdate;
		// GameObject.OnCreate += Obj_AI_Base_OnCreate;
		// Drawing.OnDraw += Drawing_OnDraw;
		// Obj_AI_Base.OnProcessSpellCast += Obj_AI_Base_OnProcessSpellCast;
		// Interrupter2.OnInterruptableTarget += Interrupter2_OnInterruptableTarget;
		// AntiGapcloser.OnEnemyGapcloser += AntiGapcloser_OnEnemyGapcloser;
	}
	void Draw()
	{
		for (auto actora : BallsList)
		{
			CObject* actor = (CObject*)actora;

			XPolygon::DrawCircle(actor->Position(), Q.Radius, ImVec4(255, 0, 255, 255), 2.0f);
			auto w2s = Engine::WorldToScreenImVec2(actor->Position());
			Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, w2s, 15, D3DCOLOR_RGBA(0, 255, 0, 255), true, false, "%.f", actor->Mana());
		}
	}

	void BallCleaner()
	{
		BallsList.erase(
			std::remove_if(BallsList.begin(), BallsList.end(),
				[](uint32_t  o) {CObject* actor = (CObject*)o;
		return fnv::hash_runtime(actor->Name().c_str()) != FNV("Seed") || round(actor->Mana()) <= 19; }),
			BallsList.end());
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

		QMANA = me->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(0)->Level());
		WMANA = me->GetSpellBook()->GetSpellSlotByID(1)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(1)->Level());
		EMANA = me->GetSpellBook()->GetSpellSlotByID(2)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(2)->Level());

		if (!IsReady(3))
			RMANA = QMANA - me->ResourceRegen() * me->GetSpellBook()->GetSpellSlotByID(0)->CoolDown();
		else
			RMANA = me->GetSpellBook()->GetSpellSlotByID(3)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(3)->Level());
	}

	void CastQE(CObject* target)
	{
		SkillshotType CoreType2 = SkillshotType::SkillshotLine;

		auto predInput2 = PredictionInput();
		predInput2.Aoe = false,
			predInput2.Collision = EQ.Collision,
			predInput2.Speed = EQ.Speed,
			predInput2.Delay = EQ.Delay,
			predInput2.Range = EQ.Range,
			predInput2.From(me->ServerPosition()),
			predInput2.Radius = EQ.Radius,
			predInput2.Unit = target,
			predInput2.Type = CoreType2;

		auto poutput2 = prediction->GetPrediction(predInput2);

		/*if (OktwCommon.CollisionYasuo(Player.ServerPosition, poutput2.CastPosition))
			return;*/

		Vector3 castQpos = poutput2.CastPosition();

		if (me->Position().Distance(castQpos) > Q.Range)
			castQpos = me->Position().Extended(castQpos, Q.Range);

		//if (MainMenu.Item("EHitChance", true).GetValue<StringList>().SelectedIndex == 0)
		//{
		if (poutput2.HitChance() >= HitChance::VeryHigh)
		{
			EQcastNow = true;
			CastSpell(_Q, Engine::WorldToScreen(castQpos));
			SyndraQEnd = castQpos;
		}
		//}

		/*else if (MainMenu.Item("EHitChance", true).GetValue<StringList>().SelectedIndex == 1)
		{
			if (poutput2.Hitchance >= HitChance.High)
			{
				EQcastNow = true;
				Q.Cast(castQpos);
			}

		}
		else if (MainMenu.Item("EHitChance", true).GetValue<StringList>().SelectedIndex == 2)
		{
			if (poutput2.Hitchance >= HitChance.Medium)
			{
				EQcastNow = true;
				Q.Cast(castQpos);
			}
		}*/
	}

	void TryBallE(CObject* t)
	{
		if (IsReady(_Q))
		{
			CastQE(t);
		}
		if (!EQcastNow)
		{
			auto ePred = prediction->GetPrediction(t, Eany);
			if (ePred.HitChance() >= HitChance::VeryHigh)
			{
				auto playerToCP = me->Position().Distance(ePred.CastPosition());
				for (auto actora : BallsList)
				{
					CObject* ball = (CObject*)actora;
					if (me->Distance(ball) < E.Range)
					{
						auto ballFinalPos = me->ServerPosition().Extended(ball->Position(), playerToCP);
						if (ballFinalPos.Distance(ePred.CastPosition()) < 50)
						{
							CastSpell(_E, Engine::WorldToScreen(ball->Position()));
							LastEQCast = Engine::TickCount();
						}
					}
				}
			}
		}
	}

	void LogicE()
	{
		if (useQE->Value)
		{
			auto mouseTarget = Engine::GetHerosAround(E.Range, 1);
			if (mouseTarget.size() > 1)
			{
				sort(mouseTarget.begin(), mouseTarget.end(), [&](CObject* t, CObject* t1) {
					return t->Position().Distance(Engine::GetMouseWorldPosition()) < t1->Position().Distance(Engine::GetMouseWorldPosition());
					});
			}

			if (mouseTarget.size() > 0)
			{
				TryBallE(mouseTarget[0]);
				return;
			}
		}

		auto t = targetselector->GetTarget(Eany.Range);
		if (t->IsValidTarget())
		{
			if (GetSpellDamage(me, t, SpellSlot::E, false, true) + GetSpellDamage(me, t, SpellSlot::Q, false, true) > t->Health())
				TryBallE(t);
			if (global::mode== ScriptMode::Combo && me->Mana() > RMANA + EMANA + QMANA)
				TryBallE(t);
			if (global::mode== ScriptMode::Mixed && me->Mana() > RMANA + EMANA + QMANA + WMANA && harassE->Value)
				TryBallE(t);
		}
	}

	void LogicQ()
	{
		auto t = targetselector->GetTarget(Q.Range);
		if (t->IsValidTarget())
		{
			if (global::mode== ScriptMode::Combo && me->Mana() > RMANA + QMANA + EMANA && !IsReady(_E))
				CastSpell(t, _Q, Q);
			else if (global::mode== ScriptMode::Mixed && harassQ->Value && me->ManaPercent() > QHarassMana->Value && orbwalker->CanHarras())
				CastSpell(t, _Q, Q);
			else if (GetSpellDamage(me, t, SpellSlot::Q, false, true) > t->Health())
				CastSpell(t, _Q, Q);
			else if (me->Mana() > RMANA + QMANA)
			{
				for (auto enemy : Engine::GetHerosAround(Q.Range, 1))
				{
					if (!Engine::CanMove(enemy))
						CastSpell(t, _Q, Q);
				}
			}
		}

		if (me->IsWindingUp())
			return;

		if (!(global::mode == ScriptMode::None) && !(global::mode== ScriptMode::Combo))
		{
			auto allMinions = Engine::GetMinionsAround(Q.Range, 1, me->ServerPosition());

			if (farmQout->Value && me->Mana() > RMANA + QMANA + EMANA + WMANA)
			{
				for (auto minion : allMinions)
				{
					if (minion->IsValidTarget(Q.Range) && (!me->IsInAutoAttackRange(minion) || (!Engine::UnderTurret(minion->Position()) && Engine::UnderAllyTurret(minion->Position()))))
					{
						auto hpPred = orbwalker->GetHealthPrediction(minion, 600);
						if (hpPred < GetSpellDamage(me, minion, SpellSlot::Q, false, true) && hpPred > minion->Health() - hpPred * 2)
						{
							CastSpell(minion, _Q, Q);
							return;
						}
					}
				}
			}
			/*if (FarmSpells && farmQ->Value)
			{
				auto farmPos = Q.GetCircularFarmLocation(allMinions, Q.Width);
				if (farmPos.MinionsHit >= FarmMinions)
					Q.Cast(farmPos.Position);
			}*/
		}
	}

	void CatchW(CObject* t, bool onlyMinin = false)
	{
		if (Engine::TickCount() - W.LastCastAttemptT < 150 || Engine::TickCount() - LastEQCast < 500 || EQcastNow)
			return;

		float catchRange = 915;
		CObject* obj = nullptr;
		if (BallsList.size() > 0 && !onlyMinin)
		{
			for (auto actora : BallsList)
			{
				CObject* ball = (CObject*)actora;
				if (me->Distance(ball) < catchRange)
					obj = ball;
			}
		}

		if (obj == nullptr)
		{
			auto TempWCatch = Engine::GetMinionsAround(catchRange, 1);

			if (TempWCatch.size() > 0)
				obj = TempWCatch[0];
		}

		if (obj != nullptr)
		{
			for (auto minion : Engine::GetMinionsAround(catchRange, 1))
			{
				if (t->Distance(minion) < t->Distance(obj))
					obj = minion;
			}
			CastSpell(_W, Engine::WorldToScreen(obj->Position()));
		}
	}

	void LogicW()
	{
		if (me->GetSpellBook()->GetSpellSlotByID(1)->ToggleState() == CSpellSlot::SpellToggleState::NotToggled)
		{
			auto t = targetselector->GetTarget(W.Range - 150);
			if (t->IsValidTarget())
			{
				if (global::mode== ScriptMode::Combo && me->Mana() > RMANA + QMANA + WMANA)
					CatchW(t);
				else if (global::mode== ScriptMode::Mixed && harassW->Value
					&& me->ManaPercent() > QHarassMana->Value && orbwalker->CanHarras())
				{
					CatchW(t);
				}
				else if (GetSpellDamage(me, t, SpellSlot::W, false, true) > t->Health())
					CatchW(t);
				else if (me->Mana() > RMANA + WMANA)
				{
					for (auto enemy : Engine::GetHerosAround(W.Range, 1))
					{
						if (!Engine::CanMove(enemy))
							CatchW(t);
					}
				}
			}
			else if (global::mode== ScriptMode::LaneClear && !IsReady(_Q) && FarmSpells->Value && farmW->Value)
			{
				auto allMinions = Engine::GetMinionsAround(W.Range, 1);
				if (allMinions.size() > 0)
					CatchW(allMinions[0]);

				/*auto farmPos = W.GetCircularFarmLocation(allMinions, W.Width);

				if (farmPos.MinionsHit >= FarmMinions)
					CatchW(allMinions.FirstOrDefault());*/
			}
		}
		else
		{
			auto t = targetselector->GetTarget(W.Range);
			if (t->IsValidTarget())
			{
				CastSpell(t, _W, W);
			}
			else if (FarmSpells->Value && farmW->Value)
			{
				auto allMinions = Engine::GetMinionsAround(W.Range, 1);
				if (allMinions.size() > 0)
					CatchW(allMinions[0]);
				/*var allMinions = Cache.GetMinions(Player.ServerPosition, W.Range);
				var farmPos = W.GetCircularFarmLocation(allMinions, W.Width);

				if (farmPos.MinionsHit > 1)
					W.Cast(farmPos.Position);*/
			}
		}
	}

	void LogicR()
	{
		R.Range = me->GetSpellBook()->GetSpellSlotByID(_R)->Level() == 3 ? 750 : 675;

		for (auto enemy : Engine::GetHerosAround(R.Range, 1))
		{

			auto comboDMG = GetSpellDamage(me, enemy, SpellSlot::Q, false, true);
			//comboDMG += GetSpellDamage(me, enemy, SpellSlot::R, false, true) * (me->GetSpellBook()->GetSpellSlotByID(_R)->Ammo() - 3);
			if (Rcombo->Value)
			{
				if (IsReady(_Q) && enemy->IsValidTarget(R.Range))
					comboDMG += GetSpellDamage(me, enemy, SpellSlot::Q, false, true);

				if (IsReady(_E))
					comboDMG += GetSpellDamage(me, enemy, SpellSlot::E, false, true);

				if (IsReady(_W))
					comboDMG += GetSpellDamage(me, enemy, SpellSlot::W, false, true);
			}

			if (enemy->Health() < comboDMG)
			{
				CastSpell(_R, enemy);
			}
		}
	}

	void Tick()
	{
		if (!IsReady(_E))
		{
			EQcastNow = false;
			SyndraQEnd = Vector3::Zero;
		}
		if (me->GetSpellBook()->GetCastSlot() == _Q && SyndraQEnd.IsValid() && EQcastNow && IsReady(_E))
		{
			auto customeDelay = Q.Delay - (E.Delay + (me->Position().Distance(SyndraQEnd) / E.Speed));
			_DelayAction->Add((int)(customeDelay * 1000), [=]() {
				CastSpell(_E, Engine::WorldToScreen(SyndraQEnd));
				LastEQCast = Engine::TickCount();
				});
		}


		SetMana();
		BallCleaner();



		if (global::mode== ScriptMode::Combo || global::mode== ScriptMode::Mixed || global::mode== ScriptMode::LaneClear)
		{
			if (IsReady(_E) && autoE->Value)
				LogicE();

			if (IsReady(_Q) && autoQ->Value)
				LogicQ();

			if (IsReady(_W) && autoW->Value)
				LogicW();

			if (IsReady(_R) && autoR->Value)
				LogicR();
		}
	}
};