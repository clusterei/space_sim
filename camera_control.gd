extends Camera3D

@onready var reference_frame: RigidBody3D = $"../star"
@onready var reference_offset: Vector3 = reference_frame.position
var mouse_movement_tracking := Vector2.ZERO

var lin_move_speed: float = 100
var rot_move_speed: float = 0.15

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func change_reference_frame(new: RigidBody3D) -> void:
	#if reference_frame == new: return
	reference_frame = new
	reference_offset = new.position

func _process(delta: float) -> void:
	do_cam_movement(delta)
	position += reference_frame.position - reference_offset
	reference_offset = reference_frame.position

func do_cam_movement(delta: float) -> void:
	var cam_basis = basis
	
	var lin_move_v := Vector3.ZERO
	if Input.is_action_pressed("forw"): lin_move_v -= cam_basis.z
	if Input.is_action_pressed("back"): lin_move_v += cam_basis.z
	if Input.is_action_pressed("up"): lin_move_v += cam_basis.y
	if Input.is_action_pressed("down"): lin_move_v -= cam_basis.y
	if Input.is_action_pressed("right"): lin_move_v += cam_basis.x
	if Input.is_action_pressed("left"): lin_move_v -= cam_basis.x
	position += lin_move_v * lin_move_speed * delta
	
	var ang_move_v := Vector3.ZERO
	ang_move_v.x = mouse_movement_tracking.x
	ang_move_v.y = mouse_movement_tracking.y
	mouse_movement_tracking = Vector2.ZERO
	if Input.is_action_pressed("Lroll"): ang_move_v.z += 10
	if Input.is_action_pressed("Rroll"): ang_move_v.z -= 10
	ang_move_v *= rot_move_speed * delta
	rotate(basis.y, ang_move_v.x)
	rotate(basis.x, ang_move_v.y)
	rotate(basis.z, ang_move_v.z)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		mouse_movement_tracking = - event.relative
