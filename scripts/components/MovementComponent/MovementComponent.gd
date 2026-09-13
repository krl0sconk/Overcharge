class_name MovementComponent
extends Node

@export var owner_body: CharacterBody3D
@export var stats: StatsResource  ## si está asignado, stats.speed/acceleration pisan max_speed/acceleration
@export var max_speed: float = 5.0
@export var acceleration: float = 10.0
@export var friction: float = 14.0  ## global: no vive en StatsResource a propósito, mismo valor para todos
@export_flags_3d_physics var wall_mask: int = 1  ## capas que cuentan como pared para hit_wall (Entorno)

var move_direction: Vector3 = Vector3.ZERO
var hit_wall: bool = false  ## true si el último move_and_slide chocó contra wall_mask


func set_move_direction(direction: Vector3) -> void:
	if direction == Vector3.ZERO:
		move_direction = Vector3.ZERO
	else:
		move_direction = direction.normalized()

## Corta el movimiento en seco.
func stop() -> void:
	move_direction = Vector3.ZERO
	owner_body.velocity = Vector3.ZERO

## Impulso externo (knockback). Se suma a la velocidad y se disipa por friction.
## Lo usan los golpes que empujan, como el empujón del Centinela.
func apply_knockback(impulse: Vector3) -> void:
	owner_body.velocity += Vector3(impulse.x, 0.0, impulse.z)

func _physics_process(delta: float) -> void:
	var speed: float = stats.speed if stats != null else max_speed
	var accel: float = stats.acceleration if stats != null else acceleration
	if move_direction != Vector3.ZERO:
		var target_velocity: Vector3 = move_direction * speed

		owner_body.velocity = owner_body.velocity.move_toward(
		target_velocity, accel * delta
		)
	else:
		owner_body.velocity = owner_body.velocity.move_toward(
			move_direction, friction * delta
		)
	owner_body.move_and_slide()
	_update_hit_wall()

func _update_hit_wall() -> void:
	hit_wall = false
	for i in owner_body.get_slide_collision_count():
		var collision: KinematicCollision3D = owner_body.get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is CollisionObject3D and (collider.collision_layer & wall_mask) != 0 \
				and absf(collision.get_normal().y) < 0.5:
			hit_wall = true
			return
