class_name AStarPathfinder
extends RefCounted

const MAX_NODES_EXPANDED: int = 2000

static func find_path(grid: NavGrid, from_cell: int, to_cell: int) -> PackedInt32Array:
	var empty: PackedInt32Array = PackedInt32Array()
	if grid == null or from_cell < 0 or to_cell < 0:
		return empty
	if not grid.is_walkable(from_cell) or not grid.is_walkable(to_cell):
		return empty
	if from_cell == to_cell:
		var single: PackedInt32Array = PackedInt32Array()
		single.append(from_cell)
		return single

	var open := PriorityQueue.new()
	var g_score: Dictionary = {from_cell: 0.0}
	var came_from: Dictionary = {}
	var closed: Dictionary = {}

	open.push(from_cell, _heuristic(grid, from_cell, to_cell))

	var expanded: int = 0
	while not open.is_empty():
		if expanded >= MAX_NODES_EXPANDED:
			return empty

		var current: int = open.pop_min()
		if closed.has(current):
			continue
		closed[current] = true
		expanded += 1

		if current == to_cell:
			return _reconstruct(came_from, current)

		for entry in grid.get_neighbors(current):
			var neighbor: int = entry[0]
			var weight: float = entry[1]
			if closed.has(neighbor):
				continue
			var tentative_g: float = g_score[current] + weight
			if tentative_g < g_score.get(neighbor, INF):
				g_score[neighbor] = tentative_g
				came_from[neighbor] = current
				open.push(neighbor, tentative_g + _heuristic(grid, neighbor, to_cell))

	return empty

## String pulling: desde el waypoint actual, avanza al más lejano que tenga
## línea libre y descarta los intermedios.
static func smooth(grid: NavGrid, cells: PackedInt32Array) -> PackedVector3Array:
	var result: PackedVector3Array = PackedVector3Array()
	if cells.is_empty():
		return result

	var waypoints: Array = []
	for id in cells:
		waypoints.append(grid.cell_to_world(id))

	var space_state: PhysicsDirectSpaceState3D = grid.get_world_3d().direct_space_state
	var current_index: int = 0
	result.append(waypoints[0])

	while current_index < waypoints.size() - 1:
		var farthest: int = current_index + 1
		for candidate in range(waypoints.size() - 1, current_index, -1):
			if _has_line(space_state, waypoints[current_index], waypoints[candidate], grid.obstacle_mask):
				farthest = candidate
				break
		result.append(waypoints[farthest])
		current_index = farthest

	return result

static func _heuristic(grid: NavGrid, from_cell: int, to_cell: int) -> float:
	var a: Vector2i = grid.cell_coords(from_cell)
	var b: Vector2i = grid.cell_coords(to_cell)
	var dx: float = absf(a.x - b.x)
	var dy: float = absf(a.y - b.y)
	return 1.0 * (dx + dy) + (1.4142 - 2.0 * 1.0) * minf(dx, dy)

static func _reconstruct(came_from: Dictionary, current: int) -> PackedInt32Array:
	var path: Array = [current]
	while came_from.has(current):
		current = came_from[current]
		path.append(current)
	path.reverse()

	var result: PackedInt32Array = PackedInt32Array()
	for id in path:
		result.append(id)
	return result

static func _has_line(space_state: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	return space_state.intersect_ray(query).is_empty()
