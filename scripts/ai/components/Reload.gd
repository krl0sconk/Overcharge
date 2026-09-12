class_name Reload
extends PerceptNode

## Genérica: espera duration segundos antes de devolver SUCCESS. Sirve tanto
## para la recarga del Centinela como espera genérica en cualquier otro árbol.
## Marca blackboard["reloading"] mientras corre -- sin esto el overlay se
## queda mostrando la última rama que sí se tickeó, ya que recall() no
## distingue "en curso" de "nunca más se volvió a tickear".

@export var duration: float = 2.0

func tick(agent: PerceptComponent) -> Status:
	agent.blackboard["reloading"] = true
	var elapsed: float = agent.recall(self, "elapsed", 0.0) + agent.delta
	if elapsed < duration:
		agent.remember(self, "elapsed", elapsed)
		return Status.RUNNING

	agent.remember(self, "elapsed", 0.0)
	agent.blackboard["reloading"] = false
	return Status.SUCCESS
