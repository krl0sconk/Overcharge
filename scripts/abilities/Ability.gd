class_name Ability
extends Resource

@export var cooldown: float = 1.0
@export var duration: float = 0.0
@export var can_chain: bool = false
@export var ends_on_execute: bool = true

func execute(owner_body: CharacterBody3D, direction: Vector3) -> void: #Sujeto a modificaciones
	pass
func update(delta: float) -> void:
	pass
func is_finished() -> bool:
	return true
