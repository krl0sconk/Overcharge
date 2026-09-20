class_name IsTargetInRange
extends PerceptCondition

## Genérica: true si la distancia horizontal al target del blackboard cae
## dentro de [min_range, max_range]. max_range <= 0 = sin tope (solo importa
## el mínimo). Sirve tanto para gatear un ataque cuerpo a cuerpo (min 0) como
## uno a distancia (min > 0, para no solaparlo con el melé).

@export var min_range: float = 0.0
@export var max_range: float = 0.0

func check(agent: PerceptComponent) -> bool:
	var target: Node = agent.blackboard.get("target")
	if target == null or not is_instance_valid(target) or not (agent.actor is Node3D) or not (target is Node3D):
		return false

	var from: Vector3 = (agent.actor as Node3D).global_position
	var to: Vector3 = (target as Node3D).global_position
	from.y = 0.0
	to.y = 0.0
	var distance: float = from.distance_to(to)

	if distance < min_range:
		return false
	if max_range > 0.0 and distance > max_range:
		return false
	return true
