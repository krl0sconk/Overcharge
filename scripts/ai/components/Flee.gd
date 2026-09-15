class_name Flee
extends PerceptNode

## Rama de prioridad más alta: si al agente lo golpearon hace poco
## (blackboard["hit_recently"], lo prende PerceptComponent al recibir la
## señal damaged de su HealthComponent) se aleja en línea recta del target
## durante duration segundos en vez de seguir rodeando. Si no lo golpearon,
## no aplica (FAILURE) y el Selector padre sigue evaluando otras ramas.

@export var duration: float = 1.2

func tick(agent: PerceptComponent) -> Status:
	if not agent.blackboard.get("hit_recently", false):
		return Status.FAILURE

	var elapsed: float = agent.recall(self, "elapsed", 0.0) + agent.delta
	if elapsed < duration:
		agent.remember(self, "elapsed", elapsed)
		_move_away(agent)
		return Status.RUNNING

	agent.remember(self, "elapsed", 0.0)
	agent.blackboard["hit_recently"] = false
	return Status.SUCCESS

func _move_away(agent: PerceptComponent) -> void:
	var target: Node = agent.blackboard.get("target")
	var movement: MovementComponent = agent.movement_component
	if target == null or not is_instance_valid(target) or movement == null \
			or not (agent.actor is Node3D) or not (target is Node3D):
		return

	var away: Vector3 = (agent.actor as Node3D).global_position - (target as Node3D).global_position
	away.y = 0.0
	movement.set_move_direction(away)
