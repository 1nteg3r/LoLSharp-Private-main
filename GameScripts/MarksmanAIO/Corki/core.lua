local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")
local menu = module.load(header.id, "Addons/Corki/menu")
local q = module.load(header.id, "Addons/Corki/spells/q")
local w = module.load(header.id, "Addons/Corki/spells/w")
local e = module.load(header.id, "Addons/Corki/spells/e")
local r = module.load(header.id, "Addons/Corki/spells/r")
local common = module.load(header.id, "common")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
  if orb.combat.is_active() then
    if player.buff["sheen"] or player.buff["lichbane"] or player.buff["itemfrozenfist"] then --extra measure to ensure spells aren't used
      return
    end
    if menu.use_q:get() then
      if q.get_action_state() then
        q.invoke_action()
        orb.combat.set_invoke_after_attack(false)
        return
      end
    end
    if menu.use_r:get() then
      if r.get_action_state() then
        r.invoke_action()
        orb.combat.set_invoke_after_attack(false)
        return
      end
    end
  end
end

core.on_out_of_range = function()
  if orb.combat.is_active() then
    if menu.use_q:get() then
      if q.get_action_state() then
        q.invoke_action()
        orb.combat.set_invoke_after_attack(false)
        return
      end
    end
    if menu.use_r:get() then
      if r.get_action_state() then
        r.invoke_action()
        orb.combat.set_invoke_after_attack(false)
        return
      end
    end
    if menu.use_w:get() and common.GetPercentPar() > menu.w_mana_mngr:get() then
      w.get_action_state()
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

core.on_end_e = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_end_r = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_end_dash = function()
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

core.on_cast_e = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_e
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
  if menu.q_ks:get() then
    if q.invoke_killsteal() then
      return
    end
  end
  if menu.r_ks:get() then
    if player.sar > 0 and r.invoke_killsteal() then
      return
    end
  end
  if menu.semi_r:get() then
    if r.is_ready() and player.sar > 0 then
      local target = ts.get_result(function(res, obj, dist)
        if dist > 2000 then
          return
        end
        local seg = gpred.linear.get_prediction(r.predinput, obj)
        if seg and seg.startPos:distSqr(seg.endPos) < 1500625 then
          local col = gpred.collision.get_prediction(r.predinput, seg, obj)
          if not col then
            res.obj = obj
            res.seg = seg
            return true
          end
        end
      end)
      if target.seg and target.obj then
        player:castSpell("pos", 3, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
        orb.core.set_server_pause()
        return
      end
    end
  end
  if orb.combat.is_active() then
    if player.buff["sheen"] or player.buff["lichbane"] or player.buff["itemfrozenfist"] then
      return
    end
    if menu.use_e:get() then
      if e.get_action_state() then
        e.invoke_action()
        return
      end
    end
  end
end

core.on_recv_self_dash = function()
  local t = player.path.serverPos2D:dist(player.path.point2D[1]) / player.path.dashSpeed
  if os.clock() + t > core.on_end_time then
    core.on_end_func = core.on_end_dash
    core.on_end_time = os.clock() + t
    orb.core.set_pause(math.huge)
  end
end

core.on_recv_spell = function(spell)
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["PhosphorusBomb"] = core.on_cast_q
core.f_spell_map["CarpetBomb"] = core.on_cast_w
core.f_spell_map["CarpetBombMega"] = core.on_cast_w
core.f_spell_map["GGun"] = core.on_cast_e
core.f_spell_map["MissileBarrage"] = core.on_cast_r
core.f_spell_map["MissileBarrageMissile"] = core.on_cast_r
core.f_spell_map["MissileBarrageMissile2"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core