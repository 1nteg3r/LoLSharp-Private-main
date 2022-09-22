class Diana : public ModuleManager {
private:


public:
	PredictionInput Q = PredictionInput({ 900.0f, 0.5f,175.0f,1800.0f, false, SkillshotType::SkillshotCircle });
	PredictionInput W = PredictionInput({ 250.0f });
	PredictionInput E = PredictionInput({ 825.0f });
	PredictionInput R = PredictionInput({ 430.0f });
	CheckBox* AutoEKS;

	Diana()
	{

	}

	~Diana()
	{

	}


	void Draw()
	{


	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Diana", "Diana");
		AutoEKS = menu->AddCheckBox("AutoEKS", "Use KS E", true);
	}

	bool HasQBuff(CObject* target)
	{
		return target->HasBuff("dianamoonlight");
	}
	float GetQDamage(CObject* target)
	{
		int level = me->GetSpellBook()->GetSpellSlotByID(_Q)->Level();
		if (level == 0 || !IsReady(_Q))
		{
			return 0.0f;
		}
		float num = 0.0f;
		num = 60.0f + (level - 1) * 35.0f;
		num += me->TotalAbilityPower() * 0.7f;
		return me->CalculateDamage(target, num, 2);
	}

	float GetWDamage(CObject* target)
	{
		int level = me->GetSpellBook()->GetSpellSlotByID(_W)->Level();
		if (level == 0 || !IsReady(_W))
		{
			return 0.0f;
		}
		float num = 0.0f;
		num = 22.0f + (level - 1) * 12.0f;
		num += me->TotalAbilityPower() * 0.15f;
		return me->CalculateDamage(target, num * 3.0f, 2);
	}

	float GetEDamage(CObject* target)
	{
		int level = me->GetSpellBook()->GetSpellSlotByID(_E)->Level();
		if (level == 0 || !IsReady(_E))
		{
			return 0.0f;
		}
		float num = 0.0f;
		num = 40.0f + (level - 1) * 20;
		num += me->TotalAbilityPower() * 0.4f;

		/*for (auto slot : SpellSlots)
		{
			auto spell = Spell::GetSpell(slot);
			if (spell == nullptr)
				continue;

			if (spell->Name == "AtmasImpalerDummySpell" && spell->Cooldown <= 0.0f)
			{
				num += me->TotalAbilityPower() * 0.5f + me->TotalAttackDamage() * 0.745f;
			}
			if (spell->Name == "Malady")
			{
				num += 15.0f + me->TotalAbilityPower() * 0.15f;
			}
		}*/

		return me->CalculateDamage(target, num, 2) + static_cast<float>(me->GetAutoAttackDamage(target));
	}

	float GetE1Damage(CObject* target)
	{
		int level = me->GetSpellBook()->GetSpellSlotByID(_E)->Level();
		int level2 = me->Level();
		if (level == 0 || (IsReady(_E) && me->BuffCount(FNV("dianapassivemarker")) < 2))
		{
			return 0.0f;
		}
		float num = 0.0f;
		float num2 = 0.0f;
		num2 = 40.0f + (level - 1) * 20;
		num2 += me->TotalAbilityPower() * 0.4f;
		if (level2 >= 1 && level2 <= 5)
		{
			num = 20.0f + (level2 - 1) * 5;
		}
		else if (level2 >= 6 && level2 <= 10)
		{
			num = 55.0f + (level2 - 6) * 10;
		}
		else if (level2 >= 11 && level2 <= 15)
		{
			num = 120.0f + (level2 - 11) * 15;
		}
		else if (level2 >= 16)
		{
			num = 210.0f + (level2 - 16) * 20;
		}

		/*for (auto slot : SpellSlots)
		{
			auto spell = Spell::GetSpell(slot);
			if (spell == nullptr)
				continue;

			if (spell->Name == "AtmasImpalerDummySpell" && spell->Cooldown <= 0.0f)
			{
				num += ObjectManager.Player->MagicAttack * 0.5f + ObjectManager.Player->TotalAttack * 0.745f;
			}
			if (spell->Name == "Malady")
			{
				num += 15.0f + ObjectManager.Player->MagicAttack * 0.15f;
			}
		}*/
		num += me->TotalAbilityPower() * 0.4f;
		return me->CalculateDamage(target, num + num2, 2) + static_cast<float>(me->GetAutoAttackDamage(target));
	}

	float GetElectroCuteDamage(CObject* target)
	{
		int level = me->Level();
		if (level == 0 || !me->HasBuff(FNV("ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua")))
		{
			return 0.0f;
		}
		float num = 0.0f;
		num = 30.0f + (level - 1) * 8.8f;
		num += me->TotalAbilityPower() * 0.25f + me->BonusAttackDamage() * 0.4f;
		return me->CalculateDamage(target, num, 2);
	}

	float GetPasiveDamage(CObject* target)
	{
		int level = me->Level();
		if (level == 0 || me->BuffCount(FNV("dianapassivemarker")) < 2)
		{
			return 0.0f;
		}
		float num = 0.0f;
		if (level >= 1 && level <= 5)
		{
			num = 20.0f + (level - 1) * 5;
		}
		else if (level >= 6 && level <= 10)
		{
			num = 55.0f + (level - 6) * 10;
		}
		else if (level >= 11 && level <= 15)
		{
			num = 120.0f + (level - 11) * 15;
		}
		else if (level >= 16)
		{
			num = 210.0f + (level - 16) * 20;
		}
		num += me->TotalAbilityPower() * 0.4f;
		return me->CalculateDamage(target, num, 2);
	}

	void Quse(CObject* target)
	{
		if (target != nullptr && IsReady(_Q) && target->IsValidTarget(Q.Range) && target->Distance(me) < Q.Range - 39.0f)
		{
			CastSpell(target, _Q, Q, false, HitChance::High);
		}
	}

	void Wuse(CObject* target)
	{
		if ((target == nullptr || !IsReady(_W) || !me->IsDashing() || !(me->Distance(target) > me->GetSelfAttackRange())) && target != nullptr && IsReady(_W) && me->Distance(target) <= me->GetSelfAttackRange())
		{
			CastSpell(_W);
		}
	}

	void Ruse(CObject* target)
	{
		if (target == nullptr || !IsReady(_R) || !me->IsDashing() || !(me->Distance(target) > R.Range))
		{
			if (target != nullptr && IsReady(_R) && me->Distance(target) <= R.Range && Engine::GetEnemyCount(R.Range, me->Position()) >= 2)
			{
				CastSpell(_R);
			}

		}
	}

	void UserEEE(CObject* target)
	{
		if (global::mode== ScriptMode::Combo && target->IsValidTarget(E.Range))
		{
			CastSpell(_E, target);
		}
	}

	void GapCloser(CObject* target)
	{
		if (target != nullptr && target->IsValidTarget(E.Range * 2.0f) && IsReady(_Q) && IsReady(_E))
		{
			auto closeMinion = (from(Engine::GetMinionsAround(2000.f)) >> orderby([&](CObject* x) { return  x->IsValidTarget() && x->Distance(target); }) >> first_or_default([&](CObject* x)
				{
					return x->IsValidTarget(Q.Range) && x->Health() > GetQDamage(x);
				}));

			if (closeMinion != nullptr)
			{
				CastSpell(_Q, closeMinion);
				_DelayAction->Add((int)(350), [=]() {
					UserEEE(closeMinion);
					});
			}
		}
	}

	void Combo()
	{
		CObject* target2;
		if (orbwalker->CanMove(50.0f))
		{
			target2 = targetselector->GetTarget(Q.Range);
			if (target2 != nullptr)
			{

				if (target2->Distance(me) > Q.Range)
				{
					CObject* target3 = targetselector->GetTarget(Q.Range);
					Quse(target3);
				}
				else
				{
					Quse(target2);
				}

				if (target2 == nullptr)
				{
					goto IL_024a;
				}
				if (target2->Distance(me) > Q.Range)
				{
					CObject* target = targetselector->GetTarget(Q.Range);
					if (target == nullptr || !target->IsValidTarget(Q.Range) || !IsReady(_Q) || !IsReady(_E) || !(target->Distance(me) < Q.Range - 39.0f) || !CastSpell(target, _Q, Q, false, HitChance::VeryHigh))
					{
						goto IL_024a;
					}
					_DelayAction->Add((int)(350), [=]() {
						UserEEE(target);
						});
				}
				else
				{
					if (!target2->IsValidTarget(Q.Range) || !IsReady(_Q) || !IsReady(_E) || !(target2->Distance(me) < Q.Range - 39.0f) || !CastSpell(target2, _Q, Q, false, HitChance::VeryHigh))
					{
						goto IL_024a;
					}
					_DelayAction->Add((int)(350), [=]() {
						UserEEE(target2);
						});
				}
			}
		}
		goto end_IL_0000;
	IL_024a:

		if (target2 == nullptr)
		{
			goto IL_032e;
		}
		if (target2->Distance(me) > E.Range)
		{
			CObject* target4 = targetselector->GetTarget(E.Range);
			if (target4 == nullptr || !target4->IsValidTarget(E.Range) || !IsReady(_E) || !HasQBuff(target4))
			{
				goto IL_032e;
			}
			CastSpell(_E, target4);
		}
		else
		{
			if (!target2->IsValidTarget(E.Range) || !IsReady(_E) || !HasQBuff(target2))
			{
				goto IL_032e;
			}
			CastSpell(_E, target2);
		}
		goto end_IL_0000;
	IL_032e:

		if (target2->Distance(me) > W.Range)
		{
			CObject* target5 = targetselector->GetTarget(W.Range);
			Wuse(target5);
		}
		else
		{
			Wuse(target2);
		}



		if (target2->Distance(me) > R.Range)
		{
			CObject* target6 = targetselector->GetTarget(R.Range);
			Ruse(target6);
		}
		else
		{
			Ruse(target2);
		}


	end_IL_0000:
		;
	}

	void KillSteal()
	{
		if (IsReady(_Q))
		{
			auto ksTarget = (from(Engine::GetHerosAround(2000.f)) >> first_or_default([&](CObject* x) {return  x->IsValidTarget(Q.Range) && x->Health() < GetQDamage(x); }));
			if (ksTarget != nullptr && CastSpell(ksTarget, _Q, Q, false, HitChance::High))
				return;
		}

		if (AutoEKS->Value)
		{
			auto ksTarget = (from(Engine::GetHerosAround(2000.f)) >> first_or_default([&](CObject* x) {return  x->IsValidTarget(E.Range) && x->Health() < GetEDamage(x); }));
			if (ksTarget != nullptr && CastSpell(_E, ksTarget))
				return;

			for (auto current3 : (from(Engine::GetHerosAround(2000.f)) >> where([&](CObject* x) {return  x->IsValidTarget(E.Range) && x->Health() < GetE1Damage(x); }) >> to_vector()))
			{
				if (CastSpell(_E, current3))
					break;
			}
		}
	}

	void JungleClear()
	{
		if (orbwalker->CanMove(40.0f))
		{
			auto source = (from(Engine::GetJunglesAround(1000.f)) >> where([&](CObject* minion) {return  minion->IsValidTarget(Q.Range); }) >> to_vector());
			if (IsReady(_Q) && !me->HasBuff(FNV("dianapbonusas")) && source.size() > 0 && source.back()->IsValidTarget(Q.Range))
			{
				CastSpell(_Q,Engine::WorldToScreen(source.back()->Position()));
			}
			else if (IsReady(_W) && !me->HasBuff(FNV("dianapbonusas")) && source.size() > 0 && source.back()->IsValidTarget(W.Range))
			{
				CastSpell(_W);
			}
			if (IsReady(_E) && source.size() > 0 && source.back()->IsValidTarget(E.Range))
			{
				if (HasQBuff(source.back()))
				{
					CastSpell(_E, source.back());
				}
			}
		}
	}


	void LaneClear()
	{
		if (orbwalker->CanMove(40.0f) && !(60 > me->ManaPercent()))
		{
			auto source = (from(Engine::GetMinionsAround(2000.f)) >> where([&](CObject* minion) {return  minion->IsValidTarget(Q.Range); }) >> to_vector());
			if (IsReady(_Q) && source.size() > 0 && source.back()->IsValidTarget(Q.Range))
			{
				CastSpell(_Q, Engine::WorldToScreen(source.back()->Position()));
			}
			if (IsReady(_W) && source.size() > 0 && source.back()->IsValidTarget(W.Range))
			{
				CastSpell(_W);
			}
			if (IsReady(_E) && source.size() > 0 && source.back()->IsValidTarget(E.Range))
			{
				if (HasQBuff(source.back()))
				{
					CastSpell(_E, source.back());
				}
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
			JungleClear();
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