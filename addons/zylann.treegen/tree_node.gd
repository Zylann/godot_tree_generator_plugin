tool

var position = Vector3()
var orientation = Quat()
var step_distance = 0
var next_child_distance = 0
var can_grow_children = false
var branch_length = 0
var generation = 0
var begin_radius = 1
var end_radius = 1
#var parent = null # If you want this, use weakref!
var children = []
var history = []
var orientation_history = []


func _init():
	pass


func create_child():
	var child = get_script().new()
	child.position = position
	child.orientation = orientation
	child.step_distance = step_distance
	child.generation = generation + 1
#	child.begin_radius = begin_radius
#	child.end_radius = end_radius
	#child.parent = parent
	children.append(child)
	return child
