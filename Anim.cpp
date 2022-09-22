#include "Anim.h"
#define M_PI	3.14159265358979323846264338327950288419716939937510

float perc_from_time(clock_t from, float duration, clock_t now = clock()) {

	float time_passed = (now - from);
	return time_passed / duration;
}


Anim::Anim() {

	value = 0.f;
	duration = 0.f;
	start = 0.f;
	dest = 0.f;
	anim_diff = 0.f;
	pause_afteranim_duration = 0.f;

	time_started = 0;
	reverse_from = 0;
	last_finish = 0;
	reversing = false;
	gonna_loop = false;
	gonna_reverse = false;
	allow_user_reverse = false;
	reset_after_loop = false;
}
void Anim::setresetvalue_afterloop(bool reset) {
	reset_after_loop = reset;
}

// if any animations running
bool Anim::isintask() {
	return (time_started != 0);
}

// should use for internal only
void Anim::begin_animation(float (*fx_func)(float start, float end, float perc),
	float destination, float anim_duration, bool loop, bool reverse, float delay) {

	if (isintask()) {
		if (gonna_loop) {
			stop_loop(false);
		}

		BEGIN_ANIM_PARAM param;
		param.fx_func = fx_func;
		param.destination = destination;
		param.anim_duration = anim_duration;
		param.loop = loop;
		param.reverse = reverse;
		param.delay = delay;

		waiting_list.push_back(param);
		return;

	}
	
	duration = anim_duration;
	start = value;
	dest = value + destination;
	calfx = fx_func;
	time_started = clock();

	if ((time_started - last_finish) < pause_afteranim_duration) {
		time_started += pause_afteranim_duration - (time_started - last_finish);
	}
	time_started += delay;

	gonna_loop = loop;
	gonna_reverse = reverse;
}

// should use for internal only
void Anim::end_animation() {
	
	value = (reversing ? start : dest);
	float old_duration = duration;
	duration = 0.f;
	time_started = 0;
	reverse_from = 0;
	anim_diff = 0.f;
	reversing = false;

	last_finish = clock();

	if (gonna_reverse) {

		if (!gonna_loop) gonna_reverse = false;
		begin_animation(calfx, start-dest, old_duration, gonna_loop, gonna_reverse, 0);
	}
	else if (gonna_loop) {
		if (reset_after_loop) {
			value = start;
			begin_animation(calfx, dest, old_duration, gonna_loop, gonna_reverse, 0);
		}else
			begin_animation(calfx, dest-start, old_duration, gonna_loop, gonna_reverse, 0);
	}
	else if (waiting_list.size() > 0){

		BEGIN_ANIM_PARAM param = waiting_list[0];
		begin_animation(param.fx_func, param.destination, param.anim_duration, param.loop, param.reverse, param.delay);
		waiting_list.erase(waiting_list.begin());
	}
}

// pause for a while after each animation
void Anim::setpause_afteranim(float pause_time) {
	pause_afteranim_duration = pause_time;
}

// stop looping the current animation
void Anim::stop_loop(bool wait_reverse) {
	gonna_loop = false;
	if (!wait_reverse) gonna_reverse = false;
}

// reverse the current animation
void Anim::reverse() {

	if (!isintask()) return;
	//if (!allow_user_reverse) return;
	if (reversing) {

		float perc = perc_from_time(time_started, duration) + anim_diff;
		float reverse_perc = perc_from_time(reverse_from, duration, time_started);
		perc = reverse_perc - perc;
		float time_diff = perc * duration;
		time_started = clock() - time_diff;

	}
	else {

		reverse_from = time_started;
		time_started = clock();
	}
	reversing = !reversing;
}

// get the value
float Anim::get() {

	if (!isintask()) return value;
	//printf("fuck");
	
	float perc = perc_from_time(time_started, duration) + anim_diff;
	
	if (perc < 0) return start;

	if ((perc < 1) && (reversing)) {

		float reverse_perc = perc_from_time(reverse_from, duration, time_started);
		perc = reverse_perc - perc;
	}

	if ((perc >= 1) || (perc < 0)) {
		end_animation();
	}
	else {
		value = calfx(start, dest, perc);
	}

	return value;
}

float fx_linear(float start, float end, float perc) {
	return start + (end - start) * perc;

}

float fx_bouce_back(float start, float end, float perc) {
	perc = -2.9166666666666665 * pow(perc, 2) + 2.9166666666666665 * perc;
	return start + (end - start) * perc;
}

float fx_smooth(float start, float end, float perc) {
	perc = -1.0817307692307694 * pow(perc, 2) + 2.0817307692307696 * perc;
	return start + (end - start) * perc;
}

float fx_accelerate(float start, float end, float perc) {
	perc = 0.8333333333333331 * pow(perc, 2) + 0.16666666666666682 * perc;
	return start + (end - start) * perc;
}

float fx_sinking(float start, float end, float perc) {
	
	static float step1 = 0.4;
	static float step2 = 0.6;

	if (perc <= 0.5) {
		perc *= 2;
		perc = -1.0817307692307694 * pow(perc, 2) + 2.0817307692307696 * perc;
		perc /= 2;
	}
	else {
		//perc = (perc-0.5)*2;
		perc = 1 - (perc-0.5)*2;
		perc = -1.0817307692307694 * pow(perc, 2) + 2.0817307692307696 * perc;
		perc = (1-perc)/2 + 0.5;
	}

	return start + (end - start) * perc;
}

// linear movement
void Anim::linear(float destination, float anim_duration, bool loop, bool reverse, float delay) {

	begin_animation(fx_linear, destination, anim_duration, loop, reverse, delay);
}

// bounce_back movement
void Anim::bounce_back(float destination, float anim_duration, bool loop, bool reverse, float delay) {

	begin_animation(fx_bouce_back, destination, anim_duration, loop, reverse, delay);
}

// smooth movement
void Anim::smooth(float destination, float anim_duration, bool loop, bool reverse, float delay) {

	begin_animation(fx_smooth, destination, anim_duration, loop, reverse, delay);
}
// accelerate movement
void Anim::accelerate(float destination, float anim_duration, bool loop, bool reverse, float delay) {

	begin_animation(fx_accelerate, destination, anim_duration, loop, reverse, delay);
}

// sinking movement
void Anim::sinking(float destination, float anim_duration, bool loop, bool reverse, float delay) {

	begin_animation(fx_sinking, destination, anim_duration, loop, reverse, delay);
}





namespace perlin {

	int numX = 128;
	int numY = 128;
	int numOctaves = 7;
	double persistence = 1;

	int primeIndex = 0;

	int primes[10][3] = {
	  { 995615039, 600173719, 701464987 },
	  { 831731269, 162318869, 136250887 },
	  { 174329291, 946737083, 245679977 },
	  { 362489573, 795918041, 350777237 },
	  { 457025711, 880830799, 909678923 },
	  { 787070341, 177340217, 593320781 },
	  { 405493717, 291031019, 391950901 },
	  { 458904767, 676625681, 424452397 },
	  { 531736441, 939683957, 810651871 },
	  { 997169939, 842027887, 423882827 }
	};

	double Noise(int i, int x, int y) {
		int n = x + y * 57;
		n = (n << 13) ^ n;
		int a = primes[i][0], b = primes[i][1], c = primes[i][2];
		int t = (n * (n * n * a + b) + c) & 0x7fffffff;
		return 1.0 - (double)(t) / 1073741824.0;
	}

	double SmoothedNoise(int i, int x, int y) {
		double corners = (Noise(i, x - 1, y - 1) + Noise(i, x + 1, y - 1) +
			Noise(i, x - 1, y + 1) + Noise(i, x + 1, y + 1)) / 16,
			sides = (Noise(i, x - 1, y) + Noise(i, x + 1, y) + Noise(i, x, y - 1) +
				Noise(i, x, y + 1)) / 8,
			center = Noise(i, x, y) / 4;
		return corners + sides + center;
	}

	double Interpolate(double a, double b, double x) {  // cosine interpolation
		double ft = x * 3.1415927,
			f = (1 - cos(ft)) * 0.5;
		return  a * (1 - f) + b * f;
	}

	double InterpolatedNoise(int i, double x, double y) {
		int integer_X = x;
		double fractional_X = x - integer_X;
		int integer_Y = y;
		double fractional_Y = y - integer_Y;

		double v1 = SmoothedNoise(i, integer_X, integer_Y),
			v2 = SmoothedNoise(i, integer_X + 1, integer_Y),
			v3 = SmoothedNoise(i, integer_X, integer_Y + 1),
			v4 = SmoothedNoise(i, integer_X + 1, integer_Y + 1),
			i1 = Interpolate(v1, v2, fractional_X),
			i2 = Interpolate(v3, v4, fractional_X);
		return Interpolate(i1, i2, fractional_Y);
	}

	double ValueNoise_2D(double x, double y) {
		double total = 0,
			frequency = pow(2, numOctaves),
			amplitude = 1;
		for (int i = 0; i < numOctaves; ++i) {
			frequency /= 2;
			amplitude *= persistence;
			total += InterpolatedNoise((primeIndex + i) % 10,
				x / frequency, y / frequency) * amplitude;
		}
		return total / frequency;
	}
}