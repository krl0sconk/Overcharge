class_name NavPathing
extends RefCounted

## Seguimiento de ruta compartido por MoveToTarget y MoveToPosition.
## key_node identifica al leaf dueño del estado (remember/recall de agent).

static func follow(
		agent: PerceptComponent,
		key_node: PerceptNode,
		movement: MovementComponent,
		actor3d: Node3D,
		target_pos: Vector3,
		waypoint_tolerance: float,
		repath_distance: float,
		repath_interval: float,
		stuck_time: float = 1.5,
		stuck_distance: float = 0.3
	) -> PerceptNode.Status:
	_repath_if_needed(agent, key_node, actor3d, target_pos, repath_distance, repath_interval)

	var waypoints: PackedVector3Array = agent.recall(key_node, "nav_waypoints", PackedVector3Array())
	if waypoints.is_empty():
		return PerceptNode.Status.FAILURE

	var index: int = agent.recall(key_node, "nav_index", 0)
	while index < waypoints.size() - 1 and actor3d.global_position.distance_to(waypoints[index]) <= waypoint_tolerance:
		index += 1
	agent.remember(key_node, "nav_index", index)

	var at_last_waypoint: bool = index == waypoints.size() - 1 \
			and _flat_distance(actor3d.global_position, waypoints[index]) <= waypoint_tolerance
	if _is_stuck(agent, key_node, actor3d, at_last_waypoint, stuck_time, stuck_distance):
		clear(agent, key_node, repath_interval)
		movement.set_move_direction(Vector3.ZERO)
		return PerceptNode.Status.FAILURE

	var to_waypoint: Vector3 = waypoints[index] - actor3d.global_position
	to_waypoint.y = 0.0
	movement.set_move_direction(to_waypoint)
	return PerceptNode.Status.RUNNING

static func clear(agent: PerceptComponent, key_node: PerceptNode, repath_interval: float) -> void:
	agent.remember(key_node, "nav_waypoints", PackedVector3Array())
	agent.remember(key_node, "nav_index", 0)
	agent.remember(key_node, "nav_repath_pos", Vector3.INF)
	agent.remember(key_node, "nav_repath_timer", repath_interval)
	agent.remember(key_node, "nav_stuck_anchor", Vector3.INF)
	agent.remember(key_node, "nav_stuck_timer", 0.0)
	agent.blackboard.erase("nav_path_waypoints")

## Atasco: el actor no se alejó stuck_distance del ancla en stuck_time. Estar
## en el último waypoint sin que el leaf termine (destino inalcanzable,
## nearest_walkable lo dejó lo más cerca posible) acumula aunque haya jitter.
static func _is_stuck(
		agent: PerceptComponent,
		key_node: PerceptNode,
		actor3d: Node3D,
		at_last_waypoint: bool,
		stuck_time: float,
		stuck_distance: float
	) -> bool:
	var anchor: Vector3 = agent.recall(key_node, "nav_stuck_anchor", Vector3.INF)
	var timer: float = agent.recall(key_node, "nav_stuck_timer", 0.0)

	var moved_away: bool = anchor == Vector3.INF \
			or _flat_distance(actor3d.global_position, anchor) > stuck_distance
	if moved_away and not at_last_waypoint:
		anchor = actor3d.global_position
		timer = 0.0
	else:
		if anchor == Vector3.INF:
			anchor = actor3d.global_position
		timer += agent.delta

	agent.remember(key_node, "nav_stuck_anchor", anchor)
	agent.remember(key_node, "nav_stuck_timer", timer)
	return timer > stuck_time

static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

static func _repath_if_needed(
		agent: PerceptComponent,
		key_node: PerceptNode,
		actor3d: Node3D,
		target_pos: Vector3,
		repath_distance: float,
		repath_interval: float
	) -> void:
	var last_target: Vector3 = agent.recall(key_node, "nav_repath_pos", Vector3.INF)
	var timer: float = agent.recall(key_node, "nav_repath_timer", repath_interval) + agent.delta

	var needs_repath: bool = (agent.recall(key_node, "nav_waypoints", PackedVector3Array()) as PackedVector3Array).is_empty()
	if last_target != Vector3.INF and last_target.distance_to(target_pos) > repath_distance:
		needs_repath = true
	if timer >= repath_interval:
		needs_repath = true
		timer = 0.0

	agent.remember(key_node, "nav_repath_timer", timer)

	if needs_repath:
		_repath(agent, key_node, actor3d, target_pos)

static func _repath(agent: PerceptComponent, key_node: PerceptNode, actor3d: Node3D, target_pos: Vector3) -> void:
	agent.remember(key_node, "nav_repath_pos", target_pos)
	agent.remember(key_node, "nav_repath_timer", 0.0)

	var grid: NavGrid = agent.nav_grid
	if grid == null:
		_set_waypoints(agent, key_node, PackedVector3Array())
		return

	var from_id: int = grid.nearest_walkable(actor3d.global_position)
	var to_id: int = grid.nearest_walkable(target_pos)

	if from_id < 0 or to_id < 0:
		_set_waypoints(agent, key_node, PackedVector3Array())
		return

	var cells: PackedInt32Array = AStarPathfinder.find_path(grid, from_id, to_id)
	if cells.is_empty():
		_set_waypoints(agent, key_node, PackedVector3Array())
		return

	_set_waypoints(agent, key_node, AStarPathfinder.smooth(grid, cells))
	agent.remember(key_node, "nav_index", 0)

static func _set_waypoints(agent: PerceptComponent, key_node: PerceptNode, waypoints: PackedVector3Array) -> void:
	agent.remember(key_node, "nav_waypoints", waypoints)
	if waypoints.is_empty():
		agent.blackboard.erase("nav_path_waypoints")
	else:
		agent.blackboard["nav_path_waypoints"] = waypoints
