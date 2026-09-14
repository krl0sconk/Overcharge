class_name DashAbility
extends Ability

@export var dash_speed: float = 15.0

func execute(owner_body: CharacterBody3D, direction: Vector3) -> void:
	owner_body.velocity = direction * dash_speed
