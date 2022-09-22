#pragma once
class TargetSelector : public ModuleManager {
public:
	enum DamageType
	{
		Magical,

		Physical,

		True
	};

	enum TargetingMode
	{
		AutoPriority,

		LowHP,

		MostAD,

		MostAP,

		Closest,

		NearMouse,

		LessAttack,

		LessCast,

		MostStack
	};

	int _focusTime = Engine::GameTimeTickCount();
	bool HasSenna = false;
	CObject* _selectedTargetObjAiHero = nullptr;

	TargetingMode Mode = TargetingMode::AutoPriority;
	DamageType _lastDamageType;

	CheckBox* FocusSelected;
	CheckBox* VulnerableCheck;
	CheckBox* ForceFocusSelected;
	CheckBox* ForceFocusSelectedKeys;
	KeyBind* ForceFocusSelectedK;
	KeyBind* ForceFocusSelectedK2;

	CheckBox* autoPriorityItem;

	CheckBox* ResetOnRelease;

	std::vector<std::string> targetmodename = { "AutoPriority",

		"LowHP",

		"MostAD",

		"MostAP",

		"Closest",

		"NearMouse",

		"LessAttack",

		"LessCast",

		"MostStack " };

	TargetSelector()
	{

	}

	~TargetSelector()
	{

	}

	void Draw()
	{
		if (_selectedTargetObjAiHero != nullptr && FocusSelected->Value)
			XPolygon::DrawCircle3D(_selectedTargetObjAiHero->Position(), 5, 35, D3DCOLOR_ARGB(255, 255, 0, 255), 2);

		//if (Targethero != nullptr)
		//	XPolygon::DrawCircle(Targethero->Position(), 100.f, ImVec4(255, 255, 0, 0));

	}
	CObject* GetNearMouseTarget(float distance = 12000)
	{

		// Version 2.0
		float lowestHP = FLT_MAX;
		float Distance = distance;
		CObject* target = nullptr;

		for (auto enemy : Engine::GetHerosAround(FLT_MAX, 1))
		{

			if (enemy->IsValidTarget())
			{
				if (enemy->Position().Distance(Engine::GetMouseWorldPosition()) < Distance)
				{
					target = enemy;
					lowestHP = me->GetTrueHp(enemy);
					Distance = enemy->Position().Distance(Engine::GetMouseWorldPosition());
				}
				/*if (target == nullptr)
				{
					if (me->GetTrueHp(enemy) < lowestHP)
					{
						target = enemy;
						lowestHP = me->GetTrueHp(enemy);
						Distance = enemy->Position().Distance(Engine::GetMouseWorldPosition());
					}
				}*/
			}
		}

		return target;
	}

	void Tick()
	{
		/* near mouse target selected*/
		if (GetAsyncKeyState(0x1) & 0x8000) //left click
		{
			walk_position = Engine::GetMouseWorldPosition();
			auto targetNear = GetNearMouseTarget(500);

			_selectedTargetObjAiHero = targetNear;
		}
		//else if (targetselector->ResetTarget->Value) //Insert 
		//{
		//	_selectedTargetObjAiHero = nullptr;
		//}
		if (_selectedTargetObjAiHero != nullptr)
		{
			if (!_selectedTargetObjAiHero->IsValidTarget())
				_selectedTargetObjAiHero = nullptr;
		}
		auto a = (ForceFocusSelectedK->Value
			|| ForceFocusSelectedK2->Value)
			&& ForceFocusSelectedKeys->Value;

		//_configMenu.Item("ForceFocusSelectedKeys").Permashow(SelectedTarget != null && a);
		//_configMenu.Item("ForceFocusSelected").Permashow(_configMenu.Item("ForceFocusSelected").GetValue<bool>());

		if (!ResetOnRelease->Value)
		{
			return;
		}

		if (SelectedTarget() != nullptr && !a)
		{
			if (!ForceFocusSelected->Value
				&& Engine::GameTimeTickCount() - _focusTime < 150)
			{
				if (!a)
				{
					_selectedTargetObjAiHero = nullptr;
				}
			}
		}
		else
		{
			if (a)
			{
				_focusTime = Engine::GameTimeTickCount();
			}
		}
	}

	float GetPriority(fnv::hash name)
	{
		if (priorities.count(name) == 0)
			return 1.f;

		int priority = priorities[name];
		return priority == 1 ? 1.f :
			priority == 2 ? 1.5f :
			priority == 3 ? 1.75f :
			priority == 4 ? 2.f : 2.5f;
	}

	CObject* SelectedTarget()
	{
		return (FocusSelected->Value
			? _selectedTargetObjAiHero
			: nullptr);
	}

	CObject* GetSelectedTarget()
	{
		return SelectedTarget();
	}

	bool IsValidTarget(CObject* target, float range = FLT_MAX, Vector3 rangeCheckFrom = Vector3::Zero)
	{
		//if (!(target->Position().DistanceSquared(rangeCheckFrom.IsValid() ? rangeCheckFrom : me->ServerPosition())
		//	< pow(range <= 0 ? me->GetRealAutoAttackRange(target) : range, 2)))
		//{
		//	auto kekw = me->ServerPosition();
		//	auto kekw2 = target->ServerPosition();

		//	printf("Size Heros %s\n", target->ChampionName().c_str());

		//	//std::cout << "Range : " << range << std::endl;
		//	//std::cout << "RangeFrom x : " << rangeCheckFrom.x << " y : " << rangeCheckFrom.y << " z : " << rangeCheckFrom.z << std::endl;
		//	//std::cout << "LocalPos x : " << kekw.x << " y : " << kekw.y << " z : " << kekw.z << std::endl;
		//	//std::cout << "Target Name : " << target->ChampionName().c_str() << std::endl;
		//	//std::cout << "Target x : " << kekw2.x << " y : " << kekw2.y << " z : " << kekw2.z << std::endl;


		//}

		if (target->IsValidTarget()
			&& target->Position().DistanceSquared(rangeCheckFrom.IsValid() ? rangeCheckFrom : me->ServerPosition())
			< pow(range <= 0 ? me->GetRealAutoAttackRange(target) : range, 2))
		{
			if (VulnerableCheck->Value)
			{
				if (target->IsInvulnerable())
				{
					return false;
				}
			}

			if (range <= 0)
			{
				switch (target->ChampionNameHash())
				{
				case FNV("Jax"):
				{
					if (target->HasBuff(FNV("JaxCounterStrike")))
						return false;

				}
				case FNV("Samira"):
				{
					if (target->HasBuff(FNV("SamiraW")) && me->IsRanged())
						return false;
				}
				case FNV("Gwen"):
				{
					if (target->HasBuff(FNV("GwenW")))
					{
						for (auto base : global::troyobjects)
						{
							CObject* troy = (CObject*)base;
							auto name = troy->NameHash();
							if (troy->IsVisible() && name == FNV("Gwen_Base_W_MistArea"))
							{
								if (!me->Position().IsInRange(troy->Position(), 480))
								{
									return false;
								}
							}
						}
					}

				}
				case FNV("Tryndamere"):
				{
					if (target->HasBuff(FNV("UndyingRage")) && target->Health() < 100)
						return false;
				}
				}
				if (HasSenna)
				{
					if (target->HasBuff(FNV("sennaecamo")) ||
						target->HasBuff(FNV("sennaewraithform")))
					{
						if (me->Distance(target) > 400.f)
						{
							return false;
						}
					}
				}

			}


			return true;
		}


		return false;
	}

	CObject* GetTarget(CObject* champion, float range, Vector3 rangeCheckFrom = Vector3::Zero)
	{
		int dmgtype = 1;

		if (me->TotalAbilityPower() > me->TotalAttackDamage())
			dmgtype = 2;

		if (IsValidTarget(SelectedTarget(), ForceFocusSelected->Value ? FLT_MAX : range, rangeCheckFrom))
		{
			return SelectedTarget();
		}

		if (IsValidTarget(SelectedTarget(), ForceFocusSelectedKeys->Value ? FLT_MAX : range, rangeCheckFrom))
		{
			if (ForceFocusSelectedK->Value || ForceFocusSelectedK2->Value)
			{
				return SelectedTarget();
			}
		}
		auto heros = Engine::GetHeros(1);

		auto targets = from(heros) >> where([&](CObject* target) { return IsValidTarget(target, range, rangeCheckFrom); });

		/*for (auto herotest : from(targets) >> orderby_descending([&](const auto & hero) { return champion->CalculateDamage(hero, 100, dmgtype) / (1 + hero->Health()) * GetPriority(hero->ChampionNameHash()); }) >> to_vector())
		{
			std::cout << herotest->ChampionName() << std::endl;
		}
		std::cout  << std::endl;*/

		//printf("Size Heros %d\nSize targets %d\n", heros.size(), (targets >> count()));

		if (targets >> count() > 0)
		{
			switch (Mode)
			{
			case TargetingMode::LowHP:
			{
				return targets >> orderby([](CObject* hero) { return hero->Health(); }) >> first_or_default();
			}
			case TargetingMode::MostAD:
			{
				return targets >> orderby_descending([](CObject* hero) { return hero->BaseAttackDamage() + hero->FlatAttackDamageMod(); }) >> first_or_default();
			}
			case TargetingMode::MostAP:
			{
				return targets >> orderby_descending([](CObject* hero) { return hero->BaseAbilityPower() + hero->FlatAbilityPowerMod(); }) >> first_or_default();
			}
			case TargetingMode::Closest:
			{
				return targets >> orderby([&](CObject* hero) { return (rangeCheckFrom.IsValid() ? rangeCheckFrom : champion->Position()).Distance(hero->Position()); }) >> first_or_default();
			}

			case TargetingMode::NearMouse:
			{
				return targets >> orderby([&](CObject* hero) { return hero->Position().Distance(Engine::GetMouseWorldPosition()); }) >> first_or_default();
			}

			case TargetingMode::AutoPriority:
			{
				return targets >> orderby_descending([&](CObject* hero) { return GetPriority(hero->ChampionNameHash()) * champion->CalculateDamage(hero, 100, dmgtype) / hero->Health(); }) >> first_or_default();
			}

			case TargetingMode::LessAttack:
			{
				return targets >> orderby_descending([&](CObject* hero) { return GetPriority(hero->ChampionNameHash()) * champion->CalculateDamage(hero, 100, 1) / hero->Health(); }) >> first_or_default();
			}

			case TargetingMode::LessCast:
			{
				return targets >> orderby_descending([&](CObject* hero) { return GetPriority(hero->ChampionNameHash()) * champion->CalculateDamage(hero, 100, 2) / hero->Health(); }) >> first_or_default();
			}
			case TargetingMode::MostStack:
			{
				return targets >> first_or_default();
			}
			}
		}

		//std::cout << "Return nullptr" << std::endl;
		return nullptr;
	}

	CObject* GetTarget(float range, Vector3 rangeCheckFrom = Vector3::Zero)
	{
		return GetTarget(
			me,
			range,
			rangeCheckFrom);
	}

	CObject* GetTarget(float range, bool(*function)(CObject*, CObject*))
	{
		auto heros = Engine::GetHerosAround(FLT_MAX, 1);
		auto units = from(heros) >> where([&](CObject* target) { return IsValidTarget(target, range, Vector3::Zero); }) >> to_vector();


		if (units.size() > 1)
		{
			sort(units.begin(), units.end(), function);
		}

		if (units.size() > 0)
		{
			return units[0];
		}
		else
		{
			return nullptr;
		}
	}



	void Init()
	{
		auto menu = NewMenu::CreateMenu("TargetSelector", "Target Selector");


		auto focusMenu = menu->AddMenu("FocusTargetSettings", "Focus Target Settings");
		FocusSelected = focusMenu->AddCheckBox("FocusSelected", "Focus selected target", true);

		ForceFocusSelected = focusMenu->AddCheckBox("ForceFocusSelected", "Only attack selected target", false);

		ForceFocusSelectedKeys = focusMenu->AddCheckBox("ForceFocusSelectedKeys", "Enable only attack selected Keys", false);


		ForceFocusSelectedK = focusMenu->AddKeyBind("ForceFocusSelectedK", "Only attack selected Key", VK_SPACE, false, false);
		ForceFocusSelectedK2 = focusMenu->AddKeyBind("ForceFocusSelectedK", "Only attack selected Key 2", VK_SPACE, false, false);
		ResetOnRelease = focusMenu->AddCheckBox("ResetOnRelease", "Reset selected target upon release", false);


		VulnerableCheck = menu->AddCheckBox("VulnerableCheck", "Check invulnerable target (beta)", false);

		auto AutoPriority = menu->AddMenu("AutoPriority", "Auto arrange priorities");
		/*autoPriorityItem = targetSelector->AddCheckBox("AutoPriority", "Auto arrange priorities", false, [&](CheckBox*, bool value) {
			autoPriorityItem = value;
		});*/
		AutoPriority->AddTooltip("5 = Highest Priority");
		for (auto pActor : global::enemyheros)
		{
			CObject* actor = (CObject*)pActor.actor;
			char buffer[50];
			sprintf(buffer, "TargetSelector %s Priority", pActor.name.c_str());
			if (priorities.count(actor->ChampionNameHash()) > 0)
			{
				priorities[actor->ChampionNameHash()] = AutoPriority->AddSlider(pActor.name.c_str(), buffer, priorities[actor->ChampionNameHash()], 1, 5, 1, [&](Slider* slid, int value) {
					priorities[fnv::hash_runtime(slid->Name)] = value;
					})->Value;
			}
		}

		Mode = (TargetingMode)menu->AddList("TargetingMode", "Target Mode", targetmodename, 0, [&](List*, int value)
			{
				Mode = (TargetingMode)value;
			})->Value;

		std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
		std::cout << "TargetSelector Loaded" << std::endl;


		for (auto enemy : Engine::GetHeros())
		{
			if (enemy->ChampionNameHash() == FNV("Senna"))
			{
				HasSenna = true;
			}
		}

	}
};

TargetSelector* targetselector;