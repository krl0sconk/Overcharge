class_name HealthComponent
extends Node

signal damaged(amount: int)
signal died

@export var max_health: int = 100

var current_health: int = max_health

func _ready():
	current_health = max_health

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
	
	current_health = min(current_health + amount, max_health)
	
