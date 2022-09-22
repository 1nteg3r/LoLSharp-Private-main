local pMenu = module.load(header.id, "Core/Gangplank/menu")
local common = module.load(header.id, "Library/common")
local dmgLib = module.load(header.id, "Library/damageLib")
local GeoLib = module.load(header.id, "Geometry/GeometryLib")

local orb = module.internal("orb")
local evade = module.seek('evade')
local gpred = module.internal("pred")

--Classes
local Enumerable = module.load(header.id, "LuaLinq/Classes/Enumerable")

local Barrel = { }

local on_tick = function()

end 

local on_draw = function()

end 

local create_barriel = function(obj)
    if obj and obj.name == "Barrel" and obj.owner.charName == "Gangplank" then 
        Barrel[obj.ptr] = {
            obj = obj, 
            timeCreated = game.time 
        }
    end 
end 

local delete_barriel = function(obj)
    if not obj then 
        return 
    end 
    
    for i, Object in pairs(Barrel) do 
        if Object.obj and Object.obj == obj then 
            Barrel[obj.ptr] = nil 
        end 
    end 
end 

return {
    on_tick = on_tick, 
    on_draw = on_draw, 
    create_barriel = create_barriel, 
    delete_barriel = delete_barriel
}