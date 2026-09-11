class_name HealthComponent
extends Node

signal damaged(amount: int)
signal died

@export var stats: StatsResource

var current_health: int

func _ready() -> void:
	if stats == null:
		push_error("StatsResource no asignado en HealthComponent")
		return
	current_health = stats.max_health

func take_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health = max(current_health - amount, 0) 
	damaged.emit(amount)

	if current_health == 0:
		died.emit()
	
func heal(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	
	current_health = min(current_health + amount, stats.max_health)
	
