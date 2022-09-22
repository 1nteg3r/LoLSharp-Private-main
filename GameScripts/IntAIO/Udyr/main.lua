local common = module.load("int", "Library/common")
local preds = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")

local spellE = {
	range = 800
}


local menu = menu("intUdry", "Int Udyr")
menu:header('dddd', 'Core')
menu:menu("combo", "Combo")
menu.combo:dropdown("stance", "Combo Sequence:", 1, {"E and Stance", "E and Agility"})
menu.combo:boolean("qcombo", "Use Q", true)
menu.combo:boolean("wcombo", "Use W", true)
menu.combo:boolean("ecombo", "Use E", true)
menu.combo:boolean("rcombo", "Use R", true)
menu.combo:boolean("items", "Use -> Bilge", true)

menu:menu("farming", "LaneClear")
menu.farming:boolean("farmq", "Use Q", true)
menu.farming:boolean("farmw", "Use W", true)
menu.farming:boolean("farmr", "Use R", true)
menu.farming:boolean("items", "Use -> Bilge", true)

menu:menu("farming1j", "JungleClear")
menu.farming1j:boolean("useq", "Use Q", true)
menu.farming1j:boolean("usew", "Use W", true)
menu.farming1j:boolean("user", "Use R", true)
menu.farming1j:boolean("items", "Use -> Bilge", true)

TS.load_to_menu(menu)
local TargetSelection = function(res, obj, dist)
	if dist < spellE.range then
		res.obj = obj
		return true
	end
end

local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end
local TargetSelectionW = function(res, obj, dist)
	if dist < 270 then
		res.obj = obj
		return true
	end
end

local GetTargetW = function()
	return TS.get_result(TargetSelectionW).obj
end

local function Combo()
	if menu.combo.items:get() then
		local target = GetTarget()
		if target then
			if common.IsValidTarget(target) then
				if (target.pos:dist(player) <= 650) then
					for i = 6, 11 do
						local item = player:spellSlot(i).name

						if item and (item == "ItemSwordOfFeastAndFamine") then
							player:castSpell("obj", i, target)
						end
						if item and (item == "BilgewaterCutlass") then
							player:castSpell("obj", i, target)
						end
					end
				end
			end
		end
	end
	if
		menu.combo.wcombo:get() and 30 >= (player.health / player.maxHealth) * 100 and
			player:spellSlot(1).state == 0
	 then
		local target = GetTargetW()
		if target then
			if common.IsValidTarget(target) then
				player:castSpell("self", 1)
			end
		end
	end
	if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 then
		local target = GetTarget()
		if target then
			if common.IsValidTarget(target) and target.pos:dist(player.pos) > 250 then
				player:castSpell("self", 2)
			--	return meow
			end
		end
	end

	if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 then
		local target = GetTarget()
		if target then
			if
				common.IsValidTarget(target) and
					(common.HasBuffCount(player, "UdyrPhoenixStance") ~= 3 or
						(common.HasBuffCount(player, "UdyrPhoenixStance") == 3 and target.pos:dist(player.pos) > 250)) and
					not target.buff['udyrbearstuncheck']
			 then
				player:castSpell("self", 2)
			--	return meow
			end
		end
	end
	if orb.combat.target then
		if common.IsValidTarget(orb.combat.target) and player.pos:dist(orb.combat.target.pos) < 250 then
			if menu.combo.stance:get() == 1 then
				if menu.combo.ecombo:get() and player:spellSlot(2).state == 0 then
					local target = GetTarget()
					if target then
						if
							common.IsValidTarget(target) and
								(common.HasBuffCount(player, "UdyrPhoenixStance") ~= 3 or
									(common.HasBuffCount(player, "UdyrPhoenixStance") == 3 and target.pos:dist(player.pos) > 250)) and
								not  target.buff['udyrbearstuncheck']
						 then
							player:castSpell("self", 2)
						--	return meow
						end
					end
				end
				local target = GetTargetW()

				if target then
					if orb.core.can_attack() then
						if
							 target.buff['udyrbearstuncheck'] or player:spellSlot(2).level == 0 or
								menu.combo.ecombo:get() == false
						 then
							if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 then
								player:castSpell("self", 3)
								return meow
							end
							if
								(player:spellSlot(3).state ~= 0 or menu.combo.rcombo:get() == false) and
									common.HasBuffCount(player, "UdyrPhoenixStance") ~= 3 or
									player:spellSlot(3).level == 0
							 then
								if menu.combo.wcombo:get() and player:spellSlot(1).state == 0 then
									player:castSpell("self", 1)
									return meow
								end
							end
							if
								(player:spellSlot(1).state ~= 0 or menu.combo.wcombo:get() == false) and
									common.HasBuffCount(player, "UdyrPhoenixStance") ~= 3 or
									player:spellSlot(1).level == 0
							 then
								if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 then
									player:castSpell("self", 0)
									return meow
								end
							end
						end
					end
				end
			end
			if menu.combo.stance:get() == 2 then
				local target = GetTargetW()

				if target then
					if
						 target.buff['udyrbearstuncheck'] or player:spellSlot(2).level == 0 or
							menu.combo.ecombo:get() == false
					 then
						if orb.core.can_attack() then
							if menu.combo.qcombo:get() and player:spellSlot(0).state == 0 then
								player:castSpell("self", 0)
								return meow
							end
							if (player:spellSlot(0).state ~= 0 or menu.combo.qcombo:get() == false) or player:spellSlot(0).level == 0 then
								if menu.combo.rcombo:get() and player:spellSlot(3).state == 0 then
									player:castSpell("self", 3)
									return meow
								end
							end
							if
								(player:spellSlot(3).state ~= 0 or menu.combo.rcombo:get() == false) and
									common.HasBuffCount(player, "UdyrPhoenixStance") ~= 3 or
									player:spellSlot(3).level == 0
							 then
								if menu.combo.wcombo:get() and player:spellSlot(1).state == 0 then
									player:castSpell("self", 1)
									return meow
								end
							end
						end
					end
				end
			end
		end
	end
end
orb.combat.register_f_after_attack(
	function()
		if menu.combo.items:get() and orb.combat.is_active() then
			if orb.combat.target then
				if orb.combat.target and common.IsValidTarget(orb.combat.target) and player.pos:dist(orb.combat.target.pos) < 300 then
					if menu.combo.items:get() then
						for i = 6, 11 do
							local item = player:spellSlot(i).name
							if item and (item == "ItemTitanicHydraCleave" or item == "ItemTiamatCleave") and player:spellSlot(i).state == 0 then
								player:castSpell("obj", i, player)
								player:attack(orb.combat.target)

								return "on_after_attack_hydra"
							end
						end
					end
				end
			end
		end

		orb.combat.set_invoke_after_attack(false)
	end
)
local function JungleClear()
	if orb.core.can_attack() then
		--if menu.farming.stance:get() == 2 then
			for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
				local minion = objManager.minions[TEAM_NEUTRAL][i]
				if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead then
					if menu.farming1j.useq:get() then
						if minion.pos:dist(player.pos) < 300 and player:spellSlot(0).state == 0 then
							player:castSpell("self", 0)
							return meow
						end
					end
					if player:spellSlot(0).state ~= 0 or player:spellSlot(0).level == 0 then
						if minion.pos:dist(player.pos) < 300 then
							if menu.farming1j.user:get() and player:spellSlot(3).state == 0 then
								player:castSpell("self", 3)
								return meow
							end
						end
					end
					if
						player:spellSlot(3).state ~= 0 and common.HasBuffCount(player, "UdyrPhoenixStance") == 1 and
							menu.farming1j.usew:get() or
							player:spellSlot(3).level == 0
					 then
						if minion.pos:dist(player.pos) < 300 and player:spellSlot(1).state == 0 then
							player:castSpell("self", 1)
							return meow
						end
					end
				end
			end
		--end
	end
end

local function LaneClear()
	if orb.core.can_attack() then
		--if menu.farming.stance:get() == 2 then
			for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
				local minion = objManager.minions[TEAM_ENEMY][i]
				if minion and minion.isVisible and minion.moveSpeed > 0 and minion.isTargetable and not minion.isDead then
					if menu.farming.farmq:get() then
						if minion.pos:dist(player.pos) < 300 and player:spellSlot(0).state == 0 then
							player:castSpell("self", 0)
							return meow
						end
					end
					if player:spellSlot(0).state ~= 0 or player:spellSlot(0).level == 0 then
						if minion.pos:dist(player.pos) < 300 then
							if menu.farming.farmr:get() and player:spellSlot(3).state == 0 then
								player:castSpell("self", 3)
								return meow
							end
						end
					end
					if
						player:spellSlot(3).state ~= 0 and common.HasBuffCount(player, "UdyrPhoenixStance") == 1 and
							menu.farming.farmw:get() or
							player:spellSlot(3).level == 0
					 then
						if minion.pos:dist(player.pos) < 300 and player:spellSlot(1).state == 0 then
							player:castSpell("self", 1)
							return meow
						end
					end
				end
			end
		--end
	end
end


local function OnTick()
	if orb.combat.is_active() then
		Combo()
	end
	if (orb.menu.lane_clear:get()) then
		LaneClear()
		JungleClear()
	end
end

orb.combat.register_f_pre_tick(OnTick)