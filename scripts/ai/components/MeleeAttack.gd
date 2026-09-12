class_name MeleeAttack
extends PerceptNode

## Genérica: telegrafía y delega la ventana de golpe al HitboxComponent, que
## la cierra con su propio timer. Los compuestos son reactivos y sin abortos
## -- si el objetivo sale de rango a mitad de golpe, esta hoja no se vuelve a
## tickear -- así que no puede depender de un tick futuro para apagar el
## hitbox: lo abre y se desentiende.

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

	agent.remember(self, "elapsed", 0.0)
	agent.blackboard["attacking"] = false
	agent.hitbox.open_window(active_duration)
	return Status.SUCCESS
