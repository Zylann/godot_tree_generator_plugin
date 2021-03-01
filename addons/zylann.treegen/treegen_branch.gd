tool
extends "treegen_node.gd"

const _path_properties = {
	"path_length": 0,
	"path_length_randomness": 0,
	"path_length_curve_along_parent": TYPE_OBJECT,
	
	"path_min_radius": 0,
	"path_max_radius": 0,
	"path_radius_curve": TYPE_OBJECT,
	"path_radius_curve_along_parent": TYPE_OBJECT,

	"path_noise_period": 0,
	"path_noise_octaves": 0,
	"path_noise_amplitude": 0,
	"path_noise_curve": 0,
	"path_seek_sun": 0,

	"path_uv_scale": 0
}

var _main_material : Material
var _cap_material : Material


func _init():
	_data.set_type(TG_NODE_TYPE_BRANCH)

	var curve = Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	curve.bake()
	_set_resource_property(_data.get_path_params(), "radius_curve", curve)
	
	curve = Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(0.5, 1))
	curve.add_point(Vector2(1, 1))
	curve.bake()
	_set_resource_property(_data.get_path_params(), "length_curve_along_parent", curve)

	curve = Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(0.5, 1))
	curve.add_point(Vector2(1, 1))
	curve.bake()
	_set_resource_property(_data.get_path_params(), "radius_curve_along_parent", curve)


func get_materials() -> Array:
	return [_main_material, _cap_material]


func assign_material_indexes(material_to_index: Dictionary):
	var main_material_index : int = material_to_index[_main_material]
	var cap_material_index : int = material_to_index[_cap_material]

	_data.get_path_params().main_material_index = main_material_index
	_data.get_path_params().cap_material_index = cap_material_index


func _get_property_list() -> Array:
	var props = []

	props.append_array([
		{
			"name": "active",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
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
			"name": "path_min_radius",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_max_radius",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_radius_curve",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Curve",
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
		}
	])

	props.append_array(_spawn_properties_list)

	props.append_array([
		{
			"name": "Materials",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
		},
		{
			"name": "main_material",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Material",
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "cap_material",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Material",
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "path_uv_scale",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		}
	])

	return props


func _get(p_key: String):
	if p_key == "local_seed":
		return _data.get_local_seed()
	
	elif p_key == "end_cap_flat":
		return _data.get_path_params().end_cap_flat

	elif p_key == "main_material":
		return _main_material

	elif p_key == "cap_material":
		return _cap_material

	elif p_key.begins_with("path_"):
		if p_key in _path_properties:
			var key = p_key.right(5)
			return _data.get_path_params().get(key)

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

	elif p_key == "main_material":
		_main_material = value
		_on_data_changed()
		return true

	elif p_key == "cap_material":
		_cap_material = value
		_on_data_changed()
		return true
	
	elif p_key.begins_with("path_"):
		if p_key in _path_properties:
			var key = p_key.right(5)
			if _path_properties[p_key] == TYPE_OBJECT:
				_set_resource_property(_data.get_path_params(), key, value)
			else:
				_data.get_path_params().set(key, value)
			_on_data_changed()
			return true
	
	return false

