#pragma once
#ifndef _renderer_
#define _renderer_
#include "stdafx.h"
#include "ImGui/imgui.h"
#include "ImGui/imgui_impl_dx9.h"
#include "ImGui/imgui_internal.h"
#include <iostream>
#include <string>
#include "Rect.h"

class Renderer
{
public:
	void Initialize(ImFont* pFont);

	void BeginScene();
	void DrawScene();
	void EndScene();

	static Renderer* GetInstance();

	Renderer();
	~Renderer();

	void RenderLine(const ImVec2& from, const ImVec2& to, uint32_t color, float thickness = 1.0f);
	void DrawRect(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness = 1.0f);
	void DrawRectAdv(const ImVec2& aa, const ImVec2& bb, uint32_t color, ImDrawList*pDrawList, float thickness = 1.0f);
	void DrawRectFilledMultiColor(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness = 1.0f);
	void DrawRectFilled(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness = 1.0f, float rounding = 0.0f);
	void DrawRectFilled2(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness = 1.0f, float rounding = 0.0f);
	void AddTriangleFilled(const ImVec2& aa, const ImVec2& bb, const ImVec2& cc, ImU32 color);
	void DrawLine(const ImVec2& from, const ImVec2& to, uint32_t color, float thickness = 1.0f);
	void DrawCircle(const ImVec2& position, float radius, uint32_t color, float thickness = 1.0f, int point = 30);
	void DrawCircleFilled(const ImVec2& position, float radius, uint32_t color, int point = 20);
	void DrawTextVIP(ImFont* pFont, const ImVec2& position, float size, uint32_t color, bool center, bool shadow, const char *fmt, ...);
	ImVec2 GetTextSize(ImFont* pFont, float size, const char * fmt, ...);
	void DrawRectFilledCurrentWindow(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness = 1.0f);
	void DrawPolyLine(const ImVec2* from, int num_points, uint32_t color, float thickness = 1.0f);

	ImFont* m_pFont;

	void AddCircle(Vector2 position, float radius, float thickness = 1.0f, DWORD color = 0xFFFFFFFF);
	void AddCircle(Vector3 position, float radius, float thickness = 1.0f, DWORD color = 0xFFFFFFFF);
	void AddCircleFilled(Vector2 position, float radius, DWORD color = 0xFFFFFFFF);
	void AddCircleFilled(Vector3 position, float radius, DWORD color = 0xFFFFFFFF);
	//AddImage
	void AddLine(Vector2 line1, Vector2 line2, float thickness = 1.0f, DWORD color = 0xFFFFFFFF);
	void AddRectangle(Vector2 position, float width, float height, DWORD color = 0xFFFFFFFF);
	void AddRectangle(Rect rectangle, DWORD color = 0xFFFFFFFF, float thickness = 1);
	void AddRoundedRectangle(Rect rectangle, DWORD color = 0xFFFFFFFF, float thickness = 1, int rounding = 0, int roundSettings = ImDrawCornerFlags_All);
	void AddRectangleFilled(Vector2 position, float width, float height, DWORD color = 0xFFFFFFFF);
	void AddRectangleFilled(Rect rectangle, DWORD color = 0xFFFFFFFF);
	void AddRoundedRectangleFilled(Rect rectangle, DWORD color = 0xFFFFFFFF, int rounding = 0, int roundSettings = ImDrawCornerFlags_All);
	void AddText(const char* text, float size, Vector2 position, DWORD color);
	void AddText(float size, Vector2 position, DWORD color, const char* format, ...);
	void AddText(const char* text, float size, Rect rectangle, DWORD flags, DWORD color);
	void AddText(float size, Rect rectangle, DWORD flags, DWORD color, const char* format, ...);
	void AddTriangle(Vector2 point1, Vector2 point2, Vector2 point3, float thickness = 1.0f, DWORD color = 0xFFFFFFFF);
	void AddTriangleFilled(Vector2 point1, Vector2 point2, Vector2 point3, DWORD color = 0xFFFFFFFF);

	static Renderer* m_pInstance;
};

#endif // !1
