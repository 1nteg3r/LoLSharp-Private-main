class Darius : public ModuleManager {
private:


public:
	Darius()
	{

	}

	~Darius()
	{

	}

	void Draw()
	{

	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Darius", "Darius");
	}
	void Combo()
	{
		auto target = targetselector->GetTarget(550);

		//antigapcloser();



		if (target != nullptr)
		{
			global::qdmg = GetSpellDamage(me, target, SpellSlot::Q);
			global::wdmg = GetSpellDamage(me, target, SpellSlot::W);
			global::edmg = GetSpellDamage(me, target, SpellSlot::E);
			global::rdmg = GetSpellDamage(me, target, SpellSlot::R);
			global::aadmg = GetSpellDamage(me, target, SpellSlot::AA);

			if (IsReady(_R) && me->Position().Distance(target->Position()) <= 500 + target->BoundingRadius() && target->Health() <= global::rdmg + global::aadmg + target->Health() * .05)
			{
				//printf("cast R?\n");
				CastSpell(_R, target);

			}

			while (me->HasBuff("dariusqcast"))
			{
				Vector3 extpos;
				orbwalker->UseOrbWalker = false;
				if (me->Position().Distance(target->Position()) < 330)
					extpos = target->Position().Extended(me->Position(), 700);
				else if (me->Position().Distance(target->Position()) > 330)
					extpos = target->Position();

				Vector3 W2S_buffer = Engine::WorldToScreen(extpos);

				if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
				{
					Engine::SetTargetOnlyChampions(true);
					MouseClick(false, W2S_buffer.x, W2S_buffer.y);
					Engine::SetTargetOnlyChampions(false);
				}
			}
			orbwalker->UseOrbWalker = true;

			if (me->GetSpellBook()->GetActiveSpellEntry())
			{
				if (me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName().c_str() == "DariusNoxianTacticsONHAttack" && IsReady(_Q))
				{

					CastSpell(_Q);
				}
			}

			if (me->HasBuff("DariusNoxianTacticsONH"))
			{
				orbwalker->ResetAutoAttacks();
			}

			if (IsReady(_E) && me->Position().Distance(target->Position()) < 550 && me->Position().Distance(target->Position()) > me->GetRealAutoAttackRange(target))
			{
				CastSpell(_E, target);
			}


			if (orbwalker->AfterAutoAttack())
			{
				if (IsReady(_W) && IsReady(_Q))
				{
					CastSpell(_W);
					orbwalker->ResetAutoAttacks();
					CastSpell(_Q);

				}
				else if (IsReady(_W))
				{
					CastSpell(_W);
					orbwalker->ResetAutoAttacks();
				}
			}
			if (IsReady(_Q) && me->Position().Distance(target->Position()) <= 460 + target->BoundingRadius() && (!IsReady(_W) || !IsReady(_E) && me->Position().Distance(target->Position()) > 325))
			{
				CastSpell(_Q);
			}
		}

	}
	void LaneClear()
	{
		std::vector<CObject*> minions = Engine::GetMinionsAround(600, 1);
		for (auto minion : minions)
		{
			if (minion->HasBuff("DariusW"))
			{

			}
		}

	}
	void LastHit()
	{

	}
	void Harass()
	{
		auto target = targetselector->GetTarget(SpellDatabase[FNV("DariusQ")].range);
		if (target != nullptr)
		{

		}
	}
	void Tick()
	{


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