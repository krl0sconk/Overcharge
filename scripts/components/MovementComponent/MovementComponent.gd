class_name MovementComponent
extends Node

@export var owner_body: CharacterBody3D
@export var max_speed: float = 5.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
var move_direction: Vector3 = Vector3.ZERO
var movement_enabled: bool = true #Sujeto a cambios


func set_move_direction(direction: Vector3) -> void:
	if direction == Vector3.ZERO:
		move_direction = Vector3.ZERO
	else:
		move_direction = direction.normalized()
	
func _physics_process(delta: float) -> void:
	if movement_enabled: #Sujeto a cambios
		if move_direction != Vector3.ZERO:
			var target_velocity: Vector3 = move_direction * max_speed
			
			owner_body.velocity = owner_body.velocity.move_toward(
			target_velocity, acceleration * delta
			)
		else:
			owner_body.velocity = owner_body.velocity.move_toward(
				move_direction, friction * delta
			)
	owner_body.move_and_slide()
