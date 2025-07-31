extends Control

@onready var focus_circle: Sprite2D = $focus_circle
@onready var arrow1: Line2D = $arrow1
@onready var arrow2: Line2D = $arrow2
@onready var potential_focus_circle: Sprite2D = $potential_focus_circle
@onready var focus_arrow: Sprite2D = $focus_arrow
@onready var time_label: Label = $VBoxContainer/timespeed
@onready var gamespeed_label: Label = $VBoxContainer/gamespeed
@onready var tarname: Label = $VBoxContainer/tarname
@onready var gravity_label: Label = $VBoxContainer/gravaccel
@onready var distance_label: Label = $VBoxContainer/tardist
@onready var relspeed_label: Label = $VBoxContainer/tarrelvel
@onready var screensize: Vector2 = get_viewport_rect().size
@onready var camera_list: Array[Camera3D] = [$"../freecam", $"../noncel_testobj/Camera3D"]
@onready var navball_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/navball/ball
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
	update_ui_labels(delta)
	navball_mesh.basis = camera_list[0].global_basis.inverse()
	
	if Input.is_action_just_pressed("make_tar_obj_ref_frame") and target_obj != null:
		change_reference_frame(target_obj)
	if Input.is_action_just_pressed("time_down"): Global.change_game_speed(Engine.time_scale / 2.)
	if Input.is_action_just_pressed("time_up"): Global.change_game_speed(Engine.time_scale * 2.)
	if Input.is_action_just_pressed("switch_cam"):
		camera_list.reverse()
		camera_list[0].current = true
		camera_list[1].current = false
	
	var vectors := get_cam_move_inputs(delta / Engine.time_scale)
	camera_list[0].apply_cam_inputs(vectors[0], vectors[1])

func update_ui_labels(delta: float) -> void:
	var has_tar := target_obj != null
	gravity_label.visible = has_tar####make one vbox to address at once
	distance_label.visible = has_tar
	relspeed_label.visible = has_tar
	tarname.visible = has_tar
	if has_tar:
		tarname.text = target_obj.name
		var cam_pos: Vector3 = camera_list[0].global_position
		var diff_to_tar := target_obj.global_position - cam_pos
		var d_to_tar := diff_to_tar.length()
		var tar_dir := diff_to_tar / d_to_tar
		
		distance_label.text = "d_surf: " + str(round_by(d_to_tar - target_obj.surface_radius, 2))
		
		var tar_obj_d_change = (previous_tar_d - d_to_tar) / Engine.time_scale
		previous_tar_d = d_to_tar
		relspeed_label.text = "v_rel: " + str(round_by(tar_obj_d_change, 2))
		
		var grav_accel := Global.get_gravity_accel(cam_pos)
		var accel_in_tar_dir: float = (grav_accel * tar_dir).maxf(0).length()
		gravity_label.text = "g_tar: " + str(round_by(accel_in_tar_dir, 2))
	
	time_label.visible = Engine.time_scale != 1.
	time_label.text = "t: " + str(Engine.time_scale)
	
	gamespeed_label.text = "gamespeed: " + str(round_by(Engine.time_scale / delta / ProjectSettings.get_setting("physics/common/physics_ticks_per_second"), 2))

func round_by(value: float, by: int) -> float:
	var offset: float = pow(10, by)
	return roundf(value * offset) / offset

func update_target_obj_indicators() -> void:
	var camera := camera_list[0]
	var cam_basis := camera.global_basis
	
	potential_target_obj = Global.get_target_celestial_object(camera.global_position, - cam_basis.z)
	if potential_target_obj == target_obj: potential_target_obj = null
	var has_potential_target: bool = potential_target_obj != null
	potential_focus_circle.visible = has_potential_target
	if has_potential_target:
		potential_focus_circle.position = camera.unproject_position(potential_target_obj.position)
		var circlesize: float = 3.
		circlesize *= potential_target_obj.surface_radius / (potential_target_obj.position - camera.global_position).length()
		circlesize = clampf(circlesize, 0.1, 0.5) * 1.3
		potential_focus_circle.scale = Vector2.ONE * circlesize
	
	if target_obj == null: 
		focus_circle.visible = false
		focus_arrow.visible = false
	else:
		var screen_tar_pos: Vector2 = camera.unproject_position(target_obj.position)
		var in_frustrum: bool = camera.is_position_in_frustum(target_obj.position)
		focus_circle.visible = in_frustrum
		focus_arrow.visible = not in_frustrum
		arrow1.visible = in_frustrum
		arrow2.visible = in_frustrum
		if in_frustrum:
			var diff_to_tar := target_obj.position - camera.global_position
			var d_to_tar := diff_to_tar.length()
			
			focus_circle.position = screen_tar_pos
			var circlesize: float = 3.
			circlesize *= target_obj.surface_radius / d_to_tar
			circlesize = clampf(circlesize, 0.1, 0.5)
			focus_circle.scale = Vector2.ONE * circlesize
			
			
			
			return##############################
			var vel_diff: Vector3 = camera.get_vel() - target_obj.linear_velocity
			var dir_v: Vector3 = diff_to_tar / d_to_tar
			var reduced_vel_diff := vel_diff * (Vector3.ONE - dir_v)
			var side_vel_vector := - Vector2(reduced_vel_diff.dot(dir_v.cross(cam_basis.y)), reduced_vel_diff.dot(dir_v.cross(cam_basis.x))) 
			#print(side_vel_vector)
			
			#var to_tar_basis: Basis = Basis(diff_to_tar, diff_to_tar.cross(cam_basis.x), Vector3.ONE).orthonormalized()#########better than cam basis??????????
			var arrowlengthscale: float = 10
			side_vel_vector *= arrowlengthscale
			
			#var vel_right: Vector3 = vel_diff * to_tar_basis.z
			#var vel_up: Vector3 = vel_diff * to_tar_basis.y
			#print(signf(vel_right.dot(cam_basis.x)), " ", signf(vel_right.dot(cam_basis.y)), " ", signf(vel_right.dot(cam_basis.z)))
			
			var length1: float = abs(side_vel_vector.x)#vel_right.length() * arrowlengthscale
			var length2: float = abs(side_vel_vector.y)#vel_up.length() * arrowlengthscale
			var dir2 := Vector2.UP * signf(side_vel_vector.x)# * signf(vel_up.dot(cam_basis.z))
			var dir1 := Vector2.LEFT * signf(side_vel_vector.y)############### * signf(vel_right.dot(cam_basis.z))
			set_arrow_points(arrow1, focus_circle.position + dir1 * circlesize * 450., dir1, length1)
			set_arrow_points(arrow2, focus_circle.position + dir2 * circlesize * 450., dir2, length2)
		else:
			var arrow_dir: Vector2 = screen_tar_pos - screensize / 2#not normalized because not necessary here
			if camera.is_position_behind(target_obj.position):
				arrow_dir *= -1
				screen_tar_pos = screensize / 2 + arrow_dir.normalized() * screensize.length() / 2
			focus_arrow.rotation = arrow_dir.angle()
			focus_arrow.position = screen_tar_pos.clamp(Vector2.ZERO, screensize)
			###determine dir using angle between camera dir and tar pos instead of projection and intersect with screenedge instead of clamping

func set_arrow_points(node: Line2D, start: Vector2, dir: Vector2, length: float) -> void:
	var end := start + dir * length
	node.clear_points()
	node.add_point(start)
	node.add_point(end)
	node.add_point(end - dir.rotated(deg_to_rad(30)) * 20.)
	node.add_point(end)
	node.add_point(end - dir.rotated(deg_to_rad(-30)) * 20.)

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
	if Input.is_action_pressed("match_velocity") and target_obj != null:
		lin_move_v += (target_obj.linear_velocity - camera_list[0].get_vel()) * 2.#*2 to counteract better
		lin_move_v = lin_move_v.normalized()
	lin_move_v *= camera_list[0].lin_move_speed * delta
	if Input.is_action_pressed("boost"): lin_move_v *= camera_list[0].boost_mult
	
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
