#pragma once
float last_movetoorder = 0;
float last_movetoorderevade = 0;
float last_attackorder = 0;
float last_smiteorder = 0;
float last_castorder = 0;
float humanizer_delay = .01f;///1000.0f;
POINT previousMousePos;

BYTE NtUserSendInput_Bytes[30];

BOOLEAN WINAPI NtUserSendInput(UINT cInputs, LPINPUT pInputs, int cbSize)
{
	NTSTATUS Result;
	if (usespoofsendinput)
	{
		LPVOID NtUserSendInput_Spoof = VirtualAlloc(0, 0x1000, MEM_COMMIT, PAGE_EXECUTE_READWRITE); // allocate space for syscall
		if (!NtUserSendInput_Spoof)
			return FALSE;
		memcpy(NtUserSendInput_Spoof, NtUserSendInput_Bytes, 30); // copy syscall
		Result = reinterpret_cast<NTSTATUS(NTAPI*)(UINT, LPINPUT, int)>(NtUserSendInput_Spoof)(cInputs, pInputs, cbSize); // calling spoofed function
		ZeroMemory(NtUserSendInput_Spoof, 0x1000); // clean address
		VirtualFree(NtUserSendInput_Spoof, 0, MEM_RELEASE); // free it

	}
	else
	{
		Result = reinterpret_cast<NTSTATUS(NTAPI*)(UINT, LPINPUT, int)>(SendInput)(cInputs, pInputs, cbSize); // calling spoofed function
	}

	return (Result > 0); // return the status
}
// default screen size
#define SCREENWIDTH ::GetSystemMetrics(SM_CXSCREEN)
#define SCREENHEIGHT ::GetSystemMetrics(SM_CYSCREEN)

#define RandomInt(min, max) (rand() % (max - min + 1) + min) // inclusive random int (e.g 0 to 100)
const double XSCALEFACTOR = 65535.0 / (GetSystemMetrics(SM_CXSCREEN) - 1);
const double YSCALEFACTOR = 65535.0 / (GetSystemMetrics(SM_CYSCREEN) - 1);
float MouseSpeed = 1.0; //Speed range: 0.1 -> 1.0
int deviation = RandomInt(240, 260); //amount of arc path deviation  (E.g. 250pixels  will deviate the path in an arc randomly maxing at (-250 to 250)
//calculate x y coordinates for SendInput mouse movement
#define SENDINPUTX(x) (x * 65536 / (SCREENWIDTH)+1)
#define SENDINPUTY(y) (y * 65536 / (SCREENHEIGHT)+1)

bool MouseClick(bool leftClick, float x, float y)
{
	if (!in_foreground(hWndTar) || !global::mousereset)
		return false;

	global::mousereset = false;
	POINT oldPos;
	GetCursorPos(&oldPos);

	INPUT input = { 0 };
	input.type = INPUT_MOUSE;
	input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
	input.mi.dx = int(s_left + x) * XSCALEFACTOR;
	input.mi.dy = int(s_top + y) * YSCALEFACTOR;
	NtUserSendInput(1, &input, sizeof(INPUT));

	input.mi.dwFlags = (leftClick ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_RIGHTDOWN);
	NtUserSendInput(1, &input, sizeof(INPUT));


	input.mi.dwFlags = (leftClick ? MOUSEEVENTF_LEFTUP : MOUSEEVENTF_RIGHTUP);
	NtUserSendInput(1, &input, sizeof(INPUT));

	std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(8)));
	input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
	input.mi.dx = oldPos.x * XSCALEFACTOR;
	input.mi.dy = oldPos.y * YSCALEFACTOR;
	NtUserSendInput(1, &input, sizeof(INPUT));
	NtUserSendInput(1, &input, sizeof(INPUT));
	global::mousereset = true;
	return true;
}

bool MouseMoveSLD(int x, int y)
{
	POINT curMouse;
	float stepX, stepY, interimX, interimY, progress;
	bool getMouse = GetCursorPos(&curMouse);
	if (!getMouse)
		return false;

	//change below to alter the speed of the movement
	int stepSize = 240;/*RandomInt(70, 240) * 2*/; //rand() % 170 + 70; //generate random number between 70 and 240

	stepX = (x - curMouse.x) / static_cast<float>(stepSize);
	stepY = (y - curMouse.y) / static_cast<float>(stepSize);

	INPUT Input[240];
	ZeroMemory(&Input, sizeof(Input));
	//::ZeroMemory(&Input, sizeof(INPUT));
	

	for (int i = 1; i <= stepSize; i++)
	{
		progress = i / stepSize;
		interimX = (curMouse.x + (i * stepX));
		interimY = (curMouse.y + (i * stepY));

		Input[i].type = INPUT_MOUSE;
		Input[i].mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
		Input[i].mi.dx = SENDINPUTX(round(interimX));
		Input[i].mi.dy = SENDINPUTY(round(interimY));

		//SetCursorPos(round(interimX), round(interimY));
		//Sleep(1);
	}
	::NtUserSendInput(240, Input, sizeof(INPUT));
	//LOG("Moved mouse to:", x, y, "with speed of", stepSize);

	//SetCursorPos(x, y);
	return true;
}

bool MouseMovePath(int x, int y)
{
	POINT curMouse;
	float stepX, stepY, interimX, interimY, progress;
	bool getMouse = GetCursorPos(&curMouse);
	if (!getMouse)
		return false;
	int deviatePathY = RandomInt(deviation * (-1), deviation); //rand() % (deviation*2) - deviation; //deviate -250 to 250 (max 250 pixels from path) or specified deviation
	int deviatePathx = RandomInt(deviation * (-1), deviation); //deviate -250 to 250 (max 250 pixels from path) or specified deviation

	int stepSize = RandomInt(70, 220);
	float speed = MouseSpeed * stepSize;
	stepSize = static_cast<int>(speed) * 2;

	stepX = (x - curMouse.x) / static_cast<float>(stepSize);
	stepY = (y - curMouse.y) / static_cast<float>(stepSize);

	INPUT Input = { 0 };
	::ZeroMemory(&Input, sizeof(INPUT));
	Input.type = INPUT_MOUSE;
	Input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;

	for (int i = 1; i <= stepSize; i++)
	{
		progress = (i / (float)(stepSize)) * M_PI;
		interimX = (curMouse.x + (i * stepX)) + (deviatePathx * sin(progress));
		interimY = (curMouse.y + (i * stepY)) + (deviatePathY * sin(progress));
		//printf("itterim: %.0f, %.0f\n", round(interimX), round(interimY));

		Input.mi.dx = SENDINPUTX(round(interimX));
		Input.mi.dy = SENDINPUTY(round(interimY));
		::NtUserSendInput(1, &Input, sizeof(INPUT));

		//SetCursorPos(round(interimX), round(interimY));
		//Sleep(1);
	}
	//LOG("Moved mouse to:", x, y, "with speed of", stepSize);

	//SetCursorPos(x, y);
	return true;
}

bool MoveMouse(float x, float y)
{
	if (!in_foreground(hWndTar))
		return false;

	INPUT input = { 0 };
	input.type = INPUT_MOUSE;
	input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
	input.mi.dx = int(s_left + x) * XSCALEFACTOR;
	input.mi.dy = int(s_top + y) * YSCALEFACTOR;

	// Sometimes this fails idk why the fuck but calling the function two times seems to solve it
	NtUserSendInput(1, &input, sizeof(INPUT));
	NtUserSendInput(1, &input, sizeof(INPUT));
	return true;// 
}

static void ResetMouse(float x, float y)
{
	if (!in_foreground(hWndTar))
		return;

	//SetCursorPos(int( x), int( y));
	INPUT input = { 0 };
	input.type = INPUT_MOUSE;
	input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
	input.mi.dx = int(x) * XSCALEFACTOR;
	input.mi.dy = int(y) * YSCALEFACTOR;

	// Sometimes this fails idk why the fuck but calling the function two times seems to solve it
	NtUserSendInput(1, &input, sizeof(INPUT));
	NtUserSendInput(1, &input, sizeof(INPUT));

	previousMousePos.x = 0;
	previousMousePos.y = 0;
	global::mousereset = true;
}

bool SendDriverMouse(DWORD Flags, int x, int y) {
	if (!in_foreground(hWndTar))
		return false;

	INPUT Input{ 0 };
	Input.type = INPUT_MOUSE;
	Input.mi.mouseData = 0;
	Input.mi.time = 0;
	Input.mi.dx = x;
	Input.mi.dy = y;
	Input.mi.dwFlags = Flags;

	NtUserSendInput(1, &Input, sizeof(Input));
	NtUserSendInput(1, &Input, sizeof(Input));
	return true;
}

bool IsKeyDown(WORD key)
{
	SHORT keyState = GetKeyState(key);
	bool isToggled = keyState & 1;
	bool isDown = keyState & 0x8000;

	return isDown;
}

UINT PressKeyModShift(WORD key)
{
	if (!in_foreground(hWndTar))
		return 0;

	const UINT scanCode = MapVirtualKey(key, 0);
	INPUT input{};
	input.type = INPUT_KEYBOARD;
	input.ki.wVk = 0;
	input.ki.time = 0;
	input.ki.dwExtraInfo = 0;
	input.ki.dwFlags = KEYEVENTF_SCANCODE;

	input.ki.wScan = MapVirtualKey(VK_SHIFT, 0);
	(void)NtUserSendInput(1, &input, sizeof(input));

	input.ki.wScan = scanCode;
	(void)NtUserSendInput(1, &input, sizeof(input));

	std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(8)));
	input.ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;

	input.ki.wScan = scanCode;
	(void)NtUserSendInput(1, &input, sizeof(input));

	input.ki.wScan = MapVirtualKey(VK_SHIFT, 0);
	UINT ret = NtUserSendInput(1, &input, sizeof(input));
	return ret;
}

UINT KeyPress(WORD key) {
	//const UINT scanCode = MapVirtualKey(key, 0);
	//INPUT input{};
	//input.type = INPUT_KEYBOARD;
	//input.ki.wVk = 0;
	//input.ki.time = 0;
	//input.ki.dwExtraInfo = 0;
	//input.ki.dwFlags = KEYEVENTF_SCANCODE;

	//input.ki.wScan = MapVirtualKey(VK_SHIFT, 0);
	//(void)NtUserSendInput(1, &input, sizeof(input));

	//input.ki.wScan = scanCode;
	//(void)NtUserSendInput(1, &input, sizeof(input));

	//std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(8)));
	//input.ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;

	//input.ki.wScan = scanCode;
	//(void)NtUserSendInput(1, &input, sizeof(input));

	//input.ki.wScan = MapVirtualKey(VK_SHIFT, 0);
	//UINT ret = NtUserSendInput(1, &input, sizeof(input));
	//return ret;
	if (!in_foreground(hWndTar))
		return 0;

	const UINT scanCode = MapVirtualKey(key, 0);
	INPUT input;
	input.type = INPUT_KEYBOARD;
	input.ki.wScan = scanCode;
	input.ki.time = 0;
	input.ki.dwExtraInfo = 0;
	input.ki.wVk = 0;
	input.ki.dwFlags = KEYEVENTF_SCANCODE;
	NtUserSendInput(1, &input, sizeof(INPUT));

	std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(8)));
	input.ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;
	UINT ret = NtUserSendInput(1, &input, sizeof(INPUT));
	return ret;
}

UINT KeyDown(WORD vkk)
{
	if (!in_foreground(hWndTar))
		return 0;

	const UINT scanCode = MapVirtualKey(vkk, 0);

	INPUT input = { 0 };
	input.type = INPUT_KEYBOARD;
	input.ki.wScan = scanCode;
	input.ki.time = 0;
	input.ki.dwExtraInfo = 0;
	input.ki.wVk = 0;
	input.ki.dwFlags = KEYEVENTF_SCANCODE;

	UINT ret = NtUserSendInput(1, &input, sizeof(input));
	return ret;
}

UINT KeyUp(WORD vkk)
{
	if (!in_foreground(hWndTar))
		return 0;

	const UINT scanCode = MapVirtualKey(vkk, 0);

	INPUT input = { 0 };
	input.type = INPUT_KEYBOARD;
	input.ki.wScan = scanCode;
	input.ki.time = 0;
	input.ki.dwExtraInfo = 0;
	input.ki.wVk = 0;
	input.ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;

	UINT ret = NtUserSendInput(1, &input, sizeof(input));
	return ret;
}


KeyBind* Qspell;
KeyBind* Wspell;
KeyBind* Espell;
KeyBind* Rspell;
KeyBind* Dspell;
KeyBind* Fspell;
KeyBind* ItemSlot1;
KeyBind* ItemSlot2;
KeyBind* ItemSlot3;
KeyBind* ItemSlot4;
KeyBind* ItemSlot5;
KeyBind* ItemSlot6;
KeyBind* ItemSlot7;
KeyBind* ChampionOnly;

WORD CheckKey(int SlotID)
{
	switch (SlotID)
	{
	case 0:
		return Qspell->Key;
	case 1:
		return Wspell->Key;
	case 2:
		return Espell->Key;
	case 3:
		return Rspell->Key;
	case 4:
		return Dspell->Key;
	case 5:
		return Fspell->Key;
	case 6:
		return ItemSlot1->Key;
	case 7:
		return ItemSlot2->Key;
	case 8:
		return ItemSlot3->Key;
	case 9:
		return ItemSlot4->Key;
	case 10:
		return ItemSlot5->Key;
	case 11:
		return ItemSlot6->Key;
	case 12:
		return ItemSlot7->Key;
	default:
		return SlotID;
	}
}

 bool Click()
{
	if (!in_foreground(hWndTar) || !global::mousereset)
		return false;

	SendDriverMouse(MOUSEEVENTF_RIGHTDOWN, NULL, NULL);
	std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(8)));
	SendDriverMouse(MOUSEEVENTF_RIGHTUP, NULL, NULL);
	return true;
}

 void ForceClick()
{
	if (!in_foreground(hWndTar))
		return;

	SendDriverMouse(MOUSEEVENTF_RIGHTDOWN, NULL, NULL);
	std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<long long>(8)));
	SendDriverMouse(MOUSEEVENTF_RIGHTUP, NULL, NULL);
}

void TryRightClick(int isAttack, bool isAttackCommand, float x, float y)
{
	/*POINT oldPos;
	GetCursorPos(&oldPos);

	MouseMoveSLD(s_left + x, s_top + y);
	Click();
	ResetMouse(oldPos.x, oldPos.y);*/

	MouseClick(false, x, y);
	/*DataStream stream(13);
	stream.push<int>(isAttack);
	stream.push<bool>(isAttackCommand);
	stream.push<float>(x);
	stream.push<float>(y);
	global::server.clients[0]->packet(Cmd_tryrightclick, stream.size, stream.buffer).send();*/

}