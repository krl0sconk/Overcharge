class_name TestRoomSpawner
extends Node3D

## Oleadas: reparte los marcadores "enemy_spawn" en tandas de
## enemies_per_wave. Cuando muere el último enemigo de una tanda, espera
## wave_delay y manda la siguiente; cuando se acaban los marcadores y no
## queda nadie vivo, avisa por EventBus que la sala quedó limpia.

@export var player_scenes: Array[PackedScene] = []
@export var enemy_scenes: Array[PackedScene] = []
@export var enemies_per_wave: int = 3
@export var wave_delay: float = 3.0

var _enemy_spawn_points: Array[Node] = []
var _next_spawn_index: int = 0
var _alive_this_wave: int = 0

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	_spawn_players()

	_enemy_spawn_points = get_tree().get_nodes_in_group("enemy_spawn")
	_enemy_spawn_points.sort_custom(_sort_nodes_by_name)
	_spawn_wave()

func _spawn_players() -> void:
	var spawn_points: Array[Node] = get_tree().get_nodes_in_group("player_spawn")
	spawn_points.sort_custom(_sort_nodes_by_name)

	var amount:= mini(player_scenes.size(), spawn_points.size())

	for index in amount:
		var scene: PackedScene = player_scenes[index]
		var spawn_point: Node3D = spawn_points[index]

		if scene == null:
			continue

		var instance := scene.instantiate() as Node3D

		if instance == null:
			push_error("player scene mut have a Node3D root")
			continue

		add_child(instance)
		instance.global_transform = spawn_point.global_transform

func _spawn_wave() -> void:
	if enemy_scenes.is_empty() or _next_spawn_index >= _enemy_spawn_points.size():
		return

	var wave_end: int = mini(_next_spawn_index + enemies_per_wave, _enemy_spawn_points.size())
	_alive_this_wave = wave_end - _next_spawn_index

	for index in range(_next_spawn_index, wave_end):
		var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
		var spawn_point: Node3D = _enemy_spawn_points[index] as Node3D

		if scene == null:
			continue

		var instance := scene.instantiate() as Node3D
		if instance == null:
			push_error("enemy scene must have a Node3D root")
			continue

		add_child(instance)
		instance.global_transform = spawn_point.global_transform

	_next_spawn_index = wave_end

func _on_enemy_died(_killer: Node) -> void:
	_alive_this_wave -= 1
	if _alive_this_wave > 0:
		return

	if _next_spawn_index >= _enemy_spawn_points.size():
		EventBus.room_cleared.emit()
		return

	await get_tree().create_timer(wave_delay).timeout
	_spawn_wave()

func _sort_nodes_by_name(first: Node, second: Node) -> bool:
	return first.name.to_lower() < second.name.to_lower()
