class_name MeleeAttack
extends PerceptNode

## Genérica: telegrafía, abre una ventana de golpe (hitbox activo) y la
## cierra. El daño en sí lo resuelve HitboxComponent solo, al detectar el
## área con area_entered; este nodo solo prende y apaga esa ventana.

@export var telegraph_duration: float = 0.4
@export var active_duration: float = 0.2

func tick(agent: PerceptComponent) -> Status:
	if agent.hitbox == null:
		return Status.FAILURE

	agent.blackboard["attacking"] = true
	var elapsed: float = agent.recall(self, "elapsed", 0.0) + agent.delta

	if elapsed < telegraph_duration:
		agent.remember(self, "elapsed", elapsed)
		return Status.RUNNING

	agent.hitbox.monitoring = true
	var active_elapsed: float = elapsed - telegraph_duration

	if active_elapsed < active_duration:
		agent.remember(self, "elapsed", elapsed)
		return Status.RUNNING

	agent.hitbox.monitoring = false
	agent.blackboard["attacking"] = false
	agent.remember(self, "elapsed", 0.0)
	return Status.SUCCESS
