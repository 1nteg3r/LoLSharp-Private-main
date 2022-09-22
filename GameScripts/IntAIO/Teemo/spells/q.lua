local orb = module.internal("orb");
local ts = module.internal("TS")
local menu = module.load("int", "Core/Teemo/menu")
local common = module.load("int", "Library/common")

local q = {
  slot = player:spellSlot(0),
  last = 0,
  range = 680,
}

local temp = { Aatrox = true, Ekko = true, Illaoi = true, Hecarim = true, MonkeyKing = true, Rengar = true }

q.is_ready = function()
  return q.slot.state == 0
end

q.get_action_state = function()
  if q.is_ready() then
    return q.get_prediction()
  end
end

q.invoke_action = function()
  player:castSpell("obj", 0, q.result)
  orb.core.set_server_pause()
end

q.get_damage = function(target)
  local damage = (80 + (45 * (player:spellSlot(0).level - 1))) + (common.GetTotalAP() * 0.80)
  return common.CalculateMagicDamage(target, damage)
end

q.is_withdrawing = function(target)
  if target.path.isActive then
    return target.path.point[target.path.count]:dist(player.pos) > target.pos:dist(player.pos)
  end
  return false
end

q.custom_filter = ts.filter.new()
q.custom_filter.index = function(obj, rank_val)
  return common.GetTotalAD(obj) * -1
end

q.get_target = function(res, obj, dist)
  if not menu.blacklist[obj.charName]:get() then
    return
  end
  if dist <= common.GetAARange(obj) then
    local aa_damage = common.CalculateAADamage(obj)
    if aa_damage >= common.GetShieldedHealth("AD", obj) then
      return
    end
  end
  if dist <= q.range then
    res.obj = obj
    res.dist = dist
    return true
  end
end

q.get_prediction = function()
  if q.last == game.time then
    return q.result
  end
  q.last = game.time
  q.result = nil
  
  local target = ts.get_result(q.get_target, q.custom_filter)
  if target.obj then
    if q.get_damage(target.obj) > common.GetShieldedHealth("AP", target.obj) then
      q.result = target.obj
      return q.result
    end
    if orb.combat.is_active() then
      if menu.cq:get() == 1 then
        if target.obj.attackRange < 300 or temp[target.obj.charName] then
          if target.dist <= (target.obj.attackRange + target.obj.boundingRadius + 55) and not q.is_withdrawing(target.obj) then
            q.result = target.obj
            return q.result
          elseif common.GetPercentHealth(target.obj) < 25 then
            q.result = target.obj
            return q.result
          end
        else
          q.result = target.obj
          return q.result
        end
      end
      if menu.cq:get() == 2 then
        q.result = target.obj
        return q.result
      end
    end
    if orb.menu.hybrid:get() then
      q.result = target.obj
      return q.result
    end
  end
  
  return q.result
end

q.on_draw = function()
  if q.slot.level > 0 then
    if menu.draws.q_range:get() == 3 then
      local pos = {}
      for i = 0, 4 do
        local theta = i * 2 * math.pi / 5 + os.clock()
        pos[i] = vec3(player.x + q.range * math.sin(theta), player.y, player.z + q.range * math.cos(theta))
      end
      for i = 0, 4 do
        graphics.draw_line(pos[i], pos[i > 2 and i - 3 or i + 2], 3, 0xFFFF0000)
      end
      graphics.draw_circle(player.pos, q.range, 3, 0xFFFF0000, 128)
    end
    if menu.draws.q_range:get() == 2 then
      graphics.draw_circle(player.pos, q.range, 1, graphics.argb(255, 255, 255, 255), 50)
    end
  end
end

return q