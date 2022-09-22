local common = module.load(header.id, "Prediction/common"); --ActiveAttacks terminar Attacks Animation
local orb = module.internal("orb")
local menu = menu("VPrediction", "Intnner Prediction");
menu:header("xs", "Core");
menu:dropdown('Combo', 'Select Priority:', 1, {'Fast', 'Medium', 'Slow'});
menu:header("coli", "Collision Settings");
menu:slider("buffer", "Collision Buffer", 20, 5, 100, 5);
menu:boolean('_Minions', 'Minions', true);
menu:boolean('_Mobs', 'Jungle', true);
menu:boolean('_Others', 'Others', true);
menu:boolean('EnemyCollision', 'Enemy Collision', true);
menu:boolean('Unit', 'Check Collision at Unit', true);
menu:boolean('Cast', 'Check Collision at Cast', true);
menu:boolean('Predicted', 'Check Collision at Predicted', false);

local function class()
	local cls = {}
	cls.__index = cls
	return setmetatable(cls, { __call = function (c, ...)
		local instance = setmetatable({}, cls)
		if cls.__init then
			cls.__init(instance, ...)
		end
		return instance
	end})
end


local function _has_value(tab, val)
    for index, value in ipairs(tab) do
if value == val then
    return true
end
    end
    return false
end

local minionTar = {}
local function GetAggro(unit)
    if unit.activeSpell and unit.activeSpell.target then
        return unit.activeSpell.target
    else
        return minionTar[unit.networkID] and minionTar[unit.networkID] or nil
    end
end

local GetPathIndex = function(unit)
    if not unit then 
        return 
    end

	local origin 	= vec3{ x= unit.x, y = unit.y, z = unit.z}
	local curIndex 	= 0
	local pathCount = unit.path.count - 1

	for k = pathCount, 1, -1 do
            if unit.path.point[k] and unit.path.point[k - 1] and 
            (origin.x - (unit.path.point[k].x)) ^ 2 + (origin.z - (unit.path.point[k].z) ^ 2) < ((unit.path.point[k - 1]).x - (unit.path.point[k]).x) ^ 2 + ((unit.path.point[k -1]).z - (unit.path.point[k]).z) ^ 2 then
                curIndex = pathCount - k
                break
            end
        end

    local result = math.abs(curIndex - pathCount)

    return result > 2 and result + 1 or 2
end

local _FAST, _MEDIUM, _SLOW = 1, 2, 3
local PA = {}
local function OnPreTick()
    for i=0, objManager.enemies_n-1 do
        local obj = objManager.enemies[i]
        if obj and obj ~= nil then  
            PA[obj.networkID] = {}
        end
    end
    PA[player.networkID] = {}
end
cb.add(cb.pre_tick, OnPreTick)

local hitboxes = {['Braum'] = 80, ['RecItemsCLASSIC'] = 65, ['TeemoMushroom'] = 50.0, ['TestCubeRender'] = 65, ['Xerath'] = 65, ['Kassadin'] = 65, ['Rengar'] = 65, ['Thresh'] = 55.0, ['RecItemsTUTORIAL'] = 65, ['Ziggs'] = 55.0, ['ZyraPassive'] = 20.0, ['ZyraThornPlant'] = 20.0, ['KogMaw'] = 65, ['HeimerTBlue'] = 35.0, ['EliseSpider'] = 65, ['Skarner'] = 80.0, ['ChaosNexus'] = 65, ['Katarina'] = 65, ['Riven'] = 65, ['SightWard'] = 1, ['HeimerTYellow'] = 35.0, ['Ashe'] = 65, ['VisionWard'] = 1, ['TT_NGolem2'] = 80.0, ['ThreshLantern'] = 65, ['RecItemsCLASSICMap10'] = 65, ['RecItemsODIN'] = 65, ['TT_Spiderboss'] = 200.0, ['RecItemsARAM'] = 65, ['OrderNexus'] = 65, ['Soraka'] = 65, ['Jinx'] = 65, ['TestCubeRenderwCollision'] = 65, ['Red_Minion_Wizard'] = 48.0, ['JarvanIV'] = 65, ['Blue_Minion_Wizard'] = 48.0, ['TT_ChaosTurret2'] = 88.4, ['TT_ChaosTurret3'] = 88.4, ['TT_ChaosTurret1'] = 88.4, ['ChaosTurretGiant'] = 88.4, ['Dragon'] = 100.0, ['LuluSnowman'] = 50.0, ['Worm'] = 100.0, ['ChaosTurretWorm'] = 88.4, ['TT_ChaosInhibitor'] = 65, ['ChaosTurretNormal'] = 88.4, ['AncientGolem'] = 100.0, ['ZyraGraspingPlant'] = 20.0, ['HA_AP_OrderTurret3'] = 88.4, ['HA_AP_OrderTurret2'] = 88.4, ['Tryndamere'] = 65, ['OrderTurretNormal2'] = 88.4, ['Singed'] = 65, ['OrderInhibitor'] = 65, ['Diana'] = 65, ['HA_FB_HealthRelic'] = 65, ['TT_OrderInhibitor'] = 65, ['GreatWraith'] = 80.0, ['Yasuo'] = 65, ['OrderTurretDragon'] = 88.4, ['OrderTurretNormal'] = 88.4, ['LizardElder'] = 65.0, ['HA_AP_ChaosTurret'] = 88.4, ['Ahri'] = 65, ['Lulu'] = 65, ['ChaosInhibitor'] = 65, ['HA_AP_ChaosTurret3'] = 88.4, ['HA_AP_ChaosTurret2'] = 88.4, ['ChaosTurretWorm2'] = 88.4, ['TT_OrderTurret1'] = 88.4, ['TT_OrderTurret2'] = 88.4, ['TT_OrderTurret3'] = 88.4, ['LuluFaerie'] = 65, ['HA_AP_OrderTurret'] = 88.4, ['OrderTurretAngel'] = 88.4, ['YellowTrinketUpgrade'] = 1, ['MasterYi'] = 65, ['Lissandra'] = 65, ['ARAMOrderTurretNexus'] = 88.4, ['Draven'] = 65, ['FiddleSticks'] = 65, ['SmallGolem'] = 80.0, ['ARAMOrderTurretFront'] = 88.4, ['ChaosTurretTutorial'] = 88.4, ['NasusUlt'] = 80.0, ['Maokai'] = 80.0, ['Wraith'] = 50.0, ['Wolf'] = 50.0, ['Sivir'] = 65, ['Corki'] = 65, ['Janna'] = 65, ['Nasus'] = 80.0, ['Golem'] = 80.0, ['ARAMChaosTurretFront'] = 88.4, ['ARAMOrderTurretInhib'] = 88.4, ['LeeSin'] = 65, ['HA_AP_ChaosTurretTutorial'] = 88.4, ['GiantWolf'] = 65.0, ['HA_AP_OrderTurretTutorial'] = 88.4, ['YoungLizard'] = 50.0, ['Jax'] = 65, ['LesserWraith'] = 50.0, ['Blitzcrank'] = 80.0, ['brush_D_SR'] = 65, ['brush_E_SR'] = 65, ['brush_F_SR'] = 65, ['brush_C_SR'] = 65, ['brush_A_SR'] = 65, ['brush_B_SR'] = 65, ['ARAMChaosTurretInhib'] = 88.4, ['Shen'] = 65, ['Nocturne'] = 65, ['Sona'] = 65, ['ARAMChaosTurretNexus'] = 88.4, ['YellowTrinket'] = 1, ['OrderTurretTutorial'] = 88.4, ['Caitlyn'] = 65, ['Trundle'] = 65, ['Malphite'] = 80.0, ['Mordekaiser'] = 80.0, ['ZyraSeed'] = 65, ['Vi'] = 50, ['Tutorial_Red_Minion_Wizard'] = 48.0, ['Renekton'] = 80.0, ['Anivia'] = 65, ['Fizz'] = 65, ['Heimerdinger'] = 55.0, ['Evelynn'] = 65, ['Rumble'] = 80.0, ['Leblanc'] = 65, ['Darius'] = 80.0, ['OlafAxe'] = 50.0, ['Viktor'] = 65, ['XinZhao'] = 65, ['Orianna'] = 65, ['Vladimir'] = 65, ['Nidalee'] = 65, ['Tutorial_Red_Minion_Basic'] = 48.0, ['ZedShadow'] = 65, ['Syndra'] = 65, ['Zac'] = 80.0, ['Olaf'] = 65, ['Veigar'] = 55.0, ['Twitch'] = 65, ['Alistar'] = 80.0, ['Akali'] = 65, ['Urgot'] = 80.0, ['Leona'] = 65, ['Talon'] = 65, ['Karma'] = 65, ['Jayce'] = 65, ['Galio'] = 80.0, ['Shaco'] = 65, ['Taric'] = 65, ['TwistedFate'] = 65, ['Varus'] = 65, ['Garen'] = 65, ['Swain'] = 65, ['Vayne'] = 65, ['Fiora'] = 65, ['Quinn'] = 65, ['Kayle'] = 65, ['Blue_Minion_Basic'] = 48.0, ['Brand'] = 65, ['Teemo'] = 55.0, ['Amumu'] = 55.0, ['Annie'] = 55.0, ['Odin_Blue_Minion_caster'] = 48.0, ['Elise'] = 65, ['Nami'] = 65, ['Poppy'] = 55.0, ['AniviaEgg'] = 65, ['Tristana'] = 55.0, ['Graves'] = 65, ['Morgana'] = 65, ['Gragas'] = 80.0, ['MissFortune'] = 65, ['Warwick'] = 65, ['Cassiopeia'] = 65, ['Tutorial_Blue_Minion_Wizard'] = 48.0, ['DrMundo'] = 80.0, ['Volibear'] = 80.0, ['Irelia'] = 65, ['Odin_Red_Minion_Caster'] = 48.0, ['Lucian'] = 65, ['Yorick'] = 80.0, ['RammusPB'] = 65, ['Red_Minion_Basic'] = 48.0, ['Udyr'] = 65, ['MonkeyKing'] = 65, ['Tutorial_Blue_Minion_Basic'] = 48.0, ['Kennen'] = 55.0, ['Nunu'] = 65, ['Ryze'] = 65, ['Zed'] = 65, ['Nautilus'] = 80.0, ['Gangplank'] = 65, ['shopevo'] = 65, ['Lux'] = 65, ['Sejuani'] = 80.0, ['Ezreal'] = 65, ['OdinNeutralGuardian'] = 65, ['Khazix'] = 65, ['Sion'] = 80.0, ['Aatrox'] = 65, ['Hecarim'] = 80.0, ['Pantheon'] = 65, ['Shyvana'] = 50.0, ['Zyra'] = 65, ['Karthus'] = 65, ['Rammus'] = 65, ['Zilean'] = 65, ['Chogath'] = 80.0, ['Malzahar'] = 65, ['YorickRavenousGhoul'] = 1.0, ['YorickSpectralGhoul'] = 1.0, ['JinxMine'] = 65, ['YorickDecayedGhoul'] = 1.0, ['XerathArcaneBarrageLauncher'] = 65, ['Odin_SOG_Order_Crystal'] = 65, ['TestCube'] = 65, ['ShyvanaDragon'] = 80.0, ['FizzBait'] = 65, ['ShopKeeper'] = 65, ['Blue_Minion_MechMelee'] = 65.0, ['OdinQuestBuff'] = 65, ['TT_Buffplat_L'] = 65, ['TT_Buffplat_R'] = 65, ['KogMawDead'] = 65, ['TempMovableChar'] = 48.0, ['Lizard'] = 50.0, ['GolemOdin'] = 80.0, ['OdinOpeningBarrier'] = 65, ['TT_ChaosTurret4'] = 88.4, ['TT_Flytrap_A'] = 65, ['TT_Chains_Order_Periph'] = 65, ['TT_NWolf'] = 65.0, ['ShopMale'] = 65, ['OdinShieldRelic'] = 65, ['TT_Chains_Xaos_Base'] = 65, ['LuluSquill'] = 50.0, ['TT_Shopkeeper'] = 65, ['redDragon'] = 100.0, ['MonkeyKingClone'] = 65, ['Odin_skeleton'] = 65, ['OdinChaosTurretShrine'] = 88.4, ['Cassiopeia_Death'] = 65, ['OdinCenterRelic'] = 48.0, ['Ezreal_cyber_1'] = 65, ['Ezreal_cyber_3'] = 65, ['Ezreal_cyber_2'] = 65, ['OdinRedSuperminion'] = 55.0, ['TT_Speedshrine_Gears'] = 65, ['JarvanIVWall'] = 65, ['DestroyedNexus'] = 65, ['ARAMOrderNexus'] = 65, ['Red_Minion_MechCannon'] = 65.0, ['OdinBlueSuperminion'] = 55.0, ['SyndraOrbs'] = 65, ['LuluKitty'] = 50.0, ['SwainNoBird'] = 65, ['LuluLadybug'] = 50.0, ['CaitlynTrap'] = 65, ['TT_Shroom_A'] = 65, ['ARAMChaosTurretShrine'] = 88.4, ['Odin_Windmill_Propellers'] = 65, ['DestroyedInhibitor'] = 65, ['TT_NWolf2'] = 50.0, ['OdinMinionGraveyardPortal'] = 1.0, ['SwainBeam'] = 65, ['Summoner_Rider_Order'] = 65.0, ['TT_Relic'] = 65, ['odin_lifts_crystal'] = 65, ['OdinOrderTurretShrine'] = 88.4, ['SpellBook1'] = 65, ['Blue_Minion_MechCannon'] = 65.0, ['TT_ChaosInhibitor_D'] = 65, ['Odin_SoG_Chaos'] = 65, ['TrundleWall'] = 65, ['HA_AP_HealthRelic'] = 65, ['OrderTurretShrine'] = 88.4, ['OriannaBall'] = 48.0, ['ChaosTurretShrine'] = 88.4, ['LuluCupcake'] = 50.0, ['HA_AP_ChaosTurretShrine'] = 88.4, ['TT_Chains_Bot_Lane'] = 65, ['TT_NWraith2'] = 50.0, ['TT_Tree_A'] = 65, ['SummonerBeacon'] = 65, ['Odin_Drill'] = 65, ['TT_NGolem'] = 80.0, ['Shop'] = 65, ['AramSpeedShrine'] = 65, ['DestroyedTower'] = 65, ['OriannaNoBall'] = 65, ['Odin_Minecart'] = 65, ['Summoner_Rider_Chaos'] = 65.0, ['OdinSpeedShrine'] = 65, ['TT_Brazier'] = 65, ['TT_SpeedShrine'] = 65, ['odin_lifts_buckets'] = 65, ['OdinRockSaw'] = 65, ['OdinMinionSpawnPortal'] = 1.0, ['SyndraSphere'] = 48.0, ['TT_Nexus_Gears'] = 65, ['Red_Minion_MechMelee'] = 65.0, ['SwainRaven'] = 65, ['crystal_platform'] = 65, ['MaokaiSproutling'] = 48.0, ['Urf'] = 65, ['TestCubeRender10Vision'] = 65, ['MalzaharVoidling'] = 10.0, ['GhostWard'] = 1, ['MonkeyKingFlying'] = 65, ['LuluPig'] = 50.0, ['AniviaIceBlock'] = 65, ['TT_OrderInhibitor_D'] = 65, ['yonkey'] = 65, ['Odin_SoG_Order'] = 65, ['RammusDBC'] = 65, ['FizzShark'] = 65, ['LuluDragon'] = 50.0, ['OdinTestCubeRender'] = 65, ['OdinCrane'] = 65, ['TT_Tree1'] = 65, ['ARAMOrderTurretShrine'] = 88.4, ['TT_Chains_Order_Base'] = 65, ['Odin_Windmill_Gears'] = 65, ['ARAMChaosNexus'] = 65, ['TT_NWraith'] = 50.0, ['TT_OrderTurret4'] = 88.4, ['Odin_SOG_Chaos_Crystal'] = 65, ['TT_SpiderLayer_Web'] = 65, ['OdinQuestIndicator'] = 1.0, ['JarvanIVStandard'] = 65, ['TT_DummyPusher'] = 65, ['OdinClaw'] = 65, ['EliseSpiderling'] = 1.0, ['QuinnValor'] = 65, ['UdyrTigerUlt'] = 65, ['UdyrTurtleUlt'] = 65, ['UdyrUlt'] = 65, ['UdyrPhoenixUlt'] = 65, ['ShacoBox'] = 10, ['HA_AP_Poro'] = 65, ['AnnieTibbers'] = 80.0, ['UdyrPhoenix'] = 65, ['UdyrTurtle'] = 65, ['UdyrTiger'] = 65, ['HA_AP_OrderShrineTurret'] = 88.4, ['HA_AP_OrderTurretRubble'] = 65, ['HA_AP_Chains_Long'] = 65, ['HA_AP_OrderCloth'] = 65, ['HA_AP_PeriphBridge'] = 65, ['HA_AP_BridgeLaneStatue'] = 65, ['HA_AP_ChaosTurretRubble'] = 88.4, ['HA_AP_BannerMidBridge'] = 65, ['HA_AP_PoroSpawner'] = 50.0, ['HA_AP_Cutaway'] = 65, ['HA_AP_Chains'] = 65, ['HA_AP_ShpSouth'] = 65, ['HA_AP_HeroTower'] = 65, ['HA_AP_ShpNorth'] = 65, ['ChaosInhibitor_D'] = 65, ['ZacRebirthBloblet'] = 65, ['OrderInhibitor_D'] = 65, ['Nidalee_Spear'] = 65, ['Nidalee_Cougar'] = 65, ['TT_Buffplat_Chain'] = 65, ['WriggleLantern'] = 1, ['TwistedLizardElder'] = 65.0, ['RabidWolf'] = 65.0, ['HeimerTGreen'] = 50.0, ['HeimerTRed'] = 50.0, ['ViktorFF'] = 65, ['TwistedGolem'] = 80.0, ['TwistedSmallWolf'] = 50.0, ['TwistedGiantWolf'] = 65.0, ['TwistedTinyWraith'] = 50.0, ['TwistedBlueWraith'] = 50.0, ['TwistedYoungLizard'] = 50.0, ['Red_Minion_Melee'] = 48.0, ['Blue_Minion_Melee'] = 48.0, ['Blue_Minion_Healer'] = 48.0, ['Ghast'] = 60.0, ['blueDragon'] = 100.0, ['Red_Minion_MechRange'] = 65.0, ['Test_CubeSphere'] = 65,}
local projectilespeeds = {["Velkoz"]= 2000,["TeemoMushroom"] = math.huge,["TestCubeRender"] = math.huge ,["Xerath"] = 2000.0000 ,["Kassadin"] = math.huge ,["Rengar"] = math.huge ,["Thresh"] = 1000.0000 ,["Ziggs"] = 1500.0000 ,["ZyraPassive"] = 1500.0000 ,["ZyraThornPlant"] = 1500.0000 ,["KogMaw"] = 1800.0000 ,["HeimerTBlue"] = 1599.3999 ,["EliseSpider"] = 500.0000 ,["Skarner"] = 500.0000 ,["ChaosNexus"] = 500.0000 ,["Katarina"] = 467.0000 ,["Riven"] = 347.79999 ,["SightWard"] = 347.79999 ,["HeimerTYellow"] = 1599.3999 ,["Ashe"] = 2000.0000 ,["VisionWard"] = 2000.0000 ,["TT_NGolem2"] = math.huge ,["ThreshLantern"] = math.huge ,["TT_Spiderboss"] = math.huge ,["OrderNexus"] = math.huge ,["Soraka"] = 1000.0000 ,["Jinx"] = 2750.0000 ,["TestCubeRenderwCollision"] = 2750.0000 ,["Red_Minion_Wizard"] = 650.0000 ,["JarvanIV"] = 20.0000 ,["Blue_Minion_Wizard"] = 650.0000 ,["TT_ChaosTurret2"] = 1200.0000 ,["TT_ChaosTurret3"] = 1200.0000 ,["TT_ChaosTurret1"] = 1200.0000 ,["ChaosTurretGiant"] = 1200.0000 ,["Dragon"] = 1200.0000 ,["LuluSnowman"] = 1200.0000 ,["Worm"] = 1200.0000 ,["ChaosTurretWorm"] = 1200.0000 ,["TT_ChaosInhibitor"] = 1200.0000 ,["ChaosTurretNormal"] = 1200.0000 ,["AncientGolem"] = 500.0000 ,["ZyraGraspingPlant"] = 500.0000 ,["HA_AP_OrderTurret3"] = 1200.0000 ,["HA_AP_OrderTurret2"] = 1200.0000 ,["Tryndamere"] = 347.79999 ,["OrderTurretNormal2"] = 1200.0000 ,["Singed"] = 700.0000 ,["OrderInhibitor"] = 700.0000 ,["Diana"] = 347.79999 ,["HA_FB_HealthRelic"] = 347.79999 ,["TT_OrderInhibitor"] = 347.79999 ,["GreatWraith"] = 750.0000 ,["Yasuo"] = 347.79999 ,["OrderTurretDragon"] = 1200.0000 ,["OrderTurretNormal"] = 1200.0000 ,["LizardElder"] = 500.0000 ,["HA_AP_ChaosTurret"] = 1200.0000 ,["Ahri"] = 1750.0000 ,["Lulu"] = 1450.0000 ,["ChaosInhibitor"] = 1450.0000 ,["HA_AP_ChaosTurret3"] = 1200.0000 ,["HA_AP_ChaosTurret2"] = 1200.0000 ,["ChaosTurretWorm2"] = 1200.0000 ,["TT_OrderTurret1"] = 1200.0000 ,["TT_OrderTurret2"] = 1200.0000 ,["TT_OrderTurret3"] = 1200.0000 ,["LuluFaerie"] = 1200.0000 ,["HA_AP_OrderTurret"] = 1200.0000 ,["OrderTurretAngel"] = 1200.0000 ,["YellowTrinketUpgrade"] = 1200.0000 ,["MasterYi"] = math.huge ,["Lissandra"] = 2000.0000 ,["ARAMOrderTurretNexus"] = 1200.0000 ,["Draven"] = 1700.0000 ,["FiddleSticks"] = 1750.0000 ,["SmallGolem"] = math.huge ,["ARAMOrderTurretFront"] = 1200.0000 ,["ChaosTurretTutorial"] = 1200.0000 ,["NasusUlt"] = 1200.0000 ,["Maokai"] = math.huge ,["Wraith"] = 750.0000 ,["Wolf"] = math.huge ,["Sivir"] = 1750.0000 ,["Corki"] = 2000.0000 ,["Janna"] = 1200.0000 ,["Nasus"] = math.huge ,["Golem"] = math.huge ,["ARAMChaosTurretFront"] = 1200.0000 ,["ARAMOrderTurretInhib"] = 1200.0000 ,["LeeSin"] = math.huge ,["HA_AP_ChaosTurretTutorial"] = 1200.0000 ,["GiantWolf"] = math.huge ,["HA_AP_OrderTurretTutorial"] = 1200.0000 ,["YoungLizard"] = 750.0000 ,["Jax"] = 400.0000 ,["LesserWraith"] = math.huge ,["Blitzcrank"] = math.huge ,["ARAMChaosTurretInhib"] = 1200.0000 ,["Shen"] = 400.0000 ,["Nocturne"] = math.huge ,["Sona"] = 1500.0000 ,["ARAMChaosTurretNexus"] = 1200.0000 ,["YellowTrinket"] = 1200.0000 ,["OrderTurretTutorial"] = 1200.0000 ,["Caitlyn"] = 2500.0000 ,["Trundle"] = 347.79999 ,["Malphite"] = 1000.0000 ,["Mordekaiser"] = math.huge ,["ZyraSeed"] = math.huge ,["Vi"] = 1000.0000 ,["Tutorial_Red_Minion_Wizard"] = 650.0000 ,["Renekton"] = math.huge ,["Anivia"] = 1400.0000 ,["Fizz"] = math.huge ,["Heimerdinger"] = 1500.0000 ,["Evelynn"] = 467.0000 ,["Rumble"] = 347.79999 ,["Leblanc"] = 1700.0000 ,["Darius"] = math.huge ,["OlafAxe"] = math.huge ,["Viktor"] = 2300.0000 ,["XinZhao"] = 20.0000 ,["Orianna"] = 1450.0000 ,["Vladimir"] = 1400.0000 ,["Nidalee"] = 1750.0000 ,["Tutorial_Red_Minion_Basic"] = math.huge ,["ZedShadow"] = 467.0000 ,["Syndra"] = 1800.0000 ,["Zac"] = 1000.0000 ,["Olaf"] = 347.79999 ,["Veigar"] = 1100.0000 ,["Twitch"] = 2500.0000 ,["Alistar"] = math.huge ,["Akali"] = 467.0000 ,["Urgot"] = 1300.0000 ,["Leona"] = 347.79999 ,["Talon"] = math.huge ,["Karma"] = 1500.0000 ,["Jayce"] = 347.79999 ,["Galio"] = 1000.0000 ,["Shaco"] = math.huge ,["Taric"] = math.huge ,["TwistedFate"] = 1500.0000 ,["Varus"] = 2000.0000 ,["Garen"] = 347.79999 ,["Swain"] = 1600.0000 ,["Vayne"] = 2000.0000 ,["Fiora"] = 467.0000 ,["Quinn"] = 2000.0000 ,["Kayle"] = math.huge ,["Blue_Minion_Basic"] = math.huge ,["Brand"] = 2000.0000 ,["Teemo"] = 1300.0000 ,["Amumu"] = 500.0000 ,["Annie"] = 1200.0000 ,["Odin_Blue_Minion_caster"] = 1200.0000 ,["Elise"] = 1600.0000 ,["Nami"] = 1500.0000 ,["Poppy"] = 500.0000 ,["AniviaEgg"] = 500.0000 ,["Tristana"] = 2250.0000 ,["Graves"] = 3000.0000 ,["Morgana"] = 1600.0000 ,["Gragas"] = math.huge ,["MissFortune"] = 2000.0000 ,["Warwick"] = math.huge ,["Cassiopeia"] = 1200.0000 ,["Tutorial_Blue_Minion_Wizard"] = 650.0000 ,["DrMundo"] = math.huge ,["Volibear"] = 467.0000 ,["Irelia"] = 467.0000 ,["Odin_Red_Minion_Caster"] = 650.0000 ,["Lucian"] = 2800.0000 ,["Yorick"] = math.huge ,["RammusPB"] = math.huge ,["Red_Minion_Basic"] = math.huge ,["Udyr"] = 467.0000 ,["MonkeyKing"] = 20.0000 ,["Tutorial_Blue_Minion_Basic"] = math.huge ,["Kennen"] = 1600.0000 ,["Nunu"] = 500.0000 ,["Ryze"] = 2400.0000 ,["Zed"] = 467.0000 ,["Nautilus"] = 1000.0000 ,["Gangplank"] = 1000.0000 ,["Lux"] = 1600.0000 ,["Sejuani"] = 500.0000 ,["Ezreal"] = 2000.0000 ,["OdinNeutralGuardian"] = 1800.0000 ,["Khazix"] = 500.0000 ,["Sion"] = math.huge ,["Aatrox"] = 347.79999 ,["Hecarim"] = 500.0000 ,["Pantheon"] = 20.0000 ,["Shyvana"] = 467.0000 ,["Zyra"] = 1700.0000 ,["Karthus"] = 1200.0000 ,["Rammus"] = math.huge ,["Zilean"] = 1200.0000 ,["Chogath"] = 500.0000 ,["Malzahar"] = 2000.0000 ,["YorickRavenousGhoul"] = 347.79999 ,["YorickSpectralGhoul"] = 347.79999 ,["JinxMine"] = 347.79999 ,["YorickDecayedGhoul"] = 347.79999 ,["XerathArcaneBarrageLauncher"] = 347.79999 ,["Odin_SOG_Order_Crystal"] = 347.79999 ,["TestCube"] = 347.79999 ,["ShyvanaDragon"] = math.huge ,["FizzBait"] = math.huge ,["Blue_Minion_MechMelee"] = math.huge ,["OdinQuestBuff"] = math.huge ,["TT_Buffplat_L"] = math.huge ,["TT_Buffplat_R"] = math.huge ,["KogMawDead"] = math.huge ,["TempMovableChar"] = math.huge ,["Lizard"] = 500.0000 ,["GolemOdin"] = math.huge ,["OdinOpeningBarrier"] = math.huge ,["TT_ChaosTurret4"] = 500.0000 ,["TT_Flytrap_A"] = 500.0000 ,["TT_NWolf"] = math.huge ,["OdinShieldRelic"] = math.huge ,["LuluSquill"] = math.huge ,["redDragon"] = math.huge ,["MonkeyKingClone"] = math.huge ,["Odin_skeleton"] = math.huge ,["OdinChaosTurretShrine"] = 500.0000 ,["Cassiopeia_Death"] = 500.0000 ,["OdinCenterRelic"] = 500.0000 ,["OdinRedSuperminion"] = math.huge ,["JarvanIVWall"] = math.huge ,["ARAMOrderNexus"] = math.huge ,["Red_Minion_MechCannon"] = 1200.0000 ,["OdinBlueSuperminion"] = math.huge ,["SyndraOrbs"] = math.huge ,["LuluKitty"] = math.huge ,["SwainNoBird"] = math.huge ,["LuluLadybug"] = math.huge ,["CaitlynTrap"] = math.huge ,["TT_Shroom_A"] = math.huge ,["ARAMChaosTurretShrine"] = 500.0000 ,["Odin_Windmill_Propellers"] = 500.0000 ,["TT_NWolf2"] = math.huge ,["OdinMinionGraveyardPortal"] = math.huge ,["SwainBeam"] = math.huge ,["Summoner_Rider_Order"] = math.huge ,["TT_Relic"] = math.huge ,["odin_lifts_crystal"] = math.huge ,["OdinOrderTurretShrine"] = 500.0000 ,["SpellBook1"] = 500.0000 ,["Blue_Minion_MechCannon"] = 1200.0000 ,["TT_ChaosInhibitor_D"] = 1200.0000 ,["Odin_SoG_Chaos"] = 1200.0000 ,["TrundleWall"] = 1200.0000 ,["HA_AP_HealthRelic"] = 1200.0000 ,["OrderTurretShrine"] = 500.0000 ,["OriannaBall"] = 500.0000 ,["ChaosTurretShrine"] = 500.0000 ,["LuluCupcake"] = 500.0000 ,["HA_AP_ChaosTurretShrine"] = 500.0000 ,["TT_NWraith2"] = 750.0000 ,["TT_Tree_A"] = 750.0000 ,["SummonerBeacon"] = 750.0000 ,["Odin_Drill"] = 750.0000 ,["TT_NGolem"] = math.huge ,["AramSpeedShrine"] = math.huge ,["OriannaNoBall"] = math.huge ,["Odin_Minecart"] = math.huge ,["Summoner_Rider_Chaos"] = math.huge ,["OdinSpeedShrine"] = math.huge ,["TT_SpeedShrine"] = math.huge ,["odin_lifts_buckets"] = math.huge ,["OdinRockSaw"] = math.huge ,["OdinMinionSpawnPortal"] = math.huge ,["SyndraSphere"] = math.huge ,["Red_Minion_MechMelee"] = math.huge ,["SwainRaven"] = math.huge ,["crystal_platform"] = math.huge ,["MaokaiSproutling"] = math.huge ,["Urf"] = math.huge ,["TestCubeRender10Vision"] = math.huge ,["MalzaharVoidling"] = 500.0000 ,["GhostWard"] = 500.0000 ,["MonkeyKingFlying"] = 500.0000 ,["LuluPig"] = 500.0000 ,["AniviaIceBlock"] = 500.0000 ,["TT_OrderInhibitor_D"] = 500.0000 ,["Odin_SoG_Order"] = 500.0000 ,["RammusDBC"] = 500.0000 ,["FizzShark"] = 500.0000 ,["LuluDragon"] = 500.0000 ,["OdinTestCubeRender"] = 500.0000 ,["TT_Tree1"] = 500.0000 ,["ARAMOrderTurretShrine"] = 500.0000 ,["Odin_Windmill_Gears"] = 500.0000 ,["ARAMChaosNexus"] = 500.0000 ,["TT_NWraith"] = 750.0000 ,["TT_OrderTurret4"] = 500.0000 ,["Odin_SOG_Chaos_Crystal"] = 500.0000 ,["OdinQuestIndicator"] = 500.0000 ,["JarvanIVStandard"] = 500.0000 ,["TT_DummyPusher"] = 500.0000 ,["OdinClaw"] = 500.0000 ,["EliseSpiderling"] = 2000.0000 ,["QuinnValor"] = math.huge ,["UdyrTigerUlt"] = math.huge ,["UdyrTurtleUlt"] = math.huge ,["UdyrUlt"] = math.huge ,["UdyrPhoenixUlt"] = math.huge ,["ShacoBox"] = 1500.0000 ,["HA_AP_Poro"] = 1500.0000 ,["AnnieTibbers"] = math.huge ,["UdyrPhoenix"] = math.huge ,["UdyrTurtle"] = math.huge ,["UdyrTiger"] = math.huge ,["HA_AP_OrderShrineTurret"] = 500.0000 ,["HA_AP_Chains_Long"] = 500.0000 ,["HA_AP_BridgeLaneStatue"] = 500.0000 ,["HA_AP_ChaosTurretRubble"] = 500.0000 ,["HA_AP_PoroSpawner"] = 500.0000 ,["HA_AP_Cutaway"] = 500.0000 ,["HA_AP_Chains"] = 500.0000 ,["ChaosInhibitor_D"] = 500.0000 ,["ZacRebirthBloblet"] = 500.0000 ,["OrderInhibitor_D"] = 500.0000 ,["Nidalee_Spear"] = 500.0000 ,["Nidalee_Cougar"] = 500.0000 ,["TT_Buffplat_Chain"] = 500.0000 ,["WriggleLantern"] = 500.0000 ,["TwistedLizardElder"] = 500.0000 ,["RabidWolf"] = math.huge ,["HeimerTGreen"] = 1599.3999 ,["HeimerTRed"] = 1599.3999 ,["ViktorFF"] = 1599.3999 ,["TwistedGolem"] = math.huge ,["TwistedSmallWolf"] = math.huge ,["TwistedGiantWolf"] = math.huge ,["TwistedTinyWraith"] = 750.0000 ,["TwistedBlueWraith"] = 750.0000 ,["TwistedYoungLizard"] = 750.0000 ,["Red_Minion_Melee"] = math.huge ,["Blue_Minion_Melee"] = math.huge ,["Blue_Minion_Healer"] = 1000.0000 ,["Ghast"] = 750.0000 ,["blueDragon"] = 800.0000 ,["Red_Minion_MechRange"] = 3000, ["SRU_OrderMinionRanged"] = 650, ["SRU_ChaosMinionRanged"] = 650, ["SRU_OrderMinionSiege"] = 1200, ["SRU_ChaosMinionSiege"] = 1200, ["SRUAP_Turret_Chaos1"]  = 1200, ["SRUAP_Turret_Chaos2"]  = 1200, ["SRUAP_Turret_Chaos3"] = 1200, ["SRUAP_Turret_Order1"]  = 1200, ["SRUAP_Turret_Order2"]  = 1200, ["SRUAP_Turret_Order3"] = 1200, ["SRUAP_Turret_Chaos4"] = 1200, ["SRUAP_Turret_Chaos5"] = 500, ["SRUAP_Turret_Order4"] = 1200, ["SRUAP_Turret_Order5"] = 500 }

local ActiveAttacks = {}
local MinionsAttacks = {}

local lastick = 0

local nohitboxmode = false
local DontUseWayPoints = false
local ShotAtMaxRange = true

local WaypointsTime = 10


local TargetsVisible = {}
local TargetsWaypoints = {}
local TargetsImmobile = {}
local TargetsDashing = {}
local TargetsSlowed = {}
local DontShoot = {}
local DontShoot2 = {}
local DontShootUntilNewWaypoints = {}


--Callback.Add("Tick", function() self:OnTick() end)
--Callback.Add("Draw", function() self:OnDraw() end)
--Callback.Add("ProcessSpell", function(unit, spell) self:OnProcessSpell(unit, spell) end)
--Callback.Add("ProcessSpell", function(unit, spell) self:CollisionProcessSpell(unit, spell) end)
--Callback.Add("UpdateBuff", function(unit, buff) self:OnGainBuff(unit, buff) end)
--Callback.Add("PlayAnimation", function(unit, anim) self:Animation(unit, anim) end)
--Callback.Add("NewPath", function(...) self:OnNewPath(...) end)


local BlackList = {
    {name = "aatroxq", duration = 0.75}, --[[4 Dashes, OnDash fails]]
}

--[[Spells that will cause OnDash to fire, dont shoot and wait to OnDash]]
local dashAboutToHappend ={
    --{name = "zedw2", duration = 0.25},--zed w
    {name = "ahritumble", duration = 0.25},--ahri's r
    {name = "akalishadowdance", duration = 0.25},--akali r
    {name = "headbutt", duration = 0.25},--alistar w
    {name = "caitlynentrapment", duration = 0.25},--caitlyn e
    {name = "carpetbomb", duration = 0.25},--corki w
    {name = "dianateleport", duration = 0.25},--diana r
    {name = "fizzpiercingstrike", duration = 0.25},--fizz q
    {name = "fizze", duration = 0.25},--fizz e
    {name = "gragase", duration = 0.25},--gragas e
    {name = "gravesmove", duration = 0.25},--graves e
    {name = "ireliagatotsu", duration = 0.25},--irelia q
    {name = "jarvanivdragonstrike", duration = 0.25},--jarvan q
    {name = "jaxleapstrike", duration = 0.25},--jax q
    {name = "khazixe", duration = 0.25},--khazix e and e evolved
    {name = "khazixelong", duration = 0.25},--khazix e and e evolved
    {name = "leblancw", duration = 0.25},--leblanc w
    {name = "leblancslidem", duration = 0.25},--leblanc w (r)
    {name = "blindmonkqtwo", duration = 0.25},--lee sin q
    {name = "blindmonkwone", duration = 0.25},--lee sin w
    {name = "luciane", duration = 0.25},--lucian e
    {name = "maokaiw", duration = 0.25},--maokai w
    {name = "braumw", duration = 0.25},--maokai w
    {name = "nocturneparanoia2", duration = 0.25},--nocturne r
    {name = "pantheonw", duration = 0.25},--pantheon w?
    {name = "renektonsliceanddice", duration = 0.25},--renekton e
    {name = "renektondice", duration = 0.25},--renekton e
    {name = "riventricleave", duration = 0.25},--riven q
    {name = "rivenfeint", duration = 0.25},--riven e
    {name = "sejuaniq", duration = 0.25},--sejuani q
    {name = "shene", duration = 0.25},--shen e
    {name = "shyvanatransformcast", duration = 0.25},--shyvana r
    {name = "tristanaw", duration = 0.25},--tristana w
    {name = "slashcast", duration = 0.25},--tryndamere e
    {name = "vaynetumble", duration = 0.25},--vayne q
    {name = "viq", duration = 0.25},--vi q
    {name = "zace", duration = 0.25},--zac q
    {name = "monkeykingnimbus", duration = 0.25},--wukong q
    {name = "xinzhaoe", duration = 0.25},--xin xhao e
    {name = "yasuodashwrapper", duration = 0.25},--yasuo e
    {name = "camillee", duration = 0.25},--camille e
    {name = "ekkoe", duration = 0.25},--Ekko e
    {name = "ekkoeattack", duration = 0.25},--Ekko e
    {name = "fioraq", duration = 0.25},--fiora q
    {name = "galioe", duration = 0.25},--galio e
    {name = "ufslash", duration = 0.25},--maphite r
    {name = "kindredq", duration = 0.25},--kindred q
    {name = "rakanw", duration = 0.25},--Rakan w
    {name = "poppye", duration = 0.25},--Poppy e
    {name = "kaynq", duration = 0.25},--Kayn q
    {name = "urgote", duration = 0.25},--Urgot e
    {name = "tryndameree", duration = 0.25},--Tryndamere e
    {name = "ornne", duration = 0.25},--ornn e
    --{name = "aatroxq", duration = 0.75},
}
--[[Spells that don't allow movement (durations approx)]]
local spells = {
    {name = "pantheon_leapbash", duration = 0.25},--pantheon e?
    {name = "katarinar", duration = 1}, --Katarinas R
    {name = "drain", duration = 1}, --Fiddle W
    {name = "crowstorm", duration = 1}, --Fiddle R
    {name = "consume", duration = 0.5}, --Nunu Q
    {name = "absolutezero", duration = 1}, --Nunu R
    {name = "rocketgrab", duration = 0.5}, --Blitzcrank Q
    {name = "staticfield", duration = 0.5}, --Blitzcrank R
    {name = "cassiopeiapetrifyinggaze", duration = 0.5}, --Cassio's R
    {name = "ezrealtrueshotbarrage", duration = 1}, --Ezreal's R
    {name = "galioidolofdurand", duration = 1}, --Ezreal's R
    --{name = "gragasdrunkenrage", duration = 1}, --Gragas W, Rito changed it so that it allows full movement while casting
    {name = "luxmalicecannon", duration = 1}, --Lux R
    {name = "reapthewhirlwind", duration = 1}, --Jannas R
    {name = "jinxw", duration = 0.6}, --jinxW
    {name = "jinxr", duration = 0.6}, --jinxR
    {name = "missfortunebullettime", duration = 1}, --MissFortuneR
    {name = "shenstandunited", duration = 1}, --ShenR
    {name = "threshe", duration = 0.4}, --ThreshE
    {name = "threshrpenta", duration = 0.75}, --ThreshR
    {name = "infiniteduress", duration = 1}, --Warwick R
    {name = "meditate", duration = 1} --yi W
}

local blinks = {
    {name = "zedw", range = 475, delay = 0.25, delay2=0.8},--zed w
    {name = "akalismokebomb", range = 250, delay = 0.25, delay2=0.8},--flash r,
    {name = "summonerflash", range = 400, delay = 0.25, delay2=0.8},--flash r,
    {name = "zoer", range = 570, delay = 0.25, delay2=0.8},--zoe r,
    {name = "ezrealarcaneshift", range = 475, delay = 0.25, delay2=0.8},--Ezreals E
    {name = "deceive", range = 400, delay = 0.25, delay2=0.8}, --Shacos Q
    {name = "riftwalk", range = 700, delay = 0.25, delay2=0.8},--KassadinR
    {name = "gate", range = 5500, delay = 1.5, delay2=1.5},--Twisted fate R
    {name = "katarinae", range = math.huge, delay = 0.25, delay2=0.8},--Katarinas E
    {name = "elisespideredescent", range = math.huge, delay = 0.25, delay2=0.8},--Elise E
    {name = "elisespidere", range = math.huge, delay = 0.25, delay2=0.8},--Elise insta E
}


local function GetCurrentWayPoints(object)
    local result = {}

    if not object then 
        return 
    end

    if object.path.active and object.path.count > 0 then
        table.insert(result, object.pos)
        for i = 1, object.path.count do

            local objPath = object.path.point[i]
            table.insert(result, objPath)
        end
    else
        table.insert(result, vec3(object.x, object.y, object.z))
    end
    return result
end

local function isSlowed(unit, delay, speed, from)
    if TargetsSlowed[unit.networkID] then
        local distance = common.GetDistance(unit, from)
        if TargetsSlowed[unit.networkID] > (os.clock() + delay + distance / speed) then
            return true
        end
    end
    return false
end

local function IsImmobile(unit, delay, width, speed, from, spelltype)
    local radius = width / 2

    if TargetsImmobile[unit.networkID] then
        local ExtraDelay = speed == math.huge and  0 or (common.GetDistance(from, unit) / speed)
        if (TargetsImmobile[unit.networkID] > (os.clock() + delay + ExtraDelay) and spelltype == 0) then
            return true, vec3(unit.x, unit.y, unit.z), vec3(unit.x, unit.y, unit.z) + (radius / 3) * (vec3(from.x, from.y, from.z) - vec3(unit.x, unit.y, unit.z)):norm()
        elseif (TargetsImmobile[unit.networkID] + (radius / unit.moveSpeed)) > (os.clock() + delay + ExtraDelay) then
            return true, vec3(unit.x, unit.y, unit.z), vec3(unit.x, unit.y, unit.z)
        end
    end
    return false, vec3(unit.x, unit.y, unit.z),  vec3(unit.x, unit.y, unit.z)
end

local function IsDashing(unit, delay, radius, speed, from)
    local TargetDashing = false
    local CanHit = false
    local Position = nil

    if TargetsDashing[unit.networkID] then
        local dash = TargetsDashing[unit.networkID]
        if dash.endT >= os.clock() then
            TargetDashing = true
            if dash.isblink then
                if (dash.endT - os.clock()) <= (delay + common.GetDistance(from, dash.endPos)/speed) then
                    Position = vec3(dash.endPos.x, 0, dash.endPos.z)
                    CanHit = (unit.moveSpeed * (delay + common.GetDistance(from, dash.endPos)/speed - (dash.endT2 - os.clock()))) < radius
                end

                if ((dash.endT - os.clock()) >= (delay + common.GetDistance(from, dash.startPos)/speed)) and not CanHit then
                    Position = vec3(dash.startPos.x, 0, dash.startPos.z)
                    CanHit = true
                end
            else
                local t1, p1, t2, p2, dist = common.VectorMovementCollision(dash.startPos, dash.endPos, dash.speed, from, speed, (os.clock() - dash.startT) + delay)
                t1, t2 = (t1 and 0 <= t1 and t1 <= (dash.endT - os.clock() - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <=  (dash.endT - os.clock() - delay)) and t2 or nil
                local t = t1 and t2 and math.min(t1,t2) or t1 or t2
                if t then
                    Position = t==t1 and vec3(p1.x, 0, p1.y) or vec3(p2.x, 0, p2.y)
                    CanHit = true
                else
                    Position = vec3(dash.endPos.x, 0, dash.endPos.z)
                    CanHit = (unit.moveSpeed * (delay + common.GetDistance(from, Position)/speed - (dash.endT - os.clock()))) < radius
                end
            end
        end
    end
    return TargetDashing, CanHit, Position
end

local function GetWaypoints(NetworkID, from, to)
    local Result = {}
    to = to and to or os.clock()
    if TargetsWaypoints[NetworkID] then
        for i, waypoint in ipairs(TargetsWaypoints[NetworkID]) do
            if from <= waypoint.time and to >= waypoint.time then
                table.insert(Result, waypoint)
            end
        end
    end
    return Result, #Result
end
	

local function CountWaypoints(NetworkID, from, to)
    local R, N = GetWaypoints(NetworkID, from, to)
    --if N == nil then N = 0 end
    return N
end

local function GetWaypointsLength(Waypoints)
    local result = 0
    for i = 1, #Waypoints -1 do
        result = result + common.GetDistance(Waypoints[i], Waypoints[i + 1])
    end
    return result
end

local function CutWaypoints(Waypoints, distance)
    local result = {}
    local remaining = distance
    if distance > 0 then
        for i = 1, #Waypoints -1 do
            local A, B = Waypoints[i], Waypoints[i + 1]
            local dist = common.GetDistance(A, B)
            if dist >= remaining then
                result[1] = A + remaining * (B - A):norm()

                for j = i + 1, #Waypoints do
                    result[j - i + 1] = Waypoints[j]
                end
                remaining = 0
                break
            else
                remaining = remaining - dist
            end
        end
    else
        local A, B = Waypoints[1], Waypoints[2]
        result = Waypoints
        result[1] = A - distance * (B - A):norm()
    end

    return result
end

--[[Calculate the hero position based on the last waypoints]]
local function CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, second)
    if unit and unit.type == TYPE_HERO and unit.team == TEAM_ENEMY  then
        --print(unit.charName.." "..#PA[unit.networkID])
        if #PA[unit.networkID] > 4 then
            return vec3(unit.x, unit.y, unit.z), vec3(unit.x, unit.y, unit.z)
        elseif #PA[unit.networkID] > 3 then
            delay = delay*.8
            speed = speed*1.20
        end

    end
    local spot
    local startPos = unit.path.point[0]
    local endPath = unit.path.point[unit.path.count]
    if common.IsValidTarget(unit) and endPath then    ---- FIX
        local p90x = second and second or unit
        local pathPot = (unit.moveSpeed * ((common.GetDistance(player, p90x) / speed) + delay))

        if unit.path.count < 3 then
            local v = unit.pos + (endPath - unit.pos):norm() * (pathPot - unit.boundingRadius + 10)
            if common.GetDistance(unit, v) > 1 then
                if common.GetDistance(endPath, unit) >= common.GetDistance(unit, v) then
                    spot = v
                else
                    spot = endPath
                end
            else
                spot = endPath
            end
        else
            local pathIndex = GetPathIndex(unit)
            for i = pathIndex, unit.path.count do
                --print'Path'
                if unit.path.point[i] and unit.path.point[i - 1] then
                    local pStart = i == pathIndex and vec3(unit.x, unit.y, unit.z) or unit.path.point[i - 1]
                    local pEnd = unit.path.point[i]
                    local iPathDist = common.GetDistance(pStart, pEnd)
                    if unit.path.point[pathIndex - 1] then
                        if pathPot > iPathDist then
                            pathPot = pathPot-iPathDist
                        else
                            local v = pStart + (pEnd - pStart):norm()*(pathPot- unit.boundingRadius + 10)
                            spot = v
                            if second then
                                return spot, spot
                            else
                                return CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, spot)
                            end
                        end
                    end
                end
            end
            if common.GetDistance(unit, endPath) > unit.boundingRadius then
                spot = endPath
            else
                spot = vec3(unit.x, unit.y, unit.z)
            end
        end
    end
    spot = spot and spot or vec3(unit.x, unit.y, unit.z)
    if second then
        return spot, spot
    else
        return CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, spot)
    end
end

local function MaxAngle(unit, currentwaypoint, from)
    local WPtable, n = GetWaypoints(unit.networkID, from)
    local Max = 0
    local CV = (vec3(currentwaypoint.x, 0, currentwaypoint.y) - unit.pos)
        for i, waypoint in ipairs(WPtable) do
            local angle =  mathf.angle_between(vec2(0, 0), CV:to2D(), vec2(waypoint.waypoint.x, waypoint.waypoint.y) - vec2(waypoint.unitpos.x, waypoint.unitpos.y))
            if angle > Max then
                Max = angle
            end
        end
    return Max
end

local function GetPredictedHealth(unit, time, delay)
    local IncDamage = 0
    local i = 1
    local MaxDamage = 0
    local count = 0

    delay = delay and delay or 0.07
    while i <= #ActiveAttacks do
        if ActiveAttacks[i].Attacker and not ActiveAttacks[i].Attacker.IsDead and ActiveAttacks[i].Target and ActiveAttacks[i].Target.networkID == unit.networkID then
            local hittime = ActiveAttacks[i].starttime + ActiveAttacks[i].windUpTime + (common.GetDistance(ActiveAttacks[i].pos, unit)) / ActiveAttacks[i].projectilespeed + delay
            if os.clock() < hittime - delay and hittime < os.clock() + time  then
                IncDamage = IncDamage + ActiveAttacks[i].damage
                count = count + 1
                if ActiveAttacks[i].damage > MaxDamage then
                    MaxDamage = ActiveAttacks[i].damage
                end
            end
        end
        i = i + 1
    end

    return unit.health - IncDamage, MaxDamage, count
end

local function GetProjectileSpeed(unit)
    return projectilespeeds[unit.charName] and projectilespeeds[unit.charName] or math.huge
end

local function WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
    local Position, CastPosition, HitChance
    local SavedWayPoints = TargetsWaypoints[unit.networkID] and TargetsWaypoints[unit.networkID] or {}
    local CurrentWayPoints = GetCurrentWayPoints(unit)
    local VisibleSince = TargetsVisible[unit.networkID] and TargetsVisible[unit.networkID]

    if delay < 0.25 then
        HitChance = 2
    else
        HitChance = 1
    end

    Position, CastPosition = CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)

    if CountWaypoints(unit.networkID, os.clock() - 0.1) >= 1 or CountWaypoints(unit.networkID, os.clock() - 1) == 1 then
        HitChance = 2
    end

    if not unit.path.isActive and common.GetDistance(player, unit) < range then
        HitChance = 3
    end

    local N = 0
    local t1 = 0

    if menu.Combo:get() then
        N = (menu.Combo:get() == _SLOW) and 3 or 2
        t1 = (menu.Combo:get() == _SLOW) and 1 or 0.5
    else
        N = 2
        t1 = 0.5
    end

    if CountWaypoints(unit.networkID, os.clock() - 0.75) >= N then
        local angle = MaxAngle(unit, CurrentWayPoints[#CurrentWayPoints], os.clock() - t1)
        if angle > 90 then
            HitChance = 1
        elseif angle < 30 and CountWaypoints(unit.networkID, os.clock() - 0.1) >= 1 then
            HitChance = 2
        end
    end

    if menu.Combo:get() then
        N = (menu.Combo:get() == _SLOW) and 2 or 1
    else
        N = 1
    end
    if CountWaypoints(unit.networkID, os.clock() - N) == 0 then
        HitChance = 2
    end

    if menu.Combo:get() then
        if menu.Combo:get()== _FAST then
            HitChance = 2
        end
    else
        HitChance = 2
    end

    if #CurrentWayPoints <= 1 and os.clock() - VisibleSince > 1 then
        HitChance = 2
    end

    if isSlowed(unit, delay, speed, from) then
        HitChance = 3
    end

    if Position and CastPosition and ((radius / unit.moveSpeed >= delay + common.GetDistance(from, CastPosition)/speed) or (radius / unit.moveSpeed >= delay + common.GetDistance(from, Position)/speed)) then
        HitChance = 3
    end
    --[[Angle too wide]]
    local tempAngle = mathf.angle_between(from.pos:to2D(), unit.pos:to2D(), CastPosition)
    if tempAngle > 60 then
        HitChance = 1
    end

    if not Position or not CastPosition then
        HitChance = 0
        CastPosition = vec3(unit.x, unit.y, unit.z)
        Position = CastPosition
    end

    if common.GetDistance(player, unit) < 250 and unit ~= player then
        HitChance = 2
        Position, CastPosition = CalculateTargetPosition(unit, delay*0.5, radius, speed*2, from, spelltype)
        Position = CastPosition
    end

    if #SavedWayPoints == 0 and (os.clock() - VisibleSince) > 3 then
        HitChance = 2
    end

    if DontShootUntilNewWaypoints[unit.networkID] then
        HitChance = 0
        CastPosition = vec3(unit.x, unit.y, unit.z)
        Position = CastPosition
    end

    return CastPosition, HitChance, Position
end

local function CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw)
    if unit.networkID == minion.networkID then
        return false
    end

    --[[Check first if the minion is going to be dead when skillshots reaches his position]]
    if minion.type ~= player.type and  orb.farm.predict_hp(minion, delay + common.GetDistance(from, minion) / speed)  < 0 then
        return false
    end

    --local waypoints = GetCurrentWayPoints(minion)
    local MPos, CastPosition = minion.path.count == 1 and minion or CalculateTargetPosition(minion, delay, radius, speed, from, "line")
    if common.GetDistanceSqr(from, MPos) <= (range)^2 and common.GetDistanceSqr(from, minion) <= (range + 100)^2 then
        local buffer = 0
        if menu.buffer:get() then
            buffer = (minion.path.count > 1) and menu.buffer:get() or 8
        else
            if (minion.path.count > 1) then
                buffer = 20
            else
                buffer = 8
            end
        end

        if minion.type == player.type then
            buffer = buffer + minion.boundingRadius
        end

        if minion.path.count > 1 then
            local proj1, pointLine, isOnSegment = common.VectorPointProjectionOnLineSegment(from, Position, MPos)
            if isOnSegment and (common.GetDistanceSqr(MPos, proj1) <= (minion.boundingRadius + radius + buffer) ^ 2) then
                return true
            end
        end

        local proj2, pointLine, isOnSegment = common.VectorPointProjectionOnLineSegment(from, Position, minion)
        if isOnSegment and (common.GetDistanceSqr(minion, proj2) <= (minion.boundingRadius + radius + buffer) ^ 2) then
            return true
        end
    end
    return false
end

local function CheckMinionCollision(unit, Position, delay, radius, range, speed, from, draw, updatemanagers)
    Position = Position
    from = from and from or player
    --local draw = true
    --[[if updatemanagers then
        self.EnemyMinions.range = range + 500 * (delay + range / speed)
        self.JungleMinions.range = self.EnemyMinions.range
        self.OtherMinions.range = self.EnemyMinions.range
        self.EnemyMinions:update()
        self.JungleMinions:update()
        self.OtherMinions:update()
        self.AllyMinions:update()
    end]]
    local result = false

        for i=0, objManager.maxObjects-1 do
            local obj = objManager.get(i)
            if obj then
                if obj and obj.team == TEAM_ENEMY then
                    --__PrintTextGame(tostring(GetObjName(minion.Addr)))
                    if obj.type == TYPE_MINION then
                        if CheckCol(unit, obj, Position, delay, radius, range, speed, from, draw) then
                            if not draw then
                                return true
                            else
                                result = true
                            end
                        end
                    end
                    if obj.type == TEAM_NEUTRAL and (obj.name ~= "PlantSatchel" and obj.name ~= "PlantHealth" and obj.name ~= "PlantVision") then
                        if CheckCol(unit, obj, Position, delay, radius, range, speed, from, draw) then
                            if not draw then
                                return true
                            else
                                result = true
                            end
                        end
                    end
                end
            end
        end
        for i=0, objManager.enemies_n-1 do
            local obj = objManager.enemies[i]
            if obj then 
                if CheckCol(unit, obj, Position, delay, radius, range, speed, from, draw) then
                    if not draw then
                        return true
                    else
                        result = true
                    end
                end
            end
        end
    return result
end


local function GetBestCastPosition(unit, delay, radius, range, speed, from, collision, spelltype)
    assert(unit, "[SDK]VPrediction: Target can't be nil")
    --LastFocusedTarget = unit
    range = range and range - 15 or math.huge
    radius = radius == 0 and 1 or (radius + unit.boundingRadius) - 4
    speed = speed and speed or math.huge
    from = from and from or player
    --excludeWaypoints = excludeWaypoints and excludeWaypoints or false

    local IsFromMyHero = common.GetDistanceSqr(from, player) < 50*50 and true or false

    delay = delay + (0.07 + network.latency / 2000)

    local Position, CastPosition, HitChance = vec3(unit.x, unit.y, unit.z), vec3(unit.x, unit.y, unit.z), 0
    local TargetDashing, CanHitDashing, DashPosition = IsDashing(unit, delay, radius, speed, from)
    local TargetImmobile, ImmobilePos, ImmobileCastPosition = IsImmobile(unit, delay, radius, speed, from, spelltype)
    local VisibleSince = TargetsVisible[unit.networkID] and TargetsVisible[unit.networkID] or os.clock()

    if unit.type ~= player.type then
        Position, CastPosition = CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)
        HitChance = 2
    else
        if DontShoot[unit.networkID] and DontShoot[unit.networkID] > os.clock() then
            Position, CastPosition = vec3(unit.x, unit.y, unit.z), vec3(unit.x, unit.y, unit.z)
            HitChance = 0
        elseif TargetDashing then
            if CanHitDashing then
                HitChance = 5
            else
                HitChance = 0
            end
            Position, CastPosition = DashPosition, DashPosition
        elseif DontShoot2[unit.networkID] and DontShoot2[unit.networkID] > os.clock() then
            Position, CastPosition = vec3(unit.x, unit.y, unit.z),  vec3(unit.x, unit.y, unit.z)
            HitChance = 7
        elseif TargetImmobile then
            Position, CastPosition = ImmobilePos, ImmobileCastPosition
            HitChance = 4
        elseif not DontUseWayPoints then
            CastPosition, HitChance, Position = WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
        end
    end

    --[[Out of range]]
    if IsFromMyHero then
        if (spelltype == "line" and common.GetDistanceSqr(from, Position) >= range * range) then
            HitChance = 0
        end
        if (spelltype == "circular" and (common.GetDistanceSqr(from, Position) >= (range + radius)^2)) then
            HitChance = 0
        end

        if ShotAtMaxRange and HitChance ~= 0 and spelltype == "circular" and (common.GetDistanceSqr(from, CastPosition) > range ^ 2) then
            if common.GetDistanceSqr(from, Position) <= (range + radius / 1.4) ^ 2 then
                if common.GetDistanceSqr(from, Position) <= range * range then
                    CastPosition = Position
                else
                    CastPosition = from + range * (Position - from):norm()
                end
            end
        elseif (common.GetDistanceSqr(from, CastPosition) > range ^ 2) then
            HitChance = 0
        end
    end

    radius = radius - unit.boundingRadius + 4

    if collision and HitChance > 0 then


        if menu._Minions:get() and CheckMinionCollision(unit, CastPosition, delay, radius, range, speed, from, false, false) then
            HitChance = -1
        elseif menu._Minions:get() and CheckMinionCollision(unit, Position, delay, radius, range, speed, from, false, false) then
            HitChance = -1
        end

        if menu._Minions:get() and CheckMinionCollision(unit, unit, delay, radius, range, speed, from, false, false) then
            HitChance = -1
        end
    end
    return CastPosition, HitChance, Position
end

local function OnGainBuff()
    for i=0, objManager.maxObjects-1 do
        local unit = objManager.get(i)
        if unit and unit.type == TYPE_HERO and unit.team == TEAM_ENEMY then 
            for i, buff in pairs(unit.buff) do
                if (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) then
                    TargetsImmobile[unit.networkID] = os.clock() + (buff.endTime - buff.startTime)
                elseif (buff.type == 10 or buff.type == 22 or buff.type == 21 or buff.type == 8) then
                    TargetsSlowed[unit.networkID] = os.clock() + (buff.endTime - buff.startTime)
                end
                
                if (buff.type == 30) then
                    DontShoot[unit.networkID] = os.clock() + 1
                end
            end
        end 
    end
end

local function OnTick()
    if not lastick or os.clock() - lastick > 0.2 then
        lastick = os.clock()
        for i=0, objManager.enemies_n-1 do
            local enemy = objManager.enemies[i]
            if enemy and common.IsValidTarget(enemy) then 
                for i, tbl in pairs(PA[enemy.networkID]) do
                    if os.clock() - 1.5 > tbl.t then
                        table.remove(PA[enemy.networkID], i)
                    end
                end
            end
        end
        for i, tbl in pairs(PA[player.networkID]) do
            if os.clock() - 1.5 > tbl.t then
                table.remove(PA[player.networkID], i)
            end
        end
        for NID, TargetWaypoints in pairs(TargetsWaypoints) do
            local i = 1
            while i <= #TargetsWaypoints[NID] do
                if TargetsWaypoints[NID][i]["time"] + WaypointsTime < os.clock() then
                    table.remove(TargetsWaypoints[NID], i)
                else
                    i = i + 1
                end
            end
        end
    end

    OnGainBuff()


    --[[for i=0, objManager.enemies_n-1 do
        local unit = objManager.enemies[i]
        if unit and common.IsValidTarget(unit) then 
            if not unit then 
                return 
            end 
            local CastPosition, HitChance, Position = GetBestCastPosition(unit, 1, 200, 825, math.huge, player, false, "circular")

            if HitChance > 1 then 
                player:castSpell('pos', 0, Position)
            end 
        end 
    end]]

    for _, target in pairs(common.GetEnemyHeroes()) do
        if target then
            if target.isVisible then
                TargetsVisible[target.networkID] = os.clock()
            else 
                TargetsVisible[target.networkID] = 0
            end
        end 
    end
    
end
local function GetCircularAOEPrediction(unit, delay, radius, range, speed, sourcePos, collision, spelltype)
    local castPos = GetBestCastPosition(unit, delay, radius, range, speed, sourcePos, collision, spelltype)
    local pI = { x = castPos.x, y = castPos.y, z = castPos.z}

    if (radius and radius > 1) then
        local width = 1 * radius
        local aoeCastPos, threshold = castPos, (2 * width) ^ 2
  
        for _, enemy in pairs(common.GetEnemyHeroes()) do
            
            if enemy and enemy ~= unit and enemy.isVisible and common.IsValidTarget(enemy) then
                local Vecp = GetBestCastPosition(unit, delay, radius, range, speed, sourcePos, collision, spelltype)
                local m_sq = (Vecp.x - aoeCastPos.x) ^ 2 + (Vecp.z - aoeCastPos.z) ^ 2
    
                if m_sq < threshold then
                    aoeCastPos.x, aoeCastPos.z = 0.5 * (aoeCastPos.x + Vecp.x), 0.5 * (aoeCastPos.z + Vecp.z)
                    threshold = threshold - (0.5 * m_sq)
                end
            end
        end
  
        castPos.x, castPos.y, castPos.z = aoeCastPos.x, aoeCastPos.y, aoeCastPos.z
    end
    return castPos
end

local function OnProcessSpell(spell)
    if spell.owner and spell.owner.type == TYPE_HERO then 
        for i, s in ipairs(spells) do
            if spell.name:lower() == s.name then
                TargetsImmobile[spell.owner.networkID] = os.clock() + s.duration
                return
            end
        end
        local startPos = vec3(spell.startPos.x, spell.startPos.y, spell.startPos.z)
        local endPos = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)
        for i, s in ipairs(blinks) do
            local LandingPos = common.GetDistance(spell.owner, endPos) < s.range and endPos or spell.owner.pos + s.range * (endPos - spell.owner.pos):norm()
            if spell.name:lower() == s.name and not navmesh.isWall(endPos) then
                TargetsDashing[spell.owner.networkID] = {isblink = true, duration = s.delay, endT = os.clock() + s.delay, endT2 = os.clock() + s.delay2, startPos = spell.owner.pos, endPos = LandingPos}
                return
            end
        end

        for i, s in ipairs(BlackList) do
            if spell.name:lower() == s.name then
                DontShoot[spell.owner.networkID] = os.clock() + s.duration
                return
            end
        end

        for i, s in ipairs(dashAboutToHappend) do
            if spell.name:lower() == s.name then
                DontShoot2[spell.owner.networkID] = os.clock() + s.duration
                return
            end
        end
    end

    if spell.owner and _has_value({TYPE_HERO, TYPE_MINION, TYPE_CAMP}, spell.owner.type) then 
        if string.match(spell.name:lower(), "attack")  and not projectilespeeds[spell.owner.charName] then
            local time = os.clock() + 0.393 - network.latency/2000
            local tar = GetAggro(spell.owner)
            if tar then
                table.insert(ActiveAttacks, {Attacker = spell.owner, pos = spell.owner.pos, Target = tar, animationTime = math.huge, damage = common.CalculateAADamage(spell.owner), hittime=time, starttime = os.clock() - network.latency/2000, windUpTime = 0.393, projectilespeed = math.huge})
            end
        end
    end

    if spell.target and spell.owner and spell.owner.type ~= player.type and (spell.owner.type == TYPE_MINION or spell.owner.type == TYPE_CAMP) and spell.owner.type == TYPE_HERO and spell and spell.name and (spell.name:lower():find("attack") or (spell.name == "frostarrow")) and spell.static.castFrame and spell.target then
        if common.GetDistanceSqr(spell.target) < 4000000 then
            if projectilespeeds[spell.target.charName] then
                local time = os.clock() + common.GetDistance(spell.target, spell.owner) / GetProjectileSpeed(spell.owner) - network.latency/2000
                local i = 1
                while i <= #ActiveAttacks do
                    if (ActiveAttacks[i].Attacker and ActiveAttacks[i].Attacker.IsValid and ActiveAttacks[i].Attacker.networkID == spell.owner.networkID) or ((ActiveAttacks[i].hittime + 3) < os.clock()) then
                        table.remove(ActiveAttacks, i)
                    else
                        i = i + 1
                    end
                end

                table.insert(self.ActiveAttacks, {Attacker = spell.owner, pos = spell.owner.pos, Target = spell.target, animationTime = spell.animationTime, damage = common.CalculateAADamage(spell.owner), hittime = time, starttime = os.clock() - network.latency/2000, windUpTime = 0, projectilespeed = GetProjectileSpeed(spell.owner)})
            else
                minionTar[spell.owner.networkID] = spell.target
            end
        end
    end
end

--0=champ, 1=minion, 2=turret, 3=jungle, 4= Inhibitor, 5=Nexus, 6=Missile, -1= other
local function OnNewPath()
    for i=0, objManager.maxObjects-1 do
        local unit = objManager.get(i)
        if unit and unit.type == TYPE_HERO and unit.team == TEAM_ENEMY then

            local startPos = unit.path.point[0]
            local endPos = unit.path.point[unit.path.count]
            
            if PA[unit.networkID] and PA[unit.networkID][#PA[unit.networkID] -1] then
                local p1 = PA[unit.networkID][#PA[unit.networkID] -1].p
                local p2 = PA[unit.networkID][#PA[unit.networkID]].p
                local angle =  mathf.angle_between(unit.pos:to2D(), vec2(p2.x, p2.z), vec2(p1.x, p1.z))
                if angle > 20 then
                    local submit = {t = os.clock(), p = endPos}
                    table.insert(PA[unit.networkID], submit)
                end
            else
                if PA[unit.networkID] and PA[unit.networkID][#PA[unit.networkID]] then 
                    local submit = {t = os.clock(), p = endPos}
                    table.insert(PA[unit.networkID], submit)
                end
            end

            --[[OnDash Alternative]]
            if unit.path.isActive and unit.path.isDashing  then --isDash
                local dash = {}
                dash.startPos = startPos
                dash.endPos = endPos
                dash.speed = unit.path.dashSpeed
                dash.startT = os.clock() - network.latency/2000
                local dis = common.GetDistance(startPos, endPos)
                dash.endT = dash.startT + (dis/unit.path.dashSpeed)
                TargetsDashing[unit.networkID] = dash
                DontShootUntilNewWaypoints[unit.networkID] = true
            end

            
            local object = unit
            local NetworkID = unit.networkID
            
            if object and object.networkID and object.type == TYPE_HERO then
                DontShootUntilNewWaypoints[NetworkID] = false
                if not TargetsWaypoints[NetworkID] then
                    TargetsWaypoints[NetworkID] = {}
                end
                local WaypointsToAdd = GetCurrentWayPoints(unit)
                if WaypointsToAdd and #WaypointsToAdd >= 1 then
                    --[[Save only the last waypoint (where the player clicked)]]
                    table.insert(TargetsWaypoints[NetworkID], {unitpos = object.pos, waypoint = WaypointsToAdd[#WaypointsToAdd], time = os.clock(), n = #WaypointsToAdd})
                end
            elseif object and object.type ~= TYPE_HERO then
                local i = 1
                while i <= #ActiveAttacks do
                    if (ActiveAttacks[i].Attacker and ActiveAttacks[i].Attacker.IsValid and ActiveAttacks[i].Attacker.NetworkId == NetworkID and (ActiveAttacks[i].starttime + ActiveAttacks[i].windUpTime - network.latency/2000) > os.clock()) then
                        local wpts = GetWaypoints(unit.networkID)
                        if #wpts > 1 then
                            table.remove(ActiveAttacks, i)
                        else
                            i = i + 1
                        end
                    else
                        i = i + 1
                    end
                end
            end
        end
    end 
end


------------ >> Callbacks << -------------
cb.add(cb.tick, OnTick)
cb.add(cb.spell, OnProcessSpell)
cb.add(cb.path, OnNewPath)

print('VPrediction')

return { 
    GetBestCastPosition = GetBestCastPosition, 
    GetCircularAOEPrediction = GetCircularAOEPrediction
}