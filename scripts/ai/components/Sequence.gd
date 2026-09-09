class_name Sequence
extends PerceptComposite

## Corta apenas un hijo no tenga éxito.
func tick(agent: PerceptComponent) -> Status:
	for child in children:
		var result := child.tick(agent)
		if result != Status.SUCCESS:
			return result
	return Status.SUCCESS
