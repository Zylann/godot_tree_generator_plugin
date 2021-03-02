tool
extends EditorPlugin

const TreeGenTree = preload("../treegen_tree.gd")
const TreeGenBranch = preload("../treegen_branch.gd")
const TreeGenLeaf = preload("../treegen_leaf.gd")

const MENU_SAVE_AS_MESH = 0

var _menu : MenuButton
var _save_file_dialog : EditorFileDialog
var _tree_node : TreeGenTree


static func get_icon(name):
	return load("res://addons/zylann.treegen/tools/icons/icon_" + name + ".svg")


func _enter_tree():
	add_custom_type("TreeGenTree", "Spatial", TreeGenTree, get_icon("tree_node"))
	add_custom_type("TreeGenBranch", "Node", TreeGenBranch, get_icon("tree_node"))
	add_custom_type("TreeGenLeaf", "Node", TreeGenLeaf, get_icon("tree_node"))

	_menu = MenuButton.new()
	_menu.set_text("Tree")
	_menu.get_popup().add_item("Save As Mesh...", MENU_SAVE_AS_MESH)
	_menu.get_popup().connect("id_pressed", self, "_on_menu_id_pressed")
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _menu)
	_menu.hide()

	var editor_interface := get_editor_interface()
	var base_control := editor_interface.get_base_control()

	_save_file_dialog = EditorFileDialog.new()
	_save_file_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
	_save_file_dialog.add_filter("*.mesh ; MESH files")
	_save_file_dialog.resizable = true
	_save_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	#_save_file_dialog.current_dir = 
	_save_file_dialog.connect("file_selected", self, "_on_save_file_dialog_file_selected")
	base_control.add_child(_save_file_dialog)


func _exit_tree():
	remove_custom_type("TreeGenTree")
	remove_custom_type("TreeGenBranch")
	remove_custom_type("TreeGenLeaf")


func handles(obj: Object) -> bool:
	return obj is TreeGenTree


func make_visible(visible: bool):
	_menu.visible = visible


func edit(obj: Object):
	_tree_node = obj


func _on_menu_id_pressed(id: int):
	match id:
		MENU_SAVE_AS_MESH:
			var mesh := _tree_node.get_generated_mesh()
			if mesh == null:
				push_error("No generated mesh")
				return
			_save_file_dialog.popup_centered_ratio()


func _on_save_file_dialog_file_selected(fpath: String):
	var mesh := _tree_node.get_generated_mesh()
	ResourceSaver.save(fpath, mesh)
