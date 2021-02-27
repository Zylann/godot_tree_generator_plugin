tool

# Core functionality.
# It is abstracted away from UI or Godot's node system for portability,
# or can even run in a thread.

# Can't use `Tree`, it's taken already.
# Oops, can't use `Node` either.
# Let's prefix everything then.

const TG_Node = preload("./tg_node.gd")
const TG_NodeInstance = preload("./tg_node_instance.gd")
const TG_GrowParams = preload("./tg_grow_params.gd")
const TG_SpawnParams = preload("./tg_spawn_params.gd")

# Global params
var global_seed := 0

# Quality settings
var mesh_divisions_per_unit := 1.0
var branch_segments_per_unit := 1.0

# Tree definition
var root_node := TG_Node.new()
# Generated tree
var root_instance : TG_NodeInstance


func generate():
	root_instance = TG_NodeInstance.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = global_seed + root_node.local_seed
	_process_node(root_node, root_instance, Vector3(0, 1, 0), rng)


func _process_node(node: TG_Node, node_instance: TG_NodeInstance, sun_dir_local: Vector3,
	rng: RandomNumberGenerator):
		
	if node.grow_params != null:
		_generate_node_path(node, node_instance, sun_dir_local, rng)
	
	if len(node.children) == 0:
		return

	var path_length : float = node_instance.path_distances[-1]
	
	# Process children
	for i in len(node.children):
		var child : TG_Node = node.children[i]

		var child_rng = RandomNumberGenerator.new()
		child_rng.seed = global_seed + child.local_seed
		
		var spawns := generate_spawns(child.spawn_params, child_rng, path_length)
		
		for j in len(spawns):
			var spawn_trans : Transform = spawns[j]
			var offset := spawn_trans.origin.y * path_length
			# TODO Sample parent radius and offset child accordingly
			var path_trans := interpolate_path(
				node_instance.path, node_instance.path_distances, offset)
			var child_node_instance := TG_NodeInstance.new()
			child_node_instance.offset_ratio = spawn_trans.origin.y
			child_node_instance.transform = \
				Transform(path_trans.basis * spawn_trans.basis, path_trans.origin)

			_process_node(child, child_node_instance,
				child_node_instance.transform.basis.inverse() * sun_dir_local, child_rng)
			
			node_instance.children.append(child_node_instance)


func _generate_node_path(node: TG_Node, node_instance: TG_NodeInstance, sun_dir_local: Vector3,
	rng: RandomNumberGenerator):
		
	var relative_offset_ratio := \
		(node_instance.offset_ratio - node.spawn_params.along_begin_ratio) \
		/ (node.spawn_params.along_end_ratio - node.spawn_params.along_begin_ratio)

	# Calculate expected length
	var length_with_modifiers := node.grow_params.length
	if node.grow_params.length_curve_along_parent != null:
		length_with_modifiers *= \
			node.grow_params.length_curve_along_parent.interpolate_baked(relative_offset_ratio)
	length_with_modifiers += node.grow_params.length_randomness \
		* rng.randf_range(-1.0, 1.0) * length_with_modifiers

	var radius_multiplier := 1.0
	if node.grow_params.radius_curve_along_parent != null:
		radius_multiplier *= \
			node.grow_params.radius_curve_along_parent.interpolate_baked(relative_offset_ratio)

	var point_count := int(max(branch_segments_per_unit * length_with_modifiers, 2))
	var segment_length := 1.0 / branch_segments_per_unit
	
	var sun_basis := Basis()
	
	var path := []
	var radii := []
	
	var distance_step := length_with_modifiers / float(point_count)
	
	# Plot base points
	var trans := Transform()
	for i in point_count:
		var k := float(i) / float(point_count)
		
		var r : float = lerp(node.grow_params.begin_radius, node.grow_params.end_radius, 
			pow(k, node.grow_params.radius_curve)) * radius_multiplier
		
		radii.append(r)
		path.append(trans)
		
		if node.grow_params.seek_sun != 0.0:
			var seek_sun := node.grow_params.seek_sun / branch_segments_per_unit
			var tend_dir := sun_dir_local * sign(seek_sun)
			var a := sign(seek_sun) * trans.basis.y.angle_to(tend_dir)
			if abs(a) > 0.001:
				var axis = trans.basis.y.cross(tend_dir).normalized()
				trans.basis = trans.basis.rotated(axis, a * seek_sun)
		
		trans.origin += distance_step * trans.basis.y
	
	# Apply noise
	if node.grow_params.noise_amplitude != 0.0:
		var noise_x := OpenSimplexNoise.new()
		var noise_y := OpenSimplexNoise.new()
		var noise_z := OpenSimplexNoise.new()
		var noises := [noise_x, noise_y, noise_z]
		for i in len(noises):
			var noise : OpenSimplexNoise = noises[i]
			noise.seed = global_seed + node.local_seed + i
			noise.octaves = node.grow_params.noise_octaves
			noise.period = node.grow_params.noise_period

		for i in point_count:
			var k := float(i) / float(point_count)
			trans = path[i]
			var amp := node.grow_params.noise_amplitude * pow(k, node.grow_params.noise_curve)
			var disp := amp * Vector3(
				noise_x.get_noise_3dv(trans.origin), 
				noise_y.get_noise_3dv(trans.origin), 
				noise_z.get_noise_3dv(trans.origin))
			trans.origin += disp
			path[i] = trans
	
	# Renormalize length
	var length := calc_length(path)
	if length > 0.0:
		var rscale := length_with_modifiers / length
		scale_path(path, rscale)

	# TODO Optimize path so straight parts have less points

	# Bake distances
	var distances := [0.0]
	for i in range(1, len(path)):
		distances.append(distances[i - 1] + path[i].origin.distance_to(path[i - 1].origin))
	
	# Recalculate orientations after modifiers
	calc_orientations(path, segment_length)

	#_debug_axes(path)
	
	var mesh := generate_path_mesh(path, radii, mesh_divisions_per_unit, 
		node.grow_params.end_cap_flat)

	node_instance.path = path
	node_instance.radii = radii
	node_instance.path_distances = distances
	node_instance.mesh = mesh


static func generate_path_mesh(transforms: Array, radii: Array, divs_per_unit: float,
	end_cap_flat: bool) -> ArrayMesh:
		
	assert(len(transforms) == len(radii))
	
	var vertices := []
	var normals := []
	var indices := []
	
	var previous_ring_point_count := 0
	
	# TODO Path shape
	# TODO Path welding
	
	for transform_index in len(transforms):
		var trans : Transform = transforms[transform_index]
		var r : float = radii[transform_index]
		var circumference := TAU * r
		var point_count := int(max(circumference * divs_per_unit, 3))
		#point_count = 8
		
		for pi in point_count:
			var a := TAU * float(pi) / float(point_count)
			var normal := trans.basis.x.rotated(trans.basis.y, a)
			var pos := trans.origin + r * normal
			vertices.append(pos)
			normals.append(normal)
		
		if transform_index > 0:
			# Connect to previous ring
			if point_count == previous_ring_point_count:
				var prev_ring_begin := len(vertices) - 2 * point_count
				connect_rings_with_same_point_count(indices, prev_ring_begin, point_count)
			else:
				var ring_begin := len(vertices) - point_count
				var prev_ring_begin := ring_begin - previous_ring_point_count
				connect_rings_with_different_point_count(indices,
					prev_ring_begin, previous_ring_point_count,
					ring_begin, point_count)
		
		previous_ring_point_count = point_count
	
	_add_cap(vertices, normals, indices, transforms[-1], previous_ring_point_count, end_cap_flat)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PoolVector3Array(vertices)
	arrays[Mesh.ARRAY_NORMAL] = PoolVector3Array(normals)
	# TODO Tangents
	arrays[Mesh.ARRAY_INDEX] = PoolIntArray(indices)
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _add_cap(positions: Array, normals: Array, indices: Array, trans: Transform,
	point_count: int, flat: bool):
	
	if flat:
		var i0 := len(positions) - point_count
		for pi in point_count:
			positions.append(positions[i0 + pi])
			normals.append(trans.basis.y)
	
	positions.append(trans.origin)
	normals.append(trans.basis.y)
	
	var ib = positions.size() - point_count - 1
	var ie = positions.size() - 1
	
	var i0 = ib
	for i in range(1, point_count):
		indices.append(i0)
		i0 += 1
		indices.append(ie)
		indices.append(i0)
	
	indices.append(i0)
	indices.append(ie)
	indices.append(ib)


static func connect_rings_with_different_point_count(indices: Array, prev_ring_begin: int,
	prev_point_count: int, next_ring_begin: int, next_point_count: int):
		
	# Assumes rings have evenly sparsed points and their starting point is aligned.
	# If not then it would require an implementation that finds the closest points.
	
	var flip_winding = false
	if prev_point_count < next_point_count:
		# Swap
		var temp := prev_ring_begin
		prev_ring_begin = next_ring_begin
		next_ring_begin = temp

		temp = prev_point_count
		prev_point_count = next_point_count
		next_point_count = temp
		
		flip_winding = true
	
	assert(prev_point_count > next_point_count)
	
	var k := float(next_point_count) / float(prev_point_count)
	var c := 0.0

	var min_dst_i := next_ring_begin
	var max_dst_i := next_ring_begin + next_point_count
	
	var min_src_i := prev_ring_begin
	var max_src_i := prev_ring_begin + prev_point_count

	var src_i := prev_ring_begin
	var dst_i := next_ring_begin
	
	var added_indices_begin = len(indices)
	
	for i in prev_point_count:
		var prev_src_i := src_i
		src_i += 1
		if src_i == max_src_i:
			src_i = min_src_i
		indices.append(prev_src_i)
		indices.append(dst_i)
		indices.append(src_i)
		c += k
		if c >= 0.5:
			c -= 1.0
			var prev_dst_i := dst_i
			dst_i += 1
			if dst_i == max_dst_i:
				dst_i = min_dst_i
			indices.append(src_i)
			indices.append(prev_dst_i)
			indices.append(dst_i)
	
	if flip_winding:
		for i in range(added_indices_begin, len(indices), 3):
			var temp = indices[i]
			indices[i] = indices[i + 1]
			indices[i + 1] = temp


static func connect_rings_with_same_point_count(
	indices: Array, prev_ring_begin: int, point_count: int):
	
	var i0 = prev_ring_begin
	var i1 = prev_ring_begin + 1
	var i2 = prev_ring_begin + point_count
	var i3 = prev_ring_begin + point_count + 1
	
	for i in range(1, point_count):
		add_quad_indices(indices, i0, i1, i2, i3)
		i0 += 1
		i1 += 1
		i2 += 1
		i3 += 1
	
	# Last quad closes the loop
	i1 = prev_ring_begin
	i3 = prev_ring_begin + point_count
	add_quad_indices(indices, i0, i1, i2, i3)


static func add_quad_indices(indices: Array, i0: int, i1: int, i2: int, i3: int):
	#  --2---3--
	#    |  /|
	#    | / |
	#    |/  |
	#  --0---1--
	
	indices.append(i0)
	indices.append(i3)
	indices.append(i1)
	
	indices.append(i0)
	indices.append(i2)
	indices.append(i3)


static func interpolate_path(transforms: Array, distances: Array, offset: float) -> Transform:
	assert(len(transforms) == len(distances))
	for i in range(1, len(distances)):
		if distances[i] < offset:
			continue
		assert(i > 0)
		var prev_trans : Transform = transforms[i - 1]
		var trans : Transform = transforms[i]
		var prev_d : float = distances[i - 1]
		var d : float = distances[i]
		var t := (offset - prev_d) / (d - prev_d)
		return prev_trans.interpolate_with(trans, t)
	return transforms[len(transforms) - 1]


static func generate_spawns(params: TG_SpawnParams, rng: RandomNumberGenerator,
	parent_length: float) -> Array:
	
	var transforms := []
	
	var amount := \
		params.along_base_amount + int(float(params.along_amount_per_unit) * parent_length)
	
	if amount > 0:
		var k_along_jitter := 0.5 * params.along_jitter \
			* (params.along_end_ratio - params.along_begin_ratio) / float(amount)
		
		var a_jitter := 0.5 * params.around_jitter / float(params.around_amount)
		var half_pi := PI * 0.5
		
		for i in amount:
			var k : float = lerp(params.along_begin_ratio, params.along_end_ratio, 
				float(i) / float(amount))

			k += rng.randf_range(-k_along_jitter, k_along_jitter)

			var pos := Vector3(0, k, 0)
			
			for j in params.around_amount:
				if rng.randf() < params.skip_probability:
					continue
				
				# TODO Can't type hint this one for reasons that escape me
				var v_angle = params.vertical_angle + \
					params.vertical_angle_jitter * rng.randf_range(-half_pi, half_pi)
				var basis := Basis().rotated(Vector3(1, 0, 0), v_angle)
				
				var af := float(j) / float(params.around_amount)
				af += rng.randf_range(-a_jitter, a_jitter)
				basis = basis.rotated(Vector3(0, 1, 0), af * TAU + params.around_offset)
				
				transforms.append(Transform(basis, pos))
	
	return transforms


static func scale_path(transforms: Array, s: float):
	for i in len(transforms):
		var t = transforms[i]
		t.origin = t.origin * s
		transforms[i] = t


static func calc_length(transforms: Array) -> float:
	var length = 0.0
	for i in range(1, len(transforms)):
		length += transforms[i - 1].origin.distance_to(transforms[i].origin)
	return length


static func calc_orientations(transforms: Array, segment_length: float):
	for i in len(transforms):
		var trans : Transform = transforms[i]
		
		var prev_trans : Transform
		if i > 0:
			prev_trans = transforms[i - 1]
		else:
			prev_trans = trans
			prev_trans.origin -= trans.basis.y * segment_length
		
		var next_trans : Transform
		if i + 1 < len(transforms):
			next_trans = transforms[i + 1]
		else:
			next_trans = transforms[i]
			next_trans.origin += prev_trans.basis.y * segment_length
		
		var u0 := trans.origin - prev_trans.origin
		var u1 := next_trans.origin - trans.origin
		var u := (u0 + u1).normalized()
		
		var a := u.cross(prev_trans.basis.y).normalized()
		if a != Vector3():
			trans.basis = prev_trans.basis.rotated(a, -prev_trans.basis.y.angle_to(u))
		else:
			trans.basis = prev_trans.basis
		transforms[i] = trans
