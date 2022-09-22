#pragma once

const char* const AttackResets[] =
{
	"dariusnoxiantacticsonh", "fiorae", "garenq", "gravesmove",
	"jaxempowertwo", "jaycehypercharge",
	"leonashieldofdaybreak", "luciane", "monkeykingdoubleattack",
	"mordekaisermaceofspades", "nasusq", "nautiluspiercinggaze",
	"netherblade", "gangplankqwrapper", "powerfist",
	"renektonpreexecute", "rengarq", "shyvanadoubleattack",
	"sivirw", "takedown", "talonnoxiandiplomacy",
	"trundletrollsmash", "vaynetumble", "vie", "volibearq",
	"xenzhaocombotarget", "yorickspectral", "reksaiq",
	"itemtitanichydracleave", "masochism", "illaoiw",
	"elisespiderw", "fiorae", "meditate", "sejuaninorthernwinds",
	"asheq", "camilleq", "camilleq2", "ViegoQDoubleAttack"
};

const char* const Attacks[] =
{
	"caitlynheadshotmissile", "frostarrow", "garenslash2",
	"kennenmegaproc", "masteryidoublestrike", "quinnwenhanced",
	"renektonexecute", "renektonsuperexecute",
	"rengarnewpassivebuffdash", "trundleq", "xenzhaothrust",
	"xenzhaothrust2", "xenzhaothrust3", "viktorqbuff",
	"lucianpassiveshot"
};
const char* const NoCancelChamps = { "Kalista" };
const char* const NoAttacks[] =
{
	"volleyattack", "volleyattackwithsound",
	"jarvanivcataclysmattack", "monkeykingdoubleattack",
	"shyvanadoubleattack", "shyvanadoubleattackdragon",
	"zyragraspingplantattack", "zyragraspingplantattack2",
	"zyragraspingplantattackfire", "zyragraspingplantattack2fire",
	"viktorpowertransfer", "sivirwattackbounce", "asheqattacknoonhit",
	"elisespiderlingbasicattack", "heimertyellowbasicattack",
	"heimertyellowbasicattack2", "heimertbluebasicattack",
	"annietibbersbasicattack", "annietibbersbasicattack2",
	"yorickdecayedghoulbasicattack", "yorickravenousghoulbasicattack",
	"yorickspectralghoulbasicattack", "malzaharvoidlingbasicattack",
	"malzaharvoidlingbasicattack2", "malzaharvoidlingbasicattack3",
	"kindredwolfbasicattack", "gravesautoattackrecoil"
};

float BeginReset = 0.0f;
struct SelfResetSpell
{
	int slot;
	int timer;
};

SelfResetSpell ResetSpell;

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

	bool Attack = true;
	bool DisableNextAttack;
	float _ApheliosChakramAATick;
	float _LastAATick;
	float LastCastEnd;

	const float& LastAATick() const {
		if (global::LocalChampNameHash == FNV("Aphelios"))
		{
			if (me->HasBuff("ApheliosCrescendumManager"))
				return _ApheliosChakramAATick;
		}
		return _LastAATick;
	}
	void LastAATick(const float& value) {
		if (global::LocalChampNameHash == FNV("Aphelios"))
		{
			if (me->HasBuff("ApheliosCrescendumManager"))
			{
				_ApheliosChakramAATick = value;

				if (_ApheliosChakramAATick == 0)
					return;
			}
		}

		_LastAATick = value;
	}

	float _sennaAttackCastDelay;

	float AttackCastDelay()
	{
		if (global::LocalChampNameHash == FNV("Senna"))
		{
			return _sennaAttackCastDelay;
		}

		return Engine::AttackCastDelay();
	}

	float GetMyProjectileSpeed()
	{
		if (global::LocalChampNameHash == FNV("Aphelios"))
		{
			for (auto buff : me->GetBuffManager()->Buffs())
			{
				switch (buff.namehash)
				{
				case FNV("ApheliosCalibrumManager"):
					return 2500;

				case FNV("ApheliosSeverumManager"):
					return FLT_MAX;

				case FNV("ApheliosGravitumManager"):
					return 1500;

				case FNV("ApheliosInfernumManager"):
					return 1500;

				case FNV("ApheliosCrescendumManager"):
					return 4000;
				}
			}

			return 1500;
		}

		if (global::LocalChampNameHash == FNV("Kayle"))
		{
			if (me->AttackRange() < 525.f)
				return FLT_MAX;

			return 2250;
		}

		return me->IsMelee() || global::LocalChampNameHash == FNV("Azir") || global::LocalChampNameHash == FNV("Velkoz") || global::LocalChampNameHash == FNV("Senna")
			|| global::LocalChampNameHash == FNV("Viktor") && me->HasBuff("ViktorPowerTransferReturn")
			? FLT_MAX
			: global::LocalData->basicAttackMissileSpeed;
	}

	std::vector<CObject*> minionListAA = {};

	CObject* LastTarget = nullptr;
	CObject* NonKillableMinion;
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
		if (AttackRange->Value)
		{
			XPolygon::DrawCircle(me->Position(), me->GetSelfAttackRange(), ImVec4(255, 0, 255, 255), 2.0f);
		}

		if (HoldRadiusBool->Value && HoldRadius->Value > 0) {
			XPolygon::DrawCircle(me->Position(), HoldRadius->Value, ImVec4(255, 144, 238, 144), 2.0f);
		}

		if (LasthittableMinions->Value && me->IsAlive()) {
			auto speed = GetMyProjectileSpeed();
			auto minions = Engine::GetMinionsAround(1500, 1);
			float dmg = 0.f;

			for (auto minion : minions)
			{
				if (minion->Team() != 300 - me->Team() || !minion->IsValidTarget()) {
					continue;
				}

				if (dmg == 0.f)
					dmg = CalcPhysicalDamage(me, minion, me->GetTotalAD());


				auto t = AttackCastDelay() * 1.05f + max(0, minion->Distance(me) - me->BoundingRadius()) / GetMyProjectileSpeed();

				if (dmg >= GetHealthPrediction(minion, t))
				{
					auto p = Engine::HpBarPos(minion);
					Renderer::GetInstance()->DrawRect(ImVec2(p.x - 34, p.y - 9), ImVec2(p.x + 32, p.y + 1), D3DCOLOR_ARGB(255, 66, 174, 222), 2.f);
				}
				else if (dmg >= GetHealthPrediction(minion, t * 3))
				{
					auto p = Engine::HpBarPos(minion);
					Renderer::GetInstance()->DrawRect(ImVec2(p.x - 34, p.y - 9), ImVec2(p.x + 32, p.y + 1), D3DCOLOR_ARGB(255, 255, 255, 255), 2.f);
				}
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

	bool ShouldWait()
	{
		if (me->Level() > 16)
			return false;


		auto speed = GetMyProjectileSpeed();
		for (auto minion : minionListAA)
		{
			if (GetHealthPrediction(minion, AttackCastDelay() + (speed != FLT_MAX ? max(0.0f, minion->Position().Distance(me->Position()) - global::LocalData->gameplayRadius) / speed : 0.0f) + max(0.0f, LastAATick() + Engine::AttackDelay() - Engine::GameGetTickCount()) + ExtraFarmDelay->Value * 0.001f
			, ExtraFarmDelay->Value) <= CalcPhysicalDamage(me, minion, me->GetTotalAD()) * 1.2f)
				return true;
		}

		/*float attackCalc = (Engine::GetAttackDelay() * 1.2f) + AttackCastDelay() + 0.0f + Engine::GetLatency() + 0.5f / GetMyProjectileSpeed();

		for (auto minion : minionListAA)
		{
			if (LaneClearHealthPrediction(minion, attackCalc, ExtraFarmDelay->Value) <= CalcPhysicalDamage(me, minion, me->GetTotalAD()) * 1.2f)
				return true;
		}*/

		return false;
	}

	bool ShouldWaitUnderTurret(CObject* noneKillableMinion)
	{
		float attackCalc = (Engine::GetAttackDelay() + (me->IsMelee() ? AttackCastDelay() : AttackCastDelay() +
			(me->GetSelfAttackRange() + 2 * me->BoundingRadius()) / global::LocalData->basicAttackMissileSpeed));

		for (auto minion : minionListAA)
		{
			if ((noneKillableMinion != nullptr ? noneKillableMinion->NetworkID() != minion->NetworkID() : true) && GetHealthPrediction(minion, attackCalc) <= CalcPhysicalDamage(me, minion, me->GetTotalAD()))
				return true;
		}
		return false;
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
		auto activeSpell = me->GetSpellBook()->GetActiveSpellEntry();
		/*if (activeSpell) {
			auto castInfo = activeSpell->GetSpellData();
			if (castInfo->ChannelIsInterruptedByAttacking() && (!activeSpell->IsInstantCast() || !activeSpell->SpellWasCast())) {
				return false;
			}

			if (activeSpell->IsAutoAttack())
				return false;

		}*/

		if (!me->ActionState(CharacterState::CanAttack))
		{
			if (global::LocalChampNameHash == FNV("Aphelios") || activeSpell->IsChanneling())
				return false;
		}

		for (auto buff : me->GetBuffManager()->Buffs())
		{
			if (buff.type == BuffType::Disarm || buff.type == BuffType::Blind && global::LocalChampNameHash != FNV("Kalista"))
				return false;

			if (global::LocalChampNameHash == FNV("Kayle") && buff.namehash == FNV("KayleR"))
				return false;

			if (global::LocalChampNameHash == FNV("Samira"))
			{
				switch (buff.namehash)
				{
				case FNV("SamiraW"):
				case FNV("SamiraR"):
					return false;
				}
			}

			switch (buff.namehash)
			{
			case FNV("JhinPassiveReload"):
			case FNV("XayahR"):
			case FNV("KaisaE"):
				return false;
			}
		}

		if (global::LocalChampNameHash == FNV("Graves"))
		{
			double attackDelay = 0.740296828 * Engine::AttackDelay() - 0.07;

			if (Engine::GameGetTickCount() + Engine::GetLatency() + 0.025 >= LastAATick() + attackDelay
				&& me->HasBuff("gravesbasicattackammo1"))
			{
				return true;
			}

			return false;
		}

		if (!me->IsDashing())
		{
			if (!me->ActionState(CharacterState::CanAttack))
				return false;
			//if (Player.Spellbook.IsCastingSpell)
			//    return false;
		}

		return Engine::GameGetTickCount() + Engine::GetLatency() + 0.025 > LastAATick() + Engine::AttackDelay();
	}

	bool CanMove() {

		auto activeSpell = me->GetSpellBook()->GetActiveSpellEntry();
		if (activeSpell) {
			auto castInfo = activeSpell->GetSpellData();
			if (!castInfo->CanMoveWhileChanneling() && (!activeSpell->IsInstantCast() || !activeSpell->SpellWasCast())) {
				return false;
			}
		}

		return global::LocalChampNameHash == FNV("Kalista") || Engine::GameGetTickCount() + Engine::GetLatency() > LastAATick() + AttackCastDelay() + ExtraWindUpTime->Value * 0.001f;
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

	void IssueMove()
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

		if (!me->ActionState(CharacterState::CanMove))
			return;

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

	void ResetAutoAttacks()
	{
		LastAATick(0);
	}

	void DetectAutoAttacksAndSpells()
	{
		auto spell = me->GetSpellBook()->GetActiveSpellEntry();
		auto timer = Engine::GameGetTickCount();
		if (spell && spell->IsAutoAttack())
		{
			if (LastCastEnd != spell->MidTick())
			{
				LastAATick(spell->StartTick());
				LastCastEnd = spell->MidTick();
				if (global::LocalChampNameHash == FNV("Senna"))
				{
					_sennaAttackCastDelay = spell->CastDelay();
				}
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

		std::vector<CObject*> minions = Engine::GetMinionsAround(me->GetSelfAttackRange() + 550, 2);
		for (auto minion : minions)
		{
			auto active = minion->GetSpellBook()->GetActiveSpellEntry();
			if (active && active->isAutoAttackAll())
			{
				ActiveAttacks[minion->NetworkID()] = {
					(uint32_t)minion,
					active->targetID(),
					active->StartTick(),
					active->EndTick(),
					active->CastDelay(),
					active->Delay(),
					(active->GetSpellData()->MissileSpeed() == 0) ? FLT_MAX : active->GetSpellData()->MissileSpeed(),
					false
				};
			}
		}

		for (auto turret_actor : global::turrets)
		{
			auto turret = (CObject*)turret_actor;
			auto active = turret->GetSpellBook()->GetActiveSpellEntry();
			if (active && active->isAutoAttackAll() && turret->IsAlly())
			{
				ActiveAttacks[turret->NetworkID()] = {
					(uint32_t)turret,
					active->targetID(),
					active->StartTick(),
					active->EndTick(),
					active->CastDelay(),
					active->Delay() + 0.1f,
					1200.F,
					true
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
		if (actor == nullptr || (justevade->BlockAttack && justevade->Block))
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
			last_attackorder = Engine::GameGetTickCount();
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
			if ((LastTarget->IsMonster() || LastTarget->IsHero()) && pathController->IsMoving() && me->ServerPosition().IsInRange(pathController->CurrentPosition(), me->GetRealAutoAttackRange(LastTarget) + 150.0f)) {
				auto way = LastTarget->GetWaypoints().back();
				return Engine::WorldToScreen(Vector3(way.x, me->Position().y, way.y));
			}
		}

		return Vector3::Zero;
		//return Engine::WorldToScreen(Engine::GetMouseWorldPosition());
	}

	float GetHealthPrediction(CObject* unit, float delta, float delay = 0)
	{
		auto predHealth = unit->Health() + unit->PhysicalShield();
		float timer = Engine::GameGetTickCount();
		delta += Engine::GetPing() * 0.0005f;
		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
		{
			auto attack = it->second;
			if (attack.target == unit->Index())
			{
				auto damage = 0.0f;
				auto source = (CObject*)attack.source;
				auto timeTillHit = attack.startTime + attack.Delay - Engine::GameGetTickCount();
				if (attack.projectileSpeed != FLT_MAX) {
					timeTillHit += max(0.0f, unit->ServerPosition().Distance(source->ServerPosition()) - source->BoundingRadius()) / attack.projectileSpeed + 0.01f;
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
	/*float GetHealthPrediction(CObject* unit, float time, float delay = 0)
	{
		auto predictedDamage = 0.f;
		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
		{
			auto attack = it->second;
			if (attack.target == unit->Index())
			{
				auto source = (CObject*)attack.source;
				float landTime = attack.startTime + attack.Delay - Engine::GameGetTickCount()
					+ max(0.f, unit->ServerPosition().Distance(source->ServerPosition()) - source->BoundingRadius())
					/ attack.projectileSpeed + 0.05f;

				if (landTime < time)
				{
					predictedDamage += source->GetTotalAD();
				}

			}
		}
		return unit->Health() - predictedDamage;
	}

	float LaneClearHealthPrediction(CObject* unit, float delta, int delay = 0)
	{
		auto predictedDamage = 0.f;
		delta += Engine::GetPing() * 0.0005f;

		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
		{
			auto attack = it->second;
			if (attack.target == unit->Index() && Engine::GameGetTickCount() - 0.1f <= attack.startTime + attack.animationTime)
			{
				auto n = 1;
				auto fromT = attack.startTime;
				auto toT = Engine::GameGetTickCount() + delta;
				auto source = (CObject*)attack.source;

				while (fromT < toT)
				{
					auto travelTime = fromT + attack.Delay + max(0, unit->Distance(source) - source->BoundingRadius()) / attack.projectileSpeed + 0.05f;
					if (fromT >= Engine::GameGetTickCount() && travelTime < toT)
					{
						n++;
					}

					fromT += attack.animationTime;
				}
				predictedDamage += n * source->GetTotalAD();
			}
		}
		return unit->Health() - predictedDamage;
	}*/


	float TurretAggroStartTick(CObject* minion)
	{
		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
		{
			auto attack = it->second;
			if (attack.isTurret && attack.target == minion->Index())
			{
				return attack.startTime;
			}
		}
		return 0;
	}
	bool HasMinionAggro(CObject* minion)
	{
		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
		{
			auto attack = it->second;
			if (!attack.isTurret && attack.target == minion->Index())
			{
				return true;
			}
		}
		return false;
	}
	bool HasTurretAggro(CObject* minion)
	{
		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
		{
			auto attack = it->second;
			if (attack.isTurret && attack.target == minion->Index())
			{
				return true;
			}
		}
		return false;
	}

	CObject* GetTarget()
	{
		CObject* result = nullptr;

		if ((mode & ScriptMode::Harass || mode & ScriptMode::LaneClear) &&
			!LastHitPriority->Value)
		{
			auto target = targetselector->GetTarget(0);
			if (target != nullptr && me->IsInAutoAttackRange(target))
				return target;
		}

		/*if (mode == OrbwalkingMode.Mixed || mode == OrbwalkingMode.LaneClear)
		{
			foreach(var nexus in ObjectManager.Get<Obj_HQ>().Where(t = > t.IsValidTarget() && this.InAutoAttackRange(t)))
				return nexus;

			if (_config.Item("AttackWards").IsActive())
			{
				var wardToAttack = ObjectManager.Get<Obj_AI_Minion>().Where(ward = > ward.IsValidTarget() && InAutoAttackRange(ward) && ward.IsEnemy && MinionManager.IsWard(ward)
					&& ward.CharData.BaseSkinName != "gangplankbarrel").FirstOrDefault();

				if (wardToAttack != null)
					return wardToAttack;
			}
		}*/
		minionListAA.clear();
		for (auto minion : Engine::GetMinionsAround(me->GetSelfAttackRange() + 100.f, 1))
		{
			if (minion->IsValidTarget() && me->IsInAutoAttackRange(minion) && minion->Team() == 300 - me->Team())
			{
				minionListAA.push_back(minion);
			}
		}
		//auto firstT = AttackCastDelay() + 0.0f + Engine::GetLatency();
		auto projectileSpeed = GetMyProjectileSpeed();

		/*Killable Minion*/
		if (mode & ScriptMode::LaneClear || mode & ScriptMode::Harass || mode & ScriptMode::LastHit)
		{
			std::vector<CObject*> LastHitList = {};
			for (auto minion : Engine::GetMinionsAround(1500.f, 1))
			{
				if (minion->Team() != 300 - me->Team() || !me->IsInAutoAttackRange(minion) || !minion->IsValidTarget()) {
					continue;
				}
				LastHitList.push_back(minion);
			}

			sort(LastHitList.begin(), LastHitList.end(), [&](CObject* minion, CObject* minion2) {
				return minion->MaxHealth() > minion2->MaxHealth();
			});
			sort(LastHitList.begin(), LastHitList.end(), [&](CObject* minion, CObject* minion2) {
				return minion->IsSiegeMinion() > minion2->IsSiegeMinion();
			});
			sort(LastHitList.begin(), LastHitList.end(), [&](CObject* minion, CObject* minion2) {
				return minion->IsSuperMinion() > minion2->IsSuperMinion();
			});


			for (auto minion : LastHitList)
			{
				auto t = AttackCastDelay() + (projectileSpeed != FLT_MAX ? max(0.0f, minion->Position().Distance(me->Position()) - global::LocalData->gameplayRadius) / projectileSpeed : 0.0f) + max(0.0f, LastAATick() + Engine::AttackDelay() - Engine::GameGetTickCount()) + ExtraFarmDelay->Value * 0.001f;// firstT + max(0, me->Distance(minion) - me->BoundingRadius()) / projectileSpeed;

				if (!PushPriority->Value)
				{
					t += 0.2f + Engine::GetLatency();
				}

				auto predHealth = GetHealthPrediction(minion, t);
				auto damage = CalcPhysicalDamage(me, minion, me->GetTotalAD());
				bool killable = predHealth <= damage;

				if (!PushPriority->Value)
				{
					if (minion->Health() < 50 || predHealth <= 50)
						return minion;
				}
				else
				{
					if (CanAttack())
					{
						//DelayOnFire = t + Utils.TickCount;
						//DelayOnFireId = minion.NetworkId;
					}

					if (predHealth <= 0)
					{
						if (GetHealthPrediction(minion, t - 0.05f, ExtraFarmDelay->Value) > 0)
						{
							NonKillableMinion = minion;
							return minion;
						}
					}
					else if (killable)
					{
						return minion;
					}

				}
			}

		}


		/*Champions*/
		if (!(mode & ScriptMode::LastHit))
		{
			auto target = targetselector->GetTarget(0);
			if (target->IsValidTarget() && me->IsInAutoAttackRange(target))
			{
				if (!me->UnderTurret(true) || mode & ScriptMode::Combo)
					return target;
			}
		}

		/*Jungle minions*/
		if (mode & ScriptMode::LaneClear || mode & ScriptMode::Harass)
		{
			float highestMaxHealth = 0.0f;
			auto minions = Engine::GetJunglesAround(me->GetSelfAttackRange() + 100.f, 2);
			for (auto minion : minions) {
				if (minion && me->IsInAutoAttackRange(minion)) {
					if (minion->MaxHealth() > highestMaxHealth) {
						result = minion;
						highestMaxHealth = minion->MaxHealth();
					}
				}
			}

			if (result != nullptr)
				return result;
		}


		if (mode & ScriptMode::LaneClear || mode & ScriptMode::Harass)
		{
			for (auto turret_actor : global::turrets)
			{
				auto t = (CObject*)turret_actor;
				if (t->IsValidTarget() && me->IsInAutoAttackRange(t) && t->IsEnemy())
					return t;
			}

			/*foreach(var inhi in ObjectManager.Get<Obj_BarracksDampener>().Where(t = > t.IsValidTarget() && this.InAutoAttackRange(t)))
				return inhi;*/
		}


		/* UnderTurret Farming */
		if ((mode & ScriptMode::LaneClear || mode & ScriptMode::Harass || mode && ScriptMode::LastHit) && CanAttack() && me->Level() < 17)
		{
			std::vector<CObject*> closestTower_list = Engine::GetTurrets(2);

			sort(closestTower_list.begin(), closestTower_list.end(), [&](CObject* turret, CObject* turret2) {
				return  me->Distance(turret) < me->Distance(turret2);
			});

			auto closestTower = closestTower_list[0];

			if (closestTower != nullptr && me->Distance(closestTower) < 1500.f)
			{
				CObject* farmUnderTurretMinion = nullptr;
				CObject* noneKillableMinion = nullptr;
				// return all the minions underturret in auto attack range
				std::vector<CObject*> minions = {};

				for (auto minion : Engine::GetMinionsAround(1500.f, 1))
				{
					if (minion->Team() != 300 - me->Team() || !me->IsInAutoAttackRange(minion) || !minion->IsValidTarget()) {
						continue;
					}
					if (closestTower->Distance(minion) < 900.f)
						minions.push_back(minion);
				}


				sort(minions.begin(), minions.end(), [&](CObject* minion, CObject* minion2) {
					return minion->Health() > minion2->Health();
				});
				sort(minions.begin(), minions.end(), [&](CObject* minion, CObject* minion2) {
					return minion->MaxHealth() > minion2->MaxHealth();
				});
				sort(minions.begin(), minions.end(), [&](CObject* minion, CObject* minion2) {
					return minion->IsSuperMinion() < minion2->IsSuperMinion();
				});
				sort(minions.begin(), minions.end(), [&](CObject* minion, CObject* minion2) {
					return minion->IsSiegeMinion() > minion2->IsSiegeMinion();
				});


				if (minions.size() > 0)
				{
					std::vector<CObject*>::iterator it_turretMinion = std::find_if(minions.begin(), minions.end(), [&](CObject* minion)
					{
						return HasTurretAggro(minion);
					});

					// get the turret aggro minion
					auto turretMinion = *it_turretMinion;

					if (turretMinion != nullptr)
					{
						float hpLeftBeforeDie = 0;
						float hpLeft = 0;
						float turretAttackCount = 0;
						float turretStarTick = TurretAggroStartTick(turretMinion);
						// from healthprediction (don't blame me :S)
						float turretLandTick = turretStarTick + 1.5f +
							max(
								0,
								(turretMinion->Distance(closestTower) -
									closestTower->BoundingRadius())) /
									(1200 + 70);
						// calculate the HP before try to balance it
						for (float i = turretLandTick + 0.05f;
							i < turretLandTick + 0.01f * 1.5f + 0.05f;
							i = i + Engine::GetAttackDelay(closestTower))
						{
							float time = i - Engine::GameGetTickCount() + Engine::GetLatency();
							float predHP =
								GetHealthPrediction(
									turretMinion, time > 0 ? time : 0);
							if (predHP > 0)
							{
								hpLeft = predHP;
								turretAttackCount += 1;
								continue;
							}
							hpLeftBeforeDie = hpLeft;
							hpLeft = 0;
							break;
						}
						// calculate the hits is needed and possibilty to balance
						if (hpLeft == 0 && turretAttackCount != 0 && hpLeftBeforeDie != 0)
						{
							float damage = CalcPhysicalDamage(me, turretMinion, me->GetTotalAD());
							float hits = hpLeftBeforeDie / damage;
							float timeBeforeDie = turretLandTick +
								(turretAttackCount + 1) *
								(Engine::GetAttackDelay(closestTower)) -
								Engine::GameGetTickCount();
							float timeUntilAttackReady = LastAATick() + Engine::GetAttackDelay() >
								Engine::GameGetTickCount() + Engine::GetLatency() + 0.025f
								? LastAATick() + Engine::GetAttackDelay() -
								(Engine::GameGetTickCount() + Engine::GetLatency() + 0.025f)
								: 0;
							float timeToLandAttack = me->IsMelee()
								? AttackCastDelay()
								: AttackCastDelay() + max(0, turretMinion->Distance(me) - me->BoundingRadius()) /
								global::LocalData->basicAttackMissileSpeed;
							if (hits >= 1 &&
								hits * Engine::GetAttackDelay() + timeUntilAttackReady + timeToLandAttack <
								timeBeforeDie)
							{
								farmUnderTurretMinion = turretMinion;
							}
							else if (hits >= 1 &&
								hits * Engine::GetAttackDelay() + timeUntilAttackReady + timeToLandAttack >
								timeBeforeDie)
							{
								noneKillableMinion = turretMinion;
							}
						}
						else if (hpLeft == 0 && turretAttackCount == 0 && hpLeftBeforeDie == 0)
						{
							noneKillableMinion = turretMinion;
						}
						// should wait before attacking a minion.
						if (ShouldWaitUnderTurret(noneKillableMinion))
						{
							return nullptr;
						}
						if (farmUnderTurretMinion != nullptr)
						{
							return farmUnderTurretMinion;
						}
						// balance other minions
						for (auto x : minions)
						{
							if (x->NetworkID() != turretMinion->NetworkID() && !HasMinionAggro(x))
							{
								int playerDamage = CalcPhysicalDamage(me, x, me->GetTotalAD());
								int turretDamage = CalcPhysicalDamage(closestTower, x, closestTower->GetTotalAD());
								int leftHP = (int)x->Health() % turretDamage;
								if (leftHP > playerDamage)
								{
									return x;
								}
							}
						}
						// late game
						std::vector<CObject*> lastminion_list = {};
						for (auto x : minions)
						{
							if (x->NetworkID() != turretMinion->NetworkID() && !HasMinionAggro(x))
								lastminion_list.push_back(x);
						}

						if (lastminion_list.size() > 0)
						{
							auto lastminion = lastminion_list.back();

							if (lastminion != nullptr && minions.size() >= 2)
							{
								if (1.f / Engine::GetAttackDelay() >= 1.f &&
									(turretAttackCount * Engine::GetAttackDelay(closestTower) / Engine::GetAttackDelay()) *
									CalcPhysicalDamage(me, lastminion, me->GetTotalAD()) > lastminion->Health())
								{
									return lastminion;
								}
								if (minions.size() >= 5 && 1.f / Engine::GetAttackDelay() >= 1.2)
								{
									return lastminion;
								}
							}
						}
					}
					else
					{
						if (ShouldWaitUnderTurret(noneKillableMinion))
						{
							return nullptr;
						}
						// balance other minions
						for (auto x : minions)
						{
							if (!HasMinionAggro(x) && closestTower != nullptr)
							{
								int playerDamage = CalcPhysicalDamage(me, x, me->GetTotalAD());
								int turretDamage = CalcPhysicalDamage(closestTower, x, closestTower->GetTotalAD());
								int leftHP = (int)x->Health() % turretDamage;
								if (leftHP > playerDamage)
								{
									return x;
								}
							}
						}
						// late game
						std::vector<CObject*> lastminion_list = {};
						for (auto x : minions)
						{
							if (!HasMinionAggro(x))
								lastminion_list.push_back(x);
						}

						if (lastminion_list.size() > 0)
						{
							auto lastminion = lastminion_list.back();

							if (lastminion != nullptr && minions.size() >= 2)
							{
								if (minions.size() >= 5 && 1.f / Engine::GetAttackDelay() >= 1.2)
								{
									return lastminion;
								}
							}
						}
					}


					return nullptr;
				}
			}
		}

		/*Lane Clear minions*/
		if (mode & ScriptMode::LaneClear)
		{
			if (!ShouldWait())
			{
				//float firstT2 = (Engine::GetAttackDelay() * 1.2f) + AttackCastDelay() + Engine::GetLatency();
				std::vector<CObject*> laneclearminion_list = {};
				for (auto minion : Engine::GetMinionsAround(1500.f, 1))
				{
					if (minion->Team() != 300 - me->Team() || !me->IsInAutoAttackRange(minion) || !minion->IsValidTarget()) {
						continue;
					}
					laneclearminion_list.push_back(minion);
				}
				sort(laneclearminion_list.begin(), laneclearminion_list.end(), [&](CObject* minion, CObject* minion2) {
					return minion->Health() < minion2->Health();
				});
				for (auto minion : laneclearminion_list)
				{
					float t = AttackCastDelay() + Engine::AttackDelay() + (projectileSpeed != FLT_MAX ? me->GetRealAutoAttackRange(minion) / projectileSpeed : 0.0f) + ExtraFarmDelay->Value * 0.001f;// firstT2 + max(0, me->Distance(minion) - me->BoundingRadius()) / projectileSpeed;

					float predHealth = GetHealthPrediction(minion, t);
					if (abs(predHealth - minion->Health()) < FLT_EPSILON)
						return minion;
					float damage = CalcPhysicalDamage(me, minion, me->GetTotalAD());
					if (predHealth >= (2 * damage))
						return minion;
				}
			}

		}
		return result;
	}

	void OrbWalk(CObject* actor, bool Ap, float extrarange = 1.5f)
	{
		if (Engine::GameGetTickCount() - last_attackorder < 0.07f + Engine::GetPing() * 0.001f) {
			return;
		}

		if (actor->IsValidTarget() && UseOrbWalker)
		{
			if (CanAttack())
			{
				IssueAttack(actor);
				return;
			}
			else if (global::LocalChampNameHash == FNV("Caitlyn") && actor->IsHero())
			{
				if (actor != nullptr && actor->HasBuff("caitlynyordletrapinternal"))
				{
					IssueAttack(actor);
				}
			}
		}

		if (CanMove())
		{
			auto holdRadius = HoldRadius->Value;
			if (holdRadius > 0) {
				if (me->ServerPosition().DistanceSquared(Engine::GetMouseWorldPosition()) <= holdRadius * holdRadius) {
					return;
				}
			}
			MoveTo(GetOrbwalkPosition());
		}


	}

	void Tick()
	{
		if (!me->IsAlive() || mode == ScriptMode::None)
			return;

		if (LastTarget && !LastTarget->IsValidTarget()) {
			LastTarget = nullptr;
		}

		OrbWalk(GetTarget(), false);

	}
};


Orbwalker* orbwalker = nullptr;