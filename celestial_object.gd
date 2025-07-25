extends RigidBody3D

func _physics_process(_delta: float) -> void:
	apply_central_force(Global.get_gravity_accel(position) * mass)
