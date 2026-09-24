class_name ProjectileAbility
extends Ability

@export var projectile_speed: float = 10.0
@export var projectile_scene: PackedScene
@export var stats: StatsResource
@export var knockback: Vector3 = Vector3.ZERO

func execute(owner_body: CharacterBody3D, direction: Vector3) -> void:
	if projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate() as Projectile

	if projectile == null:
		return

	## MuzzlePoint marca dónde y hacia dónde se dispara (mira al frente, igual
	## que el modelo). Si el dueño no tiene uno, se cae al centro del cuerpo
	## y a la dirección de movimiento, para no reventar con otras entidades.
	var muzzle := owner_body.get_node_or_null("MuzzlePoint") as Node3D
	var spawn_position: Vector3 = owner_body.global_position
	var spawn_scale: Vector3 = Vector3.ONE
	var fire_direction: Vector3 = direction
	if muzzle != null:
		spawn_position = muzzle.global_position
		spawn_scale = muzzle.global_transform.basis.get_scale()
		## -Z: _face_move_direction rota con +PI para compensar que el modelo
		## importado mira +Z, así que el frente real queda en -Z local.
		fire_direction = -muzzle.global_transform.basis.z

	if fire_direction == Vector3.ZERO:
		return

	projectile.speed = projectile_speed
	projectile.stats = stats
	projectile.knockback = knockback
	projectile.source = owner_body
	projectile.setup(fire_direction)
	projectile.scale = spawn_scale

	owner_body.get_parent().add_child(projectile)
	projectile.global_position = spawn_position
