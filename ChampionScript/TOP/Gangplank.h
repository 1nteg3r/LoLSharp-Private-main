

class Gangplank : public ModuleManager {
private:


public:
	PredictionInput Q = PredictionInput({ 625 });
	PredictionInput W = PredictionInput({ });
	PredictionInput E = PredictionInput({ 1000 });
	PredictionInput R = PredictionInput({  });

	Gangplank()
	{

	}

	~Gangplank()
	{

	}

	std::vector<Barrel> Barrels = {};
	float LastCastE;
	Vector2 LastEPos;
	float LastCondition;
	Vector3 Kek;
	bool ActorCacheContains(std::vector<Barrel> list, uint32_t actorcheck)
	{
		bool skip = false;
		if ((list.size() > 0) && (list.size() != 0))
		{
			for (int i = 0; i < list.size();)
			{
				auto Actor = (uint32_t)list[i].Bottle;

				if (Actor == actorcheck)
				{
					skip = true;
					break;
				}
				i++;
			}
		}

		return skip;
	}

	void AddBarrel(uint32_t barrel32, float time)
	{
		if (!ActorCacheContains(Barrels, barrel32))
		{
			Barrel barrel;
			barrel.Bottle = (CObject*)barrel32;
			barrel.CreationTime = time;
			Barrels.push_back(barrel);
		}
	}

	void BarrelCleaner()
	{
		Barrels.erase(
			std::remove_if(Barrels.begin(), Barrels.end(),
				[&](Barrel o) {
					return !o.Bottle->IsTargetable() || o.Bottle->Health() == 0 || o.Bottle->GetSkinData()->GetSkinHash() != SkinHash::GangplankBarrel; }),
			Barrels.end());
	}

	std::vector<Barrel> ChainedBarrels(Barrel explodeBarrel)
	{

		auto level1 = from(Barrels)
			>> where([&](const Barrel& x) { return x.Bottle->Distance(explodeBarrel.Bottle) < 700.f; });

		auto level2 = from(Barrels)
			>> where([&](const Barrel& x) { return level1
				>> any([&](const Barrel& y) { return y.Bottle->Distance(x.Bottle) < 700.f; }); });

		auto level3 = from(Barrels)
			>> where([&](const Barrel& x) { return level2
				>> any([&](const Barrel& y) { return y.Bottle->Distance(x.Bottle) < 700.f; }); });

		return level3 >> to_vector();
	}

	std::vector<Barrel> AttackableBarrels(int delay = 0)
	{
		auto time = me->Level() >= 13 ?
			500 :
			me->Level() >= 7 ?
			1000 :
			2000;

		auto meelebarrels = from(Barrels)
			>> where([&](const Barrel& x) {
			auto barrelBuff = x.Bottle->GetBuffManager()->GetBuffCacheByFNVHash(FNV("gangplankebarrelactive"));
			return me->IsInAutoAttackRange(x.Bottle)
				&& (Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f >= 2 * time - Engine::GetPing() - me->AttackCastDelay() * 1000 + 50 - delay
					|| (Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f >= time - Engine::GetPing() - me->AttackCastDelay() * 1000 + 50 - delay && x.Bottle->Health() == 2
						&& Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f <= time) ?
					true : false
					|| x.Bottle->Health() == 1); });

		return meelebarrels >> to_vector();
	}

	std::vector<Barrel> QableBarrels(int delay = 0)
	{
		auto time = me->Level() >= 13 ?
			500 :
			me->Level() >= 7 ?
			1000 :
			2000;

		auto qbarrel = from(Barrels)
			>> where([&](const Barrel& x) {
			auto barrelBuff = x.Bottle->GetBuffManager()->GetBuffCacheByFNVHash(FNV("gangplankebarrelactive"));
			return Q.IsInRange(x.Bottle)
				&& (Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f >= 2 * time - Engine::GetPing() - 350 + 50 - delay
					|| (Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f >= time - Engine::GetPing() - 350 + 50 - delay && x.Bottle->Health() == 2
						&& Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f <= time) ?
					true : false
					|| x.Bottle->Health() == 1); });

		return qbarrel >> to_vector();
	}

	std::vector<Barrel> DelayedBarrels(int miliseconds = 0)
	{
		auto time = me->Level() >= 13 ?
			500 :
			me->Level() >= 7 ?
			1000 :
			2000;

		auto qbarrel = from(Barrels)
			>> where([&](const Barrel& x) {
			auto barrelBuff = x.Bottle->GetBuffManager()->GetBuffCacheByFNVHash(FNV("gangplankebarrelactive"));
			return Q.IsInRange(x.Bottle)
				&& (Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f >= 2 * time - Engine::GetPing() - 350 + 50 - miliseconds
					|| (Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f >= time - Engine::GetPing() - 350 + 50 - miliseconds && x.Bottle->Health() == 2
						&& Engine::GameTimeTickCount() - barrelBuff.starttime * 1000.f <= time) ?
					true : false
					|| x.Bottle->Health() == 1); });

		return qbarrel >> to_vector();
	}

	void Draw()
	{

		for (auto barrel : Barrels)
		{
			XPolygon::DrawCircle(barrel.Bottle->Position(), 50, ImVec4(255, 0, 255, 0), 1.0f);
			if (ChainedBarrels(barrel).size() >= 2)
				XPolygon::DrawCircle(barrel.Bottle->Position(), 50, ImVec4(255, 255, 0, 0), 1.0f);
		}


	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Gangplank", "Gangplank");
	}
	void Combo()
	{
		if (Engine::GameTimeTickCount() - LastCondition >= 100 + Engine::GetPing())
		{
			for (auto enemy : Engine::GetHerosAround(2000.f, 1))
			{
				Vector3 pred = prediction->GetPrediction(enemy, 0.5f).UnitPosition();
				if (IsReady(_Q) && IsReady(_E))
				{

					for (auto barrel : QableBarrels(350))
					{
						auto nbarrels = ChainedBarrels(barrel);
						if (from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Position().Distance(pred) <= 990.f; })
							&& !(from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Position().Distance(pred) <= 330.f; })))
						{
							for (int i = 990; i >= 400; i -= 20)
							{
								auto mbarrels = from(nbarrels) >> where([&](const Barrel& x) { return x.Bottle->Position().Distance(pred) <= i; }) >> orderby([&](const Barrel& x) { return x.Bottle->Position().Distance(pred); }) >> to_vector();


								for (auto mbarrel : mbarrels)
								{
									auto pos = mbarrel.Bottle->Position().Extended(pred, i - 330);


									if (me->Position().Distance(pos) < E.Range)
									{
										orbwalker->UseOrbWalker = false;
										_DelayAction->Add((int)(100 + Engine::GetPing()), []() {
											orbwalker->UseOrbWalker = true;
											});

										CastSpell(_E, Engine::WorldToScreen(pos));
										LastCondition = Engine::GameTimeTickCount();
										return;
									}
								}
							}
						}
					}

					for (auto barrel : QableBarrels())
					{
						auto nbarrels = ChainedBarrels(barrel);
						if (barrel.Bottle->Distance(pred) <= 330 + 660 + 660 && !(barrel.Bottle->Distance(pred) <= 330 + 660) && me->GetSpellBook()->GetSpellSlotByID(_E)->Ammo() >= 2)
						{
							for (int i = 330 + 660 + 660; i >= 380 + 660; i -= 20)
							{
								if (barrel.Bottle->Distance(pred) <= i)
								{
									auto pos1 = barrel.Bottle->Position().Extended(pred, 660);
									auto pos2 = barrel.Bottle->Position().Extended(pred, i - 330);
									if (E.IsInRange(pos1) && E.IsInRange(pos2)
										&& !Engine::IsWall(pos1) && !Engine::IsWall(pos2))
									{
										orbwalker->UseOrbWalker = false;
										_DelayAction->Add((int)(100 + Engine::GetPing() + 875), []() {
											orbwalker->UseOrbWalker = true;
											});
										CastSpell(_E, Engine::WorldToScreen(pos1));

										_DelayAction->Add((int)(550), [=]() {
											CastSpell(_Q, barrel.Bottle);
											});

										_DelayAction->Add((int)(875), [=]() {
											CastSpell(_E, Engine::WorldToScreen(pos2));
											});
										LastCondition = Engine::GameTimeTickCount() + 875;
										return;
									}
								}
							}
						}
						for (auto nbarrel : nbarrels)
						{
							if (nbarrel.Bottle->Distance(pred) <= 330 + 660 + 660 && !(nbarrel.Bottle->Distance(pred) <= 330 + 660) && me->GetSpellBook()->GetSpellSlotByID(_E)->Ammo() >= 2)
							{
								for (int i = 330 + 660 + 660; i >= 380 + 660; i -= 20)
								{
									if (nbarrel.Bottle->Distance(pred) <= i)
									{
										auto pos1 = nbarrel.Bottle->Position().Extended(pred, 660);
										auto pos2 = nbarrel.Bottle->Position().Extended(pred, i - 330);
										if (E.IsInRange(pos1) && E.IsInRange(pos2)
											&& !Engine::IsWall(pos1) && !Engine::IsWall(pos2))
										{
											orbwalker->UseOrbWalker = false;
											_DelayAction->Add((int)(100 + Engine::GetPing() + 875), []() {
												orbwalker->UseOrbWalker = true;
												});
											CastSpell(_E, Engine::WorldToScreen(pos1));

											_DelayAction->Add((int)(550), [=]() {
												CastSpell(_Q, barrel.Bottle);
												});

											_DelayAction->Add((int)(875), [=]() {
												CastSpell(_E, Engine::WorldToScreen(pos2));
												});
											LastCondition = Engine::GameTimeTickCount() + 875;
											return;
										}

									}
								}
							}
						}
					}
				}
			}


			for (auto enemy : Engine::GetHerosAround(2000.f, 1))
			{
				Vector3 pred = prediction->GetPrediction(enemy, 0.5f).UnitPosition();
				if (orbwalker->CanAttack() && IsReady(_E))
				{

					for (auto barrel : AttackableBarrels(350))
					{
						auto nbarrels = ChainedBarrels(barrel);
						if (from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Position().Distance(pred) <= 990.f; })
							&& !(from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Position().Distance(pred) <= 330.f; })))
						{
							for (int i = 990; i >= 400; i -= 20)
							{
								auto mbarrels = from(nbarrels) >> where([&](const Barrel& x) { return x.Bottle->Position().Distance(pred) <= i; }) >> orderby([&](const Barrel& x) { return x.Bottle->Position().Distance(pred); }) >> to_vector();


								for (auto mbarrel : mbarrels)
								{
									auto pos = mbarrel.Bottle->Position().Extended(pred, i - 330);
									if (me->Position().Distance(pos) < E.Range)
									{
										orbwalker->UseOrbWalker = false;
										_DelayAction->Add((int)(100 + Engine::GetPing()), []() {
											orbwalker->UseOrbWalker = true;
											});

										CastSpell(_E, Engine::WorldToScreen(pos));
										LastCondition = Engine::GameTimeTickCount();
										return;
									}
								}
							}
						}
					}

					for (auto barrel : AttackableBarrels())
					{
						auto nbarrels = ChainedBarrels(barrel);
						if (barrel.Bottle->Distance(pred) <= 330 + 660 + 660 && !(barrel.Bottle->Distance(pred) <= 330 + 660) && me->GetSpellBook()->GetSpellSlotByID(_E)->Ammo() >= 2)
						{
							for (int i = 330 + 660 + 660; i >= 380 + 660; i -= 20)
							{
								if (barrel.Bottle->Distance(pred) <= i)
								{
									auto pos1 = barrel.Bottle->Position().Extended(pred, 660);
									auto pos2 = barrel.Bottle->Position().Extended(pred, i - 330);
									if (E.IsInRange(pos1) && E.IsInRange(pos2)
										&& !Engine::IsWall(pos1) && !Engine::IsWall(pos2))
									{
										orbwalker->UseOrbWalker = false;
										_DelayAction->Add((int)(100 + Engine::GetPing() + 875), []() {
											orbwalker->UseOrbWalker = true;
											});
										CastSpell(_E, Engine::WorldToScreen(pos1));

										_DelayAction->Add((int)(550), [=]() {
											orbwalker->IssueAttack(barrel.Bottle);
											});

										_DelayAction->Add((int)(875), [=]() {
											CastSpell(_E, Engine::WorldToScreen(pos2));
											});
										LastCondition = Engine::GameTimeTickCount() + 875;
										return;
									}
								}
							}
						}
						for (auto nbarrel : nbarrels)
						{
							if (nbarrel.Bottle->Distance(pred) <= 330 + 660 + 660 && !(nbarrel.Bottle->Distance(pred) <= 330 + 660) && me->GetSpellBook()->GetSpellSlotByID(_E)->Ammo() >= 2)
							{
								for (int i = 330 + 660 + 660; i >= 380 + 660; i -= 20)
								{
									if (nbarrel.Bottle->Distance(pred) <= i)
									{
										auto pos1 = barrel.Bottle->Position().Extended(pred, 660);
										auto pos2 = barrel.Bottle->Position().Extended(pred, i - 330);
										if (E.IsInRange(pos1) && E.IsInRange(pos2)
											&& !Engine::IsWall(pos1) && !Engine::IsWall(pos2))
										{
											orbwalker->UseOrbWalker = false;
											_DelayAction->Add((int)(100 + Engine::GetPing() + 875), []() {
												orbwalker->UseOrbWalker = true;
												});
											CastSpell(_E, Engine::WorldToScreen(pos1));

											_DelayAction->Add((int)(550), [=]() {
												CastSpell(_Q, barrel.Bottle);
												});

											_DelayAction->Add((int)(875), [=]() {
												CastSpell(_E, Engine::WorldToScreen(pos2));
												});
											LastCondition = Engine::GameTimeTickCount() + 875;
											return;
										}

									}
								}
							}
						}
					}
				}
			}


			for (auto enemy : Engine::GetHerosAround(2000.f, 1))
			{
				Vector3 pred = prediction->GetPrediction(enemy, 0.5f).UnitPosition();
				if (IsReady(_Q))
				{
					for (auto barrel : QableBarrels())
					{
						auto nbarrels = ChainedBarrels(barrel);
						if (from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Position().Distance(pred) <= 330.f; }))
						{
							orbwalker->UseOrbWalker = false;
							_DelayAction->Add((int)(100 + Engine::GetPing()), []() {
								orbwalker->UseOrbWalker = true;
								});

							if (CastSpell(_Q, barrel.Bottle))
							{
								LastCondition = Engine::GameTimeTickCount();
								return;
							}
						}
					}
				}
			}

			for (auto enemy : Engine::GetHerosAround(2000.f, 1))
			{
				Vector3 pred = prediction->GetPrediction(enemy, 0.5f).UnitPosition();
				if (orbwalker->CanAttack())
				{
					for (auto barrel : AttackableBarrels())
					{
						auto nbarrels = ChainedBarrels(barrel);
						if (from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Position().Distance(pred) <= 330.f; }))
						{
							orbwalker->UseOrbWalker = false;
							_DelayAction->Add((int)(100 + Engine::GetPing()), []() {
								orbwalker->UseOrbWalker = true;
								});

							orbwalker->IssueAttack(barrel.Bottle);
							LastCondition = Engine::GameTimeTickCount();
							return;
						}
					}
				}
			}
		}

		if (me->GetSpellBook()->GetSpellSlotByID(_E)->Ammo() >= 2 && IsReady(_E) /*&& BadaoGangplankVariables.ComboE1.GetValue<bool>()*/)
		{
			auto target = targetselector->GetTarget(E.Range);
			if (target->IsValidTarget())
			{
				Vector3 pred = prediction->GetPrediction(target, 0.5f).UnitPosition();
				/*if (!(from(Barrels) >> any([&](const Barrel& x) {return (x.Bottle->Distance(pred) <= 660.f); })) &&
					Barrels.size() < 1 || !(from(Barrels) >> any([&](const Barrel& x) {return (x.Bottle->Distance(pred) <= 660.f); })) && (from(Barrels) >> any([&](const Barrel& x) {return (x.Bottle->Distance(me) > 660.f); })))
					CastSpell(_E, Engine::WorldToScreen(pred));*/
				if (!(from(Barrels) >> any([&](const Barrel& x) {return (x.Bottle->Distance(pred) <= 660.f); })) && (from(Barrels) >> any([&](const Barrel& x) {return (x.Bottle->Distance(me) > 625.f); }))
					|| !(from(Barrels) >> any([&](const Barrel& x) {return (x.Bottle->Distance(pred) <= 660.f); })) && Barrels.size() == 0)
					CastSpell(_E, Engine::WorldToScreen(pred));
			}
		}

		if (IsReady(_Q)&& 1 ==2)
		{
			auto target = targetselector->GetTarget(Q.Range);
			if (target->IsValidTarget())
			{
				bool useQ = true;
				for (auto barrel : DelayedBarrels(1000))
				{
					auto nbarrels = ChainedBarrels(barrel);
					if (IsReady(_E) && from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Distance(target) <= 660.f + target->BoundingRadius(); })
						&& !(from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Distance(target) <= 330.f + target->BoundingRadius(); })))
					{
						useQ = false;
						break;
					}
					else if (from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Distance(target) <= 330.f + target->BoundingRadius(); }))
					{
						useQ = false;
						break;
					}
				}

				if (1/*BadaoGangplankVariables.ComboQSave.GetValue<bool>()*/)
				{
					for (auto barrel : DelayedBarrels(10000))
					{
						auto nbarrels = ChainedBarrels(barrel);
						for (auto enemy : Engine::GetHerosAround(2000.f, 1))
						{
							if (from(nbarrels) >> any([&](const Barrel& x) {return x.Bottle->Distance(enemy) <= 330.f + target->BoundingRadius(); }))
							{
								useQ = false;
								break;
							}
						}
						if (useQ == false)
							break;
					}
				}

				if (useQ)
				{
					CastSpell(_Q, target);
				}
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

		BarrelCleaner();

		orbwalker->UseOrbWalker = true;
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