class_name NavGrid
extends Node3D

## Grafo explícito de la zona (XZ), centrado en el nodo. Se construye una
## sola vez en _ready() -- no se recalcula en runtime salvo rebuild() manual.

@export var cell_size: float = 0.5
@export var bounds_size: Vector2 = Vector2(20.0, 20.0)
@export_flags_3d_physics var obstacle_mask: int = 1  ## Entorno
@export var agent_radius: float = 0.4
@export var probe_height: float = 0.5  ## sondea por encima del piso: el piso suele compartir capa con las paredes

const ORTHOGONAL_WEIGHT: float = 1.0
const DIAGONAL_WEIGHT: float = 1.4142

var adjacency: Dictionary = {}  ## int id -> Array de [neighbor_id: int, weight: float]

var _walkable: PackedByteArray = PackedByteArray()
var _cols: int = 0
var _rows: int = 0
var _origin: Vector3 = Vector3.ZERO  ## esquina -X -Z de la grilla

func _ready() -> void:
	add_to_group("nav_grid")
	rebuild()

func rebuild() -> void:
	_cols = maxi(1, int(ceil(bounds_size.x / cell_size)))
	_rows = maxi(1, int(ceil(bounds_size.y / cell_size)))
	_origin = global_position - Vector3(bounds_size.x, 0.0, bounds_size.y) * 0.5

	_compute_walkable()
	_build_adjacency()

func cell_count() -> int:
	return _cols * _rows

func world_to_cell(pos: Vector3) -> int:
	var col: int = int(floor((pos.x - _origin.x) / cell_size))
	var row: int = int(floor((pos.z - _origin.z) / cell_size))
	if col < 0 or col >= _cols or row < 0 or row >= _rows:
		return -1
	return _id_of(col, row)

func cell_to_world(id: int) -> Vector3:
	var coords: Vector2i = cell_coords(id)
	return _cell_center(coords.x, coords.y)

func cell_coords(id: int) -> Vector2i:
	return Vector2i(id % _cols, id / _cols)

func is_walkable(id: int) -> bool:
	if id < 0 or id >= _walkable.size():
		return false
	return _walkable[id] == 1

## Si pos cae en una celda bloqueada (o fuera de la grilla), devuelve la
## libre más cercana buscando en anillos crecientes alrededor de esa celda.
func nearest_walkable(pos: Vector3) -> int:
	var col: int = clampi(int(floor((pos.x - _origin.x) / cell_size)), 0, _cols - 1)
	var row: int = clampi(int(floor((pos.z - _origin.z) / cell_size)), 0, _rows - 1)

	var start_id: int = _id_of(col, row)
	if is_walkable(start_id):
		return start_id

	var max_radius: int = maxi(_cols, _rows)
	for radius in range(1, max_radius + 1):
		var best_id: int = -1
		var best_dist: float = INF
		for dc in range(-radius, radius + 1):
			for dr in range(-radius, radius + 1):
				if maxi(absi(dc), absi(dr)) != radius:
					continue
				var c: int = col + dc
				var r: int = row + dr
				if c < 0 or c >= _cols or r < 0 or r >= _rows:
					continue
				var id: int = _id_of(c, r)
				if not is_walkable(id):
					continue
				var dist: float = Vector2(dc, dr).length()
				if dist < best_dist:
					best_dist = dist
					best_id = id
		if best_id != -1:
			return best_id

	return -1

func random_walkable_cell() -> int:
	var candidates: Array[int] = []
	for id in _walkable.size():
		if _walkable[id] == 1:
			candidates.append(id)
	if candidates.is_empty():
		return -1
	return candidates[randi() % candidates.size()]

func get_neighbors(id: int) -> Array:
	return adjacency.get(id, [])

func _compute_walkable() -> void:
	_walkable = PackedByteArray()
	_walkable.resize(_cols * _rows)

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	var side: float = cell_size + agent_radius * 2.0
	shape.size = Vector3(side, 1.0, side)

	for row in _rows:
		for col in _cols:
			var id: int = _id_of(col, row)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform = Transform3D(Basis(), _cell_center(col, row) + Vector3(0.0, probe_height, 0.0))
			query.collision_mask = obstacle_mask
			var hits: Array = space_state.intersect_shape(query, 1)
			_walkable[id] = 1 if hits.is_empty() else 0

func _build_adjacency() -> void:
	adjacency.clear()
	for row in _rows:
		for col in _cols:
			var id: int = _id_of(col, row)
			if not is_walkable(id):
				continue
			var edges: Array = []
			_try_add_orthogonal(edges, col, row, 1, 0)
			_try_add_orthogonal(edges, col, row, -1, 0)
			_try_add_orthogonal(edges, col, row, 0, 1)
			_try_add_orthogonal(edges, col, row, 0, -1)
			_try_add_diagonal(edges, col, row, 1, 1)
			_try_add_diagonal(edges, col, row, 1, -1)
			_try_add_diagonal(edges, col, row, -1, 1)
			_try_add_diagonal(edges, col, row, -1, -1)
			adjacency[id] = edges

func _try_add_orthogonal(edges: Array, col: int, row: int, dc: int, dr: int) -> void:
	var c: int = col + dc
	var r: int = row + dr
	if c < 0 or c >= _cols or r < 0 or r >= _rows:
		return
	var neighbor_id: int = _id_of(c, r)
	if is_walkable(neighbor_id):
		edges.append([neighbor_id, ORTHOGONAL_WEIGHT])

## No permite cortar esquinas: la diagonal solo existe si las dos celdas
## ortogonales que la flanquean también están libres.
func _try_add_diagonal(edges: Array, col: int, row: int, dc: int, dr: int) -> void:
	var c: int = col + dc
	var r: int = row + dr
	if c < 0 or c >= _cols or r < 0 or r >= _rows:
		return
	var neighbor_id: int = _id_of(c, r)
	if not is_walkable(neighbor_id):
		return
	if not is_walkable(_id_of(c, row)) or not is_walkable(_id_of(col, r)):
		return
	edges.append([neighbor_id, DIAGONAL_WEIGHT])

func _id_of(col: int, row: int) -> int:
	return row * _cols + col

func _cell_center(col: int, row: int) -> Vector3:
	return Vector3(
		_origin.x + (col + 0.5) * cell_size,
		global_position.y,
		_origin.z + (row + 0.5) * cell_size
	)
