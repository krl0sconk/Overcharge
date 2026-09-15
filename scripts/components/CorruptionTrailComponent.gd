class_name CorruptionTrailComponent
extends Node

## Suelta un grupo de manchas de corrupción cada distance_per_blot unidades
## RECORRIDAS (no por tiempo): persiguiendo deja rastro denso, patrullando
## ralo, sin consultar el blackboard de nadie -- es emisión pasiva del Virus,
## no una decisión de la IA.

@export var owner_body: Node3D
@export var spawn_point: Node3D  ## de dónde salen las manchas (ej. la cola). Vacío = owner_body.
@export var blot_scene: PackedScene
@export var distance_per_blot: float = 1.5
@export var blots_per_drop: int = 3
@export var scatter_radius: float = 0.4  ## dispersión horizontal entre manchas de un mismo grupo

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
		_drop_blots()

func _drop_blots() -> void:
	var origin: Vector3 = spawn_point.global_position if spawn_point != null else owner_body.global_position
	for _i in blots_per_drop:
		var offset := Vector3(
			randf_range(-scatter_radius, scatter_radius),
			0.0,
			randf_range(-scatter_radius, scatter_radius)
		)
		var blot: Node3D = blot_scene.instantiate()
		owner_body.get_parent().add_child(blot)
		blot.global_position = origin + offset
