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
		repath_interval: float
	) -> PerceptNode.Status:
	_repath_if_needed(agent, key_node, actor3d, target_pos, repath_distance, repath_interval)

	var waypoints: PackedVector3Array = agent.recall(key_node, "nav_waypoints", PackedVector3Array())
	if waypoints.is_empty():
		return PerceptNode.Status.FAILURE

	var index: int = agent.recall(key_node, "nav_index", 0)
	while index < waypoints.size() - 1 and actor3d.global_position.distance_to(waypoints[index]) <= waypoint_tolerance:
		index += 1
	agent.remember(key_node, "nav_index", index)

	var to_waypoint: Vector3 = waypoints[index] - actor3d.global_position
	to_waypoint.y = 0.0
	movement.set_move_direction(to_waypoint)
	return PerceptNode.Status.RUNNING

static func clear(agent: PerceptComponent, key_node: PerceptNode, repath_interval: float) -> void:
	agent.remember(key_node, "nav_waypoints", PackedVector3Array())
	agent.remember(key_node, "nav_index", 0)
	agent.remember(key_node, "nav_repath_pos", Vector3.INF)
	agent.remember(key_node, "nav_repath_timer", repath_interval)
	agent.blackboard.erase("nav_path_waypoints")

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
