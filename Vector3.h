#pragma once

class Vector2;

class Vector3 {
public:
	static Vector3 Zero;

	float x, y, z;

	Vector3();
	Vector3(float x, float y, float z);

	bool IsValid();
	//bool IsValid2();
	float Length();
	float LengthSquared();
	Vector3 SetZ(Vector3 v);
	void Normalize();
	Vector3 Normalized();
	void Extend(Vector3 v, float distance);
	Vector3 Extended(Vector3 v, float distance);
	void Shorten(Vector3 v, float distance);
	Vector3 Shortened(Vector3 v, float distance);
	void Rotate(float angle);
	Vector3 Rotated(float angle);
	float Distance(Vector3 v);
	float DistanceSquared(Vector3 v);
	float Dot(Vector3 v);
	float Cross(Vector3 v);
	float AngleBetween(Vector3 v);
	Vector3 Perpendicular();
	Vector3 Perpendicular2();
	bool IsInRange(Vector3 v, float range);

	bool operator==(Vector3 v);
	bool operator!=(Vector3 v);
};

Vector3 operator+(Vector3 left, Vector3 right);
Vector3 operator+(Vector3 v, float scalar);
Vector3 operator+(float scalar, Vector3 v);
Vector3 operator-(Vector3 v);
Vector3 operator-(Vector3 left, Vector3 right);
Vector3 operator-(Vector3 v, float scalar);
Vector3 operator-(float scalar, Vector3 v);
Vector3 operator*(Vector3 left, Vector3 right);
Vector3 operator*(Vector3 v, float scale);
Vector3 operator*(float scale, Vector3 v);
Vector3 operator/(Vector3 v, Vector3 scale);
Vector3 operator/(Vector3 v, float scale);
Vector3 operator/(float scale, Vector3 v);


class Vector4
{
public:
	Vector4() : x(0.f), y(0.f), z(0.f), w(0.f)
	{

	}

	Vector4(float _x, float _y, float _z, float _w) : x(_x), y(_y), z(_z), w(_w)
	{

	}
	~Vector4()
	{

	}

	float x;
	float y;
	float z;
	float w;

	Vector4 operator+(Vector4 v)
	{
		return Vector4(x + v.x, y + v.y, z + v.z, w + v.w);
	}
	Vector4 operator/(Vector4 v)
	{
		return Vector4(x / v.x, y / v.y, z / v.z, w / v.w);
	}
	Vector4 operator/(int v)
	{
		return Vector4(x / (float)v, y / (float)v, z / (float)v, w / (float)v);
	}
	Vector4 operator/(float v)
	{
		return Vector4(x / v, y / v, z / v, w / v);
	}
	Vector4 operator*(Vector4 v)
	{
		return Vector4(x * v.x, y * v.y, z * v.z, w * v.w);
	}
	Vector4 operator*(int v)
	{
		return Vector4(x * (float)v, y *(float)v, z * (float)v, w * (float)v);
	}
	Vector4 operator*(float v)
	{
		return Vector4(x * v, y * v, z * v, w * v);
	}
	Vector4 operator-(Vector4 v)
	{
		return Vector4(x - v.x, y - v.y, z - v.z, w - v.w);
	}

	bool operator!=(Vector4 v)
	{
		return (x != v.x && y != v.y && z != v.z && w != v.w);
	}

	Vector4& operator+=(const Vector4& v)
	{
		x += v.x; y += v.y; z += v.z; w += v.w;
		return *this;
	}

	Vector4& operator+=(float v)
	{
		x += v; y += v; z += v; ; w += v;
		return *this;
	}
};