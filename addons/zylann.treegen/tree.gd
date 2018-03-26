tool
extends Spatial


const TreeNode = preload("tree_node.gd")
const TreeMesher = preload("tree_mesher.gd")
const DirectMeshInstance = preload("direct_mesh_instance.gd")
const Util = preload("util.gd")


export var random_seed = 131183 setget set_random_seed

export var step_distance = 2.0 setget set_step_distance
export var curviness = 0.2 setget set_curviness
export var max_length = 30.0 setget set_max_length

export var begin_radius = 1.0 setget set_begin_radius
export var end_radius = 0.1 setget set_end_radius
export var cylinder_points = 5 setget set_cylinder_points

export var branch_interval = 3.0 setget set_branch_interval
export var branch_interval_randomness = 0.0 setget set_branch_interval_randomness
export var branch_direction_randomness = 0.2 setget set_branch_direction_randomness
export var branch_start_margin = 3.0 setget set_branch_start_margin
export var branch_end_margin = 2.0 setget set_branch_end_margin

export(Material) var branch_material = null setget set_branch_material

var _mesher = TreeMesher.new()
var _dirty = false
var _mesh = null
var _mesh_instance = DirectMeshInstance.new()
var _branch_material = null


func _init():
	set_notify_transform(true)


func set_random_seed(v):
	random_seed = int(v)
	_make_dirty()


func set_step_distance(v):
	step_distance = max(v, 0.0)
	_make_dirty()


func set_curviness(v):
	curviness = max(v, 0.0)
	_make_dirty()


func set_max_length(v):
	max_length = max(v, 0.0)
	_make_dirty()


func set_begin_radius(v):
	begin_radius = max(v, 0.01)
	_make_dirty()


func set_end_radius(v):
	end_radius = max(v, 0.01)
	_make_dirty()


func set_cylinder_points(v):
	cylinder_points = int(max(v, 3))
	_make_dirty()


func set_branch_interval(v):
	branch_interval = max(v, 0.1)
	_make_dirty()


func set_branch_interval_randomness(v):
	branch_interval_randomness = clamp(v, 0.0, 1.0)
	_make_dirty()


func set_branch_direction_randomness(v):
	branch_direction_randomness = clamp(v, 0.0, 1.0)
	_make_dirty()


func set_branch_start_margin(v):
	branch_start_margin = max(v, 0.0)
	_make_dirty()


func set_branch_end_margin(v):
	branch_end_margin = max(v, branch_start_margin)
	_make_dirty()


func set_branch_material(v):
	branch_material = v
	_mesh_instance.set_material_override(v)


func _make_dirty():
	if not _dirty:
		_dirty = true
		call_deferred("_generate")


func _ready():
	_generate()


func _notification(what):
	match what:
		NOTIFICATION_ENTER_WORLD:
			#print("Enter world")
			_mesh_instance.set_world(get_world())

		NOTIFICATION_EXIT_WORLD:
			#print("Exit world")
			_mesh_instance.set_world(null)

		NOTIFICATION_TRANSFORM_CHANGED:
			#print("Transform changed")
			_mesh_instance.set_transform(get_transform())

		NOTIFICATION_VISIBILITY_CHANGED:
			#print("Visibility changed ", visible)
			_mesh_instance.set_visible(visible)


func _generate():
	seed(random_seed)
	var root = _generate_node_tree()
	_mesher.add_tree(root, begin_radius, end_radius, cylinder_points)
	_mesh = _mesher.finish()
	_mesh_instance.set_mesh(_mesh)
	_dirty = false


func _get_next_child_distance():
	var r = rand_range(1.0 - branch_interval_randomness, 1.0 + branch_interval_randomness)
	return r * branch_interval + branch_start_margin


func _generate_node_tree():
	var nodes = []
	
	var root = TreeNode.new()
	root.step_distance = step_distance
	root.next_child_distance = _get_next_child_distance()
	root.can_grow_children = true
	root.begin_radius = begin_radius
	root.end_radius = end_radius
	nodes.append(root)
	
	var j = 0
	while nodes.size() != 0 and j < 200:
		var i = 0
		while i < nodes.size():
			var node = nodes[i]
			if not _grow(node, nodes):
				var last = nodes.size() - 1
				if i != last:
					nodes[i] = nodes[last]
				nodes.pop_back()
			i += 1
		j += 1
	
	return root


func _grow(node, nodes):
	node.history.append(node.position)
	node.orientation_history.append(node.orientation)
	
	var dir = node.orientation * Vector3(0,1,0)
	
	node.position += dir * node.step_distance
	node.orientation = Util.randomize_quat(node.orientation, curviness)
	node.branch_length += node.step_distance
	
	var local_max_len = max_length / float(node.generation + 1)
	if node.branch_length > local_max_len:
		return false
	
	if node.can_grow_children and node.branch_length >= node.next_child_distance:
		if node.branch_length < local_max_len - branch_end_margin:
			node.next_child_distance += _get_next_child_distance()
			
			var child = node.create_child()
			child.orientation = Util.randomize_quat(child.orientation, branch_direction_randomness)
			child.begin_radius = lerp(node.begin_radius, node.end_radius, node.branch_length / local_max_len)
			child.end_radius = node.end_radius
			child.can_grow_children = (child.generation < 2)
			nodes.append(child)
	
	return true

