class_name Selector
extends PerceptComposite

## Devuelve el primer hijo que no falle. Si todos fallan, falla.
## Recuerda qué hijo quedó activo (por índice) para que herramientas de
## debug puedan mostrar la rama en curso sin que el nodo guarde estado propio.
func tick(agent: PerceptComponent) -> Status:
	for i in children.size():
		var result := children[i].tick(agent)
		if result != Status.FAILURE:
			agent.remember(self, "active_child", i)
			return result
	agent.remember(self, "active_child", -1)
	return Status.FAILURE
