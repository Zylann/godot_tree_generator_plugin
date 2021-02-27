tool
extends "treegen_node.gd"

const TG_SpawnParams = preload("./native/tg_spawn_params.gdns")
const TG_GrowParams = preload("./native/tg_path_params.gdns")


const _properties = {
	"path_length": 0,
	"path_length_randomness": 0,
	"path_length_curve_along_parent": TYPE_OBJECT,
	
	"path_begin_radius": 0,
	"path_end_radius": 0,
	"path_radius_curve": 0,
	"path_radius_curve_along_parent": TYPE_OBJECT,

	"path_noise_period": 0,
	"path_noise_octaves": 0,
	"path_noise_amplitude": 0,
	"path_noise_curve": 0,
	"path_seek_sun": 0,
	
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


func _init():
	_data = TG_Node.new()
	#_data.set_type(TG_Node.TYPE_BRANCH)
	
	var curve = Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(0.5, 1))
	curve.add_point(Vector2(1, 1))
	curve.bake()
	_set_resource(_data.get_path_params(), "length_curve_along_parent", curve)

	curve = Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(0.5, 1))
	curve.add_point(Vector2(1, 1))
	curve.bake()
	_set_resource(_data.get_path_params(), "radius_curve_along_parent", curve)


func _get_property_list() -> Array:
	return [
		{
			"name": "local_seed",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		#####################################################
		{
			"name": "Length",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
		},
		{
			"name": "path_length",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_length_randomness",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_length_curve_along_parent",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Curve",
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		#####################################################
		{
			"name": "Shape",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
		},
		{
			"name": "path_begin_radius",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_end_radius",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_radius_curve",
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_EXP_EASING,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_radius_curve_along_parent",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Curve",
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "end_cap_flat",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		#####################################################
		{
			"name": "Curving",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
		},
		{
			"name": "path_noise_period",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_noise_octaves",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_noise_amplitude",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_noise_curve",
			"type": TYPE_REAL,
			"hint": PROPERTY_HINT_EXP_EASING,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_seek_sun",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		#####################################################
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
		#####################################################
		{
			"name": "Spawn Misc",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
		},
		{
			"name": "spawn_skip_probability",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
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


func _get(p_key: String):
	if p_key == "local_seed":
		return _data.get_local_seed()
	
	elif p_key == "end_cap_flat":
		return _data.get_path_params().end_cap_flat

	elif p_key.begins_with("path_"):
		if p_key in _properties:
			var key = p_key.right(5)
			return _data.get_path_params().get(key)

	if p_key.begins_with("spawn_"):
		if p_key in _properties:
			var key = p_key.right(6)
			return _data.get_spawn_params().get(key)

	return null


func _set(p_key: String, value):
	if p_key == "local_seed":
		_data.set_local_seed(value)
		_on_data_changed()
		return true
	
	elif p_key == "end_cap_flat":
		_data.get_path_params().end_cap_flat = value
		_on_data_changed()
		return true
	
	elif p_key.begins_with("path_"):
		if p_key in _properties:
			var key = p_key.right(5)
			if _properties[p_key] == TYPE_OBJECT:
				_set_resource(_data.get_path_params(), key, value)
			else:
				_data.get_path_params().set(key, value)
			_on_data_changed()
			return true
			
	elif p_key.begins_with("spawn_"):
		if p_key in _properties:
			var key = p_key.right(6)
			_data.get_spawn_params().set(key, value)
			_on_data_changed()
			return true

	return false


func _on_data_changed():
	if _tree != null:
		_tree.schedule_parsing()


func _set_resource(obj: Object, key: String, value: Resource):
	var prev : Resource = obj.get(key)
	if prev != null:
		prev.disconnect("changed", self, "_on_data_changed")
	obj.set(key, value)
	if value != null:
		value.connect("changed", self, "_on_data_changed")

