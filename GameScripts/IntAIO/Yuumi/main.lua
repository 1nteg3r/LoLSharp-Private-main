local evade = module.seek("evade")
local predhan = module.internal("pred");
local common = module.load('int', 'Library/common');
local TS = module.load("int", "TargetSelector/targetSelector")

local database = module.load('int', "Core/Yuumi/SpellDatabase")

local YuumiSolo = false;
--[[
    spellthief's edge
    dark seal
    athene's unholy grail
    ardent censer
    redemption
    mikael's crucible
    shurelya's reverie
    dark seal / mejais soulstealer < but this is situational
]]

local igniteDmg = { 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410 } --"50 + (20 * myHero.level)"
local igniteSlot = nil
if player:spellSlot(4).name == "SummonerDot" then
	igniteSlot = 4
elseif player:spellSlot(5).name == "SummonerDot" then
	igniteSlot = 5
else 
	igniteSlot = nil
end


local menu = menu('intyuumi', 'Int Yuumi');
menu:menu("itemo", "Offensive Items")
menu.itemo:menu("ado", "Physical - Items")
        menu.itemo.ado:header("xd", "Bligewater")
        menu.itemo.ado:boolean("bwc", "Use Bligewater Cutlass", true)
        menu.itemo.ado:slider("bwcathp", "Use if Target health {0}", 60, 10, 100, 10)

        menu.itemo.ado:header("xd", "Ruined King")
        menu.itemo.ado:boolean("botrk", "Use Ruined King", true)
        menu.itemo.ado:slider("botrkathp", "Use if Target health {0}", 60, 10, 100, 10)
        menu.itemo.ado:slider("botrkatownhp", "Use if my health {0}", 60, 10, 100, 10)

        menu.itemo.ado:header("xd", "Tiamat")
        menu.itemo.ado:boolean("tiamat", "Use Tiamat/Hydra", true)
        menu.itemo.ado:boolean("titanic", "Use Titanic", true)


    menu.itemo:menu("apo", "Magics - Items")
        menu.itemo.apo:header("xd", "Hextech")
        menu.itemo.apo:boolean("hex", "Use Hextech Gunblade", true)
        menu.itemo.apo:slider("hexathp", "Use if Target health {0}", 60, 10, 100, 10)

        menu.itemo.apo:header("xd", "Bligewater")
        menu.itemo.apo:boolean("bwc", "Use Bligewater Cutlass", true)
        menu.itemo.apo:slider("bwcathp", "Use if Target health {0}", 60, 10, 100, 10)

    

menu:menu("itemd", "Support - Items")
    menu.itemd:header("xd", "Shields")
    menu.itemd:menu("def", "Shield - Items")
        menu.itemd.def:header("xd", "Zhonya")
        menu.itemd.def:boolean("zhonya", "Use Zhonya", true)
        menu.itemd.def:slider("itemhp", "Use Zhonyas if Health {0} <=", 20, 0, 100, 10)

        menu.itemd.def:header("xd", "Seraphs Embrace")
        menu.itemd.def:boolean("seraph", "Use Seraphs Embrace", true)
        menu.itemd.def:slider("seraphx", "Use Seraph if Health {0} <=", 20, 0, 100, 10)

        menu.itemd.def:header("xd", "Face Of Mountain")
        menu.itemd.def:boolean("bomb", "Use Face Of Mountain", true)
        menu.itemd.def:slider("bombx", "Use FoM if Health {0} <=", 20, 0, 100, 10)

        menu.itemd.def:header("xd", "Thresh Lantern")
        menu.itemd.def:boolean("tl", "Grab Lantern", true)

        menu.itemd.def:header("xd", "Gargoyle Stoneplate")
        menu.itemd.def:boolean("gs", "Use Stoneplate", true)
        menu.itemd.def:slider("gsx", "Use Stoneplate if Health {0} <=", 10, 0, 100, 10)
        menu.itemd.def:slider("gsx2", "Enemys Near: ", 1, 0, 5, 1)

				
		menu.itemd:header("xd", "Mikael's Crucible")
		menu.itemd:menu("mikaBF", "Mikeals Buff")
			menu.itemd.mikaBF:boolean("silcenM", "Silence: ", false)
			menu.itemd.mikaBF:boolean("supM", "Suppression: ", true)
			menu.itemd.mikaBF:boolean("rootM", "Root: ", true)
			menu.itemd.mikaBF:boolean("tauntM", "Taunt: ", true)
			menu.itemd.mikaBF:boolean("sleepM", "Sleep:", true)
			menu.itemd.mikaBF:boolean("stunM", "Stun: ", true)
			menu.itemd.mikaBF:boolean("blindM", "Blind: ", false)
			menu.itemd.mikaBF:boolean("fearM", "Fear: ", true)
			menu.itemd.mikaBF:boolean("charmM", "Charm: ", true)
			menu.itemd.mikaBF:boolean("knockM", "Knockback or Knockup", false)
	
local enemy = common.GetAllyHeroes()
for i, allies in ipairs(enemy) do
	if
		allies.charName ~= "Yuumi" and allies.charName ~= "Twitch" and allies.charName ~= "KogMaw" and
			allies.charName ~= "Tristana" and
			allies.charName ~= "Ashe" and
			allies.charName ~= "Vayne" and
			allies.charName ~= "Varus" and
			allies.charName ~= "Xayah" and
			allies.charName ~= "Lucian" and
			allies.charName ~= "Sivir" and
			allies.charName ~= "Draven" and
			allies.charName ~= "Kalista" and
			allies.charName ~= "Caitlyn" and
			allies.charName ~= "Jinx" and
			allies.charName ~= "Ezreal"
	 then
		menu:slider(allies.charName, "Priority: " .. allies.charName, 0, 0, 5, 1)
	end
	if
		allies.charName == "Twitch" or allies.charName == "KogMaw" or allies.charName == "Tristana" or
			allies.charName == "Ashe" or
			allies.charName == "Vayne" or
			allies.charName == "Varus" or
			allies.charName == "Xayah" or
			allies.charName == "Lucian" or
			allies.charName == "Sivir" or
			allies.charName == "Draven" or
			allies.charName == "Kalista" or
			allies.charName == "Caitlyn" or
			allies.charName == "Jinx" or
			allies.charName == "Ezreal"
	 then
		menu:slider(allies.charName, "Priority: " .. allies.charName, 1, 0, 5, 1)
    end
    menu:slider(allies.charName, "Use E if X HP: " .. allies.charName, 30, 1, 100, 1)
end

local PSpells = {
	"CaitlynHeadshotMissile",
	"RumbleOverheatAttack",
	"JarvanIVMartialCadenceAttack",
	"ShenKiAttack",
	"MasterYiDoubleStrike",
	"sonahymnofvalorattackupgrade",
	"sonaariaofperseveranceupgrade",
	"sonasongofdiscordattackupgrade",
	"NocturneUmbraBladesAttack",
	"NautilusRavageStrikeAttack",
	"ZiggsPassiveAttack",
	"QuinnWEnhanced",
	"LucianPassiveAttack",
	"SkarnerPassiveAttack",
	"KarthusDeathDefiedBuff",
	"GarenQAttack",
	"KennenMegaProc",
	"MordekaiserQAttack",
	"MordekaiserQAttack2",
	"BlueCardPreAttack",
	"RedCardPreAttack",
	"GoldCardPreAttack",
	"XenZhaoThrust",
	"XenZhaoThrust2",
	"XenZhaoThrust3",
	"ViktorQBuff",
	"TrundleQ",
	"RenektonSuperExecute",
	"RenektonExecute",
	"GarenSlash2",
	"frostarrow",
	"SivirWAttack",
	"rengarnewpassivebuffdash",
	"YorickQAttack",
	"ViEAttack",
	"SejuaniBasicAttackW",
	"ShyvanaDoubleAttackHit",
	"ShenQAttack",
	"SonaEAttackUpgrade",
	"SonaWAttackUpgrade",
	"SonaQAttackUpgrade",
	"PoppyPassiveAttack",
	"NidaleeTakedownAttack",
	"NasusQAttack",
	"KindredBasicAttackOverrideLightbombFinal",
	"LeonaShieldOfDaybreakAttack",
	"KassadinBasicAttack3",
	"JhinPassiveAttack",
	"JayceHyperChargeRangedAttack",
	"JaycePassiveRangedAttack",
	"JaycePassiveMeleeAttack",
	"illaoiwattack",
	"hecarimrampattack",
	"DrunkenRage",
	"GalioPassiveAttack",
	"FizzWBasicAttack",
	"FioraEAttack",
	"EkkoEAttack",
	"ekkobasicattackp3",
	"MasochismAttack",
	"DravenSpinningAttack",
	"DianaBasicAttack3",
	"DariusNoxianTacticsONHAttack",
	"CamilleQAttackEmpowered",
	"CamilleQAttack",
	"PowerFistAttack",
	"AsheQAttack",
	"jinxqattack",
	"jinxqattack2",
	"KogMawBioArcaneBarrage"
}

local function PrioritizedAllyLow()
	local heroTarget = nil
	for i = 0, objManager.allies_n - 1 do
		local hero = objManager.allies[i]
		if not player.isRecalling then
			if hero.team == TEAM_ALLY and not hero.isDead and hero.pos:dist(player.pos) <= 700 then
				if heroTarget == nil then
					heroTarget = hero
				elseif (hero.health / hero.maxHealth) * 100 < (heroTarget.health / heroTarget.maxHealth) * 100 then
					heroTarget = hero
				end
			end
		end
	end
	return heroTarget
end

local healSlot = nil
if player:spellSlot(4).name == "SummonerHeal" then
	healSlot = 4
elseif player:spellSlot(5).name == "SummonerHeal" then
	healSlot = 5
else 
	healSlot = nil
end


local function PrioritizedAllyW()
	local heroTarget = nil
	for i = 0, objManager.allies_n - 1 do
		local hero = objManager.allies[i]
		if not player.isRecalling then
			if
                hero.team == TEAM_ALLY and not hero.isDead and menu[hero.charName]:get() > 0 
			 then
				if heroTarget == nil then
					heroTarget = hero
				elseif menu[hero.charName]:get() < menu[heroTarget.charName]:get() then
					heroTarget = hero
				end
			end
		end
	end
	return heroTarget
end

local function Mikaels() --do print/opt
    local mikafriend = common.GetAllyHeroesInRange(700)
    for _, allies in ipairs(mikafriend) do
        if allies and not allies.isDead and allies.pos:dist(player.pos) < 700 and #common.GetEnemyHeroesInRange(1000, allies) >= 1 then
			if (menu.itemd.mikaBF.stunM:get() and allies.buff[5]) or (menu.itemd.mikaBF.rootM:get() and allies.buff[11]) or (menu.itemd.mikaBF.silcenM:get() and allies.buff[7]) or (menu.itemd.mikaBF.tauntM:get() and allies.buff[8]) or (menu.itemd.mikaBF.supM:get() and allies.buff[24]) or (menu.itemd.mikaBF.sleepM:get() and allies.buff[18]) or (menu.itemd.mikaBF.charmM:get() and allies.buff[22]) or (menu.itemd.mikaBF.fearM:get() and allies.buff[28]) or (menu.itemd.mikaBF.knockM:get() and allies.buff[29]) then
				for i = 6, 11 do
					local item = player:spellSlot(i).name
					if item == "MorellosBane" or item == "ItemMorellosBane" and player:spellSlot(i).state == 0 then
						common.DelayAction(function() player:castSpell("obj", i, allies) end, 0.2)
					end	
				end	
            end
        end   
	end	
end


local function OnTick()
    if player.isDead then return end 

    if player:spellSlot(1).name == 'YuumiWEndWrapper' then 
        YuumiSolo = true;
    else 
        YuumiSolo = false;
    end

    Mikaels();

    local mikafriend = common.GetAllyHeroesInRange(700)
    for _, allies in ipairs(mikafriend) do
        if allies and not allies.isDead and allies.pos:dist(player.pos) < 700 and #common.GetEnemyHeroesInRange(1000, allies) >= 1 then
            if (menu.itemd.mikaBF.stunM:get() and allies.buff[5]) or (menu.itemd.mikaBF.rootM:get() and allies.buff[11]) or (menu.itemd.mikaBF.silcenM:get() and allies.buff[7]) or (menu.itemd.mikaBF.tauntM:get() and allies.buff[8]) or (menu.itemd.mikaBF.supM:get() and allies.buff[24]) or (menu.itemd.mikaBF.sleepM:get() and allies.buff[18]) or (menu.itemd.mikaBF.charmM:get() and allies.buff[22]) or (menu.itemd.mikaBF.fearM:get() and allies.buff[28]) or (menu.itemd.mikaBF.knockM:get() and allies.buff[29]) then
                if YuumiSolo then
                    player:castSpell("obj", 2, allies)
                end
            end 
        end 
    end 

    if not player.isDead and healSlot and player:spellSlot(healSlot).state == 0 then
		for i = 0, objManager.allies_n - 1 do
			local ally = objManager.allies[i]
			if #common.GetAllyHeroesInRange(850, player.pos) > 0 then
				--print("xd2")
				if ally.pos:dist(player.pos) < 850 and #common.GetEnemyHeroesInRange(800, ally) >= 1 and common.GetPercentHealth(ally) <=15 then
					player:castSpell("self", healSlot)
				end
			end
		end
    end
    local RedFriend = common.GetAllyHeroesInRange(5500)
    local redPred = {delay = 2.5, radius = 550, speed = math.huge, boundingRadiusMod = 0, range = 5500}
	for i=1, #RedFriend do
		local RF = RedFriend[i]
		if RF and not RF.isDead and common.GetPercentHealth(RF) < 30 and #common.GetEnemyHeroesInRange(700, RF) >= 1 then
			for i = 6, 11 do
				local item = player:spellSlot(i).name
				if item == "Redemption" or item == "ItemRedemption" and player:spellSlot(i).state == 0 then
					local seg = predhan.circular.get_prediction(redPred, RF)
					if seg and seg.startPos:dist(seg.endPos) < 5500 then
						player:castSpell("pos", i, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))		
					end
				end
			end
		end
    end

    for _, allies in ipairs(mikafriend) do
        if allies and not allies.isDead and allies.pos:dist(player.pos) < 700 and #common.GetEnemyHeroesInRange(1000, allies) >= 1 then
            if common.GetPercentHealth(allies) < 30 then 

                if not YuumiSolo then 
                    player:castSpell("obj", 1, allies)
                elseif YuumiSolo then
                    player:castSpell("obj", 2, allies)
                end
            end
        end 
    end

    if (PrioritizedAllyLow()) then 
        if not YuumiSolo then 
            player:castSpell("obj", 1, PrioritizedAllyLow())
        elseif YuumiSolo and PrioritizedAllyLow() and PrioritizedAllyLow() ~= PrioritizedAllyLow() and #common.GetAllyHeroesInRange(1000, player.pos) >= 2 then 
            player:castSpell("self", 1)
            
            player:castSpell("obj", 1, PrioritizedAllyLow())
        end
    end 

    if PrioritizedAllyW() then 
        player:interact(PrioritizedAllyW())
    end


    if YuumiSolo then 
        local enemies = common.GetEnemyHeroes()
        local qPred = { delay = 0.25, width = 240, speed = 1700, boundingRadiusMod = 1, collision = { hero = false, minion = false, wall = false } }
        for _, aaaaaaaaaa in ipairs(enemies) do
            if #common.GetEnemyHeroesInRange(1000, player.pos) >= 2 and aaaaaaaaaa.pos:dist(player.pos) < 700 then
                local seg = predhan.linear.get_prediction(qPred, aaaaaaaaaa)
	               if seg and seg.startPos:dist(seg.endPos) < 1150 then
                    player:castSpell("pos",3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
                   end
            end
        end
    end

    if not player.isDead then 
		for i = 0, objManager.enemies_n - 1 do
			local enemy = objManager.enemies[i]
			if common.GetPercentHealth(enemy) < 15 then
		        if common.IsValidTarget(enemy) and player.path.serverPos:dist(enemy.path.serverPos) <= 600 and player.path.serverPos:dist(enemy.path.serverPos) >= 500 then
		            if igniteSlot and player:spellSlot(igniteSlot).state == 0 and igniteDmg[player.levelRef] > enemy.health then player:castSpell("obj", igniteSlot, enemy) end
		        elseif common.IsValidTarget(enemy) and player.path.serverPos:dist(enemy.path.serverPos) <= 500 and player.path.serverPos:dist(enemy.path.serverPos) >= 200 then
		        	if igniteSlot and player:spellSlot(igniteSlot).state == 0 and igniteDmg[player.levelRef] + 40 > enemy.health then player:castSpell("obj", igniteSlot, enemy) end
		        end
		    end
	    end
    end
    --buy item 
--[[    if player.gold == 400 or player.gold >= 400 then
        player:buyItem(3850)
    end

    if player.gold >= 800 then
        player:buyItem(3114)
    elseif player.gold < 800 then 
        player:buyItem(1004)
    end

    for i = 0, 7 do
        local item = player:itemID(i)
        print(item)
    end]]

    if not player.isRecalling then 
        --if menu.SpellsMenu.enable:get() then
            for i = 1, #evade.core.active_spells do
                local spell = evade.core.active_spells[i]
                --if menu.SpellsMenu.priority:get() then
                    local allies = common.GetAllyHeroes()
                    for z, ally in ipairs(allies) do
                        if ally and ally.pos:dist(player.pos) <= 1000 and ally ~= player then
                            if YuumiSolo then
                                if (spell.polygon and spell.polygon:Contains(ally.path.serverPos) ~= 0) then
                                    allow = false
                                else
                                    allow = true
                                end

                                if spell.data.spell_type == "Target" and spell.target == ally and spell.owner.type == TYPE_HERO then
                                    if not spell.name:find("crit") then
                                        if not spell.name:find("basicattack") then
                                            if YuumiSolo then
                                                if ally.pos:dist(player.pos) <= 1000 then
                                                    player:castSpell("obj", 2, ally)
                                                end
                                            end
                                        end
                                    end
                                elseif
                                    spell.polygon and spell.polygon:Contains(ally.path.serverPos) ~= 0 and
                                        (not spell.data.collision or #spell.data.collision == 0)
                                 then
                                    for _, k in pairs(database) do
                                        if YuumiSolo then
                                            if
                                                spell.name:find(_:lower()) and 30 >= (ally.health / ally.maxHealth) * 100 and YuumiSolo
                                             then
                                                if ally.pos:dist(player.pos) <= 1000 then
                                                    if ally ~= player then
                                                        if spell.missile then
                                                            if (ally.pos:dist(spell.missile.pos) / spell.data.speed < network.latency + 0.35) then
                                                                if ally.pos:dist(player.pos) <= 1000 then
                                                                    player:castSpell("obj", 2, ally)
                                                                end
                                                            end
                                                        end
                                                        if spell.name:find(_:lower()) then
                                                            if k.speeds == math.huge or spell.data.spell_type == "Circular" then
                                                                if ally.pos:dist(player.pos) <= 1000 then
                                                                    player:castSpell("obj", 2, ally)
                                                                end
                                                            end
                                                        end
                                                        if spell.data.speed == math.huge or spell.data.spell_type == "Circular" then
                                                            if ally.pos:dist(player.pos) <= 1000 then
                                                                player:castSpell("obj", 2, ally)
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    for z, ally in ipairs(allies) do
                        if ally and ally == player and allow then
                            if YuumiSolo then
                                if spell.data.spell_type == "Target" and spell.target == ally and spell.owner.type == TYPE_HERO then
                                    if not spell.name:find("crit") then
                                        if not spell.name:find("basicattack") then
                                            if YuumiSolo then
                                                if ally.pos:dist(player.pos) <= 1000 then
                                                    player:castSpell("obj", 2, ally)
                                                end
                                            end
                                        end
                                    end
                                elseif
                                    spell.polygon and spell.polygon:Contains(player.path.serverPos) ~= 0 and
                                        (not spell.data.collision or #spell.data.collision == 0)
                                 then
                                    for _, k in pairs(database) do
                                        if ally == player then
                                            if YuumiSolo then
                                                if
                                                    spell.name:find(_:lower()) and 40 >= (player.health / player.maxHealth) * 100 and YuumiSolo
                                                 then
                                                    if player.pos:dist(player.pos) <= 1000 then
                                                        if spell.missile then
                                                            if (player.pos:dist(spell.missile.pos) / spell.data.speed < network.latency + 0.35) then
                                                                player:castSpell("obj", 2, player)
                                                            end
                                                        end
                                                        if spell.name:find(_:lower()) then
                                                            if k.speeds == math.huge or spell.data.spell_type == "Circular" then
                                                                player:castSpell("obj", 2, player)
                                                            end
                                                        end
                                                        if spell.data.speed == math.huge or spell.data.spell_type == "Circular" then
                                                            player:castSpell("obj", 2, player)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                --end

                --if not menu.SpellsMenu.priority:get() then
                    local allies = common.GetAllyHeroes()
                    for z, ally in ipairs(allies) do
                        if ally then
                            if YuumiSolo then
                                if spell.data.spell_type == "Target" and spell.target == ally and spell.owner.type == TYPE_HERO then
                                    if not spell.name:find("crit") then
                                        if not spell.name:find("basicattack") then
                                            if YuumiSolo then
                                                if ally.pos:dist(player.pos) <= 1000 then
                                                    player:castSpell("obj", 2, ally)
                                                end
                                            end
                                        end
                                    end
                                elseif
                                    spell.polygon and spell.polygon:Contains(ally.path.serverPos) ~= 0 and
                                        (not spell.data.collision or #spell.data.collision == 0)
                                 then
                                    for _, k in pairs(database) do
                                        if
                                            spell.name:find(_:lower()) and 30 >= (ally.health / ally.maxHealth) * 100 and YuumiSolo
                                         then
                                            if ally.pos:dist(player.pos) <= 1000 then
                                                if spell.missile then
                                                    if (ally.pos:dist(spell.missile.pos) / spell.data.speed < network.latency + 0.35) then
                                                        if ally.pos:dist(player.pos) <= 1000 then
                                                            player:castSpell("obj", 2, ally)
                                                        end
                                                    end
                                                end
                                                if spell.name:find(_:lower()) then
                                                    if k.speeds == math.huge or spell.data.spell_type == "Circular" then
                                                        if ally.pos:dist(player.pos) <= 1000 then
                                                            player:castSpell("obj", 2, ally)
                                                        end
                                                    end
                                                end
                                                if spell.data.speed == math.huge or spell.data.spell_type == "Circular" then
                                                    if ally.pos:dist(player.pos) <= 1000 then
                                                        player:castSpell("obj", 2, ally)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                --end
            end
        --end
    end
end 

local function on_spell(spell)
    local heroTarget = nil
	if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY and spell.target == TYPE_HERO then
		for i = 1, #PSpells do
			if
				 spell.owner.pos:dist(player.pos) <= 1000 and
					menu[spell.owner.charName]:get() > 0
			 then
				if heroTarget == nil then
					heroTarget = spell.owner
				elseif
					menu[spell.owner.charName]:get() < menu[heroTarget.charName]:get()
				 then
					heroTarget = spell.owner
				end
				if (heroTarget) then
                    if not YuumiSolo then 
                        player:castSpell("obj", 1, heroTarget)
                    elseif YuumiSolo then
                        player:castSpell("obj", 2, heroTarget)
                    end
				end
			end
		end
		if
			spell.name:find("BasicAttack") and spell.owner.pos:dist(player.pos) <= 1000 and
				menu[spell.owner.charName]:get() > 0
		 then
			if heroTarget == nil then
				heroTarget = spell.owner
			elseif menu[spell.owner.charName]:get() < menu[heroTarget.charName]:get() then
				heroTarget = spell.owner
			end
			if (heroTarget) then
                if not YuumiSolo then 
                    player:castSpell("obj", 1, heroTarget)
                elseif YuumiSolo then
                    player:castSpell("obj", 2, heroTarget)
                end
            end
		end
	end
	if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ALLY then
		if
			spell.name:find("KogMawBioArcaneBarrage") and spell.owner.pos:dist(player.pos) <= 1000 and
				menu[spell.owner.charName]:get() > 0
		 then
			if heroTarget == nil then
				heroTarget = spell.owner
			elseif menu[spell.owner.charName]:get() < menu[heroTarget.charName]:get() then
				heroTarget = spell.owner
			end
			if (heroTarget) then
                if not YuumiSolo then 
                    player:castSpell("obj", 1, heroTarget)
                elseif YuumiSolo then
                    player:castSpell("obj", 2, heroTarget)
                end
            end
		end
	end

	--if menu.SpellsMenu.targeteteteteteed:get() then
		local allies = common.GetAllyHeroes()
		for z, ally in ipairs(allies) do
			if ally then
				--if menu.SpellsMenu.blacklist[ally.charName] and not YuumiSolo then
					if spell and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.target == ally then
						if not spell.name:find("crit") then
							if not spell.name:find("BasicAttack") then
								--if menu.SpellsMenu.targeteteteteteed:get() then
									if ally.pos:dist(player.pos) <= 1000 then
										if (player.mana / player.maxMana) * 100 >= 25 and YuumiSolo then
											player:castSpell("obj", 2, ally)

											if YuumiSolo then
												if ally.pos:dist(player.pos) <= 1000 then
													player:castSpell("obj", 2, ally)
												end
											end
										end
									end
								--end
							end
						end
					end
				--end
			end
		end
	--end
	--if menu.SpellsMenu.BasicAttack.aa:get() then
		local allies = common.GetAllyHeroes()
		for z, ally in ipairs(allies) do
			if ally and ally.pos:dist(player.pos) <= 1000 then
				if ally and ally.pos:dist(player.pos) <= 1000 then
					if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.target == ally then
						for i = 1, #PSpells do
							if spell.name:lower():find(PSpells[i]:lower()) then
								if (ally.health / ally.maxHealth) * 100 <= 30 then
									if YuumiSolo then
										if ally.pos:dist(player.pos) <= 1000 then
											if (player.mana / player.maxMana) * 100 >= 25 then
												player:castSpell("obj", 2, ally)
											end
										end
										
                                    elseif not YuumiSolo then 
                                        if ally.pos:dist(player.pos) <= 900 then
                                            player:castSpell("obj", 1, ally)
                                        end 
                                    end
								end
							end
						end
						if spell.name:find("BasicAttack") then
							if (ally.health / ally.maxHealth) * 100 <= 30 then
								if YuumiSolo then
									if ally.pos:dist(player.pos) <= 1000 then
										if (player.mana / player.maxMana) * 100 >= 25 then
											player:castSpell("obj", 2, ally)
										end
									end
                                elseif not YuumiSolo then 
                                    if ally.pos:dist(player.pos) <= 900 then
                                        player:castSpell("obj", 1, ally)
                                    end 
                                end
							end
						end
					end
				end
			end
		end
	--end
	--if menu.SpellsMenu.BasicAttack.critaa:get() then
		local allies = common.GetAllyHeroes()
		for z, ally in ipairs(allies) do
			if ally and ally.pos:dist(player.pos) <= 1000 then
				if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and spell.target == ally then
					if spell.name:find("crit") then
						if (ally.health / ally.maxHealth) * 100 <= 60 then
							if YuumiSolo then
								if ally.pos:dist(player.pos) <= 1000 then
									if (player.mana / player.maxMana) * 100 >= 25 then
										player:castSpell("obj", 2, ally)
									end
								end
                            elseif not YuumiSolo then 
                                if ally.pos:dist(player.pos) <= 900 then
                                    player:castSpell("obj", 1, ally)
                                end 
                            end
						end
					end
				end
			end
		end
	--end
	--if menu.SpellsMenu.BasicAttack.minionaa:get() then
		local allies = common.GetAllyHeroes()
		for z, ally in ipairs(allies) do
			if ally and ally.pos:dist(player.pos) <= 1000 then
				if spell.owner.type == TYPE_MINION and spell.owner.team == TEAM_ENEMY and spell.target == ally then
					if (ally.health / ally.maxHealth) * 100 <= 10 then
						if YuumiSolo then
							if ally.pos:dist(player.pos) <= 1000 then
								if (player.mana / player.maxMana) * 100 >= 25 then
									player:castSpell("obj", 2, ally)
								end
							end
                        elseif not YuumiSolo then 
                            if ally.pos:dist(player.pos) <= 900 then
                                player:castSpell("obj", 1, ally)
                            end 
                        end
					end
				end
			end
		end
	--end
	--if menu.SpellsMenu.BasicAttack.turret:get() then
		local allies = common.GetAllyHeroes()
		for z, ally in ipairs(allies) do
			if ally and ally.pos:dist(player.pos) <= 1000 then
				if spell.owner.type == TYPE_TURRET and spell.owner.team == TEAM_ENEMY and spell.target == ally then
					if YuumiSolo then
						if ally.pos:dist(player.pos) <= 1000 then
							if (player.mana / player.maxMana) * 100 >= 25 then
								player:castSpell("obj", 2, ally)
							end
						end
                    elseif not YuumiSolo then 
                        if ally.pos:dist(player.pos) <= 900 then
                            player:castSpell("obj", 1, ally)
                        end 
                    end
				end
			end
		end
	--end
end

function CountAllysInRange(range)
	local range, count = range*range, 0 
	for i = 0, objManager.allies_n - 1 do
		if player.pos:distSqr(objManager.allies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end

function CountEnemyHeroInRange(range)
	local range, count = range*range, 0 
	for i = 0, objManager.enemies_n - 1 do
		if player.pos:distSqr(objManager.enemies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end
cb.add(cb.spell, on_spell)
cb.add(cb.tick, OnTick)
