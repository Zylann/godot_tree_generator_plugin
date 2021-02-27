#include "tg_tree.h"
#include <gen/Mesh.hpp>
#include <gen/OpenSimplexNoise.hpp>
#include <gen/RandomNumberGenerator.hpp>

template <typename T>
T max(T a, T b) {
	return a > b ? a : b;
}

godot::PoolVector3Array to_pool_array(const std::vector<godot::Vector3> &src) {
	godot::PoolVector3Array dst;
	dst.resize(static_cast<int>(src.size()));
	{
		godot::PoolVector3Array::Write w = dst.write();
		memcpy(w.ptr(), src.data(), src.size() * sizeof(godot::Vector3));
	}
	return dst;
}

godot::PoolIntArray to_pool_array(const std::vector<int> &src) {
	godot::PoolIntArray dst;
	dst.resize(static_cast<int>(src.size()));
	{
		godot::PoolIntArray::Write w = dst.write();
		memcpy(w.ptr(), src.data(), src.size() * sizeof(int));
	}
	return dst;
}

static godot::Transform interpolate_path(const std::vector<godot::Transform> transforms,
		const std::vector<float> &distances, float offset) {

	TG_CRASH_COND(transforms.size() == 0);
	TG_CRASH_COND(transforms.size() != distances.size());

	if (offset <= 0.f) {
		return transforms[0];
	}

	for (size_t i = 0; i < distances.size(); ++i) {
		if (distances[i] > offset) {
			continue;
		}
		TG_CRASH_COND(i <= 0);
		const godot::Transform &prev_trans = transforms[i - 1];
		const godot::Transform &trans = transforms[i];
		const float prev_d = distances[i];
		const float d = distances[i];
		const float t = (d - prev_d) / offset;
		return prev_trans.interpolate_with(trans, t);
	}

	return transforms.back();
}

static float calc_length(const std::vector<godot::Transform> &transforms) {
	float length = 0.0f;
	for (size_t i = 1; i < transforms.size(); ++i) {
		length += transforms[i - 1].origin.distance_to(transforms[i].origin);
	}
	return length;
}

static void scale_path(std::vector<godot::Transform> &transforms, const float scale) {
	for (size_t i = 0; i < transforms.size(); ++i) {
		godot::Transform &t = transforms[i];
		t.origin = t.origin * scale;
	}
}

static void calc_orientations(std::vector<godot::Transform> &transforms, const float segment_length) {
	for (size_t i = 0; i < transforms.size(); ++i) {
		godot::Transform &trans = transforms[i];

		godot::Transform prev_trans;
		if (i > 0) {
			prev_trans = transforms[i - 1];
		} else {
			prev_trans = trans;
			prev_trans.origin -= trans.basis.y * segment_length;
		}

		godot::Transform next_trans;
		if (i + 1 < transforms.size()) {
			next_trans = transforms[i + 1];
		} else {
			next_trans = transforms[i];
			next_trans.origin += prev_trans.basis.y * segment_length;
		}

		const godot::Vector3 u0 = trans.origin - prev_trans.origin;
		const godot::Vector3 u1 = next_trans.origin - trans.origin;
		const godot::Vector3 u = (u0 + u1).normalized();

		const godot::Vector3 a = u.cross(prev_trans.basis.y).normalized();
		if (a != godot::Vector3()) {
			trans.basis = prev_trans.basis.rotated(a, -prev_trans.basis.y.angle_to(u));
		} else {
			trans.basis = prev_trans.basis;
		}
	}
}

static void add_quad_indices(std::vector<int> &indices, int i0, int i1, int i2, int i3) {
	//  --2---3--
	//    |  /|
	//    | / |
	//    |/  |
	//  --0---1--

	indices.push_back(i0);
	indices.push_back(i3);
	indices.push_back(i1);

	indices.push_back(i0);
	indices.push_back(i2);
	indices.push_back(i3);
}

static void connect_rings_with_same_point_count(std::vector<int> &indices, int prev_ring_begin, int point_count) {
	int i0 = prev_ring_begin;
	int i1 = prev_ring_begin + 1;
	int i2 = prev_ring_begin + point_count;
	int i3 = prev_ring_begin + point_count + 1;

	for (int i = 1; i < point_count; ++i) {
		add_quad_indices(indices, i0, i1, i2, i3);
		++i0;
		++i1;
		++i2;
		++i3;
	}

	// Last quad closes the loop
	i1 = prev_ring_begin;
	i3 = prev_ring_begin + point_count;
	add_quad_indices(indices, i0, i1, i2, i3);
}

static void connect_rings_with_different_point_count(std::vector<int> &indices,
		int prev_ring_begin, int prev_point_count, int next_ring_begin, int next_point_count) {

	// Assumes rings have evenly sparsed points and their starting point is aligned.
	// If not then it would require an implementation that finds the closest points.

	// Could have symetrical functions... but harder to maintain

	bool flip_winding = false;
	if (prev_point_count < next_point_count) {
		std::swap(prev_ring_begin, next_ring_begin);
		std::swap(prev_point_count, next_point_count);
		flip_winding = true;
	}

	TG_CRASH_COND(prev_point_count <= next_point_count);

	const float k = static_cast<float>(next_point_count) / static_cast<float>(prev_point_count);
	float c = 0.f;

	const int min_dst_i = next_ring_begin;
	const int max_dst_i = next_ring_begin + next_point_count;

	const int min_src_i = prev_ring_begin;
	const int max_src_i = prev_ring_begin + prev_point_count;

	int src_i = prev_ring_begin;
	int dst_i = next_ring_begin;

	const size_t added_indices_begin = indices.size();

	for (int i = 0; i < prev_point_count; ++i) {
		int prev_src_i = src_i;
		++src_i;
		if (src_i == max_src_i) {
			src_i = min_src_i;
		}
		indices.push_back(prev_src_i);
		indices.push_back(dst_i);
		indices.push_back(src_i);
		c += k;
		if (c >= 0.5f) {
			c -= 1.0;
			int prev_dst_i = dst_i;
			++dst_i;
			if (dst_i == max_dst_i) {
				dst_i = min_dst_i;
			}
			indices.push_back(src_i);
			indices.push_back(prev_dst_i);
			indices.push_back(dst_i);
		}
	}

	if (flip_winding) {
		for (size_t i = added_indices_begin; i < indices.size(); i += 3) {
			std::swap(indices[i], indices[i + 1]);
		}
	}
}

static void add_cap(std::vector<godot::Vector3> &positions, std::vector<godot::Vector3> &normals,
		std::vector<int> &indices, const godot::Transform &trans, int point_count, bool flat) {

	TG_CRASH_COND(point_count < 0);

	if (flat) {
		int i0 = static_cast<int>(positions.size()) - point_count;
		for (int pi = 0; pi < point_count; ++pi) {
			const godot::Vector3 p = positions[i0 + pi];
			positions.push_back(p);
			normals.push_back(trans.basis.y);
		}
	}

	positions.push_back(trans.origin);
	normals.push_back(trans.basis.y);

	int ib = static_cast<int>(positions.size()) - point_count - 1;
	int ie = static_cast<int>(positions.size()) - 1;

	int i0 = ib;

	for (int i = 1; i < point_count; ++i) {
		indices.push_back(i0);
		++i0;
		indices.push_back(ie);
		indices.push_back(i0);
	}

	indices.push_back(i0);
	indices.push_back(ie);
	indices.push_back(ib);
}

static godot::Array generate_path_mesh(const std::vector<godot::Transform> &transforms, const std::vector<float> &radii,
		float mesh_divisions_per_unit, bool end_cap_flat) {

	TG_CRASH_COND(transforms.size() != radii.size());

	std::vector<godot::Vector3> vertices;
	std::vector<godot::Vector3> normals;
	std::vector<int> indices;

	int previous_ring_point_count = 0;

	// TODO Path shape
	// TODO Path welding

	for (size_t transform_index = 0; transform_index < transforms.size(); ++transform_index) {
		const godot::Transform &trans = transforms[transform_index];
		const float r = radii[transform_index];
		const float circumference = static_cast<float>(Math_TAU) * r;
		const int point_count = max(static_cast<int>(circumference * mesh_divisions_per_unit), 3);
		//const int point_count = 8;

		for (int pi = 0; pi < point_count; ++pi) {
			const float a = static_cast<float>(Math_TAU) * static_cast<float>(pi) / static_cast<float>(point_count);
			const godot::Vector3 normal = trans.basis.x.rotated(trans.basis.y, a);
			const godot::Vector3 pos = trans.origin + r * normal;
			vertices.push_back(pos);
			normals.push_back(normal);
		}

		if (transform_index > 0) {
			// Connect to previous ring
			if (point_count == previous_ring_point_count) {
				const int prev_ring_begin = static_cast<int>(vertices.size()) - 2 * point_count;
				connect_rings_with_same_point_count(indices, prev_ring_begin, point_count);

			} else {
				const int ring_begin = static_cast<int>(vertices.size()) - point_count;
				const int prev_ring_begin = ring_begin - previous_ring_point_count;
				connect_rings_with_different_point_count(indices,
						prev_ring_begin, previous_ring_point_count,
						ring_begin, point_count);
			}
		}

		previous_ring_point_count = point_count;
	}

	add_cap(vertices, normals, indices, transforms.back(), previous_ring_point_count, end_cap_flat);

	godot::Array arrays;
	arrays.resize(godot::Mesh::ARRAY_MAX);
	arrays[godot::Mesh::ARRAY_VERTEX] = to_pool_array(vertices);
	arrays[godot::Mesh::ARRAY_NORMAL] = to_pool_array(normals);
	arrays[godot::Mesh::ARRAY_INDEX] = to_pool_array(indices);
	// TODO Tangents
	return arrays;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void TG_Tree::_init() {
}

int TG_Tree::get_global_seed() const {
	return _global_seed;
}

void TG_Tree::set_global_seed(int p_seed) {
	_global_seed = p_seed;
}

float TG_Tree::get_mesh_divisions_per_unit() const {
	return _mesh_divisions_per_unit;
}

void TG_Tree::set_mesh_divisions_per_unit(float d) {
	_mesh_divisions_per_unit = d;
}

float TG_Tree::get_branch_segments_per_unit() const {
	return _branch_segments_per_unit;
}

void TG_Tree::set_branch_segments_per_unit(float b) {
	_branch_segments_per_unit = b;
}

godot::Ref<TG_Node> TG_Tree::get_root_node() const {
	return _root_node;
}

void TG_Tree::set_root_node(godot::Ref<TG_Node> node) {
	_root_node = node;
}

godot::Ref<TG_NodeInstance> TG_Tree::get_root_node_instance() const {
	return _root_instance;
}

void TG_Tree::generate() {
	ERR_FAIL_COND(_root_node.is_null());
	_root_instance.instance();
	godot::Ref<godot::RandomNumberGenerator> rng;
	rng.instance();
	rng->set_seed(_global_seed + _root_node->get_local_seed());
	process_node(**_root_node, **_root_instance, godot::Vector3(0, 1, 0), **rng);
}

void TG_Tree::process_node(const TG_Node &node, TG_NodeInstance &node_instance, godot::Vector3 sun_dir_local,
		godot::RandomNumberGenerator &rng) {

	if (node.get_type() == TG_Node::TYPE_BRANCH) {
		generate_node_path(node, node_instance, sun_dir_local, rng);
	}

	if (node.get_child_count() == 0) {
		return;
	}

	const float path_length = node_instance.path_distances.back();
	std::vector<SpawnInfo> spawns;

	// Process children
	for (int i = 0; i < node.get_child_count(); ++i) {
		const TG_Node &child = node.get_child_internal(i);

		godot::Ref<godot::RandomNumberGenerator> child_rng;
		child_rng.instance();
		child_rng->set_seed(_global_seed + child.get_local_seed());

		generate_spawns(spawns, child.get_spawn_params(), **child_rng, path_length);

		for (size_t j = 0; j < spawns.size(); ++j) {
			const SpawnInfo &spawn_info = spawns[j];
			const float offset = spawn_info.offset_ratio * path_length;
			// TODO Sample parent radius and offset child accordingly
			const godot::Transform path_trans = interpolate_path(
					node_instance.path, node_instance.path_distances, offset);

			godot::Ref<TG_NodeInstance> child_node_instance;
			child_node_instance.instance();
			child_node_instance->offset_ratio = spawn_info.offset_ratio;
			child_node_instance->local_transform =
					godot::Transform(path_trans.basis * spawn_info.basis, path_trans.origin);

			process_node(child, **child_node_instance,
					child_node_instance->local_transform.basis.inverse().xform(sun_dir_local), **child_rng);

			node_instance.children.push_back(child_node_instance);
		}
	}
}

void TG_Tree::generate_node_path(const TG_Node &node, TG_NodeInstance &node_instance, godot::Vector3 sun_dir_local,
		godot::RandomNumberGenerator &rng) {

	const TG_SpawnParams &spawn_params = node.get_spawn_params();

	const float relative_offset_ratio =
			(node_instance.offset_ratio - spawn_params.along_begin_ratio) /
			(spawn_params.along_end_ratio - spawn_params.along_begin_ratio);

	const TG_PathParams &path_params = node.get_path_params();

	// Calculate expected length

	float length_with_modifiers = path_params.length;
	if (path_params.length_curve_along_parent.is_valid()) {
		godot::Ref<godot::Curve> curve = path_params.length_curve_along_parent;
		length_with_modifiers *= curve->interpolate_baked(relative_offset_ratio);
	}
	length_with_modifiers += path_params.length_randomness * rng.randf_range(-1.0, 1.0) * length_with_modifiers;

	float radius_multiplier = 1.0;
	if (path_params.radius_curve_along_parent.is_valid()) {
		godot::Ref<godot::Curve> curve = path_params.radius_curve_along_parent;
		radius_multiplier *= curve->interpolate_baked(relative_offset_ratio);
	}

	const int point_count = max(static_cast<int>(_branch_segments_per_unit * length_with_modifiers), 2);
	const float segment_length = 1.0f / _branch_segments_per_unit;

	godot::Basis sun_basis;

	std::vector<godot::Transform> &path = node_instance.path;
	std::vector<float> &radii = node_instance.path_radii;
	path.clear();
	radii.clear();

	const float distance_step = length_with_modifiers / point_count;

	// Plot base points

	godot::Transform trans;

	for (int i = 0; i < point_count; ++i) {
		const float k = static_cast<float>(i) / point_count;

		const float r = godot::Math::lerp(
								path_params.begin_radius,
								path_params.end_radius,
								pow(k, path_params.radius_curve)) *
						radius_multiplier;

		radii.push_back(r);
		path.push_back(trans);

		if (path_params.seek_sun != 0.f) {
			const float seek_sun = path_params.seek_sun / _branch_segments_per_unit;
			const godot::Vector3 tend_dir = sun_dir_local * godot::Math::sign(seek_sun);
			const float a = godot::Math::sign(seek_sun) * trans.basis.y.angle_to(tend_dir);
			if (fabs(a) > 0.001f) {
				godot::Vector3 axis = trans.basis.y.cross(tend_dir).normalized();
				trans.basis = trans.basis.rotated(axis, a * seek_sun);
			}
		}

		trans.origin += distance_step * trans.basis.y;
	}

	// Apply noise
	if (path_params.noise_amplitude != 0.f) {
		godot::Ref<godot::OpenSimplexNoise> noise_x;
		godot::Ref<godot::OpenSimplexNoise> noise_y;
		godot::Ref<godot::OpenSimplexNoise> noise_z;

		noise_x.instance();
		noise_x->set_seed(_global_seed + node.get_local_seed());
		noise_x->set_octaves(path_params.noise_octaves);
		noise_x->set_period(path_params.noise_period);

		noise_y.instance();
		noise_y->set_seed(_global_seed + node.get_local_seed() + 1);
		noise_y->set_octaves(path_params.noise_octaves);
		noise_y->set_period(path_params.noise_period);

		noise_z.instance();
		noise_z->set_seed(_global_seed + node.get_local_seed() + 2);
		noise_z->set_octaves(path_params.noise_octaves);
		noise_z->set_period(path_params.noise_period);

		for (int i = 0; i < point_count; ++i) {
			const float k = static_cast<float>(i) / point_count;
			godot::Transform &trans = path[i];
			const float amp = path_params.noise_amplitude * pow(k, path_params.noise_curve);
			const godot::Vector3 disp =
					amp * godot::Vector3(
								  noise_x->get_noise_3dv(trans.origin),
								  noise_y->get_noise_3dv(trans.origin),
								  noise_z->get_noise_3dv(trans.origin));
			trans.origin += disp;
		}
	}

	// Renormalize length
	const float length = calc_length(path);
	if (length > 0.0f) {
		const float rscale = length_with_modifiers / length;
		scale_path(path, rscale);
	}

	// TODO Optimize path so straight parts have less points

	// Bake distances
	std::vector<float> &distances = node_instance.path_distances;
	distances.clear();
	distances.push_back(0);
	for (size_t i = 1; i < path.size(); ++i) {
		distances.push_back(distances[i - 1] + path[i].origin.distance_to(path[i - 1].origin));
	}

	// Recalculate orientations after modifiers
	calc_orientations(path, segment_length);

	godot::Array mesh = generate_path_mesh(path, radii, _mesh_divisions_per_unit, path_params.end_cap_flat);
	node_instance.surfaces = mesh;
}

void TG_Tree::generate_spawns(std::vector<SpawnInfo> &transforms, const TG_SpawnParams &params,
		godot::RandomNumberGenerator &rng, float parent_length) {

	transforms.clear();

	const int amount = params.along_base_amount + static_cast<int>(params.along_amount_per_unit * parent_length);

	if (amount == 0) {
		return;
	}

	const float k_along_jitter = 0.5f * params.along_jitter *
								 (params.along_end_ratio - params.along_begin_ratio) / static_cast<float>(amount);

	const float a_jitter = 0.5f * params.around_jitter / static_cast<float>(params.around_amount);
	const float half_pi = static_cast<float>(Math_PI) * 0.5f;

	for (int i = 0; i < amount; ++i) {
		float k = godot::Math::lerp(params.along_begin_ratio, params.along_end_ratio,
				static_cast<float>(i) / static_cast<float>(amount));

		k += rng.randf_range(-k_along_jitter, k_along_jitter);

		for (int j = 0; j < params.around_amount; ++j) {
			if (rng.randf() < params.skip_probability) {
				continue;
			}

			const float v_angle = params.vertical_angle +
								  params.vertical_angle_jitter * rng.randf_range(-half_pi, half_pi);

			godot::Basis basis = godot::Basis().rotated(godot::Vector3(1, 0, 0), v_angle);

			float af = static_cast<float>(j) / static_cast<float>(params.around_amount);
			af += rng.randf_range(-a_jitter, a_jitter);

			basis = basis.rotated(godot::Vector3(0, 1, 0), af * static_cast<float>(Math_TAU) + params.around_offset);

			SpawnInfo si;
			si.basis = basis;
			si.offset_ratio = k;
			transforms.push_back(si);
		}
	}
}

void TG_Tree::_register_methods() {
	godot::register_method("set_global_seed", &TG_Tree::set_global_seed);
	godot::register_method("get_global_seed", &TG_Tree::get_global_seed);

	godot::register_method("get_mesh_divisions_per_unit", &TG_Tree::get_mesh_divisions_per_unit);
	godot::register_method("set_mesh_divisions_per_unit", &TG_Tree::set_mesh_divisions_per_unit);

	godot::register_method("get_branch_segments_per_unit", &TG_Tree::get_branch_segments_per_unit);
	godot::register_method("set_branch_segments_per_unit", &TG_Tree::set_branch_segments_per_unit);

	godot::register_method("get_root_node", &TG_Tree::get_root_node);
	godot::register_method("set_root_node", &TG_Tree::set_root_node);

	godot::register_method("get_root_node_instance", &TG_Tree::get_root_node_instance);

	godot::register_method("generate", &TG_Tree::generate);
}
