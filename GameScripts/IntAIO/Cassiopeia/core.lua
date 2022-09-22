local orb = module.internal("orb")
local menu = module.load("int", "Cassiopeia/menu")
local common = module.load("int", "common")
local q = module.load("int", "Cassiopeia/spells/q")
local w = module.load("int", "Cassiopeia/spells/w")
local e = module.load("int", "Cassiopeia/spells/e")
local r = module.load("int", "Cassiopeia/spells/r")

local core = {
  on_end_func = nil,
  on_end_time = 0,
  f_spell_map = {},
}

local q_time = 0
local w_time = 0

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
  if core.on_end_func and os.clock() + network.latency > core.on_end_time then
    core.on_end_func()
  end
  if menu.auto_q:get() and q.is_ready() then
    q.invoke__on_dash()
  end
  if menu.auto_w:get() and w.is_ready() then
    w.invoke__anti_gapcloser()
  end
  if not orb.combat.is_active() and not orb.menu.last_hit.key:get() and not orb.menu.lane_clear.key:get() then
    if orb.core.is_attack_paused() then
      orb.core.set_pause_attack(0)
    end
  end
  if (orb.combat.is_active())  then
    if orb.combat.is_active() and menu.combo.no_aa:get() <= player.levelRef and player.mana > 100 then
      orb.core.set_pause_attack(math.huge)
    end
    if common.GetPercentHealth() <= 30 and menu.zhoyah:get() then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and slot.name == 'ZhonyasHourglass' and slot.state == 0 then
          player:castSpell("self", i)
          orb.core.set_server_pause()
          break
        end
      end
    end
    if common.GetPercentHealth() <= 25 and menu.sera:get() then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and slot.name == 'ItemSeraphsEmbrace' and slot.state == 0 then
          player:castSpell("self", i)
          orb.core.set_server_pause()
          break
        end
      end
   end
    if menu.combo.r.r:get() and r.get_action_state() then
      r.invoke_action()
      return
    end
    if menu.combo.path:get() == 1 then
      if menu.combo.q.q:get() and os.clock() > w_time and q.get_action_state() then
        q.invoke_action()
        return
      end
      if menu.combo.w.w:get() and os.clock() > q_time and w.get_action_state() then
        w.invoke_action()
        return
      end
    end
    if menu.combo.path:get() == 2 then
      if menu.combo.w.w:get() and os.clock() > q_time and w.get_action_state() then
        w.invoke_action()
        return
      end
      if menu.combo.q.q:get() and os.clock() > w_time and q.get_action_state() then
        q.invoke_action()
        return
      end
    end
    if menu.combo.e.e:get() ~= 3 and e.get_action_state() then
      e.invoke_action()
      return
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass.q.q:get()  and os.clock() > w_time and q.get_action_state() then
      q.invoke_action()
      return
    end
    if menu.harass.e.e:get() ~= 3  and e.get_action_state() then
      e.invoke_action()
      return
    end
    if menu.harass.w.w:get()  and os.clock() > q_time and w.get_action_state() then
      w.invoke_action()
      return
    end
    if menu.clear.e.lasthit_e:get() and e.is_ready() then
      e.invoke__last_hit()
      return
    end
  end
  if orb.menu.lane_clear:get() then
    if menu.clear.q.q:get() and q.is_ready() then
      q.invoke__lane_clear()
      return
    end
    if menu.clear.e.e:get() ~= 3 and e.is_ready()  then
      e.invoke__lane_clear()
      return
    end
    if menu.clear.e.lasthit_e:get() and e.is_ready() then
      e.invoke__last_hit()
      return
    end
  end
  if (orb.menu.last_hit:get() or orb.menu.lane_clear:get()) and menu.clear.e.lasthit_e:get() and e.is_ready() then
    e.invoke__last_hit()
    return
  end
   if keyboard.isKeyDown(0x56) then
    if e.is_ready() then
      orb.core.set_pause_attack(0.25)
      e.invoke__last_hit()
    end 
  end
end

core.on_recv_spell = function(spell)
  if spell.name == 'CassiopeiaQ' then
    q_time = os.clock() + 1
  end
  if spell.name == 'CassiopeiaW' then
    w_time = os.clock() + 1
  end
  if core.f_spell_map[spell.name] then
    core.f_spell_map[spell.name](spell)
  end
end

core.f_spell_map["CassiopeiaQ"] = core.on_cast_q
core.f_spell_map["CassiopeiaW"] = core.on_cast_w
core.f_spell_map["CassiopeiaE"] = core.on_cast_e
core.f_spell_map["CassiopeiaR"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core