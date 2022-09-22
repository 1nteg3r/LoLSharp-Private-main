--Variables
local common = module.load('int', 'Library/common');
local Variables = module.load('int', 'Core/Yasuo/Variables')
local DashingManager = module.load('int', 'Core/Yasuo/DashingManager');

local spotsWalls ={
    {FromPlayer = vec2(11070, 6908)},
    {FromPlayer = vec2(2232, 8412)},
    {FromPlayer = vec2(7046, 5426)},
    {FromPlayer = vec2(7046, 5426)},
    {FromPlayer = vec2(6830, 55000)},
    {FromPlayer = vec2(8322, 2658)},
    {FromPlayer = vec2(3892, 6466)},
    {FromPlayer = vec2(12582, 6402)},
    {FromPlayer = vec2(11072, 8306)},
    {FromPlayer = vec2(10882, 8416)},
    {FromPlayer = vec2(6574, 12256)},
    {FromPlayer = vec2(7760, 9500)},
} 


local JumpSpots = {

       
            {From = vec3(7372, 52.565307617188, 5858),  To = vec3(7372, 52.565307617188, 5858), CastPos = vec3(7110, 58.387092590332, 5612)}, 
            {From = vec3(8222, 51.648384094238, 3158),  To = vec3(8222, 51.648384094238, 3158), CastPos = vec3(8372, 51.130004882813, 2908)}, 
            {From = vec3(3674, 50.331886291504, 7058),  To = vec3(3674, 50.331886291504, 7058), CastPos = vec3(3674, 52.459594726563, 6708)}, 
           
            {From = vec3(8372, 50.384059906006, 9606),  To = vec3(8372, 50.384059906006, 9606), CastPos = vec3(7923, 53.530361175537, 9351)}, 
            {From = vec3(6650, 53.829689025879, 11766),  To = vec3(6650, 53.829689025879, 11766), CastPos = vec3(6426, 56.47679901123, 12138)}, 
            {From = vec3(1678, 52.838096618652, 8428),  To = vec3(1678, 52.838096618652, 8428), CastPos = vec3(2050, 51.777256011963, 8416)}, 
            {From = vec3(10822, 52.152740478516, 7456),  To = vec3(10822, 52.152740478516, 7456), CastPos = vec3(10894, 51.722988128662, 7192)},
            {From = vec3(11160, 52.205154418945, 7504),  To = vec3(11160, 52.205154418945, 7504), CastPos = vec3(11172, 51.725219726563, 7208)},	
            {From = vec3(6424, 48.527244567871, 5208),  To = vec3(6424, 48.527244567871, 5208), CastPos = vec3(6824, 48.720901489258, 5308)},
            {From = vec3(13172, 54.201187133789, 6508),  To = vec3(13172, 54.201187133789, 6508), CastPos = vec3(12772, 51.666019439697, 6458)}, 
            {From = vec3(11222, 52.210571289063, 7856),  To = vec3(11222, 52.210571289063, 7856), CastPos = vec3(11072, 62.272243499756, 8156)}, 
            {From = vec3(10372, 61.73225402832, 8456),  To = vec3(10372, 61.73225402832, 8456), CastPos = vec3(10772, 63.136688232422, 8456)},
            {From = vec3(4324, 51.543388366699, 6258),  To = vec3(4324, 51.543388366699, 6258), CastPos = vec3(4024, 52.466369628906, 6358)},
            {From = vec3(6488, 56.632884979248, 11192),  To = vec3(6488, 56.632884979248, 11192), CastPos = vec3(66986, 53.771095275879, 10910)},
            {From = vec3(7672, 52.87260055542, 8906),  To = vec3(7672, 52.87260055542, 8906), CastPos = vec3(7822, 52.446697235107, 9306)},
    
    
}

local LastMoveC = 0

local function MoveToLimited(where)
    if (os.clock() - LastMoveC < 80) then return end
    LastMoveC = os.clock();
    player:move(where)
end

local function WallDash()
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
        local jungle = objManager.minions[TEAM_NEUTRAL][i]
        if jungle then
            local PosTo = vec3(player.x, player.y, player.z)
            local stopMove = false
            local Spots = JumpSpots
            if Spots then
                for i, spot in ipairs(Spots) do
                    if common.GetDistanceSqr(spot.From, mousePos) < 300*300 then
                        local stopMove = true 
                        if common.GetDistanceSqr(spot.From, PosTo) > 250*250 then
                            player:move(mousePos)
                        elseif common.GetDistanceSqr(spot.From, PosTo) < 250*250 then
                            --player:move(navmesh.isWall(spot.From))
                            player:move(spot.From)
                        end 
                        if common.GetDistanceSqr(spot.From, PosTo) < 25*25 then
                            if player:spellSlot(1).state == 0 and not (jungle.isVisible) then
                                player:castSpell("pos", 1, spot.CastPos)
                            end
                            if jungle ~= nil and common.GetDistance(jungle) <= 475 and player:spellSlot(2).state == 0 then
                                player:castSpell("obj", 2, jungle)
                                for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
                                    local minion = objManager.minions[TEAM_ENEMY][i]
                                    if minion and common.IsValidTarget(minion) and common.GetDistance(minion) <= 475 then
                                        player:castSpell("obj", 2, minion)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local PosTo = vec3(player.x, player.y, player.z)
            local stopMove = false
            local Spots = spotsWalls
            if Spots then
                for i, spot in ipairs(Spots) do
                    if common.GetDistanceSqr(spot.FromPlayer:to3D(), mousePos) < 300*300 then
                        local stopMove = true 
                        if common.GetDistanceSqr(spot.FromPlayer:to3D(), PosTo) > 250*250 then
                            player:move(mousePos)
                        elseif common.GetDistanceSqr(spot.FromPlayer:to3D(), PosTo) < 250*250 then
                            --player:move(navmesh.isWall(spot.From))
                            player:move(spot.FromPlayer:to3D())
                        end 
                        if common.GetDistanceSqr(spot.FromPlayer:to3D(), PosTo) < 25*25 then
                            if jungle ~= nil and common.GetDistance(jungle) <= 475 and player:spellSlot(2).state == 0 then
                                player:castSpell("obj", 2, jungle)
                                for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
                                    local minion = objManager.minions[TEAM_ENEMY][i]
                                    if minion and common.IsValidTarget(minion) and common.GetDistance(minion) <= 475 then
                                        player:castSpell("obj", 2, minion)
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

return {
    spotA = spotA,
    spotB = spotB,
    spotC = spotC,
    spotD = spotD,
    spotP = spotP,
    spotE = spotE,
    spotF = spotF,
    spotG = spotG,
    spotH = spotH,
    spotI = spotI,
    spotJ = spotJ,
    spotK = spotK,
    spotL = spotL,
    spotM = spotM,
    spotN = spotN,
    spotO = spotO,
    JumpSpots = JumpSpots,
    WallDash = WallDash
}