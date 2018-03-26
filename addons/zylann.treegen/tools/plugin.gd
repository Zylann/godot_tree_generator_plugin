tool
extends EditorPlugin


const TreeMesh = preload("../tree.gd")


static func get_icon(name):
	return load("res://addons/zylann.treegen/tools/icons/icon_" + name + ".svg")


func _enter_tree():
	add_custom_type("TreeMesh", "Spatial", TreeMesh, get_icon("tree_node"))


