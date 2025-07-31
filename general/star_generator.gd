extends MultiMeshInstance3D

@export var num_stars: int
@export var min_d: float
@export var max_d: float

func _ready() -> void:
	multimesh.instance_count = num_stars
	
	for i in num_stars:
		var pos := random_direction() * randf_range(min_d, max_d)
		multimesh.set_instance_transform(i, Transform3D(Basis(), pos))

func random_direction() -> Vector3:#####test if correct
	var theta := randf() * TAU
	var phi := acos(2.0 * randf() - 1.0)
	var sin_phi := sin(phi)
	return Vector3(cos(theta) * sin_phi, sin(theta) * sin_phi, cos(phi))
