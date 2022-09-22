local orb = module.internal('orb')
local pred = module.internal('pred')

local sdk = module.load(header.id, "Library/common") 
local misc = module.load(header.id, "Core/Zoe/misc") 
local menu_ts = module.load(header.id, "Core/Zoe/menu")
local GeomLib = module.load(header.id, "Geometry/GeometryLib")
local yas_wind_wall={}

local test = {}

local ZoeQPos = vec3(0,0,0)
local LastQ=0
local LastR=0
local ZoeItemHL = {["itemredemption"]=true}
local ZoeItemSF = {["healthbomb"]=true,["ironstylus"]=true,["shurelyascrest"]=true}
local ZoeItemSM = {["summonerexhaust"]=true,["exhaust"]=true,["summonerdot"]=true,["s5_summonersmiteplayerganker"]=true,["s5_summonersmiteduel"]=true, ["summonerflash"] = true}
local ZoeItem= {["summonerheal"]=true,["summonerbarrier"]=true}
local inputQ = {
	  delay = 0.25,
	  speed = 2500,
	  width = 75,
	  boundingRadiusMod = 0,
	  collision = {
		--no collision for heros to remove clunky wait time if a tank is blocking the way to a squishy target
		hero = false,
		minion = false,
	  },
	}
--local res={}
local f = function(res, obj, dist)
	
	
	
	if player:spellSlot(0).state==0 then
	local seg = pred.linear.get_prediction(inputQ, obj)
	if seg then
	
	if player:spellSlot(3).state == 0 and seg.startPos:distSqr(seg.endPos) < 1425^2 then
		res.obj = obj
		--res.seg = seg
		return true
		elseif seg.startPos:distSqr(seg.endPos) < 875^2 then
		res.obj = obj
		--res.seg = seg
		return true
	end
	end
	elseif dist and dist<=875 then
		res.obj = obj
		return true
	end
end

local ForcePoint=function(pos)
	if not pos and orb.core.is_move_paused() then
		orb.core.set_pause_move(0)
	elseif pos then
		orb.core.set_pause_move(player:basicAttack(0).clientAnimationTime)
		player:move(vec3(pos))
	end
end

local function IsWallBetween(start, endPos, step)
    local start = start or vec3(0,0,0)
    local endPos = endPos or vec3(0,0,0)
    local step = step or 3 

    if (start and start ~= vec3(0,0,0)) and (endPos and endPos ~= vec3(0,0,0)) and step > 0 then 

        local distance = common.GetDistance(start, endPos)
        for i = 0, distance, step do   
            local VecStart = GeomLib.Vector:new(start)
            local VecEnd = GeomLib.Vector:new(endPos)

            local extend = VecStart + (VecEnd - VecStart):normalized() * i
            if extend and (navmesh.isWall(extend)) then  
                return true 
            end 
        end 
    end 
    return false
end 

local wall_check = function(start_pos, end_pos)
 if yas_wind_wall.left  and yas_wind_wall.right and yas_wind_wall.vis then
	local width=yas_wind_wall.left.pos:dist(yas_wind_wall.right.pos)
		if start_pos:dist(end_pos)>yas_wind_wall.vis.pos:dist(end_pos) and start_pos:dist(end_pos)>start_pos:dist(yas_wind_wall.vis.pos) and mathf.dist_line_vector(start_pos, end_pos,yas_wind_wall.vis)<=width then
			return true
		end
   end
   return false
end
local CastQ1=function(Q1pos,unit)
	if player:spellSlot(0).state~=0 or not unit or not sdk.isValidTarget(unit) or not Q1pos then return false end

	local input = {
		  --delay = unit.pos:dist(Q1pos)/2500,
		  delay = 0.25,
		  speed = 2800,
		  width = 80,
		  boundingRadiusMod = 0,
		  collision = {
			hero = false,
			minion = false,
		  },
	}
	
	if misc.CountEnemiesInQ(0.25 ,80 ,1200,Q1pos, player.pos,unit) or wall_check(player,Q1pos) then return false end
	local seg = pred.linear.get_prediction(input, unit , vec2(Q1pos.x,Q1pos.z))
	if seg and player.pos:distSqr(vec3(seg.endPos.x, unit.pos.y, seg.endPos.y)) < 875^2 then
		--if misc.CountEnemiesInQ(unit.pos:dist(Q1pos)/2500,75,2500,Q1pos, seg.endPos,unit) then
		if misc.CountEnemiesInQ2(0.25,75,2500,Q1pos, seg.endPos,unit) then
		return false
		else
		return true
		end
	end

end
local CastE=function(unit)
	if player:spellSlot(2).state~=0 or not unit or not sdk.isValidTarget(unit) then return false end

	local input = {
		  delay = 0.3,
		  speed = 1850,
		  width = 45,
		  boundingRadiusMod = 0,
		  collision = {
			hero = true,
			minion = true,
		  },
	}
	
	local seg = pred.linear.get_prediction(input, unit)
	if seg and seg.endPos and seg.startPos:distSqr(seg.endPos) < 875^2 and not pred.collision.get_prediction(input, seg,unit) and not wall_check(player,vec3(seg.endPos.x,unit.y,seg.endPos.y)) then
		player:castSpell('pos', 2, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
	end
end

local CastEWall = function(target)
	if player:spellSlot(2).state ~= 0 or not target or not sdk.isValidTarget(target) then 
		return false 
	end

	local input = {
		delay = 0.3,
		speed = 1850,
		width = 45,
		boundingRadiusMod = 0,
		collision = {
		  hero = true,
		  minion = true,
		},
  	}

	if target.pos2D:distSqr(player.pos2D) > 875 ^ 2  then 

		local seg = pred.linear.get_prediction(input, target)
		if seg and seg.endPos and not pred.collision.get_prediction(input, seg,target) and not wall_check(player,vec3(seg.endPos.x,target.y,seg.endPos.y)) then

			local start = player
			local endPos = target
			local step = 3 or 3 

			if (start and start ~= vec3(0,0,0)) and (endPos and endPos ~= vec3(0,0,0)) and step > 0 then 

				local distance = sdk.GetDistance(start, endPos)
				for i = 0, 650, step do   
					local VecStart = GeomLib.Vector:new(start)
					local VecEnd = GeomLib.Vector:new(endPos)

					local extend = VecStart + (VecEnd - VecStart):normalized() * i
					if extend and (navmesh.isWall(extend)) then  
						player:castSpell('pos', 2, vec3(seg.endPos.x, target.pos.y, seg.endPos.y))
					end 
				end 
			end 
		end 
	end 
end

local CastQ3=function(unit)
	if player:spellSlot(0).state~=0 or not unit or not sdk.isValidTarget(unit) then return false end

	local input = {
		  delay = 0.25,
		  speed = 1200,
		  width = 75,
		  boundingRadiusMod = 0,
		  collision = {
			hero = true,
			minion = true,
		  },
	}
	
	local seg = pred.linear.get_prediction(input, unit)
	if seg and seg.endPos and not pred.collision.get_prediction(input, seg,unit) and not wall_check(player,vec3(seg.endPos.x,unit.y,seg.endPos.y)) then
		player:castSpell('pos', 0, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
	end
end
local CastQ2=function(unit)
	if player:spellSlot(0).state~=0 or not unit or not sdk.isValidTarget(unit)  then return false end

	if ZoeQPos == vec3(0, 0 , 0) then 
		return 
	end

	local input = {
		  delay = 0.25,
		  speed = 2500,
		  width = 75,
		  boundingRadiusMod = 0,
		  collision = {
			hero = false,
			minion = false,
		  },
	}
	
	local seg = pred.linear.get_prediction(input, unit, vec2(ZoeQPos.x,ZoeQPos.z))
	if seg and seg.endPos then
		if LastQ+0.9<game.time then
			player:castSpell('pos', 0, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
		end
		 
		if unit.type==player.type then
			if not misc.CountEnemiesInQ2(0.25 ,75 ,2500,ZoeQPos,seg.endPos,unit) and not wall_check(ZoeQPos,vec3(seg.endPos.x,unit.y,seg.endPos.y)) then
				if player.pos:distSqr(vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))<875^2 then
					player:castSpell('pos', 0, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
				elseif player.pos:distSqr(vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))<=1425^2 and menu_ts.menu.combo.r:get() and player:spellSlot(3).state==0 then
					if ZoeQPos:distSqr(vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))>650^2 then --0.25*2500 --Rdelay
					player:castSpell('pos', 0, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
					player:castSpell('pos', 3, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
					else
					player:castSpell('pos', 3, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
					player:castSpell('pos', 0, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
					end
				end
			end
		else
			player:castSpell('pos', 0, vec3(seg.endPos.x, unit.pos.y, seg.endPos.y))
		end
		
	end
end
local CastQR1=function(Q1pos,unit)
	if player:spellSlot(0).state~=0 or not unit or not sdk.isValidTarget(unit) or not Q1pos then return false end

	local input = {
		  --delay = unit.pos:dist(Q1pos)/2500,
		  delay = 0.25,
		  speed = 2500,
		  width = 75,
		  boundingRadiusMod = 0,
		  collision = {
			hero = false,
			minion = false,
		  },
	}
	if misc.CountEnemiesInQ(0.25 ,75 ,1200,Q1pos, player.pos,unit) or wall_check(player,Q1pos) then return false end
	local seg = pred.linear.get_prediction(input, unit, vec2(Q1pos.x,Q1pos.z))
	if seg and player.pos:distSqr(vec3(seg.endPos.x, unit.pos.y, seg.endPos.y)) < 1425^2 then
		--if misc.CountEnemiesInQ(unit.pos:dist(Q1pos)/2500,75,2500,Q1pos, seg.endPos,unit) then
		if misc.CountEnemiesInQ2(0.25,75,2500,Q1pos, seg.endPos,unit) then
		return false
		else
		return true
		end
	end

end


local Combo=function()
	
	
	
	if not Target or not sdk.isValidTarget(Target) then return end

	
	if menu_ts.menu.combo.e:get() and player:spellSlot(2).state==0 then
		CastE(Target)

		if menu_ts.menu.combo['e_isWall']:get() then 
			CastEWall(Target)
		end
	end
	
	if menu_ts.menu.combo.w:get() and misc.CountEnemiesNear(player.pos,750)>0 then
	 local Wname=player:spellSlot(1).name:lower()
	 if ZoeItemSM[Wname]==true and game.time>LastR+1 and Target.pos:distSqr(player.pos)<=575^2 then
		player:castSpell('obj', 1, Target)
	 end
	 if ZoeItem[Wname]==true and game.time>LastR+1 and player.health+400<player.maxHealth then
		player:castSpell('self', 1)
	 end
	 if ZoeItemSF[Wname]==true and player.health+400<player.maxHealth then
		player:castSpell('self', 1)
	 end
	 if Wname=="summonermana" and player.mana+400<player.maxMana then
		player:castSpell('self', 1)
	 end
	 if Wname=="summonerhaste" and game.time>LastR+1 then
		player:castSpell('self', 1)
	 end
	 if ZoeItemHL[Wname]==true and game.time>LastR+1 and player.health+400<player.maxHealth then
		player:castSpell('pos', 2, vec3(player.x, player.y, player.z))
	 end
	end
	
	if menu_ts.menu.combo.q:get() and player:spellSlot(0).state==0  then
		if player:spellSlot(0).name=="ZoeQ" then
			
			local Q1pos=Target.pos + (player.pos - Target.pos):norm()*(player.pos:dist(Target.pos)+800)
			local Q2pos,Q3pos = misc.CircleCircleIntersection(player,Target)
				
			if Target.pos:distSqr(player.pos)<=875^2 then
			if CastQ1(Q1pos,Target) then
				player:castSpell('pos', 0, vec3(Q1pos.x, Q1pos.y, Q1pos.z))
				elseif Q2pos and CastQ1(Q2pos,Target) then
				player:castSpell('pos', 0, vec3(Q2pos.x, Q2pos.y, Q2pos.z))
				elseif Q3pos and CastQ1(Q3pos,Target) then
				player:castSpell('pos', 0, vec3(Q3pos.x, Q3pos.y, Q3pos.z))
			end
			elseif Target.pos:distSqr(player.pos)<=1425^2 and menu_ts.menu.combo.r:get() and player:spellSlot(3).state==0 then
				if CastQR1(Q1pos,Target) then
					player:castSpell('pos', 0, vec3(Q1pos.x, Q1pos.y, Q1pos.z))
				elseif Q2pos and CastQR1(Q2pos,Target) then
					player:castSpell('pos', 0, vec3(Q2pos.x, Q2pos.y, Q2pos.z))
				elseif Q3pos and CastQR1(Q3pos,Target) then
					player:castSpell('pos', 0, vec3(Q3pos.x, Q3pos.y, Q3pos.z))
				end
			end
			else
			CastQ2(Target) 
		end
	end
	
end
local Harass=function()
	if not Target or not sdk.isValidTarget(Target) or ((player.mana*100)/player.maxMana<menu_ts.menu.harass.minimana:get()) then return end
	
	if ZoeQPos == vec3(0, 0 , 0) then 
		return 
	end

	if menu_ts.menu.harass.e:get() and player:spellSlot(2).state==0 then
		CastE(Target)
	end
	
	if menu_ts.menu.harass.w:get() and misc.CountEnemiesNear(player.pos,750)>0 then
	 local Wname=player:spellSlot(1).name:lower()
	 if ZoeItemSM[Wname]==true and game.time>LastR+1 and Target.pos:distSqr(player.pos)<=575^2 then
		player:castSpell('obj', 1, Target)
	 end
	 if ZoeItem[Wname]==true and game.time>LastR+1 and player.health+400<player.maxHealth then
		player:castSpell('self', 1)
	 end
	 if ZoeItemSF[Wname]==true and player.health+400<player.maxHealth then
		player:castSpell('self', 1)
	 end
	 if Wname=="summonermana" and player.mana+400<player.maxMana then
		player:castSpell('self', 1)
	 end
	 if Wname=="summonerhaste" and game.time>LastR+1 then
		player:castSpell('self', 1)
	 end
	 if ZoeItemHL[Wname]==true and game.time>LastR+1 and player.health+400<player.maxHealth then
		player:castSpell('pos', 2, vec3(player.x, player.y, player.z))
	 end
	end
	
	if menu_ts.menu.harass.q:get() and player:spellSlot(0).state==0  then
		if player:spellSlot(0).name=="ZoeQ" then
			local Q1pos=Target.pos + (player.pos - Target.pos):norm()*(player.pos:dist(Target.pos)+800)
			local Q2pos,Q3pos =misc.CircleCircleIntersection(player,Target)
				
			if Target.pos:distSqr(player.pos)<=875^2 then
			
			if CastQ1(Q1pos,Target) then
				player:castSpell('pos', 0, vec3(Q1pos.x, Q1pos.y, Q1pos.z))
				elseif CastQ1(Q2pos,Target) then
				player:castSpell('pos', 0, vec3(Q2pos.x, Q2pos.y, Q2pos.z))
				elseif CastQ1(Q3pos,Target) then
				player:castSpell('pos', 0, vec3(Q3pos.x, Q3pos.y, Q3pos.z))
			end
			elseif Target.pos:distSqr(player.pos)<=1425^2 and menu_ts.menu.harass.r:get() and player:spellSlot(3).state==0 then
				if CastQR1(Q1pos,Target) then
					player:castSpell('pos', 0, vec3(Q1pos.x, Q1pos.y, Q1pos.z))
				elseif CastQR1(Q2pos,Target) then
					player:castSpell('pos', 0, vec3(Q2pos.x, Q2pos.y, Q2pos.z))
				elseif CastQR1(Q3pos,Target) then
					player:castSpell('pos', 0, vec3(Q3pos.x, Q3pos.y, Q3pos.z))
				end
			end
			else
			CastQ2(Target) 
		end
	end
end



local process_spell=function(spell)
	if spell and spell.name and spell.owner and spell.owner==player then
		if spell.name=="ZoeR" then
			LastR=game.time
		end

		if spell.name=="ZoeQMissile" then
			ZoeQPos = vec3(spell.endPos.x, spell.endPos.y, spell.endPos.z)
			LastQ=game.time
		end 

		if spell.name=="ZoeQRecast" then
			ZoeQPos = vec3(0,0,0)
			LastQ = 0
		end
	end
	if not menu_ts.menu.misc.Enable:get() or (spell and spell.owner and (spell.owner.team == player.team or spell.owner.type~=player.type)) then return end
	if (spell.target and spell.target==player) or (spell.endPos and spell.endPos:distSqr(player.path.serverPos)<=300^2) then		

		if menu_ts.menu.misc[spell.name] and menu_ts.menu.misc[spell.name]:get() then
			CastE(spell.owner)
		end

	end
	
	
end
--local update_buff=function(buff)

--end
--local remove_buff=function(buff)
	
--end

local Killsteal=function()

for i = 0 , objManager.enemies_n - 1 do 
		local obj = objManager.enemies[i]
		if obj and sdk.isValidTarget(obj) and obj.team ~= player.team then 
			if menu_ts.menu.misc.q:get() and player:spellSlot(0).state==0 then
				if obj.pos:distSqr(player.pos)<1425^2 and obj.health<=misc.QDmg(obj) then
				CastQ2(obj)
				elseif player:spellSlot(0).name=="ZoeQ" and obj.pos:distSqr(player.pos)<800^2 and obj.health<=misc.QKDmg(obj) then
				CastQ3(obj)
				end
			elseif menu_ts.menu.misc.e:get() and player:spellSlot(2).state==0 and obj.pos:distSqr(player.pos)<=875^2 and obj.health<=misc.EDmg(obj) and (player:spellSlot(0).state ~= 0 or not menu_ts.menu.kill.q:get()) then
				CastE(obj,true)
			end
		end
end

end
local Flee=function()
	if not orb.menu.combat.key:get() and not orb.menu.hybrid.key:get() then
		player:move(mousePos)
	end
	if Target and sdk.isValidTarget(Target) and menu_ts.menu.misc.useE:get() then
		CastE(Target)
	end
end
local get_action=function()

   	if player.isDead then
		return 
	end

	Target = menu_ts.TS.target
	
	if orb.menu.combat.key:get() then
		Combo()		
	elseif orb.menu.hybrid.key:get() then
		Harass()
	elseif menu_ts.menu.misc.flee:get() then
		Flee()	
	end

	
	Killsteal()

end


local on_draw=function()
	if player.isDead then return end

	if menu_ts.menu.display.Q:get() and player.isOnScreen then
		if player:spellSlot(0).state==0 then
		graphics.draw_circle_xyz(player.x,player.y,player.z, 875, 1, 0xFF3B92EF, 100)
		else
		graphics.draw_circle_xyz(player.x,player.y,player.z, 875, 1, 0xFF878486, 100)
		end
	end
	if menu_ts.menu.display.E:get() and player.isOnScreen and not menu_ts.menu.display.Q:get() then
		if player:spellSlot(2).state==0 then
		graphics.draw_circle_xyz(player.x,player.y,player.z, 875, 1, 0xFF3B92EF, 100)
		else
		graphics.draw_circle_xyz(player.x,player.y,player.z, 875, 1, 0xFF878486, 100)
		end
	end
	if menu_ts.menu.display.R:get() and player:spellSlot(3).state==0 and player.isOnScreen then
		graphics.draw_circle_xyz(player.x,player.y,player.z, 1425, 2, 0xFF878486, 100)
	end
end
local create_mis=function(missile)
  if missile and missile.spell.owner and missile.spell.owner.team~=player.team then
    if missile.spell.name:lower() == 'yasuowmovingwallmisl' then
      yas_wind_wall.left = missile
    elseif missile.spell.name:lower() == 'yasuowmovingwallmisvis' then
      yas_wind_wall.vis = missile
    elseif missile.spell.name:lower() == 'yasuowmovingwallmisr' then
      yas_wind_wall.right = missile
    end
  end
end
local create_obj=function(obj)

end

local delete_obj=function(obj)

	if (yas_wind_wall.left and obj==yas_wind_wall.left) or (yas_wind_wall.right and obj==yas_wind_wall.right)  then
		yas_wind_wall={}
	end

end
return {
get_action=get_action,
process_spell=process_spell,
--update_buff=update_buff,
--remove_buff=remove_buff,
on_draw=on_draw,
create_obj=create_obj,
delete_obj=delete_obj,
create_mis=create_mis,
}