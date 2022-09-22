#pragma once
bool lineLineIntersection(ImVec2 p1, ImVec2 p2, ImVec2 r1, ImVec2 r2, ImVec2* out, int flag = 0)
{
	float A1 = p2.y - p1.y;
	float B1 = p1.x - p2.x;
	float C1 = A1 * p1.x + B1 * p1.y;
	float A2 = r2.y - r1.y;
	float B2 = r1.x - r2.x;
	float C2 = A2 * r1.x + B2 * r1.y;

	float det = A1 * B2 - A2 * B1;

	if (det == 0) return false;

	ImVec2 intersect(0, 0);
	intersect.x = (B2 * C1 - B1 * C2) / det;
	intersect.y = (A1 * C2 - A2 * C1) / det;
	float vx0 = (intersect.x - p1.x) / (p2.x - p1.x);
	float vy0 = (intersect.y - p1.y) / (p2.y - p1.y);
	float vx1 = (intersect.x - r1.x) / (r2.x - r1.x);
	float vy1 = (intersect.y - r1.y) / (r2.y - r1.y);

	if ((flag == 1) ||
		(((flag == 2) || (vx0 >= 0 && vx0 <= 1) || (vy0 >= 0 && vy0 <= 1))
			&& ((flag == 3) || (vx1 >= 0 && vx1 <= 1) || (vy1 >= 0 && vy1 <= 1)))) {
		out->x = intersect.x;
		out->y = intersect.y;
		return true;
	}

	return false;
}

void DrawCountDown(ImVec2 center, float radius, float percent, ImDrawList* pDrawList, D3DCOLOR color) {

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	auto colorBackground = ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255));
	float angle = M_PI * 2 * (1.f - percent) - M_PI;

	ImVec2 topLeft = { center.x - radius, center.y - radius };
	ImVec2 topRight = { center.x + radius, center.y - radius };
	ImVec2 botLeft = { center.x - radius, center.y + radius };
	ImVec2 botRight = { center.x + radius, center.y + radius };

	ImVec2 intCircle = { center.x + radius * Engine::fastsin(angle) * 2, center.y + radius * Engine::fastcos(angle) * 2 };

	ImVec2 intSquare = { 0,0 };

	int step = -1;

	if (lineLineIntersection(center, intCircle, topLeft, topRight, &intSquare)) { step = 0; goto DRAW_INTERSECT_FUCKER; }
	if (lineLineIntersection(center, intCircle, topRight, botRight, &intSquare)) { step = 1; goto DRAW_INTERSECT_FUCKER; }
	if (lineLineIntersection(center, intCircle, botRight, botLeft, &intSquare)) { step = 2; goto DRAW_INTERSECT_FUCKER; }
	if (lineLineIntersection(center, intCircle, botLeft, topLeft, &intSquare)) { step = 3; goto DRAW_INTERSECT_FUCKER; }

DRAW_INTERSECT_FUCKER:
	//ImVec2 intTop = ;
	if (step != -1) {

		if (step != 0 || percent <= 0.25f) {
			if (step < 3 || (step == 3 && percent <= 0.75f)) {
				pDrawList->AddRectFilled(topLeft, center, colorBackground);

				if (step < 2 || (step == 2 && percent <= 0.5f)) {
					pDrawList->AddRectFilled(botLeft, center, colorBackground);

					if (step < 1 || (step == 1 && percent <= 0.25f)) {
						pDrawList->AddRectFilled(botRight, center, colorBackground);
						if (step < 1) {
							pDrawList->AddTriangleFilled(center, { center.x + radius, center.y }, topRight, colorBackground);
							pDrawList->AddTriangleFilled(center, intSquare, topRight, colorBackground);
						}
						else {
							pDrawList->AddTriangleFilled(center, intSquare, { center.x + radius, center.y }, colorBackground);
						}
					}
					else {

						if (step < 2) {
							pDrawList->AddTriangleFilled(center, { center.x, center.y + radius }, botRight, colorBackground);
							pDrawList->AddTriangleFilled(center, intSquare, botRight, colorBackground);
						}
						else {
							pDrawList->AddTriangleFilled(center, intSquare, { center.x, center.y + radius }, colorBackground);
						}
					}

				}
				else {

					if (step < 3) {
						pDrawList->AddTriangleFilled(center, { center.x - radius, center.y }, botLeft, colorBackground);
						pDrawList->AddTriangleFilled(center, intSquare, botLeft, colorBackground);
					}
					else {
						pDrawList->AddTriangleFilled(center, intSquare, { center.x - radius, center.y }, colorBackground);
					}
				}
			}
			else {
				pDrawList->AddTriangleFilled(center, { center.x, center.y - radius }, topLeft, colorBackground);
				pDrawList->AddTriangleFilled(center, intSquare, topLeft, colorBackground);
			}

		}
		else {

			pDrawList->AddTriangleFilled(center, intSquare, { center.x, center.y - radius }, colorBackground);
		}

	}
}

void GetLevel(int exp, int* limit, int* remaining_exp) {
	int exp_rank[] = { 280, 380 ,480,580,680,780,980,1080,1180,1280, 1380 ,1480,1580,1680,1780,1980,2080,2180 };
	int total = 0;
	int level = 0;


	for (; level < sizeof(exp_rank) / sizeof(exp_rank[0]); level++) {
		total += exp_rank[level];
		if (total >= exp) break;
	}
	*remaining_exp = exp - (total - exp_rank[level]);
	*limit = exp_rank[level];
}

struct img_struct
{
	ImDrawList* drawlist;
	LPDIRECT3DTEXTURE9 buffer;
	ImVec2 a;
	ImVec2 b;
	ImVec2 f;
	ImVec2 e;
	ImU32 color;
	float rouding;

	/*img_struct(ImDrawList* drawlist, LPDIRECT3DTEXTURE9 buffer, ImVec2 a, ImVec2 b, ImVec2 f, ImVec2 e, ImU32 color, float rouding)
	{
		this->drawlist = drawlist;
		this->buffer = buffer;
		this->a = a;
		this->b = b;
		this->f = f;
		this->e = e;
		this->color = color;
		this->rouding = rouding;
	}
	~img_struct()
	{
		this->drawlist = nullptr;
		this->buffer = NULL;
		this->a = ImVec2();
		this->b = ImVec2();
		this->f = ImVec2();
		this->e = ImVec2();
		this->color = 0x0;
		this->rouding = 0.f;
	}*/
};

std::vector<img_struct> draw_imgs;

class Awareness : public ModuleManager {
public:
	CheckBox* MoveLocation;
	CheckBox* LastLocation;
	CheckBox* EnemyLine;
	CheckBox* EnemyLineOnFlashDown;
	CheckBox* Range;
	CheckBox* Info;
	CheckBox* InfoChampion;
	CheckBox* DamageHPBar;

	CheckBox* ShowPath;
	CheckBox* ShowPathMM;
	CheckBox* ShowNotify;
	CheckBox* HideInBush;

	CheckBox* TurretRange;

	CheckBox* Ward;
	CheckBox* WardRange;
	CheckBox* WardRangeWall;
	CheckBox* WardHelper;
	CheckBox* WardMinimap;

	CheckBox* Trap;

	CheckBox* JungleTimer;
	CheckBox* JungleTimerOnMinimap;

	Vector3 objectLocationLocal;
	Vector3 objectScreenLocationLocal;
	bool isLocalDead;
	float posw = s_width - 60.f;
	float posh = s_height - 420.f;

	Vector3 BaseTeam1 = Vector3(394.000, 182.133, 462.000);
	Vector3 BaseTeam2 = Vector3(14340.000, 171.978, 14390.000);

	uint32_t colorRed = D3DCOLOR_ARGB(255, 255, 105, 97);
	uint32_t colorOrange = D3DCOLOR_ARGB(255, 227, 142, 0);
	uint32_t colorGreen = D3DCOLOR_ARGB(255, 151, 185, 50);
	float recallTimers[5];
	float teleportTimers[5];
	float baronTimers[5];
	float timeToFinishRecall;
	float currTime;
	Awareness()
	{

	}

	~Awareness()
	{

	}

	void DrawImages()
	{

		for (int i = 0; i < draw_imgs.size(); i++)
		{
			draw_imgs[i].drawlist->AddImage(draw_imgs[i].buffer, draw_imgs[i].a, draw_imgs[i].b, ImVec2(0, 0), ImVec2(1, 1), draw_imgs[i].color);
		}
	}

	void AddImage(ImDrawList* drawlist, LPDIRECT3DTEXTURE9 buffer, ImVec2 a, ImVec2 b, ImVec2 f, ImVec2 e, ImU32 color)
	{
		img_struct s;
		s.drawlist = drawlist;
		s.buffer = buffer;
		s.a = a;
		s.b = b;
		s.f = f;
		s.e = e;
		s.color = color;

		draw_imgs.push_back(s);
	}

	void DrawTraps()
	{
		if ((global::traps.size() > 0) && (global::traps.size() != 0) && this->Trap->Value)
		{
			for (int i = 0; i < global::traps.size(); i++)
			{
				auto trap = global::traps[i];
				Vector3 objectScreenLocation2 = Engine::WorldToScreen(trap.position);

				if (!Engine::IsOutboundScreen(objectScreenLocation2) && objectScreenLocation2.x != 0 && objectScreenLocation2.y != 0)
				{
					XPolygon::DrawCircle(trap.position, 125, ImVec4(255, 255, 255, 0));
					Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, trap.name.c_str());
				}
			}
		}
	}

	void DrawTroy()
	{
		for (auto base : global::troyobjects)
		{
			CObject* troy = (CObject*)base;
			auto namehash = troy->NameHash();
			auto name = troy->Name();
			if (strstr(name.c_str(), "_SE") && (strstr(name.c_str(), "Warning")))
			{
				XPolygon::DrawCircle(troy->Position(), 10, ImVec4(255, 255, 255, 0));
				Vector3 objectScreenLocation2 = Engine::WorldToScreen(troy->Position());
				Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, name.c_str());
			}
			if (strstr(name.c_str(), "_SW") && (strstr(name.c_str(), "Warning")))
			{
				XPolygon::DrawCircle(troy->Position(), 10, ImVec4(255, 255, 255, 0));
				Vector3 objectScreenLocation2 = Engine::WorldToScreen(troy->Position());
				Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, name.c_str());
			}
			if (strstr(name.c_str(), "_NW") && (strstr(name.c_str(), "Warning")))
			{
				XPolygon::DrawCircle(troy->Position(), 10, ImVec4(255, 255, 255, 0));
				Vector3 objectScreenLocation2 = Engine::WorldToScreen(troy->Position());
				Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, name.c_str());
			}
			if (strstr(name.c_str(), "_NE") && (strstr(name.c_str(), "Warning")))
			{
				XPolygon::DrawCircle(troy->Position(), 10, ImVec4(255, 255, 255, 0));
				Vector3 objectScreenLocation2 = Engine::WorldToScreen(troy->Position());
				Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, name.c_str());
			}
		}
	}

	void DrawTurrets()
	{
		for (auto turret : Engine::GetTurrets(1))
		{
			if (turret->IsVisible())
			{
				XPolygon::DrawCircle(turret->Position(), 850 + global::LocalData->gameplayRadius / 2, ImVec4(255, 255, 255, 0));
			}
		}
	}

	void DrawWards()
	{
		if (this->WardHelper->Value)
		{
			XPolygon::DrawCircle(Vector3{ 1867, 53, 11236 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 2400, -71, 11007 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 5515, -73, 10468 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 6087, 56, 10487 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 8278, 59, 2932 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 8131, 52, 3520 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 10022, -37, 3845 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 10250, 49, 3376 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 12483, -41, 3862 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 11804, -24, 4704 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 12211, 52, 5040 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 12715, 52, 4798 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 9614, 16, 6606 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 9575, 52, 7756 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 3993, 40, 11904 }, 10, ImVec4(255, 255, 0, 0), 2);

			XPolygon::DrawCircle(Vector3{ 10729, 50, 3008 }, 10, ImVec4(255, 255, 0, 0), 2);
			//dragon pit top bush
			XPolygon::DrawCircle(Vector3{ 4720, -80, 10935 }, 10, ImVec4(255, 255, 0, 0), 2);
			XPolygon::DrawCircle(Vector3{ 4594, 52, 11424 }, 10, ImVec4(255, 255, 0, 0), 2);

		}


		if ((global::wards.size() > 0) && (global::wards.size() != 0) && this->Ward->Value)
		{
			for (int i = 0; i < global::wards.size(); i++)
			{
				auto wards = global::wards[i];
				Vector3 objectScreenLocation2 = Engine::WorldToScreen(wards.position);
				Vector2 Minimap = Engine::WorldToMinimap(wards.position);

				if (wards.type == 1.f && this->WardMinimap->Value)
					AddImage(ImGui::GetTestgroundDrawList(), pTotemWard, ImVec2(Minimap.x - 13, Minimap.y - 13), ImVec2(Minimap.x + 13, Minimap.y + 13), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(1, 1, 1, 1)));

				if (wards.type == 2.f && this->WardMinimap->Value)
					AddImage(ImGui::GetTestgroundDrawList(), pControlWard, ImVec2(Minimap.x - 13, Minimap.y - 13), ImVec2(Minimap.x + 13, Minimap.y + 13), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(1, 1, 1, 1)));

				if (wards.type == 3.f && this->WardMinimap->Value)
					AddImage(ImGui::GetTestgroundDrawList(), pFarsightWard, ImVec2(Minimap.x - 13, Minimap.y - 13), ImVec2(Minimap.x + 13, Minimap.y + 13), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(1, 1, 1, 1)));


				if (!Engine::IsOutboundScreen(objectScreenLocation2) && objectScreenLocation2.x != 0 && objectScreenLocation2.y != 0)
				{
					if (wards.type == 1.f)
					{
						float time = (wards.time + RPM<float>(wards.actor + offsets_lol.oObjMana)) - Engine::GameGetTickCount();
						if (time > 0)
						{
							static Anim radius;
							static float full_rad = 100;
							radius.value = 0;
							if (!radius.isintask()) radius.accelerate(1, 5000);
							if (radius.get() == 1) radius.value = 0;

							if (this->WardRange->Value)
							{
								if (this->WardRangeWall->Value)
								{
									XPolygon::DrawPolygon(wards.vision, wards.position.y, D3DCOLOR_ARGB(255, 255, 255, 0), 2);
								}
								else {
									XPolygon::DrawCircle(wards.position, 1100, ImVec4(255, 255, 255, 0), 2);
								}
							}

							XPolygon::DrawCircle(wards.position, 140, ImVec4(255, 255, 255, 0));

							XPolygon::DrawCircle(wards.position, 40 + (radius.get() * full_rad), ImVec4(150 - (radius.get() * full_rad), 255, 255, 0), 2);

							Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 255, 0, 255), true, false, textonce("Stealth Ward %.01f"), time);
						}
					}

					if (wards.type == 2.f)
					{

						static Anim radius;
						static float full_rad = 40;
						radius.value = 0;
						if (!radius.isintask()) radius.accelerate(1, 3000);
						if (radius.get() == 1) radius.value = 0;

						if (this->WardRange->Value)
						{
							if (this->WardRangeWall->Value)
							{
								XPolygon::DrawPolygon(wards.vision, wards.position.y, D3DCOLOR_ARGB(255, 255, 0, 0), 2);
							}
							else {
								XPolygon::DrawCircle(wards.position, 1100, ImVec4(255, 255, 0, 0), 2);
							}
						}

						XPolygon::DrawCircle(wards.position, 140, ImVec4(255, 255, 0, 0));
						XPolygon::DrawCircle(wards.position, 140 + (radius.get() * full_rad + 16), ImVec4(150 - (radius.get() * full_rad), 255, 0, 0));
						XPolygon::DrawCircle(wards.position, 140 + (radius.get() * full_rad), ImVec4(150 - (radius.get() * full_rad), 255, 0, 0));
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 0, 0, 255), true, false, textonce("Control Ward"));

					}

					if (wards.type == 3.f)
					{
						static Anim radius;
						static float full_rad = 100;
						radius.value = 0;
						if (!radius.isintask()) radius.accelerate(1, 5000);
						if (radius.get() == 1) radius.value = 0;

						if (this->WardRange->Value)
						{
							if (this->WardRangeWall->Value)
							{
								XPolygon::DrawPolygon(wards.vision, wards.position.y, D3DCOLOR_ARGB(255, 30, 144, 255), 2);
							}
							else {
								XPolygon::DrawCircle(wards.position, 700, ImVec4(255, 30, 144, 255), 2);
							}
						}
						XPolygon::DrawCircle(wards.position, 40 + (radius.get() * full_rad - 15), ImVec4(255, 30, 144, 255));
						XPolygon::DrawCircle(wards.position, 40 + (radius.get() * full_rad), ImVec4(150 - (radius.get() * full_rad), 30, 144, 255));
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(30, 154, 255, 255), true, false, textonce("Farsight Alteration"));

					}
				}
			}
		}
	}

	void DrawCamps()
	{
		for (auto obj : global::campobject)
		{
			CObject* actor = (CObject*)obj;
			float timeRemaining = 0;
			float time = 0;

			if (actor->HasBuff(0xad1e78d3)) //camprespawncountdownhidden
			{
				time = actor->GetBuffManager()->GetBuffEntryByHash(0xad1e78d3)->GetBuffEndTime() + 60;
				timeRemaining = time - Engine::GameGetTickCount();
			}
			else if (actor->HasBuff(0xe2b233b7)) //camprespawncountdownvisible
			{
				time = actor->GetBuffManager()->GetBuffEntryByHash(0xe2b233b7)->GetBuffEndTime();
				timeRemaining = time - Engine::GameGetTickCount();
			}

			if (timeRemaining <= 0)
				continue;

			Vector3 objectLocation = actor->Position();
			Vector3 objectScreenLocation2 = Engine::WorldToScreen(objectLocation);
			Vector2 MinimapJung = Engine::WorldToMinimap(objectLocation);

			int min = (int)timeRemaining / 60;
			int sec = (int)timeRemaining % 60;

			if (JungleTimerOnMinimap->Value)
				Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(MinimapJung.x, MinimapJung.y - 14 / 2), 15.f, D3DCOLOR_RGBA(0, 255, 0, 255), true, true, textonce("%02d:%02d"), min, sec);

			if (!Engine::IsOutboundScreen(objectScreenLocation2) && JungleTimer->Value)
			{
				Renderer::GetInstance()->DrawRectFilled(ImVec2(objectScreenLocation2.x - 2.f, objectScreenLocation2.y), ImVec2(objectScreenLocation2.x + 32.f, objectScreenLocation2.y + 28.f), D3DCOLOR_ARGB(255, 30, 144, 255));
				Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 14.f, D3DCOLOR_RGBA(255, 255, 255, 255), false, true, textonce("%02d:%02d\n%02d:%02d"), min, sec, (int)time / 60, (int)time % 60);
			}
			//Draw timeRemaining on map or world whatever u want
		}
	}

	void DrawHeros()
	{
		Vector2 screen_start;
		float scaling = MenuSettings::MinimapScaling / 100;
		float wsize = 193 + 190.0 * scaling;
		//printf("wsize: %.5f \n", wsize);
		//printf("w: %.0f h: %.0f", s_width, s_height);
		Vector2 screen_size = Vector2(wsize, wsize);

		if (MenuSettings::RightSide)
			screen_start = Vector2(s_width - wsize - 10, s_height - wsize - 10);
		else
			screen_start = Vector2(s_width - s_width + 10, s_height - wsize - 10);

		posh = screen_start.y - 230.f;
		if (global::enemyheros.size() > 0)
		{
			int i = -1;
			int ih = 0;
			int ispell = 0;
			int isrecall = 1;
			int invisiblecount = 0;
			for (auto& object : global::enemyheros)
			{
				CObject* actor = (CObject*)object.actor;

				bool actor_isally = actor->IsAlly();
				bool actor_isenemy = actor->IsAlly();
				bool actor_isme = actor->Index() == me->Index();
				bool actor_isdead = !actor->IsAlive();
				Vector3 actor_pos = actor->Position();
				Vector2 actor_pos2d = actor->Pos2D();
				float gametick = Engine::GameGetTickCount();
				float gametime = Engine::GameTimeTickCount();
				float actor_exp = actor->Exp();
				auto actor_aimanager = actor->GetAIManager();
				auto actor_visible = actor->IsVisible();

				float actor_health = actor->Health();
				float actor_maxhealth = actor->MaxHealth();

				float actor_mana = actor->Mana();
				float actor_maxmana = actor->MaxMana();

				if (actor_isally)
					continue;

				i++;
				ih++;

				/*auto pathLive = actor->GetWaypoints3D();
				if (pathLive.size() > 1)
					object.path = pathLive;*/

				Vector3 objectScreenLocation = Engine::WorldToScreen(actor_pos);

				if (actor_pos.x != 0 && actor_pos.z != 0)
				{
					auto spellbook = actor->GetSpellBook();
					auto pointerq = spellbook->GetSpellSlotByID(0);
					auto pointerw = spellbook->GetSpellSlotByID(1);
					auto pointere = spellbook->GetSpellSlotByID(2);
					auto pointerr = spellbook->GetSpellSlotByID(3);

					auto pointerd = spellbook->GetSpellSlotByID(4);
					auto pointerf = spellbook->GetSpellSlotByID(5);

					float spellq = pointerq->CoolDown();
					float spellw = pointerw->CoolDown();
					float spelle = pointere->CoolDown();
					float spellr = pointerr->CoolDown();

					float spelld = pointerd->CoolDown();
					float spellf = pointerf->CoolDown();

					spellq = spellq < 0.f ? 0 : spellq;
					spellw = spellw < 0.f ? 0 : spellw;
					spelle = spelle < 0.f ? 0 : spelle;
					spellr = spellr < 0.f ? 0 : spellr;
					spelld = spelld < 0.f ? 0 : spelld;
					spellf = spellf < 0.f ? 0 : spellf;

					int xpos = (i) * 60;

					if (spelld > 0.f)
					{
						int minutesD = floor(((int)(spelld + gametick) / 60) % 60);
						int secondsD = (int)(spelld + gametick) % 60;
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw - xpos + 25, posh - 65), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%02d:%02d", minutesD, secondsD);
					}

					if (spellf > 0.f)
					{
						int minutesF = floor(((int)(spellf + gametick) / 60) % 60);
						int secondsF = (int)(spellf + gametick) % 60;
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw - xpos + 25, posh - 50), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%02d:%02d", minutesF, secondsF);
					}

					if (pointerr->IsReady())
					{
						if (object.pushedTimeR == 0)
							object.pushedTimeR = Engine::TickCount();// GetTickCount();
					}
					else
					{
						object.pushedTimeR = 0;
					}

					if (pointerd->IsReady())
					{
						if (object.pushedTimeD == 0)
							object.pushedTimeD = Engine::TickCount();// GetTickCount();
					}
					else
					{
						object.pushedTimeD = 0;
					}

					if (pointerf->IsReady())
					{
						if (object.pushedTimeF == 0)
							object.pushedTimeF = Engine::TickCount();// GetTickCount();
					}
					else
					{
						object.pushedTimeF = 0;
					}

					if (Engine::TickCount() - object.pushedTimeD < 3000 && Engine::TickCount() - object.pushedTimeD > 1)
					{
						float spellyaa = ispell * 60.f;

						AddImage(ImGui::GetImguigroundDrawList(), object.pTextureChampRounded, ImVec2(s_width / 3, s_height / 10 + spellyaa), ImVec2(s_width / 3 + 50, s_height / 10 + 50 + spellyaa), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(1, 1, 1, 1)));
						Renderer::GetInstance()->DrawCircle(ImVec2(s_width / 3 + 25, s_height / 10 + 25 + spellyaa), 25, D3DCOLOR_ARGB(255, 157, 123, 65), 2.f);
						AddImage(ImGui::GetImguigroundDrawList(), object.pTextureSpellRounded1, ImVec2(s_width / 3 + 200, s_height / 10 + spellyaa), ImVec2(s_width / 3 + 250, s_height / 10 + 50 + spellyaa), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(1, 1, 1, 1)));
						Renderer::GetInstance()->DrawCircle(ImVec2(s_width / 3 + 225, s_height / 10 + 25 + spellyaa), 25, D3DCOLOR_ARGB(255, 157, 123, 65), 2.f);
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(s_width / 3 + 75, s_height / 10 + 10 + spellyaa), 30, D3DCOLOR_RGBA(255, 255, 255, 255), false, true, "IS READY");
						ispell++;
					}

					if (Engine::TickCount() - object.pushedTimeF < 3000 && Engine::TickCount() - object.pushedTimeF > 1)
					{
						float spellyaa = ispell * 60.f;
						AddImage(ImGui::GetImguigroundDrawList(), object.pTextureChampRounded, ImVec2(s_width / 3, s_height / 10 + spellyaa), ImVec2(s_width / 3 + 50, s_height / 10 + 50 + spellyaa), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(1, 1, 1, 1)));
						Renderer::GetInstance()->DrawCircle(ImVec2(s_width / 3 + 25, s_height / 10 + 25 + spellyaa), 25, D3DCOLOR_ARGB(255, 157, 123, 65), 2.f);
						AddImage(ImGui::GetImguigroundDrawList(), object.pTextureSpellRounded2, ImVec2(s_width / 3 + 200, s_height / 10 + spellyaa), ImVec2(s_width / 3 + 250, s_height / 10 + 50 + spellyaa), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(1, 1, 1, 1)));
						Renderer::GetInstance()->DrawCircle(ImVec2(s_width / 3 + 225, s_height / 10 + 25 + spellyaa), 25, D3DCOLOR_ARGB(255, 157, 123, 65), 2.f);
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(s_width / 3 + 75, s_height / 10 + 10 + spellyaa), 30, D3DCOLOR_RGBA(255, 255, 255, 255), false, true, "IS READY");
						ispell++;
					}

					float height = (ih) * 50;
					float sizeH = 150.f;
					float dist = objectLocationLocal.Distance(actor_pos);

					ImVec4 colormiss = ImVec4(255, 255, 255, 255);
					if (HideInBush->Value)
					{
						if (actor_exp)
						{
							if (object.lastexp != actor_exp)
							{

								object.expdiff = actor_exp - object.lastexp;

								if (object.expdiff > 0 && fmod(object.expdiff, 60.45) > 1 && fmod(object.expdiff, 29.76) > 1 && fmod(object.expdiff, 93) > 1)
								{
									object.pushedTimeGank = Engine::TickCount();
								}
								object.lastexp = actor_exp;

							}

							if (Engine::TickCount() - object.pushedTimeGank < 1000 && invisiblecount > 0)
							{
								//printf("ganking? near %s | diff: %.2f | lastexp: %.2f | curExp: %.2f \n", actor->Name().c_str(), global::objects[i].expdiff, global::objects[i].lastexp, actor->Exp());
							}
						}
					}

					if (actor_aimanager != nullptr)
					{
						//XPolygon::DrawCircle3D(actor->GetAIManager()->LastClickPosition(), 30, 100);
						if (MoveLocation->Value && !actor_isdead)
						{
							auto lastclick = Engine::WorldToScreenImVec2(actor_aimanager->LastClickPosition());
							Renderer::GetInstance()->DrawLine(ImVec2(objectScreenLocation.x, objectScreenLocation.y), lastclick, D3DCOLOR_RGBA(255, 255, 255, 255));
							Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, lastclick, 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%s", object.name.c_str());
						}
						if (actor_aimanager->EndPosition() != object.lastMoveTargetPosition)
						{
							//printf("%s NEW CLICK AT %.5f\n", actor->Name().c_str(),Engine::GameGetTickCount());


							object.pushedTimeLastMoveClick = gametick;
							object.lastMoveTargetPosition = actor_aimanager->EndPosition();
							if (gametick - object.pushedTimeLastMoveClick < 1.f)
							{
								//printf("%s avg move click : %.5f\n", actor->ChampionName().c_str(), object.avgMoveClick);

								object.avgMoveClick = (object.avgMoveClick + (gametick - object.pushedTimeLastMoveClick)) / 2;
							}

						}
					}

					if (!actor_isdead)
					{
						if (ShowPath->Value)
						{
							if (!actor->IsVisible())
							{
								XPolygon::DrawArrow(actor_pos2d, XPolygon::AppendVector(actor_pos2d, actor_pos2d + XPolygon::To2D(actor->Direction()), 400), D3DCOLOR_RGBA(255, 0, 0, 170), 3.f, actor->Position().y);
							}
						}
						/*if (ShowPathMM->Value)
						{
							if (!actor->IsVisible())
							{
								if (object.path.size() > 1)
								{
									for (int i = 0; i < object.path.size() - 1; i++)
									{
										auto Start = Engine::WorldToMinimap(object.path[i]);
										auto End = Engine::WorldToMinimap(object.path[i + 1]);
										Renderer::GetInstance()->DrawLine(*(ImVec2*)&Start, *(ImVec2*)&End, D3DCOLOR_RGBA(255, 0, 0, 100), 4);
									}
								}
							}
						}*/
						if (!Engine::IsOutboundScreen(objectScreenLocation) && orbwalker->EnemyAttackRange->Value && actor_visible)
						{
							XPolygon::DrawCircle(actor_pos, actor->GetSelfAttackRange(), ImVec4(255, 255, 255, 255), 2.5f);
						}

						if (!Engine::IsOutboundScreen(objectScreenLocation) && this->Range->Value && actor_visible)
						{
							for (auto range : object.skillrange)
								if (range > 20.f)
									XPolygon::DrawCircle(actor_pos, range, ImVec4(255, 255, 69, 0), 2.5f);
						}

						bool resetinvi = false;

						if (!actor_visible)
						{
							if (object.missTime == 0)
								object.missTime = Engine::TickCount();

							invisiblecount++;
							object.missing = true;
							object.inviTime = 0;
							colormiss = ImVec4(255, 0, 0, 255);
							if (this->LastLocation->Value)
							{
								Vector2 Minimap = Engine::WorldToMinimap(actor_pos);
								Renderer::GetInstance()->DrawCircle(ImVec2(Minimap.x, Minimap.y), 13, D3DCOLOR_ARGB(255, 255, 0, 0));
								AddImage(ImGui::GetImguigroundDrawList(), object.pTextureChampRounded, ImVec2(Minimap.x - 12, Minimap.y - 12), ImVec2(Minimap.x + 12, Minimap.y + 12), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(100.f / 255.f, 100.f / 255.f, 100.f / 255.f, 1)));
								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(Minimap.x + 1.f, Minimap.y + 15), 14, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%d", (Engine::TickCount() - object.missTime) / 1000);

								if ((this->EnemyLine->Value || this->EnemyLineOnFlashDown->Value) && !isLocalDead)
								{
									if ((this->EnemyLine->Value && dist < 4000) || (this->EnemyLineOnFlashDown->Value && !actor->IsReady(actor->GetSpellSlotByName("SummonerFlash"))))
									{

										auto color = D3DCOLOR_ARGB(150, 255, 0, 0);


										float size = 20.f;
										if (Engine::IsOutboundScreen(objectScreenLocation))
										{
											color = D3DCOLOR_ARGB(150, 0, 255, 0);
										}
										float sizetemp = (me->Distance(actor) / 2000.f) * 20.f;
										size -= sizetemp;
										size = std::max(size, 2.f);
										size = std::min(size, 20.f);

										float theta = atan2(objectScreenLocation.y - objectScreenLocationLocal.y, objectScreenLocation.x - objectScreenLocationLocal.x);
										float a = objectScreenLocationLocal.x + 200.f * Engine::fastcos(theta);
										float b = objectScreenLocationLocal.y + 200.f * Engine::fastsin(theta);

										float aa = objectScreenLocationLocal.x + 70.f * Engine::fastcos(theta);
										float bb = objectScreenLocationLocal.y + 70.f * Engine::fastsin(theta);

										Renderer::GetInstance()->DrawLine(ImVec2(aa, bb), ImVec2(objectScreenLocation.x, objectScreenLocation.y), color, size);

										if (dist > 400 && Engine::IsOutboundScreen(objectScreenLocation))
											Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(a, b), 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%s %0.2fm", object.name.c_str(), me->Distance(actor));
									}
								}
								if (!Engine::IsOutboundScreen(objectScreenLocation))
								{
									AddImage(ImGui::GetImguigroundDrawList(), object.pTextureChampRounded, ImVec2(objectScreenLocation.x - 25, objectScreenLocation.y - 25), ImVec2(objectScreenLocation.x + 25, objectScreenLocation.y - 25 + 50), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(100.f / 255.f, 100.f / 255.f, 100.f / 255.f, 1)));
									Renderer::GetInstance()->DrawCircle(ImVec2(objectScreenLocation.x, objectScreenLocation.y), 25, D3DCOLOR_ARGB(255, 157, 123, 65), 1.f);
									Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation.x, objectScreenLocation.y + 37), 17, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%d", (Engine::TickCount() - object.missTime) / 1000);
									Renderer::GetInstance()->DrawRectFilledCurrentWindow(ImVec2(objectScreenLocation.x - 25 + 3, objectScreenLocation.y + 27), ImVec2(objectScreenLocation.x + 3 + 20, objectScreenLocation.y + 31), D3DCOLOR_ARGB(255, 1, 1, 1));
									Renderer::GetInstance()->DrawRectFilledCurrentWindow(ImVec2(objectScreenLocation.x - 25 + 3, objectScreenLocation.y + 27), ImVec2(objectScreenLocation.x - 25 + 3 + ((45 / actor->MaxHealth()) * actor->Health()), objectScreenLocation.y + 31), D3DCOLOR_ARGB(255, 9, 197, 73));
									Renderer::GetInstance()->DrawRectAdv(ImVec2(objectScreenLocation.x - 25, objectScreenLocation.y + 25), ImVec2(objectScreenLocation.x + 25, objectScreenLocation.y + 32), D3DCOLOR_ARGB(255, 157, 123, 65), ImGui::GetForegroundDrawList());

									Renderer::GetInstance()->DrawRectFilledCurrentWindow(ImVec2(objectScreenLocation.x - 25 + 3, objectScreenLocation.y + 33), ImVec2(objectScreenLocation.x + 3 + 20, objectScreenLocation.y + 36), D3DCOLOR_ARGB(255, 1, 1, 1));
									Renderer::GetInstance()->DrawRectFilledCurrentWindow(ImVec2(objectScreenLocation.x - 25 + 3, objectScreenLocation.y + 33), ImVec2(objectScreenLocation.x - 25 + 3 + ((45 / actor->MaxMana()) * actor->Mana()), objectScreenLocation.y + 36), D3DCOLOR_ARGB(255, 57, 154, 249));
									Renderer::GetInstance()->DrawRectAdv(ImVec2(objectScreenLocation.x - 25, objectScreenLocation.y + 33), ImVec2(objectScreenLocation.x + 25, objectScreenLocation.y + 37), D3DCOLOR_ARGB(255, 157, 123, 65), ImGui::GetForegroundDrawList());
								}
							}
						}
						else
						{
							resetinvi = true;
							invisiblecount--;
						}

						if (object.oldLocation != actor_pos)
						{
							resetinvi = true;
							object.oldLocation = actor_pos;
						}
						if (!actor_visible && actor_aimanager->IsMoving())
						{
							resetinvi = true;
						}

						if (resetinvi)
						{
							object.missTime = 0;

							if (object.missing)
							{
								if (object.inviTime == 0)
									object.inviTime = Engine::TickCount();


								if (ShowNotify->Value)
								{
									static Anim radius;
									static float full_rad = 75;
									radius.value = 1;
									if (!radius.isintask()) radius.accelerate(-1, 1000);
									if (radius.get() == 1) radius.value = 0;

									Vector2 Minimap = Engine::WorldToMinimap(actor_pos);
									Renderer::GetInstance()->DrawCircle(ImVec2(Minimap.x, Minimap.y), 25 + (radius.get() * full_rad + 15), D3DCOLOR_ARGB(255, 255, 255, 255));
									Renderer::GetInstance()->DrawCircle(ImVec2(Minimap.x, Minimap.y), 25 + (radius.get() * full_rad + 0), D3DCOLOR_ARGB(255, 255, 255, 255));
									Renderer::GetInstance()->DrawCircle(ImVec2(Minimap.x, Minimap.y), 25 + (radius.get() * full_rad - 15), D3DCOLOR_ARGB(255, 255, 255, 255));
								}

								if (Engine::TickCount() - object.inviTime > 2000)
								{
									object.missing = false;
									object.inviTime = 0;
								}
							}

							if (this->EnemyLine->Value && !isLocalDead)
							{
								if (dist < 4000)
								{
									auto color = D3DCOLOR_ARGB(150, 255, 0, 0);


									float size = 20.f;
									if (Engine::IsOutboundScreen(objectScreenLocation))
									{
										color = D3DCOLOR_ARGB(150, 0, 255, 0);
									}
									float sizetemp = (me->Distance(actor) / 2000.f) * 20.f;
									size -= sizetemp;
									size = std::max(size, 2.f);
									size = std::min(size, 20.f);

									float theta = atan2(objectScreenLocation.y - objectScreenLocationLocal.y, objectScreenLocation.x - objectScreenLocationLocal.x);
									float a = objectScreenLocationLocal.x + 200.f * Engine::fastcos(theta);
									float b = objectScreenLocationLocal.y + 200.f * Engine::fastsin(theta);

									float aa = objectScreenLocationLocal.x + 70.f * Engine::fastcos(theta);
									float bb = objectScreenLocationLocal.y + 70.f * Engine::fastsin(theta);

									Renderer::GetInstance()->DrawLine(ImVec2(aa, bb), ImVec2(objectScreenLocation.x, objectScreenLocation.y), color, size);

									if (dist > 400 && Engine::IsOutboundScreen(objectScreenLocation))
										Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(a, b), 20, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%s %0.2fm", object.name.c_str(), me->Distance(actor));
								}
							}
						}
					}


					auto cooldowndcolor = ImGui::GetColorU32(ImVec4(1, 1, 1, 1));
					auto cooldownfcolor = ImGui::GetColorU32(ImVec4(1, 1, 1, 1));
					if (this->Info->Value)
					{
						if (object.pTextureChamp != 0)
						{
							auto colorimage = ImGui::GetColorU32(ImVec4(1, 1, 1, 1));

							if (actor_isdead || !actor_visible)
								colorimage = ImGui::GetColorU32(ImVec4(100.f / 255.f, 100.f / 255.f, 100.f / 255.f, 1));

							AddImage(ImGui::GetImguigroundDrawList(), object.pTextureChampRounded, ImVec2(posw - xpos, posh - 25), ImVec2(posw - xpos + 50, posh - 25 + 50), ImVec2(0, 0), ImVec2(1, 1), colorimage);



							if (spelld > 0.f)
								cooldowndcolor = ImGui::GetColorU32(ImVec4(100.f / 255.f, 100.f / 255.f, 100.f / 255.f, 1));

							if (spellf > 0.f)
								cooldownfcolor = ImGui::GetColorU32(ImVec4(100.f / 255.f, 100.f / 255.f, 100.f / 255.f, 1));

							AddImage(ImGui::GetCurrentWindow()->DrawList, object.pTextureSpell1, ImVec2(posw - xpos, posh + 41), ImVec2(posw - xpos + 24, posh + 65), ImVec2(0, 0), ImVec2(1, 1), cooldowndcolor);
							AddImage(ImGui::GetCurrentWindow()->DrawList, object.pTextureSpell2, ImVec2(posw - xpos + 26, posh + 41), ImVec2(posw - xpos + 50, posh + 65), ImVec2(0, 0), ImVec2(1, 1), cooldownfcolor);
							if (pointerr->Level() > 0)
								if (!(spellr > 0.f))
									AddImage(ImGui::GetTestgroundDrawList(), pUltimateDot, ImVec2(posw - xpos + 18, posh - 32), ImVec2(posw - xpos + 32, posh - 19), ImVec2(0, 0), ImVec2(1, 1), ImGui::GetColorU32(ImVec4(1, 1, 1, 1)));

							if (actor_isdead)
							{
								//printf("actor_isdead\n");

								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw - xpos + 25, posh - 17), 30, D3DCOLOR_RGBA(255, 0, 0, 255), true, false, "!");
							}
							else
							{
								if (!actor_visible)
								{
									//printf("actor_visible\n");

									Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw - xpos + 25, posh - 17), 30, D3DCOLOR_RGBA(255, 255, 0, 255), true, false, "?");
								}
							}
						}

						Renderer::GetInstance()->DrawCircle(ImVec2(posw - xpos + 25, posh), 25, D3DCOLOR_ARGB(255, 157, 123, 65), 2.f);

						Renderer::GetInstance()->DrawCircle(ImVec2(posw - xpos + 25, posh - 25), 8, D3DCOLOR_ARGB(255, 157, 123, 65), 2.f);
						if (pointerr->Level() > 0)
						{
							if (spellr > 0.f)
							{
								Renderer::GetInstance()->DrawCircleFilled(ImVec2(posw - xpos + 25, posh - 25), 7, D3DCOLOR_ARGB(255, 0, 0, 0));
								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw - xpos + 25, posh - 35), 15, D3DCOLOR_RGBA(0, 255, 0, 255), true, true, "%0.f", spellr);
							}
						}
						else
						{
							Renderer::GetInstance()->DrawCircleFilled(ImVec2(posw - xpos + 25, posh - 25), 7, D3DCOLOR_ARGB(255, 0, 0, 0));
						}

						Renderer::GetInstance()->DrawRectFilledCurrentWindow(ImVec2(posw - xpos, posh + 25), ImVec2(posw - xpos + 50, posh + 40), D3DCOLOR_ARGB(255, 19, 19, 19));
						Renderer::GetInstance()->DrawRectFilledCurrentWindow(ImVec2(posw - xpos + 3, posh + 27), ImVec2(posw - xpos + 3 + ((45 / actor_maxhealth) * actor_health), posh + 33), D3DCOLOR_ARGB(255, 9, 197, 73));
						Renderer::GetInstance()->DrawRectFilledCurrentWindow(ImVec2(posw - xpos + 3, posh + 35), ImVec2(posw - xpos + 3 + ((45 / actor_maxmana) * actor_mana), posh + 38), D3DCOLOR_ARGB(255, 57, 154, 239));
						Renderer::GetInstance()->DrawRectAdv(ImVec2(posw - xpos, posh + 25), ImVec2(posw - xpos + 50, posh + 40), D3DCOLOR_ARGB(255, 157, 123, 65), ImGui::GetForegroundDrawList());

						if (spelld > 0.f)
						{
							float d_cooldown_circle = (1.f / pointerd->TotalCD()) * spelld;
							DrawCountDown(ImVec2(posw - xpos + 24 / 2, posh + 41 + 24 / 2), 12.f, 1.f - d_cooldown_circle, ImGui::GetForegroundDrawList(), D3DCOLOR_ARGB(220, 3, 50, 100));
							Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw - xpos + (25 / 2), posh + 43), 13, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, "%0.f", spelld);
						}
						if (spellf > 0.f)
						{
							float f_cooldown_circle = (1.f / pointerf->TotalCD()) * spellf;
							DrawCountDown(ImVec2(posw - xpos + 26 + 24 / 2, posh + 41 + 24 / 2), 12.f, 1.f - f_cooldown_circle, ImGui::GetForegroundDrawList(), D3DCOLOR_ARGB(220, 3, 50, 100));
							Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw - xpos + 26 + (25 / 2), posh + 43), 13, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, "%0.f", spellf);
						}
						int level = actor->Level();
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw - xpos + 40, posh + 2), 14, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%d", level);

						Renderer::GetInstance()->DrawRectAdv(ImVec2(posw - xpos, posh + 41), ImVec2(posw - xpos + 24, posh + 65), D3DCOLOR_ARGB(255, 157, 123, 65), ImGui::GetForegroundDrawList());
						Renderer::GetInstance()->DrawRectAdv(ImVec2(posw - xpos + 26, posh + 41), ImVec2(posw - xpos + 50, posh + 65), D3DCOLOR_ARGB(255, 157, 123, 65), ImGui::GetForegroundDrawList());

					}
					//recall timer
					if (actor->RecallState() == 6)
					{
						if (recallTimers[i] - gametime <= 0)
						{
							recallTimers[i] = gametime + 8100.0f;
						}
						auto percentage = (recallTimers[i] - gametime) / 8000;
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw / 2.5 + (400 * percentage), posh + isrecall * 50 - 14), 13.0f, D3DCOLOR_RGBA(255, 255, 255, 255), false, false, "Recall %.1f - %s", (recallTimers[i] - gametime) / 1000, object.name.c_str());
						Renderer::GetInstance()->DrawRectFilled(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(255, 16, 25, 24));
						Renderer::GetInstance()->DrawRectFilled(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400 * percentage, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(150, 8, 179, 165));
						Renderer::GetInstance()->DrawRect(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(255, 49, 39, 17));
						Renderer::GetInstance()->DrawRect(ImVec2(posw / 2.5 - 1, posh + isrecall * 50 - 1), ImVec2(posw / 2.5 + 401, posh + isrecall * 50 + 11), D3DCOLOR_ARGB(255, 32, 26, 16));

						isrecall++;
					}
					else if (actor->RecallState() == 8)
					{
						if (teleportTimers[i] - gametime <= 0)
						{
							teleportTimers[i] = gametime + 4100.0f;
						}
						auto percentage = (teleportTimers[i] - gametime) / 4000;
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw / 2.5 + (400 * percentage), posh + isrecall * 40 - 5), 13.0f, D3DCOLOR_RGBA(255, 255, 255, 255), false, false, "Teleport %.1f - %s", (teleportTimers[i] - gametime) / 1000, object.name.c_str());
						Renderer::GetInstance()->DrawRectFilled(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(255, 16, 25, 24));
						Renderer::GetInstance()->DrawRectFilled(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400 * percentage, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(150, 255, 0, 255));
						Renderer::GetInstance()->DrawRect(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(255, 49, 39, 17));
						Renderer::GetInstance()->DrawRect(ImVec2(posw / 2.5 - 1, posh + isrecall * 50 - 1), ImVec2(posw / 2.5 + 401, posh + isrecall * 50 + 11), D3DCOLOR_ARGB(255, 32, 26, 16));

						isrecall++;
					}
					else if (actor->RecallState() == 11)
					{
						if (baronTimers[i] - gametime <= 0)
						{
							baronTimers[i] = gametime + 4100.0f;
						}
						auto percentage = (baronTimers[i] - gametime) / 4000;
						Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(posw / 2.5 + (400 * percentage), posh + isrecall * 40 - 5), 13.0f, D3DCOLOR_RGBA(255, 255, 255, 255), false, false, "Recall %.1f - %s", (baronTimers[i] - gametime) / 1000, object.name.c_str());
						Renderer::GetInstance()->DrawRectFilled(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(255, 16, 25, 24));
						Renderer::GetInstance()->DrawRectFilled(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400 * percentage, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(150, 255, 0, 255));
						Renderer::GetInstance()->DrawRect(ImVec2(posw / 2.5, posh + isrecall * 50), ImVec2(posw / 2.5 + 400, posh + isrecall * 50 + 10), D3DCOLOR_ARGB(255, 49, 39, 17));
						Renderer::GetInstance()->DrawRect(ImVec2(posw / 2.5 - 1, posh + isrecall * 50 - 1), ImVec2(posw / 2.5 + 401, posh + isrecall * 50 + 11), D3DCOLOR_ARGB(255, 32, 26, 16));


						isrecall++;
					}
					else if (actor->RecallState() == 0)
					{
						recallTimers[i] = 0;
						teleportTimers[i] = 0;
						baronTimers[i] = 0;
					}


					if (this->InfoChampion->Value && !actor_isdead)
					{
						if (actor_visible && !Engine::IsOutboundScreen(objectScreenLocation) && !actor_isdead)
						{
							auto vHp = Engine::HpBarPos(actor, 32);
							//vHp.x -= 37;
							vHp.y -= 4;

							uint32_t colorQ;
							if (spellq < 1.f)
								colorQ = colorGreen;
							else if (spellq > 1.f && spellq <= 10.f)
								colorQ = colorOrange;
							else
								colorQ = colorRed;

							uint32_t colorW;
							if (spellw < 1.f)
								colorW = colorGreen;
							else if (spellw > 1.f && spellw <= 10.f)
								colorW = colorOrange;
							else
								colorW = colorRed;

							uint32_t colorE;
							if (spelle < 1.f)
								colorE = colorGreen;
							else if (spelle > 1.f && spelle <= 10.f)
								colorE = colorOrange;
							else
								colorE = colorRed;

							uint32_t colorR;
							if (spellr < 1.f)
								colorR = colorGreen;
							else if (spellr > 1.f && spellr <= 10.f)
								colorR = colorOrange;
							else
								colorR = colorRed;


							float size = 25.f;
							objectScreenLocation.x = objectScreenLocation.x - size * 3;
							objectScreenLocation.y += 40.f;


							float q_cooldown = 0.f;// (20.f / RPM<float>(RPM<uint32_t>(actor + oObjSpellBook + 0x508 + (0x4 * 0)) + 0x78)) * spellq;
							float w_cooldown = 0.f; //(20.f / RPM<float>(RPM<uint32_t>(actor + oObjSpellBook + 0x508 + (0x4 * 1)) + 0x78)) * spellw;
							float e_cooldown = 0.f; //(20.f / RPM<float>(RPM<uint32_t>(actor + oObjSpellBook + 0x508 + (0x4 * 2)) + 0x78)) * spelle;
							float r_cooldown = 0.f; //(20.f / RPM<float>(RPM<uint32_t>(actor + oObjSpellBook + 0x508 + (0x4 * 3)) + 0x78)) * spellr;
							float d_cooldown = 0.f; //(20.f / RPM<float>(RPM<uint32_t>(actor + oObjSpellBook + 0x508 + (0x4 * 3)) + 0x78)) * spellr;
							float f_cooldown = 0.f; //(20.f / RPM<float>(RPM<uint32_t>(actor + oObjSpellBook + 0x508 + (0x4 * 3)) + 0x78)) * spellr;

							if (spellq > 0)
								q_cooldown = (size / pointerq->TotalCD()) * spellq;

							if (spellw > 0)
								w_cooldown = (size / pointerw->TotalCD()) * spellw;

							if (spelle > 0)
								e_cooldown = (size / pointere->TotalCD()) * spelle;

							if (spellr > 0)
								r_cooldown = (size / pointerr->TotalCD()) * spellr;

							if (spelld > 0)
								d_cooldown = (size / pointerd->TotalCD()) * spelld;

							if (spellf > 0)
								f_cooldown = (size / pointerf->TotalCD()) * spellf;

							float borderh = 15.f;

							if (DamageHPBar->Value)
							{
								auto totaldmg = me->GetAutoAttackDamage(actor) + GetSpellDamage(me, actor, SpellSlot::Q, false, true) + GetSpellDamage(me, actor, SpellSlot::W, false, true) + GetSpellDamage(me, actor, SpellSlot::E, false, true) + GetSpellDamage(me, actor, SpellSlot::R, false, true);

								auto curHpPos = vHp.x - 9;
								auto maxHpPos = vHp.x + 97;

								float dmgtrue = (actor_health - totaldmg);
								float DamageHealth = (dmgtrue / actor_maxhealth) * 97;
								DamageHealth = vHp.x + DamageHealth < curHpPos ? curHpPos : vHp.x + DamageHealth;
								float CurrentHealth = (actor_health / actor_maxhealth) * 106;

								D3DCOLOR killable = D3DCOLOR_ARGB(200, 32, 232, 91);
								if (dmgtrue <= 0)
									killable = D3DCOLOR_ARGB(200, 208, 34, 34);

								Renderer::GetInstance()->DrawRectFilled(ImVec2(DamageHealth, vHp.y - 23),
									ImVec2(curHpPos + CurrentHealth, vHp.y - 12), killable);
							}

							//Renderer::GetInstance()->DrawRectFilled(ImVec2(vHp.x - 10, vHp.y - 2), ImVec2(vHp.x + (size * 4), vHp.y + 11.f), D3DCOLOR_ARGB(255, 89, 88, 91));
							Renderer::GetInstance()->DrawRectFilled(ImVec2(vHp.x - 8, vHp.y - 25), ImVec2(vHp.x + (size * 4) - 2, vHp.y - 23), D3DCOLOR_ARGB(255, 175, 175, 175));

							if (actor_exp) // level
							{
								int limit;
								int remain_exp;
								GetLevel(actor_exp, &limit, &remain_exp);
								Renderer::GetInstance()->DrawRectFilled(ImVec2(vHp.x - 8, vHp.y - 25), ImVec2(vHp.x + ((size * 4) / limit) * remain_exp - 2, vHp.y - 23), D3DCOLOR_ARGB(255, 225, 0, 255));
							}

							Renderer::GetInstance()->DrawRectFilled2(ImVec2(vHp.x - 8, vHp.y), ImVec2(vHp.x + size - 8, vHp.y + 4), D3DCOLOR_ARGB(255, 175, 175, 175), 1.f, 5);
							Renderer::GetInstance()->DrawRectFilled2(ImVec2(vHp.x + size - 6, vHp.y), ImVec2(vHp.x + (size * 2) - 6, vHp.y + 4), D3DCOLOR_ARGB(255, 175, 175, 175), 1.f, 5);
							Renderer::GetInstance()->DrawRectFilled2(ImVec2(vHp.x + (size * 2) - 4, vHp.y), ImVec2(vHp.x + (size * 3) - 4, vHp.y + 4), D3DCOLOR_ARGB(255, 175, 175, 175), 1.f, 5);
							Renderer::GetInstance()->DrawRectFilled2(ImVec2(vHp.x + (size * 3) - 2, vHp.y), ImVec2(vHp.x + (size * 4) - 2, vHp.y + 4), D3DCOLOR_ARGB(255, 175, 175, 175), 1.f, 5);

							if (pointerq->Level() > 0)
								Renderer::GetInstance()->DrawRectFilled2(ImVec2(vHp.x - 8, vHp.y), ImVec2(vHp.x + size - q_cooldown - 8, vHp.y + 4), colorQ, 1.f, 2.f);

							if (pointerw->Level() > 0)
								Renderer::GetInstance()->DrawRectFilled2(ImVec2(vHp.x + size - 6, vHp.y), ImVec2(vHp.x + (size * 2) - w_cooldown - 6, vHp.y + 4), colorW, 1.f, 2.f);

							if (pointere->Level() > 0)
								Renderer::GetInstance()->DrawRectFilled2(ImVec2(vHp.x + (size * 2) - 4, vHp.y), ImVec2(vHp.x + (size * 3) - e_cooldown - 4, vHp.y + 4), colorE, 1.f, 2.f);

							if (pointerr->Level() > 0)
								Renderer::GetInstance()->DrawRectFilled2(ImVec2(vHp.x + (size * 3) - 2, vHp.y), ImVec2(vHp.x + (size * 4) - r_cooldown - 2, vHp.y + 4), colorR, 1.f, 2.f);


							Renderer::GetInstance()->DrawRectFilled(ImVec2(vHp.x + (size * 4), vHp.y - 23), ImVec2(vHp.x + (size * 6), vHp.y + 1), D3DCOLOR_ARGB(255, 99, 101, 99));
							AddImage(ImGui::GetCurrentWindow()->DrawList, object.pTextureSpell1, ImVec2(vHp.x + (size * 4) + 2, vHp.y - 22), ImVec2(vHp.x + (size * 5) - 1, vHp.y), ImVec2(0, 0), ImVec2(1, 1), cooldowndcolor);
							AddImage(ImGui::GetCurrentWindow()->DrawList, object.pTextureSpell2, ImVec2(vHp.x + (size * 5) + 1, vHp.y - 22), ImVec2(vHp.x + (size * 6) - 1, vHp.y), ImVec2(0, 0), ImVec2(1, 1), cooldownfcolor);


							if (spellq > 0.f)
								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(vHp.x + 1 - 8, vHp.y + 6), 13.f, D3DCOLOR_RGBA(255, 255, 255, 255), false, true, "%0.0f", spellq);
							if (spellw > 0.f)
								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(vHp.x + 1 + size - 6, vHp.y + 6), 13.f, D3DCOLOR_RGBA(255, 255, 255, 255), false, true, "%0.0f", spellw);
							if (spelle > 0.f)
								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(vHp.x + 1 + (size * 2) - 4, vHp.y + 6), 13.f, D3DCOLOR_RGBA(255, 255, 255, 255), false, true, "%0.0f", spelle);
							if (spellr > 0.f)
								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(vHp.x + 1 + (size * 3) - 2, vHp.y + 6), 13.f, D3DCOLOR_RGBA(255, 255, 255, 255), false, true, "%0.0f", spellr);

							if (spelld > 0.f)
							{
								float d_cooldown_circle = (1.f / pointerd->TotalCD()) * spelld;
								DrawCountDown(ImVec2(vHp.x + (size * 4) + (22 / 2) + 1, vHp.y - 22 / 2), 11.0f, 1.f - d_cooldown_circle, ImGui::GetForegroundDrawList(), D3DCOLOR_ARGB(220, 3, 50, 100));
								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(vHp.x + (size * 4) + 25 / 2 + 1, vHp.y - 20), 13, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, "%0.f", spelld);
							}
							if (spellf > 0.f)
							{
								float f_cooldown_circle = (1.f / pointerf->TotalCD()) * spellf;
								DrawCountDown(ImVec2(vHp.x + (size * 5) + 1 + (22 / 2), vHp.y - 22 / 2), 11.f, 1.f - f_cooldown_circle, ImGui::GetForegroundDrawList(), D3DCOLOR_ARGB(220, 3, 50, 100));
								Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(vHp.x + (size * 5) + 25 / 2, vHp.y - 20), 13, D3DCOLOR_RGBA(255, 255, 255, 255), true, false, "%0.f", spellf);
							}
							Renderer::GetInstance()->DrawRectAdv(ImVec2(vHp.x + (size * 4) + 1, vHp.y - 23), ImVec2(vHp.x + (size * 5) - 1, vHp.y), D3DCOLOR_ARGB(255, 157, 123, 65), ImGui::GetForegroundDrawList());
							Renderer::GetInstance()->DrawRectAdv(ImVec2(vHp.x + (size * 5) + 1, vHp.y - 23), ImVec2(vHp.x + (size * 6) - 1, vHp.y), D3DCOLOR_ARGB(255, 157, 123, 65), ImGui::GetForegroundDrawList());
						}
					}
				}

			}
		}
	}
	void Draw()
	{
		isLocalDead = !me->IsAlive();
		objectLocationLocal = me->Position();
		objectScreenLocationLocal = Engine::WorldToScreen(objectLocationLocal);

		draw_imgs.clear();
		DrawWards();
		DrawTraps();
		DrawCamps();
		DrawHeros();
		DrawTurrets();
		DrawTroy();
		DrawImages();

		/*auto closestTower = linq::make_enumerable(Engine::GetTurrets(2)).Where([&](const auto & t) { return me->Distance(t, true) < 900 * 900; }).Min();

		Vector3 objectLocationA = closestTower->Position();
		Vector3 objectScreenLocation2A = Engine::WorldToScreen(objectLocationA);

		if (objectLocationA.x != 0 && objectLocationA.z != 0)
		{
			Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2A.x, objectScreenLocation2A.y), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%s %x", closestTower->Name().c_str(), (DWORD)closestTower);
		}*/

		/*
		for (auto object : global::turrets)
			{
				CObject* actor = (CObject*)object;

				Vector3 objectLocation = actor->ServerPosition();
				Vector3 objectScreenLocation2 = Engine::WorldToScreen(objectLocation);

				if (objectLocation.x != 0 && objectLocation.z != 0)
				{
					Renderer::GetInstance()->DrawTextVIP(Renderer::GetInstance()->m_pFont, ImVec2(objectScreenLocation2.x, objectScreenLocation2.y), 15, D3DCOLOR_RGBA(255, 255, 255, 255), true, true, "%s %x", actor->Name().c_str() , (DWORD)actor);
				}
			}
			*/
	}

	void Tick()
	{
	}

	void Init()
	{
		auto menu = NewMenu::CreateMenu("Awareness", "Awareness");
		auto mainSettings = menu->AddMenu("Main", "Hero Settings");
		MoveLocation = mainSettings->AddCheckBox("MoveLocation", "Show Move Location", false);
		LastLocation = mainSettings->AddCheckBox("LastLocation", "Show Last Location", true);
		EnemyLine = mainSettings->AddCheckBox("EnemyLine", "Enemy Line", false);
		EnemyLineOnFlashDown = mainSettings->AddCheckBox("EnemyLineFlashDown", "Enemy Line When Flash Down", false);
		Range = mainSettings->AddCheckBox("Range", "Draw Enemy Range", false);
		Info = mainSettings->AddCheckBox("Info", "Draw Champion Info", true);
		InfoChampion = mainSettings->AddCheckBox("InfoChampion", "Draw Info On HPBar", true);
		DamageHPBar = mainSettings->AddCheckBox("DamageHPBar", "Show Damage On HPBar", false);

		auto gankSettings = menu->AddMenu("GankDetector", "Gank Detector");
		auto pathSettings = gankSettings->AddMenu("PathTracking", "Path Tracking");
		ShowPath = pathSettings->AddCheckBox("PathTracking", "Path Tracking", true);
		ShowPathMM = pathSettings->AddCheckBox("PathTrackingMM", "Show on Minimap", true);
		ShowNotify = gankSettings->AddCheckBox("ShowNotify", "Show Notify on Minimap", true);
		HideInBush = gankSettings->AddCheckBox("HideInBush", "Detect Enemy hiding nearby", true);


		auto turretSettings = menu->AddMenu("TurretSettings", "Turret Settings");
		TurretRange = turretSettings->AddCheckBox("TurretRange", "Show Turret Range", true);


		auto wardSettings = menu->AddMenu("WardSettings", "Ward Settings");
		Ward = wardSettings->AddCheckBox("EnemyWards", "Show Enemy Wards", true);
		WardRange = wardSettings->AddCheckBox("WardsRange", "Show Wards Range", false);
		WardRangeWall = wardSettings->AddCheckBox("WardsRangeWall", "Check Wards Collision", false);
		WardHelper = wardSettings->AddCheckBox("WardHelper", "Show Ward Helper", false);
		WardMinimap = wardSettings->AddCheckBox("WardMinimap", "Show Ward on Minimap", false);

		auto trapSettings = menu->AddMenu("TrapSettings", "Trap Settings");
		Trap = trapSettings->AddCheckBox("EnemyTraps", "Show Enemy Traps", true);


		auto jungleSettings = menu->AddMenu("JungleSettings", "Jungle Settings");
		JungleTimer = jungleSettings->AddCheckBox("JungleTimer", "Show Jungle Timer", true);
		JungleTimerOnMinimap = jungleSettings->AddCheckBox("JungleTimerOnMinimap", "Show Timer on Minimap", true);

		std::cout << colorwin::color(colorwin::cyan) << time_in_HH_MM_SS();
		std::cout << "Awareness Loaded" << std::endl;
	}
};

Awareness* awareness;