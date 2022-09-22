#pragma once

//class Ezreal : public ModuleManager
//{
//public:
//	CheckBox *noti;
//	CheckBox *onlyRdy;
//	CheckBox *qRange;
//	CheckBox *wRange;
//	CheckBox *wRange;
//	CheckBox *eRange;
//	CheckBox *rRange;
//
//	CheckBox *autoW;
//	CheckBox *wPush;
//	CheckBox *harassW;
//	KeyBind *smartE;
//	KeyBind *smartEW;
//	CheckBox *EKsCombo;
//	CheckBox *EAntiMelee;
//	CheckBox *autoEgrab;
//	CheckBox *autoR;
//	CheckBox *Rcc;
//	Slider *Raoe;
//	KeyBind *useR;
//	CheckBox *Rturrent;
//	Slider *MaxRangeR;
//	Slider *MinRangeR;
//	CheckBox *farmQ;
//	CheckBox *FQ;
//	CheckBox *LCP;
//
//	float QMANA = 0;
//	float WMANA = 0;
//	float EMANA = 0;
//	float RMANA = 0;
//
//	Vector3 CursorPosition = Vector3::Zero;
//
//	double lag = 0;
//	double WCastTime = 0;
//	double QCastTime = 0;
//	float DragonDmg = 0;
//	double DragonTime = 0;
//	bool Esmart = false;
//	double OverKill = 0;
//	double OverFarm = 0;
//	double diag = 0;
//	double diagF = 0;
//	int Muramana = 3042;
//	int Tear = 3070;
//	int Manamune = 3004;
//	double NotTime = 0;
//
//	PredictionInput Q = PredictionInput({ 1180, 25.f,60.f,2000.f, true, SkillshotType::SkillshotLine });
//	PredictionInput W = PredictionInput({ 1180, 25.f,60.f,1700.f, false, SkillshotType::SkillshotLine });
//	PredictionInput E = PredictionInput({ 475 });
//	PredictionInput R = PredictionInput({ 3000.f, 1.1f,160.f,2000.f,false,SkillshotType::SkillshotLine });
//
//	Ezreal()
//	{
//	}
//
//	~Ezreal()
//	{
//	}
//
//	void Init()
//	{
//		// Q = new Spell(SpellSlot.Q, 1180);
//		//     W = new Spell(SpellSlot.W, 1180);
//		//     E = new Spell(SpellSlot.E, 475);
//		//     R = new Spell(SpellSlot.R, 3000f);
//
//		//     Q.SetSkillshot(0.25f, 60f, 2000f, true, SkillshotType.SkillshotLine);
//		//     W.SetSkillshot(0.25f, 60f, 1700f, false, SkillshotType.SkillshotLine);
//		//     R.SetSkillshot(1.1f, 160f, 2000f, false, SkillshotType.SkillshotLine);
//		auto menu = Menu::CreateMenu("Ezreal", "Ezreal");
//
//		auto Draw = menu->AddMenu("Draw", "Draw");
//		noti = Draw->AddCheckBox("noti", "Show notification", false);
//		onlyRdy = Draw->AddCheckBox("onlyRdy", "Draw only ready spells", true);
//		qRange = Draw->AddCheckBox("qRange", "Q range", false);
//		wRange = Draw->AddCheckBox("wRange", "W range", false);
//		eRange = Draw->AddCheckBox("eRange", "E range", false);
//		rRange = Draw->AddCheckBox("rRange", "R range", false);
//
//		auto WConfig = menu->AddMenu("WConfig", "W Config");
//		autoW = WConfig->AddCheckBox("autoW", "Auto W", true);
//		wPush = WConfig->AddCheckBox("wPush", "W on towers", true);
//		harassW = WConfig->AddCheckBox("harassW", "Harass W", true);
//
//		auto EConfig = menu->AddMenu("EConfig", "E Config");
//		smartE = EConfig->AddKeyBind("smartE", "SmartCast E key", VK_KEY_T, false, true);       //32 == space
//		smartEW = EConfig->AddKeyBind("smartEW", "SmartCast E + W key", VK_KEY_T, false, true); //32 == space
//		EKsCombo = EConfig->AddCheckBox("EKsCombo", "E ks combo", true);
//		EAntiMelee = EConfig->AddCheckBox("EAntiMelee", "E anti-melee", true);
//		autoEgrab = EConfig->AddCheckBox("autoEgrab", "Auto E anti grab", true);
//		// Dash = new Core.OKTWdash(E);
//
//		auto RConfig = menu->AddMenu("RConfig", "R Config");
//		autoR = RConfig->AddCheckBox("autoR", "Auto R", true);
//		Rcc = RConfig->AddCheckBox("Rcc", "R cc", true);
//		Raoe = RConfig->AddSlider("Raoe", "R AOE", 3, 0, 5, 1);
//		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rjungle", "R Jungle stealer", true);
//		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rdragon", "Dragon", true);
//		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rbaron", "Baron", true);
//		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rred", "Red", true);
//		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rblue", "Blue", true);
//		// HeroMenu.SubMenu("R Config").SubMenu("R Jungle stealer").AddItem(new MenuItem("Rally", "Ally stealer", false);
//		useR = RConfig->AddKeyBind("useR", "Semi-manual cast R key", VK_KEY_T, false, true); //32 == space
//		Rturrent = RConfig->AddCheckBox("Rturrent", "Don't R under turret", true);
//		MaxRangeR = RConfig->AddSlider("MaxRangeR", "Max R range", 3000, 0, 5000, 1);
//		MinRangeR = RConfig->AddSlider("MinRangeR", "Min R range", 900, 0, 5000, 1);
//
//		menu->AddSlider("HarassMana", "Harass Mana", 30, 0, 100, 1);
//
//		auto Farm = menu->AddMenu("Farm", "Farm");
//		farmQ = Farm->AddCheckBox("farmQ", "LaneClear Q", true);
//		FQ = Farm->AddCheckBox("FQ", "Farm Q out range", true);
//		LCP = Farm->AddCheckBox("LCP", "FAST LaneClear", true);
//
//		menu->AddCheckBox("debug", "Debug", false);
//
//		menu->AddCheckBox("stack", "Stack Tear if full mana", false);
//
//		// Game.OnUpdate += Game_OnUpdate;
//		// Drawing.OnDraw += Drawing_OnDraw;
//		// Orbwalking.BeforeAttack += Orbwalking_BeforeAttack;
//		// Obj_AI_Base.OnBuffAdd += Obj_AI_Base_OnBuffAdd;
//	}
//
//	void Draw()
//	{
//	}
//
//	void SetMana()
//	{
//		if (global::mode== ScriptMode::Combo || me->HealthPercent() < 20)
//		{
//			QMANA = 0;
//			WMANA = 0;
//			EMANA = 0;
//			RMANA = 0;
//			return;
//		}
//
//		QMANA = me->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(0)->Level());
//		QMANA = me->GetSpellBook()->GetSpellSlotByID(1)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(1)->Level());
//		QMANA = me->GetSpellBook()->GetSpellSlotByID(2)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(2)->Level());
//
//		if (!IsReady(_R))
//			RMANA = QMANA - me->ResourceRegen() * me->GetSpellBook()->GetSpellSlotByID(0)->CoolDown();
//		else
//			RMANA = me->GetSpellBook()->GetSpellSlotByID(3)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(3)->Level());
//	}
//
//	void Tick()
//	{
//		if (LagFree(0))
//		{
//			SetMana();
//		}
//
//		if (IsReady(_E))
//		{
//			if (LagFree(0))
//				LogicE();
//
//			if (smartE->Value)
//				Esmart = true;
//			if (smartEW->Value && IsReady(_W))
//			{
//				CursorPosition = Engine::GetMouseWorldPosition();
//				CastSpell(1, Engine::WorldToScreen(CursorPosition));
//			}
//			if (Esmart && Engine::GetHerosAround(500, 1, me->Position().Extended(Engine::GetMouseWorldPosition(), E.Range)).size() < 4)
//				CastSpell(2, Engine::WorldToScreen(me->Position().Extended(Engine::GetMouseWorldPosition(), E.Range)));
//
//			if (CursorPosition.IsValid())
//				CastSpell(2, Engine::WorldToScreen(me->Position().Extended(CursorPosition, E.Range)));
//		}
//		else
//		{
//			CursorPosition = Vector3::Zero;
//			Esmart = false;
//		}
//
//	}
//};

class Ezreal : public ModuleManager {
private:
	PredictionInput Q = PredictionInput({ 1180, 0.25f,60.f,2000.f, true, SkillshotType::SkillshotLine });
	PredictionInput W = PredictionInput({ 1180, 0.25f,60.f,1700.f, false, SkillshotType::SkillshotLine });
	PredictionInput E = PredictionInput({ 475 });
	PredictionInput R = PredictionInput({ 3000.f, 1.1f,160.f,2000.f,false,SkillshotType::SkillshotLine });

public:
	Ezreal()
	{

	}

	~Ezreal()
	{

	}

	void Draw()
	{

	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Ezreal", "Ezreal");
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
						if (CastSpell(_Q,minion))
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

	void Combo(CObject* TargetQ, CObject* TargetW, CObject* TargetE, CObject* TargetR)
	{
		if (TargetW && IsReady(1) && me->IsInAutoAttackRange(TargetW))
		{
			W.Collision = false;
			CastSpell(TargetW, 1, W);
		}

		if (TargetW && IsReady(1) && IsReady(0))
		{
			W.Collision = true;
			(CastSpell(TargetW, 1, W));
		}

		if (TargetQ && IsReady(0) && !IsReady(1))
		{
			(CastSpell(TargetW, 0, Q));
		}
	}

	void LaneClear()
	{
		farmQ();
	}

	void Tick()
	{
		orbwalker->UseOrbWalker = true;
		if (global::mode== ScriptMode::Combo)
		{
			this->Combo(targetselector->GetTarget(this->Q.Range), targetselector->GetTarget(this->W.Range), targetselector->GetTarget(this->E.Range), targetselector->GetTarget(this->R.Range));
		}
		else if (global::mode== ScriptMode::LaneClear)
		{
			LaneClear();
		}
	}
};