local common = module.load(header.id, "Library/common");

local objList = {}
local trackList = {}
local passivePos = { }

local passtiveList = {
    ["Fiora_Base_Passive_NE"] = { x = 0, z = 200},
    ["Fiora_Base_Passive_NW"] = { x = 200, z = 0},
    ["Fiora_Base_Passive_SE"] = { x = -1 * 200, z = 0},
    ["Fiora_Base_Passive_SW"] = { x = 0, z = -1 * 200},
    ["Fiora_Base_R_Mark_NE_FioraOnly"] = { x = 0, z = 200},
    ["Fiora_Base_R_Mark_NW_FioraOnly"] = { x = 200, z = 0},
    ["Fiora_Base_R_Mark_SE_FioraOnly"] = { x = -1 * 200, z = 0},
    ["Fiora_Base_R_Mark_SW_FioraOnly"] = { x = 0, z = -1 * 200}
}

local function ObjList()
    local result = {}

    for i, object in pairs(objList) do
        local nID = object

        if nID then
            trackList[nID] = object
        else
            table.insert(result, object)
        end
    end

    objList = result
end 

local function GetQPos()
    local result = nil
    local distanceTemp = math.huge

    for i, obj in pairs(trackList) do
        local origin  = { x = obj.x, y = obj.y, z = obj.z }

        if origin then
            local distance = passtiveList[obj.name]

            if not distance then 
                return 
            end

            local buff_pos = {
                x = origin.x + distance.x,
                y = origin.y,
                z = origin.z + distance.z
            }

            local buff_pos_distance = common.GetDistance(buff_pos)
            if not result or buff_pos_distance < distanceTemp then
                result = buff_pos
                distanceTemp = buff_pos_distance
            end
        end
    end

    return result, distanceTemp
end 

local function OnTick()
    ObjList()

    local buff_pos, distance = GetQPos()
    if buff_pos and distance > 100 then
        if player:spellSlot(0).state == 0 and distance < 450 then
            player:castSpell("pos", 0, vec3(buff_pos.x, 0, buff_pos.z))
        end
    end 
end
local function on_create_particle(obj)
    if obj then 
        if string.match(obj.name, "Base_Passive")  then 
            table.insert(objList, obj)
            print'ehre'
        end
    end
end

local function on_delete_particle(obj)
    if obj then 
        trackList[obj.ptr] = nil
    end
end

cb.add(cb.create_particle, on_create_particle)
cb.add(cb.delete_particle, on_delete_particle)
cb.add(cb.tick, OnTick)
