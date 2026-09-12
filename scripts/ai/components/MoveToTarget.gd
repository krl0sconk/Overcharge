class_name MoveToTarget
extends PerceptNode

## Genérica: mueve al actor en línea recta hacia el target del blackboard,
## en el plano XZ. Sin pathfinding (entrega 2): persecución directa. Se frena
## a stop_distance para no encimarse con el objetivo.

@export var stop_distance: float = 1.0

func tick(agent: PerceptComponent) -> Status:
	var target: Node = agent.blackboard.get("target")
	var movement: MovementComponent = agent.movement_component
	if target == null or not is_instance_valid(target) or movement == null \
			or not (agent.actor is Node3D) or not (target is Node3D):
		return Status.FAILURE

	var actor3d: Node3D = agent.actor as Node3D
	var to_target: Vector3 = (target as Node3D).global_position - actor3d.global_position
	to_target.y = 0.0

	if to_target.length() <= stop_distance:
		movement.set_move_direction(Vector3.ZERO)
		return Status.SUCCESS

	movement.set_move_direction(to_target)
	return Status.RUNNING
