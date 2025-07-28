extends Camera3D

const lin_move_speed: float = 50
const boost_mult: float = 30
const rot_move_speed: float = 0.15

@onready var parent: RigidBody3D = $".."

func apply_cam_inputs(lin_move_v: Vector3, ang_move_v: Vector3) -> void:
	var auto_stabilisation := true
	#var auto_stabilisation_limit: float = 0.01##
	
	var time_scale := Engine.time_scale
	lin_move_v *= time_scale
	ang_move_v /= time_scale#compenating for slowdown for players sake
	
	parent.apply_central_impulse(lin_move_v)
	var p_basis := parent.global_basis
	parent.apply_torque_impulse(p_basis.y * ang_move_v.x)
	parent.apply_torque_impulse(p_basis.x * ang_move_v.y)
	parent.apply_torque_impulse(p_basis.z * ang_move_v.z)
	
	if auto_stabilisation:
		var ang_vel := (parent.angular_velocity / 10.)#.minf(auto_stabilisation_limit)
		var torque := Vector3(ang_vel.dot(p_basis.y), ang_vel.dot(p_basis.x), ang_vel.dot(p_basis.z))
		
		if ang_move_v.x == 0:
			parent.apply_torque_impulse(- p_basis.y * torque.x)
		if ang_move_v.y == 0:
			parent.apply_torque_impulse(- p_basis.x * torque.y)
		if ang_move_v.z == 0:
			parent.apply_torque_impulse(- p_basis.z * torque.z)
