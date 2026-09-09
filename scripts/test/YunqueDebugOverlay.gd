class_name YunqueDebugOverlay
extends Label

## Overlay de debug: rama activa del árbol, objetivo fijado y banderas del
## blackboard. Asume que el árbol raíz es Sequence[AcquireTarget, Selector]
## (la forma que arma AcquireTarget al tope de todo árbol de enemigo).

@export var percept: PerceptComponent

const BRANCH_NAMES: Array[String] = [
	"1. Aturdido",
	"2. Cargando",
	"3. Flanqueado",
	"4. Iniciar carga",
	"5. Buscar línea",
]

func _process(_delta: float) -> void:
	if percept == null:
		text = "Sin PerceptComponent asignado"
		return

	var target: Node = percept.blackboard.get("target")
	var lines: Array[String] = [
		"Objetivo: %s" % (target.name if is_instance_valid(target) else "ninguno"),
		"Rama activa: %s" % _active_branch_name(),
		"stunned: %s" % percept.blackboard.get("stunned", false),
		"charging: %s" % percept.blackboard.get("charging", false),
		"telegraphing: %s" % percept.blackboard.get("telegraphing", false),
	]
	text = "\n".join(lines)

func _active_branch_name() -> String:
	if percept.tree == null or not (percept.tree is PerceptComposite):
		return "-"
	var root_children: Array[PerceptNode] = (percept.tree as PerceptComposite).children
	if root_children.size() < 2:
		return "-"
	var branch_selector: PerceptNode = root_children[1]
	var index: int = percept.recall(branch_selector, "active_child", -1)
	if index < 0 or index >= BRANCH_NAMES.size():
		return "ninguna (sin objetivo)"
	return BRANCH_NAMES[index]
