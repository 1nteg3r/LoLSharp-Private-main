#pragma once

class Fiora : public ModuleManager {
private:


public:
	float fioraQmaxRange = 750;
	float qDashRange = 350;
	float qHitAOErange = 400;

	PredictionInput Q = PredictionInput({ 625 });
	PredictionInput W = PredictionInput({ });
	PredictionInput E = PredictionInput({ 1000 });
	PredictionInput R = PredictionInput({  });

	bool canReset = true;

	struct vitalAngledFiora_struct
	{
		Vector3 pos;
		float time;
	};

	Fiora()
	{

	}

	~Fiora()
	{

	}

	void Draw()
	{


	}
	void Init()
	{
		auto menu = NewMenu::CreateMenu("Fiora", "Fiora");
	}

	Vector3 QHarassPos(CObject* slot0)
	{

	}
	float QSpeed()
	{
		return std::min((me->MoveSpeed() - 345) * 3.5 + 1100, 1600.0);
	}

	vitalAngledFiora_struct vitalAngledFiora(CObject* slot0, bool slot1, bool slot2, CObject *slot3, Vector3 slot4,float slot5)
	{
		auto slot6 = me;

		PredictionInput local = PredictionInput({ 1200 });
		auto slot7 = prediction->GetPrediction(me, local).UnitPosition();

		if (slot1)
		{
			PredictionInput Q = PredictionInput({ 420, 0.f, 10.f,QSpeed(), false, SkillshotType::SkillshotLine });
			slot7 = prediction->GetPrediction(slot0, Q).UnitPosition();
		}

		if (slot4.IsValid()) {
			slot7 = slot4;
		}
	}

	void Combo()
	{



	}

	void LaneClear()
	{



	}
	void LastHit()
	{

	}
	void Harass()
	{


	}
	void Tick()
	{

		if (global::mode == ScriptMode::Combo)
		{
			Combo();
		}
		else if (global::mode == ScriptMode::LaneClear)
		{
			LaneClear();
		}
		else if (global::mode == ScriptMode::Mixed)
		{
			Harass();
		}
		else if (global::mode == ScriptMode::LastHit)
		{
			LastHit();
		}
	}
};