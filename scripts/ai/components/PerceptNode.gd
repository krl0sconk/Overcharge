class_name PerceptNode
extends Resource

enum Status { SUCCESS, FAILURE, RUNNING }

func tick(_agent: PerceptComponent) -> Status:
	return Status.FAILURE

## Ejecuta el nodo y registra su resultado con la ruta que ocupa en el árbol.
## La ruta evita depender de la identidad del Resource, que puede compartirse.
func tick_traced(agent: PerceptComponent, path: String = "") -> Status:
	agent._debug_enter(path)
	var result: Status = tick(agent)
	agent._debug_record(path, result)
	agent._debug_exit()
	return result
