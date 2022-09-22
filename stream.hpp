#pragma-once
#include <Windows.h>

class DataStream {
private:
	bool isAllocated = false;

public:
	LPVOID buffer = 0;
	int size = 0;
	int cursor = 0;

	DataStream(LPVOID _buffer, int _size) {
		buffer = _buffer;
		size = _size;
		cursor = 0;
	}

	DataStream(int _size) {
		buffer = new char[_size];
		isAllocated = true;
		size = _size;
		cursor = 0;
	}

	DataStream() {
	}

	~DataStream() {
		//if (isAllocated) {
		//	delete[] buffer;
		//	isAllocated = false;
		//}
	}

	template<typename T>
	T pop() {
		int readCursor = cursor;
		cursor += sizeof(T);
		return *(T*)((DWORD_PTR)buffer + readCursor);
	}

	LPVOID pop(size_t _size) {
		if (_size == 0)
			_size = size - cursor;

		LPVOID result = new char[_size];
		memcpy(result, (LPVOID)((DWORD_PTR)buffer + cursor), _size);
		cursor += _size;
		return result;
	}

	template<typename T>
	void push(T value) {
		*(T*)((DWORD_PTR)buffer + cursor) = value;
		cursor += sizeof(T);
	}

	void push(LPVOID src, size_t size) {
		memcpy((LPVOID)((DWORD_PTR)buffer + cursor), src, size);
		cursor += size;
	}

	void operator delete(void* ptr) {
		auto _this = (DataStream*)ptr;
		if (_this->isAllocated) {
			delete[] _this->buffer;
			_this->isAllocated = false;
		}
	}
};