class_name Nitzsch
extends Entidad

## Controlador de Ni-TZSch: traduce las intenciones del InputComponent a los
## demás componentes. Ataque básico por HitboxComponent; dash real por
## DashAbilityComponent.
## TODO(quien siga el combo): ComboAbility.execute() todavía no pega de
## verdad (solo imprime), así que no se cablea a ningún botón todavía.

@export var attack_window: float = 0.2
@export var turn_speed: float = 10.0  ## rad/s

@onready var dash_component: AbilityComponent = get_node_or_null("DashAbilityComponent")

func _physics_process(delta: float) -> void:
	if input_component == null or movement_component == null:
		return

	movement_component.set_move_direction(input_component.move_dir)
	_face_move_direction(delta)

	if input_component.consume_attack() and hitbox_component != null:
		hitbox_component.open_window(attack_window)

	if input_component.consume_dash() and dash_component != null:
		dash_component.try_execute()

## Mismo criterio que TurnToTarget.gd: +PI porque el modelo mira +Z, no -Z.
func _face_move_direction(delta: float) -> void:
	var direction: Vector3 = input_component.move_dir
	if direction == Vector3.ZERO:
		return
	var target_yaw: float = atan2(direction.x, direction.z) + PI
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
