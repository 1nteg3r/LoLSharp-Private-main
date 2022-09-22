#pragma once


class Xerath : public ModuleManager
{
public:
	CheckBox* noti;
	CheckBox* autoQ;
	CheckBox* harassQ;
	CheckBox* QHarassMana;
	CheckBox* autoW;
	CheckBox* harassW;
	CheckBox* rRangeMini;

	CheckBox* autoR;
	CheckBox* ComboInfo;
	CheckBox* qRange;
	CheckBox* wRange;
	CheckBox* rRange;
	CheckBox* eRange;
	CheckBox* onlyRdy;

	CheckBox* autoE;
	CheckBox* harassE;

	CheckBox* autoRlast;
	CheckBox* trinkiet;
	Slider* MaxRangeR;
	CheckBox* farmQ;
	Slider* delayR;
	KeyBind* useR;

	CheckBox* separate;
	CheckBox* farmW;

	CheckBox* jungleE;
	CheckBox* jungleQ;
	CheckBox* jungleW;

	float QMANA = 0;
	float WMANA = 0;
	float EMANA = 0;
	float RMANA = 0;
	bool chargeQXerath = false;
	bool canCastQ = true;

	int qTick = Engine::TickCount();
	int releaseqTick = Engine::TickCount();
	PredictionInput Q = PredictionInput({ 750, 0.7f,95.f,FLT_MAX, false, SkillshotType::SkillshotLine });
	PredictionInput W = PredictionInput({ 1100, 0.7f,150.f,FLT_MAX, false, SkillshotType::SkillshotCircle });
	PredictionInput E = PredictionInput({ 1050, 0.25f,60.f,1400.f, true, SkillshotType::SkillshotLine });
	PredictionInput R = PredictionInput({ 5000, 0.7f,130.f,FLT_MAX, false, SkillshotType::SkillshotCircle });

	Xerath()
	{
	}

	~Xerath()
	{
	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Xerath", "Xerath");

		auto Draw = menu->AddMenu("Draw", "Draw");
		auto QConfig = menu->AddMenu("QConfig", "QConfig");
		auto WConfig = menu->AddMenu("WConfig", "WConfig");
		auto EConfig = menu->AddMenu("EConfig", "EConfig");
		auto RConfig = menu->AddMenu("RConfig", "RConfig");
		auto Farm = menu->AddMenu("Farm", "Farm");

		noti = Draw->AddCheckBox("noti", "Show notification & line", true);
		onlyRdy = Draw->AddCheckBox("onlyRdy", "Draw only ready spells", true);
		qRange = Draw->AddCheckBox("qRange", "Q range", false);
		wRange = Draw->AddCheckBox("wRange", "W range", false);
		eRange = Draw->AddCheckBox("eRange", "E range", false);
		rRange = Draw->AddCheckBox("rRange", "R range", false);
		rRangeMini = Draw->AddCheckBox("rRangeMini", "R range minimap", true);

		autoQ = QConfig->AddCheckBox("autoQ", "Auto Q", true);
		harassQ = QConfig->AddCheckBox("harassQ", "harass Q", true);

		autoW = WConfig->AddCheckBox("autoW", "Auto W", true);
		harassW = WConfig->AddCheckBox("harassW", "Harass W", true);

		autoE = EConfig->AddCheckBox("autoE", "Auto E", true);
		harassE = EConfig->AddCheckBox("harassE", "Harass E", true);

		autoR = RConfig->AddCheckBox("autoR", "Auto R 2 x dmg R", true);
		autoRlast = RConfig->AddCheckBox("autoRlast", "Cast last position if no target", true);
		useR = RConfig->AddKeyBind("useR", "Semi-manual cast R key", VK_KEY_T, false, false); //32 == space
		trinkiet = RConfig->AddCheckBox("trinkiet", "Auto blue trinkiet", true);
		delayR = RConfig->AddSlider("delayR", "custome R delay ms (1000ms = 1 sec)", 0, 0, 3000, 1);
		MaxRangeR = RConfig->AddSlider("MaxRangeR", "Max R adjustment (R range - slider)", 0, 0, 5000, 1);

		separate = Farm->AddCheckBox("separate", "Separate laneclear from harras", false);
		farmQ = Farm->AddCheckBox("farmQ", "Lane clear Q", true);
		farmW = Farm->AddCheckBox("farmW", "Lane clear W", true);

		jungleE = Farm->AddCheckBox("jungleE", "Jungle clear E", true);
		jungleQ = Farm->AddCheckBox("jungleQ", "Jungle clear Q", true);
		jungleW = Farm->AddCheckBox("jungleW", "Jungle clear W", true);

		menu->AddCheckBox("force", "Force passive use in combo on minion", true);

		// Game.OnUpdate += Game_OnGameUpdate;
		// GameObject.OnCreate += Obj_AI_Base_OnCreate;
		// Drawing.OnDraw += Drawing_OnDraw;
		// Obj_AI_Base.OnProcessSpellCast += Obj_AI_Base_OnProcessSpellCast;
		// Interrupter2.OnInterruptableTarget += Interrupter2_OnInterruptableTarget;
		// AntiGapcloser.OnEnemyGapcloser += AntiGapcloser_OnEnemyGapcloser;
	}
	void Draw()
	{

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

	void castingQ()
	{
		if (chargeQXerath == true)
		{
			Q.Range = std::min((750 + 500 * (Engine::TickCount() - qTick) / 1000), 1465);
		}

		auto qBuff = me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("XerathArcanopulseChargeUp"));

		if (chargeQXerath == false && qBuff.count > 0)
		{
			qTick = Engine::TickCount();
			chargeQXerath = true;
		}
		if (chargeQXerath == true && qBuff.count == 0)
		{
			chargeQXerath = false;
			Q.Range = 750;
			if (IsKeyDown(CheckKey(_Q)))
			{
				KeyUp(CheckKey(_Q));
			}
		}

		if (qBuff.count == 0)
		{
			if (IsKeyDown(CheckKey(_Q)) == true && chargeQXerath == false)
			{
				_DelayAction->Add((int)(300), [=]() {
					if (IsKeyDown(CheckKey(_Q)) == true && chargeQXerath == false && !me->IsCasting())
					{
						KeyUp(CheckKey(_Q));
					}
					});
			}
		}

		if (IsKeyDown(CheckKey(_Q)) == true && !IsReady(_Q) && chargeQXerath == false)
		{
			Q.Range = 750;
			_DelayAction->Add((int)(10), []() {
				if (IsKeyDown(CheckKey(_Q)) == true)
				{
					KeyUp(CheckKey(_Q));
				}
				});
		}
	}

	void startQ()
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!IsKeyDown(CheckKey(_Q)) && IsReady(_Q) && /*caststate[0] &&*/ chargeQXerath == false && canCastQ && Engine::TickCount() - releaseqTick > 1000.f && !me->IsCasting())
		{
			KeyDown(CheckKey(_Q));
		}

	}

	void Tick()
	{
		castingQ();
		if (LagFree(0))
		{
			SetMana();
		}

		if (global::mode == ScriptMode::Combo)
		{
			if (LagFree(1) && autoQ->Value)
			{
				auto targetQ = targetselector->GetTarget(1400);
				if (targetQ != nullptr)
				{
					startQ();
					if (chargeQXerath)
					{

						if (me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellNameHash() == FNV("XerathArcanopulseChargeUp"))
						{
							auto pO = prediction->GetPrediction(targetQ, Q);

							if (pO.HitChance() >= HitChance::High)
							{
								ReleaseSpell(_Q, Engine::WorldToScreen(pO.CastPosition()));
								releaseqTick = Engine::TickCount();
							}
						}
					}
				}
			}

			if (LagFree(2) && autoW->Value && !chargeQXerath)
			{
				auto targetW = targetselector->GetTarget(W.Range);
				if (targetW != nullptr)
				{
					CastSpell(targetW, _W, W);
				}
			}

			if (LagFree(3) && autoE->Value && !chargeQXerath)
			{
				auto targetE = targetselector->GetTarget(E.Range);
				if (targetE != nullptr)
				{
					CastSpell(targetE, _E, E);
				}
			}

			if (LagFree(4) && autoR->Value && !chargeQXerath)
			{
				auto targetR = targetselector->GetTarget(R.Range);
				if (targetR != nullptr)
				{
					if (me->HasBuff(FNV("XerathLocusOfPower2")))
					{
						CastSpell(targetR, _R, R,true);
					}
				}
			}
		}
	}
};