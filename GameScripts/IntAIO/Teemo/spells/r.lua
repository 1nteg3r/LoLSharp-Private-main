local orb = module.internal("orb");
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load("int", "Core/Teemo/menu")
local common = module.load("int", "Library/common")

local r = {
  slot = player:spellSlot(3),
  range = { 400, 650, 900 },
  cast_interval = 0.25,
  map_name = "",
  existing_shrooms = {},
  
  shroom_spots = { --need to update these
    --Top Lane Blue Side (including Baron)
    vec3(2790, 50.16358, 7278),
    vec3(3700.708, -11.22648, 9294.094),
    vec3(2314, 53.165, 9722),
    vec3(3090, -68.03732, 10810),
    vec3(4722, -71.2406, 10010),
    vec3(5208, -71.2406, 9114),
    vec3(4724, 52.53909, 7590),
    vec3(4564, 51.83786, 6060),
    vec3(2760, 52.96445, 5178),
    vec3(4440, 56.8484, 11840),
    --Top Lane Tri Bush
    vec3(2420, 52.8381, 13482),
    vec3(1630, 52.8381, 13008),
    vec3(1172, 52.8381, 12302),
    --Top Lane Red Side
    vec3(5666, 52.8381, 12722),
    vec3(8004, 56.4768, 11782),
    vec3(9194, 53.35013, 11368),
    vec3(8280, 50.06194, 10254),
    vec3(6728, 53.82967, 11450),
    vec3(6242, 54.09851, 10270),
    --Mid Lane
    vec3(6484, -71.2406, 8380),
    vec3(8380, -71.2406, 6502),
    vec3(9099.75, 52.95337, 7376.637),
    vec3(7376, 52.8726, 8802),
    vec3(7602, 52.56985, 5928),
    --Dragon
    vec3(9372, -71.2406, 5674),
    vec3(10148, -71.2406, 4801.525),
    --Bot Lane Red Side
    vec3(9772, 9.031885, 6458),
    vec3(9938, 51.62378, 7900),
    vec3(11465, 51.72557, 7157.772),
    vec3(12481, 51.7294, 5232.559),
    vec3(11266, -7.897567, 5542),
    vec3(11290, 64.39886, 8694),
    vec3(12676, 51.6851, 7310.818),
    vec3(12022, 9154, 51.25105),
    --Bot Lane Blue Side (Bushes only)
    vec3(6544, 48.257, 4732),
    vec3(5576, 51.42581, 3512),
    vec3(6888, 51.94016, 3082),
    vec3(8070, 51.5508, 3472),
    vec3(8594, 51.73177, 4668),
    vec3(10388, 49.81641, 3046),
    vec3(9160, 59.97022, 2122),
    --Bot Lane Tri Bush
    vec3(12518, 53.66707, 1504),
    vec3(13404, 51.3669, 2482),
    vec3(11854, -68.06037, 3922),
  }
}

objManager.loop(function(obj)
  if obj then
    if string.find(obj.name, "SRU_") ~= nil then
      r.map_name = "Summoner's Rift"
    end
    if string.find(obj.name, "TT_shop") ~= nil then
      r.map_name = "Twisted Treeline"
    end
    if string.find(obj.name, "MB_shop") ~= nil then
      r.map_name = "Howling Abyss"
    end
    if obj.name == 'Noxious Trap' and obj.health > 0 and r.existing_shrooms[obj.ptr] == nil then
      r.existing_shrooms[obj.ptr] = obj
    end
  end
end)

r.is_ready = function()
  return r.slot.state == 0
end

r.get_obj_movement_speed = function(obj)
  if obj and obj.path.isActive and obj.path.isDashing then
    return obj.path.dashSpeed
  end
  return obj.moveSpeed
end

r.get_prediction = function()
  local target = ts.get_result(function(res, obj, dist)
    if dist <= r.range[r.slot.level] then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    local pred = gpred.core.project(player.path.serverPos, target.path, 1.25, 1000, r.get_obj_movement_speed(target))
    local pred_pos = vec3(pred.x, player.y, pred.y)
    local dist_to_pos = player.path.serverPos:dist(pred_pos)
    if dist_to_pos <= r.range[r.slot.level] then
      local aa_damage = common.CalculateAADamage(target)
      if aa_damage >= common.GetShieldedHealth("AD", target) then
        return
      end
      if r.slot.stacks >= menu.min_r:get() and r.cast_interval < os.clock() then
        player:castSpell("pos", 3, pred_pos)
        orb.core.set_server_pause()
        r.cast_interval = os.clock() + 2
      end
    end
  end
end

r.on_create_obj = function(obj)
  if obj.name == 'Noxious Trap' and obj.health > 0 and r.existing_shrooms[obj.ptr] == nil then
    r.existing_shrooms[obj.ptr] = obj
  end
end

r.on_delete_obj = function(obj)
  for _, shroom in pairs(r.existing_shrooms) do
    if shroom == obj then
      r.existing_shrooms[obj.ptr] = nil
    end
  end
end

r.on_draw = function()
  if r.slot.level > 0 then
    if menu.draws.r_range:get() == 3 then
      local pos = {}
      for i = 0, 4 do
        local theta = i * 2 * math.pi / 5 + os.clock()
        pos[i] = vec3(player.x + r.range[r.slot.level] * math.sin(theta), player.y, player.z + r.range[r.slot.level] * math.cos(theta))
      end
      for i = 0, 4 do
        graphics.draw_line(pos[i], pos[i > 2 and i - 3 or i + 2], 3, 0xFFFF0000)
      end
      graphics.draw_circle(player.pos, r.range[r.slot.level], 3, 0xFFFF0000, 128)
    end
    if menu.draws.r_range:get() == 2 then
      graphics.draw_circle(player.pos, r.range[r.slot.level], 1, graphics.argb(255, 255, 255, 255), 50)
    end
    if r.map_name == "Summoner's Rift" then
      if menu.draws.r_spots:get() == 3 then
        for i = 1, #r.shroom_spots do
          local shroom_pos = r.shroom_spots[i]
          local pos = {}
          for i = 0, 4 do
            local theta = i * 2 * math.pi / 5 + os.clock()
            pos[i] = vec3(shroom_pos.x + 83.75 * math.sin(theta), shroom_pos.y, shroom_pos.z + 83.75 * math.cos(theta))
          end
          for i = 0, 4 do
            graphics.draw_line(pos[i], pos[i > 2 and i - 3 or i + 2], 2, 0xFFFF0000)
          end
          graphics.draw_circle(shroom_pos, 83.75, 2, 0xFFFF0000, 128)
        end
      end
      if menu.draws.r_spots:get() == 2 then
        for i = 1, #r.shroom_spots do
          local shroom_pos = r.shroom_spots[i]
          graphics.draw_circle(shroom_pos, 83.75, 1, graphics.argb(255, 255, 255, 255), 50)
        end
      end
    end
  end
end

return r