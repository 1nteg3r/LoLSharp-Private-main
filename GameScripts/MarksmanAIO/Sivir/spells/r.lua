local menu = module.load(header.id, "Addons/Sivir/menu")

local r = {
  slot = player:spellSlot(3),
  range = 1000,
}

r.on_draw = function()
	if menu.draw_r_range:get() and r.slot.level > 0 then
	  graphics.draw_circle(player.pos, r.range, 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

return r