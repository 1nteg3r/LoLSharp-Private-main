#pragma once
class Udyr : public ModuleManager {
private:
	CheckBox* Stack;

public:
	Udyr()
	{

	}

	~Udyr()
	{

	}

	void Draw()
	{

	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Udyr", "Udyr");
		auto ComboSet = menu->AddMenu("ComboSet", "Combo Settings");

		Stack = ComboSet->AddCheckBox("Stack", "Keep Stacks up", true);

		//ComboMenu 

	}

	void Tick()
	{

		if (Stack->Value)
		{
			if (Engine::GetEnemyCount(1000, me->Position()) < 1 && me->HasBuff("udyrmonkeyagilitybuff") && me->GetBuffManager()->GetBuffEntryByName("udyrmonkeyagilitybuff")->GetBuffEndTime() - Engine::GameGetTickCount() <= .2f)
			{
				//	printf("end: %.0f | game: %.0f\n", me->GetBuffManager()->GetBuffEntryByName("udyrmonkeyagilitybuff")->GetBuffEndTime(), Engine::GameGetTickCount());
				if (IsReady(_E))
					CastSpell(_E);
				else if (IsReady(_W))
					CastSpell(_W);
				else if (IsReady(_R))
					CastSpell(_R);
				else if (IsReady(_Q))
					CastSpell(_Q);
			}
		}

		if (global::mode== ScriptMode::Combo)
		{

			//orbwalker->OrbWalk(targetselector->GetTarget(_Q), false);
			auto target = targetselector->GetTarget(_Q);
			global::rdmg = GetSpellDamage(me, target, SpellSlot::R);
			global::qdmg = GetSpellDamage(me, target, SpellSlot::Q);

			if (Engine::GetEnemyCount(1000, me->Position()) > 0 && Engine::GetEnemyCount(400, me->Position()) == 0 && IsReady(_E))
				CastSpell(_E);


			if (orbwalker->AfterAutoAttack())
			{
				if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrBearAttack") //after turtle stance
				{
					//printf("target afterbearatt\n");
					if (IsReady(_R) && target->Health() <= global::rdmg)
						CastSpell(_R);
					else if (IsReady(_Q))
						CastSpell(_Q);
					else if (!IsReady(_Q) && IsReady(_R))
						CastSpell(_R);
				}
				if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrTurtleAttack" && IsReady(_R)) //after turtle stance
				{
					CastSpell(_R);
				}
				if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrTigerAttack" && IsReady(_R)) //after turtle stance
				{
					CastSpell(_R);
				}

				if (target->GetBuffManager()->GetBuffEntryByName("UdyrTigerPunchBleed")->GetBuffStartTime() < Engine::GameGetTickCount() - .8f && IsReady(_Q) && me->BuffCount("udyrtigerpunch") != 3) //double Q strike
				{
					CastSpell(_Q);

				}
				if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrBasicAttack") //turtle
				{
					if (me->HealthPercent() <= 50)
					{
						if (!IsReady(_R) && IsReady(_W))
						{
							CastSpell(_W);
						}
						if (!IsReady(_W) && IsReady(_Q) && !IsReady(_R))
						{

							CastSpell(_Q);
						}
					}
					else
					{
						if (IsReady(_Q))
						{
							CastSpell(_Q);
						}
					}
				}
			}

			//for (auto actora : global::objects)
			//{
			//	CObject* target = (CObject*)actora.actor;


			//	//if (target->GetBuffManager()->GetBuffEntryByName("UdyrTigerPunchBleed")->GetBuffStartTime() < Game::GetTickCount() - .8f && IsReady(_R)) //double Q strike
			//	//{
			//	//	CastSpell(_R);

			//	//}
			//	//if (target->GetBuffManager()->GetBuffEntryByName("UdyrTigerPunchBleed")->GetBuffStartTime() < Game::GetTickCount() - .8f && IsReady(_Q) && me->BuffCount("udyrtigerpunch") != 3) //double Q strike
			//	//{
			//	//	CastSpell(_Q);

			//	//}

			//}


			if (orbwalker->AfterAutoAttack())
			{
				auto target = targetselector->GetTarget(800);

			}


		}
		if (global::mode== ScriptMode::Mixed)
		{
			//orbwalker->OrbWalk(targetselector->GetTarget(_Q), false);
			auto target = targetselector->GetTarget(-1);
			if (target != nullptr)
			{
				if (target->IsValidTarget() && me->IsInAutoAttackRange(target))
				{
					if (orbwalker->AfterAutoAttack())
					{
						if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrBearAttack" && IsReady(_R)) //after turtle stance
						{
							CastSpell(_Q);
						}
						if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrTurtleAttack" && IsReady(_R)) //after turtle stance
						{
							CastSpell(_R);
						}
						if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrTigerAttack" && IsReady(_R)) //after turtle stance
						{
							CastSpell(_R);
						}

						if (target->GetBuffManager()->GetBuffEntryByName("UdyrTigerPunchBleed")->GetBuffStartTime() < Engine::GameGetTickCount() - .8f && IsReady(_Q) && me->BuffCount("udyrtigerpunch") != 3) //double Q strike
						{
							CastSpell(_Q);

						}
						if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrBasicAttack") //turtle
						{
							if (me->HealthPercent() <= 50)
							{
								if (!IsReady(_R) && IsReady(_W))
								{
									CastSpell(_W);
								}
								if (!IsReady(_W) && IsReady(_Q) && !IsReady(_R))
								{

									CastSpell(_Q);
								}
							}
							else
							{
								if (IsReady(_Q))
								{
									CastSpell(_Q);
								}
							}
						}
					}
				}
			}
		}

		if (global::mode== ScriptMode::LaneClear)
		{
			//orbwalker->OrbWalk(targetselector->GetTarget(_Q), false);
			auto target = targetselector->GetTarget(-1);

			/*		if (!Engine::GetMinionCount(400, me->Pos2D()) && IsReady(_E))
						CastSpell(_Q);
					else if (!Engine::GetMinionCount(400, me->Pos2D()) && !IsReady(_E) && IsReady(_W))
						CastSpell(_W);*/
			if (target != nullptr)
			{
				if (target->IsValidTarget() && me->IsInAutoAttackRange(target))
				{
					if (orbwalker->AfterAutoAttack())
					{
						if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrBearAttack" && IsReady(_R)) //after turtle stance
						{
							//printf("target afterbearatt\n");

							CastSpell(_Q);
						}
						if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrTurtleAttack" && IsReady(_R)) //after turtle stance
						{
							CastSpell(_R);
						}
						if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrTigerAttack" && IsReady(_R)) //after turtle stance
						{
							CastSpell(_R);
						}

						if (target->GetBuffManager()->GetBuffEntryByName("UdyrTigerPunchBleed")->GetBuffStartTime() < Engine::GameGetTickCount() - .8f && IsReady(_Q) && me->BuffCount("udyrtigerpunch") != 3) //double Q strike
						{
							CastSpell(_Q);

						}

					}
					if (me->GetSpellBook()->GetActiveSpellEntry() && me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName() == "UdyrBasicAttack") //turtle
					{
						if (me->HealthPercent() <= 50)
						{
							if (!IsReady(_R) && IsReady(_W))
							{
								CastSpell(_W);
							}
							if (!IsReady(_W) && IsReady(_Q) && !IsReady(_R))
							{

								CastSpell(_Q);
							}
						}
						else
						{
							if (IsReady(_Q))
							{
								CastSpell(_Q);
							}
						}
					}
				}
			}
		}

		if (global::mode== ScriptMode::Fly)
		{
			if (IsReady(_E))
				CastSpell(_E);
			else if (!IsReady(_E) && IsReady(_W))
				CastSpell(_W);
		}
	}
};