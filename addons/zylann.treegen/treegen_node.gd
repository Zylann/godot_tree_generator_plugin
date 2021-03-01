tool
extends Node

# Using `var` instead of `const` because otherwise it creates a cyclic dependency
var TreeGenTree = load("res://addons/zylann.treegen/treegen_tree.gd")
var TreeGenNode = load("res://addons/zylann.treegen/treegen_node.gd")
const TG_Node = preload("./native/tg_node.gdns")
const Util = preload("./util.gd")

const TG_NODE_TYPE_BRANCH = 0
const TG_NODE_TYPE_LEAF = 1

const _spawn_properties = {
	"spawn_along_base_amount": 0,
	"spawn_along_amount_per_unit": 0,
	"spawn_along_begin_ratio": 0,
	"spawn_along_end_ratio": 0,
	"spawn_along_jitter": 0,
	"spawn_around_amount": 0,
	"spawn_around_jitter": 0,
	"spawn_around_offset": 0,
	"spawn_skip_probability": 0,
	"spawn_vertical_angle": 0,
	"spawn_vertical_angle_jitter": 0
}

var _data := TG_Node.new()
var _tree = null

const _spawn_properties_list = [
	{
		"name": "Spawn Along",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	},
	{
		"name": "spawn_along_base_amount",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	{
		"name": "spawn_along_amount_per_unit",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	{
		"name": "spawn_along_begin_ratio",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	{
		"name": "spawn_along_end_ratio",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	{
		"name": "spawn_along_jitter",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	#####################################################
	{
		"name": "Spawn Around",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	},
	{
		"name": "spawn_around_amount",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	{
		"name": "spawn_around_jitter",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	{
		"name": "spawn_around_offset",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	{
		"name": "spawn_skip_probability",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	#####################################################
	{
		"name": "Spawn angle",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	},
	{
		"name": "spawn_vertical_angle",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	},
	{
		"name": "spawn_vertical_angle_jitter",
		"type": TYPE_REAL,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
	}
]


func _get_configuration_warning() -> String:
	if _tree == null:
		return "This node must be under a TreeGen root"
	if not (get_parent() is TreeGenNode or get_parent() is TreeGenTree):
		return "This node must be under a TreeGen node"
	return ""


func get_materials() -> Array:
	# Implemented in subclasses
	return []


func assign_material_indexes(material_to_index: Dictionary):
	# Implemented in subclasses
	pass


func _notification(what: int):
	match what:
		NOTIFICATION_PARENTED:
			_tree = Util.get_node_in_parents(self, TreeGenTree)
			if _tree != null:
				_tree.schedule_parsing()
	
		NOTIFICATION_UNPARENTED:
			if _tree != null:
				_tree.schedule_parsing()
			_tree = null


func get_tg_node():
	return _data


func _on_data_changed():
	if _tree != null:
		_tree.schedule_parsing()


func _set_resource_property(obj: Object, key: String, value: Resource):
	var prev : Resource = obj.get(key)
	if prev != null:
		prev.disconnect("changed", self, "_on_data_changed")
	obj.set(key, value)
	if value != null:
		value.connect("changed", self, "_on_data_changed")


func _get(p_key: String):
	if p_key == "active":
		return _data.is_active()

	elif p_key.begins_with("spawn_"):
		if p_key in _spawn_properties:
			var key = p_key.right(6)
			return _data.get_spawn_params().get(key)

	return null


func _set(p_key: String, value):
	if p_key == "active":
		_data.set_active(value)
		_on_data_changed()
		return true
	
	elif p_key.begins_with("spawn_"):
		if p_key in _spawn_properties:
			var key = p_key.right(6)
			_data.get_spawn_params().set(key, value)
			_on_data_changed()
			return true

	return false
