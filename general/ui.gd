extends Control

@onready var camera: Camera3D = $".."
@onready var focus_circle: Sprite2D = $focus_circle
@onready var potential_focus_circle: Sprite2D = $potential_focus_circle
@onready var focus_arrow: Sprite2D = $focus_arrow
@onready var screensize: Vector2 = get_viewport_rect().size

var target_obj: celestial_object = null
var potential_target_obj: celestial_object = null

func _ready() -> void:
	get_viewport().size_changed.connect(update_screensize)

func update_screensize() -> void:
	screensize = get_viewport_rect().size

func _process(_delta: float) -> void:
	update_target_obj_indicators()
	
	if Input.is_action_just_pressed("make_tar_obj_ref_frame") and target_obj != null:
		$"..".change_reference_frame(target_obj)
	
	if Input.is_action_just_pressed("ui_left"): Global.change_game_speed(Engine.time_scale / 2.)
	if Input.is_action_just_pressed("ui_right"): Global.change_game_speed(Engine.time_scale * 2.)
	$timespeed.visible = Engine.time_scale != 1.
	$timespeed.text = str(Engine.time_scale)

func update_target_obj_indicators() -> void:
	potential_target_obj = Global.get_target_celestial_object(camera.position, - camera.basis.z)
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

func check_target_selection() -> void:
	target_obj = potential_target_obj

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		check_target_selection()
