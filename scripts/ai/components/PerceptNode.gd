class_name PerceptNode
extends Resource

enum Status { SUCCESS, FAILURE, RUNNING }

func tick(_agent: PerceptComponent) -> Status:
	return Status.FAILURE
