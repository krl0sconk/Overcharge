class_name IsTargetBehind
extends PerceptCondition

## Gate de la rama "me flanquearon": true si el objetivo quedó a la espalda
## del actor (fuera del cono frontal).

@export var behind_dot_threshold: float = -0.3  ## dot(forward, to_target) por debajo de esto = está detrás

func check(agent: PerceptComponent) -> bool:
	var target: Node = agent.blackboard.get("target")
	if target == null or not is_instance_valid(target):
		return false
	if not (agent.actor is Node3D) or not (target is Node3D):
		return false

	var actor3d: Node3D = agent.actor as Node3D
	var to_target: Vector3 = (target as Node3D).global_position - actor3d.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return false
	to_target = to_target.normalized()

	var forward: Vector3 = -actor3d.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	return forward.dot(to_target) < behind_dot_threshold
