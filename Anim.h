#pragma once

#ifndef ANIM_LIB_H
#define ANIM_LIB_H

#include <ctime>
#include <iostream>
#include <vector>
#include <cstdio>
#include <cmath>
#include <cstdlib>
#include <windows.h>
#include <map>

struct BEGIN_ANIM_PARAM {
	float (*fx_func)(float start, float end, float perc);
	float destination;
	float anim_duration;
	bool loop;
	bool reverse;
	float delay;
};

class Anim
{

private:

	float start;
	float dest;
	float duration;
	bool reversing;
	bool allow_user_reverse;
	bool reset_after_loop;
	bool gonna_reverse;
	bool gonna_loop;
	clock_t reverse_from;
	clock_t time_started;
	clock_t last_finish;
	float anim_diff;
	float pause_afteranim_duration;
	float (*calfx)(float start, float end, float perc);


	std::vector<BEGIN_ANIM_PARAM> waiting_list;

public:
	float value;


	Anim();

	float get();

	void begin_animation(float (*fx_func)(float start, float end, float perc),
		float destination, float anim_duration, bool loop, bool reverse, float delay);
	void end_animation();
	void stop_loop(bool wait_reverse = true);

	bool isintask();
	void reverse();
	void setpause_afteranim(float pause_time);
	void setresetvalue_afterloop(bool reset);
	void linear(float destination, float anim_duration, bool loop = false, bool reverse = false, float delay = 0.f);
	void bounce_back(float destination, float anim_duration, bool loop = false, bool reverse = false, float delay = 0.f);
	void smooth(float destination, float anim_duration, bool loop = false, bool reverse = false, float delay = 0.f);
	void accelerate(float destination, float anim_duration, bool loop = false, bool reverse = false, float delay = 0.f);
	void sinking(float destination, float anim_duration, bool loop = false, bool reverse = false, float delay = 0.f);

};



namespace perlin {
	extern int numX;
	extern int numY;
	extern int numOctaves;
	extern double persistence ;

	extern int primeIndex;

	extern int primes[10][3];

	double Noise(int i, int x, int y);
	double SmoothedNoise(int i, int x, int y);
	double Interpolate(double a, double b, double x);
	double InterpolatedNoise(int i, double x, double y);
	double ValueNoise_2D(double x, double y);
}

#endif


