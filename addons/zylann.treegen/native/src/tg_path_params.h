#ifndef TG_PATH_PARAMS_H
#define TG_PATH_PARAMS_H

#include <Godot.hpp>
#include <gen/Curve.hpp>
#include <gen/Reference.hpp>

class TG_PathParams : public godot::Reference {
	GODOT_CLASS(TG_PathParams, godot::Reference)
public:
	// Base length of the branch in space units
	float length = 15.f;
	// Modulates the length depending on where the branch spawns on the parent.
	godot::Ref<godot::Curve> length_curve_along_parent;
	float length_randomness = 0.f;

	// Radius at the beginning at the branch
	float min_radius = 0.3f;
	// Radius at the end of the branch
	float max_radius = 1.0f;
	// How radius progresses between its begin and end value.
	godot::Ref<godot::Curve> radius_curve;
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

	int main_material_index = 0;
	int cap_material_index = 0;
	godot::Vector2 uv_scale;

	TG_PathParams() {
		uv_scale = godot::Vector2(1.f, 1.f);
	}

	void _init() {}

	static void _register_methods() {
		godot::register_property("length", &TG_PathParams::length, 15.f);

		// TODO The class name could be automatically determined, but it's not!
		// It uses the default value, because get_class() is an instance method, but the default value is null...
		godot::register_property("length_curve_along_parent", &TG_PathParams::length_curve_along_parent,
				godot::Ref<godot::Curve>(), GODOT_METHOD_RPC_MODE_DISABLED, GODOT_PROPERTY_USAGE_DEFAULT,
				GODOT_PROPERTY_HINT_RESOURCE_TYPE, "Curve");

		godot::register_property("length_randomness", &TG_PathParams::length_randomness, 0.f);
		godot::register_property("min_radius", &TG_PathParams::min_radius, 0.3f);
		godot::register_property("max_radius", &TG_PathParams::max_radius, 1.0f);

		godot::register_property("radius_curve", &TG_PathParams::radius_curve,
				godot::Ref<godot::Curve>(), GODOT_METHOD_RPC_MODE_DISABLED, GODOT_PROPERTY_USAGE_DEFAULT,
				GODOT_PROPERTY_HINT_RESOURCE_TYPE, "Curve");

		godot::register_property("radius_curve_along_parent", &TG_PathParams::radius_curve_along_parent,
				godot::Ref<godot::Curve>(), GODOT_METHOD_RPC_MODE_DISABLED, GODOT_PROPERTY_USAGE_DEFAULT,
				GODOT_PROPERTY_HINT_RESOURCE_TYPE, "Curve");

		godot::register_property("noise_period", &TG_PathParams::noise_period, 16.f);
		godot::register_property("noise_octaves", &TG_PathParams::noise_octaves, 3);
		godot::register_property("noise_amplitude", &TG_PathParams::noise_amplitude, 0.f);
		godot::register_property("noise_curve", &TG_PathParams::noise_curve, 1.f);

		godot::register_property("end_cap_flat", &TG_PathParams::end_cap_flat, true);

		godot::register_property("seek_sun", &TG_PathParams::seek_sun, 0.f);

		godot::register_property("main_material_index", &TG_PathParams::main_material_index, 0);
		godot::register_property("cap_material_index", &TG_PathParams::cap_material_index, 0);
		godot::register_property("uv_scale", &TG_PathParams::uv_scale, godot::Vector2(1.f, 1.f));
	}
};

#endif // TG_PATH_PARAMS_H
