local menu = module.load("int", "Core/Ryze/menu")

local r = {
  slot = player:spellSlot(3),
  range = { 1750, 3000, 3001 },
}

r.on_draw = function()
	if menu.draw_r_range:get() and r.slot.level > 0 then
	  graphics.draw_circle(player.pos, r.range[r.slot.level], 1, graphics.argb(255, 255, 255, 255), 50)
	end
end

return r