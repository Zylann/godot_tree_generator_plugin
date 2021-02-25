tool
extends EditorPlugin


const TreeGenTree = preload("../treegen_tree.gd")
const TreeGenBranch = preload("../treegen_branch.gd")


static func get_icon(name):
	return load("res://addons/zylann.treegen/tools/icons/icon_" + name + ".svg")


func _enter_tree():
	add_custom_type("TreeGenTree", "Spatial", TreeGenTree, get_icon("tree_node"))
	add_custom_type("TreeGenBranch", "Node", TreeGenBranch, get_icon("tree_node"))


func _exit_tree():
	remove_custom_type("TreeGenTree")
	remove_custom_type("TreeGenBranch")
