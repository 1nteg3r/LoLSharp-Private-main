local common = module.load(header.id, "Library/common")
local GeometryLib = module.load(header.id, "Geometry/GeometryLib")
local gpred = module.internal("pred")

local Vector = GeometryLib.Vector

local spellQ = {
	range = 800,
	radius = 210,
	speed = math.huge,
	boundingRadiusMod = 0,
	delay = 0.75
}

local ontick = function()

    --[[for i = 1, #common.GetEnemyHeroes() do
        local target = common.GetEnemyHeroes()[i]

        if target and common.isValidTarget(target) then 

            local seg = { }

            seg.startPos = vec2(player.x, player.z)
            seg.endPos = vec2(target.x, target.z)

            if seg.startPos and seg.endPos then 
                --common.ChatPrint("here")
                local pos = gpred.circular.get_prediction(spellQ, target, vec2(player.x, player.z))

                if pos and pos.endPos  and player.pos:distSqr(vec3(pos.endPos.x, target.pos.y, pos.endPos.y)) < 875^2 then 
                    common.ChatPrint("endPos")
                    local castPos = vec3(pos.endPos.x, target.y, pos.endPos.y)

                    player:castSpell("pos", 0, castPos)
                end 
            end 
        end 
    end ]]
end 
