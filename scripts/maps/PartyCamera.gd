class_name PartyCamera
extends Camera3D

@export var min_distance: float = 10.0
@export var max_distance: float = 16.0
@export var horizontal_padding: float = 1.5
@export var follow_speed: float = 4.0

var _view_direction: Vector3

func _ready() -> void:
	_view_direction = global_position.normalized()
	if _view_direction == Vector3.ZERO:
		_view_direction = Vector3(0, 1, 1).normalized()

func _process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() < 2:
		return

	var pos_a: Vector3 = (players[0] as Node3D).global_position
	var pos_b: Vector3 = (players[1] as Node3D).global_position
	var midpoint: Vector3 = (pos_a + pos_b) / 2.0

	var distance := _distance_to_fit(pos_a.distance_to(pos_b))
	var target_position: Vector3 = midpoint + _view_direction * distance

	global_position = global_position.lerp(target_position, follow_speed * delta)
	look_at(midpoint, Vector3.UP)

func _distance_to_fit(player_separation: float) -> float:
	var half_width: float = player_separation / 2.0 + horizontal_padding
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = viewport_size.x / viewport_size.y
	var v_fov: float = deg_to_rad(fov)
	var h_fov: float = 2.0 * atan(tan(v_fov / 2.0) * aspect)

	var required_distance: float = half_width / tan(h_fov / 2.0)
	return clamp(required_distance, min_distance, max_distance)
