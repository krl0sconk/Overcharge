class_name NavGridDebug
extends Node3D

## Hijo opcional de NavGrid. Dibuja celdas, aristas del grafo y la ruta activa
## de cada enemigo vivo. Se togglea con "debug_nav" (F2), arranca apagado.

@export var free_color: Color = Color(0.2, 0.8, 0.3, 0.35)
@export var blocked_color: Color = Color(0.8, 0.2, 0.2, 0.35)
@export var edge_color: Color = Color(0.9, 0.9, 0.2, 0.6)
@export var path_color: Color = Color(0.2, 0.6, 1.0, 0.9)
@export var draw_height: float = 0.05

var _grid: NavGrid
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _enabled: bool = false

func _ready() -> void:
	_grid = get_parent() as NavGrid
	_immediate_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _immediate_mesh
	## Los vértices que dibujamos ya están en espacio global (cell_to_world);
	## top_level evita que se les sume encima el transform de NavGrid/NavGridDebug.
	_mesh_instance.top_level = true
	_mesh_instance.global_transform = Transform3D.IDENTITY
	_mesh_instance.material_override = _make_material()
	_mesh_instance.visible = false
	add_child(_mesh_instance)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_nav"):
		_enabled = not _enabled
		_mesh_instance.visible = _enabled

func _process(_delta: float) -> void:
	if not _enabled or _grid == null:
		return
	_draw()

func _make_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _draw() -> void:
	_immediate_mesh.clear_surfaces()
	_draw_cells()
	_draw_edges()
	_draw_paths()

func _draw_cells() -> void:
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for id in _grid.cell_count():
		_add_cell_quad(id, free_color if _grid.is_walkable(id) else blocked_color)
	_immediate_mesh.surface_end()

func _add_cell_quad(id: int, color: Color) -> void:
	var center: Vector3 = _grid.cell_to_world(id) + Vector3(0, draw_height, 0)
	var half: float = _grid.cell_size * 0.5 * 0.85
	var a: Vector3 = center + Vector3(-half, 0, -half)
	var b: Vector3 = center + Vector3(half, 0, -half)
	var c: Vector3 = center + Vector3(half, 0, half)
	var d: Vector3 = center + Vector3(-half, 0, half)

	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(a)
	_immediate_mesh.surface_add_vertex(b)
	_immediate_mesh.surface_add_vertex(c)
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(a)
	_immediate_mesh.surface_add_vertex(c)
	_immediate_mesh.surface_add_vertex(d)

func _draw_edges() -> void:
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_mesh.surface_set_color(edge_color)
	for id in _grid.adjacency.keys():
		var from: Vector3 = _grid.cell_to_world(id) + Vector3(0, draw_height, 0)
		for entry in _grid.adjacency[id]:
			var neighbor_id: int = entry[0]
			if neighbor_id <= id:
				continue  ## cada arista se dibuja una sola vez
			var to: Vector3 = _grid.cell_to_world(neighbor_id) + Vector3(0, draw_height, 0)
			_immediate_mesh.surface_add_vertex(from)
			_immediate_mesh.surface_add_vertex(to)
	_immediate_mesh.surface_end()

func _draw_paths() -> void:
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_mesh.surface_set_color(path_color)
	for node in get_tree().get_nodes_in_group("percept_debug_components"):
		if not (node is PerceptComponent):
			continue
		var waypoints: PackedVector3Array = node.blackboard.get("nav_path_waypoints", PackedVector3Array())
		for i in range(waypoints.size() - 1):
			_immediate_mesh.surface_add_vertex(waypoints[i] + Vector3(0, draw_height, 0))
			_immediate_mesh.surface_add_vertex(waypoints[i + 1] + Vector3(0, draw_height, 0))
	_immediate_mesh.surface_end()
