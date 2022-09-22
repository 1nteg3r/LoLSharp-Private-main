local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Tristana/menu")
local common = module.load(header.id, "common")
local q = {
  slot = player:spellSlot(0),
  last = 0,
  
  data = {
    radius = function(source, target) return common.GetAARange() end,
    obj_speed = function(obj)
      if obj.path.isActive and obj.path.isDashing then
        return obj.path.dashSpeed
      end
      return obj.moveSpeed
    end,
    source = player,
  },
}

q.is_ready = function()
  return q.slot.state == 0
end

q.get_action_state = function()
  if q.is_ready() then
    return q.get_prediction()
  end
end

q.invoke_action = function()
  player:castSpell("self", 0)
end

q.get_prediction = function()
  if q.last == game.time then
    return q.result
  end
  q.last = game.time
  q.result = nil
  
  local target = ts.get_result(function(res, obj, dist)
    if dist <= common.GetAARange(obj) then
      res.obj = obj
      return true
    end
  end).obj
  if target then
    q.data.target = target
    if gpred.multipresent.get_prediction(q.data) then
      local aa_dmg = common.CalculateAADamage(q.data.target)
      if (aa_dmg * menu.combo.q.x_aa:get()) > common.GetShieldedHealth("AD", q.data.target) then
        return q.result
      else
        q.result = q.data.target
        return q.result
      end
    end
  end

  return q.result
end

return q