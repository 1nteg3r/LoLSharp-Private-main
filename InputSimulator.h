#pragma once
class InputSimulator : public ModuleManager
{
private:
public:
	std::deque<INPUT>inputsqueue;
	bool empty()
	{
		return inputsqueue.empty();
	}
	POINT ConvertPoint(int x, int y)
	{
		static int screen_x = GetSystemMetrics(SM_CXSCREEN) - 1;
		static int screen_y = GetSystemMetrics(SM_CYSCREEN) - 1;
		return POINT{ (x * 65535) / screen_x,(y * 65535) / screen_y };
	}


	InputSimulator()
	{
	}

	~InputSimulator()
	{
	}

	void Draw()
	{

	}

	void Init()
	{


	}
	
	void OnIssue(GameObjectOrder order, Vector2 tPos)
	{
		//ENGINE_MSG("OnIssue Called  x : %0.f    y : %0.f", tPos.x, tPos.y);
		auto targetPoint = ConvertPoint(s_left + tPos.x, s_top + tPos.y);

		POINT mouse_pos = { int(s_left + tPos.x), int(s_top + tPos.y) };

		INPUT inputs[4];

		GetCursorPos(&mouse_pos);
		auto mouseSex = ConvertPoint(mouse_pos.x, mouse_pos.y);
		if (!Engine::IsOutboundScreen2(tPos))
		{
			inputs[0].type = INPUT_MOUSE;
			inputs[0].mi.dx = targetPoint.x;
			inputs[0].mi.dy = targetPoint.y;
			inputs[0].mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;

			inputs[3].type = INPUT_MOUSE;
			inputs[3].mi.dx = mouseSex.x;
			inputs[3].mi.dy = mouseSex.y;
			inputs[3].mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;
		}

		inputs[1].type = INPUT_MOUSE;
		inputs[1].mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;

		inputs[2].type = INPUT_MOUSE;
		inputs[2].mi.dwFlags = MOUSEEVENTF_RIGHTUP;



		inputsqueue.push_back(inputs[0]);
		inputsqueue.push_back(inputs[1]);
		inputsqueue.push_back(inputs[2]);
		inputsqueue.push_back(inputs[3]);
	}

	void OnCast(UINT key, Vector2 castPos_src, Vector2 castPos_dst)
	{
		auto scrPoint = ConvertPoint(s_left + castPos_src.x, s_top + castPos_src.y);

		auto dstPoint = ConvertPoint(s_left + castPos_dst.x, s_top + castPos_dst.y);

		INPUT inputs[5];

		ZeroMemory(inputs, sizeof(inputs));
		POINT mouse_pos = { 0 };
		GetCursorPos(&mouse_pos);
		auto mouseSex = ConvertPoint(mouse_pos.x, mouse_pos.y);

		if (!Engine::IsOutboundScreen2(castPos_src))
		{
			inputs[0].type = INPUT_MOUSE;
			inputs[0].mi.dx = scrPoint.x;
			inputs[0].mi.dy = scrPoint.y;
			inputs[0].mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;
			inputs[0].mi.time = NULL;

			inputs[4].type = INPUT_MOUSE;
			inputs[4].mi.dx = mouseSex.x;
			inputs[4].mi.dy = mouseSex.y;
			inputs[4].mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;
			inputs[4].mi.time = NULL;
		}

		inputs[1].type = INPUT_KEYBOARD;
		inputs[1].ki.wVk = NULL;
		inputs[1].ki.wScan = key;
		inputs[1].ki.dwFlags = KEYEVENTF_SCANCODE;
		inputs[1].ki.time = NULL;

		inputs[2].type = INPUT_MOUSE;
		inputs[2].mi.dx = dstPoint.x;
		inputs[2].mi.dy = dstPoint.y;
		inputs[2].mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;
		inputs[2].mi.time = NULL;

		inputs[3].type = INPUT_KEYBOARD;
		inputs[3].ki.wVk = NULL;
		inputs[3].ki.wScan = key;
		inputs[3].ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;
		inputs[3].ki.time = NULL;




		inputsqueue.push_back(inputs[0]);
		inputsqueue.push_back(inputs[1]);
		inputsqueue.push_back(inputs[2]);
		inputsqueue.push_back(inputs[3]);
		inputsqueue.push_back(inputs[4]);
	}

	void OnCast(UINT key, Vector2 castPos)
	{
		auto targetPoint = ConvertPoint(s_left + castPos.x, s_top + castPos.y);

		POINT mouse_pos = { int(castPos.x),int(castPos.y) };

		INPUT inputs[4];

		ZeroMemory(inputs, sizeof(inputs));
		GetCursorPos(&mouse_pos);
		auto mouseSex = ConvertPoint(mouse_pos.x, mouse_pos.y);

		if (!Engine::IsOutboundScreen2(castPos))
		{
			inputs[0].type = INPUT_MOUSE;
			inputs[0].mi.dx = targetPoint.x;
			inputs[0].mi.dy = targetPoint.y;
			inputs[0].mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;
			inputs[0].mi.time = NULL;

			inputs[3].type = INPUT_MOUSE;
			inputs[3].mi.dx = mouseSex.x;
			inputs[3].mi.dy = mouseSex.y;
			inputs[3].mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;
			inputs[3].mi.time = NULL;
		}

		inputs[1].type = INPUT_KEYBOARD;
		inputs[1].ki.wVk = NULL;
		inputs[1].ki.wScan = key;
		inputs[1].ki.dwFlags = KEYEVENTF_SCANCODE;
		inputs[1].ki.time = NULL;


		inputs[2].type = INPUT_KEYBOARD;
		inputs[2].ki.wVk = NULL;
		inputs[2].ki.wScan = key;
		inputs[2].ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;
		inputs[2].ki.time = NULL;




		inputsqueue.push_back(inputs[0]);
		inputsqueue.push_back(inputs[1]);
		inputsqueue.push_back(inputs[2]);
		inputsqueue.push_back(inputs[3]);
	}

	void Tick()
	{
		if (!inputsqueue.empty())
		{
			auto input = *inputsqueue.begin();
			NtUserSendInput(1, &input, sizeof(INPUT));
			inputsqueue.pop_front();
		}
	}
};

InputSimulator* inputsimulator = nullptr;