class_name Cooldown
extends PerceptDecorator

## Mientras el cooldown está corriendo devuelve FAILURE, para que el Selector
## padre siga evaluando otras ramas. Si no, tickea al hijo; el cooldown arranca
## recién cuando el hijo tiene éxito (no por intentarlo).

@export var cooldown: float = 1.0

func tick(agent: PerceptComponent) -> Status:
	## Arranca "listo": sin esto, todo enemigo esperaría un cooldown completo
	## antes de su primer ataque.
	var elapsed: float = agent.recall(self, "elapsed", cooldown)
	if elapsed < cooldown:
		agent.remember(self, "elapsed", elapsed + agent.delta)
		return Status.FAILURE

	var child: PerceptNode = _child()
	if child == null:
		return Status.FAILURE

	var result: Status = child.tick_traced(agent, agent._debug_child_path(0))
	if result == Status.SUCCESS:
		agent.remember(self, "elapsed", 0.0)
	return result
