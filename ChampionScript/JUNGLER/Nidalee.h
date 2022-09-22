class Nidalee : public ModuleManager {
private:


public:
	PredictionInput Q = PredictionInput({ 1500,0.25f , 40, 1300,true, SkillshotType::SkillshotLine });
	PredictionInput W = PredictionInput({ 900, 0.25f, 100, FLT_MAX, false, SkillshotType::SkillshotCircle });
	PredictionInput E = PredictionInput({  });
	PredictionInput R = PredictionInput({  });

	Nidalee()
	{

	}

	~Nidalee()
	{

	}


	void Draw()
	{

		//XPolygon::DrawPolygon(me->GetWaypoints3D(), D3DCOLOR_ARGB(255, 0, 0, 255),2,false,false);
		/*auto target = targetselector->GetTarget(Q.Range);

		auto Q1 = prediction->GetPrediction(target, Q);
		auto castpos = XPolygon::To2D(Q1.CastPosition());

		auto lastclick = Engine::WorldToScreenImVec2(target->ServerPosition());
		auto lastclick2 = Engine::WorldToScreenImVec2(Q1.CastPosition());

		Renderer::GetInstance()->DrawLine(lastclick, lastclick2, D3DCOLOR_RGBA(255, 255, 255, 255));*/
		//std::cout << Q1.HitChanceStr() << std::endl;
		/*auto mePos = me->Position();
		auto target = targetselector->GetTarget(Q.Range);

		auto Q1 = prediction->GetPrediction(target, Q);
		auto castpos = XPolygon::To2D(Q1.CastPosition());
		auto castposz = me->Pos2D().Extended(castpos, Q.Range);

		auto path = XPolygon::RectangleToPolygon(me->Pos2D(), castposz, Q.Radius, target->BoundingRadius() / 2);
		XPolygon::DrawPolygon(path, Q1.CastPosition().y, D3DCOLOR_ARGB(255, 0, 0, 255));
		XPolygon::DrawCircle(XPolygon::To3D(target->Pos2D().Extended(XPolygon::AppendVector(target->Pos2D(), castpos, 99999), target->MoveSpeed())), 50, ImVec4(255, 255, 0, 0), 2);
		if (Q1.HitChance() >= HitChance::High)
		{
		}
		
		if (Q1.HitChance() == HitChance::OutOfRange && target->IsMoving())
		{
			ImGui::Text("Out Of Range");
		}

		auto num2 = 150.f;
		auto WallPoint = prediction->GetWallPoint(Q1.CastPosition(), 200.0f);
	

		XPolygon::DrawCircle(WallPoint, 50, ImVec4(255, 0, 0, 255), 2);
		if (WallPoint != Vector3::Zero && WallPoint.Distance(Q1.CastPosition()) < num2 && WallPoint.Distance(target->Position()) < num2)
		{
			Vector2 WallPoint2D = XPolygon::To2D(WallPoint);
			Vector2 vector2 = target->Pos2D() - WallPoint2D;
			Vector2 toVector = XPolygon::To2D(Q1.CastPosition()) - WallPoint2D;
			float num3 = vector2.AngleBetween(toVector);

			XPolygon::DrawCircle(XPolygon::To3D(toVector), 50, ImVec4(255, 0, 0, 255), 2);
			XPolygon::DrawCircle(XPolygon::To3D(WallPoint2D), 50, ImVec4(255, 0, 0, 255), 2);
			std::cout << num3 << std::endl;
			XPolygon::DrawCircle(WallPoint.Extended(Q1.CastPosition(), num2), 50, ImVec4(255, 0, 255, 0), 2);
			if (num3 > 70.0f && num3 < 90.0f)
			{
				XPolygon::DrawCircle(WallPoint.Extended(Q1.CastPosition(), num2), 50, ImVec4(255, 255, 0, 0), 2);
			}
		}*/

	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Nidalee", "Nidalee");
	}



	void KillSteal()
	{


	}



	void Combo()
	{
		auto mePos = me->Position();
		auto target = targetselector->GetTarget(Q.Range);

		auto Q1 = prediction->GetPrediction(target, Q);
		if (Q1.HitChance() >= HitChance::High)
		{
			CastSpell(0, Engine::WorldToScreen(Q1.CastPosition()));
		}

	}


	void LaneClear()
	{



	}


	void LastHit()
	{

	}
	void Harass()
	{


	}
	void Tick()
	{

		orbwalker->UseOrbWalker = true;
		KillSteal();
		if (global::mode== ScriptMode::Combo)
		{
			Combo();
		}
		else if (global::mode== ScriptMode::LaneClear)
		{
			LaneClear();
		}
		else if (global::mode== ScriptMode::Mixed)
		{
			Harass();
		}
		else if (global::mode== ScriptMode::LastHit)
		{
			LastHit();
		}
	}
};