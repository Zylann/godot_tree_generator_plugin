tool

#static func randomize_vector(v, amount):
#	return v + amount * Vector3(rand_range(-1,1), rand_range(-1,1), rand_range(-1,1))

static func randomize_quat(q, amount):
	# TODO I'm sure there is a simpler way
	var random_axis = Vector3(rand_range(-1,1), rand_range(-1,1), rand_range(-1,1)).normalized()
	return q * Quat(random_axis, rand_range(-PI, PI) * amount)


# Stolen from https://stackoverflow.com/questions/12435671/quaternion-lookat-function
static func Quat_look_at(look_dir, up=Vector3(0,1,0)):
	var world_forward = Vector3(0,0,-1)
	var dot = world_forward.dot(look_dir)
	if abs(dot - (-1.0)) < 0.00001:
		return Quat(up.x, up.y, up.z, PI)
	if abs(dot - 1.0) < 0.00001:
		return Quat()
	var rot_angle = acos(dot)
	var rot_axis = world_forward.cross(look_dir).normalized()
	return Quat(rot_axis, rot_angle)


static func calculate_normals(positions, indices):
	var out_normals = PoolVector3Array()
	
	var tcounts = []
	tcounts.resize(positions.size())
	out_normals.resize(positions.size())
	
	for i in range(0, tcounts.size()):
		tcounts[i] = 0
	
	var tri_count = indices.size() / 3
	
	var i = 0
	while i < indices.size():
		
		var i0 = indices[i]
		var i1 = indices[i+1]
		var i2 = indices[i+2]
		i += 3
		
		# TODO does triangle area matter?
		# If it does then we don't need to normalize in triangle calculation since it will account for its length
		var n = get_triangle_normal(positions[i0], positions[i1], positions[i2])
		
		out_normals[i0] += n
		out_normals[i1] += n
		out_normals[i2] += n
		
		tcounts[i0] += 1
		tcounts[i1] += 1
		tcounts[i2] += 1
	
	for j in range(out_normals.size()):
		out_normals[j] = (out_normals[j] / float(tcounts[j])).normalized()
	#print("DDD ", out_normals.size())
	return out_normals


static func get_triangle_normal(a, b, c):
	var u = (a - b).normalized()
	var v = (a - c).normalized()
	return v.cross(u)


