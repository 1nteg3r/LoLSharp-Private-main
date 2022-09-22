local orb = module.internal("orb")
local menu = module.load(header.id, "Addons/Twitch/menu")
local common = module.load(header.id, "common")

local q = {
  slot = player:spellSlot(0),
  
  buff = {
    name = "twitchhideinshadows",
    duration = { 10, 11, 12, 13, 14 },
    reveal_range = 500
  }
}

q.is_ready = function()
  return q.slot.state == 0
end

q.invoke_action = function()
  player:castSpell("self", 0)
  orb.core.set_server_pause()
end

q.invoke__stealth_recall = function()
  q.invoke_action()
  player:castSpell("self", 13)
  orb.core.set_server_pause()
end

q.on_draw = function()
  if menu.draws.q_range:get() and q.slot.level > 0 and player.buff[q.buff.name] then
    local buff = player.buff[q.buff.name]
    graphics.draw_circle(player.pos, q.buff.reveal_range, menu.draws.width:get(), menu.draws.q:get(), menu.draws.numpoints:get())
    local factor = (game.time - (q.buff.duration[q.slot.level] + buff.startTime)) - network.latency
    graphics.draw_circle(player.pos, (150 * factor), menu.draws.width:get(), graphics.argb(255, 255, 0, 0), menu.draws.numpoints:get())
  end
end

return q