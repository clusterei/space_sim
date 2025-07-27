extends Node

const grav_constant: float = 0.02
var previous_game_speed: float = Engine.time_scale
@onready var cel_objects := get_tree().get_nodes_in_group("celestial_objects")####dont have group and make manually or detect group updates automatically

func get_gravity_accel(pos: Vector3) -> Vector3:
	var accel := Vector3.ZERO
	for c_object in cel_objects:
		var diff: Vector3 = c_object.position - pos
		var d: float = diff.length()
		if d == 0.: continue
		var subsurface_mod: float = min(d / c_object.surface_radius, 1.)
		var strength: float = grav_constant * c_object.mass / pow(d, 2) * subsurface_mod
		accel += diff / d * strength
	return accel

func get_target_celestial_object(pos: Vector3, dir: Vector3) -> celestial_object:
	var raycast_mode := true
	const angle_limit: float = deg_to_rad(10)
	
	var hit_obj = null
	var hit_obj_d: float = INF
	for cl_object in get_tree().get_nodes_in_group("celestial_objects"):
		var obj_pos: Vector3 = cl_object.position
		var closest_point_d: float = (obj_pos - pos).dot(dir)
		if raycast_mode:
			if closest_point_d > hit_obj_d or closest_point_d < 0.: continue
			var point_obj_d_sq: float = (pos + dir * closest_point_d - obj_pos).length_squared()
			if pow(cl_object.surface_radius, 2) >= point_obj_d_sq:
				hit_obj = cl_object
				hit_obj_d = closest_point_d
		else:
			####work inn progress
			var angle: float = abs(cos(closest_point_d))
			if angle <= angle_limit and angle <= hit_obj_d:
				hit_obj = cl_object
				hit_obj_d = angle
			
	return hit_obj

func change_game_speed(speed: float) -> void:
	Engine.time_scale = speed
	Engine.physics_ticks_per_second = int(max(speed, 1.) * ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))

func predict_paths() -> Array[PackedVector3Array]:#####work in progress
	var num_steps: int = 200
	var stepsize: float = 0.1
	#var ref_frame_obj_index: int = 0
	
	var num_objs: int = cel_objects.size()
	var path_arr_arr: Array[PackedVector3Array] = []
	var pos_arr := PackedVector3Array()
	var vel_arr := PackedVector3Array()
	var mass_arr := PackedFloat32Array()
	for obj in cel_objects:
		var path_arr := PackedVector3Array()
		path_arr.resize(num_steps)
		path_arr_arr.append(path_arr)
		pos_arr.append(obj.position)
		vel_arr.append(obj.linear_velocity)
		mass_arr.append(obj.mass)
	var new_pos_arr := PackedVector3Array()
	new_pos_arr.resize(num_objs)
	
	for i in num_steps:
		#var ref_frame_offset := pos_arr[ref_frame_obj_index]#to adjust for ref frame moving
		for j in num_objs:
			var accel := Vector3.ZERO
			var pos: Vector3 = pos_arr[j]
			path_arr_arr[j][i] = pos#updates path
			for k in num_objs:
				var diff: Vector3 = pos_arr[k] - pos
				var d: float = diff.length()
				if d == 0.: continue
				var strength: float = grav_constant * mass_arr[k] / pow(d, 2)
				accel += diff / d * strength
			vel_arr[j] += accel * stepsize
			new_pos_arr[j] = pos + vel_arr[j] * stepsize# - ref_frame_offset
		pos_arr = new_pos_arr.duplicate()
	
	return path_arr_arr
