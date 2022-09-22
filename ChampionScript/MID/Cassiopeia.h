#pragma once
bool sortCassiopeia(CObject* a, CObject* b);

class Cassiopeia : public ModuleManager {
private:
	structspell Q = SpellDatabase[FNV("CassiopeiaQ")];
	structspell W = SpellDatabase[FNV("CassiopeiaW")];
	double E[3] = { 2500,700,0.125 }; // speed , range , windup
	structspell R = SpellDatabase[FNV("CassiopeiaR")];
public:
	Cassiopeia()
	{

	}

	~Cassiopeia()
	{

	}

	void Draw()
	{

	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Cassiopeia", "Cassiopeia");
	}

	float CalcFangArrivalTime(CObject* unit)
	{
		return me->Distance(unit) / this->E[0] + this->E[2];
	}

	float PoisonDuration(CObject* unit)
	{
		for (auto buff : unit->GetBuffManager()->Buffs())
		{
			if (buff.namehash == FNV("cassiopeiaqdebuff") && buff.count > 0)
			{
				return buff.remaintime;
			}
			else if (buff.namehash == FNV("cassiopeiawpoison") && buff.count > 0)
			{
				return buff.remaintime;
			}
		}
		return 0;
	}

	void Combo(CObject* TargetQ, CObject* TargetW, CObject* TargetE, CObject* TargetR)
	{
		if (!me->IsAlive())
			return;

		if (TargetQ && IsReady(0))
		{
			if (this->PoisonDuration(TargetQ) < this->Q.delay)
			{
				(CastSpell(TargetQ, 0, "CassiopeiaQ"));
			}
		}

		if (TargetW && IsReady(1))
		{
			(CastSpell(1, TargetW));
		}


		if (this->PoisonDuration(TargetE) >= this->CalcFangArrivalTime(TargetE))
		{
			orbwalker->UseOrbWalker = false;
			if (TargetE && IsReady(2))
			{
				CastSpell(2, TargetE);
			}
		}
	}

	void Tick()
	{
		orbwalker->UseOrbWalker = true;
		if (global::mode== ScriptMode::Combo)
		{
			this->Combo(targetselector->GetTarget(this->Q.range, sortCassiopeia), targetselector->GetTarget(this->W.range, sortCassiopeia), targetselector->GetTarget(this->E[1], sortCassiopeia), targetselector->GetTarget(this->R.range, sortCassiopeia));
		}
	}
};



bool sortCassiopeia(CObject* a, CObject* b)
{
	return Cassiopeia().PoisonDuration(a) > Cassiopeia().PoisonDuration(b) &&
		me->CalculateDamage(a, 100, 2) / (1 + a->Health()) * GetPriority(a->ChampionNameHash()) >
		me->CalculateDamage(b, 100, 2) / (1 + b->Health()) * GetPriority(b->ChampionNameHash());
}