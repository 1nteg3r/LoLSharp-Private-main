#pragma once
std::vector<ULONG_PTR>LogicComponents;

class ModuleManager
{
private:

public:

	ModuleManager() {};
	~ModuleManager() {};

	virtual void Init() = 0;
	virtual void Draw() = 0;
	virtual void Tick() = 0;

	void Add()
	{
		LogicComponents.push_back(reinterpret_cast<ULONG_PTR>(this));
	}

	static void ComponentEvents_onInit()
	{
		for (ULONG_PTR pPtr : LogicComponents)
		{
			ModuleManager* component = reinterpret_cast<ModuleManager*>(pPtr);
			component->Init();
		}
	}

	static void ComponentsEvent_onDraw()
	{
		for (ULONG_PTR pPtr : LogicComponents)
		{
			ModuleManager* component = reinterpret_cast<ModuleManager*>(pPtr);
			component->Draw();
		}
	}

	static void ComponentsEvent_onTick()
	{
		for (ULONG_PTR pPtr : LogicComponents)
		{
			ModuleManager* component = reinterpret_cast<ModuleManager*>(pPtr);
			component->Tick();
		}
	}
};
