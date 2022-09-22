local t_selector = module.load(header.id, "TargetSelector/targetSelector")

local menu = menu("IntnnerZoe", "Intnner - Zoe");

local TS = t_selector(menu, 1425, 2)
TS:addToMenu()

local GAPCLOSER_SPELLS = {
    'AatroxQ',
	'RenektonE',
    'AkaliR',
    'AkaliRb',
	'YasuoDashWrapper',
    'Headbutt',
    'FioraQ',
	'FizzQ',
    'DianaTeleport',
    'EliseSpiderQCast',
    'FizzPiercingStrike',
    'GragasE',
    "EkkoE",
    "Pounce",
    "GalioE",
    "GnarE",
    'HecarimUlt',
	'HecarimRamp',
    'IreliaQ',
    'JaxLeapStrike',
	'XinZhaoE',
	'XenZhaoE',
    'LeblancW',
    'LeblancRW',
    "CamilleE",
    "OrnnE",
    'BlindMonkQOne',
	'JayceShockBlast',
    'LeonaZenithBlade',
    'UFSlash',
    'Pantheon_LeapBash',
    'PoppyHeroicCharge',
    'RenektonSliceAndDice',
    'RivenTriCleave',
    'SejuaniQ',
    'slashCast',
    'ViQ',
    "ShenE",
    "TalonQ",
    "TristanaW",
    "TryndamereE",
    "UrgotE",
    "ZacE",
    'MonkeyKingNimbus',
    "WarwickR",
    "PykeE",
    "RiftWalk",
    'XenZhaoSweep',
    'YasuoDashWrapper'
}
	
local Contain=function(table, value)
	for _, v in pairs(table) do
		if (v == value) then
			return true
		end
	end
	return false
end

menu:header('core', "Core")

menu:menu("combo", "Combat - Settings")
menu.combo:boolean('q' , 'Use Q', true)
menu.combo:boolean('w' , 'Use W', true)
menu.combo:boolean('e' , 'Use E', true)
menu.combo:boolean('e_isWall' , '^~ Use Wall', true)
menu.combo:boolean('r' , 'Use R', true)

menu:menu("harass", "Harass - Settings")
menu.harass:boolean('q' , 'Use Q', true)
menu.harass:boolean('w' , 'Use W', false)
menu.harass:boolean('e' , 'Use E', false)
menu.harass:slider('minimana', 'Min. Harass >= {0}:', 65 , 0 , 100 , 1 )

menu:menu('misc' ,  'Misc - Settings')
menu.misc:boolean('q' , 'KillSteal with Q', true)
menu.misc:boolean('e' , 'KillSteal with E', true)

menu.misc:header('ap5',  "Gabcloser - Settings")
menu.misc:boolean('Enable', 'Use E - Gabcloser', true)
for i = 0, objManager.enemies_n - 1 do
	local obj = objManager.enemies[i]
	local Qname = obj:spellSlot(0).name
	local Wname = obj:spellSlot(1).name
	local Ename = obj:spellSlot(2).name
	local Rname = obj:spellSlot(3).name
	
	if (Contain(GAPCLOSER_SPELLS, Qname)) then
		menu.misc:boolean(Qname, obj.charName..'(Q)', true)
		elseif Qname=='JayceShockBlast' then
		menu.misc:boolean('JayceToTheSkies', obj.charName..'(Q2)', true)
	end
	if (Contain(GAPCLOSER_SPELLS, Wname)) then
		menu.misc:boolean(Wname, obj.charName..'(W)', true)
		
	end
	if (Contain(GAPCLOSER_SPELLS, Ename)) and Ename~='HecarimRamp' then
		menu.misc:boolean(Ename, obj.charName..'(E)', true)
	elseif Ename=='HecarimRamp' then
		menu.misc:boolean('HecarimRampAttack', obj.charName..'(E)', true)
	elseif Ename=='KhazixELong' or Ename=='KhazixE' then
		menu.misc:boolean('KhazixE', obj.charName..'(E)', true)
		menu.misc:boolean('KhazixELong', obj.charName..'(E)', true)
	end
	if (Contain(GAPCLOSER_SPELLS, Rname)) then
		menu.misc:boolean(Rname, obj.charName..'(R)', true)
	end
end
menu.misc:header('ap4d',  "Flee - Settings")
menu.misc:keybind('flee', 'Flee', 'Z', nil)
menu.misc:boolean('useE' , 'Sleepy Trouble Bubble - (E)', true)

menu:menu('display' ,  'Drawings - Settings')
menu.display:boolean('Q','Draw Q Range', true)
menu.display:boolean('E','Draw E Range', false)
menu.display:boolean('R','Draw R Range', false)

return {
    menu = menu, 
    TS = TS
}