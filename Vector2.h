#pragma once

class Vector3;



class Vector2 {
public:
	static Vector2 Zero;


	float x, y;

	Vector2();
	Vector2(float x, float y);


	bool IsValid();
	bool IsWorldValid();
	float Length();
	float LengthSquared();
	void Normalize();
	Vector2 Normalized();
	void Extend(Vector2 v, float distance);
	Vector2 Extended(Vector2 v, float distance);
	void Shorten(Vector2 v, float distance);
	Vector2 Shortened(Vector2 v, float distance);
	void Rotate(float angle);
	Vector2 Rotated(float angle);
	float Distance(Vector2 v);
	float DistanceSquared(Vector2 v);
	float Dot(Vector2 v);
	float Cross(Vector2 v);
	float AngleBetween(Vector2 v);
	Vector2 Perpendicular();
	Vector2 Perpendicular2();
	bool IsInRange(Vector2 v, float range);

	bool operator==(Vector2 v);
	bool operator!=(Vector2 v);
};

Vector2 operator+(Vector2 left, Vector2 right);
Vector2 operator+(Vector2 v, float scalar);
Vector2 operator+(float scalar, Vector2 v);
Vector2 operator-(Vector2 v);
Vector2 operator-(Vector2 left, Vector2 right);
Vector2 operator-(Vector2 v, float scalar);
Vector2 operator-(float scalar, Vector2 v);
Vector2 operator*(Vector2 left, Vector2 right);
Vector2 operator*(Vector2 v, float scale);
Vector2 operator*(float scale, Vector2 v);
Vector2 operator/(Vector2 v, Vector2 scale);
Vector2 operator/(Vector2 v, float scale);
Vector2 operator/(float scale, Vector2 v);