local orb = module.internal("orb")
local menu = module.load(header.id, "Addons/Kaisa/menu")
local common = module.load(header.id, "common")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local q = module.load(header.id, "Addons/Kaisa/spells/q")
local w = module.load(header.id, "Addons/Kaisa/spells/w")
local e = module.load(header.id, "Addons/Kaisa/spells/e")
local r = module.load(header.id, "Addons/Kaisa/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
  if orb.combat.is_active() then
    if menu.c_q:get() == 2 and q.get_action_state() then
      q.invoke_action()
      orb.combat.set_invoke_after_attack(false)
      return
    end
  end
end

core.on_out_of_range = function()
  if orb.combat.is_active() then
    if menu.c_q:get() == 1 and q.get_action_state() then
      q.invoke_action()
      orb.combat.set_invoke_after_attack(false)
      return
    end
  end
end

core.on_end_q = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_end_w = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_end_r = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_cast_q = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_q
    core.on_end_time = os.clock() + spell.windUpTime
    orb.core.set_pause(math.huge)
  end
end

core.on_cast_w = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_w
    core.on_end_time = os.clock() + spell.windUpTime
    orb.core.set_pause(math.huge)
  end
end

core.on_cast_r = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_r
    core.on_end_time = os.clock() + spell.windUpTime
    orb.core.set_pause(math.huge)
  end
end

core.get_action = function()
  if core.on_end_func and os.clock() + network.latency > core.on_end_time then
    core.on_end_func()
  end

  if menu.autoQ:get() then 
    for i = 0, objManager.enemies_n - 1 do
      local enemy = objManager.enemies[i]
      if enemy and common.IsValidTarget(enemy) then
        local count = 0
        for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
          local minion = objManager.minions[TEAM_ENEMY][i]
          if minion and not minion.isDead and minion.isVisible then
            local distSqr = player.path.serverPos:distSqr(minion.path.serverPos)
            if distSqr <= (q.predinput.radius * q.predinput.radius) then
              count = count + 1
            end
          end
        end
        if count == 0 then 
          if gpred.present.get_prediction(q.predinput, enemy) then
            player:castSpell("self", 0)
          end
        end 
      end 
    end
  end 
  if menu.flee_key:get() then
    player:move(mousePos)
    if menu.flee_e:get() and e.is_ready() then
      e.invoke_action()
      return
    end
  end
  if orb.combat.is_active() or orb.menu.hybrid.key:get() or orb.menu.last_hit.key:get() or orb.menu.lane_clear.key:get() then
    if player.buff["kaisae"] then
        player:move(mousePos)
    end
  end
  if menu.ks_w:get() then
    if w.invoke_killsteal() then
      return
    end
  end
  if orb.combat.is_active() then
    if menu.c_q:get() == 1 and q.get_action_state() then
      q.invoke_action()
      return
    end
    if menu.combo_w:get() ~= 3 and w.get_action_state() then
      w.invoke_action()
      return
    end
  end
  if menu.semiW:get() then 
    player:move(mousePos)
    local target = ts.get_result(function(res, obj, dist)
      if dist >= menu.combo_w_slider:get() then
        return
      end
      if dist <= common.GetAARange(obj) then
        local aa_damage = common.CalculateAADamage(obj)
        if (aa_damage * 2) > common.GetShieldedHealth("AD", obj) then
          return
        end
      end
      res.obj = obj
      return true
      end).obj
      if target then 
        local seg = gpred.linear.get_prediction(w.predinput, target)
        if seg and seg.startPos:distSqr(seg.endPos) <= (w.range * w.range) then
          local col = gpred.collision.get_prediction(w.predinput, seg, target)
          if not col then
            player:castSpell("pos", 1, vec3(seg.endPos.x, target.y, seg.endPos.y))
          end
        end
      end 
  end 
end

core.on_recv_spell = function(spell)
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["KaisaQ"] = core.on_cast_q
core.f_spell_map["KaisaW"] = core.on_cast_w
core.f_spell_map["KaisaR"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core