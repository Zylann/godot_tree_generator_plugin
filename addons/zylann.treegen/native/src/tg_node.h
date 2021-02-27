#ifndef TG_NODE_H
#define TG_NODE_H

#include "macros.h"

#include <Godot.hpp>
#include <gen/Curve.hpp>
#include <gen/Mesh.hpp>
#include <gen/Reference.hpp>
#include <vector>

class TG_SpawnParams : public godot::Reference {
	GODOT_CLASS(TG_SpawnParams, godot::Reference)
public:
	// Base amount to spawn
	int along_base_amount = 10;
	// How many to add per space unit
	float along_amount_per_unit = 0.f;
	// From where to start spawning along the parent
	float along_begin_ratio = 0.f;
	// From where to stop spawning along the parent
	float along_end_ratio = 1.f;
	// Spawn randomness along parent
	float along_jitter = 0.f;
	// Skip chance
	float skip_probability = 0.f;

	// At how many angles to spawn around the parent
	int around_amount = 3;
	// Randomness of the angle at which to spawn around the parent
	float around_jitter = 0.75f;
	// Angular offset from which the spawn angles are chosen
	float around_offset = 0.f;

	// Vertical angle at which to orientate relative to the parent
	float vertical_angle = static_cast<float>(Math_PI) / 3.f;
	// Randomness added to the angle
	float vertical_angle_jitter = 0.f;

	void _init() {}

	static void _register_methods() {
		godot::register_property("along_base_amount", &TG_SpawnParams::along_base_amount, 10);
		godot::register_property("along_amount_per_unit", &TG_SpawnParams::along_amount_per_unit, 0.f);
		godot::register_property("along_begin_ratio", &TG_SpawnParams::along_begin_ratio, 0.f);
		godot::register_property("along_end_ratio", &TG_SpawnParams::along_end_ratio, 1.f);
		godot::register_property("along_jitter", &TG_SpawnParams::along_jitter, 0.f);
		godot::register_property("skip_probability", &TG_SpawnParams::skip_probability, 0.f);

		godot::register_property("around_amount", &TG_SpawnParams::around_amount, 3);
		godot::register_property("around_jitter", &TG_SpawnParams::around_jitter, 0.75f);
		godot::register_property("around_offset", &TG_SpawnParams::around_offset, 0.f);

		godot::register_property("vertical_angle", &TG_SpawnParams::vertical_angle, static_cast<float>(Math_PI) / 3.f);
		godot::register_property("vertical_angle_jitter", &TG_SpawnParams::vertical_angle_jitter, 0.f);
	}
};

class TG_PathParams : public godot::Reference {
	GODOT_CLASS(TG_PathParams, godot::Reference)
public:
	// Base length of the branch in space units
	float length = 15.f;
	// Modulates the length depending on where the branch spawns on the parent.
	godot::Ref<godot::Curve> length_curve_along_parent;
	float length_randomness = 0.f;

	// Radius at the beginning at the branch
	float begin_radius = 1.f;
	// Radius at the end of the branch
	float end_radius = 0.3f;
	// How radius progresses between its begin and end value.
	// This is calculated as `pow(offset / length, radius_curve)`
	float radius_curve = 1.f;
	// Modulates the radii depending on where the branch spawns on the parent
	godot::Ref<godot::Curve> radius_curve_along_parent;

	// Distort the path. Acts as modifier.
	float noise_period = 16.f;
	int noise_octaves = 3;
	float noise_amplitude = 0.f;
	// Modulates noise amplitude along path.
	// This is calculated as `pow(offset / length, noise_curve)`
	float noise_curve = 1.f;

	// User-defined curve for the branch.
	// If set, will serve as a base for positional data.
	// Modifiers will still apply on top of it.
	//var authored_curve : Curve

	bool end_cap_flat = true;

	// Modifier to the grow angle to make the branch tend upward.
	// Negative values makes branches tend downward.
	float seek_sun = 0.f;

	void _init() {}

	static void _register_methods() {
		godot::register_property("length", &TG_PathParams::length, 15.f);

		// TODO The class name could be automatically determined, but it's not!
		// It uses the default value, because get_class() is an instance method, but the default value is null...
		godot::register_property("length_curve_along_parent", &TG_PathParams::length_curve_along_parent,
				godot::Ref<godot::Curve>(), GODOT_METHOD_RPC_MODE_DISABLED, GODOT_PROPERTY_USAGE_DEFAULT,
				GODOT_PROPERTY_HINT_RESOURCE_TYPE, "Curve");

		godot::register_property("length_randomness", &TG_PathParams::length_randomness, 0.f);
		godot::register_property("begin_radius", &TG_PathParams::begin_radius, 1.f);
		godot::register_property("end_radius", &TG_PathParams::end_radius, 0.3f);
		godot::register_property("radius_curve", &TG_PathParams::radius_curve, 1.f);

		godot::register_property("radius_curve_along_parent", &TG_PathParams::radius_curve_along_parent,
				godot::Ref<godot::Curve>(), GODOT_METHOD_RPC_MODE_DISABLED, GODOT_PROPERTY_USAGE_DEFAULT,
				GODOT_PROPERTY_HINT_RESOURCE_TYPE, "Curve");

		godot::register_property("noise_period", &TG_PathParams::noise_period, 16.f);
		godot::register_property("noise_octaves", &TG_PathParams::noise_octaves, 3);
		godot::register_property("noise_amplitude", &TG_PathParams::noise_amplitude, 0.f);
		godot::register_property("noise_curve", &TG_PathParams::noise_curve, 1.f);

		godot::register_property("end_cap_flat", &TG_PathParams::end_cap_flat, true);

		godot::register_property("seek_sun", &TG_PathParams::seek_sun, 0.f);
	}
};

class TG_Node : public godot::Reference {
	GODOT_CLASS(TG_Node, godot::Reference)
public:
	enum Type {
		TYPE_BRANCH = 0,
		TYPE_LEAF = 1
	};

	void _init() {
		_spawn_params.instance();
		_path_params.instance();
	}

	Type get_type() const {
		return _type;
	}

	int get_local_seed() const {
		return _local_seed;
	}

	void set_local_seed(int p_local_seed) {
		_local_seed = p_local_seed;
	}

	int get_child_count() const {
		return static_cast<int>(_children.size());
	}

	void add_child(godot::Ref<TG_Node> node) {
		_children.push_back(node);
	}

	void clear_children() {
		_children.clear();
	}

	// Internal

	const TG_SpawnParams &get_spawn_params() const {
		TG_CRASH_COND(_spawn_params.is_null());
		return **_spawn_params;
	}

	const TG_PathParams &get_path_params() const {
		TG_CRASH_COND(_path_params.is_null());
		return **_path_params;
	}

	const TG_Node &get_child_internal(int i) const {
		const godot::Ref<TG_Node> &ref = _children[i];
		TG_CRASH_COND(ref.is_null());
		return **ref;
	}

	static void _register_methods() {
		godot::register_method("get_spawn_params", &TG_Node::_b_get_spawn_params);
		godot::register_method("get_path_params", &TG_Node::_b_get_path_params);

		godot::register_method("get_local_seed", &TG_Node::get_local_seed);
		godot::register_method("set_local_seed", &TG_Node::set_local_seed);

		godot::register_method("get_child_count", &TG_Node::get_child_count);
		godot::register_method("get_child", &TG_Node::_b_get_child);
		godot::register_method("add_child", &TG_Node::add_child);
		godot::register_method("clear_children", &TG_Node::clear_children);
	}

private:
	godot::Ref<TG_SpawnParams> _b_get_spawn_params() {
		return _spawn_params;
	}

	godot::Ref<TG_PathParams> _b_get_path_params() {
		return _path_params;
	}

	godot::Ref<TG_Node> _b_get_child(int i) {
		ERR_FAIL_INDEX_V(i, _children.size(), godot::Ref<TG_Node>());
		return _children[i];
	}

	godot::Ref<TG_SpawnParams> _spawn_params;
	godot::Ref<TG_PathParams> _path_params;
	int _local_seed = 0;
	Type _type = TYPE_BRANCH;
	// Mesh to spawn in leaf mode
	godot::Ref<godot::Mesh> _mesh;
	std::vector<godot::Ref<TG_Node> > _children;
};

#endif // TG_NODE_H
