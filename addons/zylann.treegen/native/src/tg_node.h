#ifndef TG_NODE_H
#define TG_NODE_H

#include "macros.h"
#include "tg_leaf_params.h"
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
		TYPE_LEAF = 1,
		TYPE_COUNT
	};

	void _init() {
		_spawn_params.instance();
		_path_params.instance();
		_leaf_params.instance();
	}

	Type get_type() const {
		return _type;
	}

	void set_type(Type type) {
		_type = type;
	}

	int get_local_seed() const {
		return _local_seed;
	}

	void set_local_seed(int p_local_seed) {
		_local_seed = p_local_seed;
	}

	bool is_active() const {
		return _active;
	}

	void set_active(bool active) {
		_active = active;
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

	const TG_LeafParams &get_leaf_params() const {
		TG_CRASH_COND(_leaf_params.is_null());
		return **_leaf_params;
	}

	const TG_Node &get_child_internal(int i) const {
		const godot::Ref<TG_Node> &ref = _children[i];
		TG_CRASH_COND(ref.is_null());
		return **ref;
	}

	static void _register_methods() {
		godot::register_method("get_spawn_params", &TG_Node::_b_get_spawn_params);
		godot::register_method("get_path_params", &TG_Node::_b_get_path_params);
		godot::register_method("get_leaf_params", &TG_Node::_b_get_leaf_params);

		godot::register_method("get_local_seed", &TG_Node::get_local_seed);
		godot::register_method("set_local_seed", &TG_Node::set_local_seed);

		godot::register_method("is_active", &TG_Node::is_active);
		godot::register_method("set_active", &TG_Node::set_active);

		godot::register_method("set_type", &TG_Node::_b_set_type);

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

	godot::Ref<TG_LeafParams> _b_get_leaf_params() {
		return _leaf_params;
	}

	godot::Ref<TG_Node> _b_get_child(int i) {
		ERR_FAIL_INDEX_V(i, _children.size(), godot::Ref<TG_Node>());
		return _children[i];
	}

	// TODO enums in bindings?
	void _b_set_type(int type) {
		ERR_FAIL_INDEX(type, TYPE_COUNT);
		_type = static_cast<Type>(type);
	}

	godot::Ref<TG_SpawnParams> _spawn_params;
	godot::Ref<TG_PathParams> _path_params;
	godot::Ref<TG_LeafParams> _leaf_params;
	int _local_seed = 0;
	bool _active = true;
	Type _type = TYPE_BRANCH;
	std::vector<godot::Ref<TG_Node> > _children;
};

#endif // TG_NODE_H
