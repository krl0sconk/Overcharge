class_name CorruptionTrailComponent
extends Node

## Suelta una mancha de corrupción cada distance_per_blot unidades
## RECORRIDAS (no por tiempo): persiguiendo deja rastro denso, patrullando
## ralo, sin consultar el blackboard de nadie -- es emisión pasiva del Virus,
## no una decisión de la IA.

@export var owner_body: Node3D
@export var blot_scene: PackedScene
@export var distance_per_blot: float = 1.5

var _last_position: Vector3
var _distance_accum: float = 0.0

func _ready() -> void:
	if owner_body != null:
		_last_position = owner_body.global_position

func _physics_process(_delta: float) -> void:
	if owner_body == null or blot_scene == null:
		return

	var current_position: Vector3 = owner_body.global_position
	_distance_accum += current_position.distance_to(_last_position)
	_last_position = current_position

	if _distance_accum >= distance_per_blot:
		_distance_accum = 0.0
		_drop_blot(current_position)

func _drop_blot(position: Vector3) -> void:
	var blot: Node3D = blot_scene.instantiate()
	owner_body.get_parent().add_child(blot)
	blot.global_position = position
