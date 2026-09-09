class_name PerceptCondition
extends PerceptNode

func tick(agent: PerceptComponent) -> Status:
	return Status.SUCCESS if check(agent) else Status.FAILURE

func check(_agent: PerceptComponent) -> bool:
	return false
