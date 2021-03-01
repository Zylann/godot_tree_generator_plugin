#include "tg_tree.h"

extern "C" {

void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options *o) {
	printf("godot_gdnative_init treegen_native\n");
	godot::Godot::gdnative_init(o);
}

void GDN_EXPORT godot_gdnative_terminate(godot_gdnative_terminate_options *o) {
	printf("godot_gdnative_terminate treegen_native\n");
	godot::Godot::gdnative_terminate(o);
}

void GDN_EXPORT godot_nativescript_init(void *handle) {
	printf("godot_nativescript_init treegen_native\n");
	godot::Godot::nativescript_init(handle);

	godot::register_tool_class<TG_SpawnParams>();
	godot::register_tool_class<TG_PathParams>();
	godot::register_tool_class<TG_LeafParams>();
	godot::register_tool_class<TG_Node>();
	godot::register_tool_class<TG_NodeInstance>();
	godot::register_tool_class<TG_Tree>();
}

} // extern "C"
