#pragma once
class Quinn : public ModuleManager {
private:


public:
	Quinn()
	{

	}

	~Quinn()
	{

	}

	void Draw()
	{

	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Quinn", "Quinn");
	}
	bool CanQuinnQ(CObject* target)
	{
		//if (target->GetSkinData()->GetSkinHash() == SkinHash::Mordekaiser)
		//{
		//	return (target->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "MordekaiserR");
		//}
		return true;
	}
	bool CanQuinnE(CObject* target)
	{
		//if (target->GetSpellSlotByName("SummonerDot") == target->GetSpellBook()->Casting())
		//{
		//	return true;
		//}
		if (target->GetSkinData()->GetSkinHash() == SkinHash::Darius)
		{
			if (!target->IsReady(2))
			{
				//printf("darius used E can VAULT\n");
				return true;
			}
		}

		if (Engine::GetEnemyCount(2000, target->Position()) > 2)
		{
			return false;
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Darius)
		{
			if (!target->IsReady(2))
			{
				//printf("darius used E can VAULT\n");
				return true;
			}
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Warwick)
		{
			if (!target->IsReady(0))
			{
				//printf("darius used E can VAULT\n");
				return true;
			}
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Garen)
		{
			return !target->IsGhosted();
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Yasuo)
		{
			return !target->IsReady(0) && target->GetAIManager()->IsDashing();
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Tryndamere)
		{
			return !target->IsReady(2);
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Camille)
		{
			return !target->IsReady(2);
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Urgot)
		{
			return !target->IsReady(2);
		}
		//else if (target->GetSkinData()->GetSkinHash() == SkinHash::Sett)
		//{
		//	return !target->IsReady(2);
		//}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Shen)
		{
			return !target->IsReady(2) || target->GetAIManager()->IsDashing();
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Jax)
		{
			return !target->IsReady(0);
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Diana)
		{
			return !target->IsReady(2);
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Mordekaiser)
		{
			return !target->IsReady(2);
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Singed)
		{
			return !target->IsReady(2);
		}
		//else if (target->GetSkinData()->GetSkinHash() == SkinHash::Khazix)
		//{
		//	return !target->IsReady(2);
		//}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Chogath)
		{
			return !target->IsReady(0);

		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Maokai)
		{
			return !target->IsReady(1);

		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::XinZhao)
		{
			return !target->IsReady(2);

		}
		//else if (target->GetSkinData()->GetSkinHash() == SkinHash::Akali)
		//{
		//	return !target->IsReady(2);
		//}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Aatrox)
		{
			if (me->GetSpellBook()->GetSpellSlotByID(_Q)->GetSpellData()->GetSpellName() == "AatroxQ" && IsReady(0))
				return false;
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Sion)
		{
			return !target->IsReady(0);
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Volibear)
		{
			return !target->IsReady(0);
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Yorick)
		{
			return !target->IsReady(1);
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Malphite)
		{
			return !target->IsReady(3) && target->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() != "MalphiteR";
		}
		else if (target->GetSkinData()->GetSkinHash() == SkinHash::Riven)
		{
			return target->BuffCount("RivenTriCleave") == 3 && target->GetAIManager()->IsDashing();
		}
		else
		{
			if (target->IsHero() && target->IsMelee() && me->Position().Distance(target->Position()) <= target->GetRealAutoAttackRange(me))
				return true;
		}
		return true;
	}
	bool antigapcloser()
	{
		for (auto actora : global::enemyheros)
		{
			if (IsValid(actora.actor))
			{
				CObject* actor = (CObject*)actora.actor;
				if (actor)
				{
					if (actor->IsMelee() && me->Position().Distance(actor->Position()) <= actor->GetRealAutoAttackRange(me) + 100)
						CastSpell(2, actor);
				}
			}

		}
	}
	float pdmg(CObject* target)
	{
		//return 0;
		if (target)
		{
			if (me->GetSkinData()->GetSkinHash() == SkinHash::Quinn)
			{

				if (target->IsMinion())
				{
					//printf("minion");
					global::pdmg += target->HasBuff("QuinnW") ? me->CalculateDamage(target, (5 + 5 * me->Level()) + (.14 + .2 * me->Level()) * me->TotalAttackDamage(), 1) : 0;

				}
				auto count = 0;

				if (target->HasBuff("QuinnW"))
					count += 1;

				if (me->IsReady(0))
					count += 1;

				if (me->IsReady(2))
					count += 1;



				if (target->IsHero())
				{
					//printf("hero");

					global::pdmg += me->CalculateDamage(target, (5 + 5 * me->Level()) + (.14 + .2 * me->Level()) * me->TotalAttackDamage(), 1) * count;
					//printf("hero2");

				}

			}
		}
		return global::pdmg;
	}

	float galeforcedmg(CObject* target)
	{
		if (target)
		{
			//printf("gforce");
			if (me->Level() >= 10)
			{
				auto postlevel = me->Level() - 9;
				return me->CalculateDamage(target, (180 + (15 * postlevel) + .45 * me->BonusAttackDamage()) * (1 + floor(target->MissingHealthPercent() / 7) * .05), 2);
			}
			else
			{
				return me->CalculateDamage(target, (180 + .45 * me->BonusAttackDamage()) * (1 + floor(target->MissingHealthPercent() / 7) * .05), 2);
			}

			//printf("gforce2");
		}
		return 0;
	}
	void Combo()
	{
		auto target = targetselector->GetTarget(1100);

		//antigapcloser();



		if (target != nullptr)
		{
			global::qdmg = GetSpellDamage(me, target, SpellSlot::Q);
			global::wdmg = GetSpellDamage(me, target, SpellSlot::W);
			global::edmg = GetSpellDamage(me, target, SpellSlot::E);
			global::rdmg = GetSpellDamage(me, target, SpellSlot::R);
			global::aadmg = GetSpellDamage(me, target, SpellSlot::AA);
			//if (me->HasItem(kItemID::Galeforce))
			//{
			//	if (orbwalker->CanAttack() && me->Position().Distance(target->Position()) <= me->GetRealAutoAttackRange(target) + 400 && me->Position().Distance(target->Position()) > me->GetRealAutoAttackRange(target) && target->Health() > global::aadmg && target->Health() <= global::qdmg + global::edmg + global::aadmg * 2 + pdmg(target) + galeforcedmg(target) + activator->ignitedmg())
			//	{
			//		//printf("gforce");
			//		CastItem(kItemID::Galeforce, target);
			//	}
			//}
			if (target->IsHero() && IsReady(0) && me->MoveSpeed() < 500 && me->Position().Distance(target->Position()) > me->GetRealAutoAttackRange(target) && CanQuinnQ(target))
			{
				CastSpell(target, 0, "QuinnQ");
				//CastSpellLine(0, target, SpellDatabase[FNV("QuinnQ")].range, SpellDatabase[FNV("QuinnQ")].radius, SpellDatabase[FNV("QuinnQ")].speed, 0, true);
			}

			if (target->IsMelee() && me->Position().Distance(target->Position()) <= 400)
			{
				CastSpell(2, target);
			}

			if (orbwalker->AfterAutoAttack())
			{
				if (target->IsHero() && (target->GetAIManager()->IsDashing() && CanQuinnE(target)))
				{
					//printf("target is dashing");
					CastSpell(2, target);
				}

				if (target->IsHero() && target->IsMelee() && me->Position().Distance(target->Position()) <= target->GetRealAutoAttackRange(me) + 50)// && CountEnemyHeroes(me, 1500) < 3 || CountEnemyHeroes(me, 350) >= 1)
				{
					CastSpell(2, target);
					//global::CanAttackTime = 0;
				}
				if (target->IsHero() && CanQuinnE(target))
				{
					CastSpell(2, target);
				}

				if (target->IsHero() && IsReady(0))
				{
					//printf("cast Q");
					CastSpell(target, 0, "QuinnQ");
					//CastSpellLine(0, target, SpellDatabase[FNV("QuinnQ")].range, SpellDatabase[FNV("QuinnQ")].radius, SpellDatabase[FNV("QuinnQ")].speed, 0, true);
				}
			}
		}
	}
	void LaneClear()
	{
		std::vector<CObject*> minions = Engine::GetMinionsAround(600, 1);
		for (auto minion : minions)
		{
			if (minion->HasBuff("QuinnW"))
			{
				if (orbwalker->CanAttack())
				{
					orbwalker->IssueAttack(minion);
				}
			}
		}

	}
	void LastHit()
	{

	}
	void Harass()
	{
		auto target = targetselector->GetTarget(SpellDatabase[FNV("QuinnQ")].range);
		if (target != nullptr)
		{
			if (target->IsHero() && (target->GetAIManager()->IsDashing() && CanQuinnE(target)))
			{
				//printf("target is dashing");
				CastSpell(2, target);
			}
		}
	}
	void Tick()
	{


		orbwalker->UseOrbWalker = true;
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
