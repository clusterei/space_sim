extends RigidBody3D
class_name celestial_object

@export var surface_radius: float

const num_path_nodes: int = 1000
var previous_positions: PackedVector3Array
var path_I: int = 0
const path_node_d_limit: float = 1000

func _ready() -> void:
	previous_positions = PackedVector3Array()
	previous_positions.resize(num_path_nodes)

func _physics_process(_delta: float) -> void:
	apply_central_force(Global.get_gravity_accel(position) * mass)
	
	#update_path_arr
	previous_positions[path_I-1] = position - get_tree().get_first_node_in_group("celestial_objects").position
	var progress: float = (previous_positions[path_I-1] - previous_positions[path_I - 2]).length_squared()
	if progress >= path_node_d_limit:
		path_I = (path_I + 1) % num_path_nodes
		previous_positions[path_I-1] = previous_positions[path_I-2]

func _process(_delta: float) -> void:
	update_path()

func update_path() -> void:
	var mesh := ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var num_vertices: int = 0
	for i in range(path_I, num_path_nodes):
		if previous_positions[i] == Vector3.ZERO: break#to skip if still in proces of filling arr
		mesh.surface_add_vertex(previous_positions[i])
		num_vertices += 1
	for i in range(0, path_I):
		mesh.surface_add_vertex(previous_positions[i])
		num_vertices += 1
	if num_vertices < 2: return#to handle strange error where no vertices are added
	mesh.surface_end()
	$path.mesh = mesh
	$path.position = get_tree().get_first_node_in_group("celestial_objects").position
