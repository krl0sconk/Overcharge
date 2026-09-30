class_name MoveToPosition
extends PerceptNode

## Igual que MoveToTarget, pero el destino sale de una clave del blackboard
## en vez de un target Node -- lo usan enemigos que van a un punto (Ancla,
## Divisor) en vez de perseguir directamente.

@export var position_key: String = "target_position"
@export var stop_distance: float = 1.0
@export var waypoint_tolerance: float = 0.3
@export var repath_distance: float = 1.5
@export var repath_interval: float = 0.5

func tick(agent: PerceptComponent) -> Status:
	var movement: MovementComponent = agent.movement_component
	if movement == null or not (agent.actor is Node3D) or not agent.blackboard.has(position_key):
		return Status.FAILURE

	var actor3d: Node3D = agent.actor as Node3D
	var target_pos: Vector3 = agent.blackboard[position_key]
	var to_target: Vector3 = target_pos - actor3d.global_position
	to_target.y = 0.0

	if to_target.length() <= stop_distance:
		movement.set_move_direction(Vector3.ZERO)
		NavPathing.clear(agent, self, repath_interval)
		return Status.SUCCESS

	if agent.nav_grid == null:
		movement.set_move_direction(to_target)
		return Status.RUNNING

	return NavPathing.follow(
		agent, self, movement, actor3d, target_pos,
		waypoint_tolerance, repath_distance, repath_interval
	)
