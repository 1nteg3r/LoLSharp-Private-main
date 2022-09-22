class Talon : public ModuleManager {
private:


public:
	PredictionInput Q = PredictionInput({ 575.f });
	PredictionInput W = PredictionInput({ 650.f, 0.25f, 70.f, 2300.f, false, SkillshotType::SkillshotLine });
	PredictionInput W2 = PredictionInput({ 650.f, 0.25f, 40.f, 2300.f, false, SkillshotType::SkillshotLine });
	PredictionInput E = PredictionInput({  });
	PredictionInput R = PredictionInput({  });

	Talon()
	{

	}

	~Talon()
	{

	}


	void Draw()
	{


	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Talon", "Talon");
	}

	float qDmg(CObject* target)
	{
		if (me->Distance(target) < 555.f)
		{
			auto base_damage = 40 + (25 * me->GetSpellBook()->GetSpellSlotByID(0)->Level()) + (me->BonusAttackDamage() * 1.10);
			auto total = base_damage;
			return me->CalcPhysicalDamage(target, total);
		}
		return 0.f;
	}

	float wDmg(CObject* target)
	{
		if (me->Distance(target) < 640.f)
		{
			auto base_damage = 35 + (15 * me->GetSpellBook()->GetSpellSlotByID(1)->Level()) + (me->BonusAttackDamage() * 0.4);
			auto back = 55 + (25 * me->GetSpellBook()->GetSpellSlotByID(1)->Level()) + (me->BonusAttackDamage() * 0.6);
			auto total = base_damage + back;
			return me->CalcPhysicalDamage(target, total);
		}
		return 0.f;
	}

	float rDmg(CObject* target)
	{
		if (me->Distance(target) < 550.f)
		{
			auto base_damage = 45 + (45 * me->GetSpellBook()->GetSpellSlotByID(3)->Level()) + (me->BonusAttackDamage() * 1);
			auto total = base_damage;
			return me->CalcPhysicalDamage(target, total);
		}
		return 0.f;
	}

	void CastW(CObject* target)
	{
		if (me->Distance(target) < 640 && me->Distance(target) > 400)
		{
			CastSpell(target, _W, W);
		}
		else if (me->Distance(target) < 400)
		{
			CastSpell(target, _W, W2);

		}
	}

	void KillSteal()
	{
		for (auto enemy : Engine::GetHerosAround(2000.f, 1))
		{
			auto d = me->Distance(enemy);
			if (enemy->IsValidTarget() && !enemy->HasBuff(FNV("sionpassivezombie")))//dive
			{
				if (IsReady(_Q) && d < 555 and enemy->Health() < qDmg(enemy))
				{
					CastSpell(_Q, enemy);
				}
				if (IsReady(_W) && d < 640 and enemy->Health() < wDmg(enemy))
				{
					CastW(enemy);
				}
				if (IsReady(_R) && d < 550 and enemy->Health() < rDmg(enemy))
				{
					CastSpell(_R);
				}
			}
		}
	}



	void Combo()
	{
		auto target = targetselector->GetTarget(W.Range);
		if (target->IsValidTarget() && target->HealthPercent() < 60.f && !target->HasBuff(FNV("sionpassivezombie")) && !me->HasBuff(FNV("talonrstealth")))
		{
			auto d = me->Distance(target);
			if (IsReady(_W) && d < 650)
			{
				CastW(target);
			}

			if (me->IsInAutoAttackRange(target, 20.f))
			{
				if (!orbwalker->CanAttack())
					CastSpell(_Q, target);
			}
			else
			{
				if (IsReady(_Q) && d < 575 && !IsReady(_W))
				{
					CastSpell(_Q, target);
				}
			}

			if (IsReady(_R) && d < 550 && !IsReady(_Q))
			{
				CastSpell(_R);
			}
		}
		else if (target->IsValidTarget() && target->HealthPercent() >= 60.f && !target->HasBuff(FNV("sionpassivezombie")))
		{
			auto d = me->Distance(target);
			if (IsReady(_Q))
			{
				auto targetQ = targetselector->GetTarget(Q.Range);
				if (targetQ->IsValidTarget() && !target->HasBuff(FNV("sionpassivezombie")))
				{
					if (me->IsInAutoAttackRange(target, 20.f))
					{
						if (!orbwalker->CanAttack())
							CastSpell(_Q, target);
					}
					else
					{
						if (!Engine::UnderTurret(targetQ->Position()) && d < 555 || Engine::UnderTurret(targetQ->Position()) && d < 555 && targetQ->Health() < (qDmg(target) * 1.5))//dive
						{
							CastSpell(_Q, targetQ);
						}
					}
				}
			}

			if (IsReady(_W))
			{
				if (d < 650 && !me->HasBuff(FNV("talonrstealth")))
				{
					CastW(target);
				}
			}

			if (IsReady(_R) && IsReady(_W) && IsReady(_Q))
			{
				if (d < 550 && qDmg(target) + (wDmg(target)) > target->Health())
				{
					

				}
				else if (d < 550 && rDmg(target) + qDmg(target) + (wDmg(target)) > target->Health())
				{
					CastSpell(_R);
				}
			}
		}

	}


	void LaneClear()
	{
		for (auto mob : Engine::GetJunglesAround(W.Range))
		{
			if (IsReady(_Q))
			{
				CastSpell(_Q, mob);
			}
			if (IsReady(_W))
			{
				CastW(mob);
			}
		}

	}


	void LastHit()
	{

	}
	void Harass()
	{


	}
	void Tick()
	{

		orbwalker->UseOrbWalker = true;
		KillSteal();
		if (global::mode== ScriptMode::Combo)
		{
			Combo();
		}
		else if (global::mode== ScriptMode::LaneClear)
		{
			LaneClear();
		}
		else if (global::mode== ScriptMode::Mixed)
		{
			Harass();
		}
		else if (global::mode== ScriptMode::LastHit)
		{
			LastHit();
		}
	}
};