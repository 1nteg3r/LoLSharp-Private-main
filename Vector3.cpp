#include "stdafx.h"
#include "Vector3.h"
#include "Vector2.h"
#define M_PI	3.14159265358979323846264338327950288419716939937510

	Vector3 Vector3::Zero = Vector3();

	Vector3::Vector3() {
		this->x = 0.0f;
		this->y = 0.0f;
		this->z = 0.0f;
	}

	Vector3::Vector3(float x, float y, float z) {
		this->x = x;
		this->y = y;
		this->z = z;
	}

	bool Vector3::IsValid() {
		return *this != Vector3::Zero && (this->x > -1 * 10 ^ 6) && (this->y > -1 * 10 ^ 6) && (this->z > -1 * 10 ^ 6) && (this->x < 1 * 10 ^ 6) && (this->y < 1 * 10 ^ 6) && (this->z < 1 * 10 ^ 6) || *this != Vector3::Zero;
	}

	/*bool Vector3::IsValid2() {
		return this->x > -1 * 10 ^ 6 && this->y > -1 * 10 ^ 6 && this->z > -1 * 10 ^ 6 && this->x < 1 * 10 ^ 6 && this->y < 1 * 10 ^ 6 && this->z < 1 * 10 ^ 6;
	}*/

	float Vector3::Length() {
		return sqrtf(this->x * this->x + this->z * this->z);
	}

	float Vector3::LengthSquared() {
		return this->x* this->x + this->z * this->z;
	}

	void Vector3::Normalize() {
		auto length = this->Length();
		this->x /= length;
		this->z /= length;
	}

	Vector3 Vector3::Normalized() {
		auto result = Vector3(this->x, this->y, this->z);
		result.Normalize();
		return result;
	}

	void Vector3::Extend(Vector3 v, float distance) {
		auto normalized = (v - *this).Normalized();
		this->x = this->x + distance * normalized.x;
		this->z = this->z + distance * normalized.z;
	}

	Vector3 Vector3::Extended(Vector3 v, float distance) {
		auto result = Vector3(this->x, this->y, this->z);
		result.Extend(v, distance);
		return result;
	}

	void Vector3::Shorten(Vector3 v, float distance) {
		auto normalized = (v - *this).Normalized();
		this->x = this->x - distance * normalized.x;
		this->z = this->z - distance * normalized.z;
	}

	Vector3 Vector3::Shortened(Vector3 v, float distance) {
		auto result = Vector3(this->x, this->y, this->z);
		result.Shorten(v, distance);
		return result;
	}

	void Vector3::Rotate(float angle) {
		auto c = cosf(angle);
		auto s = sinf(angle);

		this->x = this->x * c - this->z * s;
		this->z = this->z * c + this->x * s;
	}

	Vector3 Vector3::Rotated(float angle) {
		auto result = Vector3(this->x, this->y, this->z);
		result.Rotate(angle);
		return result;
	}

	float Vector3::Distance(Vector3 v) {
		float x = this->x - v.x;
		float z = this->z - v.z;
		return sqrtf(x * x + z * z);
	}

	Vector3 Vector3::SetZ(Vector3 v)
	{
		auto result = Vector3(this->x, this->y, this->z);
		result.y = v.y;
		return result;
	}

	float Vector3::DistanceSquared(Vector3 v) {
		auto x = this->x - v.x;
		auto z = this->z - v.z;
		return x * x + z * z;
	}

	float Vector3::Dot(Vector3 v) {
		return this->x * v.x + this->z * v.z;
	}

	float Vector3::Cross(Vector3 v) {
		return this->x * v.z - this->z * v.x;
	}

	float Vector3::AngleBetween(Vector3 v) {
		auto vec = v - *this;
		return atan2f(vec.z, vec.x)* 180.0f* M_PI;
	}

	Vector3 Vector3::Perpendicular() {
		return Vector3(-this->z, this->y, this->x);
	}

	Vector3 Vector3::Perpendicular2() {
		return Vector3(this->z, this->y, -this->x);
	}

	bool Vector3::IsInRange(Vector3 v, float range) {
		return this->DistanceSquared(v) < range * range;
	}

	bool Vector3::operator==(Vector3 v) {
		return this->x == v.x && this->y == v.y && this->z == v.z;
	}

	bool Vector3::operator!=(Vector3 v) {
		return this->x != v.x || this->y != v.y || this->z != v.z;
	}

	Vector3 operator+(Vector3 left, Vector3 right) {
		return Vector3(left.x + right.x, left.y, left.z + right.z);
	}

	Vector3 operator+(Vector3 v, float scalar) {
		return Vector3(v.x + scalar, v.y + scalar, v.z + scalar);
	}

	Vector3 operator+(float scalar, Vector3 v) {
		return Vector3(scalar + v.x, scalar + v.y, scalar + v.z);
	}

	Vector3 operator-(Vector3 v) {
		return Vector3(-v.x, -v.y, -v.z);
	}

	Vector3 operator-(Vector3 left, Vector3 right) {
		return Vector3(left.x - right.x, left.y - right.y, left.z - right.z);
	}

	Vector3 operator-(Vector3 v, float scalar) {
		return Vector3(v.x - scalar, v.y - scalar, v.z - scalar);
	}

	Vector3 operator-(float scalar, Vector3 v) {
		return Vector3(scalar - v.x, scalar - v.y, scalar - v.z);
	}

	Vector3 operator*(Vector3 left, Vector3 right) {
		return Vector3(left.x * right.x, left.y * right.y, left.z * right.z);
	}

	Vector3 operator*(Vector3 v, float scale) {
		return Vector3(v.x * scale, v.y * scale, v.z * scale);
	}

	Vector3 operator*(float scale, Vector3 v) {
		return Vector3(scale * v.x, scale * v.y, scale * v.z);
	}

	Vector3 operator/(Vector3 v, Vector3 scale) {
		return Vector3(v.x / scale.x, v.y / scale.y, v.z / scale.z);
	}

	Vector3 operator/(Vector3 v, float scale) {
		return Vector3(v.x / scale, v.y / scale, v.z / scale);
	}

	Vector3 operator/(float scale, Vector3 v) {
		return Vector3(scale / v.x, scale / v.y, scale / v.z);
	}
