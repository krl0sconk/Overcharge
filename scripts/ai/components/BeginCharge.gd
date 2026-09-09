class_name BeginCharge
extends PerceptNode

## Cuerpo de la rama "iniciar carga" (gateada por HasLineToTarget en el
## árbol). Telegrafía telegraph_duration y arranca la carga en línea recta.
##
## Reactivo: si la línea se pierde a mitad de telegrafía, el Sequence padre
## corta acá antes de tickear este nodo (no hay sistema de abortos), así que
## el cronómetro simplemente queda pausado en memoria hasta que la línea
## vuelva a estar libre.

@export var telegraph_duration: float = 0.6

func tick(agent: PerceptComponent) -> Status:
	var elapsed: float = agent.recall(self, "elapsed", 0.0) + agent.delta
	agent.blackboard["telegraphing"] = true

	if elapsed < telegraph_duration:
		agent.remember(self, "elapsed", elapsed)
		return Status.RUNNING

	agent.remember(self, "elapsed", 0.0)
	agent.blackboard["telegraphing"] = false
	agent.blackboard["charging"] = true

	if agent.actor is Node3D:
		agent.blackboard["charge_direction"] = -(agent.actor as Node3D).global_transform.basis.z
	else:
		agent.blackboard["charge_direction"] = Vector3.ZERO

	return Status.SUCCESS
