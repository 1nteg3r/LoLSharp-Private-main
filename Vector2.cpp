#include "stdafx.h"
#include "Vector2.h"
#define M_PI	3.14159265358979323846264338327950288419716939937510

Vector2 Vector2::Zero = Vector2();

Vector2::Vector2() {
	this->x = 0.0f;
	this->y = 0.0f;
}

Vector2::Vector2(float x, float y) {
	this->x = x;
	this->y = y;
}

bool Vector2::IsValid() {
	return *this != Vector2::Zero && this->x > -1 * 10 ^ 6 && this->y > -1 * 10 ^ 6 && this->x < 1 * 10 ^ 6 && this->y < 1 * 10 ^ 6;
}

bool Vector2::IsWorldValid() {
	return this->IsValid() && roundf(this->x) > 1800 && roundf(this->x) < 12965 && roundf(this->y) > 80 && roundf(this->y) < 15000;
}

float Vector2::Length() {
	return sqrtf(this->x * this->x + this->y * this->y);
}

float Vector2::LengthSquared() {
	return this->x* this->x + this->y * this->y;
}

void Vector2::Normalize() {
	auto length = this->Length();
	this->x /= length;
	this->y /= length;
}

Vector2 Vector2::Normalized() {
	auto result = Vector2(this->x, this->y);
	result.Normalize();
	return result;
}

void Vector2::Extend(Vector2 v, float distance) {
	auto normalized = (v - *this).Normalized();
	this->x = this->x + distance * normalized.x;
	this->y = this->y + distance * normalized.y;
}

Vector2 Vector2::Extended(Vector2 v, float distance) {
	auto result = Vector2(this->x, this->y);
	result.Extend(v, distance);
	return result;
}

void Vector2::Shorten(Vector2 v, float distance) {
	auto normalized = (v - *this).Normalized();
	auto result = Vector2(this->x, this->y);
	this->x = result.x - distance * normalized.x;
	this->y = result.y - distance * normalized.y;
}

Vector2 Vector2::Shortened(Vector2 v, float distance) {
	auto result = Vector2(this->x, this->y);
	result.Shorten(v, distance);
	return result;
}

void Vector2::Rotate(float angle) {
	float c = cos(angle);
	float s = sin(angle);
	auto result = Vector2(this->x, this->y);

	this->x = result.x * c - result.y * s;
	this->y = result.y * c + result.x * s;
}

Vector2 Vector2::Rotated(float angle) {
	auto result = Vector2(this->x, this->y);
	result.Rotate(angle);
	return result;
}

float Vector2::Distance(Vector2 v) {
	if (!v.IsValid())
		return 0;

	auto x = this->x - v.x;
	auto y = this->y - v.y;
	return sqrtf(x * x + y * y);
}

float Vector2::DistanceSquared(Vector2 v) {
	auto x = this->x - v.x;
	auto y = this->y - v.y;
	return x * x + y * y;
}

float Vector2::Dot(Vector2 v) {
	return this->x* v.x + this->y * v.y;
}

float Vector2::Cross(Vector2 v) {
	return this->x* v.y - this->y * v.x;
}

float Vector2::AngleBetween(Vector2 v) {
	auto vec = v - *this;
	return atan2f(vec.y, vec.x) * 180.0f * M_PI;
}

Vector2 Vector2::Perpendicular() {
	return Vector2(-this->y, this->x);
}

Vector2 Vector2::Perpendicular2() {
	return Vector2(this->y, -this->x);
}

bool Vector2::IsInRange(Vector2 v, float range) {
	return this->DistanceSquared(v) < range* range;
}

bool Vector2::operator==(Vector2 v) {
	return this->x == v.x && this->y == v.y;
}

bool Vector2::operator!=(Vector2 v) {
	return this->x != v.x || this->y != v.y;
}

Vector2 operator+(Vector2 left, Vector2 right) {
	return Vector2(left.x + right.x, left.y + right.y);
}

Vector2 operator+(Vector2 v, float scalar) {
	return Vector2(v.x + scalar, v.y + scalar);
}

Vector2 operator+(float scalar, Vector2 v) {
	return Vector2(scalar + v.x, scalar + v.y);
}

Vector2 operator-(Vector2 v) {
	return Vector2(-v.x, -v.y);
}

Vector2 operator-(Vector2 left, Vector2 right) {
	return Vector2(left.x - right.x, left.y - right.y);
}

Vector2 operator-(Vector2 v, float scalar) {
	return Vector2(v.x - scalar, v.y - scalar);
}

Vector2 operator-(float scalar, Vector2 v) {
	return Vector2(scalar - v.x, scalar - v.y);
}

Vector2 operator*(Vector2 left, Vector2 right) {
	return Vector2(left.x * right.x, left.y * right.y);
}

Vector2 operator*(Vector2 v, float scale) {
	return Vector2(v.x * scale, v.y * scale);
}

Vector2 operator*(float scale, Vector2 v) {
	return Vector2(scale * v.x, scale * v.y);
}

Vector2 operator/(Vector2 v, Vector2 scale) {
	return Vector2(v.x / scale.x, v.y / scale.y);
}

Vector2 operator/(Vector2 v, float scale) {
	return Vector2(v.x / scale, v.y / scale);
}

Vector2 operator/(float scale, Vector2 v) {
	return Vector2(scale / v.x, scale / v.y);
}

