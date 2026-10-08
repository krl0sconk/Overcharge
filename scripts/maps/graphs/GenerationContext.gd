class_name GenerationContext
extends RefCounted

var player_1_current_health: int
var player_2_current_health: int
var player_1_max_health: int
var player_2_max_health: int
var health_ratio: float
var average_damage: float
var player_count: int
var seed: int

func _init(
	player_1_current_health: int,
	player_2_current_health: int,
	player_1_damage: int,
	player_2_damage: int,
	player_count: int,
	generation_seed: int,
	player_1_max_health: int = 100,
	player_2_max_health: int = 100
) -> void:
	self.player_1_current_health = player_1_current_health
	self.player_2_current_health = player_2_current_health
	self.player_1_max_health = player_1_max_health
	self.player_2_max_health = player_2_max_health
	self.average_damage = (player_1_damage + player_2_damage) / 2.0
	self.player_count = player_count
	self.seed = generation_seed

	var total_max_health: int = (
		player_1_max_health + player_2_max_health
	)

	if total_max_health > 0:
		health_ratio = clampf(
			float(player_1_current_health + player_2_current_health)
			/ total_max_health,
			0.0,
			1.0
		)
	else:
		health_ratio = 0.0
