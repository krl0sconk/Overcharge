class_name RangedAttack
extends PerceptNode

## Genérica: telegrafía y dispara un raycast recto hacia adelante -- sin
## proyectil, tipo láser instantáneo. Usa el StatsResource del hitbox del
## actor para el daño, así no depende de tener un HealthComponent propio.

@export var telegraph_duration: float = 0.5
@export var range: float = 10.0
@export_flags_3d_physics var hit_mask: int = 9  ## Entorno (1) + Hurtbox jugador (8)

func tick(agent: PerceptComponent) -> Status:
	if agent.hitbox == null or agent.hitbox.stats == null or not (agent.actor is Node3D):
		return Status.FAILURE

	agent.blackboard["firing"] = true
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
	var from: Vector3 = actor3d.global_position
	var to: Vector3 = from - actor3d.global_transform.basis.z * range

	var space_state := actor3d.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, hit_mask)
	query.collide_with_areas = true
	query.exclude = [actor3d.get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return

	var collider: Object = result.get("collider")
	if collider != null and collider.has_method("receive_hit"):
		collider.receive_hit(agent.hitbox.stats.damage, agent.hitbox.knockback, agent.hitbox.source)
