#pragma once
class Hecarim : public ModuleManager {
private:
	CheckBox* Stack;

public:
	Hecarim()
	{

	}

	~Hecarim()
	{

	}

	void Draw()
	{

	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Hecarim", "Hecarim");
		auto ComboSet = menu->AddMenu("ComboSet", "Combo Settings");

		//Stack = ComboSet->AddCheckBox("Stack", "Keep Stacks up", true);

		//ComboMenu 

	}

	void Tick()
	{

		if (Stack->Value)
		{

		}

		if (global::mode== ScriptMode::Combo)
		{

			//orbwalker->OrbWalk(targetselector->GetTarget(_Q), false);
			auto target = targetselector->GetTarget(1000);
			global::qdmg = GetSpellDamage(me, target, SpellSlot::Q);


			if (me->Position().Distance(target->Position()) <= 350)
				CastSpell(_Q);

			if (me->Position().Distance(target->Position()) <= 575)
				CastSpell(_W);

			if (orbwalker->AfterAutoAttack())
			{
				CastSpell(_Q);
			}
		}


		if (global::mode== ScriptMode::Mixed)
		{
			//orbwalker->OrbWalk(targetselector->GetTarget(_Q), false);
			auto target = targetselector->GetTarget(_Q);
			if (orbwalker->AfterAutoAttack())
			{

			}
		}

		if (global::mode== ScriptMode::LaneClear)
		{
			std::vector<CObject*> minions = Engine::GetMinionsAround(600, 1);
			for (auto minion : minions)
			{
				if (IsReady(_Q))
				{
					if (me->Position().Distance(minion->Position()) <= 350)
						CastSpell(_Q);
				}
			}
			std::vector<CObject*> jungles = Engine::GetJunglesAround(600, 2);
			for (auto jungle : jungles)
			{
				if (IsReady(_Q))
				{
					if (me->Position().Distance(jungle->Position()) <= 350)
						CastSpell(_Q);
				}
			}

			//if (orbwalker->AfterAutoAttack())
			//{
			//	CastSpell(_Q);
			//}
		}

		if (global::mode== ScriptMode::Fly)
		{

		}
	}
};