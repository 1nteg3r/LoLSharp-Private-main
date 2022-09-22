#pragma once

bool sortHealth(CObject* a, CObject* b)
{
	return a->MaxHealth() > b->MaxHealth();
}
bool IsItemReady(int slot)
{
	return me->GetSpellBook()->GetSpellSlotByID(slot)->IsItemReady();
}

bool IsReady(int slot)
{
	return slot > -1 && me->GetSpellBook()->GetSpellSlotByID(slot)->IsReady() /*&& me->GetSpellState(slot) == SpellState::Ready*/;
}

float ManaCost(int slot)
{
	return me->GetSpellBook()->GetSpellSlotByID(slot)->GetSpellData()->ManaCost(me->GetSpellBook()->GetSpellSlotByID(slot)->Level());
}


struct castspell_struct
{
	int state = 0;
};
std::map<int, int>SpellLastTime;

castspell_struct castSpellOnce;

castspell_struct castSpell1;
bool CastSpell(int SlotID, bool asap = false, bool blockspell = true) {
	if (castSpellOnce.state == 2 || blockspell && (justevade->BlockAttack && justevade->Block) || me->IsCasting() && !asap || global::blockOrbAttack)
	{
		return false;
	}

	if (SlotID < 4)
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!caststate[SlotID])
			return false;
	}

	if (((IsReady(SlotID) && SlotID < 6) || (IsItemReady(SlotID) && SlotID > 5)) && (orbwalker->CheckInterrupt() || asap) && me->IsAlive() && !Engine::IsChatOpen())
	{
		if (SpellLastTime.count(SlotID))
		{
			if (Engine::GameTimeTickCount() - SpellLastTime[SlotID] < 200)
			{
				return false;
			}
		}
		else
		{
			SpellLastTime.insert({ SlotID,Engine::GameTimeTickCount() });
		}
		SpellLastTime[SlotID] = Engine::GameTimeTickCount();

		auto key = CheckKey(SlotID);
		if (key)
		{
			//BlockInput(true);
			CastSpellEvent(nullptr);

			if (orbwalker->UseNormalCast->Value)
				PressKeyModShift(key);
			else
				KeyPress(key);

			/*castSpellOnce.state = 2;
			_DelayAction->Add(150, []() {
				if (castSpellOnce.state == 2)
				{
					castSpellOnce.state = 1;
				}
			});*/

			//BlockInput(false);
			return true;
		}
	}

	return false;
}
castspell_struct castSpell2;
bool CastSpell(int SlotID, Vector3 pos, bool asap, bool blockspell) {
	if (castSpellOnce.state == 2 || blockspell && (justevade->BlockAttack && justevade->Block) || me->IsCasting() && !asap || !global::mousereset || global::blockOrbAttack)
		return false;

	if (SlotID < 4)
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!caststate[SlotID])
			return false;
	}

	if (((IsReady(SlotID) && SlotID < 6) || (IsItemReady(SlotID) && SlotID > 5)) && (orbwalker->CheckInterrupt() || asap) && me->IsAlive() && !Engine::IsChatOpen())
	{
		Vector3 W2S_buffer = pos;

		if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
		{
			if (SpellLastTime.count((int)SlotID))
			{
				if (Engine::GameTimeTickCount() - SpellLastTime[(int)SlotID] < 200)
				{
					return false;
				}
			}
			else
			{
				SpellLastTime.insert({ (int)SlotID,Engine::GameTimeTickCount() });
			}
			SpellLastTime[(int)SlotID] = Engine::GameTimeTickCount();

			auto key = CheckKey(SlotID);
			if (key)
			{
				//BlockInput(true);
				global::mousereset = false;
				CastSpellEvent(nullptr);
				GetCursorPos(&previousMousePos);
				MoveMouse(W2S_buffer.x, W2S_buffer.y);

				std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(5)));
				if (orbwalker->UseNormalCast->Value)
					PressKeyModShift(key);
				else
					KeyPress(key);

				std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(30)));

				ResetMouse(previousMousePos.x, previousMousePos.y);
				/*castSpellOnce.state = 2;
				_DelayAction->Add(150, []() {
					if (castSpellOnce.state == 2)
					{
						castSpellOnce.state = 1;
					}
				});*/
				//BlockInput(false);
				return true;
			}
		}

	}

	return false;
}

bool ReleaseSpell(int SlotID, Vector3 pos)
{
	if (castSpellOnce.state == 2 || !global::mousereset || !me->IsChargeing())
		return false;

	if (SlotID < 4)
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!caststate[SlotID])
			return false;
	}

	//if (IsReady(SlotID))
	{

		Vector3 W2S_buffer = pos;

		if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
		{

			auto key = CheckKey(SlotID);
			if (key)
			{
				//BlockInput(true);
				global::mousereset = false;
				GetCursorPos(&previousMousePos);
				MoveMouse(W2S_buffer.x, W2S_buffer.y);
				std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(5)));
				KeyUp(key);
				std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(30)));
				ResetMouse(previousMousePos.x, previousMousePos.y);
				/*castSpellOnce.state = 2;
				_DelayAction->Add(150, []() {
					if (castSpellOnce.state == 2)
					{
						castSpellOnce.state = 1;
					}
					});*/
				//BlockInput(false);
				return true;
			}


		}
	}

	return false;
}

bool ReleaseSpell2(int SlotID, Vector3 pos)
{
	if (castSpellOnce.state == 2)
		return false;

	if (SlotID < 4)
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!caststate[SlotID])
			return false;
	}

	if (IsReady(SlotID))
	{
		Vector3 W2S_buffer = pos;

		if (W2S_buffer.x != 0 && W2S_buffer.y != 0)
		{
			auto key = CheckKey(SlotID);
			if (key)
			{
				if (SpellLastTime.count((int)SlotID))
				{
					if (Engine::GameTimeTickCount() - SpellLastTime[(int)SlotID] < 200)
					{
						return false;
					}
				}
				else
				{
					SpellLastTime.insert({ (int)SlotID,Engine::GameTimeTickCount() });
				}
				SpellLastTime[(int)SlotID] = Engine::GameTimeTickCount();

				if (MouseClick(false, W2S_buffer.x, W2S_buffer.y))
				{
					Sleep(100);
					if (orbwalker->UseNormalCast->Value)
						PressKeyModShift(key);
					else
						KeyPress(key);

					//BlockInput(false);
					return true;
				}
			}
		}
	}

	return false;
}

castspell_struct castSpell3;
bool CastSpell(int SlotID, CObject* obj, bool asap = false, bool blockspell = true) {
	if (castSpellOnce.state == 2 || blockspell && (justevade->BlockAttack && justevade->Block) || me->IsCasting() && !asap || !global::mousereset || global::blockOrbAttack)
		return false;

	if (SlotID < 4)
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!caststate[SlotID])
			return false;
	}

	if (!obj->IsValidTarget())
		return false;

	if (((IsReady(SlotID) && SlotID < 6) || (IsItemReady(SlotID) && SlotID > 5)) && (orbwalker->CheckInterrupt() || asap) && me->IsAlive() && !Engine::IsChatOpen())
	{
		float range = me->GetSpellBook()->GetSpellSlotByID(SlotID)->GetRange();
		if (me->Position().IsInRange(obj->Position(), range + obj->BoundingRadius() + global::LocalData->gameplayRadius))
		{
			auto pos = obj->Position();
			bool hero = obj->IsHero();

			Vector3 W2S_buffer = Engine::WorldToScreen(pos);

			if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
			{
				if (SpellLastTime.count((int)SlotID))
				{
					if (Engine::GameTimeTickCount() - SpellLastTime[(int)SlotID] < 200)
					{
						return false;
					}
				}
				else
				{
					SpellLastTime.insert({ (int)SlotID,Engine::GameTimeTickCount() });
				}
				SpellLastTime[(int)SlotID] = Engine::GameTimeTickCount();

				auto key = CheckKey(SlotID);
				if (key)
				{
					//BlockInput(true);
					global::mousereset = false;
					CastSpellEvent(obj);
					GetCursorPos(&previousMousePos);
					if (hero)
					{
								Engine::SetTargetOnlyChampions(true);
					}

					MoveMouse(W2S_buffer.x, W2S_buffer.y);

					std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(5)));
					if (orbwalker->UseNormalCast->Value)
						PressKeyModShift(key);
					else
						KeyPress(key);

					std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(30)));


					ResetMouse(previousMousePos.x, previousMousePos.y);
					/*castSpellOnce.state = 2;
					_DelayAction->Add(150, []() {
						if (castSpellOnce.state == 2)
						{
							castSpellOnce.state = 1;
						}
					});*/

					if (hero)
					{
						Engine::SetTargetOnlyChampions(false);
					}
					//BlockInput(false);
					return true;

				}


			}
		}
	}
	return false;
}

castspell_struct castSpell4;
bool CastSpell(CObject* obj, int SlotID, std::string name, bool asap = false, bool blockspell = true) {
	if (castSpellOnce.state == 2 || blockspell && (justevade->BlockAttack && justevade->Block) || me->IsCasting() && !asap || !global::mousereset || global::blockOrbAttack)
		return false;

	if (SlotID < 4)
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!caststate[SlotID])
			return false;
	}

	if (!obj->IsValidTarget())
		return false;

	if (((IsReady(SlotID) && SlotID < 6) || (IsItemReady(SlotID) && SlotID > 5)) && (orbwalker->CheckInterrupt() || asap) && me->IsAlive() && !Engine::IsChatOpen())
	{
		PredictionInput pi;
		auto hash = fnv::hash_runtime(name.c_str());
		pi.Aoe = false;
		pi.Collision = SpellDatabase[hash].collision;
		pi.Delay = SpellDatabase[hash].delay;
		pi.Range = SpellDatabase[hash].range;
		pi.From(me->ServerPosition());
		pi.Radius = SpellDatabase[hash].radius;
		pi.Unit = obj;
		pi.Speed = SpellDatabase[hash].speed;

		if (SpellDatabase[hash].type == "circular")
			pi.Type = SkillshotType::SkillshotCircle;

		if (SpellDatabase[hash].type == "conic")
			pi.Type = SkillshotType::SkillshotCone;

		auto pO = prediction->GetPrediction(pi);
		Vector3 W2S_buffer = Engine::WorldToScreen(pO.CastPosition());

		HitChance hitcc = HitChance::High;

		if (SlotID == 0)
			hitcc = (HitChance)((int)prediction->hitQ + 3);
		else if (SlotID == 1)
			hitcc = (HitChance)((int)prediction->hitW + 3);
		else if (SlotID == 2)
			hitcc = (HitChance)((int)prediction->hitE + 3);
		else if (SlotID == 3)
			hitcc = (HitChance)((int)prediction->hitR + 3);

		if (pO.HitChance() >= hitcc)
		{
			if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
			{
				if (SpellLastTime.count((int)SlotID))
				{
					if (Engine::GameTimeTickCount() - SpellLastTime[(int)SlotID] < 200)
					{
						return false;
					}
				}
				else
				{
					SpellLastTime.insert({ (int)SlotID,Engine::GameTimeTickCount() });
				}
				SpellLastTime[(int)SlotID] = Engine::GameTimeTickCount();

				auto key = CheckKey(SlotID);
				if (key)
				{
					//BlockInput(true);
					global::mousereset = false;
					CastSpellEvent(obj);
					GetCursorPos(&previousMousePos);
					MoveMouse(W2S_buffer.x, W2S_buffer.y);

					std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(5)));
					if (orbwalker->UseNormalCast->Value)
						PressKeyModShift(key);
					else
						KeyPress(key);

					std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(30)));


					ResetMouse(previousMousePos.x, previousMousePos.y);

					/*castSpellOnce.state = 2;
					_DelayAction->Add(pi.Delay * 1000, []() {
						if (castSpellOnce.state == 2)
						{
							castSpellOnce.state = 1;
						}
					});*/
					//BlockInput(false);
					return true;
				}
			}
		}

	}
	return false;
}

castspell_struct castSpell5;
bool CastSpell(CObject* obj, int SlotID, PredictionInput& spell, bool asap = false, HitChance hitchance = HitChance::Impossible, bool blockspell = true) {
	if (castSpellOnce.state == 2 || blockspell && (justevade->BlockAttack && justevade->Block) || me->IsCasting() && !asap || !global::mousereset || global::blockOrbAttack)
		return false;

	if (SlotID < 4)
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!caststate[SlotID])
			return false;
	}

	if (!obj->IsValidTarget())
		return false;

	if (((IsReady(SlotID) && SlotID < 6) || (IsItemReady(SlotID) && SlotID > 5)) && (orbwalker->CheckInterrupt() || asap) && me->IsAlive() && !Engine::IsChatOpen())
	{

		auto pO = prediction->GetPrediction(obj, spell);
		Vector3 W2S_buffer = Engine::WorldToScreen(pO.CastPosition());

		if (hitchance == HitChance::Impossible)
		{
			if (SlotID == 0)
				hitchance = (HitChance)((int)prediction->hitQ + 3);
			else if (SlotID == 1)
				hitchance = (HitChance)((int)prediction->hitW + 3);
			else if (SlotID == 2)
				hitchance = (HitChance)((int)prediction->hitE + 3);
			else if (SlotID == 3)
				hitchance = (HitChance)((int)prediction->hitR + 3);
		}

		if (pO.HitChance() >= hitchance)
		{
			if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
			{
				if (SpellLastTime.count((int)SlotID))
				{
					if (Engine::GameTimeTickCount() - SpellLastTime[(int)SlotID] < 200)
					{
						return false;
					}
				}
				else
				{
					SpellLastTime.insert({ (int)SlotID,Engine::GameTimeTickCount() });
				}
				SpellLastTime[(int)SlotID] = Engine::GameTimeTickCount();

				auto key = CheckKey(SlotID);
				if (key)
				{
					//BlockInput(true);
					global::mousereset = false;
					CastSpellEvent(obj);
					GetCursorPos(&previousMousePos);
					MoveMouse(W2S_buffer.x, W2S_buffer.y);

					std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(5)));
					if (orbwalker->UseNormalCast->Value)
						PressKeyModShift(key);
					else
						KeyPress(key);

					std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(30)));


					ResetMouse(previousMousePos.x, previousMousePos.y);
					spell.LastCastAttemptT = Engine::TickCount();

					/*castSpellOnce.state = 2;
					_DelayAction->Add(spell.Delay * 1000, []() {
						if (castSpellOnce.state == 2)
						{
							castSpellOnce.state = 1;
						}
					});*/
					//BlockInput(false);
					return true;
				}
			}
		}

	}
	return false;
}

castspell_struct castSpell6;
bool CastSpellMM(int SlotID, Vector3 pos, bool asap = false, bool blockspell = true) {
	if (castSpellOnce.state == 2 || blockspell && (justevade->BlockAttack && justevade->Block) || me->IsCasting() && !asap || !global::mousereset || global::blockOrbAttack)
		return false;

	if (SlotID < 4)
	{
		auto caststate = me->GetSpellBook()->GetCastState();
		if (!caststate[SlotID])
			return false;
	}

	if (((IsReady(SlotID) && SlotID < 6) || (IsItemReady(SlotID) && SlotID > 5)) && (orbwalker->CheckInterrupt() || asap) && me->IsAlive() && !Engine::IsChatOpen())
	{
		if (me->GetSpellBook()->GetActiveSpellEntry()->IsCastingSpell())
			return false;

		Vector3 W2S_buffer = pos;

		if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
		{
			if (SpellLastTime.count((int)SlotID))
			{
				if (Engine::GameTimeTickCount() - SpellLastTime[(int)SlotID] < 200)
				{
					return false;
				}
			}
			else
			{
				SpellLastTime.insert({ (int)SlotID,Engine::GameTimeTickCount() });
			}
			SpellLastTime[(int)SlotID] = Engine::GameTimeTickCount();

			auto key = CheckKey(SlotID);
			if (key)
			{
				//BlockInput(true);
				global::mousereset = false;
				CastSpellEvent(nullptr);
				GetCursorPos(&previousMousePos);
				MoveMouse(W2S_buffer.x, W2S_buffer.y);

				std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(5)));
				if (orbwalker->UseNormalCast->Value)
					PressKeyModShift(key);
				else
					KeyPress(key);

				std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(30)));


				ResetMouse(previousMousePos.x, previousMousePos.y);

				/*castSpellOnce.state = 2;
				_DelayAction->Add(250, []() {
					if (castSpellOnce.state == 2)
					{
						castSpellOnce.state = 1;
					}
				});*/
				//BlockInput(false);
				return true;
			}
		}

	}

	return false;
}
castspell_struct castSpellpush;
void CastSpell(int SlotID, Vector3 source1, Vector3 destination1)
{
	if (castSpellpush.state == 2 || !global::mousereset || global::blockOrbAttack)
		return;

	if (IsReady(SlotID) && me->IsAlive() && !Engine::IsChatOpen())
	{
		if (SlotID < 5)
		{
			auto caststate = me->GetSpellBook()->GetCastState();
			if (!caststate[SlotID])
				return;
		}

		Vector3 source = Engine::WorldToScreen(source1);
		Vector3 destination = Engine::WorldToScreen(destination1);
		if (source.x != 0 && source.y != 0 && !Engine::IsOutboundScreen(source))
		{
			auto key = CheckKey(SlotID);

			if (key && GetCursorPos(&previousMousePos))
			{
				global::mousereset = false;
				CastSpellEvent(nullptr);
				MoveMouse(source.x, source.y);
				KeyDown(key);
				std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(8)));
				MoveMouse(destination.x, destination.y);
				KeyUp(key);
				std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(30)));
				ResetMouse(previousMousePos.x, previousMousePos.y);

				castSpellpush.state = 2;
				_DelayAction->Add(250, []() {
					if (castSpellpush.state == 2)
					{
						castSpellpush.state = 1;
					}
					});
			}
		}
	}
}

//
//bool CastSpellLineVIP(CObject* obj, int SlotID, std::string name, bool collision = false, bool wait = true) {
//	bool success = false;
//
//	if (me->GetSpellBook()->GetSpellSlotByID(SlotID)->IsReady() && orbwalker->CheckInterrupt() && me->IsAlive() && !Engine::IsChatOpen())
//	{
//		PredictionInput pI;
//		auto hash = fnv::hash_runtime(name.c_str());
//		pI.Speed = SpellDatabase[hash].speed;
//		pI.Range = SpellDatabase[hash].range;
//		pI.Delay = SpellDatabase[hash].delay;
//		pI.Radius = SpellDatabase[hash].radius;
//		pI.AddHitBox = SpellDatabase[hash].hitbox;
//
//		if (me->Position().Distance(obj->Position()) <= pI.Range + obj->BoundingRadius())
//		{
//			Vector2 s = me->Pos2D();
//
//			Unit u;
//			u.Position = obj->Pos2D();
//			u.BoundingRadius = obj->BoundingRadius();
//			u.MovementSpeed = obj->MoveSpeed();
//			u.Paths = obj->GetWaypoints();
//
//			PredictionOutput pO = Prediction().PredictPosition(s, u, pI);
//			Vector3 W2S_buffer = Engine::WorldToScreen(XPolygon::To3D(pO.CastPos));
//			if (!collision || (collision && !XPolygon::IsCollisioned(XPolygon::To3D(pO.CastPos), pI.Radius)))
//			{
//				if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
//				{
//					if (Engine::GameGetTickCount() - last_castorder > humanizer_delay)
//					{
//						auto key = CheckKey(SlotID);
//						if (key && GetCursorPos(&previousMousePos))
//						{
//							MoveMouse(W2S_buffer.x, W2S_buffer.y);
//							std::this_thread::sleep_for(std::chrono::milliseconds(20));
//							KeyPress(key);
//							success = true;
//							std::this_thread::sleep_for(std::chrono::milliseconds(20));
//							ResetMouse(previousMousePos.x, previousMousePos.y);
//						}
//
//						last_castorder = Engine::GameGetTickCount();
//					}
//				}
//			}
//		}
//	}
//	int temp = 0;
//	while (success && wait)
//	{
//		temp++;
//		if (temp > 50)
//			break;
//
//		if (!me->GetSpellBook()->GetSpellSlotByID(SlotID)->IsReady())
//			break;
//	}
//	return success;
//}
//
//bool CastSpellCircleVIP(CObject* obj, int SlotID, std::string name, bool wait = true) {
//	bool success = false;
//
//	if (me->GetSpellBook()->GetSpellSlotByID(SlotID)->IsReady() && orbwalker->CheckInterrupt() && me->IsAlive() && !Engine::IsChatOpen())
//	{
//		PredictionInput pI;
//		pI.Speed = 0;
//		auto hash = fnv::hash_runtime(name.c_str());
//		pI.Range = SpellDatabase[hash].range;
//		pI.Delay = SpellDatabase[hash].delay;
//		pI.Radius = SpellDatabase[hash].radius;
//		pI.AddHitBox = SpellDatabase[hash].hitbox;
//
//		if (me->Position().Distance(obj->Position()) <= pI.Range + obj->BoundingRadius())
//		{
//			Vector2 s = me->Pos2D();
//
//			Unit u;
//			u.Position = obj->Pos2D();
//			u.BoundingRadius = obj->BoundingRadius();
//			u.MovementSpeed = obj->MoveSpeed();
//			u.Paths = obj->GetWaypoints();
//
//			PredictionOutput pO = Prediction().PredictPosition(s, u, pI);
//			Vector3 W2S_buffer = Engine::WorldToScreen(XPolygon::To3D(pO.CastPos));
//
//			if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
//			{
//				if (Engine::GameGetTickCount() - last_castorder > humanizer_delay)
//				{
//					auto key = CheckKey(SlotID);
//					if (key && GetCursorPos(&previousMousePos))
//					{
//						MoveMouse(W2S_buffer.x, W2S_buffer.y);
//						std::this_thread::sleep_for(std::chrono::milliseconds(20));
//						KeyPress(key);
//						success = true;
//						std::this_thread::sleep_for(std::chrono::milliseconds(20));
//						ResetMouse(previousMousePos.x, previousMousePos.y);
//					}
//
//					last_castorder = Engine::GameGetTickCount();
//				}
//			}
//		}
//	}
//	int temp = 0;
//	while (success && wait)
//	{
//		temp++;
//		if (temp > 50)
//			break;
//
//		if (!me->GetSpellBook()->GetSpellSlotByID(SlotID)->IsReady())
//			break;
//	}
//	return success;
//}

void CastItem(kItemID id) {
	for (int i = 0; i <= 5; i++)
	{
		if (me->GetInventory() != nullptr)
		{
			auto itemID = me->GetInventory()->ItemID(i);
			if (itemID == id && me->GetSpellBook()->GetSpellSlotByID(6 + i)->IsItemReady())
			{
				CastSpell(6 + i, true, false);
			}
		}
	}
};

void CastItem(kItemID id, CObject* obj, bool aareset = false) {
	for (int i = 0; i <= 5; i++)
	{
		if (me->GetInventory() != nullptr)
		{
			auto itemID = me->GetInventory()->ItemID(i);

			if (itemID == id && me->GetSpellBook()->GetSpellSlotByID(6 + i)->IsItemReady())
			{
				bool success = false;
				if (me->GetSpellBook()->GetSpellSlotByID(6 + i)->IsItemReady() && orbwalker->CheckInterrupt() && me->IsAlive() && !Engine::IsChatOpen())
				{

					auto pos = obj->Position();
					bool hero = obj->IsHero();

					Vector3 W2S_buffer = Engine::WorldToScreen(pos);

					if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
					{
						if (Engine::GameGetTickCount() - last_castorder > humanizer_delay)
						{
							if (hero)
							{
										Engine::SetTargetOnlyChampions(true);
							}

							auto key = CheckKey(6 + i);
							if (key && GetCursorPos(&previousMousePos))
							{
								MoveMouse(W2S_buffer.x, W2S_buffer.y);
								std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(3)));
								KeyPress(key);
								success = true;
								std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(3)));
								ResetMouse(previousMousePos.x, previousMousePos.y);
							}

							if (hero)
							{
								Engine::SetTargetOnlyChampions(false);
							}
							last_castorder = Engine::GameGetTickCount();
						}
					}

				}
			}



		}
	}
};

void CastItem(kItemID id, Vector3 obj) {
	for (int i = 0; i <= 5; i++)
	{
		if (me->GetInventory() != nullptr)
		{
			auto itemID = me->GetInventory()->ItemID(i);

			if (itemID == id && me->GetSpellBook()->GetSpellSlotByID(6 + i)->IsItemReady())
			{
				bool success = false;
				if (me->GetSpellBook()->GetSpellSlotByID(6 + i)->IsItemReady() && orbwalker->CheckInterrupt() && me->IsAlive() && !Engine::IsChatOpen())
				{

					//auto pos = obj->Position();
					//bool hero = obj->IsHero();

					Vector3 W2S_buffer = Engine::WorldToScreen(obj);

					if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
					{
						if (Engine::GameGetTickCount() - last_castorder > humanizer_delay)
						{
							auto key = CheckKey(6 + i);
							if (key && GetCursorPos(&previousMousePos))
							{
								MoveMouse(W2S_buffer.x, W2S_buffer.y);
								std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(3)));
								KeyPress(key);
								success = true;
								std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(3)));
								ResetMouse(previousMousePos.x, previousMousePos.y);
							}

							last_castorder = Engine::GameGetTickCount();
						}
					}

				}
			}
		}
	}
};

void CastItem(CObject* obj, kItemID id, PredictionInput& spell, bool asap = false, HitChance hitchance = HitChance::Impossible, bool blockspell = true) {
	for (int i = 0; i <= 5; i++)
	{
		if (me->GetInventory() != nullptr)
		{
			auto itemID = me->GetInventory()->ItemID(i);

			if (itemID == id && me->GetSpellBook()->GetSpellSlotByID(6 + i)->IsItemReady())
			{
				bool success = false;
				if (me->GetSpellBook()->GetSpellSlotByID(6 + i)->IsItemReady() && orbwalker->CheckInterrupt() && me->IsAlive() && !Engine::IsChatOpen())
				{
					auto pO = prediction->GetPrediction(obj, spell);
					Vector3 W2S_buffer = Engine::WorldToScreen(pO.CastPosition());

					//auto pos = obj->Position();
					//bool hero = obj->IsHero();

					if (W2S_buffer.x != 0 && W2S_buffer.y != 0 && !Engine::IsOutboundScreen(W2S_buffer))
					{
						if (Engine::GameGetTickCount() - last_castorder > humanizer_delay)
						{
							auto key = CheckKey(6 + i);
							if (key && GetCursorPos(&previousMousePos))
							{
								MoveMouse(W2S_buffer.x, W2S_buffer.y);
								std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(3)));
								KeyPress(key);
								success = true;
								std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(3)));
								ResetMouse(previousMousePos.x, previousMousePos.y);
							}

							last_castorder = Engine::GameGetTickCount();
						}
					}

				}
			}
		}
	}
};
