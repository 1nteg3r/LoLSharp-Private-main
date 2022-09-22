local common = module.load('int', 'Library/common');

local function CanCastE(target)
    return target.buff[string.lower('YasuoDashWrapper')]
end

local function PosAfterE(target)
    local PosAfter = player.path.serverPos + (target.path.serverPos - player.path.serverPos):norm() * math.random(player.pos:dist(target.pos) < 410, player.pos:dist(target.pos) + 65) 
    return PosAfter
end

local function AlliesNearTarget(target, range)
    local aleds_in_range = {}
	for i = 0, objManager.allies_n - 1 do
		local aled = objManager.allies[i]
		if target:dist(aled.pos) < range and common.IsValidTarget(aled) then
			aleds_in_range[#aleds_in_range + 1] = aled
		end
	end
	return aleds_in_range
end

local function enemyIsJumpable(enemy, ignore)
    if enemy and common.IsValidTarget(enemy) then
        if ignore ~= nil then 
            for i = 0, objManager.enemies_n - 1 do
                local target = objManager.enemies[i]
                if enemy.networkID == target.networkID then 
                    return false
                end
            end
            for _, buff in pairs(enemy.buff) do 
                if buff and buff.valid then 
                    if (buff.name == "yasuodashwrapper") then return false end 
                end
                return true
            end
        end
        return false
    end
end

return {
    CanCastE = CanCastE,
    PosAfterE = PosAfterE,
    AlliesNearTarget = AlliesNearTarget, 
    enemyIsJumpable = enemyIsJumpable,
}