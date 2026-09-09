class_name Sequence
extends PerceptComposite

## Corta apenas un hijo no tenga éxito.
func tick(agent: PerceptComponent) -> Status:
	for i in children.size():
		var result := children[i].tick_traced(agent, agent._debug_child_path(i))
		if result != Status.SUCCESS:
			return result
	return Status.SUCCESS
