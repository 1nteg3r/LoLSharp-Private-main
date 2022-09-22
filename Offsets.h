#pragma once
#ifndef _offsets_
#define _offsets_

struct Offsets_Garena
{

	const size_t oGameClient = 0x2491BDC;						//  | 0x2991BDC
	const size_t oGameState = 0x08;						//  | 
	const size_t oRiotGameWindow = 0x3108550;						//  | 0x3608550
	const size_t oPingInstance = 0x0;						//  | ERROR - BROKEN
	const size_t oD3DXDevice = 0x210;						//  | 
	const size_t oChampionManager = 0x18A0014; //8B 15 ? ? ? ? 0F 44 C1 //12.18 - same as herolist
	const size_t oTemplateManager_ParticleList = 0x0;						//  | ERROR - BROKEN
	const size_t oTemplateManager_MinionList = 0x24ED788; //A3 ?? ?? ?? ?? E8 ?? ?? ?? ?? 83 C4 04 85 C0 74 32 // 12.18
	const size_t oTemplateManager_MinionAndTurretList = 0x0;						//  | ERROR - BROKEN
	const size_t oTemplateManager_MissleMap = 0x313D2B4; //84 C9 8D 85 ? ? ? ? // 12.18
	const size_t oTemplateManager_AttackableUnitsList = 0x2491B6C;						//  | ERROR - BROKEN
	const size_t oTemplateManager_AllTheShitsList = 0x2491B6C;						//  | 0x2991B6C
	const size_t oTemplateManager_ShopList = 0x0;						//  | ERROR - BROKEN
	const size_t oTemplateManager_AIBaseList_2 = 0x0;						//  | ERROR - BROKEN
	const size_t oTemplateManager_HeroList = 0x18A0014; //8B 15 ? ? ? ? 0F 44 C1 //12.18
	const size_t oTemplateManager_UnknownList = 0x2491BA4;						//  | 0x2991BA4
	const size_t oTemplateManager_TurretList = 0x3134C94; //8B 35 ? ? ? ? 8B 76 18 //12.18
	const size_t oTemplateManager_ObjManager = 0x189FF7C; //0x24BFACC; // 12.18
	const size_t oTemplateManager_UnknownList_2 = 0x18423E4;						//  | 0x1D423E4
	const size_t oHudInstance = 0x1842D70;						//  | 0x1D42D70
	const size_t oNetClient = 0x0;						//  | ERROR - BROKEN
	const size_t oZoomClass = 0x31012BC;						//  | 12.18
	const size_t oLocalPlayer = 0x313D26C;						//  | 12.18
	const size_t oObjManager = 0x189FF7C;                   //0x24BFACC; // 12.18
	const size_t oGameTime = 0x3136040;                     //F3 0F 11 05 ? ? ? ? 8B 49 // 12.18
	const size_t oRenderer = 0x311147C;						//  | 0x361147C
	const size_t oW2sStatic = 0x316A730;					// 83 C4 04 5F 8B 8C 24 ? ? ? ? -> viewprojmatrices // 12.18
	const size_t oMenuGUI = 0x30E11F8;						//  | 0x35E11F8
	const size_t oMinimap = 0x313383C;                      //74 22 8B 0D ? ? ? ? 85 C9 74 18 80 79 38 00 //12.18
	const size_t oPreCharData = 0x2A9C;						//  | 
	const size_t oCharData = 0x1C;						//  | 
	const size_t oUnitInfo = 0x0;						//  | ERROR - BROKEN
	const size_t oObjBaseAttackSpeed = 0x1D0;						//  | 
	const size_t oObjBaseAttackSpeedRatio = 0x1D4;						//  | 
	const size_t oMiniMapSize = 0x120;						//  | ERROR - BROKEN
	const size_t oHPBar_1 = 0x3089;						//12.18 
	const size_t oHPBar_2 = oHPBar_1 + 0x7;						//12.18
	const size_t oHPBar_3 = oHPBar_2 + 0x4;						//12.18
	const size_t oHPBar_4 = oHPBar_3 - 0x8;						//12.18
	const size_t oHPBar_dwbar2_1 = 0x10;						//  | 
	const size_t oHPBar_dwbar2_2 = 0x04;						//  | 
	const size_t oHPBar_Off_1 = 0x1C;						//  | 
	const size_t oHPBar_Off_2 = 0x88;						//  | 
	const size_t oHPBar_Zoom_1 = 0x0C;						//  | 
	const size_t oHPBar_Zoom_2 = 0x264;						//  | 
	const size_t oGetAIManager_1 = 0x2B9C;						//  | 
	const size_t oGetAIManager_2 = 0x2B95;						//  | 
	const size_t oIsWallDWORD = 0x3109E98;						//  | 0x3609E98
	const size_t oActionState = 0x1034;						//  | ERROR - BROKEN
	const size_t oObjSpellBook = 0x2250;						//  | ERROR - BROKEN
	const size_t oObjBuffMgr = 0x2098;						//  | 
	const size_t oObjDirection = 0x1AF0;						//  | 
	const size_t oObjInventory = 0x32E0;						//  | 
	const size_t oObjChampionName2 = 0x2CB4;						//  | 
	const size_t oObjChampionName = 0x2AC4;						//  | 
	const size_t oObjSkinData = 0x2A9C;						//  | 
	const size_t oObjBoundingRadius = 0x458;						//  | 
	const size_t oAttackInfo = 0x30DA608;						//  | 0x35DA608
	const size_t oAttackData = 0x2A28;						//  | 
	const size_t oCharacterIntermediate = 0x113C;						//12.18
	const size_t oGetAttackDelayDWORD = 0x2491B3C;						//  | 0x2991B3C
	const size_t oGetAttackDelayBASE = 0x2D59;						//  | 
	const size_t oGetAttackDelayOffset = 0x1244;						//  | 
	const size_t oObjExp = 0x329C;						//  | 
	const size_t oObjCombatType = 0x1FC8;						//  | 

	//++ Find by Using Strings
	const size_t oObjLevel = 0x32AC;						//  | 
	const size_t oObjHPMaxPenalty = 0xDBC;						//  | 
	const size_t oObjAllShield = 0xDDC;						//  | 
	const size_t oObjPhysicalShield = 0xDEC;						//  | 
	const size_t oObjMagicalShield = 0xDFC;						//  | 
	const size_t oObjTargetable = 0xD04;						//  | 

	//++ Character Data
	const size_t oObjMaxMana = 0x2AC;						//  | 
	const size_t oObjMana = 0x29C;						//  | 
	const size_t oObjMaxHealth = 0xDAC;						//  | 
	const size_t oObjHealth = 0xD9C;						//  | 
	const size_t oObjBaseAtk = 0x126C;						//  | 
	const size_t oObjBonusAtk = 0x11E4;						//  | 
	const size_t oObjAP = 0x127C;						//  | 
	const size_t oObjBonusAP = 0x11F4;						//  | 
	const size_t oObjMR = 0x129C;						//  | 
	const size_t oObjBonusMR = 0x12A0;						//  | 
	const size_t oObjAtkRange = 0x12B4;						//  | 
	const size_t oObjPercentCooldownMod = oCharacterIntermediate + 0x10;
	const size_t oObjPercentCooldownCapMod = oCharacterIntermediate + 0x20;
	const size_t oObjPassiveCooldownEndTime = oCharacterIntermediate + 0x30;
	const size_t oObjPassiveCooldownTotalTime = oCharacterIntermediate + 0x40;
	const size_t oObjPercentDamageToBarracksMinionMod = oCharacterIntermediate + 0x50;
	const size_t oObjFlatDamageReductionFromBarracksMinionMod = oCharacterIntermediate + 0x60;
	const size_t oObjFlatAttackDamageMod = oCharacterIntermediate + 0x80;
	const size_t oObjPercentAttackDamageMod = oCharacterIntermediate + 0x90;
	const size_t oObjPercentBonusAttackDamageMod = oCharacterIntermediate + 0xB0;
	const size_t oObjFlatAbilityPowerMod = oCharacterIntermediate + 0xC0;
	const size_t oObjPercentAbilityPowerMod = oCharacterIntermediate + 0xD0;
	const size_t oObjFlatMagicReduction = oCharacterIntermediate + 0xE0;
	const size_t oObjPercentMagicReduction = oCharacterIntermediate + 0x100;
	const size_t oObjAttackSpeedModTotal = oCharacterIntermediate + 0x110;
	const size_t oObjAttackSpeedMod = oCharacterIntermediate + 0x120;
	const size_t oObjPercentMultiplicativeAttackSpeedMod = oCharacterIntermediate + 0x130;
	const size_t oObjBaseAttackDamage = oCharacterIntermediate + 0x140;
	const size_t oObjFlatBaseAttackDamageMod = oCharacterIntermediate + 0x160;
	const size_t oObjPercentBaseAttackDamageMod = oCharacterIntermediate + 0x170;
	const size_t oObjBaseAbilityPower = oCharacterIntermediate + 0x180;
	const size_t oObjCritDamageMultiplier = oCharacterIntermediate + 0x190;
	const size_t oObjDodge = oCharacterIntermediate + 0x1B0;
	const size_t oObjCrit = oCharacterIntermediate + 0x1C0;
	const size_t oObjArmor = oCharacterIntermediate + 0x1E0;
	const size_t oObjBonusArmor = oCharacterIntermediate + 0x1F0;
	const size_t oObjMagicResist = oCharacterIntermediate + 0x200;
	const size_t oObjBonusMagicResist = oCharacterIntermediate + 0x210;
	const size_t oObjHealthRegen = oCharacterIntermediate + 0x220;
	const size_t oObjMoveSpeed = oCharacterIntermediate + 0x240;
	const size_t oObjAttackRange = oCharacterIntermediate + 0x260;
	const size_t oObjPhysicalLethality = oCharacterIntermediate + 0x2A0;
	const size_t oObjPercentArmorPenetration = oCharacterIntermediate + 0x2B0;
	const size_t oObjPercentBonusArmorPenetration = oCharacterIntermediate + 0x2C0;
	const size_t oObjFlatMagicPenetration = oCharacterIntermediate + 0x2F0;
	const size_t oObjPercentMagicPenetration = oCharacterIntermediate + 0x310;
	const size_t oObjPercentBonusMagicPenetration = oCharacterIntermediate + 0x320;
	const size_t oObjLifeSteal = oCharacterIntermediate + 0x330;
	const size_t oObjSpellVamp = oCharacterIntermediate + 0x340;
	const size_t oObjTenacity = oCharacterIntermediate + 0x360;
	const size_t oObjResourceRegen = oCharacterIntermediate + 0x380;

	//
	//const size_t oGameClient = 0x24B9BEC;						//  | 0x2A89BEC
	//const size_t oGameState = 0x08;						//  | 
	//const size_t oRiotGameWindow = 0x312FE18;						//  | 0x36FFE18
	//const size_t oPingInstance = 0x0;						//  | ERROR - BROKEN
	//const size_t oD3DXDevice = 0x210;						//  | 
	//const size_t oChampionManager = 0x24B9BD8;						//  | 0x2A89BD8
	//const size_t oTemplateManager_ParticleList = 0x0;						//  | ERROR - BROKEN
	//const size_t oTemplateManager_MinionList = 0x24B9BD8;						//  | 0x2A89BD8
	//const size_t oTemplateManager_MinionAndTurretList = 0x0;						//  | ERROR - BROKEN
	//const size_t oTemplateManager_MissleMap = 0x3108E70;						//  | ERROR - BROKEN
	//const size_t oTemplateManager_AttackableUnitsList = 0x24B9B7C;						//  | 0x2A89B7C
	//const size_t oTemplateManager_AllTheShitsList = 0x24B9B7C;						//  | 0x2A89B7C
	//const size_t oTemplateManager_ShopList = 0x30FF4E0;						//  | 0x36CF4E0
	//const size_t oTemplateManager_AIBaseList_2 = 0x0;						//  | ERROR - BROKEN
	//const size_t oTemplateManager_HeroList = 0x186AB8C;						//  | 0x1E3AB8C
	//const size_t oTemplateManager_UnknownList = 0x24B9BB4;						//  | 0x2A89BB4
	//const size_t oTemplateManager_TurretList = 0x3100948;						//  | 0x36D0948
	//const size_t oTemplateManager_ObjManager = 0x24B9B48;						//  | 0x2A89B48
	//const size_t oTemplateManager_UnknownList_2 = 0x186A434;						//  | 0x1E3A434
	//const size_t oHudInstance = 0x186ABB0;						//  | 0x1E3ABB0
	//const size_t oNetClient = 0x3110D80;						//  | 0x36E0D80
	//const size_t oZoomClass = 0x31012BC;						//  | 0x36D12BC
	//const size_t oLocalPlayer = 0x31085EC;						//  | 0x36D85EC
	//const size_t oObjManager = 0x2491B40;						//  | 0x2A89B48
	//const size_t oGameTime = 0x3101D6C;						//  | 0x36D1D6C
	//const size_t oRenderer = 0x3138D54;						//  | 0x3708D54
	//const size_t oW2sStatic = 0x3135ED0;						//  | 0x3705ED0
	//const size_t oMenuGUI = 0x31085F0;						//  | 0x36D85F0
	//const size_t oMinimap = 0x3101DAC;						//  | 0x36D1DAC
	//const size_t oPreCharData = 0x2A94;						//  | 
	//const size_t oCharData = 0x1C;						//  | 
	//const size_t oUnitInfo = 0x2DF0;						//  | 
	//const size_t oObjBaseAttackSpeed = 0x1D0;						//  | 
	//const size_t oObjBaseAttackSpeedRatio = 0x1D4;						//  | 
	//const size_t oMiniMapSize = 0x120;						//  | ERROR - BROKEN
	//const size_t oHPBar_1 = 0x2DE9;						//  | 
	//const size_t oHPBar_2 = 0x2DF0;						//  | 
	//const size_t oHPBar_3 = 0x2DF4;						//  | 
	//const size_t oHPBar_4 = 0x2DEC;						//  | 
	//const size_t oHPBar_dwbar2_1 = 0x10;						//  | 
	//const size_t oHPBar_dwbar2_2 = 0x04;						//  | 
	//const size_t oHPBar_Off_1 = 0x1C;						//  | 
	//const size_t oHPBar_Off_2 = 0x88;						//  | 
	//const size_t oHPBar_Zoom_1 = 0x0C;						//  | 
	//const size_t oHPBar_Zoom_2 = 0x264;						//  | 
	//const size_t oGetAIManager_1 = 0x2B94;						//  | 
	//const size_t oGetAIManager_2 = 0x2B8D;						//  | 
	//const size_t oIsWallDWORD = 0x3131788;						//  | 0x3701788
	//const size_t oActionState = 0x1034;						//  | ERROR - BROKEN
	//const size_t oObjSpellBook = 0x2250;						//  | ERROR - BROKEN
	//const size_t oObjBuffMgr = 0x2098;						//  | 
	//const size_t oObjDirection = 0x1AF0;						//  | 
	//const size_t oObjInventory = 0x32D0;						//  | 
	//const size_t oObjChampionName2 = 0x2CA8;						//  | 
	//const size_t oObjChampionName = 0x2ABC;						//  | 
	//const size_t oObjSkinData = 0x2A94;						//  | 
	//const size_t oObjBoundingRadius = 0x458;						//  | 
	//const size_t oAttackInfo = 0x3102138;						//  | 0x36D2138
	//const size_t oAttackData = 0x2A20;						//  | 
	//const size_t oCharacterIntermediate = 0x15A0;						//  | 
	//const size_t oGetAttackDelayDWORD = 0x24B9B44;						//  | 0x2A89B44
	//const size_t oGetAttackDelayBASE = 0x2D4D;						//  | 
	//const size_t oGetAttackDelayOffset = 0x1244;						//  | 
	//const size_t oObjExp = 0x328C;						//  | 
	//const size_t oObjCombatType = 0x1FC8;						//  | 

	////++ Find by Using Strings
	//const size_t oObjLevel = 0x329C;						//  | 
	//const size_t oObjHPMaxPenalty = 0xDBC;						//  | 
	//const size_t oObjAllShield = 0xDDC;						//  | 
	//const size_t oObjPhysicalShield = 0xDEC;						//  | 
	//const size_t oObjMagicalShield = 0xDFC;						//  | 
	//const size_t oObjTargetable = 0xD04;						//  | 

	////++ Character Data
	//const size_t oObjMaxMana = 0x2AC;						//  | 
	//const size_t oObjMana = 0x29C;						//  | 
	//const size_t oObjMaxHealth = 0xDAC;						//  | 
	//const size_t oObjHealth = 0xD9C;						//  | 
	//const size_t oObjBaseAtk = 0x126C;						//  | 
	//const size_t oObjBonusAtk = 0x11E4;						//  | 
	//const size_t oObjAP = 0x127C;						//  | 
	//const size_t oObjBonusAP = 0x11F4;						//  | 
	//const size_t oObjMR = 0x129C;						//  | 
	//const size_t oObjBonusMR = 0x12A0;						//  | 
	//const size_t oObjAtkRange = 0x12B4;						//  | 
	//const size_t oObjPercentCooldownMod = oCharacterIntermediate + 0x10;
	//const size_t oObjPercentCooldownCapMod = oCharacterIntermediate + 0x20;
	//const size_t oObjPassiveCooldownEndTime = oCharacterIntermediate + 0x30;
	//const size_t oObjPassiveCooldownTotalTime = oCharacterIntermediate + 0x40;
	//const size_t oObjPercentDamageToBarracksMinionMod = oCharacterIntermediate + 0x50;
	//const size_t oObjFlatDamageReductionFromBarracksMinionMod = oCharacterIntermediate + 0x60;
	//const size_t oObjFlatAttackDamageMod = oCharacterIntermediate + 0x80;
	//const size_t oObjPercentAttackDamageMod = oCharacterIntermediate + 0x90;
	//const size_t oObjPercentBonusAttackDamageMod = oCharacterIntermediate + 0xB0;
	//const size_t oObjFlatAbilityPowerMod = oCharacterIntermediate + 0xC0;
	//const size_t oObjPercentAbilityPowerMod = oCharacterIntermediate + 0xD0;
	//const size_t oObjFlatMagicReduction = oCharacterIntermediate + 0xE0;
	//const size_t oObjPercentMagicReduction = oCharacterIntermediate + 0x100;
	//const size_t oObjAttackSpeedModTotal = oCharacterIntermediate + 0x110;
	//const size_t oObjAttackSpeedMod = oCharacterIntermediate + 0x120;
	//const size_t oObjPercentMultiplicativeAttackSpeedMod = oCharacterIntermediate + 0x130;
	//const size_t oObjBaseAttackDamage = oCharacterIntermediate + 0x140;
	//const size_t oObjFlatBaseAttackDamageMod = oCharacterIntermediate + 0x160;
	//const size_t oObjPercentBaseAttackDamageMod = oCharacterIntermediate + 0x170;
	//const size_t oObjBaseAbilityPower = oCharacterIntermediate + 0x180;
	//const size_t oObjCritDamageMultiplier = oCharacterIntermediate + 0x190;
	//const size_t oObjDodge = oCharacterIntermediate + 0x1B0;
	//const size_t oObjCrit = oCharacterIntermediate + 0x1C0;
	//const size_t oObjArmor = oCharacterIntermediate + 0x1E0;
	//const size_t oObjBonusArmor = oCharacterIntermediate + 0x1F0;
	//const size_t oObjMagicResist = oCharacterIntermediate + 0x200;
	//const size_t oObjBonusMagicResist = oCharacterIntermediate + 0x210;
	//const size_t oObjHealthRegen = oCharacterIntermediate + 0x220;
	//const size_t oObjMoveSpeed = oCharacterIntermediate + 0x240;
	//const size_t oObjAttackRange = oCharacterIntermediate + 0x260;
	//const size_t oObjPhysicalLethality = oCharacterIntermediate + 0x2A0;
	//const size_t oObjPercentArmorPenetration = oCharacterIntermediate + 0x2B0;
	//const size_t oObjPercentBonusArmorPenetration = oCharacterIntermediate + 0x2C0;
	//const size_t oObjFlatMagicPenetration = oCharacterIntermediate + 0x2F0;
	//const size_t oObjPercentMagicPenetration = oCharacterIntermediate + 0x310;
	//const size_t oObjPercentBonusMagicPenetration = oCharacterIntermediate + 0x320;
	//const size_t oObjLifeSteal = oCharacterIntermediate + 0x330;
	//const size_t oObjSpellVamp = oCharacterIntermediate + 0x340;
	//const size_t oObjTenacity = oCharacterIntermediate + 0x360;
	//const size_t oObjResourceRegen = oCharacterIntermediate + 0x380;


};


struct Offsets_Riot
{
	const size_t oGameClient = 0x2491BDC;						//  | 0x2991BDC
	const size_t oGameState = 0x08;						//  | 
	const size_t oRiotGameWindow = 0x3108550;						//  | 0x3608550
	const size_t oPingInstance = 0x0;						//  | ERROR - BROKEN
	const size_t oD3DXDevice = 0x210;						//  | 
	const size_t oChampionManager = 0x2491BC8;						//  | 0x2991BC8
	const size_t oTemplateManager_ParticleList = 0x0;						//  | ERROR - BROKEN
	const size_t oTemplateManager_MinionList = 0x2491BC8;						//  | 0x2991BC8
	const size_t oTemplateManager_MinionAndTurretList = 0x0;						//  | ERROR - BROKEN
	const size_t oTemplateManager_MissleMap = 0x30E1240;						//  | ERROR - BROKEN
	const size_t oTemplateManager_AttackableUnitsList = 0x2491B6C;						//  | ERROR - BROKEN
	const size_t oTemplateManager_AllTheShitsList = 0x2491B6C;						//  | 0x2991B6C
	const size_t oTemplateManager_ShopList = 0x0;						//  | ERROR - BROKEN
	const size_t oTemplateManager_AIBaseList_2 = 0x0;						//  | ERROR - BROKEN
	const size_t oTemplateManager_HeroList = 0x1842D4C;						//  | 0x1D42D4C
	const size_t oTemplateManager_UnknownList = 0x2491BA4;						//  | 0x2991BA4
	const size_t oTemplateManager_TurretList = 0x30D8E18;						//  | 0x35D8E18
	const size_t oTemplateManager_ObjManager = 0x2491B40;						//  | 0x2991B40
	const size_t oTemplateManager_UnknownList_2 = 0x18423E4;						//  | 0x1D423E4
	const size_t oHudInstance = 0x1842D70;						//  | 0x1D42D70
	const size_t oNetClient = 0x0;						//  | ERROR - BROKEN
	const size_t oZoomClass = 0x1842D70;						//  | ERROR - BROKEN
	const size_t oLocalPlayer = 0x30E11FC;						//  | 0x35E11FC
	const size_t oObjManager = 0x2491B40;						//  | 0x2991B40
	const size_t oGameTime = 0x30DA23C;						//  | 0x35DA23C
	const size_t oRenderer = 0x311147C;						//  | 0x361147C
	const size_t oW2sStatic = 0x310E5F0;						//  | 0x360E5F0
	const size_t oMenuGUI = 0x30E11F8;						//  | 0x35E11F8
	const size_t oMinimap = 0x30DA27C;						//  | 0x35DA27C
	const size_t oPreCharData = 0x2A9C;						//  | 
	const size_t oCharData = 0x1C;						//  | 
	const size_t oUnitInfo = 0x0;						//  | ERROR - BROKEN
	const size_t oObjBaseAttackSpeed = 0x1D0;						//  | 
	const size_t oObjBaseAttackSpeedRatio = 0x1D4;						//  | 
	const size_t oMiniMapSize = 0x120;						//  | ERROR - BROKEN
	const size_t oHPBar_1 = 0x2DF9;						//  | 
	const size_t oHPBar_2 = 0x2E00;						//  | 
	const size_t oHPBar_3 = 0x2E04;						//  | 
	const size_t oHPBar_4 = 0x2DFC;						//  | 
	const size_t oHPBar_dwbar2_1 = 0x10;						//  | 
	const size_t oHPBar_dwbar2_2 = 0x04;						//  | 
	const size_t oHPBar_Off_1 = 0x1C;						//  | 
	const size_t oHPBar_Off_2 = 0x88;						//  | 
	const size_t oHPBar_Zoom_1 = 0x0C;						//  | 
	const size_t oHPBar_Zoom_2 = 0x264;						//  | 
	const size_t oGetAIManager_1 = 0x2B9C;						//  | 
	const size_t oGetAIManager_2 = 0x2B95;						//  | 
	const size_t oIsWallDWORD = 0x3109E98;						//  | 0x3609E98
	const size_t oActionState = 0x1034;						//  | ERROR - BROKEN
	const size_t oObjSpellBook = 0x2250;						//  | ERROR - BROKEN
	const size_t oObjBuffMgr = 0x2098;						//  | 
	const size_t oObjDirection = 0x1AF0;						//  | 
	const size_t oObjInventory = 0x32E0;						//  | 
	const size_t oObjChampionName2 = 0x2CB4;						//  | 
	const size_t oObjChampionName = 0x2AC4;						//  | 
	const size_t oObjSkinData = 0x2A9C;						//  | 
	const size_t oObjBoundingRadius = 0x458;						//  | 
	const size_t oAttackInfo = 0x30DA608;						//  | 0x35DA608
	const size_t oAttackData = 0x2A28;						//  | 
	const size_t oCharacterIntermediate = 0x15A0;						//  | 
	const size_t oGetAttackDelayDWORD = 0x2491B3C;						//  | 0x2991B3C
	const size_t oGetAttackDelayBASE = 0x2D59;						//  | 
	const size_t oGetAttackDelayOffset = 0x1244;						//  | 
	const size_t oObjExp = 0x329C;						//  | 
	const size_t oObjCombatType = 0x1FC8;						//  | 

	//++ Find by Using Strings
	const size_t oObjLevel = 0x32AC;						//  | 
	const size_t oObjHPMaxPenalty = 0xDBC;						//  | 
	const size_t oObjAllShield = 0xDDC;						//  | 
	const size_t oObjPhysicalShield = 0xDEC;						//  | 
	const size_t oObjMagicalShield = 0xDFC;						//  | 
	const size_t oObjTargetable = 0xD04;						//  | 

	//++ Character Data
	const size_t oObjMaxMana = 0x2AC;						//  | 
	const size_t oObjMana = 0x29C;						//  | 
	const size_t oObjMaxHealth = 0xDAC;						//  | 
	const size_t oObjHealth = 0xD9C;						//  | 
	const size_t oObjBaseAtk = 0x126C;						//  | 
	const size_t oObjBonusAtk = 0x11E4;						//  | 
	const size_t oObjAP = 0x127C;						//  | 
	const size_t oObjBonusAP = 0x11F4;						//  | 
	const size_t oObjMR = 0x129C;						//  | 
	const size_t oObjBonusMR = 0x12A0;						//  | 
	const size_t oObjAtkRange = 0x12B4;						//  | 
	const size_t oObjPercentCooldownMod = oCharacterIntermediate + 0x10;
	const size_t oObjPercentCooldownCapMod = oCharacterIntermediate + 0x20;
	const size_t oObjPassiveCooldownEndTime = oCharacterIntermediate + 0x30;
	const size_t oObjPassiveCooldownTotalTime = oCharacterIntermediate + 0x40;
	const size_t oObjPercentDamageToBarracksMinionMod = oCharacterIntermediate + 0x50;
	const size_t oObjFlatDamageReductionFromBarracksMinionMod = oCharacterIntermediate + 0x60;
	const size_t oObjFlatAttackDamageMod = oCharacterIntermediate + 0x80;
	const size_t oObjPercentAttackDamageMod = oCharacterIntermediate + 0x90;
	const size_t oObjPercentBonusAttackDamageMod = oCharacterIntermediate + 0xB0;
	const size_t oObjFlatAbilityPowerMod = oCharacterIntermediate + 0xC0;
	const size_t oObjPercentAbilityPowerMod = oCharacterIntermediate + 0xD0;
	const size_t oObjFlatMagicReduction = oCharacterIntermediate + 0xE0;
	const size_t oObjPercentMagicReduction = oCharacterIntermediate + 0x100;
	const size_t oObjAttackSpeedModTotal = oCharacterIntermediate + 0x110;
	const size_t oObjAttackSpeedMod = oCharacterIntermediate + 0x120;
	const size_t oObjPercentMultiplicativeAttackSpeedMod = oCharacterIntermediate + 0x130;
	const size_t oObjBaseAttackDamage = oCharacterIntermediate + 0x140;
	const size_t oObjFlatBaseAttackDamageMod = oCharacterIntermediate + 0x160;
	const size_t oObjPercentBaseAttackDamageMod = oCharacterIntermediate + 0x170;
	const size_t oObjBaseAbilityPower = oCharacterIntermediate + 0x180;
	const size_t oObjCritDamageMultiplier = oCharacterIntermediate + 0x190;
	const size_t oObjDodge = oCharacterIntermediate + 0x1B0;
	const size_t oObjCrit = oCharacterIntermediate + 0x1C0;
	const size_t oObjArmor = oCharacterIntermediate + 0x1E0;
	const size_t oObjBonusArmor = oCharacterIntermediate + 0x1F0;
	const size_t oObjMagicResist = oCharacterIntermediate + 0x200;
	const size_t oObjBonusMagicResist = oCharacterIntermediate + 0x210;
	const size_t oObjHealthRegen = oCharacterIntermediate + 0x220;
	const size_t oObjMoveSpeed = oCharacterIntermediate + 0x240;
	const size_t oObjAttackRange = oCharacterIntermediate + 0x260;
	const size_t oObjPhysicalLethality = oCharacterIntermediate + 0x2A0;
	const size_t oObjPercentArmorPenetration = oCharacterIntermediate + 0x2B0;
	const size_t oObjPercentBonusArmorPenetration = oCharacterIntermediate + 0x2C0;
	const size_t oObjFlatMagicPenetration = oCharacterIntermediate + 0x2F0;
	const size_t oObjPercentMagicPenetration = oCharacterIntermediate + 0x310;
	const size_t oObjPercentBonusMagicPenetration = oCharacterIntermediate + 0x320;
	const size_t oObjLifeSteal = oCharacterIntermediate + 0x330;
	const size_t oObjSpellVamp = oCharacterIntermediate + 0x340;
	const size_t oObjTenacity = oCharacterIntermediate + 0x360;
	const size_t oObjResourceRegen = oCharacterIntermediate + 0x380;
};


//++ AntiCheat

////////////////////////////////////////////////////////////
const size_t oObjIndex = 0x8;							// 	|  HEAP 2A010001
const size_t oObjTeam = 0x34;							// 	| 100 
const size_t oObjName = 0x54;							// 	| summoner name : eg nixeus2 || = 0x60
const size_t oObjNetworkID = 0xB4;						// 	| = 0x400001e for local -> <HEAP>4000001E
const size_t oObjPos = 0x1DC;							// 	| XYZ floats
const size_t oObjIsDead = 0x21C;						// 10.4.308.9400 |  Last number will increase by one DEAD = odd number
const size_t oObjVisibility = 0x274;					// 	| base+objmanager -> obj -> offset | 0x101 = VISSIBLE 0x100 = INVISIBLE
const size_t oStatusFlag = 0x3D4;						//  |~~ E8 ? ? ? ? 8B 4C 24 1C 8B F0 6A 00 //yi W = 512
const size_t oObjRecallState = 0xD78;                    //     | 0 = no , 6 = yes 
const size_t oObjRecallType = oObjRecallState + 0x18;    //     | 8 = normal , 11 = baron
const size_t oOldCastSpell = 0x50B350;  //not use
const size_t oDisableMove = 0x2D38;

const size_t oIsUntargetableToAllies = 0xD00 - 0x10;						// 11.4.360.513 | doesn't use
const size_t oIsUntargetableToEnemies = oIsUntargetableToAllies - 0x10;						// 11.4.360.513 | doesn't use


////////////////////////////////////////////////////////////////


//DO NOT ALTAR
// Renderer not checked
//#define MAX(x, y) (((x) > (y)) ? (x) : (y))
//#define MIN(x, y) (((x) < (y)) ? (x) : (y))
#define oviewMatrix 0x68
#define oprojMatrix 0xA8
#define oscreenWeight 0x210
#define oscreenHeight 0x214
#define oChatOpen 0x8

const size_t oItemSlotInst = 0x18;
const size_t oItemInfo = 0xC;
const size_t oItemData = 0x20;
const size_t oItemSlotID = 0x68;

//Missile Data
const size_t MissileSpellInfo = 0x260; //		11.6 ==> 11.7
const size_t MissileSrcIdx = 0x2C4; //			11.6 ==> 11.7
const size_t MissileDestIdx = 0x318; //			11.6 ==> 11.7
const size_t MissileStartPos = 0x2dc; //		11.6 ==> 11.7
const size_t MissileEndPos = 0x2e8; //			11.6 ==> 11.7

//SpellData
const size_t oManaCost = 0x52C;//0xD997830A
const size_t oSpellRangeArray = 0x3D4; //0x1B9CBD9B
const size_t oSpellRangeArrayOverride = 0x3F0;  //0xD4C233B3
const size_t oMissileSpeed = 0x460; // \"MissileSpeed\" 0x165E061E
const size_t oMissileWidth = 0x494; // \"mLineWidth\" 0x1A24E25E
const size_t oCastRadius = 0x40C; // \"CastRadius\" 0xB7250B1C
const size_t oCastRadiusSecondary = 0x428; // \"CastRadiusSecondary\" 0x8F6F40E6
const size_t oCastConeAngle = 0x444; // "CastConeAngle" 0x7738AA28
const size_t oCastConeDistance = 0x448; // "CastConeDistance" 0x5C46E292
const size_t oCantCancelWhileWindingUp = 0x397; // \"mCantCancelWhileWindingUp\" 0xE321919C
const size_t oCantCancelWhileChanneling = 0x399; // \"mCantCancelWhileChanneling\" 0x551B248C
const size_t oChannelIsInterruptedByDisables = 0x39B; // \"mChannelIsInterruptedByDisables\"    
const size_t oChannelIsInterruptedByAttacking = 0x39C; // \"mChannelIsInterruptedByAttacking\" 0xA54FF456
const size_t oCanMoveWhileChanneling = 0x3AC; // \"mCanMoveWhileChanneling\" 0x3F8BC625

const size_t oSpellSlotArrayStart = 0x488;				// 8D AB ? ? ? ? C7 03 ? ? ? ? 33 
const size_t oSpellInfo = 0x120;					//  83 BF ? ? ? ? ? 0F 84 ? ? ? ? 8B CF 
const size_t oSpellData = 0x40;					// FF 72 ? 6A FF 
const size_t oTargetingClient = 0x130;

//Buff
const size_t O_BUFFMGR_BUFFTYPE = 0x4;
const size_t O_BUFFMGR_BUFFNAME = 0x8;					// 10.7	|
const size_t O_BUFFMGR_STARTTIME = 0xC;					// 10.7	|
const size_t O_BUFFMGR_ENDTIME = 0x10;					// 10.7	|
const size_t O_BUFFMGR_flBUFFCOUNT = 0x130;				// 10.7 | 
const size_t O_BUFFMGR_iBUFFCOUNT = 0x74;				// 10.7	| 
const size_t O_BUFFMGR_IsPermanent = 0x70;
const size_t O_BUFFMGR_BUFFINFO = 0x20;

//AI MGR
const size_t O_AIMGR_TARGETPOS = 0x10;					// 10.10	| where the target is going?
const size_t O_AIMGR_ISMOVING = 0x1C0;					// 11.14	| ??
const size_t O_AIMGR_ISDASHING = 0x214;					// 10.10	|
const size_t O_AIMGR_DASHSPEED = 0x1F8;					// 11.14	|
const size_t O_AIMGR_NAVBEGIN = 0x1E4;					// 11.14 | pathlist
const size_t O_AIMGR_NAVEND = 0x1E8;					// 11.14
const size_t O_AIMGR_PASSED_WAYPOINTS = 0x1C4;			// 11.14	
const size_t O_AIMGR_CURRENTPOS = 0x2EC;				// 11.14
const size_t O_AIMGR_VELOCITY = 0x2F0;					// 11.14

enum ENavMash
{
	NMMaxX = 112,
	NMMinX = 100,

	NMMaxZ = 120,
	NMMinZ = 108,

	NMOffset1 = 156,
	NMOffset2 = 152,
	NMOffset3 = 144,
	NMOffset4 = 148,
	NMOffset5 = 140,

	NMOffset6 = 1452,
	NMOffset7 = 1440,
	NMOffset8 = 1444,
	NMOffset9 = 128,

	NMBufferSize = NMOffset6 + 0x08,
};

#endif