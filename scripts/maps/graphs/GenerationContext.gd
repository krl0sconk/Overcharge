class_name GenerationContext
extends RefCounted

var player_1_current_health: int
var player_2_current_health: int
var average_damage: float
var player_count: int
var seed: int

func _init(player_1_current_health: int, player_2_current_health: int, player_1_damage: int, player_2_damage: int, player_count: int, generation_seed: int) -> void:
	self.player_1_current_health = player_1_current_health
	self.player_2_current_health = player_2_current_health
	self.average_damage = (player_1_damage + player_2_damage) / 2.0
	self.player_count = player_count
	self.seed = generation_seed
