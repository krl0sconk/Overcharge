class_name Plato
extends Entidad

## Controlador de Pl4-to: se mueve y ataca a distancia con el proyectil.

@export var turn_speed: float = 10.0  ## rad/s
@onready var return_ability_component: AbilityComponent = get_node_or_null("ReturnAbilityComponent")

func _physics_process(delta: float) -> void:
	if input_component == null or movement_component == null:
		return

	movement_component.set_move_direction(input_component.move_dir)
	_face_move_direction(delta)

	if input_component.consume_attack():
		if ability_component != null:
			ability_component.try_execute()
	
	if input_component.consume_return():
		if return_ability_component != null:
			return_ability_component.try_execute()

## Mismo criterio que TurnToTarget.gd: +PI porque el modelo mira +Z, no -Z.
func _face_move_direction(delta: float) -> void:
	var direction: Vector3 = input_component.move_dir
	if direction == Vector3.ZERO:
		return
	var target_yaw: float = atan2(direction.x, direction.z) + PI
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
