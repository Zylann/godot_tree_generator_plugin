#ifndef TG_LEAF_PARAMS_H
#define TG_LEAF_PARAMS_H

#include <Godot.hpp>

class TG_LeafParams : public godot::Reference {
	GODOT_CLASS(TG_LeafParams, godot::Reference)
public:
	void _init() {}

	int material_index = 0;
	float scale = 1.f;
	float scale_jitter = 0.f;

	//godot::Ref<godot::Mesh> mesh;

	static void _register_methods() {
		godot::register_property("material_index", &TG_LeafParams::material_index, 0);
		godot::register_property("scale", &TG_LeafParams::scale, 1.f);
		godot::register_property("scale_jitter", &TG_LeafParams::scale_jitter, 0.f);

		// godot::register_property("mesh", &TG_LeafParams::mesh,
		// 		godot::Ref<godot::Mesh>(), GODOT_METHOD_RPC_MODE_DISABLED, GODOT_PROPERTY_USAGE_DEFAULT,
		// 		GODOT_PROPERTY_HINT_RESOURCE_TYPE, "Mesh");
	}
};

#endif // TG_LEAF_PARAMS_H
