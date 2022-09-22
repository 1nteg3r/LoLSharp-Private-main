#pragma once
class DelayAction
{
public:
	//typedef void(*Callback)();
	typedef std::function<void()> Callback;
	struct Action
	{
		Callback CallbackObject;
		int Time;

		Action(int time, Callback callback)
		{
			Time = time + (float)(GetTickCount() & INT_MAX);
			CallbackObject = callback;
		}
	};

	std::vector<std::shared_ptr<Action>> ActionList;
	DelayAction()
	{
		//ActionList = new std::vector<Action>;
	}

	void Add(float time, Callback func)	// time tinh theo ms
	{
		ActionList.push_back(std::make_shared<Action>(time, func));
	}

	void DelayAction_OnOnUpdate()
	{
		for (int num = ActionList.size() - 1; num >= 0; num--)
		{
			if (ActionList[num]->Time <= (GetTickCount() & INT_MAX))
			{
				try
				{
					if (ActionList[num]->CallbackObject != nullptr)
					{
						ActionList[num]->CallbackObject();
					}
				}
				catch (const std::runtime_error&)
				{
				}
				ActionList.erase(ActionList.begin() + num);
			}
		}
	}
};

extern DelayAction*		_DelayAction;
