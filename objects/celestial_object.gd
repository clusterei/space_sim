extends RigidBody3D
class_name celestial_object

@export var surface_radius: float

func _physics_process(_delta: float) -> void:
	apply_central_force(Global.get_gravity_accel(position) * mass)
