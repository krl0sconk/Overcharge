class_name AcquireTarget
extends PerceptCondition

## Hoja genérica: va al tope de todo árbol de enemigo. Fija un objetivo del
## grupo "players" en el blackboard y no lo recalcula mientras siga siendo
## válido (pegajoso).

@export var vision_range: float = 10.0  

func check(agent: PerceptComponent) -> bool:
	var current: Node = agent.blackboard.get("target")
	if _is_valid_target(agent, current):
		return true

	var candidates: Array[Node] = []
	for player in agent.actor.get_tree().get_nodes_in_group("players"):
		if _is_valid_target(agent, player):
			candidates.append(player)

	if candidates.is_empty():
		agent.blackboard.erase("target")
		return false

	agent.blackboard["target"] = candidates[randi() % candidates.size()]
	return true

func _is_valid_target(agent: PerceptComponent, target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not _is_alive(target):
		return false
	return _in_range(agent, target)

func _is_alive(target: Node) -> bool:
	var health: Node = target.get_node_or_null("HealthComponent")
	if health == null:
		return true  ## sin HealthComponent se considera siempre vivo
	return health.current_health > 0

func _in_range(agent: PerceptComponent, target: Node) -> bool:
	if vision_range <= 0.0:
		return true
	if not (agent.actor is Node3D) or not (target is Node3D):
		return true
	var from: Vector3 = (agent.actor as Node3D).global_position
	var to: Vector3 = (target as Node3D).global_position
	from.y = 0.0
	to.y = 0.0
	return from.distance_to(to) <= vision_range
