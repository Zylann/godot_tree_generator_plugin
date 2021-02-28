tool
extends Spatial

const TG_Tree = preload("./native/tg_tree.gdns")
const TG_Node = preload("./native/tg_node.gdns")
const TG_NodeInstance = preload("./native/tg_node_instance.gdns")
const TreeGenNode = preload("./treegen_node.gd")

const AxesScene = preload("./axes.tscn")

# Global params
export(int) var global_seed = 0 setget set_global_seed

# Quality settings
export(float) var mesh_divisions_per_unit := 1.0 setget set_mesh_divisions_per_unit
export(float) var branch_segments_per_unit := 1.0 setget set_branch_segments_per_unit

# Tree
var _generator = TG_Tree.new()
var _nodes = []
var _parsing_scheduled = false


#func _ready():
#	_parse_scene_nodes()


func set_global_seed(new_seed: int):
	global_seed = new_seed
	_generator.set_global_seed(new_seed)
	if is_inside_tree():
		generate()


func set_mesh_divisions_per_unit(v: float):
	v = max(v, 0.0)
	mesh_divisions_per_unit = v
	_generator.set_mesh_divisions_per_unit(v)
	if is_inside_tree():
		generate()


func set_branch_segments_per_unit(v: float):
	v = max(v, 0.0)
	branch_segments_per_unit = v
	_generator.set_branch_segments_per_unit(v)
	if is_inside_tree():
		generate()


func generate():
	for node in _nodes:
		node.queue_free()
	_nodes.clear()
	
	var time_before = OS.get_ticks_msec()
	var surfaces = _generator.generate()
	var elapsed_gen = OS.get_ticks_msec() - time_before
	
	time_before = OS.get_ticks_msec()
	var mesh := ArrayMesh.new()
	for surface in surfaces:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	var mi = MeshInstance.new()
	mi.mesh = mesh
	add_child(mi)
	_nodes.append(mi)
	var elapsed_mesh = OS.get_ticks_msec() - time_before
	
	print("Gen: ", elapsed_gen, ", mesh: ", elapsed_mesh)


func schedule_parsing():
	if _parsing_scheduled:
		return
	_parsing_scheduled = true
	call_deferred("_parse_scene_nodes")


func _parse_scene_nodes():
	if not is_inside_tree():
		# WTF are you doing
		return
	
	var root
	for child in get_children():
		if child is TreeGenNode:
			# Root
			root = child.get_tg_node()
			_parse_scene_nodes_recursive(child)
			_generator.set_root_node(root)
			break

	generate()
	_parsing_scheduled = false


func _parse_scene_nodes_recursive(scene_node: TreeGenNode):
	var tg_node = scene_node.get_tg_node()
	if tg_node == null:
		return
	tg_node.clear_children()
	for child_scene_node in scene_node.get_children():
		if child_scene_node is TreeGenNode:
			var child_tg_node = child_scene_node.get_tg_node()
			if child_tg_node != null:
				tg_node.add_child(child_tg_node)
				_parse_scene_nodes_recursive(child_scene_node)


#func _clear_debug_axes():
#	for child in get_children():
#		if child.is_in_group("zylann.treegen.debug_axes"):
#			child.queue_free()	
#
#
#func _debug_axes(path: Array):
#	for trans in path:
#		var axes = AxesScene.instance()
#		axes.transform = trans
#		axes.add_to_group("zylann.treegen.debug_axes")
#		add_child(axes)
