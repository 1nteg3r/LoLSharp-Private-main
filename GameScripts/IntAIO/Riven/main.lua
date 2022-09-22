local orb = module.internal("orb")

local common = module.load("int", "Library/common");
local menu = module.load("int", "Core/Riven/menu");
local q = module.load("int", "Core/Riven/spell/q");
local w = module.load("int", "Core/Riven/spell/w");--require'Riven/spell/w'
local e = module.load("int", "Core/Riven/spell/e");
local r2 = module.load("int", "Core/Riven/spell/r2");
local core = module.load("int", "Core/Riven/core/main");--require'Riven/core/main'
local spell = module.load("int", "Core/Riven/spell/main");--require'Riven/spell/main'

orb.combat.register_f_pre_tick(function()
  spell.r2.on_update_buff()
  spell.r2.on_remove_buff()
  spell.r1.on_remove_buff()
  core.ai.get_action()
  --print(player.path.isActive, player.path.index, player.path.count, player.path.serverPos.x, player.path.point[player.path.count].x, os.clock())
    if menu.flee:get() then 
      player:move(mousePos)
      local post = player.pos + (mousePos - player.pos):norm() * 300
      player:castSpell("pos", 0, post)
      player:castSpell("pos", 2, mousePos)
    end 
end)

local consider_killable = function(obj)
  local damage = 0 
  local raw = player.baseAttackDamage + player.flatPhysicalDamageMod
  if w.is_ready()  then
    damage = raw + w.dmg()
  end
  if q.is_ready() then
    damage = raw + q.dmg()
  end
  damage = raw + r2.dmg(obj)
  return damage * (100 / (100 + obj.armor)) > obj.health
end

local on_draw = function()
  local enemy = common.GetEnemyHeroes()
  for i, target in ipairs(enemy) do
      if target and target.isVisible and common.IsValidTarget(target) and not target.buff[17] then
          if target.isOnScreen then 
            local raw = player.baseAttackDamage + player.flatPhysicalDamageMod
              local damage = ((w.dmg() + raw) + (q.dmg()+raw) + (r2.dmg(target)+ raw))
              local barPos = target.barPos                   
              local percentHealthAfterDamage = math.max(0, target.health - damage) / target.maxHealth
              graphics.draw_line_2D(barPos.x + 165 + 103 * target.health/target.maxHealth, barPos.y+123, barPos.x + 165 + 100 * percentHealthAfterDamage, barPos.y+123, 11,  graphics.argb(90, 255, 169, 4))        
          end 
      end 
  end
  local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
  if menu.r1:get() then 
    graphics.draw_text_2D("Use R1 in Combo", 16, pos.x - 50, pos.y + 30, graphics.argb(255, 255, 255, 255))
  end
  if menu.e_aa:get() then 
    graphics.draw_text_2D("Bursting", 16, pos.x - 50, pos.y, graphics.argb(255, 255, 255, 255))
  end
end

local on_recv_spell = function(proc)
  if proc.owner.ptr == player.ptr then
    spell.e.on_new_path(proc)
    spell.r1.on_recv_spell(proc)
    spell.r2.on_recv_spell(proc)
    core.ai.on_recv_spell(proc)
  end
end

local on_new_path = function(obj)
  if obj.ptr == player.ptr then
    spell.e.on_new_path()
  end
end

local on_create_obj = function(obj)
  core.ai.on_create_obj(obj)
end

local on_update_buff = function(buff)
  if buff.owner.ptr == player.ptr then
    spell.r2.on_update_buff(buff)
  end
end

local on_remove_buff = function(buff)
  if buff.owner.ptr == player.ptr then
    spell.r1.on_remove_buff(buff)
    spell.r2.on_remove_buff(buff)
  end
end

cb.add(cb.draw, on_draw)
cb.add(cb.spell, on_recv_spell)
--cb.add(cb.path, on_new_path)
cb.add(cb.create_particle, on_create_obj)
--cb.add(cb.updatebuff, on_update_buff)
--cb.add(cb.removebuff, on_remove_buff)
