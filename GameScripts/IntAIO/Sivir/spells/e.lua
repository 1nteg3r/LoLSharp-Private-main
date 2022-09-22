local orb = module.load("int", "Orbwalking/Orb");
local evade = module.seek("evade")
local menu = module.load("int", "Core/Sivir/menu")

local e = {
  slot = player:spellSlot(2),
  last = 0,
  delay = 0.5,
  
  use = {
    state = false,
    data = {
      source = nil,
      spell_name = nil,
      wait_time = 0
    }
  },

  spells = {
    ["ahriseduce"] = { delay = 0.1, state = true },
    ["akalimota"] = { delay = 0.1, state = true },
    ["bardr"] = { delay = 0.3, state = true },
    ["blindingdart"] = { delay = 0.1, state = true },
    ["blindmonkrkick"] = { delay = 0.1, state = true },
    ["bluecardpreattack"] = { delay = 0.1, state = true },
    ["brandq"] = { delay = 0.1, state = true },
    ["braumrwrapper"] = { delay = 0.3, state = true },
    ["caitlynaceinthehole"] = { delay = 1, state = true },
    ["cassiopeiar"] = { delay = 0.3, state = true },
    ["curseofthesadmummy"] = { delay = 0.1, state = true },
    ["dariusexecute"] = { delay = 0.1, state = true },
    ["darkbindingmissile"] = { delay = 0.1, state = true },
    ["dazzle"] = { delay = 0.1, state = true },
    ["dianateleport"] = { delay = 0.1, state = true },
    ["disintegrate"] = { delay = 0.1, state = true },
    ["elisehumane"] = { delay = 0.1, state = true },
    ["elisespiderqcast"] = { delay = 0.1, state = true },
    ["ezrealmysticshot"] = { delay = 0.1, state = true },
    ["feast"] = { delay = 0.1, state = true },
    ["fiddlesticksdarkwind"] = { delay = 0.1, state = true },
    ["fling"] = { delay = 0, state = true },
    ["frostbite"] = { delay = 0.1, state = true },
    ["garenqattack"] = { delay = 0.1, state = true },
    ["garenr"] = { delay = 0.1, state = true },
    ["goldcardpreattack"] = { delay = 0.1, state = true },
    ["gnarr"] = { delay = 0.1, state = true },
    ["gragasr"] = { delay = 0.1, state = true },
    ["headbutt"] = { delay = 0.1, state = true },
    ["hecarimrampattack"] = { delay = 0.1, state = true },
    ["iceblast"] = { delay = 0.1, state = true },
    ["infiniteduress"] = { delay = 0, state = true },
    ["ireliaequilibriumstrike"] = { delay = 0.1, state = true },
    ["jaycethunderingblow"] = { delay = 0, state = true },
    ["judicatorreckoning"] = { delay = 0.1, state = true },
    ["karthusfallenone"] = { delay = 2, state = true },
    ["khazixq"] = { delay = 0.1, state = true },
    ["khazixqlong"] = { delay = 0.1, state = true },
    ["leblancchaosorb"] = { delay = 0.1, state = true },
    ["leblancchaosorbm"] = { delay = 0.1, state = true },
    ["leonashieldofdaybreakattack"] = { delay = 0.1, state = true },
    ["leonasolarflare"] = { delay = 0.1, state = true },
    ["lissandrar"] = { delay = 0.1, state = true },
    ["luluwtwo"] = { delay = 0.1, state = true },
    ["luxlightbinding"] = { delay = 0.1, state = true },
    ["malzaharr"] = { delay = 0, state = true },
    ["maokaiunstablegrowth"] = { delay = 0.1, state = true },
    ["missfortunericochetshot"] = { delay = 0.1, state = true },
    ["monkeykingqattack"] = { delay = 0.1, state = true },
    ["mordekaiserchildrenofthegrave"] = { delay = 0, state = true },
    ["namiw"] = { delay = 0.1, state = true },
    ["namiqmissile"] = { delay = 0.1, state = true },
    ["namirmissile"] = { delay = 0.2, state = true },
    ["nasusw"] = { delay = 0.1, state = true },
    ["nocturneunspeakablehorror"] = { delay = 0, state = true },
    ["nulllance"] = { delay = 0.1, state = true },
    ["olafrecklessstrike"] = { delay = 0.1, state = true },
    ["orianadetonatecommand"] = { delay = 0.1, state = true },
    ["pantheonq"] = { delay = 0.1, state = true },
    ["pantheonw"] = { delay = 0.1, state = true },
    ["parley"] = { delay = 0.1, state = true },
    ["powerfistattack"] = { delay = 0, state = true },
    ["pulverize"] = { delay = 0.1, state = true },
    ["puncturingtaunt"] = { delay = 0, state = true },
    ["redcardpreattack"] = { delay = 0.1, state = true },
    ["rocketgrab"] = { delay = 0.1, state = true },
    ["ryzew"] = { delay = 0, state = true },
    ["sionq"] = { delay = 0.1, state = true },
    ["skarnerimpale"] = { delay = 0.1, state = true },
    ["sonar"] = { delay = 0.1, state = true },
    ["sowthewind"] = { delay = 0.1, state = true },
    ["staticfield"] = { delay = 0.1, state = true },
    ["syndrar"] = { delay = 0.1, state = true },
    ["tahmkenchq"] = { delay = 0.1, state = true },
    ["tahmkenchw"] = { delay = 0.1, state = true },
    ["terrify"] = { delay = 0, state = true },
    ["threshq"] = { delay = 0.1, state = true },
    ["tristanae"] = { delay = 0.1, state = true },
    ["tristanar"] = { delay = 0.1, state = true },
    ["twoshivpoison"] = { delay = 0.1, state = true },
    ["xayahe"] = { delay = 0, state = true },
    ["vaynecondemn"] = { delay = 0.1, state = true },
    ["veigarbalefulstrike"] = { delay = 0.1, state = true },
    ["veigardarkmatter"] = { delay = 0.1, state = true },
    ["veigareventhorizon"] = { delay = 0.1, state = true },
    ["veigarr"] = { delay = 0.1, state = true },
    ["vir"] = { delay = 0.1, state = true },
    ["volibearqattack"] = { delay = 0, state = true },
    ["volibearw"] = { delay = 0.1, state = true },
    ["zedult"] = { delay = 0.74, state = true },
    ["zileanqattackaudio"] = { delay = 2.5, state = true },
    ["zoee"] = { delay = 0, state = true },
    ["zyrae"] = { delay = 0.1, state = true }
  }
}

e.is_ready = function()
  return e.slot.state == 0
end

e.get_action_state = function()
  if e.is_ready() then
    return e.get_prediction()
  end
end

e.invoke_action = function()
  player:castSpell("self", 2)
  orb.core.set_server_pause()
end

e.get_prediction = function()
  if e.last == game.time then
    return e.result
  end
  e.last = game.time
  e.result = nil
  
  if not evade then
    if e.use.state and e.use.data.spell_name and e.spells[e.use.data.spell_name:lower()] then
      if os.clock() >= e.use.data.wait_time then
        e.result = e.use.data
        e.use.state = false
        e.use.data.wait_time = 0
        e.use.data.source = nil
        e.use.data.spell_name = nil
        return e.result
      end
    end
  else
    for _, spell in pairs(evade.core.active_spells) do
      if type(spell) == "table" and e.spells[spell.name:lower()] then
        if spell.missile and spell.missile.speed then
          if ((spell.target and spell.target.ptr == player.ptr) or (spell.polygon and spell.polygon:Contains(player.path.serverPos))) then
            local hit_time = (player.path.serverPos:dist(spell.missile.pos) - player.boundingRadius) / spell.missile.speed
            if hit_time > (e.delay + network.latency) and hit_time < (e.delay + 0.25 + network.latency) then
              e.result = spell
              return e.result
            end
          end
        else
          if spell.target and spell.target.ptr == player.ptr then
            e.result = spell
            return e.result
          end
        end
      end
    end
  end

  return e.result
end

local radius = player.boundingRadius * player.boundingRadius
e.on_recv_spell = function(spell)
  if e.spells[spell.name:lower()] then
    local dist_to_spell = spell.endPos and player.path.serverPos:distSqr(spell.endPos) or nil
    if (spell.target and spell.target.ptr == player.ptr) or (dist_to_spell and dist_to_spell <= radius) then
      e.use.data.wait_time = os.clock() + e.spells[spell.name:lower()].delay
      e.use.state = true
      e.use.data.source = spell.owner
      e.use.data.spell_name = spell.name:lower()
    end
  end
end

return e