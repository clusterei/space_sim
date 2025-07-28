extends Control

@onready var focus_circle: Sprite2D = $focus_circle
@onready var potential_focus_circle: Sprite2D = $potential_focus_circle
@onready var focus_arrow: Sprite2D = $focus_arrow
@onready var time_label: Label = $VBoxContainer/timespeed
@onready var gravity_label: Label = $VBoxContainer/gravaccel
@onready var distance_label: Label = $VBoxContainer/tardist
@onready var relspeed_label: Label = $VBoxContainer/tarrelvel
@onready var screensize: Vector2 = get_viewport_rect().size
@onready var camera_list: Array[Camera3D] = [$"../freecam", $"../noncel_testobj/Camera3D"]
var mouse_movement_tracking := Vector2.ZERO
var target_obj: celestial_object = null
var previous_tar_d: float
var potential_target_obj: celestial_object = null

func _ready() -> void:
	get_viewport().size_changed.connect(update_screensize)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	change_reference_frame($"../star")

func update_screensize() -> void:
	screensize = get_viewport_rect().size

func _process(delta: float) -> void:
	update_target_obj_indicators()
	
	if Input.is_action_just_pressed("make_tar_obj_ref_frame") and target_obj != null:
		change_reference_frame(target_obj)
	
	if Input.is_action_just_pressed("time_down"): Global.change_game_speed(Engine.time_scale / 2.)
	if Input.is_action_just_pressed("time_up"): Global.change_game_speed(Engine.time_scale * 2.)
	var time_scale := Engine.time_scale
	time_label.visible = time_scale != 1.
	time_label.text = "t: " + str(Engine.time_scale)
	
	if Input.is_action_just_pressed("switch_cam"):
		camera_list.reverse()
		camera_list[0].current = true
		camera_list[1].current = false
	
	var vectors := get_cam_move_inputs(delta / Engine.time_scale)
	if Input.is_action_pressed("boost"): vectors[0] *= camera_list[0].boost_mult
	camera_list[0].apply_cam_inputs(vectors[0], vectors[1])
	
	var has_tar := target_obj != null
	gravity_label.visible = has_tar
	distance_label.visible = has_tar
	relspeed_label.visible = has_tar
	if has_tar:
		var cam_pos: Vector3 = camera_list[0].global_position
		var diff_to_tar := target_obj.global_position - cam_pos
		var d_to_tar := diff_to_tar.length()
		var tar_dir := diff_to_tar / d_to_tar
		
		distance_label.text = "d_surf: " + str(round_by(d_to_tar - target_obj.surface_radius, 2))
		
		var tar_obj_d_change = (previous_tar_d - d_to_tar) / time_scale
		previous_tar_d = d_to_tar
		relspeed_label.text = "v_rel: " + str(round_by(tar_obj_d_change, 2))
		
		var grav_accel := Global.get_gravity_accel(cam_pos)
		var accel_in_tar_dir: float = (grav_accel * tar_dir).maxf(0).length()
		gravity_label.text = "g_tar: " + str(round_by(accel_in_tar_dir, 2))

func round_by(value: float, by: int) -> float:
	var offset: float = pow(10, by)
	return roundf(value * offset) / offset

func update_target_obj_indicators() -> void:
	var camera := camera_list[0]
	potential_target_obj = Global.get_target_celestial_object(camera.global_position, - camera.global_basis.z)
	if potential_target_obj == target_obj: potential_target_obj = null
	var has_potential_target: bool = potential_target_obj != null
	potential_focus_circle.visible = has_potential_target
	if has_potential_target:
		potential_focus_circle.position = camera.unproject_position(potential_target_obj.position)
	
	if target_obj == null: 
		focus_circle.visible = false
		focus_arrow.visible = false
	else:
		var screen_tar_pos: Vector2 = camera.unproject_position(target_obj.position)
		var in_frustrum: bool = camera.is_position_in_frustum(target_obj.position)
		focus_circle.visible = in_frustrum
		focus_arrow.visible = not in_frustrum
		if in_frustrum:
			focus_circle.position = screen_tar_pos
		else:
			var arrow_dir: Vector2 = screen_tar_pos - screensize / 2#not normalized because not necessary here
			if camera.is_position_behind(target_obj.position):
				arrow_dir *= -1
				screen_tar_pos = screensize / 2 + arrow_dir.normalized() * screensize.length() / 2
			focus_arrow.rotation = arrow_dir.angle()
			focus_arrow.position = screen_tar_pos.clamp(Vector2.ZERO, screensize)
			######determine dir using angle between camera dir and tar pos instead of projection and intersect with screenedge instead of clamping
	
	#########label d and rel vel to tar

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		target_obj = potential_target_obj
		if target_obj != null:
			previous_tar_d = (target_obj.global_position - camera_list[0].global_position).length()
	elif event is InputEventMouseMotion:
		mouse_movement_tracking = - event.relative

func get_cam_move_inputs(delta: float) -> PackedVector3Array:
	var cam_basis = camera_list[0].global_basis
	
	var lin_move_v := Vector3.ZERO
	if Input.is_action_pressed("forw"): lin_move_v -= cam_basis.z
	if Input.is_action_pressed("back"): lin_move_v += cam_basis.z
	if Input.is_action_pressed("up"): lin_move_v += cam_basis.y
	if Input.is_action_pressed("down"): lin_move_v -= cam_basis.y
	if Input.is_action_pressed("right"): lin_move_v += cam_basis.x
	if Input.is_action_pressed("left"): lin_move_v -= cam_basis.x
	lin_move_v = lin_move_v.normalized()
	lin_move_v *= camera_list[0].lin_move_speed * delta
	
	var ang_move_v := Vector3.ZERO
	ang_move_v.x = mouse_movement_tracking.x
	ang_move_v.y = mouse_movement_tracking.y
	mouse_movement_tracking = Vector2.ZERO
	if Input.is_action_pressed("Lroll"): ang_move_v.z += 10
	if Input.is_action_pressed("Rroll"): ang_move_v.z -= 10
	ang_move_v *= camera_list[0].rot_move_speed * delta
	
	return PackedVector3Array([lin_move_v, ang_move_v])

func change_reference_frame(new: celestial_object) -> void:
	#if Global.reference_frame == new: return
	if Global.reference_frame != null:
		Global.reference_frame.get_node("path").visible = true
	new.get_node("path").visible = false
	Global.reference_frame = new
	$"../freecam".reference_offset = new.position
	
	####quick hack; #####reset all paths including noncel. obj.
	for cl_obj in get_tree().get_nodes_in_group("celestial_objects"):
		cl_obj.init_path()
