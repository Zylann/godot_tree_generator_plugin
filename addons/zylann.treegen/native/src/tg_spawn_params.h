#ifndef TG_SPAWN_PARAMS_H
#define TG_SPAWN_PARAMS_H

#include <Godot.hpp>
#include <gen/Reference.hpp>

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

#endif // TG_SPAWN_PARAMS_H
