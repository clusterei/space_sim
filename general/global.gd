extends Node

const grav_constant: float = 0.001
var previous_game_speed: float = Engine.time_scale
@onready var cel_objects := get_tree().get_nodes_in_group("celestial_objects")####dont have group and make manually or detect group updates automatically
var reference_frame: celestial_object

func get_gravity_accel(pos: Vector3) -> Vector3:
	var accel := Vector3.ZERO
	for c_object in cel_objects:
		var diff: Vector3 = c_object.position - pos
		var d_sqr: float = diff.length_squared()
		if d_sqr == 0.: continue
		var subsurface_mod: float = min(d_sqr / pow(c_object.surface_radius, 2), 1.)
		var strength: float = grav_constant * c_object.mass / d_sqr * subsurface_mod
		accel += diff / sqrt(d_sqr) * strength
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
	Engine.max_physics_steps_per_frame = int(max(speed, 1.)) * ProjectSettings.get_setting("physics/common/max_physics_steps_per_frame")
