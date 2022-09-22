#include "stdafx.h"
#include "Slider.h"
#include "Menu.h"
#include "MenuSettings.h"
#include "Renderer.h"
#include "HudManager.h"


Slider::Slider(const char* name, const char* displayName, int defaultValue, int minimumValue, int maximumValue, int step, std::function<void(Slider*, int)> callback) {
	strncpy_s(this->Name, name, sizeof(this->Name));
	strncpy_s(this->DisplayName, displayName, sizeof(this->DisplayName));
	this->MinimumValue = min(minimumValue, maximumValue);
	this->MaximumValue = max(maximumValue, minimumValue);
	this->Value = min(this->MaximumValue, max(this->MinimumValue, defaultValue));
	this->Step = step;
	this->Callback = callback;
	this->Tooltip[0] = 0;
}

void Slider::AddTooltip(const char* tooltip)
{
	strncpy_s(this->Tooltip, tooltip, sizeof(this->Tooltip));
}

void Slider::GetSave(json& j) {
	j[this->Name] = json{ {"value", this->Value} };
}

Vector2 Slider::GetPosition() {
	auto& components = this->Parent->Components;
	for (auto i = 0; i < components.size(); i++) {
		auto component = components[i];
		if (component == this) {
			return this->Parent->GetPosition() + Vector2(this->Parent->GetWidth(), MenuComponent::Height * (i + this->Parent->Children.size()));
		}
	}

	return Vector2::Zero;
}

float Slider::GetWidth() {
	auto value = 0.0f;

	for (auto child : this->Parent->Children) {
		value = max(value, child->NeededWidth());
	}
	for (auto component : this->Parent->Components) {
		value = max(value, component->NeededWidth());
	}

	return max(MenuComponent::Width, value);
}

float Slider::NeededWidth() {
	return 10.0f + Renderer::GetInstance()->m_pFont->CalcTextSizeA(16, FLT_MAX, 0.0f, this->DisplayName).x + 5.0f + Renderer::GetInstance()->m_pFont->CalcTextSizeA(16, FLT_MAX, 0.0f, std::to_string(this->MaximumValue).c_str()).x + 5.0f;
}

void Slider::Draw() {
	if (!this->Visible) {
		return;
	}

	auto position = this->GetPosition();
	auto rect = Rect(position.x, position.y, this->GetWidth(), MenuComponent::Height);
	auto percentage = ((float)(this->Value - this->MinimumValue) / (this->MaximumValue - this->MinimumValue));

	if (this->Value != this->MinimumValue) {
		Renderer::GetInstance()->AddRectangleFilled(Rect(rect.Position.x, rect.Position.y, rect.Width * percentage, rect.Height), IM_COL32(0, 35, 54, 255));
	}
	if (this->Value != this->MaximumValue) {
		Renderer::GetInstance()->AddRectangleFilled(Rect(rect.Position.x + rect.Width * percentage, rect.Position.y, rect.Width * (1 - percentage), rect.Height), IM_COL32(17, 32, 33, MenuSettings::BackgroundOpacity));
	}

	Renderer::GetInstance()->AddRectangle(rect, IM_COL32(143, 122, 72, 255));
	Renderer::GetInstance()->AddLine(Vector2(rect.Position.x + rect.Width * percentage, rect.Position.y), Vector2(rect.Position.x + rect.Width * percentage, rect.Position.y + rect.Height), 2.0f, IM_COL32(255, 0, 0, 255));
	Renderer::GetInstance()->AddText(this->DisplayName, 14.0f, Rect(rect.Position.x + 10.0f, rect.Position.y, 0.0f, rect.Height), DT_VCENTER, IM_COL32(189, 190, 172, 255));
	Renderer::GetInstance()->AddText(14.0f, Rect(rect.Position.x, rect.Position.y, rect.Width - 5.0f, rect.Height), DT_RIGHT | DT_VCENTER, IM_COL32(189, 190, 172, 255), "%d", this->Value);

	//TODO
	if (this->Tooltip[0] != 0)
	{
		auto textWidth = 10.0f + Renderer::GetInstance()->m_pFont->CalcTextSizeA(14, FLT_MAX, 0.0f, this->DisplayName).x;
		auto mousePos = HudManager::CursorPos2D;
		auto iconRect = Rect(rect.Position.x + textWidth + 5, rect.Position.y + Height * 0.5f - 10.0f, 20, 20);
		Renderer::GetInstance()->AddText("(?)", 16.0f, iconRect, DT_VCENTER, IM_COL32(255, 30, 30, 255));

		if (iconRect.Contains(mousePos))
		{
			auto alpha = min(MenuSettings::BackgroundOpacity + 70, 255);
			auto black = IM_COL32(0, 0, 0, alpha);
			auto width = 20.0f + Renderer::GetInstance()->m_pFont->CalcTextSizeA(14, FLT_MAX, 0.0f, this->Tooltip).x;
			auto tooltipRect = Rect(mousePos.x + 20, mousePos.y - Height * 0.5f, width, Height);
			Renderer::GetInstance()->AddRoundedRectangleFilled(tooltipRect, black, 4, ImDrawCornerFlags_All);
			Renderer::GetInstance()->AddRoundedRectangle(tooltipRect, black, 1.1f, 4, ImDrawCornerFlags_All);
			Renderer::GetInstance()->AddText(this->Tooltip, 14.0f, Rect(tooltipRect.Position.x + 10.0f, tooltipRect.Position.y, 0.0f, rect.Height), DT_VCENTER, IM_COL32(255, 255, 255, 255));
		}
	}
}

void Slider::WndProc(UINT msg, WPARAM wparam, Vector2 cursorPos) {
	if (!this->Visible || !this->Parent->IsVisible()) {
		return;
	}

	auto position = this->GetPosition();
	auto rect = Rect(position.x, position.y, this->GetWidth(), MenuComponent::Height);

	if ((msg == WM_MOUSEMOVE && this->Interacting) || (/*msg == WM_LBUTTONDOWN*/ ImGui::GetIO().MouseDown[0] && !this->Interacting && rect.Contains(cursorPos))) {
		this->Value = min(this->MaximumValue, max(this->MinimumValue, (int)((((cursorPos.x - rect.Position.x) / rect.Width) * (this->MaximumValue - this->MinimumValue) + this->MinimumValue) / this->Step) * this->Step));
		if (this->Callback) {
			this->Callback(this, this->Value);
		}
	}

	if (/*msg == WM_LBUTTONDOWN*/(ImGui::GetIO().MouseDown[0] && rect.Contains(cursorPos)) || !ImGui::GetIO().MouseDown[0] /*msg == WM_LBUTTONUP*/) {
		this->Interacting = ImGui::GetIO().MouseDown[0];// msg == WM_LBUTTONDOWN;
	}
}