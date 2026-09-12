class_name PerceptComponent
extends Node

@export var actor: Node
@export var tree: PerceptNode          ## el .tres compartido
@export var tick_rate: float = 0.1
@export var movement_component: MovementComponent   # TODO(María): tipar a MovementComponent cuando exista.

var blackboard: Dictionary = {}        ## datos del enemigo: target, etc.
var memory: Dictionary = {}            ## lo que un nodo necesita recordar
var delta: float = 0.0

var _accum: float = 0.0

func _physics_process(d: float) -> void:
	_accum += d
	if _accum < tick_rate:
		return
	delta = _accum
	_accum = 0.0
	if tree != null:
		tree.tick(self)

## Los nodos son compartidos, así que su memoria vive acá, en cada enemigo.
func remember(node: PerceptNode, key: String, value: Variant) -> void:
	if not memory.has(node):
		memory[node] = {}
	memory[node][key] = value

func recall(node: PerceptNode, key: String, default: Variant = null) -> Variant:
	return memory.get(node, {}).get(key, default)
