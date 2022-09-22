#pragma once


class Pyke : public ModuleManager
{
public:



	bool chargeQPyke = false;


	int qTick = Engine::TickCount();
	float pullRange = 550.f;

	PredictionInput Q = PredictionInput({ 400.f, 0.25f,70.f,2000.f, true, SkillshotType::SkillshotLine });
	PredictionInput E = PredictionInput({ 550, 0.0f,70.f,3000.f, false, SkillshotType::SkillshotLine });
	PredictionInput Q2 = PredictionInput({ 1100.f, 0.25f,55.f,2000.f, true, SkillshotType::SkillshotLine });
	PredictionInput R = PredictionInput({ 750.f, 0.5f,100.f,2000.f, false, SkillshotType::SkillshotCircle });

	CheckBox* autoQ;
	CheckBox* comboE;
	CheckBox* ksR;

	Pyke()
	{
	}

	~Pyke()
	{
	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Pyke", "Pyke");
		auto QConfig = menu->AddMenu("QConfig", "QConfig");
		auto EConfig = menu->AddMenu("EConfig", "EConfig");
		auto RConfig = menu->AddMenu("RConfig", "RConfig");

		autoQ = QConfig->AddCheckBox("autoQ", "Use Q in Combo", true);
		comboE = EConfig->AddCheckBox("comboE", "Use E in Combo(Smart)", true);
		ksR = RConfig->AddCheckBox("ksR", "R to ks", true);

	}
	void Draw()
	{

	}
	float Dmg;

	void castingQ()
	{
		if (chargeQPyke == true)
		{
			Q.Range = std::min((400.f + 116.67f * (float(Engine::TickCount() - qTick) - 400.f) / 100.f), 1100.f);


		}

		auto qBuff = me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("PykeQ"));

		if (chargeQPyke == false && qBuff.count > 0)
		{
			qTick = Engine::TickCount();
			chargeQPyke = true;
		}
		if (chargeQPyke == true && qBuff.count == 0)
		{
			chargeQPyke = false;
			Q.Range = 400.f;
			if (IsKeyDown(CheckKey(_Q)))
			{
				KeyUp(CheckKey(_Q));
			}
		}

		if (qBuff.count == 0)
		{
			if (IsKeyDown(CheckKey(_Q)) == true && chargeQPyke == false)
			{
				_DelayAction->Add((int)(300), [=]() {
					if (IsKeyDown(CheckKey(_Q)) == true && chargeQPyke == false && !me->IsCasting())
					{
						KeyUp(CheckKey(_Q));
					}
					});
			}
		}

		if (IsKeyDown(CheckKey(_Q)) == true && !IsReady(_Q) && chargeQPyke == false)
		{
			Q.Range = 400.f;
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
		if (!IsKeyDown(CheckKey(_Q)) && IsReady(_Q) && /*caststate[0] &&*/ chargeQPyke == false && !me->IsCasting())
		{
			auto targetQ = targetselector->GetTarget(1100);
			if (targetQ != nullptr)
			{
				auto pO = prediction->GetPrediction(targetQ, Q2);

				if (pO.HitChance() >= HitChance::Low)
				{
					KeyDown(CheckKey(_Q));
				}
			}
		}

	}

	void Tick()
	{
		castingQ();

		if (global::mode == ScriptMode::Combo)
		{
			if (LagFree(1) && autoQ->Value)
			{
				auto targetQ = targetselector->GetTarget(1100);
				if (targetQ != nullptr)
				{
					startQ();

					if (chargeQPyke)
					{
						if (me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellNameHash() == FNV("PykeQ"))
						{
							auto pO = prediction->GetPrediction(targetQ, Q);

							if (pO.HitChance() >= HitChance::Medium)
							{
								ReleaseSpell(_Q, Engine::WorldToScreen(pO.CastPosition()));
							}
						}
					}
				}
			}

			if (LagFree(3) && comboE->Value)// E SKILL
			{
				auto targetE = targetselector->GetTarget(550);
				auto count = Engine::GetEnemyCount(300, targetE->Position());
				if (targetE->HasBuffOfType(BuffType::Slow))
				{

					if (count <= 2)
					{
						CastSpell(targetE, _E, E);
					}
					
                }
					 

					
			}

			if (LagFree(4) and ksR->Value)// R SKILL
			{
				auto targetR = targetselector->GetTarget(750);
				Dmg = GetSpellDamage(me, targetR, SpellSlot::R);

				if (targetR->IsValidTarget())
				{
					if (targetR->Health() < Dmg)
					{
						if (!targetR->IsInvulnerable())
						{
							CastSpell(targetR, _R, R);
						}
						
					}

				}

			}
		}
	}
};