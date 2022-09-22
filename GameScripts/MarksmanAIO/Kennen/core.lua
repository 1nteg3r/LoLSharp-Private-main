local orb = module.internal("orb")
local menu = module.load(header.id, "Addons/Kennen/menu")
local common = module.load(header.id, "common");
local q = module.load(header.id, "Addons/Kennen/spells/q")
local w = module.load(header.id, "Addons/Kennen/spells/w")
local e = module.load(header.id, "Addons/Kennen/spells/e")
local r = module.load(header.id, "Addons/Kennen/spells/r")

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
  if core.on_end_func then
    if os.clock() + network.latency > core.on_end_time then
      core.on_end_func()
    end
  end
  if menu.flee_key:get() then
    if not orb.menu.movement.minimap:get() and minimap.on_map(game.cursorPos) then
      orb.combat.move_to_cursor()
    else
      player:move(mousePos)
    end
    if menu.flee_e:get() and not player.buff["kennenlightningrush"] and e.is_ready() then
      e.invoke_action()
      return
    end
  end
  if orb.combat.is_active() then
    if menu.hourglass:get() and common.GetPercentHealth() <= menu.glass_hp:get() then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and slot.name == 'ZhonyasHourglass' and slot.state == 0 then
          player:castSpell("self", i)
          orb.core.set_server_pause()
          break
        end
      end
    end
    if menu.combo_q:get() and q.get_action_state() then
      q.invoke_action()
      return
    end
    if menu.combo_w:get() ~= 1 and w.get_action_state() then
      w.invoke_action()
      return
    end
    if menu.combo_r:get() and r.get_action_state() then
      r.invoke_action()
      return
    end
  end
  if orb.menu.hybrid:get() then
    if menu.harass_q:get() and q.get_action_state() then
      q.invoke_action()
      return
    end
    if menu.harass_w:get() ~= 1 and w.get_action_state() then
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

core.f_spell_map["KennenShurikenHurlMissile1"] = core.on_cast_q
core.f_spell_map["KennenBringTheLight"] = core.on_cast_w
core.f_spell_map["KennenShurikenStorm"] = core.on_cast_r

orb.combat.register_f_after_attack(core.on_after_attack)
orb.combat.register_f_out_of_range(core.on_out_of_range)

return core