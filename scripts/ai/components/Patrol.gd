class_name Patrol
extends PerceptNode

## Genérica: deambula sin objetivo. Va al fondo del Selector: es lo que hace
## un enemigo sin nada mejor que hacer, así que nunca falla.
## Sin NavGrid: dirección aleatoria sostenida por leg_duration (comportamiento
## original, fallback obligatorio). Con NavGrid: elige una celda libre
## aleatoria, va hacia ella y al llegar elige otra.

@export var leg_duration: float = 2.0
@export var waypoint_tolerance: float = 0.3
@export var repath_distance: float = 1.5
@export var repath_interval: float = 0.5

func tick(agent: PerceptComponent) -> Status:
	var movement: MovementComponent = agent.movement_component
	if movement == null:
		return Status.FAILURE

	if agent.nav_grid != null and agent.actor is Node3D:
		return _patrol_grid(agent, movement, agent.actor as Node3D)

	return _patrol_random_direction(agent, movement)

func _patrol_random_direction(agent: PerceptComponent, movement: MovementComponent) -> Status:
	var elapsed: float = agent.recall(self, "elapsed", leg_duration) + agent.delta
	if elapsed >= leg_duration or movement.hit_wall:
		elapsed = 0.0
		var angle: float = randf() * TAU
		agent.remember(self, "direction", Vector3(cos(angle), 0.0, sin(angle)))

	agent.remember(self, "elapsed", elapsed)
	movement.set_move_direction(agent.recall(self, "direction", Vector3.ZERO))
	return Status.RUNNING

func _patrol_grid(agent: PerceptComponent, movement: MovementComponent, actor3d: Node3D) -> Status:
	var target_pos: Vector3 = agent.recall(self, "patrol_target", Vector3.INF)

	if target_pos == Vector3.INF or actor3d.global_position.distance_to(target_pos) <= waypoint_tolerance:
		target_pos = _pick_random_cell(agent.nav_grid, actor3d.global_position)
		agent.remember(self, "patrol_target", target_pos)
		NavPathing.clear(agent, self, repath_interval)
		movement.set_move_direction(Vector3.ZERO)
		return Status.RUNNING

	var status: Status = NavPathing.follow(
		agent, self, movement, actor3d, target_pos,
		waypoint_tolerance, repath_distance, repath_interval
	)
	if status == Status.FAILURE:
		agent.remember(self, "patrol_target", Vector3.INF)
		movement.set_move_direction(Vector3.ZERO)
	return Status.RUNNING

func _pick_random_cell(grid: NavGrid, from_pos: Vector3) -> Vector3:
	var id: int = grid.random_walkable_cell()
	if id < 0:
		return from_pos
	return grid.cell_to_world(id)
