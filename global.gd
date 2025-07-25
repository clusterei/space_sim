extends Node

const grav_constant: float = 1

func get_gravity_accel(pos: Vector3) -> Vector3:
	var accel := Vector3.ZERO
	for object in get_tree().get_nodes_in_group("celestial_objects"):
		var diff: Vector3 = object.position - pos
		var d: float = diff.length()
		if d == 0.: continue
		var strength: float = grav_constant * object.mass / pow(d, 2)
		accel += diff / d * strength
	return accel
