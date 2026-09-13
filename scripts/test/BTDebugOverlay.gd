class_name BTDebugOverlay
extends Label

## Overlay de debug genérico para cualquier árbol de Percept: objetivo
## fijado, rama activa del Selector de comportamiento y las banderas del
## blackboard que se le pidan. No asume una forma fija de raíz: busca el
## Selector cuya cantidad de hijos coincide con branch_names, sin importar
## cuántos Sequence/Selector lo envuelvan por encima.

@export var percept: PerceptComponent
@export var branch_names: Array[String] = []
@export var blackboard_keys: Array[String] = []
@export var health: HealthComponent

func _process(_delta: float) -> void:
	if percept == null:
		text = "Sin PerceptComponent asignado"
		return

	var target: Node = percept.blackboard.get("target")
	var lines: Array[String] = [
		"Objetivo: %s" % (target.name if is_instance_valid(target) else "ninguno"),
		"Rama activa: %s" % _active_branch_name(),
	]
	for key in blackboard_keys:
		lines.append("%s: %s" % [key, percept.blackboard.get(key, false)])
	if health != null:
		lines.append("Vida: %d" % health.current_health)
	text = "\n".join(lines)

func _active_branch_name() -> String:
	var branch_selector: PerceptComposite = _find_branch_selector(percept.tree)
	if branch_selector == null:
		return "-"
	var index: int = percept.recall(branch_selector, "active_child", -1)
	if index < 0 or index >= branch_names.size():
		return "ninguna (sin objetivo)"
	return branch_names[index]

func _find_branch_selector(node: PerceptNode) -> PerceptComposite:
	if not (node is PerceptComposite):
		return null

	var composite: PerceptComposite = node as PerceptComposite
	if composite is Selector and composite.children.size() == branch_names.size():
		return composite

	for child in composite.children:
		var found: PerceptComposite = _find_branch_selector(child)
		if found != null:
			return found
	return null
