class_name ReturnNodeAbility
extends Ability

@export var marker_scene: PackedScene

var return_position: Vector3 = Vector3.ZERO
var has_return_position: bool = false
var _marker: Node3D = null

func execute(owner_body: CharacterBody3D, _direction: Vector3) -> void:
	if not has_return_position:
		return_position = owner_body.global_position
		has_return_position = true
		_spawn_marker(owner_body)
	else:
		owner_body.global_position = return_position
		has_return_position = false
		_free_marker()

func cancel() -> void:
	_free_marker()
	has_return_position = false

func _spawn_marker(owner_body: CharacterBody3D) -> void:
	if marker_scene == null:
		return
	_marker = marker_scene.instantiate() as Node3D
	if _marker == null:
		return
	owner_body.get_parent().add_child(_marker)
	_marker.global_position = return_position

func _free_marker() -> void:
	if _marker != null:
		_marker.queue_free()
		_marker = null
