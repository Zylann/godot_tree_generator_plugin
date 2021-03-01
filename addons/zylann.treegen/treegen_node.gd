tool
extends Node

# Using `var` instead of `const` because otherwise it creates a cyclic dependency
var TreeGenTree = load("res://addons/zylann.treegen/treegen_tree.gd")
const TG_Node = preload("./native/tg_node.gdns")


var _data := TG_Node.new()
var _tree = null


func _treegen_get_root():
	return get_node_in_parents(self, TreeGenTree)


# Goes up all parents until a node of the given class is found
static func get_node_in_parents(node: Node, klass) -> Node:
	while node != null:
		node = node.get_parent()
		if node != null and node is klass:
			return node
	return null


func _get_configuration_warning() -> String:
	if _tree == null:
		return "This node must be under a TreeGen root"
	if not (get_parent() is get_script() or get_parent() is TreeGenTree):
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
			_tree = _treegen_get_root()
			if _tree != null:
				_tree.schedule_parsing()
	
		NOTIFICATION_UNPARENTED:
			if _tree != null:
				_tree.schedule_parsing()
			_tree = null


func get_tg_node():
	return _data

