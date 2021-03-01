tool
extends "treegen_node.gd"

const _leaf_properties = {
	"leaf_scale": 0,
	"leaf_scale_jitter": 0
}

var _leaf_material : Material


func _init():
	_data.set_type(TG_NODE_TYPE_LEAF)


func get_materials() -> Array:
	return [_leaf_material]


func assign_material_indexes(material_to_index: Dictionary):
	var leaf_material_index : int = material_to_index[_leaf_material]
	_data.get_leaf_params().material_index = leaf_material_index


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
		}
	])

	props.append_array([
		{
			"name": "Shape",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
		},
		{
			"name": "leaf_scale",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		},
		{
			"name": "leaf_scale_jitter",
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
			"name": "leaf_material",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Material",
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
		}
	])

	return props


func _get(p_key: String):
	if p_key == "local_seed":
		return _data.get_local_seed()
	
	elif p_key == "leaf_material":
		return _leaf_material

	elif p_key.begins_with("leaf_"):
		if p_key in _leaf_properties:
			var key = p_key.right(5)
			return _data.get_leaf_params().get(key)

	return null


func _set(p_key: String, value):
	if p_key == "local_seed":
		_data.set_local_seed(value)
		_on_data_changed()
		return true
	
	elif p_key == "leaf_material":
		_leaf_material = value
		_on_data_changed()
		return true
	
	elif p_key.begins_with("leaf_"):
		if p_key in _leaf_properties:
			var key = p_key.right(5)
			if _leaf_properties[p_key] == TYPE_OBJECT:
				_set_resource_property(_data.get_leaf_params(), key, value)
			else:
				_data.get_leaf_params().set(key, value)
			_on_data_changed()
			return true

	return false

