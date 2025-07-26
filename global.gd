extends Node

const grav_constant: float = 0.02

func get_gravity_accel(pos: Vector3) -> Vector3:
	var accel := Vector3.ZERO
	for c_object in get_tree().get_nodes_in_group("celestial_objects"):
		var diff: Vector3 = c_object.position - pos
		var d: float = diff.length()
		if d == 0.: continue
		var subsurface_mod: float = min(d / c_object.surface_radius, 1.)
		var strength: float = grav_constant * c_object.mass / pow(d, 2) * subsurface_mod
		#####reduce strength the deeper below surfice one is
		accel += diff / d * strength
	return accel
