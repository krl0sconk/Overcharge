class_name ProjectileAbility
extends Ability

@export var projectile_speed: float = 10.0
@export var projectile_scene: PackedScene

func execute(owner_body: CharacterBody3D, direction: Vector3) -> void:
	if projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate() as Projectile

	if projectile == null:
		return

	projectile.speed = projectile_speed
	projectile.setup(direction)

	owner_body.get_parent().add_child(projectile)
	projectile.global_position = owner_body.global_position
