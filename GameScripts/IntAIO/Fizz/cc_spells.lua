local cc_spells = {
  ["Aatrox"] = {
    [0] = "Q", --knockup
    [2] = "E" --slow
  },
  ["Ahri"] = {
    [2] = "E" --charm
  },
  ["Akali"] = {
    [1] = "E" --slow
  },
  ["Alistar"] = {
    [0] = "Q", --knockup
    [1] = "E", --knockback
    --[[2 --5stack = stun]]
  },
  ["Amumu"] = {
    [0] = "Q", --stun
    [3] = "R" --disarm + root
  },
  ["Anivia"] = {
    [0] = "Q", --stun
    [3] = "R" --slow
  },
  ["Annie"] = {
    --[[passive -> 5th ability = stun]]
  },
  ["Ashe"] = {
    --[[passive -> slow]]
    [3] = "R" --stun
  },
  ["AurelionSol"] = {
    [0] = "Q", --stun
    [3] = "R" --slow + knockback
  },
  ["Azir"] = {
    [0] = "Q", --slow
    [3] = "R" --knockback
  },
  ["Bard"] = {
    [0] = "Q", --slow (stun if hits 2nd target or wall)
    [3] = "R" --stasis
  },
  ["Blitzcrank"] = {
    [0] = "Q", --stun
    [2] = "E", --knockup
    [3] = "R" --silence
  },
  ["Brand"] = {
    [0] = "Q" --with passive = stun
  },
  ["Braum"] = {
    --[[passive -> 4stacks = stun]]
    [0] = "Q", --slow
    [3] = "R" --knockup + slow
  },
  ["Caitlyn"] = {
    [1] = "W", --root
    [2] = "E" --slow
  },
  ["Camille"] = {
    [1] = "W", --out half of cone = slow
    [2] = "E" --2nd cast = stun
  },
  ["Cassiopeia"] = {
    [1] = "W", --grounded + slow
    [3] = "R" -- slow (isFacing = stun)
  },
  ["ChoGath"] = {
    [0] = "Q", --knockup
    [1] = "W", --silence
    [2] = "E" --slow
  },
  ["Corki"] = {
    [1] = "W" --special delivery = knockback + slow
  },
  ["Darius"] = {
    [1] = "W", --slow
    [2] = "E" --slow
  },
  ["Diana"] = {
    [2] = "E" --knockup+slow
  },
  ["Draven"] = {
    [2] = "E" --knockback+slow
  },
  ["DrMundo"] = {
    [0] = "Q" --slow
  },
  ["Ekko"] = {
    [0] = "Q", --slow
    [1] = "W" --slow (ekko in sphere on detonate = stun)
  },
  ["Elise"] = {
    [2] = "E" --human form: stun
  },
  ["Evelynn"] = {
    [1] = "W" --slow (Expunging = charm)
  },
  ["Ezreal"] = {},
  ["FiddleSticks"] = {
    [0] = "Q", --flee + slow
    [2] = "E" --silence
  },
  ["Fiora"] = {
    [1] = "W" --slow (if parries at least one immobilizing effect = stun)
  },
  ["Fizz"] = {
    [2] = "E", --1st cast = slow
    [3] = "R" --slow + knockup (surrounding objs are knockedback and slowed)
  },
  ["Galio"] = {
    [1] = "W", --taun
    [2] = "E", --knockup
    [3] = "R" --knockup
  },
  ["Gangplank"] = {
    [2] = "E", --slow
    [3] = "R" --slow
  },
  ["Garen"] = {
    [0] = "Q" --silence
  },
  ["Gnar"] = {
    [0] = "Q", --[mini] slow / [mega] slow
    [1] = "W", --[mega] stun
    [2] = "E", --[mini] slow / [mega] slow
    [3] = "R" --[mega] knockup + slow (stun instead of slow if hit wall)
  },
  ["Gragas"] = {
    [0] = "Q", --slow
    [2] = "E", --knockback + stun
    [3] = "R" --knockback
  },
  ["Graves"] = {
    [1] = "W" --slow
  },
  ["Hecarim"] = {
    [2] = "E", --knockback
    [3] = "R" --flee + slow
  },
  ["Heimerdinger"] = {
    [2] = "E" --slow (center = stun)
  },
  ["Illaoi"] = {
    [2] = "E" --tether break = slow
  },
  ["Irelia"] = {
    [2] = "E",
    [3] = "R" --slow (if player.health <= enemy.health then stun instead)
  },
  ["Ivern"] = {
    [0] = "Q", --root
    [2] = "E", --end of duration = slow
    [3] = "R" --2stacks = knockup
  },
  ["Janna"] = {
    [0] = "Q", --knockup
    [1] = "W" --slow
  },
  ["JarvanIV"] = {
    [0] = "Q", --connects to E = knockup
    [1] = "W" --slow
  },
  ["Jax"] = {
    [2] = "E" --stun on reactivation
  },
  ["Jayce"] = {
    [0] = "Q", --[hammer] slow
    [2] = "E" --[hammer] knockback
  },
  ["Jhin"] = {
    [1] = "W", --target 'caught out' = root
    [2] = "E", --slow
    [3] = "R" --slow
  },
  ["Jinx"] = {
    [1] = "W", --slow
    [2] = "E" --root
  },
  ["KaiSa"] = {},
  ["Kalista"] = {
    [2] = "E", --slow
    [3] = "R" --knockup
  },
  ["Karma"] = {
    [0] = "Q", --slow
    [1] = "W" --root
  },
  ["Karthus"] = {
    [1] = "W", --slow
    [3] = "R"
  },
  ["Kassadin"] = {
    [2] = "E" --slow
  },
  ["Katarina"] = {},
  ["Kayle"] = {
    [0] = "Q" --slow
  },
  ["Kayn"] = {
    [0] = "Q", --slow / [rhaast] +knockup
    [2] = "E" --[assassin] slow
  },
  ["Kennen"] = {
    --[[passive -> 3stacks = stun]]
  },
  ["KhaZix"] = {
    [1] = "W" --evolved = slow
  },
  ["Kindred"] = {
    [1] = "W", --slow
    [2] = "E" --slow
  },
  ["Kled"] = {
    [0] = "Q", --[mounted] slow
    [3] = "R" --[mounted] knockback
  },
  ["KogMaw"] = {
    [2] = "E" --slow
  },
  ["Leblanc"] = {
    [2] = "E" --root
  },
  ["LeeSin"] = {
    [2] = "E", --E2 = slow
    [3] = "R" --root + knockback (enemies hit by the enemy-turned-projectile receive knockup)
  },
  ["Leona"] = {
    [0] = "Q", --slow
    [2] = "E", --root
    [3] = "R" --slow (center = stun)
  },
  ["Lissandra"] = {
    [0] = "Q", --slow
    [1] = "W", --root
    [3] = "R" --stun (slow nearby enemies)
  },
  ["Lucian"] = {},
  ["Lulu"] = {
    [0] = "Q", --slow
    [1] = "W", --polymorph
    [3] = "R" --knockup (slow nearby enemies)
  },
  ["Lux"] = {
    [0] = "Q", --root
    [2] = "E" --slow
  },
  ["Malphite"] = {
    [1] = "W", --slow
    [3] = "R" --knockup
  },
  ["Malzahar"] = {
    [0] = "Q", --silence
    [3] = "R" --supression
  },
  ["Maokai"] = {
    [0] = "Q", --slow + knockback
    [1] = "W", --root
    [2] = "E", --slow
    [3] = "R" --root
  },
  ["MasterYi"] = {},
  ["MissFortune"] = {
    [2] = "E" --slow
  },
  ["MonkeyKing"] = {
    [3] = "R" --knockup
  },
  ["Mordekaiser"] = {},
  ["Morgana"] = {
    [0] = "Q",
    [3] = "R"
  }, --root, slow+stun
  ["Nami"] = {
    [0] = "Q", --knockup (suspension)
    [2] = "E", --slow
    [3] = "R" --knockup + slow
  },
  ["Nasus"] = {
    [1] = "W" --slow
  },
  ["Nautilus"] = {
    [0] = "Q", --stun
    [2] = "E", --slow
    [3] = "R" --knockup + stun
  },
  ["Nidalee"] = {},
  ["Nocturne"] = {
    [2] = "E" --flee + slow
  },
  ["Nunu"] = {
    [2] = "E", --slow
    [3] = "R" --slow
  },
  ["Olaf"] = {
    [0] = "Q" --slow
  },
  ["Orianna"] = {
    [1] = "W", --slow
    [3] = "R" --knockup
  },
  ["Ornn"] = {
    [0] = "Q", --slow + knockback
    [2] = "E", --knockup
    [3] = "R" --slow + knockup
  },
  ["Pantheon"] = {
    [1] = "W", --stun
    [3] = "R" --slow
  },
  ["Poppy"] = {
    [0] = "Q", --slow
    [1] = "W", --knockdown
    [2] = "E", --knockup + stun
    [3] = "R" --knockback (cancel channel = knockup)
  },
  ["Quinn"] = {
    [0] = "Q", --nearsight
    [2] = "E" --knockback + slow
  },
  ["Rakan"] = {
    [1] = "W", --knockup
    [3] = "R" --charm + slow
  },
  ["Rammus"] = {
    [0] = "Q", --knockback + slow
    [1] = "W", --slow
    [2] = "E", --taunt
    [3] = "R" --slow
  },
  ["RekSai"] = {
    [1] = "W" --[burrowed] knockup
  },
  ["Renekton"] = {
    [1] = "W" --stun
  },
  ["Rengar"] = {
    [2] = "E" --slow/[empowered] root
  },
  ["Riven"] = {
    [0] = "Q", --Q3 = knockup
    [1] = "W" --root
  },
  ["Rumble"] = {
    [2] = "E", --slow
    [3] = "R" --slow
  },
  ["Ryze"] = {
    [1] = "W" --root
  },
  ["Sejuani"] = {
    [0] = "Q", --knockup
    [1] = "W", --slow
    [2] = "E", --stun
    [3] = "R" --stun + slow
  },
  ["Shaco"] = {
    [1] = "W", --flee
    [2] = "E", --slow
    [3] = "R" --fear
  },
  ["Shen"] = {
    [2] = "E" --taunt
  },
  ["Shyvana"] = {
    [3] = "R" --knockback/knockdown
  },
  ["Singed"] = {
    [1] = "W", --slow + grounded
    [2] = "E" --knockup (rooted if flung into W-area)
  },
  ["Sion"] = {
    [0] = "Q", --slow (knockup after 1 second)
    [2] = "E", --slow
    [3] = "R" --slow (stun if hits enemy)
  },
  ["Sivir"] = {},
  ["Skarner"] = {
    [2] = "E", --slow (basic attack on target with Crystal Venom = stun)
    [3] = "R" --root + supression
  },
  ["Sona"] = {
    [2] = "E", --[power cord] slow
    [3] = "R" --stun
  },
  ["Soraka"] = {
    [0] = "Q", --slow
    [2] = "E" --silence (root on detonation if enemy inside)
  },
  ["Swain"] = {
    [1] = "W", --slow
    [2] = "E", --stun
  },
  ["Syndra"] = {
    [1] = "W", --slow
    [2] = "E" --knockback + stun
  },
  ["TahmKench"] = {
    [0] = "Q", --slow / 3 passive stack = stun
    [1] = "W" --3 passive stacks = slow + supression + nearsight (W2 = stun)
  },
  ["Taliyah"] = {
    [1] = "W", --knockup
    [2] = "E", --slow
    [3] = "R" --knockback
  },
  ["Talon"] = {
    [1] = "W" --slow
  },
  ["Taric"] = {
    [2] = "E" --stun
  },
  ["Teemo"] = {
    [0] = "Q" --blind
  },
  ["Thresh"] = {
    [0] = "Q", --stun
    [2] = "E", --knockup + slow
    [3] = "R" --slow
  },
  ["Tristana"] = {
    [1] = "W", --slow
    [3] = "R" --knockback
  },
  ["Trundle"] = {
    [0] = "Q", --slow
    [2] = "E" --slow
  },
  ["Tryndamere"] = {
    [1] = "W" --slow
  },
  ["TwistedFate"] = {
    [1] = "W" --[red] slow / [gold] stun
  },
  ["Twitch"] = {
    [1] = "W" --slow
  },
  ["Udyr"] = {
    [2] = "E" --stun
  },
  ["Urgot"] = {
    [0] = "Q", --slow
    [2] = "E", --knockback (collide with target = knockup + stun)
    [3] = "R" --slow + supression (surrounding enemies = flee + slow)
  },
  ["Varus"] = {
    [2] = "E", --slow
    [3] = "R" --root
  },
  ["Vayne"] = {
    [2] = "E" --knockback (collide with terrain = stun)
  },
  ["Veigar"] = {
    [2] = "E" --stun
  },
  ["VelKoz"] = {
    [0] = "Q", --slow
    [2] = "E", --knockup (enemies near are knockback)
    [3] = "R" --slow
  },
  ["Vi"] = {
    [0] = "Q", --knockback
    [3] = "R" --knockup (enemies in path are knockback)
  },
  ["Viktor"] = {
    [1] = "W" --stun
  },
  ["Vladimir"] = {
    [1] = "W" --slow
  },
  ["Volibear"] = {
    [0] = "Q", --knockup
    [2] = "E" --slow
  },
  ["Warwick"] = {
    [2] = "E", --flee + slow
    [3] = "R" --supression
  },
  ["Xayah"] = {
    [2] = "E" --root
  },
  ["Xerath"] = {
    [1] = "W", --slow
    [2] = "E" --stun
  },
  ["XinZhao"] = {
    [0] = "Q", --third aa = knockup
    [1] = "W", --slow
    [2] = "E", --slow
    [3] = "R" --knockback/knockup + stun
  },
  ["Yasuo"] = {
    [0] = "Q", --Q3 = knockup
    [3] = "R" --suspend
  },
  ["Yorick"] = {
    [2] = "E" --slow
  },
  ["Zac"] = {
    [0] = "Q", --slow
    [2] = "E", --knockup
    [3] = "R" --slow + knockback
  },
  ["Zed"] = {
    [2] = "E", --slow
    [3] = "R"
  },
  ["Ziggs"] = {
    [1] = "W", --knockback
    [2] = "E", --slow
    [3] = "R",
  },
  ["Zilean"] = {
    [0] = "Q", --2stack = stun
    [2] = "E" --slow
  },
  ["Zoe"] = {
    [2] = "E" --slow + sleep
  },
  ["Zyra"] = {
    [2] = "E", --root
    [3] = "R" --knockup
  }
}

return cc_spells