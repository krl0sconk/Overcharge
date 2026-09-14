class_name Plato
extends Entidad

## Controlador de Pl4-to: mueve y ataca con lo que ya tiene cableado.
## TODO(quien le ponga la habilidad): todavía no tiene AbilityComponent en
## la escena, así que no hay dash ni combo que enlazar acá.

@export var attack_window: float = 0.2
@export var turn_speed: float = 10.0  ## rad/s

func _physics_process(delta: float) -> void:
	if input_component == null or movement_component == null:
		return

	movement_component.set_move_direction(input_component.move_dir)
	_face_move_direction(delta)

	if input_component.consume_attack() and hitbox_component != null:
		hitbox_component.open_window(attack_window)

## Mismo criterio que TurnToTarget.gd: +PI porque el modelo mira +Z, no -Z.
func _face_move_direction(delta: float) -> void:
	var direction: Vector3 = input_component.move_dir
	if direction == Vector3.ZERO:
		return
	var target_yaw: float = atan2(direction.x, direction.z) + PI
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
