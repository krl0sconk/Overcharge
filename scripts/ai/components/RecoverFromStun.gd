class_name RecoverFromStun
extends PerceptNode

## Rama 1 del Yunque. Si no está aturdido, no aplica (FAILURE) y el Selector
## sigue evaluando. Si está aturdido, espera stun_duration y limpia la bandera.

@export var stun_duration: float = 1.5

func tick(agent: PerceptComponent) -> Status:
	if not agent.blackboard.get("stunned", false):
		return Status.FAILURE

	var elapsed: float = agent.recall(self, "elapsed", 0.0) + agent.delta
	if elapsed < stun_duration:
		agent.remember(self, "elapsed", elapsed)
		return Status.RUNNING

	agent.remember(self, "elapsed", 0.0)
	agent.blackboard["stunned"] = false
	return Status.SUCCESS
