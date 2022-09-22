local orb = module.internal("orb")
local ts = module.internal('TS')
local gpred = module.internal("pred")
local menu = module.load("int", "Cassiopeia/menu")
local common = module.load("int", "common")
local e = module.load("int", "Cassiopeia/spells/e")

local r = {
  slot = player:spellSlot(3),
  last = 0,
  range = 825, --680625
  
  result = {
    seg = nil,
    obj = nil,
  },

  predinput = {
    delay = 0.5,
    width = 100,
    speed = math.huge,
    boundingRadiusMod = 0,
    collision = { wall = true, }
  },
  
  --[[
  interuptable_spells = {
    ["Anivia"] = { [3] = true },
    ["Caitlyn"] = { [3] = true },
    ["Ezreal"] = { [3] = true },
    ["FiddleSticks"] = { [3] = true },
    ["Gragas"] = { [1] = true },
    ["Janna"] = { [3] = true },
    ["Jhin"] = { [3] = true },
    ["Karthus"] = { [3] = true }, --isDead will prevent from casting @ zombie karthus
    ["Katarina"] = { [3] = true },
    ["Lucian"] = { [3] = true },
    ["Lux"] = { [3] = true },
    ["Malzahar"] = { [3] = true },
    ["MasterYi"] = { [1] = true },
    ["MissFortune"] = { [3] = true },
    ["Nunu"] = { [3] = true },
    ["Pantheon"] = { [3] = true },
    ["Poppy"] = { [3] = true }, --maybe
    ["Shen"] = { [3] = true },
    ["TwistedFate"] = { [3] = true },
    ["Varus"] = { [0] = true },
    ["Velkoz"] = { [3] = true },
    ["Warwick"] = { [3] = true },
    ["MonkeyKing"] = { [3] = true }, --maybe
    ["Xerath"] = { [3] = true },
  },
  ]]
}

r.is_ready = function()
  return r.slot.state == 0
end

r.get_action_state = function()
  if r.is_ready() then
    return r.get_prediction()
  end
end

r.get_damage = function(target)
  local damage = (50 + (100 * r.slot.level)) + (common.GetTotalAP() * 0.50)
  local total_damage = common.CalculateMagicDamage(target, damage)
  return total_damage
end

r.invoke_action = function()
  player:castSpell("pos", 3, vec3(r.result.seg.endPos.x, r.result.obj.y, r.result.seg.endPos.y))
  orb.core.set_server_pause()
end

r.is_facing = function(target)
  return player.path.serverPos:distSqr(target.path.serverPos) > player.path.serverPos:distSqr(target.path.serverPos + target.direction)
end

r.trace_filter = function()
  if menu.combo.r.ONEvONE.use:get() ~= 4 then
    local mode = menu.combo.r.ONEvONE.use:get()
    local enemies = ts.loop(function(res, obj, dist)
      if dist <= menu.combo.r.ONEvONE.range_check:get() then
        res.in_range = res.in_range and res.in_range + 1 or 1
      end
    end)
    if enemies.in_range and enemies.in_range == 1 then
      local dist_to_target = player.path.serverPos:distSqr(r.result.obj.path.serverPos)
      if e.is_ready() and dist_to_target <= (e.predinput.radius * e.predinput.radius) then
        if e.get_damage(r.result.obj) >= common.GetShieldedHealth("AP", r.result.obj) then
          return false
        end
      end
      if mode == 1 then
        return true
      end
      if mode == 2 and r.is_facing(r.result.obj) then
        return true
      end
      if mode == 3 and r.get_damage(r.result.obj) >= common.GetShieldedHealth("AP", r.result.obj) then
        return true
      end
    end
  end
  local count = 0
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if enemy and not enemy.isDead and enemy.isTargetable and enemy.isVisible then
      if player.path.serverPos:dist(enemy.path.serverPos) < (r.range - enemy.boundingRadius) and r.is_facing(enemy) then
        count = count + 1
      end
    end
    if count == menu.combo.r.min_r:get() then
      if gpred.trace.linear.hardlock(r.predinput, r.result.seg, r.result.obj) then
        return false
      end
      if gpred.trace.linear.hardlockmove(r.predinput, r.result.seg, r.result.obj) then
        return true
      end
      if gpred.trace.newpath(r.result.obj, 0.033, 0.500) then
        return true
      end
    end
  end
end

r.get_prediction = function()
  if r.last == game.time then
    return r.result.seg
  end
  r.last = game.time
  r.result.obj = nil
  r.result.seg = nil
  
  r.result = ts.get_result(function(res, obj, dist)
    if menu.combo.r.whitelist[obj.charName]:get() and dist < r.range then
      local seg = gpred.linear.get_prediction(r.predinput, obj)
      if seg and seg.startPos:distSqr(seg.endPos) < 680625 then
        if not gpred.collision.get_prediction(r.predinput, seg, obj) then
          res.obj = obj
          res.seg = seg
          return true
        end
      end
    end
  end)
  if r.result.seg and r.trace_filter() then
    return r.result
  end
end

r.on_draw = function()
  if menu.draws.r_range:get() and r.slot.level > 0 then
    graphics.draw_circle(player.pos, r.range, 1, graphics.argb(255, 255, 255, 200), 100)
  end
end

return r