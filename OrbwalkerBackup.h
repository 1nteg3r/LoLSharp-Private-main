#pragma once
float AttackTimer = 0, CastTimer = 0, LastAttack = 0, LastCastEnd = 0, MoveTimer = 0;

struct SelfResetSpell
{
	int slot;
	int timer;
};

SelfResetSpell ResetSpell;

float BeginAttackTime = 0.0f;
float EndAttackTime = 0.0f;
float CanAttackTime = 0.0f;
float CanMoveTime = 0.0f;

float BeginReset = 0.0f;

std::unordered_map<std::string, int> ResetAASpells;

void OrbInit()
{
	ResetAASpells["Blitzcrank"] = _E, ResetAASpells["Camille"] = _Q, ResetAASpells["Chogath"] = _E, ResetAASpells["Darius"] = _W, ResetAASpells["DrMundo"] = _E, ResetAASpells["Elise"] = _W, ResetAASpells["Fiora"] = _E, ResetAASpells["Garen"] = _Q,
		ResetAASpells["Graves"] = _E, ResetAASpells["Kassadin"] = _W, ResetAASpells["Illaoi"] = _W, ResetAASpells["Jax"] = _W, /*ResetAASpells["Jayce"] = _W,*/ ResetAASpells["Kaisa"] = _R, ResetAASpells["Kayle"] = _E, ResetAASpells["Katarina"] = _E, ResetAASpells["Kindred"] = _Q,
		ResetAASpells["Leona"] = _Q, ResetAASpells["Lucian"] = _E, ResetAASpells["MasterYi"] = _W, ResetAASpells["Mordekaiser"] = _Q, ResetAASpells["Nautilus"] = _W, /*ResetAASpells["Nidalee"] = _Q,*/ ResetAASpells["Nasus"] = _Q,
		ResetAASpells["RekSai"] = _Q, ResetAASpells["Renekton"] = _W, ResetAASpells["Rengar"] = _Q, ResetAASpells["Riven"] = _Q, ResetAASpells["Sejuani"] = _E, ResetAASpells["Sett"] = _Q, ResetAASpells["Sivir"] = _W, ResetAASpells["Trundle"] = _Q,
		ResetAASpells["Vayne"] = _Q, ResetAASpells["Vi"] = _E, ResetAASpells["Volibear"] = _Q, ResetAASpells["MonkeyKing"] = _Q, ResetAASpells["XinZhao"] = _Q, ResetAASpells["Yorick"] = _Q;
}

class Orbwalker : public ModuleManager {
private:

public:
	unsigned int mode = ScriptMode::None;
	float LastShouldWait = 0.0f;
	bool UseOrbWalker = true;
	CObject* LastHitMinion = nullptr;
	CObject* AlmostLastHitMinion = nullptr;
	CObject* LaneClearMinion = nullptr;
	CObject* LastTarget = nullptr;
	CObject* LastLastHitMinion = nullptr;

	CheckBox* Interrupt;

	CheckBox* LaneClearHeroes;
	CheckBox* SupportMode;
	Slider* HoldRadius;
	Slider* MovementDelay;
	Slider* ExtraWindUpTime;

	CheckBox* LastHitPriority;
	CheckBox* PushPriority;
	Slider* ExtraFarmDelay;

	CheckBox* StickToTarget;

	CheckBox* AttackRange;
	CheckBox* AzirSoldierAttackRange;
	CheckBox* EnemyAttackRange;
	CheckBox* HoldRadiusBool;
	CheckBox* LasthittableMinions;

	Vector3 ForcedPosition = Vector3::Zero;

	Orbwalker()
	{

	}

	~Orbwalker()
	{

	}
	void Draw()
	{
		if (me->IsAlive() && AttackRange->Value)
		{
			XPolygon::DrawCircle(me->Position(), me->GetTrueAttackRange(), ImVec4(255, 0, 255, 255), 2.0f);
		}

		if (HoldRadiusBool->Value && HoldRadius->Value > 0) {
			XPolygon::DrawCircle(me->Position(), HoldRadius->Value, ImVec4(255, 144, 238, 144), 2.0f);
		}

		if (LasthittableMinions->Value) {
			if (LastHitMinion) {
				auto p = Engine::HpBarPos(LastHitMinion);

				Renderer::GetInstance()->DrawRect(ImVec2(p.x - 34, p.y - 9), ImVec2(p.x + 32, p.y + 1), D3DCOLOR_ARGB(255, 66, 174, 222), 2.f);
				//XPolygon::DrawCircle(LastHitMinion->Position(), LastHitMinion->BoundingRadius(), ImVec4(255, 255, 255, 255), 2.0f);
			}
			if (AlmostLastHitMinion && AlmostLastHitMinion != LastHitMinion) {
				auto p = Engine::HpBarPos(AlmostLastHitMinion);
				Renderer::GetInstance()->DrawRect(ImVec2(p.x - 34, p.y - 9), ImVec2(p.x + 32, p.y + 1), D3DCOLOR_ARGB(255, 255, 255, 255), 2.f);
				//XPolygon::DrawCircle(AlmostLastHitMinion->Position(), AlmostLastHitMinion->BoundingRadius(), ImVec4(255, 255, 69, 0), 2.0f);
			}
		}

	}
	void Init()
	{
		auto menu = Menu::CreateMenu("Orbwalker", "Orbwalker");

		auto hoykeysMenu = menu->AddMenu("Hotkeys", "Hotkeys");
		hoykeysMenu->AddKeyBind("Combo", "Combo", VK_KEY_Z, false, false, [&](KeyBind*, bool newValue) {
			if (newValue) {
				mode |= ScriptMode::Combo;
			}
			else {
				mode &= ~ScriptMode::Combo;
			}
		});

		hoykeysMenu->AddKeyBind("Harass", "Harass", VK_KEY_X, false, false, [&](KeyBind*, bool newValue) {
			if (newValue) {
				mode |= ScriptMode::Harass;
			}
			else {
				mode &= ~ScriptMode::Harass;
			}
		});

		hoykeysMenu->AddKeyBind("LaneClear", "Lane clear", VK_KEY_C, false, false, [&](KeyBind*, bool newValue) {
			if (newValue) {
				mode |= ScriptMode::LaneClear;
			}
			else {
				mode &= ~ScriptMode::LaneClear;
			}
		});

		hoykeysMenu->AddKeyBind("JungleClear", "JungleClear", VK_KEY_C, false, false, [&](KeyBind * self, bool newValue) {
			if (newValue) {
				mode |= ScriptMode::JungleClear;
			}
			else {
				mode &= ~ScriptMode::JungleClear;
			}
		});

		hoykeysMenu->AddKeyBind("LastHit", "Last hit", VK_KEY_V, false, false, [&](KeyBind*, bool newValue) {
			if (newValue) {
				mode |= ScriptMode::LastHit;
			}
			else {
				mode &= ~ScriptMode::LastHit;
			}
		});

		hoykeysMenu->AddKeyBind("Flee", "Flee", VK_KEY_Y, false, false, [&](KeyBind * self, bool newValue) {
			if (newValue) {
				mode |= ScriptMode::Fly;
			}
			else {
				mode &= ~ScriptMode::Fly;
			}
		});

		auto spellitemskeysMenu = menu->AddMenu("SpellsKeys", "Spells/Items Keys");
		Qspell = spellitemskeysMenu->AddKeyBind("Qspell", "Q Spell", VK_KEY_Q, false, false);
		Wspell = spellitemskeysMenu->AddKeyBind("Wspell", "W Spell", VK_KEY_W, false, false);
		Espell = spellitemskeysMenu->AddKeyBind("Espell", "E Spell", VK_KEY_E, false, false);
		Rspell = spellitemskeysMenu->AddKeyBind("Rspell", "R Spell", VK_KEY_R, false, false);
		Dspell = spellitemskeysMenu->AddKeyBind("Dspell", "D Spell", VK_KEY_D, false, false);
		Fspell = spellitemskeysMenu->AddKeyBind("Fspell", "F Spell", VK_KEY_F, false, false);
		ItemSlot1 = spellitemskeysMenu->AddKeyBind("ItemSlot1", "Item Slot 1", VK_KEY_1, false, false);
		ItemSlot2 = spellitemskeysMenu->AddKeyBind("ItemSlot2", "Item Slot 2", VK_KEY_2, false, false);
		ItemSlot3 = spellitemskeysMenu->AddKeyBind("ItemSlot3", "Item Slot 3", VK_KEY_3, false, false);
		ItemSlot4 = spellitemskeysMenu->AddKeyBind("ItemSlot4", "Item Slot 4", VK_KEY_4, false, false);
		ItemSlot5 = spellitemskeysMenu->AddKeyBind("ItemSlot5", "Item Slot 5", VK_KEY_5, false, false);
		ItemSlot6 = spellitemskeysMenu->AddKeyBind("ItemSlot6", "Item Slot 6", VK_KEY_6, false, false);
		ChampionOnly = spellitemskeysMenu->AddKeyBind("ChampionOnly", "Champion Only Key", VK_KEY_I, false, false);

		auto configurationMenu = menu->AddMenu("Configuration", "Configuration");
		Interrupt = configurationMenu->AddCheckBox("Interrupt", "Interrupt Spell Check", true);
		LaneClearHeroes = configurationMenu->AddCheckBox("LaneClearHeroes", "Attack heroes in laneclear", true);
		LaneClearHeroes->AddTooltip("It will attack heroes when lane clearing");
		//SupportMode = configurationMenu->AddCheckBox(("SupportMode" + ObjectManager::Player->SkinName).c_str(), "Support mode");
		HoldRadius = configurationMenu->AddSlider("HoldRadius", "Hold radius", 0, 0, 100);
		MovementDelay = configurationMenu->AddSlider("MovementDelay", "Movement delay", 100, 0, 500, 10);
		ExtraWindUpTime = configurationMenu->AddSlider("ExtraWindUpTime", "Extra windup time", 0, 0, 200, 10);

		auto farmingMenu = menu->AddMenu("Farming", "Farming");
		LastHitPriority = farmingMenu->AddCheckBox("LastHitPriority", "Prioritize lasthit over harass", true);
		PushPriority = farmingMenu->AddCheckBox("PushPriority", "Prioritize push over freeze", true);
		ExtraFarmDelay = farmingMenu->AddSlider("ExtraFarmDelay", "Extra farm delay", 0, -80, 80, 10);

		auto meleeMenu = menu->AddMenu("Melee", "Melee");
		StickToTarget = meleeMenu->AddCheckBox("StickToTarget", "Stick to target", false);

		auto drawingsMenu = menu->AddMenu("Drawings", "Drawings");
		AttackRange = drawingsMenu->AddCheckBox("AttackRange", "Attack range", true);
		/*if (IsAzir) {
			Config::Drawings::AzirSoldierAttackRange = drawingsMenu->AddCheckBox("AzirSoldierAttackRange", "Azir soldier attack range", true);
		}*/
		EnemyAttackRange = drawingsMenu->AddCheckBox("EnemyAttackRange", "Enemy attack range", true);
		HoldRadiusBool = drawingsMenu->AddCheckBox("HoldRadius", "Hold radius", true);
		LasthittableMinions = drawingsMenu->AddCheckBox("LasthittableMinions", "Lasthittable minions", true);
	}

	bool ShouldWait() {
		return Engine::GameGetTickCount() - LastShouldWait <= 0.4f || AlmostLastHitMinion != nullptr;
	}

	bool AttackInterrupt()
	{
		if ((global::LocalChampNameHash != FNV("Kalista") && me->GetBuffManager()->HasBuffType(BuffType::Blind)) ||
			(global::LocalChampNameHash == FNV("Jhin") && me->HasBuff("JhinPassiveReload")) ||
			(global::LocalChampNameHash == FNV("Kaisa") && me->HasBuff("KaisaE")))
		{
			return true;
		}
		return false;
	}

	bool CanAttack() {
		if (me->IsDashing() || AttackInterrupt())
			return false;

		if (global::LocalChampNameHash == FNV("Graves"))
		{
			double attackDelay = 0.740296828 * Engine::GetAttackDelay() - 0.07;

			if (Engine::GameGetTickCount() + Engine::GetLatency() + 0.025 >= LastAttack + attackDelay
				&& me->HasBuff("gravesbasicattackammo1"))
			{
				return true;
			}

			return false;
		}

		auto activeSpell = me->GetSpellBook()->GetActiveSpellEntry();
		if (activeSpell) {
			auto castInfo = activeSpell->GetSpellData();
			if (/*castInfo->ChannelIsInterruptedByAttacking() &&*/ (!activeSpell->IsInstantCast() || !activeSpell->SpellWasCast())) {
				return false;
			}
		}

		return Engine::GameGetTickCount() + Engine::GetLatency() + 0.025 > LastAttack + Engine::GetAnimationTime();
	}

	bool CanMove() {
		if (!me->ActionState(CharacterState::CanMove) || me->IsDashing()) {
			return false;
		} 

		auto activeSpell = me->GetSpellBook()->GetActiveSpellEntry();
		if (activeSpell) {
			auto castInfo = activeSpell->GetSpellData();
			if (!castInfo->CanMoveWhileChanneling() && (!activeSpell->IsInstantCast() || !activeSpell->SpellWasCast())) {
				return false;
			}
		}

		return Engine::GameGetTickCount() + Engine::GetLatency() > LastAttack + Engine::GetWindUpTime() + ExtraWindUpTime->Value * 0.001f;
	}

	bool AfterAutoAttack()
	{
		if (Engine::GameGetTickCount() > LastCastEnd + .02f && Engine::GameGetTickCount() < LastCastEnd + .12f)
		{
			return true;
		}
		return false;
	}

	bool CheckInterrupt()
	{
		return Interrupt->Value ? !me->IsAutoAttacking() || AfterAutoAttack() : true;
	}

	static void IssueMove()
	{
		if (Engine::IsChatOpen() || !me->ActionState(CharacterState::CanMove))
			return;

		if (Engine::GameGetTickCount() - last_movetoorder > humanizer_delay && me->ActionState(CharacterState::CanMove))
		{
			Click();
			last_movetoorder = Engine::GameGetTickCount();
		}
	}

	void MoveTo(Vector3 pos)
	{
		if (!CanMove() || Engine::GameGetTickCount() - last_movetoorder < MovementDelay->Value * 0.001f) {
			return;
		}

		if (Engine::IsChatOpen() || !me->ActionState(CharacterState::CanMove) || !me->IsAlive())
			return;

		//if (Engine::GameGetTickCount() - last_movetoorder > humanizer_delay)
		{
			KeyDown(ChampionOnly->Key);
			if (pos.IsValid() && !Engine::IsOutboundScreen(pos))
			{
				MouseClick(false, pos.x, pos.y);
			}
			else {
				Click();
			}
			KeyUp(ChampionOnly->Key);
			last_movetoorder = Engine::GameGetTickCount();
		}
	}

	void ResetAutoAttacks()
	{
		AttackTimer = 0;
		LastAttack = 0;
		LastCastEnd = 0;
		std::this_thread::sleep_for(std::chrono::milliseconds(10));
	}

	void DetectAutoAttacksAndSpells()
	{
		auto spell = me->GetSpellBook()->GetActiveSpellEntry();
		auto timer = Engine::GameGetTickCount();
		if (spell && spell->IsAutoAttack())
		{
			if (LastCastEnd != spell->MidTick())
			{
				Engine::BaseAttackSpeed = 1.f / (spell->Animation() * me->AttackSpeed());
				Engine::BaseWindUp = 1.f / (spell->Windup() * me->AttackSpeed());
				LastAttack = spell->StartTick();
				LastCastEnd = spell->MidTick();
			}
		}


		if (ResetSpell.slot != 1998)
		{
			if (global::LocalChampNameHash == FNV("Vayne"))
			{
				if (!me->HasBuff("vaynetumblebonus"))
					return;

				if (timer - ResetSpell.timer > 1)
				{
					ResetSpell.timer = Engine::GameGetTickCount();
					ResetAutoAttacks();
				}
			}
			else
			{
				if (!me->GetSpellBook()->GetSpellSlotByID(ResetSpell.slot)->IsReady() && me->GetSpellBook()->GetSpellSlotByID(ResetSpell.slot)->GetCastTime() < 0.25f && timer - ResetSpell.timer > 1)
				{
					ResetSpell.timer = Engine::GameGetTickCount();
					ResetAutoAttacks();
				}
			}
		}

		std::vector<CObject*> minions = Engine::GetMinionsAround(me->GetTrueAttackRange() + 550, 2);
		for (auto minion : minions)
		{
			auto active = minion->GetSpellBook()->GetActiveSpellEntry();
			if (active && active->isAutoAttack())
			{
				ActiveAttacks[minion->NetworkID()] = {
					(uint32_t)minion,
					active->targetID(),
					active->StartTick(),
					active->EndTick(),
					active->Windup(),
					active->Animation(),
					(active->GetSpellData()->MissileSpeed() == 0) ? FLT_MAX : active->GetSpellData()->MissileSpeed()
				};
			}
		}

		if (ActiveAttacks.size() > 0)
		{
			std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
			for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
			{
				auto id = it->first;
				auto data = it->second;
				if (timer >= data.endTime)
				{
					ActiveAttacks.erase(id);
				}
			}
		}
	}

	void IssueAttack(CObject* actor)
	{
		if (actor == nullptr || Engine::IsChatOpen() || (justevade->BlockAttack && justevade->Block))
			return;

		bool hero = actor->IsHero();

		Vector3 W2S_buffer = Engine::WorldToScreen(actor->Position());

		if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
		{
			if (hero)
			{
				KeyDown(ChampionOnly->Key);
			}
			else
			{
				W2S_buffer.y -= 10.f;
			}

			LastTarget = actor;
			if (actor == LastHitMinion)
				LastLastHitMinion = actor;

			AttackTimer = Engine::GameGetTickCount();
			MouseClick(false, W2S_buffer.x, W2S_buffer.y);

			if (hero)
			{
				KeyUp(ChampionOnly->Key);
			}
		}
	}

	Vector3 GetOrbwalkPosition() {
		if (ForcedPosition.IsValid()) {
			return ForcedPosition;
		}
		else if (me->IsMelee() && StickToTarget->Value && !(mode & ScriptMode::Fly) && LastTarget) {
			auto pathController = LastTarget->GetAIManager();
			if ((LastTarget->IsMonster() || LastTarget->IsHero()) && pathController->IsMoving() && me->ServerPosition().IsInRange(pathController->CurrentPosition(), me->GetTrueAttackRange(LastTarget) + 150.0f)) {
				auto way = LastTarget->GetWaypoints().back();
				return Engine::WorldToScreen(Vector3(way.x, me->Position().y, way.y));
			}
		}

		return Vector3::Zero;
		//return Engine::WorldToScreen(Engine::GetMouseWorldPosition());
	}
	CObject* GetTargetByType(OrbwalkerTargetType targetType) {
		switch (targetType) {
		case OrbwalkerTargetType::Hero: {
			return targetselector->GetTarget(0);
		}
		case OrbwalkerTargetType::Minion: {
			auto supportMode = false;

			if (!supportMode) {
				if (LastHitMinion) {
					if (AlmostLastHitMinion && AlmostLastHitMinion != LastHitMinion && AlmostLastHitMinion->IsSiegeMinion()) {
						return nullptr;
					}
					return LastHitMinion;
				}
				if (supportMode || ShouldWait()) {
					return nullptr;
				}
				if (mode & ScriptMode::LaneClear) {
					return LaneClearMinion;
				}
			}
			break;
		}
		case OrbwalkerTargetType::Monster: {
			CObject* monster = nullptr;
			float highestMaxHealth = 0.0f;
			auto minions = Engine::GetJunglesAround(me->GetTrueAttackRange() + 100.f, 2);
			for (auto minion : minions) {
				if (minion) {
					if (minion->MaxHealth() > highestMaxHealth) {
						monster = minion;
						highestMaxHealth = minion->MaxHealth();
					}
				}
			}
			return monster;
		}
		case OrbwalkerTargetType::Structure: {
			return nullptr;

			/*auto AIBases = Engine::GetAIBasesAround(10000);
			for (auto unit : AIBases) {
				if (unit->IsEnemy() && unit->IsTargetable() && unit->IsTurret() && me->Position().IsInRange(unit->Position(), me->GetTrueAttackRange(unit))) {
					return unit;
				}
			}*/
			break;
		}
		}
		return nullptr;
	}
	CObject * GetTarget()
	{
		if (mode & ScriptMode::Combo) {
			auto hero = GetTargetByType(OrbwalkerTargetType::Hero);
			if (hero) {
				return hero;
			}
		}
		if (mode & ScriptMode::Harass) {
			auto hero = GetTargetByType(OrbwalkerTargetType::Hero);
			if (hero) {
				return hero;
			}
		}

		if (mode & ScriptMode::LastHit) {
			auto minion = GetTargetByType(OrbwalkerTargetType::Minion);
			if (minion) {
				return minion;
			}
		}

		if (mode & ScriptMode::LaneClear) {
			auto structure = GetTargetByType(OrbwalkerTargetType::Structure);
			if (structure) {
				if (!LastHitPriority->Value) {
					return structure;
				}
				auto minion = GetTargetByType(OrbwalkerTargetType::Minion);

				if (minion && minion == LastHitMinion) {
					return minion;
				}
				if (!ShouldWait()) {
					return structure;
				}
			}
			else {
				auto hero = GetTargetByType(OrbwalkerTargetType::Hero);
				if (hero && LaneClearHeroes->Value && !LastHitPriority->Value) {
					return hero;
				}
				auto minion = GetTargetByType(OrbwalkerTargetType::Minion);

				if (minion && minion == LastHitMinion) {
					return minion;
				}
				if (hero && LaneClearHeroes->Value && !ShouldWait()) {
					return hero;
				}
				if (minion) {
					return minion;
				}
			}
		}

		if (mode & ScriptMode::JungleClear) {
			return GetTargetByType(OrbwalkerTargetType::Monster);
		}

		return nullptr;
	}

	float GetHealthPrediction(CObject* unit, float delta)
	{
		auto predHealth = unit->Health() + unit->PhysicalShield();
		float timer = Engine::GameGetTickCount();
		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
		{
			auto attack = it->second;
			if (attack.target == unit->Index())
			{
				delta += Engine::GetPing() * 0.0005f;
				auto damage = 0.0f;
				auto source = (CObject*)attack.source;
				auto timeTillHit = attack.startTime + attack.windUpTime - Engine::GameGetTickCount();
				if (attack.projectileSpeed != FLT_MAX) {
					timeTillHit += max(0.0f, unit->Position().Distance(source->Position()) - source->BoundingRadius()) / attack.projectileSpeed + 0.05f;
				}

				while (timeTillHit < delta) {
					if (timeTillHit > 0.0f) {
						damage += source->GetTotalAD();
					}
					timeTillHit += attack.animationTime;
				}

				predHealth -= damage;

			}
		}
		return predHealth;
	}

	void OrbWalk(CObject* actor, bool Ap, float extrarange = 1.5f)
	{
		if (Engine::GameGetTickCount() - AttackTimer < 0.07f + Engine::GetPing() * 0.001f || !me->IsAlive()) {
			return;
		}

		if (CanAttack())
		{
			if (actor && Engine::IsValidActor(actor, me->GetTrueAttackRange(actor)))
			{
				IssueAttack(actor);
				return;
			}
		}

		if (CanMove())
		{
			auto holdRadius = HoldRadius->Value;
			if (holdRadius > 0) {
				if (me->Position().DistanceSquared(Engine::GetMouseWorldPosition()) <= holdRadius * holdRadius) {
					return;
				}
			}
			MoveTo(GetOrbwalkPosition());
		}
	}

	void Tick()
	{
		if (LastTarget && !LastTarget->IsValidTarget()) {
			LastTarget = nullptr;
		}

		LastHitMinion = nullptr;
		AlmostLastHitMinion = nullptr;
		LaneClearMinion = nullptr;


		auto speed = global::LocalData->basicAttackMissileSpeed;
		auto minions = Engine::GetMinionsAround(FLT_MAX, 1);
		for (auto minion : minions)
		{
			if (minion->Team() != 300 - me->Team() || !me->IsInAutoAttackRange(minion) || !minion->IsValidTarget()) {
				continue;
			}

			auto lastHitHealth = minion->Health();
			auto laneClearHealth = lastHitHealth;

			auto LastHitMinion_lastHitHealth = FLT_MAX;
			auto AlmostLastHitMinion_laneClearHealth = FLT_MAX;
			auto LaneClearMinion_laneClearHealth = 0;

			lastHitHealth = GetHealthPrediction(minion, Engine::GetWindUpTime() + (global::LocalData->basicAttackMissileSpeed != FLT_MAX ? max(0.0f, minion->Position().Distance(me->Position()) - global::LocalData->gameplayRadius) / global::LocalData->basicAttackMissileSpeed : 0.0f) + max(0.0f, LastAttack + Engine::GetAttackDelay() - Engine::GameGetTickCount()) + ExtraFarmDelay->Value * 0.001f);
			laneClearHealth = GetHealthPrediction(minion, Engine::GetWindUpTime() + Engine::GetAnimationTime() + (global::LocalData->basicAttackMissileSpeed != FLT_MAX ? me->GetTrueAttackRange(minion) / global::LocalData->basicAttackMissileSpeed : 0.0f) + ExtraFarmDelay->Value * 0.001f);

			auto health = laneClearHealth; // lastHitHealth if turret is targetting
			auto attackDamage = CalcPhysicalDamage(me, minion, me->GetTotalAD());

			if (lastHitHealth > 0 && lastHitHealth < attackDamage) {
				if (!LastHitMinion || (minion->MaxHealth() == LastHitMinion->MaxHealth() ? lastHitHealth < LastHitMinion_lastHitHealth : minion->MaxHealth() > LastHitMinion->MaxHealth())) {
					LastHitMinion = minion;
					LastHitMinion_lastHitHealth = lastHitHealth;
				}
			}
			else if (health <= (minion->IsSiegeMinion() ? 1.5f : 1.0f) * attackDamage && health < minion->Health()) {
				if (!AlmostLastHitMinion || (minion->MaxHealth() == AlmostLastHitMinion->MaxHealth() ? laneClearHealth < AlmostLastHitMinion_laneClearHealth : minion->MaxHealth() > AlmostLastHitMinion->MaxHealth())) {
					AlmostLastHitMinion = minion;
					AlmostLastHitMinion_laneClearHealth = laneClearHealth;
					LastShouldWait = Engine::GameGetTickCount();
				}
			}
			else if (mode & ScriptMode::LaneClear) {
				bool isLaneClearMinion = true;
				//for (auto tur : global::turrets) {
				//	CObject* turret = (CObject*)tur;
				//	if (turret->IsAlly() && turret->IsInAutoAttackRange(minion)) {
				//		if (laneClearHealth == minion->Health()) {
				//			auto turretDamage = CalcPhysicalDamage(turret, minion, turret->GetTotalAD());
				//			for (auto minionHealth = minion->Health(); minionHealth > 0.0f && turretDamage > 0.0f; minionHealth -= turretDamage) {
				//				if (minionHealth <= attackDamage) {
				//					isLaneClearMinion = false;
				//					break;
				//				}
				//			}
				//			if (!LaneClearMinion || (PushPriority->Value ? laneClearHealth < LaneClearMinion_laneClearHealth : laneClearHealth > LaneClearMinion_laneClearHealth)) { // 1 = push 
				//				LaneClearMinion = minion;
				//				LaneClearMinion_laneClearHealth = laneClearHealth;
				//			}
				//		}
				//		isLaneClearMinion = false;
				//		break;
				//	}
				//}

				if (!isLaneClearMinion) {
					continue;
				}

				if (laneClearHealth > 2.0f * attackDamage || laneClearHealth == minion->Health()) {
					if (!LaneClearMinion || (PushPriority->Value ? laneClearHealth < LaneClearMinion_laneClearHealth : laneClearHealth > LaneClearMinion_laneClearHealth)) { // 1 = push 
						LaneClearMinion = minion;
						LaneClearMinion_laneClearHealth = laneClearHealth;
					}
				}
			}

		}

		if (!this->UseOrbWalker)
			return;

		if (mode != ScriptMode::None) {
			OrbWalk(GetTarget(), false);
		}
	}
};


Orbwalker* orbwalker = nullptr;