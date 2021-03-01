#ifndef TG_UTILITY_H
#define TG_UTILITY_H

#include <Godot.hpp>
#include <vector>

template <typename T>
T max(T a, T b) {
	return a > b ? a : b;
}

template <typename T>
inline godot::PoolRealArray to_pool_real_array_reinterpret(const std::vector<T> &src) {
	godot::PoolRealArray dst;
	dst.resize(static_cast<int>((src.size() * sizeof(T)) / sizeof(float)));
	{
		godot::PoolRealArray::Write w = dst.write();
		memcpy(w.ptr(), src.data(), src.size() * sizeof(T));
	}
	return dst;
}

inline godot::PoolVector3Array to_pool_array(const std::vector<godot::Vector3> &src) {
	godot::PoolVector3Array dst;
	dst.resize(static_cast<int>(src.size()));
	{
		godot::PoolVector3Array::Write w = dst.write();
		memcpy(w.ptr(), src.data(), src.size() * sizeof(godot::Vector3));
	}
	return dst;
}

inline godot::PoolVector2Array to_pool_array(const std::vector<godot::Vector2> &src) {
	godot::PoolVector2Array dst;
	dst.resize(static_cast<int>(src.size()));
	{
		godot::PoolVector2Array::Write w = dst.write();
		memcpy(w.ptr(), src.data(), src.size() * sizeof(godot::Vector2));
	}
	return dst;
}

inline godot::PoolIntArray to_pool_array(const std::vector<int> &src) {
	godot::PoolIntArray dst;
	dst.resize(static_cast<int>(src.size()));
	{
		godot::PoolIntArray::Write w = dst.write();
		memcpy(w.ptr(), src.data(), src.size() * sizeof(int));
	}
	return dst;
}

template <typename T>
void raw_append_to(std::vector<T> &dst, const std::vector<T> &src) {
	const size_t begin_pos = dst.size();
	dst.resize(dst.size() + src.size());
	memcpy(dst.data() + begin_pos, src.data(), src.size() * sizeof(T));
}

#endif // TG_UTILITY_H
