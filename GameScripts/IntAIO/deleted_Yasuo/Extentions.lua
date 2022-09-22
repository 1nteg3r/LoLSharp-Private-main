local function HasWhirlwind(unit)
    return unit.buff[string.lower('YasuoQ2')]
end

local function IsKnockedUp(unit)
    return unit.buff[29] or unit.buff[30]
end

local function IsUnderTower(pos)
    if not pos then return false end
    for i= 1, objManager.turrets.size[TEAM_ENEMY]-1 do
        local tower = objManager.turrets[TEAM_ENEMY][i]
        if tower and not tower.isDead and tower.health > 0 then
            if tower.pos:dist(pos) < (950) then
                return true
            end
        else 
            tower = nil 
        end
    end
    return false
end

return {
    HasWhirlwind = HasWhirlwind, 
    IsKnockedUp = IsKnockedUp,
    IsUnderTower = IsUnderTower
}