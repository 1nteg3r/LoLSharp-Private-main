class Olaf : public ModuleManager {
private:


public:
	Olaf()
	{

	}

	~Olaf()
	{

	}

	void Draw()
	{

	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Olaf", "Olaf");
	}

	void Combo()
	{
		auto target = targetselector->GetTarget(SpellDatabase[FNV("OlafAxeThrow")].range);
		global::qdmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::Q, true));
		global::wdmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::W, true));
		global::edmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::E, true));
		global::rdmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::R, true));
		std::string q("OlafAxeThrow");
		if (target != nullptr)
		{
			auto localpos = me->Position();
			auto targetpos = target->Position();
			if (me->HealthPercent() <= 50 && orbwalker->AfterAutoAttack())
				CastSpell(1);

			PredictionInput pi;
			pi.Aoe = false;
			pi.Collision = true;
			pi.Speed = SpellDatabase[FNV("OlafAxeThrow")].speed;
			pi.Delay = SpellDatabase[FNV("OlafAxeThrow")].delay;
			pi.Range = SpellDatabase[FNV("OlafAxeThrow")].range;
			pi.From(me->ServerPosition());
			pi.Radius = SpellDatabase[FNV("OlafAxeThrow")].radius;
			pi.Unit = target;
			pi.Type = SkillshotType::SkillshotLine;

			auto PredPos = prediction->GetPrediction(pi).CastPosition();

			if (!me->CanMove() && !me->GetAIManager()->IsDashing())
			{
				CastSpell(3);
			}
			if (IsReady(0) && me->Position().Distance(target->Position()) <= 1000 && target->Health() <= global::qdmg)
			{
				Vector3 Pred;
				if (localpos.Distance(targetpos) <= 300)
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 150);
				else if (localpos.Distance(targetpos) <= 400)
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 200);
				else if (localpos.Distance(targetpos) <= 500)
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 200);
				else if (localpos.Distance(targetpos) <= 600)
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 250);
				else
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 300);

				Vector3 W2S_buffer = Engine::WorldToScreen(Pred);
				CastSpell(0, W2S_buffer);
			}
			else if (IsReady(2) && localpos.Distance(targetpos) <= 325 && target->Health() <= global::edmg)
			{
				CastSpell(2, target);
			}
			else if (localpos.Distance(targetpos) > me->GetRealAutoAttackRange(target) && IsReady(0) && localpos.Distance(targetpos) <= 1000)
			{
				Vector3 Pred;
				if (localpos.Distance(targetpos) <= 300)
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 150);
				else if (localpos.Distance(targetpos) <= 400)
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 200);
				else if (localpos.Distance(targetpos) <= 500)
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 200);
				else if (localpos.Distance(targetpos) <= 600)
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 250);
				else
					Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 300);

				Vector3 W2S_buffer = Engine::WorldToScreen(Pred);
				CastSpell(0, W2S_buffer);
			}

			else if (localpos.Distance(targetpos) <= me->GetRealAutoAttackRange(target) && IsReady(0))
			{
				if (localpos.Distance(targetpos) <= 1000 && orbwalker->AfterAutoAttack())
				{
					Vector3 Pred = localpos.Extended(PredPos, localpos.Distance(targetpos) + 150);
					Vector3 W2S_buffer = Engine::WorldToScreen(Pred);
					CastSpell(0, W2S_buffer);
				}
			}


			if (IsReady(2) && localpos.Distance(targetpos) <= 325 && localpos.Distance(targetpos) > me->GetRealAutoAttackRange(target))
				CastSpell(2, target);

			if (orbwalker->AfterAutoAttack())
			{
				//printf("workit");
				CastSpell(2, target);

			}
		}
	}
	void LaneClear()
	{

		if (me->HealthPercent() <= 40 && orbwalker->AfterAutoAttack())
			CastSpell(1);

		if (IsReady(_Q) || IsReady(_E))
		{
			orbwalker->UseOrbWalker = true;

			std::vector<CObject*> minions = Engine::GetMinionsAround(1000, 1);
			for (auto target : minions)
			{
				global::qdmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::Q, true));
				global::wdmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::W, true));
				global::edmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::E, true));

				if (IsReady(2) && target->Health() <= global::edmg)
				{
					CastSpell(2, target);
				}
				else if (IsReady(0) && target->Health() <= global::qdmg)
				{
					CastSpell(0, target);

				}

				if (target->IsMonster())
				{
					if (IsReady(2) && orbwalker->AfterAutoAttack())
					{
						CastSpell(2, target);
					}
					else if (IsReady(0) && orbwalker->AfterAutoAttack())
					{
						CastSpell(0, target);

					}
				}
				//if (AfterAutoAttack() && me->HasItem(kItemID::GoreDrinker) && GetEnemyCount(2000, me->Pos2D()) < 1)
				//{
				//	//printf("i have goredinker");
				//	CastItem(kItemID::GoreDrinker);
				//}

				if (orbwalker->AfterAutoAttack() && me->HasItem(kItemID::IronSpikeWhip) && Engine::GetEnemyCount(2000, me->Position()) < 1)
				{
					//printf("i have goredinker");
					CastItem(kItemID::IronSpikeWhip);
				}
			}
			std::vector<CObject*> jungles = Engine::GetJunglesAround(1000, 2);
			for (auto target : jungles)
			{
				global::qdmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::Q, true));
				global::wdmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::W, true));
				global::edmg = me->CalculateDamage(target, GetSpellDamage(me, target, SpellSlot::E, true));

				if (IsReady(2) && target->Health() <= global::edmg)
				{
					CastSpell(2, target);
				}
				else if (IsReady(0) && target->Health() <= global::qdmg)
				{
					CastSpell(0, target);

				}

				if (target->IsMonster())
				{
					if (IsReady(2) && orbwalker->AfterAutoAttack())
					{
						CastSpell(2, target);
					}
					else if (IsReady(0) && orbwalker->AfterAutoAttack())
					{
						CastSpell(0, target);

					}
				}
				//if (AfterAutoAttack() && me->HasItem(kItemID::GoreDrinker) && GetEnemyCount(2000, me->Pos2D()) < 1)
				//{
				//	//printf("i have goredinker");
				//	CastItem(kItemID::GoreDrinker);
				//}

				if (orbwalker->AfterAutoAttack() && me->HasItem(kItemID::IronSpikeWhip) && Engine::GetEnemyCount(2000, me->Position()) < 1)
				{
					//printf("i have goredinker");
					CastItem(kItemID::IronSpikeWhip);
				}
			}
		}

	}
	void LastHit()
	{

	}
	void Tick()
	{
		if (me->HealthPercent() <= 40 && orbwalker->AfterAutoAttack())
			CastSpell(1);
		orbwalker->UseOrbWalker = true;
		if (global::mode== ScriptMode::Combo)
		{
			Combo();
		}
		else if (global::mode== ScriptMode::LaneClear)
		{
			LaneClear();
		}
		else if (global::mode== ScriptMode::LastHit)
		{
			LastHit();
		}
	}
};
