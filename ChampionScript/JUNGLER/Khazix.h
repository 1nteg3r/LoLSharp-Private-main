#pragma once
class Khazix : public ModuleManager {
private:
	CheckBox* Stack;

public:
	Khazix()
	{

	}

	~Khazix()
	{

	}

	void Draw()
	{
		for (auto object : global::enemyheros)
		{
			auto target = (CObject*)object.actor;
			if (target->IsAlive() && target->IsEnemy() && target->Health() <= global::pdmg + global::aadmg + global::wdmg + global::edmg + global::rdmg)
			{
				XPolygon::DrawCircle(target->Position(), 100, ImVec4(255, 255, 0, 0), 20);

			}
		}
	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Khazix", "Khazix");
		auto ComboSet = menu->AddMenu("ComboSet", "Combo Settings");

		//Stack = ComboSet->AddCheckBox("Stack", "Keep Stacks up", true);

		//ComboMenu 

	}
	void ks(CObject* target)
	{
		if (target->Health() <= global::qdmg)
			CastSpell(0, target);
		if (target->Health() <= global::wdmg)
			CastSpell(1, target);
	}

	bool Isolated(CObject* target)
	{
		return (Engine::GetEnemyCount(500, target->Position()) == 1 && Engine::GetMinionCount(500, target->Position()) == 0);
	}
	float passivedmg(CObject* target)
	{
		if (Isolated(target) && IsReady(_Q))
			return me->CalculateDamage(target, get_spell_damage_table(8, 6, me->Level()) + (me->BonusAttackDamage() * .4), 2);

		return 0;
	}
	void Combo()
	{
		auto target = targetselector->GetTarget(1025);
		while (me->IsStealthed())
		{
			orbwalker->UseOrbWalker = false;
		}
		orbwalker->UseOrbWalker = true;

		if (target != nullptr)
		{
			global::qdmg = GetSpellDamage(me, target, SpellSlot::Q);
			global::wdmg = GetSpellDamage(me, target, SpellSlot::W);
			global::edmg = GetSpellDamage(me, target, SpellSlot::E);
			global::rdmg = GetSpellDamage(me, target, SpellSlot::R);
			global::aadmg = GetSpellDamage(me, target, SpellSlot::AA);
			global::pdmg = passivedmg(target);
			ks(target);

			if (me->Position().Distance(target->Position()) <= 1025 && (me->Position().Distance(target->Position()) > me->GetRealAutoAttackRange(target) || target->Health() <= global::wdmg))
				CastSpell(target, 1, "KhazixW");

			if (me->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->GetSpellNameHash() == FNV("KhazixQLong"))
			{
				if (me->Position().Distance(target->Position()) <= 375)
					CastSpell(0, target);
			}
			else {
				if (me->Position().Distance(target->Position()) <= 325)
					CastSpell(0, target);
			}

			if (target->IsHero() && !IsReady(0) && !IsReady(1) && IsReady(3))
				CastSpell(3);
			//if (target->Health() <= global::qdmg + global::wdmg + global::edmg + global::rdmg)

			if (orbwalker->AfterAutoAttack())
			{
				CastSpell(0, target);
				CastSpell(target, 1, "KhazixW");
			}
		}

	}
	void LaneClear()
	{
		std::vector<CObject*> minions = Engine::GetMinionsAround(1025, 1);
		for (auto target : minions)
		{

			if (me->Position().Distance(target->Position()) <= 1025 && (me->Position().Distance(target->Position()) > me->GetRealAutoAttackRange(target) || target->Health() <= global::wdmg))
				CastSpell(target, 1, "KhazixW");


			if (me->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->GetSpellNameHash() == FNV("KhazixQLong"))
			{
				if (me->Position().Distance(target->Position()) <= 375)
					CastSpell(0, target);
			}
			else {
				if (me->Position().Distance(target->Position()) <= 325)
					CastSpell(0, target);
			}

			//if (target->Health() <= global::qdmg + global::wdmg + global::edmg + global::rdmg)

			if (orbwalker->AfterAutoAttack())
			{
				CastSpell(0, target);
				CastSpell(target, 1, "KhazixW");
			}
		}
		std::vector<CObject*> jungles = Engine::GetJunglesAround(1025, 2);
		for (auto target : jungles)
		{

			if (me->Position().Distance(target->Position()) <= 1025 && (me->Position().Distance(target->Position()) > me->GetRealAutoAttackRange(target) || target->Health() <= global::wdmg))
				CastSpell(target, 1, "KhazixW");


			if (me->GetSpellBook()->GetSpellSlotByID(0)->GetSpellData()->GetSpellNameHash() == FNV("KhazixQLong"))
			{
				if (me->Position().Distance(target->Position()) <= 375)
					CastSpell(0, target);
			}
			else {
				if (me->Position().Distance(target->Position()) <= 325)
					CastSpell(0, target);
			}

			//if (target->Health() <= global::qdmg + global::wdmg + global::edmg + global::rdmg)

			if (orbwalker->AfterAutoAttack())
			{
				CastSpell(0, target);
				CastSpell(target, 1, "KhazixW");
			}
		}
	}
	void LastHit()
	{
		std::vector<CObject*> minions = Engine::GetMinionsAround(1025, 1);
		for (auto target : minions)
		{

			if (target->Health() <= global::wdmg)
				CastSpell(target, 1, "KhazixW");


			if (target->Health() <= global::qdmg)
				CastSpell(0, target);

			//if (target->Health() <= global::qdmg + global::wdmg + global::edmg + global::rdmg)
		}
		std::vector<CObject*> jungles = Engine::GetJunglesAround(1025, 2);
		for (auto target : jungles)
		{

			if (target->Health() <= global::wdmg)
				CastSpell(target, 1, "KhazixW");


			if (target->Health() <= global::qdmg)
				CastSpell(0, target);

		}
	}
	void Harass()
	{
		auto target = targetselector->GetTarget(-1);
		if (target != nullptr)
		{

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