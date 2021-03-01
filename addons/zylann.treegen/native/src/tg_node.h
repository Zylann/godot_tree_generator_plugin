#ifndef TG_NODE_H
#define TG_NODE_H

#include "macros.h"
#include "tg_path_params.h"
#include "tg_spawn_params.h"

#include <gen/Mesh.hpp>
#include <gen/Reference.hpp>
#include <vector>

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

	// Type get_type() const {
	// 	return _type;
	// }

	// void set_type(Type type) {
	// 	_type = type;
	// }

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
