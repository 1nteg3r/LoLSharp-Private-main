#pragma once
namespace XPolygon
{
	Vector3 To3D(Vector2 pos, float y = me->Position().y)
	{
		return Vector3(pos.x, Engine::heightForPosition(pos.x, pos.y), pos.y);
	}

	Vector2 To2D(Vector3 pos)
	{
		return Vector2(pos.x, pos.z);
	}

	Vector2 ClosestPointOnSegment(Vector2 s1, Vector2 s2, Vector2 pt)
	{
		auto ab = (s2 - s1);
		auto t = ((pt.x - s1.x) * ab.x + (pt.y - s1.y) * ab.y) / (ab.x * ab.x + ab.y * ab.y);
		return t < 0 ? (s1) : (t > 1 ? (s2) : (s1 + t * ab));
	}

	Vector2 PrependVector(Vector2 pos1, Vector2 pos2, float dist)
	{
		return pos1 + Vector2(pos2 - pos1).Normalized() * dist;
	}

	Vector2 AppendVector(Vector2 pos1, Vector2 pos2, float dist)
	{
		return pos2 + Vector2(pos2 - pos1).Normalized() * dist;
	}

	Vector2 Intersection(Vector2 a1, Vector2 b1, Vector2 a2, Vector2 b2)
	{
		Vector2 r = (b1 - a1), s = (b2 - a2);
		float x = r.Cross(s);
		float t = (a2 - a1).Cross(s) / x, u = (a2 - a1).Cross(r) / x;
		return x != 0 && t >= 0 && t <= 1 && u >= 0 && u <= 1 ? (a1 + t * r) : Vector2::Zero;
	}

	bool IsTargetCollisioned(CObject* actor, float radius)
	{
		std::vector<CObject*> result = {};

		std::vector<CObject*> minions = Engine::GetMinionsAround(2000, 1);
		for (auto minion : minions)
		{
			if (actor == minion)
				continue;

			if (PointOnLineSegment(me->Pos2D(), actor->Pos2D(), minion->Pos2D(), radius + minion->BoundingRadius()))
			{
				return true;
			}
		}

		return false;
	}

	bool IsCollisioned(Vector3 vec, float radius)
	{
		std::vector<CObject*> minions = Engine::GetMinionsAround(2000, 1);
		for (auto minion : minions)
		{

			if (PointOnLineSegment(me->Pos2D(), To2D(vec), minion->Pos2D(), radius + minion->BoundingRadius()))
			{
				return true;
			}
		}

		return false;
	}

	Geometry::Polygon CircleToPolygon(Vector2 pos, float radius, int quality = 26)
	{
		Geometry::Polygon points;
		for (int i = 0; i < quality; i++)
		{
			float angle = 2 * M_PI / quality * (i + 0.5);
			float cx = pos.x + radius * Engine::fastcos(angle);
			float cy = pos.y + radius * Engine::fastsin(angle);
			points.Add(Vector2(round(cx), round(cy)));
		}
		return points;
	}


	Geometry::Polygon RectangleToPolygon(Vector2 startPos, Vector2 endPos, float radius, float offset)
	{
		Geometry::Polygon results;

		auto dir = Vector2(endPos - startPos).Normalized();
		auto perp = (radius + offset) * dir.Perpendicular();
		results.Add(Vector2(startPos + perp - offset * dir));
		results.Add(Vector2(startPos - perp - offset * dir));
		results.Add(Vector2(endPos - perp + offset * dir));
		results.Add(Vector2(endPos + perp + offset * dir));
		return results;
	}

	Vector2 Rotate(Vector2 startPos, Vector2 endPos, float theta)
	{
		auto dx = endPos.x - startPos.x, dy = endPos.y - startPos.y;
		auto px = dx * Engine::fastcos(theta) - dy * Engine::fastsin(theta), py = dx * Engine::fastsin(theta) + dy * Engine::fastcos(theta);
		return Vector2(px + startPos.x, py + startPos.y);
	}

	Geometry::Polygon ConeToPolygon(Vector2 center, Vector2 direction, float angle, float radius)
	{
		Geometry::Polygon points;
		float outRadius = (radius + angle) / (float)Engine::fastcos(2 * M_PI / 22);
		points.Add(center);

		auto Side1 = direction.Rotated(-angle * 0.5f);

		for (int i = 0; i <= 22; i++)
		{
			auto cDirection = Side1.Rotated(i * angle / 22).Normalized();
			points.Add(Vector2(center.x + outRadius * cDirection.x, center.y + outRadius * cDirection.y));
		}
		return points;
	}

	Vector2 LineSegmentIntersection(Vector2 a1, Vector2 b1, Vector2 a2, Vector2 b2)
	{
		auto r = b1 - a1;
		auto s = b2 - a2;
		auto x = r.Cross(s);
		auto t = (a2 - a1).Cross(s) / x;
		auto u = (a2 - a1).Cross(r) / x;

		return x != 0 && t >= 0 && t <= 1 && u >= 0 && u <= 1 ? (a1 + t * r) : Vector2::Zero;
	}

	std::vector<Vector2> FindIntersections(Geometry::Polygon poly, Vector2 p1, Vector2 p2)
	{
		std::vector<Vector2> intersections;

		for (size_t i = 0; i < poly.Points.size(); ++i)
		{
			auto startPos = poly.Points[i];
			auto endPos = poly.Points[i + 1 == poly.Points.size() ? 0 : i + 1];
			//if (i + 1 == poly.size())
			//{
			//	//startPos = poly[poly.size() - 1];
			//	endPos = poly[0];
			//}
			auto inta = LineSegmentIntersection(startPos, endPos, p1, p2);
			if (inta.IsValid())
				intersections.push_back(inta);
		}

		return intersections;
	}

	Vector2 FixPosMinimap(Vector2 pos, double y)
	{
		return Engine::WorldToMinimap(Vector3(pos.x, y, pos.y));
	}

	Vector2 FixPos(Vector2 pos, double y)
	{
		auto test = Engine::WorldToScreenBeta(Vector3(pos.x, y, pos.y));
		return Vector2(test.x, test.y);
	}

	void DrawPolygon(Geometry::Polygon poly, double y, D3DCOLOR color, float thickness = 2.f, bool minimap = false, bool filled = false, bool close = true)
	{
		if (poly.Points.size() < 3)
			return;

		static ImVec2 points[200];
		float a = (color >> 24) & 0xff;
		float r = (color >> 16) & 0xff;
		float g = (color >> 8) & 0xff;
		float b = (color) & 0xff;
		Vector2 world = Vector2::Zero;
		for (int i = 0; i < poly.Points.size(); ++i)
		{
			if (minimap)
				world = FixPosMinimap(poly.Points[i], y);
			else
				world = FixPos(poly.Points[i], y);

			points[i].x = world.x;
			points[i].y = world.y;
		}
		if (!filled)
			ImGui::GetBackgroundDrawList()->AddPolyline(points, poly.Points.size(), ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), close, thickness);
		else
			ImGui::GetBackgroundDrawList()->AddConvexPolyFilled(points, poly.Points.size(), ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)));
	}

	void DrawPolygon(std::vector<Vector3>poly, D3DCOLOR color, float thickness = 2.f, bool minimap = false, bool close = true)
	{
		if (poly.size() < 3)
			return;

		static ImVec2 points[200];
		float a = (color >> 24) & 0xff;
		float r = (color >> 16) & 0xff;
		float g = (color >> 8) & 0xff;
		float b = (color) & 0xff;
		Vector2 world = Vector2::Zero;
		for (int i = 0; i < poly.size(); ++i)
		{
			if (minimap)
				world = Engine::WorldToMinimap(poly[i]);
			else
				world = Engine::WorldToScreenvec2(poly[i]);

			points[i].x = world.x;
			points[i].y = world.y;
		}

		ImGui::GetBackgroundDrawList()->AddPolyline(points, poly.size(), ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), close, thickness);
	}

	void DrawCircle3D(Vector3 vPos, float flPoints, float flRadius, D3DCOLOR clrColor = D3DCOLOR_ARGB(255, 0, 255, 0), float flThickness = 1.f)
	{
		float flPoint = D3DX_PI * 2.0f / flPoints;

		for (float flAngle = 0; flAngle < (D3DX_PI * 2.0f); flAngle += flPoint)
		{
			Vector3 vStart(flRadius * Engine::fastcos(flAngle) + vPos.x, vPos.y, flRadius * Engine::fastsin(flAngle) + vPos.z);
			Vector3 vEnd(flRadius * Engine::fastcos(flAngle + flPoint) + vPos.x, vPos.y, flRadius * Engine::fastsin(flAngle + flPoint) + vPos.z);

			Vector3 vStartScreen = Engine::WorldToScreen(vStart);
			Vector3 vEndScreen = Engine::WorldToScreen(vEnd);

			Renderer::GetInstance()->DrawLine(ImVec2(vStartScreen.x, vStartScreen.y), ImVec2(vEndScreen.x, vEndScreen.y), clrColor, flThickness);
		}
	}

	/*void DrawPolygon(std::vector<Vector2>poly, double y, D3DCOLOR color, float thickness = 1.f)
	{
		if (poly.size() < 3)
			return;

		std::vector<Vector2> path = {};

		for (int i = 0; i < poly.size(); ++i) path.push_back(FixPos(poly[i], y));


		Renderer::GetInstance()->DrawLine(ImVec2(path[path.size() - 1].x, path[path.size() - 1].y), ImVec2(path[0].x, path[0].y), color, thickness);

		for (int i = 0; i < path.size() - 1; ++i)
		{
			Renderer::GetInstance()->DrawLine(ImVec2(path[i].x, path[i].y), ImVec2(path[i + 1].x, path[i + 1].y), color, thickness);
		}
	}*/

	void DrawArrow2(Vector2 startPos, Vector2 endPos, D3DCOLOR color, float thick = 1.f, float height = me->Position().y)
	{
		auto p1 = endPos - ((startPos - endPos).Normalized() * 30).Perpendicular() + (startPos - endPos).Normalized() * 30;
		auto p2 = endPos - ((startPos - endPos).Normalized() * 30).Perpendicular2() + (startPos - endPos).Normalized() * 30;
		startPos = Engine::WorldToScreenvec2(XPolygon::To3D(startPos, height));
		endPos = Engine::WorldToScreenvec2(XPolygon::To3D(endPos, height));

		p1 = Engine::WorldToScreenvec2(XPolygon::To3D(p1, height));
		p2 = Engine::WorldToScreenvec2(XPolygon::To3D(p2, height));

		Renderer::GetInstance()->DrawLine(ImVec2(p1.x, p1.y), ImVec2(endPos.x, endPos.y), color, thick);
		Renderer::GetInstance()->DrawLine(ImVec2(p2.x, p2.y), ImVec2(endPos.x, endPos.y), color, thick);
	}

	void DrawArrow(Vector2 startPos, Vector2 endPos, D3DCOLOR color, float thick = 1.f, float height = me->Position().y)
	{
		auto p1 = endPos - ((startPos - endPos).Normalized() * 30).Perpendicular() + (startPos - endPos).Normalized() * 30;
		auto p2 = endPos - ((startPos - endPos).Normalized() * 30).Perpendicular2() + (startPos - endPos).Normalized() * 30;
		startPos = Engine::WorldToScreenvec2(XPolygon::To3D(startPos, height));
		endPos = Engine::WorldToScreenvec2(XPolygon::To3D(endPos, height));

		p1 = Engine::WorldToScreenvec2(XPolygon::To3D(p1, height));
		p2 = Engine::WorldToScreenvec2(XPolygon::To3D(p2, height));

		Renderer::GetInstance()->DrawLine(ImVec2(startPos.x, startPos.y), ImVec2(endPos.x, endPos.y), color, thick);
		Renderer::GetInstance()->DrawLine(ImVec2(p1.x, p1.y), ImVec2(endPos.x, endPos.y), color, thick);
		Renderer::GetInstance()->DrawLine(ImVec2(p2.x, p2.y), ImVec2(endPos.x, endPos.y), color, thick);
	}

	void DrawCircle(Vector3 Position, float Radius, ImVec4 Color, float Thickness = 1, bool filled = false)
	{
		if (!(MenuSettings::ShowDraw->Value && GetForegroundWindow() == GetLoLWindow()) || Position == Vector3::Zero)
			return;

		g_pEffect->Begin(NULL, NULL);
		d3ddev->SetStreamSource(0,                   //StreamNumber
			g_list_vb,           //StreamData
			0,                   //OffsetInBytes
			sizeof(Vector4)); //Stride


		auto ViewMatrix = global::Matrix.viewmatrix;
		auto ProjectionMatrix = global::Matrix.projmatrix;
		D3DXMATRIX value;

		D3DXMatrixTranslation(&value, Position.x, Position.y, Position.z);
		D3DXMATRIXA16 matrix = (value * ViewMatrix * ProjectionMatrix);
		D3DXVECTOR4 color = D3DXVECTOR4(Color.y / 255.f, Color.z / 255.f, Color.w / 255.f, Color.x / 255.f);

		g_pEffect->BeginPass(0);
		g_pEffect->SetMatrix("ProjectionMatrix", &matrix);
		g_pEffect->SetVector("Color", &color);
		g_pEffect->SetFloat("Radius", Radius);
		g_pEffect->SetFloat("Width", Thickness);
		g_pEffect->SetBool("Filled", filled);
		g_pEffect->SetBool("EnableZ", false);
		g_pEffect->SetFloat("antiAlias", 1.25f);
		g_pEffect->CommitChanges();
		g_pEffect->EndPass();
		d3ddev->DrawPrimitive(D3DPT_TRIANGLELIST, 0, 1);
		g_pEffect->End();
	}
}