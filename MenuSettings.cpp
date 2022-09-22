#include "stdafx.h"
#include "MenuSettings.h"
#include "Menu.h"

int MenuSettings::BackgroundOpacity = 200;
KeyBind* MenuSettings::ShowDraw;
bool MenuSettings::DrawMenu = false;
int MenuSettings::DrawTicksPerSecond = 60;
int MenuSettings::UpdateTicksPerSecond = 1;
int MenuSettings::ComboTicksPerSecond = 60;
int MenuSettings::Ping = 20;
float MenuSettings::MinimapScaling = 1;
bool MenuSettings::RightSide = true;
bool MenuSettings::AntiAFK = true;