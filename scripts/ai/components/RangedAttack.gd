class_name RangedAttack
extends PerceptNode

## De prioridad alta en el árbol: mientras "firing" esté activo (lo enciende
## BeginFiring) no se reconsidera nada más, así telegrafía y dispara un
## raycast recto hacia adelante -- sin proyectil, tipo láser instantáneo --
## sin volver a pedir rango ni línea de vista. Si "firing" no está activo, no
## aplica (FAILURE). Usa el StatsResource del hitbox del actor para el daño,
## así no depende de tener un HealthComponent propio.

@export var telegraph_duration: float = 0.5
@export var max_distance: float = 10.0
@export_flags_3d_physics var hit_mask: int = 9  ## Entorno (1) + Hurtbox jugador (8)

func tick(agent: PerceptComponent) -> Status:
	if not agent.blackboard.get("firing", false):
		return Status.FAILURE

	if agent.hitbox == null or agent.hitbox.stats == null or not (agent.actor is Node3D):
		agent.blackboard["firing"] = false
		if agent.laser != null:
			agent.laser.end_telegraph()
		return Status.FAILURE

	var elapsed: float = agent.recall(self, "elapsed", 0.0) + agent.delta
	if elapsed < telegraph_duration:
		agent.remember(self, "elapsed", elapsed)
		return Status.RUNNING

	agent.remember(self, "elapsed", 0.0)
	agent.blackboard["firing"] = false
	_fire(agent)
	return Status.SUCCESS

func _fire(agent: PerceptComponent) -> void:
	var actor3d: Node3D = agent.actor as Node3D
	var from: Vector3 = agent.aim_position()
	var to: Vector3 = from + agent.aim_forward() * max_distance

	var space_state := actor3d.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, hit_mask)
	query.collide_with_areas = true
	query.exclude = [actor3d.get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)

	var hit_point: Vector3 = result.get("position", to) if not result.is_empty() else to
	if agent.laser != null:
		agent.laser.fire(from.distance_to(hit_point))

	if result.is_empty():
		return

	var collider: Object = result.get("collider")
	if collider != null and collider.has_method("receive_hit"):
		collider.receive_hit(agent.hitbox.stats.damage, agent.hitbox.knockback_vector(hit_point), agent.hitbox.source)
