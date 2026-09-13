class_name TestRoomSpawner
extends Node3D

@export var player_scenes: Array[PackedScene] = []
@export var enemy_scenes: Array[PackedScene] = []

func _ready():
	_spawn_players()
	_spawn_enemies()

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

func _spawn_enemies() -> void:
	var spawn_points: Array[Node] = get_tree().get_nodes_in_group("enemy_spawn")
	spawn_points.sort_custom(_sort_nodes_by_name)
	
	if enemy_scenes.is_empty():
		return

	for index in spawn_points.size():
		var scene: PackedScene = enemy_scenes[index % enemy_scenes.size()]
		var spawn_point: Node3D = spawn_points[index]

		if scene == null:
			continue
		
		var instance:= scene.instantiate() as Node3D
		if instance == null:
			push_error("enemy scene must have a Node3D root")
			continue
		
		add_child(instance)
		instance.global_transform = spawn_point.global_transform
		
func _sort_nodes_by_name(first: Node, second: Node) -> bool:
	return first.name.to_lower() < second.name.to_lower()
