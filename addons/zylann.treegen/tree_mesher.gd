tool

const Util = preload("util.gd")

var _positions = PoolVector3Array()
var _normals = PoolVector3Array()
var _indices = PoolIntArray()


func _init():
	reset()


func reset():
	_positions = PoolVector3Array()
	_normals = PoolVector3Array()
	_indices = PoolIntArray()


func add_tree(root, begin_radius, end_radius, steps):
	add_path(root.history, root.orientation_history, begin_radius, end_radius, steps)
	
	for i in range(root.children.size()):
		var child = root.children[i]
		add_tree(root.children[i], child.begin_radius, child.end_radius, steps)


func add_path(points, orientations, begin_radius, end_radius, steps):
	if points.size() < 2:
		return
	
	# pos0 ---------- pos1
	
	for i in range(1, points.size()):
		var pos0 = points[i - 1]
		var pos1 = points[i]
		
		var ori0 = orientations[i - 1]
		var ori1 = orientations[i]
		
		if i == 1:
			# Add first ring, not connected to previous vertices
			add_ring(pos0, ori0, begin_radius, steps)
			continue
		
		var ori1_avg = ori0.slerp(ori1, 0.5)
		
		var t = float(i) / float(points.size())
		var radius = lerp(begin_radius, end_radius, t)
		
		add_ring(pos1, ori1_avg, radius, steps)
		connect_ring(steps)
	
	add_cap(points[points.size() - 1], steps)


func finish():
	print("Positions: ", _positions.size(), ", indices: ", _indices.size())
	
	# Debug checks
	for i in range(_indices.size()):
		var index = _indices[i]
		if index >= _positions.size() or index < 0:
			print("Index ", i, " out of bounds: ", index, "/", _positions.size())
			assert(false)
			return null
	
	_normals = Util.calculate_normals(_positions, _indices)
	#print("Normals: ", _normals.size())
	assert(_positions.size() == _normals.size())
	
#	for p in _positions:
#		print(p)
	
	var arrays = []
	arrays.resize(9)
	arrays[Mesh.ARRAY_VERTEX] = _positions
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_INDEX] = _indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	reset()
	
	return mesh


func add_ring(center, q, radius, steps):
	for i in range(0, steps):
		var t = 2.0 * PI * float(i) / float(steps)
		# Describe a Y-oriented ring, then rotate it using the branch orientation
		var dir = q * Vector3(cos(t), 0, sin(t))
		var pos = center + radius * dir
		_positions.append(pos)


func add_cap(center, steps):
	_positions.append(center)
	
	var ib = _positions.size() - steps - 1
	var ie = _positions.size() - 1
	
	var i0 = ib
	for i in range(1, steps):
		_indices.append(i0)
		i0 += 1
		_indices.append(i0)
		_indices.append(ie)
	
	_indices.append(i0)
	_indices.append(ib)
	_indices.append(ie)


func connect_ring(steps):
	# TODO Have a way to connect rings having different step count
	
	var vi0 = _positions.size() - 2 * steps
	assert(vi0 >= 0)
	
	var i0 = vi0
	var i1 = vi0 + 1
	var i2 = vi0 + steps
	var i3 = vi0 + steps + 1
	
	for i in range(1, steps):
		add_quad_indices(i0, i1, i2, i3)
		i0 += 1
		i1 += 1
		i2 += 1
		i3 += 1
	
	# Last quad closes the loop
	
	i1 = vi0
	i3 = vi0 + steps
	
	add_quad_indices(i0, i1, i2, i3)


func add_quad_indices(i0, i1, i2, i3):
	#  --2---3--
	#    |  /|
	#    | / |
	#    |/  |
	#  --0---1--
	
	_indices.append(i0)
	_indices.append(i1)
	_indices.append(i3)
	
	_indices.append(i0)
	_indices.append(i3)
	_indices.append(i2)





