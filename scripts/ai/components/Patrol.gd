class_name Patrol
extends PerceptNode

## Genérica: deambula sin objetivo ni pathfinding. Sostiene una dirección
## aleatoria por leg_duration segundos y la cambia antes si choca contra algo
## (hit_wall). Va al fondo del Selector: es lo que hace un enemigo sin nada
## mejor que hacer, así que nunca falla.

@export var leg_duration: float = 2.0

func tick(agent: PerceptComponent) -> Status:
	var movement: MovementComponent = agent.movement_component
	if movement == null:
		return Status.FAILURE

	var elapsed: float = agent.recall(self, "elapsed", leg_duration) + agent.delta
	if elapsed >= leg_duration or movement.hit_wall:
		elapsed = 0.0
		var angle: float = randf() * TAU
		agent.remember(self, "direction", Vector3(cos(angle), 0.0, sin(angle)))

	agent.remember(self, "elapsed", elapsed)
	movement.set_move_direction(agent.recall(self, "direction", Vector3.ZERO))
	return Status.RUNNING
