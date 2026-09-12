class_name PerceptDecorator
extends PerceptComposite

## Base de decoradores: exactamente un hijo. Extiende PerceptComposite (en vez
## de tener su propio `child`) para que el editor visual de Percept, que arma
## y valida el árbol a través de la propiedad `children`, trate decoradores y
## compuestos con el mismo mecanismo de guardado.

func _child() -> PerceptNode:
	return children[0] if not children.is_empty() else null
