#include "stdafx.h"
#include "Menu.h"
#include "MenuSettings.h"
#include "Renderer.h"
#include "Keybind.h"
#include "List.h"
#include "Slider.h"
#include "HudManager.h"

Vector2 NewMenu::BasePosition = Vector2(30.0f, 30.0f);
Vector2 NewMenu::DragPosition = Vector2();
bool NewMenu::IsDragging = false;
std::vector<NewMenu*> NewMenu::RootMenus;
json NewMenu::MenuSave;

NewMenu::NewMenu(const char* name, const char* displayName) {
	strncpy(this->Name, name, sizeof(this->Name));
	strncpy(this->DisplayName, displayName, sizeof(this->DisplayName));
	this->Tooltip[0] = 0;
}

NewMenu::~NewMenu() {
	for (auto child : this->Children) {
		delete child;
	}

	for (auto component : this->Components) {
		delete component;
	}
}
bool is_empty(std::ifstream& pFile)
{
	return pFile.peek() == std::ifstream::traits_type::eof();
}
void NewMenu::SetVisible(bool value) {
	this->Visible = value;

	if (!value) {
		this->Interacting = false;
		for (auto menu : this->Children) {
			menu->SetVisible(false);
		}
		for (auto component : this->Components) {
			component->Visible = false;
			component->Interacting = false;
		}
	}
}

void NewMenu::Initialize() {
	std::ifstream file("Config.yts");
	if (file.is_open()) {
		if (!is_empty(file))
		{
			file >> MenuSave;
			auto& savedBasePositionX = MenuSave["LoLSharp"]["MenuSettings"]["BasePosition"]["X"];
			auto& savedBasePositionY = MenuSave["LoLSharp"]["MenuSettings"]["BasePosition"]["Y"];
			if (!savedBasePositionX.is_null() && !savedBasePositionY.is_null()) {
				BasePosition = Vector2(savedBasePositionX, savedBasePositionY);
			}
		}
	}

	auto menu = NewMenu::CreateMenu("YTSPlusPlus", "YTS++");

	auto menuSettings = menu->AddMenu("MenuSettings", "Menu Settings");

	MenuSettings::DrawMenu = false;
	menuSettings->AddKeyBind("MenuKey", "Menu Key", VK_F1, false, false, [](KeyBind*, bool value) {
		MenuSettings::DrawMenu = value;
	});
	MenuSettings::ShowDraw = menuSettings->AddKeyBind("ShowDraw", "Show All Draw", VK_F6, true, true);


	auto coreMenu = menu->AddMenu("Core", "Core");
	MenuSettings::DrawTicksPerSecond = coreMenu->AddSlider("DrawTicksPerSecond", "Draw FPS", 60, 60, 240, 10, [](Slider*, int value) {
		MenuSettings::DrawTicksPerSecond = value;
	})->Value;

	MenuSettings::ComboTicksPerSecond = coreMenu->AddSlider("ComboTicksPerSecond", "Combo FPS", 60, 60, 240, 10, [](Slider*, int value) {
		MenuSettings::ComboTicksPerSecond = value;
	})->Value;

	auto hacksMenu = menu->AddMenu("Hacks", "Hacks");
	MenuSettings::AntiAFK = hacksMenu->AddCheckBox("AntiAFK", "Anti AFK", false, [](CheckBox*, bool value) {
		MenuSettings::AntiAFK = value;
	})->Value;

	auto MinimapSettings = menu->AddMenu("MiniMapSettings", "MiniMap Settings");
	MenuSettings::MinimapScaling = MinimapSettings->AddSlider("MinimapScaling", "Match your Minimap Scaling", 1, 1, 100, 1, [](Slider*, int value) {
		MenuSettings::MinimapScaling = value;
	})->Value;
	MenuSettings::RightSide = MinimapSettings->AddCheckBox("MinimapRightSide", "Minimap on Right Side", true, [](CheckBox*, bool value) {
		MenuSettings::RightSide = value;
	})->Value;
}

void NewMenu::Dispose() {
	for (auto menu : RootMenus) {
		menu->GetSave(MenuSave);
		delete menu;
	}
	RootMenus.clear();

	MenuSave["LoLSharp"]["MenuSettings"]["BasePosition"]["X"] = BasePosition.x;
	MenuSave["LoLSharp"]["MenuSettings"]["BasePosition"]["Y"] = BasePosition.y;

	if (!MenuSave.is_null())
	{
		std::ofstream file("Config.yts");
		if (file.is_open()) {
			file << MenuSave.dump(4);
			file.close();
		}
	}
}

void NewMenu::OnDraw() {

	if (!MenuSettings::DrawMenu) {
		return;
	}

	for (auto menu : RootMenus) {
		menu->Draw();
	}
	for (auto menu : RootMenus) {
		menu->GetSave(MenuSave);
	}
	//std::cout << MenuSave.dump() << std::endl;
	if (!MenuSave.empty())
	{
		std::ofstream file("Config.yts");
		if (file.is_open()) {
			file << MenuSave.dump(4);
		}
	}

}

void NewMenu::OnWndProc(UINT msg, WPARAM wparam) {
	if (IsDragging) {
		if (msg == WM_MOUSEMOVE) {
			BasePosition = DragPosition + HudManager::CursorPos2D;
		}
		/*else*/ if (!ImGui::GetIO().MouseDown[0]) { //msg == WM_LBUTTONUP
			IsDragging = false;
		}
	}
	for (auto menu : RootMenus) {
		menu->WndProc(msg, wparam, HudManager::CursorPos2D);
	}
}

NewMenu* NewMenu::CreateMenu(const char* name, const char* displayName) {
	auto menu = new NewMenu(name, displayName);
	menu->Save = MenuSave[name];
	RootMenus.push_back(menu);
	return menu;
}

NewMenu* NewMenu::AddMenu(const char* name, const char* displayName) {
	auto menu = new NewMenu(name, displayName);
	menu->Save = this->Save[name];
	menu->Parent = this;
	this->Children.push_back(menu);
	return menu;
}

CheckBox* NewMenu::AddCheckBox(const char* name, const char* displayName, bool defaultValue, std::function<void(CheckBox*, bool)> callback) {
	auto component = new CheckBox(name, displayName, defaultValue, callback);
	component->Save = this->Save[name];
	auto& savedValue = component->Save["value"];
	if (!savedValue.is_null()) {
		component->Value = savedValue;
	}
	component->Parent = this;
	this->Components.push_back(component);
	return component;
}

Info* NewMenu::AddInfo(const char* name, const char* displayName) {
	auto component = new Info(name, displayName);
	component->Parent = this;
	this->Components.push_back(component);
	return component;
}

KeyBind* NewMenu::AddKeyBind(const char* name, const char* displayName, unsigned char key, bool defaultValue, bool isToggle, std::function<void(KeyBind*, bool)> callback) {
	auto component = new KeyBind(name, displayName, key, defaultValue, isToggle, callback);
	component->Save = this->Save[name];
	auto& savedKey = component->Save["key"];
	auto& savedValue = component->Save["value"];
	if (!savedKey.is_null()) {
		component->Key = savedKey;
	}
	if (!savedValue.is_null()) {
		component->Value = savedValue;
	}
	component->Parent = this;
	this->Components.push_back(component);
	return component;
}

List* NewMenu::AddList(const char* name, const char* displayName, std::vector<std::string> items, unsigned int defaultIndex, std::function<void(List*, unsigned int)> callback) {
	auto component = new List(name, displayName, items, defaultIndex, callback);
	component->Save = this->Save[name];
	auto& savedValue = component->Save["value"];
	if (!savedValue.is_null()) {
		component->Value = min((unsigned int)savedValue, items.size() - 1);
	}
	component->Parent = this;
	this->Components.push_back(component);
	return component;
}

Slider* NewMenu::AddSlider(const char* name, const char* displayName, int defaultValue, int minimumValue, int maximumValue, int step, std::function<void(Slider*, int)> callback) {
	auto component = new Slider(name, displayName, defaultValue, minimumValue, maximumValue, step, callback);
	component->Save = this->Save[name];
	auto& savedValue = component->Save["value"];
	if (!savedValue.is_null()) {
		component->Value = min(component->MaximumValue, max(component->MinimumValue, (int)savedValue));
	}
	component->Parent = this;
	this->Components.push_back(component);
	return component;
}

bool NewMenu::IsVisible() {
	return MenuSettings::DrawMenu && (!this->Parent || this->Visible);
}

void NewMenu::AddTooltip(const char* tooltip)
{
	strncpy_s(this->Tooltip, tooltip, sizeof(this->Tooltip));
}

void NewMenu::GetSave(json & j) {

	j[this->Name] = {};

	for (auto child : this->Children) {
		child->GetSave(j[this->Name]);
	}

	for (auto component : this->Components) {
		component->GetSave(j[this->Name]);
	}

	if (j[this->Name].is_null()) {
		j.erase(this->Name);
	}
}

Vector2 NewMenu::GetPosition() {
	if (this->Parent) {
		auto& children = this->Parent->Children;
		for (auto i = 0; i < children.size(); i++) {
			auto child = children[i];
			if (child == this) {
				return this->Parent->GetPosition() + Vector2(this->Parent->GetWidth(), MenuComponent::Height * i);
			}
		}
	}
	else {
		for (auto i = 0; i < RootMenus.size(); i++) {
			auto menu = RootMenus[i];
			if (menu == this) {
				return BasePosition + Vector2(0, MenuComponent::Height * i);
			}
		}
	}
	return Vector2::Zero;
}

float NewMenu::GetWidth() {
	auto value = 0.0f;

	if (this->Parent) {
		for (auto child : this->Parent->Children) {
			value = max(value, child->NeededWidth());
		}
		for (auto component : this->Parent->Components) {
			value = max(value, component->NeededWidth());
		}
	}
	else {
		for (auto menu : RootMenus) {
			value = max(value, menu->NeededWidth());
		}
	}

	return max(MenuComponent::Width, value);
}

float NewMenu::NeededWidth() {
	return 10.0f + Renderer::GetInstance()->m_pFont->CalcTextSizeA(16, FLT_MAX, 0.0f, this->DisplayName).x + 5.0f + MenuComponent::Height * 0.45f;
}

void NewMenu::Draw() {
	if (!this->IsVisible()) {
		return;
	}

	auto position = this->GetPosition();
	auto rect = Rect(position.x, position.y, this->GetWidth(), MenuComponent::Height);

	Renderer::GetInstance()->AddRectangleFilled(rect, this->Interacting ? IM_COL32(8, 46, 61, 255) : IM_COL32(17, 32, 33, MenuSettings::BackgroundOpacity));
	Renderer::GetInstance()->AddRectangle(rect, IM_COL32(143, 122, 72, MenuSettings::BackgroundOpacity));
	Renderer::GetInstance()->AddText(this->DisplayName, 14.0f, Rect(rect.Position.x + 10.0f, rect.Position.y, 0.0f, rect.Height), DT_VCENTER, IM_COL32(189, 190, 172, 255));

	if (!this->Children.empty() || !this->Components.empty()) {
		auto p1 = Vector2(rect.Position.x + rect.Width - (int)(rect.Height * 0.2f), rect.Position.y + (int)(rect.Height * 0.5f));
		auto p2 = Vector2(rect.Position.x + rect.Width - (int)(rect.Height * 0.45f), rect.Position.y + (int)(rect.Height * 0.65f));
		auto p3 = Vector2(rect.Position.x + rect.Width - (int)(rect.Height * 0.45f), rect.Position.y + (int)(rect.Height * 0.35f));

		Renderer::GetInstance()->AddTriangleFilled(p1, p2, p3, /*this->Interacting ? IM_COL32(255, 0, 0, 255) :*/ IM_COL32(189, 190, 172, 255));

		for (auto child : this->Children) {
			child->Draw();
		}

		for (auto component : this->Components) {
			component->Draw();
		}
	}

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

void NewMenu::WndProc(UINT msg, WPARAM wparam, Vector2 cursorPos) {
	for (auto child : this->Children) {
		child->WndProc(msg, wparam, cursorPos);
	}

	for (auto component : this->Components) {
		component->WndProc(msg, wparam, cursorPos);
	}

	auto position = this->GetPosition();
	auto rect = Rect(position.x, position.y, this->GetWidth(), MenuComponent::Height);

	if (!this->IsVisible() || !rect.Contains(cursorPos)) {
		return;
	}

	if (!IsDragging && ImGui::GetIO().MouseDown[0]) {
		IsDragging = true;
		DragPosition = BasePosition - cursorPos;
	}

	if (ImGui::GetIO().MouseClicked[0])
	{
		if (!this->Parent) {
			for (auto menu : RootMenus) {
				if (menu != this) {
					menu->SetVisible(false);
				}
			}
		}
		else {
			for (auto menu : this->Parent->Children) {
				if (menu != this) {
					menu->Interacting = false;
					for (auto child : menu->Children) {
						child->SetVisible(false);
					}
					for (auto component : menu->Components) {
						component->Visible = false;
						component->Interacting = false;
					}
				}
			}
			for (auto component : this->Parent->Components) {
				component->Interacting = false;
			}
		}

		if (!this->Children.empty() || !this->Components.empty()) {
			this->Interacting = !this->Interacting;
		}

		for (auto child : this->Children) {
			child->SetVisible(!child->Visible);
		}

		for (auto component : this->Components) {
			component->Visible = !component->Visible;
			component->Interacting = false;
		}
	}
}

MenuComponent* NewMenu::operator[](std::string key) {
	for (auto child : this->Children) {
		if (child->Name == key) {
			return child;
		}
	}

	for (auto component : this->Components) {
		if (component->Name == key) {
			return component;
		}
	}

	return nullptr;
}