class_name HasLineToTarget
extends PerceptCondition

## Gate de "iniciar carga": el objetivo tiene que estar dentro de un cono
## angosto frente al actor (línea recta) y sin nada de la capa Entorno en
## el medio.

@export var facing_dot_threshold: float = 0.97  ## ~14° de cono frontal
@export var environment_mask: int = 1  ## capa 1 = "Entorno"

func check(agent: PerceptComponent) -> bool:
	var target: Node = agent.blackboard.get("target")
	if target == null or not is_instance_valid(target) or not (agent.actor is Node3D) or not (target is Node3D):
		return false

	var actor3d: Node3D = agent.actor as Node3D
	var target3d: Node3D = target as Node3D

	var to_target: Vector3 = target3d.global_position - actor3d.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return false
	to_target = to_target.normalized()

	var forward: Vector3 = agent.aim_forward()

	if forward.dot(to_target) < facing_dot_threshold:
		return false

	var space_state := actor3d.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		actor3d.global_position, target3d.global_position, environment_mask
	)
	query.exclude = [actor3d.get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	return result.is_empty()
