#ifndef TG_NODE_INSTANCE_H
#define TG_NODE_INSTANCE_H

#include <Godot.hpp>
#include <core/Array.hpp>
#include <gen/Reference.hpp>
#include <vector>

// Godot expects 4 floats per tangent. This struct should match the same layout.
struct TG_Tangents {
	godot::Vector3 tangent;
	float binormal_sign;
};

struct TG_SurfaceData {
	std::vector<godot::Vector3> positions;
	std::vector<godot::Vector3> normals;
	std::vector<godot::Vector2> uvs;
	std::vector<TG_Tangents> tangents;
	std::vector<int> indices;
};

class TG_NodeInstance : public godot::Reference {
	GODOT_CLASS(TG_NodeInstance, godot::Reference)
public:
	void _init() {}

	int get_child_count() const {
		return static_cast<int>(children.size());
	}

	godot::Ref<TG_NodeInstance> get_child(int i) {
		ERR_FAIL_INDEX_V(i, children.size(), godot::Ref<TG_NodeInstance>());
		return children[i];
	}

	int get_path_size() const {
		return static_cast<int>(path.size());
	}

	godot::Transform get_path_transform(int i) const {
		ERR_FAIL_INDEX_V(i, path.size(), godot::Transform());
		return path[i];
	}

	// Internal

	static void _register_methods() {
		godot::register_method("get_child_count", &TG_NodeInstance::get_child_count);
		godot::register_method("get_child", &TG_NodeInstance::get_child);
		godot::register_method("get_path_size", &TG_NodeInstance::get_path_size);
		godot::register_method("get_path_transform", &TG_NodeInstance::get_path_transform);

		godot::register_property("local_transform", &TG_NodeInstance::local_transform, godot::Transform());
	}

	godot::Transform local_transform;
	std::vector<TG_SurfaceData> surfaces;

	// Where is the node instance along its parent, as a 0 to 1 ratio
	float offset_ratio = 0.f;

	std::vector<godot::Transform> path;
	std::vector<float> path_distances;
	std::vector<float> path_radii;

	std::vector<godot::Ref<TG_NodeInstance> > children;
};

#endif // TG_NODE_INSTANCE_H
