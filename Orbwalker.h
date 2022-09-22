#pragma once 
#include "JustEvade.h"
//
//const char* const AttackResets[] =
//{
//	"dariusnoxiantacticsonh", "fiorae", "garenq", "gravesmove",
//	"jaxempowertwo", "jaycehypercharge",
//	"leonashieldofdaybreak", "luciane", "monkeykingdoubleattack",
//	"mordekaisermaceofspades", "nasusq", "nautiluspiercinggaze",
//	"netherblade", "gangplankqwrapper", "powerfist",
//	"renektonpreexecute", "rengarq", "shyvanadoubleattack",
//	"sivirw", "takedown", "talonnoxiandiplomacy",
//	"trundletrollsmash", "vaynetumble", "vie", "volibearq",
//	"xenzhaocombotarget", "yorickspectral", "reksaiq",
//	"itemtitanichydracleave", "masochism", "illaoiw",
//	"elisespiderw", "fiorae", "meditate", "sejuaninorthernwinds",
//	"asheq", "camilleq", "camilleq2", "ViegoQDoubleAttack"
//};
//
//const char* const Attacks[] =
//{
//	"caitlynheadshotmissile", "frostarrow", "garenslash2",
//	"kennenmegaproc", "masteryidoublestrike", "quinnwenhanced",
//	"renektonexecute", "renektonsuperexecute",
//	"rengarnewpassivebuffdash", "trundleq", "xenzhaothrust",
//	"xenzhaothrust2", "xenzhaothrust3", "viktorqbuff",
//	"lucianpassiveshot"
//};
//const char* const NoCancelChamps = { "Kalista" };
//const char* const NoAttacks[] =
//{
//	"volleyattack", "volleyattackwithsound",
//	"jarvanivcataclysmattack", "monkeykingdoubleattack",
//	"shyvanadoubleattack", "shyvanadoubleattackdragon",
//	"zyragraspingplantattack", "zyragraspingplantattack2",
//	"zyragraspingplantattackfire", "zyragraspingplantattack2fire",
//	"viktorpowertransfer", "sivirwattackbounce", "asheqattacknoonhit",
//	"elisespiderlingbasicattack", "heimertyellowbasicattack",
//	"heimertyellowbasicattack2", "heimertbluebasicattack",
//	"annietibbersbasicattack", "annietibbersbasicattack2",
//	"yorickdecayedghoulbasicattack", "yorickravenousghoulbasicattack",
//	"yorickspectralghoulbasicattack", "malzaharvoidlingbasicattack",
//	"malzaharvoidlingbasicattack2", "malzaharvoidlingbasicattack3",
//	"kindredwolfbasicattack", "gravesautoattackrecoil"
//};

float BeginReset = 0.0f;
struct SelfResetSpell
{
	int slot;
	float timer;
	bool reset = false;
	bool autoaa = false;
	bool vaynecanrs = true;
};

SelfResetSpell ResetSpell;

std::unordered_map<std::string, int> ResetAASpells;

void OrbInit()
{
	ResetAASpells["Blitzcrank"] = _E, ResetAASpells["Camille"] = _Q, ResetAASpells["Chogath"] = _E, ResetAASpells["Darius"] = _W, ResetAASpells["DrMundo"] = _E, ResetAASpells["Elise"] = _W, ResetAASpells["Fiora"] = _E, ResetAASpells["Garen"] = _Q,
		ResetAASpells["Graves"] = _E, ResetAASpells["Kassadin"] = _W, ResetAASpells["Illaoi"] = _W, ResetAASpells["Jax"] = _W, ResetAASpells["Jayce"] = _W, ResetAASpells["Kaisa"] = _R, ResetAASpells["Kayle"] = _E, ResetAASpells["Katarina"] = _E, ResetAASpells["Kindred"] = _Q,
		ResetAASpells["Leona"] = _Q, ResetAASpells["Lucian"] = _E, ResetAASpells["MasterYi"] = _W, ResetAASpells["Mordekaiser"] = _Q, ResetAASpells["Nautilus"] = _W, ResetAASpells["Nasus"] = _Q,
		ResetAASpells["RekSai"] = _Q, ResetAASpells["Renekton"] = _W, ResetAASpells["Rengar"] = _Q, ResetAASpells["Riven"] = _Q, ResetAASpells["Sejuani"] = _E, ResetAASpells["Sett"] = _Q, ResetAASpells["Sivir"] = _W, ResetAASpells["Trundle"] = _Q, ResetAASpells["Talon"] = _Q,
		ResetAASpells["Vayne"] = _Q, ResetAASpells["Vi"] = _E, ResetAASpells["Volibear"] = _Q, ResetAASpells["MonkeyKing"] = _Q, ResetAASpells["XinZhao"] = _Q, ResetAASpells["Yorick"] = _Q;
}

void ResetAutoAttack();
static std::initializer_list<size_t> const AttackResets = { FNV("dariusnoxiantacticsonh"), FNV("fiorae"), FNV("garenq"), FNV("gravesmove"), /*FNV("hecarimrapidslash"),*/ FNV("jaxempowertwo"), FNV("jaycehypercharge"), FNV("leonashieldofdaybreak"), FNV("luciane"),FNV("monkeykingdoubleattack"),FNV("mordekaisermaceofspades"), FNV("nasusq"), FNV("nautiluspiercinggaze"), FNV("netherblade"), FNV("gangplankqwrapper"), FNV("renektonpreexecute"), FNV("rengarq"),FNV("rengarqemp"), FNV("shyvanadoubleattack"),   FNV("sivirw"), FNV("takedown"), FNV("talonnoxiandiplomacy"), FNV("trundletrollsmash"), FNV("vaynetumble"), FNV("vie"), FNV("volibearq"), FNV("xenzhaocombotarget"), FNV("yorickspectral"), FNV("reksaiq"), FNV("itemtitanichydracleave"), FNV("masochism"), FNV("illaoiw"), FNV("elisespiderw"), FNV("fiorae"), FNV("meditate"), FNV("sejuaninorthernwinds"), FNV("camilleq"), FNV("camilleq2"), FNV("xinzhaoq"), FNV("kaylee"), FNV("asheq"),FNV("settbasicattack"), FNV("settbasicattack3"), FNV("settqattack"), FNV("settqattack3"), FNV("settq"), FNV("aphelioscalibrumlineattack"),FNV("gwene"),FNV("quinne"),FNV("viegow") };


static std::initializer_list<size_t> const Attacks = { FNV("xinzhaoqthrust1"), FNV("xinzhaoqthrust2"), FNV("xinzhaoqthrust3"), FNV("caitlynheadshotmissile"), FNV("frostarrow"), FNV("garenslash2"), FNV("kennenmegaproc"), FNV("masteryidoublestrike"), FNV("quinnwenhanced"), FNV("renektonexecute"), FNV("renektonsuperexecute"), FNV("rengarnewpassivebuffdash"), FNV("trundleq"), FNV("xenzhaothrust"), FNV("xenzhaothrust2"),FNV("xenzhaothrust3"), FNV("viktorqbuff"), FNV("lucianpassiveshot") };


static std::initializer_list<size_t> const NoAttacks = { FNV("volleyattack"), FNV("volleyattackwithsound"), FNV("jarvanivcataclysmattack"), FNV("monkeykingdoubleattack"), FNV("shyvanadoubleattack"), FNV("shyvanadoubleattackdragon"), FNV("zyragraspingplantattack"), FNV("zyragraspingplantattack2"), FNV("zyragraspingplantattackfire"), FNV("zyragraspingplantattack2fire"),FNV("viktorpowertransfer"),FNV("sivirwattackbounce"),FNV("asheqattacknoonhit"), FNV("elisespiderlingbasicattack"), FNV("heimertyellowbasicattack"), FNV("heimertyellowbasicattack2"), FNV("heimertbluebasicattack"), FNV("annietibbersbasicattack"), FNV("annietibbersbasicattack2"),FNV("yorickdecayedghoulbasicattack"), FNV("yorickravenousghoulbasicattack"), FNV("yorickspectralghoulbasicattack"), FNV("malzaharvoidlingbasicattack"),FNV("malzaharvoidlingbasicattack2"), FNV("malzaharvoidlingbasicattack3"), FNV("kindredwolfbasicattack"), FNV("gravesautoattackrecoil"), FNV("gravesautoattackrecoilcastedummy"), FNV("seraphinepassiveattack") };
bool IsAutoAttackReset(std::string name)
{
	const auto lowerName = fnv::hash_runtime(ToLower(name).c_str());

	if (std::find(AttackResets.begin(), AttackResets.end(), lowerName) != AttackResets.end())
	{
		return std::find(NoAttacks.begin(), NoAttacks.end(), lowerName) == NoAttacks.end();
	}
	return false;
}

enum class HealthPredictionType
{
	Default,
	Simulated
};

class Orbwalker : public ModuleManager {
private:

public:
	CObject* LastHitMinion = nullptr;
	CObject* AlmostLastHitMinion = nullptr;
	CObject* LaneClearMinion = nullptr;
	float LastShouldWait = 0.0f;

	bool UseOrbWalker = true;
	CObject* EnemyGangPlank = nullptr;

	bool Attack = true;
	bool AAProcessed = false;
	bool DisableNextAttack = false;
	int BrainFarmInt = -100;// -100;f
	float TowerAttackCastDelay = 0.1668667466986795f;
	float TowerAttackDelay = 1.200480192076831f;
	float _ApheliosChakramAATick = 0;
	float _LastAATick = 0;
	float LastCastEnd = 0;
	float LastAACASTDelay = 0;
	float LastAATick() {
		if (global::LocalChampNameHash == FNV("Aphelios"))
		{
			if (me->HasBuff(FNV("aphelioscrescendummanager")))
				return _ApheliosChakramAATick;
		}
		return _LastAATick;
	}
	void LastAATick(float value) {
		if (global::LocalChampNameHash == FNV("Aphelios"))
		{
			if (me->HasBuff(FNV("aphelioscrescendummanager")))
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
		/*if (global::LocalChampNameHash == FNV("Senna"))
		{
			return _sennaAttackCastDelay;
		}*/

		return me->AttackCastDelay();
	}

	float GetMyProjectileSpeed()
	{
		if (global::LocalChampNameHash == FNV("Aphelios"))
		{
			for (auto buff : me->GetBuffManager()->Buffs())
			{
				switch (buff.namehash)
				{
				case FNV("aphelioscalibrummanager"):
					return 2500;

				case FNV("apheliosseverummanager"):
					return FLT_MAX;

				case FNV("apheliosgravitummanager"):
					return 1500;

				case FNV("apheliosinfernummanager"):
					return 1500;

				case FNV("aphelioscrescendummanager"):
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
			|| global::LocalChampNameHash == FNV("Viktor") && me->HasBuff(FNV("viktorpowertransferreturn"))
			? FLT_MAX
			: global::LocalData->basicAttackMissileSpeed;
	}

	//std::vector<CObject*> minionListAA = {};
	int ResetState = 0;
	CObject* LastTarget = nullptr;
	CObject* NonKillableMinion;
	CheckBox* Interrupt;
	CheckBox* WindWallCheckVar;
	CheckBox* UseNormalCast;

	CheckBox* LaneClearHeroes;
	CheckBox* SupportMode;
	Slider* HoldRadius;

	CheckBox* MissileCheck;
	CheckBox* AACheck;

	Slider* OrbwalkerDelaySpeed;
	Slider* ExtraWindUpTime;
	Slider* LaneClearSpeed;


	CheckBox* LastHitPriority;
	CheckBox* AutoPetsTraps;
	CheckBox* AttackBarrels;
	CheckBox* PushPriority;
	Slider* ExtraFarmDelay;

	CheckBox* StickToTarget;

	CheckBox* AttackRange;
	CheckBox* AzirSoldierAttackRange;
	CheckBox* EnemyAttackRange;
	CheckBox* HoldRadiusBool;
	CheckBox* LasthittableMinions;

	Vector3 ForcedPosition = Vector3::Zero;

	KeyBind* ComboKey;
	KeyBind* MixedKey;
	KeyBind* LastHitKey;
	KeyBind* LaneClearKey;
	KeyBind* JungleClearKey;
	KeyBind* FlyKey;

	Orbwalker()
	{

	}

	~Orbwalker()
	{

	}
	void Draw()
	{
		/*for (auto inhi_actor : Engine::GetInhib())
		{
			XPolygon::DrawCircle(inhi_actor->Position(), inhi_actor->BoundingRadius(), ImVec4(255, 144, 238, 144), 2.0f);
			Vector3 objectScreenLocation2 = Engine::WorldToScreen(inhi_actor->Position());
			Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 255, 0, 255), true, false, textonce("%s"), inhi_actor->Name().c_str());

		}*/

		/*auto target = targetselector->GetTarget(-1);

		if (target->IsValidTarget())
			XPolygon::DrawArrow(me->Pos2D(), target->Pos2D(), D3DCOLOR_ARGB(255, 0, 0, 0), 4);*/

			/*std::vector<CObject*> minions = Engine::GetMinionsAround(me->GetSelfAttackRange() + 550, 1);
			for (auto minion : minions)
			{
				XPolygon::DrawCircle(minion->Position(), 50, ImVec4(255, 255, 0, 255), 2);
			}*/

			//XPolygon::DrawArrow2(me->Pos2D(), me->Pos2D().Extended(Engine::GetMouseWorldPosition2D(), 200.f), D3DCOLOR_ARGB(255, 0, 0, 0), 4);
			//XPolygon::DrawArrow2(me->Pos2D(), me->Pos2D().Extended(Engine::GetMouseWorldPosition2D(), 200.f), D3DCOLOR_ARGB(255, 0, 255, 0), 2);

		if (AttackRange->Value)
		{
			//XPolygon::DrawCircle(me->Position(), me->GetSelfAttackRange(), ImVec4(255, 0, 255, 255), 2.0f);
			// Render Hue Wheel
			if (!Engine::IsOutboundScreen2(Engine::WorldToScreenvec2(me->Position())))
			{
				auto points = Engine::CirclePoints(4, me->GetSelfAttackRange(), me->Position());

				auto w1 = Engine::WorldToScreenImVec2(points[0]);
				auto w2 = Engine::WorldToScreenImVec2(points[1]);


				// Paint colors over existing vertices
				ImVec2 gradient_p0(w1);
				ImVec2 gradient_p1(w2);

				const int vert_start_idx = ImGui::GetBackgroundDrawList()->VtxBuffer.Size;
				XPolygon::DrawPolygon(Engine::CirclePoints(70, me->GetSelfAttackRange(), me->Position()), D3DCOLOR_ARGB(255, 0, 0, 255), 3);
				const int vert_end_idx = ImGui::GetBackgroundDrawList()->VtxBuffer.Size;
				ImGui::ShadeVertsLinearColorGradientKeepAlpha(ImGui::GetBackgroundDrawList(), vert_start_idx, vert_end_idx, gradient_p0, gradient_p1, IM_COL32(136, 78, 240, 255), IM_COL32(5, 189, 253, 255));
			}
		}


		if (HoldRadiusBool->Value && HoldRadius->Value > 0) {
			XPolygon::DrawCircle(me->Position(), HoldRadius->Value, ImVec4(255, 144, 238, 144), 2.0f);
		}

		if (LasthittableMinions->Value && me->IsAlive()) {
			auto speed = GetMyProjectileSpeed();
			auto minions = Engine::GetMinionsAround(700, 1);

			for (auto minion : minions)
			{
				if (minion->Team() != 300 - me->Team() || !minion->IsValidTarget()) {
					continue;
				}

				float dmg = me->GetAutoAttackDamage(minion);

				auto t = me->AttackCastDelay() * 1050.f + 1000 * std::max(0.f, minion->Distance(me) - global::LocalData->gameplayRadius) / GetMyProjectileSpeed();

				auto hppos = Engine::HpBarPos(minion);

				if (dmg >= GetHealthPrediction(minion, t))
				{
					//Renderer::GetInstance()->DrawRect(ImVec2(hppos.x - 33, hppos.y - 8), ImVec2(hppos.x + 32, hppos.y + 1), D3DCOLOR_ARGB(255, 255, 0, 0), 2.f);
					ImVec2 p;
					ImVec2 p2;

					p.x = hppos.x - 43;
					p.y = hppos.y - 14;

					p2.x = hppos.x + 33;
					p2.y = hppos.y - 14;


					static ImVec2 pointskek[6];

					pointskek[0].x = p.x + 0;
					pointskek[0].y = p.y + 2;

					pointskek[1].x = p.x + 3;
					pointskek[1].y = p.y + 0;

					pointskek[2].x = p.x + 10;
					pointskek[2].y = p.y + 10;

					pointskek[3].x = p.x + 3;
					pointskek[3].y = p.y + 20;

					pointskek[4].x = p.x + 0;
					pointskek[4].y = p.y + 18;

					pointskek[5].x = p.x + 6;
					pointskek[5].y = p.y + 10;

					static ImVec2 pointskek2[6];

					pointskek2[0].x = p2.x + 10;
					pointskek2[0].y = p2.y + 2;

					pointskek2[1].x = p2.x + 7;
					pointskek2[1].y = p2.y + 0;

					pointskek2[2].x = p2.x + 0;
					pointskek2[2].y = p2.y + 10;

					pointskek2[3].x = p2.x + 7;
					pointskek2[3].y = p2.y + 20;

					pointskek2[4].x = p2.x + 10;
					pointskek2[4].y = p2.y + 18;

					pointskek2[5].x = p2.x + 4;
					pointskek2[5].y = p2.y + 10;

					ImGui::GetBackgroundDrawList()->AddPolyline(pointskek, 6, ImGui::GetColorU32(ImVec4(255, 255, 255, 255)), true, 1);
					ImGui::GetBackgroundDrawList()->AddPolyline(pointskek2, 6, ImGui::GetColorU32(ImVec4(255, 255, 255, 255)), true, 1);
					XPolygon::DrawCircle(minion->Position(), 50, ImVec4(255, 255, 0, 0), 2);
				}
				else if (dmg >= GetHealthPrediction(minion, t * 3, 10.f, HealthPredictionType::Simulated))
				{
					//Renderer::GetInstance()->DrawRect(ImVec2(hppos.x - 33, hppos.y - 8), ImVec2(hppos.x + 32, hppos.y + 1), D3DCOLOR_ARGB(255, 255, 255, 255), 2.f);
					XPolygon::DrawCircle(minion->Position(), 50, ImVec4(255, 255, 255, 255), 2);
				}
			}
		}

	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Orbwalker", "Orbwalker");

		auto hoykeysMenu = menu->AddMenu("Hotkeys", "Hotkeys");
		ComboKey = hoykeysMenu->AddKeyBind("Combo", "Combo", VK_SPACE, false, false);

		MixedKey = hoykeysMenu->AddKeyBind("Mixed", "Mixed", VK_KEY_X, false, false);

		LaneClearKey = hoykeysMenu->AddKeyBind("LaneClear", "Lane clear", VK_KEY_C, false, false);

		JungleClearKey = hoykeysMenu->AddKeyBind("JungleClear", "JungleClear", VK_KEY_C, false, false);

		LastHitKey = hoykeysMenu->AddKeyBind("LastHit", "Last hit", VK_KEY_V, false, false);

		FlyKey = hoykeysMenu->AddKeyBind("Flee", "Flee", VK_KEY_Y, false, false);

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
		ItemSlot7 = spellitemskeysMenu->AddKeyBind("ItemSlot7", "Item Slot 7", VK_KEY_7, false, false);
		ChampionOnly = spellitemskeysMenu->AddKeyBind("ChampionOnly", "Champion Only Key", VK_KEY_I, false, false);

		auto configurationMenu = menu->AddMenu("Configuration", "Configuration");
		UseNormalCast = configurationMenu->AddCheckBox("UseNormalCast", "Use Normal Cast", false);
		Interrupt = configurationMenu->AddCheckBox("Interrupt", "Interrupt Spell Check", true);
		WindWallCheckVar = configurationMenu->AddCheckBox("WindWallCheck", "Check Yasuo WindWall", true);
		LaneClearHeroes = configurationMenu->AddCheckBox("LaneClearHeroes", "Attack heroes in laneclear", true);
		LaneClearHeroes->AddTooltip("It will attack heroes when lane clearing");
		//SupportMode = configurationMenu->AddCheckBox(("SupportMode" + ObjectManager::Player->SkinName).c_str(), "Support mode");
		HoldRadius = configurationMenu->AddSlider("HoldRadius", "Hold radius", 65, 65, 100);

		/* Missile check */
		MissileCheck = configurationMenu->AddCheckBox("MissileCheck", "Use AA Missile Check", false);
		MissileCheck->AddTooltip("Check if auto attack is cancel too much");
		AACheck = configurationMenu->AddCheckBox("AACheck", "AA Cancel check", true);

		OrbwalkerDelaySpeed = configurationMenu->AddSlider("OrbwalkerDelaySpeed", "Orbwalker Delay speed", 120, 50, 200, 10);
		OrbwalkerDelaySpeed->AddTooltip("Lowest = Fastest orbwalking");

		ExtraWindUpTime = configurationMenu->AddSlider("ExtraWindUpTime", "Extra windup time", 20, 0, 200, 10);

		auto farmingMenu = menu->AddMenu("Farming", "Farming");
		LastHitPriority = farmingMenu->AddCheckBox("LastHitPriority", "Prioritize lasthit over harass", true);
		AutoPetsTraps = farmingMenu->AddCheckBox("AutoPetsTraps", "Auto attack pets & traps", true);
		AttackBarrels = farmingMenu->AddCheckBox("AttackBarrels", "Auto attack GP Barrels", true);
		PushPriority = farmingMenu->AddCheckBox("PushPriority", "Prioritize push over freeze", true);
		ExtraFarmDelay = farmingMenu->AddSlider("ExtraFarmDelay", "Extra farm delay", 0, 0, 200, 10);
		LaneClearSpeed = farmingMenu->AddSlider("LaneClearSpeed", "LaneClear Speed", 50, -100, 200, 10);

		auto meleeMenu = menu->AddMenu("Melee", "Melee");
		StickToTarget = meleeMenu->AddCheckBox("StickToTarget", "Stick to target", false);

		auto drawingsMenu = menu->AddMenu("Drawings", "Drawings");
		AttackRange = drawingsMenu->AddCheckBox("AttackRange", "Attack range", true);
		/*if (IsAzir) {
			Config::Drawings::AzirSoldierAttackRange = drawingsMenu->AddCheckBox("AzirSoldierAttackRange", "Azir soldier attack range", true);
		}*/
		EnemyAttackRange = drawingsMenu->AddCheckBox("EnemyAttackRange", "Enemy attack range", false);
		HoldRadiusBool = drawingsMenu->AddCheckBox("HoldRadius", "Hold radius", true);
		LasthittableMinions = drawingsMenu->AddCheckBox("LasthittableMinions", "Lasthittable minions", true);



		for (auto actor : Engine::GetHeros(1))
		{
			if (actor->ChampionNameHash() == FNV("GangPlank"))
			{
				EnemyGangPlank = actor;
				break;
			}
		}
	}


	float LaneClearWaitTimeMod()
	{
		return 1.8 - 0.01 * LaneClearSpeed->Value;
	}

	bool ShouldWait() {
		return Engine::GameGetTickCount() - LastShouldWait <= 0.4f || AlmostLastHitMinion;
	}

	bool ShouldWaitOld()
	{
		if (me->Level() > 16)
			return false;


		auto attackCalc = (me->AttackDelay() * 1000 * LaneClearWaitTimeMod()) + (int)(me->AttackCastDelay() * 1000) + BrainFarmInt + Engine::GetPing() / 2 + 1000 * 500 / (int)GetMyProjectileSpeed();
		auto targets = Engine::GetMinionsAround(me->GetSelfAttackRange() + 100.f, 1);
		return from(targets)
			>> any([&](CObject* minion) {return LaneClearHealthPrediction(minion, attackCalc, ExtraFarmDelay->Value) <= me->GetAutoAttackDamage(minion) * 1.2f; });

		/*
		auto attackCalc = me->AttackDelay() * 1000 * LaneClearWaitTimeMod();

		return from(Engine::GetMinionsAround(me->GetSelfAttackRange() + 100.f, 1))
			>> any([&](CObject* minion) {return GetHealthPrediction(minion, attackCalc, 10.f, HealthPredictionType::Simulated) < me->GetAutoAttackDamage(minion); });*/
	}

	bool ShouldWaitUnderTurret(CObject* noneKillableMinion)
	{
		auto attackCalc = (int)(me->AttackDelay() * 1000 + (me->IsMelee() ? me->AttackCastDelay() * 1000 : me->AttackCastDelay() * 1000 +
			1000 * (me->AttackRange() + 2 * global::LocalData->gameplayRadius) / global::LocalData->basicAttackMissileSpeed));
		auto targets = Engine::GetMinionsAround(me->GetSelfAttackRange(), 1);
		return from(targets)
			>> any([&](CObject* minion) {return (noneKillableMinion != nullptr ? noneKillableMinion->NetworkID() != minion->NetworkID() : true) &&
				LaneClearHealthPrediction(minion, attackCalc) <= me->GetAutoAttackDamage(minion); });

		/*return
			MinionListAA.Any(minion = >
			(noneKillableMinion != null ? noneKillableMinion.NetworkId != minion.NetworkId : true) &&
				HealthPrediction.LaneClearHealthPrediction(minion, attackCalc, FarmDelay) <= Player.GetAutoAttackDamage(minion));

		if (minionListAA.size() == 0)
			return false;

		return std::find_if(minionListAA.begin(), minionListAA.end(), [&](CObject* minion) { return (noneKillableMinion != nullptr ? noneKillableMinion->NetworkID() != minion->NetworkID() : true) &&
			LaneClearHealthPrediction(
				minion,
				(int)
				(me->AttackDelay() * 1000
					+ (me->IsMelee()
						? Engine::AttackCastDelayLastHit() * 1000
						: Engine::AttackCastDelayLastHit() * 1000
						+ 1000 * (me->AttackRange() + 2 * global::LocalData->gameplayRadius)
						/ global::LocalData->basicAttackMissileSpeed))) < me->GetAutoAttackDamage(minion); }) != minionListAA.end();*/
	}

	bool AttackInterrupt()
	{
		if ((global::LocalChampNameHash != FNV("Kalista") && me->GetBuffManager()->HasBuffType(BuffType::Blind)) ||
			(global::LocalChampNameHash == FNV("Jhin") && me->HasBuff(FNV("jhinpassivereload"))) ||
			(global::LocalChampNameHash == FNV("Kaisa") && me->HasBuff(FNV("kaisae"))))
		{
			return true;
		}
		return false;
	}

	bool CanAttack() {
		//if (global::LocalChampNameHash == FNV("Riven"))
		//{
		//	if (!me->IsDashing() /*&& me->IsMoving()*/ && LastAATick() == 0
		//		/*(Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundone")).starttime > 0.25f and
		//			Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundone")).starttime < 0.3f) or
		//		(Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundtwo")).starttime > 0.27f and
		//			Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundtwo")).starttime < 0.3f) or
		//		(Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundthree")).starttime > 0.369f and
		//			Engine::GameGetTickCount() - me->GetBuffManager()->GetBuffCacheByFNVHash(FNV("riventricleavesoundthree")).starttime < 0.8f)*/)
		//	{
		//		return true;
		//	}
		//}
		//else
		//{
		//	if (LastAATick() == 0)
		//		return true;
		//}
		if (LastAATick() == 0)
			return true;

		auto activespell = me->GetSpellBook()->GetActiveSpellEntry();
		if (activespell) {
			auto castInfo = me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData();
			if (castInfo->ChannelIsInterruptedByAttacking() && (!activespell->IsInstantCast() || !activespell->SpellWasCast())) {
				return false;
			}
		}

		if (activespell->IsAutoAttack())
		{
			return false;
		}

		/*if (!me->CanAttack())
		{
			if (global::LocalChampNameHash == FNV("Aphelios") || me->GetSpellBook()->GetActiveSpellEntry()->IsChanneling())
				return false;
		}*/

		for (auto buff : me->GetBuffManager()->Buffs())
		{
			if (buff.type == BuffType::Disarm || buff.type == BuffType::Blind && global::LocalChampNameHash != FNV("Kalista"))
				return false;

			if (global::LocalChampNameHash == FNV("Kayle") && buff.namehash == FNV("kayler"))
				return false;

			if (global::LocalChampNameHash == FNV("samira"))
			{
				switch (buff.namehash)
				{
				case FNV("samiraw"):
				case FNV("samirar"):
					return false;
				}
			}

			switch (buff.namehash)
			{
			case FNV("jhinpassivereload"):
			case FNV("xayahr"):
			case FNV("kaisae"):
				return false;
			}
		}

		if (global::LocalChampNameHash == FNV("Graves"))
		{
			float attackDelay = 1.0740296828f * 1000 * me->AttackDelay() - 716.2381256175f;

			if (Engine::GameTimeTickCount() + Engine::GetPing() / 2 + 25 >= LastAATick() + attackDelay
				&& me->HasBuff(FNV("gravesbasicattackammo1")))
			{
				return true;
			}

			return false;
		}

		if (me->IsDashing())
		{
			//if (!me->CanAttack())
			return false;
		}

		return Engine::GameTimeTickCount() + Engine::GetPing() / 2 + 25 > LastAATick() + me->AttackDelay() * 1000;
	}

	bool CanMove(float extraWindup, bool disableMissileCheck = false) {
		auto activeSpell = me->GetSpellBook()->GetActiveSpellEntry();
		if (activeSpell) {
			auto castInfo = activeSpell->GetSpellData();

			//if (activeSpell->IsAutoAttack() && !activeSpell->SpellWasCast() && !castInfo->CanMoveWhileChanneling() /*|| !activeSpell->isAutoAttackAll() && !castInfo->CanMoveWhileChanneling()*/) {
			//	return false;
			//}
			if (!castInfo->CanMoveWhileChanneling() && (!activeSpell->IsInstantCast() || !activeSpell->SpellWasCast())) {
				return false;
			}

			/*if (global::LocalChampNameHash == FNV("Xerath"))
			{
				if (activeSpell->GetSpellData()->GetSpellNameHash() == FNV("XerathLocusOfPower2"))
					return false;
			}
			else if (global::LocalChampNameHash == FNV("Jhin"))
			{
				if (activeSpell->GetSpellData()->GetSpellNameHash() == FNV("JhinRShot"))
					return false;
			}
			else if (global::LocalChampNameHash == FNV("MissFortune"))
			{
				if (activeSpell->GetSpellData()->GetSpellNameHash() == FNV("MissFortuneBulletTime"))
					return false;
			}
			else if (global::LocalChampNameHash == FNV("Velkoz"))
			{

			}
			else if (global::LocalChampNameHash == FNV("Katarina"))
			{
				if (activeSpell->GetSpellData()->GetSpellNameHash() == FNV("KatarinaR"))
					return false;
			}*/
		}

		if (global::_missileLaunched && MissileCheck->Value && !disableMissileCheck)
		{
			return true;
		}


		return global::LocalChampNameHash == FNV("Kalista") || (Engine::GameTimeTickCount() + Engine::GetPing() / 2 > LastAATick() + AttackCastDelay() * 1000 + extraWindup);
	}

	bool AfterAutoAttack()
	{
		if (Engine::GameGetTickCount() > LastCastEnd && Engine::GameGetTickCount() < LastCastEnd + 0.12f && AAProcessed)
		{
			return true;
		}
		return false;
	}

	bool CheckInterrupt()
	{
		return Interrupt->Value ? Engine::GameGetTickCount() > LastCastEnd + 0.12f || AfterAutoAttack() : true;
	}

	bool IssueMove(Vector3 worldpos = Vector3::Zero)
	{
		if (Engine::IsChatOpen() /*|| !me->CanMove()*/)
			return false;

		//if (Engine::GameGetTickCount() - last_movetoorder > humanizer_delay /*&& me->CanMove()*/)
		{
			Engine::DisableMove(false);
			if (worldpos.IsValid())
			{
				auto movepos = Engine::WorldToScreen(worldpos);
				MouseClick(false, movepos.x, movepos.y);
			}
			else
			{
				Click();
			}
			last_movetoorder = Engine::GameGetTickCount();
			return true;
		}
		return false;
	}

	bool CanHarras()
	{
		if (!me->IsWindingUp() && !Engine::UnderTurret(me->Position()) && CanMove(ExtraWindUpTime->Value))
			return true;
		else
			return false;
	}

	float PathLength(std::vector<Vector2> path)
	{
		auto distance = 0.f;
		for (int i = 0; i < path.size() - 1; i++)
		{
			distance += path[i].Distance(path[i + 1]);
		}
		return distance;
	}
	Vector3 LastMoveCommandPosition;

	void MoveTo(Vector3 pos)
	{
		if (!CanMove(ExtraWindUpTime->Value) || Engine::GameGetTickCount() - last_movetoorder < OrbwalkerDelaySpeed->Value * 0.001f) {
			return;
		}

		/*if (!me->CanMove())
			return;*/

			/*Vector3 point = pos;
			auto serverPosition = me->ServerPosition();

			if (serverPosition.DistanceSquared(point) < 150 * 150)
			{
				point = serverPosition.Extended(pos, 200.0f);
			}

			auto angle = 0.0f;
			auto currentPath = me->GetPath();
			if (currentPath.size() > 1 && PathLength(currentPath) > 100)
			{
				std::vector<Vector2> movePath;
				movePath.push_back(XPolygon::To2D(serverPosition));
				movePath.push_back(XPolygon::To2D(point));

				if (movePath.size() > 1)
				{
					auto v1 = currentPath[1] - currentPath[0];
					auto v2 = movePath[1] - movePath[0];
					angle = v1.AngleBetween(v2);
					auto distance = movePath.back().DistanceSquared(currentPath.back());

					if ((angle < 10 && distance < 200 * 200) || distance < 30 * 30)
					{
						return;
					}
				}
			}*/

		Engine::SetTargetOnlyChampions(true);
		if (pos.IsValid())
		{
			Vector3 point = pos;
			Vector3 point3d = Engine::WorldToScreen(point);
			MouseClick(false, point3d.x, point3d.y);
		}
		else
		{
			Click();
		}
		Engine::SetTargetOnlyChampions(false);

		last_movetoorder = Engine::GameGetTickCount();
	}

	void ResetAutoAttacks()
	{
		LastAATick(0);

	}

	bool IsAutoAttackSpell(ActiveSpellEntry* spell)
	{
		if (global::LocalChampNameHash == FNV("Vayne"))
		{
			return spell->Slot() == 2;
		}

		return false;
	}

	void DetectAutoAttacksAndSpells()
	{
		auto spell = me->GetSpellBook()->GetActiveSpellEntry();
		if (spell && (spell->IsAutoAttack() || IsAutoAttackSpell(spell)))
		{
			AAProcessed = false;
			if (spell->SpellWasCast())
			{
				AAProcessed = true;
			}
			if (LastCastEnd != spell->MidTick() /*&& spell->SpellWasCast()*/)
			{
				LastAATick(spell->StartTick() * 1000.f);
				//LastAATick(Engine::GameTimeTickCount() - Engine::GetPing() / 2);
				LastAACASTDelay = spell->CastDelay() * 1000.f;
				LastCastEnd = spell->MidTick();

				if (global::LocalChampNameHash == FNV("Senna"))
				{
					_sennaAttackCastDelay = spell->CastDelay();
				}
				ResetSpell.reset = false;
			}
		}

		if ((!spell->isValid() || !me->IsAutoAttacking()) && me->GetWaypoints().size() > 1 && me->IsMoving() && !me->IsDashing() && !AAProcessed && AACheck->Value)
		{
			if (global::LocalChampNameHash != FNV("Kalista"))
			{
				if (!(Engine::GameTimeTickCount() + Engine::GetPing() / 2 > LastAATick() + LastAACASTDelay) /*&& Engine::GameTimeTickCount() - LastAATick() > 30.f*/ && Engine::GameTimeTickCount() < LastCastEnd * 1000.f)
				{
					ResetAutoAttack();
					//std::cout << "Cancel Attack Error" << std::endl;
				}
				/*if (ActiveTick - LastAATick() < LastAACASTDelay && ActiveTick - LastAATick() > 30.0f)
				{
					std::cout << "Cancel Attack" << std::endl;
					ResetAutoAttack();
				}*/
			}
		}

		if (CanAttack() && CanMove(ExtraWindUpTime->Value))
		{
			ResetSpell.autoaa = false;
		}
		if (!CanAttack() && CanMove(ExtraWindUpTime->Value))
		{
			ResetSpell.autoaa = true;
		}

		if (global::LocalChampNameHash == FNV("Vayne"))
		{
			if (me->HasBuff(FNV("vaynetumblebonus")))
			{
				auto caststate = me->GetSpellBook()->GetCastState();
				if (ResetSpell.slot == me->GetSpellBook()->GetCastSlot() && ResetSpell.timer < Engine::GameGetTickCount() && !caststate[ResetSpell.slot] && ResetSpell.autoaa && !ResetSpell.reset && ResetSpell.vaynecanrs)
				{
					ResetSpell.reset = true;
					ResetSpell.vaynecanrs = false;
					ResetSpell.timer = Engine::GameGetTickCount() + 1.0f;
					ResetAutoAttack();
				}
			}
			else
			{
				if (!IsReady(0))
				{
					ResetSpell.vaynecanrs = true;
				}

				ResetSpell.reset = false;
			}
		}
		else
		{
			if (ResetSpell.slot != 1998)
			{
				std::bitset<4> caststate = me->GetSpellBook()->GetCastState();
				if (ResetSpell.slot == me->GetSpellBook()->GetCastSlot() && !caststate[ResetSpell.slot] && ResetSpell.timer < Engine::GameGetTickCount() && ResetSpell.autoaa && ResetSpell.reset == false)
				{
					ResetSpell.reset = true;
					ResetSpell.timer = Engine::GameGetTickCount() + 1.0f;
					ResetAutoAttack();
				}
			}
		}

		std::vector<CObject*> minions = Engine::GetMinionsAround(me->GetSelfAttackRange() + 550, 2);
		for (auto minion : minions)
		{
			auto active = minion->GetSpellBook()->GetActiveSpellEntry();
			if (active && active->IsAutoAttack() && (minion->IsMelee() || minion->IsRanged() && active->SpellWasCast()))
			{
				if (ActiveAttacks.count(minion->NetworkID()) == 0)
				{
					ActiveAttacks[minion->NetworkID()] = {
					   (uint32_t)minion,
					   (short)active->targetID(),
					   active->StartTick() * 1000.0f - Engine::GetPing() / 2,
					   active->EndTick() * 1000.f,
					   minion->AttackCastDelay() * 1000.f,
					   minion->AttackDelay() * 1000.f,
					   minion->IsMelee() ? FLT_MAX : active->GetSpellData()->MissileSpeed(),
					   false,
					   false
					};
				}
			}
		}

		for (auto actor : global::allyheros)
		{
			CObject* hero = (CObject*)actor.actor;
			auto active = hero->GetSpellBook()->GetActiveSpellEntry();
			if (active && active->IsAutoAttack() && (hero->IsMelee() || hero->IsRanged() && active->SpellWasCast()) && hero->Index() != me->Index())
			{
				if (ActiveAttacks.count(hero->NetworkID()) == 0)
				{
					ActiveAttacks[hero->NetworkID()] = {
					   (uint32_t)hero,
					   (short)active->targetID(),
					   active->StartTick() * 1000.0f - Engine::GetPing() / 2,
					   active->EndTick() * 1000.f,
					   hero->AttackCastDelay() * 1000.f,
					   hero->AttackDelay() * 1000.f,
					   hero->IsMelee() ? FLT_MAX : active->GetSpellData()->MissileSpeed(),
					   false,
					   true
					};
				}
			}
		}

		for (auto turret : Engine::GetTurrets(2))
		{
			auto active = turret->GetSpellBook()->GetActiveSpellEntry();
			if (active && active->IsAutoAttack())
			{
				if (ActiveAttacks.count(turret->NetworkID()) == 0)
				{
					ActiveAttacks[turret->NetworkID()] = {
					(uint32_t)turret,
					(short)active->targetID(),
					(float)Engine::GameTimeTickCount() - Engine::GetPing() / 2,
					active->EndTick() * 1000.f,
					turret->AttackCastDelay() * 1000.f,
					turret->AttackDelay() * 1000.f,
					active->GetSpellData()->MissileSpeed(),
					true
					};

					/*std::cout << active->EndTick() << std::endl;
					std::cout << turret->AttackCastDelay() << std::endl;
					std::cout << turret->AttackDelay() << std::endl;
					std::cout << active->GetSpellData()->MissileSpeed() << std::endl;*/

				}
			}
		}

		if (ActiveAttacks.size() > 0)
		{
			std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
			for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
			{
				auto id = it->first;
				auto data = it->second;
				if (Engine::GameTimeTickCount() > data.endTime)//data.startTime < Engine::GameTimeTickCount() - 3000)
				{
					ActiveAttacks.erase(id);
				}
			}
		}
	}


	bool IssueAttack(CObject* actor)
	{
		if (actor == nullptr || Engine::GameGetTickCount() - last_attackorder < OrbwalkerDelaySpeed->Value * 0.001f || !Attack)
			return false;

		bool hero = actor->IsHero();

		Vector2 W2S_buffer = Engine::WorldToScreenvec2(actor->Position());

		if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen2(W2S_buffer))
		{
			Engine::DisableMove(false);
			if (hero)
			{
				Engine::SetTargetOnlyChampions(true);
			}
			else
			{
				Engine::SetTargetOnlyChampions(false);
				W2S_buffer.y -= 10.f;
			}

			LastTarget = actor;
			last_attackorder = Engine::GameGetTickCount();

			TryRightClick(1, true, W2S_buffer.x, W2S_buffer.y);

			Engine::SetTargetOnlyChampions(false);
			return true;
		}
		return false;
	}

	Vector3 GetOrbwalkPosition() {
		if (ForcedPosition.IsValid()) {
			return ForcedPosition;
		}

		if (me->IsMelee() && StickToTarget->Value && !(global::mode == ScriptMode::Fly)) {
			if ((LastTarget->IsMonster() || LastTarget->IsHero()) && LastTarget->IsValidTarget() && LastTarget->IsMoving()) {
				if (Engine::GetMouseWorldPosition().Distance(LastTarget->Position()) < Engine::GetMouseWorldPosition().Distance(me->Position()))
				{
					if (me->IsInAutoAttackRange(LastTarget, 100.f))
					{
						auto way = LastTarget->GetWaypoints3D();
						if (way.size() > 1)
						{
							return way.back();
						}
					}
				}
			}
		}

		return Vector3::Zero;// Engine::GetMouseWorldPosition();
	}

	//float GetHealthPrediction(CObject* unit, float delta, float delay = 0, bool usedead = false)
	//{
	//	//auto ActiveAttackscache = ActiveAttacks;
	//	auto predictedDamage = 0.0f;
	//	if (ActiveAttacks.size() > 0)
	//	{
	//		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
	//		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
	//		{
	//			auto attack = it->second;
	//			auto attackDamage = 0.0f;
	//			auto source = (CObject*)attack.source;

	//			if (attack.target == unit->Index() && !attack.isTurret && attack.projectileSpeed != FLT_MAX)
	//			{
	//				auto landTime = attack.startTime + attack.Delay + 1000 * std::max(0.0f, unit->Distance(source) - source->BoundingRadius()) / attack.projectileSpeed + delay;

	//				if (landTime < Engine::GameTimeTickCount() + delta)
	//				{
	//					if (usedead)
	//					{
	//						if (!ActiveAttacks[attack.source].dead)
	//						{
	//							attackDamage = source->GetAutoAttackDamage(unit);
	//							ActiveAttacks[attack.source].dead = true;
	//						}
	//					}
	//					else
	//						attackDamage = source->GetAutoAttackDamage(unit);
	//				}

	//			}

	//			predictedDamage += attackDamage;

	//		}
	//	}


	//	return unit->Health() - predictedDamage;
	//}

	float GetPredictionDefault(CObject* unit, float delta, float delay)
	{
		auto ActiveAttackscache = ActiveAttacks;
		auto predHealth = unit->Health();
		if (ActiveAttackscache.size() > 0)
		{
			std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
			for (it = ActiveAttackscache.begin(); it != ActiveAttackscache.end(); it++)
			{
				auto attack = it->second;
				if (attack.target == unit->Index())
				{
					auto damage = 0.0f;
					auto source = (CObject*)attack.source;
					auto timeTillHit = attack.startTime + attack.Delay - Engine::GameTimeTickCount();
					if (attack.projectileSpeed != FLT_MAX) {
						timeTillHit += 1000.f * std::max(0.0f, unit->Distance(source) - source->BoundingRadius()) / attack.projectileSpeed + 10.f;
					}

					while (timeTillHit < delta) {
						if (timeTillHit > 0.0f) {
							damage += source->GetAutoAttackDamage(unit);
						}
						timeTillHit += attack.animationTime;
					}

					predHealth -= damage;

				}
			}
		}
		return predHealth;
	}

	float GetPredictionSimulated(CObject* unit, float time)
	{
		auto ActiveAttackscache = ActiveAttacks;
		float num = 0.0f;
		if (ActiveAttackscache.size() > 0)
		{
			std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
			for (it = ActiveAttackscache.begin(); it != ActiveAttackscache.end(); it++)
			{
				auto item = it->second;
				auto source = (CObject*)item.source;
				if (item.target == unit->Index())
				{
					auto num2 = 0.0f;
					if ((float)(Engine::GameTimeTickCount() - 100) <= (float)item.startTime + item.animationTime)
					{
						int num3 = item.startTime;
						int num4 = Engine::GameTimeTickCount() + time;
						do
						{
							float num5 = item.Delay / 1000.0f + (item.projectileSpeed == FLT_MAX ? 0.0f : (std::max(0.0f, unit->Distance(source) - source->BoundingRadius()) / (float)item.projectileSpeed));
							if (num3 >= Engine::GameTimeTickCount() && (float)num3 + num5 < (float)num4)
							{
								num2++;
							}
							num3 += (int)item.animationTime;
						} while (num3 < num4);
					}
					num += (float)num2 * source->GetAutoAttackDamage(unit);
				}
			}
		}
		return unit->Health() - num;
	}

	float GetHealthPrediction(CObject* unit, float time, float delay = 0, HealthPredictionType type = HealthPredictionType::Default)
	{
		if (type != HealthPredictionType::Simulated)
		{
			return GetPredictionDefault(unit, time, delay);
		}
		return LaneClearHealthPrediction(unit, time + delay);//GetPredictionSimulated(unit, time + delay);
	}

	/*float GetHealthPrediction(CObject* unit, float delta, float delay = 0)
	{
		auto ActiveAttackscache = ActiveAttacks;
		auto predHealth = unit->Health();
		if (ActiveAttackscache.size() > 0)
		{
			std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
			for (it = ActiveAttackscache.begin(); it != ActiveAttackscache.end(); it++)
			{
				auto attack = it->second;
				if (attack.target == unit->Index() && !attack.isTurret)
				{
					auto damage = 0.0f;
					auto source = (CObject*)attack.source;
					auto timeTillHit = attack.startTime + attack.Delay - Engine::GameTimeTickCount();
					if (attack.projectileSpeed != FLT_MAX) {
						timeTillHit += 1000.f * MAX(0.0f, unit->Distance(source) - source->BoundingRadius()) / attack.projectileSpeed + 10.f;
					}

					while (timeTillHit < delta) {
						if (timeTillHit > 0.0f) {
							damage += source->GetAutoAttackDamage(unit);
						}
						timeTillHit += attack.animationTime;
					}

					predHealth -= damage;

				}
			}
		}
		return predHealth;
	}*/


	/*float GetHealthPrediction(CObject* unit, int time, float delay = 0)
	{
		auto predictedDamage = 0.f;
		std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
		for (it = ActiveAttacks.begin(); it != ActiveAttacks.end(); it++)
		{
			auto attack = it->second;
			if (attack.target == unit->Index())
			{
				auto source = (CObject*)attack.source;
				auto landTime = attack.startTime + attack.Delay
					+ 1000.f * max(0.f, unit->Distance(source) - source->BoundingRadius())
					/ attack.projectileSpeed + 10.f;

				if (landTime < Engine::GameTimeTickCount() + time)
				{
					predictedDamage += source->TotalAttackDamage();
				}
			}
		}
		return unit->Health() - predictedDamage;
	}*/

	float LaneClearHealthPrediction(CObject* unit, int time, int delay = 0)
	{
		//return GetPredictionDefault(unit, time, delay);
		//return GetHealthPrediction(unit, time, delay);
		auto ActiveAttackscache = ActiveAttacks;
		auto predictedDamage = 0.f;
		if (ActiveAttackscache.size() > 0)
		{
			std::unordered_map<DWORD, ActiveAttackstruct>::iterator it;
			for (it = ActiveAttackscache.begin(); it != ActiveAttackscache.end(); it++)
			{
				auto attack = it->second;
				if (attack.target == unit->Index() && Engine::GameTimeTickCount() - 100 <= attack.startTime + attack.animationTime /*&& !attack.isTurret*/)
				{
					auto n = 1;
					auto fromT = attack.startTime;
					auto toT = Engine::GameTimeTickCount() + time;
					auto source = (CObject*)attack.source;

					while (fromT < toT)
					{
						auto travelTime = fromT + attack.Delay + 1000.f * std::max(0.f, unit->Distance(source) - source->BoundingRadius()) / attack.projectileSpeed + 10.f;
						if (fromT >= Engine::GameTimeTickCount() && travelTime < toT)
						{
							n++;
						}

						fromT += (int)attack.animationTime;
					}
					predictedDamage += n * source->GetAutoAttackDamage(unit);
				}
			}
		}
		return unit->Health() - predictedDamage;
	}


	float TurretAggroStartTick(CObject* minion)
	{
		if (ActiveAttacks.size() > 0)
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
		}
		return 0.f;
	}
	bool HasMinionAggro(CObject* minion)
	{
		if (ActiveAttacks.size() > 0)
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
		}
		return false;
	}
	bool HasTurretAggro(CObject* minion)
	{
		if (ActiveAttacks.size() > 0)
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
		}
		return false;
	}

	void SetForceTarget(CObject* target)
	{
		targetselector->_selectedTargetObjAiHero = target;
	}

	//std::vector<CObject*> GetMinions(float range = 0, bool jungle = true, bool checkunit = true)
	//{
	//	std::vector<CObject*> list;
	//	std::vector<CObject*> mins;
	//	auto minionkek = Engine::GetMinionsAround(3000.0f, 1);
	//	auto minioncurrentattackrange = Engine::GetMinionsAround(me->GetSelfAttackRange(), 1);
	//	auto junglekek = Engine::GetJunglesAround(3000.0f, 2);

	//	mins.insert(mins.end(), minionkek.begin(), minionkek.end());

	//	if (jungle)
	//		mins.insert(mins.end(), junglekek.begin(), junglekek.end());

	//	if (from(mins) >> any())
	//	{
	//		mins.erase(
	//			std::remove_if(mins.begin(), mins.end(),
	//				[&](CObject* actor) {
	//					return !actor->IsValidTarget(range) || !actor->IsAlive(); }),
	//			mins.end());

	//		if (from(mins) >> any()) list.insert(list.end(), mins.begin(), mins.end());;
	//	}

	//	if (checkunit)
	//		if (/*OrbMenu.Configs.AttacableUnit.AttackJunglePlants.Enabled*/1 ||
	//			/*OrbMenu.Configs.AttacableUnit.AttackPet.Enabled*/2)
	//		{
	//			auto templist = from(minionkek) >> where([&](CObject* h) {return h->IsValidTarget() && me->IsInAutoAttackRange(h) /*&& CheckMinion(h)*/; }) >> to_vector();
	//			list.insert(list.end(), templist.begin(), templist.end());
	//		}

	//	auto closestTower = from(Engine::GetTurrets(2)) >>
	//		orderby([&](const auto& t) { return me->Distance(t, true); }) >> first_or_default();

	//	if (closestTower != nullptr && me->Distance(closestTower, true) < 900 * 900)
	//	{
	//		return from(list)
	//			>> orderby_descending([&](CObject* minion) { return minion->MaxHealth(); })
	//			>> thenby([](CObject* minion) { return !minion->IsMelee(); })
	//			>> thenby_descending([](CObject* minion) { return minion->IsSiegeMinion(); })
	//			>> thenby_descending([](CObject* minion) { return minion->IsSuperMinion(); })
	//			>> thenby([&](CObject* minion) { return GetHealthPrediction(minion, 2000, 70, HealthPredictionType::Simulated); })
	//			>> thenby_descending([](CObject* minion) { return minion->MaxHealth(); })
	//			>> thenby([&](CObject* minion) { return minion->Distance(closestTower); })
	//			>> to_vector();

	//	}

	//	return from(list)
	//		>> orderby_descending([&](CObject* minion) { return minion->MaxHealth(); })
	//		>> thenby([](CObject* minion) { return !minion->IsMelee(); })
	//		>> thenby_descending([](CObject* minion) { return minion->IsSiegeMinion(); })
	//		>> thenby_descending([](CObject* minion) { return minion->IsSuperMinion(); })
	//		>> thenby([&](CObject* minion) { return GetHealthPrediction(minion, 2000); })
	//		>> thenby_descending([](CObject* minion) { return minion->MaxHealth(); })
	//		>> to_vector();
	//}

	//bool ShouldWait()
	//{

	//	auto time = (float)(me->AttackDelay() * 1000.0 * 2.0);

	//	return from(GetMinions(me->GetSelfAttackRange()))
	//		>> any([&](CObject* minion) {return GetHealthPrediction(minion, time, 10.f, HealthPredictionType::Simulated) < me->GetAutoAttackDamage(minion); });
	//}

	/*private static bool CheckMinion(AIMinionClient minion = null, float checkrange = 0)
	{
		if (checkrange <= 0)
			checkrange = ObjectManager.Player.GetCurrentAutoAttackRange();

		return minion != null && minion.Type == GameObjectType.AIMinionClient && minion.IsValid() &&
			(!minion.IsPet() || OrbMenu.Configs.AttacableUnit.AttackPet.Enabled) && minion.IsValidTarget() &&
			!minion.IsDead && !minion.IsAlly &&
			(!minion.GetMinionType().HasFlag(MinionTypes.JunglePlant) ||
				OrbMenu.Configs.AttacableUnit.AttackJunglePlants.Enabled) &&
			(minion.InCurrentAutoAttackRange() || minion.IsValidTarget(checkrange));
	}*/
	CObject* GetTargetMinion()
	{

		auto supportMode = false;

		/*for (auto hero : *ManagerTemplate::Heroes) {
			if (hero != ObjectManager::Player && hero->IsAlly() && hero->IsValidTarget(1050.0f)) {
				supportMode = true;
				break;
			}
		}*/


		if (!supportMode /*|| me->HasBuff(0xC406EAE0)*/) { // "TalentReaper"
			if (LastHitMinion) {
				if (AlmostLastHitMinion && AlmostLastHitMinion != LastHitMinion && AlmostLastHitMinion->IsSiegeMinion()) {
					return nullptr;
				}
				return LastHitMinion;
			}
			if (supportMode || ShouldWait()) {
				return nullptr;
			}
			if (global::mode == ScriptMode::LaneClear) {
				return LaneClearMinion;
			}
		}
		return nullptr;
	}

	CObject* GetTarget()
	{
		CObject* result = nullptr;
		//std::vector<CObject*>list;

		//Forced target
		if (targetselector->SelectedTarget() != nullptr)
		{
			if (targetselector->SelectedTarget()->IsValidTarget() && me->IsInAutoAttackRange(targetselector->SelectedTarget()))
				return targetselector->SelectedTarget();
		}

		/*if ((global::mode == ScriptMode::Mixed || global::mode == ScriptMode::LaneClear) &&
			!LastHitPriority->Value)
		{
			auto target = targetselector->GetTarget(-1);
			if (target != nullptr)
			{
				if (me->IsInAutoAttackRange(target) && target->IsValidTarget())
					return target;
			}
		}*/

		/*if (!(global::mode == ScriptMode::Combo))
		{
			list = from(Engine::GetMinionsAround(me->GetSelfAttackRange() + 100.f, 1)) >> where([&](CObject* h) {return h->IsValidTarget() && me->IsInAutoAttackRange(h); }) >> to_vector();
		}*/


		auto projectileSpeed = (int)GetMyProjectileSpeed();

		/*Killable Minion  */
		if (global::mode == ScriptMode::LastHit)
		{
			auto minion = GetTargetMinion();
			if (minion != nullptr) {
				return minion;
			}
		}

		if (global::mode == ScriptMode::LaneClear || global::mode == ScriptMode::Mixed)
		{
			auto hero = targetselector->GetTarget(-1);
			if (hero != nullptr && LaneClearHeroes->Value && !LastHitPriority->Value) {
				return hero;
			}
			auto minion = GetTargetMinion();
			if (minion != nullptr && minion == LastHitMinion) {
				return minion;
			}
			if (hero != nullptr && LaneClearHeroes->Value && !ShouldWait()) {
				return hero;
			}
		}

		/*Killable Minion NOT USE */
		//if (global::mode == ScriptMode::LaneClear || global::mode == ScriptMode::Mixed || global::mode == ScriptMode::LastHit)
		//{

		//	auto tempList = list;
		//	auto list2 = from(tempList)
		//		>> where([&](CObject* minion) { return minion->IsEnemy() && minion->IsValidTarget() && me->IsInAutoAttackRange(minion); })
		//		>> orderby_descending([&](CObject* minion) { return minion->IsSiegeMinion(); })
		//		>> thenby([&](CObject* minion) { return minion->IsSuperMinion(); })
		//		>> thenby_descending([&](CObject* minion) { return GetHealthPrediction(minion, 1500); })
		//		>> thenby_descending([&](CObject* minion) { return minion->MaxHealth(); }) >> to_vector();



		//	for (auto item2 : list2)
		//	{
		//		if (item2->MaxHealth() <= 10.0f)
		//		{
		//			if (item2->Health() <= 1.0f)
		//			{
		//				return item2;
		//			}
		//		}
		//		else
		//		{
		//			float num6 = me->AttackCastDelay() * 1000.0f - 100.0f + (float)Engine::GetPing() / 2.0f + 1000.0f * std::max(0.0f, me->Distance(item2) - me->BoundingRadius()) / projectileSpeed;

		//			if (!PushPriority->Value)
		//				num6 += 200 + (float)Engine::GetPing() / 2.0f;

		//			float prediction = GetHealthPrediction(item2, num6, ExtraFarmDelay->Value);

		//			if (!PushPriority->Value)
		//			{
		//				if (item2->Health() < me->BaseAttackDamage() || prediction <= me->BaseAttackDamage())
		//				{
		//					return item2;
		//				}
		//			}
		//			else
		//			{

		//				if (prediction <= 0.0f)
		//				{
		//					NonKillableMinion = item2;
		//				}

		//				double autoAttackDamage = me->GetAutoAttackDamage(item2);
		//				if (prediction <= autoAttackDamage && prediction > 0)
		//				{
		//					//LastKillableMinionID = item2->NetworkId;
		//					return item2;
		//				}
		//			}
		//		}
		//	}
		//}

		if (AttackBarrels->Value && (global::mode == ScriptMode::Combo || global::mode == ScriptMode::LaneClear || global::mode == ScriptMode::Mixed || global::mode == ScriptMode::LastHit))
		{
			if (EnemyGangPlank != nullptr)
			{
				//auto time = EnemyGangPlank->Level() >= 13 ?
				//	500 :
				//	EnemyGangPlank->Level() >= 7 ?
				//	1000 :
				//	2000;
				//auto delay = 350;

				//auto meelebarrels = from(Cache::Barrels)
				//	>> where([&](const Barrel& x) { return me->IsInAutoAttackRange(x.Bottle)
				//		&& (/*Engine::GameTimeTickCount() - x.CreationTime >= 2 * time - Engine::GetPing() - me->AttackCastDelay() * 1000 + 50 - delay
				//			||*/ (Engine::GameTimeTickCount() - x.CreationTime >= time - Engine::GetPing() - me->AttackCastDelay() * 1000 + 50 - delay && x.Bottle->Health() == 2
				//				&& Engine::GameTimeTickCount() - x.CreationTime <= time) ?
				//			true : false
				//			|| x.Bottle->Health() == 1); }) >> to_vector();

				//if (meelebarrels.size() > 0)
				//	return meelebarrels.front().Bottle;
				auto barrels = from(Cache::Barrels)
					>> where([&](const Barrel& x) { return x.Bottle->Health() <= 2.f && me->IsInAutoAttackRange(x.Bottle) && x.Bottle->IsValidTarget(); });

				for (auto barrelz : barrels >> to_vector())
				{
					auto barrel = barrelz.Bottle;
					if (barrel->Health() <= 1.f)
						return barrel;

					auto t = (int)(me->AttackCastDelay() * 1000) + Engine::GetPing() / 2 + 1000 * (int)std::max(0.f, me->Distance(barrel) - me->BoundingRadius()) / projectileSpeed;

					auto barrelBuff = barrel->GetBuffManager()->GetBuffCacheByFNVHash(FNV("gangplankebarrelactive"));

					if (barrelBuff.count > 0 && barrel->Health() <= 2.f)
					{
						auto healthDecayRate = EnemyGangPlank->Level() >= 13 ? 0.5f : (EnemyGangPlank->Level() >= 7 ? 1.f : 2.f);
						auto nextHealthDecayTime = Engine::GameGetTickCount() < barrelBuff.starttime + healthDecayRate ? barrelBuff.starttime + healthDecayRate : barrelBuff.starttime + healthDecayRate * 2;

						if (nextHealthDecayTime <= Engine::GameGetTickCount() + t / 1000.f)
							return barrel;
					}
				}
				if (barrels >> any())
					return nullptr;
			}
		}

		/*Champions*/
		if (!(global::mode == ScriptMode::LastHit) && global::mode != ScriptMode::None)
		{
			auto target = targetselector->GetTarget(-1);
			if (target != nullptr)
			{
				if (target->IsValidTarget() && me->IsInAutoAttackRange(target))
				{
					if (!Engine::UnderTurret(me->Position()) && (global::mode == ScriptMode::LaneClear && LaneClearHeroes->Value) || global::mode == ScriptMode::Combo)
						return target;
				}
			}
		}

		/*Jungle minions*/
		if (global::mode == ScriptMode::LaneClear || global::mode == ScriptMode::Mixed)
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

		/*PETS*/
		if (global::mode != ScriptMode::Combo && AutoPetsTraps->Value)
		{
			auto pet_list = Engine::GetPetsAround(3000.0f);
			auto pets = from(pet_list) >> where([&](CObject* h) {return h->IsValidTarget() && me->IsInAutoAttackRange(h); }) >> to_vector();
			if (pets.size() > 0)
				return pets.front();
		}

		if (global::mode == ScriptMode::LaneClear || global::mode == ScriptMode::Mixed)
		{
			for (auto turret_actor : global::turrets)
			{
				auto t = (CObject*)turret_actor;
				if (t->IsValidTarget() && me->IsInAutoAttackRange(t) && t->IsEnemy())
					return t;
			}

			for (auto inhib_actor : Engine::GetInhib())
			{

				if (inhib_actor->IsValidTarget() && me->IsInAutoAttackRange(inhib_actor, 110.f) && inhib_actor->IsEnemy())
					return inhib_actor;
			}

		}


		/* UnderTurret Farming 2 METHOD*/

		// METHOD 1
		/*if ((mode== ScriptMode::LaneClear || mode== ScriptMode::Mixed || mode== ScriptMode::LastHit) && CanAttack() && me->Level() < 17)
		{
			auto closestTower = from(Engine::GetTurrets(2)) >>
				where([&](const auto& t) { return t->Distance(me) <= 1500; })
				>> orderby([&](const auto& t) { return t->Distance(Engine::GetMouseWorldPosition(), true); }) >> first_or_default();

			if (closestTower != nullptr)
			{

				auto list = from(Engine::GetMinionsAround(FLT_MAX, 1))
					>> where([&](const auto& minion) { return minion->Distance(closestTower, true) < pow(900, 2); })
					>> orderby([&](const auto& x) { return x->Distance(closestTower); });

				if (list >> any())
				{
					auto turretMinion = list >> first_or_default([&](const auto& x) { return HasTurretAggro(x); });

					if (turretMinion != nullptr)
					{
						auto towerDamage = closestTower->GetAutoAttackDamage(turretMinion);

						auto n1 = (float)(TowerAttackCastDelay * 1000.0 + 1000.0 *
							std::max(0.0f, turretMinion->Distance(closestTower) - 88.5f) /
							(1200 + 70.0));

						auto n2 = (float)(me->AttackCastDelay() * 1000.0 - 100.0 + Engine::GetPing() / 2.0 +
							1000.0 * std::max(0.0f,
								me->Distance(turretMinion) -
								me->BoundingRadius()) / projectileSpeed);

						auto prediction = GetHealthPrediction(turretMinion, (int)(n1 + n2), 0);
						if (prediction > towerDamage)
						{
							auto aa = me->GetAutoAttackDamage(turretMinion);
							if (prediction > towerDamage + aa && prediction < towerDamage + aa * 2)
							{
								return turretMinion;
							}

							for (auto nextMinion : list >> where([&](const auto& x) { return !HasTurretAggro(x); }) >> to_vector())
							{
								auto playerDamageToNext = me->GetAutoAttackDamage(nextMinion);
								auto towerDamageToNext = closestTower->GetAutoAttackDamage(nextMinion);

								if (HasMinionAggro(nextMinion))
								{
									continue;
								}

								auto time = (float)(me->AttackCastDelay() * 1000.0 - 100.0 +
									Engine::GetPing() / 2.0 + 1000.0 * std::max(0.0f,
										me->Distance(nextMinion) -
										me->BoundingRadius()) / projectileSpeed);

								auto healthPrediction = GetHealthPrediction(nextMinion, (int)(time + n1), 10);

								if ((healthPrediction < towerDamageToNext * 2.0 || healthPrediction >
									towerDamageToNext * 2.0 + playerDamageToNext) &&
									(healthPrediction > towerDamageToNext + playerDamageToNext &&
										healthPrediction <= towerDamageToNext + playerDamageToNext * 2.0 ||
										healthPrediction > towerDamageToNext * 2.0 + playerDamageToNext * 2.0))
								{
									return nextMinion;
								}
							}
						}

						auto minion = list >> first_or_default();

						if (minion != nullptr)
						{
							auto damage = closestTower->GetAutoAttackDamage(minion);
							auto healthPrediction = GetHealthPrediction(minion, 1500, 10) - damage * 1.1f;

							if (healthPrediction > me->GetAutoAttackDamage(minion) &&
								healthPrediction < damage * 1.1f || healthPrediction >
								damage * 2.0 + me->GetAutoAttackDamage(minion) * 2.0)
							{
								return minion;
							}
						}

						return nullptr;
					}
				}
			}
		}*/

		if ((global::mode == ScriptMode::LaneClear || global::mode == ScriptMode::Mixed || global::mode == ScriptMode::LastHit) && CanAttack() && me->Level() < 17)
		{
			auto turrets_list = Engine::GetTurrets(2);
			auto closestTower = from(turrets_list) >>
				orderby([&](CObject* t) { return me->Distance(t, true); }) >> first_or_default();

			if (closestTower != nullptr && me->Distance(closestTower, true) < 900 * 900)
			{
				CObject* farmUnderTurretMinion = nullptr;
				CObject* noneKillableMinion = nullptr;
				// return all the minions underturret in auto attack range
				auto minions_turret_list = Engine::GetMinionsAround(me->GetSelfAttackRange(), 1);
				auto minions = from(minions_turret_list)
					>> where([&](CObject* minion) { return closestTower->Distance(minion, true) < 900 * 900; })
					>> orderby_descending([](CObject* minion) { return minion->IsSiegeMinion(); })
					>> thenby([](CObject* minion) { return minion->IsSuperMinion(); })
					>> thenby_descending([](CObject* minion) { return minion->MaxHealth(); })
					>> thenby_descending([](CObject* minion) { return minion->Health(); });

				if (minions >> any())
				{
					// get the turret aggro minion
					CObject* turretMinion = nullptr;

					for (auto minion : minions >> to_vector())
					{
						if (HasTurretAggro(minion))
						{
							turretMinion = minion;
							break;
						}
					};

					if (turretMinion != nullptr)
					{
						float hpLeftBeforeDie = 0;
						float hpLeft = 0;
						float turretAttackCount = 0;
						float turretStarTick = TurretAggroStartTick(
							turretMinion);
						// from healthprediction (don't blame me :S)
						auto turretLandTick = turretStarTick + (int)(closestTower->AttackCastDelay() * 1000) +
							1000 *
							std::max(
								0,
								(int)
								(turretMinion->Distance(closestTower) -
									88.5f)) / //closestTower.BoundingRadius
							(int)(1200 + 70); //closestTower.BasicAttack.MissileSpeed

				// calculate the HP before try to balance it
						for (float i = turretLandTick + 50;
							i < turretLandTick + 10 * closestTower->AttackDelay() * 1000 + 50;
							i = i + closestTower->AttackDelay() * 1000)
						{
							auto time = (int)i - (Engine::GameTimeTickCount() + Engine::GetPing() / 2);

							auto predHP =
								(int)
								LaneClearHealthPrediction(
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
							auto damage = (int)me->GetAutoAttackDamage(turretMinion);
							auto hits = hpLeftBeforeDie / damage;
							auto timeBeforeDie = turretLandTick +
								(turretAttackCount + 1) *
								(int)(closestTower->AttackDelay() * 1000) -
								Engine::GameTimeTickCount();
							auto timeUntilAttackReady = LastAATick() + (int)(me->AttackDelay() * 1000) >
								Engine::GameTimeTickCount() + Engine::GetPing() / 2 + 25
								? LastAATick() + (int)(me->AttackDelay() * 1000) -
								(Engine::GameTimeTickCount() + Engine::GetPing() / 2 + 25)
								: 0;
							auto timeToLandAttack = me->IsMelee()
								? me->AttackCastDelay() * 1000
								: me->AttackCastDelay() * 1000 +
								1000 * std::max(0.f, turretMinion->Distance(me) - global::LocalData->gameplayRadius) /
								global::LocalData->basicAttackMissileSpeed;
							if (hits >= 1 &&
								hits * me->AttackDelay() * 1000 + timeUntilAttackReady + timeToLandAttack <
								timeBeforeDie)
							{
								//std::cout << "event 1 " << std::endl;
								farmUnderTurretMinion = turretMinion;
							}
							else if (hits >= 1 &&
								hits * me->AttackDelay() * 1000 + timeUntilAttackReady + timeToLandAttack >
								timeBeforeDie)
							{
								//std::cout << "event 2 " << std::endl;
								noneKillableMinion = turretMinion;
							}
						}
						else if (hpLeft == 0 && turretAttackCount == 0 && hpLeftBeforeDie == 0)
						{
							//std::cout << "event 3 " << std::endl;
							noneKillableMinion = turretMinion;
						}
						// should wait before attacking a minion.
						if (ShouldWaitUnderTurret(noneKillableMinion))
						{
							//std::cout << "event 4 " << std::endl;
							return nullptr;
						}
						if (farmUnderTurretMinion != nullptr)
						{
							// std::cout << "event 5 " << std::endl;
							return farmUnderTurretMinion;
						}
						// balance other minions
						for (auto minion :
							minions >> where(
								[&](CObject* x) { return
								x->NetworkID() != turretMinion->NetworkID() &&
								!HasMinionAggro(x); }) >> to_vector()
							)
						{
							auto playerDamage = (int)me->GetAutoAttackDamage(minion);
							auto turretDamage = (int)closestTower->GetAutoAttackDamage(minion);
							auto leftHP = (int)minion->Health() % turretDamage;
							if (leftHP > playerDamage)
							{
								//std::cout << "playerDamage  " << playerDamage << std::endl;
								//std::cout << "turretDamage  " << turretDamage << std::endl;
								//std::cout << "leftHP  " << leftHP << std::endl;
								//std::cout << "leftHP2  " << minion->Health() - turretDamage << std::endl;
								//std::cout << "event 6 " << std::endl;
								return minion;
							}
						}
						// late game
						auto lastminion = minions >> where([&](CObject* x) { return x->NetworkID() != turretMinion->NetworkID() &&
							!HasMinionAggro(x); }) >> last_or_default();

						if (lastminion != nullptr && minions >> count() >= 2)
						{
							if (1.f / me->AttackDelay() >= 1.f &&
								(int)(turretAttackCount * closestTower->AttackDelay() / me->AttackDelay()) *
								me->GetAutoAttackDamage(lastminion) > lastminion->Health())
							{
								//std::cout << "event 7 " << std::endl;
								return lastminion;
							}
							if (minions >> count() >= 5 && 1.f / me->AttackDelay() >= 1.2)
							{
								//std::cout << "event 8 " << std::endl;
								return lastminion;
							}
						}
					}
					else
					{
						//std::cout << "turretMinion == nullptr" << std::endl;
						if (ShouldWaitUnderTurret(noneKillableMinion))
						{
							return nullptr;
						}
						// balance other minions
						for (auto minion :
							minions >> where(
								[&](CObject* x) { return !HasMinionAggro(x); }) >> to_vector()
							)
						{
							if (closestTower != nullptr)
							{
								auto playerDamage = (int)me->GetAutoAttackDamage(minion);
								auto turretDamage = (int)closestTower->GetAutoAttackDamage(minion);
								auto leftHP = (int)minion->Health() % turretDamage;
								if (leftHP > playerDamage)
								{
									//std::cout << "playerDamage  " << playerDamage << std::endl;
									//std::cout << "turretDamage  " << turretDamage << std::endl;
									//std::cout << "event 9 " << std::endl;
									return minion;
								}
							}
						}
						//late game
						auto lastminion = minions >> where(
							[&](CObject* x) { return !HasMinionAggro(x); }) >> last_or_default();
						if (lastminion != nullptr && minions >> count() >= 2)
						{
							if (minions >> count() >= 5 && 1.f / me->AttackDelay() >= 1.2)
							{
								//std::cout << "event 10 " << std::endl;
								return lastminion;
							}
						}
					}
					return nullptr;
				}
			}
		}



		if (global::mode == ScriptMode::LaneClear || global::mode == ScriptMode::Mixed)
		{
			auto minion = GetTargetMinion();
			if (minion != nullptr) {
				return minion;
			}
		}

		//// METHOD 2
		//if ((mode== ScriptMode::LaneClear || mode== ScriptMode::Mixed || mode && ScriptMode::LastHit) && CanAttack() && me->Level() < 17)
		//{
		//	auto closestTower = from(Engine::GetTurrets(2)) >>
		//		orderby([&](const auto & t) { return me->Distance(t, true); }) >> first_or_default();

		//	if (closestTower != nullptr && me->Distance(closestTower, true) < 1500 * 1500)
		//	{
		//		// return all the minions underturret in auto attack range
		//		auto minions = from(Engine::GetMinionsAround(me->GetSelfAttackRange() + 200, 1))
		//			>> where([&](const auto & minion) { return me->IsInAutoAttackRange(minion) && closestTower->Distance(minion, true) < 900 * 900; })
		//			>> orderby([&](const auto & minion) { return minion->Distance(closestTower); });

		//		if (minions >> any())
		//		{
		//			// get the turret aggro minion

		//			auto turretMinion =
		//				minions >> first_or_default(
		//					[&](const auto & x) { return HasTurretAggro(x); });

		//			if (turretMinion->IsLaneMinion())
		//			{
		//				auto damageOnMinion = closestTower->GetAutoAttackDamage(turretMinion);

		//				auto minionHpPred = GetHealthPrediction(turretMinion, 1500) - damageOnMinion;
		//				if (minionHpPred > me->GetAutoAttackDamage(turretMinion) && minionHpPred < damageOnMinion)
		//					return turretMinion;
		//			}

		//			auto nextMinion =
		//				minions >> first_or_default(
		//					[&](const auto & x) { return !HasTurretAggro(x); });

		//			if (nextMinion->IsLaneMinion())
		//			{
		//				auto damageOnMinion = closestTower->GetAutoAttackDamage(nextMinion);
		//				auto minionHpPred = GetHealthPrediction(nextMinion, 1500) - damageOnMinion;
		//				if (minionHpPred > me->GetAutoAttackDamage(nextMinion) && minionHpPred < damageOnMinion)
		//					return nextMinion;
		//			}

		//			auto minionToTryKill = minions
		//				>> where([&](const auto & x) { return closestTower->GetAutoAttackDamage(x) > x->Health()
		//					&& me->GetAutoAttackDamage(x) < x->Health(); }) >> last_or_default();

		//			if (minionToTryKill != nullptr)
		//				return minionToTryKill;

		//			if (mode== ScriptMode::LaneClear && minions >> count() > 3)
		//			{
		//				auto lastMinion = minions
		//					>> where([&](const auto & x) { return !HasMinionAggro(x); }) >> last_or_default();

		//				if (lastMinion != nullptr)
		//					return lastMinion;
		//			}
		//			return nullptr;
		//		}
		//	}
		//}
		/*if (global::mode == ScriptMode::LaneClear)
		{
			auto minion = GetTargetMinion();
			if (minion) {
				return minion;
			}
		}*/
		/*Lane Clear minions*/
		//if (global::mode == ScriptMode::LaneClear)
		//{
		//	if (!ShouldWait())
		//	{
		//		/*std::vector<CObject*> laneclearminion_list = {};

		//		auto t = (int)(Engine::AttackCastDelayLastHit() * 1000) - 30 + 1000 * (int)max(0, 500) / (int)GetMyProjectileSpeed();
		//		float laneClearDelay = me->AttackDelay() * 1000 * LaneClearWaitTimeMod + t;

		//		if (minionListAA.size() > 0)
		//		{
		//			for (auto minion : minionListAA)
		//			{
		//				float predHealth = LaneClearHealthPrediction(minion, laneClearDelay);
		//				if (abs(predHealth - minion->Health()) < FLT_EPSILON || predHealth >= (2 * me->CalculateDamage(minion, me->TotalAttackDamage())))
		//					laneclearminion_list.push_back(minion);
		//			}
		//		}

		//		if (laneclearminion_list.size() > 0)
		//		{
		//			sort(laneclearminion_list.begin(), laneclearminion_list.end(), [&](CObject* minion, CObject* minion2) {
		//				return minion->Health() - LaneClearHealthPrediction(minion, (int)(laneClearDelay)) < minion2->Health() - LaneClearHealthPrediction(minion2, (int)(laneClearDelay));
		//			});


		//			result = laneclearminion_list[0];
		//		}*/

		//		auto firstT2 = (int)(me->AttackDelay() * 1000 * LaneClearWaitTimeMod()) + (int)(me->AttackCastDelay() * 1000) + BrainFarmInt + Engine::GetPing() / 2;

		//		for (auto minion : from(Engine::GetMinionsAround(3000, 1))
		//			>> where([&](CObject* minion) { return me->IsInAutoAttackRange(minion); })
		//			>> orderby([](CObject* minion) { return minion->Health(); }) >> to_vector())
		//		{
		//			auto t = firstT2 + 1000 * (int)MAX(0, me->ServerPosition().Distance(minion->ServerPosition()) - global::LocalData->gameplayRadius) / projectileSpeed;

		//			auto predHealth = LaneClearHealthPrediction(minion, t);
//			if (abs(predHealth - minion->Health()) < FLT_EPSILON)
//				return minion;
//			auto damage = me->GetAutoAttackDamage(minion);
//			if (predHealth >= (2 - 0.01 * LaneClearSpeed->Value) * damage)
//				return minion;
//		}
//	}

//}


		return result;
	}

	bool WindWallCheck(Vector2 pos)
	{
		if (Engine::GameGetTickCount() - Cache::windwall.time < 0.1f && me->IsRanged() && global::LocalChampNameHash != FNV("Senna"))
		{
			auto windwall = Cache::windwall;
			if (XPolygon::LineSegmentIntersection(windwall.StartPos, windwall.Pos, me->Pos2D(), pos).IsValid())
			{
				return true;
			}
		}
		return false;
	}

	void OrbWalk(CObject* actor, bool Ap = false, float extrarange = 1.5f)
	{
		if (me->IsDashing()) {
			return;
		}

		if (actor != nullptr)
		{
			if (actor->IsValidTarget())
			{
				if (CanAttack() && !global::blockOrbAttack && me->IsInAutoAttackRange(actor))
				{
					if (BeforeAttackEvent(actor))
					{
						if (!WindWallCheckVar || WindWallCheckVar && !WindWallCheck(actor->Pos2D()))
						{
							IssueAttack(actor);
							return;
						}
					}
				}
			}
		}

		if (CanMove(ExtraWindUpTime->Value) && !global::blockOrbMove)
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
		if (ComboKey->Value)
			global::mode = ScriptMode::Combo;
		else if (MixedKey->Value)
			global::mode = ScriptMode::Mixed;
		else if (LaneClearKey->Value)
			global::mode = ScriptMode::LaneClear;
		else if (JungleClearKey->Value)
			global::mode = ScriptMode::JungleClear;
		else if (LastHitKey->Value)
			global::mode = ScriptMode::LastHit;
		else if (FlyKey->Value)
			global::mode = ScriptMode::Fly;
		else
			global::mode = ScriptMode::None;

		if (!me->IsAlive() || !UseOrbWalker || global::mode == ScriptMode::None || (justevade->BlockAttack->Value && (justevade->Evade->Value || justevade->HoldEvade->Value) && justevade->SafePos.IsValid())  /*|| Engine::IsCastingInterruptableSpell(me)*/)
			return;

		LastHitMinion = nullptr;
		AlmostLastHitMinion = nullptr;
		LaneClearMinion = nullptr;

		auto attackCalc = (me->AttackDelay() * 1000 * LaneClearWaitTimeMod()) + (int)(me->AttackCastDelay() * 1000) + BrainFarmInt + Engine::GetPing() / 2 + 1000 * 500 / (int)GetMyProjectileSpeed();
		/*auto attackCalc = (int)(me->AttackDelay() * 1000 + (me->IsMelee() ? me->AttackCastDelay() * 1000 : me->AttackCastDelay() * 1000 +
			1000 * (me->AttackRange() + 2 * global::LocalData->gameplayRadius) / global::LocalData->basicAttackMissileSpeed));*/
		auto attackMissileSpeed = GetMyProjectileSpeed();
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
			float num6 = me->AttackCastDelay() * 1000.0f - 100.0f + (float)Engine::GetPing() / 2.0f + 1000.0f * std::max(0.0f, me->Distance(minion) - me->BoundingRadius()) / attackMissileSpeed;
			/*if (!PushPriority->Value)
				num6 += 200 + (float)Engine::GetPing() / 2.0f;*/

			lastHitHealth = GetHealthPrediction(minion, num6, ExtraFarmDelay->Value);
			laneClearHealth = LaneClearHealthPrediction(minion, attackCalc, ExtraFarmDelay->Value);

			auto health = laneClearHealth; // lastHitHealth if turret is targetting
			auto attackDamage = me->GetAutoAttackDamage(minion);

			if (lastHitHealth > 0 && lastHitHealth < attackDamage) {
				if (!LastHitMinion /*|| !LastHitMinion->IsValidTarget()*/ || (minion->MaxHealth() == LastHitMinion->MaxHealth() ? lastHitHealth < LastHitMinion_lastHitHealth : minion->MaxHealth() > LastHitMinion->MaxHealth())) {
					LastHitMinion = minion;
					LastHitMinion_lastHitHealth = lastHitHealth;
				}
			}
			else if (health <= (minion->IsSiegeMinion() ? 1.5f : 1.0f) * attackDamage && health < minion->Health()) {
				if (!AlmostLastHitMinion /*|| !AlmostLastHitMinion->IsValidTarget()*/ || (minion->MaxHealth() == AlmostLastHitMinion->MaxHealth() ? laneClearHealth < AlmostLastHitMinion_laneClearHealth : minion->MaxHealth() > AlmostLastHitMinion->MaxHealth())) {
					AlmostLastHitMinion = minion;
					AlmostLastHitMinion_laneClearHealth = laneClearHealth;
					LastShouldWait = Engine::GameGetTickCount();
				}
			}
			else if (global::mode == ScriptMode::LaneClear) {
				bool isLaneClearMinion = true;
				//for (auto tur : global::turrets) {
				//	CObject* turret = (CObject*)tur;
				//	if (turret->IsAlly() && turret->IsInAutoAttackRange(minion)) {
				//		if (laneClearHealth == minion->Health()) {
				//			auto turretDamage = turret->GetAutoAttackDamage(minion);
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

				if (laneClearHealth > (2.0f - 0.01f * LaneClearSpeed->Value) * attackDamage || laneClearHealth == minion->Health()) {
					if (!LaneClearMinion /*|| !LaneClearMinion->IsValidTarget()*/ || (PushPriority->Value ? laneClearHealth < LaneClearMinion_laneClearHealth : laneClearHealth > LaneClearMinion_laneClearHealth)) { // 1 = push 
						LaneClearMinion = minion;
						LaneClearMinion_laneClearHealth = laneClearHealth;
					}
				}
			}

		}

		if (LastTarget && !LastTarget->IsValidTarget()) {
			LastTarget = nullptr;
		}

		OrbWalk(GetTarget());

		Attack = true;

		if (AfterAutoAttack())
		{
			AfterAttackEvent(LastTarget);
		}
	}
};


Orbwalker* orbwalker = nullptr;

void ResetAutoAttack()
{
	orbwalker->LastAATick(0);
}