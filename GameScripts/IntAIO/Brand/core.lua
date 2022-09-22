local orb = module.internal("orb");
local ts = module.internal("TS")
local menu = module.load("int", "Core/Brand/menu")
local common = module.load("int", "Library/common")
local q = module.load("int", "Core/Brand/spells/q")
local w = module.load("int", "Core/Brand/spells/w")
local e = module.load("int", "Core/Brand/spells/e")
local r = module.load("int", "Core/Brand/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

core.on_after_attack = function()
end

core.on_out_of_range = function()
end

core.on_end_q = function()
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

core.on_end_w = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_cast_w = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_w
    core.on_end_time = os.clock() + spell.windUpTime
    orb.core.set_pause(math.huge)
  end
end

core.on_end_e = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_cast_e = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_e
    core.on_end_time = os.clock() + spell.windUpTime
    orb.core.set_pause(math.huge)
  end
end

core.on_end_r = function()
  core.on_end_func = nil
  orb.core.set_pause(0)
end

core.on_cast_r = function(spell)
  if os.clock() + spell.windUpTime > core.on_end_time then
    core.on_end_func = core.on_end_r
    core.on_end_time = os.clock() + spell.windUpTime
    orb.core.set_pause(math.huge)
  end
end

core.get_action = function()
  if core.on_end_func then
    if os.clock() + network.latency > core.on_end_time then
      core.on_end_func()
    end
  end
  if menu.misc.auto_q:get() and q.get_action_state() then
    q.invoke_action()
    return
  end
  if orb.combat.is_active() then
    if common.GetPercentHealth() <= 30 then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and slot.name == 'ZhonyasHourglass' and slot.state == 0 then
          player:castSpell("self", i)
          orb.core.set_server_pause()
          break
        end
      end
    end
    local target = ts.get_result(function(res, obj, dist)
      if dist < 1100 then
        res.obj = obj
        return true
      end
    end).obj
    if target then
      local enemies = ts.loop(function(res, obj, dist)
        if dist < 585 then
          res.in_range = res.in_range and res.in_range + 1 or 1
        end
      end)
      if enemies.in_range and enemies.in_range > 1 then
        if target.buff["brandablaze"] then --BrandAblaze
          if menu.combo.e:get() and e.get_action_state() then
            e.invoke_action()
            return
          end
          if menu.combo.q:get() ~= 1 and q.get_action_state() and not menu.misc.auto_q:get() then
            q.invoke_action()
            return
          end
          if menu.combo.w:get() and w.get_action_state() then
            w.invoke_action()
            return
          end
          if menu.combo.r.r:get() and r.get_action_state() then
            r.invoke_action()
            return
          end	
        else
          if menu.combo.w:get() and w.get_action_state() then
            w.invoke_action()
            return
          end
          if menu.combo.q:get() ~= 1 and q.get_action_state() and not menu.misc.auto_q:get() then
            q.invoke_action()
            return
          end
          if menu.combo.e:get() and e.get_action_state() then
            e.invoke_action()
            return
          end
          if menu.combo.r.r:get() and r.get_action_state() then
            r.invoke_action()
            return
          end
        end
      else
        if target.buff["brandablaze"] then --BrandAblaze
          if menu.combo.q:get() ~= 1 and q.get_action_state() and not menu.misc.auto_q:get() then
            q.invoke_action()
            return
          end
          if menu.combo.w:get() and w.get_action_state() then
            w.invoke_action()
            return
          end
          if menu.combo.e:get() and e.get_action_state() then
            e.invoke_action()
            return
          end
          if menu.combo.r.r:get() and r.get_action_state() then
            r.invoke_action()
            return
          end	
        else
          if menu.combo.w:get() and w.get_action_state() then
            w.invoke_action()
            return
          end
          if menu.combo.e:get() and e.get_action_state() then
            e.invoke_action()
            return
          end
          if menu.combo.q:get() ~= 1 and q.get_action_state() and not menu.misc.auto_q:get() then
            q.invoke_action()
            return
          end
          if menu.combo.r.r:get() and r.get_action_state() then
            r.invoke_action()
            return
          end
        end
      end
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass.e:get() and e.get_action_state() then
      e.invoke_action()
      return
    end
    if menu.harass.q:get() ~= 1 and q.get_action_state() and not menu.misc.auto_q:get() then
      q.invoke_action()
      return
    end
    if menu.harass.w:get() and w.get_action_state() then
      w.invoke_action()
      return
    end
  end
end

core.on_recv_spell = function(spell)
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["BrandQ"] = core.on_cast_q
core.f_spell_map["BrandW"] = core.on_cast_w
core.f_spell_map["BrandE"] = core.on_cast_e
core.f_spell_map["BrandR"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core