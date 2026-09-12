class_name Reload
extends PerceptNode

## Genérica: espera duration segundos antes de devolver SUCCESS. Sirve tanto
## para la recarga del Centinela como espera genérica en cualquier otro árbol.

@export var duration: float = 2.0

func tick(agent: PerceptComponent) -> Status:
	var elapsed: float = agent.recall(self, "elapsed", 0.0) + agent.delta
	if elapsed < duration:
		agent.remember(self, "elapsed", elapsed)
		return Status.RUNNING

	agent.remember(self, "elapsed", 0.0)
	return Status.SUCCESS
