extends Camera3D

const lin_move_speed: float = 300
const boost_mult: float = 10
const rot_move_speed: float = 0.15

var reference_offset: Vector3
@onready var UI: Control = $"../UI"

func apply_cam_inputs(lin_move_v: Vector3, ang_move_v: Vector3) -> void:
	position += lin_move_v
	rotate(basis.y, ang_move_v.x)
	rotate(basis.x, ang_move_v.y)
	rotate(basis.z, ang_move_v.z)
	
	position += Global.reference_frame.position - reference_offset
	reference_offset = Global.reference_frame.position

func get_vel() -> Vector3:
	return Vector3.ZERO
