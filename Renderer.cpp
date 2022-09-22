#include "Renderer.h"
#include "ImGui/imgui_internal.h"
#include <iostream>
#include <sstream>
Renderer* Renderer::m_pInstance;

Renderer::Renderer()
{
}

Renderer::~Renderer()
{
}

void Renderer::Initialize(ImFont* pFont)
{

	m_pFont = pFont;

}

void Renderer::BeginScene()
{
	ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 0.0f));
	ImGui::Begin("xd", reinterpret_cast<bool*>(true), ImVec2(0, 0), 0.0f, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoInputs);

	ImGui::SetWindowPos(ImVec2(0, 0), ImGuiCond_Always);
	ImGui::SetWindowSize(ImVec2(ImGui::GetIO().DisplaySize.x, ImGui::GetIO().DisplaySize.y), ImGuiCond_Always);
}

void Renderer::DrawScene()
{
	ImGuiIO& io = ImGui::GetIO();
}

void Renderer::RenderLine(const ImVec2& from, const ImVec2& to, uint32_t color, float thickness)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetBackgroundDrawList()->AddLine(from, to, ImGui::GetColorU32({ r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f }), thickness);
}

void Renderer::EndScene()
{
	ImGui::End();
	ImGui::PopStyleColor();
}

ImVec2 Renderer::GetTextSize(ImFont* pFont, float size, const char * fmt, ...)
{
	char buf[1024] = { 0 };
	va_list va_alist;

	va_start(va_alist, fmt);
	vsprintf_s(buf, fmt, va_alist);
	va_end(va_alist);

	ImVec2 textSize = pFont->CalcTextSizeA(size, FLT_MAX, 0.0f, buf);
	//delete va_alist;
	memset(va_alist, 0, sizeof(va_alist));
	memset(buf, 0, sizeof(buf));
	return textSize;
}

void Renderer::DrawTextVIP(ImFont* pFont, const ImVec2& pos, float size, uint32_t color, bool center, bool shadow, const char *fmt, ...)
{
	char buf[1024] = { 0 };
	va_list va_alist;

	va_start(va_alist, fmt);
	vsprintf_s(buf, fmt, va_alist);
	va_end(va_alist);


	//ImGuiWindow* window = ImGui::GetCurrentWindow();
	int i = 0;

	ImVec2 textSize = pFont->CalcTextSizeA(size, FLT_MAX, 0.0f, buf);

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	if (center)
	{
		if (shadow)
		{
			ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2((pos.x - textSize.x / 2.0f) + 1, (pos.y + textSize.y * i) + 1), ImGui::GetColorU32(ImVec4(0, 0, 0, 255)), buf);
			ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2((pos.x - textSize.x / 2.0f) - 1, (pos.y + textSize.y * i) - 1), ImGui::GetColorU32(ImVec4(0, 0, 0, 255)), buf);
			ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2((pos.x - textSize.x / 2.0f) + 1, (pos.y + textSize.y * i) - 1), ImGui::GetColorU32(ImVec4(0, 0, 0, 255)), buf);
			ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2((pos.x - textSize.x / 2.0f) - 1, (pos.y + textSize.y * i) + 1), ImGui::GetColorU32(ImVec4(0, 0, 0, 255)), buf);
		}


		ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2(pos.x - textSize.x / 2.0f, pos.y + textSize.y * i), ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), buf);
	}
	else
	{
		if (shadow)
		{
			ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2((pos.x) + 1, (pos.y + textSize.y * i) + 1), ImGui::GetColorU32(ImVec4(0, 0, 0, 255)), buf);
			ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2((pos.x) - 1, (pos.y + textSize.y * i) - 1), ImGui::GetColorU32(ImVec4(0, 0, 0, 255)), buf);
			ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2((pos.x) + 1, (pos.y + textSize.y * i) - 1), ImGui::GetColorU32(ImVec4(0, 0, 0, 255)), buf);
			ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2((pos.x) - 1, (pos.y + textSize.y * i) + 1), ImGui::GetColorU32(ImVec4(0, 0, 0, 255)), buf);
		}

		ImGui::GetForegroundDrawList()->AddText(pFont, size, ImVec2(pos.x, pos.y + textSize.y * i), ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), buf);
	}
	//delete va_alist;
	memset(buf, 0, sizeof(buf));
}

void Renderer::DrawPolyLine(const ImVec2* from, int num_points, uint32_t color, float thickness)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetForegroundDrawList()->AddPolyline(from, num_points, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), true, thickness);
}

void Renderer::DrawLine(const ImVec2& from, const ImVec2& to, uint32_t color, float thickness)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetBackgroundDrawList()->AddLine(from, to, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), thickness);
}

void Renderer::AddTriangleFilled(const ImVec2& aa, const ImVec2& bb, const ImVec2& cc, ImU32 color)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetBackgroundDrawList()->AddTriangleFilled(aa, bb, cc, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)));
}

void Renderer::DrawRectAdv(const ImVec2& aa, const ImVec2& bb, uint32_t color, ImDrawList*pDrawList, float thickness)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	pDrawList->AddRect(aa, bb, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), 0, 15, thickness);
}

void Renderer::DrawRect(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetBackgroundDrawList()->AddRect(aa, bb, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), 0, 15, thickness);
}

void Renderer::DrawRectFilledCurrentWindow(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetForegroundDrawList()->AddRectFilled(aa, bb, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)));
}

void Renderer::DrawRectFilledMultiColor(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	//ImGui::GetBackgroundDrawList()->AddRectFilledMultiColor(aa, bb, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)));
}

void Renderer::DrawRectFilled(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness, float rounding)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetBackgroundDrawList()->AddRectFilled(aa, bb, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), rounding);
}

void Renderer::DrawRectFilled2(const ImVec2& aa, const ImVec2& bb, uint32_t color, float thickness, float rounding)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetBackgroundDrawList()->AddRectFilled(aa, bb, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), rounding, ImDrawCornerFlags_TopLeft | ImDrawCornerFlags_BotRight);
}

void Renderer::DrawCircle(const ImVec2& position, float radius, uint32_t color, float thickness,int point)
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetForegroundDrawList()->AddCircle(position, radius, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), point, thickness);
}

void Renderer::DrawCircleFilled(const ImVec2& position, float radius, uint32_t color, int point )
{

	float a = (color >> 24) & 0xff;
	float r = (color >> 16) & 0xff;
	float g = (color >> 8) & 0xff;
	float b = (color) & 0xff;

	ImGui::GetForegroundDrawList()->AddCircleFilled(position, radius, ImGui::GetColorU32(ImVec4(r / 255, g / 255, b / 255, a / 255)), point);
}


void Renderer::AddCircle(Vector2 position, float radius, float thickness, DWORD color) {
	ImGui::GetForegroundDrawList()->AddCircle(*(ImVec2*)& position, radius, color, 100, thickness);
}

void Renderer::AddCircle(Vector3 position, float radius, float thickness, DWORD color) {
	/*if ((color & IM_COL32_A_MASK) == 0)
		return;

	ImGui::GetForegroundDrawList()->_Path.reserve(ImGui::GetForegroundDrawList()->_Path.Size + 100);
	for (auto i = 0; i <= 99; i++) {
		auto angle = (float)i * IM_PI * 1.98f / 99.0f;
		Vector2 pos = WorldToScreenvec2(Vector3(position.x + ImCos(angle) * radius, position.y, position.z + ImSin(angle) * radius));
		ImGui::GetForegroundDrawList()->_Path.push_back(*(ImVec2*)& pos);
	}
	ImGui::GetForegroundDrawList()->PathStroke(color, true, thickness);*/
}

void Renderer::AddCircleFilled(Vector2 position, float radius, DWORD color) {
	ImGui::GetForegroundDrawList()->AddCircleFilled(*(ImVec2*)& position, radius, color, 100);
}

void Renderer::AddCircleFilled(Vector3 position, float radius, DWORD color) {
	/*if ((color & IM_COL32_A_MASK) == 0)
		return;

	ImGui::GetForegroundDrawList()->_Path.reserve(ImGui::GetForegroundDrawList()->_Path.Size + 100);
	for (auto i = 0; i <= 99; i++) {
		auto angle = (float)i * IM_PI * 1.98f / 99.0f;
		Vector2 pos = WorldToScreenvec2(Vector3(position.x + ImCos(angle) * radius, position.y, position.z + ImSin(angle) * radius));
		ImGui::GetForegroundDrawList()->_Path.push_back(*(ImVec2*)& pos);
	}
	ImGui::GetForegroundDrawList()->PathFillConvex(color);*/
}

void Renderer::AddLine(Vector2 line1, Vector2 line2, float thickness, DWORD color) {
	ImGui::GetForegroundDrawList()->AddLine(*(ImVec2*)& line1, *(ImVec2*)& line2, color, thickness);
}

void Renderer::AddRectangle(Vector2 position, float width, float height, DWORD color) {
	ImGui::GetForegroundDrawList()->AddRect(*(ImVec2*)& position, ImVec2(position.x + width, position.y + height), color);
}

void Renderer::AddRectangle(Rect rectangle, DWORD color, float thickness) {
	ImGui::GetForegroundDrawList()->AddRect(ImVec2(rectangle.Position.x, rectangle.Position.y), ImVec2(rectangle.Position.x + rectangle.Width, rectangle.Position.y + rectangle.Height), color, 0, ImDrawCornerFlags_All, thickness);
}

void Renderer::AddRoundedRectangle(Rect rectangle, DWORD color, float thickness, int rounding,
	int roundSettings)
{
	ImGui::GetForegroundDrawList()->AddRect(ImVec2(rectangle.Position.x, rectangle.Position.y), ImVec2(rectangle.Position.x + rectangle.Width, rectangle.Position.y + rectangle.Height), color, rounding, roundSettings, thickness);
}

void Renderer::AddRectangleFilled(Vector2 position, float width, float height, DWORD color) {
	ImGui::GetForegroundDrawList()->AddRectFilled(*(ImVec2*)& position, ImVec2(position.x + width, position.y + height), color);
}

void Renderer::AddRectangleFilled(Rect rectangle, DWORD color) {
	ImGui::GetForegroundDrawList()->AddRectFilled(ImVec2(rectangle.Position.x, rectangle.Position.y), ImVec2(rectangle.Position.x + rectangle.Width, rectangle.Position.y + rectangle.Height), color);
}

void Renderer::AddRoundedRectangleFilled(Rect rectangle, DWORD color, int rounding,
	int roundSettings)
{
	ImGui::GetForegroundDrawList()->AddRectFilled(ImVec2(rectangle.Position.x, rectangle.Position.y), ImVec2(rectangle.Position.x + rectangle.Width, rectangle.Position.y + rectangle.Height), color, rounding, roundSettings);
}

void Renderer::AddText(const char* text, float size, Vector2 position, DWORD color) {
	ImGui::GetForegroundDrawList()->AddText(this->m_pFont, size, *(ImVec2*)& position, color, text);
}

void Renderer::AddText(float size, Vector2 position, DWORD color, const char* format, ...) {
	char buffer[256];
	va_list args;
	va_start(args, format);
	vsprintf_s(buffer, 256, format, args);
	va_end(args);
	ImGui::GetForegroundDrawList()->AddText(this->m_pFont, size, *(ImVec2*)& position, color, buffer);
}

void Renderer::AddText(const char* text, float size, Rect rectangle, DWORD flags, DWORD color) {
	auto textSize = this->m_pFont->CalcTextSizeA(size, FLT_MAX, 0.0f, text);
	auto position = ImVec2(rectangle.Position.x, rectangle.Position.y);

	if (flags & DT_CENTER) {
		position.x = rectangle.Position.x + (rectangle.Width - textSize.x) * 0.5f;
	}
	else if (flags & DT_RIGHT) {
		position.x = rectangle.Position.x + rectangle.Width - textSize.x;
	}

	if (flags & DT_VCENTER) {
		position.y = rectangle.Position.y + (rectangle.Height - textSize.y) * 0.5f;
	}
	else if (flags & DT_BOTTOM) {
		position.y = rectangle.Position.y + rectangle.Height - textSize.y;
	}

	ImGui::GetForegroundDrawList()->AddText(this->m_pFont, size, position, color, text);
}

void Renderer::AddText(float size, Rect rectangle, DWORD flags, DWORD color, const char* format, ...) {
	char buffer[256];
	va_list args;
	va_start(args, format);
	vsprintf_s(buffer, 256, format, args);
	va_end(args);

	auto textSize = this->m_pFont->CalcTextSizeA(size, FLT_MAX, 0.0f, buffer);
	auto position = ImVec2(rectangle.Position.x, rectangle.Position.y);

	if (flags & DT_CENTER) {
		position.x = rectangle.Position.x + (rectangle.Width - textSize.x) * 0.5f;
	}
	else if (flags & DT_RIGHT) {
		position.x = rectangle.Position.x + rectangle.Width - textSize.x;
	}

	if (flags & DT_VCENTER) {
		position.y = rectangle.Position.y + (rectangle.Height - textSize.y) * 0.5f;
	}
	else if (flags & DT_BOTTOM) {
		position.y = rectangle.Position.y + rectangle.Height - textSize.y;
	}

	ImGui::GetForegroundDrawList()->AddText(this->m_pFont, size, position, color, buffer);
}

void Renderer::AddTriangle(Vector2 point1, Vector2 point2, Vector2 point3, float thickness, DWORD color) {
	ImGui::GetForegroundDrawList()->AddTriangle(*(ImVec2*)& point1, *(ImVec2*)& point2, *(ImVec2*)& point3, color, thickness);
}

void Renderer::AddTriangleFilled(Vector2 point1, Vector2 point2, Vector2 point3, DWORD color) {
	ImGui::GetForegroundDrawList()->AddTriangleFilled(*(ImVec2*)& point1, *(ImVec2*)& point2, *(ImVec2*)& point3, color);
}

Renderer* Renderer::GetInstance()
{
	if (!m_pInstance)
		m_pInstance = new Renderer();

	return m_pInstance;
}