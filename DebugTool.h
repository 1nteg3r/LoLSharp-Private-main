#pragma once


class Debugger : public ModuleManager {
private:
	CheckBox* showstat;
	CheckBox* showase;
	CheckBox* showbuffs;
	CheckBox* showminions;
	CheckBox* showheroes;
	CheckBox* showparts;
	CheckBox* showskilldamage;
	CheckBox* showskinhash;

	std::string Name = me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName();
	std::string MissleName = me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetMissileName();
	float StartTick = me->GetSpellBook()->GetActiveSpellEntry()->StartTick();
	float CastTime = me->GetSpellBook()->GetActiveSpellEntry()->CastTime();
	float MidTick = me->GetSpellBook()->GetActiveSpellEntry()->MidTick();
	float EndTick = me->GetSpellBook()->GetActiveSpellEntry()->EndTick();
	float CastDelay = me->GetSpellBook()->GetActiveSpellEntry()->CastDelay();
	float Delay = me->GetSpellBook()->GetActiveSpellEntry()->Delay();
	bool isBasicAttack = me->GetSpellBook()->GetActiveSpellEntry()->isBasicAttack();
	bool IsSpecialAttack = me->GetSpellBook()->GetActiveSpellEntry()->IsSpecialAttack();
	bool isAutoAttackAll = me->GetSpellBook()->GetActiveSpellEntry()->isAutoAttackAll();
	kSpellSlot Slot = me->GetSpellBook()->GetActiveSpellEntry()->Slot();
	bool IsCastingSpell = me->GetSpellBook()->GetActiveSpellEntry()->IsStopped();
	bool IsInstantCast = me->GetSpellBook()->GetActiveSpellEntry()->IsInstantCast();
	bool SpellWasCast = me->GetSpellBook()->GetActiveSpellEntry()->SpellWasCast();
	Vector3 GetStartPos = me->GetSpellBook()->GetActiveSpellEntry()->GetStartPos();
	Vector3 GetEndPos = me->GetSpellBook()->GetActiveSpellEntry()->GetEndPos();

	//CheckBox* useHeal;
	//Slider* HealthThreshold;

	//CheckBox* useIgnite;
	//CheckBox* useSmite;
	//CheckBox* useSmiteOnEnemy;
	//CheckBox* useSmiteEnemyAround;

	//CheckBox* useItem;
	//CheckBox* usePotion;
	//Slider* PotionHealthThreshold;
	//CheckBox* usePotionEnemyAround;

	//CheckBox* EnableCleanse;
	//CheckBox* OnlyuseinCombo;
	//CheckBox* Stun;
	//CheckBox* Snare;
	//CheckBox* Charm;
	//CheckBox* Fear;
	//CheckBox* Suppression;
	//CheckBox* Taunt;
	//CheckBox* Blind;
public:
	

	Debugger()
	{

	}

	~Debugger()
	{

	}
	float CalcExtraDmg(CObject* unit)
	{
		float total = 0;
		bool Passive = me->HasBuff("ireliapassivestacksmax");
		auto PassiveDmg = me->CalculateDamage(unit, (10 + 3 * me->Level() - 1) + (0.20 * me->BonusAttackDamage()));

		if (Passive)
			total = PassiveDmg;
		else
			total = 0;

		return total;
	}
	void Draw()
	{

		if (showstat->Value)
		{
			ImGui::Text(textonce("Ping: %i "), Engine::GetPing());
			ImGui::Text(textonce("is dashing : %i"), me->GetAIManager()->IsDashing());
			ImGui::Text(textonce("is moving : %i"), me->GetAIManager()->IsMoving());
			ImGui::Text(textonce("dash speed : %.0f"), me->GetAIManager()->DashSpeed());
			ImGui::Text(textonce("Name: %s "), me->ChampionName().c_str());
			ImGui::Text(textonce("Team: %i "), me->Team());
			ImGui::Text(textonce("Level: %i "), me->Level());
			ImGui::Text(textonce("MaxMana: %.0f "), me->MaxMana());
			ImGui::Text(textonce("Mana: %.0f "), me->Mana());
			ImGui::Text(textonce("MaxHealth: %.0f "), me->MaxHealth());
			ImGui::Text(textonce("Health: %.0f "), me->Health());
			ImGui::Text(textonce("BaseAttackDamage: %.0f "), me->BaseAttackDamage());
			ImGui::Text(textonce("BonusAttackDamage: %.0f"), me->BonusAttackDamage());
			ImGui::Text(textonce("TotalAP: %.0f "), me->TotalAbilityPower());
			ImGui::Text(textonce("BonusMagicDamage: %.0f "), me->BonusMagicDamage());
			ImGui::Text(textonce("Armor: %.0f "), me->Armor());
			ImGui::Text(textonce("mBonusArmor: %.0f "), me->BonusArmor());
			ImGui::Text(textonce("MRes: %.0f "), me->MRes());
			ImGui::Text(textonce("BonusMRes: %.0f "), me->BonusMRes());
			ImGui::Text(textonce("MoveSpeed: %.0f "), me->MoveSpeed());
			ImGui::Text(textonce("AttackRange: %.0f "), me->AttackRange());
			ImGui::Text(textonce("AttackSpeed: %.2f "), me->AttackSpeed());
			ImGui::Text(textonce("ArmorPen: %.0f "), me->ArmorPen());
			ImGui::Text(textonce("MagicPen: %.0f "), me->MagicPen());
			ImGui::Text(textonce("ArmorPenPercent: %.2f "), me->ArmorPenPercent());
			ImGui::Text(textonce("MagicPenPercent: %.2f "), me->MagicPenPercent());
			ImGui::Text(textonce("BoundingRadius: %.0f "), me->BoundingRadius());
			ImGui::Text(textonce("AdditionalMana: %.0f "), me->GetSpellBook()->GetSpellSlotByID(3)->AdditionalMana());
			ImGui::Text(textonce("SkinHash: %x "), me->GetSkinData()->GetSkinHash());
		}

		if (showase->Value)
		{
			if (me->GetSpellBook()->GetActiveSpellEntry())
			{
				 Name = me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetSpellName();
				 MissleName = me->GetSpellBook()->GetActiveSpellEntry()->GetSpellData()->GetMissileName();
				 StartTick = me->GetSpellBook()->GetActiveSpellEntry()->StartTick();
				 CastTime = me->GetSpellBook()->GetActiveSpellEntry()->CastTime();
				 MidTick = me->GetSpellBook()->GetActiveSpellEntry()->MidTick();
				 EndTick = me->GetSpellBook()->GetActiveSpellEntry()->EndTick();
				 CastDelay = me->GetSpellBook()->GetActiveSpellEntry()->CastDelay();
				 Delay = me->GetSpellBook()->GetActiveSpellEntry()->Delay();
				 isBasicAttack = me->GetSpellBook()->GetActiveSpellEntry()->isBasicAttack();
				 IsSpecialAttack = me->GetSpellBook()->GetActiveSpellEntry()->IsSpecialAttack();
				 isAutoAttackAll = me->GetSpellBook()->GetActiveSpellEntry()->isAutoAttackAll();
				 Slot = me->GetSpellBook()->GetActiveSpellEntry()->Slot();
				 IsCastingSpell = me->GetSpellBook()->GetActiveSpellEntry()->IsCastingSpell();
				 IsInstantCast = me->GetSpellBook()->GetActiveSpellEntry()->IsInstantCast();
				 SpellWasCast = me->GetSpellBook()->GetActiveSpellEntry()->SpellWasCast();
				 GetStartPos = me->GetSpellBook()->GetActiveSpellEntry()->GetStartPos();
				 GetEndPos = me->GetSpellBook()->GetActiveSpellEntry()->GetEndPos();
				
			}
			ImGui::Text(textonce("Name : %s "), Name.c_str());
			ImGui::Text(textonce("MissleName : %s "), MissleName.c_str());
			ImGui::Text(textonce("Start Tick: %.2f "), StartTick);
			ImGui::Text(textonce("CastTime: %.2f "), CastTime);
			ImGui::Text(textonce("Mid Tick: %.2f "), MidTick);
			ImGui::Text(textonce("End Tick: %.2f "), EndTick);
			ImGui::Text(textonce("CastDelay: %.2f "), CastDelay);
			ImGui::Text(textonce("Delay: %.2f "), Delay);
			ImGui::Text(textonce("isBasicAttack: %i "), isBasicAttack);
			ImGui::Text(textonce("IsSpecialAttack: %i "), IsSpecialAttack);
			ImGui::Text(textonce("isAutoAttackAll: %i "), isAutoAttackAll);
			ImGui::Text(textonce("Slot: %i "), Slot);
			ImGui::Text(textonce("IsCastingSpell: %i "), IsCastingSpell);
			ImGui::Text(textonce("IsInstantCast: %i "), IsInstantCast);
			ImGui::Text(textonce("SpellWasCast: %i "), SpellWasCast);
			ImGui::Text(textonce("GetStartPos: %0.f,%0.f,%0.f "), GetStartPos.x, GetStartPos.y, GetStartPos.z);
			ImGui::Text(textonce("GetEndPos: %0.f,%0.f,%0.f "), GetEndPos.x, GetEndPos.y, GetEndPos.z);
		}
		/*if (showskilldamage->Value)
		{
			for (auto actor : Cache::AllMinionsObj)
			{
				auto minion = (CObject*)actor;
				if (minion)
				{
					auto position = Engine::WorldToScreen(minion->Position());
					auto QDmg = GetSpellDamage(me, minion, SpellSlot::Q);

					Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(position.x, position.y), 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "Q: %.0f + Extra :%.0f = %.0f ", QDmg, CalcExtraDmg(minion), QDmg + CalcExtraDmg(minion));
				}
			}
		}
		if (showminions->Value)
		{
			for (auto actor : Cache::AllMinionsObj)
			{
				auto minion = (CObject*)actor;
				if (minion->IsEnemy())
				{
					auto position = Engine::WorldToScreen(minion->Position());
					Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(position.x, position.y), 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%s %x %x", minion->Name().c_str(), minion, minion->Index());
				}
			}
		}*/
		if (showskinhash->Value)
		{
			auto jungle = Engine::GetJunglesAround(1000.0f, 2);
			for (auto actor : jungle)
			{
				auto minion = (CObject*)actor;
				if (minion->IsEnemy())
				{
					auto position = Engine::WorldToScreen(minion->Position());
					Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(position.x, position.y), 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "SkinHash %x", minion->GetSkinData()->GetSkinHash());
				}
			}

			//for (auto actor : Cache::AllMinionsObj)
			//{
			//	auto minion = (CObject*)actor;
			//	if (minion->IsEnemy())
			//	{
			//		auto position = Engine::WorldToScreen(minion->Position());
			//		Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(position.x, position.y), 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "SkinHash %x", minion->GetSkinData()->GetSkinHash());
			//	}
			//}
		}
		if (showheroes->Value)
		{
			for (auto actor : global::heros)
			{
				auto hero = (CObject*)actor.actor;
				if (hero)
				{
					auto position = Engine::WorldToScreen(hero->Position());
					Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(position.x, position.y), 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%s %x %x %.0f", hero->Name().c_str(), hero, hero->Index(), hero->BoundingRadius());
				}
			}
		}


		if (showparts->Value)
		{
			//for (auto actor : )
			//{
			//	auto hero = (CObject*)actor.actor;
			//	if (hero)
			//	{
			//		auto position = Engine::WorldToScreen(hero->Position());
			//		Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(position.x, position.y), 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%s %x %x", hero->Name().c_str(), hero, hero->Index());
			//	}
			//}
		}

	}
	void Init()
	{
		auto DebugTool = NewMenu::CreateMenu("DebugTool", "DebugTool");


		//auto ignitesettings = DebugTool->AddMenu("ignitesettings", "Ignite");
		showstat = DebugTool->AddCheckBox("showstat", "Show Stat", true);
		showase = DebugTool->AddCheckBox("showase", "Show Active Spell Entry", true);
		showbuffs = DebugTool->AddCheckBox("showbuff", "Show Buffs", true);
		showminions = DebugTool->AddCheckBox("showminion", "Show Minions", true);
		showheroes = DebugTool->AddCheckBox("showheroes", "Show Heroes", true);
		showparts = DebugTool->AddCheckBox("showparts", "Show Particles", true);
		showskilldamage = DebugTool->AddCheckBox("showskilldamage", "Show Skill Damage (irelia only)", true);
		showskinhash = DebugTool->AddCheckBox("showskinhash", "Show Skin Hash", true);

		//_config->AddBool("showbuffs", "Show Buffs", false);


		//_config->AddBool("showitems", "Show Items", false);
		//_config->AddBool("showSpells", "Show Spells", false);
		//_config->AddBool("showdmgminion", "Show Damage Minions", false);
		//_config->AddBool("showpath", "Show Path", false);
		//_config->AddBool("showpath2", "Show Path2", false);

		//_config->AddBool("processspell", "Process Spell", false);
		//_config->AddBool("processspellall", "Process Spell All", false);

		//_config->AddBool("processspellATTACK", "Process Spell Attack", false);
		//_config->AddBool("oncreatemissile", "OnCreate Spell", false);
		//_config->AddBool("buffgain", "buff gain", false);
		//_config->AddBool("showClickPos", "showClickPos", false);
		//_config->AddBool("showminions", "show minions", false);
		//_config->AddBool("showturrets", "show turrets", false);

		//_config->AddBool("showminionsown", "show minions owner", false);
		//_config->AddBool("showminionscolls", "show minions collision", false);
		//_config->AddBool("showpart", "show part", false);
		//_config->AddBool("testcrash", "test crash", false);
		//_config->AddBool("testdisablespell", "testdisablespell", false);
		//_config->AddBool("testparticlecreate", "testparticlecreate", false);

		//_config->AddBool("showheroes", "show heroes", false);
		//_config->AddBool("drawtarget", "drawtarget", false);
		//_config->AddBool("incomingdmg", "show incomingdmg", false);
		//auto cscript = _config->AddSubMenu(new Menu("ChampionScript", "ChampionScript"));
		//cscript->AddItem(new MenuItem("ScriptName", "Champion"))->SetValue(StringList(std::vector<std::string>{"Ezreal", "Jinx", "Irelia", "Caitlyn", "Blitzcrank", "Lulu", "Ashe", "Kaisa", "KogMaw", "Soraka", "Viego", "Aatrox", "Ahri", "Amumu", "Annie", "Brand", "Cassiopeia", "Corki", "Darius", "Diana", "Draven", "DrMundo", "Evelynn", "Fiora", "Graves", "Illaoi", "JarvanIV", "Jax", "Jayce", "Jhin", "Kalista", "Karma", "Karthus", "Kassadin", "Katarina", "Kayle", "Kennen", "Khazix", "Kindred", "Kled", "LeeSin", "Lissandra", "Lucian", "Lux", "MasterYi", "MissFortune", "Mordekaiser", "Morgana", "Nami", "Nasus", "Nautilus", "Neeko", "Nocturne", "Olaf", "Orianna", "Pantheon", "Pyke", "Quinn", "Renekton", "Rengar", "Riven", "Ryze", "Sivir", "Sylas", "Syndra", "Talon", "Thresh", "Tristana", "TwistedFate", "Twitch", "Urgot", "Varus", "Vayne", "Veigar", "Velkoz", "Viktor", "Volibear", "Xerath", "XinZhao", "Zilean", "Zyra", "Senna", "Samira", "Yasuo", "Xayah", "Akali", "Sett", "Aphelios", "Rell", "Zed", "Qiyana", "Elise", "Gwen"}));
		//cscript->AddBool("testload", "testload", false);
		//cscript->AddBool("unload", "unload", false);
		//_config->AddKeyBind("kataE2", "Charge cast1 ", Keys::C, KeyBindType::Press);

		//auto smitesettings = DebugTool->AddMenu("smitesettings", "Smite");
		//useSmite = smitesettings->AddCheckBox("useSmite", "Enable Smite", true);
		//useSmiteOnEnemy = smitesettings->AddCheckBox("useSmiteEnemy", "Use Smite to enemies/KS", true);
		//useSmiteEnemyAround = smitesettings->AddCheckBox("useSmiteEnemyAround", "Only use Smite when enemies is around", true);

		//auto healsettings = DebugTool->AddMenu("healsettings", "Heal");
		//useHeal = healsettings->AddCheckBox("autoheal", "Enable Heal", true);
		//HealthThreshold = healsettings->AddSlider("HealThreshold", "% Health Threshold to use heal", 30, 20, 100, 5);

		////auto barriersettings = DebugTool->AddMenu("barriersettings", "Barrier");
		////useBarrier = barriersettings->AddCheckBox("autobarrier", "Enable Barrier", true);
		////HealthThreshold = barriersettings->AddSlider("HealThreshold", "% Health to use barrier", 30, 20, 100, 5);

		//auto exhaustsettings = DebugTool->AddMenu("exhaustsettings", "Exhaust");
		//exhaustsettings->AddCheckBox("autoExhaust", "Enable Exhaust", true);

		//auto cleansesettings = DebugTool->AddMenu("cleansesettings", "Cleanse");
		//EnableCleanse = cleansesettings->AddCheckBox("autocleanse", "Enable Cleanse", true);
		//OnlyuseinCombo = cleansesettings->AddCheckBox("OnlyuseinCombo", "Only use in Combo", true);

		//auto cleansetypesettings = cleansesettings->AddMenu("cctypesettings", "CC Type");
		//Stun = cleansetypesettings->AddCheckBox("Stun", "Stun", true);
		//Snare = cleansetypesettings->AddCheckBox("Snare", "Snare", true);
		//Charm = cleansetypesettings->AddCheckBox("Charm", "Charm", true);
		//Fear = cleansetypesettings->AddCheckBox("Fear", "Fear", true);
		//Suppression = cleansetypesettings->AddCheckBox("Suppression", "Suppression", true);
		//Taunt = cleansetypesettings->AddCheckBox("Taunt", "Taunt", true);
		//Blind = cleansetypesettings->AddCheckBox("Blind", "Blind", true);


		//auto itemsettings = DebugTool->AddMenu("itemsettings", "Use Items");
		//useItem = itemsettings->AddCheckBox("autoitem", "Enable Use Item", true);

		//auto potionsettings = DebugTool->AddMenu("potionsettings", "Use Potions");
		//usePotion = potionsettings->AddCheckBox("autopotion", "Auto Potion", true);
		//PotionHealthThreshold = potionsettings->AddSlider("potionhealththreshold", "% Health to use Potion", 70, 20, 100, 5);
		//usePotionEnemyAround = potionsettings->AddCheckBox("usePotionEnemyAround", "Only use Potion when enemies is around", true);

	}

	void Tick()
	{
		//auto target = targetselector->GetTarget(600);

		//if (target && useIgnite->Value)
		//	autoignite(target);


		//if (useSmite->Value)
		//	autosmite();

		//if (EnableCleanse->Value)
		//	autocleanse();


		//if (useItem->Value)
		//{
		//	useOffensiveItems(target);
		//	useDefensiveItems();
		//}

		//if (usePotion->Value)
		//	autopotion();

		//if (useHeal->Value || useBarrier->Value)
		//	autoheal();
	}
};

Debugger* debugger;