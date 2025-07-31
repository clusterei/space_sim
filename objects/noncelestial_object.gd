extends RigidBody3D
class_name noncelestial_object

const num_path_nodes: int = 1000
var previous_positions: PackedVector3Array
var path_I: int
const path_node_d_limit: float = 100####use angle instead

func _ready() -> void:
	init_path()

func init_path() -> void:
	previous_positions = PackedVector3Array()
	previous_positions.resize(num_path_nodes)
	path_I = 0

func _physics_process(_delta: float) -> void:
	apply_central_force(Global.get_gravity_accel(position) * mass)
	
	#update_path_arr
	previous_positions[path_I-1] = position - Global.reference_frame.position#quick hack
	var progress: float = (previous_positions[path_I-1] - previous_positions[path_I - 2]).length_squared()
	if progress >= path_node_d_limit:
		path_I = (path_I + 1) % num_path_nodes
		previous_positions[path_I-1] = previous_positions[path_I-2]

func _process(_delta: float) -> void:
	update_path()

func update_path() -> void:####maove func to global????
	var mesh := ImmediateMesh.new()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var num_vertices: int = 0
	for i in range(path_I, num_path_nodes):
		if previous_positions[i] == Vector3.ZERO: break#to skip if still in proces of filling arr
		mesh.surface_add_vertex(previous_positions[i])
		mesh.surface_set_normal(-previous_positions[i])
		num_vertices += 1
	for i in range(0, path_I):
		mesh.surface_add_vertex(previous_positions[i])
		mesh.surface_set_normal(-previous_positions[i])
		num_vertices += 1
	if num_vertices < 2: return#to handle strange error where no vertices are added
	mesh.surface_end()
	$path.mesh = mesh
	$path.position = Global.reference_frame.position#quick hack
	#$path.visible = $"../Camera3D".reference_frame != self
	#$pred_path.position = $"../Camera3D".reference_frame.position#quick hack

func _on_body_entered(body: Node) -> void:
	if body in Global.cel_objects: print("! ", self.name, " collided with ", body.name, " !")
