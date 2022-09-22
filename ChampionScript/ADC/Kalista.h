#pragma once
class Kalista : public ModuleManager {
private:

public:
	Kalista()
	{

	}

	~Kalista()
	{

	}

	void Draw()
	{

	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Kalista", "Kalista");
	}

	void AutoE()
	{
		for (auto object : global::enemyheros)
		{
			CObject* actor = (CObject*)object.actor;

			if (actor->IsValidTarget())
			{
				global::edmg = IsReady(2) ? GetSpellDamage(me, actor, SpellSlot::E) : 0;

				if (actor->Health() < global::edmg && me->Position().Distance(actor->Position()) <= 1100.f)
				{
					if (!me->IsAutoAttacking())
						CastSpell(2);
				}
			}
		}
	}

	void Tick()
	{
		AutoE();
		if (global::mode == ScriptMode::Combo)
		{
			if (orbwalker->CanMove(orbwalker->ExtraWindUpTime->Value) || orbwalker->AfterAutoAttack())
			{
				if (CastSpell(targetselector->GetTarget(SpellDatabase[FNV("KalistaMysticShot")].range), 0, "KalistaMysticShot"))
					orbwalker->IssueMove(Vector3::Zero);
			}
		}
	}
};