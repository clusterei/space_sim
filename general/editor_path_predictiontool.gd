@tool
extends Node

@export var grainyness: int = 100
@export var stepsize: float = 1. / 60.
@export var ref_frame_obj: celestial_object
var prev_cel_obj: celestial_object
@export var num_steps: int = 0
@export var steps_per_frame: int = 2000
@export var trigger_recalc := false

var path_arr_arr: Array[PackedVector3Array]
var progress: int = 0
var path_end_state: Dictionary

var initial_planet_properties: Array[Dictionary]

func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()

func _process(_delta: float) -> void:
	if ref_frame_obj == null: ref_frame_obj = get_tree().get_first_node_in_group("celestial_objects")
	if prev_cel_obj != ref_frame_obj:
		prev_cel_obj = ref_frame_obj
		progress = 0
	
	var cel_objects: Array = get_tree().get_nodes_in_group("celestial_objects")
	if trigger_recalc:
		progress = 0
		trigger_recalc = false
	
	var diff_detected := progress == 0
	if not diff_detected:
		for i in cel_objects.size():
			var obj = cel_objects[i]
			var known_state := initial_planet_properties[i]
			diff_detected = diff_detected or obj.position != known_state["pos"]
			diff_detected = diff_detected or obj.linear_velocity != known_state["vel"]
			diff_detected = diff_detected or obj.mass != known_state["mass"]
			diff_detected = diff_detected or obj.surface_radius != known_state["radius"]
		if diff_detected:
			progress = 0
	if diff_detected:
		initial_planet_properties.resize(cel_objects.size())
		
		for i in cel_objects.size():
			var obj = cel_objects[i]
			var known_state := initial_planet_properties[i]
			known_state["pos"] = obj.position
			known_state["vel"] = obj.linear_velocity
			known_state["mass"] = obj.mass
			known_state["radius"] = obj.surface_radius
	
	#print(progress, " ", num_steps)
	if progress < num_steps:
		predict_paths(cel_objects)
		draw_trajectory(cel_objects)

func draw_trajectory(cel_objects: Array) -> void:
	#print("drawing")
	for i in cel_objects.size():
		var pred_path: MeshInstance3D
		var path_name := "pred_path" + str(i)
		if not has_node(path_name):
			pred_path = MeshInstance3D.new()
			pred_path.top_level = true
			pred_path.name = path_name
			#pred_path.set_layer_mask_value(0, false)
			#pred_path.set_layer_mask_value(1, true)
			add_child(pred_path)
		else:
			pred_path = get_node(path_name)
		
		var mesh := ImmediateMesh.new()
		mesh.clear_surfaces()
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		#var color = cel_objects[i].get_node("MeshInstance3D").mesh.material.albedo_color
		var num_vertices: int = 0
		for pos in path_arr_arr[i]:
			if pos == Vector3.ZERO: break
			#mesh.surface_set_color(color)####doesnt seem to work
			mesh.surface_add_vertex(pos)
			mesh.surface_set_normal(-pos)
			num_vertices += 1
		if num_vertices < 2: continue
		mesh.surface_end()
		pred_path.mesh = mesh
		pred_path.position = ref_frame_obj.position

func predict_paths(cel_objects: Array):
	#print("predicting")
	var grav_constant := Global.grav_constant
	var num_objs: int = cel_objects.size()
	
	var pos_arr: PackedVector3Array
	var vel_arr: PackedVector3Array
	var mass_arr: PackedFloat32Array
	var new_pos_arr: PackedVector3Array
	var radius_arr: PackedFloat32Array
	var grainy_progress: int
	var path_index: int
	var collides_arr: PackedByteArray
	if progress == 0:
		path_arr_arr = []
		pos_arr = PackedVector3Array()
		vel_arr = PackedVector3Array()
		radius_arr = PackedFloat32Array()
		grainy_progress = 0
		path_index = 0
		for obj in cel_objects:
			var path_arr := PackedVector3Array()
			path_arr_arr.append(path_arr)
			pos_arr.append(obj.position)
			vel_arr.append(obj.linear_velocity)
			radius_arr.append(pow(obj.surface_radius, 2))
	else:
		path_index = path_end_state["path_index"]
		pos_arr = path_end_state["pos_arr"]
		vel_arr = path_end_state["vel_arr"]
		grainy_progress = path_end_state["grainy_progress"]
		radius_arr = path_end_state["radius_arr"]
	mass_arr = PackedFloat32Array()
	new_pos_arr = PackedVector3Array()
	collides_arr = PackedByteArray()
	for i in cel_objects.size():
		mass_arr.append(cel_objects[i].mass)
		path_arr_arr[i].resize(int(ceil(num_steps / float(grainyness))))
	new_pos_arr.resize(num_objs)
	collides_arr.resize(num_objs)
	
	var ref_frame_obj_index: int = cel_objects.find(ref_frame_obj)
	var collides := false
	for i in range(progress, min(progress + steps_per_frame, num_steps)):
		if grainy_progress == 0:
			grainy_progress = grainyness
			for j in num_objs:
				path_arr_arr[j][path_index] = pos_arr[j]
			path_index += 1
		grainy_progress -= 1
		
		var ref_frame_offset := pos_arr[ref_frame_obj_index]#to adjust for ref frame moving
		for j in num_objs:
			var accel := Vector3.ZERO
			var pos: Vector3 = pos_arr[j]
			var radius_sq: float = radius_arr[j]
			#path_arr_arr[j][i] = pos#updates path
			for k in num_objs:#####check somewhere for collisions and show them somehow
				var diff: Vector3 = pos_arr[k] - pos
				var d_sqr: float = diff.length_squared()
				if d_sqr == 0.: continue
				if d_sqr <= radius_arr[k] + radius_sq:
					collides = true
					collides_arr.encode_s8(j, 1)
					collides_arr.encode_s8(k, 1)
					break
				var strength: float = grav_constant * mass_arr[k] / d_sqr
				accel += diff / sqrt(d_sqr) * strength
			if collides: break
			vel_arr[j] += accel * stepsize
			new_pos_arr[j] = pos + vel_arr[j] * stepsize - ref_frame_offset
		if collides: break
		pos_arr = new_pos_arr.duplicate()
	if collides:
		pass#########find colliding objs. from colliion arr thingy and somehow color representations of them
		#######maby make markers for closest and farthet approach to reframe obj and make looking up each distance and their ratio possible
	
	path_end_state["pos_arr"] = pos_arr
	path_end_state["vel_arr"] = vel_arr
	path_end_state["grainy_progress"] = grainy_progress
	path_end_state["radius_arr"] = radius_arr
	path_end_state["path_index"] = path_index
	progress = (path_index - 1) * grainyness + (grainyness - grainy_progress)
