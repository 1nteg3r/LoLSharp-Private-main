#pragma once

class Riven : public ModuleManager {
private:


public:
	PredictionInput Q = PredictionInput({ 625 });
	PredictionInput W = PredictionInput({ });
	PredictionInput E = PredictionInput({ 1000 });
	PredictionInput R = PredictionInput({  });

	bool canReset = true;

	Riven()
	{

	}

	~Riven()
	{

	}

	void Draw()
	{
		//if(me->GetAIManager()->IsMoving() == true and me->GetAIManager()->IsDashing() == false)std::cout << Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundthree")).starttime << std::endl;



	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Riven", "Riven");
	}

	bool CastQ(CObject* target)
	{
		if (castSpellOnce.state == 2)
			return false;

		if (0 < 4)
		{
			auto caststate = me->GetSpellBook()->GetCastState();
			if (!caststate[0])
				return false;
		}

		if (IsReady(0))
		{

			auto key = CheckKey(0);
			if (key)
			{
				if (SpellLastTime.count((int)0))
				{
					if (Engine::GameTimeTickCount() - SpellLastTime[(int)0] < 200)
					{
						return false;
					}
				}
				else
				{
					SpellLastTime.insert({ (int)0,Engine::GameTimeTickCount() });
				}
				SpellLastTime[(int)0] = Engine::GameTimeTickCount();

				if (orbwalker->IssueAttack(target))
				{
					Sleep(50);
					if (orbwalker->UseNormalCast->Value)
						PressKeyModShift(key);
					else
						KeyPress(key);

					//BlockInput(false);
					return true;
				}
			}

		}

		return false;
	}

	Vector3 QMovePos(CObject* Target, int a = 0)
	{
		if (Target && Target->IsHero() && Target->IsValidTarget(400))
		{
			auto TargetPos = me->Position();
			auto PlayerPos = Target->Position();
			auto TargetNorm = (TargetPos - PlayerPos).Normalized();

			auto i = -500;
			if (me->IsInAutoAttackRange(Target , 30.f))
			{
				i = 500;
			}

			auto EndPos = Vector3(TargetPos.x + (TargetNorm.x * i), TargetPos.y, TargetPos.z + (TargetNorm.z * i));
			return EndPos;
		}
		else
		{
			return me->Position().Extended(Engine::GetMouseWorldPosition(), me->Distance(Engine::GetMouseWorldPosition()) + 300);
		}
	}
	void Reset(int Q)
	{
		if (orbwalker->LastAATick() != 0 || !orbwalker->CanAttack())
		{
			Engine::SetTargetOnlyChampions(true);
			orbwalker->IssueMove(QMovePos(orbwalker->LastTarget, Q));
			Engine::SetTargetOnlyChampions(false);
			if (Q == 3)
			{
				std::this_thread::sleep_for(std::chrono::milliseconds(220));
			}
			else if (Q == 2)
			{
				std::this_thread::sleep_for(std::chrono::milliseconds(150));
			}
			else
			{
				std::this_thread::sleep_for(std::chrono::milliseconds(150));
			}

			orbwalker->LastAATick(0);
		}
		/*_DelayAction->Add(100, [=]() {
			orbwalker->LastAATick(0);
			canReset = true;
			});*/
	}

	void FastQ()
	{
		//if (!me->IsDashing())
		//	std::cout << (Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundthree")).starttime) << std::endl;
		auto Q1 = (Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundone")).starttime);
		auto Q2 = (Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundtwo")).starttime);
		auto Q3 = (Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundthree")).starttime);

		/*if (me->IsDashing())
			std::cout << Q3 << std::endl;*/

		if (Q1 > 0.20f && Q1 < 0.28f)
		{
			Reset(1);
		}

		if (Q2 > 0.20f && Q2 < 0.28f)
		{
			Reset(2);
		}

		if (Q3 > 0.32f && Q3 < 0.4f)
		{
			Reset(3);
		}

		/*if ( (Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundtwo")).starttime) < 0.123f)
		{
			if (canReset)
			{
				canReset = false;
				_DelayAction->Add(215, [=]() {
					Reset();
					});
			}
		}

		if ( (Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundthree")).starttime) < 0.223f)
		{
			if (canReset)
			{
				canReset = false;
				_DelayAction->Add(310, [=]() {
					Reset();
					});
			}
		}*/
	}

	void Combo()
	{
		/*if (IsReady(_Q) and 1 == 1 ) {
			auto target = targetselector->GetTarget(150 + 150 + 250 + me->AttackRange());
			if (target)
			{
				if (me->Distance(target) < me->AttackRange()) {
					if (((os.clock() - Orbwalker.LastAttackTime) > Orbwalker.LastWindup * 0.90 and (os.clock() - Orbwalker.LastAttackTime) < Orbwalker.LastWindup + 0.3)) {
						return Engine : ReleaseSpell("HK_SPELL1", Riven:QMovePos(target));
					}
					if (self.WTarget and self.WTarget.IsTargetable and (os.clock() - self.WTimer) < 0.3) ){
					return Engine : ReleaseSpell("HK_SPELL1", Riven:QMovePos(target));
							}
					else
						local ERange = 0
						if (Engine:SpellReady("HK_SPELL3")
							) {
							ERange = self.ERange;
						}
					if (self: KillCombo(target) >= target.Health and GetDist(myHero.Position, target.Position) < QRange + QRange + ERange - (target.MovementSpeed * 0.2) and GetDist(myHero.Position, target.Position) > QRange - 50) {

						if (myHero.AIData.Dashing == false) {
							return Engine : ReleaseSpell("HK_SPELL1", target.Position);
						}
					}
				}
			}
		}*/
		FastQ();
		auto target2 = targetselector->GetTarget(400.f);
		if (target2->IsValidTarget())
		{
			if (orbwalker->AfterAutoAttack())
			{
				CastQ(target2);
			}
		}

	}

	void LaneClear()
	{



	}
	void LastHit()
	{

	}
	void Harass()
	{


	}
	void Tick()
	{

		if (global::mode == ScriptMode::Combo)
		{
			Combo();
		}
		else if (global::mode == ScriptMode::LaneClear)
		{
			LaneClear();
		}
		else if (global::mode == ScriptMode::Mixed)
		{
			Harass();
		}
		else if (global::mode == ScriptMode::LastHit)
		{
			LastHit();
		}
	}
};